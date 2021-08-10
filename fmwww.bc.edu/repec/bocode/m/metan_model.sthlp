{smcl}
{* *! version 4.02  David Fisher  23feb2021}{...}
{vieweralsosee "metan" "help metan"}{...}
{vieweralsosee "metan_binary" "help metan_binary"}{...}
{vieweralsosee "metan_continuous" "help metan_continuous"}{...}
{vieweralsosee "metan_proportion" "help metan_proportion"}{...}
{vieweralsosee "forestplot" "help forestplot"}{...}
{vieweralsosee "metani" "help metani"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "ipdmetan" "help ipdmetan"}{...}
{vieweralsosee "ipdover" "help ipdover"}{...}
{vieweralsosee "metaan" "help metaan"}{...}
{vieweralsosee "metandi" "help metandi"}{...}
{vieweralsosee "metaprop_one" "help metaprop_one"}{...}
{viewerjumpto "Syntax" "metan_model##syntax"}{...}
{viewerjumpto "Description" "metan_model##description"}{...}
{viewerjumpto "Options" "metan_model##options"}{...}
{viewerjumpto "References" "metan_model##refs"}{...}
{hi:help metan_model}
{hline}

{title:Title}

{phang}
{it:model_spec} {hline 2} Specify models and methods for meta-analytic pooling of aggregate (summary) data with {bf:{help metan}},
including estimation of heterogeneity statistics


{marker syntax}{...}
{title:Syntax}

{pstd}
{it:model_spec} is:

