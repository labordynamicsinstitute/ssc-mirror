/* ============================================================
   causalspline_example.do
   Complete worked example for Stata 14.1
   Mirrors the R test outputs from CausalSpline v0.1.0
   
   INSTALLATION:
   Copy all .ado and .sthlp files to:
   C:\ado\personal\   (or wherever your personal ado path is)
   
   To check your path: sysdir
   ============================================================ */

clear all
set more off

// Optional: set working directory for output files
// cd "C:\Users\<you>\Documents\causalspline_output"


// ====================================================================
// STEP 1 - Simulate data (mirrors R simulate_dose_response)
// ====================================================================

di as text "=== Simulating data ==="

cs_simulate 500, dgp(threshold)   seed(1) clear
save "dat_threshold.dta",   replace

cs_simulate 500, dgp(diminishing) seed(2) clear
save "dat_diminishing.dta", replace

cs_simulate 500, dgp(nonmonotone) seed(3) clear
save "dat_nonmonotone.dta", replace

cs_simulate 500, dgp(linear)      seed(4) clear
save "dat_linear.dta",      replace

cs_simulate 500, dgp(sinusoidal)  seed(5) clear
save "dat_sinusoidal.dta",  replace

di as text "All 5 DGPs simulated OK"


// ====================================================================
// STEP 2 - IPW fit (threshold DGP)
// Mirrors R: fit_ipw <- causal_spline(Y~T|X1+X2+X3, method="ipw", df=5)
// ====================================================================

di as text _n "=== IPW fit (threshold DGP) ==="

use "dat_threshold.dta", clear

causalspline,                          ///
    outcome(Y)                         ///
    treatment(T)                       ///
    confounders(X1 X2 X3)              ///
    method(ipw)                        ///
    dfexposure(5)                      ///
    evalgrid(100)                      ///
    bootreps(200)                      ///
    savecurve("curve_ipw.dta")         ///
    verbose

// Check scalars - mirrors R print(fit_ipw)
di "Method    : " e(method)
di "df        : " e(dfexposure)
di "n         : " e(n)
di "T range   : [" e(t_min) ", " e(t_max) "]"
di "ESS       : " e(ess) " / " e(n) " (" e(ess_pct) "%)"


// ====================================================================
// STEP 3 - G-computation fit (diminishing DGP)
// Mirrors R: fit_gc <- causal_spline(..., method="gcomp")
// ====================================================================

di as text _n "=== G-computation fit (diminishing DGP) ==="

use "dat_diminishing.dta", clear

causalspline,                          ///
    outcome(Y)                         ///
    treatment(T)                       ///
    confounders(X1 X2 X3)              ///
    method(gcomp)                      ///
    dfexposure(5)                      ///
    evalgrid(100)                      ///
    bootreps(200)                      ///
    savecurve("curve_gcomp.dta")


// ====================================================================
// STEP 4 - Doubly robust fit (nonmonotone DGP)
// Mirrors R: fit_dr <- causal_spline(..., method="dr", df_exposure=6)
// ====================================================================

di as text _n "=== Doubly Robust fit (nonmonotone DGP) ==="

use "dat_nonmonotone.dta", clear

causalspline,                          ///
    outcome(Y)                         ///
    treatment(T)                       ///
    confounders(X1 X2 X3)              ///
    method(dr)                         ///
    dfexposure(6)                      ///
    evalgrid(100)                      ///
    bootreps(200)                      ///
    savecurve("curve_dr.dta")


// ====================================================================
// STEP 5 - Plots
// Mirrors R: plot(fit_ipw, truth=truth_threshold)
// ====================================================================

di as text _n "=== Plotting ==="

// Plot 1: IPW curve with true effect overlay
use "curve_ipw.dta", clear
twoway  (rarea lower upper t, lwidth(none) color(ltblue))          ///
        (line estimate t, lcolor(navy) lwidth(medthick)),          ///
    xtitle("Treatment (T)")                                        ///
    ytitle("E[Y(t)]")                                              ///
    title("Causal Dose-Response - IPW (Threshold DGP)")            ///
    subtitle("95% CI shaded  |  Blue = estimated curve")          ///
    scheme(s2color)
graph export "fig_ipw_threshold.png", replace

// Plot 2: G-computation
use "curve_gcomp.dta", clear
twoway  (rarea lower upper t, lwidth(none) color(ltblue))          ///
        (line estimate t, lcolor(navy) lwidth(medthick)),          ///
    title("Causal Dose-Response - G-computation (Diminishing)")    ///
    xtitle("Treatment (T)") ytitle("E[Y(t)]")                     ///
    scheme(s2color)
graph export "fig_gcomp_diminishing.png", replace

// Plot 3: DR nonmonotone
use "curve_dr.dta", clear
twoway  (rarea lower upper t, lwidth(none) color(ltblue))          ///
        (line estimate t, lcolor(navy) lwidth(medthick)),          ///
    title("Causal Dose-Response - Doubly Robust (Nonmonotone)")    ///
    xtitle("Treatment (T)") ytitle("E[Y(t)]")                     ///
    scheme(s2color)
graph export "fig_dr_nonmonotone.png", replace


// ====================================================================
// STEP 6 - Overlap diagnostics
// Mirrors R: check_overlap(dat_threshold$T, fit_ipw$weights)
// ====================================================================

