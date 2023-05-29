{smcl}
{* *! version 1.0.0  2022-5-13}{...}
{vieweralsosee "stpm3" "help stpm3"}{...}
{vieweralsosee "stpm3 extended varlist" "help stpm3_extfunctions"}{...}
{vieweralsosee "stpm3 predictions guide" "help stpm3_predictions"}{...}
{vieweralsosee "stpm3 competing risks" "help stpm3_competing_risks"}{...}
{vieweralsosee "standsurv" "help standsurv"}{...}
{viewerjumpto "Syntax" "stpm3_postestimation##syntax"}{...}
{viewerjumpto "Description" "stpm3_postestimation##description"}{...}
{viewerjumpto "Options" "stpm3_postestimation##options"}{...}
{viewerjumpto "Remarks" "stpm3_postestimation##remarks"}{...}
{viewerjumpto "Examples" "stpm3_postestimation##examples"}{...}

{marker syntax}{...}
{title:Syntax for predict}

{pstd}
Syntax for predictions following a {helpb stpm3:stpm3} model

{p 8 16 2}
{cmd:predict}
{it:newvarname}
{ifin} [{cmd:,}
{it:{help stpm3_postestimation##statistic:statistic}}
{it:{help stpm3_postestimation##opts_table:options}}]

{phang}
When using the {cmd:timevar()} option, the default is to save predictions to a new frame.
In most cases it is best to use the {cmd:timevar()} option.
See {helpb stpm3_predictions:stpm3 predictions guide} for details.

{marker statistic}{...}
{synoptset 25 tabbed}{...}
{syntab:{bf: Single models:}}
{synoptline}
{synopthdr:statistic}
{synoptline}
{synopt :{opt cent:ile(options)}}centiles{p_end}
{synopt :{opt crudep:rob}}crude probabilities{p_end}
{synopt :{opt cumh:azard}}cumulative hazard function{p_end}
{synopt :{opt fail:ure}}failure function{p_end}
{synopt :{opt haz:ard}}hazard function{p_end}
{synopt :{opt lnhaz:ard}}ln(hazard) function{p_end}
{synopt :{opt rmft}}restricted mean failure time{p_end}
{synopt :{opt rmst}}restricted mean survival time{p_end}
{synopt :{opt surv:ival}}survival function{p_end}
{synopt :{opt xb}}the full linear predictor{p_end}
{synopt :{opt xbnotime}}the linear predictor (without the effect of time){p_end}
{synoptline}

{syntab:{bf: Competing risk models:}}
{synoptline}
{synopthdr:statistic}
{synoptline}{synopt :{opt cif}}cumulative incidence function{p_end}
{synopt :{opt haz:ard}}total hazard function{p_end}
{synopt :{opt surv:ival}}total survival function{p_end}
{synoptline}

{marker opts_table}{...}
{synoptset 30 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt:{opt at1()}{it:...}{opt atn()}}covariate values to predict at{p_end}
{synopt:{opt atr:ef(#)}}reference {cmd:at}{it:n} option for contrasts{p_end}
{synopt:{opt ci}}calculate confidence intervals{p_end}
{synopt:{opt contrast(contrasttype)}}calculate contrast(s) between {cmd:at()} options{p_end}
{synopt:{opt contrastv:ars(varlist)}}new variables to be created for contrasts{p_end}
{synopt:{opt cpnames(namelist)}}change names of suffix for crude probability predictions{p_end}
{synopt:{opt crmodels(modellist)}}names of models for competing risk predictions{p_end}
{synopt:{opt crnames(namelist)}}change names of suffix for competing risk predictions{p_end}
{synopt:{opt expsurv(options)}}use expected rates in predictions{p_end}
{synopt:{opt frame(framename)}}frame name for predictions{p_end}
{synopt:{opt lev:el(#)}}sets confidence level (default 95){p_end}
{synopt:{opt merge}}merge predictions into current dataset rather than a frame{p_end}
{synopt:{opt nogen}}do not generate {cmd:at()} options variables{p_end}
{synopt:{opt odeoptions(ode options)}}ode options for numerical integration{p_end}
{synopt:{opt per(#)}}multiply predictions by {it:#}{p_end}
{synopt:{opt se}}calculate standard errors{p_end}
{synopt:{opt setbaseline}}set covariates to their baseline values (or zero){p_end}
{synopt:{opt timevar(varname|# [#])}}calculate predictions at specified times{p_end}
{synopt:{opt verb:ose}}verbose output details{p_end}
{synopt:{opt zero:s}}set covariates to zero{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:predict} after {cmd:stpm3} creates new variables containing predictions with optional standard errors or 
confidence intervals.

{pstd}
Using {cmd:predict} with the {cmd:crmodels()} option gives various competing risks measures.
See {help stpm3_competing_risks}.

{phang} 
By default {cmd:stpm3} adds predictions to a new data frame when using the {cmd:timevar()} option.
The default name for the frame is {it:stpm3_pred}, but this can be changed using the
{cmd:frame()} option. It is also possible to add predictions to an existing frame.
If you use the {cmd:timevar()} option, but prefer having predictions in the current dataset, then use the {cmd:merge} option.

{phang}
When you do not specify the {cmd:timevar()} option then {cmd:timevar(_t)} and {cmd:merge} is assumed.
This means predictions are created in the current dataset. 
You can still choose to save results to a frame using the {cmd:frame()} option.

{phang} 
Using the {cmd:contrast()} option enables contrasts between different predictions.
For example, if the prediction type is {cmd:hazard} then you can obtain hazard ratios
using {cmd:contrast(ratio)} when using a minimum of 2 {cmd:at()} options. 
Altenatively, using {cmd:contrast(difference)} with the {cmd:survival} option
will give differences in survival functions.

{phang} 
This {cmd:predict} command will give you predictions and contrasts for specific
covariate patterns. If you want marginal predictions then you will need to use the 
{help standsurv} command.


{marker options}{...}
{title:Options}

{dlgtab:Statistic}

{phang}
{opt centile(numlist | varname, options)} #th centile of failure distribution.
You can specify this as a numlist, eg {cmd:centile(25(25)50)} will give estimates of
the lower quartile, median and upper quartile of the distribution of failure times.
Centiles are estimated iteratively using Brent's root finder.
There are some suboptions,

{phang3}
{opt centvar(varname)} name of variable giving centiles (default {cmd:centile})

{phang3}
{opt high(#)} upper endpoint of the search interval (default 100)

{phang3}
{opt low(#)} upper endpoint of the search interval (1e-8)

{phang3}
{opt maxiter(#)} maximum number of iterations (default 100).

{phang3}
{opt tol(#)} tolerence (default 1e-6).

{phang}
{cmd:cif} calculates cause-specific cumulative incidence functions in competing risks models.
You must use the {cmd:crmodels()} when using the {cmd:cif} option.

{phang}
{cmd:cpnames} give the names of the suffixes for crude probability predictions.
The default names are {cmd:d} and {cmd:o} (disease and other).

{phang}
{cmd:crnames} give the names of the suffixes for competing risks predictions
when using the {cmd:cif} option. The default names are the names of the models
specified in the {cmd:crmodels()} option.

{phang}
{cmd:crudeprob} calculates crude probabilities for relative survival models.

{phang} 
{cmd:cumhazard} calculates the cumulative hazard function.

{phang} 
{cmd:failure} calculates the failure function, i.e. 1-S(t).

{phang} 
{cmd:hazard} calculates the hazard function.

{phang} 
{cmd:rmft} calculates the restricted mean failure time, i.e the area under the failure function. 

{phang} 
{cmd:rmst} calculates the restricted mean survival time, i.e the area under the survival curve. 

{phang} 
{cmd:survival} calculates the survival function. 

{phang} 
{cmd:xb} calculates the linear predictor. Note this is the full model which includes their
effect of time.

{phang} 
{cmd:xbnobaseline} a synonym for xbnotime 

{phang} 
{cmd:xbnotime} calculates the linear predictor for the first equation only. 
Note this exclude the effects of time (including any time-dependent effects).
This can be useful to obtain the prognostic index in a prognostic model
(with proportional hazards).

{phang} 
The predictions are at times specified by the {cmd:timevar()} option.

{dlgtab:Options}

{phang}
{opt at1(varname # [varname # ..], suboptions)}{it:..}{opt atn(varname # [varname # ..], suboptions)}
specifies covariates to fix at specific values when obtaining predictions. 
Note that predictions are conditional on a specified covariate pattern
and all covariates must take a value,
but this may be made easier using the {cmd:setbaseline} or {cmd:obsvalues} options.

{pmore}
There are some suboptions. These are,

{phang3}
{opt atif(expression)} restrict predictions to a subset of observations defined by {it:expression}.
You will rarely, if ever, want to do this and generally you should use the main {cmd:if} qualifier.

{phang3}
{opt attimevar(varname | # [#], options)} specifies or calculates 
a specific time variable for each {cmd:at()} option.
This could be useful if you wanted, for example, predictions of survival at 1, 5 and 10 years.
Most of the time it is better to avoid having different time variables in the same frame,
so use the main {cmd:timevar()} option unless you have a good reason not to.

{phang3}
{opt obsvalues} sets all covariates not listed in the {cmd:at()} options to their observed values. 

{phang3}
{opt setbaseline} See main {cmd: setbaseline} option. 

{phang3}
{opt zeros} A synonym for {cmd:setbaseline}. 

{phang2}
See {helpb stpm3_predictions:stpm3 predictions guide} for examples.

{phang}
{opt atreference(#)} defines which {bf:at()} option is the reference category.
By default this is {bf:at1()}. This is only applicable when making contrasts.
When the contrast is a {cmd:ratio} then the reference is the denominator.
When the contrast is a {cmd:difference} then the reference is the negative term.

{phang}
{cmd:ci} specifies that confidence intervals are calculated for the predicted {it:statistic}. 
The upper and lower bounds are generated in {it:newvarname}{cmd:_lci} 
and {it:newvarname}{cmd:_uci}.

{phang}
{opt contrast(contrastname)} calculates contrasts between different predictions
that have been specified using the {cmd:at()} options.
Options are {bf:difference} and {bf:ratio}. There will be {it:n-1} 
new variables created, where {it:n} is the number of {bf:at()} options.
The names default to {bf:_contrast}{it:k}_{it:j} where {it:k} is the contrast
between {bf:at}{it:k} and {bf:at}{it:j} where the reference can be set using 
{cmd:atreference()}. Alternatively, use the {cmd:contrastsvars()} option
to define the names of the contrast variables.

{phang}
{opt contrastvars(stub | newvarnames)} gives the new variables to create when
using the {bf:contrast()} option. This can be specified as a {it:varlist} or a {it:stub},
whereby new variables are named {bf:stub}{it:1} - {bf:stub}{it:n-1}. 

{phang}
{opt expsurv(suboptions)} indicates that expected survial should be calculated
and then combined with the model based (relative) survival estimates to give
all cause survival and other measures. There are a number of suboptions, which are,

{phang2}
{opt agediag(# | varname)} gives either a single value, a list of {it:n} numbers,
where {it:n} is the number of {cmd:at()} options, or a variable 
giving the age at diagnosis in years for the predictions. 
Note that when using integer age is is assumed that individuals were diagnosed 
on their birthday.

{phang2}
{opt datediag(date | varname)} gives either a date value or the variable giving 
the date at diagnosis for subjects when making predictions. 
If you do not have exact dates then you still need to specify this option. 
For example, if you had dates in months and years you could use

{phang3}
        {bf:. gen datediag = mdy(diagmonth,1,diagyear)}
        
{phang3}
        to assume all subjects were diagnosed on the 1st of the month.

{phang3}
If you want to use a date value then this can be entered using the "YMD" format.
For example,

{phang3}
datediag(2015-1-1)        
        
{phang2}
{opt expvars(stub | newvarnames)} gives the names of the new variables to be
created for expected survival ({cmd:survival} option), expected hazard ({cmd:hazard} option),
expected life expectency ({cmd:rmst} option) 
or the crude probability of death due to other causes
{cmd:crudeprob} option. If not specified these variables will 
not be stored. The names can be specified as a {it:varlist} equal to the number 
of {cmd:at()} options or a {it:stub} where new variables are named {it:stub}{bf:1} - 
{it:stub}{bf:n}. 
        
{phang2}
{opt pmage(varname)} gives the age variable in the population mortality file.
        
{phang2}
{opt pmmaxage(varname)} gives the maximum age in the population mortality file.
When calculating attained age to merge in the expected mortality rates any record
that is over this maximum will be set to this maximum. The default value is 99.
        
{phang2}
{opt pmmaxyear(varname)} gives the maximum year in the population mortality file.
This is potentially useful when extrapolating. When calculating attained year
to merge in the expected mortality rates any record that is over this maximum 
will be set to this maximum. 

{phang2}
{opt pmother(other)} gives the name of other variables in the population 
mortality file. For example, this is usually sex, but can also be region,
deprivation etc.

{phang2}
{opt pmrate(rate)} gives the name of the rate variable in the population mortality file. 

{phang2}
{opt pmyear(varname)} gives the calendar year variable in the population 
mortality file.

{phang2}
{opt split(varname)} gives the split times when calculating expected survival. 
The default is one year.

{phang2}
{opt using(filename)} filename of population mortality file.

{phang}
{opt frame(framename, options)} specifies the name of the frame to store the predictions.
The default name is {it:stpm2_pred}. Options are,

{phang2}
{opt copy(varlist)} copy {it:varlist} into {it:framename}.

{phang2}
{opt merge} merge predictions into frame {it:framename}. This will extract the
time variable from the {it:framename} automatically.

{phang2}
{opt mergecreate} is a convenience option when writing predictions in a loop.
If the frame does not exist it will be created. 
If the frame does exists then the {cmd:timevar()} option will be ignored
and predictions merged into {it:framename}.

{phang2}
{opt replace} replace the existing frame {it:framename} if it exists.

{phang}
{opt merge} merge predictions into current dataset rather than a new frame.
This is useful if you want to plot predictions againt covariates in your dataset.

{phang2}
See {helpb stpm3_predictions:stpm3 predictions guide} for examples.

{phang}
{opt nogen} Does not generate variables for each {cmd:at()} option. This is only
relevent when using the contrast() option and you are not interested 
in the predictions for each at option.

{phang}
{opt odeoptions(options)} Various options for ordinary differential equations. 
These are used for numerical integration, for example calculation of restricted
mean survival time ({cmd:rmst}) or the survival function prediction for models
on the log(hazard) scale. These options will rarely need changing.

{phang2}
{opt level(#)} sets the confidence level; default is level(95) or as set by {help set level}.

{phang2}
{opt abstol(#)} absolute tolerance - default 1e-8.

{phang2}
{opt error_control(#)} error control when reducing step size - default (5/safety)^(1/pgrow).

{phang2}
{opt initialh(#)} initial step size - default 1e-8.

{phang2}
{opt maxsteps(#)} maxiumum number of steps - default 1000.

{phang2}
{opt pgrow(#)} power using when increasing step size. The default is -0.2.

{phang2}
{opt pshrink(#)} power using when decreasing step size. The default is -0.25.

{phang2}
{opt reltol(#)} relative tolerance - default 1e-5.

{phang2}
{opt safety(#)} safety factor - default 0.9.

{phang2}
{opt tstart(#)} lower bound of integration. The deafult is 1e-6.

{phang2}
{opt verbose} output details for each step.

{phang}
{opt per(#)} multiplies predictions by {it:#}. For example, when predicting 
survival {bf: per(100)} will express results as a percentage rather than a 
proportion, or when predicting hazard functions, {bf: per(1000)} gives results
per 1000 person years (if your time scale is in years of course).

{phang}
{opt se} calculates the standard error for each prediction. 
This is stored using the suffix {it:newvarname}{bf:_se}.

{phang}
{opt setbaseline} sets each covariate included in the model to its reference level.
For factor variables this is the term exluded from the model.
For continuous variables the baseline is zero, which may not be sensible. 
When using extended functions with the {cmd:center()} option the covariate 
value is set to the value of the centering value.

{phang}
{opt timevar(varname | # [#], options)} gives or specifies times at which predictions are required.

{phang2}
If a {it:varname} is specified then predictions will be at the values of times
defined in that variable. 
If saving to a frame (the default) then any non missing values of this variable will be copied to the new frame.

{phang2}
Using {it:# [#]} will calculate a new variable defining the times to predict at.
If only a single value is given, predictions are all at the same time point,
otherwise a range is given. 

{phang2}
If 2 values are given the predictions are at a range of values between the two time points.
The default number of observations is 100, but this can be changed using
the {cmd:n()} or {cmd:step()} options.

{phang2} Options are as follows. 
Note the options are only relevant when using two numbers in the {cmd:timevalues()} option.

{phang3}
{opt gen(varname)} name of the time variable created. The default is {bf:tt}.

{phang3}
{opt n(#)} the number of values to predict at. 

{phang3}
{opt step(#)} the step between values of time. 

{phang3}
See {helpb stpm3_predictions:stpm3 predictions guide} for examples.


{phang}
{opt verbose} more detailed output.

{phang}
{opt zeros} This is a synonym for setbaseline.

{marker remarks}{...}
{title:Remarks}

{pstd}
Out-of-sample prediction is allowed for all {cmd:predict} statistics.

{marker examples}{...}
{title:Examples}

{phang}
These are very simple examples.  For more complex examples see 
{bf:{browse "https://pclambert.net/software/stpm3/":https://pclambert.net/software/stpm3/}}.

{pstd}Load data{p_end}
{phang2}{stata "webuse brcancer"}{p_end}
{phang2}{stata "stset rectime, failure(censrec = 1)"}{p_end}

{phang}
{ul:{bf:Example 1: Proportional hazards model on log cumulative hazard scale}}
{p_end}

{phang2}{stata "stpm3 i.hormon, scale(lncumhazard) df(4) eform"}{p_end}
{phang2}{stata "range tt 0 7 100 "}{p_end}
{phang2}{stata "predict S0 S1, surv timevar(tt) at1(hormon 0) at2(hormon 1) ci contrast(difference)"}{p_end}
{phang2}{stata "frame stpm3_pred: line S0 S1 tt"}{p_end}

{title:Author}

{p 5 12 2}{bf:Paul C. Lambert}{p_end}        
{p 5 12 2}Biostatistics Research Group{p_end}
{p 5 12 2}Department of Population Health Sciences{p_end}
{p 5 12 2}University of Leicester{p_end}
{p 5 12 2}Leicester, UK{p_end}
{p 5 12 2}{it: and}{p_end}
{p 5 12 2}Department of Medical Epidemiology and Biostatistics{p_end}
{p 5 12 2}Karolinska Institutet{p_end}
{p 5 12 2}Stockholm, Sweden{p_end}
{p 5 12 2}paul.lambert@le.ac.uk{p_end}

{title:References}

{phang}
{bf:P. C. Lambert and P. Royston}. Further development of flexible parametric
models for survival analysis. {browse "https://journals.sagepub.com/doi/10.1177/1536867X0900900206:":{it:Stata Journal} 2009;9:265-290}

{phang}
{bf:C. P. Nelson, P. C. Lambert, I. B. Squire and D. R. Jones.} 
Flexible parametric models for relative survival, with application
in coronary heart disease. Statistics in Medicine 2007;26:5486-5498

{phang}
{bf:P. Royston and M. K. B. Parmar}. Flexible proportional-hazards and
proportional-odds models for censored survival data, with application
to prognostic modelling and estimation of treatment effects.
Statistics in Medicine 2002;21:2175-2197.

{phang}
{bf:P. Royston, P.C. Lambert}. {browse `"https://www.stata.com/bookstore/flexible-parametric-survival-analysis-stata"':Flexible parametric survival analysis in Stata: Beyond the Cox model}. StataPress, 2011