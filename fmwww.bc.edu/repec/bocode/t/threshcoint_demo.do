*! threshcoint_demo.do -- Walkthrough of every test/model in the package
*! Author: Dr Merwan Roudane
*
* This do-file builds a small synthetic dataset that exhibits threshold
* cointegration and then runs the entire library against it.
*
* Run with: do threshcoint_demo.do   (from the examples folder)
* or invoke after `net install threshcoint, from(...)`.

clear all

// ----- Locate threshcoint -----------------------------------------------------
// The demo works in three scenarios:
//   (1) threshcoint already installed via `ssc install threshcoint'
//   (2) run from the source examples/ folder (../ado/threshcoint.ado exists)
//   (3) run from the source root (ado/threshcoint.ado exists)
capture which threshcoint
if !_rc {
    di as text "[threshcoint demo] using installed threshcoint package."
}
else {
    local pkgroot ""
    capture confirm file "../ado/threshcoint.ado"
    if !_rc local pkgroot ".."
    else {
        capture confirm file "ado/threshcoint.ado"
        if !_rc local pkgroot "."
    }
    if "`pkgroot'" == "" {
        di as error "threshcoint is not installed and no source folder was found."
        di as error "Either run:  ssc install threshcoint"
        di as error "or cd to the source examples/ folder before do-ing this script."
        exit 198
    }
    adopath + "`pkgroot'/help"
    adopath + "`pkgroot'/mata"
    adopath + "`pkgroot'/ado"
    di as text "[threshcoint demo] using source folder at `pkgroot'/"
}

set seed 20260514
set obs 500

// ----- Simulate threshold-cointegrated data ---------------------------
gen t = _n
gen double eps_x = rnormal(0,1)
gen double x = sum(eps_x)                       // x ~ I(1)
gen double e = .
qui replace e = 0 in 1
qui forvalues i = 2/`=_N' {
    local prev = e[`i'-1]
    local sh   = rnormal(0,0.5)
    if `prev' > 0.5 {
        qui replace e = -0.4*`prev' + `sh' in `i'
    }
    else if `prev' < -0.5 {
        qui replace e = -0.8*`prev' + `sh' in `i'
    }
    else {
        qui replace e = `prev' + `sh' in `i'
    }
}
gen double y = x + e                              // threshold-cointegrated

tsset t

// ----- Stationarity checks --------------------------------------------
tc_adf y
tc_adf x
tc_pp  y
tc_pp  x

// ----- Linear cointegration baseline ----------------------------------
tc_eg  y x, case(c)

// ----- Threshold cointegration tests ----------------------------------
tc_es        y x, model(tar)  maxlag(6)
tc_es        y x, model(mtar) maxlag(6)
tc_glsmtar   y x, case(c)
tc_exes      y x
tc_covaug    y x, model(mtar)
tc_bf        y x
tc_adlbdm    y x
tc_adlbo     y x
tc_kss       y x, case(2)
tc_bbc       e
tc_supf      y x, breaktype(1) model(tar)
tc_supf      y x, breaktype(4) model(tar)
tc_hs        y x, lag(2)

// ----- One-stop comparison --------------------------------------------
tc_compare   y x, maxlag(6)

// ----- Models on cointegrating residuals ------------------------------
tc_eg  y x, case(c)
* tc_eg is rclass; use a plain regress to obtain residuals for the model fits.
quietly regress y x
predict double resid_eg, residual
tc_tar    resid_eg, model(tar)
tc_tar    resid_eg, model(mtar)
tc_eqtar  resid_eg, type(eq)
tc_eqtar  resid_eg, type(rd)
tc_setar  y,        lag(2) delay(1)
tc_tvecm  y x,      lag(1)

// ----- Visualisations -------------------------------------------------
tc_es        y x, model(mtar)
tc_plot regime resid_eg, threshold(0) model(mtar)             ///
        title("MTAR regime split on EG residuals") saving(tc_regime)

tc_bf        y x
tc_plot grid, title("Balke-Fomby sup-Wald grid search")        ///
        saving(tc_grid)

tc_tvecm     y x, lag(1)
local tv_thr = r(threshold)
matrix ect_v = r(ect)
preserve
    drop _all
    svmat ect_v, names("ect_var")
    gen long t = _n
    tsset t
    tc_plot ect ect_var1, threshold(`tv_thr')                  ///
        title("TVECM error-correction term") saving(tc_ect)
restore
