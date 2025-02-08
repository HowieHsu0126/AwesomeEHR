DROP TABLE IF EXISTS aki_cr;

CREATE TABLE aki_cr AS
WITH creatinine_measurements AS (
    SELECT
        patientunitstayid,
        labresultoffset,
        labresult,
        ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY labresultoffset ASC) AS row_num
    FROM
        eicu_crd.lab
    WHERE
        labname = 'creatinine'
),
baseline_creatinine AS (
    SELECT
        patientunitstayid,
        MIN(labresult) AS baseline_creatinine, -- 选择第一个7天内的最低肌酐值
        MIN(labresultoffset) AS baseline_creat_offset -- 对应的时间偏移
    FROM
        creatinine_measurements
    WHERE
        labresultoffset BETWEEN 0 AND 10080 -- ICU入院后的7天内
    GROUP BY
        patientunitstayid
),
aki_criteria_7days AS (
    SELECT
        cm.patientunitstayid,
        cm.labresult,
        cm.labresultoffset,
        bc.baseline_creatinine,
        bc.baseline_creat_offset,
        -- 判断肌酐是否满足KDIGO标准，KDIGO标准：肌酐升高1.5倍及以上（基于7天）
        CASE WHEN cm.labresult >= 1.5 * bc.baseline_creatinine
            AND cm.labresultoffset > bc.baseline_creat_offset
            AND cm.labresultoffset <= bc.baseline_creat_offset + 10080 -- 时间差不超过7天
            THEN
            1
        ELSE
            0
        END AS is_aki_7days
    FROM
        creatinine_measurements cm
        JOIN baseline_creatinine bc ON cm.patientunitstayid = bc.patientunitstayid
),
aki_criteria_48hrs AS (
    SELECT
        cm.patientunitstayid,
        cm.labresult,
        cm.labresultoffset,
        bc.baseline_creatinine,
        bc.baseline_creat_offset,
        -- 判断肌酐是否满足KDIGO标准，KDIGO标准：肌酐升高0.3 mg/dL及以上（基于48小时）
        CASE WHEN cm.labresult - LAG(cm.labresult) OVER (PARTITION BY cm.patientunitstayid ORDER BY cm.labresultoffset) >= 0.3
            AND cm.labresultoffset > bc.baseline_creat_offset
            AND cm.labresultoffset <= bc.baseline_creat_offset + 2880 -- 时间差不超过48小时
            THEN
            1
        ELSE
            0
        END AS is_aki_48hrs
    FROM
        creatinine_measurements cm
    JOIN baseline_creatinine bc ON cm.patientunitstayid = bc.patientunitstayid
),
earliest_aki_criteria AS (
    SELECT
        COALESCE(aki_criteria_7days.patientunitstayid, aki_criteria_48hrs.patientunitstayid) AS patientunitstayid,
        MAX(aki_criteria_7days.is_aki_7days) AS aki_diagnosis_7days, -- 是否符合基于7天的AKI标准
        MAX(aki_criteria_48hrs.is_aki_48hrs) AS aki_diagnosis_48hrs, -- 是否符合基于48小时的AKI标准
        CASE WHEN MAX(aki_criteria_7days.is_aki_7days) = 1
            OR MAX(aki_criteria_48hrs.is_aki_48hrs) = 1 THEN
            1
        ELSE
            0
        END AS final_aki_diagnosis, -- 最终AKI诊断（如果满足任一标准则为1）
        ROW_NUMBER() OVER (PARTITION BY COALESCE(aki_criteria_7days.patientunitstayid, aki_criteria_48hrs.patientunitstayid) ORDER BY COALESCE(aki_criteria_7days.labresultoffset, aki_criteria_48hrs.labresultoffset) ASC) AS row_num
    FROM
        aki_criteria_7days
    FULL OUTER JOIN aki_criteria_48hrs
        ON aki_criteria_7days.patientunitstayid = aki_criteria_48hrs.patientunitstayid
    GROUP BY
        COALESCE(aki_criteria_7days.patientunitstayid, aki_criteria_48hrs.patientunitstayid),
        COALESCE(aki_criteria_7days.labresultoffset, aki_criteria_48hrs.labresultoffset)
)
SELECT DISTINCT
    patientunitstayid,
    aki_diagnosis_7days,
    aki_diagnosis_48hrs,
    final_aki_diagnosis
FROM
    earliest_aki_criteria
WHERE
    final_aki_diagnosis = 1 -- 选择最终被判断为AKI的患者
    AND row_num = 1 -- 选择每个患者的最早记录
ORDER BY
    patientunitstayid;
