*! version 2.1.2  16sep2021
program define estudy, rclass
        version 13

syntax  anything(id="varlist" equalok) , /// 
		DATevar(varlist max=1) ///
		EVDate(str) ///
		LB1(numlist max=1 integer) UB1(numlist max=1 integer) ///
		[LB2(numlist max=1 integer) UB2(numlist max=1 integer) ///
		LB3(numlist max=1 integer) UB3(numlist max=1 integer) ///
		LB4(numlist max=1 integer) UB4(numlist max=1 integer) ///
		LB5(numlist max=1 integer) UB5(numlist max=1 integer) ///
		LB6(numlist max=1 integer) UB6(numlist max=1 integer) ///
		DATEFormat(str) ///  
		PRIce /// 
		INDexlist(varlist) ///
		DIAGNosticsstat(namelist max=1) ///
		ESWLBound(numlist max=1 integer) ///
		ESWUBound(numlist max=1 integer) ///
		MODType(namelist max=1) /// 
		DECimal(numlist max=1 integer) ///
		OUTPutfile(string) ///
		SUPPress(namelist max=1) ///
		SHOWPvalues ///
		NOStar ///
		TEX ///
		GRAPH (string) /// 
		MYDataset(string) ///
		Detail /// 
		]
		
tempvar obsn
qui gen `obsn' = _n /* Generate the ascending tempvar (1, 2, 3... N) obsn */
qui preserve 
local orig_sample_size = _N /* Store di original sample size in macro local */
	 
local p 0
tokenize `anything', parse("()")
forvalues i=1/1000000000 {
	if "``i''" == ""  {
		continue, break
	}
	if "``i''" != "("  { /* Tokenize the specified varlists */
		if "``i''" != ")" {
			if "``i''" != "" {
				local ++p /* p is the counter of specified varlists */
				if (strpos("``i''", "*") != 0 | strpos("``i''", "-") != 0) {
					unab varlist_n_`p' : ``i''
				}
				else{
					local varlist_n_`p' ``i''
				}
			}
		}
	}
}
*

qui ds `datevar', has(format %t*) /* Check if the specified date variable has a date format */
tempvar date_check_1
qui gen `date_check_1' = r(varlist)
tokenize `date_check_1'

capture confirm str variable `1'
if _rc != 0 {
	disp as err "The specified Datevar is not in date format"
	exit 451 /* Invalid values for time variable */
}
*
if "`suppress'" != "" {
	if "`suppress'" != "group" {
		if "`suppress'" != "ind" { 
			disp as err "Option Suppress misspecified"
			exit 198 /* Option incorrectly specified */
		}
	}
}

if "`decimal'" != "" {  /* Use the number of decimal specified by the user */
	local n_dec = "`decimal'"
}
else {
	local n_dec = 2
}
if `n_dec' > 7 {  /* Return an error message if the number of decimals is greater than the maximum (7) */
	disp as err "The number of decimals must be maximum 7"
	exit 198 /* Option incorrectly specified */
}

local delimiter_1 = "" /* default delimiters for output tables */
local delimiter_2 = "" 
local delimiter_3 = "" 
if "`tex'" != "" {
	local delimiter_1 = " & " /* end of columns tex delimiter */
	local delimiter_2 = " \\" /* end of line tex delimiter */
	local delimiter_3 = "\" /* escape character for latex percentages */ 
}

tokenize `evdate'
if "`1'" != "" {
	if "`2'" != "" {
		if "`3'" != "" {
			disp as err "Too many variables specified. Evdate option must include either a string (event date clustering) or namelist and datelist (multiple event dates)"
			exit 198 /* Option incorrectly specified */
		}
		else {
			qui set obs `=_N*2-1'
			tempvar generic_event
			qui gen `generic_event' = _n - `orig_sample_size' /* Auxiliary var useful to align ruturn series around 0 */
			disp as input _newline "Event study with multiple event dates"
			if "`dateformat'" != "" & "`detail'" != "" disp as input " In case of multiple events estudy ignores the dateformat option" as input "" /* Ignoring dateformat when multiple events are specified */
			
			tempvar events_label_list 
			tempvar events_date_list 
			qui clonevar `events_label_list' = `1' 
			qui clonevar `events_date_list'  = `2' 
			
			capture confirm str variable `events_label_list' /* Check if the first variable specified in evdate has a string format */
			if _rc != 0 {
				disp as err "The namelist variable specified in evdate must include only string values" 
				exit 198 /* Option incorrectly specified */
			}
			/* Check if the second variable specified in evdate has a date format */
			qui ds `events_date_list', has(format %t*)
			tempvar evd_dateformat_check_1
			qui gen `evd_dateformat_check_1' = r(varlist)
			tokenize `evd_dateformat_check_1'
			
			capture confirm str variable `1'
			if _rc != 0 {
				disp as err "The datelist variable specified in evdate is not in date format"
				exit 451 /* Invalid values for time variable */
			}
		}
	}
	else{
		local commonevent = "YES"
		disp as input _newline "Event study with common event date"
		
		if "`dateformat'" == ""{
			disp as err "With a common event date, the dateformat option must be specified"
			exit 198 /* Option incorrectly specified */
		}
		
		if strlen("`dateformat'") < 3 {
			disp as err "The specified date format is too short: only DMY, MDY, and YMD are allowed"
			exit 198 /* Option incorrectly specified */
		}
		else if strlen("`dateformat'") == 3 {
			if ("`dateformat'" != "DMY" & "`dateformat'" != "MDY" & "`dateformat'" != "YMD") {
				disp as err "The specified date format is not allowed: only DMY, MDY, and YMD are allowed"
				exit 198 /* Option incorrectly specified */
			}
		}
		else {
			disp as err "The specified date format is too long: only DMY, MDY, and YMD are allowed"
			exit 198 /* Option incorrectly specified */
		}
		if strlen("`evdate'") !=8 {
			disp as err "The event date must be 8 characters long"
			exit 198 /* Option incorrectly specified */
		}
		
		local day = dow(date("`evdate'","`dateformat'"))
		if `day' == . {
			disp as err "Evdate option incorrectly specified. Allowed arguments are:"
			disp as err "	- in case of event date clustering, a single string including 8 numbers" 
			disp as err "	- in case of multiple event dates, two variables i.e. namelist and datelist"
			exit 198 /* Option incorrectly specified */ 
		}
		
		if date("`evdate'","`dateformat'") < `datevar' in 1 {  /* Check if the date is before the sample period */
			disp as err "The specified event date is before the sample period"
			exit 198 /* Option incorrectly specified */ 
		}
		else if date("`evdate'","`dateformat'") > `datevar'[_N] { /* Check if the date if after the sample period */
			disp as err "The specified event date is after the sample period"
			exit 198 /* Option incorrectly specified */ 
		}
		if `day' != 0 & `day' != 6 { /* Check if the specified date is missing (holiday) */
			qui count if `datevar' == date("`evdate'","`dateformat'")
			if r(N) == 0 {
				disp as err "The specified date is missing in the database: check whether it is a holiday or the dateformat is not adequate to the evdate"
				exit 416 /* Missing values encountered */
			}
		}
	}
}
else {
	disp as err "Evdate option must be specified"
	exit 198 /* Option incorrectly specified */
}

