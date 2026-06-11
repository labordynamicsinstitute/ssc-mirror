*! _qnardl_lagsel v1.1.0  28may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! BIC / AIC / HQIC lag-order selection for QNARDL.
*!
*! Follows the conventions of qardl (Cho/Kim/Shin 2015) and ardl
*! (Kripfganz/Schneider): OLS regression on the URECM is used for the IC search
*! (much faster than re-estimating qreg at each grid point and standard
*! practice — see Bertsatos et al. 2022 §3.3 footnote 23 and Kripfganz/Schneider
*! 2018). The selected (p,q,r) are then used for the per-tau QNARDL estimation.
*!
*! IC formulae (n * log(SSR/n) form, matching ardl and qardl):
*!   BIC  = n * log(SSR/n) + k * log(n)
*!   AIC  = n * log(SSR/n) + 2 * k
*!   HQIC = n * log(SSR/n) + 2 * k * log(log(n))
*!
*! Returns:
*!   r(p), r(q), r(r)         optimal lag orders
*!   r(bic_grid)              full (pmax × qmax) IC grid at r = q
*!   r(ic_value)              IC at the optimum
*!   r(ic_used)               "bic" / "aic" / "hqic"

program define _qnardl_lagsel, rclass
    version 14.0

    syntax , depvar(varname) pos_vars(varlist) neg_vars(varlist) ///
        touse(varname) [ linear_vars(string) exog(string) ///
        trendvar(string) case(integer 3) ///
        pmax(integer 4) qmax(integer 4) rmax(integer 4) ///
        IC(string) DOTs noTable ]

    if "`ic'" == ""        local ic "bic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "bic", "aic", "hqic") {
        di as error "_qnardl_lagsel: ic() must be bic, aic, or hqic"
        exit 198
    }

    local kasym : word count `pos_vars'
    local klin  : word count `linear_vars'

    local has_const = (`case' >= 3)
    local has_trend = inlist(`case', 4, 5, 6, 7, 8, 9, 10, 11)
    local has_quad  = inlist(`case', 8, 9, 10, 11)
    if `has_quad' & "`trendvar'" != "" {
        tempvar t2var
        qui gen double `t2var' = (`trendvar')^2 if `touse'
    }
    local consopt = cond(`has_const', "", "noconstant")

    qui tsrevar D.`depvar'
    local dydepvar `r(varlist)'

    di as txt _n "{hline 78}"
    di as res _col(3) "QNARDL Lag Order Selection (" upper("`ic'") ")"
    di as txt "{hline 78}"

    // Allocate the 2-D IC grid for display.  r is set to q (Bertsatos
    // convention; user can override with -lags()-).
    tempname ic_grid
    matrix `ic_grid' = J(`pmax', `qmax', .)

    local best_ic = .
    local best_p = 1
    local best_q = 1
    local best_r = 1

    forvalues p = 1/`pmax' {
        forvalues q = 1/`qmax' {
            local r = `q'

            // Build URECM
            local urecm "L.`depvar'"
            foreach pv of varlist `pos_vars' {
                local urecm "`urecm' L.`pv'"
            }
            foreach nv of varlist `neg_vars' {
                local urecm "`urecm' L.`nv'"
            }
            if `klin' > 0 {
                foreach lv of varlist `linear_vars' {
                    local urecm "`urecm' L.`lv'"
                }
            }
            if `p' > 1  local urecm "`urecm' L(1/`=`p'-1').D.`depvar'"
            foreach pv of varlist `pos_vars' {
                local urecm "`urecm' L(0/`=`q'-1').D.`pv'"
            }
            foreach nv of varlist `neg_vars' {
                local urecm "`urecm' L(0/`=`q'-1').D.`nv'"
            }
            if `klin' > 0 {
                foreach lv of varlist `linear_vars' {
                    local urecm "`urecm' L(0/`=`r'-1').D.`lv'"
                }
            }
            if "`exog'" != ""                       local urecm "`urecm' `exog'"
            if `has_trend' & "`trendvar'" != ""     local urecm "`urecm' `trendvar'"
            if `has_quad'  & "`trendvar'" != ""     local urecm "`urecm' `t2var'"

            // OLS regression on the URECM (faster than qreg; standard
            // practice for ARDL family IC selection)
            capture qui regress `dydepvar' `urecm' if `touse', `consopt'
            if _rc continue

            local n   = e(N)
            local rss = e(rss)
            local k   = e(rank)        // number of estimated parameters
            if missing(`rss') | `rss' <= 0 continue
            local logRSS = log(`rss' / `n')

            if "`ic'" == "bic"   local ic_v = `n' * `logRSS' + `k' * log(`n')
            if "`ic'" == "aic"   local ic_v = `n' * `logRSS' + 2 * `k'
            if "`ic'" == "hqic"  local ic_v = `n' * `logRSS' + 2 * `k' * log(log(`n'))

            matrix `ic_grid'[`p', `q'] = `ic_v'

            if "`dots'" != "" {
                di as txt _col(3) "(p=`p', q=`q', r=`r')  `ic' = " %10.3f `ic_v' "  n=" `n' "  k=" `k'
            }

            if `ic_v' < `best_ic' {
                local best_ic = `ic_v'
                local best_p = `p'
                local best_q = `q'
                local best_r = `r'
            }
        }
    }

    // Display the IC grid table (qardl style)
    if "`table'" != "notable" {
        di as txt _col(3) "Grid: rows = p (AR lags), columns = q (DL lags); r = q"
        di as txt _col(3) "{hline 72}"

        di as txt _col(3) "{ralign 6:p \ q}" _c
        forvalues j = 1/`qmax' {
            di as txt _col(`=10 + 11*`j'') "{ralign 10:q=`j'}" _c
        }
        di ""
        di as txt _col(3) "{hline 72}"

        forvalues i = 1/`pmax' {
            di as txt _col(3) "{ralign 6:p=`i'}" _c
            forvalues j = 1/`qmax' {
                local v = `ic_grid'[`i', `j']
                if `i' == `best_p' & `j' == `best_q' {
                    di as res _col(`=10 + 11*`j'') " " %9.2f `v' "*" _c
                }
                else {
                    di as txt _col(`=10 + 11*`j'') "  " %9.2f `v' " " _c
                }
            }
            di ""
        }
        di as txt _col(3) "{hline 72}"
        di as res _col(3) "Optimal: " "p = `best_p', q = `best_q'" ///
                  cond(`klin' > 0, ", r = `best_r'", "") ///
                  as txt "    (min " upper("`ic'") " = " %9.2f `best_ic' ")"
        di as txt _col(3) "* denotes minimum " upper("`ic'")
    }

    matrix colnames `ic_grid' = q1-q`qmax'
    matrix rownames `ic_grid' = p1-p`pmax'

    return scalar p = `best_p'
    return scalar q = `best_q'
    return scalar r = `best_r'
    return scalar ic_value = `best_ic'
    return matrix bic_grid = `ic_grid'
    return local  ic_used  "`ic'"
end
