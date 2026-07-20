*! regbreak 1.0.0  19jul2026
*! Structural breaks in error variance and coefficients of a linear regression
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*! Implements Bai & Perron (1998) and Perron, Yamamoto & Zhou (joint tests).

program define regbreak, eclass
    version 14.0
    syntax varlist(min=1 numeric ts) [if] [in] , [ ///
        X(varlist numeric ts) MAXB(integer 5) MAXV(integer 2) TRIM(real 0.15) ///
        noConstant JOINT ///
        Prewhite(integer -1) Robust(integer 1) VRobust(integer 1) ///
        HETDAT(integer 1) HETVAR(integer 1) HETOMEGA(integer 1) HETQ(integer 1) ///
        TYPEk(integer 2) IC(string) FIXn(integer -1) SIGnif(integer 2) ///
        GRAPH GNAME(string) Level(cilevel) ]

    marksample touse
    gettoken dep zvars : varlist
    markout `touse' `dep' `zvars' `x'
    qui count if `touse'
    if r(N) < 20 {
        di as error "too few observations ({bf:`r(N)'}); need at least 20"
        exit 2001
    }

    * constant / number of z regressors subject to change
    local addcons = cond("`constant'"=="noconstant", 0, 1)
    local nz : word count `zvars'
    local q = `nz' + `addcons'
    if `q'==0 {
        di as error "no regressors with changing coefficients; drop {bf:noconstant} or add {it:indepvars}"
        exit 198
    }
    if `q' > 10 {
        di as error "at most 10 regressors with changing coefficients are supported"
        exit 198
    }

    * trimming must match a tabulated critical-value set
    local okeps 0.05 0.10 0.15 0.20 0.25
    local trimok 0
    foreach e of local okeps {
        if reldif(`trim',`e') < 1e-6 local trimok 1
    }
    if !`trimok' {
        di as error "trim() must be one of 0.05, 0.10, 0.15, 0.20, 0.25"
        exit 198
    }

    * mode-specific prewhitening default
    if `prewhite'==-1 {
        local prewhite = cond("`joint'"=="joint", 0, 1)
    }
    if !inrange(`signif',1,4) local signif 2

    * IC selection code (1=BIC,2=LWZ,3=KT), default KT
    local icsel 3
    if "`ic'"!="" {
        local IC = upper("`ic'")
        if "`IC'"=="BIC" local icsel 1
        else if "`IC'"=="LWZ" local icsel 2
        else if "`IC'"=="KT"  local icsel 3
        else {
            di as error "ic() must be BIC, LWZ or KT"
            exit 198
        }
    }

    capture drop _rb_fit
    if `addcons'==1 local znames _cons `zvars'
    else            local znames `zvars'

    if "`joint'"=="joint" {
        regbreak_joint, dep(`dep') z(`zvars') x(`x') touse(`touse') addcons(`addcons') ///
            maxb(`maxb') maxv(`maxv') trim(`trim') robust(`robust') vrobust(`vrobust') ///
            prewhite(`prewhite') typek(`typek') signif(`signif') q(`q')
    }
    else {
        regbreak_bp, dep(`dep') z(`zvars') x(`x') touse(`touse') addcons(`addcons') ///
            maxb(`maxb') trim(`trim') prewhite(`prewhite') robust(`robust') ///
            hetdat(`hetdat') hetvar(`hetvar') hetomega(`hetomega') hetq(`hetq') ///
            fixn(`fixn') icsel(`icsel') signif(`signif') q(`q') level(`level') ///
            znames(`znames') `graph' gname(`gname')
    }
end

*-----------------------------------------------------------------------------
* Bai & Perron mode
*-----------------------------------------------------------------------------
program define regbreak_bp, eclass
    version 14.0
    syntax , dep(string) touse(string) addcons(integer) maxb(integer) trim(real) ///
        prewhite(integer) robust(integer) hetdat(integer) hetvar(integer) ///
        hetomega(integer) hetq(integer) fixn(integer) icsel(integer) signif(integer) ///
        q(integer) level(integer) [ z(string) x(string) ZNames(string) GRAPH GNAME(string) ]

    mata: rb_bp("`dep'", "`z'", "`x'", "`touse'", `addcons', `maxb', `trim', ///
        `prewhite', `robust', `hetdat', `hetvar', `hetomega', `hetq', `fixn', `icsel')

    tempname supF supFcv udcv seqF seqFcv ic
    matrix `supF'   = r_supF
    matrix `supFcv' = r_supFcv
    matrix `udcv'   = r_udcv
    matrix `seqF'   = r_seqF
    matrix `seqFcv' = r_seqFcv
    matrix `ic'     = r_ic
    local ud   = r_udmax
    local nbrk = r_nbreak
    local bigt = r_bigt

    local icname : word `icsel' of BIC LWZ KT
    local siglab : word `signif' of "10%" "5%" "2.5%" "1%"

    di as text _n "{hline 78}"
    di as text "Structural break analysis (Bai & Perron, 1998)"
    di as text "Dep. var.: " as result "`dep'" as text ///
       "   T = " as result "`bigt'" as text "   trimming = " as result %4.2f `trim' ///
       as text "   max breaks = " as result "`maxb'"
    di as text "{hline 78}"

    * ---- Table 1: supF(0 vs m) and UDmax ----
    di as text _n "(a) Sup F tests of no break vs. a fixed number of breaks"
    di as text "{hline 78}"
    di as text %10s "Breaks" _col(16) %12s "Sup F" %10s "10% cv" %10s "5% cv" %10s "2.5% cv" %10s "1% cv"
    di as text "{hline 78}"
    forvalues i = 1/`maxb' {
        local st = `supF'[`i',1]
        local c1 = `supFcv'[1,`i']
        local c2 = `supFcv'[2,`i']
        local c3 = `supFcv'[3,`i']
        local c4 = `supFcv'[4,`i']
        local star = ""
        if `st' > `c4' & `c4'<. local star "***"
        else if `st' > `c2' & `c2'<. local star "**"
        else if `st' > `c1' & `c1'<. local star "*"
        di as text %10.0g `i' _col(16) as result %12.3f `st' as text "`star'" _continue
        _regbreak_cvcells `c1' `c2' `c3' `c4'
    }
    di as text "{hline 78}"
    local uc1 = `udcv'[1,1]
    local uc2 = `udcv'[2,1]
    local uc3 = `udcv'[3,1]
    local uc4 = `udcv'[4,1]
    local ustar = ""
    if `ud' > `uc4' & `uc4'<. local ustar "***"
    else if `ud' > `uc2' & `uc2'<. local ustar "**"
    else if `ud' > `uc1' & `uc1'<. local ustar "*"
    di as text %10s "UDmax" _col(16) as result %12.3f `ud' as text "`ustar'" _continue
    _regbreak_cvcells `uc1' `uc2' `uc3' `uc4'
    di as text "{hline 78}"
    di as text "* / ** / *** : significant at 10 / 5 / 1 percent."

    * ---- Table 2: sequential supF(l+1|l) ----
    di as text _n "(b) Sequential Sup F(l+1|l) tests"
    di as text "{hline 78}"
    di as text %10s "Test" _col(16) %12s "Sup F" %10s "10% cv" %10s "5% cv" %10s "2.5% cv" %10s "1% cv"
    di as text "{hline 78}"
    forvalues i = 1/`maxb' {
        local im1 = `i' - 1
        local st = `seqF'[`i',1]
        local c1 = `seqFcv'[1,`i']
        local c2 = `seqFcv'[2,`i']
        local c3 = `seqFcv'[3,`i']
        local c4 = `seqFcv'[4,`i']
        local star = ""
        if `st' > `c4' & `c4'<. local star "***"
        else if `st' > `c2' & `c2'<. local star "**"
        else if `st' > `c1' & `c1'<. local star "*"
        di as text %10s "F(`i'|`im1')" _col(16) as result %12.3f `st' as text "`star'" _continue
        _regbreak_cvcells `c1' `c2' `c3' `c4'
    }
    di as text "{hline 78}"

    * ---- Table 3: information criteria ----
    di as text _n "(c) Number of breaks selected by information criteria"
    di as text "{hline 40}"
    di as text %14s "BIC" %14s "LWZ" %12s "KT"
    di as result %14.0g `ic'[1,1] %14.0g `ic'[2,1] %12.0g `ic'[3,1]
    di as text "{hline 40}"

    * ---- Table 4: estimated model ----
    if `nbrk' >= 1 {
        tempname date CI beta se
        matrix `date' = r_date
        matrix `CI'   = r_ci
        matrix `beta' = r_beta
        matrix `se'   = r_se
        local ssr = r_ssr
        if `fixn'>=0 local how "pre-specified (`nbrk')"
        else         local how "`icname' (`nbrk')"

        di as text _n "(d) Estimated model — `how' break(s)"
        di as text "{hline 78}"
        di as text %8s "Break" %12s "Date" %22s "95% CI" %22s "90% CI"
        di as text "{hline 78}"
        forvalues j = 1/`nbrk' {
            local d  = `date'[`j',1]
            local l95 = `CI'[`j',1]
            local u95 = `CI'[`j',2]
            local l90 = `CI'[`j',3]
            local u90 = `CI'[`j',4]
            di as text %8.0g `j' as result %12.0g `d' ///
               as text "   (" as result `l95' as text ", " as result `u95' as text ")" _col(52) ///
               as text "   (" as result `l90' as text ", " as result `u90' as text ")"
        }
        di as text "{hline 78}"
        di as text "SSR = " as result %10.4f `ssr'

        * regime-specific coefficients
        local nregz = `q'
        di as text _n "Regime-specific coefficients (corrected SE in parentheses)"
        di as text "{hline 78}"
        local hdr %20s "Coefficient"
        forvalues r = 1/`=`nbrk'+1' {
            local hdr `"`hdr' %14s "Regime `r'""'
        }
        di as text `hdr'
        di as text "{hline 78}"
        forvalues c = 1/`nregz' {
            local cname : word `c' of `znames'
            di as text %20s "`cname'" _continue
            forvalues r = 1/`=`nbrk'+1' {
                local idx = (`c'-1)*(`nbrk'+1) + `r'
                local b = `beta'[`idx',1]
                di as result %14.3f `b' _continue
            }
            di ""
            di as text %20s " " _continue
            forvalues r = 1/`=`nbrk'+1' {
                local idx = (`c'-1)*(`nbrk'+1) + `r'
                local s = `se'[`idx',1]
                di as text %14s "(`:di %6.3f `s'')" _continue
            }
            di ""
        }
        di as text "{hline 78}"

        * plot
        if "`graph'"=="graph" {
            regbreak_plot, dep(`dep') touse(`touse') nbreak(`nbrk') ///
                date(`date') ci(`CI') gname(`gname')
        }

        ereturn matrix date  = `date'
        ereturn matrix CI    = `CI'
        ereturn matrix beta  = `beta'
        ereturn matrix SE    = `se'
        ereturn scalar SSR   = `ssr'
    }

    ereturn matrix supF   = `supF'
    ereturn matrix supFcv = `supFcv'
    ereturn matrix seqF   = `seqF'
    ereturn matrix seqFcv = `seqFcv'
    ereturn matrix IC     = `ic'
    ereturn scalar UDmax  = `ud'
    ereturn scalar nbreak = `nbrk'
    ereturn scalar T      = `bigt'
    ereturn local  method "Bai-Perron"
    ereturn local  depvar "`dep'"
    ereturn local  cmd    "regbreak"
