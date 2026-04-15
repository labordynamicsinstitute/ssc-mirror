{smcl}
{* *! version 3.0.0  2026-04-12}{...}
{vieweralsosee "round()" "help round"}{...}
{viewerjumpto "Syntax" "round_exact##syntax"}{...}
{viewerjumpto "Description" "round_exact##description"}{...}
{viewerjumpto "Remarks" "round_exact##remarks"}{...}
{viewerjumpto "Notes" "round_exact##notes"}{...}
{viewerjumpto "Examples" "round_exact##examples"}{...}
{viewerjumpto "Stored results" "round_exact##results"}{...}
{viewerjumpto "Limitations" "round_exact##limitations"}{...}


{title:Title}

{phang}
{bf:round_exact} {hline 2} Exact decimal rounding via integer transformation to mitigate floating‑point noise.


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
{p2coldent:* {opt d(integer)}}number of decimal places for rounding{p_end}
{synopt:{opt gen:erate(newvar)}}create a new variable containing rounded values{p_end}
{synopt:{opt replace}}overwrite the existing variable with rounded values{p_end}
{synoptline}
{p 4 6 2}* {opt d(integer)} is required.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:round_exact} addresses floating‑point precision errors commonly encountered with Stata's built‑in
{cmd:round(x, unit)} function. Standard rounding may leave binary representation noise (for example,
{cmd:round(0.3, 0.1)} yielding {cmd:0.30000000000000004}), which can cause logical comparisons and
{cmd:assert} statements to fail.

{pstd}
{cmd:round_exact} mitigates this problem by temporarily transforming decimal values into integers, 
applying a rounding offset with a conditional epsilon to guard against floating‑point edge cases, and 
then scaling results back to decimals. This approach avoids fractional binary units during rounding 
and produces results that align with expected decimal logic for statistical reporting and analysis. 
It is especially useful when rounded values are used in comparisons, merges, tabulations, or logical checks—situations where small floating‑point discrepancies can lead to unexpected results.

{pstd}
{bf:New in version 3.0.0:} Numeric rounding has been refined by using a conditional epsilon, improving
alignment between human decimal intent and binary floating‑point representation and yielding greater
accuracy than unconditional adjustment methods.


{marker remarks}{...}
{title:Remarks: Precision and binary representation}

{pstd}
As frequently noted by {help ncox:Nicholas J. Cox}, many decimal fractions (such as 0.1 or 0.01) lack
exact binary representations, leading to apparent numerical "noise" in computations. For a detailed
discussion of rounding behavior in Stata, see Cox, N. J. (2018),
{it:Speaking Stata: From rounding to binning}. {it:Stata Journal} 18: 741–754.

{pstd}
Foundational discussion of the architectural limits of digital arithmetic is provided by
{help gould:William Gould}. See Gould, W. (2006), {it:Mata Matters: Precision}.
{it:Stata Journal} 6: 550–560.

{pstd}
Integer arithmetic is inherently stable because integers are represented exactly in binary.
{cmd:round_exact} exploits this property by scaling decimals to integers for rounding and then scaling
back. This transformation produces stable decimal results, supports consistent comparisons, and
reduces spurious failures in logical checks.


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


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:round_exact} stores the following in {cmd:r()}:

{synoptset 15 tabbed}
{p2col 5 15 19 2:Scalars}{p_end}
{synopt:{cmd:r(val)}}rounded value (when rounding a literal #){p_end}
{synopt:{cmd:r(N)}}number of observations modified or generated{p_end}


{marker limitations}{...}
{title:Limitations}

{pstd}
{cmd:round_exact} improves alignment with expected decimal logic but does not overcome the inherent
limits of binary floating‑point arithmetic. The program does not modify Stata's numerical engine, and
any residual ambiguity near rounding boundaries reflects binary representation rather than
implementation defects. Applications requiring exact decimal precision should use fixed‑point
(scaled‑integer) representations instead of floating‑point values.


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
