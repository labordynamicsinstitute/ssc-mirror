*! xtkpybreak version 1.0.0  09jul2026
*! CCE estimation with non-stationary factors (Kapetanios, Pesaran & Yamagata 2011)
*!   and multiple structural changes in non-stationary heterogeneous panels
*!   (Baltagi, Feng & Wang 2025).
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Implements, faithfully to the two papers:
*!   subcommand  cce   : CCEMG and CCEP estimators, valid under I(1) common
*!                       factors.  Proxy f_t by cross-section averages
*!                       (Pesaran 2006; KPY 2011, eqs 14-20, 38-44).
*!   subcommand  break : least-squares estimation of multiple structural
*!                       breaks (Bai & Perron 1998, 2003 dynamic programming)
*!                       in slopes (model 4) or in slopes AND error-factor
*!                       loadings (model 5) of non-stationary heterogeneous
*!                       panels with common factors (BFW 2025, eqs 4-19).
*!
*! Data: Stata long format, xtset panelvar timevar, balanced panel required.

program define xtkpybreak, eclass
        version 14.0
        if replay() {
                if ("`e(cmd)'" != "xtkpybreak") error 301
                _xtkpb_display
                exit
        }
        gettoken sub 0 : 0, parse(" ,")
        local l = length("`sub'")
        if ("`sub'" == substr("cce",1,max(2,`l'))    & `l'>=2 & "`sub'"!="") {
                _xtkpb_cce `0'
        }
        else if ("`sub'" == substr("break",1,max(2,`l')) & `l'>=2 & "`sub'"!="") {
                _xtkpb_break `0'
        }
        else {
                di as error "unknown subcommand '`sub''"
                di as error "syntax:  xtkpybreak {bf:cce} ...   or   xtkpybreak {bf:break} ..."
                exit 198
        }
end

