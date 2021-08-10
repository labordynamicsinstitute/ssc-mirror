{smcl}
{* *! version 1.0 27 Feb 2021}{...}
{viewerjumpto "Syntax" "onewai##syntax"}{...}
{viewerjumpto "Options" "onewai##options"}{...}
{viewerjumpto "Examples" "onewai##examples"}{...}
{viewerjumpto "Results" "onewai##results"}{...}
{viewerjumpto "Author and support" "onewai##author"}{...}
{title:Title}
{phang}
{bf:onewai} {hline 2} Immediate oneway analysis of variance similar to 
{help oneway:oneway} and {help loneway:loneway}. 
However, here all results are gathered in matrices.
Input is either a matrix of n's, means and standard deviations or n's, means 
and standard deviations given separately.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:onewai}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Either }
{synopt:{opt nms:matrix(string)}}A n, means, SDs matrix. Ie n, means and SDs 
in a column matrix.{p_end}
{synopt:{opt t:ranspose}}If the {opt nms:matrix(string)} is a n, means 
and SDs row matrix it can be transposed.{p_end}
{syntab:or }
{synopt:{opt m:eans(numlist)}}A numlist of means{p_end}
{synopt:{opt n:(numlist)}}A numlist of n's.
This numlist is resized the {opt m:eans(numlist)}{p_end}
{synopt:{opt s:ds(numlist)}}A numlist of SD's.
This numlist is resized the {opt m:eans(numlist)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker examples}{...}
{title:Examples}

{phang}Compare three means with same n and two standard deviations:{p_end}
{phang}{stata `"onewai, n(20) means(122 113 130) sds(6 7)"'}
{p_end}

{phang}Compare four groups with different n and standard deviations:{p_end}
{phang}{stata `"onewai, n(3 3 2 2) means(111.9 52.733333 78.65 77.5) sds(6.7535176 5.3928966 11.667262 14.424978)"'}
{p_end}

{phang}Compare the result to:{p_end}
{phang}{stata `"webuse apple"'}{p_end}
{phang}{stata `"oneway weight treatment"'}{p_end}
{phang}{stata `"loneway weight treatment"'}{p_end}

{phang}Compare two groups with different n and standard deviations:{p_end}
{phang}{stata `"onewai, n(20 30) m(19 20) s(3 2)"'}

{phang}Compare the result to:{p_end}
{phang}{stata `"ttesti 20 19 3 30 20 2"'}{p_end}

{phang}Integration to eg {help sumat:sumat} using {opt nms:matrix}:{p_end}
{phang}{stata `"webuse apple"'}{p_end}
{phang}{stata `"sumat weight, statistics(n mean sd) rowby(treatment)"'}{p_end}
{phang}{stata `"onewai , nmsmatrix(r(sumat))"'}{p_end}

{phang}Integration to eg {help sumat:sumat} using {opt nms:matrix} and  {opt t:ranspose}:{p_end}
{phang}{stata `"webuse apple"'}{p_end}
{phang}{stata `"sumat weight, statistics(n mean sd) rowby(treatment)"'}{p_end}
{phang}{stata `"onewai , nmsmatrix(r(sumat)') transpose"'}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:onewai} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 25 2: Matrix}{p_end}
{synopt:{cmd:r(anova)}}The ANOVA table.{p_end}
{synopt:{cmd:r(bartletts)}}The Bartlett's test of equal variances table.{p_end}
{synopt:{cmd:r(table)}}The means, standard deviations, standard errors and 
confidence intervals table.{p_end}
{synopt:{cmd:r(total)}}The means, standard deviations, standard errors and 
confidence intervals table for totals only.{p_end}
{synopt:{cmd:r(icc)}}The ICC table.{p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}



