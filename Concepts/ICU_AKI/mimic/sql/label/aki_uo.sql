-- 创建 DATETIME_DIFF 函数，用于处理日期的差异
CREATE OR REPLACE FUNCTION DATETIME_DIFF(endtime timestamp(3), starttime timestamp(3), datepart text)
    RETURNS numeric
    AS $$
BEGIN
    RETURN EXTRACT(EPOCH FROM endtime - starttime) / CASE WHEN datepart = 'SECOND' THEN
        1.0
    WHEN datepart = 'MINUTE' THEN
        60.0
    WHEN datepart = 'HOUR' THEN
        3600.0
    WHEN datepart = 'DAY' THEN
        24 * 3600.0
    WHEN datepart = 'YEAR' THEN
        365.242 * 24 * 3600.0
    ELSE
        NULL
    END;
END;
$$
LANGUAGE PLPGSQL;

-- 删除旧的结果表
DROP TABLE IF EXISTS aki_uo;

-- 创建新的结果表
CREATE TABLE aki_uo AS
WITH weight_data AS (
    -- 计算每个患者的平均体重
    SELECT
        s.stay_id,
        AVG(s.weight) AS avg_weight,
        ie.subject_id,
        ie.intime,
        ie.outtime
    FROM
        mimiciv_derived.weight_durations s
    JOIN
        mimiciv_icu.icustays ie ON s.stay_id = ie.stay_id
    GROUP BY
        s.stay_id, ie.subject_id, ie.intime, ie.outtime
),
ur_stg AS (
    SELECT 
        io.stay_id, 
        io.charttime,
        -- 6 hours
        SUM(CASE WHEN iosum.charttime >= DATETIME_SUB(io.charttime, interval '5' hour)
            THEN iosum.urineoutput
            ELSE NULL END) AS UrineOutput_6hr,
        -- calculate the number of hours over which we've tabulated UO
        ROUND(CAST(
            DATETIME_DIFF(io.charttime, 
                -- below MIN() gets the earliest time that was used in the summation 
                MIN(CASE WHEN iosum.charttime >= DATETIME_SUB(io.charttime, interval '5' hour)
                    THEN iosum.charttime
                    ELSE NULL END),
                'SECOND') AS NUMERIC)/3600.0, 4) AS uo_tm_6hr
    FROM 
        mimiciv_derived.urine_output io
    -- this join gives all UO measurements over the 24 hours preceding this row
    LEFT JOIN mimiciv_derived.urine_output iosum
        ON io.stay_id = iosum.stay_id
        AND iosum.charttime <= io.charttime
        AND iosum.charttime >= DATETIME_SUB(io.charttime, interval '5' hour)
    GROUP BY 
        io.stay_id, io.charttime
),
aki_ur AS (
    SELECT
        ur.stay_id,
        ur.charttime,
        wd.avg_weight,
        ur.urineoutput_6hr,
        -- calculate rates - adding 1 hour as we assume data charted at 10:00 corresponds to previous hour
        ROUND(CAST((ur.UrineOutput_6hr/wd.avg_weight/(uo_tm_6hr+1)) AS NUMERIC), 4) AS uo_rt_6hr,
        -- number of hours between current UO time and earliest charted UO within the X hour window
        uo_tm_6hr
    FROM 
        ur_stg ur
    LEFT JOIN weight_data wd
        ON ur.stay_id = wd.stay_id
        AND ur.charttime >= wd.intime
        AND ur.charttime < wd.outtime
),
aki_final AS (
    SELECT
        uo.stay_id,
        ie.subject_id,
        uo.charttime,
        uo.avg_weight,
        uo.uo_rt_6hr,
        -- AKI stages according to urine output
        CASE
            WHEN uo.uo_rt_6hr IS NULL THEN NULL
            -- require patient to be in ICU for at least 6 hours to stage UO
            WHEN uo.charttime <= DATETIME_ADD(ie.intime, INTERVAL '6' HOUR) THEN 0
            -- require the UO rate to be calculated over half the period
            WHEN uo.uo_tm_6hr >= 2 AND uo.uo_rt_6hr < 0.5 THEN 1
            ELSE 0 
        END AS aki_stage_uo
    FROM 
        aki_ur uo
    INNER JOIN mimiciv_icu.icustays ie
        ON uo.stay_id = ie.stay_id
),
earliest_aki AS (
    SELECT
        subject_id,
        stay_id,
        charttime AS aki_timepoint,
        ROW_NUMBER() OVER (PARTITION BY subject_id ORDER BY charttime) AS rn
    FROM aki_final
    WHERE aki_stage_uo = 1
)
SELECT
    subject_id,
    stay_id,
    aki_timepoint
FROM earliest_aki
WHERE rn = 1;

-- 主要内容：基于KDIGO尿量标准判断AKI，
-- 计算6小时内的尿量输出率（ml/kg/h），当低于0.5时判定为AKI，
-- 记录每个患者最早的AKI发生时间
