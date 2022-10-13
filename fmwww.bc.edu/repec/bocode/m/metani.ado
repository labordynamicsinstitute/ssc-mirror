* -metani- 
* "Immediate" form of -metan-
* for quick pooling of, say, 2 or 3 estimates

* version 1.0  David Fisher  11may2017
// (part of version 2.0 of -ipdmetan- package)

* version 1.01  David Fisher  14sep2017
// (part of version 2.1 of -ipdmetan- package)

* version 3.0  David Fisher  08nov2018
// (N.B. only changed very slightly from v1.01 ... this is actually more v1.02!)

* version 4.0  David Fisher  25nov2020
// changed from -admetani- to -metani-
// upversioned to match with the rest of -metan- package

* version 4.01  David Fisher  12feb2021
* version 4.02  David Fisher  23feb2021
* version 4.03  David Fisher  28apr2021
* version 4.04  David Fisher  16aug2021
// No changes; upversioned to match with the rest of -metan- package

* version 4.05 David Fisher  29nov2021
// added ability to specify a value label for studies, instead of rownames
// syntax notes:
// - studylabel() on its own = apply label to studies labelled "naturally" i.e. 1, 2, ...
// - studylabel() + rownames = label studies with (numeric) rownames; then apply label to those values
// - rowfullnames, roweq work the same way.
// If row[eq|[full]names] are non-numeric with studylabel(), exit with error.

*! version 4.06  David Fisher  12oct2022
// No changes; upversioned to match with the rest of -metan- package


