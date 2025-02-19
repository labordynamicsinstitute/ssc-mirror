*! version 1.0.0  17feb2025

/***************************    PRIMARY ROUTINE     ***************************/
program define goprobit2, eclass
	version 15

	syntax varlist [fw iw pw] [if] [in] [, DISTribution(string) * ]
	
	gettoken depvar indepvars: varlist
	tempvar touse
	mark `touse' `if' `in'
	
	if ("`distribution'"=="") local distribution "normal"
	GetDistributionOptions `distribution'
	local eval  "`r(eval)'"
	local args0 "`r(args0)'"
	local eqs0  "`r(eqs0)'"
	local k_aux "`r(k_aux)'"
	local aux_constr "`r(aux_constr)'"
	local title "Ordered reponse regression with `distribution' CDF"
	
	quietly levelsof `depvar' if (`touse'), local(J)
	global gloJ `J'
	while (`:list sizeof J'>1) { // get |J|-1 "/cuts"
		gettoken j J: J
		local   cuts   `cuts'  cut`j'
		local eqcuts `eqcuts' /cut`j'
	}
	global args `args0' `cuts'

	* Define equations following oprobit.ado convention
	* - if univariate:   (cut0:depvar=) /cut1 ... /cut8
	* - if multivariate: (depvar:depvar=indepvars,noconstant) /cut0 ... /cut8
	global univariate = ("`indepvars'"=="")
	if (${univariate}) {
		gettoken mincut cuts:   cuts
		gettoken drop eqcuts: eqcuts
		local xb (`mincut': `depvar'=)
	}
	else {
		local xb (mu: `depvar'=`indepvars', noconstant)
		global args mu ${args}
	}

	* Starting values
	quietly oprobit `depvar' `indepvars' [`weight'`exp'] if (`touse'), `options'
	mat mu = e(b)[1,1..e(k)-e(k_aux)]
	mat cuts = e(b)[1,e(k)-e(k_aux)+1...]
	if      ("`eval'"=="sged")  mat b0 = (mu, 0, 2,    cuts)
	else if ("`eval'"=="sgt")   mat b0 = (mu, 0, 2, 5, cuts)
	else                        mat b0 = (mu,          cuts)
	
	* Estimate
	ml model lf                     /*
	*/	goprobit2_`eval'_llf	        /*
	*/ `xb' `eqs0' `eqcuts'			/*
	*/ [`weight'`exp']				/*
	*/ if (`touse')					/*
	*/ , maximize `options'         /*
	*/ constraint(`aux_constr')     /*
	*/ init(b0, copy)               /*
	*/ title(`title')
	ml display
	
	* Returns
	ereturn scalar k_cat = `J'
	ereturn scalar k_aux = `k_aux'
	ereturn local cmdline "goprobit2 `0'"
	ereturn local cmd "goprobit2"
	ereturn local distribution "`distribution'"
	ereturn local title "`title'"
	
end


/***********************    DISTRIBUTION OPTIONS    ***************************/
program define GetDistributionOptions, rclass

	if ("`0'"=="") | ("`0'"=="normal") {
		local k_aux = 0
		local eval "normal"
	}
	else if ("`0'"=="laplace") {
		local k_aux = 0
		local eval "laplace"
	}
	else if ("`0'"=="slaplace") {
		local k_aux = 1
		local eval "sged"
		constraint free
		constraint define `r(free)' [p]_cons=1
		local aux_constr `r(free)'
	}
	else if ("`0'"=="snormal") {
		local k_aux = 1
		local eval "sged"
		constraint free
		constraint define `r(free)' [p]_cons=2
		local aux_constr `r(free)'
	}
	else if ("`0'"=="ged") {
		local k_aux = 1
		local eval "sged"
		constraint free
		constraint define `r(free)' [lambda]_cons=0
		local aux_constr `r(free)'
	}
	else if ("`0'"=="sged") {
		local k_aux = 2
		local eval "sged"
	}
	else if ("`0'"=="t") {
		local k_aux = 1
		local eval "sgt"
		constraint free
		constraint define `r(free)' [lambda]_cons=0
		local aux_constr `r(free)'
		constraint free
		constraint define `r(free)' [p]_cons=2
		local aux_constr `aux_constr' `r(free)'
	}
	else if ("`0'"=="st") {
		local k_aux = 2
		local eval "sgt"
		constraint free
		constraint define `r(free)' [p]_cons=2
		local aux_constr `aux_constr' `r(free)'
	}
	else if ("`0'"=="gt") {
		local k_aux = 2
		local eval "sgt"
		constraint free
		constraint define `r(free)' [lambda]_cons=0
		local aux_constr `r(free)'
	}
	else if ("`0'"=="sgt") {
		local k_aux = 3
		local eval "sgt"
	}
	else {
		di as err "option distribution() specified incorrectly"
		error 198
	}

	if ("`eval'"=="sged") {
		local args0 "lambda p"
		local eqs0  "(lambda:) (p:)" 
	}
	else if ("`eval'"=="sgt") {
		local args0 "lambda p q"
		local eqs0  "(lambda:) (p:) (q:)" 
	}

	return local k_aux "`k_aux'"
	return local eval  "`eval'"
	return local args0 "`args0'"
	return local eqs0  "`eqs0'"
	return local aux_constr "`aux_constr'"
end


/**************************    EVALUATOR PROGRAMS   ***************************/
program goprobit2_normal_llf
	
	args lnf ${args}
	if (${univariate}) local mu ${ML_y}
	gettoken j J: (global) gloJ
	tempvar Fl Fu
	
	* Fl,Fu of minimum value of depvar
	quietly gen double `Fl' = 0                     if (${ML_y}==`j')
	quietly gen double `Fu' = normal(`cut`j''-`mu') if (${ML_y}==`j')
	
	* Fl,Fu of middle value(s) of depvar, if any (ie if 2+ categories)
	gettoken j J: J 
	while ("`J'"!="") {
		quietly replace `Fl' = normal(`cut`=`j'-1''-`mu') if (${ML_y}==`j')
		quietly replace `Fu' = normal(`cut`j''-`mu')      if (${ML_y}==`j')
		gettoken j J: J
	}
	
	* Fl,Fu of maximum value of depvar
	quietly replace `Fl' = normal(`cut`=`j'-1''-`mu') if (${ML_y}==`j')
	quietly replace `Fu' = 1                          if (${ML_y}==`j')

	* Bring it all together
	quietly replace `lnf' = ln(`Fu'-`Fl')

end


program goprobit2_laplace_llf
	
	args lnf ${args}
	if (${univariate}) local mu ${ML_y}
	gettoken j J: (global) gloJ
	tempvar Fl Fu
	local sigma = .70710678 // 1/sqrt(2)
	
	* Fl,Fu of minimum value of depvar
	quietly gen double `Fl' = 0                              if (${ML_y}==`j')
	quietly gen double `Fu' = laplace(`mu',`sigma',`cut`j'') if (${ML_y}==`j')
	
	* Fl,Fu of middle value(s) of depvar, if any (ie if 2+ categories)
	gettoken j J: J 
	while ("`J'"!="") {
		quietly replace `Fl' = laplace(`mu',`sigma',`cut`=`j'-1'') if (${ML_y}==`j')
		quietly replace `Fu' = laplace(`mu',`sigma',`cut`j'')      if (${ML_y}==`j')
		gettoken j J: J
	}
	
	* Fl,Fu of maximum value of depvar
	quietly replace `Fl' = laplace(`mu',`sigma',`cut`=`j'-1'') if (${ML_y}==`j')
	quietly replace `Fu' = 1                                   if (${ML_y}==`j')

	* Bring it all together
	quietly replace `lnf' = ln(`Fu'-`Fl')

