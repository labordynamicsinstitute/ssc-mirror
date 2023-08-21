{smcl}
{* *! version 1.0.0 13Aug2023}{...}
{title:Title}

{p2colset 5 13 14 2}{...}
{p2col:{hi:wscv} {hline 2}} Within-subject coefficient of variation {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:wscv}
{it:{help varname:rating1}} 
{it:{help varname:rating2}}
[{it:{help varname:rating3}} {it:...}]
{ifin}
[, {opt l:evel(#)}
{opt onesid:ed}
]

 

{synoptset 16 tabbed}{...}
{synopthdr:wscv}
{synoptline}
{synopt:{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt onesid:ed}}one-sided test; default is two sided{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt by} is allowed with {cmd:wscv}; see {manhelp by D}.{p_end}



{marker description}{...}
{title:Description}

{pstd}
{opt wscv} computes the within-subject coefficient of variation (WSCV) among two or more repeated tests or ratings. The WSCV is widely used as a measure of reliability and reproducibility
for interval-level (continuous) data in medical and biological science. Quan and Shih (1996) recommend the WSCV as an alternative to the intraclass correlation (ICC) to assess reproducibility
of a measurement when the study population is homogeneous. In such cases, the ICC (which relies on between-subject variation) will produce a low estimate, whereas the WSCV is unaffected. 

{pstd} 
{opt wscv} uses the "within-subject standard deviation method" for computing WSCV, as described in Bland & Altman (1996). Two alternative computation approaches are the 
"root mean square method" and "logarithmic method" as described in Bland (2006). All methods appear to produce similar point estimates, but there are various approaches to computing 
confidence intervals that produce different results. {opt wscv} computes confidence intervals based on the delta method (Quan and Shih 1996), but I recommend using the bootstrap as
shown in the example below. The smaller the WSCV, the better the reproducibility. Estimates produced by {opt wscv} can be multiplied by 100 to provide results as a percentage.  



{title:Options}

{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for confidence intervals. The default is {cmd:level(95)}. 

{p 4 8 2}
{cmd:onesided} indicates a one-sided test. The default is two-sided.



{title:Examples}

{pstd}Setup {p_end}
{phang2}{cmd:. use lungfunction.dta}{p_end}

{pstd} Compute WSCV across four measurements of lung function in each of 20 schoolchildren (data are from Bland & Altman [1996]).  {p_end}
{phang2}{cmd:. wscv rating1 - rating4}{p_end}

{pstd} Same as above but set CI level to 99.  {p_end}
{phang2}{cmd:. wscv rating1 - rating4, level(99)}{p_end}

{pstd}We now rerun {opt wscv} and apply the bootstrap to compute 95% confidence intervals {p_end}
{phang2}{cmd:. bootstrap wscv = r(wscv), reps(1000): wscv rating1 - rating4}{p_end}
{phang2}{cmd:. estat bootstrap, all}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:wscv} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(ntar)}}number of targets (observations) {p_end}
{synopt:{cmd:r(nrat)}}number of ratings {p_end}
{synopt:{cmd:r(mu)}}mean of subject means {p_end}
{synopt:{cmd:r(wssd)}}within-subject standard deviation{p_end}
{synopt:{cmd:r(sd)}}standard deviation of the WSCV {p_end}
{synopt:{cmd:r(lcl)}}lower confidence limit{p_end}
{synopt:{cmd:r(ucl)}}upper confidence limit{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Bland, J. M. and D. G. Altman. 1996. Statistics notes: measurement error. {it:BMJ} 312: 1654.{p_end}

{p 4 8 2}
Bland, J. M. 2006. How should I calculate a within-subject coefficient of variation? Found at:
{browse "https://www-users.york.ac.uk/~mb55/meas/cv.htm"} {p_end}

{p 4 8 2}
Quan, H., and W. Shih. 1996. Assessing reproducibility by the within-subject coefficient of variation with random effects models. {it:Biometrics} 52: 1195-1203.{p_end}




{marker citation}{title:Citation of {cmd:wscv}}

{p 4 8 2}{cmd:wscv} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). WSCV: Stata module to compute the within-subject coefficient of variation.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb icc}, {helpb finn} (if installed), {helpb robinson} (if installed), {helpb bhapkar} (if installed), {helpb iota} (if installed), 
{helpb maxwell} (if installed), {helpb repeatability} (if installed), {helpb kappaetc} (if installed){p_end}

