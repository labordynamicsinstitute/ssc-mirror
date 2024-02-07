{smcl}
{* *! version 1.4.2  06feb2024}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{* *! Vasilis Sarafidis, sites.google.com/view/vsarafidis}{...}
{vieweralsosee "spxtivdfreg" "help spxtivdfreg"}{...}
{vieweralsosee "xtivdfreg" "help xtivdfreg"}{...}
{vieweralsosee "xtivdfreg postestimation" "help xtivdfreg_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] predict" "help predict"}{...}
{vieweralsosee "[SP] spivregress postestimation" "help spivregress_postestimation"}{...}
{viewerjumpto "Postestimation commands" "xtivdfreg_postestimation##description"}{...}
{viewerjumpto "estat" "xtivdfreg_postestimation##estat"}{...}
{viewerjumpto "Author" "xtivdfreg_postestimation##authors"}{...}
{viewerjumpto "References" "xtivdfreg_postestimation##references"}{...}
{title:Title}

{p2colset 5 35 37 2}{...}
{p2col :{bf:spxtivdfreg postestimation} {hline 2}}Postestimation tools for spxtivdfreg{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following postestimation commands are of special interest after {cmd:spxtivdfreg}:

{synoptset 13}{...}
{p2coldent:Command}Description{p_end}
{synoptline}
{synopt:{helpb spxtivdfreg postestimation##estat:estat impact}}direct, indirect, and total impacts{p_end}
{synopt:{helpb spxtivdfreg postestimation##estat:estat overid}}perform test of overidentifying restrictions{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The following standard postestimation commands are available:

{synoptset 13}{...}
{p2coldent:Command}Description{p_end}
{synoptline}
{p2col:{helpb estat}}VCE and estimation sample summary{p_end}
INCLUDE help post_estimates
INCLUDE help post_hausman
INCLUDE help post_lincom
INCLUDE help post_margins
INCLUDE help post_marginsplot
INCLUDE help post_nlcom
{synopt:{helpb spxtivdfreg postestimation##predict:predict}}predictions and residuals{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:{help xtivdfreg_postestimation##predict_statistics:statistic}}]


{marker predict_statistics}{...}
{synoptset 13 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{syntab:Main}
{synopt:{opt rf:orm}}reduced-form prediction; the default{p_end}
{synopt:{opt direct}}prediction of the direct mean{p_end}
{synopt:{opt indirect}}prediction of the indirect mean{p_end}
{synopt:{opt na:ive}}naive-form prediction{p_end}
{synopt:{opt xb}}linear prediction{p_end}
{synopt:{opt r:esiduals}}residuals{p_end}
{synoptline}
{p2colreset}{...}


{title:Description for predict}

{pstd}
{cmd:predict} creates a new variable containing predictions such as fitted values and residuals.


{title:Options for predict}

{dlgtab:Main}

{phang}
{opt rform} calculates the reduced-form prediction, which is the predicted mean of the dependent variable conditional on the independent variables and any spatial lags of the independend variables. This is the default.

{phang}
{opt direct} calculates the prediction of the direct mean, which is a group's predicted contribution to its reduced-form mean.

{phang}
{opt indirect} calculates the prediction of the indirect mean, which is the predicted contribution of all other groups to the reduced-form mean, i.e. the predicted contribution to the direct mean subtracted from the reduced-form prediction.

{phang}
{opt naive} calculates the naive-form prediction, which is the linear prediction from the fitted model.

{phang}
{opt xb} calculates the linear prediction from the fitted model, ignoring the spatial lag of the dependent variable.

{phang}
{opt residuals} calculates the residuals, i.e. the naive-form prediction subtracted from {it:depvar}.


{marker estat}{...}
{title:Syntax for estat}

{phang}
Direct, indirect, and total impacts

{p 8 16 2}
{cmd:estat} {cmdab:impact} [{varlist}] [{cmd:,} {opt sr}|{opt lr} {opt cons:tant} {opt post} {opt force} {it:display_options}]

{phang}
Hansen tests of overidentifying restrictions

{p 8 16 2}
{cmd:estat} {cmdab:over:id}


{title:Description for estat}

{pstd}
{cmd:estat impact} estimates the mean of the direct, indirect, and total impacts of the independent variables in {it:varlist} on the reduced-form mean of the dependent variable.
By default, the impacts of all independent variables in the fitted model are computed.

{pstd}
{cmd:estat overid} reports the Hansen (1982) J-statistic which is used to determine the validity of the overidentifying restrictions.


{title:Options for estat}

{phang}
{opt constant} with {cmd:estat impact} requests to also compute the impacts for the constant term. By default, this is suppressed.

{phang}
{opt sr} with {cmd:estat impact} requests to compute the short-run impacts. This is the default.

{phang}
{opt lr} with {cmd:estat impact} requests to compute the long-run impacts instead of the short-run impacts.

{phang}
{opt post} with {cmd:estat impact} replaces the coefficient vector {cmd:e(b)} in the saved estimation results by the vector of direct, indirect, and total impacts, and accordingly for the variance-covariance matrix {cmd:e(V)}.
This allows the subsequent use of other postestimation commands, such as the calculation of linear combinations of impacts or tests for linear hypotheses; see {helpb lincom:[R] lincom} and {helpb test:[R] test}, respectively.
The original estimation results can only be recovered by refitting the original model with {cmd:spxtivdfreg}, or by storing the estimation results before calling {cmd: estat impact} and then restoring them;
see {helpb estimates_store:[R] estimates store}.

{phang}
{opt force} with {cmd:estat impact} ignores a potential violation of the model's stability conditions and forces the computation of the impacts.
By default, if the estimated spatial lag coefficient is larger than the inverse maximum eigenvalue of the spatial weights matrix, {cmd:estat impact} stops with an error message.
For long-run impacts, an additional stability condition is that the sum of time lags, spatial lag, and spatial time lags coefficients must not exceed the inverse maximum eigenvalue of the spatial weights matrix.

{phang}
{it:display_options}: {opt level(#)} and other {it:{help xtivdfreg##display_options:display_options}}; see {helpb xtivdfreg}.


{title:Remarks for estat}

{pstd}
The standard errors for the direct, indirect, and total impacts are computed with the Delta method.

{pstd}
In order to correctly compute long-run impacts, time lags and spatial time lags of {it:depvar} must be specified with options {opt tlags(#)} and {opt sptlags(#)} of {cmd:spxtivdfreg}, respectively.
They must not be specified directly in the {it:indepvars} or {opt spindevars(varlist)} lists.

{pstd}
If the regression model contains distributed lags of {it:indepvars} or spatially lagged {it:indepvars}, {cmd:estat impact} does not automatically add up their effects when computing long-run impacts.
This needs to be done manually by calling {cmd:estat impact} with option {opt post} and subsequently running the {helpb lincom} command.

{pstd}
The overidentification test statistic is constructed as a quadratic form of the moment functions with an asymptotically optimal weighting matrix. The latter is based on the first-stage residuals.
The test is not valid and therefore not reported for a model with heterogeneous slopes that is estimated with the mean-group estimator.


{marker example}{...}
{title:Example}

{pstd}Setup (requires Stata version 15 or higher){p_end}
{pstd}(The data set and spatial weights matrix are available as ancillary files for the {cmd:xtivdfreg} package.){p_end}
{phang2}. {stata "use http://www.kripfganz.de/stata/spxtivdfreg_example"}{p_end}
{phang2}. {stata "copy http://www.kripfganz.de/stata/spxtivdfreg_example_spmat.stswm ."}{p_end}
{phang2}. {stata spmatrix use W using spxtivdfreg_example_spmat}{p_end}

{pstd}Defactored IV estimation with spatial lag and time lag, homogeneous slopes{p_end}
{phang2}. {stata spxtivdfreg NPL INEFF CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, absorb(ID) splag tlags(1) spmatrix(W) iv(INTEREST CAR SIZE BUFFER PROFIT QUALITY LIQUIDITY, splags lag(1)) std}{p_end}

{pstd}Short-run and long-run impacts{p_end}
{phang2}. {stata estat impact, sr}{p_end}
{phang2}. {stata estat impact, lr}{p_end}


{marker results}{...}
{title:Saved results}

{pstd}
{cmd:estat impact} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}vector of impacts{p_end}
{synopt:{cmd:r(V)}}variance-covariance matrix of the impacts{p_end}
{p2colreset}{...}

{pstd}
{cmd:estat overid} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(chi2)}}Hansen's J-statistic{p_end}
{synopt:{cmd:r(df)}}degrees of freedom of Hansen's J-test{p_end}
{synopt:{cmd:r(p)}}p-value of Hansen's J-test{p_end}
{p2colreset}{...}


{marker authors}{...}
{title:Author}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}

{pstd}
Vasilis Sarafidis, Brunel University London, {browse "https://sites.google.com/view/vsarafidis"}


{marker references}{...}
{title:References}

{phang}
Hansen, L. P. 1982.
Large sample properties of generalized method of moments estimators.
{it:Econometrica} 50: 1029-1054.
