/* ==============================================================================
   compile_all.do --- Compile all TROP Mata source files in dependency order.

   Exits with error 198 if any file fails to compile.
   Pass --ci or set the CI environment variable for machine-readable output.

   Usage:
     stata-mp -b do trop_stata/mata/compile_all.do
     stata-mp -b do trop_stata/mata/compile_all.do --ci
   ============================================================================== */

clear all
set more off

// --- Locate Mata source directory --------------------------------------------
// Probe candidate paths for trop_constants.mata to resolve the source directory.

local mata_dir ""
local search_paths `" "." "trop_stata/mata" "mata" "../mata" "'

foreach path of local search_paths {
    capture confirm file "`path'/trop_constants.mata"
    if _rc == 0 {
        local mata_dir "`path'"
        continue, break
    }
}

if "`mata_dir'" == "" {
    display as error "Error: Cannot find Mata files."
    display as error "Please run from project root or trop_stata/mata directory."
    display as error "Or use absolute path: stata-mp -b do /path/to/compile_all.do"
    exit 601
}

// --- Error tracking ----------------------------------------------------------
local error_count = 0
local failed_files ""
local total_files = 0

// --- CI mode detection -------------------------------------------------------
// Enabled by the CI environment variable or the --ci command-line flag.
local ci_mode = 0
capture local ci_env : env CI
if "`ci_env'" == "true" {
    local ci_mode = 1
}
args ci_flag
if "`ci_flag'" == "--ci" {
    local ci_mode = 1
}

// ============================================================================
// Compilation order (dependency graph)
// ============================================================================
//
// Layer 1: Foundation
//   trop_constants              Numeric and string constants.
//
// Layer 2: Core interfaces (depend on Layer 1)
//   trop_rust_interface         Plugin calling conventions and availability check.
//   trop_data_transfer          Mata-to-plugin data marshalling.
//   trop_lambda_grid            Regularization parameter grid construction.
//
// Layer 3: Dependent modules (depend on Layer 2)
//   trop_backend_select         Backend selection (Rust or pure Mata).
//   trop_ereturn_store          e()-class result storage.
//
// Layer 4: Functional modules (no cross-dependencies)
//   trop_validation             Input validation.
//   trop_loocv_validation       LOOCV parameter validation.
//   trop_bootstrap_diagnostics  Bootstrap diagnostic statistics.
//   trop_estat_helpers          Post-estimation summary utilities.
//   trop_eventstudy             Event-study aggregation and pre-trend testing.
//
// Layer 5: Entry point (depends on Layers 2--4)
//   trop_main                   Top-level estimation driver.
// ============================================================================

// --- File list (ordered by dependency) ---------------------------------------
local mata_files ///
    "trop_constants.mata" ///
    "trop_rust_interface.mata" ///
    "trop_data_transfer.mata" ///
    "trop_lambda_grid.mata" ///
    "trop_backend_select.mata" ///
    "trop_ereturn_store.mata" ///
    "trop_validation.mata" ///
    "trop_loocv_validation.mata" ///
    "trop_bootstrap_diagnostics.mata" ///
    "trop_estat_helpers.mata" ///
    "trop_eventstudy.mata" ///
    "trop_main.mata"

// --- Compilation loop --------------------------------------------------------
display ""
display as text "Starting Mata compilation..."
display as text "=========================================="

foreach file of local mata_files {
    local total_files = `total_files' + 1
    local filepath "`mata_dir'/`file'"
    
    if `ci_mode' {
        display as text "[CI] Compiling: `file'"
    }
    else {
        display as text "Compiling: `file'"
    }
    
    capture noisily do "`filepath'"
    
    if _rc != 0 {
        local error_count = `error_count' + 1
        local failed_files "`failed_files' `file'"
        display as error "  FAILED: `file' (error code: " _rc ")"
    }
    else {
        display as result "  OK: `file'"
    }
}

// --- Compilation summary -----------------------------------------------------
display ""
display as text "=========================================="
display as text "COMPILATION SUMMARY"
display as text "=========================================="
display as text "Total files:  `total_files'"
display as text "Successful:   " `total_files' - `error_count'
display as text "Failed:       `error_count'"

if `error_count' > 0 {
    display ""
    display as error "FAILED FILES:"
    foreach f of local failed_files {
        display as error "  - `f'"
    }
    display ""
    
    if `ci_mode' {
        // Machine-readable tags for CI pipelines.
        display as text "[CI:STATUS] FAILED"
        display as text "[CI:ERROR_COUNT] `error_count'"
        display as text "[CI:FAILED_FILES]`failed_files'"
    }
    
    display as error "Mata compilation FAILED with `error_count' error(s)"
    exit 198
}
else {
    display ""
    if `ci_mode' {
        display as text "[CI:STATUS] SUCCESS"
        display as text "[CI:TOTAL_FILES] `total_files'"
    }
    display as result "=========================================="
    display as result "TROP Mata compilation completed successfully"
    display as result "All `total_files' files compiled without errors"
    display as result "=========================================="
}
