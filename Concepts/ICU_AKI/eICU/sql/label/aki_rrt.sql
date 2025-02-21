-- 删除旧的 RRT 结果表
DROP TABLE IF EXISTS aki_rrt;

-- 创建一个视图，以识别在ICU入住前就已接受替代性肾脏治疗的慢性AKI患者
CREATE TABLE aki_rrt AS
WITH all_rrt_treatments AS (
    SELECT
        t.patientunitstayid,
        p.uniquepid,
        t.treatmentstring,
        t.treatmentoffset,
        -- 标记是否为慢性/预先存在的RRT
        CASE WHEN LOWER(t.treatmentstring) LIKE '%chronic%' 
             OR LOWER(t.treatmentstring) LIKE '%pre-existing%'
             OR LOWER(t.treatmentstring) LIKE '%preexisting%'
             THEN TRUE ELSE FALSE END AS is_pre_existing,
        ROW_NUMBER() OVER (PARTITION BY t.patientunitstayid ORDER BY t.treatmentoffset ASC) AS row_num
    FROM
        eicu_crd.treatment t
    JOIN
        eicu_crd.patient p ON t.patientunitstayid = p.patientunitstayid
    WHERE
        (LOWER(t.treatmentstring) LIKE '%rrt%'
        OR LOWER(t.treatmentstring) LIKE '%dialysis%'
        OR LOWER(t.treatmentstring) LIKE '%ultrafiltration%'
        OR LOWER(t.treatmentstring) LIKE '%cavhd%'
        OR LOWER(t.treatmentstring) LIKE '%cvvh%'
        OR LOWER(t.treatmentstring) LIKE '%sled%')
)
SELECT
    uniquepid,
    patientunitstayid,
    treatmentoffset,
    is_pre_existing
FROM
    all_rrt_treatments
WHERE
    row_num = 1
    AND treatmentoffset >= 0
ORDER BY
    uniquepid, treatmentoffset;
