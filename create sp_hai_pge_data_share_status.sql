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
		,date_received
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
		inner join (SELECT 
				ebatch
				, file_name
				, received_date
				FROM [EQuIS].[dbo].[st_file_registration]
				where facility_id = @facility_id and received_date >= DATEADD(DAY, -@date_window,getdate()))email_edd
			on t.ebatch = email_edd.ebatch
		Where t.facility_id = @facility_id
		and received_date >=  DATEADD(DAY, -@date_window,getdate()))z
		Order by  date_received, lab_sdg

end