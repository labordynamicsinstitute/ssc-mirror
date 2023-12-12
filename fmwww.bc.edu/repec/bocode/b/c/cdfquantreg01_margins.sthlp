{smcl}
{* *! version 1.0.0  14jul2018}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerdialog "predict for cdfquantreg01" "dialog cdfquantreg_m"}{...}
{viewerjumpto "Syntax for cdfquantreg01_mf" "cdfquantreg01_mf##syntax_cdfquantreg01_mf"}{...}
{viewerjumpto "Options for cdfquantreg01_mf" "cdfquantreg01_mf##options_cdfquantreg01_mf"}{...}
{viewerjumpto "Examples" "examples_cdfquantreg01_mf##examples"}{...}
{viewerjumpto "Author" "cdfquantreg01##author"}{...}
{viewerjumpto "References" "cdfquantreg01##references"}{...}
{title:Title}

{phang}
{bf:cdfquantreg_m} {hline 2} Marginal effects conversion for cdfquantreg

{marker description}{...}
{title:Description}

{pstd}
The following alternative to the {cmd :{helpb cdfquantreg postestimation##margins:margins}} command 
is available after {cmd:cdfquantreg01}: {cmd:cdfquantreg01_mf}.  This command reports 
marginal effects for the location and dispersion parameters (and skew parameter if fitting a 3-parameter distribution), and converts these to 
effects on the quantile specified by the user. The default is the median (the 0.5 quantile).

{marker syntax_cdfquantreg01_mf}{...}
{marker cdfquantreg01_mf}{...}
{title:Syntax for cdfquantreg01_mf}

{cmd:cdfquantreg01_mf} {varlist} [{cmd:,}{opt pctle(real #)}]]

{marker options_cdfquantreg01_mf}{...}
{title:Options for cdfquantreg01_mf}

{dlgtab:Main}

{phang}{opt pctle(#)} specifies the quantile that {cmd:cdfquantreg01_mf} is to estimate. It expects a number in the 
(0,1) interval.  To estimate the 75th percentile, for instance, # would be set to 0.75. 
The default is 0.5.

{marker examples_cdfquantreg01_mf}{...}
{title:Examples}

{phang}{cmd:/* This example uses YoonnData2.dta */}{p_end}

{phang}{cmd:. generate loglosh = ln(losh)}{p_end}

{phang}{cmd:. cdfquantreg01 pregptriage i.ambulance loglosh , cdf(cauchit) quantile(asinh) pos(outer) func(w) twothree(2) zvarlist(i.ambulance loglosh)}{p_end}

{phang}{cmd:. cdfquantreg01_mf ambulance, pctle(0.5)}{p_end}

{marker author}{...}
{title:Author}

{pstd}
Michael Smithson, Research School of Psychology, The Australian National University, 
Canberra, A.C.T. Australia{break}Michael.Smithson@anu.edu.au

{marker references}{...}
{title:References}

{p 4 4 2}
Smithson, M. & Shou, Y. (accepted 18/11/22). Flexible cdf-quantile distributions on the closed unit interval, with software and applications.  {it:Communications in Statistics – Theory and Methods}. 

{p 4 4 2}
Smithson, M. & Shou, Y. (2017). CDF-quantile distributions for modeling random 
variables on the unit interval. {it:British Journal of Mathematical and Statistical Psychology}, 70(3), 412-438.

{p 4 4 2}
Shou, Y. & Smithson, M. (2019). cdfquantreg: An R package for 
CDF-Quantile Regression. {it:Journal of Statistical Software}, 88, 1-30. 
