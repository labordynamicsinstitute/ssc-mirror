*! tarur_kss.ado — Kapetanios, Shin & Snell (2003) nonlinear unit-root test
*! Auxiliary regression: Δyₜ = β₁ y³ₜ₋₁ + Σ ρᵢ Δyₜ₋ᵢ + uₜ
*! Statistic: tNL = t(β̂₁)   — left-tail rejection.
*!
*! Syntax:
*!   tarur_kss varname [if] [in], [case(string) maxlags(int) lagmethod(string)]
*!
*! Options:
*!   case(raw|demeaned|detrended)   default = demeaned
*!   maxlags(integer)               default = 8
*!   lagmethod(aic|bic|tstat)       default = aic

program define tarur_kss, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        Case(string)         ///
        MAXLags(integer 8)   ///
        LAGMethod(string)    ///
        QUIETly ]

    quietly tarur_init
    if "`case'"      == "" local case      "demeaned"
    if "`lagmethod'" == "" local lagmethod "aic"

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_kss("`tv'", "`case'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return local  case     "`case'"
    return local  test     "KSS (2003) Nonlinear Unit Root Test"
end
