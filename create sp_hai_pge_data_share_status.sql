use equis
go

set ansi_nulls off
go

set nocount on
go

alter procedure hai.sp_hai_pge_data_share_status(
@facility_id int
,@date_window int
,@date_check_threshold int)

as
begin

	select distinct 
		task_code
		,lab_sdg
		,case when edd_user = 'TestAmerica' then 'TA Lab' else 'H&A' end as Loaded_by
		,Date_Received as [date_received/loaded]
		,elapsed_days
		,case when elapsed_days > = @date_check_threshold and permission_type_code not like '0' and permission_type_code not like '999' then 'Check' else '--' end as status
		,permission_type_code
		,review_comment
		,dt_test_ebatch
		,file_name

		from (
		select 
		s.task_code
		,s.permission_type_code
		,s.review_comment
		,t.lab_sdg
		,t.ebatch as dt_test_ebatch
		,email_edd.ebatch
		,email_edd.file_name
		,edd_user
		,convert(varchar,email_edd.received_date, 101) as Date_Received
		,datediff(d,received_date,getdate())  elapsed_days

		from (select distinct 
			facility_id
			, sample_id
			, ebatch
			, lab_sdg 
			from dt_test 
			where facility_id = @facility_id) t 
		inner join (
			select distinct 
			s.facility_id
			, sample_id
			, s.task_code 
			,tp.permission_type_code
			,tp.review_comment
			from dt_sample s
			left join dt_hai_task_permissions tp
			on s.facility_id = tp.facility_id and s.task_code = tp.task_code
			where s.facility_id = @facility_id and s.sample_type_code = 'n')s
			 on t.facility_id = s.facility_id and t.sample_id = s.sample_id
		left join (select    
					eb.ebatch
					,t.lab_sdg
					,reverse(case when charindex('\',reverse(eb.edd_file)) > 0 then left(reverse(eb.edd_file), charindex('\',reverse(eb.edd_file))-1) else reverse(eb.edd_file) end) as file_name
					, edd_date as received_date
					,edd_user
					from st_edd_batch eb
					inner join (
						select distinct 
							 t.facility_id
							,t.sample_id
							,t.ebatch
							,lab_sdg 
						from dt_test t 
						inner join dt_sample s on t.facility_id = s.facility_id and t.sample_id = s.sample_id
						where t.facility_id = 47 and s.sample_type_code = 'n') t 
						on eb.ebatch = t.ebatch
					where edd_type = 'equis 4-file format'
						and facility_id = @facility_id 
						and edd_date >= DATEADD(DAY, -@date_window,getdate()))email_edd
			on t.ebatch = email_edd.ebatch
		Where t.facility_id = @facility_id
		and received_date >=  DATEADD(DAY, -@date_window,getdate()))z
		Order by  date_received desc, lab_sdg

end