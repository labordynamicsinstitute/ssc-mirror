/****************************************************************************
  lsmlm_example.do  --  how to use the lsmlm command
  --------------------------------------------------------------------------
  INSTALL FIRST:
  Put lsmlm.ado and lsmlm.sthlp where Stata can find them, e.g. in your
  PERSONAL ado folder (type  -personal-  to see the path), or in the folder
  you run this from. Then, to (re)load a freshly edited version:
        discard
  Check the help with:
        help lsmlm
****************************************************************************/

clear all
set more off
set seed 12345

********************************************************************************
* 1. A SINGLE TIME SERIES  (any variable, any time unit)
********************************************************************************

* Build an illustrative annual series 1880-2019: a drifting random walk with a
* trend break around 1945. (Only to show the command runs and returns values.)
set obs 140
gen int year = 1880 + _n - 1

gen double e = rnormal()
gen double y = .
replace y = e                                   in 1
replace y = y[_n-1] + 0.02 + e                  in 2/l
replace y = y + 0.03*(year-1945)*(year>1945)

tsset year, yearly

* One break, trend-break model:
lsmlm y, breaks(1)

* Two breaks:
lsmlm y, breaks(2)

* Restrict the time range with -if- (post-1945 sub-sample):
lsmlm y if inrange(year,1946,2019), breaks(1)

* Annual-data settings (8 lags, minimum gap of 5 obs between breaks):
lsmlm y, breaks(2) maxlag(8) mindist(5) trim(0.10)

* No break (Schmidt-Phillips baseline):
lsmlm y, breaks(0)

* Crash model (level shifts only) instead of the trend-break model:
lsmlm y, breaks(1) model(crash)
lsmlm y, breaks(2) model(crash)

* Grab the returned results after a run:
lsmlm y, breaks(2)
display as text "tau = "      as result r(tau)
display as text "break 1 = "  as result r(tb1)   as text "   break 2 = " as result r(tb2)
display as text "5% CV = "    as result r(cv5)
display as text "reject unit root at 10%? " as result r(reject10)


********************************************************************************
* 2. LOOPING OVER PANEL UNITS  (one series per call)
********************************************************************************
* lsmlm works on a single series, so restrict to one unit at a time. The
* template below mirrors a Table-1-style workflow and collects results with
* -postfile-. Uncomment and adapt to your own data.
*
*   use "yourdata.dta", clear
*   xtset id year
*
*   tempname P
*   postfile `P' ///
*       int id int N int k int tb1 int tb2 double lambda1 double lambda2 ///
*       double tau double cv1 double cv5 double cv10 byte reject10 ///
*       using "lsmlm_results.dta", replace
*
*   levelsof id, local(ids)
*   foreach i of local ids {
*       preserve
*           keep if id == `i'
*           tsset year
*           quietly lsmlm y, breaks(2) maxlag(8) mindist(5) trim(0.10)
*           post `P' (`i') (r(N)) (r(k)) (r(tb1)) (r(tb2)) ///
*               (r(lambda1)) (r(lambda2)) (r(tau)) ///
*               (r(cv1)) (r(cv5)) (r(cv10)) (r(reject10))
*       restore
*   }
*   postclose `P'
*
*   use "lsmlm_results.dta", clear
*   gen str40 decision = cond(reject10==1, "reject unit root", "do not reject")
*   list, noobs sep(0)
*   export excel using "lsmlm_results.xlsx", firstrow(variables) replace

exit
