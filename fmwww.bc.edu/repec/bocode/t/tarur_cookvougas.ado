*! tarur_cookvougas.ado — Cook & Vougas (2009) ST-MTAR Unit-Root Test
*! NLS smooth-transition detrend then momentum-TAR regression:
*!   Iₜ = 1 if Δresₜ₋₁ ≥ 0
*!   Δresₜ = ρ⁺ I·resₜ₋₁ + ρ⁻ (1-I)·resₜ₋₁ + Σ φᵢ Δresₜ₋ᵢ + uₜ
*! Statistic: F (ρ⁺=ρ⁻=0)  — right-tail rejection.

program define tarur_cookvougas, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        MODel(string)        ///
        MAXLags(integer 8)   ///
        QUIETly ]

    quietly tarur_init
    if "`model'" == "" local model "A"
    local model = upper("`model'")
    if !inlist("`model'", "A","B","C","D") {
        di as error "Cook-Vougas model must be A, B, C, or D."
        exit 198
    }

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    mata: _tarur_run_cookv("`tv'", "`model'", `maxlags', "`quietly'")

    return scalar stat = r(stat)
    return scalar cv1  = r(cv1)
    return scalar cv5  = r(cv5)
    return scalar cv10 = r(cv10)
    return scalar reject1  = r(reject1)
    return scalar reject5  = r(reject5)
    return scalar reject10 = r(reject10)
    return scalar lag      = r(lag)
    return local  model    "`model'"
    return local  test     "Cook & Vougas (2009) Model `model'"
end
