*! NDM edited version 2025-10-02
*! SPJ edited version 2025-08-28
*! version 1.0.0 16jan2025

/* -----------------------------------------------------------------------------
** PROGRAM NAME: cgmstats
** -----------------------------------------------------------------------------
** CREATED BY: NATALIE DAYA MALEK (ndaya1@jh.edu)
** -----------------------------------------------------------------------------
** PURPOSE: THIS PROGRAM IS DESIGNED TO PROCESS, SUMMARIZE AND VISUALIZE DATA 
FROM CONTINUOUS GLUCOSE MONITORS
*/

capture log close

log using cgmstats.log, text replace

program define cgmstats
	version 12.0
	syntax [if] [in], id(string) glucose(string) time(string) dtadir(string) ///
		[freq(integer 15)] [unit(string)] [by(string)] [keep(string)] ///
		[hyper(numlist max=300)] [hypo(numlist max=300)] ///
		[hyper_exc_lngth(integer 30)] [hypo_exc_lngth(integer 30)] ///
		[daystart(string)] [dayend(string)] ///
		[firsthours(real -99)] [lasthours(real -99)]  ///
		[timebefore(string)] [timeafter(string)] [auc] ///
		[hist(string)] [plot(string)] ///
		[savecombdta(string)] [savecombdir(string)] ///
		[savesumdta(string)] [savesumdir(string)] ///
		[saveplotdir(string)]  

*****************************************************************************
* (1) create "combined" dta file for processing from files in user-specified ///
	directory (`dtadir'), and (optionally) save 
* (2) process "combined" file, and (optionally) save summary data and graphs
*****************************************************************************

	
	local dtaflist : dir "`dtadir'" files "*.dta"  // put input file list into local
	di `dtaflist'
 

* get number of files
	local wc : word count `dtaflist'
* read first dta file in; append the remaining ones
	forvalues f = 1/`wc' {
		local w`f' : word `f' of `dtaflist'
	}

qui {
	use "`dtadir'/`w1'", clear
	forvalues f = 2/`wc' {
		append using "`dtadir'/`w`f''"
	}

	if "`keep'" != "" {
		keep `keep' 
	}

	if "`timebefore'" != "" {
		keep if `time' < clock("`timebefore'", "YMDhm")
	}


	if "`timeafter'" != "" {
		keep if `time' > clock("`timeafter'", "YMDhm")
	}	
		
* Optionally save the "combined dta" to specified directory
* 	(if dir not specified, defaults to cwd)
	compress
	if "`savecombdta'" != "" & "`savecombdir'" != ""  ///
		save "`savecombdir'"/"`savecombdta'", replace
	if "`savecombdta'" != "" & "`savecombdir'" == "" save `savecombdta', replace


	marksample touse
	keep if `touse'
		
	if "`daystart'" == "" local daystart "06:00"
	if "`dayend'" == "" local dayend "23:00"

		
// Check if the timestamp format matches the expected format %tcCCYY/NN/DD_HH:MM
	local fmt: format `time'
		if "`fmt'" == "%tcCCYY/NN/DD_HH:MM" {
			noi display as result "Timestamp is in the correct format: `fmt'"
		}
		else {
			noi display as error /// 
		"Timestamp in wrong format %tcCCYY/NN/DD_HH:MM. Current format: `fmt'"
			exit 198
		}

* If duplicates are found, throw an error
	bysort `id' `time' : gen dup = cond(_N== 1, 0, _n)

	if sum(dup) > 0 {
		noi di as error "Error: Duplicate timestamps detected!"
		duplicates list `id' `time'      
		exit 1
	}

	else {
		 noi di as result "No duplicate timestamps found. Proceeding ..." 
	}

	drop dup

