*! dptest v2.0.0 - Multiple Unit Root & Cointegration Tests
*! Dickey-Pantula (1987), Hasza-Fuller (1979), Haldrup (1994 JBES/JoE)
*! Author: Dr. Merwan Roudane
*! Date: 2026-03-14

capture program drop dptest
program define dptest, rclass
    version 14.0
    syntax varlist(min=1) [if] [in], [TEst(string) MAXDiff(integer 3) ///
        MAXLag(integer -1) DET(string) LEvel(integer 5) ///
        BANDwidth(integer -1) I2vars(varlist) GRAPH NOTable ///
        CRIT(string)]
    
    * --- Defaults ---
    if "`test'" == "" local test "all"
    if "`det'" == ""  local det "const"
    if "`crit'" == "" local crit "bic"
    
    * --- Validate ---
    if !inlist("`test'","dp","hf","hz","coint","all") {
        di as err "test() must be dp, hf, hz, coint, or all"
        exit 198
    }
    if !inlist(`level', 1, 5, 10) {
        di as err "level() must be 1, 5, or 10"
        exit 198
    }
    if !inlist("`det'","none","const","trend","qtrend") {
        di as err "det() must be none, const, trend, or qtrend"
        exit 198
    }
    if "`test'" == "coint" & "`i2vars'" == "" {
        di as err "i2vars() required for cointegration test"
        exit 198
    }
    
    * --- Mark sample ---
    marksample touse
    if "`i2vars'" != "" {
        markout `touse' `i2vars'
    }
    
    * --- Get variable ---
    local depvar : word 1 of `varlist'
    local indepvars : list varlist - depvar
    
    * --- Preserve and keep sample ---
    preserve
    qui keep if `touse'
    qui count
    local N = r(N)
    if `N' < 25 {
        di as err "Sample size too small (n=`N'). Need at least 25."
        exit 2001
    }
    
    * --- Default maxlag by Schwert rule ---
    if `maxlag' == -1 {
        local maxlag = int(12 * (`N'/100)^0.25)
    }
    
    * --- Default bandwidth by Schwert rule ---
    if `bandwidth' == -1 {
        local bandwidth = int(4 * (`N'/100)^0.25)
    }
    
    * --- Deterministic label ---
    local det_label "None"
    if "`det'" == "const"   local det_label "Constant"
    if "`det'" == "trend"   local det_label "Constant + Trend"
    if "`det'" == "qtrend"  local det_label "Constant + Quadratic Trend"
    
    * --- Header ---
    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as txt "{bf:dptest} {c -} Multiple Unit Root & Cointegration Tests" ///
           _col(68) "v2.0.0"
        di as txt "{hline 78}"
        di as txt "  Dependent variable" _col(30) "{c |}" ///
           _col(33) as res "`depvar'"
        di as txt "  Sample size" _col(30) "{c |}" ///
           _col(33) as res "`N'"
        di as txt "  Deterministic terms" _col(30) "{c |}" ///
           _col(33) as res "`det_label'"
        di as txt "  Maximum lag order" _col(30) "{c |}" ///
           _col(33) as res "`maxlag'"
        di as txt "  Significance level" _col(30) "{c |}" ///
           _col(33) as res "`level'%"
        if "`test'" == "hz" | "`test'" == "all" {
            di as txt "  Bandwidth (Bartlett)" _col(30) "{c |}" ///
               _col(33) as res "`bandwidth'"
        }
        di as txt "{hline 78}"
    }
    
    * --- Return common values ---
    return scalar N = `N'
    return local depvar "`depvar'"
    return local det "`det'"
    return scalar level = `level'
    return scalar maxlag = `maxlag'
    return scalar bandwidth = `bandwidth'
    
    * ==============================================
    * Run requested tests
    * ==============================================
    
    if "`test'" == "dp" | "`test'" == "all" {
        _dptest_dp `depvar', maxdiff(`maxdiff') maxlag(`maxlag') ///
            det(`det') level(`level') n(`N') `notable'
        return scalar dp_d = r(dp_d)
        forval i = 1/`maxdiff' {
            capture return scalar dp_tstar_`i' = r(dp_tstar_`i')
        }
    }
    
    if "`test'" == "hf" | "`test'" == "all" {
        _dptest_hf `depvar', maxlag(`maxlag') det(`det') ///
            level(`level') n(`N') `notable'
        return scalar hf_F = r(hf_F)
        return scalar hf_d = r(hf_d)
    }
    
    if "`test'" == "hz" | "`test'" == "all" {
        _dptest_hz `depvar', maxlag(`maxlag') det(`det') ///
            level(`level') n(`N') bandwidth(`bandwidth') `notable'
        return scalar hz_ZF = r(hz_ZF)
        return scalar hz_d = r(hz_d)
    }
    
    if "`test'" == "coint" {
        _dptest_coint `depvar', indepvars(`indepvars') ///
            i2vars(`i2vars') maxlag(`maxlag') det(`det') ///
            level(`level') n(`N') `notable'
        return scalar coint_adf = r(coint_adf)
        return scalar coint_cv = r(coint_cv)
        return scalar coint_reject = r(coint_reject)
    }
    
    * --- Graphs ---
    if "`graph'" != "" & "`test'" != "coint" {
        _dptest_graph `depvar', maxdiff(`maxdiff')
    }
    
    * --- Summary ---
    if "`notable'" == "" & "`test'" != "coint" {
        di as txt _n "{hline 78}"
        di as txt "{bf:Summary of Integration Order}"
        di as txt "{hline 78}"
        di as txt _col(5) "Method" _col(50) "Estimated {it:d}"
        di as txt "{hline 78}"
        if "`test'" == "dp" | "`test'" == "all" {
            local dpd = return(dp_d)
            di as txt _col(5) "Sequential t* (Dickey-Pantula)" ///
               _col(50) as res "I(`dpd')"
        }
        if "`test'" == "hf" | "`test'" == "all" {
            local hfd = return(hf_d)
            if `hfd' == 2 {
                di as txt _col(5) "Joint F test (Hasza-Fuller)" ///
                   _col(50) as res "I(2)"
            }
            else {
                di as txt _col(5) "Joint F test (Hasza-Fuller)" ///
                   _col(50) as res "{c <=} I(1)"
            }
        }
        if "`test'" == "hz" | "`test'" == "all" {
            local hzd = return(hz_d)
            if `hzd' == 2 {
                di as txt _col(5) "Semiparametric Z(F*) (Haldrup)" ///
                   _col(50) as res "I(2)"
            }
            else {
                di as txt _col(5) "Semiparametric Z(F*) (Haldrup)" ///
                   _col(50) as res "{c <=} I(1)"
            }
        }
        di as txt "{hline 78}"
    }
    
    restore
end

* ==============================================================================
* SUBPROGRAM 1: Dickey-Pantula Sequential t* Procedure
* ==============================================================================
capture program drop _dptest_dp
program define _dptest_dp, rclass
    syntax varname, maxdiff(integer) maxlag(integer) det(string) ///
        level(integer) n(integer) [NOTable]
    
    local y `varlist'
    tempvar dy ddy
    
    * Generate differences
    qui gen double `dy' = D.`y'
    qui gen double `ddy' = D2.`y'
    
    * --- Fuller (1976) tau critical values ---
    * No constant (tau): 1%, 5%, 10%
    tempname cv_nc cv_c cv_ct
    mat `cv_nc' = (-2.66, -1.95, -1.60)
    mat `cv_c'  = (-3.58, -2.93, -2.60)
    mat `cv_ct' = (-4.15, -3.50, -3.18)
    
    * Adjust for sample size
    if `n' <= 25 {
        mat `cv_nc' = (-2.66, -1.95, -1.60)
        mat `cv_c'  = (-3.75, -3.00, -2.63)
        mat `cv_ct' = (-4.38, -3.60, -3.24)
    }
    else if `n' <= 50 {
        mat `cv_nc' = (-2.62, -1.95, -1.61)
        mat `cv_c'  = (-3.58, -2.93, -2.60)
        mat `cv_ct' = (-4.15, -3.50, -3.18)
    }
    else if `n' <= 100 {
        mat `cv_nc' = (-2.60, -1.95, -1.61)
        mat `cv_c'  = (-3.51, -2.89, -2.58)
        mat `cv_ct' = (-4.04, -3.45, -3.15)
    }
    else if `n' <= 250 {
        mat `cv_nc' = (-2.58, -1.95, -1.62)
        mat `cv_c'  = (-3.46, -2.88, -2.57)
        mat `cv_ct' = (-3.99, -3.43, -3.13)
    }
    else {
        mat `cv_nc' = (-2.58, -1.95, -1.62)
        mat `cv_c'  = (-3.43, -2.86, -2.57)
        mat `cv_ct' = (-3.96, -3.41, -3.13)
    }
    
    * Select CV based on det
    tempname cv_use
    if "`det'" == "none" {
        mat `cv_use' = `cv_nc'
    }
    else if "`det'" == "const" {
        mat `cv_use' = `cv_c'
    }
    else {
        mat `cv_use' = `cv_ct'
    }
    
    * Map level to column
    local cvidx = 2
    if `level' == 1  local cvidx = 1
    if `level' == 10 local cvidx = 3
    local cv_val = `cv_use'[1, `cvidx']
    
    * --- Display header ---
    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as txt "{bf:Panel A: Sequential t* Unit Root Test}"
        di as txt "{hline 78}"
        di as txt "  Null hypothesis: Series contains {it:d} unit roots"
        di as txt "  Testing order: H({it:d_max}) {c ->} H({it:d_max}-1) {c ->} ... {c ->} H(1)"
        di as txt "  Procedure stops at first non-rejection"
        di as txt "{hline 78}"
        di as txt _col(3) "{bf:Step}" _col(15) "{bf:H{sub:0}}" ///
           _col(30) "{bf:t* statistic}" _col(50) "{bf:CV (`level'%)}" ///
           _col(65) "{bf:Decision}"
        di as txt "{hline 78}"
    }
    
    local d_hat = `maxdiff'
    
    * The LHS is always D^maxdiff(Y)
    tempvar lhs_dp
    if `maxdiff' == 3 {
        qui gen double `lhs_dp' = D.`ddy'
    }
    else if `maxdiff' == 2 {
        qui gen double `lhs_dp' = `ddy'
    }
    
    * Generate all needed lagged regressors
    tempvar rY rDY rD2Y
    qui gen double `rY'   = L.`y'
    qui gen double `rDY'  = L.`dy'
    qui gen double `rD2Y' = L.`ddy'
    
    forval step = `maxdiff'(-1)1 {
        
        local key_var ""
        local ctrl_vars ""
        
        if `maxdiff' == 3 {
            if `step' == 3 {
                local key_var "`rD2Y'"
                local ctrl_vars ""
            }
            else if `step' == 2 {
                local key_var "`rDY'"
                local ctrl_vars "`rD2Y'"
            }
            else if `step' == 1 {
                local key_var "`rY'"
                local ctrl_vars "`rDY' `rD2Y'"
            }
        }
        else if `maxdiff' == 2 {
            if `step' == 2 {
                local key_var "`rDY'"
                local ctrl_vars ""
            }
            else if `step' == 1 {
                local key_var "`rY'"
                local ctrl_vars "`rDY'"
            }
        }
        
        * Select augmenting lags by BIC
        local p = min(`maxlag', 4)
        local best_bic = .
        local best_p = 0
        
        forval pp = 0/`p' {
            local auglag ""
            forval j = 1/`pp' {
                tempvar augj_dp_`step'_`j'
                qui gen double `augj_dp_`step'_`j'' = L`j'.`lhs_dp'
                local auglag "`auglag' `augj_dp_`step'_`j''"
            }
            
            local allrhs "`key_var' `ctrl_vars' `auglag'"
            
            capture {
                if "`det'" == "none" {
                    qui reg `lhs_dp' `allrhs', nocons
                }
                else {
                    qui reg `lhs_dp' `allrhs'
                }
            }
            
            if _rc == 0 {
                local this_bic = e(N) * ln(e(rss)/e(N)) + (e(df_m)+1)*ln(e(N))
                if `this_bic' < `best_bic' {
                    local best_bic = `this_bic'
                    local best_p = `pp'
                }
            }
            
            forval j = 1/`pp' {
                capture drop `augj_dp_`step'_`j''
            }
        }
        
        * Re-run with optimal lag
        local augvars_dp ""
        forval j = 1/`best_p' {
            tempvar augfin_`step'_`j'
            qui gen double `augfin_`step'_`j'' = L`j'.`lhs_dp'
            local augvars_dp "`augvars_dp' `augfin_`step'_`j''"
        }
        
        local allrhs "`key_var' `ctrl_vars' `augvars_dp'"
        
        if "`det'" == "none" {
            qui reg `lhs_dp' `allrhs', nocons
        }
        else {
            qui reg `lhs_dp' `allrhs'
        }
        
        * Get t statistic for KEY variable
        local tstar = _b[`key_var'] / _se[`key_var']
        return scalar dp_tstar_`step' = `tstar'
        
        * Decision
        local decision "Do not reject"
        local star ""
        if `tstar' < `cv_val' {
            local decision "Reject"
            local star "***"
            local d_hat = `step' - 1
        }
        
        * Display
        if "`notable'" == "" {
            di as txt _col(3) "`step'" ///
               _col(15) "d = `step'" ///
               _col(30) as res %10.4f `tstar' ///
               _col(50) as res %10.4f `cv_val' ///
               _col(65) as txt "`decision'"
        }
        
        forval j = 1/`best_p' {
            capture drop `augfin_`step'_`j''
        }
        
        * If we don't reject, stop
        if `tstar' >= `cv_val' {
            continue, break
        }
    }
    
    drop `lhs_dp' `rY' `rDY' `rD2Y'
    
    if "`notable'" == "" {
        di as txt "{hline 78}"
        di as txt "  {bf:Conclusion:} The series is integrated of order" ///
           as res " I(`d_hat')"
        if `d_hat' == 0 {
            di as txt "  {it:The series is stationary. No differencing needed.}"
        }
        else if `d_hat' == 1 {
            di as txt "  {it:The series has one unit root. First differencing achieves stationarity.}"
        }
        else if `d_hat' == 2 {
            di as txt "  {it:The series has two unit roots. Second differencing is required.}"
        }
        else {
            di as txt "  {it:The series has `d_hat' unit roots.}"
        }
        di as txt "{hline 78}"
    }
    
    return scalar dp_d = `d_hat'
end

* ==============================================================================
* SUBPROGRAM 2: Hasza-Fuller Joint F Test
* ==============================================================================
capture program drop _dptest_hf
program define _dptest_hf, rclass
    syntax varname, maxlag(integer) det(string) level(integer) ///
        n(integer) [NOTable]
    
    local y `varlist'
    
    * --- Hasza-Fuller Table 4.1: Phi statistics ---
    * Rows: n = {25, 50, 100, 250, 500, inf}
    * Cols: percentiles {.50, .80, .90, .95, .975, .99}
    
    tempname phi1_2
    mat `phi1_2' = ( 0.96, 2.05, 2.89, 3.78, 4.66, 6.01 \ ///
                     0.97, 2.03, 2.82, 3.60, 4.41, 5.52 \ ///
                     0.98, 2.02, 2.78, 3.53, 4.29, 5.31 \ ///
                     0.98, 2.01, 2.76, 3.49, 4.22, 5.20 \ ///
                     0.98, 2.01, 2.76, 3.48, 4.20, 5.17 \ ///
                     0.98, 2.01, 2.75, 3.47, 4.18, 5.14 )
    
    tempname phi2_2
    mat `phi2_2' = ( 2.56, 4.44, 5.78, 7.17, 8.61, 10.55 \ ///
                     2.58, 4.30, 5.47, 6.61, 7.76, 9.22  \ ///
                     2.58, 4.24, 5.33, 6.36, 7.38, 8.65  \ ///
                     2.59, 4.20, 5.25, 6.23, 7.18, 8.36  \ ///
                     2.59, 4.19, 5.22, 6.19, 7.13, 8.28  \ ///
                     2.59, 4.18, 5.21, 6.16, 7.08, 8.22  )
    
    tempname phi3_2
    mat `phi3_2' = ( 4.97, 7.70, 9.54, 11.41, 13.34, 15.88 \ ///
                     4.89, 7.21, 8.75, 10.17, 11.61, 13.43 \ ///
                     4.86, 6.98, 8.36,  9.58, 10.80, 12.31 \ ///
                     4.83, 6.86, 8.13,  9.25, 10.34, 11.70 \ ///
                     4.83, 6.82, 8.05,  9.15, 10.20, 11.52 \ ///
                     4.82, 6.78, 7.98,  9.05, 10.08, 11.37 )
    
    tempname phi_qt
    mat `phi_qt' = ( 7.57, 10.82, 13.11, 15.54, 17.59, 20.73 \ ///
                     7.04,  9.92, 11.77, 13.33, 14.88, 17.01 \ ///
                     6.82,  9.40, 10.93, 12.33, 13.53, 15.24 \ ///
                     6.67,  9.07, 10.54, 11.78, 12.87, 14.45 \ ///
                     6.63,  9.01, 10.39, 11.58, 12.66, 14.18 )
    
    * --- Determine row index based on n ---
    local nvals "25 50 100 250 500"
    local rowidx = 6
    local idx = 1
    foreach nv of local nvals {
        if `n' <= `nv' {
            local rowidx = `idx'
            continue, break
        }
        local idx = `idx' + 1
    }
    if `rowidx' > 5 & "`det'" == "qtrend" {
        local rowidx = 5
    }
    
    local colidx = 4
    if `level' == 1  local colidx = 6
    if `level' == 10 local colidx = 3
    
    * --- Select which Phi statistic to use ---
    local phi_type = ""
    tempname cv_mat
    if "`det'" == "none" {
        mat `cv_mat' = `phi1_2'
        local phi_type "Phi_1(2)"
    }
    else if "`det'" == "const" {
        mat `cv_mat' = `phi2_2'
        local phi_type "Phi_2(2)"
    }
    else if "`det'" == "trend" {
        mat `cv_mat' = `phi3_2'
        local phi_type "Phi_3(2)"
    }
    else if "`det'" == "qtrend" {
        mat `cv_mat' = `phi_qt'
        local phi_type "Phi_QT"
        if `rowidx' > 5 local rowidx = 5
    }
    
    local cv_val = `cv_mat'[`rowidx', `colidx']
    
    * --- Run HF regression ---
    tempvar d2y dy_lag y_lag
    qui gen double `d2y' = D2.`y'
    qui gen double `dy_lag' = L.D.`y'
    qui gen double `y_lag' = L.`y'
    
    * BIC lag selection
    local best_bic = .
    local best_p = 0
    local pmax = min(`maxlag', 8)
    
    forval pp = 0/`pmax' {
        local auglag ""
        forval j = 1/`pp' {
            tempvar atmp`j'
            qui gen double `atmp`j'' = L`j'.`d2y'
            local auglag "`auglag' `atmp`j''"
        }
        
        capture {
            if "`det'" == "none" {
                qui reg `d2y' `y_lag' `dy_lag' `auglag', nocons
            }
            else if "`det'" == "const" {
                qui reg `d2y' `y_lag' `dy_lag' `auglag'
            }
            else if "`det'" == "trend" {
                tempvar tt
                qui gen `tt' = _n
                qui reg `d2y' `y_lag' `dy_lag' `tt' `auglag'
                capture drop `tt'
            }
            else if "`det'" == "qtrend" {
                tempvar tt tt2
                qui gen `tt' = _n
                qui gen `tt2' = _n^2
                qui reg `d2y' `y_lag' `dy_lag' `tt' `tt2' `auglag'
                capture drop `tt' `tt2'
            }
        }
        
        if _rc == 0 {
            local this_bic = e(N)*ln(e(rss)/e(N)) + (e(df_m)+1)*ln(e(N))
            if `this_bic' < `best_bic' {
                local best_bic = `this_bic'
                local best_p = `pp'
            }
        }
        
        forval j = 1/`pp' {
            capture drop `atmp`j''
        }
    }
    
    * Re-run with optimal lag
    local augvars ""
    forval j = 1/`best_p' {
        tempvar augf`j'
        qui gen double `augf`j'' = L`j'.`d2y'
        local augvars "`augvars' `augf`j''"
    }
    
    if "`det'" == "none" {
        qui reg `d2y' `y_lag' `dy_lag' `augvars', nocons
    }
    else if "`det'" == "const" {
        qui reg `d2y' `y_lag' `dy_lag' `augvars'
    }
    else if "`det'" == "trend" {
        tempvar tt
        qui gen `tt' = _n
        qui reg `d2y' `y_lag' `dy_lag' `tt' `augvars'
    }
    else if "`det'" == "qtrend" {
        tempvar tt tt2
        qui gen `tt' = _n
        qui gen `tt2' = _n^2
        qui reg `d2y' `y_lag' `dy_lag' `tt' `tt2' `augvars'
    }
    
    qui test `y_lag' `dy_lag'
    local Fstat = r(F)
    
    local cv1  = `cv_mat'[`rowidx', 6]
    local cv5  = `cv_mat'[`rowidx', 4]
    local cv10 = `cv_mat'[`rowidx', 3]
    
    local hf_d = 2
    if `Fstat' > `cv_val' {
        local hf_d = 1
    }
    
    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as txt "{bf:Panel B: Joint F Test for Double Unit Roots}"
        di as txt "{hline 78}"
        di as txt "  H{sub:0}: {it:alpha} = {it:beta} = 1" ///
           _col(45) "(two unit roots)"
        di as txt "  H{sub:1}: At most one unit root"
        di as txt "  Test statistic: `phi_type'" ///
           _col(45) "Augmentation lags: `best_p'"
        di as txt "{hline 78}"
        di as txt _col(15) "{bf:F statistic}" ///
           _col(35) "{bf:CV 1%}" ///
           _col(48) "{bf:CV 5%}" ///
           _col(61) "{bf:CV 10%}"
        di as txt "{hline 78}"
        di as res _col(15) %10.4f `Fstat' ///
           _col(35) %10.4f `cv1' ///
           _col(48) %10.4f `cv5' ///
           _col(61) %10.4f `cv10'
        di as txt "{hline 78}"
        if `hf_d' == 2 {
            di as txt "  {bf:Conclusion:} Cannot reject H{sub:0}." ///
               " Evidence consistent with" as res " I(2)"
            di as txt "  {it:The joint hypothesis of two unit roots" ///
               " cannot be rejected at `level'% level.}"
        }
        else {
            di as txt "  {bf:Conclusion:} Reject H{sub:0}." ///
               " Evidence of at most" as res " I(1)"
            di as txt "  {it:The null of two unit roots is rejected;" ///
               " the series has at most one unit root.}"
        }
        di as txt "{hline 78}"
    }
    
    return scalar hf_F = `Fstat'
    return scalar hf_d = `hf_d'
    return scalar hf_cv1 = `cv1'
    return scalar hf_cv5 = `cv5'
    return scalar hf_cv10 = `cv10'
    return scalar hf_lags = `best_p'
