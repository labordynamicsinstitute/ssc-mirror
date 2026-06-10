{smcl}
{* *! version 1.0)}
{hline}
{cmd:help mixedpower}
{hline}
{vieweralsosee "[R] mixed" "help mixed"}{...}
{vieweralsosee "mvmixedpower" "help mvmixedpower"}{...}
{vieweralsosee "dmmixedpower" "help dmmixedpower"}{...}
{vieweralsosee "trialcounts" "help trialcounts"}{...}
{viewerjumpto "Syntax" "mixedpower##syntax"}{...}
{viewerjumpto "Menu" "mixedpower##menu"}{...}
{viewerjumpto "Description" "mixedpower##description"}{...}
{viewerjumpto "Options" "mixedpower##options"}{...}
{viewerjumpto "Warnings" "mixedpower##warnings"}{...}
{viewerjumpto "Examples" "mixedpower##examples"}{...}
{viewerjumpto "Stored results" "mixedpower##results"}{...}
{viewerjumpto "Author" "mixedpower##author"}{...}

{title:Title}
{p2colset 5 20 20 2}{...}
{p2col :{hi:mixedpower} {hline 2}}{cmd:mixedpower} is a program for calculating power or sample size analytically for linear mixed-effects
models, typically for the design of a randomised clinical trial. As such, calculation will be far quicker and generally more accurate than by the 
use of simulation. The user has the facility to select the treatment effect 
parameterisation, covariance structure, allocation ratio, adjust for both dropout and incomplete follow-up due to staggered recruitment, 
and even account for misspecification of the treatment effect.
It is anticipated that the most likely scenario of use will be where there are repeated measurements over time, and some of the 
option terminology reflects this (for example {opt sched:ule}). However, the generalisability of the command allows for designs that are 
not necessarily temporal.{p_end}

{p 4}{...}
See also {helpb mvmixedpower}, {helpb dmmixedpower}, {helpb trialcounts}
{p2colreset}{...}
	
