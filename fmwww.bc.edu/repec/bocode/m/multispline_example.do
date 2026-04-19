/* ============================================================
   MultiSpline v0.2.0 - Stata Example Do-file
   Subir Hait | Michigan State University | haitsubi@msu.edu
   ============================================================
   SETUP: Copy multispline.ado, multispline_plot.ado, and
   multispline.sthlp to your PERSONAL ado directory.
   Find it with:  sysdir
   Typical path:  c:\ado\personal\
   ============================================================
   NOTE: This example uses the plot() option which generates
   figures inline without saving to disk - works on all
   machines including restricted lab computers.
   ============================================================ */

* ============================================================
* PART A: Quick test with built-in auto dataset
* ============================================================

sysuse auto, clear

* 1. Basic trajectory plot
multispline price mpg, df(auto) plot(trajectory)

* 2. With derivatives and turning points
multispline price mpg, df(auto) derivatives turning_points plot(combo)

* 3. With controls and model comparison
multispline price mpg weight, df(auto) compare r2 plot(trajectory)

* 4. B-spline alternative
multispline price mpg, method(bs) df(4) plot(trajectory)

* 5. Slope plot (first derivative)
multispline price mpg, df(auto) derivatives plot(slope)

* ============================================================
* PART B: Simulated multilevel longitudinal data
* ============================================================
* True curve: f(age) = 16 - 0.22*(age-12.5)^2 + 1.8*sin(0.55*age)

clear all
set more off
set seed 20260417

local n_school       = 25
local n_per_school   = 18
local n_time         = 6
local N = `n_school' * `n_per_school' * `n_time'
set obs `N'

* Indices
generate school_id  = ceil(_n / (`n_per_school' * `n_time'))
generate student_id = ceil(_n / `n_time')
generate wave       = mod(_n - 1, `n_time') + 1

* Age: 6 waves from 8 to 16
generate age = 8 + (wave - 1) * 8 / (`n_time' - 1) + rnormal(0, 0.15)

* Covariates (fixed within student)
by student_id (wave), sort: generate female = (runiform() < 0.5) if _n == 1
by student_id (wave):       replace  female = female[1]
by student_id (wave):       generate ses    = rnormal(0, 0.9)   if _n == 1
by student_id (wave):       replace  ses    = ses[1]

* Random effects
by school_id  (wave), sort: generate u_school  = rnormal(0, 0.9) if _n == 1
by student_id (wave), sort: generate u_student = rnormal(0, 1.8) if _n == 1
by school_id  (wave):  replace u_school  = u_school[1]
by student_id (wave):  replace u_student = u_student[1]

* True curve and outcome
generate true_f = 16 - 0.22*(age - 12.5)^2 + 1.8*sin(0.55*age)
generate score  = true_f + 0.5*ses - 0.4*female ///
                  + u_school + u_student + rnormal(0, 1.0)

label variable score     "Cognitive test score"
label variable age       "Age (years)"
label variable female    "Female (0/1)"
label variable ses       "Socioeconomic status"
label variable school_id "School identifier"

* ---- Descriptive summary ----
summarize score age female ses
tabulate wave

* ---- Knot selection ----
di _newline as text "--- Knot selection ---"
multispline score age female ses, ///
    cluster(school_id student_id) nested ///
    df(auto) df_range(2 3 4 5 6) criterion(aic) ///
    predict_grid(0)

* ---- Full nested multilevel model ----
multispline score age female ses, ///
    cluster(school_id student_id) nested ///
    df(auto) df_range(2 3 4 5 6) criterion(aic) ///
    r2 icc compare ///
    derivatives turning_points ///
    predict_grid(150) level(95) ///
    plot(combo)

* ---- Trajectory plot ----
multispline score age female ses, ///
    cluster(school_id student_id) nested ///
    df(auto) r2 plot(trajectory)

* ---- Slope plot ----
multispline score age female ses, ///
    cluster(school_id student_id) nested ///
    df(auto) derivatives plot(slope)

* ---- Cross-classified model ----
multispline score age female ses, ///
    cluster(school_id student_id) ///
    df(4) r2 icc plot(trajectory)

* ---- Single cluster ----
multispline score age female ses, ///
    cluster(student_id) ///
    df(auto) r2 icc plot(combo)

di _newline as text "========================================"
di as text " MultiSpline Stata example complete."
di as text "========================================"

* ============================================================
* PART C: New features in v0.2.0
* ============================================================

* ---- C1. Random spline slopes ----
di _newline as text "=== Random spline slopes ==="
clear
set obs 300
set seed 42
generate id    = ceil(_n/5)
generate age   = 8 + mod(_n-1,5)*2 + rnormal(0,0.2)
generate score = 16 - 0.22*(age-12.5)^2 + rnormal(0,2)

* Random intercepts only (baseline)
multispline score age, cluster(id) df(3) r2 icc

* Random spline slopes (allows trajectory shape to vary by cluster)
multispline score age, cluster(id) df(3) randslope r2

* ---- C2. Cluster heterogeneity (nl_het equivalent) ----
di _newline as text "=== Cluster heterogeneity analysis ==="
multispline score age, cluster(id) df(3) het nhet(20)

* ---- C3. Binary outcomes ----
di _newline as text "=== Binary outcome (logit) ==="
clear
set obs 400
set seed 123
generate id    = ceil(_n/5)
generate age   = 10 + runiform()*10
generate xb    = -2 + 0.5*age - 0.03*age^2
generate pass  = rbinomial(1, invlogit(xb))

* Single-level logit spline
multispline pass age, family(logit) df(auto) plot(trajectory)

* Multilevel logit spline
multispline pass age, cluster(id) family(logit) df(auto) r2 plot(trajectory)

* Probit alternative
multispline pass age, family(probit) df(auto) compare plot(trajectory)

di _newline as text "========================================"
di as text " All features demonstrated successfully"
di as text "========================================"
