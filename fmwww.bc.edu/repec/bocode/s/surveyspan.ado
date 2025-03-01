
capture program drop surveyspan

program surveyspan, rclass

    version 13

	* surveyspan needs to be an R class command because we are generating a new variable. 

    syntax varlist(min=2 max=2) [if] [, GENerate(string) MAXtime(real 0) MINtime(real 0) Cutoff(real 17) GROUPvar(varname) OUTfile(string)]
    
    quietly {
		
		********************************************************************************
		* Section 1: Standard set-up  
		********************************************************************************
		
        * Store if/in condition
		
        marksample touse, strok
        
		* Get the variable names for start and end time 
		
		local start_time: 	word 1 of `varlist'
		local end_time: 	word 2 of `varlist'
		
		* Check if start and end variables exist and are strings (in the right format)
		
		capture confirm variable `start_time'
		if _rc {
			di as error "	Error: Variable `start_time' not found in dataset"
			exit 111
		}

		capture confirm variable `end_time'
		if _rc {
			di as error "	Error: Variable `end_time' not found in dataset"
			exit 111
		}
		
		capture confirm string variable `start_time'
		if _rc {
			di as error "	Error: Variable `start_time' must be a string variable"
			exit 109
		}

		capture confirm string variable `end_time'
		if _rc {
			di as error "	Error: Variable `end_time' must be a string variable"
			exit 109
		}
		

		foreach var in `start_time' `end_time' {   
			
		count if !regexm(`var', "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]?T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]") & `touse'
		local invalid = r(N)  
    
		if `invalid' > 0 {  
			di as error "    Error: `var' contains `invalid' values not in YYYY-MM-DDThh:mm:ss format"
			exit 198
		}
		}

		* There needs to be at least one observation for this module to work 

		count if `touse'
		if r(N) == 0 {
			di as error "	No observations meet the current criteria"
			exit 2000
		}
			
	
		* Validate cutoff parameter
		
		if `cutoff' < 0 | `cutoff' > 23 {
			di as error "	Error: cutoff() must be between 0 and 23 (representing hours in a 24-hour format)"
			exit 198
		}
		
		* Min and max times cannot be negative
		
		if `mintime' < 0 {
			di as error "	Error: mintime() cannot be negative"
			exit 198
		}

		if `maxtime' < 0 {
			di as error "	Error: maxtime() cannot be negative"
			exit 198
		}
		
		if `maxtime' > 0 & `mintime' > 0 & `mintime' >= `maxtime' {
			di as error "	Error: mintime(`mintime') must be less than maxtime(`maxtime')"
			exit 198
		}		
						
        * Get the name for the output variable, default to "survey_span" if not provided
		
        local duration_var 		"survey_span"
			
		if "`generate'" != "" {
			
		capture confirm variable `generate'
		if !_rc {
			di as error "	Variable `generate' already exists in the dataset"
			exit 110
		}
		
		local duration_var "`generate'"
		}
		
		if "`groupvar'" != "" {
			
		capture confirm variable `groupvar'
		if _rc {
			di as error "	Error: Grouping variable `groupvar' does not exist"
			exit 110
		}
			
		* Create default output filename if none is specified
		
		if "`outfile'" == "" {
			local datetime = 	subinstr("`c(current_date)'"," ","",.)  
			local shortdate = 	substr("`datetime'", 1, 5) + substr("`datetime'", -2, .) 
			local time = 		subinstr("`c(current_time)'", ":", "-", .)
			local outfile "surveyspan_`shortdate'_`time'.xlsx"
		}
    
		* Add .xlsx extension if not present
		
		if !regexm("`outfile'", "\.xlsx$") {
			local outfile "`outfile'.xlsx"
		}
}
		
		********************************************************************************
		* Section 2: Correctly calculate the duration   
		********************************************************************************
        
        * Create temporary variables for intermediate calculations
		
        tempvar start_adj end_adj time_begins time_ends time_begins_dt after_cutoff
            
        * Convert timestamps to proper format
		
		gen `start_adj' = 	`start_time'
		gen `end_adj' = 	`end_time'

		replace `start_adj' = "" 		if `touse' != 1
		replace `end_adj' = "" 			if `touse' != 1
        
        * Fix single-digit days (convert 9T to 09T) - this is an identified bug with KoboToolbox
		
		replace `start_adj' = 	cond(substr(`start_adj',10,1) == "T", 	substr(`start_adj',1,8) + "0" + substr(`start_adj',9,.),`start_adj') 	if `touse'
		replace `end_adj' = 	cond(substr(`end_adj',10,1) == "T", 	substr(`end_adj',1,8) + "0" + 	substr(`end_adj',9,.),`end_adj') 		if `touse'
		     
        * Generate time variables
		
        gen `time_begins' = 	substr(`start_adj',1,10) + 	" " + substr(`start_adj',12,8) 	if `touse'
        gen `time_ends' = 		substr(`end_adj',1,10) + 	" " + substr(`end_adj',12,8) 	if `touse'
		     
        * Generate datetime format for start time and after cutoff indicator
		
        gen double `time_begins_dt' = clock(`time_begins', "YMDhms") if `touse'
        format `time_begins_dt' %tc
		
        gen `after_cutoff' = hh(`time_begins_dt') >= `cutoff' & !missing(`time_begins_dt') if `touse'
        
        * Calculate duration
		
        gen `duration_var' = . if `touse'
        replace `duration_var' = (clock(`time_ends',"YMDhms") - clock(`time_begins',"YMDhms"))/60000 ///
            if (!missing(`start_adj') & !missing(`end_adj') & `touse')
			
		label variable `duration_var' "`end_time' - `start_time' (in minutes)"
		
        * Count and report negative duration values
		
        local neg_count = 0
        count if `duration_var' < 0 & `touse'
        local neg_count = r(N)
        
        * Replace negative durations to missing
		
        if `neg_count' > 0 {
            replace `duration_var' = . if `duration_var' < 0 & `touse'
        }
        
        * Check and remove surveys longer than maximum time
		
        local above_max = 0
        if `maxtime' > 0 {
            count if `duration_var' > `maxtime' & !missing(`duration_var') & `touse'
            local above_max = r(N)
            replace `duration_var' = . if `duration_var' > `maxtime' & `touse'
        }
        
        * Check for surveys shorter than minimum time (but don't remove them)
		
        local below_min = 0
        if `mintime' > 0 {
            count if `duration_var' < `mintime' & !missing(`duration_var') & `touse'
            local below_min = r(N)
        }
        
        * Calculate statistics based on the cleaned data
		
		count if `touse'
		local total_obs = r(N)
		
		sum `duration_var' if `touse', detail
		local obs = r(N)
		local var_mean = r(mean)
		local var_median = r(p50)
		local var_sd = r(sd) 

		* Calculate observations within 1 SD
		count if (`duration_var' >= `var_mean' - `var_sd') & ///
			   (`duration_var' <= `var_mean' + `var_sd') & ///
			   !missing(`duration_var') & `touse'
			   
		local within_sd_count = r(N)
		local within_sd_pct = round(r(N) / `obs' * 100, 0.1)
		local within_sd_pct_display = string(round(r(N) / `obs' * 100, 0.01), "%5.2f")
		
        * Calculate after cutoff statistics (but only when the duration variable is also included)
		
		count if `after_cutoff' == 1 & !missing(`duration_var') & `touse'
        local after_cutoff_count = r(N)
        local after_cutoff_pct = round(`after_cutoff_count' / `obs' * 100, 0.1)
		local after_cutoff_pct_display = string(round(`after_cutoff_count' / `obs' * 100, 0.01), "%5.2f")
		
	
 		********************************************************************************
		* Section 3: Excel output 
		********************************************************************************
		
		* If groupvar option is specified, create Excel output
		
		if "`groupvar'" != "" {
		preserve
	   
		* First, create total observations indicator before any filtering
		
		gen total_obs = 1 if `touse'
		
		* Create binary indicators
		
		gen late_upload = `after_cutoff' == 1 if !missing(`duration_var') 
		
		* Create below threshold indicator
		
		gen below_threshold = 0 if !missing(`duration_var')
		
		if `mintime' > 0 {
			replace below_threshold = 1 if `duration_var' < `mintime' & !missing(`duration_var')
			local threshold_label "less than `mintime' minutes"
		}
		else {
			sum `duration_var' if `touse', detail
			local threshold = r(mean) - (2 * r(sd))
			replace below_threshold = 1 if `duration_var' < `threshold' & !missing(`duration_var')
			local threshold_label "more than 2 standard deviations below mean"
		}
	   
		* Now collapse with all indicators properly set up 
		
		collapse 	(sum) 	total_obs ///
					(mean) 	mean_duration=`duration_var' ///
					(p50) 	median_duration=`duration_var' ///
					(sd) 	sd_duration=`duration_var' ///
					(sum) 	late_uploads=late_upload ///
					(sum) 	flagged_short=below_threshold ///
					(count) obs=`duration_var' ///
				if `touse', by(`groupvar')
		
		* Calculate excluded as difference between total and valid observations      
		
		gen excluded = total_obs - obs
		
		* Generate percentage columns using total_obs as denominator
		
		gen pct_excluded = 	round(excluded/total_obs * 100, 0.01)
		
		* Generate percentage columns using obs as denominator
		
		gen pct_late = 		round(late_uploads/obs * 100, 0.01)
		gen pct_flagged = 	round(flagged_short/obs * 100, 0.01)

			
		* Add variable labels
		
		label variable total_obs 				"Total Observations"
		label variable obs 						"Observations Used for Analysis"
		label variable excluded 				"Excluded Observations"
		label variable pct_excluded 			"Percent of Observations Excluded"
		label variable mean_duration 			"Mean Duration (minutes)"
		label variable median_duration 			"Median Duration (minutes)"
		label variable sd_duration 				"Standard Deviation of Duration"
		label variable late_uploads 			"Number of Surveys After `cutoff':00 hours"
		label variable pct_late 				"Percent of Total Surveys After `cutoff':00 hours"
		label variable flagged_short 			"Number of Surveys `threshold_label'"
		label variable pct_flagged 				"Percent of Total Surveys `threshold_label'"
		label variable `groupvar' 				"Grouping variable"
		
	   * Format statistics
	   
	   format mean_duration median_duration sd_duration pct_excluded pct_flagged pct_late %9.2f
	   
	   order `groupvar' total_obs obs excluded pct_excluded ///
	   mean_duration median_duration sd_duration /// 
	   late_uploads pct_late flagged_short pct_flagged
	   
	   * Export to Excel with variable labels
	   
	   export excel using "`outfile'", sheet("Summary Stats") firstrow(varlabels) replace
		
	   * Set OS-appropriate path separator
	   
	   local sep = cond("`c(os)'" == "Windows", "\", "/")

	   restore
  
     }  
	 
} 	 
        * Store results in the return list

		return scalar total_obs = 			`total_obs'
		return scalar obs = 				`obs'
        return scalar mean = 				`var_mean'
        return scalar median = 				`var_median'
		return scalar sd = 					`var_sd' 
		return scalar within_sd_pct = 		`within_sd_pct' 
        return scalar aft_cutoff_count = 	`after_cutoff_count'
        return scalar aft_cutoff_pct = 		`after_cutoff_pct'	

	********************************************************************************
	* Section 4: Display text
	********************************************************************************
	
    * Display text - outside the quietly block
	
	display as result 	"	"
	display as result 	"	Total observations:               " %9.2f `total_obs'
	display as result 	"	Observations with valid durations:" %9.2f `obs'
    display as result	"	Mean:                             " %9.2f `var_mean' 
    display as result	"	Median:                           " %9.2f `var_median'
	display as result 	"	Standard deviation:               " %9.2f `var_sd'
	display as result 	"	`within_sd_count' (`within_sd_pct_display'%) of observations were within one standard deviation of the mean"
	display as result 	"	`after_cutoff_count' (`after_cutoff_pct_display'%) of observations started after `cutoff':00 hours"
	
    if `neg_count' > 0 {
	display as result 	"	"	
    display as result	"	Number of observations with negative duration: `neg_count'."
	display as result	"	These negative observations have not been used for the purposes of the calculations."
    }
    
    if `mintime' > 0 {
	display as result 	"	"	
    display as result 	"	Number of surveys completed in less than `mintime' minutes: `below_min'"
	display as result 	"	Percentage of surveys completed in less than `mintime' minutes: " %5.2f (`below_min'/`obs')*100
    }
    
    if `maxtime' > 0 {
	display as result 	"	"		
    display as result 	"	Surveys longer than `maxtime' minutes: `above_max'"
	
		if `above_max' > 0 {
		display as result	"	These observations above the maximum time duration have not been used for the purposes of the calculations."
    }

    }
	
    if "`groupvar'" != "" {

	display as result 	""
	display as result 	`"	Excel report has been generated: {browse "`c(pwd)'`sep'`outfile'"}"'
    }
    
    quietly {
        if "`generate'" == "" {
            drop `duration_var'
        }
    }
end

