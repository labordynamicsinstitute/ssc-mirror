*! leestra 1.2.0  29apr2026  H. Ozan Eruygur (eruygur@gmail.com)
*! Lee-Strazicich Minimum LM Unit Root Test with Structural Breaks
*! Stata adaptation of Tom Doan's RATS @LSUnit procedure (Estima)
*! v1.2.0: Numerical stability - replaced sweep operator with QR-based OLS
*!         (handles large samples robustly); dy and lagged level computed
*!         from observation order to support tsset with calendar gaps;
*!         time-index gap warning printed at runtime; method(bg) BG warning
*!         now reports the lag at which autocorrelation persists; lags()
*!         default for method(bg) follows the kapetanios convention
*!         (floor(4*(T/100)^0.25), at least 1).
*! v1.1.0: Added Breusch-Godfrey-based lag selection (method(bg))
*
* References:
*   Schmidt & Phillips (1992)  - no break  (Oxford Bulletin of Econ. and Stat.)
*   Lee & Strazicich (2013)    - one break  (Economics Bulletin)
*   Lee & Strazicich (2003)    - two breaks (Review of Econ. and Statistics)
*
program define leestra, rclass
    version 14.0
    syntax varname(ts) [if] [in] , ///
        [ Model(string)            ///
          Breaks(integer 1)        ///
          Lags(integer -1)         ///
          METHod(string)           ///
          SLStay(real 0.10)        ///
          SIGnif(real -1)          ///
          BGLags(integer -1)       ///
          PI(real 0.10)            ///
          THIN(integer 1)          ///
          TItle(string)            ///
          NOPRint ]

    if "`model'" == "" local model "crash"
    if !inlist("`model'", "crash", "break") {
        di as err "model() must be either crash or break"
        exit 198
    }
    local mflag = cond("`model'"=="crash", 1, 2)

    if "`method'" == "" local method "gtos"
    if !inlist("`method'", "fixed", "gtos", "bg") {
        di as err "method() must be one of: fixed, gtos, bg"
        exit 198
    }
    if "`method'" == "fixed"      local mthflag = 1
    else if "`method'" == "gtos"  local mthflag = 2
    else if "`method'" == "bg"    local mthflag = 3

    if `breaks' < 0 {
        di as err "breaks() cannot be negative"
        exit 198
    }
    if `breaks' > 2 {
        di as err "breaks() must be 0, 1, or 2; critical values are not tabulated for more than two breaks"
        exit 198
    }
    * lags() unspecified is encoded as -1 (sentinel). Negative values otherwise = error.
    * Default value will be set after we know T (sample size).
    if `lags' < -1 {
        di as err "lags() cannot be negative"
        exit 198
    }
    if `pi' <= 0 | `pi' >= 0.5 {
        di as err "pi() must be in (0, 0.5)"
        exit 198
    }
    if `thin' < 1 {
        di as err "thin() must be at least 1"
        exit 198
    }

    local gtossig = cond(`signif' > 0, `signif', `slstay')

    cap tsset
    if _rc {
        di as err "data must be tsset before calling leestra"
        exit 198
    }
    local timevar `r(timevar)'
    local tdelta `r(tdelta)'
    local tsfmt `r(unit1)'

    * Detect time-index gaps. If gaps exist, warn the user; leestra works on
    * observation order, so it will run, but results may be misleading if the
    * data is genuinely irregularly sampled (rather than mislabelled).
    qui count if !missing(`varlist')
    local _nobs_v = r(N)
    qui sum `timevar' if !missing(`varlist')
    local _tspan = r(max) - r(min)
    if `tdelta' > 0 & `_nobs_v' > 1 {
        local _expected = (`_tspan' / `tdelta') + 1
        if abs(`_expected' - `_nobs_v') > 0.5 {
            di
            di as txt "Note: the time variable contains gaps. leestra treats consecutive"
            di as txt "      observations as one period apart, ignoring calendar gaps."
            di as txt "      If the data is genuinely irregularly sampled, results may"
            di as txt "      be misleading; verify the data layout before interpreting."
            di
        }
    }

    * BG horizon default depending on data frequency
    * (only used when method(bg))
    if `bglags' < 0 {
        if "`tsfmt'" == "yearly" | "`tsfmt'" == "y" {
            local bglags_use = 2
        }
        else if "`tsfmt'" == "halfyearly" | "`tsfmt'" == "h" {
            local bglags_use = 4
        }
        else if "`tsfmt'" == "quarterly" | "`tsfmt'" == "q" {
            local bglags_use = 8
        }
        else if "`tsfmt'" == "monthly" | "`tsfmt'" == "m" {
            local bglags_use = 24
        }
        else if "`tsfmt'" == "weekly" | "`tsfmt'" == "w" {
            local bglags_use = 52
        }
        else if "`tsfmt'" == "daily" | "`tsfmt'" == "d" {
            local bglags_use = 100
        }
        else {
            local bglags_use = 2
        }
    }
    else {
        local bglags_use = `bglags'
    }
    if `bglags_use' < 1 local bglags_use = 1

    marksample touse
    qui replace `touse' = 0 if missing(`varlist')
    qui count if `touse'
    if r(N) < 10 {
        di as err "not enough observations"
        exit 198
    }
    local Tobs = r(N)

    * Default lags() if unspecified:
    *   - method(fixed): 0 (RATS @LSUnit default)
    *   - method(gtos) and method(bg): floor(4*(T/100)^0.25), at least 1
    *     (so the data-driven methods have something to prune from)
    if `lags' == -1 {
        if `mthflag' == 1 {
            local lags = 0
        }
        else {
            local lags = floor(4 * (`Tobs'/100)^0.25)
            if `lags' < 1 local lags = 1
        }
    }

    * Minimum observations needed for the auxiliary regression:
    *   regression uses T - lags - 1 obs, with (1 + ndet + lags) regressors.
    *   ndet = model*breaks + 1.
    *   Require at least 5 residual degrees of freedom.
    local ndet_chk = `mflag' * `breaks' + 1
    local need_obs = 2 * `lags' + `ndet_chk' + 3 + 5
    if `Tobs' < `need_obs' {
        di as txt "lags(`lags') is too large for the available sample (T = `Tobs')."
        di as txt "       Auxiliary regression would have insufficient degrees of freedom."
        local max_lags_ok = floor((`Tobs' - `ndet_chk' - 3 - 5) / 2)
        if `max_lags_ok' < 0 local max_lags_ok = 0
        di as txt "       Try lags(`max_lags_ok') or smaller."
        exit 198
    }

    tempvar y t
    qui gen double `y' = `varlist' if `touse'

    qui gen long `t' = .
    qui replace `t' = sum(`touse') if `touse'

    * Note: dy and lagy are computed inside Mata using the observation order
    * (touse-filtered), not the time index. This makes leestra robust to
    * datasets where tsset reports gaps (e.g. weekly data sampled every k
    * weeks), where D.varlist would otherwise return all-missing.
    mata: leestra_main("`y'", "`y'", "`y'", "`t'", "`touse'", `mflag', `breaks', `lags', `mthflag', `gtossig', `pi', `thin', `bglags_use')

    local tstat   = r(tstat)
    local nobs    = r(nobs)
    local bestlag = r(bestlag)
    local ndf     = r(ndf)
    local ncomb   = r(ncomb)
    local use_lag = r(use_lag)
    local bg_chi2     = r(bg_chi2)
    local bg_p        = r(bg_p)
    local bg_minp     = r(bg_minp)
    local bg_minplag  = r(bg_minplag)
    local bg_minpchi2 = r(bg_minpchi2)
    local bg_warn     = r(bg_warn)
    * Replace missing values with sentinels for non-bg methods
    if "`bg_chi2'" == "."     local bg_chi2     = -1
    if "`bg_p'" == "."        local bg_p        = -1
    if "`bg_minp'" == "."     local bg_minp     = -1
    if "`bg_minplag'" == "."  local bg_minplag  = 0
    if "`bg_minpchi2'" == "." local bg_minpchi2 = -1
    if "`bg_warn'" == "."     local bg_warn     = 0
    matrix b      = r(beta)
    matrix tt     = r(tstats)
    matrix bps    = r(bps)
    matrix cv     = r(cv)
    local lambda1 = r(lambda1)
    local lambda2 = r(lambda2)

    if "`title'" == "" {
        local title "Lee-Strazicich Unit Root Test, Series `varlist'"
    }

    if "`noprint'" == "" {
        leestra_display, title(`"`title'"') model(`mflag') breaks(`breaks') method(`mthflag') lags(`lags') uselag(`use_lag') bestlag(`bestlag') nobs(`nobs') tstat(`tstat') beta(b) tstats(tt) cv(cv) varname(`varlist') timevar(`timevar') t(`t') bps(bps) bgchi2(`bg_chi2') bgp(`bg_p') bgminp(`bg_minp') bgminplag(`bg_minplag') bgminpchi2(`bg_minpchi2') bgwarn(`bg_warn') bglagsmax(`bglags_use')
    }

    return scalar tstat   = `tstat'
    return scalar nobs    = `nobs'
    return scalar bestlag = `bestlag'
    return scalar ndf     = `ndf'
    return scalar breaks  = `breaks'
    return scalar model   = `mflag'
    return scalar lambda1 = `lambda1'
    return scalar lambda2 = `lambda2'
    return scalar ncomb   = `ncomb'
    if `mthflag' == 3 {
        return scalar bg_chi2 = `bg_chi2'
        return scalar bg_p    = `bg_p'
        return scalar bg_minp = `bg_minp'
        return scalar bg_warn = `bg_warn'
    }
    return matrix beta    = b
    return matrix tstats  = tt
    return matrix bps     = bps
    return matrix cv      = cv
    return local  varname `varlist'
end


*--------------------------------------------------------------------
* Display helper
*--------------------------------------------------------------------
program define leestra_display
    version 14.0
    syntax , title(string) model(integer) breaks(integer) method(integer) lags(integer) uselag(integer) bestlag(integer) nobs(integer) tstat(real) beta(name) tstats(name) cv(name) varname(string) timevar(string) t(string) bps(name) [ bgchi2(real -1) bgp(real -1) bgminp(real -1) bgminplag(integer 0) bgminpchi2(real -1) bgwarn(integer 0) bglagsmax(integer 0) ]

    di
    di as txt "{hline 65}"
    di as res "  `title'"
    di as txt "{hline 65}"

    if `breaks' == 0 {
        di as txt "  Test:        " as res "Schmidt-Phillips LM (no break)"
    }
    else {
        local mdesc = cond(`model'==1, "Crash Model (level shift only)", "Trend Break Model (level + trend shift)")
        di as txt "  Test:        " as res "Lee-Strazicich (`breaks' break(s))"
        di as txt "  Model:       " as res "`mdesc'"
    }

    if `method' == 1 {
        di as txt "  Lags:        " as res "fixed, lags = `lags'"
    }
    else if `method' == 2 {
        di as txt "  Lags:        " as res "GTOS chose `bestlag' (max `lags')"
    }
    else {
        di as txt "  Lags:        " as res "BG chose `bestlag' (max `lags')"
    }
    di as txt "  Obs:         " as res `nobs'

    * Regression range: relative t = uselag+2 .. T (in the touse sample)
    local t_start = `uselag' + 2
    local t_end   = `nobs' + `uselag' + 1
    qui sum `timevar' if `t' == `t_start', meanonly
    local d_start = r(mean)
    qui sum `timevar' if `t' == `t_end', meanonly
    local d_end   = r(mean)
    cap local fmt : format `timevar'
    if "`fmt'" == "" local fmt "%9.0g"
    local tag_s = string(`d_start', "`fmt'")
    local tag_e = string(`d_end',   "`fmt'")
    di as txt "  Range:       " as res "`tag_s' to `tag_e'"

    forvalues i = 1/`breaks' {
        local pos = `bps'[1, `i']
        qui sum `timevar' if `t' == `pos', meanonly
        local bd = r(mean)
        cap local fmt : format `timevar'
        if "`fmt'" == "" local fmt "%9.0g"
        local tag = string(`bd', "`fmt'")
        di as txt "  Break `i':     " as res "`tag'" as txt "  (t = " as res `pos' as txt ")"
    }

    di as txt "{hline 65}"
    di as txt "  Test statistic:   " as res %9.4f `tstat'
    di as txt
    di as txt "  Critical values:"
    di as txt "    1%:    " as res %9.4f `cv'[1,1]
    di as txt "    5%:    " as res %9.4f `cv'[1,2]
    di as txt "    10%:   " as res %9.4f `cv'[1,3]
    di as txt "{hline 65}"

    local decision "Cannot reject H0 (unit root present)"
    if `tstat' < `cv'[1,1]      local decision "Reject H0 at 1% (no unit root)"
    else if `tstat' < `cv'[1,2] local decision "Reject H0 at 5% (no unit root)"
    else if `tstat' < `cv'[1,3] local decision "Reject H0 at 10% (no unit root)"
    di as txt "  Decision: " as res "`decision'"
    di as txt "{hline 65}"

    di as txt
    di as txt "  Auxiliary regression coefficients (S(t-1) is the unit root coefficient):"
    di as txt "  {hline 50}"
    di as txt %-15s "Variable" "  " %12s "Coef" "  " %10s "t-stat"
    di as txt "  {hline 50}"
    di as txt %-15s "S(t-1)" "  " %12.6f `beta'[1,1] "  " %10.4f `tstats'[1,1]
    di as txt %-15s "Const" "  " %12.6f `beta'[1,2] "  " %10.4f `tstats'[1,2]
    forvalues i = 1/`breaks' {
        local row = `model' * (`i' - 1) + 3
        local pos = `bps'[1, `i']
        qui sum `timevar' if `t' == `pos', meanonly
        local bd = r(mean)
        cap local fmt : format `timevar'
        if "`fmt'" == "" local fmt "%9.0g"
        local tag = string(`bd', "`fmt'")
        di as txt %-15s "D(`tag')" "  " %12.6f `beta'[1,`row'] "  " %10.4f `tstats'[1,`row']
        if `model' == 2 {
            local row2 = `row' + 1
            di as txt %-15s "DT(`tag')" "  " %12.6f `beta'[1,`row2'] "  " %10.4f `tstats'[1,`row2']
        }
    }
    di as txt "  {hline 50}"

    * BG diagnostics (only for method(bg))
    if `method' == 3 & `bgp' >= 0 {
        di as txt
        di as txt "  Breusch-Godfrey LM test for autocorrelation in auxiliary regression:"
        di as txt "  {hline 50}"
        di as txt %-15s "Test" "  " %12s "chi2" "  " %10s "p-value"
        di as txt "  {hline 50}"
        di as txt %-15s "AR(1)" "  " %12.4f `bgchi2' "  " %10.4f `bgp'
        di as txt "  {hline 50}"
        if `bgwarn' == 1 {
            local next_lag = `lags' + 1
            local minp_str : di %5.4f `bgminp'
            di
            di as err "  Warning: Autocorrelation detected at lag `bgminplag' (BG p = `minp_str')."
            di as err "           lags = `lags' was insufficient. Try lags(`next_lag') or higher."
            di as err "           Results should be interpreted with caution."
        }
        else {
            di as txt "  Tested for autocorrelation up to lag `bglagsmax' (BG); none detected."
        }
    }
