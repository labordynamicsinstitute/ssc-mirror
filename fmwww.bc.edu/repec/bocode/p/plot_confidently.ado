

********************************************************************************
* Plot Confidently
********************************************************************************

capture program drop plot_confidently
program plot_confidently

version 17

syntax varlist(numeric min=1) ///
		[if]            /// 
		[in],           /// 
		[Over(varname)] /// 
		[By(varname)]   ///
		[Graphopts(string asis)] ///
		[Scale]
			   
	/// temp file

	qui tempfile main 
	qui save  `main', replace

	/// sample indicator for mapping the [IF] condition

	marksample touse, strok

	/// keep if X == x

	qui keep if `touse' == 1
			
	local check : word 1 of `varlist'
	qui count if !(missing(`check'))
	local N = `r(N)'
	
	
if(`r(N)' <= 0){
			
	display as err "	Sorry! There are no observations to work with."

}

	
if(`r(N)'> 0){		
	
	unab vars : `varlist'	
	if(`: word count `vars'' > 1){
			
	display as err "	This program works with only one variable."
	display as err "	For multiple variables, please use mult_plot."
	display as err "	You need to run:" 
	display as err "	ssc install multi_plot, replace"
	exit 198
}
	
	/// this requires coefplot to work
	cap which coefplot
	if _rc == 111{
			
	display as err "	Sorry! This wrapper function requires the 'coefplot' package!"
	display as err "	You need to run:" 
	display as err "	ssc install coefplot, replace"
	exit 198
}

* Accounting for scale

	if "`scale'" !="" {
	
    global x_title "Percentage (%)"
	global xlabs "0(20)100"
}

	if "`scale'" == "" {
	
    global x_title ""
	global xlabs "#5"
}
	
* simple plot

	if "`over'" == "" & "`by'" == "" {
		
	estimates clear    
	qui mean `varlist'
	estimates store simple
	local n = e(N) 

	coefplot simple,                             ///  
	title("Estimates with confidence intervals (N=`n')", /// 
	size(medium))                               /// 
	xlab($xlabs)                                ///
	xtitle($x_title)                            ///
	mlabel format(%9.1f)                        /// 
	mlabposition(12)                            /// 
	mlabgap(*2)                                 /// 
	ciopts(recast(rcap))                        /// 
	`graphopts' 		
}

	if "`over'" == "" & "`by'" != "" {
		
	display as err "	Sorry! 'By' is a second order level of disaggregation for this command."
	display as err "	'By' can only be used in conjunction with 'over'"
	display as err "	If you want only one level of disaggregation, please use 'over'"
}

	if "`over'" != "" {
		
	* IF by has not been specified
		if "`by'" =="" {
	
	* Calculate N accounting for any missing observations under `over'
	
	qui summarize `varlist' if `over' != . 
	local N = `r(N)'
	local var_mean = strltrim("`: display %9.1f r(mean)'")
 
preserve

qui statsby,  /// 
by(`over')    /// 
clear:        /// 
ci            /// 
means         /// 
`varlist'

qui{
egen label = concat(`over'), decode p(" x ")
/// calculates the correct group-wise DoF --- note: DoF = N-1 foreach group mean
replace N  = N-1
/// making a matrix of summary stats
mkmat mean /// 
      se   /// 
	  lb   /// 
	  ub   /// 
	  N,   /// 
	  matrix(R)
mat  R = R' 
}

* labels
qui{
levelsof `over', local(levels)
local lbls
foreach   z of local levels {
    local lbl : label (`over') `z'
    local lbls      `" `lbls' "`lbl'" "'
}
local  lbls         `" `lbls' "'
matrix colnames R = `lbls'
restore
}

//// syntax to make a plot using coefplot() via a matrix
global call "(matrix(R), se(2) df(R[5,.]))"

/*
making the plot using the all globals and our matrices
*/
	
coefplot $call,                                       		///
xline(`var_mean',                                     		/// 
lcolor(red))                                          		///
ciopts(recast(rcap))                                  		///
title("`: var la `varlist''",  size(medium))          		///
subtitle("N = `N' and Mean = `var_mean'", size(small)) 		/// 
ytitle("`: var la `over' '")                       			///
xtitle("`: var la `varlist''")                       		///
mlabel                                                		/// 
format(%9.1f)                                         		/// 
mlabposition(12)                                      		///
legend(subtitle("`: var la `over' '",              			/// 
size(small)))                                         		/// 
legend(position(6)                                   		/// 
size(small)                                           		///
rows(1))                                              		/// 
levels(95)                                            		///
xlab($xlabs)                                		  		///
legend(off)                                           		///
plotregion(margin(large))                             		/// 
 `graphopts'                                          

}

	* IF by has been specified
		if "`by'" !="" {
	
	* Calculate N accounting for any missing observations under `over' or 'by'
	qui summarize `varlist' if (`by' != . & `over' != .)
	local N = `r(N)'
	local var_mean = strltrim("`: display %9.1f r(mean)'")
	
	
qui levelsof `by', local(plot_levels)
foreach p of local plot_levels {  
preserve

qui keep if `by' == `p'

qui statsby, /// 
by(`over')  /// 
clear:       /// 
ci           /// 
means        /// 
`varlist'

qui{
egen label = concat(`over'), decode p(" x ")
replace N = N-1
mkmat mean /// 
	  se   /// 
	  lb   /// 
	  ub   /// 
	  N,   /// 
	  matrix(R_`p')
mat R_`p' = R_`p'' 
}

qui{
levelsof `over', local(levels)
local lbls_`p'
foreach   z of local levels {
	local lbl_`p' : label (`over') `z'
    local lbls_`p' `" `lbls_`p'' "`lbl_`p''" "'
}
local lbls `" `lbls_`p'' "'
matrix colnames R_`p' = `lbls_`p''
restore
	}
}

qui { 
levelsof `by', local(levels)
global call
qui local labl : value label `by'
qui foreach l of local levels {
		         local `by'`l' : label `labl' `l'	
		
* creating an empty variable that is labelled with the command we need - we then extract the command from the label
		gen cat_`l'   = ""	
		lab var cat_`l'     "(matrix(R_`l'), se(2) df(R_`l'[5,.]) label(``by'`l''))"
			foreach v of varlist cat_* {
						global call "$call `: var la `v''"		
						drop cat_*
		}	
	}	
}	
	
/*
making the plot using the all globals and our new matrices
*/

coefplot $call,                                       	///
xline(`var_mean',                                     	/// 
lcolor(red))                                          	///
ciopts(recast(rcap))                                  	///
title("`: var la `varlist''",  size(medium))          	///
subtitle("N = `N' and Mean = `var_mean'", size(small)) 	/// 
ytitle("`: var la `over' '")                        	///
xtitle("`: var la `varlist''")                        	///
mlabel                                                	/// 
format(%9.1f)                                         	/// 
mlabposition(12)                                      	///
legend(subtitle("`: var la `by' '",              		/// 
size(small)))                                         	/// 
legend(position(6)                                    	/// 
size(small)                                           	///
rows(1))                                              	/// 
levels(95)                                            	///
xlab($xlabs)                                			///
legend(on)                                            	///
plotregion(margin(large))                             	///
`graphopts'                                           

	}

}	

	
	}
	
	cap macro drop call
	cap macro drop xlabs
	cap macro drop xtitle
	qui use `main', clear

end	
