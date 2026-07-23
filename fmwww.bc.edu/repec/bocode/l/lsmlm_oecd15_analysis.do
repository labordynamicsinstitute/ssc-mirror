/*****************************************************************************
  lsmlm_oecd15_analysis.do
  ---------------------------------------------------------------------------
  A complete worked application of the -lsmlm- command (Lee-Strazicich minimum
  LM unit root test with structural breaks) to the shipped example dataset
  lsmlm_oecd15.dta: log relative per-capita income for 15 OECD countries,
  1870-1994.

  ECONOMIC QUESTION
  -----------------
  y = log(country GDP per capita / OECD15 average GDP per capita).
  If y is stationary (unit root REJECTED), the country's relative income
  reverts to a fixed level -> convergence. If y has a unit root, shocks to
  relative income are permanent -> no convergence. Allowing for structural
  breaks matters: ignoring a real break biases standard tests toward failing
  to reject the unit root.

  WHAT THIS FILE PRODUCES
  -----------------------
    Section 1  Setup and data check
    Section 2  Descriptive statistics
    Section 3  Single-country walkthrough (all model variants)
    Section 4  TABLE 1  two-break LM test, full sample, 15 countries
    Section 5  TABLE 2  one-break LM test, full sample, 15 countries
    Section 6  TABLE 3  two-break LM test on sub-samples
    Section 7  Piecewise trend models at the estimated breaks
    Section 8  Figures - one standalone PNG per country, plus 2 summaries
    Section 9  Excel workbook with every table

  REQUIREMENTS
  ------------
    - lsmlm installed (net install lsmlm, from("<folder>"))
    - lsmlm_oecd15.dta available (shipped with the package)

  RUN TIME WARNING
  ----------------
  lsmlm searches the break dates on a native-Stata grid. The two-break search
  over 15 countries with T=125 is the expensive part and can take a while
  (order of tens of minutes on a typical machine). Set QUICK to 1 below for a
  fast smoke run (fewer lags, 3 countries) before committing to the full run.
*****************************************************************************/

clear all
set more off
set linesize 120

*============================================================================
* SECTION 1  SETUP AND DATA CHECK
*============================================================================

*--- USER SETTINGS ----------------------------------------------------------
* QUICK = 1 : fast trial run (3 countries, maxlag 2)
* QUICK = 0 : full analysis (15 countries, maxlag 8)
local QUICK = 1

* Where to write results. Change to any folder you like.
global OUT "C:\Users\ibrah\OneDrive\Masaüstü\lsmlm\outputs"

* Econometric settings for annual data (used when QUICK = 0)
local MAXLAG  8      // maximum augmenting lags for general-to-specific search
local MINDIST 5      // minimum number of years between the two breaks
local TRIM    0.10   // fraction trimmed at each end of the break search

* Shorter sub-samples need a smaller maxlag to keep enough residual d.f.
local MAXLAG_SUB 4
*----------------------------------------------------------------------------

if `QUICK' {
    local MAXLAG     2
    local MAXLAG_SUB 2
    di as txt _n "*** QUICK MODE: 3 countries, maxlag(`MAXLAG'). Set QUICK = 0 for the full run. ***"
}

capture mkdir "$OUT"

capture which lsmlm
if _rc {
    di as error "lsmlm not found. Install it first, e.g.:"
    di as error "    net install lsmlm, from(\"D:/lsmlm\")"
    exit 111
}

* Load the shipped example dataset. sysuse finds datasets installed along the
* ado-path; if that fails, fall back to a plain -use- from the current folder.
capture sysuse lsmlm_oecd15, clear
if _rc {
    capture use "lsmlm_oecd15.dta", clear
    if _rc {
        di as error "lsmlm_oecd15.dta not found. Put it in the working directory,"
        di as error "or install the package so that -sysuse lsmlm_oecd15- works."
        exit 601
    }
}

di as txt _n "{hline 78}"
di as res  "  DATA: OECD15 relative per-capita income, 1870-1994"
di as txt  "{hline 78}"
describe
xtset cid year, yearly

