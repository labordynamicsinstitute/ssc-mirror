{smcl}
{* *! version 1.0.0 29aug2026}{...}
{title:Title}

{phang}
{cmd:minvar} {hline 2} Longitudinal measurement invariance testing with effects-coded {cmd:sem}


{title:Syntax}

{p 8 16 2}
{cmd:minvar} [{it:if}]{cmd:,} {cmd:k1(}{it:varlist}{cmd:)} {cmd:k2(}{it:varlist}{cmd:)} [{cmd:k3(}{it:varlist}{cmd:)} ... {cmd:k16(}{it:varlist}{cmd:)}]
{cmd:name(}{it:stub}{cmd:)} [{it:options}]


{title:Description}

{pstd}
{cmd:minvar} tests whether a latent construct is measured equivalently across
repeated measurements (or any set of parallel indicator lists in wide format).
It fits a sequence of nested models and compares them:

{p2colset 8 24 26 2}{...}
{p2col:{bf:configural}}same items load on the same factor at each timepoint; all loadings and intercepts free{p_end}
{p2col:{bf:weak (metric)}}loadings constrained equal across timepoints{p_end}
{p2col:{bf:strong (scalar)}}loadings and intercepts constrained equal across timepoints{p_end}
{p2col:{bf:strict (residual)}}optional fourth step (the {cmd:strict} option): each item's residual variance also equated across timepoints{p_end}
{p2colreset}{...}

{pstd}
There is no limit on the number of indicators, and up to 16 timepoints/groups
are accepted. Effects coding is used for identification (Little, Slegers, &
Card 2006): each factor's loadings sum to the number of indicators and its
intercepts sum to 0, so the latent variables keep the metric of the items and
factor means are estimated at every timepoint. The residual of each item is
allowed to covary with the residual of the same item at every other
timepoint. Estimation is by {cmd:method(mlmv)} (full-information ML under
missing data) unless overridden.

{pstd}
Iteration logs are suppressed; each model instead prints a start time before
estimation and its elapsed time after (use the {cmd:log} option to watch the
iterations live). After each model, fit statistics
({cmd:estat gof, stats(all)}) and modification indices are shown. At the end
you get a reporting table in the format recommended by Putnick & Bornstein
(2016): each model's chi2({it:df}), CFI, TLI, RMSEA with its 90% CI, and SRMR,
followed by the nested comparisons (Dchi2, Ddf, {it:p}, DCFI, DRMSEA, DSRMR),
the estimation sample size, and a note stating the conventional criteria for
concluding invariance. SRMR (and therefore DSRMR) is unavailable under
{cmd:mlmv} when data contain missing values.


{title:Options}

{phang}{cmd:k1(}{it:varlist}{cmd:)} ... {cmd:k16(}{it:varlist}{cmd:)} indicator variables at each
timepoint/group. Every list must contain the same items in the same order.
{cmd:k1()} and {cmd:k2()} are required. {cmd:t1()}-{cmd:t16()} are accepted as synonyms.

{phang}{cmd:name(}{it:stub}{cmd:)} required. Names the latent variables ({it:stub}{cmd:1},
{it:stub}{cmd:2}, ...) and, with {cmd:save(yes)}, the saved factor-score variables.

{phang}{cmd:save(yes)} saves factor scores from the {bf:strong} model as
{it:stub}{cmd:1}, {it:stub}{cmd:2}, ... (existing variables with those names are
replaced; scores come from the strong model even when {cmd:strict} is also
specified). If the weak-to-strong DCFI is worse than -.010, the scores are
still saved but a warning is printed, since latent mean comparisons presuppose
(at least partial) scalar invariance.

{phang}{cmd:strict} additionally fits a fourth model that equates each item's
residual variance across timepoints (cross-time residual covariances stay
free), with its own row and comparison in the fit table. Per Putnick &
Bornstein (2016), this step is not required for latent mean comparisons.
Cannot be combined with {cmd:strongonly}.

