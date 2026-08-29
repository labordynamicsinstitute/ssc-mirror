*! _aardl_dynmult - dynamic multipliers for aardl (linear and asymmetric)
*! Version 2.0.0 - 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! The cumulative dynamic multiplier of y with respect to a unit PERMANENT
*! shock to x(m) is obtained by simulating the estimated conditional ECM
*! forward, using ALL of its short-run dynamics (Shin, Yu & Greenwood-Nimmo
*! 2014, sec. 3):
*!
*!   Dy(h) = a*y(h-1) + pi(m)*x(m,h-1)
*!           + sum_j psi(j) Dy(h-j) + sum_j om(m,j) Dx(m,h-j)
*!   y(h)  = y(h-1) + Dy(h)
*!
*! with Dx(m,0) = 1, Dx(m,h) = 0 for h > 0 and all other regressors held at
*! zero.  M(h) = y(h) is the cumulative multiplier; it converges to the
*! long-run coefficient -pi(m)/a.
*!
*! Confidence bands come from a parametric bootstrap: b* ~ N(bhat, Vhat),
*! recomputing the whole path for each draw and taking percentiles.  For a
*! NARDL model the band on M+(h) - M-(h) is the asymmetry band plotted in
*! Shin et al. (2014).

capture program drop _aardl_dynmult
program define _aardl_dynmult, rclass
    version 17

    syntax , DEPvar(string) SHocks(string) QList(string) PLags(integer) ///
        HORizon(integer) [ PAIrs(string) BANds(integer 500)             ///
        Level(cilevel) NOGraph GRAPHPrefix(string) ASYMlabel ]

    if "`level'" == "" local level 95

    tempname bb VV
    mat `bb' = e(b)
    mat `VV' = e(V)
    local nb = colsof(`bb')

    // ---- index of the adjustment coefficient ---------------------------
    local ia = colnumb(`bb', "L.`depvar'")
    if missing(`ia') {
        di as txt _col(5) "(dynamic multipliers unavailable: L.`depvar' not in the model)"
        exit
    }

    // ---- index vector of the psi (lagged Dy) coefficients ---------------
    local ipsi ""
    forvalues j = 1/`plags' {
        local c = colnumb(`bb', "L`j'.D.`depvar'")
        if missing(`c') local c = 0
        local ipsi "`ipsi' `c'"
    }

    local nsh : word count `shocks'
    tempname PATH LOB UPB
    local anyres 0

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 5: Cumulative dynamic multipliers"
    di as txt _col(5) "{it:Shin, Yu & Greenwood-Nimmo (2014) {&mdash} unit permanent shock}"
    di as txt "{hline 78}"

    // =====================================================================
    // one path per shock variable
    // =====================================================================
    local m 0
    foreach sv of local shocks {
        local ++m
        local qm : word `m' of `qlist'
        local ipm = colnumb(`bb', "L.`sv'")
        if missing(`ipm') continue

        local iom ""
        forvalues j = 0/`qm' {
            if `j' == 0 local c = colnumb(`bb', "D.`sv'")
            else        local c = colnumb(`bb', "L`j'.D.`sv'")
            if missing(`c') local c = 0
            local iom "`iom' `c'"
        }

        tempname IDX
        mat `IDX' = (`ia', `ipm')
        foreach c of local ipsi {
            mat `IDX' = `IDX', `c'
        }
        foreach c of local iom {
            mat `IDX' = `IDX', `c'
        }

        mata: _aardl_dm("`bb'", "`VV'", "`IDX'", `plags', `qm', `horizon', ///
                        `bands', `level')

        tempname M`m'
        mat `M`m'' = r(dmpath)     // horizon+1 x 4: h, M(h), lo, hi
        local anyres 1

        local lr = el(`M`m'', `horizon'+1, 2)
        local im = el(`M`m'', 1, 2)

        di as txt ""
        di as txt _col(3) "{bf:Shock variable: `sv'}"
        di as txt _col(5) "Impact multiplier  M(0)  = " as res %12.6f `im'
        di as txt _col(5) "Long-run  -b[L.`sv']/b[L.`depvar'] = " as res %12.6f ///
           (-`bb'[1,`ipm']/`bb'[1,`ia'])
        di as txt "  {hline 62}"
        di as txt _col(5) "h" _col(16) "M(h)" _col(32) "[`level'% conf. interval]"
        di as txt "  {hline 62}"
        local stride = ceil((`horizon'+1)/10)
        if `stride' < 1 local stride 1
        forvalues i = 1/`=`horizon'+1' {
            if mod(`i'-1,`stride') == 0 | `i' == `horizon'+1 {
                di as txt _col(5) %4.0f el(`M`m'',`i',1) ///
                   as res _col(12) %12.6f el(`M`m'',`i',2) ///
                   as txt _col(30) %10.6f el(`M`m'',`i',3) ///
                   _col(44) %10.6f el(`M`m'',`i',4)
            }
        }
        di as txt "  {hline 62}"

        return matrix dm_`m' = `M`m'', copy
        local mname_`m' "`sv'"

        if "`nograph'" == "" {
            _aardl_dmplot, mat(`M`m'') title("Cumulative dynamic multiplier: `sv'") ///
                name(`graphprefix'dm_`m') ytitle("Cumulative effect on `depvar'")
        }
    }

    // =====================================================================
    // asymmetry: pairs of (+, -) partial-sum regressors
    // =====================================================================
    if "`pairs'" != "" {
        di as txt ""
        di as txt "{hline 78}"
        di as res _col(5) "Table 5b: Asymmetric dynamic multipliers"
        di as txt _col(5) "{it:Shin, Yu & Greenwood-Nimmo (2014)}"
        di as txt "{hline 78}"

        local pj 0
        foreach base of local pairs {
            local ++pj
            // locate the (+) and (-) members inside shocks()
            local ip 0
            local inn 0
            local w 0
            foreach sv of local shocks {
                local ++w
                if "`sv'" == "`base'_pos" local ip = `w'
                if "`sv'" == "`base'_neg" local inn = `w'
            }
            if `ip' == 0 | `inn' == 0 continue

            local qp : word `ip'  of `qlist'
            local qn : word `inn' of `qlist'
            local ipp = colnumb(`bb', "L.`base'_pos")
            local ipn = colnumb(`bb', "L.`base'_neg")
            if missing(`ipp') | missing(`ipn') continue

            local iomp ""
            forvalues j = 0/`qp' {
                if `j' == 0 local c = colnumb(`bb', "D.`base'_pos")
                else        local c = colnumb(`bb', "L`j'.D.`base'_pos")
                if missing(`c') local c = 0
                local iomp "`iomp' `c'"
            }
            local iomn ""
            forvalues j = 0/`qn' {
                if `j' == 0 local c = colnumb(`bb', "D.`base'_neg")
                else        local c = colnumb(`bb', "L`j'.D.`base'_neg")
                if missing(`c') local c = 0
                local iomn "`iomn' `c'"
            }

            tempname IP IN
            mat `IP' = (`ia', `ipp')
            mat `IN' = (`ia', `ipn')
            foreach c of local ipsi {
                mat `IP' = `IP', `c'
                mat `IN' = `IN', `c'
            }
            foreach c of local iomp {
                mat `IP' = `IP', `c'
            }
            foreach c of local iomn {
                mat `IN' = `IN', `c'
            }

            mata: _aardl_dmasym("`bb'", "`VV'", "`IP'", "`IN'", `plags', ///
                                `qp', `qn', `horizon', `bands', `level')

            tempname A`pj'
            mat `A`pj'' = r(asympath)   // h, M+, M-, diff, difflo, diffhi
            local nrw = `horizon'+1

            di as txt ""
            di as txt _col(3) "{bf:Decomposed variable: `base'}"
            di as txt _col(5) "LR (+) = " as res %10.6f (-`bb'[1,`ipp']/`bb'[1,`ia']) ///
               as txt "    LR (-) = " as res %10.6f (-`bb'[1,`ipn']/`bb'[1,`ia'])
            di as txt "  {hline 70}"
            di as txt _col(5) "h" _col(14) "M+(h)" _col(28) "M-(h)" ///
               _col(41) "M+ - M-" _col(54) "[`level'% CI]"
            di as txt "  {hline 70}"
            local stride = ceil(`nrw'/10)
            if `stride' < 1 local stride 1
            forvalues i = 1/`nrw' {
                if mod(`i'-1,`stride') == 0 | `i' == `nrw' {
                    di as txt _col(5) %4.0f el(`A`pj'',`i',1) ///
                       as res _col(10) %11.6f el(`A`pj'',`i',2) ///
                       _col(24) %11.6f el(`A`pj'',`i',3) ///
                       _col(38) %11.6f el(`A`pj'',`i',4) ///
                       as txt _col(52) %8.4f el(`A`pj'',`i',5) ///
                       _col(62) %8.4f el(`A`pj'',`i',6)
                }
            }
            di as txt "  {hline 70}"
            local sigasym = ((el(`A`pj'',`nrw',5) > 0) | (el(`A`pj'',`nrw',6) < 0))
            if `sigasym' {
                di as txt _col(5) "Long-horizon asymmetry is " as res ///
                   "significant at the `level'% level " as txt "(CI excludes 0)."
            }
            else {
                di as txt _col(5) "Long-horizon asymmetry is " as res ///
                   "not significant at the `level'% level " as txt "(CI contains 0)."
            }

            return matrix asym_`pj' = `A`pj'', copy

            if "`nograph'" == "" {
                _aardl_asymplot, mat(`A`pj'') base("`base'") ///
                    name(`graphprefix'asym_`pj') level(`level') depvar("`depvar'")
            }
        }
    }

    return scalar nshocks = `nsh'
end

// -------------------------------------------------------------------------
// plot helpers
// -------------------------------------------------------------------------
capture program drop _aardl_dmplot
program define _aardl_dmplot
    version 17
    syntax , MAT(string) TItle(string) NAME(string) [ YTitle(string) ]

    mat _aardl_dmtmp = `mat'
    local nr = rowsof(_aardl_dmtmp)
    preserve
    capture noisily {
        qui clear
        qui set obs `nr'
        qui gen double h  = .
        qui gen double m  = .
        qui gen double lo = .
        qui gen double hi = .
        forvalues i = 1/`nr' {
            qui replace h  = el(_aardl_dmtmp,`i',1) in `i'
            qui replace m  = el(_aardl_dmtmp,`i',2) in `i'
            qui replace lo = el(_aardl_dmtmp,`i',3) in `i'
            qui replace hi = el(_aardl_dmtmp,`i',4) in `i'
        }
        qui gen double lr = m[`nr']
        twoway (rarea hi lo h, color("31 119 180*.20") lwidth(none))          ///
               (line m h, lcolor("31 119 180") lwidth(medthick))              ///
               (line lr h, lcolor("214 39 40") lpattern(dash) lwidth(medium)), ///
               yline(0, lcolor(gs11) lwidth(vthin))                            ///
               title("`title'", size(medium))                                  ///
               subtitle("Unit permanent shock, with confidence band", size(small)) ///
               ytitle("`ytitle'", size(small)) xtitle("Horizon h", size(small))  ///
               legend(order(2 "Cumulative multiplier" 1 "Confidence band"       ///
                            3 "Long-run level") size(small) rows(1))            ///
               scheme(s2color) name(`name', replace) nodraw
    }
    restore
    capture mat drop _aardl_dmtmp
    capture graph display `name'
end

capture program drop _aardl_asymplot
program define _aardl_asymplot
    version 17
    syntax , MAT(string) BASE(string) NAME(string) [ Level(cilevel) DEPvar(string) ]

    mat _aardl_astmp = `mat'
    local nr = rowsof(_aardl_astmp)
    preserve
    capture noisily {
        qui clear
        qui set obs `nr'
        qui gen double h   = .
        qui gen double mp  = .
        qui gen double mn  = .
        qui gen double df  = .
        qui gen double dlo = .
        qui gen double dhi = .
        forvalues i = 1/`nr' {
            qui replace h   = el(_aardl_astmp,`i',1) in `i'
            qui replace mp  = el(_aardl_astmp,`i',2) in `i'
            qui replace mn  = el(_aardl_astmp,`i',3) in `i'
            qui replace df  = el(_aardl_astmp,`i',4) in `i'
            qui replace dlo = el(_aardl_astmp,`i',5) in `i'
            qui replace dhi = el(_aardl_astmp,`i',6) in `i'
        }
        twoway (rarea dhi dlo h, color("128 128 128*.25") lwidth(none))        ///
               (line mp h, lcolor("31 119 180") lwidth(medthick))              ///
               (line mn h, lcolor("214 39 40") lwidth(medthick) lpattern(shortdash)) ///
               (line df h, lcolor("44 160 44") lwidth(medthick) lpattern(longdash)), ///
               yline(0, lcolor(gs11) lwidth(vthin))                            ///
               title("Asymmetric dynamic multipliers: `base'", size(medium))    ///
               subtitle("Shin, Yu & Greenwood-Nimmo (2014)", size(small))       ///
               ytitle("Cumulative effect on `depvar'", size(small))             ///
               xtitle("Horizon h", size(small))                                 ///
               legend(order(2 "M{superscript:+}(h)" 3 "M{superscript:-}(h)"     ///
                            4 "Asymmetry M{superscript:+} - M{superscript:-}"   ///
                            1 "`level'% band on asymmetry") size(vsmall) rows(2)) ///
               scheme(s2color) name(`name', replace) nodraw
    }
    restore
    capture mat drop _aardl_astmp
    capture graph display `name'
end

// =========================================================================
version 17
mata:
// path of the cumulative multiplier for one coefficient draw
// idx = (i_alpha, i_pi, i_psi(1..p), i_om(0..q))
real colvector _aardl_dmpath(real rowvector b, real rowvector idx,
                             real scalar p, real scalar q, real scalar H)
{
    real colvector y, dy, M
    real scalar h, j, a, pim, s, xlag
    real rowvector psi, om

    a   = (idx[1] > 0 ? b[idx[1]] : 0)
    pim = (idx[2] > 0 ? b[idx[2]] : 0)
    psi = J(1, max((p,1)), 0)
    for (j=1; j<=p; j++) psi[j] = (idx[2+j] > 0 ? b[idx[2+j]] : 0)
    om = J(1, q+1, 0)
    for (j=0; j<=q; j++) om[j+1] = (idx[2+p+j+1] > 0 ? b[idx[2+p+j+1]] : 0)

    y  = J(H+1, 1, 0)
    dy = J(H+1, 1, 0)
    M  = J(H+1, 1, 0)

    for (h=0; h<=H; h++) {
        s = 0
        // adjustment on the lagged level of y
        if (h > 0) s = s + a*y[h]
        // long-run pull from the lagged level of x (x jumps to 1 at h = 0)
        xlag = (h >= 1 ? 1 : 0)
        s = s + pim*xlag
        // lagged differences of y
        for (j=1; j<=p; j++) {
            if (h-j >= 0) s = s + psi[j]*dy[h-j+1]
        }
        // current and lagged differences of x (unit impulse at h = 0)
        for (j=0; j<=q; j++) {
            if (h-j == 0) s = s + om[j+1]
        }
        dy[h+1] = s
        y[h+1]  = (h > 0 ? y[h] : 0) + s
        M[h+1]  = y[h+1]
    }
    return(M)
}

real matrix _aardl_draws(real rowvector b, real matrix V, real scalar B)
{
    real matrix L, Z, Vs
    Vs = makesymmetric(V)
    L  = cholesky(Vs)
    if (hasmissing(L) | diag0cnt(L) > 0) {
        Vs = Vs + I(cols(Vs))*1e-12*trace(Vs)/cols(Vs)
        L  = cholesky(Vs)
    }
    if (hasmissing(L)) return(J(0, cols(V), .))
    Z = rnormal(B, cols(V), 0, 1)
    return(J(B,1,1)*b + Z*transposeonly(L))
}

void _aardl_dm(string scalar bn, string scalar vn, string scalar idxn,
               real scalar p, real scalar q, real scalar H,
               real scalar B, real scalar lvl)
{
    real rowvector b, idx
    real matrix V, Db, S, out
    real colvector M, r
    real scalar i, lo, hi

    b   = st_matrix(bn)
    V   = st_matrix(vn)
    idx = st_matrix(idxn)

    M = _aardl_dmpath(b, idx, p, q, H)

    out = ((0::H), M, J(H+1,1,.), J(H+1,1,.))
    if (B > 10) {
        Db = _aardl_draws(b, V, B)
        if (rows(Db) > 0) {
            S = J(H+1, rows(Db), .)
            for (i=1; i<=rows(Db); i++) S[.,i] = _aardl_dmpath(Db[i,], idx, p, q, H)
            lo = max((1, round(rows(Db)*(1-lvl/100)/2)))
            hi = min((rows(Db), round(rows(Db)*(1 - (1-lvl/100)/2))))
            for (i=1; i<=H+1; i++) {
                r = sort(transposeonly(S[i,]), 1)
                out[i,3] = r[lo]
                out[i,4] = r[hi]
            }
        }
    }
    st_matrix("r(dmpath)", out)
}

void _aardl_dmasym(string scalar bn, string scalar vn, string scalar ipn,
                   string scalar inn, real scalar p, real scalar qp,
                   real scalar qn, real scalar H, real scalar B, real scalar lvl)
{
    real rowvector b, ip, inx
    real matrix V, Db, S, out
    real colvector Mp, Mn, r
    real scalar i, lo, hi

    b   = st_matrix(bn)
    V   = st_matrix(vn)
    ip  = st_matrix(ipn)
    inx = st_matrix(inn)

    Mp = _aardl_dmpath(b, ip,  p, qp, H)
    Mn = _aardl_dmpath(b, inx, p, qn, H)

    out = ((0::H), Mp, Mn, Mp - Mn, J(H+1,1,.), J(H+1,1,.))
    if (B > 10) {
        Db = _aardl_draws(b, V, B)
        if (rows(Db) > 0) {
            S = J(H+1, rows(Db), .)
            for (i=1; i<=rows(Db); i++) {
                S[.,i] = _aardl_dmpath(Db[i,], ip, p, qp, H) -
                         _aardl_dmpath(Db[i,], inx, p, qn, H)
            }
            lo = max((1, round(rows(Db)*(1-lvl/100)/2)))
            hi = min((rows(Db), round(rows(Db)*(1 - (1-lvl/100)/2))))
            for (i=1; i<=H+1; i++) {
                r = sort(transposeonly(S[i,]), 1)
                out[i,5] = r[lo]
                out[i,6] = r[hi]
            }
        }
    }
    st_matrix("r(asympath)", out)
}
end
