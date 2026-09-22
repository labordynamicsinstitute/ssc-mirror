*! ihsretran.ado - Duan's smearing retransformation and marginal effects for IHS models
*! Version 1.1.0 - 19Sep2026
*! Author: Dereje Fedasa
*! Based on Edward C. Norton (2022), The Stata Journal

program define ihsretran, rclass
    version 14.0
    
    syntax varlist(min=2) [if] [in] [, SCale(real 1.0) Level(cilevel) GENerate(name)]
    
    marksample touse
    
    gettoken y xvars: varlist
    
    if `scale' <= 0 {
        di as error "Scale factor must be strictly positive."
        exit 411
    }
    
    di as text ""
    di as text "{hline 78}"
    di as text "{bf:IHS Marginal Effects with Duan's Smearing Estimator}"
    di as text "{bf:Reference: Edward C. Norton (2022, Stata Journal)}"
    di as text "{hline 78}"
    di as text "Dependent variable: " as result "`y'"
    di as text "Scaling factor:     " as result `scale'
    di as text "Covariates:         " as result "`xvars'"
    di as text "{hline 78}"
    
    tempvar ihs_y xbhat ehat smear_exp
    qui gen double `ihs_y' = asinh(`scale' * `y')
    label variable `ihs_y' "Asinh(`scale' * `y')"
    
    regress `ihs_y' `xvars' if `touse', vce(robust)
    
    local nobs = e(N)
    local r2   = e(r2)
    
    qui predict double `xbhat' if `touse', xb
    qui predict double `ehat' if `touse', residual
    
    qui gen double `smear_exp' = exp(`ehat') if `touse'
    qui sum `smear_exp' if `touse', meanonly
    scalar duan_fac = r(mean)
    
    if "`generate'" != "" {
        capture drop `generate'
        qui gen double `generate' = 0.5 * (exp(`xbhat') * scalar(duan_fac) - (1 / (exp(`xbhat') * scalar(duan_fac)))) / `scale' if `touse'
        label variable `generate' "Retransformed predicted `y' (Duan adjusted)"
        di as text "Note: Retransformed predictions saved as variable: " as result "`generate'"
    }
    
    di as text ""
    di as text "Number of observations = " as result `nobs'
    di as text "Duan's smearing factor (D) = " as result %10.4f scalar(duan_fac)
    di as text ""
    di as text "{hline 78}"
    di as text "{bf:Marginal Effects on the Original Scale (Duan's Adjusted):}"
    di as text "{hline 78}"
    
    margins, dydx(*) expression(0.5 * (exp(xb()) * scalar(duan_fac) - (1 / (exp(xb()) * scalar(duan_fac)))) / `scale') level(`level')
    
    return scalar N = `nobs'
    return scalar r2 = `r2'
    return scalar duan = scalar(duan_fac)
    return local cmd "ihsretran"
    
end
