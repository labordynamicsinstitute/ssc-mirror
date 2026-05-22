*! mixi01_lrcov 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! mixi01_lrcov — Long-run covariance estimation
*! Stata wrapper for Mata functions mixi01_lrcov(), mixi01_onesided(), mixi01_lambda()

program define mixi01_lrcov, rclass sortpreserve
    version 17.0

    /* ── syntax ── */
    syntax varlist(numeric min=1) [if] [in],  ///
        [Kernel(string)                        ///
         Bwidth(real -1)                       ///
         Bmeth(string)                         ///
         Vlag(integer -1)                      ///
         NODisplay                             ///
        ]

    /* ── defaults ── */
    if `"`kernel'"' == "" local kernel "bartlett"
    local kernel = strlower(`"`kernel'"')

    /* Validate kernel */
    if !inlist(`"`kernel'"', "bartlett", "parzen", "qs", "tukey", "tukey-hanning") {
        di as err "kernel() must be one of: bartlett, parzen, qs, tukey"
        exit 198
    }

    if `"`bmeth'"' == "" local bmeth "andrews"
    local bmeth = strlower(`"`bmeth'"')

    /* ── mark sample ── */
    marksample touse
    qui count if `touse'
    local N = r(N)
    if `N' < 10 {
        di as err "insufficient observations (`N')"
        exit 2001
    }

    /* ── count variables ── */
    local nvars : word count `varlist'

    /* ── transfer data to Mata ── */
    tempname mat_Omega mat_Delta mat_Lambda bw_used

    mata: {
        real matrix U, _Omega, _Delta, _Lambda
        real scalar _K, _T
        string scalar _kernel

        /* Load data */
        st_view(U = ., ., tokens(st_local("varlist")), st_local("touse"))

        _T = rows(U)
        _kernel = st_local("kernel")

        /* Bandwidth */
        _K = strtoreal(st_local("bwidth"))
        if (_K <= 0) {
            if (st_local("vlag") != "-1") {
                _K = strtoreal(st_local("vlag"))
            }
            else if (st_local("bmeth") == "andrews") {
                _K = mixi01_bandwidth_andrews(U)
            }
            else {
                /* Newey-West rule of thumb */
                _K = floor(4 * (_T / 100)^(2/9))
                if (_K < 1) _K = 1
            }
        }

        /* Compute matrices */
        _Omega  = mixi01_lrcov(U, _K, _kernel)
        _Delta  = mixi01_onesided(U, _K, _kernel)
        _Lambda = mixi01_lambda(U, _K, _kernel)

        /* Store bandwidth used */
        st_numscalar(st_local("bw_used"), _K)

        /* Return matrices to Stata */
        st_matrix(st_local("mat_Omega"), _Omega)
        st_matrix(st_local("mat_Delta"), _Delta)
        st_matrix(st_local("mat_Lambda"), _Lambda)
    }

    /* ── label matrices ── */
    local matnames ""
    foreach v of local varlist {
        local matnames `"`matnames' `v'"'
    }

    matrix rownames `mat_Omega' = `matnames'
    matrix colnames `mat_Omega' = `matnames'
    matrix rownames `mat_Delta' = `matnames'
    matrix colnames `mat_Delta' = `matnames'
    matrix rownames `mat_Lambda' = `matnames'
    matrix colnames `mat_Lambda' = `matnames'

    /* ── display ── */
    if "`nodisplay'" == "" {
        local bw_val = `bw_used'

        di ""
        di as txt "{hline 68}"
        di as res _col(4) "Long-Run Covariance Estimation" ///
           as txt _col(45) "mixi01 lrcov"
        di as txt "{hline 68}"
        di as txt _col(4) "Kernel      = " as res "`kernel'"
        di as txt _col(4) "Bandwidth   = " as res `bw_val' ///
           as txt _col(40) "Method = " as res "`bmeth'"
        di as txt _col(4) "Obs         = " as res `N' ///
           as txt _col(40) "Vars   = " as res `nvars'
        di as txt "{hline 68}"

        /* ── Omega ── */
        di ""
        di as txt "  {ul:Long-run covariance matrix (Omega)}"
        di ""
        _mixi01_display_matrix `mat_Omega' `nvars'

        /* ── Delta ── */
        di ""
        di as txt "  {ul:One-sided long-run covariance (Delta)}"
        di ""
        _mixi01_display_matrix `mat_Delta' `nvars'

        /* ── Lambda ── */
        di ""
        di as txt "  {ul:Bias correction term (Lambda = Delta - Gamma(0)/2)}"
        di ""
        _mixi01_display_matrix `mat_Lambda' `nvars'

        di as txt "{hline 68}"
        di ""
    }

    /* ── return results ── */
    return matrix Omega  = `mat_Omega'
    return matrix Delta  = `mat_Delta'
    return matrix Lambda = `mat_Lambda'
    return scalar bwidth = `bw_used'
    return scalar N      = `N'
    return local  kernel   "`kernel'"
    return local  bmeth    "`bmeth'"
    return local  varlist  "`varlist'"
end


/* ================================================================== */
/*  Matrix display helper                                              */
/* ================================================================== */
program define _mixi01_display_matrix
    version 17.0
    args matname nvars

    local rnames : rownames `matname'
    local cnames : colnames `matname'

    /* Header row */
    di as txt _col(14) "{c |}" _c
    forvalues j = 1/`nvars' {
        local cn : word `j' of `cnames'
        local cn = abbrev("`cn'", 10)
        di as txt %12s "`cn'" _c
    }
    di ""

    /* Separator */
    di as txt "{hline 13}{c +}" _c
    forvalues j = 1/`nvars' {
        di as txt "{hline 12}" _c
    }
    di ""

    /* Data rows */
    forvalues i = 1/`nvars' {
        local rn : word `i' of `rnames'
        local rn = abbrev("`rn'", 12)
        di as txt %12s "`rn'" " {c |}" _c
        forvalues j = 1/`nvars' {
            local val = `matname'[`i', `j']
            di as res %12.6f `val' _c
        }
        di ""
    }
end
