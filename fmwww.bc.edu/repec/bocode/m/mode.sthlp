{smcl}
{* *! version 1.0.0 20May2025}{...}

{title:Title}

{p2colset 5 13 14 2}{...}
{p2col:{hi:mode} {hline 2}} a function to display and store the mode of a variable {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:mode} {helpb varname:varname} {ifin} [, {opt nomiss} ]


{pstd}
{it: varname} can be either {it: string} or {it: numeric}


{p 4 6 2}
{p2colreset}{...}	

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nomiss}}drop observations with missing values{p_end}
{synoptline}
{p2colreset}{...}
			
	
{title:Description}

{pstd}
{cmd:mode} is a convenience tool for displaying and storing the mode (highest frequency of values) of a variable, so that it can be easily accessed for 
later use. In the case of ties between multiple values, {cmd:mode} will display and store all of them. When the {cmd:nomiss} option is specified, missing 
values are dropped and therefore cannot be considered for the mode. When the {cmd:nomiss} option is not specified, missing values are treated like other 
values and will be displayed and stored as ".". 


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse "auto", clear}{p_end}

{pstd}
Compute the mode of the variable {cmd:mpg} {p_end}
{phang2}{cmd:. mode mpg}{p_end}

{pstd}
Show that {cmd:mode} will display all values tied with the highest frequency (i.e. the mode) {p_end}
{phang2}{cmd:. replace mpg = 19 in 1}{p_end}
{phang2}{cmd:. mode mpg}{p_end}

{pstd}
Using {cmd:mode} with {it:string} variables {p_end}
{phang2}{cmd:. gen manuf = substr( make , 1, strpos( make , " ") - 1)}{p_end}
{phang2}{cmd:. mode manuf}{p_end}


{title:Stored results}

{pstd}
{cmd:mode} stores the following in {cmd:r()}:

{synoptset 8 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(mode)}}the value(s) representing the mode of {it:varname}{p_end}



{marker citation}{title:Citation of {cmd:mode}}

{p 4 8 2}{cmd:mode} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, A. (2025). MODE: Stata module to display and store the mode of a variable. {p_end}


{title:Authors}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}	alinden@lindenconsulting.org{p_end}


 
{title:Also see}

{p 4 8 2} Online: {helpb sum()}, {helpb egen mode()}, {helpb contract} {p_end}

