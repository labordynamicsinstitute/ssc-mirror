/*===========================================================================
 * example_kdid.do - Generalized K-DID Examples
 *
 * Demonstrates the K-DID extension from Appendix E of Egami & Yamauchi (2023).
 * Uses synthetic data to illustrate when and how K>2 components help.
 *
 * Contents:
 *   Part 1: Basic K-DID — no confounding (all k agree)
 *   Part 2: Linear confounding — k=2,3 correct, k=1 biased
 *   Part 3: Quadratic confounding — k=3 correct, k=1,2 biased
 *   Part 4: J-test moment selection
 *   Part 5: SA K-DID with Paglayan (2019) data
 *
 * Key concepts:
 *   - kmax(K) combines K component estimators via GMM
 *   - k=1: standard parallel trends (constant confounding)
 *   - k=2: parallel trends-in-trends (linear confounding)
 *   - k=3: 2nd-order parallel trends (quadratic confounding)
 *   - jtest(on): Hansen J-test for adaptive moment selection
 *
 * Reference:
 *   Egami, N. & Yamauchi, S. (2023). Using Multiple Pretreatment Periods
 *   to Improve Difference-in-Differences and Staggered Adoption Designs.
 *   Political Analysis 31(2): 195-212.
 *===========================================================================*/

version 16
clear all
set more off

