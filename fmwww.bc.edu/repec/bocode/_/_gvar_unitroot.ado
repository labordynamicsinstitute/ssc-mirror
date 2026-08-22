*! _gvar_unitroot 1.0.1  21aug2026
*! gvar unitroot -- unit-root tests on the domestic, foreign-specific and
*! global variable blocks.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   ADF, lag by AIC or SBC                  <- Toolbox adf.m, unitroot_tests.m
*   weighted-symmetric Dickey-Fuller        <- Toolbox ws.m (Park-Fuller)
*   WS read at the ADF-selected lag         <- Toolbox unitroot_tests.m
*   four blocks: levels +/- trend, D, DD    <- Toolbox unitroot_tests.m
*   DdPS asymptotic 5% critical values      <- Toolbox unitroot_tests.m
*   ADF-GLS, KPSS, Phillips-Perron          <- added (standard practice)

program define _gvar_unitroot, rclass
    version 14.0

    syntax [, MAXLag(integer 4)        ///
              IC(string)               ///
              TESTs(string)            ///
              BLOCKs(string)           ///
              DOMestic                 ///
              FOReign                  ///
              noSUMmary                ///
              SAVing(name)             ///
              GRaph                    ///
              GSTat(string)            ///
              GBLock(integer 1)        ///
              NAME(string) ]

    _gvar_require foreign

    * ---- which information criterion picks the ADF lag --------------------
    if ("`ic'" == "") local ic sbc
    local ic = lower("`ic'")
    if ("`ic'" == "aic")      local icsel 2
    else if ("`ic'" == "sbc") local icsel 3
    else {
        di as err "ic() must be {bf:aic} or {bf:sbc}"
        exit 198
    }

    * ---- which tests -------------------------------------------------------
    if ("`tests'" == "") local tests "adf ws"
    local tests = lower("`tests'")
    foreach t of local tests {
        if (!inlist("`t'", "adf", "ws", "gls", "kpss", "pp")) {
            di as err "tests(): unknown test {bf:`t'}"
            di as err "choose from adf, ws, gls, kpss, pp"
            exit 198
        }
    }

    * ---- which blocks ------------------------------------------------------
    if ("`blocks'" == "") local blocks "1 2 3 4"
    foreach b of local blocks {
        if (!inlist(`b', 1, 2, 3, 4) ) {
            di as err "blocks() must list values from 1 to 4"
            exit 198
        }
    }

    * ---- which variable blocks --------------------------------------------
    local kinds ""
    if ("`domestic'" != "") local kinds "1"
    if ("`foreign'"  != "") local kinds "`kinds' 2"
    if ("`kinds'" == "")    local kinds "1 2"

    * =======================================================================
    * Run the battery
    * =======================================================================
    tempname R
    mata: st_matrix("`R'", gvar_urt(`maxlag', `icsel'))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    mata: st_local("N",  strofreal(gvar_getN()))

    local nr = rowsof(`R')

    * =======================================================================
    * Report
    * =======================================================================
    * The report loop was never guarded, so nosummary had nothing to switch
    * off -- and the option was declared as SUMmary, whose local nothing read.
    * There was no way to run this command quietly except -quietly-.
    if ("`summary'" == "nosummary") local kinds ""

    foreach kind of local kinds {
        if ("`kind'" == "1") local kindlab "Domestic variables"
        else                 local kindlab "Foreign-specific variables (x*)"

        foreach b of local blocks {
            if (`b' == 1) local blab "levels, intercept and trend"
            if (`b' == 2) local blab "levels, intercept only"
            if (`b' == 3) local blab "first differences, intercept only"
            if (`b' == 4) local blab "second differences, intercept only"

            foreach t of local tests {
                * Stata requires { to be the last thing on its line and }
                * to stand alone, so these cannot be written as one-liners.
                *
                * col is the statistic; cvc is the column PRINTED as "the
                * critical value" in the last column of the table.  For
                * ADF-GLS and KPSS that printed value does NOT govern the
                * stars -- their cutoffs are constants set in _gvar_urt_table,
                * because GLS detrending and a stationarity null both have
                * their own distributions.  The footer of each table says
                * which number produced its stars.
                if ("`t'" == "adf") {
                    local col  5
                    local cvc  6
                    local tlab "ADF"
                }
                if ("`t'" == "ws") {
                    local col  8
                    local cvc  9
                    local tlab "Weighted symmetric (WS)"
                }
                if ("`t'" == "gls") {
                    local col 10
                    local cvc  6
                    local tlab "ADF-GLS"
                }
                if ("`t'" == "kpss") {
                    local col 11
                    local cvc  6
                    local tlab "KPSS"
                }
                if ("`t'" == "pp") {
                    local col 12
                    local cvc  6
                    local tlab "Phillips-Perron Z(t)"
                }

                tempname TAB
                mata: st_matrix("`TAB'", gvar_urt_tab(st_matrix("`R'"), ///
                                         `kind', `b', `col', `cvc'))
                _gvar_urt_table `TAB' "`__urtvars'" "`cn'" "`t'" "`tlab'" ///
                    "`kindlab' -- `blab'" `b'
            }
        }
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
        di as text "Full results saved in matrix {bf:`saving'} " ///
                   "(kind unit var block adf cv lag ws cv gls kpss pp)."
    }

    * ---- graph --------------------------------------------------------------
    * One test for one block, each statistic against its own 5% cutoff.
    * For the four t-type tests a rejection is the statistic falling BELOW the
    * cutoff -- both are negative -- so the marked points are the STATIONARY
    * series, which in a levels block is the interesting minority.  KPSS runs
    * the other way: its null is stationarity, its statistic is positive, and
    * a rejection is a LARGE value.  Getting that backwards marks exactly the
    * complement and still draws a plausible-looking picture.
    if ("`graph'" != "") {
        local gs = lower("`gstat'")
        if ("`gs'" == "") local gs adf
        if (!inlist("`gs'", "adf", "ws", "gls", "kpss", "pp")) {
            di as err "gstat() must be {bf:adf}, {bf:ws}, {bf:gls}," ///
                      " {bf:kpss} or {bf:pp}"
            exit 198
        }
        local gblk = `gblock'
        if (`gblk' < 1 | `gblk' > 4) {
            di as err "gblock() must be 1, 2, 3 or 4"
            exit 198
        }
        * the matrix holds BOTH the domestic and the foreign block, so the
        * kind has to be filtered as well or the two get interleaved
        local gk 1
        if ("`domestic'" == "" & "`foreign'" != "") local gk 2

        * Which column holds the statistic, where its cutoff comes from,
        * and which side of the cutoff counts as a rejection.  "row" means the
        * cutoff travels with each row of the results matrix; a number means it
        * is a constant that depends only on whether the block has a trend.
        *   gdir = 1  reject BELOW the cutoff (all the t-type tests)
        *   gdir = 0  reject ABOVE it (KPSS, whose null is stationarity)
        if ("`gs'" == "adf") {
            local gcol 5
            local gcvc "row"
            local gcvr 6
            local gdir 1
            local gnm  "ADF unit-root"
        }
        if ("`gs'" == "ws") {
            local gcol 8
            local gcvc "row"
            local gcvr 9
            local gdir 1
            local gnm  "Weighted-symmetric unit-root"
        }
        if ("`gs'" == "pp") {
            local gcol 12
            local gcvc "row"
            local gcvr 6
            local gdir 1
            local gnm  "Phillips-Perron Z(t)"
        }
        if ("`gs'" == "gls") {
            local gcol 10
            local gdir 1
            local gnm  "ADF-GLS"
            if (`gblk' == 1) local gcvc -2.89
            else             local gcvc -1.95
        }
        if ("`gs'" == "kpss") {
            local gcol 11
            local gdir 0
            local gnm  "KPSS stationarity"
            if (`gblk' == 1) local gcvc 0.146
            else             local gcvc 0.463
        }

        local nq = rowsof(`R')
        tempname G
        matrix `G' = J(`nq', 4, .)
        local nk 0
        forvalues q = 1/`nq' {
            if (`R'[`q', 4] != `gblk') continue
            if (`R'[`q', 1] != `gk')   continue
            local ++nk
            matrix `G'[`nk', 1] = `R'[`q', 2]
            matrix `G'[`nk', 2] = `R'[`q', `gcol']
            if ("`gcvc'" == "row") matrix `G'[`nk', 3] = `R'[`q', `gcvr']
            else                   matrix `G'[`nk', 3] = `gcvc'
            matrix `G'[`nk', 4] = 1
        }
        if (`nk' == 0) {
            di as err "no rows for block `gblk'"
            exit 498
        }
        matrix `G' = `G'[1..`nk', 1...]

        local bnm1 "levels, intercept and trend"
        local bnm2 "levels, intercept only"
        local bnm3 "first differences, intercept only"
        local bnm4 "second differences, intercept only"
        local sub "`bnm`gblk''; marked = rejects at 5%"
        if ("`gs'" == "kpss") {
            local sub "`bnm`gblk''; marked = rejects STATIONARITY at 5%"
        }
        _gvar_dotplot `G' `nk' "`cn'" ///
            "`gnm' statistics" "`sub'" ///
            "statistic" "`name'" `gdir'
    }

    return matrix urt = `R', copy
    return local  ic     "`ic'"
    return scalar maxlag = `maxlag'
end
* ---------------------------------------------------------------------------
* One block per VARIABLE, listing only the units that carry it.
*
* A rectangular units x variables grid cannot avoid blank cells when units own
* different variables: 26 units and 9 variables give 234 cells for 136 real
* results, and no amount of column reshuffling changes that.  The blanks are a
* property of the layout, not of the data.
*
* print_dstats.m is variable-major for this reason -- it writes one block per
* variable with countries as rows.  It still emits NaN rows for countries that
* lack the variable; omitting those rows instead makes a blank impossible.
* Every printed number is a result, and the unit count in each header says how
* many countries carry that series.
*
* Step -> source map
*   block-per-variable layout   <- Toolbox print_dstats.m structure
*   the star rule               <- _gvar_urt_mark, shared with nothing else now
* ---------------------------------------------------------------------------
program define _gvar_urt_table
    version 14.0
    args TAB vlist cn tcode tlab title blk

    local nv : word count `vlist'
    if (`nv' == 0) exit
    local nu : word count `cn'

    * ---- the cutoffs that are NOT stored beside the statistic ---------------
    * Only block 1 carries a trend, and that changes two of the five cutoffs.
    * Getting this wrong is silent: the table still prints, with stars in the
    * wrong places.
    *
    *   ADF, WS   their own 5% value travels with each row (columns 6 and 9)
    *   PP Z(t)   the same asymptotic distribution as the ADF t, so the ADF
    *             value is correct for it and is used
    *   ADF-GLS   Elliott, Rothenberg & Stock (1996): -2.89 with a trend,
    *             -1.95 without.  The ADF value is far too demanding.
    *   KPSS      Kwiatkowski, Phillips, Schmidt & Shin (1992): 0.146 for
    *             trend stationarity, 0.463 for level stationarity.  The null
    *             is STATIONARITY, so rejection is a large POSITIVE value.
    if ("`blk'" == "") local blk 2
    if (`blk' == 1) {
        local gcv -2.89
        local kcv 0.146
        local trlab "with a trend"
    }
    else {
        local gcv -1.95
        local kcv 0.463
        local trlab "without a trend"
    }

    local w 74
    di ""
    di as text "{hline `w'}"
    di as text "  {bf:`tlab'} -- `title'"
    di as text "{hline `w'}"

    local nrej 0
    local ntot 0
    local nfl  0

    forvalues p = 1/`nv' {
        local v : word `p' of `vlist'

        * which units carry this variable, and how many of them reject
        local own ""
        forvalues i = 1/`nu' {
            if (`TAB'[`i', `=2*`nv'+`p''] == 1) local own "`own' `i'"
        }
        local nown : word count `own'
        if (`nown' == 0) continue

        local vrej 0
        foreach i of local own {
            local st = `TAB'[`i', `p']
            local cv = `TAB'[`i', `=`nv'+`p'']
            _gvar_urt_mark "`tcode'" `st' `cv' `kcv' `gcv'
            if ("`r(mark)'" == "*") local ++vrej
        }

        di as text "  {bf:`v'}" _col(14) as text "carried by " ///
           as result `nown' as text " unit(s), " as result `vrej' ///
           as text " reject" _continue
        if (`nown' > 0) {
            di as text " (" as result %4.1f `=100*`vrej'/`nown'' as text "%)"
        }
        else {
            di ""
        }

        * flow the units across the line: four per line keeps it inside 74
        * columns and never leaves a hole, because only owners are printed
        local col 0
        foreach i of local own {
            local u : word `i' of `cn'
            local st = `TAB'[`i', `p']
            local cv = `TAB'[`i', `=`nv'+`p'']
            if (`col' == 0) di as text "    " _continue
            if (`st' >= .) {
                * the unit HAS the variable and the test still produced
                * nothing.  That is a failure and the only thing that earns a
                * dot; there is no other way for a gap to appear here.
                local ++nfl
                * 9 + 6 + 2 = 17 columns per entry, four to a line.  The mark
                * field is TWO wide so a star cannot abut the next unit name.
                di as text %-9s abbrev("`u'", 9) as err %6s "." ///
                   as text %-2s "" _continue
            }
            else {
                local ++ntot
                _gvar_urt_mark "`tcode'" `st' `cv' `kcv' `gcv'
                local mark "`r(mark)'"
                if ("`mark'" == "*") local ++nrej
                di as text %-9s abbrev("`u'", 9) ///
                   as result %6.2f `st' as text %-2s "`mark'" _continue
            }
            local ++col
            if (`col' == 4) {
                di ""
                local col 0
            }
        }
        if (`col' > 0) di ""
        di ""
    }

    di as text "{hline `w'}"
    if (`ntot' > 0) {
        di as text "  Rejections: " as result `nrej' as text " of " ///
                   as result `ntot' as text " (" ///
                   as result %4.1f `=100*`nrej'/`ntot'' as text "%)"
        di as text "  Every printed number is a result.  Only the units that" ///
                   " carry a series"
        di as text "  are listed under it, so a gap in this table is not" ///
                   " possible" _continue
        if (`nfl' > 0) {
            di as text " --"
            di as err "  except the `nfl' dot(s) above, where a unit HAS the" ///
                      " variable and the"
            di as err "  test failed.  Those are a defect, not a" ///
                      " specification fact."
        }
        else {
            di as text ", and there are none."
        }
    }

    * Each footer names the cutoff THIS table actually used, not the pair of
    * values the test has in general: a reader checking a star by hand needs
    * the number that produced it.
    if ("`tcode'" == "adf") {
        di as text "  5% critical value: -3.45 `trlab' (Dees, di Mauro," ///
                   " Pesaran & Smith 2007)."
    }
    if ("`tcode'" == "ws") {
        di as text "  5% critical value: Park & Fuller weighted symmetric," ///
                   " `trlab'."
    }
    if ("`tcode'" == "gls") {
        di as text "  5% critical value " as result "`gcv'" as text ///
                   " (`trlab'), Elliott, Rothenberg & Stock (1996)."
        di as text "  This is {bf:not} the ADF value: GLS detrending changes" ///
                   " the distribution."
    }
    if ("`tcode'" == "pp") {
        di as text "  5% critical value: the ADF one.  The Phillips-Perron" ///
                   " Z(t) shares the"
        di as text "  Dickey-Fuller asymptotic distribution, so it applies" ///
                   " unchanged."
    }
    if ("`tcode'" == "kpss") {
        di as text "  5% critical value " as result "`kcv'" as text ///
                   " (`trlab'), Kwiatkowski, Phillips,"
        di as text "  Schmidt & Shin (1992).  H0 here is {bf:STATIONARITY}," ///
                   " so * means the"
        di as text "  null is rejected and the series looks nonstationary."
    }
    if ("`tcode'" != "kpss") {
        di as text "  * marks rejection of the unit-root null at 5%."
    }
end


* ---------------------------------------------------------------------------
* The one rule that decides whether a unit-root statistic gets a star.
*
* Factored out because it is now needed in two places -- the grid and the
* single-owner block -- and duplicated arithmetic drifts.  The same lesson
* applied to the Ploberger-Kramer path functions, which are checked against
* their summary statistics for exactly this reason.
*
*   KPSS      H0 is STATIONARITY, so a rejection is a LARGE POSITIVE value,
*             against the Kwiatkowski-Phillips-Schmidt-Shin cutoff that
*             depends on whether the block carries a trend.
*   ADF-GLS   Elliott-Rothenberg-Stock cutoff, not the ADF one: GLS
*             detrending changes the distribution.
*   ADF, WS   their own cutoff travels with the row.
*   PP Z(t)   the ADF cutoff, which is correct because the Z(t) shares the
*             Dickey-Fuller asymptotic distribution.
* ---------------------------------------------------------------------------
program define _gvar_urt_mark, rclass
    version 14.0
    args tcode st cv kcv gcv

    local mark " "
    if ("`tcode'" == "kpss") {
        if (`st' < . & `st' > `kcv') local mark "*"
    }
    else if ("`tcode'" == "gls") {
        if (`st' < . & `st' < `gcv') local mark "*"
    }
    else {
        if (`st' < . & `cv' < . & `st' < `cv') local mark "*"
    }
    return local mark "`mark'"
end
