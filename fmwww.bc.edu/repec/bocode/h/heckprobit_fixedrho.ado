*!  version 1.0.0 01jun2020

program  heckprobit_fixedrho
    version 11
	
	syntax varlist(numeric default=none ts fv) [if] [in], SELect(string) rho(real) [Robust vce(string) DIFficult TOLerance(real 1e-6) LTOLerance(real 1e-7) NRTOLerance(real 1e-5) SHOWTOLerance nolog level(cilevel)]
	SelectEq seldep selind selnc seloff : `"`select'"'
	
	local maxopts `difficult' tol(`tolerance')  `showtolerance'	`nolog'	 ///
		ltol(`ltolerance') nrtol(`nrtolerance') 

	if `rho' < -1 | `rho' > 1 {
		noi di in red "value of rho must be between -1 and 1"
		exit 198
	}
		
	global rho = `rho'
	gettoken y rhs : varlist
	tempvar y_for_ML
	qui gen `y_for_ML' = `y'
	qui replace `y_for_ML' = 0 if missing(`y_for_ML')
	
	ml model lf heckprobit_fixedrho_lf  (`y': `y_for_ML'=`rhs') (`seldep': `seldep' = `selind') `if' `in', `robust' vce(`vce') title(Heckprob with a specified value of rho)
	ml max, `maxopts' level(`level')
	version 11: _diparm __lab__, label(rho) value($rho) 
	version 11: _diparm __bot__
end

/* process the selection equation
	[depvar =] indvars [, noconstant offset ]
   This was heavily borrowed from the heckman command
*/

program define SelectEq
	args seldep selind selnc seloff colon sel_eqn

	gettoken dep rest : sel_eqn, parse(" =")
	gettoken equal rest : rest, parse(" =")

	if "`equal'" == "=" { 
		_fv_check_depvar `dep'
		tsunab dep : `dep'
		c_local `seldep' `dep' 
	}

	else	local rest `"`sel_eqn'"'
	local 0 `"`rest'"'
	syntax [varlist(numeric default=none ts fv)] 	/*
		*/ [, noCONstant OFFset(varname numeric) ]

	if "`s(fvops)'" == "true" {
		c_local fvops 1
	}
	if "`varlist'" == "" {
		di in red "no variables specified for selection equation"
		exit 198
	}
	c_local `selind' `varlist'
	c_local `selnc' `constant'
	c_local `seloff' `offset'
end
