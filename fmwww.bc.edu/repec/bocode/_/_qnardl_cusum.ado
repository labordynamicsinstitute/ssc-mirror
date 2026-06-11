*! _qnardl_cusum v1.0.0  28may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! CUSUM and CUSUM-square stability tests for QNARDL.
*!
*! For the chosen tau (default 0.5), runs the URECM via qreg, recovers
*! residuals, and computes:
*!   CUSUM_t   = Σ_{j=k+1}^t ε̂_j / σ̂                  (with 5% linear bands)
*!   CUSUMSQ_t = Σ_{j=k+1}^t ε̂²_j / Σ_{j=k+1}^T ε̂²_j  (with 5% bands)
*!
*! 5% bands (Brown, Durbin & Evans 1975):
*!   CUSUM   :  ± 0.948 [ √(T-k) + 2(t-k)/√(T-k) ]
*!   CUSUMSQ :  (t-k)/(T-k)  ±  1.358/√(T-k)
*!
*! Stores results in r() for plotting via -qnardl_cgraph-.
*!

program define _qnardl_cusum, rclass
    version 14.0

    syntax , depvar(varname) pos_vars(varlist) neg_vars(varlist) ///
        touse(varname) [ linear_vars(string) exog(string) ///
        trendvar(string) case(integer 3) ///
        p(integer 1) q(integer 1) r(integer 1) ///
        TAUuse(numlist max=1) ]

    if "`tauuse'" == "" local tauuse 0.5

    local kasym : word count `pos_vars'
    local klin  : word count `linear_vars'

    local has_const = (`case' >= 3)
    local has_trend = inlist(`case', 4, 5, 6, 7, 8, 9, 10, 11)
    local has_quad  = inlist(`case', 8, 9, 10, 11)
    if `has_quad' & "`trendvar'" != "" {
        tempvar t2var
        qui gen double `t2var' = (`trendvar')^2 if `touse'
    }
    local consopt = cond(`has_const', "", "noconstant")

    // Build URECM (same construction as the other modules)
    local urecm "L.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L.`lv'"
        }
    }
    if `p' > 1  local urecm "`urecm' L(1/`=`p'-1').D.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L(0/`=`r'-1').D.`lv'"
        }
    }
    if "`exog'" != ""                       local urecm "`urecm' `exog'"
    if `has_trend' & "`trendvar'" != ""     local urecm "`urecm' `trendvar'"
    if `has_quad' & "`trendvar'" != ""      local urecm "`urecm' `t2var'"

    qui tsrevar `urecm'
    local urecm_temps `r(varlist)'
    qui tsrevar D.`depvar'
    local dydepvar `r(varlist)'

    capture qui qreg `dydepvar' `urecm_temps' if `touse', ///
        quantile(`tauuse') `consopt'
    if _rc {
        di as error "_qnardl_cusum: qreg failed at tau=`tauuse'"
        exit _rc
    }

    local T = e(N)
    local k = e(df_m) + `has_const'
    local effT = `T' - `k'      // degrees of freedom

    // Predict residuals from the qreg
    tempvar resid esample
    qui gen byte `esample' = e(sample)
    qui predict double `resid' if `esample', residuals

    // Compute sigma_hat (use IQR/normal-equivalent or OLS sigma)
    qui sum `resid' if `esample'
    local sigma_hat = r(sd)

    // Build CUSUM and CUSUMSQ as new variables (only over esample)
    tempvar tobs cuc cucsq ssr_tail upper_c lower_c upper_cs lower_cs
    qui gen int    `tobs'  = .
    qui gen double `cuc'   = .
    qui gen double `cucsq' = .

    // total SSR for CUSUMSQ denominator
    qui gen double `ssr_tail' = `resid'^2 if `esample'
    qui sum `ssr_tail' if `esample'
    local total_ssr = r(sum)

    // Compute running sums
    qui gen long _qnct_row = _n if `esample'
    qui sum _qnct_row if `esample'
    local row_min = r(min)
    local row_max = r(max)

    qui gen double _qnct_runeps = 0
    qui gen double _qnct_runsq  = 0
    local running_eps 0
    local running_sq  0
    local trow = 0
    forvalues i = `row_min'/`row_max' {
        local ri = `resid'[`i']
        if missing(`ri') continue
        local running_eps = `running_eps' + `ri'
        local running_sq  = `running_sq'  + `ri'^2
        local ++trow
        qui replace `tobs'  = `trow' in `i'
        qui replace `cuc'   = `running_eps' / `sigma_hat' in `i'
        qui replace `cucsq' = `running_sq'  / `total_ssr' in `i'
    }

    // 5% bands: BDE (1975)
    qui gen double `upper_c'  = 0.948 * (sqrt(`effT') + 2 * `tobs' / sqrt(`effT')) if !missing(`tobs')
    qui gen double `lower_c'  = -`upper_c' if !missing(`tobs')
    local c0 = 1.358 / sqrt(`effT')
    qui gen double `upper_cs' = `tobs' / `effT' + `c0' if !missing(`tobs')
    qui gen double `lower_cs' = `tobs' / `effT' - `c0' if !missing(`tobs')

    // Test verdicts: any breach of CUSUM or CUSUMSQ bounds?
    qui gen byte _qnct_break_c  = (abs(`cuc')   > `upper_c')   if !missing(`tobs')
    qui gen byte _qnct_break_cs = (`cucsq' > `upper_cs' | `cucsq' < `lower_cs') if !missing(`tobs')
    qui sum _qnct_break_c
    local nbreak_c = r(sum)
    qui sum _qnct_break_cs
    local nbreak_cs = r(sum)

    // Display
    di as txt _n "{hline 78}"
    di as res "[F] CUSUM / CUSUMSQ STABILITY TESTS  (tau = " `tauuse' ")"
    di as txt _col(3) "Brown-Durbin-Evans 1975 recursive tests applied to URECM residuals."
    di as txt _col(3) "T = " `T' ", k = " `k' ", effective T-k = " `effT'
    di as txt "{hline 78}"
    di as txt _col(3) %-30s "Test" _col(40) %-30s "Verdict"
    di as txt _col(3) "{hline 72}"
    di as txt _col(3) %-30s "CUSUM   bands breached (#)" ///
              as res _col(40) `nbreak_c' "  of " `effT' "  obs"
    if `nbreak_c' == 0 {
        di as res _col(40) "==>  STABLE (within 5% bands)"
    }
    else {
        di as err _col(40) "==>  REJECT stability"
    }
    di as txt _col(3) %-30s "CUSUMSQ bands breached (#)" ///
              as res _col(40) `nbreak_cs' "  of " `effT' "  obs"
    if `nbreak_cs' == 0 {
        di as res _col(40) "==>  STABLE (within 5% bands)"
    }
    else {
        di as err _col(40) "==>  REJECT stability"
    }
    di as txt _col(3) "{hline 72}"
    di as txt _col(3) "Plot the paths:  {bf:qnardl_cgraph}  or  {bf:qnardl_cgraph , cusumsq}"

    // Store plotting data in permanent named variables (qnardl_cgraph reads them)
    capture drop _qnct_cuc _qnct_cucsq _qnct_uc _qnct_lc _qnct_ucs _qnct_lcs _qnct_t
    qui gen double _qnct_cuc   = `cuc'
    qui gen double _qnct_cucsq = `cucsq'
    qui gen double _qnct_uc    = `upper_c'
    qui gen double _qnct_lc    = `lower_c'
    qui gen double _qnct_ucs   = `upper_cs'
    qui gen double _qnct_lcs   = `lower_cs'
    qui gen int    _qnct_t     = `tobs'

    // capture cleanup of internal temps
    capture drop _qnct_row _qnct_runeps _qnct_runsq _qnct_break_c _qnct_break_cs

    return scalar nbreak_cusum   = `nbreak_c'
    return scalar nbreak_cusumsq = `nbreak_cs'
    return scalar T_eff = `effT'
    return scalar tauuse = `tauuse'
end
