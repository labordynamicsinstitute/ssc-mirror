*! _gvar_stability 1.0.1  21aug2026
*! gvar stability -- structural stability battery for every country-model
*! equation.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   PKsup, PKmsq  Ploberger & Kramer (1992) maximal OLS-CUSUM and its
*                 mean-square variant          <- Toolbox kraplob.m
*   Nyblom        Nyblom (1989) LM against a
*                 non-stationary alternative,
*                 plus its robust version      <- Toolbox nyblom.m
*   QLR           Quandt likelihood ratio, sup-F
*   MW            mean-F
*   APW           Andrews & Ploberger exp-F
*                 and heteroskedasticity-robust
*                 versions of all three        <- Toolbox schow.m
*   break date    argmax of the sequential Chow <- Toolbox schow.m (maxobs)
*
* The Toolbox obtains critical values by bootstrapping the solved GVAR
* (bootstrap_GVAR_ss.m); that requires gvar irf, reps() and is offered there.

program define _gvar_stability, rclass
    version 14.0

    syntax [,                                   ///
        CCUT(real 0.15)                         ///
        TESTs(string)                           ///
        REPS(integer 0)                         ///
        SHUFFLE                                 ///
        SHRINKDraw                              ///
        LAMDraw(real -1)                        ///
        VCOV(string)                            ///
        SHRINK                                  ///
        LAMbda(real -1)                         ///
        DETail                                  ///
        noSUMmary                               ///
        SAVing(name)                            ///
        SAVECV(name)                            ///
        GRAPH                                   ///
        EQuations(string)                       ///
        TOP(integer 6)                          ///
        NAME(string)                            ///
        EFP(string)                             ///
        HFRAC(real 0.15)                        ///
        ALL                                     ///
    ]

    _gvar_require estimate

    * ---- the empirical fluctuation processes, a separate battery ------------
    if ("`efp'" != "" | "`all'" != "") {
        if (`hfrac' <= 0 | `hfrac' >= 1) {
            di as err "hfrac() must lie strictly between 0 and 1"
            exit 198
        }
        _gvar_shrinkopt 0 0 "`vcov'" "`shrink'" "`lambda'"
        local shf 0
        if ("`shuffle'" != "") local shf 1
        local dgs 0
        local dgl .
        if ("`shrinkdraw'" != "") local dgs 1
        if ("`lamdraw'" != "" & "`lamdraw'" != "-1") {
            local dgs 1
            local dgl `lamdraw'
        }
        _gvar_stab_efp "`efp'" `hfrac' `reps' `shf' `r(vmeth)' `r(vexcl)' ///
                       `r(shr)' "`r(lam)'" `dgs' "`dgl'" "`summary'" ///
                       "`graph'" "`equations'" `top' "`name'" "`all'"
        return add
        exit
    }

    if (`ccut' <= 0 | `ccut' >= 0.5) {
        di as err "ccut() must lie strictly between 0 and 0.5"
        exit 198
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    mata: st_local("tv", strofreal(gvar_getT() - gvar_getpmax()))

    tempname R CV
    mata: st_matrix("`R'", gvar_stabtests(`ccut'))
    local nr = rowsof(`R')

    * ---- bootstrap critical values (bootstrap_GVAR_ss.m) -------------------
    * The Toolbox obtains 90, 95 and 99 per cent critical values by
    * regenerating the GVAR, re-estimating every country model and
    * recomputing the whole battery on each replication.
    _gvar_shrinkopt 0 0 "`vcov'" "`shrink'" "`lambda'"
    local vmeth "`r(vmeth)'"
    local vexcl "`r(vexcl)'"
    local shr   "`r(shr)'"
    local lam   "`r(lam)'"

    local shf 0
    if ("`shuffle'" != "") local shf 1
    local dgs 0
    local dgl .
    if ("`shrinkdraw'" != "") local dgs 1
    if ("`lamdraw'" != "" & "`lamdraw'" != "-1") {
        if (`lamdraw' < 0 | `lamdraw' > 1) {
            di as err "lamdraw() must lie between 0 and 1"
            exit 198
        }
        local dgs 1
        local dgl `lamdraw'
    }
    local havecv 0
    if (`reps' > 0) {
        if (`shf' == 0) {
            mata: st_local("dgok", strofreal(gvar_dgpd(`vmeth', `vexcl', ///
                                                       `dgs', `dgl')))
            if ("`dgok'" != "1") {
                mata: st_local("KK", strofreal(gvar_getK()))
                mata: st_local("rk", strofreal(gvar_szetarank()))
                di as err "the bootstrap cannot draw from this covariance:" ///
                          " it is not positive definite"
                di as text "  Sigma_zeta is `KK' by `KK' with rank `rk'."
                di as text "  Add {bf:shuffle}, or {bf:shrinkdraw}."
                exit 506
            }
        }
        * A 95th percentile from B draws is the 0.95*B-th order statistic.
        * These statistics are strongly right-skewed, so with a small B the
        * upper tail is undersampled and the critical value comes out too
        * LOW -- which shows up as over-rejection, not under-rejection.
        if (`reps' < 200) {
            di as text "  {bf:note}: " as result `reps' as text ///
                       " replications is few for a 95th percentile."
            di as text "  The sup-type statistics are right-skewed, so a" ///
                       " small number of"
            di as text "  draws under-samples the upper tail and biases the" ///
                       " critical value"
            di as text "  DOWN, inflating the rejection rate.  Use" ///
                       " {bf:reps(200)} or more"
            di as text "  before reading the rejection counts as evidence."
        }
        di as text "  bootstrapping " as result `reps' as text ///
                   " replications for the critical values ..."
        mata: gvar_bootwrap(`reps', `shf', 4, J(0,1,0), `ccut', 0, 0, ///
                            `vmeth', `vexcl', `shr', `lam', 0, ///
                            0.90, 0.95, 0.99, `dgs', `dgl')
        local bnok   = r_nok
        local bndisc = r_ndisc
        if (`bnok' == 0) {
            di as err "every bootstrap replication failed or was unstable"
            exit 498
        }
        matrix `CV' = r_boot
        local havecv 1
    }

    if ("`tests'" == "") local tests "pk ny qlr"
    local tests = lower("`tests'")

    * counters for rejections against the bootstrap critical values; declared
    * here so -return- and the footer always have something to read, whether
    * or not the table is printed
    local nrej 0
    local ntst 0

    if ("`summary'" != "nosummary") {
        _gvar_title "Structural stability tests of the VECMX* equations"
        di as text "  Sequential Chow trimming: " as result %4.2f `ccut' ///
                   as text " at each end of " as result `tv' as text " observations."
        di ""
        di as text "{hline 100}"
        di as text %-11s "  Unit" %-8s "eq" _col(23) "PKsup" _col(33) "PKmsq" ///
                   _col(43) "Nyblom" _col(54) "robNy" _col(65) "QLR" ///
                   _col(75) "MW" _col(85) "APW" _col(94) "break"
        di as text "{hline 100}"

        forvalues q = 1/`nr' {
            local i = `R'[`q', 1]
            local j = `R'[`q', 2]
            local u : word `i' of `cn'
            mata: st_local("eqn", gvar_getyname(`i', `j'))
            if (`j' == 1) di as text "  " %-9s abbrev("`u'", 9) _continue
            else          di as text "  " %-9s "" _continue
            di as text %-8s abbrev("`eqn'", 8) _continue
            forvalues cc = 3/9 {
                local st " "
                if (`havecv') {
                    local cvv = `CV'[`=`nr'+`q'', `=`cc'-2']
                    if (`R'[`q',`cc'] > `cvv' & `cvv' < .) {
                        local st "*"
                        local ++nrej
                    }
                    local ++ntst
                }
                local cpos = 9 + 10 * (`cc' - 2)
                local val = `R'[`q', `cc']
                di _col(`cpos') as result %8.3f `val' ///
                   as text "`st'" _continue
            }
            di _col(90) as result %6.0f `=`R'[`q',13]'
        }
        di as text "{hline 100}"
        di as text "  PKsup / PKmsq  Ploberger-Kramer OLS-CUSUM and mean-square"
        di as text "  Nyblom / robNy Nyblom LM and its heteroskedasticity-robust form"
        di as text "  QLR / MW / APW Quandt sup-F, mean-F, Andrews-Ploberger exp-F"
        di as text "  break          observation at which the sup-F is attained"
        di ""
        di as text "  These statistics have non-standard distributions, so"
        di as text "  they cannot be read against a chi-squared or F table."
        if (`havecv') {
            di as text "  * marks rejection at 5% against the BOOTSTRAP critical"
            di as text "  value, from " as result `bnok' as text ///
                       " replications" _continue
            if (`bndisc' > 0) {
                di as text " (" as result `bndisc' as text " discarded)."
            }
            else {
                di as text "."
            }
            di as text "  Rejections: " as result `nrej' as text " of " ///
               as result `ntst' as text " (" as result %4.1f ///
               `=100*`nrej'/max(`ntst',1)' as text "%).  Under the null a"
            di as text "  correctly sized battery rejects about 5%."
            di as text "  Use {bf:gvar stability, reps(#) savecv(name)} to keep"
            di as text "  the 90, 95 and 99 per cent values."
        }
        else {
            di as text "  No critical values were computed.  Add" ///
                       " {bf:reps(#) shuffle} to"
            di as text "  bootstrap them as the Toolbox does" ///
                       " (bootstrap_GVAR_ss.m), or read"
            di as text "  them off Table A1 of Dees, di Mauro, Pesaran &" ///
                       " Smith (2007)."
        }
        di ""
    }

    if ("`detail'" != "") {
        di as text "  Robust sequential Chow statistics"
        di as text "{hline 60}"
        di as text %-11s "  Unit" %-8s "eq" _col(24) "robQLR" _col(38) "robMW" ///
                   _col(50) "robAPW"
        di as text "{hline 60}"
        forvalues q = 1/`nr' {
            local i = `R'[`q', 1]
            local j = `R'[`q', 2]
            local u : word `i' of `cn'
            mata: st_local("eqn", gvar_getyname(`i', `j'))
            di as text "  " %-9s abbrev("`u'", 9) %-8s abbrev("`eqn'", 8) ///
               _col(20) as result %11.2f `=`R'[`q',10]' ///
               _col(33) as result %11.2f `=`R'[`q',11]' ///
               _col(46) as result %11.2f `=`R'[`q',12]'
        }
        di as text "{hline 60}"
    }

    * ---- recursive paths ----------------------------------------------------
    * The table above reports maxima and means.  This draws what they are the
    * maximum or the mean OF, which is the only way to see WHERE a rejection
    * comes from and whether it is one date or a drift over the whole sample.
    if ("`graph'" != "") {
        local sel ""
        if ("`equations'" != "") {
            _gvar_xsel "`equations'"
            local xpos "`r(pos)'"
            local xlab "`r(labels)'"
            mata: st_local("xu", invtokens(strofreal(gvar_getxunit())'))
            mata: st_local("xe", invtokens(strofreal(gvar_getxeq())'))
            local w 0
            foreach p of local xpos {
                local ++w
                local uu : word `p' of `xu'
                local ee : word `p' of `xe'
                local ll : word `w' of `xlab'
                local sel "`sel' `uu'|`ee'|`ll'"
            }
        }
        else {
            * no equation named: show the ones the battery likes least, ranked
            * by PKsup relative to its bootstrap critical value where we have
            * one and by PKsup itself where we do not
            tempname RK
            matrix `RK' = J(`nr', 2, .)
            forvalues q = 1/`nr' {
                local sc = `R'[`q', 3]
                if (`havecv') {
                    local cvv = `CV'[`=`nr'+`q'', 1]
                    if (`cvv' < . & `cvv' > 0) local sc = `R'[`q',3] / `cvv'
                }
                matrix `RK'[`q', 1] = `q'
                matrix `RK'[`q', 2] = `sc'
            }
            mata: st_matrix("`RK'", sort(st_matrix("`RK'"), -2))
            local nshow = min(`top', `nr')
            forvalues w = 1/`nshow' {
                local q  = `RK'[`w', 1]
                local uu = `R'[`q', 1]
                local ee = `R'[`q', 2]
                local u : word `uu' of `cn'
                mata: st_local("eqn", gvar_getyname(`uu', `ee'))
                local sel "`sel' `uu'|`ee'|`u':`eqn'"
            }
        }

        local pkcv .
        local qlcv .
        if (`havecv') {
            * the battery's critical values are common to every equation: the
            * bootstrap distribution is taken over replications, so row nr+q
            * of CV is equation q's.  For the reference line we use the median
            * across equations, and say so in the note.
            tempname CVM
            matrix `CVM' = `CV'
            local spk 0
            local sql 0
            local ncv 0
            forvalues q = 1/`nr' {
                * CV columns follow gvar_ssrow: 1 PKsup .. 5 QLR
                local a = `CVM'[`=`nr'+`q'', 1]
                local b = `CVM'[`=`nr'+`q'', 5]
                if (`a' < . & `b' < .) {
                    local spk = `spk' + `a'
                    local sql = `sql' + `b'
                    local ++ncv
                }
            }
            if (`ncv' > 0) {
                local pkcv = `spk' / `ncv'
                local qlcv = `sql' / `ncv'
            }
        }

        _gvar_stab_graph "`sel'" `ccut' `pkcv' `qlcv' "`name'" `havecv'
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    if ("`savecv'" != "" & `havecv') {
        matrix `savecv' = `CV'
    }
    if (`havecv') {
        return matrix cv = `CV', copy
        return scalar reps = `bnok'
        return scalar discarded = `bndisc'
    }
    return matrix stability = `R', copy
    return scalar ccut = `ccut'
    return scalar nrej = `nrej'
    return scalar ntest = `ntst'
end

* ---------------------------------------------------------------------------
* Two small-multiple panels in the light palette:
*   left   the Ploberger-Kramer OLS-CUSUM path, with the +/- critical band
*   right  the sequential Chow F path, with the critical line and the break
*
* The CUSUM path is what PKsup maximises; the Chow path is what QLR maximises.
* Reading them beside the table is the difference between knowing that an
* equation is unstable and knowing when it became unstable.
* ---------------------------------------------------------------------------
program define _gvar_stab_graph
    version 14.0
    args sel ccut pkcv qlcv name havecv

    * every colour must be copied out of r() BEFORE the loop: -summarize- and
    * -svmat- inside it overwrite r(), and a glcolor() read late comes back
    * empty
    _gvar_palette
    local c1     "`r(c1)'"
    local c2     "`r(c2)'"
    local band   "`r(band)'"
    local zero   "`r(zero)'"
    local grid   "`r(grid)'"
    local region "`r(region)'"
    local bando  "`r(band_o)'"

    * -graph combine- takes region_options but NOT bgcolor(), which the shared
    * palette region does include, so it needs its own shorter form
    local creg "graphregion(color(white)) plotregion(color(white) lcolor(none))"

    preserve
    quietly {
        local plots ""
        local w 0
        foreach s of local sel {
            local ++w
            local u   = substr("`s'", 1, strpos("`s'", "|") - 1)
            local rst = substr("`s'", strpos("`s'", "|") + 1, .)
            local e   = substr("`rst'", 1, strpos("`rst'", "|") - 1)
            local lab = substr("`rst'", strpos("`rst'", "|") + 1, .)

            clear
            tempname P
            mata: st_matrix("`P'", gvar_stabpath(`u', `e', `ccut'))
            if (rowsof(`P') < 2) continue
            svmat double `P', names(col)
            rename c1 t
            rename c2 cusum
            rename c3 chow
            rename c4 rchow

            * the break date is the argmax of the non-robust Chow path.  The
            * path is missing outside the trimmed interior, so guard on r(N)
            * rather than assuming r(max) exists.
            local bobs = .
            summarize chow, meanonly
            if (r(N) > 0) {
                local cmax = r(max)
                summarize t if abs(chow - `cmax') < 1e-12, meanonly
                if (r(N) > 0) local bobs = r(min)
            }

            * every colour here is an "R G B" triple, so it MUST be quoted:
            * unquoted, Stata reads the first number as a named colour style
            local xt ""
            if (`bobs' < .) {
                local xt `"xline(`bobs', lcolor("`c2'") lpattern(dash) lwidth(medthin))"'
            }

            * ---- CUSUM panel ----
            local cb ""
            if (`pkcv' < .) {
                gen double _hi =  `pkcv'
                gen double _lo = -`pkcv'
                local cb `"(rarea _hi _lo t, color("`band'%`bando'") lwidth(none))"'
            }
            * plain names, not tempnames: -graph combine- needs them to still
            * exist after this program's tempnames would be released, and we
            * drop them ourselves once combined
            local g1 "_gvst_c`w'"
            twoway `cb'                                                     ///
                   (line cusum t, lcolor("`c1'") lwidth(medthick))          ///
                   , yline(0, lcolor("`zero'") lwidth(thin))                ///
                     `xt'                                                   ///
                     legend(off) `region'                                   ///
                     title("`lab'", size(small) color(black))               ///
                     subtitle("OLS-CUSUM", size(vsmall) color(black))       ///
                     xtitle("") ytitle("")                                  ///
                     ylabel(, labsize(vsmall) angle(0) grid glcolor("`grid'")) ///
                     xlabel(, labsize(vsmall))                              ///
                     name(`g1', replace) nodraw
            local plots "`plots' `g1'"
            capture drop _hi _lo

            * ---- sequential Chow panel ----
            local ql ""
            if (`qlcv' < .) {
                local ql `"yline(`qlcv', lcolor("`c2'") lpattern(shortdash) lwidth(medthin))"'
            }
            local g2 "_gvst_f`w'"
            twoway (line chow t, lcolor("`c1'") lwidth(medthick))           ///
                   , `ql' `xt'                                              ///
                     legend(off) `region'                                   ///
                     title(" ", size(small))                                ///
                     subtitle("sequential Chow F", size(vsmall) color(black)) ///
                     xtitle("") ytitle("")                                  ///
                     ylabel(, labsize(vsmall) angle(0) grid glcolor("`grid'")) ///
                     xlabel(, labsize(vsmall))                              ///
                     name(`g2', replace) nodraw
            local plots "`plots' `g2'"
        }
    }
    restore

    local np : word count `plots'
    if (`np' == 0) {
        di as err "no equation produced a usable path"
        exit 498
    }

    local nm "gvar_stability"
    if ("`name'" != "") local nm "`name'"

    * a multi-line note() is a sequence of quoted strings, so the local has to
    * be built with compound quotes or only the first line survives
    local nt `""horizontal axis: observation number within the estimation sample""'
    if (`havecv' == 1) {
        local nt `"`nt' "band and dashed line: bootstrap 5% critical values, averaged over equations""'
        local nt `"`nt' "vertical dash: the break date, the argmax of the sequential Chow F""'
    }
    else {
        local nt `"`nt' "no critical values were computed: add reps(#) shuffle""'
    }

    graph combine `plots', cols(2) `creg'                                   ///
        title("Structural stability of the VECMX* equations",               ///
              size(medsmall) color(black))                                  ///
        note(`nt', size(vsmall) color(black))                               ///
        name(`nm', replace)

    foreach g of local plots {
        capture graph drop `g'
    }

    di as text "  graph saved as {bf:`nm'}"
end

* ---------------------------------------------------------------------------
* The strucchange family of empirical fluctuation processes.
*
* Step -> source map
*   every process, the sdev() scaling, root.matrix() and the drop/rescale of
*   the max functional                       <- strucchange R/efp.R
*   recursive residuals                      <- strucchange R/recresid.R
*   closed-form p-values for Brownian motion
*   and Brownian bridge                      <- strucchange R/efp.R pvalue.efp
*   the two increments tables                <- Chu, Hornik & Kuan (1995)
*                                               Table 1, written inline in
*                                               efp.R, and sc.me from
*                                               R/critvals.R
*
* GVARX's .gvar.stability and vars' stability.varest both call efp() and
* nothing else, so this is the whole of what they offer, applied to each
* VECMX* equation instead of to each VAR equation.
*
* Bootstrap critical values are optional here, unlike for the Toolbox battery:
* efp carries exact asymptotic p-values.  They are still worth having, because
* the asymptotics assume a single equation estimated on independent data and a
* GVAR equation is neither.
* ---------------------------------------------------------------------------
program define _gvar_stab_efp, rclass
    version 14.0
    args efp hfrac reps shf vmeth vexcl shr lam dgs dgl summary graph ///
         equations top name all

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))

    * ---- which processes ---------------------------------------------------
    local known "rec-cusum ols-cusum rec-mosum ols-mosum re me score-cusum score-mosum"
    local want ""
    if ("`all'" != "") {
        local want "1 2 3 4 5 6 7 8"
    }
    else {
        foreach t of local efp {
            local t = lower("`t'")
            * accept the strucchange spellings and a few obvious short forms
            if ("`t'" == "reccusum")  local t "rec-cusum"
            if ("`t'" == "olscusum")  local t "ols-cusum"
            if ("`t'" == "recmosum")  local t "rec-mosum"
            if ("`t'" == "olsmosum")  local t "ols-mosum"
            if ("`t'" == "scorecusum") local t "score-cusum"
            if ("`t'" == "scoremosum") local t "score-mosum"
            if ("`t'" == "cusum")     local t "ols-cusum"
            if ("`t'" == "mosum")     local t "ols-mosum"
            if ("`t'" == "fluctuation") local t "re"
            local w : list posof "`t'" in known
            if (`w' == 0) {
                di as err "efp(): {bf:`t'} is not one of the processes"
                di as err "Choose from, in strucchange's own names:"
                di as err "    {bf:Rec-CUSUM  OLS-CUSUM  Rec-MOSUM  OLS-MOSUM}"
                di as err "    {bf:RE  ME  Score-CUSUM  Score-MOSUM}"
                di as err "{bf:fluctuation} is accepted as a synonym for RE," ///
                          " as in efp()."
                exit 198
            }
            local already : list posof "`w'" in want
            if (`already' == 0) local want "`want' `w'"
        }
    }
    local nw : word count `want'

    local lname1 "Rec-CUSUM"
    local lname2 "OLS-CUSUM"
    local lname3 "Rec-MOSUM"
    local lname4 "OLS-MOSUM"
    local lname5 "RE"
    local lname6 "ME"
    local lname7 "Score-CUSUM"
    local lname8 "Score-MOSUM"
    local llim1 "Brownian motion"
    local llim2 "Brownian bridge"
    local llim3 "BM increments"
    local llim4 "BB increments"
    local llim5 "Brownian bridge"
    local llim6 "BB increments"
    local llim7 "Brownian bridge"
    local llim8 "BB increments"

    tempname S
    local nrej 0
    local ntst 0

    if ("`summary'" != "nosummary") {
        _gvar_title "Empirical fluctuation processes of the VECMX* equations"
        di as text "  Window fraction h = " as result %4.2f `hfrac' ///
           as text ".  Statistic: the max functional."
        di as text "  Source: {bf:strucchange::efp}, which is what GVARX and" ///
                   " vars call."
        di ""
    }

    foreach w of local want {
        mata: st_matrix("`S'", gvar_efptests(`w', `hfrac'))
        local nr = rowsof(`S')

        * bootstrap critical values for this process, if asked for
        local havecv 0
        if (`reps' > 0) {
            di as text "  bootstrapping " as result `reps' ///
               as text " replications for {bf:`lname`w''} ..."
            mata: gvar_bootwrap(`reps', `shf', 5, J(0,1,0), `hfrac', 0, `w', ///
                                `vmeth', `vexcl', `shr', `lam', 0, ///
                                0.90, 0.95, 0.99, `dgs', `dgl')
            local bnok = r_nok
            if (`bnok' > 0) {
                tempname CV
                matrix `CV' = r_boot
                local havecv 1
            }
        }

        * Count the rejections BEFORE the display block.  Counting inside it
        * means nosummary returns 0 of 0, which has bitten this package four
        * times: any counter that -return- reports has to be accumulated
        * outside every display guard.
        forvalues q = 1/`nr' {
            local pv = `S'[`q', 4]
            if (`pv' < .) {
                local ++ntst
                if (`pv' < 0.05) local ++nrej
            }
        }

        if ("`summary'" != "nosummary") {
            local wid 74
            if (`havecv') local wid 88
            di as text "{hline `wid'}"
            di as text "  {bf:`lname`w''}" _col(30) "limit: `llim`w''"
            di as text "{hline `wid'}"
            di as text %-11s "  Unit" %-9s "eq" _col(24) "statistic" ///
               _col(38) "p-value" _col(50) "comp" _continue
            if (`havecv') {
                di as text _col(60) "5% boot" _col(74) "1% boot"
            }
            else {
                di ""
            }
            di as text "{hline `wid'}"

            forvalues q = 1/`nr' {
                local i = `S'[`q', 1]
                local j = `S'[`q', 2]
                local u : word `i' of `cn'
                mata: st_local("eqn", gvar_getyname(`i', `j'))
                if (`j' == 1) di as text "  " %-9s abbrev("`u'", 9) _continue
                else          di as text "  " %-9s "" _continue
                di as text %-9s abbrev("`eqn'", 9) _continue

                local pv = `S'[`q', 4]
                local st ""
                if (`pv' < .) {
                    _gvar_stars `pv'
                    local st "`r(stars)'"
                }
                di _col(22) as result %10.4f `=`S'[`q',3]' ///
                   _col(35) as result %9.4f `pv' as text "`st'" ///
                   _col(49) as result %5.0f `=`S'[`q',5]' _continue
                if (`havecv') {
                    di _col(57) as result %10.4f `=`CV'[`=`nr'+`q'', 1]' ///
                       _col(71) as result %10.4f `=`CV'[`=2*`nr'+`q'', 1]'
                }
                else {
                    di ""
                }
            }
            di as text "{hline `wid'}"
            di ""
        }
    }

    if ("`summary'" != "nosummary") {
        di as text "  {bf:comp} is the number of components of the process," ///
                   " strucchange's k:"
        di as text "  one for the CUSUM and MOSUM processes, one per" ///
                   " coefficient for RE and"
        di as text "  ME, and one per coefficient plus one for the variance" ///
                   " score in the"
        di as text "  Score processes.  The p-value depends on it, and" ///
                   " pvalue.efp caps it"
        di as text "  at 6 for the Brownian-bridge-increments table -- so" ///
                   " for ME and"
        di as text "  Score-MOSUM on a GVAR equation the p-value is the" ///
                   " k = 6 one and is"
        di as text "  {bf:conservative}, not exact."
        di ""
        if (`ntst' > 0) {
            di as text "  Rejections at 5%: " as result `nrej' as text " of " ///
               as result `ntst' as text " (" as result %4.1f ///
               `=100*`nrej'/`ntst'' as text "%)."
        }
        di as text "  The asymptotics behind these p-values assume one" ///
                   " equation estimated"
        di as text "  on its own data.  A GVAR equation shares its foreign" ///
                   " variables with"
        di as text "  every other, so add {bf:reps(#) shuffle} for critical" ///
                   " values that"
        di as text "  come from the model itself."
        di ""
        di as text "  * 10%  ** 5%  *** 1%"
        di ""
    }

    if ("`graph'" != "") {
        local w1 : word 1 of `want'
        _gvar_efp_graph `w1' `hfrac' "`equations'" `top' "`name'" ///
                        "`lname`w1''"
    }

    return matrix efp = `S', copy
    return scalar nrej  = `nrej'
    return scalar ntest = `ntst'
    return scalar hfrac = `hfrac'
    return local  types "`want'"
end

* ---------------------------------------------------------------------------
* The fluctuation path of one process for a few equations, with its critical
* value drawn as a horizontal line.  For Brownian motion the process has
* already been divided by its (1 + 2t) boundary, so a flat line is right for
* every type.
* ---------------------------------------------------------------------------
program define _gvar_efp_graph
    version 14.0
    args which hfrac equations top name lname

    _gvar_palette
    local c1   "`r(c1)'"
    local c2   "`r(c2)'"
    local grid "`r(grid)'"
    local reg  "`r(region)'"
    local creg "graphregion(color(white)) plotregion(color(white) lcolor(none))"

    local nm "gvar_efp"
    if ("`name'" != "") local nm "`name'"

    mata: st_local("cn", invtokens(gvar_getcname()'))

    * pick the equations
    tempname S
    mata: st_matrix("`S'", gvar_efptests(`which', `hfrac'))
    local nr = rowsof(`S')

    local sel ""
    if ("`equations'" != "") {
        _gvar_xsel "`equations'"
        local xpos "`r(pos)'"
        local xlab "`r(labels)'"
        mata: st_local("xu", invtokens(strofreal(gvar_getxunit())'))
        mata: st_local("xe", invtokens(strofreal(gvar_getxeq())'))
        local w 0
        foreach p of local xpos {
            local ++w
            local uu : word `p' of `xu'
            local ee : word `p' of `xe'
            local ll : word `w' of `xlab'
            local sel "`sel' `uu'|`ee'|`ll'"
        }
    }
    else {
        * the equations with the smallest p-values
        tempname RK
        matrix `RK' = J(`nr', 2, .)
        forvalues q = 1/`nr' {
            matrix `RK'[`q', 1] = `q'
            matrix `RK'[`q', 2] = `S'[`q', 4]
        }
        mata: st_matrix("`RK'", sort(st_matrix("`RK'"), 2))
        local nshow = min(`top', `nr')
        forvalues w = 1/`nshow' {
            local q  = `RK'[`w', 1]
            local uu = `S'[`q', 1]
            local ee = `S'[`q', 2]
            local u : word `uu' of `cn'
            mata: st_local("eqn", gvar_getyname(`uu', `ee'))
            local sel "`sel' `uu'|`ee'|`u':`eqn'"
        }
    }

    preserve
    local plots ""
    local w 0
    quietly {
        foreach s of local sel {
            local ++w
            local u   = substr("`s'", 1, strpos("`s'", "|") - 1)
            local rst = substr("`s'", strpos("`s'", "|") + 1, .)
            local e   = substr("`rst'", 1, strpos("`rst'", "|") - 1)
            local lab = substr("`rst'", strpos("`rst'", "|") + 1, .)

            clear
            tempname P
            mata: st_matrix("`P'", gvar_efppath(`u', `e', `which', `hfrac'))
            if (rowsof(`P') < 2) continue
            svmat double `P', names(col)
            rename c1 t
            rename c2 v

            * the 5% critical value for this equation's component count, found
            * by inverting the p-value function
            local q5 .
            forvalues qq = 1/`nr' {
                if (`S'[`qq',1] == `u' & `S'[`qq',2] == `e') {
                    local nc = `S'[`qq', 5]
                    mata: st_local("q5", strofreal(gvar_efpcrit(`which', ///
                                   `hfrac', `nc', 0.05)))
                }
            }
            local cl ""
            if ("`q5'" != "" & "`q5'" != ".") {
                local cl `"yline(`q5', lcolor("`c2'") lpattern(dash) lwidth(medthin))"'
            }

            local gn "_gvefp`w'"
            twoway (line v t, lcolor("`c1'") lwidth(medthick))              ///
                   , `reg' `cl'                                            ///
                     ylabel(, angle(0) labsize(vsmall) grid                 ///
                            glcolor("`grid'"))                              ///
                     xlabel(, labsize(vsmall))                              ///
                     ytitle("") xtitle("")                                  ///
                     title("`lab'", size(small) color(black))               ///
                     legend(off) name(`gn', replace) nodraw
            local plots "`plots' `gn'"
        }
    }
    restore

    local np : word count `plots'
    if (`np' == 0) {
        di as err "no equation produced a usable process"
        exit 498
    }
    local cols 2
    if (`np' == 1) local cols 1
    if (`np' > 6)  local cols 3

    graph combine `plots', cols(`cols') `creg'                              ///
        title("`lname' fluctuation process", size(medsmall) color(black))   ///
        note("dashed: the 5% critical value"                                 ///
             "the path is the max-norm across components, after the drop"    ///
             " and rescale sctest applies",                                  ///
             size(vsmall) color(black))                                     ///
        name(`nm', replace)

    foreach g of local plots {
        capture graph drop `g'
    }
    di as text "  graph saved as {bf:`nm'}"
end