end


*--------------------------------------------------------------------
* Mata: main computation engine
*--------------------------------------------------------------------
version 14.0
mata:
mata set matastrict off

real rowvector leestra_nlookup()
{
    real rowvector v
    v = (100, 250, 500, 1000)
    return(v)
}

// No break (Schmidt-Phillips)
real matrix leestra_cv0()
{
    real matrix M
    M = J(4, 3, .)
    M[1,1] = -3.597; M[1,2] = -3.031; M[1,3] = -2.745
    M[2,1] = -3.572; M[2,2] = -3.023; M[2,3] = -2.747
    M[3,1] = -3.570; M[3,2] = -3.021; M[3,3] = -2.748
    M[4,1] = -3.566; M[4,2] = -3.023; M[4,3] = -2.748
    return(M)
}

// One break, MODEL=crash
real matrix leestra_cvc1()
{
    real matrix M
    M = J(4, 3, .)
    M[1,1] = -4.084; M[1,2] = -3.487; M[1,3] = -3.185
    M[2,1] = -3.987; M[2,2] = -3.387; M[2,3] = -3.076
    M[3,1] = -3.840; M[3,2] = -3.277; M[3,3] = -2.985
    M[4,1] = -3.798; M[4,2] = -3.230; M[4,3] = -2.925
    return(M)
}

