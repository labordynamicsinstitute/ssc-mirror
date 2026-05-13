*! xtccecoint.ado — Panel CCE Cointegration Test
*! Version 1.0.0 — 2026-05-11
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Implements the CADF_P panel cointegration test from:
*!   Banerjee, A. & Carrion-i-Silvestre, J.L. (2017).
*!   "Testing for Panel Cointegration Using Common Correlated Effects Estimators."
*!   Journal of Time Series Analysis, DOI: 10.1111/jtsa.12234
*!
*! GAUSS source translated: cadfcoin_multiple.src
*!   by Josep Lluis Carrion-i-Silvestre (August 21st, 2021)
*!
*! Key options mirror the GAUSS sample.prg setup:
*!   model   : 0=none, 1=constant, 2=constant+trend   [GAUSS: model = 0|1|2]
*!   nfactors: number of common factors               [GAUSS: num_factors]
*!   method  : 0=no CCE, 1=CCE                        [GAUSS: method = 0|1]
*!   option  : 0=Individual, 1=MG, 2=Pooled CCE       [GAUSS: option = 0|1|2]
*!   plags   : AR order for CADF regression           [GAUSS: p]
*!
*! Data: Stata long format (xtset panelvar timevar), balanced panel required

capture program drop xtccecoint
program define xtccecoint, eclass
    version 14

    // ── Syntax ──────────────────────────────────────────────────────────────
    syntax varlist(min=2 numeric) [if] [in], ///
        [Model(string)          /// 0, 1, or 2 (default: 2)
         NFactors(string)       /// number of common factors (default: k+1)
         Method(string)         /// 0=no CSD, 1=CCE (default: 1)
         OPTion(string)         /// 0=individual, 1=MG, 2=pooled (default: 2)
         PLags(string)          /// AR lag order for CADF (default: 1)
         NOTRuncate             /// suppress truncation of t-ratios
         PLot                   /// produce visualization plots
         NOTable                /// suppress output tables
         SAVing(string)         /// filename stem for saving graphs
         NOIsily                /// verbose Mata output
         ]

    // ── Parse options ────────────────────────────────────────────────────────
    if "`model'"    == "" local model    "2"
    if "`method'"   == "" local method   "1"
    if "`option'"   == "" local option   "2"
    if "`plags'"    == "" local plags    "1"

    local model_n  = real("`model'")
    local method_n = real("`method'")
    local option_n = real("`option'")
    local plags_n  = real("`plags'")

    if !inlist(`model_n', 0, 1, 2) {
        di as error "model() must be 0, 1, or 2."
        exit 198
    }
    if !inlist(`method_n', 0, 1) {
        di as error "method() must be 0 (no CSD) or 1 (CCE)."
        exit 198
    }
    if !inlist(`option_n', 0, 1, 2) {
        di as error "option() must be 0 (individual), 1 (MG), or 2 (pooled CCE)."
        exit 198
    }

    local do_trunc = ("`notruncate'" == "")
    local verbose  = ("`noisily'"    != "")

    // ── Sample ──────────────────────────────────────────────────────────────
    marksample touse
    markout `touse' `varlist'

    // ── Validate panel structure ─────────────────────────────────────────────
    qui xtset
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"

    if "`panelvar'" == "" {
        di as error "Data must be xtset before calling xtccecoint."
        exit 459
    }

    // ── Parse varlist ────────────────────────────────────────────────────────
    local depvar    : word 1 of `varlist'
    local indepvars : list varlist - depvar
    local k         : word count `indepvars'

    if `k' < 1 {
        di as error "xtccecoint requires at least one independent variable."
        exit 102
    }

    // ── Default nfactors = k+1 (rank condition with equality) ────────────────
    if "`nfactors'" == "" local nfactors = `k' + 1
    local nfactors_n = real("`nfactors'")
    if `nfactors_n' < 1 {
        di as error "nfactors() must be a positive integer."
        exit 198
    }

    // ── Count observations ───────────────────────────────────────────────────
    qui xtsum `depvar' if `touse'
    local N_g = r(n)
    local T   = r(Tbar)

    if `N_g' < 5 {
        di as error "xtccecoint requires at least 5 panel units."
        exit 2000
    }
    if `T' < 20 {
        di as error "xtccecoint requires at least 20 time periods."
        exit 2001
    }

    // ── Model label ──────────────────────────────────────────────────────────
    if `model_n' == 0 local modlab "0 (no deterministics)"
    else if `model_n' == 1 local modlab "1 (constant)"
    else local modlab "2 (constant + trend)"

    // ── Estimator label ──────────────────────────────────────────────────────
    if `method_n' == 0 local estlab "OLS (no cross-section dependence)"
    else {
        if `option_n' == 0 local estlab "Individual CCE"
        else if `option_n' == 1 local estlab "Mean Group CCE (MG-CCE)"
        else local estlab "Pooled CCE (PCCE) [recommended]"
    }

    // ── Display running message ──────────────────────────────────────────────
    di ""
    di as text "  {bf:xtccecoint} {c -} Panel CCE Cointegration Test"
    di as text "  Banerjee & Carrion-i-Silvestre (2017, JTSA)"
    di as text "  " "{hline 65}"
    di as text "  N = `N_g' units | T ≈ `=round(`T')' periods"
    di as text "  Model: `modlab'"
    di as text "  Estimator: `estlab'"
    di as text "  Common factors (r): `nfactors_n' | AR lags (p): `plags_n'"
    if `do_trunc' di as text "  Truncation: ON (Pesaran 2007)"
    else           di as text "  Truncation: OFF"
    di as text "  Computing..."
    di ""

    // ── Load Mata engine ─────────────────────────────────────────────────────
    capture mata: mata describe xtcce_main
    if _rc {
        capture quietly do "_xtccecoint_mata.ado"
        if _rc {
            capture findfile _xtccecoint_mata.ado
            if !_rc {
                capture quietly do `"`r(fn)'"'
            }
            if _rc {
                local mypath : sysdir PLUS
                capture quietly do `"`mypath'x/xtccecoint/_xtccecoint_mata.ado"'
            }
        }
    }

    // ── Call Mata engine ─────────────────────────────────────────────────────
    mata: xtcce_main("`depvar'", "`indepvars'",    ///
                     "`touse'",  "`panelvar'",       ///
                     "`timevar'",                    ///
                     `model_n',  `nfactors_n',       ///
                     `method_n', `option_n',         ///
                     `plags_n',  `do_trunc',         ///
                     `verbose')

    // ── Retrieve scalars ─────────────────────────────────────────────────────
    local cadfp = _xcce_cadfp
    local N_obs = _xcce_N
    local T_obs = _xcce_T
    local k_obs = _xcce_k
    local r_obs = _xcce_r

    // ── Get critical values ──────────────────────────────────────────────────
    // Look up 5% and 10% CVs using embedded tables
    mata: st_numscalar("_xcce_cv5",  xtcce_cv_lookup(`model_n', `k_obs'+1, `nfactors_n', `plags_n', `T_obs', `N_obs', 5))
    mata: st_numscalar("_xcce_cv10", xtcce_cv_lookup(`model_n', `k_obs'+1, `nfactors_n', `plags_n', `T_obs', `N_obs', 10))
    local cv5  = _xcce_cv5
    local cv10 = _xcce_cv10

    // ── Display output tables ────────────────────────────────────────────────
    if "`notable'" == "" {
        _xtccecoint_display,            ///
            cadfp(`cadfp')              ///
            cv5(`cv5') cv10(`cv10')     ///
            nunits(`N_obs')             ///
            tperiods(`T_obs')           ///
            kregs(`k_obs')              ///
            rfactors(`r_obs')           ///
            plagopt(`plags_n')          ///
            modelopt(`model_n')         ///
            depopt(`depvar')            ///
            indepopt(`indepvars')       ///
            panopt(`panelvar')          ///
            timeopt(`timevar')          ///
            estlab(`estlab')            ///
            dotrunc(`do_trunc')
    }

    // ── Plots ────────────────────────────────────────────────────────────────
    if "`plot'" != "" {
        local save_opt ""
        if "`saving'" != "" local save_opt "saving(`saving')"

        _xtccecoint_plot,               ///
            depopt(`depvar')            ///
            indepopt(`indepvars')       ///
            modelopt(`model_n')         ///
            nunits(`N_obs')             ///
            tperiods(`T_obs')           ///
            plagopt(`plags_n')          ///
            cv5(`cv5') cv10(`cv10')     ///
            `save_opt'
    }

    // ── Store results in e() ─────────────────────────────────────────────────
    tempname b_pcce V_pcce t_ind beta_vec ids_vec

    // Build e(b) from PCCE estimate
    matrix `beta_vec' = _xcce_beta
    matrix colnames `beta_vec' = `indepvars'

    // Build dummy e(V)
    matrix `V_pcce' = J(`k_obs', `k_obs', 0)
    matrix colnames `V_pcce' = `indepvars'
    matrix rownames `V_pcce' = `indepvars'

    ereturn clear
    ereturn post `beta_vec' `V_pcce', esample(`touse')

    // Individual statistics
    matrix `t_ind' = _xcce_t_ind
    ereturn matrix cadf_ind = `t_ind'

    // Scalars
    ereturn scalar cadfp     = `cadfp'
    ereturn scalar cv5       = `cv5'
    ereturn scalar cv10      = `cv10'
    ereturn scalar N         = `N_obs'
    ereturn scalar T         = `T_obs'
    ereturn scalar k         = `k_obs'
    ereturn scalar nfactors  = `r_obs'
    ereturn scalar plags     = `plags_n'
    ereturn scalar model     = `model_n'
    ereturn scalar method    = `method_n'
    ereturn scalar opttype   = `option_n'
    ereturn scalar truncated = `do_trunc'

    // Macros
    ereturn local cmd       "xtccecoint"
    ereturn local cmdline   "xtccecoint `0'"
    ereturn local depvar    "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local panelvar  "`panelvar'"
    ereturn local timevar   "`timevar'"
    ereturn local estimator "`estlab'"
    ereturn local modtype   "`modlab'"
    ereturn local papers    "Banerjee & Carrion-i-Silvestre (2017, JTSA)"

    di as text "  Note: All results stored in {cmd:e()}. Use {cmd:ereturn list} for details."
    di as text "  CADF_P = {res:`=string(round(`cadfp',0.0001))'}"
    di ""
end
