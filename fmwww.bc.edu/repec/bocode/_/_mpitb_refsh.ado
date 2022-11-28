*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_refsh
program define _mpitb_refsh 
	* di "mpitb refsh was run!"
	syntax using/  , id(name) [clear Path(string) File(string) NEWFiles UPDate(namelist) /// 
		sid(name) Keep(namelist) Char(namelist) Depind(string) GENTvar(name)] 

	/* ToDo:   
		- subgroup / sid option  
		- varlist */

	* input checks 
	if "`clear'" != "" & ("`newfiles'" != "" | "`update'" != "") | ("`newfiles'" != "" & "`update'" != "") {
		di as err "Please choose only one of options {bf:clear}, {bf:update}, or {bf:newfiles}!"
		e 198
	}
	if "`clear'" == "" & "`update'" == "" & "`newfiles'" == "" {
		di as err "One option of {bf:clear}, {bf:update}, or {bf:newfiles} is required!"
		e 198
	} 
	if "`gentvar'" != "" {
		loc allvars `keep' `char'
		loc tinall : list gentvar in allvars 
		if `tinall' == 0 {
			di as err "tvar {bf:`gentvar'} neither found in {bf:keep()} nor in {bf:char()}"
			exit 197
		}
	}
	if "`path'`file'" == "" | ("`path'" != "" & "`file'" != "") {
		di as err "Please specify one of {bf:path} or {bf:file} option."
		exit 198
	}
	if "`file'" != "" & "`update'`newfiles'" != "" {
		di as err "Option {bf:file} may not be combined with options {bf:update} or {bf:newfiles}."
		exit 198
	}
	
	
