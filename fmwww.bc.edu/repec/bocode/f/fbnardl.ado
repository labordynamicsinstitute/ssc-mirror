*! fbnardl — Fourier Bootstrap Nonlinear ARDL
*! Version 2.0.0 — 2026-09-22
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Independent Researcher
*!
*! Implements:
*!   type(fnardl)  — Fourier NARDL with Kripfganz & Schneider (2020) bounds
*!   type(fbnardl) — Fourier Bootstrap NARDL: recursive null-imposed bootstrap
*!                   of McNown, Sam & Goh (2018) or Bertelli, Vacca & Zoia (2022)
*!
*! References:
*!   Shin, Yu & Greenwood-Nimmo (2014) — NARDL framework
*!   Yilanci, Bozoklu & Gorus (2020) — Fourier ARDL
*!   McNown, Sam & Goh (2018) — Bootstrap ARDL
*!   Bertelli, Vacca & Zoia (2022) — Bootstrap cointegration tests in ARDL
*!   Kripfganz & Schneider (2020) — ARDL bounds test critical values
*!   Pesaran, Shin & Smith (2001) — ARDL bounds testing
*!   White (1980); Newey & West (1987) — robust / HAC covariance matrices
*!   Brown, Durbin & Evans (1975) — CUSUM / CUSUMSQ on recursive residuals

