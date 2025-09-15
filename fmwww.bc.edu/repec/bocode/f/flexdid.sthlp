{smcl}
{* *! version 1.0.0  10sep2025}{...}
{viewerjumpto "Syntax" "flexdid##syntax"}{...}
{viewerjumpto "Description" "flexdid##description"}{...}
{viewerjumpto "Options" "flexdid##options"}{...}
{viewerjumpto "Examples" "flexdid##examples"}{...}
{viewerjumpto "Stored results" "flexdid##results"}{...}
{p}
{bf:flexdid} {hline 2} Flexible estimation of difference-in-differences regression with staggered implementation timing 


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:flexdid}
	{help varname:{it:ovar}}
	{help varlist:{it:covarlist}}
	{ifin} 
	[{help flexdid##weight:{it:weight}}]{cmd:,}
	{opth tx:(varname:txvar)}
	{opth gr:oup(varname:groupvar)}
        {opth ti:me(varname:timevar)}
	[{help flexdid##optstbl:{it:options}}]
	
	
{phang}
{it:ovar} is the outcome of interest.{p_end}
{phang}
{it:covarlist} specifies the covariates in the model and may contain
factor variables; see {help fvvarlist}.{p_end}
{phang}
{it:txvar} is a binary variable indicating observations subject to
treatment.{p_end}
{phang}
{it:groupvar} is a categorical variable that indicates the group level at
which the treatment occurs.{p_end}
{phang}
{it:timevar} is an integer-valued time variable.{p_end}	 
	

{marker optstbl}{...}
{synoptset 28 tabbed}{...}
{synopthdr} 
{synoptline}
{syntab:Model}
{p2coldent :* {opth tx:(varname:txvar)}}specify the treatment variable{p_end}
{p2coldent :* {opth gr:oup(varname:groupvar)}}specify the group variable and level of fixed effects{p_end}
{p2coldent :* {opth ti:me(varname:timevar)}}specify the time variable{p_end}
{synopt :{opth spec:ification(flexdid##mtype:stype)}}specify the regression; 
default is {cmd:specification(lagsonly)}{p_end}
{synopt :{opth txgr:oup(varname:txgroupvar)}}specify alternative treatment group variable; fixed effects are
estimated at the {it:groupvar} level{p_end}
{synopt :{opth xint:eract(varlist:intvarlist)}}specify covariate interactions;
default is all covariates interacted{p_end}
{synopt :{opt noxint:eract}}specify no covariate interactions;
default is fully interacted covariates{p_end}
{synopt :{opth userco:hort(varlist:cohortvar)}}specify the cohort variable if the internally generated cohort 
variable is inappropriate{p_end}
{synopt :{opt ver:bose}}display output of underlying regression{p_end}

{syntab:SE/Robust}
{synopt :{opth vce:(varlist:vcetype)}}{it:vcetype} may be {opt cl:uster} {it:clustvar}
or {opt r:obust}; default is {opt cl:uster} {it:groupvar} {p_end}
{synoptline}

{marker stype}{...}
{synoptset 28}{...}
{synopthdr:stype}
{synoptline}
{synopt :{opt lagsonly}}specify the regression to include only lags parameters; the default{p_end}
{synopt :{opt lagsandleads}}specify the regression to include lags and leads parameters{p_end}
{synoptline}

{p 4 6 2}
* {opt tx()} {opt group()} and {opt time()} are required.{p_end}
{p 4 6 2}
{it:covarlist} may contain factor variables; see {help fvvarlist}.{p_end}
{marker weight}{...}
{p 4 6 2}
{cmd:fweight}s and {cmd:pweight}s are allowed;
see {help weight}.{p_end}
{p 4 6 2}
See {helpb flexdid postestimation} for aggregation features available after estimation. 
Also see {helpb regress postestimation} for additional features available after OLS regression.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:flexdid} estimates average treatment effects on the treated (ATETs) in difference-in-differences designs with
staggered implementation of treatment using a flexible linear model estimated by pooled OLS with covariates, (FLEX),
as described in Deb et al. (2025). In the design, there must be at least one time-period in which all units are 
untreated, i.e., there cannot be any always-treated units. In addition, the typical design includes a set of 
never-treated units. FLEX can be specified using lags only parameters. In this case, the FLEX regression
produces group by time effects that are identical to those producted by the estimator described in Borusyak et al. (2021). 
FLEX can also be specified using lags and leads parameters. In this case, when there are no covariates, the 
FLEX regression produces cohort by time effects that are identical to those produced by the regression adjustment
estimator described in Callaway and Sant'Anna (2021). 

{pstd}
{cmd:flexdid} allows for specification flexibility in a number of dimensions. The basic specification interacts
all covariates with treatment, group and time indicators. Optionally, the user can select a subset of covariates to
be included in the interactions, with a larger set of covariates entering the regression in the typical additive manner.
{cmd:flexdid} also allows the treatment group indicators to be disaggregates of cohorts, and for the group-level fixed
effects in the regression to be different from (typically disaggregates of) the treatment group indicators. {cmd:flexdid} 
can handle designs with no never-treated units with additional identification assumptions. {cmd:flexdid} can also 
handle designs in which data is missing in some time-periods (periods in which cohorts of treatment started but are
unobserved).


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opth tx:(varname:txvar)} specifies a binary treatment variable that indicates whether
an observation is treated in a given time period.

{phang}
{opth gr:oup(varname:groupvar)} specifies a numeric group variable that indicates the level
at which treatment occurs and the level of fixed effects.

{phang}
{opth ti:me(varname:timevar)} specifies a numeric time variable that indicates when 
treatment occurs for an observation.

{phang}
{opt spec:ification(stype)} specifies the regression, either {cmd: lagsonly}
or {cmd: lagsandleads}; the default is {cmd:specification(lagsonly)}.  

{phang2}{cmd: lagsonly} specifies the estimation of the lags only specification. In the 
lags only specification all pre-period effects are set to zero.{p_end}

{phang2}{cmd: lagsandleads} specifies the estimation of the lags and leads specification. In the 
lags and leads specification, only the effect in the period preceding the first period of treatment 
for each cohort is set to zero.{p_end}

{phang}
{opth txgr:oup(varname:txgvar)} specifies alternative group variable, 
overriding {opth gr:oup(varlist:groupvar)}; fixed effects remain at {it:groupvar} level.

{phang}
{opth xint:eract(varlist:intvarlist)} specifies covariate interactions that
 are included in the regression, if unspecified the default is to interact all
 the covariates in the model with treatment group, and group and time indicators. 
 Typically, {it:intvarlist} is a strict subset of {it:covarlist}.
 
{phang} 
{opt noxint:eract} specifies no covariate interactions in the regression, covariates are
only included in the regression additively. The default is to interact all 
covariates in the model.

{phang}
{opth userco:hort(varname:cohortvar)} specifies a user-defined cohort variable, overriding 
the internal cohort variable calculated using {opth tx:(varlist:txvar)} and {opth ti:me(varlist:timevar)}. 
It is useful in situations where the internal cohort variable is incorrect or inappropriate.

{phang}
{opt ver:bose} displays the output of the underlying OLS regression. Allows the user to see
the table of {cmd:flexdid} regression estimates.

{dlgtab:SE/Robust}

{marker vcetype}{...}
{phang}
{opt vce:(vcetype)} specifies the type of standard errors reported, which includes {cmd:vce(cluster} {it:clustvar}}
that allows for intragroup correlation, and {cmd:vce(robust)} that allows for heteroskedasticity. 
{cmd:vce(cluster} {it:groupvar}} is the default.


{marker examples}{...}
{title:Examples}

{pstd}
Setup{p_end}
{phang2}{cmd:.  webuse hhabits}

{pstd}
Estimate the FLEX regression of treatment, {cmd:hhabit}, on outcome body mass index, {cmd:bmi},
for school districts by year; using the lags only specification. Reports the overall ATET.{p_end}
{phang2}{cmd:. flexdid bmi, tx(hhabit) group(schools) time(year)}{p_end}

{pstd}
As above but include {cmd:medu}, {cmd:sports} and {cmd:girl} as covariates. Covariates are included additively 
and as interactions with the treatment group, group and time indicators. Reports the overall ATET. Also displays the
underlying regression with the {cmd:verbose} option.{p_end}
{phang2}{cmd:. flexdid bmi medu sports girl, tx(hhabit) group(schools) time(year) verbose}{p_end}

{pstd}
Estimate the FLEX regression of treatment, {cmd:hhabit}, on outcome body mass index, {cmd:bmi}
for school districts over year; using the lags and leads specification and 
{cmd:medu}, {cmd:sports} and {cmd:girl} as covariates. Reports the overall ATET.{p_end}
{phang2}{cmd:. flexdid bmi medu sports girl, tx(hhabit) group(schools) time(year)} 
        {cmd:  specification(lagsandleads)}{p_end}

{pstd}
As above but treatment is estimated at the cohort by year level, {cmd:txgr(chrt)}, while 
the regression fixed effects are estimated at the {cmd:group} level and the standard errors 
are clustered at the {cmd:group}-level, {cmd:gr(schools)}. Reports the overall ATET.{p_end}

{phang2}Setup - manually create cohort variable{p_end}
{phang2}{cmd:. egen chrt = min(year/hhabit), by(schools)}{p_end}
{phang2}{cmd:. replace chrt = 0 if chrt==.}{p_end}
	 
{phang2}{cmd:. flexdid bmi, tx(hhabit) gr(schools) txgr(chrt) ti(year)} 
        {cmd:vce(cluster schools) specification(lagsandleads)}{p_end}
	
{pstd}
As above with treatment estimated at the cohort by year level, regression fixed effects at the 
cohort level and standard errors clustered at the {cmd:group} level. The cohort by year
effects are identical to those obtained using {cmd: hdidregress ra}{p_end}
{phang2}{cmd:. flexdid bmi, tx(hhabit) gr(chrt) ti(year) vce(cluster schools)} 
        {cmd:specification(lagsandleads) verbose}{p_end}
	
{phang2}{cmd:. hdidregress ra (bmi) (hhabit), group(schools) time(year) basetime(common)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:flexdid} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(sum_w)}}sum of weights{p_end}
{synopt :{cmd:e(N_clust)}}number of clusters{p_end}
{synopt :{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt :{cmd:e(rss)}}residual sum of squares{p_end}
{synopt :{cmd:e(mss)}}model sum of squares{p_end}
{synopt :{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt :{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt :{cmd:e(F)}}{it:F} statistic{p_end}
{synopt :{cmd:e(ll)}}log likelihood, assuming i.i.d. normal errors{p_end}
{synopt :{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:flexdid}{p_end}
{synopt :{cmd:e(specification)}}model specification either {cmd:lagsonly} or {cmd:lagsleads}{p_end}
{synopt :{cmd:e(cmdline)}}command as typed{p_end}
{synopt :{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt :{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end}
{synopt :{cmd:e(model}}{cmd:ols}{p_end}
{synopt :{cmd:e(depvar)}}name of outcome variable{p_end}
{synopt :{cmd:e(tx)}}name of {it:txvar}, binary treatment variable{p_end}
{synopt :{cmd:e(group)}}name of {it:groupvar}, group variable{p_end}
{synopt :{cmd:e(time)}}name of {it:timevar}, time variable{p_end}
{synopt :{cmd:e(txgroup)}}name of treatment group variable{p_end}
{synopt :{cmd:e(usercohort)}}name of user-specified cohort variable{p_end}
{synopt :{cmd:e(title)}}title in estimation output when {cmd:vce()} is not {cmd:ols}{p_end}
{synopt :{cmd:e(vce)}}{it:vcetype} specified by {cmd:vce()}{p_end}
{synopt :{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt :{cmd:e(vcetype)}}title used to label Std. err.{p_end}
{synopt :{cmd:e(wtype)}}weight type{p_end}
{synopt :{cmd:e(wexp)}}weight expression{p_end}
{synopt :{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt :{cmd:e(marginsok)}}predictions allowed by {cmd:margins}{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt :{cmd:e(b)}}coefficient vector{p_end}
{synopt :{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt :{cmd:e(V_modelbased)}}model-based variance{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}

{pstd}
In addition to the above, the following is stored in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2:Macros}{p_end}
{synopt :{cmd:r(atettype)}}ATET option specified{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt :{cmd:r(table)}}matrix containing the coefficients with their standard errors,
test statistics, {it:p}-values, and confidence intervals{p_end}
{synopt :{cmd:r(b)}}coefficient vector{p_end}
{synopt :{cmd:r(V)}}variance-covariance matrix of the estimators{p_end}


{pstd}
In addition to the above, the following are added to the dataset:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2:Variables*}{p_end}
{synopt :{cmd:_Chrt}}internally generated cohort variable{p_end}
{synopt :{cmd:_Grp}}internally generated group variable{p_end}
{synopt :{cmd:_Tx}}internally generated treatment variable{p_end}

{pstd}
*{cmd:flexdid} will overwrite variables in the dataset with the same names. 
Therefore, any such variables should be dropped or renamed before using {cmd:flexdid}.



{marker authors}{...}
{title:Authors}

{pstd}
Partha Deb{break}
Hunter College, CUNY and NBER{break}
partha.deb@hunter.cuny.edu{p_end}


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
The flexible regression (FLEX) that estimates average treatment effects on the treated (ATETs) 
in difference-in-differences designs with staggered implementation is conceived, described and 
implemented in Deb et al. (2025). Thus, without Edward Norton, Jeff Wooldridge and Jeff Zabel
there would be no {cmd:flexdid}. In addition, Anjelica Gangaram helped write the help file and 
Jacky Wu helped with initial coding of the package.{p_end}


{marker references}{...}
{title:References}

{phang}Borusyak, K., Jaravel, X., & Spiess, J. (2024). "Revisiting Event-study Designs: 
Robust and Efficient Estimation", {it:Review of Economic Studies}, 91(6), 3253-3285.{p_end}

{phang}Callaway, B. and Sant'Anna, P. H. C. (2021). "Difference-in-Differences 
with multiple time periods", {it:Journal of Econometrics}, 225(2):200-230.{p_end}

{phang}Deb, P., Norton, E. C., Wooldridge, J. M., Zabel, J. E. (2025), "A Flexible, 
Heterogeneous Treatment Effects Difference-in-Differences Estimator for Repeated 
Cross-Sections", National Bureau of Economic Research, Working Paper Series, No. 33026.{p_end}

