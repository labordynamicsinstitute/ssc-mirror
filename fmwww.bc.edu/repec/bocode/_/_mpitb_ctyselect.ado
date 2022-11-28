*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_ctyselect
program define _mpitb_ctyselect , rclass
	syntax varname [if] , [Select(namelist min=1) Rexp(string) /// 
		WRegion(namelist)] // Wregion(numlist min=1 integer)]
	* di "_mpitb_ctyselect was run!"
	* todo allow if for: wregion based on label values

	* tests
	conf v `varlist'

	if ("`select'" != "" & ("`rexp'" != "" | "`wregion'" != "")) | ("`rexp'" != "" & "`wregion'" != "") {
		di as err "Please choose only one of {bf:select()}, {bf:rexp()}, or {bf:wregion()}!"
		exit 197
	}

	* check: duplicates in select?
	loc dupsel : list dups select 
	if "`dupsel'" != "" {
		di as txt "Note: Countries specified repeatedly (`dupsel'). Ignoring..."
		loc select : list uniq select		// make list of unique elements
	}
	
	* check: do all ctys exist?
	if "`select'" != "" {
		qui levelsof `varlist' , c l(ctyall)		
		loc ctyok : list select in ctyall
		if `ctyok' == 1 {
			loc ctylist `select'
		}
		else {
			loc ctynok : list select - ctyall
			di as err "Country `ctynok' not found!"
			exit  198
		}
	}
	else if "`rexp'" != "" {
		qui levelsof `varlist' if regexm(`varlist',"`rexp'") , c l(ctylist) 
	}
	else if "`wregion'" != "" {
		* string version values 
		
		foreach w of loc wregion {
			loc vwregions `_dta[GMPI_worldreg_lab]'
			loc wnum : list posof `"`w'"' in vwregions 
			if `wnum' == 0 {
				di as err "Invalid world regions (`w')!"
				exit 198
			}
			qui levelsof `varlist' if `_dta[GMPI_worldreg]' == `wnum' , l(ctyl_`wnum') c
			loc ctylist "`ctylist' `ctyl_`wnum''"
		}
		qui levelsof `varlist' if mi(`_dta[GMPI_worldreg]') & !mi(`varlist') , c
		if r(levels) != "" {
			di as err "Warning: some countries seem to lack world region (`r(levels)')"
			
		}
		
		
		/* numeric version
		loc validwreg 1 2 3 4 5 6
		loc wregok : list wregion in validwreg
		if `wregok' == 1 {				// are all numbers valid regions?
			loc ctylist ""
			foreach r of numlist `wregion' {
				levelsof `varlist' if `_dta[GMPI_worldreg]' == `r' , l(ctyl_`r') c
				loc ctylist "`ctylist' `ctyl_`r''"
			}
		}

		else {
			loc wregnok : list wregion - validwreg
			di as err "Invalid regions of the world: `wregnok'"
			exit 198
		}
		*/
	}
	else if "`select'" == "" & "`rexp'" == "" & "`wregion'" == "" {			// all available countries
		qui levelsof `varlist' `if' , l(ctylist) c
	}

	loc Nctylist : word count `ctylist'
	di as txt "Note: `Nctylist' countries selected: `ctylist'."

	ret loc ctylist `ctylist'
	ret loc Nctylist `Nctylist'
end
