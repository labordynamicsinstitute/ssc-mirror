*! _qnardl_onestep v0.2.0  27may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Single-step QNARDL: direct quantile regression on the unrestricted
*! error-correction model (Bertsatos, Sakellaris & Tsionas 2022 eq. 13).
*!
*! Estimating equation for each tau in tau():
*!   Δy_t = c(τ) + γ1(τ)·t + γ2(τ)·t^2
*!        + φ_y(τ)·y_{t-1}
*!        + Σ_j [ φ+_j(τ)·x+_j_{t-1} + φ-_j(τ)·x-_j_{t-1} ]
*!        + δ(τ)' · lin_{t-1}
*!        + ψ(τ)' · exog_t
*!        + Σ_{i=1..p-1} λ_i(τ)·Δy_{t-i}
*!        + Σ_j Σ_{i=0..q-1} [ a+_ij(τ)·Δx+_j_{t-i} + a-_ij(τ)·Δx-_j_{t-i} ]
*!        + Σ_j Σ_{i=0..r-1} ω_ij(τ)·Δlin_j_{t-i}
*!        + ε_t(τ)
*!
*! Long-run multipliers recoverable as:
*!   β+_j(τ) = -φ+_j(τ) / φ_y(τ),   β-_j(τ) = -φ-_j(τ) / φ_y(τ)
*!
*! Bounds testing then uses simulated critical values from Bertsatos et al.
*! 2022 (cases I–XI, k regressors, T observations) — handled by _qnardl_bounds.