*	if inlist("`=substr("`path'",-1,. )'","/","\") {
*		di as err "`path' is not correctly specified! Please remove slash!"	// make sure path is directory
*		err 198
*	}

	if "`path'" != "" {
		m: st_numscalar("direxists", direxists("`path'")) 						
		if scalar(direxists) == 0 {
			di as err "directory {bf:`path'} does not exist!" 
			e 601 
		}
		
		if "`clear'" == "" {				// => newfiles or update
			conf f `using'								// refsh exists?
			use `using' , clear
			conf v `id'								// id var exists?
		}
		* assembling file lists 
		if "`update'" == "" {				// => newfiles or clear
			loc fl : dir "`path'" file "*.dta" , respectcase				// full file list		
		}

		if "`update'" != "" {
			tempvar upd 	
			qui gen `upd' = .
			foreach c in `update' {
				qui count if `id' == "`c'"
				if r(N) == 0 {
					di as err "Country {bf:`c'} not found in reference sheet."
					e 119
				}
				qui replace `upd' = 1 if `id' == "`c'"
				qui levelsof fname if `upd' == 1 , l(nfl) c
			}
			loc fl `nfl'
		}

		if "`newfiles'" != "" {
			qui levelsof fname , l(ofl) 						
			loc fl : list fl - ofl
			if `"`fl'"' == "" {
				di as txt _n "No new files found. Exiting..."
				e 
			}
			* di `" `fl' "'
		}
	}
	if "`file'" != "" {
		loc fl `file'
		loc path .
	}
	
	* process individual micro data files
	foreach f in `fl' {
		loc f = subinstr("`f'",".dta","",.)
		use "`path'/`f'" , clear
		di as txt "Note: processing " as res "`f'.dta" as txt " now."

		* check keep variables being 
		if "`keep'" != "" {
			foreach v of varlist `keep' {						
				qui count if mi(`v')						// MV in ID vars?
				if r(N) > 0 {
					di as txt "Note: {bf:`v'} has missing values being dropped now."	// report existence of MV
					drop if mi(`v')
				}
				sort `v'
				cap assert `v'[1] == `v'[_N]					// test for id vars to be constant
				if _rc != 0 {
					di as err "variable {bf:`v'} not constant for all obs!"
					e 9 
				}
			}
		}
		
		* gen vars from chars
		if "`char'" != "" { 
			foreach c of loc char {
				qui gen `c' = "`_dta[`c']'" // di "`c'"
				if ("`_dta[`c']'" == "") di as txt "Note: char" as res " `c' " as txt "not found."
			}
			*loc keep `keep' `char'						// all chars are automatically kept
		}
		conf v `id' `keep' `char'   						// confirm vars exists
		if "`sid'" != "" {
			cap conf v `sid'
			if _rc != 0 {						// introduced for COT
				loc nosid `nosid' `f'
				di as txt "Skipping " as res " `f' " as txt " since sid var is missing." _n
				continue 
			}
		}
		* best place ?
		if "`depind'" != "" {
			_mpitb_missvars , ind(`depind') // sub(region agec4 area)		// make miss-var options accessible through -refsh- options
			loc Nind `r(NMind)'
			loc misind "`r(misind)'"
		}	
		* OLD PLACE FOR LOOP: check for missings and constants (over id originally)
		
	
		*loc cty "`_dta[ccty]'" 			// `id'[1]			// obtain country code (data comes sorted)
			// make above optional: (i) main id in data, (ii) recovered from char, (iii) exclusively provided by user
		tempfile `id' //`cty'

		qui duplicates drop `id' `sid' , force				// reduce data
		keep `id' `sid' `keep' `char'
		
		if "`sid'" != "" {
			if "`: val lab `sid''" != "" {
				decode `sid' , gen(`sid'_name)			// only for cty that allow disaggregation
				lab var `sid'_name "name in c-data"
			}
			lab var `sid' "code in c-data"
		}
		
		gen fname = "`f'"
		gen fdate = Clock("`c(filedate)'","DMY hm")
		gen adate = Clock("`c(current_date)' `c(current_time)'","DMY hms")
		format ?date %tcdd_Mon_CCYY_HH:MM
		
		if "`depind'" != "" {
			gen Nind = `Nind'
			qui gen misind = "`misind'"
		}
		
		qui save ``id''	// cty
		loc slist `slist' ``id'' // cty						// tempfiles saved
		* di "Note: processing " as res "`f'" as txt " completed." _n
		* di as txt  "Done." _n
	}

	* assemble reference sheet
	if "`clear'" != "" {
		di as txt "Note: creating reference sheet now."
		clear				
		qui save "`using'" , empty replace
	}

	if "`clear'" ==  "" {							// => update OR newfiles
		qui use "`using'" , clear
	}

	tempvar appd
	qui append using `slist' , gen(`appd')				// dummy appended: 0=master, 1=first file, 2=second file, etc

	qui levelsof `id' if `appd' > 0 , c l(cappd)			// all countries finally appended
	loc Nappd : word count `cappd'

	if "`update'" == "" {								// =>  clear or new
		di as txt _n "Note: Countries added to reference sheet: " as res "`Nappd'" as txt "." _n "(`cappd')"
	}	
	if "`update'" != "" {
		foreach c of loc cappd {
			qui drop if `id' == "`c'" & `appd' ==  0
		}
		di as txt _n "Note : Countries updated: " as res "`Nappd'" as txt " (`cappd')."
	}

	* COT:
	if "`gentvar'" != "" {
		conf var `gentvar'
		conf new v t		// allow option to change name?
		conf new v T
		qui count if mi(`gentvar')
		if r(N) != 0 {
			di as err "Encountered missings in `gentvar'!"
			e 
		}
		tempvar nid
		qui {
			bys `id' `gentvar' : gen `nid' = 1 if _n == 1		
			bys `id' : gen t = sum(`nid')
			bys `id' : egen T = max(t)						
		}
	}
	* report countries skipped entirely
	if "`nosid'" != "" {
		loc Nnosid : word count `nosid'
		loc nosid : list sort nosid
		di as txt _n "Note: " as res "`Nnosid'" as txt " files not covered for lacking" /// 
			as res " `sid' " as txt " variable" _n as txt "(`nosid')." _n
	}
	
	* tidy up
	drop `appd'

	foreach v of varlist * {
	loc ilist: char `v'[]
		foreach i in `ilist' {
		    char `v'[`i']		// remove all characteristics attached to variables
		}
	}

	la drop _all				// remove all potential value labels


	lab var fname "file name of micro data"	
	lab var fdate "date of micro data (last save)"	
	lab var adate "date when added to reference sheet"
	/* infos to add as chars: 
	- path to micro data, 
	- country and sid ids */
	loc clist : char _dta[]
	foreach c of loc clist {
		char _dta[`c']
	}
	char _dta[type] "refsheet"
	label data `"GMPI reference sheet. Compiled on `c(current_date)'"'
	
	save "`using'" , replace

end

* make public tool, if needed
capture program drop _mpitb_missvars
program define _mpitb_missvars , rclass
	syntax , [INDicator(varlist numeric) Other(varlist numeric)]
	
	if "`indicator'" == "" & "`other'" == "" { 
		di as err "At least one of {bf:indicator()} and {bf:other()} has to be specified"
		err 197
	}
	
	if "`indicator'" != "" {}
		loc Nind : word count `indicator'
		foreach v of varlist `indicator' {
			qui count if !mi(`v')
			if (`r(N)' == 0) loc misind `misind' `v'
		}
		loc Nmind : word count `misind'
		loc N = `Nind' - `Nmind'
		di as txt "# indicator: {bf:`N'}, missing indicators: {bf:`misind'}."
		ret loc misind "`misind'"
		ret sca NMind = `N'			// non-missing indicator
	}
	if "`other'" != "" {
		foreach v of varlist `other' {
			qui count if !mi(`v')
			if (`r(N)' == 0) loc mv_`v' "has only missings"
			else if (`r(N)' == _N) loc mv_`v' "has no missings"
			else loc mv_`v' "has some missings (`=`=_N'-`r(N)'')"
			di as txt "{bf:`v'} `mv_`v''."
			ret loc mv_`v' "`mv_`v''"
		}
		
	}
end


exit
