\i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/mimic/sql/label/aki_cr.sql'
\i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/mimic/sql/label/aki_uo.sql'
\i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/mimic/sql/label/aki_rrt.sql'
\i '/data/hwxu/Dataset/PKU/AwsomeEHR/Concepts/ICU_AKI/mimic/sql/label/aki_final.sql'

-- 主要内容：主程序文件，按顺序执行所有AKI相关的SQL查询，
-- 依次处理肌酐值、尿量和RRT三个维度的判断，最后整合得到最终结果
