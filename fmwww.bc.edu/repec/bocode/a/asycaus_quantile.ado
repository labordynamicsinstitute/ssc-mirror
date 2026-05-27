*! asycaus_quantile v1.0.0  24may2026
*! Quantile Asymmetric Causality (Fang, Wang, Shieh & Chung 2026)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define asycaus_quantile, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [,    ///
          MAXLag(integer 4)         ///
          IC(string)                ///
          INTOrder(integer 1)       ///
          SHOCK(string)             ///
          Quantiles(numlist >0 <1 sort)  ///
          FOURIER                   ///
          KMAX(integer 3)           ///
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

    if "`shock'" == "" local shock both
    local shock = lower("`shock'")
    if !inlist("`shock'", "pos", "positive", "neg", "negative", "both") {
        di as err "shock() must be {bf:pos}, {bf:neg}, or {bf:both}"
        exit 198
    }
    if "`quantiles'" == "" local quantiles 0.1 0.25 0.5 0.75 0.9

    qui keep if `touse'
    tempname Yraw
    qui mkmat `depvar' `causvar', matrix(`Yraw')
    if "`lnform'" != "" mata: st_matrix("`Yraw'", log(st_matrix("`Yraw'")))

    local shocks
    if inlist("`shock'", "pos", "positive", "both") local shocks `shocks' pos
    if inlist("`shock'", "neg", "negative", "both") local shocks `shocks' neg

    // Storage: rows = shock x quantile
    tempname Q

    _asycaus_header "Quantile Asymmetric Causality"
    di as txt _col(2) "H0: " as res "`causvar'" as txt " does not Granger-cause " as res "`depvar'"
    di as txt _col(2) "Reference: Fang, Wang, Shieh & Chung (2026)"
    if "`fourier'" != "" {
        di as txt _col(2) "Fourier augmentation:    " as res "yes (k=`kmax')"
    }
    di as txt _col(2) "Lag selection:           " as res "`=upper("`ic'")'"
    di as txt _col(2) "Augmentation lags:       " as res "`intorder'"
    di as txt _col(2) "Quantiles (tau):             " as res "`quantiles'"
    di as txt "{hline 78}"
    di as txt _col(2) "{ralign 10:Shock}" ///
              _col(15) "{ralign 6:tau}" ///
              _col(24) "{ralign 11:Wald}" ///
              _col(36) "{ralign 5:Lag}" ///
              _col(43) "{ralign 11:Asy p-val}" ///
              _col(57) "Reject 5%"
    di as txt "{hline 78}"

    local sidx 0
    foreach s of local shocks {
        local sidx = `sidx' + 1
        local pflag = cond("`s'" == "pos", 1, 0)
        mata: st_matrix("Zcomp", asycaus_pos_neg(st_matrix("`Yraw'"), `pflag'))
        mata: st_local("p_opt", strofreal( ///
            asycaus_lag_select(st_matrix("Zcomp"), 1, `maxlag', `icnum')))
        local p `p_opt'
        // optional Fourier detrending: subtract sinusoidal fit before
        // quantile causality
        if "`fourier'" != "" {
            mata: asycaus_qfourier_detrend(`kmax')
        }
        local lbl = cond("`s'" == "pos", "Positive", "Negative")
        foreach tau of local quantiles {
            mata: st_matrix("wres", asycaus_wald_quant( ///
                st_matrix("Zcomp"), `p', `intorder', 1, 2, `tau'))
            local W   = wres[1,1]
            local dof = wres[1,2]
            local pv  = chi2tail(`dof', `W')
            local rej = cond(`pv' < 0.05, 1, 0)
            matrix `Q' = nullmat(`Q') \ ( `sidx', `tau', `W', `p', `pv', `rej' )
            local mark = cond(`rej' == 1, "✓", " ")
            local star = ""
            if `pv' < 0.01      local star "***"
            else if `pv' < 0.05 local star "**"
            else if `pv' < 0.10 local star "*"
            di as res _col(2) "{ralign 10:`lbl'}" ///
                      _col(15) %6.2f `tau' ///
                      _col(24) %11.4f `W' ///
                      _col(36) %5.0f `p' ///
                      _col(43) %11.4f `pv' ///
                      _col(60) "`mark'  `star'"
        }
        di as txt _col(2) "{hline 76}"
    }
    di as txt _col(2) "Significance: * 10%   ** 5%   *** 1%   (asymptotic chi-square(p))"
    _asycaus_footer

    if "`graph'" != "nograph" {
        _asycaus_quantile_graph `"`Q'"' `"`shocks'"' "`depvar'" "`causvar'" `"`saving'"'
    }

    return matrix results = `Q'
    return local  shock "`shock'"
    return local  depvar "`depvar'"
    return local  cause  "`causvar'"
    return local  test "Fang, Wang, Shieh & Chung (2026) Quantile Asymmetric"
end


program define _asycaus_quantile_graph
    args results shocks dep cause saving
    tempname B
    matrix `B' = `results'
    local nrow = rowsof(`B')

    preserve
    qui drop _all
    qui set obs `nrow'
    qui gen int shock_id = .
    qui gen double tau   = .
    qui gen double Wald  = .
    qui gen double pv    = .
    forvalues i = 1/`nrow' {
        qui replace shock_id = `B'[`i', 1] in `i'
        qui replace tau      = `B'[`i', 2] in `i'
        qui replace Wald     = `B'[`i', 3] in `i'
        qui replace pv       = `B'[`i', 5] in `i'
    }
    local ns : word count `shocks'
    local plotlist ""
    forvalues k = 1/`ns' {
        local sword : word `k' of `shocks'
        local lbl = cond("`sword'" == "pos", "Positive", "Negative")
        twoway ///
            (connected Wald tau if shock_id == `k', msymbol(O) mcolor(navy) lcolor(navy)) ///
            , ytitle("Wald statistic") ///
              xtitle("Quantile (tau)") ///
              title("`lbl' shocks: {it:`cause'} → {it:`dep'}", size(medium)) ///
              note("Fang, Wang, Shieh & Chung (2026)", size(vsmall)) ///
              graphregion(color(white)) plotregion(lcolor(black)) ///
              scheme(s1color) name(asycaus_q_`k', replace)
        local plotlist `plotlist' asycaus_q_`k'
    }
    if `ns' > 1 {
        graph combine `plotlist', cols(1) graphregion(color(white)) name(asycaus_quantile, replace)
    }
    else graph rename asycaus_q_1 asycaus_quantile, replace
    restore
    if `"`saving'"' != "" graph save asycaus_quantile `"`saving'"', replace
end
