program define var_nr, rclass
version 16.0

	syntax name(name=ident id="identification") , VARname(string) OPTname(string) [LINtrend(varname) QUADtrend(varname)]
	
	// add check that lags are 1 2 ... n (not skipping or missing)
	
	// check that var or svar were run
	loc cmd = "`e(cmd)'"
	if ("`cmd'"!="var" & "`cmd'"!="svar") {
		di as err "Must run {cmd:var} or {cmd:svar} before running {cmd:var_nr}"
		exit 198
	}
	
	// 
	if ("`ident'"!="sr" & "`ident'"!="bq" & "`ident'"!="oir") {
		di as error "Identification must = {oir}, {bq}, or {sr}"
		exit 198
	}
	
	// must specify linear trend if specifying quadratic trend
	if "`lintrend'"=="" & "`quadtrend'"!="" {
		di as err "{cmd:quadtrend} cannot be specified without {cmd:lintrend}"
		exit 198
	}
	loc ltr = "`lintrend'"
	loc qtr = "`quadtrend'"
	// quad trend cannot equal lin trend
	if ("`lintrend'"!="" & "`quadtrend'"!="" & ("`ltr'"=="`qtr'")) {
		di as err "{cmd:quadtrend} variable cannot be the same as {cmd:lintrend} variable"
		exit 198
	}
	
	// cannot suppress constant if including a trend
	if ("`e(nocons)'"=="nocons" & "`ltr'"!="") {
		di as err "{cmd:noconstant} cannot be specified with {cmd:lintrend}"
		exit 198
	}
	
	// lintrend and quadtrend must reference variables included in (s)var exog()
	if "`lintrend'"!="" {
		tokenize "`e(exog)'"
		if "`1'"=="" {
			di as err "linear trend variable must be included in (s)var in exog()"
			exit 198
		}
		loc check = 0
		loc wc = wordcount("`e(exog)'")
		foreach ii of numlist 1/`wc' {
			if ("``ii''"=="`lintrend'") {
				loc check = 1
			}
		}
		if `check'==0 {
			di as err "linear trend variable must be included in (s)var in exog()"
			exit 198
		}
		else {
			if "`quadtrend'"!="" {
				loc check = 0
				foreach ii of numlist 1/`wc' {
					if ("``ii''"=="`quadtrend'") {
						loc check = 1
					}
				}
				if `check'==0 {
					di as error "quadratic trend variable must be included in (s)var in exog()"
					exit 198
				}
			}
		}
	}
	
	// exogenous vars
	if ("`e(exog)'"!="") {
		loc exog_list = "`e(exog)'"
		loc wc = wordcount("`e(exog)'")
		loc nlag_ex = subinstr("`e(exlags)'", ":", " ", .)
		loc nlag_ex = subinstr("`nlag_ex'", " ", ",", .)
		loc nlag_ex = max(0,`nlag_ex')
		tokenize "`e(exog)'"
		// make lagged exogenous variable matrix
		mat EXO = J((_N)-`nlag_ex',1,.)
		foreach ii of numlist 1/`wc' {
			if ("``ii''"!="`ltr'" & "``ii''"!="`qtr'") {
				if (strpos("``ii''",".")==0) {
					mkmat ``ii'', matrix(temp_mat)
					mat temp_mat = temp_mat[`nlag_ex'+1...,1]
				}
				else if (strpos("``ii''","L0.")==1) {
					loc temp_varname = subinstr("``ii''","L0.","",1)
					mkmat `temp_varname', matrix(temp_mat)
					mat temp_mat = temp_mat[`nlag_ex'+1...,1]
				}
				else if (strpos("``ii''","L1.")==1 | strpos("``ii''","L.")==1) {
					loc temp_varname = subinstr("``ii''","L1.","",1)
					loc temp_varname = subinstr("``ii''","L.","",1)
					mkmat `temp_varname', matrix(temp_mat)
					mat temp_mat = temp_mat[`nlag_ex'..(_N)-1,1]
				}
				else if (strpos("``ii''","L")==1 & strpos("``ii''",".")!=0) {
					loc temp_varname = subinstr("``ii''","L","",1)
					loc temp_nlag = substr("`temp_varname'",1,strpos("``temp_varname''",".")-1)
					loc temp_varname = substr("``ii''",strpos("``ii''",".")+1,.)
					mkmat `temp_varname', matrix(temp_mat)
					mat temp_mat = temp_mat[`nlag_ex'+1-`temp_nlag'..(_N)-`temp_nlag',1]
				}
				mat EXO = EXO,temp_mat
			}
		}
		if (colsof(EXO)>=2) {
			mat EXO = EXO[.,2...]
			loc nvar_ex = colsof(EXO)
		}
		else {
			loc nvar_ex = 0
			loc nlag_ex = 0
		}
	}
	else {
		loc nvar_ex = 0
		loc nlag_ex = 0
	}
	
	// get time series variable and format (for plotting)
	qui tsset, noquery
	if ("`r(timevar)'"=="") {
		di as error "time variable not set, use tsset varname ..."
		exit 111
	}
	loc tsrs_var "`r(timevar)'"
	loc tsrs_dlt "`r(tsfmt)'"

	// get endogenous variable list, number endog vars, lag order of endog vars
	loc end_list = "`e(endog)'"
	loc nvar = wordcount("`e(endog)'")
	loc nlag = wordcount("`e(lags)'")
	
	// code based on presence of constant/trend(s)
	if "`quadtrend'"!="" loc cconst=3
	else if "`lintrend'"!="" loc cconst=2
	else if "`e(nocons)'"!="nocons" loc cconst=1
	else loc cconst=0
	
	// pass variables and identification settings into Mata, store OLS objects in var_struct
	mata: `varname' = var_funct("`end_list'","`nvar'", "`nlag'", /*
					   */ "`cconst'", "`nvar_ex'", "`nlag_ex'", /*
					   */ "`tsrs_var'", "`tsrs_dlt'", "EXO")
					   
	// initialize opts_struct structure with default options, set identification option
	mata: `optname' = opt_set()
	mata: `optname'.ident = "`ident'"

end