*! xtdhcoint v1.0.0 - Durbin-Hausman Panel Cointegration Tests
*! Faithful Stata implementation of the original GAUSS code by Westerlund
*! Date: February 2026
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Reference: Westerlund, J. (2008). Panel cointegration tests of the Fisher effect.
*!            Journal of Applied Econometrics, 23: 193-233.

/*
** VERSION 2.0.0 - COMPLETE REWRITE
**
** Changes from v1.0.x:
**   - Faithful line-by-line replication of the original GAUSS code (dhh.txt)
**   - Zero-padding before differencing (matches GAUSS cum() lines 19-22)
**   - Robust balanced-panel extraction
**   - Replaced 'mata clear' with targeted function drops
**   - Removed bootstrap (not in original GAUSS code)
**
** GAUSS CODE REFERENCE (dhh.txt by Joakim Westerlund):
**   cum()       -> lines 10-38   : First-diff, defactor, cumulate
**   gdh()       -> lines 40-63   : Individual DH statistic
**   pdh()       -> lines 65-102  : Panel DH statistic
**   fact()      -> lines 104-158 : Factor number selection
**   prin()      -> lines 160-178 : Principal components
**   gdh_panel() -> lines 180-207 : Main driver, standardization
**
** PAPER REFERENCE (Westerlund 2008, p.203-204):
**   DHg = sum_i Si * (phi_tilde_i - phi_hat_i)^2 * sum_t(e_{it-1}^2)
**   DHp = Sn * (phi_tilde - phi_hat)^2 * sum_i sum_t(e_{it-1}^2)
**   Standardization via Theorem 1 moments:
**     E(Bi)=5.5464, var(Bi)=36.7673, E(Ci)=0.5005, var(Ci)=0.3348
*/

