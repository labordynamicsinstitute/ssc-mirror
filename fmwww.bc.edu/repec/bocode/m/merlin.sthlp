{smcl}
{* *! version 1.0.0}{...}
{vieweralsosee "merlin model description options" "help merlin_models"}{...}
{vieweralsosee "merlin estimation options" "help merlin_estimation"}{...}
{vieweralsosee "merlin reporting options" "help merlin_reporting"}{...}
{vieweralsosee "merlin postestimation" "help merlin_postestimation"}{...}
{vieweralsosee "stmerlin" "help stmerlin"}{...}
{vieweralsosee "multistate" "help multistate"}{...}
{vieweralsosee "stmixed" "help stmixed"}{...}
{vieweralsosee "survsim" "help survsim"}{...}
{vieweralsosee "exptorcs" "help exptorcs"}{...}
{viewerjumpto "Syntax" "merlin##syntax"}{...}
{viewerjumpto "Description" "merlin##description"}{...}
{viewerjumpto "Options" "merlin##options"}{...}
{viewerjumpto "Examples" "merlin##examples"}{...}
{viewerjumpto "Stored results" "merlin##results"}{...}
{title:Title}

{p2colset 5 15 19 2}{...}
{p2col:{bf:merlin} {hline 2}}Mixed effects regression for linear, non-linear and user-defined models{p_end}
{p2colreset}{...}

