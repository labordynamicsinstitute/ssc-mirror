*! asycaus_fourier v1.0.1  19jul2026
*! Fourier Asymmetric Toda-Yamamoto causality (Nazlioglu, Gormus & Soytas 2016; Pata 2020)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! v1.0.1: select optimal frequency k* by minimizing model SSR (not by
*!         maximizing the causality Wald, which would be data-snooping).

program define asycaus_fourier, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [,    ///
          MAXLag(integer 8)         ///
          IC(string)                ///
          INTOrder(integer 1)       ///
          SHOCK(string)             ///
          KMAX(integer 5)           ///
          FORM(string)              ///
          BOOT(integer 1000)        ///
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

    if "`form'" == "" local form single
    local form = lower("`form'")
    if !inlist("`form'", "single", "cumulative") {
        di as err "form() must be {bf:single} or {bf:cumulative}"
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

    // Find optimal Fourier frequency k by minimizing SSR of the
    // restricted equation for the dependent variable.
    tempname Restab
    local rowlabs ""

    foreach s of local shocks {
        local pflag = cond("`s'" == "pos", 1, 0)
        mata: st_matrix("Zcomp", asycaus_pos_neg(st_matrix("`Yraw'"), `pflag'))
        mata: st_local("p_opt", strofreal( ///
            asycaus_lag_select(st_matrix("Zcomp"), 1, `maxlag', `icnum')))
        local p `p_opt'

        // Select the optimal frequency k* by MINIMIZING the model SSR (the
        // multivariate det of the residual covariance), following Nazlioglu,
        // Gormus & Soytas (2016).  Selecting k to maximize the causality Wald
        // would be data-snooping and would invalidate the test.
        local kbest = 1
        local fitbest = .
        forvalues k = 1/`kmax' {
            mata: st_local("fitk", strofreal(asycaus_fourier_fit( ///
                st_matrix("Zcomp"), `p', `intorder', `k', "`form'")))
            if `fitbest' == . | `fitk' < `fitbest' {
                local fitbest = `fitk'
                local kbest = `k'
            }
        }
        // Compute the Fourier-Wald statistic at the selected k*.
        mata: st_matrix("wres", asycaus_wald_fourier( ///
            st_matrix("Zcomp"), `p', `intorder', 1, 2, `kbest', "`form'"))
        local wbest = wres[1,1]
        local dofk  = wres[1,2]
        local pbest = chi2tail(`dofk', `wbest')
        local nobs = rowsof(Zcomp)
        matrix `Restab' = nullmat(`Restab') \ ( `wbest', `p', `kbest', `pbest', `nobs' )
        local lbl = cond("`s'" == "pos", "Positive", "Negative")
        local rowlabs `"`rowlabs' "`lbl'""'
    }
    capture matrix rownames `Restab' = `rowlabs'

    // PROFESSIONAL TABLE
    _asycaus_header "Fourier Asymmetric Toda-Yamamoto Causality"
    di as txt _col(2) "H0: " as res "`causvar'" as txt " does not Granger-cause " as res "`depvar'"
    di as txt _col(2) "Reference: Nazlioglu, Gormus & Soytas (2016); Pata (2020)"
    di as txt _col(2) "Fourier form:             " as res cond("`form'"=="single", "Single frequency", "Cumulative")
    di as txt _col(2) "Maximum frequency k:      " as res "`kmax'"
    di as txt _col(2) "Lag selection:            " as res "`=upper("`ic'")'"
    di as txt _col(2) "Augmentation lags:        " as res "`intorder'"
    di as txt "{hline 78}"
    di as txt _col(2) "{ralign 10:Shock}" ///
              _col(15) "{ralign 11:Wald}" ///
              _col(27) "{ralign 5:Lag}" ///
              _col(33) "{ralign 7:k*}" ///
              _col(42) "{ralign 11:Asy p-val}" ///
              _col(55) "{ralign 8:Obs}"
    di as txt "{hline 78}"
    local r = 1
    foreach s of local shocks {
        local lbl = cond("`s'" == "pos", "Positive", "Negative")
        local W = `Restab'[`r', 1]
        local p = `Restab'[`r', 2]
        local kk = `Restab'[`r', 3]
        local pv = `Restab'[`r', 4]
        local nn = `Restab'[`r', 5]
        local star = ""
        if `pv' < 0.01      local star "***"
        else if `pv' < 0.05 local star "**"
        else if `pv' < 0.10 local star "*"
        di as res _col(2) "{ralign 10:`lbl'}" ///
                  _col(15) %11.4f `W' ///
                  _col(27) %5.0f `p' ///
                  _col(33) %7.0f `kk' ///
                  _col(42) %11.4f `pv' ///
                  _col(55) %8.0f `nn' "  " "`star'"
        local r = `r' + 1
    }
    di as txt "{hline 78}"
    di as txt _col(2) "Significance: * 10%   ** 5%   *** 1%   (asymptotic chi-square(p))"
    _asycaus_footer

    if "`graph'" != "nograph" {
        _asycaus_fourier_graph `"`Restab'"' `"`shocks'"' "`depvar'" "`causvar'" `"`saving'"'
    }

    return matrix results = `Restab'
    return scalar kmax = `kmax'
    return local  form "`form'"
    return local  depvar "`depvar'"
    return local  cause  "`causvar'"
    return local  test "Nazlioglu et al. (2016) Fourier Asymmetric TY"
end


program define _asycaus_fourier_graph
    args results shocks dep cause saving
    tempname B
    matrix `B' = `results'
    local nrow = rowsof(`B')

    preserve
    qui drop _all
    qui set obs `nrow'
    qui gen str10 shock = ""
    qui gen double Wald = .
    qui gen double pval = .
    local i 1
    foreach s of local shocks {
        local lbl = cond("`s'" == "pos", "Positive", "Negative")
        qui replace shock = "`lbl'" in `i'
        qui replace Wald  = `B'[`i', 1] in `i'
        qui replace pval  = `B'[`i', 4] in `i'
        local i = `i' + 1
    }
    qui gen idx = _n
    // p-value labels are produced as a separate string variable so the
    // bar chart can show them via blabel() (which is valid for bar);
    // mlabel() is only valid on scatter, not bar.
    qui gen str10 pstr = string(pval, "%5.3f")

    twoway ///
        (bar Wald idx, barwidth(0.5) fcolor(navy*0.7) lcolor(navy)) ///
        (scatter Wald idx, msymbol(none) mlabel(pstr) mlabcolor(black) ///
                           mlabposition(12) mlabsize(small)) ///
        , xlabel(1 "Positive" 2 "Negative", noticks) ///
          ytitle("Fourier-Wald statistic") ///
          xtitle("") ///
          title("Fourier Asymmetric TY Causality: {it:`cause'} -> {it:`dep'}", size(medium)) ///
          subtitle("Nazlioglu, Gormus & Soytas (2016)", size(small)) ///
          note("Note: trigonometric terms capture smooth structural shifts. Bars labelled with asymptotic p-values.", size(vsmall)) ///
          legend(off) ///
          graphregion(color(white)) plotregion(lcolor(black)) ///
          scheme(s1color) name(asycaus_fourier, replace)
    restore

    if `"`saving'"' != "" graph save asycaus_fourier `"`saving'"', replace
end
