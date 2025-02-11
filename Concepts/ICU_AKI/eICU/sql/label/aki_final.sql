-- 删除已存在的表格以避免重复
DROP TABLE IF EXISTS final_aki_status;

-- 创建最终AKI状态表，专注于ICU获得性AKI病人
CREATE TABLE final_aki_status AS
SELECT DISTINCT
    COALESCE(ac.patientunitstayid, uo.patientunitstayid, rrt.patientunitstayid) AS patientunitstayid,
    MIN(CASE 
        WHEN ac.final_aki_diagnosis = 1 THEN ac.earliest_aki_diagnosis_time
        WHEN uo.aki_status = 'AKI' THEN uo.chartoffset
        WHEN rrt.patientunitstayid IS NOT NULL THEN rrt.treatmentoffset -- 取RRT的最早治疗时间
        ELSE NULL
    END) AS earliest_aki_diagnosis_time
FROM aki_cr ac
FULL OUTER JOIN aki_uo uo ON ac.patientunitstayid = uo.patientunitstayid
FULL OUTER JOIN aki_rrt rrt ON COALESCE(ac.patientunitstayid, uo.patientunitstayid) = rrt.patientunitstayid
WHERE (ac.final_aki_diagnosis = 1 OR uo.aki_status = 'AKI' OR rrt.patientunitstayid IS NOT NULL)
GROUP BY COALESCE(ac.patientunitstayid, uo.patientunitstayid, rrt.patientunitstayid)
ORDER BY patientunitstayid;