*-----------------------------------------------------------------------------
* CCE  (Kapetanios, Pesaran & Yamagata 2011)
*-----------------------------------------------------------------------------
program define _xtkpb_cce, eclass
        syntax varlist(min=2 numeric ts) [if] [in] [ ,   ///
                PROXY(string)                            ///
                ESTimator(string)                        ///
                NOCONstant                               ///
                Level(cilevel)                           ///
                COEFplot FACTORplot                      ///
                name(string) ]

        gettoken dv xvars : varlist
        local k : word count `xvars'
        local nocons = ("`noconstant'"!="")

        * ---- proxy choice ----
        if ("`proxy'"=="") local proxy "yx"
        if !inlist("`proxy'","yx","x") {
                di as error "proxy() must be {bf:yx} (default) or {bf:x}"
                exit 198
        }
        local pyx = ("`proxy'"=="yx")

        * ---- which estimator is posted in e(b) ----
        if ("`estimator'"=="") local estimator "mg"
        if !inlist("`estimator'","mg","pooled","pool") {
                di as error "estimator() must be {bf:mg} or {bf:pooled}"
                exit 198
        }
        if ("`estimator'"=="pool") local estimator "pooled"

        * ---- panel setup (inline, per skill note on tempvar scope) ----
        qui xtset
        local ivar "`r(panelvar)'"
        local tvar "`r(timevar)'"
        if ("`ivar'"=="" | "`tvar'"=="") {
                di as error "data must be {bf:xtset} panelvar timevar first"
                exit 459
        }
        marksample touse
        markout `touse' `dv' `xvars'
        qui count if `touse'
        if (r(N)==0) error 2000

        * ---- Mata engine ----
        tempname bMG seMG bP seP Bi Bise VMG VP
        mata: xtkpb_cce_engine("`dv'","`xvars'","`ivar'","`tvar'","`touse'", ///
                `pyx', `nocons', "`bMG'","`seMG'","`bP'","`seP'","`Bi'","`Bise'", ///
                "`VMG'","`VP'")

        if (`r(balanced)'==0) {
                di as error "xtkpybreak requires a balanced panel " ///
                        "(N*T = `r(nobs)' does not match `r(N_g)' x `r(Tbar)')"
                exit 451
        }
        local N   = r(N_g)
        local T   = r(Tbar)

        * ---- display ----
        _xtkpb_cce_tab, dv(`dv') xvars(`xvars') n(`N') t(`T') proxy(`proxy') ///
                level(`level') bmg(`bMG') semg(`seMG') bp(`bP') sep(`seP')

        * ---- post e() (chosen estimator) ----
        tempname b V
        if ("`estimator'"=="mg") {
                matrix `b' = `bMG'
                matrix `V' = `VMG'
        }
        else {
                matrix `b' = `bP'
                matrix `V' = `VP'
        }
        matrix colnames `b' = `xvars'
        matrix colnames `V' = `xvars'
        matrix rownames `V' = `xvars'
        ereturn post `b' `V', esample(`touse') depname(`dv') obs(`=`N'*`T'')

        ereturn local cmd       "xtkpybreak"
        ereturn local subcmd    "cce"
        ereturn local estimator "`estimator'"
        ereturn local proxy     "`proxy'"
        ereturn local depvar    "`dv'"
        ereturn local indepvars "`xvars'"
        ereturn local ivar      "`ivar'"
        ereturn local tvar      "`tvar'"
        ereturn local title     "CCE estimation with non-stationary factors (KPY 2011)"
        ereturn scalar N_g      = `N'
        ereturn scalar Tbar     = `T'
        ereturn scalar N        = `N'*`T'
        ereturn scalar k        = `k'
        matrix colnames `bMG' = `xvars'
        matrix colnames `bP'  = `xvars'
        ereturn matrix b_mg     = `bMG'
        ereturn matrix se_mg    = `seMG'
        ereturn matrix b_pooled = `bP'
        ereturn matrix se_pooled= `seP'
        ereturn matrix b_i      = `Bi'
        ereturn matrix se_i     = `Bise'
        ereturn matrix V_mg     = `VMG'
        ereturn matrix V_pooled = `VP'

        * ---- plots (isolated frames; require Stata 16; never abort estimation) ----
        if ("`name'"=="") local name "xtkpb"
        if ("`coefplot'`factorplot'"!="" & c(stata_version)<16) {
                di as text "(plots require Stata 16 or later; estimation results are unaffected)"
        }
        if ("`coefplot'"!="" & c(stata_version)>=16) {
                capture noisily _xtkpb_cce_coefplot, xvars(`xvars') level(`level') name(`name')
                if (_rc) di as error "(coefplot skipped: graph error rc=`=_rc')"
        }
        if ("`factorplot'"!="" & c(stata_version)>=16) {
                capture noisily _xtkpb_factorplot, dv(`dv') xvars(`xvars') ivar(`ivar') ///
                        tvar(`tvar') touse(`touse') pyx(`pyx') name(`name')
                if (_rc) di as error "(factorplot skipped: graph error rc=`=_rc')"
        }
end

program define _xtkpb_cce_tab
        syntax , dv(string) xvars(string) n(string) t(string) proxy(string) ///
                level(string) bmg(name) semg(name) bp(name) sep(name)
        local k : word count `xvars'
        local zc = invnormal(1-(100-`level')/200)

        di ""
        di as text "Common Correlated Effects estimation, non-stationary factors" ///
                _col(58) as text "(KPY 2011)"
        di as text "{hline 78}"
        di as text "Dependent variable : " as result "`dv'"
        di as text "Panels (N)         : " as result %-9.0g `n' ///
                as text "  Time periods (T): " as result %-9.0g `t'
        if ("`proxy'"=="yx") di as text "Factor proxy       : " as result ///
                "cross-section averages of (`dv', regressors)"
        else di as text "Factor proxy       : " as result ///
                "cross-section averages of regressors"
        di as text "{hline 78}"
        di as text "{col 1}Variable{col 16}{col 22}Coef.{col 34}Std.Err." ///
                "{col 47}z{col 56}P>|z|{col 65}[`level'% C.I.]"

        foreach blk in MG POOLED {
                if ("`blk'"=="MG") {
                        di as text "{hline 78}"
                        di as text "CCEMG  (mean-group)"
                        local bb `bmg'
                        local ss `semg'
                }
                else {
                        di as text "{hline 78}"
                        di as text "CCEP   (pooled)"
                        local bb `bp'
                        local ss `sep'
                }
                di as text "{hline 78}"
                forvalues j = 1/`k' {
                        local vn : word `j' of `xvars'
                        local co = `bb'[1,`j']
                        local se = `ss'[1,`j']
                        local zv = `co'/`se'
                        local pv = 2*normal(-abs(`zv'))
                        local lo = `co' - `zc'*`se'
                        local hi = `co' + `zc'*`se'
                        local st ""
                        if (`pv'<0.10) local st "*"
                        if (`pv'<0.05) local st "**"
                        if (`pv'<0.01) local st "***"
                        di as text %-15s abbrev("`vn'",14) ///
                          as result "{col 18}" %9.4f `co' "`st'" ///
                          as result "{col 33}" %9.4f `se' ///
                          as result "{col 44}" %7.2f `zv' ///
                          as result "{col 54}" %6.3f `pv' ///
                          as result "{col 62}" %9.4f `lo' ///
                          as result "{col 72}" %9.4f `hi'
                }
        }
        di as text "{hline 78}"
        di as text "Significance: * 10%, ** 5%, *** 1%.  " ///
                "MG s.e. from cross-panel dispersion (KPY eq.38);"
        di as text "pooled s.e. from KPY eq.42-44.  Individual b_i in e(b_i)."
end

*-----------------------------------------------------------------------------
* BREAK  (Baltagi, Feng & Wang 2025)
*-----------------------------------------------------------------------------
program define _xtkpb_break, eclass
        syntax varlist(min=2 numeric ts) [if] [in] [ ,   ///
                NBReaks(integer 1)                       ///
                LOADings                                 ///
                PROXY(string)                            ///
                TRIM(real 0.10)                          ///
                NONStationary                            ///
                NOCONstant                               ///
                HAC(integer -1)                          ///
                Level(cilevel)                           ///
                BREAKplot COEFEvolution                  ///
                name(string) ]

        gettoken dv xvars : varlist
        local k : word count `xvars'
        if (`nbreaks'<1) {
                di as error "nbreaks() must be >= 1"
                exit 198
        }
        if ("`proxy'"=="") local proxy "x"
        if !inlist("`proxy'","yx","x") {
                di as error "proxy() must be {bf:x} (default, BFW) or {bf:yx}"
                exit 198
        }
        local pyx = ("`proxy'"=="yx")
        local ldg = ("`loadings'"!="")
        local nocons = ("`noconstant'"!="")
        if (`trim'<=0 | `trim'>=0.5) {
                di as error "trim() must be in (0,0.5); BFW use 0.10"
                exit 198
        }

        qui xtset
        local ivar "`r(panelvar)'"
        local tvar "`r(timevar)'"
        if ("`ivar'"=="" | "`tvar'"=="") {
                di as error "data must be {bf:xtset} panelvar timevar first"
                exit 459
        }
        marksample touse
        markout `touse' `dv' `xvars'
        qui count if `touse'
        if (r(N)==0) error 2000

        tempname MGco MGse Bdate Bidx MGco_p MGse_p ssr Bi Bise
        mata: xtkpb_break_engine("`dv'","`xvars'","`ivar'","`tvar'","`touse'", ///
                `nbreaks', `ldg', `pyx', `trim', `hac', `nocons',             ///
                "`MGco'","`MGse'","`Bdate'","`Bidx'","`MGco_p'","`MGse_p'",    ///
                "`ssr'","`Bi'","`Bise'")

        if (`r(balanced)'==0) {
                di as error "xtkpybreak requires a balanced panel"
                exit 451
        }
        if (`r(feasible)'==0) {
                di as error "trim()/nbreaks() leave too few observations per regime " ///
                        "for T=`r(Tbar)' and " `k' " regressor(s); reduce nbreaks() or trim()"
                exit 198
        }
        local N    = r(N_g)
        local T    = r(Tbar)
        local hacw = r(hacw)
        local m    = `nbreaks'
        local nreg = `m'+1

        local nsflag = ("`nonstationary'"!="")
        _xtkpb_break_tab, dv(`dv') xvars(`xvars') n(`N') t(`T') m(`m') ///
                proxy(`proxy') loadings(`ldg') nonstat(`nsflag') hac(`hacw') ///
                level(`level') mgco(`MGco') mgse(`MGse') bdate(`Bdate') ssr(`ssr')

        * ---- build stacked e(b): eq r1..r(m+1) each with xvars ----
        tempname b V
        local names ""
        forvalues r = 1/`nreg' {
                foreach v of local xvars {
                        local names "`names' r`r':`v'"
                }
        }
        mata: xtkpb_break_post("`MGco'","`MGse'","`b'","`V'", `nreg', `k')
        matrix colnames `b' = `names'
        matrix colnames `V' = `names'
        matrix rownames `V' = `names'
        ereturn post `b' `V', esample(`touse') depname(`dv') obs(`=`N'*`T'')

        ereturn local cmd       "xtkpybreak"
        ereturn local subcmd    "break"
        ereturn local proxy     "`proxy'"
        ereturn local depvar    "`dv'"
        ereturn local indepvars "`xvars'"
        ereturn local ivar      "`ivar'"
        ereturn local tvar      "`tvar'"
        if (`ldg') ereturn local model "breaks in slopes and factor loadings (BFW model 5)"
        else       ereturn local model "breaks in slopes only (BFW model 4)"
        if ("`nonstationary'"!="") ereturn local regressors "I(1) - Case 2 (T-consistent)"
        else                       ereturn local regressors "I(0) - Case 1 (root-T-consistent)"
        ereturn local title     "Multiple structural breaks, non-stationary panels (BFW 2025)"
        ereturn scalar N_g      = `N'
        ereturn scalar Tbar     = `T'
        ereturn scalar N        = `N'*`T'
        ereturn scalar k        = `k'
        ereturn scalar nbreaks  = `m'
        ereturn scalar ssr      = `ssr'[1,1]
        ereturn scalar trim     = `trim'
        ereturn scalar hac      = `hacw'
        matrix colnames `Bdate' = break
        ereturn matrix breakdates = `Bdate'
        ereturn matrix breakobs   = `Bidx'
        ereturn matrix b_regime   = `MGco'
        ereturn matrix se_regime  = `MGse'
        ereturn matrix bp_regime  = `MGco_p'
        ereturn matrix sep_regime = `MGse_p'
        ereturn matrix b_i        = `Bi'
        ereturn matrix se_i       = `Bise'

        * ---- plots (isolated frames; require Stata 16; never abort estimation) ----
        if ("`name'"=="") local name "xtkpb"
        if ("`breakplot'`coefevolution'"!="" & c(stata_version)<16) {
                di as text "(plots require Stata 16 or later; estimation results are unaffected)"
        }
        if ("`breakplot'"!="" & c(stata_version)>=16) {
                capture noisily _xtkpb_breakplot, dv(`dv') ivar(`ivar') tvar(`tvar') ///
                        touse(`touse') name(`name')
                if (_rc) di as error "(breakplot skipped: graph error rc=`=_rc')"
        }
        if ("`coefevolution'"!="" & c(stata_version)>=16) {
                capture noisily _xtkpb_coefevo, xvars(`xvars') tvar(`tvar') ivar(`ivar') ///
                        touse(`touse') m(`m') level(`level') name(`name')
                if (_rc) di as error "(coefevolution skipped: graph error rc=`=_rc')"
        }
end

program define _xtkpb_break_tab
        syntax , dv(string) xvars(string) n(string) t(string) m(string) ///
                proxy(string) loadings(string) nonstat(string) hac(string) ///
                level(string) mgco(name) mgse(name) bdate(name) ssr(name)
        local k : word count `xvars'
        local nreg = `m'+1
        local zc = invnormal(1-(100-`level')/200)

        di ""
        di as text "Multiple structural breaks in non-stationary heterogeneous panels" ///
                _col(66) as text "(BFW 2025)"
        di as text "{hline 78}"
        di as text "Dependent variable : " as result "`dv'"
        di as text "Panels (N)         : " as result %-9.0g `n' ///
                as text "  Time periods (T): " as result %-9.0g `t'
        if ("`loadings'"=="1") di as text "Break specification: " as result ///
                "slopes and error-factor loadings (model 5)"
        else di as text "Break specification: " as result "slopes only (model 4)"
        if ("`nonstat'"=="1") di as text "Regressors         : " as result ///
                "I(1) after CCE transform - Case 2 (T-consistent)"
        else di as text "Regressors         : " as result ///
                "I(0) after CCE transform - Case 1 (root-T-consistent)"
        if ("`proxy'"=="yx") di as text "Factor proxy       : " as result ///
                "cross-section averages of (`dv', regressors)"
        else di as text "Factor proxy       : " as result ///
                "cross-section averages of regressors"

        * ---- estimated break dates ----
        di as text "{hline 78}"
        di as text "Estimated break points (Bai-Perron dynamic programming):"
        forvalues j = 1/`m' {
                local bd = `bdate'[`j',1]
                di as text "   break " %2.0f `j' as text " at " as result ///
                        "`tvar'" as text " = " as result %9.0g `bd'
        }
        local ss = `ssr'[1,1]
        di as text "   total SSR (all panels) = " as result %12.4f `ss'

        * ---- regime mean-group coefficients ----
        di as text "{hline 78}"
        di as text "Mean-group slope estimates by regime  (95%% level = `level')"
        di as text "{hline 78}"
        di as text "{col 1}Regime{col 12}Variable{col 26}Coef.{col 38}Std.Err." ///
                "{col 51}z{col 60}P>|z|"
        di as text "{hline 78}"
        forvalues r = 1/`nreg' {
                di as text "regime `r'"
                forvalues j = 1/`k' {
                        local vn : word `j' of `xvars'
                        local co = `mgco'[`r',`j']
                        local se = `mgse'[`r',`j']
                        local zv = `co'/`se'
                        local pv = 2*normal(-abs(`zv'))
                        local st ""
                        if (`pv'<0.10) local st "*"
                        if (`pv'<0.05) local st "**"
                        if (`pv'<0.01) local st "***"
                        di as text "{col 12}" %-14s abbrev("`vn'",13) ///
                          as result "{col 24}" %9.4f `co' "`st'" ///
                          as result "{col 37}" %9.4f `se' ///
                          as result "{col 49}" %7.2f `zv' ///
                          as result "{col 58}" %6.3f `pv'
                }
        }
        di as text "{hline 78}"
        di as text "Significance: * 10%, ** 5%, *** 1%.  " ///
                "MG s.e. from cross-panel dispersion (BFW Prop.2)."
        di as text "Break points estimated jointly with slopes (BFW eq.13)."
        di as text "Individual b_i in e(b_i); Newey-West s.e. (window = `hac') " ///
                "in e(se_i) (BFW Prop.1)."
end

*-----------------------------------------------------------------------------
* replay
*-----------------------------------------------------------------------------
program define _xtkpb_display
        if ("`e(subcmd)'"=="cce") {
                tempname bmg semg bp sep
                matrix `bmg'  = e(b_mg)
                matrix `semg' = e(se_mg)
                matrix `bp'   = e(b_pooled)
                matrix `sep'  = e(se_pooled)
                _xtkpb_cce_tab, dv(`e(depvar)') xvars(`e(indepvars)') ///
                        n(`e(N_g)') t(`e(Tbar)') proxy(`e(proxy)') level(95) ///
                        bmg(`bmg') semg(`semg') bp(`bp') sep(`sep')
        }
        else {
                di as text "(replay of xtkpybreak break; full table via stored e() results)"
                ereturn display
        }
end

*-----------------------------------------------------------------------------
* Graphs
*-----------------------------------------------------------------------------
program define _xtkpb_cce_coefplot
        syntax , xvars(string) level(string) name(string)
        local vn : word 1 of `xvars'
        local zc = invnormal(1-(100-`level')/200)
        tempname M bmg smg
        matrix `M'   = e(b_i)
        matrix `bmg' = e(b_mg)
        matrix `smg' = e(se_mg)
        local mg  = `bmg'[1,1]
        local se  = `smg'[1,1]
        local lo  = `mg' - `zc'*`se'
        local hi  = `mg' + `zc'*`se'
        local NN  = colsof(`M')
        forvalues i = 1/`NN' {
                local v`i' = `M'[1,`i']
        }
        * build the graph in an isolated frame (never touches the caller's data)
        tempname fr
        frame create `fr'
        frame `fr' {
                qui set obs `NN'
                qui gen double bcoef = .
                forvalues i = 1/`NN' {
                        qui replace bcoef = `v`i'' in `i'
                }
                qui gen long panel = _n
                twoway (scatter bcoef panel, msymbol(oh) mcolor(navy))       ///
                       , yline(`mg', lcolor(cranberry) lwidth(medthick))     ///
                         yline(`lo', lpattern(dash) lcolor(gs8))             ///
                         yline(`hi', lpattern(dash) lcolor(gs8))             ///
                         title("Heterogeneous CCE slopes: `vn'")             ///
                         subtitle("per-panel b{sub:i} with CCEMG (line) and `level'% band") ///
                         ytitle("b{sub:i}(`vn')") xtitle("panel index")       ///
                         graphregion(color(white)) legend(off)               ///
                         name(`name'_coef, replace)
        }
        frame drop `fr'
end

program define _xtkpb_factorplot
        syntax , dv(string) xvars(string) ivar(string) tvar(string) ///
                touse(string) pyx(string) name(string)
        tempname fr
        frame put `dv' `xvars' `tvar' if e(sample), into(`fr')
        frame `fr' {
                tempvar ybar
                qui bysort `tvar': egen double `ybar' = mean(`dv')
                local avlist "`ybar'"
                local anames `"1 "CS avg `dv'""'
                local pos 2
                foreach v of local xvars {
                        tempvar xb`pos'
                        qui bysort `tvar': egen double `xb`pos'' = mean(`v')
                        local avlist "`avlist' `xb`pos''"
                        local anames `"`anames' `pos' "CS avg `v'""'
                        local ++pos
                }
                qui bysort `tvar': keep if _n==1
                local plots ""
                foreach a of local avlist {
                        local plots "`plots' (line `a' `tvar', lwidth(medthick))"
                }
                twoway `plots', title("Cross-section-average factor proxies")  ///
                        subtitle("proxies for the unobserved I(1) common factors") ///
                        ytitle("cross-section average") xtitle("`tvar'")        ///
                        graphregion(color(white))                              ///
                        legend(order(`anames') size(small) rows(1))            ///
                        name(`name'_factor, replace)
        }
        frame drop `fr'
end

program define _xtkpb_breakplot
        syntax , dv(string) ivar(string) tvar(string) touse(string) name(string)
        tempname BD
        matrix `BD' = e(breakdates)
        local m = rowsof(`BD')
        local xl ""
        forvalues j = 1/`m' {
                local bd = `BD'[`j',1]
                local xl "`xl' xline(`bd', lcolor(cranberry) lpattern(dash) lwidth(medthick))"
        }
        tempname fr
        frame put `dv' `tvar' if e(sample), into(`fr')
        frame `fr' {
                tempvar ybar
                qui bysort `tvar': egen double `ybar' = mean(`dv')
                qui bysort `tvar': keep if _n==1
                twoway (line `ybar' `tvar', lwidth(medthick) lcolor(navy)),   ///
                        `xl'                                                  ///
                        title("Cross-section average of `dv' and estimated breaks") ///
                        subtitle("dashed lines = Bai-Perron break dates")     ///
                        ytitle("CS average `dv'") xtitle("`tvar'")            ///
                        graphregion(color(white)) legend(off)                 ///
                        name(`name'_break, replace)
        }
        frame drop `fr'
end

program define _xtkpb_coefevo
        syntax , xvars(string) tvar(string) ivar(string) touse(string) ///
                m(string) level(string) name(string)
        tempname MGco MGse Bdate
        matrix `MGco'  = e(b_regime)
        matrix `MGse'  = e(se_regime)
        matrix `Bdate' = e(breakdates)
        local vn : word 1 of `xvars'
        local nreg = `m'+1
        local zc = invnormal(1-(100-`level')/200)

        qui su `tvar' if e(sample), meanonly
        local tmin = r(min)
        local tmax = r(max)

        * pull all matrix values into locals
        forvalues r = 1/`nreg' {
                local co`r' = `MGco'[`r',1]
                local se`r' = `MGse'[`r',1]
        }
        local xl ""
        forvalues j = 1/`m' {
                local bk`j' = `Bdate'[`j',1]
                local xl "`xl' xline(`bk`j'', lcolor(gs9) lpattern(dash))"
        }

        * build the step series in an isolated frame
        tempname fr
        frame create `fr'
        frame `fr' {
                qui set obs `nreg'
                qui gen int regime = _n
                qui gen double b   = .
                qui gen double lo  = .
                qui gen double hi  = .
                qui gen double tstart = .
                qui gen double tstop  = .
                forvalues r = 1/`nreg' {
                        qui replace b  = `co`r''             in `r'
                        qui replace lo = `co`r''-`zc'*`se`r'' in `r'
                        qui replace hi = `co`r''+`zc'*`se`r'' in `r'
                }
                local prev = `tmin'
                forvalues r = 1/`nreg' {
                        qui replace tstart = `prev' in `r'
                        if (`r'<=`m') {
                                qui replace tstop = `bk`r'' in `r'
                                local prev = `bk`r''
                        }
                        else qui replace tstop = `tmax' in `r'
                }
                qui expand 2
                sort regime
                by regime: gen double tt = cond(_n==1, tstart, tstop)
                twoway (rarea lo hi tt, sort color(navy%20))                  ///
                       (line b tt, sort lwidth(medthick) lcolor(navy)),       ///
                        `xl'                                                  ///
                        title("Regime evolution of MG slope: `vn'")           ///
                        subtitle("step = CCEMG slope by regime, band = `level'% CI") ///
                        ytitle("MG slope(`vn')") xtitle("`tvar'")             ///
                        graphregion(color(white))                            ///
                        legend(order(2 "MG slope" 1 "`level'% CI") rows(1) size(small)) ///
                        name(`name'_evo, replace)
        }
        frame drop `fr'
end

*=============================================================================
* Mata engine  (compiles at load; use // comments only, one stmt per line)
*=============================================================================
version 14.0
mata:
mata set matastrict off

// ---- reshape long balanced panel into T x N and per-panel X ----------------
// returns success in ok (1/0); fills Ymat (T x N) and pointer array Xp
real scalar xtkpb_reshape(string scalar yv, string scalar xv,        ///
        string scalar idv, string scalar tv, string scalar tousev,   ///
        real matrix Ymat, pointer(real matrix) rowvector Xp,         ///
        real scalar N, real scalar T, real scalar k)
{
        real colvector y, id, tt, ids, times, perm
        real matrix X
        real scalar i, nobs, a, b

        y  = st_data(., yv, tousev)
        X  = st_data(., xv, tousev)
        id = st_data(., idv, tousev)
        tt = st_data(., tv, tousev)
        k  = cols(X)
        nobs = rows(y)

        // robust: sort by (panel, time) so panel blocks are contiguous/ordered
        perm = order((id, tt), (1, 2))
        y  = y[perm]
        X  = X[perm, .]
        id = id[perm]
        tt = tt[perm]

        ids   = uniqrows(id)
        times = uniqrows(tt)
        N = rows(ids)
        T = rows(times)

        if (nobs != N*T) {
                return(0)
        }

        Ymat = J(T, N, .)
        Xp   = J(1, N, NULL)
        for (i=1; i<=N; i++) {
                a = (i-1)*T + 1
                b = i*T
                Ymat[., i] = y[a::b]
                Xp[i] = &(X[a::b, .])
        }
        return(1)
}

// ---- CCE engine (KPY 2011) -------------------------------------------------
void xtkpb_cce_engine(string scalar yv, string scalar xv, string scalar idv, ///
        string scalar tv, string scalar tousev, real scalar pyx,            ///
        real scalar nocons,                                                 ///
        string scalar bMGn, string scalar seMGn, string scalar bPn,         ///
        string scalar sePn, string scalar Bin, string scalar Bisen,         ///
        string scalar VMGn, string scalar VPn)
{
        real matrix Ymat, Hbar, Mbar, Xi, XM, A, B, Ap_i, Sig, Psi, R, Q
        real matrix SigMG, SigP, VMG, VP, Bse
        real colvector ybar, yi, bi, c, bMG, bP, d, seMG, seP, ehat, resid
        real scalar N, T, k, i, ok, dof, s2
        pointer(real matrix) rowvector Xp
        pointer(real matrix) rowvector Ap
        real matrix xbar, cons, sumXMX, sumXMy

        N = 0
        T = 0
        k = 0
        ok = xtkpb_reshape(yv, xv, idv, tv, tousev, Ymat, Xp, N, T, k)

        st_numscalar("r(N_g)",  N)
        st_numscalar("r(Tbar)", T)
        st_numscalar("r(nobs)", N*T)
        if (ok==0) {
                st_numscalar("r(balanced)", 0)
                return
        }
        st_numscalar("r(balanced)", 1)

        // cross-section averages
        ybar = J(T, 1, 0)
        xbar = J(T, k, 0)
        for (i=1; i<=N; i++) {
                ybar = ybar + Ymat[., i]
                xbar = xbar + *Xp[i]
        }
        ybar = ybar :/ N
        xbar = xbar :/ N

        cons = J(T, 1, 1)
        if (nocons==1) {
                if (pyx==1) {
                        Hbar = ybar, xbar
                }
                else {
                        Hbar = xbar
                }
        }
        else {
                if (pyx==1) {
                        Hbar = cons, ybar, xbar
                }
                else {
                        Hbar = cons, xbar
                }
        }
        Mbar = I(T) - Hbar * invsym(Hbar'Hbar) * Hbar'

        // per-panel CCE
        B    = J(k, N, .)
        Bse  = J(k, N, .)
        Ap   = J(1, N, NULL)
        sumXMX = J(k, k, 0)
        sumXMy = J(k, 1, 0)
        dof = T - cols(Hbar) - k
        if (dof < 1) {
                dof = 1
        }
        for (i=1; i<=N; i++) {
                Xi = *Xp[i]
                yi = Ymat[., i]
                XM = Xi' * Mbar
                A  = XM * Xi
                c  = XM * yi
                bi = invsym(A) * c
                B[., i] = bi
                // store a FRESH copy of A (do not alias the reused loop var)
                Ap[i] = &(XM*Xi)
                sumXMX = sumXMX + A
                sumXMy = sumXMy + c
                // individual s.e. (KPY Thm 3, eq.49-50)
                resid = yi - Xi*bi
                s2 = (resid' * Mbar * resid) / dof
                Bse[., i] = sqrt(diagonal(s2 * invsym(A)))
        }

        // CCEMG and its variance (eq.14, 38)
        bMG = J(k, 1, 0)
        for (i=1; i<=N; i++) {
                bMG = bMG + B[., i]
        }
        bMG = bMG :/ N
        Sig = J(k, k, 0)
        for (i=1; i<=N; i++) {
                d = B[., i] - bMG
                Sig = Sig + d*d'
        }
        SigMG = Sig :/ (N-1)
        VMG   = SigMG :/ N
        seMG  = sqrt(diagonal(VMG))

        // CCEP and its variance (eq.20, 42-44)
        bP = invsym(sumXMX) * sumXMy
        Psi = J(k, k, 0)
        for (i=1; i<=N; i++) {
                Psi = Psi + (*Ap[i]) :/ T
        }
        Psi = Psi :/ N
        R = J(k, k, 0)
        for (i=1; i<=N; i++) {
                Q = (*Ap[i]) :/ T
                d = B[., i] - bMG
                R = R + Q*d*d'*Q
        }
        R = R :/ (N-1)
        SigP = invsym(Psi) * R * invsym(Psi)
        VP   = SigP :/ N
        seP  = sqrt(diagonal(VP))

        st_matrix(bMGn,  bMG')
        st_matrix(seMGn, seMG')
        st_matrix(bPn,   bP')
        st_matrix(sePn,  seP')
        st_matrix(Bin,   B)
        st_matrix(Bisen, Bse)
        st_matrix(VMGn,  VMG)
        st_matrix(VPn,   VP)
}

// ---- segment SSR summed across panels (direct accumulate) ------------------
void xtkpb_costmat(pointer(real matrix) rowvector Wp, real matrix YY,  ///
        real scalar N, real scalar T, real scalar q, real scalar h,    ///
        real matrix C)
{
        real matrix Wi, XtX
        real colvector Xty, yi
        real scalar i, a, b, cnt, yty, ssr
        real rowvector z

        C = J(T, T, 0)
        for (i=1; i<=N; i++) {
                Wi = *Wp[i]
                yi = YY[., i]
                for (a=1; a<=T; a++) {
                        XtX = J(q, q, 0)
                        Xty = J(q, 1, 0)
                        yty = 0
                        cnt = 0
                        for (b=a; b<=T; b++) {
                                z = Wi[b, .]
                                XtX = XtX + z'z
                                Xty = Xty + z'*yi[b]
                                yty = yty + yi[b]*yi[b]
                                cnt = cnt + 1
                                if (cnt>=h) {
                                        ssr = yty - Xty' * invsym(XtX) * Xty
                                        C[a, b] = C[a, b] + ssr
                                }
                        }
                }
        }
}

// ---- Bai-Perron dynamic programming ---------------------------------------
real rowvector xtkpb_dp(real matrix C, real scalar T, real scalar m, real scalar h)
{
        real matrix OPT, POS
        real scalar bigM, s, j, lo, hi, l, best, bestl, cand, jj
        real rowvector brk

        bigM = 1e300
        OPT = J(T, m+1, bigM)
        POS = J(T, m+1, 0)

        for (j=1; j<=T; j++) {
                if (j>=h) {
                        OPT[j, 1] = C[1, j]
                }
        }
        for (s=2; s<=m+1; s++) {
                for (j=1; j<=T; j++) {
                        lo = (s-1)*h
                        hi = j - h
                        if (hi>=lo) {
                                best  = bigM
                                bestl = 0
                                for (l=lo; l<=hi; l++) {
                                        if (OPT[l, s-1] < bigM) {
                                                cand = OPT[l, s-1] + C[l+1, j]
                                                if (cand < best) {
                                                        best  = cand
                                                        bestl = l
                                                }
                                        }
                                }
                                OPT[j, s] = best
                                POS[j, s] = bestl
                        }
                }
        }
        brk = J(1, m, 0)
        jj = T
        for (s=m+1; s>=2; s=s-1) {
                l = POS[jj, s]
                brk[s-1] = l
                jj = l
        }
        return(brk)
}

// ---- Newey-West HAC sandwich for one panel (BFW Prop.1, eq.17-18) ----------
// b_i is OLS of (M Y_i) on Xt = M X_i(K0); Var(b_i) = A^-1 S A^-1 with A=Xt'Xt
// and S the Bartlett-weighted long-run variance of the scores Xt_t * e_t.
real matrix xtkpb_nwhac(real matrix Xt, real colvector e, real matrix Ainv, real scalar w)
{
        real scalar T, p, jj, t
        real matrix S, Lam
        real rowvector zt

        T = rows(Xt)
        p = cols(Xt)
        S = J(p, p, 0)
        for (t=1; t<=T; t++) {
                zt = Xt[t, .]
                S = S + (e[t]*e[t]) * (zt' * zt)
        }
        for (jj=1; jj<=w; jj++) {
                Lam = J(p, p, 0)
                for (t=jj+1; t<=T; t++) {
                        Lam = Lam + (e[t]*e[t-jj]) * (Xt[t,.]' * Xt[t-jj,.])
                }
                S = S + (1 - jj/(w+1)) * (Lam + Lam')
        }
        return(Ainv * S * Ainv)
}

// ---- BREAK engine (BFW 2025) ----------------------------------------------
void xtkpb_break_engine(string scalar yv, string scalar xv, string scalar idv, ///
        string scalar tv, string scalar tousev, real scalar m,                 ///
        real scalar ldg, real scalar pyx, real scalar trim, real scalar hacw,  ///
        real scalar nocons,                                                    ///
        string scalar MGcon, string scalar MGsen, string scalar Bdaten,        ///
        string scalar Bidxn, string scalar MGcopn, string scalar MGsepn,       ///
        string scalar ssrn, string scalar Bin, string scalar Bisen)
{
        real matrix Ymat, xbar, ybar, cons, Hprox, Xi, Wi, Wseg
        real matrix C, MGco, MGse, MGcop, MGsep, Bslp
        real matrix Xblk, K1blk, MK1, Abig, Breg, Psi, R, SigP, VP, Q, sumA
        real matrix Bse_i, Xtil, Vi
        real colvector times, yi, coef, bounds, bd, bidx, dd, bmgr, cbig, bhat
        real colvector bMGfull, bP, sumc, dfull, seP, ei
        real scalar N, T, k, i, ok, q, h, r, nreg, a, b, j, feas, p2, w
        pointer(real matrix) rowvector Xp, Wp, Ap
        real rowvector brk
        real scalar totssr

        N = 0
        T = 0
        k = 0
        ok = xtkpb_reshape(yv, xv, idv, tv, tousev, Ymat, Xp, N, T, k)

        st_numscalar("r(N_g)",  N)
        st_numscalar("r(Tbar)", T)
        st_numscalar("r(nobs)", N*T)
        if (ok==0) {
                st_numscalar("r(balanced)", 0)
                st_numscalar("r(feasible)", 0)
                return
        }
        st_numscalar("r(balanced)", 1)

        times = uniqrows(st_data(., tv, tousev))

        // cross-section averages
        ybar = J(T, 1, 0)
        xbar = J(T, k, 0)
        for (i=1; i<=N; i++) {
                ybar = ybar + Ymat[., i]
                xbar = xbar + *Xp[i]
        }
        ybar = ybar :/ N
        xbar = xbar :/ N
        cons = J(T, 1, 1)

        // proxy block (BFW eq.9 uses x-bar only; the constant is the KPY D term
        // and is included unless noconstant is specified)
        if (nocons==1) {
                if (pyx==1) {
                        Hprox = ybar, xbar
                }
                else {
                        Hprox = xbar
                }
        }
        else {
                if (pyx==1) {
                        Hprox = cons, ybar, xbar
                }
                else {
                        Hprox = cons, xbar
                }
        }

        // ---- break-DATE estimation: fully-broken z=(x,proxy), BFW eq.(11)-(13) ----
        // Unrestricted segment-additive SSR (per-regime OLS of y on [x,proxy]);
        // the DP objective is identical whether or not loadings break.
        p2 = cols(Hprox)
        Wp = J(1, N, NULL)
        for (i=1; i<=N; i++) {
                Xi = *Xp[i]
                Wp[i] = &(Xi, Hprox)
        }
        q = k + p2

        // minimum segment length: each regime needs > (k+p2) free parameters
        h = floor(trim*T)
        if (h < q+1) {
                h = q + 1
        }
        feas = 1
        if ((m+1)*h > T) {
                feas = 0
        }
        st_numscalar("r(feasible)", feas)
        if (feas==0) {
                return
        }

        // Newey-West window (auto = floor(4 (T/100)^(2/9)) if hacw < 0)
        if (hacw < 0) {
                w = floor(4 * (T/100)^(2/9))
        }
        else {
                w = hacw
        }
        if (w < 0) {
                w = 0
        }
        if (w > T-1) {
                w = T - 1
        }
        st_numscalar("r(hacw)", w)

        xtkpb_costmat(Wp, Ymat, N, T, q, h, C)
        brk = xtkpb_dp(C, T, m, h)

        nreg = m + 1
        bounds = J(nreg+1, 1, 0)
        bounds[1] = 0
        for (j=1; j<=m; j++) {
                bounds[j+1] = brk[j]
        }
        bounds[nreg+1] = T

        // total SSR of the fully-broken z model at the optimum (BFW eq.13 objective)
        totssr = 0
        for (i=1; i<=N; i++) {
                Wi = *Wp[i]
                for (r=1; r<=nreg; r++) {
                        a = bounds[r] + 1
                        b = bounds[r+1]
                        Wseg = Wi[a::b, .]
                        yi   = Ymat[a::b, i]
                        coef = invsym(Wseg'Wseg) * Wseg'yi
                        totssr = totssr + (yi - Wseg*coef)' * (yi - Wseg*coef)
                }
        }

        // ---- loading (proxy) projection M_X(K1), common across panels ----
        //   model 4 (loadings constant): X(K1) = global proxy  -> BFW eq.(14)
        //   model 5 (loadings break)   : X(K1) = block-diagonal -> BFW eq.(15)
        if (ldg==0) {
                K1blk = Hprox
        }
        else {
                K1blk = J(T, p2*nreg, 0)
                for (r=1; r<=nreg; r++) {
                        a = bounds[r] + 1
                        b = bounds[r+1]
                        K1blk[a::b, ((r-1)*p2+1)::(r*p2)] = Hprox[a::b, .]
                }
        }
        MK1 = I(T) - K1blk * invsym(K1blk'K1blk) * K1blk'

        // ---- SLOPE estimation: partitioned CCE regression, BFW eq.(14)-(15) ----
        //   bhat_i = [X_i(K0)' M_X(K1) X_i(K0)]^-1 X_i(K0)' M_X(K1) Y_i
        //   X_i(K0) is X_i made block-diagonal across the m+1 regimes.
        Breg  = J(nreg*k, N, .)
        Bse_i = J(nreg*k, N, .)
        Ap    = J(1, N, NULL)
        for (i=1; i<=N; i++) {
                Xi = *Xp[i]
                yi = Ymat[., i]
                Xblk = J(T, k*nreg, 0)
                for (r=1; r<=nreg; r++) {
                        a = bounds[r] + 1
                        b = bounds[r+1]
                        Xblk[a::b, ((r-1)*k+1)::(r*k)] = Xi[a::b, .]
                }
                Abig = Xblk' * MK1 * Xblk
                cbig = Xblk' * MK1 * yi
                bhat = invsym(Abig) * cbig
                Breg[., i] = bhat
                Ap[i] = &(Xblk' * MK1 * Xblk)
                // individual Newey-West s.e. (BFW Prop.1, eq.17-18)
                Xtil = MK1 * Xblk
                ei   = MK1*yi - Xtil*bhat
                Vi   = xtkpb_nwhac(Xtil, ei, invsym(Abig), w)
                Bse_i[., i] = sqrt(diagonal(Vi))
        }

        // full-length mean group (stack of all regime slopes)
        bMGfull = J(nreg*k, 1, 0)
        for (i=1; i<=N; i++) {
                bMGfull = bMGfull + Breg[., i]
        }
        bMGfull = bMGfull :/ N

        // pooled point estimate (BFW footnote 13; eq.19)
        sumA = J(nreg*k, nreg*k, 0)
        sumc = J(nreg*k, 1, 0)
        for (i=1; i<=N; i++) {
                sumA = sumA + *Ap[i]
                sumc = sumc + (*Ap[i]) * Breg[., i]
        }
        bP = invsym(sumA) * sumc

        // pooled variance (sandwich, analogous to CCEP eq.42-44)
        Psi = J(nreg*k, nreg*k, 0)
        for (i=1; i<=N; i++) {
                Psi = Psi + (*Ap[i]) :/ T
        }
        Psi = Psi :/ N
        R = J(nreg*k, nreg*k, 0)
        for (i=1; i<=N; i++) {
                Q = (*Ap[i]) :/ T
                dfull = Breg[., i] - bMGfull
                R = R + Q*dfull*dfull'*Q
        }
        R = R :/ (N-1)
        SigP = invsym(Psi) * R * invsym(Psi)
        VP   = SigP :/ N
        seP  = sqrt(diagonal(VP))

        // ---- regime tables: mean group (Prop.2) and pooled (footnote 13) ----
        MGco  = J(nreg, k, .)
        MGse  = J(nreg, k, .)
        MGcop = J(nreg, k, .)
        MGsep = J(nreg, k, .)
        for (r=1; r<=nreg; r++) {
                Bslp = Breg[((r-1)*k+1)::(r*k), .]
                bmgr = J(k, 1, 0)
                for (i=1; i<=N; i++) {
                        bmgr = bmgr + Bslp[., i]
                }
                bmgr = bmgr :/ N
                dd = J(k, 1, 0)
                for (i=1; i<=N; i++) {
                        dd = dd + (Bslp[., i]-bmgr):^2
                }
                MGco[r, .]  = bmgr'
                MGse[r, .]  = sqrt(dd :/ (N*(N-1)))'
                MGcop[r, .] = (bP[((r-1)*k+1)::(r*k)])'
                MGsep[r, .] = (seP[((r-1)*k+1)::(r*k)])'
        }

        bidx = J(m, 1, .)
        bd   = J(m, 1, .)
        for (j=1; j<=m; j++) {
                bidx[j] = brk[j]
                bd[j]   = times[brk[j]]
        }

        st_matrix(MGcon,  MGco)
        st_matrix(MGsen,  MGse)
        st_matrix(MGcopn, MGcop)
        st_matrix(MGsepn, MGsep)
        st_matrix(Bdaten, bd)
        st_matrix(Bidxn,  bidx)
        st_matrix(ssrn, totssr)
        st_matrix(Bin,   Breg)
        st_matrix(Bisen, Bse_i)
}

// ---- stack regime coefficients into b (1 x p) and V (p x p block) ---------
void xtkpb_break_post(string scalar MGcon, string scalar MGsen, ///
        string scalar bn, string scalar Vn, real scalar nreg, real scalar k)
{
        real matrix MGco, MGse, V
        real rowvector b
        real scalar r, j, p, pos

        MGco = st_matrix(MGcon)
        MGse = st_matrix(MGsen)
        p = nreg*k
        b = J(1, p, 0)
        V = J(p, p, 0)
        pos = 0
        for (r=1; r<=nreg; r++) {
                for (j=1; j<=k; j++) {
                        pos = pos + 1
                        b[pos] = MGco[r, j]
                        V[pos, pos] = MGse[r, j]^2
                }
        }
        st_matrix(bn, b)
        st_matrix(Vn, V)
}

end