* Restrict to a few countries in QUICK mode
if `QUICK' keep if inlist(country, "France", "United Kingdom", "United States")

levelsof cid, local(cids)
local ncty : word count `cids'
di as txt _n "Countries in this run: " as res `ncty'

* Log the session
capture log close _all
log using "$OUT/lsmlm_oecd15_analysis.log", replace text name(main)

timer clear 1
timer on 1

*============================================================================
* SECTION 2  DESCRIPTIVE STATISTICS
*============================================================================

di as txt _n "{hline 78}"
di as res  "  SECTION 2: Descriptive statistics"
di as txt  "{hline 78}"

tempname D
postfile `D' str32 country int N double mean_gdppc double mean_rel ///
    double mean_y double sd_y double min_y double max_y ///
    using "$OUT/desc_stats.dta", replace

foreach i of local cids {
    quietly levelsof country if cid==`i', local(cn) clean
    quietly summarize gdppc if cid==`i'
    local m_g = r(mean)
    local nn  = r(N)
    quietly summarize rel_gdppc if cid==`i'
    local m_r = r(mean)
    quietly summarize y if cid==`i'
    post `D' ("`cn'") (`nn') (`m_g') (`m_r') (r(mean)) (r(sd)) (r(min)) (r(max))
}
postclose `D'

preserve
    use "$OUT/desc_stats.dta", clear
    format mean_gdppc %9.0f
    format mean_rel mean_y sd_y min_y max_y %7.3f
    list country N mean_gdppc mean_rel mean_y sd_y min_y max_y, noobs sepby(country) abbrev(12)
restore

*============================================================================
* SECTION 3  SINGLE-COUNTRY WALKTHROUGH
*----------------------------------------------------------------------------
* Run every model variant on one country so the output of each is visible.
*============================================================================

di as txt _n "{hline 78}"
di as res  "  SECTION 3: Single-country walkthrough (France)"
di as txt  "{hline 78}"

preserve
    keep if country == "France"
    tsset year, yearly

    di as txt _n ">>> (a) No break: Schmidt-Phillips LM test"
    lsmlm y, breaks(0) maxlag(`MAXLAG')

    di as txt _n ">>> (b) One break, crash model (level shift)"
    lsmlm y, breaks(1) model(crash) maxlag(`MAXLAG') trim(`TRIM')

    di as txt _n ">>> (c) One break, trend-break model (level + trend shift)"
    lsmlm y, breaks(1) model(break) maxlag(`MAXLAG') trim(`TRIM')

    di as txt _n ">>> (d) Two breaks, trend-break model  [the main specification]"
    lsmlm y, breaks(2) model(break) maxlag(`MAXLAG') mindist(`MINDIST') trim(`TRIM')

    * Everything the command returns is available in r()
    di as txt _n ">>> Stored results from the last run:"
    di as txt "   tau       = " as res r(tau)
    di as txt "   lags (k)  = " as res r(k)
    di as txt "   break 1   = " as res r(tb1) as txt "   lambda1 = " as res r(lambda1)
    di as txt "   break 2   = " as res r(tb2) as txt "   lambda2 = " as res r(lambda2)
    di as txt "   5% CV     = " as res r(cv5)
    di as txt "   decision  = " as res "`r(siglevel)'"

    di as txt _n ">>> (e) Post-war sub-sample only, via if"
    lsmlm y if year >= 1946, breaks(1) model(break) maxlag(`MAXLAG_SUB') trim(`TRIM')
restore

*============================================================================
* SECTION 4  TABLE 1 - TWO-BREAK LM TEST, FULL SAMPLE
*============================================================================

di as txt _n "{hline 78}"
di as res  "  SECTION 4: TABLE 1 - two-break LM test, 1870-1994"
di as txt  "{hline 78}"

tempname P1
postfile `P1' str32 country int N byte k int tb1 int tb2 ///
    double lambda1 double lambda2 double tau ///
    double cv1 double cv5 double cv10 ///
    byte rej1 byte rej5 byte rej10 ///
    byte b1sig byte b2sig ///
    double tB1 double tD1 double tB2 double tD2 ///
    using "$OUT/table1_two_break.dta", replace

foreach i of local cids {
    quietly levelsof country if cid==`i', local(cn) clean
    di as txt "  running: " as res "`cn'" _continue

    preserve
        quietly keep if cid==`i'
        quietly tsset year, yearly
        capture quietly lsmlm y, breaks(2) model(break) ///
            maxlag(`MAXLAG') mindist(`MINDIST') trim(`TRIM')
        local rc = _rc
        if `rc' == 0 {
            post `P1' ("`cn'") (r(N)) (r(k)) (r(tb1)) (r(tb2)) ///
                (r(lambda1)) (r(lambda2)) (r(tau)) ///
                (r(cv1)) (r(cv5)) (r(cv10)) ///
                (r(reject1)) (r(reject5)) (r(reject10)) ///
                (r(break1_sig10)) (r(break2_sig10)) ///
                (r(tB1)) (r(tD1)) (r(tB2)) (r(tD2))
        }
    restore

    if `rc' == 0  di as txt "  done"
    else          di as err "  FAILED (rc=`rc')"
    if `rc' != 0 {
        post `P1' ("`cn'") (.) (.) (.) (.) (.) (.) (.) (.) (.) (.) ///
            (.) (.) (.) (.) (.) (.) (.) (.) (.)
    }
}
postclose `P1'

preserve
    use "$OUT/table1_two_break.dta", clear
    gen str24 decision = cond(rej10==1, "convergence", "no convergence")
    label var decision "Unit root rejected at 10%?"
    gen str8 sig = cond(rej1==1,"1%", cond(rej5==1,"5%", cond(rej10==1,"10%","ns")))
    format tau cv1 cv5 cv10 %8.3f
    format lambda1 lambda2 %6.3f
    save "$OUT/table1_two_break.dta", replace

    di as txt _n "TABLE 1: Two-break minimum LM unit root test, 1870-1994"
    list country N k tb1 tb2 tau cv5 sig decision, noobs abbrev(12) sep(0)

    quietly count if rej10==1
    di as txt _n "  Countries rejecting the unit root at 10%: " as res r(N) as txt " of " as res _N
restore

*============================================================================
* SECTION 5  TABLE 2 - ONE-BREAK LM TEST, FULL SAMPLE
*----------------------------------------------------------------------------
* Useful as a robustness check, and as the preferred specification when the
* second break is not statistically relevant in Table 1.
*============================================================================

di as txt _n "{hline 78}"
di as res  "  SECTION 5: TABLE 2 - one-break LM test, 1870-1994"
di as txt  "{hline 78}"

tempname P2
postfile `P2' str32 country int N byte k int tb1 double lambda1 double tau ///
    double cv1 double cv5 double cv10 ///
    byte rej1 byte rej5 byte rej10 byte b1sig ///
    double tB1 double tD1 ///
    using "$OUT/table2_one_break.dta", replace

