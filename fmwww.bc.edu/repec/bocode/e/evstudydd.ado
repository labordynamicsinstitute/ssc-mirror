
*! Version: June, 2024
*! Authors: Adrien Matray, Pablo E. Rodriguez
/*
This program requires at least Stata 13. It also requires reghdfe to be installed 
*/

qui{

capture program drop evstudydd
program define evstudydd
version 13.0
    syntax varlist(numeric min=1 max=1) [if] [in], Treated(name) SHOCKYear(string) CLuster(string) [Weight(name)] FE(string) [Name(string)] Period(string)

    * Temporarily capture variables from varlist
    tokenize `varlist'
    local Y `1'
    
    * Validate treated var defined
    if "`treated'" == "" {
        di as err "You must specify a treated variable (must be a dummy [0-1])"
        exit 198
    }
    * Validate ref year defined
    if "`shockyear'" == "" {
        di as err "You must specify the variable or numeric value for the year of the shock (also used as the ref. year for event study)"
        exit 198
    }

    * Validate period option defined
    if "`period'" == "" {
        di as err "You must specify the period option in the format lower_bound upper_bound"
        exit 198
    }

    * Parse the period option
    tokenize `period'
    local before `1'
    local after `2'
    
    * Check if `shockyear` is a variable or a number
    capture confirm variable `shockyear'
    if _rc == 0 {
        local is_var = 1
    }
    else {
        local is_var = 0
    }
    
    * Make sure no variable needed are already in the sample  
    cap drop DiD* 
    cap drop *B* SE* time
    
    * Create coefficients
    if `is_var' {
        * If shockyear is a variable
        gen DiD0 = (year < `shockyear' - `before') * (`treated' == 1)
        
        local T = `before' + `after' + 1
        forvalues time_evstudy = 1(1)`T' {
            if `time_evstudy' != `before' + 1 {
                qui gen DiD`time_evstudy' = (year == `shockyear' + `time_evstudy' - `before' - 1) * (`treated')
            }
        }
        
        gen DiDpost = (year > `shockyear' + `after') * (`treated')
    }
    else {
        * If shockyear is a number
        local shockyear_val = real("`shockyear'")
        gen DiD0 = (year < `shockyear_val' - `before') * (`treated')
        
        local T = `before' + `after' + 1
        forvalues time_evstudy = 1(1)`T' {
            if `time_evstudy' != `before' + 1 {
                qui gen DiD`time_evstudy' = (year == `shockyear_val' + `time_evstudy' - `before' - 1) * (`treated')
            }
        }
        
        gen DiDpost = (year > `shockyear_val' + `after') * (`treated')
    }
    
    * Estimate event study 
    * if weight is specified
    if "`weight'" != "" {
        reghdfe `Y' DiD* [aw = `weight'] ,a(`fe') vce(cluster `cluster') noconst
    }
    * if weight is not specified
    if "`weight'" == "" {
        reghdfe `Y' DiD* ,a(`fe') vce(cluster `cluster') noconst
    }
    
    * Save the coeffs and standard errors
    * Start at -k -1
    qui gen time = -`before' - 1 			if _n == 1
    qui gen B = _b[DiD0] 					if _n == 1
    qui gen SE = _se[DiD0] 					if _n == 1
    
    * Values from -k to k 
    forvalues t = 1(1)`T' {
        if `t' != `before' + 1 {
            qui replace time = `t' - `before' - 1 	if _n == `t' + 1
            qui replace B = _b[DiD`t'] 				if _n == `t' + 1
            qui replace SE = _se[DiD`t'] 			if _n == `t' + 1
        }
    }
    
    * Ref year not estimated 
    qui replace time = 0 			if _n == `before' + 2
    qui replace B = 0 				if _n == `before' + 2
    qui replace SE = 0 				if _n == `before' + 2

    * Adjust k+1 onward 
    qui replace time = `after' + 1 	if _n == `T' + 2
    qui replace B = _b[DiDpost] 	if _n == `T' + 2
    qui replace SE = _se[DiDpost] 	if _n == `T' + 2
    
	quiet drop DiD*
    preserve
        keep time B* SE*
        keep if time < .
        
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
