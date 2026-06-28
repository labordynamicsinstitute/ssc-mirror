/*===========================================================================
 * example_paglayan.do - Staggered Adoption Design Example
 *
 * Replication of Paglayan (2019) analysis using diddesign (SA design).
 *
 * Data Description:
 *   Panel data of US states from 1959-2000. States adopted collective
 *   bargaining requirements at different times (staggered adoption).
 *
 * Variables:
 *   - state: State identifier (string)
 *   - year: Year (1959-2000)
 *   - treatment: Collective bargaining required (0/1)
 *   - pupil_expenditure: Per-pupil expenditure (current $)
 *   - teacher_salary: Average teacher salary
 *   - log_salary: Log teacher salary (pre-computed)
 *
 * Notes:
 *   - Use design(sa) for staggered adoption
 *   - id() and time() required; use panel structure
 *   - Never-treated states serve as the control group
 *
 * Reference:
 *   Paglayan (2019). "Public-Sector Unions and the Size of Government."
 *   American Journal of Political Science.
 *===========================================================================*/

version 16
clear all
set more off
capture log close

local outdir "output"
capture mkdir "`outdir'"
log using "`outdir'/example_paglayan.log", replace

/*---------------------------------------------------------------------------
 * Section 1: Data Loading and Preparation
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 1: DATA LOADING AND PREPARATION"
di as txt _dup(70) "=" _n

capture noisily sysuse paglayan2019, clear
if _rc != 0 {
    display as error "Error: paglayan2019.dta is not installed"
    display as error "Please run: net install diddesign, from(...)"
    exit _rc
}

// Basic data description
di as txt "Data Description:"
describe

// Summary statistics
di as txt _n "Summary Statistics:"
summarize treatment pupil_expenditure teacher_salary

// Create outcome variables for analysis
di as txt _n "Creating Log-Transformed Outcome Variables..."
gen log_expenditure = log(pupil_expenditure + 1)
// Note: log_salary already exists in dataset, no need to recreate
label variable log_expenditure "Log per-pupil expenditure"

// Create numeric state identifier (required for Mata)
di as txt "Creating Numeric State Identifier..."
encode state, gen(id_subject)
gen id_time = year

// Summary of transformed variables
summarize log_expenditure log_salary

/*---------------------------------------------------------------------------
 * Section 2: Treatment Pattern Exploration
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 2: TREATMENT PATTERN EXPLORATION"
di as txt _dup(70) "=" _n

// Treatment adoption summary
di as txt "Treatment Adoption by Year:"
tabulate year treatment

// First treatment year by state
preserve
collapse (min) first_treat_year = year if treatment == 1, by(state)
di as txt _n "First Treatment Year by State:"
list, sep(0)
restore

// Count of treated states over time
preserve
collapse (sum) n_treated = treatment, by(year)
di as txt _n "Number of Treated States by Year:"
list, sep(0)
restore

/*---------------------------------------------------------------------------
 * Section 3: Parallel Trends Assessment for SA Design
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 3: SA PARALLEL TRENDS ASSESSMENT"
di as txt _dup(70) "=" _n

// Set random seed for reproducibility
set seed 1234

// Check parallel trends with multiple lag periods
di as txt "Running SA parallel trends diagnostic..."

diddesign_check log_expenditure, ///
    treatment(treatment) ///
    id(id_subject) time(id_time) ///
    design(sa) ///
    lag(1 2 3 4 5) ///
    thres(1) ///
    nboot(200)

local placebo_raw1 = e(placebo)[1,4]
local placebo_eqci_lb1 = e(placebo)[1,6]
local placebo_eqci_ub1 = e(placebo)[1,7]

// Display results
di as txt _n "SA Placebo Test Results:"
matrix list e(placebo), format(%9.4f)


/*---------------------------------------------------------------------------
 * Section 4: SA Double DID Estimation
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 4: SA DOUBLE DID ESTIMATION"
di as txt _dup(70) "=" _n

set seed 1234

// Main SA estimation
di as txt "Running SA Double DID estimation..."
diddesign log_expenditure, ///
    treatment(treatment) ///
    id(id_subject) time(id_time) ///
    design(sa) ///
    thres(1) ///
    nboot(200)

local main_exp_est = e(estimates)[1,2]

// Display detailed results
// e(estimates) columns: [lead, estimate, std_error, ci_lo, ci_hi, weight]
// Row order: SA-Double-DID (row 1), SA-DID (row 2), SA-sDID (row 3)
di as txt _n "SA Estimation Results:"
di as txt _dup(50) "-"
di as txt "  SA-Double DID estimate: " %9.4f e(estimates)[1,2]
di as txt "  SA-DID estimate:        " %9.4f e(estimates)[2,2]
di as txt "  SA-sDID estimate:       " %9.4f e(estimates)[3,2]
di as txt _dup(50) "-"
di as txt "  Weight on SA-DID:       " %9.4f e(weights)[1,1]
di as txt "  Weight on SA-sDID:      " %9.4f e(weights)[1,2]
di as txt _dup(50) "-"

/*---------------------------------------------------------------------------
 * Section 5: Dynamic Effects with Multiple Lead Periods
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 5: SA DYNAMIC TREATMENT EFFECTS"
di as txt _dup(70) "=" _n

set seed 1234

// Estimate effects at multiple lead periods (0 through 9)
di as txt "Estimating dynamic treatment effects (lead 0-9)..."
diddesign log_expenditure, ///
    treatment(treatment) ///
    id(id_subject) time(id_time) ///
    design(sa) ///
    lead(0 1 2 3 4 5 6 7 8 9) ///
    thres(1) ///
    nboot(200)

di as txt _n "Dynamic Treatment Effects (SA Design):"
matrix list e(estimates), format(%9.4f)

// Interpretation

/*---------------------------------------------------------------------------
 * Section 6: Sensitivity to Threshold Parameter
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 6: SENSITIVITY TO THRESHOLD PARAMETER"
di as txt _dup(70) "=" _n

di as txt "thres() controls the minimum number of treated units per timing group."

// thres = 1 (include all groups)
set seed 1234
di as txt "thres(1) - Include all timing groups:"
diddesign log_expenditure, ///
    treatment(treatment) ///
    id(id_subject) time(id_time) ///
    design(sa) thres(1) nboot(100)
local est_thres1 = e(estimates)[1,2]
di as txt "  Double DID: " %9.4f `est_thres1'

// thres = 2 (require at least 2 treated units)
set seed 1234
di as txt _n "thres(2) - Require >= 2 treated units per group:"
diddesign log_expenditure, ///
    treatment(treatment) ///
    id(id_subject) time(id_time) ///
    design(sa) thres(2) nboot(100)
local est_thres2 = e(estimates)[1,2]
di as txt "  Double DID: " %9.4f `est_thres2'

// thres = 3
set seed 1234
di as txt _n "thres(3) - Require >= 3 treated units per group:"
diddesign log_expenditure, ///
    treatment(treatment) ///
    id(id_subject) time(id_time) ///
    design(sa) thres(3) nboot(100)
local est_thres3 = e(estimates)[1,2]
di as txt "  Double DID: " %9.4f `est_thres3'

di as txt _n "Sensitivity Summary:"
di as txt "  thres(1): " %9.4f `est_thres1'
di as txt "  thres(2): " %9.4f `est_thres2'
di as txt "  thres(3): " %9.4f `est_thres3'

/*---------------------------------------------------------------------------
 * Section 7: Visualization for SA Design
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 7: SA VISUALIZATION"
di as txt _dup(70) "=" _n

// First run diagnostic check for plot data
set seed 1234
diddesign_check log_expenditure, ///
    treatment(treatment) ///
    id(id_subject) time(id_time) ///
    design(sa) lag(1 2 3 4 5) thres(1) nboot(200)

// Treatment pattern plot (unique to SA design)
di as txt "Generating treatment pattern plot..."
diddesign_plot, type(pattern) saving("`outdir'/paglayan_pattern.png") replace

// Placebo plot
di as txt "Generating SA placebo plot..."
diddesign_plot, type(placebo) saving("`outdir'/paglayan_placebo.png") replace

// Combined plot
di as txt "Generating combined plot..."
diddesign_plot, type(both) saving("`outdir'/paglayan_combined.png") replace

/*---------------------------------------------------------------------------
 * Section 8: Alternative Outcome - Teacher Salary
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 8: ALTERNATIVE OUTCOME - TEACHER SALARY"
di as txt _dup(70) "=" _n

set seed 1234

di as txt "Estimating effect on log teacher salary..."
diddesign log_salary, ///
    treatment(treatment) ///
    id(id_subject) time(id_time) ///
    design(sa) ///
    thres(1) ///
    nboot(200)

local salary_est = e(estimates)[1,2]

di as txt _n "Effect on Log Teacher Salary:"
di as txt "  Double DID: " %9.4f e(estimates)[1,2]


/*---------------------------------------------------------------------------
 * Section 10: Comparison Summary
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 10: SUMMARY OF RESULTS"
di as txt _dup(70) "=" _n

di as txt "PAGLAYAN (2019) REPLICATION SUMMARY"
di as txt ""
di as txt "Research Question:"
di as txt "  Effect of collective bargaining requirements on education spending"
di as txt ""
di as txt "Key Findings:"
di as txt "  - SA-Double DID on log expenditure: " %9.4f `main_exp_est'
di as txt "  - SA-Double DID on log salary: " %9.4f `salary_est'
di as txt ""
di as txt "Parallel Trends Assessment:"
di as txt "  - Placebo diagnostic (lag 1): raw estimate = " %9.4f `placebo_raw1' ///
    as txt ", EqCI95 = [" %9.4f `placebo_eqci_lb1' as txt ", " %9.4f `placebo_eqci_ub1' as txt "]"
di as txt "  - Inspect the placebo and pattern plots above; the example does not impose a fixed pass/fail cutoff."
di as txt ""
di as txt "Robustness:"
di as txt "  - Threshold sensitivity on log expenditure: thres(1)=" %9.4f `est_thres1' ///
    as txt ", thres(2)=" %9.4f `est_thres2' as txt ", thres(3)=" %9.4f `est_thres3'

/*---------------------------------------------------------------------------
 * End of Example
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SA EXAMPLE COMPLETED SUCCESSFULLY"
di as txt _dup(70) "=" _n

log close
