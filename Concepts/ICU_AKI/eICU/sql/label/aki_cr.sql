DROP VIEW IF EXISTS aki_cr;
CREATE VIEW aki_cr AS
SELECT 
    b.patientunitstayid,
    b.stable_creatinine,
    p48h.peakcreat48h,
    p7d.peakcreat7d,
    CASE 
        WHEN p48h.peakcreat48h >= b.stable_creatinine + 0.3 OR p48h.peakcreat48h >= 1.5 * b.stable_creatinine THEN 'AKI within 48h'
        WHEN p7d.peakcreat7d >= 1.5 * b.stable_creatinine THEN 'AKI within 7days'
        ELSE 'No AKI'
    END AS aki_status
FROM baseline_creat_view b
LEFT JOIN peakcreat48h_view p48h ON b.patientunitstayid = p48h.patientunitstayid
LEFT JOIN peakcreat7h_view p7d ON b.patientunitstayid = p7d.patientunitstayid
ORDER BY b.patientunitstayid;