// Two breaks, MODEL=crash
real matrix leestra_cvc2()
{
    real matrix M
    M = J(4, 3, .)
    M[1,1] = -4.073; M[1,2] = -3.563; M[1,3] = -3.296
    M[2,1] = -4.101; M[2,2] = -3.594; M[2,3] = -3.345
    M[3,1] = -4.261; M[3,2] = -3.647; M[3,3] = -3.287
    M[4,1] = -3.828; M[4,2] = -3.248; M[4,3] = -3.005
    return(M)
}

// One break, MODEL=break: 4 sample sizes x 9 lambda values = 36 rows
real matrix leestra_cvb1()
{
    real matrix M
    M = J(36, 3, .)
    M[1,1]=-4.630; M[1,2]=-4.064; M[1,3]=-3.787
    M[2,1]=-4.704; M[2,2]=-4.132; M[2,3]=-3.843
    M[3,1]=-4.769; M[3,2]=-4.199; M[3,3]=-3.906
    M[4,1]=-4.820; M[4,2]=-4.253; M[4,3]=-3.963
    M[5,1]=-4.857; M[5,2]=-4.293; M[5,3]=-4.008
    M[6,1]=-4.891; M[6,2]=-4.324; M[6,3]=-4.042
    M[7,1]=-4.899; M[7,2]=-4.338; M[7,3]=-4.058
    M[8,1]=-4.910; M[8,2]=-4.348; M[8,3]=-4.071
    M[9,1]=-4.915; M[9,2]=-4.351; M[9,3]=-4.073
    M[10,1]=-4.523; M[10,2]=-3.974; M[10,3]=-3.697
    M[11,1]=-4.536; M[11,2]=-3.982; M[11,3]=-3.702
    M[12,1]=-4.563; M[12,2]=-4.010; M[12,3]=-3.726
    M[13,1]=-4.609; M[13,2]=-4.060; M[13,3]=-3.777
    M[14,1]=-4.647; M[14,2]=-4.098; M[14,3]=-3.819
    M[15,1]=-4.667; M[15,2]=-4.125; M[15,3]=-3.846
    M[16,1]=-4.672; M[16,2]=-4.130; M[16,3]=-3.856
    M[17,1]=-4.681; M[17,2]=-4.144; M[17,3]=-3.870
    M[18,1]=-4.685; M[18,2]=-4.145; M[18,3]=-3.873
    M[19,1]=-4.502; M[19,2]=-3.959; M[19,3]=-3.679
    M[20,1]=-4.489; M[20,2]=-3.944; M[20,3]=-3.664
    M[21,1]=-4.496; M[21,2]=-3.950; M[21,3]=-3.671
    M[22,1]=-4.534; M[22,2]=-3.991; M[22,3]=-3.714
    M[23,1]=-4.570; M[23,2]=-4.031; M[23,3]=-3.756
    M[24,1]=-4.587; M[24,2]=-4.052; M[24,3]=-3.777
    M[25,1]=-4.598; M[25,2]=-4.065; M[25,3]=-3.794
    M[26,1]=-4.612; M[26,2]=-4.081; M[26,3]=-3.809
    M[27,1]=-4.602; M[27,2]=-4.074; M[27,3]=-3.799
    M[28,1]=-4.466; M[28,2]=-3.928; M[28,3]=-3.651
    M[29,1]=-4.455; M[29,2]=-3.919; M[29,3]=-3.640
    M[30,1]=-4.469; M[30,2]=-3.933; M[30,3]=-3.651
    M[31,1]=-4.501; M[31,2]=-3.968; M[31,3]=-3.687
    M[32,1]=-4.523; M[32,2]=-3.993; M[32,3]=-3.713
    M[33,1]=-4.546; M[33,2]=-4.018; M[33,3]=-3.740
    M[34,1]=-4.562; M[34,2]=-4.033; M[34,3]=-3.756
    M[35,1]=-4.576; M[35,2]=-4.049; M[35,3]=-3.773
    M[36,1]=-4.593; M[36,2]=-4.065; M[36,3]=-3.790
    return(M)
}

