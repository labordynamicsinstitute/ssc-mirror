{smcl}
{* *! version 17.0 09may2024}{...}

{title: Title}

	{cmdab:trim_vars} trims blanks in a varlist specified by the user.

{title: Syntax}

	{cmdab:trim_vars} {varlist}

{title: Description}

	The {cmdab:trim_vars} command removes leading and trailing Unicode whitespace characters
	and blanks, as well as multiple, consecutive internal blanks, from the list of
	variable[s] the user inputs.

	{cmdab:trim_vars} finds all of the string variables in the current dataset and performs
	trimming on them if {cmd:_all} or {cmd:*} are specified in {varlist}.

	{cmdab:trim_vars} performs trimming on the desired string variable[s] if a list of one or more
	string variables are specified in {varlist}.

	{cmdab:trim_vars} performs trimming only on the string variables if a combination of string and
	numeric variables are specified in {varlist}.

	However, {cmdab:trim_vars} issues an error if no string variables are found.

{title: Examples}

	{cmd:trim_vars _all} // Trim all string variables in current dataset
	{cmd:trim_vars strvar1 strvar2 strvar3} // Trim string variables specified
	{cmd:trim_vars strvar1 strvar2 numvar1 numvar2} // Trim only the string variable specified

{title: Remarks}

	See {help ustrtrim()} and {help stritrim()} for more on Stata's trim functions.
	See also {help ds} for more on listing variables with specified properties.

{title: Author}

	Kaifeng Deng, Washington, DC, USA
	deng.28@outlook.com