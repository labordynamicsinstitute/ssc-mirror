*! _fbardl_diagtest — Diagnostic Tests for FBARDL
*! Version 1.2.0 — 2026-08-02
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Serial correlation is tested with the genuine Breusch-Godfrey auxiliary
*! regression (residuals on the ORIGINAL regressors plus lagged residuals),
*! which is the form that remains valid when the equation contains a lagged
*! dependent variable — always the case in an ARDL model.
*!
*! CUSUM and CUSUM of squares are computed on RECURSIVE residuals, as defined
*! by Brown, Durbin & Evans (1975), with their expanding significance bands.

capture program drop _fbardl_diagtest
program define _fbardl_diagtest, rclass
    version 17

    syntax, RESIDvar(string) NOBS(integer) NPARAMS(integer) ///
        [ LHS(string) RHS(string) NOGRAPHs ]

    // =========================================================================
    // A. NORMALITY TESTS
    // =========================================================================
    di as txt ""
    di as txt "  {bf:A. Normality Tests}"
    di as txt "  {hline 62}"
    di as txt _col(5) "Test" _col(40) "Statistic" _col(55) "p-value"
    di as txt "  {hline 62}"

    capture qui sum `residvar', detail
    if _rc == 0 {
        local skew = r(skewness)
        local kurt = r(kurtosis)
        local n_jb = r(N)
        if `n_jb' > 5 {
            // The parentheses around `skew' are essential: in Stata ^ binds
            // tighter than unary minus, so a negative skewness expanded as
            // -0.4^2 would evaluate to -(0.4^2) and subtract from the
            // statistic instead of adding to it.
            local jb = (`n_jb' / 6) * ((`skew')^2 + ((`kurt') - 3)^2 / 4)
            local jb_p = chi2tail(2, `jb')
            di as txt _col(5) "Jarque-Bera" _col(38) as res %10.4f `jb' _col(53) %8.4f `jb_p' _c
            _fbardl_stars `jb_p'
            return scalar jb = `jb'
            return scalar jb_p = `jb_p'
        }
        di as txt _col(5) "  skewness" _col(38) as res %10.4f `skew'
        di as txt _col(5) "  kurtosis" _col(38) as res %10.4f `kurt'
    }

    capture qui swilk `residvar'
    if _rc == 0 {
        local sw_p = r(p)
        if `sw_p' < . {
            di as txt _col(5) "Shapiro-Wilk W" _col(38) as res %10.4f r(W) _col(53) %8.4f `sw_p' _c
            _fbardl_stars `sw_p'
        }
    }

    capture qui sfrancia `residvar'
    if _rc == 0 {
        local sf_p = r(p)
        if `sf_p' < . {
            di as txt _col(5) "Shapiro-Francia W'" _col(38) as res %10.4f r(W) _col(53) %8.4f `sf_p' _c
            _fbardl_stars `sf_p'
        }
    }
    di as txt "  {hline 62}"
    di as txt _col(5) "{it:H0: residuals are normally distributed}"

    // =========================================================================
    // B. SERIAL CORRELATION
    // =========================================================================
    di as txt ""
    di as txt "  {bf:B. Serial Correlation Tests}"
    di as txt "  {hline 62}"
    di as txt _col(5) "Test" _col(40) "Statistic" _col(55) "p-value"
    di as txt "  {hline 62}"

    // ---- Breusch-Godfrey LM ----
    // The auxiliary regression must include the original regressors as well as
    // the lagged residuals. Regressing the residuals on their own lags alone
    // is a different test, and with a lagged dependent variable in the
    // equation — always true of an ARDL — it is not valid.
    local bg_rc = 0
    forvalues lag = 1/4 {
        local bg_chi = .
        local bg_p = .

        capture qui estat bgodfrey, lags(`lag')
        local thisrc = _rc
        if `thisrc' == 0 {
            _fbardl_rval
            local bg_chi = `_fb_stat'
            local bg_p   = `_fb_p'
        }
        else {
            local bg_rc = `thisrc'
        }

        // Fall back to a hand-built auxiliary regression that still contains
        // the original regressors
        if missing(`bg_p') & "`rhs'" != "" {
            capture {
                tempvar rcopy
                qui gen double `rcopy' = `residvar'
                qui replace `rcopy' = 0 if missing(`rcopy')
                qui regress `rcopy' `rhs' L(1/`lag').`rcopy'
                local bg_chi = e(N) * e(r2)
                local bg_p = chi2tail(`lag', `bg_chi')
            }
            if _rc local bg_rc = _rc
        }

        if !missing(`bg_p') {
            di as txt _col(5) "Breusch-Godfrey LM(`lag')" _col(38) as res %10.4f `bg_chi' ///
               _col(53) %8.4f `bg_p' _c
            _fbardl_stars `bg_p'
        }
        else {
            di as txt _col(5) "Breusch-Godfrey LM(`lag')" _col(38) ///
               as err "not available (rc = `bg_rc')"
        }
    }

    // ---- Ljung-Box Q(12) (McNown, Sam & Goh 2018, Table 5) ----
    local lb_q = .
    local lb_p = .
    capture {
        qui wntestq `residvar', lags(12)
        local lb_q = r(stat)
        local lb_p = r(p)
    }
    if !missing(`lb_p') {
        di as txt _col(5) "Ljung-Box Q(12)" _col(38) as res %10.4f `lb_q' ///
           _col(53) %8.4f `lb_p' _c
        _fbardl_stars `lb_p'
    }

    // ---- Durbin's alternative test ----
    // Valid when the equation contains a lagged dependent variable, unlike DW
    local da_chi = .
    local da_p = .
    capture qui estat durbinalt, lags(1)
    if _rc == 0 {
        _fbardl_rval
        local da_chi = `_fb_stat'
        local da_p   = `_fb_p'
    }
    if !missing(`da_p') {
        di as txt _col(5) "Durbin's alternative (1)" _col(38) as res %10.4f `da_chi' ///
           _col(53) %8.4f `da_p' _c
        _fbardl_stars `da_p'
    }

    // ---- Durbin-Watson, reported for reference only ----
    // DW = sum_{t>=2}(e_t - e_{t-1})^2 / sum_t e_t^2
    local dw = .
    capture {
        tempvar dwe dwnum dwden
        qui gen double `dwe' = `residvar'
        qui gen double `dwnum' = (`dwe' - L.`dwe')^2
        qui gen double `dwden' = `dwe'^2
        qui sum `dwnum', meanonly
        local num = r(sum)
        qui sum `dwden', meanonly
        local den = r(sum)
        if `den' > 0 local dw = `num' / `den'
    }
    if `dw' < . {
        di as txt _col(5) "Durbin-Watson" _col(38) as res %10.4f `dw'
    }
    di as txt "  {hline 62}"
    di as txt _col(5) "{it:H0: no serial correlation}"
    di as txt _col(5) "{it:Durbin-Watson is biased towards 2 when the equation contains a}"
    di as txt _col(5) "{it:lagged dependent variable, as an ARDL always does. Use the}"
    di as txt _col(5) "{it:Breusch-Godfrey and Durbin alternative tests instead.}"

    // =========================================================================
    // C. HETEROSKEDASTICITY
    // =========================================================================
    di as txt ""
    di as txt "  {bf:C. Heteroskedasticity Tests}"
    di as txt "  {hline 62}"
    di as txt _col(5) "Test" _col(40) "Statistic" _col(55) "p-value"
    di as txt "  {hline 62}"

    // ---- Breusch-Pagan / Cook-Weisberg ----
    local bp_chi = .
    local bp_p = .
    capture qui estat hettest
    if _rc == 0 {
        _fbardl_rval
        local bp_chi = `_fb_stat'
        local bp_p   = `_fb_p'
    }
    if !missing(`bp_p') {
        di as txt _col(5) "Breusch-Pagan / Cook-Weisberg" _col(38) as res %10.4f `bp_chi' ///
           _col(53) %8.4f `bp_p' _c
        _fbardl_stars `bp_p'
    }

    // ---- White's general test ----
    local wh_chi = .
    local wh_p = .
    capture qui estat imtest, white
    if _rc == 0 {
        _fbardl_rval
        local wh_chi = `_fb_stat'
        local wh_p   = `_fb_p'
    }
    if !missing(`wh_p') {
        di as txt _col(5) "White's general test" _col(38) as res %10.4f `wh_chi' ///
           _col(53) %8.4f `wh_p' _c
        _fbardl_stars `wh_p'
    }

    // ---- ARCH LM ----
    foreach L in 1 4 {
        local a_chi = .
        local a_p = .
        capture qui estat archlm, lags(`L')
        if _rc == 0 {
            _fbardl_rval
            local a_chi = `_fb_stat'
            local a_p   = `_fb_p'
        }
        if !missing(`a_p') {
            di as txt _col(5) "ARCH LM(`L')" _col(38) as res %10.4f `a_chi' ///
               _col(53) %8.4f `a_p' _c
            _fbardl_stars `a_p'
        }
        else {
            di as txt _col(5) "ARCH LM(`L')" _col(38) as err "not available"
        }
    }
    di as txt "  {hline 62}"
    di as txt _col(5) "{it:H0: homoskedastic errors. If these reject, consider hac(hetero);}"
    di as txt _col(5) "{it:if the serial correlation tests also reject, consider hac(both).}"

    // =========================================================================
    // D. FUNCTIONAL FORM
    // =========================================================================
    di as txt ""
    di as txt "  {bf:D. Functional Form}"
    di as txt "  {hline 62}"

    local reset_p = .
    capture {
        qui estat ovtest
        local reset_F = r(F)
        local reset_p = r(p)
    }
    if `reset_p' < . {
        di as txt _col(5) "Ramsey RESET" _col(38) as res %10.4f `reset_F' _col(53) %8.4f `reset_p' _c
        _fbardl_stars `reset_p'
    }
    else {
        di as txt _col(5) "Ramsey RESET" _col(38) as txt "(not available)"
    }
    di as txt "  {hline 62}"
    di as txt _col(5) "{it:H0: no omitted variables / correct functional form}"

    // =========================================================================
    // E. STABILITY — CUSUM AND CUSUM OF SQUARES
    // =========================================================================
    di as txt ""
    di as txt "  {bf:E. Parameter Stability} {it:(Brown, Durbin & Evans, 1975)}"
    di as txt "  {hline 62}"

    if "`lhs'" == "" {
        di as txt _col(5) "(model specification not supplied — CUSUM not computed)"
        di as txt "  {hline 62}"
        di as txt ""
        exit
    }

    _fbardl_cusum, lhs(`lhs') rhs(`rhs') `nographs'

    di as txt "  {hline 62}"
    di as txt _col(5) "{it:H0: the coefficient vector is constant over the sample.}"
    di as txt _col(5) "{it:Both tests use recursive residuals with 5% BDE bands.}"
    di as txt ""
end


// =============================================================================
// CUSUM and CUSUM of squares on recursive residuals
// =============================================================================
// Recursive residuals are the standardised one-step-ahead forecast errors of
// an expanding-window OLS fit:
//     w_t = (y_t - x_t'b_{t-1}) / sqrt(1 + x_t'(X_{t-1}'X_{t-1})^{-1} x_t)
// Stata's -predict, stdf- returns s*sqrt(1 + x'(X'X)^{-1}x), so the scaling
// factor is recovered as w_t = (y_t - xb_t) * e(rmse) / stdf_t.
capture program drop _fbardl_cusum
program define _fbardl_cusum, rclass
    version 17

    syntax, lhs(string) rhs(string) [ NOGRAPHs ]

    tempvar yv esamp seq xbh sef wrec
    qui gen double `yv' = `lhs'

    qui regress `lhs' `rhs'
    local k = e(df_m) + 1
    qui gen byte `esamp' = e(sample)
    qui count if `esamp'
    local T = r(N)

    if `T' - `k' < 10 {
        di as txt _col(5) "(too few observations beyond k to compute recursive residuals)"
        exit
    }

    qui gen long `seq' = sum(`esamp') if `esamp'
    qui gen double `wrec' = .

    // Expanding-window recursion. The first fit uses k+1 observations: with
    // exactly k the residual degrees of freedom are zero, e(rmse) is zero and
    // the scaling factor recovered from stdf would be 0/0.
    forvalues t = `=`k' + 2'/`T' {
        capture {
            qui regress `lhs' `rhs' if `esamp' & `seq' <= `=`t' - 1'
            local s = e(rmse)
            capture drop `xbh'
            capture drop `sef'
            qui predict double `xbh' if `seq' == `t', xb
            qui predict double `sef' if `seq' == `t', stdf
            qui replace `wrec' = (`yv' - `xbh') * `s' / `sef' if `seq' == `t'
        }
    }

    qui count if !missing(`wrec')
    local nw = r(N)
    if `nw' < 10 {
        di as txt _col(5) "(recursive residuals could not be computed)"
        exit
    }

    // ---- CUSUM ----
    // W_t = (1/sigma_w) * sum_{j<=t} w_j, with sigma_w the sd of the
    // recursive residuals. BDE bands run from +/- a*sqrt(T-k) at t=k to
    // +/- 3a*sqrt(T-k) at t=T, i.e. +/- a*[sqrt(T-k) + 2(t-k)/sqrt(T-k)].
    qui sum `wrec'
    local sw = r(sd)
    local nk = `nw'

    tempvar cw cband tt cratio
    qui gen double `cw' = sum(cond(missing(`wrec'), 0, `wrec')) / `sw' if !missing(`wrec')
    qui gen double `tt' = sum(!missing(`wrec')) if !missing(`wrec')

    // BDE bands run from +/- a*sqrt(nk) at the first recursive residual to
    // +/- 3a*sqrt(nk) at the last. Dividing |W_t| by the shape of that band
    // gives a statistic that is compared directly against a, so the numbers
    // below are on the same scale as Stata's own -estat sbcusum-.
    qui gen double `cband' = sqrt(`nk') + 2 * `tt' / sqrt(`nk')
    qui gen double `cratio' = abs(`cw') / `cband' if !missing(`cw')
    qui sum `cratio', meanonly
    local cusum_stat = r(max)

    di as txt _col(5) "CUSUM" _col(38) as res %10.4f `cusum_stat' _col(53) _c
    if `cusum_stat' < 0.948 {
        di as res "Stable"
    }
    else {
        di as err "Unstable"
    }
    di as txt _col(7) "critical values: 1% 1.1430   5% 0.9479   10% 0.8499"
    di as txt _col(7) "{it:(same scale as -estat sbcusum-; may differ marginally because}"
    di as txt _col(7) "{it: the first, exactly identified recursive residual is omitted)}"

    // ---- CUSUM of squares ----
    // s_t = sum_{j<=t} w_j^2 / sum_{all} w_j^2, compared with the mean line
    // (t-k)/(T-k) plus/minus c0. c0 is the Kolmogorov-Smirnov approximation
    // to the Brown-Durbin-Evans table: 1.358/sqrt(T-k-1) at 5%.
    tempvar w2 sq sline
    qui gen double `w2' = `wrec'^2 if !missing(`wrec')
    qui sum `w2', meanonly
    local tot = r(sum)

    local c0 = 1.358 / sqrt(`nk' - 1)

    qui gen double `sq' = sum(cond(missing(`w2'), 0, `w2')) / `tot' if !missing(`wrec')
    qui gen double `sline' = `tt' / `nk'

    tempvar sdev
    qui gen double `sdev' = abs(`sq' - `sline') if !missing(`sq')
    qui sum `sdev', meanonly
    local sq_max = r(max)

    di as txt _col(5) "CUSUM of squares" _col(38) as res %10.4f `sq_max' _col(53) _c
    if `sq_max' < `c0' {
        di as res "Stable"
    }
    else {
        di as err "Unstable"
    }
    di as txt _col(7) "5% critical value: " as res %6.4f `c0' as txt ///
       " (Kolmogorov-Smirnov approximation to the BDE table)"

    return scalar cusum_stat = `cusum_stat'
    return scalar cusum_cv5 = 0.948
    return scalar cusumsq_max = `sq_max'
    return scalar cusumsq_cv = `c0'

    // ---- graphs ----
    if "`nographs'" != "" exit

    capture noisily {
        tempvar upper lower sup slo
        qui gen double `upper' = `cband'
        qui gen double `lower' = -`cband'
        qui gen double `sup' = `sline' + `c0'
        qui gen double `slo' = `sline' - `c0'

        twoway (line `cw' `tt', lcolor("24 54 104") lwidth(medthick)) ///
               (line `upper' `tt', lcolor("220 50 47") lpattern(dash)) ///
               (line `lower' `tt', lcolor("220 50 47") lpattern(dash)), ///
               title("{bf:CUSUM of Recursive Residuals}", size(medlarge) color("24 54 104")) ///
               subtitle("Brown, Durbin & Evans (1975), 5% bands", size(small) color(gs6)) ///
               xtitle("Observation (within estimation sample)", size(medsmall)) ///
               ytitle("Cumulative sum", size(medsmall)) ///
               legend(order(1 "CUSUM" 2 "5% bands") size(small) cols(2) ///
                   ring(0) pos(1) region(fcolor(white%80) lcolor(gs12))) ///
               graphregion(fcolor(white) lcolor(white)) ///
               plotregion(fcolor(white) lcolor(gs14)) ///
               ylabel(, labsize(small) angle(0) grid glcolor(gs14%50)) ///
               xlabel(, labsize(small) grid glcolor(gs14%50)) ///
               scheme(s2color) name(fbardl_cusum, replace)
        qui graph export "cusum.png", replace width(1400)

        twoway (line `sq' `tt', lcolor("52 168 83") lwidth(medthick)) ///
               (line `sup' `tt', lcolor("220 50 47") lpattern(dash)) ///
               (line `slo' `tt', lcolor("220 50 47") lpattern(dash)), ///
               title("{bf:CUSUM of Squares}", size(medlarge) color("24 54 104")) ///
               subtitle("Brown, Durbin & Evans (1975), 5% bands", size(small) color(gs6)) ///
               xtitle("Observation (within estimation sample)", size(medsmall)) ///
               ytitle("Cumulative sum of squares", size(medsmall)) ///
               legend(order(1 "CUSUM-SQ" 2 "5% bands") size(small) cols(2) ///
                   ring(0) pos(5) region(fcolor(white%80) lcolor(gs12))) ///
               graphregion(fcolor(white) lcolor(white)) ///
               plotregion(fcolor(white) lcolor(gs14)) ///
               ylabel(, labsize(small) angle(0) grid glcolor(gs14%50)) ///
               xlabel(, labsize(small) grid glcolor(gs14%50)) ///
               scheme(s2color) name(fbardl_cusumsq, replace)
        qui graph export "cusumsq.png", replace width(1400)

        di as txt _col(5) "Graphs saved: cusum.png, cusumsq.png"
    }
end


// =============================================================================
// Pull the statistic and p-value out of the last estat command.
// Stata returns these sometimes as scalars (estat hettest, estat imtest) and
// sometimes as 1 x k matrices (estat bgodfrey, estat durbinalt, estat archlm).
// Reading the wrong form is why these rows previously came back empty.
// Both are extracted in ONE call: r() must not be re-read afterwards.
// =============================================================================
capture program drop _fbardl_rval
program define _fbardl_rval
    version 17
    tempname M
    local s = .
    local pp = .

    // Different estat commands store the statistic under different names:
    //   estat bgodfrey, estat durbinalt, estat hettest, estat imtest -> r(chi2)
    //   estat archlm                                                 -> r(arch)
    // and each may be a scalar or a 1 x k matrix. Try each in turn.
    foreach nm in chi2 arch F stat {
        if missing(`s') {
            capture mat `M' = r(`nm')
            if _rc == 0 {
                capture local s = `M'[1, 1]
            }
            else {
                capture local s = r(`nm')
            }
        }
    }

    capture mat `M' = r(p)
    if _rc == 0 {
        capture local pp = `M'[1, 1]
    }
    else {
        capture local pp = r(p)
    }

    c_local _fb_stat `s'
    c_local _fb_p `pp'
end
