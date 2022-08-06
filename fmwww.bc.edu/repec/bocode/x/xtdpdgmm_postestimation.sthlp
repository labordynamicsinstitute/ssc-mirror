{smcl}
{* *! version 2.6.2  03aug2022}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{vieweralsosee "xtdpdgmm" "help xtdpdgmm"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] predict" "help predict"}{...}
{vieweralsosee "[R] gmm postestimation" "help gmm_postestimation"}{...}
{vieweralsosee "[XT] xtreg postestimation" "help xtreg_postestimation"}{...}
{vieweralsosee "[XT] xtdpd postestimation" "help xtdpd_postestimation"}{...}
{viewerjumpto "Postestimation commands" "xtdpdgmm_postestimation##description"}{...}
{viewerjumpto "predict" "xtdpdgmm_postestimation##predict"}{...}
{viewerjumpto "estat" "xtdpdgmm_postestimation##estat"}{...}
{viewerjumpto "Example" "xtdpdgmm_postestimation##example"}{...}
{viewerjumpto "Author" "xtdpdgmm_postestimation##author"}{...}
{viewerjumpto "References" "xtdpdgmm_postestimation##references"}{...}
{title:Title}

{p2colset 5 32 34 2}{...}
{p2col :{bf:xtdpdgmm postestimation} {hline 2}}Postestimation tools for xtdpdgmm{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following postestimation commands are of special interest after {cmd:xtdpdgmm}:

{synoptset 15 tabbed}{...}
{p2coldent:Command}Description{p_end}
{synoptline}
{synopt:{helpb xtdpdgmm postestimation##estat:estat serial}}perform test for autocorrelated residuals{p_end}
{synopt:{helpb xtdpdgmm postestimation##estat:estat serialpm}}perform portmanteau test for autocorrelated residuals{p_end}
{synopt:{helpb xtdpdgmm postestimation##estat:estat overid}}perform tests of overidentifying restrictions{p_end}
{synopt:{helpb xtdpdgmm postestimation##estat:estat hausman}}perform generalized Hausman test{p_end}
{synopt:{helpb xtdpdgmm postestimation##estat:estat mmsc}}obtain model and moment selection criteria{p_end}
{p2coldent :* {helpb underid}}underidentification tests{p_end}
{p2coldent :* {helpb overid}}overidentification tests{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* These community-contributed commands need to be installed separately.{p_end}

{pstd}
The following standard postestimation commands are available:

{synoptset 15}{...}
{p2coldent:Command}Description{p_end}
{synoptline}
{p2col:{helpb estat}}VCE and estimation sample summary{p_end}
INCLUDE help post_estimates
INCLUDE help post_hausman
INCLUDE help post_lincom
INCLUDE help post_margins
INCLUDE help post_marginsplot
INCLUDE help post_nlcom
{synopt:{helpb xtdpdgmm postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:{help xtdpdgmm_postestimation##predict_statistics:statistic}}]

{p 8 16 2}
{cmd:predict} {dtype} [{c -(}{it:stub*}{c |}{it:{help newvar:newvar1}} ... {it:{help newvar:newvarq}}{c )-}] {ifin} {cmd:,} {opt iv} [{it:{help xtdpdgmm_postestimation##predict_options:options}}]

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
{p2coldent:* {opt xbu}}calculate prediction including group-specific error component{p_end}
{p2coldent:* {opt u}}calculate the the group-specific error component{p_end}
{p2coldent:* {opt e}}calculate the idiosyncratic error component{p_end}
{p2coldent:* {opt iv}}generate instrumental variables used in the estimation{p_end}
{p2coldent:* {opt sc:ores}}calculate parameter-level scores{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help unstarred

{marker predict_options}{...}
{synoptset 13 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Options}
{p2coldent :# {opt nogen:erate}}do not generate new variables{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}# The option {cmd:nogenerate} is available only in combination with option {cmd:iv}.{p_end}


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
{opt iv} generates the instrumental variables that are associated with the linear moment conditions, excluding the constant term. All instrumental variables are transformed appropriately such that they become instruments for the model in levels.
This option requires that the length of the new variable list be equal to the number of linearly independent instrumental variables excluding the constant term, unless the option {opt nogenerate} is specified.
A list of the instrumental variables is displayed as well, including the constant term, if any.

{phang}
{opt scores} calculates the parameter-level scores for all independent variables, the first derivatives of the criterion function with respect to the coefficients (scaled by -0.5);
see {helpb gmm postestimation##option_predict:[R] gmm postestimation}. This option requires that the length of the new variable list be equal to the number of independent variables including the constant term, if any.
The Windmeijer (2005) finite-sample correction is taken into account whenever appropriate. A small-sample degrees-of-freedom correction is made if option {opt small} was specified with {cmd:xtdpdgmm}.

{dlgtab:Options}

{phang}
{opt nogenerate} displays the list of instrumental variables but does not generate new variables.


{marker estat}{...}
{title:Syntax for estat}

{phang}
Arellano-Bond test for no autocorrelation in the residuals

{p 8 16 2}
{cmd:estat} {cmdab:ser:ial} [, {opth o:rder(numlist)}]

{phang}
Jochmans portmanteau test for no autocorrelation in the residuals

{p 8 16 2}
{cmd:estat} {cmdab:serialpm} [, {opt d:ifference} {opt c:ollapse} {opth o:rder(numlist)}]

{phang}
Sargan-Hansen tests of overidentifying restrictions

{p 8 16 2}
{cmd:estat} {cmdab:over:id} [{it:name}], [{opt d:ifference}]

{phang}
Generalized Hausman test for model misspecification

{p 8 16 2}
{cmd:estat} {cmdab:haus:man} {it:name} [{cmd:(}{varlist}{cmd:)}] [, {opt df(#)} {opt none:sted}]

{phang}
Andrews-Lu model and moment selection criteria

{p 8 16 2}
{cmd:estat} {cmdab:mmsc} [{it:namelist}] [, {cmd:n(}{opt gr:oups}|{opt cl:uster}|{opt obs)} {opt hq(#)}]

{p 4 6 2}
where {it:name} is a name under which estimation results were stored via {helpb estimates store:estimates store}, and {it:namelist} is a list of such names.


{title:Description for estat}

{pstd}
{cmd:estat serial} reports the Arellano and Bond (1991) test for absence of autocorrelation in the first-differenced residuals at specific orders.

{pstd}
{cmd:estat serialpm} reports the the heteroskedasticity-robust Jochmans (2020) portmanteau test for absence of autocorrelation in the idiosyncratic error component at any order.

{pstd}
{cmd:estat serialpm, difference collapse} and {cmd:estat serialpm, difference collapse order(}{it:#}{cmd:)} report the Yamagata (2008) and Arellano and Bond (1991) tests for absence of autocorrelation in the first-differenced residuals
at any order or order {it:#}, respectively.

{pstd}
{cmd:estat overid} reports the Sargan (1958) and Hansen (1982) J-statistic which is used to determine the validity of the overidentifying restrictions. Two versions of the test are reported for the one-step and two-step GMM estimators.
The first version uses the weighting matrix from the final estimation step. The second version updates the weighting matrix one more time based on the residuals from the final estimation step.
The moment functions are evaluated at the final-step estimates in any case. After {helpb xtdpdgmm} with option {cmd:onestep} or {cmd:twostep}, these are the one-step or two-step estimates, respectively.

{pstd}
{cmd:estat overid, difference} reports the Sargan-Hansen statistics for the reduced models, leaving out one subset of moment conditions at a time without reestimating the weighting matrix.
It also reports the corresponding Sargan-Hansen difference statistics as proposed by Newey (1985) and Eichenbaum, Hansen, and Singleton (1988), which are used to determine the validity of the omitted subset of overidentifying restrictions.

{pstd}
{cmd:estat overid} {it:name} reports a Sargan-Hansen difference statistic as proposed by Eichenbaum, Hansen, and Singleton (1988), which is used to determine the validity of a subset of overidentifying restrictions.
It is computed as the difference between the respective J-statistics from the most recent {helpb xtdpdgmm} estimation results and the estimation results stored as {it:name} by using {helpb estimates store:estimates store}.

{pstd}
{cmd:estat hausman} reports a generalized Hausman (1978) test for model misspecification by comparing the coefficient estimates of {it:varlist} from the most recent {helpb xtdpdgmm} estimation results
to the corresponding coefficient estimation results stored as {it:name} by using {helpb estimates store:estimates store}. By default, the coefficients of all {it:indepvars} are contrasted, excluding the constant term.
This generalized test does not require one of the estimators to be efficient. It uses the cluster-robust variance-covariance estimator for the test statistic suggested by White (1982),
which is computed using the parameter-level scores; see {helpb suest:[R] suest}.

{pstd}
{cmd:estat mmsc} reports the Akaike (AIC), Bayesian (BIC), and Hannan-Quinn (HQIC) versions of the Andrews and Lu (2001) model and moment selection criterion.
If {it:namelist} is specified, it lists the criteria for the most recent {helpb xtdpdgmm} estimation and all estimations specified in {it:namelist}, previously stored by using {helpb estimates store:estimates store}.


{title:Options for estat}

{phang}
{opth order(numlist)} with {cmd:estat serial} or {cmd:estat serialpm} specifies the orders of serial correlation to be tested with the Arellano-Bond test. With {cmd:estat serial}, the default is {cmd:ar(1 2)}.
With {cmd:estat serialpm}, the default is to test for serial correlation of any order.

{phang}
{opt difference} with {cmd:estat serialpm} requests to compute tests for serial correlation of the first-differenced residuals instead of the the untransformed idiosyncratic error component.

{phang}
{opt collapse} with {cmd:estat serialpm} requests to compute a collapsed version of the test, which consumes only one degree of freedom for each order of serial correlation.

{phang}
{opt difference} with {cmd:estat overid} requests to report Sargan-Hansen difference statistics for a subset of the overidentifying restrictions. This option requires that option {opt overid} was specified with {helpb xtdpdgmm}.

{phang}
{opt df(#)} with {cmd:estat hausman} specifies the degrees of freedom for the test.
The default is the difference in the number of overidentifying restrictions from the two estimations or the number of contrasted coefficients, whichever is smaller.

{phang}
{opt nonested} with {cmd:estat hausman} specifies that the two estimators are not nested in terms of the moment conditions they employ. This option implies that the degrees of freedom for the test equal the number of contrasted coefficients.

{phang}
{cmd:n(groups}|{cmd:cluster}|{cmd:obs)} with {cmd:estat mmsc} specifies whether the penalty term for the MMSC-BIC and MMSC-HQIC criteria is calculated based on the number of groups, {cmd:n(groups)},
the number of clusters, {cmd:n(cluster)}, or the number of observations, {cmd:n(obs)}. The default is {cmd:n(cluster)} if option {cmd:vce(cluster }{it:clustvar}{cmd:)} was specified with {helpb xtdpdgmm}, and {cmd:n(groups)} otherwise.

{phang}
{opt hq(#)} with {cmd:estat mmsc} specifies the Hannan-Quinn scaling factor for the correction term of the MMSC-HQIC criterion. The default is {cmd:hq(1.01)}.


{title:Remarks for estat}

{pstd}
Remarks are presented under the following headings:

{phang2}{help xtdpdgmm_postestimation##remarks_serial:Serial correlation tests}{p_end}
{phang2}{help xtdpdgmm_postestimation##remarks_overid:Overidentification tests}{p_end}
{phang2}{help xtdpdgmm_postestimation##remarks_mmsc:Model and moment selection criteria}{p_end}


{marker remarks_serial}{...}
{title:Serial correlation tests}

{pstd}
The Arellano and Bond (1991) test considers the null hypothesis of no autocorrelation of the first-differenced residuals at a specified order. If the untransformed idiosyncratic error component is serially uncorrelated,
it is expected to find first-order autocorrelation but no higher-order autocorrelation of the first-differenced residuals. If {cmd:vce(robust)} or {cmd:vce(cluster} {it:clustvar}{cmd:)} is specified with {helpb xtdpdgmm},
a cluster-robust version is computed with {cmd:estat serial}.

{pstd}
The Jochmans (2020) portmanteau test is a joint test for the null hypothesis of no autocorrelation of the idiosyncratic error component at any order. It is robust to heteroskedasticity irrespective of the chosen variance-covariance estimator.
By default, for each order of autocorrelation a separate restriction is included in the test for every time period. When the number of time periods is large, the portmanteau test therefore consumes a large number of degrees of freedom,
which can result in a loss of power.

{pstd}
Restricted versions of the portmanteau test can be obtained by forming linear combinations of the tested moment conditions. Option {opt difference} of {cmd:estat serialpm} limits the test to autocorrelation of the first-differenced residuals.
Option {opt collapse} combines moments for the same order of autocorrelation over all time periods into a single restriction. Option {opt order(numlist)} limits the test to autocorrelation of orders specified in {it:numlist}.
Combining options {opt difference} and {opt collapse} yields the Yamagata (2008) test for the joint null hypothesis of no autocorrelation of the first-differenced residuals at any order.

{pstd}
{cmd:estat serial, }{opt order(#)} and {cmd:estat serialpm, difference collapse }{opt order(#)} compute equivalent Arellano and Bond (1991) tests for order {it:#}. However, due to different ways of computing the test statistics,
they will not be numerically identical in finite samples. If multiple orders are specified with option {opt order(numlist)}, the two commands produce different tests.
{cmd:estat serial} computes separate tests for each order of autocorrelation, while {cmd:estat serialpm} computes a joint test for the specified orders of autocorrelation.


{marker remarks_overid}{...}
{title:Overidentification tests}

{pstd}
The overidentification tests are asymptotically invalid after {helpb xtdpdgmm} with option {cmd:onestep} if the one-step weighting matrix is not optimal.
This is true even for the version of the test with updated weighting matrix because the one-step estimates remain inefficient.

{pstd}
The Sargan (1958) or Hansen (1982) difference test statistics reported by {cmd:estat overid, difference} are guaranteed to be nonnegative because all statistics are based on the same weighting matrix from the full model.
This is not the case when calling {cmd:estat overid} with a {it:name} of stored estimation results. Asymptotically, both versions are equivalent.

{pstd}
For the Sargan-Hansen difference test statistic to be valid, the two estimators need to be nested in terms of the moment conditions they employ. When calling {cmd:estat overid} with a {it:name} of stored estimation results,
it is the user's responsibility to verify that {it:name} is indeed nested in the last estimated model, or vice versa. The test statistic is computed as the difference of Sargan-Hansen J-statistics from the two estimations,
subtracting the J-statistic with the smaller degrees of freedom from the one with the larger degrees of freedom.

{pstd}
The generalized Hausman test can be used as an asymptotically equivalent test to the Sargan-Hansen difference test if the two estimators are nested
and the number of the excluded overidentifying restrictions does not exceed the number of contrasted coefficients. This test statistic is guaranteed to be nonnegative but it might have poor coverage in finite samples.


{marker remarks_mmsc}{...}
{title:Model and moment selection criteria}

{pstd}
The Andrews-Lu model and moment selection criteria can be used to find an optimal model among competing specifications.
These criteria combine the Sargan-Hansen test statistic with a bonus term that rewards fewer coefficients for a given number of moment conditions or more moment conditions for a given number of coefficients.
Smaller values of the model and moment selection criteria are preferred.


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}. {stata webuse abdata}{p_end}

{pstd}Two-step difference GMM estimator with predetermined covariates{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n w k, l(1 4)) m(d) c two vce(r)}{p_end}
{phang2}. {stata estimates store ab}{p_end}

{pstd}Jochmans portmanteau test for no autocorrelation{p_end}
{phang2}. {stata estat serialpm}{p_end}

{pstd}Yamagata test for no autocorrelation{p_end}
{phang2}. {stata estat serialpm, difference collapse}{p_end}

{pstd}Arellano-Bond test for no autocorrelation{p_end}
{phang2}. {stata estat serial, order(1/3)}{p_end}
{phang2}. {stata estat serialpm, difference collapse order(2)}{p_end}
{phang2}. {stata estat serialpm, difference collapse order(3)}{p_end}

{pstd}Sargan-Hansen test for the validity of the overidentifying restrictions{p_end}
{phang2}. {stata estat overid}{p_end}

{pstd}Two-step system GMM estimator with predetermined covariates{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, gmm(L.n w k, l(1 4) m(d)) iv(L.n w k, d) two c vce(r) overid}{p_end}

{pstd}Sargan-Hansen difference test for the additional level moment conditions{p_end}
{phang2}. {stata estat overid, difference}{p_end}
{phang2}. {stata estat overid ab}{p_end}

{pstd}Generalized Hausman test for the additional level moment conditions{p_end}
{phang2}. {stata estat hausman ab}{p_end}

{pstd}Andrews-Lu model and moment selection criteria{p_end}
{phang2}. {stata estat mmsc ab}{p_end}

{pstd}Instrumental variables used in the estimation{p_end}
{phang2}. {stata predict double iv*, iv}{p_end}

{pstd}Replication of the system GMM estimates with the generated instruments{p_end}
{phang2}. {stata xtdpdgmm L(0/1).n w k, iv(iv*) two vce(r)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}


{marker references}{...}
{title:References}

{phang}
Andrews, D. W. K., and B. Lu. 2001.
Consistent model and moment selection procedures for GMM estimation with application to dynamic panel data models.
{it:Journal of Econometrics} 101: 123-164.

{phang}
Arellano, M., and S. R. Bond. 1991.
Some tests of specification for panel data: Monte Carlo evidence and an application to employment equations.
{it:Review of Economic Studies} 58: 277-297.

{phang}
Eichenbaum, M. S., L. P. Hansen, and K. J. Singleton. 1988.
A time series analysis of representative agent models of consumption and leisure choice under uncertainty.
{it:Quarterly Journal of Economics} 103: 51-78.

{phang}
Hansen, L. P. 1982.
Large sample properties of generalized method of moments estimators.
{it:Econometrica} 50: 1029-1054.

{phang}
Hausman, J. A. 1978.
Specification tests in econometrics.
{it:Econometrica} 46: 1251-1271.

{phang}
Jochmans, K. 2020.
Testing for correlation in error-component models.
{it: Journal of Applied Econometrics} 35: 860-878.

{phang}
Newey, W. K. 1985.
Generalized method of moments specification testing.
{it:Journal of Econometrics} 29: 229-256.

{phang}
Sargan, J. D. 1958.
The estimation of economic relationships using instrumental variables.
{it:Econometrica} 26: 393-415.

{phang}
White, H. L. 1982.
Maximum likelihood estimation of misspecified models.
{it:Econometrica} 50: 1-25.

{phang}
Windmeijer, F. 2005.
A finite sample correction for the variance of linear efficient two-step GMM estimators.
{it:Journal of Econometrics} 126: 25-51.

{phang}
Yamagata, T. 2008.
A joint serial correlation test for linear panel data models.
{it:Journal of Econometrics} 146: 135-145.
