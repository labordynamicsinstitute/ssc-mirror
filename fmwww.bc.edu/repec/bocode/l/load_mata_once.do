*! TROP Mata function loader
*! Purpose: Load all Mata functions in dependency order; skip if already loaded

// Check whether functions are already loaded
capture mata: mata describe trop_main()
if _rc == 0 {
    // Already loaded; skip
    exit
}

// Resolve the base path to the mata/ source directory.
// Try multiple strategies to locate the files.
local base_path ""

// Strategy 1: current working directory is trop_stata/
capture confirm file "`c(pwd)'/mata/trop_constants.mata"
if _rc == 0 {
    local base_path "`c(pwd)'"
}

// Strategy 2: trop_stata/ subdirectory relative to CWD
if "`base_path'" == "" {
    capture confirm file "`c(pwd)'/trop_stata/mata/trop_constants.mata"
    if _rc == 0 {
        local base_path "`c(pwd)'/trop_stata"
    }
}

// Strategy 3: relative to this script (if CWD == trop_stata/)
if "`base_path'" == "" {
    // Assumes this script resides in trop_stata/
    capture confirm file "mata/trop_constants.mata"
    if _rc == 0 {
        local base_path "."
    }
}

// Strategy 4: parent directory (when run from tests/ subdirectory)
if "`base_path'" == "" {
    capture confirm file "`c(pwd)'/../mata/trop_constants.mata"
    if _rc == 0 {
        local base_path "`c(pwd)'/.."
    }
}

// Strategy 5: derive package root from the installed location of trop.ado
// via findfile (works regardless of CWD, e.g. in Stata batch mode)
if "`base_path'" == "" {
    capture findfile trop.ado
    if !_rc {
        local _ado_path "`r(fn)'"
        local _base : subinstr local _ado_path "/ado/trop.ado" ""
        if "`_base'" != "`_ado_path'" {
            capture confirm file "`_base'/mata/trop_constants.mata"
            if _rc == 0 {
                local base_path "`_base'"
            }
        }
    }
}

if "`base_path'" == "" {
    di as error "Error: Cannot find TROP Mata files."
    di as error "Please ensure adopath includes trop_stata/ado directory."
    exit 601
}

// Compilation order (dependency hierarchy; see compile_all.do)
//
// Level 1: base definitions (constants)
qui do "`base_path'/mata/trop_constants.mata"

// Level 2: core interfaces (Rust plugin + data transfer + grid)
qui do "`base_path'/mata/trop_rust_interface.mata"
qui do "`base_path'/mata/trop_data_transfer.mata"
qui do "`base_path'/mata/trop_lambda_grid.mata"

// Level 3: modules depending on level 2
qui do "`base_path'/mata/trop_backend_select.mata"   // depends on trop_rust_interface
qui do "`base_path'/mata/trop_ereturn_store.mata"

// Level 4: independent modules
qui do "`base_path'/mata/trop_validation.mata"
qui do "`base_path'/mata/trop_loocv_validation.mata"
qui do "`base_path'/mata/trop_bootstrap_diagnostics.mata"
qui do "`base_path'/mata/trop_estat_helpers.mata"
qui do "`base_path'/mata/trop_eventstudy.mata"

// Level 5: main entry point (depends on levels 2-4)
qui do "`base_path'/mata/trop_main.mata"              // depends on data_transfer, rust_interface, ereturn_store
