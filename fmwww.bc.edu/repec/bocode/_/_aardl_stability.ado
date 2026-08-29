*! _aardl_stability - CUSUM and CUSUMSQ parameter-stability tests for aardl
*! Version 2.0.0 - 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Brown, Durbin & Evans (1975, JRSS-B 37, 149-192) recursive-residual tests.
*!
*!   w(t) = (y(t) - x(t)'b(t-1)) / sqrt(1 + x(t)'(X(t-1)'X(t-1))^{-1} x(t))
*!
*!   CUSUM(t)   = sum_{j=k+1}^{t} w(j) / sigma_hat
*!                bands  +/- a*[ sqrt(N-k) + 2*(t-k)/sqrt(N-k) ]
*!                a = 0.850 (10%), 0.948 (5%), 1.143 (1%)  (BDE Table 1)
*!
*!   CUSUMSQ(t) = sum_{j=k+1}^{t} w(j)^2 / sum_{j=k+1}^{N} w(j)^2
*!                bands  (t-k)/(N-k) +/- c0
*!                Durbin (1969) showed the statistic behaves as a
*!                Kolmogorov-Smirnov statistic with m = (N-k)/2 - 1, so
*!                c0 = c(alpha)/(sqrt(m) + 0.12 + 0.11/sqrt(m)) with
*!                c = 1.224 (10%), 1.358 (5%), 1.628 (1%).

capture program drop _aardl_stability
program define _aardl_stability, rclass
    version 17

    syntax varlist(ts fv), DEPvar(string) ESample(varname) TIMevar(varname) ///
        [ CONStant(integer 1) NOGraph GRAPHPrefix(string) ALPHA(real 0.05) ]

    // ---- materialise the design as ordinary variables ------------------
    // (Mata views cannot read time-series operators directly)
    tempvar ylhs
    qui gen double `ylhs' = `depvar' if `esample'

    local Wlist ""
    foreach v of local varlist {
        tempvar c
        qui gen double `c' = `v' if `esample'
        local Wlist "`Wlist' `c'"
    }

    tempname P
    mata: _aardl_recres("`ylhs'", "`Wlist'", "`esample'", "`timevar'", ///
                        `constant', `alpha')

    local nrec = r(nrec)
    if `nrec' < 5 {
        di as txt _col(5) "(too few recursive residuals for CUSUM / CUSUMSQ)"
        exit
    }
    mat `P' = r(path)

    local cs_cross  = r(cs_cross)
    local cs_margin = r(cs_margin)
    local cq_cross  = r(cq_cross)
    local cq_margin = r(cq_margin)
    local pct = round(`alpha'*100)

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 7: Parameter stability {&mdash} CUSUM and CUSUMSQ"
    di as txt _col(5) "{it:Brown, Durbin & Evans (1975); Durbin (1969)}"
    di as txt "{hline 78}"
    di as txt ""
    di as txt "  {hline 72}"
    di as txt _col(5) "Test" _col(20) "Max excess" _col(37) "First crossing" ///
       _col(56) "Verdict (`pct'%)"
    di as txt "  {hline 72}"

    local cs_v = cond(`cs_cross' < ., "UNSTABLE", "STABLE")
    local cq_v = cond(`cq_cross' < ., "UNSTABLE", "STABLE")
    local cs_t = cond(`cs_cross' < ., "`=string(`cs_cross',"%9.0g")'", "none")
    local cq_t = cond(`cq_cross' < ., "`=string(`cq_cross',"%9.0g")'", "none")

    di as txt _col(5) "CUSUM"   _col(20) as res %10.4f `cs_margin' ///
       _col(38) "`cs_t'" _col(56) "`cs_v'"
    di as txt _col(5) "CUSUMSQ" _col(20) as res %10.4f `cq_margin' ///
       _col(38) "`cq_t'" _col(56) "`cq_v'"
    di as txt "  {hline 72}"
    di as txt _col(5) "{it:Max excess = largest amount by which the path leaves its `pct'% band}"
    di as txt _col(5) "{it:(0 = never leaves it).  Recursive residuals: `nrec'.}"
    di as txt ""

    // ---- path table ------------------------------------------------------
    local nrow = rowsof(`P')
    local stride = ceil(`nrow'/12)
    if `stride' < 1 local stride 1

    di as txt _col(5) "{bf:Recursive path} (every `stride' observation)"
    di as txt "  {hline 72}"
    di as txt _col(5) "`timevar'" _col(17) "CUSUM" _col(30) "+/- band" ///
       _col(44) "CUSUMSQ" _col(57) "`pct'% band"
    di as txt "  {hline 72}"
    forvalues i = 1/`nrow' {
        if mod(`i'-1, `stride') == 0 | `i' == `nrow' {
            di as txt _col(5) %8.0g el(`P',`i',1) ///
               as res _col(14) %10.4f el(`P',`i',2) ///
               _col(28) %10.4f el(`P',`i',3) ///
               _col(42) %10.4f el(`P',`i',4) ///
               as txt _col(54) "[" as res %5.3f el(`P',`i',5) as txt "," ///
               as res %5.3f el(`P',`i',6) as txt "]"
        }
    }
    di as txt "  {hline 72}"

    // ---- cross-check against Stata's own test ---------------------------
    capture qui estat sbcusum
    if _rc == 0 {
        capture local sbstat = r(chi2)
        if _rc | missing(`sbstat') capture local sbstat = r(cusum)
        if !missing(`sbstat') {
            di as txt _col(5) "Cross-check {bf:estat sbcusum} (recursive): statistic = " ///
               as res %8.4f `sbstat'
        }
    }
    di as txt ""

    // ---- graphs ----------------------------------------------------------
    if "`nograph'" == "" {
        mat _aardl_path = `P'
        preserve
        capture noisily {
            qui clear
            qui set obs `nrow'
            qui gen double tvar = .
            qui gen double cs   = .
            qui gen double csb  = .
            qui gen double cq   = .
            qui gen double cqlo = .
            qui gen double cqhi = .
            forvalues i = 1/`nrow' {
                qui replace tvar = el(_aardl_path,`i',1) in `i'
                qui replace cs   = el(_aardl_path,`i',2) in `i'
                qui replace csb  = el(_aardl_path,`i',3) in `i'
                qui replace cq   = el(_aardl_path,`i',4) in `i'
                qui replace cqlo = el(_aardl_path,`i',5) in `i'
                qui replace cqhi = el(_aardl_path,`i',6) in `i'
            }
            qui gen double csbn = -csb

            twoway (rarea csb csbn tvar, color("214 39 40*.18") lwidth(none))          ///
                   (line csb  tvar, lcolor("214 39 40") lpattern(dash))                 ///
                   (line csbn tvar, lcolor("214 39 40") lpattern(dash))                 ///
                   (line cs   tvar, lcolor("31 119 180") lwidth(medthick)),             ///
                   yline(0, lcolor(gs11) lwidth(vthin))                                 ///
                   title("CUSUM of recursive residuals", size(medium))                  ///
                   subtitle("Brown, Durbin & Evans (1975), `pct'% bands", size(small))   ///
                   ytitle("CUSUM", size(small)) xtitle("`timevar'", size(small))         ///
                   legend(order(4 "CUSUM" 2 "`pct'% critical bounds") size(small) rows(1)) ///
                   scheme(s2color) name(`graphprefix'cusum, replace) nodraw

            twoway (rarea cqhi cqlo tvar, color("214 39 40*.18") lwidth(none))         ///
                   (line cqhi tvar, lcolor("214 39 40") lpattern(dash))                 ///
                   (line cqlo tvar, lcolor("214 39 40") lpattern(dash))                 ///
                   (line cq   tvar, lcolor("44 160 44") lwidth(medthick)),              ///
                   title("CUSUM of squares of recursive residuals", size(medium))       ///
                   subtitle("Brown, Durbin & Evans (1975), `pct'% bands", size(small))   ///
                   ytitle("CUSUMSQ", size(small)) xtitle("`timevar'", size(small))       ///
                   legend(order(4 "CUSUMSQ" 2 "`pct'% critical bounds") size(small) rows(1)) ///
                   scheme(s2color) name(`graphprefix'cusumsq, replace) nodraw
        }
        restore
        capture mat drop _aardl_path
        capture graph display `graphprefix'cusum
        capture graph display `graphprefix'cusumsq
    }

    return scalar cusum_cross    = `cs_cross'
    return scalar cusumsq_cross  = `cq_cross'
    return scalar cusum_margin   = `cs_margin'
    return scalar cusumsq_margin = `cq_margin'
    return scalar nrec           = `nrec'
    return local  cusum_verdict   "`cs_v'"
    return local  cusumsq_verdict "`cq_v'"
    return matrix path = `P'
end

// =========================================================================
version 17
mata:
void _aardl_recres(string scalar yn, string scalar xn, string scalar tousen,
                   string scalar timen, real scalar cons, real scalar alpha)
{
    real colvector yv, tv, w, cs, cq, band, lo, hi, ww, b, xt
    real matrix    X, XXi, P
    real scalar    N, k, t, denom, e, sig, tot, i
    real scalar    csx, cqx, csfirst, cqfirst, m, c0, aa, nrec

    X  = st_data(., tokens(xn), tousen)
    yv = st_data(., yn,   tousen)
    tv = st_data(., timen, tousen)
    if (cons) X = X, J(rows(X), 1, 1)

    N = rows(X); k = cols(X)
    nrec = N - k
    st_numscalar("r(nrec)", nrec)
    if (nrec < 5) return

    w   = J(nrec, 1, .)
    XXi = invsym(quadcross(X[|1,1 \ k,.|], X[|1,1 \ k,.|]))
    b   = XXi*quadcross(X[|1,1 \ k,.|], yv[|1 \ k|])

    for (t=k+1; t<=N; t++) {
        xt     = X[t,]'
        e      = yv[t] - X[t,]*b
        denom  = 1 + X[t,]*XXi*xt
        w[t-k] = e/sqrt(denom)
        XXi    = XXi - (XXi*xt*X[t,]*XXi)/denom
        b      = b + XXi*xt*e
    }

    ww = select(w, w :< .)
    if (rows(ww) < 5) {
        st_numscalar("r(nrec)", 0)
        return
    }
    nrec = rows(ww)
    sig  = sqrt(quadcross(ww :- mean(ww), ww :- mean(ww))/(nrec-1))
    tot  = quadcross(ww, ww)

    cs   = J(nrec,1,.); cq = J(nrec,1,.)
    band = J(nrec,1,.); lo = J(nrec,1,.); hi = J(nrec,1,.)

    if      (alpha <= 0.011) aa = 1.143
    else if (alpha <= 0.051) aa = 0.948
    else                     aa = 0.850
    m = nrec/2 - 1
    if (m < 1) m = 1
    if      (alpha <= 0.011) c0 = 1.628/(sqrt(m) + 0.12 + 0.11/sqrt(m))
    else if (alpha <= 0.051) c0 = 1.358/(sqrt(m) + 0.12 + 0.11/sqrt(m))
    else                     c0 = 1.224/(sqrt(m) + 0.12 + 0.11/sqrt(m))

    csx = 0; cqx = 0; csfirst = .; cqfirst = .
    for (i=1; i<=nrec; i++) {
        csx = csx + ww[i]
        cqx = cqx + ww[i]^2
        cs[i]   = csx/sig
        cq[i]   = cqx/tot
        band[i] = aa*(sqrt(nrec) + 2*i/sqrt(nrec))
        lo[i]   = i/nrec - c0
        hi[i]   = i/nrec + c0
        if (csfirst >= . & abs(cs[i]) > band[i]) csfirst = tv[k+i]
        if (cqfirst >= . & (cq[i] > hi[i] | cq[i] < lo[i])) cqfirst = tv[k+i]
    }

    st_numscalar("r(cs_cross)",  csfirst)
    st_numscalar("r(cq_cross)",  cqfirst)
    st_numscalar("r(cs_margin)", max((0, colmax(abs(cs) - band))))
    st_numscalar("r(cq_margin)", max((0, colmax(rowmax((cq - hi, lo - cq))))))

    P = tv[|(k+1) \ (k+nrec)|], cs, band, cq, lo, hi
    st_matrix("r(path)", P)
}
end
