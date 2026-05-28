*! dnqr_impulse.ado  version 1.0.1  27may2026
*! Tail-event-driven impulse response for NQAR / DNQR models, following
*! Zhu et al. (2019) Section 3 and Xu et al. (2024).  The reduced-form
*! one-step propagation matrix at quantile tau is
*!     G_tau = (I - gamma1(tau)*W)^{-1} * (gamma2(tau)*W + gamma3(tau)*I)
*! for DNQR (with gamma1 = 0 for NQAR).  The IRF iterates G_tau^h * v0
*! over a user-defined horizon and stores results in e(irf).
*!
*! Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! Help    : help dnqr_impulse

program define dnqr_impulse, rclass
        version 13.0

        if !inlist("`e(cmd)'", "nqar", "dnqr") {
                di as err "{bf:dnqr_impulse} only works after {bf:nqar} or {bf:dnqr}"
                exit 301
        }

        syntax , Network(name) Horizon(integer) [             ///
                Quantile(real -1)                              ///
                SHocknode(integer 1)                           ///
                SHocksize(real 1)                              ///
                Mata                                           ///
                ROWSTD                                         ///
                SAVing(string)                                 ///
                Plot                                           ///
                Top(integer 6)                                 ///
                Title(string)                                  ///
                SCHeme(string)                                 ///
                NAme(string)                                   ///
                ]

        if ("`scheme'"=="") local scheme s2color
        if ("`name'"=="")   local name dnqrimpulse
        if (`horizon' < 1) {
                di as err "{bf:horizon()} must be >= 1"
                exit 198
        }

        _dnqr_mata

        // ---- get coefficients at desired quantile -------------------
        tempname Q B
        matrix `Q' = e(quantile)
        matrix `B' = e(b_q)
        local nq = colsof(`Q')
        local qcol = 0
        if (`quantile' < 0) {
                // default: the middle column
                local qcol = ceil(`nq'/2)
                local tau = `Q'[1,`qcol']
        }
        else {
                forvalues j = 1/`nq' {
                        if (abs(`Q'[1,`j'] - `quantile') < 1e-6) {
                                local qcol = `j'
                                continue, break
                        }
                }
                if (`qcol'==0) {
                        di as err "{bf:quantile(`quantile')} not in e(quantile);" ///
                                  " available: " _c
                        forvalues j = 1/`nq' di as res `Q'[1,`j'] " " _c
                        di
                        exit 198
                }
                local tau = `quantile'
        }

        // ---- read W --------------------------------------------------
        tempname Wm
        if ("`mata'"=="") {
                capture confirm matrix `network'
                if _rc {
                        di as err "{bf:network(`network')} is not a Stata matrix; " ///
                                  "add {bf:mata} if it is a Mata matrix"
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

        // ---- pull gamma1, gamma2, gamma3 from e(b_q) ----------------
        local rows : rowfullnames `B'
        local idx_g1 = 0
        local idx_g2 = 0
        local idx_g3 = 0
        local r 0
        foreach nm of local rows {
                local ++r
                if ("`nm'"=="WY")    local idx_g1 = `r'
                if ("`nm'"=="WY_L1") local idx_g2 = `r'
                if ("`nm'"=="Y_L1")  local idx_g3 = `r'
        }
        local g1 = cond(`idx_g1'==0, 0, `B'[`idx_g1',`qcol'])
        local g2 = cond(`idx_g2'==0, 0, `B'[`idx_g2',`qcol'])
        local g3 = cond(`idx_g3'==0, 0, `B'[`idx_g3',`qcol'])

        // ---- compute IRF in Mata -----------------------------------
        tempname IRF NORMS
        mata: _dnqr_irf("`Wm'", `g1', `g2', `g3', `horizon', ///
                        `shocknode', `shocksize', ("`rowstd'"!=""), ///
                        "`IRF'", "`NORMS'")

        di ""
        di as txt "{hline 78}"
        di as res _col(2) "Tail-event impulse response"   ///
            as txt _col(45) "tau = " as res %5.3f `tau'
        di as txt "{hline 78}"
        di as txt _col(2) "Shock node = " as res `shocknode' ///
            as txt _col(25) "Shock size = " as res %6.3f `shocksize' ///
            as txt _col(50) "Horizon = " as res `horizon'
        di as txt _col(2) "Coefficients used: " ///
            as txt "gamma1=" as res %6.3f `g1' ///
            as txt "  gamma2=" as res %6.3f `g2' ///
            as txt "  gamma3=" as res %6.3f `g3'
        di as txt "{hline 78}"
        di as txt _col(2) "Horizon" _col(20) "||IRF||_2" _col(45) "max(|IRF|)"
        di as txt "{hline 78}"
        local H1 = `horizon' + 1
        forvalues h = 1/`H1' {
                local nrm = `NORMS'[1,`h']
                local mx  = `NORMS'[2,`h']
                local hh  = `h' - 1
                di as txt _col(4) `hh' as res _col(18) %10.5f `nrm' ///
                       as res _col(43) %10.5f `mx'
        }
        di as txt "{hline 78}"

        if ("`plot'" != "") {
                if ("`title'"=="") local title = "IRF at tau = " + string(`tau', "%5.3f")
                _dnqr_impulse_plot, irf(`IRF') horizon(`horizon') ///
                        top(`top') title("`title'") scheme(`scheme') ///
                        name(`name') saving(`saving')
        }

        return scalar tau    = `tau'
        return scalar gamma1 = `g1'
        return scalar gamma2 = `g2'
        return scalar gamma3 = `g3'
        return matrix irf    = `IRF'
        return matrix norms  = `NORMS'
end
