{smcl}
{* *! version 1.0  4 Oct 2021}{...}
{viewerjumpto "Syntax" "boxcoxsim##syntax"}{...}
{viewerjumpto "Description" "boxcoxsim##description"}{...}
{viewerjumpto "Remarks" "boxcoxsim##remarks"}{...}
{viewerjumpto "Examples" "boxcoxsim##examples"}{...}
{viewerjumpto "Author and support" "sumat##author"}{...}
{title:Title}
{phang}
{bf:boxcoxsim} {hline 2} Simulating Box Cox transformed data, possibly left 
truncated and possibly with some degree of extreme values.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:boxcoxsim} 
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt n(#)}} Number of observations. The default value is 200.

{synopt:{opt m:ean(#)}} Mean for the underlying normal distribution. {red:Mean is reset if not 4 times the standard deviation to exactly that.} The default value is 4.

{synopt:{opt sd(#)}} Standard deviation for the underlying normal distribution. The default value is 1.

{synopt:{opt t:heta(#)}} Box Cox transformation on the underlying normal distribution. The default value is 1.

{synopt:{opt nd(#)}} Percentage degree of left non-detects ie of left censoring. The default value is 0.

{synopt:{opt f:mt(string)}} Format for the censored and underlying normal distribution. The default is "%6.2f".

{synopt:{opt o:utlierpct(#)}} Proportion of the upper outliers. The default value is 0.

{synopt:{opt om:ean(#)}} mean for the upper outliers.

{synopt:{opt osd:(#)}} standard deviation for upper the outliers.

{synopt:{opt ot:heta(#)}} Box Cox transformation for the upper outliers.

{synopt:{opt p:ercentiles(numlist)}} Percentiles to report for comparison. The default is "50 75 90 95 99".

{synopt:{opt c:lear}} Clear the data editor.

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:boxcoxsim} simulates data from a Box Cox (normal) distributed data with 
a possible percentage degree of left truncation and in a mixture of 
possible percentage degrees of extreme values.
It is a simulation tool for {help ros:ros}.


{marker examples}{...}
{title:Examples}


{dlgtab:Simulated data example 1}

{phang}To simulate 2000 values from a normal distribution (theta = 1 and nd = 0
by default) with a normal mean of 10 and a normal standard deviation of 2

{phang}{stata `"boxcoxsim, n(2000) mean(10) sd(2) outlierpct(0) clear"'}

{phang}A histogram of the simulated data:

{phang}{stata `"hist yc, norm ylabel(none) xtitle(normal values)"'}


{dlgtab:Simulated data example 2}

{phang}To simulate 2000 values from a squared normal distribution 
(theta = 2) with a normal mean of 2 and a normal standard deviation of 0.5. 
There are no non-detects (nd = 0 by default) and no outliers (outlierpct = 0)

{phang}{stata `"boxcoxsim, n(2000) nd(0) theta(2) mean(2) sd(0.5) outlierpct(0) clear"'}

{phang}A histogram of the simulated data:

{phang}{stata `"hist yc, norm ylabel(none) xtitle(normal values)"'}


{dlgtab:Simulated data example 3}

{phang}To simulate 2000 values from a log-normal distribution (theta = 0) 
having a normal mean of 1.5 and a normal standard deviation of 0.3 and where 
55% of data are non-detectable (nd = 55).
Further, there are 30% outliers (outlierpct = 30) with a normal mean of 2 and 
a standard deviation of 0.5.

{phang}{stata `"boxcoxsim, n(2000) nd(55) theta(0) mean(1.5) sd(0.3) outlierpct(0.3) omean(2) osd(0.5) clear"'}

{phang}Returned values:

{phang}{stata `"return list"'}

{phang}A histogram of the simulated data:

{phang}{stata `"hist yc, norm ylabel(none) xtitle(normal values)"'}


{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(y_percentileXXX)}} Empirical XXX percentile {p_end}
{synopt:{cmd:r(n)}} Number of generated data {p_end}
{synopt:{cmd:r(mean)}} The chosen mean of the underlying normal distribution {p_end}
{synopt:{cmd:r(sd)}} The chosen standard deviation of the underlying normal distribution {p_end}
{synopt:{cmd:r(theta)}} The chosen Box-Cox transformation {p_end}
{synopt:{cmd:r(non_detects_pct)}} Chosen percentage of non-detects {p_end}
{synopt:{cmd:r(outlierpct)}} The chosen percentage of outliers {p_end}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(percentiles)}} Empirical percentiles {p_end}
{p2col 5 15 19 2: Variables}{p_end}
{synopt:{cmd:y}} The Box-Cox transformed data {p_end}
{synopt:{cmd:censored}} The marker for data being censored {p_end}
{synopt:{cmd:yc}} The censored Box-Cox transformed data {p_end}

{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}


