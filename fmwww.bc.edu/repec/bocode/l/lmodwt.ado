*! lmodwt — Maximal Overlap Discrete Wavelet Transform
*! Version 1.0.0  2026-05-10
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*! Part of the lwavelet package
*!
*! Note: named lmodwt to avoid clash with Stata 18+ built-in "modwt".

program define lmodwt, eclass sortpreserve
    version 11

    syntax varname(ts) [if] [in], [Levels(integer 4) Filter(string) MRA GENerate(string) NODisplay]

    * ── Defaults ──
    if ("`filter'" == "") local filter "la8"
    local filter = lower(trim("`filter'"))

    * ── Sample ──
    marksample touse
    qui count if `touse'
    local N = r(N)

    if (`N' < 8) {
        di as error "Insufficient observations (N=`N'). Need at least 8."
        exit 2001
    }

    * ── Validate filter ──
    local valid_filters "haar d2 d4 d6 d8 d10 d12 d14 d16 d18 d20"
    local valid_filters "`valid_filters' la8 la10 la12 la14 la16 la18 la20"
    local valid_filters "`valid_filters' bl14 bl18 bl20 c6 c12 c18 c24 c30"

    local found 0
    foreach f of local valid_filters {
        if ("`filter'" == "`f'") local found 1
    }
    if (!`found') {
        di as error "Unknown filter: `filter'"
        di as error "Available: `valid_filters'"
        exit 198
    }

    * ── Validate levels ──
    mata: st_local("maxJ", strofreal(_wv_max_level(`N', "`filter'")))
    if (`levels' > `maxJ') {
        di as error "Max levels for N=`N' with `filter' is `maxJ'. Requested `levels'."
        exit 198
    }

    * ── Extract data ──
    tempname xvec
    mata: `xvec' = st_data(., "`varlist'", "`touse'")

    * ── Compute MODWT ──
    tempname result
    mata: `result' = _wv_modwt(`xvec', "`filter'", `levels')

    * ── Wavelet variance per level ──
    tempname wvar_mat
    mata: st_matrix("`wvar_mat'", J(`levels', 1, .))
    forvalues jj = 1/`levels' {
        mata: st_numscalar("__wv_v", mean(`result'.W[`jj', .]' :^ 2))
        matrix `wvar_mat'[`jj', 1] = __wv_v
    }

    * ── Store W matrices ──
    forvalues j = 1/`levels' {
        tempname W`j'_mat
        mata: st_matrix("`W`j'_mat'", `result'.W[`j', .])
    }
    tempname V_mat
    mata: st_matrix("`V_mat'", `result'.V')

    * ── e() returns ──
    ereturn clear
    ereturn local cmd      "lmodwt"
    ereturn local varname  "`varlist'"
    ereturn local filter   "`filter'"
    ereturn scalar N       = `N'
    ereturn scalar J       = `levels'
    ereturn scalar L       = `maxJ'
    ereturn matrix wvar    = `wvar_mat'

    forvalues j = 1/`levels' {
        ereturn matrix W`j' = `W`j'_mat'
    }
    ereturn matrix VJ = `V_mat'

    * ── MRA: Generate detail/smooth variables ──
    if ("`mra'" != "" | "`generate'" != "") {
        if ("`generate'" == "") local generate "_wv"

        tempname mra_result
        mata: `mra_result' = _wv_mra(`xvec', "`filter'", `levels')

        forvalues j = 1/`levels' {
            cap drop `generate'_D`j'
            qui gen double `generate'_D`j' = . if `touse'
            mata: st_store(., "`generate'_D`j'", "`touse'", `mra_result'.D[`j', .]')
            label var `generate'_D`j' "MODWT Detail D`j' (`filter')"
        }

        cap drop `generate'_S`levels'
        qui gen double `generate'_S`levels' = . if `touse'
        mata: st_store(., "`generate'_S`levels'", "`touse'", `mra_result'.S)
        label var `generate'_S`levels' "MODWT Smooth S`levels' (`filter')"

        di as text ""
        di as text "  Generated variables: `generate'_D1 ... `generate'_D`levels' `generate'_S`levels'"
    }

    * ── Display ──
    if ("`nodisplay'" == "") {
        mata: _wv_display_modwt(`result', "`varlist'")
    }

    * ── Clean up Mata ──
    mata: mata drop `xvec' `result'
    cap mata: mata drop `mra_result'
end
