{smcl}
{* *! v4.0.2 21apr2022}{...}
{vieweralsosee "mvmeta (if installed)" "mvmeta"}{...}
{viewerjumpto "Description" "mvmeta_make##description"}{...}
{viewerjumpto "Syntax" "mvmeta_make##syntax"}{...}
{viewerjumpto "Which coefficients are used?" "mvmeta_make##whichcoeffs"}{...}
{viewerjumpto "Perfect prediction" "mvmeta_make##pp"}{...}
{viewerjumpto "Returned results" "mvmeta_make##returned"}{...}
{viewerjumpto "Changes since publication in Stata Journal" "mvmeta_make##whatsnew"}{...}
{viewerjumpto "Limitations" "mvmeta_make##limitations"}{...}
{viewerjumpto "Examples" "mvmeta_make##examples"}{...}
{viewerjumpto "References" "mvmeta_make##refs"}{...}
{viewerjumpto "Updates" "mvmeta_make##updates"}{...}
{title:Title}

{phang}{bf:mvmeta_make} {hline 2} Prepare data for multivariate meta-analysis


{title:Description}{marker description}

{pstd}{cmd:mvmeta_make} is a utility to produce data in a suitable format for
multivariate meta-analysis.
It performs {it:regression_command} for each combination of levels of {it:byvarlist}. 
It then stores the results in the format required by {helpb mvmeta}.


{title:Syntax}{marker syntax}

Classic syntax:

{phang}
{cmd:mvmeta_make}
{it:regression_command}
{ifin}
{weight}{cmd:,}
{cmd:by(}{it:byvarlist}{cmd:)}
[{it:mvmeta_make_options}
{it:regression_options}]

Prefix syntax:

{phang}
{cmd:mvmeta_make},
{cmd:by(}{it:byvarlist}{cmd:)}
[{it:mvmeta_make_options}]: {it:regression_command}
{ifin}
{weight}{cmd:,}
[{it:regression_options}]

where {it:mvmeta_make_options} are

