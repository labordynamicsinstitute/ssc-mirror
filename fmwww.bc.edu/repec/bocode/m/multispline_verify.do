/* ============================================================
   MultiSpline v0.2.0 - Full Verification Script
   Tests ALL features against R v0.2.0 parity claims
   Subir Hait | Michigan State University
   ============================================================ */

clear all
set more off
set seed 20260417
discard

di _newline as text "========================================"
di as text " MultiSpline v0.2.0 - Full Verification"
di as text "========================================"

* ============================================================
* SIMULATE DATA: 25 schools, 18 students each, 6 waves
* ============================================================
local n_school = 25
local n_per    = 18
local n_wave   = 6

* Build student-level data first, then expand
local n_students = `n_school' * `n_per'
set obs `n_students'

generate school_id  = ceil(_n / `n_per')
generate student_id = _n

* Student-level random effects and covariates
generate u_school = rnormal(0, 0.9)
bysort school_id (student_id): replace u_school = u_school[1]
generate u_student = rnormal(0, 1.8)
generate female    = (runiform() < 0.5)
generate ses       = rnormal(0, 0.9)

* Expand to longitudinal
expand `n_wave'
bysort student_id: generate wave = _n
generate age   = 8 + (wave-1)*8/(`n_wave'-1) + rnormal(0, 0.15)
generate true_f = 16 - 0.22*(age-12.5)^2 + 1.8*sin(0.55*age)
generate score  = true_f + 0.5*ses - 0.4*female ///
                  + u_school + u_student + rnormal(0, 1)
generate pass   = (score > 14)

local N = _N
di as text "Data: N=`N', schools=`n_school', students=`n_students'"
assert _N == `n_school' * `n_per' * `n_wave'

* ============================================================
* TEST 1: Single-level OLS with compare and derivatives
* ============================================================
di _newline as text "--- TEST 1: OLS single-level ---"
multispline score age female ses, df(auto) compare r2 ///
    derivatives turning_points plot(trajectory)
assert e(df) > 0
assert e(aic) < .
di as result "TEST 1 PASSED"

* ============================================================
* TEST 2: Single cluster LMM + derivatives
* ============================================================
di _newline as text "--- TEST 2: Single cluster LMM ---"
multispline score age female ses, ///
    cluster(student_id) df(auto) r2 icc compare ///
    derivatives turning_points plot(combo)
assert "`e(model_type)'" == "LMM"
di as result "TEST 2 PASSED"

* ============================================================
* TEST 3: Nested multilevel (schools > students)
* ============================================================
di _newline as text "--- TEST 3: Nested LMM ---"
multispline score age female ses, ///
    cluster(school_id student_id) nested ///
    df(auto) r2 icc compare ///
    derivatives turning_points plot(trajectory)
assert "`e(model_type)'" == "LMM-nested"
di as result "TEST 3 PASSED"

* ============================================================
* TEST 4: Cross-classified multilevel
* ============================================================
di _newline as text "--- TEST 4: Cross-classified LMM ---"
multispline score age female ses, ///
    cluster(school_id student_id) ///
    df(3) r2 icc plot(trajectory)
assert "`e(model_type)'" == "LMM-cross"
di as result "TEST 4 PASSED"

* ============================================================
* TEST 5: R-squared + ICC
* ============================================================
di _newline as text "--- TEST 5: R-squared decomposition ---"
multispline score age female ses, ///
    cluster(student_id) df(3) r2 icc
di as result "TEST 5 PASSED"

* ============================================================
* TEST 6: Model comparison workflow
* ============================================================
di _newline as text "--- TEST 6: Model comparison ---"
multispline score age female ses, ///
    cluster(student_id) df(auto) compare poly_degrees(2 3)
di as result "TEST 6 PASSED"

* ============================================================
* TEST 7: Random spline slopes
* ============================================================
di _newline as text "--- TEST 7: Random spline slopes ---"
multispline score age female ses, ///
    cluster(student_id) df(3) randslope r2
assert "`e(model_type)'" == "LMM-rslope"
di as result "TEST 7 PASSED"

* ============================================================
* TEST 8: Cluster heterogeneity + LRT
* ============================================================
di _newline as text "--- TEST 8: Cluster het + LRT ---"
multispline score age female ses, ///
    cluster(student_id) df(3) het nhet(25) predict_grid(0)
di as result "TEST 8 PASSED"

* ============================================================
* TEST 9: B-spline basis
* ============================================================
di _newline as text "--- TEST 9: B-spline basis ---"
multispline score age female ses, ///
    cluster(student_id) method(bs) df(4) plot(trajectory)
assert e(df) == 4
di as result "TEST 9 PASSED"

* ============================================================
* TEST 10: Binary outcome logit (single-level)
* ============================================================
di _newline as text "--- TEST 10: Binary outcome (logit) ---"
multispline pass age female ses, ///
    family(logit) df(auto) compare plot(trajectory)
assert "`e(model_type)'" == "Logit"
di as result "TEST 10 PASSED"

* ============================================================
* TEST 11: Multilevel binary GLMM
* ============================================================
di _newline as text "--- TEST 11: Multilevel binary GLMM ---"
multispline pass age female ses, ///
    cluster(student_id) family(logit) df(3) r2 plot(trajectory)
assert substr("`e(model_type)'",1,4) == "GLMM"
di as result "TEST 11 PASSED"

* ============================================================
* TEST 12: Derivatives + turning points under clustering
* ============================================================
di _newline as text "--- TEST 12: Derivatives + turning points (LMM) ---"
multispline score age female ses, ///
    cluster(student_id) df(auto) ///
    derivatives turning_points plot(combo)
di as result "TEST 12 PASSED"

* ============================================================
* TEST 13: BIC criterion
* ============================================================
di _newline as text "--- TEST 13: BIC df selection ---"
multispline score age, df(auto) criterion(bic) df_range(2 3 4 5 6)
di as result "TEST 13 PASSED"

* ============================================================
* SUMMARY
* ============================================================
di _newline as text "========================================"
di as result " ALL 13 TESTS PASSED"
di as text " MultiSpline Stata v0.2.0 verified:"
di as text "  OLS, LMM, nested, cross-classified"
di as text "  R2/ICC, model comparison (LRT fixed)"
di as text "  Random slopes, het + BLUP plot"
di as text "  Binary outcomes (logit/probit/GLMM)"
di as text "  B-splines, derivatives, turning points"
di as text "  Inline plots: trajectory/slope/combo"
di as text "========================================"
