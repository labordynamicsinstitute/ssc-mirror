*! qnardl v1.0.0  28may2026
*! Quantile Nonlinear Autoregressive Distributed Lag Model
*!
*! Implements both:
*!   (a) Single-step QNARDL on the unrestricted error-correction model
*!       (Bertsatos, Sakellaris & Tsionas, Empirical Economics 2022; default option onestep)
*!   (b) Two-step QNARDL with FM-quantile long-run + quantile short-run ECM
*!       (Cho, Greenwood-Nimmo, Kim & Shin 2020a; default; survey: Cho/G-N/Shin 2021 §4.2)
*!
*! Building blocks (all by the same author):
*!   - xqcoint   (qcointlib)  Xiao 2009 FM-quantile cointegrating regression
*!   - qardl     (SSC)        Cho, Kim & Shin 2015 QARDL (one-step quantile ARDL)
*!   - twostep_nardl          Cho, G-N & Shin 2019/2020b two-step NARDL
*!
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Date  : May 2026

program define qnardl, eclass sortpreserve
    version 14.0

    local cmd = "qnardl"

    // -------------------------------------------------------------------------
    // REPLAY
    // -------------------------------------------------------------------------
    if replay() {
        if "`e(cmd)'" != "`cmd'" error 301
        _qnardl_display `0'
        exit
    }

    local cmdline_orig `"`0'"'

    // -------------------------------------------------------------------------
    // SYNTAX (two-pass to allow trendvar with or without an argument)
    // -------------------------------------------------------------------------
    capture syntax anything [if] [in] , TRendvar [ * ]
    if !_rc {
        tsset , noquery
        local trendvar `r(timevar)'
        local 0 `"`anything' `if' `in' , `options'"'
    }
    else {
        local trendvaropt "TRendvar(varlist min=1 max=1 numeric)"
    }

    syntax varlist(min=2 numeric ts) [if] [in] ,                         ///
        DECompose(varlist numeric ts)                                    ///
        TAU(numlist >0 <1 sort)                                          ///
        [                                                                ///
        LAgs(numlist >=0 int miss)                                       ///
        MAxlags(numlist >=0 int miss)                                    ///
        BIC AIC HQIC                                                     ///
        TWOstep ONEstep                                                  ///
        STEP1(string)                                                    ///
        BWidth(numlist min=1 max=1 int >0)                               ///
        THReshold(numlist)                                               ///
        noConstant                                                       ///
        `trendvaropt'                                                    ///
        QUADratictrend                                                   ///
        RESTricted                                                       ///
        Exog(varlist numeric ts)                                         ///
        MULTiplier(numlist min=1 max=1 int >0)                           ///
        BOUNDS                                                           ///
        INTERPercentile                                                  ///
        INTERDecile                                                      ///
        SIMulate(numlist min=1 max=1 int >100)                           ///
        LRSYMmetry                                                       ///
        SRSYMmetry                                                       ///
        MULTipliers                                                      ///
        HORizon(numlist min=1 max=1 int >0)                              ///
        CUSUM                                                            ///
        CUSUMtau(numlist max=1 >0 <1)                                    ///
        DIAGnostics                                                      ///
        BGLags(numlist min=1 max=1 int >0)                               ///
        CASE(numlist min=1 max=1 int >=1 <=11)                           ///
        Level(cilevel)                                                   ///
        noCTable                                                         ///
        noHEader                                                         ///
        noWALDtest                                                       ///
        DOTs                                                             ///
        GRAPH                                                            ///
        FULL                                                             ///
        BYTAU                                                            ///
        * ]

    // -------------------------------------------------------------------------
    // INPUT VALIDATION
    // -------------------------------------------------------------------------

    // Parse depvar / xvars
    local numvars  : word count `varlist'
    local numxvars = `numvars' - 1
    gettoken depvar xvars : varlist
    local k : word count `xvars'

    // decompose() must be a subset of xvars
    local asym_check : list decompose - xvars
    if "`asym_check'" != "" {
        di as error "decompose() variables must be a subset of independent variables"
        di as error "  offending: `asym_check'"
        exit 198
    }
    local asymmetry `decompose'
    local k_asym : word count `asymmetry'
    local linear_vars : list xvars - decompose
    local k_lin : word count `linear_vars'

    if `k_asym' == 0 {
        di as error "decompose() must list at least one variable for partial-sum decomposition"
        di as error "  if you want a pure quantile ARDL with no asymmetry, use {help qardl}"
        exit 198
    }

    // Method: twostep (default) or onestep
    if "`twostep'" != "" & "`onestep'" != "" {
        di as error "options twostep and onestep are mutually exclusive"
        exit 198
    }
    if "`onestep'" != "" {
        local method "onestep"
    }
    else {
        local method "twostep"
    }

    // Long-run estimator for two-step
    if "`step1'" == "" local step1 "fmqr"
    local step1 = lower("`step1'")
    if !inlist("`step1'", "fmqr", "qr", "augfmqr") {
        di as error "step1() must be: fmqr (default), qr, or augfmqr"
        exit 198
    }
    if "`method'" == "onestep" & "`step1'" != "fmqr" {
        di as txt "note: step1() ignored when onestep is specified"
    }

    // Information criterion default
    if "`bic'`aic'`hqic'" == "" local bic "bic"
    local ic_count = ("`bic'" != "") + ("`aic'" != "") + ("`hqic'" != "")
    if `ic_count' > 1 {
        di as error "specify only one of bic, aic, hqic"
        exit 198
    }
    local ic_type = cond("`aic'"!="", "aic", cond("`hqic'"!="", "hqic", "bic"))

    // Threshold for partial sum (default 0; vector allowed for per-variable thresholds)
    if "`threshold'" == "" {
        local nthr 0
    }
    else {
        local nthr : word count `threshold'
        if `nthr' != 1 & `nthr' != `k_asym' {
            di as error "threshold() must have either 1 value or `k_asym' values (one per decomposed var)"
            exit 198
        }
    }

    // Determinístic case (Bertsatos et al. 2022 Table 1: I..XI)
    //   I  : no constant, no trend                                 (default if noconstant)
    //   II : restricted intercept, no trend                        (restricted + no trendvar)
    //   III: unrestricted intercept, no trend                      (default with constant)
    //   IV : unrestricted intercept, restricted linear trend       (trendvar + restricted)
    //   V  : unrestricted intercept, unrestricted linear trend     (trendvar)
    //   VI : intercept and trend in DGP, restricted in long-run    (case 6 - special)
    //   VII: intercept and trend in DGP, no restriction in long-run
    //   VIII..XI : as IV..VII but with quadratic trend
    // If user explicitly sets case(), it overrides the inference below.
    if "`case'" == "" {
        _qnardl_infer_case , const("`constant'") trendvar("`trendvar'") ///
                     quad("`quadratictrend'") restricted("`restricted'")
        local case = r(case)
    }

    // PSS bounds-test multiplier horizon (for dynamic multipliers)
    if "`multiplier'" == "" local multiplier 12

    // Level for CIs
    if "`level'" == "" local level 95

    // Mark sample BEFORE we build any new variables
    marksample touse
    qui count if `touse'
    local nobs = r(N)
    if `nobs' < 30 {
        di as error "qnardl requires at least 30 observations after if/in (got `nobs')"
        exit 2001
    }

    // Time-series setup
    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as error "qnardl is for time-series data only (no panels)"
        di as error "  for panel QNARDL see xtpqardl / xtpmg"
        exit 198
    }

    local ntau : word count `tau'

    // -------------------------------------------------------------------------
    // HEADER
    // -------------------------------------------------------------------------
    if "`header'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Quantile Nonlinear ARDL — " _c
        if "`method'" == "twostep" {
            di as res "Two-step (Cho, G-N, Kim & Shin 2020a)"
        }
        else {
            di as res "Single-step (Bertsatos, Sakellaris & Tsionas 2022)"
        }
        di as txt "{hline 78}"
        di as txt _col(3) "Dependent variable    : " as res "`depvar'"
        di as txt _col(3) "Asymmetric regressors : " as res "`asymmetry'"
        if "`linear_vars'" != "" {
            di as txt _col(3) "Linear regressors     : " as res "`linear_vars'"
        }
        if "`exog'" != "" {
            di as txt _col(3) "Exogenous (no decomp) : " as res "`exog'"
        }
        di as txt _col(3) "Quantiles (#=" as res `ntau' as txt "): " as res "`tau'"
        di as txt _col(3) "Observations          : " as res `nobs'
        di as txt _col(3) "Method                : " as res "`method'" _c
        if "`method'" == "twostep" {
            di as txt "   long-run engine: " as res "`step1'"
        }
        else {
            di ""
        }
        di as txt _col(3) "Case (Bertsatos 2022) : " as res `case'
        di as txt _col(3) "Information criterion : " as res "`ic_type'"
        di as txt "{hline 78}"
    }

    // -------------------------------------------------------------------------
    // CLEAR previous estimation state (stale e() from earlier calls
    // could otherwise leak into the display/graph downstream)
    // -------------------------------------------------------------------------
    ereturn clear

    // -------------------------------------------------------------------------
    // STEP 1: PARTIAL-SUM DECOMPOSITION (always needed for both onestep & twostep)
    // -------------------------------------------------------------------------
    tempvar touse2
    qui gen byte `touse2' = `touse'

    local asym_pos_vars ""
    local asym_neg_vars ""
    local thr_opt = cond("`threshold'"=="", "", "threshold(`threshold')")
    _qnardl_decompose `asymmetry' if `touse', `thr_opt' ///
        prefix(_qnardl) touse(`touse')
    local asym_pos_vars `r(pos_vars)'
    local asym_neg_vars `r(neg_vars)'

    // -------------------------------------------------------------------------
    // STEP 2: LAG SELECTION  (user lags(), or IC search via maxlags(), or default 1,1,1)
    // -------------------------------------------------------------------------
    if "`lags'" != "" {
        local p_lag : word 1 of `lags'
        local q_lag : word 2 of `lags'
        local r_lag : word 3 of `lags'
        if "`p_lag'" == "" local p_lag 1
        if "`q_lag'" == "" local q_lag `p_lag'
        if "`r_lag'" == "" local r_lag `q_lag'
        local lagselect 0
    }
    else if "`maxlags'" != "" {
        local pmax : word 1 of `maxlags'
        local qmax : word 2 of `maxlags'
        local rmax : word 3 of `maxlags'
        if "`pmax'" == "" local pmax 4
        if "`qmax'" == "" local qmax `pmax'
        if "`rmax'" == "" local rmax `qmax'
        _qnardl_lagsel ,                                         ///
            depvar(`depvar')                                     ///
            pos_vars(`asym_pos_vars')                            ///
            neg_vars(`asym_neg_vars')                            ///
            linear_vars(`linear_vars')                           ///
            exog(`exog')                                         ///
            trendvar(`trendvar')                                 ///
            case(`case')                                         ///
            touse(`touse')                                       ///
            pmax(`pmax') qmax(`qmax') rmax(`rmax')               ///
            ic(`ic_type') `dots'
        local p_lag = r(p)
        local q_lag = r(q)
        local r_lag = r(r)
        local lagselect 1
    }
    else {
        local p_lag 1
        local q_lag 1
        local r_lag 1
        local lagselect 0
    }

    // -------------------------------------------------------------------------
    // STEP 3: ESTIMATION (per-quantile loop happens inside the subroutine)
    // -------------------------------------------------------------------------
    if "`method'" == "twostep" {
        _qnardl_twostep ,                                       ///
            depvar(`depvar')                                    ///
            asymmetry(`asymmetry')                              ///
            pos_vars(`asym_pos_vars')                           ///
            neg_vars(`asym_neg_vars')                           ///
            linear_vars(`linear_vars')                          ///
            exog(`exog')                                        ///
            tau(`tau')                                          ///
            p(`p_lag') q(`q_lag') r(`r_lag')                    ///
            step1(`step1')                                      ///
            bwidth(`bwidth')                                    ///
            case(`case')                                        ///
            trendvar(`trendvar')                                ///
            quad("`quadratictrend'")                            ///
            constant("`constant'")                              ///
            restricted("`restricted'")                          ///
            touse(`touse')                                      ///
            level(`level')
    }
    else {
        _qnardl_onestep ,                                       ///
            depvar(`depvar')                                    ///
            asymmetry(`asymmetry')                              ///
            pos_vars(`asym_pos_vars')                           ///
            neg_vars(`asym_neg_vars')                           ///
            linear_vars(`linear_vars')                          ///
            exog(`exog')                                        ///
            tau(`tau')                                          ///
            p(`p_lag') q(`q_lag') r(`r_lag')                    ///
            case(`case')                                        ///
            trendvar(`trendvar')                                ///
            quad("`quadratictrend'")                            ///
            constant("`constant'")                              ///
            touse(`touse')                                      ///
            level(`level')
    }

    // -------------------------------------------------------------------------
    // STEP 4: POST-ESTIMATION TESTS  (each is optional)
    // -------------------------------------------------------------------------
    // Before running tests (which internally re-run qreg and clobber e()),
    // snapshot the matrices we care about so we can restore them at the end.
    tempname _s_b_lr_pos _s_b_lr_neg _s_t_lr_pos _s_t_lr_neg ///
             _s_b_lr_int _s_b_lr_lin _s_b_lr_det                ///
             _s_b_sr _s_V_sr _s_b_urecm _s_V_urecm _s_phi_y
    local _save_matrices "b_lr_pos b_lr_neg t_lr_pos t_lr_neg b_lr_int b_lr_lin b_lr_det b_sr V_sr b_urecm V_urecm phi_y"
    foreach mn of local _save_matrices {
        capture matrix `_s_`mn'' = e(`mn')
        if _rc local _have_`mn' = 0
        else   local _have_`mn' = 1
    }
    local _save_engine     = "`e(engine)'"
    capture local _save_have_xqcoint = e(have_xqcoint)
    if _rc local _save_have_xqcoint ""

    if "`bounds'" != "" {
        _qnardl_bounds ,                                        ///
            depvar(`depvar')                                    ///
            pos_vars(`asym_pos_vars')                           ///
            neg_vars(`asym_neg_vars')                           ///
            linear_vars(`linear_vars')                          ///
            exog(`exog')                                        ///
            tau(`tau')                                          ///
            p(`p_lag') q(`q_lag') r(`r_lag')                    ///
            case(`case')                                        ///
            trendvar(`trendvar')                                ///
            touse(`touse')                                      ///
            sim(`simulate')
        // bring r() results into e()
        tempname bnd_mat
        capture matrix `bnd_mat' = r(bounds)
        if !_rc {
            ereturn matrix bounds = `bnd_mat'
            cap ereturn scalar cv_F_lo = r(cv_F_lo)
            cap ereturn scalar cv_F_hi = r(cv_F_hi)
            cap ereturn scalar cv_t_lo = r(cv_t_lo)
            cap ereturn scalar cv_t_hi = r(cv_t_hi)
        }
    }
    local wald_common ///
        depvar(`depvar') pos_vars(`asym_pos_vars') neg_vars(`asym_neg_vars') ///
        linear_vars(`linear_vars') exog(`exog') tau(`tau') ///
        p(`p_lag') q(`q_lag') r(`r_lag') ///
        case(`case') trendvar(`trendvar') touse(`touse')

    if "`lrsymmetry'" != "" {
        _qnardl_wald , type(lrsym) `wald_common'
    }
    if "`srsymmetry'" != "" {
        _qnardl_wald , type(srsym) `wald_common'
    }
    if "`interpercentile'" != "" {
        _qnardl_wald , type(interquart) `wald_common' sim(`simulate')
    }
    if "`interdecile'" != "" {
        _qnardl_wald , type(interdec) `wald_common' sim(`simulate')
    }

    // CUSUM and CUSUM-square stability tests (Brown/Durbin/Evans 1975)
    if "`cusum'" != "" {
        if "`cusumtau'" == "" local cusumtau 0.5
        _qnardl_cusum ,                                         ///
            depvar(`depvar')                                    ///
            pos_vars(`asym_pos_vars')                           ///
            neg_vars(`asym_neg_vars')                           ///
            linear_vars(`linear_vars')                          ///
            exog(`exog')                                        ///
            tauuse(`cusumtau')                                  ///
            p(`p_lag') q(`q_lag') r(`r_lag')                    ///
            case(`case')                                        ///
            trendvar(`trendvar')                                ///
            touse(`touse')
    }

    // Diagnostic tests (BG, BPG, JB, RESET)
    if "`diagnostics'" != "" {
        if "`bglags'" == "" local bglags 4
        _qnardl_diagnostics ,                                   ///
            depvar(`depvar')                                    ///
            pos_vars(`asym_pos_vars')                           ///
            neg_vars(`asym_neg_vars')                           ///
            linear_vars(`linear_vars')                          ///
            exog(`exog')                                        ///
            tau(`tau')                                          ///
            p(`p_lag') q(`q_lag') r(`r_lag')                    ///
            case(`case')                                        ///
            trendvar(`trendvar')                                ///
            touse(`touse')                                      ///
            bglags(`bglags')
    }

    // Dynamic multipliers per quantile (Shin/Yu/G-N 2014 style)
    if "`multipliers'" != "" {
        if "`horizon'" == "" local horizon 12
        _qnardl_multipliers ,                                   ///
            depvar(`depvar')                                    ///
            pos_vars(`asym_pos_vars')                           ///
            neg_vars(`asym_neg_vars')                           ///
            linear_vars(`linear_vars')                          ///
            exog(`exog')                                        ///
            tau(`tau')                                          ///
            p(`p_lag') q(`q_lag') r(`r_lag')                    ///
            case(`case')                                        ///
            trendvar(`trendvar')                                ///
            touse(`touse')                                      ///
            horizon(`horizon')
        // capture multiplier matrices for later qnardl_mgraph
        tempname _s_mult_pos _s_mult_neg
        capture matrix `_s_mult_pos' = r(mult_pos)
        capture matrix `_s_mult_neg' = r(mult_neg)
        local _mult_horizon = r(horizon)
    }

    // -------------------------------------------------------------------------
    // RESTORE estimation matrices that internal qreg calls clobbered.
    // -------------------------------------------------------------------------
    foreach mn of local _save_matrices {
        if `_have_`mn'' {
            capture ereturn matrix `mn' = `_s_`mn''
        }
    }
    if "`_save_engine'" != "" capture ereturn local engine = "`_save_engine'"
    if "`_save_have_xqcoint'" != "" capture ereturn scalar have_xqcoint = `_save_have_xqcoint'

    // Re-attach multiplier matrices (computed before this restore block)
    if "`multipliers'" != "" {
        capture ereturn matrix mult_pos = `_s_mult_pos'
        capture ereturn matrix mult_neg = `_s_mult_neg'
        capture ereturn scalar horizon_mult = `_mult_horizon'
    }

    // -------------------------------------------------------------------------
    // STEP 5: ERETURN finalisation
    // -------------------------------------------------------------------------
    ereturn local cmd        "qnardl"
    ereturn local cmdline    `"`cmd' `cmdline_orig'"'
    ereturn local cmdversion "0.1.0"
    ereturn local depvar     "`depvar'"
    ereturn local asymvars   "`asymmetry'"
    ereturn local linvars    "`linear_vars'"
    ereturn local exogvars   "`exog'"
    ereturn local pos_vars   "`asym_pos_vars'"
    ereturn local neg_vars   "`asym_neg_vars'"
    ereturn local method     "`method'"
    ereturn local step1      "`step1'"
    ereturn local trendvar   "`trendvar'"
    ereturn local ic_type    "`ic_type'"
    ereturn local title      "QNARDL"
    ereturn local author     "Dr Merwan Roudane"
    ereturn local email      "merwanroudane920@gmail.com"
    ereturn local predict    "qnardl_p"
    ereturn local estat_cmd  "qnardl_estat"
    ereturn scalar N         = `nobs'
    ereturn scalar k         = `k_asym'
    ereturn scalar k_lin     = `k_lin'
    ereturn scalar ntau      = `ntau'
    ereturn scalar p_lag     = `p_lag'
    ereturn scalar q_lag     = `q_lag'
    ereturn scalar r_lag     = `r_lag'
    ereturn scalar case      = `case'
    ereturn scalar level     = `level'

    // Display final tables (reads everything from e())
    if "`ctable'" == "" {
        _qnardl_display , `full' `bytau' level(`level')
    }

    // Optional graphs
    if "`graph'" != "" {
        capture noisily qnardl_graph , type(all) level(`level')
    }
end


// =============================================================================
// HELPER: infer Bertsatos et al. 2022 case from option flags
// =============================================================================
program define _qnardl_infer_case, rclass
    syntax , [const(string) trendvar(string) quad(string) restricted(string)]

    local has_const  = ("`const'" == "")              // noconstant absent => has constant
    local has_trend  = ("`trendvar'" != "")
    local has_quad   = ("`quad'" != "")
    local restr      = ("`restricted'" != "")

    if !`has_const' & !`has_trend' & !`has_quad' {
        local c = 1                                    // Case I: no det.
    }
    else if `has_const' & !`has_trend' & !`has_quad' & `restr' {
        local c = 2                                    // Case II: restricted intercept
    }
    else if `has_const' & !`has_trend' & !`has_quad' & !`restr' {
        local c = 3                                    // Case III: unrestricted intercept
    }
    else if `has_const' & `has_trend' & !`has_quad' & `restr' {
        local c = 4                                    // Case IV: unrestr int + restr trend
    }
    else if `has_const' & `has_trend' & !`has_quad' & !`restr' {
        local c = 5                                    // Case V: unrestr int + unrestr trend
    }
    else if `has_quad' & `restr' {
        local c = 8                                    // Case VIII: + restr quadratic
    }
    else if `has_quad' & !`restr' {
        local c = 9                                    // Case IX
    }
    else {
        local c = 3                                    // safe default
    }
    return scalar case = `c'
end
