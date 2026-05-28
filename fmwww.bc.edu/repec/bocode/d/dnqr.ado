*! dnqr.ado  version 1.0.1  27may2026
*! Dynamic Network Quantile Regression (DNQR)
*! Implements Xu, Wang, Shin and Zheng (2024), "Dynamic Network Quantile
*! Regression Model" (SSRN 3690631).  Extends NQAR by allowing a
*! contemporaneous network effect Gamma1(tau) * W*Yt, which induces a
*! simultaneity bias.  Estimation uses Chernozhukov-Hansen instrumental
*! variable quantile regression (IVQR) via a one-dimensional grid search
*! over the endogenous coefficient, plugged into Stata's -qreg- at each
*! grid point.  Standard errors follow Powell (1986) with Koenker-Xiao
*! bandwidth (Hall-Sheather or Bofinger).
*!
*! Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! See also: nqar (lagged-network only), dnqr_plot, dnqr_impulse,
*!           dnqr_simulate
*! Help    : help dnqr  or  help dnqrlib

program define dnqr, eclass sortpreserve
        version 13.0

        if replay() {
                if ("`e(cmd)'" != "dnqr") error 301
                _dnqr_display
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
                  IVtype(string)                           ///
                  GRidpoints(integer 41)                   ///
                  GRidscale(real 4)                        ///
                  GRid(numlist sort)                       ///
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
        if ("`ivtype'"=="") local ivtype "wy23"
        local ivtype = lower("`ivtype'")
        if !inlist("`ivtype'", "wy2", "wy3", "wy23") {
                di as err "{bf:ivtype()} must be wy2, wy3 or wy23"
                exit 198
        }
        if (`gridpoints' < 5) {
                di as err "{bf:gridpoints()} must be >= 5"
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

        // ---- user-supplied custom grid (optional) -------------------
        tempname GRID
        if ("`grid'"=="")  matrix `GRID' = J(1,1,.)
        else {
                local k : word count `grid'
                matrix `GRID' = J(1, `k', 0)
                local i 0
                foreach g of numlist `grid' {
                        local ++i
                        matrix `GRID'[1,`i'] = `g'
                }
        }

        tempname B SE TVAL PVAL CILO CIHI QMAT ALPHAS GNORM NETD BFIRST VFIRST
        mata: _dnqr_engine("`depvar'", "`z'", "`factors'", "`Wm'",       ///
                "`pvar'", "`tvar'", "`touse'", `plags', "`quantile'",    ///
                "`bandwidth'", `bscale', ("`rowstd'"!=""), `level',      ///
                "`ivtype'", `gridpoints', `gridscale', "`GRID'",         ///
                "`B'", "`SE'", "`TVAL'", "`PVAL'", "`CILO'", "`CIHI'",   ///
                "`QMAT'", "`ALPHAS'", "`GNORM'", "`NETD'",               ///
                "`BFIRST'", "`VFIRST'")

        ereturn post `BFIRST' `VFIRST', esample(`touse') depname(`depvar')
        ereturn local cmd        "dnqr"
        ereturn local cmdline    "dnqr `0'"
        ereturn local title      "`title'"
        ereturn local depvar     "`depvar'"
        ereturn local zvars      "`z'"
        ereturn local factors    "`factors'"
        ereturn local bandwidth  "`bandwidth'"
        ereturn local ivtype     "`ivtype'"
        ereturn local panelvar   "`pvar'"
        ereturn local timevar    "`tvar'"
        ereturn scalar plags     = `plags'
        ereturn scalar level     = `level'
        ereturn scalar bscale    = `bscale'
        ereturn scalar gridpts   = `gridpoints'
        ereturn scalar gridscale = `gridscale'
        ereturn scalar netdens   = scalar(`NETD')
        ereturn matrix quantile  = `QMAT'
        ereturn matrix b_q       = `B'
        ereturn matrix se_q      = `SE'
        ereturn matrix t_q       = `TVAL'
        ereturn matrix p_q       = `PVAL'
        ereturn matrix lo_q      = `CILO'
        ereturn matrix hi_q      = `CIHI'
        ereturn matrix alphahat  = `ALPHAS'
        ereturn matrix gnorm     = `GNORM'

        if ("`notable'"=="") _dnqr_display
end


program define _dnqr_display
        version 13.0
        local depvar  : disp e(depvar)
        local title   `"`e(title)'"'
        local plags   = e(plags)
        local panel   = e(panelvar)
        local tvar    = e(timevar)
        local level   = e(level)
        local band    = e(bandwidth)
        local iv      = e(ivtype)
        tempname Q B SE TVAL PVAL LO HI AL
        matrix `Q'    = e(quantile)
        matrix `B'    = e(b_q)
        matrix `SE'   = e(se_q)
        matrix `TVAL' = e(t_q)
        matrix `PVAL' = e(p_q)
        matrix `LO'   = e(lo_q)
        matrix `HI'   = e(hi_q)
        matrix `AL'   = e(alphahat)
        local rows : rowfullnames `B'
        local nq = colsof(`Q')

        if ("`title'"=="") local title "Dynamic Network Quantile Regression (Xu et al. 2024)"

        di ""
        di as txt "{hline 78}"
        di as res _col(2) "`title'"
        di as txt "{hline 78}"
        di as txt _col(2) "Panel : "    as res "`panel'"   ///
            as txt _col(28) "Time : "  as res "`tvar'"      ///
            as txt _col(48) "IV type : " as res "`iv'"
        di as txt _col(2) "Network density (W>0) : " as res %5.4f e(netdens) ///
            as txt _col(40) "Bandwidth : " as res "`band'"  ///
            as txt _col(58) "Level : " as res `level' "%"
        di as txt _col(2) "Grid points : " as res e(gridpts)   ///
            as txt _col(24) "Grid scale : " as res e(gridscale) ///
            as txt _col(48) "Plags : " as res `plags'
        di as txt "{hline 78}"

        forvalues q = 1/`nq' {
                local tau = `Q'[1,`q']
                local ah  = `AL'[1,`q']
                di ""
                di as txt "{hline 78}"
                di as res _col(2) "Quantile tau = " %5.3f `tau'   ///
                    as txt _col(38) "alpha_hat (CH-IVQR) = " as res %8.4f `ah'
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
            "{bf:`depvar'} on the row-standardised contemporaneous network " ///
            "mean WY (gamma1), lagged network mean WY_L1 (gamma2), own lag " ///
            "Y_L1 (gamma3), nodal covariates Z and (optional) common factors " ///
            "F. The endogeneity of WY is handled by Chernozhukov-Hansen IVQR " ///
            "with instruments {bf:`iv'} (powers of W applied to Y_L1). " ///
            "Standard errors are Powell (1986) sandwich with {bf:`band'} " ///
            "bandwidth (Koenker and Xiao 2006). Use {help dnqr_plot} to " ///
            "plot the quantile process and {help dnqr_impulse} for " ///
            "tail-event impulse analysis.{p_end}"
end
