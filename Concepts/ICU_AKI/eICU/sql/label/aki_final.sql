-- 删除已存在的最终结果表以避免重复
DROP TABLE IF EXISTS final_aki_status;

-- 创建最终AKI状态表，包含最早诊断时间以及各条件下的判断标志
CREATE TABLE final_aki_status AS
WITH combined AS (
    SELECT
        COALESCE(ac.patientunitstayid, uo.patientunitstayid, rrt.patientunitstayid) AS patientunitstayid,
        ac.aki_diagnosis_time AS cr_offset,
        uo.chartoffset AS uo_offset,
        rrt.treatmentoffset AS rrt_offset,
        -- 来自 aki_cr 表的判断（48小时与7天各自独立判断）
        CASE WHEN ac.aki_diagnosis_48hrs = 1 THEN TRUE ELSE FALSE END AS aki_cr_48h,
        CASE WHEN ac.aki_diagnosis_7days = 1 THEN TRUE ELSE FALSE END AS aki_cr_7d,
        -- 来自 aki_uo 表的判断
        CASE WHEN uo.aki_status = 'AKI' THEN TRUE ELSE FALSE END AS aki_uo,
        -- 来自 aki_rrt 表的判断：只要存在记录则为 True
        CASE WHEN rrt.patientunitstayid IS NOT NULL THEN TRUE ELSE FALSE END AS aki_rrt
    FROM aki_cr ac
    FULL OUTER JOIN aki_uo uo
         ON ac.patientunitstayid = uo.patientunitstayid
    FULL OUTER JOIN aki_rrt rrt
         ON COALESCE(ac.patientunitstayid, uo.patientunitstayid) = rrt.patientunitstayid
    WHERE ((ac.aki_diagnosis_48hrs = 1 OR ac.aki_diagnosis_7days = 1)
           OR (uo.aki_status = 'AKI')
           OR (rrt.patientunitstayid IS NOT NULL)
          )
)
SELECT DISTINCT
    patientunitstayid,
    -- 计算最早的 AKI 诊断时间：
    -- 这里利用 LEAST 对来自 aki_cr（48h 和 7d）、aki_uo 和 aki_rrt 的时间字段进行比较。
    -- 为了防止 NULL 值干扰比较，采用 COALESCE 将 NULL 转为一个很大数（此处用 99999999），
    -- 最后用 MIN 聚合确保同一患者若有多条记录也只取最早时间。
    CASE 
       WHEN MIN(LEAST(
          COALESCE(cr_offset, 99999999),
          COALESCE(uo_offset, 99999999),
          COALESCE(rrt_offset, 99999999)
       )) = 99999999 THEN NULL
       ELSE MIN(LEAST(
          COALESCE(cr_offset, 99999999),
          COALESCE(uo_offset, 99999999),
          COALESCE(rrt_offset, 99999999)
       ))
    END AS earliest_aki_diagnosis_time,
    -- 分别返回各条件下的判断标志
    bool_or(aki_rrt)    AS aki_rrt,
    bool_or(aki_cr_48h) AS aki_cr_48h,
    bool_or(aki_cr_7d)  AS aki_cr_7d,
    bool_or(aki_uo)     AS aki_uo
FROM combined
GROUP BY patientunitstayid
ORDER BY patientunitstayid;
