********************************************************************************
* mean_ci_plot
********************************************************************************

program mean_ci_plot

version 11

syntax varlist(min=1 numeric)    	/// 
       [if]                      	/// 
	   [in],                    	///
	   [By(varname)]    			///
	   [Title(string)]				///
	   [Scale] 						///
	   [Graphopts(string asis)]  	
	   
	* The program will not run without coefplot (and coefplot can run on Stata version 11 or higher)
	   
	cap which coefplot
	if _rc == 111{
			
	display as err "	Sorry, this wrapper function requires the 'coefplot' package"
	display as err "	Prior to running this command, you need to run:" 
	display as err "	ssc install coefplot, replace"
	exit 198
}
	      	   	
* 	Temp files

	qui tempfile main
	qui save     `main', replace

* 	Sample indicator for mapping the [IF] [IN] conditions

	marksample touse, strok
	qui keep if `touse' == 1

	if "`title'" !="" {
	global graph_title "`title'"
}

	if "`title'" == "" {
	global graph_title "Means and confidence intervals"
}
	
	if "`scale'" !="" {
    global x_title 	"Percentage (%)"
	global x_lab 	"0(20)100"
}

	if "`scale'" == "" {
    global x_title 	""
	global x_lab 	"#5"
}	

	eststo clear
	estimates clear    
	mean `varlist'
	estimates store simple
	local n = e(N) 

if "`by'" =="" {

	global call 	"simple"
	global leg		"off"
}
	
if "`by'" !="" {	

	global call
	
	local by_label: value label `by'

	levelsof `by', local(levels)
	
	foreach l of local levels {

    local c_label: label (`by') `l'	
    local n_label = subinstr("`c_label'", " ", "_", .)
    label define `by_label' `l' "`n_label'", modify
	
	mean `varlist' if `by' == `l'
	estimates store `: label (`by') `l''
				
	gen temp_lab_`l' =.		
	lab var temp_lab_`l'  "`: label (`by') `l''"

}

	foreach v of varlist temp_lab* {	
	local leg_lab = subinstr("`: var la `v''", "_", " ", .)
	global call "$call (`: var la `v'', label(`leg_lab'))"
}

	drop temp_lab*
	
	global leg 	  "position(6) rows(1)"
}

	coefplot $call,                             ///  
	title("$graph_title (n = `n')", 			/// 
	size(medium))                               /// 
	xlab($x_lab)                                ///
	xtitle( $x_title )                          ///
	mlabel format(%9.1f)                        /// 
	mlabposition(12)                            /// 
	mlabgap(*2)                                 /// 
	ciopts(recast(rcap))                        /// 
	legend($leg)                 				///
	`graphopts' 
 
	macro drop call
	macro drop x_title
	macro drop x_lab
	macro drop graph_title
	macro drop leg

	qui use `main', clear

end	
