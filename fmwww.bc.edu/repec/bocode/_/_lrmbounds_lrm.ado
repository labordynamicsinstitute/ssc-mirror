*! version 1.0.0  20mar2026  Dr. Merwan Roudane
*! _lrmbounds_lrm: LRM bounds test from Webb, Linn & Lebo (2019)
*! Computes LRMs and applies the critical-value bounds (Tables 3-6)
*! Also supports Bewley (1979) IV regression as alternative SE estimator

capture program drop _lrmbounds_lrm
program define _lrmbounds_lrm, rclass
    syntax varlist(ts min=2) [if] [in], [     ///
        OPTLAG(integer 1)                      ///
        TREND                                  ///
        NOCONStant                             ///
        ROBUST                                 ///
        BEWLEY                                 ///
        ALPHA(real 0.05)                       ///
        ]
    
    marksample touse
    
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'
    
    * ================================================================
    *  Step 1: ECM estimation (same as in _lrmbounds_estimate)
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
    
    * Estimate ECM
    if "`robust'" != "" {
        qui regress D.`depvar' `allregs' if `touse', `noconstant' vce(robust)
    }
    else {
        qui regress D.`depvar' `allregs' if `touse', `noconstant'
    }
    
    local N = e(N)
    local k_total = e(rank)
    local df_r = e(df_r)
    
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    
    * ECR
    local ecr = _b[L.`depvar']
    local ecr_se = _se[L.`depvar']
    
    * ================================================================
    *  Step 2: Compute LRMs via delta method (Webb 2019, eq. 8, 12)
    * ================================================================
    local j = 0
    foreach xv of local indepvars {
        local ++j
        
        local psi_yx = _b[L.`xv']
        local psi_yx_se = _se[L.`xv']
        
        * LRM_j = -psi_yx_j / psi_yy
        local lrm = -`psi_yx' / `ecr'
        
        * Delta method variance (Webb 2019, following eq. 12)
        local pos_yy = colnumb(`b', "L.`depvar'")
        local pos_xj = colnumb(`b', "L.`xv'")
        
        local var_yy = `V'[`pos_yy', `pos_yy']
        local var_xj = `V'[`pos_xj', `pos_xj']
        local cov_xy = `V'[`pos_xj', `pos_yy']
        
        * Gradients: g1 = d(LRM)/d(psi_yx) = -1/psi_yy
        *            g2 = d(LRM)/d(psi_yy) = psi_yx/psi_yy^2
        local g1 = -1 / `ecr'
        local g2 = `psi_yx' / (`ecr' * `ecr')
        
        local var_lrm = `g1'^2 * `var_xj' + `g2'^2 * `var_yy' + 2 * `g1' * `g2' * `cov_xy'
        local lrm_se = sqrt(max(`var_lrm', 0))
        local lrm_t = `lrm' / `lrm_se'
        
        * Store delta method results
        local dm_lrm_`j' = `lrm'
        local dm_se_`j' = `lrm_se'
        local dm_t_`j' = `lrm_t'
    }
    
    * ================================================================
    *  Step 3: Bewley (1979) IV regression (if requested)
    *  Webb (2019) eq. (13-14): Regress y_t on x_t using
    *  {constant, Dx_t, Dz_{t-i}} as instruments
    *  This directly gives LRM as coefficient on x_t
    * ================================================================
    if "`bewley'" != "" {
        * Build instrument list: constant, Dx_t, lagged differences
        local instruments ""
        foreach xv of local indepvars {
            local instruments "`instruments' D.`xv'"
        }
        if `optlag' > 1 {
            forvalues i = 1/`=`optlag'-1' {
                local instruments "`instruments' L`i'D.`depvar'"
                foreach xv of local indepvars {
                    local instruments "`instruments' L`i'D.`xv'"
                }
            }
        }
        if "`trend'" != "" {
            local instruments "`instruments' `trendvar'"
        }
        
        * IV regression: y_t = theta_0 + theta_j*x_{j,t} + ...
        * Instrumented variables: x_t (levels of independent vars)
        * Instruments: Dx_t, lagged Dz, constant
        
        * Using the Bewley transformation:
        * y_t = c/(-psi_yy) + LRM_j*x_{j,t} + [short-run dynamics/(-psi_yy)] + v_t
        * The coefficient on x_{j,t} is directly the LRM_j
        
        * Construct the IV regression manually
        * Endogenous: levels of x
        * Exogenous: constant, differences
        capture qui ivregress 2sls `depvar' `ecm_diffs' `trendvar' ///
            (`indepvars' = `instruments' D.`depvar') if `touse', `noconstant'
        
        if !_rc {
            local j = 0
            foreach xv of local indepvars {
                local ++j
                local bw_lrm_`j' = _b[`xv']
                local bw_se_`j' = _se[`xv']
                local bw_t_`j' = `bw_lrm_`j'' / `bw_se_`j''
            }
            local bewley_ok = 1
        }
        else {
            local bewley_ok = 0
        }
    }
    else {
        local bewley_ok = 0
    }
    
    * ================================================================
    *  Step 4: Apply Webb (2019) Table 6 bounds
    *  Compare |t_LRM| to the critical value bounds
    * ================================================================
    _lrmbounds_cv_lrm_lookup, k(`nindep') nobs(`N') alpha(`alpha')
    local cv_lb = r(lb)
    local cv_ub = r(ub)
    
    * Also get bounds at other significance levels
    foreach a in 0.01 0.05 0.10 {
        _lrmbounds_cv_lrm_lookup, k(`nindep') nobs(`N') alpha(`a')
        local cv_lb_`=100*`a'' = r(lb)
        local cv_ub_`=100*`a'' = r(ub)
    }
    
    * Make decisions for each LRM
    local j = 0
    foreach xv of local indepvars {
        local ++j
        
        * Use delta method t-stat (or Bewley if available)
        if `bewley_ok' {
            local use_t = abs(`bw_t_`j'')
        }
        else {
            local use_t = abs(`dm_t_`j'')
        }
        
        if `use_t' > `cv_ub' {
            local lrm_decision_`j' "Reject H0: Significant LRR"
            local lrm_dcode_`j' "reject"
        }
        else if `use_t' < `cv_lb' {
            local lrm_decision_`j' "Fail to Reject H0: No LRR"
            local lrm_dcode_`j' "fail"
        }
        else {
            local lrm_decision_`j' "Inconclusive"
            local lrm_dcode_`j' "inconclusive"
        }
    }
    
    * ================================================================
    *  Return results
    * ================================================================
    return scalar N = `N'
    return scalar k = `nindep'
    return scalar alpha = `alpha'
    return scalar ecr = `ecr'
    return scalar ecr_se = `ecr_se'
    
    * Webb bounds
    return scalar cv_lb = `cv_lb'
    return scalar cv_ub = `cv_ub'
    return scalar cv_lb_1 = `cv_lb_1'
    return scalar cv_ub_1 = `cv_ub_1'
    return scalar cv_lb_5 = `cv_lb_5'
    return scalar cv_ub_5 = `cv_ub_5'
    return scalar cv_lb_10 = `cv_lb_10'
    return scalar cv_ub_10 = `cv_ub_10'
    
    * LRM results per variable
    local j = 0
    foreach xv of local indepvars {
        local ++j
        return scalar dm_lrm_`j' = `dm_lrm_`j''
        return scalar dm_se_`j' = `dm_se_`j''
        return scalar dm_t_`j' = `dm_t_`j''
        if `bewley_ok' {
            return scalar bw_lrm_`j' = `bw_lrm_`j''
            return scalar bw_se_`j' = `bw_se_`j''
            return scalar bw_t_`j' = `bw_t_`j''
        }
        return local lrm_decision_`j' "`lrm_decision_`j''"
        return local lrm_dcode_`j' "`lrm_dcode_`j''"
        return local xvar_`j' "`xv'"
    }
    
    return scalar bewley_ok = `bewley_ok'
    return local depvar "`depvar'"
    return local indepvars "`indepvars'"
end
