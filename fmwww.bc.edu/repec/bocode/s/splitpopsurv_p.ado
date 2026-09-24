*! splitpopsurv_p v1.0.0  22sep2026
*! predict subroutine for splitpopsurv
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>

capture program drop splitpopsurv_p
program define splitpopsurv_p
    version 17
    if "`e(cmd)'" != "splitpopsurv" {
        error 301
    }
    syntax newvarname [if] [in] [, XB PCure SUrvival]

    local nopt : word count `xb' `pcure' `survival'
    if `nopt' > 1 {
        display as error "only one of xb, pcure, or survival may be specified"
        exit 198
    }
    if `nopt' == 0 local survival "survival"

    marksample touse, novarlist

    local dist "`e(distribution)'"

    tempname beta
    matrix `beta' = e(b)
    tempvar theta1 thetap
    quietly matrix score double `theta1' = `beta' if `touse', eq(H_regression)
    quietly matrix score double `thetap' = `beta' if `touse', eq(P_regression)

    if "`xb'" != "" {
        quietly gen double `varlist' = `theta1' if `touse'
        label variable `varlist' "Fitted H_regression linear predictor"
        exit
    }

    * cure (stayer) probability, respecting the group() flip if one was used
    tempvar p
    local grpvar "`e(groupvar)'"
    if "`grpvar'" != "" {
        quietly gen double `p' = invlogit(`thetap')   if `touse' & `grpvar'==1
        quietly replace   `p' = 1-invlogit(`thetap') if `touse' & `grpvar'==0
    }
    else {
        quietly gen double `p' = invlogit(`thetap') if `touse'
    }

    if "`pcure'" != "" {
        quietly gen double `varlist' = `p' if `touse'
        label variable `varlist' "Predicted cure (stayer) probability"
        exit
    }

    * marginal survival S(t), evaluated at each observation's own duration
    local depvar "`e(depvar)'"
    tempvar sv

    if "`dist'" == "loglogistic" {
        tempname theta2
        scalar `theta2' = _b[theta2:_cons]
        quietly gen double `sv' = 1/(1+(exp(-`theta1')*`depvar')^(1/`theta2')) if `touse'
    }
    else if "`dist'" == "weibull" {
        tempname lnsig
        scalar `lnsig' = _b[ln_sigma:_cons]
        quietly gen double `sv' = exp(-exp(`theta1')*(`depvar'^exp(`lnsig'))) if `touse'
    }
    else if "`dist'" == "lognormal" {
        tempname lnsig
        scalar `lnsig' = _b[ln_sigma:_cons]
        quietly gen double `sv' = 1-normal((ln(`depvar')-`theta1')/exp(`lnsig')) if `touse'
    }
    else if "`dist'" == "gamma" {
        tempname kap
        scalar `kap' = _b[kappa:_cons]
        quietly gen double `sv' = 1-gammap(`kap', `theta1'*`depvar') if `touse'
    }
    else if "`dist'" == "ggamma" {
        tempname lnsig kap
        scalar `lnsig' = _b[ln_sigma:_cons]
        scalar `kap'   = _b[kappa:_cons]
        tempvar k s l z u cdf
        quietly gen double `k' = `kap' if `touse'
        quietly replace `k' = sign(`k')*.01 if abs(`k')<0.01 & `touse'
        quietly gen double `s' = exp(`lnsig') if `touse'
        quietly gen double `l' = (abs(`k'))^(-2) if `touse'
        quietly gen double `z' = sign(`k')*(ln(`depvar')-`theta1')/`s' if `touse'
        quietly gen double `u' = `l'*exp(abs(`k')*`z') if `touse'
        quietly gen double `cdf' = 1-gammap(`l', `u') if `touse'
        quietly replace `cdf' = gammap(`l', `u') if `k'>=0.01 & `touse'
        quietly replace `cdf' = normal(`z') if abs(`k')<0.01 & `touse'
        quietly gen double `sv' = 1-`cdf' if `touse'
    }

    quietly gen double `varlist' = (1-`p')*`sv' + `p' if `touse'
    label variable `varlist' "Predicted marginal survival S(t)"
end
