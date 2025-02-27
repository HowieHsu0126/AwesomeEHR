DROP TABLE IF EXISTS pivoted_uo CASCADE;
CREATE TABLE pivoted_uo AS
with uo as
(
select
  patientunitstayid
  , intakeoutputoffset
  , outputtotal
  , cellvaluenumeric
  , case
    when cellpath not like 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|%' then 0
    when cellpath in
    (
      'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine' -- most data is here
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|3 way foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|3 Way Foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Actual Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Adjusted total UO NOC end shift'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|BRP (urine)'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|BRP (Urine)'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|condome cath urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|diaper urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|inc of urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incontient urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Incontient urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Incontient Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incontinence of urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Incontinence-urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incontinence/ voids urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incontinent of urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|INCONTINENT OF URINE'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Incontinent UOP'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incontinent urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Incontinent (urine)'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Incontinent Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incontinent urine counts'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incont of urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incont. of urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incont. of urine count'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incont. of urine count'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incont urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|incont. urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Incont. urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Incont. Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|inc urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|inc. urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Inc. urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Inc Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|indwelling foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Indwelling Foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Catheter-Foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Catheterization Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Cath UOP'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|straight cath urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Cath Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|strait cath Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Suprapubic Urine Output'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|true urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|True Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|True Urine out'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|unmeasured urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Unmeasured Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|unmeasured urine output'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urethal Catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urethral Catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|urinary output 7AM - 7 PM'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|urinary output 7AM-7PM'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|URINE'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|URINE'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|URINE CATHETER'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Intermittent/Straight Cath (mL)'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|straightcath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|straight cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight  cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight  Cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Cath''d'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|straight cath daily'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|straight cathed'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Cathed'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Catheter-Foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight catheterization'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Catheterization Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Catheter Output'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Catheter-Straight Catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|straight cath ml''s'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight cath ml''s'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Cath Q6hrs'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight caths'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Cath UOP'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|straight cath urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Straight Cath Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-straight cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine-straight cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Straight Cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Condom Catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|condom catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|condome cath urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|condom cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Condom Cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|CONDOM CATHETER OUTPUT'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine via condom catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine-foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine- foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine- Foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine foley catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine, L neph:'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine (measured)'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|urine output'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-external catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Foley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-FOLEY'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Foley cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-FOLEY CATH'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-foley catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Foley Catheter'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-FOLEY CATHETER'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Foley Output'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Fpley'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Ileoconduit'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-left nephrostomy'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Left Nephrostomy'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Left Nephrostomy Tube'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-LEFT PCN TUBE'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-L Nephrostomy'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-L Nephrostomy Tube'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Nephrostomy'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-right nephrostomy'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-RIGHT Nephrouretero Stent Urine Output'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-R nephrostomy'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-R Nephrostomy'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-R. Nephrostomy'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-R Nephrostomy Tube'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Rt Nephrectomy'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-stent'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-straight cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-suprapubic'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Texas Cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Urine'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output-Urine Output'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine, R neph:'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine-straight cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Straight Cath'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|urine (void)'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine- void'
    , 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine, void:'
    ) then 1
    when cellpath ilike 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|foley%'
    AND lower(cellpath) not like '%pacu%'
    AND lower(cellpath) not like '%or%'
    AND lower(cellpath) not like '%ir%'
      then 1
    when cellpath like 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Output%Urinary Catheter%' then 1
    when cellpath like 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Output%Urethral Catheter%' then 1
    when cellpath like 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urine Output (mL)%' then 1
    when cellpath like 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Output%External Urethral%' then 1
    when cellpath like 'flowsheet|Flowsheet Cell Labels|I&O|Output (ml)|Urinary Catheter Output%' then 1
  else 0 end as cellpath_is_uo
from eicu_crd.intakeoutput
)
select
  patientunitstayid
  , intakeoutputoffset as chartoffset
  , max(outputtotal) as outputtotal
  , sum(cellvaluenumeric) as urineoutput
from uo
where uo.cellpath_is_uo = 1
and cellvaluenumeric is not null
group by patientunitstayid, intakeoutputoffset
order by patientunitstayid, intakeoutputoffset;

-- 主要内容：处理患者的尿量数据，整合各种不同记录方式的尿量信息，
-- 统一格式便于后续分析