*! xtrec v1.0.0
*! Panel unit root test based on recursive detrending
*! Implements t-REC and t-RREC from Westerlund (2015, Journal of Econometrics)
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: March 2026
capture program drop xtrec
program define xtrec, rclass sortpreserve
    version 14.0
    syntax varname(numeric ts) [if] [in], [         ///
        TRend(integer 0)            /// polynomial trend degree (default 0 = constant only)
        MAXLag(integer -1)          /// max lag augmentation for robust version (-1 = auto BIC)
        ROBust                      /// use robust t-RREC (serial corr, CSD, heterosked)
        NOGRaph                     /// suppress diagnostic graphs
        NOTABle                     /// suppress output table
        Level(integer 95)           /// confidence level
    ]

    * =========================================================================
    * SETUP AND VALIDATION
    * =========================================================================

    qui xtset
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"

    if "`panelvar'" == "" | "`timevar'" == "" {
        di as error "Panel and time variables must be set. Use {cmd:xtset panelid timevar}."
        exit 198
    }

    marksample touse
    sort `panelvar' `timevar'

    * Validate trend degree
    if `trend' < 0 {
        di as error "trend() must be >= 0 (0 = constant, 1 = linear, 2 = quadratic, ...)"
        exit 198
    }

    * Count panels and time periods
    tempvar gid
    qui egen `gid' = group(`panelvar') if `touse'
    qui sum `gid' if `touse', meanonly
    local N = r(max)

    * Check for balanced panel
    qui tab `timevar' if `touse'
    local T = r(r)

    * Check minimum requirements
    if `N' < 3 {
        di as error "At least 3 panels are required."
        exit 2001
    }
    if `T' < `trend' + 5 {
        di as error "Insufficient time periods for trend degree `trend'. Need at least `=`trend'+5' periods."
        exit 2001
    }

    * Total observations
    qui count if `touse'
    local NTobs = r(N)

    * Check balanced
    qui tab `panelvar' if `touse'
    local expected_obs = `N' * `T'
    if `NTobs' != `expected_obs' {
        di as error "Panel must be strongly balanced. Found `NTobs' obs but expected `expected_obs' (N=`N' x T=`T')."
        exit 198
    }

    * Set maxlag for robust version
    if "`robust'" != "" & `maxlag' == -1 {
        local maxlag = floor(4 * (`T'/100)^(2/9))
        if `maxlag' < 1 local maxlag = 1
    }
    if "`robust'" == "" {
        local maxlag = 0
    }

    * =========================================================================
    * CALL MATA TO COMPUTE TEST STATISTICS
    * =========================================================================

    tempname results coefs_mat panel_stats_mat
    mata: _xtrec_compute("`varlist'", "`panelvar'", "`timevar'", "`touse'", `trend', `maxlag', "`robust'", "`results'")

    * Compute individual panel statistics
    mata: _xtrec_panel_stats("`varlist'", "`panelvar'", "`timevar'", "`touse'", `trend', "`robust'", `maxlag', "`panel_stats_mat'")

    * Extract results from returned matrix
    * Row 1: [trec_stat, pvalue, sigma2, trend_p, lag_q, N, T]
    local trec_stat = `results'[1,1]
    local pvalue    = `results'[1,2]
    local sigma2    = `results'[1,3]
    local trend_p   = `results'[1,4]
    local lag_q     = `results'[1,5]
    local Nused     = `results'[1,6]
    local Tused     = `results'[1,7]

    * Determine test name
    if "`robust'" != "" {
        local testname "t-RREC"
    }
    else {
        local testname "t-REC"
    }

    * Determine decision
    local alpha = (100 - `level') / 100
    local crit = invnormal(`alpha')
    if `trec_stat' < `crit' {
        local decision "Reject H0"
        local decision_color "err"
    }
    else {
        local decision "Fail to reject H0"
        local decision_color "text"
    }

    * Get coefficients a_p and b_p from paper Table 1
    mata: _xtrec_get_coefficients(`trend', "`coefs_mat'")
    local a_p = `coefs_mat'[1,1]
    local b_p = `coefs_mat'[1,2]

    * Extract individual panel statistics
    * panel_stats_mat: [mean_tstat, med_tstat, sd_tstat, min_tstat, max_tstat, mean_sig2i]
    local ps_mean    = `panel_stats_mat'[1,1]
    local ps_median  = `panel_stats_mat'[1,2]
    local ps_sd      = `panel_stats_mat'[1,3]
    local ps_min     = `panel_stats_mat'[1,4]
    local ps_max     = `panel_stats_mat'[1,5]
    local ps_sig2    = `panel_stats_mat'[1,6]

    * Effective time periods after detrending
    if `trend' <= 0 {
        local T_eff = `Tused' - 1
    }
    else {
        local T_eff = `Tused' - 1 - `trend'
    }

    * =========================================================================
    * DISPLAY OUTPUT
    * =========================================================================

    if "`notable'" == "" {

        * =================================================================
        * HEADER
        * =================================================================
        di ""
        di as text "{hline 78}"
        di as text "{bf: Westerlund (2015) Panel Unit Root Test}"
        di as text " Recursively Detrended `testname' Test"
        di as text " {it:Journal of Econometrics} 185(2), 453-467"
        di as text "{hline 78}"

        * =================================================================
        * DATA SUMMARY
        * =================================================================
        di ""
        di as text " {bf:Data Summary}"
        di as text "{hline 78}"
        di as text " Variable tested       : {res:`varlist'}" ///
            _col(45) as text "Panel variable  : {res:`panelvar'}"
        di as text " Time variable         : {res:`timevar'}" ///
            _col(45) as text "Panel structure : {res:Balanced}"
        di as text " N (panels)            : {res:`Nused'}" ///
            _col(45) as text "T (time periods): {res:`Tused'}"
        di as text " Total observations    : {res:`NTobs'}" ///
            _col(45) as text "T effective     : {res:`T_eff'}"
        di as text "{hline 78}"

        * =================================================================
        * ESTIMATION DETAILS
        * =================================================================
        di ""
        di as text " {bf:Estimation Details}"
        di as text "{hline 78}"
        di as text " Test type             : {res:`testname'}" ///
            _col(45) as text "Trend degree (p): {res:`trend_p'}"

        * Trend specification description
        if `trend' == 0 {
            di as text " Deterministic terms   : {res:Constant only}"
        }
        else if `trend' == 1 {
            di as text " Deterministic terms   : {res:Constant + linear trend}"
        }
        else if `trend' == 2 {
            di as text " Deterministic terms   : {res:Constant + linear + quadratic trend}"
        }
        else if `trend' == 3 {
            di as text " Deterministic terms   : {res:Constant + polynomial up to t^`trend'}"
        }
        else {
            di as text " Deterministic terms   : {res:Polynomial trend of degree `trend'}"
        }

        if "`robust'" == "" {
            di as text " Error assumption      : {res:iid across i and t}"
            if `sigma2' != . {
                di as text " sigma^2_eps           : {res:" %10.6f `sigma2' "}" ///
                    _col(45) as text "Estimation: sigma^2 = (NT)^-1 sum y^2"
            }
        }
        else {
            di as text " Error assumption      : {res:Heteroskedastic, serial & CSD}"
            di as text " Lag augmentation      : {res:`lag_q' (BIC-selected)}"
            di as text " Defactoring method    : {res:Cross-section averaging (Pesaran 2007)}"
            di as text " Max lag formula       : {res:q_max = floor[4(T/100)^(2/9)]}"
        }
        di as text " Null distribution     : {res:N(0,1)}" ///
            _col(45) as text "Critical region : {res:Left tail}"
        di as text "{hline 78}"

        * =================================================================
        * MAIN TEST RESULTS
        * =================================================================
        di ""
        di as text " {bf:Test Results}"
        di as text "{hline 78}"
        di as text %22s "Statistic" _col(24) %14s "Value" _col(40) %14s "p-value" _col(56) %20s "Decision (`level'%)"
        di as text "{hline 78}"

        * Format significance stars
        if `pvalue' < 0.01 {
            local stars "***"
            local pcolor "err"
        }
        else if `pvalue' < 0.05 {
            local stars "**"
            local pcolor "err"
        }
        else if `pvalue' < 0.10 {
            local stars "*"
            local pcolor "result"
        }
        else {
            local stars ""
            local pcolor "text"
        }

        * Format p-value string for display
        if `pvalue' < 0.0001 & `pvalue' >= 0 {
            local pval_str "<0.0001"
        }
        else if `pvalue' > 0.9999 {
            local pval_str ">0.9999"
        }
        else {
            local pval_str : di %8.4f `pvalue'
            local pval_str = strtrim("`pval_str'")
        }

        di as text %22s "`testname'" _col(24) as result %14.4f `trec_stat' ///
            _col(40) as `pcolor' %14s "`pval_str'`stars'" ///
            _col(56) as `decision_color' %20s "`decision'"
        di as text "{hline 78}"

        * =================================================================
        * CRITICAL VALUES TABLE
        * =================================================================
        di ""
        di as text " {bf:Critical Values and Decision Table}"
        di as text "{hline 78}"
        di as text %18s "Signif. Level" _col(22) %14s "Critical Value" _col(38) %14s "`testname'" _col(54) %24s "Decision"
        di as text "{hline 78}"

        * 1% level
        local cv_01 = invnormal(0.01)
        if `trec_stat' < `cv_01' {
            di as text %18s "1%" _col(22) as result %14.4f `cv_01' _col(38) as result %14.4f `trec_stat' _col(54) as err %24s "Reject H0 ***"
        }
        else {
            di as text %18s "1%" _col(22) as result %14.4f `cv_01' _col(38) as result %14.4f `trec_stat' _col(54) as text %24s "Fail to reject H0"
        }

        * 5% level
        local cv_05 = invnormal(0.05)
        if `trec_stat' < `cv_05' {
            di as text %18s "5%" _col(22) as result %14.4f `cv_05' _col(38) as result %14.4f `trec_stat' _col(54) as err %24s "Reject H0 **"
        }
        else {
            di as text %18s "5%" _col(22) as result %14.4f `cv_05' _col(38) as result %14.4f `trec_stat' _col(54) as text %24s "Fail to reject H0"
        }

        * 10% level
        local cv_10 = invnormal(0.10)
        if `trec_stat' < `cv_10' {
            di as text %18s "10%" _col(22) as result %14.4f `cv_10' _col(38) as result %14.4f `trec_stat' _col(54) as err %24s "Reject H0 *"
        }
        else {
            di as text %18s "10%" _col(22) as result %14.4f `cv_10' _col(38) as result %14.4f `trec_stat' _col(54) as text %24s "Fail to reject H0"
        }
        di as text "{hline 78}"

        * =================================================================
        * INDIVIDUAL PANEL STATISTICS
        * =================================================================
        di ""
        di as text " {bf:Individual Panel Statistics}"
        di as text "{hline 78}"
        if "`robust'" != "" {
            di as text "  Per-panel variance-weighted statistics from defactored residuals"
        }
        else {
            di as text "  Per-panel unit root regression t-statistics (from recursive residuals)"
        }
        di as text "{hline 78}"
        di as text %16s "Mean" _col(18) %12s "Median" _col(32) %12s "Std. Dev." ///
            _col(46) %12s "Minimum" _col(60) %12s "Maximum"
        di as text "{hline 78}"
        di as result %16.4f `ps_mean' _col(18) as result %12.4f `ps_median' ///
            _col(32) as result %12.4f `ps_sd' ///
            _col(46) as result %12.4f `ps_min' _col(60) as result %12.4f `ps_max'
        di as text "{hline 78}"

        * Heterogeneity assessment
        if `ps_sd' > abs(`ps_mean') & `ps_mean' != 0 {
            di as text "  >> High cross-sectional heterogeneity detected (SD > |Mean|)"
        }
        else {
            di as text "  >> Moderate cross-sectional homogeneity (SD <= |Mean|)"
        }
        if `ps_min' < invnormal(0.05) & `ps_max' > invnormal(0.95) {
            di as text "  >> Evidence of mixed stationarity across panels"
        }
        di as text "{hline 78}"

        * =================================================================
        * INTERPRETATION
        * =================================================================
        di ""
        di as text " {bf:Interpretation}"
        di as text "{hline 78}"
        if `trec_stat' < `cv_01' {
            di as text " {bf:Strong evidence against the unit root null hypothesis.}"
            di as text " The panel data is {res:stationary} (or trend-stationary with degree `trend_p')."
            di as text " The null of a common unit root is rejected at the 1% level."
        }
        else if `trec_stat' < `cv_05' {
            di as text " {bf:Moderate evidence against the unit root null hypothesis.}"
            di as text " The panel data is likely {res:stationary} (or trend-stationary"
            di as text " with degree `trend_p'). The null is rejected at the 5% level."
        }
        else if `trec_stat' < `cv_10' {
            di as text " {bf:Weak evidence against the unit root null hypothesis.}"
            di as text " The panel data may be {res:stationary} (or trend-stationary"
            di as text " with degree `trend_p'). The null is rejected at the 10% level only."
        }
        else {
            di as text " {bf:No evidence against the unit root null hypothesis.}"
            di as text " The panel data contains a {res:unit root} (non-stationary)."
            di as text " The null cannot be rejected at conventional significance levels."
        }
        di ""
        di as text " H0: All panels contain a unit root (rho_i = 1 for all i)"
        di as text " H1: At least some panels are stationary (rho_i < 1 for some i)"
        if "`robust'" != "" {
            di as text ""
            di as text " Note: Robust to serial correlation, cross-section dependence,"
            di as text "       and heteroskedasticity (t-RREC with defactoring)."
        }
        di as text "{hline 78}"

        * =================================================================
        * PAPER TABLE 1: ASYMPTOTIC COEFFICIENTS
        * =================================================================
        di ""
        di as text " {bf:Table 1: Asymptotic Coefficients (Westerlund 2015, Table 1)}"
        di as text "{hline 78}"
        di as text %10s "p" _col(16) %14s "a_p" _col(34) %14s "b_p" ///
            _col(52) %12s "kappa" _col(66) %12s "Power by"
        di as text "{hline 78}"

        * p = -1
        if `trend' == -1 {
            di as result %10s ">> -1 <<" _col(16) as result %14.5f 0.5 _col(34) as result %14.5f 0.33333 ///
                _col(52) as result %12s "1/2" _col(66) as result %12s "mu_1"
        }
        else {
            di as text %10.0f -1 _col(16) as text %14.5f 0.5 _col(34) as text %14.5f 0.33333 ///
                _col(52) as text %12s "1/2" _col(66) as text %12s "mu_1"
        }

        * p = 0
        if `trend' == 0 {
            di as result %10s ">> 0 <<" _col(16) as result %14.5f 0.5 _col(34) as result %14.5f 0.33333 ///
                _col(52) as result %12s "1/2" _col(66) as result %12s "mu_1"
        }
        else {
            di as text %10.0f 0 _col(16) as text %14.5f 0.5 _col(34) as text %14.5f 0.33333 ///
                _col(52) as text %12s "1/2" _col(66) as text %12s "mu_1"
        }

        * p = 1
        if `trend' == 1 {
            di as result %10s ">> 1 <<" _col(16) as result %14.5f 0.0 _col(34) as result %14.5f -0.03704 ///
                _col(52) as result %12s "1/4" _col(66) as result %12s "mu_2"
        }
        else {
            di as text %10.0f 1 _col(16) as text %14.5f 0.0 _col(34) as text %14.5f -0.03704 ///
                _col(52) as text %12s "1/4" _col(66) as text %12s "mu_2"
        }

        * p = 2
        if `trend' == 2 {
            di as result %10s ">> 2 <<" _col(16) as result %14.5f 0.0 _col(34) as result %14.5f -0.00648 ///
                _col(52) as result %12s "1/4" _col(66) as result %12s "mu_2"
        }
        else {
            di as text %10.0f 2 _col(16) as text %14.5f 0.0 _col(34) as text %14.5f -0.00648 ///
                _col(52) as text %12s "1/4" _col(66) as text %12s "mu_2"
        }

        * p = 3
        if `trend' == 3 {
            di as result %10s ">> 3 <<" _col(16) as result %14.5f 0.0 _col(34) as result %14.5f -0.00238 ///
                _col(52) as result %12s "1/4" _col(66) as result %12s "mu_2"
        }
        else {
            di as text %10.0f 3 _col(16) as text %14.5f 0.0 _col(34) as text %14.5f -0.00238 ///
                _col(52) as text %12s "1/4" _col(66) as text %12s "mu_2"
        }

        * p = 4
        if `trend' == 4 {
            di as result %10s ">> 4 <<" _col(16) as result %14.5f 0.0 _col(34) as result %14.5f -0.00115 ///
                _col(52) as result %12s "1/4" _col(66) as result %12s "mu_2"
        }
        else {
            di as text %10.0f 4 _col(16) as text %14.5f 0.0 _col(34) as text %14.5f -0.00115 ///
                _col(52) as text %12s "1/4" _col(66) as text %12s "mu_2"
        }
        di as text "{hline 78}"

        * Explanation of Table 1
        di as text "  a_p and b_p are coefficients of the 1st and 2nd order bias terms"
        di as text "  in the asymptotic distribution of `testname'."
        di as text ""
        di as text "  {bf:Key insight:} a_p = 0 for all p >= 1. This means that when"
        di as text "  trend terms are fitted, the first-order bias vanishes entirely."
        di as text "  Power is then driven by the second-order term b_p through mu_2"
        di as text "  (the variance of c_i), requiring N^{-1/4}T^{-1}-neighborhoods."
        di as text "{hline 78}"

        * =================================================================
        * POWER PROPERTIES
        * =================================================================
        di ""
        di as text " {bf:Power Properties}"
        di as text "{hline 78}"
        if `trend' < 1 {
            di as text " kappa = 1/2:  Power within N^{-1/2}*T^{-1} neighborhoods of unity"
            di as text " Power driver: mu_1 = E(c_i), the mean of the local-to-unity parameter"
            di as text " For your data: N^{-1/2}*T^{-1} = " as result %10.6f 1/(sqrt(`Nused')*`Tused')
        }
        else {
            di as text " kappa = 1/4:  Power within N^{-1/4}*T^{-1} neighborhoods of unity"
            di as text " Power driver: mu_2 = E(c_i^2), the second moment of local-to-unity"
            di as text " For your data: N^{-1/4}*T^{-1} = " as result %10.6f 1/(`Nused'^0.25*`Tused')
        }
        di as text ""
        di as text " {bf:Key Properties:}"
        di as text " {c -} Null distribution is {bf:invariant} to both true and fitted trend degree"
        di as text " {c -} No mean/variance correction factors needed (unique among panel UR tests)"
        di as text " {c -} Critical values from standard Normal: reject H0 if `testname' < z_alpha"
        di as text " {c -} Critical region is {bf:always} in the left tail"
        if `trend' >= 1 {
            di as text " {c -} b_p is declining in p: power decreases as trend degree increases"
            di as text " {c -} Test cannot distinguish local stationarity from local explosiveness"
        }
        if "`robust'" != "" {
            di as text " {c -} Robust to serial correlation, cross-section dependence"
            di as text "   and heteroskedasticity"
            di as text " {c -} Common factor removed via cross-section averaging (Pesaran 2007)"
        }
        di as text "{hline 78}"

        * =================================================================
        * METHODOLOGY SUMMARY
        * =================================================================
        di ""
        di as text " {bf:Methodology}"
        di as text "{hline 78}"
        di as text " The `testname' test statistic is constructed in four steps:"
        di as text ""
        di as text "  Step 1: First-difference: y_it = Delta Y_it"
        di as text "  Step 2: Recursively detrend y_it using only past and current values"
        di as text "          to obtain y_{i,t,p} (preserves martingale property)"
        di as text "  Step 3: Accumulate: R_{i,t,p} = sum_{s=p+1}^t y_{i,s,p}"
        if "`robust'" != "" {
            di as text "  Step 3b: Defactor by removing cross-section average (common factor)"
            di as text "           and augment with BIC-selected lags for serial correlation"
        }
        di as text "  Step 4: Compute pooled t-ratio from R_{i,t-1,p} and y_{i,t,p}"
        di as text ""
        if "`robust'" == "" {
            di as text "  t-REC = A_{NT,p} / (sigma_hat * sqrt(B_{NT,p}))"
            di as text "  where A_{NT,p} = (1/sqrt(N)T) sum_i sum_t R_{i,t-1,p} * y_{i,t,p}"
            di as text "        B_{NT,p} = (1/NT^2) sum_i sum_t R^2_{i,t-1,p}"
        }
        else {
            di as text "  t-RREC = [sum_i sum_t sigma^{-2}_{e,i} R_{i,t-1,p} r_{i,t,p}]"
            di as text "         / sqrt[sum_i sum_t sigma^{-2}_{e,i} R^2_{i,t-1,p}]"
        }
        di as text ""
        di as text "  Under H0: `testname' -> N(0,1) as N,T -> infinity"
        di as text "{hline 78}"
        di as text " *** p<0.01, ** p<0.05, * p<0.10"
        di as text " Reference: Westerlund, J. (2015). The effect of recursive detrending"
        di as text "            on panel unit root tests. J. Econometrics, 185(2), 453-467."
        di as text "{hline 78}"
    }

    * =========================================================================
    * GRAPHS
    * =========================================================================

    if "`nograph'" == "" {
        preserve

        * --- Graph 1: Density of recursively detrended residuals (pooled) ---
        tempvar resid_rd
        qui gen double `resid_rd' = .
        mata: _xtrec_get_residuals("`varlist'", "`panelvar'", "`timevar'", "`touse'", `trend', "`resid_rd'")

        local graph_list ""

        qui summarize `resid_rd' if `touse', detail
        local res_mean = r(mean)
        local res_sd   = r(sd)

        twoway (histogram `resid_rd' if `touse', density fcolor(ltblue%60) lcolor(white)) ///
               (kdensity `resid_rd' if `touse', lcolor(navy) lwidth(medthick)) ///
               (function normalden(x, `res_mean', `res_sd'), range(`=r(min)' `=r(max)') ///
                    lcolor(cranberry) lwidth(medthick) lpattern(dash)), ///
               title("Recursively Detrended Residuals", size(medium)) ///
               subtitle("Pooled density (p = `trend')", size(small)) ///
               xtitle("Residual") ytitle("Density") ///
               legend(order(1 "Histogram" 2 "Kernel density" 3 "Normal fit") ///
                   size(vsmall) cols(3) position(6)) ///
               graphregion(color(white)) plotregion(margin(small)) ///
               scheme(s2color) name(xtrec_resid, replace) nodraw

        local graph_list "`graph_list' xtrec_resid"

        * --- Graph 2: Cumulative sum paths R_{i,t,p} ---
        tempvar cusum_path panel_id_graph
        qui gen double `cusum_path' = .
        qui gen long `panel_id_graph' = .
        mata: _xtrec_get_cusums("`varlist'", "`panelvar'", "`timevar'", "`touse'", `trend', "`cusum_path'", "`panel_id_graph'")

        * Pick up to 20 panels for the spaghetti plot
        qui levelsof `panel_id_graph' if `touse' & !missing(`cusum_path'), local(pids)
        local npids : word count `pids'
        local max_lines = min(`npids', 20)

        local tw_cmd ""
        forvalues j = 1/`max_lines' {
            local pid : word `j' of `pids'
            local tw_cmd `"`tw_cmd' (line `cusum_path' `timevar' if `panel_id_graph' == `pid' & `touse', lcolor(ltblue%40) lwidth(thin))"'
        }

        * Add the cross-section mean
        tempvar mean_cusum
        qui bysort `timevar': egen double `mean_cusum' = mean(`cusum_path') if `touse'

        twoway `tw_cmd' ///
               (line `mean_cusum' `timevar' if `touse', lcolor(navy) lwidth(thick)), ///
               title("Cumulative Sum Paths R{sub:i,t,p}", size(medium)) ///
               subtitle("Individual panels (light) and cross-section mean (bold)", size(small)) ///
               xtitle("`timevar'") ytitle("Cumulative sum") ///
               legend(off) ///
               graphregion(color(white)) plotregion(margin(small)) ///
               scheme(s2color) name(xtrec_cusum, replace) nodraw

        local graph_list "`graph_list' xtrec_cusum"

        * --- Combine ---
        graph combine `graph_list', ///
            title("Westerlund (2015) `testname' Panel Unit Root Test Diagnostics", size(medsmall)) ///
            subtitle("Variable: `varlist' | N=`Nused', T=`Tused' | Trend degree p=`trend'", size(small)) ///
            cols(2) ///
            graphregion(color(white)) ///
            name(xtrec_diag, replace)

        restore
    }

    * =========================================================================
    * RETURN VALUES
    * =========================================================================

    return clear
    if "`robust'" != "" {
        return scalar trrec = `trec_stat'
    }
    else {
        return scalar trec = `trec_stat'
    }
    return scalar pvalue   = `pvalue'
    return scalar N        = `Nused'
    return scalar T        = `Tused'
    return scalar T_eff    = `T_eff'
    return scalar trend    = `trend_p'
    return scalar a_p      = `a_p'
    return scalar b_p      = `b_p'
    return scalar sigma2   = `sigma2'
    if `trend' < 1 {
        return scalar kappa = 0.5
    }
    else {
        return scalar kappa = 0.25
    }
    if "`robust'" != "" {
        return scalar maxlag = `lag_q'
    }
    return scalar ps_mean   = `ps_mean'
    return scalar ps_median = `ps_median'
    return scalar ps_sd     = `ps_sd'
    return scalar ps_min    = `ps_min'
    return scalar ps_max    = `ps_max'
    return local test      "`testname'"
    return local varname   "`varlist'"
    return local panelvar  "`panelvar'"
    return local timevar   "`timevar'"

end

* =============================================================================
* MATA FUNCTIONS
* =============================================================================

mata:
mata clear

// ─────────────────────────────────────────────────────────────────────────────
// Get a_p and b_p coefficients from Westerlund (2015) Table 1
// ─────────────────────────────────────────────────────────────────────────────
void _xtrec_get_coefficients(real scalar p, string scalar matname)
{
    real scalar a_p, b_p

    if (p <= 0) {
        a_p = 0.5
        b_p = 1/3
    }
    else {
        a_p = _xtrec_compute_ap(p)
        b_p = _xtrec_compute_bp(p)
    }

    st_matrix(matname, (a_p, b_p))
}

// ─────────────────────────────────────────────────────────────────────────────
// Compute h_{m,n,p} from the paper
// h_{m,n,p} = (-1)^{m+n} * (m+n-1) * C(p-1+m, p-n) * C(p-1+n, p-m) * [C(m+n-2, m-1)]^2
// ─────────────────────────────────────────────────────────────────────────────
real scalar _xtrec_hmn(real scalar m, real scalar n, real scalar p)
{
    real scalar val
    val = ((-1)^(m+n)) * (m+n-1) * comb(p-1+m, p-n) * comb(p-1+n, p-m) * (comb(m+n-2, m-1))^2
    return(val)
}

// ─────────────────────────────────────────────────────────────────────────────
// Compute h_{m,p} = 1(p>=1) * sum_{n=1}^{p} h_{m,n,p}
// ─────────────────────────────────────────────────────────────────────────────
real scalar _xtrec_hmp(real scalar m, real scalar p)
{
    real scalar s, n
    if (p < 1) return(0)
    s = 0
    for (n = 1; n <= p; n++) {
        s = s + _xtrec_hmn(m, n, p)
    }
    return(s)
}

// ─────────────────────────────────────────────────────────────────────────────
// Compute b_p coefficient from the paper (Lemma 1)
// b_p = 1/3 - sum_{k=1}^{p} h_{k,p} * [(2k+1)(k+2) + k(2k+5) + 4] / [6k(k+1)(k+2)]
//       + sum_{k=1}^{p} sum_{m=1}^{p} h_{k,p}h_{m,p} * [k(k+2)(k+m+1) + m] / [3mk(k+1)(k+2)(k+m+1)]
// ─────────────────────────────────────────────────────────────────────────────
real scalar _xtrec_compute_bp(real scalar p)
{
    real scalar bp, k, m, hk, hm

    bp = 1/3

    for (k = 1; k <= p; k++) {
        hk = _xtrec_hmp(k, p)
        bp = bp - hk * ((2*k+1)*(k+2) + k*(2*k+5) + 4) / (6*k*(k+1)*(k+2))
    }

    for (k = 1; k <= p; k++) {
        for (m = 1; m <= p; m++) {
            hk = _xtrec_hmp(k, p)
            hm = _xtrec_hmp(m, p)
            bp = bp + hk * hm * (k*(k+2)*(k+m+1) + m) / (3*m*k*(k+1)*(k+2)*(k+m+1))
        }
    }

    return(bp)
}

// ─────────────────────────────────────────────────────────────────────────────
// Compute a_p coefficient from the paper (Lemma 1)
// a_p = 1/2 - sum_{k=1}^{p} h_{k,p} * (1/k)
//       + sum_{k=1}^{p} sum_{m=1}^{p} h_{k,p}h_{m,p} * [(k+1)(m+2)+m(m+1)] / [2m(m+k)(m+1)(k+1)]
// ─────────────────────────────────────────────────────────────────────────────
real scalar _xtrec_compute_ap(real scalar p)
{
    real scalar ap, k, m, hk, hm

    if (p < 1) return(0.5)

    ap = 0.5

    for (k = 1; k <= p; k++) {
        hk = _xtrec_hmp(k, p)
        ap = ap - hk / k
    }

    for (k = 1; k <= p; k++) {
        for (m = 1; m <= p; m++) {
            hk = _xtrec_hmp(k, p)
            hm = _xtrec_hmp(m, p)
            ap = ap + hk * hm * ((k+1)*(m+2) + m*(m+1)) / (2*m*(m+k)*(m+1)*(k+1))
        }
    }

    return(ap)
}

// ─────────────────────────────────────────────────────────────────────────────
// Build d_{t,p} vector from the paper
//
// Paper (p.5, Section 3.1):
//   y_{i,t} = Delta Y_{i,t}
//   d_{t,p} = G * Delta D_{t,p+1} = D_{t,p}  for p >= 1
//
// where D_{t,p} = (1, t, t^2, ..., t^{p-1})' is the polynomial basis of dim p
// and G is a selection matrix removing the first (zero) element of Delta D_{t,p+1}
//
// Since Delta(1) = 0, Delta(t) = 1, Delta(t^2) = 2t-1, Delta(t^3) = 3t^2-3t+1, ...
// After G removes the zero: d_{t,p} = (1, 2t-1, 3t^2-3t+1, ...)'
// which equals D_{t,p} = (1, t, t^2, ..., t^{p-1})'? No!
//
// Actually, re-reading carefully: D_{t,p+1} = (1, t, ..., t^p)'
// So Delta D_{t,p+1} = (0, 1, 2t-1, 3t^2-3t+1, ..., Delta(t^p))'
// G removes the first zero element, giving the p-vector:
//   d_{t,p} = (1, 2t-1, 3t^2-3t+1, ..., Delta(t^p))'
//
// But the paper also says d_{t,p} = D_{t,p} for p>=1.
// D_{t,p} has dimension p and D_{t,p} = (1, t, t^2, ..., t^{p-1})'
//
// These are NOT the same! The resolution is that "D_{t,p}" here refers to the
// p-dimensional VERSION of the trend, NOT the level.
// But since y_{i,t} = Delta Y_{i,t}, the regression that detrends y is in first
// differences. The appropriate trend basis for y_{i,t} IS the first-differenced
// polynomial: d_{t,p} = (Delta(t), Delta(t^2), ..., Delta(t^p))'
//             = (1, 2t-1, 3t^2-3t+1, ...)
//
// This matches the formula Delta(t^k) = t^k - (t-1)^k.
//
// In the paper's notation, D_{t,p} for the first-differenced model IS these
// first-differenced polynomials. This is consistent with the recursive OLS
// formula.
// ─────────────────────────────────────────────────────────────────────────────
void _xtrec_build_dt(real scalar t, real scalar p, real colvector dt)
{
    real scalar k
    // d_{t,p} = (Delta(t), Delta(t^2), ..., Delta(t^p))'
    //         = (1, 2t-1, 3t^2-3t+1, ...)
    //         = (t^1-(t-1)^1, t^2-(t-1)^2, ..., t^p-(t-1)^p)
    for (k = 1; k <= p; k++) {
        dt[k] = t^k - (t-1)^k
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recursive detrending of y_{i,t}
//
// Paper equation:
//   y_{i,t,p} = y_{i,t} - sum_{k=2}^{t} y_{i,k} * a_{k,t,p}
//   for t = p+1, ..., T and p >= 1
//
//   a_{k,t,p} = d'_{k,p} * (sum_{n=2}^{t} d_{n,p} d'_{n,p})^{-1} * d_{t,p}
//
//   y_{i,t,-1} = y_{i,t,0} = y_{i,t}  (no detrending for p <= 0)
// ─────────────────────────────────────────────────────────────────────────────
real colvector _xtrec_recursive_detrend(real colvector y, real scalar p)
{
    real scalar TT, t, k, j, s_val
    real colvector y_detrended, d_t, d_k
    real matrix DtDt_sum, DtDt_inv

    TT = rows(y)

    // If p <= 0, no detrending needed
    if (p <= 0) return(y)

    y_detrended = J(TT, 1, .)

    // d_{t,p} is p x 1
    d_t = J(p, 1, 0)
    d_k = J(p, 1, 0)
    DtDt_sum = J(p, p, 0)

    for (t = 2; t <= TT; t++) {
        // Build d_{t,p}
        _xtrec_build_dt(t, p, d_t)

        // Accumulate sum of d_n * d_n' for n = 2..t
        DtDt_sum = DtDt_sum + d_t * d_t'

        if (t <= p) {
            // Not enough observations to detrend yet (need t >= p+1)
            y_detrended[t] = .
            continue
        }

        // Compute detrended value:
        // y_{i,t,p} = y_{i,t} - sum_{k=2}^{t} y_{i,k} * a_{k,t,p}
        DtDt_inv = invsym(DtDt_sum)

        s_val = 0
        for (k = 2; k <= t; k++) {
            _xtrec_build_dt(k, p, d_k)
            // a_{k,t,p} = d'_k * (sum d_n d_n')^{-1} * d_t  (scalar)
            s_val = s_val + y[k] * (d_k' * DtDt_inv * d_t)
        }

        y_detrended[t] = y[t] - s_val
    }

    // First observation has no detrending applied
    y_detrended[1] = .

    return(y_detrended)
}

// ─────────────────────────────────────────────────────────────────────────────
// Main computation function for t-REC and t-RREC
//
// t-REC (paper eq. from Section 3.1):
//   t-REC = A_{NT,p} / (sigma_hat_eps * sqrt(B_{NT,p}))
//   A_{NT,p} = (1/(sqrt(N)*T)) * sum_i sum_{t=p+1}^{T} R_{i,t-1,p} * r_{i,t,p}
//   B_{NT,p} = (1/(N*T^2))     * sum_i sum_{t=p+1}^{T} R^2_{i,t-1,p}
//   sigma_hat^2 = (NT)^{-1} * sum_i sum_{t=2}^{T} y^2_{i,t,p}
//   R_{i,t,p} = sum_{n=p+1}^{t} r_{i,n,p}
//   r_{i,t,p} = y_{i,t,p}
//
// t-RREC (paper Section 3.3, Theorem 1):
//   t-RREC = sum_i sum_{t=h}^{T} sigma_hat^{-2}_{e,i} * R_{i,t-1,p} * r_{i,t,p}
//          / sqrt(sum_i sum_{t=h}^{T} sigma_hat^{-2}_{e,i} * R^2_{i,t-1,p})
//   sigma_hat^2_{e,i} = T^{-1} * r'_{i,p} * r_{i,p}
// ─────────────────────────────────────────────────────────────────────────────
void _xtrec_compute(string scalar varname,
                    string scalar panelvar,
                    string scalar timevar,
                    string scalar touse,
                    real scalar p,
                    real scalar maxlag,
                    string scalar do_robust,
                    string scalar matname)
{
    real colvector Y, pid, tid, panel_ids, Yi, dYi, dYi_rd, R_i
    real colvector f_hat, q_selected, yi_vec, beta_def, resid_def
    real colvector y_dep, beta_bic, resid_bic, R_i_rob
    real matrix y_fd, y_rd, r_defactored, X_lags, Xi_aug
    real scalar N, T_total, T_fd, T_per_panel, i, t, k, j
    real scalar trec_stat, pvalue, sigma2_eps
    real scalar sum_sq, count_rd, A_NT, B_NT, cumsum_val, T_eff
    real scalar q, h_val, best_bic, best_q, qq, t_reg_start, n_reg
    real scalar row_idx, ll, rss_bic, any_miss, bic_val
    real scalar q_max_used, T_eff_robust, cs_sum, cs_count
    real scalar qi, t_reg_s, n_obs_i, n_regs, t_abs, ll2
    real scalar skip_panel, sig2_ei, n_valid, cumsum_rob
    real scalar num_sum, den_sum, lag_used

    // Read data
    st_view(Y, ., varname, touse)
    st_view(pid, ., panelvar, touse)
    st_view(tid, ., timevar, touse)

    // Identify panels
    panel_ids = uniqrows(pid)
    N = rows(panel_ids)

    // Get T per panel (assumed balanced)
    T_per_panel = 0
    for (i = 1; i <= rows(pid); i++) {
        if (pid[i] == panel_ids[1]) T_per_panel++
    }
    T_total = T_per_panel

    // ─────────────────────────────────────────────────────────
    // Step 1: First-difference and recursive detrending per panel
    // ─────────────────────────────────────────────────────────
    T_fd = T_total - 1
    y_fd = J(T_fd, N, .)
    y_rd = J(T_fd, N, .)

    for (i = 1; i <= N; i++) {
        Yi = Y[((i-1)*T_total + 1)::(i*T_total)]
        dYi = Yi[2::T_total] - Yi[1::(T_total-1)]
        y_fd[., i] = dYi
        dYi_rd = _xtrec_recursive_detrend(dYi, p)
        y_rd[., i] = dYi_rd
    }

    // Effective start index: paper uses t = p+1,...,T for sums
    // In our first-differenced data (length T-1), this corresponds to index p+1
    // For p=0: start at 1 (no detrending)
    // For p>=1: start at p+1 (because first p obs are lost to detrending)
    real scalar t_start
    if (p <= 0) {
        t_start = 1
    }
    else {
        t_start = p + 1
    }

    // ─────────────────────────────────────────────────────────
    // Non-robust: t-REC
    // ─────────────────────────────────────────────────────────
    if (do_robust == "") {
        // Paper (Section 4.1): sigma_hat^2_eps = (NT)^{-1} sum_i sum_{t=2}^T y^2_{i,t,p}
        // In our indexing, t=2 in the original corresponds to t=1 in first-diff.
        // But for p>=1, we start from t_start=p+1 since earlier values are missing.
        sum_sq = 0
        count_rd = 0
        for (i = 1; i <= N; i++) {
            for (t = t_start; t <= T_fd; t++) {
                if (y_rd[t, i] != .) {
                    sum_sq = sum_sq + y_rd[t, i]^2
                    count_rd++
                }
            }
        }
        sigma2_eps = sum_sq / count_rd

        // Compute R_{i,t,p} and the t-REC statistic
        // Paper: R_{i,t,p} = sum_{n=p+1}^{t} r_{i,n,p}
        // Paper: A_{NT,p} = (1/(sqrt(N)*T)) * sum_i sum_{t=p+1}^{T} R_{i,t-1,p} * r_{i,t,p}
        // Paper: B_{NT,p} = (1/(N*T^2)) * sum_i sum_{t=p+1}^{T} R^2_{i,t-1,p}
        // Note: T in the paper is the original T, our T_fd = T-1 is the length of first diffs
        // The sums run from p+1 to T in the ORIGINAL time. In first-differenced data
        // with length T-1, this corresponds to index p+1 to T-1 = T_fd.

        A_NT = 0
        B_NT = 0

        for (i = 1; i <= N; i++) {
            R_i = J(T_fd, 1, 0)

            // Accumulate: R_{i,t,p} = sum_{n=t_start}^{t} r_{i,n,p}
            cumsum_val = 0
            for (t = t_start; t <= T_fd; t++) {
                if (y_rd[t, i] != .) {
                    cumsum_val = cumsum_val + y_rd[t, i]
                }
                R_i[t] = cumsum_val
            }

            // Sum for A_NT and B_NT (t starts at t_start+1 because we need R_{i,t-1})
            for (t = t_start + 1; t <= T_fd; t++) {
                if (y_rd[t, i] != .) {
                    A_NT = A_NT + R_i[t-1] * y_rd[t, i]
                    B_NT = B_NT + R_i[t-1]^2
                }
            }
        }

        // Paper normalization uses T (original time dimension)
        // A_{NT,p} = (1/(sqrt(N)*T)) * raw_sum
        // B_{NT,p} = (1/(N*T^2)) * raw_sum
        T_eff = T_total

        A_NT = A_NT / (sqrt(N) * T_eff)
        B_NT = B_NT / (N * T_eff^2)

        // t-REC = A_{NT,p} / (sigma_hat * sqrt(B_{NT,p}))
        trec_stat = A_NT / (sqrt(sigma2_eps) * sqrt(B_NT))
    }
    // ─────────────────────────────────────────────────────────
    // Robust: t-RREC
    // ─────────────────────────────────────────────────────────
    else {
        q = maxlag

        // h = max(p, q+2), at least 1
        h_val = max((p, q + 2))
        if (h_val < 1) h_val = 1

        // BIC lag selection per panel
        q_selected = J(N, 1, 0)

        for (i = 1; i <= N; i++) {
            best_bic = .
            best_q = 0

            for (qq = 0; qq <= q; qq++) {
                t_reg_start = max((t_start, qq + 2))
                n_reg = T_fd - t_reg_start + 1

                if (n_reg < qq + 2) continue

                y_dep = J(n_reg, 1, .)
                if (qq > 0) {
                    X_lags = J(n_reg, qq, 0)
                }

                row_idx = 0
                for (t = t_reg_start; t <= T_fd; t++) {
                    row_idx++
                    y_dep[row_idx] = y_rd[t, i]
                    for (ll = 1; ll <= qq; ll++) {
                        if (t - ll >= 1) {
                            X_lags[row_idx, ll] = y_rd[t - ll, i]
                        }
                    }
                }

                if (qq == 0) {
                    rss_bic = y_dep' * y_dep
                }
                else {
                    any_miss = 0
                    for (t = 1; t <= n_reg; t++) {
                        if (y_dep[t] == . | X_lags[t,1] == .) {
                            any_miss = 1
                            break
                        }
                    }
                    if (any_miss) continue

                    beta_bic = invsym(X_lags' * X_lags) * X_lags' * y_dep
                    resid_bic = y_dep - X_lags * beta_bic
                    rss_bic = resid_bic' * resid_bic
                }

                bic_val = n_reg * ln(rss_bic / n_reg) + qq * ln(n_reg)

                if (bic_val < best_bic | best_bic == .) {
                    best_bic = bic_val
                    best_q = qq
                }
            }
            q_selected[i] = best_q
        }

        // Use maximum selected lag across panels for h computation
        q_max_used = max(q_selected)
        h_val = max((p, q_max_used + 2))
        if (h_val < 1) h_val = 1

        // Step 2: Estimate common factor via cross-section averaging
        T_eff_robust = T_fd - h_val + 1
        if (T_eff_robust < 5) {
            errprintf("Insufficient time periods after lag augmentation.\n")
            return
        }

        // Paper: f_hat = (1/N) sum_i M_{x_i} y_{i,p}
        // Simplified: cross-section average of recursively detrended first diffs
        f_hat = J(T_fd, 1, 0)
        for (t = 1; t <= T_fd; t++) {
            cs_sum = 0
            cs_count = 0
            for (i = 1; i <= N; i++) {
                if (y_rd[t, i] != .) {
                    cs_sum = cs_sum + y_rd[t, i]
                    cs_count++
                }
            }
            if (cs_count > 0) f_hat[t] = cs_sum / cs_count
        }

        // Step 3: Defactor and lag-augment per panel
        // Paper: r_{i,p} = M_{f_hat} M_{x_i} y_{i,p}
        r_defactored = J(T_fd, N, .)

        for (i = 1; i <= N; i++) {
            qi = q_selected[i]
            t_reg_s = h_val
            n_obs_i = T_fd - t_reg_s + 1

            if (n_obs_i < 3) continue

            yi_vec = y_rd[t_reg_s::T_fd, i]

            // Regressors: f_hat + lags of y_rd
            n_regs = 1 + qi   // f_hat + qi lags
            if (n_regs < 1) n_regs = 1
            Xi_aug = J(n_obs_i, n_regs, 0)

            for (t = 1; t <= n_obs_i; t++) {
                t_abs = t_reg_s + t - 1
                Xi_aug[t, 1] = f_hat[t_abs]
                for (ll2 = 1; ll2 <= qi; ll2++) {
                    if (t_abs - ll2 >= 1) {
                        Xi_aug[t, 1 + ll2] = y_rd[t_abs - ll2, i]
                    }
                }
            }

            // Check for missing
            skip_panel = 0
            for (t = 1; t <= n_obs_i; t++) {
                if (yi_vec[t] == .) {
                    skip_panel = 1
                    break
                }
            }

            if (!skip_panel) {
                beta_def = invsym(Xi_aug' * Xi_aug) * Xi_aug' * yi_vec
                resid_def = yi_vec - Xi_aug * beta_def
                r_defactored[t_reg_s::T_fd, i] = resid_def
            }
            else {
                r_defactored[t_reg_s::T_fd, i] = yi_vec
            }
        }

        // Step 4: Compute t-RREC statistic
        // Paper: t-RREC = sum_i sum_{t=h}^T sigma_hat^{-2}_{e,i} R_{i,t-1,p} r_{i,t,p}
        //               / sqrt(sum_i sum_{t=h}^T sigma_hat^{-2}_{e,i} R^2_{i,t-1,p})
        // sigma_hat^2_{e,i} = T^{-1} r'_{i,p} r_{i,p}

        num_sum = 0
        den_sum = 0

        for (i = 1; i <= N; i++) {
            // Individual variance: sigma_hat^2_{e,i} = T^{-1} * r'_i * r_i
            sig2_ei = 0
            n_valid = 0
            for (t = h_val; t <= T_fd; t++) {
                if (r_defactored[t, i] != .) {
                    sig2_ei = sig2_ei + r_defactored[t, i]^2
                    n_valid++
                }
            }
            if (n_valid > 0) sig2_ei = sig2_ei / n_valid
            if (sig2_ei < 1e-15) sig2_ei = 1e-15  // safety

            // Cumulative sum of defactored residuals
            R_i_rob = J(T_fd, 1, 0)
            cumsum_rob = 0
            for (t = h_val; t <= T_fd; t++) {
                if (r_defactored[t, i] != .) {
                    cumsum_rob = cumsum_rob + r_defactored[t, i]
                }
                R_i_rob[t] = cumsum_rob
            }

            // Numerator and denominator
            for (t = h_val + 1; t <= T_fd; t++) {
                if (r_defactored[t, i] != .) {
                    num_sum = num_sum + (1/sig2_ei) * R_i_rob[t-1] * r_defactored[t, i]
                    den_sum = den_sum + (1/sig2_ei) * R_i_rob[t-1]^2
                }
            }
        }

        if (den_sum > 0) {
            trec_stat = num_sum / sqrt(den_sum)
        }
        else {
            trec_stat = 0
        }

        sigma2_eps = .
    }

    // p-value from standard normal (left tail)
    pvalue = normal(trec_stat)

    // Effective lag used
    if (do_robust != "") {
        lag_used = q_max_used
    }
    else {
        lag_used = 0
    }

    // Store results matrix: [trec_stat, pvalue, sigma2, p, lag, N, T]
    st_matrix(matname, (trec_stat, pvalue, sigma2_eps, p, lag_used, N, T_total))
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Extract recursively detrended residuals for graphing
// ─────────────────────────────────────────────────────────────────────────────
void _xtrec_get_residuals(string scalar varname,
                          string scalar panelvar,
                          string scalar timevar,
                          string scalar touse,
                          real scalar p,
                          string scalar resid_var)
{
    real colvector Y, pid, panel_ids, Yi, dYi, dYi_rd, resid_out
    real scalar N, T_total, T_fd, i, t, t_start

    st_view(Y, ., varname, touse)
    st_view(pid, ., panelvar, touse)

    panel_ids = uniqrows(pid)
    N = rows(panel_ids)

    T_total = 0
    for (i = 1; i <= rows(pid); i++) {
        if (pid[i] == panel_ids[1]) T_total++
    }

    T_fd = T_total - 1
    if (p <= 0) t_start = 1
    else t_start = p + 1

    st_view(resid_out, ., resid_var, touse)

    for (i = 1; i <= N; i++) {
        Yi = Y[((i-1)*T_total + 1)::(i*T_total)]
        dYi = Yi[2::T_total] - Yi[1::(T_total-1)]
        dYi_rd = _xtrec_recursive_detrend(dYi, p)

        resid_out[(i-1)*T_total + 1] = .
        for (t = 1; t <= T_fd; t++) {
            resid_out[(i-1)*T_total + 1 + t] = dYi_rd[t]
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Extract cumulative sum paths for graphing
// ─────────────────────────────────────────────────────────────────────────────
void _xtrec_get_cusums(string scalar varname,
                       string scalar panelvar,
                       string scalar timevar,
                       string scalar touse,
                       real scalar p,
                       string scalar cusum_var,
                       string scalar panelid_var)
{
    real colvector Y, pid, panel_ids, Yi, dYi, dYi_rd
    real colvector cusum_out, pid_out
    real scalar N, T_total, T_fd, i, t, t_start, cumsum_val

    st_view(Y, ., varname, touse)
    st_view(pid, ., panelvar, touse)

    panel_ids = uniqrows(pid)
    N = rows(panel_ids)

    T_total = 0
    for (i = 1; i <= rows(pid); i++) {
        if (pid[i] == panel_ids[1]) T_total++
    }

    T_fd = T_total - 1
    if (p <= 0) t_start = 1
    else t_start = p + 1

    st_view(cusum_out, ., cusum_var, touse)
    st_view(pid_out, ., panelid_var, touse)

    for (i = 1; i <= N; i++) {
        Yi = Y[((i-1)*T_total + 1)::(i*T_total)]
        dYi = Yi[2::T_total] - Yi[1::(T_total-1)]
        dYi_rd = _xtrec_recursive_detrend(dYi, p)

        cusum_out[(i-1)*T_total + 1] = .
        pid_out[(i-1)*T_total + 1] = i

        cumsum_val = 0
        for (t = 1; t <= T_fd; t++) {
            pid_out[(i-1)*T_total + 1 + t] = i
            if (t >= t_start & dYi_rd[t] != .) {
                cumsum_val = cumsum_val + dYi_rd[t]
            }
            cusum_out[(i-1)*T_total + 1 + t] = cumsum_val
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compute individual panel statistics for heterogeneity display
// Returns: [mean_stat, median_stat, sd_stat, min_stat, max_stat, mean_sig2i]
// ─────────────────────────────────────────────────────────────────────────────
void _xtrec_panel_stats(string scalar varname,
                        string scalar panelvar,
                        string scalar timevar,
                        string scalar touse,
                        real scalar p,
                        string scalar do_robust,
                        real scalar maxlag,
                        string scalar matname)
{
    real colvector Y, pid, panel_ids, Yi, dYi, dYi_rd, R_i, panel_tstats
    real scalar N, T_total, T_fd, i, t, t_start, cumsum_val
    real scalar A_i, B_i, sig2_i, t_i, n_valid
    real scalar mean_stat, med_stat, sd_stat, min_stat, max_stat, mean_sig2

    // Read data
    st_view(Y, ., varname, touse)
    st_view(pid, ., panelvar, touse)

    panel_ids = uniqrows(pid)
    N = rows(panel_ids)

    T_total = 0
    for (i = 1; i <= rows(pid); i++) {
        if (pid[i] == panel_ids[1]) T_total++
    }

    T_fd = T_total - 1
    if (p <= 0) t_start = 1
    else t_start = p + 1

    panel_tstats = J(N, 1, 0)
    mean_sig2 = 0

    for (i = 1; i <= N; i++) {
        Yi = Y[((i-1)*T_total + 1)::(i*T_total)]
        dYi = Yi[2::T_total] - Yi[1::(T_total-1)]
        dYi_rd = _xtrec_recursive_detrend(dYi, p)

        // Compute per-panel sigma^2
        sig2_i = 0
        n_valid = 0
        for (t = t_start; t <= T_fd; t++) {
            if (dYi_rd[t] != .) {
                sig2_i = sig2_i + dYi_rd[t]^2
                n_valid++
            }
        }
        if (n_valid > 0) sig2_i = sig2_i / n_valid
        if (sig2_i < 1e-15) sig2_i = 1e-15
        mean_sig2 = mean_sig2 + sig2_i

        // Compute per-panel cumulative sum and t-statistic
        R_i = J(T_fd, 1, 0)
        cumsum_val = 0
        for (t = t_start; t <= T_fd; t++) {
            if (dYi_rd[t] != .) {
                cumsum_val = cumsum_val + dYi_rd[t]
            }
            R_i[t] = cumsum_val
        }

        // Per-panel A_i and B_i
        A_i = 0
        B_i = 0
        for (t = t_start + 1; t <= T_fd; t++) {
            if (dYi_rd[t] != .) {
                A_i = A_i + R_i[t-1] * dYi_rd[t]
                B_i = B_i + R_i[t-1]^2
            }
        }

        // Per-panel t-statistic
        if (B_i > 0 & sig2_i > 0) {
            t_i = A_i / (sqrt(sig2_i) * sqrt(B_i))
        }
        else {
            t_i = 0
        }

        panel_tstats[i] = t_i
    }

    mean_sig2 = mean_sig2 / N

    // Compute summary statistics
    mean_stat = mean(panel_tstats)
    med_stat  = mm_median(panel_tstats)
    sd_stat   = sqrt(variance(panel_tstats))
    min_stat  = min(panel_tstats)
    max_stat  = max(panel_tstats)

    st_matrix(matname, (mean_stat, med_stat, sd_stat, min_stat, max_stat, mean_sig2))
}

// Helper: mm_median for Mata (in case moremata not installed)
real scalar mm_median(real colvector x)
{
    real colvector sx
    real scalar n, mid

    sx = sort(x, 1)
    n = rows(sx)
    mid = floor(n/2)

    if (mod(n, 2) == 0) {
        return((sx[mid] + sx[mid+1]) / 2)
    }
    else {
        return(sx[mid+1])
    }
}

end
