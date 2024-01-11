************************************
*!Author: Laura C Whiting
*!Contact: support@surveydesign.com.au
*!Date: 08 January 2024
*!Version: 2.25
************************************
/*
syntax is epitable3 command depvar xvar covars [if] [in] [weights], by(groupvars)
[dp(integer) cilimiter(string) title(string) notes(multiple strings with double-quotes)
ptrendvar(if it isn't xvar) aftercovars(if running a model like mixed effects) collection(name)
export opcon *Other command options*]

command is REQUIRED. This is the regression command that is going to be used to generate coefficients and p-values. For example, logistic or regress

depvar is REQUIRED. This is your dependent variable

xvar is REQUIRED. This is the variable of interest. Referred to in comments as xvar but appears in code as macro `varlist'

covars is REQUIRED. These are your independent variable(s).

by is REQUIRED. These are your group variables that xvar will be broken down into

ptrendvar is optional. It will calculate the p for trend (collection c2) based on the variable you give here rather than xvar. Designed so you can apply median in each quartile for ptrend calculations

dp is decimal points, default is 2 so only specify if you want more or less than 2 decimal places for coeff/ci's

cilimiter is what sits between lower and upper bounds, default is hyphen - so only use if you want something other than a hyphen

title will add a title to your table

notes allows you to add one or more notes to your table. Each note must be enclosed in double-quotes, and notes should be separated from each other by a single space

aftercovars is REQUIRED for MIXED regressions, or any other regression where you need to put something additonal after the independent variables are given

collection allows you to name the collection the table is output to. Default is table3. Give the replace option after the name to replace a collection already in memory. E.g. collection(table3c, replace)

export will set up the table for immediate export to a word document through Stata's putdocx command.
If the export option is given, a putdocx document is opened (if one was not already open) and the table is appended to the document.
The export option does not save the putdocx document, so if you want to keep adding to it you can.

opcon will run the contrast section (p for interaction) with the opposite variable type to the one given as xvar.
For example, if you give i.xvar and opcon the contrast will run on c.xvar, and vice versa.
Otherwise, contrast is run with the same prefix you gave xvar.

You should be able to add other options that are accepted by the original command, but this has not been extensively tested.

*/
*************************************

program epitable3, nclass
version 18.0
syntax anything [if/] [in] [fw aw pw iw], BY(varlist min=1 numeric) [ PREcmd(string) DP(integer 2) ///
CIlimiter(string) TItle(string) NOtes(string asis) PTRendvar(varname numeric) ///
AFTERcovars(string) COLLECTion(string) EXPORT OPCON *]

//Separate out varlist from model
gettoken cmd varlist : anything
if "`cmd'" == "stcox" {
	gettoken xvar varlist : varlist
	local depvar = ""
}
else {
	gettoken depvar varlist : varlist
	gettoken xvar varlist : varlist
}

// if no cilimiter given apply default
if "`cilimiter'" == "" {
	local cilimiter = "-"
}

//Check collection names c1 c2 and c3 are not in use
quietly collect dir
foreach item in c1 c2 c3 {
	if ustrpos("`s(collections)'", " `item'") > 0 | ustrpos("`s(collections)'", "`item' ") > 0 {
		display as error "Collection `item' already exists, using temporary collection name instead."
		//Use a tempname for the collection if c1 or c2 or c3 are already generated
		tempname `item'
	}
	else {
		local `item' = "`item'"
	}
}

