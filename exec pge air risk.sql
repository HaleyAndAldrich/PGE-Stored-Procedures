use equis
go


exec hai.sp_hai_pge_air_risk

		 47, -- @facility_id int  = 47,
		 null, --@subfacility_codes varchar (500),
		 null, --@location_groups varchar (2000),
		'ppp-apams-01a', -- @locations varchar (2000) =
		  null, --@sample_type varchar(200),
		 'potrero-pams' , --@task_codes varchar (1000) =
		  null, --@SDG varchar (2000),
		 'jan 01 1900 12:00 AM', --@start_date datetime= 
		 'dec 31 2050 11:59 PM', --@end_date datetime=
		 'pge potrero air risk vocs', --@analyte_groups varchar(2000) =
		  null, --@cas_rns varchar (2000),
		  null, --@analytic_methods varchar (2000),
		  null, --@matrix_codes varchar (500),
		 'ug/m3', --@target_unit varchar(100) = 
		  'RL', --@limit_type varchar (10) =
		'pge-sl-potrero-aa-noncarc|pge-sl-potrero-aa-carc', -- @action_level_codes varchar (500) =
		 '# Q', --@user_qual_def varchar (10) =
		 'y', --@show_val_yn varchar(10) =
		 'AVG', --@aggregate varchar (20) = 
		1 -- @dispersion_factor float = 1