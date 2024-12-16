-- 目的: 计算患者在ICU入住后48小时内的最高肌酐值。
-- 操作: 通过筛选48小时内的肌酐实验室结果，并使用ROW_NUMBER()函数对结果进行排序，以确定每个患者的最高肌酐值及其对应的时间偏移量。
CREATE VIEW peakcreat48h_view AS
SELECT
    patientunitstayid,
    labresultoffset AS peakcreat48h_offset,
    labresult AS peakcreat48h,
    ROW_NUMBER() OVER (PARTITION BY patientunitstayid ORDER BY labresult DESC) AS position
FROM
    eicu_crd.lab
WHERE
    labname LIKE 'creatinine%'
    AND labresultoffset >= 0
    AND labresultoffset <= (48 * 60); -- Within 48hrs
