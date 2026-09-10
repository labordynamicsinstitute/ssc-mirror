{smcl}
{* *! version 2.0.0 03sep2026}{...}
{* *! version 1.2.0 02dec2020}{...}
{* *! version 1.1.0 10feb2020}{...}
{* *! version 1.0.0 07jan2020}{...}

{title:Title}

{phang}
{bf:oda} {hline 2} Optimal Discriminant Analysis

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:oda} {it:classvar} {it:attrvar} {ifin}
[{cmd:,} {it:options}]

{pstd}
{it:classvar} is the categorical outcome to be classified (binary or
multi-category); {it:attrvar} is the single predictor attribute (categorical or continuous)

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt cat}}treat {it:attrvar} as categorical: search for the optimal
grouping of its levels instead of a continuous cutpoint{p_end}
{synopt:{opt dir:ection(string)}}constrain the direction of the
classification rule (binary), or pin the full class order (multi-category); "<" or "lt" indicates that the {it:classvar} values 
are ordered in the "less-than" direction. ">" or "gt" 
indicates the {it:classvar} values are ordered in the "greater-than" 
direction. The value list must contain every value of the {it:classvar} currently defined{p_end}
{synopt:{opt deg:en}}allow a degenerate (all-one-class) solution to be
reported as optimal, if it has the best score{p_end}
{synopt:{opt pri:mary(string)}}specify the primary criterion for choosing among multiple optimal solutions.  Options 
are "maxsens", "meansens", "samplerep", "balanced", "distance", "random",
"genmean", "sens #", and "gensens #"; The default is "maxsens" when priors is on, and "meansens" when the {cmd:nopriors} option is specified{p_end}
{synopt:{opt sec:ondary(string)}}specify the secondary criterion for choosing among multiple optimal solutions. 
Options are the same as {cmd:primary()}; The default is "samplerep" {p_end}
{synopt:{opt nopriors}}turn off prior-probability weighting in the search
objective; suitable for matched pairs or equal N's{p_end}

