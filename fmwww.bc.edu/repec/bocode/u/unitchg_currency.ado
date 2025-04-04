*! version 1.0.0 April 2, 2025 @ 10:27:56 UK

// Currency converter
program unitchg_currency, rclass

	syntax, from(string) to(string) date(string)

	// Re-Format the date to call API
	// ------------------------------

	// Date empty: -> Today
	if inlist(`"`date'"',`"today"',`"yesterday"') {
		local shift = cond(`"`date'"'==`"today"',0,1)
		local datestring = strofreal(date(c(current_date),"DMY")-`shift',"%dCCYY-NN-DD")
	}
	// Year only: -> All days 
	else if strlen("`date'") == 4 local datestring `"`date'-01-01..`date'-12-31"' 

	// One day, no range: -> DMY to Y-N-D
	else if !strpos(`"`date'"',":") local datestring = strofreal(date(`"`date'"',"DMY"),"%dCCYY-NN-DD")

	// Any other dates with ranges -> First:Last
	else {
		gettoken first rest: date, parse(":")
		gettoken x last: rest, parse(":")

		// First is year: -> Set to January 1st
		if strlen(`"`first'"') == 4  local first `"`first'-01-01"'
		// First is day: DMY to Y-N-D
		else local first = strofreal(date(`"`first'"',"DMY"),"%dCCYY-NN-DD")

		// Last is year: -> Set to December 31th
		if strlen(`"`last'"') == 4  local last `"`last'-12-31"'
		// Last is empty: -> Set to today
		else if `"`last'"' == `""' local last = strofreal(date(c(current_date),"DMY"),"%dCCYY-NN-DD")
		// Last is day: -> DMY to Y-N-D
		else local last = strofreal(date(`"`last'"',"DMY"),"%dCCYY-NN-DD")

		local datestring `first'..`last'
	}
	
	// Check if datestring exists
	capture assert "`datestring'" != "" 
	if _rc {
		display `"{err}date() must be full year, day, or valid range"'
		exit _rc
	}

	// Call API for single date
	quietly {
		
		if !strpos("`datestring'","..") {
			capture import delimited v1 using `"https://api.frankfurter.dev/v1/`datestring'?base=`from'&symbols=`to'"' ///
			  , delim("\t") varnames(nonames) clear
			if _rc == 603 {
				noi display `"{err}No response from https://api.frankfurter.dev/v1/`date'?base=`from'&symbols=`to'"'
				exit _rc
			}
			local unitchg = regexmatch(v1[1],`""`to'":([0-9.]+)"') 
			scalar unitchg_rescale = real(regexcapture(1))
			local typ at
		}
		
		else {
			tempfile converter filtered
			capture copy `"https://api.frankfurter.dev/v1/`datestring'?base=`from'&symbols=`to'"' `converter'
			if _rc  {
				noi display `"{err}No response from https://api.frankfurter.dev/v1/`date'?base=`from'&symbols=`to'"'
				exit _rc
			}
			filefilter `converter' `filtered', from(",") to("\n")
			import delimited v1 using `filtered', delim("\t") varnames(nonames) clear
			gen factors = ""
			replace factors = regexcapture(1) if regexmatch(v1,`""`to'":([0-9.]+)"')
			destring factors, replace
			summarize factors, meanonly
			scalar unitchg_rescale = r(mean)
			local typ average of
		}
		
	}

	
	return scalar unitchg_rescale = unitchg_rescale
   return local fromname  "`from'"
   return local toname  "`to'"
	return local date "`datestring'"
	return local typ "`typ' "

end

