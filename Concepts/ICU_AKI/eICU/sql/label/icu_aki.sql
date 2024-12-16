-- SELECT *
-- FROM aki_final
-- WHERE final_aki_status = 'ICU Acquired AKI';
SELECT DISTINCT ON (subject_id) *
FROM aki_final
WHERE final_aki_status = 'ICU Acquired AKI'
ORDER BY subject_id;
