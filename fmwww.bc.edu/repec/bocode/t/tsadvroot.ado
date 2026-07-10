*! tsadvroot 1.2.0  08jul2026
*! Advanced time-series unit-root tests:
*!   qadf  - quantile ADF (Koenker & Xiao 2004)
*!   fqadf - Fourier quantile ADF (Li & Zheng 2018) with residual bootstrap
*!   npadf - two-break ADF (Narayan & Popp 2010): grid (tspdlib) default,
*!           plus sequential/simultaneous impulse-dummy procedures (paper)
*!   cisur - GLS unit-root tests with multiple structural breaks
*!           (Carrion-i-Silvestre, Kim & Perron 2009)
*! Exact Stata translation of the GAUSS routines by Saban Nazlioglu (tspdlib)
*! and Josep Lluis Carrion-i-Silvestre (based on Ng & Perron 2001 code).
*! Author: Merwan Roudane, merwanroudane920@gmail.com
*! https://github.com/merwanroudane

program define tsadvroot, rclass
    version 14.0
    gettoken sub rest : 0, parse(" ,")
    local sub = lower(`"`sub'"')
    if ("`sub'" == "qadf") {
        tsadvroot_qadf `rest'
    }
    else if inlist("`sub'", "fqadf", "qfadf", "fourierqadf") {
        tsadvroot_fqadf `rest'
    }
    else if inlist("`sub'", "npadf", "np", "adf2b") {
        tsadvroot_npadf `rest'
    }
    else if inlist("`sub'", "cisur", "cis", "gls") {
        tsadvroot_cisur `rest'
    }
    else if ("`sub'" == "") {
        di as err "subcommand required: {bf:qadf} | {bf:fqadf} | {bf:npadf} | {bf:cisur}"
        di as err "see {helpb tsadvroot} for details"
        exit 198
    }
    else {
        di as err `"unknown tsadvroot subcommand "`sub'""'
        di as err "valid subcommands: {bf:qadf} | {bf:fqadf} | {bf:npadf} | {bf:cisur}"
        exit 199
    }
    return add
end

*==============================================================================
* Common checks: tsset, no panel, contiguous sample
* (touse is created by the CALLER and passed by name; see help gotchas)
*==============================================================================
program define _tsav_check, rclass
    version 14.0
    args touse
    capture qui tsset
    if _rc {
        di as err "data must be {helpb tsset} with a time variable"
        exit 459
    }
    if "`r(panelvar)'" != "" {
        di as err "tsadvroot works on a single time series; data are xtset with panel variable {bf:`r(panelvar)'}"
        di as err "use {cmd:if} to select one unit, or {cmd:tsset} the series"
        exit 459
    }
    local tvar "`r(timevar)'"
    qui tsreport if `touse'
    if r(N_gaps) > 0 {
        di as err "the estimation sample contains `r(N_gaps)' gap(s) in `tvar'"
        di as err "unit-root tests require a contiguous series (no gaps, no interior if/in holes)"
        exit 498
    }
    qui count if `touse'
    return scalar T = r(N)
    return local tvar "`tvar'"
end