//If no collection name given apply default
if "`collection'" == "" {
	quietly collect dir
	//Check default doesn't already exist, if it does exit
	if ustrpos("`s(collections)'", "table3") > 0 {
		display as error `"Default table name "table3" is in use."'
		display as error "Please specify a table name with the collection({it:name}) option."
		exit 110
	}
	local collection = "table3"
}
else {
	//If collection name given, check for replace option and apply
	tokenize "`collection'", parse(",")
	quietly collect dir
	if ustrpos("`s(collections)'", strtrim("`1'")) > 0 & strtrim("`3'") != "replace" {
		display as error "Collection name `1' currently in use."
		display as error "Please give the replace option if you wish to overwrite it."
		exit 110
	}
	if strtrim("`3'") == "replace" {
		capture collect drop `1'
	}
	local collection = strtrim("`1'")
}
//Use temporary names for the collections

//Set up any command-specific options given
if "`options'" != "" {
	//Pick up and remove hidden "indent" option so it isn't applied to the model commands
	if ustrpos("`options'", "indent") > 0 {
		local options = subinstr("`options'", "indent", "", .)
		//Create hidden "indent" option for use later, if given
		local indent = "indent"
		local options = stritrim("`options'")
	}
	local options = ", " + "`options'"
}

//Check if varname given is factored (i.) or continuous(c.)
if strpos("`xvar'", ".") == 0 {
	local prefix = "c."
}
else {
	tokenize "`xvar'", parse(".")
	local prefix `1'`2'
	local xvar `3'
}

//Set up if to work together with the if that is already needed
if "`if'" != "" {
	local contif = "if " + "`if'"
	local if = "& " + "`if'"
}

//create the first collection, for the coefficients
quietly collect create `c1'
//This loops through each by and runs the cmd with depvar, covars, and i. or c. xvar. The collect prefix command allows for table building.
foreach var of varlist `by' {
	quietly levelsof `var', local(level)
	foreach item in `level' {
		quietly collect, tags(`var'[`item']): `precmd' `cmd' `depvar' `prefix'`xvar' `varlist' if `var' == `item' `if' `in' `weight' `exp' `aftercovars' `options'
	}
}

//redefine varlist tag if xvar is continuous, in case of later contrast as non-continuous
if "`prefix'" == "c." {
	local newxvar = "`xvar'C"
	quietly collect remap colname[`xvar'] = colname[`newxvar']
}
else {
	local newxvar = "`xvar'"
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
// change border and font
collect style cell, border(right, pattern(nil)) font(Times New Roman)

// Set the layout for this collection. Generally not seen but here for reference
quietly collect layout (`by') (colname[`newxvar']#result[coefci2])

*******************************

//Create the second collection, for the trend p-values.
quietly collect create `c2'
//Check if alternative variable requested for p-value calculation
if "`ptrendvar'" == "" {
	local pvar = "`xvar'"
}
else {
	local pvar = "`ptrendvar'"
}
//This loops through each by and runs the cmd with depvar, covars, and c.xvar. The collect prefix command allows for table building.
local cmdcount = 1
foreach var of varlist `by' {
	quietly levelsof `var', local(level)
	foreach item in `level' {
		quietly collect, tags(`var'[`item']): `precmd' `cmd' `depvar' c.`pvar' `varlist' if `var' == `item' `if' `in' `weight' `exp' `aftercovars' `options'
		capture collect remap cmdset[`cmdcount'] = cmdset[1]
		local ++cmdcount
	}
}
//Remapping xvar is necessary for layout changes later on, otherwise once collections are combined the p-values disappear
quietly collect remap colname[`pvar'] = colname[`xvar'p]

// apply p-value formatting
collect style cell result[_r_p], nformat(%5.3f) minimum(0.001)
// Show correct column header
collect style header result[_r_p], title(hide) level(label)

//Set the layout for this collection. Generally not seen but here for reference
quietly collect layout (`by') (colname[`xvar'p]#result[_r_p])

*****************************

//Create the third collection, for the interaction p-values
quietly collect create `c3'

if "`opcon'" != "" {
	if "`prefix'" == "c." {
		local prefix = "i."
	}
	else if "`prefix'" == "i." {
		local prefix = "c."
	}
	else {
		local prefix = "`prefix'"
	}
}

//This loops through each by to run the cmd with depvar, covars, and the interaction between c.xvar and each by. P-values are collected through contrast.
foreach var of varlist `by' {
	quietly `precmd' `cmd' `depvar' `prefix'`xvar'##`var' `varlist' `contif' `in' `weight' `exp' `aftercovars' `options'
	quietly collect: contrast `prefix'`xvar'#`var'
	if "`opcon'" != "" & "`prefix'" == "i." {
		local c3varlist = "`xvar'FV"
		quietly collect remap colname[`xvar'] = colname["`c3varlist'"], fortags(result[p])
	}
	else {
		local c3varlist = "`xvar'"
	}
}

//This loops through and applies a new tag for each by that will be by[.t]. This is so that once collections are combined the interaction p-value for each by will appear alongside the p-values for each subgroup.
forvalues i = 1/`: word count `by'' {
	quietly collect addtags `: word `i' of `by''[.t], fortags(cmdset[`i']#result[p])
	local grouplabel = "`: word `i' of `by''"
	collect label levels `grouplabel' .t `"`: variable label `grouplabel''"', modify
}

