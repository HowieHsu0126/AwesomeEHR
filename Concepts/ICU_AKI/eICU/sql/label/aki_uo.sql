-- 删除旧的 UO 结果表
DROP TABLE IF EXISTS aki_uo;

-- 创建一个视图，以识别尿量低于标准的 AKI 患者
CREATE TABLE aki_uo AS
WITH weight_data AS (
    -- 获取每个患者的平均体重
    SELECT
        p.patientunitstayid,
        p.uniquepid,
        p.unitdischargeoffset,
        AVG(w.weight) AS avg_weight
    FROM
        patient_weight w
    JOIN
        eicu_crd.patient p ON w.patientunitstayid = p.patientunitstayid
    GROUP BY
        p.patientunitstayid, p.uniquepid, p.unitdischargeoffset
), urine_output_stg1 AS (
    -- 计算5小时窗口内的尿量统计
    SELECT
        io.patientunitstayid,
        io.chartoffset,
        -- 计算5小时窗口内的总尿量
        SUM(CASE WHEN iosum.chartoffset >= io.chartoffset - 300  -- 300分钟 = 5小时
            THEN iosum.urineoutput
            ELSE NULL END) AS UrineOutput_6hr,
        -- 计算实际计算时间（小时）
        ROUND(CAST(
            (io.chartoffset - 
                MIN(CASE WHEN iosum.chartoffset >= io.chartoffset - 300
                    THEN iosum.chartoffset
                    ELSE NULL END)) / 60.0 AS NUMERIC), 4) AS uo_tm_6hr
    FROM
        pivoted_uo io
    LEFT JOIN pivoted_uo iosum
        ON io.patientunitstayid = iosum.patientunitstayid
        AND iosum.chartoffset <= io.chartoffset
        AND iosum.chartoffset >= io.chartoffset - 300
    GROUP BY
        io.patientunitstayid, io.chartoffset
), aki_ur AS (
    SELECT
        ur.patientunitstayid,
        ur.chartoffset,
        wd.avg_weight,
        ur.urineoutput_6hr,
        -- calculate rates - adding 1 hour as we assume data charted at 10:00 corresponds to previous hour
        ROUND(CAST((ur.UrineOutput_6hr/wd.avg_weight/(uo_tm_6hr+1)) AS NUMERIC), 4) AS uo_rt_6hr,
        -- number of hours between current UO time and earliest charted UO within the X hour window
        uo_tm_6hr
    FROM
        urine_output_stg1 ur
    LEFT JOIN weight_data wd
        ON ur.patientunitstayid = wd.patientunitstayid
        AND ur.chartoffset >= 0
        AND ur.chartoffset <= wd.unitdischargeoffset
), aki_final AS (
    SELECT
        uo.patientunitstayid,
        p.uniquepid,
        uo.chartoffset,
        uo.avg_weight,
        uo.uo_rt_6hr,
        -- AKI stages according to urine output
        CASE
            WHEN uo.uo_rt_6hr IS NULL THEN NULL
            -- require patient to be in ICU for at least 6 hours to stage UO
            WHEN uo.chartoffset <= 360 THEN 0  -- 360分钟 = 6小时
            -- require the UO rate to be calculated over half the period
            WHEN uo.uo_tm_6hr >= 3 AND uo.uo_rt_6hr < 0.5 THEN 1
            ELSE 0
        END AS aki_stage_uo
    FROM
        aki_ur uo
    INNER JOIN eicu_crd.patient p
        ON uo.patientunitstayid = p.patientunitstayid
), ranked_aki AS (
    SELECT
        uniquepid,
        patientunitstayid,
        chartoffset AS aki_timepoint,
        ROW_NUMBER() OVER (PARTITION BY uniquepid ORDER BY chartoffset) AS rn
    FROM
        aki_final
    WHERE
        aki_stage_uo = 1
)
SELECT
    uniquepid,
    patientunitstayid,
    aki_timepoint AS chartoffset
FROM
    ranked_aki
WHERE
    rn = 1
ORDER BY
    uniquepid;

-- 主要内容：基于尿量判断AKI，使用5小时窗口计算尿量输出率，
-- 当时间>=3小时且尿量<0.5ml/kg/h时判定为AKI
