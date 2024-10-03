{smcl}
{* *! Version 2.0.0 20 September 2024}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:nehurdle} {hline 2}}estimation command for hurdle models.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 2 6 2}
	General Syntax:
{p_end}

{phang}
	{cmd:nehurdle} {depvar} [{indepvars}] {ifin}
	[{it:{help nehurdle##weight:weight}}] [{cmd:,}
	{{opt he:ckman}|{opt to:bit}|{opt tr:unc}|{opt truncp}|{opt truncnb1}|{opt truncnb2}} {it:shared_options}
	{it:specific_options} ]
{p_end}

{dlgtab:Models for Continuous Variables}

{p 2 6 2}
	Tobit's Syntax:
{p_end}

{phang}
	{cmd:nehurdle} {depvar} [{indepvars}] {ifin}
	[{it:{help nehurdle##weight:weight}}] {cmd:,} {opt to:bit}
	[ {it:shared_options} ]
{p_end}

{p 2 6 2}
	Normal Truncated Hurdle's Syntax:
{p_end}

{phang}
	{cmd:nehurdle} {depvar} [{indepvars}] {ifin}
	[{it:{help nehurdle##weight:weight}}] [{cmd:,} {opt tr:unc}
	{it:shared_options} {it:specific_options} ]
{p_end}

{p 2 6 2}
	Type II Tobit's Syntax:
{p_end}

{phang}
	{cmd:nehurdle} {depvar} [{indepvars}] {ifin}
	[{it:{help nehurdle##weight:weight}}] {cmd:,} {opt he:ckman}
	[ {it:shared_options} {it:specific_options} ]
{p_end}

{dlgtab:Models for Count Data}

{p 2 6 2}
	Poisson Truncated Hurdle's Syntax:
{p_end}

{phang}
	{cmd:nehurdle} {depvar} [{indepvars}] {ifin}
	[{it:{help nehurdle##weight:weight}}] {cmd:,} {opt truncp}
	[ {it:shared_options} {it:specific_options} ]
{p_end}

{p 2 6 2}
	NB1 Truncated Hurdle's Syntax:
{p_end}

{phang}
	{cmd:nehurdle} {depvar} [{indepvars}] {ifin}
	[{it:{help nehurdle##weight:weight}}] {cmd:,} {opt truncnb1}
	[ {it:shared_options} {it:specific_options} ]
{p_end}

{p 2 6 2}
	NB2 Truncated Hurdle's Syntax:
{p_end}

{phang}
	{cmd:nehurdle} {depvar} [{indepvars}] {ifin}
	[{it:{help nehurdle##weight:weight}}] {cmd:,} {opt truncnb2}
	[ {it:shared_options} {it:specific_options} ]
{p_end}

{title:Options}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Estimator}
{synopt:{opt he:ckman}}required to use the Type II Tobit estimator{p_end}
{synopt:{opt to:bit}}required to use the Tobit estimator{p_end}
{synopt:{opt tr:unc}}optional to use the Normal truncated hurdle estimator; this is
the default if no estimator option is specified{p_end}
{synopt:{opt truncp}}required to use the Poisson truncated hurdle estimator{p_end}
{synopt:{opt truncnb1}}required to use the NB1 truncated hurdle estimator{p_end}
{synopt:{opt truncnb2}}required to use the NB2 truncated hurdle estimator{p_end}

{syntab:Shared Options}
{synopt:{opt coefl:egend}}display legend instead of statistics{p_end}
{synopt:{opth exp:osure(varname)}}include ln({it:varname}) in the value equation
with coefficient constrained to 1{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{help nehurdle##mlopts:{it:ml options}}}options that work with {cmd:ml}{p_end}
{synopt:{opt nocon:stant}}suppress constant term in the value equation{p_end}
{synopt:{opt nohe:ader}}do not display the header of the results{p_end}
{synopt:{opt nolo:g}}do not display the iteration log of the log likelihood{p_end}
{synopt:{opth off:set(varname)}}include {it:varname} in value equation with
coefficient constrained to 1{p_end}
{synopt :{opth vce(vcetype)}}specifies the method to estimator for the variance
covariance matrix. {it:vcetype} may be {opt cl:uster} {it:clustvar}, {opt oim},
{opt opg}, or {opt r:obust}{p_end}

{syntab:Specific Options}
{p 6 6 2}
	The following can also be used with not all of the estimators. See
	{help nehurdle##spopts:Specific Options} for details on which can be used
	with whatestimator
{p_end}

{synopt:{opt expon:ential}}specifies the explained variable to be longnormally
distributed{p_end}
{synopt:{opt het}{bf:(}{help nehurdle##hetspec:{it:hetspec}}{opt )}}specifies
	the functional form of the value's heteroskedasticity or the heterogeneity
	in the dispersion{p_end}
{synopt:{opt nolrt:est}}specifies that the likelihood-ratio test of the
the dispersion parameter being zero should not be done{p_end}
{synopt:{opt sel:ect}{bf:(}{help nehurdle##selspec:selspec}{bf:)}}specifies the
independent variables and options for the selection equation{p_end}
{synoptline}
{marker hetspec}{...}
{p 4 6 2}
	{it:hetspec} for {opt het()} is {indepvars}, {opt nocons:tant}
{p_end}

{marker selspec}{...}
{p 4 6 2}
	{it:selspec} for {opt select()} is {indepvars}, {opth het(indepvars)}
	{opt nocons:tant} {opth exp:osure(varname)} {opth off:set(varname)}
{p_end}

{p 4 6 2}
	{it:indepvars} may contain factor variables; see {manhelp fvvarlist U}.
{p_end}
{marker weight}{...}
{p 4 6 2}
	{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see
	{manhelp weight U}.
{p_end}
{p 4 6 2}
	{cmd:bootstrap}, {cmd:by}, {cmd:fp}, {cmd:jacknife}, {cmd:statsby}, and
	{cmd:svy} are allowed; see {manhelp prefix U}.
{p_end}
{p 4 6 2}
	Weights are not allowed with either the {manhelp bootstrap R} prefix or the 
	{manhelp svy SVY} prefix.
{p_end}
{p 4 6 2}
	{cmd:vce()} not allowed with the {manhelp svy SVY} prefix.
{p_end}
{p 4 6 2}
	See {helpb nehurdle_postestimation} for features available after estimation.
{p_end}

 
{title:Description}

{pstd}{cmd:nehurdle} estimates different hurdle models via maximum likelihood.
For continuous variables it collects the Tobit ({help nehurdle##tobin:Tobin (1958)}),
(Log)Normal (Truncated) Hurdle ({help nehurdle##cragg:Cragg (1971)}), and
(Log)Normal Type II Tobit. For count data it collects the Poisson Truncated
Hurdle, and NB1 and NB2 Truncated Hurdle versions of the negative binomial
models. It allows to model heteroskedasticity in the selection process in
all models except Tobit. It also allows to model heteroskedasticity in the value
process for all (log)normal models, and heterogeneity in the dispersion parameter
in the negative binomial family models.

{pstd} It is common to observe variables of interest with many zeroes. {cmd:nehurdle}
provides a collection of estimators that can be used in explaining those variables,
for both continuous and discrete variables. Tobit is the original model for
continuous variables, but hurdle models add a level of flexibility in separating
the selection process from the value process. Most of the models here can be
estimated one way or another with {cmd:Stata}'s commands, so {cmd:nehurdle}'s
purpose is to provide a common interface that is extremely easy to use, and
adding some functionality, whether it is modeling heteroskedasticity in the
selection process, heterogeneity/heteroskedasticity in the value process,
or the ability to easily predict many different parameters after estimation that
would be more complicated otherwise.

{pstd}For information about all the models here, check chapters 19 and 20 of
{help nehurdle##ctriv:Cameron and Trivedi (2022)}. Another excellent reference
for the truncated hurdle models of count data is chapter 9 of
{help nehurdle##LFreese: Long and Freese (2014)}. The NB1 and NB2 names follow
{help nehurdle##ctcup: Cameron and Trivedi (2013)}.

{pstd}In all its estimations, {cmd:nehurdle} reports a pseudo R-squared that equals
the squared correlation coefficient of the predicted observed variable mean
and the explained variable.

{marker options}{...}
{title:Option Description}

{dlgtab:Estimator}

{p 4 4 2}
	These options are mutually exclusive, i.e. only one may be used at a time,
	since they specify the estimator to be used.
{p_end}

{phang}{opt heckman} is required to tell {cmd: nehurdle} to use the Type II Tobit
	estimator.
	
{phang}{opt tobit} is required to tell {cmd: nehurdle} to use the Tobit estimator.

{phang}{opt trunc} is optional to tell {cmd: nehurdle} to use the Normal
	Hurdle estimator. This is {cmd: nehurdle}'s default estimator, which is why
	it is optional to specify it.

{phang}{opt truncp} is required to tell {cmd: nehurdle} to use the Poisson
	Truncated Hurdle estimator.

{phang}{opt truncnb1} is required to tell {cmd: nehurdle} to use the NB1
	Truncated Hurdle estimator.
	
{phang}{opt truncnb2} is required to tell {cmd: nehurdle} to use the NB2
	Truncated Hurdle estimator.

{dlgtab:Shared Options}

{p 4 6 2}
	These options can be used with all estimators.
{p_end}

{phang}{opt coeflegend} see
     {helpb estimation options##coeflegend:[R] estimation options}.

{phang}{opth exposure(varname)} includes ln({it:varname}) in the model for the
	value equation with its coefficient constrained to 1.

{phang}{opt level(#)} see
	{helpb estimation options##level():[R] estimation options}.

{marker mlopts}{...}
{phang}{it:ml options}. {cmd:nehurdle} accepts the following maximum likelihood
options:

{pmore}{opt collinear} tells the maximum-likelihood estimator to keep collinear
variables. This is useful if you know that there are no collinear variables, and
thus, want to save the estimator time by not checking if there are any.

{pmore}{cmd:constraints(}{it:{help numlist}}|{it:matname}{cmd:)} specifies the
linear constraints to be applied during estimation. {opt constraints(numlist)}
specifies the constraints by number. Constraints are defined using the {cmd:constraint}
command. {opt constraint(matname)} specifies a matrix that contains the
constraints. See {manhelp constraint R}.

{pmore}{opt difficult} is sometimes helpful when you get the message
"not concave" in many of the iterations of the maximization process (when you
don't specify {opt nolog} as an option). This may be a sign that {cmd:ml}'s
standard stepping algorithm may not be working well. {opt difficult} specifies
that a different stepping algorithm be used in these non-concave regions.
Notice that this may not help, since there is no guarantee that {opt difficult}
will make things better than the default. See
{helpb ml##noninteractive_maxopts:[R] ml maximize options}.

{pmore}{opt gradient} displays the gradient vector after each iteration if the
log is being displayed, i.e. you have not specified {opt nolog}.

{pmore}{opt hessian} displays the negative hessian matrix after each iteration
if the log is being displayed, i.e. you have not specified {opt nolog}.

{pmore}{opt iterate(#)} specifies the maximum number of iterations to be used.
If convergence is achieved before reaching that maximum number, the optimizer
stops when convergence is declared. If the maximum number of iterations is
reached before achieving convergence, the optimizer stops as well and presents
the results it has at that iteration number. The default maximum number of
iterations is 16,000. You can change the default maximum number of iterations
with {cmd:set maxiter}.

{pmore}{opt ltolerance(#)} sets the level for log-likelihood tolerance
convergence. When the change in log-likelihood is less than that level,
log-likelihood convergence is achieved. The default is {bf:tolerance(1e-6)}.

{pmore}{opt nocnsnotes} prevents notes on contraints-related errors from
displaying above the estimation results. Sometimes these errors cause constraints
to be dropped, but others the constraint is still applied to the estimation.

{pmore}{opt nonrtolerance} turns off the default {opt nrtolerance()} criterion.

{pmore}{opt nrtolerance(#)} specifies the level for scaled gradient tolerance.
When the scaled gradient, g*inv(H)*g', has a value that is less than the level
scaled gradient convergence is achieved. {cmd:Stata}'s default is
{cmd:nrtolerance(1e-5)}, but since all ml evaluators in {cmd:nehurdle} have
both the analytical gradient and hessian programmed, it sets the default to
{cmd:nrtolerance(1e-12)}.

{pmore}{opt qtolerance(#)} sets the level of convergene for the q-H matrix. It
works when specified with algorithms {cmd:bhhh}, {cmd:dfp}, or
{cmd:bfgs}, and tells the otpimizer to uses the q-H matrix as the final check
for convergence rather than scaled gradient and the H matrix.

{pmore}{opt shownrtolerance} is a synonim for {opt showtolerance}.

{pmore}{opt showstep} shows information about the steps within an interation in
the iteration log, and shows the log even if you have specified {opt nolog}.

{pmore}{opt showtolerance} shows the log-likelihood tolerance in each step in
the iteration log until the log-likelihood convergence criterion has been met.
It then shows the scaled gradient g*inv(H)*g'. It does so even if you have
specified {opt nolog}.

{pmore}{opt technique(algorithm_spec)} specifies the algorithm(s) used and when
they are used in the maximization of the log likelihood. The possible algorithms
are: {opt nr}, Newton-Raphson algorithm, {opt bhhh}, Brendt-Hall-Hall-Hausman
algorithm, {opt dfp}, Davidon-Fletcher-Powell (DFP) algorithm, and {opt bfgs},
Broyden-Fletcher-Goldfarb-Shanno algorithm. The default algorithm is {opt nr}.
You can specify different algorithms to be used at different intervals of the
iterations. {it:algorithm_spec} is {it:algorithm} [ {it:#} [ {it:algorithm}
	[{it:#}] ] ... ] where {it:algorithm} is
	{{opt nr}|{opt bhhh}|{opt dfp}|{opt bfgs}}. For details, see
	{help nehurdle##gould:Pitblado, Poi, and Gould (2024)}.

{pmore}{opt tolerance(#)} sets the level for the coefficient vector tolerance.
When the relative change in the coefficient vector is less than the specified
level, coefficient vector convergence is achieved. The default is 
{bf:tolerance(1e-6)}. 

{pmore}{opt trace} displays the vector of the current estimates of the
coefficients after the each iteration in the iteration log, even if you have
specified {opt nolog}.

{phang}{opt noconstant} see
{helpb estimation options##noconstant:[R] estimation options}.

{phang}{opt nolog} tells {cmd:nehurdle} to hide the iteration information of the
	maximum-likelihood estiamtor.
	
{phang}{opth offset(varname)} adds {it:varname} to the model of the value equation
with its coefficient constrained to 1.

{phang}{opt vce(vcetype)} specifies the type of standard error reported, which
includes types that are robust to some kinds of misspecification
({cmd:robust}), that allow for intragroup correlation ({cmd:cluster}
{it:clustvar}), and that are derived from asymptotic theory
({cmd:oim}, {cmd:opg}). See {helpb vce_option:[R] {it:vce_option}}.

{marker spopts}{...}
{dlgtab:Specific Options}

{phang}
{opt exponential} tells {cmd:nehurdle} that the explained variable is lognormally,
rather than normally, distributed. {cmd:nehurdle} will estimate a linear in
parameters value equation with the explained variable being the natural logarithm
of the actual variable. 
	
{pmore}{cmd:nehurdle} takes care of the transformation
internally, so you still need to pass the original variable as the explained
variable in the variable list.

{pmore} This option is only valid for the models that
assume a normal distribution of the value process: Tobit, Normal Hurdle, and
Type II Tobit.

{phang}
{opt het}{bf:({indepvars},} {opt nocons:tant)} lets you specify the functional
form for either heteroskedasticity in the value process in all the models for
continuous variables (Tobit, Normal Hurdle, and Type II Tobit), or observed
heterogeneity in the dispersion parameter for negative binomial family of
estimators (NB1 and NB2 Truncated Hurdle models).

{pmore}It doesn't work with the Poisson Truncated Hurdle model, because the
Poisson assumption fixes the variance to be equal to the mean, and there cannot
be overdispersion, so there is no dispersion parameter to model.

{phang}
{opt nolrtest} tells {cmd:nehurdle} to not do the likelihood-ratio test of the
dispersion parameter being zero, i.e. the test of whether a negative binomial
model collapses into the Poisson model.

{pmore}This is only available with the NB1 and NB2 truncated hurdle models,
since they are the ones that have a dispersion parameter, you have not
modeled heterogeneity in the dispersion, and you are not estimating robust or
clustered standard errors. In any of these last two cases the likelihood-ratio
test is not performed, and {opt:nolrtest} will be ignored because it becomes
redundant.

{phang}
{opt select(:}{bf:{indepvars}, het({indepvars}) noconstant exposure({varname}) offset({varname}))}
specifies the composition of the explanatory variables in the selection equation
as well as whether to model heteroskedasticity in the selection equation. This
is an optional option (all of it).

{pmore}{opt select()} works with all the models except for the Tobit model. It
doesn't work with the Tobit estimator because the Tobit estimator doesn't have
separate selection and value processes.

{pmore}The first {it:{indepvars}} sets the independent variables of the
selection equation. If you don't include it, {cmd:nehurdle} assumes that
the independent variables for the selection equation are the same as those
of the value equation.

{pmore}{opth het(indepvars)} sets the independent variables of the heteroskedasticity
in the selection process.

{pmore}{opt noconstant} tells {cmd:nehurdle} to not include a constant in the
selection equation.

{pmore}{opt exposure(varname)} adds ln({it:varname}) to the model of the selection
equation and constraints its coefficient to 1.

{pmore}{opt offset(varname)} adds {it:varname} to the model of the selection
equation and constraints its coefficient to 1.

{pmore}You can specify options for the selection equation without specifying
the independent variables of that equation. If you do that {cmd:nehurdle} will
use the same independent variables as for the value equation. For example
{bf: select(, noconstant)} will use the same independent variables as in the
value equation and not include a constant term in the selection equation.

{pmore}Since {cmd:nehurdle} assumes normality of the errors in the selection
process, the estimator for the selection equation is actually a Probit estimator,
like {cmd:probit}. When modeling heteroskedasticity in the selection process, it
is the heteroskedastic Probit estimator, like {cmd:hetprobit}.

{marker examples}{...}
{title:Examples}

{dlgtab:Models for Continuous Variables}

{pstd}Data Setup{p_end}
{phang2}. {stata "webuse womenwk, clear"}{p_end}
{phang2}. {stata "replace wage = 0 if missing(wage)"}{p_end}
{phang2}. {stata "global xvars i.married children educ age"}{p_end}

{pstd}Homoskedastic Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, tobit nolog"}{p_end}
{phang2}. {stata "tobit wage $xvars, ll nolog"}{p_end}

{pstd}Homoskedastic Exponential Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, tobit expon nolog"}{p_end}
{phang2}. {stata "gen double lny = ln(wage)"}{p_end}
{phang2}. {stata "summarize lny, mean"}{p_end}
{phang2}. {stata "replace lny = (r(min) - 1e-7) if missing(lny)"}{p_end}
{phang2}. {stata "tobit lny $xvars, ll nolog"}{p_end}
{phang2}. {stata "drop lny"}{p_end}

{pstd}Heteroskedastic Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, tobit het($xvars) offset(age) nolog"}{p_end}

{pstd}Homoskedastic Normal Truncated Hurdle{p_end}
{phang2}. {stata "nehurdle wage $xvars, nolog"}{p_end}

{pstd}Value Heteroskedastic Lognormal Hurdle{p_end}
{phang2}. {stata "nehurdle wage $xvars, het($xvars) expon nolog"}{p_end}

{pstd}Selection and Value Heteroskedastic Normal Truncated Hurdle{p_end}
{phang2}. {stata "nehurdle wage $xvars, het($xvars) sel(, het($xvars)) nolog"}{p_end}

{pstd}Homoskedastic Type II Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, heck nolog"}{p_end}
{phang2}. {stata "gen byte dy = wage > 0"}{p_end}
{phang2}. {stata "heckman wage $xvars, sel(dy = $xvars) nolog"}{p_end}
{phang2}. {stata "drop dy"}{p_end}

{pstd}Homoskedastic Exponential Type II Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, heck expon nolog"}{p_end}
{phang2}. {stata "gen double lny = ln(wage)"}{p_end}
{phang2}. {stata "heckman lny $xvars, sel($xvars) nolog"}{p_end}
{phang2}. {stata "drop lny"}{p_end}

{pstd}Value Heteroskedastic Type II Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, heck het($xvars) nolog"}{p_end}

{pstd}Selection Heteroskedastic Lognormal Type II Tobit:{p_end}
{phang2}. {stata "nehurdle wage $xvars, heck expon sel(, het($xvars)) nolog"}{p_end}

{dlgtab:Models for Count Data}

{pstd}Data Setup{p_end}
{phang2}. {stata "use http://www.stata-press.com/data/mus2/mus220mepsdocvis, clear"}{p_end}
{phang2}. {stata global xvars i.private i.medicaid age educyr i.actlim totchr}{p_end}
{phang2}. {stata global shet income age totchr}{p_end}
{phang2}. {stata global ahet age totchr i.female}{p_end}

{pstd}Poisson Truncated Hurdle:{p_end}
{phang2}. {stata "nehurdle docvis $xvars, truncp nolog"}{p_end}

{pstd}Selection Heteroskedastic Poisson Truncated Hurdle:{p_end}
{phang2}. {stata "nehurdle docvis $xvars, truncp sel(, het($shet)) nolog"}{p_end}

{pstd}NB1 Truncated Hurdle:{p_end}
{phang2}. {stata nehurdle docvis $xvars, truncnb1 nolog}{p_end}

{pstd}NB1 Truncated Hurdle with dispersion heterogeneity:{p_end}
{phang2}. {stata "nehurdle docvis $xvars, truncnb1 nolog het($ahet)"}{p_end}

{pstd}NB2 Truncated Hurdle:{p_end}
{phang2}. {stata nehurdle docvis $xvars, truncnb2 nolog}{p_end}

{pstd}Selection Heteroskedastic NB2 Truncated Hurdle with dispersion heterogeneity:{p_end}
{phang2}. {stata "nehurdle docvis $xvars, truncnb2 nolog het($ahet) sel(, het($shet))"}{p_end}

{title:Stored Results}
{pstd}
{cmd:nehurdle} stores the following in {cmd:e()}:

{marker stscal}{...}
{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}total number of observations{p_end}
{synopt:{cmd:e(N_c)}}number of censored observations{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters; reported when {cmd:vce(cluster}
	{it:clustvar}{cmd:)} is specified; see {findalias frrobust}{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_aux)}}number of auxiliary parameters{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(df_m)}}number of non-constant parameters estimated (degrees of
	freedom of the overall significance test){p_end}
{synopt:{cmd:e(chi2)}}overall significance test Wald chi-squared{p_end}
{synopt:{cmd:e(p)}}overall significance test p-value{p_end}
{synopt:{cmd:e(sel_df)}}number of non-constant parameters in the selection
	equation (degrees of freedom of the joint significance test for the
	selection equation); reported for all models except Tobit{p_end}
{synopt:{cmd:e(sel_chi2)}}selection equation joint significance test Wald
	chi-squared; reported for all models except Tobit{p_end}
{synopt:{cmd:e(sel_p)}}selection equation joint significance test p-value;
	reported for all models except Tobit{p_end}
{synopt:{cmd:e(val_df)}}number of non-constant parameters in the value equation
	(degrees of freedom of the joint significance test for the value equation);
	reported for all Truncated Hurdle models, and the Type II Tobit estimations;
	also reported for the Tobit model when modeling value heteroskedasticity{p_end}
{synopt:{cmd:e(val_chi2)}}value equation joint significance test Wald 
	chi-squared; reported for all Truncated Hurdle models, and the Type II Tobit estimations;
	also reported for the Tobit model when modeling value heteroskedasticity{p_end}
{synopt:{cmd:e(val_p)}}value equation joint significance test p-value;
	reported for all Truncated Hurdle models, and the Type II Tobit estimations;
	also reported for the Tobit model when modeling value heteroskedasticity{p_end}
{synopt:{cmd:e(het_df)}}number of non-constant parameters in the value
	hetersokedasticity / dispersion heterogeneity equation (degrees of freedom
	of the joint significance test for value heteroskedasticity / dispersion
	heterogeneity); reported for all estimations that model the value
	heteroksedasticity or dispersion heterogeneity{p_end}
{synopt:{cmd:e(het_chi2)}}value heteroskedasticity / dispersion heterogeneity
	equation joint significance test Wald chi-squared; reported for all
	estimations that model the value heteroksedasticity or dispersion
	heterogeneity{p_end}
{synopt:{cmd:e(het_p)}}value heteroskedasticity / dispersion heterogeneity
	equation joint significance test p-value; reported for all estimations that
	model the value	heteroksedasticity / dispersion heterogeneity{p_end}
{synopt:{cmd:e(selhet_df)}}number of non-constant parameters in the selection
	hetersokedasticity equation (degrees of freedom of the joint significance
	test for selection heteroskedasticity); reported for all estimations that
	model the selection heteroksedasticity{p_end}
{synopt:{cmd:e(selhet_chi2)}}selection heteroskedasticity equation joint
	significance test Wald chi-squared; reported for all estimations that model
	the selection heteroksedasticity{p_end}
{synopt:{cmd:e(selhet_p)}}selection heteroskedasticity equation joint
	significance test p-value; reported for all estimations that model the
	selection heteroksedasticity{p_end}
{synopt:{cmd:e(chi2_c)}}chi-squared of LR test against Truncated Hurdle;
	reported for Type II Tobit estimations{p_end}
{synopt:{cmd:e(p_c)}}LR test against Truncated Hurdle significance{p_end}
{synopt:{cmd:e(r2)}}pseudo r-squared{p_end}
{synopt:{cmd:e(gamma)}}lowest value of the natural logarithm of the dependent
	variable in the value equation; reported for the Lognormal Tobit{p_end}
{synopt:{cmd:e(sigma)}}standard deviation of the value process; reported for
	value homoskedastic estimations of (Log)Normal models{p_end}
{synopt:{cmd:e(rho)}}correlation between selection and value errors; reported
	for Type II Tobit estimations{p_end}
{synopt:{cmd:e(lambda)}}lambda; reported for Type II Tobit estimations{p_end}
	
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:nehurdle}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(cmd_opt)}}the estimator option: {opt heckman}, {opt tobit},
	{opt trunc}, {opt truncp}, {opt truncnb1}, or {opt truncnb2}{p_end}
{synopt:{cmd:e(depvar)}}the dependent variable{p_end}
{synopt:{cmd:e(wtype)}}type of weight; reported for estimations using weights{p_end}
{synopt:{cmd:e(wexp)}}weight expression; reported for estimations using weights{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {opt vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable; reported for estimations
	with clustered standard errors{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(which)}}{opt max} or {opt min}; whether the optimizer is to
	perform maximization or minimization{p_end}
{synopt:{cmd:e(method)}}{cmd:ml}{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(properties)}}{opt b} {opt V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(asbalanced)}}factor variables {opt fvset} as {opt asbalanced}{p_end}
{synopt:{cmd:e(asbobserved)}}factor variables {opt fvset} as {opt asobserved}{p_end}
{synopt:{cmd:e(chi2type)}}{opt Wald}; type of model chi-squred test{p_end}
			
{title:References}

{marker ctcup}{...}
{phang}
	Cameron, A. Colin, and Pravin K. Trivedi. 2013.
	{it:Regression Analysis of Count Data}. Econometric Society Monographs. 2nd ed.
	Cambrdige, UK: Cambridge University Press.
{p_end}

{marker ctriv}{...}
{phang}
	Cameron, A. Colin, and Pravin K. Trivedi. 2022.
	{browse "https://www.stata.com/bookstore/microeconometrics-stata/":{it:Micreconometrics Using Stata}. 2nd ed.}
	Vol II: Nonlinear Models and Casual Inference Methods. College Station, TX: Stata Press.
{p_end}

{marker cragg}{...}
{phang}
	Cragg John G. 1971. Some Statistical Models for Limited Dependent Variables
	with Application to the Demand for Durable Goods. {it:Econometrica} 39(5):
	829-844
{p_end}

{marker gould}{...}
{phang}
	Pitbaldo, Jeffrey, Poi, Brian P., and William M. Gould. 2024.
	{browse "https://www.stata.com/bookstore/maximum-likelihood-estimation-stata/":{it:Maximum Likelihood Estimation with Stata}. 5th ed.}
	College Station, TX: Stata Press.
{p_end}

{marker LFreese}{...}
{phang}
	Long, J. Scott, and Jeremy Freese. 2014.
	{browse "https://www.stata.com/bookstore/regression-models-categorical-dependent-variables/":{it:Regression Models for Categorical Dependent Variables Using Stata}. 4th ed.}
	College Station, TX: Stata Press.
{p_end}

{marker tobin}{...}
{phang}
	Tobin, James. 1958. Estimation of Relationships for Limited Dependent
	Variables. {it:Econometrica} 26(1): 24-36
{p_end}

{title:Acknowledgements}

{p 4 4 2}
	I would like to thank Isabel Canette from StataCorp LLC for her patience and
	her insightful comments that helped me debug much of {cmd: nehurdle}'s predict
	functionality.
{p_end}

{title:Author}

{phang}Alfonso S{c a'}nchez-Pe{c n~}alver{p_end}
{phang}alfonsos1@usf.edu{p_end}

{title:Also See}

{psee}
Manual: {manlink R heckman}, {manlink R hetprobit}, {manlink R probit},
{manlink R tnbreg}, {manlink R tobit}, {manlink R tpoisson}
{p_end}
