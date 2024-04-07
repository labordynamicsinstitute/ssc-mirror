*! version 1.1.3  07oct2022  I I Bolotov
program def xtimportu, rclass
	version 14.0
	/*
		This program imports monthly, quarterly, half-yearly, and yearly time   
		series and panel data from a supported file format, filtering and       
		encoding its cross-sectional units if required (use "|" as separator    
		in encode()), allowing the user to export and/or save the result.       
		Wide (pivoted) data must be imported in a way that the time values      
		are located in _n == 1 (use cellrange() for excel and preformat()       
		for other filetypes) and are transposed with (SSC) sxpose2.             
		Unicode characters are fully supported for Stata 14 and newer versions. 

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 20 November 2020                                                  
	*/
	cap which sxpose2
	if _rc {
		ssc install sxpose2
	}
	// syntax                                                                   
	syntax																	///
	/* syntax for import */ anything(name=import id="import: subcommand"),	///
	[/* ignore */ FIRSTrow VARNames(string) case(string) force replace]		///
	[/* preformat */ PREformat(string asis)]								///
	[PANELvar(string) REgex(string) ENcode(string)]							///
	[TIMEvar(string) TFORmat(string)] TFREQuency(string) [drop TDEstring]	///
	[GENerate(string) float Ignore(string asis) percent dpcomma TOstring]	///
	[clear export(string asis) SAving(string asis) *]
	// adjust and preprocess options                                            
	local regex  = ustrregexra(`"`regex'"',  "\s", "\\s")
	local encode = ustrregexra(`"`encode'"', "\s", "_"  )
	local tfrequency =														///
	cond(ustrregexm(strtrim(`"`tfrequency'"'), "y", 1), "year",     "") +	///
	cond(ustrregexm(strtrim(`"`tfrequency'"'), "h", 1), "halfyear", "") +	///
	cond(ustrregexm(strtrim(`"`tfrequency'"'), "q", 1), "quarter",  "") +	///
	cond(ustrregexm(strtrim(`"`tfrequency'"'), "m", 1), "month",    "")
	local ignore = cond(`"`ignore'"' != "", `"ignore(`ignore')"',   "")
	// check options for errors                                                 
	if trim(`"`tfrequency'"') == "" {
		di as err "invalid syntax"
		exit 198
	}
	if trim(`"`float'`ignore'`percent'`dpcomma'"') != "" &					///
	   trim(`"`tostring'"') != "" {
		di as err "must specify either * (destring options) or tostring option"
		exit 198
	}
	if trim(`"`clear'`export'`saving'"') == "" {
		di as err "must specify one or more of clear, export or saving options"
		exit 198
	}
	tempname j F f var
	// check for third-party packages from SSC                                  
	qui which sxpose2
	// import data from a supported file format                                 
	if trim(`"`clear'"') == "" {			// preserve data (if required)
		preserve
	}
	qui import `import', `options' clear
	`preformat'								// preformat data (if required)
	// prepare the cross-sectional unit(s)                                      
	if trim(`"`regex'"') != "" {			// filter rows (if required)
		qui {
			/* filter panelvar by matching regex()                            */
			if trim(`"`panelvar'"') == "" {	// get the first variable
				ds
				/* define panelvar */
				local panelvar : word 1 of `r(varlist)'
			}
			drop if ! ustrregexm(`panelvar', `"`regex'"') &					///
			("`timevar'" != "" | _n > 1)	// preserve the first row
			/* replace regex with the contents of encode()                    */
			if trim(`"`encode'"') != "" {
				local regex = usubinstr(`"`regex'"', "|", " ", .)
				local i = usubinstr(`"`encode'"', "|", " ", .)
				forvalues `j' = 1/`=wordcount(`"`regex'"')' {
					replace `panelvar' = word(`"`encode'"', ``j'') if		///
					ustrregexm(`panelvar', word(`"`regex'"', ``j''))
				}
			}
			/* drop duplicates and missing values                             */
			by `panelvar', sort: drop if _n > 1
		}
	}
	// prepare the time variale                                                 
	qui {
		if trim("`timevar'") == "" {		// transpose data (if required)
			sxpose2, clear force
			/* define timevar */
			local timevar "_var1"
		}
		/* fill in eventual missing values in the time variable               */
		replace `timevar' = `timevar'[_n - 1] if mi(`timevar')
		tostring `timevar', replace force
		if trim(`"`tformat'"') == "" {		// autoformat (if required)
			/* drop yearly sums for frequency higher than yearly */
			if trim("`tfrequency'") != "year" &								///
			   trim(`"`drop'"') != "" {
				drop if ustrregexm(`timevar', `"^\s{0,}\d{4}\s{0,}$"')
			}
			/* strip frequency higher than yearly (if `tfrequency' != "year") */
			replace `timevar' =												///
			ustrregexrf(`timevar', `".{0,}(\d{4}).{0,}"', "$1", 1)
			/* recreate stripped frequency (if `tfrequency' != "year") */
			if trim("`tfrequency'") != "year" {
				local `F' =	cond("`tfrequency'" == "halfyear", 2, 0) +		///
							cond("`tfrequency'" == "quarter",  4, 0) +		///
							cond("`tfrequency'" == "month",   12, 0)
				local `f' =													///
				cond(``F'', "-" + upper(substr("`tfrequency'", 1, 1)), "")
				replace `timevar' = `timevar' + "``f''" + cond(``F'',		///
				string(cond(mod(_n - 1, ``F''), mod(_n - 1, ``F''), ``F'')), "")
			}
			/* drop duplicates and missing values */
			drop if ! ustrregexm(`timevar', "\d{4}") &						///
			_n > 1							// preserve the first row
			by `timevar', sort: drop if _n > 1
			/* define tformat() */
			local tformat = cond("`tfrequency'" != "year",					///
							"Y`=upper(substr("`tfrequency'", 1, 1))'", "Y")
		}
		if trim("`timevar'") == "_var1" |									///
		   trim(`"`tdestring'"') != "" {
			tempvar dt
			g `dt' = `tfrequency'ly(`timevar', `"`tformat'"')
			drop `timevar'
			rename `dt' `timevar'
			order `timevar'
			destring `timevar', replace force
		}
		if trim("`timevar'") == "_var1" {	// transpose data (if required)
			foreach `var' of varlist * {
				cap rename ``var'' `=subinstr("``var''", "_var", "v", .)'
			}
			sxpose2, clear force
			ds _var1, not					// reshape data
			foreach `var' of varlist `r(varlist)' {
				cap rename ``var'' value`=``var''[1]'
			}
			drop if _n == 1
			rename _var1 `panelvar'
			reshape long value, string i(`panelvar') j(`timevar')
			destring `timevar', replace force
		}
		/* format the time variable as str# or %tX                            */
		if trim(`"`tdestring'"') != "" {
			format `timevar' %t`=lower(substr("`tfrequency'", 1, 1))'
		}
		if trim("`timevar'") == "_var1" &									///
		   trim(`"`tdestring'"') == "" {
			g `dt' = string(yofd(dof`=lower(substr("`tfrequency'", 1, 1))'(	///
			`timevar'))) + cond("`tfrequency'" != "year", "``f''" +			///
			string(`tfrequency'(dof`=lower(substr("`tfrequency'", 1, 1))'(	///
			`timevar'))), "")
			drop `timevar'
			rename `dt' `timevar'
		}
	}
	// prepare the variable                                                     
	if trim(`"`tostring'"') == "" {
		qui destring value, replace force `float' `ignore' `percent' `dpcomma'
	}
	// rename dimensions and the variable, order and sort                       
	rename `panelvar' unit
	rename `timevar' `tfrequency'
	if trim(`"`generate'"') != "" {
		confirm new var `generate'
		rename value `generate'
	}
	order unit `tfrequency'
	sort  unit `tfrequency'
	// export data to a supported file format                                   
	if trim(`"`export'"') != "" {
		export `export'
	}
	// save data to a DTA file                                                  
	if trim(`"`saving'"') != "" {
		save `saving'
	}
end
