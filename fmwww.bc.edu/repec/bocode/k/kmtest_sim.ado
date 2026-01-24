*! kmtest_sim.ado - Simulate integrated processes for testing kmtest
*! Version 1.0.0  23jan2026
*! Implementation by Dr. Merwan Roudane

program define kmtest_sim
    version 14.0
    
    syntax newvarname, [N(integer 100) Y0(real 1) MU(real 0.01) ///
           SIGMA(real 0.01) AR1(real 0) LOG SEed(integer 0) REPLACE]
    
    * Handle variable replacement
    capture confirm variable `varlist'
    if _rc == 0 {
        if "`replace'" == "" {
            di as error "Variable `varlist' already exists. Use replace option."
            exit 110
        }
        qui drop `varlist'
    }
    
    * Set seed if specified
    if `seed' != 0 {
        set seed `seed'
    }
    
    * Check initial value
    if `y0' <= 0 {
        di as error "Initial value y0 must be positive."
        exit 411
    }
    
    * Check AR coefficient
    if abs(`ar1') >= 1 {
        di as error "AR(1) coefficient must be less than 1 in absolute value."
        exit 198
    }
    
    * Set up observations
    local current_n = _N
    if `current_n' < `n' {
        qui set obs `n'
    }
    
    * Generate time variable if not already set
    capture tsset
    if _rc != 0 {
        qui gen _t = _n
        qui tsset _t
    }
    
    * Display header
    di as text ""
    di as text "{hline 60}"
    di as text "{bf:Simulating Integrated Process}"
    di as text "{hline 60}"
    
    if "`log'" == "" {
        di as text "Model: Linear I(1)"
        di as text "       y_t - y_{t-1} = e_t + mu"
        di as text "       e_t = ar1 * e_{t-1} + epsilon_t"
    }
    else {
        di as text "Model: Logarithmic I(1)"
        di as text "       log(y_t) - log(y_{t-1}) = u_t + eta"
        di as text "       u_t = ar1 * u_{t-1} + zeta_t"
    }
    
    di as text ""
    di as text "Parameters:"
    di as text "  n (observations):  " as result "`n'"
    di as text "  y0 (initial):      " as result %6.4f `y0'
    if "`log'" == "" {
        di as text "  mu (drift):        " as result %6.4f `mu'
        di as text "  sigma (std.dev):   " as result %6.4f `sigma'
    }
    else {
        di as text "  eta (drift):       " as result %6.4f `mu'
        di as text "  omega (std.dev):   " as result %6.4f `sigma'
    }
    di as text "  ar1 (AR coef):     " as result %6.4f `ar1'
    di as text ""
    
    * Generate innovations
    tempvar eps e
    qui gen double `eps' = rnormal(0, `sigma') if _n <= `n'
    
    * Generate AR(1) process for e_t
    qui gen double `e' = `eps' if _n == 1
    qui replace `e' = `ar1' * L.`e' + `eps' if _n > 1 & _n <= `n'
    
    if "`log'" == "" {
        * Linear model: y_t = y_{t-1} + e_t + mu
        qui gen double `varlist' = `y0' if _n == 1
        qui replace `varlist' = L.`varlist' + `e' + `mu' if _n > 1 & _n <= `n'
    }
    else {
        * Logarithmic model: log(y_t) = log(y_{t-1}) + u_t + eta
        tempvar logy
        qui gen double `logy' = ln(`y0') if _n == 1
        qui replace `logy' = L.`logy' + `e' + `mu' if _n > 1 & _n <= `n'
        qui gen double `varlist' = exp(`logy') if _n <= `n'
    }
    
    * Summary of generated data
    qui sum `varlist' if _n <= `n'
    di as text "{hline 60}"
    di as text "{bf:Generated Variable: `varlist'}"
    di as text "{hline 60}"
    di as text "  Observations:  " as result r(N)
    di as text "  Mean:          " as result %12.4f r(mean)
    di as text "  Std. Dev:      " as result %12.4f r(sd)
    di as text "  Min:           " as result %12.4f r(min)
    di as text "  Max:           " as result %12.4f r(max)
    di as text "{hline 60}"
    di as text ""
    
end
