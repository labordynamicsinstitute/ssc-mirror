*! quasicoint.ado - Quasi-Cointegration Analysis without Unit Roots
*! Version 1.0.2 - 2026-05-09
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Implements:
*!   Duffy, J.A. & Simons, J.R. (2023). Cointegration without Unit Roots.
*!     Cambridge Working Papers in Economics 2332.
*!
*! Features:
*!   - Quasi-cointegrating space (QCS) estimation via spectral decomposition
*!   - Conditional LR tests for cointegrating coefficients (given lambda)
*!   - Profile likelihood across dominant root values
*!   - Elliott-Mueller-Watson nearly optimal (NP) tests
*!   - Bonferroni-based robust confidence intervals
*!   - Beautiful visualisation and publication-quality tables
*!   - LaTeX / Excel / CSV export
*!
*! Methodology:
*!   Standard cointegration estimators (FM-OLS, DOLS, Johansen ML) break down
*!   when autoregressive roots are near (but not exactly at) unity (Elliott 1998).
*!   Quasi-cointegration identifies long-run relationships via the *relative
*!   decay rate* of impulse responses, remaining valid even without exact unit
*!   roots. The quasi-cointegrating space (QCS) coincides with the standard
*!   cointegrating space (CS) when unit roots are exact.

capture program drop quasicoint
program define quasicoint, eclass
    version 14

    // --- Syntax ---------------------------------------------------------------
    syntax varlist(min=2 numeric ts) [if] [in], ///
        [RHO(string)                  /// real: lower bound on dominant root (default=0.95)
         NRoots(string)               /// integer: number of near-unit roots q (default=1)
         LAGS(string)                 /// integer: VAR lag order k (0=auto via AIC)
         MAXLags(string)              /// integer: maximum lags for AIC selection (default=8)
         GRIDsize(string)             /// integer: number of grid points for lambda profile (default=50)
         NBOOT(string)                /// integer: Monte Carlo reps for NP test (default=2000)
         NOCONStant                   /// suppress intercept in VAR
         TREND                        /// include linear trend in VAR
         PLot                         /// produce all visualisation plots
         PLotprofile                   /// plot: profile likelihood + conditional CIs
         PLotirf                      /// plot: impulse response comparison
         PLotroots                    /// plot: characteristic root map
         EXPort(string)               /// excel|latex|csv|all
         SAVing(string)               /// filename prefix for plots/exports
         NOIsily                      /// verbose output
         LEVel(cilevel)               /// confidence level (default 95)
         ]

    // --- Defaults & conversion ------------------------------------------------
    if "`rho'"     == "" local rho     0.95
    else                 local rho     = real("`rho'")
    if "`nroots'"  == "" local nroots  1
    else                 local nroots  = real("`nroots'")
    if "`lags'"    == "" local lags    0
    else                 local lags    = real("`lags'")
    if "`maxlags'" == "" local maxlags 8
    else                 local maxlags = real("`maxlags'")
    if "`gridsize'"== "" local gridsize 50
    else                 local gridsize= real("`gridsize'")
    if "`nboot'"   == "" local nboot   2000
    else                 local nboot   = real("`nboot'")
    if "`level'"   == "" local level   95
    if "`saving'"  == "" local saving  "quasicoint"

    local q = `nroots'

    // --- Validate -------------------------------------------------------------
    foreach opt in rho nroots lags maxlags gridsize nboot {
        if missing(``opt'') {
            di as error "Option `opt'() must be a valid number."
            exit 198
        }
    }
    if `rho' < 0 | `rho' > 1 {
        di as error "rho() must be in [0, 1]. Got `rho'."
        exit 198
    }
    if `q' < 1 {
        di as error "nroots() must be >= 1. Got `q'."
        exit 198
    }

    // --- Sample ---------------------------------------------------------------
    marksample touse
    markout `touse' `varlist'

    // --- Parse varlist --------------------------------------------------------
    local allvars `varlist'
    local nvars : word count `allvars'
    local p = `nvars'
    local r = `p' - `q'

    if `r' < 1 {
        di as error "Number of variables (`p') must exceed nroots (`q')."
        di as error "Need at least q+1 = `=`q'+1' variables."
        exit 102
    }

    // --- Time-series check ----------------------------------------------------
    qui tsset
    local timevar = "`r(timevar)'"
    if "`timevar'" == "" {
        di as error "Data must be tsset before using quasicoint."
        exit 198
    }

    // --- Count usable observations --------------------------------------------
    qui count if `touse'
    local nobs = r(N)
    if `nobs' < 20 {
        di as error "Too few observations (`nobs'). Need at least 20."
        exit 2001
    }

    // =========================================================================
    //  HEADER
    // =========================================================================
    di ""
    di as text "  {hline 72}"
    di as text "  {bf:quasicoint} — Quasi-Cointegration Analysis (Duffy & Simons 2023)"
    di as text "  {hline 72}"
    di ""
    di as text "  Variables:       " as result "`allvars'"
    di as text "  Observations:    " as result "`nobs'"
    di as text "  Dimension p:     " as result "`p'"
    di as text "  Near-unit roots: " as result "q = `q'"
    di as text "  QCS dimension:   " as result "r = `r'"
    di as text "  Root lower bound:" as result "rho = `rho'"
    local halflife = -log(2)/log(`rho')
    di as text "  Half-life bound: " as result %6.1f `halflife' " periods"
    di as text "  Confidence:      " as result "`level'%"
    di ""

    // =========================================================================
    //  STEP 1: ESTIMATE VAR
    // =========================================================================
    // Determine lag order
    local k = `lags'
    if `k' == 0 {
        di as text "  Selecting lag order via AIC (max = `maxlags')..."
        local bestaic = .
        local bestk   = 1
        forvalues kk = 1/`maxlags' {
            qui var `allvars' if `touse', lags(1/`kk') `noconstant'
            qui estat ic
            tempname ictab
            matrix `ictab' = r(S)
            local thisaic = `ictab'[1,5]
            if `thisaic' < `bestaic' {
                local bestaic = `thisaic'
                local bestk   = `kk'
            }
        }
        local k = `bestk'
        di as text "  Selected lag order: k = " as result "`k'" as text " (AIC = " as result %10.2f `bestaic' as text ")"
    }
    else {
        di as text "  Using specified lag order: k = " as result "`k'"
    }

    // Estimate the VAR
    local varopts "lags(1/`k')"
    if "`noconstant'" != "" local varopts "`varopts' noconstant"
    if "`trend'" != ""      local varopts "`varopts' exog(_trend)"

    // Generate trend if needed
    if "`trend'" != "" {
        tempvar ttrend
        qui gen `ttrend' = _n if `touse'
        local varopts "lags(1/`k')"
        if "`noconstant'" != "" local varopts "`varopts' noconstant"
    }

    qui var `allvars' if `touse', `varopts'
    local nobs_eff = e(N)
    di as text "  VAR(`k') estimated with " as result "`nobs_eff'" as text " effective observations"

    // =========================================================================
    //  STEP 2: COMPANION FORM & EIGENVALUES
    // =========================================================================
    di ""
    di as text "  Computing companion form eigenvalues..."

    // Load Mata engine
    capture findfile _quasicoint_mata.ado
    if _rc {
        // Mata code is embedded below — source it
        capture mata: mata describe _qc_companion()
        if _rc {
            qui run "`c(sysdir_plus)'q/quasicoint/_quasicoint_mata.ado"
            capture mata: mata describe _qc_companion()
            if _rc {
                // Try local directory
                capture findfile _quasicoint_mata.ado
                if !_rc {
                    qui run `"`r(fn)'"'
                }
                else {
                    // Inline the Mata code
                    qui run "`c(pwd)'/_quasicoint_mata.ado"
                }
            }
        }
    }
    else {
        qui run `"`r(fn)'"'
    }

    // Build companion matrix and do spectral decomposition in Mata
    mata: _qc_main("`allvars'", "`touse'", `k', `p', `q', `rho', ///
                   `gridsize', `nboot', `level', ///
                   "`noconstant'", "`trend'", "`noisily'")

    // =========================================================================
    //  STEP 3: DISPLAY RESULTS
    // =========================================================================
    _quasicoint_display, level(`level') p(`p') q(`q') k(`k') ///
        rho(`rho') nobs(`nobs_eff') vars(`allvars') `noisily'

    // =========================================================================
    //  STEP 4: PLOTS
    // =========================================================================
    if "`plot'" != "" | "`plotprofile'" != "" | "`plotirf'" != "" | "`plotroots'" != "" {
        local gopt ""
        if "`plot'" != ""        local gopt "all"
        if "`plotprofile'" != "" local gopt "profile"
        if "`plotirf'" != ""    local gopt "irf"
        if "`plotroots'" != ""  local gopt "roots"

        _quasicoint_plot, graph(`gopt') saving(`saving') ///
            p(`p') q(`q') k(`k') rho(`rho') vars(`allvars') level(`level')
    }

    // =========================================================================
    //  STEP 5: EXPORT
    // =========================================================================
    if "`export'" != "" {
        _quasicoint_export, format(`export') saving(`saving') ///
            p(`p') q(`q') k(`k') rho(`rho') vars(`allvars') level(`level')
    }

    // =========================================================================
    //  STEP 6: STORE e() RESULTS
    // =========================================================================

    // beta is p x r. The free parameters are the last q rows (the A matrix).
    // For ereturn post we need a 1 x q row vector and q x q V matrix.
    tempname b_qc V_qc b_post V_post

    matrix `b_qc' = _qc_beta
    matrix `V_qc' = _qc_V

    // Extract free coefficients: last q rows, first column
    // (for r=1 cointegrating relation, this is the "a" parameter)
    local nfree = `q'
    matrix `b_post' = J(1, `nfree', 0)
    forvalues j = 1/`nfree' {
        matrix `b_post'[1, `j'] = `b_qc'[`r' + `j', 1]
    }

    // Build V_post: q x q
    local v_rows = rowsof(`V_qc')
    local v_cols = colsof(`V_qc')
    if `v_rows' >= `nfree' & `v_cols' >= `nfree' {
        matrix `V_post' = `V_qc'[1..`nfree', 1..`nfree']
    }
    else {
        matrix `V_post' = I(`nfree') * 0.01
    }

    // Build variable names for free parameters
    local freevars ""
    forvalues j = `=`r'+1'/`p' {
        local vj : word `j' of `allvars'
        local freevars "`freevars'`vj' "
    }
    local freevars = strtrim("`freevars'")

    // Name matrices
    capture {
        matrix colnames `b_post' = `freevars'
        matrix colnames `V_post' = `freevars'
        matrix rownames `V_post' = `freevars'
    }

    // Post primary result
    ereturn post `b_post' `V_post', esample(`touse')

    // Additional matrices (use capture since some may not exist)
    capture ereturn matrix beta_qcs      = _qc_beta
    capture ereturn matrix beta_johansen = _qc_beta_joh
    capture ereturn matrix eigenvalues   = _qc_eigenvalues
    capture ereturn matrix R_LU          = _qc_RLU
    capture ereturn matrix Lambda_LU     = _qc_LambdaLU
    capture ereturn matrix profile_ll    = _qc_profile_ll
    capture ereturn matrix profile_grid  = _qc_profile_grid
    capture ereturn matrix cond_ci       = _qc_cond_ci
    capture ereturn matrix IRF_qc        = _qc_irf
    capture ereturn matrix IRF_johansen  = _qc_irf_joh
    capture ereturn matrix np_ci         = _qc_np_ci

    // Scalars
    ereturn scalar N           = `nobs_eff'
    ereturn scalar p           = `p'
    ereturn scalar q           = `q'
    ereturn scalar r           = `r'
    ereturn scalar k           = `k'
    ereturn scalar rho         = `rho'
    ereturn scalar halflife    = `halflife'
    ereturn scalar level       = `level'
    ereturn scalar lambda_hat  = _qc_lambda_hat
    ereturn scalar LR_lambda   = _qc_LR_lambda
    ereturn scalar gridsize    = `gridsize'
    ereturn scalar nboot       = `nboot'
    capture ereturn scalar johansen_trace = _qc_joh_trace

    // Strings
    ereturn local cmd        "quasicoint"
    ereturn local cmdline    "quasicoint `0'"
    ereturn local varlist    "`allvars'"
    ereturn local timevar    "`timevar'"
    ereturn local title      "Quasi-Cointegration (Duffy & Simons 2023)"
    ereturn local paper      "Duffy & Simons (2023, CWPE 2332)"
    ereturn local vcetype    "Conditional LR (chi-squared)"

    // --- Final notes ----------------------------------------------------------
    di ""
    di as text "  {it:Primary e(b), e(V): QCS free coefficients (at profile-max lambda).}"
    di as text "  {it:Full vectors: e(beta_qcs), e(beta_johansen). CIs: e(cond_ci).}"
    di ""
end
