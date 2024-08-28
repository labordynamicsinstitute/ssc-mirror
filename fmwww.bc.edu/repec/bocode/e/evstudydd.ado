*! evstudydd: estimate event studies in D-i-D settings using the reghdfe or ppmlhdfe packages. It requires reghdfe and ppmlhdfe to be installed.
*! Version: August, 2024
*! Authors: Adrien Matray, Pablo E. Rodriguez

qui{

cap program drop evstudydd
program define evstudydd
version 13.0
    syntax varlist(numeric min=2 max=2) [if] [in], Treated(name) SHOCKTime(string) Period(string) CLuster(string) FE(string) Name(string) [Weight(name)] [CONTrols(string)] ///
	[Estimator(string)]

    * Temporarily capture variables from varlist
    tokenize `varlist'
    local Y `1'
    local t `2'
    
    * Validate treated var defined
    if "`treated'" == "" {
        di as err "You must specify a treated variable"
        exit 198
    }
    * Validate shock period defined
    if "`shocktime'" == "" {
        di as err "You must specify the variable or numeric value for the time of the shock (also used as the ref. time for event study)"
        exit 198
    }

    * Validate period option defined
    if "`period'" == "" {
        di as err "You must specify the period option in the format lower_bound upper_bound"
        exit 198
    }

    * Validate name option defined
    if "`name'" == "" {
        di as err "You must specify the name option to store .dta dataset"
        exit 198
    }
	
	* Validate estimator option
    if "`estimator'" != "" & "`estimator'" != "ols" & "`estimator'" != "reghdfe" & "`estimator'" != "ppmlhdfe" & "`estimator'" != "poisson" {
        di as err "Invalid estimator specified. Allowed values are blank (default is reghdfe), ols, reghdfe, ppmlhdfe, or poisson."
        exit 198
    }
	
    * Parse the period option
    tokenize `period'
    local before `1'
    local after `2'
    
    * Check if `shockperiod` is a variable or a number
    capture confirm variable `shockperiod'
    if _rc == 0 {
        local is_var = 1
    }
    else {
        local is_var = 0
    }
    
    * Make sure no variable needed are already in the sample  
    cap drop DiD* 
    cap drop *B* SE* TIME
    
    * Create coefficients
    if `is_var' {
        * If shocktime is a variable
        gen DiD0 = (`t' < `shocktime' - `before') * (`treated' == 1)
        
        local T = `before' + `after' + 1
        forvalues time_evstudy = 1(1)`T' {
            if `time_evstudy' != `before' + 1 {
                qui gen DiD`time_evstudy' = (`t' == `shocktime' + `time_evstudy' - `before' - 1) * (`treated')
            }
        }
        
        gen DiDpost = (`t' > `shocktime' + `after') * (`treated')
    }
    else {
        * If shocktime is a number
        local shockperiod_val = real("`shocktime'")
        gen DiD0 = (`t' < `shockperiod_val' - `before') * (`treated')
        
        local T = `before' + `after' + 1
        forvalues time_evstudy = 1(1)`T' {
            if `time_evstudy' != `before' + 1 {
                qui gen DiD`time_evstudy' = (`t' == `shockperiod_val' + `time_evstudy' - `before' - 1) * (`treated')
            }
        }
        
        gen DiDpost = (`t' > `shockperiod_val' + `after') * (`treated')
    }
    
    * Estimate event study 
    if "`estimator'" == "" | "`estimator'" == "reghdfe" | "`estimator'" == "ols" {
        * if weight is specified
        if "`weight'" != "" {
            if "`controls'" != "" {
                reghdfe `Y' DiD* `controls' [aw = `weight'], a(`fe') vce(cluster `cluster') noconst
            }
            else {
                reghdfe `Y' DiD* [aw = `weight'], a(`fe') vce(cluster `cluster') noconst
            }
        }
        * if weight is not specified
        if "`weight'" == "" {
            if "`controls'" != "" {
                reghdfe `Y' DiD* `controls', a(`fe') vce(cluster `cluster') noconst
            }
            else {
                reghdfe `Y' DiD*, a(`fe') vce(cluster `cluster') noconst
            }
        }
    }
    
    if "`estimator'" == "ppmlhdfe" | "`estimator'" == "poisson" {
        * Poisson estimators do not allow analytical weights
        if "`weight'" != "" {	
            display in red "Poisson estimators do not allow analytical weights"
            exit 198
        }
        * if weight is not specified
        if "`weight'" == "" {	
            if "`controls'" != "" {
                ppmlhdfe `Y' DiD* `controls', a(`fe') vce(cluster `cluster')
            }
            else {
                ppmlhdfe `Y' DiD*, a(`fe') vce(cluster `cluster')
            }
        }
    }
    
    * Save the coeffs and standard errors
    * Start at -k -1
    qui gen TIME 	= -`before' - 1 			if _n == 1
    qui gen B 		= _b[DiD0] 					if _n == 1
    qui gen SE 		= _se[DiD0] 				if _n == 1
    
    * Values from -k to k 
    forvalues time_evstudy = 1(1)`T' {
        if `time_evstudy' != `before' + 1 {
            qui replace TIME 	= `time_evstudy' - `before' - 1 	if _n == `time_evstudy' + 1
            qui replace B 		= _b[DiD`time_evstudy'] 			if _n == `time_evstudy' + 1
            qui replace SE 		= _se[DiD`time_evstudy'] 			if _n == `time_evstudy' + 1
        }
    }
    
    * Ref year not estimated 
    qui replace TIME 	= 0 			if _n == `before' + 2
    qui replace B 		= 0 			if _n == `before' + 2
    qui replace SE 		= 0 			if _n == `before' + 2

    * Adjust k+1 onward 
    qui replace TIME 	= `after' + 1 	if _n == `T' + 2
    qui replace B 		= _b[DiDpost] 	if _n == `T' + 2
    qui replace SE 		= _se[DiDpost] 	if _n == `T' + 2
    
	quiet drop DiD*
    preserve
        keep TIME B* SE*
        keep if TIME < .
		rename TIME time 
        
        * Ensure the specified name includes the full path and filename
        local filepath `"`name'"'
        
        * Check if the .dta extension is included, if not, add it
        if strpos("`filepath'", ".dta") == 0 {
            local filepath = "`filepath'.dta"
        }
        
        * Set up file write using the specified path and filename
        save "`filepath'", replace
    restore

end

}
