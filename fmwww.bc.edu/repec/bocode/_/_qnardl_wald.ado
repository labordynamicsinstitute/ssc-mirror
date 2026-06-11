*! _qnardl_wald v0.3.0  27may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Wald tests for QNARDL.
*!
*! Test types (option type()):
*!   lrsym       Long-run sign symmetry per tau:
*!               H0:  phi+_j(tau) = phi-_j(tau)  for each asymmetric regressor j
*!               (equivalently, beta+_j(tau) = beta-_j(tau))
*!               Asymptotically chi^2(1) per j (Cho et al. 2020a).
*!
*!   srsym       Short-run additive symmetry per tau:
*!               H0:  sum_i a+_ij(tau) = sum_i a-_ij(tau)  for each j
*!               Tests via Stata's -test- command after qreg.
*!
*!   interquart  Interquartile equality across tau (3 quartiles):
*!               H0:  phi_y(0.25) = phi_y(0.50) = phi_y(0.75)
*!               and equivalent joint restrictions on phi+, phi-.
*!               Uses chi^2 approximation under independence — Bertsatos et al.
*!               2022 simulated CVs are STRICTER (TODO in v0.4 via simulate()).
*!
*!   interdec    Interdecile equality across tau (9 deciles).
*!

program define _qnardl_wald, rclass
    version 14.0

    syntax , TYPE(string) [ depvar(varname) pos_vars(varlist) neg_vars(varlist) ///
             linear_vars(string) exog(string) tau(numlist) ///
             p(integer 1) q(integer 1) r(integer 1) ///
             case(integer 3) trendvar(string) ///
             touse(varname) sim(string) ]

    if !inlist("`type'", "lrsym", "srsym", "interquart", "interdec") {
        di as error "_qnardl_wald: type() must be lrsym, srsym, interquart, or interdec"
        exit 198
    }

    // Note: internal qreg calls below clobber e().  The caller
    // (qnardl.ado) is responsible for restoring its matrices.

    local kasym : word count `pos_vars'
    local klin  : word count `linear_vars'
    local ntau  : word count `tau'

    local has_const = (`case' >= 3)
    local has_trend = inlist(`case', 4, 5, 6, 7, 8, 9, 10, 11)
    local has_quad  = inlist(`case', 8, 9, 10, 11)

    if `has_quad' & "`trendvar'" != "" {
        tempvar t2var
        qui gen double `t2var' = (`trendvar')^2 if `touse'
    }

    // -------- Build URECM regressors and remember which temp = which slot ---
    local urecm "L.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L.`lv'"
        }
    }
    if `p' > 1  local urecm "`urecm' L(1/`=`p'-1').D.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L(0/`=`r'-1').D.`lv'"
        }
    }
    if "`exog'" != ""                     local urecm "`urecm' `exog'"
    if `has_trend' & "`trendvar'" != ""   local urecm "`urecm' `trendvar'"
    if `has_quad'  & "`trendvar'" != ""   local urecm "`urecm' `t2var'"

    local consopt = cond(`has_const', "", "noconstant")
    qui tsrevar `urecm'
    local urecm_temps `r(varlist)'
    qui tsrevar D.`depvar'
    local dydepvar `r(varlist)'

    // Build maps from "logical slot" to tempvar name
    local Ly_temp : word 1 of `urecm_temps'
    // L.x_pos positions are 2..1+kasym
    // L.x_neg positions are 2+kasym..1+2*kasym
    local Lxp_temps ""
    local Lxn_temps ""
    forvalues j = 1/`kasym' {
        local p_idx = 1 + `j'
        local n_idx = 1 + `kasym' + `j'
        local Lxp_temps "`Lxp_temps' `: word `p_idx' of `urecm_temps''"
        local Lxn_temps "`Lxn_temps' `: word `n_idx' of `urecm_temps''"
    }
    // Δ-blocks start after the level block (1 + 2*kasym + klin)
    local lev_total = 1 + 2 * `kasym' + `klin'
    local dyn_start = `lev_total' + 1 + (`p' - 1)        // skip p-1 Δy lags
    // For each asym var j, q lags of Δx+_j then q lags of Δx-_j
    // dyn_start..dyn_start+q-1 = Δx+_1, +q..+2q-1 = Δx-_1, etc.

    di as txt _n "{hline 78}"
    if "`type'" == "lrsym" {
        di as res "[D] LONG-RUN SIGN SYMMETRY  H0:  beta+_j(tau) = beta-_j(tau)"
    }
    else if "`type'" == "srsym" {
        di as res "[D] SHORT-RUN SYMMETRY  H0:  sum a+_ij(tau) = sum a-_ij(tau)"
    }
    else {
        local lab = cond("`type'"=="interquart", ///
            "INTERQUARTILE EQUALITY", "INTERDECILE EQUALITY")
        di as res "[D] " "`lab'"  "  H0: coefficient equal across quantiles"
    }
    di as txt "{hline 78}"

    // -------- LRSYM and SRSYM: per-tau qreg + test --------------------------
    if inlist("`type'", "lrsym", "srsym") {
        di as txt _col(3) %-8s "tau" _c
        forvalues j = 1/`kasym' {
            local vn : word `j' of `pos_vars'
            // strip _qnardl_X_pos prefix → just X
            local vn : subinstr local vn "_qnardl_" ""
            local vn : subinstr local vn "_pos" ""
            di as txt _col(`=10 + 14*`j'') %12s "`vn'" _c
        }
        di as txt _col(`=10 + 14*(`kasym'+1)') %12s "JOINT"
        di as txt _col(3) "{hline `=10 + 14*(`kasym'+1) + 12'}"

        tempname W_mat
        matrix `W_mat' = J(`ntau', `kasym' + 1, .)

        local itau = 0
        foreach t of numlist `tau' {
            local ++itau
            capture noisily qui qreg `dydepvar' `urecm_temps' if `touse', ///
                quantile(`t') `consopt'
            if _rc continue

            di as txt _col(3) %-8s "`t'" _c

            // Build joint restriction expression as we go
            local joint_expr ""

            forvalues j = 1/`kasym' {
                local pv : word `j' of `Lxp_temps'
                local nv : word `j' of `Lxn_temps'

                if "`type'" == "lrsym" {
                    // H0: coef on L.x_pos_j = coef on L.x_neg_j
                    local this_eq "(`pv' = `nv')"
                    capture noisily qui test `pv' = `nv'
                    if !_rc {
                        local Wj = r(F) * r(df)        // chi^2 = F * df
                        local pj = r(p)
                        matrix `W_mat'[`itau', `j'] = `Wj'
                        local star = ""
                        if `pj' < 0.10 local star "*"
                        if `pj' < 0.05 local star "**"
                        if `pj' < 0.01 local star "***"
                        di as res _col(`=10 + 14*`j'') %8.3f `Wj' as txt " `star'" _c
                    }
                    else {
                        di as txt _col(`=10 + 14*`j'') %12s "fail" _c
                    }
                }
                else {  // srsym
                    // H0: sum_{i=0..q-1} a+_ij = sum_{i=0..q-1} a-_ij
                    // Build the test expression — first term has no leading "+"
                    local pv_offset = `dyn_start' + 2 * (`j' - 1) * `q'
                    local nv_offset = `pv_offset' + `q'
                    local pos_sum ""
                    local neg_sum ""
                    forvalues k = 1/`q' {
                        local pv_t : word `=`pv_offset' + `k' - 1' of `urecm_temps'
                        local nv_t : word `=`nv_offset' + `k' - 1' of `urecm_temps'
                        if "`pos_sum'" == "" {
                            local pos_sum "`pv_t'"
                            local neg_sum "`nv_t'"
                        }
                        else {
                            local pos_sum "`pos_sum' + `pv_t'"
                            local neg_sum "`neg_sum' + `nv_t'"
                        }
                    }
                    local this_eq "(`pos_sum' = `neg_sum')"
                    capture noisily qui test (`pos_sum') = (`neg_sum')
                    if !_rc {
                        local Wj = r(F) * r(df)
                        local pj = r(p)
                        matrix `W_mat'[`itau', `j'] = `Wj'
                        local star = ""
                        if `pj' < 0.10 local star "*"
                        if `pj' < 0.05 local star "**"
                        if `pj' < 0.01 local star "***"
                        di as res _col(`=10 + 14*`j'') %8.3f `Wj' as txt " `star'" _c
                    }
                    else {
                        di as txt _col(`=10 + 14*`j'') %12s "fail" _c
                    }
                }

                // Accumulate the per-j restriction for the joint test
                if "`joint_expr'" == "" {
                    local joint_expr "`this_eq'"
                }
                else {
                    local joint_expr "`joint_expr' `this_eq'"
                }
            }

            // Joint test across all asymmetric regressors at this tau
            capture noisily qui test `joint_expr'
            if !_rc {
                local Wjoint = r(F) * r(df)
                local pjoint = r(p)
                matrix `W_mat'[`itau', `kasym' + 1] = `Wjoint'
                local star = ""
                if `pjoint' < 0.10 local star "*"
                if `pjoint' < 0.05 local star "**"
                if `pjoint' < 0.01 local star "***"
                di as res _col(`=10 + 14*(`kasym'+1)') %8.3f `Wjoint' as txt " `star'" _c
            }
            di ""
        }
        di as txt _col(3) "{hline `=10 + 14*(`kasym'+1) + 12'}"
        di as txt _col(3) "Per-variable stat = chi^2(1).  JOINT stat = chi^2(`kasym')."
        di as txt _col(3) "* p<.10, ** p<.05, *** p<.01"

        matrix rownames `W_mat' = `tau'
        local cnms ""
        foreach pv of varlist `pos_vars' {
            local vn : subinstr local pv "_qnardl_" "", all
            local vn : subinstr local vn "_pos" "", all
            local cnms "`cnms' `vn'"
        }
        local cnms "`cnms' JOINT"
        matrix colnames `W_mat' = `cnms'
        return matrix W = `W_mat'
    }

    // -------- INTERPERCENTILE / INTERDECILE ---------------------------------
    if inlist("`type'", "interquart", "interdec") {
        if "`type'" == "interquart" local tau_use 0.25 0.50 0.75
        else                        local tau_use 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90
        local nq : word count `tau_use'

        // For each level-block coefficient, collect (b_q, se_q) across all q's
        // and compute chi^2 = sum( (b_q - bbar)^2 / se_q^2 ), df = nq-1
        // (independence approximation; bootstrap-based CVs are TODO).
        tempname b_all se_all
        matrix `b_all'  = J(`nq', `lev_total', .)
        matrix `se_all' = J(`nq', `lev_total', .)

        local iq = 0
        foreach t of numlist `tau_use' {
            local ++iq
            capture noisily qui qreg `dydepvar' `urecm_temps' if `touse', ///
                quantile(`t') `consopt'
            if _rc continue
            forvalues j = 1/`lev_total' {
                local tv : word `j' of `urecm_temps'
                matrix `b_all'[`iq',  `j'] = _b[`tv']
                matrix `se_all'[`iq', `j'] = _se[`tv']
            }
        }

        di as txt _col(3) "Quantiles tested: `tau_use'"
        di as txt _col(3) %-22s "Coefficient" _col(28) %12s "Wald chi^2" ///
                  _col(43) %6s "df" _col(53) %10s "p-value"
        di as txt _col(3) "{hline 70}"

        local labels "L.y"
        forvalues j = 1/`kasym' {
            local vn : word `j' of `pos_vars'
            local vn : subinstr local vn "_qnardl_" "", all
            local labels "`labels' `vn'"
        }
        forvalues j = 1/`kasym' {
            local vn : word `j' of `neg_vars'
            local vn : subinstr local vn "_qnardl_" "", all
            local labels "`labels' `vn'"
        }
        if `klin' > 0 {
            foreach lv of varlist `linear_vars' {
                local labels "`labels' L.`lv'"
            }
        }

        tempname interp_mat
        matrix `interp_mat' = J(`lev_total', 3, .)

        forvalues j = 1/`lev_total' {
            // Inverse-variance weighted mean
            local sum_w 0
            local sum_wb 0
            forvalues iq = 1/`nq' {
                local s = `se_all'[`iq', `j']
                local b = `b_all'[`iq', `j']
                if !missing(`s') & `s' > 0 & !missing(`b') {
                    local w = 1 / (`s')^2
                    local sum_w  = `sum_w'  + `w'
                    local sum_wb = `sum_wb' + `w' * `b'
                }
            }
            if `sum_w' > 0 {
                local bbar = `sum_wb' / `sum_w'
                // Wald = sum ((b - bbar)^2 / se^2)
                local W = 0
                forvalues iq = 1/`nq' {
                    local s = `se_all'[`iq', `j']
                    local b = `b_all'[`iq', `j']
                    if !missing(`s') & `s' > 0 & !missing(`b') {
                        local W = `W' + ((`b' - `bbar') / `s')^2
                    }
                }
                local df = `nq' - 1
                local pv = chi2tail(`df', `W')
                matrix `interp_mat'[`j', 1] = `W'
                matrix `interp_mat'[`j', 2] = `df'
                matrix `interp_mat'[`j', 3] = `pv'
                local star = ""
                if `pv' < 0.10 local star "*"
                if `pv' < 0.05 local star "**"
                if `pv' < 0.01 local star "***"
                local lab : word `j' of `labels'
                di as txt _col(3) %-22s "`lab'" ///
                          as res _col(28) %12.4f `W' as txt " `star'" ///
                          as res _col(43) %6.0f `df' ///
                          as res _col(53) %10.4f `pv'
            }
        }
        di as txt _col(3) "{hline 70}"
        di as txt _col(3) "Note: chi^2 under INDEPENDENCE across quantiles."
        di as txt _col(3) "      For exact Bertsatos et al. 2022 critical values, use"
        di as txt _col(3) "      simulate() option (TODO v0.4)."

        matrix rownames `interp_mat' = `labels'
        matrix colnames `interp_mat' = W df p
        return matrix W = `interp_mat'
    }
end
