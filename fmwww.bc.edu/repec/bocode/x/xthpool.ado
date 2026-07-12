*! xthpool 1.0.0  11jul2026
*! Hausman poolability test for cointegrated panels (Westerlund & Hess, 2011)
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Implements the maximum-Hausman poolability test of
*   Westerlund, J. and Hess, W. (2011) "A New Poolability Test for Cointegrated
*   Panels", Journal of Applied Econometrics 26: 56-88. doi:10.1002/jae.1143
*
* Step -> equation map (full derivation in xthpool_methods.sthlp):
*   [A] within (FE) demeaning of y_it, x_it        eq (1),(6); x°=x-mean_i(x)
*   [B] individual & pooled LS estimators          Sec 2.2 (beta_i, beta_pool)
*   [C] PCA of residual matrix ee' -> f_hat,lam,u  Sec 2.2 two-step, eq p.63
*   [D] IC1 factor-number selection                eq IC1(r), Prop 1
*   [E] Newey-West LR covariance of z=(f,u,dx)     Sec 2.2, Bartlett K(j)
*   [F] bias terms U_fvi,U_uvi,U_i; beta_i+,beta_pool+   p.60-61
*   [G] individual Hausman H_i (T^2 form)          p.61, Lemma A.1
*   [H] Hmax, Zmax normalization, Gumbel p-value   Thm 1, Remarks 1-3
*   [I] defactoring on observable g_t              Corollary 1, eq (4),(5)
*   [J] iterative sequential-drop scheme           Sec 3.2, crit = alpha^j pctile

