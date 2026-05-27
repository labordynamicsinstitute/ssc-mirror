*! asycaus_spectral v1.0.0  24may2026
*! Asymmetric Frequency-Domain Causality (Breitung-Candelon 2006 on
*! positive/negative cumulative shocks — Bahmani-Oskooee, Chang & Ranjbar 2016)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define asycaus_spectral, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [,    ///
          MAXLag(integer 8)         ///
          IC(string)                ///
          SHOCK(string)             ///
          NFreq(integer 50)         ///
          BOOT(integer 500)         ///
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

    if "`shock'" == "" local shock both
    local shock = lower("`shock'")
    if !inlist("`shock'", "pos", "positive", "neg", "negative", "both") {
        di as err "shock() must be {bf:pos}, {bf:neg}, or {bf:both}"
        exit 198
    }

    qui keep if `touse'
    tempname Yraw
    qui mkmat `depvar' `causvar', matrix(`Yraw')
    if "`lnform'" != "" {
        mata: st_matrix("`Yraw'", log(st_matrix("`Yraw'")))
    }

    local shocks
    if inlist("`shock'", "pos", "positive", "both") local shocks `shocks' pos
    if inlist("`shock'", "neg", "negative", "both") local shocks `shocks' neg

    _asycaus_header "Asymmetric Frequency-Domain Causality"
    di as txt _col(2) "H0: " as res "`causvar'" as txt " does not Granger-cause " as res "`depvar'" as txt " at frequency w"
    di as txt _col(2) "Reference: Bahmani-Oskooee, Chang & Ranjbar (2016); Breitung-Candelon (2006)"
    di as txt _col(2) "Lag selection:            " as res "`=upper("`ic'")'"
    di as txt _col(2) "Frequencies w in (0,pi]:  " as res "`nfreq'"
    di as txt "{hline 78}"

    // Build frequency grid
    tempname OutSpec
    local sidx = 0
    foreach s of local shocks {
        local sidx = `sidx' + 1
        local pflag = cond("`s'" == "pos", 1, 0)
        local lbl = cond("`s'" == "pos", "Positive", "Negative")
        mata: st_matrix("Zcomp", asycaus_pos_neg(st_matrix("`Yraw'"), `pflag'))
        mata: st_local("p_opt", strofreal( ///
            asycaus_lag_select(st_matrix("Zcomp"), 1, `maxlag', `icnum')))
        local p `p_opt'

        // Build a small grid in (0, pi]
        forvalues j = 1/`nfreq' {
            local omega = `j' * (_pi / `nfreq')
            mata: st_local("Wj", strofreal( ///
                asycaus_bc_at_omega(st_matrix("Zcomp"), `p', `omega', 1, 2)))
            // Chi-square critical values with 2 df
            local c10 = invchi2tail(2, 0.10)
            local c5  = invchi2tail(2, 0.05)
            local c1  = invchi2tail(2, 0.01)
            matrix `OutSpec' = nullmat(`OutSpec') \ ( `sidx', `omega', `Wj', `c10', `c5', `c1' )
        }
        // Summarize: % of frequencies rejecting null
        local r10 = 0
        local r5  = 0
        local r1  = 0
        local rstart = (`sidx' - 1) * `nfreq' + 1
        local rend   = `sidx' * `nfreq'
        forvalues r = `rstart'/`rend' {
            if `OutSpec'[`r', 3] > `OutSpec'[`r', 4] local ++r10
            if `OutSpec'[`r', 3] > `OutSpec'[`r', 5] local ++r5
            if `OutSpec'[`r', 3] > `OutSpec'[`r', 6] local ++r1
        }
        di as txt _col(2) "{ralign 10:`lbl' shocks}: " ///
                  as txt "frequencies rejecting H0: " ///
                  as res %3.0f `r1' as txt "/" as res "`nfreq'" as txt " at 1%, " ///
                  as res %3.0f `r5' as txt "/" as res "`nfreq'" as txt " at 5%, " ///
                  as res %3.0f `r10' as txt "/" as res "`nfreq'" as txt " at 10%"
        di as txt _col(2) "{ralign 10: }: lag p = " as res "`p'"
    }
    _asycaus_footer

    if "`graph'" != "nograph" {
        _asycaus_spectral_graph `"`OutSpec'"' `"`shocks'"' "`depvar'" "`causvar'" `"`saving'"'
    }

    return matrix results = `OutSpec'
    return scalar nfreq = `nfreq'
    return local  shock "`shock'"
    return local  depvar "`depvar'"
    return local  cause  "`causvar'"
    return local  test "Bahmani-Oskooee et al. (2016) Asymmetric Spectral Causality"
end


program define _asycaus_spectral_graph
    args results shocks dep cause saving
    tempname B
    matrix `B' = `results'
    local nrow = rowsof(`B')

    preserve
    qui drop _all
    qui set obs `nrow'
    qui gen int shock_id = .
    qui gen double omega = .
    qui gen double Wald  = .
    qui gen double cv10  = .
    qui gen double cv5   = .
    qui gen double cv1   = .
    forvalues i = 1/`nrow' {
        qui replace shock_id = `B'[`i', 1] in `i'
        qui replace omega    = `B'[`i', 2] in `i'
        qui replace Wald     = `B'[`i', 3] in `i'
        qui replace cv10     = `B'[`i', 4] in `i'
        qui replace cv5      = `B'[`i', 5] in `i'
        qui replace cv1      = `B'[`i', 6] in `i'
    }

    local ns : word count `shocks'
    local plotlist ""
    forvalues k = 1/`ns' {
        local lbl : word `k' of `shocks'
        local lbl = cond("`lbl'" == "pos", "Positive", "Negative")
        twoway ///
            (line Wald omega if shock_id == `k', lcolor(navy) lwidth(medthick)) ///
            (line cv10 omega if shock_id == `k', lcolor(green)    lpattern(dot)) ///
            (line cv5  omega if shock_id == `k', lcolor(orange)   lpattern(dash)) ///
            (line cv1  omega if shock_id == `k', lcolor(cranberry) lpattern(longdash)) ///
            , ytitle("Wald statistic") ///
              xtitle("Frequency ω (0 = long-run, π ≈ 3.14 = short-run)") ///
              xlabel(0(0.5)3.14) ///
              title("`lbl' shocks: {it:`cause'} → {it:`dep'}", size(medium)) ///
              legend(order(1 "Wald" 2 "10% CV" 3 "5% CV" 4 "1% CV") rows(1) region(lcolor(none))) ///
              graphregion(color(white)) plotregion(lcolor(black)) ///
              scheme(s1color) name(asycaus_spec_`k', replace) ///
              note("Bahmani-Oskooee, Chang & Ranjbar (2016)", size(vsmall))
        local plotlist `plotlist' asycaus_spec_`k'
    }
    if `ns' > 1 {
        graph combine `plotlist', cols(1) graphregion(color(white)) name(asycaus_spectral, replace)
    }
    else {
        graph rename asycaus_spec_1 asycaus_spectral, replace
    }
    restore
    if `"`saving'"' != "" graph save asycaus_spectral `"`saving'"', replace
end
