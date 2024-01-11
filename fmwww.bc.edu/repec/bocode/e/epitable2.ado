************************************
*!Author: Laura C Whiting
*!Contact: support@surveydesign.com.au
*!Date: 08 January 2024
*!Version: 2.0
************************************
/*
syntax is epitable2 xvar, dp(integer) cilimiter(string) title(string) notes(multiple strings with double-quotes) include long export showp

dp is number decimal places to display coefficients and confidence intervals, default is 2

cilimiter is what sits between lower and upper bounds, default is hyphen

title will add a title to your table

notes allows you to add one or more notes to your table. Each note must be enclosed in double-quotes, and notes should be separated from each other by a single space

include will include all covariates in the table, default is to show xvar only

long will change the table layout from wide to long, default is wide

export will set up the table for immediate export to a word document through Stata's putdocx command.
If the export option is given, a putdocx document is opened (if one was not already open) and the table is appended to the document.
The export option does not save the putdocx document, so if you want to keep adding to it you can.

showp will show all the p-values for the given xvar and any covariates (if shown). All p-values except trend are hidden by default.

*/
*************************************

program epitable2, nclass
version 18.0
syntax varname(fv) [, DP(integer 2) CIlimiter(string) TItle(string) NOtes(string asis) INClude LONG EXPORT SHOWp]

// if no cilimiter given apply default
if "`cilimiter'" == "" {
	local cilimiter = "-"
}

