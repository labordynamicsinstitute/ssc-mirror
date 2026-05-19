*! tc_kss.ado -- KSS (2006) nonlinear cointegration
program define tc_kss, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, CASE(integer 1) MAXLag(integer 8) CRITerion(string)]
    if "`criterion'" == "" local criterion "aic"
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    tempname stat lags cv
    mata: tc_run_kss("`depvar'", "`indepvars'", "`touse'", `case', `maxlag', "`criterion'", "`stat'", "`lags'", "`cv'")

    di
    di as text "{hline 72}"
    di as result "  KSS (2006) nonlinear cointegration test"
    di as text "{hline 72}"
    di as text "  KSS t-statistic          : " as result %10.4f scalar(`stat')
    di as text "  Lags                     : " as result %10.0f scalar(`lags')
    di as text "  Critical (1% / 5% / 10%) : " as result %8.3f el(`cv',1,1) " " %8.3f el(`cv',1,2) " " %8.3f el(`cv',1,3)
    di as text "{hline 72}"

    return scalar t_stat = scalar(`stat')
    return matrix cv = `cv'
    return local cmd "tc_kss"
end
