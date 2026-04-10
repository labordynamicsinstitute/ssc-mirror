/* ============================================================
   metalong_example.do
   Complete reproducible example for the metaLong Stata package
   Stata 14.1 | Author: Subir Hait | haitsubi@msu.edu
   ============================================================ */

version 14.1
clear all
set more off

* ──────────────────────────────────────────────────────────────
* STEP 0  Install (run once; comment out after installation)
* ──────────────────────────────────────────────────────────────
/*
  Copy all ado/ and help/ files from the metalong ZIP to your
  personal ado directory, then verify:
      which ml_meta
      help metalong
*/

* ──────────────────────────────────────────────────────────────
* STEP 1  Simulate longitudinal meta-analytic data
* ──────────────────────────────────────────────────────────────
sim_longmeta,        ///
    k(20)            ///   20 studies
    times(0 6 12 24) ///   4 time points (months)
    mu(0.4)          ///   true effect = 0.4
    tau(0.2)         ///   between-study SD
    seed(42)         ///   for reproducibility
    clear

* Quick look at the data structure
list study time yi vi pub_year quality n in 1/8, sep(4)

* Save a copy for re-use
save metalong_data.dta, replace

* ──────────────────────────────────────────────────────────────
* STEP 2  Longitudinal pooled meta-analysis
* ──────────────────────────────────────────────────────────────
use metalong_data.dta, clear

ml_meta yi vi,            ///
    study(study)          ///
    time(time)            ///
    alpha(0.05)           ///   95% CIs
    mink(2)               ///   need ≥2 studies per time
    saving(meta_res) replace

* Inspect results
use meta_res, clear
list time k theta se df p_val ci_lb ci_ub tau2, sep(0)

* Reload data for next step
use metalong_data.dta, clear

* ──────────────────────────────────────────────────────────────
* STEP 3  Time-varying sensitivity analysis (ITCV)
* ──────────────────────────────────────────────────────────────
ml_sens yi vi,            ///
    study(study)          ///
    time(time)            ///
    metafile(meta_res)    ///
    alpha(0.05)           ///
    delta(0.15)           ///   fragility threshold
    saving(sens_res) replace

* Summarise fragility
use sens_res, clear
list time theta itcv itcv_alpha fragile, sep(0)
display "Fragile proportion: " r(frag_prop)

use metalong_data.dta, clear

* ──────────────────────────────────────────────────────────────
* STEP 4  Benchmark ITCV against observed covariates
* ──────────────────────────────────────────────────────────────
ml_benchmark yi vi,              ///
    study(study)                 ///
    time(time)                   ///
    metafile(meta_res)           ///
    sensfile(sens_res)           ///
    covariates(pub_year quality n) ///
    mink(3)                      ///
    saving(bench_res) replace

use bench_res, clear
list time covariate r_partial itcv_alpha beats p_val, sep(3)

use metalong_data.dta, clear

* ──────────────────────────────────────────────────────────────
* STEP 5  Leave-k-out fragility analysis
* ──────────────────────────────────────────────────────────────
ml_fragility yi vi,           ///
    study(study)              ///
    time(time)                ///
    metafile(meta_res)        ///
    maxk(3)                   ///
    alpha(0.05)               ///
    saving(frag_res) replace

use frag_res, clear
list time k_studies p_original fragility_index frag_quotient study_removed, sep(0)

* ──────────────────────────────────────────────────────────────
* STEP 6  Restricted cubic spline time trend
* ──────────────────────────────────────────────────────────────
ml_spline,              ///
    metafile(meta_res)  ///
    df(3)               ///   3 df spline (2 internal knots)
    npred(200)          ///   smooth prediction grid
    saving(spline_res) replace

display "Weighted R-squared: " r(r_squared)
if !missing(r(p_nonlinear)) ///
    display "Nonlinearity p-value: " r(p_nonlinear)

* ──────────────────────────────────────────────────────────────
* STEP 7  Combined publication figure
* ──────────────────────────────────────────────────────────────
ml_plot,                               ///
    metafile(meta_res)                 ///
    sensfile(sens_res)                 ///
    splinefile(spline_res)             ///
    fragfile(frag_res)                 ///
    title("Longitudinal Meta-Analysis: metaLong") ///
    scheme(s2color)                    ///
    saving(metalong_figure.gph) replace

* Export to PDF
graph export metalong_figure.pdf, replace
display "Figure exported to metalong_figure.pdf"

* ──────────────────────────────────────────────────────────────
* STEP 8  Examine individual result files
* ──────────────────────────────────────────────────────────────
di _newline "=== POOLED EFFECTS ===" _newline
use meta_res, clear
list, sep(0)

di _newline "=== SENSITIVITY (ITCV) ===" _newline
use sens_res, clear
list time theta sy itcv itcv_alpha fragile, sep(0)

di _newline "=== FRAGILITY ===" _newline
use frag_res, clear
list time k_studies fragility_index frag_quotient, sep(0)

di _newline "Analysis complete."
