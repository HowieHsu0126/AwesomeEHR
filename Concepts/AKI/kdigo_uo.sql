DROP TABLE IF EXISTS mimiciv_derived.kdigo_uo;
CREATE TABLE mimiciv_derived.kdigo_uo AS
with ur_stg as
(
  select pat.subject_id, io.stay_id, io.charttime
  -- we have joined each row to all rows preceding within 24 hours
  -- we can now sum these rows to get total UO over the last 24 hours
  -- we can use case statements to restrict it to only the last 6/12 hours
  -- therefore we have three sums:
  -- 1) over a 6 hour period
  -- 2) over a 12 hour period
  -- 3) over a 24 hour period
  -- note that we assume data charted at charttime corresponds to 1 hour of UO
  -- therefore we use '5' and '11' to restrict the period, rather than 6/12
  -- this assumption may overestimate UO rate when documentation is done less than hourly

  -- 6 hours
  , sum(case when iosum.charttime >= io.charttime - interval '6 hours'
      then iosum.urineoutput
    else null end) as UrineOutput_6hr
  -- 12 hours
  , sum(case when iosum.charttime >= io.charttime - interval '12 hours'
      then iosum.urineoutput
    else null end) as UrineOutput_12hr
  -- 24 hours
  , sum(iosum.urineoutput) as UrineOutput_24hr
    
  -- calculate the number of hours over which we've tabulated UO
  , ROUND(CAST(
      EXTRACT(EPOCH FROM (io.charttime - 
        MIN(case when iosum.charttime >= io.charttime - interval '6 hours'
          then iosum.charttime
        else null end)))/3600.0 AS NUMERIC), 4)
     AS uo_tm_6hr
  -- repeat extraction for 12 hours and 24 hours
  , ROUND(CAST(
      EXTRACT(EPOCH FROM (io.charttime - 
        MIN(case when iosum.charttime >= io.charttime - interval '12 hours'
          then iosum.charttime
        else null end)))/3600.0 AS NUMERIC), 4)
   AS uo_tm_12hr
  , ROUND(CAST(
      EXTRACT(EPOCH FROM (io.charttime - MIN(iosum.charttime)))/3600.0
   AS NUMERIC), 4) AS uo_tm_24hr
  from mimiciv_derived.urine_output io
  -- this join gives all UO measurements over the 24 hours preceding this row
  -- 通过 icustays 表连接到 patients 表获取 subject_id
  inner join mimiciv_icu.icustays icu
    on io.stay_id = icu.stay_id
  inner join mimiciv_hosp.patients pat
    on icu.subject_id = pat.subject_id
  -- 连接24小时内的尿量记录
  left join mimiciv_derived.urine_output iosum
    on  io.stay_id = iosum.stay_id
    and iosum.charttime <= io.charttime
    and iosum.charttime >= io.charttime - interval '24 hours'
  group by pat.subject_id, io.stay_id, io.charttime
),
-- 获取每个患者的第一条记录
first_records as (
  select *,
         ROW_NUMBER() OVER (PARTITION BY subject_id ORDER BY charttime) as rn
  from ur_stg
)
select
  fr.subject_id
, fr.stay_id
, fr.charttime
, wd.weight
, fr.urineoutput_6hr
, fr.urineoutput_12hr
, fr.urineoutput_24hr
-- calculate rates - adding 1 hour as we assume data charted at 10:00 corresponds to previous hour
, ROUND(CAST((fr.UrineOutput_6hr/wd.weight/(uo_tm_6hr+1))   AS NUMERIC), 4) AS uo_rt_6hr
, ROUND(CAST((fr.UrineOutput_12hr/wd.weight/(uo_tm_12hr+1)) AS NUMERIC), 4) AS uo_rt_12hr
, ROUND(CAST((fr.UrineOutput_24hr/wd.weight/(uo_tm_24hr+1)) AS NUMERIC), 4) AS uo_rt_24hr
-- number of hours between current UO time and earliest charted UO within the X hour window
, uo_tm_6hr
, uo_tm_12hr
, uo_tm_24hr
from first_records fr
left join mimiciv_derived.weight_durations wd
  on  fr.stay_id = wd.stay_id
  and fr.charttime >= wd.starttime
  and fr.charttime <  wd.endtime
where fr.rn = 1  -- 只保留每个患者的第一条记录
;

-- 添加主键和索引以提高查询性能
ALTER TABLE mimiciv_derived.kdigo_uo 
ADD PRIMARY KEY (subject_id);

-- 为常用查询字段创建索引
CREATE INDEX idx_kdigo_uo_subject_id ON mimiciv_derived.kdigo_uo(subject_id);
CREATE INDEX idx_kdigo_uo_stay_id ON mimiciv_derived.kdigo_uo(stay_id);
CREATE INDEX idx_kdigo_uo_charttime ON mimiciv_derived.kdigo_uo(charttime);