foreach i of local cids {
    quietly levelsof country if cid==`i', local(cn) clean
    di as txt "  running: " as res "`cn'" _continue

    preserve
        quietly keep if cid==`i'
        quietly tsset year, yearly
        capture quietly lsmlm y, breaks(1) model(break) maxlag(`MAXLAG') trim(`TRIM')
        local rc = _rc
        if `rc' == 0 {
            post `P2' ("`cn'") (r(N)) (r(k)) (r(tb1)) (r(lambda1)) (r(tau)) ///
                (r(cv1)) (r(cv5)) (r(cv10)) ///
                (r(reject1)) (r(reject5)) (r(reject10)) (r(break1_sig10)) ///
                (r(tB1)) (r(tD1))
        }
    restore

    if `rc' == 0  di as txt "  done"
    else          di as err "  FAILED (rc=`rc')"
    if `rc' != 0  post `P2' ("`cn'") (.) (.) (.) (.) (.) (.) (.) (.) (.) (.) (.) (.) (.) (.)
}
postclose `P2'

preserve
    use "$OUT/table2_one_break.dta", clear
    gen str24 decision = cond(rej10==1, "convergence", "no convergence")
    gen str8 sig = cond(rej1==1,"1%", cond(rej5==1,"5%", cond(rej10==1,"10%","ns")))
    format tau cv1 cv5 cv10 %8.3f
    format lambda1 %6.3f
    save "$OUT/table2_one_break.dta", replace

    di as txt _n "TABLE 2: One-break minimum LM unit root test, 1870-1994"
    list country N k tb1 tau cv5 sig decision, noobs abbrev(12) sep(0)
restore

*============================================================================
* SECTION 6  TABLE 3 - TWO-BREAK TEST ON SUB-SAMPLES
*----------------------------------------------------------------------------
* The world wars dominate the early part of the sample. Splitting the sample
* shows whether the convergence evidence is driven by the war period.
*============================================================================

di as txt _n "{hline 78}"
di as res  "  SECTION 6: TABLE 3 - sub-sample analysis"
di as txt  "{hline 78}"

tempname P3
postfile `P3' str32 country str16 sample int startyr int endyr ///
    int N byte k int tb1 int tb2 double tau ///
    double cv1 double cv5 double cv10 byte rej10 ///
    using "$OUT/table3_subsamples.dta", replace

