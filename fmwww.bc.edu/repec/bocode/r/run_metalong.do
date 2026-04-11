/* ============================================================
   run_metalong.do
   metaLong for Stata 14.1 — complete reproducible pipeline
   Run with:   do run_metalong.do
   Output files are saved to your current working directory.
   ============================================================ */

version 14.1
clear all
set more off

di as txt "Working directory: " as res c(pwd)

/* ── STEP 1: Simulate data ──────────────────────────────────── */
sim_longmeta, k(8) times(0 6 12 24) mu(0.20) tau(0.35) seed(42) clear
save sim_data.dta, replace

/* ── STEP 2: Pool effects ───────────────────────────────────── */
use sim_data.dta, clear
ml_meta yi vi, study(study) time(time) saving(meta_res) replace

di _newline "=== Pooled Effects ==="
use meta_res.dta, clear
list time k theta se p_val ci_lb ci_ub tau2, sep(0)

/* ── STEP 3: ITCV sensitivity ───────────────────────────────── */
use sim_data.dta, clear
ml_sens yi vi, study(study) time(time) metafile(meta_res) delta(0.15) saving(sens_res) replace

di _newline "=== Sensitivity (ITCV) ==="
use sens_res.dta, clear
list time theta sy itcv itcv_alpha fragile, sep(0)

/* ── STEP 4: Benchmark ──────────────────────────────────────── */
use sim_data.dta, clear
ml_benchmark yi vi, study(study) time(time) metafile(meta_res) ///
    sensfile(sens_res) covariates(pub_year quality n) saving(bench_res) replace

di _newline "=== Benchmark ==="
use bench_res.dta, clear
list time covariate r_partial itcv_alpha beats p_val, sep(3)

/* ── STEP 5: Fragility ──────────────────────────────────────── */
use sim_data.dta, clear
ml_fragility yi vi, study(study) time(time) metafile(meta_res) maxk(5) saving(frag_res) replace

di _newline "=== Fragility ==="
use frag_res.dta, clear
list time k_studies fragility_index frag_quotient study_removed, sep(0)

/* ── STEP 6: Spline ─────────────────────────────────────────── */
ml_spline, metafile(meta_res) df(3) npred(100) saving(spline_res) replace

/* ── STEP 7: Combined figure (drawn directly — no ado needed) ── */

/* Panel 1: Pooled effects */
use meta_res.dta, clear
twoway (rcap ci_ub ci_lb time if !missing(theta), lcolor(navy) lwidth(thin)) (connected theta time if !missing(theta), lcolor(navy) lwidth(medthick) msymbol(O) mcolor(navy)) (scatter theta time if !missing(theta) & sig==1, msymbol(D) mcolor(red) msize(medsmall)), yline(0, lpattern(dash) lcolor(gs10)) xtitle("Follow-up time") ytitle("Pooled effect") title("Pooled Effects") note("Bars=95%CI  |  Red=significant", size(vsmall)) legend(off) name(fig_p1, replace) nodraw

/* Panel 2: Sensitivity */
use sens_res.dta, clear
twoway (connected itcv_alpha time if !missing(itcv_alpha), lcolor(navy) lwidth(medium) msymbol(O) mcolor(navy)), yline(0.15, lpattern(dash) lcolor(gs6)) xtitle("Follow-up time") ytitle("ITCV-adj") title("Sensitivity (ITCV)") note("Dashed = threshold 0.15", size(vsmall)) legend(off) name(fig_p2, replace) nodraw

/* Panel 3: Spline */
use meta_res.dta, clear
quietly gen byte _src = 0
quietly append using spline_res.dta
quietly replace _src = 1 if missing(_src)
twoway (line theta_hat time if _src==1, lcolor(maroon) lwidth(medthick)) (rcap ci_ub ci_lb time if _src==0 & !missing(theta), lcolor(gs10) lwidth(thin)) (scatter theta time if _src==0 & !missing(theta), msymbol(O) mcolor(gs6) msize(small)), yline(0, lpattern(dash) lcolor(gs10)) xtitle("Follow-up time") ytitle("Pooled effect") title("Spline Trend") note("Maroon=spline  |  Grey=observed", size(vsmall)) legend(off) name(fig_p3, replace) nodraw

/* Panel 4: Fragility */
use frag_res.dta, clear
twoway (bar fragility_index time if !missing(fragility_index), fcolor(navy) lcolor(navy)), yline(1, lpattern(dash) lcolor(gs10)) xtitle("Follow-up time") ytitle("Fragility index") title("Fragility Index") note("Dashed at FI=1  |  Bar = min removals to flip", size(vsmall)) legend(off) name(fig_p4, replace) nodraw

/* Combine */
graph combine fig_p1 fig_p2 fig_p3 fig_p4, cols(2) name(fig_combined, replace)
graph drop fig_p1 fig_p2 fig_p3 fig_p4
graph save fig_combined metalong_figure.gph, replace
graph export metalong_figure.pdf, replace

di _newline "========================================"
di "  metaLong pipeline complete."
di "  All files saved to: " c(pwd)
di "  Figure: metalong_figure.pdf"
di "========================================"