end


program goprobit2_sged_llf
	
	args lnf ${args}
	if (${univariate}) local mu ${ML_y}
	gettoken j J: (global) gloJ
	tempvar Fl Fu phi Xl Xu Zl Zu
	
	* Phi calculation and helper variables
	quietly gen double `phi' = 1 / [sqrt(exp(lngamma(3/`p') - lngamma(1/`p'))*(3*`lambda'^2 + 1))]
	quietly gen double `Xl' = .
	quietly gen double `Xu' = .
	quietly gen double `Zl' = .
	quietly gen double `Zu' = .
	
	
	* Fl,Fu of minimum value of depvar
	quietly replace `Xu' = (`cut`j''-`mu')
	quietly replace `Zu' = abs(`Xu')^`p' / (`phi'^`p' * (1 + `lambda'*sign(`Xu'))^`p') 
	
	quietly gen double `Fl' = 0 if (${ML_y}==`j')
	quietly gen double `Fu' = /*
	*/ (1 - `lambda')/2 + ((1 + `lambda'*sign(`Xu'))/2) * sign(`Xu') * gammap(1/`p', `Zu') /*
	*/ if (${ML_y}==`j')
	
	* Fl,Fu of middle value(s) of depvar, if any (ie 2+ categories)
	gettoken j J: J 
	while ("`J'"!="") {
		quietly replace `Xl' = (`cut`=`j'-1''-`mu')
		quietly replace `Xu' = (`cut`j''-`mu')
		quietly replace `Zl' = abs(`Xl')^`p' / (`phi'^`p' * (1 + `lambda'*sign(`Xl'))^`p') 
		quietly replace `Zu' = abs(`Xu')^`p' / (`phi'^`p' * (1 + `lambda'*sign(`Xu'))^`p') 

		quietly replace `Fl' = /*
		*/ (1 - `lambda')/2 + ((1 + `lambda'*sign(`Xl'))/2) * sign(`Xl') * gammap(1/`p', `Zl') /*
		*/ if (${ML_y}==`j')
		quietly replace `Fu' = /*
		*/ (1 - `lambda')/2 + ((1 + `lambda'*sign(`Xu'))/2) * sign(`Xu') * gammap(1/`p', `Zu') /*
		*/ if (${ML_y}==`j')
		
		gettoken j J: J
	}
	
	* Fl,Fu of maximum value of depvar
	quietly replace `Xl' = (`cut`=`j'-1''-`mu')
	quietly replace `Zl' = abs(`Xl')^`p' / (`phi'^`p' * (1 + `lambda'*sign(`Xl'))^`p') 
	quietly replace `Fl' = /*
	*/ (1 - `lambda')/2 + ((1 + `lambda'*sign(`Xl'))/2) * sign(`Xl') * gammap(1/`p', `Zl') /*
	*/ if (${ML_y}==`j')
	quietly replace `Fu' = 1 if (${ML_y}==`j')

	* Bring it all together
	quietly replace `lnf' = ln(`Fu'-`Fl')

end


program goprobit2_sgt_llf
	
	args lnf ${args}
	if (${univariate}) local mu ${ML_y}
	gettoken j J: (global) gloJ
	tempvar Fl Fu phi Xl Xu Zl Zu
	
	* Phi calculation and helper variables
	quietly gen double `phi' = 1 / [sqrt((`q'^(2/`p')) * (exp(lngamma(3/`p') + lngamma(`q'-2/`p') - lngamma((3/`p')+(`q'-2/`p')) - (lngamma(1/`p') + lngamma(`q') - lngamma((1/`p')+`q'))) * (3*`lambda'^2 + 1)))]
	quietly gen double `Xl' = .
	quietly gen double `Xu' = .
	quietly gen double `Zl' = .
	quietly gen double `Zu' = .
	
	
	* Fl,Fu of minimum value of depvar
	quietly replace `Xu' = (`cut`j''-`mu')
	quietly replace `Zu' = abs(`Xu')^`p' / (abs(`Xu')^`p' + `q'*`phi'^`p' * (1 + `lambda'*sign(`Xu'))^`p')	
	
	quietly gen double `Fl' = 0 if (${ML_y}==`j')
	quietly gen double `Fu' = /*
	*/ (1 - `lambda')/2 + ((1 + `lambda'*sign(`Xu'))/2) * sign(`Xu') * ibeta(1/`p', `q', `Zu') /*
	*/ if (${ML_y}==`j')
	
	* Fl,Fu of middle value(s) of depvar, if any (ie 2+ categories)
	gettoken j J: J 
	while ("`J'"!="") {
		quietly replace `Xl' = (`cut`=`j'-1''-`mu')
		quietly replace `Xu' = (`cut`j''-`mu')
		quietly replace `Zl' = abs(`Xl')^`p' / (abs(`Xl')^`p' + `q'*`phi'^`p' * (1 + `lambda'*sign(`Xl'))^`p')
		quietly replace `Zu' = abs(`Xu')^`p' / (abs(`Xu')^`p' + `q'*`phi'^`p' * (1 + `lambda'*sign(`Xu'))^`p')

		quietly replace `Fl' = /*
		*/ (1-`lambda')/2 + ((1 + `lambda'*sign(`Xl'))/2) * sign(`Xl') * ibeta(1/`p', `q', `Zl') /*
		*/ if (${ML_y}==`j')
		quietly replace `Fu' = /*
		*/ (1-`lambda')/2 + ((1 + `lambda'*sign(`Xu'))/2) * sign(`Xu') * ibeta(1/`p', `q', `Zu') /*
		*/ if (${ML_y}==`j')
		
		gettoken j J: J
	}
	
	* Fl,Fu of maximum value of depvar
	quietly replace `Xl' = (`cut`=`j'-1''-`mu')
	quietly replace `Zl' = abs(`Xl')^`p' / (abs(`Xl')^`p' + `q'*`phi'^`p' * (1 + `lambda'*sign(`Xl'))^`p')
	quietly replace `Fl' = /*
	*/ (1-`lambda')/2 + ((1 + `lambda'*sign(`Xl'))/2) * sign(`Xl') * ibeta(1/`p', `q', `Zl') /*
	*/ if (${ML_y}==`j')
	quietly replace `Fu' = 1 if (${ML_y}==`j')

	* Bring it all together
	quietly replace `lnf' = ln(`Fu'-`Fl')

end
