*! xtkpybreak_example.do  -- worked examples for xtkpybreak
*! Dr Merwan Roudane (merwanroudane920@gmail.com)
*
* Two parts:
*   A) Real data (Grunfeld investment panel, ships with Stata) -- shows syntax
*      and the journal-style tables/plots on genuine data.
*   B) A controlled BFW (2025) data-generating process with KNOWN break dates
*      and slopes, to show that xtkpybreak recovers them.
*
* Run:  do xtkpybreak_example.do
* (xtkpybreak must be installed, e.g. net install xtkpybreak, from(<folder>) )

clear all
set more off

*==================================================================
* A. REAL DATA -- Grunfeld investment panel (N=10 firms, T=20 years)
*==================================================================
webuse grunfeld, clear
xtset company year

* --- CCE (KPY 2011), robust to I(1) common factors ---
xtkpybreak cce invest mvalue kstock
xtkpybreak cce invest mvalue kstock, proxy(x) estimator(pooled)

* postestimation works (e-class):
test mvalue kstock

* built-in plots
xtkpybreak cce invest mvalue kstock, coefplot factorplot name(g_cce)

* --- One structural break in the slopes (BFW 2025, model 4) ---
xtkpybreak break invest mvalue kstock, nbreaks(1) breakplot coefevolution name(g_brk)
matrix list e(breakdates)

* test whether the mvalue slope changed across the break
test [r1]mvalue = [r2]mvalue

* individual-panel slopes with Newey-West s.e. (BFW Prop.1, eqs 17-18)
xtkpybreak break invest mvalue kstock, nbreaks(1) hac(2)
matrix list e(b_i)
matrix list e(se_i)

* strict BFW eq.(9) proxy: cross-section averages only, no intercept
xtkpybreak break invest mvalue kstock, nbreaks(1) noconstant

* combine the four graphs into one journal-style figure
capture graph combine g_cce_coef g_cce_factor g_brk_break g_brk_evo, ///
        cols(2) title("xtkpybreak: Grunfeld panel") ///
        graphregion(color(white)) name(dashboard, replace)

*==================================================================
* B. SIMULATED BFW DGP -- known breaks, to verify recovery
*    y_it = b_i(k) x_it + g_i f_t + e_it,  f_t ~ I(1)
*    slope break at t = 0.4T ; T=60, N=40
*==================================================================
clear
set seed 20260709
local N = 40
local T = 60

* common I(1) factor
set obs `T'
gen t = _n
gen f = .
replace f = rnormal() in 1
replace f = f[_n-1] + rnormal() if _n>1
tempfile fac
save `fac'

* panel
clear
set obs `N'
gen id = _n
gen g  = rnormal(1,0.5)       // heterogeneous loading
gen b  = rnormal(1,0.10)      // pre-break slope, mean 1
gen db = rnormal(2,0.30)      // slope jump, mean +2  -> post-break mean ~3
expand `T'
bysort id: gen t = _n
merge m:1 t using `fac', nogen

gen v = rnormal()
gen x = 0.5*f + v             // regressor loads on the factor
local k1 = round(0.4*`T')     // TRUE break at t = 24
gen slope = b
replace slope = b + db if t > `k1'
gen y = slope*x + g*f + rnormal()
xtset id t

di as txt "TRUE break at t = `k1'; TRUE mean slope: regime1 ~ 1, regime2 ~ 3"
xtkpybreak break y x, nbreaks(1) coefevolution name(g_sim)
matrix list e(breakdates)
matrix list e(b_regime)

di as result _n "==== xtkpybreak_example.do complete ===="
