*! tnardllmult version 1.0.0  03jun2026
*! Cumulative dynamic multipliers for tnardll (threshold ARDL).
*!
*! Simulates the response of the level of depvar to a unit permanent change in
*! each regime's partial-sum process x^(s), traced out over the requested
*! horizon.  As h -> infinity each multiplier converges to the long-run
*! coefficient beta^(s) = -theta^(s)/rho.  For S=2 the difference path
*! (regime 1 - regime 2) summarises the asymmetric adjustment.

program define tnardllmult, rclass
    version 17.0

    if "`e(cmd)'" != "tnardll" {
        di as err "tnardllmult only works after tnardll"
        exit 301
    }

    syntax [, Horizon(integer 24) GRAPH noTABle SAVing(string asis) ///
              TITle(string asis) * ]

    if `horizon' < 1 {
        di as err "horizon() must be a positive integer"
        exit 198
    }

    local S = e(S)
    local thrvar "`e(thrvar)'"

    mata: _tnardll_mult(`horizon')

    * column names
    local mnames ""
    forvalues s = 1/`S' {
        local mnames "`mnames' m_r`s'"
    }
    if `S' == 2 {
        matrix colnames __mult = h `mnames' diff
    }
    else {
        matrix colnames __mult = h `mnames'
    }
    return matrix mult = __mult, copy

    * ---------------- table ----------------
    if "`table'" != "notable" {
        di ""
        di as txt "Cumulative dynamic multipliers (level of `e(depvar)'), horizon 0..`horizon'"
        di as txt "Long-run targets beta^(s):"
        matrix lb = e(lr_b)
        forvalues s = 1/`S' {
            di as txt "    regime `s' : " as res %9.4f lb[1,`s']
        }
        local hd "    h"
        forvalues s = 1/`S' {
            local hd "`hd'      regime`s'"
        }
        if `S' == 2 local hd "`hd'      asym1-2"
        di as txt "`hd'"
        di as txt "{hline 70}"
        local nr = rowsof(__mult)
        local nc = colsof(__mult)
        * print a compact subset of horizons
        forvalues r = 1/`nr' {
            local hh = __mult[`r',1]
            local line "`:di %5.0f `hh''"
            forvalues c = 2/`nc' {
                local line "`line'  `:di %10.4f __mult[`r',`c']'"
            }
            * print every horizon up to 12, then every 4th
            if `hh' <= 12 | mod(`hh',4)==0 | `r'==`nr' {
                di as res "`line'"
            }
        }
        di as txt "{hline 70}"
    }

    * ---------------- graph ----------------
    if "`graph'" != "" {
        if `"`title'"' == "" local title `"Cumulative dynamic multipliers: `e(depvar)'"'
        tempname fr
        frame create `fr'
        frame `fr' {
            qui svmat double __mult, names(col)
            local plots ""
            forvalues s = 1/`S' {
                local plots `"`plots' (line m_r`s' h, lwidth(medthick))"'
            }
            local leg ""
            forvalues s = 1/`S' {
                local leg `"`leg' `s' "regime `s'""'
            }
            if `S' == 2 {
                local plots `"`plots' (line diff h, lpattern(dash) lcolor(black))"'
                local leg `"`leg' 3 "asym (1-2)""'
            }
            twoway `plots', ///
                yline(0, lcolor(gs10)) ///
                xtitle("Horizon") ytitle("Cumulative response") ///
                title(`"`title'"') ///
                legend(order(`leg') rows(1) size(small)) ///
                `options'
            if `"`saving'"' != "" {
                graph save `saving', replace
            }
        }
        frame drop `fr'
    }
end

version 17.0
mata:
mata set matastrict off

void _tnardll_mult(real scalar H)
{
    real scalar S, p, q, rho, s, h, j, dyt, xlag, ylag, idx
    real colvector theta, phi, yv, dyv
    real matrix pim, M

    rho   = st_numscalar("e(rho)")
    theta = st_matrix("e(theta)")        // S x 1
    pim   = st_matrix("e(pimat)")        // S x q
    p     = st_numscalar("e(p)")
    q     = st_numscalar("e(q)")
    S     = rows(theta)
    if (p > 1) phi = st_matrix("e(phi)") // (p-1) x 1
    else       phi = J(0,1,.)

    // horizon col + S regimes (+ diff appended in ado for S=2)
    if (S == 2) M = J(H+1, S+2, 0)
    else        M = J(H+1, S+1, 0)

    for (s=1; s<=S; s++) {
        yv  = J(H+1,1,0)
        dyv = J(H+1,1,0)
        for (h=0; h<=H; h++) {
            xlag = (h==0 ? 0 : 1)
            ylag = (h==0 ? 0 : yv[h])
            dyt = rho*ylag + theta[s]*xlag
            for (j=1; j<=p-1; j++) {
                idx = h - j
                if (idx >= 0) dyt = dyt + phi[j]*dyv[idx+1]
            }
            for (j=0; j<=q-1; j++) {
                if (h - j == 0) dyt = dyt + pim[s, j+1]
            }
            dyv[h+1] = dyt
            yv[h+1]  = (h==0 ? dyt : yv[h] + dyt)
            M[h+1, s+1] = yv[h+1]
        }
    }
    for (h=0; h<=H; h++) M[h+1,1] = h
    if (S == 2) M[., S+2] = M[.,2] - M[.,3]
    st_matrix("__mult", M)
}
end
