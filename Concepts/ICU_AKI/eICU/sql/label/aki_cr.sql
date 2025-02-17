-- 删除旧的 AKI 结果表
DROP TABLE IF EXISTS aki_cr;

-- 创建新的 AKI 结果表
CREATE TABLE aki_cr AS
-- 结合肌酐检测数据来提取 AKI 患者
WITH creatinine_measurements AS (
    SELECT
        l.patientunitstayid,
        p.uniquepid,  -- 通过 eicu_crd.patient 表中的 uniquepid 唯一标识患者
        l.labresultoffset,
        l.labresult,
        ROW_NUMBER() OVER (PARTITION BY l.patientunitstayid ORDER BY l.labresultoffset ASC) AS row_num
    FROM
        eicu_crd.lab l
    JOIN
        eicu_crd.patient p ON l.patientunitstayid = p.patientunitstayid  -- 连接 patient 表获取 uniquepid
    WHERE
        l.labname = 'creatinine'
),
baseline_creatinine AS (
    SELECT
        cm.patientunitstayid,
        cm.uniquepid,  -- 通过 uniquepid 唯一标识患者
        MIN(cm.labresult) AS baseline_creatinine,  -- 选择第一个7天内的最低肌酐值
        MIN(cm.labresultoffset) AS baseline_creat_offset  -- 对应的时间偏移
    FROM
        creatinine_measurements cm
    GROUP BY
        cm.patientunitstayid, cm.uniquepid
),
aki_criteria_7days AS (
    SELECT
        cm.patientunitstayid,
        cm.uniquepid,  -- 通过 uniquepid 唯一标识患者
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
        cm1.uniquepid,  -- 通过 uniquepid 唯一标识患者
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
        COALESCE(aki_criteria_7days.uniquepid, aki_criteria_48hrs.uniquepid) AS uniquepid,  -- 使用 uniquepid 唯一标识患者
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
        COALESCE(aki_criteria_7days.patientunitstayid, aki_criteria_48hrs.patientunitstayid),
        COALESCE(aki_criteria_7days.uniquepid, aki_criteria_48hrs.uniquepid)
),
-- 使用 ROW_NUMBER() 来选择每个患者最早的 AKI 诊断记录
earliest_aki AS (
    SELECT
        uniquepid,
        patientunitstayid,
        aki_diagnosis_7days,
        aki_diagnosis_48hrs,
        final_aki_diagnosis,
        aki_diagnosis_time,
        ROW_NUMBER() OVER (PARTITION BY uniquepid ORDER BY aki_diagnosis_time ASC) AS row_num  -- 按照时间排序，选择最早记录
    FROM
        earliest_aki_criteria
)
SELECT
    uniquepid,  -- 返回 uniquepid 作为患者唯一标识
    patientunitstayid,
    aki_diagnosis_7days,
    aki_diagnosis_48hrs,
    final_aki_diagnosis,
    aki_diagnosis_time
FROM
    earliest_aki
WHERE
    -- 只选择最早的 AKI 诊断记录且final_aki_diagnosis为1
    row_num = 1
    AND final_aki_diagnosis = 1
    -- 过滤掉诊断时间为负的样本
    AND aki_diagnosis_time >= 0
ORDER BY
    uniquepid, aki_diagnosis_time;
