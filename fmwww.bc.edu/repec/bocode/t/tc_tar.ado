*! tc_tar.ado -- TAR / MTAR model fit
program define tc_tar, rclass
    version 14
    syntax varname(numeric) [if] [in] [, MODEL(string) THReshold(real 0) MAXLag(integer 4) CRITerion(string)]
    if "`model'" == "" local model "tar"
    if "`criterion'" == "" local criterion "aic"
    marksample touse
    _tc_load

    tempname phi rho1 rho2 t1 t2 fasy thr lags n1 n2
    mata: tc_run_tar("`varlist'", "`touse'", `threshold', `maxlag', "`criterion'", "`model'", "`phi'", "`rho1'", "`rho2'", "`t1'", "`t2'", "`fasy'", "`thr'", "`lags'", "`n1'", "`n2'")

    di
    di as text "{hline 72}"
    di as result "  " as text upper("`model'") " model fit on `varlist'"
    di as text "{hline 72}"
    di as text "  Phi statistic            : " as result %10.4f scalar(`phi')
    di as text "  F-asymmetry              : " as result %10.4f scalar(`fasy')
    di as text "  rho_1 / rho_2            : " as result %10.4f scalar(`rho1') " / " %10.4f scalar(`rho2')
    di as text "  Threshold                : " as result %10.4f scalar(`thr')
    di as text "  Lags                     : " as result %10.0f scalar(`lags')
    di as text "{hline 72}"

    return scalar phi_stat = scalar(`phi')
    return scalar threshold = scalar(`thr')
    return local cmd "tc_tar"
end
