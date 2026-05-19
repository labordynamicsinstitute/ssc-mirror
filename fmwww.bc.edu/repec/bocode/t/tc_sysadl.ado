*! tc_sysadl.ado -- System-equation ADL (Li 2016)
program define tc_sysadl, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, LAG(integer 1) TRIM(real 0.15) NGrid(integer 200) CASE(string)]
    if "`case'" == "" local case "c"
    marksample touse
    _tc_load

    tempname stat thr lags
    mata: tc_run_sysadl("`varlist'", "`touse'", `lag', `trim', `ngrid', "`case'", "`stat'", "`thr'", "`lags'")

    di
    di as text "{hline 72}"
    di as result "  System-equation ADL test (Li 2016)"
    di as text "{hline 72}"
    di as text "  sup-Wald (system)        : " as result %10.4f scalar(`stat')
    di as text "  Threshold                : " as result %10.4f scalar(`thr')
    di as text "{hline 72}"

    return scalar sup_wald = scalar(`stat')
    return scalar threshold = scalar(`thr')
    return local cmd "tc_sysadl"
end
