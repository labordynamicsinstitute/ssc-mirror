{smcl}
{* *! version 1.2.1  09apr2022}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{vieweralsosee "xtdpdbc postestimation" "help xtdpdbc_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "[XT] xtabond" "help xtabond"}{...}
{vieweralsosee "[XT] xtdpd" "help xtdpd"}{...}
{vieweralsosee "[XT] xtdpdsys" "help xtdpdsys"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtdpdbc##syntax"}{...}
{viewerjumpto "Description" "xtdpdbc##description"}{...}
{viewerjumpto "Options" "xtdpdbc##options"}{...}
{viewerjumpto "Remarks" "xtdpdbc##remarks"}{...}
{viewerjumpto "Example" "xtdpdbc##example"}{...}
{viewerjumpto "Saved results" "xtdpdbc##results"}{...}
{viewerjumpto "Authors" "xtdpdbc##authors"}{...}
{viewerjumpto "References" "xtdpdbc##references"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{bf:xtdpdbc} {hline 2}}Bias-corrected linear dynamic panel data estimation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:xtdpdbc} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]


{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{p2coldent :* {opt fe}}estimate fixed-effects model, the default{p_end}
{p2coldent :* {opt re}}estimate random-effects model{p_end}
{p2coldent :* {opth hy:brid(varlist)}}estimate hybrid model{p_end}
{synopt:{opt la:gs(#)}}lags of the dependent variable; default is {cmd:lags(1)}{p_end}
{synopt:{opt te:ffects}}add time effects to the model{p_end}
{synopt:{opt one:step}}use the one-step instead of the two-step estimator{p_end}
{synopt:{opt nocor:rection}}do not apply bias correction{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}

{syntab:SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt conventional}, {opt un:adjusted}, or {opt r:obust}{p_end}
{synopt:{opt sm:all}}make degrees-of-freedom adjustment and report small-sample statistics{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
INCLUDE help shortdes-coeflegend
{synopt:{opt nohe:ader}}suppress output header{p_end}
{synopt:{opt notab:le}}suppress coefficient table{p_end}
{synopt:{it:{help xtdpdbc##display_options:display_options}}}control
INCLUDE help shortdes-displayoptall

{syntab:Minimization}
{synopt:{opt from(init_specs)}}initial values for the coefficients{p_end}
{synopt:{opt conc:entration}}minimize the concentrated objective function{p_end}
{synopt:{it:{help xtdpdbc##minimize_options:minimize_options}}}control the minimization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* You can specify at most one of these options.{p_end}

{p 4 6 2}
{it:init_specs} is one of

{p 8 20 2}{it:matname} [{cmd:,} {cmd:skip} {cmd:copy}]{p_end}

{p 8 20 2}{it:#} [{it:#} {it:...}]{cmd:,} {cmd:copy}{p_end}

{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:xtdpdbc}; see {helpb xtset:[XT] xtset}.{p_end}
{p 4 6 2}
All {it:varlists} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}
{it:depvar} and all {it:varlists} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}
See {helpb xtdpdbc postestimation} for features available after estimation.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdpdbc} implements the bias-corrected method-of-moments estimator of Breitung, Kripfganz, and Hayakawa (2021) for linear dynamic panel data models with unobserved group-specific effects,
where all {it:indepvars} are strictly exogenous with respect to the idiosyncratic error component. The fixed-effects version of the estimator is equivalent to the adjusted profile likelihood estimator of Dhaene and Jochmans (2016) and,
for models with a single lag of the dependent variable, to the iterative bias-corrected estimator of Bun and Carree (2005).


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt fe}, the default, requests to estimate a dynamic fixed-effects model.

{phang}
{opt re} requests to estimate a dynamic random-effects model.

{phang}
{opth hybrid(varlist)} requests to estimate a hybrid model, in which {it:varlist} satisfies a random-effects assumption and all other variables in {it:indepvars} satisfy a fixed-effects assumption.

{phang}
{opt lags(#)} specifies the lags of {it:depvar} to be used as regressors. The default is {cmd:lags(1)}.

{phang}
{opt teffects} requests that time-specific effects are added to the model. The first time period in the estimation sample is treated as the base period.

{phang}
{opt onestep} requests the one-step instead of the two-step GMM estimator to be computed for the random-effects or hybrid model. This is the default for the fixed-effects model.

{phang}
{opt nocorrection} requests not to apply the bias correction.

{phang}
{opt noconstant}; see {helpb estimation options##noconstant:[R] estimation options}.

{dlgtab:SE/Robust}

{phang}
{opt vce(vcetype)} specifies the type of standard error reported, which includes types that are derived from asymptotic theory ({opt conventional}) and that are robust to some kinds of misspecification ({opt robust}).

{pmore}
{cmd:vce(conventional)}, the default, uses the conventionally derived variance estimator. This is a sandwich-type estimator unless option {opt nocorrection} is specified, but it is not fully robust;
see Theorem 1(i) in Breitung, Kripfganz, and Hayakawa (2021). When option {opt nocorrection} is specified, {cmd:vce(conventional)} is equivalent to {cmd:vce(unadjusted)}.

{pmore}
{cmd:vce(unadjusted)} uses an unadjusted estimator. This is the conventionally derived variance estimator when no bias correction is applied. It is usually only appropriate if there are many time periods in the estimation sample.

{pmore}
{cmd:vce(robust)} uses the sandwich estimator.

{phang}
{opt small} requests that a degrees-of-freedom adjustment be made to the variance-covariance matrix and that small-sample t and F statistics be reported.
The adjustment factor is (N-1)/(N-K) * M/(M-1), where N is the number of observations, M the number of groups, and K the number of coefficients. By default, no degrees-of-freedom adjustment is made and z and Wald statistics are reported.

{dlgtab:Reporting}

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] estimation options}.

{phang}
{opt coeflegend}; see {helpb estimation options##coeflegend:[R] estimation options}.

{phang}
{opt noheader} suppresses display of the header above the coefficient table that displays the number of observations.

{phang}
{opt notable} suppresses display of the coefficient table.

{marker display_options}{...}
{phang}
{it:display_options}: {opt noci}, {opt nopv:alues}, {opt noomit:ted}, {opt vsquish}, {opt noempty:cells}, {opt base:levels}, {opt allbase:levels}, {opt nofvlab:el}, {opt fvwrap(#)}, {opt fvwrapon(style)}, {opth cformat(%fmt)},
{opt pformat(%fmt)}, {opt sformat(%fmt)}, and {opt nolstretch}; see {helpb estimation options##display_options:[R] estimation options}.

{dlgtab:Minimization}

{phang}
{opt from(init_specs)} specifies initial values for the coefficients; see {helpb maximize:[R] maximize}. By default, initial values are taken from the fixed-effects estimator; see {helpb xtreg:[XT] xtreg}.

{phang}
{opt concentration} specifies that the concentrated objective function with the autoregressive coefficients as the only parameters should be minimized.
The coefficient estimates for the strictly exogenous {it:indepvars} are obtained from the analytical first-order conditions given the estimates of the autoregressive coefficients.
By default, minimization is done over all coefficients simultaneously.

{phang}{marker minimize_options}
{it:minimize_options}: {opt iter:ate(#)}, {opt nolo:g}, {opt showstep}, {opt showtol:erance}, {opt tol:erance(#)}, {opt ltol:erance(#)}, {opt nrtol:erance(#)}, and {opt nonrtol:erance}; see {helpb maximize:[R] maximize}.
These options are seldom used.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:xtdpdbc} applies a bias correction to the first-order conditions of the fixed-effects estimator in dynamic panel data models. This yields a just-identified method-of-moments estimator with nonlinear moment conditions.
{cmd:xtdpdbc} minimizes the quadratic criterion function numerically with the Gauss-Newton technique.

{pstd}
{cmd:xtdpdbc} can also compute a random-effects version of the bias-corrected estimator. It adds additional orthogonality conditions for the model in levels. This yields an overidentified generalized method-of-moments estimator.
By default, a two-step estimator is used, which computes an optimal weighting matrix in the first step.

{pstd}
Unbalanced panel data are supported, but groups with interior missing values (gaps) are dropped from the estimation sample.
The minimum number of consecutive observations required per group is 1 + 2 * {it:#}, where {it:#} is the lag order of the dependent variable specified with option {opt lags(#)}.

{pstd}
Due to the nonlinearity of the moment functions, the estimator has multiple solutions and the numerical algorithm might converge to an incorrect solution. At the correct solution, all eigenvalues of the gradient should be negative.
A warning message is displayed if this is not the case. In such a situation, as discussed by Breitung, Kripfganz, and Hayakawa (2021), alternative starting values with the option {cmd:from()} should be used until a correct solution is found.

{pstd}
In some cases, the numerical algorithm might not converve due to an almost flat criterion function. In such a situation, the option {opt concentration} might help to simplify the optimization problem.
Otherwise, formal convergence could be achieved by declaring the option {opt nonrtolerance}. However, the results might not be very reliable.


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}{stata webuse psidextract:. webuse psidextract}{p_end}

{pstd}Bias-corrected fixed-effects estimator with AR(2) dynamics{p_end}
{phang2}{stata xtdpdbc lwage wks south smsa ms exp exp2 occ ind union, lags(2):. xtdpdbc lwage wks south smsa ms exp exp2 occ ind union, lags(2)}{p_end}

{pstd}Bias-corrected random-effects estimator with AR(2) dynamics{p_end}
{phang2}{stata xtdpdbc lwage wks south smsa ms exp exp2 occ ind union, re lags(2):. xtdpdbc lwage wks south smsa ms exp exp2 occ ind union, re lags(2)}{p_end}


{marker results}{...}
{title:Saved results}

{pstd}
{cmd:xtdpdbc} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom; not always saved{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(g_min)}}smallest group size{p_end}
{synopt:{cmd:e(g_avg)}}average group size{p_end}
{synopt:{cmd:e(g_max)}}largest group size{p_end}
{synopt:{cmd:e(f)}}value of the objective function{p_end}
{synopt:{cmd:e(chi2_J)}}overidentification J-statistic; not always saved{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(zrank)}}number of moment functions{p_end}
{synopt:{cmd:e(zrank_a)}}number of moment functions, adjusted for time effects in unbalanced panels; not always saved{p_end}
{synopt:{cmd:e(lags)}}number of lags of the dependent variable{p_end}
{synopt:{cmd:e(sigma2e)}}estimate of sigma_e^2; not always saved{p_end}
{synopt:{cmd:e(steps)}}number of steps{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(converged)}}= {cmd:1} if converged, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(maxeig)}}maximum eigenvalue of the score matrix{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtdpdbc}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(ivar)}}variable denoting groups{p_end}
{synopt:{cmd:e(tvar)}}variable denoting time{p_end}
{synopt:{cmd:e(estat_cmd)}}{cmd:xtdpdbc_estat}{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtdpdbc_p}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {cmd:margins}{p_end}
{synopt:{cmd:e(teffects)}}time effects created with option {cmd:teffects}{p_end}
{synopt:{cmd:e(model)}}{cmd:fe}, {cmd:re}, or {cmd:hybrid(}{it:varlist}{cmd:)}{p_end}
{synopt:{cmd:e(vce)}}{cmd:conventional} or {cmd:robust}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker authors}{...}
{title:Authors}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}

{pstd}
J{c o:}rg Breitung, University of Cologne, {browse "https://wisostat.uni-koeln.de/en/institute/professors/breitung"}


{marker references}{...}
{title:References}

{phang}
Breitung, J., S. Kripfganz, and K. Hayakawa. 2021.
Bias-corrected method of moments estimators for dynamic panel data models.
{it:Accepted for publication in Econometrics and Statistics}.

{phang}
Bun, M. J. G., and M. A. Carree. 2005.
Bias-corrected estimation in dynamic panel data models.
{it:Journal of Business & Economic Statistics} 23: 200-210.

{phang}
Dhaene, G., and K. Jochmans. 2016.
Likelihood inference in an autoregression with fixed effects.
{it:Econometric Theory} 32: 1178-1215.
