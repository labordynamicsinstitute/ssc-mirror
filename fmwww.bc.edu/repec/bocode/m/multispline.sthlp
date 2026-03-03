{smcl}
{* *! version 1.0.4  Subir Hait  01mar2026}{...}
{hline}
help for {cmd:multispline}
{hline}

{title:Title}

{phang}
{bf:multispline} {hline 2} Nonlinear multilevel spline modeling

{title:Syntax}

{p 8 17 2}
{cmd:multispline}
{depvar}
{indepvar}
{ifin},
{cmd:cluster(}{varname}{cmd:)}
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt cluster(varname)}}grouping variable for multilevel model{p_end}

{syntab:Optional}
{synopt:{opt nknots(#)}}number of spline knots; default is {cmd:nknots(4)}{p_end}
{synopt:{opt autoknots}}automatically select optimal number of knots{p_end}
{synopt:{opt at(numlist)}}predict over range defined by numlist{p_end}
{synopt:{opt plot}}display plot of nonlinear fit{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:multispline} fits nonlinear multilevel regression models using
natural cubic spline basis expansion. It provides a unified workflow
for fitting, predicting, visualizing, and summarizing nonlinear effects
in hierarchical or longitudinal data.

{pstd}
The command is particularly suited to large-scale education and health
datasets such as ECLS-K, HSLS, and PISA where outcomes are expected
to have nonlinear relationships with predictors such as socioeconomic
status (SES) or treatment dosage.

{pstd}
While Stata provides {cmd:mixed} for multilevel models and
{cmd:mkspline} for spline construction, no existing Stata command
provides a unified workflow for fitting, predicting, visualizing,
and computing ICCs from nonlinear multilevel models.
{cmd:multispline} fills this gap.

{title:Options}

{phang}
{opt cluster(varname)} specifies the grouping variable for the
multilevel model. Required.

{phang}
{opt nknots(#)} number of knots for cubic spline basis.
Default is 4. Must be >= 3.

{phang}
{opt autoknots} automatically selects optimal number of knots
between 4 and 7 based on number of unique values of predictor.

{phang}
{opt at(numlist)} generates predictions over a 50-point grid
spanning the range defined by the numlist values.
Useful for smooth prediction curves.

{phang}
{opt plot} displays plot of predicted nonlinear relationship.

{title:Examples}

{pstd}
{bf:Example 1: Education example}

{phang2}{cmd:. multispline math_score ses, cluster(schid) nknots(4) plot}{p_end}

{pstd}
{bf:Example 2: Automatic knot selection}

{phang2}{cmd:. multispline math_score ses, cluster(schid) autoknots plot}{p_end}

{pstd}
{bf:Example 3: Grid predictions}

{phang2}{cmd:. multispline math_score ses, cluster(schid) nknots(4) at(-3 -2 -1 0 1 2 3) plot}{p_end}

{pstd}
{bf:Example 4: Health science example}

{phang2}{cmd:. multispline bloodpressure dosage, cluster(hospital) nknots(4) plot}{p_end}

{pstd}
{bf:Example 5: Real Stata data}

{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. multispline wage age, cluster(industry) nknots(4) plot}{p_end}

{title:Stored results}

{pstd}
{cmd:multispline} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(nknots)}}number of knots used{p_end}
{synopt:{cmd:r(nsplines)}}number of spline terms{p_end}
{synopt:{cmd:r(interior)}}number of interior knots{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(y)}}outcome variable name{p_end}
{synopt:{cmd:r(x)}}predictor variable name{p_end}
{synopt:{cmd:r(cluster)}}cluster variable name{p_end}
{synopt:{cmd:r(knots)}}interior knot locations{p_end}
{synopt:{cmd:r(cmd)}}command name{p_end}
{synoptline}
{p2colreset}{...}

{title:Author}

{pstd}
Subir Hait{break}
Michigan State University{break}
haitsubi@msu.edu{break}
{browse "https://github.com/causalfragility-lab/MultiSpline-Stata"}

{title:References}

{phang}
Bates, D., Maechler, M., Bolker, B., and Walker, S. (2015).
Fitting linear mixed-effects models using lme4.
{it:Journal of Statistical Software}, 67(1), 1-48.

{phang}
Hastie, T. and Tibshirani, R. (1990).
{it:Generalized Additive Models}.
CRC Press.

{phang}
Raudenbush, S. W. and Bryk, A. S. (2002).
{it:Hierarchical Linear Models}.
Sage Publications.

{title:Also see}

{psee}
{helpb mixed}, {helpb mkspline}, {helpb estat icc}
{p_end}
