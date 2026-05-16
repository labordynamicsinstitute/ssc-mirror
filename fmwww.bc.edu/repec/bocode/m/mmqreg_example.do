*! mmqreg_example.do
*! Example do-file for mmqreg v2.4 + mmqregplot v2.0
*! Authors: Fernando Rios-Avila (original); Dr Merwan Roudane (v2.4)

clear all
set more off

*--------------------------------------------------------------
* Install dependencies (run once)
*--------------------------------------------------------------
* ssc install ftools
* ssc install hdfe

*--------------------------------------------------------------
* Load data
*--------------------------------------------------------------
webuse nlswork, clear
xtset idcode year

* Keep balanced-ish panel for JK demonstration
by idcode: egen c = count(idcode)
keep if c >= 10
gen s = 2*((year/2) - int(year/2))       // 0=even, 1=odd  (for JK)

display "N = " _N " observations"

*==============================================================
* SECTION 1: Basic MM-QR (no fixed effects)
*==============================================================

* 1a. Median regression
mmqreg ln_w age ttl_exp tenure not_smsa south

* 1b. Multiple quantiles simultaneously
mmqreg ln_w age ttl_exp tenure not_smsa south, q(10 25 50 75 90)

* 1c. Only quantile equation (suppress location/scale)
mmqreg ln_w age ttl_exp tenure not_smsa south, q(25 50 75) nols

*==============================================================
* SECTION 2: MM-QR with Fixed Effects
*==============================================================

* 2a. Absorb individual fixed effect
mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(50)

* 2b. Clustered SE with FE
mmqreg ln_w age ttl_exp tenure not_smsa south, ///
    absorb(idcode) cluster(idcode) q(25 50 75)

* 2c. Robust SE
mmqreg ln_w age ttl_exp tenure not_smsa south, robust q(50)

* 2d. Degrees-of-freedom adjustment
mmqreg ln_w age ttl_exp tenure not_smsa south, ///
    absorb(idcode) dfadj q(50)

*==============================================================
* SECTION 3: Decomposed Split-Panel Jackknife (v2.4 — NEW)
*==============================================================
* The jknife option requires xtset data.
* It splits on odd/even years, estimates three models, and
* computes bias-corrected coefficients and jackknife SEs.

* 3a. Jackknife without FE
mmqreg ln_w age ttl_exp tenure not_smsa south, q(50) jknife

* 3b. Jackknife with fixed effects
mmqreg ln_w age ttl_exp tenure not_smsa south, ///
    absorb(idcode) q(50) jknife

* 3c. Compare: analytical vs jackknife at q50
mmqreg ln_w age ttl_exp tenure not_smsa south, q(50)
est store mmq_analytic

mmqreg ln_w age ttl_exp tenure not_smsa south, q(50) jknife
est store mmq_jk

esttab mmq_analytic mmq_jk, ///
    mtitles("Analytical SE" "Jackknife SE") ///
    keep(*:tenure *:age *:ttl_exp) ///
    title("Comparison: MM-QR SE methods at Q50")

*==============================================================
* SECTION 4: Visualization with mmqregplot (v2.4 — NEW)
*==============================================================

* 4a. Plot all coefficients across 10th–90th quantiles
mmqreg ln_w age ttl_exp tenure not_smsa south
mmqregplot, quantile(10(5)90)

* 4b. Subset of variables with OLS overlay
mmqregplot age ttl_exp tenure, quantile(10(5)90) ols

* 4c. Use variable labels as titles
mmqregplot, quantile(10 25 50 75 90) label

* 4d. Custom colors and line width
mmqregplot age ttl_exp tenure, ///
    raopt(color(maroon%20) lwidth(none)) ///
    lnopt(lcolor(maroon) lwidth(thick)) ///
    twopt(graphregion(color(white)) plotregion(margin(small)))

* 4e. After FE estimation
mmqreg ln_w age ttl_exp tenure, absorb(idcode)
mmqregplot age ttl_exp tenure, ols ///
    twopt(graphregion(color(white))) ///
    grcopt(title("MM-QR with idcode FE", size(medsmall)))

*==============================================================
* SECTION 5: Manual JK replication (from MM-QR-JK literature)
*==============================================================
* This replicates the logic of the MM-QR-JK (5).do test script,
* now natively implemented via the jknife option above.

qui mmqreg ln_w age ttl_exp tenure not_smsa south, q(50) nols
mat b_full = e(b)
scalar N    = e(N)

