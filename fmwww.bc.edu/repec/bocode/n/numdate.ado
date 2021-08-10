*! 1.4.1 NJC 29 September 2015 
* 1.4.0 NJC 21 August 2015 
* 1.3.0 NJC 19 August 2015 
* 1.2.0 NJC 18 August 2015 
* 1.1.0 NJC 14 August 2015 
* 1.0.0 NJC 12 August 2015 
program numdate 
	version 12 

	/// get and check user date-time type, zapping any hyphens or percents 
	gettoken utype 0 : 0 
	local utype : subinstr local utype "-" "", all 
	local utype : subinstr local utype "%" "", all 

	/// -- allowed are any Stata abbreviations 	
	tokenize "tc tC td td tw tm tq th ty" 

	/// -- or (abbreviations of) any longer names 
	///    date() predated daily() 
	local T clock Clock daily date weekly monthly quarterly ///
	halfyearly yearly 

	local OK = 0 

	forval t = 1/9 { 
		if "`utype'" == "``t''" { 
			local dtype "`: word `t' of `T''" 
			local OK 1 
			continue, break 
		}
	} 

	if `OK' == 0 { 
		local len = length("`utype'") 
		foreach t of local T {  
			if "`utype'" == substr("`t'", 1, `len') { 
				local dtype "`t'" 
				local OK 1 
				continue, break 
			}
		} 
	}

	if `OK' == 0 { 
		di as err "`utype' unrecognised kind of date-time" 
		exit 498 
	} 

	// newvar = 
	gettoken newvar 0 : 0, parse("= ")  
	confirm new var `newvar' 
	gettoken eqs 0 : 0, parse("= ") 
	if "`eqs'" != "=" { 
		di as err "invalid syntax" 
		exit 198
	} 

	/// rest of syntax
	/// clean() undocumented
	syntax varlist [if] [in] , ///
	Pattern(str) [Format(str) Dryrun Topyear(numlist int max=1) Clean] 

	marksample touse, strok 
	quietly count if `touse' 
	if r(N) == 0 error 2000 

	/// existing variable(s) could be string or numeric 
	local oldvar `varlist' 

    /// if format requested check consistency with date type 
	/// else default format assigned 
	local t = substr("`dtype'", 1, 1)  
	if "`format'" != "" { 
		/// treat "%-" as if "%" 
		local Format : subinstr local format "%-" "%" 
		if substr("`Format'", 3, 1) != "`t'" { 
			di as err "`format' format does not match `dtype'" 
			exit 498 
		}
	} 
	else local format %t`t'

	/// concatenate multiple input into one string variable 
	local nvars : word count `oldvar' 
	if `nvars' > 1 { 
		tempvar combined 
		egen `combined' = concat(`oldvar'), p(" ") 
		local oldvar `combined' 
	} 

	/// optionally clean strings of non-numeric characters 
	if "`clean'" != "" { 
		capture confirm str var `oldvar' 

		quietly if _rc == 0 {               
			tempvar s length 
			gen `s' = `oldvar' 
			gen `length' = length(`s') 
			su `length', meanonly 

			forval j = 1/`r(max)' { 
				local c substr(`s', `j', 1) 
				replace `s' = subinstr(`s', `c', " ", .) ///
				if !inrange(`c', "0", "9") 
			}
		}

		local oldvar "`s'" 
	} 

	/// dry run or for real 	
    if "`dryrun'" != "" { 
		char `oldvar'[varname] "`varlist'" 
		Tryit `touse' `newvar' `oldvar' `dtype' "`pattern'" `format' `topyear' 
	} 
	else Doit `touse' `newvar' `oldvar' `dtype' "`pattern'" `format' `topyear' 
end 

program Tryit 
	args touse newvar oldvar dtype pattern format topyear 
	tempvar work toshow nmiss 

	if inlist("`dtype'", "clock", "Clock") { 
		local vtype "double" 
	} 

	quietly { 
		capture confirm str var `oldvar' 
		if _rc {
			local savename "`oldvar'" 
			tempvar strvar
			// 30 is plucked out of the air  
			gen `strvar' = string(`oldvar', "%30.0f") 
			local oldvar "`strvar'"
			char `oldvar'[varname] "`savename'" 
		}  

		if "`topyear'" != "" { 
			gen `vtype' `work' = `dtype'(`oldvar', "`pattern'", `topyear') if `touse' 
		}	 
		else gen `vtype' `work' = `dtype'(`oldvar', "`pattern'") if `touse' 
	
		gen `toshow' = sum(`touse' & (`work' < .)) 
		gen `nmiss' = sum(`touse' & (`work' == .))  
	}

	format `work' `format' 
	local len = max(length("`: char `oldvar'[varname]'"), length("`newvar'")) 
	char `work'[varname] "`newvar'" 

	list `oldvar' `work' if `touse' & `toshow' <= 5 & `nmiss' <= 20, ///
	subvarname abbrev(`len')

	di _n as txt "{p}note: " ///   
	"`newvar' is not yet a variable in your dataset{p_end}"  

	if `toshow'[_N] == 0 { 
		di _n as txt "{p}all values would be missing: " ///
		"check {stata help datetime}{p_end}" 
	} 
end 
		
program Doit 
	args touse newvar oldvar dtype pattern format topyear 

	if inlist("`dtype'", "clock", "Clock") { 
		local vtype "double" 
	}

	capture confirm str var `oldvar' 
	if _rc {
		di as txt "note: `oldvar' is numeric; converting contents to string" 
		tempvar strvar 
		// 30 is plucked out of the air  
		quietly gen `strvar' = string(`oldvar', "%30.0f") if `touse' 
		local oldvar "`strvar'"
	}  

	if "`topyear'" != "" { 
		gen `vtype' `newvar' = `dtype'(`oldvar', "`pattern'", `topyear') if `touse' 
	} 
	else gen `vtype' `newvar' = `dtype'(`oldvar', "`pattern'") if `touse' 

	quietly if "`dtype'" == "" compress `newvar' 
	format `newvar' `format' 
end 

