{smcl}
{* *! version 1.0.0  04jul2018}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "cdfquantreg01##syntax"}{...}
{viewerjumpto "Description" "cdfquantreg01##description"}{...}
{viewerjumpto "Distribution Names" "cdfquantreg01##options"}{...}
{viewerjumpto "Examples" "cdfquantreg01##examples"}{...}
{viewerjumpto "Author" "cdfquantreg01##examples"}{...}
{viewerjumpto "References" "cdfquantreg01##references"}{...}
{title:Title}

{phang}
{bf:cdfquantreg} {hline 2} General linear models using finite-tailed cdf-quantile distributions for variables on the closed unit interval

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cdfquantreg01}
{it:varlist} 
{cmd:,cdf(}
{it:distribution1} 
{cmd:)}
{cmd:quantile(}
{it:distribution2} 
{cmd:)}
{cmd:[pos(}
{it:position}
{cmd:)]}
{cmd:[func(}
{it:function}
{cmd:)]}
{cmd:[twothree(}
{it:num_parameters}
{cmd:)]}
{cmd:[zvarlist(}
{it:varlist_z}
{cmd:)]}
{cmd:[wvarlist(}
{it:varlist_w}
{cmd:)]}
{cmd:[nolog]}

{marker description}{...}
{title:Description}

{pstd}
{cmd:cdfquantreg01} invokes maximum likelhood estimation using {help ml} with 
a linear form.  A general linear model is estimated for a dependent variable 
on the unit [0,1] interval, using a member of the finite-tailed cdf-quantile distributon family.

{pstd}
{it:varlist} must include at least the dependent variable, and also may include the 
predictor variables for the location submodel.  {cmd:zvarlist} is a non-required 
option presenting the predictor variables for the dispersion submodel in 
a 2-parameter distribution model, and for the skew-parameter submodel in a 
3-parameter distribution model. {cmd:wvarlist} is a non-required option 
presenting the predictor variables for the dispersion submodel in a 
3-parameter distribution model. 

{pstd}
The {cmd:cdf} and {cmd:quantile} options are required, and they specify the 
cdf-quantile distribution to be used in the model. Likewise, {it:distribution1} 
and {it:distribution2} are names chosen from the {ul:Distributions} list below.

{pstd}
The {cmd:pos} option is required, and specifies the inner versus outer 
position type of distribution via the {it:position} name which is either "inner" or "outer".

{pstd}
The {cmd:func} option is required, and specifies the W versus V 
type of skew function via the {it:function} name which is either "w" or "v".

{pstd}
The {cmd:twothree} option is required, and specifies the two- versus three-parameter 
distributions via the {it:num_parameters} number which is either "2" or "3".

{pstd}
Also available are {cmd:cdfquantreg01_p} and {cmd:cdfquantreg01_mf}, 
postestimation commands.   
{cmd:cdfquantreg01_p} uses the specified cdf-quantile distribution to generate 
the model's parameter estimates and fitted values. See the help file 
for {cmd:cdfquantreg_p}.
{cmd:cdfquantreg01_mf} uses the specified cdf-quantile distribution to generate 
estimates of marginal effects of each predictor in the model. See the help file 
for {cmd:cdfquantreg01_mf}.

{marker options}{...}
{title:Distribution Names}

{phang}
{opt asinh} invokes the arcsinh distribution.

{phang}
{opt cauchit, cauchy} invokes the Cauchy distribution.

{phang}
{opt t2} invokes the t distribution with 2 degrees of freedom.

{phang}
{opt asinh-asinh, asinh-cauchy, cauchit-asinh, cauchit-cauchy, t2-t2} are 
the permissible cdf-quantile distributions.

{marker examples}{...}
{title:Example 1}

{phang}{cmd:/* This example uses YoonData2.dta */}{p_end}

{phang}{cmd:. generate loglosh = ln(losh)}{p_end}

{phang}{cmd:. cdfquantreg01 pregptriage i.ambulance , cdf(cauchit) quantile(asinh) pos(outer) func(w) twothree(2) zvarlist(i.ambulance)}{p_end}

{phang}{cmd:. estimates store A}{p_end}

{phang}{cmd:. cdfquantreg01 pregptriage i.ambulance loglosh , cdf(cauchit) quantile(asinh) pos(outer) func(w) twothree(2) zvarlist(i.ambulance loglosh)}{p_end}

{phang}{cmd:. estimates store B}{p_end}

{phang}{cmd:. lrtest A B}{p_end}

{title:Example 2}

{phang}{cmd:/* This example uses YoonData2.dta */}{p_end}

{phang}{cmd:. generate loglosh = ln(losh)}{p_end}

{phang}{cmd:. cdfquantreg01 pregptriage i.ambulance loglosh , cdf(cauchit) quantile(asinh) pos(outer) func(w) twothree(3) zvarlist(i.ambulance loglosh) wvarlist(i.ambulance loglosh)}{p_end}

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

