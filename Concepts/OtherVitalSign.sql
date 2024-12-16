-- ICU中前24小时内每个小时的尿量
SELECT
    ie.stay_id,
    -- 计算从进入ICU到记录时间的小时数
    FLOOR(EXTRACT(epoch FROM (ce.charttime - ie.intime)) / 3600) AS hour,
    AVG(ce.sbp) AS sbp, -- 每小时收缩压
    AVG(ce.dbp) AS dbp, -- 每小时舒张压
    AVG(ce.mbp) AS mbp, -- 每小时平均动脉压
    AVG(resp_rate) AS resp_rate -- 每小时呼吸频率 
FROM mimiciv_icu.icustays ie
LEFT JOIN vitalsign ce ON ie.stay_id = ce.stay_id
AND ce.charttime >= ie.intime
AND ce.charttime <= ie.intime + INTERVAL '24 hours' -- 确保数据在首24小时内
GROUP BY ie.stay_id, hour
ORDER BY ie.stay_id, hour;
