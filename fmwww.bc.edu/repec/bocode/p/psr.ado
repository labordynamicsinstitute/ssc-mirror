*! version 0.9.3 04aug2025

program define psr, eclass byable(onecall)
    version 12
	if _by() {
		local BY `"by `_byvars'`_byrc0':"'
	}
	
	`BY' Estimate `0'
end

program Estimate, eclass byable(recall) sortpreserve

	local vv : di "version " string(_caller()) ":"
	version 10

	* Dependent variable
	gettoken lhs 0 : 0, parse(" ,[") match(paren) bind
	if (strpos("(",`"`lhs'"')) {
		fvunab lhs : `lhs'
		if `:list sizeof lhs' > 1 {
			gettoken lhs rest : lhs
			local 0 `"`rest' `0'"'
		}
	}

	IsStop `lhs'
	if `s(stop)' {
		error 198 
	}
	_fv_check_depvar `lhs'

	* Treatment variable - cannot use _iv_parse because the order is important
	gettoken treat 0 : 0, parse(" ,[") match(paren) bind
	if (strpos("(",`"`treat'"')) {
		fvunab lhs : `treat'
		if `:list sizeof treat' > 1 {
			gettoken treat rest : treat
			local 0 `"`rest' `0'"'
		}
	}

	local d_endog 0
	if (strpos("`treat'", "=")) {
		_iv_parse `lhs' (`treat')
		local treat `s(endog)'
		local inst `s(inst)'
		local d_endog 1
		
		tokenize `treat'
		if "`2'" != "" {
			di as err "cannot have multiple endogenous variables."
			di as err "only one treatment variable is allowed."
			error 198
		}
		
		local iv_msg "only single binary instrument is allowed."
		
		tokenize `inst'
		if "`2'" != "" {
			di as err "cannot use multiple instruments." _n "`iv_msg'"
			error 198
		}

		if !inlist(`inst',0,1) {
			di as err "instrumental variable (`inst') is not binary." _n "`iv_msg'"
			error 198
		}
	}

	* covariates
	_iv_parse `lhs' `0'

	local endog `s(endog)'
	local exog `s(exog)'
	local 0 `s(zero)'
	
	
	if "`endog'" != "" {
		di as err "endogenous control variables not allowed"
		error 198
	}

	* Check if the treatment variable is binary
	if !inlist(`treat',0,1) {
		di as err "treatment (`treat') should be binary"
		error 198
	}
	
	*syntax [if] [in] [, Logit nolog ORDer(integer 2) Verbose PMIN(real 0.0) PMAX(real 1.0)]
	syntax [if] [in] [, Logit ORDer(integer 2) USEProb AUXiliary Verbose VVerbose]

	marksample touse
	markout `touse' `lhs' `treat' `inst' `exog'
	
	if "`exog'" != "" & `order' < 1 {
		di as err "order should be >0 (recommended: 2 or 3, default: 2)"
		error 198
	}
	
	if "`vverbose'" != "" {
		local verbose "verbose"
		local auxiliary "auxiliary"
	}

	local classifier "probit"
	if "`logit'" != "" {
		local classifier "logit"
	}
	*di as txt "classifier:", as res "`classifier'"

	local qui ""
	if "`verbose'" == "" {
		local qui "quietly"
	}
	local is_vrb = "`qui'" == ""
	if "`exog'" != "" & !`is_vrb' {
		di as txt "(intermediate outputs suppressed; use", as inp "verbose", ///
			as txt "option to override)"
	}
	
	local msg "(verbose option for outputs)"
	if "`exog'" == "" {
		if `d_endog' {
			di as txt "Note: no covariates; 2SLS of", as inp "`lhs'", ///
				as txt "on", as inp "`treat'", as txt "using", ///
				as inp "`inst'", as txt "as instrument"
			ivregress 2sls `lhs' (`treat' = `inst') if `touse', vce(r)
		}
		else {
			di as txt "Note: no covariates; same as OLS of", as inp "`lhs'", ///
				as txt "on", as inp "`treat'"
			regress `lhs' `treat' if `touse', vce(r)
		}
	}
	else {
		* -------------------------------------------------------------
		* Step 1: probit/logit of D or Z on X
		* -------------------------------------------------------------
		local bindepvar = "`treat'"
		if `d_endog' {
			local bindepvar = "`inst'"
		}
		if `is_vrb' {
			di _n as txt "Step 1: " as res "`classifier'" as txt " regression of " as res "`bindepvar'"
		}
		`qui' `classifier' `bindepvar' `exog' if `touse'
		tempname bprob Vprob
		mat `bprob' = e(b)
		mat `Vprob' = e(V)
		tempvar xb pr b V imillsprod
		quietly predict `xb' if `touse', xb
		quietly predict `pr' if `touse', pr
		if "`logit'" == "" {
			tempvar xb1 pr1
			quietly generate `xb1' = -abs(`xb')
			quietly generate `pr1' = normal(`xb1')
			quietly generate `imillsprod' = normalden(`xb1')/`pr1'/(1-`pr1') if `touse'
			quietly replace `imillsprod' = abs(`xb') if `touse' & missing(`imillsprod')
		}
		else {
			quietly generate `imillsprod' = 1
		}

		* drop if pr is out of range
		local touse2 "`touse'"
		/*
		tempvar touse2
		generate `touse2' = `touse'
		quietly generate `touse2' = `touse' & `pr' >= `pmin' & `pr' <= `pmax'
		su `pr' if `touse' & !`touse2', meanonly
		local ndrop = r(N)
		if `ndrop' > 0 {
			di as txt "(`ndrop' obs pscores out of range)"
		}
		else {
			*di as txt "(all pscores within range)"
		}
		*/

		* -------------------------------------------------------------
		* Step 2: regress y on polynomials of xb and get residuals
		* -------------------------------------------------------------
		local predictor "`xb'"
		local predvname "xb"
		if "`useprob'" != "" {
			local predictor "`pr'"
			local predvname "prob"
		}
		genpoly `predictor', order(`order')
		local xpoly "`s(xlist)'"
		if `is_vrb' {
			di _n as txt "Step 2: regress", as inp "`lhs'", ///
				as txt "on `predvname''s polynomials of order " as res "`order'" as text ""
		}
		quietly regress `lhs' `xpoly' if `touse2'
		mat `b' = e(b)
		mat `V' = e(V)
		local df_r = e(df_r)
		tempvar yres
		quietly predict `yres' if `touse2', resid
		quietly drop `xpoly'
		local names: rownames `V'
		local names: subinstr local names "`predictor'_" "`predvname'^", all
		
		if `is_vrb' {
			mat coln `b' = `names'
			mat rown `V' = `names'
			mat coln `V' = `names'
			eret post `b' `V', depname("`lhs'") dof(`df_r')
			eret disp
			di "Note. Standard errors not adjusted for generated regressors."
		}
		
		* -------------------------------------------------------------
		* Step 3: final regression (OLS or IVE)
		* -------------------------------------------------------------
		if `is_vrb' {
			di _n as txt "Step 3: Regression of outcome prediction error on " _c
			if `d_endog' {
				di "D using ISR as instrument"
			}
			else {
				di "PSR"
			}
		}
		tempvar psr
		quietly generate `psr' = `bindepvar' - `pr' if `touse2'
		mata: psr_reg("`lhs'", "`yres'", "`treat'", "`xb'", "`pr'", "`imillsprod'", "`inst'", "`exog'", "`touse2'")
		tempname b_saved V_saved bx Vx
		mat `b' = r(b)
		mat `V' = r(V)
		local obs = r(N)
		mat coln `b' = "`treat'"
		mat rown `V' = "`treat'"
		mat coln `V' = "`treat'"
		mat `bx' = r(bx)
		mat `Vx' = r(Vx)
		mat coln `bx' = `exog' _cons
		mat coln `Vx' = `exog' _cons
		mat rown `Vx' = `exog' _cons
		local teffect = `b'[1,1]
		eret post `b' `V', depname("`lhs'") obs(`obs') esample(`touse')
		eret disp
		di as txt "Polynomial order of " _c
		if "`useprob'" == "" {
			di as inp "xb" _c
		}
		else {
			di as inp "pr" _c
		}
		di as txt " for output prediction = " as res %2.0f `order' ///
			_column(63) as txt "obs = " as res %10.0f `obs'
		mat `b_saved' = e(b)
		mat `V_saved' = e(V)
		generate `touse' = e(sample)
		
		*di as txt "     outcome : " as inp "`lhs'"
		di as txt "Treatment: " as inp "`treat'", as txt "(" _c
		if (`d_endog') {
			di as txt "instrumented by " as inp "`inst'" _c
		}
		else {
			di as txt "exogenous" _c
		}
		di as txt ", fitted by " as res "`classifier'" as txt ")"
		di as txt "Exogenous:", as res "`exog'"

		// Auxiliary regression
		if "`auxiliary'" != "" {
			di ""
			di as txt "Auxiliary results from OLS of", as inp "Y - teffect*D", as txt "on", as inp "covariates", as txt "(with robust"
			di "standard errors taking into account the first-stage estimation error for"
			di as inp "teffect" as txt " in " as inp "Y - teffect*D" as txt "):"
			/*
			tempvar res
			quietly generate `res' = `lhs' - `teffect'*`treat'
			regress `res' `exog'
			*/
			eret post `bx' `Vx', depname("Y-teffect*D") esample(`touse')
			eret disp
			generate `touse' = e(sample)
			di as txt "Caution:", as inp "Linearity", as txt "and", as inp "effect homogeneity", as txt "are assumed."
			di as txt "Treatment effect is valid without those restrictive assumptions."
			mat `bx' = e(b)
			mat `Vx' = e(V)
			eret post `b_saved' `V_saved', depname("`lhs'") obs(`obs') esample(`touse')
		}
		eret local pscmd "`classifier'"
		eret scalar q = `order'
		eret mat b_aux = `bx'
		eret mat V_aux = `Vx'
		eret mat b_bin = `bprob'
		eret mat V_bin = `Vprob'
		if `d_endog' {
			eret local model "iv"
		}
		else {
			eret local model "ols"
		}
		if "`useprob'" == "" {
			eret local predictor "xb"
		}
		else {
			eret local predictor "pr"
		}
		ereturn local cmd "psr"
	}
