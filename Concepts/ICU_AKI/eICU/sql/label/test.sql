SELECT COUNT(DISTINCT patientunitstayid) FROM aki_cr;  -- 确认肌酐记录中的患者数量
SELECT COUNT(DISTINCT patientunitstayid) FROM aki_uo;  -- 确认尿量记录中的患者数量
SELECT COUNT(DISTINCT patientunitstayid) FROM aki_rrt;  -- 确认透析记录中的患者数量
