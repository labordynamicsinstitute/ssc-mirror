*! version 1.0.2  16sep2005
program define _freduse2

	version 9.0

	syntax using/ , 		///
		[			///
		clear			///
		]

	if ("`clear'" != "") {
            `clear'
         }

	tempname fh

	file open `fh' using `"`using'"', read

	*---------------------------------------------------------------------------------
	* Get rid of the header and get to the data table
	*---------------------------------------------------------------------------------

	* First look for the end of the header
	local line = ""
	while (`"`line'"' != "</header>") {
		* read a line
		file read `fh' line
		local line = trim(`"`line'"')
	}

	* Then look for the opening of the first table
	while (!regexm(`"`line'"', ".*<table.*")) {
		* read a line
		file read `fh' line
		local line = trim(`"`line'"')
	}

	*---------------------------------------------------------------------------------
	* Parse the first table
	*---------------------------------------------------------------------------------

	* Indicator to keep track of the number of characteristics
	local c = 0

	* While loop looking for the end of the first table
	local line = ""
	while (`"`line'"' != "</table>") {
		* read a line
		file read `fh' line
		local line = trim(`"`line'"')

		* if it matches tr, parse it
		if (`"`line'"' == "<tr>") {
			* read in full tr (while </tr> not found yet read in)
			local tr `line'
			while (`"`line'"' != "</tr>") {
				file read `fh' line
				local line = trim(`"`line'"')
				local tr `tr' `line'
			}
			* parse characteristic name and data
			assert regexm(`"`tr'"', ".*<th.*>(.*)<\/th>.*<td>(.*)<\/td>.*")
			* store info
			if (regexs(1) == "Series ID") local vname = regexs(2)
			else if (regexs(1) == "Title") local vlab = regexs(2)
			else {
				local ++c
				local cat`c' = subinstr(regexs(1), " ", "_", .)
				local desc`c' = regexs(2)
			}
		}

		* otherwise repeat
	}

	* Set up the variables and store the characteristics
	qui set obs 0
	gen strL date = ""
	gen double `vname' = 0.0
	label var `vname' `"`vlab'"'
	foreach i of numlist 1/`c' {
		char define `vname'[`cat`i''] `"`desc`i''"'
	}

	*---------------------------------------------------------------------------------
	* Parse the second table
	*---------------------------------------------------------------------------------

	* Outer while loop looking for end of table
	local line = ""
	while (`"`line'"' != "</table>") {
		* Read in line
		file read `fh' line
		local line = trim(`"`line'"')

		* If thead, read in full and then continue outer while loop
		if (`"`line'"' == "<thead>") {
			while (`"`line'"' != "</thead>") {
				file read `fh' line
				local line = trim(`"`line'"')
			}
			continue
		}

		* If tr, read in full, parse date and datapoint
		if (`"`line'"' == "<tr>") {
			* read in full tr (while </tr> not found yet read in)
			local tr `line'
			while (`"`line'"' != "</tr>") {
				file read `fh' line
				local line = trim(`"`line'"')
				local tr `tr' `line'
			}
			* parse date and datapoint
			assert regexm(`"`tr'"', ".*<th.*>(.*)<\/th>.*<td.*>(.*)<\/td>.*")
			* add a datapoint with insobs, set values with replace ... in L
			qui insobs 1
			qui replace date = regexs(1) in L
			qui replace `vname' = real(regexs(2)) in L
		}

		* Otherwise repeat
	}

	* Create a stata-formatted date
	qui gen daten = date(date,"YMD")
	format %td daten
	label variable date "fed string date"
	label variable daten "numeric (daily) date"
	qui compress

	file close `fh'
end