capture program drop fbnardl
program define fbnardl, eclass sortpreserve
    version 17

    // =========================================================================
    // 1. SYNTAX PARSING
    // =========================================================================
    syntax varlist(min=1 ts fv) [if] [in], ///
        Decompose(varlist ts min=1)         /// variable(s) to decompose into pos/neg
        [                                   ///
        Type(string)                        /// fnardl or fbnardl (default: fnardl)
        MAXLag(integer 4)                   /// maximum lag to search (default: 4)
        MAXk(real 3)                        /// maximum Fourier frequency (default: 3)
        IC(string)                          /// information criterion: aic or bic (default: aic)
        REPS(integer 999)                   /// bootstrap replications (default: 999)
        Bootstrap(string)                   /// bvz (default) or mcnown
        XDGP(string)                        /// rw (default) or vecm: marginal x process
        HAC(string)                         /// hetero | auto | both | none
        HACLAGS(integer -1)                 /// Newey-West lag (-1 = automatic)
        EXOg(varlist ts fv)                 /// fixed (exogenous) regressors, e.g. dummies
        FIXed(varlist ts fv)                /// synonym for exog()
        Level(cilevel)                      /// confidence level (default: 95)
        NODIag                              /// suppress diagnostics
        NODYNmult                           /// suppress dynamic multipliers
        NOADVanced                          /// suppress advanced analyses
        HORizon(integer 20)                 /// multiplier horizon (default: 20)
        NOFourier                           /// no Fourier terms (pure NARDL)
        NOTable                             /// suppress main regression table
        ]

    // Mark estimation sample
    marksample touse
    markout `touse' `decompose'

    // Validate type option
    if "`type'" == "" local type "fnardl"
    local type = lower("`type'")
    if !inlist("`type'", "fnardl", "fbnardl") {
        di as err "type() must be {bf:fnardl} or {bf:fbnardl}"
        exit 198
    }

    // Validate IC
    if "`ic'" == "" local ic "aic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be {bf:aic} or {bf:bic}"
        exit 198
    }

    // Validate maxlag
    if `maxlag' < 1 | `maxlag' > 12 {
        di as err "maxlag() must be between 1 and 12"
        exit 198
    }

    // Validate maxk
    if `maxk' < 0.1 & "`nofourier'" == "" {
        di as err "maxk() must be >= 0.1"
        exit 198
    }

    // Validate bootstrap method and marginal DGP
    if "`bootstrap'" == "" local bootstrap "bvz"
    local bootstrap = lower("`bootstrap'")
    if "`bootstrap'" == "msg" local bootstrap "mcnown"
    if !inlist("`bootstrap'", "bvz", "mcnown") {
        di as err "bootstrap() must be {bf:bvz} or {bf:mcnown}"
        exit 198
    }
    if "`xdgp'" == "" local xdgp "rw"
    local xdgp = lower("`xdgp'")
    if !inlist("`xdgp'", "rw", "vecm") {
        di as err "xdgp() must be {bf:rw} or {bf:vecm}"
        exit 198
    }
    if `reps' < 99 & "`type'" == "fbnardl" {
        di as txt "note: reps(`reps') is low; 999 or more is recommended for inference"
    }

    // -------------------------------------------------------------------------
    // Validate hac() — covariance matrix estimator for inference
    //   hetero : White (1980) HC1  — heteroskedasticity only
    //   auto   : Newey-West HAC    — autocorrelation (also robust to hetero)
    //   both   : Newey-West HAC    — heteroskedasticity AND autocorrelation
    // -------------------------------------------------------------------------
    local hac = lower(strtrim("`hac'"))
    if inlist("`hac'", "", "none", "no", "ols", "iid") {
        local vcetype "ols"
    }
    else if inlist("`hac'", "het", "hetero", "heteroskedastic", "heteroskedasticity", "robust", "white", "hc1") {
        local vcetype "robust"
    }
    else if inlist("`hac'", "auto", "ac", "autocorr", "autocorrelation", "serial") {
        local vcetype "hac"
    }
    else if inlist("`hac'", "both", "hac", "nw", "newey", "neweywest", "newey-west") {
        local vcetype "hac"
    }
    else {
        di as err "hac() must be {bf:hetero}, {bf:auto}, {bf:both}, or {bf:none}"
        di as err "  hetero : heteroskedasticity-robust (White 1980, HC1)"
        di as err "  auto   : autocorrelation-robust (Newey-West 1987 HAC)"
        di as err "  both   : heteroskedasticity- and autocorrelation-robust (HAC)"
        exit 198
    }
    if `haclags' < -1 {
        di as err "haclags() must be a non-negative integer (or omitted for automatic)"
        exit 198
    }

    // =========================================================================
    // 2. PARSE VARIABLE LISTS
    // =========================================================================
    // depvar = first variable in varlist
    // controls = remaining variables in varlist (non-decomposed regressors)
    gettoken depvar controls : varlist

    // The bootstrap engine and the partial-sum construction address the
    // variables by name, so the dependent variable and the controls must be
    // ordinary variables (generate a transformed variable first if needed).
    foreach v in `depvar' `controls' {
        if strpos("`v'", ".") | strpos("`v'", "#") {
            di as err "{bf:`v'}: the dependent variable and the controls must be plain"
            di as err "variable names; generate the transformed variable first"
            exit 198
        }
    }

    local ndec : word count `decompose'
    local nctrl : word count `controls'
    local nindep = `ndec' + `nctrl'

    // -------------------------------------------------------------------------
    // Fixed (exogenous) regressors — fixed() is a synonym for exog()
    // -------------------------------------------------------------------------
    if "`fixed'" != "" {
        local exog "`exog' `fixed'"
    }
    local exog = stritrim(strtrim("`exog'"))
    local exogbase ""
    if "`exog'" != "" {
        qui fvrevar `exog', list
        local exogbase "`r(varlist)'"
        qui fvrevar `depvar' `controls' `decompose', list
        local modelbase "`r(varlist)'"
        foreach v of local exogbase {
            if `: list v in modelbase' {
                di as err "exog(): {bf:`v'} is already the dependent variable, a control or"
                di as err "        a decomposed variable (a fixed regressor must be a separate"
                di as err "        variable such as a dummy)"
                exit 198
            }
            if strpos("`v'", "_fbnardl_") == 1 {
                di as err "exog(): names starting with _fbnardl_ are reserved"
                exit 198
            }
        }
        markout `touse' `exogbase'
    }

    // Confirm time series
    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    local tdelta   = r(tdelta)
    if "`panelvar'" != "" {
        di as err "fbnardl is designed for time-series data only, not panel data"
        exit 198
    }

    // The recursive bootstrap, the Newey-West estimator and the recursive
    // residuals all need a gap-free sample, so refuse rather than return
    // silently wrong numbers.
    qui count if `touse'
    local T0 = r(N)
    if `T0' < 30 {
        di as err "Too few observations (`T0'). Need at least 30."
        exit 2001
    }
    qui summarize `timevar' if `touse', meanonly
    local expect = (r(max) - r(min))/`tdelta' + 1
    if abs(`T0' - `expect') > 1e-6 {
        di as err "the estimation sample has internal gaps or missing values"
        di as err "(`T0' usable observations spanning `expect' periods)."
        di as err "fbnardl requires a contiguous sample; fix the gaps or restrict"
        di as err "the sample with if/in to a gap-free window."
        exit 459
    }

    // e(sample) for the final model: the marked sample minus the first
    // maxlag+1 observations, which are lost to the lags. Every candidate
    // model is estimated on this same sample so the information criteria
    // are comparable across candidates.
    tempvar esamp cnt
    qui gen long `cnt' = sum(`touse')
    qui gen byte `esamp' = `touse' & `cnt' > `maxlag' + 1

    // =========================================================================
    // 3. PRESERVE & PREPARE DATA
    // =========================================================================
    preserve

    // Keep estimation sample
    qui keep if `touse'
    qui count
    local nobs = r(N)

    // Generate time index
    tempvar tindex
    qui gen `tindex' = _n
    local eif "if `tindex' > `maxlag' + 1"

    // A fixed regressor that is constant on the sample is almost always a
    // dummy built with the wrong date format (period >= 2020 instead of
    // period >= tm(2020m3)); refuse it rather than let regress drop it.
    foreach v of local exogbase {
        qui summarize `v', meanonly
        if r(min) == r(max) {
            di as err "exog(): {bf:`v'} is constant on the estimation sample"
            di as err "        (a dummy must switch between 0 and 1 inside the sample;"
            di as err "         check the date condition used to build it)"
            exit 198
        }
    }

    // Materialise the fixed regressors as plain variables (the Mata
    // bootstrap engine reads them by name) and expand them to coefficient
    // names for the tables. Both lists are in the same order.
    local exogexp ""
    local exogplain ""
    if "`exog'" != "" {
        qui fvrevar `exog'
        local exogplain "`r(varlist)'"
        capture fvexpand `exog'
        if _rc == 0 local exogexp "`r(varlist)'"
        else        local exogexp "`exog'"
    }

    // -------------------------------------------------------------------------
    // Covariance matrix estimator
    // -------------------------------------------------------------------------
    if "`vcetype'" == "robust" {
        local estcmd   "regress"
        local estopt   "vce(robust)"
        local vcelabel "Heteroskedasticity-robust (White 1980, HC1)"
        local vceshort "HC1 robust"
        local vcode 1
        local nwlag 0
    }
    else if "`vcetype'" == "hac" {
        // Newey & West (1987) Bartlett kernel.
        // Automatic bandwidth: floor(4*(T/100)^(2/9))  (Newey & West 1994)
        local Tuse = `nobs' - `maxlag' - 1
        if `haclags' < 0 {
            local nwlag = floor(4 * (`Tuse' / 100)^(2/9))
            if `nwlag' < 1 local nwlag = 1
        }
        else {
            local nwlag = `haclags'
        }
        local estcmd   "newey"
        local estopt   "lag(`nwlag')"
        local vcelabel "HAC Newey-West (1987), Bartlett kernel, lag = `nwlag'"
        local vceshort "HAC (NW, lag `nwlag')"
        local vcode 2
    }
    else {
        local estcmd   "regress"
        local estopt   ""
        local vcelabel "Conventional OLS (i.i.d. errors)"
        local vceshort "OLS"
        local vcode 0
        local nwlag 0
    }
    local vceclause ""
    if "`estopt'" != "" local vceclause ", `estopt'"

    // =========================================================================
    // 4. DECOMPOSE VARIABLES INTO POSITIVE / NEGATIVE PARTIAL SUMS
    // =========================================================================
    local dec_pos_vars ""
    local dec_neg_vars ""
    local dec_names ""

    foreach xvar of local decompose {
        // Get clean variable name
        local cname = subinstr("`xvar'", ".", "_", .)

        tempvar dx_`cname' xpos_`cname' xneg_`cname'

        // First difference
        qui gen double `dx_`cname'' = D.`xvar'

        // Positive partial sum: cumsum of max(dx, 0)
        qui gen double `xpos_`cname'' = 0
        qui replace `xpos_`cname'' = max(`dx_`cname'', 0) if `dx_`cname'' != .
        qui replace `xpos_`cname'' = sum(`xpos_`cname'')

        // Negative partial sum: cumsum of min(dx, 0)
        qui gen double `xneg_`cname'' = 0
        qui replace `xneg_`cname'' = min(`dx_`cname'', 0) if `dx_`cname'' != .
        qui replace `xneg_`cname'' = sum(`xneg_`cname'')

        // Rename for clarity in output
        local pname "`cname'_pos"
        local nname "`cname'_neg"
        capture confirm variable `pname'
        if _rc == 0 qui drop `pname'
        capture confirm variable `nname'
        if _rc == 0 qui drop `nname'
        qui rename `xpos_`cname'' `pname'
        qui rename `xneg_`cname'' `nname'

        local dec_pos_vars "`dec_pos_vars' `pname'"
        local dec_neg_vars "`dec_neg_vars' `nname'"
        local dec_names "`dec_names' `cname'"
    }

    // =========================================================================
    // 5. HEADER
    // =========================================================================
    di as txt ""
    di as txt "{hline 70}"
    if "`type'" == "fbnardl" {
        di as res "  Fourier Bootstrap NARDL (FBNARDL) Estimation"
    }
    else {
        di as res "  Fourier NARDL (FNARDL) Estimation"
    }
    di as txt "{hline 70}"
    di as txt "  Dependent variable : " as res "`depvar'"
    di as txt "  Decomposed var(s)  : " as res "`decompose'"
    if `nctrl' > 0 {
        di as txt "  Control var(s)     : " as res "`controls'"
    }
    if "`exog'" != "" {
        di as txt "  Fixed regressor(s) : " as res "`exog'"
    }
    di as txt "  Max lag (p,q,r)    : " as res "`maxlag'"
    if "`nofourier'" == "" {
        di as txt "  Max Fourier freq   : " as res "`maxk'"
    }
    di as txt "  Info criterion     : " as res upper("`ic'")
    di as txt "  Observations       : " as res "`=`nobs' - `maxlag' - 1'" ///
       as txt " of `nobs' (maxlag = `maxlag')"
    di as txt "  Std. errors        : " as res "`vcelabel'"
    if "`type'" == "fbnardl" {
        local bm "Bertelli, Vacca & Zoia (2022) conditional"
        if "`bootstrap'" == "mcnown" local bm "McNown, Sam & Goh (2018) unconditional"
        di as txt "  Bootstrap          : " as res "`bm'"
        di as txt "  Replications       : " as res "`reps'"
        local xd "unit root imposed on x (rw)"
        if "`xdgp'" == "vecm" local xd "estimated marginal VECM for x"
        di as txt "  Marginal x process : " as res "`xd'"
    }
    di as txt "{hline 70}"
    di as txt ""
    di as txt "  Searching for optimal model..."

    // Build Fourier frequency grid
    if "`nofourier'" != "" {
        local nkgrid = 1
        tempname kgrid
        mat `kgrid' = J(1, 1, 0)
    }
    else {
        local nkgrid = floor(`maxk' / 0.1 + 1e-8)
        tempname kgrid
        mat `kgrid' = J(1, `nkgrid', 0)
        forvalues j = 1/`nkgrid' {
            mat `kgrid'[1, `j'] = `j' * 0.1
        }
    }

    tempname best_ic_val
    scalar `best_ic_val' = .

    local best_p = 1
    local best_kstar = 0
    local best_formula ""
    local total_models = 0

    forvalues i = 1/`ndec' {
        local best_q_`i' = 0
    }
    if `nctrl' > 0 {
        forvalues i = 1/`nctrl' {
            local best_r_`i' = 0
        }
    }

    // =========================================================================
    // STEP 1: Select optimal Fourier frequency k* by minimum SSR
    //   (Yilanci, Bozoklu & Gorus 2020): for each candidate k*, estimate the
    //   maximal model and record the SSR; the smallest SSR wins.
    // =========================================================================
    di as txt "  Step 1: Selecting k* by minimum SSR (Yilanci et al. 2020)..."

    tempname best_ssr_k ssr_matrix
    scalar `best_ssr_k' = .
    mat `ssr_matrix' = J(`nkgrid', 2, .)

    forvalues kidx = 1/`nkgrid' {
        local kval = `kgrid'[1, `kidx']
        mat `ssr_matrix'[`kidx', 1] = `kval'

        if `kval' > 0 {
            capture drop _fbnardl_sin _fbnardl_cos
            qui gen double _fbnardl_sin = sin(2 * c(pi) * `kval' * `tindex' / `nobs')
            qui gen double _fbnardl_cos = cos(2 * c(pi) * `kval' * `tindex' / `nobs')
        }

        // Build maximal model: p=maxlag, all q=maxlag, all r=maxlag
        local regvars_max ""
        forvalues j = 1/`maxlag' {
            local regvars_max "`regvars_max' L`j'.D.`depvar'"
        }
        foreach cname of local dec_names {
            forvalues j = 0/`maxlag' {
                if `j' == 0 {
                    local regvars_max "`regvars_max' D.`cname'_pos D.`cname'_neg"
                }
                else {
                    local regvars_max "`regvars_max' L`j'.D.`cname'_pos L`j'.D.`cname'_neg"
                }
            }
        }
        if `nctrl' > 0 {
            foreach cvar of local controls {
                forvalues j = 0/`maxlag' {
                    if `j' == 0 {
                        local regvars_max "`regvars_max' D.`cvar'"
                    }
                    else {
                        local regvars_max "`regvars_max' L`j'.D.`cvar'"
                    }
                }
            }
        }
        local regvars_max "`regvars_max' L.`depvar'"
        foreach cname of local dec_names {
            local regvars_max "`regvars_max' L.`cname'_pos L.`cname'_neg"
        }
        foreach cvar of local controls {
            local regvars_max "`regvars_max' L.`cvar'"
        }
        if `kval' > 0 {
            local regvars_max "`regvars_max' _fbnardl_sin _fbnardl_cos"
        }
        // Fixed regressors enter every candidate model
        if "`exog'" != "" {
            local regvars_max "`regvars_max' `exog'"
        }

        capture qui regress D.`depvar' `regvars_max' `eif'
        if _rc != 0 {
            mat `ssr_matrix'[`kidx', 2] = .
            continue
        }

        local this_ssr_k = e(rss)
        mat `ssr_matrix'[`kidx', 2] = `this_ssr_k'

        if `this_ssr_k' < scalar(`best_ssr_k') | missing(scalar(`best_ssr_k')) {
            scalar `best_ssr_k' = `this_ssr_k'
            local best_kstar = `kval'
        }
    }

    if missing(scalar(`best_ssr_k')) {
        di as err "the maximal model could not be estimated; reduce maxlag() or check the data"
        exit 498
    }
    di as txt "  Optimal k* = " as res "`best_kstar'" as txt " (min SSR = " as res %10.4f scalar(`best_ssr_k') as txt ")"

    // =========================================================================
    // GRAPH: SSR vs k* (Fourier frequency selection)
    // =========================================================================
    if `nkgrid' > 1 {
        mat _fbnardl_ssr_k = `ssr_matrix'

        tempfile _fbnardl_tmpdata
        qui save `_fbnardl_tmpdata', replace

        capture noisily {
            qui clear
            qui set obs `nkgrid'
            qui gen double kstar = .
            qui gen double ssr = .

            forvalues kidx = 1/`nkgrid' {
                qui replace kstar = el(_fbnardl_ssr_k, `kidx', 1) in `kidx'
                qui replace ssr   = el(_fbnardl_ssr_k, `kidx', 2) in `kidx'
            }
            qui gen double ssr_opt = ssr if abs(kstar - `best_kstar') < 0.001

            twoway (connected ssr kstar, lcolor(navy) mcolor(navy) ///
                    msize(small) msymbol(circle) lwidth(medthick)) ///
                   (scatter ssr_opt kstar, mcolor(cranberry) msize(large) ///
                    msymbol(diamond)), ///
                   title("Fourier Frequency Selection", size(medium)) ///
                   subtitle("SSR by k* {&mdash} Yilanci et al. (2020)", size(small)) ///
                   ytitle("Sum of Squared Residuals (SSR)", size(small)) ///
                   xtitle("Fourier Frequency (k*)", size(small)) ///
                   xline(`best_kstar', lcolor(cranberry) lpattern(dash) lwidth(thin)) ///
                   legend(order(1 "SSR" 2 "Optimal k* = `best_kstar'") ///
                          size(small) rows(1)) ///
                   note("fbnardl — Step 1: k* selected by min SSR", size(vsmall)) ///
                   scheme(s2color) name(kstar_selection, replace)

            qui graph export "kstar_selection.png", replace width(1200)
            di as txt "  Graph saved: kstar_selection.png"
        }

        qui use `_fbnardl_tmpdata', clear
        capture mat drop _fbnardl_ssr_k
    }

    // =========================================================================
    // STEP 2: Select optimal lags (p, q, r) by AIC/BIC with fixed k*
    //   Full grid search; every candidate is estimated on the SAME sample
    //   (the first maxlag+1 observations are dropped for all of them).
    // =========================================================================
    di as txt "  Step 2: Selecting (p, q, r) by " upper("`ic'") " with fixed k*..."

    if `best_kstar' > 0 {
        capture drop _fbnardl_sin _fbnardl_cos
        qui gen double _fbnardl_sin = sin(2 * c(pi) * `best_kstar' * `tindex' / `nobs')
        qui gen double _fbnardl_cos = cos(2 * c(pi) * `best_kstar' * `tindex' / `nobs')
    }

    forvalues p = 1/`maxlag' {

        local n_indep = `ndec' + `nctrl'
        local n_combos = 1
        forvalues vi = 1/`n_indep' {
            local n_combos = `n_combos' * (`maxlag' + 1)
        }

        local combo_max = `n_combos' - 1
        forvalues combo = 0/`combo_max' {

            local total_models = `total_models' + 1

            // Decode combo index into variable-specific lags
            local remainder = `combo'
            forvalues di = 1/`ndec' {
                local divisor = 1
                local remaining_vars = `n_indep' - `di'
                if `remaining_vars' > 0 {
                    forvalues rv = 1/`remaining_vars' {
                        local divisor = `divisor' * (`maxlag' + 1)
                    }
                }
                local cur_q_`di' = floor(`remainder' / `divisor')
                local remainder = `remainder' - `cur_q_`di'' * `divisor'
            }
            if `nctrl' > 0 {
                forvalues ci = 1/`nctrl' {
                    local di2 = `ndec' + `ci'
                    local divisor = 1
                    local remaining_vars = `n_indep' - `di2'
                    if `remaining_vars' > 0 {
                        forvalues rv = 1/`remaining_vars' {
                            local divisor = `divisor' * (`maxlag' + 1)
                        }
                    }
                    local cur_r_`ci' = floor(`remainder' / `divisor')
                    local remainder = `remainder' - `cur_r_`ci'' * `divisor'
                }
            }

            // Build regression formula
            local regvars ""
            forvalues j = 1/`p' {
                local regvars "`regvars' L`j'.D.`depvar'"
            }
            local dec_i = 0
            foreach cname of local dec_names {
                local dec_i = `dec_i' + 1
                local qi = `cur_q_`dec_i''
                forvalues j = 0/`qi' {
                    if `j' == 0 {
                        local regvars "`regvars' D.`cname'_pos D.`cname'_neg"
                    }
                    else {
                        local regvars "`regvars' L`j'.D.`cname'_pos L`j'.D.`cname'_neg"
                    }
                }
            }
            if `nctrl' > 0 {
                local ctrl_i = 0
                foreach cvar of local controls {
                    local ctrl_i = `ctrl_i' + 1
                    local rj = `cur_r_`ctrl_i''
                    forvalues j = 0/`rj' {
                        if `j' == 0 {
                            local regvars "`regvars' D.`cvar'"
                        }
                        else {
                            local regvars "`regvars' L`j'.D.`cvar'"
                        }
                    }
                }
            }
            local regvars "`regvars' L.`depvar'"
            foreach cname of local dec_names {
                local regvars "`regvars' L.`cname'_pos L.`cname'_neg"
            }
            foreach cvar of local controls {
                local regvars "`regvars' L.`cvar'"
            }
            if `best_kstar' > 0 {
                local regvars "`regvars' _fbnardl_sin _fbnardl_cos"
            }
            if "`exog'" != "" {
                local regvars "`regvars' `exog'"
            }

            capture qui regress D.`depvar' `regvars' `eif'
            if _rc != 0 continue
            if e(N) < e(df_m) + 10 continue

            local this_n = e(N)
            local this_k = e(df_m) + 1
            local this_ssr = e(rss)

            if "`ic'" == "aic" {
                local this_ic = `this_n' * ln(`this_ssr'/`this_n') + 2 * `this_k'
            }
            else {
                local this_ic = `this_n' * ln(`this_ssr'/`this_n') + `this_k' * ln(`this_n')
            }

            if `this_ic' < scalar(`best_ic_val') | missing(scalar(`best_ic_val')) {
                scalar `best_ic_val' = `this_ic'
                local best_p = `p'
                local best_formula "`regvars'"
                forvalues di = 1/`ndec' {
                    local best_q_`di' = `cur_q_`di''
                }
                if `nctrl' > 0 {
                    forvalues ci = 1/`nctrl' {
                        local best_r_`ci' = `cur_r_`ci''
                    }
                }
            }
        } // end combo loop
    } // end p loop

    if missing(scalar(`best_ic_val')) {
        di as err "no NARDL model could be estimated; check the data and maxlag()"
        exit 498
    }

    di as txt "  Models evaluated   : " as res "`total_models'"
    di as txt "  Best " upper("`ic'") "          : " as res %10.4f scalar(`best_ic_val')
    di as txt ""

    // =========================================================================
    // 6. RE-ESTIMATE BEST MODEL & STORE RESULTS
    // =========================================================================
    if `best_kstar' > 0 {
        capture drop _fbnardl_sin _fbnardl_cos
        qui gen double _fbnardl_sin = sin(2 * c(pi) * `best_kstar' * `tindex' / `nobs')
        qui gen double _fbnardl_cos = cos(2 * c(pi) * `best_kstar' * `tindex' / `nobs')
    }

    // ---- stage 1: OLS fit. Goodness of fit, residuals and the estat-based
    //      diagnostics all come from here (point estimates are the same
    //      under every covariance estimator).
    qui regress D.`depvar' `best_formula' `eif'
    estimates store _fbnardl_ols

    local nobs_used = e(N)
    local nparams = e(df_m) + 1
    local df_m = e(df_m)
    local df_r = e(df_r)
    local r2 = e(r2)
    local r2_adj = e(r2_a)
    local ssr = e(rss)
    local sig2 = e(rss) / e(df_r)
    local loglik = e(ll)
    local rmse = e(rmse)
    local aic_val = `nobs_used' * ln(`ssr'/`nobs_used') + 2 * `nparams'
    local bic_val = `nobs_used' * ln(`ssr'/`nobs_used') + `nparams' * ln(`nobs_used')

    capture drop _fbnardl_resid
    qui predict double _fbnardl_resid, residuals
    tempvar resid yhat
    qui gen double `resid' = _fbnardl_resid
    qui predict double `yhat', xb

    // ---- stage 2: the requested covariance estimator. Everything that
    //      reports a standard error, t statistic, p-value or Wald test
    //      (Tables 2-5 and the bootstrap statistics) uses this fit.
    if "`vcetype'" != "ols" {
        capture qui `estcmd' D.`depvar' `best_formula' `eif' `vceclause'
        if _rc != 0 {
            di as err "  Warning: `estcmd' `estopt' failed (rc = " _rc "); falling back to OLS standard errors."
            qui regress D.`depvar' `best_formula' `eif'
            local vcetype  "ols"
            local estcmd   "regress"
            local estopt   ""
            local vceclause ""
            local vcelabel "Conventional OLS (i.i.d. errors)"
            local vceshort "OLS"
            local vcode 0
        }
    }
    estimates store _fbnardl_main

    local fstat = e(F)
    local fstat_p = Ftail(`df_m', `df_r', `fstat')

    tempname b_full V_full
    mat `b_full' = e(b)
    mat `V_full' = e(V)

    // Fixed regressors actually estimated (omitted / base levels are skipped)
    local nexog_est = 0
    local exogkeep ""
    local exogdrop ""
    local exogboot ""
    local ie = 0
    foreach v of local exogexp {
        local ie = `ie' + 1
        capture local ese = _se[`v']
        if _rc == 0 {
            if `ese' > 0 & `ese' < . {
                local nexog_est = `nexog_est' + 1
                local exogkeep "`exogkeep' `v'"
                local pv : word `ie' of `exogplain'
                local exogboot "`exogboot' `pv'"
            }
            else if !strpos("`v'", "b.") {
                local exogdrop "`exogdrop' `v'"
            }
        }
    }
    if "`exogdrop'" != "" {
        di as txt "  note: fixed regressor(s)`exogdrop' omitted as constant or collinear"
        di as txt "        on the estimation sample (which starts maxlag+1 periods in)."
        di as txt ""
    }

    // =========================================================================
    // 7. DISPLAY — TABLE 1: MODEL SELECTION
    // =========================================================================
    di as txt "{hline 70}"
    di as res "  Table 1: Model Selection"
    di as txt "{hline 70}"
    di as txt "  Selected lag p (depvar lags)       : " as res `best_p'
    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        di as txt "  Selected lag q (`cname' lags)" _col(40) ": " as res `best_q_`dec_i''
    }
    if `nctrl' > 0 {
        forvalues i = 1/`nctrl' {
            local cvar : word `i' of `controls'
            di as txt "  Selected lag r (`cvar' lags)"  _col(40) ": " as res `best_r_`i''
        }
    }
    if "`nofourier'" == "" {
        di as txt "  Selected Fourier frequency (k*)    : " as res %6.2f `best_kstar'
    }
    if "`exog'" != "" {
        di as txt "  Fixed regressors (estimated)       : " as res `nexog_est'
    }
    di as txt "  Standard errors                    : " as res "`vceshort'"
    di as txt "  Information criterion (" upper("`ic'") ")     : " as res %12.4f scalar(`best_ic_val')
    di as txt "  AIC                               : " as res %12.4f `aic_val'
    di as txt "  BIC                               : " as res %12.4f `bic_val'
    di as txt "  Log-likelihood                     : " as res %12.4f `loglik'
    di as txt "  Observations (used)                : " as res `nobs_used'
    di as txt "  R-squared                          : " as res %8.4f `r2'
    di as txt "  Adjusted R-squared                 : " as res %8.4f `r2_adj'
    di as txt "  F-statistic                        : " as res %8.4f `fstat' " (p=" %6.4f `fstat_p' ")"
    di as txt "{hline 70}"
    di as txt ""

    // =========================================================================
    // 8. DISPLAY — TABLE 2: STRUCTURED ESTIMATION RESULTS
    // =========================================================================
    if "`notable'" == "" {
        di as txt "{hline 78}"
        di as res "  Table 2: Estimation Results (Dependent Variable: D.`depvar')"
        di as txt _col(3) "{it:Standard errors: `vcelabel'}"
        di as txt "{hline 78}"
        di as txt _col(3) "Variable" _col(25) "Coef." _col(38) "Std.Err." _col(51) "t-stat" _col(63) "p-value"
        di as txt "{hline 78}"

        // Panel A: Short-Run Dynamics
        di as res "  Panel A: Short-Run Dynamics"
        di as txt "{hline 78}"

        di as txt _col(3) "{it:Lagged D.`depvar'}"
        forvalues j = 1/`best_p' {
            local vname "L`j'.D.`depvar'"
            _fbnardl_row "`vname'" "L`j'.D.`depvar'" `df_r'
        }

        local dec_i = 0
        foreach cname of local dec_names {
            di as txt ""
            local dec_i = `dec_i' + 1
            local this_q = `best_q_`dec_i''
            di as txt _col(3) "{it:D.`cname' (decomposed, lag q=`this_q')}"
            forvalues j = 0/`this_q' {
                if `j' == 0 {
                    _fbnardl_row "D.`cname'_pos" "D.`cname'_pos" `df_r'
                    _fbnardl_row "D.`cname'_neg" "D.`cname'_neg" `df_r'
                }
                else {
                    _fbnardl_row "L`j'.D.`cname'_pos" "L`j'.D.`cname'_pos" `df_r'
                    _fbnardl_row "L`j'.D.`cname'_neg" "L`j'.D.`cname'_neg" `df_r'
                }
            }
        }

        if `nctrl' > 0 {
            local ctrl_i = 0
            foreach cvar of local controls {
                local ctrl_i = `ctrl_i' + 1
                local this_r = `best_r_`ctrl_i''
                di as txt ""
                di as txt _col(3) "{it:D.`cvar' (control, lag r=`this_r')}"
                forvalues j = 0/`this_r' {
                    if `j' == 0 _fbnardl_row "D.`cvar'" "D.`cvar'" `df_r'
                    else        _fbnardl_row "L`j'.D.`cvar'" "L`j'.D.`cvar'" `df_r'
                }
            }
        }

        // Panel B: Long-Run / ECM Level Coefficients
        di as txt ""
        di as txt "{hline 78}"
        di as res "  Panel B: Long-Run (ECM Level) Coefficients"
        di as txt "{hline 78}"

        _fbnardl_row "L.`depvar'" "L.`depvar' (ECM)" `df_r'
        foreach cname of local dec_names {
            _fbnardl_row "L.`cname'_pos" "L.`cname'_pos" `df_r'
            _fbnardl_row "L.`cname'_neg" "L.`cname'_neg" `df_r'
        }
        foreach cvar of local controls {
            _fbnardl_row "L.`cvar'" "L.`cvar'" `df_r'
        }

        // Panel C: Fixed (exogenous) regressors
        if "`exogkeep'" != "" {
            di as txt ""
            di as txt "{hline 78}"
            di as res "  Panel C: FIXED — Fixed (Exogenous) Regressors" ///
               as txt "  {it:(excluded from the long-run relationship)}"
            di as txt "{hline 78}"
            foreach v of local exogkeep {
                _fbnardl_row "`v'" "`v'" `df_r'
            }
        }

        // Panel D: Fourier Terms & Constant
        di as txt ""
        di as txt "{hline 78}"
        if "`nofourier'" == "" & `best_kstar' > 0 {
            di as res "  Panel D: Fourier Terms (k* = " %4.1f `best_kstar' ") & Constant"
            di as txt "{hline 78}"
            _fbnardl_row "_fbnardl_sin" "sin(2*pi*k*t/T)" `df_r'
            _fbnardl_row "_fbnardl_cos" "cos(2*pi*k*t/T)" `df_r'
        }
        else {
            di as res "  Panel D: Constant"
            di as txt "{hline 78}"
        }
        _fbnardl_row "_cons" "_cons" `df_r'
        di as txt "{hline 78}"

        // Lag Selection Summary & Model Specification
        di as txt ""
        di as txt "{hline 78}"
        di as res "  Lag Selection Summary"
        di as txt "{hline 78}"

        local lag_vec ""
        local dec_i = 0
        foreach cname of local dec_names {
            local dec_i = `dec_i' + 1
            local lag_vec "`lag_vec', `best_q_`dec_i''"
        }
        if `nctrl' > 0 {
            forvalues i = 1/`nctrl' {
                local lag_vec "`lag_vec', `best_r_`i''"
            }
        }
        if "`nofourier'" == "" {
            di as res _col(5) "Model: FNARDL(`best_p'`lag_vec')    k* = " %4.1f `best_kstar'
        }
        else {
            di as res _col(5) "Model: NARDL(`best_p'`lag_vec')"
        }
        di as txt ""
        di as txt _col(5) "p = " as res `best_p' as txt "  (dep. var lags)     L1.D.`depvar'" _c
        if `best_p' > 1 di as txt " ... L`best_p'.D.`depvar'"
        else            di as txt ""
        local dec_i = 0
        foreach cname of local dec_names {
            local dec_i = `dec_i' + 1
            local qi = `best_q_`dec_i''
            di as txt _col(5) "q`dec_i'= " as res `qi' as txt "  (`cname' lags)   D.`cname'+/-" _c
            if `qi' > 0 di as txt " ... L`qi'.D.`cname'+/-"
            else        di as txt ""
        }
        if `nctrl' > 0 {
            local ctrl_i = 0
            foreach cvar of local controls {
                local ctrl_i = `ctrl_i' + 1
                local this_r = `best_r_`ctrl_i''
                di as txt _col(5) "r = " as res `this_r' as txt "  (`cvar' lags)   D.`cvar'" _c
                if `this_r' > 0 di as txt " ... L`this_r'.D.`cvar'"
                else            di as txt ""
            }
        }
        if "`nofourier'" == "" {
            di as txt _col(5) "k*= " as res %4.1f `best_kstar' as txt "  (Fourier freq)      sin(2*pi*k*t/T), cos(2*pi*k*t/T)"
        }
        if "`exogkeep'" != "" {
            di as txt _col(5) "fixed regressors:  " as res "`exogkeep'"
        }

        // Explicit Equation Display
        di as txt ""
        di as txt "{hline 78}"
        di as res "  Estimated Equation"
        di as txt "{hline 78}"
        di as txt ""
        di as txt _col(5) "D.`depvar' =" _c
        local first_term = 1
        forvalues j = 1/`best_p' {
            if `first_term' {
                di as txt " " as res "L`j'.D.`depvar'" _c
                local first_term = 0
            }
            else {
                di as txt " + " as res "L`j'.D.`depvar'" _c
            }
        }
        di as txt ""
        local dec_i = 0
        foreach cname of local dec_names {
            local dec_i = `dec_i' + 1
            local qi = `best_q_`dec_i''
            forvalues j = 0/`qi' {
                if `j' == 0 {
                    di as txt _col(16) "+ " as res "D.`cname'_pos" as txt " + " as res "D.`cname'_neg" _c
                }
                else {
                    di as txt " + " as res "L`j'.D.`cname'_pos" as txt " + " as res "L`j'.D.`cname'_neg" _c
                }
            }
            di as txt ""
        }
        if `nctrl' > 0 {
            local ctrl_i = 0
            foreach cvar of local controls {
                local ctrl_i = `ctrl_i' + 1
                local this_r = `best_r_`ctrl_i''
                di as txt _col(16) "+ " _c
                forvalues j = 0/`this_r' {
                    if `j' == 0 di as res "D.`cvar'" _c
                    else        di as txt " + " as res "L`j'.D.`cvar'" _c
                }
                di as txt ""
            }
        }
        di as txt _col(16) "+ " as res "L.`depvar'" as txt " (ECM)" _c
        foreach cname of local dec_names {
            di as txt " + " as res "L.`cname'_pos" as txt " + " as res "L.`cname'_neg" _c
        }
        foreach cvar of local controls {
            di as txt " + " as res "L.`cvar'" _c
        }
        di as txt ""
        if "`nofourier'" == "" & `best_kstar' > 0 {
            di as txt _col(16) "+ " as res "sin(2*pi*`best_kstar'*t/T)" as txt " + " as res "cos(2*pi*`best_kstar'*t/T)"
        }
        if "`exogkeep'" != "" {
            di as txt _col(16) "+ " _c
            local first_term = 1
            foreach v of local exogkeep {
                if `first_term' {
                    di as res "`v'" _c
                    local first_term = 0
                }
                else {
                    di as txt " + " as res "`v'" _c
                }
            }
            di as txt "   (fixed)"
        }
        di as txt _col(16) "+ " as res "constant"
        di as txt ""
        di as txt "{hline 78}"
        di as txt ""
        di as txt "  Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1"
        di as txt "{hline 78}"
        di as txt ""
    }

    // =========================================================================
    // 9. SHORT-RUN & LONG-RUN MULTIPLIERS
    // =========================================================================
    di as txt "{hline 70}"
    di as res "  Table 3: Short-Run & Long-Run Multipliers"
    di as txt "{hline 70}"

    local ecm_coef_name "L.`depvar'"
    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        local this_q = `best_q_`dec_i''
        local lpos_name "L.`cname'_pos"
        local lneg_name "L.`cname'_neg"

        // Short-run multipliers = sum of the D.x coefficients across lags
        local sr_pos = 0
        local sr_neg = 0
        forvalues j = 0/`this_q' {
            if `j' == 0 {
                capture local tmp_p = _b[D.`cname'_pos]
                if _rc == 0 local sr_pos = `sr_pos' + `tmp_p'
                capture local tmp_n = _b[D.`cname'_neg]
                if _rc == 0 local sr_neg = `sr_neg' + `tmp_n'
            }
            else {
                capture local tmp_p = _b[L`j'.D.`cname'_pos]
                if _rc == 0 local sr_pos = `sr_pos' + `tmp_p'
                capture local tmp_n = _b[L`j'.D.`cname'_neg]
                if _rc == 0 local sr_neg = `sr_neg' + `tmp_n'
            }
        }

        // Long run by the delta method: LR = -beta(L.x) / beta(L.y)
        local saved_df_r = e(df_r)
        capture qui nlcom ///
            (LR_pos: -_b[`lpos_name'] / _b[`ecm_coef_name']) ///
            (LR_neg: -_b[`lneg_name'] / _b[`ecm_coef_name']), ///
            level(`level') post

        if _rc == 0 {
            tempname lr_b lr_V
            mat `lr_b' = e(b)
            mat `lr_V' = e(V)
            local lr_pos = `lr_b'[1,1]
            local lr_neg = `lr_b'[1,2]
            local lr_pos_se = sqrt(`lr_V'[1,1])
            local lr_neg_se = sqrt(`lr_V'[2,2])
            local lr_pos_t = `lr_pos' / `lr_pos_se'
            local lr_neg_t = `lr_neg' / `lr_neg_se'
            local lr_pos_p = 2 * ttail(`saved_df_r', abs(`lr_pos_t'))
            local lr_neg_p = 2 * ttail(`saved_df_r', abs(`lr_neg_t'))

            di as txt ""
            di as txt "  Variable: `cname' (decomposed)"
            di as txt "  {hline 68}"
            di as txt "  " _col(5) "Component" _col(20) "Estimate" _col(32) "Std.Err." _col(44) "t-stat" _col(54) "p-value"
            di as txt "  {hline 68}"
            di as res "  " _col(5) "Short-Run (+)" _col(18) %10.4f `sr_pos'
            di as res "  " _col(5) "Short-Run (-)" _col(18) %10.4f `sr_neg'
            di as txt "  " _col(5) "{hline 58}"
            di as txt "  " _col(5) "Long-Run  (+)" _col(18) %10.4f `lr_pos' _col(30) %10.4f `lr_pos_se' _col(42) %8.3f `lr_pos_t' _col(52) %8.4f `lr_pos_p' _c
            _fbnardl_stars `lr_pos_p'
            di as txt "  " _col(5) "Long-Run  (-)" _col(18) %10.4f `lr_neg' _col(30) %10.4f `lr_neg_se' _col(42) %8.3f `lr_neg_t' _col(52) %8.4f `lr_neg_p' _c
            _fbnardl_stars `lr_neg_p'
            di as txt "  {hline 68}"
            if `sr_neg' != 0 {
                local sr_ratio = abs(`sr_pos' / `sr_neg')
                di as txt "  " _col(5) "SR Asymmetry |SR(+)/SR(-)|" _col(38) "= " as res %6.3f `sr_ratio'
            }
            if `lr_neg' != 0 {
                local lr_ratio = abs(`lr_pos' / `lr_neg')
                di as txt "  " _col(5) "LR Asymmetry |LR(+)/LR(-)|" _col(38) "= " as res %6.3f `lr_ratio'
            }

            local lr_pos_`cname' = `lr_pos'
            local lr_neg_`cname' = `lr_neg'
            local lr_pos_se_`cname' = `lr_pos_se'
            local lr_neg_se_`cname' = `lr_neg_se'
        }
        else {
            di as err "  Warning: Could not compute long-run multipliers for `cname'"
        }

        qui estimates restore _fbnardl_main
    }

    // Short-run & long-run multipliers for non-decomposed controls
    if `nctrl' > 0 {
        local ctrl_i = 0
        foreach cvar of local controls {
            local ctrl_i = `ctrl_i' + 1
            local this_r = `best_r_`ctrl_i''
            local lcvar_name "L.`cvar'"
            local saved_df_r_sr = e(df_r)

            local sr_ctrl = 0
            local sr_ctrl_se = .
            local sr_ctrl_t = .
            local sr_ctrl_p = .

            if `this_r' == 0 {
                capture local sr_ctrl = _b[D.`cvar']
                if _rc == 0 {
                    local sr_ctrl_se = _se[D.`cvar']
                    local sr_ctrl_t = `sr_ctrl' / `sr_ctrl_se'
                    local sr_ctrl_p = 2 * ttail(`saved_df_r_sr', abs(`sr_ctrl_t'))
                }
            }
            else {
                local lincom_expr "D.`cvar'"
                forvalues j = 1/`this_r' {
                    local lincom_expr "`lincom_expr' + L`j'.D.`cvar'"
                }
                capture qui lincom `lincom_expr'
                if _rc == 0 {
                    local sr_ctrl = r(estimate)
                    local sr_ctrl_se = r(se)
                    local sr_ctrl_t = `sr_ctrl' / `sr_ctrl_se'
                    local sr_ctrl_p = 2 * ttail(`saved_df_r_sr', abs(`sr_ctrl_t'))
                }
            }

            local saved_df_r = e(df_r)
            capture qui nlcom ///
                (LR: -_b[`lcvar_name'] / _b[`ecm_coef_name']), ///
                level(`level') post

            if _rc == 0 {
                tempname lr_ctrl_b lr_ctrl_V
                mat `lr_ctrl_b' = e(b)
                mat `lr_ctrl_V' = e(V)
                local lr_ctrl = `lr_ctrl_b'[1,1]
                local lr_ctrl_se = sqrt(`lr_ctrl_V'[1,1])
                local lr_ctrl_t = `lr_ctrl' / `lr_ctrl_se'
                local lr_ctrl_p = 2 * ttail(`saved_df_r', abs(`lr_ctrl_t'))

                di as txt ""
                di as txt "  Variable: `cvar' (non-decomposed)"
                di as txt "  {hline 68}"
                di as txt "  " _col(5) "Component" _col(20) "Estimate" _col(32) "Std.Err." _col(44) "t-stat" _col(54) "p-value"
                di as txt "  {hline 68}"
                if `sr_ctrl_se' < . {
                    di as res "  " _col(5) "Short-Run" _col(18) %10.4f `sr_ctrl' _col(30) %10.4f `sr_ctrl_se' _col(42) %8.3f `sr_ctrl_t' _col(52) %8.4f `sr_ctrl_p' _c
                    _fbnardl_stars `sr_ctrl_p'
                }
                else {
                    di as res "  " _col(5) "Short-Run" _col(18) %10.4f `sr_ctrl'
                }
                di as txt "  " _col(5) "{hline 58}"
                di as txt "  " _col(5) "Long-Run" _col(18) %10.4f `lr_ctrl' _col(30) %10.4f `lr_ctrl_se' _col(42) %8.3f `lr_ctrl_t' _col(52) %8.4f `lr_ctrl_p' _c
                _fbnardl_stars `lr_ctrl_p'
                di as txt "  {hline 68}"

                local lr_`cvar' = `lr_ctrl'
            }
            qui estimates restore _fbnardl_main
        }
    }

    di as txt ""
    di as txt "  Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1"
    di as txt "{hline 70}"
    di as txt ""

    // =========================================================================
    // 10. WALD TESTS FOR ASYMMETRY
    // =========================================================================
    di as txt "{hline 70}"
    di as res "  Table 4: Wald Tests for Asymmetry"
    di as txt _col(3) "{it:Standard errors: `vceshort'}"
    di as txt "{hline 70}"

    local dec_i = 0
    foreach cname of local dec_names {
        local dec_i = `dec_i' + 1
        local this_q = `best_q_`dec_i''
        di as txt ""
        di as txt "  Variable: `cname'"
        di as txt "  {hline 60}"

        // Short-run asymmetry: H0 sum(omega+) = sum(omega-) over all lags
        local sp ""
        local sn ""
        forvalues j = 0/`this_q' {
            if `j' == 0 {
                local sp "_b[D.`cname'_pos]"
                local sn "_b[D.`cname'_neg]"
            }
            else {
                local sp "`sp' + _b[L`j'.D.`cname'_pos]"
                local sn "`sn' + _b[L`j'.D.`cname'_neg]"
            }
        }
        capture qui testnl (`sp') = (`sn')
        if _rc == 0 {
            local wald_sr_f = r(chi2)
            local wald_sr_p = r(p)
            di as txt "  Short-run asymmetry: Chi2 = " %8.4f `wald_sr_f' "  p-value = " %6.4f `wald_sr_p' _c
            _fbnardl_stars `wald_sr_p'
            di as txt "    {it:H0: sum of D.`cname'_pos coefficients = sum of D.`cname'_neg coefficients}"
        }
        else {
            di as txt "  Short-run asymmetry: not estimable"
            local wald_sr_f = .
            local wald_sr_p = .
        }

        // Long-run asymmetry: H0 LR_pos = LR_neg
        local lpos_name "L.`cname'_pos"
        local lneg_name "L.`cname'_neg"
        capture qui testnl _b[`lpos_name']/_b[`ecm_coef_name'] = _b[`lneg_name']/_b[`ecm_coef_name']
        if _rc == 0 {
            local wald_lr_chi2 = r(chi2)
            local wald_lr_p = r(p)
            di as txt "  Long-run asymmetry:  Chi2 = " %8.4f `wald_lr_chi2' "  p-value = " %6.4f `wald_lr_p' _c
            _fbnardl_stars `wald_lr_p'
            di as txt "    {it:H0: LR(+) = LR(-)}"
        }
        else {
            di as txt "  Long-run asymmetry:  not estimable"
            local wald_lr_chi2 = .
            local wald_lr_p = .
        }
        local wsr_`cname' = `wald_sr_f'
        local wsrp_`cname' = `wald_sr_p'
        local wlr_`cname' = `wald_lr_chi2'
        local wlrp_`cname' = `wald_lr_p'
        di as txt "  {hline 60}"
    }
    di as txt "{hline 70}"
    di as txt ""

    // =========================================================================
    // 11. BOUNDS / BOOTSTRAP COINTEGRATION TEST
    // =========================================================================
    di as txt "{hline 70}"
    di as res "  Table 5: Cointegration Test"
    di as txt _col(3) "{it:Statistics use `vceshort' standard errors}"
    di as txt "{hline 70}"

    // Restriction sets
    local levels_test "`ecm_coef_name'"
    local indep_levels_test ""
    foreach cname of local dec_names {
        local levels_test "`levels_test' L.`cname'_pos L.`cname'_neg"
        local indep_levels_test "`indep_levels_test' L.`cname'_pos L.`cname'_neg"
    }
    foreach cvar of local controls {
        local levels_test "`levels_test' L.`cvar'"
        local indep_levels_test "`indep_levels_test' L.`cvar'"
    }

    qui test `levels_test'
    local Fov = r(F)
    if missing(`Fov') local Fov = r(chi2)/r(df)
    local Fov_df1 = r(df)
    local Fov_p = r(p)

    local t_dep = _b[`ecm_coef_name'] / _se[`ecm_coef_name']
    local t_dep_p = 2 * ttail(e(df_r), abs(`t_dep'))

    qui test `indep_levels_test'
    local Find = r(F)
    if missing(`Find') local Find = r(chi2)/r(df)
    local Find_df1 = r(df)
    local Find_p = r(p)

    // Number of long-run forcing variables for the bounds tables:
    // each decomposed variable contributes its two partial sums
    local k_pss = 2 * `ndec' + `nctrl'

    local boot_ok 0
    if "`type'" == "fnardl" {
        // ----- Pesaran-Shin-Smith bounds, Kripfganz & Schneider (2020) -----
        if "`vcetype'" != "ols" {
            di as txt ""
            di as err "  Warning: the tabulated bounds assume i.i.d. errors; combining"
            di as err "  hac() with type(fnardl) makes the comparison approximate."
            di as err "  Use type(fbnardl), which bootstraps the critical values under"
            di as err "  the same covariance estimator."
        }
        di as txt ""
        di as txt "  Method: PSS Bounds Testing (Pesaran, Shin & Smith, 2001)"
        di as txt "  Critical values: Kripfganz & Schneider (2020) response surfaces, Case III"
        di as txt "  Long-run forcing variables k = `k_pss'  (2 per decomposed variable + controls)"
        di as txt ""

        // short-run coefficient count for the K&S response surface
        local sr_count = `best_p'
        forvalues di = 1/`ndec' {
            local sr_count = `sr_count' + 2 * (`best_q_`di'' + 1)
        }
        if `nctrl' > 0 {
            forvalues ci = 1/`nctrl' {
                local sr_count = `sr_count' + `best_r_`ci'' + 1
            }
        }
        if `best_kstar' > 0 local sr_count = `sr_count' + 2
        local sr_count = `sr_count' + `nexog_est'

        local has_ardlbounds = 0
        foreach s in 10 05 01 {
            local F_I0_`s' = .
            local F_I1_`s' = .
            local t_I0_`s' = .
            local t_I1_`s' = .
        }
        local F_pv_I0 = .
        local F_pv_I1 = .
        local t_pv_I0 = .
        local t_pv_I1 = .

        capture which ardlbounds
        if _rc == 0 {
            local has_ardlbounds = 1
            capture {
                qui ardlbounds, case(3) stat(F) n(`nobs_used') k(`k_pss') ///
                    sr(`sr_count') siglevels(10 5 1) pvalue(`Fov')
                tempname Fcvmat
                mat `Fcvmat' = r(cvmat)
                local F_I0_10 = `Fcvmat'[1, 1]
                local F_I1_10 = `Fcvmat'[1, 2]
                local F_I0_05 = `Fcvmat'[1, 3]
                local F_I1_05 = `Fcvmat'[1, 4]
                local F_I0_01 = `Fcvmat'[1, 5]
                local F_I1_01 = `Fcvmat'[1, 6]
                local ncol_F = colsof(`Fcvmat')
                if `ncol_F' >= 8 {
                    local F_pv_I0 = `Fcvmat'[1, `ncol_F' - 1]
                    local F_pv_I1 = `Fcvmat'[1, `ncol_F']
                }
            }
            if _rc != 0 local has_ardlbounds = 0
            if `has_ardlbounds' {
                capture {
                    qui ardlbounds, case(3) stat(t) n(`nobs_used') k(`k_pss') ///
                        sr(`sr_count') siglevels(10 5 1) pvalue(`t_dep')
                    tempname tcvmat
                    mat `tcvmat' = r(cvmat)
                    local t_I0_10 = `tcvmat'[1, 1]
                    local t_I1_10 = `tcvmat'[1, 2]
                    local t_I0_05 = `tcvmat'[1, 3]
                    local t_I1_05 = `tcvmat'[1, 4]
                    local t_I0_01 = `tcvmat'[1, 5]
                    local t_I1_01 = `tcvmat'[1, 6]
                    local ncol_t = colsof(`tcvmat')
                    if `ncol_t' >= 8 {
                        local t_pv_I0 = `tcvmat'[1, `ncol_t' - 1]
                        local t_pv_I1 = `tcvmat'[1, `ncol_t']
                    }
                }
                if _rc != 0 local has_ardlbounds = 0
            }
        }
        qui estimates restore _fbnardl_main

        if `has_ardlbounds' {
            di as txt "  Finite-sample critical values (k = `k_pss', N = `nobs_used', sr = `sr_count')"
            di as txt ""
            di as txt "  {hline 76}"
            di as txt _col(5) "Test" _col(18) "Stat" ///
               _col(27) "  10% cv" _col(41) "   5% cv" _col(55) "   1% cv" _col(68) "p-value"
            di as txt _col(27) " I(0)  I(1)" _col(41) " I(0)  I(1)" ///
               _col(55) " I(0)  I(1)" _col(67) "I(0)  I(1)"
            di as txt "  {hline 76}"
            di as txt _col(3) "F_ov" _col(15) as res %7.3f `Fov' ///
               _col(25) %6.3f `F_I0_10' " " %6.3f `F_I1_10' ///
               _col(39) %6.3f `F_I0_05' " " %6.3f `F_I1_05' ///
               _col(53) %6.3f `F_I0_01' " " %6.3f `F_I1_01' _c
            if `F_pv_I0' < . di as res _col(67) %5.3f `F_pv_I0' " " %5.3f `F_pv_I1'
            else             di as txt ""
            di as txt _col(3) "t_dep" _col(15) as res %7.3f `t_dep' ///
               _col(25) %6.3f `t_I0_10' " " %6.3f `t_I1_10' ///
               _col(39) %6.3f `t_I0_05' " " %6.3f `t_I1_05' ///
               _col(53) %6.3f `t_I0_01' " " %6.3f `t_I1_01' _c
            if `t_pv_I0' < . di as res _col(67) %5.3f `t_pv_I0' " " %5.3f `t_pv_I1'
            else             di as txt ""
            di as txt _col(3) "F_ind" _col(15) as res %7.3f `Find' ///
               _col(25) as txt "  (no tabulated bounds; use type(fbnardl))"
            di as txt "  {hline 76}"

            local d_fov "Inconclusive"
            if `Fov' > `F_I1_05' local d_fov "Reject H0"
            if `Fov' < `F_I0_05' local d_fov "Fail to reject"
            local d_t "Inconclusive"
            if `t_dep' < `t_I1_05' local d_t "Reject H0"
            if `t_dep' > `t_I0_05' local d_t "Fail to reject"
            di as txt ""
            di as txt "  Decision at 5% level:"
            di as res "    F_overall   : `d_fov'"
            di as res "    t_dependent : `d_t'"
            if "`d_fov'" == "Reject H0" & "`d_t'" == "Reject H0" {
                di as res "    => COINTEGRATION detected (F_ov and t_dep both reject at 5%)"
                local coint "cointegrated"
            }
            else if "`d_fov'" == "Reject H0" & "`d_t'" != "Reject H0" {
                di as res "    => F_ov rejects but t_dep does not: possible degenerate"
                di as res "       lagged dependent variable case; no cointegration"
                local coint "degenerate_dep"
            }
            else {
                di as res "    => No cointegration at 5%"
                local coint "no_cointegration"
            }
            di as txt ""
            di as txt "  {it:F_ind has no tabulated bounds under I(1) regressors; its regression}"
            di as txt "  {it:p-value is not valid and is not reported.  type(fbnardl) bootstraps it.}"
        }
        else {
            di as txt "  {it:Note: ardlbounds is not installed; approximate PSS (2001) Case III}"
            di as txt "  {it:asymptotic bounds are used.  Install it with}"
            di as txt "  {it:  net install ardl, from(http://www.kripfganz.de/stata/)}"
            di as txt ""
            di as txt "  {hline 60}"
            di as txt "  " _col(5) "Test" _col(25) "Statistic"
            di as txt "  {hline 60}"
            di as txt "  " _col(5) "F_overall (Fov)" _col(23) %10.4f `Fov'
            di as txt "  " _col(5) "t_dependent" _col(23) %10.4f `t_dep'
            di as txt "  " _col(5) "F_independent (Find)" _col(23) %10.4f `Find'
            di as txt "  {hline 60}"
            di as txt ""
            di as txt "  PSS Bounds (Case III), k = `k_pss':"
            di as txt "  {hline 60}"
            di as txt "  " _col(5) "Signif." _col(18) "I(0) Bound" _col(35) "I(1) Bound" _col(50) "Decision"
            di as txt "  {hline 60}"
            _fbnardl_pss_cv `k_pss' `Fov' `nobs_used'
            di as txt "  {hline 60}"
            local coint ""
        }
        di as txt ""
        di as txt "  {it:For bootstrap critical values under the chosen covariance estimator,}"
        di as txt "  {it:use type(fbnardl).}"
    }
    else {
        // ----- Recursive null-imposed bootstrap -----
        di as txt ""
        if "`bootstrap'" == "bvz" {
            di as txt "  Method: Bertelli, Vacca & Zoia (2022) conditional bootstrap"
            di as txt "          one restricted equation per null (their eqs. 16-18);"
            di as txt "          marginal VECM excludes y(t-1) (weak exogeneity, eqs. 19-20)"
        }
        else {
            di as txt "  Method: McNown, Sam & Goh (2018) unconditional bootstrap"
            di as txt "          one restricted equation for all three tests (their Step 1);"
            di as txt "          marginal equations include y(t-1) (their eq. 12)"
        }
        di as txt "  DGP: y*(t) = y*(t-1) + Dy*(t), x*(t) = x*(t-1) + Dx*(t); residuals"
        di as txt "       recentred and df-rescaled; the partial sums, Fourier terms and"
        di as txt "       fixed regressors enter as in the estimated equation."
        di as txt "  Replications: `reps'"
        di as txt ""
        di as txt "  Computing bootstrap distributions..."

        // regressors seen by the Mata engine: the partial sums and controls
        local allx ""
        tempname QM
        local K = 2 * `ndec' + `nctrl'
        mat `QM' = J(1, `K', .)
        local w = 0
        local dec_i = 0
        foreach cname of local dec_names {
            local dec_i = `dec_i' + 1
            local allx "`allx' `cname'_pos `cname'_neg"
            local w = `w' + 1
            mat `QM'[1, `w'] = `best_q_`dec_i''
            local w = `w' + 1
            mat `QM'[1, `w'] = `best_q_`dec_i''
        }
        if `nctrl' > 0 {
            local ctrl_i = 0
            foreach cvar of local controls {
                local ctrl_i = `ctrl_i' + 1
                local allx "`allx' `cvar'"
                local w = `w' + 1
                mat `QM'[1, `w'] = `best_r_`ctrl_i''
            }
        }

        // deterministic block: constant first (conscol = 1), then Fourier
        // terms and the fixed regressors, all held at their sample values
        tempvar one allobs
        qui gen byte `one' = 1
        qui gen byte `allobs' = 1
        local detvars "`one'"
        if `best_kstar' > 0 local detvars "`detvars' _fbnardl_sin _fbnardl_cos"
        if "`exogboot'" != "" local detvars "`detvars' `exogboot'"

        local s0 = `maxlag' + 1
        capture noisily _fbnardl_bootstrap, depvar(`depvar') xvars(`allx')  ///
            detvars(`detvars') p(`best_p') qmat(`QM') s0(`s0')           ///
            reps(`reps') bmethod(`bootstrap') caseval(3)                 ///
            vcode(`vcode') hlag(`nwlag') conscol(1) trendcol(0)          ///
            touse(`allobs') xdgp(`xdgp')
        if _rc == 0 {
            local boot_ok 1
            local bs_Fov_pval  = r(Fov_bp)
            local bs_t_pval    = r(tDV_bp)
            local bs_Find_pval = r(Find_bp)
            foreach a in 10 5 1 {
                local bs_Fov_cv`a'  = r(Fov_cv`a')
                local bs_t_cv`a'    = r(tDV_cv`a')
                local bs_Find_cv`a' = r(Find_cv`a')
            }
            local nvalid = r(nvalid)
            local Fov_mata  = r(Fov_obs)
            local t_mata    = r(tDV_obs)
            local Find_mata = r(Find_obs)
            local dmax = max(abs(`Fov_mata' - `Fov'), abs(`t_mata' - `t_dep'), ///
                             abs(`Find_mata' - `Find'))
            if `dmax' > 1e-6 & `dmax' < . {
                di as txt "  note: the bootstrap engine's observed statistics differ from"
                di as txt "        the regression ones by " %9.2e `dmax' " (sample or vce mismatch)."
            }
        }
        else {
            di as err "  the bootstrap failed (rc = " _rc "); no bootstrap inference is reported"
        }
        qui estimates restore _fbnardl_main

        if `boot_ok' {
            di as txt ""
            di as txt "  {hline 72}"
            di as txt _col(5) "Test" _col(19) "Statistic" _col(32) "Boot. p" ///
               _col(43) "10% cv" _col(54) "5% cv" _col(64) "1% cv"
            di as txt "  {hline 72}"
            di as txt _col(5) "F_overall" _col(17) as res %10.4f `Fov' ///
               _col(30) %8.4f `bs_Fov_pval' _col(40) %9.4f `bs_Fov_cv10' ///
               _col(51) %9.4f `bs_Fov_cv5' _col(61) %9.4f `bs_Fov_cv1' _c
            _fbnardl_stars `bs_Fov_pval'
            di as txt _col(5) "t_dependent" _col(17) as res %10.4f `t_dep' ///
               _col(30) %8.4f `bs_t_pval' _col(40) %9.4f `bs_t_cv10' ///
               _col(51) %9.4f `bs_t_cv5' _col(61) %9.4f `bs_t_cv1' _c
            _fbnardl_stars `bs_t_pval'
            di as txt _col(5) "F_independent" _col(17) as res %10.4f `Find' ///
               _col(30) %8.4f `bs_Find_pval' _col(40) %9.4f `bs_Find_cv10' ///
               _col(51) %9.4f `bs_Find_cv5' _col(61) %9.4f `bs_Find_cv1' _c
            _fbnardl_stars `bs_Find_pval'
            di as txt "  {hline 72}"
            di as txt _col(5) "{it:F tests are upper-tail, t_dependent is lower-tail.}"
            di as txt _col(5) "{it:Valid replications: `nvalid' of `reps'.}"

            local sig_fov  = (`bs_Fov_pval'  < 0.05)
            local sig_tdv  = (`bs_t_pval'    < 0.05)
            local sig_find = (`bs_Find_pval' < 0.05)
            di as txt ""
            di as txt "  Decision at 5% level:"
            if `sig_fov' & `sig_tdv' & `sig_find' {
                di as res "    => COINTEGRATION: all three tests reject."
                local coint "cointegrated"
            }
            else if `sig_fov' & `sig_tdv' & !`sig_find' {
                di as res "    => Degenerate lagged independent variable(s) case"
                di as res "       (F_ov and t_dep reject, F_ind does not).  No cointegration."
                local coint "degenerate_indep"
            }
            else if `sig_fov' & !`sig_tdv' & `sig_find' {
                di as res "    => Degenerate lagged dependent variable case"
                di as res "       (F_ov and F_ind reject, t_dep does not).  No cointegration."
                local coint "degenerate_dep"
            }
            else {
                di as res "    => No cointegration."
                local coint "no_cointegration"
            }
        }
        else {
            local coint ""
        }
    }
    di as txt "{hline 70}"
    di as txt ""

    // =========================================================================
    // 12. DIAGNOSTIC TESTS (on the OLS fit: estat needs it)
    // =========================================================================
    if "`nodiag'" == "" {
        di as txt "{hline 78}"
        di as res "  Table 6: Diagnostic Tests"
        di as txt "{hline 78}"
        if "`vcetype'" != "ols" {
            di as txt _col(5) "{it:Note: standard errors already correct for }" _c
            if "`vcetype'" == "robust" {
                di as txt "{it:heteroskedasticity (HC1).}"
            }
            else {
                di as txt "{it:heteroskedasticity and}"
                di as txt _col(5) "{it:autocorrelation (Newey-West, lag `nwlag').}"
            }
            di as txt _col(5) "{it:The tests below remain informative about the error process.}"
        }
        tempvar esfit
        qui gen byte `esfit' = (`tindex' > `maxlag' + 1)
        capture estimates restore _fbnardl_ols
        _fbnardl_diagtest, residvar(_fbnardl_resid) nobs(`nobs_used') ///
            nparams(`nparams') lhs(D.`depvar') rhs(`best_formula') esample(`esfit')
        capture estimates restore _fbnardl_main
    }

    // =========================================================================
    // 13. DYNAMIC MULTIPLIERS
    // =========================================================================
    if "`nodynmult'" == "" {
        capture estimates restore _fbnardl_main
        // shocks = every partial sum and control, each with its own lag order
        local shocks ""
        local qlist ""
        local dec_i = 0
        foreach cname of local dec_names {
            local dec_i = `dec_i' + 1
            local shocks "`shocks' `cname'_pos `cname'_neg"
            local qlist "`qlist' `best_q_`dec_i'' `best_q_`dec_i''"
        }
        if `nctrl' > 0 {
            local ctrl_i = 0
            foreach cvar of local controls {
                local ctrl_i = `ctrl_i' + 1
                local shocks "`shocks' `cvar'"
                local qlist "`qlist' `best_r_`ctrl_i''"
            }
        }
        capture noisily _fbnardl_dynmult, depvar(`depvar') shocks(`shocks') ///
            qlist(`qlist') plags(`best_p') horizon(`horizon') bands(500)   ///
            level(`level') pairs(`dec_names') graphprefix(fbnardl_)
    }

    // =========================================================================
    // 14. ADVANCED POST-ESTIMATION ANALYSES
    // =========================================================================
    if "`noadvanced'" == "" {
        capture estimates restore _fbnardl_main
        local max_q = 0
        forvalues di = 1/`ndec' {
            if `best_q_`di'' > `max_q' local max_q = `best_q_`di''
        }
        _fbnardl_advanced, depvar(`depvar') decnames(`dec_names') ///
            ecmcoef(`ecm_coef_name') p(`best_p') q(`max_q') ///
            horizon(`horizon') best_kstar(`best_kstar') ///
            `= cond("`nofourier'" != "", "nofourier", "")' ///
            `= cond(`nctrl' > 0, "controls(`controls')", "")'
    }

    // =========================================================================
    // 15. STORE e() RESULTS
    // =========================================================================
    capture estimates restore _fbnardl_main
    tempname b_post V_post
    mat `b_post' = e(b)
    mat `V_post' = e(V)
    local nobs_post = e(N)
    local df_r_post = e(df_r)
    capture estimates drop _fbnardl_main
    capture estimates drop _fbnardl_ols
    capture drop _fbnardl_resid

    // Restore original data FIRST, then post results
    restore

    ereturn post `b_post' `V_post', obs(`nobs_post') esample(`esamp') ///
        depname(D.`depvar') dof(`df_r_post')

    ereturn scalar best_p = `best_p'
    forvalues di = 1/`ndec' {
        local cname : word `di' of `dec_names'
        ereturn scalar best_q_`cname' = `best_q_`di''
    }
    if `nctrl' > 0 {
        forvalues ci = 1/`nctrl' {
            local cvar : word `ci' of `controls'
            ereturn scalar best_r_`cvar' = `best_r_`ci''
        }
    }
    ereturn scalar best_kstar = `best_kstar'
    ereturn scalar maxlag = `maxlag'
    ereturn scalar ic_val = scalar(`best_ic_val')
    ereturn scalar aic = `aic_val'
    ereturn scalar bic = `bic_val'
    ereturn scalar ll = `loglik'
    ereturn scalar Fov = `Fov'
    ereturn scalar t_dep = `t_dep'
    ereturn scalar Find = `Find'
    ereturn scalar k = `k_pss'
    ereturn scalar N = `nobs_post'
    ereturn scalar N_full = `nobs'
    ereturn scalar df_m = `df_m'
    ereturn scalar df_r = `df_r_post'
    ereturn scalar r2 = `r2'
    ereturn scalar r2_a = `r2_adj'
    ereturn scalar F_model = `fstat'
    ereturn scalar rmse = `rmse'
    ereturn scalar rss = `ssr'
    ereturn scalar n_exog = `nexog_est'
    ereturn scalar nmodels = `total_models'
    if "`vcetype'" == "hac" ereturn scalar haclags = `nwlag'

    foreach cname of local dec_names {
        capture ereturn scalar lr_pos_`cname' = `lr_pos_`cname''
        capture ereturn scalar lr_neg_`cname' = `lr_neg_`cname''
        capture ereturn scalar wald_sr_`cname' = `wsr_`cname''
        capture ereturn scalar wald_sr_p_`cname' = `wsrp_`cname''
        capture ereturn scalar wald_lr_`cname' = `wlr_`cname''
        capture ereturn scalar wald_lr_p_`cname' = `wlrp_`cname''
    }
    foreach cvar of local controls {
        capture ereturn scalar lr_`cvar' = `lr_`cvar''
    }

    if "`type'" == "fnardl" {
        capture {
            ereturn scalar F_I0_05 = `F_I0_05'
            ereturn scalar F_I1_05 = `F_I1_05'
            ereturn scalar t_I0_05 = `t_I0_05'
            ereturn scalar t_I1_05 = `t_I1_05'
            ereturn scalar Fov_pval_I0 = `F_pv_I0'
            ereturn scalar Fov_pval_I1 = `F_pv_I1'
            ereturn scalar t_pval_I0 = `t_pv_I0'
            ereturn scalar t_pval_I1 = `t_pv_I1'
        }
    }
    if "`type'" == "fbnardl" & `boot_ok' {
        ereturn scalar reps = `reps'
        ereturn scalar bs_Fov_cv05 = `bs_Fov_cv5'
        ereturn scalar bs_t_cv05 = `bs_t_cv5'
        ereturn scalar bs_Find_cv05 = `bs_Find_cv5'
        ereturn scalar bs_Fov_cv01 = `bs_Fov_cv1'
        ereturn scalar bs_t_cv01 = `bs_t_cv1'
        ereturn scalar bs_Find_cv01 = `bs_Find_cv1'
        ereturn scalar bs_Fov_cv10 = `bs_Fov_cv10'
        ereturn scalar bs_t_cv10 = `bs_t_cv10'
        ereturn scalar bs_Find_cv10 = `bs_Find_cv10'
        ereturn scalar bs_Fov_pval = `bs_Fov_pval'
        ereturn scalar bs_t_pval = `bs_t_pval'
        ereturn scalar bs_Find_pval = `bs_Find_pval'
        ereturn scalar bs_nvalid = `nvalid'
    }

    // Macros
    ereturn local cmd "fbnardl"
    ereturn local cmdline "fbnardl `0'"
    ereturn local type "`type'"
    ereturn local depvar "`depvar'"
    ereturn local decompose "`decompose'"
    ereturn local controls "`controls'"
    ereturn local exog "`exog'"
    ereturn local ic "`ic'"
    ereturn local dec_names "`dec_names'"
    ereturn local vcetype "`vcetype'"
    ereturn local vce "`vcelabel'"
    ereturn local coint_status "`coint'"
    ereturn local timevar "`timevar'"
    if "`type'" == "fbnardl" {
        ereturn local bootstrap "`bootstrap'"
        ereturn local xdgp "`xdgp'"
    }

    di as txt "{hline 70}"
    di as res "  References"
    di as txt "{hline 70}"
    di as txt "  Shin, Yu & Greenwood-Nimmo (2014). Modelling asymmetric cointegration"
    di as txt "    and dynamic multipliers in a nonlinear ARDL framework."
    di as txt "  Pesaran, Shin & Smith (2001). Bounds testing approaches to the"
    di as txt "    analysis of level relationships. JAE, 16(3), 289-326."
    if "`type'" == "fnardl" {
        di as txt "  Kripfganz & Schneider (2020). Response surface regressions for"
        di as txt "    critical value bounds. Oxford Bull. Econ. Stat., 82(6)."
    }
    else {
        di as txt "  Bertelli, Vacca & Zoia (2022). Bootstrap cointegration tests"
        di as txt "    in ARDL models. Economic Modelling, 116, 105987."
        di as txt "  McNown, Sam & Goh (2018). Bootstrapping the ARDL test for"
        di as txt "    cointegration. Applied Economics, 50(13), 1509-1521."
    }
    if "`nofourier'" == "" {
        di as txt "  Yilanci, Bozoklu & Gorus (2020). Fourier ARDL approach."
        di as txt "    Evaluation Review, 44(5-6), 431-450."
    }
    if "`vcetype'" == "robust" {
        di as txt "  White (1980). A heteroskedasticity-consistent covariance matrix"
        di as txt "    estimator. Econometrica, 48(4), 817-838."
    }
    if "`vcetype'" == "hac" {
        di as txt "  Newey & West (1987). A simple, positive semi-definite, HAC"
        di as txt "    covariance matrix. Econometrica, 55(3), 703-708."
    }
    di as txt "{hline 70}"

    di as txt "{hline 70}"
    di as res "  fbnardl v2.0.0 — estimation complete. Results stored in e()."
    di as txt "  Type {cmd:ereturn list} to view stored results."
    di as txt "{hline 70}"

end


// =============================================================================
// HELPER: one coefficient row of Table 2
// =============================================================================
capture program drop _fbnardl_row
program define _fbnardl_row
    version 17
    args vname label dfr
    capture local coef_val = _b[`vname']
    if _rc != 0 exit
    local se_val = _se[`vname']
    if `se_val' <= 0 | `se_val' >= . {
        di as txt _col(5) abbrev("`label'", 17) _col(23) as res %10.4f `coef_val' ///
           _col(36) as txt "  (omitted)"
        exit
    }
    local t_val = `coef_val' / `se_val'
    local p_val = 2 * ttail(`dfr', abs(`t_val'))
    di as txt _col(5) abbrev("`label'", 17) _col(23) as res %10.4f `coef_val' ///
       _col(36) %10.4f `se_val' _col(49) %8.3f `t_val' _col(61) %8.4f `p_val' _c
    _fbnardl_stars `p_val'
end


// =============================================================================
// HELPER: Display significance stars
// =============================================================================
capture program drop _fbnardl_stars
program define _fbnardl_stars
    version 17
    args pval
    if `pval' < 0.001 {
        di as res " ***"
    }
    else if `pval' < 0.01 {
        di as res " **"
    }
    else if `pval' < 0.05 {
        di as res " *"
    }
    else if `pval' < 0.1 {
        di as res " ."
    }
    else {
        di as txt ""
    }
end


// =============================================================================
// HELPER: Approximate PSS Critical Values (fallback when ardlbounds is absent)
// =============================================================================
capture program drop _fbnardl_pss_cv
program define _fbnardl_pss_cv
    version 17
    args k Fstat nobs

    // Approximate PSS (2001) Table CI(iii) — Case III (unrestricted intercept, no trend)
    if `k' == 1 {
        local lb10 = 4.04
        local lb05 = 4.94
        local lb01 = 6.84
    }
    else if `k' == 2 {
        local lb10 = 3.17
        local lb05 = 3.79
        local lb01 = 5.15
    }
    else if `k' == 3 {
        local lb10 = 2.72
        local lb05 = 3.23
        local lb01 = 4.29
    }
    else if `k' == 4 {
        local lb10 = 2.45
        local lb05 = 2.86
        local lb01 = 3.74
    }
    else if `k' == 5 {
        local lb10 = 2.26
        local lb05 = 2.62
        local lb01 = 3.41
    }
    else if `k' == 6 {
        local lb10 = 2.12
        local lb05 = 2.45
        local lb01 = 3.15
    }
    else if `k' == 7 {
        local lb10 = 2.03
        local lb05 = 2.32
        local lb01 = 2.96
    }
    else {
        local lb10 = 1.95
        local lb05 = 2.22
        local lb01 = 2.79
    }

    if `k' == 1 {
        local ub10 = 4.78
        local ub05 = 5.73
        local ub01 = 7.84
    }
    else if `k' == 2 {
        local ub10 = 4.14
        local ub05 = 4.85
        local ub01 = 6.36
    }
    else if `k' == 3 {
        local ub10 = 3.77
        local ub05 = 4.35
        local ub01 = 5.61
    }
    else if `k' == 4 {
        local ub10 = 3.52
        local ub05 = 4.01
        local ub01 = 5.06
    }
    else if `k' == 5 {
        local ub10 = 3.35
        local ub05 = 3.79
        local ub01 = 4.68
    }
    else if `k' == 6 {
        local ub10 = 3.22
        local ub05 = 3.61
        local ub01 = 4.43
    }
    else if `k' == 7 {
        local ub10 = 3.13
        local ub05 = 3.50
        local ub01 = 4.26
    }
    else {
        local ub10 = 3.06
        local ub05 = 3.39
        local ub01 = 4.10
    }

    foreach slev in 10 05 01 {
        if "`slev'" == "10" local slabel "10%"
        if "`slev'" == "05" local slabel " 5%"
        if "`slev'" == "01" local slabel " 1%"

        local lb = `lb`slev''
        local ub = `ub`slev''

        if `Fstat' > `ub' {
            local decision "Reject H0"
        }
        else if `Fstat' < `lb' {
            local decision "Fail to Reject"
        }
        else {
            local decision "Inconclusive"
        }

        di as txt "  " _col(5) "`slabel'" _col(18) %8.3f `lb' _col(35) %8.3f `ub' _col(50) "`decision'"
    }
end
