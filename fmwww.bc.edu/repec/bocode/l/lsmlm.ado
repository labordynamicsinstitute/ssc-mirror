*! lsmlm 1.1.0  20jul2026  Ibrahim Ongoren, Pamukkale University
*! Lee-Strazicich minimum LM unit root test with zero, one, or two breaks.
*! Models: crash (level shift) and break (level + trend shift). breaks(0) is
*! the Schmidt-Phillips no-break LM test.
*!
*! General-purpose command: it operates on the current tsset time series
*! (or a series given via timevar()) and can be restricted to any sub-sample
*! with if / in. The test statistic is computed in native Stata (adapted from
*! the author's own ls1break_lm / ls2break_lm routines).
*!
*! Critical values: the interpolated CV tables (interpolation over the sample
*! size T and, for the trend-break model, over the break fraction lambda) are
*! ported from the -leestra- package by H. Ozan Eruygur (SSC s459688), which
*! is distributed under the MIT License. The tables ultimately come from
*! Schmidt & Phillips (1992) and Lee & Strazicich (2003, 2013).
*
* Method (Lee & Strazicich 2003, 2013; Schmidt & Phillips 1992):
*   1) For each candidate break date (pair), regress D.y on the differenced
*      deterministic terms DZ to recover the shift magnitudes, then build the
*      LM-detrended series S(t) (S(1)=0, D.S = residual of D.y on DZ).
*   2) Regress D.y on DZ, S(t-1) and lagged D.S terms; general-to-specific
*      lag selection from maxlag() downward (keep the highest lag with
*      |t| >= 1.645).
*   3) Pick the break date(s) that MINIMISE the t-statistic on S(t-1).
*   4) Compare that minimum statistic to the interpolated LS/SP critical values.
*
* Deterministic terms by model (per break j at index b):
*   impulse B_j = 1{t == b+1},  step D_j = 1{t > b},  trend T_j = (t-b)*1{t>b}
*   crash model : DZ regressors = {const, B_j};        S subtracts level steps
*   break model : DZ regressors = {const, B_j, D_j};   S subtracts level + trend
*   no break    : DZ regressors = {const}