* sample label / first year / last year / breaks / maxlag
local S1 "full 1870 1994 2"
local S2 "pre-war 1870 1945 2"
local S3 "post-war 1946 1994 1"

foreach s in "`S1'" "`S2'" "`S3'" {
    tokenize "`s'"
    local slab "`1'"
    local y0   = `2'
    local y1   = `3'
    local nbr  = `4'
    local ml   = cond("`slab'"=="full", `MAXLAG', `MAXLAG_SUB')

    di as txt _n "  --- sub-sample: `slab' (`y0'-`y1'), breaks(`nbr'), maxlag(`ml')"

    foreach i of local cids {
        quietly levelsof country if cid==`i', local(cn) clean

        preserve
            quietly keep if cid==`i' & inrange(year, `y0', `y1')
            quietly tsset year, yearly
            capture quietly lsmlm y, breaks(`nbr') model(break) ///
                maxlag(`ml') mindist(`MINDIST') trim(`TRIM')
            local rc = _rc
            if `rc' == 0 {
                local tb2v = cond(`nbr'==2, r(tb2), .)
                post `P3' ("`cn'") ("`slab'") (`y0') (`y1') ///
                    (r(N)) (r(k)) (r(tb1)) (`tb2v') (r(tau)) ///
                    (r(cv1)) (r(cv5)) (r(cv10)) (r(reject10))
            }
        restore

        if `rc' != 0 {
            di as err "     `cn': FAILED (rc=`rc')"
            post `P3' ("`cn'") ("`slab'") (`y0') (`y1') (.) (.) (.) (.) (.) (.) (.) (.) (.)
        }
    }
}
postclose `P3'

preserve
    use "$OUT/table3_subsamples.dta", clear
    gen str24 decision = cond(rej10==1, "convergence", "no convergence")
    format tau cv1 cv5 cv10 %8.3f
    save "$OUT/table3_subsamples.dta", replace

    di as txt _n "TABLE 3: Two-break LM test across sub-samples"
    sort country sample
    list country sample N k tb1 tb2 tau cv10 decision, noobs abbrev(12) sepby(country)

    di as txt _n "  Rejection counts by sub-sample (rejected at 10% / tested):"
    levelsof sample, local(samps)
    foreach s of local samps {
        quietly count if sample=="`s'" & rej10==1
        local nrej = r(N)
        quietly count if sample=="`s'" & !missing(rej10)
        di as txt "    " as res %-10s "`s'" as txt "  " as res `nrej' as txt " / " as res r(N)
    }
restore

*============================================================================
* SECTION 7  PIECEWISE TREND MODELS AT THE ESTIMATED BREAKS
*----------------------------------------------------------------------------
* Once the break dates are known, fit a deterministic trend model with level
* and slope shifts at those dates to describe HOW relative income moved.
*     y_t = a + b*t + d1*D1 + d2*D2 + g1*T1 + g2*T2 + e_t
*============================================================================

di as txt _n "{hline 78}"
di as res  "  SECTION 7: Piecewise trend models at the Table 1 breaks"
di as txt  "{hline 78}"

tempname P4
postfile `P4' str32 country int tb1 int tb2 ///
    double b_t double b_D1 double b_T1 double b_D2 double b_T2 ///
    double r2 int N ///
    using "$OUT/piecewise_trends.dta", replace

