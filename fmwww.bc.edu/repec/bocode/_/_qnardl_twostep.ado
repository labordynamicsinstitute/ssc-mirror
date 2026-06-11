*! _qnardl_twostep v0.2.0  27may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Two-step QNARDL: FM-quantile long-run + quantile-regression short-run ECM
*!
*! Per Cho, Greenwood-Nimmo, Kim & Shin (2020a):
*!   Step 1. Re-parameterise long run as
*!             y_t = lambda(τ)' x_t + eta(τ)' x+_t + δ' lin + det + u_t(τ)
*!           where lambda = beta-,  eta = beta+ - beta-, and
*!                 x_t = x+_t + x-_t (the level recovers as the sum of partial sums).
*!           This kills the asymptotic singularity introduced by the partial-sum
*!           decomposition (Cho/G-N/Shin 2019, 2020b).
*!           Estimate by FM-quantile regression via xqcoint (Xiao 2009 FMQR).
*!           Recover  beta-_hat(τ) = lambda_hat,  beta+_hat(τ) = lambda_hat + eta_hat.
*!
*!   Step 2. Build the cointegration residual at each τ:
*!             u_hat_{t-1}(τ) = y_{t-1} - beta+_hat(τ)' x+_{t-1}
*!                                       - beta-_hat(τ)' x-_{t-1}
*!                                       - δ_hat' lin_{t-1} - det_hat
*!           Run quantile regression of Δy on  L.u_hat,  L(1..p-1).Δy,
*!           L(0..q-1).Δx+, L(0..q-1).Δx-, L(0..r-1).Δlin, Δexog, det short-run.
*!
*! Dependencies: xqcoint (qcointlib).  Falls back to plain quantile regression
*! for the long-run if xqcoint is not on the ado-path (with a warning).

