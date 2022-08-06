{smcl}
{* *! version 2.6.2  03aug2022}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{vieweralsosee "xtdpdgmm" "help xtdpdgmm"}{...}
{vieweralsosee "xtdpdgmm postestimation" "help xtdpdgmm_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "[XT] xtivreg" "help xtivreg"}{...}
{vieweralsosee "[XT] xtabond" "help xtabond"}{...}
{vieweralsosee "[XT] xtdpd" "help xtdpd"}{...}
{vieweralsosee "[XT] xtdpdsys" "help xtdpdsys"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtdpdgmmfe##syntax"}{...}
{viewerjumpto "Description" "xtdpdgmmfe##description"}{...}
{viewerjumpto "Options" "xtdpdgmmfe##options"}{...}
{viewerjumpto "Example" "xtdpdgmmfe##example"}{...}
{viewerjumpto "Author" "xtdpdgmm##author"}{...}
{viewerjumpto "References" "xtdpdgmm##references"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{bf:xtdpdgmmfe} {hline 2}}GMM linear dynamic panel data estimation with fixed effects{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:xtdpdgmmfe} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]


{synoptset 23 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{synopt:{opt la:gs(#)}}lags of the dependent variable; default is {cmd:lags(1)}{p_end}
{synopt:{opth exo:genous(varlist)}}exogenous variables in {it:indepvars}{p_end}
{synopt:{opth pre:determined(varlist)}}predetermined variables in {it:indepvars}{p_end}
{synopt:{opth endo:genous(varlist)}}endogenous variables in {it:indepvars}{p_end}
{synopt:{opt or:thogonal}}use orthogonal deviations instead of first differences{p_end}
{synopt:{opt c:ollapse}}collapse GMM-type into standard instruments{p_end}
{synopt:{opt cur:tail(#)}}curtail the lag range for GMM-type instruments{p_end}
{synopt:{opt ser:ial(#)}}degree of serial correlation; default is {cmd:serial(0)}{p_end}
{synopt:{opt iid}}independent and identically distributed errors{p_end}
{synopt:{opt initd:ev}}weaker assumption on initial observations{p_end}
{synopt:{opt sta:tionary}}joint mean stationarity assumption{p_end}
{synopt:{opt nonl}}do not use nonlinear moment conditions{p_end}
{p2coldent :* {opt one:step}|{opt two:step}}use the one-step or two-step estimator{p_end}
{p2coldent :* {opt igmm}}use the iterated GMM estimator, the default{p_end}
{p2coldent :* {opt cu:gmm}}use the continuously-updating GMM estimator{p_end}
{synopt:{opt te:ffects}}add time effects to the model{p_end}
{synopt:{it:{help xtdpdgmmfe##xtdpdgmm_options:xtdpdgmm_options}}}other options for {cmd:xtdpdgmm} estimation{p_end}

{syntab:Reporting}
{synopt:{opt nocmd:line}}supress {cmd:xtdpdgmm} command line{p_end}
{synopt:{it:{help xtdpdgmmfe##display_options:display_options}}}control the display of the regression output{p_end}

{syntab:Minimization}
{synopt:{it:{help xtdpdgmmfe##igmm_options:igmm_options}}}control the iterated GMM process; seldom used{p_end}
{synopt:{it:{help xtdpdgmmfe##minimize_options:minimize_options}}}control the minimization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* You can specify at most one of these options. {cmd:igmm} is the default.{p_end}

{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:xtdpdgmm}; see {helpb xtset:[XT] xtset}.{p_end}
{p 4 6 2}
All {it:varlists} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}
{it:depvar} and all {it:varlists} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}
{cmd:xtdpdgmmfe} is a wrapper for {helpb xtdpdgmm}. See {helpb xtdpdgmm postestimation} for features available after estimation.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdpdgmmfe} implements generalized method of moments (GMM) estimators for linear dynamic panel data models in the spirit of Anderson and Hsiao (1981), Arellano and Bond (1991), Ahn and Schmidt (1995), Arellano and Bover (1995),
Blundell and Bond (1998), Hayakawa, Qi, and Breitung (2019), and Chudik and Pesaran (2022).

{pstd}
The model can be estimated with the one-step, two-step, iterated, or continuously-updating GMM estimator. The two-step estimator uses an optimal weighting matrix which is estimated from the one-step residuals.
The iterated GMM estimator, suggested by Hansen, Heaton, and Yaron (1996), further updates the weighting matrix until convergence.
The continuously-updating GMM estimator, also proposed by Hansen, Heaton, and Yaron (1996), updates the weighting matrix jointly with the coefficients.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(#)} specifies the lags of {it:depvar} to be used as regressors. The default is {cmd:lags(1)}.

{phang}
{opth exogenous(varlist)} specifies which of the variables in {it:indepvars} are strictly exogenous with respect to the idiosyncratic error component; see {helpb xtdpdgmm##remarks_exogenous:xtdpdgmm}.

{phang}
{opth predetermined(varlist)} specifies which of the variables in {it:indepvars} are predetermined with respect to the idiosyncratic error component; see {helpb xtdpdgmm##remarks_exogenous:xtdpdgmm}.

{phang}
{opth endogenous(varlist)} specifies which of the variables in {it:indepvars} are endogenous with respect to the idiosyncratic error component; see {helpb xtdpdgmm##remarks_exogenous:xtdpdgmm}.

{phang}
{opt orthogonal} requests instruments to be specified for the model in forward-orthogonal deviations instead of the model in first differences.
For exogenous variables, instruments are also specified for the model in deviations from within-group means; see {helpb xtdpdgmm##remarks_model:xtdpdgmm}.
In addition, when {opt initdev} is specified, backward-orthogonal deviations instead of first differences are used to transform instruments; see {helpb xtdpdgmm##remarks_iv:xtdpdgmm}.

{phang}
{opt collapse} requests to reduce the number of moment conditions by collapsing all GMM-type instruments into standard instruments and all nonlinear moment conditions into a single moment condition;
see {helpb xtdpdgmm##remarks_collapse:xtdpdgmm}.

{phang}
{opt curtail(#)} requests to reduce the number of moment conditions by curtailing the lag range for GMM-type instruments such that {it:#} is the maximum lag used; see {helpb xtdpdgmm##remarks_collapse:xtdpdgmm}.
In combination with with option {opt orthogonal}, the maximum lag used is {it:#}-1. This ensures that the same number of instruments is used with or without option {opt orthogonal}.

{phang}
{opt serial(#)} assumes that the idiosyncratic error component is serially correlated at most of order {it:#}. This affects which lags of predetermined and endogenous variables are valid instruments;
see {helpb xtdpdgmm##remarks_exogenous:xtdpdgmm}. By default, {cmd:serial(0)}, the idiosyncratic error component is assumed to be serially uncorrelated.
Depending on other assumptions made, additional nonlinear moment conditions proposed by Ahn and Schmidt (1995) or Chudik and Pesaran (2022) might be added which are valid under the absence of (higher-order) serial correlation;
see {helpb xtdpdgmm##remarks_nl:xtdpdgmm}.

{phang}
{opt iid} assumes that the idiosyncratic error component is homoskedastic and serially uncorrelated. This implies option {cmd:serial(0)}.
Depending on other assumptions made, additional linear and nonlinear moment conditions might be added; see {helpb xtdpdgmm##remarks_nl:xtdpdgmm}.

{phang}
{opt initdev} assumes that the deviations of the initial observations of {it:depvar} from its long-run mean are uncorrelated with the first-differenced idiosyncratic error component, as considered by Chudik and Pesaran (2022).
By default, it is assumed that both the group-specific error component and the initial observations of {it:varlist} and {it:indepvars} are uncorrelated with the first-differenced idiosyncratic error component;
see {helpb xtdpdgmm##remarks_nl:xtdpdgmm}.

{phang}
{opt stationary} assumes that the initial observations of {it:depvar} and {it:indepvars} are jointly mean stationary. This allows to include additional instruments for the untransformed model, as proposed by Blundell and Bond (1998).
This implies option {opt nonl} because nonlinear moment conditions generally become redundant; see {helpb xtdpdgmm##remarks_nl:xtdpdgmm}.

{phang}
{opt nonl} requests not to include any nonlinear moment conditions.

{phang}
{opt onestep}, {opt twostep}, {opt igmm}, and {opt cugmm} specify which estimator is to be used. At most one of these options can be specified.

{pmore}
{opt onestep} requests the one-step GMM estimator to be computed. In a model without nonlinear moment conditions and with the default weighting matrix, the one-step estimator corresponds to the two-stage least squares estimator.

{pmore}
{opt twostep} requests the two-step GMM estimator to be computed which is based on an unrestricted (cluster-robust) optimal weighting matrix.

{pmore}
{opt igmm}, the default, requests the iterated GMM estimator to be computed. At each iteration step, an unrestricted (cluster-robust) optimal weighting matrix is computed using the GMM estimates from the previous step.
Iterations continue until convergence is achieved for the coefficient vector or the weighting matrix, or the maximum number of iterations is reached.

{pmore}
{opt cugmm} requests the continuously-updating GMM estimator to be computed. As a function of the model's coefficients, the unrestricted (cluster-robust) weighting matrix is updated jointly with the coefficients.

{phang}
{opt teffects} requests that time-specific effects in the form of time dummies are added to the model.

{marker xtdpdgmm_options}{...}
{phang}
{it:xtdpdgmm_options}: {opt iv}{cmd:(}{it:{help xtdpdgmm##options_spec:iv_spec}}{cmd:)}, {opt gmm:iv}{cmd:(}{it:{help xtdpdgmm##options_spec:gmmiv_spec}}{cmd:)}, {opt w:matrix}{cmd:(}{it:{help xtdpdgmm##options_spec:wmat_spec}}{cmd:)},
{opt cen:ter}, {opt nores:cale}, {opt:nocons:tant}, {opt vce}{cmd:(}{it:{help xtdpdgmm##options_spec:vce_spec}}{cmd:)}, {opt sm:all}, and {opt over:id}; see {helpb xtdpdgmm}.
When adding further instruments with option {cmd:iv()} or {cmd:gmm()}, the suboption {opt m:odel}{cmd:(}{it:{help xtdpdgmm##options_spec:model_spec}}{cmd:)} should be specified because {cmd:xtdpdgmmfe} changes the default model.

{dlgtab:Reporting}

{phang}
{opt nocmdline} suppresses display of the {cmd:xtdpdgmm} command line.

{marker display_options}{...}
{phang}
{it:display_options}: {opt aux:iliary}, {opt l:evel(#)}, {opt coefl:egend}, {opt nohe:ader}, {opt notab:le}, and {opt nofo:oter}; see {helpb xtdpdgmm}.
{opt noci}, {opt nopv:alues}, {opt noomit:ted}, {opt vsquish}, {opt noempty:cells}, {opt base:levels}, {opt allbase:levels}, {opt nofvlab:el}, {opt fvwrap(#)}, {opt fvwrapon(style)}, {opth cformat(%fmt)}, {opt pformat(%fmt)},
{opt sformat(%fmt)}, and {opt nolstretch}; see {helpb estimation options##display_options:[R] estimation options}.

{dlgtab:Minimization}

{marker igmm_options}{...}
{phang}
{it:igmm_options}: {opt igmmit:erate(#)}, {opt igmmeps(#)}, and {opt igmmweps(#)}; see {helpb gmm:[R] gmm}. These options are seldom used and only have an effect if the iterated GMM estimator is used.

{marker minimize_options}{...}
{phang}
{it:minimize_options}: {opt noan:alytic}, {opt from}{cmd:(}{it:{help xtdpdgmm##options_spec:init_spec}}{cmd:)}, and {opt nodot:s}; see {helpb xtdpdgmm}.
{opt iter:ate(#)}, {opt nolo:g}, {opt showstep}, {opt showtol:erance}, {opt tol:erance(#)}, {opt ltol:erance(#)}, {opt nrtol:erance(#)}, and {opt nonrtol:erance}; see {helpb maximize:[R] maximize}.
These options are seldom used.


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}. {stata webuse abdata}{p_end}

{pstd}Anderson-Hsiao IV estimators with predetermined covariates{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) c cur(1) nonl nocons one}{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) initd c cur(1) nonl nocons one}{p_end}

{pstd}Arellano-Bond one-step GMM estimator with predetermined covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) c cur(4) nonl nocons one}{p_end}

{pstd}Arellano-Bover iterated GMM estimator with predetermined covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) c cur(4) or nonl vce(r)}{p_end}

{pstd}Ahn-Schmidt iterated GMM estimators with predetermined covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) c cur(4) vce(r)}{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) iid c cur(4) vce(r)}{p_end}

{pstd}Chudik-Pesaran iterated GMM estimator with predetermined covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) initd c cur(4) nocons vce(r)}{p_end}

{pstd}Blundell-Bond two-step, iterated, and continuously-updating GMM estimators with predetermined covariates and curtailed/collapsed instruments{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) sta c cur(4) two vce(r)}{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) sta c cur(4) igmm vce(r)}{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) sta c cur(4) cu vce(r)}{p_end}

{pstd}Hayakawa-Qi-Breitung IV estimator with predetermined covariates{p_end}
{phang2}. {stata xtdpdgmmfe n w k, pre(w k) initd or c cur(1) nonl nocons one}{p_end}

{pstd}Replication of a static fixed-effects estimator{p_end}
{phang2}. {stata xtdpdgmmfe n w k, la(0) exo(w k) or c cur(1) nores one}{p_end}
{phang2}. {stata xtreg n w k, fe}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}


{marker references}{...}
{title:References}

{phang}
Ahn, S. C., and P. Schmidt. 1995.
Efficient estimation of models for dynamic panel data.
{it:Journal of Econometrics} 68: 5-27.

{phang}
Anderson, T. W., and C. Hsiao. 1981.
Estimation of dynamic models with error components.
{it:Journal of the American Statistical Association} 76: 598-606.

{phang}
Arellano, M., and S. R. Bond. 1991.
Some tests of specification for panel data: Monte Carlo evidence and an application to employment equations.
{it:Review of Economic Studies} 58: 277-297.

{phang}
Arellano, M., and O. Bover. 1995.
Another look at the instrumental variable estimation of error-components models.
{it:Journal of Econometrics} 68: 29-51.

{phang}
Blundell, R., and S. R. Bond. 1998.
Initial conditions and moment restrictions in dynamic panel data models.
{it:Journal of Econometrics} 87: 115-143.

{phang}
Chudik, A., and M. H. Pesaran. 2022.
An augmented Anderson-Hsiao estimator for dynamic short-T panels.
{it:Econometric Reviews} 41: 416-447.

{phang}
Hansen, L. P., J. Heaton, and A. Yaron. 1996.
Finite-sample properties of some alternative GMM estimators.
{it:Journal of Business & Economic Statistics} 14: 262-280.

{phang}
Hayakawa, K., M. Qi, and J. Breitung. 2019.
Double filter instrumental variable estimation of panel data models with weakly exogenous variables.
{it:Econometric Reviews} 38: 1055-1088.
