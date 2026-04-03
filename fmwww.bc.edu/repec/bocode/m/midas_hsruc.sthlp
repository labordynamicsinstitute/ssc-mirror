{smcl}
{* *! version 1.0.0  30mar2026}{...}
{vieweralsosee "[R] midas" "help midas"}{...}
{vieweralsosee "[R] midas mle" "help midas_mle"}{...}
{vieweralsosee "[R] midas fagan" "help midas_fagan"}{...}
{vieweralsosee "[R] midas condiplot" "help midas_condiplot"}{...}
{viewerjumpto "Syntax" "midas_hsruc##syntax"}{...}
{viewerjumpto "Description" "midas_hsruc##description"}{...}
{viewerjumpto "Options" "midas_hsruc##options"}{...}
{viewerjumpto "Examples" "midas_hsruc##examples"}{...}
{viewerjumpto "Stored results" "midas_hsruc##results"}{...}
{viewerjumpto "Methods" "midas_hsruc##methods"}{...}
{viewerjumpto "References" "midas_hsruc##references"}{...}
{viewerjumpto "Author" "midas_hsruc##author"}{...}

{title:Title}

{phang}
{bf:midas hsruc} {hline 2} Hierarchical Summary Relative Utility Curve Analysis
        for diagnostic test accuracy meta-analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas_hsruc}
