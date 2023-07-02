{smcl}
{* *! version 1.0.0 24Jun2023}{...}
{title:Title}

{p2colset 5 13 14 2}{...}
{p2col:{hi:finn} {hline 2}} Finn's coefficient of reliability {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:finn}
{it:{help varname:varname1}} 
{it:{help varname:varname2}}
[{it:{help varname:varname3}} {it:...}]
{ifin} 
[,
{opt I:d}{cmd:(}{it:{help varname:varname}{cmd:})}
{opt CAT:egories(#)}]


{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt i:d(varname)}}subject identifier; when {cmd: id()} is not specified, the Finn coefficient is computed assuming that observations are independent{p_end}
{synopt :{opt cat:egories(#)}}the number of categories in a categorical level rating system; when {cmd: categories()} is not specified the data are assumed to be continuous {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt by} is allowed with {cmd:finn}; see {manhelp by D}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt finn} computes Finn's reliability coefficient (Finn 1970). Although initially designed for categorical (sequential integer)
ratings (e.g. 1,2,3,4,5), Gwet (2021) has generalized Finn's coefficient to accommodate continuous (quantitative) ratings. 
The coefficient, which is also known in the literature as a {it:Within-Group Inter-Rater Reliability} statistic, may be considered
an alternative to the intraclass correlation coefficient (ICC) for estimating inter-rater reliability. The statistic may be helpful
when the sample is either small or not sufficiently diverse -- which will result in a very low ICC, even though there may be 
a good-to-high correlation between ratings.

{pstd}
To compute the Finn's reliability coefficient, first, all subject-level variances are averaged to obtain the mean subject variance (MSV). This 
number tells us how far on average the rating from any given judge will stray away from the average rating. The smaller the mean subject variance,
the higher the rater agreement. Second, we compute the expected value that this mean subject variance (eMSV) would take if the ratings were assigned to subjects 
in a purely random manner. Finally Finn's coefficient is computed as 1-(MSV/eMSV). See Gwet (2021) for a comprehensive discussion.
 


{title:Options}

{p 4 8 2} 
{cmd:id(}{it:varname}{cmd:)} specifies the subjects' identifier. When {cmd: id()} is not specified, 
the Finn coefficient is computed assuming that observations are independent. 

{p 4 8 2} 
{cmd:categories(}{it:#}{cmd:)} the number of categories possible in the rating scale. For example, if the data are from a Likert scale with possible responses ranging from 0 to 7, the user
should specify {cmd: categories(7)}. When {cmd: categories()} is not specified, the Finn coefficient is computed using Gwet's (2021) generalized method for continuous data.



{title:Examples}

{pstd}Setup for repeated observations and continuous scores{p_end}
{phang2}{cmd:. use example7_1.dta}{p_end}

{pstd}These data have 4 raters, subjects have repeated measurements, and the data are continuous {p_end}
{phang2}{cmd:. finn judge1- judge4, i(subject)}{p_end}

{pstd}We now apply the bootstrap to compute 95% confidence intervals {p_end}
{phang2}{cmd:. bootstrap finn = r(finn), cluster(subject) reps(1000): finn judge1- judge4, i( subject)}{p_end}
{phang2}{cmd:. estat bootstrap, all}

{pstd}Setup for independent observations and categorical scores{p_end}
{phang2}{cmd:. example7_3.dta}{p_end}

{pstd}These data have 5 raters and 4 independent observations. The ratings are on a 1-5 Likert scale even though the actual scores only range from 1-3  {p_end}
{phang2}{cmd:. finn judge1- judge5, cat(5)}{p_end}

{pstd}We now apply the bootstrap to compute 95% confidence intervals {p_end}
{phang2}{cmd:. bootstrap finn = r(finn), reps(1000): finn judge1- judge5, cat(5)}{p_end}
{phang2}{cmd:. estat bootstrap, all}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:finn} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(MSV)}}mean subject variance{p_end}
{synopt:{cmd:r(eMSV)}}expected mean subject variance{p_end}
{synopt:{cmd:r(finn)}}finn's coefficient of reliability{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Finn, R. H. 1970. A note on estimating the reliability of categorical data. {it:Educational and Psychological Measurement} 30: 71-76.{p_end}

{p 4 8 2}
Gwet, K. L. 2021. Handbook of Inter-Rater Reliability, 5th Edition. Volume 2: Analysis of Quantitative Ratings. Gaithersburg, MD:  Advanced Analytics.{p_end}



{marker citation}{title:Citation of {cmd:finn}}

{p 4 8 2}{cmd:finn} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). FINN: Stata module to compute Finn's coefficient of reliability.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb icc}, {helpb kappaetc} (if installed){p_end}

