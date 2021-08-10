{smcl}
{* *! version 1.0.1  19feb2021}{...}


{cmd:help hetsar}
{hline}

{title:Title}

{p2colset 5 15 15 1}{...}
{p2col:{hi:hetsar} {hline 2}}Spatial autoregressive models with heterogeneous coefficients{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 16 2}{cmd:hetsar} {depvar} [{indepvars}] {ifin},
wmatrix(name) [{it:{help hetsar##hetsaroptions:options}}]


{marker hetsaroptions}{...}
{synoptset 33 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab:Model}
{synopt :{cmdab:wmat:rix(}{it:name}{cmd:)}}specifies a spatial weights matrix used to create spatial lags of dependent and independent variables. Stata matrices, {help spmat} or {help spmatrix} objects are allowed.
{p_end}
{synopt :{opt det:ailed}}post to e(b) and e(V) the estimated unit-specific coefficients and corresponding VCV matrix.
{it: Default} is to post the mean group estimates (see Aquaro, Bailey and Pesaran, 2021 for more details) {p_end}
{synopt :{cmdab:ivarlag(}{it:durb_varlist})}specifies that the spatial lag of the independent variables in {it:durb_varlist} is included in the model.
{p_end}
{synopt :{cmdab:dyn:amic}}specifies that time lagged dependent and independent variables and spatial/time lagged dependent variable are included in the model. If the option {cmd: ivarlag({it:durb_varlist})} is specified,
also time lagged {it:durb_varlist} are included in the model{p_end}
{synopt :{opt rob:ust}}Sandwich estimator of the VCV matrix{p_end}
{synopt :{opt nocons:tant}}suppress unit-specific intercepts in the model{p_end}

{syntab:Maximization}
{synopt :{it:{help hetsar##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}

{p2colreset}{...}
{p 4 6 2}
A panel and a time variable must be specified. Use {helpb xtset}.{p_end}
{p 4 6 2}
{it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}
{help weights} are not allowed.{p_end}



{title: Description}

{pstd}
{cmd:hetsar} fits spatial panel data models with heterogeneous coefficients, with and without weakly exogenous regressors, subject to heteroskedastic errors. The estimation is performed via quasi maximum-likelihood.{p_end}
{pstd}See Aquaro, Bailey and Pesaran (2021) for more details.{p_end}


{dlgtab:Maximization}
{marker maximize_options}
{phang}
{it:maximize_options}: {opt dif:ficult}, {opt tech:nique(algorithm_spec)},
{opt iter:ate(#)}, [{opt no:}]{opt lo:g}, {opt from(init_specs)}, {opt tol:erance(#)},
{opt ltol:erance(#)}, {opt nrtol:erance(#)}; see {manhelp maximize R}.  These
options are seldom used.


{title:Remarks}

{pstd}
{cmd:hetsar} performs a constrained minimization of the negative log-likelihood function of the model.{p_end}
{pstd}{it:Wy} parameters are constrained in [-0.995, 0.995] while {it:sigmasq} parameters are constrained in [0, +infty]. All the other parameters are left unconstrained.{p_end}
{pstd}
A {cmd:d1} evaluator is used for optimization. See {help optimize}{p_end}


{title:Examples}

{pstd}Load spatial weights matrix{p_end}
{phang2}{cmd: use http://www.econometrics.it/stata/data/hetsar_demo_wmat.dta, clear} {p_end}
{phang2}{cmd: mkmat w1-w25, mat(w)} {p_end}

{pstd}Load data and set-up the panel{p_end}
{phang2}{cmd: use http://www.econometrics.it/stata/data/hetsar_demo.dta, clear}{p_end}
{phang2}{cmd: xtset id time} {p_end}

{pstd}Estimate a SAR static model{p_end}
{phang2}{cmd: hetsar y x, wmatrix(w)} {p_end}

{pstd}Estimate a Durbin static model{p_end}
{phang2}{cmd: hetsar y x, wmatrix(w) ivarlag(x)}{p_end}

{pstd}Estimate a SAR dynamic model{p_end}
{phang2}{cmd: hetsar y x, wmatrix(w) dynamic} {p_end}

{pstd}Estimate a Durbin dynamic model{p_end}
{phang2}{cmd: hetsar y x, wmatrix(w) ivarlag(x) dynamic} {p_end}

{pstd}Estimate a SAR static model and report estimated unit-specific coefficients{p_end}
{phang2}{cmd: hetsar y x, wmatrix(w) detailed} {p_end}


{title:References}

{phang}
Aquaro, M, Bailey, N and Pesaran, M.H., 2021
"Estimation and inference for spatial models with heterogeneous coefficients: An application to US house prices", Journal of Applied Econometrics, 36, pp. 18-44.



{title:Saved results}

{pstd}
{cmd:hetsar} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(mean_group)}}1 if mean group estimator, 0 otherwise{p_end}
{synopt:{cmd:e(k_mg)}}number of parameters (Mean group estimator){p_end}
{synopt:{cmd:e(dynamic)}}1 if dynamic model, 0 otherwise{p_end}
{synopt:{cmd:e(ll)}}negative log-likelihood{p_end}
{synopt:{cmd:e(converged)}}1 if the model converged, 0 otherwise{p_end}
{synopt:{cmd:e(rank)}}rank of the variance-covariance matrix{p_end}
{synopt:{cmd:e(iter)}}number of iterations{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:hetsar}{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Authors}

{pstd}Federico Belotti{p_end}
{pstd}Department of Economics and Finance{p_end}
{pstd}University of Rome Tor Vergata{p_end}
{pstd}Rome, Italy{p_end}
{pstd}federico.belotti@uniroma2.it{p_end}




{title:Also see}

{psee}
Online: {help spxtregress}, {helpb xsmle} (if installed){p_end}
