*! xtbestcce 1.0.0 - 2026-05-12
*! Author : Dr. Merwan Roudane
*! Email  : merwanroudane920@gmail.com
*!
*! Bootstrap-Enhanced Common Correlated Effects estimation for panels
*! with distinct correlated factors.
*!
*! Implements the toolbox of:
*!   Stauskas, O. and De Vos, I. (2024).
*!   "Handling Distinct Correlated Effects with CCE."
*!   MPRA Paper No. 120194.
*!
*!   - CCEP (pooled)  / CCEMG (mean-group) estimators     eq. (2.4)-(2.5)
*!   - Information Criterion selector for CAs              eq. (3.1)-(3.2)
*!     (Margaritella & Westerlund 2023 / De Vos-Stauskas 2024)
*!   - Cross-Section bootstrap (Algorithm 1) percentile CI eq. (2.8)
*!   - Analytical variance estimators                      eq. (2.6)-(2.7)
*!   - Beautiful output table and visualization
*!
*! Companion to xtdcce2 (Ditzen, 2024).        For help :  help xtbestcce

program define xtbestcce, eclass sortpreserve
        version 15.1

        if replay() {
                if ("`e(cmd)'" != "xtbestcce") error 301
                Display, level(`=e(level)') nice(`=e(nicetab)')
                exit
        }

        syntax varlist(min=2 numeric ts) [if] [in] ,         ///
                [                                             ///
                Pooled                                        ///
                MG                                            ///
                CRosssectional(varlist numeric ts)            ///
                IC                                            ///
                IC_Penalty(string)                            ///
                NOYBAR                                        ///
                Bootstrap                                     ///
                Reps(integer 999)                             ///
                Seed(integer 0)                               ///
                Level(cilevel)                                ///
                FE                                            ///
                NOConstant                                    ///
                NICE                                          ///
                Plot                                          ///
                BOOTPLOT                                      ///
                NOTABle                                       ///
                BSAVE(name)                                   ///
                Trace                                         ///
                ]

        marksample touse
        markout `touse'

        // -----------------------------------------------------------
        // 0. Parse and validate
        // -----------------------------------------------------------
        capture xtset
        if _rc {
                di as err "panel data must be xtset before running xtbestcce"
                exit 459
        }
        local idvar  "`r(panelvar)'"
        local tvar   "`r(timevar)'"
        if ("`tvar'" == "") {
                di as err "xtset must specify a time variable"
                exit 459
        }

        local estimator "ccep"
        if ("`mg'" != "")     local estimator "ccemg"
        if ("`pooled'" != "" & "`mg'" != "") {
                di as err "options pooled and mg are mutually exclusive"
                exit 198
        }

        gettoken depvar indepvars : varlist
        local k : word count `indepvars'

        if ("`crosssectional'" == "") local crosssectional "`depvar' `indepvars'"

        local incl_ybar = ("`noybar'" == "")
        local doboot    = ("`bootstrap'" != "")
        if `doboot' & `reps' < 99 {
                di as err "bootstrap reps() must be at least 99"
                exit 198
        }
        if ("`ic_penalty'" == "") local ic_penalty "log"
        if !inlist("`ic_penalty'", "log", "sqrt", "nt") {
                di as err "ic_penalty() must be one of: log sqrt nt"
                exit 198
        }

        local fixedeffects = ("`fe'" != "")
        local addconstant  = ("`noconstant'" == "")
        // Per paper eq. (1.1), the CCE model has no separate intercept: β is
        // the only parameter and FE is handled by adding a column of ones to
        // the CAs (paper p.4). So when fe is on we drop the redundant constant
        // from X — there is no post-hoc α̂ to display.
        if `fixedeffects' local addconstant 0
        local doplot       = ("`plot'" != "")
        local dobootplot   = ("`bootplot'" != "")
        local doniceTable  = ("`nice'" != "")
        local notabledisp  = ("`notable'" != "")
        local trace_on     = ("`trace'" != "")
        local doIC         = ("`ic'" != "")

        if `dobootplot' & !`doboot' {
                di as err "bootplot requires the bootstrap option"
                exit 198
        }
        if `seed' > 0 set seed `seed'

        // -----------------------------------------------------------
        // 1. Header
        // -----------------------------------------------------------
        Banner, depvar(`depvar') estimator(`estimator') ic(`doIC') ///
                bootstrap(`doboot') reps(`reps')

        // -----------------------------------------------------------
        // 2. Call Mata
        // -----------------------------------------------------------
        tempname b V Vb bsamples sel
        tempname Nobs Npanels Tperiods kx gca

        mata: _xtbestcce_run(                                    ///
                "`depvar'", "`indepvars'", "`crosssectional'",    ///
                "`idvar'", "`tvar'", "`touse'",                   ///
                `incl_ybar', `addconstant', `fixedeffects',       ///
                "`estimator'", `doIC', "`ic_penalty'",             ///
                `doboot', `reps', `trace_on',                     ///
                "`b'", "`V'", "`Vb'", "`bsamples'", "`sel'",      ///
                "`Nobs'", "`Npanels'", "`Tperiods'",              ///
                "`kx'", "`gca'", "_xtbestcce_caStr"                ///
        )

        local Fxnames_disp "`_xtbestcce_caStr'"

        // -----------------------------------------------------------
        // 3. Post results
        // -----------------------------------------------------------
        local colnames "`indepvars'"
        if `addconstant' local colnames "`colnames' _cons"

        matrix colnames `b' = `colnames'
        matrix rownames `V' = `colnames'
        matrix colnames `V' = `colnames'

        if `doboot' {
                matrix rownames `Vb' = `colnames'
                matrix colnames `Vb' = `colnames'
        }

        ereturn post `b' `V', esample(`touse') depname(`depvar') ///
                obs(`=scalar(`Nobs')')

        ereturn local cmd       "xtbestcce"
        ereturn local cmdline   "xtbestcce `0'"
        ereturn local estimator "`estimator'"
        ereturn local depvar    "`depvar'"
        ereturn local indepvars "`indepvars'"
        ereturn local idvar     "`idvar'"
        ereturn local tvar      "`tvar'"
        ereturn local ic_pen    "`ic_penalty'"
        ereturn local Fxnames   "`Fxnames_disp'"
        ereturn local author    "Dr. Merwan Roudane"
        ereturn local paperref  "Stauskas & De Vos (2024) MPRA 120194"

        ereturn scalar N         = scalar(`Nobs')
        ereturn scalar N_g       = scalar(`Npanels')
        ereturn scalar T         = scalar(`Tperiods')
        ereturn scalar k         = scalar(`kx')
        ereturn scalar g_ca      = scalar(`gca')
        ereturn scalar ic_used   = `doIC'
        ereturn scalar fe        = `fixedeffects'
        ereturn scalar bootstrap = `doboot'
        ereturn scalar level     = `level'
        ereturn scalar nicetab   = `doniceTable'
        if `doboot' {
                ereturn scalar reps      = `reps'
                ereturn matrix V_boot    = `Vb'
                if ("`bsave'" != "") {
                        matrix `bsave' = `bsamples'
                        matrix colnames `bsave' = `colnames'
                        ereturn matrix bsamples = `bsave'
                }
                else {
                        matrix colnames `bsamples' = `colnames'
                        ereturn matrix bsamples = `bsamples'
                }
        }
        if `doIC' {
                ereturn matrix selector = `sel'
        }

        if !`notabledisp' {
                Display, level(`level') nice(`doniceTable')
        }

        if `doplot'     xtbestcce_plot, kind(coef)
        if `dobootplot' xtbestcce_plot, kind(bdist)
end


// =================================================================
// Sub-program: Banner header
// =================================================================
program define Banner
        syntax , depvar(string) estimator(string) ic(integer) ///
                bootstrap(integer) reps(integer)

        local est_label = cond("`estimator'"=="ccep", "Pooled (CCEP)", "Mean-Group (CCEMG)")
        di
        di as txt "{hline 78}"
        di as txt "  {bf:xtbestcce}  Bootstrap-Enhanced CCE with Distinct Correlated Factors"
        di as txt "  Stauskas & De Vos (2024)"
        di as txt "{hline 78}"
        di as txt "  Estimator    : " as res "`est_label'"
        di as txt "  Dependent var: " as res "`depvar'"
        di as txt "  IC selector  : " as res cond(`ic'==1, "active", "off")
        di as txt "  CS bootstrap : " as res cond(`bootstrap'==1, "B = `reps'", "off")
        di as txt "{hline 78}"
end


// =================================================================
// Sub-program: Display results
// =================================================================
program define Display
        syntax , [level(cilevel) nice(integer 0)]
        if ("`level'" == "") local level 95
        local critz = invnormal(1 - (1-`level'/100)/2)
        local alpha_lo = (100-`level')/2
        local alpha_hi = 100 - `alpha_lo'

        // If bootstrap was used, prebuild percentile CIs per eq. (2.8):
        //   CI = [ 2β̂ - θ*_{1-α/2},  2β̂ - θ*_{α/2} ]
        local use_boot_ci = 0
        capture matrix list e(bsamples)
        if !_rc & e(bootstrap) == 1 local use_boot_ci 1

        di
        if `nice' {
                di as txt "{c TLC}{hline 14}{c TT}{hline 12}{c TT}{hline 12}{c TT}{hline 8}{c TT}{hline 8}{c TT}{hline 12}{c TT}{hline 12}{c TRC}"
                di as txt "{c |} " %-12s "Variable"  " {c |} " ///
                                   %10s "Coef." " {c |} " ///
                                   %10s "Std.Err." " {c |} " ///
                                   %6s "z" " {c |} " ///
                                   %6s "P>|z|" " {c |} " ///
                                   %10s "[`level'% CI" " {c |} " ///
                                   %10s "Upper]"  " {c |}"
                di as txt "{c LT}{hline 14}{c +}{hline 12}{c +}{hline 12}{c +}{hline 8}{c +}{hline 8}{c +}{hline 12}{c +}{hline 12}{c RT}"
        }
        else {
                di as txt "{hline 13}{c TT}{hline 64}"
                di as txt %12s "`e(depvar)'" " {c |}  " ///
                          %10s "Coef." "   " %9s "Std.Err." "   " ///
                          %6s "z" "   " %6s "P>|z|" "   " ///
                          %20s "[`level'% Conf. Interval]"
                di as txt "{hline 13}{c +}{hline 64}"
        }

        local cols : colnames e(b)
        local p = colsof(e(b))

        // Pre-extract bootstrap quantiles if needed (eq 2.8 basic-bootstrap CI)
        if `use_boot_ci' {
                tempname BS
                matrix `BS' = e(bsamples)
                preserve
                quietly {
                        clear
                        svmat `BS', names(xbcoef)
                }
        }

        forvalues j = 1/`p' {
                local nm : word `j' of `cols'
                local cf = el(e(b), 1, `j')
                local se = sqrt(el(e(V), `j', `j'))
                if (`se' == 0) | (`se' >= .) {
                        local zz = .
                        local pz = .
                        local lo = .
                        local hi = .
                }
                else {
                        local zz = `cf'/`se'
                        local pz = 2*(1 - normal(abs(`zz')))
                        if `use_boot_ci' {
                                quietly _pctile xbcoef`j', p(`alpha_lo' `alpha_hi')
                                local q_lo = r(r1)
                                local q_hi = r(r2)
                                // Basic-bootstrap CI of eq. (2.8)
                                local lo = 2*`cf' - `q_hi'
                                local hi = 2*`cf' - `q_lo'
                        }
                        else {
                                local lo = `cf' - `critz'*`se'
                                local hi = `cf' + `critz'*`se'
                        }
                }
                if `nice' {
                        di as txt "{c |} " as res %-12s "`nm'" as txt " {c |} " ///
                          as res %10.6f `cf' as txt " {c |} " ///
                          as res %10.6f `se' as txt " {c |} " ///
                          as res %6.2f  `zz' as txt " {c |} " ///
                          as res %6.4f  `pz' as txt " {c |} " ///
                          as res %10.6f `lo' as txt " {c |} " ///
                          as res %10.6f `hi' as txt " {c |}"
                }
                else {
                        di as txt %12s "`nm'" " {c |} " ///
                          as res %10.6f `cf' "  "  ///
                          as res %9.6f  `se' "  "  ///
                          as res %6.2f  `zz' "  "  ///
                          as res %6.4f  `pz' "  "  ///
                          as res %10.6f `lo' "  " ///
                          as res %10.6f `hi'
                }
        }
        if `use_boot_ci' restore

        if `nice' {
                di as txt "{c BLC}{hline 14}{c BT}{hline 12}{c BT}{hline 12}{c BT}{hline 8}{c BT}{hline 8}{c BT}{hline 12}{c BT}{hline 12}{c BRC}"
        }
        else {
                di as txt "{hline 13}{c BT}{hline 64}"
        }

        di
        di as txt "Observations  : " as res %9.0gc e(N)        ///
                  as txt "    Panels (N)  : " as res %6.0fc e(N_g)
        di as txt "Time periods T: " as res %9.0fc e(T)        ///
                  as txt "    Regressors  : " as res %6.0fc e(k)
        di as txt "CAs used (g)  : " as res %9.0fc e(g_ca)     ///
                  as txt "    IC select.  : " as res cond(e(ic_used)==1,"yes","no")
        if e(bootstrap) {
                di as txt "Bootstrap reps: " as res %9.0fc e(reps) ///
                  as txt "    CI level    : " as res %6.0fc e(level) "%"
                di as txt "{it:Std. errors and CIs from cross-section bootstrap.}"
        }
        else {
                di as txt "{it:Std. errors from analytical estimators.}"
        }
        di as txt "Cross-section averages: " as res "`e(Fxnames)'"
        di
end


// =================================================================
// MATA: core estimation engine
// =================================================================
version 15.1
mata:
mata clear
mata set matastrict off

// -----------------------------------------------------------------
// Moore-Penrose pseudo-inverse via SVD (rank-robust, paper eq. 1.13)
// -----------------------------------------------------------------
real matrix _xt_pinv(real matrix A)
{
        real matrix U, Vt, Sinv
        real colvector s
        real scalar tol, j
        pragma unset U
        pragma unset Vt
        pragma unset s
        svd(A, U, s, Vt)
        if (length(s) == 0) return(J(cols(A), rows(A), 0))
        tol = max((rows(A), cols(A))) * max(s) * epsilon(1)
        Sinv = J(cols(Vt), rows(U), 0)
        for (j=1; j<=length(s); j++) {
                if (s[j] > tol) Sinv[j,j] = 1/s[j]
        }
        return(Vt' * Sinv * U')
}

// -----------------------------------------------------------------
// Cross-section averages: T x p matrix from NT data
// -----------------------------------------------------------------
real matrix _xt_build_ca(real matrix data, real colvector tvec)
{
        real colvector uT
        real scalar Tn, p, j
        real matrix out
        uT = uniqrows(tvec)
        Tn = rows(uT)
        p  = cols(data)
        out = J(Tn, p, 0)
        for (j=1; j<=Tn; j++) {
                out[j,.] = mean(select(data, tvec :== uT[j]))
        }
        return(out)
}

// -----------------------------------------------------------------
// Rank-robust projector M_F = I - F (F'F)^+ F'
// -----------------------------------------------------------------
real matrix _xt_proj_M(real matrix F)
{
        if (cols(F) == 0) return(I(rows(F)))
        return(I(rows(F)) - F * _xt_pinv(F'F) * F')
}

// -----------------------------------------------------------------
// Q̄_x̌ = (1/N) Σ T^{-1} X_i' M_{F̂_x} X_i
// -----------------------------------------------------------------
real matrix _xt_Qbar(real matrix X, real matrix Fx,
                     real colvector idv, real colvector uniqI, real scalar Tn)
{
        real matrix MF, Xi, Q
        real scalar i, N
        N = rows(uniqI)
        MF = _xt_proj_M(Fx)
        Q  = J(cols(X), cols(X), 0)
        for (i=1; i<=N; i++) {
                Xi = select(X, idv :== uniqI[i])
                if (rows(Xi) == Tn) Q = Q + (Xi' * MF * Xi) / Tn
        }
        return(Q / N)
}

// -----------------------------------------------------------------
// IC selector (paper eq. 3.1):
//   IC(M_x) = log(det(Q̄_x̌)) + g * k * p_NT
// Search over non-empty subsets of size >= k.
// -----------------------------------------------------------------
real rowvector _xt_ic_select(real matrix Yall,
                              real colvector idv, real colvector tvec,
                              real matrix Xstack,
                              real scalar N, real scalar Tn, real scalar k,
                              real scalar incl_ybar, string scalar penalty)
{
        real scalar p_NT, j, i, nsel, best_ic, ic, ngrid, C_NT
        real rowvector cand, bestsel, mask, sel_tmp
        real matrix Qbar
        real colvector uniqI

        if (incl_ybar) cand = 1..cols(Yall)
        else           cand = 2..cols(Yall)

        C_NT = min((sqrt(N), sqrt(Tn)))
        if      (penalty == "log")  p_NT = (N+Tn)/(N*Tn) * log(C_NT^2)
        else if (penalty == "sqrt") p_NT = 1/sqrt(min((N,Tn)))
        else                        p_NT = 1/(N*Tn)

        ngrid = length(cand)
        bestsel = cand
        if (ngrid < k) return(bestsel)

        best_ic = .
        uniqI = uniqrows(idv)
        for (j=1; j < 2^ngrid; j++) {
                mask = J(1, ngrid, 0)
                for (i=1; i<=ngrid; i++) {
                        if (mod(floor(j/(2^(i-1))), 2) == 1) mask[i] = 1
                }
                nsel = sum(mask)
                if (nsel < k) continue
                sel_tmp = select(cand, mask)
                Qbar = _xt_Qbar(Xstack, Yall[., sel_tmp], idv, uniqI, Tn)
                if (det(Qbar) <= 1e-14) continue
                ic = log(det(Qbar)) + nsel * k * p_NT
                if (ic < best_ic) {
                        best_ic = ic
                        bestsel = sel_tmp
                }
        }
        return(bestsel)
}

// -----------------------------------------------------------------
// CCEP estimator core (paper eq. 2.4)
//   returns β̂; also writes per-unit β̂_i to bi
// -----------------------------------------------------------------
real colvector _xt_ccep(real matrix y, real matrix X, real matrix Fx,
                         real colvector idv, real colvector uniqI,
                         real scalar Tn, real matrix bi_out)
{
        real matrix MF, Xi, yi, QQ, AA, Qi
        real scalar i, N, k
        N = rows(uniqI)
        k = cols(X)
        MF = _xt_proj_M(Fx)
        QQ = J(k, k, 0)
        AA = J(k, 1, 0)
        bi_out = J(N, k, .)
        for (i=1; i<=N; i++) {
                Xi = select(X, idv :== uniqI[i])
                yi = select(y, idv :== uniqI[i])
                if (rows(Xi) != Tn) continue
                Qi = Xi' * MF * Xi
                QQ = QQ + Qi
                AA = AA + Xi' * MF * yi
                bi_out[i,.] = (_xt_pinv(Qi) * (Xi' * MF * yi))'
        }
        return(_xt_pinv(QQ) * AA)
}

// -----------------------------------------------------------------
// Analytical variance (paper eq. 2.6 / 2.7)
// -----------------------------------------------------------------
real matrix _xt_var(real matrix y, real matrix X, real matrix Fx,
                     real colvector idv, real colvector uniqI,
                     real scalar Tn, string scalar est, real colvector b)
{
        real matrix MF, Xi, yi, bi, Qbar, Vmat, di, Qi, Sandwich, Qinv
        real colvector bMG
        real scalar i, N, k
        N  = rows(uniqI)
        k  = cols(X)
        MF = _xt_proj_M(Fx)
        bi = J(N, k, .)
        Qbar = J(k, k, 0)
        for (i=1; i<=N; i++) {
                Xi = select(X, idv :== uniqI[i])
                yi = select(y, idv :== uniqI[i])
                if (rows(Xi) != Tn) continue
                Qi   = Xi' * MF * Xi
                Qbar = Qbar + Qi/Tn
                bi[i,.] = (_xt_pinv(Qi) * (Xi' * MF * yi))'
        }
        Qbar = Qbar / N
        bMG  = mean(bi)'
        Vmat = J(k, k, 0)
        if (est == "ccemg") {
                for (i=1; i<=N; i++) {
                        di   = bi[i,.]' - bMG
                        Vmat = Vmat + di * di'
                }
                Vmat = Vmat / (N*(N-1))
        }
        else {
                Qinv = _xt_pinv(Qbar)
                Sandwich = J(k, k, 0)
                for (i=1; i<=N; i++) {
                        Xi = select(X, idv :== uniqI[i])
                        if (rows(Xi) != Tn) continue
                        Qi = (Xi' * MF * Xi)/Tn
                        di = bi[i,.]' - bMG
                        Sandwich = Sandwich + Qi * di * di' * Qi
                }
                Sandwich = Sandwich / (N*(N-1))
                Vmat = Qinv * Sandwich * Qinv / N
        }
        return(Vmat)
}

// -----------------------------------------------------------------
// CS bootstrap (paper Algorithm 1)
// -----------------------------------------------------------------
real matrix _xt_csboot(real matrix y, real matrix X, real matrix CAdata,
                       real colvector idv, real colvector tvec,
                       real colvector uniqI, real scalar Tn,
                       real scalar B, string scalar est,
                       real rowvector ca_cols, real scalar fixedeffects,
                       real scalar trace_on)
{
        real matrix Bsamp, Yall_star, Fx_b, ystar, Xstar, Wstar, bi_b
        real colvector idv_star, tvec_star, picks_col, sel_i, bstar
        real scalar N, k, b, i, draw, npt
        real rowvector picks

        N = rows(uniqI)
        k = cols(X)
        Bsamp = J(B, k, .)

        for (b=1; b<=B; b++) {
                picks = ceil(runiform(1, N) * N)
                npt   = N * Tn

                ystar     = J(npt, 1, .)
                Xstar     = J(npt, k, .)
                Wstar     = J(npt, cols(CAdata), .)
                idv_star  = J(npt, 1, .)
                tvec_star = J(npt, 1, .)

                for (i=1; i<=N; i++) {
                        draw = picks[i]
                        sel_i = idv :== uniqI[draw]
                        ystar[(i-1)*Tn+1::i*Tn, 1] = select(y, sel_i)
                        Xstar[(i-1)*Tn+1::i*Tn, .] = select(X, sel_i)
                        Wstar[(i-1)*Tn+1::i*Tn, .] = select(CAdata, sel_i)
                        idv_star[(i-1)*Tn+1::i*Tn, 1] = J(Tn, 1, i)
                        tvec_star[(i-1)*Tn+1::i*Tn, 1] = select(tvec, sel_i)
                }
                Yall_star = _xt_build_ca(Wstar, tvec_star)
                Fx_b = Yall_star[., ca_cols]
                if (fixedeffects) Fx_b = (J(Tn, 1, 1), Fx_b)

                bstar = _xt_ccep(ystar, Xstar, Fx_b,
                                 idv_star, uniqrows(idv_star), Tn, bi_b=.)
                if (est == "ccemg") bstar = mean(bi_b)'
                Bsamp[b,.] = bstar'
                if (trace_on) {
                        if (mod(b, max((1, floor(B/10)))) == 0)
                                printf("  bootstrap %g / %g\n", b, B)
                }
        }
        return(Bsamp)
}

// -----------------------------------------------------------------
// Main driver — exposed to ado-file
// -----------------------------------------------------------------
void _xtbestcce_run(string scalar depvar, string scalar xnames,
                    string scalar canames,
                    string scalar idvar,  string scalar tvar,
                    string scalar touse,
                    real scalar incl_ybar, real scalar addconstant,
                    real scalar fixedeffects,
                    string scalar estimator,
                    real scalar doIC, string scalar ic_pen,
                    real scalar doboot, real scalar B,
                    real scalar trace_on,
                    string scalar bname,  string scalar Vname,
                    string scalar Vbname, string scalar bsname,
                    string scalar selname,
                    string scalar Nname,  string scalar Ngname,
                    string scalar Tname,  string scalar kname,
                    string scalar gname,  string scalar caStrLoc)
{
        real matrix X, CA, Yall, Fx, V, Bsamp, Vb, bi
        real colvector y, idv, tvec, uniqI, uniqT, b
        real scalar N, Tn, k, kca, g_used, j, i, addconst_orig
        real rowvector ca_cols, mb, dvec
        string rowvector all_can_names
        string scalar capicked_str

        st_view(y   = ., ., depvar,                touse)
        st_view(X   = ., ., tokens(xnames),        touse)
        st_view(idv = ., ., idvar,                 touse)
        st_view(tvec= ., ., tvar,                  touse)
        st_view(CA  = ., ., tokens(canames),       touse)

        y    = y[.,1]
        X    = X[.,.]
        idv  = idv[.,1]
        tvec = tvec[.,1]
        CA   = CA[.,.]

        uniqI = uniqrows(idv)
        uniqT = uniqrows(tvec)
        N  = rows(uniqI)
        Tn = rows(uniqT)
        k  = cols(X)
        kca = cols(CA)
        addconst_orig = addconstant

        // build T x kca cross-section averages
        Yall = _xt_build_ca(CA, tvec)

        // IC or full
        if (doIC) {
                ca_cols = _xt_ic_select(Yall, idv, tvec, X, N, Tn, k,
                                        incl_ybar, ic_pen)
        }
        else {
                if (incl_ybar) ca_cols = 1..kca
                else           ca_cols = 2..kca
        }
        Fx = Yall[., ca_cols]
        if (fixedeffects) Fx = (J(Tn, 1, 1), Fx)

        if (addconstant) {
                X = X, J(rows(X), 1, 1)
                k = k + 1
        }
        g_used = cols(Fx)

        // ----- estimation
        if (estimator == "ccep") {
                b = _xt_ccep(y, X, Fx, idv, uniqI, Tn, bi=.)
        }
        else {
                _xt_ccep(y, X, Fx, idv, uniqI, Tn, bi=.)
                b = mean(bi)'
        }

        // ----- analytical variance
        V = _xt_var(y, X, Fx, idv, uniqI, Tn, estimator, b)

        // ----- bootstrap (replaces V with bootstrap-percentile-variance if requested)
        Vb    = J(k, k, 0)
        Bsamp = J(B, k, .)
        if (doboot) {
                if (trace_on) printf("  CS bootstrap: B = %g\n", B)
                // Strip constant from X for bootstrap recomputation; constant
                // re-added inside loop by toggling addconstant via the
                // ca_cols mechanism — we keep X as-is (with constant) since
                // M_{1,Fx} = M_Fx for the slope on the constant, but the
                // CCEP routine handles it transparently.
                Bsamp = _xt_csboot(y, X, CA, idv, tvec, uniqI, Tn,
                                   B, estimator, ca_cols, fixedeffects, trace_on)
                mb = mean(Bsamp)
                for (j=1; j<=B; j++) {
                        dvec = Bsamp[j,.] - mb
                        Vb = Vb + dvec' * dvec
                }
                Vb = Vb / (B - 1)
                V  = Vb     // post bootstrap variance as default
        }

        // ----- ship
        st_matrix(bname, b')
        st_matrix(Vname, V)
        if (doboot) {
                st_matrix(Vbname, Vb)
                st_matrix(bsname, Bsamp)
        }
        if (doIC) st_matrix(selname, ca_cols)

        st_numscalar(Nname,  rows(y))
        st_numscalar(Ngname, N)
        st_numscalar(Tname,  Tn)
        st_numscalar(kname,  k - addconst_orig)
        st_numscalar(gname,  g_used)

        all_can_names = tokens(canames)
        capicked_str = ""
        if (fixedeffects) capicked_str = capicked_str + " _cons_bar"
        for (i=1; i<=length(ca_cols); i++) {
                capicked_str = capicked_str + " " + all_can_names[ca_cols[i]] + "_bar"
        }
        st_local(caStrLoc, capicked_str)
}

end
