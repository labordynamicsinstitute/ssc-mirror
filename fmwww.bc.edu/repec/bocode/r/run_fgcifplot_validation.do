version 14.2
clear all
set more off

di as text "============================================================"
di as text "FGCIFPLOT 1.0.0 RELEASE VALIDATION"
di as text "============================================================"

do "test_fgcifplot_knowntruth.do"
do "test_fgcifplot.do"
do "test_fgcifplot_edgecases.do"
do "stress_fgcifplot.do"

di as result ""
di as result "ALL FGCIFPLOT 1.0.0 RELEASE TESTS COMPLETED"
