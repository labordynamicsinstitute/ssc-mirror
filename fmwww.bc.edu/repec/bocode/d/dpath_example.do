/* ============================================================
   dpath — Stata Package: Full Workflow Example
   Hait, S. (2026). Decision Infrastructure Paradigm.
   Michigan State University
   ============================================================ */

clear all
set seed 2025

/* ── Simulate panel data: 200 students x 8 waves ───────────────────────── */
local N = 200
local T = 8

set obs `= `N' * `T''

// Generate IDs and waves
gen long studentid = ceil(_n / `T')
bysort studentid: gen int wave = _n

// SES quartile group
gen sesq = ""
replace sesq = "Q1" if mod(studentid, 4) == 1
replace sesq = "Q2" if mod(studentid, 4) == 2
replace sesq = "Q3" if mod(studentid, 4) == 3
replace sesq = "Q4" if mod(studentid, 4) == 0

// Latent risk (time-invariant per student)
bysort studentid: gen double risk = rnormal(0, 1) if _n == 1
bysort studentid: replace risk = risk[1]

// Time-varying covariate
gen double x = risk + rnormal(0, 0.5)

// AI decision flag (Type III: continuously adaptive threshold)
gen double threshold = 0.3 + 0.05 * wave + rnormal(0, 0.1)
gen byte ai_flag = (x > threshold)

// Outcome: influenced by AI decision and SES
gen double outcome = 0.5 * ai_flag + 0.3 * risk ///
    + (sesq == "Q4") * 0.2 + rnormal(0, 1)

label variable studentid "Student ID"
label variable wave      "Wave (semester)"
label variable sesq      "SES Quartile"
label variable ai_flag   "AI Decision Flag (0/1)"
label variable outcome   "Academic Outcome"

xtset studentid wave

di as result "Panel data created: `= `N' * `T'' observations"

/* ── Step 1: Build decision-path variables ─────────────────────────────── */
dpath build ai_flag, id(studentid) time(wave) group(sesq) outcome(outcome)

// Inspect new variables
list studentid wave ai_flag _dp_dosage _dp_switch _dp_path_str ///
    if studentid <= 3, sepby(studentid)

/* ── Step 2: Path descriptors ──────────────────────────────────────────── */
dpath describe, id(studentid) time(wave) by(sesq)

/* ── Step 3: Decision Reliability Index ────────────────────────────────── */
dpath dri, id(studentid) time(wave) by(sesq)
di "Overall DRI = " r(DRI)

/* ── Step 4: Shannon entropy ────────────────────────────────────────────── */
dpath entropy, id(studentid) time(wave) by(sesq) mutualinfo
di "Entropy H = " r(entropy) " bits"
di "Normalized H* = " r(normalized_entropy)

/* ── Step 5: Equity diagnostics ─────────────────────────────────────────── */
dpath equity, id(studentid) time(wave) by(sesq) ref(Q1)

/* ── Full audit (all five steps) ────────────────────────────────────────── */
dpath audit ai_flag, id(studentid) time(wave) by(sesq) ref(Q1) outcome(outcome)

/* ── Access stored scalars ──────────────────────────────────────────────── */
di "DRI              = " r(DRI)
di "Entropy (bits)   = " r(entropy)
di "Unique paths     = " r(n_unique_paths)
di "Mean dosage      = " r(mean_dosage)
di "Mean switch rate = " r(mean_switch)

/* ── Collapse to unit-level for further analysis ────────────────────────── */
preserve
bysort studentid (wave): keep if _n == _N

// Regression: predict dosage from SES
regress _dp_dosage i.sesq
// Dosage by SES group
tabstat _dp_dosage _dp_switch _dp_onset _dp_duration, ///
    by(sesq) stat(mean sd n)
restore

/* ============================================================
   End of example
   ============================================================ */
