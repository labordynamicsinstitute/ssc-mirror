{smcl}
{* Version 1.0, January 5, 2022}{...}
{hline}
help for {hi:esteta}
{hline}

{title:Estimation of long-run effects using historical instruments}

{p 4}Full syntax

{p 8 14}{cmd:esteta} {it:y} {it:x2} {it:x1}
[{cmd:if} {it:exp}]
{cmd:instruments(}{it:varlist}{cmd:)}
{cmd:t_y(}{it:real}{cmd:)}
{cmd:t_x2(}{it:real}{cmd:)}
{cmd:t_x1(}{it:real}{cmd:)}
{cmd:t_eta(}{it:real}{cmd:)}
{bind:[{cmd:,} {cmd:controls(}{it:varlist}{cmd:)}]}

{p}All {it:varlists} may contain time-series operators or factor variables; see help {help varlist}.

{p}{cmd:esteta} is compatible with Stata version 10 or later.

{p}Note: {opt esteta} requires {opt ivreg2} which requires {opt ranktest}.

{marker s_description}{title:Description}

{p}{cmd:esteta} estimates the long-run effect of an endogenous contemporary factor instrumented by a historical instrument. The estimator requires two variables representing the endogenous factor measured at two different points in time. It uses these two variables to estimate and adjust for the persistency of the endogenous contemporary factor in the estimation of the long-run effect. {it:y} is the dependent variable. {it:x2} is a variable measuring the endogenous contemporary factor at some time period. {it:x1} is a variable measuring the endogenous contemporary factor at some earlier time period. The required settings (see below) specifies the time periods for these variables as well as for the dependent variable and the time period of impact of the historical instrument.

{synoptset 27 tabbed}{...}
{synopthdr:required settings}
{synoptline}
{synopt:{opth instruments(varlist)}}List of excluded historical instruments.{p_end}
{synopt:{opth t_y(varlist)}}Time period (e.g., calendar year) of the dependent variable, {it:y}.{p_end}
{synopt:{opth t_x2(varlist)}}Time period (e.g., calendar year) of the later measure of the endogenous contemporary factor, {it:x2}.{p_end}
{synopt:{opth t_x1(varlist)}}Time period (e.g., calendar year) of the earlier measure of the endogenous contemporary factor, {it:x1}.{p_end}
{synopt:{opth t_eta(varlist)}}Time period (e.g., calendar year) of the impact of the historical instrument.{p_end}

{synoptset 27 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opth controls(varlist)}}List of control variables{p_end}

{marker s_examples}{title:Examples}

{pstd} Estimate the long-run effect of institutions, as instrumented by settler mortality (with assumed impact on institutions in year 1800), on GDP in year 2022, using measurements of institutions in year 1960 and 1900.{p_end}
{phang2}{cmd:. esteta gdp_year_2022 institutions_1960 institutions_1900, t_y(2022) t_x2(1960) t_x1(1900) t_eta(1800) instruments(settler_mortality) controls(absolute_latitude)} {p_end}

{marker s_refs}{title:Reference}

{p 0 4}Casey, Gregory and Marc Klemp. "Historical instruments and contemporary endogenous regressors." Journal of Development Economics, volume 149, 2021, 102586. {browse "https://doi.org/10.1016/j.jdeveco.2020.102586":https://doi.org/10.1016/j.jdeveco.2020.102586}. ({browse "https://www.sciencedirect.com/science/article/pii/S0304387820301619":https://www.sciencedirect.com/science/article/pii/S0304387820301619}.)

{marker s_citation}{title:Citation of esteta}

{p}Please cite {cmd:esteta} using the above reference.{p_end}

{title:Authors}

    Gregory Casey
    Williams College, USA
    gregory.p.casey@williams.edu

    Marc Klemp (corresponding author)
    University of Copenhagen, Denmark
    marc.klemp@econ.ku.dk
