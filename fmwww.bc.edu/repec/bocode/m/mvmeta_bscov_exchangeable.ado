/******************************************************************************
*! version 0.2  Ian White  15nov2021
version 0.1  Ian White  4jun2020
Exchangeable covariance matrix for mvmeta
Sigma = tau^2 * P(rho)
Parameters: tau (or log tau)
	rho 
Note that Sigma is singular if rho is outside range -1/(dim - 1) to 1
	but solutions may lie outside this range
	since only Sigma+S`i' must be non-singular
	hence transformation is not desirable
	-> could allow truncate option?
	-> what transformation would I use?
******************************************************************************/

program define mvmeta_bscov_exchangeable, rclass

syntax [if] [in], [log  ///
    setup start(string) ///
    mm1 mm2 notrunc      /// Method of moments
    varparms(string)    /// Within -ml-
    postfit             /// After -ml-
    ]
local p $MVMETA_p
marksample touse
tempname startchol Sigma binit vinit init

if "$MVMETA_taulog"=="taulog" {
    // Estimate tau on log scale
    local exp exp
    local tauname logtau
	local taustart 0
}
else {
	local tauname tau
	local taustart 1
}
local rhoname rho
local rhostart 0
* could include transformation here, not done yet

if "`setup'"!="" {
    di as text "Note: variance-covariance matrix is " as result "exchangeable"
    // STARTING VALUES
    if "`start'"!="" {
        cap numlist "`start'", min(2) max(2)
        if _rc {
            di as error "Error in start(`start'): need start(# #)"
            exit 499
        }
    }
    else local start `taustart' 0
	local tau : word 1 of `start'
	local rho : word 2 of `start'
    mat `Sigma' = `exp'(`tau')^2 * (J(`p',`p',`rho')+(1-`rho')*I(`p'))
    cap mvmeta_mufromsigma, sigma(`Sigma')
    if _rc {
        di as error "mvmeta_bscov_exchangeable: mvmeta_mufrom sigma failed"
        mat l `Sigma', title(Sigma used)
        exit _rc
    }
    mat `binit' = e(b)
    mat `vinit' = (`tau', `rho')
    mat colnames `vinit' = "`tauname'" "`rhoname'"
    mat `init' = (`binit', `vinit')
    return local nvarparms = 2
    return matrix binit = `binit'
    return matrix init = `init'
    // SET UP EQUATIONS
    return local eqlist (`tauname':) (`rhoname':)
}

if "`varparms'" != "" {
	local tau = `varparms'[1,1]
	local rho = `varparms'[1,2]
    matrix `Sigma' = (`exp'(`tau'))^2 * (J(`p',`p',`rho')+(1-`rho')*I(`p'))
}

if "`postfit'" != "" {
	if "`exp'"=="exp" local tau2 `exp'(2*[`tauname']_b[_cons])
	else local tau2 ([`tauname']_b[_cons])^2
	local rho = [`rhoname']_b[_cons]
	matrix `Sigma' = (`tau2') * (J(`p',`p',`rho')+(1-`rho')*I(`p'))
    mat rownames `Sigma' = $MVMETA_ylist
    mat colnames `Sigma' = $MVMETA_ylist
    // SET UP VARIANCE EXPRESSIONS
    forvalues r=1/`p' {
        forvalues s=1/`r' {
			if `s' == `r' return local Sigma`s'`r' `tau2'
			else return local Sigma`s'`r' [`rhoname']_b[_cons] * `tau2'
        }
    }
}

if !mi("`mm1'`mm2'") {    // METHOD OF MOMENTS
    di as error "Sorry, method of moments is not yet implemented for bscov(exchangeable)"
    exit 498
}

return matrix Sigma = `Sigma'
return scalar nparms_aux = 2
return scalar neqs_aux = 2

end