// apply p-value formatting
collect style cell result[p], nformat(%5.3f) minimum(0.001)
// Show correct column header
collect style header result[p], title(hide) level(label)

// Sets the layout for this collection. Generally not seen but here for reference
quietly collect layout (`by') (result[p])

*****************************************

// Combine the individual collections to create one table
quietly collect combine `collection' = `c1' `c2' `c3'

// Name the column header for subgroup p-values
collect label values colname `xvar'p "p for trend", replace
// Name the column header for interaction p-values
collect label values result p "p for interaction", replace

// Hide column header for p-value and instead show colname[`varlist'p] header as set above
collect style header result[_r_p], level(hide)
collect style header collection, level(hide)
collect style header colname[`xvar'p], level(label)
// Center column headers
collect style column, nodelimiter dups(center) position(bottom) width(asis)

//Set alignments for "tabbed" look as default
if "`indent'" == "" {
	// Set row headers to right align for "tabbed" look
	collect style cell cell_type[row-header], halign(right)
	// Set row headers for all by[.t] levels to left align for "tabbed" look
	foreach var of varlist `by' {
		collect style cell `var'[.t]#cell_type[row-header], halign(left)
	}
}

// Re-attach label header if it is missing
collect label levels colname `xvar' "`: variable label `xvar''"

// Set layout so by[.t] appears at the top instead of the bottom of each table section
foreach var of varlist `by' {
	quietly collect levelsof `var'
	local levels = "`s(levels)'"
	local newlevels : subinstr local levels ".t" "", all
	local newlevels = ".t `newlevels'"
	local layout = "`layout'" + " `var'[`newlevels']"
}

// The final layout for the combined collection. This is the only layout that most will see.
collect layout (`layout') (colname[`newxvar']#result[coefci2]#collection[`c1'] colname[`xvar'p]#result[_r_p]#collection[`c2'] result[p])

// Apply table title if given
if "`title'" != "" {
	collect title "`title'"
	collect style title, font(Times New Roman)
}

// Apply table note(s) if given
if `"`notes'"' != "" {
	foreach item in `notes' {
		collect notes "`item'"
		collect style notes, font(Times New Roman)
	}
}

// Drop preceding collections, only table3 is needed for export
collect drop `c1' `c2' `c3'

// Set row headers for all levels of by except [.t] to add an indent - hidden option
if "`indent'" != "" {
	collect style cell cell_type[row-header], halign(left)
	foreach var of varlist `by' {
		quietly collect levelsof `var'
		local levels = "`s(levels)'"
		local levcount : word count `levels'
		forvalues i = 1/`levcount' {
			quietly collect label list `var'
			if "`s(level`i')'" != ".t" {
				collect label levels `var' `s(level`i')' "\`=char(255)' \`=char(255)' `s(label`i')'", modify
			}
		}
	}
}

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
		//Add the table to the opened putdocx document
		putdocx collect
	}
}

end
