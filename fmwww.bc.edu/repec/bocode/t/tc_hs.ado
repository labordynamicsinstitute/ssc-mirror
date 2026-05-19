*! tc_hs.ado -- Hansen-Seo (2002) supLM
program define tc_hs, rclass
    version 14
    syntax varlist(min=2 max=2 numeric) [if] [in] [, LAG(integer 1) BETA(real -99) TRIM(real 0.05) NGrid(integer 300)]
    marksample touse
    _tc_load

    local bv = `beta'
    if `beta' == -99 local bv .

    tempname stat thr be lags gv gs
    mata: tc_run_hs("`varlist'", "`touse'", `lag', `bv', `trim', `ngrid', "`stat'", "`thr'", "`be'", "`lags'", "`gv'", "`gs'")

    di
    di as text "{hline 72}"
    di as result "  Hansen-Seo (2002) supLM test"
    di as text "{hline 72}"
    di as text "  supLM statistic          : " as result %10.4f scalar(`stat')
    di as text "  Estimated threshold      : " as result %10.4f scalar(`thr')
    di as text "  beta (cointegrating)     : " as result %10.4f scalar(`be')
    di as text "{hline 72}"

    return scalar sup_lm = scalar(`stat')
    return matrix grid_values = `gv'
    return matrix grid_stats = `gs'
    return local cmd "tc_hs"
end
