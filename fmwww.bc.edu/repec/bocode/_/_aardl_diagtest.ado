*! _aardl_diagtest - full residual and specification diagnostics for aardl
*! Version 2.0.0 - 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Must be called while the OLS companion regression is the active estimate,
*! so that estat bgodfrey / durbinalt / archlm / hettest / imtest / ovtest /
*! vif all operate on the correct model and sample.
*!
*! Panels
*!   A  Normality        Jarque-Bera, skewness, kurtosis, Shapiro-Wilk,
*!                       Shapiro-Francia
*!   B  Serial correl.   Breusch-Godfrey LM (1-4 lags), Durbin alternative,
*!                       Ljung-Box portmanteau Q
*!   C  Heteroskedast.   Breusch-Pagan/Cook-Weisberg, White general,
*!                       ARCH LM (1, 2, 4 lags)
*!   D  Functional form  Ramsey RESET
*!   E  Collinearity     VIF (mean and maximum)

capture program drop _aardl_diagtest
program define _aardl_diagtest, rclass
    version 17

    syntax varname, ESample(varname) [ SERIALlags(integer 4) ]

    local resid "`varlist'"

    // the VIF panel refits auxiliary regressions, so protect the active model
    tempname _dgsave
    capture estimates store `_dgsave'

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 4: Diagnostic tests"
    di as txt "{hline 78}"

    tempname D
    mat `D' = J(40, 3, .)
    local rn ""
    local nr 0

    // =====================================================================
    // A. NORMALITY
    // =====================================================================
    di as txt ""
    di as txt _col(3) "{bf:A. Normality of residuals}"
    di as txt "  {hline 72}"
    di as txt _col(5) "Test" _col(34) "Statistic" _col(50) "p-value" _col(63) "Result"
    di as txt "  {hline 72}"

    qui summarize `resid' if `esample', detail
    local nn   = r(N)
    local sk   = r(skewness)
    local ku   = r(kurtosis)
    local jb   = (`nn'/6)*((`sk')^2 + ((`ku')-3)^2/4)
    local jb_p = chi2tail(2, `jb')
    local r1   = cond(`jb_p' < 0.05, "Non-normal", "Normal")
    di as txt _col(5) "Jarque-Bera" _col(32) as res %10.4f `jb' ///
       _col(48) %8.4f `jb_p' _col(63) "`r1'"
    local ++nr
    mat `D'[`nr',1] = `jb'
    mat `D'[`nr',2] = `jb_p'
    local rn "`rn' jarque_bera"

    di as txt _col(5) "  Skewness" _col(32) as res %10.4f `sk'
    di as txt _col(5) "  Kurtosis" _col(32) as res %10.4f `ku'
    local ++nr
    mat `D'[`nr',1] = `sk'
    local rn "`rn' skewness"
    local ++nr
    mat `D'[`nr',1] = `ku'
    local rn "`rn' kurtosis"

    capture qui swilk `resid' if `esample'
    if _rc == 0 {
        local sw = r(W)
        local sw_p = r(p)
        local r2 = cond(`sw_p' < 0.05, "Non-normal", "Normal")
        di as txt _col(5) "Shapiro-Wilk W" _col(32) as res %10.4f `sw' ///
           _col(48) %8.4f `sw_p' _col(63) "`r2'"
        local ++nr
        mat `D'[`nr',1] = `sw'
        mat `D'[`nr',2] = `sw_p'
        local rn "`rn' shapiro_wilk"
    }
    capture qui sfrancia `resid' if `esample'
    if _rc == 0 {
        local sf = r(W)
        local sf_p = r(p)
        local r3 = cond(`sf_p' < 0.05, "Non-normal", "Normal")
        di as txt _col(5) "Shapiro-Francia W'" _col(32) as res %10.4f `sf' ///
           _col(48) %8.4f `sf_p' _col(63) "`r3'"
        local ++nr
        mat `D'[`nr',1] = `sf'
        mat `D'[`nr',2] = `sf_p'
        local rn "`rn' shapiro_francia"
    }
    di as txt "  {hline 72}"

    // =====================================================================
    // B. SERIAL CORRELATION
    // =====================================================================
    di as txt ""
    di as txt _col(3) "{bf:B. Serial correlation}"
    di as txt "  {hline 72}"
    di as txt _col(5) "Test" _col(34) "Statistic" _col(50) "p-value" _col(63) "Result"
    di as txt "  {hline 72}"

    local anybg 0
    forvalues L = 1/`seriallags' {
        capture qui estat bgodfrey, lags(`L')
        if _rc continue
        _aardl_getstat 1
        local st = r(stat)
        local pv = r(pval)
        if missing(`st') continue
        local anybg 1
        local rr = cond(`pv' < 0.05, "Serial corr.", "No serial corr.")
        di as txt _col(5) "Breusch-Godfrey LM, `L' lag(s)" _col(32) ///
           as res %10.4f `st' _col(48) %8.4f `pv' _col(63) "`rr'"
        local ++nr
        mat `D'[`nr',1] = `st'
        mat `D'[`nr',2] = `pv'
        local rn "`rn' bg`L'"
    }
    if !`anybg' {
        di as txt _col(5) "Breusch-Godfrey LM" _col(32) as txt "(not available)"
    }

    capture qui estat durbinalt, lags(`seriallags')
    if _rc == 0 {
        _aardl_getstat 1
        local st = r(stat)
        local pv = r(pval)
        if !missing(`st') {
            local rr = cond(`pv' < 0.05, "Serial corr.", "No serial corr.")
            di as txt _col(5) "Durbin alternative, `seriallags' lag(s)" _col(32) ///
               as res %10.4f `st' _col(48) %8.4f `pv' _col(63) "`rr'"
            local ++nr
            mat `D'[`nr',1] = `st'
            mat `D'[`nr',2] = `pv'
            local rn "`rn' durbinalt"
        }
    }

    foreach L in 4 8 12 {
        capture qui wntestq `resid' if `esample', lags(`L')
        if _rc == 0 {
            local st = r(stat)
            local pv = r(p)
            local rr = cond(`pv' < 0.05, "Not white noise", "White noise")
            di as txt _col(5) "Ljung-Box Q(`L')" _col(32) as res %10.4f `st' ///
               _col(48) %8.4f `pv' _col(63) "`rr'"
            local ++nr
            mat `D'[`nr',1] = `st'
            mat `D'[`nr',2] = `pv'
            local rn "`rn' lbq`L'"
        }
    }
    di as txt "  {hline 72}"

    // =====================================================================
    // C. HETEROSKEDASTICITY
    // =====================================================================
    di as txt ""
    di as txt _col(3) "{bf:C. Heteroskedasticity}"
    di as txt "  {hline 72}"
    di as txt _col(5) "Test" _col(34) "Statistic" _col(50) "p-value" _col(63) "Result"
    di as txt "  {hline 72}"

    capture qui estat hettest
    if _rc == 0 {
        local st = r(chi2)
        local pv = r(p)
        local rr = cond(`pv' < 0.05, "Heteroskedastic", "Homoskedastic")
        di as txt _col(5) "Breusch-Pagan / Cook-Weisberg" _col(32) ///
           as res %10.4f `st' _col(48) %8.4f `pv' _col(63) "`rr'"
        local ++nr
        mat `D'[`nr',1] = `st'
        mat `D'[`nr',2] = `pv'
        local rn "`rn' bpagan"
    }
    capture qui estat imtest, white
    if _rc == 0 {
        local st = r(chi2)
        local pv = r(p)
        local rr = cond(`pv' < 0.05, "Heteroskedastic", "Homoskedastic")
        di as txt _col(5) "White general test" _col(32) as res %10.4f `st' ///
           _col(48) %8.4f `pv' _col(63) "`rr'"
        local ++nr
        mat `D'[`nr',1] = `st'
        mat `D'[`nr',2] = `pv'
        local rn "`rn' white"
    }
    foreach L in 1 2 4 {
        capture qui estat archlm, lags(`L')
        if _rc continue
        _aardl_getstat 1
        local st = r(stat)
        local pv = r(pval)
        if missing(`st') continue
        local rr = cond(`pv' < 0.05, "ARCH effects", "No ARCH")
        di as txt _col(5) "ARCH LM, `L' lag(s)" _col(32) as res %10.4f `st' ///
           _col(48) %8.4f `pv' _col(63) "`rr'"
        local ++nr
        mat `D'[`nr',1] = `st'
        mat `D'[`nr',2] = `pv'
        local rn "`rn' arch`L'"
    }
    di as txt "  {hline 72}"

    // =====================================================================
    // D. FUNCTIONAL FORM
    // =====================================================================
    di as txt ""
    di as txt _col(3) "{bf:D. Functional form}"
    di as txt "  {hline 72}"
    capture qui estat ovtest
    if _rc == 0 {
        local st = r(F)
        local pv = r(p)
        local rr = cond(`pv' < 0.05, "Misspecified", "Correct spec.")
        di as txt _col(5) "Ramsey RESET (powers of fitted)" _col(32) ///
           as res %10.4f `st' _col(48) %8.4f `pv' _col(63) "`rr'"
        local ++nr
        mat `D'[`nr',1] = `st'
        mat `D'[`nr',2] = `pv'
        local rn "`rn' reset"
    }
    else {
        di as txt _col(5) "Ramsey RESET" _col(32) as txt "(not available)"
    }
    di as txt "  {hline 72}"

    // =====================================================================
    // E. COLLINEARITY
    // =====================================================================
    di as txt ""
    di as txt _col(3) "{bf:E. Collinearity}"
    di as txt "  {hline 72}"
    local rhs : colnames e(b)
    local cnsname "_cons"
    local rhs : list rhs - cnsname
    local vmax = .
    local vsum = 0
    local vcnt = 0
    foreach v of local rhs {
        local vloc "`v'"
        local others : list rhs - vloc
        if "`others'" == "" continue
        capture qui regress `v' `others' if `esample'
        if _rc == 0 {
            if e(r2) < 1 {
                local vf = 1/(1 - e(r2))
                local vsum = `vsum' + `vf'
                local ++vcnt
                if `vf' > `vmax' | missing(`vmax') local vmax = `vf'
            }
        }
    }
    if `vcnt' > 0 {
        local vmean = `vsum'/`vcnt'
        local rr = cond(`vmax' > 10, "Severe collinearity", ///
                   cond(`vmax' > 5, "Moderate", "Acceptable"))
        di as txt _col(5) "Mean VIF" _col(32) as res %10.4f `vmean'
        di as txt _col(5) "Max  VIF" _col(32) as res %10.4f `vmax' ///
           _col(63) "`rr'"
        local ++nr
        mat `D'[`nr',1] = `vmean'
        local rn "`rn' vif_mean"
        local ++nr
        mat `D'[`nr',1] = `vmax'
        local rn "`rn' vif_max"
    }
    else {
        di as txt _col(5) "VIF" _col(32) as txt "(not available)"
    }
    di as txt "  {hline 72}"

    di as txt ""
    di as txt _col(5) "{it:Persistent serial correlation or heteroskedasticity: refit with}"
    di as txt _col(5) "{it:vce(hac) (Newey-West) or vce(robust). The three bounds statistics}"
    di as txt _col(5) "{it:and their bootstrap null distribution then use the same estimator.}"
    di as txt ""

    capture estimates restore `_dgsave'
    capture estimates drop `_dgsave'

    if `nr' > 0 & `nr' <= rowsof(`D') {
        mat `D' = `D'[1..`nr', 1..3]
        mat rownames `D' = `rn'
        mat colnames `D' = statistic pvalue df
        return matrix diag = `D'
    }
    return scalar ndiag = `nr'
end

// -------------------------------------------------------------------------
// helper: read a chi2/p pair from r() whether it is stored as a scalar or
// as a 1 x L / L x 1 matrix (estat return shapes differ across tests)
// -------------------------------------------------------------------------
capture program drop _aardl_getstat
program define _aardl_getstat, rclass
    version 17
    args pos
    if "`pos'" == "" local pos 1

    local st = .
    local pv = .
    foreach nm in chi2 arch F {
        if !missing(`st') continue
        capture local st = r(`nm')
        if _rc {
            local st = .
            tempname M
            capture mat `M' = r(`nm')
            if _rc == 0 {
                if rowsof(`M') == 1 local st = el(`M', 1, `pos')
                else                local st = el(`M', `pos', 1)
            }
        }
    }
    capture local pv = r(p)
    if _rc {
        tempname P
        capture mat `P' = r(p)
        if _rc == 0 {
            if rowsof(`P') == 1 local pv = el(`P', 1, `pos')
            else                local pv = el(`P', `pos', 1)
        }
    }
    return scalar stat = `st'
    return scalar pval = `pv'
end
