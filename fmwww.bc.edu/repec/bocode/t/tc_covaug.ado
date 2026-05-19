*! tc_covaug.ado -- Covariates-augmented (Oh-Lee-Meng 2017)
program define tc_covaug, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, MODEL(string) THReshold(real 0) MAXLag(integer 8) CRITerion(string)]
    if "`model'" == "" local model "mtar"
    if "`criterion'" == "" local criterion "aic"
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    tempname phi rho1 rho2 t1 t2 thr n1 n2 cv
    mata: tc_run_covaug("`depvar'", "`indepvars'", "`touse'", "`model'", `threshold', `maxlag', "`criterion'", "`phi'", "`rho1'", "`rho2'", "`t1'", "`t2'", "`thr'", "`n1'", "`n2'", "`cv'")

    di
    di as text "{hline 72}"
    di as result "  Covariates-Augmented (Oh, Lee & Meng 2017) -- " as text upper("`model'")
    di as text "{hline 72}"
    di as text "  Phi statistic            : " as result %10.4f scalar(`phi')
    di as text "  rho_1 / rho_2            : " as result %10.4f scalar(`rho1') " / " %10.4f scalar(`rho2')
    di as text "  Threshold                : " as result %10.4f scalar(`thr')
    di as text "  Critical (1% / 5% / 10%) : " as result %8.3f el(`cv',1,1) " " %8.3f el(`cv',1,2) " " %8.3f el(`cv',1,3)
    di as text "{hline 72}"

    return scalar phi_stat = scalar(`phi')
    return matrix cv = `cv'
    return local cmd "tc_covaug"
end
