-- aki_final.sql
-- 删除旧的结果表
DROP TABLE IF EXISTS aki_final;

-- 创建新的结果表
CREATE TABLE aki_final AS
-- 结合肌酐、尿量、RRT 和AKI状态
WITH combined_aki AS (
    SELECT
        cr.hadm_id,
        cr.stay_id,
        cr.aki_status AS aki_status_cr,
        uo.aki_status AS aki_status_uo,
        crrt.rrt_in_icu,
        cr.charttime AS cr_charttime, -- 记录肌酐的时间戳
        uo.charttime AS uo_charttime, -- 记录尿量的时间戳
        crrt.charttime AS rrt_charttime -- 记录RRT的时间戳
    FROM
        aki_cr cr
        LEFT JOIN aki_uo uo ON cr.stay_id = uo.stay_id -- 连接尿量 AKI 数据
        LEFT JOIN icu_crrt crrt ON cr.stay_id = crrt.stay_id -- 引入 RRT 信息
),
-- 确保每个患者只有一个最早的 AKI 判断
earliest_aki AS (
SELECT
    hadm_id,
    stay_id,
    CASE WHEN rrt_in_icu = TRUE THEN
        'RRT'
    WHEN aki_status_cr = 'AKI-Cr within 48hr' OR aki_status_cr = 'AKI-Cr within 7day' THEN
        'Cr'
    WHEN aki_status_uo = 'AKI-UO' THEN
        'UO'
    ELSE
        NULL
    END AS aki_method, -- 根据优先级判定 AKI 判断方法
    LEAST(COALESCE(rrt_charttime, '9999-12-31'), -- RRT 时间戳
    COALESCE(cr_charttime, '9999-12-31'), -- 肌酐时间戳
    COALESCE(uo_charttime, '9999-12-31') -- 尿量时间戳
) AS earliest_time -- 选择最早的时间戳
FROM
    combined_aki
),
-- 确定每个患者的最终 AKI 状态
final_aki AS (
SELECT
    hadm_id,
    stay_id,
    aki_method,
    CASE WHEN aki_method = 'RRT' THEN
        TRUE
    WHEN aki_method = 'Cr' THEN
        TRUE
    WHEN aki_method = 'UO' THEN
        TRUE
    ELSE
        FALSE
    END AS final_aki_status -- 如果符合任何标准则认为是 AKI
FROM
    earliest_aki)
    -- 最终输出患者的 AKI 状态
    SELECT DISTINCT
        hadm_id, stay_id, final_aki_status
    FROM
        final_aki
WHERE
    final_aki_status = TRUE;

-- 只保留最终被判断为 AKI 的患者