*==============================================================================
* SUBCOMMAND 1 : qadf  --  Koenker & Xiao (2004) quantile ADF
* Exact translation of qr_adf.src (QRADF proc, fourier=0 path)
*==============================================================================
program define tsadvroot_qadf, rclass
    version 14.0
    syntax varname(ts) [if] [in] [, Tau(numlist >0 <1 sort) Model(string) ///
        PMax(integer 8) IC(string) GRaph NAme(string) noPRint ]

    local yv `varlist'

    * ---- defaults & validation -------------------------------------------
    if "`tau'" == "" local tau "0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"
    if "`model'" == "" local model "c"
    local model = lower("`model'")
    if inlist("`model'", "c", "1", "constant") local mnum 1
    else if inlist("`model'", "ct", "2", "trend") local mnum 2
    else {
        di as err "model() must be {bf:c} (constant) or {bf:ct} (constant and trend)"
        exit 198
    }
    if "`ic'" == "" local ic "tstat"
    local ic = lower("`ic'")
    if inlist("`ic'", "aic", "1") local icn 1
    else if inlist("`ic'", "sic", "bic", "2") local icn 2
    else if inlist("`ic'", "tstat", "t", "3") local icn 3
    else {
        di as err "ic() must be {bf:aic}, {bf:sic} or {bf:tstat}"
        exit 198
    }
    if `pmax' < 0 {
        di as err "pmax() must be non-negative"
        exit 198
    }

    * ---- sample -----------------------------------------------------------
    marksample touse
    _tsav_check `touse'
    local T = r(T)
    local tvar "`r(tvar)'"
    if `T' < `pmax' + 15 {
        di as err "insufficient observations (T=`T') for pmax(`pmax')"
        exit 2001
    }

    * protect the user's e() results (we run qreg internally)
    tempname ehold
    capture _estimates hold `ehold', restore nullok

    * ---- lag selection: GAUSS { ADFt, p, cv } = ADF(y, 1, pmax, ic) --------
    mata: _tsav_adfsel_st("`yv'", "`touse'", `pmax', `icn')
    local p = r(adflag)

    * ---- build regressors on the estimation sample -------------------------
    * GAUSS trims the first p+1 observations: sample = positions p+2 .. T
    tempvar pos esamp y1
    qui gen long `pos' = sum(`touse')
    qui gen byte `esamp' = `touse' & (`pos' > `p' + 1)
    qui gen double `y1' = L.`yv' if `touse'
    local xvars "`y1'"
    forvalues j = 1/`p' {
        tempvar dy`j'
        qui gen double `dy`j'' = L`j'.D.`yv' if `touse'
        local xvars "`xvars' `dy`j''"
    }
    if `mnum' == 2 {
        tempvar trnd
        qui gen double `trnd' = `pos' if `touse'
        local xvars "`xvars' `trnd'"
    }
    qui count if `esamp'
    local neff = r(N)

    * ---- per-quantile computation ------------------------------------------
    local ntau : word count `tau'
    tempname R b0 b1 b2
    matrix `R' = J(`ntau', 8, .)
    local row 0
    foreach t of local tau {
        local ++row
        * bandwidth h (GAUSS __get_qr_adf_h)
        mata: st_local("h", strofreal(_tsav_h(`t', `neff'), "%18.0g"))
        local t1 = `t' + `h'
        if `t1' >= 1 local t1 = .9999
        local t2 = `t' - `h'
        if `t2' <= 0 local t2 = .0001
        capture qui qreg `yv' `xvars' if `esamp', quantile(`t')
        if _rc {
            di as err "qreg failed at tau = `t' (rc = " _rc ")"
            exit _rc
        }
        matrix `b0' = e(b)
        capture qui qreg `yv' `xvars' if `esamp', quantile(`t1')
        if _rc {
            di as err "qreg failed at tau+h = `t1' (rc = " _rc ")"
            exit _rc
        }
        matrix `b1' = e(b)
        capture qui qreg `yv' `xvars' if `esamp', quantile(`t2')
        if _rc {
            di as err "qreg failed at tau-h = `t2' (rc = " _rc ")"
            exit _rc
        }
        matrix `b2' = e(b)
        mata: _tsav_qadf_one("`R'", `row', "`yv'", "`xvars'", "`esamp'", ///
            `t', `h', "`b0'", "`b1'", "`b2'", `p', 0, `mnum')
    }
    matrix colnames `R' = tau rho_tau rho_ols delta2 tn cv1 cv5 cv10

    * ---- display ------------------------------------------------------------
    if "`print'" == "" {
        local mlab "constant"
        if `mnum' == 2 local mlab "constant and trend"
        local iclab "AIC"
        if `icn' == 2 local iclab "SIC"
        if `icn' == 3 local iclab "t-stat (1.645)"
        di
        di as text "{hline 82}"
        di as text "Quantile ADF unit-root test" _col(50) "Koenker & Xiao (2004, JASA)"
        di as text "{hline 82}"
        di as text "Variable      : " as result "`yv'" ///
            as text _col(44) "Obs (effective) = " as result %8.0f `neff'
        di as text "Model         : " as result "`mlab'" ///
            as text _col(44) "Max lags        = " as result %8.0f `pmax'
        di as text "Lag selection : " as result "`iclab'" ///
            as text _col(44) "Lags selected   = " as result %8.0f `p'
        di as text "{hline 82}"
        di as text "    tau    rho(tau)    rho(OLS)    delta{c 94}2     t_n(tau)" ///
            "        1%       5%      10%"
        di as text "{hline 82}"
        forvalues i = 1/`ntau' {
            local st ""
            if `R'[`i',5] < `R'[`i',6] local st "***"
            else if `R'[`i',5] < `R'[`i',7] local st "**"
            else if `R'[`i',5] < `R'[`i',8] local st "*"
            di as text %7.2f `R'[`i',1] ///
                as result %12.4f `R'[`i',2] %12.4f `R'[`i',3] ///
                %11.4f `R'[`i',4] %13.3f `R'[`i',5] as text %-4s "`st'" ///
                as result %8.3f `R'[`i',6] %9.3f `R'[`i',7] %9.3f `R'[`i',8]
        }
        di as text "{hline 82}"
        di as text "H0: unit root at quantile tau, i.e. rho(tau) = 1."
        di as text "Critical values: Hansen (1995), interpolated on delta{c 94}2" ///
            " as in Koenker & Xiao (2004)."
        di as text "Rejection: * p<0.10, ** p<0.05, *** p<0.01 (t_n below the critical value)."
        di as text "{hline 82}"
    }

    * ---- graph (before return matrix; gotcha: return matrix moves) ----------
    if "`graph'" != "" {
        if `ntau' < 2 {
            di as text "(graph skipped: needs at least two quantiles in tau())"
        }
        else {
            local gname "`name'"
            if "`gname'" == "" local gname "tsavqadf"
            tempname RG
            matrix `RG' = `R'
            preserve
            qui clear
            qui svmat double `RG', name(_tq)
            local gopt graphregion(color(white)) plotregion(color(white)) ///
                ylabel(, angle(horizontal) grid glcolor(gs14) glwidth(vthin)) ///
                xlabel(, grid glcolor(gs14) glwidth(vthin))
            twoway (line _tq2 _tq1, lcolor(navy) lwidth(medthick)) ///
                   (scatter _tq2 _tq1, mcolor(navy) msymbol(O)), ///
                yline(1, lpattern(dash) lcolor(gs8)) ///
                ytitle("{&rho}({&tau})") xtitle("") ///
                title("Persistence  {&rho}({&tau})", size(medsmall) color(black)) ///
                legend(off) `gopt' name(`gname'_rho, replace) nodraw
            twoway (line _tq6 _tq1, lpattern(shortdash) lcolor(gs6)) ///
                   (line _tq7 _tq1, lpattern(dash) lcolor(maroon)) ///
                   (line _tq8 _tq1, lpattern(longdash_dot) lcolor(gs10)) ///
                   (line _tq5 _tq1, lcolor(navy) lwidth(medthick)) ///
                   (scatter _tq5 _tq1, mcolor(navy) msymbol(O)), ///
                ytitle("t{sub:n}({&tau})") xtitle("Quantile {&tau}") ///
                title("Quantile ADF statistic", size(medsmall) color(black)) ///
                legend(order(4 "t{sub:n}({&tau})" 1 "1% cv" 2 "5% cv" 3 "10% cv") ///
                    rows(1) size(small) region(lstyle(none))) ///
                `gopt' name(`gname'_tn, replace) nodraw
            graph combine `gname'_rho `gname'_tn, cols(1) iscale(0.9) ///
                graphregion(color(white)) ///
                title("Quantile ADF unit-root test: `yv'", size(medium) color(black)) ///
                note("Koenker & Xiao (2004); Hansen (1995) critical values.", ///
                    size(vsmall)) name(`gname', replace)
            restore
        }
    }

    * ---- returns -------------------------------------------------------------
    return scalar T = `T'
    return scalar N = `neff'
    return scalar lags = `p'
    return local model = cond(`mnum' == 1, "c", "ct")
    return local ic "`ic'"
    return local tau "`tau'"
    return local varname "`yv'"
    return local cmd "tsadvroot qadf"
    if `ntau' == 1 {
        return scalar tau = `R'[1,1]
        return scalar rho_tau = `R'[1,2]
        return scalar rho_ols = `R'[1,3]
        return scalar delta2 = `R'[1,4]
        return scalar tn = `R'[1,5]
        return scalar cv1 = `R'[1,6]
        return scalar cv5 = `R'[1,7]
        return scalar cv10 = `R'[1,8]
    }
    return matrix results = `R', copy
end

*==============================================================================
* SUBCOMMAND 2 : fqadf  --  Li & Zheng (2018) Fourier quantile ADF
* Exact translation of qr_fourier_adf.src
* (QR_Fourier_ADF and QR_Fourier_ADF_bootstrap)
*==============================================================================
program define tsadvroot_fqadf, rclass
    version 14.0
    syntax varname(ts) [if] [in] [, Tau(numlist >0 <1 sort) Model(string) ///
        Lags(integer 8) Freq(integer 3) NBoot(integer 1000) SEED(integer 0) ///
        noBOOTstrap GRaph NAme(string) noPRint ]

    local yv `varlist'
    local p = `lags'
    local k = `freq'

    if "`tau'" == "" local tau "0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"
    if "`model'" == "" local model "c"
    local model = lower("`model'")
    if inlist("`model'", "c", "1", "constant") local mnum 1
    else if inlist("`model'", "ct", "2", "trend") local mnum 2
    else {
        di as err "model() must be {bf:c} or {bf:ct}"
        exit 198
    }
    if `p' < 0 {
        di as err "lags() must be non-negative"
        exit 198
    }
    if `k' < 1 {
        di as err "freq() must be a positive integer"
        exit 198
    }
    if `nboot' < 0 {
        di as err "nboot() must be non-negative"
        exit 198
    }
    if "`bootstrap'" != "" local nboot 0

    marksample touse
    _tsav_check `touse'
    local T = r(T)
    local tvar "`r(tvar)'"
    if `T' < `p' + 20 {
        di as err "insufficient observations (T=`T') for lags(`p')"
        exit 2001
    }

    tempname ehold
    capture _estimates hold `ehold', restore nullok

    * ---- observed statistics (exact QR_Fourier_ADF) --------------------------
    local ntau : word count `tau'
    tempname R
    matrix `R' = J(`ntau', 8, .)
    tsadvroot_fqadf_core `yv' if `touse', taulist(`tau') model(`mnum') ///
        p(`p') k(`k') rmat(`R')
    local neff = r(neff)

    * ---- bootstrap (exact QR_Fourier_ADF_bootstrap) ---------------------------
    tempname BS
    matrix `BS' = J(`ntau', 7, .)
    if `nboot' > 0 {
        if "`print'" == "" {
            di as text "(running " as result `nboot' ///
                as text " bootstrap replications, this may take a while...)"
        }
        * residuals of the null model on the full sample -> __tsav_mu (Mata)
        mata: _tsav_fq_prep("`yv'", "`touse'", `mnum', `p', `k')
        local tt = r(tt)
        tempname tnobs BR
        matrix `tnobs' = `R'[1..., 5]
        matrix `BR' = J(`ntau', 8, .)
        preserve
        qui drop _all
        qui set obs `tt'
        tempvar tb yb
        qui gen long `tb' = _n
        qui tsset `tb'
        qui gen double `yb' = .
        local corecmd "quietly tsadvroot_fqadf_core `yb', taulist(`tau') model(`mnum') p(`p') k(`k') rmat(`BR')"
        mata: _tsav_fq_boot("`yb'", `tt', `nboot', st_local("corecmd"), ///
            "`BR'", `ntau', "`BS'", "`tnobs'", `seed')
        restore
        capture mata: mata drop __tsav_mu
    }
    matrix colnames `R' = tau rho_tau rho_ols delta2 tn cv1 cv5 cv10
    matrix colnames `BS' = cvlt1 cvlt5 cvlt10 cvsrc1 cvsrc5 cvsrc10 pboot

    * ---- display ---------------------------------------------------------------
    if "`print'" == "" {
        local mlab "constant"
        if `mnum' == 2 local mlab "constant and trend"
        di
        di as text "{hline 82}"
        di as text "Fourier quantile ADF unit-root test" _col(48) ///
            "Li & Zheng (2018, Fin Res Letters)"
        di as text "{hline 82}"
        di as text "Variable      : " as result "`yv'" ///
            as text _col(44) "Obs (effective) = " as result %8.0f `neff'
        di as text "Model         : " as result "`mlab'" ///
            as text _col(44) "Lags (fixed)    = " as result %8.0f `p'
        di as text "Fourier freq. : " as result "`k'" ///
            as text _col(44) "Bootstrap reps  = " as result %8.0f `nboot'
        di as text "{hline 82}"
        if `nboot' > 0 {
            di as text "    tau    rho(tau)     F-QADF t_n    boot p" ///
                "        1%       5%      10%   (bootstrap cv)"
        }
        else {
            di as text "    tau    rho(tau)     F-QADF t_n"
        }
        di as text "{hline 82}"
        forvalues i = 1/`ntau' {
            if `nboot' > 0 {
                local st ""
                if `R'[`i',5] < `BS'[`i',1] local st "***"
                else if `R'[`i',5] < `BS'[`i',2] local st "**"
                else if `R'[`i',5] < `BS'[`i',3] local st "*"
                di as text %7.2f `R'[`i',1] ///
                    as result %12.4f `R'[`i',2] %14.3f `R'[`i',5] ///
                    as text %-4s "`st'" ///
                    as result %8.3f `BS'[`i',7] ///
                    %10.3f `BS'[`i',1] %9.3f `BS'[`i',2] %9.3f `BS'[`i',3]
            }
            else {
                di as text %7.2f `R'[`i',1] ///
                    as result %12.4f `R'[`i',2] %14.3f `R'[`i',5]
            }
        }
        di as text "{hline 82}"
        di as text "H0: unit root at quantile tau (with smooth structural change)."
        if `nboot' > 0 {
            di as text "Displayed cv: left-tail (1st/5th/10th percentile)" ///
                " of the bootstrap distribution;"
            di as text "boot p = share of bootstrap t_n below the observed t_n."
            di as text "The GAUSS-source order statistics (0.99/0.95/0.90)" ///
                " are stored in r(boot) cols 4-6."
            di as text "Rejection: * p<0.10, ** p<0.05, *** p<0.01."
        }
        else {
            di as text "No critical values displayed: use the bootstrap" ///
                " (option nboot(#)) for inference."
        }
        di as text "{hline 82}"
    }

    * ---- graph -------------------------------------------------------------------
    if "`graph'" != "" {
        if `ntau' < 2 {
            di as text "(graph skipped: needs at least two quantiles in tau())"
        }
        else {
            local gname "`name'"
            if "`gname'" == "" local gname "tsavfqadf"
            tempname RG
            matrix `RG' = `R'[1..., 1], `R'[1..., 5], `BS'[1..., 1..3]
            preserve
            qui clear
            qui svmat double `RG', name(_tf)
            local gopt graphregion(color(white)) plotregion(color(white)) ///
                ylabel(, angle(horizontal) grid glcolor(gs14) glwidth(vthin)) ///
                xlabel(, grid glcolor(gs14) glwidth(vthin))
            if `nboot' > 0 {
                twoway (line _tf3 _tf1, lpattern(shortdash) lcolor(gs6)) ///
                       (line _tf4 _tf1, lpattern(dash) lcolor(maroon)) ///
                       (line _tf5 _tf1, lpattern(longdash_dot) lcolor(gs10)) ///
                       (line _tf2 _tf1, lcolor(navy) lwidth(medthick)) ///
                       (scatter _tf2 _tf1, mcolor(navy) msymbol(O)), ///
                    ytitle("t{sub:n}({&tau})") xtitle("Quantile {&tau}") ///
                    title("Fourier quantile ADF test: `yv'", size(medium) color(black)) ///
                    subtitle("Fourier frequency k = `k', p = `p' lags", ///
                        size(small)) ///
                    legend(order(4 "F-QADF t{sub:n}({&tau})" 1 "1% cv" ///
                        2 "5% cv" 3 "10% cv") rows(1) size(small) ///
                        region(lstyle(none))) ///
                    note("Bootstrap critical values (left tail), B = `nboot'." ///
                        , size(vsmall)) ///
                    `gopt' name(`gname', replace)
            }
            else {
                twoway (line _tf2 _tf1, lcolor(navy) lwidth(medthick)) ///
                       (scatter _tf2 _tf1, mcolor(navy) msymbol(O)), ///
                    ytitle("t{sub:n}({&tau})") xtitle("Quantile {&tau}") ///
                    title("Fourier quantile ADF test: `yv'", size(medium) color(black)) ///
                    legend(off) `gopt' name(`gname', replace)
            }
            restore
        }
    }

    * ---- returns --------------------------------------------------------------------
    return scalar T = `T'
    return scalar N = `neff'
    return scalar lags = `p'
    return scalar k = `k'
    return scalar nboot = `nboot'
    return local model = cond(`mnum' == 1, "c", "ct")
    return local tau "`tau'"
    return local varname "`yv'"
    return local cmd "tsadvroot fqadf"
    if `ntau' == 1 {
        return scalar tn = `R'[1,5]
        return scalar rho_tau = `R'[1,2]
        return scalar delta2 = `R'[1,4]
        if `nboot' > 0 {
            return scalar pboot = `BS'[1,7]
            return scalar cv1 = `BS'[1,1]
            return scalar cv5 = `BS'[1,2]
            return scalar cv10 = `BS'[1,3]
            return scalar cvsrc1 = `BS'[1,4]
            return scalar cvsrc5 = `BS'[1,5]
            return scalar cvsrc10 = `BS'[1,6]
        }
    }
    if `nboot' > 0 {
        return matrix boot = `BS', copy
    }
    return matrix results = `R', copy
end

*------------------------------------------------------------------------------
* fqadf computational core -- shared by the observed test and the bootstrap.
* Assumes a tsset, contiguous series. Fills rmat (ntau x 8):
*   tau  rho_tau  .  delta2  tn  .  .  .
* Exact translation of QR_Fourier_ADF (print branch excluded):
*   trims p+1 obs, THEN builds the Fourier terms on the trimmed length,
*   x = [y1, dyl(1..p), sin, cos, (trend = original index)].
*------------------------------------------------------------------------------
program define tsadvroot_fqadf_core, rclass
    version 14.0
    syntax varname [if] [, TAUlist(numlist >0 <1) MODel(integer 1) ///
        P(integer 8) K(integer 3) RMAT(string) ]

    local yv `varlist'
    marksample touse
    qui count if `touse'
    local T = r(N)
    local neff = `T' - `p' - 1
    if `neff' < `p' + 8 {
        di as err "fqadf core: series too short (T=`T', lags=`p')"
        exit 2001
    }

    tempvar pos esamp y1 sink cosk
    qui gen long `pos' = sum(`touse')
    qui gen byte `esamp' = `touse' & (`pos' > `p' + 1)
    qui gen double `y1' = L.`yv' if `touse'
    local xvars "`y1'"
    forvalues j = 1/`p' {
        tempvar dy`j'
        qui gen double `dy`j'' = L`j'.D.`yv' if `touse'
        local xvars "`xvars' `dy`j''"
    }
    * Fourier terms: sequence restarts at 1 on the trimmed sample and the
    * denominator is the trimmed length (exact source behaviour)
    qui gen double `sink' = sin(2*_pi*`k'*(`pos'-`p'-1)/`neff') if `esamp'
    qui gen double `cosk' = cos(2*_pi*`k'*(`pos'-`p'-1)/`neff') if `esamp'
    local xvars "`xvars' `sink' `cosk'"
    if `model' == 2 {
        tempvar trnd
        qui gen double `trnd' = `pos' if `touse'
        local xvars "`xvars' `trnd'"
    }

    tempname b0 b1 b2
    local row 0
    foreach t of local taulist {
        local ++row
        mata: st_local("h", strofreal(_tsav_h(`t', `neff'), "%18.0g"))
        local t1 = `t' + `h'
        if `t1' >= 1 local t1 = .9999
        local t2 = `t' - `h'
        if `t2' <= 0 local t2 = .0001
        capture qui qreg `yv' `xvars' if `esamp', quantile(`t')
        if _rc {
            di as err "qreg failed at tau = `t' (rc = " _rc ")"
            exit _rc
        }
        matrix `b0' = e(b)
        capture qui qreg `yv' `xvars' if `esamp', quantile(`t1')
        if _rc {
            di as err "qreg failed at tau+h = `t1' (rc = " _rc ")"
            exit _rc
        }
        matrix `b1' = e(b)
        capture qui qreg `yv' `xvars' if `esamp', quantile(`t2')
        if _rc {
            di as err "qreg failed at tau-h = `t2' (rc = " _rc ")"
            exit _rc
        }
        matrix `b2' = e(b)
        mata: _tsav_qadf_one("`rmat'", `row', "`yv'", "`xvars'", "`esamp'", ///
            `t', `h', "`b0'", "`b1'", "`b2'", `p', 1, `model')
    }
    return scalar neff = `neff'
end

*==============================================================================
* SUBCOMMAND 3 : npadf  --  Narayan & Popp (2010) two-break unit-root test
* Exact translation of narayan pop.src (ADF_2breaks)
*==============================================================================
program define tsadvroot_npadf, rclass
    version 14.0
    syntax varname(ts) [if] [in] [, Model(string) PMax(integer 8) IC(string) ///
        TRim(real 0.10) SEQuential SIMul GRaph NAme(string) noPRint ]

    local yv `varlist'
    if "`model'" == "" local model "1"
    local model = lower("`model'")
    if inlist("`model'", "1", "a", "level", "m1") local mnum 1
    else if inlist("`model'", "2", "c", "both", "m2") local mnum 2
    else {
        di as err "model() must be {bf:1} (M1: breaks in level) or {bf:2}" ///
            " (M2: breaks in level and slope)"
        exit 198
    }
    if "`ic'" == "" local ic "tstat"
    local ic = lower("`ic'")
    if inlist("`ic'", "aic", "1") local icn 1
    else if inlist("`ic'", "sic", "bic", "2") local icn 2
    else if inlist("`ic'", "tstat", "t", "3") local icn 3
    else {
        di as err "ic() must be {bf:aic}, {bf:sic} or {bf:tstat}"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        di as err "trim() must be strictly between 0 and 0.5"
        exit 198
    }
    * ---- break-search procedure ------------------------------------------
    * mode 0 = tspdlib/GAUSS grid (min ADF-t, no impulse dummies)  [default]
    * mode 1 = Narayan-Popp (2010) sequential  (Eqs. 10-11, impulse dummies)
    * mode 2 = Narayan-Popp (2010) simultaneous(Eq. 9,     impulse dummies)
    local seq = ("`sequential'" != "")
    local sim = ("`simul'" != "")
    if `seq' & `sim' {
        di as err "{bf:sequential} and {bf:simul} cannot be combined;" ///
            " choose one break-search procedure"
        exit 198
    }
    local mode = cond(`seq', 1, cond(`sim', 2, 0))

    marksample touse
    _tsav_check `touse'
    local T = r(T)
    local tvar "`r(tvar)'"
    if `T' < 2*`pmax' + 20 {
        di as err "insufficient observations (T=`T') for pmax(`pmax')"
        exit 2001
    }

    if "`print'" == "" {
        di as text "(search over two break dates, this may take a moment...)"
    }
    mata: _tsav_np("`yv'", "`touse'", `mnum', `pmax', `icn', `trim', `mode')
    local stat = r(npstat)
    local tb1p = r(tb1)
    local tb2p = r(tb2)
    local plag = r(nplag)
    local cv1 = r(cv1)
    local cv5 = r(cv5)
    local cv10 = r(cv10)
    local fstat = r(fstat)

    * map break positions to time values
    tempvar pos
    qui gen long `pos' = sum(`touse')
    qui su `tvar' if `pos' == `tb1p' & `touse', meanonly
    local tb1 = r(min)
    qui su `tvar' if `pos' == `tb2p' & `touse', meanonly
    local tb2 = r(min)
    local tf : format `tvar'
    local tb1s = string(`tb1', "`tf'")
    local tb2s = string(`tb2', "`tf'")

    local st ""
    if `stat' < `cv1' local st "***"
    else if `stat' < `cv5' local st "**"
    else if `stat' < `cv10' local st "*"

    local bstxt "grid, minimum ADF-t (tspdlib/GAUSS)"
    if `mode' == 1 local bstxt "sequential, max |t| on impulse (NP Eqs. 10-11)"
    if `mode' == 2 local bstxt "simultaneous, max joint-impulse F (NP Eq. 9)"

    if "`print'" == "" {
        local mlab "M1: two breaks in level"
        if `mnum' == 2 local mlab "M2: two breaks in level and slope"
        local iclab "AIC"
        if `icn' == 2 local iclab "SIC"
        if `icn' == 3 local iclab "t-stat (1.645)"
        di
        di as text "{hline 78}"
        di as text "Narayan & Popp (2010) unit-root test with two structural breaks"
        di as text "{hline 78}"
        di as text "Variable      : " as result "`yv'" ///
            as text _col(44) "Obs             = " as result %8.0f `T'
        di as text "Model         : " as result "`mlab'"
        di as text "Break search  : " as result "`bstxt'"
        di as text "Lag selection : " as result "`iclab'" ///
            as text _col(44) "Lags selected   = " as result %8.0f `plag'
        di as text "Trimming      : " as result %5.2f `trim'
        if `mode' == 2 {
            di as text "Impulse joint F: " as result %8.3f `fstat' ///
                as text "  (at the selected break pair)"
        }
        di as text "{hline 78}"
        di as text "   ADF-stat        TB1          TB2          1%       5%      10%"
        di as text "{hline 78}"
        di as result %10.3f `stat' as text "`st'" ///
            as result _col(17) %10s "`tb1s'" _col(30) %10s "`tb2s'" ///
            _col(43) %9.3f `cv1' %9.3f `cv5' %9.3f `cv10'
        di as text "{hline 78}"
        di as text "H0: unit root with two breaks in the DGP."
        if `mode' == 0 {
            di as text "Grid path (tspdlib): additive step/trend dummies," ///
                " breaks chosen by min ADF-t."
        }
        else {
            di as text "Paper form (NP Eqs. 7-8): innovational-outlier impulse" ///
                " dummies included;"
            di as text "breaks chosen by the significance of the impulse" ///
                " coefficients."
        }
        di as text "Break dates are the last period of each pre-break regime" ///
            " (level shift starts at TB+1)."
        di as text "Critical values: Narayan & Popp (2010), Table 3, T = `T'."
        di as text "Rejection: * p<0.10, ** p<0.05, *** p<0.01."
        di as text "{hline 78}"
    }

    if "`graph'" != "" {
        local gname "`name'"
        if "`gname'" == "" local gname "tsavnpadf"
        local subt = "ADF = " + string(`stat', "%9.3f") + "`st'" + ///
            ",  TB1 = `tb1s',  TB2 = `tb2s'"
        twoway (line `yv' `tvar' if `touse', lcolor(navy) lwidth(medthin)), ///
            xline(`tb1' `tb2', lpattern(dash) lcolor(maroon)) ///
            ytitle("`yv'") xtitle("") ///
            title("Narayan-Popp two-break test: `yv'", size(medium) color(black)) ///
            subtitle("`subt'", size(small)) ///
            note("Dashed lines: estimated break dates.", size(vsmall)) ///
            graphregion(color(white)) plotregion(color(white)) ///
            ylabel(, angle(horizontal) grid glcolor(gs14) glwidth(vthin)) ///
            name(`gname', replace)
    }

    return scalar T = `T'
    return scalar stat = `stat'
    return scalar lags = `plag'
    return scalar tb1 = `tb1'
    return scalar tb2 = `tb2'
    return scalar tb1pos = `tb1p'
    return scalar tb2pos = `tb2p'
    return scalar frac1 = `tb1p'/`T'
    return scalar frac2 = `tb2p'/`T'
    return scalar cv1 = `cv1'
    return scalar cv5 = `cv5'
    return scalar cv10 = `cv10'
    return local model "`mnum'"
    return local ic "`ic'"
    return local breakdates "`tb1s' `tb2s'"
    local bsret "grid"
    if `mode' == 1 local bsret "sequential"
    if `mode' == 2 local bsret "simultaneous"
    return local breaksearch "`bsret'"
    if `mode' == 2 return scalar fstat = `fstat'
    return local varname "`yv'"
    return local cmd "tsadvroot npadf"
end

*==============================================================================
* SUBCOMMAND 4 : cisur  --  Carrion-i-Silvestre, Kim & Perron (2009)
* GLS-based unit-root tests with multiple structural breaks.
* Exact translation of carrion silvestre2009.src. Both source estimation
* paths are implemented: method(brute) = __sbur_multiple_gls_brute
* (estimation = 0, the sburControlCreate default; 1-3 unknown breaks) and
* method(dp) = __sbur_multiple_gls_algorithm (estimation = 1; 1-5 breaks).
*==============================================================================
program define tsadvroot_cisur, rclass
    version 14.0
    syntax varname(ts) [if] [in] [, Model(string) Breaks(integer 1) ///
        BREAKDates(numlist) METHod(string) MAXiter(integer 100) ///
        Penalty(string) KMax(integer 4) KMin(integer 0) ///
        GRaph NAme(string) noPRint ]

    local yv `varlist'
    if "`model'" == "" local model "break"
    local model = lower("`model'")
    if inlist("`model'", "0", "const", "constant") local mnum 0
    else if inlist("`model'", "1", "trend") local mnum 1
    else if inlist("`model'", "2", "slope") local mnum 2
    else if inlist("`model'", "3", "break", "both") local mnum 3
    else {
        di as err "model() must be one of: {bf:const} (0, constant, no breaks)," ///
            " {bf:trend} (1, linear trend, no breaks),"
        di as err "{bf:slope} (2, breaks in trend slope) or {bf:break}" ///
            " (3, breaks in level and slope)"
        exit 198
    }
    if "`penalty'" == "" local penalty "maic"
    local penalty = lower("`penalty'")
    if inlist("`penalty'", "maic", "0") local pen 0
    else if inlist("`penalty'", "bic", "1") local pen 1
    else {
        di as err "penalty() must be {bf:maic} or {bf:bic}"
        exit 198
    }
    if `kmin' < 0 | `kmax' < `kmin' {
        di as err "require 0 <= kmin() <= kmax()"
        exit 198
    }
    * ---- estimation method: brute (GAUSS estimation=0, sburControlCreate ----
    * ---- default) or dp (dynamic programming, GAUSS estimation=1) -----------
    if "`method'" == "" local method "brute"
    local method = lower("`method'")
    if inlist("`method'", "brute", "bruteforce", "grid", "0") local est 0
    else if inlist("`method'", "dp", "algorithm", "algo", "dynamic", "1") local est 1
    else {
        di as err "method() must be {bf:brute} (grid search, GAUSS" ///
            " estimation=0, the source default) or {bf:dp} (dynamic" ///
            " programming, GAUSS estimation=1)"
        exit 198
    }
    if `maxiter' < 1 {
        di as err "maxiter() must be a positive integer"
        exit 198
    }

    marksample touse
    _tsav_check `touse'
    local T = r(T)
    local tvar "`r(tvar)'"
    if `T' < `kmax' + 25 {
        di as err "insufficient observations (T=`T')"
        exit 2001
    }

    * ---- break setup -----------------------------------------------------------
    local known 0
    local m = `breaks'
    tempvar pos
    qui gen long `pos' = sum(`touse')
    tempname TB
    if `mnum' >= 2 {
        if "`breakdates'" != "" {
            local known 1
            local m : word count `breakdates'
            if `m' > 5 {
                di as err "at most 5 known break dates are allowed"
                exit 198
            }
            matrix `TB' = J(`m', 1, .)
            local i 0
            local prev = -1e300
            foreach d of numlist `breakdates' {
                local ++i
                if `d' <= `prev' {
                    di as err "breakdates() must be strictly increasing"
                    exit 198
                }
                local prev = `d'
                qui su `pos' if `touse' & float(`tvar') == float(`d'), meanonly
                if r(N) == 0 {
                    di as err "breakdates(): value `d' not found in `tvar'" ///
                        " within the sample"
                    exit 198
                }
                matrix `TB'[`i', 1] = r(min)
            }
        }
        else {
            if `est' == 0 & (`m' < 1 | `m' > 3) {
                di as err "with unknown break dates the brute-force search" ///
                    " (method(brute), the GAUSS-source default) supports" ///
                    " breaks(1) to breaks(3);"
                di as err "use {bf:method(dp)} for 4 or 5 unknown breaks," ///
                    " or supply known dates via breakdates()"
                exit 198
            }
            if `est' == 1 & (`m' < 1 | `m' > 5) {
                di as err "the dynamic-programming search supports breaks(1)" ///
                    " to breaks(5)"
                exit 198
            }
            if `est' == 1 {
                local h10 = int(0.10*`T')
                if `h10' < 5 | `T' < (`m'+2)*`h10' {
                    di as err "sample too short for method(dp) with breaks(`m')" ///
                        " and 10% trimming"
                    exit 2001
                }
            }
            if `est' == 0 & `m' == 3 & `T' > 150 & "`print'" == "" {
                di as text "(3 unknown breaks with T=`T': the O(T{c 94}3)" ///
                    " grid search may take several minutes)"
            }
        }
    }
    else {
        local m 0
    }
    if !`known' matrix `TB' = J(1, 1, 0)

    if "`print'" == "" & `mnum' >= 2 & !`known' {
        local howtxt "GLS-SSR grid search"
        if `est' == 1 local howtxt "the dynamic-programming algorithm"
        di as text "(searching for `m' break(s) by `howtxt'...)"
    }

    tempvar fitv
    qui gen double `fitv' = .
    tempname ST CV TBOUT
    mata: _tsav_cis("`yv'", "`touse'", `mnum', `known', "`TB'", `m', ///
        `pen', `kmax', `kmin', `est', `maxiter', "`fitv'", "`ST'", ///
        "`CV'", "`TBOUT'")
    local cbar = r(cbar)
    local krule = r(krule)

    * stats vector: pt mpt adf za mza msb mzt
    local pt = `ST'[1,1]
    local mpt = `ST'[1,2]
    local adf = `ST'[1,3]
    local za = `ST'[1,4]
    local mza = `ST'[1,5]
    local msb = `ST'[1,6]
    local mzt = `ST'[1,7]

    * break dates in time units
    local bdates ""
    local bxline ""
    local nbfound = rowsof(`TBOUT')
    if `mnum' >= 2 {
        local tf : format `tvar'
        forvalues i = 1/`nbfound' {
            local bp = `TBOUT'[`i',1]
            qui su `tvar' if `pos' == `bp' & `touse', meanonly
            local bd = r(min)
            local bds = string(`bd', "`tf'")
            local bdates "`bdates' `bds'"
            local bxline "`bxline' `bd'"
        }
    }

    * ---- display -------------------------------------------------------------------
    if "`print'" == "" {
        local mlab "constant, no breaks (Model 0)"
        if `mnum' == 1 local mlab "linear trend, no breaks (Model 1)"
        if `mnum' == 2 local mlab "breaks in the trend slope (Model 2)"
        if `mnum' == 3 local mlab "breaks in level and slope (Model 3)"
        local blab "estimated, brute-force GLS-SSR grid search"
        if `est' == 1 local blab "estimated, dynamic programming (dp)"
        if `known' local blab "known (user supplied)"
        local plab "MAIC"
        if `pen' == 1 local plab "BIC"
        di
        di as text "{hline 78}"
        di as text "GLS unit-root tests with multiple structural breaks"
        di as text "Carrion-i-Silvestre, Kim & Perron (2009, Econometric Theory)"
        di as text "{hline 78}"
        di as text "Variable   : " as result "`yv'" ///
            as text _col(44) "Obs           = " as result %8.0f `T'
        di as text "Model      : " as result "`mlab'"
        if `mnum' >= 2 {
            di as text "Breaks     : " as result "`nbfound'" ///
                as text "  `blab'"
            di as text "Break dates: " as result "`bdates'"
        }
        di as text "c-bar      : " as result %8.4f `cbar' ///
            as text _col(44) "Lags (`plab')   = " as result %8.0f `krule'
        di as text "{hline 78}"
        di as text "   Test        Statistic       1%      2.5%        5%       10%"
        di as text "{hline 78}"
        * cv rows in CV: 1=msb 2=mza 3=mzt 4=pt ; cols 1/2.5/5/10 as in source
        local names `""PT" "MPT" "ADF" "ZA" "MZA" "MSB" "MZT""'
        local cvrow "4 4 3 2 2 1 3"
        forvalues i = 1/7 {
            local nm : word `i' of `names'
            local cr : word `i' of `cvrow'
            local s = `ST'[1, `i']
            local c1 = `CV'[`cr', 1]
            local c25 = `CV'[`cr', 2]
            local c5 = `CV'[`cr', 3]
            local c10 = `CV'[`cr', 4]
            local st ""
            if `s' < `c1' local st "***"
            else if `s' < `c5' local st "**"
            else if `s' < `c10' local st "*"
            di as text %7s "`nm'" as result %14.3f `s' as text %-4s "`st'" ///
                as result %9.3f `c1' %10.3f `c25' %10.3f `c5' %10.3f `c10'
        }
        di as text "{hline 78}"
        di as text "H0: unit root. Tests reject for values BELOW the critical value." ///
            "  * p<.10 ** p<.05 *** p<.01."
        di as text "Critical values from the response surfaces in the GAUSS code of"
        di as text "Carrion-i-Silvestre et al. (2009), evaluated at the break fractions."
        di as text "{hline 78}"
    }

    * ---- graph -----------------------------------------------------------------------
    if "`graph'" != "" {
        local gname "`name'"
        if "`gname'" == "" local gname "tsavcisur"
        local xl ""
        if "`bxline'" != "" local xl xline(`bxline', lpattern(dash) lcolor(maroon))
        local ngtxt = "Dashed lines: break dates. MZt = " + ///
            string(`mzt', "%9.3f") + ", MSB = " + string(`msb', "%9.3f") + "."
        twoway (line `yv' `tvar' if `touse', lcolor(navy) lwidth(medthin)) ///
               (line `fitv' `tvar' if `touse', lcolor(dkorange) ///
                lwidth(medthick) lpattern(solid)), ///
            `xl' ytitle("`yv'") xtitle("") ///
            title("CiS-Kim-Perron GLS test: `yv'", size(medium) color(black)) ///
            subtitle("Broken deterministic trend (GLS estimates)", size(small)) ///
            legend(order(1 "`yv'" 2 "GLS trend") rows(1) size(small) ///
                region(lstyle(none))) ///
            note("`ngtxt'", size(vsmall)) ///
            graphregion(color(white)) plotregion(color(white)) ///
            ylabel(, angle(horizontal) grid glcolor(gs14) glwidth(vthin)) ///
            name(`gname', replace)
    }

    * ---- returns -----------------------------------------------------------------------
    return scalar T = `T'
    return scalar pt = `pt'
    return scalar mpt = `mpt'
    return scalar adf = `adf'
    return scalar za = `za'
    return scalar mza = `mza'
    return scalar msb = `msb'
    return scalar mzt = `mzt'
    return scalar cbar = `cbar'
    return scalar lags = `krule'
    return scalar nbreaks = cond(`mnum' >= 2, `nbfound', 0)
    return local model "`mnum'"
    return local method = cond(`est' == 1, "dp", "brute")
    return local penalty "`penalty'"
    return local breakdates "`bdates'"
    return local varname "`yv'"
    return local cmd "tsadvroot cisur"
    matrix rownames `CV' = MSB MZA MZT PT
    matrix colnames `CV' = cv1 cv2_5 cv5 cv10
    return matrix cv = `CV', copy
    if `mnum' >= 2 {
        return matrix breakpos = `TBOUT', copy
    }
    tempname STAB
    matrix `STAB' = `ST'
    matrix colnames `STAB' = PT MPT ADF ZA MZA MSB MZT
    return matrix stats = `STAB', copy
end

*==============================================================================
* Mata computational engine
*==============================================================================
version 14.0
mata:

// ---------------------------------------------------------------------------
// tspdlib _get_lag: index (1..pmax+1) of the selected lag+1
// ic 1 = AIC (first minimum), 2 = SIC, 3 = general-to-specific t-stat (1.645)
// ---------------------------------------------------------------------------
real scalar _tsav_getlagidx(real scalar ic, real colvector aicp,
    real colvector sicp, real colvector tstatp)
{
    real scalar pidx, j, n
    real colvector v

    n = rows(aicp)
    pidx = 1
    if (ic == 1) {
        v = aicp
        for (j = 2; j <= n; j++) {
            if (v[j] < v[pidx]) {
                pidx = j
            }
        }
    }
    else if (ic == 2) {
        v = sicp
        for (j = 2; j <= n; j++) {
            if (v[j] < v[pidx]) {
                pidx = j
            }
        }
    }
    else {
        pidx = 1
        j = n
        while (j >= 2) {
            if (tstatp[j] > 1.645) {
                pidx = j
                break
            }
            j = j - 1
        }
    }
    return(pidx)
}

// ---------------------------------------------------------------------------
// tspdlib ADF(y, 1, pmax, ic) lag selection (constant model)
// dep sample: dy trimmed twice (once for diff, once for p+1), regressors
// x = [y_{t-1}, const, dy lags]; aic/sic use the (k+2) penalty of the source
// Returns the selected LAG COUNT via r(adflag)
// ---------------------------------------------------------------------------
void _tsav_adfsel_st(string scalar yname, string scalar touse,
    real scalar pmax, real scalar ic)
{
    real colvector y
    real scalar p

    y = st_data(., yname, touse)
    p = _tsav_adfsel(y, pmax, ic)
    st_numscalar("r(adflag)", p)
}

real scalar _tsav_adfsel(real colvector y, real scalar pmax, real scalar ic)
{
    real scalar T, p, lo, n1, kx, pidx, j
    real colvector dy, y1, dep, bb, ee, sevec, taup, aicp, sicp, tstatp
    real matrix lmat, X, XX

    T = rows(y)
    dy = y[2::T] - y[1::(T-1)]
    y1 = y[1::(T-1)]
    lmat = J(T-1, pmax, 0)
    for (j = 1; j <= pmax; j++) {
        if (T-1-j >= 1) {
            lmat[(j+1)::(T-1), j] = dy[1::(T-1-j)]
        }
    }
    taup = J(pmax+1, 1, .)
    aicp = J(pmax+1, 1, .)
    sicp = J(pmax+1, 1, .)
    tstatp = J(pmax+1, 1, .)
    for (p = 0; p <= pmax; p++) {
        lo = p + 2
        dep = dy[lo::(T-1)]
        X = y1[lo::(T-1)], J(rows(dep), 1, 1)
        if (p > 0) {
            X = X, lmat[lo::(T-1), 1::p]
        }
        n1 = rows(dep)
        kx = cols(X)
        XX = invsym(cross(X, X))
        bb = XX*cross(X, dep)
        ee = dep - X*bb
        sevec = sqrt(diagonal(XX)*(cross(ee, ee)/(n1-kx)))
        taup[p+1] = bb[1]/sevec[1]
        aicp[p+1] = ln(cross(ee, ee)/n1) + 2*(kx+2)/n1
        sicp[p+1] = ln(cross(ee, ee)/n1) + (kx+2)*ln(n1)/n1
        tstatp[p+1] = abs(bb[kx]/sevec[kx])
    }
    pidx = _tsav_getlagidx(ic, aicp, sicp, tstatp)
    return(pidx - 1)
}

// ---------------------------------------------------------------------------
// bandwidth (GAUSS: bandwidth + __get_qr_adf_h) -- Hall-Sheather then Bofinger
// ---------------------------------------------------------------------------
real scalar _tsav_bwhs(real scalar tau, real scalar n)
{
    real scalar x0, f0

    x0 = invnormal(tau)
    f0 = normalden(x0)
    return(n^(-1/3) * invnormal(1 - 0.05/2)^(2/3) * ((1.5*f0^2)/(2*x0^2 + 1))^(1/3))
}

real scalar _tsav_bwbof(real scalar tau, real scalar n)
{
    real scalar x0, f0

    x0 = invnormal(tau)
    f0 = normalden(x0)
    return(n^(-0.2) * ((4.5*f0^4)/(2*x0^2 + 1)^2)^0.2)
}

real scalar _tsav_h(real scalar tau, real scalar n)
{
    real scalar h

    h = _tsav_bwhs(tau, n)
    if (tau <= 0.5 & h > tau) {
        h = _tsav_bwbof(tau, n)
        if (h > tau) {
            h = tau/1.5
        }
    }
    if (tau > 0.5 & h > 1 - tau) {
        h = _tsav_bwbof(tau, n)
        if (h > 1 - tau) {
            h = (1 - tau)/1.5
        }
    }
    return(h)
}

// ---------------------------------------------------------------------------
// Hansen (1995) critical values, interpolated on delta2 (GAUSS crit_QRadf)
// model: 0 = no deterministic, 1 = constant, 2 = constant + trend
// ---------------------------------------------------------------------------
real rowvector _tsav_qadfcv(real scalar r2, real scalar model)
{
    real matrix crt
    real rowvector ct
    real scalar r210, r2a, r2b, wa

    if (model == 0) {
        crt = (-2.4611512, -1.7832090, -1.4189957 \
               -2.4943410, -1.8184897, -1.4589747 \
               -2.5152783, -1.8516957, -1.5071775 \
               -2.5509773, -1.8957720, -1.5323511 \
               -2.5520784, -1.8949965, -1.5418830 \
               -2.5490848, -1.8981677, -1.5625462 \
               -2.5547456, -1.9343180, -1.5889045 \
               -2.5761273, -1.9387996, -1.6020210 \
               -2.5511921, -1.9328373, -1.6128210 \
               -2.5658, -1.9393, -1.6156)
    }
    else if (model == 1) {
        crt = (-2.7844267, -2.1158290, -1.7525193 \
               -2.9138762, -2.2790427, -1.9172046 \
               -3.0628184, -2.3994711, -2.0573070 \
               -3.1376157, -2.5070473, -2.1680520 \
               -3.1914660, -2.5841611, -2.2520173 \
               -3.2437157, -2.6399560, -2.3163270 \
               -3.2951006, -2.7180169, -2.4085640 \
               -3.3627161, -2.7536756, -2.4577709 \
               -3.3896556, -2.8074982, -2.5037759 \
               -3.4336, -2.8621, -2.5671)
    }
    else {
        crt = (-2.9657928, -2.3081543, -1.9519926 \
               -3.1929596, -2.5482619, -2.1991651 \
               -3.3727717, -2.7283918, -2.3806008 \
               -3.4904849, -2.8669056, -2.5315918 \
               -3.6003166, -2.9853079, -2.6672416 \
               -3.6819803, -3.0954760, -2.7815263 \
               -3.7551759, -3.1783550, -2.8728146 \
               -3.8348596, -3.2674954, -2.9735550 \
               -3.8800989, -3.3316415, -3.0364171 \
               -3.9638, -3.4126, -3.1279)
    }
    if (r2 < 0.1) {
        ct = crt[1, .]
    }
    else {
        r210 = r2*10
        if (r210 >= 10) {
            ct = crt[10, .]
        }
        else {
            r2a = floor(r210)
            r2b = ceil(r210)
            if (r2a < 1) {
                r2a = 1
            }
            if (r2a == r2b) {
                ct = crt[r2a, .]
            }
            else {
                wa = r2b - r210
                ct = wa*crt[r2a, .] + (1 - wa)*crt[r2b, .]
            }
        }
    }
    return(ct)
}

// ---------------------------------------------------------------------------
// per-quantile QADF computation (GAUSS QRADF tail / __get_qr_adf_stat /
// __get_qr_adf_delta2), given the three qreg coefficient vectors.
// usef = 0 : plain QADF  (w = dy, xx = [1, dyl], Hansen cvs)
// usef = 1 : Fourier QADF (w = residuals, xx = [1, all x but y1], no cvs)
// Fills row `row' of matrix `rmatname':
//   tau rho_tau rho_ols delta2 tn cv1 cv5 cv10
// ---------------------------------------------------------------------------
void _tsav_qadf_one(string scalar rmatname, real scalar row,
    string scalar yname, string scalar xvars, string scalar esamp,
    real scalar tau, real scalar h,
    string scalar b0name, string scalar b1name, string scalar b2name,
    real scalar p, real scalar usef, real scalar model)
{
    real colvector Y, y1, bg0, bg1, bg2, res, ind, phi, w, bols, tvec
    real matrix X, Xc, xx, ixx, Rm
    real rowvector b0, b1, b2, z1m, cv
    real scalar n, k, rho_tau, rho_ols, q1, q2, dq, fz, y1p, stat
    real scalar mw, mphi, covv, sdw, delta2

    Y = st_data(., yname, esamp)
    X = st_data(., tokens(xvars), esamp)
    n = rows(Y)
    Xc = J(n, 1, 1), X

    // reorder e(b): Stata puts _cons last, GAUSS puts it first
    b0 = st_matrix(b0name)
    k = cols(b0)
    bg0 = b0[k] \ b0[1::(k-1)]'
    b1 = st_matrix(b1name)
    bg1 = b1[k] \ b1[1::(k-1)]'
    b2 = st_matrix(b2name)
    bg2 = b2[k] \ b2[1::(k-1)]'

    rho_tau = bg0[2]

    // OLS rho (GAUSS: beta_ols = y/(ones~x))
    bols = invsym(cross(Xc, Xc))*cross(Xc, Y)
    rho_ols = bols[2]

    // density at the quantile: fz = 2h / (q1 - q2)
    z1m = 1, mean(X)
    q1 = z1m*bg1
    q2 = z1m*bg2
    dq = q1 - q2
    if (dq == 0) {
        fz = 0.01
    }
    else {
        fz = 2*h/dq
    }
    if (fz < 0) {
        fz = 0.01
    }

    // projection: xx = [1, dyl] (plain) or [1, all x except y1] (fourier)
    y1 = X[., 1]
    if (usef == 1) {
        if (cols(X) >= 2) {
            xx = J(n, 1, 1), X[., 2::cols(X)]
        }
        else {
            xx = J(n, 1, 1)
        }
    }
    else {
        if (p > 0) {
            xx = J(n, 1, 1), X[., 2::(p+1)]
        }
        else {
            xx = J(n, 1, 1)
        }
    }
    ixx = invsym(cross(xx, xx))
    tvec = cross(xx, y1)
    y1p = cross(y1, y1) - tvec'*ixx*tvec
    if (y1p < 0) {
        y1p = 0
    }
    stat = fz/sqrt(tau*(1 - tau)) * sqrt(y1p) * (rho_tau - 1)

    // delta2 (GAUSS __get_qr_adf_delta2)
    res = Y - Xc*bg0
    ind = res :< 0
    phi = J(n, 1, tau) - ind
    if (usef == 1) {
        w = res
    }
    else {
        w = Y - y1
    }
    mw = mean(w)
    mphi = mean(phi)
    covv = sum((w :- mw) :* (phi :- mphi))/(n - 1)
    sdw = sqrt(sum((w :- mw) :* (w :- mw))/(n - 1))
    delta2 = (covv/(sdw*sqrt(tau*(1 - tau))))^2

    if (usef == 0) {
        cv = _tsav_qadfcv(delta2, model)
    }
    else {
        cv = (., ., .)
    }

    Rm = st_matrix(rmatname)
    Rm[row, .] = (tau, rho_tau, rho_ols, delta2, stat, cv[1], cv[2], cv[3])
    st_matrix(rmatname, Rm)
}

// ---------------------------------------------------------------------------
// Fourier QADF bootstrap preparation (GAUSS QR_Fourier_ADF_bootstrap, part 1)
// Estimates the null model on the FULL sample (Fourier terms built on full T),
// fits AR(1) to its residuals and stores the centred innovations in the
// external __tsav_mu. Returns rows(mu) via r(tt).
// ---------------------------------------------------------------------------
void _tsav_fq_prep(string scalar yname, string scalar touse,
    real scalar model, real scalar p, real scalar k)
{
    external real colvector __tsav_mu
    real colvector y, s, sink, cosk, dyfull, yt, b, yd, yd1, yd0, mu
    real matrix X, Xt, L
    real scalar T, j, lo, n0, fi

    y = st_data(., yname, touse)
    T = rows(y)
    s = (1::T)
    sink = sin(2*pi()*k*s/T)
    cosk = cos(2*pi()*k*s/T)
    dyfull = J(T, 1, .)
    dyfull[2::T] = y[2::T] - y[1::(T-1)]
    X = J(T, 1, 1)
    if (model == 1) {
        X = X, sink, cosk
    }
    else {
        X = X, s, sink, cosk
    }
    if (p > 0) {
        L = J(T, p, .)
        for (j = 1; j <= p; j++) {
            if (T-j >= 2) {
                L[(j+2)::T, j] = dyfull[2::(T-j)]
            }
        }
        X = X, L
    }
    lo = p + 2
    Xt = X[lo::T, .]
    yt = y[lo::T]
    b = invsym(cross(Xt, Xt))*cross(Xt, yt)
    yd = yt - Xt*b
    n0 = rows(yd)
    yd1 = yd[1::(n0-1)]
    yd0 = yd[2::n0]
    fi = cross(yd1, yd0)/cross(yd1, yd1)
    mu = yd0 - yd1*fi
    mu = mu :- mean(mu)
    __tsav_mu = mu
    st_numscalar("r(tt)", rows(mu))
}

// ---------------------------------------------------------------------------
// Fourier QADF bootstrap loop (GAUSS QR_Fourier_ADF_bootstrap, part 2)
// For each replication: iid resample of mu with replacement, cumulate into a
// pure random walk, run the full Fourier-QADF core on the pseudo-series.
// Writes BSname (ntau x 7):
//   cvlt1 cvlt5 cvlt10  cvsrc1 cvsrc5 cvsrc10  pboot
// cvsrc* reproduce the GAUSS source order statistics (0.99/0.95/0.90 of the
// ascending-sorted bootstrap stats); cvlt* are the left-tail 1/5/10 percent
// order statistics used for the displayed decisions.
// ---------------------------------------------------------------------------
void _tsav_fq_boot(string scalar ystar, real scalar tt, real scalar nboot,
    string scalar corecmd, string scalar rmatname, real scalar ntau,
    string scalar BSname, string scalar tnobsname, real scalar seed)
{
    external real colvector __tsav_mu
    real colvector idx, mus, yd, col, tnobs
    real matrix B, R, BS
    real scalar r, s2, j, nb, i1, i5, i10, j1, j5, j10

    if (seed > 0) {
        rseed(seed)
    }
    tnobs = st_matrix(tnobsname)
    B = J(nboot, ntau, .)
    for (r = 1; r <= nboot; r++) {
        idx = ceil(tt :* runiform(tt, 1))
        for (s2 = 1; s2 <= tt; s2++) {
            if (idx[s2] < 1) {
                idx[s2] = 1
            }
        }
        mus = __tsav_mu[idx]
        yd = runningsum(mus)
        st_store(., ystar, yd)
        stata(corecmd)
        R = st_matrix(rmatname)
        B[r, .] = R[., 5]'
    }
    BS = J(ntau, 7, .)
    nb = nboot
    // source convention: index = alpha*Nboot, GAUSS truncation
    j1 = trunc(0.99*nb)
    j5 = trunc(0.95*nb)
    j10 = trunc(0.90*nb)
    if (j1 < 1) {
        j1 = 1
    }
    if (j5 < 1) {
        j5 = 1
    }
    if (j10 < 1) {
        j10 = 1
    }
    i1 = trunc(0.01*nb)
    i5 = trunc(0.05*nb)
    i10 = trunc(0.10*nb)
    if (i1 < 1) {
        i1 = 1
    }
    if (i5 < 1) {
        i5 = 1
    }
    if (i10 < 1) {
        i10 = 1
    }
    for (j = 1; j <= ntau; j++) {
        col = sort(B[., j], 1)
        BS[j, 1] = col[i1]
        BS[j, 2] = col[i5]
        BS[j, 3] = col[i10]
        BS[j, 4] = col[j1]
        BS[j, 5] = col[j5]
        BS[j, 6] = col[j10]
        BS[j, 7] = sum(col :<= tnobs[j])/nb
    }
    st_matrix(BSname, BS)
}

// ---------------------------------------------------------------------------
// Narayan & Popp (2010) two-break test (GAUSS ADF_2breaks, exact)
// model 1 = M1 (breaks in level), 2 = M2 (breaks in level and slope)
// NOTE the source quirks reproduced here:
//   - both models include a linear trend among the deterministics
//   - the deterministic terms enter LAGGED (z_{t-1})
//   - default trimming 0.10 (dynargsGet default, not the 0.15 of the header)
//   - T1/t1 and T2/t2 are the same (case-insensitive) GAUSS symbols:
//     the effective bounds are T1 = max(3+pmax, ceil(trim*T)) (then pmax+3 if
//     < pmax+2) and T2 = min(T-3-pmax, floor((1-trim)*T))
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Narayan & Popp (2010) paper-form deterministics for a break whose last
// pre-break period is tb, aligned to the (T-1)-length differenced equation
// used by _tsav_np (row i corresponds to time t = i+1):
//   impulse  D(TB)_t   = 1(t = tb+1)              -> 1 at row tb
//   level    DU'_{t-1} = 1(t-1 > tb) = 1(t > tb+1)-> 1 for rows > tb
//   trend    DT'_{t-1} = 1(t-1 > tb)*(t-1-tb)     -> (row-tb) for rows > tb
// This matches the LAGGED convention of the grid path, so break positions are
// reported consistently across the grid and paper procedures.
// ---------------------------------------------------------------------------
real colvector _tsav_np_imp(real scalar tb, real scalar Tm1)
{
    return(J(tb-1, 1, 0) \ 1 \ J(Tm1-tb, 1, 0))
}
real colvector _tsav_np_du(real scalar tb, real scalar Tm1)
{
    return(J(tb, 1, 0) \ J(Tm1-tb, 1, 1))
}
real colvector _tsav_np_dtl(real scalar tb, real scalar Tm1)
{
    return(J(tb, 1, 0) \ (1::(Tm1-tb)))
}

// ---------------------------------------------------------------------------
// Paper-form candidate regression (NP 2010, Eq. 7 for M1 / Eq. 8 for M2):
//   D.y_t = rho*y_{t-1} + Zb'gamma + sum_j phi_j D.y_{t-j} + e_t
// Zb is the deterministic block (impulse + lagged level/trend dummies) for
// the candidate break(s). The lag is selected by ic on the varying sample
// (the same mechanics as the grid path); the regression is refit at the
// selected lag. Returns (tau, sel, pidx):
//   tau  = ADF t-ratio on y_{t-1}
//   sel  = |t| on column reqc1 (impulse coef) when reqc2==0     [sequential]
//        = joint F on columns reqc1,reqc2 (two impulses) /2      [Eq. 9]
//   pidx = 1-based selected-lag index (reported lag = pidx-1)
// ---------------------------------------------------------------------------
real rowvector _tsav_np_cand(real colvector dy, real colvector y1,
    real matrix Zb, real matrix lmat, real scalar pmax, real scalar ic,
    real scalar Tm1, real scalar reqc1, real scalar reqc2)
{
    real colvector dep, bb, ee, sevec, taup, aicp, sicp, tstatp, idx, bc
    real matrix X, XX, Vc
    real scalar p, lo, n1, kx, pidx, plag, tau, sel, sig2

    taup   = J(pmax+1, 1, .)
    aicp   = J(pmax+1, 1, .)
    sicp   = J(pmax+1, 1, .)
    tstatp = J(pmax+1, 1, .)
    for (p = 0; p <= pmax; p++) {
        lo  = p + 2
        dep = dy[lo::Tm1]
        X   = y1[lo::Tm1], Zb[lo::Tm1, .]
        if (p > 0) {
            X = X, lmat[lo::Tm1, 1::p]
        }
        n1 = rows(dep)
        kx = cols(X)
        XX = invsym(cross(X, X))
        bb = XX*cross(X, dep)
        ee = dep - X*bb
        sevec = sqrt(diagonal(XX)*(cross(ee, ee)/(n1-kx)))
        taup[p+1]   = bb[1]/sevec[1]
        aicp[p+1]   = ln(cross(ee, ee)/n1) + 2*(kx+2)/n1
        sicp[p+1]   = ln(cross(ee, ee)/n1) + (kx+2)*ln(n1)/n1
        tstatp[p+1] = abs(bb[kx]/sevec[kx])
    }
    pidx = _tsav_getlagidx(ic, aicp, sicp, tstatp)
    plag = pidx - 1
    lo   = plag + 2
    dep  = dy[lo::Tm1]
    X    = y1[lo::Tm1], Zb[lo::Tm1, .]
    if (plag > 0) {
        X = X, lmat[lo::Tm1, 1::plag]
    }
    n1    = rows(dep)
    kx    = cols(X)
    XX    = invsym(cross(X, X))
    bb    = XX*cross(X, dep)
    ee    = dep - X*bb
    sig2  = cross(ee, ee)/(n1-kx)
    sevec = sqrt(diagonal(XX)*sig2)
    tau   = bb[1]/sevec[1]
    if (reqc2 == 0) {
        sel = abs(bb[reqc1]/sevec[reqc1])
    }
    else {
        idx = (reqc1 \ reqc2)
        bc  = bb[idx]
        Vc  = XX[idx, idx]*sig2
        if (missing(Vc[1,1]) | missing(bc[1]) | missing(bc[2])) {
            sel = .
        }
        else {
            sel = (bc' * invsym(Vc) * bc)/2
        }
    }
    return((tau, sel, pidx))
}

void _tsav_np(string scalar yname, string scalar touse, real scalar model,
    real scalar pmax, real scalar ic, real scalar trimm, real scalar mode)
{
    real colvector y, dy, y1, dep, bb, ee, sevec, taup, aicp, sicp, tstatp
    real colvector du1, du2, dt1v, dt2v, dc, dtv, cv
    real colvector dcm, dtm, imp1, dul1, dtl1, imp2, dul2, dtl2
    real matrix lmat, z, z1, X, XX, Zb
    real scalar T, Tm1, j, T1, T2, tb1, tb2, tb2s, p, lo, n1, kx, pidx, stat
    real scalar ADFmin, tb1min, tb2min, optlag, fstat, gap, c2col
    real scalar tbb, best, tb1s
    real rowvector rr

    y = st_data(., yname, touse)
    T = rows(y)
    Tm1 = T - 1
    dy = y[2::T] - y[1::(T-1)]
    y1 = y[1::(T-1)]
    lmat = J(T-1, pmax, 0)
    for (j = 1; j <= pmax; j++) {
        if (T-1-j >= 1) {
            lmat[(j+1)::(T-1), j] = dy[1::(T-1-j)]
        }
    }
    T1 = max((3 + pmax, ceil(trimm*T)))
    T2 = min((T - 3 - pmax, floor((1 - trimm)*T)))
    if (T1 < pmax + 2) {
        T1 = pmax + 3
    }
    ADFmin = 1000
    tb1min = 0
    tb2min = 0
    optlag = 1
    fstat  = .

    if (mode == 0) {
        // ---- tspdlib / GAUSS grid: min ADF-t, additive LAGGED dummies -----
        dc = J(T, 1, 1)
        dtv = (1::T)
        taup = J(pmax+1, 1, .)
        aicp = J(pmax+1, 1, .)
        sicp = J(pmax+1, 1, .)
        tstatp = J(pmax+1, 1, .)
        for (tb1 = T1; tb1 <= T2; tb1++) {
            if (model == 1) {
                tb2s = tb1 + 2
            }
            else {
                tb2s = tb1 + 3
            }
            for (tb2 = tb2s; tb2 <= T2; tb2++) {
                du1 = J(tb1, 1, 0) \ J(T-tb1, 1, 1)
                du2 = J(tb2, 1, 0) \ J(T-tb2, 1, 1)
                if (model == 1) {
                    z = dc, dtv, du1, du2
                }
                else {
                    dt1v = J(tb1, 1, 0) \ (1::(T-tb1))
                    dt2v = J(tb2, 1, 0) \ (1::(T-tb2))
                    z = dc, dtv, du1, du2, dt1v, dt2v
                }
                // z1 = lagged deterministics: z_{t-1} aligned with dy_t
                z1 = z[1::(T-1), .]
                for (p = 0; p <= pmax; p++) {
                    lo = p + 2
                    dep = dy[lo::(T-1)]
                    X = y1[lo::(T-1)], z1[lo::(T-1), .]
                    if (p > 0) {
                        X = X, lmat[lo::(T-1), 1::p]
                    }
                    n1 = rows(dep)
                    kx = cols(X)
                    XX = invsym(cross(X, X))
                    bb = XX*cross(X, dep)
                    ee = dep - X*bb
                    sevec = sqrt(diagonal(XX)*(cross(ee, ee)/(n1-kx)))
                    taup[p+1] = bb[1]/sevec[1]
                    aicp[p+1] = ln(cross(ee, ee)/n1) + 2*(kx+2)/n1
                    sicp[p+1] = ln(cross(ee, ee)/n1) + (kx+2)*ln(n1)/n1
                    tstatp[p+1] = abs(bb[kx]/sevec[kx])
                }
                pidx = _tsav_getlagidx(ic, aicp, sicp, tstatp)
                stat = taup[pidx]
                if (stat < ADFmin) {
                    tb1min = tb1
                    tb2min = tb2
                    ADFmin = stat
                    optlag = pidx
                }
            }
        }
    }
    else {
        // ---- Narayan-Popp (2010) paper form: impulse dummies included -----
        dcm = J(Tm1, 1, 1)
        dtm = (1::Tm1)
        if (model == 1) {
            gap = 2
            c2col = 6
        }
        else {
            gap = 3
            c2col = 7
        }
        if (mode == 1) {
            // ---- Sequential procedure (Eqs. 10-11) ------------------------
            // Step 1: single break maximizing |t| of the impulse coefficient.
            best = -1
            tb1s = 0
            for (tbb = T1; tbb <= T2; tbb++) {
                imp1 = _tsav_np_imp(tbb, Tm1)
                dul1 = _tsav_np_du(tbb, Tm1)
                if (model == 1) {
                    Zb = dcm, dtm, imp1, dul1
                }
                else {
                    dtl1 = _tsav_np_dtl(tbb, Tm1)
                    Zb = dcm, dtm, imp1, dul1, dtl1
                }
                rr = _tsav_np_cand(dy, y1, Zb, lmat, pmax, ic, Tm1, 4, 0)
                if (rr[2] < . & rr[2] > best) {
                    best = rr[2]
                    tb1s = tbb
                }
            }
            if (tb1s == 0) {
                _error("sequential step 1 found no admissible break; reduce pmax()/trim() or add observations")
            }
            // Step 2: impose TB1, maximize |t| of the second impulse coef.
            imp1 = _tsav_np_imp(tb1s, Tm1)
            dul1 = _tsav_np_du(tb1s, Tm1)
            if (model == 2) {
                dtl1 = _tsav_np_dtl(tb1s, Tm1)
            }
            best = -1
            for (tbb = T1; tbb <= T2; tbb++) {
                if (abs(tbb - tb1s) < gap) {
                    continue
                }
                imp2 = _tsav_np_imp(tbb, Tm1)
                dul2 = _tsav_np_du(tbb, Tm1)
                if (model == 1) {
                    Zb = dcm, dtm, imp1, dul1, imp2, dul2
                }
                else {
                    dtl2 = _tsav_np_dtl(tbb, Tm1)
                    Zb = dcm, dtm, imp1, dul1, dtl1, imp2, dul2, dtl2
                }
                rr = _tsav_np_cand(dy, y1, Zb, lmat, pmax, ic, Tm1, c2col, 0)
                if (rr[2] < . & rr[2] > best) {
                    best   = rr[2]
                    tb1min = min((tb1s, tbb))
                    tb2min = max((tb1s, tbb))
                    ADFmin = rr[1]
                    optlag = rr[3]
                }
            }
            if (tb1min == 0) {
                _error("sequential step 2 found no admissible second break; reduce pmax()/trim() or add observations")
            }
        }
        else {
            // ---- Simultaneous procedure (Eq. 9) ---------------------------
            // over all admissible pairs, maximize the joint F of the two
            // impulse-dummy coefficients.
            best = -1
            for (tb1 = T1; tb1 <= T2 - gap; tb1++) {
                imp1 = _tsav_np_imp(tb1, Tm1)
                dul1 = _tsav_np_du(tb1, Tm1)
                if (model == 2) {
                    dtl1 = _tsav_np_dtl(tb1, Tm1)
                }
                for (tb2 = tb1 + gap; tb2 <= T2; tb2++) {
                    imp2 = _tsav_np_imp(tb2, Tm1)
                    dul2 = _tsav_np_du(tb2, Tm1)
                    if (model == 1) {
                        Zb = dcm, dtm, imp1, dul1, imp2, dul2
                    }
                    else {
                        dtl2 = _tsav_np_dtl(tb2, Tm1)
                        Zb = dcm, dtm, imp1, dul1, dtl1, imp2, dul2, dtl2
                    }
                    rr = _tsav_np_cand(dy, y1, Zb, lmat, pmax, ic, Tm1, 4, c2col)
                    if (rr[2] < . & rr[2] > best) {
                        best   = rr[2]
                        fstat  = rr[2]
                        tb1min = tb1
                        tb2min = tb2
                        ADFmin = rr[1]
                        optlag = rr[3]
                    }
                }
            }
            if (tb1min == 0) {
                _error("simultaneous search found no admissible break pair; reduce pmax()/trim() or add observations")
            }
        }
    }
    cv = _tsav_np_cv(T, model)
    st_numscalar("r(npstat)", ADFmin)
    st_numscalar("r(tb1)", tb1min)
    st_numscalar("r(tb2)", tb2min)
    st_numscalar("r(nplag)", optlag - 1)
    st_numscalar("r(cv1)", cv[1])
    st_numscalar("r(cv5)", cv[2])
    st_numscalar("r(cv10)", cv[3])
    st_numscalar("r(fstat)", fstat)
}

// Narayan & Popp (2010), Table 3 critical values by sample size
real colvector _tsav_np_cv(real scalar T, real scalar model)
{
    real colvector cv

    if (model == 1) {
        if (T <= 50) {
            cv = (-5.259 \ -4.514 \ -4.143)
        }
        else if (T <= 200) {
            cv = (-4.958 \ -4.316 \ -3.980)
        }
        else if (T <= 400) {
            cv = (-4.731 \ -4.136 \ -3.825)
        }
        else {
            cv = (-4.672 \ -4.081 \ -3.772)
        }
    }
    else {
        if (T <= 50) {
            cv = (-5.949 \ -5.181 \ -4.789)
        }
        else if (T <= 200) {
            cv = (-5.576 \ -4.937 \ -4.596)
        }
        else if (T <= 400) {
            cv = (-5.318 \ -4.741 \ -4.430)
        }
        else {
            cv = (-5.287 \ -4.692 \ -4.396)
        }
    }
    return(cv)
}

// ---------------------------------------------------------------------------
// Carrion-i-Silvestre et al. (2009): response surface for c_bar
// (GAUSS __sbur_c_bar_rs), lam is a 5x1 vector of break fractions
// ---------------------------------------------------------------------------
real scalar _tsav_cbar(real colvector lam)
{
    real rowvector x
    real colvector prm
    real scalar i, j, idx

    x = J(1, 61, .)
    x[1] = 1
    for (i = 1; i <= 5; i++) {
        x[1+i] = lam[i]
        x[6+i] = lam[i]^2
        x[11+i] = lam[i]^3
        x[16+i] = lam[i]^4
    }
    idx = 21
    for (i = 1; i <= 4; i++) {
        for (j = i+1; j <= 5; j++) {
            idx = idx + 1
            x[idx] = abs(lam[i] - lam[j])
            x[idx+10] = abs(lam[i] - lam[j])^2
            x[idx+20] = abs(lam[i] - lam[j])^3
            x[idx+30] = abs(lam[i] - lam[j])^4
        }
    }
    prm = (-13.12832 \ -36.53045 \ 0 \ 20.2423 \ -4.596202 \ -10.31678 \
        115.2092 \ -29.18712 \ -68.36453 \ 5.873121 \ 0 \ -130.337 \
        74.64396 \ 85.48737 \ 0 \ 0 \ 51.98117 \ -53.03452 \ -36.27221 \
        0 \ 11.27727 \ -23.39517 \ -5.360149 \ 23.99683 \ 4.788676 \
        -27.10002 \ -35.78388 \ 51.12371 \ -29.8518 \ -3.069174 \
        -37.45898 \ 64.95842 \ 5.825729 \ -88.78176 \ -11.54197 \
        83.48645 \ 125.2349 \ -173.1259 \ 80.95821 \ 2.863782 \ 118.2829 \
        -80.1287 \ 0 \ 128.872 \ 6.387147 \ -118.1043 \ -199.0615 \
        247.6469 \ -98.05947 \ 0 \ -160.5713 \ 38.52177 \ 0 \ -65.21576 \
        0 \ 62.86494 \ 117.9976 \ -127.5544 \ 46.2304 \ 0 \ 79.1693)
    return(x*prm)
}

// ---------------------------------------------------------------------------
// CiS et al. (2009): response surfaces for the critical values
// (GAUSS pd_msbur_rsf). Returns a 4x3 matrix, rows MSB / MZA / MZT / PT,
// columns 1% / 5% / 10% (the source keeps columns 1, 3, 4 of each 4-block).
// ---------------------------------------------------------------------------
real matrix _tsav_ciscv(real colvector lam, real scalar cbar)
{
    real rowvector x, crit
    real matrix P
    real scalar i, j, idx, d

    x = J(1, 63, .)
    x[1] = 1
    for (i = 1; i <= 5; i++) {
        x[1+i] = lam[i]
        x[6+i] = lam[i]^2
        x[12+i] = lam[i]*cbar
        x[18+i] = lam[i]*cbar^2
    }
    x[12] = cbar
    x[18] = cbar^2
    idx = 23
    for (i = 1; i <= 4; i++) {
        for (j = i+1; j <= 5; j++) {
            idx = idx + 1
            d = abs(lam[i] - lam[j])
            x[idx] = d*cbar
            x[idx+10] = d^2*cbar
            x[idx+20] = d^3*cbar
            x[idx+30] = d^4*cbar
        }
    }
    P = _tsav_cisparam()
    crit = x*P
    // rows MSB / MZA / MZT / PT ; columns 1% / 2.5% / 5% / 10%
    return((crit[1], crit[2], crit[3], crit[4] \
            crit[5], crit[6], crit[7], crit[8] \
            crit[9], crit[10], crit[11], crit[12] \
            crit[13], crit[14], crit[15], crit[16]))
}

real matrix _tsav_cisparam()
{
    real matrix P

    P = J(63, 16, 0)
    P[1,.] = (0.206065483, 0.247173646, 0.279911696, 0.311573002, -26.31391813, -20.61149374, -12.1438623, -6.08490852, -2.52133657, -1.766570893, -1.46435731, -1.277987954, -3.518835863, -3.305558261, -3.454833615, -3.240058047)
    P[2,.] = (-0.131592168, -0.083176707, -0.079273217, -0.136364352, -129.5317914, -84.29286654, -36.47970616, -31.60984523, -6.668037145, -3.349004828, -3.066463141, -3.217982311, -15.69764073, -15.89838295, -10.46560768, -18.14173976)
    P[3,.] = (-0.018230144, 0, 0, 0, -3.503797177, 0, 0, 0, -0.193154126, 0, 0, 0, 2.698367477, 0, 0, 3.094894401)
    P[4,.] = (-0.001829617, 0, 0.036867994, 0, 0, 0, 31.56762014, 13.63038899, 0, 0, 1.32634005, 0.633301965, 6.412055579, 0, 5.223542808, 4.405653332)
    P[5,.] = (-0.071694008, -0.069876819, -0.098386033, -0.063992057, -22.82788603, -13.10518388, -39.87684614, -23.51617143, -2.651936734, -1.893827718, -2.317691146, -1.235047933, -10.32717062, -1.986102341, -8.649758634, -1.987760716)
    P[6,.] = (-0.113224418, -0.123618939, -0.114531349, -0.171308084, -71.88919188, -56.62886058, -22.2258743, -45.74522263, -4.308941432, -3.028641495, -2.666831955, -3.513398467, -5.232680619, -13.76324196, -6.17789082, -12.35876925)
    P[7,.] = (0.045497638, 0.034139777, 0.033789576, 0.055316264, 47.47172982, 32.22798967, 18.27175882, 11.56516258, 2.242409839, 1.205414124, 1.172595231, 1.065619758, 4.664094355, 5.198014133, 4.311973301, 6.869459093)
    P[8,.] = (0.005667139, 0.007183722, 0.014895671, 0.00832245, 0, 5.942060926, 8.371062059, 6.269767228, 0, 0.307559368, 0.499975826, 0.381693852, 0, 0, 1.28702057, 0)
    P[9,.] = (0, 0, 0, 0.007275262, 0, 0, 0, 0, -0.085060207, 0, 0, 0.194838181, 0, 0, 0, 0)
    P[10,.] = (0.011393725, 0, 0.006925649, 0.007101886, 14.70004959, 11.44618918, 8.81485526, 8.184740859, 0.87936997, 0.56718476, 0.473032483, 0.402464154, 1.183189107, 1.643475816, 0, 1.791921929)
    P[11,.] = (0.041416456, 0.037458345, 0.036987117, 0.053884486, 37.54355821, 29.58007215, 20.19100032, 26.06901605, 2.110275336, 1.487278396, 1.44212234, 1.676575305, 4.970060977, 6.400077634, 6.119151722, 6.360822366)
    P[12,.] = (0.006744983, 0.009229194, 0.01117728, 0.012830135, 0, 0, 0.383835339, 0.85365241, 0.114546234, 0.141951363, 0.144171363, 0.139480635, -0.544592947, -0.53171116, -0.666577377, -0.74225554)
    P[13,.] = (-0.008881686, -0.005163807, -0.00419873, -0.007623439, -8.508298137, -5.471425562, -1.873513518, -2.233163794, -0.457380818, -0.223355446, -0.186935755, -0.219966762, -1.116029433, -1.044782065, -0.624407428, -1.106702061)
    P[14,.] = (-0.000477302, 0.001411259, 0.001490823, 0.000992921, 0, 0.821678805, 0.839344685, 0.693315109, 0, 0.040353055, 0.049102085, 0.044657513, 0.3017767, 0.013704832, 0.128412682, 0.273588757)
    P[15,.] = (0, 0, 0.003166102, 0.000383907, 0.315654917, 0.353092298, 2.84583848, 1.121511646, 0, 0.017148054, 0.120078208, 0.072095127, 0.636962573, 0.022144415, 0.523175329, 0.412172316)
    P[16,.] = (-0.004879334, -0.005905712, -0.007875096, -0.005118819, -0.270010842, 0, -2.545569579, -1.407264853, -0.12770179, -0.112106002, -0.155499347, -0.077321047, -0.756479306, 0, -0.693933651, 0)
    P[17,.] = (-0.005109823, -0.006312857, -0.005745887, -0.008799213, -2.346920289, -1.877066153, 0, -1.439270423, -0.15405538, -0.106423683, -0.083556342, -0.135095954, 0, -0.587410296, 0, -0.447876179)
    P[18,.] = (0.000147113, 0.000180001, 0.000216343, 0.000261777, 0.010036211, 0, 0, 0.019804635, 0.003272583, 0.002943926, 0.002822847, 0.003038937, 0, 0.004379253, 0, 0)
    P[19,.] = (-0.00018911, -0.000109989, -7.2476E-05, -0.000130686, -0.180808958, -0.117234577, -0.036217559, -0.050234142, -0.009870463, -0.004857975, -0.003790936, -0.00464363, -0.023994328, -0.021043324, -0.012868843, -0.021946248)
    P[20,.] = (0, 4.98993E-05, 3.87592E-05, 2.10757E-05, 0, 0.023326443, 0.022083426, 0.01757633, 0, 0.001151668, 0.001220296, 0.001083382, 0.007411666, 0, 0.003373215, 0.005094191)
    P[21,.] = (0, 0, 6.56928E-05, 0, 0.012434324, 0.014488305, 0.063997488, 0.02118732, 0, 0.000643625, 0.002670921, 0.001514238, 0.014861192, 0, 0.01257116, 0.009431941)
    P[22,.] = (-0.000101491, -0.000129658, -0.000170948, -0.000117271, 0, 0, -0.053703036, -0.033337638, -0.002353799, -0.002482217, -0.003375858, -0.001867064, -0.016239629, 0, -0.014642206, 0)
    P[23,.] = (-9.12367E-05, -0.000115959, -0.000107388, -0.000164942, -0.042581947, -0.034973534, 0, -0.028709714, -0.002863078, -0.002011657, -0.001581567, -0.002664683, 0, -0.01272247, -0.000903779, -0.009291186)
    P[24,.] = (0.001502737, 0.001632669, 0.001702841, 0.002021723, 1.632727956, 1.605877644, 1.004404184, 0.868853384, 0.083333993, 0.079478462, 0.065367552, 0.063715851, 0.310198878, 0.360029916, 0.330191659, 0.381965256)
    P[25,.] = (0, 0, 0, 0.001328702, 0, 0, 0.202483643, 0.620890565, 0.006479305, 0, 0.006933813, 0.032275901, 0, 0.134517084, 0, 0)
    P[26,.] = (0, 0, 0, 0, -0.192709346, 0, 0, 0.36221429, -0.021488357, 0, -0.001200112, 0.011828416, 0, 0.099982238, 0.103069901, 0.084964524)
    P[27,.] = (0.000680309, 0, 0.000414141, 0, 0.499555624, 0, 0.269613377, 0.236974663, 0.040862054, 0.022834275, 0.016456528, 0.017878489, 0.127583576, 0, 0.129658797, 0.079531443)
    P[28,.] = (0.001076323, 0.000746542, 0.001534534, 0.001854214, 1.222722601, 0.980994239, 0.952309602, 0.981692971, 0.06103088, 0.048322535, 0.062848187, 0.068704135, 0.34819102, 0.351457151, 0.285248474, 0.389323838)
    P[29,.] = (0.001602307, 0.001718432, 0.000513486, 0.001320012, 1.284000309, 0.790608102, 0.29128284, 0.192243305, 0.073187675, 0.037307962, 0.015603486, 0.008831525, 0, 0.161831707, 0.161667434, 0)
    P[30,.] = (-3.13393E-05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.178056784)
    P[31,.] = (0.000915733, 0.000465616, 0.000828461, 0.0015141, 0.895732659, 0.635112942, 0.357984838, 0.70758854, 0.051259672, 0.033026078, 0.039391705, 0.054005928, 0.114186355, 0.272130694, 0.173459972, 0.236092255)
    P[32,.] = (0.001297134, 0.001989702, 0.001648169, 0.000516108, 1.486377973, 1.448576409, 1.438138712, 0.44934008, 0.06084729, 0.063368696, 0.060177344, 0.023938672, 0.184586257, 0.01941423, 0.270773963, 0.306240705)
    P[33,.] = (0.000779578, 0.000538182, 0.001171215, 0.001602482, 0.553062822, 0.350422194, 0.468555532, 0.425359716, 0.03353265, 0.028507047, 0.042001183, 0.043941342, 0.138176188, 0.167194529, 0.177010468, 0.210812736)
    P[34,.] = (-0.004345646, -0.005825265, -0.006868541, -0.00796319, -4.479282599, -4.8858522, -3.136191913, -2.458114748, -0.231523802, -0.248286094, -0.213133815, -0.194637365, -0.922468402, -0.985366571, -0.923999903, -1.130047)
    P[35,.] = (0, 0, -5.04974E-05, -0.004738169, 0, 0, -0.403826354, -1.909565827, -0.009229909, 0, -0.008242746, -0.098804196, 0, -0.507406066, 0, -0.021572133)
    P[36,.] = (0, 0, 0, -5.05847E-05, 0, 0, -0.417036823, -1.119339897, 0.043558418, 0, 0, -0.02166457, 0, -0.454778552, -0.405307294, -0.332490735)
    P[37,.] = (-0.004679147, -0.002222758, -0.004695542, -0.003025465, -3.000000235, -0.964674073, -1.860955551, -1.416293256, -0.208817124, -0.134046896, -0.136841302, -0.125359252, -0.631341206, 0, -0.587433653, -0.487244954)
    P[38,.] = (-0.002164419, -0.001967051, -0.005817976, -0.006214813, -2.092813644, -1.850008801, -2.941485078, -2.857336306, -0.104657956, -0.097680824, -0.195504402, -0.201534614, -1.128138371, -0.979191193, -0.703716053, -1.028065809)
    P[39,.] = (-0.005484897, -0.006163019, -0.00124581, -0.004023965, -4.057652598, -2.738110318, -0.61059659, -0.332618017, -0.222016788, -0.126749269, -0.030055771, -0.009635946, 0, -0.599177023, -0.584313329, 0)
    P[40,.] = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.089011851, 0.124842286, 0, -0.508722695)
    P[41,.] = (-0.00165207, -0.001163458, -0.003198713, -0.005190305, -1.276113948, -0.889271056, -0.747636053, -1.839058302, -0.069225581, -0.055577102, -0.112927132, -0.159646685, -0.154761007, -0.597212331, -0.288535459, -0.379766195)
    P[42,.] = (-0.003789148, -0.0064054, -0.004817945, -0.000649124, -4.496633229, -4.594051759, -4.597029802, -0.694146329, -0.167498301, -0.194612003, -0.171395671, -0.037729237, -0.67125797, 0, -0.997655245, -1.102797825)
    P[43,.] = (-0.001096697, -0.000571708, -0.00416902, -0.004537825, 0, 0, -1.150001536, -0.397475842, 0, -0.036557664, -0.117430944, -0.100061587, -0.189720447, -0.156458132, -0.171258066, -0.367949029)
    P[44,.] = (0.004725461, 0.008280992, 0.010451449, 0.011883757, 4.700545573, 6.27119741, 4.178380993, 3.094835252, 0.247801364, 0.322844187, 0.291165672, 0.255602766, 1.114026174, 1.079445866, 1.116574652, 1.435226881)
    P[45,.] = (0, 0, 0, 0.006868754, -0.046355934, 0, 0.220249151, 2.5334366, 0, 0, 0, 0.133924549, 0, 0.776781333, 0, 0.023477765)
    P[46,.] = (0, 0, 0, 0, 0.811913273, 0, 0.998239994, 1.47110097, -0.023485383, 0, 0, 0.010896637, 0, 0.75874924, 0.657353781, 0.52514633)
    P[47,.] = (0.009039167, 0.005334347, 0.009880517, 0.007579264, 5.503001956, 2.327899451, 3.493280873, 2.574956682, 0.361357325, 0.240732181, 0.272754543, 0.241334704, 1.095018463, 0, 0.92651935, 0.916080571)
    P[48,.] = (0.001237718, 0.001401401, 0.008484588, 0.008416308, 1.02572597, 1.046754093, 3.967072173, 3.760263385, 0.052317695, 0.060133444, 0.261308977, 0.263752707, 1.565059276, 1.23081264, 0.745421462, 1.252746367)
    P[49,.] = (0.008139359, 0.009159069, 0.000918836, 0.005481258, 5.865893641, 4.234610015, 0.400719375, 0.166727218, 0.311141107, 0.193402656, 0.018125688, 0, 0, 0.979632255, 0.860652087, 0)
    P[50,.] = (0, -5.0721E-05, 0, -4.79068E-05, -0.038957002, 0, 0, -0.024479515, -0.002278556, 0, 0, -0.001680802, -0.216616021, -0.359131022, 0, 0.639272615)
    P[51,.] = (0.000809364, 0.000809675, 0.004538856, 0.007550505, 0, 0, 0.474813133, 2.435657851, 0, 0.0278107, 0.141916393, 0.221121513, 0, 0.592286581, 0.142276904, 0.175199011)
    P[52,.] = (0.004893033, 0.00886491, 0.006136727, 0, 6.088534864, 6.377018844, 6.286955077, 0.283095346, 0.216868391, 0.263466015, 0.214566444, 0.01661417, 1.025111042, 0, 1.492001945, 1.627703373)
    P[53,.] = (0.000352955, 0, 0.005980789, 0.005904448, -1.299540015, -0.727894226, 1.347458203, 0, -0.07801745, 0.011508158, 0.152800184, 0.120073816, 0.059252271, 0, 0, 0.316314136)
    P[54,.] = (-0.00179525, -0.004086714, -0.005417723, -0.006105744, -1.709027953, -2.961023806, -2.016300404, -1.471404534, -0.092721304, -0.151065777, -0.142110387, -0.122864487, -0.497264715, -0.42244023, -0.500157415, -0.683828054)
    P[55,.] = (-0.000109346, -5.35444E-05, 0, -0.003596853, 0, 0, 0, -1.260438948, 0, 0, 0, -0.069784359, -0.009288362, -0.426512724, 0, 0)
    P[56,.] = (0, 0, -5.57416E-05, 0, -0.674459313, 0, -0.621350492, -0.713530106, 0, 0, 0, 0, 0, -0.427537109, -0.374390888, -0.288974182)
    P[57,.] = (-0.005138561, -0.003190206, -0.00580564, -0.004742335, -3.034884695, -1.395732499, -1.970609696, -1.436365327, -0.195891984, -0.132984979, -0.157536611, -0.138135224, -0.602410686, -0.011191895, -0.488796736, -0.530722743)
    P[58,.] = (0, 0, -0.004283777, -0.004053352, 0, 0, -1.984788663, -1.891122229, 0, 0, -0.126796139, -0.128361041, -0.785227631, -0.594785802, -0.300198458, -0.603224179)
    P[59,.] = (-0.004463549, -0.004931673, 0, -0.002862951, -3.272972482, -2.462761762, 0, 0, -0.170881185, -0.111894795, 0, 0, -0.010121395, -0.588066534, -0.443113015, 0)
    P[60,.] = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.132384584, 0.271088476, 0, -0.311195596)
    P[61,.] = (0, 0, -0.002139895, -0.003923755, 0.528575644, 0.366450912, 0, -1.31877996, 0.026385386, 0, -0.064682374, -0.114348818, 0.067265656, -0.247275032, 0, 0)
    P[62,.] = (-0.00241816, -0.004474527, -0.00297588, 0.00023128, -3.169547182, -3.321085197, -3.169497865, 0, -0.1144538, -0.135673769, -0.103644277, 0, -0.570723203, -0.03959037, -0.788709363, -0.849343883)
    P[63,.] = (0, 0, -0.002984229, -0.002989047, 0.798089652, 0.412611617, -0.64630145, 0, 0.048845232, 0, -0.074881653, -0.061526855, 0, 0, 0, -0.147843764)
    return(P)
}

