*!  version 1.0.0 01jun2020

program  biprobit_fixedrho
    version 11
	
	syntax varlist(numeric default=none ts fv)[if] [in], eq2(string) rho(real) [Robust vce(string) DIFficult TOLerance(real 1e-6) LTOLerance(real 1e-7) NRTOLerance(real 1e-5) SHOWTOLerance nolog level(cilevel)]
	SecEq dep2 ind2 selnc seloff : `"`eq2'"'
		
	
	local maxopts `difficult' tol(`tolerance') 	`showtolerance'	`nolog'	 ///
		ltol(`ltolerance') nrtol(`nrtolerance') 
		
	if `rho' < -1 | `rho' > 1 {
	  noi di in red "value of rho must be between -1 and 1"
	  exit 198
	}
	
	global rho = `rho'

	gettoken dep1 ind1 : varlist

	ml model lf biprobit_fixedrho_lf (`dep1': `dep1'=`ind1') (`dep2': `dep2' = `ind2') `if' `in', `robust' vce(`vce') title(Biprobit with a specified value of rho)
	ml search
	ml max, `maxopts' level(`level')
	version 11: _diparm __lab__, label(rho) value($rho) 
	version 11: _diparm __bot__
end

/*
   This was heavily borrowed from the heckman command
*/
program define SecEq
	args dep2 ind2 selnc seloff colon sel_eqn

	gettoken dep rest : sel_eqn, parse(" =")
	gettoken equal rest : rest, parse(" =")

	if "`equal'" == "=" { 
		_fv_check_depvar `dep'
		tsunab dep : `dep'
		c_local `dep2' `dep' 
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
	c_local `ind2' `varlist'
	c_local `selnc' `constant'
	c_local `seloff' `offset'
end
