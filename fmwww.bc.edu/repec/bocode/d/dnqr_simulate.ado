*! dnqr_simulate.ado  version 1.0.1  27may2026
*! Monte Carlo simulator that replicates the data-generating processes
*! used in Xu, Wang, Shin and Zheng (2024) and Zhu et al. (2019).
*! Generates an N x T panel with a user-chosen network topology
*! (DyadW / BlockW / PowerLawW / AsymW), then writes long-form data
*! to disk and / or returns the network matrix as a Stata / Mata matrix
*! ready for nqar or dnqr.
*!
*! Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! Help    : help dnqr_simulate

program define dnqr_simulate, rclass
        version 13.0
        syntax , N(integer) T(integer) [          ///
                Wtype(string)                     ///
                Wparam(real 2.5)                  ///
                Burnin(integer 50)                ///
                ERRordist(string)                 ///
                ERRordf(real 5)                   ///
                GAMma1(real 0.20)                 ///
                GAMma2(real 0.30)                 ///
                GAMma3(real 0.30)                 ///
                Z(integer 0)                      ///
                Factors(integer 0)                ///
                SEED(integer 1234)                ///
                CLEAR                             ///
                Genvar(string)                    ///
                Idvar(string)                     ///
                Timevar(string)                   ///
                Wname(string)                     ///
                Mata                              ///
                ]

        if ("`wtype'"=="")   local wtype  powerlaw
        local wtype = lower("`wtype'")
        if !inlist("`wtype'", "powerlaw", "block", "dyad", "asym") {
                di as err "{bf:wtype()} must be powerlaw, block, dyad or asym"
                exit 198
        }
        if ("`errordist'"=="") local errordist normal
        local errordist = lower("`errordist'")
        if !inlist("`errordist'", "normal", "t", "chi") {
                di as err "{bf:errordist()} must be normal, t or chi"
                exit 198
        }
        if ("`genvar'"=="")  local genvar  y
        if ("`idvar'"=="")   local idvar   id
        if ("`timevar'"=="") local timevar t
        if ("`wname'"=="")   local wname   Wsim

        _dnqr_mata

        if ("`clear'" != "") quietly drop _all

        tempname Wm Ymat Zmat Fmat
        mata: _dnqr_simulate("`wtype'", `n', `wparam', `burnin', `t',          ///
                "`errordist'", `errordf', `gamma1', `gamma2', `gamma3',         ///
                `z', `factors', `seed', "`Wm'", "`Ymat'", "`Zmat'", "`Fmat'")

        // store W under user-chosen name (Stata matrix or Mata matrix)
        if ("`mata'"=="") {
                matrix `wname' = `Wm'
        }
        else {
                mata: `wname' = st_matrix("`Wm'")
        }

        // ----- write long-form panel data ----------------------------
        local NT = `n' * `t'
        quietly set obs `NT'
        quietly gen int `idvar' = mod(_n - 1, `n') + 1
        quietly gen int `timevar' = floor((_n - 1)/`n') + 1
        quietly gen double `genvar' = .
        mata: _dnqr_sim_writeY("`genvar'", st_matrix("`Ymat'"))
        if (`z' > 0) {
                forvalues k = 1/`z' {
                        quietly gen double Z`k' = .
                }
                mata: _dnqr_sim_writeZ(st_matrix("`Zmat'"))
        }
        if (`factors' > 0) {
                forvalues k = 1/`factors' {
                        quietly gen double F`k' = .
                }
                mata: _dnqr_sim_writeF(st_matrix("`Fmat'"))
        }
        sort `idvar' `timevar'
        quietly xtset `idvar' `timevar'

        // network density (compute in Mata to handle both Stata/Mata storage)
        tempname Wden
        if ("`mata'"=="") mata: st_numscalar("`Wden'", sum(st_matrix("`wname'"):>0)/(`n'*`n'-`n'))
        else              mata: st_numscalar("`Wden'", sum(`wname':>0)/(`n'*`n'-`n'))
        local wd = scalar(`Wden')

        di ""
        di as txt "{hline 78}"
        di as res "  Simulated DNQR panel"
        di as txt "{hline 78}"
        di as txt "  N = "        as res `n'                   ///
            as txt "   T = "      as res `t'                   ///
            as txt "   wtype = "  as res "`wtype'"             ///
            as txt "   error = "  as res "`errordist'"
        di as txt "  gamma1 = "  as res %5.3f `gamma1'         ///
            as txt "  gamma2 = "  as res %5.3f `gamma2'        ///
            as txt "  gamma3 = "  as res %5.3f `gamma3'        ///
            as txt "  seed = "    as res `seed'
        di as txt "  W stored as " _c
        if ("`mata'"=="") di as res "Stata matrix " "`wname'" ///
            as txt " ; density = " as res %5.4f `wd'
        else              di as res "Mata matrix "  "`wname'" ///
            as txt " ; density = " as res %5.4f `wd'
        di as txt "  Data set in memory; xtset by `idvar' `timevar'."
        di as txt "{hline 78}"

        return scalar N  = `n'
        return scalar T  = `t'
        return scalar Wd = `wd'
        return local  wname "`wname'"
end
