*! _gvar_diag 1.0.1  21aug2026
*! gvar diag -- residual diagnostics for every country-model equation and for
*! every country model as a system.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   F test for residual serial correlation  <- Toolbox Ftest_rsc.m
*   descriptive statistics of the residuals <- Toolbox dstats.m
*   Jarque-Bera normality, univariate       <- Toolbox jarquebera.m; GVARX .jb.uni
*   ARCH-LM, univariate                     <- GVARX .arch.uni
*   Jarque-Bera, multivariate               <- GVARX .jb.multi
*   portmanteau Qh and Qh*                  <- GVARX .pt.multi
*   Breusch-Godfrey LM, Edgerton-Shukur F   <- GVARX .bgserial
*   ARCH-LM, multivariate                   <- GVARX .arch.multi
*   White heteroskedasticity (special form) <- additional
*
* The univariate table is the one the Toolbox prints (Output 12 of the User
* Guide).  The multivariate table is what GVARX adds: an equation can look
* clean one at a time and still fail as a system, because the univariate
* tests ignore the contemporaneous correlation across the equations of the
* same country model.

program define _gvar_diag, rclass
    version 14.0

    syntax [,                                   ///
        PSC(integer 4)                          ///
        ARCH(integer 4)                         ///
        MULTIvariate                            ///
        LAGSpt(integer 16)                      ///
        LAGSbg(integer 5)                       ///
        MVARCH(integer 2)                       ///
        REPS(integer 0)                         ///
        SEED(string)                            ///
        DETail                                  ///
        noSUMmary                               ///
        SAVing(name)                            ///
        SAVEMV(name)                            ///
        GRaph                                   ///
        NAME(string)                            ///
    ]

    _gvar_require estimate

    if (`psc' < 1 | `arch' < 1) {
        di as err "psc() and arch() must be at least 1"
        exit 198
    }
    if (`lagspt' < 1 | `lagsbg' < 1 | `mvarch' < 1) {
        di as err "lagspt(), lagsbg() and mvarch() must be at least 1"
        exit 198
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))

    tempname R
    mata: st_matrix("`R'", gvar_resdiag(`psc', `arch'))
    local nr = rowsof(`R')

    local nsc 0
    local njb 0
    local nar 0
    local nwh 0
    local ntot 0

    * -----------------------------------------------------------------------
    * Table 1: one row per equation
    * -----------------------------------------------------------------------
    if ("`summary'" != "nosummary") {
        _gvar_title "Residual diagnostics of the VECMX* country models"
        di as text "  Serial correlation: F test of order " as result `psc' ///
                   as text ";  ARCH-LM of order " as result `arch' as text "."
        di ""
        di as text "{hline 92}"
        di as text %-11s "  Unit" %-8s "eq" _col(24) "F(sc)" _col(36) "JB" ///
                   _col(46) "p" _col(58) "ARCH" _col(68) "p" _col(78) "skew" ///
                   _col(88) "kurt"
        di as text "{hline 92}"
    }

    forvalues q = 1/`nr' {
        local i  = `R'[`q', 1]
        local j  = `R'[`q', 2]
        local u  : word `i' of `cn'
        mata: st_local("eqn", gvar_getyname(`i', `j'))
        local fs = `R'[`q', 5]
        local fc = `R'[`q', 4]
        local jb = `R'[`q', 6]
        local jp = `R'[`q', 7]
        local ac = `R'[`q', 8]
        local ap = `R'[`q', 9]
        local sk = `R'[`q', 12]
        local ku = `R'[`q', 13]
        local wp = `R'[`q', 18]

        local ++ntot
        local m1 " "
        if (`fs' < . & `fc' < . & `fs' > `fc') {
            local m1 "*"
            local ++nsc
        }
        local m2 " "
        if (`jp' < . & `jp' < 0.05) {
            local m2 "*"
            local ++njb
        }
        local m3 " "
        if (`ap' < . & `ap' < 0.05) {
            local m3 "*"
            local ++nar
        }
        if (`wp' < . & `wp' < 0.05) local ++nwh

        if ("`summary'" == "nosummary") continue

        if (`j' == 1) di as text "  " %-9s abbrev("`u'", 9) _continue
        else          di as text "  " %-9s "" _continue
        di as text %-8s abbrev("`eqn'", 8)              ///
           _col(20) as result %8.2f `fs' as text "`m1'" ///
           _col(30) as result %8.2f `jb'                ///
           _col(40) as result %8.3f `jp' as text "`m2'" ///
           _col(52) as result %8.2f `ac'                ///
           _col(62) as result %8.3f `ap' as text "`m3'" ///
           _col(73) as result %8.2f `sk'                ///
           _col(83) as result %8.2f `ku'
    }

    if ("`summary'" != "nosummary") {
        di as text "{hline 92}"
        di as text "  * marks rejection at 5%."
        di as text "  serial correlation " as result `nsc' as text "/" ///
                   as result `ntot' as text "   non-normal " as result `njb' ///
                   as text "/" as result `ntot' as text "   ARCH " ///
                   as result `nar' as text "/" as result `ntot'
        di as text "  A Gaussian residual has skewness 0 and kurtosis 3."
        di as text "  Every equation of every country model appears; there are"
        di as text "  no dots because each equation always has a residual."
        * With a dominant unit, `ntot' is short of K by the dominant variables --
        * they have no VECMX* and so no residual here.  Saying so stops the count
        * looking like missing results when compared with K.
        capture mata: st_local("hasdu", strofreal(gvar_hasdu()))
        if (_rc == 0 & "`hasdu'" == "1") {
            mata: st_local("ndu", strofreal(rows(gvar_getduylist())))
            mata: st_local("KK",  strofreal(gvar_getK()))
            di as text "  The count is " as result `ntot' as text ", not " ///
               as result `KK' as text ": the dominant unit's " ///
               as result `ndu' as text " variable(s) have no VECMX* and"
            di as text "  therefore no residual in this table.  See" ///
               as text " {bf:gvar dominant}"
            di as text "  for that block's own diagnostics."
        }
        di as text "  See {help gvar_diag##multivariate:gvar diag, multivariate}"
        di as text "  for the system-wide counterparts of these tests."
        di ""
    }

    * -----------------------------------------------------------------------
    * Table 2 (detail): descriptive statistics, heteroskedasticity, fit
    * -----------------------------------------------------------------------
    if ("`detail'" != "" & "`summary'" != "nosummary") {
        di as text "{hline 96}"
        di as text "  {bf:Residual descriptives, heteroskedasticity and fit}"
        di as text "{hline 96}"
        di as text %-11s "  Unit" %-8s "eq" _col(21) "mean" _col(31) "sd" ///
                   _col(41) "min" _col(51) "max" _col(62) "White" _col(72) "p" ///
                   _col(82) "R2" _col(91) "adjR2"
        di as text "{hline 96}"
        forvalues q = 1/`nr' {
            local i  = `R'[`q', 1]
            local j  = `R'[`q', 2]
            local u  : word `i' of `cn'
            mata: st_local("eqn", gvar_getyname(`i', `j'))
            local wp = `R'[`q', 18]
            local m4 " "
            if (`wp' < . & `wp' < 0.05) local m4 "*"
            if (`j' == 1) di as text "  " %-9s abbrev("`u'", 9) _continue
            else          di as text "  " %-9s "" _continue
            di as text %-8s abbrev("`eqn'", 8)                ///
               _col(17) as result %8.4f `=`R'[`q',10]'        ///
               _col(27) as result %8.4f `=`R'[`q',11]'        ///
               _col(37) as result %8.4f `=`R'[`q',14]'        ///
               _col(47) as result %8.4f `=`R'[`q',15]'        ///
               _col(57) as result %8.2f `=`R'[`q',16]'        ///
               _col(67) as result %8.3f `wp' as text "`m4'"   ///
               _col(78) as result %8.3f `=`R'[`q',19]'        ///
               _col(88) as result %8.3f `=`R'[`q',20]'
        }
        di as text "{hline 96}"
        di as text "  White is the special form of White's test: e^2 regressed on"
        di as text "  the fitted value and its square, chi2(2).  The full"
        di as text "  cross-product form is infeasible here, because a VECMX*"
        di as text "  equation has more cross-products than the sample has"
        di as text "  quarters.  Rejections at 5%: " as result `nwh' as text ///
                   " of " as result `ntot' as text "."
        di as text "  R2 and adjR2 are for the equation in first differences,"
        di as text "  so values of 0.1-0.4 are normal and are not a defect."
        di ""
    }

    * -----------------------------------------------------------------------
    * Table 3 (multivariate): one row per country model
    * -----------------------------------------------------------------------
    local domv 0
    if ("`multivariate'" != "" | "`savemv'" != "") local domv 1

    if (`reps' < 0) {
        di as err "reps() cannot be negative"
        exit 198
    }
    if (`reps' > 0) local domv 1

    tempname M B
    if (`domv') {
        mata: st_matrix("`M'", gvar_resdiag_mv(`lagspt', `lagsbg', `mvarch'))
    }
    else {
        matrix `M' = J(1, 1, .)
    }
    local nm = rowsof(`M')
    if (`domv' == 0) local nm 0

    * Bootstrap p-values.  The asymptotic distributions of these statistics
    * are unreliable at country-model dimensions; see the note under the
    * table and {help gvar_diag##size:the size study}.
    local doboot 0
    if (`reps' > 0) {
        local doboot 1
        if ("`seed'" != "") set seed `seed'
        di as text "  bootstrapping " as result `reps' as text ///
                   " replications for each of " as result `N' ///
                   as text " country models ..."
        mata: st_matrix("`B'", gvar_resdiag_mvboot(`lagspt', `lagsbg', ///
                                                   `mvarch', `reps'))
    }

    local mjb 0
    local mpt 0
    local mps 0
    local mar 0
    local mbg 0
    local mes 0
    local mtot 0
    local trimpt 0
    local trimbg 0
    local trimar 0

    if ("`multivariate'" != "" & "`summary'" != "nosummary") {
        _gvar_title "System-wide residual diagnostics of each country model"
        di as text "  Each row treats the k equations of one country model as a"
        di as text "  system, so the contemporaneous correlation across those"
        di as text "  equations is taken into account.  Requested orders:"
        di as text "  portmanteau h=" as result `lagspt' as text ", " ///
                   "Breusch-Godfrey h=" as result `lagsbg' as text ", " ///
                   "ARCH q=" as result `mvarch' as text "."
        di ""
        di as text "{hline 104}"
        di as text %-11s "  Unit" _col(13) "k" _col(19) "JBm" _col(29) "p" ///
                   _col(39) "Qh" _col(49) "p" _col(58) "Qh*" _col(68) "p" ///
                   _col(76) "ARCHm" _col(86) "p" _col(95) "h,h,q"
        di as text "{hline 104}"
    }

    forvalues q = 1/`nm' {
        local i  = `M'[`q', 1]
        local u  : word `i' of `cn'
        local ++mtot

        local p1 = `M'[`q',  6]
        local p2 = `M'[`q', 15]
        local p3 = `M'[`q', 18]
        local p4 = `M'[`q', 21]
        local p5 = `M'[`q', 24]
        local p6 = `M'[`q', 28]

        local s1 " "
        if (`p1' < . & `p1' < 0.05) {
            local s1 "*"
            local ++mjb
        }
        local s2 " "
        if (`p2' < . & `p2' < 0.05) {
            local s2 "*"
            local ++mpt
        }
        local s3 " "
        if (`p3' < . & `p3' < 0.05) {
            local s3 "*"
            local ++mps
        }
        local s4 " "
        if (`p4' < . & `p4' < 0.05) {
            local s4 "*"
            local ++mar
        }
        if (`p5' < . & `p5' < 0.05) local ++mbg
        if (`p6' < . & `p6' < 0.05) local ++mes

        local hp = `M'[`q', 29]
        local hb = `M'[`q', 30]
        local hq = `M'[`q', 31]
        if (`hp' != `lagspt')    local ++trimpt
        if (`hb' != `lagsbg')    local ++trimbg
        if (`hq' != `mvarch') local ++trimar

        if ("`multivariate'" == "" | "`summary'" == "nosummary") continue

        local ord "`hp',`hb',`hq'"
        di as text "  " %-9s abbrev("`u'", 9)                  ///
           _col(12) as result %3.0f `=`M'[`q',2]'              ///
           _col(16) as result %8.2f `=`M'[`q',4]'              ///
           _col(26) as result %8.3f `p1' as text "`s1'"        ///
           _col(36) as result %8.1f `=`M'[`q',13]'             ///
           _col(46) as result %8.3f `p2' as text "`s2'"        ///
           _col(55) as result %8.1f `=`M'[`q',16]'             ///
           _col(65) as result %8.3f `p3' as text "`s3'"        ///
           _col(74) as result %8.1f `=`M'[`q',19]'             ///
           _col(84) as result %8.3f `p4' as text "`s4'"        ///
           _col(93) as text %9s "`ord'"
    }

    if ("`multivariate'" != "" & "`summary'" != "nosummary") {
        di as text "{hline 104}"
        di as text "  JBm   Jarque-Bera on Cholesky-standardised residuals, chi2(2k)"
        di as text "  Qh    portmanteau, asymptotic form, chi2(k^2 h - k^2 p + k)"
        di as text "  Qh*   the same statistic with the small-sample adjustment"
        di as text "  ARCHm multivariate ARCH-LM on the standardised residuals"
        di as text "  h,h,q the orders actually used for Qh, Breusch-Godfrey and"
        di as text "        ARCH; they are cut back when the auxiliary regression"
        di as text "        would need more regressors than the sample has quarters"
        di as text "{hline 104}"
        di as text "  * marks rejection at 5%:  JBm " as result `mjb' as text "/" ///
                   as result `mtot' as text "   Qh " as result `mpt' as text "/" ///
                   as result `mtot' as text "   Qh* " as result `mps' as text "/" ///
                   as result `mtot' as text "   ARCHm " as result `mar' ///
                   as text "/" as result `mtot'
        if (`trimpt' | `trimbg' | `trimar') {
            di as text "  Orders were cut back for " as result `trimpt' ///
               as text " (Qh), " as result `trimbg' as text " (BG) and " ///
               as result `trimar' as text " (ARCH) country models."
        }
        di as text "  Non-normality is the usual finding in quarterly"
        di as text "  macroeconomic data and does not invalidate the generalized"
        di as text "  impulse responses, which need only the second moments."
        di ""

        di as text "{hline 84}"
        di as text "  {bf:Serial correlation of the system: Breusch-Godfrey and Edgerton-Shukur}"
        di as text "{hline 84}"
        di as text %-11s "  Unit" _col(15) "LM" _col(25) "df" _col(35) "p" ///
                   _col(46) "ES F" _col(57) "df1" _col(65) "df2" _col(75) "p"
        di as text "{hline 84}"
        forvalues q = 1/`nm' {
            local i = `M'[`q', 1]
            local u : word `i' of `cn'
            local p5 = `M'[`q', 24]
            local p6 = `M'[`q', 28]
            local t5 " "
            if (`p5' < . & `p5' < 0.05) local t5 "*"
            local t6 " "
            if (`p6' < . & `p6' < 0.05) local t6 "*"
            di as text "  " %-9s abbrev("`u'", 9)           ///
               _col(11) as result %9.2f `=`M'[`q',22]'      ///
               _col(21) as result %8.0f `=`M'[`q',23]'      ///
               _col(31) as result %8.3f `p5' as text "`t5'" ///
               _col(42) as result %9.3f `=`M'[`q',25]'      ///
               _col(53) as result %7.0f `=`M'[`q',26]'      ///
               _col(61) as result %7.0f `=`M'[`q',27]'      ///
               _col(70) as result %8.3f `p6' as text "`t6'"
        }
        di as text "{hline 84}"
        di as text "  * marks rejection at 5%:  LM " as result `mbg' as text "/" ///
                   as result `mtot' as text "   ES F " as result `mes' ///
                   as text "/" as result `mtot'
        di as text "  The Edgerton-Shukur F is the small-sample correction to the"
        di as text "  LM statistic and is the one to read with about 115 quarters."
        di as text "  Widespread rejection means the country lag orders are too"
        di as text "  short; raise them with {help gvar_lags:gvar lags} or set"
        di as text "  them by hand in {help gvar_setup:gvar setup, spec()}."
        di ""
    }

    * -----------------------------------------------------------------------
    * Table 4: bootstrap p-values
    * -----------------------------------------------------------------------
    local bjb 0
    local bpt 0
    local bps 0
    local bar 0
    local bbg 0
    local bes 0
    local bmin 0

    if (`doboot') {
        local nb = rowsof(`B')
        forvalues q = 1/`nb' {
            if (`B'[`q', 3] < . & `B'[`q', 3] < 0.05)  local ++bjb
            if (`B'[`q', 6] < . & `B'[`q', 6] < 0.05)  local ++bpt
            if (`B'[`q', 7] < . & `B'[`q', 7] < 0.05)  local ++bps
            if (`B'[`q', 8] < . & `B'[`q', 8] < 0.05)  local ++bar
            if (`B'[`q', 9] < . & `B'[`q', 9] < 0.05)  local ++bbg
            if (`B'[`q',10] < . & `B'[`q',10] < 0.05)  local ++bes
        }
        local bmin = `B'[1, 2]
        forvalues q = 1/`nb' {
            if (`B'[`q', 2] < `bmin') local bmin = `B'[`q', 2]
        }
    }

    if (`doboot' & "`summary'" != "nosummary") {
        _gvar_title "Bootstrap p-values for the system-wide diagnostics"
        di as text "  " as result `reps' as text " parametric-bootstrap" ///
                   " replications per country model."
        di as text "  Each replication draws Gaussian innovations, builds the"
        di as text "  path forward from the estimated VARX* holding the weakly"
        di as text "  exogenous block at its observed values, re-estimates the"
        di as text "  VECMX* at the same rank and lag orders, and recomputes"
        di as text "  every statistic.  No asymptotic approximation is used."
        di ""
        di as text "{hline 94}"
        di as text %-11s "  Unit" _col(14) "reps" _col(24) "JBm" _col(34) "skew" ///
                   _col(44) "kurt" _col(54) "Qh" _col(63) "Qh*" _col(73) "ARCH" ///
                   _col(83) "LM" _col(91) "ES F"
        di as text "{hline 94}"
        forvalues q = 1/`nb' {
            local i = `B'[`q', 1]
            local u : word `i' of `cn'
            di as text "  " %-9s abbrev("`u'", 9) ///
               _col(12) as result %6.0f `=`B'[`q',2]' _continue
            forvalues c = 3/10 {
                local pb = `B'[`q', `c']
                local sb " "
                if (`pb' < . & `pb' < 0.05) local sb "*"
                local cc = 14 + 10 * (`c' - 2)
                di _col(`cc') as result %7.3f `pb' as text "`sb'" _continue
            }
            di ""
        }
        di as text "{hline 94}"
        di as text "  * marks rejection at 5% on the bootstrap distribution:"
        di as text "    JBm " as result `bjb' as text "/" as result `mtot' ///
           as text "   Qh " as result `bpt' as text "/" as result `mtot' ///
           as text "   Qh* " as result `bps' as text "/" as result `mtot' ///
           as text "   ARCH " as result `bar' as text "/" as result `mtot'
        di as text "    LM " as result `bbg' as text "/" as result `mtot' ///
           as text "   ES F " as result `bes' as text "/" as result `mtot'
        if (`bmin' < `reps') {
            di as text "  The fewest replications that converged for any unit was " ///
               as result `bmin' as text "."
        }
        di as text "  Read these in preference to the asymptotic p-values above."
        di as text "  A Monte Carlo at this model's own dimensions puts the"
        di as text "  asymptotic Qh* at three to nine times its nominal size and"
        di as text "  the asymptotic Edgerton-Shukur F at about twice nominal for"
        di as text "  a unit whose rank is close to its block size; only Qh at"
        di as text "  h=16 and the multivariate Jarque-Bera hold up unaided."
        di ""
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    if ("`savemv'" != "" & `domv') {
        matrix `savemv' = `M'
    }
    if (`doboot') {
        return matrix diagboot = `B', copy
        return scalar reps  = `reps'
        return scalar bjb   = `bjb'
        return scalar bpt   = `bpt'
        return scalar bps   = `bps'
        return scalar barch = `bar'
        return scalar bbg   = `bbg'
        return scalar bes   = `bes'
    }
    * ---- graph --------------------------------------------------------------
    * The serial-correlation F for every equation against its own 5% critical
    * value.  This is the diagnostic that matters most: non-normality is
    * expected in quarterly macro data and does not invalidate the generalized
    * responses, but serial correlation says the lag orders are too short and
    * biases everything downstream.
    if ("`graph'" != "") {
        tempname G
        matrix `G' = J(`nr', 4, .)
        forvalues q = 1/`nr' {
            matrix `G'[`q', 1] = `R'[`q', 1]
            matrix `G'[`q', 2] = `R'[`q', 5]
            matrix `G'[`q', 3] = `R'[`q', 4]
            matrix `G'[`q', 4] = 1
        }
        local sub "F test for residual serial correlation at `psc' lag(s); marked = reject at 5%"
        _gvar_dotplot `G' `nr' "`cn'" ///
            "Residual serial correlation, VECMX* equations" "`sub'" ///
            "F statistic" "`name'" 0
    }

    if (`domv') {
        return matrix diagmv = `M', copy
    }
    return matrix diag   = `R', copy
    return scalar nsc  = `nsc'
    return scalar njb  = `njb'
    return scalar narch = `nar'
    return scalar nwhite = `nwh'
    return scalar nequations = `ntot'
    return scalar mjb   = `mjb'
    return scalar mpt   = `mpt'
    return scalar march = `mar'
    return scalar mbg   = `mbg'
    return scalar mes   = `mes'
    return scalar nunits = `mtot'
end
