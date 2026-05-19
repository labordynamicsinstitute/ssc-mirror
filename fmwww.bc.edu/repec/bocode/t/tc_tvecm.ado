*! tc_tvecm.ado -- Threshold VECM (2 regimes)
program define tc_tvecm, rclass
    version 14
    syntax varlist(min=2 max=2 numeric) [if] [in] [, LAG(integer 1) TRIM(real 0.05) BETA(real -99) NGrid(integer 300)]
    marksample touse
    _tc_load
    local bv = `beta'
    if `beta' == -99 local bv .

    tempname thr be lags n1 n2 ssr ect
    mata: tc_run_tvecm("`varlist'", "`touse'", `lag', `trim', `bv', `ngrid', "`thr'", "`be'", "`lags'", "`n1'", "`n2'", "`ssr'", "`ect'")

    di
    di as text "{hline 72}"
    di as result "  TVECM (2 regimes) -- Hansen-Seo / Lo-Zivot framework"
    di as text "{hline 72}"
    di as text "  Total SSR (system)       : " as result %10.4f scalar(`ssr')
    di as text "  Threshold                : " as result %10.4f scalar(`thr')
    di as text "  Cointegrating beta       : " as result %10.4f scalar(`be')
    di as text "  Regime obs (1/2)         : " as result %8.0f scalar(`n1') " / " %8.0f scalar(`n2')
    di as text "{hline 72}"

    return scalar threshold = scalar(`thr')
    return scalar beta_est = scalar(`be')
    return scalar ssr = scalar(`ssr')
    return matrix ect = `ect'
    return local cmd "tc_tvecm"
end