program define lsmlm, rclass
    version 14.0
    syntax varname(numeric) [if] [in] , ///
        [ Breaks(integer 2)          ///
          Model(string)              ///
          MAXLag(integer -1)         ///
          TRim(real 0.10)            ///
          MINDist(integer -1)        ///
          TIMEvar(varname numeric)   ///
          noPRINT ]

    * ---------- validate options ----------
    if "`model'" == "" local model "break"
    if !inlist("`model'", "break", "crash") {
        di as err "model() must be break or crash"
        exit 198
    }
    local mflag = cond("`model'" == "crash", 1, 2)

    if !inlist(`breaks', 0, 1, 2) {
        di as err "breaks() must be 0, 1, or 2"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        di as err "trim() must be in (0, 0.5)"
        exit 198
    }

    * ---------- determine the time variable ----------
    if "`timevar'" == "" {
        cap tsset
        if _rc {
            di as err "data must be tsset, or specify timevar(), before using lsmlm"
            exit 198
        }
        local timevar `r(timevar)'
    }

    marksample touse
    qui replace `touse' = 0 if missing(`varlist') | missing(`timevar')

    preserve
    qui keep if `touse'
    sort `timevar'

    cap qui isid `timevar'
    if _rc {
        di as err "the time variable is not unique in the current sample."
        di as err "lsmlm operates on a single time series: restrict to one panel"
        di as err "unit with if/in (e.g. if id==1), or tsset a single series."
        exit 198
    }

    qui count
    local T = r(N)
    if `T' < 20 {
        di as err "not enough observations after if/in and missing (need ~20+)"
        exit 198
    }

    if `maxlag' < 0 {
        local maxlag = floor(4*(`T'/100)^0.25)
        if `maxlag' < 1 local maxlag = 1
    }
    if `mindist' < 0 local mindist = 2

    tempvar yy tt dy
    qui gen double `yy' = `varlist'
    qui gen long   `tt' = _n
    qui gen double `dy' = `yy' - `yy'[_n-1]

    local lo = ceil(`trim' * `T')
    local hi = floor((1 - `trim') * `T')
    if `lo' < 3 local lo = 3
    if `hi' > `T' - 3 local hi = `T' - 3
    * Collinearity guard: keep the earliest candidate at least maxlag+2 so a
    * level dummy cannot be constant across the lagged-regression sample and
    * collide with the constant.
    if `lo' < `maxlag' + 2 local lo = `maxlag' + 2
    if `breaks' > 0 & `lo' > `hi' {
        di as err "sample too short for the chosen trim() and maxlag(): empty break window"
        exit 198
    }

    * ---------- best-configuration storage ----------
    local best_tau = .
    local best_k = .
    local best_b1 = .
    local best_b2 = .
    local best_year1 = .
    local best_year2 = .
    local best_lam1 = .
    local best_lam2 = .
    local best_tB1 = .
    local best_tB2 = .
    local best_tD1 = .
    local best_tD2 = .
    local best_sig1 = .
    local best_sig2 = .
    local best_N = .

    if `breaks' == 0 {
        * ===================== NO BREAK (Schmidt-Phillips) =====================
        capture drop _ls_S _ls_dS _ls_LS
        capture drop _ls_LdS*
        capture quietly regress `dy' if `tt' > 1
        if !_rc {
            local btrend = _b[_cons]
            local y1  = `yy'[1]
            local psi = `y1' - (`btrend' * 1)
            qui gen double _ls_S  = `yy' - `psi' - (`btrend' * `tt')
            qui gen double _ls_dS = _ls_S - _ls_S[_n-1]
            qui gen double _ls_LS = _ls_S[_n-1]

            local done = 0
            forvalues kk = `maxlag'(-1)0 {
                capture drop _ls_LdS*
                local laglist ""
                if `kk' > 0 {
                    forvalues L = 1/`kk' {
                        qui gen double _ls_LdS`L' = _ls_dS[_n-`L']
                        local laglist "`laglist' _ls_LdS`L'"
                    }
                }
                capture quietly regress `dy' _ls_LS `laglist'
                if !_rc & e(N) > 20 {
                    local tau = _b[_ls_LS] / _se[_ls_LS]
                    if `kk' == 0 {
                        local best_k = 0
                        local best_tau = `tau'
                        local best_N = e(N)
                        local done = 1
                        continue, break
                    }
                    else {
                        local lastvar "_ls_LdS`kk'"
                        local tlast = abs(_b[`lastvar'] / _se[`lastvar'])
                        if `tlast' >= 1.645 {
                            local best_k = `kk'
                            local best_tau = `tau'
                            local best_N = e(N)
                            local done = 1
                            continue, break
                        }
                    }
                }
            }
        }
    }
    else if `breaks' == 1 {
        * ===================== ONE BREAK =====================
        forvalues b1 = `lo'/`hi' {
            capture drop _ls_D1 _ls_T1 _ls_B1 _ls_S _ls_dS _ls_LS
            capture drop _ls_LdS*
            qui gen double _ls_D1 = (`tt' > `b1')
            qui gen double _ls_T1 = (`tt' - `b1') * (`tt' > `b1')
            qui gen double _ls_B1 = (`tt' == `b1' + 1)

            if `mflag' == 2 local dvars "_ls_B1 _ls_D1"
            else            local dvars "_ls_B1"

            capture quietly regress `dy' `dvars' if `tt' > 1
            if !_rc {
                local btrend = _b[_cons]
                local blev1  = _b[_ls_B1]
                local y1  = `yy'[1]
                local psi = `y1' - (`btrend' * 1)
                if `mflag' == 2 {
                    local btr1 = _b[_ls_D1]
                    qui gen double _ls_S = `yy' - `psi' - (`btrend' * `tt') - (`blev1' * _ls_D1) - (`btr1' * _ls_T1)
                }
                else {
                    qui gen double _ls_S = `yy' - `psi' - (`btrend' * `tt') - (`blev1' * _ls_D1)
                }
                qui gen double _ls_dS = _ls_S - _ls_S[_n-1]
                qui gen double _ls_LS = _ls_S[_n-1]

                local final_k = .
                local final_tau = .
                local final_N = .
                local final_tB1 = .
                local final_tD1 = .
                local done = 0

                forvalues kk = `maxlag'(-1)0 {
                    capture drop _ls_LdS*
                    local laglist ""
                    if `kk' > 0 {
                        forvalues L = 1/`kk' {
                            qui gen double _ls_LdS`L' = _ls_dS[_n-`L']
                            local laglist "`laglist' _ls_LdS`L'"
                        }
                    }
                    capture quietly regress `dy' `dvars' _ls_LS `laglist'
                    if !_rc & e(N) > 20 {
                        local tau = _b[_ls_LS] / _se[_ls_LS]
                        local ok = 0
                        if `kk' == 0 local ok = 1
                        else {
                            local lastvar "_ls_LdS`kk'"
                            if abs(_b[`lastvar'] / _se[`lastvar']) >= 1.645 local ok = 1
                        }
                        if `ok' {
                            local final_k = `kk'
                            local final_tau = `tau'
                            local final_N = e(N)
                            local final_tB1 = _b[_ls_B1] / _se[_ls_B1]
                            if `mflag' == 2 local final_tD1 = _b[_ls_D1] / _se[_ls_D1]
                            local done = 1
                            continue, break
                        }
                    }
                }

                if `done' == 1 {
                    if missing(`best_tau') | `final_tau' < `best_tau' {
                        local best_tau = `final_tau'
                        local best_k = `final_k'
                        local best_b1 = `b1'
                        local best_year1 = `timevar'[`b1']
                        local best_lam1 = `b1' / `T'
                        local best_tB1 = `final_tB1'
                        local best_tD1 = `final_tD1'
                        if `mflag' == 2 local best_sig1 = (max(abs(`final_tB1'), abs(`final_tD1')) >= 1.645)
                        else            local best_sig1 = (abs(`final_tB1') >= 1.645)
                        local best_N = `final_N'
                    }
                }
            }
            capture drop _ls_D1 _ls_T1 _ls_B1 _ls_S _ls_dS _ls_LS
            capture drop _ls_LdS*
        }
    }
    else {
        * ===================== TWO BREAKS =====================
        forvalues b1 = `lo'/`hi' {
            forvalues b2 = `lo'/`hi' {
                if (`b2' > `b1' + `mindist') {
                    capture drop _ls_D1 _ls_D2 _ls_T1 _ls_T2 _ls_B1 _ls_B2 _ls_S _ls_dS _ls_LS
                    capture drop _ls_LdS*
                    qui gen double _ls_D1 = (`tt' > `b1')
                    qui gen double _ls_D2 = (`tt' > `b2')
                    qui gen double _ls_T1 = (`tt' - `b1') * (`tt' > `b1')
                    qui gen double _ls_T2 = (`tt' - `b2') * (`tt' > `b2')
                    qui gen double _ls_B1 = (`tt' == `b1' + 1)
                    qui gen double _ls_B2 = (`tt' == `b2' + 1)

                    if `mflag' == 2 local dvars "_ls_B1 _ls_B2 _ls_D1 _ls_D2"
                    else            local dvars "_ls_B1 _ls_B2"

                    capture quietly regress `dy' `dvars' if `tt' > 1
                    if !_rc {
                        local btrend = _b[_cons]
                        local blev1  = _b[_ls_B1]
                        local blev2  = _b[_ls_B2]
                        local y1  = `yy'[1]
                        local psi = `y1' - (`btrend' * 1)
                        if `mflag' == 2 {
                            local btr1 = _b[_ls_D1]
                            local btr2 = _b[_ls_D2]
                            qui gen double _ls_S = `yy' - `psi' - (`btrend' * `tt') - (`blev1' * _ls_D1) - (`blev2' * _ls_D2) - (`btr1' * _ls_T1) - (`btr2' * _ls_T2)
                        }
                        else {
                            qui gen double _ls_S = `yy' - `psi' - (`btrend' * `tt') - (`blev1' * _ls_D1) - (`blev2' * _ls_D2)
                        }
                        qui gen double _ls_dS = _ls_S - _ls_S[_n-1]
                        qui gen double _ls_LS = _ls_S[_n-1]

                        local final_k = .
                        local final_tau = .
                        local final_N = .
                        local final_tB1 = .
                        local final_tB2 = .
                        local final_tD1 = .
                        local final_tD2 = .
                        local done = 0

                        forvalues kk = `maxlag'(-1)0 {
                            capture drop _ls_LdS*
                            local laglist ""
                            if `kk' > 0 {
                                forvalues L = 1/`kk' {
                                    qui gen double _ls_LdS`L' = _ls_dS[_n-`L']
                                    local laglist "`laglist' _ls_LdS`L'"
                                }
                            }
                            capture quietly regress `dy' `dvars' _ls_LS `laglist'
                            if !_rc & e(N) > 20 {
                                local tau = _b[_ls_LS] / _se[_ls_LS]
                                local ok = 0
                                if `kk' == 0 local ok = 1
                                else {
                                    local lastvar "_ls_LdS`kk'"
                                    if abs(_b[`lastvar'] / _se[`lastvar']) >= 1.645 local ok = 1
                                }
                                if `ok' {
                                    local final_k = `kk'
                                    local final_tau = `tau'
                                    local final_N = e(N)
                                    local final_tB1 = _b[_ls_B1] / _se[_ls_B1]
                                    local final_tB2 = _b[_ls_B2] / _se[_ls_B2]
                                    if `mflag' == 2 {
                                        local final_tD1 = _b[_ls_D1] / _se[_ls_D1]
                                        local final_tD2 = _b[_ls_D2] / _se[_ls_D2]
                                    }
                                    local done = 1
                                    continue, break
                                }
                            }
                        }

                        if `done' == 1 {
                            if missing(`best_tau') | `final_tau' < `best_tau' {
                                local best_tau = `final_tau'
                                local best_k = `final_k'
                                local best_b1 = `b1'
                                local best_b2 = `b2'
                                local best_year1 = `timevar'[`b1']
                                local best_year2 = `timevar'[`b2']
                                local best_lam1 = `b1' / `T'
                                local best_lam2 = `b2' / `T'
                                local best_tB1 = `final_tB1'
                                local best_tB2 = `final_tB2'
                                local best_tD1 = `final_tD1'
                                local best_tD2 = `final_tD2'
                                if `mflag' == 2 {
                                    local best_sig1 = (max(abs(`final_tB1'), abs(`final_tD1')) >= 1.645)
                                    local best_sig2 = (max(abs(`final_tB2'), abs(`final_tD2')) >= 1.645)
                                }
                                else {
                                    local best_sig1 = (abs(`final_tB1') >= 1.645)
                                    local best_sig2 = (abs(`final_tB2') >= 1.645)
                                }
                                local best_N = `final_N'
                            }
                        }
                    }
                    capture drop _ls_D1 _ls_D2 _ls_T1 _ls_T2 _ls_B1 _ls_B2 _ls_S _ls_dS _ls_LS
                    capture drop _ls_LdS*
                }
            }
        }
    }

    * ---------- did we find an estimable configuration? ----------
    if missing(`best_tau') {
        di as err "no estimable configuration was found; try a larger sample,"
        di as err "a smaller maxlag(), or a smaller trim()."
        exit 498
    }

    * ---------- break fraction(s): leestra's lag-adjusted convention ----------
    * lambda = (break_index - (k+2)) / (T - (k+2) + 1), matching -leestra- so the
    * CV lookup lands on the same table cell as the reference implementation.
    if `breaks' >= 1 {
        local lower_eff = `best_k' + 2
        local best_lam1 = (`best_b1' - `lower_eff') / (`T' - `lower_eff' + 1)
        if `breaks' == 2 {
            local best_lam2 = (`best_b2' - `lower_eff') / (`T' - `lower_eff' + 1)
        }
    }

    * ---------- interpolated critical values (Mata) ----------
    local lam1arg = cond(missing(`best_lam1'), 0, `best_lam1')
    local lam2arg = cond(missing(`best_lam2'), 0, `best_lam2')
    mata: lsmlm_cvlookup(`breaks', `mflag', `lam1arg', `lam2arg', `best_N')
    local cv1  = r(cv1)
    local cv5  = r(cv5)
    local cv10 = r(cv10)

    local reject10 = (`best_tau' <= `cv10')
    local reject5  = (`best_tau' <= `cv5')
    local reject1  = (`best_tau' <= `cv1')
    local siglevel "Not significant"
    if `reject10' local siglevel "10%"
    if `reject5'  local siglevel "5%"
    if `reject1'  local siglevel "1%"

    * sample range in time units (before dropping the working copy)
    local tmin = `timevar'[1]
    local tmax = `timevar'[`T']
    local fmt : format `timevar'
    if "`fmt'" == "" local fmt "%9.0g"
    local tmintxt = string(`tmin', "`fmt'")
    local tmaxtxt = string(`tmax', "`fmt'")
    if `breaks' >= 1 local b1txt = string(`best_year1', "`fmt'")
    if `breaks' == 2 local b2txt = string(`best_year2', "`fmt'")

    restore

    * ---------- returned results ----------
    return scalar tau       = `best_tau'
    return scalar k         = `best_k'
    return scalar breaks    = `breaks'
    return scalar N         = `best_N'
    return scalar maxlag    = `maxlag'
    return scalar trim      = `trim'
    return scalar cv1       = `cv1'
    return scalar cv5       = `cv5'
    return scalar cv10      = `cv10'
    return scalar reject1   = `reject1'
    return scalar reject5   = `reject5'
    return scalar reject10  = `reject10'
    if `breaks' >= 1 {
        return scalar tb1        = `best_year1'
        return scalar tb1_index  = `best_b1'
        return scalar lambda1    = `best_lam1'
        return scalar break1_sig10 = `best_sig1'
        return scalar tB1        = `best_tB1'
        if `mflag' == 2 return scalar tD1 = `best_tD1'
    }
    if `breaks' == 2 {
        return scalar mindist    = `mindist'
        return scalar tb2        = `best_year2'
        return scalar tb2_index  = `best_b2'
        return scalar lambda2    = `best_lam2'
        return scalar break2_sig10 = `best_sig2'
        return scalar tB2        = `best_tB2'
        if `mflag' == 2 return scalar tD2 = `best_tD2'
    }
    return local siglevel "`siglevel'"
    return local model    "`model'"
    return local timevar  "`timevar'"
    return local varname  "`varlist'"

    * ---------- display ----------
    if "`print'" == "" {
        if `reject10' local decision "Reject unit root at `siglevel'"
        else          local decision "Do not reject unit root"
        local mdesc = cond(`mflag'==2, "trend break (level + trend shift)", "crash (level shift)")
        if `breaks' == 0 local mdesc "no break (Schmidt-Phillips)"

        di
        di as txt "{hline 66}"
        di as res "  Lee-Strazicich minimum LM unit root test"
        di as txt "{hline 66}"
        di as txt "  Series:        " as res "`varlist'"
        di as txt "  Model:         " as res "`mdesc'"
        di as txt "  Breaks:        " as res "`breaks'" as txt "   (endogenously selected)"
        di as txt "  Max lag:       " as res "`maxlag'" as txt "    Lags chosen (GTOS): " as res "`best_k'"
        di as txt "  Obs (regr.):   " as res "`best_N'"
        di as txt "  Sample:        " as res "`tmintxt'" as txt " to " as res "`tmaxtxt'"
        if `breaks' >= 1 {
            di as txt "  Break 1:       " as res "`b1txt'" as txt "   (lambda1 = " as res %5.3f `best_lam1' as txt ")"
        }
        if `breaks' == 2 {
            di as txt "  Break 2:       " as res "`b2txt'" as txt "   (lambda2 = " as res %5.3f `best_lam2' as txt ")"
        }
        di as txt "{hline 66}"
        di as txt "  Test statistic (t on S(t-1)):  " as res %9.4f `best_tau'
        di as txt "  Critical values:   1% " as res %7.3f `cv1' as txt "    5% " as res %7.3f `cv5' as txt "    10% " as res %7.3f `cv10'
        di as txt "  Decision:      " as res "`decision'"
        di as txt "{hline 66}"
        if `breaks' >= 1 {
            di as txt "  Break significance (|t| on dummies >= 1.645):"
            local s1txt = cond(`best_sig1', "significant", "not significant")
            di as txt "    Break 1:     " as res "`s1txt'"
            if `breaks' == 2 {
                local s2txt = cond(`best_sig2', "significant", "not significant")
                di as txt "    Break 2:     " as res "`s2txt'"
            }
            di as txt "{hline 66}"
        }
    }
end


*===========================================================================
* Mata: interpolated critical-value engine.
*
* The CV tables and interpolation routines below are ported from the -leestra-
* package by H. Ozan Eruygur (SSC s459688), distributed under the MIT License.
* Underlying sources: Schmidt & Phillips (1992); Lee & Strazicich (2003, 2013).
*===========================================================================
version 14.0
mata:
mata set matastrict off

real rowvector lsmlm_nlookup()
{
    return((100, 250, 500, 1000))
}

// No break (Schmidt-Phillips)
real matrix lsmlm_cv0()
{
    real matrix M
    M = J(4, 3, .)
    M[1,1] = -3.597; M[1,2] = -3.031; M[1,3] = -2.745
    M[2,1] = -3.572; M[2,2] = -3.023; M[2,3] = -2.747
    M[3,1] = -3.570; M[3,2] = -3.021; M[3,3] = -2.748
    M[4,1] = -3.566; M[4,2] = -3.023; M[4,3] = -2.748
    return(M)
}

// One break, crash model
real matrix lsmlm_cvc1()
{
    real matrix M
    M = J(4, 3, .)
    M[1,1] = -4.084; M[1,2] = -3.487; M[1,3] = -3.185
    M[2,1] = -3.987; M[2,2] = -3.387; M[2,3] = -3.076
    M[3,1] = -3.840; M[3,2] = -3.277; M[3,3] = -2.985
    M[4,1] = -3.798; M[4,2] = -3.230; M[4,3] = -2.925
    return(M)
}

// Two breaks, crash model
real matrix lsmlm_cvc2()
{
    real matrix M
    M = J(4, 3, .)
    M[1,1] = -4.073; M[1,2] = -3.563; M[1,3] = -3.296
    M[2,1] = -4.101; M[2,2] = -3.594; M[2,3] = -3.345
    M[3,1] = -4.261; M[3,2] = -3.647; M[3,3] = -3.287
    M[4,1] = -3.828; M[4,2] = -3.248; M[4,3] = -3.005
    return(M)
}

// One break, break model: 4 sample sizes x 9 lambda = 36 rows
real matrix lsmlm_cvb1()
{
    real matrix M
    M = J(36, 3, .)
    M[1,1]=-4.630; M[1,2]=-4.064; M[1,3]=-3.787
    M[2,1]=-4.704; M[2,2]=-4.132; M[2,3]=-3.843
    M[3,1]=-4.769; M[3,2]=-4.199; M[3,3]=-3.906
    M[4,1]=-4.820; M[4,2]=-4.253; M[4,3]=-3.963
    M[5,1]=-4.857; M[5,2]=-4.293; M[5,3]=-4.008
    M[6,1]=-4.891; M[6,2]=-4.324; M[6,3]=-4.042
    M[7,1]=-4.899; M[7,2]=-4.338; M[7,3]=-4.058
    M[8,1]=-4.910; M[8,2]=-4.348; M[8,3]=-4.071
    M[9,1]=-4.915; M[9,2]=-4.351; M[9,3]=-4.073
    M[10,1]=-4.523; M[10,2]=-3.974; M[10,3]=-3.697
    M[11,1]=-4.536; M[11,2]=-3.982; M[11,3]=-3.702
    M[12,1]=-4.563; M[12,2]=-4.010; M[12,3]=-3.726
    M[13,1]=-4.609; M[13,2]=-4.060; M[13,3]=-3.777
    M[14,1]=-4.647; M[14,2]=-4.098; M[14,3]=-3.819
    M[15,1]=-4.667; M[15,2]=-4.125; M[15,3]=-3.846
    M[16,1]=-4.672; M[16,2]=-4.130; M[16,3]=-3.856
    M[17,1]=-4.681; M[17,2]=-4.144; M[17,3]=-3.870
    M[18,1]=-4.685; M[18,2]=-4.145; M[18,3]=-3.873
    M[19,1]=-4.502; M[19,2]=-3.959; M[19,3]=-3.679
    M[20,1]=-4.489; M[20,2]=-3.944; M[20,3]=-3.664
    M[21,1]=-4.496; M[21,2]=-3.950; M[21,3]=-3.671
    M[22,1]=-4.534; M[22,2]=-3.991; M[22,3]=-3.714
    M[23,1]=-4.570; M[23,2]=-4.031; M[23,3]=-3.756
    M[24,1]=-4.587; M[24,2]=-4.052; M[24,3]=-3.777
    M[25,1]=-4.598; M[25,2]=-4.065; M[25,3]=-3.794
    M[26,1]=-4.612; M[26,2]=-4.081; M[26,3]=-3.809
    M[27,1]=-4.602; M[27,2]=-4.074; M[27,3]=-3.799
    M[28,1]=-4.466; M[28,2]=-3.928; M[28,3]=-3.651
    M[29,1]=-4.455; M[29,2]=-3.919; M[29,3]=-3.640
    M[30,1]=-4.469; M[30,2]=-3.933; M[30,3]=-3.651
    M[31,1]=-4.501; M[31,2]=-3.968; M[31,3]=-3.687
    M[32,1]=-4.523; M[32,2]=-3.993; M[32,3]=-3.713
    M[33,1]=-4.546; M[33,2]=-4.018; M[33,3]=-3.740
    M[34,1]=-4.562; M[34,2]=-4.033; M[34,3]=-3.756
    M[35,1]=-4.576; M[35,2]=-4.049; M[35,3]=-3.773
    M[36,1]=-4.593; M[36,2]=-4.065; M[36,3]=-3.790
    return(M)
}

// Two breaks, break model: 4 sample sizes x 12 = 48 rows
real matrix lsmlm_cvb2()
{
    real matrix M
    M = J(48, 3, .)
    M[1,1]=-6.750; M[1,2]=-6.108; M[1,3]=-5.779
    M[2,1]=-7.196; M[2,2]=-6.312; M[2,3]=-5.893
    M[3,1]=-6.932; M[3,2]=-6.175; M[3,3]=-5.825
    M[4,1]=-7.004; M[4,2]=-6.185; M[4,3]=-5.828
    M[5,1]=-6.691; M[5,2]=-6.152; M[5,3]=-5.798
    M[6,1]=-6.821; M[6,2]=-5.917; M[6,3]=-5.541
    M[7,1]=-6.963; M[7,2]=-6.201; M[7,3]=-5.890
    M[8,1]=-6.821; M[8,2]=-6.166; M[8,3]=-5.832
    M[9,1]=-6.978; M[9,2]=-6.288; M[9,3]=-5.998
    M[10,1]=-7.032; M[10,2]=-6.375; M[10,3]=-6.011
    M[11,1]=-6.863; M[11,2]=-6.268; M[11,3]=-5.956
    M[12,1]=-7.014; M[12,2]=-6.446; M[12,3]=-6.072
    M[13,1]=-5.667; M[13,2]=-5.177; M[13,3]=-4.921
    M[14,1]=-5.974; M[14,2]=-5.342; M[14,3]=-5.004
    M[15,1]=-5.869; M[15,2]=-5.398; M[15,3]=-5.112
    M[16,1]=-6.064; M[16,2]=-5.462; M[16,3]=-5.192
    M[17,1]=-5.957; M[17,2]=-5.374; M[17,3]=-5.104
    M[18,1]=-5.783; M[18,2]=-5.272; M[18,3]=-4.943
    M[19,1]=-5.934; M[19,2]=-5.300; M[19,3]=-4.988
    M[20,1]=-5.771; M[20,2]=-5.357; M[20,3]=-5.032
    M[21,1]=-5.958; M[21,2]=-5.421; M[21,3]=-5.179
    M[22,1]=-5.751; M[22,2]=-5.349; M[22,3]=-5.063
    M[23,1]=-5.971; M[23,2]=-5.264; M[23,3]=-5.018
    M[24,1]=-6.035; M[24,2]=-5.484; M[24,3]=-5.161
    M[25,1]=-5.640; M[25,2]=-4.855; M[25,3]=-4.572
    M[26,1]=-5.392; M[26,2]=-4.939; M[26,3]=-4.691
    M[27,1]=-5.608; M[27,2]=-4.947; M[27,3]=-4.661
    M[28,1]=-5.602; M[28,2]=-5.059; M[28,3]=-4.782
    M[29,1]=-5.533; M[29,2]=-4.989; M[29,3]=-4.752
    M[30,1]=-5.619; M[30,2]=-5.038; M[30,3]=-4.723
    M[31,1]=-5.511; M[31,2]=-4.898; M[31,3]=-4.607
    M[32,1]=-5.494; M[32,2]=-5.035; M[32,3]=-4.742
    M[33,1]=-5.548; M[33,2]=-5.043; M[33,3]=-4.811
    M[34,1]=-5.716; M[34,2]=-5.149; M[34,3]=-4.912
    M[35,1]=-5.509; M[35,2]=-4.963; M[35,3]=-4.674
    M[36,1]=-5.655; M[36,2]=-4.967; M[36,3]=-4.705
    M[37,1]=-5.116; M[37,2]=-4.539; M[37,3]=-4.195
    M[38,1]=-5.240; M[38,2]=-4.578; M[38,3]=-4.278
    M[39,1]=-5.437; M[39,2]=-4.917; M[39,3]=-4.533
    M[40,1]=-5.387; M[40,2]=-4.884; M[40,3]=-4.567
    M[41,1]=-5.099; M[41,2]=-4.716; M[41,3]=-4.481
    M[42,1]=-5.247; M[42,2]=-4.776; M[42,3]=-4.472
    M[43,1]=-5.085; M[43,2]=-4.576; M[43,3]=-4.301
    M[44,1]=-5.209; M[44,2]=-4.697; M[44,3]=-4.398
    M[45,1]=-5.212; M[45,2]=-4.734; M[45,3]=-4.534
    M[46,1]=-5.183; M[46,2]=-4.773; M[46,3]=-4.535
    M[47,1]=-5.100; M[47,2]=-4.699; M[47,3]=-4.364
    M[48,1]=-5.291; M[48,2]=-4.803; M[48,3]=-4.481
    return(M)
}

// Linear interpolation over the sample size T
real rowvector lsmlm_interp_T(real matrix tab, real scalar tnobs)
{
    real rowvector nl, cv
    real scalar i, t1, t2, tw1, tw2
    nl = lsmlm_nlookup()
    t1 = cols(nl); t2 = t1; tw1 = 1; tw2 = 0
    for (i=1; i<=cols(nl); i++) {
        if (tnobs < nl[i]) {
            if (i == 1) {
                t1 = 1; t2 = 1; tw1 = 1; tw2 = 0
            }
            else {
                tw1 = (tnobs - nl[i-1]) / (nl[i] - nl[i-1])
                t1  = i-1
                tw2 = 1 - tw1
                t2  = i
            }
            break
        }
    }
    cv = tw1 * tab[t1,.] + tw2 * tab[t2,.]
    return(cv)
}

// One break, break model: interpolate over lambda then T
real rowvector lsmlm_interp_cvb1(real scalar lambda, real scalar tnobs)
{
    real rowvector bp, nl, cv
    real scalar i, i1, i2, w1, w2, lam, off
    real matrix M, cv1
    bp = (.10, .15, .20, .25, .30, .35, .40, .45, .50)
    nl = lsmlm_nlookup()
    M  = lsmlm_cvb1()
    lam = lambda
    if (lam > 0.5) lam = 1 - lam
    i1 = 1; i2 = 1; w1 = 1; w2 = 0
    if (lam <= bp[1]) {
        i1 = 1; i2 = 1; w1 = 1; w2 = 0
    }
    else if (lam >= bp[cols(bp)]) {
        i1 = cols(bp); i2 = i1; w1 = 1; w2 = 0
    }
    else {
        for (i=2; i<=cols(bp); i++) {
            if (lam < bp[i]) {
                w2 = (lam - bp[i-1]) / (bp[i] - bp[i-1])
                w1 = 1 - w2
                i1 = i-1
                i2 = i
                break
            }
        }
    }
    cv1 = J(cols(nl), 3, .)
    for (i=1; i<=cols(nl); i++) {
        off = (i-1)*9
        cv1[i,.] = w1 * M[off+i1,.] + w2 * M[off+i2,.]
    }
    cv = lsmlm_interp_T(cv1, tnobs)
    return(cv)
}

// Two breaks, break model: nearest (lambda1,lambda2) cell then interpolate T
real rowvector lsmlm_interp_cvb2(real scalar lam1, real scalar lam2, real scalar tnobs)
{
    real rowvector bp, nl, cv
    real scalar i, i1, i2, lambda1, lambda2, temp, idx, off, b1, b2
    real matrix M, cv1
    bp = (.20, .30, .40, .50, .60, .70, .80)
    nl = lsmlm_nlookup()
    M  = lsmlm_cvb2()

    lambda1 = lam1
    lambda2 = lam2
    if (lambda1 + lambda2 >= 1.0) {
        temp    = lambda1
        lambda1 = 1 - lambda2
        lambda2 = 1 - temp
    }

    b1 = 1; b2 = 1; i1 = 1; i2 = 1
    for (i=1; i<=cols(bp); i++) {
        if (abs(lambda1 - bp[i]) < b1) {
            i1 = i
            b1 = abs(lambda1 - bp[i])
        }
        if (abs(lambda2 - bp[i]) < b2) {
            i2 = i
            b2 = abs(lambda2 - bp[i])
        }
    }
    if (i1 == i2) {
        if (i1 == 1) {
            i2 = i1 + 1
        }
        else if (i1 == cols(bp)) {
            i1 = i2 - 1
        }
        else if ((lambda1 - bp[i1]) + (lambda2 - bp[i2]) > 0) {
            i2 = i1 + 1
        }
        else {
            i1 = i2 - 1
        }
    }

    idx = (cols(bp) - i1) * (i1 - 1) + i2 - 1
    if (idx < 1)  idx = 1
    if (idx > 12) idx = 12

    cv1 = J(cols(nl), 3, .)
    for (i=1; i<=cols(nl); i++) {
        off = (i-1)*12
        cv1[i,.] = M[off+idx,.]
    }
    cv = lsmlm_interp_T(cv1, tnobs)
    return(cv)
}

// Dispatcher: pick the right table given breaks/model, write CVs to r()
void lsmlm_cvlookup(real scalar breaks, real scalar model, real scalar lam1, real scalar lam2, real scalar tnobs)
{
    real rowvector cv
    if (breaks == 0) {
        cv = lsmlm_interp_T(lsmlm_cv0(), tnobs)
    }
    else if (breaks == 1 & model == 1) {
        cv = lsmlm_interp_T(lsmlm_cvc1(), tnobs)
    }
    else if (breaks == 2 & model == 1) {
        cv = lsmlm_interp_T(lsmlm_cvc2(), tnobs)
    }
    else if (breaks == 1 & model == 2) {
        cv = lsmlm_interp_cvb1(lam1, tnobs)
    }
    else if (breaks == 2 & model == 2) {
        cv = lsmlm_interp_cvb2(lam1, lam2, tnobs)
    }
    else {
        cv = J(1, 3, .)
    }
    st_numscalar("r(cv1)",  cv[1])
    st_numscalar("r(cv5)",  cv[2])
    st_numscalar("r(cv10)", cv[3])
}

end
