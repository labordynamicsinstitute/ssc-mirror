*! _aardl_advanced - advanced post-estimation analytics for aardl
*! Version 2.0.0 - 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Half-life and persistence profile are computed from the FULL autoregressive
*! structure of the estimated conditional ECM,
*!     Dy(h) = a*y(h-1) + sum_j psi(j)*Dy(h-j),
*! simulated forward from a unit shock, rather than from the single-parameter
*! approximation (1+a)^h.  The two coincide only when p = 0.
*!
*! Also reports the dominant root of the AR polynomial (a stability check),
*! the joint significance of the Fourier terms, and the long-run equation
*! with delta-method standard errors.

capture program drop _aardl_advanced
program define _aardl_advanced, rclass
    version 17

    syntax , DEPvar(string) XVars(string) PLags(integer) HORizon(integer) ///
        [ KSTar(real 0) Level(cilevel) CASEval(integer 3) TRendvar(string) ///
          NOGraph GRAPHPrefix(string) ]

    if "`level'" == "" local level 95

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 6: Advanced analysis"
    di as txt "{hline 78}"

    tempname bb
    mat `bb' = e(b)
    local alpha = _b[L.`depvar']

    // ---- collect the psi coefficients ------------------------------------
    tempname PSI
    mat `PSI' = J(1, max(`plags',1), 0)
    forvalues j = 1/`plags' {
        capture local pj = _b[L`j'.D.`depvar']
        if _rc local pj = 0
        mat `PSI'[1,`j'] = `pj'
    }

    mata: _aardl_pp(`alpha', "`PSI'", `plags', `horizon')
    tempname PP
    mat `PP' = r(pppath)
    local halflife  = r(halflife)
    local domroot   = r(domroot)
    local stableflg = r(stable)

    // ---- half-life --------------------------------------------------------
    di as txt ""
    di as txt _col(3) "{bf:Speed of adjustment and half-life}"
    di as txt "  {hline 62}"
    di as txt _col(5) "ECM coefficient (alpha)" _col(38) as res %12.6f `alpha'
    if `alpha' < 0 & `alpha' > -2 {
        di as txt _col(5) "Half-life, full ECM dynamics" _col(38) as res %12.4f `halflife'
        if `alpha' > -1 {
            di as txt _col(5) "Half-life, -ln(2)/ln(1+alpha)" _col(38) ///
               as res %12.4f (-ln(2)/ln(1+`alpha'))
        }
    }
    else {
        di as txt _col(5) "Half-life" _col(38) as res "not computable (alpha outside (-2,0))"
    }
    di as txt _col(5) "Dominant AR root (modulus)" _col(38) as res %12.6f `domroot'
    if `stableflg' {
        di as txt _col(5) "Dynamic stability" _col(38) as res "stable (all roots < 1)"
    }
    else {
        di as txt _col(5) "Dynamic stability" _col(38) as res "UNSTABLE (a root >= 1)"
    }
    di as txt "  {hline 62}"

    // ---- persistence profile ---------------------------------------------
    di as txt ""
    di as txt _col(3) "{bf:Persistence profile} (response of the EC term to a unit shock)"
    di as txt "  {hline 62}"
    di as txt _col(5) "h" _col(22) "Persistence"
    di as txt "  {hline 62}"
    local nrw = `horizon'+1
    local stride = ceil(`nrw'/10)
    if `stride' < 1 local stride 1
    forvalues i = 1/`nrw' {
        if mod(`i'-1,`stride') == 0 | `i' == `nrw' {
            di as txt _col(5) %4.0f el(`PP',`i',1) as res _col(20) %12.6f el(`PP',`i',2)
        }
    }
    di as txt "  {hline 62}"

    if "`nograph'" == "" {
        mat _aardl_pptmp = `PP'
        preserve
        capture noisily {
            qui clear
            qui set obs `nrw'
            qui gen double h  = .
            qui gen double pp = .
            forvalues i = 1/`nrw' {
                qui replace h  = el(_aardl_pptmp,`i',1) in `i'
                qui replace pp = el(_aardl_pptmp,`i',2) in `i'
            }
            qui gen double half = 0.5
            twoway (line pp h, lcolor("44 160 44") lwidth(medthick))              ///
                   (line half h, lcolor(gs8) lpattern(dash) lwidth(thin)),        ///
                   yline(0, lcolor(gs11) lwidth(vthin))                           ///
                   title("Persistence profile", size(medium))                     ///
                   subtitle("Response of the error-correction term to a unit shock", size(small)) ///
                   ytitle("Persistence", size(small)) xtitle("Horizon h", size(small)) ///
                   legend(order(1 "Persistence" 2 "Half-life reference") size(small) rows(1)) ///
                   scheme(s2color) name(`graphprefix'persistence, replace) nodraw
        }
        restore
        capture mat drop _aardl_pptmp
        capture graph display `graphprefix'persistence
    }

    // ---- Fourier joint significance --------------------------------------
    if `kstar' > 0 {
        di as txt ""
        di as txt _col(3) "{bf:Fourier terms: joint significance at k* = `kstar'}"
        di as txt "  {hline 62}"
        capture qui test _aardl_sin _aardl_cos
        if _rc == 0 {
            local fF = r(F)
            local fp = r(p)
            if missing(`fF') local fF = r(chi2)
            di as txt _col(5) "F(sin, cos)" _col(30) as res %12.4f `fF' ///
               as txt "   p = " as res %8.4f `fp'
            if `fp' < 0.05 {
                di as txt _col(5) "The Fourier terms are " as res "jointly significant" ///
                   as txt " {&mdash} smooth breaks matter."
            }
            else {
                di as txt _col(5) "The Fourier terms are " as res "not jointly significant" ///
                   as txt " {&mdash} consider a non-Fourier type()."
            }
            return scalar fourier_F = `fF'
            return scalar fourier_p = `fp'
        }
        di as txt "  {hline 62}"
    }

    // ---- long-run equation with delta-method standard errors -------------
    di as txt ""
    di as txt _col(3) "{bf:Long-run equilibrium relationship}"
    di as txt "  {hline 72}"
    di as txt _col(5) "Variable" _col(24) "LR coef." _col(38) "Std. err." ///
       _col(52) "[`level'% conf. int.]"
    di as txt "  {hline 72}"

    local lrstr ""
    local first 1
    foreach xv of local xvars {
        capture qui nlcom (lr: -_b[L.`xv']/_b[L.`depvar']), level(`level')
        if _rc continue
        tempname rb rV
        mat `rb' = r(b)
        mat `rV' = r(V)
        local co = `rb'[1,1]
        local se = sqrt(`rV'[1,1])
        local tc = invttail(e(df_r), (100-`level')/200)
        di as txt _col(5) "`xv'" _col(20) as res %12.6f `co' ///
           _col(34) %12.6f `se' _col(48) %11.6f (`co'-`tc'*`se') ///
           _col(61) %11.6f (`co'+`tc'*`se')
        if `first' {
            local lrstr "`=string(`co',"%9.4f")'*`xv'"
            local first 0
        }
        else if `co' >= 0 {
            local lrstr "`lrstr' + `=string(`co',"%9.4f")'*`xv'"
        }
        else {
            local lrstr "`lrstr' - `=string(abs(`co'),"%9.4f")'*`xv'"
        }
    }
    if `caseval' == 2 {
        capture qui nlcom (lr: -_b[_cons]/_b[L.`depvar']), level(`level')
        if _rc == 0 {
            tempname rb2 rV2
            mat `rb2' = r(b)
            mat `rV2' = r(V)
            di as txt _col(5) "_cons (restricted)" _col(20) as res %12.6f `rb2'[1,1] ///
               _col(34) %12.6f sqrt(`rV2'[1,1])
        }
    }
    if `caseval' == 4 & "`trendvar'" != "" {
        capture qui nlcom (lr: -_b[`trendvar']/_b[L.`depvar']), level(`level')
        if _rc == 0 {
            tempname rb3 rV3
            mat `rb3' = r(b)
            mat `rV3' = r(V)
            di as txt _col(5) "trend (restricted)" _col(20) as res %12.6f `rb3'[1,1] ///
               _col(34) %12.6f sqrt(`rV3'[1,1])
        }
    }
    di as txt "  {hline 72}"
    di as txt _col(5) "`depvar' = " as res "`lrstr'"
    di as txt ""

    return scalar halflife = `halflife'
    return scalar domroot  = `domroot'
    return scalar stable   = `stableflg'
    return matrix pppath   = `PP'
    return local  lreq     "`lrstr'"
end

// =========================================================================
version 17
mata:
void _aardl_pp(real scalar a, string scalar psin, real scalar p,
               real scalar H)
{
    real rowvector psi, phi
    real colvector y, dy, pp
    real matrix    C, out
    real scalar    h, j, s, hl, dom
    complex colvector ev

    psi = st_matrix(psin)

    // simulate Dy(h) = a*y(h-1) + sum psi(j) Dy(h-j) from a unit shock at h = 0
    y  = J(H+1, 1, 0)
    dy = J(H+1, 1, 0)
    pp = J(H+1, 1, 0)
    y[1]  = 1
    dy[1] = 0
    pp[1] = 1
    for (h=1; h<=H; h++) {
        s = a*y[h]
        for (j=1; j<=p; j++) {
            if (h-j >= 0) s = s + psi[j]*dy[h-j+1]
        }
        dy[h+1] = s
        y[h+1]  = y[h] + s
        pp[h+1] = y[h+1]
    }

    // half-life: first crossing of 0.5, linearly interpolated
    hl = .
    for (h=2; h<=H+1; h++) {
        if (abs(pp[h]) <= 0.5 & hl >= .) {
            if (abs(pp[h-1]) > abs(pp[h])) {
                hl = (h-2) + (abs(pp[h-1]) - 0.5)/(abs(pp[h-1]) - abs(pp[h]))
            }
            else hl = h-1
        }
    }

    // AR polynomial of y in levels: phi(1) = 1 + a + psi(1), etc.
    phi = J(1, p+1, 0)
    phi[1] = 1 + a + (p >= 1 ? psi[1] : 0)
    for (j=2; j<=p; j++)   phi[j] = psi[j] - psi[j-1]
    if (p >= 1) phi[p+1] = -psi[p]
    else        phi = (1+a)

    // companion matrix, dominant modulus
    if (cols(phi) == 1) {
        dom = abs(phi[1])
    }
    else {
        C = phi \ (I(cols(phi)-1), J(cols(phi)-1, 1, 0))
        ev = eigenvalues(C)
        dom = max(abs(ev))
    }

    out = (0::H), pp
    st_matrix("r(pppath)", out)
    st_numscalar("r(halflife)", hl)
    st_numscalar("r(domroot)",  dom)
    st_numscalar("r(stable)",   (dom < 1))
}
end
