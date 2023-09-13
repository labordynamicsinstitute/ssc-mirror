*! version 2.0.0 07Sep2022
program define sotable_getextract, rclass

	version 16

	syntax , plist(string)

	tempname b

	matrix `b' = e(b)
	local cfnames : colfullnames `b'

	local k_n     : word count `cfnames'
	local k_b     = colsof(`b')

	_ms_omit_info `b'
	tempname omits
	matrix `omits' = r(omit)

	qui preserve 
	qui drop _all
	qui set obs `k_n'
	qui generate eqname   = ""
	qui generate pname    = ""
	qui generate pnumber  = _n
	qui generate omit     = .

	local j = 1
	foreach next of local cfnames {
	
		parsename , pname(`next')
		local eqn `r(eqn)'
		local pn  `r(pn)'

		qui replace eqname = "`eqn'" in `j'
		qui replace pname  = "`pn'"  in `j'
		qui replace omit   = `omits'[1,`j']

		local ++j
	}

	qui generate eqnumber = 1 in 1
	qui replace eqnumber  = (eqname != eqname[_n-1]) in 2/l
	qui replace  eqnumber = sum(eqnumber)

	qui drop if omit==1

	qui frame copy default pinfo, replace

	getpinfo, plist(`plist')

	local pnlist `r(pnlist)' 

	qui restore

	return local toget `pnlist'
end

program define parsename, rclass

	syntax , pname(string)

	gettoken first second : pname , parse(":")

	if "`second'"==":" {
		if "`first'" == "/" {
			di `"{err}`pname' invalid specification"'
			di `"{text}/ parameters must be accessed indvidually"'
			exit 498
		}
		else {
			local eqn "`first'"
			local pn  ""
		}
	}
	else if "`second'"==":" {
		if "`first'" == "" {
			di `"{err}`pname' invalid"'
			exit 498
		}
		else {
			local eqn "`first'"
			local pn  ""
		}
	}
	else if "`second'"=="" {
		local eqn ""
		if "`first'" == "" {
			di "{err}problem parsing parameter names"
			exit 498
		}
		else {
			local pn  "`first'"
		}
	}
	else {
		local eqn "`first'"
		gettoken c d : second , parse(":")
		local pn  "`d'"
	}

	if `"`eqn'"' == "/" {
		local eqn
		local pn /`pn'
	}

	return local eqn `eqn'
	return local pn  `pn'

end

program define getpinfo, rclass

	syntax , plist(string)

	foreach pspec of local plist {
		qui drop _all
		qui frame copy pinfo default, replace

		parsename , pname(`pspec')
		local eqn `r(eqn)'
		local pn  `r(pn)'

		_ms_parse_parts `pn'
		if `r(omit)' == 1 {
			di "parameter `pspec' was omitted, removing it from list"
		}
		else {
			local slash = usubstr(`"`pn'"', 1, 1)
			if "`eqn'" == "" & `"`slash'"' != "/" {
				qui keep if eqnumber == 1
			}
			else {
				qui keep if eqname == "`eqn'"
				if _N == 0 {
					di "{err}`pn' invalid"
					di "{text}equation `eqn' not found"
					exit 498
				}
			}

			if "`pn'" == "" {
				local N = _N
				forvalues j2=1/`N' {
					local pnj = pname[`j2']
					_ms_parse_parts `pnj'
					if `r(omit)' == 1 {
						di "parameter `eqn:`pnj' was omitted, removing it from list"
					}
					else {
						local tmp = pnumber[`j2']
						local pnlist `pnlist' `tmp'
					}
				}
			}
			else {
				qui keep if pname == "`pn'"
				if _N == 0 {
					di "{err}`pn' invalid"
					di "{text}parameter `pspec' not found"
					exit 498
				}

				if _N > 1 {
					di "{err}`pn' invalid"
					di "{text}duplicate parameters found"
					exit 498
				}
				local tmp = pnumber[1]
				local pnlist `pnlist' `tmp'
			}

		}
	}

	local pnlist : list uniq pnlist

	return local pnlist  `pnlist' 
end

exit

returns list elements in e(b) specified by name in pnames()

  #. any element in e(b) that matches eqn:pn is found and put in list

  #. eqn: specifies that the parameters in equation eqn are to  be
     in found list

  #.  duplicate element numbers are removed

  #. :pn or pn  are understood to be references to pn in the first equation
     in e(b)

  #. both /lnsigma and /:lnsigma include the parameter named /:lnsigma in e(b)

  #. you cannot get all the parameters from the slash equation ; plist(/:)
     returns an error
