{smcl}
{* *! version 2.1.0 04jan2024}{...}
{vieweralsosee "sampsi (if installed)" "sampsi"}{...}
{vieweralsosee "power (if installed)" "power"}{...}
{vieweralsosee "artbin_whatsnew" "artbin_whatsnew"}{...}
{vieweralsosee "art" "art"}{...}
{vieweralsosee "artsurv" "artsurv"}{...}
{viewerjumpto "Syntax" "artbin##syntax"}{...}
{viewerjumpto "Description" "artbin##description"}{...}
{viewerjumpto "Options" "artbin##options"}{...}
{viewerjumpto "Remarks" "artbin##remarks"}{...}
{viewerjumpto "Use for Observational Studies" "artbin##observationaluse"}{...}
{viewerjumpto "Changes from artbin version 1.1.2 to version 2.0.1" "artbin##whatsnew"}{...}
{viewerjumpto "Examples" "artbin##examples"}{...}
{viewerjumpto "References" "artbin##references"}{...}
{viewerjumpto "Citation" "artbin##citation"}{...}
{viewerjumpto "Authors" "artbin##authors"}{...}
{viewerjumpto "Stored results" "artbin##stored"}{...}
{viewerjumpto "Also see" "artbin##also_see"}{...}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:artbin} {hline 2}}ART (Binary Outcomes) - Sample Size and Power{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmdab:artbin, }
{cmd:pr(}{it:#}1 ... {it:#}K{cmd:)}
[{cmd:}
{it:options}
]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Trial type}
{synopt :{opt m:argin(#)}}margin for a non-inferiority or substantial-superiority trial{p_end}
{synopt :{opt fav:ourable}}outcome is favourable{p_end}
{synopt :{opt unf:avourable}}outcome is unfavourable{p_end}

{syntab:Power and sample size}
{synopt :{opt po:wer(#)}}power of trial{p_end}
{synopt :{opt n(#)}}total sample size{p_end}
{synopt :{opt ar:atios(aratio_list)}}allocation ratio(s){p_end}
{synopt :{opt ltfu(#)}}proportion lost to follow-up{p_end}

{syntab:Test}
{synopt :{opt al:pha(#)}}significance level for testing treatment effect(s){p_end}
{synopt :{opt o:nesided}}the significance level given by {opt alpha()} is one-sided{p_end}
{synopt :{opt tr:end}}applies a linear trend test{p_end}
{synopt :{opt do:ses(dose_list)}}doses for linear trend test{p_end}
{synopt :{opt co:ndit}}applies a conditional test{p_end}
{synopt :{opt wa:ld}}applies a Wald test{p_end}
{synopt :{opt c:correct}}applies a continuity correction{p_end}


{syntab:Method}
{synopt :{opt lo:cal}}calculates under local alternatives (only valid for small treatment effects){p_end}
{synopt :{opt noround}}the calculated sample size in each group should not be rounded up to the nearest integer{p_end}
{synopt :{opt force}}overrides the program's inference of the favourable/ unfavourable outcome type{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:artbin} is part of the {help art:ART} suite: {cmd:A}ssessment of {cmd:R}esources for {cmd:T}rials.

{pstd}
{cmd:artbin} calculates the power or total sample size for various tests comparing {it:K}
anticipated probabilities. Power is calculated if {opt n()} is specified,
otherwise total sample size is estimated. {cmd:artbin} can be used in designing
superiority, non-inferiority and substantial-superiority trials.

{pstd}
{cmd:pr(}{it:#}1 ... {it:#}K{cmd:)} is required and specifies the anticipated outcome probabilities
in the groups that will be compared. {it: #1} is the anticipated probability in the control group
({it:pi1^a}) and {it: #2}, {it:#3}, ... are the anticipated probabilities in the treatment groups
({it:pi2^a, pi3^a, ...}).

{pstd}
{cmd: artbin} makes comparisons on the scale of difference in
probabilities. The results on other scales such as
odds ratios will be very similar for superiority trials 
but potentially very different for  non-inferiority and substantial-superiority trials ({help artbin##quartagno:Quartagno, 2020}).

{pstd}
In a multi-group trial, {cmd:artbin} is based on a test of the global null 
hypothesis that the probabilities are equal in all groups. The alternative 
hypothesis is that there is a difference between two or more of the groups.

{pstd}
In a two-group superiority trial, {cmd:artbin} is based on a test of the null hypothesis 
that the probabilities
in the two groups are equal, and the alternative hypothesis is that they take
unequal values, such that the experimental treatment is better than the control
treatment.

{pstd}
In a non-inferiority trial, {cmd:artbin} is based on a test of the null 
hypothesis that the experimental treatment is worse than the control
treatment by at least a pre-specified amount, termed the {it:margin}. {cmd: artbin}
supports the design of more complex non-inferiority trials in which
{it: pi1^a} and {it: pi2^a} are unequal. Substantial-superiority trials are
increasingly used; here, the null hypothesis is that the experimental
treatment is better than the control treatment by at most the margin.

{pstd}
To minimise the risk of error in two-group trials, 
the user is advised to identify whether the trial outcome is favourable or
unfavourable. 
If this option is omitted, {cmd:artbin} infers favourability status from the
{opt pr()} and {opt margin()} options. If {it:pi2^a > pi1^a + margin}, the outcome
is assumed to be favourable, otherwise unfavourable.


{marker options}{...}
{title:Options}

{dlgtab:Trial type}

{phang}
{opt margin(#)} is used with two-group trials and must be specified if a non-inferiority or
substantial-superiority trial is being designed. The default margin is {it:# = 0},
denoting a superiority trial.

{pmore}
If the event of interest is unfavourable, the null hypothesis
for all these designs is {it:pi2 – pi1 >= m}, where {it:m} is the
pre-specified margin. The alternative hypothesis is {it:pi2 – pi1 < m}.
{it:m > 0} denotes a non-inferiority trial, whereas {it:m < 0} denotes
a substantial-superiority trial.

{pmore}
If on the other hand the event of interest is favourable, the above
inequalities are reversed. The null hypothesis for all these designs
is then {it:pi2 – pi1 <= m} and the alternative hypothesis is
{it:pi2 – pi1 > m}. {it:m < 0} denotes a non-inferiority trial,
while {it:m > 0} denotes a substantial-superiority trial.

{pmore}
The hypothesised margin for the difference in anticipated probabilities, {it:#}, must lie
between -1 and 1. 

{phang}
{opt favourable} or {opt unfavourable} are used with two-group trials
to specify whether the outcome is {opt favourable} or {opt unfavourable}.
If either option is used, {cmd:artbin} checks the assumptions;
otherwise, it infers the favourability status.  Both American and 
English spellings are allowed.

{dlgtab:Power and sample size}

{phang}
{opt power(#)} specifies the required power of the trial at the
{opt alpha()} significance level and computes the total sample size.
{opt power()} cannot be used with {opt n()}. Default {it:#} is 0.8.

{phang}
{opt n(#)} specifies the total sample size available and computes the
corresponding power. {opt n()} cannot be used with {opt power()}. 
The default is to calculate the sample size for power 0.8.

{phang}
{opt aratios(aratio_list)} specifies the allocation ratio(s).
The allocation ratio for group {it:k} is {it:#k}, {it:k = 1,...,K} e.g. {cmd:aratios(1 2)}
means two participants are randomised to the experimental group for each one randomised
to the control group. With two groups, {cmd:aratios(#)} is taken to mean {opt aratios(1 #)}.
The default is equal allocation to all groups.

{phang}               
{opt ltfu(#)} assumes a proportional loss to follow-up of {it:#}, where {it:#}
is a number between 0 and 1. The total sample size is divided by 1 - {it:#} before rounding.
The default is {it:#} = 0, meaning no loss to follow-up.

{dlgtab:Test}

{phang}
{opt alpha(#)} specifies that the trial will be analysed using a significance test 
with level {it:#}. That is, {it:#} is the type 1 error probability. Default is {it:#} = 0.05.

{phang}
{opt onesided} is used for two-group trials and for trend tests in multi-group trials. 
It specifies that the significance level given by {opt alpha()} is one-sided. 
Otherwise, the value of {opt alpha()} is halved to give a one-sided significance level. 
Thus for example {opt alpha(0.05)} is exactly the same as {opt alpha(0.025)} {opt onesided}.

{pmore}
{cmd: artbin} always assumes that a two-group trial or a trend test in a multi-group trial will be 
analysed using a one-sided alternative, regardless of whether the alpha level was specified as 
one-sided or two-sided. {cmd: artbin} therefore uses a slightly different definition of power from
the {cmd: power} command: when a two-tailed test is performed, {cmd: power} 
reports the probability of rejecting the null hypothesis in either direction, whereas {cmd: artbin} 
only considers rejecting the null hypothesis in the direction of interest. 

{pmore}
{cmd: artbin} assumes that multi-group trials will be analysed using a two-sided alternative, so 
{opt onesided} is not allowed with multi-group trials unless {opt trend}/{opt doses()} is 
specified (see below).

{phang}               
{opt trend} is used for trials with more than two groups and 
specifies that the trial will be analysed using a linear trend test.
The default is a test for any difference between the groups. See also
{opt doses()}.

{phang}
{opt doses(dose_list)} is used for trials with more than two groups 
and specifies 'doses' or other quantitative measures
for a dose-response (linear trend) test. 
{opt doses()} implies {opt trend}.
{opt doses(#1 #2...#r)} assigns
doses for groups {it:1,...,r}.  If {it:r < K} (the total number of groups), the dose
is assumed equal to #r for groups {it:r+1, r+2, ..., K}. 
If {opt trend} is specified without {opt doses()} then the default is {opt doses(1 2 ... K)}.
{opt doses()} is not permitted for a two-group trial.

{phang}
{opt condit} specifies that the trial will be analysed using Peto's conditional test. 
This test conditions on the total number of events observed
and is based on Peto's local approximation to the log odds ratio.
This option is also likely to be a good approximation
with other conditional tests.
The default is the usual Pearson chisquare test. 

{pmore}
{opt condit} is not available for non-inferiority and super-superiority trials.
{opt condit} cannot be used with {opt wald} since only one test type is allowed.
{opt condit} implies {opt local}.
The {opt ccorrect} option is not available with {opt condit}.

{phang}
{opt wald} specifies that the trial will be analysed using the Wald test.
The default is the usual Pearson chisquare test. 

{pmore}
{opt wald} cannot be used with {opt condit} since only one test type is allowed.
The Wald test inherently allows for distant alternatives so {opt wald} and {opt local} can not be used together.

{phang}
{opt ccorrect} specifies that the trial will be analysed using a continuity correction. {opt ccorrect} is not
available with {opt condit}. The default is no continuity correction.

{dlgtab:Method}

{phang}
{opt local} specifies that the calculation should use the variance of the difference in proportions only under the null.
This approximation is valid when the treatment effect is small ("local alternatives"). 
The default uses the variance of the difference in proportions both under the null and under the alternative hypothesis.  
The local method is not recommended and is only included to allow comparisons with other software.

{pmore}
The Wald test inherently allows for distant alternatives so {opt wald} and {opt local} can not be used together.

{phang}
{opt noround} prevents rounding of the calculated sample size. The default is to round the calculated sample size in each group up to the nearest integer. 

{phang}
{opt force} can be used with two-group studies to override the program's inference of the
{opt favourable}/ {opt unfavourable} outcome type. This may be needed for example when designing an observational 
study with a harmful risk factor, the favourability types would be reversed and the {opt force} option applied.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:artbin} computes sample size/power for the (global/trend) unconditional
chisquare test or the conditional test based on the hypergeometric distribution
with Peto's one-step approximation to the odds ratio (OR). Sample size/power
is calculated in the unconditional case under either local or distant
alternatives. Under local alternatives, the program uses the test statistic 
covariance matrix appropriate to the null hypothesis of no difference among the 
probabilities under both the null and the alternative hypotheses.  This approach is 
reasonable if the odds ratio(s) under the alternative hypothesis are between about 
0.5 and 2. For two-group studies, the sample sizes tend to be somewhat larger with 
local alternatives than with global (non-local) alternatives. The default is 
non-local (distant).
  
{pstd}
The expected number of events is calculated based on the trial recruiting the sample size per group 
given in the output table (which have been rounded up to the nearest integer unless {opt noround} has been specified).  

{pstd}All calculations in {cmd:artbin} are based on the approximation that the difference in proportions is Normally distributed (or with {opt condit} that the score statistic is Normally distributed). 
This approximation may fail with very small sample sizes, in which case the continuity correction should be used.
We suggest using the usual rule for the Pearson chi-squared test, namely to mistrust the results when any expected 
cell count is lower than about 5. Concerned users should check the power by simulation.
 
{pstd}
For a full description of the methods and formulae used in {cmd:artbin}, please see {help artbin##citation:the accompanying Stata Journal paper}.


{marker observationaluse}{...}
{title:Use for Observational Studies}

{pstd}
{cmd:artbin} has been created to assist the design of clinical trials, but it can also be used
in the design of observational studies to explore a protective or harmful factor. The
trial and outcome types may need to be re-interpreted, for example for a harmful risk
factor in an observational study, the favourable/unfavourable outcome types would be
reversed. This would be an example of when the option {opt force} would be used.
An observational study design to demonstrate a protective factor could be
designed in exactly the same way as a trial, but the term {it:superiority} might be replaced
by {it:benefit}. This is further described in the newly available {bf:{help artcat:artcat}}, a Stata program to
calculate sample size or power for a 2-group trial with ordered categorical outcome.

{marker whatsnew}
{title:Changes from {cmd:artbin} version 1.1.2 to version 2.0.1}

{pstd}
For a detailed description of what's new in artbin, please see {helpb artbin_whatsnew}.


{title:Changes from {cmd:artbin} version 2.0.1 to version 2.1}

{pstd}An error in the {cmd:ltfu()} option when calculating power from sample size has been corrected.

{pstd}Rounding now behaves exactly as stated in the help file, i.e. sample sizes are rounded up to the nearest integer in each group.


{marker examples}{...}
{title:Examples}

{pstd}Find the sample size to give 80% power in a two-group superiority trial where the experimental treatment is expected to increase the proportion from 0.25 to 0.35:

{phang}. {stata "artbin, pr(0.25 0.35)"}

{pstd}Note that {cmd:artbin} infers that the outcome is favourable from the fact that we want to increase the proportion.

{pstd}The same, but with a local approximation in the calculation:

{phang}. {stata "artbin, pr(0.25 0.35) local"}

{pstd}The same, but assuming a Wald test and requiring 90% power:

{phang}. {stata "artbin, pr(0.25 0.35) favourable wald power(0.9)"}

{pstd}The same, but allowing for 20% loss to follow-up:

{phang}. {stata "artbin, pr(0.25 0.35) ltfu(0.2)"}

{pstd}Find the sample size for a trial comparing four groups using a Pearson chisquared test,
with event probability 0.15 in the control group and 0.25 to 0.45 in the experimental groups:

{phang}. {stata "artbin, pr(0.15 0.25 0.35 0.45)"}

{pstd}The same, but assuming the primary analysis will test for trend across the four groups:

{phang}. {stata "artbin, pr(0.15 0.25 0.35 0.45) trend"}

{pstd}The same, but with unequal allocation:

{phang}. {stata "artbin, pr(0.15 0.25 0.35 0.45) aratios(1 2 2 2)"}


{marker references}{...}
{title:References}

{phang}{marker quartagno}
Quartagno M, Walker AS, Babiker AG et al. Handling an uncertain control group event risk 
in non-inferiority trials: non-inferiority frontiers and the power-stabilising transformation. 
Trials 21, 145 (2020). {browse "https://doi.org/10.1186/s13063-020-4070-4"}

{marker citation}{...}
{title:Citation}

{phang}If you find this command useful, please cite it as below: 

{phang}Ella Marley-Zagar, Ian R. White, Patrick Royston, Friederike M.-S. Barthel, Mahesh K B Parmar, Abdel G. Babiker. artbin: Extended sample size for randomised trials with binary outcomes. Stata J 2023:1;24-52.
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X231161971"}


{marker stored}{...}
{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(n)}}Sample size (total){p_end}
{synopt:{cmd:r(n1)}}Sample size in group 1 {p_end}
{synopt:{cmd:r(n2)}}Sample size in group 2 {p_end}
{synopt:{cmd:r(D)}}Events expected  (total) {p_end}
{synopt:{cmd:r(D1)}}Events expected in group 1 {p_end}
{synopt:{cmd:r(D2)}}Events expected in group 2 {p_end}
{synopt:{cmd:r(power)}}Power  {p_end}
{pstd}The same quantities are returned, whether {cmd:artbin} has calculated power from sample size or sample size from power.
Further scalars {cmd:r(n3)} etc. are returned for trials with more than 2 arms.


{marker authors}{...}
{title:Authors}

{pstd}Abdel Babiker, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:a.babiker@ucl.ac.uk":Ab Babiker}

{pstd}Friederike Maria-Sophie Barthel, formerly MRC Clinical Trials Unit{break}
{browse "mailto:sophie@fm-sbarthel.de":Sophie Barthel}

{pstd}Babak Choodari-Oskooei, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:b.choodari-oskooei@ucl.ac.uk":Babak Oskooei}

{pstd}Patrick Royston, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:j.royston@ucl.ac.uk":Patrick Royston}

{pstd}Ella Marley-Zagar, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:e.marley-zagar@ucl.ac.uk":Ella Marley-Zagar}

{pstd}Ian White, MRC Clinical Trials Unit at UCL{break}
{browse "mailto:ian.white@ucl.ac.uk":Ian White}

{marker also_see}{...}
{title:Also see}

    Manual:  {hi:[R] sampsi}
    Manual:  {hi:[R] power}

{p 4 13 2}
Online:  help for {help artmenu}, {help artbindlg}, {help art}, {help artsurv}


