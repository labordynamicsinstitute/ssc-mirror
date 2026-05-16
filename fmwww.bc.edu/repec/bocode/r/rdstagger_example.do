* rdstagger_example.do
* Complete worked example for rdstagger package
* Replicates all results in Hait (2026), Stata Journal
* Run in a fresh Stata 14 session after: ssc install rdstagger

version 14
clear all
set more off
set linesize 120

* ============================================================
* Section 1: Simulate staggered RD panel data
* ============================================================

rdstagger_sim,                  ///
    n(400)                      ///  400 units
    periods(8)                  ///  8 time periods
    cohorts(3)                  ///  3 treatment cohorts
    direct(0.3)                 ///  true direct ATT = 0.3
    spill(0.1)                  ///  true spillover = 0.1
    density(0.1)                ///  10% density at cutoff
    outcome(continuous)         ///
    seed(42)

* ============================================================
* Section 2: Estimate ATT(g,t) — main command
* ============================================================

rdstagger y x,                  ///
    cutoff(0)                   ///
    gvar(g)                     ///
    tvar(period)                ///
    idvar(id)                   ///
    bw(1.5)                     ///
    kernel(triangular)          ///
    control(nevertreated)

* ============================================================
* Section 3: Pre-treatment falsification test
* ============================================================

rdstagger_pretest, method(both)

* ============================================================
* Section 4: Aggregation
* ============================================================

rdstagger_agg, type(dynamic)   // event-study
rdstagger_agg, type(group)     // by cohort
rdstagger_agg, type(calendar)  // by calendar period
rdstagger_agg, type(overall)   // single overall ATT

* ============================================================
* Section 5: Event-study plot
* ============================================================

rdstagger_agg, type(dynamic)
rdstagger_plot, name(event_study, replace)

* ============================================================
* Section 6: Formatted table output
* ============================================================

rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id) bw(1.5)

* Save LaTeX table

* ============================================================
* Section 6: Spillover decomposition
* ============================================================

rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id) bw(1.5)
rdstagger_spillover

* Retrieve decomposition matrix
matrix SPILL = e(spillover)
di "Spillover matrix stored in e(spillover): " rowsof(SPILL) " rows"

* ============================================================
* Section 7: Not-yet-treated control group comparison
* ============================================================

rdstagger y x,                  ///
    cutoff(0)                   ///
    gvar(g)                     ///
    tvar(period)                ///
    idvar(id)                   ///
    bw(1.5)                     ///
    control(notyetreated)

rdstagger_agg, type(overall)

* ============================================================
* Section 8: Binary and count outcomes
* ============================================================

clear
rdstagger_sim, n(400) periods(8) cohorts(3) direct(0.3) outcome(binary) seed(42)
rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id) bw(1.5)
rdstagger_agg, type(overall)

clear
rdstagger_sim, n(400) periods(8) cohorts(3) direct(0.3) outcome(count) seed(42)
rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id) bw(1.5)
rdstagger_agg, type(overall)

di as result _newline "EXAMPLE COMPLETE"
