{smcl}
{* *! version 1.0)}
{hline}
{cmd:help mvmixedpower}
{hline}
{vieweralsosee "[R] mixed" "help mixed"}{...}
{vieweralsosee "mixedpower" "help mvmixedpower"}{...}
{vieweralsosee "dmmixedpower" "help dmmixedpower"}{...}
{vieweralsosee "trialcounts" "help trialcounts"}{...}
{viewerjumpto "Syntax" "mvmixedpower##syntax"}{...}
{viewerjumpto "Menu" "mvmixedpower##menu"}{...}
{viewerjumpto "Description" "mvmixedpower##description"}{...}
{viewerjumpto "Options" "mvmixedpower##options"}{...}
{viewerjumpto "Examples" "mvmixedpower##examples"}{...}
{viewerjumpto "Stored results" "mvmixedpower##results"}{...}
{viewerjumpto "Author" "mvmixedpower##author"}{...}

{title:Title}
{p2colset 5 22 22 2}{...}
{p2col :{hi:mvmixedpower} {hline 2}}{cmd:mvmixedpower} is a program for calculating power or sample size analytically for multivariate 
linear mixed-effects
models, typically for the design of a randomised clinical trial where you wish to consider more than one outcome jointly.{p_end}

{p 4}{...}
See also {helpb mixedpower}, {helpb dmmixedpower}, {helpb trialcounts}
{p2colreset}{...}
	
