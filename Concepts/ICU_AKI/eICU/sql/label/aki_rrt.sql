-- 删除旧的 RRT 结果表
DROP TABLE IF EXISTS aki_rrt;

-- 创建一个视图，以识别在ICU入住前就已接受替代性肾脏治疗的慢性AKI患者
CREATE TABLE aki_rrt AS
WITH ranked_treatments AS (
    SELECT
        t.patientunitstayid,
        p.uniquepid,  -- 通过 patient 表获取 uniquepid 唯一标识患者
        t.treatmentstring,
        t.treatmentoffset,
        ROW_NUMBER() OVER (PARTITION BY t.patientunitstayid ORDER BY t.treatmentoffset ASC) AS row_num
    FROM
        eicu_crd.treatment t
    JOIN
        eicu_crd.patient p ON t.patientunitstayid = p.patientunitstayid  -- 连接 patient 表获取 uniquepid
    WHERE
        (LOWER(t.treatmentstring) LIKE '%rrt%'
        OR LOWER(t.treatmentstring) LIKE '%dialysis%'
        OR LOWER(t.treatmentstring) LIKE '%ultrafiltration%'
        OR LOWER(t.treatmentstring) LIKE '%cavhd%'
        OR LOWER(t.treatmentstring) LIKE '%cvvh%'
        OR LOWER(t.treatmentstring) LIKE '%sled%')
        AND LOWER(t.treatmentstring) LIKE '%chronic%'  -- 只选择慢性AKI患者的记录
)
SELECT
    uniquepid,  -- 返回 uniquepid 作为患者唯一标识
    patientunitstayid,
    treatmentoffset
FROM
    ranked_treatments
WHERE
    row_num = 1  -- 只选择每个患者的最早记录
    -- 过滤掉诊断时间为负的样本
    AND treatmentoffset >= 0
ORDER BY
    uniquepid, treatmentoffset;
