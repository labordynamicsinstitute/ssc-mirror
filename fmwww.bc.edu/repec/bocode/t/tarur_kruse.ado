*! tarur_kruse.ado — Kruse (2011) modified Wald ESTAR unit-root test
*! Δyₜ = β₁ y³ₜ₋₁ + β₂ y²ₜ₋₁ + Σ ρᵢ Δyₜ₋ᵢ + uₜ
*! τ = t²(β₂⊥=0) + 𝟙(β̂₁<0)·t²(β₁=0)   — right-tail rejection.
*!
*! Bug fix vs R NonlinearTSA: the orthogonalized β₂⊥ and indicator function
*! are correctly applied per Kruse (2011, eq. 5).

program define tarur_kruse, rclass
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

    mata: _tarur_run_kruse("`tv'", "`case'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return scalar beta1    = r(beta1)
    return scalar beta2    = r(beta2)
    return local  case     "`case'"
    return local  test     "Kruse (2011) Modified Wald Test"
end
