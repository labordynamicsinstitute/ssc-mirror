{smcl}
{* *! version 1.0.0  26jun2026  Dr Merwan Roudane}{...}
{vieweralsosee "xtlongestim postestimation" "help xtlongestim_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtpmg" "help xtpmg"}{...}
{vieweralsosee "xtmg" "help xtmg"}{...}
{vieweralsosee "xtpb" "help xtpb"}{...}
{viewerjumpto "Syntax" "xtlongestim##syntax"}{...}
{viewerjumpto "Description" "xtlongestim##description"}{...}
{viewerjumpto "Estimators" "xtlongestim##estimators"}{...}
{viewerjumpto "Options" "xtlongestim##options"}{...}
{viewerjumpto "Stored results" "xtlongestim##results"}{...}
{viewerjumpto "Examples" "xtlongestim##examples"}{...}
{viewerjumpto "References" "xtlongestim##references"}{...}
{viewerjumpto "Author" "xtlongestim##author"}{...}
{title:Title}

{phang}
{bf:xtlongestim} {hline 2} Long-run and mean-coefficient estimators with small-{it:T}
bias correction for dynamic heterogeneous panels


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtlongestim}
{depvar}
{it:indepvars}
{ifin}
[{cmd:,} {it:options}]

{pstd}
The data must be {helpb xtset}. The fitted model is the dynamic heterogeneous panel

{p 8 8 2}{it:y(it)} = {it:a(i)} + {it:lambda(i)} {it:y(i,t-1)} + {it:beta(i)'}{it:x(it)} + {it:e(it)}{p_end}

{pstd}
and the long-run coefficient of interest is {it:theta(i)} = {it:beta(i)}/(1 {c -} {it:lambda(i)}).
The lag of {depvar} is added automatically; {it:indepvars} are the contemporaneous regressors.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opth lr(varlist)}}regressors for which to report the long-run coefficient; default is all {it:indepvars}{p_end}
{synopt:{opt nocons:tant}}suppress the group-specific intercept{p_end}

{syntab:Methods}
{synopt:{opt m:ethods(list)}}estimators to compute; default {cmd:mg dbc1 dbc2 bsbc}{p_end}

