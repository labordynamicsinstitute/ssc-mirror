*! tc_bbc.ado -- BBC (2004) unit root vs SETAR
program define tc_bbc, rclass
    version 14
    syntax varname(numeric) [if] [in] [, M(integer 1) TRIM(real 0.10) TYPE(string)]
    if "`type'" == "" local type "Wald"
    marksample touse
    _tc_load

    tempname stat cv
    mata: tc_run_bbc("`varlist'", "`touse'", `m', `trim', "`type'", "`stat'", "`cv'")

    di
    di as text "{hline 72}"
    di as result "  BBC (2004) unit root vs SETAR test (type = `type')"
    di as text "{hline 72}"
    di as text "  sup-`type' statistic     : " as result %10.4f scalar(`stat')
    di as text "  Critical (1% / 5% / 10%) : " as result %8.3f el(`cv',1,1) " " %8.3f el(`cv',1,2) " " %8.3f el(`cv',1,3)
    di as text "{hline 72}"

    return scalar sup_stat = scalar(`stat')
    return matrix cv = `cv'
    return local cmd "tc_bbc"
end
