*! tc_supf.ado -- Schweikert (2019) supF*
program define tc_supf, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in] [, MODEL(string) BReaktype(integer 1) MAXLag(integer 4) THReshold(real 0) U(real -99) TRIM(real 0.15) CRITerion(string)]
    if "`model'" == "" local model "tar"
    if "`criterion'" == "" local criterion "aic"
    gettoken depvar indepvars : varlist
    marksample touse
    _tc_load

    local uval = `u'
    if `u' == -99 local uval .

    tempname fstar fasy rho1 rho2 lags bp cv
    scalar `bp' = .
    mata: tc_run_supf("`depvar'", "`indepvars'", "`touse'", "`model'", `breaktype', `maxlag', `threshold', `uval', `trim', "`criterion'", "`fstar'", "`fasy'", "`rho1'", "`rho2'", "`lags'", "`bp'", "`cv'")

    local bk_name : word `breaktype' of "none" "C0_intercept" "CT_trend" "CS_slope"

    di
    di as text "{hline 72}"
    di as result "  supF* with structural break (Schweikert 2019)"
    di as text "  model = `model' | breaktype = `bk_name'"
    di as text "{hline 72}"
    di as text "  supF* statistic          : " as result %10.4f scalar(`fstar')
    di as text "  F-asymmetry              : " as result %10.4f scalar(`fasy')
    di as text "  rho_1 / rho_2            : " as result %10.4f scalar(`rho1') " / " %10.4f scalar(`rho2')
    if `breaktype' > 1 di as text "  Break point              : " as result %10.0f scalar(`bp')
    di as text "  Critical (1% / 5% / 10%) : " as result %8.3f el(`cv',1,1) " " %8.3f el(`cv',1,2) " " %8.3f el(`cv',1,3)
    di as text "{hline 72}"

    return scalar f_star = scalar(`fstar')
    return matrix cv = `cv'
    return local cmd "tc_supf"
end
