*! qqgcause 1.0.0 16may2026
*! Nonparametric Quantile Granger Causality
*! Balcilar et al. (2016); Jeong, Härdle & Song (2012)
*! Author: Merwan Roudane

program qqgcause, rclass
    version 14
    syntax varlist(min=2 max=2 numeric) [if] [in],   ///
        [ TAU(string)                                 ///
          Bandwidth(real 0)                           ///
          TYPE(string)                                ///
          SAVing(string asis)                         ///
          REPLACE                                     ///
          noPROGress ]

    marksample touse
    tokenize `varlist'
    local y `1'   /* effect */
    local x `2'   /* candidate cause */

    if "`tau'"==""  local tau "0.05(0.05)0.95"
    if "`type'"=="" local type "mean"
    if !inlist("`type'", "mean", "variance") {
        di as err "type() must be {mean} or {variance}"
        exit 198
    }
    local moment = cond("`type'"=="variance", 2, 1)

    numlist "`tau'"
    local tau `r(numlist)'
    local Q : word count `tau'

    qui count if `touse'
    local N = r(N)
    if `N' < 30 {
        di as err "need at least 30 observations"
        exit 2001
    }

    tempname Tau OUT
    mata: st_matrix("`Tau'", strtoreal(tokens(st_local("tau")))')

    if "`progress'"=="" {
        di as txt _n "{hline 62}"
        di as txt "  Nonparametric Quantile Causality Test"
        di as txt "{hline 62}"
        di as txt "  cause   : " as res "`x'"   as txt "  ->  effect : " as res "`y'"
        di as txt "  type    : causality in " as res "`type'"
        di as txt "  n       : " as res "`N'" as txt "    quantiles : " as res "`Q'"
        di as txt "{hline 62}"
    }

    mata: lqqr_qqgcause_run("`y'", "`x'", "`touse'", "`Tau'", `moment', `bandwidth', "`OUT'")

    * Show results table
    di _n as txt "  {bf:tau}       {bf:T-stat}     {bf:p-val}   {bf:sig}"
    di as txt "  {hline 38}"
    mata: lqqr_qqgcause_print("`OUT'")
    di as txt "  {hline 38}"
    di as txt "  note: |T| > 1.645 (10%)  > 1.96 (5%)  > 2.58 (1%)"

    if `"`saving'"' != "" {
        preserve
        drop _all
        mata: (void) st_addvar("double", ("tau","tstat","p"))
        mata: M_GC = st_matrix("`OUT'"); (void) st_addobs(rows(M_GC)); st_store(.,.,M_GC)
        qui gen byte sig5 = abs(tstat) > 1.96
        qui gen byte sig1 = abs(tstat) > 2.58
        if "`replace'"=="replace" save `saving', replace
        else                       save `saving'
        restore
    }

    return matrix tau   = `Tau'
    return matrix stats = `OUT'
    return scalar N     = `N'
    return local  type  "`type'"
    return local  cause "`x'"
    return local  effect "`y'"
end
