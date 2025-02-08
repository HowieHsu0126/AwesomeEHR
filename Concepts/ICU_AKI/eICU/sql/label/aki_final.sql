DROP TABLE IF EXISTS final_aki_status;

CREATE TABLE final_aki_status AS
SELECT
    ac.patientunitstayid,
    ac.final_aki_diagnosis AS aki_cr_diagnosis,
    uo.aki_status AS aki_uo_status,
    CASE WHEN rrt.patientunitstayid IS NOT NULL THEN 1 ELSE 0 END AS aki_rrt_status  -- 使用CASE表达式处理NULL判断
FROM aki_cr ac
LEFT JOIN aki_uo uo ON ac.patientunitstayid = uo.patientunitstayid
LEFT JOIN aki_rrt rrt ON ac.patientunitstayid = rrt.patientunitstayid
WHERE
    (ac.final_aki_diagnosis = 1  -- 肌酐标准为AKI
    OR uo.aki_status = 'AKI'  -- 尿量标准为AKI
    OR rrt.patientunitstayid IS NOT NULL)  -- 透析治疗记录存在
GROUP BY ac.patientunitstayid, ac.final_aki_diagnosis, uo.aki_status, rrt.patientunitstayid  -- 必须按这些字段分组
ORDER BY ac.patientunitstayid;