// Two breaks, MODEL=break: 4 sample sizes x 12 rows = 48 rows
real matrix leestra_cvb2()
{
    real matrix M
    M = J(48, 3, .)
    M[1,1]=-6.750; M[1,2]=-6.108; M[1,3]=-5.779
    M[2,1]=-7.196; M[2,2]=-6.312; M[2,3]=-5.893
    M[3,1]=-6.932; M[3,2]=-6.175; M[3,3]=-5.825
    M[4,1]=-7.004; M[4,2]=-6.185; M[4,3]=-5.828
    M[5,1]=-6.691; M[5,2]=-6.152; M[5,3]=-5.798
    M[6,1]=-6.821; M[6,2]=-5.917; M[6,3]=-5.541
    M[7,1]=-6.963; M[7,2]=-6.201; M[7,3]=-5.890
    M[8,1]=-6.821; M[8,2]=-6.166; M[8,3]=-5.832
    M[9,1]=-6.978; M[9,2]=-6.288; M[9,3]=-5.998
    M[10,1]=-7.032; M[10,2]=-6.375; M[10,3]=-6.011
    M[11,1]=-6.863; M[11,2]=-6.268; M[11,3]=-5.956
    M[12,1]=-7.014; M[12,2]=-6.446; M[12,3]=-6.072
    M[13,1]=-5.667; M[13,2]=-5.177; M[13,3]=-4.921
    M[14,1]=-5.974; M[14,2]=-5.342; M[14,3]=-5.004
    M[15,1]=-5.869; M[15,2]=-5.398; M[15,3]=-5.112
    M[16,1]=-6.064; M[16,2]=-5.462; M[16,3]=-5.192
    M[17,1]=-5.957; M[17,2]=-5.374; M[17,3]=-5.104
    M[18,1]=-5.783; M[18,2]=-5.272; M[18,3]=-4.943
    M[19,1]=-5.934; M[19,2]=-5.300; M[19,3]=-4.988
    M[20,1]=-5.771; M[20,2]=-5.357; M[20,3]=-5.032
    M[21,1]=-5.958; M[21,2]=-5.421; M[21,3]=-5.179
    M[22,1]=-5.751; M[22,2]=-5.349; M[22,3]=-5.063
    M[23,1]=-5.971; M[23,2]=-5.264; M[23,3]=-5.018
    M[24,1]=-6.035; M[24,2]=-5.484; M[24,3]=-5.161
    M[25,1]=-5.640; M[25,2]=-4.855; M[25,3]=-4.572
    M[26,1]=-5.392; M[26,2]=-4.939; M[26,3]=-4.691
    M[27,1]=-5.608; M[27,2]=-4.947; M[27,3]=-4.661
    M[28,1]=-5.602; M[28,2]=-5.059; M[28,3]=-4.782
    M[29,1]=-5.533; M[29,2]=-4.989; M[29,3]=-4.752
    M[30,1]=-5.619; M[30,2]=-5.038; M[30,3]=-4.723
    M[31,1]=-5.511; M[31,2]=-4.898; M[31,3]=-4.607
    M[32,1]=-5.494; M[32,2]=-5.035; M[32,3]=-4.742
    M[33,1]=-5.548; M[33,2]=-5.043; M[33,3]=-4.811
    M[34,1]=-5.716; M[34,2]=-5.149; M[34,3]=-4.912
    M[35,1]=-5.509; M[35,2]=-4.963; M[35,3]=-4.674
    M[36,1]=-5.655; M[36,2]=-4.967; M[36,3]=-4.705
    M[37,1]=-5.116; M[37,2]=-4.539; M[37,3]=-4.195
    M[38,1]=-5.240; M[38,2]=-4.578; M[38,3]=-4.278
    M[39,1]=-5.437; M[39,2]=-4.917; M[39,3]=-4.533
    M[40,1]=-5.387; M[40,2]=-4.884; M[40,3]=-4.567
    M[41,1]=-5.099; M[41,2]=-4.716; M[41,3]=-4.481
    M[42,1]=-5.247; M[42,2]=-4.776; M[42,3]=-4.472
    M[43,1]=-5.085; M[43,2]=-4.576; M[43,3]=-4.301
    M[44,1]=-5.209; M[44,2]=-4.697; M[44,3]=-4.398
    M[45,1]=-5.212; M[45,2]=-4.734; M[45,3]=-4.534
    M[46,1]=-5.183; M[46,2]=-4.773; M[46,3]=-4.535
    M[47,1]=-5.100; M[47,2]=-4.699; M[47,3]=-4.364
    M[48,1]=-5.291; M[48,2]=-4.803; M[48,3]=-4.481
    return(M)
}

// Sweep operator (Goodnight 1979) - retained for compatibility but no longer
// used in the main computation; numerically unstable in large samples.
real matrix leestra_sweep(real matrix A, real scalar k)
{
    real matrix B
    real scalar n, i, j, d
    n = rows(A)
    B = A
    d = B[k,k]
    if (abs(d) < 1e-14) return(A)
    for (i=1; i<=n; i++) {
        if (i == k) continue
        for (j=1; j<=n; j++) {
            if (j == k) continue
            B[i,j] = A[i,j] - A[i,k]*A[k,j]/d
        }
    }
    for (j=1; j<=n; j++) {
        if (j != k) B[k,j] = A[k,j]/d
    }
    for (i=1; i<=n; i++) {
        if (i != k) B[i,k] = -A[i,k]/d
    }
    B[k,k] = 1/d
    return(B)
}

