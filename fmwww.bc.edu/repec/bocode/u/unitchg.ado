*! version 1.0.0 April 3, 2025 @ 17:10:01 UK

* Main program
program unitchg, rclass
version 18
	
** Syntax
	syntax [anything] [, ///
	  ANgle(string)  ///
	  ARea(string)   ///
	  Currency(string) Date(string)  ///
	  DATAStorage(string)  ///
	  DATATransfer(string)  ///
	  Length(string)  ///
	  MILeage(string)   ///
	  Mass(string)   ///
	  Speed(string)  ///
	  TEmperature(string)  ///
	  TIme(string) decimal(string)  ///
	  Volume(string) ///
	  To(string) ]

	// Show what we have ot offer
	// -------------------------
	
	capture confirm number `anything'
	if _rc {
		if "`1'" == "" {
			display `"{txt}Available converters are: "' ///
			  _n `"  o {stata unitchg angles:angles} "' ///
			  _n `"  o {stata unitchg areas:areas} "' ///
			  _n `"  o {stata unitchg currencies:currencies} "' ///
			  _n `"  o {stata unitchg datastorages:datastorages} "' ///
			  _n `"  o {stata unitchg datatransfers:datatransfers} "' ///
			  _n `"  o {stata unitchg lengths:lengths} "' ///
			  _n `"  o {stata unitchg masses:masses} "' ///
			  _n `"  o {stata unitchg mileages:mileages} "' ///
			  _n `"  o {stata unitchg speeds:speeds} "' ///
			  _n `"  o {stata unitchg temperatures:temperatures} "' ///
			  _n `"  o {stata unitchg times:times} "' ///
			  _n `"  o {stata unitchg volumes:volumes} "' _n ///
			  `"Click on converter, or type {cmd:unitchg {it:converter-name}} for a list of available units."'
		}

		else if "`:word 1 of `anything''"' == "currencies" {
			unitchange_show_currencies `: word 2 of `anything''

			return local shortnames `"`r(shortnames)'"'
			return local fullnames `"`r(fullnames)'"'
		}
		else if `: word count `anything'' == 1 {
			if "`: word 1 of `anything''" == "mileages" {
				display `"{txt}Any combination of "' ///
				  `"{stata unitchg lengths:lengths} and {stata unitchg volumes:volumes}; "' ///
				  `"use "/" to set nominator and denominator"'
			}
			else if "`: word 1 of `anything''" == "speeds" {
				display `"{txt}Any combination of "' ///
				  `"{stata unitchg lengths:lengths} and {stata unitchg times:times}; "' ///
				  `"use "/" to set nominator and denominator (knots or kn is also allowed)"'
			}
			
			else {
				mata: sortedlist = strlower(unitchg_`:word 1 of `anything''()[.,1]),unitchg_`:word 1 of `anything''()
				mata:	sort(sortedlist,1)[.,2..3]
			}
			
		}
		else if `: word count `anything'' == 2 {
			
			mata:	all = unitchg_`:word 1 of `anything''()
			mata:	selected = select(all,rowsum(strpos(ustrupper(all),ustrupper("`:word 2 of `anything''"))))
			mata:	sortedlist = strlower(selected[.,2]),selected
			mata:	sort(sortedlist,1)[.,2..3]
		}
		
	}

	// Convert just one number
	// -----------------------
	
	else {
		if ///
		  "`angle'" == "" ///
		  + "`area'" ///
		  + "`currency'" ///
		  + "`datastorage'" ///
		  + "`datatransfer'" ///
		  + "`length'" ///
		  + "`mass'" ///
		  + "`mileage'" ///
		  + "`speed'" ///
		  + "`temperature'" ///
		  + "`time'" ///
		  + "`volume'" ///
		  {
			display "{err}Unit required"
			exit 189
		}

		// Defaults
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
		else if "`mileage'" != "" {
			if "`to'" == "" local to m/m^3
			local unit mileage
		}
		else if "`speed'" != "" {
			if "`to'" == "" local to m/s
			local unit speed
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
			if `"`unit'"' == `"currency"' {
				preserve
				noi unitchg_currency, from(`currency') to(`to') date(`date')

				scalar unitchg_rescale = r(unitchg_rescale)
				local fromname = "`r(fromname)'"			
				local toname = "`r(toname)' (`r(typ)'`r(date)')"
				restore
			}
		
			// Temperature
			else if "`unit'" == "temperature" {
				capture mata: unitchg("`unit'","``unit''","`to'")
				if _rc {
					noisily display `"{err}Unit(s) ``unit'' or `to' not available in converter `unit'"'
					exit 198
				}
									
				local toK = subinstr("`toK'","x","`anything'",.)
				local totemp = subinstr("`totemp'","x","`toK'",.)
				local a = `toK' 
				local b = `totemp' 
				noi display `"{res}`anything'{txt}° `fromname' is {res}"' %12.0g `b' `"° {txt}`toname'"'

				return local from = `anything'
				return local to = `b'
				return local formula "`totemp'"
				return local fromname `fromname'
				return local toname `toname'


				exit
			}

			// Milage and Speed
			else if "`unit'" == "mileage" | "`unit'" == "speed" {
				noi unitchg_ratio, mileage(`"`mileage'"') speed(`"`speed'"') to(`"`to'"') 
				local formula = subinstr("`r(formula)'","X","`anything'",.)
				noi display `"{res}`anything' {txt}`r(from)' is {res}"' %12.0g `formula' `" {txt}`r(to)'"'

				return local from = `anything'
				return local to = `formula'
				return local formula "`formula'"
				return local fromname `r(from)'
				return local toname `r(to)'

				exit
			}

			// Length, Areas, Volumes, Masses, Angles, Milages, Time, etc.
			else {
				capture mata: unitchg("`unit'","``unit''","`to'")

				if _rc {
					noisily display `"{err}Unit(s) ``unit'' or `to' not available in converter `unit'"'
					exit 198
				}

			}
		}
		
		// Show the results
		display  `"{res}`anything' {txt}`fromname' is {res}"' %12.0g `anything' * unitchg_rescale `" {txt}`toname'"'

		return local from = `anything'
		return local to = `anything' * unitchg_rescale
		return local factor = unitchg_rescale
		return local fromname `fromname'
		return local toname `toname'
	}

	
end


program unitchange_show_currencies, rclass
   preserve
	quietly {
		tempfile currencylist y
		copy https://api.frankfurter.dev/v1/currencies `currencylist', replace
		filefilter `currencylist' `y', from(",") to(\n) replace
		import delimited symbol fullname using `y', delimiter(":") clear stripquotes(yes)
		replace symbol = subinstr(symbol,"{","",.)
		replace fullname = subinstr(fullname,"}","",.)
		
		if "`1'" != "" {
			keep if strpos(ustrupper(fullname),`"`=ustrupper("`1'")'"')
		}
	levelsof symbol, local(symbol)
	levelsof full, local(full)
	}
	
	list

	return local shortnames `"`symbol'"'
	return local fullnames `"`full'"'
end

exit
    




