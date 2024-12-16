-- 计算每个患者的平均体重：在weight_avg子查询中，我们计算了每个患者的平均体重。
-- 计算每小时每公斤体重的尿量：在uo_aki子查询中，我们计算了每小时每公斤体重的尿量。
-- 根据尿量来判断AKI状态：根据KDIGO标准，如果尿量少于0.5毫升/千克/小时持续6小时以上，则被认为是AKI。我们在uo_aki子查询中实现了这个逻辑。
-- 结合每个患者的尿量数据和AKI状态进行输出：最终输出包括每个患者的stay_id、时间戳、平均体重、6小时尿量、尿量输出时间、每小时每公斤体重的尿量以及AKI状态。
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

DROP TABLE IF EXISTS aki_uo;

CREATE TABLE aki_uo AS
WITH uo_stg1 AS (
    SELECT
        ie.stay_id,
        uo.charttime,
        ie.subject_id,
        DATETIME_DIFF(charttime, intime, 'SECOND') AS seconds_since_admit,
        COALESCE(DATETIME_DIFF(charttime, LAG(charttime) OVER (PARTITION BY ie.stay_id ORDER BY charttime), 'SECOND') / 3600.0, 1) AS hours_since_previous_row,
        urineoutput
    FROM
        mimiciv_icu.icustays ie
        INNER JOIN mimiciv_derived.urine_output uo ON ie.stay_id = uo.stay_id
),
weight_avg AS (
    -- Calculate the average weight for each patient
    SELECT
        stay_id,
        AVG(weight) AS avg_weight
    FROM
        mimiciv_derived.weight_durations
    GROUP BY
        stay_id
),
uo_stg2 AS (
    SELECT
        stay_id,
        charttime,
        subject_id,
        hours_since_previous_row,
        urineoutput,
        SUM(urineoutput) OVER (PARTITION BY stay_id ORDER BY seconds_since_admit RANGE BETWEEN 21600 PRECEDING AND CURRENT ROW) AS urineoutput_6hr,
        SUM(hours_since_previous_row) OVER (PARTITION BY stay_id ORDER BY seconds_since_admit RANGE BETWEEN 21600 PRECEDING AND CURRENT ROW) AS uo_tm_6hr
    FROM
        uo_stg1
),
uo_aki AS (
    -- Determine AKI status based on KDIGO urine output criteria
    SELECT
        ur.subject_id,
        ur.stay_id,
        ur.charttime,
        wa.avg_weight,
        ur.urineoutput_6hr,
        ur.uo_tm_6hr,
        ROUND(CAST((ur.urineoutput_6hr / wa.avg_weight / ur.uo_tm_6hr) AS numeric), 4) AS uo_rt_6hr,
        CASE WHEN ur.uo_tm_6hr >= 6
            AND (ur.urineoutput_6hr / wa.avg_weight / ur.uo_tm_6hr) < 0.5 THEN
            'AKI-UO'
        ELSE
            'No AKI'
        END AS aki_status,
        -- Record the earliest time point when AKI criteria are met
        MIN(charttime) OVER (PARTITION BY ur.stay_id ORDER BY ur.charttime RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS aki_timepoint -- 假设AKI的发生是在连续6小时内尿量低于阈值的第一次发生时确定的
    FROM
        uo_stg2 ur
        LEFT JOIN weight_avg wa ON ur.stay_id = wa.stay_id
    WHERE
        ur.uo_tm_6hr >= 6
        AND (ur.urineoutput_6hr / wa.avg_weight / ur.uo_tm_6hr) < 0.5
)
SELECT
    *
FROM
    uo_aki;

