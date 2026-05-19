*! tc_pp.ado -- Phillips-Perron unit-root test
program define tc_pp, rclass
    version 14
    syntax varname(numeric) [if] [in] [, LAGS(integer 0) CASE(string)]
    if "`case'" == "" local case "c"
    marksample touse
    _tc_load

    local lg = `lags'
    if `lags' == 0 local lg .

    tempname stat lags_used nobs cv
    mata: tc_run_pp("`varlist'", "`touse'", "`case'", `lg', "`stat'", "`lags_used'", "`nobs'", "`cv'")

    di
    di as text "{hline 60}"
    di as result "  Phillips-Perron test on `varlist'"
    di as text "  case = `case'"
    di as text "{hline 60}"
    di as text "  PP Z(t)      : " as result %10.4f scalar(`stat')
    di as text "  NW bandwidth : " as result %10.0f scalar(`lags_used')
    di as text "  N obs        : " as result %10.0f scalar(`nobs')
    di as text "  Critical 1%  : " as result %10.4f el(`cv',1,1)
    di as text "  Critical 5%  : " as result %10.4f el(`cv',1,2)
    di as text "  Critical 10% : " as result %10.4f el(`cv',1,3)
    di as text "{hline 60}"

    return scalar stat = scalar(`stat')
    return scalar lags = scalar(`lags_used')
    return scalar nobs = scalar(`nobs')
    return matrix cv = `cv'
    return local cmd "tc_pp"
end
