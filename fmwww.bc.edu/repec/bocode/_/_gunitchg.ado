*! version 1.0.0 April 3, 2025 @ 17:09:46 UK

* Main program
program _gunitchg
version 18
	
** Syntax
	gettoken type 0 : 0
	gettoken h    0 : 0 
	gettoken eqs  0 : 0
	
	syntax varname(numeric) [if] [in] [, ///
	  ANgle(string)  ///
	  ARea(string)   ///
	  Currency(string) Date(string)  ///
	  DATAStorage(string)  ///
	  DATATransfer(string)  ///
	  Length(string)  ///
	  MILeage(string)   ///
	  Mass(string)   ///
	  TEmperature(string)  ///
	  TIme(string) decimal(string) ///
	  Volume(string) ///
	  To(string)  ///
		]
		
	marksample touse 
	
** Error Checks, Defaults, etc
		
	if ///
	  "`angle'"  ///
	  + "`area'" ///
	  + "`currency'" ///
	  + "`datastorage'" ///
	  + "`datatransfer'"  ///
	  + "`length'" ///
	  + "`mass'" ///
	  + "`mileage'" ///
	  + "`temperature'" ///
	  + "`speed'" ///
     + "`time'" ///
	  + "`volume'" ///
	  == ""  {
		display "{err}Unit of `varlist' required"
		exit 189
	}

	if "`length'" != "" {
		if "`to'" == "" local to m
		local unit length
	}
	else if "`area'" != "" {
		if "`to'" == "" local to m^2
		local unit area
	}
	else if "`volume'" != "" {
		if "`to'" == "" local to m^3
		local unit volume
	}
	else if "`mass'" != "" {
		if "`to'" == "" local to g
		local unit mass
	}
	else if "`currency'" != "" {
		if "`to'" == "" local to EUR
		local unit currency
	}
	else if "`temperature'" != "" {
		if "`to'" == "" local to K
		local unit temperature
	}
	else if "`angle'" != "" {
		if "`to'" == "" local to rad
		local unit angle
	}
	else if "`datatransfer'" != "" {
		if "`to'" == "" local to B/s
		local unit datatransfer
	}
	else if "`datastorage'" != "" {
		if "`to'" == "" local to B
		local unit datastorage
	}
	else if "`mileage'" != "" {
		if "`to'" == "" local to m/m^3
		local unit mileage
	}
	else if "`time'" != "" {
		if "`to'" == "" local to s
		local unit time
	}
	

	if "`decimal'" == "doy" local anything = int(`anything') + ((`anything' - int(`anything'))*100)/365.25
	if "`decimal'" == "dom" local anything = int(`anything') + ((`anything' - int(`anything'))*100)/30
	if "`decimal'" == "dow" local anything = int(`anything') + ((`anything' - int(`anything'))*100)/7
	if "`decimal'" == "hour" local anything = int(`anything') + ((`anything' - int(`anything'))*100)/24
	if "`decimal'" == "minute" local anything = int(`anything') + ((`anything' - int(`anything'))*100)/60
	if "`decimal'" == "second" local anything = int(`anything') + ((`anything' - int(`anything'))*100)/60
	if "`decimal'" == "inch" local anything = int(`anything') + ((`anything' - int(`anything'))*100)/12
		
	quietly {
		// Currencies
		if "`unit'" == "currency" {
			preserve
			noi unitchg_currency, from(`currency') to(`to') date(`date')
			scalar unitchg_rescale = r(unitchg_rescale)
			local fromname = "`r(fromname)'"			
			local toname = "`r(toname)' (`r(typ)'`r(date)')"
			local atdate `"(`r(typ)'`r(date)')"'
			restore
		}
		
		// Temperature
		else if "`unit'" == "temperature" {
			capture mata: unitchg("`unit'","``unit''","`to'")
			if _rc {
				noisily display `"{err}Unit ``unit'' or `to' not available in converter `unit'"'
				exit 198
			}

			local toK = subinstr("`toK'","x","`varlist'",.)
			local totemp = subinstr("`totemp'","x","`h'",.)
			gen `type' `h' = `toK' `if' `in'
			replace `h' = `totemp' `if' `in'
			label variable `h' `"`=cond(`"`:variable label `varlist''"' == `""' , `"`varlist'"' , `"`:variable label `varlist''"')' converted to °`toname'"'

			note `h': `totemp' `if' `in'
			exit
		}

		// Mileage and Speed
		else if "`unit'" == "mileage" | "`unit'" == "speed" {
			noi unitchg_ratio, mileage(`"`mileage'"') speed(`"`speed'"') to(`"`to'"') 
			local formula = subinstr("`r(formula)'","X","`varlist'",.)
			local toname `r(to)'
			
			gen `type' `h' = `formula' `if' `in'
			
			label variable `h' `"`=cond(`"`:variable label `varlist''"' == `""' , `"`varlist'"' , `"`:variable label `varlist''"')' converted to `toname'"'
			note `h': `formula' `if' `in'
			exit
		}
		
		// Length, Areas, Volumes, Masses, Angles, Datatransfer, Datastoreage, Time
		else {
			capture mata: unitchg("`unit'","``unit''","`to'")
			if _rc {
				noisily display `"{err}Unit ``unit'' or `to' not available in converter `unit'"'
				exit 198
			}

		}
		
		// Generate the variable
		gen `type' `h' = `varlist' * unitchg_rescale `if' `in'
		label variable `h' `"`=cond(`"`:variable label `varlist''"' == `""' , `"`varlist'"' , `"`:variable label `varlist''"')' converted to `toname'"'
		note `h': `varlist' * `=unitchg_rescale' `if' `in' `atdate'
	}
	
end

exit