end

*-----------------------------------------------------------------------------
* Joint (Perron-Yamamoto-Zhou) mode
*-----------------------------------------------------------------------------
program define regbreak_joint, eclass
    version 14.0
    syntax , dep(string) touse(string) addcons(integer) maxb(integer) maxv(integer) ///
        trim(real) robust(integer) vrobust(integer) prewhite(integer) typek(integer) ///
        signif(integer) q(integer) [ z(string) x(string) ]

    mata: rb_joint("`dep'", "`z'", "`x'", "`touse'", `addcons', `maxb', `maxv', `trim', ///
        `robust', `vrobust', `prewhite', `typek', `typek', `signif')

    tempname slr4 cv4 slr3 slr2 cv1c cv1v Tc Tv
    matrix `slr4' = r_slr4
    matrix `cv4'  = r_cv4
    matrix `slr3' = r_slr3
    matrix `slr2' = r_slr2
    matrix `cv1c' = r_cv1coef
    matrix `cv1v' = r_cv1var
    local ud4  = r_ud4
    local mh   = r_mh
    local nh   = r_nh
    local bigt = r_bigt
    local siglab : word `signif' of "10%" "5%" "2.5%" "1%"

    di as text _n "{hline 78}"
    di as text "Joint tests for breaks in variance and coefficients"
    di as text "(Perron, Yamamoto & Zhou)"
    di as text "Dep. var.: " as result "`dep'" as text "   T = " as result "`bigt'" ///
       as text "   max coef breaks = " as result "`maxb'" as text ///
       "   max var breaks = " as result "`maxv'"
    di as text "{hline 78}"

    * supLR4 joint table (rows = coef breaks m, cols = var breaks n), CV at signif
    di as text _n "(a) Sup LR4 — joint test of m coefficient and n variance breaks"
    di as text "     critical values at `siglab' shown in [brackets]"
    di as text "{hline 78}"
    di as text %8s "m \ n" _continue
    forvalues n = 1/`maxv' {
        di as text %14s "n=`n'" _continue
    }
    di ""
    di as text "{hline 78}"
    forvalues m = 1/`maxb' {
        di as text %8s "m=`m'" _continue
        forvalues n = 1/`maxv' {
            local st = `slr4'[`m',`n']
            di as result %14.3f `st' _continue
        }
        di ""
        di as text %8s " " _continue
        forvalues n = 1/`maxv' {
            local cv = `cv4'[`m',`n']
            di as text %14s "[`:di %5.2f `cv'']" _continue
        }
        di ""
    }
    di as text "{hline 78}"
    di as text "UDmax4 = " as result %9.3f `ud4'

    * supLR / supLR3 : coefficient breaks given n variance breaks
    di as text _n "(b) Sup LR (coef breaks | given variance breaks); crit. `siglab'"
    di as text "{hline 78}"
    di as text %8s "m" _col(12) %14s "| 0 var" _continue
    forvalues n = 1/`maxv' {
        di as text %14s "| `n' var" _continue
    }
    di as text %12s "crit(`siglab')"
    di as text "{hline 78}"
    forvalues m = 1/`maxb' {
        di as text %8.0g `m' _col(12) _continue
        forvalues c = 1/`=`maxv'+1' {
            local st = `slr3'[`m',`c']
            di as result %14.3f `st' _continue
        }
        local cv = `cv1c'[`m',1]
        di as text %12s "`:di %6.2f `cv''"
    }
    di as text "{hline 78}"

    * supLR1 / supLR2 : variance breaks given m coefficient breaks
    di as text _n "(c) Sup LR (variance breaks | given coefficient breaks); crit. `siglab'"
    di as text "{hline 78}"
    di as text %8s "n" _col(12) %14s "| 0 coef" _continue
    forvalues m = 1/`maxb' {
        di as text %14s "| `m' coef" _continue
    }
    di as text %12s "crit(`siglab')"
    di as text "{hline 78}"
    forvalues n = 1/`maxv' {
        di as text %8.0g `n' _col(12) _continue
        forvalues c = 1/`=`maxb'+1' {
            local st = `slr2'[`n',`c']
            di as result %14.3f `st' _continue
        }
        local cv = `cv1v'[`n',1]
        di as text %12s "`:di %6.2f `cv''"
    }
    di as text "{hline 78}"

    * sequential selection + estimated dates
    di as text _n "(d) Sequential selection at `siglab' significance"
    di as text "{hline 78}"
    di as text "Number of coefficient breaks (given 0 variance breaks): " as result "`mh'"
    di as text "Number of variance breaks (given 0 coefficient breaks): " as result "`nh'"
    matrix `Tc' = r_Tc
    matrix `Tv' = r_Tv
    if `mh' > 0 {
        di as text "Estimated coefficient break date(s):" _continue
        forvalues j = 1/`mh' {
            di as result "  " `Tc'[`j',1] _continue
        }
        di ""
    }
    if `nh' > 0 {
        di as text "Estimated variance break date(s):   " _continue
        forvalues j = 1/`nh' {
            di as result "  " `Tv'[`j',1] _continue
        }
        di ""
    }
    di as text "{hline 78}"

    ereturn matrix supLR4 = `slr4'
    ereturn matrix cvLR4  = `cv4'
    ereturn matrix supLR3 = `slr3'
    ereturn matrix supLR2 = `slr2'
    ereturn scalar UDmax4 = `ud4'
    ereturn scalar mcoef  = `mh'
    ereturn scalar nvar   = `nh'
    ereturn scalar T      = `bigt'
    ereturn local  method "Perron-Yamamoto-Zhou joint"
    ereturn local  depvar "`dep'"
    ereturn local  cmd    "regbreak"
