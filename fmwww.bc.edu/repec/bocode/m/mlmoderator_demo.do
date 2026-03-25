 /* =========================================================
   mlmoderator_demo.do
   Demonstration script for mlmoderator v1.0.0
   Subir Hait, Michigan State University, 2026

   Requires: Stata 14.1+
   Commands: mlmcenter mlmprobe mlmjn mlmplot
             mlmsummary mlmvdecomp mlmsens
   ========================================================= */

version 14.1
clear all
set more off
set seed 2025

/* ---------------------------------------------------------
   STEP 1: Simulate school data
   Education example: SES x School Climate -> Math
   Design: 30 schools, 30 students each = 900 observations
   --------------------------------------------------------- */

di _newline as text "=== STEP 1: Simulate Data ==="

local J = 30
local n = 30

set obs 900

generate int    school  = ceil(_n / `n')
generate double ses     = rnormal(0, 1)
generate byte   gender  = runiform() > 0.5
generate double climate = .
generate double u0      = .
generate double u1      = .

forvalues j = 1/`J' {
    replace climate = rnormal(0, 1)   if school == `j'
    replace u0      = rnormal(0, 0.5) if school == `j'
    replace u1      = rnormal(0, 0.3) if school == `j'
}

generate double math = 10 + 1.5*ses + 0.8*climate + 0.6*ses*climate + u0 + u1*ses + rnormal(0,1)

label variable math    "Mathematics achievement"
label variable ses     "Student SES"
label variable climate "School climate"
label variable school  "School ID"
label variable gender  "Gender (1=female)"

di as text "Data created: N = " as result _N as text " students in " as result `J' as text " schools"

/* ---------------------------------------------------------
   STEP 2: Center variables
   --------------------------------------------------------- */

di _newline as text "=== STEP 2: Centering ==="

* Grand-mean center school climate (level-2 variable)
mlmcenter climate, type(grand)

* Group-mean center SES within schools (level-1 variable)
mlmcenter ses, cluster(school) type(group)

* Within-between decomposition for SES
mlmcenter ses, cluster(school) type(both)

* Check all centered variables
summarize ses_c climate_c ses_within ses_between

/* ---------------------------------------------------------
   STEP 3: Fit the multilevel model
   --------------------------------------------------------- */

di _newline as text "=== STEP 3: Fit MLM ==="

mixed math c.ses_c##c.climate_c gender || school: ses_c, reml covariance(unstructured)

/* ---------------------------------------------------------
   STEP 4: Simple slopes at -1SD, Mean, +1SD of climate
   --------------------------------------------------------- */

di _newline as text "=== STEP 4: Simple Slopes ==="

* Default: mean-SD strategy
mlmprobe, pred(ses_c) modx(climate_c)

* Quartiles
mlmprobe, pred(ses_c) modx(climate_c) values(quartiles)

* Tertiles
mlmprobe, pred(ses_c) modx(climate_c) values(tertiles)

* Custom values
mlmprobe, pred(ses_c) modx(climate_c) at(-1.5 0 1.5)

/* ---------------------------------------------------------
   STEP 5: Johnson-Neyman interval
   --------------------------------------------------------- */

di _newline as text "=== STEP 5: Johnson-Neyman Interval ==="

* Analytical exact solution
mlmjn, pred(ses_c) modx(climate_c)

* With significance region plot
mlmjn, pred(ses_c) modx(climate_c) plot

* Stricter alpha
mlmjn, pred(ses_c) modx(climate_c) alpha(0.01)

/* ---------------------------------------------------------
   STEP 6: Interaction plot
   --------------------------------------------------------- */

di _newline as text "=== STEP 6: Interaction Plot ==="

* Default: lines at -1SD, Mean, +1SD with confidence bands
mlmplot, pred(ses_c) modx(climate_c) xlabel("Student SES (group-mean centred)") ylabel("Mathematics Achievement") legendtitle("School Climate")

* Quartile lines, no CI bands
mlmplot, pred(ses_c) modx(climate_c) values(quartiles) nointerval

* Custom moderator values
mlmplot, pred(ses_c) modx(climate_c) at(-1.5 0 1.5)

/* ---------------------------------------------------------
   STEP 7: Consolidated summary report
   --------------------------------------------------------- */

di _newline as text "=== STEP 7: Summary Report ==="

mlmsummary, pred(ses_c) modx(climate_c)

/* ---------------------------------------------------------
   STEP 8: Variance decomposition
   --------------------------------------------------------- */

di _newline as text "=== STEP 8: Variance Decomposition ==="

* Tabular decomposition at -1SD, Mean, +1SD
mlmvdecomp, pred(ses_c) modx(climate_c)

* With plot showing fixed CI vs prediction interval
mlmvdecomp, pred(ses_c) modx(climate_c) plot

/* ---------------------------------------------------------
   STEP 9: Robustness diagnostics

   ICC-shift: how does the interaction SE change across
              a range of plausible ICC values?
   LOCO:      leave-one-cluster-out stability check
              (refits model 30 times, takes ~30 seconds)
   --------------------------------------------------------- */

di _newline as text "=== STEP 9: Robustness Diagnostics ==="

* ICC-shift only (fast)
mlmsens, pred(ses_c) modx(climate_c) cluster(school) noloco

* ICC-shift with plot
mlmsens, pred(ses_c) modx(climate_c) cluster(school) noloco plot

* Full diagnostics including LOCO (slower ~30 sec)
mlmsens, pred(ses_c) modx(climate_c) cluster(school) verbose

/* ---------------------------------------------------------
   STEP 10: Minimal complete workflow (5 commands)
   --------------------------------------------------------- */

di _newline as text "=== STEP 10: Minimal Workflow ==="

clear all
set seed 2025
set obs 900
generate int    school  = ceil(_n / 30)
generate double ses     = rnormal(0, 1)
generate double climate = .
generate double u0      = .
forvalues j = 1/30 {
    replace climate = rnormal(0, 1)   if school == `j'
    replace u0      = rnormal(0, 0.5) if school == `j'
}
generate double math = 10 + 1.5*ses + 0.8*climate + 0.6*ses*climate + u0 + rnormal(0,1)

mlmcenter ses,     cluster(school) type(group)
mlmcenter climate, type(grand)
mixed math c.ses_c##c.climate_c || school:, reml
mlmsummary, pred(ses_c) modx(climate_c)
mlmplot,    pred(ses_c) modx(climate_c)

di _newline as text "========================================"
di          as text "=== mlmoderator demo complete        ==="
di          as text "========================================"

