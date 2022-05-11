{smcl}
{* *! version 1.2.1  09apr2022}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{vieweralsosee "xtdpdbc" "help xtdpdbc"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] predict" "help predict"}{...}
{vieweralsosee "[XT] xtreg postestimation" "help xtreg_postestimation"}{...}
{vieweralsosee "[XT] xtdpd postestimation" "help xtdpd_postestimation"}{...}
{viewerjumpto "Postestimation commands" "xtdpdbc_postestimation##description"}{...}
{viewerjumpto "predict" "xtdpdbc_postestimation##predict"}{...}
{viewerjumpto "estat" "xtdpdbc_postestimation##estat"}{...}
{viewerjumpto "Example" "xtdpdbc_postestimation##example"}{...}
{viewerjumpto "Authors" "xtdpdbc_postestimation##authors"}{...}
{viewerjumpto "References" "xtdpdbc_postestimation##references"}{...}
{title:Title}

{p2colset 5 32 34 2}{...}
{p2col :{bf:xtdpdbc postestimation} {hline 2}}Postestimation tools for xtdpdbc{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following postestimation commands are of special interest after {cmd:xtdpdbc}:

{synoptset 13}{...}
{p2coldent:Command}Description{p_end}
{synoptline}
{synopt:{helpb xtdpdbc postestimation##estat:estat serial}}perform test for autocorrelated residuals{p_end}
{synopt:{helpb xtdpdbc postestimation##estat:estat overid}}perform test of overidentifying restrictions{p_end}
{synopt:{helpb xtdpdbc postestimation##estat:estat hausman}}perform generalized Hausman test{p_end}
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
{synopt:{helpb xtdpdbc postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:{help xtdpdbc_postestimation##predict_statistics:statistic}}]

{p 8 16 2}
{cmd:predict} {dtype} {c -(}{it:stub*}{c |}{it:{help newvar:newvar1}} ... {it:{help newvar:newvarq}}{c )-} {ifin} {cmd:,} {opt sc:ores}


{marker predict_statistics}{...}
{synoptset 13 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{syntab:Main}
{synopt:{opt xb}}calculate linear prediction; the default{p_end}
{synopt:{opt stdp}}calculate standard error of the prediction{p_end}
{synopt:{opt ue}}calculate the combined residual{p_end}
{p2coldent:* {opt xbu}}calculate prediction including unit-specific error component{p_end}
{p2coldent:* {opt u}}calculate the the unit-specific error component{p_end}
{p2coldent:* {opt e}}calculate the idiosyncratic error component{p_end}
{p2coldent:* {opt sc:ores}}calculate parameter-level scores{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help unstarred


{title:Description for predict}

{pstd}
{cmd:predict} creates a new variable containing predictions such as fitted values, standard errors, and residuals.


{title:Options for predict}

{dlgtab:Main}

{phang}
{opt xb} calculates the linear prediction from the fitted model; see {helpb predict##options:[R] predict}. This is the default.

{phang}
{opt stdp} calculates the standard error of the linear prediction; see {helpb predict##options:[R] predict}.

{phang}
{opt ue} calculates the prediction of u_i + e_it, the combined residual; see {helpb xtreg postestimation##options_predict:[XT] xtreg postestimation}.

{phang}
{opt xbu} calculates the linear prediction including the group-specific error component; see {helpb xtreg postestimation##options_predict:[XT] xtreg postestimation}.

{phang}
{opt u} calculates the prediction of u_i, the estimated group-specific error component; see {helpb xtreg postestimation##options_predict:[XT] xtreg postestimation}.

{phang}
{opt e} calculates the prediction of e_it; see {helpb xtreg postestimation##options_predict:[XT] xtreg postestimation}.

{phang}
{opt scores} calculates the parameter-level scores for all independent variables, the first derivatives of the criterion function with respect to the coefficients.
This option requires that the length of the new variable list be equal to the number of independent variables including the constant term, if any.


{marker estat}{...}
{title:Syntax for estat}

{phang}
Arellano-Bond test for autocorrelated residuals

{p 8 16 2}
{cmd:estat} {cmdab:ser:ial} [, {opth ar(numlist)}]

{phang}
Sargan-Hansen test of overidentifying restrictions

{p 8 16 2}
{cmd:estat} {cmdab:over:id}

{phang}
Generalized Hausman test for model misspecification

{p 8 16 2}
{cmd:estat} {cmdab:haus:man} {it:name} [{cmd:(}{varlist}{cmd:)}] [, {opt df(#)}]


{title:Description for estat}

{pstd}
{cmd:estat serial} reports the Arellano and Bond (1991) test for autocorrelation of the first-differenced residuals. A robust version is computed if {cmd:vce(robust)} is specified with {helpb xtdpdbc}.

{pstd}
{cmd:estat overid} reports the Sargan (1958) or Hansen (1982) J-statistic which is used to determine the validity of the overidentifying restrictions.

{pstd}
{cmd:estat hausman} reports a generalized Hausman (1978) test for model misspecification by comparing the coefficient estimates of {it:varlist} from the most recent {helpb xtdpdbc} estimation results
to the corresponding coefficient estimation results stored as {it:name} by using {helpb estimates store:estimates store}. By default, the coefficients of all {it:indepvars} are contrasted, excluding the constant term.
This generalized test uses the cluster-robust variance-covariance estimator for the test statistic suggested by White (1982), which is computed using the parameter-level scores; see {helpb suest:[R] suest}.


{title:Options for estat}

{phang}
{opth ar(numlist)} with {cmd:estat serial} specifies the orders of serial correlation to be tested. The default is {cmd:ar(1 2)}.

{phang}
{opt df(#)} with {cmd:estat hausman} specifies the degrees of freedom for the test.
The default is the difference in the number of overidentifying restrictions from the two estimations or the number of contrasted coefficients, whichever is smaller.


{title:Remarks for estat}

{pstd}
Even though the bias-corrected estimator does not transform the model into first differences, the serial correlation test is performed on the first-differenced residuals as originally suggested by Arellano and Bond (1991).
If the untransformed idiosyncratic error component is serially uncorrelated, then there will be first-order but no higher-order serial correlation in the first-differenced errors.

{pstd}
The Sargan-Hansen test is only available for random-effects or hybrid models because the fixed-effects estimator is just-identified.
The Sargan test after the one-step estimator is asymptotically invalid, unless there are no unobserved group-specific effects. The Hansen test after the two-step estimator should be considered instead.

{pstd}
Under a random-effects assumption, when the panel data set is unbalanced and time effects are included, time dummies will be used as instruments both for the model in deviations from within-group means and the model in levels.
The additional instruments for the model in levels are asymptotically redundant, even though some of them are not numerically redundant in finite samples.
When {helpb xtdpdbc} is specified with option {opt teffects}, {cmd:estat overid} adjusts the degrees of freedom accordingly by ignoring the time dummy instruments for the model in levels.

{pstd}
The generalized Hausman test can be used as an asymptotically equivalent test to the Sargan-Hansen test if a random-effects (or hybrid) estimator is constrasted with a fixed-effects estimator.
This test statistic is guaranteed to be nonnegative but it might have poor coverage in finite samples.


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}{stata webuse psidextract:. webuse psidextract}{p_end}

{pstd}Bias-corrected fixed-effects estimator with AR(2) dynamics{p_end}
{phang2}{stata xtdpdbc lwage wks south smsa ms exp exp2 occ ind union, lags(2):. xtdpdbc lwage wks south smsa ms exp exp2 occ ind union, lags(2)}{p_end}
{phang2}{stata estimates store fe:. estimates store fe}{p_end}

{pstd}Arellano-Bond test for autocorrelation of the first-differenced residuals{p_end}
{phang2}{stata estat serial, ar(1/3):. estat serial, ar(1/3)}{p_end}

{pstd}Bias-corrected random-effects estimator with AR(2) dynamics{p_end}
{phang2}{stata xtdpdbc lwage wks south smsa ms exp exp2 occ ind union, re lags(2):. xtdpdbc lwage wks south smsa ms exp exp2 occ ind union, re lags(2)}{p_end}

{pstd}Hansen test for the validity of the overidentifying restrictions{p_end}
{phang2}{stata estat overid:. estat overid}{p_end}

{pstd}Generalized Hausman test{p_end}
{phang2}{stata estat hausman fe:. estat hausman fe}{p_end}


{marker authors}{...}
{title:Authors}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}

{pstd}
J{c o:}rg Breitung, University of Cologne, {browse "https://wisostat.uni-koeln.de/en/institute/professors/breitung"}


{marker references}{...}
{title:References}

{phang}
Arellano, M., and S. R. Bond. 1991.
Some tests of specification for panel data: Monte Carlo evidence and an application to employment equations.
{it:Review of Economic Studies} 58: 277-297.

{phang}
Hansen, L. P. 1982.
Large sample properties of generalized method of moments estimators.
{it:Econometrica} 50: 1029-1054.

{phang}
Hausman, J. A. 1978.
Specification tests in econometrics.
{it:Econometrica} 46: 1251-1271.

{phang}
Sargan, J. D. 1958.
The estimation of economic relationships using instrumental variables.
{it:Econometrica} 26: 393-415.

{phang}
White, H. L. 1982.
Maximum likelihood estimation of misspecified models.
{it:Econometrica} 50: 1-25.
