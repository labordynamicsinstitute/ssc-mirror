*! _aardl_fourier - Fourier frequency selection for aardl
*! Version 2.0.0 - 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Yilanci, Bozoklu & Gorus (2020), eqs. (6)-(8): a single-frequency Fourier
*! term d(t) = g1*sin(2*pi*k*t/T) + g2*cos(2*pi*k*t/T) is added to the
*! conditional ECM and k is chosen over the grid k = [kstep, ..., maxk] by
*! minimum sum of squared residuals of the maximal model.
*!
*! Christopoulos & Leon-Ledesma (2011) and Omay (2015) show that INTEGER
*! frequencies correspond to temporary breaks while FRACTIONAL frequencies
*! correspond to permanent breaks.  This program therefore reports the
*! minimum-SSR frequency separately over the integer grid, over the
*! fractional grid, and over the two combined, so the break type implied by
*! the selected frequency is explicit.  kmode() picks which one is used.

capture program drop _aardl_fourier
program define _aardl_fourier, rclass
    version 17

    syntax varname(ts), XVars(string) ESample(varname) TRendvar(varname) ///
        NOBs(integer) MAXLag(integer) MAXk(real) KSTep(real)             ///
        KMOde(string) [ DETvars(string) REGopts(string) NOGraph          ///
        GRAPHPrefix(string) ]

    local depvar "`varlist'"

    // ---- build the maximal regressor list (fixed across the k grid) -----
    local rmax "`detvars' L.`depvar'"
    foreach xv of local xvars {
        local rmax "`rmax' L.`xv'"
    }
    forvalues j = 1/`maxlag' {
        local rmax "`rmax' L`j'.D.`depvar'"
    }
    foreach xv of local xvars {
        local rmax "`rmax' D.`xv'"
        forvalues j = 1/`maxlag' {
            local rmax "`rmax' L`j'.D.`xv'"
        }
    }

    local nk = floor(`maxk'/`kstep' + 1e-8)
    if `nk' < 1 {
        di as err "maxk() must be at least as large as kstep()"
        exit 198
    }

    tempname G
    mat `G' = J(`nk', 3, .)          // k , SSR , 1 if integer

    local best_all  = .
    local best_int  = .
    local best_frac = .
    local k_all  = 0
    local k_int  = 0
    local k_frac = 0

    capture drop _aardl_sin
    capture drop _aardl_cos
    qui gen double _aardl_sin = .
    qui gen double _aardl_cos = .
    label var _aardl_sin "Fourier sin(2*pi*k*t/T)"
    label var _aardl_cos "Fourier cos(2*pi*k*t/T)"

    forvalues i = 1/`nk' {
        local kv = `i' * `kstep'
        local isint = (abs(`kv' - round(`kv')) < 1e-8)

        qui replace _aardl_sin = sin(2*c(pi)*`kv'*`trendvar'/`nobs')
        qui replace _aardl_cos = cos(2*c(pi)*`kv'*`trendvar'/`nobs')

        capture qui regress D.`depvar' `rmax' _aardl_sin _aardl_cos ///
            if `esample', `regopts'
        if _rc {
            mat `G'[`i',1] = `kv'
            mat `G'[`i',3] = `isint'
            continue
        }
        local ssr = e(rss)
        mat `G'[`i',1] = `kv'
        mat `G'[`i',2] = `ssr'
        mat `G'[`i',3] = `isint'

        if `ssr' < `best_all' {
            local best_all = `ssr'
            local k_all    = `kv'
        }
        if `isint' & `ssr' < `best_int' {
            local best_int = `ssr'
            local k_int    = `kv'
        }
        if !`isint' & `ssr' < `best_frac' {
            local best_frac = `ssr'
            local k_frac    = `kv'
        }
    }

    // ---- which frequency is actually used -------------------------------
    if "`kmode'" == "integer" {
        local kuse   = `k_int'
        local ssruse = `best_int'
    }
    else if "`kmode'" == "fractional" {
        local kuse   = `k_frac'
        local ssruse = `best_frac'
    }
    else {
        local kuse   = `k_all'
        local ssruse = `best_all'
    }
    if `kuse' == 0 | missing(`kuse') {
        di as err "no Fourier frequency could be selected; check maxk(), kstep() and the sample"
        exit 498
    }

    // ---- write the selected frequency into the data ---------------------
    qui replace _aardl_sin = sin(2*c(pi)*`kuse'*`trendvar'/`nobs')
    qui replace _aardl_cos = cos(2*c(pi)*`kuse'*`trendvar'/`nobs')

    // ---- report ----------------------------------------------------------
    local btype_all  = cond(abs(`k_all'  - round(`k_all'))  < 1e-8, "temporary", "permanent")
    local btype_int  "temporary"
    local btype_frac "permanent"

    di as txt ""
    di as txt _col(3) "{bf:Fourier frequency selection} " ///
       as txt "(min SSR over k = " as res %4.2f `kstep' as txt " ... " ///
       as res %4.2f `maxk' as txt ", step " as res %4.2f `kstep' as txt ")"
    di as txt "  {hline 70}"
    di as txt _col(5) "Grid" _col(22) "k*" _col(34) "SSR" _col(50) "Implied break"
    di as txt "  {hline 70}"
    di as txt _col(5) "Integer only" _col(20) as res %6.2f `k_int' ///
       _col(30) %12.6f `best_int' as txt _col(50) "temporary"
    di as txt _col(5) "Fractional only" _col(20) as res %6.2f `k_frac' ///
       _col(30) %12.6f `best_frac' as txt _col(50) "permanent"
    di as txt _col(5) "Combined" _col(20) as res %6.2f `k_all' ///
       _col(30) %12.6f `best_all' as txt _col(50) "`btype_all'"
    di as txt "  {hline 70}"
    di as txt _col(5) "Selected (kmode(" as res "`kmode'" as txt "))" ///
       _col(20) as res %6.2f `kuse' _col(30) %12.6f `ssruse'
    di as txt "  {hline 70}"
    di as txt _col(5) "{it:Integer k implies a temporary break; fractional k a permanent}"
    di as txt _col(5) "{it:break (Christopoulos & Leon-Ledesma 2011; Omay 2015).}"
    di as txt ""

    // ---- graph -----------------------------------------------------------
    if "`nograph'" == "" & `nk' > 1 {
        mat _aardl_kgrid = `G'
        preserve
        capture noisily {
            qui clear
            qui set obs `nk'
            qui gen double kstar   = .
            qui gen double ssr     = .
            qui gen byte   isint   = .
            forvalues i = 1/`nk' {
                qui replace kstar = el(_aardl_kgrid,`i',1) in `i'
                qui replace ssr   = el(_aardl_kgrid,`i',2) in `i'
                qui replace isint = el(_aardl_kgrid,`i',3) in `i'
            }
            qui gen double ssr_int = ssr if isint
            qui gen double ssr_sel = ssr if abs(kstar - `kuse') < `kstep'/2

            twoway (line ssr kstar, lcolor("31 119 180") lwidth(medthick))            ///
                   (scatter ssr_int kstar, mcolor("255 127 14") msymbol(triangle)     ///
                    msize(small))                                                     ///
                   (scatter ssr_sel kstar, mcolor("214 39 40") msymbol(diamond)       ///
                    msize(large)),                                                    ///
                   title("Fourier frequency selection", size(medium))                 ///
                   subtitle("SSR over the k grid {&mdash} Yilanci et al. (2020)", size(small)) ///
                   ytitle("Sum of squared residuals", size(small))                    ///
                   xtitle("Fourier frequency k", size(small))                         ///
                   xline(`kuse', lcolor("214 39 40") lpattern(dash))                  ///
                   legend(order(1 "SSR (all k)" 2 "Integer k (temporary break)"       ///
                                3 "Selected k* = `kuse'") size(vsmall) rows(2))       ///
                   scheme(s2color) name(`graphprefix'kstar, replace)
        }
        restore
        capture mat drop _aardl_kgrid
    }

    return scalar kstar     = `kuse'
    return scalar kint      = `k_int'
    return scalar kfrac     = `k_frac'
    return scalar kall      = `k_all'
    return scalar ssr_star  = `ssruse'
    return scalar ssr_int   = `best_int'
    return scalar ssr_frac  = `best_frac'
    return scalar ssr_all   = `best_all'
    return scalar nk        = `nk'
    return local  ktype     = cond(abs(`kuse'-round(`kuse'))<1e-8, "integer", "fractional")
    return local  breaktype = cond(abs(`kuse'-round(`kuse'))<1e-8, "temporary", "permanent")
    return matrix kgrid     = `G'
end
