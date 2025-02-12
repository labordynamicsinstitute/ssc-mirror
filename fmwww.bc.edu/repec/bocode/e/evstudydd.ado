*! evstudydd: estimate event studies in D-i-D settings using the reghdfe or ppmlhdfe packages
*! It requires reghdfe and ppmlhdfe to be installed.
*! Version: February, 2025
*! Authors: Adrien Matray, Pablo E. Rodriguez

qui{

cap program drop evstudydd
program define evstudydd
version 13.0
    syntax varlist(numeric min=2 max=2) [if] [in], Treated(name) SHOCKTime(string) Period(string) CLuster(string) FE(string) Name(string) [Weight(name)] [CONTrols(string)] ///
    [Estimator(string)] [INTeraction(varname)]
    
    * Add top-level preserve motivated by the creation of new variables and to avoid erasing already existing variables 
    preserve

    * Temporarily capture variables from varlist
    tokenize `varlist'
    local Y `1'
    local t `2'
    
    * Validate options
    if "`treated'" == "" {
        di as err "You must specify a treated variable"
        exit 198
    }
    if "`shocktime'" == "" {
        di as err "You must specify the variable or numeric value for the time of the shock"
        exit 198
    }
    if "`period'" == "" {
        di as err "You must specify the period option in the format lower_bound upper_bound"
        exit 198
    }
    if "`name'" == "" {
        di as err "You must specify the name option to store .dta dataset"
        exit 198
    }
    
    * Parse the period option
    tokenize `period'
    local before `1'
    local after `2'
    
    * Check if `shockperiod` is a variable or a number
    capture confirm variable `shocktime'
    if _rc == 0 {
        local is_var = 1
    }
    else {
        local is_var = 0
    }
    
    * Make sure no DiD_evstudydd variables are in the sample
    cap drop DiD_evstudydd* 
    
    * Create coefficients
    if `is_var' {
        * If shocktime is a variable
        gen DiD_evstudydd0 = (`t' < `shocktime' - `before') * (`treated' == 1)
        if "`interaction'" != "" {
            gen DiD_evstudydd0_int = DiD_evstudydd0 * `interaction'
        }
        
        local T = `before' + `after' + 1
        forvalues time_evstudy = 1(1)`T' {
            if `time_evstudy' != `before' + 1 {
                qui gen DiD_evstudydd`time_evstudy' = (`t' == `shocktime' + `time_evstudy' - `before' - 1) * (`treated')
                if "`interaction'" != "" {
                    qui gen DiD_evstudydd`time_evstudy'_int = DiD_evstudydd`time_evstudy' * `interaction'
                }
            }
        }
        
        gen DiD_evstudyddpost = (`t' > `shocktime' + `after') * (`treated')
        if "`interaction'" != "" {
            gen DiD_evstudyddpost_int = DiD_evstudyddpost * `interaction'
        }
    }
    else {
        * If shocktime is a number
        local shockperiod_val = real("`shocktime'")
        gen DiD_evstudydd0 = (`t' < `shockperiod_val' - `before') * (`treated')
        if "`interaction'" != "" {
            gen DiD_evstudydd0_int = DiD_evstudydd0 * `interaction'
        }
        
        local T = `before' + `after' + 1
        forvalues time_evstudy = 1(1)`T' {
            if `time_evstudy' != `before' + 1 {
                qui gen DiD_evstudydd`time_evstudy' = (`t' == `shockperiod_val' + `time_evstudy' - `before' - 1) * (`treated')
                if "`interaction'" != "" {
                    qui gen DiD_evstudydd`time_evstudy'_int = DiD_evstudydd`time_evstudy' * `interaction'
                }
            }
        }
        
        gen DiD_evstudyddpost = (`t' > `shockperiod_val' + `after') * (`treated')
        if "`interaction'" != "" {
            gen DiD_evstudyddpost_int = DiD_evstudyddpost * `interaction'
        }
    }
    
    * Generate temporary variables for storing results
    tempvar B_temp SE_temp TIME_temp B_int_temp SE_int_temp
    
    * Estimate event study 
    if "`estimator'" == "" | "`estimator'" == "reghdfe" | "`estimator'" == "ols" {
        * if weight is specified
        if "`weight'" != "" {
            if "`controls'" != "" {
                reghdfe `Y' DiD_evstudydd* `controls' [aw = `weight'], a(`fe') vce(cluster `cluster') noconst
            }
            else {
                reghdfe `Y' DiD_evstudydd* [aw = `weight'], a(`fe') vce(cluster `cluster') noconst
            }
        }
        * if weight is not specified
        if "`weight'" == "" {
            if "`controls'" != "" {
                reghdfe `Y' DiD_evstudydd* `controls', a(`fe') vce(cluster `cluster') noconst
            }
            else {
                reghdfe `Y' DiD_evstudydd*, a(`fe') vce(cluster `cluster') noconst
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
                ppmlhdfe `Y' DiD_evstudydd* `controls', a(`fe') vce(cluster `cluster')
            }
            else {
                ppmlhdfe `Y' DiD_evstudydd*, a(`fe') vce(cluster `cluster')
            }
        }
    }
    
    * Create dataset of results
    qui gen double `TIME_temp' = -`before' - 1 if _n == 1
    
    if "`interaction'" != "" {
        * For cases with interaction, store both base and interaction coefficients
        qui gen double `B_temp' = _b[DiD_evstudydd0] if _n == 1
        qui gen double `SE_temp' = _se[DiD_evstudydd0] if _n == 1
        qui gen double `B_int_temp' = _b[DiD_evstudydd0_int] if _n == 1
        qui gen double `SE_int_temp' = _se[DiD_evstudydd0_int] if _n == 1
    
        * Values from -k to k 
        forvalues time_evstudy = 1(1)`T' {
            if `time_evstudy' != `before' + 1 {
                qui replace `TIME_temp' = `time_evstudy' - `before' - 1 if _n == `time_evstudy' + 1
                qui replace `B_temp' = _b[DiD_evstudydd`time_evstudy'] if _n == `time_evstudy' + 1
                qui replace `SE_temp' = _se[DiD_evstudydd`time_evstudy'] if _n == `time_evstudy' + 1
                qui replace `B_int_temp' = _b[DiD_evstudydd`time_evstudy'_int] if _n == `time_evstudy' + 1
                qui replace `SE_int_temp' = _se[DiD_evstudydd`time_evstudy'_int] if _n == `time_evstudy' + 1
            }
        }
    
        * Ref year not estimated 
        qui replace `TIME_temp' = 0 if _n == `before' + 2
        qui replace `B_temp' = 0 if _n == `before' + 2
        qui replace `SE_temp' = 0 if _n == `before' + 2
        qui replace `B_int_temp' = 0 if _n == `before' + 2
        qui replace `SE_int_temp' = 0 if _n == `before' + 2
    
        * Adjust k+1 onward 
        qui replace `TIME_temp' = `after' + 1 if _n == `T' + 2
        qui replace `B_temp' = _b[DiD_evstudyddpost] if _n == `T' + 2
        qui replace `SE_temp' = _se[DiD_evstudyddpost] if _n == `T' + 2
        qui replace `B_int_temp' = _b[DiD_evstudyddpost_int] if _n == `T' + 2
        qui replace `SE_int_temp' = _se[DiD_evstudyddpost_int] if _n == `T' + 2
    }
    else {
        * For cases without interaction
        qui gen double `B_temp' = _b[DiD_evstudydd0] if _n == 1
        qui gen double `SE_temp' = _se[DiD_evstudydd0] if _n == 1
    
        * Values from -k to k 
        forvalues time_evstudy = 1(1)`T' {
            if `time_evstudy' != `before' + 1 {
                qui replace `TIME_temp' = `time_evstudy' - `before' - 1 if _n == `time_evstudy' + 1
                qui replace `B_temp' = _b[DiD_evstudydd`time_evstudy'] if _n == `time_evstudy' + 1
                qui replace `SE_temp' = _se[DiD_evstudydd`time_evstudy'] if _n == `time_evstudy' + 1
            }
        }
    
        * Ref year not estimated 
        qui replace `TIME_temp' = 0 if _n == `before' + 2
        qui replace `B_temp' = 0 if _n == `before' + 2
        qui replace `SE_temp' = 0 if _n == `before' + 2
    
        * Adjust k+1 onward 
        qui replace `TIME_temp' = `after' + 1 if _n == `T' + 2
        qui replace `B_temp' = _b[DiD_evstudyddpost] if _n == `T' + 2
        qui replace `SE_temp' = _se[DiD_evstudyddpost] if _n == `T' + 2
    }
    
    * Keep only necessary variables and save
    if "`interaction'" != "" {
        keep `TIME_temp' `B_temp' `SE_temp' `B_int_temp' `SE_int_temp'
        keep if `TIME_temp' < .
        rename `TIME_temp' time
        rename `B_temp' B
        rename `SE_temp' SE
        rename `B_int_temp' B_int
        rename `SE_int_temp' SE_int
    }
    else {
        keep `TIME_temp' `B_temp' `SE_temp'
        keep if `TIME_temp' < .
        rename `TIME_temp' time
        rename `B_temp' B
        rename `SE_temp' SE
    }
    
    save "`name'", replace
    
    * Restore user dataset     
    restore

end

}
