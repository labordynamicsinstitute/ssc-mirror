*! kapetanios.ado  v3.2.0
*! Kapetanios (2005) unit-root test with up to 5 structural breaks
*! v2.0: Mata backend for improved speed
*! v2.1: Added BG-based lag selection option (lagsel)
*! v2.2: Added AIC and BIC lag selection options
*! v3.1: Obs numbering matches Gretl convention
*! v3.2: Real-data examples added; improved documentation
*
* This program is largely a translation of the Gretl package
* Kapetanios v2.1 (2022-04-11) by Andrea E. Sánchez Urbina,
* Ricardo Ramírez & Daniel Ventosa-Santaulària to Stata,
* with the following extensions:
*
* Differences between the Gretl Kapetanios package and -kapetanios-:
*
* 1. -kapetanios- offers Breusch-Godfrey (BG) based lag selection via
*    a general-to-specific (GTS) procedure (lagsel(bg)), which directly
*    targets the elimination of serial correlation in test residuals.
*
* 2. -kapetanios- offers AIC-based lag selection (lagsel(aic)).
*
* 3. -kapetanios- offers BIC-based lag selection (lagsel(bic)).
*
* 4. For lagsel(aic) and lagsel(bic), a post-selection BG test is
*    automatically performed using the estimated break dates, and a
*    warning is issued if residual autocorrelation remains.
*
* 5. -kapetanios- accepts time-series operators directly as input
*    (e.g. D.varname, D2.varname).
*
* 6. -kapetanios- uses a Mata backend for significantly faster computation.
*
* Results have been verified to be numerically identical to the Gretl
* implementation. Replication example:
*   . webuse lutkepohl2
*   . tsset qtr
*   . kapetanios consump, breaks(3) kmax(1) epsilon(0.1) model(3)
* produces identical results to Kapetanios(consump, 3, 1, 0.1, 3) in Gretl.
*
* To reload after update: discard

