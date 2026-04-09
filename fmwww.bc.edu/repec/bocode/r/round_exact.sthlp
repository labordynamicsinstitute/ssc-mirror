{smcl}
{* *! version 2.7.0  2026-04-08}{...}
{vieweralsosee "round()" "help round"}{...}
{viewerjumpto "Syntax" "round_exact##syntax"}{...}
{viewerjumpto "Description" "round_exact##description"}{...}
{viewerjumpto "Remarks" "round_exact##remarks"}{...}
{viewerjumpto "Examples" "round_exact##examples"}{...}
{title:Title}

{phang}
{bf:round_exact} {hline 2} Exact decimal rounding using integer transformation to bypass floating-point noise.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:round_exact} {it:{help varname}} {ifin} {cmd:,} {opt d(integer)} [{it:options}]

{p 8 17 2}
{cmd:round_exact} {it:#} {cmd:,} {opt d(integer)}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntypelist:Main}
{p2coldent:* {opt d(integer)}}specify the number of decimal places for rounding.{p_end}
{synopt:{opt gen:erate(newvar)}}create a new variable to store the rounded values.{p_end}
{synopt:{opt replace}}overwrite the existing variable with rounded values.{p_end}
{synoptline}
{p 4 6 2}* {opt d(integer)} is required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:round_exact} addresses the common issue of floating-point precision errors in Stata's built-in {cmd:round(x, unit)} function. 
Standard rounding often leaves "noise" in binary representation (e.g., {cmd:round(0.3, 0.1)} resulting in {cmd:0.30000000000000004}), which 
causes logical assertions to fail.

{pstd}
This command implements the formula: {it:round(val * 10^d) / 10^d}. By transforming the value into an integer before rounding, 
it avoids the precision errors introduced by fractional units. 


{marker remarks}{...}
{title:Remarks: Precision and Binary Representation}

{pstd}
As frequently noted by {help ncox:Nicholas J. Cox}, decimal fractions like 0.1 or 0.01 often lack exact binary 
representations, leading to unexpected "noise" in calculations. For a comprehensive overview of rounding 
logic and its implications in Stata, see: Cox, N. J. 2018. {it:Speaking Stata: From rounding to binning}. 
{it:Stata Journal} 18: 741-754.

{pstd}
A foundational discussion of the architectural hurdles of digital computing was provided by 
{help gould:William Gould}, President and Architect of Stata. See: Gould, William. 2006. 
{it:Mata Matters: Precision}. {it:Stata Journal} 6: 550-560.

{pstd}
Performing calculations with integers is inherently more stable because integers are represented 
exactly. {cmd:round_exact} follows this logic by scaling decimals into integers, performing the 
rounding, and then scaling back. This "back-and-forth" transformation ensures that the final decimal 
result matches the user's expectation for exactness, enabling successful {cmd:assert} checks and 
consistent results across comparative data analysis.


{marker examples}{...}
{title:Examples}

{pstd}Rounding a literal for display or scalar return:{p_end}
{phang2}{cmd:. round_exact 0.3, d(1)}{p_end}
{phang2}{cmd:. assert r(val) == 0.3}{p_end}

{pstd}Rounding a variable in a dataset:{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. round_exact wage, d(4) replace}{p_end}

{pstd}Creating a new rounded variable:{p_end}
{phang2}{cmd:. round_exact gear_ratio, d(1) generate(gr_rounded)}{p_end}
{phang2}{cmd:. list gear_ratio gr_rounded}{p_end}


{marker author}{...}
{title:Author}

{pstd}Anne Fengyan Shi, Pew Research Center{p_end}
{pstd}Support: email AShi@pewresearch.org{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}This program was developed to address precision hurdles in longitudinal fraction arithmetic and comparative data analysis.{p_end}
