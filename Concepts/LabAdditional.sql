SELECT
    ie.stay_id
    -- 计算从进入ICU到记录时间的小时数
    , FLOOR(EXTRACT(epoch FROM (le.charttime - ie.intime)) / 3600) AS hour
    , AVG(hematocrit) as hematocrit
    , AVG(hemoglobin) as hemoglobin
    , AVG(platelet) as platelets
    , AVG(wbc) as wbc
FROM mimiciv_icu.icustays ie
LEFT JOIN complete_blood_count le
    ON le.subject_id = ie.subject_id
    AND le.charttime >= DATETIME_SUB(ie.intime, INTERVAL '6' HOUR)
    AND le.charttime <= ie.intime + INTERVAL '24 hours' -- 确保数据在首24小时内
GROUP BY ie.stay_id, hour
ORDER BY ie.stay_id, hour;