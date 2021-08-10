{smcl}
{cmd:help kappaetc}
{hline}

{title:Title}

{p 5}
{cmd:kappaetc} {hline 2} Interrater agreement


{title:Syntax}

{pstd}
Interrater agreement, variables record raw ratings

{p 8 18 2}
{cmd:kappaetc} 
{it:{help varname:varname1}} 
{it:{help varname:varname2}}
[{it:{help varname:varname3}} {it:...}]
{ifin} 
{weight}
[{cmd:,} {it:{help kappaetc##opts:options}} ]


{pstd}
Interrater agreement, variables record frequency of ratings

{p 8 18 2}
{cmd:kappaetc} 
{it:{help varname:varname1}} 
{it:{help varname:varname2}}
[{it:{help varname:varname3}} {it:...}]
{ifin} 
{weight}
{cmd:, frequency} [ {it:{help kappaetc##opts:options}} ]


{pstd}
Immediate command, interrater agreement, two raters, contingency table

{p 8 18 2}
{cmd:kappaetci}
{it:#11} {it:#12} [{it:...}] {cmd:\}
{it:#21} {it:#22} [{it:...}] [{cmd:\} {it:...}]
[{cmd:, tab} 
{it:{help kappaetc##opts:options}} ]


{pstd}
Test difference of correlated agreement coefficients

{p 8 18 2}
{cmd:kappaetc}
{varlist} 
{ifin} 
{weight}
{cmd:,} {opt store(name1)} 
[ {it:{help kappaetc##opts:options}} ]

{p 8 18 2}
{cmd:kappaetc}
{varlist} 
{ifin} 
{weight}
{cmd:,} {opt store(name2)}
[ {it:{help kappaetc##opts:options}} ]

{p 8 18 2}
{cmd:kappaetc}
{it:name1} {cmd:==} {it:name2}
{cmd:,} {helpb kappaetc_ttest:ttest}
[ {it:{help kappaetc_ttest##opts:kappaetc_ttest_options}} ]


{synoptset 28 tabbed}{...}
{marker opts}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{cmd:{ul:w}gt(}{it:wgtid} [{cmd:,} {it:wgt_options}]{cmd:)}}specify 
how disagreements be weighted; see {it:{help kappaetc##opt_wgt:Options}} for 
alternatives{p_end}
{synopt:{opt se(se_type)}}specify how standard errors be estimated; see 
{it:{help kappaetc##opt_se:Options}} for alternatives{p_end}
{synopt:{opt fre:quency}}specify that variables record rating frequencies
{p_end}
{synopt:{opt cat:egories(numlist)}}specify predetermined rating categories
{p_end}
{synopt:{opt casewise}}exclude subjects with missing ratings{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is 
{cmd:level({ccl level})}{p_end}
{synopt:{opt showw:eights}}display weighting matrix{p_end}
{synopt:{opt bench:mark}}benchmark interrater agreement coefficients; see 
{it:{help kappaetc##opt_benchmark:Options}}{p_end}
{synopt:{opt shows:cale}}display benchmark scale{p_end}
{synopt:{opt testval:ue(#)}}test whether coefficients equal {it:#}{p_end}
{synopt:{opt nohe:ader}}suppress output header{p_end}
{synopt:{opt notab:le}}suppress coefficient table{p_end}
{synopt:{it:{help kappaetc##opt_di:format_options}}}control column formats
{p_end}

{syntab:Advanced}
{synopt:{opt nsubjects(#)}}specify size of subject universe{p_end}
{synopt:{opt nraters(#)}}specify size of rater population{p_end}
{synopt:{opt df(matname)}}specify degrees of freedom{p_end}
{synopt:{opt largesample}}use standard normal distribution for p-values and 
intervals{p_end}

{syntab:Immediate command}
{synopt:{opt t:ab}}display contingency table{p_end}

{syntab:Miscellaneous}
{synopt:{opt sto:re(name)}}store (additional) returned results under {it:name}
{p_end}
{synopt:{opt ttest}}paired t test of difference between correlated agreement 
coefficients; see {help kappaetc##opt_ttest:{it:Options}}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by} is allowed only with {cmd:kappaetc}; see {manlink D by}.
{p_end}
{p 4 6 2}
{cmd:fweight}s and {cmd:iweight}s are allowed; see {help weight}.


{title:Description}

{pstd}
{cmd:kappaetc} calculates various measures of interrater agreement along with 
their standard errors and confidence intervals. Statistics are calculated for 
any number of raters, any number of categories, and in the presence of missing 
values (i.e. varying number of raters per subject). Disagreement among raters 
may be weighted by user-defined weights or a set of prerecorded weights, 
suitable for any level of measurement.

{pstd}
The command is implemented using methods and formulas discussed in Gwet 
(2014). It calculates percent agreement, the Brennan and Prediger coefficient 
(1981), Cohen's kappa (1960, 1968) and its generalizations by Conger (1980) 
and Fleiss (1971), Gwet's AC (2008, 2014) and Krippendorff's alpha (1970, 
2004, 2013) coefficient.

{pstd}
Standard errors are estimated conditionally upon the sample of raters, allowing 
results to be projected to the subject universe only. Optionally, 
{cmd:kappaetc} calculates (jackknife) standard errors conditional on the sample 
of subjects, or unconditional standard errors allowing projection of results to 
both, the subject universe and the rater population.

{pstd}
{cmd:kappaetc} assumes that each observation is a subject (unit of analysis) 
and variables contain the ratings by raters (coders, judges, observers). Thus, 
the first variable records the ratings assigned by the first rater, the second 
variable records the ratings assigned by the second rater, and so on. With the 
{opt frequency} option, each observation is still assumed to represent one 
subject. Variables, however, are expected to record the frequencies of ratings.

{pstd}
{cmd:kappaetc} also assumes that all possible rating categories are observed in 
the data. This assumption is crucial. If some of the rating categories are not 
used by any of the raters the full set of conceivable ratings must be specified 
in the {helpb kappaetc##opt_cat:categories()} option. Failing to do so might 
produce incorrect results for all weighted agreement coefficients. The Brennan 
and Prediger coefficient and Gwet's AC will not be correctly estimated, even if 
no weights are used.

{pstd}
{cmd:kappaetci} calculates interrater agreement for two raters from a 
contingency table of rating frequencies. The rows and columns of the table are 
assumed to represent the rating categories and the cell frequencies indicate 
how often the respective categories have been assigned by the two raters. The 
syntax mirrors that of {helpb tabulate_twoway:tabi}. Also see {help immed} for 
a general description of immediate commands.

{pstd}
{cmd:kappaetc} with the {opt ttest} option performs (paired) t tests of 
differences between estimated agreement coefficients. See 
{helpb kappaetc_ttest:kappaetc , ttest}.


{title:Remarks}

{pstd}
In the case of two raters and no missing ratings, Cohen's and Conger's kappa 
is the same as the coefficient that is obtained with Stata's {helpb kappa:kap} 
command. For two raters, Fleiss' kappa could also be labeled Scott's pi (1955), 
which in turn is identical to the bias-adjusted kappa (BAK) proposed by Byrt, 
Bishop and Carlin (1993; cf. Gwet 2014, p. 69). With two raters and missing 
ratings the coefficient of Stata's {helpb kappa:kap} command is replicated 
when the {opt casewise} option is specified.

{pstd}
For more than two raters and no missing ratings, the reported Fleiss' kappa 
is equivalent to the combined kappa reported by Stata's {helpb kappa:kap} 
command. However, {cmd:kappaetc} does not report a kappa value for each of 
the rating categories.

{pstd}
The Brennan and Prediger coefficient is generally the same as the 
prevalence-adjusted and bias-adjusted kappa (PABAK) suggested by Byrt, Bishop 
and Carlin (1993) (cf. Gwet 2014, p. 69).

{pstd}
{cmd:kappaetc} with the {opt frequency} option does not calculate Cohen's and 
Conger's kappa. In the case of a constant number of raters per subject, Fleiss' 
kappa is equivalent to the combined kappa obtained with Stata's {helpb kappa} 
command.


{title:Options}

{dlgtab:Main}

{marker opt_wgt}{...}
{phang}
{cmd:wgt(}{it:wgtid} [{cmd:,} {it:wgt_options}]{cmd:)} specifies 
that {it:wgtid} be used to weight disagreements. The available 
weights and {it:wgt_options} are described below.

{p2colset 9 23 24 8}{...}
{p2col:{opt i:dentity}} weights
are the q x q identity matrix, where q is the number of categories used 
to rate subjects. Identity weights are the default and result in the 
unweighted analysis.
{p_end}

{p2col:{opt o:rdinal}} weights
are defined as 1 - {help comb:comb}(|k-l|+1), 2)/comb(q, 2) for all k!=l, where 
k and l represent the ranked categories 1, 2, ..., q and q is the highest 
category. The {it:wgt_option} {opt krippen:dorff} is allowed and specifies that 
ordinal weights suggested by Krippendorff (2013) be used instead. The latter 
are defined as 1 - sum(n_g - (n_k+n_l)/2)^2, where the n_* are the observed 
number of pairable values k and l. Note that standard errors are not available 
with Krippendorff's ordinal weights.
{p_end}

{p2col:{opt l:inear}} weights
are defined as 1 - |k-l|/|q_max-q_min|, where k and l refer to the actual 
ratings and q_max and q_min are the maximum and minimum of all ratings. These 
weights are conceptually equivalent to the {opt w} weights in 
{helpb kappa##options:kap} when the {helpb kappa##options:absolute} option is 
specified. The {it:wgt_option} {opt noa:bsolute} is allowed and specifies that 
k and l be interpreted as row and column indices of the weighting matrix.
{p_end}

{p2col:{opt q:uadratic}} weights
are defined as 1 - (k-l)^2/(q_max-q_min)^2, where k and l refer to the actual 
ratings and q_max and q_min are the maximum and minimum of all observed 
ratings. These weights are conceptually equivalent to the {opt w2} weights in 
{helpb kappa##options:kap} when the {helpb kappa##options:absolute} option is 
specified. The {it:wgt_option} {opt noa:bsolute} is allowed and specifies that 
k and l be interpreted as row and column indices of the weighting matrix.
{p_end}

{p2col:{opt rad:ical}} weights
are defined as 1 - {help sqrt:sqrt}(|k-l|)/sqrt(|q_max-q_min|), where k and l 
refer to the actual ratings and q_max and q_min are the maximum and minimum of 
all ratings. The {it:wgt_option} {opt noa:bsolute} is allowed and specifies 
that k and l be interpreted as row and column indices of the weighting matrix.
{p_end}

{p2col:{opt r:atio}} weights
are defined as 1 - [(k-l)/(k+l)^2]/[(q_max-q_min)/(q_max+q_min)], where k and 
l refer to the actual ratings and q_max and q_min are the maximum and minimum 
of all ratings. The {it:wgt_option} {opt noa:bsolute} is allowed and specifies 
that k and l be interpreted as row and column indices of the weighting matrix.
{p_end}

{p2col:{opt c:ircular}} weights
are defined as 1 - {help sin():sin}({it:sine_arg}*(k-l)/(q_max-q_min+1))/M, 
where k and l refer to the actual ratings, q_max and q_min are the maximum and 
minimum of all ratings, M is the maximum of all weights and {it:sine_arg} is 
specified in the {it:wgt_option}
{cmd:sine(}{c -(}{cmd:pi}|{cmd:180}{c )-}{cmd:)}. The default is 
{cmd:sine(pi)}. Alternatively, the {it:wgt_option} {opt u(#)} is allowed and 
specifies that circular weights proposed by Warrens and Pratiwi (2016) be used 
instead. The latter are definded as u for all k!=l, where u = 
{it:#}*[(|k-l|==1)+(|k-l|==|q-1)] and 0 <= {it:#} < 1. The {it:wgt_option} 
{opt noa:bsolute} is required with {opt u()} and specifies that k and l are 
interpreted as row and column indices of the weighting matrix.
{p_end}

{p2col:{opt b:ipolar}} weights
are defined as (k-l)^2/[(k+l-2*q_min)*(2*q_max-k-l)], where k and l refer to 
the actual ratings and q_max and q_min are the maximum and minimum of all 
ratings.
{p_end}

{p2col:{opt p:ower(#)}} weights
are defined as 1 - (|k-l|^{it:#})/(|q_max-q_min|^{it:#}), where k and l refer 
to the actual ratings and q_max and q_min are the maximum and minimum of all 
ratings. These weights are discussed in Warrenes (2014) as a generalization 
of identity ({it:#}=0), linear ({it:#}=1), quadratic ({it:#}=2) and radical 
({it:#}=0.5) weights. The {it:wgt_option} {opt noa:bsolute} is allowed and 
specifies that k and l be interpreted as row and column indices of the 
weighting matrix.
{p_end}

{p2col:{opt w}} is a synonym for {opt l:inear} with {it:wgt_option} 
{opt noa:bsolute}. See above.
{p_end}

{p2col:{opt w2}} is a synonym for {opt q:uadratic} with {it:wgt_option} 
{opt noa:bsolute}. See above.
{p_end}

{p2col:{it:kapwgt}} 
are weights defined with the {helpb kapwgt} command. The {it:wgt_option} 
{opt kap:wgt} is allowed and must be used if {it:kapwgt} has the same 
name as one of the prerecorded weights (or their abbreviations) discussed 
above.
{p_end}

{p2col:{it:matname}}
are weights defined in a Stata matrix. The {it:wgt_option} {opt mat:rix} 
is allowed and must be used if {it:matname} is the same name as {it:kapwgt} 
or any of the prerecorded weights (or their abbreviations) discussed 
above.
{p_end}
{p2colreset}{...}

{marker opt_se}{...}
{phang}
{opt se(se_type)} specifies how standard errors be estimated. Any estimated 
interrater agreement coefficient potentially depends on two samples. Subjects 
to be rated might be drawn from a universe of subjects while raters might be 
drawn from a rater population. Standard errors may therefore be conditional 
upon either of the samples, or unconditional, taking into account the two 
respective sampling errors. The appropriateness of these different standard 
errors depends on the research questions. Available {it:se_types} are described 
below.

{p2colset 9 23 24 8}{...}
{p2col:{cmd:{ul:cond}itional}} standard errors are the default and are 
estimated conditionally upon the sample of raters. These standard errors are 
appropriate if results are to be generalized to the subject universe given the 
specific raters.
{p_end}

{p2col:{cmd:{ul:jack}knife}} standard errors are estimated conditionally upon 
the sample of subjects. The extent of agreement among all but one rater is 
obtained for each of the r (r > 2) raters in the sample. The standard errors 
allow projection of results to the rater population given the rated subjects.
{p_end}

{p2col:{cmd:{ul:uncond}itional}} standard errors are appropriate if the 
results are to be projected to the universe of subjects and the rater 
population. They are calculated as the square root of the  sum of variances 
due to the subject and rater sample.
{p_end}
{p2colreset}{...}

{phang}
{opt frequency} specifies that variables represent rating categories. The first 
variable records the frequency of the first rating category, the second 
variable records the frequency of the second rating category, and so on. Rating 
categories are assumed to be the integer sequence 1, 2, ..., q (but see option
{helpb kappaetc##opt_cat:categories()}). Note that all possible ratings must 
be represented by one variable even if the frequency is 0 for all 
subjects. Cohen's and Conger's kappa is not available for recorded frequencies 
and only the default conditional standard errors can be obtained.

{marker opt_cat}{...}
{phang}
{cmd:categories(}{it:{help numlist}}{cmd:)} specifies the predetermined rating 
categories. By default the set of ratings is obtained from the data. There are 
two situations where this option is used. 

{p 8 8 2}
With variables containing ratings (the default), the full set of possible 
rating categories must be specified if not all of them are observed in the 
data. Failing to do so may lead to incorrect results. The order in which 
ratings are specified does not matter. Note that noninteger values are 
processed in {help data_types:double} precision. To convert them to 
{help data_types:float} precision an extension of the {helpb f_float:float()}
function may be used. Specify {cmd:categories(float(}{it:numlist}{cmd:))}.

{p 8 8 2}
With the {opt frequency} option the ratings are assumed to be the integer 
sequence 1, 2, ..., q, corresponding to the specified variables. Likewise, 
with the immediate form of the command, the ratings are assumed to be the 
integer sequence 1, 2, ..., q of rows and columns entered. In both cases 
the {cmd:categories()} option may be used to specify alternative rating 
categories including noninteger, negative and even missing values. Also in 
both cases the order in which the ratings are specified matters and 
corresponds to the respective variables or sorted values underlying the table.

{phang}
{opt casewise} specifies that subjects with missing ratings be excluded 
from the analysis. By default all subjects that are rated by at least one 
(two, for Krippendorff's alpha) rater(s) are used to estimate expected 
agreement. Observed agreement is based only those subjects that are rated 
by two or more raters.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence 
intervals. The default is {cmd:level({ccl level})}.

{phang}
{opt showweights} additionally displays the weighting matrix below the 
coefficient table. For the unweighted analysis the identity matrix is shown.

{marker opt_benchmark}{...}
{phang}
{opt benchmark} benchmarks the estimated interrater agreement coefficients 
using the Landis and Koch (1977) scale and the method proposed by Gwet 
(2014). 

{p 8 8 2}
Landis and Koch (1977) suggest the following benchmark scale for 
interpreting the kappa-statistic:

{p2colset 26 36 34 8}{...}
{p2col:{bind:    }<0.00}Poor{p_end}
{p2col:0.00-0.20}Slight{p_end}
{p2col:0.21-0.40}Fair{p_end}
{p2col:0.41-0.60}Moderate{p_end}
{p2col:0.61-0.80}Substantial{p_end}
{p2col:0.81-1.00}Almost Perfect{p_end}
{p2colreset}{...}

{p 8 8 2}
Gwet (2014) argues that the probability distribution of an agreement 
coefficient depends on the number of subjects, raters and categories in the 
study. Therefore, the error margin associated with these sources of variance 
must be taken into account when comparing estimated coefficients to 
predetermined thresholds. Consequently, benchmarking should be probabilistic 
rather than deterministic. He proposes a statistical method that consists of 
three steps. First, the probability for an agreement coefficient to fall into 
each of the intervals, defined by the benchmark limits, is calculated. Next, 
the cumulative probability for the intervals is computed, starting from the 
highest level. Finally, the interval associated with a cumulative probability 
larger than a given level ({ccl level}%, by default) determines the final 
benchmark level.

{p 8 8 2}
With the {opt benchmark} option, {cmd:kappaetc} displays the estimated 
coefficients along with their standard errors. It reports the probability for 
each coefficient to fall into the selected benchmark interval along with the 
cumulative probability exceeding the predetermined threshold associated 
with this interval. The interval limits are shown as well.

{p 8 8 2}
The full syntax for this option is {opt benchmark(benchmark_options)}, and 
available {it:benchmark_options} are described below.

{p2colset 9 23 24 8}{...}
{p2col:{opt p:robabilistic}} is the default and selects the benchmark interval 
associated with the smallest cumulative membership probability exceeding 
{ccl level}%. The threshold is controlled by the {opt level()} option.
{p_end}

{p2col:{opt d:eterministic}} selects the benchmark interval associated with 
the estimated agreement coefficient. This method is deterministic in the sense 
that the chosen interval is determined by the point estimate alone, ignoring 
any uncertainty associated with its estimation. 
{p_end}

{p2col:{opt s:cale(spec)}} specifies the benchmark scale. {it:spec} is usually 
one of {cmd:landis} (or {cmd:koch}), {cmd:fleiss} or {cmd:altman}. The default 
is {cmd:landis} (or {cmd:koch}) and results in the Landis and Koch scale as 
shown above. {cmd:fleiss} requests a three level scale, suggested by Fleiss 
(1981), and {cmd:altman} collapses the first two levels of the default scale 
into one category, yielding the Altman (1991) scale. Alternatively, {it:spec} 
explicitly specifies the (upper limit) benchmarks as a {it:{help numlist}}. The 
Landis and Koch scale could be obtained by {cmd:scale(0(.2)1)}.
{p_end}
{p2colreset}{...}

{phang}
{opt showscale} additionally displays the benchmark scale for interpreting 
coefficients. This option is ignored when {opt benchmark} is not specified.

{phang}
{cmd:testvalue(#)} tests whether the estimated agreement coefficients equal 
{it:#}. Default is {cmd:testvalue(0)}. The full syntax for this option is 
{cmd:testvalue(}[{it:{help operator:relop.}}]{it:#}{cmd:)}, where {it:relop} 
is one of the relational operators {cmd:>}[{cmd:=}] or {cmd:<}[{cmd:=}] and 
preforms one-sided tests.

{phang}
{opt noheader} suppresses the report about the number of subjects, ratings per
subject and rating categories. Only the coefficient table is displayed.

{phang}
{opt notable} suppresses the display of the coefficient table.

{marker opt_di}{...}
{phang}
{cmd:cformat(}{it:{help format:{bf:%}fmt}}{cmd:)} specifies how to format 
coefficients, standard errors, and confidence limits. The maximum format 
width is 8.

{phang}
{cmd:pformat(}{it:{help format:{bf:%}fmt}}{cmd:)} specifies how to format 
p-values. The maximum format width is 5.

{phang}
{cmd:sformat(}{it:{help format:{bf:%}fmt}}{cmd:)} specifies how to format 
test statistics. The maximum format width is 6.

{dlgtab:Advanced}

{phang}
{opt nsubjects(#)} specifies the size of the subject universe to be used for 
the finite sample correction. The default is {cmd:nsubjects(.)}, leading to a 
sampling fraction of 0 that is assumed to be negligible. This option is seldom 
used.

{phang}
{opt nraters(#)} specifies the size of the rater population to be used for 
the finite sample correction. The default is {cmd:nraters(.)}, leading to 
a sampling fraction of 0 that is assumed to be negligible. This option is 
relevant only for jackknife or unconditional standard errors. It is seldom 
used although the default might overestimate the variance for small rater 
populations.

{phang}
{opt df(matname)} specifies that the degrees of freedom in {it:matname} be used 
to calculate p-values and confidence intervals. Currently no close equation is 
available for expressing the degrees of freedom associated with the jackknife 
and unconditional standard errors. By default, {cmd:kappaetc} uses the standard 
normal distribution as an approximation in both cases. This option is seldom 
used.

{phang}
{opt largesample} specifies that the calculation of p-values and intervals be 
based on the standard normal distribution rather than the t distribution. This 
is the default for jackknife and unconditional standard errors, unless option  
{opt df()} has been specified. {opt largesample} is a reporting option and it 
is seldom used.

{dlgtab:Immediate command}

{phang}
{opt tab} displays the two-way table of cell frequencies. The option is 
useful for data entry verification.

{dlgtab:Miscellaneous}

{marker opt_ttest}{...}
{phang}
{opt store(name)} returns additional results in {cmd:r()} and stores them 
under {it:name}. This option is intended for use with the {opt ttest} option 
(see below). Results are stored using {helpb _return:_return hold}. Note that 
any results previously held under {it:name} will be overwritten. {opt store()} 
may not be combined with the {cmd:by} prefix.

{phang}
{opt ttest} performs paired t tests of correlated agreement coefficients. See 
{helpb kappaetc_ttest:kappaetc , ttest}.


{title:Examples}

{pstd}
Examples are drawn from those in {helpb kappa##examples:kap} and 
{manlink R kappa}.

{pstd}
{cmd:{ul:Two raters}}

{phang2}{cmd:. webuse rate2}{p_end}
{phang2}{cmd:. kappaetc rada radb}{p_end}
{phang2}{cmd:. kappaetc rada radb , wgt(linear)}{p_end}

{phang2}{cmd:. kapwgt xm 1 \ .8 1 \ 0 0 1 \ 0 0 .8 1}{p_end}
{phang2}{cmd:. kappaetc rada radb , wgt(xm)}{p_end}

{pstd}
{cmd:{ul:More than two raters, varying number of raters (missing values)}}

{phang2}{cmd:. webuse rvary2}{p_end}
{phang2}{cmd:. kappaetc rater1-rater5}{p_end}


{title:Saved results}

{pstd}
{cmd:kappaetc} saves the following in {cmd:r()}:

{pstd}
Scalars{p_end}
{synoptset 24 tabbed}{...}
{synopt:{cmd:r(N)}}number of subjects{p_end}
{synopt:{cmd:r(r)}}number of raters (maximum number of ratings per subject)
{p_end}
{synopt:{cmd:r(r_min)}}minimum number of ratings per subject{p_end}
{synopt:{cmd:r(r_avg)}}average number of ratings per subject{p_end}
{synopt:{cmd:r(r_max)}}maximum number of ratings per subject 
(same as {cmd:r(r)}){p_end}
{synopt:{cmd:r(jk_miss)}}number of missing jackknife coefficients 
(not with {cmd:se(conditional)}){p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}

{pstd}
Macros{p_end}
{synoptset 24 tabbed}{...}
{synopt:{cmd:r(cmd)}}{cmd:kappaetc}{p_end}
{synopt:{cmd:r(wgt)}}{it:wgtid} for weighting disagreement{p_end}
{synopt:{cmd:r(userwgt)}}{cmd:kapwgt} or {cmd:matrix}
(only with user-defined {it:wgtid}){p_end}
{synopt:{cmd:r(setype)}}{cmd:conditional}, {cmd:jackknife} 
or {cmd:unconditional}{p_end}
{synopt:{cmd:r(wtype)}}{cmd:fweight} or {cmd:iweight}{p_end}
{synopt:{cmd:r(wexp)}}weight expression{p_end}
{synopt:{cmd:r(weight_i)}}subject-level weights 
({opt store()} only){p_end}
{synopt:{cmd:r(dfmat)}}{it:matname} holding degrees of freedom 
({opt df()} only){p_end}

{pstd}
Matrices{p_end}
{synoptset 24 tabbed}{...}
{synopt:{cmd:r(table)}}information from the coefficient table{p_end}
{synopt:{cmd:r(b)}}coefficients{p_end}
{synopt:{cmd:r(se)}}standard errors{p_end}
{synopt:{cmd:r(b_jknife)}}jackknife coefficients
(not with {cmd:se(conditional)}){p_end}
{synopt:{cmd:r(se_jknife)}}jackknife standard errors
({cmd:se(unconditional)} only){p_end}
{synopt:{cmd:r(se_conditional)}}conditional standard errors 
({cmd:se(unconditional)} only){p_end}
{synopt:{cmd:r(df)}}coefficient-specific degrees of freedom{p_end}
{synopt:{cmd:r(prop_o)}}observed proportion of agreement{p_end}
{synopt:{cmd:r(prop_e)}}expected proportion of agreement{p_end}
{synopt:{cmd:r(W)}}weighting matrix for disagreement (note capitalization)
{p_end}
{synopt:{cmd:r(categories)}}distinct levels of ratings{p_end}
{synopt:{cmd:r(table_benchmark_prob)}}information from the probabilistic
benchmark table ({opt benchmark} only){p_end}
{synopt:{cmd:r(table_benchmark_det)}}information from the deterministic
benchmark table ({opt benchmark} only){p_end}
{synopt:{cmd:r(benchmarks)}}upper limits of intervals
({opt benchmark} only){p_end}
{synopt:{cmd:r(imp)}}probability to fall into an interval
({opt benchmark} only){p_end}
{synopt:{cmd:r(p_cum)}}cumulative interval membership probability
({opt benchmark} only){p_end}
{synopt:{cmd:r(b_istar)}}subject-level agreement coefficients
({opt store()} only){p_end}


{title:References}

{pstd}
Altman, D. G. (1991). {it:Practical Statistics for Medical Research}. Chapman 
and Hall.

{pstd}
Brennan, R. L. and Prediger, D. J. (1981). Coefficient Kappa: some uses, 
misuses, and alternatives. {it:Educational and Psychological Measurement}, 
41, 687-699.

{pstd}
Byrt, T., Bsihop, J. and Carlin, J. B. (1993) Bias, prevalence and 
Kappa. {it:Journal of Clinical Epidemiology}, 46, 423-429.

{pstd}
Cohen, J. (1968). Weighted kappa: Nominal scale agreement with provision for 
scaled disagreement or partial credit. {it:Psychological Bulletin}, 70, 
213-220.

{pstd}
Cohen, J. (1960). A coefficient of agreement for nominal 
scales. {it:Educational and Psychological Measurement}, 20, 37-46.

{pstd}
Conger, A. J. (1980). Integration and Generalization of Kappa for Multiple 
Raters. {it:Psychological Bulletin}, 88, 322-328.

{pstd}
Fleiss, J. L. (1981). {it:Statistical Methods for Rates and Proportions}. John 
Wiley & Sons.

{pstd}
Fleiss, J. L. (1971). Measuring nominal scale agreement among many 
raters. {it:Psychological Bulletin}, 76, 378-382.

{pstd}
Gwet, K. L. (2014). {it:Handbook of Inter-Rater Reliability}. Gaithersburg, 
MD: Advanced Analytics, LLC.

{pstd}
Gwet, K. L. (2008). Computing inter-rater reliability and its variance in the 
presence of high agreement. {it:British Journal of Mathematical and Statistical Psycholgy}, 
61, 29-48. 

{pstd}
Krippendorff, Klaus (2013). Computing Krippendorff's 
Alpha-Reliability. (2011.1.25, Literature updated 2013.9.13)
{browse "http://www.asc.upenn.edu/usr/krippendorff/mwebreliability5.pdf"}

{pstd}
Krippendorff, Klaus (2004). 
{it:Content Analysis. An Introduction to Its Methodology}. Thousand Oaks, 
CA: SAGE. 

{pstd}
Krippendorff, Klaus (1970). Estimating the reliability, systematic error, and 
random error of interval data. {it:Educational and Psychological Measurement}, 
30, 61-70.

{pstd}
Landis, J. R., and Koch, G. G. (1977). The measurement of observer agreement 
for categorical data. {it:Biometrics}, 33, 159-174.

{pstd}
Scott, W. A. (1955). Reliability of content analysis: the case of nominal 
scale coding. {it:Public Opinion Quarterly}, XIX, 321-325.

{pstd}
Warrens, M. J. (2014). Power Weighted Versions of Bennett, Alpert, and 
Goldstein's S. {it:Journal of Mathematics}, 1-9.

{pstd}
Warrens, M. J., Pratiwi, B. C. (2016). Kappa Coefficients for Circular 
Classifications. {it:Journal of Classification}, 33, 507-522.


{title:Acknowledgments}

{pstd}
I am deeply grateful to Kilem Gwet for continuous support and patently 
clarifying my questions during the implementation of {cmd:kappaetc}. 

{pstd}
The name {cmd:kappaetc} is borrowed from {cmd:entropyetc} with approval from
Nicholas Cox.


{title:Author}

{pstd}Daniel Klein, University of Kassel, klein.daniel.81@gmail.com


{title:Also see}

{psee}
Online: {helpb kappa}, {helpb icc}
{p_end}

{psee}
if installed: {help kappa2}, {help kapci}, {help kappci}, {help kanom}, 
{help kalpha}, {help krippalpha}, {help kapssi}, {help concord}, 
{help entropyetc}
{p_end}
