{smcl}
{* *! version 1.0.0  2026-03-15}{...}
{viewerjumpto "Syntax" "mht_est##syntax"}{...}
{viewerjumpto "Quick start" "mht_est##quick"}{...}
{viewerjumpto "Description" "mht_est##description"}{...}
{viewerjumpto "Options" "mht_est##options"}{...}
{viewerjumpto "Remarks" "mht_est##remarks"}{...}
{viewerjumpto "Examples" "mht_est##examples"}{...}
{viewerjumpto "Stored results" "mht_est##stored"}{...}
{viewerjumpto "References" "mht_est##references"}{...}

{title:Title}

{phang}
{bf:mht_est} {hline 2} Optimal MHT adjustment after any estimation command


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mht_est}{cmd:,}
{opt vars(varlist)}
{opt alpha:bar(#)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt vars(varlist)}}names of coefficients to test (must match e(b) column names){p_end}
{synopt:{opt alpha:bar(#)}}benchmark single-hypothesis significance level{p_end}

{syntab:P-value direction}
{synopt:{opt ones:ided}}use one-sided p-values, positive direction (default){p_end}
{synopt:{opt twos:ided}}use two-sided p-values instead{p_end}

{syntab:Cost model}
{synopt:{opt mod:el(string)}}{bf:linear} (default) or {bf:cobbdouglas}{p_end}
{synopt:{opt cfs:hare(#)}}fixed cost share (Linear); default {bf:0.46}{p_end}
{synopt:{opt jbar(#)}}average subgroups (Linear); default {bf:3}{p_end}
{synopt:{opt nmr:atio(#)}}sample size ratio n_bar/m_bar; default {bf:1.0}{p_end}
{synopt:{opt mbar(#)}}benchmark per-arm sample size; if given, nm_ratio is computed as (e(N)/J)/mbar (overrides {opt nmratio()}){p_end}
{synopt:{opt beta(#)}}arms elasticity (Cobb-Douglas); default {bf:0.13}{p_end}
{synopt:{opt iota(#)}}size elasticity (Cobb-Douglas); default {bf:0.075}{p_end}
{synoptline}

{pstd}
{cmd:mht_est} reads coefficient estimates and standard errors directly from
{cmd:e(b)} and {cmd:e(V)} of the {bf:most recently fitted estimation results}.
This means it works after {cmd:regress}, {cmd:logit}, {cmd:probit}, {cmd:areg},
{cmd:xtreg}, {cmd:ivregress}, {cmd:poisson}, and any other Stata estimation
command -- no need to re-run the model.


{marker quick}{...}
{title:Quick start}

{pstd}Apply the optimal MHT correction to three coefficients of the most recent regression:{p_end}
{phang2}{cmd:. regress price mpg weight foreign, robust}{p_end}
{phang2}{cmd:. mht_est, vars(mpg weight foreign) alphabar(0.05)}{p_end}

{pstd}Same regression, Cobb-Douglas (J-PAL) calibration:{p_end}
{phang2}{cmd:. mht_est, vars(mpg weight foreign) alphabar(0.05) model(cobbdouglas)}{p_end}

{pstd}After a clustered field experiment with multiple treatment arms:{p_end}
{phang2}{cmd:. areg y treat1 treat2 treat3, absorb(strata) cluster(hh_id)}{p_end}
{phang2}{cmd:. mht_est, vars(treat1 treat2 treat3) alphabar(0.05)}{p_end}

{pstd}Two-sided tests (e.g., when there is no a priori sign of the effect):{p_end}
{phang2}{cmd:. mht_est, vars(treat1 treat2) alphabar(0.05) twosided}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mht_est} is a postestimation command that applies the optimal multiple
hypothesis testing (MHT) adjustment from Proposition 4.1 of Viviano, Wuthrich,
and Niehaus (2026) to the results of the most recently fitted model. It reads
coefficient estimates and standard errors directly from {cmd:e(b)} and
{cmd:e(V)}, and therefore works after {cmd:regress}, {cmd:logit},
{cmd:probit}, {cmd:ivregress}, {cmd:areg}, {cmd:xtreg}, {cmd:poisson}, and
virtually any other Stata estimation command.

{pstd}
{cmd:mht_est} computes rejection decisions under five procedures:

{phang2}1. {bf:Optimal (model-based)} {hline 2} Proposition 4.1: alpha* = C(J,n) / (b * omega_bar(J)){p_end}
{phang2}2. {bf:Bonferroni} {hline 2} alpha_bonf = alpha_bar / J{p_end}
{phang2}3. {bf:Holm} {hline 2} step-down procedure{p_end}
{phang2}4. {bf:Benjamini-Hochberg (BH)} {hline 2} FDR control{p_end}
{phang2}5. {bf:Unadjusted} {hline 2} compare directly to alpha_bar{p_end}

{pstd}
The number of hypotheses |J| is set automatically to the number of variables
in {opt vars()}.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt vars(varlist)} specifies the coefficient names to test. These must match
column names in {cmd:e(b)} exactly, which are typically the variable names
used in the regression. Use {cmd:ereturn list} to see available names.

{phang}
{opt alphabar(#)} is the benchmark single-hypothesis significance level,
typically 0.05 or 0.10.

{dlgtab:P-value direction}

{phang}
{opt onesided} (default) converts t-statistics to one-sided p-values in the
positive direction: p = p_two/2 for t >= 0, and p = 1 - p_two/2 for t < 0.
This means a variable with a negative coefficient will not be rejected.

{phang}
{opt twosided} uses two-sided p-values directly from the model. Use this
if your application does not have a directional hypothesis.

{dlgtab:Cost model}

{phang}
{opt model(string)} selects the research cost function:

{p2col 8 26 30 2:{cmd:linear} (default)}Linear model (Equation 26 in the paper).
Optimal alpha = alpha_bar * [(1 + r/J)/(1 + r) + (nm_ratio - 1)/(1 + r)],
where r = cfshare*jbar/(1-cfshare). Calibrated to Sertkaya et al. (2016).{p_end}

{p2col 8 26 30 2:{cmd:cobbdouglas}}Cobb-Douglas model (Appendix A).
Optimal alpha = alpha_bar * J^(beta-1) * nm_ratio^iota. Calibrated to J-PAL
data (Table 2 of the paper).{p_end}

{phang}
{opt cfshare(#)} is the fixed cost share for the Linear model. Default 0.46
(Sertkaya et al. 2016). Must be in (0, 1).

{phang}
{opt jbar(#)} is the average number of subgroups/arms per trial used in
the linear calibration. Default 3 (Pocock et al. 2002).

{phang}
{opt nmratio(#)} is the ratio of the study's per-arm sample size to the
benchmark ({it:n_bar/m_bar}). Default 1.0. A value greater than 1 indicates
a larger-than-benchmark study, warranting a less conservative threshold.

{phang}
{opt mbar(#)} is the benchmark per-arm sample size {it:m_bar}. When provided,
{cmd:mht_est} computes {cmd:nm_ratio} automatically as
{cmd:(e(N) / J) / mbar}, where {cmd:e(N)} is the total sample size from the
preceding regression and {it:J} is the number of variables in {opt vars()}.
This option overrides {opt nmratio()}.

{phang2}
{bf:Caveat for clustered/non-RCT designs.} {cmd:e(N)/J} is a rough proxy
for "per-arm sample size" that treats the regression's full sample as if
it were evenly distributed across {it:J} arms. In a clustered RCT or any
design where treatment-arm sample sizes are unequal, the proxy may differ
from the true per-arm size. If you know the per-arm size externally
(e.g., from study design), set {opt nmratio()} = (true per-arm) / mbar
directly and skip {opt mbar()}.

{phang}
{opt beta(#)} is the elasticity of cost with respect to the number of
treatment arms (Cobb-Douglas model). Default 0.13 (J-PAL estimate). When
beta = 0, the optimal procedure is Bonferroni; when beta = 1, no adjustment
is needed.

{phang}
{opt iota(#)} is the elasticity of cost with respect to sample size
(Cobb-Douglas model). Default 0.075 (J-PAL estimate).


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Choosing between Linear and Cobb-Douglas.}
The linear calibration (default) is appropriate for settings resembling clinical
trials: experiments with defined regulatory approval processes and mixed
fixed/variable costs. The Cobb-Douglas calibration is appropriate for
development economics field experiments, based on J-PAL cost data.

{pstd}
{bf:Interpreting the optimal procedure.}
Under linear calibration with default parameters, the optimal procedure is
intermediate between Bonferroni and unadjusted testing. For example, with
J = 5 and alpha_bar = 0.05, the optimal threshold is approximately 0.021,
compared to 0.010 (Bonferroni) and 0.050 (unadjusted).

{pstd}
{bf:Connection to standard procedures.}
Bonferroni is optimal when research costs are entirely fixed (beta = 0 in
Cobb-Douglas, or equivalently high cf_share). No adjustment is optimal when
costs scale proportionally with the number of hypotheses (beta = 1). The Linear
and J-PAL calibrations both imply intermediate adjustment.

{pstd}
{bf:Sample size adjustment.}
Setting {opt nmratio()} > 1 makes the optimal threshold less conservative.
If your study has twice the benchmark sample size (nmratio = 2), the
researcher has already incurred higher costs to produce better-powered tests,
and the threshold should reflect this.

{pstd}
{bf:Multiple outcomes.}
When testing multiple treatment effects (one treatment, multiple outcomes),
the paper recommends using an index if there is a single decision-maker. Use
{cmd:mht_est} when either (a) multiple distinct treatments are being compared
or (b) the audience is heterogeneous with different preferences over outcomes.


{marker examples}{...}
{title:Examples}

{pstd}Setup: load auto data{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}{bf:Example 1: OLS after regress}{p_end}
{phang2}{cmd:. regress price mpg weight foreign, robust}{p_end}
{phang2}{cmd:. mht_est, vars(mpg weight foreign) alphabar(0.05)}{p_end}

{pstd}{bf:Example 2: Cobb-Douglas with J-PAL calibration}{p_end}
{phang2}{cmd:. regress price mpg weight foreign, robust}{p_end}
{phang2}{cmd:. mht_est, vars(mpg weight foreign) alphabar(0.05) ///}{p_end}
{phang2}{cmd:        model(cobbdouglas) beta(0.13) iota(0.075)}{p_end}

{pstd}{bf:Example 3: After logit}{p_end}
{phang2}{cmd:. logit foreign price mpg weight, robust}{p_end}
{phang2}{cmd:. mht_est, vars(price mpg weight) alphabar(0.05) twosided}{p_end}

{pstd}{bf:Example 4: After areg with cluster SE (field experiment)}{p_end}
{phang2}{cmd:. * Simulate a field experiment:}{p_end}
{phang2}{cmd:. gen treat1 = runiform() > 0.5}{p_end}
{phang2}{cmd:. gen treat2 = runiform() > 0.5}{p_end}
{phang2}{cmd:. gen cluster_id = ceil(_n/5)}{p_end}
{phang2}{cmd:. areg price treat1 treat2 mpg, absorb(rep78) cluster(cluster_id)}{p_end}
{phang2}{cmd:. mht_est, vars(treat1 treat2) alphabar(0.05)}{p_end}

{pstd}{bf:Example 5: Using stored results with estimates store}{p_end}
{phang2}{cmd:. quietly regress price mpg weight, robust}{p_end}
{phang2}{cmd:. estimates store model_a}{p_end}
{phang2}{cmd:. mht_est, vars(mpg weight) alphabar(0.05)}{p_end}
{phang2}{cmd:. local alpha_opt_a = r(alpha_opt)}{p_end}
{phang2}{cmd:. display "Model A optimal alpha: " `alpha_opt_a'}{p_end}

{pstd}{bf:Example 6: Larger study, less conservative threshold (nmratio)}{p_end}
{phang2}{cmd:. regress price mpg weight foreign, robust}{p_end}
{phang2}{cmd:. * Compare: benchmark sample vs. double sample}{p_end}
{phang2}{cmd:. mht_est, vars(mpg weight foreign) alphabar(0.05) nmratio(1.0)}{p_end}
{phang2}{cmd:. mht_est, vars(mpg weight foreign) alphabar(0.05) nmratio(2.0)}{p_end}

{pstd}{bf:Example 7: Using estimated cost parameters from mht_cost_estimate}{p_end}
{phang2}{cmd:. * First estimate the cost function:}{p_end}
{phang2}{cmd:. mht_cost_estimate cost_var arms_var size_var, alphabar(0.05)}{p_end}
{phang2}{cmd:. local est_beta = e(beta)}{p_end}
{phang2}{cmd:. local est_iota = e(iota)}{p_end}
{phang2}{cmd:. * Then apply to regression results:}{p_end}
{phang2}{cmd:. regress y treat1 treat2 treat3, cluster(hh_id)}{p_end}
{phang2}{cmd:. mht_est, vars(treat1 treat2 treat3) alphabar(0.05) ///}{p_end}
{phang2}{cmd:        model(cobbdouglas) beta(`est_beta') iota(`est_iota')}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mht_est} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(alpha_opt)}}optimal test size (Proposition 4.1){p_end}
{synopt:{cmd:r(alpha_bonf)}}Bonferroni test size (alpha_bar / J){p_end}
{synopt:{cmd:r(alpha_bar)}}benchmark alpha{p_end}
{synopt:{cmd:r(J)}}number of hypotheses tested{p_end}
{synopt:{cmd:r(n_reject_opt)}}number of rejections under optimal procedure{p_end}
{synopt:{cmd:r(n_reject_bonf)}}number of rejections under Bonferroni{p_end}
{synopt:{cmd:r(n_reject_holm)}}number of rejections under Holm{p_end}
{synopt:{cmd:r(n_reject_bh)}}number of rejections under BH/FDR{p_end}
{synopt:{cmd:r(n_reject_unadj)}}number of rejections without adjustment{p_end}

{pstd}
Per-variable results (where {it:varname} is each name in {opt vars()}):

{synopt:{cmd:r(coef_}{it:varname}{cmd:)}}coefficient estimate{p_end}
{synopt:{cmd:r(se_}{it:varname}{cmd:)}}standard error{p_end}
{synopt:{cmd:r(t_}{it:varname}{cmd:)}}t-statistic{p_end}
{synopt:{cmd:r(p_}{it:varname}{cmd:)}}p-value used for testing{p_end}
{synopt:{cmd:r(rej_opt_}{it:varname}{cmd:)}}1 if rejected under optimal, 0 otherwise{p_end}
{synopt:{cmd:r(rej_bonf_}{it:varname}{cmd:)}}1 if rejected under Bonferroni, 0 otherwise{p_end}
{synopt:{cmd:r(rej_holm_}{it:varname}{cmd:)}}1 if rejected under Holm, 0 otherwise{p_end}
{synopt:{cmd:r(rej_bh_}{it:varname}{cmd:)}}1 if rejected under BH, 0 otherwise{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(model)}}cost model used (linear or cobbdouglas){p_end}
{synopt:{cmd:r(vars)}}variable list tested{p_end}
{synopt:{cmd:r(cmd)}}estimation command (from e(cmd)){p_end}


{marker references}{...}
{title:References}

{phang}
Viviano, D., K. Wuthrich, and P. Niehaus (2026).
A model of multiple hypothesis testing.
{it:arXiv:2104.13367v10}.
{p_end}

{phang}
Sertkaya, A., H. H. Wong, A. Jessup, and T. Beleche (2016).
Key cost drivers of pharmaceutical clinical trials in the United States.
{it:Clinical Trials}, 13(2), 117-126.
{p_end}

{phang}
Benjamini, Y. and Y. Hochberg (1995).
Controlling the false discovery rate: a practical and powerful approach
to multiple testing. {it:Journal of the Royal Statistical Society, Series B},
57(1), 289-300.
{p_end}

{phang}
Holm, S. (1979). A simple sequentially rejective multiple test procedure.
{it:Scandinavian Journal of Statistics}, 6(2), 65-70.
{p_end}


{title:Also see}

{psee}
{helpb mht_critical} {hline 2} compute optimal critical values
{p_end}
{psee}
{helpb mht_test} {hline 2} test a variable of p-values
{p_end}
{psee}
{helpb mht_cost_estimate} {hline 2} estimate cost function parameters
{p_end}
