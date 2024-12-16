-- 删除已存在的表格以避免重复
DROP TABLE IF EXISTS final_aki_status;

-- 创建最终AKI状态表，专注于ICU获得性AKI病人
CREATE TABLE final_aki_status AS
SELECT DISTINCT
    ac.patientunitstayid
FROM aki_cr ac
JOIN aki_uo uo ON ac.patientunitstayid = uo.patientunitstayid
-- LEFT JOIN aki_rrt rrt ON ac.patientunitstayid = rrt.patientunitstayid
WHERE (ac.aki_status = 'AKI within 48h' OR ac.aki_status = 'AKI within 7days' OR uo.aki_status = 'AKI')
    --   AND rrt.patientunitstayid IS NULL
GROUP BY ac.patientunitstayid
ORDER BY ac.patientunitstayid;

-- -- 将最终的ICU获得性AKI病人的patientunitstayid导出到CSV文件
-- COPY final_aki_status TO '/home/hwxu/Projects/Dataset/PKU/eICU/csv/aki_eicu_icu_acquired.csv' DELIMITER ',' CSV HEADER;
