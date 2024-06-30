*inflate command: inflates to real dollars using the all urban cpi
*2022-01-05 Sean McCulloch <sean_mcculloch@brown.edu> 
*2024-06-22 Update to use import fred rather than freduse and requires 
*inputting an API key

cap prog drop inflate
prog define inflate
	version 16
	
	syntax [varlist(default=none)] [if] [in] ,  			 ///
	[end(string)  											 ///  
	///														 ///
	GENerate(string)					     				 ///
	replace													 ///
	///														 ///
	start(string)				             				 ///
	Year(varname numeric)									 ///
	Half(varname numeric))									 ///
	Month(varname numeric))									 ///
	Quarter(varname numeric))								 ///
															 ///
	keepcpi  												 ///
	update cpicheck 										 ///
	apikey(string)]	
	
	local inflatepath  "`c(sysdir_plus)'/i/"
	
	*-----------------
	*Download CPI using FRED API if dta file does not exist or update specified
	cap confirm file "`inflatepath'/cpi.dta" 
	if ((_rc != 0) | ("`update'" == "update")) {				
		disp "Importing CPI from FRED API to `inflatepath'/cpi.dta"
		
		*check that api key is inputted if downloading new CPI data
		if "`apikey'" == "" {
			disp as error "FRED API key required to the download CPI series. Please input a FRED API key in the argument apikey()"
			exit
		}
		
		inflateopencpiframe // Open cpi
		inflateimportfred, update_path(`inflatepath') apikey(`apikey')
		frame drop cpi // Close cpi
		
		*exit if update
		if  "`update'" == "update" {
			exit
		}
	} 
	
	if "`cpicheck'" == "cpicheck" {
		di "option cpicheck will clear current working dataset. Is this ok (Y/N)?", ///
		_request(check)
		if "$check" == "Y" {
			di "continue..."
		}
		else {
			exit 
		}
		use "`c(sysdir_plus)'/i/cpi.dta", clear
		exit
	}
	
	*----------------
	*Check Errors before initiating	
	*Make sure expression fed in 
	if "`varlist'" == "" {
	    di as error "No variable to inflate entered."
		exit
	}
	
	if "`end'" == "" {
		di as error "Option end() required."
		exit
	}
	
	*check variables to inflate are numeric
	confirm numeric variable `varlist'
	
	loc numvars: word count `varlist' // used later loop through/inflate variables 
	
	*Check variable names not already taken
	loc genvars start_cpi end_cpi inflator 
	if 	"`generate'" != "" {
		loc numgenvars: word count `generate'
		*Also check number of variables in varlist = number of varnames in gen
		cap assert `numvars' == `numgenvars'
		if _rc != 0 {
			di as error "number of variable names in generate() != number of variables to inflate"
			exit
		}
		
		foreach g of loc generate {			
			loc genvars `genvars' `g'
		}
	}
	else if "`replace'" != "" { 
		loc pass
	}
	else {
	    foreach v of loc varlist {			
		    loc genvars `genvars' `v'_real 
		}
	}
	
	confirm new variable `genvars'

	*-----------
	if "`start'" == "" & "`year'" == "" {
		di as error "option start() or year() required"
		exit
	}
	
	if "`start'" != "" & "`year'" != "" {
	    di as error "Can specify either a starting time period or time variable to merge on but not both."
		exit
	}
	
	local timeopts = ("`half'" != "") + ("`quarter'" != "") + ("`month'" != "")
	if (`timeopts' > 0) & "`year'" == "" {
		di as error "Must specify a year variable if merging on half, quarter, or month."
		exit
	}
	if (`timeopts' > 1) {
	    di as error "Can only specify one time period variable to merge on half, quarter, or month."
		exit
	}
	
	*Check if in and replace specified
	if "`replace'" != "" & "`if'`in'" != "" {
		di as error "Warning: replace specified with if/in range."
		di as error "Will inflate some observations but not others. Is this ok (Y/N)?", ///
		_request(check)
		
		if "$check" == "Y" {
			di "continue..."
		}
		else {
			exit 
		}
	}
	
	*------------------
	*Parse inputted dates
	*start
	if "`start'" != "" {
		inflateparsedate, date("`start'") startend("start")
		loc start_cond = r(start_cond)
		loc start_timep = r(start_timep)
		loc start_year = r(start_year)
	}
	
	*end
	inflateparsedate, date("`end'") startend("end")
	loc end_cond = r(end_cond)
	loc end_timep = r(end_timep)
	loc end_year = r(end_year)
	
	if "`start'" != "" & "`start_timep'" != "`end_timep'" {
		di as error "Start and end time periods are not consistent, e.g. year versus quarter." 
		di as error "You specified starting time period as `start_timep' and the end as `end_timep'. Is this correct? (Y/N)", _request(check)
		if "$check" == "Y" {
			di "continue..."
		}
		else {
			exit 197
		}
	}
	*---------	
	*Load cpi into separate frame in memory
	inflateopencpiframe // Open cpi
	frame cpi: use "`inflatepath'/cpi.dta"
	 
	*Retrieve relevant CPI values for end [and start] time period[s]
	frame cpi: qui: sum CPIAUCNS if `end_cond'
	assert r(N) == 1
	gen end_cpi = r(mean) `if' `in'
		
	*If simple start year adjust based on individual time period values
	if "`start'" != "" {
		frame cpi: qui: sum CPIAUCNS if `start_cond'
		assert r(N) == 1
		gen start_cpi = r(mean) `if' `in'
	}
	*-----------------------------
	*For multiple time period datasets merge with cpi data and inflate 
	else {
		foreach t in year half quarter month {
			if "``t''" != "" {
				loc merge_timeperiods `merge_timeperiods' `t'
				loc merge_vars `merge_vars' ``t''
			}
		}
		
		*Need to rename to so can merge
		frame cpi: keep CPIAUCNS year half quarter month periodtype
		*Keep only relevant period type
		if "`merge_timeperiods'" == "year" {
			frame cpi: keep if periodtype == "Y"
		}
		else if "`merge_timeperiods'" == "year half" {
			frame cpi: keep if periodtype == "H"
		}
		else if "`merge_timeperiods'" == "year quarter" {
			frame cpi: keep if periodtype == "Q"
		}
		else if "`merge_timeperiods'" == "year month" {
			frame cpi: keep if periodtype == "M"
		}
		else {
			di as error "Period Type Unknown"
			exit
		}
		
		foreach t of loc merge_timeperiods {
			frame cpi: rename `t' ``t''
		}
		
		frlink m:1 `merge_vars', frame(cpi) gen(mergekeycpi)
		frget start_cpi = CPIAUCNS, from(mergekeycpi)
		
		*Impose if/in conditions
		gen inifvar39238 = 1 `if'
		gen inrangvar94850 = 1 `in'
		replace start_cpi = .  if inifvar39238 != 1
		replace start_cpi = .  if inrangvar94850 != 1 
		drop inifvar39238
		drop inrangvar94850
		*----
		drop mergekeycpi
	}
	
	*Close cpi frame
	frame drop cpi // Close
	
	*----------------------------
	*Make inflated variables
	gen inflator = end_cpi / start_cpi `if' `in'
	
	forvalues i = 1(1)`numvars' {
		loc v: word `i' of `varlist'
		di "Inflating `v'..."
		
		if 	"`generate'" != "" {
			loc g: word `i' of `generate'
			
			gen `g' = `v'*inflator `if' `in'  
			label var `g' "`v' in real `end' $" 
			order `g', after(`v')
		} 
		else if "`replace'" == "replace" {
			replace `v' = `v'*inflator `if' `in'
			label var `v' "`v' in real `end' $" 
		}
		else {
			gen `v'_real = `v'*inflator `if' `in' 
			label var `v'_real "`v' in real `end' $" 
			order `v'_real, after(`v')
		}
	}
	
	*Drop intermediate variables unless keepcpi specified.
	loc ordervar: word 1 of `varlist'
	if "`keepcpi'" == "keepcpi" {
		label var start_cpi "CPI-U in `start'`year' `half'`quarter'`month'"
		label var end_cpi "CPI-U in `end'"
		label var inflator "end_cpi / start_cpi"
		
		order start_cpi end_cpi inflator, after(`ordervar')
	}
	else {
		drop start_cpi end_cpi inflator
	}
end
*-----------------------------------------------
cap prog drop inflateopencpiframe
prog define inflateopencpiframe
	*----------------
	*Check cpi frame does not already exist in memory, then make cpi frame 
	cap frame create cpi 
	if _rc != 0 {
		di "inflate will drop existing cpi frame from memory is this alright (Y/N)?", ///
		_request(check)
		if "$check" == "Y" {
			di "continue..."
			frame drop cpi 
			frame create cpi
		}
		else {
			exit 
		}
	}
end

cap prog drop inflateimportfred
prog define inflateimportfred
	syntax[anything], update_path(string) apikey(string)
		
	set fredkey "`apikey'"
	*Load CPI into separate frame in memory
	frame cpi { 
		import fred CPIAUCNS, clear	
		*U.S. Bureau of Labor Statistics, 
		*Consumer Price Index for All Urban Consumers: All Items in U.S. City Average [CPIAUCNS], 
		*retrieved from FRED, Federal Reserve Bank of St. Louis
		*Not Seasonally Adjusted, base 1982-1984 = 100
		
		*make annual, half, quarter averages
		gen year = year(daten)
		gen half = halfyear(daten)
		gen quarter = quarter(daten)
		gen month = month(daten)
		gen periodtype = "M"
				
		loc ts year half quarter 
		loc tabbs Y H Q 
		forvalues i=1(1)3 {
			loc t: word `i' of `ts'
			loc tabb: word `i' of `tabbs'
			
			preserve 
			
			if "`t'" == "year" {
				loc collapseby year
			}
			else {
				loc collapseby year `t'
			}
			
			gen counter = 1 
			collapse (sum) counter (mean) CPIAUCNS, by(`collapseby')
			gen periodtype = "`tabb'"
			tempfile `t'avg
			save ``t'avg'
			restore
		}
		
		append using `yearavg'
		append using `halfavg'
		append using `quarteravg'
		
		drop if periodtype == "Y" & counter < 12
		drop if periodtype == "H" & counter < 6	
		drop if periodtype == "Q" & counter < 3	

		*---------------
		save "`update_path'/cpi.dta", replace
	}
end 

*Parse inputted date and output if conditions to retrieve cpi
cap prog drop inflateparsedate
prog define inflateparsedate, rclass
	syntax[anything], date(string) startend(string)
	
	local curyear = substr("$S_DATE", -4, 4)
	
	loc timep "Y" // default to year unless specified
	
	if regexm("`date'", "^[1-9][0-9][0-9][0-9][HhQqMm][0-9][0-9]$")  ///
	|  regexm("`date'", "^[1-9][0-9][0-9][0-9][HhQqMm][0-9]$")     {
		loc year = substr("`date'", 1, 4)
		if `year' < 1913 | `year' > `curyear'  {
			di as error "`startend' year entered out of range."
			exit 197
		}
		
		loc date_select "`date_select' year == `year' "
		
		loc timep = strupper(substr("`date'", 5, 1))
		loc date_select `" `date_select' & periodtype == "`timep'" "'
		
		loc periodnum = substr("`date'", 6, .)
		loc periodnum = `periodnum'
		
		if ("`timep'" == "H" | "`timep'" == "h" ) {
			loc periodvar "half"
			if `periodnum' < 1 | `periodnum' > 2 {
				di as error "`startend' half entered out of range."
				exit 197
			}
		} 
		else if ("`timep'" == "Q" | "`timep'" == "q" ) {
			loc periodvar "quarter"
			if `periodnum' < 1 | `periodnum' > 4 {
				di as error "`startend' quarter entered out of range."
				exit 197
			}
		} 
		else if ("`timep'" == "M" | "`timep'" == "m" ) {
			loc periodvar "month"	
			if `periodnum' < 1 | `periodnum' > 12 {
				di as error "`startend' month entered out of range."
				exit 197
			}
		}
		
		loc date_select "`date_select' & `periodvar' == `periodnum' "
		
	}
	else if regexm("`date'", "^[1-9][0-9][0-9][0-9]$") {
		loc year = `date'
		if `year' < 1913 | `year' > `curyear' {
			di as error "`startend' year entered out of range."
			exit 197
		}
		loc date_select `" `date_select' year == `year' & periodtype == "`timep'" "'
		
	}
	else {
		di as error `"`startend' date not formatted as expected. Dates should be entered as a year or year-half/quarter/month."'
		di as error `"Example: for the year 2020 enter just "2020"."'
		di as error `"Example: for February, 1975 enter "1975M02" or "1975M2"."'
		exit 197
	}
	
	*------------
	*return year, period type, period num to store as locals
	return local `startend'_year = `year'
	return local `startend'_timep = "`timep'"
	return local `startend'_cond "`date_select'"
end