program define kapetanios, rclass
    version 14

    * Extract options manually before calling syntax
    * This allows ts operators like D.varname to work
    local 0_orig `"`0'"'
    gettoken inputvar rest : 0, parse(" ,")
    local 0 `"`rest'"'
    syntax [, Breaks(integer 3) Kmax(integer -1) Epsilon(real 0.1) Model(integer 3) LAGSel(string) BGLags(integer -1)]

    if `breaks' < 1 | `breaks' > 5 {
        di as error "breaks() must be between 1 and 5"
        exit 198
    }
    if `model' < 1 | `model' > 3 {
        di as error "model() must be 1, 2, or 3"
        exit 198
    }
    if `epsilon' <= 0 | `epsilon' >= 0.5 {
        di as error "epsilon() must be between 0 and 0.5 (exclusive)"
        exit 198
    }

    * Parse varname — support ts operators like D., L., S., etc.
    local inputvar = trim("`inputvar'")
    * Check if ts operator is used (contains a dot)
    if strpos("`inputvar'", ".") {
        * Has a ts operator — create temp variable
        tempvar tsvar
        quietly gen double `tsvar' = `inputvar'
        local yvar       `tsvar'
        local yvar_label "`inputvar'"
    }
    else {
        * Plain variable name
        local yvar       `inputvar'
        local yvar_label "`inputvar'"
        confirm variable `yvar'
    }
    local use_bg  = 0
    local use_aic = 0
    local use_bic = 0
    if "`lagsel'" != "" {
        if lower("`lagsel'") == "bg" {
            local use_bg = 1
        }
        else if lower("`lagsel'") == "aic" {
            local use_aic = 1
        }
        else if lower("`lagsel'") == "bic" {
            local use_bic = 1
        }
        else if lower("`lagsel'") == "ttest" {
            * explicit ttest — same as default, nothing to set
        }
        else {
            di as error "lagsel() must be ttest, bg, aic, or bic"
            exit 198
        }
    }

    quietly {
        tempvar touse
        mark `touse'
        markout `touse' `yvar'
        count if `touse'
        local T = r(N)
    }

    local m = `breaks'

    if `kmax' < 0 {
        * Conservative rule for all methods by default
        local kmax = floor(4*((`T'/100)^0.25))
        if `kmax' < 1 local kmax = 1
    }

    * Label and BG horizon
    if `use_bg' {
        if `bglags' < 0 {
            qui tsset
            local tsfmt  `r(tsfmt)'
            local tdelta `r(tdelta)'
            * Detect frequency from format string or delta
            if strpos("`tsfmt'", "q") {
                local bglags = 8
            }
            else if strpos("`tsfmt'", "m") {
                local bglags = 24
            }
            else if strpos("`tsfmt'", "w") {
                local bglags = 52
            }
            else if strpos("`tsfmt'", "d") | strpos("`tsfmt'", "td") {
                local bglags = 100
            }
            else if `tdelta' == 1 & strpos("`tsfmt'", "t") {
                local bglags = 100
            }
            else {
                local bglags = 2
            }
            * Cap bglags at kmax*5 to avoid excessive computation
            local bgcap = `kmax' * 5
            if `bglags' > `bgcap' local bglags = `bgcap'
            if `bglags' < 1       local bglags = 1
        }
        local lagsel_label "Breusch-Godfrey (BG lags: 1 to `bglags')"
    }
    else if `use_aic' {
        local lagsel_label "Akaike Information Criterion (AIC)"
    }
    else if `use_bic' {
        local lagsel_label "Bayesian Information Criterion (BIC)"
    }
    else {
        local lagsel_label "Sequential t-test (|t| > 1.6)"
    }

    local Schwert = floor(12*((`T'/100)^0.5))
    local kmax_default = floor(4*((`T'/100)^0.25))
    if `kmax_default' < 1 local kmax_default = 1

    * Warn if kmax exceeds Schwert rule
    if `kmax' > `Schwert' & "`lagsel'" == "" {
        di as result "Note: kmax(`kmax') exceeds Schwert's rule (p_max = `Schwert')."
        di as result "      Consider using kmax(`Schwert') or lagsel(bg)/lagsel(aic)/lagsel(bic)."
        di as text " "
    }
    else if `model' == 2 local modlabel "Only DT (trend breaks)"
    else                 local modlabel "Both DU and DT"

    * Trimming
    local eps = `epsilon'
    if mod(`T',2) == 1 {
        local eps_max = (`T'-3)/(2*`T')
    }
    else {
        local eps_max = (`T'-2)/(2*`T')
    }
    if `eps_max' < `eps' {
        local eps = `eps_max'
    }
    local bound = ceil(`eps'*`T')

    * BG-based lag selection
    if `use_bg' {
        qui tsset
        local tvar `r(timevar)'

        local bg_ksel = 0
        local Kprev   = `kmax'
        local found   = 0

        forvalues K = `kmax'(-1)0 {
            if `found' continue

            local lagvars ""
            forvalues lg = 1/`K' {
                local lagvars "`lagvars' LD`lg'.`yvar'"
            }

            capture qui regress D.`yvar' L.`yvar' `lagvars' if `touse'
            if _rc continue

            local minp = 1
            forvalues lag = 1/`bglags' {
                capture qui estat bgodfrey, lags(`lag') nomiss0
                if !_rc {
                    local plag = el(r(p),1,1)
                    if `plag' < `minp' local minp = `plag'
                }
            }

            if `minp' < 0.05 {
                local bg_ksel = `Kprev'
                local found   = 1
            }
            else {
                local Kprev = `K'
            }
        }

        if !`found' {
            local bg_ksel = 0
        }
        else {
            local lagvars ""
            forvalues lg = 1/`bg_ksel' {
                local lagvars "`lagvars' LD`lg'.`yvar'"
            }
            capture qui regress D.`yvar' L.`yvar' `lagvars' if `touse'
            if !_rc {
                local minp_final = 1
                forvalues lag = 1/`bglags' {
                    capture qui estat bgodfrey, lags(`lag') nomiss0
                    if !_rc {
                        local plag = el(r(p),1,1)
                        if `plag' < `minp_final' local minp_final = `plag'
                    }
                }
                if `minp_final' < 0.05 & `bg_ksel' == `kmax' {
                    local bg_warn = 1
                }
            }
        }

        local kmax_mata   = `bg_ksel'
        local use_bg_mata = 0
        local best_lag    = `bg_ksel'
    }

    * AIC-based lag selection
    else if `use_aic' {
        local aic_ksel  = 0
        local aic_best  = 1e15

        forvalues K = 0/`kmax' {
            local lagvars ""
            forvalues lg = 1/`K' {
                local lagvars "`lagvars' LD`lg'.`yvar'"
            }

            capture qui regress D.`yvar' L.`yvar' `lagvars' if `touse'
            if _rc continue

            local nobs = e(N)
            local npar = e(df_m) + 1
            local ssr  = e(rss)
            local aic  = log(`ssr'/`nobs') + 2*`npar'/`nobs'

            if `aic' < `aic_best' {
                local aic_best = `aic'
                local aic_ksel = `K'
            }
        }

        local kmax_mata   = `aic_ksel'
        local use_bg_mata = 0
        local best_lag    = `aic_ksel'
    }

    * BIC-based lag selection
    else if `use_bic' {
        local bic_ksel  = 0
        local bic_best  = 1e15

        forvalues K = 0/`kmax' {
            local lagvars ""
            forvalues lg = 1/`K' {
                local lagvars "`lagvars' LD`lg'.`yvar'"
            }

            capture qui regress D.`yvar' L.`yvar' `lagvars' if `touse'
            if _rc continue

            local nobs = e(N)
            local npar = e(df_m) + 1
            local ssr  = e(rss)
            local bic  = log(`ssr'/`nobs') + `npar'*log(`nobs')/`nobs'

            if `bic' < `bic_best' {
                local bic_best = `bic'
                local bic_ksel = `K'
            }
        }

        local kmax_mata   = `bic_ksel'
        local use_bg_mata = 0
        local best_lag    = `bic_ksel'
    }

    else {
        local kmax_mata   = `kmax'
        local use_bg_mata = 0
    }

    * Call Mata
    tempname lambda_mat stat_mat lag_mat
    mata: _kapetanios_main("`yvar'", "`touse'", `m', `kmax_mata', `model', `bound', `T', `use_bg_mata', `bglags', "`lambda_mat'", "`stat_mat'", "`lag_mat'")

    * Retrieve results
    local stat = el(`stat_mat', 1, 1)
    local M    = el(`stat_mat', 1, 2)
    if !`use_bg' {
        local best_lag = el(`lag_mat', 1, 1)
    }

    if `stat' == 1000 {
        di as error "Non-invertible matrix encountered. Try a higher trimming parameter."
        exit 499
    }

    * BG check for AIC/BIC — using break dummies from Mata results
    if `use_aic' | `use_bic' {
        * Determine BG horizon
        if `bglags' < 0 {
            qui tsset
            local tsfmt2 `r(tsfmt)'
            if strpos("`tsfmt2'", "q")      local bglags2 = 8
            else if strpos("`tsfmt2'", "m") local bglags2 = 24
            else if strpos("`tsfmt2'", "w") local bglags2 = 52
            else if strpos("`tsfmt2'", "d") local bglags2 = 100
            else                            local bglags2 = 2
            * Cap at kmax*5
            local bgcap2 = `kmax' * 5
            if `bglags2' > `bgcap2' local bglags2 = `bgcap2'
            if `bglags2' < 1        local bglags2 = 1
        }
        else local bglags2 = `bglags'

        * Build break dummies using estimated break dates
        qui tsset
        local tvar2 `r(timevar)'
        local Mint2 = int(`M')
        forvalues bk = 1/`Mint2' {
            local lamv2 = int(el(`lambda_mat', `bk', 1))
            tempvar bkdu`bk' bkdt`bk'
            qui {
                tempvar obsnum2
                gen `obsnum2' = sum(`touse')
                su `tvar2' if `obsnum2' == `lamv2' & `touse', meanonly
                local bkraw = r(mean)
                drop `obsnum2'
            }
            qui gen double `bkdu`bk'' = (`tvar2' > `bkraw') if `touse'
            qui gen double `bkdt`bk'' = `bkdu`bk'' * (`tvar2' - `bkraw') if `touse'
        }

        * Build lag variables
        local lagvars2 ""
        forvalues lg = 1/`best_lag' {
            tempvar dyl2_`lg'
            qui gen double `dyl2_`lg'' = L`lg'.D.`yvar' if `touse'
            local lagvars2 "`lagvars2' `dyl2_`lg''"
        }

        * Build dummy varlists
        local duvars ""
        local dtvars ""
        forvalues bk = 1/`Mint2' {
            local duvars "`duvars' `bkdu`bk''"
            local dtvars "`dtvars' `bkdt`bk''"
        }

        * Run regression with break dummies and selected lag
        if `model' == 1 {
            capture qui regress D.`yvar' L.`yvar' `lagvars2' `duvars' if `touse'
        }
        else if `model' == 2 {
            capture qui regress D.`yvar' L.`yvar' `lagvars2' `dtvars' if `touse'
        }
        else {
            capture qui regress D.`yvar' L.`yvar' `lagvars2' `duvars' `dtvars' if `touse'
        }

        if !_rc {
            local minp_ic = 1
            forvalues lag = 1/`bglags2' {
                capture qui estat bgodfrey, lags(`lag') nomiss0
                if !_rc {
                    local plag = el(r(p),1,1)
                    if `plag' < `minp_ic' local minp_ic = `plag'
                }
            }
            if `minp_ic' < 0.05 {
                if `use_aic' local aic_ac_warn = 1
                if `use_bic' local bic_ac_warn = 1
            }
        }
    }

    * Critical values
    tempname A B C CVmod
    matrix `A' = J(5,3,0)
    matrix `A'[1,1] = -4.661
    matrix `A'[1,2] = -4.938
    matrix `A'[1,3] = -5.338
    matrix `A'[2,1] = -5.467
    matrix `A'[2,2] = -5.685
    matrix `A'[2,3] = -6.162
    matrix `A'[3,1] = -6.265
    matrix `A'[3,2] = -6.529
    matrix `A'[3,3] = -6.991
    matrix `A'[4,1] = -6.832
    matrix `A'[4,2] = -7.104
    matrix `A'[4,3] = -7.560
    matrix `A'[5,1] = -7.398
    matrix `A'[5,2] = -7.636
    matrix `A'[5,3] = -8.248

    matrix `B' = J(5,3,0)
    matrix `B'[1,1] = -4.144
    matrix `B'[1,2] = -4.495
    matrix `B'[1,3] = -5.014
    matrix `B'[2,1] = -4.784
    matrix `B'[2,2] = -5.096
    matrix `B'[2,3] = -5.616
    matrix `B'[3,1] = -5.429
    matrix `B'[3,2] = -5.726
    matrix `B'[3,3] = -6.286
    matrix `B'[4,1] = -5.999
    matrix `B'[4,2] = -6.305
    matrix `B'[4,3] = -6.856
    matrix `B'[5,1] = -6.417
    matrix `B'[5,2] = -6.717
    matrix `B'[5,3] = -7.395

    matrix `C' = J(5,3,0)
    matrix `C'[1,1] = -4.820
    matrix `C'[1,2] = -5.081
    matrix `C'[1,3] = -5.704
    matrix `C'[2,1] = -5.847
    matrix `C'[2,2] = -6.113
    matrix `C'[2,3] = -6.587
    matrix `C'[3,1] = -6.686
    matrix `C'[3,2] = -7.006
    matrix `C'[3,3] = -7.401
    matrix `C'[4,1] = -7.426
    matrix `C'[4,2] = -7.736
    matrix `C'[4,3] = -8.243
    matrix `C'[5,1] = -8.016
    matrix `C'[5,2] = -8.343
    matrix `C'[5,3] = -9.039

    if `model' == 3      matrix `CVmod' = `C'
    else if `model' == 2 matrix `CVmod' = `B'
    else                 matrix `CVmod' = `A'

    local cv10 = el(`CVmod', `M', 1)
    local cv05 = el(`CVmod', `M', 2)
    local cv01 = el(`CVmod', `M', 3)

    * Decision at 5%
    if `stat' < `cv05' {
        local decision "Reject H0 at the 5% significance level"
    }
    else {
        local decision "Do not reject H0 at the 5% significance level"
    }

    * Get break dates and OLS observation range
    qui tsset
    local tvar `r(timevar)'
    local tfmt `r(tsfmt)'

    * OLS sample starts at best_lag + 2 (due to lagging)
    local ols_start_obs = `best_lag' + 2
    local ols_T = `T' - `best_lag' - 1

    qui {
        tempvar obsnum
        gen `obsnum' = sum(`touse')
        su `tvar' if `obsnum' == `ols_start_obs' & `touse', meanonly
        local ols_start_raw = r(mean)
        su `tvar' if `touse', meanonly
        local ols_end_raw = r(max)
        drop `obsnum'
    }
    local ols_start : display `tfmt' `ols_start_raw'
    local ols_end   : display `tfmt' `ols_end_raw'
    local ols_start = trim("`ols_start'")
    local ols_end   = trim("`ols_end'")

    local Mint = int(`M')
    forvalues bk = 1/`Mint' {
        local lamv = int(el(`lambda_mat', `bk', 1))
        qui {
            tempvar obsnum origobs
            gen `obsnum' = sum(`touse')
            gen `origobs' = _n
            su `tvar' if `obsnum' == `lamv' & `touse', meanonly
            local rawdate = r(mean)
            su `origobs' if `obsnum' == `lamv' & `touse', meanonly
            local bkobs_`bk' = r(mean)
            drop `obsnum' `origobs'
        }
        local bkdate_`bk' : display `tfmt' `rawdate'
        local bkdate_`bk' = trim("`bkdate_`bk''")
    }

    local ord1 "First"
    local ord2 "Second"
    local ord3 "Third"
    local ord4 "Fourth"
    local ord5 "Fifth"

    * =================== OUTPUT ===================
    di as text " "
    di as text "Kapetanios test for unit root" _col(45) "Number of obs    = " as result `ols_T'
    di as text "Variable: " as result "`yvar_label'" as text _col(45) "Number of breaks = " as result `M'
    di as text " "
    di as text "  Model             : `modlabel'"
    di as text "  Trimming parameter: `epsilon'"
    di as text "  Lag selection     : `lagsel_label'"
    di as text "  Selected lag      : `best_lag'"
    if "`bg_warn'" == "1" {
        di as text " "
        di as result "  Warning: Autocorrelation could not be eliminated with kmax = `kmax' lags."
        di as result "           Results should be interpreted with caution."
        di as result "           Consider increasing kmax()."
    }
    if "`aic_ac_warn'" == "1" {
        di as text " "
        di as result "  Warning: Breusch-Godfrey test detects autocorrelation at selected lag (K = `best_lag')."
        di as result "           Consider using lagsel(bg) instead."
    }
    if "`bic_ac_warn'" == "1" {
        di as text " "
        di as result "  Warning: Breusch-Godfrey test detects autocorrelation at selected lag (K = `best_lag')."
        di as result "           Consider using lagsel(bg) instead."
    }
    di as text " "
    di as text "H0: " as result "`yvar_label'" as text " has a unit root"
    di as text " "
    di as text _col(19) "                    Kapetanios"
    di as text _col(14) "Test  {hline 11} critical value {hline 11}"
    di as text _col(14) "statistic" _col(34) "1%" _col(46) "5%" _col(57) "10%"
    di as text "{hline 62}"
    di as result "Z(t)" _col(14) %9.3f `stat' _col(27) %9.3f `cv01' _col(39) %9.3f `cv05' _col(51) %9.3f `cv10'
    di as text "{hline 62}"

    * Rejection decisions — always show all three levels
    if `stat' < `cv01' {
        di as text " - Reject H0 at the 1% significance level"
    }
    else {
        di as text " - Do not reject H0 at the 1% significance level"
    }
    if `stat' < `cv05' {
        di as text " - Reject H0 at the 5% significance level"
    }
    else {
        di as text " - Do not reject H0 at the 5% significance level"
    }
    if `stat' < `cv10' {
        di as text " - Reject H0 at the 10% significance level"
    }
    else {
        di as text " - Do not reject H0 at the 10% significance level"
    }
    di as text " "

    forvalues bk = 1/`Mint' {
        di as text "  `ord`bk'' break" _col(20) ": " as result "`bkdate_`bk''" as text " (obs: " as result `bkobs_`bk'' as text ")"
    }

    di as text " "

    return scalar stat     = `stat'
    return scalar cv10     = `cv10'
    return scalar cv05     = `cv05'
    return scalar cv01     = `cv01'
    return scalar breaks   = `M'
    return scalar best_lag = `best_lag'
    return matrix lambda   = `lambda_mat'
end


* ============================================================
* Mata functions
* ============================================================
* Mata functions
* ============================================================

* ============================================================
* Mata functions
* ============================================================
mata:

// -------------------------------------------------------
// Simple OLS — for BG augmented regression only
// -------------------------------------------------------
real scalar function _kols_simple(real matrix y,
                                   real matrix X,
                                   real matrix B,
                                   real matrix seB,
                                   real scalar ssr)
{
    real matrix XtX, XtXi, U, CovB
    real scalar k, n, s2

    k    = cols(X)
    n    = rows(y)
    XtX  = cross(X, X)
    XtXi = invsym(XtX)
    if (missing(XtXi[1,1])) return(0)

    B    = XtXi * cross(X, y)
    U    = y - X * B
    ssr  = (U' * U)[1,1]
    s2   = ssr / (n - k)
    CovB = s2 * XtXi
    seB  = sqrt(diagonal(CovB))
    return(1)
}

// -------------------------------------------------------
// BG test — takes residual vector U only
// -------------------------------------------------------
real scalar function _bg_test(real matrix U,
                               real scalar bglags)
{
    real matrix Umat, Xaug, B, seB
    real scalar n, p, LM, pval, lag, ssr, ok, ssr0_trim
    real matrix U0

    n = rows(U)
    p = n - bglags
    if (p < bglags + 2) return(0)

    Umat = J(p, bglags, 0)
    for (lag=1; lag<=bglags; lag++) {
        Umat[,lag] = U[bglags-lag+1::n-lag]
    }

    U0   = U[bglags+1::n]
    Xaug = (J(p, 1, 1), Umat)

    ok = _kols_simple(U0, Xaug, B, seB, ssr)
    if (!ok) return(0)

    ssr0_trim = (U0' * U0)[1,1]
    LM   = p * (1 - ssr / ssr0_trim)
    pval = chi2tail(bglags, LM)

    return(pval < 0.05)
}

// -------------------------------------------------------
// OLS — row-by-row, no T×k matrix ever stored
// lambda_vec: previously found breaks (j-1 x 1)
// candidate: current break point being tested
// m_cur: total number of breaks in this regression
// -------------------------------------------------------
real scalar function _kols2(real matrix Y,
                             real colvector lambda_vec,
                             real scalar candidate,
                             real scalar K,
                             real scalar mod,
                             real scalar m_cur,
                             real matrix B,
                             real matrix seB,
                             real scalar ssr,
                             real matrix U)
{
    real scalar T, n_obs, ncols, r, t, s2, k, n, bk, du_val, dt_val, jj
    real matrix XtX, XtXi, Xty, CovB
    real colvector xi, Dy

    T     = rows(Y)
    n_obs = T - K - 1
    Dy    = Y[2::T] - Y[1::T-1]

    if (mod == 3) ncols = K + 2*m_cur + 3
    else          ncols = K + m_cur + 3

    k   = ncols
    XtX = J(k, k, 0)
    Xty = J(k, 1, 0)

    for (t = K+2; t <= T; t++) {
        xi    = J(k, 1, 0)
        xi[1] = 1
        xi[2] = t
        xi[3] = Y[t-1]
        if (K > 0) {
            for (r=1; r<=K; r++) xi[r+3] = Dy[t-1-r]
        }
        for (jj=1; jj<=m_cur; jj++) {
            bk     = (jj < m_cur ? lambda_vec[jj] : candidate)
            du_val = (t > bk ? 1 : 0)
            dt_val = (t > bk ? t - bk : 0)
            if (mod == 1 | mod == 3) xi[K+3+jj]       = du_val
            if (mod == 2)            xi[K+3+jj]        = dt_val
            if (mod == 3)            xi[K+m_cur+3+jj]  = dt_val
        }
        XtX = XtX + xi * xi'
        Xty = Xty + xi * Y[t]
    }

    XtXi = invsym(XtX)
    if (missing(XtXi[1,1])) return(0)
    B = XtXi * Xty

    U   = J(n_obs, 1, 0)
    ssr = 0
    for (t = K+2; t <= T; t++) {
        xi    = J(k, 1, 0)
        xi[1] = 1
        xi[2] = t
        xi[3] = Y[t-1]
        if (K > 0) {
            for (r=1; r<=K; r++) xi[r+3] = Dy[t-1-r]
        }
        for (jj=1; jj<=m_cur; jj++) {
            bk     = (jj < m_cur ? lambda_vec[jj] : candidate)
            du_val = (t > bk ? 1 : 0)
            dt_val = (t > bk ? t - bk : 0)
            if (mod == 1 | mod == 3) xi[K+3+jj]      = du_val
            if (mod == 2)            xi[K+3+jj]       = dt_val
            if (mod == 3)            xi[K+m_cur+3+jj] = dt_val
        }
        U[t-K-1] = Y[t] - (xi' * B)[1,1]
        ssr = ssr + U[t-K-1]^2
    }

    n    = n_obs
    s2   = ssr / (n - k)
    CovB = s2 * XtXi
    seB  = sqrt(diagonal(CovB))
    return(1)
}

// -------------------------------------------------------
// Lag selection
// -------------------------------------------------------
real scalar function _klag2(real matrix Y,
                              real colvector lambda_vec,
                              real scalar candidate,
                              real scalar kmax,
                              real scalar mod,
                              real scalar m_cur,
                              real scalar use_bg,
                              real scalar bglags)
{
    real matrix B, seB, U
    real scalar K, n_obs, ssr, b3, se3, tstat, ok, kk, has_ac, Kprev

    if (use_bg) {
        Kprev = kmax
        for (K=kmax; K>=0; K--) {
            n_obs = rows(Y) - K - 1
            if (n_obs < 1) {
                Kprev = K+1
                continue
            }
            ok = _kols2(Y, lambda_vec, candidate, K, mod, m_cur, B, seB, ssr, U)
            if (!ok) return(-1)
            has_ac = _bg_test(U, bglags)
            if (has_ac) return(Kprev)
            Kprev = K
        }
        return(0)
    }

    for (kk=1; kk<=kmax; kk++) {
        K     = kmax + 1 - kk
        n_obs = rows(Y) - K - 1
        if (n_obs < 1) continue
        ok = _kols2(Y, lambda_vec, candidate, K, mod, m_cur, B, seB, ssr, U)
        if (!ok) return(-1)
        b3    = B[K+3, 1]
        se3   = seB[K+3, 1]
        tstat = b3 / se3
        if (abs(tstat) > 1.6) return(K)
    }
    return(0)
}

// -------------------------------------------------------
// Regression for a given break configuration
// -------------------------------------------------------
real rowvector function _kreg2(real matrix Y,
                                real colvector lambda_vec,
                                real scalar candidate,
                                real scalar kmax,
                                real scalar mod,
                                real scalar m_cur,
                                real scalar use_bg,
                                real scalar bglags)
{
    real matrix B, seB, U
    real scalar K, n_obs, b3, se3, tstat, ssr, ok

    K = _klag2(Y, lambda_vec, candidate, kmax, mod, m_cur, use_bg, bglags)
    if (K == -1) return((0, 0, 0, 0))

    n_obs = rows(Y) - K - 1
    if (n_obs < 1) return((0, 0, 0, K))

    ok = _kols2(Y, lambda_vec, candidate, K, mod, m_cur, B, seB, ssr, U)
    if (!ok) return((0, 0, 0, K))

    b3    = B[3, 1]
    se3   = seB[3, 1]
    tstat = (b3 - 1) / se3

    return((tstat, ssr, 1, K))
}

// -------------------------------------------------------
// -------------------------------------------------------
// -------------------------------------------------------
// Main function — pure scalar tracking, zero T-length vectors
// -------------------------------------------------------
// -------------------------------------------------------
// Main function — st_view for Y, tau vecs in Mata only
// -------------------------------------------------------
void function _kapetanios_main(string scalar Yvarname,
                                string scalar tousename,
                                real scalar m,
                                real scalar kmax,
                                real scalar mod,
                                real scalar bound,
                                real scalar T,
                                real scalar use_bg,
                                real scalar bglags,
                                string scalar lambdaname,
                                string scalar statname,
                                string scalar lagname)
{
    real matrix Y, res
    real colvector lambda, lambda_prev, tau_prev, tau_cur
    real scalar i, j, Break, M, lj1, stat, best_lag
    real scalar cond1, cond2, best_ssr, best_tstat, best_lagk, prev_feasible

    st_view(Y, ., Yvarname, tousename)
    lambda    = J(m, 1, 0)
    M         = m
    tau_prev  = J(T, 1, 1000)

    // ---- First break search ----
    best_ssr   = 1e15
    best_tstat = 1000
    best_lagk  = 0
    Break      = 1

    for (i=1; i<=T; i++) {
        if (i <= bound | i >= T - bound) continue
        res = _kreg2(Y, J(0,1,0), i, kmax, mod, 1, use_bg, bglags)
        if (res[1,3] == 0) {
            st_matrix(statname,   (1000, 1))
            st_matrix(lagname,    (0))
            st_matrix(lambdaname, lambda)
            return
        }
        tau_prev[i] = res[1,1]
        if (res[1,2] < best_ssr) {
            best_ssr   = res[1,2]
            best_tstat = res[1,1]
            best_lagk  = res[1,4]
            Break      = i
        }
    }
    lambda[1,1] = Break

    // ---- Additional breaks ----
    for (j=2; j<=m; j++) {
        lj1           = lambda[j-1, 1]
        lambda_prev   = lambda[1::j-1, 1]
        best_ssr      = 1e15
        best_tstat    = 1000
        best_lagk     = 0
        Break         = 1
        prev_feasible = 0
        tau_cur       = J(T, 1, 1000)

        for (i=1; i<=T; i++) {
            cond1 = (i > lj1 + bound)
            cond2 = (i < lj1 - bound)
            if (!(cond1 | cond2)) continue
            if (tau_prev[i] == 1000) continue

            res = _kreg2(Y, lambda_prev, i, kmax, mod, j, use_bg, bglags)
            if (res[1,3] == 0) {
                st_matrix(statname,   (1000, 1))
                st_matrix(lagname,    (0))
                st_matrix(lambdaname, lambda)
                return
            }
            tau_cur[i]    = res[1,1]
            prev_feasible = 1
            if (res[1,2] < best_ssr) {
                best_ssr   = res[1,2]
                best_tstat = res[1,1]
                best_lagk  = res[1,4]
                Break      = i
            }
        }

        if (!prev_feasible | Break == 1) {
            M = j - 1
            break
        }
        lambda[j,1] = Break
        tau_prev     = tau_cur
    }

    // ---- Final stat ----
    stat     = best_tstat
    best_lag = best_lagk

    st_matrix(lambdaname, lambda[1::M, 1])
    st_matrix(statname,   (stat, M))
    st_matrix(lagname,    (best_lag))
}

end
