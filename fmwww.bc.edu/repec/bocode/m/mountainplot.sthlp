{smcl}
{* *! version 1.0.0 18Aug2023}{...}
{title:Title}

{p2colset 5 21 22 2}{...}
{p2col:{hi:mountainplot} {hline 2}} Folded Empirical Distribution Function Curves (Mountain Plots) {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:mountainplot}
{it:{help varlist:varlist}} 
{ifin}
[, {opt st:andardize}
{cmd:}{it:{help twoway_options:twoway_options}}
]

 

{synoptset 16 tabbed}{...}
{synopthdr:mountainplot}
{synoptline}
{synopt:{opt st:andardize}}standardizes values of {it:varlist} to have a mean of 0 and standard deviation of 1 {p_end}
{synopt:{it:{help twoway_options:twoway_options}}}allows all available options of {help twoway_options:twoway graphs}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}



{marker description}{...}
{title:Description}

{pstd}
{opt mountainplot} produces mountainplots as proposed by Monti (1995). A mountainplot is a graphical representation of an empirical 
cumulative distribution function in which pecentile values above 50 are "folded" (i.e. subtracted from 100 in order to produce a 
reverse ordering). The resulting graphic resembles a mountain where the peak is approximately at the median.

{pstd}
Monti (1995) suggests that mountain plots allow the user to perform the following:{p_end}

{pstd}
1. Determine the median.{p_end}
{pstd}
2. Determine the range.{p_end}
{pstd}
3. Determine the central or tail percentiles of any magnitude.{p_end}
{pstd}
4. Observe outliers.{p_end}
{pstd}
5. Observe unusual gaps in the data.{p_end}
{pstd}
6. Examine the data for symmetry.{p_end}
{pstd}
7. Compare several distributions.{p_end}
{pstd}
8. Visually gauge the sample size.{p_end}



{title:Options}

{p 4 8 2}
{cmd:standardize} transforms the data in {it:varlist} to have a mean of 0 and standard deviation of 1. This option is 
particularly appropriate when more than one variable is being plotted and the variables are on different scales.

{p 4 8 2}
{cmd:{it:{help twoway_options:twoway_options}}} allows all available options for twoway graphs.



{title:Examples}

{pstd}Setup {p_end}
{phang2}{cmd:. use lungfunction.dta}{p_end}

{pstd} Produce a mountainplot for the first of four measurements of lung function in each of 20 schoolchildren (data are from Bland & Altman [1996])  {p_end}
{phang2}{cmd:. mountainplot rating1}{p_end}

{pstd} Now plot all four measurements of lung function  {p_end}
{phang2}{cmd:. mountainplot rating1 - rating4}{p_end}

{pstd}Same as above but used standardized values for the specified variables {p_end}
{phang2}{cmd:. mountainplot rating1 - rating4, stand}{p_end}



{title:References}

{p 4 8 2}
Bland, J. M. and D. G. Altman. 1996. Statistics notes: measurement error. BMJ 312: 1654.

{p 4 8 2}
Monti, K. L. 1995. Folded empirical distribution function curves-mountain plots. {it:The American Statistician} 49: 342–345.



{marker citation}{title:Citation of {cmd:mountainplot}}

{p 4 8 2}{cmd:mountainplot} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). MOUNTAINPLOT: Stata module to produce folded empirical distribution function curves (mountain plots)



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb cumul}, {helpb mountain} (if installed){p_end}