local zzz 1
forvalues z=1/`p' {
	local varlist `varlist_n_`z''
	local nind : word count `indexlist' /* nind is the index/indexes used to compute the normal returns */
	local nvars : word count `varlist' /* nvars is the number of rows in the final table */
	local spec_vars : word count `varlist' /* specvars in the number of variables included in the varlist */
		
	if "`suppress'" == "ind" & `nvars' == 1 { /* Condition to hide CARs. Only CAARs are shown*/
		disp as error "Suppress cannot be used with only 1 variable specified in varlist"
		exit 198 /* Option incorrectly specified */
	}

	local nn=1 
	while `nn'<7 {
		if "`lb`nn''" != "" & "`ub`nn''" != "" { /* Count the number of specified event windows */
			local num_ev_wdws = `nn'
			local nn=`nn'+1
		}
		else if ("`lb`nn''" != "" & "`ub`nn''" == "") | ("`lb`nn''" == "" & "`ub`nn''" != "") { /* Check if both bounds of the event windows are specified are specified */
			disp as err "Both upper and lower bound must be specified"
			exit 198 /* Option incorrectly specified */
		}
		else {
			forvalues mm=`nn'/6 {
				if ("`lb`mm''" != "" | "`ub`mm''" != "") | ("`lb`mm''" != "" & "`ub`mm''" != "") { /* Check if event windows are specified in ascenging order */
					disp as err "Event windows must be specified in ascending order: 1, 2, 3..."
					exit 198 /* Option incorrectly specified */
				}
			}
			local nn=7
		}
	} /* end of while */
	forvalues i=1/`num_ev_wdws' { /* Allocate the specified event windows */
		local evlbound_`i' = "`lb`i''"
		local evubound_`i' = "`ub`i''"
	}
	
	local upp_bound = "`eswubound'" /* Allocate the specified upper bound of the estimation window */
	local low_bound = "`eswlbound'" /* Allocate the specified lower bound of the estimation window */
	
	if "`upp_bound'" == "" { /* Set the upper bound of the event window equal to -30 if not specified */
		local upp_bound = -30
		if (`z' == 1 & "`detail'" != "") disp as input "By default the upper bound of the estimation window has been set to (-30)"
	}
	if `upp_bound' > -2 { /* Check if the estimation window is too close or after the event date */
		disp as err "The estimation window is either too close or after the event date" 
		exit 198 /* Option incorrectly specified */ 
	}
	
	if "`commonevent'" != "" { 
		if "`modtype'" != "HMM" {
			local aux_index_list ""
			tokenize "`indexlist'" 
			forvalues j = 1/`nind' {
				local spec_index_`j' = "``j''"
				capture drop `idv_`j''
				tempvar idv_`j'
				local aux_index_list = "`aux_index_list' `idv_`j''"
				
				if "`price'" != "" { /* Compute securities returns from prices */
					qui sum `spec_index_`j''
					if r(min) < 0 {
						disp as err "Price series of index `j' includes negative values"
						exit 411 /* Nonpositive values encountered */
					}
					qui gen `idv_`j'' = ln(`spec_index_`j''/`spec_index_`j''[_n-1])
				}
				else{ /* Allocate returns */
						qui gen `idv_`j'' = `spec_index_`j''
				}
				
			}
		}	
		tempvar event
		if (`day' == 0 | `day' == 6) { /* Check if the event date falls on sunday and adjust the event windows accordingly */
			if `day' == 0 {
				local dayname = "Sunday"
				local day_shift = 1
			}
			else {
				local dayname = "Saturday"
				local day_shift = 2
			}
			if ("`detail'" != "" & `z'==1) disp as input "The specified common event date falls on a `dayname'"
			
			local date_aux = date("`evdate'","`dateformat'")
			local date_aux = `date_aux'+`day_shift'
			qui count if `datevar' == `date_aux' 
			if r(N) == 0 {
				disp as err "The first Monday after the event date is missing"
				exit 416 /* Missing values encountered */
			}
			qui gen `event'=0 if `datevar'==`date_aux'
			qui levelsof `obsn' if `event'==0 , local(levels)
			foreach l of local levels {
				qui replace `event'=`obsn'-`l'
			}
			qui replace `event'=`event' + 1 if `event'>= 0 /* Generate the ascending tempvar event equal to zero in the event date (...-2, -1, 1, 2, ... since the event date falls on sunday) */
		}
		else if (`day' != 0  & `day' != 6) { /* Generate the ascending tempvar equal to zero in the event date (...-2, -1, 0, 1, 2, ...) */
			qui gen `event'=0 if `datevar'==date("`evdate'","`dateformat'")
			qui levelsof `obsn' if `event'==0 , local(levels)
			foreach l of local levels {
				qui replace `event'=`obsn'-`l'
			}
		} /* end of if day != 6 & 0 */

		local rowmean_aux_varlist = "" 
		tokenize "`varlist'" 
		forvalues i = 1/`nvars' {
			local aux_index_list_`i' = "`aux_index_list'" /* Create the i-th index list by copying the generic index list */
			capture drop `dv_`i''
			capture drop `expdv_`i''
			tempvar dv_`i'
			tempvar expdv_`i'
			if "`price'" != "" { /* Compute securities returns from prices */
				qui sum ``i''
				if r(min) < 0 {
					disp as err "Price series of security `i' of varlist `z' includes negative values"
					exit 411 /* Nonpositive values encountered */
				}
				qui gen `dv_`i'' = ln(``i''/``i''[_n-1])
			}
			else{ /* Allocate returns */
				qui gen `dv_`i'' = ``i''
			}
			qui gen `expdv_`i'' = exp(`dv_`i'')
			local rowmean_aux_varlist = "`rowmean_aux_varlist' `expdv_`i''"
		}
		
		if `nvars' > 1 { /* Create portfolios using shifted variables (multiple events) or renamed variables (common events) */
			tempvar exp_portfolio_model
			tempvar portfolio_model
			qui egen `exp_portfolio_model' = rowmean(`rowmean_aux_varlist')
			qui gen `portfolio_model' = ln(`exp_portfolio_model')
			label var `portfolio_model' "Ptf CARs n `z' (`nvars' securities)"
		}
	} /* End of common event */	
	else { /* Multiple events */
		if "`modtype'" != "HMM" { 
			tokenize "`indexlist'" /* Separate the variables specified in indexlist in different local */
				forvalues j = 1/`nind' {
					local spec_index_`j' = "``j''"
			}
		}
		tokenize "`varlist'"
		forvalues i = 1/`nvars' {
			local aux_index_list_`i' "" /* Create auxiliary list of variable stored in a single local to be used in regressions */
			forvalues j = 1/`nind' { /* Create as many indexes as the the number of variables specified in the varlist */ 
				capture drop `idv_`i'_`j''
				tempvar idv_`i'_`j'
				local aux_index_list_`i' = "`aux_index_list_`i'' `idv_`i'_`j''"   
			}
			
			capture drop `dv_`i'' /* Drop tempvars if they already exist */
			tempvar dv_`i' /* Generate the aligned return variable */
			
			capture drop `event'
			tempvar event
			qui gen `event' = .
			qui levelsof `events_date_list' if `events_label_list' == "``i''" , local(aux_day)
			
			qui count if `events_label_list' == "``i''" 
			if r(N) == 0 { /* Check if each variable specified in each varlist is included in namelist */
				disp as err "Option evdate does not include the variable ``i''" as text ""
				exit 198 /* Option incorrectly specified */ 
			}
			
			else if r(N) > 1 { /* Check if namelist contains duplicated values */
				disp as err "Namelist must include only unique values" as text "" 
				exit 198 /* Option incorrectly specified */ 
			}
			else if r(N) ==1 {
				qui sum `events_date_list' if `events_label_list' == "``i''" 
				if r(N) == 0 {
					disp as err "The variable " as input "``i''" as err " has no date"
					exit 198 /* Option incorrectly specified */
				}
			}
			
			if `aux_day' < `datevar' in 1 {  /* Check if the date is before the sample period */
				disp as err "The event date of company ``i'' preceeds the sample period"
				exit 198 /* Option incorrectly specified */ 
			}
			else if `aux_day' > `datevar'[_N] { /* Check if the date if after the sample period */
				disp as err "The event date of company ``i'' exceeds the sample period"
				exit 198 /* Option incorrectly specified */ 
			}
			
			local day = dow(`aux_day')
			if `day' != 0 & `day' != 6 { /* Check if the specified date is missing (holiday) */
				qui count if `datevar' == date("`evdate'","`dateformat'")
				if r(N) == 0 {
					disp as err "The event date of company ``i'' is missing in the database: check whether it is a holiday or the dateformat is not adequate to the evdate"
					exit 416 /* Missing values encountered */
				}
			}
			local warn_label : variable label ``i''
			if (`day' == 0 | `day' == 6) { /* Check if the event date falls on sunday and adjust the event windows accordingly */
				if `day' == 0 {
					local dayname = "Sunday"
					local day_shift = 1
				}
				else {
					local dayname = "Saturday"
					local day_shift = 2
				}
				if "`detail'" != "" disp as input "The event date of company" as result " `warn_label' " as input "falls on a `dayname'"
				
				local aux_day = `aux_day'+`day_shift'
				qui count if `datevar' == `aux_day' 
				if r(N) == 0 {
					disp as err "The first Monday after the event date is missing"
					exit 416 /* Missing values encountered */
				}
				qui replace `event'=0 if `datevar'==`aux_day' 
				qui levelsof `obsn' if `event'==0 , local(levels)
				foreach l of local levels {
					local evobs = `orig_sample_size' - `l' /* Compute the shift necessary to align variables */
					qui replace `event'=`obsn'-`l'
				}
				qui replace `event'=`event' + 1 if `event'>= 0 /* Generate the ascending tempvar event equal to zero in the event date (...-2, -1, 1, 2, ... since the event date falls on sunday) */
				if "`price'" != "" { /* Compute returns from prices */
					tempvar aux_sec_ret_`i'
					
					qui sum ``i''
					if r(min) < 0 {
						disp as err "Price series of security `i' of varlist `z' includes negative values"
						exit 411 /* Nonpositive values encountered */
					}
					
					qui gen `aux_sec_ret_`i'' = ln(``i''/``i''[_n-1])
					qui gen `dv_`i'' = `aux_sec_ret_`i''[_n - `evobs'] if `generic_event' < 0 
					qui replace `dv_`i'' = `aux_sec_ret_`i''[_n - `=`evobs'+1'] if `generic_event' > 0
				}
				else {
					qui gen `dv_`i'' = ``i''[_n - `evobs'] if `generic_event' < 0 
					qui replace `dv_`i'' = ``i''[_n - `=`evobs'+1'] if `generic_event' > 0 
				}
				
				if "`modtype'" != "HMM"	{
					forvalues j = 1/`nind' {
						if "`price'" != "" { 
							tempvar aux_ind_ret_`j'
							qui sum `spec_index_`j''
							if r(min) < 0 {
								disp as err "Price series of index `j' includes negative values"
								exit 411 /* Nonpositive values encountered */
							}
							qui gen `aux_ind_ret_`j'' = ln(`spec_index_`j''/`spec_index_`j''[_n-1])
							qui gen `idv_`i'_`j'' = `aux_ind_ret_`j''[_n - `evobs'] if `generic_event' < 0 
							qui replace `idv_`i'_`j'' = `aux_ind_ret_`j''[_n - `=`evobs'+1'] if `generic_event' > 0
						}
						else {
							qui gen `idv_`i'_`j'' = `spec_index_`j''[_n - `evobs'] if `generic_event' < 0 /* Create shifted indixes */
							qui replace `idv_`i'_`j'' = `spec_index_`j''[_n - `=`evobs'+1'] if `generic_event' > 0
						}
					}
				}
			}
			else { /* Generate the ascending tempvar equal to zero in the event date (...-2, -1, 0, 1, 2, ...) */
				qui replace `event'=0 if `datevar'==`aux_day'
				qui levelsof `obsn' if `event'==0 , local(levels)
				foreach l of local levels {
					local evobs = `orig_sample_size' - `l'
					qui replace `event'=`obsn'-`l'
				}
				if "`price'" != "" { /* Compute returns from prices */
					tempvar aux_sec_ret_`i'
					qui sum ``i''
					if r(min) < 0 {
						disp as err "Price series of security `i' of varlist `z' includes negative values"
						exit 411 /* Nonpositive values encountered */
					}
					qui gen `aux_sec_ret_`i'' = ln(``i''/``i''[_n-1])
					qui gen `dv_`i'' = `aux_sec_ret_`i''[_n - `evobs']
				}
				else{
					qui gen `dv_`i'' = ``i''[_n - `evobs'] 
				}
				
				if "`modtype'" != "HMM"	{	
					forvalues j = 1/`nind' {
						if "`price'" != "" { /* Create indices returns from prices */
							tempvar aux_ind_ret_`j'
							qui sum `spec_index_`j''
							if r(min) < 0 {
								disp as err "Price series of index `j' includes negative values"
								exit 411 /* Nonpositive values encountered */
							}
							qui gen `aux_ind_ret_`j'' = ln(`spec_index_`j''/`spec_index_`j''[_n-1])
							qui gen `idv_`i'_`j'' = `aux_ind_ret_`j''[_n - `evobs']
						}
						else {
							qui gen `idv_`i'_`j'' = `spec_index_`j''[_n - `evobs']  /* Create shifted indixes */
						}
					}

				}
			}
		} 
		qui replace `event' = . 
		qui replace `event' = `generic_event' 
	} /* End of multiple events */
	
	if "`low_bound'" == "" { /* Set the lower bound of the estimation window equal to the first available value */
		local low_bound = `event' in 1
	}
	if `low_bound' < `event' in 1 { /* Check if the specified lower bound of the estimation window pertains to the sample */
		disp as err "The specified lower bound is outside the sample extension"
		exit 198 /* Option incorrectly specified */ 
	}
	
	if `low_bound' >= `upp_bound' { /* Check if the boundaries of the estimation window are correctly specified */
		disp as err "The lower bound of the estimation window exceeds the upper bound"
		exit 198 /* Option incorrectly specified */ 
	}
	
	forvalues i=1/`num_ev_wdws' {
		if `evlbound_`i'' < `upp_bound' { /* Check if estimation and events windows overlap */
			disp as error "The lower bound of the event window n. `i' overlaps the estimation window"
			exit 198 /* Option incorrectly specified */ 
		}
		else if `evlbound_`i'' == `upp_bound' { /* Check if estimation and event windows overlap */
			if `z' == 1 {
				if "`detail'" != "" {
					disp as error "Warning: " as text "the lower bound of the event window n. `i' corresponds to upper bound of the estimation window" 
				}
			}
		}
		
		if `evlbound_`i'' > `evubound_`i'' { /* Check if the boundaries of the event windows are correctly specified */
			disp as error "The lower bound of the event window n. `i' exceeds the upper bound" 
			exit 198 /* Option incorrectly specified */ 
		}
		if `evubound_`i'' > `event'[_N] {
			disp as err "The upper bound of the event window n. `i' is outside the sample extension"
			exit 198 /* Option incorrectly specified */ 
		}
	}
	local aux_nind = `nind'
	if ("`modtype'" == "" | "`modtype'" == "SIM" | "`modtype'" == "MFM") { /* Compute ARs according to the market model */
		if "`indexlist'" == "" {
			disp as err "Indexlist must be specified"
			exit 102 /* Too few variables specified */ 
		}
		if ("`modtype'" == "" | "`modtype'" == "SIM") {
			if `nind'>1 {
				disp as err "Single Index Model requires only 1 index"
				exit 103 /* Too many variables specified */
			}
		}
		
		tokenize "`varlist'" 
		forvalues i = 1/`nvars' {
			qui regress `dv_`i'' `aux_index_list_`i'' if `event'<=`upp_bound' & `event'>=`low_bound' 
			tempvar ar_`z'_`i'
			qui predict `ar_`z'_`i'' , resid
			_crcslbl `ar_`z'_`i'' ``i''
		}
		if (`nvars' > 1 & "`commonevent'" != "") { /* Compute the portfolio ARs */
			local nvars=`nvars' + 1 
			qui regress `portfolio_model' `aux_index_list_1' if `event'<=`upp_bound' & `event'>=`low_bound' 
			tempvar ar_`z'_`nvars' 
			qui predict `ar_`z'_`nvars'', resid 
			_crcslbl `ar_`z'_`nvars'' `portfolio_model'
		}
	}	
	else if "`modtype'" == "HMM" { /* Compute ARs according to the historical mean model */
		local aux_nind 1
		tokenize "`varlist'" 
		forvalues i = 1/`nvars' {
			qui sum `dv_`i'' if `event' <= `upp_bound' & `event' >= `low_bound'
			local hist_avg = r(mean)
			tempvar ar_`z'_`i'
			qui generate `ar_`z'_`i'' = `dv_`i'' - `hist_avg'
			_crcslbl `ar_`z'_`i'' ``i'' 
		}
		if (`nvars' > 1 & "`commonevent'" != "") { /* Compute the portfolio ARs */
			local nvars=`nvars' + 1 
			qui sum `portfolio_model' if `event'<=`upp_bound' & `event'>=`low_bound'
			local hist_avg = r(mean)
			tempvar ar_`z'_`nvars' 
			qui generate `ar_`z'_`nvars'' = `portfolio_model' - `hist_avg'
			_crcslbl `ar_`z'_`nvars'' `portfolio_model'
		}
	}
	else if "`modtype'" == "MAM" { /* Compute ARs according to the market adjusted model */
		if `nind' > 1 {
			disp as error "Only 1 index must be specified to adopt the Market Adjusted Model (MAM)"
			exit 103 /* Too many variables specified */
		}
		tokenize "`varlist'" 
		forvalues i = 1/`nvars' {
			tempvar ar_`z'_`i'
			qui generate `ar_`z'_`i'' = `dv_`i'' - `aux_index_list_`i''
			_crcslbl `ar_`z'_`i'' ``i'' 
		}
		if (`nvars' > 1 & "`commonevent'" != "") { /* Compute the portfolio ARs */ 
			local nvars=`nvars' + 1 
			tempvar ar_`z'_`nvars' 
			qui generate `ar_`z'_`nvars'' = `portfolio_model' - `aux_index_list_1'
			_crcslbl `ar_`z'_`nvars'' `portfolio_model'
		}
	}
	else if "`modtype'" != "" { /* Check if the model is misspecified */
		disp as err "Model misspecified"
		exit 198 /* Option incorrectly specified */ 
	}
	
	forvalues i = 1/`nvars' {
		qui sum `ar_`z'_`i'' if `event' <= `upp_bound' & `event' >= `low_bound'
		scalar variance = r(Var) 
		scalar variance_`i'=variance 
		scalar m_ret_`i' = r(N)
		
		if `i' <= `spec_vars' {
			
		
			if "`detail'" != "" {
				local warn_label : variable label ``i''
				if m_ret_`i' < 50 { 
					disp as err "The variable " as result "`warn_label' of varlist n.`z'" as err " has " m_ret_`i' " observations in the estimation window" as text "" 
				}
				else {
					disp as input "The variable " as result "`warn_label' of varlist n.`z' " as input " has " m_ret_`i' " observations in the estimation window" as text "" 
				}
			}
			if "`commonevent'" == "" {
				qui levelsof `events_date_list' if `events_label_list' == "``i''", local(evntdts)
				scalar evntdts_`z'_`i' = `evntdts' /* store events for output tables */
				if `i' == `spec_vars' {
					scalar evntdts_`z'_`=`i'+1' = "    -    "
				}
			}
		}
		
		forvalues j=1/`num_ev_wdws' {
			qui sum `ar_`z'_`i'' if (`event' >= `evlbound_`j'' & `event' <= `evubound_`j'') 
			scalar carvalue_`z'_`i'_`j' = r(sum) 			
			local carvalue_`z'_`i'_`j' = r(sum)
			scalar num = r(N)
			scalar carvariance_`i'_`j' = num*variance
			
			if "`modtype'" == "" | "`modtype'" == "SIM" {
				if "`commonevent'" == "" {
					qui sum `idv_`i'_1' if `event' <= `upp_bound' & `event' >= `low_bound' 
				}
				else{
					qui sum `idv_1' if `event' <= `upp_bound' & `event' >= `low_bound' 
				}
				scalar mean_mkt_ret = r(mean)
				scalar var_mkt_ret = r(Var)
				scalar n_mkt_ret = r(N)
				scalar corr_fac_den = var_mkt_ret*n_mkt_ret
				tempvar mean_resid
				if "`commonevent'" == "" {
					qui gen `mean_resid' = `idv_`i'_1' - mean_mkt_ret  
				}
				else{
					qui gen `mean_resid' = `idv_1' - mean_mkt_ret
				}
				qui sum `mean_resid' if `event' >= `evlbound_`j'' & `event' <= `evubound_`j''
				scalar corr_fac_num = r(sum)
				scalar corr_fac_num = corr_fac_num^2
				scalar carvariance_`i'_`j' = variance_`i' * (num + (num^2/m_ret_`i') + (corr_fac_num/corr_fac_den))
			}
			else if "`modtype'" == "HMM" {
				scalar carvariance_`i'_`j' = carvariance_`i'_`j' * (1 + num/m_ret_`i')
			}
			scalar sd = sqrt(carvariance_`i'_`j')
			local sd_`z'_`i'_`j' = sd
			qui scalar zstat = carvalue_`z'_`i'_`j'/sd 
			local testat_`z'_`i'_`j' = zstat
			
			local pval_`z'_`i'_`j' = 2*ttail((`= m_ret_`i' - `aux_nind' - 1'),abs(zstat))
			qui scalar pval_`z'_`i'_`j' = "(" + string(`pval_`z'_`i'_`j'' , "%5.4f") + ")" 
			
			scalar car_`z'_`i'_`j'=string(100 * carvalue_`z'_`i'_`j', "%12.`n_dec'f") 
			if "`nostar'" == "" {
				if `pval_`z'_`i'_`j''<0.01 {
					scalar star_`z'_`i'_`j' = "`delimiter_3'%***"
				}
				else if `pval_`z'_`i'_`j''<0.05 {
					scalar star_`z'_`i'_`j' = "`delimiter_3'%**"
				}
				else if `pval_`z'_`i'_`j''<0.1 {
					scalar star_`z'_`i'_`j' = "`delimiter_3'%*"
				}
				else {
					scalar star_`z'_`i'_`j' = "`delimiter_3'%"
				}
			}
			else {
				scalar star_`z'_`i'_`j' = "`delimiter_3'%"
			}
		}
	}
	if `nvars' > 1 { /* Compute AARs and their variance under the Normality Hypothesis */ 
		local nvars = `nvars'+1
		tempvar ar_`z'_`nvars'
		qui gen `ar_`z'_`nvars'' = .
		label var `ar_`z'_`nvars'' "CAAR group `z' (`spec_vars' securities)"
		local avg_aux_varlist = ""
		local rowmean_aux_varlist = ""
		forvalues i = 1/`spec_vars' {
			capture drop `expar_`i''
			tempvar expar_`i'
			qui gen `expar_`i'' = exp(`ar_`z'_`i'')
			
			local rowmean_aux_varlist = "`rowmean_aux_varlist' `expar_`i''"
		}
		tempvar exp_avgabret
		tempvar avgabret
		qui egen `exp_avgabret' = rowmean(`rowmean_aux_varlist')
		qui gen `avgabret' = ln(`exp_avgabret')  
				
		qui sum `avgabret' if `event' <= `upp_bound' & `event' >= `low_bound'
		scalar m_ret_`nvars' = r(N)
		
		qui replace `ar_`z'_`nvars'' = `avgabret' 
		
		forvalues j=1/`num_ev_wdws' {
			qui sum `avgabret' if (`event' >= `evlbound_`j'' & `event' <= `evubound_`j'')
			scalar carvalue_`z'_`nvars'_`j' = r(sum) 
			local carvalue_`z'_`nvars'_`j' = r(sum)
			scalar varsumcar_0_`j'=0
			forvalues k = 1/`spec_vars' {
				local kk = `k' - 1
				if carvariance_`k'_`j' == . {
					scalar varsumcar_`k'_`j' = varsumcar_`kk'_`j'
				}
				else {
					scalar varsumcar_`k'_`j' = varsumcar_`kk'_`j' + carvariance_`k'_`j'
				}
			}
			scalar car_`z'_`nvars'_`j'=string(100 * carvalue_`z'_`nvars'_`j', "%12.`n_dec'f") 
			scalar varcaar = varsumcar_`spec_vars'_`j'/(`spec_vars'^2) /* As in Mackinlay (1997) - EQ (18) */
			
			if "`diagnosticsstat'" == "" | "`diagnosticsstat'" == "Norm" { /* Diagnostic under the Normality Hypothesis */
				local str_diagn = "under the Normality assumption" 
				qui scalar zstat = carvalue_`z'_`nvars'_`j'/sqrt(varcaar) 
				local testat_`z'_`nvars'_`j' = zstat
				local sd_`z'_`nvars'_`j' = sqrt(varcaar)
				local pval_`z'_`nvars'_`j' = 2*ttail((`=m_ret_`nvars' - `aux_nind' - 1'),abs(zstat))
				qui scalar pval_`z'_`nvars'_`j' = "(" + string(`pval_`z'_`nvars'_`j'' , "%5.4f") + ")" 
			}

			else if "`diagnosticsstat'" == "Patell" | "`diagnosticsstat'" == "ADJPatell" { /* Perform the Patell test */
				forvalues i=1/`spec_vars' {
					local ii = `i' - 1
					scalar l2_`j'=r(N)
					scalar csar_`i'_`j' = carvalue_`z'_`i'_`j' / sqrt(carvariance_`i'_`j') /* Compute standardized CARs */
					scalar sumcsar_0_`j' = 0
					if csar_`i'_`j' == . {
						scalar sumcsar_`i'_`j' = sumcsar_`ii'_`j'
					}
					else {
						scalar sumcsar_`i'_`j' = sumcsar_`ii'_`j' + csar_`i'_`j' 
					}
					
					local exp_vars = 1
					if "`modtype'" == "MFM" { 
						local exp_vars = `nind'
					}
					scalar var_csar_`i' = (m_ret_`i' - `exp_vars' - 1)/(m_ret_`i' - `exp_vars' - 3) /* As in Pynnonen (2005) - EQ 24 */
					scalar sum_var_csar_0 = 0
					if var_csar_`i' == . {
						scalar sum_var_csar_`i' = sum_var_csar_`ii'
					}
					else {
						scalar sum_var_csar_`i' = sum_var_csar_`ii' + var_csar_`i'
					}
				}
				
				scalar zpatell = sumcsar_`spec_vars'_`j' / sqrt(sum_var_csar_`spec_vars') /* As in Patell (1976) - EQ(11) */
				if "`diagnosticsstat'" == "ADJPatell" { /* Perform the Adjusted Patell test */
					local str_diagn = "using the Patell test, with the Kolari and Pynnonen adjustment" 
					mata: C = J(`spec_vars', `spec_vars',.)
					forvalues ppp = 1/`=`spec_vars'-1' {
						forvalues kkk = `=`ppp'+1'/`spec_vars' { 
							qui corr `ar_`z'_`ppp'' `ar_`z'_`kkk'' if (`event' <= `upp_bound' & `event' >= `low_bound')
							mata: C[`kkk',`ppp'] = `r(rho)'
						}
					}
					mata : st_numscalar("rho_Kolari", mean(select(vech(C), vech(C) :< 1)))		
					scalar zpatell = zpatell/sqrt(1+(`spec_vars'-1)*rho_Kolari) /* As in Kolari Pynnonen (2010) - EQ (13) */
					local sd_`z'_`nvars'_`j' = sqrt(sum_var_csar_`spec_vars')*sqrt(1+(`spec_vars'-1)*rho_Kolari) /* Store ADJ Patell St Dev */
				}
				else {
					local str_diagn = "using the Patell test"
					local sd_`z'_`nvars'_`j' = sqrt(sum_var_csar_`spec_vars') /* Patell's St. Dev */
				}
				local testat_`z'_`nvars'_`j' = zpatell /* Store value of the statistic test */
			
				local pval_`z'_`nvars'_`j'=2*(1-normal(abs(zpatell)))
				qui scalar pval_`z'_`nvars'_`j' = "(" + string(`pval_`z'_`nvars'_`j'' , "%5.4f") + ")" 
			}
			
			else if "`diagnosticsstat'" == "BMP" | "`diagnosticsstat'" == "KP" { /* Perform the Boehmer Musumeci Paulsen test */
				scalar sum_std_car_0_`j' = 0
				forvalues i=1/`spec_vars' {
					scalar std_car_`i'_`j' = carvalue_`z'_`i'_`j'/sqrt(carvariance_`i'_`j')
					local ii = `i' - 1
					if std_car_`i'_`j' == . {
						scalar sum_std_car_`i'_`j' = sum_std_car_`ii'_`j'
					}
					else {
						scalar sum_std_car_`i'_`j' = sum_std_car_`ii'_`j' + std_car_`i'_`j'
					}
				}
				scalar lined_scar_`j'=sum_std_car_`spec_vars'_`j'/`spec_vars' /* A-bar of EQ (6) in Kolari Pynnonen (2010)  */
				
				scalar sum_sq_dif_scar_0_`j' = 0
				forvalues i=1/`spec_vars' {
					scalar sq_dif_scar_`i'_`j' = (std_car_`i'_`j' - lined_scar_`j')^2
					local ii = `i' - 1
					if sq_dif_scar_`i'_`j' == . {
						scalar sum_sq_dif_scar_`i'_`j' = sum_sq_dif_scar_`ii'_`j'
					}
					else {
						scalar sum_sq_dif_scar_`i'_`j' = sum_sq_dif_scar_`ii'_`j' + sq_dif_scar_`i'_`j'
					}
				}
				scalar s_lined_scar_`j' = sqrt(sum_sq_dif_scar_`spec_vars'_`j'/(`spec_vars'-1)) /* As in Kolari and Pynnonen (2010) - EQ (7) */
				scalar zbmp = sqrt(`spec_vars')*(lined_scar_`j' / s_lined_scar_`j') 
			
				if "`diagnosticsstat'" == "KP" { /* Perform the Kolari and Pynnonen test */
					local str_diagn = "using the Boehmer, Musumeci, Poulsen test, with the Kolari and Pynnonen adjustment" 
					mata: C = J(`spec_vars', `spec_vars',.)
					forvalues ppp = 1/`=`spec_vars'-1' {
						forvalues kkk = `=`ppp'+1'/`spec_vars' { 
							qui corr `ar_`z'_`ppp'' `ar_`z'_`kkk'' if (`event' <= `upp_bound' & `event' >= `low_bound')
							mata: C[`kkk',`ppp'] = `r(rho)'
						}
					}
					mata : st_numscalar("rho_Kolari", mean(select(vech(C), vech(C) :< 1)))
					scalar zbmp = zbmp * sqrt((1-rho_Kolari)/(1+(`spec_vars'-1)*rho_Kolari))
					local sd_`z'_`nvars'_`j' = (s_lined_scar_`j'/sqrt(1-rho_Kolari))*sqrt(1/`spec_vars')*sqrt(1+(`spec_vars'-1)*rho_Kolari) /* As in Kolari and Pynnonen (2010) - EQ(10) */
				}
				else {
					local str_diagn = "using the Boehmer, Musumeci, Poulsen test"
					local sd_`z'_`nvars'_`j' = s_lined_scar_`j'
				}
				local testat_`z'_`nvars'_`j' = zbmp
			
				local pval_`z'_`nvars'_`j'=2*(1-normal(abs(zbmp)))
				qui scalar pval_`z'_`nvars'_`j' = "(" + string(`pval_`z'_`nvars'_`j'' , "%5.4f") + ")" 
			}
		
			else if "`diagnosticsstat'" == "GRANK" { /* Perform the Generalized RANK test */
				local str_diagn = "using the Generalised Rank test by Kolari and Pynnonen"
				scalar sum_std_car_0_`j' = 0
				scalar sum_sq_dif_scar_0_`j' = 0
				local aux_num_lined_u = ""
		  		forvalues i=1/`spec_vars' {
					tempvar stdar_`i'_`j'
					qui gen `stdar_`i'_`j'' = .
					qui replace `stdar_`i'_`j'' = `ar_`z'_`i''/sqrt(variance_`i') if (`event' <= `upp_bound' & `event' >= `low_bound')
					qui scalar std_car_`i'_`j' = carvalue_`z'_`i'_`j'/sqrt(carvariance_`i'_`j')	
					local ii = `i' - 1
					if std_car_`i'_`j' == . {
						scalar sum_std_car_`i'_`j' = sum_std_car_`ii'_`j'
					}
					else {
						scalar sum_std_car_`i'_`j' = sum_std_car_`ii'_`j' + std_car_`i'_`j'
					}
				}
				scalar lined_scar_`j'=sum_std_car_`spec_vars'_`j'/`spec_vars'
				scalar sum_sq_dif_scar_0_`j' = 0
				forvalues i=1/`spec_vars' {
					scalar sq_dif_scar_`i'_`j' = (std_car_`i'_`j' - lined_scar_`j')^2
					local ii = `i' - 1
					if sq_dif_scar_`i'_`j' == . {
						scalar sum_sq_dif_scar_`i'_`j' = sum_sq_dif_scar_`ii'_`j'
					}
					else {
						scalar sum_sq_dif_scar_`i'_`j' = sum_sq_dif_scar_`ii'_`j' + sq_dif_scar_`i'_`j'
					}
				}
				scalar csec_sd_scar_`j' = sqrt(sum_sq_dif_scar_`spec_vars'_`j'/(`spec_vars'-1))
				forvalues i=1/`spec_vars' {
					qui replace `stdar_`i'_`j'' = std_car_`i'_`j'/csec_sd_scar_`j' if `event' == `=`upp_bound'+1' /* CAR period is squeezed in a single cumulative event day (as in Kolari and Pynnonen, 2011) */
					qui tempvar u_`i'_`j'
					local aux_num_lined_u = "`aux_num_lined_u' `u_`i'_`j''"
					qui egen `u_`i'_`j'' = rank(`stdar_`i'_`j'')
					qui replace `u_`i'_`j'' = `u_`i'_`j''/(`upp_bound'-`low_bound'+2) - 0.5 /* As in Kolari and Pynnonen (2011) - EQ (9) */
				}
				tempvar lined_u_`j'
				tempvar num_lined_u_`j'
				tempvar den_lined_u_`j'
				tempvar sq_lined_u_`j'
				qui egen `num_lined_u_`j'' = rowtotal(`aux_num_lined_u')
				qui egen `den_lined_u_`j'' = rownonmiss(`aux_num_lined_u')
				qui gen `lined_u_`j'' = `num_lined_u_`j'' / `den_lined_u_`j'' /* As in Kolari and Pynnonen (2011) - EQ (15) */
				qui egen `sq_lined_u_`j'' = rownonmiss(`aux_num_lined_u')
				qui replace `sq_lined_u_`j'' = `sq_lined_u_`j'' /`spec_vars' * `lined_u_`j''^2
				qui sum `sq_lined_u_`j''
				scalar s_u_lined_`j' = sqrt(r(sum)/(`upp_bound'-`low_bound'+1)) /* As in Kolari and Pynnonen (2011) - EQ (14) */
				qui sum `lined_u_`j'' if `event' == `=`upp_bound'+1'
				scalar u_lined_0_`j' = r(mean)
				scalar z_`j' = u_lined_0_`j'/s_u_lined_`j'  /* As in Kolari and Pynnonen (2011) - EQ (13) */
				scalar t_grank_`j' = z_`j'*sqrt((`upp_bound'-`low_bound'-1)/(`upp_bound'-`low_bound'-z_`j'^2)) /* As in Kolari and Pynnonen (2011) - EQ (12) */
				scalar t_grank_dof_`j' = `upp_bound'-`low_bound' + 1 - 2
				local pval_`z'_`nvars'_`j'=2*ttail(t_grank_dof_`j',abs(t_grank_`j'))
				qui scalar pval_`z'_`nvars'_`j' = "(" + string(`pval_`z'_`nvars'_`j'' , "%5.4f") + ")" 
				local testat_`z'_`nvars'_`j' = t_grank_`j' 
				local sd_`z'_`nvars'_`j' = s_u_lined_`j'
			}
		
			else if "`diagnosticsstat'" == "Wilcoxon" { /* Perform the Wilcoxon test */
				local str_diagn = "using the Generalised SIGN test by Wilcoxon"
				tempvar wilcox_`j'
				local aux_rank_varlist = ""
				forvalues i=1/`spec_vars' {
					tempvar abs_ar_`i'_`j'
					tempvar stdar_`i'_`j'
					tempvar rank_`i'_`j'
					qui gen `stdar_`i'_`j'' =.
					qui replace `stdar_`i'_`j'' = `ar_`z'_`i'' if (`event' <= `upp_bound' & `event' >= `low_bound')
					qui replace `stdar_`i'_`j'' = carvalue_`z'_`i'_`j' if `event' == `=`upp_bound'+1'
					qui gen `abs_ar_`i'_`j'' = abs(`stdar_`i'_`j'')
					qui egen `rank_`i'_`j'' = rank(`abs_ar_`i'_`j'')
					qui replace `rank_`i'_`j'' = . if `stdar_`i'_`j'' < 0
					local aux_rank_varlist = "`aux_rank_varlist' `rank_`i'_`j''"
				}
				qui egen `wilcox_`j'' = rowtotal(`aux_rank_varlist')
				qui sum `wilcox_`j'' if `event' == `=`upp_bound'+1'
				scalar wilcoxon_`j' = r(sum)
				scalar z_wilcoxon_`j' = (wilcoxon_`j'-`spec_vars'*(`spec_vars'+1)/4)/sqrt(`spec_vars'*(`spec_vars'+1)*(2*`spec_vars'+1)/24) /* As in Sprent and Smeeton (2001) p.72 - EQ (2.1) */
				local testat_`z'_`nvars'_`j' = z_wilcoxon_`j'
			
				local pval_`z'_`nvars'_`j'=2*(1-normal(abs(z_wilcoxon_`j')))
				qui scalar pval_`z'_`nvars'_`j' = "(" + string(`pval_`z'_`nvars'_`j'' , "%5.4f") + ")" 
				local sd_`z'_`nvars'_`j' = sqrt(`spec_vars'*(`spec_vars'+1)*(2*`spec_vars'+1)/24)
			}
			
			else if "`diagnosticsstat'" != "" { /* Check if the diagnostic stats is incorrectly specified */
				disp as error "Diagnosticstat is incorrectly specified" as text ""
				exit 198 /* Option incorrectly specified */ 
			}
			
			if "`nostar'" == "" {
				if `pval_`z'_`nvars'_`j''<0.01 {
					scalar star_`z'_`nvars'_`j' = "`delimiter_3'%***"
				}
				else if `pval_`z'_`nvars'_`j''<0.05 {
					scalar star_`z'_`nvars'_`j' = "`delimiter_3'%**"
				}
				else if `pval_`z'_`nvars'_`j''<0.1 {
					scalar star_`z'_`nvars'_`j' = "`delimiter_3'%*"
				}
				else {
					scalar star_`z'_`nvars'_`j' = "`delimiter_3'%"
				}
			}
			else {
				scalar star_`z'_`nvars'_`j' = "`delimiter_3'%"
			}
			
		}
	}
	
	if "`graph'" != "" {
		local aux_graph = "`graph'"
		gettoken gr_opt_left aux_graph : aux_graph , p(",") /* Tokenize to separate option arguments from suboptions */
		if "`aux_graph'" != "" { /* Checks if suboptions are correctly specified suboptions */
			tokenize "`aux_graph'"
			if "`3'" != "" {
				disp as err "Too many arguments specified in the graph suboption"
				exit 198 /* Option incorrectly specified */ 
			}
			else if "`2'" == "" {
				disp as err "Graph option incorrectly specified"
				exit 198 /* Option incorrectly specified */ 
			}
			else if "`2'" == "save" {
				local gr_suboption = "`2'" 
			}
			else {
				disp as err "Graph suboption incorrectly specified. Only save is allowed"
				exit 198 /* Option incorrectly specified */ 
			}
		}
		
		tokenize `gr_opt_left'
		if ("`1'" =="" | "`2'" == "") {
			disp as err "Option graph incorrectly specified. Two integers required"
			exit 198 /* Option incorrectly specified */
		}
		else if "`3'" != "" {
			disp as err "Two many arguments specified in the graph option"
			exit 198 /* Option incorrectly specified */ 
		}
		
		capture confirm integer number `1'
		if _rc != 0 {
			disp as err "Option graph incorrecly specified. The lower bound must be an integer"
			exit 198 /* Option incorrectly specified */
		}
		else {
			capture confirm integer number `2'
			if _rc != 0 {
				disp as err "Option graph incorrecly specified. The upper bound must be an integer"
				exit 198 /* Option incorrectly specified */ 
			}
		}
		if `1' >= `2' {
			disp as err "Option graphs incorrectly specified. Lower bound must be lower than upper bound"
			exit 198 /* Option incorrectly specified */ 
		}
		else if `1' < `upp_bound' {
			disp as err "Option graphs incorrectly specified. Lower bound must be higher than estimantion window's upper bound"
			exit 198 /* Option incorrectly specified */ 
		}
		
		local first_graph = 1
		local last_graph = `nvars'

		if "`suppress'" == "ind" {
			if "`commonevent'" != "" { /* Event study on common event date */ 
				local first_graph = `nvars' - 1
			}
			else { /* Event study on multiple event dates */
				local first_graph = `nvars'
			}
		}
		else if "`suppress'" == "group" {
			if "`commonevent'" != "" { /* Event study on common event date */
				local last_graph = `nvars' - 2
			}
			else { /* Event study on multiple event dates */
				local last_graph = `nvars' - 1
			}
		}
				
		forvalues i = `first_graph'/`last_graph' { /* Plot CAR graphs */ 
			qui sum `event' if `ar_`z'_`i'' !=.
			
			if (`1' < `r(min)' | `1' > `r(max)') & (`2' < `r(min)' | `2' > `r(max)') {
				disp as err "Option graphs incorrectly specified. Both lower and upper bounds are out of range"
				exit 198 /* Option incorrectly specified */
			}
			else if (`1' < `r(min)' | `1' > `r(max)') {
				disp as err "Option graphs incorrectly specified. The lower bound is out of range"
				exit 198 /* Option incorrectly specified */
			}
			else if (`2' < `r(min)' | `2' > `r(max)') {
				disp as err "Option graphs incorrectly specified. The upper bound is out of range"
				exit 198 /* Option incorrectly specified */
			}
			tempvar cumul_ar_`i'
			qui gen `cumul_ar_`i'' = sum(`ar_`z'_`i''*100) if (`event' >= `1' & `event' <= `2')
			
			local warn_label : variable label `ar_`z'_`i''
			if "`gr_suboption'" == "save" {
				qui graph twoway (line `cumul_ar_`i'' `event' if (`event' >= `1' & `event' <= `2')) , ///
				ytitle("CAR (%)") xtitle("Days") ///
				title("`warn_label'") ///
				name("varlist_`z'_variable_`i'") saving("Varlist_`z'_`warn_label'" , replace)
				graph close "varlist_`z'_variable_`i'"
			}
			else {
				noisily graph twoway (line `cumul_ar_`i'' `event' if (`event' >= `1' & `event' <= `2')) , ///
				ytitle("CAR (%)") xtitle("Days") ///
				title("`warn_label'") ///
				name("varlist_`z'_variable_`i'")
			}
		}
	}

	tempvar dim_label /* Compute the length of the longest label of the varlist */
	qui gen `dim_label' =.
	local i=1
	forvalues num = 1/`nvars' {
		tokenize "`varlist'" 
		local div_label : variable label `ar_`z'_`num''
		if strpos(`"`div_label'"', ".") > 0 {
			disp as err "The label of the variable ``num'' contains the invalid character '.'"
			exit 198 /* Option incorrectly specified */ 
		}
		
		local len_label : length local div_label
		if "`outputfile'" != "" | "`mydataset'" != "" {
			local max_lab_len 32
		}
		else {
			local max_lab_len 45
		}
		if `len_label' > `max_lab_len' {
			disp as err "Note: label of variable ``num'' truncated to `max_lab_len' characters" as text
			local div_label = substr(`"`div_label'"',1,`max_lab_len')
			label var `ar_`z'_`num'' `"`div_label'"'
			local len_label : length local div_label
		}
		qui capture set obs `num'
		qui replace `dim_label' = `len_label' in `num'
				
		if "`suppress'" == "group" {
			if "`commonevent'" != "" { /* Common event date */
				if `=`nvars'-`num'' > 1 {
					local otp_r_label_`zzz' : variable label `ar_`z'_`num'' /* Store variable labels for excel output except for groups */
					local ++zzz /* zzz is the number of variables to export */ 
				}
			}
			else { /* Multiple event date */
				if `=`nvars'-`num'' > 0 {
					local otp_r_label_`zzz' : variable label `ar_`z'_`num'' /* Store variable labels for excel output except for groups */
					local ++zzz /* zzz is the number of variables to export */ 
				}
			}
		}
		else if "`suppress'" == "ind" {
			if "`commonevent'" != "" { /* Common event date */
				if `=`nvars'-`num'' < 2 {
					local otp_r_label_`zzz' : variable label `ar_`z'_`num''  /* Store variable labels of groups only for excel output */
					local ++zzz 
				}
			}
			else { /* Multiple event date */
				if `=`nvars'-`num'' < 1 {
					local otp_r_label_`zzz' : variable label `ar_`z'_`num''  /* Store variable labels of groups only for excel output */
					local ++zzz 
				}
			}
		}
		else {
			local otp_r_label_`zzz' : variable label `ar_`z'_`num'' /* Store all variable labels for excel output  */
			local ++zzz 
		}
	}
	local space = 4 /* Compute the minimum length of the column between the column label and the column content */
	local dist_1=`n_dec' + 9 + `space'
	local dist_2=14 + `space'
	if `dist_1' > `dist_2' {
		local dist = `dist_1'
	}
	else{
		local dist = `dist_2'
	}
	forvalues name=1/`num_ev_wdws'{ /* Construct the column labels */
		scalar namecol_`name' = "CAAR[`lb`name'',`ub`name'']"
		local namecol_`name' = "CAAR[`lb`name'',`ub`name'']"
		local opt_c_label_`name' = "CAAR(`lb`name'',`ub`name'')" /* Store col labels */ 
	}
	local num_cols = `num_ev_wdws' + 1 /* Set the column length according to the preeceding code */
	qui sum `dim_label'
	local cols1_`z' = r(max) + `space'
	local dist3 = `n_dec' + 4
	local dist4 = `dist' - 10
	local start_nvars = 1
	
	
	if "`commonevent'" != "" {
		if "`suppress'" == "ind" { /* Condition to hide single CARs */
			local start_nvars = `nvars'-1
		}
		else if "`suppress'" == "group" { 
			local nvars = `nvars' - 2
		}
	}
	else {
		if "`suppress'" == "ind" { /* Condition to hide single CARs */
			local start_nvars = `nvars'
		}
		else if "`suppress'" == "group" { 
			local nvars = `nvars' - 1
		}	
	}
	
	local nvars_`z' = `nvars'
	local start_nvars_`z' = `start_nvars'

	mata: CAR_`z' = J(`=`nvars'-`start_nvars'+1', `num_ev_wdws',.)
	mata: PVAL_`z' = J(`=`nvars'-`start_nvars'+1',`num_ev_wdws',.)
	mata: CARSD_`z' = J(`=`nvars'-`start_nvars'+1',`num_ev_wdws',.)
	mata: STTEST_`z' = J(`=`nvars'-`start_nvars'+1',`num_ev_wdws',.)

	forvalues iii = 1/`=`nvars'-`start_nvars'+1' {
		if (`z' ==1 & `iii' == 1) {
			mata: ARS = st_data(.,("`ar_`z'_`=`iii' + `start_nvars' -1''")) /* Store estimated ARs in matrices AR_`N_of_varlist' */
		}
		else{
			capture mata: mata drop aux_ar_mat
			mata: aux_ar_mat = st_data(.,("`ar_`z'_`=`iii' + `start_nvars' -1''"))
			mata: ARS = ARS, aux_ar_mat
		}
		
		forvalues jjj=1/`num_ev_wdws' {
			mata: CAR_`z'[`iii',`jjj'] = `carvalue_`z'_`=`iii' + `start_nvars' -1'_`jjj''
			mata: PVAL_`z'[`iii',`jjj'] = `pval_`z'_`=`iii'+`start_nvars'-1'_`jjj''
			mata: CARSD_`z'[`iii',`jjj'] = `sd_`z'_`=`iii'+`start_nvars'-1'_`jjj''
			mata: STTEST_`z'[`iii',`jjj'] = `testat_`z'_`=`iii'+`start_nvars'-1'_`jjj''	
		}
	}
	if `z' == 1{
		mata: CAR = CAR_`z'
		mata: PVAL = PVAL_`z'
		mata: CARSD = CARSD_`z'
		mata: STTEST = STTEST_`z'
	}
	else{
		mata: CAR = (CAR\CAR_`z')
		mata: PVAL = (PVAL\PVAL_`z')
		mata: CARSD = (CARSD\CARSD_`z')
		mata: STTEST = (STTEST\STTEST_`z')
	}
} /* End of loop on z - > Nr of varlist */
*
local cols1_0 = 0
forvalues z=1/`p' {
	local zz = `z' - 1
	if `cols1_`z'' > `cols1_`zz'' {
		local cols1 = `cols1_`z''
	}
	else {
		local cols1 = `cols1_`zz''
	}
}
if "`suppress'" == "ind" { 
	local cols1 = 35 /* Length of first column when suppress "ind" is specified */
}
forvalues n=2/`num_cols' {
	local m=`n'-1
	local cols`n' = `cols`m'' + `dist'
} 
*
if "`commonevent'" != "" {
	local colsdate 0
}
else {
	local colsdate 12 /* Lenght of header of event dates column */
}
local width = `cols1' + (`num_cols')*(`dist' - `space') + `colsdate' /* lenght of line separating varlists in output table */
forvalues z = 1/`p' {
	if `z'==1 {
		if "`commonevent'" != "" {
			if "`tex'" != "" {
				disp as text "\title{Event date: " as result %td date("`evdate'","`dateformat'") as text ", with " ///
				as result `num_ev_wdws' as text " event windows specified, `str_diagn'}"
			}
			else {
				disp as text "Event date: " as result %td date("`evdate'","`dateformat'") as text ", with " ///
				as result `num_ev_wdws' as text " event windows specified, `str_diagn'"
			}
		}
		else{
			if "`tex'" != "" {
				disp as text "\title{Event study on multiple event dates, with " ///
				as result `num_ev_wdws' as text " event windows specified, `str_diagn'}"
			}
			else {
				disp as text "Event study on multiple event dates, with " ///
				as result `num_ev_wdws' as text " event windows specified, `str_diagn'"
			}
		}
		noisily display _column(1)  "SECURITY" "`delimiter_1'" _continue
		if "`commonevent'" != "" {
			forvalues k=1/`num_ev_wdws' {
				if `k' != `num_ev_wdws' {
					noisily display _column(`cols`k'') %`dist4's namecol_`k' _column(`cols`k'') "`delimiter_1'" _continue
				}
				else {
					noisily display _column(`cols`k'') %`dist4's namecol_`k' _column(`cols`k'') "`delimiter_2'"
				}
			}
		}
		else{
			forvalues k=1/`num_ev_wdws' {
				if `k' == 1 {
					noisily display  _column(`cols1') %`dist4's "EVENT DATE" "`delimiter_1'" _continue
				}
				if `k' != `num_ev_wdws' {
					noisily display _column(`=`cols`k'' + `colsdate'') %`dist4's namecol_`k' _column(`=`cols`k'' + `colsdate'') "`delimiter_1'" _continue
				}
				else {
					noisily display _column(`=`cols`k'' + `colsdate'') %`dist4's namecol_`k' _column(`=`cols`k'' + `colsdate'') "`delimiter_2'"
				}
			}
		}
		if "`tex'" != "" {
			disp "\midrule"
		}
		else {
			di as text "{hline `width'}"
		}
	}
	forvalues num = `start_nvars_`z''/`nvars_`z'' {
		local div_label : variable label `ar_`z'_`num''
		local names_col_`z'_`num' : variable label `ar_`z'_`num''
		noisily display _column(1)   "`div_label'" "`delimiter_1'" _continue
		if "`commonevent'" != "" {
			forvalues kk=1/`num_ev_wdws' {
				if `kk' != `num_ev_wdws' {
					noisily display _column(`cols`kk'')  %`dist3's scalar(car_`z'_`num'_`kk') _column(`cols`kk'') scalar(star_`z'_`num'_`kk') "`delimiter_1'" _continue
				}
				else {
					noisily display _column(`cols`kk'')  %`dist3's scalar(car_`z'_`num'_`kk') _column(`cols`kk'') scalar(star_`z'_`num'_`kk') "`delimiter_2'"
				}
			}
			if "`showpvalues'" != "" {
				forvalues kk=1/`num_ev_wdws' {
					if `kk' != `num_ev_wdws' {
						noisily display _column(`cols`kk'') "`delimiter_1'"  %~12s pval_`z'_`num'_`kk'  _continue
					}
					else {
						noisily display _column(`cols`kk'')  "`delimiter_1'" %~12s pval_`z'_`num'_`kk' "`delimiter_2'"
					}
				}
			}
		}
		else { 
			noisily display  _column(`cols1') %td evntdts_`z'_`num' "`delimiter_1'" _continue
			forvalues kk=1/`num_ev_wdws' {
				if `kk' != `num_ev_wdws' {
					noisily display _column(`= `cols`kk'' + `colsdate'')  %`dist3's scalar(car_`z'_`num'_`kk') _column(`= `cols`kk'' + `colsdate'') scalar(star_`z'_`num'_`kk') "`delimiter_1'" _continue
				}
				else {
					noisily display _column(`= `cols`kk'' + `colsdate'')  %`dist3's scalar(car_`z'_`num'_`kk') _column(`= `cols`kk'' + `colsdate'') scalar(star_`z'_`num'_`kk') "`delimiter_2'"
				}
			}
			if "`showpvalues'" != "" {
				noisily display _column(`cols1') "`delimiter_1'" _continue
				forvalues kk=1/`num_ev_wdws' {
					if `kk' != `num_ev_wdws' {
						noisily display _column(`= `cols`kk'' + `colsdate'') "`delimiter_1'" %~12s pval_`z'_`num'_`kk'  _continue
					}
					else {
						noisily display _column(`= `cols`kk'' + `colsdate'')  "`delimiter_1'" %~12s pval_`z'_`num'_`kk' "`delimiter_2'"
					}
				}
			}	
		}
	}
	if "`tex'" != "" {
		disp "\midrule"
	}
	else {
		di as text "{hline `width'}"
	}
}
if "`nostar'" == "" {
	if "`tex'" != "" {
		disp as text "\caption{*** p-value < .01, ** p-value <.05, * p-value <.1}"
	}
	else {
		disp as text "*** p-value < .01, ** p-value <.05, * p-value <.1"
	}
}
if "`showpvalues'" != "" {
	if "`tex'" != "" {
		disp as text "\caption{p-values in parentheses}"
	}
	else {
		disp as text "p-values in parentheses"
	}
}
	tempname AUX_ARS
	local rcount 0 
	mata: st_numscalar("n_of_cols", cols(ARS))
	mata: st_numscalar("n_of_rows", rows(ARS))
	local n_of_cols = n_of_cols
	local n_of_rows = n_of_rows
	forvalues r = 1/`n_of_rows' {
		mata: st_numscalar("mx",max(ARS[`r',.]))
		if (mx<.) {
		local ++rcount
			local auxarrnames = `event' in `r'
			local arrnames `"`arrnames'"`auxarrnames'" "'
			if `rcount' == 1 {
				mata: `AUX_ARS' = ARS[`r',1..`n_of_cols']
			}
			else {
				mata: `AUX_ARS' = `AUX_ARS'\ARS[`r',1..`n_of_cols']
			}
		}
	}
	
	mata: st_matrix("S_CAR", CAR)
	mata: st_matrix("P_VAL", PVAL)
	mata: st_matrix("SD_CAR", CARSD)
	mata: st_matrix("ST_TEST", STTEST)  
	mata: st_matrix("AR", `AUX_ARS')
	
	forvalues i=1/`=rowsof(S_CAR)' {
		local rnames `"`rnames'"`otp_r_label_`i''" "'
	}
	mat rownames S_CAR=`rnames'
	mat rownames P_VAL=`rnames'
	mat rownames SD_CAR=`rnames'
	mat rownames ST_TEST=`rnames'
	
	mat rownames AR = `arrnames' 
	mat colnames AR = `rnames'
	
	forvalues ii=1/`=colsof(S_CAR)' {
		local cnames `"`cnames'"`opt_c_label_`ii''" "'
	}
	mat colnames S_CAR=`cnames'
	mat colnames P_VAL=`cnames'
	mat colnames SD_CAR=`cnames'
	mat colnames ST_TEST=`cnames'
