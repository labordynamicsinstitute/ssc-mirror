*! cupfm.ado - Panel Cointegration with Common Factors
*! Version 1.0.1 - 2026-04-16 (First SSC submission)
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Implements all estimators from:
*!   Bai, J., Kao, C. & Ng, S. (2009). Panel cointegration with global
*!     stochastic trends. Journal of Econometrics, 149(1), 82-99.
*!   Bai, J. & Kao, C. (2005). On the estimation and inference of a panel
*!     cointegration model with cross-sectional dependence.
*!     CPR Working Paper No. 75, Syracuse University. SSRN-1815227.
*!
*! Estimators (exactly as in GAUSS bkn source code):
*!   LSDV     : Within/fixed-effects (baseline, biased under CS dependence)
*!   Bai FM   : One-shot 2-step FM  [Bai & Kao 2005, Eq. 7-8]
*!   CupFM    : Continuously-Updated FM  [BKN 2009, Theorem 3, Eq. 16]
*!   CupFM-bar: CupFM with Z-bar instrument  [BKN 2009, alternative]
*!   CupBC    : Continuously-Updated BC  [BKN 2009, Theorem 2]
*!
*! Data: Stata long format (xtset panelvar timevar), balanced panel required
*! Long->Wide conversion handled internally in Mata (matches GAUSS bkn)
*!
*! Dependencies: Mata (built-in), _cupfm_*.ado helpers