program define xthpool, rclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in] , ///
        [ Factors(integer -1)     ///
          Rmax(integer 5)         ///
          Bandwidth(integer -1)   ///
          DEFACTor(varlist numeric ts) ///
          AConst(real 2)          ///
          Level(cilevel)          ///
          ITERate                 ///
          GRAPH                   ///
          name(string) ]

    // ---- parse dependent / independent variables --------------------------
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    if (`k' < 1) {
        di as error "at least one regressor is required"
        exit 198
    }

    // ---- panel structure --------------------------------------------------
    qui xtset
    if ("`r(panelvar)'" == "") {
        di as error "data are not xtset; use {bf:xtset panelvar timevar} first"
        exit 459
    }
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`tvar'" == "") {
        di as error "a time variable is required; use {bf:xtset panelvar timevar}"
        exit 459
    }

    marksample touse
    markout `touse' `depvar' `indepvars' `defactor'
    qui replace `touse' = 0 if missing(`ivar') | missing(`tvar')

    // ---- require a balanced panel with no gaps ----------------------------
    tempvar nobs Tmin Tmax
    qui bysort `touse' `ivar' (`tvar'): gen long `nobs' = _N if `touse'
    sort `ivar' `tvar'
    qui su `nobs' if `touse', meanonly
    local Tbal = r(max)
    qui su `nobs' if `touse'
    if (r(min) != r(max)) {
        di as error "xthpool requires a balanced panel (each unit the same T, no gaps)"
        exit 459
    }

    local kg : word count `defactor'
    local dofact = ("`defactor'" != "")

    // ---- Newey-West Bartlett HAC bandwidth: default M = floor(4 (T/100)^(2/9))
    //      (the Newey-West rule); a user-supplied bandwidth() overrides it.
    local bw = `bandwidth'
    if (`bw' < 0) local bw = floor(4*(`Tbal'/100)^(2/9))
    if (`bw' < 1) local bw = 1

    // ---- run the engine ----------------------------------------------------
    // sort so that panelsetup blocks line up
    sort `ivar' `tvar'
    local doiter = ("`iterate'" != "")
    tempname RES HI IDV ITR BPLUS
    mata: _xthpool_engine( ///
        "`depvar'", "`indepvars'", "`defactor'", "`ivar'", "`tvar'", "`touse'", ///
        `factors', `rmax', `bw', `dofact', `aconst', `doiter', ///
        "`RES'", "`HI'", "`IDV'", "`ITR'", "`BPLUS'")

    // pull scalars back from the 1 x 9 results matrix
    tempname Hmax Zmax pval Nact Tt kk rr
    scalar `Hmax' = `RES'[1,1]
    scalar `Zmax' = `RES'[1,2]
    scalar `pval' = `RES'[1,3]
    local imax   = `RES'[1,4]
    local Nact   = `RES'[1,5]
    local Tt     = `RES'[1,6]
    local kk     = `RES'[1,7]
    local rr     = `RES'[1,8]
    local bwu    = `RES'[1,9]

    // ------------------------------------------------------------------ table
    di ""
    di as text "Hausman poolability test for cointegrated panels"
    di as text "Westerlund & Hess (2011, J. Appl. Econ.)"
    di as text "{hline 64}"
    di as text "Panel variable : " as result "`ivar'"
    di as text "Time variable  : " as result "`tvar'"
    di as text "Dependent var. : " as result "`depvar'"
    di as text "Regressors     : " as result "`indepvars'"
    if (`dofact') {
        di as text "Defactored on  : " as result "`defactor'"
    }
    di as text "{hline 64}"
    di as text "N (units) = " as result %5.0f `Nact' ///
       as text "   T = " as result %5.0f `Tt' ///
       as text "   m = " as result %2.0f `kk'
    di as text "Common factors r = " as result %2.0f `rr' ///
       as text "   NW bandwidth = " as result %3.0f `bwu' ///
       as text "   a_N = " as result %4.2f `aconst'
    di as text "{hline 64}"
    di as text %-22s "Statistic" _col(24) %12s "Value" _col(40) %12s "p-value"
    di as text "{hline 64}"
    local star ""
    if (`pval' < 0.10) local star "*"
    if (`pval' < 0.05) local star "**"
    if (`pval' < 0.01) local star "***"
    di as text %-22s "H_max" _col(24) as result %12.4f `Hmax' _col(46) " "
    di as text %-22s "Z_max (normalized)" _col(24) as result %12.4f `Zmax'
    di as text %-22s "Gumbel p-value" _col(24) as result %12.4f `pval' ///
       "  " as result "`star'"
    di as text "{hline 64}"
    di as text "H0: the slope is common across all units (poolable panel)"
    di as text "Most extreme unit (argmax H_i): " as result "`ivar' = `imax'"
    di as text "Significance: * 10%, ** 5%, *** 1%. p-value from Gumbel(0,1)."

    // ------------------------------------------------------- iterative scheme
    if ("`iterate'" != "") {
        di ""
        di as text "Iterative (sequential-drop) poolability scheme"
        di as text "{hline 64}"
        di as text %-4s "Step" _col(6) %-12s "Unit" _col(20) %10s "H_max" ///
           _col(32) %10s "Z_max" _col(44) %10s "p (raw)" _col(56) %10s "p (adj)"
        di as text "{hline 64}"
        local nsteps = rowsof(`ITR')
        forvalues s = 1/`nsteps' {
            local u  = `ITR'[`s',1]
            local hm = `ITR'[`s',2]
            local zm = `ITR'[`s',3]
            local pr = `ITR'[`s',4]
            local pa = `ITR'[`s',5]
            di as text %-4.0f `s' _col(6) as result %-12.0g `u' ///
               _col(20) %10.4f `hm' _col(32) %10.4f `zm' ///
               _col(44) %10.4f `pr' _col(56) %10.4f `pa'
        }
        di as text "{hline 64}"
        di as text "p (adj) maintains the overall level across steps"
        di as text "(critical value at step j = upper alpha^j Gumbel percentile)."
        return matrix itertable = `ITR'
    }

    // ------------------------------------------------------------- graph(s)
    if ("`graph'" != "") {
        if ("`name'" == "") local name xthpool
        _xthpool_graph "`HI'" "`IDV'" `Zmax' `Hmax' `aconst' `Nact' `kk' "`name'"
    }

    // --------------------------------------------------------- stored results
    return scalar Hmax  = `Hmax'
    return scalar Zmax  = `Zmax'
    return scalar p     = `pval'
    return scalar N     = `Nact'
    return scalar T     = `Tt'
    return scalar m     = `kk'
    return scalar r     = `rr'
    return scalar bw    = `bwu'
    return scalar aN    = `aconst'
    return scalar imax  = `imax'
    return local  depvar    "`depvar'"
    return local  indepvars "`indepvars'"
    return local  ivar      "`ivar'"
    return local  tvar      "`tvar'"
    return local  cmd       "xthpool"
    return matrix Hi     = `HI'
    return matrix unit   = `IDV'
    return matrix bplus  = `BPLUS'
end

*-------------------------------------------------------------------------------
* Graph helper: sorted individual H_i against the (per-unit) critical level
*-------------------------------------------------------------------------------
program define _xthpool_graph
    args HI IDV Zmax Hmax aN Nn kk nm
    // critical H that would make the maximum reject at 5%:
    // H_crit = a_N * z_.05 + b_N,  z_.05 = -ln(-ln(.95)) = 2.9702
    local zc = -ln(-ln(0.95))
    local bN = invchi2(`kk', 1 - 1/`Nn')
    local hc = `aN'*`zc' + `bN'
    preserve
    clear
    qui svmat double `HI', name(hi)
    qui svmat double `IDV', name(unit)
    qui gen long _ord = _n
    gsort -hi1
    qui gen _rank = _n
    capture {
        twoway (bar hi1 _rank, barwidth(0.7) color(navy%70)) ///
               (function y = `hc', range(_rank) lcolor(cranberry) lpattern(dash)), ///
            graphregion(color(white)) plotregion(color(white)) ///
            ytitle("Individual Hausman statistic H{sub:i}") ///
            xtitle("Units ordered by H{sub:i}") ///
            title("Poolability: individual Hausman statistics", size(medium)) ///
            legend(order(1 "H{sub:i}" 2 "5% rejection threshold") ///
                   rows(1) region(lstyle(none))) ///
            name("`nm'", replace)
    }
    if (_rc) {
        di as text "(graph skipped: `=_rc')"
    }
    restore
end

*-------------------------------------------------------------------------------
* Mata engine
*-------------------------------------------------------------------------------
version 14.0
mata:
mata set matastrict off

// --- Newey-West two-sided long-run covariance of the columns of Z ----------
// returns Delta (=Omega+Lam+Lam') and Lam (one-sided lagged sum) by reference
void _xthp_nw(real matrix Z, real scalar bw, real scalar T,
              real matrix Delta, real matrix Lam)
{
    real scalar Tz, j, kk2
    real matrix Om, A2
    real scalar kf

    Tz  = rows(Z)
    kk2 = cols(Z)
    Om  = (Z' * Z) / T
    Lam = J(kk2, kk2, 0)
    for (j = 1; j <= bw; j++) {
        if (j < Tz) {
            kf = 1 - j/(1 + bw)
            A2 = Z[(1)::(Tz-j), .]' * Z[(1+j)::(Tz), .]
            Lam = Lam + kf * (A2 / T)
        }
    }
    Delta = Om + Lam + Lam'
}

// --- core test on a given set of active columns of the residual matrix ------
// returns rowvector (Hmax, Zmax, praw, imax_pos, na, r_used) and, by ref,
// the full per-unit Hi vector (Hi) and the argmax position (pos)
real rowvector _xthp_core(real matrix ehat, pointer(real matrix) rowvector pXcz,
    pointer(real matrix) rowvector pDx, pointer(real matrix) rowvector pSdxxc,
    pointer(real matrix) rowvector pMinv, real matrix bi, real matrix xcy,
    pointer(real matrix) rowvector pMi,
    real colvector active, real scalar T, real scalar k,
    real scalar bw, real scalar aN, real scalar factors, real scalar rmax,
    real matrix Hi, real matrix Bout)
{
    real scalar na, r, rr, j, i, Vr, ic, best, bN, Hmax, Zmax, praw, Devi
    real matrix ea, A, Vfull, fhat, lam, uhat, uu, fh, lm
    real rowvector Lvals
    real matrix Z, Delta, Lam, Gam, fz, uz, dxi, Dvv, Dvvinv, Dfv, Duv, Dff, Duu
    real matrix Gfv, Guv, Gvv, mid, Ufv, Uuv, Ui, Upool, Mpool, Mpoolinv
    real matrix Bplus
    real colvector lami, biplus, bpool, bpoolplus, diff, xcysum, Devec
    real scalar fidx1, fidx2, uidx, vidx1, vidx2
    real scalar imaxpos
    real colvector idxo

    na = rows(active)
    ea = ehat[., active]                       // T x na  (individual FE resid)

    // ----- principal components (eigen of ea*ea', done once) ---------------
    A = ea * ea'
    symeigensystem(A, Vfull, Lvals)            // Vfull cols = eigenvectors
    // sort columns by eigenvalue descending so [.,1..r] are the r largest
    idxo  = order(Lvals', -1)
    Vfull = Vfull[., idxo]

    // choose number of factors
    if (factors >= 0) {
        r = factors
    }
    else {
        best = .
        r = 0
        for (rr = 0; rr <= rmax; rr++) {
            if (rr == 0) {
                uu = ea
            }
            else {
                fh = sqrt(T) :* Vfull[., (1)::(rr)]
                lm = (1/T) * (fh' * ea)
                uu = ea - fh * lm
            }
            Vr = sum(uu :^ 2) / (na * T)
            ic = log(Vr) + rr * log(na*T/(na+T)) * (na+T)/(na*T)
            if (rr == 0) {
                best = ic
                r = 0
            }
            else {
                if (ic < best) {
                    best = ic
                    r = rr
                }
            }
        }
    }
    if (r > na - 1) r = na - 1
    if (r < 0) r = 0

    if (r > 0) {
        fhat = sqrt(T) :* Vfull[., (1)::(r)]    // T x r
        lam  = (1/T) * (fhat' * ea)             // r x na
        uhat = ea - fhat * lam                  // T x na
    }
    else {
        fhat = J(T, 0, 0)
        lam  = J(0, na, 0)
        uhat = ea
    }

    // block indices in z = ( f(1..r), u(r+1), v(r+2..r+1+k) )
    fidx1 = 1
    fidx2 = r
    uidx  = r + 1
    vidx1 = r + 2
    vidx2 = r + 1 + k

    // ----- pass 1: per-unit bias terms, conditional LR var, unit Dvv --------
    Bplus    = J(na, k, 0)
    Devec    = J(na, 1, 0)
    Upool = J(1, k, 0)
    Mpool = J(k, k, 0)
    xcysum = J(k, 1, 0)

    for (j = 1; j <= na; j++) {
        i   = active[j]
        dxi = *pDx[i]                            // Tz x k  (first-diff of x)
        // align factor/idiosyncratic to t = 2..T
        if (r > 0) {
            fz = fhat[(2)::(T), .]               // Tz x r
        }
        else {
            fz = J(T-1, 0, 0)
        }
        uz = uhat[(2)::(T), j]                    // Tz x 1
        Z  = (fz, uz, dxi)                        // Tz x (r+1+k)

        _xthp_nw(Z, bw, T, Delta, Lam)

        // one-sided long-run covariance Gamma = Omega + Lambda = Delta - Lambda'
        // (the correction terms in Westerlund-Hess are one-sided; the driftless
        //  limit on p.79 forces contemporaneous + lagged, not lagged alone)
        Gam    = Delta - Lam'

        Dvv    = Delta[(vidx1)::(vidx2), (vidx1)::(vidx2)]   // two-sided, for scaling
        Dvvinv = invsym(Dvv)
        Duu    = Delta[uidx, uidx]
        Duv    = Delta[uidx, (vidx1)::(vidx2)]    // 1 x k
        Gvv    = Gam[(vidx1)::(vidx2), (vidx1)::(vidx2)]     // one-sided
        Guv    = Gam[uidx, (vidx1)::(vidx2)]      // 1 x k

        mid = (*pSdxxc[i]) - T * Gvv              // k x k

        // idiosyncratic bias piece (always present)
        Uuv = Duv * Dvvinv * mid + T * Guv        // 1 x k
        Ui  = Uuv

        // conditional LR variance of e given v (uses two-sided Delta)
        Devi = Duu - Duv * Dvvinv * Duv'          // scalar (u.v part)

        if (r > 0) {
            Dfv = Delta[(fidx1)::(fidx2), (vidx1)::(vidx2)]   // r x k
            Dff = Delta[(fidx1)::(fidx2), (fidx1)::(fidx2)]   // r x r
            Gfv = Gam[(fidx1)::(fidx2), (vidx1)::(vidx2)]     // r x k, one-sided
            Ufv = Dfv * Dvvinv * mid + T * Gfv               // r x k
            lami = lam[., j]                                  // r x 1
            Ui   = lami' * Ufv + Uuv                          // 1 x k
            // conditional var adds factor part
            Devi = lami' * (Dff - Dfv*Dvvinv*Dfv') * lami + Devi
        }

        biplus = (bi[i, .])' - (Ui * (*pMinv[i]))'           // k x 1
        Bplus[j, .]    = biplus'
        Devec[j]       = Devi

        Upool  = Upool + Ui
        Mpool  = Mpool + (*pMi[i])
        xcysum = xcysum + xcy[., i]
    }

    // ----- pooled bias-adjusted estimator ----------------------------------
    Mpoolinv  = invsym(Mpool)
    bpool     = Mpoolinv * xcysum                 // k x 1
    bpoolplus = bpool' - Upool * Mpoolinv          // 1 x k

    // ----- pass 2: individual Hausman statistics ---------------------------
    // Individual Hausman statistic.  Var(beta_i+) = Delta_e.vi * M_i^-1 with the
    // REALIZED information M_i = Sum x° x°' (the paper's 1/6 Delta_vv is only the
    // probability limit of the normalized moment M_i/T^2, E[int B° B°'] = 1/6
    // Delta_vv, used to state the closed-form asymptotic variance -- Theorem 1 /
    // Remark 2 require H_i to be asymptotically chi-square(m)).  Plugging the
    // realized information gives the pivotal cointegration Wald form:
    //     H_i = (beta_i+ - beta_pool+)' M_i (beta_i+ - beta_pool+) / Delta_e.vi
    Hi = J(na, 1, 0)
    for (j = 1; j <= na; j++) {
        i    = active[j]
        diff = (Bplus[j, .] - bpoolplus)'          // k x 1
        Hi[j] = (diff' * (*pMi[i]) * diff) / Devec[j]
    }

    // ----- Hmax, normalization, Gumbel p-value -----------------------------
    Hmax = max(Hi)
    imaxpos = 1
    for (j = 1; j <= na; j++) {
        if (Hi[j] >= Hmax) imaxpos = j
    }
    bN   = invchi2(k, 1 - 1/na)
    Zmax = (Hmax - bN) / aN
    praw = 1 - exp(-exp(-Zmax))

    Bout = Bplus
    return((Hmax, Zmax, praw, imaxpos, na, r))
}

// --- top-level entry -------------------------------------------------------
void _xthpool_engine(string scalar yv, string scalar xv, string scalar gv,
    string scalar idv, string scalar tv, string scalar tousev,
    real scalar factors, real scalar rmax, real scalar bw, real scalar dofact,
    real scalar aN, real scalar iterate,
    string scalar RESn, string scalar HIn, string scalar IDVn,
    string scalar ITRn, string scalar BPLUSn)
{
    real matrix Y, X, G, info, ehat, bi, xcy, Bplus, itout
    real colvector id, tt, idvals, active
    real scalar N, T, k, kg, i, r1, r2, ni, T_i
    real scalar Hmax, Zmax, praw, imaxpos, na, rused, step, uid
    pointer(real matrix) rowvector pXcz, pDx, pSdxxc, pMinv, pMi
    real matrix Yi, Xi, Gi, Xc, xcz, dxi, Mi, Miinv, res, out, Bout
    real colvector yci, meanx, meany, bihat, Hi
    real rowvector cr

    Y  = st_data(., yv, tousev)
    X  = st_data(., xv, tousev)
    id = st_data(., idv, tousev)
    tt = st_data(., tv, tousev)
    k  = cols(X)
    kg = 0
    if (dofact) {
        G  = st_data(., gv, tousev)
        kg = cols(G)
    }

    info   = panelsetup(id, 1)
    N      = rows(info)
    idvals = J(N, 1, .)
    T      = info[1,2] - info[1,1] + 1

    ehat = J(T, N, 0)
    bi   = J(N, k, 0)
    xcy  = J(k, N, 0)
    pXcz   = J(1, N, NULL)
    pDx    = J(1, N, NULL)
    pSdxxc = J(1, N, NULL)
    pMinv  = J(1, N, NULL)
    pMi    = J(1, N, NULL)

    // ---- per-unit setup ([A]-[C] pieces that do not depend on active set) --
    for (i = 1; i <= N; i++) {
        r1 = info[i,1]
        r2 = info[i,2]
        idvals[i] = id[r1]
        Yi = Y[(r1)::(r2), .]
        Xi = X[(r1)::(r2), .]

        // [I] defactoring on observable common factors g_t
        if (dofact) {
            Gi = G[(r1)::(r2), .]
            Xi = Xi - Gi * (invsym(Gi'Gi) * (Gi'Xi))
        }

        // [A] within demeaning
        meany = mean(Yi)
        meanx = mean(Xi)
        yci = Yi :- meany
        Xc  = Xi :- meanx

        // [B] individual within estimator
        Mi    = Xc' * Xc
        Miinv = invsym(Mi)
        bihat = Miinv * (Xc' * yci)               // k x 1
        bi[i, .]  = bihat'
        xcy[., i] = Xc' * yci                       // k x 1

        // [C] individual FE residual (for PCA)
        ehat[., i] = yci - Xc * bihat

        // first difference of the (defactored) regressor, aligned t=2..T
        dxi = Xi[(2)::(T), .] - Xi[(1)::(T-1), .]   // Tz x k
        xcz = Xc[(2)::(T), .]                        // Tz x k (x° for t=2..T)

        // store pointers to FRESH temporaries (":+ 0" forces a distinct copy);
        // &namedvar would alias the reused loop variable -> all units would
        // collapse to the last one (Mata pointer gotcha).
        pMi[i]    = &(Mi :+ 0)
        pMinv[i]  = &(Miinv :+ 0)
        pDx[i]    = &(dxi :+ 0)
        pXcz[i]   = &(xcz :+ 0)
        pSdxxc[i] = &(dxi' * xcz)                    // k x k  Sum dx (x°)'
    }

    // ---- base test on the full panel --------------------------------------
    active = (1::N)
    cr = _xthp_core(ehat, pXcz, pDx, pSdxxc, pMinv, bi, xcy, pMi,
                    active, T, k, bw, aN, factors, rmax, Hi, Bout)
    Hmax = cr[1]; Zmax = cr[2]; praw = cr[3]
    imaxpos = cr[4]; na = cr[5]; rused = cr[6]
    uid = idvals[active[imaxpos]]

    st_matrix(RESn, (Hmax, Zmax, praw, uid, na, T, k, rused, bw))
    st_matrix(HIn, Hi)
    st_matrix(IDVn, idvals[active])
    st_matrix(BPLUSn, (idvals[active], Bout))

    // ---- iterative sequential-drop scheme [J] -----------------------------
    if (iterate) {
        itout = J(0, 5, .)
        active = (1::N)
        step   = 1
        while (rows(active) >= 2) {
            cr = _xthp_core(ehat, pXcz, pDx, pSdxxc, pMinv, bi, xcy, pMi,
                            active, T, k, bw, aN, factors, rmax, Hi, Bout)
            Hmax = cr[1]; Zmax = cr[2]; praw = cr[3]; imaxpos = cr[4]
            uid  = idvals[active[imaxpos]]
            // adjusted p to maintain overall level: p_adj = p_raw^(1/step)
            itout = itout \ (uid, Hmax, Zmax, praw, praw^(1/step))
            // drop the maximizing unit
            active = select(active, (1::rows(active)) :!= imaxpos)
            step = step + 1
        }
        st_matrix(ITRn, itout)
    }
    else {
        st_matrix(ITRn, J(1, 5, 0))
    }
}

end
