{smcl}
{* *! version 1.2  1feb2025}{...}
{cmd:help cfbinout} 
{hline}

{title:Title}

{p2colset 5 20 22 2}{...} {phang} {bf:cfbinout} {hline 2} Control Function Estimation of Binary Outcome Models{p_end} {p2colreset}{...} 

{title:Syntax}

{p 8 17 2} {cmd:cfbinout} {it:link} {it:{help varname:depvar}} [{it:{help varname:varlist1}}] ({it:{help varname:varlist2} = {it:{help varname:varlist_iv}}}) {ifin} {weight}, [{cmd:}{it:{help cfbinout##options:options}}] 


{synoptset 28 tabbed}{...}
{marker Variables}{...}
{synopthdr :Variables}
{synoptline}
{synopt :{it:{help varname:depvar}}}binary outcome variable {p_end}
{synopt :{it:{help varname:varlist1}}}exogenous explanatory variables{p_end}
{synopt :{it:{help varname:varlist2}}}endogenous explanatory variables{p_end}
{synopt :{it:{help varname:varlist_iv}}}(excluded) instrumental variables{p_end}

{synoptset 28 tabbed}{...}
{marker Link}{...}
{syntab :{it:link}}
{synoptline}
{synopt :{it:{help logit:logit}}}logit link{p_end}
{synopt :{it:{help probit:probit}}}probit link{p_end}
{synopt :{it:{help cloglog:cloglog}}}complementary log-log link{p_end}

{synoptset 28 tabbed}{...}
{syntab :{it:Options}}
{synoptline}
{syntab :Model}
{synopt :{opt {ul on}fsl{ul off}ink(name)}}specify first-stage link function for endogenous dummy regressors; {it:name} may be {opt linear}, {opt logit}, or {opt probit}; {it:logit} is the default{p_end}
{synopt :{opt {ul on}fss{ul off}witch}}switch equation-wise to {opt fslink(linear)} in case of quasi-complete separation in first-stage{p_end}
{synopt :{opt {ul on}o{ul off}rder(#)}}specify order of control-function polynomial; {opt order(1)} is the default{p_end}

{syntab :SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim}, {opt opg}, {opt r:obust}, or {opt cl:uster} {it:clustvar}; {opt oim} is the default{p_end}
{synopt :{opt {ul on}ter{ul off}za(2017|2023)}}compute standard errors following Terza (2017) or Terza (2023); {opt 2023} is the default{p_end}
{synopt :{opt {ul on}noana{ul off}lytic}}calculate cross-stage derivatives numerically{p_end}

{syntab :Store/Generate}
{synopt :{opt {ul on}noresg{ul off}enerate}}do not permanently save first-stage residuals; do not store and report control function coefficients{p_end}
{synopt :{opt resn:ame(stub)}}permanently save first-stage residual as {it:stub_}{it:varname}; the default for {it:stub} is {it:res}{p_end}
{synopt :{opt repl:ace}}replace {it:stub_}{it:varname} if already exists{p_end}
{synopt :{opt fsk:eep}}keep full first-stage results{p_end}

{marker Reporting}{...}
{syntab :Reporting}
{synopt :{opt lev:el(#)}}set confidence level; default as set by set level{p_end}
{synopt :{help cfbinout##Reporting2:display_options}}as for {it:{help ereturn:ereturn display}}{p_end}

{marker Maximization}{...}
{syntab :Maximization}
{synopt :{opt nosearch}}do not search for an optimal delta when numerically calculating second derivatives{p_end}
{synopt :{help cfbinout##Maximization2:maximization_options}}as for {it:logit}, {it:probit}, and {it:cloglog}{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
{it:varlist1}, {it:varlist2}, and {it:varlist_iv} may contain factor variables and time-series operators; see {help fvvarlist} and {help tsvarlist}.{p_end}
{p 4 6 2}Factor variables and and time-series operators are not allowed for {it:depvar}.{p_end}
{p 4 6 2}{cmd:bootstrap} is allowed, {cmd:by} and {cmd:svy} are not allowed; see {helpb prefix:[U] prefix}.{p_end}
{p 4 6 2}{opt pweight}s, {opt fweight}s and {opt iweight}s are allowed, with {opt iweight} being the default.{p_end}
{p 4 6 2}Depending on how the options for variance estimation are specified, the do-file {it:_llcfbin_v.do} may be required to be stored in the ado-path.{p_end}
{p 4 6 2}Postestimation commands, depending on the chosen {it:link} function, are largely the same as after {it:logit}, {it:probit}, and {it:cloglog}, respectively; see {helpb logit_postestimation :[R] logit postestimation}.{p_end}

{title:Description}

{pstd}{cmd:cfbinout} implements control function (two-stage residuals inclusion) estimation of binary outcome models, specifically {cmd:logit}, {cmd:probit}, and {cmd:cloglog}, as suggested in Wooldridge (2015).
That is, in a first-stage the endogenous right-hand-side variables ({it:varlist2}) are regressed on the exogenous variables in the model ({it:varlist1} and {it:varlist_iv}). 
Subsequently, the (generalized) residuals from these regressions enter the second-stage regression as additional regressors.
Regarding the implementation in Stata and Mata, {cmd:cfbinout} draws on Terza (2017, 2023). 
{cmd:cfbinout} complements the real Stata command {cmd:ivprobit} and the recent community contributed command {cmd:ivcloglog}.
Unlike {cmd:ivprobit} and {cmd:ivcloglog}, {cmd:cfbinout} allows for discrete/factor variables in {it:varlist2}.
For them, nonlinear first-stage models (default logit, alternatively probit) are estimated and generalized residuals are included in the second-stage regression, unless {opt fslink(linear)} is specified.
With {it:link} {opt probit} and {opt fslink(linear)}, {cmd:cfbinout probit} is equivalent to {cmd:ivprobit, twostep} in terms of model estimation.
An important difference is, however, that unless the option {opt noresgenerate} is specified, {cmd:cfbinout} takes the control functions (included residuals) into account in postestimation; 
see the {browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1509439-bug-overcorrection-with-post-stata-14-1-margins-command-after-ivprobit":discussion} on Statalist.
The equivalence of {cmd:cfbinout probit} is even closer with {cmd:cfprobit}, an official Stata command that was released for StataNow almost at the same time as {cmd:cfbinout} was completed.


{marker options}{...}
{title:Options}

{dlgtab:Model}  

{phang} {opt fslink(name)} specifies a link function for first-stage regressions with binary left-hand-side variable.
The default is the {opt fslink(logit)} link, i.e. logit regressions are estimated in the first-stage for dummy endogenous regressors.
{opt fslink(probit)} provides an alternative nonlinear specification.   
Specifying {it:logit} or {it:probit} as first-stage link function makes {cmd:cfbinout} use generalized residuals as auxiliary regressors in the second-stage.
(For {it:logit}, but not for {it:probit}, the generalized residual takes the simple form of the difference between the observed outcome and the fitted success probability.) 
Note that {cmd:cfbinout} identifies binary variables even if no factor variables syntax is used.
With {opt fslink(linear)}, {cmd:cfbinout} estimates linear regressions in the first-stage and uses conventional residuals as auxiliary regressors in the second-stage, regardless of whether the endogenous regressors are continuous or binary.
If {it:varlist2} does not contain binary variables, specifying {opt fslink(name)} has no effect, since all first-stage regressions are linear anyway. 

{phang} {opt fsswitch} allows {cmd:cfbinout} to estimate a linear first-stage although the respective endogenous regressor is binary and {opt fslink(name)} is not {opt fslink(linear)}.
With {opt fsswitch}, {cmd:cfbinout} switches to a linear first-stage regression if the respective first-stage is subject to quasi-complete separation.
Without {opt fsswitch}, {cmd:cfbinout} will fail in such a case.    

{phang} {opt order(#)} determines the order of the control-function polynomial. With {opt order(1)}, which is the default, the (generalized) first-stage residuals enter the second-stage regression linearly.
With {opt order(2)}, the first-stage residuals enter not only linearly but also as squared values.
With {opt order(3)}, also cubic transformations of the first-stage residuals are considered as second-stage, rhs variables; ect.
Interactions of first-stage residuals (from different first-stage regressions) do not enter the second-stage, irrespective of how {opt order(#)} is specified.
Only strictly positive integer values are allowed.

{marker options_SE/Robust}{...}
{dlgtab:SE/Robust}

{phang} {opt vce(vcetype)} specifies the method used for estimating the coefficient variance-covariance matrix and in turn the standard errors.
{opt oim} and {opt opg} are derived from asymptotic properties of maximum likelihood estimators.
{opt robust} and {opt cluster} {it:clustvar}, are robust to some kinds of misspecification, for instance intra cluster correlation for the latter. 
With analytically determined cross-stage derivatives {cmd:cfbinout}, applies the {it:vcetype} to the covariance estimation in the first (either {opt robust} or {opt cluster}) and the second-stage. 
Yet, combining the two preliminary variance-covariance matrices to what is finally saved in {cmd:e(V)} does not take the {it:vcetype} into account.
In contrast, with numerically determined cross-stage derivatives (see option {opt noanalytic}), a sandwich estimator is used if the {it:vcetype} is {opt robust} or {opt cluster}.

{phang} {opt terza(2017|2023)} specifies whether the method of variance-covariance estimation is the one originally proposed by Terza (2017) or the corrected version proposed by Terza (2023).
{opt terza(2023)} is the default, which, according to Terza (2023), has a much better basis in statistical theory. 
Unlike {opt terza(2017)}, {opt terza(2023)} requires not only calculating first but also second (cross-stage) derivatives of the pseudo-log-likelihood function and is computationally more demanding.
Choosing the (incorrect) {it:2017} method may hence be a work-around if {opt cfbinout, terza(2023)} fails or takes excessive time to run, cf. option {it:{help cfbinout##options:noanalytic}}.
The two methods often give similar estimates. However, depending on the specific application, the difference between them can still be substantial. 

{phang} {opt noanalytic} requests numerical calculation of the cross-stage derivatives of the (pseudo) log-likelihood function, using the Mata function {it:{help mf_deriv##search:deriv()}}.
Analytically derived cross-stage derivatives are not available for {opt fslink(probit)}, nor when {opt order(#)} is specified other than the default.
For these specifications, {cmd:cfbinout} automatically activates {opt noanalytic} and issues a respective message.
Calculating cross-stage derivatives numerically requires the Stata do file {it:_llcfbin_v.do} to be stored in the ado-path.
For large models and big data sets, calculating the cross-derivatives numerically may require substantial computing time.
{opt noanalytic} is immaterial if {opt terza(2017)} specified, since Terza's (2017) approach to variance-covariance estimation does not involve the calculation of cross-stage derivatives.


{dlgtab:Store/Generate}

{phang} {opt nogresenerate} makes {cmd:cfbinout} only temporarily generate the first-stage residuals that enter the second-stage as additional regressors.
{opt noresgenerate} also prevents {cmd:cfbinout} from saving the estimated coefficients of these additional regressors in {cmd:e(b)} and reporting them in the output.
Specifying the option {opt noresgenerate} is not recommended, if the analysis aims on estimating marginal effects, e.g. using the postestimation command {cmd:}{it:{help margins##response_options:margins}}.
Two-step control function estimation rescales the estimated coefficient but still allows for estimating marginal effects consistently.
Yet, the latter requires that the auxiliary regressors are taken into account when predicting probabilities (cf. Wooldridge, 2015).

{phang} {opt resname(stub)} specifies the prefix for the names of the variables as which the first-stage residuals are saved as {it:stub}. 
In other words, if {it:varlist2} consists of the two variables {it:endogvar1} and {it:endogvar2}, {opt resname(stub)} makes {opt resname(stub)} generate the variables {it:stub_endogvar1} and {it:stub_endogvar2}.
If {opt resname(stub)} is not specified, {cmd:cfbinout} uses {it:res} as prefix.
If a higher-order control-function polynomial is requested by specifying {opt order(#)}, the powers of the first-stage residuals receive the prefix-names {it:stub2_}, {it:stub3_}, etc.

{phang} {opt replace} allows {cmd:cfbinout} to replace existing variables that share their names with the newly generated first-stage residuals.
Specifying {opt replace} is in particularly convenient, if one estimates different specifications of a model but does not want to save the first-stage residuals from all of them.

{phang} {opt fskeep} makes {cmd:cfbinout} save the full first-stage regression results in {cmd:e(bfs)} and {cmd:e(Vfs)}.
The first-stage coefficients are always saved in the matrix {cmd:e(G)}, regardless of whether {opt fskeep} is specified or not.

{marker Reporting2}{...}
{dlgtab:Reporting}

{phang}{it:display_option}: {opt level(#)}, {opt noci}, {opt nopvalues}, {opt noomitted}, {opt vsquish}, {opt noemptycells}, {opt baselevels}, {opt allbaselevels}, {opt nofvlabel}, {opt fvwrap(#)}, {opt fvwrapon(style)}, 
{opt cformat(%fmt)}, {opt pformat(%fmt)}, {opt sformat(%fmt)}, and {opt nolstretch}.
They are essentially the same as for {cmd:}{it:{help ereturn##display_options:eretun display}}, to which they are passed through; see {helpb ereturn:[R] eretun display}.

{marker Maximization2}{...}
{dlgtab:Maximazation}

{phang} {opt nosearch} prevents {it:{help mf_deriv##search:deriv()}} from searching for optimal values for delta, when numerically calculating cross-stage derivatives.
This reduces the run time but may also reduce the accuracy.

{phang}{it:maximization_options} for the second-stage: {opt difficult}, {opt technique(algorithm_spec)}, {opt iterate(#)}, {opt tolerance(#)}, {opt ltolerance(#)}, {opt nrtolerance(#)}, {opt qtolerance}, {opt nonrtolerance}, 
and {opt from(init_specs)}; see {helpb maximize:[R] maximize} 


{title:Example}

{pstd}Load Stata example data set {it:laborsup.dta}.{p_end}
{phang2}{cmd:. webuse laborsup, clear}{p_end}

{pstd}Use {cmd:cfbinout} for estimation (equivalent to using {cmd:ivprobit, twostep}); {helpb ivprobit:[R] ivprobit}.{p_end}
{phang2}{cmd:. cfbinout probit fem_work fem_educ kids (other_inc = male_educ)}{p_end}

{pstd}Use logit link function.{p_end}
{phang2}{cmd:. cfbinout logit fem_work fem_educ kids (other_inc = male_educ), replace}{p_end}
 
{pstd}Consider having kids as binary endogenous regressor and use parents' relative education as an additional instrument.{p_end}
{phang2}{cmd:. generate haskids = kids > 0}{p_end}
{phang2}{cmd:. generate rel_educ = male_educ/fem_educ}{p_end}
{phang2}{cmd:. cfbinout probit fem_work fem_educ (other_inc i.haskids = male_educ rel_educ), fslink(probit) replace}{p_end}

{pstd}Recode kids as a categorical variable and use polynomial of husband's and interaction of spouses' education as instruments; use the cloglog link and second order control-function polynomial.{p_end}
{phang2}{cmd:. recode kids (0 = 0) (1 = 1) (2 3 4 = 2), gen(kidscat)}{p_end}
{phang2}{cmd:. cfbinout cloglog fem_work fem_educ (other_inc i.kidscat = c.male_educ##c.male_educ c.fem_educ#c.male_educ), fslink(probit) order(2) replace}{p_end}



{title:Saved results}

{pstd}
{cmd:cfbinout} saves in {hi:e()} 
(in major parts passed through from {cmd:logit}, {cmd:probit}, and {cmd:cloglog}, respectively; descriptions partly borrowed from respective help files):

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(ll)}}pseudo log likelihood (second-stage){p_end}
{synopt:{cmd:e(chi2)}}model chi-squared{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(p)}}model significance, p-value{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(k_perfect)}}number of collinear residuals dropped from second-stage{p_end}
{synopt:{cmd:e(chi2_exog)}}Wald chi-squared test of exogeneity{p_end}
{synopt:{cmd:e(df_exog)}}test of exogeneity degrees of freedom{p_end}
{synopt:{cmd:e(p_exog)}}test of exogeneity p-value{p_end}
{synopt:{cmd:e(rank)}}rank of {hi:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations (second-stage){p_end}
{synopt:{cmd:e(k)}}number of parameters (second-stage){p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {hi:e(b)} (second-stage){p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables (second-stage){p_end}
{synopt:{cmd:e(k_eq_model)}}overall number of equations{p_end}
{synopt:{cmd:e(converged)}}{hi:1} if converged, {hi:0} otherwise (second-stage){p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(wgtsum)}}sum of weights{p_end}
{synopt:{cmd:e(ll_0)}}pseudo log likelihood, constant-only model (second-stage){p_end}
{synopt:{cmd:e(order)}}order of control-function polynomial{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters (only saved with {it:vcetype} {it:cluster}){p_end}
{synopt:{cmd:e(N_f)}}number of failures (only saved with {it:link} {it:cloglog}){p_end}
{synopt:{cmd:e(N_s)}}number of successes (only saved with {it:link} {it:cloglog}){p_end}
{synopt:{cmd:e(N_cdf)}}number of completely determined failures (not saved with {it:link} {it:cloglog}){p_end}
{synopt:{cmd:e(N_cds)}}number of completely determined successes (not saved with {it:link} {it:cloglog}){p_end}
{synopt:{cmd:e(terza)}}{hi:2023} if Terza (2023) variance estimation, {hi:2017} otherwise{p_end}

{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cfbinout}{p_end}
{synopt:{cmd:e(title)}}Control function {it:link} regression{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(chi2type)}}{hi:Wald}{p_end}
{synopt:{cmd:e(generated)}}variables generated by {cmd:cfbinout}{p_end}
{synopt:{cmd:e(instruments)}}(excluded) instrumental variables{p_end}
{synopt:{cmd:e(endog)}}endogenous rhs variables{p_end}
{synopt:{cmd:e(exog)}}exogenous variables{p_end}
{synopt:{cmd:e(perfect)}}perfectly predicted rhs variables{p_end}
{synopt:{cmd:e(fsswitched)}}first-stage regressions switched to {it:linear} (only saved with {opt fsswitch}){p_end}
{synopt:{cmd:e(fslink)}}first-stage link function for binary variables{p_end}
{synopt:{cmd:e(link)}}second-stage link function{p_end}
{synopt:{cmd:e(properties)}}{opt b V}{p_end}
{synopt:{cmd:e(depvar)}}name of {it:depvar}{p_end}
{synopt:{cmd:e(which)}}max or min; whether optimizer is to perform maximization or minimization{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {opt vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable (only saved with {it:vcetype} {it:cluster}){p_end}
{synopt:{cmd:e(crossderiv)}}{opt analytic} or {opt numeric}{p_end}
{synopt:{cmd:e(sandwich)}}{opt sandwich} or {opt nosandwich}; empty if sandwich estimator was not requested{p_end}
{synopt:{cmd:e(wtype)}}weight type (only saved if weights are specified){p_end}
{synopt:{cmd:e(wexp)}}= {it:weight expression} (only saved if weights are specified){p_end}
{synopt:{cmd:e(technique)}}maximization technique (second-stage){p_end}
{synopt:{cmd:e(ml_method)}}type of ml method (second-stage){p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program (second-stage){p_end}
{synopt:{cmd:e(opt)}}type of optimization (second-stage){p_end}
{synopt:{cmd:e(marginsnotok)}}predictions disallowed by margins {opt margins}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {opt margins}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {opt predict}{p_end}

{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}vector of estimated coefficients{p_end}
{synopt:{cmd:e(V)}}estimated coefficient variance-covariance matrix{p_end}
{synopt:{cmd:e(G)}}matrix of estimated first-stage coefficients{p_end}
{synopt:{cmd:e(bfs)}}vector of estimated first-stage coefficients (only saved with {opt fskeep}){p_end}
{synopt:{cmd:e(Vfs)}}estimated first-stage coefficient variance-covariance matrix (only saved with {opt fskeep}){p_end}
{synopt:{cmd:e(mns)}}vector of means of the independent variables (not saved with {it:link} {it:cloglog}){p_end}
{synopt:{cmd:e(rules)}}information about perfect predictors (second-stage, not saved with {it:link} {it:cloglog}){p_end}
{synopt:{cmd:e(ilog)}}iteration log (second-stage, up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector (second-stage){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:References}

{pstd} Liu, W. (2023). {browse "https://ideas.repec.org/c/boc/bocode/s459239.html":IVCLOGLOG: Stata module to estimate a complementary log-log model with endogenous covariates, instrumented via the control function approach (i.e., 2SRI)}, 
{it:Statistical Software Components} S459239, Boston College Department of Economics, revised 18 Nov 2023. 

{pstd} Terza, J.V. (2023). Simpler standard errors for two-stage optimization estimators revisited, {it:The Stata Journal} 23(4), 1057-1061. 

{pstd} Terza, J.V. (2017). Two-stage residual inclusion estimation: A practitioners guide to Stata implementation, {it:The Stata Journal} 17(4), 916-938.
 
{pstd} Terza, J.V. (2016). Simpler Standard Errors for Two-stage Optimization Estimators, {it:The Stata Journal} 16(2), 368–385.

{pstd} Wooldridge, J.M. (2015). Control Function Methods in Applied Econometrics, {it:The Journal of Human Resources} 50(2), 420-445.


{title:Also see}

{psee} Manual:  {manlink R cfprobit}, {manlink R ivprobit}, {manlink R probit}, {manlink R logit}, {manlink R cloglog}

{psee} {space 2}Help:  {manhelp cfprobit R:cfprobit}, {manhelp ivprobit R:ivprobit}, {manhelp probit R:probit}, {manhelp logit R:logit}, {manhelp cloglog R:cloglog}{break} 

{psee} Online:   {helpb ivcloglog}{p_end} 


{title:Authors}

{psee} Harald Tauchmann{p_end}{psee} Friedrich-Alexander-Universit{c a:}t Erlangen-N{c u:}rnberg (FAU){p_end}{psee} N{c u:}rnberg, 
Germany{p_end}{psee}E-mail: harald.tauchmann@fau.de {p_end}

{psee} Elena Yurkevich{p_end}{psee} Friedrich-Alexander-Universit{c a:}t Erlangen-N{c u:}rnberg (FAU){p_end}{psee} N{c u:}rnberg, 
Germany{p_end}{psee}E-mail: elena.yurkevich@fau.de {p_end}


{title:Disclaimer}
 
{pstd} This software is provided "as is" without warranty of any kind, either expressed or implied. The entire risk as to the quality and 
performance of the program is with you. Should the program prove defective, you assume the cost of all necessary servicing, repair or 
correction. In no event will the copyright holders or their employers, or any other party who may modify and/or redistribute this software, 
be liable to you for damages, including any general, special, incidental or consequential damages arising out of the use or inability to 
use the program.{p_end} 


{title:Acknowledgements}

{pstd} We gratefully acknowledge comments and suggestions by the participants of the German Stata Conference 2024 and excellent research assistance by Michail Liatos.{p_end} 
