*! version 1.0.0  20mar2026  Dr. Merwan Roudane
*! _lrmbounds_ftest: PSS F-bounds test and ECR t-bounds test
*! Implements the Pesaran, Shin & Smith (2001) bounds testing approach
*! as used in Webb, Linn & Lebo (2019, 2020)

capture program drop _lrmbounds_ftest
program define _lrmbounds_ftest, rclass
    syntax varlist(ts min=2) [if] [in], [     ///
        OPTLAG(integer 1)                      ///
        TREND                                  ///
        NOCONStant                             ///
        ROBUST                                 ///
        ]
    
    marksample touse
    
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'
    
    * ================================================================
    *  Step 1: Estimate UNRESTRICTED ECM
    *  Dy_t = c + psi_yy*y_{t-1} + psi_yx*x_{t-1} + short_run + u_t
    * ================================================================
    local ecm_levels "L.`depvar'"
    foreach xv of local indepvars {
        local ecm_levels "`ecm_levels' L.`xv'"
    }
    
    local ecm_diffs ""
    foreach xv of local indepvars {
        local ecm_diffs "`ecm_diffs' D.`xv'"
    }
    if `optlag' > 1 {
        forvalues i = 1/`=`optlag'-1' {
            local ecm_diffs "`ecm_diffs' L`i'D.`depvar'"
            foreach xv of local indepvars {
                local ecm_diffs "`ecm_diffs' L`i'D.`xv'"
            }
        }
    }
    
    local trendvar ""
    if "`trend'" != "" {
        tempvar tvar
        qui gen double `tvar' = _n if `touse'
        local trendvar "`tvar'"
    }
    
    local allregs "`ecm_levels' `ecm_diffs' `trendvar'"
    
    if "`robust'" != "" {
        qui regress D.`depvar' `allregs' if `touse', `noconstant' vce(robust)
    }
    else {
        qui regress D.`depvar' `allregs' if `touse', `noconstant'
    }
    
    local N_u = e(N)
    local k_u = e(rank)
    local rss_u = e(rss)
    local df_u = e(df_r)
    
    * Save ECR coefficient for t-test
    local ecr = _b[L.`depvar']
    local ecr_se = _se[L.`depvar']
    local ecr_t = `ecr' / `ecr_se'
    
    * ================================================================
    *  Step 2: Estimate RESTRICTED model (drop all lagged levels)
    *  H0: psi_yy = psi_yx = 0 (no level relationship)
    * ================================================================
    if "`robust'" != "" {
        qui regress D.`depvar' `ecm_diffs' `trendvar' if `touse', `noconstant' vce(robust)
    }
    else {
        qui regress D.`depvar' `ecm_diffs' `trendvar' if `touse', `noconstant'
    }
    
    local rss_r = e(rss)
    local k_r = e(rank)
    
    * ================================================================
    *  Step 3: Compute joint F-statistic
    *  F = [(RSS_r - RSS_u) / q] / [RSS_u / (N - k_u)]
    *  where q = number of restrictions = k+1 (psi_yy + k psi_yx's)
    * ================================================================
    local q = `nindep' + 1  /* psi_yy + psi_yx_1 + ... + psi_yx_k */
    local F_pss = ((`rss_r' - `rss_u') / `q') / (`rss_u' / `df_u')
    
    * ================================================================
    *  Step 4: Look up F-bounds critical values
    * ================================================================
    local case = cond("`trend'" != "", 5, 3)
    
    foreach alpha in 0.01 0.05 0.10 {
        _lrmbounds_cv_ftest, k(`nindep') case(`case') alpha(`alpha') nobs(`N_u')
        local f_lb_`=100*`alpha'' = r(lb)
        local f_ub_`=100*`alpha'' = r(ub)
    }
    
    * F-test decision at 5% level
    if `F_pss' > `f_ub_5' {
        local f_decision "Reject H0: Evidence of a level relationship"
        local f_dcode "reject"
    }
    else if `F_pss' < `f_lb_5' {
        local f_decision "Fail to Reject H0: No evidence of a level relationship"
        local f_dcode "fail"
    }
    else {
        local f_decision "Inconclusive: F-statistic falls between bounds"
        local f_dcode "inconclusive"
    }
    
    * ================================================================
    *  Step 5: ECR t-bounds test (PSS Table CII)
    *  Tests H0: psi_yy = 0 (no error correction)
    * ================================================================
    foreach alpha in 0.01 0.05 0.10 {
        _lrmbounds_cv_ttest_ecr, k(`nindep') case(`case') alpha(`alpha')
        local t_lb_`=100*`alpha'' = r(lb)
        local t_ub_`=100*`alpha'' = r(ub)
    }
    
    * ECR t-test decision at 5%
    if abs(`ecr_t') > `t_ub_5' {
        local t_decision "Reject H0: Significant error correction"
        local t_dcode "reject"
    }
    else if abs(`ecr_t') < `t_lb_5' {
        local t_decision "Fail to Reject H0: No error correction"
        local t_dcode "fail"
    }
    else {
        local t_decision "Inconclusive"
        local t_dcode "inconclusive"
    }
    
    * ================================================================
    *  Step 6: Degenerate equilibrium check (Webb 2019, Table 1)
    *  After rejecting F-test, check which alternative holds
    * ================================================================
    local ecr_sig = (abs(`ecr_t') > `t_ub_5')
    
    * Check if any psi_yx is significant
    local any_psi_sig = 0
    local j = 0
    foreach xv of local indepvars {
        local ++j
        * Re-estimate to get coefficients
        qui regress D.`depvar' `allregs' if `touse', `noconstant'
        local psi_t = _b[L.`xv'] / _se[L.`xv']
        local psi_p = 2 * ttail(`df_u', abs(`psi_t'))
        if `psi_p' < 0.05 local any_psi_sig = 1
    }
    
    if "`f_dcode'" == "reject" {
        if `ecr_sig' & `any_psi_sig' {
            local equil_type "Nondegenerate: Valid long-run equilibrium (H_A3)"
            local equil_code "valid"
        }
        else if !`ecr_sig' & `any_psi_sig' {
            local equil_type "Degenerate: Nonsense equilibrium (H_A1)"
            local equil_code "nonsense"
        }
        else if `ecr_sig' & !`any_psi_sig' {
            local equil_type "Degenerate: y is independent of x (H_A2)"
            local equil_code "degenerate"
        }
        else {
            local equil_type "Undefined: Neither psi_yy nor psi_yx significant"
            local equil_code "undefined"
        }
    }
    else {
        local equil_type "N/A (F-test null not rejected)"
        local equil_code "na"
    }
    
    * ================================================================
    *  Return results
    * ================================================================
    return scalar F_pss = `F_pss'
    return scalar N = `N_u'
    return scalar q = `q'
    return scalar case = `case'
    return scalar df_u = `df_u'
    return scalar rss_u = `rss_u'
    return scalar rss_r = `rss_r'
    
    * F-bounds
    return scalar f_lb_1 = `f_lb_1'
    return scalar f_ub_1 = `f_ub_1'
    return scalar f_lb_5 = `f_lb_5'
    return scalar f_ub_5 = `f_ub_5'
    return scalar f_lb_10 = `f_lb_10'
    return scalar f_ub_10 = `f_ub_10'
    
    * ECR t-test
    return scalar ecr = `ecr'
    return scalar ecr_se = `ecr_se'
    return scalar ecr_t = `ecr_t'
    return scalar t_lb_1 = `t_lb_1'
    return scalar t_ub_1 = `t_ub_1'
    return scalar t_lb_5 = `t_lb_5'
    return scalar t_ub_5 = `t_ub_5'
    return scalar t_lb_10 = `t_lb_10'
    return scalar t_ub_10 = `t_ub_10'
    
    * Decisions
    return local f_decision "`f_decision'"
    return local f_dcode "`f_dcode'"
    return local t_decision "`t_decision'"
    return local t_dcode "`t_dcode'"
    return local equil_type "`equil_type'"
    return local equil_code "`equil_code'"
end
