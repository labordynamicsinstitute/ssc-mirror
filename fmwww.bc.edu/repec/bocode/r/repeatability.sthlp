{smcl}
{* *! version 1.0.0 13Aug2023}{...}
{title:Title}

{p2colset 5 22 23 2}{...}
{p2col:{hi:repeatability} {hline 2}} Repeatability coefficient {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:repeatability}
{it:{help varname:rating1}} 
{it:{help varname:rating2}}
[{it:{help varname:rating3}} {it:...}]
{ifin}
[, {opt l:evel(#)}
{opt onesid:ed}
]

 

{synoptset 16 tabbed}{...}
{synopthdr:repeatability}
{synoptline}
{synopt:{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt onesid:ed}}one-sided test; default is two sided{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt by} is allowed with {cmd:repeatability}; see {manhelp by D}.{p_end}



{marker description}{...}
{title:Description}

{pstd}
{opt repeatability} computes the repeatability coefficient (RC) which has been described as the "consistency of quantitative results obtained when the same imaging
test is performed at short intervals on the same subjects or test objects using the same equipment in the same center" (Barnhart & Barboriak 2009), or
interpreted as the "smallest detectable difference between a test and retest measurement for a given subject, defined as a 100(1−α/2)% quantile of the 
distribution of test-retest differences" (Baumgartner et. al. 2018). More specifically, the interpretation of RC is that the difference between any two 
readings on the same subject is expected to be from −RC to RC for 95% (or whatever level is specified) of subjects (Barnhart & Barboriak 2009; Bland & Altman 1996).

{pstd} 
{opt repeatability} computes confidence intervals based on the chi2 method described by Barnhart & Barboriak (2009), but I recommend using the bootstrap as
shown in the example below.  



{title:Options}

{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for confidence intervals. The default is {cmd:level(95)}. 

{p 4 8 2}
{cmd:onesided} indicates a one-sided test. The default is two-sided.



{title:Examples}

{pstd}Setup {p_end}
{phang2}{cmd:. use lungfunction.dta}{p_end}

{pstd} Compute repeatability across four measurements of lung function in each of 20 schoolchildren (data are from Bland & Altman [1996]).  {p_end}
{phang2}{cmd:. repeatability rating1 - rating4}{p_end}

{pstd} Same as above but set CI level to 99.  {p_end}
{phang2}{cmd:. repeatability rating1 - rating4, level(99)}{p_end}

{pstd}We now rerun {opt repeatability} and apply the bootstrap to compute 95% confidence intervals {p_end}
{phang2}{cmd:. bootstrap repeatability = r(repeat), reps(1000): repeatability rating1 - rating4}{p_end}
{phang2}{cmd:. estat bootstrap, all}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:repeatability} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(ntar)}}number of targets (observations) {p_end}
{synopt:{cmd:r(nrat)}}number of ratings {p_end}
{synopt:{cmd:r(wssd)}}within-subject standard deviation{p_end}
{synopt:{cmd:r(repeat)}}repeatability coefficient{p_end}
{synopt:{cmd:r(lcl)}}lower confidence limit{p_end}
{synopt:{cmd:r(ucl)}}upper confidence limit{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Barnhart, H. X., and D. P. Barboriak. 2009. Applications of the repeatability of quantitative
imaging biomarkers: a review of statistical analysis of repeat data sets. 
{it:Translational Oncology} 2: 231–5.{p_end}

{p 4 8 2}
Baumgartner, R., Joshi, A., Feng, D., Zanderigo, F. and R. T. Ogden. 2018. Statistical evaluation of test-retest 
studies in PET brain imaging. {it:EJNMMI Research} 8: 1-9.{p_end}

{p 4 8 2}
Bland, J. M. and D. G. Altman. 1996. Statistics notes: measurement error. {it:BMJ} 312: 1654.{p_end}



{marker citation}{title:Citation of {cmd:repeatability}}

{p 4 8 2}{cmd:repeatability} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). REPEATABILITY: Stata module to compute the repeatability coefficient.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb icc}, {helpb finn} (if installed), {helpb robinson} (if installed), {helpb bhapkar} (if installed), {helpb iota} (if installed), 
{helpb maxwell} (if installed), {helpb wscv} (if installed), {helpb kappaetc} (if installed){p_end}

