{smcl}
{* *! version 1.0.0 14July2023}{...}
{title:Title}

{p2colset 5 13 14 2}{...}
{p2col:{hi:iota} {hline 2}} Iota coefficient of interrater agreement for interval or nomimal multivariate observations {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:iota}
{it:{help varname:depvar1}} 
[{it:{help varname:depvar2}} {it:...}]
{ifin}
,
{opt rat:er}{cmd:(}{it:{help varname:varname}{cmd:})}
{opt tar:get}{cmd:(}{it:{help varname:varname}{cmd:})}
[ {opt st:andardize} 
  {opt no:minal}
]


{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt rat:er(varname)}}rater identifier; {cmd:rater() is required}{p_end}
{synopt :{opt tar:get(varname)}}subject identifier; {cmd:target() is required}{p_end}
{synopt :{opt st:andardize}}z-transforms the {it:depvar(s)} when the data type is interval (quantitative) {p_end}
{synopt :{opt no:minal}}indicates that the {it:depvar(s)} are nominal level data {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt by} is allowed with {cmd:iota}; see {manhelp by D}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt iota} computes the iota coefficient of interrater agreement proposed by Janson and Olsson (2001). This measure of agreement
is an extension of Cohen's (1960) kappa for univariate (single {it:depvar}) nominal data and Berry and Mielke's (1988) generalization 
of Cohen's kappa agreement measure to univariate (single {it:depvar}) interval level data to the multivariate case. 

{pstd}
As described by Janson and Olsson (2001), their proposed extension of Cohen's agreement measure is applicable to interobserver 
agreement in the case where a set of two or more judges (sampled from a larger population of possible judges) have rated a set of 
targets (sampled from a larger population of targets) on several dimensions or variables. The basic assumptions are that targets are 
independent and that judges have operated independently. When there are two judges and one variable, iota is exactly equivalent to 
Cohen's (1960) kappa. And when there is one variable and several judges, iota exactly equals Berry and Mielke's (1988) {it:R} and 
also Conger's (1980) "Fleiss exact" coefficient — a modification of a measure originally proposed by Fleiss (1971).
 

{title:Options}

{p 4 8 2} 
{cmd:rater(}{it:varname}{cmd:)} specifies the raters' identifier; {cmd:rater() is required}. 

{p 4 8 2} 
{cmd:target(}{it:varname}{cmd:)} specifies the subjects' identifier. {cmd:target() is required}.  

{p 4 8 2} 
{cmd:standardize} z-transforms the {it:depvar(s)} when the data type is interval (quantitative). This is particularly appropriate
when the {it:depvars} are on different scales.

{p 4 8 2} 
{cmd:nominal} indicates that the {it:depvar(s)} are nominal level data.


{title:Examples}

{pstd}Setup for interval (quantitative) level data{p_end}
{phang2}{cmd:. use iota_interval.dta}{p_end}

{pstd}These data are from Example 1 in Janson and Olsson (2001) where three judges have
rated height and weight of five men on the basis of photographs.{p_end}
{phang2}{cmd:. iota weight height, rater(judge) target( id)}{p_end}

{pstd}Same as above, but we standardize the variables because they are on different scales.{p_end}
{phang2}{cmd:. iota weight height, rater(judge) target( id) standardize}{p_end}

{pstd}We now apply the bootstrap to compute 95% confidence intervals {p_end}
{phang2}{cmd:. bootstrap iota = r(iota), reps(1000): iota weight height, rater(judge) target(id) standardize}{p_end}
{phang2}{cmd:. estat bootstrap, all}

{pstd}Setup for nominal level data{p_end}
{phang2}{cmd:. iota_nominal.dta}{p_end}

{pstd}These data are from Example 2 in Janson and Olsson (2001) where two judges classify six targets in
terms of their color and shape. {p_end}
{phang2}{cmd:. iota shape color, rater(judge) target(id) nominal}{p_end}

{pstd}We now apply the bootstrap to compute 95% confidence intervals. {p_end}
{phang2}{cmd:. bootstrap iota = r(iota), reps(1000): iota shape color, rater(judge) target(id) nominal}{p_end}
{phang2}{cmd:. estat bootstrap, all}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:iota} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(iota)}}the iota coefficient of interrater agreement{p_end}
{synopt:{cmd:r(ntar)}}the number of unique targets (subjects){p_end}
{synopt:{cmd:r(nrat)}}the number of unique raters{p_end}
{synopt:{cmd:r(nvar)}}the number of variables{p_end}
{synopt:{cmd:r(obs)}}the total number of observations{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Berry, K. J., & P. W. Mielke Jr. 1988. A generalization of Cohen's kappa agreement measure to interval measurement and multiple raters. 
{it:Educational and Psychological Measurement} 48: 921-933.{p_end}

{p 4 8 2}
Cohen, J. 1960. A coefficient of agreement for nominal scales. {it:Educational and Psychological Measurement} 20: 37-46.{p_end}

{p 4 8 2}
Conger, A.J. 1980. Integration and generalisation of Kappas for multiple raters. {it:Psychological Bulletin} 88: 322-328.{p_end}

{p 4 8 2}
Fleiss, J. L. 1971. Measuring nominal scale agreement among many raters. {it:Psychological Bulletin} 76: 378-382.{p_end}

{p 4 8 2}
Janson, H., & U Olsson. 2001. A measure of agreement for interval or nominal multivariate observations. {it:Educational and Psychological Measurement}
61: 277-289.{p_end}



{marker citation}{title:Citation of {cmd:iota}}

{p 4 8 2}{cmd:iota} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). IOTA: Stata module to compute the Iota coefficient of interrater agreement for interval or nominal multivariate observations.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb icc}, {helpb kappaetc} (if installed){p_end}

