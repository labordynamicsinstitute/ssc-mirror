*! _xtpc_display v1.1.0 — Generic display for xtpanelcoint results
*! Author: Dr. Merwan Roudane

program define _xtpc_display
    local est "`e(estimator)'"
    local depvar "`e(depvar)'"
    local indepvar "`e(indepvar)'"

    di
    di as txt "{hline 78}"
    di as txt "{bf:xtpanelcoint -- `est'}"
    di as txt "{hline 78}"

    if "`e(estimator_type)'" == "pme" {
        _xtpc_pme_display
        exit
    }
    if "`e(estimator_type)'" == "mgdl" {
        _xtpc_mgdl_display
        exit
    }

    di as txt "  Dep. variable   : " as res "`depvar'"
    di as txt "  Indep. variable : " as res "`indepvar'"
    di as txt "  N (panels)      : " as res %6.0f e(N_g)
    di as txt "  T (periods)     : " as res %6.0f e(T)
    if e(lags) > 0 {
        di as txt "  Lag order (p)   : " as res %6.0f e(lags)
    }
    if e(n_iter) > 0 {
        di as txt "  Iterations      : " as res %6.0f e(n_iter)
        di as txt "  Converged       : " as res cond(e(converged)==1, "Yes", "No")
    }
    di as txt "{hline 78}"

    di
    di as txt "{ralign 20:}{c |}" ///
       as txt "{ralign 12:Coef.}" ///
       as txt "{ralign 12:Std.Err.}" ///
       as txt "{ralign 10:t}" ///
       as txt "{ralign 10:P>|t|}" ///
       as txt "    [95% Conf. Interval]"
    di as txt "{hline 20}{c +}{hline 57}"

    local theta = e(theta)
    local se    = e(se)
    local tval  = e(t_ratio)
    local pval  = e(p_value)
    local ci_lo = e(ci95_lo)
    local ci_hi = e(ci95_hi)

    local sig ""
    if `pval' < 0.01      local sig "***"
    else if `pval' < 0.05 local sig "**"
    else if `pval' < 0.10 local sig "*"

    di as txt "{ralign 20:theta (long-run)}" ///
       as txt "{c |}" ///
       as res %12.6f `theta' ///
       as res %12.6f `se' ///
       as res %10.4f `tval' ///
       as res %10.4f `pval' ///
       as res %12.6f `ci_lo' ///
       as res %12.6f `ci_hi' ///
       as txt "  `sig'"
    di as txt "{hline 20}{c BT}{hline 57}"

    // H0: theta = 1
    di
    di as txt "  H0: theta = 1 (unit long-run coefficient)"
    if `pval' < 0.05 {
        di as res "  Result: Rejected at 5% level"
    }
    else {
        di as res "  Result: Not rejected at 5% level"
    }

    // Bootstrap CI if available
    if e(boot_ci_lo) < . {
        di
        di as txt "  Bootstrap 95% CI : [" ///
           as res %9.6f e(boot_ci_lo) ///
           as txt ", " ///
           as res %9.6f e(boot_ci_hi) ///
           as txt "]  (wild bootstrap, " as res e(boot_reps) as txt " reps)"
    }
    di as txt "{hline 78}"
end