end

program genpoly, sclass
	syntax varlist(min=1 max=1), ORDer(integer) [LABel(string) SEParator(string)]
	if `order' < 1 {
		sreturn ""
	}
	if "`separator'" == "" {
		local separator "_"
	}
	forv j = 1/`order' {
		local vj = "`varlist'`separator'`j'"
		quietly generate `vj' = `varlist'^`j'
		if "`label'" != "" {
			if `j' == 1 {
				lab var `vj' "`label'"
			}
			else {
				lab var `vj' "xb**`j'"
			}
		}
	}
	local x ""
	forv j = 1/`order' {
		local x = "`x' `varlist'`separator'`j'"
	}
	sreturn local xlist `x'
end

// Borrowed from _iv_parse
// Borrowed from ivreg.ado
program define IsStop, sclass

	if `"`0'"' == "[" {
		sreturn local stop 1
		exit
	}
	if `"`0'"' == "," {
		sreturn local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sreturn local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sreturn local stop 1
		exit
	}
	if `"`0'"' == "" {
		sreturn local stop 1
		exit
	}
	else {
		sreturn local stop 0
	}

end

version 12
mata:

void psr_reg(string scalar yvar, string scalar yresid, string scalar treat, string scalar xbeta, 
	string scalar pscore, string scalar imillsprod, string scalar inst, string scalar xvars, string scalar touse) {
	real colvector y, uhat, d, xb, p, imp, z, psr
	real matrix X
	is_ols = inst == ""
	st_view(y, ., yvar, touse)
	st_view(uhat, ., yresid, touse)
	st_view(d, ., treat, touse)
	st_view(xb, ., xbeta, touse)
	st_view(p, ., pscore, touse)
	st_view(imp, ., imillsprod, touse)
	st_view(X, ., xvars, touse)
	X = X, J(rows(X),1,1)
	if (is_ols) {
		psr = d :- p
		bread = cross(psr,psr)
		b = cross(psr,uhat) :/ bread
		vhat = uhat - b[1,1]*psr
	} else {
		st_view(z, ., inst, touse)
		psr = z :- p
		bread = cross(psr,d)
		b = cross(psr,uhat) :/ bread
		vhat = uhat - b[1,1]*d
	}
	dens = normalden(xb)
	ell = -cross(X, dens :* vhat)
	//tmp = psr :* dens
	//tmp = tmp :/ (p :- p:^2)
	S = X :* (imp :* psr)
	eta = S*invsym(cross(S,S))
	tmp = vhat:*psr + eta*ell
	meat = cross(tmp, tmp)
	st_matrix("r(b)",b)
	st_matrix("r(V)", meat :/ (bread:^2))
	st_numscalar("r(N)", rows(X))

	// Auxiliary regression
	yd = y :- b:*d
	bx = invsym(cross(X,X))*cross(X,yd)
	iXX = invsym(cross(X,X))
	res = yd :- X*bx
	th = (vhat:*psr + eta*ell):/cross(psr,d)
	Xdbar = cross(X,d)/rows(X)
	tmp = X:*res-th*Xdbar'
	vcov = iXX*cross(tmp,tmp)*iXX
	st_matrix("r(bx)", bx')
	st_matrix("r(Vx)", vcov)
}

end
