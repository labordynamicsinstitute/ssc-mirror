*! tc_es.ado -- Enders-Siklos TAR/MTAR threshold cointegration test
program define tc_es, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, MODEL(string) THReshold(real 0) MAXLag(integer 8) CRITerion(string) CASE(string)]
    if "`model'" == "" local model "mtar"
    if "`case'" == "" local case "c"
    if "`criterion'" == "" local criterion "aic"
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    tempname phi rho1 rho2 t1 t2 fasy thr lags n1 n2 cv
    mata: tc_run_es("`depvar'", "`indepvars'", "`touse'", "`model'", `threshold', `maxlag', "`criterion'", "`case'", "`phi'", "`rho1'", "`rho2'", "`t1'", "`t2'", "`fasy'", "`thr'", "`lags'", "`n1'", "`n2'", "`cv'")

    di
    di as text "{hline 72}"
    di as result "  Enders & Siklos (2001) " as text upper("`model'") " threshold cointegration"
    di as text "  depvar=`depvar'  X=`indepvars'  case=`case'"
    di as text "{hline 72}"
    di as text "  Phi statistic            : " as result %10.4f scalar(`phi')
    di as text "  F-asymmetry              : " as result %10.4f scalar(`fasy')
    di as text "  rho_1 (above)            : " as result %10.4f scalar(`rho1') "   t = " %8.3f scalar(`t1')
    di as text "  rho_2 (below)            : " as result %10.4f scalar(`rho2') "   t = " %8.3f scalar(`t2')
    di as text "  Threshold (tau)          : " as result %10.4f scalar(`thr')
    di as text "  Lags selected            : " as result %10.0f scalar(`lags')
    di as text "  Regime obs (above/below) : " as result %8.0f scalar(`n1') " / " %8.0f scalar(`n2')
    di as text "  Critical (1% / 5% / 10%) : " as result %8.3f el(`cv',1,1) " " %8.3f el(`cv',1,2) " " %8.3f el(`cv',1,3)
    di as text "{hline 72}"

    return scalar phi_stat = scalar(`phi')
    return scalar rho1 = scalar(`rho1')
    return scalar rho2 = scalar(`rho2')
    return scalar threshold = scalar(`thr')
    return scalar lags = scalar(`lags')
    return matrix cv = `cv'
    return local cmd "tc_es"
end