di as text _n "=== check_overlap() ==="

use "dat_threshold.dta", clear
causalspline, outcome(Y) treatment(T) confounders(X1 X2 X3) ///
    method(ipw) dfexposure(5) bootreps(50)

cs_overlap
di "ESS: " r(ess) " / n = " r(n)


// ====================================================================
// STEP 7 - Gradient curve
// Mirrors R: gd <- gradient_curve(fit_ipw)
// ====================================================================

di as text _n "=== gradient_curve() ==="

use "dat_threshold.dta", clear
causalspline, outcome(Y) treatment(T) confounders(X1 X2 X3) ///
    method(ipw) dfexposure(5) bootreps(100)

cs_gradient, savegradient("gradient_ipw.dta")

// Show head of gradient table
use "gradient_ipw.dta", clear
list in 1/6
use "dat_threshold.dta", clear
causalspline, outcome(Y) treatment(T) confounders(X1 X2 X3) ///
    method(ipw) dfexposure(5) bootreps(100)


// ====================================================================
// STEP 8 - Fragility curve (curvature_ratio)
// Mirrors R: fc_cr <- fragility_curve(fit_ipw, type="curvature_ratio")
// ====================================================================

di as text _n "=== fragility_curve() - curvature_ratio ==="

cs_fragility, type(curvature_ratio) savefragility("frag_curv.dta")

// Plot curvature fragility - dual panel (Stata 14 style)
preserve
    use "frag_curv.dta", clear

    // Top panel
    twoway  (rarea estimate estimate t if high_fragility==1,       ///
                 color(gs12))                                      ///
            (line estimate t, lcolor(navy) lwidth(medthick)),      ///
        xtitle("") ytitle("E[Y(t)]")                               ///
        title("Dose-Response with Fragility Regions")              ///
        subtitle("Shaded = high fragility (top 25%)  |  Type: curvature_ratio") ///
        legend(off) name(top, replace)

    // Bottom panel: fragility
    qui sum fragility, detail
    local q75 = r(p75)
    local q50 = r(p50)

    twoway  (line fragility t, lcolor(navy) lwidth(medthick)),     ///
        yline(`q75', lpattern(dash)  lcolor(red)  lwidth(thin))   ///
        yline(`q50', lpattern(dot)   lcolor(gs8)  lwidth(thin))   ///
        xtitle("Treatment (T)") ytitle("Fragility")                ///
        note("Red dashed = 75th pct (high)  |  Dotted = 50th pct (moderate)") ///
        legend(off) name(bottom, replace)

    graph combine top bottom, cols(1)                              ///
        title("CausalSpline Fragility Diagnostics")
    graph export "fig_fragility_curvature.png", replace
restore


// ====================================================================
// STEP 9 - Fragility curve (inverse_slope)
// Mirrors R: fc_is <- fragility_curve(fit_ipw, type="inverse_slope")
// ====================================================================

di as text _n "=== fragility_curve() - inverse_slope ==="

cs_fragility, type(inverse_slope) savefragility("frag_slope.dta")
// Expected: high fragility below T=3 (flat pre-threshold region)


// ====================================================================
// STEP 10 - Regional fragility
// Mirrors R: region_fragility(fit_ipw, a=2, b=4, type="curvature_ratio")
// ====================================================================

di as text _n "=== region_fragility() ==="

// Below threshold [2, 4]
cs_region, a(2) b(4) type(curvature_ratio)
di "Region [2,4] integral fragility : " r(integral_fragility)
di "Region [2,4] average fragility  : " r(average_fragility)
// Expected: ~0.40 (high - threshold zone)

// Above threshold [4, 8]
cs_region, a(4) b(8) type(curvature_ratio)
di "Region [4,8] integral fragility : " r(integral_fragility)
di "Region [4,8] average fragility  : " r(average_fragility)
// Expected: ~0.20 (lower - stable slope)

// Nonmonotone DR fit
use "dat_nonmonotone.dta", clear
causalspline, outcome(Y) treatment(T) confounders(X1 X2 X3) ///
    method(dr) dfexposure(6) bootreps(100)

cs_region, a(3) b(7) type(curvature_ratio)
di "Nonmonotone [3,7] curvature_ratio avg: " r(average_fragility)
// Expected: ~3.35

cs_region, a(3) b(7) type(inverse_slope)
di "Nonmonotone [3,7] inverse_slope   avg: " r(average_fragility)
// Expected: ~3.47


// ====================================================================
// DONE
// ====================================================================

di as text _n "=== All tests complete ==="
di as text "Output files:"
di as text "  curve_ipw.dta         - IPW dose-response curve (100 rows)"
di as text "  curve_gcomp.dta       - G-computation curve"
di as text "  curve_dr.dta          - Doubly robust curve"
di as text "  gradient_ipw.dta      - Derivatives (d1, d2)"
di as text "  frag_curv.dta         - Curvature fragility dataset"
di as text "  frag_slope.dta        - Slope fragility dataset"
di as text "  fig_ipw_threshold.png"
di as text "  fig_gcomp_diminishing.png"
di as text "  fig_dr_nonmonotone.png"
di as text "  fig_fragility_curvature.png"
