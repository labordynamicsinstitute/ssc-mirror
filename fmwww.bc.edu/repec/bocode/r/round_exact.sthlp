{smcl}
{* *! version 4.0.0  30jul2026}{...}
{vieweralsosee "[D] round" "help round"}{...}
{viewerjumpto "Syntax" "round_exact##syntax"}{...}
{viewerjumpto "Description" "round_exact##description"}{...}
{viewerjumpto "Remarks" "round_exact##remarks"}{...}
{viewerjumpto "Notes" "round_exact##notes"}{...}
{viewerjumpto "Examples" "round_exact##examples"}{...}
{viewerjumpto "Stored results" "round_exact##results"}{...}
{viewerjumpto "Limitations" "round_exact##limitations"}{...}
{viewerjumpto "Author" "round_exact##author"}{...}

{title:Title}

{phang}
{bf:round_exact} {hline 2} Exact decimal rounding via integer transformation to mitigate floating‑point noise.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:round_exact} {it:{help varname}} {ifin} {cmd:,} {opt d(integer)} 
[{opt gen:erate(newvar)} {opt rep:lace} {opt froms:tring}]

{p 8 17 2}
{cmd:round_exact} {it:#} {cmd:,} {opt d(integer)} [{opt froms:tring}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntypelist:Main}
{p2coldent:* {opt d(integer)}}number of decimal places for rounding{p_end}
{synopt:{opt gen:erate(newvar)}}create a new variable containing rounded values{p_end}
{synopt:{opt replace}}overwrite the existing variable with rounded values{p_end}
{synopt:{opt fromstring}}treat input as a string literal or variable to avoid initial binary conversion noise{p_end}
{synoptline}
{p 4 6 2}* {opt d(integer)} is required.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:round_exact} addresses floating‑point precision artifacts commonly encountered with Stata's built‑in
{cmd:round(x, unit)} function. In some cases, rounded results may retain small binary representation 
differences that can affect equality tests, assert statements, merges, and other validation procedures.

{pstd}
The command rounds values to a specified decimal precision while producing results that conform 
more closely to expected decimal rounding behavior. It is designed for applications in which rounded 
values are subsequently used in comparisons, data validation, reporting, tabulation, or reproducibility 
checks.

{pstd}
The optional {opt fromstring} mode rounds directly from string representations before conversion to numeric 
storage, allowing decimal values to be interpreted from their textual form rather than from an existing 
floating‑point approximation.

{pstd}
{bf:New in version 3.1.0:} The command now supports {opt fromstring} mode for precision rounding from
literals and reports specific counts for generated vs. changed observations.

{pstd}
{bf:New in version 4.0.0:} Fixed a bug affecting string variable processing. Full support is now
provided for direct conversion and exact rounding from string representations using either {opt generate(newvar)} or {opt replace}.

{marker remarks}{...}
{title:Remarks: Precision and binary representation}

{pstd}
As frequently noted by Nicholas J. Cox, many decimal fractions (such as 0.1 or 0.01) lack
exact binary representations, leading to apparent numerical "noise" in computations. For a detailed
discussion of rounding behavior in Stata, see Cox, N. J. (2018),
{it:Speaking Stata: From rounding to binning}. {it:Stata Journal} 18: 741–754.

{pstd}
Foundational discussion of the architectural limits of digital arithmetic is provided by
William Gould. See Gould, W. (2006), {it:Mata Matters: Precision}.
{it:Stata Journal} 6: 550–560.

{pstd}
{cmd:round_exact} is based on the observation that integer values are represented exactly in binary whereas many 
decimal fractions are not. For a requested precision {opt d}, the command scales each value by 10^d, transforming the 
rounding problem into an integer-domain operation. The scaled value is then evaluated relative to the nearest 
half-integer boundary. To mitigate representation noise, {cmd:round_exact} applies machine-precision (epsilon-based) 
tolerance bounds around those boundaries. Values that fall within these bounds are treated as numerically 
equivalent to the intended decimal threshold and are rounded according to decimal rather than binary semantics.

{pstd}
After the rounding decision is made, the result is rescaled to the original decimal precision and stored as 
a double-precision numeric value. Because the procedure minimizes reliance on fractional binary units at the 
decision point, it often produces results that correspond more closely to common decimal expectations than 
direct floating-point rounding. This behavior can improve the stability of comparisons, assertions, merges, 
reproducibility checks, and other workflows in which agreement at a specified decimal precision is of primary 
interest.

{pstd}
The command operates on the finite-precision values available in memory and does not alter Stata's underlying 
floating-point representation. Consequently, differences that are smaller than machine-representable precision 
cannot be recovered once lost during storage.

{marker notes}{...}
{title:Notes}

{pstd}
{cmd:round_exact} modifies stored numeric values rather than display formatting. Unlike display
formats (such as {cmd:%9.2f}), which affect only presentation, the command ensures that values are
stored in a form suitable for exact comparisons and reliable use with {cmd:==} and {cmd:assert}.

{marker examples}{...}
{title:Examples}

{pstd}Rounding a literal:{p_end}
{phang2}{cmd:. round_exact 0.3, d(1)}{p_end}
{phang2}{cmd:. assert r(val) == 0.3}{p_end}

{pstd}Rounding a variable in a dataset:{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. round_exact wage, d(4) replace}{p_end}

{pstd}Creating a new rounded variable:{p_end}
{phang2}{cmd:. round_exact gear_ratio, d(1) generate(gr_rounded)}{p_end}
{phang2}{cmd:. list gear_ratio gr_rounded}{p_end}

{pstd}Converting and rounding string representations as double-precision numeric variables:{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str12 price}{p_end}
{phang2}{cmd:  "0.3"}{p_end}
{phang2}{cmd:  "0.15"}{p_end}
{phang2}{cmd:  "2.675"}{p_end}
{phang2}{cmd:  "1.005"}{p_end}
{phang2}{cmd:  "0.005"}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. round_exact price, d(1) generate(price2) fromstring}{p_end}
{phang2}{cmd:. round_exact price, d(2) replace fromstring}{p_end}
{phang2}{cmd:. list}{p_end}
{phang2}{cmd:. describe price price2}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:round_exact} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Scalars}{p_end}
{synopt:{cmd:r(val)}}rounded value (when rounding a literal #){p_end}
{synopt:{cmd:r(N_generated)}}number of non-missing observations created (when using {cmd:generate()}){p_end}
{synopt:{cmd:r(N_changed)}}number of observations where the value actually changed (when using {cmd:replace}){p_end}

{marker limitations}{...}
{title:Limitations}

{pstd}
{cmd:round_exact} improves alignment with expected decimal logic but does not overcome the inherent
limits of binary floating‑point arithmetic. The program does not modify Stata's numerical engine, and
any residual ambiguity near rounding boundaries reflects binary representation rather than
implementation defects. Because the command treats values within machine-precision distance of 
decimal boundaries as equivalent for rounding purposes, distinctions smaller than machine 
precision may occasionally be suppressed. Applications requiring exact decimal precision should 
use fixed‑point (scaled‑integer) representations instead of floating‑point values.

{marker author}{...}
{title:Author}

{pstd}
Anne Fengyan Shi, Pew Research Center{p_end}
{pstd}
Support: email AShi@pewresearch.org{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
Version 3 was revised based on feedback from Daniel Klein.{p_end}
