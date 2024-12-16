-- 用于确定稳定的基线肌酐水平
-- 目的: 确定患者在进入ICU前3个月内至ICU入住时的稳定肌酐值。
-- 操作: 首先筛选出特定时间窗口内的肌酐实验室结果。然后计算这段时间内肌酐值的平均值，并选择最接近平均值的记录作为稳定值。

DROP VIEW IF EXISTS baseline_creat_view;

CREATE VIEW baseline_creat_view AS
WITH creatinine_measurements AS (
    SELECT 
        patientunitstayid,
        labresultoffset,
        labresult,
        ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY labresultoffset ASC) AS row_num
    FROM eicu_crd.lab
    WHERE labname = 'creatinine'
      AND labresultoffset BETWEEN -10080 AND 0  -- -10080 minutes = -7 days
),
average_creatinine AS (
    SELECT
        patientunitstayid,
        AVG(labresult) AS avg_creatinine
    FROM creatinine_measurements
    GROUP BY patientunitstayid
),
closest_to_average AS (
    SELECT 
        cm.patientunitstayid,
        cm.labresult AS stable_creatinine,
        cm.labresultoffset AS stable_creat_offset,
        ABS(cm.labresult - ac.avg_creatinine) AS diff
    FROM creatinine_measurements cm
    JOIN average_creatinine ac ON cm.patientunitstayid = ac.patientunitstayid
    ORDER BY diff ASC, cm.labresultoffset DESC
)
SELECT
    patientunitstayid,
    MIN(stable_creatinine) AS stable_creatinine,  -- 选择最接近平均值的肌酐值
    MIN(stable_creat_offset) AS stable_creat_offset  -- 对应的时间偏移
FROM closest_to_average
GROUP BY patientunitstayid
ORDER BY patientunitstayid;