program metani, rclass

	version 11.0
	
	* Valid inputs are:
	// a matrix name, e.g. A
	// a matrix inputted by hand, e.g. (1, 2 \ 3, 4); see help matrix define
	// the syntax of tabi, e.g. 1 2 \ 3 4; see help tabi
	cap syntax anything [, NPTS(string) noKEEPVars noRSample ///
		ROWNames ROWFullnames ROWEq Quoted ROWTitle(string) ROWLabel(name) ///
		STUDYTitle(string) STUDYLabel(name) VARiances * ]
	// (these last options are just needed to decide what to do with extra obs, if relevant)

	local metan_opts : copy local options
	
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
		local nr = rowsof(`A')
		local nc = colsof(`A')
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
			qui gen `tv`j'' = matrix(`A'[_n, `j']) in 1/`nr'
			local ++j
		}
	}
	if _rc {
		qui drop if _n > `old_N'
		exit _rc
	}
	cap compress `tv1'-`tv`nc''
	
	// labelling of rownames; pass to -metan- as study names
	opts_exclusive `"`rownames' `rowfullnames' `roweq'"' `""' 184
	if `"`rowlabel'"'!=`""' | `"`studylabel'"'!=`""' {
		if `"`rowlabel'"'!=`""' & `"`studylabel'"'!=`""' {
			nois disp as err `"only one of {bf:rowlabel()} and {bf:studylabel()} is allowed"'
			exit 184
		}
		if `"`rowlabel'"'!=`""' local labelopt rowlabel
		else local labelopt studylabel
	}
	if `"`rowtitle'"'!=`""' & `"`studytitle'"'!=`""' {
	    nois disp as err `"only one of {bf:rowtitle()} and {bf:studytitle()} is allowed"'
		exit 184
	}

	// matrix rownames/equation names
	if `"`rownames'`rowfullnames'`roweq'"'!=`""' {
	    local rc = 0
		tempvar study
		qui gen `study' = ""
		local names : `rownames'`rowfullnames'`roweq' `A', `quoted'
		tokenize `"`names'"'
		local i = 0
		while `"`1'"' != `""' {
			local ++i
		    if `i' > `nr' {
			    local rc = 9
				continue, break
			}
			qui replace `study' = `"`1'"' in `i'
			mac shift
		}
		cap assert `i'==`nr'
		local rc = max(`rc', _rc)
		if `rc' {
		    nois disp as err `"Number of elements in list of matrix row[eq]names does not match with matrix size"'
			exit `rc'
		}		
	}
	
	// value label
	if `"`rowlabel'`studylabel'"'!=`""' {
		
		// try to apply to rownames
		if `"`rownames'`rowfullnames'`roweq'"'!=`""' {
			qui destring `study', replace
			cap {
				confirm numeric variable `study'
				label values `study' `rowlabel'`studylabel'
			}
			if _rc {
				nois disp as err `"Error when applying value label {bf:`rowlabel'`studylabel'}"'
				nois disp as err `"Check that values stored in matrix row[eq]names are integers"'
				exit _rc
			}
		}
		
		// else, generate study as 1, 2, ... and apply there
		else {
			nois disp `"{error}Note: value label {bf:`rowlabel'`studylabel'} will be applied to studies numbered sequentially from 1"'
			tempvar study
			qui gen `study' = _n in 1 / `nr'
			cap label values `study' `rowlabel'`studylabel'
			if _rc {
				nois disp as err `"Error when applying value label {bf:`rowlabel'`studylabel'}"'
				exit _rc
			}
		}
	}

	// variable label ("title")
	cap confirm variable `study'
	if !_rc {
		if `"`rowtitle'`studytitle'"'!=`""' {
			label variable `study' `"`rowtitle'`studytitle'"'
		}
		else label variable `study' `"Matrix rowname"'

		local metan_opts `"study(`study') `metan_opts'"'
	}
	
	// extract npts
	if `"`npts'"'!=`""' {
		tempvar nptsvar
		qui gen long `nptsvar' = .
		cap numlist "`npts'", missingok
		
		// if numlist
		if !_rc {
			cap assert `: word count `npts'' == `nr'
			if _rc {
				disp as err "Number of elements in {bf:npts()} does not match with dimensions of inputted data"
				exit 198
			}
			tokenize `npts'
			forvalues i = 1/`nr' {
				qui replace `nptsvar' = ``i'' in `i'
			}
		}
		
		// else, test if vector
		else {
			cap {
				assert `: word count `npts'' == 1
				confirm matrix `npts'
			}
			if _rc {
				disp as err "option {bf:npts()} should contain either a {it:numlist} or a matrix name"
				exit 198
			}
			cap assert colsof(`npts')==1
			if _rc {
				cap assert rowsof(`npts')==1
				if _rc {
					disp as err "matrix {bf:npts()} is not of the required dimensions"
					exit 198
				}
				cap assert colsof(`npts')==`nr'
				if _rc {
					disp as err "Number of elements in {bf:npts()} does not match with dimensions of inputted data"
					exit 198
				}
				forvalues i = 1/`nr' {
					qui replace `nptsvar' = `npts'[1, `i'] in `i'
				}
			}
			else {
				cap assert rowsof(`npts')==`nr'
				if _rc {
					disp as err "Number of elements in {bf:npts()} does not match with dimensions of inputted data"
					exit 198
				}
				forvalues i = 1/`nr' {
					qui replace `nptsvar' = `npts'[`i', 1] in `i'
				}
			}
		}
		
		local metan_opts `"npts(`nptsvar') `metan_opts'"'
	}	
	
	// convert variances to standard errors if necessary
	if `"`variances'"'!=`""' {
		if `nc'!=2 {
			disp as err "option {bf:variances} is only relevant to two-element syntax, and will be ignored"
		}
		else qui replace `tv2' = sqrt(`tv2')
	}
	
	// pass to -metan-
	cap nois metan `tv1'-`tv`nc'', `keepvars' `rsample' `metan_opts'
	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:metan}"'
			else nois disp as err `"Error in {bf:metan}"'
		}
		qui drop if _n > `old_N'
		exit _rc
	}

	return add
	if `"`keepvars'"'!=`""' qui drop if _n > `old_N'
	
end
