
program diff_plot

	version 11.2
	
	
syntax varlist(max=1 numeric)    	/// 
       [if]                      	/// 
	   [in],                    	///
	   Time(varname)				///
	   Group(varname)				///
	   [DRop_trend]					///
	   [TItle(string)]       		///
	   [DEcimals(integer 2)] 		///
	   [SCale] 						///
	   [GRaphopts(string)]			///
	   [L1_opts(string)]			///
	   [L2_opts(string)]			///
	   [L3_opts(string)]			///
	   [M1_opts(string)]			///
	   [M2_opts(string)]			///
	   [M3_opts(string)]			

********************************************************************************	

* Basic checks prior to running the program

********************************************************************************   
	   
	* Check if elabel is installed
	   
	cap which elabel
	if _rc == 111{
			
	display as err "	This module requires the 'elabel' package to search through labels of the time and treatment variables."
	display as err "	You need to run:" 
	display as err "	ssc install elabel, replace"
	exit 198
}	
	      	  
qui {	
	
********************************************************************************	

* Setup 

******************************************************************************** 
	
	* Use preserve rather than temp files (as recommended by Kit Baum)
	
	preserve 

	* Sample indicator for mapping the [IF] condition
	
	marksample touse

	* Keep if X == x
	
	qui keep if `touse' == 1
	
	* Check if time and group variables take only two unique values
	
	levelsof `time', local(time_levels)
	local num_time_levels: word count `time_levels'
	
	if `num_time_levels' != 2 {
		display as err "	The time variable must contain only two unique values."
		exit 198
	}

	levelsof `group', local(group_levels)
	local num_group_levels: word count `group_levels'
	
	if `num_group_levels' != 2 {
		display as err "	The group variable must contain only two unique values."
		exit 198
	}
		
********************************************************************************	

* Save locals for later use

********************************************************************************
	
	local varlabel : variable label `varlist'
	
	* If missing, assign actual values as value labels to time and group variables 
	
	local val_lab: value label `time'
	
	if "`val_lab'" == "" {

	levelsof `time', local(time_levels)
	
	foreach val of local time_levels {
	label define time_lbl `val' "`val'", add
	}
	
	label values `time' time_lbl
	}
	
		
	local val_lab: value label `group'
	
	if "`val_lab'" == "" {

	levelsof `group', local(group_levels)
	
	foreach val of local group_levels {
	label define group_lbl `val' "`val'", add
	}
	
	label values `group' group_lbl	
	}	


* Save data points to add to graphs

	levelsof `time', local(time_levels)
	local time1: word 1 of `time_levels'
	local time2: word 2 of `time_levels'
	
	elabel list (`time') iff (# == `time1')
	local time_lab1 = `r(labels)'
	
	elabel list (`time') iff (# == `time2')
	local time_lab2 = `r(labels)'

	levelsof `group', local(group_levels)
	local group1: word 1 of `group_levels'
	local group2: word 2 of `group_levels'

	elabel list (`group') iff (# == `group1')
	local group_lab1 = `r(labels)'
	
	elabel list (`group') iff (# == `group2')
	local group_lab2 = `r(labels)'
	
	if "`title'" != "" {	
	local graph_title "`title'"
}

	if "`title'" == "" {
	local graph_title "Change from `time_lab1' to `time_lab2' for `varlabel'"
}

	local ylab
	
	if "`scale'" !="" {
	local ylab ylabel(0(20)100)
}
	
	* Store locals for control group 
	
	summarize `varlist' if `time' == `time1' & `group' == `group1'
	local control_p1 = r(mean)

	summarize `varlist' if `time' == `time2' & `group' == `group1'
	local control_p2 = r(mean)

	* Store locals for treatment group 
	
	summarize `varlist' if `time' == `time1' & `group' == `group2'
	local treatment_p1 = r(mean)

	summarize `varlist' if `time' == `time2' & `group' == `group2'
	local treatment_p2 = r(mean)

	* Calculate the difference between the baseline values

	local baseline_diff = `treatment_p1' - `control_p1'

	* Calculate the endline value for the parallel trend line

	local parallel_trend_p2 = `control_p2' + `baseline_diff'
	
	* Calculate the intervention effect
	
	local int_eff 		= (`treatment_p2' - `treatment_p1') - (`control_p2' - `control_p1')
	local int_eff_fmt 	= strltrim("`: display %9.`decimals'f `int_eff''")

********************************************************************************	

* Create a new dataset

********************************************************************************
	
	clear
	set obs 6
	gen str30 group = ""
	gen str10 time = ""
	gen float value = .

	replace group = "Control" in 1
	replace time = "Period 1" in 1
	replace value = `control_p1' in 1

	replace group = "Control" in 2
	replace time = "Period 2" in 2
	replace value = `control_p2' in 2

	replace group = "Treatment" in 3
	replace time = "Period 1" in 3
	replace value = `treatment_p1' in 3

	replace group = "Treatment" in 4
	replace time = "Period 2" in 4
	replace value = `treatment_p2' in 4

	replace group = "Parallel Trend" in 5
	replace time = "Period 1" in 5
	replace value = `treatment_p1' in 5

	replace group = "Parallel Trend" in 6
	replace time = "Period 2" in 6
	replace value = `parallel_trend_p2' in 6

	* Encode the time variable
	
	encode time, gen(time_num)
	
	* Format labels for the scatter plot values
	
	gen lab_val = string(value, "%8.`decimals'f")
	
	* Dynamically pad the y-axis (by 5%)
	
	sum value
	local min_value = `r(min)'
	local max_value = `r(max)'
	local range = abs(`max_value' - `min_value')

	local y1 = `min_value' - 0.05*`range'
	local y2 = `max_value' + 0.05*`range'
	
********************************************************************************	

* Make the graph

********************************************************************************

	if "`drop_trend'" == "" {	

	twoway ///
	(line 		value time_num 	if group == "Control", 			lcolor(blue) 	lpattern(solid) lwidth(medium) 					 `l1_opts') ///
	(scatter 	value time_num 	if group == "Control", 			mcolor(blue) 	mlabel(lab_val) mlabposition(12) mlabcolor(blue)	`m1_opts') ///
	(line 		value time_num 	if group == "Treatment", 		lcolor(green) 	lpattern(solid) lwidth(medium) 					 `l2_opts') ///
	(scatter 	value time_num 	if group == "Treatment", 		mcolor(green) 	mlabel(lab_val) mlabposition(12) mlabcolor(green) `m2_opts') ///
	(line 		value time_num 	if group == "Parallel Trend",	lcolor(green) 	lpattern(dash) lwidth(medium) 					 `l3_opts') ///
	(scatter 	value time_num 	if group == "Parallel Trend",	mcolor(green) 	mlabel(lab_val) mlabposition(12) mlabcolor(green) `m3_opts'), ///
	legend(order(1 "`group_lab1'" 3 "`group_lab2'" 5 "Parallel Trend")) legend(pos(6) row(1)) ///
	title("`graph_title'", size(small) span) subtitle("Intervention Effect: `int_eff_fmt'", size(vsmall) span) xtitle("Time") ytitle("") ///
	xlabel(1 "`time_lab1'" 2 "`time_lab2'") xscale(range(0.95 2.05)) yscale(range(`y1' `y2')) `ylab' `graphopts' 		

}

	if "`drop_trend'" != "" {	
		
		twoway ///
	(line 		value time_num 	if group == "Control", 			lcolor(blue) 	lpattern(solid) lwidth(medium) 					 `l1_opts') ///
	(scatter 	value time_num 	if group == "Control", 			mcolor(blue) 	mlabel(lab_val) mlabposition(12) mlabcolor(blue)	 `m1_opts') ///
	(line 		value time_num 	if group == "Treatment", 		lcolor(green) 	lpattern(solid) lwidth(medium) 					 `l2_opts') ///
	(scatter 	value time_num 	if group == "Treatment", 		mcolor(green) 	mlabel(lab_val) mlabposition(12) mlabcolor(green) `m2_opts'), ///
	legend(order(1 "`group_lab1'" 3 "`group_lab2'")) legend(pos(6) row(1)) ///
	title("`graph_title'", size(small) span) xtitle("Time") ytitle("") ///
	xlabel(1 "`time_lab1'" 2 "`time_lab2'") xscale(range(0.95 2.05)) yscale(range(`y1' `y2')) `ylab' `graphopts' 		

}

	* Go back to the user's dataset
	
	restore
	
}

end

