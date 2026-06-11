*! qqkrls 1.0.0 16may2026
*! Quantile-on-Quantile Kernel Regularised Least Squares
*! Adebayo, Ozkan & Eweade (2024). J. Cleaner Prod. 440:140832.
*! Requires the `krls` package (Hainmueller & Hazlett, SSC).
*! Author: Merwan Roudane

program qqkrls, rclass
    version 14

    cap which krls
    if _rc {
        di as err "this command requires {bf:krls}; install it first:"
        di as err "    ssc install krls"
        exit 199
    }

    syntax varlist(min=2 max=2 numeric) [if] [in],   ///
        [ TAU(string)                                 ///
          THETA(string)                               ///
          MINobs(integer 20)                          ///
          NBoot(integer 100)                          ///
          Sigma(real 0)                               ///
          Lambda(real 0)                              ///
          SAVing(string asis)                         ///
          REPLACE                                     ///
          noPROGress ]

    marksample touse
    tokenize `varlist'
    local y `1'
    local x `2'

    if "`tau'"==""    local tau   "0.05(0.05)0.95"
    if "`theta'"==""  local theta "0.05(0.05)0.95"

    numlist "`tau'"
    local tau   `r(numlist)'
    numlist "`theta'"
    local theta `r(numlist)'

    local M : word count `tau'
    local L : word count `theta'

    qui count if `touse'
    local N = r(N)
    if `N' < 20 {
        di as err "need >= 20 obs (got `N')"
        exit 2001
    }

    if "`progress'"=="" {
        di as txt _n "{hline 62}"
        di as txt "  QQ-KRLS  (Adebayo, Ozkan & Eweade 2024)"
        di as txt "{hline 62}"
        di as txt "  y = " as res "`y'" as txt "    x = " as res "`x'"
        di as txt "  n = " as res "`N'" as txt ///
           "    Y-quantiles = " as res "`M'" as txt ///
           "    X-quantiles = " as res "`L'"
        di as txt "{hline 62}"
    }

    * Stash tau as a matrix once
    tempname TAU OUT
    mata: st_matrix("`TAU'", strtoreal(tokens(st_local("tau")))')

    * OUT: (M*L) x 7: [tau, theta, coef, se, t, p, n_sub]
    mat `OUT' = J(`=`M'*`L'', 7, .)

    local row = 0
    local thi = 0
    foreach theta_j of local theta {
        local ++thi
        qui _pctile `x' if `touse', p(`=100*`theta_j'')
        local x_thresh = r(r1)
        qui count if `x' <= `x_thresh' & `touse'
        local nsub = r(N)

        if `nsub' < `minobs' {
            if "`progress'"=="" {
                di as txt "  theta = `theta_j'  skipped (n_sub=`nsub' < `minobs')"
            }
            forval i = 1/`M' {
                local ++row
                local tau_i : word `i' of `tau'
                mat `OUT'[`row',1] = `tau_i'
                mat `OUT'[`row',2] = `theta_j'
                mat `OUT'[`row',7] = `nsub'
            }
            continue
        }

        * Fit krls; pointwise derivs land in _qqkD_<xname>
        * NOTE: cannot use krls suppress option -- it nullifies deriv()
        cap drop _qqkD_*
        local sigopt = cond(`sigma'  > 0, "sigma(`sigma')",   "")
        local lamopt = cond(`lambda' > 0, "lambda(`lambda')", "")
        qui krls `y' `x' if `x' <= `x_thresh' & `touse', ///
             deriv(_qqkD) `sigopt' `lamopt'

        * Compute beta(tau) = tau-quantile of pointwise derivs, plus bootstrap SE
        tempname D
        mata: lqqr_qqkrls_step("_qqkD_`x'", st_matrix("`TAU'"), `nboot', "`D'")

        forval i = 1/`M' {
            local ++row
            local tau_i : word `i' of `tau'
            mat `OUT'[`row',1] = `tau_i'
            mat `OUT'[`row',2] = `theta_j'
            mat `OUT'[`row',3] = `D'[`i',2]
            mat `OUT'[`row',4] = `D'[`i',3]
            if `D'[`i',3] > 0 & `D'[`i',3] != . {
                mat `OUT'[`row',5] = `D'[`i',2] / `D'[`i',3]
                mat `OUT'[`row',6] = `D'[`i',4]
            }
            mat `OUT'[`row',7] = `nsub'
        }
        cap drop _qqkD_*

        if "`progress'"=="" {
            di as txt "  theta = `theta_j'  done  (n_sub=" as res "`nsub'" as txt ", " ///
                "pct=" as res `=int(100*`thi'/`L')' "%)"
        }
    }

    if `"`saving'"' != "" {
        preserve
        drop _all
        mata: (void) st_addvar("double", ("tau","theta","coef","se","t","p","n_sub"))
        mata: M_QK = st_matrix("`OUT'"); (void) st_addobs(rows(M_QK)); st_store(.,.,M_QK)
        if "`replace'"=="replace" save `saving', replace
        else                       save `saving'
        restore
    }

    tempname B SE Tst P
    mat `B'   = J(`M', `L', .)
    mat `SE'  = J(`M', `L', .)
    mat `Tst' = J(`M', `L', .)
    mat `P'   = J(`M', `L', .)
    local row = 0
    forval j = 1/`L' {
        forval i = 1/`M' {
            local ++row
            mat `B'[`i',`j']   = `OUT'[`row',3]
            mat `SE'[`i',`j']  = `OUT'[`row',4]
            mat `Tst'[`i',`j'] = `OUT'[`row',5]
            mat `P'[`i',`j']   = `OUT'[`row',6]
        }
    }

    * Summary BEFORE return (return matrix moves the tempname)
    if "`progress'"=="" _qqr_summary_show `OUT'

    return matrix coef = `B'
    return matrix se   = `SE'
    return matrix t    = `Tst'
    return matrix p    = `P'
    return matrix long = `OUT'
    return scalar N    = `N'
    return local depvar "`y'"
    return local indvar "`x'"
end

program _qqr_summary_show
    args mat
    mata: lqqr_qqkrls_summarize(st_local("mat"))
end

