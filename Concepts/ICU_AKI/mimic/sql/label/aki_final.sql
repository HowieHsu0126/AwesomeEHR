-- 删除旧的结果表
DROP TABLE IF EXISTS aki_final;

-- 创建新的结果表
CREATE TABLE aki_final AS
-- 检查患者是否在ICU期间接受了RRT
WITH icu_crrt AS (
    SELECT
        crrt.stay_id,
        TRUE AS rrt_in_icu
    FROM
        mimiciv_derived.crrt crrt
        JOIN mimiciv_icu.icustays ie ON crrt.stay_id = ie.stay_id
    WHERE
        crrt.crrt_mode IS NOT NULL
        AND crrt.charttime >= ie.intime -- 只考虑ICU期间的RRT治疗
),
-- 结合肌酐和尿量的AKI状态
combined_aki AS (
SELECT
    cr.hadm_id,
    cr.stay_id,
    cr.aki_status AS aki_status_cr,
    uo.aki_status AS aki_status_uo,
    crrt.rrt_in_icu -- 只考虑 ICU 期间接受了 RRT 的情况
FROM
    aki_cr cr
    LEFT JOIN aki_uo uo ON cr.stay_id = uo.stay_id -- 确保正确连接 aki_uo 表
        LEFT JOIN icu_crrt crrt ON cr.stay_id = crrt.stay_id
),
-- 汇总所有AKI诊断信息
final_aki AS (
SELECT
    cr.hadm_id,
    cr.stay_id,
    aki_status_cr,
    aki_status_uo,
    rrt_in_icu
FROM
    combined_aki cr)
    -- 最终结果：整合所有AKI信息并根据 RRT 状态调整 AKI 最终诊断
    SELECT DISTINCT
        hadm_id, stay_id, rrt_in_icu, aki_status_cr, aki_status_uo, CASE WHEN rrt_in_icu = TRUE OR aki_status_cr = 'AKI-Cr within 48hr' OR aki_status_cr = 'AKI-Cr within 7day' OR aki_status_uo = 'AKI-UO' THEN
            TRUE -- 如果符合肌酐、尿量或RRT标准，则认定为ICU获得性AKI
        ELSE
            FALSE -- 否则为没有AKI
        END AS final_aki_status
    FROM
        final_aki
WHERE
    rrt_in_icu = TRUE OR -- 保留进ICU后接受RRT的患者
    aki_status_cr IN ('AKI-Cr within 48hr', 'AKI-Cr within 7day') OR aki_status_uo = 'AKI-UO'; -- 保留符合肌酐或尿量标准的患者

