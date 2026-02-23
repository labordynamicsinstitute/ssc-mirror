*! _fbardl_advanced — Advanced Post-Estimation Analysis for FBARDL
*! Version 1.0.0 — 2026-02-21
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fbardl_advanced
program define _fbardl_advanced
    version 17

    syntax, depvar(string) indepvars(string)   ///
            ecmcoef(real) p(integer)            ///
            horizon(integer) best_kstar(real)   ///
            [nofourier]

    local alpha = `ecmcoef'

    // =========================================================================
    // TABLE 6: HALF-LIFE & PERSISTENCE ANALYSIS
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 6: Half-Life & Persistence Profile Analysis"
    di as txt "{hline 78}"
    di as txt ""

    // ECM diagnostics
    di as txt "  {bf:ECM Speed of Adjustment}"
    di as txt "  {hline 55}"
    di as txt _col(5) "ECM coefficient (alpha)" _col(40) as res %12.6f `alpha'

    if `alpha' < 0 & `alpha' > -2 {
        // Half-life
        local halflife = -ln(2) / ln(1 + `alpha')
        di as txt _col(5) "Half-life (periods)" _col(40) as res %12.4f `halflife'

        // Mean adjustment lag
        local mean_adj = -1 / `alpha'
        di as txt _col(5) "Mean adjustment lag" _col(40) as res %12.4f `mean_adj'

        // 90% adjustment time
        local adj90 = -ln(10) / ln(1 + `alpha')
        di as txt _col(5) "90% adjustment time" _col(40) as res %12.4f `adj90'

        // 99% adjustment time
        local adj99 = -ln(100) / ln(1 + `alpha')
        di as txt _col(5) "99% adjustment time" _col(40) as res %12.4f `adj99'
    }
    else if `alpha' >= 0 {
        di as err _col(5) "WARNING: ECM coefficient is non-negative — no stable equilibrium"
        local halflife = .
    }
    else {
        di as err _col(5) "WARNING: ECM coefficient < -2 — explosive dynamics"
        local halflife = .
    }
    di as txt "  {hline 55}"

    // =========================================================================
    // PERSISTENCE PROFILE (Pesaran & Shin, 1996)
    // =========================================================================
    di as txt ""
    di as txt "  {bf:Persistence Profile} (Pesaran & Shin, 1996)"
    di as txt "  {hline 55}"
    di as txt _col(5) "Horizon" _col(20) "Persistence" _col(38) "Cumul. adj."
    di as txt "  {hline 55}"

    if `alpha' < 0 & `alpha' > -2 {
        // Get AR coefficients
        forvalues j = 1/`p' {
            capture local phi_`j' = _b[L`j'.D.`depvar']
            if _rc != 0 local phi_`j' = 0
        }

        mata {
            H = `horizon' + 1
            pp = J(H, 1, 0)
            pp[1] = 1  // h=0: full disequilibrium

            for (h = 1; h < H; h++) {
                val = (1 + `alpha') * pp[h]
                for (j = 2; j <= min((h, `p')); j++) {
                    phi_j = strtoreal(st_local("phi_" + strofreal(j)))
                    val = val + phi_j * pp[h - j + 1]
                }
                pp[h+1] = val
            }

            st_matrix("__fbardl_pp", pp)
        }

        // Find PP half-life
        local pp_halflife = `horizon'
        forvalues h = 0/`horizon' {
            local hidx = `h' + 1
            local ppval = el(__fbardl_pp, `hidx', 1)
            local cum_adj = 1 - `ppval'

            if `h' <= 5 | `h' == 10 | `h' == 15 | `h' == `horizon' {
                di as txt _col(7) %4.0f `h' _col(18) as res %12.6f `ppval' ///
                   _col(36) %12.6f `cum_adj'
            }

            if `ppval' <= 0.5 & `pp_halflife' == `horizon' {
                local pp_halflife = `h'
            }
        }

        di as txt "  {hline 55}"
        di as txt _col(5) "Profile half-life:" _col(30) as res "`pp_halflife' periods"
        di as txt ""

        // =====================================================================
        // PERSISTENCE PROFILE GRAPH (publication quality)
        // =====================================================================
        capture noisily {
            tempfile _pp_data
            qui save `_pp_data', replace

            qui clear
            local HH = `horizon' + 1
            qui set obs `HH'
            qui gen int horizon = _n - 1
            qui gen double persistence = .
            qui gen double halfline = 0.5

            forvalues h = 0/`horizon' {
                local hidx = `h' + 1
                qui replace persistence = el(__fbardl_pp, `hidx', 1) in `hidx'
            }

            twoway (area persistence horizon, color("156 39 176%30") ///
                       lcolor("156 39 176") lwidth(medthick)) ///
                   (line halfline horizon, lcolor("255 152 0") ///
                       lpattern(dash) lwidth(medium)), ///
                   title("{bf:Persistence Profile}", size(medlarge) color("24 54 104")) ///
                   subtitle("Pesaran & Shin (1996) — fraction of disequilibrium remaining", ///
                       size(small) color(gs6)) ///
                   xtitle("Horizon", size(medsmall)) ///
                   ytitle("Persistence (proportion)", size(medsmall)) ///
                   xline(`pp_halflife', lcolor("255 152 0") lpattern(shortdash) lwidth(thin)) ///
                   legend(order(1 "Persistence profile" ///
                       2 "Half-life = `pp_halflife' periods") ///
                       size(small) cols(2) ring(0) pos(1) ///
                       region(fcolor(white%80) lcolor(gs12))) ///
                   graphregion(fcolor(white) lcolor(white)) ///
                   plotregion(fcolor(white) lcolor(gs14)) ///
                   ylabel(0(0.2)1, format(%4.2f) labsize(small) angle(0) grid glcolor(gs14%50)) ///
                   xlabel(0(5)`horizon', labsize(small) grid glcolor(gs14%50)) ///
                   note("Pesaran & Shin (1996)", size(vsmall) color(gs8)) ///
                   scheme(s2color) name(persistence_profile, replace)

            qui graph export "persistence_profile.png", replace width(1400)
            di as txt _col(5) "Graph saved: persistence_profile.png"

            qui use `_pp_data', clear
        }

        capture mat drop __fbardl_pp
    }
    else {
        di as txt _col(5) "(Persistence profile not computed — ECM coefficient invalid)"
    }

    // =========================================================================
    // TABLE 7: FOURIER TERMS JOINT SIGNIFICANCE
    // =========================================================================
    if "`nofourier'" == "" & `best_kstar' > 0 {
        di as txt ""
        di as txt "{hline 78}"
        di as res _col(5) "Table 7: Fourier Terms Joint Significance F-test"
        di as txt "{hline 78}"
        di as txt ""
        di as txt "  H0: lambda_1 = lambda_2 = 0 (no structural break)"
        di as txt "  {hline 55}"

        local F_fourier_p = .
        local F_fourier = .
        local F_fourier_df1 = .
        local F_fourier_df2 = .
        capture {
            qui test _fbardl_sin _fbardl_cos
            local F_fourier = r(F)
            local F_fourier_df1 = r(df)
            local F_fourier_df2 = r(df_r)
            local F_fourier_p = r(p)
        }
        if `F_fourier_p' < . {
            di as txt _col(5) "F-statistic" _col(30) as res %12.4f `F_fourier'
            di as txt _col(5) "d.f. (numerator)" _col(30) as res %12.0f `F_fourier_df1'
            di as txt _col(5) "d.f. (denominator)" _col(30) as res %12.0f `F_fourier_df2'
            di as txt _col(5) "p-value" _col(30) as res %12.4f `F_fourier_p' _c
            _fbardl_stars `F_fourier_p'
        }
        di as txt "  {hline 55}"

        if `F_fourier_p' < . & `F_fourier_p' < 0.05 {
            di as res _col(5) "=> Fourier terms significant: structural breaks detected"
            di as res _col(5) "   FARDL specification preferred over standard ARDL"
        }
        else if `F_fourier_p' < . {
            di as txt _col(5) "=> Fourier terms not significant at 5%"
            di as txt _col(5) "   Consider pure ARDL (option: nofourier)"
        }
        else {
            di as txt _col(5) "(could not compute Fourier significance test)"
        }
        di as txt ""
    }

    // =========================================================================
    // TABLE 8: LONG-RUN EQUILIBRIUM RELATIONSHIP
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 8: Long-Run Equilibrium Relationship"
    di as txt "{hline 78}"
    di as txt ""

    if `alpha' < 0 {
        di as txt "  Estimated long-run equation:"
        di as txt ""
        di as txt _col(5) "`depvar' = " _c

        local first = 1
        foreach xvar of local indepvars {
            capture qui nlcom (LR_`xvar': -_b[L.`xvar'] / _b[L.`depvar'])
            if _rc == 0 {
                mat _lr_b = r(b)
                mat _lr_V = r(V)
                local lr_coef = _lr_b[1,1]
                local lr_se = sqrt(_lr_V[1,1])
                local lr_t = `lr_coef' / `lr_se'

                if `first' == 0 {
                    if `lr_coef' >= 0 {
                        di as txt " + " _c
                    }
                    else {
                        di as txt " " _c
                    }
                }
                di as res %8.4f `lr_coef' as txt "*`xvar'" _c
                local first = 0

                mat drop _lr_b _lr_V
            }
        }
        di as txt ""
        di as txt ""
        di as txt "  {hline 55}"
        di as txt _col(5) "Variable" _col(22) "LR Coef." _col(36) "Std.Err." _col(48) "t-stat"
        di as txt "  {hline 55}"

        foreach xvar of local indepvars {
            capture qui nlcom (LR: -_b[L.`xvar'] / _b[L.`depvar'])
            if _rc == 0 {
                mat _lr_b = r(b)
                mat _lr_V = r(V)
                local lr_c = _lr_b[1,1]
                local lr_s = sqrt(_lr_V[1,1])
                local lr_t = `lr_c' / `lr_s'
                local lr_p = 2 * (1 - normal(abs(`lr_t')))

                di as txt _col(5) "`xvar'" _col(20) as res %10.6f `lr_c' ///
                   _col(34) %10.6f `lr_s' _col(46) %8.4f `lr_t' _c
                _fbardl_stars `lr_p'
                mat drop _lr_b _lr_V
            }
        }
        di as txt "  {hline 55}"
    }
    else {
        di as txt _col(5) "(Long-run equilibrium not computed — no valid ECM)"
    }
    di as txt ""
end
