program linkplot
*! 1.0.0 NJC 8 July 2003
	version 8.0
	syntax varlist(numeric min=2) [if] [in]                  ///
	[aweight fweight pweight], link(varname)                 ///
	[ sort(varlist) CMISsing(str) ASYvars plot(str asis) * ]

	if "`cmissing'" == "" | "`cmissing'" == "y"  { 
		marksample touse 
	} 
	else if "`cmissing'" == "n" { 
		marksample touse, novarlist 
	} 	
	else { 
		di as err "invalid cmissing() option: " /// 
			"specify " as inp "y" as err " or " as inp "n" 
		exit 198 
	}
	
	qui count if `touse' 
	if r(N) == 0 error 2000 

	tokenize `varlist'
	local nvars : word count `varlist' 
	local x "``nvars''" 
	local `nvars' 
	local Y "`*'" 
       
	qui { 
		preserve 
		keep if `touse' 
		if "`sort'" == "" local sort "`x'"

		if "`asyvars'" != "" { 
			foreach y of local Y { 
				separate `y', by(`link') 
				local newY "`newY'`r(varlist)' " 
			} 
			local Y "`newY'" 
			sort `link' `sort' 
		} 
		else { 
			tempvar last 
			bysort `link' (`sort') : gen byte `last' = _n == _N 
			expand 2 if `last'
			sort `link' `sort' 
			foreach y of local Y { 
				by `link' (`sort') : ///
					replace `y' = . if _n == _N 
			}	
		} 	
	}	

	local cmissing `"`: di _dup(`: word count `Y'') "n "'"' 
	
	twoway connected `Y' `x' [`weight' `exp'] ///
	, cmissing(`cmissing') `options'          /// 
	|| `plot' 
	// blank 
end

