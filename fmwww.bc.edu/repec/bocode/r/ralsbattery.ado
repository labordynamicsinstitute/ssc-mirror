*! ralsbattery 2.0.0  13may2026  Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! Full-package driver:
*!    - {it:varlist} with 1 variable  : run every RALS unit-root test
*!    - {it:varlist} with 2+ variables: unit-root battery on each variable
*!                                      + RALS cointegration battery
*!                                        (ECM, ADL, EG, EG2, Fourier ADL)
*------------------------------------------------------------------------------

program define ralsbattery, rclass
    version 14.0
    qui _rals_mata
    syntax varlist(min=1 ts) [if] [in], [        ///
        TREND                                    ///
        MAXLags(integer 8)                       ///
        IC(string)                               ///
        FMAX(integer 5)                          ///
        Graph                                    ///
        ]

    marksample touse
    capture tsset
    if _rc {
        di as error "data must be tsset before ralsbattery"
        exit 459
    }
    local timevar `r(timevar)'
    qui count if `touse'
    local T = r(N)
    if `T' < 30 {
        di as error "sample too small (T=`T')"
        exit 2001
    }

    if "`ic'"=="" local ic "tstat"
    local trendopt   = cond("`trend'"!="", "trend", "")
    local trendlabel = cond("`trend'"!="", "constant + trend", "constant only")
    local nvars : list sizeof varlist

    *--------------------------------------------------------------------------
    *  Master header
    *--------------------------------------------------------------------------
    di as text ""
    di as text "{c TLC}{hline 78}{c TRC}"
    di as text "{c |}  " as result "RALS COMPLETE BATTERY"                   ///
                                   as text "{col 79}{c |}"
    di as text "{c |}  Variables : " as result "`varlist'"                   ///
                                     as text "{col 79}{c |}"
    di as text "{c |}  Sample    : T = " as result `T'                       ///
                                         as text "    Model = "              ///
                                         as result "`trendlabel'"            ///
                                         as text "{col 79}{c |}"
    di as text "{c |}  IC rule   : " as result "`ic'"                        ///
                                     as text "    Max lags = " as result     ///
                                     `maxlags' as text "    Fmax = "         ///
                                     as result `fmax' as text "{col 79}{c |}"
    di as text "{c BLC}{hline 78}{c BRC}"

    *==========================================================================
    *  PART 1 -- Unit-root battery on EACH variable
    *==========================================================================
    tempname B
    matrix `B' = J(`nvars'*5, 8, .)
    local big_nrej_rals = 0
    local big_total     = 0
    local vrow = 0

    local i = 0
    foreach v of varlist `varlist' {
        local ++i
        di as text ""
        di as text "{bf:== Variable `i' of `nvars': `v' ==}"

        * --- diagnostics ----------------------------------------------------
        qui ralsdiag `v' if `touse', `trendopt' maxlags(`maxlags')
        local skew     = r(skewness)
        local kurt     = r(kurtosis)
        local sw_p     = r(sw_p)
        local rho2_pre = r(rho2)
        di as text "  Skewness=" as result %6.3f `skew'                       ///
           as text "  Kurtosis=" as result %6.3f `kurt'                       ///
           as text "  SW p=" as result %5.3f `sw_p'                           ///
           as text "  rho2_pre=" as result %5.3f `rho2_pre'

        * --- run the 5 unit-root tests --------------------------------------
        _ralsbattery_uroot `v' `touse' "`trendopt'" `maxlags' "`ic'" `fmax' ///
                           `vrow' "`B'"
        local nrej_v_rals = r(nrej_rals)
        local big_nrej_rals = `big_nrej_rals' + `nrej_v_rals'
        local big_total     = `big_total' + 5

        local vrow = `vrow' + 5

        * --- per-variable verdict -------------------------------------------
        di as text "    {bf:Verdict for `v'}: " as result `nrej_v_rals'      ///
           as text "/5 RALS tests reject H0 (unit root)."
    }

    *==========================================================================
    *  PART 2 -- Cointegration battery (only when 2+ variables)
    *==========================================================================
    tempname C
    matrix `C' = J(5, 5, .)
    local coint_nrej = 0

    if `nvars' >= 2 {
        di as text ""
        di as text "{bf:== Cointegration battery ==}"
        di as text "{hline 80}"
        local dep : word 1 of `varlist'
        local regs : list varlist - dep
        di as text "  Dependent : " as result "`dep'"                         ///
           as text "    Regressors: " as result "`regs'"
        di as text ""

        * --- ralscoint: 4 tests in one call ---------------------------------
        qui ralscoint `dep' `regs' if `touse', `trendopt' noheader
        matrix `C'[1,1] = r(ECM_t)
        matrix `C'[1,3] = r(ECM_rals)
        matrix `C'[1,4] = r(ECM_rho2)
        matrix `C'[2,1] = r(ADL_t)
        matrix `C'[2,3] = r(ADL_rals)
        matrix `C'[2,4] = r(ADL_rho2)
        matrix `C'[3,1] = r(EG_t)
        matrix `C'[3,3] = r(EG_rals)
        matrix `C'[3,4] = r(EG_rho2)
        matrix `C'[4,1] = r(EG2_t)
        matrix `C'[4,3] = r(EG2_rals)
        matrix `C'[4,4] = r(EG2_rho2)
        * 5% CVs (OLS in col 2, RALS in col 5) come from r(cv)
        tempname CV
        matrix `CV' = r(cv)
        forvalues j = 1/4 {
            matrix `C'[`j',2] = `CV'[`j',1]
            matrix `C'[`j',5] = `CV'[`j',3]
        }

        * --- ralsfadl --------------------------------------------------------
        qui ralsfadl `dep' `regs' if `touse', `trendopt' fmax(`fmax') noheader
        matrix `C'[5,1] = r(tauFADL)
        matrix `C'[5,2] = .                  // no separate OLS-FADL CV
        matrix `C'[5,3] = r(tauRALS)
        matrix `C'[5,4] = r(rho2)
        matrix `C'[5,5] = r(cv05)

        * --- table ----------------------------------------------------------
        _ralsbattery_print_header "Cointegration"
        local cnames `" "ECM"  "ADL"  "EG"  "EG2"  "Fourier ADL" "'
        forvalues j = 1/5 {
            local lab : word `j' of `cnames'
            local s1   = `C'[`j',1]
            local s1cv = `C'[`j',2]
            local s2   = `C'[`j',3]
            local r2   = `C'[`j',4]
            local s2cv = `C'[`j',5]
            local rej2 = (`s2' < `s2cv')
            if `rej2' local coint_nrej = `coint_nrej' + 1
            _ralsbattery_print_row "`lab'" `s1' `s1cv' `s2' `s2cv' `r2' `rej2'
        }
        di as text "{hline 80}"
        di as text "  {bf:Verdict (cointegration)}: " as result `coint_nrej'  ///
           as text "/5 RALS tests reject H0 (no cointegration)."
    }

    *==========================================================================
    *  Overall verdict
    *==========================================================================
    di as text ""
    di as text "{bf:Overall summary}"
    di as text "{hline 80}"
    di as text "  Unit-root rejections   (across all variables) : "         ///
       as result `big_nrej_rals' as text "/" as result `big_total'
    if `nvars' >= 2 {
        di as text "  Cointegration rejections                       : "    ///
           as result `coint_nrej' as text "/5"
    }
    di as text "{hline 80}"

    *--------------------------------------------------------------------------
    *  Optional graph
    *--------------------------------------------------------------------------
    if "`graph'" != "" {
        _ralsbattery_graph_all "`varlist'" "`timevar'" "`touse'" `B' `nvars'
    }

    return matrix unitroot   = `B'
    if `nvars' >= 2 return matrix coint = `C'
    return scalar n_rej_rals = `big_nrej_rals'
    return scalar n_tests    = `big_total'
    if `nvars' >= 2 return scalar n_coint_rej = `coint_nrej'
    return scalar T          = `T'
    return local  variables  = "`varlist'"
