-- KDIGO
    -- Cretinine
-- \i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/eICU/sql/label/cr_48h.sql'
-- \i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/eICU/sql/label/cr_7d.sql'
-- \i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/eICU/sql/label/cr_baseline.sql'
\i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/eICU/sql/label/aki_cr.sql'
    -- Urine Output
-- \i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/eICU/sql/label/patient_weight.sql'
-- \i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/eICU/sql/label/pivoted_uo.sql'
\i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/eICU/sql/label/aki_uo.sql'
-- RRT
\i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/eICU/sql/label/aki_rrt.sql'
-- Final Decision
\i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/eICU/sql/label/aki_final.sql'

-- 主要内容：主程序文件，按顺序执行所有AKI相关的SQL查询，
-- 包括肌酐值、尿量和RRT三个维度的判断