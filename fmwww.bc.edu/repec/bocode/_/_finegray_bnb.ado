*! _finegray_bnb Version 1.3.2  2026/09/08
*! Non-base coefficient vector (and variance) of the finegray fit in e()
*! Author: Timothy P Copeland, Karolinska Institutet
*! Program class: internal (nclass)

/*
  _finegray_bnb, b(tempname) [v(tempname)]

Copies e(b) -- and e(V) when v() is given -- into the caller's tempnames with
every base-level column (`0b.pelnode', `1b.grp#c.x') removed, so that what
comes back is one coefficient per column of e(designvars), in that order.

WHY THIS EXISTS.  finegray posts the full fit-time expansion as its stripe on
a factor-variable fit, base terms included with a zero coefficient and a zero
row/column of e(V), because that is the stripe margins, contrast and pwcompare
enumerate a factor's levels from.  The estimate itself is in the DESIGN frame:
the CIF, the linear predictor, the Schoenfeld residuals and the bootstrap
refits all pair coefficient k with design column k.  This is the one place
that translation happens on the Stata side (the Mata side is
_finegray_beta() in _finegray_mata.ado, same rule), so a consumer cannot
index into e(b) positionally and land on a base column.

The rule is the stripe, not a stored index: margins builds its delta-method
Jacobian by reposting a perturbed e(b) and calling predict, so a consumer must
read whatever e(b) holds NOW.  `Nb.' is the base marker; `Nbn.' (from ibn.)
is kept because it carries a real coefficient -- the same filter finegray.ado
applies when it decides which fit-time terms enter the design.

A tvc() fit is posted narrow (one equation per interval, no base columns), so
here the copy is the identity and the equation stripe is preserved; a
non-factor fit is the identity too.
*/

capture program drop _finegray_bnb
program define _finegray_bnb
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off
    capture noisily {
        syntax , B(name) [V(name)]

        capture confirm matrix e(b)
        if _rc {
            display as error "e(b) not found"
            exit 301
        }
        local _cn : colnames e(b)
        local _ce : coleq e(b)
        local _k : word count `_cn'
        local _keep ""
        local _kn ""
        local _ke ""
        local _nb = 0
        forvalues _i = 1/`_k' {
            local _n : word `_i' of `_cn'
            if regexm("`_n'", "[0-9]+b\.") continue
            local ++_nb
            local _keep "`_keep' `_i'"
            local _kn "`_kn' `_n'"
            local _ke "`_ke' `: word `_i' of `_ce''"
        }
        if `_nb' == 0 {
            display as error "e(b) holds no non-base coefficient"
            exit 498
        }
        if `_nb' == `_k' {
            matrix `b' = e(b)
            if "`v'" != "" matrix `v' = e(V)
        }
        else {
            tempname _S
            matrix `_S' = J(`_k', `_nb', 0)
            local _j = 0
            foreach _i of local _keep {
                local ++_j
                matrix `_S'[`_i', `_j'] = 1
            }
            matrix `b' = e(b) * `_S'
            matrix colnames `b' = `_kn'
            if "`v'" != "" {
                matrix `v' = `_S'' * e(V) * `_S'
                matrix colnames `v' = `_kn'
                matrix rownames `v' = `_kn'
            }
            * Equation names survive only when the fit had any; a widened
            * stripe never does (tvc() fits are posted narrow), but keep the
            * copy faithful rather than assume it.
            local _ke : list retokenize _ke
            local _ke_u : list uniq _ke
            if "`_ke_u'" != "_" & "`_ke_u'" != "" {
                matrix coleq `b' = `_ke'
                if "`v'" != "" {
                    matrix coleq `v' = `_ke'
                    matrix roweq `v' = `_ke'
                }
            }
        }
    }
    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end
