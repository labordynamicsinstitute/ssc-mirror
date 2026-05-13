*! _build_lwavelet.do — Compiles all Mata source into lwavelet.mlib
*! Run this ONCE: do _build_lwavelet.do
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*! Date: 2026-05-11
*!
*! Source-file location:
*!   - After `ssc install lwavelet`, sources live at `c(sysdir_plus)'l/
*!   - During development, sources live in the current working directory
*! This script auto-detects which case it's in.

version 17
set matastrict on

// ─── Locate Mata sources ────────────────────────────────────────────────
local srcdir "`c(sysdir_plus)'l/"
if !fileexists("`srcdir'_wv_filters.mata") {
    local srcdir "`c(pwd)'/"
}
if !fileexists("`srcdir'_wv_filters.mata") {
    display as error "Cannot find _wv_filters.mata in either `c(sysdir_plus)'l/ or `c(pwd)'"
    display as error "cd to the wavelet_pkg directory before running this script."
    exit 601
}

// Write the new mlib next to the sources
local outdir "`srcdir'"

// Clear any existing in-memory functions and on-disk mlib
cap mata: mata drop _wv_*()
cap erase "`outdir'lwavelet.mlib"

display as text ""
display as text "{hline 60}"
display as text "{bf:  Building lwavelet.mlib — Wavelet Analysis Library}"
display as text "{hline 60}"
display as text "  Source dir: `srcdir'"
display as text ""

display as text "  [1/6] Compiling filter coefficients..."
quietly do "`srcdir'_wv_filters.mata"

display as text "  [2/6] Compiling MODWT/DWT core engine..."
quietly do "`srcdir'_wv_core.mata"

display as text "  [3/6] Compiling CWT engine..."
quietly do "`srcdir'_wv_cwt.mata"

display as text "  [4/6] Compiling bivariate analysis (XWT/WTC)..."
quietly do "`srcdir'_wv_bivariate.mata"

display as text "  [5/6] Compiling multivariate analysis..."
quietly do "`srcdir'_wv_multi.mata"

display as text "  [6/6] Compiling display utilities..."
quietly do "`srcdir'_wv_display.mata"

// ─── Create compiled library ────────────────────────────────────────────
display as text ""
display as text "  Creating lwavelet.mlib in `outdir'..."
mata: mata mlib create lwavelet, dir("`outdir'") replace
mata: mata mlib add lwavelet _wv_*()

display as text ""
display as text "{hline 60}"
display as result "  lwavelet.mlib built successfully!"
display as text "{hline 60}"
display as text ""
display as text "  The following Mata functions are now available:"
mata: mata describe _wv_*()
