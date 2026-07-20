*! regbreak_example.do  -- self-test / demonstration for regbreak
*! Dr Merwan Roudane  (merwanroudane920@gmail.com)
*
* Simulates a linear series with KNOWN coefficient breaks and a KNOWN variance
* break, then checks that regbreak recovers them in both modes.  Run with:
*     do regbreak_example.do
clear
set more off
set seed 20260719

* ---------------------------------------------------------------------------
* Data-generating process
*   mean:  1.0 (t<=60),  4.0 (61<=t<=110),  -1.0 (t>110)   -> 2 coefficient breaks
*   sd  :  1.0 (t<=90),  3.0 (t>90)                          -> 1 variance break
* ---------------------------------------------------------------------------
local T = 180
set obs `T'
gen t = _n
gen double mu = cond(t<=60, 1.0, cond(t<=110, 4.0, -1.0))
gen double sd = cond(t<=90, 1.0, 3.0)
gen double y  = mu + sd*rnormal()
tsset t

di as txt _n(2) "{hline 70}"
di as txt "TRUE coefficient breaks at t = 60 and 110; variance break at t = 90"
di as txt "{hline 70}"

* ---------------------------------------------------------------------------
* 1) Bai-Perron coefficient-break analysis (default)
* ---------------------------------------------------------------------------
di as txt _n "### 1. Bai-Perron mode ###"
regbreak y, trim(0.15) maxb(5)
matrix D = e(date)
di as txt "Recovered break dates (expect near 60 and 110):"
matrix list D

* estimated model with a plot
regbreak y, trim(0.15) fixn(2) graph gname(rb_demo)

* ---------------------------------------------------------------------------
* 2) Joint variance + coefficient tests
* ---------------------------------------------------------------------------
di as txt _n "### 2. Joint (Perron-Yamamoto-Zhou) mode ###"
regbreak y, joint trim(0.10) maxb(3) maxv(2)
di as txt "e(mcoef) coefficient breaks = " e(mcoef) ///
          "   e(nvar) variance breaks = " e(nvar)

di as txt _n "{hline 70}"
di as txt "Done.  Coefficient breaks should be recovered near 60 and 110,"
di as txt "and the joint procedure should also detect the variance break near 90."
di as txt "{hline 70}"
