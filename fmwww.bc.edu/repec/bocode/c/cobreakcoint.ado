*! cobreakcoint.ado — Quasi-Likelihood Ratio Tests for CI, CB & CT
*! Version 1.0.0 — 2026-04-18
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Implements the tests from:
*!   "Quasi-likelihood ratio tests for cointegration, cobreaking,
*!    and cotrending" — Econometric Reviews (2019).
*!
*! Tests:
*!   Qr      — Robust cointegration test (robust to CB/CT)
*!   Qcb     — Joint CI & Cobreaking test
*!   Qct     — Joint CI & Cotrending test (Model II only)
*!   Dmax_cb — Double-max joint CI/CB test
*!   Dmax_ct — Double-max joint CI/CT test (Model II only)
*!
*! MATLAB source translated: longvar.m, DOLS_reg_maker.m,
*!   CK_Qknown_new.m, CK_Qunknown1_Bdate.m, CK_Qunknown2_Bdate.m,
*!   Application_Rev.m
*!
*! Data: time-series data (tsset timevar)
*! Dependencies: Mata (built-in), _cobreakcoint_*.ado helpers

capture program drop cobreakcoint
program define cobreakcoint, eclass
    version 14

    // ── Syntax ──────────────────────────────────────────────────────────
    syntax varlist(min=2 numeric ts) [if] [in], ///
        [Model(string)          /// 1 or 2 (default: 2)
         MAXBreaks(string)      /// max breaks: 0, 1, or 2 (default: 2)
         KLags(string)          /// DOLS lag/lead spec: "1 3 5 7 9" (default)
         Epsilon(string)        /// trimming fraction (default: 0.15)
         PLot                   /// produce visualization plots
         NOTable                /// suppress output tables
         SAVing(string)         /// filename stem for saving graphs
         NOIsily                /// verbose output
         ]

    // ── Parse options ──────────────────────────────────────────────────
    if "`model'" == "" local model "2"
    local model_n = real("`model'")
    if !inlist(`model_n', 1, 2) {
        di as error "model() must be 1 or 2."
        exit 198
    }

    if "`maxbreaks'" == "" local maxbreaks "2"
    local maxm = real("`maxbreaks'")
    if !inlist(`maxm', 0, 1, 2) {
        di as error "maxbreaks() must be 0, 1, or 2."
        exit 198
    }

    if "`klags'" == "" local klags "1 3 5 7 9"

    if "`epsilon'" == "" local epsilon "0.15"
    local eps_n = real("`epsilon'")

    local verbose = ("`noisily'" != "")

    // ── Sample ─────────────────────────────────────────────────────────
    marksample touse
    markout `touse' `varlist'

    // ── Parse varlist ──────────────────────────────────────────────────
    local depvar    : word 1 of `varlist'
    local indepvars : list varlist - depvar
    local nv        : word count `indepvars'
    local px        = `nv'

    if `nv' < 1 {
        di as error "cobreakcoint requires at least one independent variable."
        exit 102
    }
    if `nv' > 2 {
        di as error "cobreakcoint supports px = 1 or 2 stochastic regressors (current: `nv')."
        exit 198
    }

    // ── Count observations ─────────────────────────────────────────────
    quietly count if `touse'
    local T = r(N)
    if `T' < 50 {
        di as error "cobreakcoint requires at least 50 observations (current: `T')."
        exit 2001
    }

    // ── Count klags entries ────────────────────────────────────────────
    local nk : word count `klags'

    // ── Display running message ────────────────────────────────────────
    if `model_n' == 1 {
        local modlab "I (mean shifts)"
    }
    else {
        local modlab "II (trend + intercept shifts)"
    }

    di ""
    di as text "  {bf:cobreakcoint} {c -} Quasi-Likelihood Ratio Tests for CI, CB & CT"
    di as text "  Running: T = `T' | Model `modlab' | px = `px'"
    di as text "  DOLS lags/leads: `klags' | Max breaks: `maxm'"
    di as text "  Computing test statistics..."
    di ""

    // ── Load Mata engine ───────────────────────────────────────────────
    capture mata: mata describe cobreakcoint_main
    if _rc {
        // Try current directory first
        capture quietly do "_cobreakcoint_mata.ado"
        if _rc {
            // Try findfile (searches adopath)
            capture findfile _cobreakcoint_mata.ado
            if !_rc {
                capture quietly do `"`r(fn)'"'
            }
            if _rc {
                // Try PLUS directory
                local mypath : sysdir PLUS
                capture quietly do `"`mypath'c/cobreakcoint/_cobreakcoint_mata.ado"'
            }
        }
    }

    // ── Call Mata engine ───────────────────────────────────────────────
    mata: cobreakcoint_main("`depvar'", "`indepvars'", "`touse'", ///
                            `model_n', `maxm', "`klags'", `verbose')

    // ── Display tables ─────────────────────────────────────────────────
    if "`notable'" == "" {
        _cobreakcoint_display, ///
            depvar(`depvar') indepvar(`indepvars') ///
            model(`model_n') tobs(`T') px(`px') ///
            nk(`nk') maxm(`maxm') klags(`klags')
    }

    // ── Plots ──────────────────────────────────────────────────────────
    if "`plot'" != "" {
        local save_opt ""
        if "`saving'" != "" local save_opt "saving(`saving')"

        _cobreakcoint_plot, ///
            depvar(`depvar') indepvar(`indepvars') ///
            model(`model_n') tobs(`T') px(`px') ///
            nk(`nk') maxm(`maxm') `save_opt'
    }

    // ── Store results in e() ───────────────────────────────────────────
    tempname TestM_e ACV5_e Bmat_e Bfm_e

    matrix `TestM_e' = _cbc_TestM
    matrix `ACV5_e'  = _cbc_ACV5
    matrix `Bmat_e'  = _cbc_Bmat
    matrix `Bfm_e'   = _cbc_Bfm

    // Column names for TestM
    matrix colnames `TestM_e' = Q01 Q02 Q03 Q11 Q12 Q13 Q21 Q22 Q23 Dmax_cb Dmax_ct k
    matrix colnames `ACV5_e'  = Q01 Q02 Q03 Q11 Q12 Q13 Q21 Q22 Q23 Dmax_cb Dmax_ct k

    ereturn clear
    ereturn post, esample(`touse')

    ereturn matrix TestM    = `TestM_e'
    ereturn matrix ACV5     = `ACV5_e'
    ereturn matrix Bmat     = `Bmat_e'
    ereturn matrix Bfrac    = `Bfm_e'

    ereturn scalar T          = `T'
    ereturn scalar px         = `px'
    ereturn scalar model      = `model_n'
    ereturn scalar maxbreaks  = `maxm'
    ereturn scalar nk         = `nk'

    ereturn local cmd         "cobreakcoint"
    ereturn local cmdline     "cobreakcoint `0'"
    ereturn local depvar      "`depvar'"
    ereturn local indepvars   "`indepvars'"
    ereturn local klags       "`klags'"
    ereturn local modtype     "`modlab'"

    di as text "  {it:Note: All results stored in e(). Use ereturn list for details.}"
    di as text "  {it:  e(TestM) = test statistics matrix (Q01..Q23, Dmax_cb, Dmax_ct, k)}"
    di as text "  {it:  e(ACV5)  = 5% asymptotic critical values}"
    di as text "  {it:  e(Bmat)  = estimated break dates}"
    di as text "  {it:  e(Bfrac) = estimated break fractions}"
    di ""
end
