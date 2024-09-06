{smcl}
{* *! version 1.0.0 2021-02-28}{...}
{vieweralsosee "streg" "help streg"}{...}
{vieweralsosee "stpm2" "help stpm2"}{...}
{vieweralsosee "stpm3" "help stpm3"}{...}
{vieweralsosee "predictms" "help predictms"}{...}
{viewerjumpto "Syntax" "standsurv##syntax"}{...}
{viewerjumpto "Description" "standsurv##description"}{...}
{viewerjumpto "Options" "standsurv##options"}{...}
{viewerjumpto "Examples" "standsurv##examples"}{...}
{title:Title}

{p2colset 5 18 18 2}{...}
{p2col :{hi:standsurv} {hline 2}}Standardized survival and related functions{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 15 2}
{cmd:standsurv}
{c -(}{it:{help newvarlist##stub*:stub}}{cmd:*} | {it:{help newvar}} | {it:{help newvarlist}}{c )-}
{ifin}
[{cmd:,}  [{it:options}]

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt at1()}{it:...}{opt atn()}}fix specific covariate values for each cause{p_end}
{synopt:{opt atv:ars()}}the new variable names (or stub) for each at{it:n}() option{p_end}
{synopt:{opt atr:eference()}}the reference at{it:n}() option (default 1){p_end}
{synopt:{opt centile(numlist)}}centiles of the standardised survival function{p_end}
{synopt:{opt centileu:pper(#)}}upper starting value when calculating centiles{p_end}
{synopt:{opt centv:ar()}}the new variable to denote centiles{p_end}
{synopt:{opt ci}}calculates confidence intervals for each at{it:n}() option and for contrasts{p_end}
{synopt:{opt cif}}calculates cumulative incidence function for competing risks models{p_end}
{synopt:{opt contrast()}}perform contrast between covariate patterns defined by at{it:n}() options{p_end}
{synopt:{opt contrastv:ars()}}the new variable names (or stub) for each contrast{p_end}
{synopt:{opt crmod:els(modellist)}}names of competing risk models{p_end}
{synopt:{opt crudepr:ob}}calculate crude probabilities{p_end}
{synopt:{opt f:ailure}}calculate standardised failure function (1-S(t)){p_end}
{synopt:{opt fr:ame(framename)}}save predictions to a frame{p_end}
{synopt:{opt nogen}}do not generate at() option variables{p_end}
{synopt:{opt genind(stub)}}output individual predictions{p_end}
{synopt:{opt h:azard}}calculate hazard function of standardised survival curve{p_end}
{synopt:{opt indw:eights(varname)}}variable containing weights (for external standardisation){p_end}
{synopt:{opt lincom(numlist)}}linear combination of at options{p_end}
{synopt:{opt lev:el(#)}}sets confidence level (default 95){p_end}
{synopt:{opt mest:imation}}use M-estimation for standard errors & confidence intervals{p_end}
{synopt:{opt no:des(#)}}number of nodes for numerical integration (default 30){p_end}
{synopt:{opt ode}}use ordinary differential equations for some integrations{p_end}
{synopt:{opt odeoptions(options)}}options for ordinary differential equations{p_end}
{synopt:{opt over(varlist)}}estimate effects at unique values of {it:varlist}{p_end}
{synopt:{opt rmst}}calculate restricted mean survival time{p_end}
{synopt:{opt rmft}}calculate restricted mean failure time{p_end}
{synopt:{opt se}}calculates standard errors for each at{it:n}() option and for contrasts{p_end}
{synopt:{opt storeg(name)}}stores derivatives for each at option{p_end}
{synopt:{opt stub2(name)}}override the default stubnames{it:n}() option for competing risks{p_end}
{synopt:{opt ti:mevar(varname)}}time variable used for predictions (default _t){p_end}
{synopt:{opt toff:set(varname)}}time offset when multiple models{p_end}
{synopt:{opt tr:ansform()}}transformation to calculate standard errors when obtaining confidence intervals{p_end}
{synopt:{opt userf:unction()}}user defined function{p_end}
{synopt:{opt userfunctionv:ar()}}the new variable names (or stub) for each user defined function{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:standsurv} is a postestimation command that calculates various standardized 
(marginal) measures after fitting a parametric survival model. These include 
standardized survival functions and a variety of functions of standardized survival
functions and contrasts of these functions. These functions include
the failure and hazard functions restricted mean survival time and centiles
of the marginal failure function. 
{p_end}

{pstd}
When standardizing, specific covariate(s) can be held constant and contrasts between
different groups can be made, for example differences and ratios.  Confidence intervals for all quantities are available. 
User-defined transformations can be calculated by providing a user-written 
Mata function.
{p_end}

{pstd}
The command also allows more than one survival model to be specified in a
competing risks setting. This allows calculation of standardized cause-specific
cumulative incidence functions and other useful measures. 
{p_end}

{pstd}
Survival model estimation commands supported include {cmd:stpm2}, {cmd:stpm3}, {cmd:strcs}, and {cmd:streg}. 
Note generalized gamma models are not currently implemented for {cmd:streg} models.
{p_end}

{pstd}
Factor variables are only supported for {cmd:stpm3} models.
For other models you will need to create dummy variables and interactions 
yourself when fitting the models. 
{p_end}

{pstd}
By default new variables are saved to the original dataset.
However, it is advised that you use the frame option to save results to a new frame.
{p_end}


{pstd}
{cmd:standsurv} creates the following variables by default. However, it is recommended 
that you use the {cmd:atvar()}, {cmd:contrastvar()}, {cmd:lincomvar()} and {cmd:userfunctionvar()} options
to give more meaningful variable names.
Note that you can now specify new variables names before the comma, as an alternative to 
using the {cmd:atvars()} option.
{p_end}

{phang2}
{cmd:_at}{it:i} - standarized estimate for the ith {cmd:at}{it:i}{cmd:()} option
{p_end}

{phang2}
If the {cmd:ci} option is specified then the following variables are created
{p_end}

{phang3}
{cmd:_at}{it:i}{cmd:_lci} - lower confidence interval for standarized estimate for the ith {cmd:at}{it:i}{cmd:()} option
{p_end}
    
{phang3}
{cmd:_at}{it:i}{cmd:_uci} - upper confidence interval for standarized estimate for the ith {cmd:at}{it:i}{cmd:()} option
{p_end}
  
{phang2}
If the {cmd:contrast()} option is specified then the following variables are created
{p_end}

{phang3}
{cmd:_contrast}{it:j}{cmd:_}{it:i} - contrast between the {cmd:at}{it:j}{cmd:()} and {cmd:at}{it:i}{cmd:()} options. 
By default {cmd:at1()} is the reference, but this can be changed using the {cmd:atref()} option.
{p_end}

{phang3}
{cmd:_contrast}{it:j}{cmd:_}{it:i}{cmd:_lci} - lower confidence interval for contrast between the {cmd:at}{it:j}{cmd:()} and {cmd:at}{it:i}{cmd:()} options. 
{p_end}
    
{phang3}
{cmd:_contrast}{it:j}{cmd:_}{it:i}{cmd:_uci} - upper confidence interval for contrast between the {cmd:at}{it:j}{cmd:()} and {cmd:at}{it:i}{cmd:()} options. 
{p_end}

{phang2}
If the {cmd:lincom()} option is specified then the following variables are created
{p_end}

{phang3}
{cmd:_lincom} - linear combination of standardized estimates. 
{p_end}

{phang3}
{cmd:_lincom_lci} - lower confidence interval of linear combination of standardized estimates. 
{p_end}

{phang3}
{cmd:_lincom_uci} - upper confidence interval of linear combination of standardized estimates. 
{p_end}

{phang2}
If the {cmd:userfunctionvar()} option is specified then the following variables are created
{p_end}

{phang3}
{cmd:_userfunction} - function of standardized estimates specified using {cmd:userfunction()} option.
{p_end}

{phang3}
{cmd:_userfunction_lci} - lower confidence interval for function of standardized estimates specified using {cmd:userfunction()} option.
{p_end}

{phang3}
{cmd:_userfunction_uci} - upper confidence interval for function of standardized estimates specified using {cmd:userfunction()} option.
{p_end}



{marker options}{...}
{title:Options}

{phang}
{opt at1(varname # [varname # ..], suboptions)}{it:..}{opt atn(varname # [varname # ..], suboptions)}
specifies covariates to fix at specific values when averaging predictions. 
For example, if {cmd:x} denotes a binary covariate and you want to standardise
over all other variables in the model then using {cmd:at1(x 0) at2(x 1)} will give
two standardised functions, one where {cmd:x=0} and one where {cmd:x=1}. 

{pmore}
Using {cmd:at1(.)} will calculated the standardized quantity with all observations set to their observed values.

{pmore}
It can be sometimes be useful to set certain variables to take the values of a 
different covariate. This can be done using {bf:at1(x1 = x2)} for example. 
This can be useful when there are interactions: consider a model with 
{cmd: treat age treat_age} as covariates where {bf: treat_age} is an interaction 
between {cmd:treat} and {cmd:age}. When standardising for {cmd:treat=0} and {cmd:treat=1}, 
the {cmd:at()} options should be {cmd: at1(treat 0 treat_age 0)} and 
{cmd: at2(treat 1 treat_age = age)}.

{pmore}
If you use {cmd:stpm3} then it is advised you use factor variables when using
interactions. This makes specification of the {cmd_at()} options much easier,
particularly when there are interactions.

{pmore}
There are some suboptions. These are,

{phang3}
{opt atif(expression)} restricts the standardization to that selected by the 
expression. For example, if {bf: x} is an exposure covariate taking 0 for the 
unexposed and 1 for the exposed, then using {bf: at1(x 0, atif(x==1))} 
standardizes over the covariate distribution among the exposed. 
Note {cmd: atif()} allows different if expressions for each {cmd: at()} option.
Often the same if expression is required for each {cmd  : at()} option and so
a standard single {bf: if/in} statement can be used.

{phang3}
{opt atenter(#)} specifies the start time when integrating for RMST or RMFT.

{phang3}
{opt atindweights(varname)} Multiplies each individual prediction by the specified
{it:varname}. This can be used for external (age) standardization. If the same weights
are being used for all {bf: at()} options then the main {bf: indweights()} option can
be used.

{phang3}
{opt attimevar(varname)} specifies a different time variables for each {cmd:at}{it:i}{cmd:()} option.
Here you should be careful with contrasts. 

{phang}
{opt atvars(stub | newvarnames)} gives the names of the new variables to be
created for each {cmd:at}{it:i}{cmd:()} option. 
This can be specified as a {it:varlist} equal to the number of at() 
options or a {it:stub} where new variables are named {it:stub}{bf:1} - 
{it:stub}{bf:n}. If this option is not specified, the names default to 
{bf:_at1} to {bf:_at}{it:n}. 

{phang}
{opt atreference(#)} the {bf:at#()} option that defines the reference category.
By default this is {bf:at1()}.

{phang}
{opt centile(numlist)} calculates centiles of the standardised survival curve
for the centiles given in {it:numlist}. The centile values are given in a
new variable, {cmd:_centvar}, or that defined using the {cmd:centvar()} option.

{phang}
{opt centileupper(#)} upper starting value when calculating centiles of the 
standardised failure curve. The default is four times the maximum survival time
if there is a value of _t, otherwise it is 100. 
If you have to set this, and the analysis data is in memory, 
it probably means your estimate is based on extrapolating 
the survival function way beyond your observed follow-up.

{phang}
{opt centileupper(newvarname)} name of new varaible giving values of centiles.
The default is {cmd:_centvar}.

{phang}
{opt ci} calculates a {opt level(#)}% confidence interval for each standardised
function or contrast. The confidence limits are stored using the
suffix {bf:_lci} and {bf:_uci}.

{phang}
{opt cif} calculates the cause-specific cumulative incidence functions from 
competing risks models. This must be used with {bf:crmodels()} option to list the 
cause-specific models. See XXX for naming rules...

{phang}
{opt contrast(contrastname)} calculates contrasts between standardised measures. 
Options are {bf:difference} and {bf:ratio}. There will be {it:n-1} 
new variables created, where {it:n} is the number of {bf:at()} options. 
See above for naming rules.

{phang}
{opt contrastvars(stub | newvarnames)} gives the new variables to create when
using the {bf:contrast()} option. This can be specified as a varlist or a {it:stub},
whereby new variables are named {it:stub}{bf:1} - {it:stub}{bf:n-1}. 
The names default to {bf:_contrast1} to {bf:_contrast}{it:n-1}.

{phang}
{opt crmodels(modellist)} gives the names of the cause-specifc models for 
competing risks. Each model needs to have been saved using {cmd:estimates store}.

{phang}
{opt crudeprob} calculates crude probabilities. This assumes that a relative 
survival model has been fitted and that expected mortality rates have been 
given using the {cmd:expsurv()} option. 

{phang}
{opt enter(#)} gives the enter time for conditional estimates. This currently only 
works with the rmst and rmft options.

{phang}
{opt expsurv(suboptions)} indicates that expected survival should be calculated
and then combined with the model based (relative) survival estimates to give
all cause survival. There are a number of suboptions,

{phang2}
{opt agediag(varname)} gives the variable giving the age at diagnosis in years 
for subjects in the study population. Note that when using integer age is
is assumed that individuals were diagnosed on their birthday, so avoid this if possible.

{phang2}
{opt datediag(varname)} gives the variable giving the date at diagnosis  
for subjects in the study population. If you do not have exact dates then you 
still need to specify this option. For example, if you had dates in months 
and years you could use

{phang3}
	{bf:. gen datediag = mdy(diagmonth,1,diagyear)}
	
{phang3}
	to assume all subjects were diagnosed on the 1st of the month.

{phang2}
{opt genind(varlist)} gives the names of new variables to create and store the
individual contributions to the marginal expected survival, failure, rmst or rmft.
Note this only works if the main genind() option is specified.
	
{phang2}
{opt expsurvvars(stub | newvarnames)} gives the names of the new variables to be
created for marginal expected survival ({cmd:survival} option) or marginal expected 
life expectency (RMST option). If not specified these variables will 
not be stored. The names can be specified as a {it:varlist} equal to the number 
of {cmd:at()} options or a {it:stub} where new variables are named {it:stub}{bf:1} - 
{it:stub}{bf:n}. 
	
{phang2}
{opt pmage(varname)} gives the name of the age variable in the population mortality file.
	
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
{opt pmrate(rate)} gives the rate variables in the population mortality file. Note 
that standsurv requires the expected mortality rate and not the expected survival.

{phang2}
{opt pmyear(varname)} gives the name of the calendar year variable in the population 
mortality file.

{phang2}
{opt split(varname)} gives the split times when calculating expected survival (for {cmd:rmst}). 
The default is one year.

{phang2}
{opt using(filename)} filename of population mortality file.
	
{phang}
{opt failure} calculates the standardised failure function rather than
the standardised survival function.

{phang}
{opt frame(framename, options)} specifies the name of the frame to store the predictions.
The default name is {it:stpm2_pred}. Options are,

{phang2}
{opt merge} merge predictions into frame {it:framename}. This will extract the
time variable from the {it:framename} automatically.

{phang2}
{opt mergecreate} is a convenience option when writing predictions in a loop.
If the frame does not exist it will be created. 
If the frame does exists then the {cmd:timevar()} option will be ignored
and predictions merged into {it:framename}.

{phang2}
{opt replace} replace the existing frame {it:framename} is it exists.

{phang}
{opt nogen} Does not generate variables for each {cmd:at()} option. This is only
relevent when using the contrast() option and you are not interested 
in the predictions for each {cmd:at} option.
  
{phang}
{opt genind(stubname)} outputs the predictions for each individual, i.e. the 
predicted values that feed into the average. Standsurv is concerned with marginal 
estimates, but it is sometimes of interest to look at the variation between 
individuals. Note that this only will work if {it:timevar} is a single value. It
was implemented as a debugging tool when developing the command and may not work for all
options.

{phang}
{opt hazard} calculates the hazard function of the standardised survival
function. Note that this is not the mean of the predicted hazard functions,
but a weighted mean with weights, S(t). The weights are time-dependent.

{phang}
{opt indweights(varname)} Multiplies each individual prediction by the specified
{it:varname}. This is used for external (age) standardization.

{phang}
{opt level(#)} sets the confidence level; default is level(95) or as set by {help set level}.

{phang}
{opt lincom(#...#)} calculates a linear combination of at{it:n} options. As an example, if
there were two at() options then {bf:lincom(1 -1)} would calculate the difference in the
standardized estimate. This would be the same as using the {bf:contrast(difference)} option.
Note that in the competing risks setting the number of values in the lincom() options
should be the number of at{it:n} options muliplied by the number of competing risk models.
In such as case the first value corresponds to at1 competing risk model 1 and their
second value to at1 competing risk model 2, i.e. the values correspond to the order in which
the new standardized variables are created. For example with two competing risk models and
two at() options combined with the {bf:cif} option, {bf:lincom(1 1 0 0)} would sum the CIFs
for cause 1 and 2 for {cmd:at1}.

{phang}
{opt lincomvar(newvarname)} gives the new variable to create when
using the {bf:lincom()} option. 

{phang}
{opt mestimation} requests that standard errors are obtained using M-estimation 
(Stefanski and Boos 2002) rather than the delta-method.

{phang}
{opt nodes(#)} number of nodes when performing numerical integration using
Gaussian quadrature to calculate the restricted mean survival time.

{phang}
{opt ode} use ordinary differential equations (Dormand Prince 45) for numerical integration.
This the default and only option for various predictions and so only relevent
when the default is Gaussian quadrature.

{phang}
{opt odeoptions(options)} Various options for ordinary differential equations.

{phang2}
{opt abstol(#)} absolute tolerance - default 1e-6.

{phang2}
{opt error_control(#)} error control when reducing step size - default (5/safety)^(1/pgrow).

{phang2}
{opt initialh(#)} initial step size - default 1e-8.

{phang2}
{opt maxsteps(#)} maxiumum number of steps - default 1000.

{phang2}
{opt pgrow(#)} power using when increasing step size.

{phang2}
{opt pshrink(#)} power using when decreasing step size.

{phang2}
{opt reltol(#)} relative tolerance - default 1e-5.

{phang2}
{opt safety(#)} safety factor - default 1.

{phang2}
{opt tstart(#)} lower bound of integration.

{phang2}
{opt verbose} output details for each step.

{phang}
{opt over(varlist)} specifies that separate standardized estimates are obtained
for the groups defined by {it:varlist}.  The variables need not be
covariates in your model.  

{phang}
{opt per(#)} multiplies predictions by {it:#}. For example, when predicting 
survival {bf: per(100)} will express results as a percentage rather than a 
proportion, or when predicting hazard functions, {bf: per(1000)} gives results
per 1000 person years (if your time scale is in years of course).

{phang}
{opt rmst} calculates the restricted mean survival time. These are calculated at
the time points give in variable given in the {cmd:timevar()} option. 

{phang}
{opt rmft} calculates the restricted mean failure time. These are calculated at
the time points give in variable given in the {cmd:timevar()} option.
Note that if the {cmd:rmft} option is used together with the {cmd:cif} option 
for competing risks models then the area under the CIF is calculated. 
This is sometimes referred to as the expected loss in life due to a specific cause.
See Andersen (2013).

{phang}
{opt se} calculates the standard error  for each standardised
function or contrast. This is stored using the suffix {bf:_se}.

{phang}
{opt storeg(name)} store the derivatives of the standsardized estimate w.r.t each 
of the model parameters. This can be useful if you need to combine results from 
multiple standsurv calls.

{phang}
{opt stub2} Overide default stub names{bf:_se}.

{phang}
{opt timevar(varname)} defines the variable used as time in the predictions. The
option is useful for large datasets where, for plotting purposes, predictions
are needed only for (say) 200 observations. Note that predictions are averaged
over the whole sample, not just those where {it:timevar} is not missing. It is
recommended that {opt timevar()} is used, as otherwise an estimate of the survival
function is obtained at each value of {bf:_t} for all subjects.
Default varname is {cmd:_t}.

{phang}
{opt toffset(varlist)} defines variables that have an offset for time for use when
predicting cause-specific cumulative incidence functions. For example, if model 1
used time since diagnosis as the time-scale and model 2 uses attained age as 
the time scale, then using {cmd:toffset(. agediag)} will make all predictions 
on the time since diagnosis time scale, but making appropriate adjustments for 
age at diagnosis.

{phang}
{opt trans(name)} transformation to apply when calculating standard errors to
obtain confidence intervals for the standardised curves. The default transformation is
log(). Other possible {it:name}s are {bf:none}, {bf:loglog}, {bf:logit}.

{phang}
{opt userfunction(name)} gives a Mata function that calculates transformations the 
standardized functions. This enables flexibility to calculate 
a wide range of potential functions. An example of a Mata function to calculate 
a difference  between two standardized function is shown below

{phang2}
{cmd:mata:}{break}
{cmd:function user_eg(at) {c -(}}{break}
{space 4}{cmd:return(at[2] - at[1])}{break}
{cmd:{c )-}}{break}

{phang2}
{cmd:end}{break}

{phang2}
{cmd:standsurv, at1(x1 0) at2(x1 1) timevar(tt) ci userfunction(user_eg)}

{phang}
{opt userfunctionvar(newvarname)} gives the new variable to create when
using the {bf:userfunction()} option. The name defaults to {bf:_userfunc}.

{phang}
{opt verbose} gives details about what is being estimated during the running
of the command, mainly used for developing and debugging. 

{marker examples}{...}
{title:Example:}

For some more detailed examples see {browse "https://pclambert.net/software/standsurv/":https://pclambert.net/software/standsurv/}

{pstd}Load example dataset:{p_end}
{phang}{stata ". webuse brcancer"}

{pstd}{cmd:stset} the data:{p_end}
{phang}{stata ". stset rectime, f(censrec==1) scale(365.24)"}

{pstd}Fit {cmd:stpm2} model:{p_end}
{phang}{stata ". stpm2 hormon x5 x1 x3 x6 x7, scale(hazard) df(4) tvc(hormon x5 x3) dftvc(3)"}

{pstd}Generate variable that defines timepoints to predict at. The following creates 50 equally spaced time points between 0.05 and 5 years:{p_end}
{phang}{stata ". range timevar 0 5 50"}

{pstd}Obtain standardised curves for {bf:hormon=0} and {bf:hormon=1}.
In each case the survival curves are the average of the 686
survival curves using the observed covariate values except for {bf:hormon}.{p_end}
{phang}{stata ". standsurv, atvars(S0a S1a) at1(hormon 0) at2(hormon 1) timevar(timevar) ci frame(f1,replace)"}

{pstd}Plot standardised curves:{p_end}
{phang}{stata ". frame f1: line S0a S1a timevar"}

{pstd}Obtain standardised curves for {bf:hormon=0} and {bf:hormon=1}, but apply the covariate distribution amongst those with {bf:hormon=1}.{p_end}
{phang}{stata ". standsurv if hormon==1, atvars(S0b S1b) at1(hormon 0) at2(hormon 1) timevar(timevar) ci frame(f2, replace)"}

{pstd}Plot standardised curves:{p_end}
{phang}{stata ". frame f2: line S0b S1b timevar"}

{pstd}Obtain standardised curves for {bf:hormon=0} and {bf:hormon=1}, and calculate difference in standardised survival curves and 95 confidence interval.

{phang}{stata ". standsurv, atvars(S0c S1c) at1(hormon 0) at2(hormon 1) timevar(timevar) ci contrast(difference) contrastvar(Sdiffc) frame(f3, replace)"}

{pstd}Plot difference in standardised curves and 95% confidence interval:{p_end}
{phang}{stata ". frame f3: line Sdiffc* timevar"}

{title:Authors}

{pstd}Paul C. Lambert{p_end}
{pstd}Biostatistics Research Group{p_end}
{pstd}Department of Population Health Sciences{p_end}
{pstd}University of Leicester{p_end}
{pstd}{it: and}{p_end}
{pstd}Department of Medical Epidemiology and Biostatistics{p_end}
{pstd}Karolinska Institutet{p_end}
{pstd}E-mail: {browse "mailto:paul.lambert@le.ac.uk":paul.lambert@le.ac.uk}{p_end}

{pstd}Michael J. Crowther{p_end}
{pstd}Biostatistics Research Group{p_end}
{pstd}Department of Health Sciences{p_end}
{pstd}University of Leicester{p_end}

{phang}
Please report any errors you may find.{p_end}


{title:References}

{phang}
Andersen PK. Decomposition of number of life years lost according to causes of death. 
{it:Statistics in Medicine} 2013;{bf:32};5278-5285

{phang}
Crowther MJ, Lambert PC. Parametric multi-state survival models: flexible modelling allowing transition-specific distributions with 
application to estimating clinically useful measures of effect differences. {it: Statistics in Medicine} 2017;{bf:36}:4719-4742.

{phang}
Stefanski L.A. and Boos, DD. The calculus of M-estimation. {it: The American Statistician} 2002;{bf:56};29-38.

  