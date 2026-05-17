*! tarur_endersgranger.ado — Enders & Granger (1998) MTAR Unit-Root Test
*! Δyₜ = ρ⁺ Iₜ yₜ₋₁ + ρ⁻ (1-Iₜ) yₜ₋₁ + (deterministics) + Σ φᵢ Δyₜ₋ᵢ + uₜ
*! Iₜ = 1 if Δyₜ₋₁ ≥ 0  (momentum indicator)
*! Statistic: Φ (F-type joint test of ρ⁺ = ρ⁻ = 0) — right-tail rejection.

program define tarur_endersgranger, rclass
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

    mata: _tarur_run_eg("`tv'", "`case'", `maxlags', "`lagmethod'", "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return scalar rho_pos  = r(rho_pos)
    return scalar rho_neg  = r(rho_neg)
    return scalar F_sym    = r(F_sym)
    return scalar F_sym_p  = r(F_sym_p)
    return local  case     "`case'"
    return local  test     "Enders & Granger (1998) MTAR"
end
