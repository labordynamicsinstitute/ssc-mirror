/* ==================================================
project:       Stata client to cache results of other commands
Author:        R.Andres Castaneda & Damian Clarke
E-email:       acastanedaa@worldbank.org 
               dclarke4@worldbank.org / dclarke@fen.uchile.cl
url:           
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:     4 May 2023 - 09:35:43
Modification Date:  12 Dec 2024 - 02:06:41 
Do-file version:    0.0.0.9000
==================================================*/

/*==================================================
0: Program set up
==================================================*/
program define cacheit, rclass properties(prefix)
	version 16.1

	//========================================================
	//  Parse for single command clean or list
	//========================================================
	if regexm("`0'", "^clean") {
		// Unpack locations for cleaning
		syntax [anything(name=subcmd)], [dir(string) project(string) *]

		if ("`dir'" == "") {
			qui cacheit_setdir
			local dir = "`r(dir)'"
		}
		if ("`project'" != "") {
			local dir = "`dir'/`project'"
		}

		//clean cache
		cacheit_clean clean, dir("`dir'") 
		exit
	}
	if regexm("`0'", "^list") {
		//"listing cache"
		
		// Unpack locations for list file
		syntax [anything(name=subcmd)], [dir(string) project(string) *]

		if ("`dir'" == "") {
			qui cacheit_setdir
			local dir = "`r(dir)'"
		}
		if ("`project'" != "") {
			local dir = "`dir'/`project'"
		}

		//clean cache
		cacheit_list print, dir("`dir'") 
		exit
	}


	//========================================================
	//  SPLIT	
	//========================================================
	* Split the overall command, stored in `0' in a left and right part.
	//gettoken left right : 0, parse(":") quotes
	gettoken part 0 : 0, parse(" :") quotes
	while `"`part'"' != ":" & `"`part'"' != "" {
		local left `"`left' `part'"'
		gettoken part 0 : 0, parse(" :") quotes
	}
	local right `0'

	// Get command and properties
	if (ustrregexm("`right'", "^([A-Za-z0-9_]+)(.*)")) {
		local cmd =  ustrregexs(1)
	}
	local cmd_properties : results `cmd'
	local cmd_results : results `cmd'
	local origframe = c(frame)

	//========================================================
	// Syntax of left part
	//========================================================
	* Regular syntax parsing for cacheit
	local 0 : copy local left
	syntax [anything(name=subcmd)]   ///
	[,                   	     /// 
		dir(string)              ///  
		project(string)          ///  
		prefix(string)           /// 
		noDATA                   /// 
		datacheck(string)        ///  
		framecheck(string)       /// 
		pause                    ///
		KEEPall                  ///  does not clear previous returns  
		hidden                   ///  keeps hidden returns hidden
		clear                    ///  
		replace                  ///  replace says to re-run even if the cache is there
	] 

	//========================================================
	//  Permitting global control
	//========================================================
	if ("${cache_replace}" == "replace" & "`replace'" == "") {
		dis "{result: Note:}{text: cache is set to replace previously cached files via the {res:{it:cache_replace}} global.}"
		local replace replace
	}
	if ("${cache_on}"=="off") {
		dis "{result: Note:}{text: cache is bypassed given that global {res:{it:cache_on}} is set to {res:{ul:off}}.}"
		`right'
		exit
	}
	if (length("${cache_prefix}") > 0 & "`prefix'" == "") {
		dis "{result: Note:}{text: cache prefix is set via the {res:{it:cache_prefix}} global.}"
		local prefix: copy global cache_prefix
	}
	if (length("${cache_dir}") > 0 & "`dir'" == "") {
		dis "{result: Note:}{text: cache directory is set via the {res:{it:cache_dir}} global.}"
		local dir: copy global cache_dir
	}
	if (length("${cache_project}") > 0 & "`project'" == "") {
		dis "{result: Note:}{text: cache project directory is set via the {res:{it:cache_project}} global.}"
		local project: copy global cache_project
	}

	//========================================================
	// Set up and defenses
	//========================================================

	* pause
	if ("`pause'" == "pause") pause on
	else                      pause off
	set checksum off

	// Set dir if not selected by user
	if ("`dir'" == "") {
		qui cacheit_setdir
		local dir = "`r(dir)'"
	}
	else {
		mata : st_numscalar("direxists", direxists("`dir'"))
		if direxists==0 {
			dis "The cache directory does not exist."
			exit 693
		}
	}

	if ("`project'" != "") {
		local dir = "`dir'/`project'"
		cap mata: if(!direxists("`dir'")) mkdir("`dir'");;
		if _rc!=0 {
			dis "Trying to generate directory `dir'."
			dis "The project directory does not exist and could not be created."
			dis "Ensure that this directory is located within the main cache directory."
			exit 693
		}
	}

	//========================================================
	// HASHING and SIGNATURE
	//========================================================

	// hash command --------------------------
	cacheit_hash get,  cmd_call("`right'")
	local cmd_hash = "`r(chhash)'"
	return local cmd_hash = "`cmd_hash'"

	//  Data signature --------------------------
	qui datasignature 
	local datasignature = "`r(datasignature)'"
	return local datasignature = "`datasignature'"
	
	//  Incorporate additional data -------------------------
	if (`"`datacheck'"' != "") {
		tokenize `"`datacheck'"'

		//dsignatures will hold data signatures of all added datasets
		local dsignatures
		preserve
		while `"`1'"' != "" {
			qui use `"`1'"'

			qui datasignature 
			local dsig = "`r(datasignature)'"
			local dsignatures = "`dsignatures'_`dsig'"

			macro shift
		}
		restore
		local datasignature = "`datasignature'`dsignatures'"
		return local datasignature = "`datasignature'`dsignatures'"
	}

	//  Incorporate additional frames -----------------------
	if ("`framecheck'" != "") {
		tokenize `"`framecheck'"'

		//fsignatures will hold data signatures of all added frames
		local fsignatures
		qui pwf
		local cframe = r(currentframe)
		while `"`1'"' != "" {
			cwf `1'
			qui datasignature 
			local fsig = "`r(datasignature)'"
			local fsignatures = "`fsignatures'_`fsig'"

			macro shift
		}
		cwf `cframe'
		local datasignature = "`datasignature'`fsignatures'"
		return local datasignature = "`datasignature'`fsignatures'"
	}

	//  combine both parts --------------------------
	cacheit_hash get,  cmd_call("`cmd_hash'`datasignature'") prefix("`prefix'")
	local call_hash = "`r(chhash)'"
	return local call_hash = "`call_hash'"

	//========================================================
	// Find cache files and load
	//========================================================
	// Find log --------------------------
	cap findfile `call_hash'.smcl, path(`dir')
	if _rc==0  {
		local logfound = 1
		local log = r(fn)
	}
	else local logfound = 0

	// Find files --------------------------
	local files: dir "`dir'" files "`call_hash'*.dta*", respectcase
	local loadfiles  = 0
	local loadframes = 0

	// Find graphs --------------------------
	local gfiles: dir "`dir'" files "`call_hash'*.gph", respectcase

	// If hide is specified, re-run first time even if run previously
	local newhide = 0
	if "`hidden'"!="" {
		cap findfile `call_hash'_elements.dta, path(`dir')
		if _rc!=0 {
			local replace replace
			local newhide = 1
		}
	}

 	if (length(`"`files'"') != 0 | length(`"`gfiles'"') != 0) & "`replace'"=="" {
		//dis "Cache found"
		// Test for hash collision
		tempname hashcheck
		frame create `hashcheck'
		cwf `hashcheck'
		qui use "`dir'/`call_hash'_r_macros.dta", clear
		qui count
		local rnmax=r(N)
		local matchedCommand = contents[`rnmax']
		if "`matchedCommand'" != "`right'" {
			dis "{err: Hash collision detected.}"
			dis "{err: This is a very rare occurrence in which an identical hash has coincidentally been generated for two distinct strings.}"
			dis "{err: You typed `matchedCommand'.}"
			dis "{err: This matched with `right'.}"
			dis "{err: Please slightly change your syntax of the typed command, which will result in a different hash.}"
			exit 693
		}

		// Open all elements of visible returns
		local elfn
		if "`hidden'"!="" {
			tempname elements
			frame create `elements'
			frame `elements' {
				use "`dir'/`call_hash'_elements.dta", clear
			}
			local elfn elframe(`elements')
		}

		// Generate frames to load returns
		foreach n in scalars macros matrices {
			tempname `n'_results
			frame create ``n'_results'
		}
		local ematrix
		local rmatrix

		// use files
		foreach file of local files {
			local rfile_name = subinstr("`file'", "`call_hash'", "", 1)
			if "`rfile_name'"==".dta" {
				local loadfiles = 1
			}
			else if "`rfile_name'"==".dtas" {
				local loadframes = 1
			}
			else {
				cacheit_parsefile `rfile_name'
			    * Save first letter (e, r, s), type (macro, matrix, scalar) and extra details
				local first_letter = r(first_letter)
				local type  	   = r(type)
				local extra 	   = r(extra)

				if "`first_letter'"=="r" local treturn = "return"
				else                     local treturn = "`first_letter'return"
    
				//========================================================
				// load and export to lists
				//========================================================
				if "`type'"=="matrix" {
				    cwf	`matrices_results'
					qui use "`dir'/`call_hash'`rfile_name'", clear
					qui ds _rownames, not
					local savvars = r(varlist)
					mkmat `savvars', matrix("`first_letter'__`extra'") rownames(_rownames)

					// rownames replaces . in names with _.  Problematic.
					// Generate rownames directly to conserve .
					local Nlabs = _N
					local rownames
					local haschar=0
					forvalues i=1/`Nlabs' {
						local rowname = _rownames[`i']
						local rownames = "`rownames' `rowname'"
						if regexm("`rowname'", "[ .]") local haschar = 1
					}
					if `haschar'==1 matname `first_letter'__`extra' `rownames', rows(.) explicit
					// Now grab colnames from labels
					local colnames
					foreach var of varlist `savvars' {
						local colname: variable label `var'
						local colnames = "`colnames' `colname'"
					}
					matname `first_letter'__`extra' `colnames', columns(.) explicit

					//Save matrix in list for later processing
					local `first_letter'matrix ``first_letter'matrix' `extra'
					cwf `origframe'
					//Sets extra as empty to avoid passing forward matrix
					local `first_letter'__extra = ""
				}
				else if "`type'"=="scalars"|"`type'"=="macros" {
					//We could consider using this to just generate a list
					// of unsaved types and names to avoid re-searching below
					// when moving onto scalars and macros.
					// Otherwise, remove this else if condition
				}
			}
		}

		//========================================================
		// Export matrices and ereturn post
		//========================================================
		if length("`ematrix'`rmatrix'")!=0 {
			if length("`ematrix'")!=0 {
				local estpost = 0
				foreach matrix of local ematrix {
					if inlist("`matrix'", "b", "V", "Cns") {
						local estpost = 1
					}
				}

				// Post estimation command
				if `estpost' == 1 {
					if `loadfiles' == 1 {
						cwf	`origframe'
						qui use "`dir'/`call_hash'", clear
						ereturn post e__b e__V, esample(_funcvar) 
						local loadfiles = 0
					}
					else {
						ereturn post e__b e__V
					}
				}
			}
			// Return other ematrices
			foreach matrix of local ematrix {
				cwf	`matrices_results'
				if !inlist("`matrix'", "b", "V", "Cns") {
					cacheit_ereturn e__`matrix', name(`matrix') type("matrix") `hidden' `elfn'
				}
			}
			// Return rmatrices
			foreach matrix of local rmatrix {
				cwf	`matrices_results'
				if "`hidden'"!="" {					
					frame `elements' {
						qui count if regexm(element, "r\(`matrix'\)")==1
						if r(N)==1 local hh "visible"
						if r(N)==0 local hh "hidden"
					}
					return `hh' matrix `matrix'=r__`matrix' 
				}
				else return matrix `matrix'=r__`matrix'
			}
			cwf	`origframe'
		}

		//========================================================
		// Export scalars and macros
		//========================================================
		foreach file of local files {
			local rfile_name = subinstr("`file'", "`call_hash'", "", 1)
			if "`rfile_name'"==".dta" continue

			// extract key file details
			cacheit_parsefile `rfile_name'
			* Save first letter (e, r, s), type (macro, matrix, scalar) and extra details
			local first_letter = r(first_letter)
			local type  	   = r(type)
			local extra 	   = r(extra)

			if "`first_letter'"=="r" local treturn = "return"
			else                     local treturn = "`first_letter'return"
    
			if "`type'"=="scalars"|"`type'"=="macros" {
				cwf ``type'_results'
				clear
				//Import scalar or macro file
				use "`dir'/`call_hash'`rfile_name'", clear

				qui count
				if r(N)==0 continue 
				foreach num of numlist 1(1)`r(N)' {
					local item     = item[`num']
					local contents = contents[`num']
					// Return this element
					if "`type'"=="macros"  {
						if "`first_letter'"=="r" {
							if "`hidden'"!="" {					
								frame `elements' {
									qui count if regexm(element, "r\(`item'\)")==1
									if r(N)==1 local hh "visible"
									if r(N)==0 local hh "hidden"
								}
								return `hh' local `item' `"`contents'"'
							}
							else return local `item' `"`contents'"'
						}
						else cacheit_`treturn' "`contents'", name(`item') type("local") `hidden' `elfn'
					}
					else if "`type'"=="scalars" {
						if "`first_letter'"=="r" {
							if "`hidden'"!="" {					
								frame `elements' {
									qui count if regexm(element, "r\(`item'\)")==1
									if r(N)==1 local hh "visible"
									if r(N)==0 local hh "hidden"
								}
								return `hh' scalar `item' = `contents'
							}
							else return scalar `item' = `contents'
						}
						else cacheit_`treturn' `contents', name(`item') type("scalar") `hidden' `elfn'
					}
				}
			}
		}
		cwf	`origframe'
		if `loadfiles' == 1 qui use "`dir'/`call_hash'", clear
		if `loadframes'==1 qui frames use "`dir'/`call_hash'.dtas", `clear' replace

		//========================================================
		// Export graphs and store in memory
		//========================================================
		foreach gfile of local gfiles {
			local gfile_name = subinstr("`gfile'", "`call_hash'", "", 1)
			local sname = substr(subinstr("`gfile_name'", ".gph", "", 1), 2,.)

			// Load and save graph with original name
			graph use "`dir'/`call_hash'`gfile_name'", name(`sname', replace)
		}


		//========================================================
		// Print command output
		//========================================================
		if `logfound'==1 {
			dis "{result: Note:}{text: Command was cached.  Recovering previous output.}"
			type "`log'"
		}	
		if "`hidden'"!="" frame drop `elements'
		exit
	}


	//========================================================
	// If cacheit is not found 
	//========================================================
	// Save baseline frames before running command & datasignature of each
	dis "{result: Note:}{text: Command is not cached. Implementing cache for future.}"
	qui frames dir
	local allframes = r(frames)
	// save signatures of each
	foreach f of local allframes {
		frame `f': qui datasignature

		// Work with edge case: frames of 31 or 32 characters
		if length("`f'")>30 {
			mata: st_local("fname", strofreal(hash1("`f'", ., 2), "%12.0gc"))
		}
		else local fname = "`f'"
		local s`fname' = "`r(datasignature)'"
	}

	// Save baseline graphs before running command
	qui graph dir, memory
	local allgraphs = strtrim(r(list))

	//If there is a graph called Graph, we will temporarily move this
	// We can recover it later if no new graph is generated
	// This is because otherwise it is not clear if the default graph is old or new
	local dgexists = 0
	tempname defaultgraph
	cap graph copy Graph `defaultgraph'
	if _rc==0 {
		graph drop Graph
		local dgexists = 1
	}

	// clear ereturn and sreturn lists that may come from previous commands
	if "`keepall'"=="" ereturn clear
	if "`keepall'"=="" sreturn clear

	//Log output and then this can be printed when cached command called
	tempname logfile
	qui log using "`dir'/`call_hash'", name(`logfile') replace

	//Write current command to cache log for future reference if consulted
	qui file open cachedcommands using "`dir'/cached_commands.txt", write append
	file write cachedcommands _n `". {cmd:`right'}"'  _n
 	file close cachedcommands 


	// Will log for return list, ereturn list and sreturn list to check for hidden returns
	if "`hidden'"!="" qui log using "`dir'/rlist.txt", name(rlog) text replace
	* Now, run the command on the right
	capture noisily `right'
	if "`hidden'"!="" {
		dis ""
		dis "The following elements will be returned as visible"
		return list

	}

	// If requires clear, add if clear argument is provided
	if _rc==4 & ("`clear'"=="clear") {
		// At present, a small bug. 
		//   The above command will still show the clear error
		//   Perhaps using describe and r(changed) offers solution
		//     ie - add clear option, and if error occurs run without clear
		`right' `clear'
	}
	else if _rc!=0 {
		qui log close `logfile'	
		exit
	}

	local dtasave   = 0

	// ret list --------------
	local classes = "r e s"
	local macro_namres = "scalars  macros  matrices  functions"
	// get all the names of macros with info and save results 
	foreach l of local classes {
		foreach n of local macro_namres {
			local `l'`n': `l'(`n')
			//disp "{res:`l'`n'}: ``l'`n''"
			if ("``l'`n''" != "") {
				local ret_names = "`ret_names' `l'`n'"
			}
		}
	}

	foreach n in scalars macros matrices {
		tempname `n'_results
		frame create ``n'_results'
	}

	// Save results in cache directory (type-specific)
	foreach element of local ret_names {
		// Get class (e, s or r)
		local class   = substr("`element'", 1, 1)
		local element = substr("`element'", 2, .)

		// Save matrices as dta file for each matrix
		if regexm("`element'", "matrices")==1 {
			// generate clean frame to use svmat for saving to _cache
			cwf `matrices_results'

			// Now, iterate through all matrices, saving data and exporting
			//   Potentially can set up a savematrix function and a loadmatrix function
			local matrices: `class'(`element')
			foreach mat of local matrices {
				//Name matrix as __ to avoid problems, eg trying to store column names like _cons
				mat __ = `class'(`mat')
				qui svmat __

				//Save matrix rownames as an extra variable
				local rnames: rownames __
				qui gen _rownames = ""
				local j=1
				foreach name of local rnames {
					qui replace _rownames = "`name'" in `j'
					local ++j
				}
				//Save matrix colnames as a variable label
				local cnames: colnames __
				local j=1
				foreach name of local cnames {
					lab var __`j' "`name'"
					local ++j
				}
				qui save "`dir'/`call_hash'_`class'_matrix_`mat'.dta", replace
				clear
			}
			cwf `origframe'
		}		
		// Now, deal with scalars and macros
		else if regexm("`element'", "scalar|macro")==1 {
			local names: `class'(`element')
			local n_items: word count `names'

			// change to clean frame to import contents of list
			cwf ``element'_results'
			qui set obs `n_items'

			qui gen item = ""
			if regexm("`element'", "scalar")==1 {
				qui gen contents = .
			}
			else {
				qui gen contents = ""
			}
			local j=1
			foreach name of local names {
				qui replace item = "`name'" in `j'
				qui replace contents = `class'(`name') in `j'
				local ++j
			}
			//Save all scalars or macros
			qui save "`dir'/`call_hash'_`class'_`element'.dta", replace
			clear
			cwf `origframe'
		}
		// Deal with functions (esample probably saved as variable)
		//   From documentation (https://www.stata.com/manuals/rstoredresults.pdf):
		//   Functions are stored by e-class commands only, and the only function existing is e(sample)
		else if regexm("`element'", "functions")==1 & "`data'"=="" {
			// Based on above comment, this must be e(sample)
			qui gen _funcvar = e(sample)
			qui save "`dir'/`call_hash'.dta", replace
			local dtasave = 1
		}
	}
	return add // add results of cmd
	if `dtasave'==1 cap drop _funcvar

	// Add cached command as r macro.  This allows for check of hash collision
	cwf `scalars_results'
	clear
	cap use "`dir'/`call_hash'_r_macros.dta", clear
	if _rc==0 {
		qui count
		local rn1 = r(N)+1
		qui set obs `rn1'
		qui replace item = "cached_command" in `rn1'
		qui replace contents = "`right'" in `rn1'
	}
	else {
		qui set obs 1
		qui gen item = "cached_command"
		qui gen contents = "`right'"
	}
	qui save "`dir'/`call_hash'_r_macros.dta", replace
	cwf `origframe'

	foreach n in scalars macros matrices {
		frame drop ``n'_results'
	}
	qui log close `logfile'
	if `newhide'==1 {
		cacheit_cleanlog, folder("`dir'") fname("`call_hash'")
	}

	//========================================================
	// Store results (data) 
	//========================================================
    if "`data'"=="" { 
        qui datasignature 
		local datasignature2 = "`r(datasignature)'"
		if ("`datasignature'" != "`datasignature2'") & `dtasave'==0 {
			//dis "Data has changed, saving data"
			qui save "`dir'/`call_hash'.dta", replace
		}

		//========================================================
		// Store results (frames) 
		//========================================================
		// data frame ----------
		// if the the cmd returns or changes a data frame, save it
		qui frames dir
		local finalframes = r(frames)
		local saveframes 

		foreach f of local finalframes {
			if `"`f'"'=="default" continue

			local framescheck = 0
			foreach oframe of local allframes {
				if "`f'"=="`oframe'" {
					// dis "Frame `f' existed previously" (check if changed)
					frame `f': qui datasignature

					// Work with edge case: frames of 31 or 32 characters
					if length("`f'")>30 {
						mata: st_local("fname", strofreal(hash1("`f'", ., 2), "%12.0gc"))
					}
					else local fname = "`f'"

					local t`fname' = "`r(datasignature)'"
					// test if signature has changed, and if so add to save list
					if "`t`fname''" != "`s`fname''" {
						frame `f': qui describe
						if r(k) > 0 local saveframes = "`saveframes' `f'"
					}
					local framescheck = 1
					continue, break
				}
			}
			if `framescheck'==0 {
				frame `f': qui describe
				if r(k) > 0 local saveframes = "`saveframes' `f'"
			}
		}
		if "`saveframes'" != "" {
			//dis "Saving frames: `saveframes'"
			qui frames save "`dir'/`call_hash'.dtas", frames(`saveframes') replace
		}
	}

	//========================================================
	// Store results (graphs) 
	//========================================================
	qui graph dir, memory
	local finalgraphs = strtrim(r(list))
	local newgraph = 0
	local ngraphs: word count `allgraphs'

	// Make list of original graphs for comparison
	local graphlist
	foreach og of local allgraphs {
   		local graphlist `"`graphlist', "`og'""'
	}

	foreach g of local finalgraphs {
		if `"`g'"'=="`defaultgraph'" continue
		// if Graph is generated, this must be new
		if `"`g'"'=="Graph" {
			qui graph save `g' "`dir'/`call_hash'_`g'.gph", replace
			local newgraph = 1
			// Now, if old Graph existed, we can remove this, as it would have been saved over
			if `dgexists'==1 {
				graph drop `defaultgraph'
			}
		}
		else if `ngraphs'==0 qui graph save `g' "`dir'/`call_hash'_`g'.gph", replace
		else {
			// Otherwise, save other graphs if they weren't in previous list
			if !inlist("`g'" `graphlist') qui graph save `g' "`dir'/`call_hash'_`g'.gph", replace
		}
	}	
	// Finally, if old default "Graph" existed and no new graph was made, put it back
	if `dgexists'==1 & `newgraph'==0 {
		graph copy `defaultgraph' Graph
		graph drop `defaultgraph'
	}

	if "`hidden'"!="" {
		//========================================================
		// Store results (lists)
		//========================================================
		qui log close rlog
		qui log using "`dir'/elist.txt", name(elog) text replace
		ereturn list
		qui log close elog
		qui log using "`dir'/slist.txt", name(slog) text replace
		sreturn list
		qui log close slog

		//========================================================
		// Generate list of observed elements
		//========================================================
		tempname observed_elements
		frame create `observed_elements'
		cwf `observed_elements'
		gen element = ""
		qui save "`dir'/`call_hash'_elements.dta", replace
		foreach etype in r e s {
			qui {
				import delimited using "`dir'/`etype'list.txt", clear
				cap gen v1 = ""
				gen element = regexs(0) if regexm(v1,"`etype'\([^)]+\)")
				drop if missing(element)
				keep element
				append using "`dir'/`call_hash'_elements.dta"
				qui save "`dir'/`call_hash'_elements.dta", replace
			}
		}
		cwf `origframe'
		frame drop `observed_elements'
	}
end

//========================================================
// Aux programs
//========================================================


// set directory
cap program drop cacheit_setdir
program define cacheit_setdir, rclass
	mata {
			// Check if global macro exiss. If it does, 
			// use it as cachedir. Otherwise, use pwd()
			if (st_global("cache_dir") != "") {
				cachedir = st_global("cache_dir") + "/_cache"
			}
			else {
				cachedir = pwd() + "_cache"
			}
			if (!direxists(cachedir)) {
				mkdir(cachedir)
				fh = fopen(cachedir+"/cached_commands.txt", "w")
				fwrite(fh, "{bf:{res: Cached commands}}: ")
				fclose(fh)
			}
			st_local("dir", cachedir)
		}
	
	return local dir = "`dir'"
end

// Clean log
cap program drop cacheit_cleanlog
program define cacheit_cleanlog, rclass
	syntax [anything], folder(string) fname(string)

	file open writelog using "`folder'/mostrecentcache.smcl", write text replace
	file open readlog using "`folder'/`fname'.smcl", read text
	file read readlog line
	while regexm("`line'", "The following elements will be returned")!=1 {
		file write writelog "`line'" _newline
		file read readlog line
	}
	file close readlog
	file close writelog
	copy "`folder'/mostrecentcache.smcl" "`folder'/`fname'.smcl", replace
end

// Unpack saved file name like e_scalars, or r_matrix_PT
cap program drop cacheit_parsefile
program define cacheit_parsefile, rclass
	syntax anything(name=fn)

	* Extract the first letter (e, r, s)
	if ustrregexm("`fn'", "^_([ers])_")==1 local first_letter = ustrregexs(1)
	return local first_letter = "`first_letter'"

	* Extract the type (macros, matrix, scalars)
	if 	ustrregexm("`fn'", "^[^_]*_[^_]*_([a-z]+)") local type = ustrregexs(1) 
	return local type = "`type'"

	* Extract any extra details after matrix (if present)
	if ustrregexm("`fn'", "_matrix_([A-Za-z0-9_]+)") local extra = ustrregexs(1) 
	return local extra = "`extra'"
end

// ereturn program
cap program drop cacheit_ereturn
program define cacheit_ereturn, eclass
	syntax anything(name=element), name(string) type(string) [hidden elframe(string)]
	if "`hidden'"!="" {
		frame `elframe' {
			qui count if regexm(element, "e\(`name'\)")==1
			if r(N)==1 local hh "visible"
			if r(N)==0 local hh "hidden"
		}
	}
	else local hh "visible"

	ereturn `hh' `type' `name' = `element'
end

// sreturn program
cap program drop cacheit_sreturn
program define cacheit_sreturn, sclass
	syntax anything(name=element), name(string) type(string) [hidden elframe(string)]
	sreturn `type' `name'=`element'
end

// return program
cap program drop cacheit_return
program define cacheit_return, rclass
	syntax anything(name=element), name(string) type(string)

	frame elements {
		qui count if regexm(element, "r\(`name'\)")==1
		if r(N)==1 local hh "visible"
		if r(N)==0 local hh "hidden"
	}

	return `hh' `type' `name'=`element'
end


exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:

Version Control:




*##s
	// mata {
	// 	cachedir = pwd() + "_cache"
	// 	if (!direxists(cachedir)) {
	// 		mkdir(cachedir)
	// 	}
	// 	st_local("dir", cachedir)
	// }
	*##e

*! version 0.0.0.9000  <2024dec11>
*! -- First working version
*! version 0.0.0.9001  <2025jan13>
*! -- incorporate subcommands for clean and list 
*! -- add global cache_dir for users who want to set it up in their profile.do . Also, display commands as smcl
*! version 0.0.0.9002  <2025feb26>
*! -- implement data and frame check
*! -- Implement hash collision check
*! -- manage hidden elements
*! version 0.0.1  <2025mar09>
*! -- prepare for SSC submission
*! version 0.0.2  <2025may29>
*! -- Introduce global control variables
*! ############# END of development of {cache} #########################################
*! --------------------------------------------------------
*! ############# START of development of {cacheit} #####################################
*! version 0.0.3  <2025jun20>
*! -- `cache` has changed to `cacheit` 
*! --    New repo --> https://github.com/randrescastaneda/cacheit
*! --    Old repo --> still available--but archived--in https://github.com/randrescastaneda/cache
