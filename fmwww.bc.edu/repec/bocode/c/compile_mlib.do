*! compile_mlib.do - Compile Mata library for DIDdesign package
*!
*! This script compiles all Mata source files into a single mlib library
*! for faster loading and distribution.

version 16.0

// Clear any existing Mata functions
mata: mata clear

display as text "{hline 70}"
display as text "DIDdesign Mata Library Compiler"
display as text "{hline 70}"

// Get the directory of this script
local thisdir "/Users/cxy/Desktop/2026project/diddesign推送260401/diddesign-stata/mata"

// List of Mata files to compile (in dependency order)
local mata_files "did_utils did_estimators did_bootstrap did_gmm did_sa did_check"

local load_count = 0
local warn_count = 0

// Load all Mata source files
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
        display as error "  [-] `f'.mata not found"
        local ++warn_count
    }
}

if `warn_count' > 0 {
    display as error "{hline 70}"
    display as error "Errors occurred while loading Mata files. Aborting."
    display as error "{hline 70}"
    exit 1
}

// Create the mlib library
local libname "ldiddesign"
local libfile "`thisdir'/`libname'.mlib"

// Create new library (will overwrite if exists)
mata: mata mlib create ldiddesign, replace

// Add all functions using the 'function' keyword pattern
mata: mata mlib add ldiddesign *(), complete

// Verify the library was created
confirm file "`libfile'"
if _rc == 0 {
    display as text "{hline 70}"
    display as text "Library compiled successfully: `libfile'"
    display as text "{hline 70}"
}
else {
    display as error "{hline 70}"
    display as error "Failed to create library!"
    display as error "{hline 70}"
    exit 1
}

// List all functions in the library
display as text ""
display as text "Functions in library:"
mata: mata mlib query ldiddesign, where

display as text "{hline 70}"
display as text "Compilation complete!"
display as text "{hline 70}"
