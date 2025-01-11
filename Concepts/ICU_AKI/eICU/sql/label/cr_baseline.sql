-- 用于确定基线肌酐水平
-- 目的: 确定患者进入ICU后的第一个七天内的最低肌酐值。
-- 操作: 筛选出进入ICU后的第一个七天内的肌酐实验室结果，并选择该段时间内的最低值作为基线肌酐。

DROP TABLE IF EXISTS baseline_creat;

CREATE TABLE baseline_creat AS
WITH creatinine_measurements AS (
    SELECT 
        patientunitstayid,
        labresultoffset,
        labresult,
        ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY labresultoffset ASC) AS row_num
    FROM eicu_crd.lab
    WHERE labname = 'creatinine'
      AND labresultoffset BETWEEN 0 AND 10080  -- 0到10080分钟 = ICU入院后的7天
),
baseline_creatinine AS (
    SELECT
        patientunitstayid,
        MIN(labresult) AS baseline_creatinine,  -- 选择第一个7天内的最低肌酐值
        MIN(labresultoffset) AS baseline_creat_offset  -- 对应的时间偏移
    FROM creatinine_measurements
    GROUP BY patientunitstayid
)
SELECT
    patientunitstayid,
    baseline_creatinine,
    baseline_creat_offset
FROM baseline_creatinine
ORDER BY patientunitstayid;
