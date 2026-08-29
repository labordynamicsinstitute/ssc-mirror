*! aardl_advanced - postestimation advanced analysis after aardl
*! Version 2.0.0 - 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Re-runs the dynamic multipliers and the advanced analysis after aardl,
*! optionally over a different horizon, with different confidence bands, or
*! at a different confidence level.  It reuses the same internal routines as
*! aardl itself, so the numbers are identical to those aardl would have
*! printed with the same settings.
*!
*!   aardl ..., noadvanced nodynmult      // skip them during estimation
*!   aardl_advanced                       // run them afterwards
*!   aardl_advanced, horizon(48) bands(2000)

capture program drop aardl_advanced
program define aardl_advanced, rclass
    version 17

    syntax [, HORizon(integer -1) BANds(integer -1) Level(cilevel) ///
              GRAPHPrefix(string) NODYNmult NOADVanced NOGraph ]

    if "`e(cmd)'" != "aardl" {
        di as err "{bf:aardl_advanced} requires a prior {bf:aardl} estimation"
        exit 301
    }

    // the helper routines work off the underlying regression, so park the
    // aardl results and put them back before returning
    tempname _aasave
    capture estimates store `_aasave'

    // ---- recover the model configuration from e() ------------------------
    local depvar "`e(depvar)'"
    local allx   "`e(allx)'"
    local decn   "`e(decnames)'"
    local plags  = e(p)
    local kstar  = e(kstar)
    local caseval = e(case)
    local coint  "`e(coint_status)'"

    if `horizon' < 1 {
        local horizon = e(horizon)
        if missing(`horizon') | `horizon' < 1 local horizon 24
    }
    if `bands' < 0 local bands 500
    if "`level'" == "" local level = e(level)
    if "`level'" == "" | missing(`level') local level = c(level)

    // per-regressor lag orders
    local qlist ""
    foreach xv of local allx {
        local cn = subinstr("`xv'", ".", "_", .)
        local qq = e(q_`cn')
        if missing(`qq') local qq 0
        local qlist "`qlist' `qq'"
    }

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Postestimation: advanced analysis"
    di as txt _col(5) "{it:`e(title)'}"
    di as txt "{hline 78}"
    if "`coint'" != "cointegrated" {
        di as txt ""
        di as txt _col(5) "{it:Note: the prior estimation did not find cointegration}"
        di as txt _col(5) "{it:(status: `coint'). Long-run quantities below are still}"
        di as txt _col(5) "{it:computed but should be read with that in mind.}"
    }

    // ---- the inference fit is what the multipliers and nlcom need --------
    capture qui estimates restore _aardl_inf
    if _rc {
        capture qui estimates restore _aardl_ols
        if _rc {
            di as err "the underlying fit (_aardl_inf / _aardl_ols) is no longer stored;"
            di as err "re-run {bf:aardl} before {bf:aardl_advanced}"
            exit 301
        }
    }

    if "`nodynmult'" == "" {
        local pairsopt ""
        if "`decn'" != "" local pairsopt "pairs(`decn')"
        capture noisily _aardl_dynmult, depvar(`depvar') shocks(`allx')   ///
            qlist(`qlist') plags(`plags') horizon(`horizon')              ///
            bands(`bands') level(`level') `pairsopt'                      ///
            graphprefix(`graphprefix') `nograph'
    }

    if "`noadvanced'" == "" {
        capture qui estimates restore _aardl_inf
        capture noisily _aardl_advanced, depvar(`depvar') xvars(`allx')   ///
            plags(`plags') horizon(`horizon') kstar(`kstar')              ///
            level(`level') caseval(`caseval') trendvar(_aardl_trend)      ///
            graphprefix(`graphprefix') `nograph'
        if _rc == 0 {
            return scalar halflife = r(halflife)
            return scalar domroot  = r(domroot)
            return local  lreq      "`r(lreq)'"
        }
    }

    // ---- put the aardl estimation results back ---------------------------
    capture estimates restore `_aasave'
    capture estimates drop `_aasave'

    return scalar horizon = `horizon'
    return local  depvar  "`depvar'"
end
