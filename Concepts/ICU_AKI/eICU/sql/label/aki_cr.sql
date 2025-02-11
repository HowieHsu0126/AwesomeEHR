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
        cm1.patientunitstayid,
        cm1.labresult AS current_labresult,
        cm1.labresultoffset AS current_offset,
        cm2.labresult AS future_labresult,
        cm2.labresultoffset AS future_offset,
        CASE WHEN cm2.labresult - cm1.labresult >= 0.3
            AND cm2.labresultoffset > cm1.labresultoffset
            AND cm2.labresultoffset <= cm1.labresultoffset + 2880 -- 时间差不超过48小时
            THEN
            1
        ELSE
            0
        END AS is_aki_48hrs
    FROM
        creatinine_measurements cm1
    JOIN
        creatinine_measurements cm2
    ON
        cm1.patientunitstayid = cm2.patientunitstayid
        AND cm2.labresultoffset > cm1.labresultoffset
        AND cm2.labresultoffset <= cm1.labresultoffset + 2880
),
earliest_aki_criteria AS (
    SELECT
        COALESCE(aki_criteria_7days.patientunitstayid, aki_criteria_48hrs.patientunitstayid) AS patientunitstayid,
        MAX(aki_criteria_7days.is_aki_7days) AS aki_diagnosis_7days,
        MAX(aki_criteria_48hrs.is_aki_48hrs) AS aki_diagnosis_48hrs,
        CASE WHEN MAX(aki_criteria_7days.is_aki_7days) = 1
            OR MAX(aki_criteria_48hrs.is_aki_48hrs) = 1 THEN
            1
        ELSE
            0
        END AS final_aki_diagnosis,
        MIN(COALESCE(aki_criteria_7days.labresultoffset, aki_criteria_48hrs.current_offset)) AS aki_diagnosis_time
    FROM
        aki_criteria_7days
    FULL OUTER JOIN aki_criteria_48hrs
        ON aki_criteria_7days.patientunitstayid = aki_criteria_48hrs.patientunitstayid
    GROUP BY
        COALESCE(aki_criteria_7days.patientunitstayid, aki_criteria_48hrs.patientunitstayid)
)
SELECT
    patientunitstayid,
    aki_diagnosis_7days,
    aki_diagnosis_48hrs,
    final_aki_diagnosis,
    aki_diagnosis_time
FROM
    earliest_aki_criteria
WHERE
    final_aki_diagnosis = 1
ORDER BY
    patientunitstayid,
    aki_diagnosis_time;