program define _qnardl_twostep, eclass
    version 14.0

    syntax , [ depvar(varname) asymmetry(varlist) pos_vars(varlist) neg_vars(varlist) ///
               linear_vars(string) exog(string) tau(numlist) ///
               p(integer 1) q(integer 1) r(integer 1) step1(string) ///
               bwidth(string) case(integer 3) trendvar(string) quad(string) ///
               constant(string) restricted(string) touse(varname) level(cilevel) ]

    // ---- Resolve & validate inputs --------------------------------------
    local kasym : word count `asymmetry'
    local klin  : word count `linear_vars'
    local ntau  : word count `tau'

    // detect xqcoint
    local have_xqcoint 1
    capture which xqcoint
    if _rc {
        local have_xqcoint 0
        di as txt "  note: xqcoint not found on ado-path — using plain QR for long-run"
        di as txt "        (install qcointlib for FM-quantile inference)"
    }

    // ---- Build deterministic regressors as needed (case-dependent) ------
    // Cases:
    //   1=I (no det), 2=II (restr int), 3=III (unr int),
    //   4=IV (unr int + restr trend), 5=V (unr int + unr trend),
    //   6=VI, 7=VII (intercept+trend in DGP variants — same regressors as IV/V)
    //   8=VIII (unr int + unr trend + restr quad),
    //   9=IX  (unr int + unr trend + unr quad),
    //   10=X, 11=XI (quad variants).
    //
    // For the LONG-RUN xqcoint regression we include any deterministic factor
    // that appears in the long-run equation (cases 2..11 all include intercept).
    // xqcoint always carries an intercept internally, so we just need to add
    // t and t^2 if present.
    //
    // For the SHORT-RUN qreg we include the deterministic factors that appear
    // UNRESTRICTED (intercept always for case>=3; t for case in 5,6,7,8,9,10,11;
    // t^2 for case in 9,11).

    local lr_has_trend = inlist(`case', 4, 5, 6, 7, 8, 9, 10, 11)
    local lr_has_quad  = inlist(`case', 8, 9, 10, 11)
    local sr_has_const = (`case' >= 3)
    local sr_has_trend = inlist(`case', 5, 6, 7, 9, 10, 11)
    local sr_has_quad  = inlist(`case', 9, 11)

    // Build trend variables if needed
    local tvar_lr ""
    local t2var_lr ""
    if `lr_has_trend' & "`trendvar'" != "" {
        tempvar tvar_tmp
        qui gen double `tvar_tmp' = `trendvar' if `touse'
        local tvar_lr `tvar_tmp'
    }
    if `lr_has_quad' & "`trendvar'" != "" {
        tempvar t2var_tmp
        qui gen double `t2var_tmp' = (`trendvar')^2 if `touse'
        local t2var_lr `t2var_tmp'
    }

    // ---- STEP 1: build re-parameterised long-run regressor matrix ------
    // For each asymmetric variable v: build v_sum := v_pos + v_neg
    //   (numerically the level minus its initial value, in the working sample)
    // Long-run regressors = [v_sum vars] + [v_pos vars] + [linear vars] + [t] + [t^2]
    // Then estimate y on these via xqcoint (or qreg fallback).

    local sum_vars ""
    local i = 0
    foreach v of varlist `asymmetry' {
        local ++i
        local pv : word `i' of `pos_vars'
        local nv : word `i' of `neg_vars'
        tempvar svar
        qui gen double `svar' = `pv' + `nv' if `touse'
        local sum_vars `sum_vars' `svar'
    }

    local lr_regressors `sum_vars' `pos_vars'
    if "`linear_vars'" != "" {
        local lr_regressors `lr_regressors' `linear_vars'
    }
    if "`tvar_lr'" != "" {
        local lr_regressors `lr_regressors' `tvar_lr'
    }
    if "`t2var_lr'" != "" {
        local lr_regressors `lr_regressors' `t2var_lr'
    }

    local n_lr_reg : word count `lr_regressors'
    local n_det = ("`tvar_lr'"!="") + ("`t2var_lr'"!="")

    // ---- Run long-run estimator -----------------------------------------
    di as txt _n "  Step 1: long-run estimation"
    di as txt "    regressors (re-parameterised): " as res "`lr_regressors'"
    if `have_xqcoint' {
        di as txt "    engine: " as res "xqcoint (`step1')"

        local bw_opt = cond("`bwidth'"=="", "", "bandwidth(`bwidth')")
        local aug_opt ""
        if "`step1'" == "augfmqr" {
            // Saikkonen-style leads/lags (Xiao 2009 eq.11) — default 2 each
            local aug_opt "leads(2) lags(2)"
        }

        capture noisily qui xqcoint `depvar' `lr_regressors' if `touse', ///
            tau(`tau') `bw_opt' `aug_opt' notable nocusum
        if _rc {
            di as error "    xqcoint failed (rc=" _rc "); falling back to qreg"
            local have_xqcoint 0
        }
        else {
            tempname beta_lr_raw t_lr_raw alpha_lr_raw
            mat `beta_lr_raw'  = r(beta_set)     // ntau x n_lr_reg
            mat `t_lr_raw'     = r(t_set)
            mat `alpha_lr_raw' = r(alpha_set)    // ntau x 1
        }
    }
    if !`have_xqcoint' {
        di as txt "    engine: " as res "qreg (no long-run-variance correction)"
        // Fallback: plain qreg per τ, no FM correction
        tempname beta_lr_raw t_lr_raw alpha_lr_raw
        matrix `beta_lr_raw'  = J(`ntau', `n_lr_reg', .)
        matrix `t_lr_raw'     = J(`ntau', `n_lr_reg', .)
        matrix `alpha_lr_raw' = J(`ntau', 1, .)
        local i = 0
        foreach t of numlist `tau' {
            local ++i
            qui qreg `depvar' `lr_regressors' if `touse', quantile(`t')
            matrix `alpha_lr_raw'[`i', 1] = _b[_cons]
            local j = 0
            foreach v of varlist `lr_regressors' {
                local ++j
                matrix `beta_lr_raw'[`i', `j']  = _b[`v']
                matrix `t_lr_raw'[`i', `j']     = _b[`v'] / _se[`v']
            }
        }
    }

    // ---- Recover beta+ and beta- via reparameterisation -----------------
    // Columns of beta_lr_raw layout:
    //   1..kasym         : lambda (= beta-)
    //   kasym+1..2*kasym : eta    (= beta+ - beta-)
    //   2*kasym+1..2*kasym+klin : delta (linear vars)
    //   then det columns (t, t^2 if present)
    tempname b_lr_neg b_lr_pos b_lr_lin b_lr_det t_lr_neg t_lr_pos b_lr_int
    matrix `b_lr_int' = `alpha_lr_raw'

    matrix `b_lr_neg' = `beta_lr_raw'[1..`ntau', 1..`kasym']
    local etacols_start = `kasym' + 1
    local etacols_end   = 2 * `kasym'
    tempname eta_mat
    matrix `eta_mat'  = `beta_lr_raw'[1..`ntau', `etacols_start'..`etacols_end']
    // beta+ = lambda + eta
    matrix `b_lr_pos' = `b_lr_neg' + `eta_mat'

    // t-stats: use raw t for lambda; for beta+ we need delta-method
    //   Var(lambda + eta) = Var(lambda) + Var(eta) + 2 Cov  — not retrievable
    //   from xqcoint's t_set alone. So we'll mark these as approximate using
    //   the t-stat for eta (Cho 2020a typically reports the t-stat for the
    //   reparameterised eta as the test of asymmetry).
    matrix `t_lr_neg' = `t_lr_raw'[1..`ntau', 1..`kasym']
    matrix `t_lr_pos' = `t_lr_raw'[1..`ntau', `etacols_start'..`etacols_end']  // = t-stat of eta

    // Linear-var coefficients (if any)
    if `klin' > 0 {
        local lincols_start = 2*`kasym' + 1
        local lincols_end   = 2*`kasym' + `klin'
        matrix `b_lr_lin' = `beta_lr_raw'[1..`ntau', `lincols_start'..`lincols_end']
    }
    // Deterministic-trend coefficients (if any)
    if `n_det' > 0 {
        local detcols_start = 2*`kasym' + `klin' + 1
        local detcols_end   = 2*`kasym' + `klin' + `n_det'
        matrix `b_lr_det' = `beta_lr_raw'[1..`ntau', `detcols_start'..`detcols_end']
    }

    matrix rownames `b_lr_neg' = `tau'
    matrix rownames `b_lr_pos' = `tau'
    matrix colnames `b_lr_neg' = `asymmetry'
    matrix colnames `b_lr_pos' = `asymmetry'

    // ---- STEP 2: short-run quantile ECM per τ ---------------------------
    di as txt _n "  Step 2: short-run quantile ECM"

    tempname b_sr_all V_sr_all phi_y_all
    local nbase_sr 1                                // u_hat
    local nbase_sr = `nbase_sr' + (`p' - 1)         // Δy lags
    local nbase_sr = `nbase_sr' + 2 * `kasym' * `q'  // Δx+ and Δx- lags (incl. contemp.)
    if `klin' > 0  local nbase_sr = `nbase_sr' + `klin' * `r'
    if "`exog'" != "" {
        local kexog : word count `exog'
        local nbase_sr = `nbase_sr' + `kexog'
    }
    if `sr_has_const' local nbase_sr = `nbase_sr' + 1
    if `sr_has_trend' local nbase_sr = `nbase_sr' + 1
    if `sr_has_quad'  local nbase_sr = `nbase_sr' + 1

    matrix `b_sr_all'  = J(`ntau', `nbase_sr', .)
    matrix `V_sr_all'  = J(`ntau', `nbase_sr', .)
    matrix `phi_y_all' = J(`ntau', 2, .)            // col1: coef, col2: SE

    // Build labels for short-run columns (order must match the regressors
    // sent through tsrevar inside the per-tau loop; _cons is appended last).
    local srnames "uhat_L1"
    forvalues j = 1/`=`p'-1' {
        local srnames "`srnames' D`j'_`depvar'"
    }
    local i = 0
    foreach v of varlist `asymmetry' {
        local ++i
        local pv : word `i' of `pos_vars'
        local nv : word `i' of `neg_vars'
        forvalues j = 0/`=`q'-1' {
            local srnames "`srnames' D`j'_`pv'"
        }
        forvalues j = 0/`=`q'-1' {
            local srnames "`srnames' D`j'_`nv'"
        }
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            forvalues j = 0/`=`r'-1' {
                local srnames "`srnames' D`j'_`lv'"
            }
        }
    }
    if "`exog'" != "" {
        foreach ex of varlist `exog' {
            local srnames "`srnames' `ex'"
        }
    }
    if `sr_has_trend' & "`trendvar'" != "" local srnames "`srnames' trend"
    if `sr_has_quad'  & "`trendvar'" != "" local srnames "`srnames' trend2"
    if `sr_has_const'                      local srnames "`srnames' _cons"

    matrix colnames `b_sr_all' = `srnames'
    matrix rownames `b_sr_all' = `tau'
    matrix colnames `V_sr_all' = `srnames'
    matrix rownames `V_sr_all' = `tau'
    matrix rownames `phi_y_all' = `tau'
    matrix colnames `phi_y_all' = coef se

    // Loop over τ
    local itau = 0
    foreach t of numlist `tau' {
        local ++itau

        // ---- build u_hat for this τ ----
        tempvar uhat
        qui gen double `uhat' = `depvar' if `touse'
        // subtract beta+' x+
        forvalues j = 1/`kasym' {
            local pv : word `j' of `pos_vars'
            local b  = `b_lr_pos'[`itau', `j']
            qui replace `uhat' = `uhat' - (`b') * `pv' if `touse'
        }
        // subtract beta-' x-
        forvalues j = 1/`kasym' {
            local nv : word `j' of `neg_vars'
            local b  = `b_lr_neg'[`itau', `j']
            qui replace `uhat' = `uhat' - (`b') * `nv' if `touse'
        }
        // subtract delta' lin
        if `klin' > 0 {
            local j = 0
            foreach lv of varlist `linear_vars' {
                local ++j
                local b  = `b_lr_lin'[`itau', `j']
                qui replace `uhat' = `uhat' - (`b') * `lv' if `touse'
            }
        }
        // subtract intercept
        local aint = `b_lr_int'[`itau', 1]
        qui replace `uhat' = `uhat' - (`aint') if `touse'
        // subtract trend / quad-trend if in long-run
        if "`tvar_lr'" != "" {
            local j_det = 1
            local b  = `b_lr_det'[`itau', `j_det']
            qui replace `uhat' = `uhat' - (`b') * `tvar_lr' if `touse'
        }
        if "`t2var_lr'" != "" {
            local j_det = `=("`tvar_lr'"!="")' + 1
            local b  = `b_lr_det'[`itau', `j_det']
            qui replace `uhat' = `uhat' - (`b') * `t2var_lr' if `touse'
        }

        // ---- assemble short-run regressor EXPRESSIONS (will tsrevar them) ----
        // qreg does NOT accept ts-operators; we expand to temp vars and feed
        // those instead, then extract coefficients by temp-var name.
        local sr_expr "L.`uhat'"
        if `p' > 1 {
            local sr_expr "`sr_expr' L(1/`=`p'-1').D.`depvar'"
        }
        foreach pv of varlist `pos_vars' {
            if `q' >= 1  local sr_expr "`sr_expr' L(0/`=`q'-1').D.`pv'"
        }
        foreach nv of varlist `neg_vars' {
            if `q' >= 1  local sr_expr "`sr_expr' L(0/`=`q'-1').D.`nv'"
        }
        if `klin' > 0 {
            foreach lv of varlist `linear_vars' {
                if `r' >= 1  local sr_expr "`sr_expr' L(0/`=`r'-1').D.`lv'"
            }
        }
        if "`exog'" != "" {
            local sr_expr "`sr_expr' `exog'"
        }
        // short-run deterministic factors
        if `sr_has_trend' & "`trendvar'" != "" {
            local sr_expr "`sr_expr' `trendvar'"
        }
        if `sr_has_quad' & "`trendvar'" != "" {
            tempvar t2sr
            qui gen double `t2sr' = (`trendvar')^2 if `touse'
            local sr_expr "`sr_expr' `t2sr'"
        }

        // Expand every ts-op into a tempvar
        qui tsrevar `sr_expr'
        local sr_temps `r(varlist)'

        // LHS: qreg also rejects D.y on the left, so expand that too
        qui tsrevar D.`depvar'
        local dydepvar `r(varlist)'

        local consopt = cond(`sr_has_const', "", "noconstant")

        capture noisily qui qreg `dydepvar' `sr_temps' if `touse', ///
            quantile(`t') `consopt'
        if _rc {
            di as error "    qreg failed at tau=`t' (rc=" _rc ")"
            continue
        }

        // ---- harvest by position: the FIRST temp is L.uhat (phi_y) ----
        local v1 : word 1 of `sr_temps'
        local phi_coef = _b[`v1']
        local phi_se   = _se[`v1']
        matrix `phi_y_all'[`itau', 1] = `phi_coef'
        matrix `phi_y_all'[`itau', 2] = `phi_se'

        // walk all temp vars in order; appended at the end is _cons (if any)
        local jcol = 0
        foreach tv of local sr_temps {
            local ++jcol
            cap matrix `b_sr_all'[`itau', `jcol'] = _b[`tv']
            cap matrix `V_sr_all'[`itau', `jcol'] = _se[`tv']^2
        }
        if `sr_has_const' {
            local ++jcol
            cap matrix `b_sr_all'[`itau', `jcol'] = _b[_cons]
            cap matrix `V_sr_all'[`itau', `jcol'] = _se[_cons]^2
        }
    }

    di as txt "    estimation complete: " as res `ntau' as txt " quantile(s), " ///
        as res `nbase_sr' as txt " coefficient(s) per quantile"

    // ---- ereturn the assembled results ---------------------------------
    ereturn matrix b_lr_pos = `b_lr_pos'
    ereturn matrix b_lr_neg = `b_lr_neg'
    ereturn matrix t_lr_pos = `t_lr_pos'
    ereturn matrix t_lr_neg = `t_lr_neg'
    ereturn matrix b_lr_int = `b_lr_int'
    if `klin' > 0 {
        ereturn matrix b_lr_lin = `b_lr_lin'
    }
    if `n_det' > 0 {
        ereturn matrix b_lr_det = `b_lr_det'
    }
    ereturn matrix b_sr  = `b_sr_all'
    ereturn matrix V_sr  = `V_sr_all'
    ereturn matrix phi_y = `phi_y_all'

    ereturn scalar have_xqcoint = `have_xqcoint'
    ereturn local engine = cond(`have_xqcoint', "xqcoint-`step1'", "qreg-fallback")
end