end

*------------------------------------------------------------------------------
*  Subroutine: unit-root mini-battery on one variable
*------------------------------------------------------------------------------
program define _ralsbattery_uroot, rclass
    args v touse trendopt maxlags ic fmax row Bname

    _ralsbattery_print_header "Unit root for `v'"

    local local_nrej = 0

    *--- ADF ----------
    qui ralsadf `v' if `touse', `trendopt' maxlags(`maxlags') ic(`ic') noheader
    local rej2 = (r(tauRALS) < r(cv05))
    matrix `Bname'[`row'+1,1] = r(tauADF)
    matrix `Bname'[`row'+1,2] = r(cv05_DF)
    matrix `Bname'[`row'+1,3] = r(tauRALS)
    matrix `Bname'[`row'+1,4] = r(cv05)
    matrix `Bname'[`row'+1,5] = r(rho2)
    matrix `Bname'[`row'+1,7] = `rej2'
    _ralsbattery_print_row "ADF" r(tauADF) r(cv05_DF) r(tauRALS) r(cv05) r(rho2) `rej2'
    if `rej2' local local_nrej = `local_nrej' + 1

    *--- LM -----------
    qui ralslm `v' if `touse', maxlags(`maxlags') ic(`ic') noheader
    local rej2 = (r(tauRALS) < r(cv05))
    matrix `Bname'[`row'+2,1] = r(tauLM)
    matrix `Bname'[`row'+2,2] = r(cv05_LM)
    matrix `Bname'[`row'+2,3] = r(tauRALS)
    matrix `Bname'[`row'+2,4] = r(cv05)
    matrix `Bname'[`row'+2,5] = r(rho2)
    matrix `Bname'[`row'+2,7] = `rej2'
    _ralsbattery_print_row "LM" r(tauLM) r(cv05_LM) r(tauRALS) r(cv05) r(rho2) `rej2'
    if `rej2' local local_nrej = `local_nrej' + 1

    *--- Fourier ADF --
    qui ralsfadf `v' if `touse', `trendopt' maxlags(`maxlags') ic(`ic') fmax(`fmax') noheader
    local rej2 = (r(tauRALS) < r(cv05))
    matrix `Bname'[`row'+3,1] = r(tauFADF)
    matrix `Bname'[`row'+3,2] = r(cv05_FADF)
    matrix `Bname'[`row'+3,3] = r(tauRALS)
    matrix `Bname'[`row'+3,4] = r(cv05)
    matrix `Bname'[`row'+3,5] = r(rho2)
    matrix `Bname'[`row'+3,7] = `rej2'
    matrix `Bname'[`row'+3,8] = r(kfreq)
    _ralsbattery_print_row "Fourier ADF (k=`=r(kfreq)')"          ///
        r(tauFADF) r(cv05_FADF) r(tauRALS) r(cv05) r(rho2) `rej2'
    if `rej2' local local_nrej = `local_nrej' + 1

    *--- Fourier KSS --
    qui ralsfkss `v' if `touse', `trendopt' maxlags(`maxlags') ic(`ic') fmax(`fmax') noheader
    local rej2 = (r(tauRALS) < r(cv05))
    matrix `Bname'[`row'+4,1] = r(tauKSS)
    matrix `Bname'[`row'+4,2] = r(cv05_FKSS)
    matrix `Bname'[`row'+4,3] = r(tauRALS)
    matrix `Bname'[`row'+4,4] = r(cv05)
    matrix `Bname'[`row'+4,5] = r(rho2)
    matrix `Bname'[`row'+4,7] = `rej2'
    matrix `Bname'[`row'+4,8] = r(kfreq)
    _ralsbattery_print_row "Fourier KSS (k=`=r(kfreq)')"          ///
        r(tauKSS) r(cv05_FKSS) r(tauRALS) r(cv05) r(rho2) `rej2'
    if `rej2' local local_nrej = `local_nrej' + 1

    *--- LM 1 break ---
    qui ralslmb `v' if `touse', model(2) breaks(1) maxlags(`maxlags') ic(`ic') noheader
    local rej2 = (r(tauRALS) < r(cv05))
    matrix `Bname'[`row'+5,1] = r(LMmin)
    matrix `Bname'[`row'+5,2] = r(cv05_LM)
    matrix `Bname'[`row'+5,3] = r(tauRALS)
    matrix `Bname'[`row'+5,4] = r(cv05)
    matrix `Bname'[`row'+5,5] = r(rho2)
    matrix `Bname'[`row'+5,7] = `rej2'
    matrix `Bname'[`row'+5,8] = r(tb1)
    _ralsbattery_print_row "LM 1-break (obs `=r(tb1)')"           ///
        r(LMmin) r(cv05_LM) r(tauRALS) r(cv05) r(rho2) `rej2'
    if `rej2' local local_nrej = `local_nrej' + 1

    di as text "{hline 80}"
    return scalar nrej_rals = `local_nrej'
end

*------------------------------------------------------------------------------
*  Pretty-print helpers (shared header + 1-line row)
*------------------------------------------------------------------------------
program define _ralsbattery_print_header
    args sectionname
    di as text ""
    di as text "{hline 80}"
    di as text   _col(3)  "`sectionname'"                                    ///
                 _col(31) "Stage-1"                                          ///
                 _col(52) "RALS"                                             ///
                 _col(74) "Verdict"
    di as text   _col(3)  "Test"                                             ///
                 _col(29) "stat"                                             ///
                 _col(39) "5% CV"                                            ///
                 _col(50) "stat"                                             ///
                 _col(60) "5% CV"                                            ///
                 _col(69) "rho^2"                                            ///
                 _col(76) "(RALS)"
    di as text "{hline 80}"
