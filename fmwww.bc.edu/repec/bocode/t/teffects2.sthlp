{smcl}
{* 12sep2025}{...}
{vieweralsosee "teffects2 ipw" "help teffects2 ipw"}{...}
{vieweralsosee "teffects2 aipw" "help teffects2 aipw"}{...}
{vieweralsosee "teffects2 ipwra" "help teffects2 ipwra"}{...}
{hline}
help for {hi:teffects2}
{hline}

{title:Title}

{phang}
{bf:teffects2} {hline 2} Estimating average treatment effects with observational data{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:teffects2} {it:subcommand} ... [{cmd:,} {it:options}]

{synoptset 16}{...}
{synopthdr:subcommand}
{synoptline}
{synopt :{helpb teffects2 aipw:aipw}}augmented inverse probability weighting{p_end}
{synopt :{helpb teffects2 ipw:ipw}}inverse probability weighting{p_end}
{synopt :{helpb teffects2 ipwra:ipwra}}inverse probability weighted regression adjustment{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:teffects2} estimates average treatment effects (ATEs) and average treatment effects
on the treated (ATTs) using observational data.  As in Stata's official {cmd:teffects}
command, inverse probability weighting (IPW), augmented inverse probability weighting (AIPW),
and inverse probability weighted regression adjustment (IPWRA) estimators are supported.
However, unlike {cmd:teffects}, {cmd:teffects2} supports covariate balancing estimation
of the propensity score.
{p_end}
