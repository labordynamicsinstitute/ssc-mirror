{smcl}
{viewerjumpto "Syntax" "namecheck##syntax"}{...}
{viewerjumpto "Description" "namecheck##description"}{...}
{viewerjumpto "Example" "namecheck##example"}{...}

{bf:namecheck} {hline 2} Utility to generate Excel list of name mismatches

{marker syntax}{...}
{title:Syntax}

{opt namecheck} {it:namevar} 

{marker description}{...}
{title:Description}
{pstd}
{cmd:namecheck} compares the text in {it:namevar} with the text in the same variable in an existing file {it:names.dta} in the same directory.
You first need to create {it:names.dta}.
{cmd:namecheck} creates an Excel file ({it:namelist.xlsx}) with unmatched names and generates an error code stopping .do file execution.
Column A is unmatched names from {it:names.dta}; column B is unmatched names from the data in memory.
{cmd:namecheck} is useful to compare names (e.g., country names) across data sources to standardize them prior to merging datasets.

{pstd}
{it:names.dta} must include only one variable with a variable named {it:varname}.
For example, {it:names.dta} might be derived from the World Bank's WDI data with the one variable "countryname".
You might have data from another source and want to merge it with WDI data.
To do this, you need to first standardize on the country names the WDI uses.

{pstd}

{marker example}{...}
{title:Example}

{pstd}Setup: Create {it:names.dta} file for comparison{p_end}
{phang2}{cmd:. ssc install wbopendata}{p_end}
{phang2}{cmd:. wbopendata, indicator(SP.POP.TOTL) long clear}{p_end}
{phang2}{cmd:. drop if region=="NA" | region==""}{p_end}
{phang2}{cmd:. keep countryname}{p_end}
{phang2}{cmd:. duplicates drop}{p_end}
{phang2}{cmd:. sort countryname}{p_end}
{phang2}{cmd:. save names, replace}{p_end}

{pstd}Application: Compare with other names{p_end}
{phang2}{cmd:. sysuse lifeexp, clear}{p_end}
{phang2}{cmd:. rename country countryname}{p_end}
{phang2}{cmd:. namecheck countryname}{p_end}


{title:Author}

	Christopher Kilby, Villanova University, USA
	christopher.kilby@villanova.edu
