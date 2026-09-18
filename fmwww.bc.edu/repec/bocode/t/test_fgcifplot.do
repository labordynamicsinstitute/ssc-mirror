version 14.2
clear all
set more off

* Load the release-candidate source from this directory.
quietly run "fgcifplot.ado"

* =====================================================================
* Public-data regression test using Stata's hypoxia example.
* The expected matrices below are frozen from Stata 14.2 validation.
* =====================================================================

webuse hypoxia, clear
stset dftime, failure(failtype==1)
stcrreg ifp tumsize i.pelnode, compete(failtype==2) nolog

fgcifplot pelnode, values(0 1) risktimes(0 2 4 6 8) risktable(all) nograph

matrix C = r(conventional)
matrix R = r(retained)
matrix W = r(weighted)
matrix G = r(censor_survival)

matrix Cstar = (22,7,4,1,0 \ 87,54,39,21,4)
matrix Rstar = (22,10,7,4,3 \ 87,66,52,35,18)
matrix Wstar = (22,9.8830148,6.1490873,2.1350019,.22700037 \ ///
                87,65.78313,48.73906,26.853187,5.1706374)
matrix Gstar = (1,.96100493,.71636245,.37833396,.07566679)

forvalues i = 1/2 {
    forvalues j = 1/5 {
        assert abs(C[`i',`j'] - Cstar[`i',`j']) < 1e-8
        assert abs(R[`i',`j'] - Rstar[`i',`j']) < 1e-8
        assert abs(W[`i',`j'] - Wstar[`i',`j']) < 1e-6
    }
}
forvalues j = 1/5 {
    assert abs(G[1,`j'] - Gstar[1,`j']) < 1e-7
}

di as result "fgcifplot frozen hypoxia regression test PASSED"

* The independent numerical cross-check against Stata's predict, kmcensor
* is deliberately performed in test_fgcifplot_knowntruth.do, where requested
* times are fixed by construction and every comparison is asserted to exist.
* This public-data test is a frozen regression test: its job is to ensure that
* refactoring does not change previously validated outputs on hypoxia.
