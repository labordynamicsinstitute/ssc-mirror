*-------------------------------------------------------------------
* example_pathintdid.do
* Reproduces the examples shown in "pathintdid: A command for
* path-integrated difference-in-differences impact evaluation, with
* inference" (Salavi, 2026), using the accompanying trainingpanel.dta
* dataset (a 20-unit individual-level panel: 10 treated, 10 control;
* outcome: daily per-capita household consumption expenditure, in
* dollars; time = 0 (2008 baseline) ... 5 (2014 endline)).
*
* Run from the directory containing pathintdid.ado, pathintdidplot.ado,
* pathintdidrobust.ado, and trainingpanel.dta (or adjust the
* adopath/cd lines below).
*
* NOTE ON EXPECTED RESULTS: this dataset has genuine unit-level
* sampling variation (it is not a pair of pre-aggregated cohort
* means), so sigma, tau-bar, and the static DiD will not reproduce a
* hand-calculated illustration to the penny. The point of this
* example is the inference output: sigma should come out large and
* statistically significant, while the static endpoint DiD should
* come out small and statistically indistinguishable from zero.
* Approximate expected results:
*   sigma (cumulative causal effect)   ~ 20.5,  t > 100, p < 0.001
*   tau-bar (path-integrated ATT)      ~  4.1  per year
*   conventional static DiD (0 vs. 5)  ~  0.0,  t ~= 0,   p ~= 1
*
* Figures are saved as PDF and use the "sj" scheme, per the Stata
* Journal's figure guidelines (PDF format, sj/stsj scheme, legible in
* grayscale).
*
* ROBUSTNESS CHECKS (new in this release): pathintdidrobust implements
* the three specification tests of section 5 of the companion paper --
* (A) a dynamic placebo test for pre-treatment parallel trends, (B) a
* sensitivity check of sigma-hat to grid density and to the quadrature
* rule (trapezoidal vs. Simpson), and (C) an anticipation-robust
* bounding estimator with its sensitivity curve. Because this
* particular dataset's earliest observed wave (time = 0) IS t0()
* (there are no pre-treatment survey rounds on file), checks (A) and
* (C) will correctly report that they have no pre-treatment data to
* work with and skip themselves -- that "no pre-period available"
* message is the expected, correct behavior here, not an error.
* Check (B) does not need pre-treatment waves and runs normally.
*-------------------------------------------------------------------

capture log close
log using pathintdid.log, replace text

version 14.0
clear all
set more off
set linesize 80

* Make pathintdid/pathintdidplot/pathintdidrobust available if they
* sit alongside this do-file rather than in a standard ado-path
* directory:
capture adopath ++ "`c(pwd)'"

set scheme sj

use trainingpanel, clear
describe
summarize consumption, detail

* --- Full-horizon estimate (t0 = 0, t1 = 5), with SE/t/CI ----------
pathintdid consumption, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5)

display as text ""
display as text "sigma      = " as result r(sigma)   as text "   se = " as result r(se_sigma) ///
	as text "   t = " as result r(t_sigma)
display as text "tau-bar    = " as result r(att_path) as text "   se = " as result r(se_att)
display as text "static DiD = " as result r(did_static) as text "   se = " as result r(se_did) ///
	as text "   t = " as result r(t_did)

* --- Same estimate, point estimates only (no SE/t/CI), for speed ---
pathintdid consumption, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5) nose

* --- Dedicated impact graph (paths + cumulative sigma(t) buildup,
*     with a shaded confidence band around the plateau) -------------
* t2(5) here since the paths are calibrated to fully rejoin by Year 5
* in this illustration; set t2() to an earlier date if convergence
* happens before the chosen evaluation horizon t1().
pathintdidplot consumption, panelvar(id) timevar(time) treatvar(treat) ///
	t0(0) t1(5) t2(5) ///
	title("Training program: cumulative consumption impact") ///
	name(pathintdid_impact)

graph export pathintdidplot_example.pdf, replace

* --- Truncating the evaluation horizon at the rejoining point ------
pathintdid consumption, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(3)

*-------------------------------------------------------------------
* --- Robustness checks and specification tests (section 5) --------
*-------------------------------------------------------------------

* (1) Full horizon t0=0/t1=5: K=5 (odd) post-treatment intervals, so
*     check (B)'s half-grid/Simpson comparison will report that it
*     needs an even number of equally spaced intervals and skip --
*     this demonstrates that guard rail.
pathintdidrobust consumption, panelvar(id) timevar(time) treatvar(treat) ///
	t0(0) t1(5) maxanticip(2)

* (2) t0=0/t1=4: K=4 (even) post-treatment intervals, so the
*     grid-density and Simpson's-rule comparison in check (B) runs.
*     Checks (A) and (C) still report "no pre-treatment data" for
*     this dataset, since time=0 is the first observed wave.
pathintdidrobust consumption, panelvar(id) timevar(time) treatvar(treat) ///
	t0(0) t1(4) maxanticip(2)

log close
