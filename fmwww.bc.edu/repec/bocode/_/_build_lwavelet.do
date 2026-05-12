*! _build_lwavelet.do — Compiles all Mata source into lwavelet.mlib
*! Run this ONCE after installation: do _build_lwavelet.do
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*! Date: 2026-05-10

version 11
set matastrict on

// Clear any existing library
cap mata: mata drop _wv_*()
cap erase lwavelet.mlib

// Compile Mata source files in dependency order
display as text ""
display as text "{hline 60}"
display as text "{bf:  Building lwavelet.mlib — Wavelet Analysis Library}"
display as text "{hline 60}"
display as text ""

display as text "  [1/5] Compiling filter coefficients..."
quietly do "`c(sysdir_plus)'l/_wv_filters.mata"

display as text "  [2/5] Compiling MODWT/DWT core engine..."
quietly do "`c(sysdir_plus)'l/_wv_core.mata"

display as text "  [3/5] Compiling CWT engine..."
quietly do "`c(sysdir_plus)'l/_wv_cwt.mata"

display as text "  [4/5] Compiling bivariate analysis (XWT/WTC)..."
quietly do "`c(sysdir_plus)'l/_wv_bivariate.mata"

display as text "  [5/5] Compiling multivariate analysis + display..."
quietly do "`c(sysdir_plus)'l/_wv_multi.mata"
quietly do "`c(sysdir_plus)'l/_wv_display.mata"

// Create compiled library
display as text ""
display as text "  Creating lwavelet.mlib..."
mata: mata mlib create lwavelet, dir("`c(sysdir_plus)'l/") replace
mata: mata mlib add lwavelet _wv_*()

display as text ""
display as text "{hline 60}"
display as result "  lwavelet.mlib built successfully!"
display as text "{hline 60}"
display as text ""
display as text "  The following Mata functions are now available:"
mata: mata describe _wv_*()
