{smcl}
{* *! version 2.1.0  2026-04-03}{...}
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
{title:Remarks: The "Cox Logic" and Precision}

{pstd}
Stata expert {bf:Nicholas J. Cox} has frequently cautioned users regarding the {cmd:round()} function, noting that decimal 
fractions like 0.1 or 0.01 do not have exact binary representations. As Cox has observed, performing calculations 
directly with integers is inherently more stable in digital computing because integers are represented exactly.

{pstd}
{cmd:round_exact} conforms to this reasoning but goes a step further. By scaling decimals into integers, 
performing the rounding, and scaling back ({it:round(val * 10^d) / 10^d}), the command eliminates the 
"trailing noise" found in standard functions.  
This "back-and-forth" transformation ensures that the final decimal result matches the user's expectation 
for exactness, enabling successful {cmd:assert} checks and exact, cross‑wave‑comparable results..


{marker examples}{...}
{title:Examples}

{pstd}Rounding a literal for display or scalar return:{p_end}
{phang2}{cmd:. round_exact 0.3, d(1)}{p_end}
{phang2}{cmd:. assert r(val) == 0.3}{p_end}

{pstd}Rounding a variable in a dataset:{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. round_exact price, d(2) replace}{p_end}

{pstd}Creating a new rounded variable:{p_end}
{phang2}{cmd:. round_exact gear_ratio, d(1) generate(gr_rounded)}{p_end}
{phang2}{cmd:. list gear_ratio gr_rounded}{p_end}


{marker author}{...}
{title:Author}

{pstd}Anne Fengyan Shi, Pew Research Center{p_end}

{marker Date}{...}
{title:Date}

{pstd} April 3, 2026

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}This program was developed to address precision hurdles in longitudinal fraction arithmetic and comparative data analysis.{p_end}