{p 4 6 2}
See {bf:{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X20976311":merlin - a unified framework for data analysis and methods development in Stata}}, 
for an introduction.


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:merlin} {help merlin_models:{it:models}} {ifin}
[{cmd:,} {it:options}]

{pstd}
where
{it:models} are the model specifications; see {helpb merlin_models:merlin models}.{p_end}

{synoptset 30}{...}
{synopthdr:options}
{synoptline}
{synopt :{help merlin_model_options:{it:model_description_options}}}fully
define, along with {it:models}, the model to be fit{p_end}

{synopt :{help merlin_estimation:{it:estimation_options}}}method
used to obtain estimation results, including specifying initial values{p_end}

{synopt :{help merlin_reporting:{it:reporting_options}}}reporting
of estimation results{p_end}
{synoptline}
{p 4 6 2}
Also see {helpb merlin_postestimation:merlin postestimation} for features
available after estimation.
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:merlin} fits an extremely broad class of mixed effects regression models for linear, 
non-linear and user-defined outcomes {browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X20976311":(Crowther, 2020)}. 

{pstd}
{cmd:merlin} can fit multivariate outcome models of any type, each of which could be repeatedly measured 
(longitudinal), with any number of levels, and with any number of random effects at each level. 
Standard distributions/models available include the Bernoulli, beta, gamma, Gaussian, linear quantile, 
negative binomial, ordinal, Poisson, and time-to-event/survival models include the exponential, Gompertz, 
log-logistic, log normal, piecewise-exponential, generalised gamma, Weibull, Royston-Parmar, general log 
hazard and general log cumulative hazard models. Interval censoring and left truncation are supported for 
all survival models. {cmd:merlin} provides a flexible predictor syntax, allowing the user to define variables, 
random effects, spline and fractional polynomial functions, functions of other outcome models, and any 
interaction between each of them. Non-linear and time-dependent effects are seamlessly incorporated into the 
predictor. {cmd:merlin} allows level-specific random effect distributions, either multivariate normal or t, 
which are integrated out using either Gaussian quadrature or Monte-Carlo integration. 

{pstd}
{ul:{bf:Family members}}

{pstd}
There are a number of associated commands, which utilise or build on the power of {cmd:merlin}, including:

{phang2}
{helpb stmerlin} for standard survival analysis. This is a wrapper function to fit a range of parametric survival 
models and the Cox model, but with the standard syntax of any {helpb st:[ST] st} regression model command. 
{helpb stmerlin} is currently included as part of the {cmd: merlin} package.

{phang2}
{helpb stmixed} for multilevel mixed effects survival analysis. This is a wrapper function to fit a 
range of parametric survival models with random effects, but with a much more accessible (simpler!) 
syntax than {cmd:merlin}, and is consistent with {helpb mestreg}. {cmd:stmixed} is currently available as a separate 
package on SSC.

{phang2}
{helpb predictms} for predictions from a general multi-state model. Given a defined transition matrix, each 
transition model can be fitted as a {cmd:merlin} model, and then the model objects can be passed to 
{cmd:predictms} to calculate a huge range of useful predictions. {cmd:predictms} is currently part of the 
{helpb multistate} package, available on SSC.

{phang2}
{helpb survsim} allows you to simulate survival times from a fitted {cmd:merlin} survival model. {cmd:survsim} 
is currently available from the SSC archive.

{phang2}
{helpb exptorcs} turns an expected incidence or mortality rate, recorded in age- and calendar-time specific event 
counts and exposure time, into a restricted cubic spline-based survival model, i.e. a smooth parametric model for 
the rate, dependent on multiple timescales (Weibull et al. (2021)). {cmd:exptorcs} is currently bundled with the 
{cmd:merlin} package.

{pstd}
There are many more on the way.

{pstd}
{ul:{bf:Tutorials}}

{pstd}
For full details and many tutorials, take a look at 
{bf:{browse "https://www.mjcrowther.co.uk/software/merlin":merlin's homepage}}.


{marker options}{...}
{title:Options}

{phang}
{it:model_description_options}
describe the model to be fit.  The model to be fit is fully specified by
{it:models} -- which appear immediately after {cmd:merlin} -- and the option 
{opt covariance()}.  See {helpb merlin_model_options:merlin model description options} and 
{helpb merlin_models:merlin model notation}.

{phang}
{it:estimation_options}
control how the estimation results are obtained.  These options control how
the standard errors (VCE) are obtained and control technical issues
such as choice of estimation method.  See 
{helpb merlin_estimation:merlin estimation options}.

{phang}
{it:reporting_options}
control how the results of estimation are displayed.  See 
{helpb merlin_reporting:merlin reporting options}.


{marker examples}{...}
{title:Examples}

{phang}
These examples are intended for quick reference.  For detailed examples, see the 
{bf:{browse "https://www.mjcrowther.co.uk/software/merlin/tutorials_stata":merlin tutorial homepage}}.

{phang}
{ul:{bf:Example 1: Linear regression}}
{p_end}

{phang2}Setup{p_end}
{phang3}{cmd:. sysuse auto}{p_end}

{phang2}Use {cmd:regress} command{p_end}
{phang3}{cmd:. regress mpg weight foreign}{p_end}

{phang2}Replicate model with {cmd:merlin}{p_end}
{phang3}{cmd:. merlin (mpg weight foreign, family(gaussian))}{p_end}

{phang}
{ul:{bf:Example 2: Logistic regression}}
{p_end}

{phang2}Setup{p_end}
{phang3}{cmd:. webuse gsem_lbw}{p_end}

{phang2}Use {cmd:logit} command{p_end}
{phang3}{cmd:. logit low age lwt smoke ptl ht ui}{p_end}

{phang2}Replicate model with {cmd:merlin}{p_end}
{phang3}{cmd:. merlin (low age lwt smoke ptl ht ui, family(bernoulli))}{p_end}

{phang}
{ul:{bf:Example 3: Linear model with random intercept and slope}}
{p_end}

{phang2}Setup{p_end}
{phang3}{cmd:. use http://fmwww.bc.edu/repec/bocode/s/stjm_pbc_example_data, clear}{p_end}

{phang2}Use {cmd:mixed} command{p_end}
{phang3}{cmd:. mixed logb time age trt || id: time}{p_end}

{phang2}Replicate model with {cmd:merlin}{p_end}
{phang3}{cmd:. merlin (logb time age trt time#M1[id]@1 M2[id]@1, family(gaussian))}{p_end}


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
