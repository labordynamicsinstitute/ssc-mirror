*! _qnardl_display v0.3.0  27may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Formatted display module for qnardl results.
*!
*! Method-aware: reads b_sr/V_sr for twostep, b_urecm/V_urecm for onestep.
*! Variable names in tables are stripped of internal prefixes for readability.
*!

program define _qnardl_display
    version 14.0
    syntax [, FULL BYTAU Level(cilevel) noTABle noHeader * ]

    if "`level'" == "" local level = cond(e(level)<., e(level), 95)
    local crit_z = invnormal(1 - (100-`level')/200)

    if "`table'" == "notable" exit

    // If the user wants the by-tau consolidated view, dispatch to that
    // subroutine and return — it replaces the standard A/B/C layout.
    if "`bytau'" != "" {
        _qnardl_display_bytau , level(`level')
        exit
    }

    local method = e(method)
    local depvar = e(depvar)

    // ============================================================
    // SECTION A: long-run β⁺, β⁻ with t-stats
    // ============================================================
    capture confirm matrix e(b_lr_pos)
    if _rc {
        di as txt _n "{hline 78}"
        di as error "[A] LONG-RUN COEFFICIENTS — matrix e(b_lr_pos) not found"
        di as txt   "    estimation may have failed; check warnings above."
        di as txt   "{hline 78}"
        exit
    }

    tempname bpos bneg tpos tneg phi
    matrix `bpos' = e(b_lr_pos)
    matrix `bneg' = e(b_lr_neg)
    matrix `phi'  = e(phi_y)
    capture matrix `tpos' = e(t_lr_pos)
    if _rc local has_tpos 0
    else   local has_tpos 1
    capture matrix `tneg' = e(t_lr_neg)
    if _rc local has_tneg 0
    else   local has_tneg 1

    local asymvars : colnames `bpos'
    local taus     : rownames `bpos'
    local kasym : word count `asymvars'
    local ntau  : word count `taus'

    di as txt _n "{hline 78}"
    di as res "[A] LONG-RUN COEFFICIENTS"
    di as txt _col(3) "beta+ = positive-regime long-run multiplier; "
    di as txt _col(3) "beta- = negative-regime; Asymmetry = beta+ - beta-"
    di as txt "{hline 78}"

    forvalues t = 1/`ntau' {
        local tauv : word `t' of `taus'
        di as txt _n as res _col(3) "tau = " `tauv'
        di as txt _col(3) "{hline 72}"
        di as txt _col(3) %-12s "Variable" ///
                  _col(18) %12s "beta+" ///
                  _col(32) %10s "t" ///
                  _col(45) %12s "beta-" ///
                  _col(59) %10s "t" ///
                  _col(70) %8s "asym."
        di as txt _col(3) "{hline 72}"

        forvalues j = 1/`kasym' {
            local vn : word `j' of `asymvars'
            local bp = `bpos'[`t', `j']
            local bn = `bneg'[`t', `j']
            local tp = .
            local tn = .
            if `has_tpos' local tp = `tpos'[`t', `j']
            if `has_tneg' local tn = `tneg'[`t', `j']
            local asym = `bp' - `bn'
            local sp = ""
            local sn = ""
            if !missing(`tp') {
                if abs(`tp') > 1.645 local sp "*"
                if abs(`tp') > 1.96  local sp "**"
                if abs(`tp') > 2.576 local sp "***"
            }
            if !missing(`tn') {
                if abs(`tn') > 1.645 local sn "*"
                if abs(`tn') > 1.96  local sn "**"
                if abs(`tn') > 2.576 local sn "***"
            }
            local tp_str = cond(missing(`tp'), "    n/a", string(`tp', "%7.2f"))
            local tn_str = cond(missing(`tn'), "    n/a", string(`tn', "%7.2f"))

            di as txt _col(3) %-12s "`vn'" ///
                      as res _col(18) %10.4f `bp' as txt " `sp'" ///
                      as res _col(32) %10s "`tp_str'" ///
                      as res _col(45) %10.4f `bn' as txt " `sn'" ///
                      as res _col(59) %10s "`tn_str'" ///
                      as res _col(70) %8.3f `asym'
        }
        di as txt _col(3) "{hline 72}"
    }
    di as txt _col(3) "Significance:  * p<.10   ** p<.05   *** p<.01"
    if !`has_tpos' | !`has_tneg' {
        di as txt _col(3) "(Long-run t-stats unavailable for {bf:onestep} method;"
        di as txt _col(3) " they would require delta-method or bootstrap SEs.)"
    }

    // ============================================================
    // SECTION B: ECT (φ_y) across quantiles
    // ============================================================
    di as txt _n "{hline 78}"
    di as res "[B] ERROR-CORRECTION TERM  phi_y(tau)"
    di as txt _col(3) "Negative and significant ==> convergence to long-run equilibrium."
    di as txt "{hline 78}"
    di as txt _col(3) %-8s "tau" _col(14) %12s "phi_y" _col(28) %10s "SE" ///
              _col(40) %10s "t-stat" _col(52) %10s "p>|t|" ///
              _col(64) %14s "[`level'% CI]"
    di as txt _col(3) "{hline 75}"
    forvalues t = 1/`ntau' {
        local tauv : word `t' of `taus'
        local b  = `phi'[`t', 1]
        local se = `phi'[`t', 2]
        if missing(`b') | missing(`se') {
            di as txt _col(3) %-8s "`tauv'" as res _col(14) %12s "n/a"
            continue
        }
        local tstat = `b' / `se'
        local pval  = 2 * (1 - normal(abs(`tstat')))
        local lo = `b' - `crit_z' * `se'
        local hi = `b' + `crit_z' * `se'
        local star = ""
        if `pval' < 0.10 local star "*"
        if `pval' < 0.05 local star "**"
        if `pval' < 0.01 local star "***"
        di as txt _col(3) %-8s "`tauv'" ///
                  as res _col(14) %10.4f `b' as txt " `star'" ///
                  as res _col(28) %10.4f `se' ///
                  as res _col(40) %10.3f `tstat' ///
                  as res _col(52) %10.4f `pval' ///
                  as res _col(63) "[" %6.3f `lo' ", " %6.3f `hi' "]"
    }
    di as txt _col(3) "{hline 75}"

    // ============================================================
    // SECTION C: short-run coefficients
    //  - twostep stores b_sr/V_sr
    //  - onestep stores b_urecm/V_urecm
    // ============================================================
    tempname bsr Vsr
    local found_sr 0
    if "`method'" == "onestep" {
        capture confirm matrix e(b_urecm)
        if !_rc {
            matrix `bsr' = e(b_urecm)
            matrix `Vsr' = e(V_urecm)
            local found_sr 1
        }
    }
    else {
        capture confirm matrix e(b_sr)
        if !_rc {
            matrix `bsr' = e(b_sr)
            matrix `Vsr' = e(V_sr)
            local found_sr 1
        }
    }

    di as txt _n "{hline 78}"
    if "`full'" == "" {
        di as res "[C] SHORT-RUN / URECM COEFFICIENTS  (median quantile)"
        di as txt _col(3) "Use {bf:qnardl, full} for all quantiles."
    }
    else {
        di as res "[C] SHORT-RUN / URECM COEFFICIENTS  (all quantiles)"
    }
    di as txt "{hline 78}"

    if !`found_sr' {
        di as txt _col(3) "(no short-run / URECM matrix found in e())"
        exit
    }

    local srnames : colnames `bsr'
    local nsr : word count `srnames'

    // pick which rows to print
    if "`full'" == "" {
        local pickrow = 1
        local mindist = .
        forvalues t = 1/`ntau' {
            local tv : word `t' of `taus'
            local d = abs(`tv' - 0.5)
            if `d' < `mindist' {
                local mindist = `d'
                local pickrow = `t'
            }
        }
        local print_rows "`pickrow'"
    }
    else {
        local print_rows ""
        forvalues t = 1/`ntau' {
            local print_rows "`print_rows' `t'"
        }
    }

    foreach t of local print_rows {
        local tauv : word `t' of `taus'
        di as txt _n as res _col(3) "tau = " `tauv'
        di as txt _col(3) "{hline 72}"
        di as txt _col(3) %-28s "Variable" ///
                  _col(32) %12s "Coef." _col(46) %10s "SE" ///
                  _col(58) %10s "t-stat" _col(70) %8s "p>|t|"
        di as txt _col(3) "{hline 72}"
        forvalues j = 1/`nsr' {
            local v : word `j' of `srnames'
            // pretty-print: strip _qnardl_, replace D0_/D1_ with D., L_ with L.
            local vshow = "`v'"
            local vshow : subinstr local vshow "_qnardl_" "", all
            local vshow : subinstr local vshow "D0_" "D."
            local vshow : subinstr local vshow "L_" "L."
            local vshow : subinstr local vshow "uhat_L1" "L.u_hat"
            forvalues kk = 1/9 {
                local vshow : subinstr local vshow "D`kk'_" "L`kk'D."
            }
            local b  = `bsr'[`t', `j']
            local v_ = `Vsr'[`t', `j']
            if missing(`b') | missing(`v_') continue
            local se = sqrt(`v_')
            if `se' == 0 | missing(`se') continue
            local ts = `b' / `se'
            local pv = 2 * (1 - normal(abs(`ts')))
            local star = ""
            if `pv' < 0.10 local star "*"
            if `pv' < 0.05 local star "**"
            if `pv' < 0.01 local star "***"
            di as txt _col(3) %-28s "`vshow'" ///
                      as res _col(32) %10.4f `b' as txt " `star'" ///
                      as res _col(46) %10.4f `se' ///
                      as res _col(58) %10.3f `ts' ///
                      as res _col(70) %8.4f `pv'
        }
        di as txt _col(3) "{hline 72}"
    }

    di as txt _n "{hline 78}"
    di as txt "Notes: Stars based on standard normal asymptotics."
    if "`method'" == "twostep" {
        di as txt "       Long-run beta+/beta- are mixed-normal (Cho et al. 2020a);"
        di as txt "       Wald tests use chi^2 — run {bf:qnardl, lrsymmetry}."
    }
    else {
        di as txt "       URECM regression — bounds tests use simulated PSS CVs"
        di as txt "       (Bertsatos, Sakellaris & Tsionas 2022) — run {bf:qnardl, bounds}."
    }
    di as txt "{hline 78}"
end


// =============================================================================
// BY-TAU consolidated display: one block per quantile showing long-run,
// ECT, and short-run coefficients together (standard NARDL paper layout).
// =============================================================================
program define _qnardl_display_bytau
    version 14.0
    syntax , [ Level(cilevel) ]

    if "`level'" == "" local level = cond(e(level)<., e(level), 95)
    local crit_z = invnormal(1 - (100-`level')/200)

    local method = e(method)
    local depvar = e(depvar)

    tempname bpos bneg tpos tneg phi bsr Vsr
    matrix `bpos' = e(b_lr_pos)
    matrix `bneg' = e(b_lr_neg)
    matrix `phi'  = e(phi_y)
    capture matrix `tpos' = e(t_lr_pos)
    if _rc local has_tpos 0
    else   local has_tpos 1
    capture matrix `tneg' = e(t_lr_neg)
    if _rc local has_tneg 0
    else   local has_tneg 1

    // short-run matrix: method-aware
    local found_sr 0
    if "`method'" == "onestep" {
        capture confirm matrix e(b_urecm)
        if !_rc {
            matrix `bsr' = e(b_urecm)
            matrix `Vsr' = e(V_urecm)
            local found_sr 1
        }
    }
    else {
        capture confirm matrix e(b_sr)
        if !_rc {
            matrix `bsr' = e(b_sr)
            matrix `Vsr' = e(V_sr)
            local found_sr 1
        }
    }

    local asymvars : colnames `bpos'
    local taus     : rownames `bpos'
    local kasym : word count `asymvars'
    local ntau  : word count `taus'
    local srnames : colnames `bsr'
    local nsr : word count `srnames'

    di as txt _n "{hline 78}"
    di as res "  CONSOLIDATED BY-QUANTILE OUTPUT"
    di as txt "  One block per tau combining long-run, ECT, and short-run dynamics."
    di as txt "{hline 78}"

    forvalues t = 1/`ntau' {
        local tauv : word `t' of `taus'

        di as txt _n "{hline 78}"
        di as res _col(3) "QUANTILE  tau = " `tauv'
        di as txt "{hline 78}"

        // --- (a) Long-run coefficients ---
        di as txt _col(3) "{bf:[a] Long-run multipliers}"
        di as txt _col(5) "{hline 70}"
        di as txt _col(5) %-12s "Variable" ///
                  _col(20) %10s "beta+" _col(33) %8s "t" ///
                  _col(45) %10s "beta-" _col(58) %8s "t" ///
                  _col(68) %8s "asym."
        di as txt _col(5) "{hline 70}"
        forvalues j = 1/`kasym' {
            local vn : word `j' of `asymvars'
            local bp = `bpos'[`t', `j']
            local bn = `bneg'[`t', `j']
            local tp = .
            local tn = .
            if `has_tpos' local tp = `tpos'[`t', `j']
            if `has_tneg' local tn = `tneg'[`t', `j']
            local sp = ""
            local sn = ""
            if !missing(`tp') {
                if abs(`tp') > 1.645 local sp "*"
                if abs(`tp') > 1.96  local sp "**"
                if abs(`tp') > 2.576 local sp "***"
            }
            if !missing(`tn') {
                if abs(`tn') > 1.645 local sn "*"
                if abs(`tn') > 1.96  local sn "**"
                if abs(`tn') > 2.576 local sn "***"
            }
            local tp_s = cond(missing(`tp'), "    .", string(`tp', "%7.2f"))
            local tn_s = cond(missing(`tn'), "    .", string(`tn', "%7.2f"))
            local asym = `bp' - `bn'
            di as txt _col(5) %-12s "`vn'" ///
                      as res _col(20) %10.4f `bp' as txt " `sp'" ///
                      as res _col(33) %8s "`tp_s'" ///
                      as res _col(45) %10.4f `bn' as txt " `sn'" ///
                      as res _col(58) %8s "`tn_s'" ///
                      as res _col(68) %8.3f `asym'
        }
        di as txt _col(5) "{hline 70}"

        // --- (b) ECT ---
        local b  = `phi'[`t', 1]
        local se = `phi'[`t', 2]
        if !missing(`b') & !missing(`se') {
            local tstat = `b' / `se'
            local pval  = 2 * (1 - normal(abs(`tstat')))
            local lo = `b' - `crit_z' * `se'
            local hi = `b' + `crit_z' * `se'
            local star = ""
            if `pval' < 0.10  local star "*"
            if `pval' < 0.05  local star "**"
            if `pval' < 0.01  local star "***"
            di as txt _n _col(3) "{bf:[b] Error-correction term  phi_y(tau)}"
            di as txt _col(5) "{hline 70}"
            di as txt _col(5) %-12s "phi_y" ///
                      as res _col(20) %10.4f `b' as txt " `star'" ///
                      as res _col(33) "SE = " %7.4f `se' ///
                      as res _col(52) "t = " %6.2f `tstat' ///
                      as res _col(66) "p = " %6.4f `pval'
            di as txt _col(5) "[`level'% CI: " %7.4f `lo' ", " %7.4f `hi' "]"
            di as txt _col(5) "{hline 70}"
        }

        // --- (c) Short-run / URECM ---
        if `found_sr' {
            di as txt _n _col(3) "{bf:[c] Short-run dynamics" cond("`method'"=="onestep", " (URECM, level + Δ blocks)", " (ECM with plug-in u_hat)") "}"
            di as txt _col(5) "{hline 70}"
            di as txt _col(5) %-26s "Variable" ///
                      _col(34) %10s "Coef." _col(46) %10s "SE" ///
                      _col(58) %9s "t" _col(67) %9s "p>|t|"
            di as txt _col(5) "{hline 70}"
            forvalues j = 1/`nsr' {
                local v : word `j' of `srnames'
                local vshow = "`v'"
                local vshow : subinstr local vshow "_qnardl_" "", all
                local vshow : subinstr local vshow "D0_" "D."
                local vshow : subinstr local vshow "L_" "L."
                local vshow : subinstr local vshow "uhat_L1" "L.u_hat"
                forvalues kk = 1/9 {
                    local vshow : subinstr local vshow "D`kk'_" "L`kk'D."
                }
                local b  = `bsr'[`t', `j']
                local v_ = `Vsr'[`t', `j']
                if missing(`b') | missing(`v_') continue
                local se = sqrt(`v_')
                if `se' == 0 | missing(`se') continue
                local ts = `b' / `se'
                local pv = 2 * (1 - normal(abs(`ts')))
                local star = ""
                if `pv' < 0.10 local star "*"
                if `pv' < 0.05 local star "**"
                if `pv' < 0.01 local star "***"
                di as txt _col(5) %-26s "`vshow'" ///
                          as res _col(34) %10.4f `b' as txt " `star'" ///
                          as res _col(46) %10.4f `se' ///
                          as res _col(58) %9.3f `ts' ///
                          as res _col(67) %9.4f `pv'
            }
            di as txt _col(5) "{hline 70}"
        }
    }

    di as txt _n "{hline 78}"
    di as txt "Notes: Standard normal asymptotics; * p<.10, ** p<.05, *** p<.01."
    if "`method'" == "twostep" {
        di as txt "       Long-run beta+/beta- are mixed-normal (Cho et al. 2020a)."
    }
    di as txt "       To switch back to the section A/B/C view: {bf:qnardl}  (no bytau)"
    di as txt "{hline 78}"
end
