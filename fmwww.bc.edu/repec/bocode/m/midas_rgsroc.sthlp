{smcl}
{* version 2.00  25mar2026}{...}
{cmd:help midas rgsroc}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas rgsroc} {hline 2} Rutter-Gatsonis HSROC curve

{hline}

{title:Syntax}

{p 8 18 2}
{cmd:midas rgsroc}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Curve bands}
{synopt:{cmd:cbounds}}pointwise confidence bounds around the SROC curve{p_end}
{synopt:{cmd:cregion}}confidence band as a shaded area; color via {cmd:crcolor()}{p_end}
{synopt:{cmd:pbounds}}pointwise prediction bounds{p_end}
{synopt:{cmd:pregion}}prediction band as a shaded area; color via {cmd:prcolor()}{p_end}
{synopt:{cmd:crcolor(}{it:colorstyle}{cmd:)}}color for confidence region; default blue%30{p_end}
{synopt:{cmd:prcolor(}{it:colorstyle}{cmd:)}}color for prediction region; default green%30{p_end}

{syntab:Curve styling}
{synopt:{cmd:curveopts(}{it:line_options}{cmd:)}}options for the SROC curve line{p_end}

{syntab:Study points}
{synopt:{cmd:data}}overlay observed (Se, 1-Sp) study points{p_end}
{synopt:{cmd:weighted}}size study markers by inverse-variance weight{p_end}
{synopt:{cmd:labeldata}}label each study point with its sequence number{p_end}
{synopt:{cmd:pointopts(}{it:scatter_options}{cmd:)}}marker options for the study scatter points{p_end}

{syntab:Legend and layout}
{synopt:{cmd:lgnd}}display a legend{p_end}
{synopt:{cmd:lgnpos(}{it:#}{cmd:)}}legend position; default {cmd:lgnpos(6)}{p_end}
{synopt:{cmd:level(}{it:#}{cmd:)}}confidence/prediction level; default {cmd:level(95)}{p_end}
{synopt:{it:graph_options}}any {helpb twoway} options{p_end}
{synoptline}

{hline}

{title:Description}

{pstd}
{cmd:midas rgsroc} plots the Rutter-Gatsonis hierarchical SROC (HSROC) curve
after a {cmd:midas mle}, {cmd:midas qrsim}, {cmd:midas mh}, {cmd:midas hmc},
or {cmd:midas inla} estimation command. Sensitivity is on the y-axis,
specificity (reversed) on the x-axis. The curve and its confidence and
prediction bounds are constructed from the HSROC parameterisation (alpha,
theta, beta, sigma²_alpha, sigma²_theta) recovered via the delta method from
the bivariate random-effects estimates.

{pstd}
{cmd:cbounds}/{cmd:cregion} are mutually exclusive; so are {cmd:pbounds}/{cmd:pregion}.

{hline}

{title:Options}

{phang}
{cmd:cbounds} draws dashed pointwise confidence bounds for the SROC curve.
Default color is blue.

{phang}
{cmd:cregion} draws the confidence band as a shaded area. Default color is
blue%30; override with {cmd:crcolor()}.

{phang}
{cmd:pbounds} draws dashed pointwise prediction bounds. Default color is green.

{phang}
{cmd:pregion} draws the prediction band as a shaded area. Default color is
green%30; override with {cmd:prcolor()}.

{phang}
{cmd:curveopts(}{it:line_options}{cmd:)} overrides the default SROC curve style
(solid black thick line), e.g. {cmd:curveopts(lcolor(maroon) lwidth(medthick))}.

{phang}
{cmd:pointopts(}{it:scatter_options}{cmd:)} overrides the default study point
style, e.g. {cmd:pointopts(mcolor(navy) msymbol(circle_hollow))}.

{hline}

{title:Returned results}

{p2colset 9 22 24 2}
{p2col:{cmd:r(AUC)}}area under the SROC curve{p_end}
{p2col:{cmd:r(AUClo)}}lower confidence bound for AUC{p_end}
{p2col:{cmd:r(AUChi)}}upper confidence bound for AUC{p_end}
{p2colreset}{...}

{hline}

{title:Examples}

{pstd}SROC curve with prediction region and study points:{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(author)}{p_end}
{phang2}{cmd:. midas rgsroc, data pregion weighted}{p_end}

{pstd}Custom curve and point colors:{p_end}
{phang2}{cmd:. midas rgsroc, data cbounds curveopts(lcolor(maroon) lwidth(medthick)) pointopts(mcolor(navy))}{p_end}

{hline}

{title:References}

{phang}
Rutter CM, Gatsonis CA. A hierarchical regression approach to meta-analysis
of diagnostic test accuracy evaluations. {it:Statistics in Medicine}
2001;{bf:20}:2865–2884.
{browse "https://doi.org/10.1002/sim.942"}
{p_end}

{phang}
Harbord RM, Deeks JJ, Egger M, Whiting P, Sterne JAC. A unification of models
for meta-analysis of diagnostic accuracy studies. {it:Biostatistics}
2007;{bf:8}:239–251.
{browse "https://doi.org/10.1093/biostatistics/kxl004"}
{p_end}

{hline}

{title:Also see}

{psee}
{helpb midas}, {helpb midas bvsroc}, {helpb midas forest}