// ---------------------------------------------------------------------------
// GLS detrending (GAUSS __sbur_glsd): returns only the quasi-differenced SSR
// (fast path used inside the break-search loops)
// ---------------------------------------------------------------------------
real scalar _tsav_gls_ssr(real colvector y, real matrix z, real scalar cbar)
{
    real scalar T, abar
    real colvector ya, e, bhat
    real matrix za

    T = rows(y)
    abar = 1 + cbar/T
    ya = y[1] \ (y[2::T] - abar*y[1::(T-1)])
    za = z[1, .] \ (z[2::T, .] - abar*z[1::(T-1), .])
    bhat = invsym(cross(za, za))*cross(za, ya)
    e = ya - za*bhat
    return(cross(e, e))
}

// GLS detrending returning the detrended series (yt = y - z*bhat)
real colvector _tsav_glsd_yt(real colvector y, real matrix z, real scalar cbar)
{
    real scalar T, abar
    real colvector ya, bhat
    real matrix za

    T = rows(y)
    abar = 1 + cbar/T
    ya = y[1] \ (y[2::T] - abar*y[1::(T-1)])
    za = z[1, .] \ (z[2::T, .] - abar*z[1::(T-1), .])
    bhat = invsym(cross(za, za))*cross(za, ya)
    return(y - z*bhat)
}