foreach i of local cids {
    quietly levelsof country if cid==`i', local(cn) clean

    * pull this country's break dates out of Table 1
    preserve
        quietly use "$OUT/table1_two_break.dta", clear
        quietly keep if country == "`cn'"
        local bk1 = tb1[1]
        local bk2 = tb2[1]
    restore

    if missing(`bk1') | missing(`bk2') {
        di as err "  `cn': no break dates in Table 1, skipped"
        continue
    }

    preserve
        quietly keep if cid==`i'
        quietly tsset year, yearly
        quietly gen double t  = year - 1869
        quietly gen double D1 = (year >  `bk1')
        quietly gen double T1 = (year - `bk1') * (year > `bk1')
        quietly gen double D2 = (year >  `bk2')
        quietly gen double T2 = (year - `bk2') * (year > `bk2')

        capture quietly regress y t D1 T1 D2 T2
        if _rc == 0 {
            post `P4' ("`cn'") (`bk1') (`bk2') ///
                (_b[t]) (_b[D1]) (_b[T1]) (_b[D2]) (_b[T2]) (e(r2)) (e(N))
            di as txt "  `cn': R2 = " as res %5.3f e(r2)
        }
        else di as err "  `cn': regression failed"
    restore
}
postclose `P4'

preserve
    use "$OUT/piecewise_trends.dta", clear
    format b_* %9.5f
    format r2 %6.3f
    di as txt _n "Piecewise trend models (breaks taken from Table 1)"
    list country tb1 tb2 b_t b_D1 b_T1 b_D2 b_T2 r2, noobs abbrev(10) sep(0)
restore

*============================================================================
* SECTION 8  FIGURES
*----------------------------------------------------------------------------
* One standalone, publication-quality figure PER COUNTRY, written to
* $OUT/figs/. Each figure shows:
*     - the observed log relative income series
*     - the fitted piecewise trend implied by the estimated break dates
*     - vertical markers at the break dates (also flagged on the x axis)
*     - a reference line at y = 0 (the OECD15 average)
*     - the test result (tau, 5% critical value, decision) in the subtitle
* Plus two cross-country summary figures.
*============================================================================

di as txt _n "{hline 78}"
di as res  "  SECTION 8: Figures"
di as txt  "{hline 78}"

capture mkdir "$OUT/figs"

* Build graphs without opening windows; graph export still works.
set graphics off

* --- shared look ------------------------------------------------------------
* Deep blue for the data, muted red for the fitted trend, grey furniture.
local C_DATA  "26 82 118"
local C_FIT   "176 58 46"
local C_BRK   "176 58 46"
local C_GRID  "gs15"
local C_SUB   "gs7"

local OPTS_REGION graphregion(color(white) lcolor(white) margin(medium)) plotregion(lcolor(none) margin(zero))
local OPTS_Y      ylabel(, angle(0) labsize(small) grid glcolor(`C_GRID') glwidth(vthin) glpattern(solid))
local OPTS_X      xlabel(1870(20)1990, labsize(small) nogrid)

foreach i of local cids {
    quietly levelsof country if cid==`i', local(cn) clean

    * reset per-iteration so a previous country's values cannot leak through
    local bk1 = .
    local bk2 = .
    local tauv = .
    local cv5v = .
    local decv ""

    * pull break dates and test results from Table 1
    preserve
        quietly use "$OUT/table1_two_break.dta", clear
        quietly keep if country == "`cn'"
        if _N > 0 {
            local bk1  = tb1[1]
            local bk2  = tb2[1]
            local tauv = tau[1]
            local cv5v = cv5[1]
            local decv = decision[1]
        }
    restore
    if missing(`bk1') {
        di as err "  `cn': no break dates, figure skipped"
        continue
    }

    local nm = subinstr("`cn'", " ", "_", .)

    * break markers (tolerate a missing second break)
    local xlines "`bk1'"
    local brklab "`bk1'"
    if !missing(`bk2') {
        local xlines "`xlines' `bk2'"
        local brklab "`brklab' and `bk2'"
    }

    * numbers for the subtitle
    local taufmt = string(`tauv', "%6.3f")
    local cvfmt  = string(`cv5v', "%6.3f")

    preserve
        quietly keep if cid==`i'
        quietly tsset year, yearly

        * fitted piecewise trend at the estimated break dates
        quietly gen double _t  = _n
        quietly gen double _D1 = (year >  `bk1')
        quietly gen double _T1 = (year - `bk1') * (year > `bk1')
        local rhs "_t _D1 _T1"
        if !missing(`bk2') {
            quietly gen double _D2 = (year >  `bk2')
            quietly gen double _T2 = (year - `bk2') * (year > `bk2')
            local rhs "`rhs' _D2 _T2"
        }
        capture quietly regress y `rhs'
        if _rc == 0 {
            quietly predict double _yhat, xb
            local fitline (line _yhat year, lcolor("`C_FIT'") lwidth(medthick) lpattern(dash))
            local leg legend(order(1 "Observed" 2 "Piecewise trend at estimated breaks") ///
                       rows(1) size(vsmall) region(lstyle(none) color(none)) position(6) bmargin(zero))
        }
        else {
            local fitline ""
            local leg legend(off)
        }

        twoway (line y year, lcolor("`C_DATA'") lwidth(medthick)) ///
               `fitline' ///
            , xline(`xlines', lpattern(shortdash) lcolor("`C_BRK'") lwidth(thin)) ///
              yline(0, lcolor(gs11) lwidth(vthin) lpattern(solid)) ///
              xmlabel(`xlines', labcolor("`C_BRK'") labsize(vsmall) tlcolor("`C_BRK'")) ///
              title("`cn'", size(medlarge) color(black) position(11) justification(left)) ///
              subtitle("Two-break LM: {&tau} = `taufmt', 5% CV = `cvfmt'  -  `decv'", ///
                       size(small) color(`C_SUB') position(11) justification(left)) ///
              ytitle("Log relative per-capita income", size(small) margin(medium)) ///
              xtitle("") ///
              `OPTS_Y' `OPTS_X' ///
              note("Vertical lines: estimated breaks (`brklab'). Horizontal line: OECD15 average (y = 0)." ///
                   "Data: Maddison Project Database 2023.", size(vsmall) color(gs9) span) ///
              `OPTS_REGION' `leg' ///
              xsize(8) ysize(5)

        graph export "$OUT/figs/fig_`nm'.png", replace width(2400)
        di as txt "  saved: figs/fig_`nm'.png"
    restore
}

*--- Summary figure 1: tau vs 5% critical value, all countries ---------------
preserve
    use "$OUT/table1_two_break.dta", clear
    quietly drop if missing(tau)
    if _N >= 2 {
        gsort -tau
        gen int pos = _n

        * y-axis labels: one country name per row
        local ylab ""
        forvalues r = 1/`=_N' {
            local cnm = country[`r']
            local ylab `"`ylab' `r' "`cnm'""'
        }

        twoway (rspike tau cv5 pos, horizontal lcolor(gs13) lwidth(medium)) ///
               (scatter pos tau, msymbol(O) mcolor("26 82 118") msize(medium)) ///
               (scatter pos cv5, msymbol(pipe) mcolor("176 58 46") msize(large)) ///
            , ylabel(`ylab', angle(0) labsize(small) nogrid) ///
              yscale(reverse) ///
              xlabel(, labsize(small) grid glcolor(gs15) glwidth(vthin)) ///
              ytitle("") xtitle("Test statistic", size(small) margin(medium)) ///
              title("Two-break LM test results", size(medlarge) color(black) position(11) justification(left)) ///
              subtitle("Unit root is rejected when {&tau} lies to the left of the 5% critical value", ///
                       size(small) color(gs7) position(11) justification(left)) ///
              legend(order(2 "{&tau} (test statistic)" 3 "5% critical value") ///
                     rows(1) size(vsmall) region(lstyle(none) color(none)) position(6) bmargin(zero)) ///
              graphregion(color(white) lcolor(white) margin(medium)) ///
              plotregion(lcolor(none)) ///
              xsize(8) ysize(6)
        graph export "$OUT/figs/fig_summary_test_results.png", replace width(2400)
        di as txt "  saved: figs/fig_summary_test_results.png"
    }
restore

*--- Summary figure 2: timing of the estimated breaks ------------------------
preserve
    use "$OUT/table1_two_break.dta", clear
    quietly drop if missing(tb1)
    if _N >= 2 {
        gsort tb1
        gen int pos = _n
        local ylab ""
        forvalues r = 1/`=_N' {
            local cnm = country[`r']
            local ylab `"`ylab' `r' "`cnm'""'
        }

        twoway (rspike tb1 tb2 pos, horizontal lcolor(gs13) lwidth(medium)) ///
               (scatter pos tb1, msymbol(O) mcolor("26 82 118") msize(medium)) ///
               (scatter pos tb2, msymbol(D) mcolor("176 58 46") msize(medium)) ///
            , ylabel(`ylab', angle(0) labsize(small) nogrid) ///
              yscale(reverse) ///
              xlabel(1870(20)1990, labsize(small) grid glcolor(gs15) glwidth(vthin)) ///
              ytitle("") xtitle("") ///
              title("Timing of the estimated structural breaks", size(medlarge) color(black) position(11) justification(left)) ///
              subtitle("Each line spans a country's two estimated break dates", ///
                       size(small) color(gs7) position(11) justification(left)) ///
              legend(order(2 "First break" 3 "Second break") ///
                     rows(1) size(vsmall) region(lstyle(none) color(none)) position(6) bmargin(zero)) ///
              graphregion(color(white) lcolor(white) margin(medium)) ///
              plotregion(lcolor(none)) ///
              xsize(8) ysize(6)
        graph export "$OUT/figs/fig_summary_break_timing.png", replace width(2400)
        di as txt "  saved: figs/fig_summary_break_timing.png"
    }
restore

set graphics on

di as txt _n "  All figures written to: " as res "$OUT/figs"

*============================================================================
* SECTION 9  EXCEL WORKBOOK
*============================================================================

di as txt _n "{hline 78}"
di as res  "  SECTION 9: Excel export"
di as txt  "{hline 78}"

local XLS "$OUT/lsmlm_oecd15_results.xlsx"

preserve
    use "$OUT/desc_stats.dta", clear
    export excel using "`XLS'", sheet("Descriptives") firstrow(variables) replace
restore
preserve
    use "$OUT/table1_two_break.dta", clear
    export excel using "`XLS'", sheet("Table1_TwoBreak") firstrow(variables) sheetmodify
restore
preserve
    use "$OUT/table2_one_break.dta", clear
    export excel using "`XLS'", sheet("Table2_OneBreak") firstrow(variables) sheetmodify
restore
preserve
    use "$OUT/table3_subsamples.dta", clear
    export excel using "`XLS'", sheet("Table3_Subsamples") firstrow(variables) sheetmodify
restore
preserve
    use "$OUT/piecewise_trends.dta", clear
    export excel using "`XLS'", sheet("PiecewiseTrends") firstrow(variables) sheetmodify
restore

di as txt "  saved: `XLS'"

timer off 1
quietly timer list 1
di as txt _n "{hline 78}"
di as res  "  FINISHED"
di as txt  "{hline 78}"
di as txt "  Elapsed time: " as res %8.1f r(t1) as txt " seconds"
di as txt "  Output folder: " as res "$OUT"
if `QUICK' {
    di as txt _n as err "  NOTE: this was a QUICK run (3 countries, maxlag `MAXLAG')."
    di as err  "        Set  local QUICK = 0  near the top for the full analysis."
}

log close main

exit
