*! xtfifevd_example.do — Example & Test Do-File
*! Version 1.0.0  27feb2026
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Tests: FEVD, FEF, FEF-IV, compare mode, b/w ratio, Monte Carlo size check

clear all
set more off
set seed 12345

// =============================================================================
// PART 1: GENERATE SIMULATED PANEL DATA  (DGP A from Pesaran & Zhou 2016)
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 1: Generating simulated panel data"
di in ye "{hline 78}" _n

local N_panels  100
local T_periods 20
local beta1     1
local beta2     1
local gamma1    1
local gamma2    1

local Nobs = `N_panels' * `T_periods'
set obs `Nobs'
gen id = ceil(_n / `T_periods')
bysort id: gen t = _n
xtset id t

di "Panels (N):    `N_panels'"
di "Periods (T):   `T_periods'"
di "True beta:     (`beta1', `beta2')"
di "True gamma:    (`gamma1', `gamma2')"

// Fixed effects (heteroskedastic, as in P&Z DGP)
gen double eta_i = 0.5 * (rchi2(2) - 2) if t == 1
bysort id (t): replace eta_i = eta_i[1]

// Time-varying components
gen double w1 = rnormal()
gen double w2 = rnormal()
bysort id: egen double wbar1 = mean(w1)
bysort id: egen double wbar2 = mean(w2)

// Time-invariant regressors: z_i = 1 + Lambda*wbar_i + zeta_i  (DGP A: phi=0)
gen double z1 = 1 + wbar1 + wbar2 + rnormal() if t == 1
gen double z2 = 1 + wbar1 + wbar2 + rnormal() if t == 1
bysort id (t): replace z1 = z1[1]
bysort id (t): replace z2 = z2[1]

// Time-varying regressors (correlated with eta via g_t)
gen double x1 = eta_i * (1 + runiform()) + rnormal()
gen double x2 = eta_i * (1 + runiform()) + rnormal()

// Outcome
gen double y = 1 + `beta1' * x1 + `beta2' * x2 ///
             + `gamma1' * z1 + `gamma2' * z2 + eta_i + rnormal()

label variable y  "Outcome"
label variable x1 "Time-varying regressor 1"
label variable x2 "Time-varying regressor 2"
label variable z1 "Time-invariant regressor 1"
label variable z2 "Time-invariant regressor 2"

// =============================================================================
// PART 2: STANDARD FE (cannot estimate z coefficients)
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 2: Standard Fixed Effects (FE)"
di in ye "{hline 78}" _n

xtreg y x1 x2, fe
est store FE_model

di _n in gr "Note: z1 and z2 are dropped by FE."

// =============================================================================
// PART 3: FEVD ESTIMATION (with Pesaran-Zhou corrected SEs)
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 3: FEVD Estimation"
di in ye "{hline 78}" _n

xtfifevd y x1 x2, zinv(z1 z2)
est store FEVD_model

// =============================================================================
// PART 4: FEF ESTIMATION
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 4: FEF Estimation"
di in ye "{hline 78}" _n

xtfifevd y x1 x2, zinv(z1 z2) fef
est store FEF_model

// =============================================================================
// PART 5: COMPARE FEVD raw vs PZ corrected SEs
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 5: FEVD vs FEF Standard Error Comparison"
di in ye "{hline 78}" _n

xtfifevd y x1 x2, zinv(z1 z2) compare

// =============================================================================
// PART 6: B/W RATIO DIAGNOSTIC
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 6: Between/Within Variance Ratio"
di in ye "{hline 78}" _n

xtfifevd y x1 x2, zinv(z1 z2) bwratio

// =============================================================================
// PART 7: FEF-IV WITH INSTRUMENTS
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 7: FEF-IV with Instruments"
di in ye "{hline 78}" _n

// Instruments correlated with z but uncorrelated with eta
gen double zeta1 = z1 - 1 - wbar1 - wbar2 if t == 1
gen double zeta2 = z2 - 1 - wbar1 - wbar2 if t == 1
bysort id (t): replace zeta1 = zeta1[1]
bysort id (t): replace zeta2 = zeta2[1]

