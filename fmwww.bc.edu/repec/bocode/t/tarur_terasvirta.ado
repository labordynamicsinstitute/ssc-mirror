*! tarur_terasvirta.ado — Teräsvirta (1994) Linearity Test
*! Augmented regression: AR(p) plus three powers of yₜ₋d times AR regressors.
*! F-test of joint nullity of the auxiliary regressors; sequential H01-H03 to
*! suggest LSTAR vs ESTAR.

program define tarur_terasvirta, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        D(integer 1)         ///
        MAXP(integer 4)      ///
        QUIETly ]

    quietly tarur_init

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_terasvirta("`tv'", `d', `maxp', "`quietly'")

    return scalar F      = r(F)
    return scalar pvalue = r(pvalue)
    return scalar pH01   = r(pH01)
    return scalar pH02   = r(pH02)
    return scalar pH03   = r(pH03)
    return local  model  "`r(model)'"
    return scalar p      = r(p)
    return local  test   "Terasvirta (1994) Linearity Test"
end
