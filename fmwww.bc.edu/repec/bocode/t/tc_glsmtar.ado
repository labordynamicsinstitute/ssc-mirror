*! tc_glsmtar.ado -- Cook (2007) GLS-MTAR
program define tc_glsmtar, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, THReshold(real 0) MAXLag(integer 8) CASE(string) CRITerion(string) CBAR(real -99)]
    if "`case'" == "" local case "c"
    if "`criterion'" == "" local criterion "aic"
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    local cb = `cbar'
    if `cbar' == -99 local cb .

    tempname phi rho1 rho2 t1 t2 thr lags n1 n2 cv
    mata: tc_run_glsmtar("`depvar'", "`indepvars'", "`touse'", `threshold', `maxlag', "`case'", "`criterion'", `cb', "`phi'", "`rho1'", "`rho2'", "`t1'", "`t2'", "`thr'", "`lags'", "`n1'", "`n2'", "`cv'")

    di
    di as text "{hline 72}"
    di as result "  Cook (2007) GLS-MTAR threshold cointegration test"
    di as text "{hline 72}"
    di as text "  Phi*_GLS statistic       : " as result %10.4f scalar(`phi')
    di as text "  rho_1 / rho_2            : " as result %10.4f scalar(`rho1') " / " %10.4f scalar(`rho2')
    di as text "  Threshold                : " as result %10.4f scalar(`thr')
    di as text "  Lags                     : " as result %10.0f scalar(`lags')
    di as text "  Critical (1% / 5% / 10%) : " as result %8.3f el(`cv',1,1) " " %8.3f el(`cv',1,2) " " %8.3f el(`cv',1,3)
    di as text "{hline 72}"

    return scalar phi_gls_stat = scalar(`phi')
    return matrix cv = `cv'
    return local cmd "tc_glsmtar"
end
