*! vreverse9 1.4.0 NJC 28 August 2024 
*! 1.3.0 NJC 19 September 2008 
*! 1.2.0 NJC 17 October 2007 
*! 1.1.0 NJC 1 September 2003 
*! vreverse 1.0.0 NJC 5 August 2003 
program vreverse9
	version 9
	syntax varname(numeric) [if] [in], GENerate(str) ///
	[ VALuelabelname(str) REMOVEnumlabel Mask(str)] 
	
	capture confirm new var `generate' 
	if _rc {
		di as err "generate() requires new variable name"
		exit 198
	} 	

    if "`: value label `varlist''" == "" { 
		di as txt "note: " as res "`varlist' " as txt "not labeled"
		// 1.2.0: no longer an error; was exit 182 
	}

	if "`mask'" != "" & "`removenumlabel'" == "" { 
		di as err "mask() option without removenumlabel option" 
		exit 198 
	} 	

	if "`removenumlabel'" != "" { 
		if "`mask'" == "" local mask "#. " 
		local remove 1 
	} 
	else local remove 0 

	marksample touse, novarlist 
	quietly {
		count if `touse' 
		if r(N) == 0 error 2000 

		capture assert `varlist' == int(`varlist') if `touse'
		if _rc { 
			di as err "non-integer values in `varlist'"
			exit 498
		}	
	
		su `varlist' if `touse', meanonly 
		local max = r(max)
		local min = r(min)

		local type : type `varlist' 
		gen `type' `generate' = (`min') + (`max') - `varlist' if `touse' 
		replace `generate' = `varlist' if missing(`varlist') 
		
		local lblname = ///
		cond("`valuelabelname'" != "", "`valuelabelname'", "`generate'") 
		levelsof `varlist' if `touse', missing local(levels) 
		
		foreach l of local levels { 
			if `l' < . {
				local i = `min' + `max' - `l'
			}
			else local i = `l'
			local label : label (`varlist') `l' 
			if `remove' { 
				local Mask : subinstr local mask "#" "`l'"
				local label : subinstr local label "`Mask'" ""
			}	
			if `i' != . label def `lblname' `i' `"`label'"', modify 
		} 	
		label val `generate' `lblname' 

		label var `generate' "`: variable label `varlist''"  
		
		format `generate' `: format `varlist''
		
		tokenize `"`: char `varlist'[]'"' 
		while `"`1'"' != "" {
			char `generate'[`1'] `"`: char `varlist'[`1']'"' 
			mac shift 
		}
	}
end 	
