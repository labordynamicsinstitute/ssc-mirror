/* ============================================================
   MultiSpline v0.2.0 - Reproducible Demo
   Subir Hait | Michigan State University | haitsubi@msu.edu
   ============================================================
   This file demonstrates all major features using built-in
   Stata datasets. Copy multispline.ado, multispline_plot.ado,
   and multispline.sthlp to c:\ado\personal\ first.
   ============================================================ */

clear all
set more off

/*        1. OLS: single-level spline                                                                                */
sysuse auto, clear

multispline price mpg, ///
    df(auto) compare r2 ///
    derivatives turning_points ///
    plot(combo)

/*        2. OLS: B-spline basis                                                                                                  */
multispline price mpg weight, ///
    method(bs) df(4) ///
    plot(trajectory)

/*        3. Binary outcome: logit                                                                                            */
multispline foreign mpg weight, ///
    family(logit) df(auto) compare ///
    plot(trajectory)

/*        4. Multilevel LMM                                                                                                                 */
* Simulate 2-level longitudinal data
clear
set seed 20260418
set obs 300
generate id  = ceil(_n / 5)
generate age = 8 + mod(_n-1, 5)*2 + rnormal(0, 0.15)
bysort id: generate u_i = rnormal(0, 1.8) if _n == 1
bysort id: replace  u_i = u_i[1]
generate score = 16 - 0.22*(age-12.5)^2 + u_i + rnormal(0, 1)
generate pass  = (score > 14)
label variable score "Cognitive score"
label variable age   "Age (years)"

* LMM: single cluster, auto df, full output
multispline score age, ///
    cluster(id) df(auto) ///
    r2 icc compare ///
    derivatives turning_points ///
    plot(combo)

/*        5. Random spline slopes                                                                                               */
multispline score age, ///
    cluster(id) df(3) randslope r2

/*        6. Cluster heterogeneity                                                                                            */
multispline score age, ///
    cluster(id) df(3) het nhet(20)

/*        7. GLMM: multilevel binary                                                                                      */
multispline pass age, ///
    cluster(id) family(logit) df(auto) r2 ///
    plot(trajectory)

di _newline as result "Demo complete. All features verified."
