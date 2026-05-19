*! tc_exes.ado -- Extended E-S (Osinska & Galecki 2022)
program define tc_exes, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, MODEL(string) MAXLag(integer 8) TRIM(real 0.15) CRITerion(string) THReshvar(varname numeric)]
    if "`model'" == "" local model "mtar"
    if "`criterion'" == "" local criterion "aic"
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    tempname phi rho1 rho2 t1 t2 fasy thr lags n1 n2
    mata: tc_run_exes("`depvar'", "`indepvars'", "`touse'", "`model'", `maxlag', "`criterion'", `trim', "`threshvar'", "`phi'", "`rho1'", "`rho2'", "`t1'", "`t2'", "`fasy'", "`thr'", "`lags'", "`n1'", "`n2'")

    di
    di as text "{hline 72}"
    di as result "  Extended Enders-Siklos (Osinska & Galecki 2022)"
    di as text "{hline 72}"
    di as text "  sup-Phi statistic        : " as result %10.4f scalar(`phi')
    di as text "  F-asymmetry              : " as result %10.4f scalar(`fasy')
    di as text "  Threshold                : " as result %10.4f scalar(`thr')
    di as text "  rho_1 / rho_2            : " as result %10.4f scalar(`rho1') " / " %10.4f scalar(`rho2')
    di as text "{hline 72}"

    return scalar sup_phi = scalar(`phi')
    return scalar threshold = scalar(`thr')
    return local cmd "tc_exes"
end
