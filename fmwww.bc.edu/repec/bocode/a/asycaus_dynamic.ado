*! asycaus_dynamic v1.0.0  24may2026
*! Hatemi-J (2021) Dynamic Asymmetric Causality (rolling / recursive subsamples)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define asycaus_dynamic, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [,    ///
          MAXLag(integer 4)         ///
          IC(string)                ///
          INTOrder(integer 1)       ///
          SHOCK(string)             ///
          TRend(string)             ///
          WINDow(integer 0)         ///
          ROLLing                   ///
          RECursive                 ///
          BOOT(integer 200)         ///
          SEED(integer 12345)       ///
          LNform                    ///
          noGRAPH                   ///
          SAVing(string)            ///
        ]

    _asycaus_check_tsset
    marksample touse

    tokenize `varlist'
    local depvar  `1'
    local causvar `2'
    if "`ic'" == "" local ic hjc
    _asycaus_iccode `ic'
    local icnum = r(ic)
    if "`shock'" == "" local shock pos
    local shock = lower("`shock'")
    if !inlist("`shock'", "pos", "positive", "neg", "negative") {
        di as err "shock() must be {bf:pos} or {bf:neg}"
        exit 198
    }
    if "`trend'" == "" local trend none
    local trend = lower("`trend'")
    if !inlist("`trend'", "none", "drift", "both") {
        di as err "trend() must be {bf:none}, {bf:drift}, or {bf:both}"
        exit 198
    }
    local tcode = cond("`trend'"=="both", 2, cond("`trend'"=="drift", 1, 0))
    if "`rolling'" == "" & "`recursive'" == "" local rolling rolling
    if "`rolling'" != "" & "`recursive'" != "" {
        di as err "specify only one of {bf:rolling} or {bf:recursive}"
        exit 198
    }

    qui keep if `touse'
    qui count
    local T = r(N)

    // Build positive/negative cumulative components
    local pflag = cond(inlist("`shock'", "pos", "positive"), 1, 0)
    tempname Yraw
    qui mkmat `depvar' `causvar', matrix(`Yraw')
    if "`lnform'" != "" {
        mata: st_matrix("Yraw_log", log(st_matrix("`Yraw'")))
        mata: st_matrix("Zfull", asycaus_pos_neg_trend(st_matrix("Yraw_log"), `pflag', `tcode'))
    }
    else {
        mata: st_matrix("Zfull", asycaus_pos_neg_trend(st_matrix("`Yraw'"), `pflag', `tcode'))
    }
    local Tcomp = rowsof(Zfull)
    if `Tcomp' < 10 {
        di as err "too few observations after differencing"
        exit 2001
    }

    // Minimum subsample size (Phillips et al. 2015 / Hatemi-J 2021)
    local Smin = ceil(`Tcomp' * (0.01 + 1.8/sqrt(`Tcomp')))
    if `window' == 0 local window `Smin'
    if `window' < (`maxlag' + `intorder' + 3) {
        di as err "window() must be at least " (`maxlag' + `intorder' + 3)
        exit 198
    }

    local nsub = `Tcomp' - `window' + 1
    if `nsub' < 1 {
        di as err "window() too large for sample"
        exit 2001
    }

    // Storage
    tempname Out
    matrix `Out' = J(`nsub', 8, .)
    matrix colnames `Out' = sub_start sub_end lag Wald cv10 cv5 cv1 ratio5

    local sample_type = cond("`rolling'" != "", "Rolling window", "Recursive")
    local stitle = cond(`pflag', "Positive components", "Negative components")

    _asycaus_header "Dynamic Asymmetric Causality — Hatemi-J (2021)"
    di as txt _col(2) "H0: " as res "`causvar'" as txt " does not Granger-cause " as res "`depvar'" as txt " (`stitle')"
    di as txt _col(2) "Subsample mode:           " as res "`sample_type'"
    di as txt _col(2) "Window length S:          " as res "`window'"  as txt _col(40) "Min. window (Phillips et al.): " as res "`Smin'"
    di as txt _col(2) "Lag selection:            " as res "`=upper("`ic'")'" as txt _col(40) "Augmentation lags:             " as res "`intorder'"
    local trlab = cond("`trend'"=="both","Drift + trend (2016)", cond("`trend'"=="drift","Drift (2016)","None (Granger-Yoon)"))
    di as txt _col(2) "Component transformation:  " as res "`trlab'"
    di as txt _col(2) "Bootstrap reps per win.:  " as res "`boot'"
    di as txt "{hline 78}"
    di as txt _col(2) "Estimating " as res "`nsub'" as txt " subsamples..."  _continue
    di ""

    forvalues k = 1/`nsub' {
        if mod(`k', 10) == 0  di as txt "  subsample " as res `k' as txt " / " as res `nsub'
        if "`rolling'" != "" {
            local s = `k'
            local e = `k' + `window' - 1
        }
        else {
            local s = 1
            local e = `window' + `k' - 1
        }

        // Slice Zfull
        mata: st_matrix("Zsub", st_matrix("Zfull")[`s'..`e', .])
        mata: st_local("p_opt", strofreal( ///
            asycaus_lag_select(st_matrix("Zsub"), 1, `maxlag', `icnum')))
        local p `p_opt'
        mata: st_matrix("wres", asycaus_wald(st_matrix("Zsub"), `p', ///
            `intorder', 1, 2))
        local W = wres[1,1]
        mata: st_matrix("cv", asycaus_boot_cv(st_matrix("Zsub"), `p', ///
            `intorder', 1, 2, `boot', `seed' + `k'))
        local c1  = cv[1,1]
        local c5  = cv[1,2]
        local c10 = cv[1,3]
        matrix `Out'[`k', 1] = `s'
        matrix `Out'[`k', 2] = `e'
        matrix `Out'[`k', 3] = `p'
        matrix `Out'[`k', 4] = `W'
        matrix `Out'[`k', 5] = `c10'
        matrix `Out'[`k', 6] = `c5'
        matrix `Out'[`k', 7] = `c1'
        matrix `Out'[`k', 8] = `W' / `c5'
    }

    // Compact summary table (head, tail, and rejections)
    di as txt "{hline 78}"
    di as txt _col(2) "Time-Varying Causality Test Results (every 10th subsample shown)"
    di as txt "{hline 78}"
    di as txt _col(2) "{ralign 8:SS End}" ///
              _col(11) "{ralign 5:Lag}" ///
              _col(17) "{ralign 11:Wald}" ///
              _col(29) "{ralign 11:CV 10%}" ///
              _col(41) "{ralign 11:CV 5%}" ///
              _col(53) "{ralign 11:CV 1%}" ///
              _col(65) "{ralign 11:W/CV5%}"
    di as txt "{hline 78}"
    forvalues k = 1/`nsub' {
        if mod(`k', 10) == 1 | `k' == `nsub' {
            local e = `Out'[`k', 2]
            local p = `Out'[`k', 3]
            local W = `Out'[`k', 4]
            local c10 = `Out'[`k', 5]
            local c5  = `Out'[`k', 6]
            local c1  = `Out'[`k', 7]
            local rr  = `Out'[`k', 8]
            local mark = cond(`rr' > 1, "*", " ")
            di as res _col(2) %8.0f `e' ///
                      _col(11) %5.0f `p' ///
                      _col(17) %11.4f `W' ///
                      _col(29) %11.4f `c10' ///
                      _col(41) %11.4f `c5' ///
                      _col(53) %11.4f `c1' ///
                      _col(65) %11.4f `rr' " " "`mark'"
        }
    }
    di as txt "{hline 78}"
    // Count rejections
    tempname rej5 rej10 rej1
    scalar `rej5'  = 0
    scalar `rej10' = 0
    scalar `rej1'  = 0
    forvalues k = 1/`nsub' {
        if `Out'[`k', 4] > `Out'[`k', 5] scalar `rej10' = `rej10' + 1
        if `Out'[`k', 4] > `Out'[`k', 6] scalar `rej5'  = `rej5'  + 1
        if `Out'[`k', 4] > `Out'[`k', 7] scalar `rej1'  = `rej1'  + 1
    }
    di as txt _col(2) "Subsamples rejecting H0: " ///
              as res %3.0f `rej1' as txt " at 1%, " ///
              as res %3.0f `rej5' as txt " at 5%, " ///
              as res %3.0f `rej10' as txt " at 10%  (of " as res "`nsub'" as txt " windows)"
    _asycaus_footer

    // ----------- GRAPH -----------
    if "`graph'" != "nograph" {
        _asycaus_dynamic_graph `"`Out'"' "`depvar'" "`causvar'" "`sample_type'" "`stitle'" `"`saving'"'
    }

    return matrix results = `Out'
    return scalar nsub = `nsub'
    return scalar window = `window'
    return scalar Smin = `Smin'
    return local  mode  "`sample_type'"
    return local  shock "`shock'"
    return local  depvar "`depvar'"
    return local  cause  "`causvar'"
    return local  test "Hatemi-J (2021) Dynamic Asymmetric Causality"
end


program define _asycaus_dynamic_graph
    args results dep cause mode stitle saving
    tempname B
    matrix `B' = `results'
    local nrow = rowsof(`B')

    preserve
    qui drop _all
    qui set obs `nrow'
    qui gen long sub_end = .
    qui gen double Wald  = .
    qui gen double cv5   = .
    qui gen double cv10  = .
    qui gen double cv1   = .
    forvalues i = 1/`nrow' {
        qui replace sub_end = `B'[`i', 2] in `i'
        qui replace Wald    = `B'[`i', 4] in `i'
        qui replace cv10    = `B'[`i', 5] in `i'
        qui replace cv5     = `B'[`i', 6] in `i'
        qui replace cv1     = `B'[`i', 7] in `i'
    }
    local note = `"Note: `mode' subsamples, leverage-adjusted bootstrap CVs.  H0: `cause' does not Granger-cause `dep'."'

    twoway ///
        (line Wald sub_end, lcolor(navy) lwidth(medthick)) ///
        (line cv10 sub_end, lcolor(green)    lpattern(dot)) ///
        (line cv5  sub_end, lcolor(orange)   lpattern(dash)) ///
        (line cv1  sub_end, lcolor(cranberry) lpattern(longdash)) ///
        , ytitle("Wald statistic") ///
          xtitle("Subsample end (time index)") ///
          title("Dynamic Asymmetric Causality: {it:`cause'} → {it:`dep'}", size(medium)) ///
          subtitle("`stitle' — Hatemi-J (2021)", size(small)) ///
          legend(order(1 "Wald" 2 "10% CV" 3 "5% CV" 4 "1% CV") rows(1) region(lcolor(none))) ///
          note(`"`note'"', size(vsmall)) ///
          graphregion(color(white)) plotregion(lcolor(black)) ///
          scheme(s1color) name(asycaus_dynamic, replace)
    restore

    if `"`saving'"' != "" {
        graph save asycaus_dynamic `"`saving'"', replace
    }
end
