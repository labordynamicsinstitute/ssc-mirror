*! asycaus_static v1.0.0  24may2026
*! Hatemi-J (2012) Asymmetric Causality Test with leverage bootstrap (Hacker-Hatemi-J 2006)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define asycaus_static, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [, MAXLag(integer 8) IC(string) INTOrder(integer 1) SHOCK(string) BOOT(integer 1000) SEED(integer 12345) LNform noGRAPH SAVing(string) ]
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
    if !inlist("`shock'", "pos", "positive", "neg", "negative", "both") {
        di as err "shock() must be one of: pos | neg | both"
        exit 198
    }

    // Extract numeric matrix into Mata
    qui keep if `touse'
    if "`lnform'" != "" {
        tempvar _ld _lc
        qui gen double `_ld' = ln(`depvar')
        qui gen double `_lc' = ln(`causvar')
        tempname Yraw
        qui mkmat `_ld' `_lc', matrix(`Yraw')
    }
    else {
        tempname Yraw
        qui mkmat `depvar' `causvar', matrix(`Yraw')
    }

    // Loop over chosen shocks
    local shocks
    if inlist("`shock'", "pos", "positive", "both") local shocks `shocks' pos
    if inlist("`shock'", "neg", "negative", "both") local shocks `shocks' neg
    local nshocks : word count `shocks'

    // Storage for output table (one row per shock)
    tempname Restab
    matrix `Restab' = J(`nshocks', 6, .)

    local rowlabs ""
    local idx = 0

    foreach s of local shocks {
        local ++idx
        local pflag = cond("`s'" == "pos", 1, 0)
        local stitle = cond("`s'" == "pos", "POSITIVE", "NEGATIVE")
        mata: st_matrix("Zcomp", asycaus_pos_neg(st_matrix("`Yraw'"), `pflag'))
        mata: st_local("nn", strofreal(rows(st_matrix("Zcomp"))))

        // Select lag via chosen IC
        mata: st_local("p_opt", strofreal( ///
            asycaus_lag_select(st_matrix("Zcomp"), 1, `maxlag', `icnum')))
        local p = `p_opt'

        // H0: causvar (col 2) does NOT cause depvar (col 1)
        mata: st_matrix("wres", asycaus_wald(st_matrix("Zcomp"), `p', ///
            `intorder', 1, 2))
        local W   = wres[1,1]
        local dof = wres[1,2]

        // Bootstrap critical values
        mata: st_matrix("cv", asycaus_boot_cv(st_matrix("Zcomp"), `p', ///
            `intorder', 1, 2, `boot', `seed'))
        local cv1  = cv[1,1]
        local cv5  = cv[1,2]
        local cv10 = cv[1,3]

        // Asymptotic p-value
        local pchi = chi2tail(`dof', `W')

        // Fill row idx in result matrix
        matrix `Restab'[`idx', 1] = `W'
        matrix `Restab'[`idx', 2] = `p'
        matrix `Restab'[`idx', 3] = `dof'
        matrix `Restab'[`idx', 4] = `cv10'
        matrix `Restab'[`idx', 5] = `cv5'
        matrix `Restab'[`idx', 6] = `cv1'
        local rowlabs `"`rowlabs' "`stitle'""'
    }

    // ----------- PROFESSIONAL TABLE -----------
    _asycaus_header "Asymmetric Causality Test  —  Hatemi-J (2012)"
    di as txt _col(2) "H0: " as res "`causvar'" as txt " does not Granger-cause " as res "`depvar'"
    di as txt _col(2) "Lag selection:                          " as res "`=upper("`ic'")'"
    di as txt _col(2) "Augmentation lags (max integration):    " as res "`intorder'"
    di as txt _col(2) "Bootstrap replications:                 " as res "`boot'"
    di as txt _col(2) "Sample size (after differencing):       " as res "`nn'"
    di as txt "{hline 78}"

    di as txt _col(2) "{ralign 10:Shock}" ///
              _col(15) "{ralign 11:Wald}" ///
              _col(27) "{ralign 5:Lag}" ///
              _col(33) "{ralign 11:Asy p-val}" ///
              _col(46) "{ralign 10:CV 10%}" ///
              _col(57) "{ralign 10:CV 5%}" ///
              _col(68) "{ralign 10:CV 1%}"
    di as txt "{hline 78}"
    local i = 1
    foreach s of local shocks {
        local W   = `Restab'[`i', 1]
        local p   = `Restab'[`i', 2]
        local dof = `Restab'[`i', 3]
        local c10 = `Restab'[`i', 4]
        local c5  = `Restab'[`i', 5]
        local c1  = `Restab'[`i', 6]
        local pchi = chi2tail(`dof', `W')
        local lbl  = cond("`s'" == "pos", "Positive", "Negative")
        local star = ""
        if `W' > `c1'      local star "***"
        else if `W' > `c5' local star "**"
        else if `W' > `c10' local star "*"
        di as res _col(2) "{ralign 10:`lbl'}" ///
                  _col(15) %11.4f `W' ///
                  _col(27) %5.0f `p' ///
                  _col(33) %11.4f `pchi' ///
                  _col(46) %10.4f `c10' ///
                  _col(57) %10.4f `c5' ///
                  _col(68) %10.4f `c1' " " "`star'"
        local i = `i' + 1
    }
    di as txt "{hline 78}"
    di as txt _col(2) "Significance: * 10%   ** 5%   *** 1%  (leverage-adjusted bootstrap CVs)"
    di as txt _col(2) "Reject H0 if Wald > bootstrap CV at the chosen level."
    _asycaus_footer

    // ----------- GRAPH -----------
    if "`graph'" != "nograph" {
        _asycaus_static_graph `"`Restab'"' `"`shocks'"' "`depvar'" "`causvar'" `"`saving'"'
    }

    // Return
    return matrix results = `Restab'
    return scalar boot   = `boot'
    return scalar maxlag = `maxlag'
    return local  shock  "`shock'"
    return local  ic     "`ic'"
    return local  depvar "`depvar'"
    return local  cause  "`causvar'"
    return local  test   "Hatemi-J (2012) Asymmetric Causality"
end


program define _asycaus_static_graph
    args results shocks dep cause saving
    tempname B
    matrix `B' = `results'
    local nrow = rowsof(`B')

    preserve
    qui drop _all
    qui set obs `nrow'
    qui gen str10 shock = ""
    qui gen double Wald = .
    qui gen double cv10 = .
    qui gen double cv5  = .
    qui gen double cv1  = .
    local i 1
    foreach s of local shocks {
        local lbl = cond("`s'" == "pos", "Positive", "Negative")
        qui replace shock = "`lbl'" in `i'
        qui replace Wald  = `B'[`i', 1] in `i'
        qui replace cv10  = `B'[`i', 4] in `i'
        qui replace cv5   = `B'[`i', 5] in `i'
        qui replace cv1   = `B'[`i', 6] in `i'
        local i = `i' + 1
    }
    qui gen idx = _n
    label define _shk 1 "Positive" 2 "Negative"

    local note = `"Note: Bootstrap critical values (leverage-adjusted) at 10%, 5% and 1%. Reference: Hatemi-J (2012)."'

    twoway ///
        (bar Wald idx, barwidth(0.55) fcolor(navy*0.7) lcolor(navy)) ///
        (scatter cv10 idx, msymbol(diamond) mcolor(green) msize(small)) ///
        (scatter cv5  idx, msymbol(triangle) mcolor(orange) msize(small)) ///
        (scatter cv1  idx, msymbol(X) mcolor(cranberry) msize(small)) ///
        , xlabel(1 "Positive" 2 "Negative", noticks) ///
          legend(order(1 "Wald statistic" 2 "10% CV" 3 "5% CV" 4 "1% CV") ///
                 rows(1) region(lcolor(none))) ///
          ytitle("Test statistic") ///
          xtitle("") ///
          title("Asymmetric Causality: {it:`cause'} → {it:`dep'}", size(medium)) ///
          subtitle("Hatemi-J (2012) — leverage bootstrap CVs", size(small)) ///
          note(`"`note'"', size(vsmall)) ///
          graphregion(color(white)) plotregion(lcolor(black)) ///
          scheme(s1color) name(asycaus_static, replace)
    restore

    if `"`saving'"' != "" {
        graph save asycaus_static `"`saving'"', replace
    }
end
