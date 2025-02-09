{smcl}
{* 05Feb2025}{...}


{title:Title}

{p2colset 5 19 20 2}{...}
{p2col :{hi:power_step} {hline 2}}Power analysis for a step intervention with AR(1) Error {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:power_step}{cmd:,}
{cmdab:nt:ime(}{it:#}{cmd:)}
{cmdab:trp:eriod(}{it:#}{cmd:)}
{cmdab:phi(}{it:#}{cmd:)}
[ {cmdab:a:lpha(}{it:#}{cmd:)} ]



{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt nt:ime}{cmd:(}{it:#}{cmd:)}}specify the number of time periods in the series{p_end}
{p2coldent:* {opt trp:eriod}{cmd:(}{it:#}{cmd:)}}specify the time period when the intervention begins {p_end}
{p2coldent:* {opt phi}{cmd:(}{it:#}{cmd:)}}specify the correlation coefficient between adjacent (autoregressive) error terms {p_end}
{synopt:{opt a:lpha}{cmd:(}{it:#}{cmd:)}}significance level; default is {cmd:alpha(0.05)}{p_end}
{synoptline}
{p 4 6 2}* {opt ntime()}, {opt trperiod()}, {opt phi()} are required. {p_end}
{p2colreset}{...}



{title:Description}

{pstd}
{cmd:power_step} computes power for an interrupted time series analysis (ITSA) in which the intervention is expected to change the level (step) of 
the series (McLeod and Vingilis 2008). The results are computed in terms of the size of the intervention effect in units corresponding to 
standard deviations of the pre-intervention series (presented as the scaled intervention parameter δ). The power estimates assume that the intervention 
analysis will be performed using an autoregressive moving-average (ARMA) model.

{pstd}
The computations and output of {cmd:power_step} largely mirror those found at {browse "https://www.stats.uwo.ca/faculty/aim/2007/OnlinePower/TwoSided.html"}. 
However, there are cases in which the results between the online calculator and {cmd:power_step} slightly differ. This is due to the fact that 
Javascript does not naturally compute the cumulative standard distribution function (CDF) and therefore the author uses an approximation. Conversely, 
{cmd:power_step} uses {cmd:normal()} to compute the CDF.



{title:Options}

{phang}
{cmd:ntime(}{it:integer}{cmd:)} specifies the number of time periods to generate in the series; {cmd:ntime() is required}. 

{phang}
{cmd:trperiod(}{it:integer}{cmd:)} specifies the time period when the intervention begins; {cmd:trperiod() is required}.

{phang}
{cmd:phi(}{it:#}{cmd:)} specifies the correlation coefficient between adjacent (autoregressive) error terms.; {cmd:phi() is required}.

{phang}
{cmd:alpha(}{it:#}{cmd:)} sets the significance level of the test. The default is {cmd:alpha(0.05)}. 



{title:Examples}

{pstd}
This example is taken from McLeod and Vingilis (2008). The results show that the probability of detecting a one
standard deviation level change from the pre-intervention is 51%

{pmore2}{cmd:. power_step , nt(40) trp(20) phi(0.50)}{p_end}

{pstd}
Increasing the lengths of the pre-intervention and post-intervention series to 50 results in a substantial increase
in power. The probability of detecting a one standard deviation change is now 85%

{pmore2}{cmd:. power_step , nt(100) trp(50) phi(0.50)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:power_step} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(p0)}}power at δ = 0 {p_end}
{synopt:{cmd:r(p1)}}power at δ = 0.25 {p_end}
{synopt:{cmd:r(p2)}}power at δ = 0.50 {p_end}
{synopt:{cmd:r(p3)}}power at δ = 0.75 {p_end}
{synopt:{cmd:r(p4)}}power at δ = 1.0 {p_end}
{synopt:{cmd:r(p5)}}power at δ = 1.25 {p_end}
{synopt:{cmd:r(p6)}}power at δ = 1.50 {p_end}
{synopt:{cmd:r(p7)}}power at δ = 1.75 {p_end}
{synopt:{cmd:r(p8)}}power at δ = 2.0 {p_end}
{synopt:{cmd:r(p9)}}power at δ = 2.25 {p_end}
{synopt:{cmd:r(p10)}}power at δ = 2.50 {p_end}
{synopt:{cmd:r(p11)}}power at δ = 2.75 {p_end}
{synopt:{cmd:r(p12)}}power at δ = 3.0 {p_end}
{p2colreset}{...}



{title:References}

{phang}
McLeod, A. I. and E. R. Vingilis. 2008.
Power computations in time series analyses for traffic safety interventions.
{it:Accident Analysis & Prevention}.
40: 1244-1248.



{marker citation}{title:Citation of {cmd:power_step}}

{p 4 8 2}{cmd:power_step} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). POWER_STEP: Stata module to compute power for a step intervention with AR(1) Error.



{title:Author}

{pstd}Ariel Linden{p_end}
{pstd}Linden Consulting Group, LLC{p_end}
{pstd}{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{p_end}
       
 
{p 7 14 2}Help: {helpb arima} {p_end}