{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mixedpower}
        {cmd:,} 
		{cmd: trtspec(}{it:{help mixedpower##trtspec_type:trtspec_type}}{cmd:)}
		{opth sched:ule(numlist)}
        [{it:{help mixedpower##options_table:options}}]
		
{synoptset 36 tabbed}{...}
{marker options}
{marker options_table}{...}
{synopthdr}
{synoptline}

{p2coldent :* {cmd: trtspec(}{it:{help mixedpower##trtspec_type:trtspec_type}}{cmd:)}}specification of treatment effect type, either {opt slope}, {opt intercept}, {opt factor}, {opt factor0}, {opt lateslope}, {opt slint} or {opt user()}{p_end}
{p2coldent :* {opth sched:ule(numlist)}}the time values for the visit schedule{p_end}
{synopt :{opt a:lpha(#)}}significance level; default is 0.05{p_end}
{synopt :{opt twos:ided}}request a properly two-sided test{p_end}
{synopt :{opt pow:er(#)}}power; default is 0.8, required to compute sample size{p_end}
{synopt :{opt n(#)}}total sample size; required to compute power{p_end}
{synopt :{cmd: altcont(}{it:{help mixedpower##altcont_type:altcont_type}}{cmd:)}}alternative parameterisation of the control group. Default is to include both a slope and intercept (not specified){p_end}
{synopt :{cmd: actualtrt(}{it:{help mixedpower##trtspec_type:trtspec_type}}{cmd:)}}specify correct treatment parameterisation{p_end}
{synopt :{cmd: actualcont(}{it:{help mixedpower##altcont_type:altcont_type}}{cmd:)}}specify correct parameterisation of the control group{p_end}
{synopt :{opt cbeta(# [# ...])}}control group parameter values if using {opt actualcont}{p_end}
{synopt :{opt diff:erence(# [# ...])}}magnitude of the treatment effect. A number is required for each treatment related parameter. 
See {opt trtspec(trtspec_type)}{p_end}
{synopt :{opt eff:ectiveness(#)}}alternative treatment effect specification for slope-term only, given in 
proportionate terms relative to the control group slope{p_end}
{synopt :{opt conts:lope(#)}}the mean control group slope that the effectiveness option is relative to. 
Not required if {opt diff:erence} used{p_end}
{synopt :{opt lct:est(# # ...)}}instruction for a linear combination test of each treatment-based parameter on 1df.
{opt lct:est()} or {opt jtt:est()} required when there is more than one treatment parameter{p_end}
{synopt :{opt jtt:est(# # ...)}}instruction for a joint test of each treatment-based parameter with df 
 based on number of non-zero entries in {opt jtt:est(# # ...)}{p_end}
{synopt :{opth cov:ariance(matrix)}}user input of the random effect covariance matrix{p_end}
{synopt: {cmdab:error:var(#)}}user input of the random error variance{p_end}
{synopt :{opt auto}}alternative specification of covariance and error variance parameters that indicates automatic input of variance estimates from a mixed model in memory{p_end}
{synopt :{cmd: covhet(}{it:{help mixedpower##input_type:input_type}}[({cmd:} {it:{help matrix}}{cmd:)])}}to indicate a specific alternate random effect covariance matrix for the treatment group{p_end}
{synopt :{opt marginal}}tells the program not to expect any random effect parameters, i.e. a marginal model{p_end}
{synopt:{cmd:errxt(}{it:{help mixedpower##input_type:input_type}}[{cmd:(} {it:{help mixedpower##xterror_type:xterror_type}}{cmd:[# ... |mat_name])])}}to indicate a specific residual error structure instead of assuming 
IID errors{p_end}
{synopt:{cmd:errhet(}{it:{help mixedpower##input_type:input_type}}[{cmd:(} {it:{help mixedpower##xterror_type:xterror_type}}{cmd:[# ... |mat_name])])}}to indicate a specific alternate residual error structure for the 
treatment group{p_end}
{synopt :{opt sca:le(#)}}the ratio of the timescale used for the variance components and the timescale in {opt schedule};
 default is 1{p_end}
{synopt :{opt ara:tio(# #)}}allocation ratio between groups; default is equal allocation (1 1){p_end}
{synopt :{opth drop:outs(numlist)}}the proportion who only reached visit k of {opt schedule}, and no further, due to dropout.
Must sum to 1{p_end}
{synopt :{opth drop2(numlist)}}the dropout proportions in the treatment group, if different.
Must sum to 1{p_end}
{synopt :{opth strec:ruitment(numlist)}}the proportion who only reached visit k of {opt schedule}, and no further, due to staggered recruitment. Need not sum to 1{p_end}
{synopt :{opt nohead:er}}suppress display of {cmd:mixedpower} header banner{p_end}
{synopt :{opt nosyn:tax}}suppress display of the mixed model syntax that {opt mixedpower} is calculating power/sample size for{p_end}
{synopt :{opt notab:le}}suppress display of table count per visit given for incomplete follow-up{p_end}
{synopt :{opt xmat(#)}}return the X matrix from 'cohort' number # in the return list{p_end}
{synopt :{opt rmat(#)}}return the R matrix from 'cohort' number # in the return list{p_end}
{synopt :{opt zmat(#)}}return the Z matrix from 'cohort' number # in the return list{p_end}
{synopt :{opt gmat(#)}}return the G matrix from 'cohort' number # in the return list{p_end}
{synopt :{opt bvarn(#)}}return the covariance matrix of fixed effects based on 'cohort' number # in the return list{p_end}

{synoptline}
{pstd}*this option is required.
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{marker trtspec_type}{...}
{synopthdr :trtspec_type}
{synoptline}
{synopt :{opt slope}}proportionate slope effect i.e. constrained to equal control slope at baseline{p_end}
{synopt :{opt intercept}}intercept effect i.e. parallel shift{p_end}
{synopt :{opt lateslope #}}slope effect that only starts to differ from control slope at time #{p_end}
{synopt :{opt 2slope #}}two separate slope effects with changepoint at time #{p_end}
{synopt :{opt slint}}separate slope and intercept treatment effects{p_end}
{synopt :{opt factor}}factorised i.time#1.treatment interactions but constrained to be equal to control at 'baseline'{p_end}
{synopt :{opt factor0}}fully factorised i.time#1.treatment interactions including at 'baseline'{p_end}
{synopt :{opt user(f1(t) [;f2(t)])}}allows user to specify up to 2 functions of 'schedule time'{p_end}

{synoptset 29 tabbed}{...}
{marker altcont_type}{...}
{synopthdr :altcont_type}
{synoptline}
{syntab:Default is both slope and intercept terms for control group (never specified)}
{synopt :{opt noslope}}intercept term only i.e. horizontal line{p_end}
{synopt :{opt noint}}no intercept term i.e. slope term only with origin at (0,0){p_end}
{synopt :{opt 2slope #}}two separate slope terms with changepoint at time # plus intercept{p_end}
{synopt :{opt factor}}fully factorised i.time{p_end}
{synopt :{opt user(f1(t) [;f2(t)])}}allows user to specify up to 2 functions of 'schedule time' plus intercept{p_end}

{synoptset 29 tabbed}{...}
{marker input_type}{...}
{synopthdr :input_type}
{synoptline}
{syntab:Input type for the {opt covhet}, {opt errxt} and {opt errhet} options}
{synopt :{opt input}}indicates user-entry i.e. type out parameter values or provide a matrix{p_end}
{synopt :{opt auto}}indicates auto-entry from mixed model in memory{p_end}


{synoptset 29 tabbed}{...}
{marker xterror_type}{...}
{synopthdr :xterror_type}
{synoptline}
{syntab:All options available with {helpb mixed##restype:{cmd:mixed} restype} are allowable (except AR and MA models with more than 2 terms, currently)}
{synopt :{opt independent [#]}}independent within-group errors, though not necessarily common variance{p_end}
{synopt :{opt exchangeable}}within-group errors with equal variances and one common covariance{p_end}
{synopt :{opt ar #}}within-group errors with autoregressive (AR) structure of order # (currently # not>2){p_end}
{synopt :{opt ma #}}within-group errors with moving-average (MA) structure of order #  (currently # not>2){p_end}
{synopt :{opt unstructured}}within-group errors with distinct variances and covariances{p_end}
{synopt :{opt banded #}}within-group errors with distinct variances and covariances within first # off-diagonals{p_end}
{synopt :{opt toeplitz #}}within-group errors have Toeplitz structure of order #; Toeplitz implies that 
all matrix off-diagonals be estimated{p_end}
{synopt :{opt exponential}}within-group errors with an exponential function for the pairwise correlations 
and one overall error variance{p_end}
{syntab:See {help mixedpower##errxt: {bf:errxt}} for details on how to specify these error structures}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mixedpower} performs analytic sample size or power calculations for a proposed RCT using the asymptotic formula for the 
fixed effects variance-covariance matrix of a linear mixed model: Var({bf:B_hat})=({bf:X}'({bf:Sigma}^-1){bf:X})^-1, 
where {bf:Sigma}={bf:R}+{bf:ZGZ}'. The variance-covariance matrix is calculated for a nominal 2-person trial* and includes the 
2-person variance* for the proposed treatment effect parameter(s) may then be used in a power/sample size calculation in the conventional
manner, suitably adjusting for the proposed or required sample size. All calculations are based on the z distribution, with the exception 
of the joint tests of multiple treatment-based parameters which are based on the non-central chi-squared distribution.
The variance-covariance matrix is
 derived from 4 matrices that reflect the proposed mixed model for a representive control and representive treatment group 
 subject*: the design matrix of fixed effects {bf:X}, 
 residual error matrix {bf:R}, the design matrix of random effects {bf:Z} and the covariance matrix of random effects {bf:G}.
 Details of the general approach can be found in Frost et al (2008), for example.
 In {cmd:mixedpower} entry of the required parameter values is always possible directly from the user, 
 either as real number values or as a matrix,
 but all values can also instead be 'automatically' entered from a suitable {cmd:mixed} model in memory which speeds up practical
 use of the command appreciably.
 While it is the user's responsibility to check whether this model is 'suitable', the program contains considerable checks on the 
 inputs combined with helpful error messages should the program be forced to exit.
 
 {pstd}
{cmd:mixedpower} allows the user to choose various control and treatment group parameterisations reflected in {bf:X}, including
any user-defined function, whilst allowable
random effects choices impact {bf:Z} and {bf:G}. This includes the facility to choose separate {bf:G} blocks for control
 and treatment groups. Whilst IID errors are often chosen with random effects,
 the {bf:R} matrix can be made to reflect any resisual error structure allowed with 
{helpb mixed##restype:{cmd:mixed} restype}, including separates structures for control and treatment groups. 
Such a model is usually selected 
without random effects (using option {opt marginal}) in order to model the covariance structure directly i.e. a marginal model, but
{cmd:mixedpower} does allow input with both complex error structure and random effects included.

 {pstd}
 With treatment effect specifications that involve more than one model term, then a matching number 
 of treatment effect differences
 must be provided, with sample size or power then based on a linear combination or joint test of those parameters 
 (which can be just 
one parameter). A particular feature of {cmd:mixedpower} is that one may calculate power or sample size for a 'misspecified' model. 
That is, when a particular treatment model specification is assumed (or rather, fitted in the future study) 
but the true data actually follow an alternative treatment specification.
For example, one may explore the impact of an analyis plan that proposes a proportionate slope treatment effect term fitted to 
the trial data,
 when in fact the true treatment effect is made up of arbitrary (non-linear) sizes
 across visit timepoints. This feature utilises the generalized least squares estimator for 
 {bf:B_hat}={bf:((X'(Sigma_hat^-1)X)^-1)X'(Sigma_hat^-1)y}. 'Misspecification' of the control group parameterisation is also allowed,
though is not usually important for estimation of the treatment effect.

{pstd}
 Other capabilities provided by {cmd:mixedpower} include adjustments for unequal allocation ratio and incomplete
observation due to either (or both) dropout and staggered recruitment. Dropout is even allowed to be different for the
control and treatment groups. Companion program {helpb trialcounts}, which aids the user greatly in specifying plausible and accurate
recruitment and dropout functions, is designed to easily transfer the necessary inputs for {cmd:mixedpower}.
 The mathematical implication of either dropout or staggered recruitment
is equivalent, where the sample can be thought of as being divided into {it:k} cohorts with 
common visit schedule reached, with associated probability 
{it:p_k}, but {cmd:mixedpower} derives the {it:k} integrated probabilities when both causes are relevant. 
To derive sample size or power with 
incomplete observation {cmd:mixedpower} calculates the Var({bf:B_hat_k}) for each independent cohort {it:k} 
and then produces the Var({bf:B_hat}) for the
completed (2-person*) implied dataset using the {it:k} probability weightings {it:p_k}. A further feature is that the 
 mixed model syntax implied by the specific {cmd:mixedpower} command is reported.

{pstd}
Whilst the primary purpose of the program is for calculating power or sample size for longitudinal data models, there is facility to use 
{cmd: mixedpower} for more general designs. Specifically, parameterisation of the control and treatment arms without slope terms and a covariance
structure without random slopes imply model independence from the actual values supplied in the visit schedule list.


{pstd}
* assuming allocation ratio is (1 1), otherwise covariance matrix is calculated for a N1+N2 person trial, where N1 and N2 are
the integers specified in {opt ara:tio(N1 N2)}. If there is assumed incomplete follow-up then the covariance matrix is further 
adjusted to reflect the proportions of predicted data patterns

{marker options}{...}
{title:Options}

{dlgtab:Required options}
 
{phang} 
{cmd: trtspec(}{it:{help mixedpower##trtspec_type:trtspec_type}}{cmd:)} allows the user to specify different
 parameterisations of the treatment effect. 

{pmore}
{opt slope}
is for a proportionate slope effect implying that the control and treatment group slopes have a common overall intercept.

{pmore}
 {opt intercept} is for 
an intercept effect implying a constant parallel difference between control and treatment groups. 

{pmore}
{opt lateslope #} allows 
for a (delayed) slope effect that does not deviate from the control slope until time #, which need not be a visit time.

{pmore} 
{opt 2slope #} indicates two separate slope terms with changepoint at time #, which need not be a visit time. 
# must be the same value as for {opt altcont(2slope #)}
if that control parameterisation is also selected. Also note that it has been parameterised so that the 2nd slope treatment 
effect is directly identified by the regression parameter, whereas for the first slope the 
effect must be found by a linear combination - see {opt lct:est()}.

{pmore} 
{opt slint} is for the situation when there is an initial intercept difference at baseline and 
a subsequent additional slope effect too. A joint test probably makes more sense here than a linear
 combination of slope and intercept, though of course one may simply test either term alone.
 
{pmore} 
 {opt factor} allows for a factorised (or saturated or unstructured) time#treatment effect, so that there
 are arbitrary treatment differences at each timepoint, except that at 'baseline' (actually at first measure, usually
 when time=0), control and treatment means are constrained 
 to be equal. To specify arbitrary differences at all timepoints, including 'baseline' (or rather, first visit), then use {opt factor0}.
 
{pmore}  
 {opt user(f1(t)[;f2(t)])} allows the user to specify their own functions of schedule time as the treatment effect. 
Despite the syntactical description one should use 'x' instead of 't' for time, so that the formulation
 is exactly as if providing the right-hand side function to plot with {help twoway function}. Use of {help cond} is permissible. 
 So, for example {opt slope} could be reproduced with {opt user(x)}, {opt intercept} with
 {opt user(1)}, {opt slint} with {opt user(1; x)} and {opt lateslope 1.5} with {opt user(cond((x-1.5)>0,(x-1.5),0))}.
 Be aware that if a function is unidentified for a {opt sched:ule} time value then
 it will be imputed with 0, which may well be not what is desired. So, for example,
 rather than provide {opt user(ln(x))} for a logarithmic 
 function of time when baseline has {it:t}=0, one could enter {opt user(ln(x+1))}. Note too that 
 if 2 functions are supplied, then power or sample size for 
 a joint test on 2df will automatically be returned.

{phang}
{opth sched:ule(numlist)} specifies the visit times for the proposed trial. A baseline
 visit at time 0 is not assumed and must be given if required. The specific values of {opt sched:ule} can be made to have no
 intrinsic meaning through use of factorised or intercept-only option choices within {opt altc:ont} 
 or {opt trtspec} and a time value-invariant covariance structure. Even so, the supplied number list must always be increasing and
 not negative.
 
{dlgtab:Basic options} 

{phang}
{opt a:lpha(#)} significance level of the test; default is 0.05. Be aware that when you specify {opt a:lpha(0.05)} 
you are in fact obtaining results for a 0.025 one-sided test, unless using the {opt jtt:est(# [# ...])} option or specifically
requesting {opt twos:ided}.

{phang}
{opt twos:ided} request that sample size or power is calculated for a properly two-sided test, including power to detect a difference
in the 'opposite' direction to treatment 'improvement'. This will be denoted in the output with an asterisk next to 'alpha'. 
The default is a one-sided test with type I error of alpha/2. Usually there will be no substantive difference between the two,
 but that difference
will not be trace if alpha is high and/or the effect size is small.

{phang}
{opt pow:er(#)} power; default is 0.8, required to compute sample size. Sample size will be rounded up to nearest even 
number and a similar principle is applied when {opt ara:tio(# #)} is used, see option {opt ara:tio}. Note, the exact 
'fractional' sample size is also returned as a scalar.

{phang}
{opt n(#)} total sample size; required to compute power. If the provided number is odd, the actual sample size used will be 
rounded down to nearest even number. A similar principle is applied when {opt ara:tio(# #)} is used, see option {opt ara:tio}.
 Note, the exact power corresponding to the rounded n, is printed as output with target power returned as a scalar as 
 'fractional' power - corresponding to 'fractional' sample size.

{dlgtab:Other fixed effect options} 

{phang}
{cmd: altcont(}{it:{help mixedpower##altcont_type:altcont_type}}{cmd:)} to specify an alternative parameterisation 
of the control group. The default is to include both
a slope and intercept (which one does not specify), but permissable alternatives are {opt noslope} where the control group is only 
represented by an intercept term, {opt noint} where the control group is only represented by an slope term, 
{opt 2slopes #} where the control group is represented by 2 distinct slopes with a changepoint at # (plus an intercept). 
# must be the same value as for {opt trtspec(2slope #)} if that treatment parameterisation also selected. {opt factor} specifies 
the control group has a term for each value supplied in {opt sched:ule}. {opt user} can be used exactly as in {opt trtspec}, with
up to 2 function of time allowed. However, note that with {opt user} an intercept term is always also included. 

{phang}
{cmd: actualtrt(}{it:{help mixedpower##trtspec_type:trtspec_type}}{cmd:)} to specify the 'correct' treatment effect parameterisation,
 implying that the treatment effect parameterisation provided in 
{opt trtspec} is 'misspecified', and {cmd: mixedpower} is to calculate the power given this 'misspecification'. It should be noted that
power will be a slight approximation here, as the estimate of Var({bf:B_hat}) would, in reality, be altered to some degree in 
the presence of altered fixed effects. Any {it:trtspec_type}
allowed for {opt trtspec} can be allowed for {opt actualtrt}, although it is worth observing that 
whatever the {it:trtspec_type} supplied in {opt actualtrt},
that specific treatment effect could always be replicated through appropriate use of {opt actualtrt(factor0)} as well. 
The number of effect sizes entered in {opt diff:erence} should reflect {opt actualtrt}, not {opt trtspec} (see {opt diff:erence}). 
However, the number of test values entered in {opt lct:est} or {opt jtt:est} should reflect {opt trtspec}, not {opt actualtrt}.
 You can select the same {it:trtspec_type} in both {opt trtspec} and {opt actualtrt}
 though this will of course make no difference to the result, 
 though it will mean a vector matrix of model betas, specified betas and outcomes (mean y_i's)
 will now be returned, which may be useful. The
 'estimated' treatment parameter values that are the consequence of the model 'misspecification' can be found 
 in the returned values as {bf:r(trtbeta_model)}, and together with 'estimated' control parameter values in  {bf:r(betas_model)}.
 
{phang}
{cmd: actualcont(}{it:{help mixedpower##trtspec_type:altcont_type}}{cmd:)} to specify the correct control term parameterisation,
 implying that the model parameterisation of intercept and slope (or overridden using 
{opt altcont}) is 'misspecified', and {cmd: mixedpower} is to calculate the power and model-based parameters given this 
'misspecification'. In terms of power or sample size, control term misspecification makes no difference in most situations,
 particularly if slope and intercept or factorised time is used. Any {it:altcont_type}
allowed for {opt altcont} may be allowed for {opt actualcont}. 

{phang}
{cmd: cbeta(# [# ...])} if choosing {opt actualcont} then one must also provide some assumed parameter values for the
 control terms in the model in order to perform the calculation of model-based beta coefficients, even though in most 
 circumstances it will not make any difference. If {opt actualcont(user(...))} has been selected, then the number of values
 required is 1+number of user-functions, with the first value representing an intercept. 
 When {opt actualcont} is not used then the control parameters do not matter 
 at all and are just given default values of zero when using {opt actualtrt}.

{dlgtab:Effect size and testing options} 

{phang}
{opt diff:erence(# [# ...])} the magnitude of the treatment effect, specified as the value of the relevant regression parameter.
Hence for {opt trtspec(slope)} the value supplied is the absolute change of the treatment group relative to control group per unit time.
 A number is required for each treatment related parameter, see {opt trtspec(trtspec_type)}. So for {opt slope}, {opt intercept} and {opt lateslope} 
 one value is required. For {opt slint} two values are required (intercept, slope). 
{opt 2slopes} also requires two values, 1st slope then 2nd slope. For {opt factor} one 
less the {opt sched:ule} length is required, relating, in order, the individual treatment effect differences from 2nd to final visit. For 
{opt factor0} the number of difference values should match the {opt sched:ule} length from first to final visit, in order. For 
{opt user} supply a difference value for each user-function provided. 
 
{phang}
{opt eff:ectiveness(#)} for the {opt trtspec(slope)} selection only, {it:instead} of using {opt diff:erence} the user may alternatively specify
 the treatment magnitude in proportionate terms relative to the control group slope. The value supplied should be a real
number >0 and <=1. For example, {opt eff:ectiveness(0.3)} 
for a 30% change towards a null slope. This option also requires use of {opt conts:lope} to represent the control group slope the 
effect is relative to. If you wish to specify an effect that i) results in an effect in the opposite 
direction (positive to negative slope or vice-versa) or ii) increase (decreases) further an already positive (negative)
 slope then you will need to use {opt diff:erence}. 

{phang}
{opt conts:lope(#)} this option is to be used in conjunction with {opt eff:ectiveness} and represents the mean control group
 slope that the effectiveness option is relative to, entered as a real number. 
 Not required if {opt diff:erence} used. 
 
{phang}
{opt lct:est(# # ...)} when {opt diff:erence} has more than one value required then one must also indicate how the multiple 
treatment effect parameters will be synthesised into a single test with which to base power or sample size. Hence one must use
either {opt lct:est} or {opt jtt:est}. {opt lct:est} requests a linear combination test of each treatment-based parameter on 1df 
(see {helpb lincom}). {opt trtspec_type} options requiring
{opt lct:est} or {opt jtt:est} are {opt slint}, {opt 2slope #},{opt factor0} and {opt factor} if {opt sched:ule} length is>2. 
The values supplied can
 be any real value and will be the coefficients in the linear combination. 
 Note, the way {opt 2slope #} has been parameterised means
 that if one wishes to specifically test
 the treatment effect on the slope difference before the changepoint, then use {opt lct:est(1 1)} which linearly combines the 2 treatment
 effect estimates. Use {opt lct:est(0 1)} to test the treatment effect after the changepoint.

{phang}
{opt jtte:st(# # ...)} when {opt diff:erence} has more than one value required then one must also indicate how the multiple 
treatment effect parameters will be synthesised into a single test with which to base power or sample size. {opt jtt:est} 
requests a joint test of each treatment-based parameter with df based on number of non-zero entries in
 {opt jtt:est(# # ...)} (see {helpb test}).
One should supply a list of 0s and 1s in order to indicate parameters to include or not. Note, that unlike all
 other default calculations in {cmd:mixedpower}, {opt jtt:est(# # ...)} is
always a two-sided test so includes power to detect non-zero parameter values in either direction. 

{dlgtab:Variance options}

{phang} 
{opth cov:ariance(matrix)} the (second-level) covariance matrix of the random effects. Enter as a 2x2 symmetrical matrix.
 For {opt 2level} enter the random intercept variance in the top left position and the random slope variance in the bottom
 right position, with covariance in the off-diagonal.
 You may either first define a matrix (for example {cmd: matrix} G=(8,1\1,2)) and then insert the matrix name within the option (for 
example {opt cov:ariance(G)}) or instead define the matrix within the option (for example {opt cov:ariance(8,1\1,2)}). 
Inputting 0 for the off-diagonal terms allows the user to specify a random effects model with independent random 
intercepts and slopes, which may not be a sensible choice. A 0 additionally in the bottom right position leads to the random intercept 
model. 

{pmore}
See option {opt auto} for a shortcut to using {opt cov:ariance} and {opt err:orvar} together.

{phang}
{cmdab:error:var(#)} the error variance term, entered as a real number. If you wish to specify non IID errors
across timepoints, then use {opt errxt}, and possibly {opt marginal}. 

{pmore}
See option {opt auto} for a shortcut to using {opt cov:ariance} and {opt err:orvar} together.

{phang}
{opt auto} use of this option will automatically transfer the second-level random effect and error variance values from a suitable 
mixed model in memory, and is an auto-input alternative to using {opt cov:ariance} {it:and} {opt err:orvar}. It is the user's 
responsibility to ensure the model is 'suitable'. To clarify, {opt auto} is used {it:instead} of {opt cov:ariance} and 
{opt error:var}, whereas for options {opt covhet}, {opt errxt} and {opt errhet} one denotes auto-input by selecting the {it:input_type} 
{opt auto} within the option. 

{pmore}
When using {opt auto} {cmd: mixedpower} looks for the parameter 
names _b[lns1_1_1:_cons], _b[lns1_1_2:_cons], _b[atr1_1_1_2:_cons] and _b[lnsig_e:_cons] amongst the returned estimates 
from the mixed model. {opt auto} will accept the returned values from a mixed model with no covariance term between random 
effects or only one random effect. Using the {opt errxt} and {opt errhet} options will override, where relevant, any 
auto-input of the error variance term from using the {opt auto} option. 

{phang}
{cmd: covhet(}{it:{help mixedpower##input_type:input_type}}[({cmd:} {it:{help matrix}}{cmd:)])} to indicate a specific
 alternate random effect covariance matrix for the treatment group. We label this 'heteroschedastic' (similarly for {opt errhet}, 
 as in group-heteroschedastic).
Either select auto-entry version where {it:input_type} is {opt auto} 
from a mixed model in memory, or user-entry 
version where {it:input_type} is {opt input(matrix)}. Rules for user-input entry of the matrix are the same as for {opt cov:ariance},
 and can be
combined with the {opt auto} option for auto-entry of parameters for the control group. In fact, this specific 
combination of input types
is possible whether a standard mixed model with single covariance block has been fitted, or the heteroschedastic version detailed below. 
For the auto-entry version of {opt covhet} the heteroschedastic model in memory must be fitted in a specific manner:

{p 12 16 4}{cmd:. mixed} {it:depvar  fixed_portion}  || {it:id_level2}: 
{it:c.time#0.trt 0.trt},  cov(unstr) nocons || {it:id_level2}: {it:c.time#1.trt 1.trt},  cov(unstr) nocons 

{pmore}
where the covariance structure for each group (control and treatment, in that order) are given their own covariance block in the syntax 
by use of separate double piping. It is crucial to note the order of group-specific random slope before group-specific random intercept 
if wanting to include both, 
plus the use
of option {opt , nocons} in each case. {opt covhet(auto)} will still work with a group-heteroschedastic random intercept model,
or an independent
covariance block for either group. Again mixing of input types is feasible, 
so with {opt covhet(auto)} one can also user-input 
the control group covariance with {opt cov:ariance} or employ option {opt auto} which will auto-input the control group variances from the
first covariance block of the heteroschedastic model to the control group.

{pmore}
The (overall) error term will be auto-inputted with option {opt auto}, unless overridden by use of 
{opt errxt}  - which could also be used to auto-input an alternative error structure from the heteroschedastic mixed model in memory,
or user-entry an alternative error structure not from that model. 
It is recommended requesting the G matrix be returned to check if it matches expectations

{pmore}
See Warnings Section for important information concerning entry and use of {opt covhet}

{phang}
{opt marginal} tells the program not to expect any random effect parameters, i.e. a marginal model. With {opt marginal}
 you need to use {opt errxt} to supply an error structure rather than {opt err:orvar}, even if requesting IID errors. 

{phang}
{marker errxt}{...}
{cmd:errxt(}{it:{help mixedpower##input_type:input_type}}{cmd:[(} {it:{help mixedpower##xterror_type:xterror_type}}{cmd: # ... |mat_name]))} 
to indicate a specific residual error structure across the timepoints of the 
{opt sched:ule} list, instead of assuming IID errors. Either auto-entry version where {it:input_type} is {opt auto} taken 
from a mixed model in memory or user-entry
 version where {it:input_type} is {opt input(xterror_type [# ... |mat_name])}. {it:xterror_type} 
 can be any error structure type allowed by the {cmd:mixed} command (see {helpb mixed##restype:restype}), though note AR and 
 MA error structures are limited to a maximum of order 2.{p_end}
 {p 8 8 2} If choosing {it:input_type} {opt auto} then {it:xterror_type} and its order, if relevant, is automatically
 detected by {cmd:mixedpower} and need not be specified. Note that for {opt unstructured} the number of timepoints in the pre-fitted model
 in memory needs to be at least as long as {opt sched:ule}, but it can be longer. For a heteroschedastic {opt independent} error structure
 use {opt residuals}{bf:(banded 0, t(}{it:time_var}{bf:))} in the fitted model rather than 
 {opt residuals}{bf:(independent, t(}{it:time_var}{bf:) by(}{it:time_var}{bf:))} as this
 particular syntax is saved
 for auto-entry of {opt errhet}.{p_end}
 {p 8 8 2} If choosing the user-{it:input_type} {opt input()} then {it:xterror_type} is entered from the list in 
 {help mixedpower##xterror_type:{bf:xterror_type}}  either with 1 or more real number arguments or a matrix in the case of {opt unstructured}.
 The number of parameter values supplied indicates the order of {it:xterror_type} for those types where
 this is relevant. For example, entering 3 parameter values indicates an AR structure of order 2. In the input instructions below be aware
 that order of inputs is important and are expected in the order they are described:
 
{p2colset 12 34 34 0 }{synopt :{opt ind:ependent # [# ...]}}enter a variance for IID errors; for heteroschedastically distributed errors 
enter a variance for each timepoint of the {opt sched:ule} list{p_end}
{synopt :{opt exc:hangeable # #}}enter a common variance and a common correlation{p_end}
{synopt :{opt ar # # [#]}}enter a variance and the auto-correlation for AR 1; or variance and phi1 and phi2 for AR 2{p_end}
{synopt :{opt ma # # [#]}}enter a variance and theta1 for MA 1; or variance and theta1 and theta2 for MA 2{p_end}
{synopt :{opt un:structured mat_name}}enter name of a symmetric covariance matrix of dimension at least equal to {opt sched:ule} 
length; note direct matrix entry within option not allowed{p_end}
{synopt :{opt ba:nded}}no explicit banded option for {it:input_type} {opt input}; instead use {opt unstructured}, or perhaps
 {opt independent # [# ...]} for {opt banded 0}{p_end}
{synopt :{opt to:eplitz # # [# ...]}}enter a variance and a correlation for each off-diagonal band indicated by Toeplitz order {p_end}
{synopt :{opt exp:onential}}enter a variance and an auto-correlation {p_end}

{pmore}
 Of course all of the above {it:xterror_type}s maybe entered by use of {opt unstructured} with an appropriate matrix. One could obtain such 
 a matrix after a fitted mixed model with {helpb me estat wcorrelation} and using the returned {cmd:r(Cov)} matrix.
 Note that all {it:xterror_type} options 
 may be abbreviated in {cmd:mixedpower}, in identical manner to the {cmd: mixed} command itself. It is recommended requesting
 the R matrix be returned to check if it matches expectations. See Warnings Section for 
important information concerning entry and use of {opt errxt}. 

{phang}
{cmd:errhet(}{it:{help mixedpower##input_type:input_type}}{cmd:[(} {it:{help mixedpower##xterror_type:xterror_type}}{cmd: # ... |mat_name]))}
 to indicate a specific alternate residual error structure for the 
treatment group. With {it:input_type} {opt auto} the model in memory should utilise the syntax 
{opt residuals}{bf:(}{it:xterror_type}{bf:, t(}{it:time_var}{bf:) by(}{it:trtgrp_var}{bf:))}. Like {opt errxt}, the {it: xterror_type}
 can be any error structure type allowed by the {cmd:mixed} command (see {helpb mixed##restype:restype}) 
and entry syntax in {cmd:mixedpower} is identical to the {it:input_type} {opt input} rules for {opt errxt} above.
{opt errhet} may be used additionally to {opt covhet}.

{pmore}
It is recommended requesting the R matrix be returned to check if it matches expectations. See Warnings Section for important 
information concerning entry and use of {opt errhet}. 

{dlgtab:Adjustment options}

{phang}
{opt sca:le(#)} use this option if you wish to specify visit times in a different scale to that relating to the 
inputted random effect (co-)variance parameters. 
For example, if your variance parameter estimates came from a model where time was specified in years,
 but you wished to calculate power for a trial that had a visit schedule specified in months you could use {opt sca:le(`=1/12')}.
 Scale-dependent effect sizes (slope-based) should be kept unchanged in {opt diff:erence} - the fundamental aspects
 (schedule and effect size) are specified in the scale you wish, but variance parameters from a source with a different scale
 are rescaled by {opt sca:le}.
 
{phang}
{opt ara:tio(# #)} specifies relative group sizes (allocation ratio). {opt ara:tio} requires two integers reflecting the control group
 to treatment group allocation ratio. The default is {opt ara:tio(1 1)} i.e equal group size, though there is no limit to the 
 maximum value of either #.
 When calculating required sample size, 
 the smallest n achieving target power is calculated that results in integer group sizes.
 Hence actual power may be slightly more than if 'fractional' 
 subjects were allowed, which could meet target power exactly. When calculating power, the actual sample size used is the largest 
 n <= {opt n(#)} that gives integer group sizes. Hence, actual power may be slightly increased if any 'spare' samples were allocated
 to one of the groups. Note, this rule is always followed, so if {opt ara:tio(3 3)} was chosen, then depending on {opt n(#)}, 
 power could be slightly less than {opt ara:tio(1 1)} even though the allocation ratio itself is equivalent,
 as actual n may need to be smaller to ensure integer group sizes.
 Because you can enter any integer value, {opt ara:tio(# #)} can also be used to accurately calculate power after recruitment is finished, 
 knowing that in fact the allocation was not perfectly balanced. For example, enter {opt ara:tio(152 147)}.
 Note 'fractional' power and 'fractional' sample size
 are also returned in the stored results.
  
{phang}
{opth drop:outs(numlist)} specifies the estimated proportion of dropouts out of the original sample you 
expect following each study visit. It must correspond exactly to the length of the schedule list. 
Each number in the list should be between 0 and 1 and is the proportion who only reached visit {it:k}, and no further, 
due to dropout. To be clear, the proportion is {it:not} out of those remaining at visit {it:k} but of those eligible for full
follow-up. Therefore one does not to consider the impact of {opt strec:uitment} when specifying the dropout list values.
 Furthermore, the sum of all proportions should be equal to one, as it makes no sense to have subjects 
withdraw before the trial begins. There is a built-in tolerance of 0.00001 
to deal with numerical inaccuracies within Stata. 

{phang}
{opth drop2(numlist)} specifies a set of dropout proportions specifically for the treatment group, if it is believed they
will be different from the control. Rules are exactly as for {opt drop:outs}. 

{phang}
{opth strec:ruitment(numlist)} specifies the proportion of the original sample who have only reached as far as visit {it:k}, 
and no further,
due to the effect of staggered recruitment to the trial. Each number in the list should be between 0 and 1 and
 the sum of all proportions should not exceed one. There is a built-in tolerance of 0.00001 
to deal with numerical inaccuracies within Stata. Sums less than one are allowed however, and for staggered recruitment make sense, if one 
wishes to calculate power for an interim stage of a trial with an established final sample size, but at this interim point not everyone 
has yet been recruited. If both {opt strec:ruitment} and {opt drop:outs} are specified then the integrated cohort proportions
 (weights) are also returned in the stored results. Use of companion program {cmd:trialcounts} 
 is recommended as an accessible way to generate appropriate {opt strec:ruitment} proportions.{p_end}
 {p 8 8 2}It is also worth mentioning that 
 {opt strec:ruitment} is more relevant for calculating power rather than sample size, as it reflects recruitment constraints. Used for
 a sample size calculation, it implies that needing a bigger sample can be achieved by simply recruiting more in a given timeframe. If 
 that is not the case, then use {helpb trialcounts} to work with {cmd:mixedpower} to find when a sufficient sample size can be achieved.{p_end}

{dlgtab:Reporting options} 
 
{phang}
{opt nohead:er} prevents display of the {cmd: mixedpower} header banner.

{phang}
{opt nosyn:tax} prevents the default display of the mixed model syntax for the requested model that {cmd:mixedpower} has calculated
 power or sample size for (and not the 'true' model when {opt actualtrt} used). All terms in italics are placeholder names for variables
 names that the user would supply when fitting that model. The syntax given may not be the only way to fit a particular model, but is
a recommended parameterisation when matching with {cmd:mixedpower} and, in particular, for utilising the auto-input methods.

{phang}
{opt notab:le} prevents display of the table of counts by visit, otherwise produced when follow-up is incomplete. 
If either {opt drop:outs} or
 {opt strec:uitment} is supplied indicating that not all subjects have all been recorded for all outcome measures, then a table is 
 produced that lists the (rounded) number of subjects who have been observed for each visit by treatment arm (so different if {opt drop2} or {opt ara:tio} meaningfully supplied). 

{phang}
{opt xmat(#)} returns the X design matrix for a particular 'cohort' identified by visit number # from the schedule list. This is only
possible for cohorts with non-zero probability weightings. This means that if both {opt drop:outs} and {opt strec:ruitment} are not used then
one can only request the X matrix appropriate for the last visit (number #) in {opt sched:ule} where all individuals have a full complement
of measures. Note {bf:r(xmat)} is not automatically returned as there is 1) potential for the matrix to be large and 2) if some visits 
(especially the last one)
not represented it is not obvious for which cohort {opt xmat(#)} should be returned; hence the use of #. When displaying {bf:r(xmat)} there 
are rownames to help identify rows. The tags include 't' for (treatment) group (0 for control, 1 for treatment) and 
'v' for visit (the visit index number in the schedule list).
The columns are not labelled other than X1, X2... but all control term variables come 
before treatment term variable, and
intercepts come before slopes. Factorised terms are in 'time'-order. 
One may use {opt xmat(#)}, {opt rmat(#)}, {opt zmat(#)}, {opt gmat(#)} and {opt bvarn(#)} together
 and # can be different for all options, assuming the selections are individually permissible. Use of {opt xmat(#)} 
also returns a set of expected y outcomes i.e. {bf:X}{bf:B'}. If {opt actualtrt} has been utilised then use of
 {opt xmat(#)} will also return a design X matrix indicating the 'true' fixed portion parameterisation, as well as the modelled one, plus a matrix
 of the model derived set of expected y outcomes.
 
{phang}
{opt rmat(#)} returns the R error matrix for a particular 'cohort' identified by visit number # from the schedule list. All row information
given in {opt xmat} applies here, whereas for column identification, column matches row. Displaying {bf:r(rmat)} may be 
particularly useful when specifying a marginal model with complex error structure to ensure expectations have been met.

{phang}
{opt zmat(#)} returns the Z design matrix of random effects for a particular 'cohort' identified by visit number # 
from the schedule list. All row information
given in {opt xmat} applies here, whereas for column identification, columns represent the random intercept and 
slope - in that order - for the control then treatment group. 

{phang}
{opt gmat(#)} returns the G covariance matrix of random effects for a particular 'cohort' identified by 
visit number # from the schedule list. The matrix {bf:r(gmat)} has no row- or column-name information other than G1, G2.. 
and a covariance-block 
of random effects is given for the control then treatment group.
 Within that covariance-block the random intercept is the first variance term on the diagonal followed by the 
 random slope variance. Displaying {bf:r(gmat)} may be 
particularly useful when specifying heteroschedastic covariance structures to ensure expectations have been met.

{phang}
{opt bvarn(#)} returns the covariance matrix of the estimated fixed parameters calculated for a particular 'cohort' 
identified by visit number # from the schedule list. This is only possible for cohorts with non-zero probability weightings. 
Note that the option {opt bvarn} returns not just matrix {bf:r(bvar_n)}, but also the working correlation matrix {bf:r(wcorr_n)}, the working
covariance matrix {bf:r(sigma_n)} and the implied conditional intra-class correlation coefficient vector {bf:r(cond_icc_n)} if there
are random effects and independent errors. This vector is the ICC given the {opt sched:ule} list. For {bf:r(bvar_n)} there is
no row- or column-name information, but the order of variables is exactly as described in option {opt xmat(#)}.


  {hline}
{marker warnings}{...}
  {title:WARNING SECTION: some important information concerning (co)variance parameter entry and mixedpower}
  {hline}
 
{pstd}
There are a few things worth pointing out regarding the use of mixedpower, some general and some very specific.
 
{pstd}
It is straightforward to fit a mixed model with a particular covariance structure and then subsequently calculate
 power or sample size for that model using {cmd:mixedpower}, especially with the auto-entry methods. In fact, be aware
 it is also quite simple to calculate power or sample size using {cmd:mixedpower} for an unidentifiable mixed model; one
 that could never be fitted. An obvious example would be an unstructured error matrix combined with random effects. 

{pstd}
 It should hopefully go without
 saying that one should not design a trial based on the mixed or marginal model fitted to a representative or pilot dataset 
 that leads to the largest power or smallest sample size for the planned study. 
 Model specification should be based upon what expert opinion considers the most valid or is supported best by the relevant dataset(s). 
 For example, a random intercept model, with parameter inputs taken from a fitted model, may lead to significantly
 higher power compared to a correlated random slopes and intercept model estimated from the same data, purely because the covariance
 structure of the dataset is badly represented by the random intercept model. Implied correlations at later timepoints, for example,
 may be then be greatly understated.
 
{pstd}
The point concerning 'relevant dataset' is highly pertinent. Of course
estimates of power will be misleading if based on a pilot dataset that differs in
 important ways from the planned trial. It will be difficult
 to arrive at suitable variance parameter inputs with such a dataset. The more complicated models
 are really only plausible for {cmd:mixedpower} when that model has been fitted to a well-matched dataset. 
 An unstructured marginal model, for example, would fall into that category in terms of visit schedule.
 However, it may be that one has 
 access to accumulating control arm data of the trial itself and then such calculations might be legitimately
 performed as an improved update. For the heteroschedastic models the idea of an external dataset with useful
 information specifically for a new treatment arm might seem unlikely; but in {cmd:mixedpower} input types can be both, so
 one could auto-input for the control arm directly from a mixed model in memory, and speculate with user-entry variances 
 for the treatment arm that are anticipated to be, say, a specific amount larger due to treatment response variability. 
  
{pstd}
 When using {opt errxt} or {opt errhet} options with user-input entry, pay particular care in how 
 to specify the intended covariance structure. Variances are always required, rather than standard deviations, but correlations are 
 typically required rather than covariances. There are also special parameters required for AR and MA error structures. 
 The theta (MA 1 or 2) and phi (AR 2) terms are those reported from the mixed model output, rather than what is 'ereturned' in e(b).
 The order and number of terms is crucial. 
 
{pstd}
 Be aware of when your schedule list should match that from the assisting dataset when using {opt errxt} or {opt errhet} - 
 most error structures relate to 
 specific time gaps. Note, if the schedule list given in 
 {cmd:mixedpower} has less terms than the fitted model then {cmd:mixedpower} using auto-entry will still work, and will still
 be valid if the schedule list is a subset of the first {it:k} visits. If the schedule list is longer than the fitted model with an
 unstructured or banded error model then
 {cmd:mixedpower} will exit as required variance terms will be missing.
 
{pstd}
 The MA, AR and Toeplitz structures have parameters that reflect a constant time gap (usually of one time-unit). Be aware
 the schedule list should reflect this gap, and that the gap be consistent. Perhaps one may feasibly 
 speculate that an auto-correlation value relates to contiguous visits rather than a specific time-differential. A random slope 
 variance and the exponential model auto-correlation parameter, though time-dependent, accounts for the time value itself so can be 
 safely used with any schedule list.
 The actual {cmd:mixed} command requires that time-gaps for many of the structures be whole units. There is no reason 
 this should be so (it may hard for {cmd:mixed} to otherwise check for equal-sized gaps?)
 and {cmd:mixedpower} can be legitimately used with equal-sized, even if not necessarily integer-sized, gaps for any
 error structure regardless of {opt sched:ule} list. 
 
{pstd}
Finally, be aware that the covariance structure itself can have a significant impact on results. Not just in the obvious sense of greater variability
leading to less power, but also that time-dependent structures may lead to counter-intuitive results. Should this seemingly occur it is
worth re-running {cmd:mixedpower} for a random intercept, or even a marginal independent-errors, regression model to see whether results
 under these simpler structures follow intuitive expecations, and hopefully convince yourself it is the covariance structure itself causing
 the 'anomalous' result. This is also particularly relevant when using {opt actualtrt} and the returned {bf:r(trtbeta_model)} effect size(s)
 appears to make little sense given the inputted 'true' effect size(s) in {opt diff:erence}. See Bamia et al (2013).
 
    {hline}
{marker examples}{...}
  {title:Examples}
    {hline}

{pstd}
{ul:INTRODUCTION TO MIXEDPOWER}{p_end}	
{pstd}
We first load mixedpower_sf36.dta as our reference data to help power our trial. It contains SF-36 scores of health related QOL over 4 annual measures
for a particular population.  Fit a random slopes and intercepts model with {helpb mixed} 
and then use {cmd:mixedpower} to calculate power
 for a 30% reduction in the control slope decline over time, taken from the slope term from the fitted model. Hence we anticipate the treatment effect
 to lessen the QOL decline. We need to specify {opt trtspec(slope)}. Firstly, we use the same schedule
 as the reference data but with a smaller sample size, and then see the increase in power if we add an extra visit{p_end}
{pmore}{bf:{stata `". use mixedpower_sf36, clear"'}}{p_end}
{pmore}{bf:{stata `". mixed sf36 c.visit || id: visit, cov(uns) reml "'}}{p_end}
{pmore}{bf:{stata `". mixedpower , trtspec(slope)  schedule(0 1 2 3) conts(-1.756) eff(0.3) n(500) cov(110.0994,3.401156\3.401156,2.382049) error(13.175) "'}}{p_end}
{pmore}{bf:{stata `". mixedpower , trtspec(slope)  schedule(0 1 2 3 4) conts(-1.756) eff(0.3) n(500) cov(110.0994,3.401156\3.401156,2.382049) error(13.175) "'}}{p_end}

{pstd}
Next is an alternate version where we instead use the more convenient {opt auto} automatic entry for covariance 
and error terms, taken from the 
mixed model in memory. We also use the more general {opt diff:erence} option for specifying the 
effect size;  here
 {opt diff:erence(`=0.3*-1.756')} which equals -0.5268. There is no need to indicate the mean slope of 
 the control group now, and the sign of 
 {opt diff:erence} does not matter either in terms of power. Any slight discrepancy 
 observed in the returned {cmd: r(power)} is due to the greater precision
 of the auto-entry{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope)  schedule(0 1 2 3 4) diff(0.5268) n(500) auto"'}}{p_end}

{pstd} 
Based on the same variance inputs we calculate power for an interim analysis with a more lenient alpha criterion of 20%,
 where the relative proportions reaching up to each
of the visits at this point in the trial are indicated in {opt strec:ruitment}. Note, the sum is less than 1 and
we do not alter {opt n(#)}. If we upscaled the weights to sum to 1, then we would need to appropriately downscale {opt n(#)}.
We also believe there will be a dropout pattern
as reflected in {opt drop:outs}. Both factors will be incorporated into the calculation, and the rounded trial numbers reaching
each visit is now outputted automatically, unless suppressed with {opt notab:le}.{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope)  schedule(0 1 2 3 4) diff(0.5268) n(500) auto alpha(0.2) strec(0.05 0.1 0.15 0.2 0.4) drop(0.1 0.05 0.05 0.05 0.75)"'}}{p_end}

{pstd} 
We now fit a model with random intercepts only, and calculate power for that model. 
Estimated power is apparently much increased but the random intercept model is not appropriate as it does 
not explain error structure over time sufficiently.
We then replicate the result with the equivalent exchangeable marginal model. Auto-input is by the 
{it: input_type} {opt auto} within {opt errxt}, rather than standalone option {opt auto}, which substitutes both the random effect 
covariance input ({opt cov:ariance}) and IID errors {opt error:var} together. {p_end}
{pmore}{bf:{stata `". mixed sf36 c.visit || id: ,  reml "'}}{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope)  schedule(0 1 2 3 4) diff(0.5268) n(500) auto alpha(0.2) strec(0.05 0.1 0.15 0.2 0.4) drop(0.1 0.05 0.05 0.05 0.75)"'}}{p_end}
{pmore}{bf:{stata `". mixed sf36 c.visit || id: , nocons resid(exch, t(visit))  reml "'}}{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope)  schedule(0 1 2 3 4) diff(0.5268) n(500)  marginal errxt(auto) alpha(0.2) strec(0.05 0.1 0.15 0.2 0.4) drop(0.1 0.05 0.05 0.05 0.75)"'}}{p_end} 

{pstd}
{ul:COMPLEX COVARIANCE AND ERROR STRUCTURE}{p_end}

{pstd} 
In this tour of marginal and other complex models we load Stata's pig dataset, and create a
 fake treatment group, as well as set week to starting at time zero. First up we fit an AR(2) 
model and calculate power based on the results with auto-entry. We use just the first 5 measures (if week=<4), and also replicate the result with an input-entry version{p_end}
{pmore}{bf:{stata `". webuse pig , clear"'}} {p_end}
{pmore}{bf:{stata `". gen trt=id>=25"'}} {p_end}
{pmore}{bf:{stata `". replace week=week-1"'}} {p_end}
{pmore}{bf:{stata `". mixed weight c.week c.week#1.trt if week<=4 || id: ,nocons resid(ar 2, t(week)) reml"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0 1 2 3 4) diff(0.5) alpha(0.05) n(100) marginal errxt(auto) rmat(5)"'}}{p_end}
{pmore}{bf:{stata `". mat li r(rmat)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0 1 2 3 4) diff(0.5) alpha(0.05) n(100) marginal errxt(input(ar 13.29269 1.009429 -.0943944)) rmat(5)"'}}{p_end}
{pmore}{bf:{stata `". mat li r(rmat)"'}} {p_end}

{pstd} 
Calculating power assuming a Toeplitz(3) model{p_end}
{pmore}{bf:{stata `". mixed weight c.week c.week#1.trt if week<=4 || id: ,nocons resid(toep 3, t(week)) reml"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0 1 2 3 4) diff(0.5) alpha(0.05) n(100) marginal errxt(auto)"'}} {p_end}

{pstd} 
Calculating power assuming an unstructured marginal model, sometimes known as a mixed model 
for repeated measures (MMRM), where user-entry of the unstructured covariance matrix 
is again best avoided!{p_end}
{pmore}{bf:{stata `". mixed weight i.week i.week#1.trt if week<=4 || id: ,nocons resid(unstr, t(week)) reml"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor) sched(0 1 2 3 4) diff(0.5(0.5)2) lctest(0 0 0 1) n(100) marginal errxt(auto) rmat(5)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(rmat)"'}} {p_end}

{pstd} 
In this example we assumed a random slopes and intercepts model but also assume the residual errors have an AR(1)
 structure. The dataset now uses 7 weeks of data, to help with convergence for the following examples,
 but the planned trial is still 5 timepoints.
 The {opt marginal} option needs to be taken out of the {cmd:mixedpower} command{p_end}
{pmore}{bf:{stata `". mixed weight c.week c.week#1.trt if week<=6 || id: week , cov(unstr) resid(ar 1, t(week)) reml"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0 1 2 3 4) diff(0.5) alpha(0.05) n(100) auto errxt(auto)"'}} {p_end}

{pstd} 
This time we assume a separate random slopes and intercepts model for both control and treatment groups. 
For auto-entry the mixed model itself needs to be carefully specified with a particular syntax. 
It is recommended the G matrix is checked that expecations have been achieved{p_end}
{pmore}{bf:{stata `". mixed weight c.week c.week#1.trt if week<=6 || id: c.week#0.trt 0.trt , cov(uns) nocons || id: c.week#1.trt 1.trt, cov(uns) nocons reml"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0 1 2 3 4) diff(0.5) alpha(0.05) n(100) auto covhet(auto) gmat(5)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(gmat)"'}} {p_end}

{pstd} 
We can use {opt errhet} to specify group-heteroschedastic errors. 
If requesting complex residual error structure for both groups, it is more likely a {opt mixed} model will converge
in the marginal set-up with no random effects, than with random effects included as well.
 But all possibilities can be integrated  with {cmd:mixedpower}, and {it:input_type} may be different for each selection of 
 {opt errxt}, {opt covhet} and {opt errhet}{p_end}
{pmore}{bf:{stata `". mixed weight c.week c.week#1.trt if week<=6 || id: , nocons resid(ma 2, t(week) by(trt)) reml"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)4) diff(0.5) alpha(0.05) n(100) marginal errxt(auto) errhet(auto)  rmat(5)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(rmat)"'}} {p_end}
{pmore}{bf:{stata `". mixed weight c.week c.week#1.trt if week<=6 || id: week, cov(unst) reml resid(ma 2, t(week) by(trt))"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)4) diff(0.5) alpha(0.05) n(100) auto errxt(auto) errhet(input(ma  1.38757 .4185434  -.0162743))  rmat(5) gmat(5)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(rmat)"'}} {p_end}
{pmore}{bf:{stata `". mixed weight c.week c.week#1.trt if week<=6 || id: c.week#0.trt 0.trt , cov(uns) nocons || id: c.week#1.trt 1.trt, cov(uns) nocons reml resid(ma 2 , t(week) by(trt))"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)4) diff(0.5) alpha(0.05) n(100) auto covhet(auto) errxt(auto) errhet(input(ma 1.466888 .4507447 .0211286))  rmat(5) gmat(5)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(rmat)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(gmat)"'}} {p_end}

{pstd}
{ul:GENERALISABILITY OF MIXEDPOWER}{p_end}

{pstd}
Here we consider the generalisability of {cmd:mixedpower} by using it to calculate a 2-sample z-test and comparing 
results with the official Stata command. {p_end}

{pstd}
Firstly, select option {opt marginal} with IID errors.
For both groups we need an intercept term as we are just comparing means and do this with {opt trtspec(intercept)} 
and {opt altcont(noslope)}. Although {cmd:mixedpower} insists on at least 2 entries in the {opt sched:ule} list,
 we can use a work-around with option {opt drop:outs} (or {opt strec:ruitment}). We simply put all our probability 
 weighting into the first baseline visit.{p_end} 
{pstd}
 An alternative would be to halve the given sample size and because of the IID errors (and no random effect)
 the two measures are unrelated (i.e. now represent 2 individuals each). The two measures also have no temporal meaning as 
 both groups are represented simply by intercept terms. For the heteroschedastic example we also specify an allocation ratio
 of 1 control subjects to 2 treatment subjects.{p_end}
{pmore}{bf:{stata `". power twomeans 1 1.5, sd1(2) sd2(2) knownsds n(600) onesided alpha(0.025)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, schedule(0 1) trtspec(intercept) altcont(noslope) difference(0.5) marginal errxt(input(independent 4)) n(600) dropout(1 0) notable"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, schedule(0 1) trtspec(intercept) altcont(noslope) difference(0.5) marginal errxt(input(independent 4)) n(300)"'}} {p_end}

{pmore}{bf:{stata `". power twomeans 1 1.5, sd1(2) sd2(3) knownsds n(600) onesided alpha(0.025) nrat(2)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, schedule(0 1) trtspec(intercept) altcont(noslope) difference(0.5) marginal errxt(input(independent 4)) errhet(input(independent 9)) n(600) aratio(1 2) dropout(1 0) notable"'}} {p_end}

{pstd}
For the next example exploring the capabilities of {cmd:mixedpower}, we calculate the sample size for a cluster-randomised
 trial with required power of 90%.
A common approach is to multiply the sample size esimtated for independent samples with a 'design effect' (DE) factor, based on an
estimate of the intra-class correlation coefficient within a cluster, here=0.1. However, Stata does have a CRD specific option for their 
{helpb power twomeans} command. Each cluster is assumed to be 25 sub-units in size, and we assert there should double the number of treatment clusters.
We are also assuming that each within-cluster unit is assessed
with, say, a single final-baseline difference measure. If the within-cluster unit itself has properly repeated measures data, 
then a 3-level model is 
needed. To calculate the sample size in {cmd:mixedpower} we again specify {opt trtspec(intercept)} and {opt altcont(noslope)}, and 
indicate an exchangeable error structure with ICC=0.1.{p_end}

{pstd}
Both commands tell us we need 54 control and 108 treatment clusters each of size 25.{p_end}
{pmore}{bf:{stata `". power twomeans 0 0.4, power(0.9)  m1(25) m2(25) sd(2) rho(0.1) kratio(2)"'}}{p_end}
{pmore}{bf:{stata `". mixedpower, schedule(1(1)25) trtspec(intercept) altcont(noslope) difference(0.4) marginal errxt(input(exchangeable 4 0.1)) power(0.9)  arat(1 2)"'}} {p_end}

{pstd}
However, with {cmd:mixedpower} we could also calculate sample size for different specific cluster sizes using
option {opt drop:outs} (or {opt strec:ruitment}). 
The piece of code without a hyperlink will create a {opt drop:out} list (recreated by the local macro line)
 indicating that 25% of clusters
will be of size 10, 25% of size 15, 25% of size 20 and 25% of size 25. With this example, we now need
186 total clusters (62 control and 124 treatment), a quarter of each are sized 10, 15, 20 and 25. 
Note too, that the {opt drop2} option could be used to indicate different sized 
clusters between control and treatment.{p_end}
{pmore}{cmd: . forvalues n=1/25 {c -(}}{p_end}
{pmore}{cmd: . 	    	local prob=0}{p_end}
{pmore}{cmd: . 			if mod(`n',5)==0 & `n'>=10 local prob=0.25}{p_end}
{pmore}{cmd: . 			local dlist "`dlist' `prob'"}{p_end}
{pmore}{cmd: . {c )-}}{p_end}
{pmore}{bf:{stata `". local dlist="0 0 0 0 0 0 0 0 0 .25 0 0 0 0 .25 0 0 0 0 .25 0 0 0 0 .25""'}} {p_end}
{pmore}{bf:{stata `". mixedpower, schedule(1(1)25) trtspec(intercept) altcont(noslope) difference(0.4) marginal errxt(input(exchangeable 4 0.1)) power(0.9) dropout(`dlist')  arat(1 2)"'}} {p_end}


{pstd}
{ul:FITTING A SLOPE TERM VERSUS ALTERNATIVE OPTIONS}{p_end}

{pstd}
A single slope parameter is a statistically efficient way of modelling a treatment effect over time with the constraint that the mean 
response for each group is equal at baseline. Here we compare a slope-based model with the common baseline-final measure approach, as well as a
treatment effect that has been factorised by visit time, which may be suitable if one doesn't wish to constrain the nature of the treatment effect.

{pstd}
Firstly we look at a slope effect in a 3 year trial with 6-monthly visits, and made-up variances. Next
we consider just the baseline and final measure and see power is reduced by about 9% - not a huge amount. One
can use {opt trtspec(factor)} with {opt diff:erence(1.2)} or {opt trtspec(slope)} with {opt diff:erence(0.4)}. {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(0.5)3) diff(0.4) cov(15, 1\1, 1.5) error(12)  n(600)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor) sched(0 3) diff(1.2) cov(15, 1\ 1, 1.5) error(12) n(600) lctest(1)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0 3) diff(0.4) cov(15, 1\ 1, 1.5) error(12)  n(600)"'}} {p_end}

{pstd}
We then compare the above with modelling all the data but still only effectively looking
 at the difference between first and last visit. This roughly splits the power here, of the first
 2 approaches. If instead we modelled all the visit data 
and performed a linear combination test of all the treatment effect pieces, still assuming an underlying 
proportionate slope effect, this would be inefficient as 6 variances (plus covariances) are also added together, so the first few
(small) effect sizes help worsen power. Alternately, one can try a compromise and test 
a linear combination of, say, the last two effects plus half the third last effect (just to reinforce that {it:any} linear combination
is allowable) if one was more confident of later treatment effect differences. This result approaches the performance
 of the slope-based model.{p_end}
{pmore}{bf:{stata `". mixedpower , trtspec(factor) sched(0(0.5)3) diff(0.2(0.2)1.2) cov(15, 1\ 1, 1.5) error(12) n(600) lctest(0 0 0 0 0 1)"'}}{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor) sched(0(0.5)3) diff(0.2(0.2)1.2) cov(15, 1\ 1, 1.5) error(12) n(600)  lctest(1 1 1 1 1 1)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower , trtspec(factor) sched(0(0.5)3) diff(0.2(0.2)1.2) cov(15, 1\ 1, 1.5) error(12) n(600) lctest(0 0 0 0.5 1 1)"'}}{p_end}

{pstd}
In the prior examples it might seem that there was only moderate gain to having 7 visits instead of just baseline and a final
visit. However in a real trial there will be dropout, and if it is an interim analysis there will only be partial realisation
of data (hence {opt strec:ruitment}). If we mix in some missing data (through either 'mechanism'), the differences become more
 pronounced as of course 'first and last', in particular, suffers with only 35% of all subjects here contributing any meaningful data. 
 Baseline-only data contains no information regarding slopes, although it does for intercept defined treatment effects.{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(0.5)3) diff(0.4) cov(15, 1\1, 1.5) error(12) n(600) dropout(0.1 0.1 0.1 0.1 0.1 0.15 0.35)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor) sched(0 3) diff(1.2) cov(15, 1\1, 1.5) error(12) n(600) lctest(1) dropout(0.65 0.35)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor)  sched(0(0.5)3) diff(0.2(0.2)1.2) cov(15, 1\1, 1.5) error(12) n(600) lctest(0 0 0 0 0 1) dropout(0.1 0.1 0.1 0.1 0.1 0.15 0.35)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor)  sched(0(0.5)3) diff(0.2(0.2)1.2) cov(15, 1\1, 1.5) error(12) n(600) lctest(0 0 0 0.5 1 1) dropout(0.1 0.1 0.1 0.1 0.1 0.15 0.35)"'}} {p_end}

{pstd}
{ul:TREATMENT EFFECT MISSPECIFICATION}{p_end}

{pstd}
The previous section introduced the idea of uncertainty over the specific form of the treatment effect. 
The very last example showed that power was
almost as high when selecting some time-specific late effects only, as the slope-based version assuming a constant proportionate
effect. With use of the {opt actualtrt} option we can actively explore the consequences for power (and bias) when fitting a
misspecified model. If we fit a correctly specified slope-based model to start with, 
we see there is almost 75% power to detect that slope, 
and we get the same answer in the trivial example where we state the 'actual' treatment effect is also that same slope, though stated as
as set of individual time difference effects. However, if we
think at year 4 the effect will have plateaued (as denoted in {opt diff:erence}) we find that power has fallen quite sharply. The power 
for a slope-based model greatly depends on the final effect difference. We can see how much less than 0.5 the modelled slope
effect would be under the misspecified model using {bf:r(trtbeta_model)}. Assuming that plateau effect, we can actually do better with our
late-effects linear combination test. We also take this opportunity to show it is inefficient to include a treatment term at baseline 
when it is not needed {opt trtspec(factor0)}, even if we do not include it in the {opt lct:est} list. The last 2 examples show we can 
also combine the misspecification feature of {cmd:mixedpower} with partial samples.
 Here the slope-based model does better as the influence of the misspecification (the plateau) is downweighted as only a fifth
of subjects have reached the 5th visit.{p_end} 
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)4) diff(0.5) cov(20, 2\2, 4) error(15) n(600)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)4) diff(0 0.5 1 1.5 2) cov(20, 2\2, 4) error(15) n(600) actualtrt(factor0)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)4) diff(0 0.5 1 1.5 1.5) cov(20, 2\2, 4) error(15) n(600) actualtrt(factor0)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(trtbeta_model)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor)  sched(0(1)4) diff(0.5 1 1.5 1.5) cov(20, 2\2, 4) error(15) n(600)  lctest(0 1 1 1)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor0)  sched(0(1)4) diff(0 0.5 1 1.5 1.5) cov(20, 2\2, 4) error(15) n(600)  lctest(0 0 1 1 1)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)4) diff(0 0.5 1 1.5 1.5) cov(20, 2\2, 4) error(15) n(600) actualtrt(factor0) strec(0.2 0.2 0.2 0.2 0.2)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(trtbeta_model)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor)  sched(0(1)4) diff(0.5 1 1.5 1.5) cov(20, 2\2, 4) error(15) n(600)  lctest(0 1 1 1) strec(0.2 0.2 0.2 0.2 0.2)"'}} {p_end}

{pstd}
{ul:TREATMENT EFFECT MISSPECIFICATION AND USE OF THE USER-DEFINED FUNCTIONS}{p_end}

{pstd}
Here we explore the ability to define our own functions of time with the {opt user()} sub-options, combined with treatment effect misspecification.
Specifically we take examples from a paper by Morgan et al (2023) that used simualation to look at the effect on power and other trial operating 
characteristics when actual non-linear effects were modelled with a proportionate slope effect. It should be stressed that results might not directly
correspond as they introduce an additional layer of uncertainty whereby an initial observational study used for the variance inputs 
is itself repeatedly simulated with non-linear trajectories, but modelled as linear. 
And as mentioned under {opt actualtrt()} the estimate of Var({bf:B_hat}) will not be unchanged if the fixed
effect components differ in functional form. One set of their examples has an error variance of 0.15 and random effects covarariance matrix 
(0.5, .0354\.0354, 0.01). With an annual visit schedule out to 5 years we look at examples where the control group has
a range of non-linear trajectories and the treatment effect is proportional to the function of time, 
rather than to time itself. In all examples the functions
are defined so that both arms start baseline with a mean value of 6, and the control arm reaches 7 at year 5 with the treatment 
reaching 6.75, given the treatment difference of 0.05. This can be
checked in each case by the returned {cmd: r(exp_y_true)}. We are also interested in the modelled treatment effect {cmd: r(trtbeta_model)}
 to assess bias when assuming a proportionate slope effect.{p_end}
	
{pstd}
If the true treatment effect was a proportionate slope then the required sample size would be 230  if power is set at 0.8, 
regardless of the control arm trajectory, assuming a slope and intercept (or factorised time) is used. 
This matches the result from the paper. To obtain similar power values under the particular 'misspecifications' to Figure 8 in the paper, 
 we now replace {opt pow:er(0.8)} with {opt n(230)}.
The first example here is actually for a 'steady decline' meaning the control does have a linear slope, 
but for the treatment effect the authors instead posit a 
'delayed decline'. Power is has been reduced to 0.56 because the treatment effect is now estimated to be -0.038. The estimated treatment effects
in Figure 8 can be reproduced by multiplying our estimate by 5 (years).{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)5) diff(-0.2 -0.25) cov(0.5, .0354\.0354, 0.01) error(0.15)  n(230) actualcont(user(x)) cbeta(6 0.2) actualtrt(user(cond(x<=1.25,x,0);cond(x<=1.25,0,1)))"'}} {p_end}
{pmore}{bf:{stata `". mat li r(exp_y_true)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(trtbeta_model)"'}} {p_end}
{pstd}
The second example is for an 'early decline' with a long plateau from about year to the end 2. The power is similar
at 0.53 because the estimated treatment slope effect is -0.036.{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)5) diff(-0.05) cov(0.5, .0354\.0354, 0.01) error(0.15) n(230) actualcont(user(-5*exp(-2*x)+5)) cbeta(6 0.2) actualtrt(user(-5*exp(-2*x)+5))"'}} {p_end}
{pmore}{bf:{stata `". mat li r(exp_y_true)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(trtbeta_model)"'}} {p_end}
{pstd}
The third example is for a 'late decline' with a long initial plateau from baseline to about year 3. Similarly to the 'early decline' power is 
significantly less than under a scenario with a genuine proportionate slope effect, due to a downwardly biased treatment effect.{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)5) diff(-0.05) cov(0.5, .0354\.0354, 0.01) error(0.15) n(230) actualcont(user(1/4400*exp(2*x))) cbeta(6 0.2) actualtrt(user(1/4400*exp(2*x)))"'}} {p_end}
{pmore}{bf:{stata `". mat li r(exp_y_true)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(trtbeta_model)"'}} {p_end}
{pstd}
The fourth example is for an 'intermediate decline' with a rapid decline during the middle period. In contrast to the prior examples, 
the estimated power has been increased to 0.93 due to an upward bias of the treatment effect=-0.062. If we add the option {opt xmat(6)}, 
the 6 referring to the 6th visit at time=5, then we may also return the modelled mean y values.{p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0(1)5) diff(-0.05) cov(0.5,.0354\.0354,0.01) error(0.15) n(230) actualcont(user(-5/(1+exp(-3*(2.5-x)))+5)) cbeta(6 0.2) actualtrt(user(-5/(1+exp(-3*(2.5-x)))+5)) xmat(6)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(exp_y_true)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(exp_y_model)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(trtbeta_model)"'}} {p_end}


{pstd}
{ul:WORKING WITH TRIALCOUNTS FOR SPECIFYING COHORT PROBABILITY WEIGHTS}{p_end}

{pstd}
In this section we show how companion program {helpb trialcounts} may be integrated with {cmd:mixedpower} to enable easy specification
of {opt drop:outs} or {opt strec:uitment} (or both) weights. We return to a simple example with a slope-based model where we aim to 
recruit 600 subjects in total. We can use {cmd:trialcounts} to identify an increasing recruitment function based on an anticipated series of piecewise
linear functions with options {opt rates(40(10)120)} and {opt ends(0.5(0.5)4 15)}, and then evaluate that function at trial time=5
 to establish how much outcome data we have, and hence the power at this interim point. The final value in {opt ends} is an arbitrarily large
 value of 15 ensuring the overall recruitment
 function will reach 600, whilst the {opt maxn(600)} means the recruitment function is then capped at 600.
 The schedule list in {cmd:trialcounts} should match that  used in {cmd:mixedpower}. The table of output gives the numbers who 
 have reached each visit, both in total and for those who have only 
 reached that visit, and no further. For the purposes of {cmd:mixedpower}, however, we require the probability weights. 
 By evaluating the returned macro {cmd:r(final_wgts)} in the {opt strec:uitment} option we can simply transfer those weights into the {cmd:mixedpower}
 command for seamless .do file use. As this is an interim analysis the alpha criterion is greatly relaxed.
 Because the {cmd:r(final_wgts)} do not sum to 1, we cannot alternatively enter them in {opt drop:out}. 
 However, we could enter the upscaled weights {cmd:r(fw_rescale)} in either {opt drop:outs} or {opt strec:uitment}
 and then equivalently downscale the sample size i.e. use the reported 420
 that have been recruited by year 5 to replicate the same result.{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0/4) ends(0.5(0.5)4 15) rates(40(10)120) maxn(600) time(5) disp2 rgr"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0/4) diff(1) cov(20, 2\2, 4) error(15) alpha(0.2) n(600) strec(`=r(final_wgts)')"'}} {p_end}

{pstd}
If we wish to incorporate dropout too, {cmd: trialcounts} provides an easy way to indentify a set of plausible cohort weights with parametric
survival dropout functions. We continue the example, by also suggesting a log logistic droput function where the hazard is increasing ({opt p(0.6)})
and the probability of still being in the study at the final visit is 0.7 ({opt s(0.7)}). Instead of evaluating these functions 
at time=5 we use the {opt search} option
and look to calculate power at the point in the trial when 50 subjects have reached the 5th visit, at year 4.{p_end}
{pmore}{bf:{stata `". trialcounts, sched(0/4) ends(0.5(0.5)4 15) rates(40(10)120) maxn(600) search(50 5) time(5(0.01)6) drf(loglog, s(0.7) p(0.6)) dgr"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(slope) sched(0/4) diff(1) cov(20, 2\2, 4) error(15) alpha(0.2) n(600) strec(`=r(final_wgts)')"'}} {p_end}


{pstd}
{ul:CODA}{p_end}

{pstd}
Finally we invent a trial combining a few of the features of {cmd:mixedpower}. It is a two-way factor trial; the first factor
 involving subjects is random, whilst the second factor involving four 'methods' is fixed and is measured on each subject.
 We expect the four methods to vary in both
 mean treatment response (given in {opt diff:erence}) and in variances, but the primary analyis model is to average over method and fit a
 single treatment term. Despite the difference in variance we also believe the correlation across all methods (within subjects) is constant
 and equal to 0.6. Because we have specified {opt trtspec(intercept)} for the treatment effect and {opt altcont(factor)} for the control
 group, the values in {opt sched:ule} have no intrinsic meaning. The first commands create a suitable covariance matrix - note how a
 seemingly unstructured covariance matrix is based on
 an underlying correlational structure. Because intermittent dropout is not (yet) allowed in {cmd: mixedpower}
 , missing data for this particular
 example can only be accommodated if the missingness pattern is monotone, and the factors have been ordered appropriately. {p_end}
{pmore}{bf:{stata `". mat corr=(1,0.6, 0.6, 0.6\0.6,1, 0.6, 0.6\0.6, 0.6,1, 0.6\0.6, 0.6, 0.6,1)"'}} {p_end}
{pmore}{bf:{stata `". mat sd=(5, 6, 8, 6.5)"'}} {p_end}
{pmore}{bf:{stata `". mat sddiag=diag(sd)"'}} {p_end}
{pmore}{bf:{stata `". mat covunstr=sddiag'*corr*sddiag"'}} {p_end}
{pmore}{bf:{stata `". mat li covunstr"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(intercept) altcont(factor) sched(1 2 3 4) diff(1.4 0.8 2.2 1) marginal errxt(input(unstructured covunstr)) n(500) actualtrt(factor0)"'}} {p_end}
{pmore}{bf:{stata `". mat li r(trtbeta_model)"'}} {p_end}
{pstd} 
Actually we find we can do better in this example if we first fit a model that estimates the four 'method'#treatment interaction
 effects and then 
test the average of those effects, as that average is 1.35, larger than the 1.11 effect size of before, with a standard error that doesn't
also increase by a similar percent. In fact we can do even better with a joint test on 4df. {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor0) altcont(factor) sched(1 2 3 4) diff(1.4 0.8 2.2 1) marginal errxt(input(unstructured covunstr)) n(500) lctest(0.25 0.25 0.25 0.25)"'}} {p_end}
{pmore}{bf:{stata `". di  r(trt_eff)"'}} {p_end}
{pmore}{bf:{stata `". mixedpower, trtspec(factor0) altcont(factor) sched(1 2 3 4) diff(1.4 0.8 2.2 1) marginal errxt(input(unstructured covunstr)) n(500) jttest(1 1 1 1)"'}} {p_end}

{hline}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mixedpower} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 20 4: Scalars}{p_end}
{synopt:{cmd:r(fractional_ss)}}'fractional' sample size without rounding{p_end}
{synopt:{cmd:r(samplesize)}}calculated or supplied sample size{p_end}
{synopt:{cmd:r(fractional_power)}}power without rounding of supplied sample size{p_end}
{synopt:{cmd:r(power)}}calculated or supplied power{p_end}
{synopt:{cmd:r(effectsize)}}the treatment effect standardised by the variance={bf:r(trt_eff)}/{bf:r(var_trteff)}{p_end}
{synopt:{cmd:r(trt_eff)}}the (summarised) treatment effect, possibly linearly combined from multiple effects{p_end}
{synopt:{cmd:r(var_trteff)}}the variance of {bf:r(trt_eff)} for a (N1+N2)-person trial adjusted for incomplete follow-up{p_end}
{synopt:{cmd:r(se_trial)}}the standard error of {bf:r(trt_eff)} for the trial reflecting final sample size{p_end}
{synopt:{cmd:r(scale)}}scale used{p_end}
{synopt:{cmd:r(alpha)}}type I error rate (significance level){p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 20 4: Macros}{p_end}
{synopt:{cmd:r(cmdline)}}command line{p_end}
{synopt:{cmd:r(cmd)}}command{p_end}
{synopt:{cmd:r(schedule)}}schedule list{p_end}
{synopt:{cmd:r(final_wgts)}}integrated probability weights of dropout and staggered recruitment{p_end}
{synopt:{cmd:r(final_wgts2)}}integrated probability weights for treatment group, if different{p_end}
{synopt:{cmd:r(fw_rescale)}}rescaled integrated weights to sum to 1{p_end}
{synopt:{cmd:r(fw_rescale2)}}rescaled integrated weights for treatment group, if different{p_end}
{synopt:{cmd:r(cont_spec)}}model parameterisation of control group{p_end}
{synopt:{cmd:r(trt_spec)}}model parameterisation of treatment group{p_end}
{synopt:{cmd:r(cont_userfunc)}}model user function of control group{p_end}
{synopt:{cmd:r(trt_userfunc)}}model user function of treatment group{p_end}
{synopt:{cmd:r(cont_true)}}actual parameterisation type of control group{p_end}
{synopt:{cmd:r(trt_true)}}actual parameterisation type of treatment group{p_end}
{synopt:{cmd:r(actcont_userfunc)}}actual user function of control group{p_end}
{synopt:{cmd:r(acttrt_userfunc)}}actual user function of treatment group{p_end}
{synopt:{cmd:r(twosided)}}if calculation based on properly two-sided test or not{p_end}
{synopt:{cmd:r(aratio)}}allocation ratio{p_end}
{synopt:{cmd: r(trialcounts_cmd)}}trialcounts command line, if previous rclass command{p_end}
{synopt:{cmd:r(fr_current)}}current frame at command{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(sched_list)}}schedule list{p_end}
{synopt:{cmd:r(cont_num)}}control numbers reaching each visit{p_end}
{synopt:{cmd:r(trt_num)}}treatment numbers reaching each visit{p_end}
{synopt:{cmd:r(contrd_num)}}rounded control numbers reaching each visit{p_end}
{synopt:{cmd:r(trtrd_num)}}rounded treatment numbers reaching each visit{p_end}
{synopt:{cmd:r(trtbeta_model)}}model derived treatment group beta coefficients{p_end}
{synopt:{cmd:r(trtbeta_true)}}true treatment group beta coefficients{p_end}
{synopt:{cmd:r(betas_model)}}all model derived beta coefficients{p_end}
{synopt:{cmd:r(betas_true)}}all true beta coefficients{p_end}
{synopt:{cmd:r(exp_y_model)}}model derived expected y outcome values, when {opt xmat selected}{p_end}
{synopt:{cmd:r(exp_y_true)}}true expected y outcome values{p_end}
{synopt:{cmd:r(beta_var)}}covariance matrix of fixed effects{p_end}
{synopt:{cmd:r(wcorr_n)}}working correlation matrix if requested, for a given cohort{p_end}
{synopt:{cmd:r(sigma_n)}}working covariance matrix if requested, for a given cohort{p_end}
{synopt:{cmd:r(bvar_n)}}covariance matrix of fixed effects if requested, for a given cohort{p_end}
{synopt:{cmd:r(cond_icc_n)}}implied ICC given schedule list if requested, for a given cohort{p_end}
{synopt:{cmd:r(xmat)}}X matrix if requested, for a given cohort{p_end}
{synopt:{cmd:r(rmat)}}R matrix if requested, for a given cohort{p_end}
{synopt:{cmd:r(zmat)}}Z matrix if requested, for a given cohort{p_end}
{synopt:{cmd:r(gmat)}}G matrix if requested, for a given cohort{p_end}
{synopt:{cmd:r(cohort_wgts)}}integrated probability weights of dropout and staggered recruitment{p_end}
{synopt:{cmd:r(cohort_wgts2)}}integrated probability weights for treatment group, if different{p_end}
{synopt:{cmd:r(st_rec)}}staggered recruitment probability weights{p_end}
{synopt:{cmd:r(dropouts)}}dropout probability weights{p_end}
{synopt:{cmd:r(dropouts2)}}dropout probability weights for treatment group, if different{p_end}



{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Chris Frost, Michael G. Kenward, Nick C. Fox. Optimizing the design of clinical 
trials where the outcome is a rate. Can estimating a baseline rate in a run-in 
period increase efficiency? Statist. Med. 2008; 27:3717–3731 doi: 10.1002/sim.3280

{phang}
Christina Bamia, Ian R. White, Michael G. Kenward. Some consequences of assuming simple
patterns for the treatment effect over time in a linear mixed model. Statist. Med. 2013, 32:2585–259 doi: 10.1002/sim.5707

{phang}
Katy E. Morgan, Ian R. White, Chris Frost. How important is the linearity assumption in a sample size calculation for a randomised
controlled trial where treatment is anticipated to affect a rate of change? BMC Medical Research Methodology (2023) 23:274
https://doi.org/10.1186/s12874-023-02093-2

{marker author}{...}
{title:Author}
Matthew Burnell
MRC Centre of Research Excellence in Clinical Trial Innovation
University College London 
London, UK
m.burnell@ucl.ac.uk