program define _qnardl_onestep, eclass
    version 14.0

    syntax , [ depvar(varname) asymmetry(varlist) pos_vars(varlist) neg_vars(varlist) ///
               linear_vars(string) exog(string) tau(numlist) ///
               p(integer 1) q(integer 1) r(integer 1) ///
               case(integer 3) trendvar(string) quad(string) ///
               constant(string) touse(varname) level(cilevel) ]

    local kasym : word count `asymmetry'
    local klin  : word count `linear_vars'
    local kexog : word count `exog'
    local ntau  : word count `tau'

    // ---- Case-dependent deterministic flags --------------------------------
    local has_const = (`case' >= 3)
    local has_trend = inlist(`case', 4, 5, 6, 7, 8, 9, 10, 11)
    local has_quad  = inlist(`case', 8, 9, 10, 11)

    // Build quadratic trend if needed
    local t2var ""
    if `has_quad' & "`trendvar'" != "" {
        tempvar t2tmp
        qui gen double `t2tmp' = (`trendvar')^2 if `touse'
        local t2var `t2tmp'
    }

    // ---- Assemble URECM regressors ----------------------------------------
    // Level regressors (the "bounds testing" block): L.y, L.x+, L.x-, L.lin
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

    // Dynamic regressors
    if `p' > 1 {
        local urecm "`urecm' L(1/`=`p'-1').D.`depvar'"
    }
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
    if `kexog' > 0 {
        local urecm "`urecm' `exog'"
    }

    // Deterministic block
    if `has_trend' & "`trendvar'" != "" {
        local urecm "`urecm' `trendvar'"
    }
    if `has_quad' & "`trendvar'" != "" {
        local urecm "`urecm' `t2var'"
    }

    local consopt = cond(`has_const', "", "noconstant")

    // ---- Pre-allocate result matrices --------------------------------------
    // Levels block dimension
    local nlev = 1 + 2 * `kasym' + `klin'                       // L.y, L.x+, L.x-, L.lin
    // Dynamic block dimension
    local ndyn = (`p' - 1) + 2 * `kasym' * `q' + `klin' * `r' + `kexog'
    // Deterministic dimension (intercept handled separately)
    local ndet = `has_trend' + `has_quad'
    local ncoef = `nlev' + `ndyn' + `has_const' + `ndet'

    tempname b_all V_all phi_y_all b_lr_pos b_lr_neg b_lr_lin t_lr_pos t_lr_neg
    matrix `b_all'      = J(`ntau', `ncoef', .)
    matrix `V_all'      = J(`ntau', `ncoef', .)
    matrix `phi_y_all'  = J(`ntau', 2, .)
    matrix `b_lr_pos'   = J(`ntau', `kasym', .)
    matrix `b_lr_neg'   = J(`ntau', `kasym', .)
    matrix `t_lr_pos'   = J(`ntau', `kasym', .)
    matrix `t_lr_neg'   = J(`ntau', `kasym', .)
    if `klin' > 0 {
        matrix `b_lr_lin' = J(`ntau', `klin', .)
    }
    matrix rownames `b_lr_pos' = `tau'
    matrix rownames `b_lr_neg' = `tau'
    matrix colnames `b_lr_pos' = `asymmetry'
    matrix colnames `b_lr_neg' = `asymmetry'
    matrix rownames `t_lr_pos' = `tau'
    matrix rownames `t_lr_neg' = `tau'
    matrix colnames `t_lr_pos' = `asymmetry'
    matrix colnames `t_lr_neg' = `asymmetry'
    matrix rownames `b_all'    = `tau'

    // Build column-name labels mirroring `urecm`
    local colnms "Ly"
    foreach pv of varlist `pos_vars' {
        local colnms "`colnms' L_`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local colnms "`colnms' L_`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local colnms "`colnms' L_`lv'"
        }
    }
    if `p' > 1 {
        forvalues k = 1/`=`p'-1' {
            local colnms "`colnms' D`k'_`depvar'"
        }
    }
    foreach pv of varlist `pos_vars' {
        forvalues k = 0/`=`q'-1' {
            local colnms "`colnms' D`k'_`pv'"
        }
    }
    foreach nv of varlist `neg_vars' {
        forvalues k = 0/`=`q'-1' {
            local colnms "`colnms' D`k'_`nv'"
        }
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            forvalues k = 0/`=`r'-1' {
                local colnms "`colnms' D`k'_`lv'"
            }
        }
    }
    if `kexog' > 0 {
        foreach ex of varlist `exog' {
            local colnms "`colnms' `ex'"
        }
    }
    if `has_const'  local colnms "`colnms' _cons"
    if `has_trend' & "`trendvar'" != ""  local colnms "`colnms' trend"
    if `has_quad'  & "`trendvar'" != ""  local colnms "`colnms' trend2"
    matrix colnames `b_all' = `colnms'

    // ---- Quantile-by-quantile estimation -----------------------------------
    di as txt _n "  Single-step QNARDL: URECM via qreg"
    di as txt "    levels block size : " as res `nlev'
    di as txt "    dynamics block    : " as res `ndyn'
    di as txt "    deterministic     : " as res "`has_const'+`has_trend'+`has_quad'"

    // qreg does not accept ts-operators — expand once via tsrevar
    qui tsrevar `urecm'
    local urecm_temps `r(varlist)'
    qui tsrevar D.`depvar'
    local dydepvar `r(varlist)'

    local itau = 0
    foreach t of numlist `tau' {
        local ++itau

        capture noisily qui qreg `dydepvar' `urecm_temps' if `touse', ///
            quantile(`t') `consopt'
        if _rc {
            di as error "    qreg failed at tau=`t' (rc=" _rc ")"
            continue
        }

        // walk temp vars in order; first is L.y (phi_y), then L.x+'s, L.x-'s,
        // L.lin's, dynamics, exog, det
        local v1 : word 1 of `urecm_temps'
        local b_Ly  = _b[`v1']
        local se_Ly = _se[`v1']
        matrix `phi_y_all'[`itau', 1] = `b_Ly'
        matrix `phi_y_all'[`itau', 2] = `se_Ly'

        local jcol = 0
        foreach tv of local urecm_temps {
            local ++jcol
            cap matrix `b_all'[`itau', `jcol'] = _b[`tv']
            cap matrix `V_all'[`itau', `jcol'] = _se[`tv']^2
        }
        if `has_const' {
            local ++jcol
            cap matrix `b_all'[`itau', `jcol'] = _b[_cons]
            cap matrix `V_all'[`itau', `jcol'] = _se[_cons]^2
        }

        // long-run multipliers from level-block coefs (positions 2..nlev)
        // col 1 = L.y, cols 2..1+kasym = L.x+, cols 2+kasym..1+2*kasym = L.x-
        // Delta-method SE (ignoring Cov(phi_j, phi_y) since qreg covariance
        // matrix isn't directly accessible — conservative):
        //   beta_j = -phi_j / phi_y
        //   Var(beta_j) ≈ Var(phi_j)/phi_y^2 + phi_j^2*Var(phi_y)/phi_y^4
        local pos_start = 2
        local neg_start = 2 + `kasym'
        local lin_start = 2 + 2*`kasym'
        local phiy2 = (`b_Ly')^2
        local var_phiy = (`se_Ly')^2
        forvalues i = 1/`kasym' {
            local col   = `pos_start' + `i' - 1
            local bp_val = `b_all'[`itau', `col']
            local bp_var = `V_all'[`itau', `col']
            local b_j = -`bp_val' / `b_Ly'
            local v_j = `bp_var'/`phiy2' + (`bp_val')^2 * `var_phiy' / `phiy2'^2
            matrix `b_lr_pos'[`itau', `i'] = `b_j'
            matrix `t_lr_pos'[`itau', `i'] = cond(`v_j' > 0, `b_j' / sqrt(`v_j'), .)
        }
        forvalues i = 1/`kasym' {
            local col   = `neg_start' + `i' - 1
            local bn_val = `b_all'[`itau', `col']
            local bn_var = `V_all'[`itau', `col']
            local b_j = -`bn_val' / `b_Ly'
            local v_j = `bn_var'/`phiy2' + (`bn_val')^2 * `var_phiy' / `phiy2'^2
            matrix `b_lr_neg'[`itau', `i'] = `b_j'
            matrix `t_lr_neg'[`itau', `i'] = cond(`v_j' > 0, `b_j' / sqrt(`v_j'), .)
        }
        if `klin' > 0 {
            forvalues i = 1/`klin' {
                local col = `lin_start' + `i' - 1
                matrix `b_lr_lin'[`itau', `i'] = -`b_all'[`itau', `col'] / `b_Ly'
            }
        }
    }

    di as txt "    estimation complete: " as res `ntau' as txt " quantile(s), " ///
        as res `ncoef' as txt " coefficient(s) per quantile"

    // ---- ereturn ----------------------------------------------------------
    ereturn matrix b_urecm  = `b_all'
    ereturn matrix V_urecm  = `V_all'
    ereturn matrix phi_y    = `phi_y_all'
    ereturn matrix b_lr_pos = `b_lr_pos'
    ereturn matrix b_lr_neg = `b_lr_neg'
    ereturn matrix t_lr_pos = `t_lr_pos'
    ereturn matrix t_lr_neg = `t_lr_neg'
    if `klin' > 0 {
        ereturn matrix b_lr_lin = `b_lr_lin'
    }
    ereturn scalar nlev = `nlev'
    ereturn scalar ndyn = `ndyn'
    ereturn scalar ndet = `ndet'
end
