// ====================================================================
// xtqrplot_example.do  --  v1.3.0
// Demonstrates xtqrplot with a simulated 10-country, 10-year panel.
// x2 is generated as chi-squared(2) -- strongly right-skewed and
// non-normal -- so that quantile effects vary substantially across
// the distribution, making the heat plot more informative.
// ====================================================================

version 14.0
clear all
set more off

// ssc install xtqreg    // run once if needed
// ssc install qregpd    // run once if needed

// ------------------------------------------------------------------
// SIMULATE DATA
//   y  ~ heterogeneous in both x1 and x2 effects across quantiles
//   x1 ~ N(2,1)          -- approximately normal
//   x2 ~ chi2(2) - 2     -- strongly right-skewed, mean-centred
//        This creates large quantile heterogeneity: the effect of x2
//        on y is much stronger at higher quantiles because extreme
//        values of x2 drive extreme values of y.
// ------------------------------------------------------------------
set seed 2024
set obs 100

gen country_id = ceil(_n / 10)
gen year       = mod(_n - 1, 10) + 2010

// x1: approximately normal
gen x1 = rnormal(2, 1)

// x2: chi-squared(2) minus 2 -- skewed, mean zero
// chi2(2) = -2*ln(U1)*cos(2*pi*U2) type, simplest: sum of 2 exponentials
gen u1 = runiform()
gen u2 = runiform()
gen x2 = -ln(u1) - ln(u2) - 2    // chi2(2) - 2, right skewed
drop u1 u2

// Country fixed effects -- heterogeneous
gen fe = rnormal(0, 0.8)
bysort country_id: replace fe = fe[1]

// y: effect of x1 is moderate and roughly uniform across quantiles
//    effect of x2 is small at low quantiles, large at high quantiles
//    (heteroskedastic in x2 -- perfect for quantile regression)
gen eps = rnormal(0, 1) * (1 + 0.5 * abs(x2))
gen y = 1 + 0.4*x1 + 0.3*x2 + fe + eps

// Labels
label define clab 1 "Argentina" 2 "Brazil"   3 "Chile"    ///
                  4 "Colombia"  5 "Ecuador"   6 "Mexico"   ///
                  7 "Panama"    8 "Peru"       9 "Uruguay"  ///
                  10 "Venezuela"
label values country_id clab
label variable y  "GDP Growth"
label variable x1 "Trade Openness (normal)"
label variable x2 "Investment Shock (skewed)"

xtset country_id year

// Describe distributions
di _n "=== Summary statistics ==="
summarize y x1 x2

// ------------------------------------------------------------------
// EXAMPLE 1: Default cross-section plot
// ------------------------------------------------------------------
di _n "=== Example 1: Cross-section (default) ==="
xtqrplot y x1 x2, panelvar(country_id) timevar(year)

// ------------------------------------------------------------------
// EXAMPLE 2: Semi-elasticity, time plot
// ------------------------------------------------------------------
di _n "=== Example 2: Time-dimension, semi-elasticity ==="
xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    plottype(time) effect(semi) nonormal

// ------------------------------------------------------------------
// EXAMPLE 3: Twoway heat map -- observe x2 variation across quantiles
// ------------------------------------------------------------------
di _n "=== Example 3: Twoway heat map ==="
xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    plottype(twoway) nonormal

// ------------------------------------------------------------------
// EXAMPLE 4: Basis points, finer grid
// ------------------------------------------------------------------
di _n "=== Example 4: Basis points, 19 windows ==="
xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    effect(bp) nwindows(19) nonormal

// ------------------------------------------------------------------
// EXAMPLE 5: Save results
// ------------------------------------------------------------------
di _n "=== Example 5: Save output ==="
capture mkdir results
xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    saving(results/demo) replace nonormal

di _n "Done. Check results/ folder for saved files."