{syntab:Bootstrap (bias terms, NBC, DBC, BSBC, bias-corrected MG)}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:400}{p_end}
{synopt:{opt seed(#)}}random-number seed; default {cmd:12345}{p_end}
{synopt:{opt para:metric}}parametric (Gaussian) bootstrap; default is residual resampling{p_end}

{syntab:Hierarchical Bayes (Gibbs sampler)}
{synopt:{opt burn:in(#)}}burn-in iterations; default {cmd:1000}{p_end}
{synopt:{opt draws(#)}}retained posterior draws; default {cmd:2000}{p_end}
{synopt:{opt rho(#)}}Wishart prior degrees-of-freedom scaling; default {cmd:2}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt nodots}}suppress the bootstrap / Gibbs progress dots{p_end}

{syntab:Visualisation}
{synopt:{opt graph}}produce publication-quality forest plots and a cross-panel heterogeneity caterpillar{p_end}
{synopt:{opt gname(stub)}}name stem for the stored graphs (default {cmd:xtle}){p_end}
{synopt:{opt export(name)}}write a journal-style results table to {it:name}{cmd:.tex} (LaTeX booktabs) and/or {it:name}{cmd:.csv}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtlongestim} unifies, in a single command, the estimators of the long-run and
mean short-run coefficients of dynamic heterogeneous panels developed in
{help xtlongestim##PZ:Pesaran and Zhao (1999)} and
{help xtlongestim##HPT:Hsiao, Pesaran and Tahmiscioglu (1999)}.

{pstd}
The mean group (MG) estimator of the long-run coefficient is consistent but, as both
papers show, can carry substantial bias when the time dimension {it:T} is small,
because of (a) the small-{it:T} bias of the short-run least-squares estimates of
{it:lambda(i)} and {it:beta(i)}, and (b) the nonlinearity of {it:beta/(1{c -}lambda)}.
{cmd:xtlongestim} implements the bias-reduction and Bayes shrinkage procedures
proposed to deal with this, several of which had not previously been available in Stata.


{marker estimators}{...}
{title:Estimators}

{pstd}
The estimators fall into two groups according to what they target and which output
table they fill. Choose them in {opt methods()}.
{p_end}

{p2colset 8 30 32 2}{...}
{p2col:{bf:LONG-RUN estimators}}target {it:theta}={it:beta}/(1{c -}{it:lambda}); fill the {bf:long-run} table/forest only{p_end}
{p2col:{space 3}{cmd:mg nbc dbc1 dbc2 bsbc}}{p_end}
{p2col:{bf:SHORT-RUN estimators}}target the mean {it:lambda} and {it:beta}; fill the {bf:mean short-run} table/forest (and report an implied long-run){p_end}
{p2col:{space 3}{cmd:pols mg bcmg ebayes hbayes}}{p_end}

{pstd}
So, {bf:to see short-run results (the speed-of-adjustment lambda and the impact beta) you
must request a short-run estimator} {c -} e.g. {cmd:methods(mg bcmg)}. The pure
long-run bias-corrections ({cmd:nbc}, {cmd:dbc1}, {cmd:dbc2}, {cmd:bsbc}) have no
short-run component by construction, so on their own they print only the long-run table.
The mean group ({cmd:mg}) belongs to {it:both} groups: it is the only estimator that
fills the long-run and the short-run tables at once. The shortcut {cmd:methods(all)}
runs everything; {cmd:methods(longrun)} and {cmd:methods(shortrun)} pick one group.
{p_end}

{pstd}{bf:Long-run coefficient} {it:theta} = {it:beta}/(1{c -}{it:lambda}):{p_end}

{p2colset 8 18 20 2}{...}
{p2col:{cmd:mg}}Mean group: average of the per-group ratios
{it:beta(i)}/(1{c -}{it:lambda(i)}). Variance by the Pesaran-Smith formula.{p_end}
{p2col:{cmd:nbc}}Naive bias-corrected: plug bias-corrected short-run coefficients
into the ratio, then average (Pesaran & Zhao, Section 3.1). Included as a benchmark;
the paper shows it generally over-corrects.{p_end}
{p2col:{cmd:dbc1}}Direct bias-corrected, formula (10) {c -} retains the higher-order
{it:O(T{c 94}-3/2)} term in the denominator. Best overall performer in the paper.{p_end}
{p2col:{cmd:dbc2}}Direct bias-corrected, formula (15).{p_end}
{p2col:{cmd:bsbc}}Bootstrap bias-corrected mean group, formula (20):
2*MG {c -} mean bootstrap MG.{p_end}

{pstd}{bf:Mean short-run coefficients} ({it:lambda}, {it:beta}):{p_end}

{p2colset 8 18 20 2}{...}
{p2col:{cmd:pols}}Pooled OLS (homogeneous-slope benchmark; biased under heterogeneity).{p_end}
{p2col:{cmd:mg}}Mean group average of the per-group OLS coefficients.{p_end}
{p2col:{cmd:bcmg}}Bias-corrected mean group: average of the bootstrap bias-corrected
per-group coefficients.{p_end}
{p2col:{cmd:ebayes}}Empirical Bayes / Swamy estimator, formula (7), with the
heterogeneity covariance estimated by the method of moments, formula (8).{p_end}
{p2col:{cmd:hbayes}}Hierarchical Bayes via Gibbs sampling, using the full conditional
distributions of Hsiao, Pesaran and Tahmiscioglu (1999, p.275) with a diffuse prior on
the mean coefficient and a Wishart prior on the precision matrix.{p_end}

{pstd}
Implied long-run coefficients are also reported for {cmd:bcmg}, {cmd:ebayes},
{cmd:hbayes} and {cmd:pols}. The short-run-only methods ({cmd:pols mg bcmg ebayes hbayes})
populate the mean short-run table; the long-run-only methods ({cmd:nbc dbc1 dbc2 bsbc})
populate the long-run table.

{pstd}
The short-run bias terms B(lambda) and B(beta) that feed {cmd:nbc}, {cmd:dbc1},
{cmd:dbc2} and {cmd:bcmg} are estimated by a per-group bootstrap rather than the
closed-form Kiviet-Phillips (1993) approximation used in the original papers. The
bootstrap is exact to simulation error and applies to any number of regressors; the
analytical {it:O(T{c 94}-1)} approximation is a special case.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}{opth lr(varlist)} lists the regressors for which the long-run coefficient is
reported. They must be a subset of {it:indepvars}. The default reports them all.

{phang}{opt noconstant} fits the model without a group-specific intercept.

{dlgtab:Methods}

{phang}{opt methods(list)} chooses which estimators to compute, as a space-separated
list of the keywords above. Three shortcuts are recognized: {cmd:all} (every method),
{cmd:longrun} ({cmd:mg nbc dbc1 dbc2 bsbc}) and {cmd:shortrun}
({cmd:pols mg bcmg ebayes hbayes}). The default is {cmd:mg dbc1 dbc2 bsbc} (long-run
focus). Remember that a {bf:mean short-run table is shown only if a short-run estimator}
({cmd:pols}, {cmd:mg}, {cmd:bcmg}, {cmd:ebayes}, {cmd:hbayes}) is included; the pure
long-run bias-corrections ({cmd:nbc}, {cmd:dbc1}, {cmd:dbc2}, {cmd:bsbc}) print only the
long-run results. The first listed method that has a long-run row is posted in
{cmd:e(b)}/{cmd:e(V)}.

{dlgtab:Bootstrap}

{phang}{opt reps(#)} sets the number of bootstrap replications used for the bias terms
and for {cmd:bsbc} (minimum 20).

{phang}{opt seed(#)} sets the seed for reproducibility.

{phang}{opt parametric} draws errors from N(0, sigma2(i)) instead of resampling the
(centered) within-group residuals.

{dlgtab:Hierarchical Bayes}

{phang}{opt burnin(#)}, {opt draws(#)} and {opt rho(#)} control the Gibbs sampler:
the number of discarded initial iterations, the number of retained draws, and the
Wishart prior scaling (the prior scale matrix is set to the Swamy estimate of the
heterogeneity covariance).

{dlgtab:Reporting}

{phang}{opt level(#)} and {opt nodots} control the confidence level and the progress
display.

{dlgtab:Visualisation}

{phang}{opt graph} draws, for every long-run variable, a {it:forest plot} comparing all
requested estimators (point estimate with confidence interval; markers coloured and shaped
by estimator family: uncorrected, bias-corrected, Bayes, pooled), a matching forest plot of
the mean short-run coefficients, and a {it:cross-panel heterogeneity caterpillar} of the
per-group long-run estimates {it:theta(i)} sorted with their confidence intervals and the
mean-group line. One clean figure is produced per variable.

{phang}{opt gname(stub)} sets the name stem of the stored graphs. With stem {it:s} the graphs
are {it:s}{cmd:_lr}[#] (long-run forest), {it:s}{cmd:_sr}[#] (short-run forest) and
{it:s}{cmd:_het}[#] (heterogeneity), one per variable. Export any of them with
{cmd:graph export myfig.png, name(}{it:s}{cmd:_lr) replace}.

{phang}{opt export(name)} writes the long-run results as a ready-to-include table. If {it:name}
ends in {cmd:.tex} a LaTeX {cmd:booktabs} table is written (coefficients with significance
stars, standard errors in parentheses); if it ends in {cmd:.csv} a comma-separated table is
written; otherwise both {it:name}{cmd:.tex} and {it:name}{cmd:.csv} are produced.

{pstd}
{it:Note on batch mode:} when Stata runs headless ({cmd:-b}/{cmd:-e}) the graphs are built with
the graphics device off (so the run never aborts) and stored in memory; run interactively, or
{cmd:graph export} them afterwards, to view.


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtlongestim} stores the following in {cmd:e()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(g_min)}}, {cmd:e(g_avg)}, {cmd:e(g_max)}}obs per group{p_end}
{synopt:{cmd:e(reps)}}bootstrap replications{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtlongestim}{p_end}
{synopt:{cmd:e(primary)}}method posted in {cmd:e(b)}{p_end}
{synopt:{cmd:e(methods)}}methods computed{p_end}
{synopt:{cmd:e(lrvars)}}long-run regressors{p_end}
{synopt:{cmd:e(depvar)}}, {cmd:e(ivar)}, {cmd:e(tvar)}}variables{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}long-run estimates of the primary method{p_end}
{synopt:{cmd:e(LR_b)}, {cmd:e(LR_se)}}all long-run point estimates / std. errors (rows = methods){p_end}
{synopt:{cmd:e(SR_b)}, {cmd:e(SR_se)}}all mean short-run estimates / std. errors{p_end}
{synopt:{cmd:e(theta_i)}, {cmd:e(theta_i_se)}}per-group long-run estimates / std. errors (used by the heterogeneity plot){p_end}
{synopt:{cmd:e(coef_i)}, {cmd:e(coef_i_se)}}per-group short-run coefficients / std. errors{p_end}
{synopt:{cmd:e(panel_ids)}}panel identifiers, one per group{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Long-run bias-correction suite (the Pesaran-Zhao methods):{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtlongestim invest mvalue kstock}{p_end}

{pstd}Everything, including the Bayes estimators, with the long-run reported only for {cmd:mvalue}:{p_end}
{phang2}{cmd:. xtlongestim invest mvalue kstock, methods(all) lr(mvalue) reps(500)}{p_end}

{pstd}Short-run comparison only, parametric bootstrap:{p_end}
{phang2}{cmd:. xtlongestim invest mvalue kstock, methods(shortrun) parametric}{p_end}


{marker references}{...}
{title:References}

{marker PZ}{...}
{phang}
Pesaran, M. H., and Z. Zhao. 1999. Bias reduction in estimating long-run relationships
from dynamic heterogeneous panels. In {it:Analysis of Panels and Limited Dependent}
{it:Variable Models}, ed. C. Hsiao, K. Lahiri, L.-F. Lee, and M. H. Pesaran, 297-322.
Cambridge: Cambridge University Press.

{marker HPT}{...}
{phang}
Hsiao, C., M. H. Pesaran, and A. K. Tahmiscioglu. 1999. Bayes estimation of short-run
coefficients in dynamic panel data models. In {it:Analysis of Panels and Limited}
{it:Dependent Variable Models}, ed. C. Hsiao, K. Lahiri, L.-F. Lee, and M. H. Pesaran,
268-296. Cambridge: Cambridge University Press.

{phang}
Kiviet, J. F., and G. D. A. Phillips. 1993. Alternative bias approximations with a
lagged-dependent variable. {it:Econometric Theory} 9: 62-80.

{phang}
Pesaran, M. H., and R. Smith. 1995. Estimating long-run relationships from dynamic
heterogeneous panels. {it:Journal of Econometrics} 68: 79-113.

{phang}
Swamy, P. A. V. B. 1971. {it:Statistical Inference in Random Coefficient Regression}
{it:Models}. Berlin: Springer.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
