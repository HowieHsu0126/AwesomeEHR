COPY (
SELECT
  ie.hadm_id,
  -- 计算从入院到记录时间的小时数
  FLOOR(EXTRACT(epoch FROM (uo.charttime - ha.admittime)) / 3600) AS hour,
  AVG(uo.urineoutput) AS urineoutput -- 每小时尿量
FROM mimiciv_hosp.admissions ha
INNER JOIN mimiciv_icu.icustays ie ON ha.hadm_id = ie.hadm_id
INNER JOIN icu_aki aki ON ha.hadm_id = aki.hadm_id
LEFT JOIN mimiciv_derived.urine_output uo ON ie.stay_id = uo.stay_id
WHERE uo.charttime BETWEEN ha.admittime AND aki_time
GROUP BY ie.hadm_id, hour
ORDER BY ie.hadm_id, hour
) TO '/home/hwxu/Projects/Dataset/PKU/AMIA/Input/raw/UO.csv' WITH CSV HEADER;