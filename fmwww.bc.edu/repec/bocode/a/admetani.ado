* -admetani- 
* "Immediate" form of admetan
* for quick pooling of, say, 2 or 3 estimates

*! version 1.0  David Fisher  11may2017
*! (part of version 2.0 of -ipdmetan- package)


program admetani, rclass

	version 11.0
	
	* Valid inputs are:
	// a matrix name, e.g. A
	// a matrix inputted by hand, e.g. (1, 2 \ 3, 4); see help matrix define
	// the syntax of tabi, e.g. 1 2 \ 3 4; see help tabi
	cap syntax anything [, NPTS(numlist missingok) ROWNames ROWTitle(string) ///
		noKEEPVars noRSample * ]
	// (these last options are just needed to decide what to do with extra obs, if relevant)
	
	* If -syntax- didn't work, assume due to commas but no brackets
	if _rc {
		disp as err "invalid syntax"
		disp as err "Valid syntaxes are:"
		disp as err `" matrix-style input {bf:(} {it:a}{bf:,} {it:b} {bf:\} {it:c}{bf:,} {it:d} {bf:)}; see {help matrix define}"'
		disp as err `" or {bf:tabi}-style input {it:a} {it:b} {bf:\} {it:c} {it:d}; see {help tabi}"'
		exit _rc
	}

	tempname A
	cap matrix define `A' = `anything'
	
	* If -matrix define- didn't work, try "tabi"-style syntax
	if _rc {
		local c = 1
		gettoken tok rest : anything, parse(",\() ")
		while (`"`tok'"'!="" & `"`tok'"'!=",") {
			if !inlist(`"`tok'"', `"("', `"("') {
				if `"`tok'"' != `"\"' {
					local anything2 = cond(`c'==1, `"`anything2' `tok'"', `"`anything2', `tok'"')
					local ++c
				}
				else {
					local anything2 `"`anything2' \ "'
					local c = 1
				}
			}
			gettoken tok rest : rest, parse(",\() ")
		}
		
		// try again
		matrix define `A' = (`anything2')
	}
	
	capture {
		local nr = rowsof(matrix(`A'))
		local nc = colsof(matrix(`A'))
	}
	if _rc {
		disp as err "matrix {bf:`A'} not found"
		exit 111
	}
	if `nc' > 6 {
		disp as err `"Note: matrix {bf:`A'} has more than six columns; extra columns will be ignored"'
	}	
	
	local rsample = cond(`"`keepvars'"'!=`""', `"norsample"', `"`rsample'"')
	// no point in keeping _rsample without keepvars in this context!
	
	// my own "hacked" version of svmat.ado, allowing temp varnames for the columns
	forvalues j = 1/`nc' {
		tempvar tv`j'
	}
	local old_N = _N
	if `nr' > _N {
		if `"`rsample'"'!=`""' preserve
		nois set obs `nr'
	}
	capture {
		local j = 1
		while `j' <= `nc' {
			gen `tv`j'' = matrix(`A'[_n, `j']) in 1/`nr'
			local ++j
		}
	}
	if _rc {
		qui drop if _n > `old_N'
		exit _rc
	}
	cap compress `tv1'-`tv`nc''
	
	// extract rownames; pass to admetan as study names
	if `"`rownames'"'!=`""' {
		tempvar study
		qui gen `study' = ""
		local names : rowfullnames `inputmat'
		tokenize `names'
		local i = 1
		while `"`1'"' != `""' {
			qui replace `study' = `"`1'"' in `i'
			mac shift
			local ++i
		}
		if `"`rowtitle'"'!=`""' {
			label variable `study' `"`rowtitle'"'
		}
		else label variable `study' `"Matrix rowname"'
		
		local options `"study(`study') `options'"'
	}
	
	// extract npts
	if `"`npts'"'!=`""' {
		cap assert `: word count `npts'' == `nr'
		if _rc {
			disp as err "Number of elements in {bf:npts()} does not match with dimensions of inputted data"
			exit 198
		}
		tempvar nptsvar
		qui gen long `nptsvar' = .
		tokenize `npts'
		forvalues i = 1/`nr' {
			qui replace `nptsvar' = ``i'' in `i'
		}
		
		local options `"npts(`nptsvar') `options'"'
	}	
	
	// pass to admetan
	cap nois admetan `tv1'-`tv`nc'', `keepvars' `rsample' `options'
	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:admetan}"'
			else nois disp as err `"Error in {bf:admetan}"'
		}
		qui drop if _n > `old_N'
		exit _rc
	}

	return add
	if `"`keepvars'"'!=`""' qui drop if _n > `old_N'
	
end
