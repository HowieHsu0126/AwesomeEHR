-- 用于判断ICU获得性AKI
-- 目的: 根据KDIGO标准判断是否符合ICU获得性AKI的标准，支持基于7天和48小时内的肌酐判断
-- 操作:
-- 1. 选择肌酐时间在基线之后，且时间差不超过7天或48小时的肌酐记录。
-- 2. 判断肌酐值是否满足KDIGO标准，符合升高1.5倍或以上（基于7天）或者升高0.3 mg/dL以上（基于48小时）。

DROP TABLE IF EXISTS aki_diagnosis;

CREATE TABLE aki_diagnosis AS
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
)
SELECT
    COALESCE(aki_criteria_7days.patientunitstayid, aki_criteria_48hrs.patientunitstayid) AS patientunitstayid,
    MAX(aki_criteria_7days.is_aki_7days) AS aki_diagnosis_7days, -- 是否符合基于7天的AKI标准
    MAX(aki_criteria_48hrs.is_aki_48hrs) AS aki_diagnosis_48hrs, -- 是否符合基于48小时的AKI标准
    CASE WHEN MAX(aki_criteria_7days.is_aki_7days) = 1
        OR MAX(aki_criteria_48hrs.is_aki_48hrs) = 1 THEN
        1
    ELSE
        0
    END AS final_aki_diagnosis -- 最终AKI诊断（如果满足任一标准则为1）
FROM
    aki_criteria_7days
    FULL OUTER JOIN aki_criteria_48hrs ON aki_criteria_7days.patientunitstayid = aki_criteria_48hrs.patientunitstayid
GROUP BY
    COALESCE(aki_criteria_7days.patientunitstayid, aki_criteria_48hrs.patientunitstayid)
ORDER BY
    COALESCE(aki_criteria_7days.patientunitstayid, aki_criteria_48hrs.patientunitstayid);
