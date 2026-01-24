*! kmtest_cv.ado - Monte Carlo simulation for critical values
*! Version 1.0.0  23jan2026
*! Implementation by Dr. Merwan Roudane

program define kmtest_cv, rclass
    version 14.0
    
    syntax , [Reps(integer 10000) N(integer 200) SEed(integer 12345) ///
              DETail SAVing(string)]
    
    * Set seed for reproducibility
    set seed `seed'
    
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:Monte Carlo Simulation for Kobayashi-McAleer Critical Values}"
    di as text "{hline 70}"
    di as text ""
    di as text "Replications: " as result "`reps'"
    di as text "Sample size:  " as result "`n'"
    di as text "Random seed:  " as result "`seed'"
    di as text ""
    
    * Store results
    tempname results
    matrix `results' = J(`reps', 1, .)
    
    * Simulate the distribution of the test statistic under H0
    * The distribution is: ∫W1(r)dW2(r) - ∫W1(r)dr * ∫dW2(r)
    * where W1 and W2 are independent standard Brownian motions
    
    di as text "Running simulation..."
    
    forvalues i = 1/`reps' {
        * Display progress
        if mod(`i', 1000) == 0 {
            di as text "  Iteration `i' of `reps'"
        }
        
        * Generate independent standard normal innovations
        tempvar e1 e2 w1 w2
        qui set obs `n'
        qui gen double `e1' = rnormal()
        qui gen double `e2' = rnormal()
        
        * Compute Brownian motion approximations (scaled random walks)
        qui gen double `w1' = sum(`e1') / sqrt(`n')
        qui gen double `w2' = sum(`e2') / sqrt(`n')
        
        * Compute the integrals
        * ∫W1(r)dW2(r) ≈ (1/n) * Σ W1_{t-1} * (W2_t - W2_{t-1})
        tempvar dw2 integrand1
        qui gen double `dw2' = `w2' - L.`w2'
        qui replace `dw2' = `w2'[1] if _n == 1
        qui gen double `integrand1' = L.`w1' * `dw2'
        qui replace `integrand1' = 0 if _n == 1
        qui sum `integrand1'
        local int1 = r(sum)
        
        * ∫W1(r)dr ≈ (1/n) * Σ W1_t
        qui sum `w1'
        local int2 = r(sum) / `n'
        
        * ∫dW2(r) = W2(1) - W2(0) = W2(n) (since W2(0)=0)
        qui sum `w2' if _n == `n'
        local int3 = r(mean)
        
        * Test statistic: ∫W1(r)dW2(r) - ∫W1(r)dr * ∫dW2(r)
        local stat = `int1' - `int2' * `int3'
        
        matrix `results'[`i', 1] = `stat'
        
        drop `e1' `e2' `w1' `w2' `dw2' `integrand1'
        qui drop if _n > 0
    }
    
    * Convert to Stata variable for percentile calculation
    qui set obs `reps'
    tempvar teststat
    qui gen double `teststat' = .
    forvalues i = 1/`reps' {
        qui replace `teststat' = `results'[`i', 1] in `i'
    }
    
    * Calculate critical values (upper tail)
    qui _pctile `teststat', p(90 95 99)
    local cv10 = r(r1)
    local cv05 = r(r2)
    local cv01 = r(r3)
    
    * Calculate summary statistics
    qui sum `teststat', detail
    local mean = r(mean)
    local sd = r(sd)
    local min = r(min)
    local max = r(max)
    local p50 = r(p50)
    
    * Display results
    di as text ""
    di as text "{hline 70}"
    di as text "{bf:Results}"
    di as text "{hline 70}"
    di as text ""
    di as text "{bf:Critical Values (Upper Tail):}"
    di as text ""
    di as text "  Significance Level     Critical Value"
    di as text "  {hline 40}"
    di as text "       10%              " as result %9.4f `cv10'
    di as text "        5%              " as result %9.4f `cv05'
    di as text "        1%              " as result %9.4f `cv01'
    di as text ""
    di as text "{bf:Distribution Summary:}"
    di as text ""
    di as text "  Mean:     " as result %9.4f `mean'
    di as text "  Std.Dev:  " as result %9.4f `sd'
    di as text "  Median:   " as result %9.4f `p50'
    di as text "  Min:      " as result %9.4f `min'
    di as text "  Max:      " as result %9.4f `max'
    di as text ""
    
    if "`detail'" != "" {
        di as text "{bf:Comparison with Kobayashi-McAleer (1999) Table 1:}"
        di as text ""
        di as text "  Level   Paper CV   Simulated CV   Difference"
        di as text "  {hline 50}"
        di as text "   10%     0.477      " as result %7.4f `cv10' ///
           as text "         " as result %7.4f (`cv10' - 0.477)
        di as text "    5%     0.664      " as result %7.4f `cv05' ///
           as text "         " as result %7.4f (`cv05' - 0.664)
        di as text "    1%     1.116      " as result %7.4f `cv01' ///
           as text "         " as result %7.4f (`cv01' - 1.116)
        di as text ""
    }
    
    * Save results if requested
    if "`saving'" != "" {
        preserve
        qui keep `teststat'
        qui rename `teststat' km_statistic
        qui save "`saving'", replace
        di as text "Simulation results saved to `saving'"
        restore
    }
    
    di as text "{hline 70}"
    di as text ""
    
    * Return results
    return scalar cv10 = `cv10'
    return scalar cv05 = `cv05'
    return scalar cv01 = `cv01'
    return scalar mean = `mean'
    return scalar sd = `sd'
    return scalar reps = `reps'
    return scalar n = `n'
    return scalar seed = `seed'
    
end