program define xtdhcoint, rclass sortpreserve
    version 14.0
    
    syntax varlist(min=2 numeric ts) [if] [in], ///
        [Kmax(integer 5)]       /// Maximum number of factors
        [Criterion(string)]     /// Information criterion (ic/pc/aic/bic)
        [Penalty(integer 1)]    /// Penalty type (1=default, 2, 3)
        [Bandwidth(integer -1)] /// Kernel bandwidth (-1=automatic)
        [PREdet(real 0)]        /// Predetermined coefficient (0=estimate)
        [NOConstant]            /// Suppress constant term
        [Level(cilevel)]        /// Confidence level
        [NOTable]               /// Suppress output table
    
    *--------------------------------------------------------------------------
    * 1. Parse Variables and Check Panel Structure
    *--------------------------------------------------------------------------
    
    marksample touse
    
    * Get variable names
    gettoken depvar indepvars : varlist
    local nvars : word count `indepvars'
    
    * Check panel structure
    qui xtset
    local panelvar `r(panelvar)'
    local timevar `r(timevar)'
    
    if "`panelvar'" == "" {
        di as error "Panel variable not set. Use xtset panelvar timevar first."
        exit 459
    }
    
    *--------------------------------------------------------------------------
    * 2. Set Default Options
    *--------------------------------------------------------------------------
    
    * Information criterion
    if "`criterion'" == "" local criterion "ic"
    if !inlist("`criterion'", "ic", "pc", "aic", "bic") {
        di as error "criterion() must be one of: ic, pc, aic, bic"
        exit 198
    }
    
    * Map criterion to code (matches GAUSS fact() parameter c)
    if "`criterion'" == "pc"  local cri = 1
    if "`criterion'" == "ic"  local cri = 2
    if "`criterion'" == "aic" local cri = 3
    if "`criterion'" == "bic" local cri = 3
    
    * BIC uses penalty type 2
    if "`criterion'" == "bic" local penalty = 2
    
    *--------------------------------------------------------------------------
    * 3. Extract Balanced Panel Data
    *--------------------------------------------------------------------------
    
    preserve
    qui keep if `touse'
    
    * Sort by panel and time
    sort `panelvar' `timevar'
    
    * Get panel IDs
    tempvar panel_id
    qui egen `panel_id' = group(`panelvar')
    qui sum `panel_id', meanonly
    local N = r(max)
    
    if `N' < 2 {
        di as error "At least 2 cross-sectional units required."
        restore
        exit 198
    }
    
    * Get time periods per panel and enforce balance
    tempvar time_count
    qui bysort `panel_id': gen `time_count' = _N
    qui sum `time_count', meanonly
    local Tmin = r(min)
    local Tmax = r(max)
    
    if `Tmin' != `Tmax' {
        di as text "Note: Unbalanced panel. Truncating each unit to T = " `Tmin'
    }
    
    * Keep only first Tmin observations per unit for balance
    tempvar obs_within
    qui bysort `panel_id' (`timevar'): gen `obs_within' = _n
    qui keep if `obs_within' <= `Tmin'
    local T = `Tmin'
    
    if `T' < 10 {
        di as error "At least 10 time periods required."
        restore
        exit 198
    }
    
    * Automatic bandwidth (Newey-West) - matches paper Section 3.4
    if `bandwidth' < 0 {
        local bandwidth = floor(4 * (`T'/100)^(2/9))
    }
    if `bandwidth' < 1 {
        local bandwidth = 1
    }
    
    * Maximum factors validation
    if `kmax' < 1 {
        di as error "kmax() must be at least 1"
        restore
        exit 198
    }
    if `kmax' > min(`N', `T') {
        local kmax = min(`N', `T') - 1
        di as text "Note: kmax adjusted to " `kmax'
    }
    
    * Re-sort to ensure correct order for reshaping
    sort `panel_id' `timevar'
    
    *--------------------------------------------------------------------------
    * 4. Verify data dimensions are valid for Mata
    *--------------------------------------------------------------------------
    
    qui count
    local n_obs = r(N)
    local expected_obs = `N' * `T'
    
    if `n_obs' != `expected_obs' {
        di as error "Data dimension mismatch: expected " `expected_obs' " obs, found " `n_obs'
        restore
        exit 198
    }
    
    *--------------------------------------------------------------------------
    * 5. Pass to Mata for Computation
    *--------------------------------------------------------------------------
    
    mata: _xtdh_main("`depvar'", "`indepvars'", "`panel_id'", ///
                      `N', `T', `kmax', `penalty', `cri', ///
                      `bandwidth', `predet')
    
    *--------------------------------------------------------------------------
    * 6. Retrieve Results
    *--------------------------------------------------------------------------
    
    tempname dhg dhp dhg_z dhp_z dhg_p dhp_p nf
    
    scalar `dhg' = r(dhg)
    scalar `dhp' = r(dhp)
    scalar `dhg_z' = r(dhg_z)
    scalar `dhp_z' = r(dhp_z)
    scalar `dhg_p' = r(dhg_p)
    scalar `dhp_p' = r(dhp_p)
    scalar `nf' = r(nf)
    
    restore
    
    *--------------------------------------------------------------------------
    * 7. Display Results
    *--------------------------------------------------------------------------
    
    if "`notable'" == "" {
        di ""
        di as text "{hline 78}"
        di as text "{bf:Westerlund (2008) Durbin-Hausman Panel Cointegration Tests}"
        di as text "{hline 78}"
        di ""
        di as text "H0: No cointegration"
        di as text "H1(DHg): Cointegration for at least some units"
        di as text "H1(DHp): Cointegration for all units (common AR parameter)"
        di ""
        di as text "{hline 78}"
        di as text "Panel dimensions:" _col(25) "N = " as result %5.0f `N' ///
           as text _col(45) "T = " as result %5.0f `T'
        di as text "Number of regressors:" _col(25) "K = " as result %5.0f `nvars'
        di as text "Estimated factors:" _col(25) "F = " as result %5.0f scalar(`nf')
        di as text "Kernel bandwidth:" _col(25) "M = " as result %5.0f `bandwidth'
        if `predet' != 0 {
            di as text "Predetermined coeff.:" _col(25) as result %7.4f `predet'
        }
        di as text "{hline 78}"
        di ""
        if `nvars' > 1 {
            di as error "Warning: Simulated moments are derived for K=1 (one regressor)."
            di as error "         With K=`nvars', z-values may not follow N(0,1) under H0."
            di as error "         Consider running separate bivariate tests."
            di ""
        }
        
        * Compute averages for display
        local dhg_avg = scalar(`dhg') / `N'
        local dhp_avg = scalar(`dhp') / `N'
        
        * Theoretical means under H0 (Westerlund 2008, Remark 2, p.204)
        local mu_g = 5.5464
        local mu_p_inv = 1 / 0.5005    // E(1/Ci) = 1/E(Ci) used in DHp
        
        * Results table
        di as text "{hline 78}"
        di as text _col(5) "Test" _col(22) "Avg.Stat" _col(35) "E(.) H0" ///
           _col(48) "Z-value" _col(61) "P-value" _col(73) ""
        di as text "{hline 78}"
        
        * DHg result
        local dhg_dec = cond(scalar(`dhg_p') < (100 - `level')/100, "Reject", "Fail to reject")
        di as text _col(5) "DHg" ///
           _col(20) as result %10.4f `dhg_avg' ///
           _col(33) as result %10.4f `mu_g' ///
           _col(46) as result %10.4f scalar(`dhg_z') ///
           _col(59) as result %10.4f scalar(`dhg_p') ///
           _col(73) as text "`dhg_dec'"
        
        * DHp result
        local dhp_dec = cond(scalar(`dhp_p') < (100 - `level')/100, "Reject", "Fail to reject")
        di as text _col(5) "DHp" ///
           _col(20) as result %10.4f `dhp_avg' ///
           _col(33) as result %10.4f `mu_p_inv' ///
           _col(46) as result %10.4f scalar(`dhp_z') ///
           _col(59) as result %10.4f scalar(`dhp_p') ///
           _col(73) as text "`dhp_dec'"
        
        di as text "{hline 78}"
        di ""
        di as text "Avg.Stat = average per-unit statistic (raw sum / N)."
        di as text "E(.) H0  = expected value under H0. Z = sqrt(N)*(Avg.Stat - E(.))/se."
        di ""
        
        * ----------------------------------------------------------------
        * Decision Table: Z-value vs Critical Values
        * ----------------------------------------------------------------
        
        * Critical values (right tail of standard normal)
        local cv10 = invnormal(0.90)    // 1.2816
        local cv05 = invnormal(0.95)    // 1.6449
        local cv01 = invnormal(0.99)    // 2.3263
        
        * Decision functions
        local dhg_d10 = cond(scalar(`dhg_z') > `cv10', "Reject", "  --  ")
        local dhg_d05 = cond(scalar(`dhg_z') > `cv05', "Reject", "  --  ")
        local dhg_d01 = cond(scalar(`dhg_z') > `cv01', "Reject", "  --  ")
        local dhp_d10 = cond(scalar(`dhp_z') > `cv10', "Reject", "  --  ")
        local dhp_d05 = cond(scalar(`dhp_z') > `cv05', "Reject", "  --  ")
        local dhp_d01 = cond(scalar(`dhp_z') > `cv01', "Reject", "  --  ")
        
        di as text "{bf:Decision: Z-value vs Critical Values (right tail)}"
        di as text "{hline 78}"
        di as text _col(5) "Test" _col(20) "Z-value" ///
           _col(35) "CV 10%" _col(48) "CV 5%" _col(60) "CV 1%" _col(73) ""
        di as text _col(35) as result %7.4f `cv10' ///
           _col(47) as result %7.4f `cv05' ///
           _col(59) as result %7.4f `cv01'
        di as text "{hline 78}"
        
        di as text _col(5) "DHg" ///
           _col(18) as result %10.4f scalar(`dhg_z') ///
           _col(35) as text "`dhg_d10'" ///
           _col(48) as text "`dhg_d05'" ///
           _col(60) as text "`dhg_d01'"
        
        di as text _col(5) "DHp" ///
           _col(18) as result %10.4f scalar(`dhp_z') ///
           _col(35) as text "`dhp_d10'" ///
           _col(48) as text "`dhp_d05'" ///
           _col(60) as text "`dhp_d01'"
        
        di as text "{hline 78}"
        di ""
        di as text "Reject = Z-value > Critical Value (evidence of cointegration)."
        di as text "  --   = Fail to reject H0 (no evidence of cointegration)."
        di ""
        di as text "Reference: Westerlund (2008), J. of Applied Econometrics, 23: 193-233"
        di ""
    }
    
    *--------------------------------------------------------------------------
    * 8. Store Results
    *--------------------------------------------------------------------------
    
    return scalar N = `N'
    return scalar T = `T'
    return scalar K = `nvars'
    return scalar nf = scalar(`nf')
    return scalar bandwidth = `bandwidth'
    return scalar kmax = `kmax'
    
    return scalar dhg = scalar(`dhg')
    return scalar dhp = scalar(`dhp')
    return scalar dhg_z = scalar(`dhg_z')
    return scalar dhp_z = scalar(`dhp_z')
    return scalar dhg_p = scalar(`dhg_p')
    return scalar dhp_p = scalar(`dhp_p')
    
    return local depvar "`depvar'"
    return local indepvars "`indepvars'"
    return local criterion "`criterion'"
end

*==============================================================================
* MATA FUNCTIONS
* Line-by-line replication of GAUSS code (dhh.txt by Joakim Westerlund)
*==============================================================================

* Safely drop existing functions before redefining
capture mata: mata drop _xtdh_main()
capture mata: mata drop _xtdh_cum()
capture mata: mata drop _xtdh_gdh()
capture mata: mata drop _xtdh_pdh()
capture mata: mata drop _xtdh_fact()
capture mata: mata drop _xtdh_prin()
capture mata: mata drop _xtdh_fejer()

mata:
mata set matastrict on

/*
** Main driver function
** Replicates GAUSS gdh_panel() lines 180-207
*/
void _xtdh_main(string scalar depvar, 
                string scalar indepvars,
                string scalar panelid,
                real scalar N,
                real scalar T,
                real scalar kmax,
                real scalar pen,
                real scalar cri,
                real scalar bandwidth,
                real scalar predet)
{
    real matrix e
    real scalar i, nf, dhg, dhg_raw, dhp_raw, dhg_z, dhp_z, dhg_p, dhp_p
    real scalar n_test
    
    // Simulated moments from Westerlund (2008) Remark 2, p.204
    // Bi = (integral W(r)^2 dr)^{-1}
    // Ci = 1/Bi = integral W(r)^2 dr
    real scalar mu_g, var_g, mu_p, var_p
    mu_g  = 5.5464   // E(Bi)
    var_g = 36.7673   // var(Bi)
    mu_p  = 0.5005    // E(Ci)
    var_p = 0.3348    // var(Ci)
    
    // Step 1: Compute cumulated defactored residuals
    //         Replicates GAUSS: {e, nf} = cum(x, y, kmax, pen, cri)
    _xtdh_cum(depvar, indepvars, panelid, N, T, kmax, pen, cri, predet, e, nf)
    
    // n_test = number of units to test (= N in general use)
    // GAUSS line 186: n = cols(y)
    n_test = cols(e)
    
    // Step 2: Compute DHg = sum of individual DH statistics
    // Replicates GAUSS gdh_panel() lines 190-195
    dhg_raw = 0
    for (i = 1; i <= n_test; i++) {
        dhg_raw = dhg_raw + _xtdh_gdh(e[., i], bandwidth)
    }
    
    // Step 3: Compute DHp = panel DH statistic
    dhp_raw = _xtdh_pdh(e, bandwidth)
    
    // Step 4: Standardize - GAUSS gdh_panel() lines 198-204
    // GAUSS line 200: dhg = sqrt(n)*(dhg/n - mu_g)/sqrt(var_g)
    dhg_z = sqrt(n_test) * (dhg_raw / n_test - mu_g) / sqrt(var_g)
    
    // GAUSS line 204: dhp = sqrt(n)*(pdh(e,p)/n - mu_p^(-1))/sqrt(mu_p^(-4)*var_p)
    dhp_z = sqrt(n_test) * (dhp_raw / n_test - mu_p^(-1)) / sqrt(mu_p^(-4) * var_p)
    
    // P-values (right tail of standard normal)
    // Remark 2: "the computed value should be compared to the right tail"
    dhg_p = 1 - normal(dhg_z)
    dhp_p = 1 - normal(dhp_z)
    
    // Store results
    st_numscalar("r(dhg)", dhg_raw)
    st_numscalar("r(dhp)", dhp_raw)
    st_numscalar("r(dhg_z)", dhg_z)
    st_numscalar("r(dhp_z)", dhp_z)
    st_numscalar("r(dhg_p)", dhg_p)
    st_numscalar("r(dhp_p)", dhp_p)
    st_numscalar("r(nf)", nf)
}


/*
** Cumulated defactored residuals
** Replicates GAUSS cum() lines 10-38
**
** Key: GAUSS prepends zeros to y and x before differencing (lines 19-20)
**      This gives T first-differenced observations (not T-1)
*/
void _xtdh_cum(string scalar depvar,
               string scalar indepvars,
               string scalar panelid,
               real scalar N,
               real scalar T,
               real scalar kmax,
               real scalar pen,
               real scalar cri,
               real scalar predet,
               real matrix e,
               real scalar nf)
{
    real matrix Y_raw, X_raw, Y_wide, de, F, Lambda
    real colvector panel
    real scalar i, K
    
    // Read data from Stata (sorted by panel then time)
    Y_raw = st_data(., depvar)
    X_raw = st_data(., tokens(indepvars))
    panel = st_data(., panelid)
    K = cols(X_raw)
    
    // Reshape Y to T x N (each column = one unit's time series)
    Y_wide = J(T, N, .)
    for (i = 1; i <= N; i++) {
        Y_wide[., i] = Y_raw[(i-1)*T+1 :: i*T]
    }
    
    // GAUSS cum() lines 13-15
    // t = rows(y); n = cols(y); k = cols(x)/n
    // Here: t = T, n = N, k = K
    
    // GAUSS lines 18-22: prepend zeros then difference
    // de = zeros(t, n)
    // y  = zeros(1,n)|y     => (T+1) x N
    // x  = zeros(1,k*n)|x   => (T+1) x (k*N)  
    // dy = diff(y,1)         => T x N
    // dx = diff(x,1)         => T x (k*N)
    
    de = J(T, N, 0)
    
    for (i = 1; i <= N; i++) {
        // Extract unit i's data
        real colvector yi_level, dyi
        real matrix xi_level, dxi
        real scalar r_start, r_end
        
        yi_level = Y_wide[., i]
        
        r_start = (i-1)*T + 1
        r_end   = i*T
        xi_level = X_raw[r_start::r_end, .]
        
        // GAUSS zero-padding + differencing (lines 19-22):
        // Prepend zero row, then take first differences
        // Result: dy[1] = y[1] - 0 = y[1], dy[2] = y[2]-y[1], ...
        // This gives T observations
        dyi = yi_level - (J(1, 1, 0) \ yi_level[1::T-1])
        dxi = xi_level - (J(1, K, 0) \ xi_level[1::T-1, .])
        
        // GAUSS line 27: de[.,i] = (eye(t) - dxi*inv(dxi'dxi)*dxi')*dyi
        if (predet != 0) {
            // Predetermined coefficient: de = dy - predet*dx
            de[., i] = dyi - dxi * J(K, 1, predet)
        }
        else {
            // OLS projection: de = (I - X(X'X)^{-1}X') * dy
            de[., i] = dyi - dxi * (invsym(cross(dxi, dxi)) * cross(dxi, dyi))
        }
    }
    
    // GAUSS line 32: nf = fact(de, kmax, pen, cri)
    nf = _xtdh_fact(de, kmax, pen, cri)
    
    // GAUSS line 33: {f, lam} = prin(de, nf)
    _xtdh_prin(de, nf, F, Lambda)
    
    // GAUSS line 34: de = de - f*lam'
    de = de - F * Lambda'
    
    // GAUSS line 35: e = cumsumc(de)
    // Cumulative sum column-by-column
    e = J(T, N, 0)
    for (i = 1; i <= N; i++) {
        e[., i] = runningsum(de[., i])
    }
}


/*
** Individual DH statistic
** Replicates GAUSS gdh() lines 40-63 EXACTLY
**
** GAUSS code:
**   wl  = w[1:t-1]
**   w0  = w[2:t]
**   b1  = inv(wl'wl)*(wl'w0)          // OLS phi_hat
**   b2  = inv(wl'w0)*(w0'w0)          // IV  phi_tilde
**   e   = w0 - wl*b1
**   s   = (e'e)/rows(e)               // sigma^2
**   io  = fejer(e,p)                  // one-sided LR cov
**   sig = s + io + io'                // omega^2
**   s   = s^2/sig                     // sigma^4/omega^2
**   dhs = (b2-b1)^2/(s*inv(wl'wl))   // = (omega^2/sigma^4)*(b2-b1)^2*(wl'wl)
*/
real scalar _xtdh_gdh(real colvector w, real scalar p)
{
    real scalar t, b1, b2, s, io, sig, dhs
    real colvector wl, w0, resid
    
    t = rows(w)
    
    // GAUSS lines 45-46
    wl = w[1::t-1]
    w0 = w[2::t]
    
    // GAUSS line 48: b1 = inv(wl'wl)*(wl'w0)  [OLS]
    b1 = (wl' * w0) / (wl' * wl)
    
    // GAUSS line 49: b2 = inv(wl'w0)*(w0'w0)  [IV]
    b2 = (w0' * w0) / (wl' * w0)
    
    // GAUSS line 50: e = w0 - wl*b1
    resid = w0 - wl * b1
    
    // GAUSS line 51: s = (e'e)/rows(e)   => sigma^2
    s = (resid' * resid) / rows(resid)
    
    // GAUSS lines 52-56: one-sided long-run covariance
    if (p == 0) {
        io = 0
    }
    else {
        io = _xtdh_fejer(resid, p)
    }
    
    // GAUSS line 57: sig = s + io + io'  => omega^2 = sigma^2 + 2*io
    // (io is scalar, io' = io)
    sig = s + 2 * io
    
    // GAUSS line 58: s = s^2/sig   => sigma^4 / omega^2
    s = s^2 / sig
    
    // GAUSS line 60: dhs = (b2-b1)^2/(s*inv(wl'wl))
    //              = (b2-b1)^2 / ((sigma^4/omega^2) * (1/(wl'wl)))
    //              = (b2-b1)^2 * (wl'wl) * (omega^2/sigma^4)
    //              = Si * (phi_tilde - phi_hat)^2 * sum(e_{t-1}^2)
    dhs = (b2 - b1)^2 / (s * (1 / (wl' * wl)))
    
    return(dhs)
}


/*
** Panel DH statistic
** Replicates GAUSS pdh() lines 65-102 EXACTLY
**
** Note: GAUSS line 71 drops first column: w = w[., 2:cols(w)]
**       This is application-specific for the Fisher effect analysis.
**       For a general-purpose Stata command, we keep all columns.
*/
real scalar _xtdh_pdh(real matrix w, real scalar p)
{
    real scalar t, n, i, b1, b2, s, io, snt, lnt, dhs
    real colvector wl_pool, w0_pool, resid_i
    real matrix wl, w0, e_reshaped
    
    t = rows(w)
    n = cols(w)
    
    // GAUSS lines 72-73: create lags
    wl = w[1::t-1, .]
    w0 = w[2::t, .]
    
    // GAUSS lines 74-75: pool via vec (column stacking)
    wl_pool = vec(wl)
    w0_pool = vec(w0)
    
    // GAUSS line 77: b1 = inv(wl'wl)*(wl'w0)  [pooled OLS]
    b1 = (wl_pool' * w0_pool) / (wl_pool' * wl_pool)
    
    // GAUSS line 78: b2 = inv(wl'w0)*(w0'w0)  [pooled IV]
    b2 = (w0_pool' * w0_pool) / (wl_pool' * w0_pool)
    
    // GAUSS line 83: e = reshape((w0-wl*b1), n, t-1)'
    // GAUSS reshape(vec, nrows, ncols) fills row-by-row
    // vec(wl) stacks columns, so (w0_pool - wl_pool*b1) is n*(t-1) x 1
    // reshape to n x (t-1), then transpose to (t-1) x n
    e_reshaped = colshape(w0_pool - wl_pool * b1, n)
    
    // GAUSS lines 80-97: compute variance components
    snt = 0   // sum of sigma_i^2
    lnt = 0   // sum of omega_i^2
    
    for (i = 1; i <= n; i++) {
        resid_i = e_reshaped[., i]
        
        // GAUSS line 86: s = (e[.,i]'e[.,i])/rows(e)
        s = (resid_i' * resid_i) / rows(resid_i)
        
        // GAUSS lines 87-91: one-sided long-run covariance
        if (p == 0) {
            io = 0
        }
        else {
            io = _xtdh_fejer(resid_i, p)
        }
        
        // GAUSS lines 93-94
        snt = snt + s                // sum sigma_i^2
        lnt = lnt + (s + 2 * io)     // sum omega_i^2 (io+io' = 2*io for scalar)
    }
    
    // GAUSS line 99:
    // dhs = ((lnt/n)*(b2-b1)^2) / (((snt/n)^2)*inv(wl'wl))
    //     = Sn * (b2-b1)^2 * (wl'wl)
    // where Sn = (lnt/n) / (snt/n)^2 = omega_bar^2 / sigma_bar^4
    dhs = ((lnt / n) * (b2 - b1)^2) / (((snt / n)^2) * (1 / (wl_pool' * wl_pool)))
    
    return(dhs)
}


/*
** Factor number selection
** Replicates GAUSS fact() lines 104-158 EXACTLY
*/
real scalar _xtdh_fact(real matrix e, 
                       real scalar kmax,
                       real scalar p,
                       real scalar c)
{
    real scalar T_f, N_f, k, s, smax, pen_val
    real colvector cr
    real matrix F, Lambda, u
    
    T_f = rows(e)
    N_f = cols(e)
    
    // GAUSS lines 109-111: compute maximum variance
    _xtdh_prin(e, kmax, F, Lambda)
    u = e - F * Lambda'
    smax = sum(u:^2) / (N_f * T_f)
    
    cr = J(kmax, 1, .)
    
    // GAUSS lines 113-153
    for (k = 1; k <= kmax; k++) {
        _xtdh_prin(e, k, F, Lambda)
        u = e - F * Lambda'
        s = sum(u:^2) / (N_f * T_f)
        
        // GAUSS lines 121-140: penalty selection
        if (c == 1 | c == 2) {
            if (p == 1) {
                pen_val = (N_f + T_f) / (N_f * T_f) * ln((N_f * T_f) / (N_f + T_f))
            }
            else if (p == 2) {
                pen_val = (N_f + T_f) / (N_f * T_f) * ln(min((N_f, T_f)))
            }
            else {
                pen_val = ln(min((N_f, T_f))) / min((N_f, T_f))
            }
        }
        else {   // c == 3 (AIC/BIC)
            if (p == 1) {
                pen_val = 2 * (N_f + T_f - k) / (N_f * T_f)
            }
            else {
                pen_val = (N_f + T_f - k) * ln(N_f * T_f) / (N_f * T_f)
            }
        }
        
        // GAUSS lines 142-150: criterion value
        if (c == 1) {
            cr[k] = s + k * smax * pen_val    // PC
        }
        else if (c == 2) {
            cr[k] = ln(s) + k * pen_val        // IC
        }
        else {
            cr[k] = s + k * smax * pen_val    // AIC/BIC
        }
    }
    
    // GAUSS lines 155-157: return k that minimizes criterion
    // GAUSS: cr = sortc(seqa(1,1,rows(cr))~cr, 2); retp(cr[1,1])
    return(selectindex(cr :== min(cr))[1])
}


/*
** Principal components estimation
** Replicates GAUSS prin() lines 160-178 EXACTLY
**
** GAUSS code:
**   if n > t:
**     {f0, v, f} = svd1(e*e')
**     f   = f0[.,1:nf]*sqrt(t)
**     lam = (e'f)/t
**   else:
**     {f0, v, f} = svd1(e'e)
**     lam = f0[.,1:nf]*sqrt(n)
**     f   = (e*lam)/n
*/
void _xtdh_prin(real matrix e,
                real scalar nf,
                real matrix F,
                real matrix Lambda)
{
    real scalar T_p, N_p
    real matrix U, Vt
    real colvector sv
    
    T_p = rows(e)
    N_p = cols(e)
    
    // GAUSS lines 166-175
    if (N_p > T_p) {
        // svd(e*e') => eigendecomposition of T x T matrix
        svd(e * e', U, sv, Vt)
        F = U[., 1::nf] * sqrt(T_p)
        Lambda = (e' * F) / T_p
    }
    else {
        // svd(e'e) => eigendecomposition of N x N matrix
        svd(e' * e, U, sv, Vt)
        Lambda = U[., 1::nf] * sqrt(N_p)
        F = (e * Lambda) / N_p
    }
}


/*
** Fejer (Bartlett) kernel for one-sided long-run covariance
**
** Computes: io = sum_{j=1}^{M} w_j * gamma_j
** where:
**   w_j = 1 - j/(M+1)                     (Bartlett kernel weight)
**   gamma_j = (1/T) * sum_{t=j+1}^{T} e_t * e_{t-j}   (autocovariance)
**
** This is the ONE-SIDED covariance.
** Full LR variance: omega^2 = sigma^2 + 2*io
*/
real scalar _xtdh_fejer(real colvector e, real scalar M)
{
    real scalar T_k, j, io, w, gam_j
    
    T_k = rows(e)
    io = 0
    
    for (j = 1; j <= M; j++) {
        w = 1 - j / (M + 1)
        gam_j = (e[1::T_k-j]' * e[j+1::T_k]) / T_k
        io = io + w * gam_j
    }
    
    return(io)
}

end