//
// OLS-based replacement for sweep: takes the design matrix X (column 1 is
// the dependent variable, columns 2..ncols are regressors), runs OLS, and
// returns a matrix in the same format as the swept cross-product matrix:
//
//   bestxx[1,1]       = SSE (residual sum of squares)
//   bestxx[i+1, 1]    = beta[i]            for i = 1..(ncols-1)
//   bestxx[i+1, i+1]  = invCM[i+1, i+1]    for i = 1..(ncols-1)
//
// Only the elements actually used downstream are filled (other entries
// remain zero). Returns J(ncols, ncols, 0) on failure (singular CM).
//
real matrix leestra_ols_xx(real matrix X, real scalar ncols)
{
    real matrix Xr, CMr, invCMr, out
    real colvector y, beta, resid
    real scalar i, sse

    out = J(ncols, ncols, 0)
    if (rows(X) < ncols) return(out)

    y  = X[., 1]
    Xr = X[., 2..ncols]
    CMr = quadcross(Xr, Xr)
    invCMr = qrinv(CMr)
    beta  = invCMr * quadcross(Xr, y)
    resid = y - Xr * beta
    sse   = quadcross(resid, resid)

    out[1,1] = sse
    for (i=1; i<=cols(Xr); i++) {
        out[i+1, 1]    = beta[i]
        out[i+1, i+1] = invCMr[i, i]
    }
    return(out)
}

// GTOS lag pruning (OLS-based). Drops the highest ds lag whenever its
// t-statistic falls below the slstay critical value. Updates the sweepxx
// view (in OLS-xx format) to match the chosen lag count on exit.
//
// X       : full design matrix (col 1 = dy, cols 2..mxcols = regressors)
// mxcols  : total number of cols of X (= 1 + ndet + 1 + lags)
// lags    : maximum lag count (ds_1 .. ds_lags occupy cols mxcols-lags+1..mxcols)
// slstay  : significance level
// nbase   : ndet
// Returns the chosen number of lags; sweepxx is updated to match.
//
real scalar leestra_gtos(real matrix sweepxx, real matrix X, real scalar mxcols,
                         real scalar lags, real scalar slstay, real scalar nbase)
{
    real scalar testlag, ndf, marg_t, crit, lagsused, ncur, slot
    real matrix Xc, CMr, invCMr, Xr
    real colvector beta, resid, y
    real scalar sse, i_g

    lagsused = 0
    for (testlag=lags; testlag>=1; testlag--) {
        // Current model uses cols 1 .. (nbase+2+testlag) of X
        ncur = nbase + 2 + testlag
        if (ncur > mxcols) continue
        ndf = rows(X) - testlag - (nbase + 1)
        if (ndf <= 0) continue

        // OLS on cols 2..ncur
        y    = X[., 1]
        Xr   = X[., 2..ncur]
        CMr  = quadcross(Xr, Xr)
        invCMr = qrinv(CMr)
        beta  = invCMr * quadcross(Xr, y)
        resid = y - Xr * beta
        sse   = quadcross(resid, resid)

        // The last column of Xr is ds(testlag) - check its t-stat
        slot = cols(Xr)
        marg_t = abs(beta[slot]) / sqrt(sse * invCMr[slot, slot] / ndf)
        crit   = invttail(ndf, slstay/2)
        if (marg_t > crit) {
            lagsused = testlag
            // Fill sweepxx with the OLS results in sweep-xx format
            sweepxx[1, 1] = sse
            for (i_g=1; i_g<=cols(Xr); i_g++) {
                sweepxx[i_g+1, 1]    = beta[i_g]
                sweepxx[i_g+1, i_g+1] = invCMr[i_g, i_g]
            }
            return(lagsused)
        }
    }
    // No lag was significant; fit the model with no lags
    ncur = nbase + 2
    y    = X[., 1]
    Xr   = X[., 2..ncur]
    CMr  = quadcross(Xr, Xr)
    invCMr = qrinv(CMr)
    beta   = invCMr * quadcross(Xr, y)
    resid  = y - Xr * beta
    sse    = quadcross(resid, resid)
    sweepxx[1,1] = sse
    for (i_g=1; i_g<=cols(Xr); i_g++) {
        sweepxx[i_g+1, 1]      = beta[i_g]
        sweepxx[i_g+1, i_g+1] = invCMr[i_g, i_g]
    }
    return(0)
}

//
// Breusch-Godfrey LM test on the auxiliary regression with nomiss0=off
// (i.e. matches Stata's "estat bgodfrey, lags(p) nomiss0":
// initial p observations on lagged residuals are dropped).
//
// X: design matrix where column 1 is dy, columns 2..ncols are the regressors
//    (S(t-1), constant, DT dummies, ds lags). nrows = number of obs in regr.
// p: BG test lag order
// Returns p-value (chi^2(p) on n_aux * R^2). Returns 1 if not enough obs.
//
real scalar leestra_bg_pvalue(real matrix X, real scalar ncols, real scalar p)
{
    real scalar n, k, n_aux, j, i
    real colvector y, e, e_aux, resid_aux
    real matrix Xr, Xaux, lags_mat
    real scalar tss, rss, r2, lm

    n = rows(X)
    if (n - p <= ncols) return(1)

    Xr = X[., 2..ncols]
    y  = X[., 1]
    k  = cols(Xr)

    // Step 1: original OLS to get residuals
    e = y - Xr * (invsym(quadcross(Xr,Xr)) * quadcross(Xr,y))

    // Step 2: build auxiliary regression matrix with nomiss0 behaviour:
    // drop first p observations. Auxiliary X: original Xr (rows p+1..n) plus
    // lagged residuals e[t-1], e[t-2], ..., e[t-p].
    n_aux = n - p
    lags_mat = J(n_aux, p, .)
    for (j=1; j<=p; j++) {
        lags_mat[., j] = e[(p+1-j) :: (n-j)]
    }
    Xaux  = Xr[(p+1)::n, .], lags_mat
    e_aux = e[(p+1)::n]

    // Step 3: OLS of e_aux on Xaux, compute R^2
    resid_aux = e_aux - Xaux * (invsym(quadcross(Xaux,Xaux)) * quadcross(Xaux,e_aux))
    tss = quadcross(e_aux :- mean(e_aux), e_aux :- mean(e_aux))
    rss = quadcross(resid_aux, resid_aux)
    if (tss <= 0) return(1)
    r2 = 1 - rss/tss
    if (r2 < 0) r2 = 0
    lm = n_aux * r2
    return(chi2tail(p, lm))
}

