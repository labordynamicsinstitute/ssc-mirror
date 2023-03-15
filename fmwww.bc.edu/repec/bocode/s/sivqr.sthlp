{smcl}
{* *! version 1.1.0  22jan2022}{...}
{vieweralsosee "[R] ivregress" "help ivregress"}{...}
{vieweralsosee "[R] qreg" "help qreg"}{...}
{viewerjumpto "Syntax" "sivqr##syntax"}{...}
{viewerjumpto "Description" "sivqr##description"}{...}
{viewerjumpto "Options" "sivqr##options"}{...}
{viewerjumpto "Examples" "sivqr##examples"}{...}
{viewerjumpto "Stored results" "sivqr##results"}{...}
{viewerjumpto "Author" "sivqr##author"}{...}
{viewerjumpto "References" "sivqr##references"}{...}
{title:Title}

{phang}
{* phang is short for p 4 8 2}
{bf:sivqr} {hline 2}  Smoothed instrumental variables quantile regression


{marker syntax}{...}
{title:Syntax}

{phang}
{cmd:sivqr}
{depvar} 
[{it:{help varlist:varlist1}}]
{cmd:(}{it:{help varlist:varlist2}} {cmd:=}
        {it:{help varlist:varlist_iv}}{cmd:)}
{ifin}
{weight}
{cmd:,}
{opt q:uantile(#)}
[{it:options}]

{phang}
As in {helpb ivregress}, {it:varlist1} is the list of exogenous regressors (or control variables), 
{it:varlist2} is the list of endogenous regressors, and 
{it:varlist_iv} is the list of excluded instruments.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt q:uantile(#)}}estimate # quantile
{p_end}
{synopt :{opt b:andwidth(#)}}manually set smoothing bandwidth; default is to use plug-in bandwidth{p_end}
{synopt :{opt r:eps(#)}}perform # bootstrap replications; default is {cmd:reps(20)}{p_end}
{synopt :{opt nocon:stant}}suppress constant term{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is 95 or {cmd:c(level)} as set by {cmd:set level}{p_end}
{synopt :{opt log:iterations}}report iterations of numerical solver{p_end}
{synopt :{opt nodots}}suppress bootstrap replication dots{p_end}

{syntab:Advanced}
{synopt :{opt seed(#)}}set random-number seed to #{p_end}
{synopt :{opt init:ial(matname)}}manually set initial coefficient values for numerical search{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{bf:by} is allowed; see {help by}.{p_end}
{p 4 6 2}{cmd:pweight}s, {cmd:iweight}s, and {cmd:fweight}s are allowed; see {help weight}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:sivqr} estimates quantile regression models in which one or more of the regressors are endogenously determined.
It is like {helpb qreg}, but allowing for instrumental variables to address endogeneity.
Or, it is like {helpb ivregress}, but estimating structural coefficients or causal effects at different levels (quantiles) of unobserved heterogeneity (rank variable).
As with both {helpb qreg} and {helpb ivregress}, the structural model is implicitly linear in the regressors ({it:varlist1} and {it:varlist2}), but those regressors may themselves be nonlinear functions of variables in the raw data.
The estimator uses smoothing to improve both computational speed and statistical precision.
The methodology was proposed and studied by {help sivqr##KS2017:Kaplan and Sun (2017)}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt quantile(#)} specifies the quantile to be estimated and should be a number between 0 and 1, exclusive, or alternatively a number between 1 and 100 interpreted as a percentile.
For example, {cmd:quantile(0.5)} corresponds to the median, as does {cmd:quantile(50)}.

{phang}
{opt bandwidth(#)} manually specifies the desired smoothing bandwidth.
If a numerical solution cannot be found with the desired bandwidth, then the bandwidth is increased (as little as possible) until it can.
For example, {cmd:bandwidth(0)} uses the smallest possible amount of smoothing.
Alternatively, with no bandwidth specified, an automatic plug-in bandwidth is computed based on {help sivqr##KS2017:Kaplan and Sun (2017)}.
Though not optimal in every case, the plug-in bandwidth tries to minimize the estimator's mean squared error and has performed well in simulations, and it often greatly reduces computation time compared to {cmd:bandwidth(0)}.

{phang}{opt reps(#)} specifies the number of bootstrap replications for estimating the variance-covariance matrix and standard errors.
With the default {cmd:reps(0)} heteroskedasticity-robust analytic standard errors are reported.
The Bayesian bootstrap of {help sivqr##R1981:Rubin (1981)} is used; it is a valid frequentist bootstrap that also has a nonparametric Bayesian interpretation.

{phang}
{opt noconstant}; see 
{helpb estimation options##noconstant:[R] estimation options}.

{dlgtab:Reporting}

{phang}
{opt level(#)}; see 
{helpb estimation options##level():[R] estimation options}.

{phang}
{opt logiterations} displays each iteration of the numerical solver, {helpb mf_solvenl:solvenl()}, for the main estimation.  Usually this is not valuable information.

{phang}
{opt nodots} suppresses display of the replication dots (as in {helpb bootstrap})

{dlgtab:Advanced}

{phang}
{opt seed(#)} sets the random-number seed (as in {helpb bootstrap}).

{phang}
{opt initialize(matname)} sets the initial coefficient values for the numerical search, using the values stored in the matrix (row vector) named {it:matname}.
If not specified, then {cmd:qreg} is used to generate initial values.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse hsng2}{p_end}

{pstd}Run median IVQR with defaults (plug-in bandwidth, analytic Std. Err.){p_end}
{phang2}{cmd:. sivqr rent pcturban (hsngval = faminc i.region), q(0.5)}{p_end}

{pstd}
Additional examples are in the sivqr_examples.do file.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:sivqr} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(reps)}}number of bootstrap replications{p_end}
{synopt:{cmd:e(bwidth)}}smoothing bandwidth used{p_end}
{synopt:{cmd:e(bwidth_req)}}smoothing bandwidth requested (or plug-in value){p_end}
{synopt:{cmd:e(bwidth_max)}}maximum plug-in bandwidth (of 3){p_end}
{synopt:{cmd:e(q)}}quantile level (0<{cmd:e(q)}<1){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:sivqr}{p_end}
{synopt:{cmd:e(vcetype)}}"Robust" or "Bootstrap"{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(instd)}}instrumented variable(s){p_end}
{synopt:{cmd:e(insts)}}instrument(s){p_end}
{synopt:{cmd:e(constant)}}{cmd:noconstant} if specified
{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(exogr)}}exogenous regressors{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V} or else only {cmd:b} if {cmd:reps(0)}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}estimated coefficient vector{p_end}
{synopt:{cmd:e(V)}}estimated variance-covariance matrix of the estimator, unless {cmd:reps(0)}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{pstd}
{cmd:sivqr} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}table of results{p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}
David M. Kaplan{break}Department of Economics, University of Missouri{break}
kaplandm@missouri.edu{break}{browse "https://kaplandm.github.io"}

{marker references}
{title:References}

{marker KS2017}{...}
{phang}
Kaplan, D. M., and Sun, Y. 2017.
Smoothed Estimating Equations for Instrumental Variables Quantile Regression.
{it:Econometric Theory} 33: 105-157.{break}
URL: {browse "https://doi.org/10.1017/S0266466615000407"}

{marker R1981}{...}
{phang}
Rubin, D. B. 1981. The Bayesian Bootstrap. {it:Annals of Statistics} 9: 130-134.{break}
URL: {browse "https://projecteuclid.org/euclid.aos/1176345338"}
{p_end}