// GLS coefficient vector (for the fitted broken trend in the graph)
real colvector _tsav_glsd_b(real colvector y, real matrix z, real scalar cbar)
{
    real scalar T, abar
    real colvector ya
    real matrix za

    T = rows(y)
    abar = 1 + cbar/T
    ya = y[1] \ (y[2::T] - abar*y[1::(T-1)])
    za = z[1, .] \ (z[2::T, .] - abar*z[1::(T-1), .])
    return(invsym(cross(za, za))*cross(za, ya))
}

// ---------------------------------------------------------------------------
// GAUSS __sbur_s2ar: lag choice for the long-run variance on OLS-detrended
// data, MAIC (penalty=0) or BIC (penalty=1)
// ---------------------------------------------------------------------------
real scalar _tsav_s2ar(real colvector yts, real scalar penalty,
    real scalar kmax, real scalar kmin)
{
    real scalar T, nef, k, j, kopt, sumy
    real colvector dyf, dep, b, e, s2e, tauv, mic, kk
    real matrix reg, regk

    T = rows(yts)
    dyf = yts[2::T] - yts[1::(T-1)]
    // dep and regressors on the common sample t = kmax+2 .. T
    dep = dyf[(kmax+1)::(T-1)]
    reg = yts[(kmax+1)::(T-1)]
    for (j = 1; j <= kmax; j++) {
        reg = reg, dyf[(kmax+1-j)::(T-1-j)]
    }
    nef = T - kmax - 1
    sumy = cross(reg[., 1], reg[., 1])
    s2e = J(kmax+1, 1, 999)
    tauv = J(kmax+1, 1, 0)
    for (k = kmin; k <= kmax; k++) {
        regk = reg[., 1::(k+1)]
        b = invsym(cross(regk, regk))*cross(regk, dep)
        e = dep - regk*b
        s2e[k+1] = cross(e, e)/nef
        tauv[k+1] = (b[1]*b[1])*sumy/s2e[k+1]
    }
    kk = (0::kmax)
    if (penalty == 0) {
        mic = ln(s2e) + 2:*(kk + tauv):/nef
    }
    else {
        mic = ln(s2e) + ln(nef):*kk:/nef
    }
    kopt = 1
    for (j = 2; j <= kmax+1; j++) {
        if (mic[j] < mic[kopt]) {
            kopt = j
        }
    }
    return(kopt - 1)
}