//
// BG-based lag selection (mirrors the Kapetanios (2005) Stata implementation):
//   K = kmax, kmax-1, ..., 0.
//   At each K, compute the auxiliary regression with K ds-lags, run BG tests
//   at lag orders 1..bglags, take the minimum p-value.
//   If min_p < 0.05 (autocorrelation present): bg_ksel = Kprev; stop.
//   Else: Kprev = K; continue.
//   If no K is autocorrelation-free, bg_ksel = 0.
//
// On entry, X is the full design matrix (mxcols cols) including all lag
// columns. ncols0 = nbcols (= ndet+2) is the number of "base" columns
// before any ds-lag columns.
// Returns the selected lag count.
//
real scalar leestra_bg_select(real matrix X, real scalar mxcols, real scalar ncols0, real scalar lags, real scalar bglags)
{
    real scalar K, Kprev, found, bg_ksel, ncols_K, lag, minp, p
    real matrix Xk

    bg_ksel = 0
    Kprev   = lags
    found   = 0

    for (K=lags; K>=0; K--) {
        if (found) continue
        ncols_K = ncols0 + K
        if (ncols_K > mxcols) continue
        Xk = X[., 1..ncols_K]

        // Compute min p-value across BG lag orders 1..bglags
        minp = 1
        for (lag=1; lag<=bglags; lag++) {
            p = leestra_bg_pvalue(Xk, ncols_K, lag)
            if (p < minp) minp = p
        }

        if (minp < 0.05) {
            bg_ksel = Kprev
            found   = 1
        }
        else {
            Kprev = K
        }
    }

    if (!found) bg_ksel = 0
    return(bg_ksel)
}

// Linear interpolation in T direction
real rowvector leestra_interp_T(real matrix tab, real scalar tnobs)
{
    real rowvector nl, cv
    real scalar i, t1, t2, tw1, tw2
    nl = leestra_nlookup()
    t1 = cols(nl); t2 = t1; tw1 = 1; tw2 = 0
    for (i=1; i<=cols(nl); i++) {
        if (tnobs < nl[i]) {
            if (i == 1) {
                t1 = 1; t2 = 1; tw1 = 1; tw2 = 0
            }
            else {
                tw1 = (tnobs - nl[i-1]) / (nl[i] - nl[i-1])
                t1  = i-1
                tw2 = 1 - tw1
                t2  = i
            }
            break
        }
    }
    cv = tw1 * tab[t1,.] + tw2 * tab[t2,.]
    return(cv)
}

// One break, break model
real rowvector leestra_interp_cvb1(real scalar lambda, real scalar tnobs)
{
    real rowvector bp, nl, cv
    real scalar i, i1, i2, w1, w2, lam, off
    real matrix M, cv1
    bp = (.10, .15, .20, .25, .30, .35, .40, .45, .50)
    nl = leestra_nlookup()
    M  = leestra_cvb1()
    lam = lambda
    if (lam > 0.5) lam = 1 - lam
    i1 = 1; i2 = 1; w1 = 1; w2 = 0
    if (lam <= bp[1]) {
        i1 = 1; i2 = 1; w1 = 1; w2 = 0
    }
    else if (lam >= bp[cols(bp)]) {
        i1 = cols(bp); i2 = i1; w1 = 1; w2 = 0
    }
    else {
        for (i=2; i<=cols(bp); i++) {
            if (lam < bp[i]) {
                w2 = (lam - bp[i-1]) / (bp[i] - bp[i-1])
                w1 = 1 - w2
                i1 = i-1
                i2 = i
                break
            }
        }
    }
    cv1 = J(cols(nl), 3, .)
    for (i=1; i<=cols(nl); i++) {
        off = (i-1)*9
        cv1[i,.] = w1 * M[off+i1,.] + w2 * M[off+i2,.]
    }
    cv = leestra_interp_T(cv1, tnobs)
    return(cv)
}

// Two breaks, break model
real rowvector leestra_interp_cvb2(real scalar lam1, real scalar lam2, real scalar tnobs)
{
    real rowvector bp, nl, cv
    real scalar i, i1, i2, lambda1, lambda2, temp, idx, off, b1, b2
    real matrix M, cv1
    bp = (.20, .30, .40, .50, .60, .70, .80)
    nl = leestra_nlookup()
    M  = leestra_cvb2()

    lambda1 = lam1
    lambda2 = lam2
    if (lambda1 + lambda2 >= 1.0) {
        temp    = lambda1
        lambda1 = 1 - lambda2
        lambda2 = 1 - temp
    }

    b1 = 1; b2 = 1; i1 = 1; i2 = 1
    for (i=1; i<=cols(bp); i++) {
        if (abs(lambda1 - bp[i]) < b1) {
            i1 = i
            b1 = abs(lambda1 - bp[i])
        }
        if (abs(lambda2 - bp[i]) < b2) {
            i2 = i
            b2 = abs(lambda2 - bp[i])
        }
    }
    if (i1 == i2) {
        if (i1 == 1) {
            i2 = i1 + 1
        }
        else if (i1 == cols(bp)) {
            i1 = i2 - 1
        }
        else if ((lambda1 - bp[i1]) + (lambda2 - bp[i2]) > 0) {
            i2 = i1 + 1
        }
        else {
            i1 = i2 - 1
        }
    }

    idx = (cols(bp) - i1) * (i1 - 1) + i2 - 1
    if (idx < 1)  idx = 1
    if (idx > 12) idx = 12

    cv1 = J(cols(nl), 3, .)
    for (i=1; i<=cols(nl); i++) {
        off = (i-1)*12
        cv1[i,.] = M[off+idx,.]
    }
    cv = leestra_interp_T(cv1, tnobs)
    return(cv)
}

// Advance grid to next break combination
real scalar leestra_advance(real matrix bps, real matrix ub, real scalar breaks, real scalar pinobs, real scalar thin)
{
    real scalar i, j, done
    if (breaks == 0) return(1)
    done = 1
    for (i=breaks; i>=1; i--) {
        bps[i] = bps[i] + thin
        if (bps[i] >= ub[i]) continue
        for (j=i+1; j<=breaks; j++) {
            bps[j] = bps[j-1] + pinobs
        }
        done = 0
        break
    }
    return(done)
}

