{smcl}
{* *! version 2.0  09nov2023}{...}
{cmd:help xtdhazard} 
{hline}

{title:Title}

{p2colset 5 20 22 2}{...} {phang} {bf:xtdhazard} {hline 2} Instrumental Variables and Control Function Estimation of the Discrete-Time Hazard Model{p_end} {p2colreset}{...} 

{title:Syntax}

{p 8 17 2} {cmd:xtdhazard} {it:estimator} {it:{help varname:depvar}} {it:{help varname:indepvars}} {ifin} {weight} [, {cmd:}{it:{help xtdhazard##options:options}}] 

{synoptset 28 tabbed}{...}
{marker estimator}{...}
{synopthdr :estimator}
{synoptline}
{synopt :{it:{help ivregress:2sls}}}linear two-stage least squares{p_end}
{synopt :{it:{help logit:logit}}}control function (two-stage residuals inclusion) logit{p_end}
{synopt :{it:{help probit:probit}}}control function (two-stage residuals inclusion) probit{p_end}
{synopt :{it:{help cloglog:cloglog}}}control function (two-stage residuals inclusion) complementary log-log{p_end}

{synoptset 28 tabbed}{...}
{marker variables}{...}
{syntab :{it:variables}}
{synoptline}
{synopt :{it:{help varname:depvar}}}binary variable (indicating absorbing state){p_end}
{synopt :{it:{help varname:indepvars}}}explanatory variables{p_end}

{synoptset 28 tabbed}{...}
{syntab :{it:options}}
{synoptline}
{syntab :Model}
{synopt :{opt {ul on}d{ul off}ifference(numlist)}}set order of differencing; {opt difference(1)}, i.e. (only) using first-differences as instruments, is the default{p_end}
{synopt :{opt {ul on}instr{ul off}uments(varlist)}}additional, non-internal instruments{p_end}
{synopt :{opt {ul on}noabsorb{ul off}ing}}forces estimation if {it:depvar} does not indicate absorbing state{p_end}

{syntab :SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt r:obust}, {opt cl:uster} {it:clustvar}, {opt oim} (not with {it:2sls}), {opt opg} (not with {it:2sls}), or {opt un:adjusted} (only with {it:2sls}); 
{opt vce(robust)} is the default{p_end}

{marker Reporting}{...}
{syntab :Reporting}
{synopt :{opt lev:el(#)}}set confidence level; default as set by set level{p_end}
{synopt :{help xtdhazard##Reporting2:display_options}}as for {it:{help ereturn:ereturn display}}{p_end}

{syntab :2sls}
{synopt :{opt inter:actinst}}use squares and interactions of instruments as additional instruments{p_end}
{synopt :{opt nofirst:stage}}do not save first-stage coefficients in {hi:e(G)} and do not perform checks regarding first-stage{p_end}
{synopt :{opt und:erid(string)}}call {cmd:underid} from within {cmd:xtdhazard}; {it:string} is the full syntax of {cmd:underid}{p_end}
{synopt :{opt show:test}}report full results of {cmd:underid}{p_end}

{syntab :logit/probit/cloglog}
{synopt :{opt {ul on}o{ul off}rder(#)}}specify order of control-function polynomial; {opt order(1)} is the default{p_end}
{synopt :{opt {ul on}fsl{ul off}ink(name)}}specify first-stage link function for endogenous dummy regressors; {it:name} may be {opt linear}, {opt logit}, or {opt probit}; {it:logit} is the default{p_end}
{synopt :{opt {ul on}noresg{ul off}enerate}}do not permanently save first-stage residuals; do not store in {hi:e(b)} and report coefficients of first-stage residuals{p_end}
{synopt :{opt resn:ame(stub)}}permanently save first-stage residual as {it:stub_}{it:varname}; the default for {it:stub} is {it:res}{p_end}
{synopt :{opt repl:ace}}replace {it:stub_}{it:varname} if already existent{p_end}
{synopt :{opt {ul on}ter{ul off}za(2017|2023)}}compute standard errors following Terza (2017) or Terza (2023); {opt 2023} is the default{p_end}
{synopt :{opt {ul on}noana{ul off}lytic}}calculate cross-stage derivatives numerically{p_end}
{synopt :{help xtdhazard##cfbinoutmaximization2:maximization_options}}as for {it:logit}, {it:probit}, and {it:cloglog}{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}The data needs to be {cmd:xtset} before using {cmd: xtdhazard}, {it:timevar} needs to be specified; see {helpb xtset:[XT] xtset}.{p_end}
{p 4 6 2}{it:indepvars} may contain factor variables and and time-series operators; see {help fvvarlist} and {help tsvarlist}. factor variables and and time-series operators are not allowed for {it:depvar}.{p_end}
{p 4 6 2}{cmd:bootstrap} is allowed, {cmd:by} and {cmd:svy} are not allowed; see {helpb prefix:[U] prefix}.{p_end}
{p 4 6 2}{opt pweight}s, {opt fweight}s, {opt iweight}s, and {opt aweight}s (only with {it:2sls}) are allowed; {opt pweight}s is the default.{p_end}
{p 4 6 2}If an estimator other than 2sls is specified, the do-file {it:_llcfbin_v.do} may be required to be stored in the ado-path.{p_end}
{p 4 6 2}Available postestimation commands are the same as for the command that correspond to the respective {it:estimator}; 
see {helpb ivregress_postestimation :[R] ivregress postestimation}, {helpb logit_postestimation :[R] logit postestimation}, {helpb probit_postestimation :[R] probit postestimation}, 
and {helpb cloglog_postestimation :[R] cloglog postestimation}.{p_end}
{p 4 6 2}Note, that with the estimators {it:logit}, {it:probit}, and {it:cloglog}, postestimation behavior of {cmd:xtdhazard} is heavily affected by the option {opt noresgenerate}.
This in particular applies to {it:{help predict:predict}} and {it:{help margins:margins}} after {cmd:xtdhazard}; see {help cfbinout}.{p_end} 


{title:Description}

{pstd}{cmd:xtdhazard} implements the linear (first) differences instrumental variables estimator, 
suggested in Farbmacher & Tauchmann (2023) for dealing with unit-level unobserved heterogeneity (possibly correlated with {it:indepvars}) in the discrete-time hazard model. 
{cmd:xtdhazard} also implements related non-linear control-function (cf) estimators.
These procedures address the issue that, conventional (linear) fixed-effects panel estimators (within-transformation, first-differences; see {helpb xtreg:[XT] xtreg}), 
fail to eliminate unobserved time-invariant heterogeneity and are biased and inconsistent if {it:depvar} is a binary dummy indicating an absorbing state.
{cmd:xtdhazard} is essentially a wrapper for {cmd:{help ivregress:ivregress 2sls}} and, depending on which {it:estimator} is specified, for the community-contributed command {cmd:{help cfbinout:cfbinout}}.
{cmd:xtdhazard} temporarily generates first and/or, depending on how {opt difference(#)} is specified, higher-order own-differences of {it:indepvars}, and uses them as instruments for {it:indepvars}.
With estimator {it:2sls}, estimation is by 2sls for which {cmd:xtdhazard} calls {cmd:ivregress}. 
With estimators {it:logit}, {it:probit}, or {it:cloglog}, {cmd:xtdhazard}, instead of {cmd:ivregress}, calls {cmd:cfbinout} to run a non-linear control-function (cf, two-stage residuals inclusion) regression;
cf. Wooldridge (2015).
Unlike conventional fixed effects estimation, these estimators (both, 2sls and cf) rest on the assumption that the unobserved heterogeneity is uncorrelated with the first (or higher-order) own-differences of {it:indepvars}.


{marker variables2}{...}
{title:Variables}

{dlgtab:Dependent Variable}

{phang} {it:depvar} needs to be a binary (either numeric or string) indicator.
The (alphanumerically) smaller value indicates that a unit is still at risk, while the (alpha-numerically) larger value indicates that the absorbing state is reached. 
A 0/1 indicator is hence the most obvious choice for coding {it:depvar}.
{cmd:xtdhazard} is meant for analyzing single spell settings, that is individual-level sequences of {it:depvar}, such as {it:0,..,0,1} and {it:0,..,0,0}.
For individual-level sequences of the form {it:0,..,0,1,..,1}, {cmd:xtdhazard} does not consider observations for periods later than the first occurrence of 1. 
For multiple spell settings, that is sequences like {it:0,1,0,...} or {it:1,0,1,...}, better suited estimation procedures might be available.
For this reason, {cmd:xtdhazard} breaks and returns an error message if {it:depvar} is recognized to indicate a (potentially) repeated event, unless the option {opt noabsorbing} is specified.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang} {opt difference(numlist)} specifies the order of the differences-transformation that is applied to {it:inpdepvars} to generate the instruments. 
The default is {opt difference(1)} that is first differences. 
{opt difference(2)} makes {cmd:xtdhazard} use differences in differences as instruments, {opt difference(3)} differences in differences in differences, etc.
While considering higher-order differences allows for estimation under alternative weaker assumptions, it makes the identification rest on less variation. 
If {it:mumlist} is a list of integers, {cmd:xtdhazard} uses simultaneously differences of different orders as instruments.
In such case the model is technically over-identified.

{phang} {opt instruments(varlist)} specifies further (non-internal) instruments that are used in addition to the internal instruments specified by {opt difference(numlist)}.

{phang} {opt noabsorbing} forces {cmd:xtdhazard} to produce estimation results even if {it:depvar} is detected not to indicate an absorbing state; see {cmd:}{it:{help xtdhazard##variables2:variables}}.


{dlgtab:SE/Robust}

{phang} {opt vce(vcetype)} specifies the method used for estimating standard errors. 
{opt robust}, {opt cluster} {it:clustvar}, and {opt unadjusted} are available as {it:vcetype} with the estimator {it:2sls}.
{opt robust}, {opt cluster} {it:clustvar}, {opt oim} and {opt opg} are available as {it:vcetype} with the estimators {it:logit}, {it:probit}, and {it:cloglog}.
In either case, the default is {opt robust}.
Note that with {it:logit}, {it:probit}, and {it:cloglog}, {opt robust} and {opt cluster}, if specified, are applied to variance estimation in the first and the second-stage. 
Yet, aggregating the two variance-covariance matrices to what is finally saved in {cmd:e(V)} still draws on ML theory of two-step estimation (Murphy & Topel (1985) and in particular Terza, 2016, 2017, & 2023), 
unless the option {opt noanalytic} is specified; see {it:{help cfbinout##options_SE/Robust:cfbinout Options SE/Robust}} for details.
{cmd:xtdhazard} does not include an internal bootstrapping routine.
Yet the prefix command {cmd:bootstrap} still allows obtaining bootstrap standard errors.
When using {cmd:bootstrap} clustering at the level of {it:panelvar} is essential.
I.e. the {cmd:bootstrap} options {opt cluster()} and {opt idcluster()} are required.


{marker Reporting2}{...}
{dlgtab:Reporting}

{phang}{it:display_option}: {opt level(#)}, {opt noci}, {opt nopvalues}, {opt noomitted}, {opt vsquish}, {opt noemptycells}, {opt baselevels}, {opt allbaselevels}, {opt nofvlabel}, {opt fvwrap(#)}, {opt fvwrapon(style)}, 
{opt cformat(%fmt)}, {opt pformat(%fmt)}, {opt sformat(%fmt)}, and {opt nolstretch}.
They are essentially the same as for {cmd:}{it:{help ereturn##display_options:eretun display}}, to which they are passed through; see {helpb ereturn:[R] eretun display}


{dlgtab:2sls}

{phang} {opt interactinst} makes {cmd:xtdhazard} use the squares and cross-products of all instruments,
the differenced {it:indepvars} and possible additional instruments specified by {opt instruments(varlist)}, as additional rhs variables in the first-stage regressions.

{phang} {opt nofirststage} makes {cmd:xtdhazard} not report and not save the coefficients of the first-stage regressions in {hi:e(G)} and also not report any first stage diagnostics. 
This reduces the run time of {cmd:xtdhazard}.
Using the option {opt nofirststage} is, however, not recommended because it withholds important information, in particular about possible perfect fits achieved in first-stage regressions.
A perfect in the first stage indicates that the instruments are only valid for the respective rhs variable, if that rhs variable is itself exogenous.

{phang} {opt underid(string)} makes {cmd:xtdhazard} call the community contributed command {cmd:{help underid}} (Schaffer & Windmeijer, 2020) and report its output along with its own results.
{it:string} is the full syntax of {cmd:underid} including the leading command name.
{cmd:underid} implements various useful iv-estimation related tests. 
If {help fvvarlist:factor variables syntax} is used, however, the use of {cmd:underid} in postestimation is hampered by the feature of {cmd:xtdhazard} to generate the (own-differences) instruments only temporarily.
(When generating the own-differences instruments, {cmd:xtdhazard} needs to find a workaround for combining factor variables syntax with the difference operator {hi:D.}.)
The option {opt unterid} allows for using {cmd:underid} after {cmd:xtdhazard}, albeit {cmd:underid} may fail in postestimation.
If no factor variables syntax is used, {cmd: underid}, as well as {cmd:estat firststage}, {cmd:estat endogeneous}, etc., can be used in postestimation in the same way as after {cmd:ivregress 2sls}.
Calling {cmd:underid} from within {cmd:xtdhazard} may greatly increase the run time.

{phang} {opt showtest} makes {cmd:xtdhazard} display the full output of {cmd:underid} but not only some key results. 
{opt showtest} has no effect on the output from {cmd:underid} that is saved in {hi:e()}.
Specifying {opt showtest} has no effect, if {opt underid(string)} is not specified.


{dlgtab:lofit/probit/cloglog}

{phang} {opt order(#)} makes {cmd:xtdhazard} use not only the first-stage residuals as control-function but also, depending on how {opt order(#)} is specified, higher-order powers of them; cf. {help ivcloglog}. 
{opt order(1)}, i.e. only using the non-transformed residuals, is the default.  

{phang} {opt fslink(name)} specifies a link function for the first-stage.
The default is the {opt fslink(logit)} link, i.e. logit regressions are estimated at the first-stage for binary endogenous regressors.
If {it:logit} or {it:probit} is specified as first-stage link function, {cmd:xtdhazard} uses the respective non-linear outcome model for estimating the first-stage for binary endogenous regressors.  
Specifying {it:logit} or {it:probit} as first-stage link function {cmd:cfbinout} use generalized residuals as auxiliary regressors at the second-stage.
(For {it:logit} the generalized residual takes the simple form of the difference between the observed outcome and the fitted success probability.) 
With {opt fslink(linear)}, {cmd:cfbinout} estimates linear first-stage regressions and uses conventional residuals as auxiliary second-stage regressors.
If {it:varlist2} does not contain binary variables specifying {opt fslink(name)} has no effect. 
If the nonlinear first-stage is subject to quasi-complete separation, {cmd:xtdhazard} equation-wise switches to a linear first-stage.

{phang} {opt noresgenerate} makes {cmd:xtdhazard} generate the first-stage residuals only temporarily and not report and save in {hi:e(b)} their coefficients. 
This is not only a reporting issue, but also affects the postestimation behaviour of {cmd:xtdhazard}.
With {opt noresgenerate}, {cmd:xtdhazard} behaves like {cmd: ivprobit, twostep} and ignores the control function in predicting probabilities and estimating marginal effects.
Without {opt noresgenerate} being specified, the predictions one gets from {cmd:predict}, from which in turn marginal effects are calculated by {cmd:margins}, are conditional on the values of the control function;
see a {browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1509439-bug-overcorrection-with-post-stata-14-1-margins-command-after-ivprobit":discussion} of this issue on stata list.

{phang} {opt resname(stub)} specifies as {it:stub} the prefix for the names of the new variables, in which the first-stage residuals are saved. 
If {opt resname(stub)} is not specified, {it:res} is used as prefix.
In other words, if {it:indepvars} consists of the two variables {it:var1} and {it:var2}, {opt resname(stub)} makes {cmd:xtdhazard} generate the new variables {it:stub_var1} and {it:stub_var2}.
If a higher-order control-function polynomial is requested by specifying {opt order(#)}, the powers of the first-stage residuals receive the prefix-names {it:stub2_}, {it:stub3_}, etc.

{phang} {opt replace} allows {cmd:cfbinout} to replace existing variables that have the same name with the residuals of the first stage.
Specifying {opt replace} is particularly convenient, if one estimates different specifications of a model but does not want to save the first-stage residuals from all of them.

{phang} {opt terza(2017|2023)} specifies whether the method of variance-covariance estimation is the one originally proposed by Terza (2017) or the corrected version proposed by Terza (2023).
{opt terza(2023)} is the default, which, according to Terza (2023), has a much better basis in statistical theory. 
Unlike {opt terza(2017)}, {opt terza(2023)} requires not only calculating first but also second (cross-stage) derivatives of the pseudo-log-likelihood function and is computationally more demanding.
Choosing the (incorrect) {it:2017} method may be a work-around if {opt cfbinout, terza(2023)} fails or takes excessive time to run.
The two methods often give similar estimates. However, depending on the specific application, the difference between them can still be substantial. 

{phang} {opt noanalytic} requests numerical calculation of the cross-stage derivatives of the (pseudo) log-likelihood function, using the Mata function {it:{help mf_deriv##search:deriv()}}.
Analytically derived cross-stage derivatives are not available for {opt fslink(probit)}, nor when {opt order(#)} is specified other than the default.
For these specifications, {cmd:cfbinout} automatically activates {opt noanalytic} and issues a respective message.
Calculating cross-stage derivatives numerically requires the Stata do file {it:_llcfbin_v.do} to be stored in the ado-path.
For large models and big data sets, calculating the cross-derivatives numerically may require substantial computing time.
{opt noanalytic} is immaterial if {opt terza(2017)} specified, since Terza's (2017) approach to variance-covariance estimation does not involve the calculation of cross-stage derivatives.

{marker cfbinoutmaximization2}{...}
{phang}{it:maximization_options} (for the second stage) if {it:estimator} is either {it:logit}, {it:probit}, or {it:cloglog}: 
{opt difficult}, {opt technique(algorithm_spec)}, {opt iterate(#)}, {opt tolerance(#)}, {opt ltolerance(#)}, {opt nrtolerance(#)}, {opt qtolerance}, {opt nonrtolerance}, 
and {opt from(init_specs)}; see {helpb maximize:[R] maximize}


{title:Example} (Borrowed from Rabe-Hesketh & Skrondal, 2012)

{pstd}Load data ({it:promotion.dta}) on pormotions of assistant professors (Long, Allison & McGinnis, 1993).{p_end}
{phang2}{cmd:. use http://www.stata-press.com/data/mlmus3/promotion, clear}{p_end}

{pstd}Prepare data for being used with discrete-time hazard model. (Code borrowed from Rabe-Hesketh & Skrondal, 2012, p. 763.){p_end}
{phang2}{cmd:. reshape long art cit, i(id) j(year)}{p_end}

{pstd}{cmd:xtset} data.{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}Generate variables {it:y} (binary {it:depvar}) and {it:prestige} (possibly time-varying {it:indepvar}).
(Code borrowed, with some modifications, from Rabe-Hesketh & Skrondal, 2012, p. 764.){p_end}
{phang2}{cmd:. generate y = (year == dur & event == 1) if year <= dur}{p_end}
{phang2}{cmd:. generate prestige = cond(year<jobtime,prest1,prest2)}{p_end}
 
{pstd}Use linear first-differences IV estimator.{p_end}
{phang2}{cmd:. xtdhazard 2sls y i.year undgrad phdmed phdprest art cit prestige}{p_end}

{pstd}Same as above, but using the control-function logit estimator with control-function polynomial of order two.{p_end}
{phang2}{cmd:. xtdhazard logit y i.year undgrad phdmed phdprest art cit prestige, replace order(2)}{p_end}

{pstd}Use {cmd:margins} for estimating average partial effects on promotion hazard.{p_end}
{phang2}{cmd:. margins, dydx(art cit prestige)}{p_end}


{title:Saved results}
{pstd}

{dlgtab:2sls}

{pstd}
{cmd:xtdhazard 2sls} saves the following in {cmd:e()} 
(in major parts passed through from {cmd:ivregress}; descriptions partly borrowed from respective help file):

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations (excluding waves eliminated by taking differences){p_end}
{synopt:{cmd:e(N_g)}}number of groups (cross-sectional units in panel){p_end}
{synopt:{cmd:e(N_clust)}}number of clusters (only saved with {it:vcetype} {it:cluster}){p_end}
{synopt:{cmd:e(difference)}}order of differencing (if not multiple differences used){p_end}
{synopt:{cmd:e(k_perfect)}}number of first-stage regressions yielding perfect fit (not saved with option {opt nofirststage}){p_end}
{synopt:{cmd:e(chi2)}}model chi-squared{p_end}
{synopt:{cmd:e(p)}}model significance, p-value{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(rss)}}residual sum of squares{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(mss)}}model sum of squares{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(rank)}}rank of {hi:e(V)}{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(irregular)}}indicator saved with option {opt noabsorbing}: 
{hi:0} if {it:depvar} is regular, {hi:1} if {it:depvar} is irregular, {hi:-1} if {it:depvar} is regular but obs after absorbing state is reached enter estimation sample{p_end}
{synopt:{cmd:e(wgtsum)}}sum of weights (only saved if weights are specified){p_end}
{synopt:{cmd:e(kappa)}}{hi:1} (not applicable to 2sls){p_end}
{synopt:{cmd:e(iterations)}}{hi:0} (not applicable to 2sls){p_end}
{synopt:{cmd:e(j_uid)}}chi-sq statistic for underidentification (if applicable passed through from {opt underid}){p_end}
{synopt:{cmd:e(df_uid)}}degrees of freedom of underidentification test (if applicable passed through from {opt underid}){p_end}
{synopt:{cmd:e(p_uid)}}p-value for underidentification test (if applicable passed through from {opt underid}){p_end}
{synopt:{cmd:e(j_oid)}}chi-sq statistic for overidentification (if applicable passed through from {opt underid}){p_end}
{synopt:{cmd:e(df_oid)}}degrees of freedom of overidentification test (if applicable passed through from {opt underid}){p_end}
{synopt:{cmd:e(p_oid)}}p-value for overidentification test (if applicable passed through from {opt underid}){p_end}

{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(tvar)}}name of {it:timevar}{p_end}
{synopt:{cmd:e(ivar)}}name of {it:panelvar}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {opt predict}{p_end}
{synopt:{cmd:e(chi2type)}}{hi:Wald}{p_end}
{synopt:{cmd:e(depvar)}}name of {it:depvar}{p_end}
{synopt:{cmd:e(vcest)}}{it:vcetype} specified in {opt vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(wtype)}}weight type (only saved if weights are specified){p_end}
{synopt:{cmd:e(wexp)}}= {it:weight expression} (only saved if weights are specified){p_end}
{synopt:{cmd:e(title)}}{cmd:Own-differences IV estimation of linear discrete-time hazard model}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(cmd)}}{cmd:ivregress}{p_end}
{synopt:{cmd:e(cmd2)}}{cmd:xtdhazard}{p_end}
{synopt:{cmd:e(estimator)}}{hi:2sls}{p_end}
{synopt:{cmd:e(link)}}{hi:linear}{p_end}
{synopt:{cmd:e(endog)}}endogenous rhs variables{p_end}
{synopt:{cmd:e(exog)}}exogenous variables{p_end}
{synopt:{cmd:e(perfect)}}perfectly predicted rhs variables{p_end}
{synopt:{cmd:e(interactinst)}}{hi:interactions} or {hi:nointeractions}, depending on option {opt interactinst}{p_end}
{synopt:{cmd:e(marginsnotok)}}predictions disallowed by {opt margins}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {opt margins}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {opt predict}{p_end}
{synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end}
{synopt:{cmd:e(footnote)}}program used to implement footnote display{p_end}
{synopt:{cmd:e(properties)}}{opt b V}{p_end}
{synopt:{cmd:e(rkstat)}}test statistic (if applicable passed through from {opt underid}){p_end}
{synopt:{cmd:e(vceopt)}}variance-covariance matrix options (if applicable passed through from {opt underid}){p_end}
{synopt:{cmd:e(rkopt)}}additional options (if applicable passed through from {opt underid}){p_end}

{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}vector of estimated coefficients{p_end}
{synopt:{cmd:e(V)}}estimated coefficient variance-covariance matrix{p_end}
{synopt:{cmd:e(G)}}matrix of estimated first-stage coefficient (not saved with {opt nofirststage}; column names may violate Stata's naming conventions for differences of factor variables){p_end}
{synopt:{cmd:e(V_modelbased)}}estimated model-based variance-covariance matrix{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample (excluding periods lost because of differencing the data){p_end}
{p2colreset}{...}


{dlgtab:logit/probit/cloglog}

{pstd}
{cmd:xtdhazard logit}, {cmd:xtdhazard probit}, and {cmd:xtdhazard cloglog} save the following in {cmd:e()} 
(in major parts passed through from {cmd:logit}, {cmd:probit}, and {cmd:cloglog}, respectively; descriptions partly borrowed from respective help file):

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations (excluding waves eliminated by taking differences){p_end}
{synopt:{cmd:e(N_g)}}number of groups (cross-sectional units in panel){p_end}
{synopt:{cmd:e(N_clust)}}number of clusters (only saved with {it:vcetype} {it:cluster}){p_end}
{synopt:{cmd:e(difference)}}order of differencing (if not multiple differences used){p_end}
{synopt:{cmd:e(order)}}order of control-function polynomial{p_end}
{synopt:{cmd:e(k_perfect)}}number of collinear first-stage residuals{p_end}
{synopt:{cmd:e(chi2)}}model chi-squared{p_end}
{synopt:{cmd:e(p)}}model significance, p-value{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(rank)}}rank of {hi:e(V)}{p_end}
{synopt:{cmd:e(ll)}}pseudo log-likelihood (second stage){p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(irregular)}}indicator saved with option {opt noabsorbing}: {hi:0} if {it:depvar} is regular, {hi:1} if {it:depvar} is irregular, 
{hi:-1} if {it:depvar} is regular but obs after absorbing state is reached enter estimation sample{p_end}
{synopt:{cmd:e(wgtsum)}}sum of weights (only saved if weights are specified){p_end}
{synopt:{cmd:e(converged)}}{hi:1} if converged, {hi:0} otherwise{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(k)}}number of parameters (second stage){p_end}
{synopt:{cmd:e(k_eq_model)}}total number of equations{p_end}
{synopt:{cmd:e(k_eq)}}{hi:1} number of equations (second stage){p_end}
{synopt:{cmd:e(k_dv)}}{hi:1} number of dependent variables (second stage){p_end}
{synopt:{cmd:e(N_cds)}}number of completely determined successes (second stage){p_end}
{synopt:{cmd:e(N_cdf)}}number of completely determined failures (second stage){p_end}
{synopt:{cmd:e(p_exog)}}exogeneity test Wald p-value{p_end}
{synopt:{cmd:e(df_exog)}}degrees of freedom for chi-squared test of exogeneity{p_end}
{synopt:{cmd:e(chi2_exog)}}Wald chi-squared test of exogeneity{p_end}

{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(tvar)}}name of {it:timevar}{p_end}
{synopt:{cmd:e(ivar)}}name of {it:panelvar}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {opt predict}{p_end}
{synopt:{cmd:e(chi2type)}}{hi:Wald}{p_end}
{synopt:{cmd:e(depvar)}}name of {it:depvar}{p_end}
{synopt:{cmd:e(vcest)}}{it:vcetype} specified in {opt vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(wtype)}}weight type (only saved if weights are specified){p_end}
{synopt:{cmd:e(wexp)}}= {it:weight expression} (only saved if weights are specified){p_end}
{synopt:{cmd:e(title)}}{cmd:Own-differences instruments CF estimation of discrete-time hazard model}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(cmd)}}either {cmd:logit}, {cmd:probit} or {cmd:cloglog}{p_end}
{synopt:{cmd:e(cmd2)}}{cmd:xtdhazard}{p_end}
{synopt:{cmd:e(estimator)}}{hi:cf}{p_end}
{synopt:{cmd:e(link)}}link function, either {cmd:logit}, {cmd:probit} or {cmd:cloglog}{p_end}
{synopt:{cmd:e(fslink)}}{hi:linear}, fist-stage link-function{p_end}
{synopt:{cmd:e(endog)}}endogenous rhs variables{p_end}
{synopt:{cmd:e(exog)}}exogenous variables{p_end}
{synopt:{cmd:e(generated)}}variables generated by {cmd:cfbinout}{p_end}
{synopt:{cmd:e(perfect)}}perfectly predicted rhs variables{p_end}
{synopt:{cmd:e(marginsnotok)}}predictions disallowed by {opt margins}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {opt margins}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {opt predict}{p_end}
{synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end}
{synopt:{cmd:e(properties)}}{opt b V}{p_end}
{synopt:{cmd:e(opt)}}type of optimization (second stage){p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program (second stage){p_end}
{synopt:{cmd:e(ml_method)}}type of {hi:ml} method (second stage){p_end}
{synopt:{cmd:e(technique)}}maximization technique (second stage){p_end}
{synopt:{cmd:e(which)}}{hi:max} or {hi:min}, whether optimizer is to perform maximization or minimization (second stage){p_end}

{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}vector of estimated coefficients{p_end}
{synopt:{cmd:e(V)}}estimated coefficient variance-covariance matrix{p_end}
{synopt:{cmd:e(G)}}matrix of estimated first-stage coefficients (column names may violate Stata's naming conventions for differences of factor variables){p_end}
{synopt:{cmd:e(V_modelbased)}}estimated model-based variance-covariance matrix{p_end}
{synopt:{cmd:e(gradient)}}gradient vector (second stage){p_end}
{synopt:{cmd:e(ilog)}}iteration log (second stage){p_end}
{synopt:{cmd:e(rules)}}information about perfect predictors (second stage, not saved with {it:estimator} {it:cloglog}){p_end}
{synopt:{cmd:e(mns)}}vector of means of the independent variables{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample (excluding periods lost because of differencing the data){p_end}
{p2colreset}{...}



{title:References}
 

{pstd} Farbmacher, H. and Tauchmann, H. (2023). Linear Fixed-Effects Estimation with Non-Repeated Outcomes, {it:Econometric Reviews} 42(8), 635-654.

{pstd} Long, J.S., Allison, P.D. and McGinnis, R. (1993). Rank Advancement in Academic Careers: Sex Differences and the Effects of Productivity, {it:American Sociological Review} 58, 703–722.

{pstd} Murphy, K.M. and Topel, R.H. (1985). Estimation and Inference in Two-Step Econometric Models, {it:Journal of Business & Economic Statistics} 3(4): 370-379.

{pstd} Rabe-Hesketh, S. and Skrondal, A. (2012). {it:Multilevel and Longitudinal Modeling Using Stata}, 3rd edition. College Station, Texas: Stata Press Publication.

{pstd} Schaffer, M.E. and Windmeijer, F. (2020). {browse "http://ideas.repec.org/c/boc/bocode/s458805.html":underid: Postestimation tests of under- and over-identification after linear IV estimation}, {it:Statistical Software Components} S458805, Boston College Department of Economics, revised 29 Sep 2020.

{pstd} Terza, J.V. (2023). Simpler standard errors for two-stage optimization estimators revisited, {it:The Stata Journal} 23(4), 1057-1061. 

{pstd} Terza, J.V. (2017). Two-stage residual inclusion estimation: A practitioners guide to Stata implementation, {it:The Stata Journal} 17(4), 916-938. 

{pstd} Terza, J.V. (2016). Simpler Standard Errors for Two-stage Optimization Estimators, {it:The Stata Journal} 16(2), 368–385.

{pstd} Wooldridge, J.M. (2015). Control Function Methods in Applied Econometrics, {it:The Journal of Human Resources} 50(2), 420-445.


{title:Also see}

{psee} Manual:  {manlink R cloglog}, {manlink ST discrete}, {manlink R ivprobit}, {manlink R ivregress}, {manlink ST logit}, {manlink ST probit}, 
{manlink ST stcox}, {manlink ST streg}, {manlink ST stset}, {manlink ST stsplit}, {manlink XT xtreg}, {manlink XT xtset}{break}

{psee} {space 2}Help:  {manhelp cloglog R:cloglog}, {manhelp ivprobit R:ivprobit}, {manhelp ivregress R:ivregress}, {manhelp logit R:logit}, {manhelp probit R:probit}, 
{manhelp stcox ST:stcox}, {manhelp streg ST:streg}, {manhelp stset ST:stset}, {manhelp stsplit ST:stsplit}, {manhelp xtreg XT:xtreg}, {manhelp xtset XT:xtset}{break} 

{psee} Online:   {helpb cfbinout}, {helpb dthaz}, {helpb hshaz}, {helpb ivcloglog}, {helpb pgmhaz8}, {helpb underid}{p_end} 


{title:Author}

{psee} Harald Tauchmann{p_end}{psee} Friedrich-Alexander-Universit{c a:}t Erlangen-N{c u:}rnberg (FAU){p_end}{psee} N{c u:}rnberg, 
Germany{p_end}{psee}E-mail: harald.tauchmann@fau.de {p_end}


{title:Disclaimer}
 
{pstd} This software is provided "as is" without warranty of any kind, either expressed or implied. The entire risk as to the quality and 
performance of the program is with you. Should the program prove defective, you assume the cost of all necessary servicing, repair or 
correction. In no event will the copyright holders or their employers, or any other party who may modify and/or redistribute this software, 
be liable to you for damages, including any general, special, incidental or consequential damages arising out of the use or inability to 
use the program.{p_end} 


{title:Acknowledgements}

{pstd} I gratefully acknowledge comments and suggestions by Helene K{c o:}nnecke, Sabrina Schubert, Irina Simankova, Elena Yurkevich and the participants of the 2019 and 2024 German Stata Conferences.{p_end} 