{phang}{cmd:factors(}{it:#}{cmd:)} number of timepoints/groups. Optional: it is
inferred from how many {cmd:k#()} lists you fill in. If specified and smaller
than the number of lists given, only the first {it:#} lists are used.

{phang}{cmd:cov(}{it:stata code}{cmd:)} extra covariances passed straight to
{cmd:sem}, written as complete options, e.g.
{cmd:cov(cov(e.x1*e.x2) cov(e.x3*e.x4))}. {cmd:cov2()}-{cmd:cov8()} are also
accepted and simply appended.

{phang}{cmd:strongonly} fits only the strong model. Combine with
{cmd:save(yes)} to save the factor scores.

{phang}{cmd:method(}{it:name}{cmd:)} estimation method passed to {cmd:sem}; default {cmd:mlmv}.

{phang}{cmd:semopts(}{it:options}{cmd:)} any additional options passed straight to {cmd:sem},
e.g. {cmd:semopts(iterate(200) vce(robust))}.

{phang}{cmd:nomindices} skips {cmd:estat mindices} after each model (faster, shorter log).

{phang}{cmd:log} shows the maximization iteration logs, which are suppressed by default.

{phang}{cmd:indnum(}{it:#}{cmd:)} optional integrity check: {cmd:minvar} exits with an
error if {it:#} does not match the number of variables in {cmd:k1()}.


{title:Examples}

{pstd}Test whether anxiety is measured equivalently across three timepoints and save the factor scores:{p_end}

{phang2}{cmd:. minvar, save(yes) name(anxiety) ///}{p_end}
{phang2}{cmd:      k1(anx1_1 anx2_1 anx3_1 anx4_1 anx5_1) ///}{p_end}
{phang2}{cmd:      k2(anx1_2 anx2_2 anx3_2 anx4_2 anx5_2) ///}{p_end}
{phang2}{cmd:      k3(anx1_3 anx2_3 anx3_3 anx4_3 anx5_3) ///}{p_end}
{phang2}{cmd:      cov(cov(e.anx2_2*e.anx4_2) cov(e.anx1_2*e.anx4_2))}{p_end}

{pstd}All four invariance steps, restricted sample, no modification indices:{p_end}

{phang2}{cmd:. minvar if girl==1, strict nomindices name(warm) k1(...) k2(...) k3(...) k4(...)}{p_end}


{title:Stored results}

{pstd}{cmd:minvar} stores the following in {cmd:r()}:{p_end}

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(cfi_config)}, {cmd:r(cfi_weak)}, {cmd:r(cfi_strong)}, {cmd:r(cfi_strict)}}CFI of each fitted model (likewise {cmd:tli_}*, {cmd:rmsea_}*, {cmd:srmr_}*, {cmd:chi2_}*, {cmd:df_}*){p_end}
{synopt:{cmd:r(dcfi_weak)}, {cmd:r(dcfi_strong)}, {cmd:r(dcfi_strict)}}change in CFI from the previous model (negative = worse fit; likewise {cmd:drmsea_}*, {cmd:dsrmr_}*){p_end}
{synopt:{cmd:r(lrchi2_weak)}, {cmd:r(lrdf_weak)}, {cmd:r(lrp_weak)}}LR test of that model against the previous one (likewise {cmd:_strong}, {cmd:_strict}){p_end}
{synopt:{cmd:r(N)}}estimation sample size{p_end}
{synopt:{cmd:r(factors)}, {cmd:r(indnum)}}number of timepoints and indicators{p_end}
{synopt:{cmd:r(latent)}}names of the latent variables{p_end}

{pstd}
With {cmd:strongonly}, only the {cmd:_strong} scalars (plus {cmd:r(N)},
{cmd:r(factors)}, {cmd:r(indnum)}, and {cmd:r(latent)}) are returned; the
{cmd:_config}/{cmd:_weak} scalars, the change statistics, and the LR-test
results are not. The {cmd:_strict} results exist only when {cmd:strict} was
specified.

{pstd}
The fitted models are left as stored estimates {cmd:config}, {cmd:weak},
{cmd:strong}, and (if requested) {cmd:strict}, and can be brought back with
{cmd:estimates restore}; their {cmd:_est_} marker variables are removed from
the dataset, so a restored model's {cmd:e(sample)} is no longer tracked.


{title:References}

{phang}Chen, F. F. 2007. Sensitivity of goodness of fit indexes to lack of
measurement invariance. {it:Structural Equation Modeling} 14: 464-504.{p_end}

{phang}Cheung, G. W., and R. B. Rensvold. 2002. Evaluating goodness-of-fit
indexes for testing measurement invariance. {it:Structural Equation Modeling}
9: 233-255.{p_end}

{phang}Little, T. D., D. W. Slegers, and N. A. Card. 2006. A non-arbitrary
method of identifying and scaling latent variables in SEM and MACS models.
{it:Structural Equation Modeling} 13: 59-72.{p_end}

{phang}Putnick, D. L., and M. H. Bornstein. 2016. Measurement invariance
conventions and reporting: The state of the art and future directions for
psychological research. {it:Developmental Review} 41: 71-90.{p_end}


{title:Author}

{pstd}
Justin Dyer{break}
Brigham Young University{break}
justindyer@byu.edu{p_end}

{pstd}
Last updated: 29 August 2026{p_end}

