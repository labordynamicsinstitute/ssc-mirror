*! version 1.0.0  10jun2026
*! predict after xtdynestimb -- linear prediction or residuals (levels)
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
program xtdynestimb_predict
    version 16.0
    syntax newvarname [if] [in] [, XB Residuals ]
    if "`e(cmd)'" != "xtdynestimb" {
        di as error "predict works only after xtdynestimb"
        exit 301
    }
    if "`xb'" != "" & "`residuals'" != "" {
        di as error "specify only one of xb or residuals"
        exit 198
    }
    if "`xb'" == "" & "`residuals'" == "" local xb "xb"
    marksample touse, novarlist
    tempvar xbv
    tempname bmat
    matrix `bmat' = e(b)
    quietly matrix score double `xbv' = `bmat' if `touse'
    if "`xb'" != "" {
        quietly gen `typlist' `varlist' = `xbv' if `touse'
        label var `varlist' "Linear prediction (levels)"
    }
    else {
        quietly gen `typlist' `varlist' = `e(depvar)' - `xbv' if `touse'
        label var `varlist' "Residuals (levels)"
    }
end
