-- 从aki_final表中获取AKI诊断时间。
-- 从chartevents表中获取与电解质项目相关的最近测量值。
-- 确保每个患者的电解质测量值是在AKI诊断时间之前48小时内的最近一次测量。
-- 如果48小时内的测量值全部为null，则显示null。
-- 创建一个新表来存储电解质数据
-- 创建电解质数据表
DROP TABLE IF EXISTS electrolyte_data;
CREATE TABLE electrolyte_data AS
-- measurements 子查询：选取每个患者的所有电解质测量值，只考虑AKI诊断时间之前48小时内的测量
WITH measurements AS (
    SELECT 
        ce.stay_id AS patientunitstayid,
        ce.itemid,
        ce.value,
        ce.charttime,
        a.earliest_aki_timepoint
    FROM 
        mimiciv_icu.chartevents ce
    JOIN 
        aki_final a ON ce.stay_id = a.patientunitstayid
    WHERE 
        ce.itemid IN (220645, 227442, 220602, 225667, 225677, 220635, 227443) -- 指定的电解质项目ID
        AND ce.charttime BETWEEN a.earliest_aki_timepoint - INTERVAL '48 hours' AND a.earliest_aki_timepoint
),
-- null_check 子查询：检查每个患者在AKI诊断前48小时内是否所有电解质测量值均为null
null_check AS (
    SELECT 
        patientunitstayid,
        itemid,
        COUNT(value) AS non_null_count
    FROM measurements
    GROUP BY patientunitstayid, itemid
),
-- filtered_measurements 子查询：处理连续空值问题，确保每个测量值都是非空的
filtered_measurements AS (
    SELECT 
        m.patientunitstayid,
        m.itemid,
        CASE 
            WHEN nc.non_null_count = 0 THEN NULL
            ELSE FIRST_VALUE(m.value) OVER (
                PARTITION BY m.patientunitstayid, m.itemid 
                ORDER BY m.charttime DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )
        END AS value
    FROM measurements m
    JOIN null_check nc ON m.patientunitstayid = nc.patientunitstayid AND m.itemid = nc.itemid
)
-- 最终选择每个患者的最近非空电解质测量值
SELECT 
    patientunitstayid,
    MAX(CASE WHEN itemid = 220645 THEN value END) AS sodium,
    MAX(CASE WHEN itemid = 227442 THEN value END) AS potassium,
    MAX(CASE WHEN itemid = 220602 THEN value END) AS chloride,
    MAX(CASE WHEN itemid = 225667 THEN value END) AS calcium,
    MAX(CASE WHEN itemid = 225677 THEN value END) AS phosphate,
    MAX(CASE WHEN itemid = 220635 THEN value END) AS magnesium,
    MAX(CASE WHEN itemid = 227443 THEN value END) AS bicarbonate
FROM 
    filtered_measurements
GROUP BY 
    patientunitstayid;

-- 将新表导出为CSV文件
COPY electrolyte_data TO '/home/hwxu/Projects/Dataset/PKU/mimic/csv/electrolyte_data.csv' DELIMITER ',' CSV HEADER;

-- 创建合并后的表
DROP TABLE IF EXISTS merged_data;
CREATE TABLE merged_data AS
SELECT 
    a.*,
    e.sodium,
    e.potassium,
    e.chloride,
    e.calcium,
    e.phosphate,
    e.magnesium,
    e.bicarbonate
FROM 
    aki_final a
JOIN 
    electrolyte_data e ON a.patientunitstayid = e.patientunitstayid;

-- 将合并后的表导出为CSV文件
COPY merged_data TO '/home/hwxu/Projects/Dataset/PKU/mimic/csv/merged_data.csv' DELIMITER ',' CSV HEADER;
