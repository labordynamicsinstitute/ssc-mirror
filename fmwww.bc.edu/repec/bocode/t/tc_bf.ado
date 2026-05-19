*! tc_bf.ado -- Balke-Fomby sup-Wald (1997)
program define tc_bf, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, MAXLag(integer 4) TRIM(real 0.15) NGrid(integer 300)]
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    tempname supw thr lags gv gs
    mata: tc_run_bf("`depvar'", "`indepvars'", "`touse'", `maxlag', `trim', `ngrid', "`supw'", "`thr'", "`lags'", "`gv'", "`gs'")

    di
    di as text "{hline 72}"
    di as result "  Balke-Fomby (1997) sup-Wald test"
    di as text "{hline 72}"
    di as text "  sup-Wald statistic       : " as result %10.4f scalar(`supw')
    di as text "  Estimated threshold      : " as result %10.4f scalar(`thr')
    di as text "  Lags                     : " as result %10.0f scalar(`lags')
    di as text "{hline 72}"

    return scalar sup_wald = scalar(`supw')
    return matrix grid_values = `gv'
    return matrix grid_stats = `gs'
    return local cmd "tc_bf"
end
