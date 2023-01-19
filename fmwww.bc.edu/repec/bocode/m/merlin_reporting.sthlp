{smcl}
{* *! version 1.0.0 05nov2017}{...}
{vieweralsosee "merlin model description options" "help merlin_models"}{...}
{vieweralsosee "merlin estimation options" "help merlin_estimation"}{...}
{vieweralsosee "merlin reporting options" "help merlin_reporting"}{...}
{vieweralsosee "merlin postestimation" "help merlin_postestimation"}{...}
{title:Title}

{p2colset 5 35 37 2}{...}
{p2col:{help merlin_reporting:{bf:merlin reporting options}} {hline 2}}Options affecting
reporting of results{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:merlin} {help merlin models:{it:models}} ...{cmd:,} ...
     {it:reporting_options}

{p 8 12 2}
{cmd:merlin,} {it:reporting_options}


{synoptset 19}{...}
{synopthdr:reporting_options}
{synoptline}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt coefl:egend}}display coefficient legend{p_end}
{synopt :{opt nocnsr:eport}}do not display constraints{p_end}
{synopt :{opt nohead:er}}do not display header above parameter table{p_end}
{synopt :{opt notable}}do not display parameter tables{p_end}
{synopt :{opt eform}}display exponenitated coefficients{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
These options control how {cmd:merlin} displays estimation results.


{marker options}{...}
{title:Options}

{phang}
{opt level(#)}; see {manlink R estimation options}.

{phang}
{opt coeflegend} displays the legend that reveals how to specify estimated
coefficients in {opt _b[]} notation, which you are sometimes required to
type in specifying postestimation commands.

{phang}
{opt nocnsreport} suppresses the display of the constraints.

{phang}
{opt noheader} suppresses the header above the parameter table, the display
that reports the final log-likelihood value, number of observations, etc.

{phang}
{opt notable} suppresses the parameter table.

{phang}
{opt eform} display exponentiated coefficients for the main linear predictor


{marker remarks}{...}
{title:Remarks}

{pstd}
Any of the above options may be specified when you fit the model or when you
redisplay results, which you do by specifying nothing but options after the
{cmd:merlin} command:

{phang2}{cmd:. merlin (...) (...), ...}{p_end}
{phang2}{it:(original output displayed)}

{phang2}{cmd:. merlin}{p_end}
{phang2}{it:(output redisplayed)}

{phang2}{cmd:. merlin, coeflegend}{p_end}
{phang2}{it:(coefficient-name table displayed)}

{phang2}{cmd:. merlin}{p_end}
{phang2}{it:(output redisplayed)}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/s/stjm_pbc_example_data, clear}{p_end}
{phang2}{cmd:. merlin (logb time age trt time#M1[id]@1 M2[id]@1, family(gaussian))}{p_end}

{pstd}Display coefficient legend{p_end}
{phang2}{cmd:. merlin, coeflegend}{p_end}

{pstd}Obtain 90 percent confidence intervals{p_end}
{phang2}{cmd:. merlin, level(90)}{p_end}


{title:Author}

{p 5 12 2}
{bf:Michael J. Crowther}{p_end}
{p 5 12 2}
Red Door Analytics{p_end}
{p 5 12 2}
Stockholm, Sweden{p_end}
{p 5 12 2}
michael@reddooranalytics.se{p_end}


{title:References}

{phang}
{bf:Crowther MJ}. Extended multivariate generalised linear and non-linear mixed effects models. 
{browse "https://arxiv.org/abs/1710.02223":https://arxiv.org/abs/1710.02223}
{p_end}

{phang}
{bf:Crowther MJ}. merlin - a unified framework for data analysis and methods development in Stata. {browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X20976311":{it:Stata Journal} 2020;20(4):763-784}.
{p_end}

{phang}
{bf:Crowther MJ}. Multilevel mixed effects parametric survival analysis: Estimation, simulation and application. {browse "https://journals.sagepub.com/doi/abs/10.1177/1536867X19893639?journalCode=stja":{it:Stata Journal} 2019;19(4):931-949}.
{p_end}

{phang}
{bf:Crowther MJ}, Lambert PC. Parametric multi-state survival models: flexible modelling allowing transition-specific distributions with 
application to estimating clinically useful measures of effect differences. {browse "https://onlinelibrary.wiley.com/doi/full/10.1002/sim.7448":{it: Statistics in Medicine} 2017;36(29):4719-4742.}
{p_end}

{phang}
Weibull CE, Lambert PC, Eloranta S, Andersson TM-L, Dickman PW, {bf:Crowther MJ}. A multi-state model incorporating 
estimation of excess hazards and multiple time scales. {browse "https://onlinelibrary.wiley.com/doi/10.1002/sim.8894":{it:Statistics in Medicine} 2021; (In Press)}.
{pstd}
