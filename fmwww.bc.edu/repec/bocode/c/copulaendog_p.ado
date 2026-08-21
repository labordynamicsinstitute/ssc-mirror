*! version 0.1.0  predict after copulaendog
*!
*! The copula terms are endogeneity controls, not part of the causal model, so
*! they never enter the default prediction.  This mirrors predict() and
*! fitted() in the R reference implementation, where the copula terms are
*! likewise excluded.
*!
*!   xb          structural linear prediction mu + P alpha + W beta  (default)
*!   residuals   structural residual xi = y - xb
*!   xba         augmented prediction xb + C gamma   (needs generate() at
*!   resida      augmented residual u = y - xba       estimation time)

program define copulaendog_p, sortpreserve
    version 16.0

    syntax newvarname [if] [in] , [ XB Residuals XBA RESIDA SCores ]

    if "`e(cmd)'" != "copulaendog" {
        di as err "copulaendog_p works only after copulaendog"
        exit 301
    }
    if "`scores'" != "" {
        di as err "score variables are not available after copulaendog"
        exit 198
    }

    local nopt : word count `xb' `residuals' `xba' `resida'
    if `nopt' > 1 {
        di as err "only one statistic may be requested at a time"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist

    tempname b bs
    matrix `b' = e(b)
    local all : colnames `b'
    local cops "`e(copnames)'"

    * which coefficients belong to the structural model
    local structural
    foreach v of local all {
        local hit = 0
        foreach c of local cops {
            if "`v'" == "`c'" local hit = 1
        }
        if !`hit' local structural `structural' `v'
    }

    * the augmented prediction needs the copula terms as variables, which
    * copulaendog only leaves behind when generate() was specified
    if "`xba'" != "" | "`resida'" != "" {
        foreach c of local cops {
            capture confirm numeric variable `c'
            if _rc {
                di as err "the copula term `c' is not in the data."
                di as err "Refit with generate(stub) to keep the copula "  ///
                          "terms, then predict xba."
                exit 111
            }
        }
        local use `all'
    }
    else local use `structural'

    local k : word count `use'
    matrix `bs' = J(1, `k', 0)
    matrix colnames `bs' = `use'
    matrix coleq `bs' = `e(depvar)'
    forvalues i = 1/`k' {
        local v : word `i' of `use'
        matrix `bs'[1, `i'] = _b[`v']
    }

    tempvar xhat
    quietly matrix score double `xhat' = `bs' if `touse'

    if "`xb'" != "" {
        generate double `varlist' = `xhat' if `touse'
        label variable `varlist' "Structural linear prediction"
    }
    else if "`residuals'" != "" {
        generate double `varlist' = `e(depvar)' - `xhat' if `touse'
        label variable `varlist' "Structural residual (xi)"
    }
    else if "`xba'" != "" {
        generate double `varlist' = `xhat' if `touse'
        label variable `varlist' "Augmented linear prediction"
    }
    else {
        generate double `varlist' = `e(depvar)' - `xhat' if `touse'
        label variable `varlist' "Augmented residual (u)"
    }
end