// ---------------------------------------------------------------------------
// GAUSS __sbur_adfp: ADF regression on the GLS-detrended series, no constant
// returns (adf t-stat, alpha-hat, autoregressive long-run variance)
// ---------------------------------------------------------------------------
real rowvector _tsav_adfp(real colvector yt, real scalar kstar)
{
    real scalar T, nef, s2e, sre, adf, sumb, j
    real colvector dyf, dep, rho, e
    real matrix reg, XX

    T = rows(yt)
    dyf = yt[2::T] - yt[1::(T-1)]
    dep = dyf[(kstar+1)::(T-1)]
    reg = yt[(kstar+1)::(T-1)]
    for (j = 1; j <= kstar; j++) {
        reg = reg, dyf[(kstar+1-j)::(T-1-j)]
    }
    XX = invsym(cross(reg, reg))
    rho = XX*cross(reg, dep)
    e = dep - reg*rho
    nef = rows(dep)
    s2e = cross(e, e)/nef
    sre = XX[1, 1]*s2e
    adf = rho[1]/sqrt(sre)
    if (kstar > 0) {
        sumb = sum(rho[2::(kstar+1)])
    }
    else {
        sumb = 0
    }
    return((adf, rho[1] + 1, s2e/(1 - sumb)^2))
}

// build the deterministic matrix z for the CiS models with breaks
real matrix _tsav_cis_z(real scalar T, real scalar model, real colvector tb)
{
    real matrix z
    real colvector du, dtj
    real scalar j, m

    z = J(T, 1, 1), (1::T)
    m = rows(tb)
    for (j = 1; j <= m; j++) {
        dtj = J(tb[j], 1, 0) \ (1::(T-tb[j]))
        if (model == 3) {
            du = J(tb[j], 1, 0) \ J(T-tb[j], 1, 1)
            z = z, du, dtj
        }
        else {
            z = z, dtj
        }
    }
    return(z)
}

