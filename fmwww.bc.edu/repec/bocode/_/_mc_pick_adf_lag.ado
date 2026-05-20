*! _mc_pick_adf_lag v1.0.0  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Information-criterion lag selection for an ADF regression on a single series.
*! ic in {aic, bic, hqic}.  Returns r(plag).

program define _mc_pick_adf_lag, rclass
    version 14.0
    syntax varname [if] [in], MAXLag(integer) IC(string)
    marksample touse
    local ic = lower("`ic'")

    local best   = .
    local best_p = 0

    qui tsset, noquery
    qui sort `r(timevar)'
    forvalues p = 0/`maxlag' {
        tempvar du Lu
        qui gen double `du' = `varlist' - `varlist'[_n-1] if `touse'
        qui gen double `Lu' = `varlist'[_n-1] if `touse'
        local lagdiffs
        forvalues j=1/`p' {
            tempvar dvar_`j'
            qui gen double `dvar_`j'' = `du'[_n-`j'] if `touse'
            local lagdiffs `lagdiffs' `dvar_`j''
        }
        cap qui regress `du' `Lu' `lagdiffs' if `touse', noconstant
        if _rc continue
        local N    = e(N)
        local rss  = e(rss)
        local k    = e(rank)
        if `N' <= 0 | missing(`rss') continue
        local sig2 = `rss'/`N'
        if "`ic'" == "aic"  local crit = log(`sig2') + 2*`k'/`N'
        if "`ic'" == "bic"  local crit = log(`sig2') + log(`N')*`k'/`N'
        if "`ic'" == "hqic" local crit = log(`sig2') + 2*log(log(`N'))*`k'/`N'
        if `crit' < `best' {
            local best = `crit'
            local best_p = `p'
        }
    }
    return scalar plag = `best_p'
end
