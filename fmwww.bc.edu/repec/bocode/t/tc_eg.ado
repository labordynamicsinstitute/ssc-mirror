*! tc_eg.ado -- Engle-Granger cointegration test
program define tc_eg, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, MAXLag(integer 0) CASE(string) CRITerion(string)]
    if "`case'" == "" local case "c"
    if "`criterion'" == "" local criterion "aic"
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    local mlg = `maxlag'
    if `maxlag' == 0 local mlg .

    tempname stat lags nobs m cv coint
    mata: tc_run_eg("`depvar'", "`indepvars'", "`touse'", `mlg', "`case'", "`criterion'", "`stat'", "`lags'", "`nobs'", "`m'", "`cv'", "`coint'")

    di
    di as text "{hline 60}"
    di as result "  Engle-Granger cointegration test"
    di as text "  depvar = `depvar' | X = `indepvars' | case = `case'"
    di as text "{hline 60}"
    di as text "  EG ADF stat  : " as result %10.4f scalar(`stat')
    di as text "  Lags         : " as result %10.0f scalar(`lags')
    di as text "  N obs        : " as result %10.0f scalar(`nobs')
    di as text "  Critical 1%  : " as result %10.4f el(`cv',1,1)
    di as text "  Critical 5%  : " as result %10.4f el(`cv',1,2)
    di as text "  Critical 10% : " as result %10.4f el(`cv',1,3)
    di as text "{hline 60}"

    return scalar stat = scalar(`stat')
    return scalar lags = scalar(`lags')
    return scalar nobs = scalar(`nobs')
    return matrix cv = `cv'
    return matrix coint_vec = `coint'
    return local cmd "tc_eg"
end