// pad break fractions to a 5x1 vector
real colvector _tsav_lam5(real colvector tb, real scalar T)
{
    real colvector lam
    real scalar m

    m = rows(tb)
    lam = tb :/ T
    if (m < 5) {
        lam = lam \ J(5-m, 1, 0)
    }
    return(lam)
}

// ===========================================================================
// Bai-Perron dynamic-programming dating for the CiS-Kim-Perron estimation=1
// path. Faithful port of the __sbur_dating / recssr / __sbur_parti /
// __sbur_dating_gls / __recssr_gls / __sbur_est2_gls machinery of
// carrion silvestre2009.src (three-stage algorithm: OLS dating, iterated GLS
// re-dating with c_bar updating, and restricted GLS estimation).
// ===========================================================================

// index of the first column-minimum (GAUSS minindc)
real scalar _tsav_minindc(real colvector v)
{
    real scalar i, w

    w = min(v)
    for (i = 1; i <= rows(v); i++) {
        if (v[i] == w) {
            return(i)
        }
    }
    return(1)
}

// recursive OLS SSR for every segment ending, start..last (GAUSS recssr)
real colvector _tsav_recssr(real scalar start, real colvector y,
    real matrix z, real scalar h, real scalar last)
{
    real colvector vecssr, delta1, delta2, invz, res
    real matrix inv1, zs
    real scalar v, f, r

    vecssr = J(last, 1, 0)
    zs = z[start::(start+h-1), .]
    inv1 = luinv(cross(zs, zs))
    delta1 = inv1*cross(zs, y[start::(start+h-1)])
    res = y[start::(start+h-1)] - zs*delta1
    vecssr[start+h-1] = cross(res, res)
    for (r = start+h; r <= last; r++) {
        v = y[r] - z[r, .]*delta1
        invz = inv1*z[r, .]'
        f = 1 + z[r, .]*invz
        delta2 = delta1 + (invz*v)/f
        inv1 = inv1 - (invz*invz')/f
        delta1 = delta2
        vecssr[r] = vecssr[r-1] + v*v/f
    }
    return(vecssr)
}

// recursive GLS SSR (GAUSS __recssr_gls): appends a segment-initial impulse
// (=1 at the first observation of each segment) to the regressors
real colvector _tsav_recssr_gls(real scalar start, real colvector y,
    real matrix z, real scalar h, real scalar last)
{
    real colvector vecssr, delta1, delta2, invz, res, imp
    real matrix inv1, zs
    real rowvector zr
    real scalar v, f, r

    imp = 1 \ J(rows(z)-1, 1, 0)
    vecssr = J(last, 1, 0)
    zs = z[start::(start+h-1), .], imp[1::h]
    inv1 = luinv(cross(zs, zs))
    delta1 = inv1*cross(zs, y[start::(start+h-1)])
    res = y[start::(start+h-1)] - zs*delta1
    vecssr[start+h-1] = cross(res, res)
    for (r = start+h; r <= last; r++) {
        zr = z[r, .], imp[r-start+1]
        v = y[r] - zr*delta1
        invz = inv1*zr'
        f = 1 + zr*invz
        delta2 = delta1 + (invz*v)/f
        inv1 = inv1 - (invz*invz')/f
        delta1 = delta2
        vecssr[r] = vecssr[r-1] + v*v/f
    }
    return(vecssr)
}

// optimal one-break partition of a segment (GAUSS __sbur_parti)
void _tsav_parti(real scalar start, real scalar b1, real scalar b2,
    real scalar last, real colvector bigvec, real scalar bigt,
    real scalar ssrmin, real scalar dx)
{
    real colvector dvec
    real scalar j, jj, k, ini

    dvec = J(bigt, 1, 0)
    ini = (start-1)*bigt - (start-2)*(start-1)/2 + 1
    for (j = b1; j <= b2; j++) {
        jj = j - start
        k = j*bigt - (j-1)*j/2 + last - j
        dvec[j] = bigvec[ini+jj] + bigvec[k]
    }
    ssrmin = min(dvec[b1::b2])
    dx = (b1-1) + _tsav_minindc(dvec[b1::b2])
}

// Bai-Perron dating (GAUSS __sbur_dating / __sbur_dating_gls); glsflag picks
// the OLS or GLS recursive-SSR builder
void _tsav_dating(real colvector y, real matrix z, real scalar h,
    real scalar m, real scalar bigt, real scalar glsflag,
    real colvector glob, real matrix datevec, real colvector bigvec)
{
    real matrix optdat, optssr
    real colvector dvec, vecssr
    real scalar i, ssrmin, datx, j1, ib, jlast, jb, xx

    datevec = J(m, m, 0)
    optdat = J(bigt, m, 0)
    optssr = J(bigt, m, 0)
    dvec = J(bigt, 1, 0)
    glob = J(m, 1, 0)
    bigvec = J(bigt*(bigt+1)/2, 1, 0)
    for (i = 1; i <= bigt-h+1; i++) {
        if (glsflag == 0) {
            vecssr = _tsav_recssr(i, y, z, h, bigt)
        }
        else {
            vecssr = _tsav_recssr_gls(i, y, z, h, bigt)
        }
        bigvec[((i-1)*bigt+i-(i-1)*i/2)::(i*bigt-(i-1)*i/2)] = vecssr[i::bigt]
    }
    if (m == 1) {
        _tsav_parti(1, h, bigt-h, bigt, bigvec, bigt, ssrmin, datx)
        datevec[1, 1] = datx
        glob[1] = ssrmin
    }
    else {
        for (j1 = 2*h; j1 <= bigt; j1++) {
            _tsav_parti(1, h, j1-h, j1, bigvec, bigt, ssrmin, datx)
            optssr[j1, 1] = ssrmin
            optdat[j1, 1] = datx
        }
        glob[1] = optssr[bigt, 1]
        datevec[1, 1] = optdat[bigt, 1]
        for (ib = 2; ib <= m; ib++) {
            if (ib == m) {
                jlast = bigt
                for (jb = ib*h; jb <= jlast-h; jb++) {
                    dvec[jb] = optssr[jb, ib-1] + bigvec[(jb+1)*bigt-jb*(jb+1)/2]
                }
                optssr[jlast, ib] = min(dvec[(ib*h)::(jlast-h)])
                optdat[jlast, ib] = (ib*h-1) + _tsav_minindc(dvec[(ib*h)::(jlast-h)])
            }
            else {
                for (jlast = (ib+1)*h; jlast <= bigt; jlast++) {
                    for (jb = ib*h; jb <= jlast-h; jb++) {
                        dvec[jb] = optssr[jb, ib-1] + bigvec[jb*bigt-jb*(jb-1)/2+jlast-jb]
                    }
                    optssr[jlast, ib] = min(dvec[(ib*h)::(jlast-h)])
                    optdat[jlast, ib] = (ib*h-1) + _tsav_minindc(dvec[(ib*h)::(jlast-h)])
                }
            }
            datevec[ib, ib] = optdat[bigt, ib]
            for (i = 1; i <= ib-1; i++) {
                xx = ib - i
                datevec[xx, ib] = optdat[datevec[xx+1, ib], xx]
            }
            glob[ib] = optssr[bigt, ib]
        }
    }
}

// per-segment squared residuals under coefficients b (GAUSS __sbur_ssr2_gls)
real colvector _tsav_ssr2_gls(real colvector y, real matrix z,
    real colvector b, real scalar q, real colvector br)
{
    real scalar m, i, bigt
    real matrix imp
    real colvector bigvec2, e

    m = rows(br)
    bigt = rows(y)
    bigvec2 = J(bigt*(m+1), 1, 0)
    imp = 1 \ J(bigt-1, 1, 0)
    for (i = 1; i <= m; i++) {
        imp = imp, (J(br[i], 1, 0) \ 1 \ J(bigt-br[i]-1, 1, 0))
    }
    for (i = 1; i <= m+1; i++) {
        e = y - (z, imp[., i])*b[((i-1)*(q+1)+1)::(i*(q+1))]
        bigvec2[((i-1)*bigt+1)::(i*bigt)] = e:^2
    }
    return(bigvec2)
}

// one-break partition on the coefficient-based SSR (GAUSS __sbur_parti2)
void _tsav_parti2(real scalar start, real scalar b1, real scalar b2,
    real scalar last, real colvector bigvec2, real scalar bigt,
    real scalar ssrmin, real scalar dx)
{
    real colvector dvec
    real scalar j

    dvec = J(bigt, 1, 0)
    for (j = b1; j <= b2; j++) {
        dvec[j] = sum(bigvec2[start::j]) + sum(bigvec2[(bigt+j+1)::(bigt+last)])
    }
    ssrmin = min(dvec[b1::b2])
    dx = (b1-1) + _tsav_minindc(dvec[b1::b2])
}

// dating on coefficient-based SSR (GAUSS __sbur_dating2_gls)
void _tsav_dating2_gls(real colvector bigvec2, real scalar h,
    real scalar m, real scalar bigt, real colvector glob, real matrix datevec)
{
    real matrix optdat, optssr
    real colvector dvec
    real scalar i, ssrmin, datx, j1, ib, jlast, jb, xx

    datevec = J(m, m, 0)
    optdat = J(bigt, m, 0)
    optssr = J(bigt, m, 0)
    dvec = J(bigt, 1, 0)
    glob = J(m, 1, 0)
    if (m == 1) {
        _tsav_parti2(1, h, bigt-h, bigt, bigvec2, bigt, ssrmin, datx)
        datevec[1, 1] = datx
        glob[1] = ssrmin
    }
    else {
        for (j1 = 2*h; j1 <= bigt; j1++) {
            _tsav_parti2(1, h, j1-h, j1, bigvec2[1::(2*bigt)], bigt, ssrmin, datx)
            optssr[j1, 1] = ssrmin
            optdat[j1, 1] = datx
        }
        glob[1] = optssr[bigt, 1]
        datevec[1, 1] = optdat[bigt, 1]
        for (ib = 2; ib <= m; ib++) {
            if (ib == m) {
                jlast = bigt
                for (jb = ib*h; jb <= jlast-h; jb++) {
                    dvec[jb] = optssr[jb, ib-1] + sum(bigvec2[(bigt*m+jb+1)::(bigt*(m+1))])
                }
                optssr[jlast, ib] = min(dvec[(ib*h)::(jlast-h)])
                optdat[jlast, ib] = (ib*h-1) + _tsav_minindc(dvec[(ib*h)::(jlast-h)])
            }
            else {
                for (jlast = (ib+1)*h; jlast <= bigt; jlast++) {
                    for (jb = ib*h; jb <= jlast-h; jb++) {
                        dvec[jb] = optssr[jb, ib-1] + sum(bigvec2[(bigt*ib+jb+1)::(bigt*ib+jlast)])
                    }
                    optssr[jlast, ib] = min(dvec[(ib*h)::(jlast-h)])
                    optdat[jlast, ib] = (ib*h-1) + _tsav_minindc(dvec[(ib*h)::(jlast-h)])
                }
            }
            datevec[ib, ib] = optdat[bigt, ib]
            for (i = 1; i <= ib-1; i++) {
                xx = ib - i
                datevec[xx, ib] = optdat[datevec[xx+1, ib], xx]
            }
            glob[ib] = optssr[bigt, ib]
        }
    }
}

// block-diagonal GLS regressor matrix with per-segment impulse (GAUSS zbar)
real matrix _tsav_cis_zbar(real matrix z2, real colvector dv, real scalar T,
    real scalar q)
{
    real matrix zbar, blk, imp
    real scalar i, m, t1, t2, tbar

    m = rows(dv)
    imp = 1 \ J(T-1, 1, 0)
    tbar = dv[1]
    zbar = (z2[1::tbar, .], imp[1::tbar]) \ J(T-tbar, q+1, 0)
    for (i = 2; i <= m; i++) {
        t1 = dv[i-1]
        t2 = dv[i]
        blk = J(t1, q+1, 0) \ (z2[(t1+1)::t2, .], imp[1::(t2-t1)]) \ J(T-t2, q+1, 0)
        zbar = zbar, blk
    }
    t2 = dv[m]
    blk = J(t2, q+1, 0) \ (z2[(t2+1)::T, .], imp[1::(T-t2)])
    zbar = zbar, blk
    return(zbar)
}

// restriction matrix R for the restricted GLS estimation (GAUSS est2 R)
real matrix _tsav_cis_R(real scalar model1, real scalar alpha,
    real colvector dv, real scalar m, real scalar q)
{
    real matrix R, temp, temp2
    real scalar i, ncol

    ncol = (m+1)*3
    R = (-alpha, 0, 1), J(1, m*3, 0)
    temp = J(m, ncol, 0)
    for (i = 1; i <= m; i++) {
        if (model1 == 2) {
            temp[i, (3*i-2)::((i+1)*3)] = (-1, -dv[i], 0, 1, dv[i], 0)
        }
        else {
            temp[i, (3*i-2)::((i+1)*3)] = (-1, -dv[i], 0, 1, dv[i], -1/alpha)
        }
    }
    R = R \ temp
    if (model1 == 2) {
        temp2 = J(m, ncol, 0)
        for (i = 1; i <= m; i++) {
            temp2[i, 3*(i+1)] = 1
        }
        R = R \ temp2
    }
    return(R)
}

// restricted GLS estimation stage (GAUSS __sbur_est2_gls); returns the refined
// break dates in brout and the restricted SSR in ssrout (inner cap = 10 iters)
void _tsav_est2_gls(real colvector y, real scalar model1, real scalar q,
    real scalar m, real scalar T, real scalar trm, real colvector dvin,
    real colvector brout, real scalar ssrout)
{
    real matrix z2, zbar, R, zz, datevec2
    real colvector dv, ygls, cns, tend, b, delta, e, bigvec2, glob
    real scalar h, cbar, alpha, ssrprev, ssrnew, count

    h = round(trm*T)
    dv = sort(dvin, 1)
    cbar = _tsav_cbar(_tsav_lam5(dv, T))
    alpha = 1 + cbar/T
    cns = J(T, 1, 1-alpha)
    tend = 1 \ ((-cbar/T):*(1::(T-1)) :+ 1)
    z2 = cns, tend
    ygls = y[1] \ (y[2::T] - alpha*y[1::(T-1)])
    zbar = _tsav_cis_zbar(z2, dv, T, q)
    R = _tsav_cis_R(model1, alpha, dv, m, q)
    b = qrsolve(zbar, ygls)
    zz = invsym(cross(zbar, zbar))
    delta = b + zz*R'*invsym(R*zz*R')*(-(R*b))
    e = ygls - zbar*delta
    ssrprev = cross(e, e)
    count = 0
    while (1) {
        bigvec2 = _tsav_ssr2_gls(ygls, z2, delta, q, dv)
        _tsav_dating2_gls(bigvec2, h, m, T, glob, datevec2)
        dv = datevec2[., m]
        cbar = _tsav_cbar(_tsav_lam5(sort(dv, 1), T))
        alpha = 1 + cbar/T
        cns = J(T, 1, 1-alpha)
        tend = 1 \ ((-cbar/T):*(1::(T-1)) :+ 1)
        z2 = cns, tend
        ygls = y[1] \ (y[2::T] - alpha*y[1::(T-1)])
        zbar = _tsav_cis_zbar(z2, dv, T, q)
        R = _tsav_cis_R(model1, alpha, dv, m, q)
        b = qrsolve(zbar, ygls)
        zz = invsym(cross(zbar, zbar))
        delta = b + zz*R'*invsym(R*zz*R')*(-(R*b))
        e = ygls - zbar*delta
        ssrnew = cross(e, e)
        if (count < 10 & abs(ssrnew-ssrprev) > 1e-3) {
            count = count + 1
            ssrprev = ssrnew
        }
        else {
            brout = dv
            ssrout = ssrnew
            return
        }
    }
}