/*---------------------------------------------------------------------------
 * Part 1: Basic K-DID — No Confounding
 *
 * DGP: Y = 5 + 1.5*Gi + 0.3*t + ATT*Gi*1(t>=0) + eps
 * True ATT = 2.0
 * No confounding: all k=1,2,3 should recover ATT ≈ 2.0
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "PART 1: BASIC K-DID — NO CONFOUNDING (ATT = 2.0)"
di as txt _dup(70) "=" _n

set seed 2024
local N = 400
local T = 7
quietly {
    set obs `=`N'*`T''
    gen id = ceil(_n/`T')
    bysort id: gen t = _n - 5                // -4,-3,-2,-1,0,1,2
    gen Gi = (id <= `=`N'/2')
    gen treatment = Gi * (t >= 0)
    gen year = 2010 + t
    gen Y = 5 + 1.5*Gi + 0.3*t + 2.0*Gi*(t>=0) + rnormal(0, 0.5)
}

di as txt "Data: `N' units, `T' periods (-4 to +2), treatment at t=0"
di as txt "DGP:  Y = 5 + 1.5*Gi + 0.3*t + 2.0*Gi*1(t>=0) + N(0, 0.5)"
di as txt "True ATT = 2.0, no confounding" _n

* Standard K=2 (backward-compatible Double DID)
di as txt "--- kmax(2): Standard Double DID ---"
diddesign Y, treatment(treatment) time(year) id(id) nboot(200) seed(42)

* K=3: Generalized K-DID
di as txt _n "--- kmax(3): Generalized K-DID ---"
diddesign Y, treatment(treatment) time(year) id(id) nboot(200) seed(42) kmax(3)

di as txt _n "Note: Under no confounding, all three components (k=1,2,3)"
di as txt "should produce similar estimates near the true ATT = 2.0."

/*---------------------------------------------------------------------------
 * Part 2: Linear Confounding
 *
 * DGP: Y = 5 + 1.5*Gi + 0.3*t + 0.5*Gi*t + ATT*Gi*1(t>=0) + eps
 * The 0.5*Gi*t term creates linear time-varying confounding.
 * True ATT = 1.0
 *
 * Expected behavior:
 *   k=1 (DID): BIASED — violates parallel trends
 *   k=2 (sDID): Unbiased — accounts for linear confounding
 *   k=3: Unbiased — also accounts for linear confounding
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "PART 2: LINEAR CONFOUNDING (ATT = 1.0)"
di as txt _dup(70) "=" _n

clear
set seed 2024
local N = 400
local T = 7
quietly {
    set obs `=`N'*`T''
    gen id = ceil(_n/`T')
    bysort id: gen t = _n - 5
    gen Gi = (id <= `=`N'/2')
    gen treatment = Gi * (t >= 0)
    gen year = 2010 + t
    gen Y = 5 + 1.5*Gi + 0.3*t + 0.5*Gi*t + 1.0*Gi*(t>=0) + rnormal(0, 0.5)
}

di as txt "DGP:  Y = 5 + 1.5*Gi + 0.3*t + 0.5*Gi*t + 1.0*Gi*1(t>=0) + eps"
di as txt "True ATT = 1.0, linear confounding (0.5*Gi*t)" _n

di as txt "--- kmax(3): K-DID under linear confounding ---"
diddesign Y, treatment(treatment) time(year) id(id) nboot(200) seed(42) kmax(3)

di as txt _n "Expected: k=1 is biased (estimate > 1.0),"
di as txt "          k=2 and k=3 are approximately unbiased."

/*---------------------------------------------------------------------------
 * Part 3: Quadratic Confounding
 *
 * DGP: Y = 5 + 1.5*Gi + 0.3*t + 0.3*Gi*t + 0.15*Gi*t^2 + ATT + eps
 * The 0.15*Gi*t^2 term creates quadratic time-varying confounding.
 * True ATT = 1.0
 *
 * Expected behavior:
 *   k=1 (DID): BIASED
 *   k=2 (sDID): BIASED — linear correction is insufficient
 *   k=3: Unbiased — accounts for quadratic confounding
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "PART 3: QUADRATIC CONFOUNDING (ATT = 1.0)"
di as txt _dup(70) "=" _n

clear
set seed 2024
local N = 600
local T = 7
quietly {
    set obs `=`N'*`T''
    gen id = ceil(_n/`T')
    bysort id: gen t = _n - 5
    gen Gi = (id <= `=`N'/2')
    gen treatment = Gi * (t >= 0)
    gen year = 2010 + t
    gen Y = 5 + 1.5*Gi + 0.3*t + 0.3*Gi*t + 0.15*Gi*t^2 ///
            + 1.0*Gi*(t>=0) + rnormal(0, 0.5)
}

di as txt "DGP:  Y = 5 + 1.5*Gi + 0.3*t + 0.3*Gi*t + 0.15*Gi*t^2"
di as txt "        + 1.0*Gi*1(t>=0) + eps"
di as txt "True ATT = 1.0, quadratic confounding (0.15*Gi*t^2)" _n

di as txt "--- kmax(3): K-DID under quadratic confounding ---"
diddesign Y, treatment(treatment) time(year) id(id) nboot(200) seed(42) kmax(3)

di as txt _n "Expected: k=1 and k=2 are biased,"
di as txt "          k=3 is approximately unbiased (removes quadratic trend)."
di as txt "This is the key advantage of using K>2 pre-treatment periods."

/*---------------------------------------------------------------------------
 * Part 4: J-test Moment Selection
 *
 * Under strong linear confounding, the J-test should detect that k=1
 * (standard parallel trends) is violated and drop it, keeping k=2,3.
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "PART 4: J-TEST MOMENT SELECTION"
di as txt _dup(70) "=" _n

clear
set seed 2024
local N = 600
local T = 7
quietly {
    set obs `=`N'*`T''
    gen id = ceil(_n/`T')
    bysort id: gen t = _n - 5
    gen Gi = (id <= `=`N'/2')
    gen treatment = Gi * (t >= 0)
    gen year = 2010 + t
    gen Y = 5 + 1.5*Gi + 0.3*t + 1.0*Gi*t + 1.0*Gi*(t>=0) + rnormal(0, 0.3)
}

di as txt "DGP: Strong linear confounding (1.0*Gi*t)"
di as txt "True ATT = 1.0" _n

di as txt "--- Without J-test: kmax(3) ---"
diddesign Y, treatment(treatment) time(year) id(id) nboot(300) seed(42) kmax(3)
matrix est_nojtest = e(estimates)

di as txt _n "--- With J-test: kmax(3) jtest(on) ---"
diddesign Y, treatment(treatment) time(year) id(id) nboot(300) seed(42) ///
    kmax(3) jtest(on)

di as txt _n "The J-test adaptively selects which moment conditions to use."
di as txt "Under strong linear confounding, it should drop k=1 (standard PT)"
di as txt "and retain k=2,3 (which require weaker assumptions)."

capture confirm matrix e(k_summary)
if _rc == 0 {
    matrix ks = e(k_summary)
    di as txt _n "K_init = " ks[1,1] ", K_final = " ks[1,3]
}

capture confirm matrix e(jtest_stats)
if _rc == 0 {
    matrix js = e(jtest_stats)
    di as txt "J-statistic = " %6.3f js[1,1] ", p-value = " %6.4f js[1,3]
}

/*---------------------------------------------------------------------------
 * Part 5: SA K-DID with Paglayan (2019) Data
 *
 * The Paglayan dataset has ~40 years of panel data with staggered adoption.
 * Each treatment cohort has many pre-treatment periods, enabling SA K-DID.
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "PART 5: STAGGERED ADOPTION K-DID (PAGLAYAN 2019)"
di as txt _dup(70) "=" _n

capture noisily sysuse paglayan2019, clear
if _rc != 0 {
    capture use paglayan2019, clear
}
if _rc != 0 {
    di as err "paglayan2019.dta not found; skipping Part 5"
}
else {
    gen log_expenditure = log(pupil_expenditure + 1)
    encode state, gen(id_subject)

    di as txt "Data: US states, 1959-2000, staggered adoption of"
    di as txt "      collective bargaining requirements for teachers" _n

    * Standard SA (kmax=2)
    di as txt "--- SA design, kmax(2): Standard SA Double DID ---"
    diddesign log_expenditure, treatment(treatment) id(id_subject) time(year) ///
        design(sa) thres(1) nboot(200) seed(42)

    * SA K-DID (kmax=3)
    di as txt _n "--- SA design, kmax(3): SA K-DID ---"
    diddesign log_expenditure, treatment(treatment) id(id_subject) time(year) ///
        design(sa) thres(1) nboot(200) seed(42) kmax(3)

    di as txt _n "The SA K-DID extends the basic SA Double DID by allowing for"
    di as txt "higher-order polynomial time-varying confounding across cohorts."
}

/*---------------------------------------------------------------------------
 * Summary
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SUMMARY: WHEN TO USE K-DID"
di as txt _dup(70) "="
di as txt ""
di as txt "  kmax(2) — Default. Standard Double DID."
di as txt "            Handles constant and linear time-varying confounding."
di as txt ""
di as txt "  kmax(3) — Use when 3+ pre-treatment periods are available and"
di as txt "            there is concern about quadratic confounding trends."
di as txt "            The k=3 component is unbiased under quadratic confounding"
di as txt "            where k=1 and k=2 would be biased."
di as txt ""
di as txt "  jtest(on) — Adaptive moment selection via Hansen J-test."
di as txt "              Automatically drops violated moment conditions."
di as txt "              Recommended when unsure which assumptions hold."
di as txt ""
di as txt "  design(sa) kmax(3) — SA K-DID for staggered adoption designs."
di as txt "                        Combines K-DID with time-weighted SA aggregation."
