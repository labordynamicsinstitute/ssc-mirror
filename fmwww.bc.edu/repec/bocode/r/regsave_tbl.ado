*! regsave_tbl 1.1.2 16dec2015 by Julian Reif
* 1.1.2: added saveold option
* 1.1.1: autoid is now passed on through command arguments rather than detected directly
* 1.1  : another update to the df issue.
* 1.0.9: fixed bug related to when df is not available
* 1.0.8: changed the renaming during reshape to accommodate illegal varnames. fixed Stata 8 related bugs.
* 1.0.7: added autoid option. fixed bug related to factor variables. altered code to make use of tempnames.
* 1.0.6: added support for confidence intervals. changed -levelsof- to -levels- for 8.2 compatibility.
* 1.0.5: added backwards compatability for Stata 8.2
* 1.0.4: order() option now applies to appending datasets and doesn't require a namelist
* 1.0.3: asterisk() option now allows user to specify significance levels
* 1.0.2: issue warning if appending tables doesn't increase number of vars. regvars now preserves the order of the variables as entered in the varlist by the user
* 1.0.1: added "badchar" list for when varnames don't conform to Stata naming standards


program define regsave_tbl, rclass
	version 8.2

	syntax [varlist] [using/] [if] [in], name(name) [order(string) format(string) PARENtheses(namelist max=6) BRACKets(namelist max=6) allnumeric ASTERisk(numlist descending integer min=0 max=3 >=0 <=100) df(string) autoid append replace saveold(integer -999)]
		
	**********************************
	* Error check option selections  *
	**********************************
	* File options
	if "`append'`replace'"!="" & "`using'"=="" {
		di as error "Must specify a filename with `append'`replace'"
		exit 198
	}
	
	* Ensure there is data
	qui count `if' `in'
	if `r(N)'<1 {
		di as error "No observations"
		exit 198
	}
	
	* Make sure we don't have duplicate varnames (will cause errors during the reshape)
	qui duplicates report var `if' `in'
	if `r(unique_value)'!=`r(N)' {
		di as error "Duplicate observations in var detected.  This is not allowed."
		duplicates list var `if' `in', table divider sepby(var)
		exit 198
	}
	
	* Saveold options, if specified
	local save save
	local saveold_opts ""
	if "`saveold'"!="-999" {
		local save "saveold"
		local saveold_opts "version(`saveold')"
		
		* Reuse in regsave_tbl subcommand:
		local sv_old "saveold(`saveold')"
	}
	
	preserve
	
	* If df is blank need to set it to missing
	if `"`df'"'=="" local df "."

	* Keep variables of interest, and declare table name. Note that `varlist' is * when regsave_tbl is called by regsave.
	keep `varlist'
	qui cap keep `if' `in'
	local table "`name'"
	
	******
	* Separate constant/label variables from regression statisticis
	******
	* Regression vars are var, coef, stderr, pval, tstat, and covar_*
	
	* Identify constant variables (these come from, e.g., addlabel() option)
	tempfile cons_vars
	tempname id
	unab varnames : *
	foreach v of local varnames {
		
		* Skip the vars var, coef, stderr, pval, tstat, and anything starting with covar
		if inlist("`v'","var","coef","stderr","pval", "tstat", "ci_lower", "ci_upper") continue
		if substr("`v'",1,6) == "covar_" continue
		
		* Make sure remaining var is a constant
		qui tab `v'
		if `r(r)'>1 {
			di as error "`v' is not constant within the specified range of data"
			exit 198			
		}
		
		* Store variable name in a list
		local cons_varnames "`cons_varnames' `v'"		
	}
	
	* Save out the constant variables (will be remerged back on after the reshape)
	if "`cons_varnames'"!= "" {
		keep `cons_varnames'
		qui keep in 1
		qui gen byte `id' = 1
		sort `id'
		qui `save' "`cons_vars'", replace `saveold_opts'
	}
	restore, preserve
	
	* Keep variables of interest. Drop the constant variables.
	keep `varlist'
	qui cap keep `if' `in'	
	cap drop `cons_varnames'	


	***********************************
	* Make table for regression stats *
	***********************************

	* Ensure there are no duplicates in var
	qui duplicates report var
	if `r(unique_value)'!=_N {
		di as error "Nonunique values present in variable var"
		exit 198
	}
	
	* Rename the vars so we don't have any problems during reshape. Keep old names in a list so we can rename them back later.
	forval x = 1/`=_N' {
		tempname rename_`x'
		local nm = var[`x']
		local originals `"`originals' "`nm'" "'
		qui replace var = "`rename_`x''" in `x'
	}

	* Asterisk option: *-**-*** for 10% / 5% / 1% significance is the default
	if "`asterisk'"!="" {
		qui gen coef2 = coef // used only in one case below
		qui tostring coef, replace force format(`format')
		local allnumeric // allnumeric must be blank with asterisks
		
		* Grab the significance levels. Set them to missing if they were not specified.
		forval x=1/3 {
			tokenize "`asterisk'"
			cap local pval`x' = ``x''/100
			if "`pval`x''"=="" local pval`x' = .
		}

		* Try pval first, then tstat, then se
		cap d pval
		if _rc==0 {
			qui replace coef = coef + "*" if pval<=`pval1' & pval>max(-1,`pval2')
			if "`pval2'"!="." qui replace coef = coef + "**" if pval<=`pval2' & pval>max(-1,`pval3')
			if "`pval3'"!="." qui replace coef = coef + "***" if pval<=`pval3'
		}
		
		else {
			cap d tstat
			if _rc==0 {
				if "`df'"=="." {
					qui gen `double' pval = 2*(1-normprob(abs(tstat)))
				}
				else {
					qui gen `double' pval = tprob(`df', abs(tstat))
				}
				qui replace coef = coef + "*" if pval<=`pval1' & pval>max(-1,`pval2')
				if "`pval2'"!="." qui replace coef = coef + "**" if pval<=`pval2' & pval>max(-1,`pval3')
				if "`pval3'"!="." qui replace coef = coef + "***" if pval<=`pval3'
				drop pval			
			}
		
			else {
				cap d stderr
				if _rc==0 {
					qui gen `double' tstat = coef2/stderr 
					if "`df'"=="." {
						qui gen `double' pval = 2*(1-normprob(abs(tstat)))
					}
					else {
						qui gen `double' pval = tprob(`df', abs(tstat))
					}
					qui replace coef = coef + "*" if pval<=`pval1' & pval>max(-1,`pval2')
					if "`pval2'"!="." qui replace coef = coef + "**" if pval<=`pval2' & pval>max(-1,`pval3')
					if "`pval3'"!="." qui replace coef = coef + "***" if pval<=`pval3'
					drop pval tstat
				}	
			}
		}
		drop coef2
		qui tostring *, replace force format(`format') // All variables need to be string now, in preparation for the reshape
	}
	
	* Identify variables to be reshaped
	cap unab covs: covar_*
	cap unab pval: pval
	cap unab tstat: tstat
	cap unab stderr: stderr
	cap unab cis: ci*	

	* Declare temp files and create identifier for reshape command
	tempfile tf1 tf2
	qui gen byte `id'=1
	
	* Set run_no and save to temp file
	local run_no = 0
	qui `save' "`tf2'", replace `saveold_opts'

	* Reshape the data to make the regressor variables into their own columns
	foreach v in `covs' `cis' `pval' `tstat' `stderr' coef {
		keep var `v' `id'
		ren `v' z
		qui reshape wide z, i(`id') j(var) string

		qui gen _stat = "`v'"
		if `run_no'==0 qui `save' "`tf1'", replace `saveold_opts'
		else {
			qui append using "`tf1'"
			qui `save' "`tf1'", replace `saveold_opts'
		}
		local run_no = 1
		qui use "`tf2'", clear
	}
	qui use "`tf1'", clear
	qui drop `id'

	***
	* Make one column long
	***
	qui d
	local num_vars = `r(k)'-1
	qui count	
	qui set obs `=`r(N)'*`num_vars''
	local row = 1	
	local v_index = 1
	unab varnames : *
	tempname tbl
	
	* Check if we are in all numeric format or not
	if "`allnumeric'"!="" qui gen `tbl' = .
	else {
		qui tostring `varnames', replace force format(`format')
		qui gen `tbl' = ""
	}

	qui gen var = ""
	foreach v of local varnames {
		if "`v'"=="_stat" continue
			
		local scount = 1
		qui count if _stat!=""
		forval x=1/`r(N)' {
			local s = _stat[`x']

			* 1) Store the statistic
			qui replace `tbl' = `v'[`scount'] in `row'


			* 2) Store (correct) name of the variable
			local vname : word `v_index' of `originals'
			qui replace var = "`vname'_`s'" in `row'

			* Apply parentheses and brackets options
			tokenize "`parentheses'"
			if inlist("`s'","`1'","`2'","`3'","`4'","`5'","`6'") qui replace `tbl' = "(" + `tbl' + ")" in `row'
			tokenize "`brackets'"
			if inlist("`s'","`1'","`2'","`3'","`4'","`5'","`6'") qui replace `tbl' = "[" + `tbl' + "]" in `row'

			local row = `row'+1
			local scount = `scount'+1
		}
		local v_index = `v_index'+1
	}
	qui keep var `tbl'
	ren `tbl' `table'

	* Store a list of all variable names, and format table if they are numeric
	qui levels var, local(variable_names)
	qui cap format `table' `format'

	****************************************
	* Convert constant stats to table form *
	****************************************
	
	* Merge in the constants
	if "`cons_varnames'"!= "" {
		qui gen byte `id' = 1
		sort `id'
		qui merge `id' using "`cons_vars'", uniqusing
		drop _merge `id'
	}
		
	unab varnames : *

	* Make vars into strings, if necessary
	if "`allnumeric'"=="" {
		
		* Determine which variables need formatting
		foreach v of local varnames {
			local value = `v'[1]
			cap confirm integer number `value'
			if _rc!= 0 local float_vars "`float_vars' `v'" 
		}
		qui cap tostring `float_vars', force replace format(`format')
		if "`format'"!="" local format "%15.0fc"
		qui tostring *, force replace format(`format')
		
	}

	* Put into one column
	foreach v of local varnames {
		if "`v'" == "var" | "`v'"=="`table'" continue
		else {
			qui set obs `=_N+1'
			qui replace var = "`v'" in `=_N'
			qui replace `table' = `v'[1] in `=_N'
		}
	}

	keep var `table'
	order var

	* Merge with dataset if specified
	if "`append'"!= "" {

		* Take care that the sorting is not messed up by the merge (and add extra joinby option for Version 8 of Stata)
		tempname sortid
		gen `sortid' = _n
		cap qui merge var using `"`using'"', sort
		if _rc !=0 {
			qui joinby var using `"`using'"', unmatched(both)
		}
		qui replace `sortid' = -1 if _merge==2
		sort `sortid', stable
		local replace replace
		drop _merge `sortid'

		* autoid option
		if "`autoid'"!="" {

			unab table_name_vars : *
			local table_name_vars : subinstr local table_name_vars "var" ""
			
			local max_id = 0
			foreach v of local table_name_vars {
				qui levelsof `v' if var=="_id", local(tmp_id) clean
				capture confirm integer number `tmp_id'
				if _rc==0 {
					if `max_id' < `tmp_id' local max_id = `tmp_id'
				}
			}
			qui replace `table' = `max_id'+1 if var=="_id"
		}

		
		* Order columns so that the more recent result are on the right
		unab colnames : *
		tokenize "`colnames'"
		while "`2'"!="" {
			macro shift
		}
		move `table' `1'

		* If number of variables has not increased, issue a warning because user probably accidently overwrote data
		qui d
		local num_vars_new = `r(k)'
		qui d using "`using'"
		if `r(k)'==`num_vars_new' di in yellow "Warning: width of using dataset has not increased. Values may have been overwritten."
		
	}

	* Apply order option, if specified
	* Known issue - if user doesn't specify a valid var, nothing happens.
	if "`order'"!=""{
		tokenize `"`order'"'
		local index = 1
		qui gen index = .
		while "`1'"!= "" {
			if "`1'"=="regvars" {				
				foreach v of local variable_names {
					qui replace index = `index' if var=="`v'"
				}		
			}
			else {
				qui count if var=="`1'"
				* Need to handle situation where user specifies, e.g., "var". We need to take care of var_coef, var_stderr, etc.
				if `r(N)' > 0 qui replace index = `index' if var=="`1'"
				else qui replace index = `index' if inlist(var,"`1'_coef","`1'_stderr","`1'_tstat","`1'_pval")
			}
			macro shift
			local index = `index'+1
		}		
		sort index, stable
		drop index
	}	

	* Restore dataset if necessary
	if "`using'"!= "" {
		`save' "`using'", `replace' `saveold_opts'
		restore	
	}
	else restore, not
	
	* Return shape of new dataset
	return clear
	qui count
	return scalar N = `r(N)'
	unab all_vars : *
	local num_vars : word count `all_vars'
	return scalar k = `num_vars'
end

** EOF
