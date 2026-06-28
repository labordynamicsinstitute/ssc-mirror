*! diddesign_mata.do - Mata function loader for DIDdesign package
*!
*! All Mata functions required by the DIDdesign package are loaded by this
*! script in dependency order to ensure proper initialization of the double
*! difference-in-differences estimator and related statistical procedures.

version 16.0

// -------------------------------------------------------------------------
// Directory Detection
// -------------------------------------------------------------------------
// The Mata source directory is resolved using a fallback chain to support
// multiple installation and execution contexts.

args mata_dir

local thisdir "`mata_dir'"

// Fallback 1: Extracted from script invocation path
if "`thisdir'" == "" {
    local script_path "`0'"
    if "`script_path'" != "" {
        local script_path = subinstr("`script_path'", char(92), "/", .)
        local thisdir = reverse(substr(reverse("`script_path'"), strpos(reverse("`script_path'"), "/") + 1, .))
        capture confirm file "`thisdir'/did_utils.mata"
        if _rc != 0 {
            local thisdir ""
        }
    }
}

// Fallback 2: Located via findfile in adopath
if "`thisdir'" == "" {
    qui capture findfile diddesign_mata.do
    if _rc == 0 {
        local this_path "`r(fn)'"
        local this_path = subinstr("`this_path'", char(92), "/", .)
        local thisdir = reverse(substr(reverse("`this_path'"), strpos(reverse("`this_path'"), "/") + 1, .))
        capture confirm file "`thisdir'/did_utils.mata"
        if _rc != 0 {
            local thisdir ""
        }
    }
}

// Fallback 3: Located relative to diddesign.ado
if "`thisdir'" == "" {
    qui capture findfile diddesign.ado
    if _rc == 0 {
        local ado_path "`r(fn)'"
        local ado_path = subinstr("`ado_path'", char(92), "/", .)
        local ado_dir = reverse(substr(reverse("`ado_path'"), strpos(reverse("`ado_path'"), "/") + 1, .))
        local thisdir "`ado_dir'/../mata"
        capture confirm file "`thisdir'/did_utils.mata"
        if _rc != 0 {
            local thisdir ""
        }
    }
}

// Fallback 4: Standard project layout under current directory
if "`thisdir'" == "" {
    local thisdir "`c(pwd)'/diddesign-stata/mata"
    capture confirm file "`thisdir'/did_utils.mata"
    if _rc != 0 {
        local thisdir ""
    }
}

// Fallback 5: Current working directory
if "`thisdir'" == "" {
    local thisdir "`c(pwd)'"
    capture confirm file "`thisdir'/did_utils.mata"
    if _rc != 0 {
        local thisdir ""
    }
}

// Fallback 6: PLUS sysdir (user-installed packages)
if "`thisdir'" == "" {
    local thisdir "`c(sysdir_plus)'d"
    capture confirm file "`thisdir'/did_utils.mata"
    if _rc != 0 {
        local thisdir "."
    }
}

// -------------------------------------------------------------------------
// Initialization
// -------------------------------------------------------------------------

// Previous Mata functions are cleared to ensure clean state
mata: mata clear

display as text "{hline 70}"
display as text "DIDdesign Stata Package"
display as text "{hline 70}"
display as text "Loading Mata functions..."

// -------------------------------------------------------------------------
// Module Loading
// -------------------------------------------------------------------------
// Modules are loaded in dependency order: utilities, estimators, bootstrap,
// GMM, staggered adoption, and diagnostics.

local mata_files "did_utils did_estimators did_bootstrap did_gmm did_sa did_check"

local load_count = 0
local warn_count = 0

foreach f of local mata_files {
    capture confirm file "`thisdir'/`f'.mata"
    if _rc == 0 {
        display as text "  [+] Loading `f'.mata"
        capture noisily quietly do "`thisdir'/`f'.mata"
        if _rc == 0 {
            local ++load_count
        }
        else {
            display as error "  [!] Error loading `f'.mata (rc = `=_rc')"
            local ++warn_count
        }
    }
    else {
        display as text "  [-] `f'.mata not found"
        local ++warn_count
    }
}

// -------------------------------------------------------------------------
// Summary
// -------------------------------------------------------------------------

display as text "{hline 70}"
if `warn_count' == 0 {
    display as text "DIDdesign: `load_count' Mata modules loaded successfully."
}
else {
    display as text "DIDdesign: `load_count' modules loaded, `warn_count' warnings."
}
display as text "{hline 70}"
