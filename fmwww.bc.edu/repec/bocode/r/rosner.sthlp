{smcl}
{* *! version 1.0.0  09apr2024}{...}

{title:Title}

{p2colset 5 15 16 2}{...}
{p2col:{hi:rosner} {hline 2}} Rosner's generalized extreme studentized deviate (ESD) procedure to detect multiple outliers  {p_end}
{p2colreset}{...}



{marker syntax}{...}
{title:Syntax}

{p 8 19 2}
		{cmd:rosner} {varname} {ifin} 
		[{cmd:,}  
		{opt k}({it:#})
		{opt a:lpha(#)} ]


{synoptset 14 tabbed}{...}
{synoptline}
{synopt:{opt k(#)}}maximum number of outliers to detect; {cmd:default is k(1)}{p_end}
{synopt:{opt a:lpha(#)}}significance level; default is {cmd:alpha(0.05)}{p_end}
{synoptline}
{phang}
{opt by} is allowed with {cmd:rosner}; see {help prefix}.



{marker description}{...}
{title:Description}

{pstd}
{cmd:rosner} implements Rosner's (1983) generalized extreme studentized deviate (ESD) procedure to test for up to {it:k} 
potential outliers. Rosner's test has an advantage over some other procedures because it is designed to avoid "masking", 
which occurs when an outlier goes undetected because it is close in value to another outlier. 

{pstd}
Of note, Rosner (1983) indicates that this approximation does not work well for small samples (n < 25) and the 
procedure's accuracy is still unknown when applied to non-normally distributed data.



{title:Options}

{phang}
{cmd:by(}{it:k}{cmd:)} specifies the maximum number of potential outliers to detect. The default is {cmd:k(1)}.

{phang}
{opt alpha(#)} specifies the significance level; default is {cmd:alpha(0.05)}.



{title:Examples}

{pstd}Load example data (from Table 4 in Rosner [1983]) {p_end}
{p 4 8 2}{stata "use rosner_table4, clear":. use rosner_table4, clear}{p_end}

{pstd}Assume a maximum of 10 potential outliers (Rosner [1983]){p_end}
{p 4 8 2}{stata "rosner x, k(10)":. rosner x, k(10)}{p_end}

{pstd}Set alpha to 0.01 {p_end}
{p 4 8 2}{stata "rosner x, k(10) alpha(0.01)":. rosner x, k(10) alpha(0.01)}{p_end}


{p2colreset}{...}

{title:References}

{phang}
Rosner, B. 1983. Percentage points for a generalized ESD many-outlier procedure. {it:Technometrics} 25: 165-172. 



{title:Citation of {cmd:rosner}}

{p 4 8 2}{cmd:rosner} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2024. rosner: Stata module for implementing Rosner's generalized extreme studentized deviate (ESD) 
procedure to detect multiple outliers. {p_end}



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}


        
{title:Also see}

{p 4 8 2} {helpb grubbs} (if installed), {helpb obsofint} (if installed) {p_end}
