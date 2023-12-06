{smcl}
{* *! version 1.0.0 01Nov2023}{...}

{title:Title}

{p2colset 5 15 16 2}{...}
{p2col:{hi:maxsum} {hline 2}} a function to compute the maximum value of a rolling-sum {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmd:maxsum} {helpb exp:exp} {ifin} [, {opt f:ormat}{cmd:(%}{it:{help format:fmt}}{opt )} ]

{p 4 6 2}
{opt by} is allowed with {cmd:maxsum}; see {manhelp by D}.{p_end}

{p 4 6 2}
{p2colreset}{...}	

{synoptset 19 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt f:ormat}{cmd:(%}{it:{help format:fmt}}{opt )}}display format for {opt maxsum} value; default format is {cmd:%-14.2fc}{p_end}
{synoptline}
{p2colreset}{...}
			
	
{title:Description}

{pstd}
{cmd:maxsum} is a convenience tool for computing the maximum value of a rolling (cumulative) sum of an {help exp:expression}. It is intended to 
offer Stata users a comparable solution to R's {browse "https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/sum":sum()} function
or MS Excel's {browse "https://support.microsoft.com/en-us/office/sum-function-043e1c7d-7726-4e80-8f32-07b23e057f89":sum()} function.



{title:Examples}

{pstd}Setup{p_end}
{phang2}{bf:{stata "sysuse auto, clear":. sysuse auto, clear}}{p_end}

{pstd}
Compute the maximum value of the rolling-sum for the variable {it:weight}, changing the format of the {opt maxsum} value produced {p_end}
{phang2}{bf:{stata "maxsum weight, format(%-9.0f)":. maxsum weight, format(%-9.0f)}}{p_end}

{pstd}
A more complex expression{p_end}
{phang2}{bf:{stata "maxsum (price/mpg)^2":. maxsum (price/mpg)^2}}{p_end}

{pstd}
Using the [if] expression{p_end}
{phang2}{bf:{stata "maxsum price if rep78 == 3":. maxsum price if rep78 == 3}}{p_end}

{pstd}
Using the {helpb by:by} prefix{p_end}
{phang2}{bf:{stata "bysort rep78: maxsum price":. bysort rep78: maxsum price}}{p_end}



{title:Stored results}

{pstd}
{cmd:maxsum} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(maxsum)}}the maximum value of the rolling-sum for an expression {p_end}



{marker citation}{title:Citation of {cmd:maxsum}}

{p 4 8 2}{cmd:maxsum} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, A. (2023). MAXSUM: Stata module to compute the maximum value of a rolling-sum. 
{browse "https://ideas.repec.org/c/boc/bocode/s459258.html":https://ideas.repec.org/c/boc/bocode/s459258.html}
{p_end}


{title:Authors}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{p_end}


 
{title:Also see}

{p 4 8 2} Online: {helpb sum()}, {helpb egen total()}, {helpb total} {p_end}

