*! version 1.0.0  20mar2026  Dr. Merwan Roudane
*! _lrmbounds_estimate: ECM estimation engine for lrmbounds
*! Estimates the conditional ECM from Webb (2019) eq. (5):
*!   Dy_t = c + psi_yy*y_{t-1} + psi_yx*x_{t-1} + sum(delta_i*Dz_{t-i}) + u_t

capture program drop _lrmbounds_estimate
program define _lrmbounds_estimate, rclass
    syntax varlist(ts min=2) [if] [in], [     ///
        MAXLAG(integer 4)                      ///
        LAGSEL(string)                         ///
        LAGS(numlist integer >=0)               ///
        TREND                                  ///
        NOCONStant                             ///
        ROBUST                                 ///
        ]
    
    marksample touse
    
    * Parse dependent and independent variables
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'
    
    if `nindep' < 1 {
        di as err "At least one independent variable required"
        exit 198
    }
    
    * Lag selection
    if "`lagsel'" == "" local lagsel "bic"
    local lagsel = lower("`lagsel'")
    
    * ================================================================
    *  Step 1: Determine optimal lag length if not specified
    * ================================================================
    if "`lags'" == "" {
        * Use information criteria to select lag length
        local bestlag = 1
        local bestic = .
        
        forvalues p = 1/`maxlag' {
            * Build regressor list for lag p
            local reglist ""
            
            * Lagged levels: y_{t-1}, x_{t-1}
            local reglist "`reglist' L.`depvar'"
            foreach xv of local indepvars {
                local reglist "`reglist' L.`xv'"
            }
            
            * Short-run dynamics: Dy_{t-i}, Dx_{t-i} for i=1,...,p-1
            * And contemporaneous Dx_t
            foreach xv of local indepvars {
                local reglist "`reglist' D.`xv'"
            }
            if `p' > 1 {
                forvalues i = 1/`=`p'-1' {
                    local reglist "`reglist' L`i'D.`depvar'"
                    foreach xv of local indepvars {
                        local reglist "`reglist' L`i'D.`xv'"
                    }
                }
            }
            
            * Add trend if requested
            if "`trend'" != "" {
                tempvar tvar
                qui gen double `tvar' = _n if `touse'
                local reglist "`reglist' `tvar'"
            }
            
            * Estimate
            capture qui regress D.`depvar' `reglist' if `touse', `noconstant'
            if _rc continue
            
            local N = e(N)
            local k_est = e(rank)
            local rss = e(rss)
            
            if "`lagsel'" == "aic" {
                local ic = `N' * ln(`rss'/`N') + 2 * `k_est'
            }
            else {
                * BIC (default)
                local ic = `N' * ln(`rss'/`N') + ln(`N') * `k_est'
            }
            
            if missing(`bestic') | (`ic' < `bestic') {
                local bestic = `ic'
                local bestlag = `p'
            }
        }
        local optlag = `bestlag'
    }
    else {
        * User specified lags
        local optlag : word 1 of `lags'
    }
    
    * ================================================================
    *  Step 2: Construct the regressor list for optimal lag
    * ================================================================
    local ecm_levels ""
    local ecm_diffs ""
    local allregs ""
    
    * Lagged levels (the ECM terms): y_{t-1} and x_{t-1}
    local ecm_levels "L.`depvar'"
    foreach xv of local indepvars {
        local ecm_levels "`ecm_levels' L.`xv'"
    }
    
    * Short-run dynamics
    * Contemporaneous changes in x
    foreach xv of local indepvars {
        local ecm_diffs "`ecm_diffs' D.`xv'"
    }
    * Lagged differences
    if `optlag' > 1 {
        forvalues i = 1/`=`optlag'-1' {
            local ecm_diffs "`ecm_diffs' L`i'D.`depvar'"
            foreach xv of local indepvars {
                local ecm_diffs "`ecm_diffs' L`i'D.`xv'"
            }
        }
    }
    
    * Trend variable
    local trendvar ""
    if "`trend'" != "" {
        tempvar tvar
        qui gen double `tvar' = _n if `touse'
        local trendvar "`tvar'"
    }
    
    * Full regressor list
    local allregs "`ecm_levels' `ecm_diffs' `trendvar'"
    
    * ================================================================
    *  Step 3: Estimate the ECM by OLS
    * ================================================================
    if "`robust'" != "" {
        qui regress D.`depvar' `allregs' if `touse', `noconstant' vce(robust)
    }
    else {
        qui regress D.`depvar' `allregs' if `touse', `noconstant'
    }
    
    * Save estimation results
    local N = e(N)
    local k_total = e(rank)
    local r2 = e(r2)
    local r2_a = e(r2_a)
    local rmse = e(rmse)
    local rss = e(rss)
    local F_model = e(F)
    local ll = e(ll)
    
    * ================================================================
    *  Step 4: Extract ECM coefficients
    * ================================================================
    * Error correction rate: psi_yy = coefficient on L.depvar
    local ecr = _b[L.`depvar']
    local ecr_se = _se[L.`depvar']
    local ecr_t = `ecr' / `ecr_se'
    local ecr_p = 2 * ttail(`N' - `k_total', abs(`ecr_t'))
    
    * Coefficients on lagged levels of x: psi_yx
    local j = 0
    foreach xv of local indepvars {
        local ++j
        local psi_yx_`j' = _b[L.`xv']
        local psi_yx_se_`j' = _se[L.`xv']
        local psi_yx_t_`j' = `psi_yx_`j'' / `psi_yx_se_`j''
        local psi_yx_p_`j' = 2 * ttail(`N' - `k_total', abs(`psi_yx_t_`j''))
    }
    
    * ================================================================
    *  Step 5: Compute LRMs via delta method
    *  LRM_j = -psi_yx_j / psi_yy  (Webb 2019, eq. 8)
    * ================================================================
    * Save coefficient vector and VCV matrix
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    
    local j = 0
    foreach xv of local indepvars {
        local ++j
        * LRM = -psi_yx / psi_yy
        local lrm_`j' = -`psi_yx_`j'' / `ecr'
        
        * Delta method SE:
        * Var(LRM) = (1/psi_yy^2) * Var(psi_yx) + (psi_yx^2/psi_yy^4) * Var(psi_yy)
        *          + 2 * (-psi_yx/psi_yy^3) * Cov(psi_yx, psi_yy)
        * 
        * Partial derivatives:
        *   d(LRM)/d(psi_yx) = -1/psi_yy
        *   d(LRM)/d(psi_yy) = psi_yx/psi_yy^2
        
        * Find positions in coefficient vector
        local pos_yy = colnumb(`b', "L.`depvar'")
        local pos_xj = colnumb(`b', "L.`xv'")
        
        local var_yy = `V'[`pos_yy', `pos_yy']
        local var_xj = `V'[`pos_xj', `pos_xj']
        local cov_xy = `V'[`pos_xj', `pos_yy']
        
        local g1 = -1 / `ecr'
        local g2 = `psi_yx_`j'' / (`ecr' * `ecr')
        
        local var_lrm = `g1'^2 * `var_xj' + `g2'^2 * `var_yy' + 2 * `g1' * `g2' * `cov_xy'
        local lrm_se_`j' = sqrt(`var_lrm')
        local lrm_t_`j' = `lrm_`j'' / `lrm_se_`j''
        local lrm_p_`j' = 2 * ttail(`N' - `k_total', abs(`lrm_t_`j''))
    }
    
    * ================================================================
    *  Return results
    * ================================================================
    return scalar N = `N'
    return scalar k = `nindep'
    return scalar optlag = `optlag'
    return scalar r2 = `r2'
    return scalar r2_a = `r2_a'
    return scalar rmse = `rmse'
    return scalar rss = `rss'
    return scalar ll = `ll'
    return scalar F_model = `F_model'
    return scalar k_total = `k_total'
    
    * ECR
    return scalar ecr = `ecr'
    return scalar ecr_se = `ecr_se'
    return scalar ecr_t = `ecr_t'
    return scalar ecr_p = `ecr_p'
    
    * LRMs
    return scalar nindep = `nindep'
    local j = 0
    foreach xv of local indepvars {
        local ++j
        return scalar lrm_`j' = `lrm_`j''
        return scalar lrm_se_`j' = `lrm_se_`j''
        return scalar lrm_t_`j' = `lrm_t_`j''
        return scalar lrm_p_`j' = `lrm_p_`j''
        return scalar psi_yx_`j' = `psi_yx_`j''
        return scalar psi_yx_se_`j' = `psi_yx_se_`j''
        return local xvar_`j' "`xv'"
    }
    
    return local depvar "`depvar'"
    return local indepvars "`indepvars'"
    return local ecm_levels "`ecm_levels'"
    return local ecm_diffs "`ecm_diffs'"
    return local allregs "`allregs'"
    return local trendvar "`trendvar'"
    return local lagsel "`lagsel'"
    return local hasrobust "`robust'"
    return local hastrend "`trend'"
end
