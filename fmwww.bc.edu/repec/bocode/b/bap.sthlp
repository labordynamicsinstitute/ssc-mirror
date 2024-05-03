{smcl}
{* *! version 1.0 23 Apr 2024}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "bap##syntax"}{...}
{viewerjumpto "Description" "bap##description"}{...}
{viewerjumpto "Examples" "bap##examples"}{...}
{viewerjumpto "References" "bap##references"}{...}
{viewerjumpto "Author and support" "bap##author"}{...}
{title:Title}
{phang}
{bf:bap} {hline 2} A Bland-Altman plot generator

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:bap}
varlist(min=2
max=2
numeric)
[{help if}]
[{cmd:,}
{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt nog:raph}}  Do not generate a Bland-Altman plot

{synopt:{opt f:ormatgraph(string)}}  Stata number format to use in graph (default is %4.1f)

{synopt:{opt T:ext(string)}}  String value for the first legend (default is 
variable 1 label/variable 1 name vs variable 1 label/variable 1 name)

{synopt:{opt s:catterstyle(string)}}  A {help twoway:twoway} scatter marker specification 
(default is jitter(3))

{synopt:{opt m:eanlinestyle(string)}}  A {help twoway:twoway} line specification for the mean 
line (default is lcolor(gs8) lpattern(solid))

{synopt:{opt loa:linestyle(string)}}  A {help twoway:twoway} line specification for the LOA 
lines (default is lcolor(gs8) lpattern(dash))

{synopt:{opt R:oweq(string)}}  A string for setting roweq in the returned r(bap) 
matrix. It is useful when combining more Bland-Altman analyses into one

{synopt:{opt low:ess}}  Use a lowess curve instead of the mean of the differences

{synopt:{opt k:eepvariables}}  keep the variables for the means and the differences

{synopt:{opt *}} Any {help twoway:twoway} option{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}The command {cmd:bap} is yet another Bland-Altman plot generator.{break}
It is fairly simple and quite flexible to use.{break}
There is an option for having a lowess curve to visualize a trend instead of 
the mean line.{break}
Further, the command {cmd:bap} returns a matrix containing key information on 
the measurements: 
The mean measurements with 95% CI, the bias with 95% CI, the SEM, and the LOA limits.

{marker examples}{...}
{title:Examples}

{phang}Get Bland-Altman dataset:{p_end}
{phang}{stata `". infile using "https://www-users.york.ac.uk/~mb55/datasets/pefr.dct", clear"'}{p_end}
{phang}{stata `". label variable wright1 "PEFR 1, Wright (l/min)"'}{p_end}
{phang}{stata `". label variable wright2 "PEFR 2, Wright (l/min)"'}{p_end}
{phang}{stata `". label variable mini1 "PEFR 1, mini Wright (l/min)"'}{p_end}
{phang}{stata `". label variable mini2 "PEFR 2, mini Wright (l/min)"'}{p_end}

{phang}Making a Bland-Altman plot:{p_end}
{phang}{stata `". bap mini1 mini2"'}{p_end}

{phang}Making a Bland-Altman plot with different marker and line styles:{p_end}
{phang}{stata `". bap mini1 mini2, name(g1, replace) loa(lp(dot) lc(red) lw(thick)) m(lc(green)) s(mcolor(red))"'}{p_end}

{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(grphcmd)}}  The graph command for the Bland-Altman plot{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(bap)}}  A matrix containing key information on the measurements: 
The mean measurements with 95% CI, the bias with 95% CI, the SEM, and the LOA limits{p_end}

{marker references}{...}
{title:References}
{pstd}1983 Altman - Measurement in Medicine, the Analysis of Method
{break}1986 Bland - Statistical method for assessing agreement between two methods of clinical measurement
{break}2009 Carstensen - Comparing methods of measurement; Extending the LoA by regression
{break}2015 Giavarina - Understanding Bland Altman analysis
{break}2016 Montenij - Methodology of method comparison studies evaluating the validity of cardiac output monitors; A stepwise approach and checklist
{break}2017 Taffe - biasplot; A Package to Effective Plots to Assess Bias and Precision in Method Comparison Studies
{break}2023 Chatfield - blandaltman; A command to create variants of Bland–Altman plots

{marker author}{...}
{title:Authors and support}


{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
