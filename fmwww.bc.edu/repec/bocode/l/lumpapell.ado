*! version 1.5.9  06aug2026  Ozan Eruygur
*! lumpapell: Lumsdaine-Papell (1997) unit root test with structural breaks
*! Port of the RATS procedure lpunit.src (Tom Doan, Estima, revision 05/2017)
*! plus an article mode replicating Lumsdaine-Papell (1997): model CA, the
*! article grid, per-combination general-to-specific lag selection, and the
*! article finite-sample critical values
*! two structural breaks at unknown dates

program define lumpapell, rclass
    version 11.0
    syntax varname(numeric ts) [if] [in] [, Break(string) NBreaks(integer 2) Method(string) Lags(integer -1) MAXLags(integer -1) SIGnif(real 0.10) PI(real 0.15) CV(string) TCrit(real -1) PAPER RATSOut Graph noPRint Title(string asis)]

    * ------------------------------------------------------------------
    * Parse break() : intercept (default) / trend / both / ca -> 1/2/3/4
    * ------------------------------------------------------------------
    local brk = lower(trim(`"`break'"'))
    if `"`brk'"'=="" local brk "intercept"
    local breakn 0
    if `"`brk'"'=="intercept" local breakn 1
    if `"`brk'"'=="trend" local breakn 2
    if `"`brk'"'=="both" local breakn 3
    if `"`brk'"'=="ca" local breakn 4
    if `breakn'==0 {
        di as error "break() must be intercept, trend, both, or ca"
        exit 198
    }

    * ------------------------------------------------------------------
    * Parse method() : input (default) / aic / bic / hq / ttest / gtos
    * gtos and ttest are identical (as in the RATS code, lmethod 6 -> 5)
    * ------------------------------------------------------------------
    local mth = lower(trim(`"`method'"'))
    if `"`mth'"'=="" local mth "input"
    local lmethod 0
    if `"`mth'"'=="input" local lmethod 1
    if `"`mth'"'=="aic" local lmethod 2
    if `"`mth'"'=="bic" local lmethod 3
    if `"`mth'"'=="hq" local lmethod 4
    if `"`mth'"'=="ttest" local lmethod 5
    if `"`mth'"'=="gtos" local lmethod 5
    if `lmethod'==0 {
        di as error "method() must be input, aic, bic, hq, ttest, or gtos"
        exit 198
    }

    if `nbreaks'<0 {
        di as error "nbreaks() must be a nonnegative integer"
        exit 198
    }
    if `pi'<=0 | `pi'>=1 {
        di as error "pi() must be strictly between 0 and 1"
        exit 198
    }
    if `signif'<=0 | `signif'>=1 {
        di as error "signif() must be strictly between 0 and 1"
        exit 198
    }
    if `lags'<-1 | `maxlags'<-1 {
        di as error "lags() and maxlags() must be nonnegative integers"
        exit 198
    }

    * ------------------------------------------------------------------
    * Article mode switches: paper, cv(), tcrit(), break(ca)
    * ------------------------------------------------------------------
    local papermode = cond("`paper'"!="", 1, 0)
    if `breakn'==4 & `papermode'==0 {
        di as error "break(ca) requires the paper option"
        exit 198
    }
    if `breakn'==4 & `nbreaks'!=2 {
        di as error "break(ca) requires nbreaks(2)"
        exit 198
    }
    local cvsrc = lower(trim(`"`cv'"'))
    if `papermode'==1 & `"`cvsrc'"'=="" local cvsrc "paper"
    if `"`cvsrc'"'=="" local cvsrc "rats"
    if `"`cvsrc'"'!="rats" & `"`cvsrc'"'!="paper" {
        di as error "cv() must be rats or paper"
        exit 198
    }
    if `"`cvsrc'"'=="paper" {
        if `nbreaks'!=2 | `breakn'==2 {
            di as error "cv(paper) is available only for nbreaks(2) with break(intercept), break(ca), or break(both)"
            exit 198
        }
    }
    if `breakn'==4 & `"`cvsrc'"'=="rats" {
        di as error "no RATS critical values exist for model CA; use cv(paper)"
        exit 198
    }
    if `tcrit'!=-1 & `tcrit'<=0 {
        di as error "tcrit() must be a positive number"
        exit 198
    }
    if `tcrit'>0 & `tcrit'<. & `lmethod'!=5 {
        di as error "tcrit() may be combined only with method(ttest) or method(gtos)"
        exit 198
    }
    if `papermode'==1 & `lmethod'==5 & `tcrit'==-1 local tcrit = 1.60

    * ------------------------------------------------------------------
    * Time-series settings
    * ------------------------------------------------------------------
    capture tsset
    if _rc {
        di as error "the data must be tsset before using lumpapell"
        exit 111
    }
    if "`r(panelvar)'"!="" {
        di as error "lumpapell works on a single time series; panel data are not allowed"
        exit 198
    }
    local tvar `r(timevar)'
    local dlt = r(tdelta)
    local tsfmt "`r(tsfmt)'"
    if `dlt'>=. local dlt 1

    tsrevar `varlist'
    local tv `r(varlist)'

    * entry numbering: entry 1 = first observation in the dataset
    * (matches a RATS workspace whose CALENDAR begins at the start of the data)
    quietly summarize `tvar', meanonly
    local tmin = r(min)

    * ------------------------------------------------------------------
    * [in] maps to the RATS start/end parameters (range restriction)
    * [if] maps to the RATS SMPL option (rows skipped inside the range)
    * ------------------------------------------------------------------
    tempvar inrng smplv okv wsel
    quietly gen byte `inrng' = 0
    quietly replace `inrng' = 1 `in'
    quietly gen byte `smplv' = 0
    quietly replace `smplv' = 1 `if'

    * range available for the series and one lag (RATS: inquire(reglist) # series{0 1})
    quietly gen byte `okv' = `inrng' & !missing(`tv') & !missing(L.`tv')
    quietly count if `okv'
    if r(N)==0 {
        di as error "no observations with both the series and its first lag available"
        exit 2000
    }
    quietly summarize `tvar' if `okv', meanonly
    local startl = round((r(min)-`tmin')/`dlt') + 1
    local endl = round((r(max)-`tmin')/`dlt') + 1

    * the time grid must be gap-free on [startl-1, endl]
    local t_lo = `tmin' + (`startl'-2)*`dlt'
    local t_hi = `tmin' + (`endl'-1)*`dlt'
    quietly count if `tvar'>=`t_lo' & `tvar'<=`t_hi'
    if r(N) != `endl'-`startl'+2 {
        di as error "gaps found in the time variable within the estimation window; run tsfill first"
        exit 498
    }
    quietly gen byte `wsel' = `tvar'>=`t_lo' & `tvar'<=`t_hi'

    * ------------------------------------------------------------------
    * maxlag resolution (RATS lines 135-141) and the raw MAXLAGS value
    * used for pinobs (RATS line 124 uses the option value, 0 if not given)
    * ------------------------------------------------------------------
    local maxlag0 = -1
    if `lags'>=0 local maxlag0 = `lags'
    else if `maxlags'>=0 local maxlag0 = `maxlags'
    local mlraw = cond(`maxlags'>=0, `maxlags', 0)

    * ------------------------------------------------------------------
    * Core computation in Mata
    * ------------------------------------------------------------------
    mata: lumpapell_main("`tv'", "`tvar'", "`smplv'", "`wsel'", `tmin', `dlt', `startl', `endl', `breakn', `nbreaks', `lmethod', `maxlag0', `mlraw', `signif', `pi', `papermode', `tcrit')

    local mrc = __lp_rc
    if `mrc'==1 {
        capture scalar drop __lp_rc
        di as error "too few usable observations for the requested specification"
        exit 2001
    }
    if `mrc'==2 {
        capture scalar drop __lp_rc
        di as error "pi() and the sample length imply a trimming window of zero observations; increase pi() or the sample"
        exit 498
    }
    if `mrc'==3 {
        capture scalar drop __lp_rc
        di as error "too few observations for nbreaks() breaks with the requested grid"
        exit 2001
    }

    tempname smint
    scalar `smint' = __lp_mint
    local bestlag = __lp_bestlag
    local maxlag = __lp_maxlag
    local pinobs = __lp_pinobs
    local N = __lp_N
    local K = __lp_K
    tempname bmat tmat bpsmat
    matrix `bmat' = __lp_b
    matrix `tmat' = __lp_t
    if `nbreaks'>0 matrix `bpsmat' = __lp_bps
    capture scalar drop __lp_rc __lp_mint __lp_bestlag __lp_maxlag __lp_pinobs __lp_N __lp_K
    capture matrix drop __lp_b __lp_t __lp_bps

    * ------------------------------------------------------------------
    * Break dates as time values and display labels
    * ------------------------------------------------------------------
    local dlist ""
    local blabels ""
    if `nbreaks'>0 {
        forvalues i = 1/`nbreaks' {
            local e_i = `bpsmat'[1,`i']
            local tv_`i' = `tmin' + (`e_i'-1)*`dlt'
            local dl_`i' = trim(`"`: display `tsfmt' `tv_`i'''"')
            local dlist "`dlist' `dl_`i''"
            local blabels "`blabels'`dl_`i'' "
        }
    }

    * ------------------------------------------------------------------
    * Break dummies and trend written to the dataset (lumpapell_ prefix)
    * and the manual regress command that reproduces the break regression
    * ------------------------------------------------------------------
    capture drop lumpapell_*
    tempvar entv
    quietly gen double `entv' = round((`tvar'-`tmin')/`dlt') + 1
    quietly gen int lumpapell_trend = `entv'
    label variable lumpapell_trend "lumpapell: trend (entry number, first obs = 1)"
    local dvars ""
    if `nbreaks'>0 {
        forvalues i = 1/`nbreaks' {
            local e_i = `bpsmat'[1,`i']
            local mkdu = (`breakn'==1 | `breakn'==3 | `breakn'==4)
            local mkdt = (`breakn'==2 | `breakn'==3 | (`breakn'==4 & `i'==1))
            if `mkdu' {
                quietly gen byte lumpapell_du`i' = `entv' > `e_i'
                label variable lumpapell_du`i' "lumpapell: D(`dl_`i'')"
                local dvars "`dvars' lumpapell_du`i'"
            }
            if `mkdt' {
                quietly gen int lumpapell_dt`i' = (`entv' - `e_i') * (`entv' > `e_i')
                label variable lumpapell_dt`i' "lumpapell: DT(`dl_`i'')"
                local dvars "`dvars' lumpapell_dt`i'"
            }
        }
    }
    local fromt2 = `tmin' + (`startl'+`bestlag'-1)*`dlt'
    local endt2 = `tmin' + (`endl'-1)*`dlt'
    local lagpart ""
    if `bestlag'>0 local lagpart " L(1/`bestlag').D.`varlist'"
    * sample condition needed only when the user restricted with [in] or [if];
    * on a full series the lag operators already reproduce the sample
    local conds ""
    if `"`in'"'!="" {
        local fam = substr("`tsfmt'",1,3)
        local tfun ""
        if "`fam'"=="%tq" local tfun "tq"
        if "`fam'"=="%tm" local tfun "tm"
        if "`fam'"=="%tw" local tfun "tw"
        if "`fam'"=="%th" local tfun "th"
        if "`fam'"=="%td" local tfun "td"
        if "`tfun'"!="" {
            local fl = trim(`"`: display `fam' `fromt2''"')
            local el = trim(`"`: display `fam' `endt2''"')
            local conds "`tvar'>=`tfun'(`fl') & `tvar'<=`tfun'(`el')"
        }
        else local conds "`tvar'>=`fromt2' & `tvar'<=`endt2'"
    }
    if `"`if'"'!="" {
        local uexp0 = subinstr(`"`if'"', "if ", "", 1)
        if `"`conds'"'=="" local conds "(`uexp0')"
        else local conds "`conds' & (`uexp0')"
    }
    if `"`conds'"'=="" local regcmd `"regress D.`varlist' L.`varlist'`dvars' lumpapell_trend`lagpart'"'
    else local regcmd `"regress D.`varlist' L.`varlist'`dvars' lumpapell_trend`lagpart' if `conds'"'

    * ------------------------------------------------------------------
    * Critical values: RATS table (default) or the article's finite-sample
    * table (cv(paper); T=125, includes the 2.5 percent level)
    * ------------------------------------------------------------------
    tempname cv1 cv25 cv5 cv10
    scalar `cv1' = .
    scalar `cv25' = .
    scalar `cv5' = .
    scalar `cv10' = .
    if `"`cvsrc'"'=="paper" {
        if `breakn'==1 {
            scalar `cv1' = -6.94
            scalar `cv25' = -6.53
            scalar `cv5' = -6.24
            scalar `cv10' = -5.96
        }
        if `breakn'==4 {
            scalar `cv1' = -7.24
            scalar `cv25' = -7.02
            scalar `cv5' = -6.65
            scalar `cv10' = -6.33
        }
        if `breakn'==3 {
            scalar `cv1' = -7.34
            scalar `cv25' = -7.02
            scalar `cv5' = -6.82
            scalar `cv10' = -6.49
        }
    }
    else if `nbreaks'==0 {
        local n0 = `N' + 1
        scalar `cv1' = -3.9638 - 8.353/`n0' - 47.44/(`n0'^2)
        scalar `cv5' = -3.4126 - 4.039/`n0' - 17.83/(`n0'^2)
        scalar `cv10' = -3.1279 - 2.418/`n0' - 7.58/(`n0'^2)
    }
    else if `nbreaks'==1 {
        if `breakn'==1 {
            scalar `cv1' = -5.34
            scalar `cv5' = -4.80
            scalar `cv10' = -4.58
        }
        if `breakn'==2 {
            scalar `cv1' = -4.93
            scalar `cv5' = -4.42
            scalar `cv10' = -4.11
        }
        if `breakn'==3 {
            scalar `cv1' = -5.57
            scalar `cv5' = -5.08
            scalar `cv10' = -4.82
        }
    }
    else if `nbreaks'==2 {
        if `breakn'==1 {
            scalar `cv1' = -6.74
            scalar `cv5' = -6.16
            scalar `cv10' = -5.89
        }
        if `breakn'==2 {
            scalar `cv1' = -7.19
            scalar `cv5' = -6.62
            scalar `cv10' = -6.37
        }
        if `breakn'==3 {
            scalar `cv1' = -7.19
            scalar `cv5' = -6.75
            scalar `cv10' = -6.48
        }
    }

    * significance tag: ** below the 1% value, * below the 5% value
    local stars ""
    if `cv5'<. & `smint'<`cv5' local stars "*"
    if `cv1'<. & `smint'<`cv1' local stars "**"

    * ------------------------------------------------------------------
    * Graph (RATS lines 254-257; drawn regardless of print, as in RATS)
    * ------------------------------------------------------------------
    if "`graph'"!="" {
        twoway tsline `tv', tline(`dlist') note("Series with Breaks Highlighted") name(lumpapell, replace)
    }

    * ------------------------------------------------------------------
    * Coefficient labels: Y{1}, then break dummies, Constant, Trend, lags
    * Model CA order: D(TB1) DT(TB1) D(TB2), as in Table 4 of the article
    * ------------------------------------------------------------------
    local vlabs `""Y{c -(}1{c )-}""'
    local cnames "Y1"
    if `breakn'==4 {
        local vlabs `"`vlabs' "D(`dl_1')" "DT(`dl_1')" "D(`dl_2')""'
        local cnames "`cnames' D1 DT1 D2"
    }
    else if `nbreaks'>0 {
        forvalues i = 1/`nbreaks' {
            if `breakn'!=2 {
                local vlabs `"`vlabs' "D(`dl_`i'')""'
                local cnames "`cnames' D`i'"
            }
            if `breakn'!=1 {
                local vlabs `"`vlabs' "DT(`dl_`i'')""'
                local cnames "`cnames' DT`i'"
            }
        }
    }
    local vlabs `"`vlabs' "Constant" "Trend""'
    local cnames "`cnames' Constant Trend"
    if `bestlag'>0 {
        forvalues j = 1/`bestlag' {
            local vlabs `"`vlabs' "dy{c -(}`j'{c )-}""'
            local cnames "`cnames' dyL`j'"
        }
    }
    matrix colnames `bmat' = `cnames'
    matrix colnames `tmat' = `cnames'

    * readable labels for the default report: lags as y(-1), dy(-1), dy(-2)
    local vlabs2 `""y(-1)""'
    if `breakn'==4 {
        local vlabs2 `"`vlabs2' "D(`dl_1')" "DT(`dl_1')" "D(`dl_2')""'
    }
    else if `nbreaks'>0 {
        forvalues i = 1/`nbreaks' {
            if `breakn'!=2 local vlabs2 `"`vlabs2' "D(`dl_`i'')""'
            if `breakn'!=1 local vlabs2 `"`vlabs2' "DT(`dl_`i'')""'
        }
    }
    local vlabs2 `"`vlabs2' "Constant" "Trend""'
    if `bestlag'>0 {
        forvalues j = 1/`bestlag' {
            local vlabs2 `"`vlabs2' "dy(-`j')""'
        }
    }

    * ------------------------------------------------------------------
    * Report: default format below; ratsout reproduces the RATS layout
    * ------------------------------------------------------------------
    if "`ratsout'"!="" {
        if "`print'"!="noprint" {
            if `"`title'"'=="" local title "Lumsdaine-Papell Unit Root Test, Series `varlist'"
            local frome = `startl' + `bestlag' + 1
            local fromt = `tmin' + (`frome'-1)*`dlt'
            local endt = `tmin' + (`endl'-1)*`dlt'
            local froml = trim(`"`: display `tsfmt' `fromt''"')
            local endll = trim(`"`: display `tsfmt' `endt''"')
            di as text ""
            di as text `"`title'"'
            di as text "Regression Run From `froml' to `endll'"
            di as text "Observations " as result `N'
            if `nbreaks'==0 local descript "None -- Dickey-Fuller Test"
            if `nbreaks'>0 & `breakn'==1 local descript "Intercept Only"
            if `nbreaks'>0 & `breakn'==2 local descript "Trend Only"
            if `nbreaks'>0 & `breakn'==3 local descript "Intercept and Trend"
            if `breakn'==4 local descript "Model CA (Intercept and Trend; Intercept Only)"
            di as text "Breaks in `descript'"
            if `nbreaks'>0 di as text "Breaks at `blabels'"
            if `lmethod'==1 di as text "Using fixed lags " as result `bestlag'
            else di as text "With " as result `bestlag' as text " lags chosen from " as result `maxlag'
            if `lmethod'==1 local llagmethod "User"
            if `lmethod'==2 local llagmethod "AIC"
            if `lmethod'==3 local llagmethod "BIC"
            if `lmethod'==4 local llagmethod "HQ"
            if `lmethod'==5 {
                if `tcrit'>0 & `tcrit'<. {
                    local tcs = trim(`"`: display %5.2f `tcrit''"')
                    local llagmethod "GTOS/t-tests(|t|>=`tcs')"
                }
                else {
                    local sg = trim(`"`: display %5.2f `signif''"')
                    local llagmethod "GTOS/t-tests(`sg')"
                }
            }
            di as text "Selected by `llagmethod'"
            di as text "Sig Level" _col(13) %14s "Crit Value"
            if `cv1'<. di as text "1%(**)" _col(13) as result %14.4f `cv1'
            else di as text "1%(**)" _col(13) %14s "NA"
            if `cv25'<. di as text "2.5%" _col(13) as result %14.4f `cv25'
            if `cv5'<. di as text "5%(*)" _col(13) as result %14.4f `cv5'
            else di as text "5%(*)" _col(13) %14s "NA"
            if `cv10'<. di as text "10%" _col(13) as result %14.4f `cv10'
            else di as text "10%" _col(13) %14s "NA"
            di as text ""
            di as text "Variable" _col(15) %14s "Coefficient" %14s "T-Stat"
            local pos 1
            foreach lab of local vlabs {
                local bb = `bmat'[1,`pos']
                local tt = `tmat'[1,`pos']
                if `pos'==1 di as text `"`lab'"' _col(15) as result %14.4f `bb' %14.4f `tt' " `stars'"
                else di as text `"`lab'"' _col(15) as result %14.4f `bb' %14.4f `tt'
                local pos = `pos' + 1
            }
            di as text ""
        }
    }
    else if "`print'"!="noprint" {
        local endt = `tmin' + (`endl'-1)*`dlt'
        local endll = trim(`"`: display `tsfmt' `endt''"')
        local truee = `startl' + `bestlag'
        local truet = `tmin' + (`truee'-1)*`dlt'
        local truel = trim(`"`: display `tsfmt' `truet''"')
        if `nbreaks'==0 local mdesc "Augmented Dickey-Fuller, no breaks"
        if `nbreaks'>0 & `breakn'==1 local mdesc "Intercept breaks (DU)"
        if `nbreaks'==2 & `breakn'==1 local mdesc "AA - both breaks in the intercept (DU)"
        if `nbreaks'>0 & `breakn'==2 local mdesc "Trend breaks (DT)"
        if `nbreaks'>0 & `breakn'==3 local mdesc "Intercept and trend breaks (DU and DT)"
        if `nbreaks'==2 & `breakn'==3 local mdesc "CC - both breaks in intercept and trend (DU and DT)"
        if `breakn'==4 local mdesc "CA - TB1: intercept and trend; TB2: intercept only"
        local modetxt = cond(`papermode'==1, "article (Lumsdaine-Papell 1997)", "RATS (lpunit.src)")
        local pis = trim(`"`: display %5.2f `pi''"')
        if `papermode'==1 local gdesc "article grid (2nd to next-to-last obs, min gap 2)"
        else local gdesc "RATS grid (pi = `pis', min gap `pinobs' obs)"
        if `lmethod'==1 local ldesc "Fixed (input)"
        if `lmethod'==2 local ldesc "AIC"
        if `lmethod'==3 local ldesc "BIC"
        if `lmethod'==4 local ldesc "Hannan-Quinn"
        if `lmethod'==5 {
            local tcs = trim(`"`: display %5.2f `tcrit''"')
            local sg = trim(`"`: display %5.2f `signif''"')
            if `tcrit'>0 & `tcrit'<. local ldesc "Sequential t-test (|t| >= `tcs')"
            else local ldesc "Sequential t-test (p <= `sg')"
        }
        di as text ""
        if `"`title'"'!="" di as text `"`title'"'
        di as text "Lumsdaine-Papell test for unit root" _col(46) "Number of obs    = " as result %6.0f `N'
        di as text "Variable: " as result "`varlist'" as text _col(46) "Number of breaks = " as result %6.0f `nbreaks'
        di as text ""
        di as text "  Model" _col(18) ": " as result "`mdesc'"
        di as text "  Mode" _col(18) ": " as result "`modetxt'"
        di as text "  Break grid" _col(18) ": " as result "`gdesc'"
        di as text "  Lag selection" _col(18) ": " as result "`ldesc'"
        di as text "  Selected lag" _col(18) ": " as result `bestlag' as text "  (maximum " as result `maxlag' as text ")"
        di as text "  Sample" _col(18) ": " as result "`truel' - `endll'"
        di as text ""
        di as text "H0: " as result "`varlist'" as text " has a unit root"
        di as text ""
        if `cv25'<. {
            di as text _col(30) "Lumsdaine-Papell"
            di as text _col(12) "Test" _col(22) "----------- critical value -----------"
            di as text _col(9) "statistic" _col(27) "1%" _col(35) "2.5%" _col(44) "5%" _col(52) "10%"
            di as text "{hline 58}"
            di as text " t(alpha)" _col(12) as result %8.3f `smint' _col(21) %8.3f `cv1' _col(30) %8.3f `cv25' _col(39) %8.3f `cv5' _col(47) %8.3f `cv10'
            di as text "{hline 58}"
        }
        else if `cv1'<. {
            di as text _col(28) "Lumsdaine-Papell"
            di as text _col(12) "Test" _col(22) "------- critical value -------"
            di as text _col(9) "statistic" _col(27) "1%" _col(36) "5%" _col(44) "10%"
            di as text "{hline 50}"
            di as text " t(alpha)" _col(12) as result %8.3f `smint' _col(21) %8.3f `cv1' _col(30) %8.3f `cv5' _col(38) %8.3f `cv10'
            di as text "{hline 50}"
        }
        else {
            di as text "  Test statistic t(alpha) = " as result %9.3f `smint' as text "  (no tabulated critical values)"
        }
        if `cv1'<. {
            local rj1 = cond(`smint'<`cv1', "Reject", "Do not reject")
            di as text " - `rj1' H0 at the 1% significance level"
        }
        if `cv25'<. {
            local rj25 = cond(`smint'<`cv25', "Reject", "Do not reject")
            di as text " - `rj25' H0 at the 2.5% significance level"
        }
        if `cv5'<. {
            local rj5 = cond(`smint'<`cv5', "Reject", "Do not reject")
            di as text " - `rj5' H0 at the 5% significance level"
        }
        if `cv10'<. {
            local rj10 = cond(`smint'<`cv10', "Reject", "Do not reject")
            di as text " - `rj10' H0 at the 10% significance level"
        }
        di as text ""
        if `nbreaks'>0 {
            forvalues i = 1/`nbreaks' {
                local e_i = `bpsmat'[1,`i']
                if `breakn'==1 local comp "intercept"
                if `breakn'==2 local comp "trend"
                if `breakn'==3 local comp "intercept and trend"
                if `breakn'==4 local comp = cond(`i'==1, "intercept and trend", "intercept")
                di as text "  Break `i' (TB`i')" _col(18) ": " as result "`dl_`i''" as text " (obs: " as result `e_i' as text ") - `comp'"
            }
            di as text ""
        }
        di as text "Break regression at the selected break dates:"
        di as text "Dependent variable: " as result "dy = D.`varlist'"
        di as text "Variable" _col(15) %14s "Coefficient" %14s "T-Stat"
        local pos 1
        foreach lab of local vlabs2 {
            local bb = `bmat'[1,`pos']
            local tt = `tmat'[1,`pos']
            di as text `"`lab'"' _col(15) as result %14.4f `bb' %14.4f `tt'
            local pos = `pos' + 1
        }
        di as text ""
        di as text "Replicate the break regression manually with:"
        di as text "  . " as result `"`regcmd'"'
        di as text ""
    }

    * ------------------------------------------------------------------
    * Stored results
    * ------------------------------------------------------------------
    return scalar cdstat = `smint'
    return scalar N = `N'
    return scalar autop = `bestlag'
    return scalar lags = `bestlag'
    return scalar maxlag = `maxlag'
    return scalar pinobs = `pinobs'
    return scalar pi = `pi'
    return scalar signif = `signif'
    return scalar nbreaks = `nbreaks'
    return scalar cv1 = `cv1'
    return scalar cv5 = `cv5'
    return scalar cv10 = `cv10'
    if `cv25'<. return scalar cv25 = `cv25'
    if `tcrit'>0 & `tcrit'<. return scalar tcrit = `tcrit'
    if `nbreaks'>=1 {
        return scalar minent = `tv_1'
        tempname brtimes
        matrix `brtimes' = J(1, `nbreaks', .)
        forvalues i = 1/`nbreaks' {
            matrix `brtimes'[1,`i'] = `tv_`i''
            return scalar break`i' = `tv_`i''
        }
        return matrix breaks = `brtimes'
    }
    if `nbreaks'>=2 return scalar maxent = `tv_2'
    return local mode = cond(`papermode'==1, "paper", "rats")
    return local cvsource "`cvsrc'"
    return local breakdates "`blabels'"
    return local break "`brk'"
    return local method "`mth'"
    return local tsfmt "`tsfmt'"
    return local varname "`varlist'"
    return local regcmd `"`regcmd'"'
    return local cmd "lumpapell"
    return matrix b = `bmat'
    return matrix t = `tmat'
end

version 11.0
mata:

// ---------------------------------------------------------------------
// OLS via quad-precision cross moments (mirrors the moment-matrix OLS
// used by RATS CMOM/LINREG). Returns (K+1) x 2:
// rows 1..K = (b, t), row K+1 = (rss, ndf)
// ---------------------------------------------------------------------
real matrix lumpapell_ols(real matrix X, real colvector y)
{
    real matrix XX, Vi, R
    real colvector Xy, b, se, t
    real scalar yy, rss, n, k, s2

    n = rows(X)
    k = cols(X)
    XX = quadcross(X, X)
    Xy = quadcross(X, y)
    yy = quadcross(y, y)
    Vi = invsym(XX)
    b = Vi * Xy
    rss = yy - quadcross(Xy, b)
    s2 = rss / (n - k)
    se = sqrt(s2 :* diagonal(Vi))
    t = b :/ se
    R = (b, t) \ (rss, n - k)
    return(R)
}

// ---------------------------------------------------------------------
// Break dummy columns for a candidate break vector
// brk: 1 = D only, 2 = DT only, 3 = D and DT per break, 4 = model CA
// (D and DT at the first break, D only at the second)
// ---------------------------------------------------------------------
real matrix lumpapell_dummies(real colvector T, real colvector tbv, real scalar brk, real scalar nbreaks)
{
    real matrix B
    real scalar i

    if (brk == 4) {
        B = ((T :> tbv[1]), (T :- tbv[1]) :* (T :> tbv[1]), (T :> tbv[2]))
        return(B)
    }
    B = J(rows(T), 0, .)
    for (i=1; i<=nbreaks; i++) {
        if (brk != 2) B = (B, T :> tbv[i])
        if (brk != 1) B = (B, (T :- tbv[i]) :* (T :> tbv[i]))
    }
    return(B)
}

// ---------------------------------------------------------------------
// Design bundle for a given lag count k: returns (yv, y1, ones, T, Lg)
// with rows startl+k..endl restricted to usable observations
// ---------------------------------------------------------------------
real matrix lumpapell_design(real scalar k, real colvector dyv, real colvector w, real colvector s, real scalar startl, real scalar endl)
{
    real colvector T, posv, keep
    real matrix Lg
    real scalar j, n

    T = (startl + k)::endl
    posv = T :- startl :+ 2
    keep = s[posv] :& (dyv[posv] :< .) :& (w[posv :- 1] :< .)
    for (j=1; j<=k; j++) keep = keep :& (dyv[posv :- j] :< .)
    T = select(T, keep)
    posv = T :- startl :+ 2
    n = rows(T)
    Lg = J(n, 0, .)
    for (j=1; j<=k; j++) Lg = (Lg, dyv[posv :- j])
    return((dyv[posv], w[posv :- 1], J(n, 1, 1), T, Lg))
}

// ---------------------------------------------------------------------
// Evaluate one break combination in article mode: select the lag for
// this combination (per-combination selection, as implied by the k
// columns of Tables 2-4 of the article), run the selected regression,
// and return a header (t1, ksel) \ (n, K) stacked over (b, t)
// ---------------------------------------------------------------------
real matrix lumpapell_eval(real colvector tbv, real scalar brk, real scalar nbreaks, real scalar lmethod, real scalar kmin, real scalar kmax, real scalar signif, real scalar tcrit, real colvector dyv, real colvector w, real colvector s, real scalar startl, real scalar endl)
{
    real matrix B, X, R, Rsel, Z, Zf
    real scalar k, ksel, tl, ndf, sig, ic, icmin, n0, icmult, nsel

    ksel = kmin
    Rsel = J(0, 2, .)
    nsel = .
    if (lmethod == 5) {
        ksel = 0
        for (k=kmax; k>=1; k--) {
            Z = lumpapell_design(k, dyv, w, s, startl, endl)
            B = lumpapell_dummies(Z[., 4], tbv, brk, nbreaks)
            X = (Z[., 2], B, Z[., 3], Z[., 4], Z[., 5..4+k])
            if (rows(X) <= cols(X)) continue
            R = lumpapell_ols(X, Z[., 1])
            if (hasmissing(R[|1,2 \ cols(X),2|])) continue
            tl = R[cols(X), 2]
            ndf = R[rows(R), 2]
            if (tcrit > 0 & tcrit < .) sig = (abs(tl) >= tcrit)
            else sig = (2 * ttail(ndf, abs(tl)) <= signif)
            if (sig) {
                ksel = k
                Rsel = R
                nsel = rows(X)
                break
            }
        }
        if (ksel == 0) {
            Z = lumpapell_design(0, dyv, w, s, startl, endl)
            B = lumpapell_dummies(Z[., 4], tbv, brk, nbreaks)
            X = (Z[., 2], B, Z[., 3], Z[., 4])
            if (rows(X) <= cols(X)) return(J(2, 2, .))
            Rsel = lumpapell_ols(X, Z[., 1])
            if (hasmissing(Rsel[|1,2 \ cols(X),2|])) return(J(2, 2, .))
            nsel = rows(X)
        }
    }
    else if (lmethod >= 2 & lmethod <= 4) {
        // criterion selection on the fixed sample starting at kmax
        Zf = lumpapell_design(kmax, dyv, w, s, startl, endl)
        n0 = rows(Zf)
        B = lumpapell_dummies(Zf[., 4], tbv, brk, nbreaks)
        if (lmethod == 2) icmult = 2 / n0
        else if (lmethod == 3) icmult = ln(n0) / n0
        else icmult = 2 * ln(ln(n0)) / n0
        X = (Zf[., 2], B, Zf[., 3], Zf[., 4])
        if (rows(X) <= cols(X)) return(J(2, 2, .))
        R = lumpapell_ols(X, Zf[., 1])
        if (hasmissing(R[|1,2 \ cols(X),2|])) return(J(2, 2, .))
        icmin = ln(R[rows(R), 1] / n0) + icmult * cols(X)
        ksel = 0
        for (k=kmax; k>=1; k--) {
            X = (Zf[., 2], B, Zf[., 3], Zf[., 4], Zf[., 5..4+k])
            if (rows(X) <= cols(X)) continue
            R = lumpapell_ols(X, Zf[., 1])
            if (hasmissing(R[|1,2 \ cols(X),2|])) continue
            ic = ln(R[rows(R), 1] / n0) + icmult * cols(X)
            if (ic < icmin) {
                icmin = ic
                ksel = k
            }
        }
        // final regression at the selected lag on its own sample
        Z = lumpapell_design(ksel, dyv, w, s, startl, endl)
        B = lumpapell_dummies(Z[., 4], tbv, brk, nbreaks)
        if (ksel > 0) X = (Z[., 2], B, Z[., 3], Z[., 4], Z[., 5..4+ksel])
        else X = (Z[., 2], B, Z[., 3], Z[., 4])
        if (rows(X) <= cols(X)) return(J(2, 2, .))
        Rsel = lumpapell_ols(X, Z[., 1])
        if (hasmissing(Rsel[|1,2 \ cols(X),2|])) return(J(2, 2, .))
        nsel = rows(X)
    }
    else {
        // fixed lag count
        Z = lumpapell_design(kmin, dyv, w, s, startl, endl)
        B = lumpapell_dummies(Z[., 4], tbv, brk, nbreaks)
        if (kmin > 0) X = (Z[., 2], B, Z[., 3], Z[., 4], Z[., 5..4+kmin])
        else X = (Z[., 2], B, Z[., 3], Z[., 4])
        if (rows(X) <= cols(X)) return(J(2, 2, .))
        Rsel = lumpapell_ols(X, Z[., 1])
        if (hasmissing(Rsel[|1,2 \ cols(X),2|])) return(J(2, 2, .))
        nsel = rows(X)
    }
    if (rows(Rsel) < 2) return(J(2, 2, .))
    return((Rsel[1,2], ksel) \ (nsel, rows(Rsel)-1) \ Rsel[1..rows(Rsel)-1, .])
}

// ---------------------------------------------------------------------
// Main routine: RATS path replicates lpunit.src line by line; the
// article path implements the grid and lag selection of the article
// ---------------------------------------------------------------------
void lumpapell_main(string scalar yname, string scalar tname, string scalar sname, string scalar wname, real scalar tmin, real scalar dlt, real scalar startl, real scalar endl, real scalar brk, real scalar nbreaks, real scalar lmethod, real scalar maxlag0, real scalar mlraw, real scalar signif, real scalar pi, real scalar papermode, real scalar tcrit)
{
    real matrix D, R, X, B, Lg, Lg0, C, H
    real colvector w, s, dyv, y1, T, posv, keep, bps, ub, bestb, bestt, bestbps, yv, tbv
    real scalar M, i, j, p, znobs, maxlag, bestlag, lower, pinobs, n0, icmult, ic, icmin, lag, tst, pv, ndf, mint, done, first, K, kmax, kmin, lowc, upc, gap, tb1, tb2, bestN, bestK, bestk

    // load the window [startl-1, endl], sort by time, map to positions
    D = st_data(., (tname, yname, sname), wname)
    D = sort(D, 1)
    M = endl - startl + 2
    w = J(M, 1, .)
    s = J(M, 1, 0)
    for (i=1; i<=rows(D); i++) {
        p = round((D[i,1] - tmin)/dlt) + 1 - (startl - 2)
        w[p] = D[i,2]
        s[p] = D[i,3]
    }

    // dy over positions (position 1 = entry startl-1 has no dy)
    dyv = J(M, 1, .)
    for (p=2; p<=M; p++) dyv[p] = w[p] - w[p-1]

    // pinobs from the raw MAXLAGS option value (RATS lines 124-129)
    lower = startl + mlraw + 1
    pinobs = trunc(pi * (endl - lower + 1))

    // default maxlag (RATS lines 133-141)
    znobs = endl - startl + 1
    if (maxlag0 >= 0) maxlag = maxlag0
    else maxlag = trunc(znobs^0.25)

    // -----------------------------------------------------------------
    // RATS path lag selection on the base model, fixed sample
    // startl+maxlag..endl (RATS lines 147-177); the article path
    // selects the lag per break combination inside the grid instead
    // -----------------------------------------------------------------
    if (lmethod == 1) bestlag = maxlag
    else if (!papermode) {
        T = (startl + maxlag)::endl
        posv = T :- startl :+ 2
        keep = s[posv] :& (dyv[posv] :< .) :& (w[posv :- 1] :< .)
        for (j=1; j<=maxlag; j++) keep = keep :& (dyv[posv :- j] :< .)
        T = select(T, keep)
        posv = T :- startl :+ 2
        n0 = rows(T)
        if (n0 <= 3 + maxlag) {
            st_numscalar("__lp_rc", 1)
            return
        }
        yv = dyv[posv]
        y1 = w[posv :- 1]
        C = (J(n0, 1, 1), T)
        Lg0 = J(n0, 0, .)
        for (j=1; j<=maxlag; j++) Lg0 = (Lg0, dyv[posv :- j])
        if (lmethod == 2) icmult = 2 / n0
        else if (lmethod == 3) icmult = ln(n0) / n0
        else if (lmethod == 4) icmult = 2 * ln(ln(n0)) / n0
        else icmult = 0
        // lag 0 baseline (RATS lines 159-162)
        R = lumpapell_ols((C, y1), yv)
        ic = ln(R[4,1] / n0) + icmult * 3
        icmin = ic
        bestlag = 0
        // loop from maxlag down to 1 (RATS lines 163-177)
        for (lag=maxlag; lag>=1; lag--) {
            X = (C, y1, Lg0[., 1..lag])
            R = lumpapell_ols(X, yv)
            if (lmethod == 5) {
                tst = R[3 + lag, 2]
                ndf = R[rows(R), 2]
                pv = 2 * ttail(ndf, abs(tst))
                if (pv <= signif) {
                    bestlag = lag
                    break
                }
            }
            else {
                ic = ln(R[rows(R), 1] / n0) + icmult * (3 + lag)
                if (ic < icmin) {
                    icmin = ic
                    bestlag = lag
                }
            }
        }
    }
    else bestlag = -1

    if (!papermode) {
        // -------------------------------------------------------------
        // RATS grid over break combinations (RATS lines 193-246)
        // -------------------------------------------------------------
        lower = startl + bestlag + 1
        if (nbreaks > 0 & pinobs < 1) {
            st_numscalar("__lp_rc", 2)
            return
        }
        if (nbreaks > 0) {
            if ((lower - 1) + pinobs * (nbreaks + 1) >= endl + 1) {
                st_numscalar("__lp_rc", 3)
                return
            }
        }
        bps = J(nbreaks, 1, 0)
        ub = J(nbreaks, 1, 0)
        for (i=1; i<=nbreaks; i++) {
            bps[i] = (lower - 1) + pinobs * i
            ub[i] = endl + 1 - pinobs * (nbreaks + 1 - i)
        }

        // estimation rows for the final regressions
        T = (startl + bestlag)::endl
        posv = T :- startl :+ 2
        keep = s[posv] :& (dyv[posv] :< .) :& (w[posv :- 1] :< .)
        for (j=1; j<=bestlag; j++) keep = keep :& (dyv[posv :- j] :< .)
        T = select(T, keep)
        posv = T :- startl :+ 2
        n0 = rows(T)
        yv = dyv[posv]
        y1 = w[posv :- 1]
        C = (J(n0, 1, 1), T)
        Lg = J(n0, 0, .)
        for (j=1; j<=bestlag; j++) Lg = (Lg, dyv[posv :- j])
        K = 1 + nbreaks * (1 + (brk == 3)) + 2 + bestlag
        if (n0 <= K) {
            st_numscalar("__lp_rc", 1)
            return
        }

        mint = .
        first = 1
        bestb = J(K, 1, .)
        bestt = J(K, 1, .)
        bestbps = J(nbreaks, 1, .)
        done = 0
        while (!done) {
            // dummies grouped by break point: D then DT for each break
            B = lumpapell_dummies(T, bps, brk, nbreaks)
            X = (y1, B, C, Lg)
            R = lumpapell_ols(X, yv)
            tst = R[1, 2]
            // keep the first value, afterwards strict minimum (RATS line 230)
            if (first | tst < mint) {
                mint = tst
                bestb = R[1..K, 1]
                bestt = R[1..K, 2]
                bestbps = bps
                first = 0
            }
            // odometer (RATS lines 235-245)
            done = 1
            for (i=nbreaks; i>=1; i--) {
                bps[i] = bps[i] + 1
                if (bps[i] >= ub[i]) continue
                for (j=i+1; j<=nbreaks; j++) bps[j] = bps[j-1] + pinobs
                done = 0
                break
            }
        }
        bestN = n0
        bestK = K
        bestk = bestlag
    }
    else {
        // -------------------------------------------------------------
        // Article grid: candidates from the second observation of the
        // series to the next-to-last observation, break dates at least
        // two periods apart, model CA unordered; the lag is selected
        // for each break combination
        // -------------------------------------------------------------
        lowc = startl
        upc = endl - 1
        gap = 2
        kmax = (lmethod == 1 ? bestlag : maxlag)
        kmin = (lmethod == 1 ? bestlag : 0)
        if (nbreaks > 0 & lowc + gap * (nbreaks - 1) > upc) {
            st_numscalar("__lp_rc", 3)
            return
        }

        mint = .
        first = 1
        bestb = J(0, 1, .)
        bestt = J(0, 1, .)
        bestbps = J(max((nbreaks,1)), 1, .)
        bestk = .
        bestN = .
        bestK = .
        if (nbreaks == 0) {
            H = lumpapell_eval(J(0,1,.), brk, 0, lmethod, kmin, kmax, signif, tcrit, dyv, w, s, startl, endl)
            mint = H[1,1]
            if (rows(H) > 2) {
                bestk = H[1,2]
                bestN = H[2,1]
                bestK = H[2,2]
                bestb = H[3..rows(H), 1]
                bestt = H[3..rows(H), 2]
            }
        }
        else if (brk == 4) {
            for (tb1=lowc; tb1<=upc; tb1++) {
                for (tb2=lowc; tb2<=upc; tb2++) {
                    if (abs(tb1 - tb2) < gap) continue
                    tbv = (tb1 \ tb2)
                    H = lumpapell_eval(tbv, brk, nbreaks, lmethod, kmin, kmax, signif, tcrit, dyv, w, s, startl, endl)
                    tst = H[1,1]
                    if ((first & tst < .) | tst < mint) {
                        mint = tst
                        bestk = H[1,2]
                        bestN = H[2,1]
                        bestK = H[2,2]
                        bestb = H[3..rows(H), 1]
                        bestt = H[3..rows(H), 2]
                        bestbps = tbv
                        first = 0
                    }
                }
            }
        }
        else {
            bps = J(nbreaks, 1, 0)
            ub = J(nbreaks, 1, 0)
            for (i=1; i<=nbreaks; i++) {
                bps[i] = lowc + gap * (i - 1)
                ub[i] = upc - gap * (nbreaks - i)
            }
            done = 0
            while (!done) {
                H = lumpapell_eval(bps, brk, nbreaks, lmethod, kmin, kmax, signif, tcrit, dyv, w, s, startl, endl)
                tst = H[1,1]
                if ((first & tst < .) | tst < mint) {
                    mint = tst
                    bestk = H[1,2]
                    bestN = H[2,1]
                    bestK = H[2,2]
                    bestb = H[3..rows(H), 1]
                    bestt = H[3..rows(H), 2]
                    bestbps = bps
                    first = 0
                }
                done = 1
                for (i=nbreaks; i>=1; i--) {
                    bps[i] = bps[i] + 1
                    if (bps[i] > ub[i]) continue
                    for (j=i+1; j<=nbreaks; j++) bps[j] = bps[j-1] + gap
                    done = 0
                    break
                }
            }
        }
        if (mint >= .) {
            st_numscalar("__lp_rc", 1)
            return
        }
        bestlag = bestk
    }

    st_numscalar("__lp_rc", 0)
    st_numscalar("__lp_mint", mint)
    st_numscalar("__lp_bestlag", bestlag)
    st_numscalar("__lp_maxlag", maxlag)
    st_numscalar("__lp_pinobs", pinobs)
    st_numscalar("__lp_N", bestN)
    st_numscalar("__lp_K", bestK)
    st_matrix("__lp_b", bestb')
    st_matrix("__lp_t", bestt')
    if (nbreaks > 0) st_matrix("__lp_bps", bestbps')
}

end
