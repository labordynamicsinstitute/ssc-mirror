{smcl}
{* *! Version 2.0.0 20 September 2024}{...}

{title:Title}

{p2colset 5 35 37 2}{...}
{p2col :{cmd:nehtests} {hline 4} Postestimation command for {helpb nehurdle}.}{p_end}
{p2colreset}{...}

{title:Syntax}
{pstd} {cmd:nehtests}

{marker description}{...}
{title:Description}

{pstd}
{cmd:nehtests} displays Wald test of joint significance for the parameters of each
of the equations you are estimating, and for the overall model. The number of tests
will depend on the specification of your model you are estimating.

{pstd}
All the statistics reported for the different tests were stored in the estimation
results as scalars. See {help nehurdle##stscal: Stored Results - Scalars} in the
{cmd:nehurdle} help file.

{pstd}
These tests are not valid if you are using {cmd:nehurdle} with {cmd:svy} estimation
results.

{marker examples}{...}
{title:Examples}

{dlgtab:Models for Continuous Variables}

{pstd}Data Setup{p_end}
{phang2}. {stata "webuse womenwk, clear"}{p_end}
{phang2}. {stata "replace wage = 0 if missing(wage)"}{p_end}
{phang2}. {stata "global xvars i.married children educ age"}{p_end}

{pstd}Homoskedastic Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, tobit nolog"}{p_end}
{phang2}. {stata "nehtests"}{p_end}

{pstd}Heteroskedastic Exponential Truncated Hurdle{p_end}
{phang2}. {stata "nehurdle wage $xvars, expon het($xvars) nolog"}{p_end}
{phang2}. {stata "nehtests"}{p_end}

{pstd}Heteroskedastic Exponential Type II Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, heckman expon het($xvars) nolog"}{p_end}
{phang2}. {stata "nehtests"}{p_end}

{dlgtab:Models for Count Data}

{pstd}Data Setup{p_end}
{phang2}. {stata "use http://www.stata-press.com/data/mus2/mus220mepsdocvis, clear"}{p_end}
{phang2}. {stata global xvars i.private i.medicaid age educyr i.actlim totchr}{p_end}
{phang2}. {stata global shet income age totchr}{p_end}
{phang2}. {stata global ahet age totchr i.female}{p_end}

{pstd}Poisson Truncated Hurdle:{p_end}
{phang2}. {stata "nehurdle docvis $xvars, truncp nolog"}{p_end}
{phang2}. {stata "nehtests"}{p_end}

{pstd}NB1 Truncated Hurdle with dispersion heterogeneity:{p_end}
{phang2}. {stata "nehurdle docvis $xvars, truncnb1 nolog het($ahet)"}{p_end}
{phang2}. {stata "nehtests"}{p_end}

{pstd}Selection Heteroskedastic NB2 Truncated Hurdle with dispersion heterogeneity:{p_end}
{phang2}. {stata "nehurdle docvis $xvars, truncnb2 nolog het($ahet) sel(, het($shet))"}{p_end}
{phang2}. {stata "nehtests"}{p_end}