end

* ==============================================================================
* SUBPROGRAM 3: Haldrup (1994 JBES) Semiparametric Z(F*) Test
* ==============================================================================
capture program drop _dptest_hz
program define _dptest_hz, rclass
    syntax varname, maxlag(integer) det(string) level(integer) ///
        n(integer) bandwidth(integer) [NOTable]
    
    local y `varlist'
    
    * --- Step 1: Detrend the series ---
    tempvar ydt
    
    if "`det'" == "none" {
        qui gen double `ydt' = `y'
    }
    else if "`det'" == "const" {
        qui sum `y', meanonly
        qui gen double `ydt' = `y' - r(mean)
    }
    else if "`det'" == "trend" {
        tempvar tt
        qui gen `tt' = _n
        qui reg `y' `tt'
        qui predict double `ydt', resid
        drop `tt'
    }
    else if "`det'" == "qtrend" {
        tempvar tt tt2
        qui gen `tt' = _n
        qui gen `tt2' = _n^2
        qui reg `y' `tt' `tt2'
        qui predict double `ydt', resid
        drop `tt' `tt2'
    }
    
    * --- Step 2: Run basic HF regression on detrended series ---
    tempvar d2ydt dydt_lag ydt_lag
    qui gen double `d2ydt' = D2.`ydt'
    qui gen double `dydt_lag' = L.D.`ydt'
    qui gen double `ydt_lag' = L.`ydt'
    
    qui reg `d2ydt' `ydt_lag' `dydt_lag', nocons
    
    local nobs = e(N)
    local s2 = e(rss) / `nobs'
    local b_pi1 = _b[`ydt_lag']
    local b_pi2 = _b[`dydt_lag']
    
    tempvar ehat
    qui predict double `ehat', resid
    
    qui test `ydt_lag' `dydt_lag'
    local Fraw = r(F)
    
    * --- Step 3: Newey-West long-run variance estimate ---
    tempvar ehat2
    qui gen double `ehat2' = `ehat'^2
    qui sum `ehat2', meanonly
    local gamma0 = r(mean)
    
    local sigma2 = `gamma0'
    
    forval j = 1/`bandwidth' {
        tempvar eg
        local wt = 1 - `j'/(`bandwidth' + 1)
        qui gen double `eg' = `ehat' * L`j'.`ehat'
        qui sum `eg', meanonly
        local gammaj = r(mean)
        local sigma2 = `sigma2' + 2 * `wt' * `gammaj'
        drop `eg'
    }
    
    drop `ehat2'
    
    local lambda = 0.5 * (`sigma2' - `s2')
    local ratio = `sigma2' / `s2'
    
    * --- Step 4: Construct Z(F*) ---
    local ZF = (`s2' / `sigma2') * `Fraw'
    if `ZF' < 0 local ZF = 0
    
    * --- Critical values ---
    local nvals "25 50 100 250 500"
    local rowidx = 6
    local idx = 1
    foreach nv of local nvals {
        if `n' <= `nv' {
            local rowidx = `idx'
            continue, break
        }
        local idx = `idx' + 1
    }
    
    tempname cv_hz
    if "`det'" == "none" {
        mat `cv_hz' = ( 0.96, 2.05, 2.89, 3.78, 4.66, 6.01 \ ///
                        0.97, 2.03, 2.82, 3.60, 4.41, 5.52 \ ///
                        0.98, 2.02, 2.78, 3.53, 4.29, 5.31 \ ///
                        0.98, 2.01, 2.76, 3.49, 4.22, 5.20 \ ///
                        0.98, 2.01, 2.76, 3.48, 4.20, 5.17 \ ///
                        0.98, 2.01, 2.75, 3.47, 4.18, 5.14 )
    }
    else if "`det'" == "const" {
        mat `cv_hz' = ( 2.56, 4.44, 5.78, 7.17, 8.61, 10.55 \ ///
                        2.58, 4.30, 5.47, 6.61, 7.76, 9.22  \ ///
                        2.58, 4.24, 5.33, 6.36, 7.38, 8.65  \ ///
                        2.59, 4.20, 5.25, 6.23, 7.18, 8.36  \ ///
                        2.59, 4.19, 5.22, 6.19, 7.13, 8.28  \ ///
                        2.59, 4.18, 5.21, 6.16, 7.08, 8.22  )
    }
    else if "`det'" == "trend" {
        mat `cv_hz' = ( 4.97, 7.70, 9.54, 11.41, 13.34, 15.88 \ ///
                        4.89, 7.21, 8.75, 10.17, 11.61, 13.43 \ ///
                        4.86, 6.98, 8.36,  9.58, 10.80, 12.31 \ ///
                        4.83, 6.86, 8.13,  9.25, 10.34, 11.70 \ ///
                        4.83, 6.82, 8.05,  9.15, 10.20, 11.52 \ ///
                        4.82, 6.78, 7.98,  9.05, 10.08, 11.37 )
    }
    else if "`det'" == "qtrend" {
        mat `cv_hz' = ( 7.57, 10.82, 13.11, 15.54, 17.59, 20.73 \ ///
                        7.04,  9.92, 11.77, 13.33, 14.88, 17.01 \ ///
                        6.82,  9.40, 10.93, 12.33, 13.53, 15.24 \ ///
                        6.67,  9.07, 10.54, 11.78, 12.87, 14.45 \ ///
                        6.63,  9.01, 10.39, 11.58, 12.66, 14.18 )
        if `rowidx' > 5 local rowidx = 5
    }
    
    local colidx = 4
    if `level' == 1  local colidx = 6
    if `level' == 10 local colidx = 3
    
    local cv_val = `cv_hz'[`rowidx', `colidx']
    local cv1  = `cv_hz'[`rowidx', 6]
    local cv5  = `cv_hz'[`rowidx', 4]
    local cv10 = `cv_hz'[`rowidx', 3]
    
    local hz_d = 2
    if `ZF' > `cv_val' {
        local hz_d = 1
    }
    
    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as txt "{bf:Panel C: Semiparametric Z(F*) Test for Double Unit Roots}"
        di as txt "{hline 78}"
        di as txt "  H{sub:0}: Two unit roots (I(2))" ///
           _col(45) "Kernel: Bartlett"
        di as txt "  H{sub:1}: At most one unit root" ///
           _col(45) "Bandwidth: `bandwidth'"
        di as txt "  Short-run variance (s{sup:2})" _col(30) "=" ///
           as res %12.6f `s2'
        di as txt "  Long-run variance ({it:sigma}{sup:2})" _col(30) "=" ///
           as res %12.6f `sigma2'
        di as txt "{hline 78}"
        di as txt _col(15) "{bf:Z(F*)}" ///
           _col(35) "{bf:CV 1%}" ///
           _col(48) "{bf:CV 5%}" ///
           _col(61) "{bf:CV 10%}"
        di as txt "{hline 78}"
        di as res _col(15) %10.4f `ZF' ///
           _col(35) %10.4f `cv1' ///
           _col(48) %10.4f `cv5' ///
           _col(61) %10.4f `cv10'
        di as txt "{hline 78}"
        if `hz_d' == 2 {
            di as txt "  {bf:Conclusion:} Cannot reject H{sub:0}." ///
               " Evidence consistent with" as res " I(2)"
            di as txt "  {it:The nonparametric correction confirms" ///
               " two unit roots at `level'% level.}"
        }
        else {
            di as txt "  {bf:Conclusion:} Reject H{sub:0}." ///
               " Evidence of at most" as res " I(1)"
            di as txt "  {it:After correcting for serial correlation," ///
               " the null of two unit roots is rejected.}"
        }
        di as txt "{hline 78}"
    }
    
    return scalar hz_ZF = `ZF'
    return scalar hz_d = `hz_d'
    return scalar hz_sigma2 = `sigma2'
    return scalar hz_s2 = `s2'
    return scalar hz_lambda = `lambda'
end

* ==============================================================================
* SUBPROGRAM 4: Haldrup (1994 JoE) Cointegration ADF Test
* ==============================================================================
capture program drop _dptest_coint
program define _dptest_coint, rclass
    syntax varname, indepvars(string) i2vars(string) maxlag(integer) ///
        det(string) level(integer) n(integer) [NOTable]
    
    local y `varlist'
    
    local i1vars : list indepvars - i2vars
    local m1 : word count `i1vars'
    local m2 : word count `i2vars'
    
    * --- Haldrup JoE Table 1 ---
    tempname cv_m2_1_m1_0
    mat `cv_m2_1_m1_0' = ( -4.45, -4.02, -3.68, -3.30 \ ///
                            -4.18, -3.82, -3.51, -3.16 \ ///
                            -4.09, -3.70, -3.42, -3.12 \ ///
                            -4.02, -3.65, -3.38, -3.08 \ ///
                            -3.99, -3.67, -3.38, -3.08 )

    tempname cv_m2_1_m1_1
    mat `cv_m2_1_m1_1' = ( -5.10, -4.60, -4.21, -3.79 \ ///
                            -4.65, -4.25, -3.93, -3.60 \ ///
                            -4.51, -4.17, -3.89, -3.55 \ ///
                            -4.39, -4.06, -3.80, -3.49 \ ///
                            -4.40, -4.08, -3.80, -3.48 )
    
    tempname cv_m2_1_m1_2
    mat `cv_m2_1_m1_2' = ( -5.50, -5.02, -4.64, -4.23 \ ///
                            -4.93, -4.64, -4.30, -3.99 \ ///
                            -4.81, -4.49, -4.25, -3.93 \ ///
                            -4.77, -4.41, -4.16, -3.88 \ ///
                            -4.73, -4.41, -4.15, -3.83 )
    
    tempname cv_m2_1_m1_3
    mat `cv_m2_1_m1_3' = ( -6.02, -5.49, -5.09, -4.64 \ ///
                            -5.38, -5.04, -4.71, -4.36 \ ///
                            -5.20, -4.89, -4.56, -4.25 \ ///
                            -5.05, -4.75, -4.48, -4.16 \ ///
                            -5.05, -4.71, -4.48, -4.17 )
    
    tempname cv_m2_1_m1_4
    mat `cv_m2_1_m1_4' = ( -6.50, -5.98, -5.49, -5.03 \ ///
                            -5.81, -5.41, -5.09, -4.72 \ ///
                            -5.58, -5.23, -4.93, -4.59 \ ///
                            -5.39, -5.05, -4.78, -4.48 \ ///
                            -5.36, -5.03, -4.75, -4.45 )
    
    tempname cv_m2_2_m1_0
    mat `cv_m2_2_m1_0' = ( -5.21, -4.71, -4.32, -3.90 \ ///
                            -4.70, -4.34, -4.02, -3.70 \ ///
                            -4.51, -4.15, -3.86, -3.54 \ ///
                            -4.35, -4.06, -3.80, -3.49 \ ///
                            -4.42, -4.07, -3.79, -3.49 )
    
    tempname cv_m2_2_m1_1
    mat `cv_m2_2_m1_1' = ( -5.73, -5.20, -4.79, -4.35 \ ///
                            -5.15, -4.72, -4.40, -4.06 \ ///
                            -4.85, -4.56, -4.26, -3.94 \ ///
                            -4.71, -4.45, -4.18, -3.88 \ ///
                            -4.70, -4.38, -4.09, -3.83 )
    
    tempname cv_m2_2_m1_2
    mat `cv_m2_2_m1_2' = ( -6.15, -5.66, -5.22, -4.75 \ ///
                            -5.54, -5.14, -4.77, -4.42 \ ///
                            -5.29, -4.90, -4.59, -4.26 \ ///
                            -5.06, -4.76, -4.49, -4.19 \ ///
                            -4.99, -4.68, -4.44, -4.16 )
    
    tempname cv_m2_2_m1_3
    mat `cv_m2_2_m1_3' = ( -6.68, -6.09, -5.60, -5.12 \ ///
                            -5.76, -5.38, -5.08, -4.75 \ ///
                            -5.58, -5.23, -4.92, -4.60 \ ///
                            -5.44, -5.12, -4.83, -4.52 \ ///
                            -5.37, -5.06, -4.80, -4.48 )
    
    tempname cv_m2_2_m1_4
    mat `cv_m2_2_m1_4' = ( -6.99, -6.41, -6.01, -5.53 \ ///
                            -6.24, -5.82, -5.48, -5.10 \ ///
                            -5.88, -5.50, -5.20, -4.89 \ ///
                            -5.64, -5.33, -5.07, -4.77 \ ///
                            -5.60, -5.31, -5.03, -4.74 )
    
    * --- Row index by n ---
    local nvals "25 50 100 250 500"
    local rowidx = 5
    local idx = 1
    foreach nv of local nvals {
        if `n' <= `nv' {
            local rowidx = `idx'
            continue, break
        }
        local idx = `idx' + 1
    }
    
    local colidx = 3
    if `level' == 1  local colidx = 1
    if `level' == 10 local colidx = 4
    
    if `m2' > 2 {
        di as err "Haldrup JoE tables only cover m2 = 1 or 2"
        exit 198
    }
    if `m1' > 4 {
        di as err "Haldrup JoE tables only cover m1 = 0 to 4"
        exit 198
    }
    
    tempname cv_sel
    if `m2' == 1 {
        if `m1' == 0      mat `cv_sel' = `cv_m2_1_m1_0'
        else if `m1' == 1 mat `cv_sel' = `cv_m2_1_m1_1'
        else if `m1' == 2 mat `cv_sel' = `cv_m2_1_m1_2'
        else if `m1' == 3 mat `cv_sel' = `cv_m2_1_m1_3'
        else if `m1' == 4 mat `cv_sel' = `cv_m2_1_m1_4'
    }
    else {
        if `m1' == 0      mat `cv_sel' = `cv_m2_2_m1_0'
        else if `m1' == 1 mat `cv_sel' = `cv_m2_2_m1_1'
        else if `m1' == 2 mat `cv_sel' = `cv_m2_2_m1_2'
        else if `m1' == 3 mat `cv_sel' = `cv_m2_2_m1_3'
        else if `m1' == 4 mat `cv_sel' = `cv_m2_2_m1_4'
    }
    
    local cv_val = `cv_sel'[`rowidx', `colidx']
    local cv1  = `cv_sel'[`rowidx', 1]
    local cv5  = `cv_sel'[`rowidx', 3]
    local cv10 = `cv_sel'[`rowidx', 4]
    
    * --- Step 1: Run cointegration regression ---
    if "`det'" == "none" {
        qui reg `y' `i1vars' `i2vars', nocons
    }
    else {
        qui reg `y' `i1vars' `i2vars'
    }
    
    tempvar uhat
    qui predict double `uhat', resid
    
    * --- Step 2: ADF test on residuals ---
    tempvar duhat uhat_lag
    qui gen double `duhat' = D.`uhat'
    qui gen double `uhat_lag' = L.`uhat'
    
    local best_bic = .
    local best_p = 0
    local pmax = min(`maxlag', 8)
    
    forval pp = 0/`pmax' {
        local auglag ""
        forval j = 1/`pp' {
            tempvar ctmp`j'
            qui gen double `ctmp`j'' = L`j'.`duhat'
            local auglag "`auglag' `ctmp`j''"
        }
        
        capture qui reg `duhat' `uhat_lag' `auglag', nocons
        
        if _rc == 0 {
            local this_bic = e(N)*ln(e(rss)/e(N)) + (e(df_m)+1)*ln(e(N))
            if `this_bic' < `best_bic' {
                local best_bic = `this_bic'
                local best_p = `pp'
            }
        }
        
        forval j = 1/`pp' {
            capture drop `ctmp`j''
        }
    }
    
    local augvars ""
    forval j = 1/`best_p' {
        tempvar caugf`j'
        qui gen double `caugf`j'' = L`j'.`duhat'
        local augvars "`augvars' `caugf`j''"
    }
    
    qui reg `duhat' `uhat_lag' `augvars', nocons
    
    local adf_stat = _b[`uhat_lag'] / _se[`uhat_lag']
    
    local coint_reject = 0
    if `adf_stat' < `cv_val' {
        local coint_reject = 1
    }
    
    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as txt "{bf:Panel D: Residual-Based Cointegration ADF Test}"
        di as txt "{hline 78}"
        di as txt "  H{sub:0}: No cointegration (residuals are I(1))"
        di as txt "  H{sub:1}: Cointegration (residuals are I(0))"
        di as txt "  I(1) regressors (m{sub:1}): `m1'" ///
           _col(45) "I(2) regressors (m{sub:2}): `m2'"
        di as txt "  ADF augmentation lags: `best_p'"
        di as txt "{hline 78}"
        di as txt _col(12) "{bf:ADF statistic}" ///
           _col(35) "{bf:CV 1%}" ///
           _col(48) "{bf:CV 5%}" ///
           _col(61) "{bf:CV 10%}"
        di as txt "{hline 78}"
        di as res _col(15) %10.4f `adf_stat' ///
           _col(35) %10.4f `cv1' ///
           _col(48) %10.4f `cv5' ///
           _col(61) %10.4f `cv10'
        di as txt "{hline 78}"
        if `coint_reject' == 1 {
            di as txt "  {bf:Conclusion:} Reject H{sub:0}." ///
               " Evidence of" as res " cointegration"
            di as txt "  {it:The residuals are stationary;" ///
               " a long-run equilibrium exists among the variables.}"
        }
        else {
            di as txt "  {bf:Conclusion:} Cannot reject H{sub:0}." ///
               as res " No cointegration"
            di as txt "  {it:The residuals contain a unit root;" ///
               " no stable long-run relationship is found.}"
        }
        di as txt "{hline 78}"
    }
    
    return scalar coint_adf = `adf_stat'
    return scalar coint_cv = `cv_val'
    return scalar coint_cv1 = `cv1'
    return scalar coint_cv5 = `cv5'
    return scalar coint_cv10 = `cv10'
    return scalar coint_reject = `coint_reject'
    return scalar coint_m1 = `m1'
    return scalar coint_m2 = `m2'
    return scalar coint_lags = `best_p'
