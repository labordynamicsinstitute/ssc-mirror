{smcl}
{* *! version 2.0.0 31oct2012}{...}
{hline}
{cmd:help survsim}{right: }
{hline}

{title:Title}

{p2colset 5 16 20 2}{...}
{p2col :{cmd:survsim} {hline 2}}Simulate complex survival data{p_end}
{p2colreset}{...}


{title:Syntax}

{phang2}
{cmd: survsim} {it:newvarname1} [{it:newvarname2}] [{cmd:,} {it:options}]


{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt l:ambdas(numlist)}}scale parameters{p_end}
{synopt:{opt g:ammas(numlist)}}shape parameters{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:e:xponential)}}exponential survival distribution{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:gom:pertz)}}Gompertz survival distribution{p_end}
{synopt:{cmdab:d:istribution(}{cmdab:w:eibull)}}Weibull survival distribution (default){p_end}
{synopt:{opt maxt:ime(#)}}administrative censoring time{p_end}
{synopt:{opt cov:ariates(vn # [# ...] ...)}}baseline covariates{p_end}
{synopt:{opt tde(vn # [# ...] ...)}}time-dependent effects{p_end}
{synopt:{opt centol(real)}}set the tolerance for the root finding scheme, default is 1E-08{p_end}

{syntab:2-component mixture}
{synopt:{opt mix:ture}}simulate survival times from a 2-component mixture model{p_end}
{synopt:{opt pm:ix(real)}}mixture parameter, default is 0.5{p_end}

{syntab:Competing risks}
{synopt:{opt cr}}simulate survival times from the all-cause distribution of cause-specific hazards{p_end}
{synopt:{opt ncr(int)}}specifies the number of competing risks{p_end}
{synopt:{opt show:diff}}display the maximum difference in estimates between iterations under the Newton-Raphson scheme{p_end}

{syntab:User-defined [log] [cumulative] hazard function}
{synopt:{opt logh:azard(string)}}user-defined log baseline hazard function, see details{p_end}
{synopt:{opt h:azard(string)}}user-defined baseline hazard function, see details{p_end}
{synopt:{opt logcumh:azard(string)}}user-defined log cumulative baseline hazard function, see details{p_end}
{synopt:{opt cumh:azard(string)}}user-defined baseline cumulative hazard function, see details{p_end}
{synopt:{opt nodes(#)}}number of Gauss-Legendre quadrature nodes, default 30{p_end}
{synopt:{opt tdefunc:tion(string)}}function of time to interact with covariates specified in {bf:tde(), see details}{p_end}
{synopt:{opt it:erations(#)}}maximum number of iterations to pass to Mata function {bf:mm_root()}{p_end}
{synopt:{opt mint:ime(#)}}minimum time for use in root finding, default 1E-08{p_end}
{synoptline}
{syntab:Abbreviation: {it:vn = varname}}
{p2colreset}{...}


{title:Description}

{pstd}{cmd:survsim} simulates survival times from parametric distributions and user-defined hazard functions. Distributions include the exponential, 
Gompertz and Weibull. Newton-Raphson iterations are used to generate survival times under cause-specific hazard models for competing risks, using 
standard parametric distributions. Non-proportional hazards can be included with all models; under an exponential or Weibull model covariates are interacted with log time, under a Gompertz 
model covariates are interacted with time. Baseline covariates can be included. {it:newvarname1} specifies the new variable name to contain the 
generated survival times. {it:newvarname2} is required when generating competing risks data to create the status indicator or when the maxtime() option 
is specified which defines the time of administrative censoring. Finally, a user-defined [log] [cumulative] baseline hazard function can be specified, in Mata code 
using colon operators, with survival times generated using a combination of Gaussian quadrature and root finding techniques. Complex time-dependent effects can 
also be specified.{p_end}


{title:Options}

{phang}{opt lambdas(numlist)} defines the scale parameters in the Weibull/Gompertz distribution(s). The number of values required depends on the model choice. 
Default is a single number corresponding to a standard parametric distribution. Under a {cmd:mixture} model 2 values are required. Under a 
competing risks model, {cmd:cr}, the number of values are defined by {cmd:ncr()}.{p_end}

{phang}{opt gammas(numlist)} defines the shape parameters of the parametric distribution(s). Number of entries must be equal to that of {cmd:lambdas}.{p_end}

{phang}{opt distribution}({it:string}) specifies the parametric survival distrubution to use. {cmd:exponential}, {cmd:gompertz} or {cmd:weibull} can be used, with {cmd:weibull}
the default.{p_end}

{phang}{opt maxtime(#)} specifies an administrative censoring time. Two new varnames syntax must be specified, the second to contain the event indicator.{p_end}

{phang}{opt covariates(varname # [# ...] ...)} defines baseline covariates to be included in the linear predictor of the survival model, along with the value of the 
corresponding coefficient. For example a treatent variable coded 0/1 can be included, with a log hazard ratio of 0.5, by {cmd:covariates}(treat 0.5). 
Variable treat must be in the dataset before {cmd:survsim} is run. If {cmd:cr} is used with {cmd:ncr(4)}, then a value for each coefficient must be 
inputted for each competing risk, e.g. {cmd:covariates}(treat 0.5 -0.2 0.1 0.25). If {cmd:cumhazard()} or {cmd:logcumhazard()} are used, then {cmd:covariates()} effects are additive on the 
log cumulative hazard scale.{p_end}

{phang}{opt tde(varname # [# ...] ...)} creates non-proportional hazards by interacting covariates with either log time or time under a Weibull or Gompertz model, respectively. 
Under a user-defined [log] [cumulative] hazard function, covariates are interacted with {cmd:tdefunction()}. Values should be entered as {cmd:tde}(trt 0.5), for example. 
If {cmd:cumhazard()} or {cmd:logcumhazard()} are used, then {cmd:tde()} effects are additive on the log cumulative hazard scale.{p_end}

{dlgtab:Mixture model}

{phang}{opt mixture} specifies that survival times are simulated from a 2-component mixture model, with mixture component distributions defined by {cmd:distribution()}. {cmd:lambdas()} and {cmd:gammas()} must be of length 2.{p_end}

{phang}{opt pmix(#)} defines the mixture parameter. Default is 0.5.{p_end}

{dlgtab:Competing risks}

{phang}{opt cr} specifies that survival times are simulated from the all-cause distribution from {cmd:ncr()} cause-specific hazards, with distributions defined by {cmd:distribution()}. In this case, Newton-Raphson 
iterations are used to simulate the survival times.{p_end}

{phang}{opt ncr(#)} defines the number of competing risks. {cmd:lambdas()} and {cmd:gammas()} must be of length {cmd:ncr()}.{p_end}

{dlgtab:Convergence scheme}

{phang}{opt centol(real)} specifies the tolerance of Brent's univariate root finder or the Newton-Raphson scheme. Default is 1E-08.{p_end}

{phang}{opt showdiff} display the maximum difference in estimates between iterations when using the Newton-Raphson scheme. This can be used to monitor convergence.{p_end}

{dlgtab:User defined [log] [cumulative] baseline hazard function}

{phang}{opt loghazard(string)} is the user-defined log baseline hazard function. This must be written in Mata code using colon operators. 
Time must be entered as #t. Variables can be directly included in the defined function. See examples below.{p_end}

{phang}{opt hazard(string)} is the user-defined baseline hazard function. This must be written in Mata code using colon operators. 
Time must be entered as #t. Variables can be directly included in the defined function. See examples below.{p_end}

{phang}{opt logcumhazard(string)} is the user-defined log cumulative baseline hazard function. This must be written in Mata code using colon operators. 
Time must be entered as #t. Variables can be directly included in the defined function.{p_end}

{phang}{opt cumhazard(string)} is the user-defined baseline cumulative hazard function. This must be written in Mata code using colon operators. 
Time must be entered as #t. Variables can be directly included in the defined function.{p_end}

{phang}{opt nodes(#)} defines the number of Gauss-Legendre quadrature points used to evaluate the cumulative hazard function when {cmd:loghazard()} or {cmd:hazard()}. 
Default is 30. This should be increased to assess the stability of the simulation process.{p_end}

{phang}{opt tdefunction(string)} defines the function of time to which covariates specified in {cmd:tde()} are interacted with to create 
time-dependent effects. The default is #t, i.e. linear time. This must be written in Mata code with #t used to represent time, for example #t:^2.{p_end}

{phang}{opt iterations(#)} defines the maximum number of iterations passed to {cmd:mm_root()}. Default is 1000. See {helpb moremata} for more details.{p_end}

{phang}{opt mintime(#)} defines the minimum possible simulated survival time passed to {cmd:mm_root()}. Default is 1E-08. See {helpb moremata} for more details.{p_end}


{title:Remarks}

{pstd}When simulating from a user-defined {cmd:loghazard()} or {cmd:hazard()} function, numerical quadrature is used to evaluate the cumulative hazard function, 
within iterations of Brent's univariate root finder. As with all model frameworks which use numerical integration, it is important to assess the stability of 
the simulated survival times with an increasing number of quadrature nodes.{p_end}


{title:Examples 1}

{pstd}Generate times from a Weibull model including a binary treatment variable, with log(hazard ratio) = -0.5, and censoring after 5 years:{p_end}
{phang}{stata "set obs 1000":. set obs 1000}{p_end}
{phang}{stata "gen trt = rbinomial(1,0.5)":. gen trt = rbinomial(1,0.5)}{p_end}
{phang}{stata "survsim stime1 died, lambdas(0.1) gammas(1.5) cov(trt -0.5) maxt(5)":. survsim stime1 died, lambdas(0.1) gammas(1.5) cov(trt -0.5) maxt(5)}{p_end}
{phang}{stata "stset stime1, f(died = 1)":. stset stime1, f(died = 1)}{p_end}
{phang}{stata "streg trt, dist(weibull) nohr":. streg trt, dist(weibull) nohr}{p_end}

{pstd}Generate times from a Gompertz model:{p_end}
{phang}{stata "survsim stime2, lambdas(0.1) gammas(0.05) dist(gompertz)":. survsim stime2, lambdas(0.1) gammas(0.05) dist(gompertz)}{p_end}

{pstd}Generate times from a 2-component mixture Weibull model:{p_end}
{phang}{stata "survsim stime3, mixture lambdas(0.1 0.05) gammas(1 1.5) pmix(0.5) maxtime(5)":. survsim stime3, mixture lambdas(0.1 0.05) gammas(1 1.5) pmix(0.5) maxtime(5)}{p_end}

{pstd}Generate times from a competing risks model with 4 cause-specific Weibull hazards and 4 cause-specific treatment effects:{p_end}
{phang}{stata "survsim stime4 status, cr ncr(4) lambdas(0.1 0.05 0.1 0.05) gammas(0.5 1.5 1 1.2) cov(trt 0.2 0.1 -0.1 0.4)":. survsim stime4 status, cr ncr(4) lambdas(0.1 0.05 0.1 0.05) gammas(0.5 1.5 1 1.2) cov(trt 0.2 0.1 -0.1 0.4)}{p_end}

{pstd}Generate times from a Weibull model with diminishing treatment effect:{p_end}
{phang}{stata "survsim stime5, lambdas(0.1) gammas(1.5) cov(trt -0.5) tde(trt 0.05)":. survsim stime5, lambdas(0.1) gammas(1.5) cov(trt -0.5) tde(trt 0.05)}{p_end}

{pstd}Generate times from user-defined log baseline hazard function:{p_end}
{phang}{stata "survsim stime6, loghazard(-1 :+ 0.02:*#t :- 0.03:*#t:^2 :+ 0.005:*#t:^3) maxt(1.5)":. survsim stime6, loghazard(-1 :+ 0.02:*#t :- 0.03:*#t:^2 :+ 0.005:*#t:^3) maxt(1.5)}{p_end}

{pstd}Generate times from user-defined log baseline hazard function with diminishing treatment effect:{p_end}
{phang}{stata "survsim stime7 died2, loghazard(-1:+0.02:*#t:-0.03:*#t:^2:+0.005:*#t:^3) cov(trt -0.5) tde(trt 0.03) maxt(1.5)":. survsim stime7 died2, loghazard(-1 :+ 0.02:*#t :- 0.03:*#t:^2 :+ 0.005:*#t:^3) cov(trt -0.5) tde(trt 0.03) maxt(1.5)}{p_end}

{pstd}Generate survival times from a joint longitudinal and survival model:{p_end}
{phang}{stata "set obs 1000":. set obs 1000}{p_end}
{phang}{stata "gen trt = rbinomial(1,0.5)":. gen trt = rbinomial(1,0.5)}{p_end}
{phang}{stata "gen age = rnormal(65,12)":. gen age = rnormal(65,12)}{p_end}
{pstd}Define the association between the biomarker and survival{p_end}
{phang}{stata "local alpha = 0.25":. local alpha = 0.25}{p_end}
{pstd}Generate the random intercept and random slopes for the longitudinal submodel{p_end}
{phang}{stata "gen b0 = rnormal(0,1)":. gen b0 = rnormal(0,1)}{p_end}
{phang}{stata "gen b1 = rnormal(1,0.5)":. gen b1 = rnormal(1,0.5)}{p_end}
{pstd}Generate survival times from an exponential baseline hazard{p_end}
{phang}{stata "survsim st1 event, logh(`=log(0.1)':+`alpha':*(b0:+b1:*#t)) maxt(5) nodes(30) mint(0.03) cov(trt -0.5 age 0.02)":. survsim st1 event, logh(`=log(0.1)':+`alpha':*(b0:+b1:*#t)) maxt(5) nodes(30) cov(trt -0.5 age 0.02)}{p_end}
{pstd}Generate observed biomarker values at times 0, 1, 2, 3 , 4 years{p_end}
{phang}{stata "gen id = _n":. gen id = _n}{p_end}
{phang}{stata "expand 5":. expand 5}{p_end}
{phang}{stata "bys id: gen meastime = _n-1":. bys id: gen meastime = _n-1}{p_end}
{pstd}Remove observations after event or censoring time{p_end}
{phang}{stata "bys id: drop if meastime>=st1":. bys id: drop if meastime>=st1}{p_end}
{pstd}Generate observed biomarker values incorporating measurement error{p_end}
{phang}{stata "gen response = b0 + b1*meastime + rnormal(0,0.5)":. gen response = b0 + b1*meastime + rnormal(0,0.5)}{p_end}

{pstd}For more examples please see Crowther and Lambert (2013).{p_end}


{title:Author}

{pstd}Michael J. Crowther{p_end}
{pstd}Department of Health Sciences{p_end}
{pstd}University of Leicester{p_end}
{pstd}E-mail: {browse "mailto:michael.crowther@le.ac.uk":michael.crowther@le.ac.uk}{p_end}

{phang}Please report any errors you may find.{p_end}


{title:References}

{phang}Bender R, Augustin T and Blettner M. Generating survival times to simulate Cox proportional hazards models. {it:Statistics in Medicine} 2005;24:1713-1723.{p_end}

{phang}Beyersmann J, Latouche A, Buchholz A and Schumacher M. Simulating competing risks data in survival analysis. {it:Statistics in Medicine} 2009;28:956-971.{p_end}

{phang}Crowther MJ and Lambert PC. {browse "http://onlinelibrary.wiley.com/doi/10.1002/sim.5823/abstract":Simulating biologically plausible complex survival data.} {it:Statistics in Medicine} 2013;(In press).{p_end}

{phang}Crowther MJ and Lambert PC. {browse "http://www.stata-journal.com/article.html?article=st0275":Simulating complex survival data.}{it: The Stata Journal} 2012;12(4):674-687.{p_end}

{phang}Jann, B. 2005. moremata: Stata module (Mata) to provide various functions. Available from http://ideas.repec.org/c/boc/bocode/s455001.html.{p_end}

