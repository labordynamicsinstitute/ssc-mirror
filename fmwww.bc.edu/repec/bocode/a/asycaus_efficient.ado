*! asycaus_efficient v1.0.0  24may2026
*! Efficient Asymmetric Causality Tests (Hatemi-J 2024 — arXiv 2408.03137)
*! Joint SUR system over positive and negative components: tests
*!     (i) no causality via positive shocks,
*!     (ii) no causality via negative shocks,
*!     (iii) joint no causality,
*!     (iv) equality of positive vs negative causal parameters.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define asycaus_efficient, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [,    ///
          MAXLag(integer 8)         ///
          IC(string)                ///
          INTOrder(integer 1)       ///
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

    qui keep if `touse'
    tempname Yraw
    qui mkmat `depvar' `causvar', matrix(`Yraw')
    if "`lnform'" != "" mata: st_matrix("`Yraw'", log(st_matrix("`Yraw'")))

    mata: st_matrix("Zpos", asycaus_pos_neg(st_matrix("`Yraw'"), 1))
    mata: st_matrix("Zneg", asycaus_pos_neg(st_matrix("`Yraw'"), 0))

    // Choose a common lag: pick the larger of the two HJC choices
    mata: st_local("p_pos", strofreal( ///
        asycaus_lag_select(st_matrix("Zpos"), 1, `maxlag', `icnum')))
    mata: st_local("p_neg", strofreal( ///
        asycaus_lag_select(st_matrix("Zneg"), 1, `maxlag', `icnum')))
    local p = max(`p_pos', `p_neg')

    mata: st_matrix("eff", asycaus_efficient( ///
        st_matrix("Zpos"), st_matrix("Zneg"), `p', `intorder', 1, 2))

    local Wp     = eff[1, 1]
    local Wn     = eff[1, 2]
    local Wjoint = eff[1, 3]
    local Wdiff  = eff[1, 4]
    local dof    = eff[1, 5]

    local pPos   = chi2tail(`dof', `Wp')
    local pNeg   = chi2tail(`dof', `Wn')
    local pJoint = chi2tail(2*`dof', `Wjoint')
    local pDiff  = chi2tail(`dof', `Wdiff')

    _asycaus_header "Efficient Asymmetric Causality Tests — Hatemi-J (2024)"
    di as txt _col(2) "H0: " as res "`causvar'" as txt " does not Granger-cause " as res "`depvar'"
    di as txt _col(2) "Reference: Hatemi-J (2024) arXiv:2408.03137 — SUR-based efficient tests"
    di as txt _col(2) "Lag selection:           " as res "`=upper("`ic'")'" as txt _col(40) "Common lag p:       " as res "`p'"
    di as txt _col(2) "Augmentation lags:       " as res "`intorder'"
    di as txt "{hline 78}"
    di as txt _col(2) "{ralign 28:Null hypothesis}" ///
              _col(33) "{ralign 11:Wald}" ///
              _col(45) "{ralign 5:df}" ///
              _col(52) "{ralign 11:Asy p-val}" ///
              _col(65) "Decision"
    di as txt "{hline 78}"

    local hyp1 "No causality via POS shocks"
    local hyp2 "No causality via NEG shocks"
    local hyp3 "Joint no causality"
    local hyp4 "POS = NEG causal effects"

    local d1 = cond(`pPos'   < 0.05, "Reject", "Fail to reject")
    local d2 = cond(`pNeg'   < 0.05, "Reject", "Fail to reject")
    local d3 = cond(`pJoint' < 0.05, "Reject", "Fail to reject")
    local d4 = cond(`pDiff'  < 0.05, "Reject", "Fail to reject")

    forvalues j = 1/4 {
        local hyp = `"`hyp`j''"'
        if `j' == 1 {
            local W   = `Wp'
            local pv  = `pPos'
            local df  = `dof'
            local dd  "`d1'"
        }
        else if `j' == 2 {
            local W   = `Wn'
            local pv  = `pNeg'
            local df  = `dof'
            local dd  "`d2'"
        }
        else if `j' == 3 {
            local W   = `Wjoint'
            local pv  = `pJoint'
            local df  = 2*`dof'
            local dd  "`d3'"
        }
        else if `j' == 4 {
            local W   = `Wdiff'
            local pv  = `pDiff'
            local df  = `dof'
            local dd  "`d4'"
        }
        local star = ""
        if `pv' < 0.01            local star "***"
        else if `pv' < 0.05       local star "**"
        else if `pv' < 0.10       local star "*"
        di as res _col(2) "{ralign 28:`hyp'}" ///
                  _col(33) %11.4f `W' ///
                  _col(45) %5.0f `df' ///
                  _col(52) %11.4f `pv' "  " "`star'" ///
                  _col(65) "`dd'"
    }
    di as txt "{hline 78}"
    di as txt _col(2) "Significance: * 10%   ** 5%   *** 1%"
    di as txt _col(2) "Hypothesis 4 (POS=NEG) is the key {it:asymmetry} test introduced by Hatemi-J (2024)."
    _asycaus_footer

    if "`graph'" != "nograph" {
        _asycaus_efficient_graph `Wp' `Wn' `Wjoint' `Wdiff' `pPos' `pNeg' `pJoint' `pDiff' "`depvar'" "`causvar'" `"`saving'"'
    }

    return scalar Wpos     = `Wp'
    return scalar Wneg     = `Wn'
    return scalar Wjoint   = `Wjoint'
    return scalar Wdiff    = `Wdiff'
    return scalar p_pos    = `pPos'
    return scalar p_neg    = `pNeg'
    return scalar p_joint  = `pJoint'
    return scalar p_diff   = `pDiff'
    return scalar dof      = `dof'
    return local  test "Hatemi-J (2024) Efficient Asymmetric Causality"
end


program define _asycaus_efficient_graph
    args Wp Wn Wjoint Wdiff pPos pNeg pJoint pDiff dep cause saving

    preserve
    qui drop _all
    qui set obs 4
    qui gen str25 hyp = ""
    qui gen double Wald = .
    qui gen double pval = .
    qui replace hyp = "Pos only"       in 1
    qui replace hyp = "Neg only"       in 2
    qui replace hyp = "Joint"          in 3
    qui replace hyp = "Diff (Pos=Neg)" in 4
    qui replace Wald = `Wp'     in 1
    qui replace Wald = `Wn'     in 2
    qui replace Wald = `Wjoint' in 3
    qui replace Wald = `Wdiff'  in 4
    qui replace pval = `pPos'    in 1
    qui replace pval = `pNeg'    in 2
    qui replace pval = `pJoint'  in 3
    qui replace pval = `pDiff'   in 4
    qui gen idx = _n
    qui gen str10 pstr = string(pval, "%5.3f")

    // bar charts in Stata do NOT support mlabel(); we overlay an invisible
    // scatter that does, to label each bar with its asymptotic p-value.
    twoway ///
        (bar Wald idx, barwidth(0.55) fcolor(navy*0.7) lcolor(navy)) ///
        (scatter Wald idx, msymbol(none) mlabel(pstr) mlabcolor(black) ///
                           mlabposition(12) mlabsize(small)) ///
        , xlabel(1 "Pos only" 2 "Neg only" 3 "Joint" 4 "Diff", noticks) ///
          ytitle("Wald statistic") xtitle("") ///
          title("Efficient Asymmetric Tests: {it:`cause'} -> {it:`dep'}", size(medium)) ///
          subtitle("Hatemi-J (2024) -- SUR-based", size(small)) ///
          note("Bars labelled with asymptotic p-values. Diff tests POS = NEG causal coefficients.", size(vsmall)) ///
          legend(off) ///
          graphregion(color(white)) plotregion(lcolor(black)) ///
          scheme(s1color) name(asycaus_efficient, replace)
    restore
    if `"`saving'"' != "" graph save asycaus_efficient `"`saving'"', replace
end
