*! _xtccecoint_display.ado — Publication-quality output for xtccecoint
*! Version 1.0.0 — 2026-05-11
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _xtccecoint_display
program define _xtccecoint_display
    version 14
    syntax, cadfp(string) cv5(string) cv10(string)      ///
        nunits(string) tperiods(string) kregs(string)   ///
        rfactors(string) plagopt(string) modelopt(string) ///
        depopt(string) indepopt(string)                   ///
        panopt(string) timeopt(string) estlab(string)     ///
        dotrunc(string)

    // Convert strings to numeric
    local cadfp_n  = real("`cadfp'")
    local cv5_n    = real("`cv5'")
    local cv10_n   = real("`cv10'")
    local N_n      = real("`nunits'")
    local T_n      = real("`tperiods'")
    local k_n      = real("`kregs'")
    local r_n      = real("`rfactors'")
    local p_n      = real("`plagopt'")
    local model_n2 = real("`modelopt'")
    local trunc_n  = real("`dotrunc'")

    // Aliases for body (preserve original names below)
    local panelvar  "`panopt'"
    local timevar   "`timeopt'"
    local depvar    "`depopt'"
    local indepvars "`indepopt'"

    // Significance decision
    local reject5  = (`cadfp_n' < `cv5_n')
    local reject10 = (`cadfp_n' < `cv10_n')

    if `reject5' {
        local sig_star "**"
        local decision "{bf:Reject H0} (cointegration exists) at 5%"
    }
    else if `reject10' {
        local sig_star "*"
        local decision "{bf:Reject H0} (cointegration exists) at 10%"
    }
    else {
        local sig_star ""
        local decision "Do not reject H0 (no evidence of cointegration)"
    }

    // Model label
    if `model_n2' == 0 local modlab "0 — No deterministics"
    else if `model_n2' == 1 local modlab "1 — Constant"
    else local modlab "2 — Constant + Linear Trend"

    // Truncation info
    if `trunc_n' == 1 {
        if `model_n2' == 1 local trclabel "ON: (-6.19, +2.61) [Pesaran 2007]"
        else               local trclabel "ON: (-6.42, +1.70) [Pesaran 2007]"
    }
    else local trclabel "OFF"

    // ════════════════════════════════════════════════════════════════════════
    //  HEADER
    // ════════════════════════════════════════════════════════════════════════
    di ""
    di as text "  {hline 70}"
    di as text "  {bf:xtccecoint} — Panel CCE Cointegration Test"
    di as text "  Banerjee & Carrion-i-Silvestre (2017, J. Time Series Anal.)"
    di as text "  {hline 70}"
    di ""

    // ════════════════════════════════════════════════════════════════════════
    //  PANEL SETUP
    // ════════════════════════════════════════════════════════════════════════
    di as text "  {bf:Panel Setup}"
    di as text "  {hline 40}"
    di as text "  Panel variable    : `panelvar'"
    di as text "  Time variable     : `timevar'"
    di as text "  Dependent variable: {res:`depvar'}"
    di as text "  Regressors        : {res:`indepvars'}"
    di as text "  N (cross-sections): {res:`N_n'}"
    di as text "  T (time periods)  : {res:`=round(`T_n')'}"
    di as text "  k (regressors)    : {res:`k_n'}"
    di ""

    // ════════════════════════════════════════════════════════════════════════
    //  ESTIMATION SETTINGS
    // ════════════════════════════════════════════════════════════════════════
    di as text "  {bf:Estimation Settings}"
    di as text "  {hline 40}"
    di as text "  Model specification: `modlab'"
    di as text "  Estimator          : `estlab'"
    di as text "  Common factors (r) : {res:`r_n'}"
    di as text "  AR lag order (p)   : {res:`p_n'}"
    di as text "  Truncation         : `trclabel'"
    di ""

    // ════════════════════════════════════════════════════════════════════════
    //  SLOPE ESTIMATE (PCCE β̂)
    // ════════════════════════════════════════════════════════════════════════
    di as text "  {bf:Long-Run Coefficient Estimates (PCCE)}"
    di as text "  {hline 40}"
    tempname beta_m
    matrix `beta_m' = _xcce_beta
    local nvars : word count `indepvars'
    forvalues j = 1/`nvars' {
        local vj : word `j' of `indepvars'
        local bj = `beta_m'[1, `j']
        di as text "  β̂(`vj')  = " as res %9.5f `bj'
    }
    di ""

    // ════════════════════════════════════════════════════════════════════════
    //  MAIN RESULT TABLE
    // ════════════════════════════════════════════════════════════════════════
    di as text "  {hline 70}"
    di as text "  {bf:Panel CADFcointegration Test (CADF_P)}"
    di as text "  H0: No cointegration (spurious regression) for all units"
    di as text "  H1: Cointegration exists for some or all units"
    di as text "  Reject H0 if CADF_P < critical value (left-tail test)"
    di as text "  {hline 70}"
    di ""

    // Table header
    di as text "  " %15s "Statistic" "   " %12s "CV (5%)" "   " %12s "CV (10%)" "   Decision"
    di as text "  {hline 65}"

    // Main result row
    local cadfp_fmt = string(round(`cadfp_n', 0.0001), "%9.4f")
    local cv5_fmt   = string(round(`cv5_n',   0.0001), "%9.4f")
    local cv10_fmt  = string(round(`cv10_n',  0.0001), "%9.4f")

    di as text "  " %15s "CADF_P" ///
       "   " as res %12s "`cadfp_fmt'`sig_star'" ///
       as text "   " %12s "`cv5_fmt'" ///
       "   " %12s "`cv10_fmt'" ///
       "   " as res "`decision'"

    di as text "  {hline 65}"
    di ""

    di as text "  Significance codes: ** Reject at 5%    * Reject at 10%"
    di ""

    // ════════════════════════════════════════════════════════════════════════
    //  INDIVIDUAL CADF STATISTICS SUMMARY
    // ════════════════════════════════════════════════════════════════════════
    tempname t_ind
    matrix `t_ind' = _xcce_t_ind

    local nind = colsof(`t_ind')

    // Count rejections
    local rej5_count  = 0
    local rej10_count = 0
    local tmin = `t_ind'[1,1]
    local tmax = `t_ind'[1,1]

    forvalues i = 1/`nind' {
        local ti = `t_ind'[1,`i']
        if `ti' < `cv5_n'  local ++rej5_count
        if `ti' < `cv10_n' local ++rej10_count
        if `ti' < `tmin'   local tmin = `ti'
        if `ti' > `tmax'   local tmax = `ti'
    }

    di as text "  {bf:Individual CADF Statistics Summary}"
    di as text "  {hline 50}"
    di as text "  Number of units              : {res:`nind'}"
    di as text "  Reject H0 at 5%  (cointegrated): {res:`rej5_count'} / `nind'"
    di as text "  Reject H0 at 10% (cointegrated): {res:`rej10_count'} / `nind'"
    di as text "  Min individual statistic     : {res:`=string(round(`tmin',0.0001))'}"
    di as text "  Max individual statistic     : {res:`=string(round(`tmax',0.0001))'}"
    di ""

    // Display detailed individual results (if N <= 60)
    if `nind' <= 60 {
        di as text "  {bf:Individual CADF Statistics (t_{α̂_{i,0}})}"
        di as text "  {hline 50}"
        di as text "  " %6s "Unit" "   " %10s "CADF_i" "   " %6s "Sign."

        forvalues i = 1/`nind' {
            local uid = _xcce_ids[1, `i']
            local ti2 = `t_ind'[1, `i']
            local sstar ""
            if `ti2' < `cv5_n' local sstar "**"
            else if `ti2' < `cv10_n' local sstar "*"
            di as text "  " %6s "`uid'" ///
               "   " as res %10.4f `ti2' ///
               as text "   " %6s "`sstar'"
        }
        di as text "  {hline 50}"
    }
    else {
        di as text "  (Individual statistics stored in e(cadf_ind). N = `nind')"
        di as text "  Use: matrix list e(cadf_ind)"
    }
    di ""

    // ════════════════════════════════════════════════════════════════════════
    //  INTERPRETATION GUIDE
    // ════════════════════════════════════════════════════════════════════════
    di as text "  {hline 70}"
    di as text "  {bf:Interpretation}"
    di as text "  This test assesses panel cointegration controlling for cross-"
    di as text "  section dependence via CCE (cross-section averages as factor"
    di as text "  proxies). Under H0 (no cointegration), CADF_P ≈ N(μ, σ²/N)."
    di as text ""
    di as text "  {ul:Result}: `decision'"
    di as text "  {hline 70}"
    di ""

    // ════════════════════════════════════════════════════════════════════════
    //  REFERENCES
    // ════════════════════════════════════════════════════════════════════════
    di as text "  {bf:Reference}"
    di as text "  Banerjee, A. & Carrion-i-Silvestre, J.L. (2017)."
    di as text "  Testing for Panel Cointegration Using CCE Estimators."
    di as text "  J. Time Series Anal., DOI: 10.1111/jtsa.12234"
    di ""
    di as text "  {it:See also: {help xtdcce2}, {help xtcce}, {help xtnumfac}, {help xtbreakcoint}}"
    di ""
end
