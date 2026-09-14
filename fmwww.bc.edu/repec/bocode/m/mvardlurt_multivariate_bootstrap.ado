*! mvardlurt_multivariate_bootstrap - Bootstrap subroutine
*! Version 1.0.0 - 2026-09-09
*! Author: YUSUF TOYIN YUSUF
*! Email: YUSUF.YUSUF@KWASU.EDU.NG

capture program drop mvardlurt_multivariate_bootstrap
program define mvardlurt_multivariate_bootstrap, rclass
    version 14
    
    syntax, depvar(string) indepvars(string) [plag(integer 0) qlags(string) case(integer 3) reps(integer 1000) seed(integer 12345)]
    
    * Set seed
    set seed `seed'
    
    * Get number of independent variables
    local num_indep : list sizeof indepvars
    
    * Parse qlags
    local qlist `qlags'
    
    * Store original data
    preserve
    
    * Generate differenced series
    tempvar dy
    qui gen double `dy' = D.`depvar'
    
    * Store variables in locals for bootstrap
    local depvar_orig `depvar'
    local indepvars_orig `indepvars'
    local plag_orig `plag'
    local qlist_orig `qlist'
    local case_orig `case'
    
    * Get sample size
    qui count
    local T = r(N)
    
    * Create storage for bootstrap statistics
    tempname tstats fstats
    mat `tstats' = J(`reps', 1, 0)
    mat `fstats' = J(`reps', 1, 0)
    
    * Display progress
    di as txt _col(3) "Bootstrap in progress:"
    
    * Bootstrap loop
    forvalues r = 1/`reps' {
        
        * Display progress every 100 replications
        if mod(`r', 100) == 0 {
            di as txt _col(3) "  Replication " as res "`r'" as txt " of " as res "`reps'"
        }
        
        * Step 1: Generate bootstrap errors
        tempvar e_boot
        qui gen double `e_boot' = rnormal(0, 1) in 1/`T'
        
        * Step 2: Generate bootstrap y with unit root
        tempvar y_boot
        qui gen double `y_boot' = 0 in 1
        forvalues t = 2/`T' {
            qui replace `y_boot' = `y_boot'[_n-1] + `e_boot' in `t'
        }
        
        * Step 3: Generate bootstrap x's (keep original or generate)
        tempvar x_boot
        foreach var in `indepvars_orig' {
            qui gen double `x_boot' = `var' in 1/`T'
        }
        
        * Step 4: Build regressor list for bootstrap
        local boot_regvars "L.`y_boot'"
        
        * Add lagged levels of all independent variables
        foreach var in `indepvars_orig' {
            local boot_regvars "`boot_regvars' L.`var'"
        }
        
        * Add lagged differences of dependent
        if `plag_orig' > 0 {
            forvalues j = 1/`plag_orig' {
                local boot_regvars "`boot_regvars' L`j'.D.`y_boot'"
            }
        }
        
        * Add lagged differences of each independent
        local count = 1
        foreach var in `indepvars_orig' {
            local q_val : word `count' of `qlist_orig'
            if `q_val' > 0 {
                forvalues j = 1/`q_val' {
                    local boot_regvars "`boot_regvars' L`j'.D.`var'"
                }
            }
            local count = `count' + 1
        }
        
        * Add deterministics
        local det_regs_final ""
        if `case_orig' == 5 {
            tempvar ttrend
            qui gen `ttrend' = _n
            local det_regs_final "`ttrend'"
        }
        if "`det_regs_final'" != "" {
            local boot_regvars "`boot_regvars' `det_regs_final'"
        }
        
        * Estimate bootstrap model
        if `case_orig' == 1 {
            capture qui regress D.`y_boot' `boot_regvars', noconstant
        }
        else {
            capture qui regress D.`y_boot' `boot_regvars'
        }
        
        * Store statistics if estimation converged
        if _rc == 0 & e(N) > 15 {
            * t-statistic on lagged y
            local boot_t = _b[L.`y_boot'] / _se[L.`y_boot']
            mat `tstats'[`r',1] = `boot_t'
            
            * F-statistic on all lagged independent variables
            local test_list ""
            foreach var in `indepvars_orig' {
                local test_list "`test_list' L.`var'"
            }
            if "`test_list'" != "" {
                qui test `test_list'
                local boot_f = r(F)
                mat `fstats'[`r',1] = `boot_f'
            }
        }
    }
    
    * Calculate critical values
    local t_cv10 = .
    local t_cv05 = .
    local t_cv025 = .
    local t_cv01 = .
    local f_cv10 = .
    local f_cv05 = .
    local f_cv025 = .
    local f_cv01 = .
    
    * Extract t-statistics
    tempname tvec
    mat `tvec' = `tstats'
    
    * Sort t-statistics
    mata: st_matrix("t_sorted", sort(st_matrix("tstats"), 1))
    
    * Get quantiles
    local t_sorted = `t_sorted'
    
    * Simple quantile function (approximate)
    local t_cv10 = `t_sorted'[ceil(`reps'*0.10),1]
    local t_cv05 = `t_sorted'[ceil(`reps'*0.05),1]
    local t_cv025 = `t_sorted'[ceil(`reps'*0.025),1]
    local t_cv01 = `t_sorted'[ceil(`reps'*0.01),1]
    
    * Extract F-statistics
    tempname fvec
    mat `fvec' = `fstats'
    mata: st_matrix("f_sorted", sort(st_matrix("fstats"), 1))
    
    * Get quantiles
    local f_sorted = `f_sorted'
    local f_cv10 = `f_sorted'[ceil(`reps'*0.90),1]
    local f_cv05 = `f_sorted'[ceil(`reps'*0.95),1]
    local f_cv025 = `f_sorted'[ceil(`reps'*0.975),1]
    local f_cv01 = `f_sorted'[ceil(`reps'*0.99),1]
    
    * Restore original data
    restore
    
    * Return results
    return scalar t_cv10 = `t_cv10'
    return scalar t_cv05 = `t_cv05'
    return scalar t_cv025 = `t_cv025'
    return scalar t_cv01 = `t_cv01'
    return scalar f_cv10 = `f_cv10'
    return scalar f_cv05 = `f_cv05'
    return scalar f_cv025 = `f_cv025'
    return scalar f_cv01 = `f_cv01'
    
    di as txt ""
    di as txt _col(3) "Bootstrap complete."
    di as txt ""
end