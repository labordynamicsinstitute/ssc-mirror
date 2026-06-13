* ============================================================================ *
* Stata file-import workflow through the MCHS adapter                          *
* ============================================================================ *
* This file exercises the CSV file-import pattern for Stata users.            *
* It does not contain calculator logic.                                       *
* ============================================================================ *

* --- Option A: Import CSV from shared-core output ---
* mchs import using "./fixtures/outpatients/output.csv", clear
* mchs validate
* describe
* list in 1/5

* --- Option B: Import Parquet directly when the community package is present ---
* parquet using "./fixtures/outpatients/output.parquet", clear
* describe
* list in 1/5

* --- Option C: Import CSV with frame comparison ---
* mchs import using "./fixtures/acute/output_2026.csv", clear
* frame create expected
* frame expected: import delimited using "./fixtures/acute/expected_2026.csv", clear
* cf _all using expected, verbose

* --- DTA export for downstream analysis ---
* save "./analysis/acute_results_2026.dta", replace

* ============================================================================ *
* End of illustrative skeleton                                                 *
* ============================================================================ *