// dynamic-programming driver (GAUSS __sbur_multiple_gls_algorithm): three
// stages (OLS dating -> iterated GLS dating -> restricted estimation). Returns
// the final break dates (sorted) in mintb and the stage-2 c_bar in cbarout
// (the source uses the stage-2 c_bar for the final statistics while building
// the regressors from the stage-3 dates).
void _tsav_cis_dp(real colvector y, real scalar model1, real scalar m,
    real scalar maxiter, real colvector mintb, real scalar cbarout)
{
    real matrix zols, zg, datevec, datevec2
    real colvector dv, glob, glob2, bigvec, cns, tend, ygls, dxout
    real scalar T, trm, h1, cbar, alpha, ssrprev, count, ssrdummy, ssrest, ssrestprev

    T = rows(y)
    trm = 0.10
    h1 = trunc(trm*T)
    // ---- stage 1: OLS Bai-Perron dating ----
    zols = J(T, 1, 1), (1::T)
    _tsav_dating(y, zols, h1, m, T, 0, glob, datevec, bigvec)
    dv = select(datevec[., m], datevec[., m] :> 0)
    dv = sort(dv, 1)
    // ---- stage 2: iterated GLS re-dating with c_bar updating ----
    count = 0
    ssrprev = glob[m]
    cbar = _tsav_cbar(_tsav_lam5(dv, T))
    while (1) {
        cbar = _tsav_cbar(_tsav_lam5(dv, T))
        alpha = 1 + cbar/T
        cns = 1 \ J(T-1, 1, 1-alpha)
        tend = 1 \ ((-cbar/T):*(2::T) :+ 1)
        zg = cns, tend
        ygls = y[1] \ (y[2::T] - alpha*y[1::(T-1)])
        _tsav_dating(ygls, zg, h1, m, T, 1, glob2, datevec2, bigvec)
        if (count < maxiter & abs(glob2[m]-ssrprev) > 1e-3) {
            ssrprev = glob2[m]
            dv = datevec2[., m]
            count = count + 1
        }
        else {
            break
        }
    }
    cbarout = cbar
    // ---- stage 3: restricted GLS estimation (outer iteration) ----
    count = 0
    ssrestprev = cross(y, y)
    while (1) {
        _tsav_est2_gls(y, model1, 2, m, T, trm, dv, dxout, ssrest)
        if (count < maxiter & abs(ssrest-ssrestprev) > 1e-3) {
            count = count + 1
            ssrestprev = ssrest
            dv = sort(dxout, 1)
        }
        else {
            break
        }
    }
    mintb = sort(dv, 1)
}

