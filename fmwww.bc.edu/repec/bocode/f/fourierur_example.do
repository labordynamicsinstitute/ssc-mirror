*! fourierur_example.do - Demonstration of the fourierur main command
*! Package: fourierur v1.0
*! Author: Dr. Merwan Roudane
*! Date: 21 May 2026

clear all
set more off

* ==============================================================================
*  1. Setup: load and prepare data
* ==============================================================================

sysuse gnp96, clear
tsset date

di _n "{hline 70}"
di "  fourierur: Flexible Fourier Form Unit Root Tests"
di "  Demonstration using US GNP data (1967q1-2002q2)"
di "{hline 70}" _n


* ==============================================================================
*  2. The main command: fourierur
*
*     Syntax: fourierur varname [if] [in], test(name) [other options]
*
*     test() chooses ONE of:  lm | df | gls | kpss | fffff | dfdf | all
*     Default is test(all).
* ==============================================================================


* ------------------------------------------------------------------------------
*  Option A. Run a SINGLE test
* ------------------------------------------------------------------------------

di _n "TEST 1: Fourier LM (Enders & Lee, 2012a)" _n
fourierur gnp96, test(lm)
fourierur gnp96, test(lm) ic(1) graph
return list

di _n "TEST 2: Fourier ADF (Enders & Lee, 2012b)" _n
fourierur gnp96, test(df)
fourierur gnp96, test(df) notrend
fourierur gnp96, test(df) graph
return list

di _n "TEST 3: Fourier GLS (Rodrigues & Taylor, 2012)" _n
fourierur gnp96, test(gls)
fourierur gnp96, test(gls) notrend graph
return list

di _n "TEST 4: Fourier KPSS (Becker, Enders & Lee, 2006)" _n
* Note: KPSS has REVERSED null hypothesis (H0: stationarity)
fourierur gnp96, test(kpss)
fourierur gnp96, test(kpss) graph
return list

di _n "TEST 5: Fractional-frequency FFFFF-DF (Omay, 2015)" _n
fourierur gnp96, test(fffff)
fourierur gnp96, test(fffff) kfstep(0.05) kfmax(3) graph
return list

di _n "TEST 6: Double Frequency Fourier DF (Cai & Omay, 2021)" _n
fourierur gnp96, test(dfdf)
fourierur gnp96, test(dfdf) dk(0.1) graph
* With sieve-bootstrap critical values (Gerolimetto & Magrini, 2026).
* Note: this takes ~30-60 seconds.
fourierur gnp96, test(dfdf) dk(0.1) bootstrap breps(500) graph
return list


* ------------------------------------------------------------------------------
*  Option B. Run ALL tests at once
* ------------------------------------------------------------------------------

di _n "ALL TESTS: run every Fourier unit-root / stationarity test" _n
fourierur gnp96
fourierur gnp96, test(all) graph
fourierur gnp96, test(all) notrend


* ==============================================================================
*  3. Interpretation guide
* ==============================================================================

di _n "{hline 70}"
di "  INTERPRETATION GUIDE"
di "{hline 70}"
di ""
di "  Unit-root tests (lm, df, gls, fffff, dfdf):"
di "    H0: unit root.  Reject if test stat < critical value (left-tail)."
di ""
di "  Stationarity test (kpss):"
di "    H0: stationarity.  Reject if test stat > critical value (right-tail)."
di ""
di "  Confirmatory strategy:"
di "    - UR tests fail to reject + KPSS rejects => evidence of unit root"
di "    - UR tests reject + KPSS fails to reject => evidence of stationarity"
di ""
di "  Always check the F-test for Fourier terms. If not significant,"
di "  prefer standard (non-Fourier) unit root tests."
di "{hline 70}"


* ==============================================================================
*  End of example
* ==============================================================================

di _n "Example completed successfully." _n
