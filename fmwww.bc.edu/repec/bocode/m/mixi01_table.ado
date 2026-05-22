*! mixi01_table 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! mixi01_table — Beautiful table display for mixi01 estimation results
*! Reads e() results from mixi01 estimation commands and displays them

program define mixi01_table
    version 17.0

    syntax [, Level(cilevel) NOHeader NOFooter Wide]

    /* ── check that estimation results exist ── */
    if "`e(cmd)'" == "" {
        di as err "no mixi01 estimation results found"
        exit 301
    }

    local method  "`e(method)'"
    local kernel  "`e(kernel)'"
    local bwidth  = e(bwidth)
    local N       = e(N)
    local k       = e(k)
    local k1      = e(k_stat)
    local k2      = e(k_nonstat)
    local r2      = e(r2)
    local r2a     = e(r2_a)
    local rmse    = e(rmse)
    local lr_se   = e(omega_ee2)
    local depvar  "`e(depvar)'"

    /* ── header ── */
    if "`noheader'" == "" {
        _mixi01_table_header, method(`method') depvar(`depvar') ///
            kernel(`kernel') bwidth(`bwidth') ///
            n(`N') k(`k') k1(`k1') k2(`k2') ///
            r2(`r2') r2a(`r2a') rmse(`rmse') lr_se(`lr_se')
    }

    /* ── coefficient table ── */
    _mixi01_table_coefs, level(`level') `wide'

    /* ── footer ── */
    if "`nofooter'" == "" {
        _mixi01_table_footer
    }
end


/* ================================================================== */
/*  Header display                                                     */
/* ================================================================== */
program define _mixi01_table_header
    version 17.0

    syntax , method(string) depvar(string) ///
        kernel(string) bwidth(real) ///
        n(real) k(real) k1(real) k2(real) ///
        r2(real) r2a(real) rmse(real) lr_se(real)

    /* Pretty method name */
    local method_full ""
    if "`method'" == "fmols"     local method_full "Fully Modified OLS"
    else if "`method'" == "fmvar" local method_full "Fully Modified VAR"
    else if "`method'" == "fmiv"  local method_full "Fully Modified IV"
    else if "`method'" == "svar"  local method_full "Structural VAR (mixed)"
    else if "`method'" == "vecm"  local method_full "VECM"
    else                          local method_full "`method'"

    /* Pretty kernel name */
    local kernel_full ""
    if "`kernel'" == "bartlett"       local kernel_full "Bartlett"
    else if "`kernel'" == "parzen"    local kernel_full "Parzen"
    else if "`kernel'" == "qs"        local kernel_full "Quadratic Spectral"
    else if "`kernel'" == "tukey"     local kernel_full "Tukey-Hanning"
    else                              local kernel_full "`kernel'"

    di ""
    di as txt "{hline 78}"
    di as res _col(2) "`method_full'" ///
       as txt _col(44) "Number of obs" _col(62) "=" ///
       as res _col(64) %12.0fc `n'
    di as txt _col(2) "Dep. variable: " as res "`depvar'" ///
       as txt _col(44) "Regressors" _col(62) "=" ///
       as res _col(64) %12.0fc `k'
    di ""
    di as txt _col(2) "Kernel: " as res "`kernel_full'" ///
       as txt _col(44) "I(0) regressors" _col(62) "=" ///
       as res _col(64) %12.0fc `k1'
    di as txt _col(2) "Bandwidth: " as res %5.1f `bwidth' ///
       as txt _col(44) "I(1) regressors" _col(62) "=" ///
       as res _col(64) %12.0fc `k2'
    di ""

    /* Fit statistics */
    di as txt _col(2) "R-squared" _col(16) "=" ///
       as res _col(18) %10.6f `r2' ///
       as txt _col(44) "LR residual var" _col(62) "=" ///
       as res _col(64) %12.6f `lr_se'

    di as txt _col(2) "Adj R-squared" _col(16) "=" ///
       as res _col(18) %10.6f `r2a' ///
       as txt _col(44) "RMSE" _col(62) "=" ///
       as res _col(64) %12.6f `rmse'

    di as txt "{hline 78}"
end


/* ================================================================== */
/*  Coefficient display with integration order panels                  */
/* ================================================================== */
program define _mixi01_table_coefs
    version 17.0

    syntax [, Level(cilevel) Wide]

    local k1 = e(k_stat)
    local k2 = e(k_nonstat)

    /* ── Column headers ── */
    di as txt _col(14) "{c |}" ///
       _col(17) "Coef." ///
       _col(29) "LR Std.Err." ///
       _col(44) "t" ///
       _col(50) "P>|t|" ///
       _col(60) "[`level'% Conf. Interval]"
    di as txt "{hline 13}{c +}{hline 64}"

    /* ── I(1) block ── */
    if `k2' > 0 & `"`e(ns_names)'"' != "" {
        di as res _col(2) "I(1)" as txt " regressors {c |}"

        local ns_names "`e(ns_names)'"
        local j = 0
        foreach vn of local ns_names {
            local ++j
            local idx = `k1' + `j'
            _mixi01_coef_row, name(`vn') idx(`idx') level(`level') tag("I(1)")
        }

        di as txt "{hline 13}{c +}{hline 64}"
    }

    /* ── I(0) block ── */
    if `k1' > 0 & `"`e(st_names)'"' != "" {
        di as res _col(2) "I(0)" as txt " regressors {c |}"

        local st_names "`e(st_names)'"
        local j = 0
        foreach vn of local st_names {
            local ++j
            _mixi01_coef_row, name(`vn') idx(`j') level(`level') tag("I(0)")
        }

        di as txt "{hline 13}{c +}{hline 64}"
    }

    /* ── Fallback: if no separate blocks stored, use _coef_table ── */
    if `"`e(ns_names)'"' == "" & `"`e(st_names)'"' == "" {
        /* Use Stata's built-in coefficient table */
        _coef_table, level(`level')
    }
end


/* ================================================================== */
/*  Single coefficient row display                                     */
/* ================================================================== */
program define _mixi01_coef_row
    version 17.0

    syntax , name(string) idx(integer) level(cilevel) [tag(string)]

    tempname b V

    matrix `b' = e(b)
    matrix `V' = e(V)

    local coef = `b'[1, `idx']
    local se   = sqrt(`V'[`idx', `idx'])

    if `se' < 1e-14 {
        local tstat = .
        local pval  = .
        local ci_lo = .
        local ci_hi = .
    }
    else {
        local tstat = `coef' / `se'
        local df    = e(N) - e(k)
        if `df' < 1 local df = e(N) - 1
        local pval  = 2 * ttail(`df', abs(`tstat'))
        local crit  = invttail(`df', (100 - `level') / 200)
        local ci_lo = `coef' - `crit' * `se'
        local ci_hi = `coef' + `crit' * `se'
    }

    /* Truncate variable name */
    local dname = abbrev("`name'", 12)

    /* Display row */
    di as txt %12s "`dname'" " {c |}" ///
       as res %11.6f `coef' ///
       as res %13.6f `se' ///
       as res %8.2f `tstat' ///
       as res %8.3f `pval' ///
       as res %12.6f `ci_lo' ///
       as res %12.6f `ci_hi' ///
       as txt "  " as txt "`tag'"
end


/* ================================================================== */
/*  Footer display                                                     */
/* ================================================================== */
program define _mixi01_table_footer
    version 17.0

    local method "`e(method)'"

    di ""
    di as txt _col(2) "Asymptotic inference based on Phillips (1995) FM corrections."

    /* Method-specific notes */
    if "`method'" == "fmols" {
        di as txt _col(2) "I(1) block: " ///
           as res "mixed-normal" ///
           as txt " asymptotics; I(0) block: " ///
           as res "standard normal"
    }
    else if "`method'" == "fmvar" {
        di as txt _col(2) "System FM-VAR with equation-by-equation correction"
    }

    if "`e(eqtrend)'" == "1" {
        di as txt _col(2) "Equation includes deterministic linear trend"
    }

    di as txt _col(2) "Long-run variance: " as res "`e(kernel)'" ///
       as txt " kernel, bandwidth = " as res e(bwidth)
    di ""
end
