*! version 1.0.0  19feb2025

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
