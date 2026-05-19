*! tc_setar.ado -- SETAR(2)
program define tc_setar, rclass
    version 14
    syntax varname(numeric) [if] [in] [, LAG(integer 1) DELAY(integer 1) THReshold(real -999) TRIM(real 0.15) NGrid(integer 300)]
    marksample touse
    _tc_load
    local th_in = `threshold'
    if `threshold' == -999 local th_in .

    tempname thr lags n1 n2 ssr
    mata: tc_run_setar("`varlist'", "`touse'", `lag', `delay', `th_in', `trim', `ngrid', "`thr'", "`lags'", "`n1'", "`n2'", "`ssr'")

    di
    di as text "{hline 72}"
    di as result "  SETAR(2) -- Self-Exciting Threshold Autoregressive"
    di as text "{hline 72}"
    di as text "  Total SSR                : " as result %10.4f scalar(`ssr')
    di as text "  Threshold                : " as result %10.4f scalar(`thr')
    di as text "  Regime obs (1/2)         : " as result %8.0f scalar(`n1') " / " %8.0f scalar(`n2')
    di as text "{hline 72}"

    return scalar threshold = scalar(`thr')
    return scalar ssr = scalar(`ssr')
    return local cmd "tc_setar"
end
