* ============================================================================ *
* Stata CLI invocation through the MCHS adapter                                *
* ============================================================================ *
* This file exercises the CLI invocation pattern for Stata users.             *
* It does not contain calculator logic.                                       *
*                                                                             *
* Requirements:                                                                *
*   - funding-calculator CLI must be installed and on PATH                     *
*   - Python or Rust shared core must be available for CLI execution           *
* ============================================================================ *

* --- Option A: Invoke CLI with specific calculator and year ---
* local calc_id "acute"
* local year 2025
* mchs run using "./fixtures/acute/input.csv", ///
*     calculator(`calc_id') ///
*     year(`year') ///
*     output("`calc_id'_`year'.csv") ///
*     replace import clear
* mchs validate

* --- Option B: Use an explicit source-checkout CLI command ---
* mchs run using "./fixtures/ed/input.csv", ///
*     calculator(ed) ///
*     year(2025) ///
*     output("ed_2025.csv") ///
*     cli("python -m nwau_py.cli.main") ///
*     replace

* --- Diagnostics and provenance review ---
* describe
* list contract_version calculator_id pricing_year fixture_gate in 1/5

* --- Save as Stata-native .dta ---
* save results_2026.dta, replace

* ============================================================================ *
* End of illustrative skeleton                                                 *
* ============================================================================ *
