*! ffrroot_example.do - Demonstration of all Fourier unit root tests
*! Package: ffrroot v1.0
*! Author: Dr. Merwan Roudane
*! Date: 11 March 2026

clear all
set more off

* ==============================================================================
*  1. Setup: Load and prepare data
* ==============================================================================

sysuse gnp96, clear
tsset date

di _n "{hline 70}"
di "  ffrroot: Flexible Fourier Form Unit Root Tests"
di "  Demonstration using US GNP data (1967q1-2002q2)"
di "{hline 70}" _n


* ==============================================================================
*  2. Fourier LM Test (Enders & Lee, 2012a)
* ==============================================================================

di _n "TEST 1: Fourier LM Test" _n

* Default options (kmax=5, ic=t-stat)
fourierlm gnp96

* With AIC lag selection and graph
fourierlm gnp96, ic(1) graph

* Return stored results
return list


* ==============================================================================
*  3. Fourier ADF Test (Enders & Lee, 2012b)
* ==============================================================================

di _n "TEST 2: Fourier ADF Test" _n

* Default: constant + trend (model=2)
fourierdf gnp96

* Constant only
fourierdf gnp96, notrend

* With graph
fourierdf gnp96, graph

return list


* ==============================================================================
*  4. Fourier GLS Test (Rodrigues & Taylor, 2012)
* ==============================================================================

di _n "TEST 3: Fourier GLS Test" _n

* Default (c_bar = -22 for model 2)
fouriergls gnp96

* Constant only (c_bar = -7)
fouriergls gnp96, notrend graph

return list


* ==============================================================================
*  5. Fourier KPSS Stationarity Test (Becker, Enders & Lee, 2006)
* ==============================================================================

di _n "TEST 4: Fourier KPSS Test" _n

* Note: KPSS has REVERSED null hypothesis (H0: stationarity)
fourierkpss gnp96
fourierkpss gnp96, graph

return list


* ==============================================================================
*  6. FFFFF-DF Test with Fractional Frequencies (Omay, 2015)
* ==============================================================================

di _n "TEST 5: Fractional Frequency Flexible Fourier Form (FFFFF) DF Test" _n

* Default grid: k_fr = 0.1, 0.2, ..., 2.0
fourierfffff gnp96

* Finer grid and extended range
fourierfffff gnp96, kfstep(0.05) kfmax(3) graph

return list


* ==============================================================================
*  7. Double Frequency Fourier DF Test (Cai & Omay, 2021)
* ==============================================================================

di _n "TEST 6: Double Frequency Fourier DF (DFDF) Test" _n

* Integer frequencies (dk=1): baseline
fourierdfdf gnp96

* Fractional frequencies (dk=0.1): maximum power
fourierdfdf gnp96, dk(0.1) graph

* With Sieve Bootstrap critical values (Gerolimetto & Magrini, 2026)
* Note: This takes about 30-60 seconds
fourierdfdf gnp96, dk(0.1) bootstrap breps(500) graph

return list


* ==============================================================================
*  8. Run all tests at once with fourierall
* ==============================================================================

di _n "ALL TESTS: Running all Fourier unit root tests" _n

fourierall gnp96

* With graphs from all tests
fourierall gnp96, graph


* ==============================================================================
*  9. Interpretation Guide
* ==============================================================================

di _n "{hline 70}"
di "  INTERPRETATION GUIDE"
di "{hline 70}"
di ""
di "  For tests 1-3, 5-6 (unit root tests):"
di "    H0: unit root.  Reject if test stat < critical value (left-tail)."
di ""
di "  For test 4 (KPSS):"
di "    H0: stationarity.  Reject if test stat > critical value (right-tail)."
di ""
di "  Confirmatory strategy:"
di "    - UR tests fail to reject + KPSS rejects => evidence of unit root"
di "    - UR tests reject + KPSS fails to reject => evidence of stationarity"
di ""
di "  Always check the F-test for Fourier terms. If not significant,"
di "  use standard (non-Fourier) unit root tests instead."
di "{hline 70}"


* ==============================================================================
*  End of example
* ==============================================================================

di _n "Example completed successfully." _n
