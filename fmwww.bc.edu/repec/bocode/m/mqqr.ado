*! mqqr 1.0.0 16may2026
*! Multivariate Quantile-on-Quantile Regression
*! Author: Merwan Roudane

program mqqr, rclass
    version 14
    syntax varlist(min=2 numeric) [if] [in],    ///
        [ TAU(string)                           ///
          THETA(string)                         ///
          PIVot(varname)                        ///
          Bandwidth(real 0)                     ///
          SAVing(string asis)                   ///
          REPLACE                               ///
          noPROGress ]

    marksample touse
    tokenize `varlist'
    local y `1'
    macro shift
    local X `*'

    if "`tau'"==""    local tau   "0.05(0.05)0.95"
    if "`theta'"==""  local theta "0.05(0.05)0.95"

    numlist "`tau'"
    local tau   `r(numlist)'
    numlist "`theta'"
    local theta `r(numlist)'

    local M : word count `tau'
    local L : word count `theta'
    local K : word count `X'

    * Determine pivot column index
    if "`pivot'"=="" {
        local pivot : word 1 of `X'
    }
    local pivot_idx 0
    local i 0
    foreach v of local X {
        local ++i
        if "`v'"=="`pivot'" local pivot_idx `i'
    }
    if `pivot_idx' == 0 {
        di as err "pivot variable `pivot' must be one of the regressors"
        exit 198
    }

    qui count if `touse'
    local N = r(N)
    if `N' < 20 {
        di as err "need at least 20 observations (got `N')"
        exit 2001
    }

    if "`progress'"=="" {
        di as txt _n "{hline 62}"
        di as txt "  Multivariate Quantile-on-Quantile Regression"
        di as txt "{hline 62}"
        di as txt "  y       = " as res "`y'"
        di as txt "  X       = " as res "`X'"
        di as txt "  pivot   = " as res "`pivot'" as txt " (col `pivot_idx')"
        di as txt "  n       = " as res "`N'"
        di as txt "  Y-quant = " as res "`M'" as txt "    X-quant = " as res "`L'"
        di as txt "{hline 62}"
    }

    tempname Tau Theta OUT
    mata: st_matrix("`Tau'",   strtoreal(tokens(st_local("tau")))')
    mata: st_matrix("`Theta'", strtoreal(tokens(st_local("theta")))')

    mata: lqqr_mqqr_run("`y'", "`X'", "`touse'", "`Tau'", "`Theta'", ///
                    `pivot_idx', `bandwidth', "`OUT'")

    * Save long-format dataset with variable names attached
    if `"`saving'"' != "" {
        preserve
        drop _all
        mata: (void) st_addvar("double", ("tau","theta","var_id","coef","se","t","p"))
        mata: M_MQ = st_matrix("`OUT'"); (void) st_addobs(rows(M_MQ)); st_store(.,.,M_MQ)
        qui gen str32 variable = ""
        local i 0
        foreach v of local X {
            local ++i
            qui replace variable = "`v'" if var_id == `i'
        }
        order tau theta variable coef se t p
        drop var_id
        if "`replace'"=="replace" save `saving', replace
        else                       save `saving'
        restore
    }

    * Display summary BEFORE return (return matrix moves the tempname)
    if "`progress'"=="" {
        di as txt _n "  {bf:Per-regressor summary}"
        di as txt "{hline 62}"
        local i 0
        foreach v of local X {
            local ++i
            mata: lqqr_mqqr_var_summary("`OUT'", `i', "`v'")
        }
        di as txt "{hline 62}"
    }

    return scalar N      = `N'
    return local  depvar "`y'"
    return local  indvar "`X'"
    return local  pivot  "`pivot'"
    return matrix tau    = `Tau'
    return matrix theta  = `Theta'
    return matrix coef   = `OUT'
end
