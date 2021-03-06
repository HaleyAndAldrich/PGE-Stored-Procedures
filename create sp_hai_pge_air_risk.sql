USE [EQuIS]
GO
/****** Object:  StoredProcedure [HAI].[sp_hai_pge_air_risk]    Script Date: 10/9/2017 2:24:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [HAI].[sp_hai_pge_air_risk](

		 @facility_id int  = 47,
		 @subfacility_codes varchar (500),
		 @location_groups varchar (2000),
		 @locations varchar (2000) ='ppp-apams-01a',
		 @sample_type varchar(200),
		 @task_codes varchar (1000) ='potrero-pams' ,
		 @SDG varchar (2000),
		 @start_date datetime= 'jan 01 1900 12:00 AM',
		 @end_date datetime='dec 31 2050 11:59 PM',
		 @analyte_groups varchar(2000) ='pge potrero air risk vocs',
		 @cas_rns varchar (2000),
		 @analytic_methods varchar (2000),
		 @matrix_codes varchar (500),
		 @target_unit varchar(100) = 'ug/m3',
		 @limit_type varchar (10) = 'RL',
		 @action_level_codes varchar (500) ='pge-sl-potrero-aa-noncarc',
		 @user_qual_def varchar (10) ='# Q',
		 @show_val_yn varchar(10) ='y',
		 @aggregate varchar (20) = 'AVG',
		 @dispersion_factor float = 1
	
		)
	as
	begin

			declare 
				 @msg varchar (max)
				,@SQL varchar(max)

			--convert param to cas_Rn
			declare @params varchar(1000)
			SELECT @params =  ISNULL(@params,'') + chemical_name + '|' 
			from (
			select chemical_name from rt_analyte where cas_rn in (select cast(value as varchar) from fn_split(@cas_rns)))z

			set @params = left(@params,len(@params) -1)


			begin try
				IF OBJECT_ID('tempdb..#r') IS NOT NULL drop table #r
			end try
			begin catch
				select 'Cannot drop #r'
			end catch



		--Format date range parameters
			set @start_date = cast(CONVERT(varchar,@start_date,101)as DATE)
			set @end_date = CAST(convert(varchar, @end_date, 101) as date)

	

		--create main results set
			exec [hai].[sp_HAI_EQuIS_Results] 
					 @facility_id 
					,@subfacility_codes
					,@start_date  
					,@end_date  
					,@sample_type 
					,@matrix_codes 
					,@task_codes 
					,@location_groups 
					,@locations 
					,@sdg 
					,@analyte_groups 
					,@cas_rns 
					,@analytic_methods
					,@target_unit 
					,@limit_type 
					,null  --@coord_type 




			exec [rpt].[sp_HAI_GetParams] @facility_id,@analyte_groups, @params --creates ##mthgrps

		--Here's where we get the main data set
			if object_id('tempdb..#r') is not null drop table ##r
			create table #r 
			(
				 facility_id int
				,sys_sample_code varchar (50)
				,sample_name varchar (50)
				,lab_sdg varchar (20)
				,sys_loc_code varchar (20)
				,loc_name varchar (40)
				,loc_report_order varchar (10)
				,loc_group varchar (40)
				,subfacility_name varchar (40)
				,start_depth varchar (10)
				,end_depth varchar (10)
				,depth_unit varchar(10)
				,sample_depth varchar 
				,sample_datetime datetime
				,sample_date  varchar(20)
				,sample_end_datetime  datetime
				,sample_date_range  varchar(50)
				,task_code  varchar (20)
				,matrix_code varchar (10)
				,sample_type_code varchar (10)
				,compound_group varchar (30)
				,parameter_group_name  varchar (50)
				,param_group_order varchar (10)
				,mag_report_order varchar (10)
				,analytic_method varchar (20)
				,fraction varchar (10)
				,cas_rn varchar (15)
				,chemical_name varchar (255)
				,detect_flag varchar (2)
				,result_error_delta varchar (20)
				,lab_reported_result_unit varchar (10)
				,Result_Qualifier varchar (20)
				,Report_Result varchar(20)
				,Report_Result_Numeric  decimal(18,10)
				,report_unit varchar (10)
				,qualifier varchar (10)
				,detection_limit_type varchar (4)
				,nd_flag varchar (2)
				,approval_a varchar (10)
				,screening_level varchar (50)
				,screening_level_value float
				,hazard_index varchar(20)
			)


			begin try
			raiserror( 'Begin inserting #r',0,1) with nowait
			insert into #r
			select 
				 cast(r.facility_id as int) 
				,r.sys_sample_code
				,r.sample_name
				,r.lab_sdg
				,r.sys_loc_code
				,r.loc_name
				,r.loc_report_order
				,r.loc_group
				,r.subfacility_name
				,r.start_depth
				,r.end_depth
				,r.depth_unit
				,case 
					when r.start_depth is not null and r.end_depth is not null 
					  then  cast(hai.fn_hai_depth_zero(r.start_depth) as varchar) + '-' + coalesce(cast(hai.fn_hai_depth_zero(end_depth) as varchar),'') --+ ' (' + depth_unit + ')'
					when r.start_depth is not null and r.end_depth is null 
					  then cast(hai.fn_hai_depth_zero(r.start_depth) as varchar) --+ ' (' + depth_unit + ')'
					when r.start_depth is null and r.end_depth is not null 
					  then cast(hai.fn_hai_depth_zero(r.end_depth) as varchar) --+ ' (' + depth_unit + ')'	
				end as sample_depth
				,r.sample_date as sample_datetime
				,convert(varchar,sample_date,101) as sample_date
				,cast([rpt].[fn_HAI_sample_end_date] (duration,duration_unit,sample_date) as datetime) as sample_end_datetime
				,'12/31/2015 - 12/31/2015' as sample_date_range --MAA 1/5/2016 changed from 1-1 so the field length would be long enough to accept updates
				,r.task_code
				,r.matrix_code
				,r.sample_type_code
				,compound_group
				,r.parameter_group_name
				,case when len(r.param_report_order) =1 THEN '0' + r.param_report_order else coalesce(r.param_report_order,'99') end as param_group_order
				,coalesce(r.mag_report_order,'99') as mag_report_order
				,r.analytic_method
				,case 
					when r.fraction = 'D' then 'Dissolved'
					when r.fraction = 'T' then 'Total'
					when r.fraction = 'N' then 'NA'
				end as fraction
				,r.cas_rn
				,coalesce(r.mth_grp_parameter,r.chemical_name) as chemical_name
				,r.detect_flag
				,case when result_error_delta is not null then '+/-' + result_error_delta end as result_error_delta
				,r.reported_result_unit as lab_reported_result_unit
				,cast(rpt.fn_HAI_result_qualifier ( --Recalc unit conversion in case default units are specified in method analyte group
					coalesce(hai.fn_thousands_separator(equis.significant_figures(equis.unit_conversion(r.converted_result,r.converted_result_unit,coalesce(@target_unit,r.default_units, r.converted_result_unit),default),equis.significant_figures_get(r.converted_result),default)),equis.significant_figures(equis.unit_conversion(r.converted_result,r.converted_result_unit,coalesce(@target_unit,r.default_units, r.converted_result_unit),default),equis.significant_figures_get(r.converted_result),default)), --orginal result
					case 
						when detect_flag = 'N' then '<' 
						when detect_flag = 'Y' and charindex(validator_qualifiers, 'U') >0 then '<'
						when detect_flag = 'Y' and charindex(interpreted_qualifiers, 'U') >0 then '<'
						else null 
					end,  --nd flag
					reporting_qualifier,  --qualifiers
					interpreted_qualifiers,
					@user_qual_def) --how the user wants the result to look
					+ case when @show_val_yn = 'Y'  and (validated_yn = 'N' or validated_yn is null) then '[nv]' else '' end  as varchar (200))
					as Result_Qualifier
					--update report_result_unit with method analyte group default units
				,cast(equis.significant_figures(equis.unit_conversion(r.converted_result,r.converted_result_unit,coalesce(@target_unit,r.default_units, r.converted_result_unit),default),equis.significant_figures_get(r.converted_result),default) as varchar(200)) as Report_Result
				,cast(equis.unit_conversion(r.converted_result,r.converted_result_unit,coalesce(@target_unit,r.default_units, r.converted_result_unit),default) as decimal(18,10)) as Report_Result_Numeric
				,coalesce(@target_unit,r.default_units,converted_result_unit) as report_unit
				,coalesce(r.qualifier ,'') + case when @show_val_yn = 'Y'  and (validated_yn = 'N' or validated_yn is null) then '[nv]' else '' end as qualifier
				,r.detection_limit_type

				,case 
					when detect_flag = 'n' then '<' 
					when detect_flag = 'y' and charindex('u',validator_qualifiers ) >0 then '<'
					when detect_flag = 'y' and charindex( 'u' , interpreted_qualifiers) >0 then '<'
					else null 
				 end nd_flag
				,approval_a
				,case 
					when al.action_level_code like '%carc%' and al.action_level_code not like '%non%' then 'Carcinogenic Risk'
					when al.action_level_code like '%noncarc%' then 'Non-Carcinogenic Risk'
				 end as Screening_Level
				,equis.unit_conversion(al.action_level,al_unit,coalesce(@target_unit,converted_result_unit,al_unit),default) as screening_level_value
				,null

			from  ##results r
				inner join (select 
					action_level_code
					,param_code as cas_rn
					, action_level
					, unit as al_unit 
					from dt_action_level_parameter 
					where action_level_code in (select cast(value as varchar (50)) from fn_split(@action_level_codes)))al
				on r.cas_rn = al.cas_rn

			raiserror('#r insert done...',0,1) with nowait
			end try
			begin catch
				select 'Error inserting #results to #R ' + char(13)
				+ error_message()
			end catch

			update #r
			set 
			hazard_index = equis.significant_figures((report_result_numeric * @dispersion_factor)/cast(screening_level_value as decimal(18,10)) ,equis.significant_figures_get(report_result),default) 



		/*make risk table*/
			if object_id('tempdb..##risk') is not null drop table ##risk

			 declare @hazard_index varchar (max)
			 declare @result varchar (max)
			 declare @risk_sum varchar(max)

			 SELECT @hazard_index =  ISNULL(@hazard_index,'') + ' ,max (case when chemical_name = ' + '''' + chemical_name + '''' + ' then hazard_index end) as [' + chemical_name +  '-HI]' + char(13) 
						FROM (SELECT DISTINCT  chemical_name FROM  #r)z


			 SELECT @result =  ISNULL(@result,'') + ' ,max (case when chemical_name = ' + '''' + chemical_name + '''' + '  then report_result end) as [' + chemical_name + '_conc]' + char(13) 
						FROM (SELECT DISTINCT  chemical_name FROM  #r)z

			 select @risk_sum = isnull(@risk_sum,'') + 'cast([' +  chemical_name + '-HI] as float)+'
						from (select distinct chemical_name from #r)z
			 set @risk_sum = left(@risk_sum, len(@risk_sum) - 1)
	
	
			set @SQL = 'Select ' + char(13) + 
			'dense_rank() over(partition by screening_level order by  cast(sample_datetime as date)) as [rec_id]' + char(13) + 
			', screening_level' + char(13) + 
			', sample_datetime ' + char(13) +
			  @hazard_index + char(13) + 
			  @result + char(13) + 
			', cast(null as varchar (20))  as [Daily Total]' + char(13) +
			 ', cast(null as varchar (20)) as [Running Average]' + char(13) +
			' into ##risk' + char(13) +
			 ' From #r ' + char(13) + 
			'group by screening_level,  sample_datetime' 
	
			begin try
				exec (@SQL)

			end try
			begin catch
				set @msg = error_message()
				raiserror('##risk table failed', 0,1) with nowait
				raiserror(  @msg,0,1) with nowait
			end catch


			set @SQL = 
			'update ##risk
			set [Daily Total] =  ' + @risk_sum 
			exec (@SQL)


			update ##risk
			set [running average] = [daily total] 
			from ##risk where sample_datetime = (select min(cast(sample_datetime as datetime)) from ##risk)
			update ##risk
			set [daily total] = equis.significant_figures([daily total] ,2,default) 


			declare @cnt as int
			,@curr_rec as int = 1
			set @cnt = (select max(rec_id) from ##risk)

			declare @s table (screening_level varchar(100))
			insert into @s select distinct screening_level from ##risk

			declare @screening_level varchar (100)
			set @screening_level = (select top 1 screening_level from @s)

			declare
			 @max_rec_id int
			,@max_rec_cnt int
			,@rec_cnt int

			set @max_rec_id = (select max(rec_id) from ##risk)
			set @max_rec_cnt = (select count(*) from ##risk)
			set @rec_cnt = 1

			set nocount on
			while (select count(*) from ##risk where [running average] is  null and screening_level = @screening_level) >0  and @rec_cnt <= @max_rec_cnt 
			begin
				update ##risk 
				set [running average] = equis.significant_figures((select avg(cast([daily total] as float)) 
				from ##risk where rec_id <= @curr_rec and screening_level = @screening_level ),2, default)
				where rec_id = @curr_rec  and screening_level = @screening_level
				
				set @curr_rec = @curr_rec + 1

				set @rec_cnt = @rec_cnt + 1
				set @msg = @curr_rec
				--raiserror(@msg, 0,1) with nowait

				if @curr_rec = @max_rec_id +1
				begin
				  set @curr_rec = 1;
				  set @screening_level = (select screening_level from @s where screening_level not like @screening_level);
				end

			end

			declare @output varchar (max)

			SELECT @output =  ISNULL(@output,'') + ' ,['  + name +']' + char(13) 
			FROM (select name from tempdb.sys.columns where object_id = (select object_id from tempdb.sys.tables where name = '##risk') and name not like '%-hi'and name not like 'rec_id')z

		--Add Screening Levels to output	
		set @SQL = 	
			'select ' + char(13) +
			' screening_level  as [Screening_Level]' +  char(13) +
			',cast(' + '''' + '1/1/1900' + '''' +  ' as datetime) as [Sample_datetime]' + char(13) +
			',max(case when chemical_name = ' + '''' + 'benzene' + '''' + ' then screening_level_value end) as [benzene_conc]' + char(13) +
			',max(case when chemical_name = ' + '''' + 'ethylbenzene' + '''' + ' then screening_level_value end) as [ethylbenzene_conc]' + char(13) +
			',max(case when chemical_name = ' + '''' + 'naphthalene' + '''' + ' then screening_level_value end) as [naphthalene_conc]' + char(13) +
			',''SL'' as [Daily Total]' + char(13) +
			',''SL'' as ' + '''' + 'Running Average' + '''' + char(13) +
			'from #r'  + char(13) +
			'group by screening_level'

		
		--Output Risk Table Calcs table

			set @output = right(@output,len(@output)-2)
			set @output = 
			'Select ' + @output + char(13) +
			'From ##risk'
			begin try
				exec( @output + ' union ' +  @SQL + ' order by screening_level, sample_datetime')
			end try
			begin catch
				set @msg = error_message() 
				set @msg = 'Final Output Failed!' + @msg
				raiserror(@msg, 0,1) with nowait
			end catch

			if object_id('tempdb..##risk') is not null drop table ##risk
			IF OBJECT_ID('tempdb..#r') IS NOT NULL drop table #r
			IF OBJECT_ID('tempdb..##results') IS NOT NULL drop table ##results

	end