*! kmtest_power.ado - Power analysis for Kobayashi-McAleer tests
*! Version 1.0.0  23jan2026
*! Implementation by Dr. Merwan Roudane

program define kmtest_power, rclass
    version 14.0
    
    syntax , [Reps(integer 1000) N(integer 100) Y0(real 1) ///
              MU(real 0.01) SIGMA(real 0.01) AR1(real 0) ///
              NODrift SEed(integer 12345) Level(cilevel)]
    
    set seed `seed'
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:Power Analysis for Kobayashi-McAleer Tests}"
    di as text "{hline 70}"
    di as text ""
    di as text "Simulation Parameters:"
    di as text "  Replications:    " as result "`reps'"
    di as text "  Sample size:     " as result "`n'"
    di as text "  Initial value:   " as result %6.4f `y0'
    di as text "  Drift:           " as result %6.4f `mu'
    di as text "  Std. deviation:  " as result %6.4f `sigma'
    di as text "  AR(1) coef:      " as result %6.4f `ar1'
    di as text "  Significance:    " as result "`level'%"
    di as text ""
    
    * Critical values
    if "`nodrift'" == "" {
        local cv = invnormal(1 - (100-`level')/200)
    }
    else {
        if `level' >= 99 {
            local cv = 1.116
        }
        else if `level' >= 95 {
            local cv = 0.664
        }
        else {
            local cv = 0.477
        }
    }
    
    * Initialize counters
    local v1_reject = 0
    local v2_reject = 0
    local lm_reject = 0
    
    di as text "Running power simulation..."
    di as text ""
    
    * Run simulations
    preserve
    
    forvalues i = 1/`reps' {
        if mod(`i', 100) == 0 {
            di as text "  Iteration `i' of `reps'"
        }
        
        * Clear and generate data
        qui clear
        qui set obs `n'
        qui gen _t = _n
        qui tsset _t
        
        * Generate linear I(1) process (TRUE DGP)
        tempvar eps e y
        qui gen double `eps' = rnormal(0, `sigma')
        qui gen double `e' = `eps' if _n == 1
        qui replace `e' = `ar1' * L.`e' + `eps' if _n > 1
        
        if "`nodrift'" == "" {
            qui gen double `y' = `y0' if _n == 1
            qui replace `y' = L.`y' + `e' + `mu' if _n > 1
        }
        else {
            qui gen double `y' = `y0' if _n == 1
            qui replace `y' = L.`y' + `e' if _n > 1
        }
        
        * Run the test
        if "`nodrift'" == "" {
            qui _kmtest_withdrift `y'
            local v1 = r(V1)
            local v2 = r(V2)
        }
        else {
            qui _kmtest_nodrift `y'
            local v1 = r(U1)
            local v2 = r(U2)
        }
        
        * Count rejections (size for H0: linear, power for H0: log)
        if `v1' > `cv' {
            local v1_reject = `v1_reject' + 1
        }
        if `v2' > `cv' {
            local v2_reject = `v2_reject' + 1
        }
        
        * LM test for ARCH
        tempvar dy resid resid2 resid2_lag
        qui gen double `dy' = D.`y'
        qui reg `dy'
        qui predict double `resid', resid
        qui gen double `resid2' = `resid'^2
        qui gen double `resid2_lag' = L.`resid2'
        qui reg `resid2' `resid2_lag'
        local lm = e(N) * e(r2)
        if `lm' > invchi2(1, `level'/100) {
            local lm_reject = `lm_reject' + 1
        }
    }
    
    restore
    
    * Calculate rejection rates
    local v1_rate = `v1_reject' / `reps' * 100
    local v2_rate = `v2_reject' / `reps' * 100
    local lm_rate = `lm_reject' / `reps' * 100
    
    * Display results
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:Results (True DGP: Linear I(1) Process)}"
    di as text "{hline 70}"
    di as text ""
    
    if "`nodrift'" == "" {
        di as text "{bf:Test}{col 25}{bf:Rejection Rate}{col 45}{bf:Interpretation}"
        di as text "{hline 70}"
        di as text "V1 (H0: Linear)" ///
           as result "{col 25}" %6.2f `v1_rate' "%" ///
           as text "{col 45}Empirical Size"
        di as text "V2 (H0: Log)" ///
           as result "{col 25}" %6.2f `v2_rate' "%" ///
           as text "{col 45}Empirical Power"
        di as text "LM(ARCH)" ///
           as result "{col 25}" %6.2f `lm_rate' "%" ///
           as text "{col 45}Reference Test"
    }
    else {
        di as text "{bf:Test}{col 25}{bf:Rejection Rate}{col 45}{bf:Interpretation}"
        di as text "{hline 70}"
        di as text "U1 (H0: Linear)" ///
           as result "{col 25}" %6.2f `v1_rate' "%" ///
           as text "{col 45}Empirical Size"
        di as text "U2 (H0: Log)" ///
           as result "{col 25}" %6.2f `v2_rate' "%" ///
           as text "{col 45}Empirical Power"
        di as text "LM(ARCH)" ///
           as result "{col 25}" %6.2f `lm_rate' "%" ///
           as text "{col 45}Reference Test"
    }
    
    di as text "{hline 70}"
    di as text ""
    di as text "Note: Under the true linear DGP:"
    di as text "  - V1/U1 rejection rate should be close to " as result "`=100-`level''%"
    di as text "    (nominal size)"
    di as text "  - V2/U2 rejection rate measures power against the log alternative"
    di as text ""
    
    * Return results
    return scalar v1_size = `v1_rate'
    return scalar v2_power = `v2_rate'
    return scalar lm_power = `lm_rate'
    return scalar reps = `reps'
    return scalar n = `n'
    return scalar level = `level'
    
end