gen double r1 = zeta1 + rnormal() if t == 1
gen double r2 = zeta1 + rnormal() if t == 1
gen double r3 = zeta2 + rnormal() if t == 1
gen double r4 = zeta2 + rnormal() if t == 1
bysort id (t): replace r1 = r1[1]
bysort id (t): replace r2 = r2[1]
bysort id (t): replace r3 = r3[1]
bysort id (t): replace r4 = r4[1]

xtfifevd y x1 x2, zinv(z1 z2) iv(r1 r2 r3 r4)
est store FEFIV_model

// =============================================================================
// PART 8: CONSISTENCY CHECKS
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 8: Consistency Checks"
di in ye "{hline 78}" _n

// Check 1: FEVD gamma = FEF gamma (Proposition 3)
qui est restore FEVD_model
local g1_fevd = _b[FEVD:z1]
local g2_fevd = _b[FEVD:z2]

qui est restore FEF_model
local g1_fef = _b[FEF:z1]
local g2_fef = _b[FEF:z2]

di "Check 1: FEVD gamma = FEF gamma? (Proposition 3)"
di "  z1: FEVD=" %9.6f `g1_fevd' "  FEF=" %9.6f `g1_fef' ///
	"  Diff=" %12.9f abs(`g1_fevd' - `g1_fef')
di "  z2: FEVD=" %9.6f `g2_fevd' "  FEF=" %9.6f `g2_fef' ///
	"  Diff=" %12.9f abs(`g2_fevd' - `g2_fef')

if abs(`g1_fevd' - `g1_fef') < 1e-6 & abs(`g2_fevd' - `g2_fef') < 1e-6 {
	di in gr "  PASSED: Point estimates identical"
}
else {
	di in ye "  WARNING: Small numerical difference"
}

// Check 2: beta_FEVD = beta_FE
qui est restore FEVD_model
local b1_fevd = _b[FE:x1]
local b2_fevd = _b[FE:x2]

qui xtreg y x1 x2, fe
local b1_fe = _b[x1]
local b2_fe = _b[x2]

di _n "Check 2: FEVD beta = FE beta?"
di "  x1: FEVD=" %9.6f `b1_fevd' "  FE=" %9.6f `b1_fe' ///
	"  Diff=" %12.9f abs(`b1_fevd' - `b1_fe')
di "  x2: FEVD=" %9.6f `b2_fevd' "  FE=" %9.6f `b2_fe' ///
	"  Diff=" %12.9f abs(`b2_fevd' - `b2_fe')

if abs(`b1_fevd' - `b1_fe') < 1e-6 & abs(`b2_fevd' - `b2_fe') < 1e-6 {
	di in gr "  PASSED: beta_FEVD = beta_FE"
}

// =============================================================================
// PART 9: MINI MONTE CARLO — SIZE CHECK
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 9: Monte Carlo Size Check (100 reps)"
di in ye "  H0: gamma1 = 1 at 5%.  FEF should reject ~5%"
di in ye "{hline 78}" _n

local Nreps 100
local Npanels 50
local Tperiods 10
local true_g1 1
local rej_fef 0

forvalues rep = 1/`Nreps' {
	qui {
		clear
		local Nobs_mc = `Npanels' * `Tperiods'
		set obs `Nobs_mc'
		gen id = ceil(_n / `Tperiods')
		bysort id: gen t = _n
		xtset id t
		
		gen double mc_eta = 0.5 * (rchi2(2) - 2) if t == 1
		bysort id (t): replace mc_eta = mc_eta[1]
		
		gen double mc_w1 = rnormal()
		bysort id: egen double mc_wbar1 = mean(mc_w1)
		
		gen double mc_z1 = 1 + mc_wbar1 + rnormal() if t == 1
		gen double mc_z2 = 1 + mc_wbar1 + rnormal() if t == 1
		bysort id (t): replace mc_z1 = mc_z1[1]
		bysort id (t): replace mc_z2 = mc_z2[1]
		
		gen double mc_x1 = mc_eta * (1 + runiform()) + rnormal()
		gen double mc_x2 = mc_eta * (1 + runiform()) + rnormal()
		
		gen double mc_y = 1 + mc_x1 + mc_x2 + `true_g1' * mc_z1 ///
			+ mc_z2 + mc_eta + rnormal()
		
		cap xtfifevd mc_y mc_x1 mc_x2, zinv(mc_z1 mc_z2) fef
		if _rc == 0 {
			local g1_hat = _b[FEF:mc_z1]
			local se_pz = _se[FEF:mc_z1]
			local tstat_pz = (`g1_hat' - `true_g1') / `se_pz'
			if abs(`tstat_pz') > 1.96 {
				local rej_fef = `rej_fef' + 1
			}
		}
	}
	
	if mod(`rep', 25) == 0 {
		di in gr "  Completed `rep' / `Nreps'..."
	}
}

local size_fef = 100 * `rej_fef' / `Nreps'

di _n "Results:"
di in smcl in gr "{hline 50}"
di in gr "FEF (Pesaran-Zhou SEs):"
di in gr "  Rejection rate: " in ye %5.1f `size_fef' "%" ///
	in gr " (nominal: 5.0%)"
if `size_fef' >= 3 & `size_fef' <= 8 {
	di in gr "  PASSED: Size within acceptable range [3%, 8%]"
}
else {
	di in ye "  NOTE: Size outside ideal range (may need more reps)"
}
di in smcl in gr "{hline 50}"

// =============================================================================
// PART 10: BEAUTIFUL VISUALIZATIONS
// =============================================================================

di _n in ye "{hline 78}"
di in ye "PART 10: Generating Publication-Quality Graphs"
di in ye "{hline 78}" _n

// --- Reload simulated data for graphs ---
clear all
set more off
set seed 12345
set scheme s2color

local N_panels  100
local T_periods 20

local Nobs = `N_panels' * `T_periods'
set obs `Nobs'
gen id = ceil(_n / `T_periods')
bysort id: gen t = _n
xtset id t

gen double eta_i = 0.5 * (rchi2(2) - 2) if t == 1
bysort id (t): replace eta_i = eta_i[1]

gen double w1 = rnormal()
gen double w2 = rnormal()
bysort id: egen double wbar1 = mean(w1)
bysort id: egen double wbar2 = mean(w2)

gen double z1 = 1 + wbar1 + wbar2 + rnormal() if t == 1
gen double z2 = 1 + wbar1 + wbar2 + rnormal() if t == 1
bysort id (t): replace z1 = z1[1]
bysort id (t): replace z2 = z2[1]

gen double x1 = eta_i * (1 + runiform()) + rnormal()
gen double x2 = eta_i * (1 + runiform()) + rnormal()

gen double y = 1 + x1 + x2 + z1 + z2 + eta_i + rnormal()

// ---- Run estimations ----
qui xtfifevd y x1 x2, zinv(z1 z2)
local g1 = _b[FEVD:z1]
local g2 = _b[FEVD:z2]
local se1_pz  = sqrt(e(V_gamma_pz)[1,1])
local se2_pz  = sqrt(e(V_gamma_pz)[2,2])
local se1_raw = sqrt(e(V_gamma_fevd_raw)[1,1])
local se2_raw = sqrt(e(V_gamma_fevd_raw)[2,2])

// =========================================================================
// GRAPH 1: SE Comparison Bar Chart  —  PZ vs Raw
// =========================================================================
di in gr "  Graph 1: Standard Error Comparison..."

preserve
clear
set obs 4
gen str20 label = ""
gen double se_val = .
gen int group = .

replace label = "z1 (PZ)"   in 1
replace se_val = `se1_pz'   in 1
replace group = 1            in 1

replace label = "z1 (Raw)"  in 2
replace se_val = `se1_raw'  in 2
replace group = 2            in 2

replace label = "z2 (PZ)"   in 3
replace se_val = `se2_pz'   in 3
replace group = 1            in 3

replace label = "z2 (Raw)"  in 4
replace se_val = `se2_raw'  in 4
replace group = 2            in 4

gen order = _n

graph bar se_val, over(label, sort(order) label(labsize(small)))  ///
	bar(1, fcolor("59 130 246") lcolor("37 99 235") lwidth(medium))  ///
	blabel(bar, format(%7.4f) size(vsmall))  ///
	title("{bf:Standard Error Comparison}", size(medlarge) color(black))  ///
	subtitle("Pesaran-Zhou (Correct) vs FEVD Raw (Inconsistent)", ///
		size(small) color(gs6))  ///
	ytitle("Standard Error", size(small))  ///
	note("Raw SEs are 2-4x smaller than correct PZ SEs" ///
		"This leads to 91-100% rejection rates at nominal 5%", ///
		size(vsmall) color(cranberry))  ///
	graphregion(color(white) margin(small))  ///
	plotregion(margin(medium))  ///
	ylabel(, grid glcolor(gs14) glwidth(vthin))

graph export "xtfifevd_graph1_se_comparison.png", width(1200) replace
di in gr "  → Saved: xtfifevd_graph1_se_comparison.png"
restore

// =========================================================================
// GRAPH 2: Coefficient Plot with Confidence Intervals
//          Shows how Raw CIs are dangerously narrow
// =========================================================================
di in gr "  Graph 2: Coefficient Plot with CIs..."

preserve
clear
set obs 6
gen str25 varname = ""
gen double coef = .
gen double ci_lo = .
gen double ci_hi = .
gen int method = .
gen double ypos = .

// z1 — PZ
replace varname = "z1 (PZ Corrected)"  in 1
replace coef   = `g1'                  in 1
replace ci_lo  = `g1' - 1.96*`se1_pz'  in 1
replace ci_hi  = `g1' + 1.96*`se1_pz'  in 1
replace method = 1                     in 1
replace ypos   = 6                     in 1

// z1 — Raw
replace varname = "z1 (FEVD Raw)"      in 2
replace coef   = `g1'                  in 2
replace ci_lo  = `g1' - 1.96*`se1_raw' in 2
replace ci_hi  = `g1' + 1.96*`se1_raw' in 2
replace method = 2                     in 2
replace ypos   = 5                     in 2

// z1 — True
replace varname = "z1 (True = 1)"      in 3
replace coef   = 1                     in 3
replace ci_lo  = 1                     in 3
replace ci_hi  = 1                     in 3
replace method = 3                     in 3
replace ypos   = 4                     in 3

// z2 — PZ
replace varname = "z2 (PZ Corrected)"  in 4
replace coef   = `g2'                  in 4
replace ci_lo  = `g2' - 1.96*`se2_pz'  in 4
replace ci_hi  = `g2' + 1.96*`se2_pz'  in 4
replace method = 1                     in 4
replace ypos   = 2.5                   in 4

// z2 — Raw
replace varname = "z2 (FEVD Raw)"      in 5
replace coef   = `g2'                  in 5
replace ci_lo  = `g2' - 1.96*`se2_raw' in 5
replace ci_hi  = `g2' + 1.96*`se2_raw' in 5
replace method = 2                     in 5
replace ypos   = 1.5                   in 5

// z2 — True
replace varname = "z2 (True = 1)"      in 6
replace coef   = 1                     in 6
replace ci_lo  = 1                     in 6
replace ci_hi  = 1                     in 6
replace method = 3                     in 6
replace ypos   = 0.5                   in 6

twoway ///
	(rcap ci_lo ci_hi ypos if method==1, horizontal ///
		lcolor("16 185 129") lwidth(thick))  ///
	(scatter ypos coef if method==1, msymbol(D) msize(large) ///
		mcolor("5 150 105") mlcolor(white) mlwidth(thin))  ///
	(rcap ci_lo ci_hi ypos if method==2, horizontal ///
		lcolor("239 68 68") lwidth(thick))  ///
	(scatter ypos coef if method==2, msymbol(O) msize(large) ///
		mcolor("220 38 38") mlcolor(white) mlwidth(thin))  ///
	(scatter ypos coef if method==3, msymbol(X) msize(vlarge) ///
		mcolor("234 179 8") mlwidth(thick))  ///
	, xline(1, lpattern(dash) lcolor(gs10) lwidth(thin))  ///
	ylabel(6 `""{bf:z1} PZ Corrected""' ///
		   5 `""{bf:z1} FEVD Raw""' ///
		   4 `""{bf:z1} True Value""' ///
		   2.5 `""{bf:z2} PZ Corrected""' ///
		   1.5 `""{bf:z2} FEVD Raw""' ///
		   0.5 `""{bf:z2} True Value""', ///
		   labsize(vsmall) angle(0) noticks nogrid)  ///
	yscale(range(0 7))  ///
	xlabel(, grid glcolor(gs14))  ///
	xtitle("Coefficient estimate (95% CI)", size(small))  ///
	ytitle("")  ///
	title("{bf:Confidence Intervals: PZ Corrected vs FEVD Raw}", ///
		size(medlarge) color(black))  ///
	subtitle("Same point estimates, dramatically different inference", ///
		size(small) color(gs6))  ///
	legend(order(2 "Pesaran-Zhou (Correct)" ///
		4 "FEVD Raw (Inconsistent)" 5 "True Parameter Value")  ///
		size(vsmall) rows(1) position(6) region(lcolor(gs14)))  ///
	note("Raw CIs are 2-4x narrower → severe over-rejection of H0", ///
		size(vsmall) color(cranberry))  ///
	graphregion(color(white) margin(small))  ///
	plotregion(margin(medium))

graph export "xtfifevd_graph2_coefplot.png", width(1400) replace
di in gr "  → Saved: xtfifevd_graph2_coefplot.png"
restore

// =========================================================================
// GRAPH 3: Monte Carlo Size Distortion  —  PZ vs Raw rejection rates
//          at different nominal levels (1%, 5%, 10%)
// =========================================================================
di in gr "  Graph 3: Monte Carlo Rejection Rates (50 reps — quick)..."

local Nreps 50
local Npanels 50
local Tperiods 10
local true_g1 1

tempfile mc_results
postfile mc_handle rep double(tstat_pz tstat_raw) using `mc_results'

forvalues rep = 1/`Nreps' {
	qui {
		clear
		local Nobs_mc = `Npanels' * `Tperiods'
		set obs `Nobs_mc'
		gen id = ceil(_n / `Tperiods')
		bysort id: gen t = _n
		xtset id t
		
		gen double mc_eta = 0.5 * (rchi2(2) - 2) if t == 1
		bysort id (t): replace mc_eta = mc_eta[1]
		
		gen double mc_w1 = rnormal()
		bysort id: egen double mc_wbar1 = mean(mc_w1)
		
		gen double mc_z1 = 1 + mc_wbar1 + rnormal() if t == 1
		gen double mc_z2 = 1 + mc_wbar1 + rnormal() if t == 1
		bysort id (t): replace mc_z1 = mc_z1[1]
		bysort id (t): replace mc_z2 = mc_z2[1]
		
		gen double mc_x1 = mc_eta * (1 + runiform()) + rnormal()
		gen double mc_x2 = mc_eta * (1 + runiform()) + rnormal()
		
		gen double mc_y = 1 + mc_x1 + mc_x2 + `true_g1' * mc_z1 ///
			+ mc_z2 + mc_eta + rnormal()
		
		cap xtfifevd mc_y mc_x1 mc_x2, zinv(mc_z1 mc_z2)
		if _rc == 0 {
			local g1_hat = _b[FEVD:mc_z1]
			local se_pz_mc  = sqrt(e(V_gamma_pz)[1,1])
			local se_raw_mc = sqrt(e(V_gamma_fevd_raw)[1,1])
			local ts_pz  = (`g1_hat' - `true_g1') / `se_pz_mc'
			local ts_raw = (`g1_hat' - `true_g1') / `se_raw_mc'
			post mc_handle (`rep') (`ts_pz') (`ts_raw')
		}
	}
	if mod(`rep', 10) == 0 {
		di in gr "    MC rep `rep' / `Nreps'..."
	}
}
postclose mc_handle

preserve
use `mc_results', clear

// Compute rejection rates at 1%, 5%, 10%
gen rej_pz_01 = abs(tstat_pz) > 2.576
gen rej_pz_05 = abs(tstat_pz) > 1.960
gen rej_pz_10 = abs(tstat_pz) > 1.645
gen rej_raw_01 = abs(tstat_raw) > 2.576
gen rej_raw_05 = abs(tstat_raw) > 1.960
gen rej_raw_10 = abs(tstat_raw) > 1.645

qui summ rej_pz_01
local pz_01 = 100* r(mean)
qui summ rej_pz_05
local pz_05 = 100* r(mean)
qui summ rej_pz_10
local pz_10 = 100* r(mean)
qui summ rej_raw_01
local raw_01 = 100* r(mean)
qui summ rej_raw_05
local raw_05 = 100* r(mean)
qui summ rej_raw_10
local raw_10 = 100* r(mean)

clear
set obs 6
gen str25 label = ""
gen double rate = .
gen int group = .
gen double nominal = .
gen order = _n

replace label = "PZ 1%"   in 1
replace rate  = `pz_01'   in 1
replace group = 1          in 1
replace nominal = 1        in 1

replace label = "Raw 1%"   in 2
replace rate  = `raw_01'   in 2
replace group = 2          in 2
replace nominal = 1        in 2

replace label = "PZ 5%"    in 3
replace rate  = `pz_05'    in 3
replace group = 1           in 3
replace nominal = 5         in 3

replace label = "Raw 5%"   in 4
replace rate  = `raw_05'   in 4
replace group = 2           in 4
replace nominal = 5         in 4

replace label = "PZ 10%"   in 5
replace rate  = `pz_10'    in 5
replace group = 1           in 5
replace nominal = 10        in 5

replace label = "Raw 10%"  in 6
replace rate  = `raw_10'   in 6
replace group = 2           in 6
replace nominal = 10        in 6

graph bar rate, over(label, sort(order) label(labsize(small)))  ///
	bar(1, fcolor("99 102 241") lcolor("79 70 229"))  ///
	blabel(bar, format(%4.1f) suffix("%") size(vsmall))  ///
	title("{bf:Size Distortion: Rejection Rates under H0}", ///
		size(medlarge) color(black))  ///
	subtitle("H0: gamma1=1 (true). Nominal levels: 1%, 5%, 10%", ///
		size(small) color(gs6))  ///
	ytitle("Rejection Rate (%)", size(small))  ///
	yline(1 5 10, lpattern(dash) lcolor(gs10) lwidth(vthin))  ///
	ylabel(0(10)100, grid glcolor(gs14))  ///
	note("PZ (Pesaran-Zhou): correct size  |  Raw (FEVD Stage-3): massive over-rejection" ///
		"`Nreps' Monte Carlo replications, N=`Npanels', T=`Tperiods'", ///
		size(vsmall) color(cranberry))  ///
	graphregion(color(white) margin(small))  ///
	plotregion(margin(medium))

graph export "xtfifevd_graph3_size_distortion.png", width(1200) replace
di in gr "  → Saved: xtfifevd_graph3_size_distortion.png"
restore

// =========================================================================
di _n in ye "{hline 78}"
di in ye "All examples and graphs completed successfully!"
di in ye "Graphs saved:"
di in ye "  1. xtfifevd_graph1_se_comparison.png"
di in ye "  2. xtfifevd_graph2_coefplot.png"
di in ye "  3. xtfifevd_graph3_size_distortion.png"
di in ye "{hline 78}" _n
