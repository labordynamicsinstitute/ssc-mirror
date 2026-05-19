*! tc_adf.ado -- Augmented Dickey-Fuller unit-root test (minimal)
program define tc_adf, rclass
    version 14
    syntax varname(numeric) [if] [in] [, MAXLag(integer 0) CASE(string) CRITerion(string)]

    if "`case'" == "" local case "c"
    if "`criterion'" == "" local criterion "aic"
    marksample touse
    _tc_load

    local mlg = `maxlag'
    if `maxlag' == 0 local mlg .

    tempname stat lags nobs cv
    mata: tc_run_adf("`varlist'", "`touse'", `mlg', "`case'", "`criterion'", "`stat'", "`lags'", "`nobs'", "`cv'")

    di
    di as text "{hline 60}"
    di as result "  Augmented Dickey-Fuller test on `varlist'"
    di as text "  case = `case' | criterion = `criterion'"
    di as text "{hline 60}"
    di as text "  Statistic    : " as result %10.4f scalar(`stat')
    di as text "  Lags         : " as result %10.0f scalar(`lags')
    di as text "  N obs        : " as result %10.0f scalar(`nobs')
    di as text "  Critical 1%  : " as result %10.4f el(`cv',1,1)
    di as text "  Critical 5%  : " as result %10.4f el(`cv',1,2)
    di as text "  Critical 10% : " as result %10.4f el(`cv',1,3)
    di as text "{hline 60}"
    di

    return scalar stat = scalar(`stat')
    return scalar lags = scalar(`lags')
    return scalar nobs = scalar(`nobs')
    return matrix cv = `cv'
    return local cmd "tc_adf"
end
