*! nqar.ado  version 1.0.1  27may2026
*! Network Quantile Autoregression (NQAR)
*! Implements Zhu, Wang, Wang and H\"ardle (2019), "Network Quantile
*! Autoregression", Journal of Econometrics 212(1): 345-358. Only
*! lagged-network effects enter the conditional quantile, so plain
*! quantile regression is consistent (no simultaneity).
*!
*! Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! See also: dnqr (contemporaneous network effects), dnqr_plot,
*!           dnqr_impulse, dnqr_simulate
*! Help    : help nqar  or  help dnqrlib

program define nqar, eclass sortpreserve
        version 13.0

        if replay() {
                if ("`e(cmd)'" != "nqar") error 301
                _nqar_display
                exit
        }

        syntax varlist(min=1 max=1 numeric ts) [if] [in] , ///
                Network(name)                              ///
                [                                          ///
                  Mata                                     ///
                  Quantile(numlist >0 <1 sort)             ///
                  Z(varlist numeric)                       ///
                  Factors(varlist numeric ts)              ///
                  PLags(integer 0)                         ///
                  Bandwidth(string)                        ///
                  bscale(real 1)                           ///
                  Level(cilevel)                           ///
                  ROWSTD                                   ///
                  Title(string)                            ///
                  NOTAble                                  ///
                ]

        if ("`quantile'"=="")  local quantile = "0.5"
        if ("`bandwidth'"=="") local bandwidth = "HS"
        local bandwidth = upper("`bandwidth'")
        if !inlist("`bandwidth'", "HS", "HB") {
                di as err "{bf:bandwidth()} must be HS or HB"
                exit 198
        }

        _dnqr_mata

        capture xtset
        if _rc {
                di as err "data are not -xtset-; please {bf:xtset} panelvar timevar first"
                exit 459
        }
        local pvar `r(panelvar)'
        local tvar `r(timevar)'

        marksample touse
        markout `touse' `varlist' `z' `factors' `pvar' `tvar'

        local depvar `varlist'

        // ---- pull W into a Stata matrix temp -------------------------
        tempname Wm
        if ("`mata'"=="") {
                capture confirm matrix `network'
                if _rc {
                        di as err "{bf:network(`network')} is not a Stata matrix; " ///
                                  "add option {bf:mata} if it is a Mata matrix"
                        exit 198
                }
                matrix `Wm' = `network'
        }
        else {
                capture mata: st_matrix("`Wm'", `network')
                if _rc {
                        di as err "Mata matrix {bf:`network'} not found"
                        exit 198
                }
        }

        tempname B SE TVAL PVAL CILO CIHI QMAT NETD BFIRST VFIRST
        mata: _nqar_engine("`depvar'", "`z'", "`factors'", "`Wm'",      ///
                "`pvar'", "`tvar'", "`touse'", `plags', "`quantile'",   ///
                "`bandwidth'", `bscale', ("`rowstd'"!=""), `level',     ///
                "`B'", "`SE'", "`TVAL'", "`PVAL'", "`CILO'", "`CIHI'",  ///
                "`QMAT'", "`NETD'", "`BFIRST'", "`VFIRST'")

        ereturn post `BFIRST' `VFIRST', esample(`touse') depname(`depvar')
        ereturn local cmd        "nqar"
        ereturn local cmdline    "nqar `0'"
        ereturn local title      "`title'"
        ereturn local depvar     "`depvar'"
        ereturn local zvars      "`z'"
        ereturn local factors    "`factors'"
        ereturn local bandwidth  "`bandwidth'"
        ereturn local panelvar   "`pvar'"
        ereturn local timevar    "`tvar'"
        ereturn scalar plags     = `plags'
        ereturn scalar level     = `level'
        ereturn scalar bscale    = `bscale'
        ereturn scalar netdens   = scalar(`NETD')
        ereturn matrix quantile  = `QMAT'
        ereturn matrix b_q       = `B'
        ereturn matrix se_q      = `SE'
        ereturn matrix t_q       = `TVAL'
        ereturn matrix p_q       = `PVAL'
        ereturn matrix lo_q      = `CILO'
        ereturn matrix hi_q      = `CIHI'

        if ("`notable'"=="") _nqar_display
end


program define _nqar_display
        version 13.0
        local depvar  = e(depvar)
        local title   `"`e(title)'"'
        local plags   = e(plags)
        local panel   `"`e(panelvar)'"'
        local tvar    `"`e(timevar)'"'
        local level   = e(level)
        local band    `"`e(bandwidth)'"'
        tempname Q B SE TVAL PVAL LO HI
        matrix `Q'    = e(quantile)
        matrix `B'    = e(b_q)
        matrix `SE'   = e(se_q)
        matrix `TVAL' = e(t_q)
        matrix `PVAL' = e(p_q)
        matrix `LO'   = e(lo_q)
        matrix `HI'   = e(hi_q)
        local rows : rowfullnames `B'
        local nq = colsof(`Q')

        if ("`title'"=="") local title "Network Quantile Autoregression (Zhu et al. 2019)"

        di ""
        di as txt "{hline 78}"
        di as res _col(2) "`title'"
        di as txt "{hline 78}"
        di as txt _col(2) "Panel : "    as res "`panel'"  ///
            as txt _col(28) "Time : "  as res "`tvar'"     ///
            as txt _col(50) "Bandwidth : " as res "`band'"
        di as txt _col(2) "Network density (W>0) : " as res %5.4f e(netdens) ///
            as txt _col(50) "Confidence level : " as res `level' "%"
        if (`plags' > 0) di as txt _col(2) "Common-factor lags : " as res `plags'
        di as txt "{hline 78}"

        forvalues q = 1/`nq' {
                local tau = `Q'[1,`q']
                di ""
                di as txt "{hline 78}"
                di as res _col(2) "Quantile tau = " %5.3f `tau'
                di as txt "{hline 78}"
                di as txt _col(2) "Variable" _col(22) "Coef." ///
                       _col(34) "Std.Err." _col(46) "z" ///
                       _col(56) "P>|z|" _col(64) "[`level'% CI]"
                di as txt "{hline 78}"
                local nr = rowsof(`B')
                forvalues r = 1/`nr' {
                        local nm : word `r' of `rows'
                        local b  = `B'[`r',`q']
                        local s  = `SE'[`r',`q']
                        local t  = `TVAL'[`r',`q']
                        local p  = `PVAL'[`r',`q']
                        local lo = `LO'[`r',`q']
                        local hi = `HI'[`r',`q']
                        di as txt _col(2) "`nm'"               ///
                              as res _col(20) %10.5f `b'       ///
                              as res _col(32) %10.5f `s'       ///
                              as res _col(44) %8.3f  `t'       ///
                              as res _col(54) %7.4f  `p'       ///
                              as res _col(63) %9.4f `lo'       ///
                              as res _col(73) %9.4f `hi'
                }
                di as txt "{hline 78}"
        }
        di as txt _n "{p 2 2 2}{it:Notes:} Conditional quantile of " ///
            "{bf:`depvar'} on the row-standardised lagged-network mean, own " ///
            "lag, nodal covariates Z and (optionally) common factors F. " ///
            "Standard errors are Powell (1986) sandwich with {bf:`band'} " ///
            "bandwidth (Koenker and Xiao 2006). Use {help dnqr_plot} to " ///
            "plot the quantile process and {help dnqr_impulse} for " ///
            "tail-event impulse analysis. See {help nqar}.{p_end}"
end