//Check if varname given is factored (i.) or continuous(c.)
if strpos("`varlist'", ".") == 0 {
	//Check the continuous xvar given was continuous in the model commands as well
	quietly collect levelsof colname
	if strpos(" `s(levels)'", " `varlist' ") == 0 {
		display as error "Your chosen xvar is not found in the preceding model commands."
		display as error "If your xvar is a factor variable, make sure to include the i. prefix."
		exit 111
	}
	//Set the prefix for a continuous variable, as a continuous variable cannot show quartiles
	local prefix = "c."
}
else {
	//Set the prefix for a factor variable
	tokenize "`varlist'", parse(".")
	local prefix `1'`2'
	local varlist `3'
	//Check the factor xvar given was factored in the model commands as well
	quietly levelsof `varlist', local(fvlevels)
	local fvstart : word 1 of `fvlevels'
	quietly collect levelsof colname
	if strpos(" `s(levels)'"," `fvstart'.`varlist' ") == 0 {
		display as error "Your chosen xvar is not found in the preceding model commands."
		display as error "If your xvar is continuous no prefix is needed."
		exit 111
	}
}

//Setup new column for trend p if factor variable xvar
if "`prefix'" == "i." {
	local newcol = "`varlist'FV"
	//If variable is factor, model commands must be rerun with variable as continuous to get overall p-value
	rerun `prefix'`varlist'
	//levels of cmdset will double after rerun, we only want the first half, and the rerun sub-command returns these for us to use
	local cmdlevels = "`s(cmdlevels)'"
	//hide coefficients for the newcol level in colname only, as it contains the second set of models from rerun and we only want the p-values
	quietly collect remap result[_r_b] = result[hide], fortags(colname[`newcol'])
	quietly collect remap result[_r_ub] = result[hide], fortags(colname[`newcol'])
	quietly collect remap result[_r_lb] = result[hide], fortags(colname[`newcol'])
}
else {
	//If xvar is continuous, the newcol level in colname is set to model p-values instead
	local newcol = "`varlist'C"
}

// collect ci's into single level
collect composite define myci = _r_lb _r_ub, delimiter("`cilimiter'") replace
// apply brackets
collect style cell result[myci], sformat("(%s)")
// collect coeff and combined ci's into single level
collect composite define coefci2 = _r_b myci, trim override replace

// apply decimal places for coeff and ci's
collect style cell result[coefci2], nformat(%9.`dp'f)
// hide the level headers of dimension result
collect style header result, level(hide)
// centre columns
collect style column, dups(center)
// change border and font
collect style cell, border(right, pattern(nil)) font(Times New Roman)

// count number of models
if "`prefix'" == "c." {
	//number of models will be number of cmdset levels for continuous xvar
	quietly collect levelsof cmdset
	local levels = "`s(levels)'"
}
else {
	//number of models will be the first half of cmdset for factor xvar, given by cmdlevels set previously
	local levels = "`cmdlevels'"
}
// apply row title "Model X" for each model
foreach item in `levels' {
	quietly collect label values cmdset `item' "Model `item'"
}

//The final p-value column shows model p-value instead when xvar is continuous
if "`prefix'" == "c." {
	// add colname tag for results[p] so a column header can be set
	quietly collect addtags colname[`newcol'], fortags(result[p])
	//Convert result[p] to result[_r_p] so p-values appear in the same column/row
	quietly collect remap result[p] = result[_r_p], fortags(colname[`newcol'])
	collect label values colname `newcol' "Model", modify
}
else {
	//Re-label newcol as trend p-value for factor xvar
	collect label values colname `newcol' "Trend p-value", modify // was just "Model" so "p-value" would appear in result[_r_p], but this causes a crash so they are combined for now
}
//Label p-value and coefficient result levels appropriately
collect label values result _r_p "p-value", modify
collect label values result coefci2 "[Coef. (__LEVEL__%)]", modify

// apply p-value formatting
collect style cell result[_r_p], nformat(%5.3f) minimum(0.001)

//Set table to include all covariates if asked
if "`include'" != "" {
	//Collect all covariates
	quietly collect levelsof colname
	local collevels = "`s(levels)'"
	//Remove c1 c2 c3 c4 as these aren't covariates
	local collevels = subinstr("`collevels'", "c1 c2 c3 c4", "", .)
	//Remove newcol as we apply this separately elsewhere
	local collevels = subinstr("`collevels'", "`newcol'", "", .)
	//begin local vars to hold column order
	local vars = "["
	//Add varlist categories in order if i.xvar given
	if "`prefix'" == "i." {
		quietly levelsof `varlist', local(level)
		foreach item in `level' {
			local collevels = subinstr("`collevels'", "`item'.`varlist'", "", .)
			local vars = "`vars'" + " `item'.`varlist'"
		}
		//Remove the continuous version of xvar so i.xvar is not shown twice
		local collevels = subinstr("`collevels'", "`varlist'", "", .)
	}
	//Add just varlist if xvar is continuous
	else {
		local collevels = subinstr("`collevels'", "`varlist'", "", .)
		local vars = "`vars'" + " `varlist'"
	}
	//Default is to show only trend p-values, so newcol has to come before covariates
	if "`showp'" == "" {
		local vars = "`vars'" + " `newcol']"
		//These are needed to set the table layout at the end, other covariates are held separately in vars2
		local vars2 = "colname[`collevels']"
		local rhash = "#result[coefci2]"
	}
	//If all model p-values are asked for, place model p-values from newcol at the end
	else {
		local vars = "`vars'" + " `collevels' `newcol']"
	}
	//Remove any extraneous spaces
	local vars = stritrim("`vars'")
	//Style column headers to appear appropriately
	collect style column, nodelimiter dups(center) position(bottom) width(asis)
}
//Set table to include only xvar by default
else {
	//Add varlist categories in order if i.xvar is given
	if "`prefix'" == "i." {
		quietly levelsof `varlist', local(level)
		local vars = "["
		foreach item in `level' {
			local vars = "`vars'" + " `item'.`varlist'"
		}
		//Add the newcol level at the end so it appears on the right side of the table
		local vars = "`vars'" + " `newcol']"
	}
	//Add just varlist if xvar is continuous
	else {
		local vars = "[`varlist' `newcol']"
	}
	//Style column headers to appear appropriately
	collect style column, nodelimiter dups(center) position(bottom) width(asis)
	collect style cell cell_type[column-header], halign(center)
}

// hide all other model p-values unless asked to keep them
if "`showp'" == "" {
	quietly collect remap result[_r_p] = result[hide], fortags(colname[`varlist'])
	//Remap vars2 if it exists, as remap command would run if vars2 was missing but apply to all, which breaks the table
	if "`vars2'" != "" {
		quietly collect remap result[_r_p] = result[hide], fortags(`vars2')
	}
}

// Set table layout as wide by default
if "`long'" == "" {
	//Set layout
	quietly collect layout (cmdset) (colname`vars'#result[coefci2 _r_p] `vars2'`rhash')
	//show colname[`newcol'] header
	collect style header colname[`newcol'], level(label)
	//Set column headers and subheaders appropriately
	collect style column, nodelimiter dups(center) position(bottom) width(asis)
	if "`showp'" != "" {
		//show result headers and label
		collect style header result[_r_p], level(label)
		collect style header result[coefci2], level(label)
		//Set newcol label as trend if xvar is factor variable
		if "`prefix'" == "i." {
			collect label levels colname `newcol' "Trend", modify
		}
	}
	//Show result headings for continuous wide
	if "`prefix'" == "c." {
		collect style header result[_r_p], level(label)
		collect style header result[coefci2], level(label)
	}
}
//Set table layout as long if asked
else {
	if "`prefix'" == "i." {
		quietly levelsof `varlist'
		local start : word 1 of `r(levels)'
		if "`showp'" == "" {
			//Convert newcol p-values to first level of xvar p-values so it shows in the top-level that has no coefficients
			quietly collect remap colname[`newcol'] = colname[`start'.`varlist'], fortags(result[_r_p])
			quietly collect label levels result _r_p "Trend p-value", modify
		}
		else {
			//Do not set newcol p-values to first level of xvar if other p-values are also shown as it gets lost
			quietly collect label levels colname `newcol' "Trend", modify
		}
	}
	else {
		//If xvar is continuous and p's aren't shown, set the p-value for newcol as the norm and label headers appropriately
		if "`showp'" == "" {
			collect label levels result _r_p "Model p-value", modify
			quietly collect remap colname[`newcol'] = colname[`varlist'], fortags(result[_r_p])
		}
	}

	//Set the layout as long-ways, vars 2 is separate as it could be empty
	quietly collect layout (colname`vars' `vars2') (cmdset#result[coefci2 _r_p])
	//Set row-headers to stack style so they indent
	collect style row stack, nodelimiter nospacer indent length(.) wrapon(word) noabbreviate wrap(.) truncate(tail)
	//Show level labels for the results (column headers)
	collect style header result[coefci2], level(label)
	collect style header result[_r_p], level(label)
	if "`showp'" == "" {
		//If only trend p-values asked for then hide newcol header
		collect style header colname[`newcol'], level(hide)
	}
	else {
		//If all p-values asked for then show newcol header
		collect style header colname[`newcol'], level(label)
	}
}

//Show model labels as header
collect style header cmdset, level(label)

// Apply table title if given
if "`title'" != "" {
	collect title "`title'"
}

// Apply table note(s) if given
if `"`notes'"' != "" {
	foreach item in `notes' {
		collect notes "`item'"
	}
}

//Display the table in the results pane
collect preview

//If the export option is given, add the table to a putdocx document
if "`export'" != "" {
	//Check if a putdocx document is already open
	capture quietly putdocx describe
	//If there is no current putdocx document, open one and set it up for table export
	if _rc != 0 {
		putdocx clear
		putdocx begin, landscape
		putdocx paragraph
		collect style putdocx, layout(autofitcontents)
		//Add the table to the opened putdocx document
		putdocx collect
	}
	//If there is a current putdocx document, append the table to the open document
	else {
		putdocx paragraph
		collect style putdocx, layout(autofitcontents)
		putdocx collect
	}
}

end

//This program re-runs models with factor xvar
//It is necessary as the xvar p-values are used as trend values, and are not generated when xvar is factor
program rerun, sclass
syntax varname(fv)

//Set macros for original variable, pull prefix and variable separately
local repvar = "`varlist'"
tokenize "`varlist'", parse(".")
local prefix `1'`2'
local varlist `3'

//Create a table containing only the command-line commands
quietly collect layout (cmdset) (result[cmdline])
collect style header result, level(hide)
collect style header cmdset, level(hide)
collect style cell, halign(left)
//Save the initial set of cmdset levels, as these are about to double and we need to remap the second set to the first set
quietly collect levelsof cmdset
local cmdlevels = "`s(levels)'"

//Set tempfile for exported text table, tempname for Stata's file commands
tempfile c_commands
tempname commandfile
//Export table as txt to temporary file
quietly collect export `c_commands', as(txt)
//Open exported table txt file as read in Stata
file open `commandfile' using `c_commands', read
//Read the first line and check for border, if border found read second line then begin
file read `commandfile' line
if strpos("`line'", "---") != 0 {
	file read `commandfile' line
}
//Set macro to count through iterations and use as cmdset match tag
local count = 1
//While end of file not reached, loop through lines of text in the text table
while r(eof) == 0 {
	//Remove any erroneous whilespace
	local cline = strtrim("`line'")
	local cline = stritrim("`cline'")
	//If a border is not encountered, sub i.xvar for xvar and run the command, collecting the results
	if "`cline'" != "" & strpos("`cline'", "---") == 0 {
		local cline = subinstr("`cline'", "`repvar'", "`varlist'", 1)
		quietly collect, tag(match[`count']): `cline'
	}
	local ++count
	file read `commandfile' line
}
//Close text table file once read
file close `commandfile'

//Remap the first set of models temporarily to avoid collect errors
quietly collect remap cmdset[`cmdlevels'] = model[`cmdlevels']
//levelsof match were our tag for the second model set
quietly collect levelsof match
local levels = "`s(levels)'"

foreach match of local levels {
	//For each model of the second set, remap the xvar to newcol so it can be added to the first set without overwritting anything
	quietly collect remap colname[`varlist'] = colname[`varlist'FV], fortags(match[`match'])
	//Remap xvar p-values from second set to first set
	quietly collect remap match[`match'] = model[`match'], fortags(result[_r_p] colname[`varlist'FV])
}

//Get rid of original cmdset levels as they conflict
quietly collect remap cmdset = hide
//Set new model levels as cmdset levels
quietly collect remap model = cmdset

//Return original cmdset levels for use in the rest of epitable2
sreturn local cmdlevels = "`cmdlevels'"
end
