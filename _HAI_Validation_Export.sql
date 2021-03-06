USE [EQuIS]
GO
/****** Object:  UserDefinedFunction [v533].[analytical_results_Validation]    Script Date: 11/13/2017 11:20:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure  [HAI].[sp_HAI_Validation_Export]
(
  @facility_id integer,
  @start_date datetime = '1900-01-01 00:00:00',
  @end_date datetime = '2079-06-01 23:59:59', 
  @task_codes varchar(4000) = null,
  @sdg_names varchar(4000) = null,
  @analytic_methods varchar(4000) = null,
  @analyte_groups varchar(4000) = null,
  @reporting_limit varchar(30) = null
)  
as
begin

  set @nd_multiplier = coalesce(@nd_multiplier,1.0)
  if len(ltrim(@reporting_unit)) = 0 set @reporting_unit = null



  -- FB.11499: inclusive date range
  set @start_date = convert(varchar(10),@start_date,120) + ' 00:00:00'
  set @end_date = convert(varchar(10),@end_date,120) + ' 23:59:59'



  -- tasks
  declare @task table (task_code varchar(20))
  insert into @task select cast(value as varchar(20)) from fn_split(@task_codes)
  if (select count(*) from @task) = 0 insert into @task values ( null )

  -- sdgs
  declare @sdg table (sdg_name varchar(20))
  insert into @sdg select cast(value as varchar(20)) from fn_split(@sdg_names)
  if (select count(*) from @sdg) = 0 insert into @sdg values ( null )

  -- analytic methods
  declare @anlmth table (analytic_method varchar(35))
  insert into @anlmth select cast(value as varchar(35)) from fn_split(@analytic_methods)
  if (select count(*) from @anlmth) = 0 insert into @anlmth values ( null )



 

select 
  	s.facility_id
	,s.sys_loc_code
    ,s.sys_sample_code
	,s.sample_name
    ,s.sample_date
    ,s.sample_type_code
    ,s.matrix_code
    ,fs.field_sdg
    ,t.lab_matrix_code
    ,t.analytic_method
    ,t.prep_date
    ,t.analysis_date
    ,t.column_number
    ,t.fraction
    ,t.basis
    ,t.test_type
    ,t.leachate_method
    ,t.leachate_date
    ,t.lab_sdg
	,a.chemical_name as chemical_name
--	,c.chemical_name
    ,a.organic_yn
    ,s.parent_sample_code
	,t.lab_sample_id
	,t.instrument_id
	,t.dilution_factor
	,q.qc_spike_recovery
	,tb.test_batch_id
--	,tb.test_batch_type
--	Insert blank column
	,NULL 
--	This begins the dt_result fields
    ,r.test_id
    ,r.cas_rn
    ,r.result_text
    ,r.result_numeric
	,r.result_error_delta
    ,r.result_type_code
	,r.stat_result
    ,r.reportable_result
    ,r.detect_flag
    ,r.lab_qualifiers
    ,r.validator_qualifiers
    ,r.approval_code
    ,r.interpreted_qualifiers
	,r.dqm_qualifiers
	,r.approval_a
	,r.approval_b
	,r.approval_c
	,r.approval_d
	,r.hold_time_status
    ,r.method_detection_limit
    ,r.reporting_detection_limit
    ,r.quantitation_limit
    ,r.result_unit
    ,r.detection_limit_unit
	,r.tic_retention_time
	,r.custom_field_1
	,r.custom_field_2
	,r.custom_field_3
	,r.remark
	,r.dqm_remark
	,r.desorb_efficiency
	,r.value_type
	,r.stat_type
	,r.custom_field_4
	,r.custom_field_5
	,r.validated_yn
from dt_sample s
    left outer join dt_field_sample fs on (s.facility_id = fs.facility_id and s.sample_id = fs.sample_id)
		inner join dt_test t on (s.sample_id = t.sample_id and s.facility_id = t.facility_id)
		inner join dt_result r on (t.test_id = r.test_id and t.facility_id = r.facility_id)
		left outer join dt_result_qc q on (r.cas_rn = q.cas_rn and r.test_id = q.test_id and r.facility_id = q.facility_id)
		inner join rt_analyte a on (r.cas_rn = a.cas_rn)
		left join dt_location loc on s.facility_id = loc.facility_id and s.sys_loc_code = loc.sys_loc_code
		left join (select facility_id, test_id, test_batch_type, test_batch_id, ebatch from at_test_batch_assign
			where (facility_id = @facility_id) and (test_batch_type = 'ANALYSIS')) tb
			on t.facility_id = tb.facility_id and t.test_id = tb.test_id
    inner join @task tsk on coalesce(s.task_code,' ') = coalesce(tsk.task_code,s.task_code,' ')
    -- if field_sdg and lag_sdg are both non-null and different, then this filter is ambiguous
    inner join @sdg sdg on coalesce(fs.field_sdg, t.lab_sdg, ' ') = coalesce(sdg.sdg_name,fs.field_sdg,t.lab_sdg,' ')
    inner join @anlmth am on t.analytic_method = coalesce(am.analytic_method,t.analytic_method)


		left outer join vw_location l on s.facility_id = l.facility_id and s.sys_loc_code = l.sys_loc_code
		left outer join dt_task ts on (s.task_code = ts.task_code and s.facility_id = ts.facility_id)
where ((s.sample_date between @start_date and @end_date) or s.sample_date is null)

       
  
return

end

