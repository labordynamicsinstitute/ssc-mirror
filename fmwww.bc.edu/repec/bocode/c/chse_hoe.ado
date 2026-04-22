*! chse_hoe v1.0.2  18apr2025  Nityahapani
*! Estimate HOE statistics from observed h(t) series

program define chse_hoe, rclass
    version 14.0
    syntax varname(numeric) [if] [in] , ///
        [BURNin(integer 0) WINdows(integer 4) ///
         ALPHAr(real 0.3) TOL(real 0.05)]

    marksample touse

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

    preserve
    quietly keep if `touse'
    quietly replace `varlist' = min(1, max(0, `varlist'))
    quietly keep if _n > `burnin'
    local N_use = _N

    // --- turnover frequency ---
    quietly {
        tempvar above lag_above flip
        gen byte `above'     = (`varlist' > 0.5)
        gen byte `lag_above' = `above'[_n-1]
        gen byte `flip'      = abs(`above' - `lag_above') if _n > 1
        summarize `flip', meanonly
        local n_flips = r(sum)
    }
    local tau_hat = `n_flips' / max(`N_use' - 1, 1)

    // --- mean and variance ---
    quietly summarize `varlist'
    local mean_h = r(mean)
    local var_h  = r(Var)
    local min_h  = r(min)
    local max_h  = r(max)
    quietly count if `varlist' > 0.5
    local frac_above = r(N) / `N_use'

    // --- cascade proxy ---
    local rho_K       = min(0.99, abs(`mean_h' - 0.5) * 1.2)
    local exp_cascade = cond(`rho_K' < 1, `alphar'/(1-`rho_K'), .)

    // --- stationarity: compare window means ---
    local ws = floor(`N_use' / `windows')
    local max_diff 0
    forvalues w = 1/`windows' {
        local lo = (`w'-1)*`ws' + 1
        local hi = `w'*`ws'
        quietly summarize `varlist' if _n >= `lo' & _n <= `hi', meanonly
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

    di as text _newline "HOE Statistics — `varlist' (n=`N_use' post burn-in)"
    di as text "{hline 48}"
    di as text "  tau_hat          : " as result %8.4f `tau_hat'
    di as text "  Var(h)           : " as result %8.4f `var_h'
    di as text "  E[h]             : " as result %8.4f `mean_h'
    di as text "  h range          : [" as result %6.4f `min_h' ///
        as text ", " as result %6.4f `max_h' as text "]"
    di as text "  Frac h > 0.5     : " as result %8.4f `frac_above'
    di as text "  rho(K) proxy     : " as result %8.4f `rho_K'
    if `rho_K' < 1 {
        di as text "  E[cascade size]  : " as result %8.4f `exp_cascade'
    }
    else {
        di as text "  E[cascade size]  : " as result "inf"
    }
    di as text "{hline 48}"

    local wstr ""
    forvalues w = 1/`windows' {
        local wval : display %6.4f `wmean`w''
        local wstr "`wstr'  `wval'"
    }
    di as text "  Window means: " as result "`wstr'"
    di as text "  Max diff: " as result %6.4f `max_diff' ///
        as text "   Converged: " as result cond(`converged', "YES", "NO")
    di as text "{hline 48}"

    return scalar tau_hat       = `tau_hat'
    return scalar var_h         = `var_h'
    return scalar mean_h        = `mean_h'
    return scalar min_h         = `min_h'
    return scalar max_h         = `max_h'
    return scalar frac_above    = `frac_above'
    return scalar n_flips       = `n_flips'
    return scalar N_post_burnin = `N_use'
    return scalar rho_K_proxy   = `rho_K'
    return scalar exp_cascade   = `exp_cascade'
    return scalar max_win_diff  = `max_diff'
    return scalar converged     = `converged'
    return scalar burnin        = `burnin'
end
