{smcl}
{* version 2.00  24mar2026}{...}
{cmd:help midas qrsim}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas qrsim} {hline 2} Maximum simulated likelihood with quasi-random sequences

{title:Syntax}

{p 8 18 2}
{cmd:midas qrsim}
{it:tp fp fn tn}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:id(}{it:varlist}{cmd:)}
{cmd:simulation(}{it:method}{cmd:)}
[{cmd:burn(}{it:#}{cmd:)}
{cmd:draws(}{it:#}{cmd:)}
{cmd:level(}{it:#}{cmd:)}
{cmd:noheader}
{cmd:notable}
{cmd:nohsroc}
{cmd:nofitstats}
{cmd:nohetstats}
{cmd:revman}]

{title:Description}

{pstd}
{cmd:midas qrsim} fits the bivariate random-effects model for diagnostic
test accuracy meta-analysis using maximum simulated likelihood (MSL) with
quasi-random Monte Carlo integration sequences.

{title:Options}

{phang}
{cmd:id(}{it:varlist}{cmd:)} study identifier variable(s). Required.

{phang}
{cmd:simulation(}{it:method}{cmd:)} simulation sequence type. Required. One of:
{cmd:halton}, {cmd:hrandom}, {cmd:shuffle}, or {cmd:random}.

{phang}
{cmd:burn(}{it:#}{cmd:)} burn-in draws to discard. Default 50.

{phang}
{cmd:draws(}{it:#}{cmd:)} number of simulation draws. Default 50.

{phang}
{cmd:level(}{it:#}{cmd:)} confidence level. Default 95.

{title:Example}

{phang2}{cmd:. midas qrsim tp fp fn tn, id(author) simulation(halton)}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas mle}, {helpb midas mh}