[{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth prev:alence(#)}}disease prevalence in target population (0 < # < 1){p_end}

{syntab:Threshold grid}
{synopt:{opth thr:esholds(numlist)}}custom threshold probabilities{p_end}
{synopt:{opt np:oints(#)}}number of equispaced grid points; default is 99{p_end}

{syntab:Utility metrics}
{synopt:{opt mrs}}compute Mean Risk Stratification (Katki 2019){p_end}
{synopt:{opt nbgain}}compute net benefit gain over treat-all{p_end}
{synopt:{opt inb}}compute incremental net benefit{p_end}
{synopt:{opt allmetrics}}compute all utility metrics{p_end}
{synopt:{opt optimal}}identify optimal cost-effective threshold{p_end}

{syntab:Cost-effectiveness (for INB)}
{synopt:{opth screencost(#)}}cost of screening test; default is 0{p_end}
{synopt:{opth treatcost(#)}}cost of treatment; default is 0{p_end}
{synopt:{opth lyg(#)}}life-years gained per true positive; default is 1{p_end}

{syntab:Prediction}
{synopt:{opt pred:iction}}compute 95% prediction intervals for utility using
        between-study heterogeneity{p_end}

{syntab:Reporting}
{synopt:{opt level(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt notable}}suppress detailed output table{p_end}
{synopt:{opt nograph}}suppress graphical output{p_end}
{synopt:{opth saving(filename)}}save utility curve data to {it:filename}{p_end}
{synoptline}

{pstd}
{cmd:midas_hsruc} is a post-estimation command.  It must follow a MIDAS
estimation command: {cmd:midas mle}, {cmd:midas mh}, {cmd:midas hmc}, or
{cmd:midas inla}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas_hsruc} derives the Hierarchical Summary Relative Utility Curve
(HSRUC) from the bivariate random-effects model estimates stored by a prior
MIDAS estimation command.  It translates the summary sensitivity, specificity,
and likelihood ratios into decision-analytic metrics that quantify the
clinical value of a diagnostic test across a range of threshold probabilities.

{pstd}
The command produces six families of output:

{phang2}1. {bf:Net benefit} (Vickers and Elkin 2006): the number of true positives
per patient examined, net of the harm from false positives, at each threshold
probability.{p_end}

{phang2}2. {bf:Relative utility} (Baker et al. 2009): net benefit normalised by
the maximum achievable (perfect-test) net benefit, yielding a 0-to-1 scale.
The area under this curve (WAU-HSRUC) provides a single-number summary of
clinical utility.{p_end}

{phang2}3. {bf:Standardised net benefit}: equivalent to relative utility; at the
treatment threshold equal to prevalence, sNB equals the Youden index.{p_end}

{phang2}4. {bf:Mean Risk Stratification} (Katki 2019): the test's ability to
separate patients into distinct risk groups.{p_end}

{phang2}5. {bf:Incremental net benefit} (Katki and Bebu 2021): net benefit
adjusted for screening and treatment costs.{p_end}

{phang2}6. {bf:Prediction intervals}: the range of utility expected in a new
clinical setting, reflecting between-study heterogeneity.{p_end}

{pstd}
A four-panel graph is produced by default: Decision Curve, HSRUC (Relative
Utility), Net Benefit Gain, and Number Needed to Test.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth prevalence(#)} specifies the disease prevalence in the target clinical
population.  This is required because predictive values, net benefit, and all
derived utility metrics depend on prevalence.  If omitted, the command attempts
to use the median prevalence stored by the estimation command.

{dlgtab:Threshold grid}

{phang}
{opth thresholds(numlist)} specifies a custom list of threshold probabilities
at which utility metrics are evaluated.  Values must be strictly between 0
and 1.  If not specified, an equispaced grid of {opt npoints()} values is
generated.

{phang}
{opt npoints(#)} specifies the number of equispaced grid points for the
threshold probability axis.  Default is 99, yielding thresholds at 0.01,
0.02, ..., 0.99.

{dlgtab:Utility metrics}

{phang}
{opt mrs} computes the Mean Risk Stratification statistic (Katki 2019),
which measures the test's ability to assign patients to meaningfully different
risk categories.

{phang}
{opt nbgain} computes the net benefit gain of the test strategy over the
treat-all strategy at each threshold.

{phang}
{opt inb} computes the Incremental Net Benefit (Katki and Bebu 2021),
which incorporates screening and treatment costs.  Requires {opt screencost()},
{opt treatcost()}, and optionally {opt lyg()}.

{phang}
{opt allmetrics} is equivalent to specifying {opt mrs}, {opt nbgain},
{opt inb}, and {opt optimal} simultaneously.

{phang}
{opt optimal} identifies the threshold probability that maximises net benefit.

{dlgtab:Cost-effectiveness}

{phang}
{opth screencost(#)} specifies the cost of the screening/diagnostic test
per patient.  Used only with {opt inb}.

{phang}
{opth treatcost(#)} specifies the cost of treatment per patient.  Used only
with {opt inb}.

{phang}
{opth lyg(#)} specifies the life-years gained per true positive treated.
Default is 1.  Used only with {opt inb}.

{dlgtab:Prediction}

{phang}
{opt prediction} computes 95% prediction intervals for sensitivity,
specificity, and net benefit in a hypothetical new clinical setting.  These
intervals reflect between-study heterogeneity (tau1, tau2) and are always
wider than confidence intervals for the summary estimates.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level for intervals.  Default is 95.

{phang}
{opt notable} suppresses the detailed table of utility metrics at selected
thresholds.

{phang}
{opt nograph} suppresses the four-panel combined graph.

{phang}
{opth saving(filename)} saves the full utility curve dataset (one row per
threshold) to {it:filename}.  Variables saved include: {cmd:pt} (threshold),
{cmd:nb} (net benefit), {cmd:ru} (relative utility), {cmd:snb} (standardised
NB), {cmd:nnt} (number needed to test), {cmd:mrs_v} (MRS), and {cmd:inb_v}
(INB).


{marker examples}{...}
{title:Examples}

{pstd}Setup: fit bivariate model first{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/m/midas_example_data.dta, clear}{p_end}
{phang2}{cmd:. gen study = _n}{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(study) hetstats hsroc}{p_end}

{pstd}Basic HSRUC at 20% prevalence{p_end}
{phang2}{cmd:. midas_hsruc, prevalence(0.20)}{p_end}

{pstd}All metrics with prediction intervals{p_end}
{phang2}{cmd:. midas_hsruc, prevalence(0.20) allmetrics prediction}{p_end}

{pstd}Cost-effectiveness analysis{p_end}
{phang2}{cmd:. midas_hsruc, prevalence(0.15) inb screencost(50) treatcost(5000) lyg(3)}{p_end}

{pstd}After Bayesian estimation{p_end}
{phang2}{cmd:. midas mh tp fp fn tn, id(study) covariance(cholesky) chains(4) mcsize(20000)}{p_end}
{phang2}{cmd:. midas_hsruc, prevalence(0.30) prediction}{p_end}

{pstd}Custom thresholds and save data{p_end}
{phang2}{cmd:. midas_hsruc, prevalence(0.25) thresholds(0.05 0.10 0.15 0.20 0.30 0.50) saving(utility.dta)}{p_end}

{pstd}Suppress graph, display table only{p_end}
{phang2}{cmd:. midas_hsruc, prevalence(0.20) nograph}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:midas_hsruc} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of studies{p_end}
{synopt:{cmd:e(prevalence)}}target prevalence{p_end}
{synopt:{cmd:e(Se)}}summary sensitivity{p_end}
{synopt:{cmd:e(Sp)}}summary specificity{p_end}
{synopt:{cmd:e(LRp)}}positive likelihood ratio{p_end}
{synopt:{cmd:e(LRn)}}negative likelihood ratio{p_end}
{synopt:{cmd:e(DOR)}}diagnostic odds ratio{p_end}
{synopt:{cmd:e(youden)}}Youden index (Se + Sp - 1){p_end}
{synopt:{cmd:e(alpha)}}HSROC accuracy parameter{p_end}
{synopt:{cmd:e(theta)}}HSROC threshold parameter{p_end}
{synopt:{cmd:e(beta)}}HSROC asymmetry parameter{p_end}
{synopt:{cmd:e(s2alpha)}}variance of accuracy{p_end}
{synopt:{cmd:e(s2theta)}}variance of threshold{p_end}
{synopt:{cmd:e(wau_hsruc)}}weighted area under HSRUC (0 = useless, 1 = perfect){p_end}
{synopt:{cmd:e(auc_nb)}}area under net benefit curve{p_end}
{synopt:{cmd:e(opt_pt)}}optimal threshold probability{p_end}
{synopt:{cmd:e(max_nb)}}maximum net benefit{p_end}
{synopt:{cmd:e(pt_low)}}lower bound of positive-NB range{p_end}
{synopt:{cmd:e(pt_high)}}upper bound of positive-NB range{p_end}
{synopt:{cmd:e(useful_low)}}lower bound of test-useful range{p_end}
{synopt:{cmd:e(useful_high)}}upper bound of test-useful range{p_end}

{pstd}With {opt prediction}:{p_end}
{synopt:{cmd:e(pred_se_lo)}}prediction interval lower bound for Se{p_end}
{synopt:{cmd:e(pred_se_hi)}}prediction interval upper bound for Se{p_end}
{synopt:{cmd:e(pred_sp_lo)}}prediction interval lower bound for Sp{p_end}
{synopt:{cmd:e(pred_sp_hi)}}prediction interval upper bound for Sp{p_end}
{synopt:{cmd:e(nb_best)}}best-case NB at optimal threshold{p_end}
{synopt:{cmd:e(nb_worst)}}worst-case NB at optimal threshold{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:midas_hsruc}{p_end}
{synopt:{cmd:e(title)}}Hierarchical Summary Relative Utility Curve Analysis{p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{cmd:midas_hsruc} reads the bivariate model parameters from {cmd:e(b)} and
{cmd:e(bsum)} stored by a prior MIDAS estimation command and derives clinical
utility metrics as follows.

{pstd}
{bf:HSROC transformation.}  The bivariate parameters (mu1, mu2, tau1-squared,
tau2-squared, rho) are transformed to the Rutter-Gatsonis HSROC
parameterisation:

{pmore}
alpha = mu1 + mu2 (overall accuracy = log DOR){break}
theta = mu1 - mu2 (threshold){break}
beta = (tau1-squared - tau2-squared) / (tau1-squared + tau2-squared)
(asymmetry){break}
sigma-squared-alpha = tau1-squared + tau2-squared + 2*rho*tau1*tau2{break}
sigma-squared-theta = tau1-squared + tau2-squared - 2*rho*tau1*tau2

{pstd}
{bf:Net benefit} (Vickers and Elkin 2006).  At threshold probability pt with
prevalence pi:

{pmore}
NB(pt) = Se * pi - (1 - Sp)(1 - pi) * pt / (1 - pt)

{pstd}
{bf:Relative utility} (Baker et al. 2009):

{pmore}
RU(pt) = NB(pt) / pi

{pstd}
At pt = pi, RU equals the Youden index J = Se + Sp - 1.

{pstd}
{bf:WAU-HSRUC.}  The weighted area under the relative utility curve is computed
by trapezoidal integration of RU(pt) over the threshold grid.  WAU-HSRUC = 1
for a perfect test and 0 for a useless test.

{pstd}
{bf:Mean Risk Stratification} (Katki 2019):

{pmore}
MRS(pt) = pi * Se * (1 - pt) + (1 - pi) * Sp * pt

{pstd}
{bf:Incremental net benefit} (Katki and Bebu 2021):

{pmore}
INB = NB * LYG - ScreenCost / TreatCost

{pstd}
{bf:Prediction intervals.}  Under the bivariate model, a future study's true
accuracy is drawn from N(mu1, tau1-squared) and N(mu2, tau2-squared).  The
95% prediction interval for sensitivity is expit(mu1 +/- 1.96*tau1) and
analogously for specificity.  Best-case and worst-case net benefits are
computed at these prediction bounds.


{marker references}{...}
{title:References}

{phang}
Baker SG, Kramer BS, Srivastava S. 2009. Markers for early detection of
cancer: statistical guidelines for nested case-control studies.
{it:Medical Decision Making} 29: 247-256.

{phang}
Harbord RM, Deeks JJ, Egger M, Whiting P, Sterne JAC. 2007. A unification
of models for meta-analysis of diagnostic test accuracy studies.
{it:Biostatistics} 8: 239-251.

{phang}
Katki HA. 2019. Quantifying the clinical utility of genomic tests using mean
risk stratification. {it:Statistics in Medicine} 38: 2943-2955.

{phang}
Katki HA, Bebu I. 2021. Identifying the most useful markers by decision and
cost analysis. {it:Journal of the Royal Statistical Society, Series A}
184: 887-903.

{phang}
Reitsma JB, Glas AS, Rutjes AWS, Scholten RJPM, Bossuyt PM, Zwinderman AH.
2005. Bivariate analysis of sensitivity and specificity produces informative
summary measures in diagnostic reviews.
{it:Journal of Clinical Epidemiology} 58: 982-990.

{phang}
Rutter CM, Gatsonis CA. 2001. A hierarchical regression approach to
meta-analysis of diagnostic test accuracy evaluations.
{it:Statistics in Medicine} 20: 2865-2884.

{phang}
Vickers AJ, Elkin EB. 2006. Decision curve analysis: a novel method for
evaluating prediction models. {it:Medical Decision Making} 26: 565-574.

{phang}
Vickers AJ, van Calster B, Steyerberg EW. 2019. A simple, step-by-step
guide to interpreting decision curve analysis.
{it:Diagnostic and Prognostic Research} 3: 18.


{marker author}{...}
{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
Clinical Associate Professor Emeritus of Radiology{break}
Division of Nuclear Medicine and Molecular Imaging{break}
University of Michigan{break}
{browse "mailto:ben@bennybeaubooks.com":ben@bennybeaubooks.com}{break}
{browse "https://www.bennybeaubooks.com":www.bennybeaubooks.com}
{p_end}