{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mvmixedpower}
        {cmd:,} 
		{cmd: trtspec(}{it:{help mvmixedpower##trtspec_type:trtspec_type}}{cmd:)}
		{opth sched:ule(numlist)}
		{opt m:ulti(#)}
        [{it:{help mvmixedpower##options_table:options}}]
		
{synoptset 36 tabbed}{...}
{marker options}
{marker options_table}{...}
{synopthdr}
{synoptline}

{p2coldent :* {cmd: trtspec(}{it:{help mvmixedpower##trtspec_type:trtspec_type}}{cmd:)}}specification of treatment effect type, either {opt slope}
or {opt intercept}{p_end}
{p2coldent :* {opth sched:ule(numlist)}}the time values for the visit schedule{p_end}
{p2coldent :* {opt m:ulti(#)}}the number of outcomes {it:m} (dimensions){p_end}
{synopt :{opt a:lpha(#)}}significance level; default is 0.05{p_end}
{synopt :{opt twos:ided}}request a properly two-sided test{p_end}
{synopt :{opt pow:er(#)}}power; default is 0.8, required to compute sample size{p_end}
{synopt :{opt n(#)}}total sample size; required to compute power{p_end}
{synopt :{opt diff:erence(# [# ...])}}1 or {it:m} treatment effect size(s) in model parameter terms - alternative to {opt eff:ectiveness}.{p_end}
{synopt :{opt eff:ectiveness(# [# ...])}}1 or {it:m} treatment effect size(s) for the slope, in 
proportionate terms relative to the control group slope{p_end}
{synopt :{opt conts:lope(# [# ...])}}1 or {it:m} mean control group slope(s) that the effectiveness option is relative to. 
Not required if {opt diff:erence} used{p_end}
{synopt :{opt wei:ghting(# # ...|ivw|nivw)}}the weighting used in a linear combination test of 
each effect size per dimension{p_end}
{synopt :{opth cov:ariance(matrix)}}user input of the random effect covariance matrix{p_end}
{synopt: {cmdab:error:var(}{it:{help matrix}}{cmd:)}}user input of the random error variance{p_end}
{synopt :{opt auto}}alternative specification of covariance and error variance parameters that indicates automatic input of variance estimates from a 
multivariate mixed model in memory{p_end}
{synopt :{opt sca:le(#)}}the ratio of the timescale used for the variance components and the timescale in {opt schedule};
 default is 1{p_end}
{synopt :{opt ara:tio(# #)}}allocation ratio between groups; default is equal allocation (1 1){p_end}
{synopt :{opth drop:outs(numlist)}}the proportion who only reached visit k of {opt schedule}, and no further, due to dropout.
Must sum to 1{p_end}
{synopt :{opth drop2(numlist)}}the dropout proportions in the treatment group, if different.
Must sum to 1{p_end}
{synopt :{opth strec:ruitment(numlist)}}the proportion who only reached visit k of {opt schedule}, and no further, due to staggered recruitment. Need not sum to 1{p_end}
{synopt :{opt nohead:er}}suppress display of {cmd:mvmixedpower} header banner{p_end}
{synopt :{opt nosyn:tax}}suppress display of the mixed model syntax that {cmd:mvmixedpower} is calculating power/sample size for{p_end}
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
{syntab:Currently only slope and intercept terms allowed}
{synopt :{opt slope}}proportionate slope effect i.e. constrained to equal control slope at baseline{p_end}
{synopt :{opt intercept}}intercept effect i.e. parallel shift{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mvmixedpower} performs analytic sample size or power calculations for a proposed RCT using the asymptotic formula for the 
fixed effects variance-covariance matrix of a linear mixed model: Var({bf:B_hat})=({bf:X}'({bf:Sigma}^-1){bf:X})^-1, 
where {bf:Sigma}={bf:R}+{bf:ZGZ}'. The variance-covariance matrix is calculated for a nominal 2-person trial* and includes the 
2-person variance* for the proposed treatment effect parameters per outcome. In {cmd:mvmixedpower} these are then linearly combined
using a weighting scheme of choice, with correct inference based on the relevant variance {it:and} covariance terms from Var({bf:B_hat}). 
The subsequent effect size may then be used in a power/sample size calculation in the conventional
manner, suitably adjusting for the proposed or required sample size.
 Further details can be found in the help file for {helpb mixedpower}. 
Integration with {helpb trialcounts} for dropout and partial follow-up is feasible similarly to {cmd:mixedpower}.
 
{pstd}
* assuming allocation ratio is (1 1), otherwise covariance matrix is calculated for a N1+N2 person trial, where N1 and N2 are
the integers specified in {opt ara:tio(N1 N2)}. If there is assumed incomplete follow-up then the covariance matrix is further 
adjusted to reflect the proportions of predicted data patterns 

{marker options}{...}
{title:Options}

{dlgtab:Required options}
 
{phang} 
{cmd: trtspec(}{it:{help mvmixedpower##trtspec_type:trtspec_type}}{cmd:)} allows the user to specify different
 parameterisations of the treatment effect - currently only a slope or intercept effect allowed. 
 The parameterisation must be the same for all {it:m}
joint outcomes, even if the magnitude of the treatment effects need not be.

{pmore}
{opt slope}
is for a proportionate slope effect implying that the control and treatment group slopes have a common overall intercept.

{pmore}
 {opt intercept} is for 
an intercept effect implying a constant parallel difference between control and treatment groups. 

{phang}
{opth sched:ule(numlist)} specifies the visit times for the proposed trial. A baseline
 visit at time 0 is not assumed and must be given if required. The supplied number list must always be increasing and
 not negative.

{phang} 
{opt multi(#)} the number {it:m} of joint outcomes (dimensions). Must be of at least dimension 2 
 
{dlgtab:Basic options} 

{phang}
{opt a:lpha(#)} significance level of the test; default is 0.05. Be aware that when you specify {opt a:lpha(0.05)} 
you are in fact obtaining results for a 0.025 one-sided test, unless specifically
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
 Note, the exact power corresponding to the rounded n, is printed as output with target power returned as a scalar as 'fractional' power
  - corresponding to 'fractional' sample size.

{dlgtab:Effect size and testing options} 

{phang}
{opt diff:erence(# [# ...])} the magnitude of the {it:m} treatment effects, specified as the values of the relevant regression parameters.
Hence for {opt trtspec(slope)} the value supplied is the absolute change of the treatment group relative to control group per unit time per {it:m}.
One can either give {it:m} treatment differences as a numer list or a single value that applies for all {it:m} outcomes. This may be the 
a reasonable option when all outcomes have been standardised or are naturally commensurate.
 
{phang}
{opt eff:ectiveness(# [# ...])} for the {opt trtspec(slope)} selection only, {it:instead} of using {opt diff:erence} 
the user may alternatively specify
 the treatment magnitudes in proportionate terms relative to the control group slope. 
 Like {opt diff:erence}, one can provide either {it:m} effectiveness
 values. 1 per outcome, or a single value applying to all {it:m} outcomes. The value(s) supplied should be a real
number >0 and <=1. For example, {opt eff:ectiveness(0.3 0.3 0.3)} 
for a 30% change towards a null slope for each outcome. 
This option also requires use of {opt conts:lope} to represent the control group slopes the 
effect is relative to. If you wish to specify an effect that i) results in an effect in the opposite 
direction (positive to negative slope or vice-versa) or ii) increase (decreases) further an already positive (negative)
 slope then you will need to use {opt diff:erence}. 

{phang}
{opt conts:lope(# [# ...])} this option is to be used in conjunction with {opt eff:ectiveness}
 and represents the mean control group
 slopes that the effectiveness option is relative to, entered as real numbers. One may either
provide {it:m} different control slopes  per outcome, or a single control slope to be repeated for all {it:m} outcomes, 
regardless of whether
one or {it:m} values were supplied in {opt eff:ectiveness}.  Not required if {opt diff:erence} used.

{phang}
{opt wei:ghting(# # ...|ivw|nivw)} the weighting used in a linear combination test of each slope or intercept effect per dimension.
 The number of elements of {opt wei:ghting} must be the same as number of dimensions {it:m} entered in option {opt multi}. 
Also allowed are the text entries {it:ivw} indicating inverse-variance weighting and {it:nivw} indicating 'negative' inverse-variance
 weighting. The latter
 is necessary if some of the outcomes trend in opposite directions, meaning the effect sizes will typically be given
with opposite signs in {opt diff:erence} or assumed with {opt eff:ectiveness}. The text selection {it:nivw} acknowledges these
differentially signed effects as all indicating improvement whilst respecting the signs of the off-diagonals in the covariance matrix.{p_end}
 
{dlgtab:Variance options}

{phang} 
{opth cov:ariance(matrix)} the covariance matrix of the random effects, entered as a 2mx2m symmetrical matrix where 
{it: m} is the number of joint outcomes. The  entries are ordered at the highest level by outcome, with intercept and slope variance per 
outcome then entered in 2x2 blocks, with all the other off-diagonal possibly non-zero if desired, to induce correlation between outcomes at the 
random effect level. 

{pmore}
See option {opt auto} for a shortcut to using {opt cov:ariance} and {opt err:orvar} together.

{phang}
{cmdab:error:var(}{it:{help matrix}}{cmd:)} the error variance terms, entered as a {it:m}x{it:m} matrix,
where {it: m} is the number of joint outcomes, and error covariances across outcomes may be non-zero. 

{pmore}
See option {opt auto} for a shortcut to using {opt cov:ariance} and {opt err:orvar} together.

{phang}
{opt auto} use of this option will automatically transfer the random effect and error (co-)variance values from a suitable 
mixed model in memory, and is an auto-input alternative to using {opt cov:ariance} {it:and} {opt err:orvar}. It is the user's 
responsibility to ensure the model is 'suitable'. 

{pmore}
With {cmd:mvmixedpower} the user must be careful how the multivariate mixed model in memory
has been fitted: specifically the {it:m} random intercept terms are all named before the {it:m} random slope terms 
after the first double piping. For example if {it:m}=3: 

{p 12 16 4}{cmd:. mixed} {it:depvar  subscale_1 subscale_2 subscale_3  c.time_1  c.time_2  c.time_3} , nocons || {it:id_level2}: 
{it:subscale_1 subscale_2 subscale_3  time_1 time_2 time_3}, cov(unstr) nocons || {it:visit}: , nocons residuals(unstr, t({it:subscale})) 

{pmore}
then the three {it:subscale_#} terms after the first double piping are the three outcome-specific random intercepts, given before the 3
outcome-specific random coefficients {it:time_#}, along with the {opt , nocons} option.  Note, these variables 
have also been given as fixed effects, again with the {opt , nocons} option. The covariance structure between outcomes can be 
any of those options allowed by {help mixed##vartype:{bf:mixed}} and {opt auto} will enter the 6x6 (in this example)
 covariance matrix of random effects. 
At a lower level of hierarchy within {it:visit}
 the residuals have also been modelled here as unstructured
across the three outcomes and {opt auto} will enter the 3x3 error matrix. The {opt auto} 
option also accepts independent errors but no other residual
 structure allowed by the command {cmd:mixed}.

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
has yet been randomised. If both {opt strec:ruitment} and {opt drop:outs} are specified then the integrated cohort proportions
 (weights) are also returned in the stored results. Use of companion program {helpb trialcounts} 
 is recommended as an accessible way to generate appropriate {opt strec:ruitment} proportions.{p_end}
 {p 8 8 2}It is also worth mentioning that 
 {opt strec:ruitment} is more relevant for calculating power rather than sample size, as it reflects recruitment constraints. Used for
 a sample size calculation, it implies that needing a bigger sample can be achieved by simply recruiting more in a given timeframe. If 
 that is not the case, then use {helpb trialcounts} to work with {cmd:mvmixedpower} to find when a sufficient sample size can be achieved.{p_end}

{dlgtab:Reporting options} 
 
{phang}
{opt nohead:er} prevents display of the {cmd: mvmixedpower} header banner.

{phang}
{opt nosyn:tax} prevents the default display of the mixed model syntax for the requested model that {cmd:mvmixedpower} has calculated
 power or sample size for. All terms in italics are placeholder names for variables
 names that the user would supply when fitting that model. The syntax given may not be the only way to fit a particular model, but is
a recommended parameterisation when matching with {cmd:mvmixedpower} and, in particular, for utilising the auto-input methods.

{phang}
{opt notab:le} prevents display of the table of counts by visit, otherwise produced when follow-up is incomplete. 
If either {opt drop:outs} or
 {opt strec:uitment} is supplied indicating that not all subjects have all been recorded for all outcome measures, then a table is 
 produced that lists the (rounded) number of subjects who have been observed for each visit by treatment arm (so different if {opt drop2} or {opt ara:tio} meaningully supplied). 

{phang}
{opt xmat(#)} returns the X design matrix for a particular 'cohort' identified by visit number # from the schedule list. This is only
possible for cohorts with non-zero probability weightings. This means that if both {opt drop:outs} and {opt strec:ruitment} are not used then
one can only request the X matrix appropriate for the last visit (number #) in {opt sched:ule} where all individuals have a full complement
of measures. Note {bf:r(xmat)} is not automatically returned as there is potential for the matrix to be large. When displaying {bf:r(xmat)} there 
are rownames to help identify rows. The tags include 't' for (treatment) group (0 for control, 1 for treatment), 
'v' for visit (the visit index number in the schedule list) and 'm' for outcome, in order.
The columns are not labelled other than X1, X2... but terms are order at the highest level by
outcome and then within outcome all control term variables come 
before the treatment term variable, and
intercepts come before slopes.  
One may use {opt xmat(#)}, {opt rmat(#)}, {opt zmat(#)}, {opt gmat(#)} and {opt bvarn(#)} together
 and # can be different for all options, assuming the selections are individually permissible.
 
{phang}
{opt rmat(#)} returns the R error matrix for a particular 'cohort' identified by visit number # from the schedule list. All information
given in {opt xmat} applies here, except for column identification, where instead column matches row. Displaying {bf:r(rmat)} may be 
particularly useful to ensure the order of error variances and covariances is correct when applying {opt auto}.

{phang}
{opt zmat(#)} returns the Z design matrix of random effects for a particular 'cohort' identified by visit number # 
from the schedule list. All information
given in {opt xmat} applies here, except for column identification, where instead pairs of 
columns are represent the random intercept and 
slope - in that order - per outcome, firstly for the control and then treatment group. 

{phang}
{opt gmat(#)} returns the G covariance matrix of random effects for a particular 'cohort' identified by 
visit number # from the schedule list. The matrix {bf:r(gmat)} has no row- or column-name information other than G1, G2.. 
and a covariance-block 
of random effects is given for the control then treatment group.
 Within that covariance-block paired random effects are ordered by outcome. For the first outcome pair  
 the random intercept is the first variance term on the diagonal followed by the 
 random slope variance, and similarly for subsequent outcomes. Displaying {bf:r(gmat)} may be 
particularly useful to ensure the order of random effect variances and covariances is correct when applying {opt auto}.

{phang}
{opt bvarn(#)} returns the covariance matrix of the estimated fixed parameters calculated for a particular 'cohort' 
identified by visit number # from the schedule list. This is only possible for cohorts with non-zero probability weightings. 
Note that the option {opt bvarn} returns not just matrix {bf:r(bvar_n)}, but also the working correlation matrix {bf:r(wcorr_n)}, and
 the working
covariance matrix {bf:r(sigma_n)}. For {bf:r(bvar_n)} there is
no row- or column-name information, but the order of variables is exactly as described in option {opt xmat(#)}.


    {hline}
{marker examples}{...}
  {title:Examples}
    {hline}

{pstd} 
An example of {cmd: mvmixedpower} for use with multivariate mixed model taken from a real interim analysis plan for a trial in Parkinson's where the 3 joint
outcomes are Parts I, II and III of the MDS-UPDRS, although we have ignored the incomplete follow-up and higer alpha here.
 This is hard work with user-entry and easy to make a mistake.
The {cmd:mvmixedpower} command calculates power for a common effectiveness of 30% reduction in slope to all 3 control slopes. 
Inverse variance weighting has been used as the linear combination of treatment effects{p_end}
{pmore}{bf:{stata `". mat err=(6.107172,2.194946,2.105618\2.194946,7.459157,5.858216\2.105618,5.858216,41.01714)"'}}{p_end}
{pmore}{bf:{stata `". mat cov=(9.67,0.34,7.01, 0.56,5.23,1.06\0.34,0.63,0.52,0.58,0.3,0.52\7.01,0.52,15.06,0.43,13.62,0.36\0.56,0.58,0.43,1.12,0.16,	1.51\5.23,0.3,13.62,0.16,70.21,-3.01\1.06,0.52,0.36,1.51,-3.01,4.49)"'}}{p_end}
{pmore}{bf:{stata `". mvmixedpower ,  trtspec(slope) sched(0 0.25 0.5(0.5)3) conts(0.865 0.975 1.876) eff(0.3) cov(cov) error(err) m(3) weighting(ivw) n(800)"'}}{p_end}

{pstd} 
It is much quicker and less error-prone to use auto-entry, as done here. Firstly we load a previously saved estimation results file from a
 multivariate mixed model and replay 
the results. The slight discrepancy in power compared to the user-entry version is because it was 
necessary to reduce the precision of the covariance entries for the input version for it to be displayed properly in the help file{p_end}
{pmore}{bf:{stata `". estimates use mvmixed_pd.ster"'}} {p_end}
{pmore}{bf:{stata `". mixed"'}} {p_end}
{pmore}{bf:{stata `". mvmixedpower,  trtspec(slope) sched(0 0.25 0.5(0.5)3) conts(0.865 0.975 1.876) eff(0.3) auto m(3) weighting(ivw) n(800)"'}}{p_end}
		
{pstd}  
We now look at combining {cmd:mvmixedpower} with {helpb trialcounts} with an advanced example.
 We first load a dataset containing recruitment rates for a real MS trial. 
 The variable {bf:recr2} contains the recruitment rate per month for consecutive 2 month intervals
 in the control arm. The first 10 entries are actual monthly rates, 
 with the subsequent 17 entries being 
best estimates into the future. The interim analysis is to be held at 38 months so we really only need to consider the 
first 19 entries. However, for exposition we will include all rows in the file, but use the {opt time} option to limit the calculations 
at month 38. Doing this also allows us to show how one could reduce the number of defined {opt ends} and {opt rates} by using entering the 
number list {opt rates(recr2 1(1)21 27)}, so excluding rows 22-26 as the rates here are identical to 27. In a different example, this may
 reduce the computational burden, especially if combining with {opt search}. We also enter the name of the variable containing the {opt ends}.{p_end}
{pmore}{bf:{stata `". use ms_recruitment, clear"'}}{p_end}

{pstd}
We will run {cmd:trialcounts} with months as the unit of time and the command 
will evalute the supplied recruitment function at 38 months. In addition, we integrate in a Weibull 
dropout function that implies 90% will still be in the trial by the last visit (at 36 months). The variance parameters
for a power calculation are loaded from a
saved multivariate mixed model, which we will auto-input into {cmd:mvmixedpower}. We use the rescaled weights 
from the {cmd:trialcounts} output as the entries in the {opt strec:ruitment} list because we defined a recruitment function that resulted in 
planned sample size greater than the sample size at the time of the interim analysis. By evaluating the local 
rescaled weights macro ({bf:r(fw_rescale)}) returned by {cmd:trialcounts} one can 
enable seamless .do file use. We supply the 3 control slopes from the fitted model into the {opt conts:lope} option, together with a relative 
effect size of 30% improvement for each scale. That is, the 3 slopes are lessened in gradient by 40% towards the null. We wish to combine the 
3 effect sizes with IVW but because the first scale increases with disability progression and the other two decrease, we actually
 indicate the option 
{opt wei:ghting(nivw)} so as to respect the different coefficient signs indicating improvement. As this is an interim analysis looking for 
a signal of IMP activity we tolerate a high (one-sided) alpha in order to maintain high power.{p_end}
{pmore}{bf:{stata `". est use mvmixed_ms.ster"'}} {p_end}
{pmore}{bf:{stata `". mixed"'}} {p_end}
{pmore}{bf:{stata `". trialcounts, sched(0(6)36) ends(month) rates(recr2 1(1)21 27) time(38) drfunction(weibull, p(0.75) s(0.9)) disp2 rgr dgr"'}}{p_end}
{pmore}{bf:{stata `". mvmixedpower, trtspec(slope) sched(0 0.5 1 1.5 2 2.5 3) contslope(.1075532 -.1258883 -.0793978) eff(0.4)  auto multi(3) weighting(nivw) n(686) alpha(0.6) dropout(`= r(fw_rescale)')"'}}{p_end}
	
{pstd}
Note, even though use of {cmd:mvmixedpower} will overwrite the r-class returned list from
 {cmd:trialcounts}, {cmd:mixedpower} 
also returns the (integrated) weightings with the same macro names (either {bf:r(final_wgts)} or {bf:r(fw_rescale)}) so one may
continue entering the same {cmd: mixedpower} command when altering some other parameter of the mixed model. Because the mixed model was fitted in years we will return to years as the time unit for the {opt sched:ule} list and 
{opt diff:erence} effect sizes, which will be linearly combined with equal weighting. Note, we indicate the sample size is 343*2=686 to reflect both groups now.
{p_end}


{hline}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mvmixedpower} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 20 4: Scalars}{p_end}
{synopt:{cmd:r(fractional_ss)}}'fractional' sample size without rounding{p_end}
{synopt:{cmd:r(samplesize)}}calculated or supplied sample size{p_end}
{synopt:{cmd:r(fractional_power)}}power without rounding of supplied sample size{p_end}
{synopt:{cmd:r(power)}}calculated or supplied power{p_end}
{synopt:{cmd:r(effectsize)}}the treatment effect standardised by the variance={bf:r(wgt_trteff)}/{bf:r(var_trteff)}{p_end}
{synopt:{cmd:r(wgt_trteff)}}the overall (weighted) treatment effect, linearly combined from m outcome effects{p_end}
{synopt:{cmd:r(var_trteff)}}the variance of {bf:r(wgt_trteff)} for a (N1+N2)-person trial adjusted for incomplete follow-up{p_end}
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
{synopt:{cmd:r(m_weights)}}weights used for linear combination of {it:m} treatment effects{p_end}
{synopt:{cmd:r(trtbeta_true)}}true treatment group beta coefficients{p_end}
{synopt:{cmd:r(beta_var)}}covariance matrix of fixed effects{p_end}
{synopt:{cmd:r(wcorr_n)}}working correlation matrix if requested, for a given cohort{p_end}
{synopt:{cmd:r(sigma_n)}}working covariance matrix if requested, for a given cohort{p_end}
{synopt:{cmd:r(bvar_n)}}covariance matrix of fixed effects if requested, for a given cohort{p_end}
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


{marker author}{...}
{title:Author}
Matthew Burnell
MRC Centre of Research Excellence in Clinical Trial Innovation
University College London 
London, UK
m.burnell@ucl.ac.uk


