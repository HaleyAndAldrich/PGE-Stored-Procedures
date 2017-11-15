
use equis
go

set nocount on
go

set ansi_warnings off
go

alter procedure hai.sp_hai_PAH_TorD_RPD (
	  @facility_id int
	  ,@task_codes varchar (1000)
	 ,@target_unit varchar (10) 

	 )
	 as 
	 begin

		if object_id('tempdb..#rpd') is not null drop table #rpd

		select 
		sample_name
		,task_code
		,ra.chemical_name
		,max(case when t.fraction = 'T' then equis.unit_conversion( cast(coalesce(result_numeric,reporting_detection_limit) as float),result_unit,@target_unit, 0) end) as [Total]
		,max(case when t.fraction = 'T' then detect_flag end) as [Total_detect_flag]
		,max(case when t.fraction = 'D' then equis.unit_conversion( cast(coalesce(result_numeric,reporting_detection_limit) as float),result_unit,@target_unit, 0) end )as [Dissolved]
		,max(case when t.fraction = 'D' then detect_flag end )as [Dissolved_detect_flag]

		,@target_unit as report_unit
		,cast(null as decimal(10,2)) as [RPD (%)]
		into #RPD
		from dt_result r
		inner join rt_analyte ra on r.cas_rn= ra.cas_rn
		inner join dt_test t on r.facility_id = t.facility_id and r.test_id = t.test_id
		inner join dt_sample s on t.facility_id = s.facility_id and t.sample_id = s.sample_id
		inner join (select cas_rn, total_or_dissolved as fraction, analytic_method, chemical_name from rt_mth_anl_group_member where method_analyte_group_code in ('pge GW pahs (dissolved)','pge gw pahs (total)')) mg
		on r.cas_rn = mg.cas_rn and t.fraction = mg.fraction and t.analytic_method = mg.analytic_method
		and r.facility_id = @facility_id
		and task_code in(select cast(value as varchar (100)) from fn_split(@task_codes))

		group by sample_name,  task_code, ra.chemical_name

		update #RPD
		set [RPD (%)] = abs ([total]  - [dissolved] )/(([total]  + [dissolved] )/cast(2.0000 as float)) *100  

		--delete #RPD
		--where [Cyanide (free) detect_flag] = 'n' and [Cyanide_detect_flag] = 'n'

		select * from #RPD

		if object_id('tempdb..#rpd') is not null drop table #rpd
	end