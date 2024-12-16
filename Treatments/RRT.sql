SELECT
    aki.stay_id,
    MAX(CASE WHEN rrt.stay_id IS NOT NULL THEN 1 ELSE 0 END) AS RRT_after_aki
FROM icu_aki aki
LEFT JOIN rrt ON aki.stay_id = rrt.stay_id
    AND rrt.charttime >= aki.earliest_aki_timepoint
GROUP BY aki.stay_id
