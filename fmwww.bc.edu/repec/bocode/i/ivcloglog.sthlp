{smcl}
{hline}
Help for {cmd:ivcloglog} version 1.0.0{center:William Liu (刘威廉)}{right:1 September 2023}
{hline}
{vieweralsosee "ivprobit" "help ivprobit"}{...}
{vieweralsosee "cloglog" "help cloglog"}{...}
{vieweralsosee "stcox" "help stcox"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Quick Start" "ivcloglog##quick_start"}{...}
{viewerjumpto "Detailed Syntax" "ivcloglog##detailed_syntax"}{...}
{viewerjumpto "Dependencies" "ivcloglog##dependencies"}{...}
{viewerjumpto "Description" "ivcloglog##description"}{...}
{viewerjumpto "Options" "ivcloglog##options"}{...}
{viewerjumpto "Remarks" "ivcloglog##remarks"}{...}
{viewerjumpto "Examples" "ivcloglog##examples"}{...}
{viewerjumpto "Stored Results" "ivcloglog##stored_results"}{...}
{viewerjumpto "Author" "ivcloglog##author"}{...}
{viewerjumpto "Acknowledgements" "ivcloglog##acknowledgements"}{...}
{viewerjumpto "References" "ivcloglog##references"}{...}
{p2colset 3 16 18 2}{...}
{p2col:{cmd:ivcloglog} {hline 2}}Complementary log-log model with continuous endogenous covariates, instrumented via the control function approach (i.e., 2SRI){p_end}
{p2col:}(For more on the complementary log-log model, see {manhelp cloglog R}.){p_end}
{p2colreset}{...}

{* ********************************************************************************************************************}
{marker quick_start}{...}
{title:Quick Start}

{p 8 17 2}
{cmd:ivcloglog}
{it:{help depvar:binary_outcome_var}}
[{it:{help varlist:controls}}]
{ifin}
{cmd:, }
{cmdab:vhat:name(}{it:string}{cmd:)}
{cmdab:endo:genous(}{it:{help varlist:endogenous_vars}} {cmd:=} {it:{help varlist:instruments}} [, {cmdab:nocon:stant}]{cmd:)}
[{cmdab:nocon:stant}
{cmd:order(}{it:integer}{cmd:)}
{cmd:vce(}{it:{help vcetype:vcetype}}{cmd:)}
{cmdab:nogen:erate}
{cmdab:diff:icult_vce}
{cmdab:show:stages}]

{* ********************************************************************************************************************}
{marker detailed_syntax}{...}
{title:Detailed Syntax}

{p 8 17 2}
{cmd:ivcloglog}
{depvar}
[{it:{help varlist:varlist_exog}}]
{ifin}
{cmd:, }
{cmdab:vhat:name(}{it:string}{cmd:)}
{cmdab:endo:genous(}{it:{help varlist:varlist_endog}} {cmd:=} {it:{help varlist:varlist_inst}} [, {it:1ststage_optional_options}]{cmd:)}
[{it:2ndstage_optional_options}]

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Required}
{synopt:{opt vhat:name(string)}}supply name of first-stage residuals{p_end}
{synopt:{opt endo:genous}{cmd:(}{help varlist:...}{cmd:)}}supply first-stage equations; all equations assumed to share the same instruments, and second-stage controls are not automatically included{p_end}

{syntab:Optional, 1st-stage}
{synopt:{opt nocon:stant}}request that no constant be added as a first-stage variable{p_end}