qui mmqreg ln_w age ttl_exp tenure not_smsa south if s==0, q(50) nols
mat b_h0 = e(b)
scalar N0   = e(N)

qui mmqreg ln_w age ttl_exp tenure not_smsa south if s==1, q(50) nols
mat b_h1 = e(b)
scalar N1   = e(N)

* Manual jackknife-corrected vector
mat b_jk_manual = 2*b_full - (N1/N)*b_h1 - (N0/N)*b_h0

display _n "JK-corrected coefficients (manual):"
mat list b_jk_manual

display _n "Now using native jknife option:"
mmqreg ln_w age ttl_exp tenure not_smsa south, q(50) jknife nols
mat list e(b)

*==============================================================
* SECTION 6: mmqregplot v2.0 — Full Visualization Suite
*==============================================================

** Prepare a multi-quantile estimate with FE for plotting
mmqreg ln_w age ttl_exp tenure not_smsa south, q(25 50 75)

*--------------------------------------------------------------
* 6a. Default quantile paths (eqplot=qtile)
*--------------------------------------------------------------
mmqregplot, quantile(10(5)90)

*--------------------------------------------------------------
* 6b. Quantile paths — subset of vars + OLS overlay
*--------------------------------------------------------------
mmqregplot age ttl_exp tenure, ols quantile(10(5)90) label

*--------------------------------------------------------------
* 6c. Color schemes comparison (save each)
*--------------------------------------------------------------
mmqregplot age, quantile(10(5)90) colorscheme(navy)    name(cs_navy, replace)    nodraw
mmqregplot age, quantile(10(5)90) colorscheme(viridis) name(cs_viridis, replace) nodraw
mmqregplot age, quantile(10(5)90) colorscheme(autumn)  name(cs_autumn, replace)  nodraw
mmqregplot age, quantile(10(5)90) colorscheme(warm)    name(cs_warm, replace)    nodraw
mmqregplot age, quantile(10(5)90) colorscheme(teal)    name(cs_teal, replace)    nodraw
mmqregplot age, quantile(10(5)90) colorscheme(mono)    name(cs_mono, replace)    nodraw

graph combine cs_navy cs_viridis cs_autumn cs_warm cs_teal cs_mono, ///
    cols(3) title("Color Schemes Comparison", size(medsmall) color(navy)) ///
    graphregion(color(white))
graph drop cs_navy cs_viridis cs_autumn cs_warm cs_teal cs_mono

*--------------------------------------------------------------
* 6d. Location equation coefplot
*--------------------------------------------------------------
mmqreg ln_w age ttl_exp tenure not_smsa south, q(25 50 75)
mmqregplot, eqplot(location) colorscheme(autumn) label

*--------------------------------------------------------------
* 6e. Scale equation coefplot
*--------------------------------------------------------------
mmqregplot, eqplot(scale) colorscheme(teal) label

*--------------------------------------------------------------
* 6f. ALL equations in one figure (location + scale + paths)
*--------------------------------------------------------------
mmqregplot age ttl_exp tenure, eqplot(all) colorscheme(navy) ols label ///
    grcopt(title("MM-QR Full Results", size(medsmall) color(navy)))

*--------------------------------------------------------------
* 6g. Country/Unit FE visualization — bar chart (sorted)
*--------------------------------------------------------------
mmqreg ln_w age ttl_exp tenure not_smsa south, absorb(idcode) q(50)
mmqregplot, feplot festyle(bar) colorscheme(navy)

* FE histogram with KDE
mmqregplot, feplot festyle(hist) colorscheme(warm)

* FE dot / Cleveland plot
mmqregplot, feplot festyle(dot) colorscheme(viridis)

*--------------------------------------------------------------
* 6h. Full combined: all equations + country effects
*--------------------------------------------------------------
mmqreg ln_w age ttl_exp tenure, absorb(idcode) q(25 50 75)
mmqregplot age ttl_exp tenure, ///
    eqplot(all) feplot festyle(bar)  ///
    colorscheme(navy) ols label ///
    grcopt(title("MM-QR: Full Panel with Country Effects", ///
                  size(small) color(navy)))

*--------------------------------------------------------------
* 6i. Publication-ready: monochrome, 90% CI, no zero line
*--------------------------------------------------------------
mmqreg ln_w age ttl_exp tenure not_smsa south
mmqregplot age ttl_exp tenure, ///
    eqplot(all) colorscheme(mono) ols ///
    level(90) nozero label ///
    grcopt(title("Results (90% CI)", size(small) color(black)))

