SELECT
    ad.subject_id,
    ad.hadm_id,
    FLOOR(DATETIME_DIFF(ad.admittime, DATETIME(pa.anchor_year, 1, 1, 0, 0, 0), 'YEAR') + pa.anchor_age) AS age,
    pa.gender
FROM mimiciv_hosp.admissions ad
INNER JOIN mimiciv_hosp.patients pa
ON ad.subject_id = pa.subject_id
WHERE FLOOR(DATETIME_DIFF(ad.admittime, DATETIME(pa.anchor_year, 1, 1, 0, 0, 0), 'YEAR') + pa.anchor_age) BETWEEN 16 AND 89;
