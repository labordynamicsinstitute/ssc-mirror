{smcl}
{* *! version 1.0}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "help merlin" "help merlin"}{...}
{vieweralsosee "help predictms" "help predictms"}{...}
{viewerjumpto "Syntax" "exptorcs##syntax"}{...}
{viewerjumpto "Description" "exptorcs##description"}{...}
{viewerjumpto "Options" "exptorcs##options"}{...}
{viewerjumpto "Remarks" "exptorcs##remarks"}{...}
{viewerjumpto "Examples" "exptorcs##examples"}{...}
{title:Title}

{phang}
{bf:exptorcs} {hline 2} a command to turn expected incidence/mortality rates into a spline-based 
multiple-timescale {cmd:merlin} model object

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:exptorcs}
[{varlist}]
{cmd:,}
{it:options}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt expdata(dataset)}} name of Stata dataset which contains the expected rates{p_end}
{synopt:{opt event(varname)}} event indicator variable in {cmd:expdata()} file for Poisson model{p_end}
{synopt:{opt exp:osure(varname)}} exposure time variable in {cmd:expdata()} file for Poisson model{p_end}
{synopt:{cmd: year({varname}, {it:{help exptorcs##spline_opts:spline_options}})}} restricted cubic spline model specification for calendar year; see details{p_end}
{synopt:{cmd: age({varname}, {it:{help exptorcs##spline_opts:spline_options}})}} restricted cubic spline model specification for attained age; see details{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{synoptset 30 tabbed}{...}
{marker spline_opts}{...}
{synopthdr:spline_options}
{synoptline}
{synopt:{opt knots(string)}} specify the knot locations (including boundary knots){p_end}
{synopt:{opt log}} create splines of log(varname){p_end}
{synopt:{opt noorthog}} suppress default orthogonalisation of spline variables{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}
{cmd:exptorcs} turns an expected incidence or mortality rate into a restricted cubic spline-based survival model, 
i.e. a smooth parametric model for the rate, dependent on multiple timescales. It requires an incidence file which 
contains the number of events and the total exposure time, stratified by appropriate variables such as age, 
calendar year and sex. It first turns the rates into a Poisson based model, before transforming into a spline-based 
survival model on the log hazard scale, using {helpb merlin}. Once it is turned into a {helpb merlin} model, it can 
then be used as a transition model within a multi-state survival setting, using {helpb predictms}. See 
Weibull et al. (Submitted) for further details. 

{phang}
{cmd:exptorcs} is part of the {helpb merlin} family. Further 
details here: {bf:{browse "https://www.mjcrowther.co.uk/software/merlin":mjcrowther.co.uk/software/merlin}}
{p_end}

 
{marker options}{...}
{title:Options}

{dlgtab:options}

{phang}
{opt expdata(dataset)} specifies the name of Stata dataset which contains the expected rates to be turned into a spline based model using {helpb merlin}.
{p_end}

{phang}
{opt event(varname)} specifies the event indicator variable, which must be in {cmd:expdata()}.
{p_end}

{phang}
{opt exposure(varname)} specifies the exposure time variable, which must be in {cmd:expdata()}.
{p_end}

{phang}
{cmd: year({varname}, {it:{help exptorcs##spline_opts:spline_options}})} specifies the restricted cubic spline model 
for calendar year as a timescale. {varname} must be in the current dataset.
{p_end}

{phang}
{cmd: age({varname}, {it:{help exptorcs##spline_opts:spline_options}})} specifies the restricted cubic spline model 
for attained age as a timescale. {varname} must be in the current dataset.
{p_end}

{dlgtab:spline_options}

{phang}
The {cmd:year()} and {cmd:age()} options specify the restricted cubic spline expansion of the appropriate {it:varname}, with options: 
{p_end}

{phang2}
{cmd:knots(numlist)} specifies the knot locations, which includes the boundary knots. Must be in ascending order.
{p_end}

{phang2}
{cmd:log} use splines of log {it:varname} rather than {it:varname}, the default.
{p_end}

{phang2}
{cmd:noorthog} suppress the default orthogonalisation of the spline variables.
{p_end}


{marker examples}{...}
{title:Examples}
{pstd}

{phang}
{cmd:exptorcs sex, expdata(popinc) event(_d) exposure(_t) ///}
{p_end}
{phang2}
{cmd:year(_year, knots(1980 1990 2000)) ///}
{p_end}
{phang2}
{cmd:age(_age, knots(25 50 75 85) log)}
{p_end}


{title:Authors}
{p}

{p 5 12 2}
{bf:Michael J. Crowther}{p_end}
{p 5 12 2}
Biostatistics Research Group{p_end}
{p 5 12 2}
Department of Health Sciences{p_end}
{p 5 12 2}
University of Leicester{p_end}
{p 5 12 2}
michael.crowther@le.ac.uk{p_end}

{p 5 12 2}
{bf:Caroline E. Weibull}{p_end}
{p 5 12 2}
Department of Medicine{p_end}
{p 5 12 2}
Karolinska Institutet{p_end}


{title:References}
{pstd}

{phang}
Crowther MJ. Extended multivariate generalised linear and non-linear mixed effects models. 
{browse "https://arxiv.org/abs/1710.02223":https://arxiv.org/abs/1710.02223}
{p_end}

{phang}
Crowther MJ. merlin - a unified framework for data analysis and methods development in Stata. 
{browse "https://arxiv.org/abs/1806.01615":https://arxiv.org/abs/1806.01615}
{p_end}

{phang}
Weibull CE, Lambert PC, Eloranta S, Andersson TM-L, Dickman PW, Crowther MJ. A multi-state model incorporating 
estimation of excess hazards and multiple time scales. (Submitted).
{p_end}