end

* ==============================================================================
* SUBPROGRAM 5: Diagnostic Graphs with Professional Styling
* ==============================================================================
capture program drop _dptest_graph
program define _dptest_graph
    syntax varname, maxdiff(integer)
    
    local y `varlist'
    
    tempvar dy ddy
    qui gen double `dy' = D.`y'
    qui gen double `ddy' = D2.`y'
    
    * --- Color palette ---
    local c1 "navy"
    local c2 "dkorange"
    local c3 "forest_green"
    local c4 "cranberry"
    
    * --- Panel 1: Level series ---
    local g1opts "lcolor(`c1') lwidth(medthick)"
    twoway (tsline `y', `g1opts'), ///
        title("Level Series", size(medium) color(black)) ///
        ytitle("") xtitle("") ///
        graphregion(color(white) margin(small)) ///
        plotregion(color(white) margin(small)) ///
        ylabel(, labsize(small) angle(0) grid glcolor(gs14)) ///
        xlabel(, labsize(small) grid glcolor(gs14)) ///
        name(__g1, replace) nodraw
    
    * --- Panel 2: First difference ---
    local g2opts "lcolor(`c2') lwidth(medthick)"
    twoway (tsline `dy', `g2opts'), ///
        title("{&Delta}Y{sub:t}: First Difference", size(medium) color(black)) ///
        ytitle("") xtitle("") ///
        graphregion(color(white) margin(small)) ///
        plotregion(color(white) margin(small)) ///
        ylabel(, labsize(small) angle(0) grid glcolor(gs14)) ///
        xlabel(, labsize(small) grid glcolor(gs14)) ///
        yline(0, lcolor(gs10) lpattern(dash)) ///
        name(__g2, replace) nodraw
    
    * --- Panel 3: Second difference ---
    local g3opts "lcolor(`c3') lwidth(medthick)"
    twoway (tsline `ddy', `g3opts'), ///
        title("{&Delta}{sup:2}Y{sub:t}: Second Difference", size(medium) color(black)) ///
        ytitle("") xtitle("") ///
        graphregion(color(white) margin(small)) ///
        plotregion(color(white) margin(small)) ///
        ylabel(, labsize(small) angle(0) grid glcolor(gs14)) ///
        xlabel(, labsize(small) grid glcolor(gs14)) ///
        yline(0, lcolor(gs10) lpattern(dash)) ///
        name(__g3, replace) nodraw
    
    * --- Combine differencing plots ---
    graph combine __g1 __g2 __g3, ///
        cols(1) ///
        title("dptest: Integration Order Diagnostics", ///
            size(medlarge) color(black)) ///
        subtitle("Visual inspection of differencing transformations", ///
            size(small) color(gs6)) ///
        graphregion(color(white) margin(small)) ///
        name(dptest_diff, replace)
    
    * --- ACF plots ---
    capture {
        ac `y', lags(20) ///
            title("ACF: Level Series", size(medium) color(black)) ///
            ytitle("Autocorrelation", size(small)) xtitle("") ///
            graphregion(color(white) margin(small)) ///
            plotregion(color(white) margin(small)) ///
            ylabel(, labsize(small) angle(0) grid glcolor(gs14)) ///
            xlabel(, labsize(small) grid glcolor(gs14)) ///
            ciopts(lcolor(gs12)) ///
            name(__g4, replace) nodraw
    }
    
    capture {
        ac `dy', lags(20) ///
            title("ACF: First Difference", size(medium) color(black)) ///
            ytitle("Autocorrelation", size(small)) xtitle("") ///
            graphregion(color(white) margin(small)) ///
            plotregion(color(white) margin(small)) ///
            ylabel(, labsize(small) angle(0) grid glcolor(gs14)) ///
            xlabel(, labsize(small) grid glcolor(gs14)) ///
            ciopts(lcolor(gs12)) ///
            name(__g5, replace) nodraw
    }
    
    capture {
        ac `ddy', lags(20) ///
            title("ACF: Second Difference", size(medium) color(black)) ///
            ytitle("Autocorrelation", size(small)) xtitle("Lag") ///
            graphregion(color(white) margin(small)) ///
            plotregion(color(white) margin(small)) ///
            ylabel(, labsize(small) angle(0) grid glcolor(gs14)) ///
            xlabel(, labsize(small) grid glcolor(gs14)) ///
            ciopts(lcolor(gs12)) ///
            name(__g6, replace) nodraw
    }
    
    capture {
        graph combine __g4 __g5 __g6, ///
            cols(1) ///
            title("dptest: Autocorrelation Diagnostics", ///
                size(medlarge) color(black)) ///
            subtitle("Decay pattern indicates integration order", ///
                size(small) color(gs6)) ///
            graphregion(color(white) margin(small)) ///
            name(dptest_acf, replace)
    }
    
    capture graph drop __g1 __g2 __g3 __g4 __g5 __g6
end