*extract date without time
	gen NEWdate = dofc(`time')
	format NEWdate %td
	sort `id' `time'
		
*total # of unique days with sensor data
	bys `id' NEWdate: gen unique_num_days = _n == 1
	by `id': replace unique_num_days = sum(unique_num_days)
	by `id': gen num_days = unique_num_days[_N]	
		
	if `firsthours' != 0 {		
			by `id': gen timestamp_p1 = `time'[1] + (3600000 * (`firsthours'))
			format timestamp_p1 %tcCCYY/NN/DD_HH:MM
			drop if `time' <= timestamp_p1 ///
					& !missing(timestamp_p1) & `firsthours' != 0
	}

	if `lasthours' != 0 {
			by `id': gen timestamp_m1 = `time'[_N] - (3600000 * (`lasthours'))
			format timestamp_m1 %tcCCYY/NN/DD_HH:MM
			drop if `time' >= timestamp_m1 & !missing(`time') & `lasthours' != 0
	}

	drop unique_num_days num_days 
	capture drop timestamp_p1 timestamp_m1
			
	bys `id' NEWdate: gen unique_num_days = _n == 1
	by `id': replace unique_num_days = sum(unique_num_days)
	by `id': gen num_days = unique_num_days[_N]


	**# If user indicates by(day)

	if "`by'" == "day" {
			
		levelsof unique_num_days if "`by'" == "day", local(days)

		foreach g in `days' {
			
			preserve

			keep if unique_num_days == `g'

			*calculate difference between consecutive readings (in minutes)
			by `id': gen difftime = clockdiff(`time', `time'[1], "minute")
			replace difftime = abs(difftime)

			by `id': gen time_int = difftime - difftime[_n-1]


			*standard CGM summary statistics 
			bysort `id': egen total_counts = count(`id')
			bysort `id': egen mean_sensor = mean(`glucose')
			bysort `id': egen median_sensor = median(`glucose')
			bysort `id': egen sd_sensor = sd(`glucose')
			bysort `id': egen q1_sensor = pctile(`glucose'), p(25)
			bysort `id': egen q3_sensor = pctile(`glucose'), p(75)

			gen cv_sensor = 100 * (sd_sensor/mean_sensor)

			bysort `id': egen min_sensor = min(`glucose')
			bysort `id': egen max_sensor = max(`glucose')
				
			bysort `id' unique_num_days: egen avg_max_sensor = max(`glucose') 
			by `id' unique_num_days: gen dup = cond(_N== 1, 0, _n)
			replace avg_max_sensor = . if dup > 1
			drop dup

			by `id': gen sensorcount = !missing(`glucose')
			by `id': egen total_sensor_readings = sum(sensorcount)

			by `id': ///
				gen total_time ///
					= clockdiff(`time'[1],`time'[_N], "minute") + `freq'

			gen ndayswear = round(total_time / 60 / 24, 0.1)
				
			gen total_wear = (total_time/`freq')
			
			gen percent_cgm_wear ///
					= (round(100 * total_sensor_readings/total_wear, 0.1)) if ///
					(unique_num_days == 1)|(unique_num_days == num_days)

			replace percent_cgm_wear ///
				= (round(100 * total_sensor_readings/(1440/`freq'), 0.1)) if ///
					(unique_num_days != 1) & ///
					(unique_num_days != num_days)
					
			gen month = month(NEWdate)
			gen day = day(NEWdate)
			gen year = year(NEWdate)
		  
			local hour_strt = hh(clock("`daystart'", "hm"))
			local min_strt = mm(clock("`daystart'", "hm"))

			local hour_end = hh(clock("`dayend'", "hm"))
			local min_end = mm(clock("`dayend'", "hm"))

			gen double datetime_start = ///
				mdyhms(month, day, year, `hour_strt',`min_strt',00) 
					//code to allow users to choose day start and end
			format datetime_start %tc

			gen double datetime_end ///
				= mdyhms(month, day, year, `hour_end', `min_end', 00) 
				//code to allow users to choose day start and end
			format datetime_end %tc

			gen time_day = `freq' * (`time' < datetime_end & `time' > ///
				datetime_start)
			by `id': egen total_time_day = sum(time_day)

			gen time_night = `freq' ///
							   * (`time' >= datetime_end | `time' <= ///
								datetime_start)
			by `id': egen total_time_night = sum(time_night)
			
			bysort `id': egen sd_sensor_day = sd(`glucose') ///
							if (`time' < datetime_end & `time' > datetime_start)
			bysort `id': egen mean_sensor_day = mean(`glucose') ///
							if (`time' < datetime_end & `time' > datetime_start)
			bysort `id': egen median_sensor_day = median(`glucose') ///
							if (`time' < datetime_end & `time' > datetime_start)
			gen cv_sensor_day = 100 * (sd_sensor_day/mean_sensor_day)
			bysort `id': egen q1_sensor_day = pctile(`glucose') ///
							if (`time' < datetime_end & `time' > datetime_start) ///
							, p(25)
			bysort `id': egen q3_sensor_day = pctile(`glucose') ///
							if (`time' < datetime_end & `time' > datetime_start) ///
							, p(75)
			bysort `id': egen min_sensor_day = min(`glucose') ///
							if (`time' < datetime_end & `time' > datetime_start)
			bysort `id': egen max_sensor_day = max(`glucose') ///
							if (`time' < datetime_end & `time' > datetime_start)
					
			bysort `id': egen sd_sensor_night = sd(`glucose') ///
							if (`time' >= datetime_end | `time' <= datetime_start)
			bysort `id': egen mean_sensor_night = mean(`glucose') ///
							if (`time' >= datetime_end | `time' <= datetime_start) 
			gen cv_sensor_night = 100 * (sd_sensor_night/mean_sensor_night)
			bysort `id': egen median_sensor_night = median(`glucose') ///
							if (`time' >= datetime_end | `time' <= datetime_start)
			bysort `id': egen q1_sensor_night = pctile(`glucose') ///
							if (`time' >= datetime_end | `time' <= datetime_start) ///
							, p(25)
			bysort `id': egen q3_sensor_night = pctile(`glucose') ///
							if (`time' >= datetime_end | `time' <= datetime_start) ///
							, p(75)
			bysort `id': egen min_sensor_night = min(`glucose') ///
							if (`time' >= datetime_end | `time' <= datetime_start)
			bysort `id': egen max_sensor_night = max(`glucose') ///
							if (`time' >= datetime_end | `time' <= datetime_start)
		

			*Hyperglycemic excursions (user-specified length)
					
			if "`hyper'" == "" & "`unit'" == "" local hyper 140 180 250 
			if "`hyper'" == "" & "`unit'" != "" local hyper 7.8 10 13.9 
				
			foreach num of numlist `hyper' {

				sort `id' `time'
						
				local num_hyper_rnd = subinstr("`num'", ".", "_", .)
			
				by `id': gen flag_over_`num_hyper_rnd' = 1 ///
							if (`glucose' > `num' & !missing(`glucose')) ///
							& ((`glucose'[_n+1] > `num') ///
							& !missing(`glucose'[_n+1])) | ///
								((`glucose'[_n-1] > `num') ///
							& !missing(`glucose'[_n-1]))
				
				by `id': gen exc_over_`num_hyper_rnd' ///
							= flag_over_`num_hyper_rnd' == 1 ///
								& flag_over_`num_hyper_rnd'[_n-1] == .
						
				by `id': gen n_over_`num_hyper_rnd' ///
							= sum(exc_over_`num_hyper_rnd')
				replace n_over_`num_hyper_rnd' = . ///
							if flag_over_`num_hyper_rnd' == .

				sort `id' n_over_`num_hyper_rnd' `time'
				by `id' n_over_`num_hyper_rnd': ///
				gen hyper_lngth_`num_hyper_rnd' = ((`time'[_N]-`time'[1]))/60000 ///
							if !missing(n_over_`num_hyper_rnd')
				replace hyper_lngth_`num_hyper_rnd' ///
							= hyper_lngth_`num_hyper_rnd' + `freq' ///
							if !missing(hyper_lngth_`num_hyper_rnd')
						
				replace exc_over_`num_hyper_rnd' = 0 ///
					if exc_over_`num_hyper_rnd' == 1 ///
					& hyper_lngth_`num_hyper_rnd' < `hyper_exc_lngth'
				replace hyper_lngth_`num_hyper_rnd' = . ///
					if exc_over_`num_hyper_rnd' != 1
						
				drop flag_over_`num_hyper_rnd'
				drop n_over_`num_hyper_rnd'		
			}	
		
			sort `id' `time' 
					
			*min_spent_over_X		
			foreach num of numlist `hyper' {

				local num_hyper_rnd = subinstr("`num'", ".", "_", .)
					
				by `id': gen time_spent_over_`num_hyper_rnd' ///
								= `freq' * (`glucose' > `num' & !missing(`glucose'))
				by `id': egen min_spent_over_`num_hyper_rnd' ///
								= sum(time_spent_over_`num_hyper_rnd')
			}
				

			foreach num of numlist `hyper' {

				local num_hyper_rnd = subinstr("`num'", ".", "_", .)
					
				by `id': gen time_spent_over_`num_hyper_rnd'_night ///
							= `freq' * (`glucose' > `num' ///
								& !missing(`glucose') ///
								& (`time'>=datetime_end | `time' ///
								<= datetime_start))
				by `id': egen min_spent_over_`num_hyper_rnd'_night ///
								= sum(time_spent_over_`num_hyper_rnd'_night)
			}
					
			foreach num of numlist `hyper' {

				local num_hyper_rnd = subinstr("`num'", ".", "_", .)
						
				by `id': gen time_spent_over_`num_hyper_rnd'_day ///
							= `freq' * (`glucose' > `num' ///
								& !missing(`glucose') ///
								& (`time' < datetime_end ///
								& `time' > datetime_start))
				by `id': egen min_spent_over_`num_hyper_rnd'_day ///
									= sum(time_spent_over_`num_hyper_rnd'_day)
			}
						
			*percent_time_over_X
			foreach num of numlist `hyper' {
				local num_hyper_rnd = subinstr("`num'", ".", "_", .)
						
				gen percent_time_over_`num_hyper_rnd' ///
							= 100 * (min_spent_over_`num_hyper_rnd'/total_time)
				gen percent_time_over_`num_hyper_rnd'_day ///
						= 100 * (min_spent_over_`num_hyper_rnd'_day/ ///
						total_time_day)
				gen percent_time_over_`num_hyper_rnd'_night ///
						= 100 * (min_spent_over_`num_hyper_rnd'_night/ ///
						total_time_night)
			}


			* Hypoglycemic excursions (user-specified length)

				
			if "`hypo'" == "" & "`unit'" == "" local hypo 70 54
			if "`hypo'" == "" & "`unit'" != "" local hypo 3.9 3.0
				
			foreach num of numlist `hypo' {

				sort `id' `time'
					
				local num_hypo_rnd = subinstr("`num'", ".", "_", .)
				
				by `id': gen flag_under_`num_hypo_rnd' = 1 ///
					if `glucose' < `num' ///
						& (`glucose'[_n+1] < `num' | `glucose'[_n-1] < `num')

				by `id': gen exc_under_`num_hypo_rnd' ///
							= flag_under_`num_hypo_rnd' == 1 ///
								& flag_under_`num_hypo_rnd'[_n-1] == .
				
				by `id': gen n_under_`num_hypo_rnd' = sum(exc_under_`num_hypo_rnd')
				replace n_under_`num_hypo_rnd' = . if flag_under_`num_hypo_rnd' == .
				
				sort `id' n_under_`num_hypo_rnd' `time'
				by `id' n_under_`num_hypo_rnd': gen hypo_lngth_`num_hypo_rnd' ///
						= ((`time'[_N]-`time'[1])) / 60000 ///
						if !missing(n_under_`num_hypo_rnd')
				replace hypo_lngth_`num_hypo_rnd' ///
						= hypo_lngth_`num_hypo_rnd' + `freq' ///
						if !missing(hypo_lngth_`num_hypo_rnd')
				
				replace exc_under_`num_hypo_rnd' = 0 ///
						if exc_under_`num_hypo_rnd' == 1 ///
						& hypo_lngth_`num_hypo_rnd' < `hypo_exc_lngth'
				replace hypo_lngth_`num_hypo_rnd' = .  ///
						if exc_under_`num_hypo_rnd' != 1	
				
				drop flag_under_`num_hypo_rnd'
				drop n_under_`num_hypo_rnd'
			}
					
			sort `id' `time'
					
			*min_spent_under_X
					
			foreach num of numlist `hypo' {

				local num_hypo_rnd = subinstr("`num'", ".", "_", .)
					
				by `id': gen time_spent_under_`num_hypo_rnd' ///
							 = `freq' * (`glucose' < `num')
				by `id': egen min_spent_under_`num_hypo_rnd' ///
							= sum(time_spent_under_`num_hypo_rnd')
			}
	 
			foreach num of numlist `hypo' {

				local num_hypo_rnd = subinstr("`num'", ".", "_", .)
					
				by `id': gen time_spent_under_`num_hypo_rnd'_night ///
							= `freq' * ///
							(`glucose' < `num' ///
							& (`time' >= datetime_end | `time' <= datetime_start))
				by `id': egen min_spent_under_`num_hypo_rnd'_night ///
							= sum(time_spent_under_`num_hypo_rnd'_night)
			}
					
			foreach num of numlist `hypo' {

				local num_hypo_rnd = subinstr("`num'", ".", "_", .)
			
				by `id': gen time_spent_under_`num_hypo_rnd'_day = `freq' * ///
					(`glucose' < `num' & (`time' < datetime_end & `time' > ///
					datetime_start))
				by `id': egen min_spent_under_`num_hypo_rnd'_day = ///
					sum(time_spent_under_`num_hypo_rnd'_day)
			}
			
			*percent_time_under_X
			
			foreach num of numlist `hypo' {
				local num_hypo_rnd = subinstr("`num'", ".", "_", .)
			
				gen percent_time_under_`num_hypo_rnd' = 100 * ///
					(min_spent_under_`num_hypo_rnd'/total_time)
			}

					
			foreach num of numlist `hypo' {
				local num_hypo_rnd = subinstr("`num'", ".", "_", .)
				
				gen percent_time_under_`num_hypo_rnd'_day = 100 * ///
					(min_spent_under_`num_hypo_rnd'_day/total_time_day)
				gen percent_time_under_`num_hypo_rnd'_night = 100 * ///
					(min_spent_under_`num_hypo_rnd'_night/total_time_night)
			}
			
			*Time-in-range (user-specified)

			foreach num_low of numlist `hypo' { 
		
				foreach num_high of numlist `hyper' { 

					local num_low_rnd = subinstr("`num_low'", ".", "_", .)
					local num_high_rnd = subinstr("`num_high'", ".", "_", .)
					
					by `id': gen time_spent_`num_low_rnd'_`num_high_rnd' ///
								 = `freq' * ///
								(`glucose' >= `num_low' & `glucose' <= `num_high')
					by `id': egen min_spent_`num_low_rnd'_`num_high_rnd' ///
								= sum(time_spent_`num_low_rnd'_`num_high_rnd')
					gen percent_time_`num_low_rnd'_`num_high_rnd' ///
							= 100 * (min_spent_`num_low_rnd'_`num_high_rnd'/ ///
							total_time)
					
					by `id': gen time_spent_`num_low_rnd'_`num_high_rnd'_day ///
							= `freq' * ///
							(`glucose' >= `num_low' & `glucose' <= `num_high' ///
							& (`time' < datetime_end & `time' > datetime_start))

					by `id': egen min_spent_`num_low_rnd'_`num_high_rnd'_day ///
							= sum(time_spent_`num_low_rnd'_`num_high_rnd'_day)

					gen percent_time_`num_low_rnd'_`num_high_rnd'_day = 100 * ///
						(min_spent_`num_low_rnd'_`num_high_rnd'_day/total_time_day)
					
					by `id': gen time_spent_`num_low_rnd'_`num_high_rnd'_night ///
						 = `freq' * ///
						(`glucose' >= `num_low' & `glucose' <= `num_high' & ///
							(`time' >= datetime_end | `time' <= datetime_start))
					by `id': egen min_spent_`num_low_rnd'_`num_high_rnd'_night ///
						= sum(time_spent_`num_low_rnd'_`num_high_rnd'_night)
					gen percent_time_`num_low_rnd'_`num_high_rnd'_night ///
						= 100 * ///
					(min_spent_`num_low_rnd'_`num_high_rnd'_night/total_time_night)
				}
			}
		
			*AUC
			if "`auc'" == "auc" {
				foreach num_hyper of numlist `hyper' {
						
					local num_hyper_rnd = subinstr("`num'", ".", "_", .)
						
					gen glucose_over_`num_hyper_rnd' = `glucose' - `num_hyper' ///
						if `glucose' > `num_hyper' & !missing(`glucose')
					sort `id' `time'
					by `id': gen trapezoid_area_`num_hyper_rnd' ///
						= 0.5 * ///
						(glucose_over_`num_hyper_rnd'[_n] ///
							+ glucose_over_`num_hyper_rnd'[_n-1]) * ///
						 time_int if _n > 1
					by `id': egen auc_over_`num_hyper_rnd' ///
						= sum(trapezoid_area_`num_hyper_rnd')
				}
			}		
				
				
			 if "`auc'" == "auc" {

					collapse (min) mean_sensor* median_sensor* ///
						sd_sensor* q1_sensor* q3_sensor* cv_sensor* 
						min_sensor* max_sensor* percent_cgm_wear ///
						total_sensor_readings `time' ndayswear min_spent_* ///
						percent_time* auc_over_* (sum) exc_over_* exc_under_* ///
						(mean) hypo_lngth_* hyper_lngth_* if "`auc'" == "auc", ///
						by(`id') 
			 }
					

			if "`auc'" != "auc" {

				collapse (min) mean_sensor* median_sensor* sd_sensor* ///
					q1_sensor* q3_sensor* cv_sensor* min_sensor* max_sensor* ///
					percent_cgm_wear total_sensor_readings `time' ndayswear ///
					min_spent_* percent_time* (sum) exc_over_* exc_under_*  ///
					(mean) hypo_lngth_* hyper_lngth_*, by(`id') 
			}	
				
			rename hypo_lngth_* avg_hypo_lngth_*
			rename hyper_lngth_* avg_hyper_lngth_*
					
			foreach v of varlist mean_sensor* median_sensor*  ///
					sd_sensor* cv_sensor* q1_sensor* ///
					q3_sensor* min_sensor* ndayswear ///
					max_sensor* percent_* avg_* { 
			 
				format `v' %9.1f
			}
				
			capture format auc_over* %9.1f 
			
			rename exc_over_* episodes_over_*
			rename exc_under_* episodes_under_*

			rename `time' first_glucose_reading
		
			
			if "`unit'" == "" {
				label var mean_sensor "Mean sensor glucose (mg/dL)"
				label var mean_sensor_day "Day time mean sensor glucose (mg/dL)"
				label var mean_sensor_night "Night time mean sensor glucose (mg/dL)"
				label var median_sensor "Median sensor glucose (mg/dL)"
				label var median_sensor_day "Day time median sensor glucose (mg/dL)"
				label var median_sensor_night "Night time median sensor glucose (mg/dL)"
				label var sd_sensor "SD sensor glucose (mg/dL)"
				label var sd_sensor_day "Day time SD sensor glucose (mg/dL)"
				label var sd_sensor_night "Night time SD sensor glucose (mg/dL)"
				label var q1_sensor "First quartile sensor glucose value (mg/dL)"
				label var q1_sensor_day "Day time first quartile sensor glucose value (mg/dL)"
				label var q1_sensor_night "Night time first quartile sensor glucose value (mg/dL)"
				label var q3_sensor "Third quartile sensor glucose value (mg/dL)"
				label var q3_sensor_day "Day time third quartile sensor glucose value (mg/dL)"
				label var q3_sensor_night "Night time third quartile sensor glucose value (mg/dL)"
				label var min_sensor "Minimum of all sensor glucose values (mg/dL)"
				label var min_sensor_day "Day time minimum of all sensor glucose values (mg/dL)"
				label var min_sensor_night "Night time minimum of all sensor glucose values (mg/dL)"
				label var max_sensor "Maximum of all sensor glucose values (mg/dL)"	
				label var max_sensor_day "Day time maximum of all sensor glucose values (mg/dL)"	
				label var max_sensor_night "Night time maximum of all sensor glucose values (mg/dL)"	
			}

			else {
				label var mean_sensor "Mean sensor glucose (mmol/L)"
				label var mean_sensor_day "Day time mean sensor glucose (mmol/L)"
				label var mean_sensor_night "Night time mean sensor glucose (mmol/L)"
				label var median_sensor "Median sensor glucose (mmol/L)"
				label var median_sensor_day "Day time median sensor glucose (mmol/L)"
				label var median_sensor_night "Night time median sensor glucose (mmol/L)"
				label var sd_sensor "SD sensor glucose (mmol/L)"
				label var sd_sensor_day "Day time SD sensor glucose (mmol/L)"
				label var sd_sensor_night "Night time SD sensor glucose (mmol/L)"
				label var q1_sensor "First quartile sensor glucose value (mmol/L)"
				label var q1_sensor_day "Day time first quartile sensor glucose value (mmol/L)"
				label var q1_sensor_night "Night time first quartile sensor glucose value (mmol/L)"
				label var q3_sensor "Third quartile sensor glucose value (mmol/L)"
				label var q3_sensor_day "Day time third quartile sensor glucose value (mmol/L)"
				label var q3_sensor_night "Night time third quartile sensor glucose value (mmol/L)"
				label var min_sensor "Minimum of all sensor glucose values (mmol/L)"
				label var min_sensor_day "Day time minimum of all sensor glucose values (mmol/L)"
				label var min_sensor_night "Night time minimum of all sensor glucose values (mmol/L)"
				label var max_sensor "Maximum of all sensor glucose values (mmol/L)"	
				label var max_sensor_day "Day time maximum of all sensor glucose values (mmol/L)"	
				label var max_sensor_night "Night time maximum of all sensor glucose values (mmol/L)"		
			}

			label var cv_sensor "CV sensor glucose (%)"
			label var cv_sensor_day "Day time CV sensor glucose (%)"
			label var cv_sensor_night "Night time CV sensor glucose (%)"
			label var percent_cgm_wear "The # of sensor readings as a percentage of the # of potential readings given time worn"
			label var total_sensor_readings "The total # of sensor readings"
			label var ndayswear "# of days sensor was worn"
			
			foreach num_high of numlist `hyper' { 
			
				local num_high_rnd = subinstr("`num_high'", ".", "_", .)

				if "`unit'" == "" {
					label var min_spent_over_`num_high_rnd' "The total length of time that sensor glucose was at or above `num_high' mg/dL"
					label var min_spent_over_`num_high_rnd'_day "The total length of time that sensor glucose was at or above `num_high' mg/dL during the day" 
					label var min_spent_over_`num_high_rnd'_night "The total length of time that sensor glucose was at or above `num_high' mg/dL during the night" 
					label var percent_time_over_`num_high_rnd' "Minutes spent above `num_high' mg/dL, as a percentage of the total time CGM was worn"
					label var percent_time_over_`num_high_rnd'_day "Minutes spent above `num_high' mg/dL during the day, as a percentage of the total time CGM was worn during the day" 
					label var percent_time_over_`num_high_rnd'_night "Minutes spent above `num_high' mg/dL during the night, as a percentage of the total time CGM was worn during the night" 
					label var episodes_over_`num_high_rnd' "Count of glucose episodes (≥`hyper_exc_lngth' min) above `num_high' mg/dL" 
					label var avg_hyper_lngth_`num_high_rnd' "Mean length of hyperglycemic episodes above `num_high' mg/dL" 
					capture label var auc_over_`num_high_rnd' "AUC over `num_high' mg/dL" 
				}
				
				else {
					label var min_spent_over_`num_high_rnd' "The total length of time that sensor glucose was at or above `num_high' mmol/L"
					label var min_spent_over_`num_high_rnd'_day "The total length of time that sensor glucose was at or above `num_high' mmol/L during the day" 
					label var min_spent_over_`num_high_rnd'_night "The total length of time that sensor glucose was at or above `num_high' mmol/L during the night" 
					label var percent_time_over_`num_high_rnd' "Minutes spent above `num_high' mmol/L, as a percentage of the total time CGM was worn" 
					label var percent_time_over_`num_high_rnd'_day "Minutes spent above `num_high' mmol/L during the day, as a percentage of the total time CGM was worn during the day" 
					label var percent_time_over_`num_high_rnd'_night "Minutes spent above `num_high' mmol/L during the night, as a percentage of the total time CGM was worn during the night" 
					label var episodes_over_`num_high_rnd' "Count of glucose episodes (≥`hyper_exc_lngth' min) above `num_high' mmol/L" 
					label var avg_hyper_lngth_`num_high_rnd' "Mean length of hyperglycemic episodes above `num_high' mmol/L" 
					capture label var auc_over_`num_high_rnd' "AUC over `num_high' mmol/L" 
				}
			}
			
	 
			foreach num_low of numlist `hypo' { 
						
				local num_low_rnd = subinstr("`num_low'", ".", "_", .)
		
				if "`unit'" == "" {
					 label var min_spent_under_`num_low_rnd' "The total length of time that sensor glucose was at or below `num_low' mg/dL" 
					 label var min_spent_under_`num_low_rnd'_day "The total length of time that sensor glucose was at or below `num_low' mg/dL during the day"
					 label var min_spent_under_`num_low_rnd'_night "The total length of time that sensor glucose was at or below `num_low' mg/dL during the night" 
					 label var percent_time_under_`num_low_rnd' "Minutes spent below `num_low' mg/dL, as a percentage of the total time CGM was worn" 
					 label var percent_time_under_`num_low_rnd'_day "Minutes spent below `num_low' mg/dL during the day, as a percentage of the total time CGM was worn during the day" 
					 label var percent_time_under_`num_low_rnd'_night "Minutes spent below `num_low' mg/dL during the night, as a percentage of the total time CGM was worn during the night" 
					 label var episodes_under_`num_low_rnd' "Count of glucose episodes (≥`hypo_exc_lngth' min) lower than `num_low' mg/dL" 
					 label var avg_hypo_lngth_`num_low_rnd' "Mean length of hypoglycemic episodes below `num_low' mg/dL" 	
				}
				
				else {
					label var min_spent_under_`num_low_rnd' "The total length of time that sensor glucose was at or below `num_low' mmol/L" 
					label var min_spent_under_`num_low_rnd'_day "The total length of time that sensor glucose was at or below `num_low' mmol/L during the day" 
					label var min_spent_under_`num_low_rnd'_night "The total length of time that sensor glucose was at or below `num_low' mmol/L during the night" 
					label var percent_time_under_`num_low_rnd' "Minutes spent below `num_low' mmol/L, as a percentage of the total time CGM was worn" 
					label var percent_time_under_`num_low_rnd'_day "Minutes spent below `num_low' mmol/L during the day, as a percentage of the total time CGM was worn during the day" 
					label var percent_time_under_`num_low_rnd'_night "Minutes spent below `num_low' mmol/L during the night, as a percentage of the total time CGM was worn during the night" 
					label var episodes_under_`num_low_rnd' "Count of glucose episodes (≥`hypo_exc_lngth' min) lower than `num_low' mmol/L" 
					label var avg_hypo_lngth_`num_low_rnd' "Mean length of hypoglycemic episodes below `num_low' mmol/L" 
				}
		
			}

			foreach numl of numlist `hypo' { 
			
				foreach numh of numlist `hyper' { 		
				
					local num_low = subinstr("`numl'", ".", "_", .)
					local num_high = subinstr("`numh'", ".", "_", .)
				
					if "`unit'" == "" {
						label var min_spent_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive)" 
						label var min_spent_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the day" 
						label var min_spent_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the night" 
						label var percent_time_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive), as a percentage of the total time CGM was worn" 
						label var percent_time_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the day, as a percentage of the total time CGM was worn during the day" 
						label var percent_time_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the night, as a percentage of the total time CGM was worn during the night" 
					}
								
					else {
						label var min_spent_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive)" 
						label var min_spent_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the day" 
						label var min_spent_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the night"
						label var percent_time_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive), as a percentage of the total time CGM was worn" 
						label var percent_time_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the day, as a percentage of the total time CGM was worn during the day"
						label var percent_time_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the night, as a percentage of the total time CGM was worn during the night" 		
					}	
				}
			}

			label var `id' "ID"
			label var first_glucose_reading "`time' of first glucose reading"

			if "`auc'" != "" {
				order `id' first_glucose_reading ndayswear total_sensor_readings ///
					percent_cgm_wear mean_sensor* median_sensor* ///
					q1_sensor* q3_sensor* min_sensor* max_sensor*  ///
					sd_sensor* cv_sensor* min_spent* percent_time_* ///
					episodes_under* avg_hypo_lngth* min_spent_over* ///
					percent_time_over* episodes_over* avg_hyper_lngth* auc_over* 
			}

			if "`auc'" == "" {
				order `id' first_glucose_reading ndayswear total_sensor_readings ///
					percent_cgm_wear mean_sensor* median_sensor* q1_sensor* ///
					q3_sensor* min_sensor* max_sensor*  sd_sensor* cv_sensor* ///
					min_spent* percent_time_* episodes_under* avg_hypo_lngth* ///
					min_spent_over* percent_time_over* episodes_over* avg_hyper_lngth* 
			}
			
			compress
			if "`savesumdta'" != "" & "`savesumdir'" != "" save ///
				"`savesumdir'/`savesumdta'`g'", replace
			if "`savesumdta'" != "" & "`savesumdir'" == "" ///
				save "`savesumdta'`g'", replace
			
			if "`hist'" != "" & strpos("`hist'", "freq") > 0 {	
			
				gen hist_vars = substr("`hist'", 1, strpos("`hist'", ",") - 1) ///
					if strpos("`hist'", ",") > 0
				replace hist_vars = "`hist'" if strpos("`hist'", ",") == 0

				local hist_var = hist_vars
				
				foreach v in `hist_var' {
					
					local `v'_lbl: variable label `v'
					
					gen open_pos = strpos("`hist'", "(")    
					gen close_pos = strpos("`hist'", ")") 
					
					if open_pos > 0 & close_pos > 0 {
						
						local barwidth ///
							= substr("`hist'", open_pos + 1, close_pos - open_pos - 1) 

						histogram `v', freq xtitle("``v'_lbl'") barwidth(`barwidth') ///
							legend(off) ytitle("Frequency") name(`v', replace) 	
					
					}
					
					drop open_pos close_pos	
					
					else {
						histogram `v', freq xtitle("``v'_lbl'") legend(off) ///
							ytitle("Frequency") name(`v', replace) 
					}
						if "`saveplotdir'" != "" graph save ///
						"`saveplotdir'/`v'`g'", replace
				}				 
				
				noi summ `hist_var' 
			}
		
			if "`hist'" != "" & strpos("`hist'", "freq") == 0 {	
		
				gen hist_vars = substr("`hist'", 1, strpos("`hist'", ",") - 1) ///
					if strpos("`hist'", ",") > 0
				replace hist_vars = "`hist'" if strpos("`hist'", ",") == 0

				local hist_var = hist_vars
			
				foreach v in `hist_var' {
				
					local `v'_lbl: variable label `v'
					gen open_pos = strpos("`hist'", "(")    
					gen close_pos = strpos("`hist'", ")") 
					
					if open_pos > 0 & close_pos > 0 {
						local barwidth ///
							= substr("`hist'", open_pos + 1, close_pos - open_pos - 1) 
						twoway(histogram `v', barwidth(`barwidth'))(kdensity `v') ///
							,  xtitle("``v'_lbl'") legend(off) ytitle("Density") ///
							name(`v', replace) 
						
					}
					
					drop open_pos close_pos
					
					else {
						twoway(histogram `v')(kdensity `v') ///
							,  xtitle("``v'_lbl'") legend(off) ytitle("Density") ///
								name(`v', replace) 
					} 
					if "`saveplotdir'" != "" ///
						graph save "`saveplotdir'/`v'`g'", replace
				}
				noi summ `hist_var'
			}				 
			  
			restore  
			
		}
	}    


	**# If user indicates by ID and day

	if "`by'" == "day id"|"`by'" == "id day" {

			sort `id' unique_num_days
			*calculate difference between consecutive readings (in minutes)
			by `id' unique_num_days: gen difftime = ///
				clockdiff(`time', `time'[1], "minute")
			replace difftime = abs(difftime)

			by `id' unique_num_days: gen time_int = difftime - difftime[_n-1]

			*standard CGM summary statistics 
			bysort `id' unique_num_days: egen total_counts = count(`id')
			bysort `id' unique_num_days: egen mean_sensor = mean(`glucose')
			bysort `id' unique_num_days: egen median_sensor = median(`glucose')
			bysort `id' unique_num_days: egen sd_sensor = sd(`glucose')
			bysort `id' unique_num_days: egen q1_sensor = pctile(`glucose'), p(25)
			bysort `id' unique_num_days: egen q3_sensor = pctile(`glucose'), p(75)

			gen cv_sensor = 100 * (sd_sensor/mean_sensor)

			bysort `id' unique_num_days: egen min_sensor = min(`glucose')
			bysort `id' unique_num_days: egen max_sensor = max(`glucose')
				
			by `id' unique_num_days: gen sensorcount = !missing(`glucose')
			by `id' unique_num_days: egen total_sensor_readings = sum(sensorcount)

			by `id' unique_num_days: ///
				gen total_time ///
					= clockdiff(`time'[1],`time'[_N], "minute") + `freq'	
				
			gen ndayswear = round(total_time / 60 / 24, 0.1)
				
			gen total_wear = round((total_time/`freq'), 1)

			by `id': gen percent_cgm_wear ///
				= (round(100 * total_sensor_readings/total_wear, 0.1)) ///
				if unique_num_days == unique_num_days[1]| ///
				(unique_num_days == unique_num_days[_N])
				
			by `id': replace percent_cgm_wear ///
				= (round(100 * total_sensor_readings/(1440/`freq'), 0.1)) ///
				if unique_num_days != unique_num_days[1] & ///
				(unique_num_days != unique_num_days[_N])				

			gen month = month(NEWdate)
			gen day = day(NEWdate)
			gen year = year(NEWdate)
			  
			local hour_strt = hh(clock("`daystart'", "hm"))
			local min_strt = mm(clock("`daystart'", "hm"))

			local hour_end = hh(clock("`dayend'", "hm"))
			local min_end = mm(clock("`dayend'", "hm"))

			gen double datetime_start = ///
				mdyhms(month, day, year, `hour_strt',`min_strt',00) 
				//code to allow users to choose day start and end
			format datetime_start %tc

			gen double datetime_end = ///
				mdyhms(month, day, year, `hour_end',`min_end',00) 
				//code to allow users to choose day start and end
			format datetime_end %tc

			gen time_day = `freq' * (`time' < datetime_end & `time' > datetime_start)
			by `id' unique_num_days: egen total_time_day = sum(time_day)

			gen time_night = `freq' ///
							* (`time' >= datetime_end | `time' <= datetime_start)
			by `id' unique_num_days: egen total_time_night = sum(time_night)

			bysort `id' unique_num_days: egen sd_sensor_day = sd(`glucose') if ///
				(`time' < datetime_end & `time' > datetime_start)
			bysort `id' unique_num_days: egen mean_sensor_day = mean(`glucose') if ///
				(`time' < datetime_end & `time' > datetime_start)
			bysort `id' unique_num_days: egen median_sensor_day = median(`glucose') if ///
				(`time' < datetime_end & `time' > datetime_start)
			gen cv_sensor_day = 100 * (sd_sensor_day / mean_sensor_day)
			bysort `id' unique_num_days: egen q1_sensor_day = pctile(`glucose') if ///
				(`time' < datetime_end & `time' > datetime_start), p(25)
			bysort `id' unique_num_days: egen q3_sensor_day = pctile(`glucose') if ///
				(`time' < datetime_end & `time' > datetime_start), p(75)
			bysort `id' unique_num_days: egen min_sensor_day = min(`glucose') if ///
				(`time' < datetime_end & `time' > datetime_start)
			bysort `id' unique_num_days: egen max_sensor_day = max(`glucose') if ///
				(`time' < datetime_end & `time' > datetime_start)
					
			bysort `id' unique_num_days: egen sd_sensor_night = sd(`glucose') if ///
				(`time' >= datetime_end | `time' <= datetime_start)  
			bysort `id' unique_num_days: egen mean_sensor_night = mean(`glucose') if ///
				(`time' >= datetime_end | `time' <= datetime_start)
			gen cv_sensor_night = 100 * (sd_sensor_night/mean_sensor_night)
			bysort `id' unique_num_days: egen median_sensor_night = median(`glucose') if ///
				(`time' >= datetime_end | `time' <= datetime_start)
			bysort `id' unique_num_days: egen q1_sensor_night = pctile(`glucose') if ///
				(`time' >= datetime_end | `time' <= datetime_start), p(25)
			bysort `id' unique_num_days: egen q3_sensor_night = pctile(`glucose') if ///
				(`time' >= datetime_end | `time' <= datetime_start), p(75)
			bysort `id' unique_num_days: egen min_sensor_night = min(`glucose') if ///
				(`time' >= datetime_end | `time' <= datetime_start)
			bysort `id' unique_num_days: egen max_sensor_night = max(`glucose') if ///
				(`time' >= datetime_end | `time' <= datetime_start)
		
				
				*Hyperglycemic excursions (user-specified length)
					
			if "`hyper'" == "" & "`unit'" == "" local hyper 140 180 250 
			if "`hyper'" == "" & "`unit'" != "" local hyper 7.8 10 13.9 
				
			foreach num of numlist `hyper' {
						
				sort `id' unique_num_days `time'
						
				local num_hyper_rnd = subinstr("`num'", ".", "_", .)
						
				by `id' unique_num_days: gen flag_over_`num_hyper_rnd' = 1 ///
						if (`glucose' > `num' & !missing(`glucose')) ///
						& ((`glucose'[_n+1] > `num' ///
						& !missing(`glucose'[_n+1])) ///
						| ((`glucose'[_n-1] > `num') ///
						& !missing(`glucose'[_n-1])))
											
				by `id' unique_num_days: gen exc_over_`num_hyper_rnd' = ///
						flag_over_`num_hyper_rnd' == 1 ///
						& flag_over_`num_hyper_rnd'[_n-1] == .
						
				by `id' unique_num_days: gen n_over_`num_hyper_rnd' = ///
						sum(exc_over_`num_hyper_rnd')
				replace n_over_`num_hyper_rnd' = . if flag_over_`num_hyper_rnd' == .
						
				sort `id' unique_num_days n_over_`num_hyper_rnd' `time'
				by `id' unique_num_days n_over_`num_hyper_rnd': ///
					gen hyper_lngth_`num_hyper_rnd' =((`time'[_N]-`time'[1])) / 60000 ///
						if !missing(n_over_`num_hyper_rnd')
					replace hyper_lngth_`num_hyper_rnd' = hyper_lngth_`num_hyper_rnd' + ///
						`freq' if !missing(hyper_lngth_`num_hyper_rnd')
						
					replace exc_over_`num_hyper_rnd' = 0 ///
						if exc_over_`num_hyper_rnd' == 1 ///
						& hyper_lngth_`num_hyper_rnd' < `hyper_exc_lngth'
					replace hyper_lngth_`num_hyper_rnd' = . ///
						if exc_over_`num_hyper_rnd'!= 1
						
					drop flag_over_`num_hyper_rnd'
					drop n_over_`num_hyper_rnd'
						
			}
			
			sort `id' unique_num_days `time' 
				
			*min_spent_over_X
					
			foreach num_hyper of numlist `hyper' {
						
				local num_hyper_rnd = subinstr("`num_hyper'", ".", "_", .)
						
				by `id' unique_num_days: gen time_spent_over_`num_hyper_rnd' ///
					= `freq' * (`glucose' > `num_hyper' & !missing(`glucose'))
				by `id' unique_num_days: egen min_spent_over_`num_hyper_rnd' ///
					= sum(time_spent_over_`num_hyper_rnd')
			}
					
					
			foreach num_hyper of numlist `hyper' {
						
				local num_hyper_rnd = subinstr("`num_hyper'", ".", "_", .)
						
				by `id' unique_num_days: gen time_spent_over_`num_hyper_rnd'_night ///
					= `freq' * (`glucose' > `num_hyper' & !missing(`glucose') & ///
					(`time' >= datetime_end | `time' <= datetime_start))
				by `id' unique_num_days: egen min_spent_over_`num_hyper_rnd'_night ///
					= sum(time_spent_over_`num_hyper_rnd'_night)
			}
					
			foreach num_hyper of numlist `hyper' {
						
				local num_hyper_rnd = subinstr("`num_hyper'", ".", "_", .)
						
				by `id' unique_num_days: gen time_spent_over_`num_hyper_rnd'_day ///
						= `freq' * (`glucose' > `num_hyper' & !missing(`glucose') & /// 
						(`time' < datetime_end & `time' > datetime_start))
				by `id' unique_num_days: egen min_spent_over_`num_hyper_rnd'_day ///
						= sum(time_spent_over_`num_hyper_rnd'_day)
			}
					
					
			*percent_time_over_X
			foreach num of numlist `hyper' {
						
				local num_hyper_rnd = subinstr("`num'", ".", "_", .)
						
				gen percent_time_over_`num_hyper_rnd' = 100 * ///
					(min_spent_over_`num_hyper_rnd' / total_time)
				gen percent_time_over_`num_hyper_rnd'_day = 100 * ///
					(min_spent_over_`num_hyper_rnd'_day / total_time_day)
				gen percent_time_over_`num_hyper_rnd'_night = 100 * ///
					(min_spent_over_`num_hyper_rnd'_night / total_time_night)
			}
					
			*Hypoglycemic excursions (user-specified length)

				
			if "`hypo'" == "" & "`unit'" == "" local hypo 70 54
			if "`hypo'" == "" & "`unit'" != "" local hypo 3.9 3.0
				
			foreach num_hypo of numlist `hypo' {
				sort `id' unique_num_days `time'
						
				local num_hypo_rnd = subinstr("`num_hypo'", ".", "_", .)
						
				by `id' unique_num_days: gen flag_under_`num_hypo_rnd' = 1 if ///
					`glucose' < `num_hypo' & (`glucose'[_n+1] < `num_hypo' | ///
					`glucose'[_n-1] < `num_hypo')
				by `id' unique_num_days: gen exc_under_`num_hypo_rnd' = ///
					flag_under_`num_hypo_rnd' == 1 & flag_under_`num_hypo_rnd'[_n-1] == .
						
				by `id' unique_num_days: gen n_under_`num_hypo_rnd' = ///
					sum(exc_under_`num_hypo_rnd')
				replace n_under_`num_hypo_rnd' = . if flag_under_`num_hypo_rnd' == .
						
				sort `id' unique_num_days n_under_`num_hypo_rnd' `time'
				by `id' unique_num_days n_under_`num_hypo_rnd': ///
					gen hypo_lngth_`num_hypo_rnd' = ((`time'[_N]-`time'[1])) / 60000 ///
						if !missing(n_under_`num_hypo_rnd')
				replace hypo_lngth_`num_hypo_rnd' = hypo_lngth_`num_hypo_rnd' ///
					+`freq' if !missing(hypo_lngth_`num_hypo_rnd')
						
				replace exc_under_`num_hypo_rnd' = 0 ///
					if exc_under_`num_hypo_rnd' == 1 ///
					& hypo_lngth_`num_hypo_rnd' < `hypo_exc_lngth'
				replace hypo_lngth_`num_hypo_rnd' = . if exc_under_`num_hypo_rnd'!= 1
						
						
				drop flag_under_`num_hypo_rnd'
				drop n_under_`num_hypo_rnd'
					
			}
					
			sort `id' unique_num_days `time'
					
			*min_spent_under_X
					
			foreach num_hypo of numlist `hypo' {
						
				local num_hypo_rnd = subinstr("`num_hypo'", ".", "_", .)
						
				by `id' unique_num_days: ///
					gen time_spent_under_`num_hypo_rnd' ///
					= `freq' * (`glucose' < `num_hypo')
				by `id' unique_num_days: ///
					egen min_spent_under_`num_hypo_rnd' ///
					= sum(time_spent_under_`num_hypo_rnd')
			}
					 

			foreach num_hypo of numlist `hypo' {
						
				local num_hypo_rnd = subinstr("`num_hypo'", ".", "_", .)
						
				by `id' unique_num_days: ///
					gen time_spent_under_`num_hypo_rnd'_night ///
					 = `freq' * (`glucose' < `num_hypo' & (`time' >= datetime_end | ///
						`time' <= datetime_start))
				by `id' unique_num_days: egen min_spent_under_`num_hypo_rnd'_night ///
					= sum(time_spent_under_`num_hypo_rnd'_night)
			}
					
			foreach num_hypo of numlist `hypo' {
						
				local num_hypo_rnd = subinstr("`num_hypo'", ".", "_", .)
						
				by `id' unique_num_days: ///
					gen time_spent_under_`num_hypo_rnd'_day ///
						= `freq' * (`glucose' < `num_hypo' & ///
						(`time' < datetime_end & `time' > datetime_start))
				by `id' unique_num_days: ///
					egen min_spent_under_`num_hypo_rnd'_day ///
					= sum(time_spent_under_`num_hypo_rnd'_day)
			}
					
			*percent_time_under_X
					
			foreach num_hypo of numlist `hypo' {
						
				local num_hypo_rnd = subinstr("`num_hypo'", ".", "_", .)
						
				gen percent_time_under_`num_hypo_rnd' = 100 * ///
					(min_spent_under_`num_hypo_rnd' / total_time)
			}

					
			foreach num of numlist `hypo' {
					
				local num_hypo_rnd = subinstr("`num'", ".", "_", .)
						
				gen percent_time_under_`num_hypo_rnd'_day = 100 * ///
					(min_spent_under_`num_hypo_rnd'_day / total_time_day)
				gen percent_time_under_`num_hypo_rnd'_night = 100 * ///
					(min_spent_under_`num_hypo_rnd'_night / total_time_night)
			}
					
			*Time-in-range (user-specified)
			
			foreach num_low of numlist `hypo' { 
				foreach num_high of numlist `hyper' { 
						
				local num_low_rnd = subinstr("`num_low'", ".", "_", .)
				local num_high_rnd = subinstr("`num_high'", ".", "_", .)
						
				by `id' unique_num_days: ///
					gen time_spent_`num_low_rnd'_`num_high_rnd' ///
						= `freq' * (`glucose' >= `num_low' & `glucose' <= `num_high')
				by `id' unique_num_days: ///
					egen min_spent_`num_low_rnd'_`num_high_rnd' ///
					= sum(time_spent_`num_low_rnd'_`num_high_rnd')
				gen percent_time_`num_low_rnd'_`num_high_rnd' = 100 * ///
					(min_spent_`num_low_rnd'_`num_high_rnd' / total_time)
						
				by `id' unique_num_days: ///
						gen time_spent_`num_low_rnd'_`num_high_rnd'_day ///
							= `freq' * (`glucose' >= `num_low' & `glucose' <= `num_high' ///
							& (`time' < datetime_end & `time' > datetime_start))
				by `id' unique_num_days: ///
						egen min_spent_`num_low_rnd'_`num_high_rnd'_day ///
						= sum(time_spent_`num_low_rnd'_`num_high_rnd'_day)
				gen percent_time_`num_low_rnd'_`num_high_rnd'_day = 100 * ///
					(min_spent_`num_low_rnd'_`num_high_rnd'_day / total_time_day)
						
				by `id' unique_num_days: ///
					gen time_spent_`num_low_rnd'_`num_high_rnd'_night ///
						= `freq' *  (`glucose' >= `num_low' & `glucose' <= `num_high' ///
						& (`time' >= datetime_end | `time' <= datetime_start))
				by `id' unique_num_days: ///
					egen min_spent_`num_low_rnd'_`num_high_rnd'_night ///
					= sum(time_spent_`num_low_rnd'_`num_high_rnd'_night)
				gen percent_time_`num_low_rnd'_`num_high_rnd'_night = 100 * ///
					(min_spent_`num_low_rnd'_`num_high_rnd'_night / total_time_night)
				}
			}
			
			*AUC
			if "`auc'" == "auc" {
				foreach num_hyper of numlist `hyper' {
					
					local num_hyper_rnd = subinstr("`num_hyper'", ".", "_", .)
						
					gen glucose_over_`num_hyper_rnd' = `glucose' - `num_hyper' if ///
						`glucose' > `num_hyper' & !missing(`glucose')
					sort `id' unique_num_days `time'
					by `id' unique_num_days: gen trapezoid_area_`num_hyper_rnd' ///
						= 0.5 * (glucose_over_`num_hyper_rnd'[_n] + ///
						glucose_over_`num_hyper_rnd'[_n-1]) * time_int if _n > 1
						
					by `id' unique_num_days: egen auc_over_`num_hyper_rnd' ///
						= sum(trapezoid_area_`num_hyper_rnd')
				}
			}

			
			if "`unit'" == "" local unit_grph "mg/dL"
			if "`unit'" != "" local unit_grph "mmol/L"
			
			if "`plot'" != "" & "`unit'" == "" {
					
				sort `id' `time'
	 
				gen plot_nums = substr("`plot'", 1, strpos("`plot'", ",") - 1) ///
					if strpos("`plot'", ",") > 0
				replace plot_nums = "`plot'" if strpos("`plot'", ",") == 0

				local plot_num = plot_nums

					* some variables for the figure
					local mylist `plot_num'
					local mylist : subinstr local mylist " " ",", all 
					
						local low_rng = min(`mylist')
						if `low_rng' != floor(`low_rng') {
							local low_rng: di %4.1f `low_rng'
						}
						
						local high_rng = max(`mylist')
						if `high_rng' != floor(`high_rng') {
							local high_rng: di %4.1f `high_rng'
						}
					
					local low_rng_var = subinstr("`low_rng'", ".", "_", .)
					local high_rng_var = subinstr("`high_rng'", ".", "_", .)

						gen y`low_rng_var' = `low_rng'
						gen y`high_rng_var' = `high_rng'
						gen y0 = 0

				drop plot_nums

				levelsof `id', local(pt_id)

				foreach g in `pt_id' {
					
					preserve	

					ds `id', has(type string)
					if "`r(varlist)'" != "" {
						keep if `id' == "`g'" 
					} 
					else {
						keep if `id' == `g'
					}

					levelsof unique_num_days, local(day_wear)
					
					restore
				
					foreach h in `day_wear' {
						
						preserve	
						
						ds `id', has(type string)
						if "`r(varlist)'" != "" {
							keep if `id' == "`g'" & unique_num_days == `h' 
						} 
						else {
							keep if `id' == `g' & unique_num_days == `h'
						}

						qui summ `time', d
						
						local tmin = `r(min)'
						local temp_min = dofc(`tmin')
						local temp_min_fmt: di %tdDDmon `temp_min' 

						local tp25 = `r(p25)'
						local temp_p25 = dofc(`tp25')
						local temp_p25_fmt: di %tdDDmon `temp_p25' 

						local tmean = `r(mean)'
						local temp_mean = dofc(`tmean')
						local temp_mean_fmt: di %tdDDmon `temp_mean'

						local tp75 = `r(p75)'
						local temp_p75 = dofc(`tp75')
						local temp_p75_fmt: di %tdDDmon `temp_p75' 
						
						local tmax = `r(max)'
						local temp_max = dofc(`tmax')
						local temp_max_fmt: di %tdDDmon `temp_max'
						
						label var `time' "Date"	
						
						qui summ `glucose'
						
							local ymax = `r(max)'+ 300
							local y_p30 = `ymax'+ 30
							local y_30 = `ymax'- 30
							local y_60 = `ymax'- 60
							local y_90 = `ymax'- 90
							local y_120 = `ymax'- 120
							
						sort `id' `time'

								local mean = trim(string(mean_sensor), "%4.1f")
								local cv = trim(string(cv_sensor), "%4.1f")
								local pctwear = trim(string(percent_cgm_wear), ///
								"%4.1f")
								local pct`high_rng_var' = ///
									trim(string(percent_time_over_`high_rng_var'), ///
									"%4.1f")
								local pct`low_rng_var' = ///
									trim(string(percent_time_under_`low_rng_var'), ///
									"%4.1f")
								local pct`low_rng_var'`high_rng_var' = ///
									trim(string(percent_time_`low_rng_var'_`high_rng_var'), ///
									"%4.1f")					
								local low_rng_plus = `low_rng' + 5
								local high_rng_plus = `high_rng' + 5
							
						// Create a variable for the plot with gaps
						gen value_plot = `glucose'
						replace value_plot = . if (time_int > 2 * `freq') & ///
						!missing(time_int)

						gen double time_ts = 60000 * floor(`time' / 60000)
						format time_ts %tc

						gen time_diff = (time_ts[_n] - time_ts[_n-1]) / 60000

						qui summ time_diff
						qui tsset time_ts, clocktime delta(`r(min)' minutes) 

						local fill ""

						if strpos("`plot'", "fill") > 0 {
							tsfill, full
							local fill "fill"
						}

						if strpos("`plot'", "nostats") == 0 {
							tw ///
								(rarea y`low_rng_var' y`high_rng_var' `time', ///
								color(green%10)) (rarea y0 y`low_rng_var' `time', ///
								color(red%10)) ///
								(tsline value_plot if "`fill'" == "", lc(gs9) ///
									cmissing(no) tlabel(`tmin' `tp25' `tmean' ///
									`tp75' `tmax',format(%tcHH:MM))) ///
								(tsline value_plot if "`fill'" != "", lc(gs9) ///
									tlabel(`tmin' `tp25' `tmean' `tp75' `tmax', ///
									format(%tcHH:MM))) ///
								(line y`low_rng_var' `time', lcolor(green) ///
									lw(medium) lpattern(solid)) ///
								(line y`high_rng_var' `time', lcolor(green) ///
									lw(medium) lpattern(solid)) ///
								, /// 
								name("plot`g'",replace) graphregion(color(white) ///
									margin(large)) ///
								ytitle("CGM Glucose, `unit_grph'", size(medlarge)) ///
								xtitle("Hours : Minutes", size(medlarge)) ///
								ylabel(0(100)`ymax', ///
									nogrid nogextend tlwidth(medthick) ///
									labsize(medlarge)) yscale(lwidth(medthick)) ///
								text(`y_p30' `tmin' "ID: `g', Day `h'", ///
									size(medsmall) placement(east)) ///
								text(`ymax' `tmin' ///
									"Mean glucose: `mean' `unit_grph'; CV: `cv'%", ///
									size(medsmall) placement(east)) ///
								text(`y_30' `tmin' "% CGM wear: `pctwear'%", ///
									size(medsmall) placement(east)) ///
								text(`y_60' `tmin' ///
									"% time >`high_rng' `unit_grph': `pct`high_rng_var''%", ///
									size(medsmall) placement(east)) ///
								text(`y_90' `tmin' ///
									"% time `low_rng' - `high_rng' `unit_grph': `pct`low_rng_var'`high_rng_var''%", ///
									size(medsmall) placement(east)) ///
								text(`y_120' `tmin' ///
									"% time <`low_rng' `unit_grph': `pct`low_rng_var''%", ///
									size(medsmall) placement(east)) ///
								text(`high_rng_plus' `tmax' "`high_rng'", ///
									size(medlarge) placement(east)) ///
								text(`low_rng_plus' `tmax' "`low_rng'", ///
									size(medlarge) placement(east)) ///
								legend(off)
								
							restore
							
								if "`saveplotdir'" != "" graph save ///
								"`saveplotdir'/`g'day`h'_ts.gph", replace
								
							}
							
						if strpos("`plot'", "nostats") > 0 {
							tw ///
								(rarea y`low_rng_var' y`high_rng_var' `time', ///
									color(green%10)) ///
								(rarea y0 y`low_rng_var' `time', color(red%10)) ///
								(tsline value_plot if "`fill'" == "", lc(gs9) ///
									cmissing(no) tlabel(`tmin' `tp25' `tmean' ///
									`tp75' `tmax',format(%tcHH:MM))) ///
								(tsline value_plot if "`fill'" != "", lc(gs9) ///
									tlabel(`tmin' `tp25' `tmean' `tp75' `tmax', ///
									format(%tcHH:MM))) ///
								(line y`low_rng_var' `time', lcolor(green) ///
									lw(medium) lpattern(solid)) ///
								(line y`high_rng_var' `time', lcolor(green) ///
									lw(medium) lpattern(solid)) ///
								, /// 
								name("plot`g'",replace) ///
								graphregion(color(white) margin(large)) ///
								ytitle("CGM Glucose, `unit_grph'", size(medlarge)) ///
								xtitle("Hours : Minutes", size(medlarge)) ///
								ylabel(0(100)`ymax', ///
									nogrid nogextend tlwidth(medthick) ///
									labsize(medlarge)) ///
								yscale(lwidth(medthick)) ///
								text(`y_p30' `tmin' "ID: `g', Day `h'", ///
									size(medsmall) placement(east)) ///
								text(`high_rng_plus' `tmax' "`high_rng'", ///
									size(medlarge) placement(east)) ///
								text(`low_rng_plus' `tmax' "`low_rng'", ///
									size(medlarge) placement(east)) ///
								legend(off)
							restore
								if "`saveplotdir'" != "" graph save ///
								"`saveplotdir'/`g'day`h'_ts.gph", replace
						}	
					
					}
				}
			}


			if "`plot'" != "" & "`unit'" != "" {
					
				* generate a numiric time for figure
				sort `id' `time'
	 
				gen plot_nums = substr("`plot'", 1, strpos("`plot'", ",") - 1) ///
					if strpos("`plot'", ",") > 0
				replace plot_nums = "`plot'" if strpos("`plot'", ",") == 0

				local plot_num = plot_nums

				* some variables for the figure
				local mylist `plot_num'
				local mylist : subinstr local mylist " " ",", all 

				local low_rng = min(`mylist')
				if `low_rng' != floor(`low_rng') {
					local low_rng: di %4.1f `low_rng'
				}
						
				local high_rng = max(`mylist')
				if `high_rng' != floor(`high_rng') {
					local high_rng: di %4.1f `high_rng'
				}
					
				local low_rng_var = subinstr("`low_rng'", ".", "_", .)
				local high_rng_var = subinstr("`high_rng'", ".", "_", .)

				gen y`low_rng_var' = `low_rng'
				gen y`high_rng_var' = `high_rng'
				gen y0 = 0

				drop plot_nums 

				levelsof `id', local(pt_id)

				foreach g in `pt_id' {
					
					preserve	
					
					ds `id', has(type string)
					if "`r(varlist)'" != "" {
						keep if `id' == "`g'" 
					} 
					else {
						keep if `id' == `g'
					}

					levelsof unique_num_days, local(day_wear)
					
					restore
					
					foreach h in `day_wear' {
						
						preserve	
						
						ds `id', has(type string)
						if "`r(varlist)'" != "" {
							keep if `id' == "`g'" & unique_num_days == `h'

						} 
						
						else {
							keep if `id' == `g' & unique_num_days== `h'
						}

						qui summ `time',d
						local tmin = `r(min)'
						local temp_min = dofc(`tmin')
						local temp_min_fmt: di %tdDDmon `temp_min' 

						local tp25 = `r(p25)'
						local temp_p25 = dofc(`tp25')
						local temp_p25_fmt: di %tdDDmon `temp_p25' 
						
						local tmean = `r(mean)'
						local temp_mean = dofc(`tmean')
						local temp_mean_fmt: di %tdDDmon `temp_mean'

						local tp75 = `r(p75)'
						local temp_p75 = dofc(`tp75')
						local temp_p75_fmt: di %tdDDmon `temp_p75' 
						
						local tmax = `r(max)'
						local temp_max = dofc(`tmax')
						local temp_max_fmt: di %tdDDmon `temp_max'
						
						label var `time' "Date"	

						qui summ `glucose'
						
						local ymax=round(`r(max)' + 15,5)
						local y_2 = `ymax' - 2
						local y_4 = `ymax' - 4
						local y_6 = `ymax' - 6
						local y_8 = `ymax' - 8
						local y_10 = `ymax' - 10

						sort `id' `time'

						local mean = trim(string(mean_sensor), "%4.1f")
						local cv = trim(string(cv_sensor), "%4.1f")
						local pctwear = trim(string(percent_cgm_wear), "%4.1f")
						local pct`high_rng_var' = ///
							trim(string(percent_time_over_`high_rng_var'), ///
							"%4.1f")
						local pct`low_rng_var' = ///
							trim(string(percent_time_under_`low_rng_var'), ///
							"%4.1f")
						local pct`low_rng_var'`high_rng_var' = ///
							trim(string(percent_time_`low_rng_var'_`high_rng_var'), ///
							"%4.1f")
						local low_rng_plus = `low_rng' + .3
						local high_rng_plus = `high_rng' + .3
						
						// Create a variable for the plot with gaps
						gen value_plot = `glucose'
						replace value_plot = . if (time_int > 2 * `freq') & ///
							!missing(time_int)

						gen double time_ts = 60000 * floor(`time' / 60000)
						format time_ts %tc

						gen time_diff = (time_ts[_n] - time_ts[_n-1]) / 60000

						qui summ time_diff
						qui tsset time_ts, clocktime delta(`r(min)' minutes) 

						local fill ""
						if strpos("`plot'", "fill") > 0 {
							tsfill, full
							local fill "fill"
						}

						if strpos("`plot'", "nostats") == 0 {
							tw ///
							(rarea y`low_rng_var' y`high_rng_var' `time', ///
								color(green%10)) ///
							(rarea y0 y`low_rng_var' `time', color(red%10)) ///
							(tsline value_plot if "`fill'" == "", lc(gs9) ///
								cmissing(no) tlabel(`tmin' `tp25' `tmean' ///
								`tp75' `tmax', ///
								format(%tcHH:MM))) ///
							(tsline value_plot if "`fill'" != "", lc(gs9) ///
								tlabel(`tmin' `tp25' `tmean' `tp75' `tmax', ///
								format(%tcHH:MM))) ///
							(line y`low_rng_var' `time', lcolor(green) ///
								lw(medium) lpattern(solid)) ///
							(line y`high_rng_var' `time', lcolor(green) ///
								lw(medium) lpattern(solid)) ///
							, /// 
							name("plot`g'",replace) graphregion(color(white) ///
								margin(large)) ///
							ytitle("CGM Glucose, `unit_grph'", size(medlarge)) ///
								xtitle("Hour : Minutes", size(medlarge)) ///
							ylabel(0(5)`ymax',nogrid nogextend ///
								tlwidth(medthick) labsize(medlarge)) ///
								yscale(lwidth(medthick)) ///
							text(`ymax' `tmin' "ID: `g', Day `h'", ///
								size(medsmall) placement(east)) ///
							text(`y_2' `tmin' ///
								"Mean glucose: `mean' `unit_grph'; CV: `cv'%", ///
								size(medsmall) placement(east)) ///
							text(`y_4' `tmin' "% CGM wear: `pctwear'%", ///
								size(medsmall) placement(east)) ///
							text(`y_6' `tmin' ///
								"% time >`high_rng' `unit_grph': `pct`high_rng_var''%", ///
								size(medsmall) placement(east)) ///
							text(`y_8' `tmin' ///
								"% time `low_rng' - `high_rng' `unit_grph': `pct`low_rng_var'`high_rng_var''%", ///
								size(medsmall) placement(east)) ///
							text(`y_10' `tmin' ///
								"% time <`low_rng' `unit_grph': `pct`low_rng_var''%", ///
								size(medsmall) placement(east)) ///
							text(`high_rng_plus' `tmax' "`high_rng'", ///
								size(medlarge) placement(east)) ///
							text(`low_rng_plus' `tmax' "`low_rng'", ///
								size(medlarge) placement(east)) ///
							legend(off)
							
							restore
							
							if "`saveplotdir'" != "" graph save ///
								"`saveplotdir'/`g'day`h'_ts.gph", replace
						}
						
						if strpos("`plot'", "nostats") > 0 {
							tw ///
							(rarea y`low_rng_var' y`high_rng_var' `time', ///
								color(green%10)) ///
							(rarea y0 y`low_rng_var' `time', color(red%10)) ///
							(tsline value_plot if "`fill'" == "", lc(gs9) ///
								cmissing(no) tlabel(`tmin' `tp25' `tmean' ///
								`tp75' `tmax', ///
								format(%tcHH:MM))) ///
							(tsline value_plot if "`fill'" != "", lc(gs9) ///
								tlabel(`tmin' `tp25' `tmean' `tp75' `tmax', ///
								format(%tcHH:MM))) ///
							(line y`low_rng_var' `time', lcolor(green) ///
								lw(medium) lpattern(solid)) ///
							(line y`high_rng_var' `time', lcolor(green) ///
								lw(medium) lpattern(solid)) ///
							, /// 
							name("plot`g'",replace) graphregion(color(white) ///
								margin(large)) ///
							ytitle("CGM Glucose, `unit_grph'", size(medlarge)) ///
							xtitle("Hour : Minutes", size(medlarge)) ///
							ylabel(0(5)`ymax',nogrid nogextend ///
								tlwidth(medthick) labsize(medlarge)) ///
							yscale(lwidth(medthick)) ///
							text(`ymax' `tmin' "ID: `g', Day `h'", ///
								size(medsmall) placement(east)) ///
							text(`high_rng_plus' `tmax' "`high_rng'", ///
								size(medlarge) placement(east)) ///
							text(`low_rng_plus' `tmax' "`low_rng'", ///
								size(medlarge) placement(east)) ///
							legend(off)
							
							restore
							
							if "`saveplotdir'" != "" graph save ///
								"`saveplotdir'/`g'day`h'_ts.gph", replace
						}
					}
				}
			}

			if "`auc'" == "auc" {
					collapse (min) mean_sensor* median_sensor* sd_sensor* q1_sensor* ///
					q3_sensor* cv_sensor* min_sensor* max_sensor* percent_cgm_wear ///
					total_sensor_readings `time' ndayswear min_spent_* percent_time* ///
					auc_over* (sum) exc_over_* exc_under_* (mean)  hypo_lngth_* ///
					hyper_lngth_* , by(`id' unique_num_days) 
			 }	
				

			 if "`auc'" != "auc" {
					collapse (min) mean_sensor* median_sensor* sd_sensor* q1_sensor* ///
					q3_sensor* cv_sensor* min_sensor* max_sensor* percent_cgm_wear ///
					total_sensor_readings `time' ndayswear min_spent_* percent_time* ///
					(sum) exc_over_* exc_under_* (mean)  hypo_lngth_* hyper_lngth_* , ///
					by(`id' unique_num_days) 
			 }
			 
			rename hypo_lngth_* avg_hypo_lngth_*
			rename hyper_lngth_* avg_hyper_lngth_*
			
			foreach v of varlist mean_sensor* median_sensor* sd_sensor* cv_sensor* ///
			q1_sensor* q3_sensor* min_sensor* percent_* avg*  { // 
					format `v' %9.1f
				}
				
			capture format auc_over* %9.1f
			
			rename exc_over_* episodes_over_*
			rename exc_under_* episodes_under_*

			rename `time' first_glucose_reading
			
			rename unique_num_days day 
			label var day "Day of CGM wear"
			
			if "`unit'" == ""{
				label var mean_sensor "Mean sensor glucose (mg/dL)"
				label var mean_sensor_day "Day time mean sensor glucose (mg/dL)"
				label var mean_sensor_night "Night time mean sensor glucose (mg/dL)"
				label var median_sensor "Median sensor glucose (mg/dL)"
				label var median_sensor_day "Day time median sensor glucose (mg/dL)"
				label var median_sensor_night "Night time median sensor glucose (mg/dL)"
				label var sd_sensor "SD sensor glucose (mg/dL)"
				label var sd_sensor_day "Day time SD sensor glucose (mg/dL)"
				label var sd_sensor_night "Night time SD sensor glucose (mg/dL)"
				label var q1_sensor "First quartile sensor glucose value (mg/dL)"
				label var q1_sensor_day "Day time first quartile sensor glucose value (mg/dL)"
				label var q1_sensor_night "Night time first quartile sensor glucose value (mg/dL)"
				label var q3_sensor "Third quartile sensor glucose value (mg/dL)"
				label var q3_sensor_day "Day time third quartile sensor glucose value (mg/dL)"
				label var q3_sensor_night "Night time third quartile sensor glucose value (mg/dL)"
				label var min_sensor "Minimum of all sensor glucose values (mg/dL)"
				label var min_sensor_day "Day time minimum of all sensor glucose values (mg/dL)"
				label var min_sensor_night "Night time minimum of all sensor glucose values (mg/dL)"
				label var max_sensor "Maximum of all sensor glucose values (mg/dL)"	
				label var max_sensor_day "Day time maximum of all sensor glucose values (mg/dL)"	
				label var max_sensor_night "Night time maximum of all sensor glucose values (mg/dL)"	
			}
			else {
				label var mean_sensor "Mean sensor glucose (mmol/L)"
				label var mean_sensor_day "Day time mean sensor glucose (mmol/L)"
				label var mean_sensor_night "Night time mean sensor glucose (mmol/L)"
				label var median_sensor "Median sensor glucose (mmol/L)"
				label var median_sensor_day "Day time median sensor glucose (mmol/L)"
				label var median_sensor_night "Night time median sensor glucose (mmol/L)"
				label var sd_sensor "SD sensor glucose (mmol/L)"
				label var sd_sensor_day "Day time SD sensor glucose (mmol/L)"
				label var sd_sensor_night "Night time SD sensor glucose (mmol/L)"
				label var q1_sensor "First quartile sensor glucose value (mmol/L)"
				label var q1_sensor_day "Day time first quartile sensor glucose value (mmol/L)"
				label var q1_sensor_night "Night time first quartile sensor glucose value (mmol/L)"
				label var q3_sensor "Third quartile sensor glucose value (mmol/L)"
				label var q3_sensor_day "Day time third quartile sensor glucose value (mmol/L)"
				label var q3_sensor_night "Night time third quartile sensor glucose value (mmol/L)"
				label var min_sensor "Minimum of all sensor glucose values (mmol/L)"
				label var min_sensor_day "Day time minimum of all sensor glucose values (mmol/L)"
				label var min_sensor_night "Night time minimum of all sensor glucose values (mmol/L)"
				label var max_sensor "Maximum of all sensor glucose values (mmol/L)"	
				label var max_sensor_day "Day time maximum of all sensor glucose values (mmol/L)"	
				label var max_sensor_night "Night time maximum of all sensor glucose values (mmol/L)"			
			}
		
			label var cv_sensor "CV sensor glucose (%)"
			label var cv_sensor_day "Day time CV sensor glucose (%)"
			label var cv_sensor_night "Night time CV sensor glucose (%)"
			label var percent_cgm_wear "The # of sensor readings as a percentage of the # of potential readings given time worn"
			label var total_sensor_readings "The total # of sensor readings"
			label var ndayswear "# of days sensor was worn"

			foreach num_high of numlist `hyper' { 
			
				local num_high_rnd = subinstr("`num_high'", ".", "_", .)
						
						
				if "`unit'" == ""{
					label var min_spent_over_`num_high_rnd' "The total length of time that sensor glucose was at or above `num_high' mg/dL"
					label var min_spent_over_`num_high_rnd'_day "The total length of time that sensor glucose was at or above `num_high' mg/dL during the day" 
					label var min_spent_over_`num_high_rnd'_night "The total length of time that sensor glucose was at or above `num_high' mg/dL during the night" 
					label var percent_time_over_`num_high_rnd' "Minutes spent above `num_high' mg/dL, as a percentage of the total time CGM was worn"
					label var percent_time_over_`num_high_rnd'_day "Minutes spent above `num_high' mg/dL during the day, as a percentage of the total time CGM was worn during the day" 
					label var percent_time_over_`num_high_rnd'_night "Minutes spent above `num_high' mg/dL during the night, as a percentage of the total time CGM was worn during the night" 
					label var episodes_over_`num_high_rnd' "Count of glucose episodes (≥`hyper_exc_lngth' min) above `num_high' mg/dL" 
					label var avg_hyper_lngth_`num_high_rnd' "Mean length of hyperglycemic episodes above `num_high' mmol/L" 
					capture label var auc_over_`num_high_rnd' "AUC over `num_high' mg/dL"
				}
				
				else {
					label var min_spent_over_`num_high_rnd' "The total length of time that sensor glucose was at or above `num_high' mmol/L"
					label var min_spent_over_`num_high_rnd'_day "The total length of time that sensor glucose was at or above `num_high' mmol/L during the day" 
					label var min_spent_over_`num_high_rnd'_night "The total length of time that sensor glucose was at or above `num_high' mmol/L during the night" 
					label var percent_time_over_`num_high_rnd' "Minutes spent above `num_high' mmol/L, as a percentage of the total time CGM was worn" 
					label var percent_time_over_`num_high_rnd'_day "Minutes spent above `num_high' mmol/L during the day, as a percentage of the total time CGM was worn during the day" 
					label var percent_time_over_`num_high_rnd'_night "Minutes spent above `num_high' mmol/L during the night, as a percentage of the total time CGM was worn during the night" 
					label var episodes_over_`num_high_rnd' "Count of glucose episodes (≥`hyper_exc_lngth' min) above `num_high' mmol/L" 
					label var avg_hyper_lngth_`num_high_rnd' "Mean length of hyperglycemic episodes above `num_high' mmol/L" 
					capture label var auc_over_`num_high_rnd' "AUC over `num_high' mmol/L"
				}
		}
		
	 
		foreach num_low of numlist `hypo' { 
						
			local num_low_rnd = subinstr("`num_low'", ".", "_", .)
			
			
			if "`unit'" == "" {
				 label var min_spent_under_`num_low_rnd' "The total length of time that sensor glucose was at or below `num_low' mg/dL" 
				 label var min_spent_under_`num_low_rnd'_day "The total length of time that sensor glucose was at or below `num_low' mg/dL during the day"
				 label var min_spent_under_`num_low_rnd'_night "The total length of time that sensor glucose was at or below `num_low' mg/dL during the night" 
				 label var percent_time_under_`num_low_rnd' "Minutes spent below `num_low' mg/dL, as a percentage of the total time CGM was worn" 
				 label var percent_time_under_`num_low_rnd'_day "Minutes spent below `num_low' mg/dL during the day, as a percentage of the total time CGM was worn during the day" 
				 label var percent_time_under_`num_low_rnd'_night "Minutes spent below `num_low' mg/dL during the night, as a percentage of the total time CGM was worn during the night" 
				 label var episodes_under_`num_low_rnd' "Count of glucose episodes (≥`hypo_exc_lngth' min) lower than `num_low' mg/dL" 
				 label var avg_hypo_lngth_`num_low_rnd' "Mean length of hypoglycemic episodes below `num_low' mg/dL" 	
			}
			
			else {
				label var min_spent_under_`num_low_rnd' "The total length of time that sensor glucose was at or below `num_low' mmol/L" 
				label var min_spent_under_`num_low_rnd'_day "The total length of time that sensor glucose was at or below `num_low' mmol/L during the day" 
				label var min_spent_under_`num_low_rnd'_night "The total length of time that sensor glucose was at or below `num_low' mmol/L during the night" 
				label var percent_time_under_`num_low_rnd' "Minutes spent below `num_low' mmol/L, as a percentage of the total time CGM was worn" 
				label var percent_time_under_`num_low_rnd'_day "Minutes spent below `num_low' mmol/L during the day, as a percentage of the total time CGM was worn during the day" 
				label var percent_time_under_`num_low_rnd'_night "Minutes spent below `num_low' mmol/L during the night, as a percentage of the total time CGM was worn during the night" 
				label var episodes_under_`num_low_rnd' "Count of glucose episodes (≥`hypo_exc_lngth' min) lower than `num_low' mmol/L" 
				label var avg_hypo_lngth_`num_low_rnd' "Mean length of hypoglycemic episodes below `num_low' mmol/L" 
			}
		
		}

		foreach numl of numlist `hypo' { 
			foreach numh of numlist `hyper' { 		
				
				local num_low = subinstr("`numl'", ".", "_", .)
				local num_high = subinstr("`numh'", ".", "_", .)
			
			
					if "`unit'" == ""{
						 label var min_spent_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive)" 
						 label var min_spent_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the day" 
						 label var min_spent_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the night" 
						 label var percent_time_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive), as a percentage of the total time CGM was worn" 
						 label var percent_time_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the day, as a percentage of the total time CGM was worn during the day" 
						 label var percent_time_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the night, as a percentage of the total time CGM was worn during the night" 
					}
					
					else {
						label var min_spent_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive)" 
						label var min_spent_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the day" 
						label var min_spent_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the night"
						label var percent_time_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive), as a percentage of the total time CGM was worn" 
						label var percent_time_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the day, as a percentage of the total time CGM was worn during the day"
						label var percent_time_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the night, as a percentage of the total time CGM was worn during the night" 		
					}	
			}
		}

		label var `id' "ID"
		label var first_glucose_reading "`time' of first glucose reading"

		if "`auc'" != "" {
			order `id' day first_glucose_reading ndayswear total_sensor_readings ///
			percent_cgm_wear mean_sensor* median_sensor* q1_sensor* q3_sensor* ///
			min_sensor* max_sensor* sd_sensor* cv_sensor* min_spent* percent_time_* ///
			episodes_under* avg_hypo_lngth* min_spent_over* percent_time_over* ///
			episodes_over* avg_hyper_lngth* auc_over* 
		}
			
		if "`auc'" == ""	{
			order `id' day first_glucose_reading ndayswear total_sensor_readings ///
			percent_cgm_wear mean_sensor* median_sensor* q1_sensor* q3_sensor* ///
			min_sensor* max_sensor* sd_sensor* cv_sensor* min_spent* percent_time_* ///
			episodes_under* avg_hypo_lngth* min_spent_over* percent_time_over* ///
			episodes_over* avg_hyper_lngth*
		}
		 
		compress
		if "`savesumdta'" != "" & "`savesumdir'" != "" save ///
			"`savesumdir'/`savesumdta'_id_day", replace
		if "`savesumdta'" != "" & "`savesumdir'" == "" save ///
			"`savesumdta'_id_day", replace
		
	}

	**# If a user does not indicate a by option

	if "`by'" == "" {

				sort `id' `time'
				*calculate difference between consecutive readings (in minutes)
					by `id': gen difftime = clockdiff(`time', `time'[1], "minute")
						replace difftime = abs(difftime)

					by `id': gen time_int = difftime-difftime[_n-1]

				sort `id' `time'
				*standard CGM summary statistics 
					bysort `id': egen total_counts = count(`id')
					bysort `id': egen mean_sensor = mean(`glucose')
					bysort `id': egen median_sensor = median(`glucose')
					bysort `id': egen sd_sensor = sd(`glucose')
					bysort `id': egen q1_sensor = pctile(`glucose'), p(25)
					bysort `id': egen q3_sensor = pctile(`glucose'), p(75)

					gen cv_sensor = 100 * (sd_sensor/mean_sensor)

					bysort `id': egen min_sensor = min(`glucose')
					bysort `id': egen max_sensor = max(`glucose')
					
					bysort `id' unique_num_days: egen avg_max_sensor = max(`glucose') 
						by `id' unique_num_days: gen dup = cond(_N== 1,0,_n)
						replace avg_max_sensor = . if dup > 1
						drop dup

					by `id': gen sensorcount = !missing(`glucose')
					by `id': egen total_sensor_readings=sum(sensorcount)

				
					by `id': gen total_time = clockdiff(`time'[1],`time'[_N], ///
						"minute") + `freq'

					gen total_wear = (total_time / `freq')
					
					gen ndayswear = round(total_time / 60 / 24, 0.1)
					
					gen percent_cgm_wear = (round(100 * total_sensor_readings ///
						/ total_wear,0.1))
				
					gen month = month(NEWdate)
					gen day = day(NEWdate)
					gen year = year(NEWdate)
					  
					local hour_strt = hh(clock("`daystart'", "hm"))
					local min_strt = mm(clock("`daystart'", "hm"))

					local hour_end = hh(clock("`dayend'", "hm"))
					local min_end = mm(clock("`dayend'", "hm"))

					gen double datetime_start = mdyhms(month, day, year, ///
						`hour_strt',`min_strt',00) 
						//code to allow users to choose day start and end
					format datetime_start %tc

					gen double datetime_end = mdyhms(month, day, year, ///
						`hour_end',`min_end',00) 
						//code to allow users to choose day start and end
					format datetime_end %tc

					gen time_day = `freq' * (`time' < datetime_end & `time' ///
						> datetime_start)
					by `id': egen total_time_day =sum(time_day)

					gen time_night = `freq' * (`time' >= datetime_end | ///
						`time' <= datetime_start)
					by `id': egen total_time_night =sum(time_night)

					bysort `id' : ///
						egen sd_sensor_day = sd(`glucose') ///
						if (`time' < datetime_end & `time' > datetime_start)
					bysort `id' : ///
						egen mean_sensor_day = mean(`glucose') ///
						if (`time' < datetime_end & `time' > datetime_start)
					bysort `id' : ///
						egen median_sensor_day = median(`glucose') ///
						if (`time' < datetime_end & `time' > datetime_start)
					gen cv_sensor_day = 100 * (sd_sensor_day/mean_sensor_day)
					bysort `id' : ///
						egen q1_sensor_day = pctile(`glucose') ///
						if (`time' < datetime_end & `time' > datetime_start), p(25)
					bysort `id' : ///
						egen q3_sensor_day = pctile(`glucose') ///
						if (`time' < datetime_end & `time' > datetime_start), p(75)
					bysort `id' : ///
						egen min_sensor_day = min(`glucose') ///
						if (`time' < datetime_end & `time' > datetime_start)
					bysort `id' : ///
						egen max_sensor_day = max(`glucose') ///
						if (`time' < datetime_end & `time' > datetime_start)
							
					bysort `id' : ///
						egen sd_sensor_night = sd(`glucose') ///
						if (`time' >= datetime_end | `time' <= datetime_start)    
					bysort `id' : ///
						egen mean_sensor_night = mean(`glucose') ///
						if (`time' >= datetime_end | `time' <= datetime_start)
					gen cv_sensor_night = 100 * (sd_sensor_night/mean_sensor_night)
					bysort `id' : ///
						egen median_sensor_night = median(`glucose') ///
						if (`time' >= datetime_end | `time' <= datetime_start)
					bysort `id' : ///
						egen q1_sensor_night = pctile(`glucose') ///
						if (`time' >= datetime_end | `time' <= datetime_start), p(25)
					bysort `id' : ///
						egen q3_sensor_night = pctile(`glucose') ///
						if (`time' >= datetime_end | `time' <= datetime_start), p(75)
					bysort `id' : ///
						egen min_sensor_night = min(`glucose') ///
						if (`time' >= datetime_end | `time' <= datetime_start)
					bysort `id' : ///
						egen max_sensor_night = max(`glucose') ///
						if (`time' >= datetime_end | `time' <= datetime_start)
			
					*Hyperglycemic excursions (user-specified length)
							
					if "`hyper'" == "" & "`unit'" == "" local hyper 140 180 250 
					if "`hyper'" == "" & "`unit'" != "" local hyper 7.8 10 13.9 
					
						foreach num of numlist `hyper' {
							sort `id' `time'
							
							local num_hyper_rnd = subinstr("`num'", ".", "_", .)
							
							by `id': gen flag_over_`num_hyper_rnd' = 1 ///
								if (`glucose' > `num' & ///
								!missing(`glucose')) & ///
								((`glucose'[_n+1] >`num' & ///
								!missing(`glucose'[_n+1]))| ///
								((`glucose'[_n-1] >`num') & ///
								!missing(`glucose'[_n-1])))
							
							by `id': gen exc_over_`num_hyper_rnd' = ///
								flag_over_`num_hyper_rnd' == 1 ///
								& flag_over_`num_hyper_rnd'[_n-1]== .
							
							by `id': gen n_over_`num_hyper_rnd' = ///
							sum(exc_over_`num_hyper_rnd')
								replace n_over_`num_hyper_rnd' = . if ///
								flag_over_`num_hyper_rnd' == .
							
							sort `id' n_over_`num_hyper_rnd' `time'
							by `id' n_over_`num_hyper_rnd': ///
								gen hyper_lngth_`num_hyper_rnd' = ///
									((`time'[_N]-`time'[1])) / 60000 if ///
									!missing(n_over_`num_hyper_rnd')
								replace hyper_lngth_`num_hyper_rnd' = ///
									hyper_lngth_`num_hyper_rnd'+`freq' if ///
									!missing(hyper_lngth_`num_hyper_rnd')
							
							replace exc_over_`num_hyper_rnd' = 0 ///
								if exc_over_`num_hyper_rnd' == 1 & ///
								hyper_lngth_`num_hyper_rnd' < `hyper_exc_lngth'
							replace hyper_lngth_`num_hyper_rnd' = . if ///
								exc_over_`num_hyper_rnd'!= 1
							
							drop flag_over_`num_hyper_rnd'
							drop n_over_`num_hyper_rnd'
							
						}			
				
						sort `id' `time' 
						
						*min_spent_over_X
						
						foreach num_hyper of numlist `hyper' {
							
							local num_hyper_rnd = subinstr("`num_hyper'", ".", "_", .)
							
							by `id': gen time_spent_over_`num_hyper_rnd' = `freq' * ///
								(`glucose' > `num_hyper' & !missing(`glucose'))
							by `id': egen min_spent_over_`num_hyper_rnd' = ///
								sum(time_spent_over_`num_hyper_rnd')
						}
						
						
						foreach num_hyper of numlist `hyper' {
							
							local num_hyper_rnd = subinstr("`num_hyper'", ".", "_", .)
							
							by `id': gen time_spent_over_`num_hyper_rnd'_night = `freq' * ///
								(`glucose' > `num_hyper' & !missing(`glucose') & ///
								(`time' >= datetime_end | `time' <= datetime_start))
							by `id': egen min_spent_over_`num_hyper_rnd'_night = ///
								sum(time_spent_over_`num_hyper_rnd'_night)
						}
						
						foreach num_hyper of numlist `hyper' {
							
							local num_hyper_rnd = subinstr("`num_hyper'", ".", "_", .)
							
							by `id': gen time_spent_over_`num_hyper_rnd'_day = `freq' * ///
								(`glucose' > `num_hyper' & !missing(`glucose') & ///
								(`time' < datetime_end & `time' > datetime_start))
							by `id': egen min_spent_over_`num_hyper_rnd'_day = ///
								sum(time_spent_over_`num_hyper_rnd'_day)
						}
						
						
						*percent_time_over_X
						foreach num of numlist `hyper' {
							
							local num_hyper_rnd = subinstr("`num'", ".", "_", .)
							
							gen percent_time_over_`num_hyper_rnd' = 100 * ///
								(min_spent_over_`num_hyper_rnd'/total_time)
							gen percent_time_over_`num_hyper_rnd'_day = 100 * ///
								(min_spent_over_`num_hyper_rnd'_day/total_time_day)
							gen percent_time_over_`num_hyper_rnd'_night = 100 * ///
								(min_spent_over_`num_hyper_rnd'_night/ ///
								total_time_night)
						}
						
					*Hypoglycemic excursions (user-specified length)

					
					if "`hypo'" == "" & "`unit'" == "" local hypo 70 54
					if "`hypo'" == "" & "`unit'" != "" local hypo 3.9 3.0
					
						foreach num_hypo of numlist `hypo' {
							sort `id' `time'
							
							local num_hypo_rnd = subinstr("`num_hypo'", ".", ///
								"_", .)
							
							by `id': gen flag_under_`num_hypo_rnd' = 1 ///
								if `glucose' < `num_hypo' & (`glucose'[_n+1] ///
								< `num_hypo'| `glucose'[_n-1] < `num_hypo')
							by `id': gen exc_under_`num_hypo_rnd' = ///
								flag_under_`num_hypo_rnd' == 1 ///
								& flag_under_`num_hypo_rnd'[_n-1]== .
							
							by `id': gen n_under_`num_hypo_rnd' = ///
								sum(exc_under_`num_hypo_rnd')
							replace n_under_`num_hypo_rnd' = . if ///
								flag_under_`num_hypo_rnd' == .
							
							sort `id' n_under_`num_hypo_rnd' `time'
							by `id' n_under_`num_hypo_rnd': ///
							gen hypo_lngth_`num_hypo_rnd' = ///
								((`time'[_N] - `time'[1])) / 60000 if ///
								!missing(n_under_`num_hypo_rnd')
								replace hypo_lngth_`num_hypo_rnd' = ///
								hypo_lngth_`num_hypo_rnd' + ///
								`freq' if !missing(hypo_lngth_`num_hypo_rnd')
							
							replace exc_under_`num_hypo_rnd' = 0 if ///
								exc_under_`num_hypo_rnd' == 1 & ///
								hypo_lngth_`num_hypo_rnd' < `hypo_exc_lngth'
							replace hypo_lngth_`num_hypo_rnd' = . if ///
								exc_under_`num_hypo_rnd' != 1
							
							drop flag_under_`num_hypo_rnd'
							drop n_under_`num_hypo_rnd'
							
						}
						
						sort `id' `time'
						
						*min_spent_under_X
						
						foreach num_hypo of numlist `hypo' {
							
							local num_hypo_rnd = subinstr("`num_hypo'", ".", "_", .)
							
							by `id': gen time_spent_under_`num_hypo_rnd' = `freq' * ///
								(`glucose' < `num_hypo')
							by `id': egen min_spent_under_`num_hypo_rnd' = ///
								sum(time_spent_under_`num_hypo_rnd')
						}
						 

						foreach num_hypo of numlist `hypo' {
							
							local num_hypo_rnd = subinstr("`num_hypo'", ".", "_", .)
							
							by `id': gen time_spent_under_`num_hypo_rnd'_night ///
								= `freq' * ///
								(`glucose' < `num_hypo' & (`time' >= ///
								datetime_end | `time' <= datetime_start))
							by `id': egen min_spent_under_`num_hypo_rnd'_night = ///
								sum(time_spent_under_`num_hypo_rnd'_night)
						}
						
						foreach num_hypo of numlist `hypo' {
							
							local num_hypo_rnd = subinstr("`num_hypo'", ".", "_", .)
							
							by `id': gen time_spent_under_`num_hypo_rnd'_day ///
								= `freq' * ///
								(`glucose' < `num_hypo' & (`time' < ///
								datetime_end & ///
								`time' > datetime_start))
							by `id': egen min_spent_under_`num_hypo_rnd'_day = ///
								sum(time_spent_under_`num_hypo_rnd'_day)
						}
						
						*percent_time_under_X
						
						foreach num_hypo of numlist `hypo' {
							
							local num_hypo_rnd = subinstr("`num_hypo'", ///
								".", "_", .)
							
							gen percent_time_under_`num_hypo_rnd' = 100 * ///
								(min_spent_under_`num_hypo_rnd' / total_time)
						}

						
						foreach num of numlist `hypo' {
							
							local num_hypo_rnd = subinstr("`num'", ".", "_", .)
							
							gen percent_time_under_`num_hypo_rnd'_day = 100 * ///
								(min_spent_under_`num_hypo_rnd'_day / ///
								total_time_day)
							gen percent_time_under_`num_hypo_rnd'_night = 100 * ///
								(min_spent_under_`num_hypo_rnd'_night / ///
								total_time_night)
						}
						
					*Time-in-range (user-specified)
				
						foreach num_low of numlist `hypo' { 
							foreach num_high of numlist `hyper' { 

								local num_low_rnd = subinstr("`num_low'", ".", "_", .)
								local num_high_rnd = subinstr("`num_high'", ".", "_", .)

								by `id': gen time_spent_`num_low_rnd'_`num_high_rnd' ///
									= `freq' * ///
									(`glucose' >= `num_low' & `glucose' <= `num_high')
								by `id': egen min_spent_`num_low_rnd'_`num_high_rnd' = ///
									sum(time_spent_`num_low_rnd'_`num_high_rnd')
								gen percent_time_`num_low_rnd'_`num_high_rnd' ///
									= 100 * ///
									(min_spent_`num_low_rnd'_`num_high_rnd' ///
									/ total_time)
								 
									by `id': ///
									gen time_spent_`num_low_rnd'_`num_high_rnd'_day = ///
										`freq' * (`glucose'> = `num_low' & ///
										`glucose'< = `num_high' & ///
										(`time' < datetime_end & `time' > ///
										datetime_start))
									by `id': ///
									egen min_spent_`num_low_rnd'_`num_high_rnd'_day = ///
										sum(time_spent_`num_low_rnd'_`num_high_rnd'_day)
									gen percent_time_`num_low_rnd'_`num_high_rnd'_day ///
										= 100 * (min_spent_`num_low_rnd'_`num_high_rnd'_day ///
										/total_time_day)
								
									by `id': ///
									gen time_spent_`num_low_rnd'_`num_high_rnd'_night = ///
										`freq' * (`glucose'> = `num_low' & ///
										`glucose'< = `num_high' ///
										& (`time' >= datetime_end | `time' ///
										<= datetime_start))
									by `id': ///
									egen min_spent_`num_low_rnd'_`num_high_rnd'_night = ///
										sum(time_spent_`num_low_rnd'_`num_high_rnd'_night)
									gen percent_time_`num_low_rnd'_`num_high_rnd'_night ///
										= 100 * ///
										(min_spent_`num_low_rnd'_`num_high_rnd'_night / ///
										total_time_night)
							}
						}
				
						*AUC
						if "`auc'" == "auc" {
								foreach num_hyper of numlist `hyper' {
									
									local num_hyper_rnd = subinstr("`num_hyper'", ".", "_", .)
									
									gen glucose_over_`num_hyper_rnd' = ///
										`glucose' - `num_hyper' ///
										if `glucose' > `num_hyper' & ///
										!missing(`glucose')
									sort `id' `time'
									by `id': gen trapezoid_area_`num_hyper_rnd'///
										= 0.5 * ///
										(glucose_over_`num_hyper_rnd'[_n] + ///
										glucose_over_`num_hyper_rnd'[_n-1]) ///
										* time_int if _n>1
									
									by `id': egen auc_over_`num_hyper_rnd' = ///
										sum(trapezoid_area_`num_hyper_rnd')
								}
						}		
					
						if "`unit'" == "" local unit_grph "mg/dL"
						if "`unit'" != "" local unit_grph "mmol/L"
			
					if "`plot'" != "" & "`unit'" == "" {
										
							sort `id' `time'
		 
						gen plot_nums = substr("`plot'", 1, ///
							strpos("`plot'", ",") - 1) if ///
							strpos("`plot'", ",") > 0
						replace plot_nums = "`plot'" if strpos("`plot'", ",") ///
							== 0

						local plot_num = plot_nums

						* some variables for the figure
						local mylist `plot_num'
						local mylist : subinstr local mylist " " ",", all 
						
						local low_rng = min(`mylist')
						if `low_rng' != floor(`low_rng') {
							local low_rng: di %4.1f `low_rng'
						}
			
						local high_rng = max(`mylist')
						if `high_rng' != floor(`high_rng') {
							local high_rng: di %4.1f `high_rng'
						}
						
						local low_rng_var = subinstr("`low_rng'", ".", "_", .)
						local high_rng_var = subinstr("`high_rng'", ".", "_", .)

						gen y`low_rng_var' = `low_rng'
						gen y`high_rng_var' = `high_rng'
						gen y0= 0
				
						drop plot_nums

						levelsof `id', local(pt_id)

						foreach g in `pt_id' {
							
							preserve	
							
							ds `id', has(type string)
							if "`r(varlist)'" != "" {
								keep if `id' =="`g'" 
							} 
							else {
								keep if `id' == `g'
							}
		
							qui summ `time', d
							local tmin = `r(min)'
							local temp_min = dofc(`tmin')
							local temp_min_fmt: di %tdDDmon `temp_min' 

							local tp25 = `r(p25)'
							local temp_p25 = dofc(`tp25')
							local temp_p25_fmt: di %tdDDmon `temp_p25' 

							local tmean = `r(mean)'
							local temp_mean = dofc(`tmean')
							local temp_mean_fmt: di %tdDDmon `temp_mean'

							local tp75 = `r(p75)'
							local temp_p75 = dofc(`tp75')
							local temp_p75_fmt: di %tdDDmon `temp_p75' 
							
							local tmax = `r(max)'
							local temp_max = dofc(`tmax')
							local temp_max_fmt: di %tdDDmon `temp_max'

							label var `time' "Date"	
		 
							qui summ `glucose'
							
								local ymax = `r(max)'+ 300
								local y_p30 = `ymax'+ 30
								local y_30 = `ymax'- 30
								local y_60 = `ymax'- 60
								local y_90 = `ymax'- 90
								local y_120 = `ymax'- 120
				
							sort `id' `time'

							local mean = trim(string(mean_sensor), "%4.1f")
							local cv = trim(string(cv_sensor), "%4.1f")
							local pctwear = trim(string(percent_cgm_wear), "%4.1f")
							local pct`high_rng_var' = ///
								trim(string(percent_time_over_`high_rng_var'), "%4.1f")
							local pct`low_rng_var' = ///
								trim(string(percent_time_under_`low_rng_var'), "%4.1f")
							local pct`low_rng_var'`high_rng_var' = ///
								trim(string(percent_time_`low_rng_var'_`high_rng_var'), "%4.1f")
									
							local low_rng_plus = `low_rng'+5
							local high_rng_plus = `high_rng'+5
								
							// Create a variable for the plot with gaps
							gen value_plot = `glucose'
							replace value_plot = . if (time_int > 2 * `freq') ///
								& !missing(time_int)

							gen double time_ts = 60000 * floor(`time'/60000)
							format time_ts %tc

							gen time_diff = (time_ts[_n] - time_ts[_n-1])/60000

							qui summ time_diff
							qui tsset time_ts, clocktime delta(`r(min)' minutes) 

							local fill ""
							
							if strpos("`plot'", "fill") > 0 {
								tsfill, full
								local fill "fill"
							}

							if strpos("`plot'", "nostats") == 0 {
								tw ///
									(rarea y`low_rng_var' y`high_rng_var' `time' ///
										if `id' == `g', color(green%10)) ///
									(rarea y0 y`low_rng_var' `time' if `id' ///
										== `g', ///
										color(red%10)) ///
									(tsline value_plot if `id' == `g' ///
										& "`fill'" == "", ///
										lc(gs9) cmissing(no) tlabel(`tmin' ///
										"`temp_min_fmt'" `tp25' ///
										"`temp_p25_fmt'" `tmean' ///
										"`temp_mean_fmt'" `tp75' ///
										"`temp_p75_fmt'" ///
										`tmax' "`temp_max_fmt'")) ///
									(tsline value_plot if `id' == `g' & "`fill'" != "", ///
										lc(gs9) tlabel(`tmin' "`temp_min_fmt'" ///
										`tp25' "`temp_p25_fmt'" `tmean' ///
										"`temp_mean_fmt'" `tp75' "`temp_p75_fmt'" ///
										`tmax' "`temp_max_fmt'")) ///
									(line y`low_rng_var' `time', lcolor(green) ///
										lw(medium) lpattern(solid)) ///
									(line y`high_rng_var' `time', lcolor(green) ///
										lw(medium) lpattern(solid)) ///
									, /// 
									name("plot`g'",replace) graphregion(color(white) ///
										margin(large)) ///
									ytitle("CGM Glucose, `unit_grph'", ///
										size(medlarge)) xtitle("Date", ///
										size(medlarge)) ///
									ylabel(0(100)`ymax',nogrid nogextend ///
										tlwidth(medthick) labsize(medlarge)) ///
										yscale(lwidth(medthick)) ///
									text(`y_p30' `tmin' "ID: `g'", size(medsmall) ///
										placement(east)) ///
									text(`ymax' `tmin' ///
										"Mean glucose: `mean' `unit_grph'; CV: `cv'%", ///
										size(medsmall) placement(east)) ///
									text(`y_30' `tmin' "% CGM wear: `pctwear'%", ///
										size(medsmall) placement(east)) ///
									text(`y_60' `tmin' ///
										"% time >`high_rng' `unit_grph': `pct`high_rng_var''%", ///
										size(medsmall) placement(east)) ///
									text(`y_90' `tmin' ///
										"% time `low_rng' - `high_rng' `unit_grph': `pct`low_rng_var'`high_rng_var''%", ///
										size(medsmall) placement(east)) ///
									text(`y_120' `tmin' ///
										"% time <`low_rng' `unit_grph': `pct`low_rng_var''%", ///
										size(medsmall) placement(east)) ///
									text(`high_rng_plus' `tmax' "`high_rng'", ///
										size(medlarge) placement(east)) ///
									text(`low_rng_plus' `tmax' "`low_rng'", ///
										size(medlarge) placement(east)) ///
									legend(off)
									
								restore
								
									if "`saveplotdir'" != "" graph save ///
									"`saveplotdir'/`g'_ts.gph", replace
							}
							
							if strpos("`plot'", "nostats") > 0 {
								tw ///
									(rarea y`low_rng_var' y`high_rng_var' `time' ///
										if `id' == `g', color(green%10)) ///
									(rarea y0 y`low_rng_var' `time' if `id' ///
										== `g', ///
										color(red%10)) ///
									(tsline value_plot if `id' == `g' & ///
										"`fill'" == "", lc(gs9) cmissing(no) ///
										tlabel(`tmin' "`temp_min_fmt'" `tp25' ///
										"`temp_p25_fmt'" `tmean' "`temp_mean_fmt'" ///
										`tp75' "`temp_p75_fmt'" `tmax' /// 
										"`temp_max_fmt'")) /// 
									(tsline value_plot if `id' == `g' & ///
										"`fill'" != "", lc(gs9) ///
										tlabel(`tmin' "`temp_min_fmt'" `tp25' ///
										"`temp_p25_fmt'" `tmean' "`temp_mean_fmt'" ///
										`tp75' "`temp_p75_fmt'" `tmax' ///
										"`temp_max_fmt'")) ///
									(line y`low_rng_var' `time', lcolor(green) ///
										lw(medium) lpattern(solid)) ///
									(line y`high_rng_var' `time', lcolor(green) ///
										lw(medium) lpattern(solid)) ///
									, /// 
									name("plot`g'",replace) graphregion(color(white) ///
										margin(large)) ///
									ytitle("CGM Glucose, `unit_grph'", ///
										size(medlarge)) xtitle("Date", ///
										size(medlarge)) ///
									ylabel(0(100)`ymax',nogrid nogextend ///
										tlwidth(medthick) labsize(medlarge)) ///
									yscale(lwidth(medthick)) ///
									text(`ymax' `tmin' "ID: `g'", ///
										size(medsmall) placement(east)) ///
									text(`high_rng_plus' `tmax' "`high_rng'", ///
										size(medlarge) placement(east)) ///
									text(`low_rng_plus' `tmax' "`low_rng'", ///
										size(medlarge) placement(east)) ///
									legend(off)
							
								restore
									if "`saveplotdir'" != "" ///
									graph save "`saveplotdir'/`g'_ts.gph", replace
							
							} 
						}
					}

			
					if "`plot'" != "" & "`unit'" != "" {
						
						* generate a numeric time for figure
						sort `id' `time'

						gen plot_nums = substr("`plot'", 1, ///
							strpos("`plot'", ",") - 1) if ///
							strpos("`plot'", ",") > 0
						replace plot_nums = "`plot'" if strpos("`plot'", ",") ///
							== 0

						local plot_num = plot_nums

						* some variables for the figure
						local mylist `plot_num'
						local mylist : subinstr local mylist " " ",", all 

						local low_rng = min(`mylist')
						if `low_rng' != floor(`low_rng') {
							local low_rng: di %4.1f `low_rng'
						}
						
						local high_rng = max(`mylist')
						if `high_rng' != floor(`high_rng') {
							local high_rng: di %4.1f `high_rng'
						}
						
						local low_rng_var = subinstr("`low_rng'", ".", "_", .)
						local high_rng_var = subinstr("`high_rng'", ".", "_", .)

						di `low_rng'
						
							gen y`low_rng_var' = `low_rng'
							gen y`high_rng_var' = `high_rng'
							gen y0= 0

						drop plot_nums
	
						levelsof `id', local(pt_id)

						foreach g in `pt_id' {
			
							preserve	
							
							ds `id', has(type string)
							if "`r(varlist)'" != "" {
								keep if `id' =="`g'" 
							} 
							else {
								keep if `id' == `g'
							}

							qui summ `time',d
							local tmin = `r(min)'
							local temp_min = dofc(`tmin')
							local temp_min_fmt: di %tdDDmon `temp_min' 

							local tp25 = `r(p25)'
							local temp_p25 = dofc(`tp25')
							local temp_p25_fmt: di %tdDDmon `temp_p25' 
							
							local tmean = `r(mean)'
							local temp_mean = dofc(`tmean')
							local temp_mean_fmt: di %tdDDmon `temp_mean'

							local tp75 = `r(p75)'
							local temp_p75 = dofc(`tp75')
							local temp_p75_fmt: di %tdDDmon `temp_p75' 
							
							local tmax = `r(max)'
							local temp_max = dofc(`tmax')
							local temp_max_fmt: di %tdDDmon `temp_max'

							label var `time' "Date"	

							qui summ `glucose'
							
							local ymax = round(`r(max)' + 15, 5)
							local y_2 = `ymax' - 2
							local y_4 = `ymax' - 4
							local y_6 = `ymax' - 6
							local y_8 = `ymax' - 8
							local y_10 = `ymax' - 10
								
							sort `id' `time'
 
							local mean = trim(string(mean_sensor), "%4.1f")
							local cv = trim(string(cv_sensor), "%4.1f")
							local pctwear = trim(string(percent_cgm_wear),"%4.1f")
						
							local pct`high_rng_var' = ///
								trim(string(percent_time_over_`high_rng_var'), "%4.1f")
							local pct`low_rng_var' = ///
								trim(string(percent_time_under_`low_rng_var'), "%4.1f")
							local pct`low_rng_var'`high_rng_var' = ///
								trim(string(percent_time_`low_rng_var'_`high_rng_var'), "%4.1f")
							local low_rng_plus = `low_rng' + .3
							local high_rng_plus = `high_rng' + .3
							
							// Create a variable for the plot with gaps
							gen value_plot = `glucose'
							replace value_plot = . if (time_int > 2 * `freq') & ///
								!missing(time_int)

							gen double time_ts = 60000 * floor(`time' / 60000)
							format time_ts %tc

							gen time_diff = (time_ts[_n] - time_ts[_n-1]) / 60000

							qui summ time_diff
							qui tsset time_ts, clocktime delta(`r(min)' minutes) 

							local fill ""
							
							if strpos("`plot'", "fill") > 0 {
								tsfill, full
								local fill "fill"
							}
							

							if strpos("`plot'", "nostats") == 0 {
								tw ///
									(rarea y`low_rng_var' y`high_rng_var' `time' ///
										if `id' == `g', color(green%10)) ///
									(rarea y0 y`low_rng_var' `time' if `id' ///
										== `g', ///
										color(red%10)) ///
									(tsline value_plot if `id' == `g' ///
										& "`fill'" == "", ///
										lc(gs9) cmissing(no) tlabel(`tmin' ///
										"`temp_min_fmt'" `tp25' ///
										"`temp_p25_fmt'" `tmean' ///
										"`temp_mean_fmt'" `tp75' ///
										"`temp_p75_fmt'" ///
										`tmax' "`temp_max_fmt'")) ///
									(tsline value_plot if `id' == `g' & "`fill'" != "", ///
										lc(gs9) tlabel(`tmin' "`temp_min_fmt'" ///
										`tp25' "`temp_p25_fmt'" `tmean' ///
										"`temp_mean_fmt'" `tp75' "`temp_p75_fmt'" ///
										`tmax' "`temp_max_fmt'")) ///
									(line y`low_rng_var' `time', lcolor(green) ///
										lw(medium) lpattern(solid)) ///
									(line y`high_rng_var' `time', lcolor(green) ///
										lw(medium) lpattern(solid)) ///
									, /// 
									name("plot`g'",replace) graphregion(color(white) ///
										margin(large)) ///
									ytitle("CGM Glucose, `unit_grph'", ///
										size(medlarge)) xtitle("Date", ///
										size(medlarge)) ///
									ylabel(0(5)`ymax',nogrid nogextend ///
										tlwidth(medthick) labsize(medlarge)) ///
										yscale(lwidth(medthick)) ///
									text(`ymax' `tmin' "ID: `g'", size(medsmall) ///
										placement(east)) ///
									text(`y_2' `tmin' ///
										"Mean glucose: `mean' `unit_grph'; CV: `cv'%", ///
										size(medsmall) placement(east)) ///
									text(`y_4' `tmin' "% CGM wear: `pctwear'%", ///
										size(medsmall) placement(east)) ///
									text(`y_6' `tmin' ///
										"% time >`high_rng' `unit_grph': `pct`high_rng_var''%", ///
										size(medsmall) placement(east)) ///
									text(`y_8' `tmin' ///
										"% time `low_rng' - `high_rng' `unit_grph': `pct`low_rng_var'`high_rng_var''%", ///
										size(medsmall) placement(east)) ///
									text(`y_10' `tmin' "% time <`low_rng' `unit_grph': `pct`low_rng_var''%", ///
										size(medsmall) placement(east)) ///
									text(`high_rng_plus' `tmax' "`high_rng'", ///
										size(medlarge) placement(east)) ///
									text(`low_rng_plus' `tmax' "`low_rng'", ///
										size(medlarge) placement(east)) ///
									legend(off)
									
								restore
								
									if "`saveplotdir'" != "" graph save ///
									"`saveplotdir'/`g'_ts.gph", replace
							}
								
							if strpos("`plot'", "nostats") > 0 {
								tw ///
									(rarea y`low_rng_var' y`high_rng_var' `time' ///
										if `id' == `g', color(green%10)) ///
									(rarea y0 y`low_rng_var' `time' ///
										if `id' == `g', color(red%10)) ///
									(tsline value_plot if `id' == `g' & ///
										"`fill'" == "", lc(gs9) cmissing(no) ///
										tlabel(`tmin' "`temp_min_fmt'" `tp25' ///
										"`temp_p25_fmt'" `tmean' "`temp_mean_fmt'" ///
										`tp75' "`temp_p75_fmt'" `tmax' /// 
										"`temp_max_fmt'")) ///
									(tsline value_plot if `id' == `g' & ///
										"`fill'" != "", lc(gs9) ///
										tlabel(`tmin' "`temp_min_fmt'" `tp25' ///
										"`temp_p25_fmt'" `tmean' "`temp_mean_fmt'" ///
										`tp75' "`temp_p75_fmt'" `tmax' ///
										"`temp_max_fmt'")) ///
									(line y`low_rng_var' `time', lcolor(green) ///
										lw(medium) lpattern(solid)) ///
									(line y`high_rng_var' `time', lcolor(green) ///
										lw(medium) lpattern(solid)) ///
									, /// 
									name("plot`g'",replace) graphregion(color(white) ///
										margin(large)) ///
									ytitle("CGM Glucose, `unit_grph'", ///
										size(medlarge)) xtitle("Date", ///
										size(medlarge)) ///
									ylabel(0(5)`ymax',nogrid nogextend ///
										tlwidth(medthick) labsize(medlarge)) ///
									yscale(lwidth(medthick)) ///
									text(`ymax' `tmin' "ID: `g'", ///
										size(medsmall) placement(east)) ///
									text(`high_rng_plus' `tmax' "`high_rng'", ///
										size(medlarge) placement(east)) ///
									text(`low_rng_plus' `tmax' "`low_rng'", ///
										size(medlarge) placement(east)) ///
									legend(off)
								restore
									if "`saveplotdir'" != "" ///
									graph save "`saveplotdir'/`g'_ts.gph", replace
							}
						}
					}

					if "`auc'" == "auc" {
						capture collapse (min) mean_sensor* median_sensor* ///
						sd_sensor* q1_sensor* q3_sensor* cv_sensor* ///
						min_sensor* max_sensor* percent_cgm_wear ///
						total_sensor_readings `time' ndayswear min_spent_* ///
						percent_time* auc_over_* (sum) exc_over_* exc_under_* ///
						(mean) avg_max_sensor hypo_lngth_* hyper_lngth_*, by(`id') 
					}
			
			
					if "`auc'" != "auc" {	
							capture collapse (min) mean_sensor* median_sensor* ///
							sd_sensor* q1_sensor* q3_sensor* cv_sensor* ///
							min_sensor* max_sensor* percent_cgm_wear ///
							total_sensor_readings `time' ndayswear min_spent_* ///
							percent_time* (sum) exc_over_* exc_under_* ///
							(mean) avg_max_sensor hypo_lngth_* ///
							hyper_lngth_*, by(`id') 
					}
				
			
					rename hypo_lngth_* avg_hypo_lngth_*
					rename hyper_lngth_* avg_hyper_lngth_*
					
					foreach v of varlist mean_sensor* median_sensor* ///
					sd_sensor* cv_sensor* q1_sensor* q3_sensor* min_sensor* ///
					max_sensor* ndayswear percent_* avg_* { // 
							format `v' %9.1f
					}
					
					capture format auc_* %9.1f 
					
					rename exc_over_* episodes_over_*
					rename exc_under_* episodes_under_*

					rename `time' first_glucose_reading
				
			if "`unit'" == "" {
					label var mean_sensor "Mean sensor glucose (mg/dL)"
					label var mean_sensor_day "Day time mean sensor glucose (mg/dL)"
					label var mean_sensor_night "Night time mean sensor glucose (mg/dL)"
					label var median_sensor "Median sensor glucose (mg/dL)"
					label var median_sensor_day "Day time median sensor glucose (mg/dL)"
					label var median_sensor_night "Night time median sensor glucose (mg/dL)"
					label var sd_sensor "SD sensor glucose (mg/dL)"
					label var sd_sensor_day "Day time SD sensor glucose (mg/dL)"
					label var sd_sensor_night "Night time SD sensor glucose (mg/dL)"
					label var q1_sensor "First quartile sensor glucose value (mg/dL)"
					label var q1_sensor_day "Day time first quartile sensor glucose value (mg/dL)"
					label var q1_sensor_night "Night time first quartile sensor glucose value (mg/dL)"
					label var q3_sensor "Third quartile sensor glucose value (mg/dL)"
					label var q3_sensor_day "Day time third quartile sensor glucose value (mg/dL)"
					label var q3_sensor_night "Night time third quartile sensor glucose value (mg/dL)"
					label var min_sensor "Minimum of all sensor glucose values (mg/dL)"
					label var min_sensor_day "Day time minimum of all sensor glucose values (mg/dL)"
					label var min_sensor_night "Night time minimum of all sensor glucose values (mg/dL)"
					label var max_sensor "Maximum of all sensor glucose values (mg/dL)"	
					label var max_sensor_day "Day time maximum of all sensor glucose values (mg/dL)"	
					label var max_sensor_night "Night time maximum of all sensor glucose values (mg/dL)"	
			}
			else {
					label var mean_sensor "Mean sensor glucose (mmol/L)"
					label var mean_sensor_day "Day time mean sensor glucose (mmol/L)"
					label var mean_sensor_night "Night time mean sensor glucose (mmol/L)"
					label var median_sensor "Median sensor glucose (mmol/L)"
					label var median_sensor_day "Day time median sensor glucose (mmol/L)"
					label var median_sensor_night "Night time median sensor glucose (mmol/L)"
					label var sd_sensor "SD sensor glucose (mmol/L)"
					label var sd_sensor_day "Day time SD sensor glucose (mmol/L)"
					label var sd_sensor_night "Night time SD sensor glucose (mmol/L)"
					label var q1_sensor "First quartile sensor glucose value (mmol/L)"
					label var q1_sensor_day "Day time first quartile sensor glucose value (mmol/L)"
					label var q1_sensor_night "Night time first quartile sensor glucose value (mmol/L)"
					label var q3_sensor "Third quartile sensor glucose value (mmol/L)"
					label var q3_sensor_day "Day time third quartile sensor glucose value (mmol/L)"
					label var q3_sensor_night "Night time third quartile sensor glucose value (mmol/L)"
					label var min_sensor "Minimum of all sensor glucose values (mmol/L)"
					label var min_sensor_day "Day time minimum of all sensor glucose values (mmol/L)"
					label var min_sensor_night "Night time minimum of all sensor glucose values (mmol/L)"
					label var max_sensor "Maximum of all sensor glucose values (mmol/L)"	
					label var max_sensor_day "Day time maximum of all sensor glucose values (mmol/L)"	
					label var max_sensor_night "Night time maximum of all sensor glucose values (mmol/L)"			
			}
			
			label var cv_sensor "CV sensor glucose (%)"
			label var cv_sensor_day "Day time CV sensor glucose (%)"
			label var cv_sensor_night "Night time CV sensor glucose (%)"
			label var percent_cgm_wear "The # of sensor readings as a percentage of the # of potential readings given time worn"
			label var total_sensor_readings "The total # of sensor readings"
			label var ndayswear "# of days sensor was worn"

				
			foreach num_high of numlist `hyper' { 
				
			local num_high_rnd = subinstr("`num_high'", ".", "_", .)
			
				if "`unit'" == "" {
					label var min_spent_over_`num_high_rnd' "The total length of time that sensor glucose was at or above `num_high' mg/dL"
					label var min_spent_over_`num_high_rnd'_day "The total length of time that sensor glucose was at or above `num_high' mg/dL during the day" 
					label var min_spent_over_`num_high_rnd'_night "The total length of time that sensor glucose was at or above `num_high' mg/dL during the night" 
					label var percent_time_over_`num_high_rnd' "Minutes spent above `num_high' mg/dL, as a percentage of the total time CGM was worn"
					label var percent_time_over_`num_high_rnd'_day "Minutes spent above `num_high' mg/dL during the day, as a percentage of the total time CGM was worn during the day" 
					label var percent_time_over_`num_high_rnd'_night "Minutes spent above `num_high' mg/dL during the night, as a percentage of the total time CGM was worn during the night" 
					label var episodes_over_`num_high_rnd' "Count of glucose episodes (≥`hyper_exc_lngth' min) above `num_high' mg/dL" 
					label var avg_hyper_lngth_`num_high_rnd' "Mean length of hyperglycemic episodes above `num_high' mmol/L" 
					capture label var auc_over_`num_high_rnd' "AUC over `num_high' mg/dL"
				}
				
				else {
					label var min_spent_over_`num_high_rnd' "The total length of time that sensor glucose was at or above `num_high' mmol/L"
					label var min_spent_over_`num_high_rnd'_day "The total length of time that sensor glucose was at or above `num_high' mmol/L during the day" 
					label var min_spent_over_`num_high_rnd'_night "The total length of time that sensor glucose was at or above `num_high' mmol/L during the night" 
					label var percent_time_over_`num_high_rnd' "Minutes spent above `num_high' mmol/L, as a percentage of the total time CGM was worn" 
					label var percent_time_over_`num_high_rnd'_day "Minutes spent above `num_high' mmol/L during the day, as a percentage of the total time CGM was worn during the day" 
					label var percent_time_over_`num_high_rnd'_night "Minutes spent above `num_high' mmol/L during the night, as a percentage of the total time CGM was worn during the night" 
					label var episodes_over_`num_high_rnd' "Count of glucose episodes (≥`hyper_exc_lngth' min) above `num_high' mmol/L" 
					label var avg_hyper_lngth_`num_high_rnd' "Mean length of hyperglycemic episodes above `num_high' mmol/L" 
					capture label var auc_over_`num_high_rnd' "AUC over `num_high' mmol/L"
				}
			}
			
		 
			foreach num_low of numlist `hypo' { 
							
				local num_low_rnd = subinstr("`num_low'", ".", "_", .)
				
				
				if "`unit'" == "" {
					 label var min_spent_under_`num_low_rnd' "The total length of time that sensor glucose was at or below `num_low' mg/dL" 
					 label var min_spent_under_`num_low_rnd'_day "The total length of time that sensor glucose was at or below `num_low' mg/dL during the day"
					 label var min_spent_under_`num_low_rnd'_night "The total length of time that sensor glucose was at or below `num_low' mg/dL during the night" 
					 label var percent_time_under_`num_low_rnd' "Minutes spent below `num_low' mg/dL, as a percentage of the total time CGM was worn" 
					 label var percent_time_under_`num_low_rnd'_day "Minutes spent below `num_low' mg/dL during the day, as a percentage of the total time CGM was worn during the day" 
					 label var percent_time_under_`num_low_rnd'_night "Minutes spent below `num_low' mg/dL during the night, as a percentage of the total time CGM was worn during the night" 
					 label var episodes_under_`num_low_rnd' "Count of glucose episodes (≥`hypo_exc_lngth' min) lower than `num_low' mg/dL" 
					 label var avg_hypo_lngth_`num_low_rnd' "Mean length of hypoglycemic episodes below `num_low' mg/dL" 	
				}
				
				else {
					label var min_spent_under_`num_low_rnd' "The total length of time that sensor glucose was at or below `num_low' mmol/L" 
					label var min_spent_under_`num_low_rnd'_day "The total length of time that sensor glucose was at or below `num_low' mmol/L during the day" 
					label var min_spent_under_`num_low_rnd'_night "The total length of time that sensor glucose was at or below `num_low' mmol/L during the night" 
					label var percent_time_under_`num_low_rnd' "Minutes spent below `num_low' mmol/L, as a percentage of the total time CGM was worn" 
					label var percent_time_under_`num_low_rnd'_day "Minutes spent below `num_low' mmol/L during the day, as a percentage of the total time CGM was worn during the day" 
					label var percent_time_under_`num_low_rnd'_night "Minutes spent below `num_low' mmol/L during the night, as a percentage of the total time CGM was worn during the night" 
					label var episodes_under_`num_low_rnd' "Count of glucose episodes (≥`hypo_exc_lngth' min) lower than `num_low' mmol/L" 
					label var avg_hypo_lngth_`num_low_rnd' "Mean length of hypoglycemic episodes below `num_low' mmol/L" 
				}
			
			}

			foreach numl of numlist `hypo' { 
				foreach numh of numlist `hyper' { 		
					
				local num_low = subinstr("`numl'", ".", "_", .)
				local num_high = subinstr("`numh'", ".", "_", .)

				
						if "`unit'" == ""{
							 label var min_spent_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive)" 
							 label var min_spent_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the day" 
							 label var min_spent_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the night" 
							 label var percent_time_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive), as a percentage of the total time CGM was worn" 
							 label var percent_time_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the day, as a percentage of the total time CGM was worn during the day" 
							 label var percent_time_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mg/dL (inclusive) during the night, as a percentage of the total time CGM was worn during the night" 
						}
						
						else {
							label var min_spent_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive)" 
							label var min_spent_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the day" 
							label var min_spent_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the night"
							label var percent_time_`num_low'_`num_high' "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive), as a percentage of the total time CGM was worn" 
							label var percent_time_`num_low'_`num_high'_day "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the day, as a percentage of the total time CGM was worn during the day"
							label var percent_time_`num_low'_`num_high'_night "Minutes spent in glucose range `numl' - `numh' mmol/L (inclusive) during the night, as a percentage of the total time CGM was worn during the night" 		
						}	
				}
			}
			
			label var `id' "ID"
			label var first_glucose_reading "Timestamp of first glucose reading"
			label var avg_max_sensor "Average max CGM reading across all days"

			if "`auc'" != "" {
				order `id' first_glucose_reading ndayswear total_sensor_readings ///
				percent_cgm_wear mean_sensor* median_sensor* q1_sensor* q3_sensor* ///
				min_sensor* max_sensor* avg_max_sensor sd_sensor* cv_sensor* ///
				min_spent* percent_time_* episodes_under* avg_hypo_lngth* ///
				min_spent_over* percent_time_over* episodes_over* ///
				avg_hyper_lngth* auc_over* 
			}
			

			if "`auc'" == "" {
				order `id' first_glucose_reading ndayswear total_sensor_readings ///
				percent_cgm_wear mean_sensor* median_sensor* q1_sensor* q3_sensor* ///
				min_sensor* max_sensor* avg_max_sensor sd_sensor* cv_sensor* min_spent* ///
				percent_time_* episodes_under* avg_hypo_lngth* min_spent_over* ///
				percent_time_over* episodes_over* avg_hyper_lngth* 
			}
			
			compress
			if "`savesumdta'" != "" & "`savesumdir'" != "" save ///
				"`savesumdir'/`savesumdta'", replace
			if "`savesumdta'" != "" & "`savesumdir'" == "" save ///
				"`savesumdta'", replace
				
			if "`hist'" != "" & strpos("`hist'", "freq") > 0 {	
			
				gen hist_vars = substr("`hist'", 1, strpos("`hist'", ",") - 1) ///
					if strpos("`hist'", ",") > 0
				replace hist_vars = "`hist'" if strpos("`hist'", ",") == 0
				
				local hist_var = hist_vars
		
				foreach v in `hist_var' {
						
					local `v'_lbl: variable label `v'
						
					gen open_pos = strpos("`hist'", "(")    
					gen close_pos = strpos("`hist'", ")") 
					
					if open_pos > 0 & close_pos > 0 {
						local barwidth = substr("`hist'", open_pos + 1, ///
						close_pos - open_pos - 1) 

					histogram `v', freq xtitle("``v'_lbl'") barwidth(`barwidth') ///
						legend(off) ytitle("Frequency") name(`v', replace) 	
					}
					
					drop open_pos close_pos	
					
					else {
						histogram `v', freq xtitle("``v'_lbl'") legend(off) ///
						ytitle("Frequency") name(`v', replace) 
					}
					
					if "`saveplotdir'" != "" graph save "`saveplotdir'/`v'", ///
					replace	
				}
						
				noi summ `hist_var' 
				drop hist_vars
			}

			if "`hist'" != "" & strpos("`hist'", "freq") == 0 {	

			gen hist_vars = substr("`hist'", 1, strpos("`hist'", ",") - 1) if ///
				strpos("`hist'", ",") > 0
			replace hist_vars = "`hist'" if strpos("`hist'", ",") == 0

			local hist_var = hist_vars
			
				foreach v in `hist_var' {
				
					local `v'_lbl: variable label `v'
					
					gen open_pos = strpos("`hist'", "(")    
					gen close_pos = strpos("`hist'", ")") 
					
					if open_pos > 0 & close_pos > 0 {
						local barwidth = substr("`hist'", open_pos + 1, ///
						close_pos - open_pos - 1) 
					
						twoway(histogram `v', barwidth(`barwidth'))///
						(kdensity `v'),  ///
						xtitle("``v'_lbl'") legend(off) ytitle("Density") ///
						name(`v', replace) 	
					}
				
					drop open_pos close_pos
				
					else {
						twoway(histogram `v')(kdensity `v'),  xtitle("``v'_lbl'") ///
						legend(off) ytitle("Density") name(`v', replace) 
					}
						
					if "`saveplotdir'" != "" graph save "`saveplotdir'/`v'", ///
					replace
				
				}
					
				noi summ `hist_var' 
				drop hist_vars
			}
	}
}
end


log close