{syntab:Weights and missing data}
{synopt:{opt wt(varname)}}weight variable for use in weighted analyses{p_end}
{synopt:{opt miss:ing(#)}}integer value (positive or negative) indicating missing values; those observations will be excluded from the analysis{p_end}

{syntab:Inference}
{synopt:{opt trainreps(#)}}number of Monte Carlo permutations for the
training-sample significance test{p_end}
{synopt:{opt loo}}perform leave-one-out (jackknife) cross-validation{p_end}
{synopt:{opt looreps(#)}}number of permutations for the LOO significance
test (requires {opt loo}){p_end}
{synopt:{opt sidak(#)}}apply a Sidak multiple-comparison adjustment to the
training-sample p-value (requires {opt trainreps()}){p_end}
{synopt:{opt seed(string)}}set random-number seed to #{p_end}

{syntab:Confidence intervals}
{synopt:{opt ci}}report bootstrap confidence intervals for every
performance measure{p_end}
{synopt:{opt cireps(#)}}number of bootstrap replications for {opt ci};
default 200{p_end}
{synopt:{opt cilevel(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{syntab:Generalizability}
{synopt:{opt gen(varname)}}report a separate performance breakdown for each
distinct value of {it:varname} (a "generalizability" analysis){p_end}

{syntab:Cross-validation}
{synopt:{opt cross(varname [, train# [, hold#]])}}fit one designated
training sample and classify (without refitting) one or more holdout
samples identified by {it:varname}{p_end}

{syntab:Reporting}
{synopt:{opt name(string)}}print {it:string} as a title line ahead of the
results, to help tell multiple runs apart{p_end}
{synopt:{opt store(string)}}save a plain-text copy of everything this
command displays to the file {it:string}{p_end}
{synopt:{opt dots}}show a progress dot for each Monte Carlo/LOO-permutation
iteration{p_end}
{synoptline}
{p2colreset}{...}


{marker postestimation}{...}
{title:Postestimation syntax}

{pstd}
{cmd:oda_predict} is the postestimation companion to {cmd:oda}. It
stores the predicted class value for each selected observation in
{it:newvar}:

{p 8 17 2}
{cmd:oda_predict} {it:newvar} {ifin} [{cmd:,} {opt replace}]

{pstd}
{it:newvar} is the name of the new variable {cmd:oda_predict} creates to
hold the predicted class values.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt replace}}overwrite {it:newvar} if it already exists{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:oda_predict} is available for both in and out of sample.



{marker description}{...}
{title:Description}

{pstd}
Optimal discriminant analysis is a machine learning algorithm that was introduced over 
30 years ago to offer an alternative analytic approach to conventional statistical 
methods commonly used in research (Yarnold & Soltysik 1991). Its appeal lies in its simplicity, 
flexibility and accuracy as compared with conventional statistical methods (Yarnold & Soltysik 2005, 2016).

{pstd}
Given {it:classvar} (2 or more distinct levels) and {it:attrvar}
(continuous, or categorical via {opt cat}), {cmd:oda} performs an
exhaustive search for the cutpoint, the optimal category grouping, 
the optimal ordered segmentation, or the optimal per-category class
assignment that maximizes classification accuracy, and reports overall 
accuracy, PAC (Percent Accuracy in Classification) and PV (Predictive Value)
for every class, and their corresponding Effect Strength (ESS) measures.

{pstd}
{cmd:oda} extends ODA's original functionality in a number of ways -- most notably 
bootstrap confidence intervals and a significance test on the leave-one-out 
table for a multi-category classvar ({opt looreps()}).



{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt cat} tells {cmd:oda} to treat {it:attrvar} as categorical: rather
than searching for a numeric cutpoint, it searches for the optimal
assignment of {it:attrvar}'s distinct levels to predicted classes.

{marker direction}{...}
{phang}
{opt direction(string)} constrains the search. For a {bf:binary}
{it:classvar}, it fixes which class is predicted on the low-attribute-value
side of the cutpoint (accepts {cmd:<}, {cmd:>}, {cmd:lt}, or {cmd:gt}) rather
than letting the search pick freely. For a {bf:multi-category} {it:classvar}
(more than 2 levels) against a {bf:continuous} {it:attrvar}, it instead pins
the full left-to-right class order the segmentation must follow, e.g.
{cmd:direction(< 2 3 1 4 5)} lists every level of {it:classvar} exactly
once, low attribute values to high; {cmd:direction(>)} reverses it. Not
supported together with {opt cat} for a multi-category {it:classvar} -- a
categorical attribute has no ordering for a class sequence to run along.

{phang}
{opt degen} allows a degenerate solution (every observation predicted into
a single class) to be reported if no non-degenerate solution scores as
well. Only meaningful for a binary {it:classvar} against a continuous
{it:attrvar}.

{phang}
{opt primary(string)} and {opt secondary(string)} name a tie-break
criterion for when more than one candidate model achieves the identical
best score. Accepted values: {cmd:maxsens} (the default), {cmd:meansens},
{cmd:genmean}, {cmd:balanced}, {cmd:samplerep}, {cmd:distance},
{cmd:random}, {cmd:sens #}, and {cmd:gensens #}. {cmd:random} instead 
draws uniformly at random among the tied candidates, and is the only 
one of those seven with any effect of its own
in {opt secondary()} beyond {opt primary()}.

{phang2}
{cmd:sens #} maximizes the accuracy of one specific class, {it:#} (a value
of {it:classvar}), among the tied candidates -- unlike every value above,
which all maximize the same aggregate quantity regardless of name. For a
binary {it:classvar} this is genuinely implemented (resolved once, from
{it:#}, to which side of the cutpoint to maximize); for a multi-category
{it:classvar} it is accepted and validated but has no effect beyond
{opt primary()}'s own, matching every other name there.

{phang2}
{cmd:gensens #} requires {opt gen()} to be specified, and {it:#} must be an
observed value of the {opt gen()} variable. Among the tied candidates, it
maximizes that specific {opt gen()} group's own accuracy.

{phang}
{opt secondary()} is only implemented if {opt primary()} still leaves more
than one candidate tied.

{phang}
{opt nopriors} turns off prior-probability weighting: by default the
search objective balances each class's own accuracy equally regardless of
how common that class is in the data (average sensitivity/specificity);
{opt nopriors} instead uses raw, unweighted overall accuracy. This is
the suitable approach for matched pairs or equal N's amongst groups.

{dlgtab:Weights and missing data}

{phang}
{opt wt(varname)} indicates the weight variable for use with weighted analyses. {cmd:wt()} cannot 
be the same variable specified as either the {it:classvar} or {it:attrvar}.

{phang}
{opt missing(#)} excludes all observations from the analysis where {it:classvar}, {it:attrvar},
(and {opt wt()}, when specified) are missing.

{dlgtab:Inference}

{phang}
{opt trainreps(#)} runs a Monte Carlo permutation test on the training-sample
fit: {it:#} times, the class labels are shuffled and the whole search is
rerun, and the reported p-value is the proportion of shuffles whose score
matches or exceeds the observed one.

{phang}
{opt loo} performs leave-one-out cross-validation: each observation is held
out in turn, the model is refit on the remaining observations, and the
held-out observation is classified by that refit model. The pooled
out-of-sample classification table is reported alongside the training-sample
one.

{phang}
{opt looreps(#)} runs an analogous Monte Carlo permutation test on the
leave-one-out table itself (requires {opt loo}), in place of the
default Fisher's exact test for a binary {it:classvar}. Because each of
the {it:#} permutations reruns the entire n-fold leave-one-out
procedure, this is substantially more expensive than {opt trainreps()}.

{phang}
{opt sidak(#)} applies a Sidak correction, 1-(1-p)^{it:#}, to the
{opt trainreps()} p-value (and to the {opt looreps()} p-value, if given).
Requires {opt trainreps()}. When {opt cross()} is also given, {opt sidak(#)}
overrides the cross-sample significance test's own auto-computed Sidak
factor too (see the CROSS() remarks below) -- omit it to keep the sensible
default of 1 + the number of holdout samples.

{phang}
{opt seed(string)} sets the random-number seed #.

{dlgtab:Confidence intervals}

{phang}
{opt ci} reports a bootstrap confidence interval for every training-sample
performance measure (and every leave-one-out measure, if {opt loo} is also
specified), using a resample of the original data drawn with replacement.

{phang}
{opt cireps(#)} sets the number of bootstrap replications for {opt ci};
default 200.

{phang}
{opt cilevel(#)} set confidence level for {opt ci}; default is level(95).

{dlgtab:Generalizability}

{phang}
{opt gen(varname)} indicates a dummy variable indicating two or more independent samples. For a binary classvar, the gen() 
solution is a model which, when independently applied to the indicator groups, maximizes the worst performance 
observed amongst all samples. For a multi-category classvar, gen() does not alter model selection; it reports the 
ordinary (pooled-optimal) model's own performance broken down by each group.

{dlgtab:Cross-validation}

{phang}
{opt cross(varname [, train# [, hold#]])} fits the model using only 
the "training" sample ({it:train#}) identified by {it:varname}, 
then classifies one or more "holdout" samples identified by other 
values of {it:varname}, reporting each one's own performance alongside 
the training-sample results. This reproduces ODA's HOLDOUT mechanism.
{it:hold#} is a numlist of the holdout id(s) to evaluate (e.g.
{cmd:cross(sample, 1, 2 4 6)}). It can be omitted ({cmd:cross(sample, 1)}), 
in which case every OTHER distinct value of {it:varname} present in the 
data becomes a holdout; {it:train#} can also be omitted ({cmd:cross(sample)}), 
in which case the numerically smallest value of {it:varname} present becomes the 
training sample and every other value a holdout. Every observation 
whose {it:varname} is not in the requested train/hold set is excluded. 
{opt trainreps()}, {opt loo}, and {opt looreps()} all run using only 
the training sample's own observations. 

{dlgtab:Reporting}

{phang}
{opt name(string)} prints {it:string} as a title line ahead of the results,
useful for telling apart multiple {cmd:oda} runs in the same log or
do-file.

{phang}
{opt store(string)} additionally saves a plain-text copy of everything this
command displays -- the ODA model table, performance tables, and any
{opt gen()}/{opt ci} sections -- to the file {it:string}.

{phang}
{opt dots} shows progress dots for each iteration of the
Monte Carlo permutation test(s), and for each fold of the leave-one-out
loop.



{title:Examples}

{hline}
{pstd}
{opt (1) Binary classvar and continuous (ordered) attrvar:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}We assess whether oda can distinguish between foreign and domestic
autos based on gas mileage. We perform 1000 permutations and specify that
LOO analysis be conducted{p_end}
{phang2}{cmd:. oda foreign mpg, trainreps(1000) loo}{p_end}

{pstd}Add bootstrap confidence intervals to the same model{p_end}
{phang2}{cmd:. oda foreign mpg, trainreps(1000) loo ci}{p_end}

{hline}
{pstd}
{opt (2) Binary classvar and binary attrvar:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}We first generate a binary variable for mpg using the cutpoint of 22.5
derived in Example 1{p_end}
{phang2}{cmd:. gen binmpg = cond(mpg > 22.5,1,0)}{p_end}

{pstd}We assess whether oda can distinguish between foreign and domestic
autos based on this binary gas mileage variable, treating {cmd:binmpg} as
categorical{p_end}
{phang2}{cmd:. oda foreign binmpg, trainreps(1000) loo cat}{p_end}

{pstd}Add bootstrap confidence intervals to the same model{p_end}
{phang2}{cmd:. oda foreign binmpg, trainreps(1000) loo cat ci}{p_end}

{hline}
{pstd}
{opt (3) Binary classvar and multi-category attrvar:}{p_end}

{pstd}We assess whether oda can distinguish between foreign and domestic
autos based on levels of repair record ratings, treating {cmd:rep78} as
categorical{p_end}
{phang2}{cmd:. oda foreign rep78, trainreps(1000) loo cat}{p_end}

{pstd}Add bootstrap confidence intervals to the same model{p_end}
{phang2}{cmd:. oda foreign rep78, trainreps(1000) loo cat ci}{p_end}

{hline}
{pstd}
{opt (4) Multi-category classvar and continuous attrvar:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}We first recode missing values to -99{p_end}
{phang2}{cmd:. mvencode rep78, mv(-99)}{p_end}

{pstd}We assess whether oda can distinguish between levels of repair
record ratings based on gas mileage. We initially run oda with no
permutations or LOO to identify a model{p_end}
{phang2}{cmd:. oda rep78 mpg}{p_end}

{pstd}Next we specify the directional statement using the class order
derived from the initial model, and add permutations and LOO{p_end}
{phang2}{cmd:. oda rep78 mpg, trainreps(1000) loo direction(< 2 3 1 4 -99 5)}{p_end}

{pstd}Add bootstrap confidence intervals to the same model{p_end}
{phang2}{cmd:. oda rep78 mpg, trainreps(1000) loo direction(< 2 3 1 4 -99 5) ci}{p_end}

{hline}
{pstd}
{opt (5) Multi-category classvar and multi-category attrvar:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}We first ensure that missing values are recoded to -99{p_end}
{phang2}{cmd:. mvencode rep78, mv(-99)}{p_end}

{pstd}Next we create a 3-category variable from mpg{p_end}
{phang2}{cmd:. xtile mpg3 = mpg, nq(3)}{p_end}

{pstd}We assess whether oda can distinguish between 3 levels of gas
mileage based on levels of repair record ratings{p_end}
{phang2}{cmd:. oda mpg3 rep78, trainreps(1000) cat loo}{p_end}

{pstd}Add bootstrap confidence intervals to the same model{p_end}
{phang2}{cmd:. oda mpg3 rep78, trainreps(1000) cat loo ci}{p_end}

{hline}
{pstd}
{opt (6) Causal inference with a binary classvar (treatment) and continuous attrvar (outcome):}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}

{pstd}Estimate propensity score for {cmd:mbsmoke} as the treatment, and
generate inverse probability of treatment weights (IPTW){p_end}
{phang2}{cmd:. logit mbsmoke mmarried c.mage c.mage#c.mage fbaby medu}{p_end}
{phang2}{cmd:. predict pscore, pr}{p_end}
{phang2}{cmd:. gen iptw = cond(mbsmoke, 1/pscore, 1/(1-pscore))}{p_end}

{pstd}Estimate the treatment effect of {cmd:mbsmoke} on {cmd:bweight} using
the IPTW weights generated above{p_end}
{phang2}{cmd:. oda mbsmoke bweight, wt(iptw) trainreps(1000) loo dots}{p_end}

{pstd}Add bootstrap confidence intervals to the same model{p_end}
{phang2}{cmd:. oda mbsmoke bweight, wt(iptw) trainreps(1000) loo ci dots}{p_end}

{hline}
{pstd}
{opt (7) Causal inference with a multi-category classvar (treatment) and continuous attrvar (outcome):}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}

{pstd}Estimate propensity scores for the four treatment levels of
{cmd:msmoke} and generate four strata variables corresponding to each
treatment, respectively{p_end}
{phang2}{cmd:. mlogit msmoke i.(mmarried fbaby) mage c.mage#c.mage medu c.medu#c.medu c.mage#c.medu, base(0)}{p_end}
{phang2}{cmd:. predict double (ps1 ps2 ps3 ps4), pr}{p_end}

{pstd}Generate weights for nominal treatments using the
{helpb mmws} package (available from SSC){p_end}
{phang2}{cmd:. mmws msmoke, pscore(ps1 ps2 ps3 ps4) nominal nstrata(5 5 5 5) replace}{p_end}

{pstd}Estimate the treatment effect of {cmd:msmoke} on {cmd:bweight} using
the MMWS weights generated above. Note that we specify only that the model
be reported, since this complex analysis is very computer-intensive{p_end}
{phang2}{cmd:. oda msmoke bweight, wt(_mmws) dots}{p_end}

{pstd}Add bootstrap confidence intervals to the same model. We set ({opt cireps()} to 50 for a quick look before committing to a larger number of reps){p_end}
{phang2}{cmd:. oda msmoke bweight, wt(_mmws) ci cireps(50) dots}{p_end}

{hline}
{pstd}
{opt (8) cross-sample validation:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. xtile mpg3 = mpg, nq(3)}{p_end}

{pstd}Fit on the sample where {cmd:mpg3}=1 (the lowest-mileage tercile) and
classify the other tercile identified explicitly as a holdout{p_end}
{phang2}{cmd:. oda foreign price, loo cross(mpg3, 1)}{p_end}

{pstd}Same training sample, but naming two specific holdout values instead
of leaving them implicit{p_end}
{phang2}{cmd:. oda foreign price, loo cross(mpg3, 1, 2 3)}{p_end}

{pstd}Omit both {it:train#} and {it:hold#}: the numerically smallest value
of {cmd:mpg3} becomes the training sample and every other value becomes a
holdout, the same partition as the first command above{p_end}
{phang2}{cmd:. oda foreign price, loo cross(mpg3)}{p_end}

{pstd}{opt cross()} accepts the same additional options as any other oda
call -- add a Monte Carlo significance test and bootstrap confidence
intervals for the training sample and every holdout sample{p_end}
{phang2}{cmd:. oda foreign price, loo cross(mpg3, 1) trainreps(1000) ci}{p_end}

{hline}
{pstd}
{opt (9) generalizability:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. xtile mpg3 = mpg, nq(3)}{p_end}

{pstd}Fit once on the whole sample, then report the same fitted model's
performance broken down separately within each mileage tercile{p_end}
{phang2}{cmd:. oda foreign price, loo gen(mpg3)}{p_end}

{pstd}add a Monte Carlo significance test and bootstrap confidence
intervals, reported for the whole sample and for each {cmd:gen()} group{p_end}
{phang2}{cmd:. oda foreign price, loo gen(mpg3) trainreps(1000) ci}{p_end}

{hline}
{pstd}
{opt (10) Postestimation -- get predicted class values for each observation:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. oda foreign mpg, loo}{p_end}

{pstd}Apply the fitted model back onto the estimation sample{p_end}
{phang2}{cmd:. oda_predict predicted_foreign}{p_end}

{pstd}Overwrite an existing prediction variable{p_end}
{phang2}{cmd:. oda_predict predicted_foreign, replace}{p_end}

{pstd}Apply the fitted model to only part of the data{p_end}
{phang2}{cmd:. oda_predict predicted_foreign if price > 5000, replace}{p_end}

{pstd}Apply the fitted model to a genuinely different, holdout dataset{p_end}
{phang2}{cmd:. use myholdout.dta, clear}{p_end}
{phang2}{cmd:. oda_predict predicted_foreign}{p_end}



{title:Stored results}

{pstd}
{cmd:oda} stores the following in {cmd:r()}. When {opt wt()} is specified, 
the {cmd:_wtd}-suffixed scalars are also stored.

{pstd}
Always posted{p_end}
{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations used{p_end}
{synopt:{cmd:r(K)}}number of classes in {it:classvar}{p_end}
{synopt:{cmd:r(ess_train)}}training-sample Effect Strength (sensitivity/PAC){p_end}
{synopt:{cmd:r(overall_acc)}}training-sample Overall Accuracy{p_end}
{synopt:{cmd:r(ess_pv)}}training-sample Effect Strength (Predictive Value){p_end}
{synopt:{cmd:r(ess_total)}}training-sample Effect Strength Total{p_end}
{p2colreset}{...}

{pstd}
Binary {it:classvar} only{p_end}
{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(cutpoint)}}the fitted cutpoint ({it:attrvar} not {opt cat}), or missing ({opt cat}){p_end}
{synopt:{cmd:r(direction)}}1 or -1, the fitted direction{p_end}
{synopt:{cmd:r(sens)}}training-sample sensitivity (PAC for the high class){p_end}
{synopt:{cmd:r(spec)}}training-sample specificity (PAC for the low class){p_end}
{synopt:{cmd:r(pv0)}}training-sample Predictive Value, low class{p_end}
{synopt:{cmd:r(pv1)}}training-sample Predictive Value, high class{p_end}
{p2colreset}{...}

{pstd}
Binary {it:classvar} with {opt wt()}{p_end}
{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ess_pac_wtd)}}weighted training-sample Effect Strength (PAC){p_end}
{synopt:{cmd:r(overall_acc_wtd)}}weighted training-sample Overall Accuracy{p_end}
{synopt:{cmd:r(pac0_wtd)}}weighted PAC, low class{p_end}
{synopt:{cmd:r(pac1_wtd)}}weighted PAC, high class{p_end}
{synopt:{cmd:r(pv0_wtd)}}weighted PV, low class{p_end}
{synopt:{cmd:r(pv1_wtd)}}weighted PV, high class{p_end}
{synopt:{cmd:r(ess_pv_wtd)}}weighted Effect Strength (PV){p_end}
{synopt:{cmd:r(ess_total_wtd)}}weighted Effect Strength Total{p_end}
{p2colreset}{...}

{pstd}
Multi-category {it:classvar} with {opt wt()}{p_end}
{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ess_train_wtd)}}weighted training-sample Effect Strength (PAC){p_end}
{synopt:{cmd:r(overall_acc_wtd)}}weighted training-sample Overall Accuracy{p_end}
{synopt:{cmd:r(ess_pv_wtd)}}weighted Effect Strength (PV){p_end}
{synopt:{cmd:r(ess_total_wtd)}}weighted Effect Strength Total{p_end}
{p2colreset}{...}

{pstd}
With {opt trainreps(#)}{p_end}
{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(est_P)}}Monte Carlo permutation {it:p}-value{p_end}
{synopt:{cmd:r(est_adjP)}}Sidak-adjusted {it:p}-value (requires {opt sidak()} too){p_end}
{p2colreset}{...}

{pstd}
With {opt loo}, binary {it:classvar}{p_end}
{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ess_loo)}}leave-one-out Effect Strength (PAC){p_end}
{synopt:{cmd:r(overall_acc_loo)}}leave-one-out Overall Accuracy{p_end}
{synopt:{cmd:r(ess_pv_loo)}}leave-one-out Effect Strength (PV){p_end}
{synopt:{cmd:r(ess_total_loo)}}leave-one-out Effect Strength Total{p_end}
{synopt:{cmd:r(sens_loo)}}leave-one-out sensitivity{p_end}
{synopt:{cmd:r(spec_loo)}}leave-one-out specificity{p_end}
{synopt:{cmd:r(pv0_loo)}}leave-one-out PV, low class{p_end}
{synopt:{cmd:r(pv1_loo)}}leave-one-out PV, high class{p_end}
{synopt:{cmd:r(est_P_LOO)}}Fisher's exact (directional) {it:p}-value for LOO,
or the {opt looreps()} permutation {it:p}-value when it was given{p_end}
{synopt:{cmd:r(est_adjP_LOO)}}Sidak-adjusted LOO {it:p}-value (requires {opt sidak()} too){p_end}
{p2colreset}{...}

{pstd}
With {opt loo}, binary {it:classvar}, and {opt wt()}{p_end}
{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ess_pac_loo_wtd)}}weighted leave-one-out Effect Strength (PAC){p_end}
{synopt:{cmd:r(overall_acc_loo_wtd)}}weighted leave-one-out Overall Accuracy{p_end}
{synopt:{cmd:r(pac0_loo_wtd)}}weighted leave-one-out PAC, low class{p_end}
{synopt:{cmd:r(pac1_loo_wtd)}}weighted leave-one-out PAC, high class{p_end}
{synopt:{cmd:r(pv0_loo_wtd)}}weighted leave-one-out PV, low class{p_end}
{synopt:{cmd:r(pv1_loo_wtd)}}weighted leave-one-out PV, high class{p_end}
{synopt:{cmd:r(ess_pv_loo_wtd)}}weighted leave-one-out Effect Strength (PV){p_end}
{synopt:{cmd:r(ess_total_loo_wtd)}}weighted leave-one-out Effect Strength Total{p_end}
{p2colreset}{...}

{pstd}
With {opt loo}, multi-category {it:classvar}{p_end}
{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ess_loo_wtd)}}weighted leave-one-out Effect Strength (PAC) ({opt wt()} only){p_end}
{synopt:{cmd:r(overall_acc_loo_wtd)}}weighted leave-one-out Overall Accuracy ({opt wt()} only){p_end}
{synopt:{cmd:r(ess_pv_loo_wtd)}}weighted leave-one-out Effect Strength (PV) ({opt wt()} only){p_end}
{synopt:{cmd:r(ess_total_loo_wtd)}}weighted leave-one-out Effect Strength Total ({opt wt()} only){p_end}
{synopt:{cmd:r(est_P_LOO)}}LOO permutation {it:p}-value (only when {opt looreps()} was also given){p_end}
{synopt:{cmd:r(est_adjP_LOO)}}Sidak-adjusted LOO {it:p}-value ({opt looreps()} and {opt sidak()} both given){p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Yarnold PR Soltysik RC. Theoretical distributions of optima for univariate discrimination of random data. 
{it:Decision Sciences} 1991;22:739-752.

{p 4 8 2}
Yarnold PR Soltysik RC. {it:Optimal Data Analysis: A Guidebook with Software for Windows.} Washington, DC: APA Books, 2005.

{p 4 8 2}
Yarnold PR Soltysik RC. {it:Maximizing Predictive Accuracy.} Chicago, IL: ODA Books. DOI: 10.13140/RG.2.1.1368.3286, 2016.

{p 4 8 2}
Linden A, Yarnold PR. Using machine learning to assess covariate balance in matching studies.{it:Journal of Evaluation in Clinical Practice} 2016;22:848-854.

{p 4 8 2}
Linden A, Yarnold PR. Using machine learning to identify structural breaks in single-group interrupted time series designs.{it:Journal of Evaluation in Clinical Practice} 2016;22:855-859.

{p 4 8 2}
Linden A, Yarnold PR, Nallomothu BK. Using machine learning to model dose-response relationships.{it:Journal of Evaluation in Clinical Practice} 2016;22:860-867.

{p 4 8 2}
Linden A, Yarnold PR. Combining machine learning and matching techniques to improve causal inference in program evaluation.{it:Journal of Evaluation in Clinical Practice} 2016;22:868-874.

{p 4 8 2}
Linden A, Yarnold PR. Combining machine learning and propensity score weighting to estimate causal effects in multivalued treatments.{it:Journal of Evaluation in Clinical Practice} 2016;22:875-885.

{p 4 8 2}
Linden A, Yarnold PR. Using machine learning to evaluate treatment effects in multiple-group interrupted time series analysis.{it:Journal of Evaluation in Clinical Practice} 2018;24:740-744.



{title:Citation of {cmd:oda}}

{p 4 8 2}{cmd:oda} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2020). ODA: Stata module for conducting Optimal Discriminant Analysis. Statistical Software Components S458728, Boston College Department of Economics. {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	Linden Consulting Group, LLC{p_end}
{p 4 8 2}	alinden@lindenconsulting.org{p_end}



{title:Acknowledgments} 

{p 4 4 2}
I wish to thank Paul R. Yarnold for reviewing {cmd:oda} and providing valuable comments.{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb cta} (if installed), {helpb looclass} (if installed), {helpb kfoldclass} (if installed) {helpb classtabi} (if installed) {helpb mmws} (if installed){p_end}

