DROP TABLE IF EXISTS eicu_crd.trauma_comorbidities;
CREATE TABLE eicu_crd.trauma_comorbidities AS

WITH trauma_patients AS (
    -- 获取已确定的创伤患者
    SELECT uniquepid
    FROM eicu_crd.trauma_patients
),

patient_diagnoses AS (
    -- 连接患者表和诊断信息
    SELECT DISTINCT 
        t.uniquepid,
        a.admitdxname
    FROM trauma_patients t
    JOIN eicu_crd.patient p ON t.uniquepid = p.uniquepid
    JOIN eicu_crd.admissiondx a ON p.patientunitstayid = a.patientunitstayid
)

SELECT 
    pd.uniquepid,
    -- 充血性心力衰竭
    MAX(CASE WHEN pd.admitdxname IN (
        'CHF, congestive heart failure',
        'Shock, cardiogenic',
        'Cardiomyopathy'
    ) THEN 1 ELSE 0 END) as chf,
    
    -- 外周血管疾病
    MAX(CASE WHEN pd.admitdxname IN (
        'Thrombus, arterial',
        'Thrombosis, vascular (deep vein)',
        'Graft, femoral-popliteal bypass',
        'Graft, aorto-femoral bypass',
        'Graft, femoral-femoral bypass',
        'Endarterectomy, carotid',
        'Vascular medical, other',
        'Vascular surgery, other'
    ) THEN 1 ELSE 0 END) as pvd,
    
    -- 脑血管疾病
    MAX(CASE WHEN pd.admitdxname IN (
        'CVA, cerebrovascular accident/stroke',
        'Subarachnoid hemorrhage/arteriovenous malformation',
        'Subarachnoid hemorrhage/intracranial aneurysm',
        'Hemorrhage/hematoma, intracranial'
    ) THEN 1 ELSE 0 END) as cerebrovascular,
    
    -- 糖尿病
    MAX(CASE WHEN pd.admitdxname IN (
        'Diabetic ketoacidosis',
        'Diabetic hyperglycemic hyperosmolar nonketotic coma (HHNC)'
    ) THEN 1 ELSE 0 END) as diabetes,
    
    -- 慢性肺病
    MAX(CASE WHEN pd.admitdxname IN (
        'Emphysema/bronchitis',
        'Asthma',
        'Restrictive lung disease (i.e., Sarcoidosis, pulmonary fibrosis)',
        'ARDS-adult respiratory distress syndrome, non-cardiogenic pulmonary edema'
    ) THEN 1 ELSE 0 END) as chronic_pulmonary,
    
    -- 肾病
    MAX(CASE WHEN pd.admitdxname IN (
        'Renal failure, acute',
        'Renal obstruction',
        'Renal infection/abscess',
        'Kidney transplant',
        'Renal bleeding'
    ) THEN 1 ELSE 0 END) as renal_disease,
    
    -- 癌症
    MAX(CASE WHEN pd.admitdxname IN (
        'Cancer, lung',
        'Cancer, stomach',
        'Cancer, colon/rectal',
        'Cancer, esophageal',
        'Cancer, oral/sinus',
        'Cancer, oral',
        'Cancer, pancreatic',
        'Cancer, laryngeal',
        'Cancer, tracheal',
        'Cancer-stomach, surgery for',
        'Cancer-colon/rectal, surgery for',
        'Cancer-esophageal, surgery for',
        'Cancer-laryngeal/tracheal, surgery for',
        'Neoplasm, neurologic',
        'Renal neoplasm, cancer'
    ) THEN 1 ELSE 0 END) as cancer

FROM patient_diagnoses pd
GROUP BY pd.uniquepid;