{pmore2}
{cmd:model(} {it:model} [ {cmd:\} {it:model} [ {cmd:\} {it:model} [...]]] {cmd:)} [ {it:{help metan_model##options_het:options_het}} ]

{pmore}
where {it:model} is either:

{pmore2}
{it:{help metan_model##model_name:model_name}} [ {cmd:,} {it:{help metan_model##options_model:options_model}}
{it:{help metan_model##options_test:options_test}} {it:{help metan_model##options_label:options_label}} ]

{pmore}
or {it:model} is:

{pmore2}
{it:user_spec} [ {cmd:,} {it:{help metan_model##options_label:options_label}} ]

{pmore}
where {it:user_spec} is {it:ES lci uci}, representing a pooled effect size estimate and 95% confidence limits
which are supplied manually rather than estimated from the data.



{marker model_name}{...}
{synoptset 24 tabbed}{...}
{synopthdr :model_name}
{synoptline}
{pstd}
Note: references for particular models may be found in {help metan_model##refs:Fisher 2015}
if not specifically referenced below.{p_end}

{syntab :Methods applicable to {help metan_binary:two-group comparison of binary outcomes} only}
{synopt :{opt mh:aenszel}}Mantel-Haenszel model (default){p_end}
{synopt :{opt peto}}common-effect pooling of Peto odds ratios{p_end}

{syntab :Tau-squared estimators for standard inverse-variance random-effects model}
{synopt :{opt iv:common} | {opt fe} | {opt fixed}}Common (aka "fixed") effect inverse-variance (default unless two-group comparison of binary outcomes){p_end}
{synopt :{opt random} | {opt re} | {opt dl:aird}}DerSimonian-Laird estimator{p_end}
{synopt :{opt bdl} | {opt dlb}}Bootstrap DerSimonian-Laird estimator{p_end}
{synopt :{opt he:dges}}Hedges estimator aka "Cochran ANOVA-like" aka "variance component" estimator{p_end}
{synopt :{opt mp:aule} | {opt eb:ayes}}Mandel-Paule aka "empirical Bayes" estimator{p_end}
{synopt :{opt ml:e}}Maximum likelihood (ML) estimator{p_end}
{synopt :{opt reml}}Restricted maximum likelihood (REML) estimator{p_end}
{synopt :{opt hm:akambi}}Hartung-Makambi estimator ({help metan_model##refs:Hartung and Makambi 2003}){p_end}
{synopt :{opt b0} {opt bp}}Rukhin B0 and BP estimators{p_end}
{synopt :{opt sj2s} [, {help metan_model##options_model:{bf:init(}{it:model_name}{bf:)}}]}Sidik-Jonkman two-step estimator{p_end}
{synopt :{opt dk2s} [, {help metan_model##options_model:{bf:init(}{it:model_name}{bf:)}}]}DerSimonian-Kacker two-step estimator ({help metan_model##refs:DerSimonian and Kacker 2007}){p_end}
{synopt :{opt sa} [, {help metan_model##options_model:{bf:isq(}{it:real}{bf:) tausq(}{it:real}{bf:)}}]}Sensitivity analysis with user-defined I-squared or tau-squared{p_end}

{syntab :Non-standard models, or modifications to standard models}
{synopt :{opt hk:sj} [, {help metan_model##options_model:{bf:{ul:tru}ncate(one} | {bf:zovert)}}]}Hartung-Knapp-Sidik-Jonkman (HKSJ) variance correction to DerSimonian-Laird estimator{p_end}
{synopt :{opt pl} [, {help metan_model##options_model:{bf:{ul:ba}rtlett {ul:sk}ovgaard}}]}Estimation using profile likelihood{p_end}
{synopt :{opt kr:oger} [, {help metan_model##options_model:{bf:eim oim}}]}Kenward-Roger variance-corrected REML model ({help metan_model##refs:Morris et al 2018}){p_end}
{synopt :{opt bt:weedie}}Biggerstaff-Tweedie approximate Gamma model{p_end}
{synopt :{opt hc:opas}}Henmi-Copas approximate Gamma model ({help metan_model##refs:Henmi and Copas 2010}){p_end}
{synopt :{opt mu:lt}}Multiplicative heterogeneity model ({help metan_model##refs:Thompson and Sharp 1999}){p_end}
{synopt :{opt ivh:et}}"Inverse-variance heterogeneity" (IVhet) model ({help metan_model##refs:Doi et al 2015a}){p_end}
{synopt :{opt qe} [, {help metan_model##options_model:{bf:qwt(}{it:varname}{bf:)}}]}Quality Effects model ({help metan_model##refs:Doi et al 2015b}){p_end}
{synoptline}


{marker options_model}{...}
{synopthdr :options_model}
{synoptline}
{synopt :{opt wgt(varname)}}specify a variable containing user-defined weights, as described under {it:{help metan##options_main:options_main}},
but applicable to a specific model{p_end}
{synopt :{opt hk:sj}}Hartung-Knapp-Sidik-Jonkman (HKSJ) variance correction, applicable to any standard tau-squared estimator{p_end}
{synopt :{opt ro:bust}}Sidik-Jonkman robust (sandwich-like) variance estimator ({help metan_model##refs:Sidik and Jonkman 2006}){p_end}

{syntab :Model-specific options (see {it:{help metan_model##model_name:model_name}})}
{synopt :{opt init(model_name)}}initial estimate of tau-squared for two-step estimators {opt sj2s} and {opt dk2s}{p_end}
{synopt :{opt isq(real)} {opt tausq(real)}}user-defined I-squared or tau-squared values for use with sensitivity analysis {opt sa}{p_end}
{synopt :{opt tru:ncate}{cmd:(one} | {cmd:zovert)}}optional truncation of the Hartung-Knapp-Sidik-Jonkman correction factor{p_end}
{synopt :{opt ba:rtlett} {opt sk:ovgaard}}Bartlett's ({help metan_model##refs:Huizenga et al 2011})
or Skovgaard's ({help metan_model##refs:Guolo 2012}) corrections to the likelihood, for use with the profile-likelihood model {opt pl}{p_end}
{synopt: {opt eim} {opt oim}}use expected (default) or observed information matrix to compute degrees of freedom for Kenward-Roger model {opt kroger}
({help metan_model##refs:Morris et al 2018}){p_end}
{synopt :{opt qwt(varname)}}variable containing Quality Effect weights (model {cmd:qe} only; see {help metan_model##refs:Doi et al 2015b}){p_end}

{syntab :Options for iteration, replication or numerical integration}
{synopt :{opt itol(#)}}tolerance for iteration convergence (with {opt mpaule}, {opt mle}, {opt reml}, {opt pl}, {opt kroger}, {opt btweedie} or {opt hcopas}){p_end}
{synopt :{opt maxit:er(#)}}maximum number of iterations (as above){p_end}
{synopt :{opt maxt:ausq(#)}}upper bound of search for tau-squared confidence limits; may need to be raised in extreme cases (as above){p_end}
{synopt :{opt difficult} {opt technique(algorithm_spec)}}likelihood maximisation options; see {help maximize:help maximize}{p_end}
{synopt :{opt quadpts(#)}}number of quadrature points to use in numerical integration (with {opt bt} or {opt hc}; see help for {bf:{help integrate}}){p_end}
{synopt :{opt reps(#)}}number of replications for Bootstrap DerSimonian-Laird estimator (with {opt bdl}){p_end}
{synoptline}


{marker options_test}{...}
{synopthdr :options_test}
{synoptline}
{synopt :{opt z} {opt t} {opt chi2} {opt cmh}}specify test statistic for significance of pooled result{p_end}
{synoptline}


{marker options_het}{...}
{synopthdr :options_het}
{synoptline}
{syntab :Homogeneity test statistic}
{synopt :{opt coch:ranq}}Cochran's Q statistic (default, unless Mantel-Haenszel){p_end}
{synopt :{opt bre:slow}}Breslow-Day test for homogeneity of odds ratios (Mantel-Haenszel only){p_end}
{synopt :{opt ta:rone}}Breslow-Day-Tarone test for homogeneity of odds ratios
(Mantel-Haenszel only; preferred to {opt breslow}, see e.g. {help metan_model##refs:Breslow 1996}){p_end}

{syntab :Heterogeneity confidence intervals}
{synopt :{opt hl:evel(#)}}set confidence level for reporting confidence intervals for heterogeneity; default is {cmd:hlevel(95)}{p_end}
{synopt :{opt isqp:aram}}define {it:I}-squared parametrically, based on variance considerations; see below{p_end}
{synopt :{opt testb:ased}}use alternative test-based confidence interval for {it:H} ({help metan_model##refs:Higgins and Thompson 2002}){p_end}
{synoptline}


{marker options_label}{...}
{synopthdr :options_label}
{synoptline}
{synopt :{opt label(sting)}}specify alternative display label for a model{p_end}
{synopt :{opt extralabel(string)}}optional further description, for display within the forest plot only{p_end}
{synoptline}



{marker description}{...}
{title:Description}

{pstd}
{it:model_spec} specifies method(s) for meta-analytic pooling with {bf:{help metan}}.
If no {it:model_spec} is supplied, the default for two-group comparison of binary outcomes is {opt mh:aenszel};
otherwise the default is {opt iv:common}.

{pstd}
{it:model_spec} allows the results of multiple different pooling methods (or variations of methods) to be displayed simultaneously.
Such methods include alternative estimators of the between-study heterogeneity (tau-squared),
methods which correct {it:post hoc} the variance of the pooled estimate, or those which use alternative weighting systems
in order to improve statistical performance in the suspected presence of publication bias; see {it:{help metan_model##model_name:model_name}}.

{pstd}
Furthermore, the {it:user_spec} syntax allows pooled effect estimates from sources external to {cmd:metan}
- such as WinBUGS ({help metan_model##refs:Lunn et al 2000}), or one-stage modelling - to be displayed alongside the usual {cmd:metan} output on-screen and in the forest plot.
Note that:

{pmore}
If displayed study estimates and non-user-defined pooled effect estimates are exponentiated
(either via explicit use of {opt eform}, or by default e.g. with binary data),
then the elements of {it:user_spec} will also be exponentiated prior to display.

{pmore}
If {it:user_spec} is specified as the first {it:{help metan_model##syntax:model}} element, then {opt wgt(varname)} must also be supplied.

{pmore}
{it:user_spec} cannot be used to specify subgroup effect estimates.
Therefore, {opt by()} may not be used if {it:user_spec} is specified as the first {it:{help metan_model##syntax:model}} element.
Similarly, if {it:user_spec} is specified {ul:other} than as the first {it:{help metan_model##syntax:model}} element,
it will be ignored when printing subgroup estimates and tests.

{pmore}
All previous syntax of {cmd:metan} {help metan##diffs_metan:v3.04 for Stata v9} relating to model specification continues to be supported,
including options {opt first()}, {opt firststats()}, {opt second()} and {opt secondstats()}.
(These are implemented as special cases of {it:{help metan_model##syntax:model_spec}} with {it:{help metan_model##options_label:options_label}}.)

{pmore}
Another, more flexible, way of incorporating user-supplied estimates and/or text is to use {cmd:forestplot} "results sets"; see {bf:{help forestplot}}.

{pstd}
Underneath the table of study effects, {bf:{help metan}} reports a homogeneity test, typically based on Cochran's {it:Q} statistic;
plus the following heterogeneity statistics defined in terms of {it:Q} and its degrees of freedom {it:Q_df} as follows:

{pmore}
{it:H} = {bf:sqrt(}{it:Q} / {it:Q_df}{bf:)}, and {it:I}^2 = 100% * {bf:(}{it:Q} - {it:Q_df}{bf:)} / {it:Q}

{pstd}
Following {help metan_model##refs:Hedges and Pigott (2001)}, when the null hypothesis of homogeneity is {ul:not} true,
the homogeneity statistic (e.g. Cochran's {it:Q}) may be considered approximately to follow a non-central chi-square distribution
if under a common-effect model, or a Gamma distribution (incorporating the DerSimonian-Laird estimator of tau-squared)
if under a random-effects model.
{bf:{help metan}} uses these distributions to construct confidence intervals, based on observed data, for the heterogeneity statistics {it:H} and {it:I}-squared.

{pmore}
Note that some minor variation in the way {cmd:metan} presents heterogeneity statistics may result depending on the model(s) specified.
If more than one model is specified, heterogeneity statistics are presented consistent with the {ul:first} model only.

{pstd}
{help metan:Click here} to return to the main {bf:{help metan}} help page.



{marker options}{...}
{title:Options}

{it:{dlgtab:options_model}}

{phang}
{opt hksj} applies the Hartung-Knapp-Sidik-Jonkman (HKSJ) variance correction to any standard tau-squared estimator;
that is, in the absense of other variance correction or re-weighting mechanisms.
{opt hksj} may instead be supplied as {it:model_name}, in which case the DerSimonian-Laird estimator is implied.

{pmore}
By default, the correction factor is untruncated.
This means that, if its value is less than one, the confidence interval around the pooled effect may be less conservative
than under a model without the HKSJ correction being applied.
In that case, a warning message is printed underneath the results table, recommending that the {opt truncate()} option is used.

{phang2}
{cmd:truncate(one)} truncates the HKSJ correction factor at one ({help metan_model##refs:Jackson et al 2017}).

{phang2}
{cmd:truncate(zovert)} applies a less conservative truncation ({help metan_model##refs:van Aert et al 2019})
under which the correction factor is compared to the ratio of the {it:z}-based to the {it:t}-based critical values.

{phang}
{opt isq(real)} or {opt tausq(real)} impose a user-specified amount of heterogeneity for use with the sensitivity-analysis model {opt sa}.
At most one of these options may be used.
If neither is used, a value for {it:I}-squared of 80% is taken as the default.
A random-effects model is then fitted, with tau-squared constrained accordingly.
Accompanying heterogeneity statistics are calculated based on tau-squared and sigma-squared using formulae presented in {help metan_model##refs:Higgins and Thompson (2002)}.

{phang2}
{opt isq(real)} constrains the value of {it:I}-squared, and takes values between 0 and 100.
A value for tau-squared is back-derived in order for the random-effects model to be fitted.

{phang2}
{opt tausq(real)} constrains the value of tau-squared, and takes values of zero or above.

{phang}
{opt init(model_name)} specifies an initial estimate of tau-squared for "two-step" estimation models {opt sj2s} and {opt dk2s}.

{phang2}
For the Sidik-Jonkman two-step estimator {opt sj2s}, the default initial estimate
is the mean dispersion of effect sizes from their unweighted mean ({help metan_model##refs:Sidik and Jonkman 2005});
any standard tau-squared estimator {it:{help metan_model##model_name:model_name}} may instead be used.

{phang2}
For the DerSimonian-Kacker two-step estimator {opt dk2s}, the default initial {it:{help metan_model##model_name:model_name}} is {opt hedges},
with the single alternative of {opt dlaird}.{p_end}

{phang}
{opt bartlett} and {opt skovgaard} are options for use with the profile-likelihood model {opt pl}.
These apply small-sample corrections to the likelihood, designed to improve performance when the number of studies is small.

{phang2}
{opt bartlett} implements Bartlett's correction ({help metan_model##refs:Huizenga et al 2011}).
This is applied to the likelihood-ratio statistic,
and therefore a chi-squared test statistic is presented by default for the pooled estimate,
displayed as "LR chi2" to differentiate from a standard (non-likelihood based) chi-squared statistic.

{phang2}
{opt skovgaard} implements Skovgaard's correction ({help metan_model##refs:Guolo 2012}).
This is applied to the signed {ul:log}-likelihood ratio statistic,
and therefore a z-based test statistic is presented, displayed as "LL z" to differentiate from a standard Wald-type statistic.


{it:{dlgtab:options_test}}

{pstd}
{it:options_test} can be {opt z}, {opt t} or {opt chi2} (or {opt cmh}; see below).
These options specify a distribution for testing the significance of the pooled result.
The default is usually {opt z}, but is {opt t} with {opt hksj} or {opt robust}, and is {opt chi2} with {opt mhaenszel}, {opt peto} or {opt pl}.
Any of {opt z}, {opt t} or {opt chi2} may be specified to override these defaults.

{pstd}
Additionally, with Mantel-Haenszel odds ratios only, the Cochran-Mantel-Haenszel test statistic ({help metan_model##refs:McDonald 2014})
may be requested with option {opt cmh}.


{it:{dlgtab:options_het}}

{phang}
{opt cochranq}, {opt breslow} and {opt tarone} are used to over-ride the default choice of homogeneity statistic.
The default is usually {opt cochranq}; that is, the standard Cochran's {it:Q} statistic
using common-effect inverse-variance weighting and pooled effect size ({help metan_model##refs:Deeks et al 2001}).
When using alternative common-effect models {opt mhaenszel} or {opt peto}, the default homogeneity statistic changes
to incorporate the study weighting and pooled effect size derived from the specified model;
in the Display Window and forest plot the description becomes "Mantel-Haenszel Q" or "Peto Q" as appropriate.

{phang2}
{opt breslow} and {opt tarone} are applicable only with Mantel-Haenszel odds ratios.
{opt breslow} specifies the Breslow-Day homogeneity statistic ({help metan_model##refs:Breslow and Day 1980}).
Although widely used, this statistic is unnecessarily approximate;
{opt tarone} instead specifies the superior Breslow-Day-Tarone statistic ({help metan_model##refs:Breslow 1996}).

{phang}
{opt testbased} requests that an alternative, test-based method of constructing confidence intervals for {it:H} and {it:I}-squared is used
({help metan_model##refs:Higgins and Thompson 2002}), instead of the default intervals
based on an approximate distribution for {it:Q} under the assumption that the null hypothesis of homogeneity is false.

{phang}
{opt isqparam} requests that {cmd:metan} presents heterogeneity statistics based upon variance considerations.
That is, {it:I}-squared is to be defined parametrically based on the within-study variance tau-squared as estimated from a random-effects model,
rather than on a homogeneity statistic calculated directly from the data.
In the notation of {help metan_model##refs:Higgins and Thompson (2002)}:  {it:I}^2 = {it:tau}^2 / ({it:tau}^2 + {it:sigma}^2)
instead of the default {it:I}^2 = ({it:Q} - {it:Q_df}) / {it:Q}.
Confidence intervals for {it:I}-squared may be derived similarly, using model-derived confidence limits for tau-squared.
(Estimates and confidence intervals for {it:H} may also be derived in this way; these are not shown in the Display Window
but are returned within the matrix {cmd:r(hetstats)}.)

{pmore}
If multiple models are requested (see {it:{help metan_model##syntax:model_spec}}) alongside {opt isqparam}, then potentially
there will be multiple sets of heterogeneity statistics, each associated with a model-derived estimate of tau-squared.
This information is displayed in an additional table in the Results Window; and if a forest plot is presented,
then a set of heterogeneity information is displayed in brackets alongside the name of each individual model.


{it:{dlgtab:options_label}}

{phang}
{opt label(label_string)} specifies an alternative display label for a particular model.
For example, the default label for the DerSimonian-Laird random-effects model is "DL",
but the simpler label "Random" might be preferred if no other random-effects models are used.
{cmd:label(}""{cmd:)} will suppress the label entirely.

{pmore}
If {it:user_spec} is used without {opt label(label_string)}, the default {it:label_string} is "User".

{phang}
{opt extralabel(extra_string)} optionally specifies further descriptive text
to appear on the forest plot in place of the standard heterogeneity text; {it:extra_string} is not displayed in the Results Window.
This option is designed for use alongside {it:user_spec}, for example to display externally-derived parameters related to study heterogeneity.



{title:Authors}

{pstd}
Original authors:
Michael J Bradburn, Jonathan J Deeks, Douglas G Altman.
Centre for Statistics in Medicine, University of Oxford, Oxford, UK

{pstd}
{cmd:metan} v3.04 for Stata v9:
Ross J Harris, Roger M Harbord, Jonathan A C Sterne.
Department of Social Medicine, University of Bristol, Bristol, UK

{pstd}
Current version, {cmd:metan} v4.02:
David Fisher, MRC Clinical Trials Unit at UCL, London, UK.

{pstd}
Email {browse "mailto:d.fisher@ucl.ac.uk":d.fisher@ucl.ac.uk}



{title:Acknowledgments}

{pstd}
Thanks to Patrick Royston (MRC Clinical Trials Unit at UCL, London, UK) for suggestions of improvements to the code and help file.

{pstd}
Thanks to Vince Wiggins, Kit Baum and Jeff Pitblado of Statacorp who offered advice and helped facilitate the version 9 update.

{pstd}
Thanks to Julian Higgins and Jonathan A C Sterne (University of Bristol, Bristol, UK) who offered advice and helped facilitate this latest update,
and thanks to Daniel Klein (Universit{c a:}t Kassel, Germany) for assistance with testing under older Stata versions.

{pstd}
The "click to run" element of the examples in this document is handled using an idea originally developed by Robert Picard.



{marker refs}{...}
{title:References}

{phang}
Breslow NE, Day NE. 1980. Statistical Methods in Cancer Research: Vol. I - The Analysis of Case-Control Studies.
Lyon: International Agency for Research on Cancer.

{phang}
Breslow NE. 1996.
Statistics in epidemiology: The case-control study.
Journal of the American Statistical Association 91: 14-28

{phang}
Deeks JJ, Altman DG, Bradburn MJ. 2001.
Statistical methods for examining heterogeneity and combining results from several studies in meta-analysis.
In Systematic Reviews in Health Care: Meta-analysis in Context, ed. Egger M, Davey Smith G, Altman DG, 2nd ed., 285-312. London: BMJ Books.

{phang}
DerSimonian R, Kacker R. 2007.
Random-effects model for meta-analysis of clinical trials: An update.
Contemporary Clinical Trials 28: 105-114. doi: 10.1016/j.cct.2006.04.004

{phang}
Doi SAR, Barendregt JJ, Khan S, Thalib L, Williams GM. 2015a.
Advances in the meta-analysis of heterogeneous clinical trials I: The inverse variance heterogeneity model.
Contemporary Clinical Trials 45: 130-138

{phang}
Doi SAR, Barendregt JJ, Khan S, Thalib L, Williams GM. 2015b.
Advances in the meta-analysis of heterogeneous clinical trials II: The quality effects model.
Contemporary Clinical Trials 45: 123-129

{phang}
Fisher DJ. 2015.
Two-stage individual participant data meta-analysis and generalized forest plots.
Stata Journal 15: 369-396

{phang}
Guolo A. 2012.
Higher-order likelihood inference in meta-analysis and meta-regression.
Statistics in Medicine 31: 313-327. doi: 10.1002/sim.4451

{phang}
Hartung J, Makambi KH. 2003.
Reducing the number of unjustified significant results in meta-analysis.
Communications in Statistics - Simulation and Computation 32: 1179-1190. doi: 10.1081/SAC-120023884

{phang}
Hedges LV, Pigott TD. 2001.
The power of statistical tests in meta-analysis.
Psychological Methods 6: 203-217. doi: 10.1037/1082-989X.6.3.203

{phang}
Henmi M, Copas JB. 2010.
Confidence intervals for random effects meta-analysis and robustness to publication bias.
Statistics in Medicine 29: 2969-2983. doi: 10.1002/sim.4029

{phang}
Higgins JPT, Thompson SG. 2002.
Quantifying heterogeneity in a meta-analysis.
Statistics in Medicine 21: 1539-1558

{phang}
Huizenga HM, Visser I, Dolan CV. 2011.
Testing overall and moderator effects in random effects meta-regression.
British Journal of Mathematical and Statistical Psychology 64: 1-19

{phang}
Jackson D, Law M, R{c u:}cker G, Schwarzer G. 2017.
The Hartung-Knapp modification for random-effects meta-analysis: A useful refinement but are there any residual concerns?
Statistics in Medicine 2017; 36: 3923–3934. doi: 10.1002/sim.7411

{phang}
Lunn DJ, Thomas A, Best N, Spiegelhalter D. 2000.
WinBUGS -- a Bayesian modelling framework: concepts, structure, and extensibility.
Statistics and Computing 10: 325-337

{phang}
McDonald JH. 2014.
Handbook of Biological Statistics, 3rd ed.
Sparky House Publishing, Baltimore, Maryland

{phang}
Morris TP, Fisher DJ, Kenward MG, Carpenter JR. 2018.
Meta-analysis of quantitative individual patient data: two stage or not two stage?
Statistics in Medicine. doi: 10.1002/sim.7589

{phang}
Sidik K, Jonkman JN. 2005.
Simple heterogeneity variance estimation for meta-analysis.
Journal of the Royal Statistical Society, Series C 54: 367-384

{phang}
Sidik K, Jonkman JN. 2006.
Robust variance estimation for random effects meta-analysis.
Computational Statistics & Data Analysis 50: 3681-3701. doi: 10.1016/j.csda.2005.07.019

{phang}
Thompson SG, Sharp SJ. 1999.
Explaining heterogeneity in meta-analysis: a comparison of methods.
Statistics in Medicine 18: 2693-2708

{phang}
van Aert RCM, Jackson D. 2019.
A new justification of the Hartung-Knapp method for random-effects meta-analysis
based on weighted least squares regression.
Research Synthesis Methods 10: 515-527. doi: 10.1002/jrsm.1356

{phang}
Viechtbauer W. 2007.
Confidence intervals for the amount of heterogeneity in meta-analysis.
Statistics in Medicine 26: 37-52. doi: 10.1002/sim.2514
