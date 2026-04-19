*! _cupfm_display.ado - Clean journal-quality output for cupfm
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Version: 1.0.2 - 2026-04-18 (Fix: updated version string in banner)
*!   - Fixed table alignment (uniform 11-char estimator columns)
*!   - t-stats as (xx.xx) with 2 decimal places, fixed-width stars
*!   - Removed References section from output
*!   - Compact Panel Information layout

capture program drop _cupfm_display
program define _cupfm_display
    version 14
    // STATA 17 BATCH FIX: all numeric options as string(), converted manually
    syntax, ///
        DEPvar(string)        ///
        INDepvars(string)     ///
        PANelvar(string)      ///
        TIMevar(string)       ///
        Ng(string)            ///
        Tperiods(string)      ///
        Nobs(string)          ///
        Rfactors(string)      ///
        Bwidth(string)        ///
        Mxiter(string)        ///
        Niter(string)         ///
        [NOICsummary]

    // Convert string -> integer
    local ng       = int(real("`ng'"))
    local tperiods = int(real("`tperiods'"))
    local nobs     = int(real("`nobs'"))
    local rfactors = int(real("`rfactors'"))
    local bwidth   = int(real("`bwidth'"))
    local mxiter   = int(real("`mxiter'"))
    local niter    = int(real("`niter'"))

    // Critical values (95% CI hardcoded)
    local cv01 = 2.576
    local cv05 = 1.960
    local cv10 = 1.645

    // Retrieve stored matrices
    tempname B_lsdv B_bai B_cup B_cup2 B_bc
    tempname T_lsdv T_bai T_cup T_cup2 T_bc
    matrix `B_lsdv'  = _cupfm_b_lsdv
    matrix `B_bai'   = _cupfm_b_baifm
    matrix `B_cup'   = _cupfm_b_cupfm
    matrix `B_cup2'  = _cupfm_b_cupfm2
    matrix `B_bc'    = _cupfm_b_cupbc
    matrix `T_lsdv'  = _cupfm_t_lsdv
    matrix `T_bai'   = _cupfm_t_baifm
    matrix `T_cup'   = _cupfm_t_cupfm
    matrix `T_cup2'  = _cupfm_t_cupfm2
    matrix `T_bc'    = _cupfm_t_cupbc

    local nv  : word count `indepvars'
    local k = `nv'

    // ── Convergence & factor info ──────────────────────────────────────────
    local _cv_cup   = _cupfm_cvar
    local _cv_bc    = _cupfm_cvar_bc
    local _conv_flag = _cupfm_converged
    local _conv_s = cond(`_conv_flag', "Converged", "Max iter")

    // ═══════════════════════════════════════════════════════════════════════
    //  BANNER
    // ═══════════════════════════════════════════════════════════════════════
    di ""
    di as text "  {hline 74}"
    di as text "  {bf:cupfm} {c -} Panel Cointegration with Common Factors" ///
               "  | v1.0.2  `=c(current_date)'"
    di as text "  Bai, Kao {c &} Ng (2009, JoE 149:82-99)" ///
               "  {c |}  Bai {c &} Kao (2005, SSRN-1815227)"
    di as text "  {hline 74}"
    di ""

    // ═══════════════════════════════════════════════════════════════════════
    //  TABLE 1: PANEL INFORMATION  (two-column key:value layout)
    // ═══════════════════════════════════════════════════════════════════════
    di as text "  {bf:Panel Information}"
    di as text "  {hline 74}"
    di as text "  " %-22s "Dependent variable" " : " ///
               as result %-14s "`depvar'" ///
               as text "  " %-18s "Regressors" " : " as result "`indepvars'"
    di as text "  " %-22s "Panel variable" " : " ///
               as result %-14s "`panelvar'" ///
               as text "  " %-18s "Time variable" " : " as result "`timevar'"
    di as text "  " %-22s "Cross-sections (N)" " : " ///
               as result %-14s "`ng'" ///
               as text "  " %-18s "Time periods (T)" " : " as result "`tperiods'"
    di as text "  " %-22s "Observations (N*T)" " : " ///
               as result %-14s "`nobs'" ///
               as text "  " %-18s "Panel type" " : " as result "Balanced"
    di as text "  " %-22s "Common factors (r)" " : " ///
               as result %-14s "`rfactors'" ///
               as text "  " %-18s "Bandwidth (M)" " : " as result "`bwidth' (Bartlett)"
    di as text "  " %-22s "Max iterations" " : " ///
               as result %-14s "`mxiter'" ///
               as text "  " %-18s "CupFM iterations" " : " as result "`niter'"
    di as text "  {hline 74}"
    di ""

    // ═══════════════════════════════════════════════════════════════════════
    //  TABLE 2: ESTIMATION RESULTS
    //  Layout: 2 + 12(var) + 3(pipe) + 5 x 11(est) = 72 chars wide
    // ═══════════════════════════════════════════════════════════════════════
    di as text "  {bf:Estimation Results}"
    di as text "  {hline 74}"

    // Column headers ── uniform 11-char columns
    di as text "  " %12s "Variable" "  {c |}" ///
        %11s "LSDV" %11s "Bai FM" %11s "CupFM" %11s "CupFM-z" %11s "CupBC"
    di as text "  {hline 14}{c +}{hline 58}"

    forvalues j = 1/`k' {
        local vname : word `j' of `indepvars'
        local vn    = abbrev("`vname'", 10)

        // Coefficients
        local b1 = `B_lsdv'[1,`j']
        local b2 = `B_bai'[1,`j']
        local b3 = `B_cup'[1,`j']
        local b4 = `B_cup2'[1,`j']
        local b5 = `B_bc'[1,`j']

        // t-statistics
        local t1 = `T_lsdv'[1,`j']
        local t2 = `T_bai'[1,`j']
        local t3 = `T_cup'[1,`j']
        local t4 = `T_cup2'[1,`j']
        local t5 = `T_bc'[1,`j']

        // Stars (fixed 3-char width for alignment)
        foreach s in 1 2 3 4 5 {
            local abs_t = abs(`t`s'')
            if      `abs_t' >= `cv01' local star`s' "***"
            else if `abs_t' >= `cv05' local star`s' "**"
            else if `abs_t' >= `cv10' local star`s' "*"
            else                      local star`s' "   "
        }

        // Coefficient line: %7.4f + %-3s star = 10 chars inside 11-char col
        di as text   "  " %12s "`vn'" "  {c |}" ///
            as result " " %7.4f `b1' as text "`star1'" ///
            as result " " %7.4f `b2' as text "`star2'" ///
            as result " " %7.4f `b3' as text "`star3'" ///
            as result " " %7.4f `b4' as text "`star4'" ///
            as result " " %7.4f `b5' as text "`star5'"

        // t-stat line: (xx.xx) = 7 chars inside 11-char col
        di as text   "  " %12s "" "  {c |}" ///
            "   (" %6.2f `t1' ")" ///
            "   (" %6.2f `t2' ")" ///
            "   (" %6.2f `t3' ")" ///
            "   (" %6.2f `t4' ")" ///
            "   (" %6.2f `t5' ")"

        if `j' < `k' di as text "  {hline 14}{c +}{hline 58}"
    }

    di as text "  {hline 14}{c BT}{hline 58}"
    di as text "  t-statistics in parentheses" ///
               "  |  *** p<0.01  ** p<0.05  * p<0.10  (95% CI)"
    di as text "  CupFM = recommended estimator (BKN 2009, Theorem 3)" ///
               "  |  CupFM-z = Z-bar variant"
    di ""

    // ═══════════════════════════════════════════════════════════════════════
    //  TABLE 3: FACTOR STRUCTURE DIAGNOSTICS
    // ═══════════════════════════════════════════════════════════════════════
    if "`noicsummary'" == "" {
        tempname L_hat
        matrix `L_hat' = _cupfm_lambda

        di as text "  {bf:Factor Structure Diagnostics}" ///
               as text "  (Bai {c &} Ng 2002 IC)"
        di as text "  {hline 74}"
        di as text "  Common factors (r) : " as result `rfactors'
        if `rfactors' > 0 {
            di as text "  Factor loading |{it:lambda}| column means:" _continue
            forvalues ri = 1/`rfactors' {
                local cs = 0
                forvalues ii = 1/`ng' {
                    local cs = `cs' + abs(`L_hat'[`ii',`ri'])
                }
                local lmean`ri' = `cs'/`ng'
                di as text "  Factor `ri' : " as result %6.4f `lmean`ri'' _continue
            }
            di ""
        }
        di as text "  Bartlett bandwidth : " as result `bwidth' ///
                   as text "  |  Kernel : Bartlett" ///
                   as text "  |  IC : Bai {c &} Ng (2002)"
        di as text "  {hline 74}"
        di ""
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  TABLE 4: CONVERGENCE SUMMARY
    // ═══════════════════════════════════════════════════════════════════════
    di as text "  {bf:Convergence Summary}"
    di as text "  {hline 55}"
    di as text "  " %-9s "Estimator" " {c |}" ///
        %12s "Iterations" %18s "Omega_cond_var" %14s "Status"
    di as text "  {hline 10}{c +}{hline 44}"
    di as text "  " %-9s "CupFM" " {c |}" ///
        as result %12.0f `niter' ///
        as result %18.6f `_cv_cup' ///
        as result %14s "`_conv_s'"
    di as text "  " %-9s "CupBC" " {c |}" ///
        as result %12.0f `mxiter' ///
        as result %18.6f `_cv_bc' ///
        as result %14s "Fixed iter"
    di as text "  " %-9s "Bai FM" " {c |}" ///
        as result %12.0f 1 ///
        as text   %18s "---" ///
        as result %14s "One-step"
    di as text "  {hline 55}"
    di ""
end