//
// Main engine
//
void leestra_main(string scalar yvar, string scalar dyvar, string scalar lyvar, string scalar tvar, string scalar tousevar, real scalar model, real scalar breaks, real scalar lags, real scalar method, real scalar slstay, real scalar pi, real scalar thin, real scalar bglags)
{
    real colvector y, dy, ly, tt
    real scalar T, lower, upper, pinobs, ndet
    real scalar i, j, k, done, ndf
    real scalar nbcols, mxcols, Nr
    real scalar mint, tstat, bestlag, lagsused
    real scalar lambda1, lambda2
    real scalar Nuse, ndf2
    real scalar nout, ncomb, last1, showdots
    real matrix bps, ub, bestbreaks
    real matrix DT, X, Mr
    real matrix sweepxx, bestxx, CM
    real colvector resid, stilde, ds
    real rowvector bestcoef, besttstats, cv

    st_view(y=.,  ., yvar,  tousevar)
    st_view(tt=., ., tvar,  tousevar)

    T = rows(y)

    // dy and ly are computed here from the observation ordering (touse-filtered),
    // not from D./L. operators. This avoids issues when tsset reports gaps but
    // the observations are still in sequence (e.g. weekly data sampled every
    // k weeks).
    dy    = J(T, 1, .)
    ly    = J(T, 1, .)
    if (T > 1) {
        dy[2..T] = y[2..T] - y[1..(T-1)]
        ly[2..T] = y[1..(T-1)]
    }

    // RATS satir 315: compute lower=startl+lags+1
    // RATS startl = ilk gecerli entry (lrgnp icin 1909)
    // RATS lower mutlak = 1914 (ilk regresyon entry'si)
    // Stata goreli (1=startl): lower = lags + 2
    lower  = lags + 2
    upper  = T
    pinobs = floor(pi * (upper - lower + 1))
    if (pinobs < 1) pinobs = 1

    if (breaks > 0) {
        bps = J(1, breaks, 0)
        ub  = J(1, breaks, 0)
        bestbreaks = J(1, breaks, 0)
        for (i=1; i<=breaks; i++) {
            bps[i] = (lower - 1) + pinobs*i
            ub[i]  = upper + 1 - pinobs*(breaks + 1 - i)
        }
    }
    else {
        bps = J(1, 1, 0)
        ub  = J(1, 1, 0)
        bestbreaks = J(1, 1, 0)
    }

    ndet = model * breaks + 1
    mint = .
    bestlag = lags
    bestxx = J(1, 1, 0)

    showdots = (breaks > 0)
    nout = 0
    ncomb = 0
    last1 = -1
    done = 0

    while (!done) {
        ncomb = ncomb + 1

        if (showdots & breaks > 0 & bps[1] != last1) {
            last1 = bps[1]
            if (mod(nout, 50) == 0 & nout > 0) printf("\n")
            printf(".")
            displayflush()
            nout = nout + 1
        }

        if (breaks > 0) {
            DT = J(T, model*breaks, 0)
            for (i=1; i<=breaks; i++) {
                DT[., (i-1)*model + 1] = (tt :== (bps[i] + 1))
                if (model == 2) {
                    DT[., (i-1)*model + 2] = (tt :>= (bps[i] + 1))
                }
            }
        }
        else {
            DT = J(T, 0, .)
        }

        Mr = J(T-1, 1+cols(DT), 1)
        if (cols(DT) > 0) {
            Mr[., 2..(1+cols(DT))] = DT[2..T, .]
        }
        resid = dy[2..T] - Mr * (invsym(quadcross(Mr,Mr)) * quadcross(Mr, dy[2..T]))

        // Vectorised stilde and ds:
        //   stilde[1] = 0, stilde[k] = stilde[k-1] + resid[k-1] for k=2..T
        //   ds[k] = stilde[k] - stilde[k-1] = resid[k-1] for k=2..T
        // So stilde = (0 \ runningsum(resid)) and ds = (. \ resid).
        stilde      = J(T, 1, 0)
        stilde[2..T] = runningsum(resid)
        ds          = J(T, 1, .)
        ds[2..T]    = resid

        // nbcols = number of cols up to and including all DT dummies
        //   = 1 (dy) + 1 (stilde) + 1 (const) + cols(DT)
        //   = 3 + cols(DT) = ndet + 2
        // mxcols = nbcols + lags
        nbcols = ndet + 2
        mxcols = nbcols + lags

        if (T - lags - 1 < ndet + lags + 2) {
            done = leestra_advance(bps, ub, breaks, pinobs, thin)
            if (breaks == 0) break
            continue
        }

        // Vectorised X construction:
        //   row index = k - lags - 1 for k = lags+2..T  (Nr = T - lags - 1 rows)
        //   col 1 = dy[k]            -> dy[lags+2..T]
        //   col 2 = stilde[k-1]      -> stilde[lags+1..T-1]
        //   col 3 = 1
        //   cols 4..3+cols(DT) = DT[k,.] -> DT[lags+2..T, .]
        //   cols nbcols+j = ds[k-j] for j=1..lags -> ds[lags+2-j..T-j]
        Nr = T - lags - 1
        X  = J(Nr, mxcols, .)
        X[., 1] = dy[(lags+2)::T]
        X[., 2] = stilde[(lags+1)::(T-1)]
        X[., 3] = J(Nr, 1, 1)
        if (cols(DT) > 0) {
            X[., 4..(3+cols(DT))] = DT[(lags+2)::T, .]
        }
        for (j=1; j<=lags; j++) {
            X[., nbcols+j] = ds[(lags+2-j)::(T-j)]
        }
        CM = quadcross(X, X)

        // OLS-based replacement for sweep (numerically stable in large samples)
        sweepxx = leestra_ols_xx(X, mxcols)

        if (method == 2 & lags > 0) {
            lagsused = leestra_gtos(sweepxx, X, mxcols, lags, slstay, ndet)
        }
        else if (method == 3 & lags > 0) {
            // BG-based lag selection on the auxiliary regression
            lagsused = leestra_bg_select(X, mxcols, nbcols, lags, bglags)
            // Recompute sweepxx using the chosen number of lags
            sweepxx = leestra_ols_xx(X, nbcols + lagsused)
        }
        else {
            lagsused = lags
        }

        ndf = rows(X) - lagsused - (ndet + 1)
        if (ndf <= 0) {
            done = leestra_advance(bps, ub, breaks, pinobs, thin)
            if (breaks == 0) break
            continue
        }
        tstat = sweepxx[2,1] / sqrt(sweepxx[2,2] * sweepxx[1,1] / ndf)

        if (mint == . | tstat < mint) {
            mint = tstat
            bestbreaks = bps
            bestlag = lagsused
            bestxx = sweepxx
        }

        if (breaks == 0) break
        done = leestra_advance(bps, ub, breaks, pinobs, thin)
    }

    if (showdots & nout > 0) printf("\n")

    //
    // For method(bg) (method == 3): re-estimate at bestbreaks using
    // bestlag (rather than the maximum lags) so that the regression uses
    // the full available sample. Grid search must use a fixed sample
    // (controlled by lags) to make t-stats comparable; once the optimum
    // is found, we recompute it on T - bestlag - 1 observations.
    //
    real scalar use_lag, recompute_ok
    real scalar bg_chi2_1, bg_p1, bg_minp, bg_warn, bg_minplag, bg_minp_chi2
    use_lag = lags
    recompute_ok = 0
    bg_chi2_1    = .
    bg_p1        = .
    bg_minp      = .
    bg_minplag   = .
    bg_minp_chi2 = .
    bg_warn      = 0

    if (method == 3 & breaks > 0) {
        real matrix DT_b, Mr_b, X_b, CM_b
        real colvector resid_b, stilde_b, ds_b
        real scalar j_b, k_b, mxc_b, tstat_b, Nr_b
        real scalar bg_lag_iter, bg_pcur

        // Build dummies at bestbreaks
        DT_b = J(T, model*breaks, 0)
        for (i=1; i<=breaks; i++) {
            DT_b[., (i-1)*model + 1] = (tt :== (bestbreaks[i] + 1))
            if (model == 2) {
                DT_b[., (i-1)*model + 2] = (tt :>= (bestbreaks[i] + 1))
            }
        }

        // Step 1: dy on constant + DT
        Mr_b = J(T-1, 1+cols(DT_b), 1)
        if (cols(DT_b) > 0) {
            Mr_b[., 2..(1+cols(DT_b))] = DT_b[2..T, .]
        }
        resid_b = dy[2..T] - Mr_b * (invsym(quadcross(Mr_b,Mr_b)) * quadcross(Mr_b, dy[2..T]))

        // Step 2: vectorised stilde and ds
        stilde_b        = J(T, 1, 0)
        stilde_b[2..T]  = runningsum(resid_b)
        ds_b            = J(T, 1, .)
        ds_b[2..T]      = resid_b

        // Step 3: build auxiliary regression with bestlag and full sample
        mxc_b = (ndet + 2) + bestlag
        if (T - bestlag - 1 >= ndet + bestlag + 2) {
            Nr_b = T - bestlag - 1
            X_b  = J(Nr_b, mxc_b, .)
            X_b[., 1] = dy[(bestlag+2)::T]
            X_b[., 2] = stilde_b[(bestlag+1)::(T-1)]
            X_b[., 3] = J(Nr_b, 1, 1)
            if (cols(DT_b) > 0) {
                X_b[., 4..(3+cols(DT_b))] = DT_b[(bestlag+2)::T, .]
            }
            for (j_b=1; j_b<=bestlag; j_b++) {
                X_b[., (ndet+2)+j_b] = ds_b[(bestlag+2-j_b)::(T-j_b)]
            }
            CM_b = quadcross(X_b, X_b)
            sweepxx = leestra_ols_xx(X_b, mxc_b)
            ndf = rows(X_b) - bestlag - (ndet + 1)
            if (ndf > 0) {
                tstat_b = sweepxx[2,1] / sqrt(sweepxx[2,2] * sweepxx[1,1] / ndf)
                mint    = tstat_b
                bestxx  = sweepxx
                use_lag = bestlag
                recompute_ok = 1
            }

            //
            // Post-selection BG diagnostics on the final regression.
            // BG(1) is the reported test (matches AR(1) check).
            // Also compute min p across BG(1)..BG(bglags) to decide warning.
            //
            bg_p1      = leestra_bg_pvalue(X_b, mxc_b, 1)
            bg_minp    = bg_p1
            bg_minplag = 1
            for (bg_lag_iter=2; bg_lag_iter<=bglags; bg_lag_iter++) {
                bg_pcur = leestra_bg_pvalue(X_b, mxc_b, bg_lag_iter)
                if (bg_pcur < bg_minp) {
                    bg_minp    = bg_pcur
                    bg_minplag = bg_lag_iter
                }
            }
            // Recover chi^2 from p-value: invchi2tail(df, p) gives the statistic
            if (bg_p1 < .) {
                bg_chi2_1 = invchi2tail(1, bg_p1)
            }
            if (bg_minp < .) {
                bg_minp_chi2 = invchi2tail(bg_minplag, bg_minp)
            }
            // Warning if autocorrelation persists at largest lag tried
            if (bg_minp < 0.05 & bestlag == lags) {
                bg_warn = 1
            }
        }
    }

    Nuse = T - use_lag - 1
    ndf2 = Nuse - (ndet + 1 + bestlag)
    bestcoef   = J(1, 1+ndet, .)
    besttstats = J(1, 1+ndet, .)
    for (i=1; i<=1+ndet; i++) {
        bestcoef[i]   = bestxx[i+1, 1]
        besttstats[i] = bestcoef[i] / sqrt(bestxx[1,1] * bestxx[i+1, i+1] / ndf2)
    }

    //
    // Lambda is computed based on the effective regression range.
    // For method(bg), this is the resampled range starting at use_lag+2.
    // For other methods, use_lag == lags so this reduces to the original lower.
    //
    real scalar lower_eff
    lower_eff = use_lag + 2

    if (breaks >= 1) {
        lambda1 = (bestbreaks[1] - lower_eff) / (upper - lower_eff + 1)
    }
    else {
        lambda1 = .
    }
    if (breaks >= 2) {
        lambda2 = (bestbreaks[2] - lower_eff) / (upper - lower_eff + 1)
    }
    else {
        lambda2 = .
    }

    if (breaks == 0) {
        cv = leestra_interp_T(leestra_cv0(), Nuse)
    }
    else if (breaks == 1 & model == 1) {
        cv = leestra_interp_T(leestra_cvc1(), Nuse)
    }
    else if (breaks == 2 & model == 1) {
        cv = leestra_interp_T(leestra_cvc2(), Nuse)
    }
    else if (breaks == 1 & model == 2) {
        cv = leestra_interp_cvb1(lambda1, Nuse)
    }
    else if (breaks == 2 & model == 2) {
        cv = leestra_interp_cvb2(lambda1, lambda2, Nuse)
    }
    else {
        cv = J(1, 3, .)
    }

    st_rclear()
    st_numscalar("r(tstat)",   mint)
    st_numscalar("r(nobs)",    Nuse)
    st_numscalar("r(bestlag)", bestlag)
    st_numscalar("r(ndf)",     ndf2)
    st_numscalar("r(ncomb)",   ncomb)
    st_numscalar("r(use_lag)", use_lag)
    st_numscalar("r(bg_chi2)",     bg_chi2_1)
    st_numscalar("r(bg_p)",        bg_p1)
    st_numscalar("r(bg_minp)",     bg_minp)
    st_numscalar("r(bg_minplag)",  bg_minplag)
    st_numscalar("r(bg_minpchi2)", bg_minp_chi2)
    st_numscalar("r(bg_warn)",     bg_warn)
    st_numscalar("r(lambda1)", lambda1)
    st_numscalar("r(lambda2)", lambda2)
    st_matrix("r(beta)",   bestcoef)
    st_matrix("r(tstats)", besttstats)
    st_matrix("r(bps)",    bestbreaks)
    st_matrix("r(cv)",     cv)
}

end
