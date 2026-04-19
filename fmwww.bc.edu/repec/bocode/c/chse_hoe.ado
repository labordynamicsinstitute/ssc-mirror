*! chse_hoe — Estimate Hierarchy Orbit Equilibrium statistics
*! Version 1.0.0   April 2025
*! Author: Nityahapani
*!
*! Estimates HOE statistics from an observed h(t) time series:
*!   tau_hat   leadership turnover frequency (flips per period)
*!   var_h     variance of h in the stationary distribution
*!   mean_h    mean of h in the stationary distribution
*!
*! Definition 10.2: HOE ≡ π*(tau_hat, Var(h), E[cascade size])
*!
*! Stationarity is assessed by comparing window means across the
*! post-burn-in trajectory. A max window-mean difference below 0.05
*! is taken as convergence.
*!
*! Syntax:
*!   chse_hoe varname [if] [in], [burnin(integer) windows(integer)
*!                                alpha_r(real) tol(real)]

program define chse_hoe, rclass
    version 14.0
    
    syntax varname(numeric) [if] [in] , ///
        [BURNin(integer 0) WINdows(integer 4) ///
         ALpha_r(real 0.3) TOL(real 0.05)]
    
    marksample touse
    
    // ----------------------------------------------------------------
    // Extract h series
    // ----------------------------------------------------------------
    quietly count if `touse'
    local N = r(N)
    
    if `N' < 10 {
        di as error "Need at least 10 observations."
        exit 2001
    }
    
    if `burnin' >= `N' {
        di as error "burnin() must be less than the number of observations."
        exit 198
    }
    
    local N_post = `N' - `burnin'
    
    // Validate h in [0,1]
    quietly {
        tempvar h_ok
        gen byte `h_ok' = (`varlist' >= 0 & `varlist' <= 1) if `touse'
        summarize `h_ok' if `touse', meanonly
        if r(min) == 0 {
            di as error "Warning: some values of `varlist' are outside [0,1]. These will be clipped."
        }
    }
    
    // ----------------------------------------------------------------
    // Preserve and work on a clean sorted copy
    // ----------------------------------------------------------------
    preserve
    quietly keep if `touse'
    
    // Clip to [0,1]
    quietly replace `varlist' = min(1, max(0, `varlist'))
    
    // Drop burn-in
    quietly keep if _n > `burnin'
    local N_use = _N
    
    // ----------------------------------------------------------------
    // Turnover frequency tau_hat
    // ----------------------------------------------------------------
    quietly {
        tempvar above lag_above flip
        gen byte `above' = (`varlist' > 0.5)
        gen byte `lag_above' = `above'[_n-1]
        gen byte `flip' = abs(`above' - `lag_above') if _n > 1
        summarize `flip', meanonly
        local n_flips = r(sum)
    }
    local tau_hat = `n_flips' / max(`N_use' - 1, 1)
    
    // ----------------------------------------------------------------
    // Mean and variance of h
    // ----------------------------------------------------------------
    quietly summarize `varlist'
    local mean_h = r(mean)
    local var_h  = r(Var)
    local min_h  = r(min)
    local max_h  = r(max)
    local frac_above = .
    quietly {
        summarize `varlist' if `varlist' > 0.5, meanonly
        local n_above = r(N)
    }
    local frac_above = `n_above' / `N_use'
    
    // ----------------------------------------------------------------
    // Expected cascade size proxy: rho_K ≈ |mean(h) - 0.5| * 1.2
    // Capped at 0.99 to ensure finite cascade bound.
    // ----------------------------------------------------------------
    local h_dev = abs(`mean_h' - 0.5)
    local rho_K = min(0.99, `h_dev' * 1.2)
    if `rho_K' < 1 {
        local exp_cascade = `alpha_r' / (1 - `rho_K')
    }
    else {
        local exp_cascade = .
    }
    
    // ----------------------------------------------------------------
    // Stationarity test: compare window means
    // ----------------------------------------------------------------
    local ws = floor(`N_use' / `windows')
    local max_diff = 0
    forvalues w = 1/`windows' {
        local wlo = (`w'-1)*`ws' + 1
        local whi = `w'*`ws'
        quietly summarize `varlist' if _n >= `wlo' & _n <= `whi', meanonly
        local wmean`w' = r(mean)
    }
    forvalues w1 = 1/`windows' {
        forvalues w2 = 1/`windows' {
            if `w2' > `w1' {
                local d = abs(`wmean`w1'' - `wmean`w2'')
                if `d' > `max_diff' local max_diff = `d'
            }
        }
    }
    local converged = (`max_diff' < `tol')
    
    restore
    
    // ----------------------------------------------------------------
    // Display
    // ----------------------------------------------------------------
    di as text _newline "HOE Statistics — `varlist' (n=`N_use' post burn-in)"
    di as text "{hline 48}"
    di as text "  tau_hat (turnover/period)  : " ///
        as result %8.4f `tau_hat'
    di as text "  Var(h)                     : " ///
        as result %8.4f `var_h'
    di as text "  E[h]                       : " ///
        as result %8.4f `mean_h'
    di as text "  h range                    : [" ///
        as result %6.4f `min_h' as text ", " as result %6.4f `max_h' as text "]"
    di as text "  Fraction h > 0.5           : " ///
        as result %8.4f `frac_above'
    di as text "  rho(K) proxy               : " ///
        as result %8.4f `rho_K'
    if `rho_K' < 1 {
        di as text "  E[cascade size]            : " ///
            as result %8.4f `exp_cascade'
    }
    else {
        di as text "  E[cascade size]            : " ///
            as result "inf  (rho(K) >= 1)"
    }
    di as text "{hline 48}"
    
    // Window means
    di as text "  Stationarity test (`windows' windows):"
    local wstr ""
    forvalues w = 1/`windows' {
        local wstr "`wstr'  " + string(`wmean`w'', "%6.4f")
    }
    di as text "    Window means: " as result "`wstr'"
    di as text "    Max diff:     " as result %6.4f `max_diff' ///
        as text "   Converged: " as result cond(`converged',"YES","NO")
    di as text "{hline 48}"
    
    // ----------------------------------------------------------------
    // Return
    // ----------------------------------------------------------------
    return scalar tau_hat      = `tau_hat'
    return scalar var_h        = `var_h'
    return scalar mean_h       = `mean_h'
    return scalar min_h        = `min_h'
    return scalar max_h        = `max_h'
    return scalar frac_above   = `frac_above'
    return scalar n_flips      = `n_flips'
    return scalar N_post_burnin = `N_use'
    return scalar rho_K_proxy  = `rho_K'
    return scalar exp_cascade  = `exp_cascade'
    return scalar max_win_diff = `max_diff'
    return scalar converged    = `converged'
    return scalar burnin       = `burnin'
    
end