end

program define _ralsbattery_print_row
    args lab s1 s1cv s2 s2cv r2 rej2
    local v_s1cv = `s1cv'
    di as text   _col(3)  "`lab'"                                            ///
       as result _col(28) %8.3f `s1'                                         ///
                 _col(38) %8.3f `v_s1cv'                                     ///
                 _col(48) %8.3f `s2'                                         ///
                 _col(58) %8.3f `s2cv'                                       ///
                 _col(68) %6.3f `r2'                                         ///
                 _col(76) cond(`rej2', "{bf:REJECT}", "no rej.")
end

*------------------------------------------------------------------------------
*  Forest plot of every RALS statistic across the battery
*------------------------------------------------------------------------------
program define _ralsbattery_graph_all
    args varlist timevar touse Bname nvars

    matrix `Bname'_copy = `Bname'
    local nrows = 5 * `nvars'

    preserve
    clear
    qui set obs `nrows'
    qui gen id   = _n
    qui gen stat = .
    qui gen cv5  = .
    qui gen reject = 0
    qui gen str40 lab = ""

    local k = 0
    local vi = 0
    foreach v of local varlist {
        local ++vi
        local tests `" "ADF" "LM" "FADF" "FKSS" "LM-brk" "'
        forvalues j = 1/5 {
            local ++k
            local t : word `j' of `tests'
            qui replace lab    = "`v'/`t'"      in `k'
            qui replace stat   = `Bname'_copy[`k',3] in `k'
            qui replace cv5    = `Bname'_copy[`k',4] in `k'
            qui replace reject = `Bname'_copy[`k',7] in `k'
        }
    }

    twoway                                                                   ///
        (scatter id stat if reject==1,                                       ///
            msymbol(O) mcolor("32 119 180") msize(large))                    ///
        (scatter id stat if reject==0,                                       ///
            msymbol(O) mcolor("220 50 50") msize(large))                     ///
        (scatter id cv5,                                                     ///
            msymbol(T) mcolor("80 80 80") msize(medsmall)),                  ///
        ylabel(none) ytitle("")                                              ///
        xtitle("RALS test statistic")                                        ///
        title("RALS complete battery", size(medium))                         ///
        subtitle("Blue = reject H0 at 5%   Red = no reject"                  ///
                 "   Grey triangles = 5% CVs", size(small))                  ///
        legend(off) scheme(s2color)                                          ///
        graphregion(color(white)) plotregion(color(white))                   ///
        name(ralsbattery_all, replace)

    restore
end
