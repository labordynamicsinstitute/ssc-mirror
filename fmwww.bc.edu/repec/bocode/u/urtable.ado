*! version 1.0.0  22may2026  Y. Baris Altayligil
*! ADF, DF-GLS (3 criteria), PP, KPSS in one table with data-driven lags
*! Email: ybaris@istanbul.edu.tr
*============================================================================*
* urtable.ado
* ADF, DF-GLS (3 lag-selection criteria), PP, and KPSS unit-root tests in
* one comparison table with data-driven lag/bandwidth selection.
* Author : Y. Baris Altayligil - Istanbul University, Time Series Course
* Refs   : Levendis (2018) Ch.7; Elliott-Rothenberg-Stock (1996);
*          Ng-Perron (2001); KPSS (1992); Andrews (1991); Hall (1994).
*
* Usage:
*     tsset time
*     do urtable.do
*     urtable y                              // constant model
*     urtable y, lags(8) trend               // trend model, max lag = 8
*     urtable y, bgp(0.05) rhocap(0.95)      // stricter BG, lower rho cap
*
* Options:
*     lags(#)     max lag for ADF BG search and DF-GLS criterion search.
*                 Default: floor(12*(T/100)^(1/4))  (Schwert rule).
*     trend       include linear trend in deterministic component.
*     bgp(#)      BG p-value threshold for ADF lag selection. Default 0.10.
*     rhocap(#)   |rho| cap for Andrews AR(1) plug-in. Default 0.97.
*
* Lag / bandwidth selection (all data-driven):
*   ADF      : general-to-specific via Breusch-Godfrey: smallest k in [0,lags]
*              with residual BG p-value > bgp() (BG order = max(4, k+1)).
*   DF-GLS   : 3 rows, one per criterion (ERS seq-t, Min SC, Min MAIC).
*   PP       : Andrews (1991) AR(1) plug-in for Bartlett kernel.
*   KPSS     : Andrews (1991), residuals from y on const(+trend).
*
* DF-GLS is computed manually (not via Stata's dfgls):
*   - GLS-detrending (cbar = -7 constant, -13.5 constant+trend).
*   - ADF-type regression on the GLS-detrended series at each k.
*   - ERS (1996) Table 1 critical values (sample-size bracketed).
*============================================================================*


*----------------------------------------------------------------------------*
* Helper: Andrews (1991) AR(1) plug-in bandwidth for Bartlett kernel        *
*   alpha(1) = 4*rho^2 / (1-rho^2)^2                                        *
*   BW_raw   = 1.1447 * (alpha(1) * T)^(1/3)                                *
*   BW       = ceil(BW_raw), clamped to [1, schwert].                       *
*   |rho| is capped at rhocap to avoid blowup near unit root.               *
*----------------------------------------------------------------------------*
cap program drop _andrews_bw
program define _andrews_bw, rclass
    syntax varname(ts), TOUSE(varname) TOBS(integer) ///
        [ RHOcap(real 0.97) SCHwert(integer 99) ]

    qui reg `varlist' L.`varlist' if `touse'
    local rho = _b[L.`varlist']
    if `rho' >  `rhocap' local rho =  `rhocap'
    if `rho' < -`rhocap' local rho = -`rhocap'
    local alpha1 = 4 * `rho'^2 / ((1 - `rho'^2)^2)
    local bw_raw = 1.1447 * (`alpha1' * `tobs')^(1/3)
    local bw = ceil(`bw_raw')
    if `bw' < 1         local bw = 1
    if `bw' > `schwert' local bw = `schwert'

    return scalar rho    = `rho'
    return scalar bw_raw = `bw_raw'
    return scalar bw     = `bw'
end


*----------------------------------------------------------------------------*
* Main program: urtable                                                     *
*----------------------------------------------------------------------------*
cap program drop urtable
program define urtable, rclass
    version 14
    syntax varname(ts) [if] [in], ///
        [ Lags(integer -1)        ///
          Trend                   ///
          BGp(real 0.10)          ///
          RHOcap(real 0.97) ]

    marksample touse
    qui tsset
    local v `varlist'

    *--- Sample size and Schwert max-lag default -------------------------*
    qui count if `touse'
    local Tobs = r(N)
    if `lags' < 0 {
        local lags = floor(12 * (`Tobs'/100)^(1/4))
    }
    if `lags' < 1 {
        di as error "urtable: max lag must be >= 1; clamping to 1."
        local lags = 1
    }

    *--- Deterministic component and constants ---------------------------*
    if "`trend'" != "" {
        local trd       "trend"
        local mlab      "Constant + Trend"
        local cbar      = -13.5
        local kpss_c1  = 0.216
        local kpss_c5  = 0.146
        local kpss_c10 = 0.119
        local tau_c1   = -3.96
        local tau_c5   = -3.41
        local tau_c10  = -3.13
    }
    else {
        local trd       ""
        local mlab      "Constant"
        local cbar      = -7
        local kpss_c1  = 0.739
        local kpss_c5  = 0.463
        local kpss_c10 = 0.347
        local tau_c1   = -3.43
        local tau_c5   = -2.86
        local tau_c10  = -2.57
    }

    * Schwert max used to cap PP/KPSS bandwidths
    local _sw_max = floor(12 * (`Tobs'/100)^(1/4))

    *--- (1) ADF: general-to-specific lag selection via BG test ----------*
    * Procedure (Hall 1994 / Enders 2010):
    *   1) Schwert sets max lag (= lags() argument or default).
    *   2) For k = 0, 1, ..., lags, fit ADF on a common sample.
    *   3) Run Breusch-Godfrey on residuals at order max(4, k+1).
    *   4) Accept the smallest k whose BG p-value > bgp().
    *   5) Fallback: if no k yields clean residuals, use lags().
    tempvar tvar adfsmp
    qui gen double `tvar' = _n if `touse'

    * Determine the common sample (maxlag regression)
    if "`trend'" != "" {
        qui reg D.`v' L.`v' L(1/`lags').D.`v' `tvar' if `touse'
    }
    else {
        qui reg D.`v' L.`v' L(1/`lags').D.`v' if `touse'
    }
    qui gen byte `adfsmp' = e(sample)
    qui count if `adfsmp'
    local N_adfcom = r(N)

    tempname BGp_mat
    local adf_lag      = `lags'
    local adf_bg_p     = .
    local adf_bg_ord   = .
    local adf_selected = 0

    qui forvalues k = 0/`lags' {
        if "`trend'" != "" {
            if `k' == 0 {
                reg D.`v' L.`v' `tvar' if `adfsmp'
            }
            else {
                reg D.`v' L.`v' L(1/`k').D.`v' `tvar' if `adfsmp'
            }
        }
        else {
            if `k' == 0 {
                reg D.`v' L.`v' if `adfsmp'
            }
            else {
                reg D.`v' L.`v' L(1/`k').D.`v' if `adfsmp'
            }
        }
        local bg_ord = max(4, `k' + 1)
        capture estat bgodfrey, lags(`bg_ord')
        if !_rc {
            * estat bgodfrey stores r(p) as a 1x1 matrix for a single lag.
            * Defensive access: treat missing as no usable result.
            local pval = .
            capture {
                matrix `BGp_mat' = r(p)
                local pval = `BGp_mat'[1, 1]
            }
            if `pval' < . {
                if `pval' > `bgp' & `adf_selected' == 0 {
                    local adf_lag      = `k'
                    local adf_bg_p     = `pval'
                    local adf_bg_ord   = `bg_ord'
                    local adf_selected = 1
                    continue, break
                }
                * Keep last p-value in case no lag clears the threshold
                local adf_bg_p   = `pval'
                local adf_bg_ord = `bg_ord'
            }
        }
    }

    * Official stat and p-value from dfuller at the selected lag
    qui dfuller `v' if `touse', lags(`adf_lag') `trd'
    local adf_stat = r(Zt)
    local adf_p    = r(p)

    *--- (2) DF-GLS: manual GLS detrending + 3-criterion lag selection ---*
    local alpha = 1 + `cbar' / `Tobs'

    tempvar yqd zqd0 zqd1 trnd ystar dystar Lystar smpl
    qui {
        * Time variable for quasi-differencing and detrending
        gen double `trnd' = _n if `touse'

        * Quasi-differenced y: y_qd[1]=y[1]; y_qd[t]=y[t]-alpha*y[t-1] for t>=2
        gen double `yqd' = .
        replace `yqd' = `v' if _n == 1 & `touse'
        replace `yqd' = `v' - `alpha' * L.`v' if _n >= 2 & `touse'

        * Quasi-differenced constant (always present)
        gen double `zqd0' = .
        replace `zqd0' = 1 if _n == 1 & `touse'
        replace `zqd0' = 1 - `alpha' if _n >= 2 & `touse'

        if "`trend'" != "" {
            * Quasi-differenced trend
            gen double `zqd1' = .
            replace `zqd1' = 1 if _n == 1 & `touse'
            replace `zqd1' = `trnd' - `alpha' * (`trnd' - 1) if _n >= 2 & `touse'
            reg `yqd' `zqd0' `zqd1' if `touse', noconstant
            gen double `ystar' = `v' - _b[`zqd0'] - _b[`zqd1'] * `trnd' if `touse'
        }
        else {
            reg `yqd' `zqd0' if `touse', noconstant
            gen double `ystar' = `v' - _b[`zqd0'] if `touse'
        }

        gen double `dystar' = D.`ystar' if `touse'
        gen double `Lystar' = L.`ystar' if `touse'

        * Common sample from the maxlag regression on the detrended series
        reg `dystar' `Lystar' L(1/`lags').`dystar' if `touse', noconstant
        gen byte `smpl' = e(sample)
        count if `smpl'
        local Ncom = r(N)
    }

    * For each k = 0..lags, fit DF-GLS-type regression and compute criteria.
    * Matrix CR columns: [stat(DF-GLS), SC, MAIC, t-stat on last lag].
    * Row k+1 corresponds to lag k.
    tempname CR
    matrix `CR' = J(`lags' + 1, 4, .)

    qui forvalues k = 0/`lags' {
        if `k' == 0 {
            reg `dystar' `Lystar' if `smpl', noconstant
        }
        else {
            reg `dystar' `Lystar' L(1/`k').`dystar' if `smpl', noconstant
        }
        local rss    = e(rss)
        local sigma2 = `rss' / `Ncom'
        local stat   = _b[`Lystar'] / _se[`Lystar']
        local sc_k   = ln(`sigma2') + (`k' + 1) * ln(`Ncom') / `Ncom'

        * MAIC: tau_k = gamma^2 * sum(L.ystar^2) / sigma^2
        local gamma = _b[`Lystar']
        tempvar tmpsq
        gen double `tmpsq' = `Lystar'^2 if `smpl'
        sum `tmpsq' if `smpl', meanonly
        local sumLy2 = r(sum)
        drop `tmpsq'
        local tau_k  = `gamma'^2 * `sumLy2' / `sigma2'
        local maic_k = ln(`sigma2') + 2 * (`tau_k' + `k') / `Ncom'

        local tlast = .
        if `k' >= 1 {
            local tlast = _b[L`k'.`dystar'] / _se[L`k'.`dystar']
        }

        matrix `CR'[`k' + 1, 1] = `stat'
        matrix `CR'[`k' + 1, 2] = `sc_k'
        matrix `CR'[`k' + 1, 3] = `maic_k'
        matrix `CR'[`k' + 1, 4] = `tlast'
    }

    * ERS sequential-t: walk down from maxlag, pick first k with |t| > 1.645
    local ers_lag = 0
    forvalues k = `lags'(-1)1 {
        local tk = `CR'[`k' + 1, 4]
        if abs(`tk') > 1.645 {
            local ers_lag = `k'
            continue, break
        }
    }

    * Min SC and Min MAIC: argmin over k = 0..lags
    local sc_lag   = 0
    local maic_lag = 0
    local min_sc   = `CR'[1, 2]
    local min_mai  = `CR'[1, 3]
    forvalues k = 1/`lags' {
        local s = `CR'[`k' + 1, 2]
        local m = `CR'[`k' + 1, 3]
        if `s' < `min_sc' {
            local min_sc = `s'
            local sc_lag = `k'
        }
        if `m' < `min_mai' {
            local min_mai = `m'
            local maic_lag = `k'
        }
    }

    * DF-GLS critical values (ERS 1996, Table 1)
    if "`trend'" != "" {
        if `Tobs' < 75 {
            local dfgls_c1  = -3.77
            local dfgls_c5  = -3.19
            local dfgls_c10 = -2.89
        }
        else if `Tobs' < 150 {
            local dfgls_c1  = -3.58
            local dfgls_c5  = -3.03
            local dfgls_c10 = -2.74
        }
        else if `Tobs' < 300 {
            local dfgls_c1  = -3.46
            local dfgls_c5  = -2.93
            local dfgls_c10 = -2.64
        }
        else {
            local dfgls_c1  = -3.42
            local dfgls_c5  = -2.89
            local dfgls_c10 = -2.57
        }
    }
    else {
        * Constant-only: asymptotic CVs (weakly T-dependent)
        local dfgls_c1  = -2.59
        local dfgls_c5  = -1.94
        local dfgls_c10 = -1.62
    }

    * Pull stat and CVs for each criterion's selected lag
    foreach crit in ers sc maic {
        local L = ``crit'_lag'
        local dfgls_`crit'_stat = `CR'[`L' + 1, 1]
        local dfgls_`crit'_c1   = `dfgls_c1'
        local dfgls_`crit'_c5   = `dfgls_c5'
        local dfgls_`crit'_c10  = `dfgls_c10'
    }

    *--- (3) PP: Andrews (1991) bandwidth via helper ---------------------*
    tempvar pp_res
    if "`trend'" != "" {
        qui reg D.`v' `tvar' L.`v' if `touse'
    }
    else {
        qui reg D.`v' L.`v' if `touse'
    }
    qui predict double `pp_res' if `touse', resid

    qui _andrews_bw `pp_res', touse(`touse') tobs(`Tobs') ///
        rhocap(`rhocap') schwert(`_sw_max')
    local pp_rho    = r(rho)
    local pp_bw_raw = r(bw_raw)
    local pp_lag    = r(bw)

    qui pperron `v' if `touse', lags(`pp_lag') `trd'
    local pp_stat = r(Zt)
    local pp_p    = r(p)

    *--- (4) KPSS: Andrews (1991) bandwidth via helper -------------------*
    * Residuals from the level regression: y on const(+trend), not Delta-y.
    tempvar kpss_res_pre
    if "`trend'" != "" {
        qui reg `v' `tvar' if `touse'
    }
    else {
        qui reg `v' if `touse'
    }
    qui predict double `kpss_res_pre' if `touse', resid

    qui _andrews_bw `kpss_res_pre', touse(`touse') tobs(`Tobs') ///
        rhocap(`rhocap') schwert(`_sw_max')
    local kpss_rho    = r(rho)
    local kpss_bw_raw = r(bw_raw)
    local kpss_lag    = r(bw)

    * Manual KPSS statistic with Bartlett kernel at the chosen bandwidth
    tempvar res cumres cumsq resq trnd2
    qui {
        if "`trend'" != "" {
            gen double `trnd2' = _n if `touse'
            reg `v' `trnd2' if `touse'
        }
        else {
            reg `v' if `touse'
        }
        predict double `res' if `touse', resid
        count if !missing(`res') & `touse'
        local Tk = r(N)
        gen double `cumres' = sum(`res') if `touse'
        gen double `cumsq'  = `cumres'^2 if `touse'
        sum `cumsq' if `touse', meanonly
        local num = r(sum) / (`Tk'^2)
        gen double `resq' = `res'^2 if `touse'
        sum `resq' if `touse', meanonly
        local lrv = r(sum) / `Tk'
        forvalues j = 1/`kpss_lag' {
            tempvar rj
            gen double `rj' = `res' * L`j'.`res' if `touse'
            sum `rj' if `touse', meanonly
            local w = 1 - `j'/(`kpss_lag' + 1)
            local lrv = `lrv' + 2 * `w' * r(sum) / `Tk'
        }
        local kpss_stat = `num' / `lrv'
    }

    *--- Decision flags (Y = reject H0, . = fail to reject) --------------*
    foreach t in adf pp {
        local s = ``t'_stat'
        local `t'_r1  = cond(`s' < `tau_c1',  "Y", ".")
        local `t'_r5  = cond(`s' < `tau_c5',  "Y", ".")
        local `t'_r10 = cond(`s' < `tau_c10', "Y", ".")
    }
    foreach crit in ers sc maic {
        local s   = `dfgls_`crit'_stat'
        local dfgls_`crit'_r1  = cond(`s' < `dfgls_c1',  "Y", ".")
        local dfgls_`crit'_r5  = cond(`s' < `dfgls_c5',  "Y", ".")
        local dfgls_`crit'_r10 = cond(`s' < `dfgls_c10', "Y", ".")
    }
    local kpss_r1  = cond(`kpss_stat' > `kpss_c1',  "Y", ".")
    local kpss_r5  = cond(`kpss_stat' > `kpss_c5',  "Y", ".")
    local kpss_r10 = cond(`kpss_stat' > `kpss_c10', "Y", ".")

    *--- Joint interpretation at 5% level --------------------------------*
    local n_tau_total = 5
    local n_tau_rej   = 0
    foreach t in adf pp {
        if "``t'_r5'" == "Y" local n_tau_rej = `n_tau_rej' + 1
    }
    foreach crit in ers sc maic {
        if "`dfgls_`crit'_r5'" == "Y" local n_tau_rej = `n_tau_rej' + 1
    }
    local kpss_rej_5 = cond("`kpss_r5'" == "Y", 1, 0)
    local I0_lab     = cond("`trend'" != "", ///
        "TREND-STATIONARY (I(0) around a trend)", "STATIONARY (I(0))")

    if `n_tau_rej' >= 3 & `kpss_rej_5' == 0 {
        local v1 "Series appears `I0_lab'."
        local v2 "ADF/DF-GLS/PP reject H0 in `n_tau_rej'/`n_tau_total' tests; KPSS does not reject."
    }
    else if `n_tau_rej' <= 2 & `kpss_rej_5' == 1 {
        local v1 "Series appears NON-STATIONARY with a UNIT ROOT (I(1))."
        local v2 "ADF/DF-GLS/PP reject only `n_tau_rej'/`n_tau_total' tests; KPSS rejects stationarity."
    }
    else if `n_tau_rej' >= 3 & `kpss_rej_5' == 1 {
        local v1 "CONFLICTING: tau tests reject H0 AND KPSS also rejects."
        local v2 "Consider structural breaks, regime change, or fractional integration."
    }
    else {
        local v1 "INCONCLUSIVE: tau reject only `n_tau_rej'/`n_tau_total'; KPSS also fails to reject."
        local v2 "Tests have low power. Try larger T or alternative specification."
    }

    *--- Print results table (width = 84) --------------------------------*
    di as txt _n "{hline 84}"
    di as res "  Unit-root tests" ///
        as txt "    Series: " as res "`v'" ///
        as txt "    Model: " as res "`mlab'" ///
        as txt "    T: "     as res "`Tobs'"
    di as txt "{hline 84}"
    di as txt "  " %-18s "Test" %5s "Lag" %10s "Stat" ///
        %10s "CV(1%)" %10s "CV(5%)" %10s "CV(10%)" %12s "Rej 1/5/10"
    di as txt "{hline 84}"

    di as res "  " %-18s "ADF" %5.0f `adf_lag' %10.3f `adf_stat' ///
        %10.3f `tau_c1' %10.3f `tau_c5' %10.3f `tau_c10' ///
        "     `adf_r1'  `adf_r5'  `adf_r10'"

    foreach crit in ers maic sc {
        if "`crit'" == "ers"  local lbl "DF-GLS (ERS seq-t)"
        if "`crit'" == "maic" local lbl "DF-GLS (Min MAIC)"
        if "`crit'" == "sc"   local lbl "DF-GLS (Min SC)"
        di as res "  " %-18s "`lbl'" %5.0f ``crit'_lag' ///
            %10.3f `dfgls_`crit'_stat' ///
            %10.3f `dfgls_`crit'_c1' ///
            %10.3f `dfgls_`crit'_c5' ///
            %10.3f `dfgls_`crit'_c10' ///
            "     `dfgls_`crit'_r1'  `dfgls_`crit'_r5'  `dfgls_`crit'_r10'"
    }

    di as res "  " %-18s "PP" %5.0f `pp_lag' %10.3f `pp_stat' ///
        %10.3f `tau_c1' %10.3f `tau_c5' %10.3f `tau_c10' ///
        "     `pp_r1'  `pp_r5'  `pp_r10'"

    di as res "  " %-18s "KPSS" %5.0f `kpss_lag' %10.3f `kpss_stat' ///
        %10.3f `kpss_c1' %10.3f `kpss_c5' %10.3f `kpss_c10' ///
        "     `kpss_r1'  `kpss_r5'  `kpss_r10'"

    *--- Conclusion ------------------------------------------------------*
    di as txt "{hline 84}"
    di as res  "  Conclusion (5% level):"
    di as res  "    `v1'"
    di as res  "    `v2'"
    di as txt "{hline 84}"

    *--- Methodology notes -----------------------------------------------*
    di as txt "  H0 ADF/DF-GLS/PP: unit root.   H0 KPSS: series is stationary."
    di as txt "  'Y' = reject H0 at indicated level.   '.' = fail to reject."
    di as txt ""
    di as txt "  Lag selection (data-driven):"
    if `adf_selected' == 1 {
        di as txt "    ADF    : BG(`adf_bg_ord') p=" %4.3f `adf_bg_p' ///
            " at k=`adf_lag'  (general-to-specific via Breusch-Godfrey, threshold=`bgp')."
    }
    else if `adf_bg_p' < . {
        di as txt "    ADF    : BG never cleared p>`bgp' in [0,`lags']; fallback k=`lags'" ///
            " (last BG p=" %4.3f `adf_bg_p' ")."
    }
    else {
        di as txt "    ADF    : BG could not be evaluated; fallback k=`lags'."
    }
    di as txt "    DF-GLS : 3 criteria over [0,`lags']  (ERS seq-t, Min SC, Min MAIC)."
    di as txt "    PP     : Andrews (1991), rho=" %5.3f `pp_rho' ", BW=`pp_lag'."
    di as txt "    KPSS   : Andrews (1991), rho=" %5.3f `kpss_rho' ", BW=`kpss_lag'."
    di as txt "    (Andrews: AR(1) plug-in; |rho| capped at `rhocap'; BW capped at Schwert=`_sw_max'.)"
    di as txt ""
    di as txt "  CV sources: MacKinnon (ADF/PP), ERS 1996 (DF-GLS), KPSS 1992 (KPSS)."
    di as txt "{hline 84}" _n

    *--- Returned scalars and locals -------------------------------------*
    return scalar adf_stat         = `adf_stat'
    return scalar adf_p            = `adf_p'
    return scalar adf_lag          = `adf_lag'
    return scalar adf_bg_p         = `adf_bg_p'
    return scalar pp_stat          = `pp_stat'
    return scalar pp_p             = `pp_p'
    return scalar pp_lag           = `pp_lag'
    return scalar pp_rho           = `pp_rho'
    return scalar kpss_stat        = `kpss_stat'
    return scalar kpss_lag         = `kpss_lag'
    return scalar kpss_rho         = `kpss_rho'
    return scalar T                = `Tobs'
    return scalar Ncommon          = `Ncom'
    return scalar lags             = `lags'
    return scalar dfgls_ers_lag    = `ers_lag'
    return scalar dfgls_sc_lag     = `sc_lag'
    return scalar dfgls_maic_lag   = `maic_lag'
    return scalar dfgls_ers_stat   = `dfgls_ers_stat'
    return scalar dfgls_sc_stat    = `dfgls_sc_stat'
    return scalar dfgls_maic_stat  = `dfgls_maic_stat'
    return scalar n_tau_reject_5   = `n_tau_rej'
    return scalar kpss_reject_5    = `kpss_rej_5'
    return local  model            "`mlab'"
    return local  verdict          "`v1' `v2'"
end