{phang}
[{cmdab:sav:ing(}{it:savefile}{cmd:)}
{cmd:replace}
{cmd:append}
{cmd:clear}
{cmdab:usev:ars(}{it:string}{cmd:)}
{cmdab:usec:onstant}
{cmdab:usee:qs(}{it:eqlist}|*{cmd:)} 
{cmdab:learn:if(}{it:exp}{cmd:)} 
{cmdab:usecoe:fs(}{it:coeflist}{cmd:)} 
{cmd:esave(}{it:namelist}{cmd:)}
{cmd:counts(}{it:string}{cmd:)}
{cmdab:coll:apse(}{it:collapse_exp}{cmd:)}
{cmdab:name:s(}{it:bname Vname}{cmd:)}
{cmd:infix(}{it:string}{cmd:)}
{cmdab:long:names}
{cmd:keepmat}
{cmdab:nodet:ails}
{cmd:pause}
{cmdab:ppf:ix(none|check|all)}
{cmdab:aug:wt(#)}
{cmdab:noaugl:ist}
{cmdab:ppc:md(}{it:regcmd}[{it:,options}]{cmd:)}
{cmd:hard}
{it:regression_options}]

and {it:regression_options} are any options allowed for {it:regression_command}.


{title:Options: by-variable}

{phang}
{cmd:by(}{it:byvarlist}{cmd:)} is not optional. It identifies the studies, in each of which the regression
command will be performed.


{title:Options: saved file}

{p}Either {cmd:saving(}{it:savefile}{cmd:)} or {cmd:clear} or both must be specified.

{phang}
{cmdab:sav:ing(}{it:savefile}{cmd:)} specifies that the regression results are saved to {it:savefile}.

{phang}
{cmd:replace} specifies that {it:savefile} may already exist and should be overwritten.

{phang}
{cmd:append} specifies that {it:savefile} already exists and the results should be
appended to it.

{phang}
{cmd:clear} specifies that the regression results are loaded into memory. 


{title:Options: what results are stored}

{phang}
{cmdab:usev:ars(}{it:varlist}{cmd:)} identifies the variables whose regression coefficients are of
interest. The default is all variables in the model, excluding the constant.

{phang}
{cmdab:usec:onstant} specifies that the constant is also of interest.

{phang}
{cmdab:usee:qs(}{it:eqlist}|*{cmd:)} specifies equations in a multiple-equation model
whose regression coefficients are also of interest. 
See {help mvmeta_make##whichcoeffs:Which coefficients are used?} for details.

{phang}
{cmdab:learn:if(}{it:exp}{cmd:)} specifies a subgroup 
in which the equation names and coefficients can be learned. 
The default is to use the whole data set, which can be slow.

{phang}
{cmdab:usecoe:fs(coef1 [coef2 ...])}
specifies the coefficients to be used, in the format {it:[eqname]coefname} or {it:coefname}.
This option replaces {cmd:usevars()}, {cmd:useconstant}, {cmd:useeqs()} and {cmd:learnif()}.

{phang}
{cmd:esave(}{it:namelist}{cmd:)} adds the specified e() statistics to the saved data.
For example, {cmd:esave(}N ll{cmd:)} saves e(N) and e(ll) as variables _e_N and _e_ll.
For logistic regression, {cmd:esave(N_fail)} outputs the number of events 
even though e(N_fail) does not exist.

{phang}
{cmd:counts(}{it:string}{cmd:)} is a partial alternative to {cmd:esave()}.
{it:string} can be one or more of {cmdab:r:ecords} {cmdab:s:ubjects} and {cmdab:f:ailures}.
It adds the specified variables to the saved data.

{phang}
{cmdab:coll:apse(}{it:collapse_exp}{cmd:)} adds data summaries to the regression output. 
The data summaries are formed by running 
{cmd:collapse }{it:collapse_exp}{cmd:, by(}{it:byvarlist}{cmd:)}: see {help collapse}.


{title:Options: how results are stored}

{phang}
{cmdab:name:s(}{it:bname Vname}{cmd:)} specifies that estimated coefficients for variable x 
are to be stored in variables whose names are prefixed by {it:bname}x, 
and the estimated covariances are to be stored in variables whose names are 
prefixed by {it:Vname}.
Defaults are y and S.
When a single equation is used, the coefficient of x is {it:bname}x1 
and its covariance with the coeficient of x2 is {it:Vname}x1x2. 
When multiple equations are used, the coefficient of x in equation eq1 is {it:bname}eq1x1 
and its covariance with the coeficient of x2 in equation eq2 is {it:Vname}eq1x1eq2x2. 
But see {cmd:infix(}{it:string}{cmd:)} and {cmd:longname} below.

{phang}
{cmd:infix(}{it:string}{cmd:)} inserts {it:string} into the variable names.
For example, {cmd:infix(_)} changes {it:bname}x1 to {it:bname}_x1 and {it:Vname}eq1x1eq2x2
to {it:Vname}_eq1_x1_eq2_x2. 

{phang}
{cmdab:long:names} specifies that variables storing coefficients are to be named 
as described under "When multiple equations are used" in {cmd:names()} above.

{phang}
{cmd:keepmat} specifies that the results are also to be stored as matrices. The estimate
vector and covariance matrix for study i are stored as matrices {it:bname}i and {it:Vname}i
respectively, where {it:bname} and {it:Vname} are the names specified by {cmd:names}.


{title:Options: output}

{phang}
{cmdab:nodet:ails} suppresses the results of running {it:regression_command} on each study.

{phang}
{cmd:pause} pauses output after the analysis of each study, 
provided that {cmd:pause on} has been set.


{title:Options: perfect prediction behaviour}

See {help mvmeta_make##pp:Perfect Prediction} for details.

{phang}
{cmdab:ppf:ix(none|check|all)} specifies whether perfect prediction should be fixed in no studies, 
only in studies where it is detected (the default), or in all studies.

{phang}
{cmdab:aug:wt(}{it:#}{cmd:)} determines the weight applied to added observations 
in a study in which perfect prediction is detected (see Perfect Prediction below).
The default is 0.01.
{cmd:augwt(0)} is the same as {cmd:ppfix(none)} 
and specifies that no augmentation is to be performed.

{phang}
{cmdab:noaugl:ist} suppresses listing of the augmented observations.

{phang}
{cmdab:ppc:md(}{it:regcmd}[{it:,options}]{cmd:)} specifies that perfect prediction 
should be fixed by using 
regression command {it:regcmd} with options {it:options}, 
instead of the default augmentation procedure.


{title:Options: estimation}

{phang}
{cmd:hard} is useful when convergence may not be achieved in some studies. 
It captures the results of initial model fitting in each study, 
and treats any non-zero return code as a symptom of perfect prediction.


{title:Options specific to regression command}

{phang}
{it:regression_options} are any options allowed for {it:regression_command}.
In particular, {cmdab:ba:seoutcome()} is required when {it:regression_command} is 
{cmd:mlogit}: see {help mlogit}.


{title:Which coefficients are used?}{marker whichcoeffs}

{p}In simple calls, 
the default behaviour of {cmd:mvmeta_make} is to use all 
the regression coefficients except the constant.
{cmd:usevars()} restricts attention to a subset of coefficients
and {cmd:useconstant} additionally uses the constant.

{p}The above behaviour applies to single-equation regression commands;
and all equations of {cmd:mlogit} and {cmd:mvreg};
and the first equation of all other multiple-equation regression commands;

{p}The other equations can be used via the {cmd:useeqs()} option, which specifies 
the names of the other equations to be used. 
All coefficients in the specified equations (including the constant) are used. 

{p}{cmd:mvmeta_make} starts by learning the equation names 
and (with {cmd:useeqs()}) the coefficient names. 
By default it does this by fitting the regression command to the whole data set.
You can speed it up by specifying the {cmd:learnif()} option: 
for example, {cmd:learnif(study==3)} specifies that the equation names and coefficients 
can be learned by fitting the regression command to study 3.
You can avoid this step altogether by specifying {cmd:usecoefs()}.


{title:Perfect prediction}{marker pp}

{p}
Perfect prediction is a problem which may occur in regression models for categorical or survival data
and may lead to misleading results being output.
In logistic regression, for example, 
perfect prediction occurs if there is a level of a categorical explanatory variable 
for which the observed values of the outcome are all zero;
in Cox regression, it occurs if there is a category in which no events are observed.

{p}
{cmd:mvmeta_make} checks for perfect prediction by checking 
(i) that all parameters are reported, and 
(ii) that there are no zeroes on the diagonal of the variance-covariance matrix 
of the parameter estimates.

{p}
If perfect prediction is detected, 
it augments the data with a set of low-weight data points to avoid perfect prediction. 
Augmentation is not available when robust standard errors are requested, 
because robust standard errors do not respect the low weights.

{p}
The augmentation is performed at 2 design points for each covariate x, 
defined by letting x equal its study-specific mean 
plus or minus its study-specific standard deviation and fixing other covariates at their mean value.
The records added at each design point depend on the form of regression model.
For regression models with discrete outcomes, we add one observation with each outcome level.
For survival analyses, we add one event at time tmin/2 and one censoring at time tmax+tmin/2, 
where tmin and tmax are the earliest and latest follow-up times in the study. 
For a stratified model, the augmentation is performed for each stratum.

{p}
A total weight of w*p is then shared equally between the added observations, 
where w is specified by the {cmd:augwt(#)} option and p is the number of model parameters
(treating the baseline hazard in a Cox model as a single parameter).

{p}
The regression model is then re-run including the weighted added observations.

{p}
When many studies have perfect prediction, 
it may be worth specifying the {cmd:ppfix(all)} option 
which bypasses the initial fit of the model without augmentation.
{cmd:ppfix(all)} is also needed in a {cmd:mlogit} model if the base level of the outcome 
(speecified in {cmd:baseoutcome()}) does not occur in some studies.

{p}
Alternatives to augmentation include penalised likelihood methods, 
which would be specified by the {cmd:ppcmd()} option.
These are implemented by {helpb plogit} and {helpb stpcox} 
which should in future be able to handle perfect prediction.

{p}
The output data set contains variables _ppfix which indicates 
whether the outputted results derive from a model in which perfect prediction was tackled,
and _ppremains which indicates whether perfect prediction was detected in this final model.


{title:Returned results}{marker returned}

{p}
{cmd:mvmeta_make} is an e-class command. It returns e(cmd), e(cmdline) and e(sample) only.


{title:Changes since publication in Stata Journal}{marker whatsnew}

{p}
Version 0.10 was published in {help mvmeta_make##White09:White (2009)}. 
The main changes since then are:

{phang}Augmentation now works for clogit (the augmented values are placed into new groups).

{phang}Multiple-equation commands are now supported (v0.20).

{phang}mvmeta_make is now eclass.

{phang}esave() has new options N_sub (number of subjects) and N_fail (number of events) 
with logistic regression.

{phang}Various bug fixes.

{phang}{cmd:by()} now allows a variable list (v0.21).

{phang}Prefix syntax created (v0.22). This allows {cmd:mvmeta_make} to be used with commands such as {helpb mixed} and {helpb mi estimate}. See examples 2 and 3 below.


{title:Limitations}{marker limitations}

{pstd}{cmd:mvmeta_make} does not allow factor variables. Use {helpb xi}.


{title:Example}{marker examples}

{p}{bf:Example 1.} Analysis of individual participant data using the classic syntax.
The data are from the Fibrinogen Studies Collaboration ({help mvmeta_make##White09:White, 2009}); they are not publicly available. 
The exposure of interest is fifth of fibrinogen stored in variable {cmd:fg} with levels 1-5.

{phang}{cmd:. xi: mvmeta_make stcox ages i.fg, strata(sex tr) nohr saving(FSCstage1) replace by(cohort) usevars(i.fg) names(b V) esave(N)}

{p}Note that {cmd:strata(sex tr)} and {cmd:nohr} are options for {cmd:stcox} while the other options are for {cmd:mvmeta_make}.
The command would give exactly the same results using the prefix syntax:

{phang}{cmd:. xi: mvmeta_make, saving(FSCstage1) replace by(cohort) usevars(i.fg) names(b V) esave(N): stcox ages i.fg, strata(sex tr) nohr}

{p}The results would be then meta-analysed in the second stage:

{phang}. {stata "use FSCstage1, clear"}{txt}

{phang}. {stata "mvmeta b V"}{txt}

{p}{bf:Example 2.} Analysis of multiply imputed data using the prefix syntax.

{phang}. {stata use mvmeta_make_testdata_mi, clear}{txt}

{phang}. {stata "mvmeta_make, by(study) clear usecons details: mi estimate, post: reg y x"}

{p}Here for illustrative purposes we chose to store the constant as well as the coefficient of {cmd:x}.

{p}Note that {cmd:mi estimate} only works correctly with {cmd:mvmeta_make} if each study contains the same number of imputed datasets. 
This is a feature of {cmd:mi estimate}. 
If each study has been imputed separately then they may have different numbers of imputed datasets: 
if so, you will need to create multiple combined datasets, each containing studies with the same number of imputed datasets, and run {cmd:mvmeta_make} on each combined dataset separately, using the {cmd:append} option after the first run.

{p}{bf:Example 3.} Analysis of repeated measures data using the prefix syntax. 
We have data from a randomised trial with outcomes at times 1 and 2. 
We are interested in the treatment effects at each time, so we create variables {cmd:z1} and {cmd:z2} as treatment indicators at times 1 and 2, and use their coefficients.

{phang}. {stata "use testdata_mixed, clear"}

{phang}. {stata "gen z1 = 0"}
	
{phang}. {stata "replace z1 = z if time==1"}
	
{phang}. {stata "gen z2 = 0"}
	
{phang}. {stata "replace z2 = z if time==2"}
	
{phang}. {stata "mvmeta_make, by(study) clear usecoefs([y]z1 [y]z2): mixed y time z1 z2 || id:, nocons res(uns, t(time)) reml"}

{p}This example uses the {cmd:res(uns, t(time))} option of {mixed} to specify an unstructured variance-covariance matrix, which avoids making assumptions that would bias the standard errors if wrong.
This option causes {cmd:mixed} to fail if run on the whole data set, so we use the {cmd:usecoefs([y]z1 [y]z2)} option to specify which coefficients we want: note that the equation names must be specified. 
An alternative would be {cmd:usevars(z1 z2) learnif(study==1)}.


{title:References}{marker refs}

{phang}{marker White09}White IR. Multivariate random-effects meta-analysis. 
Stata Journal 2009; 9: 40-56.
{browse "http://www.stata-journal.com/article.html?article=st0156"}


{title:Author and updates}{marker updates}

{p}Ian White, MRC Clinical Trials Unit at UCL, London, UK. 
Email {browse "mailto:ian.white@ucl.ac.uk":ian.white@ucl.ac.uk}.

{p}You can get the latest version of this package by visiting {browse "https://github.com/UCL/mvmeta"}
or within Stata by running 
{stata "net from https://raw.githubusercontent.com/UCL/mvmeta/master/package/"}.
