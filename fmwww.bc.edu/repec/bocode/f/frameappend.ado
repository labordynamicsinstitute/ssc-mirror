*! version 1.3 - 26 Oct 2020 // better ordering of variables, fixes underscore problem
*! thanks Daniel Fernandes and Roger Newsom for code used in revisions
*! version 1.2 -  22 Sep 2020 // checks string/numeric and uses tempnames throughout 
* version 1.1 -  01 Dec 2019 // fixed bug with very large files and variables starting with underscore

program define frameappend

	version 16.0

	syntax namelist(name=frame_name max=1) [, drop]

	** get lists of variables to be combined
	quietly {
		ds
		local to_varlist "`r(varlist)'"

		frame `frame_name': ds
		local from_varlist "`r(varlist)'"

		local shared_varlist : list from_varlist & to_varlist
		local new_varlist : list from_varlist - shared_varlist

		if "`shared_varlist'" != "" {
			foreach type in numeric string{
				ds `shared_varlist', has(type `type')
				local `type'_to "`r(varlist)'"
				frame `frame_name': ds `shared_varlist', has(type `type')
				local `type'_from "`r(varlist)'"
				local `type'_eq: list `type'_to === `type'_from
			}
			if (`numeric_eq' == 0) | (`string_eq' == 0) {
				di as err "shared variables in frames being combined must be both numeric or both string"
				error 109
			}
		}
		
	* get size of new dataframe
		frame `frame_name' : local from_N = _N
		local to_N = _N
		local from_start = `to_N' + 1
		local new_N = `to_N' + `from_N'

		set obs `new_N'
		tempvar temp_n temp_link
		gen double `temp_n' = _n
		frame `frame_name' {
			gen double `temp_n' = _n + `to_N'
		}
	
		frlink 1:1 `temp_n', frame(`frame_name') gen(`temp_link')
	
	if "`shared_varlist'"!="" {
	  tempvar temphome
	  foreach X of varlist `shared_varlist' {
	    frget `temphome'=`X', from(`temp_link')
	    replace `X'=`temphome' in `=`to_N'+1' / `new_N'
	    drop `temphome'
	  }
	}
	if "`new_varlist'" != "" {
	  tempvar temphome2
	  foreach X in `new_varlist' {
	    frame `frame_name': qui clonevar `temphome2'=`X'
	    frget `X'=`temphome2', from(`temp_link')
	    frame `frame_name': drop `temphome2'
	  }
	}
	order `to_varlist' `new_varlist'

		if "`drop'" == "drop" {
			frame drop `frame_name'
		}
	}



		
end