if "`outputfile'" != "" | "`mydataset'" != "" {
	if "`outputfile'" != "" {
		qui putexcel A1=matrix(S_CAR, names) using "`outputfile'", sheet("CAR") replace
		qui putexcel A1=matrix(P_VAL, names) using "`outputfile'", sheet("PVALUES") modify
		qui putexcel A1=matrix(SD_CAR, names) using "`outputfile'", sheet("STDEV") modify
		qui putexcel A1=matrix(ST_TEST, names) using "`outputfile'", sheet("STTEST") modify
	}
	
	if "`mydataset'" != "" {
		tempvar security_name
		qui gen `security_name' = ""
		forvalues i=1/`=`zzz'-1' {
			qui capture set obs `i'
			qui replace `security_name' = "`otp_r_label_`i''" in `i'
		}
	
		tempvar event_window_
		svmat S_CAR, names(`event_window_')
		qui keep `security_name' `event_window_'*
		qui gen security_name=`security_name'
		label var security_name "Security Name"
		forvalues i=1/`num_ev_wdws'{
			capture qui gen event_wdw_`i' = `event_window_'`i'
			capture label var event_wdw_`i' "`namecol_`i''"
		}
		drop `security_name' `event_window_'*
		qui keep in 1/`=`zzz'-1'
		save "`mydataset'", replace
		qui capture restore
	}
}
*

return matrix ar = AR
return matrix stats = ST_TEST
return matrix sd = SD_CAR
return matrix pv = P_VAL
return matrix cars = S_CAR


qui gsort+ `obsn'
qui capture drop if `obsn' == .
qui mata: mata clear
qui scalar drop _all
clear results
qui capture restore
end
exit