// ---------------------------------------------------------------------------
// CiS main routine (GAUSS sbur_gls + __sbur_multiple_gls_brute /
// __sbur_multiple_gls_algorithm, exact)
// model: 0 const / 1 trend / 2 slope breaks / 3 level+slope breaks
// known = 1 with tbmat holding known break positions; est = 0 brute search
// (sburControlCreate default), est = 1 dynamic-programming dating
// Fills: STname (1x7: pt mpt adf za mza msb mzt), CVname (4x4), TBname (mx1)
//        r(cbar), r(krule); stores the fitted GLS trend in fitname
// ---------------------------------------------------------------------------
void _tsav_cis(string scalar yname, string scalar touse, real scalar model,
    real scalar known, string scalar tbmat, real scalar nbrk,
    real scalar penalty, real scalar kmax, real scalar kmin,
    real scalar est, real scalar maxiter,
    string scalar fitname, string scalar STname, string scalar CVname,
    string scalar TBname)
{
    real colvector y, mintb, lam, yt, ydols, bo, bgls, tbc, adfrow
    real matrix z, zc, CV
    real scalar T, cbar, cb, minssra, ssra, j, jj, jjj
    real scalar ahat, s2u, sumyt2, krule, adf, sar, bt, za, mza, msb, mzt
    real scalar ssr1, pt, mpt, ssrafin
    real colvector x1, r

    y = st_data(., yname, touse)
    T = rows(y)
    mintb = J(1, 1, 0)

    if (model == 0) {
        z = J(T, 1, 1)
        cbar = -7
    }
    else if (model == 1) {
        z = J(T, 1, 1), (1::T)
        cbar = -13.5
    }
    else {
        if (known == 1) {
            mintb = st_matrix(tbmat)
            if (cols(mintb) > 1) {
                mintb = mintb'
            }
            z = _tsav_cis_z(T, model, mintb)
            cbar = _tsav_cbar(_tsav_lam5(mintb, T))
        }
        else if (est == 1) {
            // dynamic-programming dating (GAUSS estimation = 1); mintb gets the
            // stage-3 dates and cbar the stage-2 c_bar (source convention)
            _tsav_cis_dp(y, model, nbrk, maxiter, mintb, cbar)
            z = _tsav_cis_z(T, model, mintb)
        }
        else {
            minssra = cross(y, y)
            if (nbrk == 1) {
                for (j = 3; j <= T-3; j++) {
                    tbc = (j)
                    zc = _tsav_cis_z(T, model, tbc)
                    cb = _tsav_cbar(_tsav_lam5(tbc, T))
                    ssra = _tsav_gls_ssr(y, zc, cb)
                    if (ssra < minssra) {
                        mintb = tbc
                        minssra = ssra
                    }
                }
            }
            else if (nbrk == 2) {
                for (j = 3; j <= T-3-2; j++) {
                    for (jj = j+2; jj <= T-3; jj++) {
                        tbc = (j \ jj)
                        zc = _tsav_cis_z(T, model, tbc)
                        cb = _tsav_cbar(_tsav_lam5(tbc, T))
                        ssra = _tsav_gls_ssr(y, zc, cb)
                        if (ssra < minssra) {
                            mintb = tbc
                            minssra = ssra
                        }
                    }
                }
            }
            else {
                for (j = 3; j <= T-3-4; j++) {
                    for (jj = j+2; jj <= T-3-2; jj++) {
                        for (jjj = jj+2; jjj <= T-3; jjj++) {
                            tbc = (j \ jj \ jjj)
                            zc = _tsav_cis_z(T, model, tbc)
                            cb = _tsav_cbar(_tsav_lam5(tbc, T))
                            ssra = _tsav_gls_ssr(y, zc, cb)
                            if (ssra < minssra) {
                                mintb = tbc
                                minssra = ssra
                            }
                        }
                    }
                }
            }
            z = _tsav_cis_z(T, model, mintb)
            cbar = _tsav_cbar(_tsav_lam5(mintb, T))
        }
    }

    // final GLS detrending and unit-root statistics (source common tail)
    ssrafin = _tsav_gls_ssr(y, z, cbar)
    yt = _tsav_glsd_yt(y, z, cbar)
    x1 = yt[1::(T-1)]
    ahat = cross(x1, yt[2::T])/cross(x1, x1)
    r = yt[2::T] - ahat*x1
    s2u = cross(r, r)/(T - 1)
    sumyt2 = cross(x1, x1)/((T - 1)^2)

    // long-run variance: lags chosen on OLS-detrended data (Perron's note)
    bo = invsym(cross(z, z))*cross(z, y)
    ydols = y - z*bo
    krule = _tsav_s2ar(ydols, penalty, kmax, kmin)
    adfrow = _tsav_adfp(yt, krule)'
    adf = adfrow[1]
    sar = adfrow[3]

    bt = T - 1
    za = bt*(ahat - 1) - (sar - s2u)/(2*sumyt2)
    mza = ((yt[T]^2)/bt - sar)/(2*sumyt2)
    msb = sqrt(sumyt2/sar)
    mzt = mza*msb

    // PT and MPT
    ssr1 = _tsav_gls_ssr(y, z, 0)
    pt = (ssrafin - (1 + cbar/T)*ssr1)/sar
    if (model == 0) {
        mpt = (cbar*cbar*sumyt2 - cbar*((yt[T]^2)/T))/sar
    }
    else {
        mpt = (cbar*cbar*sumyt2 + (1 - cbar)*((yt[T]^2)/T))/sar
    }

    // critical values from the response surfaces
    if (model <= 1) {
        lam = J(5, 1, 0)
    }
    else {
        lam = _tsav_lam5(mintb, T)
    }
    CV = _tsav_ciscv(lam, cbar)

    // fitted broken trend for the graph
    bgls = _tsav_glsd_b(y, z, cbar)
    st_store(., fitname, touse, z*bgls)

    st_matrix(STname, (pt, mpt, adf, za, mza, msb, mzt))
    st_matrix(CVname, CV)
    st_matrix(TBname, mintb)
    st_numscalar("r(cbar)", cbar)
    st_numscalar("r(krule)", krule)
}

end
*==============================================================================
* End of tsadvroot.ado
*==============================================================================