capture program drop cupfm
program define cupfm, eclass
    version 14

    // --- Syntax ---------------------------------------------------------------
    // STATA 17 BATCH FIX: integer() and real() options cause r(197) "invalid
    // syntax" in Stata 17 batch mode. ALL numeric options are declared as
    // string() and converted manually below. This does NOT affect any calling
    // syntax - users still write nfactors(2), bandwidth(5) etc. as normal.
    // Also: LEVEL() is reserved by Stata eclass - do NOT declare it.
    // Also: fv removed from varlist - cupfm uses numeric panel data only.
    syntax varlist(min=2 numeric ts) [if] [in], ///
        [NFactors(string)              /// integer: 0 = auto-select via Bai-Ng (2002) IC
         BANDwidth(string)             /// integer: Bartlett kernel bandwidth (default=5)
         KERnel(string)                /// string:  bartlett|parzen (default: bartlett)
         MAXiter(string)               /// integer: max CupFM/CupBC iterations (default=20)
         TOLerance(string)             /// real:    convergence tolerance (default=0.0001)
         AUTORMAX(string)              /// integer: max r in auto-selection (default=8)
         NOICsummary                  /// suppress factor diagnostics table
         PLot                         /// produce all visualization plots
         PLotcoef                     /// plot: coefficient comparison only
         PLotfactors                  /// plot: estimated factors only
         PLotloadings                 /// plot: factor loadings only
         EXPort(string)               /// excel|latex|csv|all
         SAVing(string)               /// filename (no extension) for export/plots
         NOIsily                      /// verbose Mata output
         ]

    // --- Convert string options -> numeric & apply defaults -------------------
    if "`nfactors'"  == "" local nfactors  0
    else                    local nfactors  = real("`nfactors'")
    if "`bandwidth'" == "" local bandwidth 5
    else                    local bandwidth = real("`bandwidth'")
    if "`maxiter'"   == "" local maxiter   20
    else                    local maxiter   = real("`maxiter'")
    if "`tolerance'" == "" local tolerance 0.0001
    else                    local tolerance = real("`tolerance'")
    if "`autormax'"  == "" local autormax  8
    else                    local autormax  = real("`autormax'")
    local level 95   // hardcoded; LEVEL is reserved by Stata eclass

    // --- Validate numeric conversions -----------------------------------------
    foreach opt in nfactors bandwidth maxiter autormax {
        if missing(``opt'') {
            di as error "Option `opt'() must be a valid integer."
            exit 198
        }
        local `opt' = int(``opt'')
    }
    if missing(`tolerance') {
        di as error "Option tolerance() must be a valid real number."
        exit 198
    }

    // --- Sample ---------------------------------------------------------------
    marksample touse
    markout `touse' `varlist'

    // --- Parse varlist --------------------------------------------------------
    local depvar    : word 1 of `varlist'
    local indepvars : list varlist - depvar
    local nv        : word count `indepvars'

    if `nv' < 1 {
        di as error "cupfm requires at least one independent variable."
        exit 102
    }

    // --- Validate -------------------------------------------------------------
    _cupfm_validate `varlist' if `touse', ///
        nfactors(`nfactors') bandwidth(`bandwidth') ///
        maxiter(`maxiter') tolerance(`tolerance')

    local N_g      = r(N_g)
    local T        = r(T)
    local N_obs    = r(N_obs)
    local rmax     = r(rmax)
    local panelvar = "`r(panelvar)'"
    local timevar  = "`r(timevar)'"

    // --- Factor number logic --------------------------------------------------
    local do_autoR = 0
    local r_use    = `nfactors'
    if `nfactors' == 0 {
        local do_autoR = 1
        local r_use    = 1   // Mata will update this
    }

    // --- Kernel ---------------------------------------------------------------
    if "`kernel'" == "" local kernel "bartlett"
    if !inlist("`kernel'", "bartlett", "parzen") {
        di as error "kernel() must be 'bartlett' or 'parzen'."
        exit 198
    }

    // --- Sort data ------------------------------------------------------------
    sort `panelvar' `timevar'

    // --- DISPLAY: Running message ---------------------------------------------
    di ""
    di as text "  {bf:cupfm} - Panel Cointegration with Common Factors"
    di as text "  Running `=`N_g'' units x `=`T'' periods = `=`N_obs'' observations"
    if `do_autoR' {
        di as text "  Factor number: auto-select via Bai-Ng (2002) IC (rmax=`autormax')"
    }
    else {
        di as text "  Factor number: specified r = `r_use'"
    }
    di as text "  Bandwidth: `bandwidth' (`kernel' kernel)"
    di as text "  Max iterations: `maxiter'"
    di as text "  Estimating..."
    di ""

    // --- LOAD MATA ENGINE -----------------------------------------------------
    // If cupfm_main is not already in memory, load _cupfm_mata.ado via adopath.
    capture mata: mata describe cupfm_main
    if _rc {
        capture quietly do "_cupfm_mata.ado"
        if _rc {
            // Last resort: check Stata PLUS directory
            local mypath : sysdir PLUS
            capture quietly do `"`mypath'c/cupfm/_cupfm_mata.ado"'
        }
    }

    // Re-sort (in case adopath loading changed dataset state)
    sort `panelvar' `timevar'

    // --- CALL MATA ENGINE - results stored in _cupfm_* global matrices --------
    mata: cupfm_main("`depvar'", "`indepvars'", "`touse'", ///
                     `N_g', `T', `r_use', `bandwidth', ///
                     "`kernel'", `maxiter', `do_autoR', `autormax', ///
                     `=cond("`noisily'"!="",1,0)')

    // --- Transfer _cupfm_ Stata scalars to local macros ----------------------
    local r_final     = _cupfm_r
    local niter_cupfm = _cupfm_niter
    local cvar_cupfm  = _cupfm_cvar
    local cvar_cupbc  = _cupfm_cvar_bc
    local converged   = _cupfm_converged

    // --- DISPLAY TABLES -------------------------------------------------------
    _cupfm_display, ///
        depvar(`depvar') indepvars(`indepvars') ///
        panelvar(`panelvar') timevar(`timevar') ///
        ng(`N_g') tperiods(`T') nobs(`N_obs') ///
        rfactors(`r_final') bwidth(`bandwidth') mxiter(`maxiter') ///
        niter(`niter_cupfm') ///
        `noicsummary'

    // --- PLOTS ----------------------------------------------------------------
    // IMPORTANT: must run BEFORE ereturn matrix (which DROPS _cupfm_b_* globals)
    if "`plot'" != "" | "`plotcoef'" != "" | "`plotfactors'" != "" | "`plotloadings'" != "" {
        local graph_opt ""
        if "`plotcoef'" != ""     local graph_opt "coef"
        if "`plotfactors'" != ""  local graph_opt "factors"
        if "`plotloadings'" != "" local graph_opt "loadings"
        if "`plot'" != ""         local graph_opt "all"

    // Pre-build option strings - avoids nested-quote r(132) in cond() expressions
        local saving_opt ""
        if "`saving'" != "" local saving_opt "saving(`saving')"
        local graph_arg "graph(all)"
        if "`graph_opt'" != "" local graph_arg "graph(`graph_opt')"

        _cupfm_plot, ///
            depvar(`depvar') indepvars(`indepvars') ///
            timevar(`timevar') ng(`N_g') tobs(`T') rfact(`r_final') ///
            `saving_opt' `graph_arg'
    }

    // --- EXPORT ---------------------------------------------------------------
    // IMPORTANT: must run BEFORE ereturn matrix (which DROPS _cupfm_b_* globals)
    if "`export'" != "" {
        if "`saving'" == "" {
            local saving "cupfm_results"
        }
        _cupfm_export, ///
            depvar(`depvar') indepvars(`indepvars') ///
            ng(`N_g') tobs(`T') rfact(`r_final') bwuse(`bandwidth') ///
            niter(`niter_cupfm') ///
            format(`export') saving(`saving')
    }

    // --- STORE IN e() ---------------------------------------------------------
    tempname b_cupfm V_cupfm

    // Build coefficient row vector for e(b): CupFM is the primary estimator
    matrix `b_cupfm' = _cupfm_b_cupfm

    // Build diagonal variance matrix: V_jj = (b_j / t_j)^2 = se_j^2
    matrix `V_cupfm' = J(`nv', `nv', 0)
    forvalues j = 1/`nv' {
        local bj = _cupfm_b_cupfm[1, `j']
        local tj = _cupfm_t_cupfm[1, `j']
        if abs(`tj') > 0.0001 {
            matrix `V_cupfm'[`j', `j'] = (`bj'/`tj')^2
        }
        else {
            matrix `V_cupfm'[`j', `j'] = 0
        }
    }

    // Name b and V with IDENTICAL column names - required by ereturn post
    matrix colnames `b_cupfm' = `indepvars'
    matrix rownames `V_cupfm' = `indepvars'
    matrix colnames `V_cupfm' = `indepvars'

    // Post primary result - clears previous e()
    ereturn post `b_cupfm' `V_cupfm', esample(`touse')

    // Additional coefficient matrices
    ereturn matrix beta_lsdv   = _cupfm_b_lsdv
    ereturn matrix beta_baifm  = _cupfm_b_baifm
    ereturn matrix beta_cupfm  = _cupfm_b_cupfm
    ereturn matrix beta_cupfm2 = _cupfm_b_cupfm2
    ereturn matrix beta_cupbc  = _cupfm_b_cupbc

    ereturn matrix tstat_lsdv   = _cupfm_t_lsdv
    ereturn matrix tstat_baifm  = _cupfm_t_baifm
    ereturn matrix tstat_cupfm  = _cupfm_t_cupfm
    ereturn matrix tstat_cupfm2 = _cupfm_t_cupfm2
    ereturn matrix tstat_cupbc  = _cupfm_t_cupbc

    // Factor/rotation matrices
    ereturn matrix F_hat    = _cupfm_f
    ereturn matrix Lambda   = _cupfm_lambda
    ereturn matrix Aik      = _cupfm_aik
    ereturn matrix Omega    = _cupfm_omega
    ereturn matrix Omega_bc = _cupfm_omega_bc

    // Scalars
    ereturn scalar Nobs        = `N_obs'
    ereturn scalar Ng          = `N_g'
    ereturn scalar Tperiods    = `T'
    ereturn scalar nfactors    = `r_final'
    ereturn scalar bw          = `bandwidth'
    ereturn scalar maxiter     = `maxiter'
    ereturn scalar niter       = `niter_cupfm'
    ereturn scalar cvar_cupfm  = `cvar_cupfm'
    ereturn scalar cvar_cupbc  = `cvar_cupbc'
    ereturn scalar level       = `level'
    ereturn scalar converged   = `converged'

    // Strings
    ereturn local cmd       "cupfm"
    ereturn local cmdline   "cupfm `0'"
    ereturn local depvar    "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local panelvar  "`panelvar'"
    ereturn local timevar   "`timevar'"
    ereturn local kernel    "`kernel'"
    ereturn local estimator "CupFM"
    ereturn local papers    "Bai, Kao & Ng (2009, JoE); Bai & Kao (2005, SSRN)"
    ereturn local vcetype   "Mixed normal (BKN 2009 Theorem 3)"

    di as text "  {it:Note: Primary result e(b), e(V) correspond to CupFM.}"
    di as text "  {it:All 5 estimators available in e(beta_*) and e(tstat_*).}"
    di ""
end
