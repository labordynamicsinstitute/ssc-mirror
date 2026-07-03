*! wdenoise 1.0.1  02jul2026
*! Haar "a trous" wavelet denoising of time series
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*!
*! Companion command of the wavenardl package. Denoises one or more series
*! with the Haar "a trous" wavelet transform (Murtagh, Starck & Renaud 2004)
*! and the Donoho (1995) universal threshold, as used in
*! Jammazi, Lahiani & Nguyen (2015).

capture program drop wdenoise
program define wdenoise, rclass
    version 17

    syntax varlist(min=1 numeric) [if] [in], ///
        [                                    ///
        GENerate(string)                     /// stub for new variables (default: dn)
        REPLACE                              /// overwrite the original variables
        LEVels(integer 0)                    /// wavelet levels J (0 = floor(log2(N)))
        THReshold(string)                    /// soft or hard (default: soft)
        NOGraph                              ///
        ]

    if "`threshold'" == "" local threshold "soft"
    local threshold = lower("`threshold'")
    if !inlist("`threshold'", "soft", "hard") {
        di as err "threshold() must be {bf:soft} or {bf:hard}"
        exit 198
    }
    if `levels' < 0 {
        di as err "levels() must be >= 0"
        exit 198
    }
    if "`generate'" != "" & "`replace'" != "" {
        di as err "specify either generate() or replace, not both"
        exit 198
    }
    if "`generate'" == "" & "`replace'" == "" local generate "dn"

    local softflag = cond("`threshold'" == "soft", 1, 0)

    marksample touse, novarlist

    // check target names before creating anything
    if "`replace'" == "" {
        foreach v of local varlist {
            capture confirm new variable `generate'_`v'
            if _rc {
                di as err "variable `generate'_`v' already exists"
                exit 110
            }
        }
    }

    di as txt ""
    di as txt "{hline 72}"
    di as res "  Haar a trous Wavelet Denoising (`threshold' threshold)"
    di as txt "{hline 72}"
    di as txt _col(3) "Variable" _col(18) "N" _col(25) "Levels J" _col(36) "sigma(noise)" _col(51) "lambda" _col(62) "SD reduction"
    di as txt "{hline 72}"

    foreach v of local varlist {
        tempvar tv
        qui gen byte `tv' = `touse' & !missing(`v')
        qui count if `tv'
        local nv = r(N)
        if `nv' < 8 {
            di as txt _col(3) "`v'" _col(15) as err "skipped (fewer than 8 observations)"
            continue
        }

        qui sum `v' if `tv'
        local sd_before = r(sd)

        if "`replace'" != "" {
            local outv "`v'"
        }
        else {
            local outv "`generate'_`v'"
            qui gen double `outv' = .
        }

        mata: _wdn_htw("`v'", "`outv'", "`tv'", `levels', `softflag')

        local sig = scalar(__wdn_sigma)
        local lam = scalar(__wdn_lambda)
        local Jl  = scalar(__wdn_J)
        scalar drop __wdn_sigma __wdn_lambda __wdn_J

        qui sum `outv' if `tv'
        local sd_after = r(sd)
        local sd_red = 100 * (1 - `sd_after' / `sd_before')

        di as txt _col(3) "`v'" _col(14) as res %6.0f `nv' _col(25) %6.0f `Jl' ///
            _col(36) %10.4f `sig' _col(49) %10.4f `lam' _col(62) %8.2f `sd_red' "%"

        if "`replace'" == "" {
            label variable `outv' "`v' denoised (HTW, `threshold')"
        }

        return scalar J_`v'      = `Jl'
        return scalar sigma_`v'  = `sig'
        return scalar lambda_`v' = `lam'

        if "`nograph'" == "" & "`replace'" == "" {
            capture {
                tempvar gx
                qui gen `gx' = sum(`tv')
                twoway (line `v' `gx' if `tv', lcolor(gs10) lwidth(thin)) ///
                       (line `outv' `gx' if `tv', lcolor(navy) lwidth(medthick)), ///
                       title("Wavelet Denoising: `v'", size(medium)) ///
                       subtitle("Haar a trous, `threshold' threshold", size(small)) ///
                       ytitle("`v'", size(small)) xtitle("Observation", size(small)) ///
                       legend(order(1 "Original" 2 "Denoised") size(small) rows(1)) ///
                       note("wdenoise (wavenardl package)", size(vsmall)) ///
                       name(wden_`v', replace)
            }
            capture qui graph export "wden_`v'.png", replace width(1200)
        }
    }

    di as txt "{hline 72}"
    di as txt "  sigma estimated by MAD of level-1 details; lambda = sigma*sqrt(2*ln(N))"
    di as txt "  Refs: Donoho (1995); Murtagh, Starck & Renaud (2004);"
    di as txt "        Jammazi, Lahiani & Nguyen (2015)"
    di as txt "{hline 72}"

end


// =============================================================================
// Mata: Haar "a trous" wavelet denoising (standalone copy for wdenoise)
// =============================================================================
capture mata mata drop _wdn_htw()
capture mata mata drop _wdn_med()

mata:

real scalar _wdn_med(real colvector v)
{
    real colvector a
    real scalar n2, m

    a = sort(v, 1)
    n2 = rows(a)
    m = a[floor((n2 + 1) / 2)]
    if (mod(n2, 2) == 0) m = 0.5 * (a[n2/2] + a[n2/2 + 1])
    return(m)
}

void _wdn_htw(string scalar invar, string scalar outvar,
              string scalar tousevar, real scalar Jin, real scalar soft)
{
    real colvector x, sp, sc, dj, thr, dsum
    real matrix D
    real scalar n, Jlev, Jmax, jj, t, tshift, shift, sigma, lambda, medd

    x = st_data(., invar, tousevar)
    n = rows(x)
    if (n < 8) {
        errprintf("wdenoise: too few observations for wavelet denoising\n")
        exit(2001)
    }

    Jmax = floor(ln(n) / ln(2))
    Jlev = Jin
    if (Jlev <= 0) Jlev = Jmax
    if (Jlev > Jmax) Jlev = Jmax

    D = J(n, Jlev, 0)
    sp = x
    shift = 1
    for (jj = 1; jj <= Jlev; jj++) {
        sc = J(n, 1, 0)
        for (t = 1; t <= n; t++) {
            tshift = t - shift
            if (tshift < 1) tshift = 1
            sc[t] = 0.5 * (sp[tshift] + sp[t])
        }
        D[., jj] = sp - sc
        sp = sc
        shift = shift * 2
    }

    dj = D[., 1]
    medd = _wdn_med(dj)
    sigma = _wdn_med(abs(dj :- medd)) / 0.6745
    lambda = sigma * sqrt(2 * ln(n))

    dsum = J(n, 1, 0)
    for (jj = 1; jj <= Jlev; jj++) {
        dj = D[., jj]
        thr = dj :* (abs(dj) :>= lambda)
        if (soft == 1) thr = sign(dj) :* rowmax((abs(dj) :- lambda, J(n, 1, 0)))
        dsum = dsum + thr
    }
    x = sp + dsum

    st_store(., outvar, tousevar, x)
    st_numscalar("__wdn_sigma", sigma)
    st_numscalar("__wdn_lambda", lambda)
    st_numscalar("__wdn_J", Jlev)
}

end