end

*-----------------------------------------------------------------------------
* helper: print four critical-value cells (skip if missing)
*-----------------------------------------------------------------------------
program define _regbreak_cvcells
    args c1 c2 c3 c4
    foreach c in `c1' `c2' `c3' `c4' {
        if `c' < . di as text %10.3f `c' _continue
        else       di as text %10s "." _continue
    }
    di ""
end

*-----------------------------------------------------------------------------
* helper: journal-style break plot
*-----------------------------------------------------------------------------
program define regbreak_plot
    version 14.0
    syntax , dep(string) touse(string) nbreak(integer) date(string) ci(string) [ GNAME(string) ]
    if "`gname'"=="" local gname regbreak
    tempvar t
    qui gen `t' = _n if `touse'
    qui summarize `dep' if `touse', meanonly
    local ymin = r(min)
    local rng  = r(max) - r(min)
    local ypos = `ymin' - 0.06*`rng'
    local cap  = 0.018*`rng'
    * break-date vertical lines + horizontal 95% CI bars with end caps
    local xlines ""
    local ciseg ""
    forvalues j = 1/`nbreak' {
        local d   = `date'[`j',1]
        local l95 = `ci'[`j',1]
        local u95 = `ci'[`j',2]
        local xlines `xlines' xline(`d', lpattern(dash) lcolor(gs11))
        local ciseg `ciseg' `ypos' `l95' `ypos' `u95'
        local ciseg `ciseg' `=`ypos'-`cap'' `l95' `=`ypos'+`cap'' `l95'
        local ciseg `ciseg' `=`ypos'-`cap'' `u95' `=`ypos'+`cap'' `u95'
    }
    twoway (line `dep' `t' if `touse', lcolor(navy) lwidth(thin)) ///
           (line _rb_fit `t' if `touse', lcolor(cranberry) lwidth(medthick)) ///
           (pci `ciseg', lcolor(red) lwidth(medthin)), ///
           `xlines' ///
           legend(order(1 "observed" 2 "fitted (regime means)" 3 "95% CI for break date") ///
                  rows(1) size(small) region(lstyle(none))) ///
           graphregion(color(white)) plotregion(style(none)) ///
           title("Structural breaks in `dep'", size(medium)) ///
           ytitle("`dep'") xtitle("observation") name(`gname', replace)
end
