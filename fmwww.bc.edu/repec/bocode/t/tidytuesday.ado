*! tidytuesday v1.0 (16 Feb 2025)
*! Asjad Naqvi

* v1.0 (16 Feb 2025): First release (beta)



*** TidyTuesday repository: https://github.com/rfordatascience/tidytuesday


*capture program drop tidytuesday 

program define tidytuesday
version 17

syntax [anything], [ year(numlist max=1 >=2018 <=2025) week(numlist max=1 >=1 <=52) month(numlist max=1 >=1 <=52) ]  

	if "`anything'"=="" local anything meta

	if !inlist("`anything'", "meta", "get", "") {
		di as error "Valid options are tidytuesday meta, [options], or tidytuesday get, [options]"
		exit
	}


quietly {
	preserve
		if "`year'" =="" local year 2025

		import delim using "https://raw.githubusercontent.com/rfordatascience/tidytuesday/refs/heads/main/data/`year'/readme.md", delim("|") clear

		gen _id = _n
		gen _temp = 1 if v1==""
		summ _id if _temp==1
		local minobs = `r(min)' - 1

		drop in 1/`minobs'
		drop v1
		drop v7

		drop _id _temp

		drop if regexm(v2, ":---:")==1


		foreach x of varlist _all {
			local mylab = lower(trim(`x'[1]))
			rename `x' `mylab'
		}

		drop in 1

		destring week, replace
		drop if week==.

		replace date = subinstr(date, "`", "", .)
		generate date2 = date(date, "YMD")
		format date2 %td

		rename date date_str
		rename date2 date

		order week date
		

		//////////////////////////
		// fix data -> info   ////
		//////////////////////////

		split data, p("](")

		replace data1 = ustrregexra(data1, "^\[", "")
		replace data2 = ustrregexra(data2, "\)$", "")

		replace data1 = trim(data1)
		replace data1 = substr(data1, 1, 50)
		
		replace data2 = trim(data2)


		global baseurl "https://github.com/rfordatascience/tidytuesday/tree/main/data/`year'/"

		replace data2 = "$baseurl" + data2 if data1!=""
		replace data2 = subinstr(data2, "/readme.md", "", .)
		replace data2 = `"""' +  data2 + `"""'

		generate data_len = length(data1)
		summ data_len, meanonly

		local max = max(r(max), 50)
		local pad : di _dup(`max') " "

		replace data1 = data1 + substr("`pad'", 1, `max' - data_len)


		capture drop info
		generate info = "{browse "  + data2  +  ":" + data1 + "}" if data!=""

		drop data data1 data2 data_len


		//////////////////////////////
		// fix source -> source   ////
		//////////////////////////////

		split source, p("), [")

		foreach x in source1   { // source2 // source3
			split `x', p("](" "). [")
			
			replace `x'1 = ustrregexra(`x'1, "^\[", "") if `x'1!=""
			replace `x'2 = ustrregexra(`x'2, "\)$", "") if `x'2!=""
			
			replace `x'2 = `"""' + `x'2 + `"""'  if `x'2!=""
			
			replace `x'1 = trim(`x'1)
			replace `x'1 = abbrev(`x'1, 25)
			
			gen `x'_len = length(`x'1)
			summ `x'_len, meanonly

			local max = max(r(max), 25)
			local pad : di _dup(`max') " "

			replace `x'1 = `x'1 + substr("`pad'", 1, `max' - `x'_len)	
			
			replace `x' = "{browse "  + `x'2  +  ":" + `x'1 + "}"  if `x'2!=""
			replace `x' = `x'1  if `x'2==""
			
			drop `x'1 `x'2 `x'_len
		}


		/////////////////
		// article   ////
		/////////////////

		split article, p("](")

		replace article1 = ustrregexra(article1, "^\[", "") if article1!=""
		replace article1 = abbrev(article1, 25)  if article1!=""
		replace article1 = trim(article1)

		replace article2 = ustrregexra(article2, "\)$", "") if article2!=""
		replace article2 = `"""' +  article2 + `"""'		if article2!=""


		gen article_len = length(article1)
		summ article_len, meanonly

		local max = r(max)
		local pad : di _dup(`max') " "

		replace article1 = article1 + substr("`pad'", 1, `max' - article_len)

		replace article = "{browse "  + article2  +  ":" + article1 + "}"  if article!=""
		replace article = article1 if article_len==0

		generate year = `year'
		
		tempfile _ttlist
		
		save `_ttlist', replace
	restore
		// print meta list
	
		if "`anything'"=="meta" {
			preserve
				use `_ttlist', clear
				noisily display in yellow "Year `year' meta list:"
				noisily _tidylist week date_str info source1 article `year' // source2 source3 
			restore
		}
	}	
	
		if "`anything'"=="get" {
			
			preserve
			use `_ttlist', clear
			
			keep if year==`year' & week==`week'
			
			local mydate = date_str[1]
			
			noisily display in yellow "Year = `year', week = `week'"
			noisily _tidylist week date_str info source1 article `year'
			noisily display _newline
			restore
			
			_tidyget, year(`year') week(`week') fetch(`mydate')
			
		}
	
end

*******************
**** _tidylist ****
*******************

	program define _tidylist
		args week date info source1 article year // source2 source3 
		
		display	_newline
		display as text %02.0f "Week" " {c |} " " Date (YMD)" _column(26)  " {c |} " "GitHub link"  _column(79) " {c |} " "Source" _column(107) " {c |} "    "Article" // "Source 2" _column(124) " {c |} " "Source 3" _column(147) " {c |} "
		display as text "{hline 5}{c +}{hline 20}{c +}{hline 52}{c +}{hline 27}{c +}{hline 27}" // {c +}{hline 24}
		
		forval i = 1/`=_N' {
			
			scalar yy = `year'
			scalar ww = `week'

			local getlist tidytuesday get, year(`year') week(`=`week'[`i']') 
			
			
			display as text "  " %02.0f `week'[`i'] " {c |} " %12s `date'[`i'] in smcl "{stata `getlist':[Load]}" " {c |} " in smcl %20s  `info'[`i']  " {c |} " `source1'[`i']  " {c |} " `article'[`i'] 	 // " {c |} " `source2'[`i']  `source3'[`i'] " {c |} " 
		}
	end



******************
**** _tidyget ****
******************

	program define _tidyget
		syntax, year(numlist max=1 >=2018 <=2025) week(numlist max=1 >=1 <=52) fetch(string)
	
		
	quietly {
	
		preserve
			import delim using "https://raw.githubusercontent.com/rfordatascience/tidytuesday/refs/heads/main/data/`year'/`fetch'/readme.md", clear groupseparator("|")  stripquotes(yes)

			gen markme=.

			replace markme = 1 if v1=="### Data Dictionary"
			replace markme = 2 if v1=="### Cleaning Script"

			replace markme = sum(markme)
			keep if markme==1

			// Define a variable to hold the CSV file names
			gen filename = v1 if substr(v1, 1, 3 ) == "# `"
			replace filename = subinstr(filename, "# `", "", .)
			replace filename = subinstr(filename, "`", "", .)

			gen markme2 = 1 if !missing(filename)
			replace markme2 = 1 if ustrregexm(v1, "\|variable")==1
			replace markme2 = 1 if ustrregexm(v1, "^\|$")==1
			
			carryforward filename, replace
			order filename	
			drop if filename==""	
			
			drop if markme2==1
			drop markme*

			ren v1 meta
			drop v*

			split meta, parse("|") trim
			drop meta
			drop meta1

			foreach x of varlist meta* {
				replace `x' = trim(`x')
			}


			ren meta2 variable
			ren meta3 type
			ren meta4 label
			
			// clean up variable
			drop if ustrregexm(variable, "^:--")==1
		
			
			replace type = "string" if type=="character"
			drop type

			tempfile _tidyget
			save `_tidyget', replace
			
			levelsof filename, local(lvls) clean
		restore
		
		preserve
			foreach x of local lvls {

				use `_tidyget', clear
				
				levelsof variable if filename=="`x'", local(vars) clean
				levelsof label    if filename=="`x'", local(labs) clean
				
				local length : word count `vars'
				
				
				import delim using "https://raw.githubusercontent.com/rfordatascience/tidytuesday/refs/heads/main/data/`year'/`fetch'/`x'", clear varn(1) encoding(utf8)

				forval y = 1/`length' {
					capture lab var  `: word `y' of `vars''  "`: word `y' of `labs''"
				}
									
				compress
					
				local filename = subinstr("`x'", ".csv", "", .)
				save `filename'.dta, replace
				count

				noisily di in green "File {ul:`filename'.dta} saved (`length' variables, `r(N)' observations)" in smcl "{stata use `filename'.dta, clear: [USE]}"

			}
		restore 
	}

			
	end
	

*************************
**** END OF PROGRAM *****
*************************
