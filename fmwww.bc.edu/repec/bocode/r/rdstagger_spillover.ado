*! rdstagger_spillover v1.0.1 Subir Hait 2026
*! Decompose staggered RD ATT(g,t) into direct and spillover effects
*! Stata 14 compatible — uses el() for all matrix element access

program define rdstagger_spillover, eclass
    version 14
    syntax [, alpha(real 0.05)]

    if "`e(cmd)'" != "rdstagger" {
        di as error "Must run rdstagger before rdstagger_spillover"
        exit 198
    }

    * ---- Retrieve settings from previous rdstagger run ----
    local yvar   = e(yvar)
    local xvar   = e(xvar)
    local gvar   = e(gvar)
    local tvar   = e(tvar)
    local kernel = e(kernel)
    local bw     = e(bandwidth)
    local bw2    = 2 * `bw'

    * Copy e(attgt) to a local matrix using el()-safe tempname
    tempname ATTGT
    matrix `ATTGT' = e(attgt)
    local R = rowsof(`ATTGT')

    * ---- Get cohorts and periods ----
    qui levelsof `gvar' if `gvar' < ., local(cohorts)
    qui levelsof `tvar',               local(periods)

    * ---- Result matrix:
    *   col 1: cohort   col 2: period    col 3: total_att
    *   col 4: spill    col 5: direct    col 6: spill_se
    *   col 7: spill_p  col 8: direct_se col 9: direct_p  ----
    tempname SPILL
    matrix `SPILL' = J(`R', 9, .)

    local cv = invnormal(1 - `alpha'/2)

    * ---- Fill result matrix row by row ----
    * Rows in SPILL match rows in ATTGT exactly (same cohort-period order)
    forvalues row = 1/`R' {

        local gc  = el(`ATTGT', `row', 1)
        local tp  = el(`ATTGT', `row', 2)
        local total_att = el(`ATTGT', `row', 3)
        local att_se    = el(`ATTGT', `row', 4)
        local prepost   = el(`ATTGT', `row', 10)

        * Store identifiers in SPILL
        matrix `SPILL'[`row', 1] = `gc'
        matrix `SPILL'[`row', 2] = `tp'
        matrix `SPILL'[`row', 3] = `total_att'

        * Skip missing or pre-treatment cells
        if `total_att' >= . {
            continue
        }

        local base_t = `gc' - 1

        * ---- Spillover identification --------------------------------
        * Near controls:  never-treated with x in [-bw, 0)
        * Far controls:   never-treated with x in [-2*bw, -bw)
        *
        * Spillover(g,t) = [E(Y|near,t) - E(Y|near,base)]
        *                - [E(Y|far, t) - E(Y|far, base)]
        *
        * Direct(g,t) = Total ATT(g,t) + Spillover(g,t)
        *   (bias-correction: near controls are contaminated upward)
        * ---------------------------------------------------------------

        qui count if `gvar' >= . & `xvar' >= -`bw'  & `xvar' < 0 & `tvar' == `tp'
        local n_near = r(N)
        qui count if `gvar' >= . & `xvar' >= -`bw2' & `xvar' < -`bw' & `tvar' == `tp'
        local n_far  = r(N)

        if `n_near' < 5 | `n_far' < 5 {
            continue
        }

        * Near controls: treatment and base periods
        qui sum `yvar' if `gvar' >= . & `xvar' >= -`bw'  & `xvar' < 0 & `tvar' == `tp'
        local y_near_t = r(mean)
        qui sum `yvar' if `gvar' >= . & `xvar' >= -`bw'  & `xvar' < 0 & `tvar' == `base_t'
        local y_near_b = r(mean)

        * Far controls: treatment and base periods
        qui sum `yvar' if `gvar' >= . & `xvar' >= -`bw2' & `xvar' < -`bw' & `tvar' == `tp'
        local y_far_t  = r(mean)
        qui sum `yvar' if `gvar' >= . & `xvar' >= -`bw2' & `xvar' < -`bw' & `tvar' == `base_t'
        local y_far_b  = r(mean)

        * Spillover DiD
        local spill_att = (`y_near_t' - `y_near_b') - (`y_far_t' - `y_far_b')

        * Bias-corrected direct effect
        local direct_att = `total_att' + `spill_att'

        * SE for spillover (pooled SD across near+far zone)
        qui sum `yvar' if `gvar' >= . & ///
            ((`xvar' >= -`bw' & `xvar' < 0) | ///
             (`xvar' >= -`bw2' & `xvar' < -`bw')) & ///
            (`tvar' == `tp' | `tvar' == `base_t')
        local pooled_sd = r(sd)
        local n_eff     = `n_near' + `n_far'
        local spill_se  = `pooled_sd' / sqrt(`n_eff')
        if `spill_se' == . | `spill_se' == 0 local spill_se = 0.0001

        local spill_p   = 2 * normal(-abs(`spill_att' / `spill_se'))

        * SE for direct: propagate both uncertainty sources
        if `att_se' >= . local att_se = 0.0001
        local direct_se = sqrt(`spill_se'^2 + `att_se'^2)
        if `direct_se' == . | `direct_se' == 0 local direct_se = 0.0001
        local direct_p  = 2 * normal(-abs(`direct_att' / `direct_se'))

        matrix `SPILL'[`row', 4] = `spill_att'
        matrix `SPILL'[`row', 5] = `direct_att'
        matrix `SPILL'[`row', 6] = `spill_se'
        matrix `SPILL'[`row', 7] = `spill_p'
        matrix `SPILL'[`row', 8] = `direct_se'
        matrix `SPILL'[`row', 9] = `direct_p'
    }

    * ---- Post results first, then display using el() ----
    ereturn clear
    ereturn matrix spillover = `SPILL'
    ereturn scalar bandwidth  = `bw'
    ereturn local  cmd "rdstagger_spillover"
    ereturn local  yvar "`yvar'"
    ereturn local  xvar "`xvar'"

    * Copy e(spillover) back to display tempname
    * (avoids e(mat)[r,c] indexing which is not Stata 14 safe)
    tempname DS AT
    matrix `DS' = e(spillover)
    matrix `AT' = `ATTGT'

    di _newline as txt "rdstagger Spillover Decomposition"
    di as txt "Bandwidth: " %6.4f `bw' "   Near controls: x in [-bw,0)"  ///
              "   Far controls: x in [-2bw,-bw)"
    di as txt "{hline 78}"
    di as txt %8s "Cohort" %8s "Period" %11s "Total ATT" ///
              %13s "Spillover" %12s "Direct" %9s "Spill p"
    di as txt "{hline 78}"

    forvalues r = 1/`R' {
        if el(`DS', `r', 3) < . {
            local pp = cond(el(`AT',`r',10)==1, "[post]", "[pre ]")
            if el(`DS', `r', 4) < . {
                di as res %8.0f  el(`DS',`r',1) %8.0f  el(`DS',`r',2) ///
                          %11.4f el(`DS',`r',3)                         ///
                          %13.4f el(`DS',`r',4) %12.4f el(`DS',`r',5)  ///
                          %9.4f  el(`DS',`r',7) "  `pp'"
            }
            else {
                di as res %8.0f  el(`DS',`r',1) %8.0f  el(`DS',`r',2) ///
                          %11.4f el(`DS',`r',3)                         ///
                          %13s "n/a" %12s "n/a" %9s "n/a" "  `pp'"
            }
        }
    }

    di as txt "{hline 78}"
    di as txt "Spillover = DiD(near controls vs far controls)"
    di as txt "Direct    = Total ATT + Spillover (bias-corrected)"

end
