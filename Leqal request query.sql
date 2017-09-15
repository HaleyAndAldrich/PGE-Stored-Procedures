

USE EQUIS
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_WARNINGS OFF
GO
SET NOCOUNT ON
GO



alter procedure hai.sp_hai_pge_legal_requests
		(@facility_id int  ,
		 @subfacility_codes varchar (500),
		 @coord_type varchar(20) ,
		 @task_codes varchar (1000)  ,
		 @SDG varchar (max) ,
		 @matrix_codes varchar (500) )

	as
	begin
		set nocount on

		declare 
			 @msg varchar (max)

		declare   @subfacilities table (subfacility_code varchar (20))
			insert into @subfacilities
			select  cast(value as varchar (20)) from fn_split(@subfacility_codes)
		if (select count(*) from @subfacilities) = 0
		begin
			insert into @subfacilities select subfacility_code from dt_subfacility where facility_id = @facility_id
		end


	--Here's where we get the main data set
		if object_id('tempdb..#r') is not null drop table #r
		create table #r 
		(
			 facility_id int
			,APN varchar (50)
			,[Address] varchar (200)
			,sys_loc_code varchar (20)
			,sys_sample_code varchar (50)
			,sample_name varchar (50)
			,coord_type_code varchar (20)
			,x_coord varchar (30)
			,y_coord varchar (30)
			,sample_datetime datetime
			,sample_type_code varchar (10)
			,matrix_code varchar (10)
			,field_sdg varchar (20)
			,lab_matrix_code varchar(10)
			,analytic_method varchar (20)
			,prep_date datetime
			,analysis_date datetime
			,column_number varchar (20)
			,fraction varchar (10)
			,basis varchar (10)
			,test_type varchar(10)
			,leachate_method varchar(20)
			,leachate_date datetime
			,lab_sdg varchar (20)
			,chemical_name varchar (255)
			,organic_yn varchar (10)
			,parent_sample_code varchar (50)
			,lab_sample_id varchar (20)
			,instrument_id varchar (20)
			,dilution_factor varchar (10)
			,qc_spike_recovery varchar (20)
			,test_batch_id  varchar (20)
			,blank_column varchar (20)
			,#test_id int 
			,cas_rn varchar (15)
			,result_text varchar (20)
			,result_numeric decimal(18,10)
			,result_error_delta varchar (10)
			,result_Type_code varchar (10)
			,stat_result varchar (10)
			,reportable_result varchar (5)
			,detect_flag varchar(2)
			,lab_qualifiers varchar (20)
			,validator_qualifiers varchar (10)
			,approval_code varchar (10)
			,interpreted_qualifiers varchar (10)
			,dqm_qualifiers varchar (10)
			,approval_a varchar(10)
			,approval_b varchar(10)
			,approval_c varchar(10)
			,approval_d varchar(10)
			,hold_time_status varchar (20)
			,method_detection_limit varchar (20)
			,reporting_detection_limit varchar (20)
			,quantitation_limit varchar (20)
			,result_unit varchar (10)
			,detection_limit_unit varchar (10)
			,tic_retention_time varchar (10)
			,custom_field_1 varchar (255)
			,custom_field_2 varchar (255)
			,custom_field_3 varchar (255)
			,remark varchar( 255)
			,dqm_remark varchar (10)
			,desorb_efficiency varchar (10)
			,value_type varchar (10)
			,stat_type varchar (10)
			,custom_field_4 varchar (255)
			,custom_field_5 varchar (255)
			,validated_yn varchar (2)
		)


		begin try
		raiserror( 'Begin inserting #r',0,1) with nowait
		insert into #r(
			 facility_id 
			,APN 
			,[Address] 
			,sys_loc_code 
			,sys_sample_code 
			,sample_name 
			,coord_type_code 
			,x_coord 
			,y_coord 
			,sample_datetime
			,sample_type_code 
			,matrix_code 
			,field_sdg
			,lab_matrix_code
			,analytic_method
			,prep_date
			,analysis_date
			,column_number
			,fraction
			,basis
			,test_type
			,leachate_method
			,leachate_date
			,lab_sdg
			,chemical_name 
			,organic_yn 
			,parent_sample_code 
			,lab_sample_id 
			,instrument_id 
			,dilution_factor 
			,qc_spike_recovery
			,test_batch_id  
			,blank_column 
			,#test_id  
			,ra.cas_rn 
			,result_text 
			,result_numeric 
			,result_error_delta 
			,result_Type_code 
			,stat_result 
			,reportable_result 
			,detect_flag 
			,lab_qualifiers 
			,validator_qualifiers 
			,approval_code 
			,interpreted_qualifiers 
			,dqm_qualifiers 
			,approval_a 
			,approval_b 
			,approval_c 
			,approval_d 
			,hold_time_status 
			,method_detection_limit 
			,reporting_detection_limit 
			,quantitation_limit 
			,result_unit 
			,detection_limit_unit 
			,tic_retention_time 
			,custom_field_1 
			,custom_field_2 
			,custom_field_3 
			,remark  
			,dqm_remark 
			,desorb_efficiency
			,value_type 
			,stat_type 
			,custom_field_4 
			,custom_field_5 
			--,validated_yn 
			 )

		select 
			 l.facility_id 
			,APN 
			,[Address] 
			,l.sys_loc_code 
			,s.sys_sample_code 
			,s.sample_name 
			,coord_type_code 
			,x_coord 
			,y_coord 
			,s.sample_date
			,s.sample_type_code 
			,s.matrix_code 
			,fs.field_sdg
			,lab_matrix_code
			,analytic_method
			,prep_date
			,analysis_date
			,column_number
			,fraction
			,basis
			,test_type
			,leachate_method
			,leachate_date
			,lab_sdg
			,chemical_name 
			,organic_yn 
			,parent_sample_code 
			,lab_sample_id 
			,instrument_id 
			,dilution_factor 
			,rq.qc_spike_recovery
			,tba.test_batch_id  
			,null
			,t.test_id  
			,ra.cas_rn 
			,result_text 
			,result_numeric 
			,result_error_delta 
			,result_Type_code 
			,stat_result 
			,reportable_result 
			,detect_flag 
			,lab_qualifiers 
			,validator_qualifiers 
			,approval_code 
			,interpreted_qualifiers 
			,dqm_qualifiers 
			,approval_a 
			,approval_b 
			,approval_c 
			,approval_d 
			,hold_time_status 
			,method_detection_limit 
			,reporting_detection_limit 
			,quantitation_limit 
			,result_unit 
			,detection_limit_unit 
			,tic_retention_time 
			,r.custom_field_1 
			,r.custom_field_2 
			,r.custom_field_3 
			,r.remark  
			,r.dqm_remark 
			,r.desorb_efficiency 
			,value_type 
			,stat_type 
			,r.custom_field_4 
			,r.custom_field_5 
			--,validated_yn 
		from 
			(select
				 l.facility_id
				,l.sys_loc_code
				,l.subfacility_code
				,ld.apn
				,ld.address
				,coord_type_code
				,x_coord
				,y_coord
			from dt_location l
			inner join @subfacilities sf on l.subfacility_code = sf.subfacility_code
			left join dbo.dt_hai_location_details ld
				on l.facility_id = ld.facility_Id and l.sys_loc_code = ld.sys_loc_code	
			left join 
				(select c.facility_id, c.sys_loc_code, coord_type_code, x_coord, y_coord
					from dt_coordinate c
					where c.facility_id = @facility_id
					and coord_type_code = @coord_type)c
				on l.facility_id = c.facility_id and l.sys_loc_code = c.sys_loc_code
				where l.facility_id = @facility_Id ) l

			inner join dt_sample s on l.facility_id = s.facility_id and l.sys_loc_code = s.sys_loc_code
			left join dt_field_sample fs on s.facility_id = fs.facility_Id and s.sample_id = fs.sample_id
			inner join dt_test t on s.facility_id = t.facility_id and s.sample_id  = t.sample_id
			inner join dt_result r on t.facility_id = r.facility_id and t.test_id = r.test_id
			left join dt_result_qc rq on r.facility_id = rq.facility_id and r.test_id = rq.test_id and r.cas_rn = rq.cas_rn
			inner join rt_analyte ra on r.cas_rn = ra.cas_rn

			left join  (select facility_id, test_id, test_batch_id from at_test_batch_assign tba where test_batch_type = 'analysis')  tba on t.facility_id = tba.facility_id and t.test_id = tba.test_id 

			inner join rpt.fn_HAI_Get_TaskCode(@facility_id, @task_codes) task on s.facility_id = task.facility_id and coalesce(s.task_code,'none') = task.task_code
			inner join rpt.fn_HAI_Get_SDGs(@facility_id, @SDG) sdg on t.facility_id = sdg.facility_id and coalesce(t.lab_sdg,'no_sdg') = sdg.sdg
			inner join rpt.fn_HAI_Get_Matrix(@facility_id,@matrix_codes) mtrx on s.facility_id = mtrx.facility_id and s.matrix_code = mtrx.matrix_code
		


		raiserror('#r insert done...',0,1) with nowait
		end try
		begin catch
			set @msg = 'Error inserting #results to #R ' + char(13) + error_message()
			select @msg
			raiserror(@msg,0,1) with nowait
		end catch

		Set @msg = cast((select count(*) from #r) as varchar (20))
		SEt @msg = @msg + ' records returned.'
		raiserror(@msg, 0,1) with nowait

		select * from #r
		if object_id('tempdb..#r') is not null drop table #r

	end