{smcl}
{* *! version 1.0.0 05Jul2021}{...}
{vieweralsosee "stipw postestimation" "help stipw_postestimation"}{...}
{vieweralsosee "logit" "help logit"}{...}
{vieweralsosee "streg" "help streg"}{...}
{vieweralsosee "stpm2" "help stpm2"}{...}
{vieweralsosee "standsurv" "help standsurv"}{...}
{viewerjumpto "Syntax" "stipw##syntax"}{...}
{viewerjumpto "Description" "stipw##description"}{...}
{viewerjumpto "Options" "stipw##options"}{...}
{viewerjumpto "Methods" "stipw##methods"}{...}
{viewerjumpto "Examples" "stipw##examples"}{...}
{viewerjumpto "Results" "stipw##results"}{...}
{title:Title}

{p2colset 5 18 18 2}{...}
{p2col :{hi:stipw} {hline 2}}Inverse probability weighted parametric survival models with variance obtained via M-estimation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:stipw}
   {cmd:(}{cmd:logit} {it:tvar} {it:tmvarlist}
      [{cmd:,} {it:{help stipw##tmoptions:tmoptions}}]{cmd:)}
        {ifin} 
     {cmd:,}
		  {cmdab:d:istribution(}{it:distname}{cmd:)}
          [{it:{help stipw##options_table:options}}]


{phang}
{it:tvar} must be a binary variable with 1 = treatment/exposure and 0 = control.{p_end}

{phang}
{it:tmvarlist} specifies the variables that predict treatment assignment/exposure in the treatment/exposure model.{p_end}

{synoptset 34 tabbed}{...}
{marker tmoptions}{...}
{synopthdr:tmoptions}
{synoptline}
{syntab:Treatment/Exposure Model}
{synopt :{opt nocons:tant}}suppress constant from treatment/exposure model{p_end}
{synopt :{opt off:set(varname)}}include {it:varname} in model with coefficient constrained to 1{p_end}
{synopt :{opt tcoef}}displays coefficient table from treatment/exposure model{p_end}

{syntab :Maximization}
{synopt :{it:{help stipw##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}

{marker options_table}{...}
{synopthdr}
{synoptline}
{syntab:Outcome Model: {cmd:streg}}
{synopt :{cmdab:d:istribution(}{cmdab:e:xponential)}}(weighted) exponential survival outcome model{p_end}
{synopt :{cmdab:d:istribution(}{cmdab:w:eibull)}}(weighted) Weibull survival outcome model{p_end}
{synopt :{cmdab:d:istribution(}{cmdab:gom:pertz)}}(weighted) Gompertz survival outcome model{p_end}
{synopt :{cmdab:d:istribution(}{cmdab:logl:ogistic)}}(weighted) loglogistic survival outcome model{p_end}
{synopt :{cmdab:d:istribution(}{cmdab:logn:ormal)}}(weighted) lognormal survival outcome model{p_end}
{synopt :{opt ancillary}}specifies that {it:tvar} should be used to model ancillary parameter{p_end}
{synopt :{opt ocoef}}displays coefficient table from outcome model, before variance is updated with M-estimation{p_end}
{synopt :{opt ohead:er}}displays header from outcome model, before variance is updated with M-estimation{p_end}

{syntab:Outcome Model: {cmd:stpm2}}
{synopt :{cmdab:d:istribution(}{cmdab:rp)}}(weighted) flexible parametric (Royston-Parmar) survival outcome model{p_end}
{synopt :{opt bk:nots(knotslist)}}boundary knots for baseline{p_end}
{synopt :{opt bknotstvc(knotslist)}}boundary knots for time-dependent treatment/exposure{p_end}
{synopt :{cmdab:df(#)}}degrees of freedom for baseline hazard function{p_end}
{synopt :{opt dft:vc(#)}}degrees of freedom for time-dependent treatment/exposure{p_end}
{synopt :{opt failconvlininit}}automatically try lininit option if convergence fails{p_end}
{synopt :{opt knots(numlist)}}knot locations for baseline hazard{p_end}
{synopt :{opt knotst:vc(numlist)}}knot locations for time-dependent treatment/exposure{p_end}
{synopt :{opt knscale(scale)}}scale for user-defined knots (default scale is time){p_end}
{synopt :{opt noorth:og}}do not use orthogonal transformation of splines variables{p_end}
{synopt :{opt ocoef}}displays coefficient table from outcome model, before variance is updated with M-estimation{p_end}
{synopt :{opt ohead:er}}displays header from outcome model, before variance is updated with M-estimation{p_end}

{syntab:SE/Robust}
{synopt :{opt vce(vcetype)}}{it:vcetype} may be {opt mestimation}, the default, or {opt robust}{p_end}

{syntab:Advanced}
{synopt :{opt ipw:type(string)}}type of IPW weight: {cmdab:s:tabilised} (default) or {cmdab:u:nstabilsied}{p_end}
{synopt :{opt genw:eight(newvar)}}name of generated weight variable{p_end}
{synopt :{opt genf:lag(newvar)}}name of generated flag variable that indicates which observations have been used in the analysis{p_end}
{synopt :{opt stsetu:pdate}}specifies that the data in memory should be updated with {cmd:stset} that specifies the weights{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt nohead:er}}suppress header from coefficient table{p_end}
{synopt :{opt nohr}}{cmd:*} do not report hazard ratios{p_end}
{synopt :{opt tr:atio}}{cmd:*} report time ratios{p_end}
{synopt :{opt nos:how}}{cmd:*} do not show st setting information{p_end}
{synopt :{opt ef:orm}}{cmd:**} exponentiate coefficients{p_end}
{synopt :{opt alleq}}{cmd:**} report all equations{p_end}
{synopt :{opt keepc:ons}}{cmd:**} do not drop constraints in ml routine (these can be seen using {cmd: constraint dir}){p_end}
{synopt :{opt showc:ons}}{cmd:**} list constraints in output{p_end}
{synopt :{it:{help stipw##display_options:display_options}}}control columns and column formats and line width 
	
{syntab:Maximisation}
{synopt :{opt lin:init}}{cmd:**} obtain initial values by first fitting a linear function of ln(time){p_end}
{synopt :{it:{help stipw##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}

{syntab:}
{synopt :{opt coefl:egend}}display legend instead of statistics{p_end}
{synopt :{opt selegend}}display legend of standard errors instead of statistics{p_end}
	
{synoptline}
{p2colreset}{...}

{p 4 6 2}
You must {cmd:stset} your data without weights and without the {opt id} option before using {cmd:stipw}; see
{manhelp stset ST}.{p_end}
{p 4 6 2}
{it:tmvarlist} may not contain factor variables. You must create dummy variables when fitting the models.{p_end}
{p 4 6 2}
{cmd:*} This option is only available for {cmd:streg} outcome models.{p_end}
{p 4 6 2}
{cmd:**} This option is only available for {cmd:stpm2} outcome models.{p_end}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}
{cmd:stipw} performs an inverse probability weighted (IPW) analysis on survival 
data. The command fits a logistic regression model to model treatment/exposure ({it:tvar} against 
confounders {it:tmvarlist}). By default, stabilised weights are calculated and therefore a second logistic 
regression model is fit with no confounders. This is used to obtain the numerator for the weights (the treatment/exposure prevalence). 
The second logistic regression model is not required for unstabilised weights. 
The weights are named {opt _stipw_weight}, unless {opt genweight(newvar)} is specified. 
The data is then {cmd:stset} with the weights (the original {cmd:stset} is preserved, unless {opt stsetupdate} is specified). 
The specified {it:distname} survival model is fit to the weighted data. The program then estimates the variance 
using a closed-form variance estimator obtained via M-estimation. This is the default variance estimator and the stored variance matrix is updated. 
A robust variance estimator can be used instead, however, robust standard errors have been shown to be conservative in some scenarios (Austin 2016) and do
not appropriately take into account that the weights themselves are estimates and not fixed.
{p_end}

{pstd}
The variable {opt _stipw_weight} is created to store the weights. This is overwritten in
subsequent runs of {cmd:stipw}.{p_end}

{pstd}
Survival model fitting commands supported include {manhelp streg ST: streg} 
and {help stpm2}  (with {opt scale(hazard)} only). 
Postestimation commands follow {cmd:stipw} 
in the same way as they do for {cmd:streg} and {cmd:stpm2}, see {help stipw_postestimation}.
The following are not supported with {cmd:stipw}:
generalized gamma models, 
frailty and shared-frailty models,
relative survival models,
cure models and
multiple-record-per-subject survival data.{p_end}

{pstd}
{cmd:stipw} with {cmd:distribution(}{cmdab:rp)} creates new variables _rcs* and _d_rcs*. 
If {opt dftvc} or {opt knotstvc} is specified, {cmd:stipw} with {cmd:distribution(}{cmdab:rp)} 
also creates new variables _rcs_{it:tvar}* and _d_rcs_{it:tvar}* where {it:tvar} is the
treatment/exposure variable. If there is delayed entry, new variables _s0_rcs* (and if applicable 
_s0_rcs_{it:tvar}*) are created. These variables are all dropped in subsequent runs of {cmd:stipw} with 
{cmd:distribution(}{cmdab:rp)}. 

{pstd}
The option {opt stsetupdate} changes the data in memory in that it respecifies the {cmd:stset} command 
with the weights, conditioning on the estimation sample ({opt _stipw_flag}).{p_end}

{pstd}
Any observations with a missing {it:tvar} value or any missing values in {it:tmvarlist}
are excluded from the analysis. Any observations with _st == 0 are also excluded
from the analysis. A note is displayed if observations are excluded with the number excluded.
{opt _stipw_flag} is created to indicate which observations were used in the analysis. 
{opt _stipw_flag} is overwritten in subsequent runs of {cmd:stipw}.{p_end}

{pstd}
{cmd:stipw} requires package {help dm79}, which can be installed using:{p_end}
{phang}{stata ". net install dm79, from(http://www.stata.com/stb/stb56)"}

{pstd}
{cmd:stipw} with {cmd:distribution(}{cmdab:rp)} also requires the {help stpm2} and
{help rcsgen} packages, installed in the standard manner. Please ensure that you have installed 
{cmd:stpm2}, version 1.7.5 May2021 or later.


{marker options}{...}
{title:Options}

{dlgtab:Treatment/Exposure Model}

{phang}
{opt noconstant}, {opt offset(varname)}; see {helpb estimation options:[R] estimation options}.

{phang}
{opt tcoef} displays coeffiecent table from {cmd: logit} treatment/exposure model(s). Default is to omit table.


{dlgtab:Maximisation}

{phang}
{opt lininit} (only applicable to {cmd: stpm2} models). This obtains initial values 
for {cmd: stpm2} by fitting only the first spline basis function (i.e. a linear function of log survival time).
This option is seldom needed.

{marker maximize_options}{...}
{phang}
{it:maximize_options}:
{opt dif:ficult},
{opth tech:nique(maximize##algorithm_spec:algorithm_spec)},
{opt iter:ate(#)}, 
{opt nolo:g}, 
{opt tr:ace}, 
{opt grad:ient}, 
{opt showstep},
{opt hess:ian},
{opt showtol:erance},
{opt tol:erance(#)},
{opt ltol:erance(#)},
{opt nrtol:erance(#)}, and
{opt nonrtol:erance}; see {manhelp maximize R}.  These options are seldom used.


{dlgtab:Outcome Model: streg}

{phang}
{opt distribution(distname)} option must be specified. This specifies the distribution of
the weighted survival model. The options in this sub-section follow for: {cmdab:distribution(}{cmdab:e:xponential)},
{cmdab:distribution(}{cmdab:w:eibull)}, {cmdab:distribution(}{cmdab:gom:pertz)}, {cmdab:distribution(}{cmdab:logn:ormal)}
and {cmdab:distribution(}{cmdab:logl:ogistic)}.

{phang}
{cmd:ancillary} specifies that {it:tvar} is used to  model the ancillary parameter.  By default, the ancillary
parameter does not depend on {it:tvar}. 

{phang}
{opt ocoef} displays coeffiecent table from {cmd: streg} outcome model, before the variance
is updated with M-estimation. Default is to omit table. This is an intermediate step and does not 
correspond to the display options for the final coefficient table. 

{phang}
{opt oheader} displays header from {cmd: streg} outcome model, before the variance
is updated with M-estimation. Default is to omit header. This is an intermediate step and does not 
correspond to the display options for the final coefficient table. 


{dlgtab:Outcome Model: stpm2}

{phang}
{opt distribution(distname)} option must be specified. This specifies the distribution of
the weighted survival model. The options in this sub-section follow for {cmdab:distribution(}{cmdab:rp)}.

{phang}
{opt bknots(knotslist)} {it:knotslist} is a two-element {it:numlist} giving
the boundary knots. By default these are located at the minimum and maximum
of the uncensored survival times. They are specified on the scale defined
by {cmd:knscale()}.

{phang}
{opt bknotstvc(knotslist)} {it:knotslist} is a two-element {it:numlist} giving
the boundary knots for the time-dependent treatment/exposure {it:tvar}. 
By default these are the same as for the bknots option. 
They are specified on the scale defined by {cmd:knscale()}. 
{opt dftvc(#)} or {opt knotstvc(# [# ...])} need to be specified in order to 
specify {opt bknotstvc(knotslist)}.

{phang}
{opt df(#)} specifies the degrees of freedom for the restricted
cubic spline function used for the baseline function. {it:#} must be between
1 and 10, but usually a value between 1 and 4 is sufficient, with 3 being a common choice. 
Exactly one of {cmd:knots()} and {cmd:df()} must be specified. 
The knots are placed at the following centiles of the
distribution of the uncensored log survival times:

        {hline 60}
        df  knots        Centile positions
        {hline 60}
         1    0    (no knots)
         2    1    50
         3    2    33 67
         4    3    25 50 75
         5    4    20 40 60 80
         6    5    17 33 50 67 83
         7    6    14 29 43 57 71 86
         8    7    12.5 25 37.5 50 62.5 75 87.5
         9    8    11.1 22.2 33.3 44.4 55.6 66.7 77.8 88.9
        10    9    10 20 30 40 50 60 70 80 90     
        {hline 60}
        
{pmore}
Note that these are {it:interior knots} and there are also boundary knots
placed at the minimum and maximum of the distribution of uncensored survival
times. 

{phang}
{opt dftvc(#)} gives the degrees of freedom for the time-dependent treatment/exposure {it:tvar}.
The potential degrees of freedom are listed under the {opt df()} option. 
With 1 degree of freedom a linear effect of log time is fitted.
The {cmd:knotstvc()} option is not applicable if the {cmd:dftvc()} option
is specified.

{phang}
{opt failconvlininit} automatically tries the {opt lininit} option of the
model fails to converge.

{phang}
{opt knots(# [# ...])} specifies knot locations for the baseline distribution
function, as opposed to the default locations set by {cmd:df()}. Note that
the locations of the knots are placed on the scale defined by {cmd:knscale()}.
However, the scale used by the restricted cubic spline function is always
log time.

{phang}
{opt knotstvc(# [# ...])} specifies the location of the interior knots for 
the time-dependent treatment/exposure {it:tvar}, as opposed to the default locations set by
{cmd:dftvc()}.

{phang}
{opt knscale(scale)} sets the scale on which user-defined knots are specified.
{cmd:knscale(time)} denotes the original time scale, {cmd:knscale(log)} the
log time scale and {cmd:knscale(centile)} specifies that the knots
are taken to be centile positions in the distribution of the uncensored log
survival times. The default is {cmd:knscale(time)}.

{phang}
{cmd: noorthog} suppresses orthogonal transformation of spline variables.

{phang}
{opt ocoef} displays coeffiecent table from {cmd: stpm2} outcome model, before the variance
is updated with M-estimation. Default is to omit table. This is an intermediate step and does not 
correspond to the display options for the final coefficient table. 

{phang}
{opt oheader} displays header from {cmd: stpm2} outcome model, before the variance
is updated with M-estimation. Default is to omit header. This is an intermediate step and does not 
correspond to the display options for the final coefficient table. This option needs to be 
specified with {opt ocoef}, as the header cannot be displayed without the coefficient table.


{dlgtab:SE/Robust}

{phang}
{opt vce(vcetype)} specifies the type of standard error reported. The default is {opt mestimation}. 
This provides a closed-form variance estimator, which appropriately takes into account that the 
weights are estimated and not fixed. {opt robust} can be specified, but this will not take
into account that the weights are estimated. 


{dlgtab:Advanced}

{phang}
{opt ipwtype(string)} specifies the type of IPW weight to be used: {cmdab:s:tabilised} (default) or {cmdab:u:nstabilised}.
Stabilised weights require the estimation of the treatment/exposure prevalence and therefore there is an additional row/column in the full variance matrix, e(V_full).{p_end}

{phang}
{opt genweight(newvar)} specifies the name of the generated weight variable. By default, weights are stored in {opt _stipw_weight}.{p_end}

{phang}
{opt genflag(newvar)} specifies the name of the generated flag variable to show which observations have been used in the analysis. 
By default, the indicator is stored in {opt _stipw_flag}.{p_end}

{phang}
{opt stsetupdate} changes the data in memory in that it respecifies the {cmd:stset} command 
with the weights, conditioning on the estimation sample ({opt _stipw_flag}).{p_end}


{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals.  The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt noheader} suppresses the output header.

{phang}
{opt nohr} (only applicable to {cmd: streg} models) specifies that coefficients 
rather than exponentiated coefficients be displayed, that is, that coefficients 
rather than hazard ratios be displayed.  This option affects only how coefficients 
are displayed, not how they are estimated. This option is valid only for models 
with a natural proportional-hazards parameterization: exponential, Weibull and Gompertz.  
These models, by default, report hazards ratios (exponentiated coefficients). 

{phang}
{opt tratio} (only applicable to {cmd: streg} models) specifies that 
exponentiated coefficients, which are interpreted as time ratios, be displayed.  
{opt tratio} is appropriate only for the loglogistic and lognormal or for the exponential
and Weibull models when fit in the accelerated failure-time metric.

{phang}
{opt noshow} (only applicable to {cmd: streg} models) prevents {cmd:stipw} 
from showing the key st variables.  This option is rarely used because most people 
type {cmd:stset, show} or {cmd:stset, noshow} to set once and for all whether 
they want to see these variables mentioned at the top of the output of every st 
command; see {manhelp stset ST}. {cmd: stpm2} models must use {opt noshow}.

{phang}
{opt eform} (only applicable to {cmd: stpm2} models) reports the exponentiated coefficents. 
This gives the hazard ratio of the treatment/exposure {it:tvar} if it is not time-dependent, i.e.,
if {opt dftvc(#)} and {opt knotstvc(# [# ...])} are not specified.

{phang}
{opt keepcons} (only applicable to {cmd: stpm2} models) prevents the constraints 
imposed by {cmd:stpm2} on the derivatives of the spline function when fitting 
delayed entry models being dropped. This can be viewed using {cmd: constraint dir}.
By default, the constraints are dropped.

{phang}
{opt alleq} (only applicable to {cmd: stpm2} models) reports all equations used by ml. 
The models are fitted by using various constraints for parameters associated with 
the derivatives of the spline functions. These parameters are generally not of 
interest and thus are not shown by default. In addition, an extra equation is used 
when fitting delayed entry models, and again this is not shown by default.

{phang}
{opt showcons} (only applicable to {cmd: stpm2} models). The constraints used by 
{cmd:stpm2} for the derivatives of the spline function and when fitting delayed 
entry models are not listed by default. Use of this option lists them in the output.

{marker display_options}{...}
{phang}
{it:display_options}:
{opt noci},
{opt nopv:alues},
{opt cformat(%fmt)},
{opt pformat(%fmt)},
{opt sformat(%fmt)},
{opt nolstretch};  see {helpb estimation options##display_options:[R] estimation options}.
{p_end}


{pstd}
The following options are available with {opt stipw}:

{phang}
{opt coeflegend}; see {helpb estimation options##coeflegend:[R] estimation options}.

{phang}
{opt selegend} specifies that the legend of the standard errors of the coefficients and how to specify them in an expression be displayed 
rather than displaying the statistics for the standard errors of the coefficients.


{marker methods}{...}
{title:Methods}

{pstd}
The formulas below define unstabilised (uw) and stabilised (sw) weights, where A denotes
the binary treatment/exposure variable {it:tvar}, X denotes the confounders {it:tmvarlist} and I represents
the indicator function:{p_end}

{pin}
uw =  I(A=1)/P(A=1|X) + I(A=0)/P(A=0|X){p_end}
{pin}
sw =  I(A=1)*P(A=1)/P(A=1|X) + I(A=0)*P(A=0)/P(A=0|X){p_end}

{pstd}
Point estimates are calculated from the weighted data in the usual way by maximum likelihood estimation with {cmd:streg} and {cmd:stpm2}.
The variance (of all model parameteres - treatment/exposure model(s) and outcome model)
is estimated using a closed-form variance estimator obtained via M-estimation.
M-estimation is chosen as the default variance estimator, as robust standard errors have been found to be conservative in some cases by Austin 2016
and do not appropriately take into account that the weights are estimated and not fixed. 
M-estimation first involves defining a set of estimating equations, similar to those in Williamson et al 2014, but applied
to survival outcome models. The variance is then estimated as described by Stefanski and Boos 2002. 
See Hill et al (in draft) for full details and formulas on how the variance is estimated.
{p_end}

{pstd}
For further reading, see Hajage et al 2018 and Shu et al 2020 for closed form variance estimators for IPW Cox models.{p_end}


{marker examples}{...}
{title:Example 1: {cmd:streg} model}

{pstd}Load example dataset:{p_end}
{phang}{stata ". webuse brcancer, clear"}

{pstd}{cmd:stset} the data:{p_end}
{phang}{stata ". stset rectime, f(censrec==1) scale(365.24)"}

{pstd}Exposure of interest is {it: hormon}.{p_end}
{pstd}Fit an unweighted Weibull model to the data (ignoring confounders) using {cmd:streg}:{p_end}
{phang}{stata ". streg hormon, distribution(weibull)"}

{pstd}We wish to adjust for confounders {it: x1}, {it:x2}, {it:x3}, {it:x5}, {it:x6} and {it:x7}.{p_end}
{pstd}Perform an IPW analysis using {cmd:stipw}. Fit a weighted Weibull model (weights from a {cmd:logit} model) and obtain standard errors from M-estimation (this is the default):{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(weibull)"}

{pstd}Repeat, but obtain robust standard errors for comparison:{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(weibull) vce(robust)"}

{pstd}Repeat, but show the output for each stage:{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7, tcoef) , distribution(weibull) ocoef oheader"}

{pstd}Repeat and store the stablised weights (the default) in {it:sweight} and indicator in {it:flag}:{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(weibull) genweight(sweight) genflag(flag)"}

{pstd}Now use unstabilised weights. Store the unstabilised weights in {it:uweight}:{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(weibull) ipwtype(unstabilised) genweight(uweight)"}

{pstd}Fit the model using {it:hormon} to model the ancillary parameter:{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(weibull) ancillary"}

{pstd}Repeat, but now update the {cmd:stset} command:{p_end}
{phang}{stata ". char list"}{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(weibull) ancillary stsetupdate"}{p_end}
{phang}{stata ". char list"}{p_end}
{pstd}You will now need to {cmd:stset} the data without weights if you wish to run another {cmd:stipw} command.{p_end}

{pstd}Repeat, reporting time ratios and set CI level as 90%:{p_end}
{phang}{stata ". stset rectime, f(censrec==1) scale(365.24)"}{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(weibull) ancillary tratio level(90)"}


{title:Example 2: {cmd:stpm2} model}

{pstd}Load example dataset:{p_end}
{phang}{stata ". webuse brcancer, clear"}

{pstd}{cmd:stset} the data:{p_end}
{phang}{stata ". stset rectime, f(censrec==1) scale(365.24)"}

{pstd}Exposure of interest is {it: hormon}.{p_end}
{pstd}Fit an unweighted Royston-Parmar (RP) model to the data (ignoring confounders) with 3 degrees of freedom using {cmd:stpm2}:{p_end}
{phang}{stata ". stpm2 hormon, scale(hazard) df(3)"}

{pstd}We wish to adjust for confounders {it: x1}, {it:x2}, {it:x3}, {it:x5}, {it:x6} and {it:x7}.{p_end}
{pstd}Perform an IPW analysis using {cmd:stipw}. Fit a weighted RP model (weights from a {cmd:logit} model) and obtain standard errors from M-estimation (this is the default):{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(rp) df(3)"}

{pstd}Repeat, but obtain robust standard errors for comparison:{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(rp) df(3) vce(robust)"}

{pstd}Repeat, but show the output for each stage:{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7, tcoef) , distribution(rp) df(3) ocoef oheader"}

{pstd}By default, stabilised weights are used. Now use unstabilised weights and store in {it:uweight}:{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(rp) df(3) ipwtype(unstabilised) genweight(uweight)"}

{pstd}Repeat, but as {it:hormon} is not time-dependent, when we use the {opt eform} option this will be the hazard ratio:{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(rp) df(3) eform"}

{pstd}Fit an unweighted RP model to the data (ignoring confounders) with time-dependent {it:hormon}:{p_end}
{phang}{stata ". stpm2 hormon, scale(hazard) df(3) tvc(hormon) dftvc(2)"}

{pstd}Fit the corresponding weighted model with {cmd:stipw} and obtain M-estimation standard errors{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(rp) df(3) dftvc(2)"}

{pstd}Repeat, displaying all the equations and all the constraints{p_end}
{phang}{stata ". stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(rp) df(3) dftvc(2) alleq showcons"}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:stipw} stores the following in {cmd:e()}, most of which come from {cmd:streg}/{cmd:stpm2}.{p_end}
{p 4 6 2}
{cmd:*} This object is only available for {cmd:streg} outcome models.{p_end}
{p 4 6 2}
{cmd:**} This object is only available for {cmd:stpm2} outcome models.{p_end}
{p 4 6 2}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(n0)}}number of observations in the control group{p_end}
{synopt:{cmd:e(n1)}}number of observations in the treatment/exposure group{p_end}
{synopt:{cmd:e(N_sub)}}{cmd:*} number of subjects{p_end}
{synopt:{cmd:e(N_fail)}}{cmd:*} number of failures{p_end}
{synopt:{cmd:e(del_entry)}}{cmd:**} indicator for delayed entry{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(k_aux)}}{cmd:*} number of auxiliary parameters{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(df_m)}}{cmd:*} model degrees of freedom (includes ancillary parameter if specified){p_end}
{synopt:{cmd:e(dfbase)}}{cmd:**} degrees of freedom in baseline hazard{p_end}
{synopt:{cmd:e(df_{it:tvar})}}{cmd:**} degrees of freedom for time-dependent treatment/exposure variable {it:tvar} {p_end}
{synopt:{cmd:e(nxbterms)}}{cmd:**} number of xb terms (_rcs*) including time-dependent {it:tvar} terms{p_end}
{synopt:{cmd:e(ndxbterms)}}{cmd:**} number of dxb terms (_d_rcs*) including time-dependent {it:tvar} terms{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}{cmd:*} log likelihood, constant-only model{p_end}
{synopt:{cmd:e(dev)}}{cmd:**} deviance = -2 * log likelihood{p_end}
{synopt:{cmd:e(AIC)}}{cmd:**} AIC{p_end}
{synopt:{cmd:e(AIC)}}{cmd:**} BIC{p_end}
{synopt:{cmd:e(chi2)}}{cmd:*} chi-squared test statistic simultaneously testing all occurences of {it:tvar} (including ancillary/splines){p_end}
{synopt:{cmd:e(risk)}}{cmd:*} total time at risk{p_end}
{synopt:{cmd:e(aux_p)}}{cmd:*} ancillary parameter ({cmd:weibull}){p_end}
{synopt:{cmd:e(gamma)}}{cmd:*} ancillary parameter ({cmd:gompertz, loglogistic}){p_end}
{synopt:{cmd:e(sigma)}}{cmd:*} ancillary parameter ({cmd:lnormal}){p_end}
{synopt:{cmd:e(p)}}{cmd:*} p-value for model test{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code for {cmd:streg}/{cmd:stpm2} outcome model{p_end}
{synopt:{cmd:e(rc_logit)}}return code for {cmd:logit} treatment/exposure model{p_end}
{synopt:{cmd:e(rc_logit2)}}return code for the second {cmd:logit} model (no confounders) if stabilised weights are used{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise ({cmd:streg}/{cmd:stpm2} outcome model){p_end}
{synopt:{cmd:e(converged_logit)}}{cmd:1} if converged, {cmd:0} otherwise ({cmd:logit} treatment/exposure model){p_end}
{synopt:{cmd:e(converged_logit2)}}{cmd:1} if converged, {cmd:0} otherwise (second {cmd:logit} model (no confounders) if stabilised weights are used){p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}model ({cmd:streg}) or {cmd:stpm2}{p_end}
{synopt:{cmd:e(cmd2)}}{cmd:*} {cmd:streg}{p_end}
{synopt:{cmd:e(cmd3)}}{cmd:stipw}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(cmdline_logit)}}command as used for {cmd:logit} treatment/exposure model{p_end}
{synopt:{cmd:e(cmdline_logit2)}}command as used for the second {cmd:logit} model (no confounders) if stabilised weights are used{p_end}
{synopt:{cmd:e(cmdline_streg)}}{cmd:*} command as used for {cmd:streg} outcome model.{p_end}
{synopt:{cmd:e(cmdline_stpm2)}}{cmd:**} command as used for {cmd:stpm2} outcome model.{p_end}
{synopt:{cmd:e(dead)}}{cmd:*} {cmd:_d}{p_end}
{synopt:{cmd:e(depvar)}}{cmd:_t} ({cmd:streg}) or {cmd:_d _t} ({cmd:stpm2}){p_end}
{synopt:{cmd:e(tvar)}}name of treatment/exposure variable {it:tvar}{p_end}
{synopt:{cmd:e(offset_logit)}}name of offset variable used in the treatment/exposure {cmd:logit} model{p_end}
{synopt:{cmd:e(varnames)}}{cmd:**} treatment/exposure variable {it:tvar}{p_end}
{synopt:{cmd:e(varlist)}}{cmd:**} treatment/exposure variable {it:tvar}{p_end}
{synopt:{cmd:e(tvc)}}{cmd:**} time-dependent variable: treatment/exposure variable {it:tvar} or missing{p_end}
{synopt:{cmd:e(drcsterms_base)}}{cmd:**} name of the _d_rcs* baseline hazard splines{p_end}
{synopt:{cmd:e(rcsterms_base)}}{cmd:**} name of the _rcs* baseline hazard splines{p_end}
{synopt:{cmd:e(drcsterms_{it:tvar})}}{cmd:**} name of the _d_rcs_{it:tvar}* time-dependent treatment/exposure {it:tvar} splines{p_end}
{synopt:{cmd:e(rcsterms_{it:tvar})}}{cmd:**} name of the _rcs_{it:tvar}* time-dependent treatment/exposure {it:tvar} splines{p_end}
{synopt:{cmd:e(ln_bhknots)}}{cmd:**} log of all the knot locations for the baseline hazard{p_end}
{synopt:{cmd:e(bhknots)}}{cmd:**} interior knot locations for the baseline hazard on the time scale{p_end}
{synopt:{cmd:e(ln_tvcknots_{it:tvar})}}{cmd:**} log of all the knot locations for time-dependent treatment/exposure {it:tvar} variable{p_end}
{synopt:{cmd:e(tvcknots_{it:tvar})}}{cmd:**} interior knot locations for time-dependent treatment/exposure {it:tvar} variable on the time scale{p_end}
{synopt:{cmd:e(boundary_knots)}}{cmd:**} boundary knot locations for the baseline hazard{p_end}
{synopt:{cmd:e(boundary_knots_{it:tvar})}}{cmd:**} boundary knot locations for time-dependent treatment/exposure {it:tvar} variable{p_end}
{synopt:{cmd:e(scale)}}{cmd:**} the scale on which the survival model is fitted: hazard{p_end}
{synopt:{cmd:e(orthog)}}{cmd:**} indicator of orthogonal transformation of spline variables{p_end}
{synopt:{cmd:e(title)}}{cmd:*} title in estimation output{p_end}
{synopt:{cmd:e(wtype)}}weight type: {cmd:pweight} only{p_end}
{synopt:{cmd:e(ipwtype)}}IPW weight type: stabilised or unstabilised{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(t0)}}{cmd:*} {cmd:_t0}{p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(frm2)}}{cmd:*} {cmd:hazard} or {cmd:time}{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:*} {cmd:Wald}; type of model chi-squared test{p_end}
{synopt:{cmd:e(stcurve)}}{cmd:*}  {cmd:stcurve}{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                         maximization or minimization{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(predict_sub)}}{cmd:*}  {cmd:predict} subprogram{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(b_full)}}full coefficient vector including estimates from treatment/exposure model (produced with {cmd:vce(}mestimation{cmd:)}){p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(Cns)}}{cmd:**} constraints matrix{p_end}
{synopt:{cmd:e(R_bh)}}{cmd:**} matrix used for orthogonal transformation of baseline hazard spline variables{p_end}
{synopt:{cmd:e(R_{it:tvar})}}{cmd:**} matrix used for orthogonal transformation of time-dependent treatment/exposure {it:tvar} spline variables{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_full)}}full variance-covariance matrix including estimates from treatment/exposure model (produced with {cmd:vce(}mestimation{cmd:)}){p_end}
{synopt:{cmd:e(V_A)}}A matrix used to calculate {cmd:vce(}mestimation{cmd:)} standard errors{p_end}
{synopt:{cmd:e(V_B)}}B matrix used to calculate {cmd:vce(}mestimation{cmd:)} standard errors{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}
{synopt:{cmd:e(V_robust)}}standard robust variance{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{title:Authors}

{pstd}Micki Hill{p_end}
{pstd}Biostatistics Research Group{p_end}
{pstd}Department of Health Sciences{p_end}
{pstd}University of Leicester{p_end}
{pstd}E-mail: {browse "mailto:mh594@le.ac.uk":mh594@le.ac.uk}{p_end}

{pstd}Paul C. Lambert{p_end}
{pstd}Biostatistics Research Group{p_end}
{pstd}Department of Health Sciences{p_end}
{pstd}University of Leicester{p_end}
{pstd}{it: and}{p_end}
{pstd}Department of Medical Epidemiology and Biostatistics{p_end}
{pstd}Karolinska Institutet{p_end}

{pstd}Michael J. Crowther{p_end}
{pstd}Department of Medical Epidemiology and Biostatistics{p_end}
{pstd}Karolinska Institutet{p_end}

{phang}
Please report any errors you may find.{p_end}


{title:References}

{phang}
Austin PC. Variance estimation when using inverse probability of treatment weighting (IPTW) with survival analysis. Statistics in Medicine. 2016;35(30):5642-55.
{p_end}

{phang}
Hajage D, Chauvet G, Belin L, Lafourcade A, Tubach F, De Rycke Y. Closed‐form variance estimator for weighted propensity score estimators with survival outcome. Biometrical Journal. 2018;60(6):1151-63.
{p_end}

{phang}
Shu D, Young JG, Toh S, Wang R. Variance estimation in inverse probability weighted Cox models. Biometrics. 2020;1-17.
{p_end}

{phang}
Stefanski LA and Boos DD. The calculus of M-estimation. The American Statistician. 2002;56;29-38.
{p_end}

{phang}
Williamson EJ, Forbes A, White IR. Variance reduction in randomised trials by inverse probability weighting using the propensity score. Statistics in Medicine. 2014;33(5):721-37.
{p_end}