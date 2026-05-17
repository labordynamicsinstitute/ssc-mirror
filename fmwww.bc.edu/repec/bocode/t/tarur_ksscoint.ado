*! tarur_ksscoint.ado — KSS (2006) Nonlinear Cointegration Test
*! Step 1: OLS regression  yₜ = α + β xₜ + uₜ  → residuals û.
*! Step 2: Apply KSS unit-root test to û.
*! Reject H0 (no cointegration) ⇔ KSS rejects unit root in residuals.

program define tarur_ksscoint, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric ts) [if] [in], [ ///
        Case(string)         ///
        MAXLags(integer 8)   ///
        LAGMethod(string)    ///
        QUIETly ]

    quietly tarur_init
    if "`case'"      == "" local case      "demeaned"
    if "`lagmethod'" == "" local lagmethod "aic"

    tokenize "`varlist'"
    local y "`1'"
    local x "`2'"

    marksample touse
    tempvar yv xv
    quietly gen double `yv' = `y' if `touse'
    quietly gen double `xv' = `x' if `touse'

    mata: _tarur_run_ksscoint("`yv'", "`xv'", "`case'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return local  case     "`case'"
    return local  test     "KSS (2006) Nonlinear Cointegration"
end
