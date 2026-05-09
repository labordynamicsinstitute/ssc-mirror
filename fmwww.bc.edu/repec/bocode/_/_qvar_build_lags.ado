*! _qvar_build_lags.ado — Build lag matrix for VAR/QVAR
*! Version 1.1.0

program define _qvar_build_lags, rclass
    version 16.0
    syntax varlist(ts), Lags(integer)

    local nvars : word count `varlist'
    local lagvars ""

    foreach var of varlist `varlist' {
        forvalues lag = 1/`lags' {
            local lagname = "`var'_L`lag'"
            capture drop `lagname'
            qui gen double `lagname' = L`lag'.`var'
            local lagvars "`lagvars' `lagname'"
        }
    }

    return local lagvars "`lagvars'"
    return scalar nvars = `nvars'
    return scalar nlags = `lags'
    return scalar nlagvars = `nvars' * `lags'
end
