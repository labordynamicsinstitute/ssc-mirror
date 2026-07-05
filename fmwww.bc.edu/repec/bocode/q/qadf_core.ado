*! qadf_core - internal computational engine for the QADF package
*! Version 1.1.0, 03 July 2026
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Called by qadf, qadf_boot and qadf_process; not for direct end-user use.

*==============================================================================
* qadf_core -- internal computational engine (also used by the bootstrap).
* Exact translation of the GAUSS QRADF procedure (qr_adf.src, fourier=0):
*   1. lag order p from the constant-only OLS ADF regression (tspdlib rules),
*      unless a fixed p() is supplied
*   2. estimation sample drops the first p+1 observations
*   3. quantile regressions of y_t (levels) on [y_{t-1}, D.y lags, (trend)]
*      at tau and tau +/- h solved exactly by qreg
*   4. t_n(tau) via the difference-quotient sparsity estimate and the
*      projection off [1, dyl]; Hansen (1995) critical values on delta2
* Assumes a tsset, contiguous series.
*==============================================================================
program define qadf_core, rclass
    version 14.0
    syntax varname [if] [, TAU(real 0.5) Model(string) PMAX(integer 8) ///
        ICN(integer 3) P(integer -1) ]

    local yv `varlist'
    if "`model'" == "" local model "c"
    marksample touse
    qui count if `touse'
    local T = r(N)

    * ---- lag selection: GAUSS { ADFt, p, cv } = ADF(y, 1, pmax, ic) ---------
    local adft = .
    if `p' >= 0 {
        local plag = `p'
    }
    else {
        mata: qadfm_adfsel("`yv'", "`touse'", `pmax', `icn')
        local plag = r(adflag)
        local adft = r(adf_t)
    }
    if `T' < `plag' + 15 {
        di as err "qadf core: series too short (T=`T', lags=`plag')"
        exit 2001
    }

    * ---- regressors on the trimmed sample (positions p+2 .. T) --------------
    tempvar pos esamp y1
    qui gen long `pos' = sum(`touse')
    qui gen byte `esamp' = `touse' & (`pos' > `plag' + 1)
    qui gen double `y1' = L.`yv' if `touse'
    local xvars "`y1'"
    forvalues j = 1/`plag' {
        tempvar dy`j'
        qui gen double `dy`j'' = L`j'.D.`yv' if `touse'
        local xvars "`xvars' `dy`j''"
    }
    if "`model'" == "ct" {
        tempvar trnd
        qui gen double `trnd' = `pos' if `touse'
        local xvars "`xvars' `trnd'"
    }
    qui count if `esamp'
    local neff = r(N)

    * ---- bandwidth and the three exact quantile regressions -----------------
    mata: st_local("h", strofreal(qadfm_h(`tau', `neff'), "%18.0g"))
    local t1 = `tau' + `h'
    if `t1' >= 1 local t1 = .9999
    local t2 = `tau' - `h'
    if `t2' <= 0 local t2 = .0001

    tempname b0 b1 b2
    capture qui qreg `yv' `xvars' if `esamp', quantile(`tau')
    if _rc {
        di as err "qreg failed at tau = `tau' (rc = " _rc ")"
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

    local mnum 1
    if "`model'" == "ct" local mnum 2
    mata: qadfm_finish("`yv'", "`xvars'", "`esamp'", `tau', `h', ///
        "`b0'", "`b1'", "`b2'", `plag', `mnum')

    local rho = r(rho_tau)
    local alpha = r(alpha_tau)
    local rols = r(rho_ols)
    local d2 = r(delta2)
    local tn = r(tn)
    local c1 = r(cv1)
    local c5 = r(cv5)
    local c10 = r(cv10)

    * half-life of a shock at quantile tau
    local hl = .
    if `rho' < 1 & `rho' > 0 {
        local hl = ln(0.5)/ln(abs(`rho'))
        if `hl' <= 0 local hl = .
    }

    return scalar tn = `tn'
    return scalar Un = `neff'*(`rho' - 1)
    return scalar rho_tau = `rho'
    return scalar rho_ols = `rols'
    return scalar alpha_tau = `alpha'
    return scalar delta2 = `d2'
    return scalar half_life = `hl'
    return scalar lags = `plag'
    return scalar neff = `neff'
    return scalar adf_t = `adft'
    return scalar cv1 = `c1'
    return scalar cv5 = `c5'
    return scalar cv10 = `c10'
end
