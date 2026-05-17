*! tarur_pascalau.ado — Pascalau (2007) Asymmetric NLSTAR Unit-Root Test
*! Δyₜ = β₁ y⁴ₜ₋₁ + β₂ y³ₜ₋₁ + β₃ y²ₜ₋₁ + Σ ρᵢ Δyₜ₋ᵢ + uₜ
*! F joint test of β₁ = β₂ = β₃ = 0  — right-tail rejection.

program define tarur_pascalau, rclass
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

    mata: _tarur_run_pascalau("`tv'", "`case'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return local  case     "`case'"
    return local  test     "Pascalau (2007) Asymmetric NLSTAR"
end