{syntab:Optional, 2nd-stage}
{synopt:{opt nocon:stant}}request that no constant be added as a second-stage variable{p_end}
{synopt:{opt order(integer)}}specify the desired order (i.e., degree) of the control function polynomial; 1 by default{p_end}
{synopt:{opth vce(vcetype)}}specify the desired type of variance-covariance estimate (VCE){p_end}
{synopt:{opt nogen:erate}}request that the control functions not be added to the dataset{p_end}
{synopt:{opt diff:icult_vce}}request different code for obtaining the variance-covariance matrix estimate; use this if (and only if) the default fails{p_end}
{synopt:{opt show:stages}}request that the output from the first-stage {cmd:regress} regressions and second-stage {cmd:cloglog} regression be shown{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{...}
{cmd:by} is allowed; see {manhelp by D}.{p_end}
{p 4 6 2}{...}
{it:varlist_exog} and {it:varlist_inst} may contain factor variables; see {manhelp fvvarlist U}.{p_end}
{p 4 6 2}{...}
{it:depvar}, {it:varlist_exog}, {it:varlist_endog}, and {it:varlist_inst} may contain time-series operators; see {manhelp tsvarlist U}.{p_end}

{* ********************************************************************************************************************}
{marker dependencies}{...}
{title:Dependencies}

{pstd}
(1) {cmd:moremata}, available on SSC

{* ********************************************************************************************************************}
{marker description}{...}
{title:Description}

{pstd}
{cmd:ivcloglog} is essentially the same thing as {cmd:ivprobit, twostep} but for the {cmd:cloglog} model; see {manhelp ivprobit R} and {manhelp cloglog R}.
{cmd:ivcloglog} estimates a complementary log-log model with instrumenting of endogenous variables via the control function approach (also known in statistics as 2SRI {c -} two-stage residuals inclusion).
This just means that transformed versions of the residuals of the first stage regressions (i.e., the "auxiliary models") are included as regressors in the second stage (i.e., the "primary model").
In the case of {cmd:ivcloglog}, a linear first stage and polynomial control functions are used {c -} the latter just means that powers of the residuals are used.

{pstd}
An important use case is that {cmd:ivcloglog} allows users to estimate a Prentice and Gloeckler (1978) model with continuous endogenous covariates,
just like how the basic version of the model (i.e., with all covariates exogenous) can be estimated using {cmd:cloglog}.

{pstd}
{hi:For the guide to the theory behind this, see }{err:Liu (2023)}{hi:. For the complementary empirical guide with a real-data application, see }{err:Palmer (2023)}{hi:.}

{dlgtab:A Brief Introduction to the Prentice and Gloeckler (1978) Model}

{pstd}
The Prentice and Gloeckler (1978) discrete- and grouped-time proportional hazards model
is a flexibly parametric survival model for discrete-data that is analogous to Cox's (1972) continuous-time proportional hazards model.
One convenient way to estimate it involves expressing it as a complementary log-log model (Allison, 1982; Jenkins, 1995).
This can be done through a few steps:

{p 8 8 2}
(1) If not the case already, format the data so that the observations for each entity {it:i} end after event occurrence.

{p 8 8 2}
(2) If not the case already, generate the outcome variable {c -} a binary indicator for event occurrence that is 1 in the time period of the event and 0 otherwise.

{p 8 8 2}
(3) Using the resulting dataset, simply estimate a {cmd:cloglog} model using the aforementioned outcome variable and with fixed effects for each time period included as controls.

{pstd}
(For a user-created command that automates these steps and estimates a model with exogenous covariates, see {cmd:pgmhaz8} [Jenkins, 2004].)

{pstd}
The process for estimating a model with endogenous covariates is identical, except with the use of {cmd:ivcloglog} instead of {cmd:cloglog}.

{* ********************************************************************************************************************}
{marker options}{...}
{title:Options}

{dlgtab:Required Options}

{pstd}
{opt vhat:name}{cmd:(}{it:string}{cmd:)} provides the names for the "vhats", the residuals of the first stages.
Specifically, the control function for first-stage (auxiliary model) equation {it:eq} is composed of powers of vhat with names taking the form {it:vhatname_eq_power}.

{pstd}
{opt endo:genous}{cmd:(}{help varlist}{cmd: = }{help varlist}{cmd:)}{* Note: -opt- doesn't work with just one opening parenthesis} supplies the first-stage equations (i.e., the "auxiliary models").
Specifically, each endogenous variable is linearly regressed on the instruments: the first-stage controls and external instruments (named so since the first-stage controls are technically instruments too);
you must specify what endogenous variables and instruments are to be used.
(The endogenous variables go on the left side of the "=" and the instruments go on the right side.)
Powers of the residuals from the first-stage regressions are then included as regressors in the second stage (i.e., the "primary model").
Like {cmd:ivprobit}, all equations are assumed to share the same instruments,
and all second-stage controls are included as first-stage regressors.
See {help ivcloglog##control_inclusion:Remarks {c -} Inclusion of Second-Stage Controls in the First Stage} in this help file for the reasoning behind the latter.

{dlgtab:Optional Options}

{pstd}
{opt nocon:stant} requests that no constant be added as a variable in the first or second stage, depending on where the option is supplied.

{pstd}
{opt order(integer)} specifies the desired order (i.e., degree) of the control function polynomial. This is 1 by default, which represents a linear control function.
This means that, for each first-stage (auxiliary model) equation {it:eq}, only {it:vhatname_eq_}1 will be included as a variable in the second stage.

{pstd}
{opth vce(vcetype)} specifies the desired type of variance-covariance estimate (VCE). All VCE options from {cmd:gmm} are available. The default is {cmd:vce(robust)}.

{pstd}
{opt nogen:erate} requests that the control functions not be added to the dataset.
Specifically, the control functions are composed of powers of the first-stage residuals;
these powers of the first-stage residuals will be kept if {opt nogenerate} is not supplied.

{pstd}
{opt diff:icult_vce} requests different code for obtaining the variance-covariance matrix estimate; use this if (and only if) the default fails.
The "only if" is because the default code is slightly faster.
Currently, this option is only implemented for one-way clustered standard errors.

{p 6 6 2}
The default code involves handing the analytical derivatives of the "residual functions" to Stata.
(Stata "residual functions" equal the moment functions after being multiplied by the respective regressors.)
Stata will then automatically calculate the VCE sandwich formula estimator as part of the {cmd:gmm} call.
The default code can fail due to floating-point imprecision.

{p 6 6 2}
As an example, consider having many fixed effect levels and observations.
Without transforming the data, these fixed effect levels will correspond to very sparse columns in the data matrix.
Unfortunately, for nonlinear models, there is no general way of transforming the data to get an equivalent model, so we have to use that data matrix.
(In contrast, in a linear model, you can just do the "within transformation": demeaning the data in groups specified by the levels of the fixed effects).
Consequently, the matrix of moment function derivatives {bf:G} may be near-singular: the sparse columns in the data matrix mean that changing
the corresponding fixed effect parameters affects the moment functions very little, resulting in near-zero columns in {bf:G}.
Stata may interpret these near-zero columns as actually zero, declare that {bf:G} is singular,
and refuse to solve {bf:GVG}' = {bf:Omega} (this is just the sandwich formula for just-identified GMM rearranged) for the VCE matrix {bf:V}.

{p 6 6 2}
On the other hand, {cmd:difficult_vce} requests that the VCE be manually calculated with a custom Mata subroutine.
The key difference is that it will use {cmd:lusolve()} with a tolerance of zero to solve {bf:GVG}' = {bf:Omega}.
The tolerance is just the threshold at which Stata declares that {bf:A} in some linear system of equation {bf:AX} = {bf:B} is singular.
{cmd:ivcloglog} already checks the data matrix for collinearity with {cmd:_rmcoll}, so checking {bf:G} for singularity
is unnecessary and can only result in problems like the example above.
(It is trivial to prove that the data matrix being full rank implies that {bf:G} is full rank too.)
Although the singularity-checking in {cmd:lusolve()} cannot be disabled, the next best thing is to set the tolerance to zero.
This means only treating 0 as zero rather than also floating-point numbers that are close enough to zero.

{pstd}
{opt show:stages} requests that the output from the first-stage {cmd:regress} regressions and second-stage {cmd:cloglog} regression be shown.
All this does is prevent {cmd:quietly} from being added in front of them. {cmd:showstages} allows you to examine the original output.
It can contain useful information, such as which variables were omitted due to being perfect predictors (in the second stage) or due to collinearity (in the first stage).
Note that the standard errors for the {cmd:cloglog} output will be incorrect.

{* ********************************************************************************************************************}
{marker remarks}{...}
{title:Remarks}

{dlgtab:Continuous Endogenous Covariates}{marker cont_endovar}

{pstd}
{cmd:ivcloglog} assumes that the endogenous covariates are continuous. The explanation for this is as follows (Liu, 2023):
It is well-known that we can always run a linear first stage if the second stage is linear (Angrist & Pischke, 2009; Kelejian, 1971).
Even if the true auxiliary model (i.e., "first stage") is non-linear, assuming that the true primary model (i.e., "second stage") is linear, under typical 2SLS assumptions, the resulting estimates will still be consistent.
This is why running a non-linear first stage in such a scenario is considered a "forbidden regression" (Angrist & Pischke, 2009; Hausman, 1975) {c -} 
if you did so, the resulting estimates would be much less robust to misspecification since their consistency is only guaranteed under strong assumptions.
Unfortunately, when the primary model is non-linear, this result no longer applies, and we cannot freely impose a linear auxiliary model.
This means that the use of non-continuous endogenous variables will render the {cmd:ivcloglog} results inconsistent, though it may be possible to interpret them as an approximation to the ground truth.

{dlgtab:First-Stage Standard Errors}

{pstd}
The first-stage standard errors from the {cmd:gmm} call will be larger than those from the {cmd:regress} call.
This is because they are adjusted for the fact that we are also doing second-stage estimates.
However, this is unnecessary because the first-stage estimates are unaffected by the second-stage estimates.
The SEs from {cmd:regress} should be preferentially used (except in the unlikely case that you wish to compare the first-
and second-stage parameter estimates, which would require one, consistent definition of variance and covariance).

{dlgtab:Selecting a Variance-Covariance Matrix Type}

{pstd}
Because the {cmd:cloglog} model is a binary outcome model that assumes i.i.d. observations,
a correctly specified model will always have homoskedastic standard errors (SEs) and there is no need to use any other error type with it (Wooldridge, 2010).
However, in reality, it is impossible to perfectly specify any model; consequently, you may wish to use other, more robust SEs.
Of course, if you need non-homoskedastic SEs, then your point estimates will in typically be biased and inconsistent.
Nevertheless, using more robust SEs under misspecification will still imperfectly increase the robustness of your hypothesis testing, improving inference.
Specifically, whilst the true coverage probability of a given hypothesis test statistic will typically not converge to the nominal coverage probability,
it will typically at least converge to somewhere closer when using more robust SEs.

{dlgtab:Choosing Factor Variable Base Categories}

{pstd}
{cmd:ivcloglog} calls {cmd:gmm}; consequently, {cmd:ivcloglog} can sometimes throw a {err:factor variable base category conflict} error due to the way {cmd:gmm} is programmed.
This occurs when the same regressor variable has different base categories in two or more first- or second-stage equations.
One situation where that can happen is when the collinearity-checking drops different levels of a factor variable in different equations.
The root cause of the {err:factor variable base category conflict} error is that, via the {cmd:gmm} call, all parameter estimates are stored in the same matrix but with their equation names stripped.
This causes Stata to produce a {err:factor variable base category conflict} error because it incorrectly thinks that you are trying to estimate a single equation with multiple base categories specified for one variable.
To get around this Stata bug, either use the {cmd:b.} prefix (to select the same base category) or the {cmd:ibn} prefix (to request no base category) for that variable in all equations.
The latter option is often easier.
See {manhelp fvvarlist U} for help with factor variable syntax.

{dlgtab:Perfect Predictors}

{pstd}
"Perfect predictors" are variables with (positive or negative) infinite coefficients. These variables and the observations where they are non-zero are excluded.
The reasoning is that the hill-climbing numerical algorithms in Stata's maximum likelihood estimation procedures will result in estimates that diverge to infinity, so excluding these variables improves numerical stability.
However, if you just exclude these variables, you would get incorrect estimates, so we also need to exclude the corresponding observations where these variables are non-zero.
This is because the infinite coefficients imply that the effects of these observations "drown out" the effects of everything else in the likelihood.
In other words, such observations produce score contributions of zero for all other variables,
so we can exclude these observations without changing the theoretical probability limit of the estimates whilst improving the numerical convergence.
See {manhelp probit R} for related, simpler discussion.

{pstd}
Note: non-binary variables omitted due to being perfect predictors may not be correctly acknowledged as such by Stata.
{cmd:_rmcoll} may instead claim that they are omitted due to collinearity.

{dlgtab:Inclusion of Second-Stage Controls in the First Stage}{marker control_inclusion}

{pstd}
Just like {cmd:ivprobit}, all second-stage controls are included in the first stage for robustness.
This is important for instrumental variable models in general because it improves efficiency and robustness.
Adding more valid instruments obviously improves the efficiency, but the reason why doing so improves the robustness may be less obvious.
The reasoning is analogous to that for 2SLS.
For 2SLS under standard assumptions, including the second-stage controls in the first stage guarantees that they will be orthogonal to the first-stage error term,
which shows up in the new, composite second-stage error term.
As a result, this orthogonality condition does not need to be separately assumed.
Similarly, for the complementary log-log model instrumented via the control-function approach ({cmd:ivcloglog}) under standard assumptions,
including the second-stage controls in the first stage guarantees that the new second-stage error term will be standard Gumbel after conditioning on all of the second-stage covariates (Liu, 2023).
Consequently, the condition that this error term remains standard Gumbel after including the second-stage controls in the conditioning does not need to be separately assumed.

{pstd}
Strictly speaking, it is only important that the second-stage controls be {it:inputted} into the first stage;
it is still perfectly fine if some of them are dropped in the first stage due to collinearity (Liu, 2023).
This is because conditioning on a set of variables implies that you can include any linear combination of them in the conditioning without affecting the result.
More specifically, any covariates that are dropped due to collinearity can be expressed as linear combinations of the retained covariates {c -}
but, this means that conditioning on the included covariates is equivalent to also conditioning on the dropped variables as well!

{dlgtab:One-Sample Estimation}

{pstd}
{cmd:ivcloglog} makes sure that the first-stage and second-stage regressions all use the same sample. This is not strictly necessary {c -} for example, see Angrist and Krueger (1995).

{dlgtab:"Warning: Convergence not achieved"}

{pstd}
The "Warning: Convergence not achieved." warning refers to {cmd:gmm}; it will always appear and can be safely ignored.
It occurs because the optimization for the {cmd:gmm} call is disabled.
This is done because we already have the correct parameter estimates from calling {cmd:regress} and {cmd:cloglog},
so running optimization again to find them is pointless.

{* ********************************************************************************************************************}
{marker examples}{...}
{title:Examples}

{dlgtab:A Basic Model with Instrumenting via a Linear Control Function}

{pstd}
This setup is exactly the same as Example 2 in the {manlink R ivprobit} pdf manual, except that the second stage is {cmd:cloglog} rather than {cmd:probit}.

{p 6 6 2}{inp:. use "https://www.stata-press.com/data/r18/laborsup"}{p_end}
{p 6 6 2}{inp:. ivcloglog fem_work fem_educ kids, endogenous(other_inc = male_educ fem_educ kids) vhatname(vhat) vce(unadjusted) nogenerate}{p_end}

{dlgtab:A Prentice and Gloeckler (1978) Model with Instrumenting via a Quadratic Control Function}

{pstd}
In this next example, the treatment variable, {it:drug}, is a binary variable and is not continuous.
The fact that the auxiliary model (i.e., "first stage") is a linear probability model means that the auxiliary model is, strictly speaking, misspecified.
Consequently, the results from this estimation will only be an approximation to the ground truth.
An explanation in this help file of why this is the case is found in {help ivcloglog##cont_endovar:Remarks {c -} Continuous Endogenous Covariates}.

{p 6 6 2}{inp:. sysuse cancer, clear}{p_end}

{p 6 6 2}{inp:. gen id = _n}{p_end}
{p 6 6 2}{inp:. recode drug 1=0 2=1 3=.}{space 23}{inp:// Recoding endogenous variable}{p_end}
{p 6 6 2}{inp:. label values drug .}{space 27}{inp:// Remove value labels to prevent confusion}{p_end}

{p 6 6 2}{inp:. expand studytime}{space 30}{inp:// Structure dataset so that each time period corresponds to one observation}{p_end}
{p 6 6 2}{inp:. bysort id: gen time = _n}{space 22}{inp:// Time period}{p_end}
{p 6 6 2}{inp:. bysort id: gen event = (died & _n == _N)}{space 6}{inp:// Event indicator}{p_end}
{p 6 6 2}{inp:. gen external_instrument = drug + rnormal(0, 1)}{space 9}{inp:// Generate a fictional instrument just so we have one for demonstration purposes}{p_end}

{p 6 6 2}{inp:. ivcloglog event ibn.time age, endogenous(drug = external_instrument, noconstant) vhatname(vhat) noconstant order(2) vce(cluster id) nogenerate}{p_end}

{pstd}
Note that {cmd:noconstant} being supplied in both stages is not strictly necessary since the results are essentially the same otherwise {c -} 
without {cmd:noconstant}, one of the time fixed effects would simply be dropped to prevent collinearity.
Also note that clustering by {it:id} is not necessary, but will increase robustness in case of misspecification.
Similarly, adding time fixed effects to the first stage is also not required, but doing so enhances robustness.

{* ********************************************************************************************************************}
{marker stored_results}{...}
{title:Stored Results}

{pstd}
{cmd:cloglog} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of first- and second-stage parameters{p_end}
{synopt:{cmd:e(endog_ct)}}number of endogenous regressors{p_end}
{synopt:{cmd:e(N_cluster)}}number of clusters{p_end}

{synopt:{cmd:e(chi2)}}Wald chi-squared test statistic for all non-intercept second-stage coefficients being zero{p_end}
{synopt:{cmd:e(df_m)}}degrees of freedom of the above chi-squared test statistic{p_end}
{synopt:{cmd:e(p)}}{it:p}-value of the above chi-squared test statistic{p_end}

{synopt:{cmd:e(ll)}}log-likelihood of the {cmd:cloglog} second stage (full model){p_end}
{synopt:{cmd:e(ll_0)}}log-likelihood of the {cmd:cloglog} second stage (constant-only model){p_end}
{synopt:{cmd:e(ic)}}number of iterations for {cmd:cloglog}{p_end}
{synopt:{cmd:e(rc)}}return code for {cmd:cloglog}{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if {cmd:cloglog} converged, {cmd:0} otherwise{p_end}

{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}; this equals {cmd:e(k)} if {cmd:e(V)} is full-rank.{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cloglog}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}

{synopt:{cmd:e(depvar)}}name of the dependent variable, i.e., the outcome variable{p_end}
{synopt:{cmd:e(exog)}}names of the exogenous variables specified in the second stage, which are also included in the first stage{p_end}
{synopt:{cmd:e(endog)}}names of the endogenous variables{p_end}
{synopt:{cmd:e(inst)}}names of the instruments, including the exogenous variables added from the second-stage{p_end}

{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector containing the first- and second-stage parameter estimates{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the first- and second-stage parameter estimates{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{* ********************************************************************************************************************}
{marker author}{...}
{title:Author}

{pstd}
William Liu (刘威廉), pre-doctoral research assistant at MIT, MIT Sloan, and Harvard

{* ********************************************************************************************************************}
{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
My {cmd:ivcloglog} command is inspired by Dr. Enrique Pinzon's (2020; Stata Conference) presentation on implementing control functions in Stata.
His presentation has helped teach me how to write a {cmd:gmm} moment evaluator program.
In addition, Enrique shared the code for his {cmd:cfunction} command with me.
It has been extremely useful for learning how to code a Stata command.
Many thanks to Enrique, whose assistance has been invaluable for the development of {cmd:ivcloglog}!

{* ********************************************************************************************************************}
{marker references}{...}
{title:References}

{p 4 8 2}
Allison, P. D. (1982). Discrete-time methods for the analysis of event histories. {it:Sociological methodology, 13}, 61-98.

{p 4 8 2}
Angrist, J. D., & Krueger, A. B. (1995). Split-sample instrumental variables estimates of the return to schooling. {it:Journal of Business & Economic Statistics, 13}(2), 225-235.

{p 4 8 2}
Angrist, J. D., & Pischke, J. S. (2009). {it:Mostly harmless econometrics: An empiricist's companion.} Princeton university press.

{p 4 8 2}
Cox, D. R. (1972). Regression models and life‐tables. {it:Journal of the Royal Statistical Society: Series B (Methodological), 34}(2), 187-202.

{p 4 8 2}
Hausman, J. A. (1975). An instrumental variable approach to full information estimators for linear and certain nonlinear econometric models. {it:Econometrica}, 727-738.

{p 4 8 2}
Jenkins, S. P. (1995). Easy estimation methods for discrete-time duration models. {it:Oxford bulletin of economics and statistics, 57}(1), 129-138.

{p 4 8 2}
Jenkins, S. P. (2004) PGMHAZ8: Stata module to estimate discrete time (grouped data) proportional hazards models. {it:Statistical Software Components S438501}, Boston College Department of Economics, revised 17 Sep 2004.

{p 4 8 2}
Kelejian, H. H. (1971). Two-stage least squares and econometric systems linear in parameters but nonlinear in the endogenous variables. {it:Journal of the American Statistical Association, 66}(334), 373-374.

{p 4 8 2}
Liu, W. (2023) A theory guide: Instrumenting a discrete-data proportional hazards model with control functions. Working Paper.

{p 4 8 2}
Palmer, C. (2023) An IV hazard model of loan default with an application to subprime mortgage cohorts. MIT Working Paper.

{p 4 8 2}
Pinzon, E. (2020) GMM with first-step residuals: A recipe for control-function S.E.s. {it:London Stata Conference 2020}, Stata Users Group. {browse "https://EconPapers.repec.org/RePEc:boc:usug20:12"}.

{p 4 8 2}
Prentice, R. L., & Gloeckler, L. A. (1978). Regression analysis of grouped survival data with application to breast cancer data. {it:Biometrics}, 57-67.

{p 4 8 2}
Wooldridge, J. M. (2010). {it:Econometric analysis of cross section and panel data}. MIT press.
{p_end}{* I use this here to avoid unnecessary blank lines, which would otherwise be needed to make the above "paragraph" show up.}