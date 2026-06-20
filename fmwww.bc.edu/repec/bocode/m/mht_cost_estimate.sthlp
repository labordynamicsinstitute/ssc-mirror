{smcl}
{* *! version 1.1.0  2026-04-27}{...}
{viewerjumpto "Syntax" "mht_cost_estimate##syntax"}{...}
{viewerjumpto "Quick start" "mht_cost_estimate##quick"}{...}
{viewerjumpto "Description" "mht_cost_estimate##description"}{...}
{viewerjumpto "Options" "mht_cost_estimate##options"}{...}
{viewerjumpto "Examples" "mht_cost_estimate##examples"}{...}
{viewerjumpto "Stored results" "mht_cost_estimate##stored"}{...}
{viewerjumpto "References" "mht_cost_estimate##refs"}{...}

{title:Title}

{phang}
{bf:mht_cost_estimate} {hline 2} Estimate cost function parameters for study-specific MHT calibration


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mht_cost_estimate} {it:costvar} {it:armsvar} {it:sizevar} {ifin}{cmd:,}
{opt alpha:bar(#)} [{it:options}]

{pstd}
{bf:Important}: {it:sizevar} should contain the {bf:per-arm} (per-subgroup)
sample size, matching the paper's parameterization. If your size variable
is the total sample size across all arms, pass option {opt tot:alsize} so
the command converts internally before estimation.


{marker quick}{...}
{title:Quick start}

{pstd}Estimate Cobb-Douglas cost parameters from data on project costs, arms, and size:{p_end}
{phang2}{cmd:. mht_cost_estimate cost arms sample_size, alphabar(0.05) robust}{p_end}

{pstd}Add controls and display the implied critical-value table:{p_end}
{phang2}{cmd:. mht_cost_estimate cost arms sample_size, alphabar(0.05) ///}{p_end}
{phang2}{cmd:        controls(ptype2 ptype3) robust table}{p_end}

{pstd}Linear (fixed-cost-share) decomposition:{p_end}
{phang2}{cmd:. mht_cost_estimate cost arms sample_size, alphabar(0.05) model(linear_share) robust table}{p_end}

{pstd}Use the estimated parameters in {cmd:mht_test} or {cmd:mht_est}:{p_end}
{phang2}{cmd:. local b = e(beta)}{p_end}
{phang2}{cmd:. local i = e(iota)}{p_end}
{phang2}{cmd:. mht_test pval, alphabar(0.05) model(cobbdouglas) beta(`b') iota(`i')}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mht_cost_estimate} estimates the parameters of the research cost function
from project-level data on costs, the number of treatment arms (or hypotheses),
and sample sizes. The estimated parameters can be passed back to
{helpb mht_test} or {helpb mht_est} for {bf:study-specific} calibration of the
optimal MHT threshold.

{pstd}
Two cost-function parameterizations are supported:

{phang2}{bf:Cobb-Douglas} (default; Table 2 / Appendix A in the paper):
log(C) = const + beta*log(|J|) + iota*log(n). Estimated via OLS on the
log-linearized equation. Used in the J-PAL calibration.{p_end}

{phang2}{bf:Linear} ({opt model(linear_share)}; Section 6.1):
C = c_f + c_v * |J| * n. Estimated via OLS to decompose fixed and variable
costs; reports the implied fixed-cost share c_f / E[C].{p_end}

{pstd}
The command also tests four restrictions on the Cobb-Douglas parameters:
beta=0 (Bonferroni appropriate), beta=1 (no adjustment needed), iota=0
(costs invariant to n), and iota=1 (costs proportional to n).

{pstd}
{bf:Note on regression output}: the command creates {bf:named} log variables
({cmd:log_}{it:costvar}, {cmd:log_}{it:armsvar}, {cmd:log_}{it:sizevar}) so that
the regression output displays meaningful variable names rather than Stata
tempvar identifiers. These variables are dropped automatically at the end.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{it:costvar}, {it:armsvar}, {it:sizevar} are the three input variables: project
cost, number of treatment arms (or hypotheses), and sample size.

{phang}
{opt alpha:bar(#)} benchmark single-hypothesis size, in (0,1).

{dlgtab:Model selection}

{phang}
{opt mod:el(string)} {bf:cobbdouglas} (default) or {bf:linear_share}.

{dlgtab:Regression}

{phang}
{opt con:trols(varlist)} additional control variables included in the cost regression.

{phang}
{opt r:obust} use robust (Huber-White) standard errors.

{phang}
{opt cl:uster(varname)} cluster standard errors by {it:varname}.

{dlgtab:Sample size convention}

{phang}
{opt tot:alsize} indicates that {it:sizevar} contains the {bf:total} sample
size (n_total = J x n_bar) rather than the per-arm sample size n_bar. When
specified, the command auto-converts: log(n_bar) = log(n_total / arms).
Without this option, {it:sizevar} is assumed to be per-arm. The command
prints a one-line note in either case so the user is reminded which
convention is in effect.

{pstd}
{bf:Why this matters.} The paper's Cobb-Douglas formula uses the per-arm
elasticity. If you regress log(C) on log(arms) and log(n_total), the
coefficient on log(arms) becomes (beta - iota) instead of beta because
log(n_total) = log(arms) + log(n_bar). Passing {opt totalsize} avoids
this bias.

{dlgtab:Output}

{phang}
{opt tab:le} display a table of implied optimal critical values for |J|=1..9 and
several n/m ratios, computed using the estimated parameters.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}: simulate a Cobb-Douglas cost dataset{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 500}{p_end}
{phang2}{cmd:. gen arms = ceil(runiform() * 5)}{p_end}
{phang2}{cmd:. gen sample_size = ceil(500 + runiform() * 4500)}{p_end}
{phang2}{cmd:. gen cost = exp(10 + 0.2*ln(arms) + 0.15*ln(sample_size) + rnormal(0, 0.4))}{p_end}

{pstd}{bf:Cobb-Douglas estimation}{p_end}
{phang2}{cmd:. mht_cost_estimate cost arms sample_size, alphabar(0.05) table robust}{p_end}

{pstd}{bf:With controls for project type}{p_end}
{phang2}{cmd:. gen ptype = ceil(runiform() * 3)}{p_end}
{phang2}{cmd:. tabulate ptype, gen(ptype_)}{p_end}
{phang2}{cmd:. mht_cost_estimate cost arms sample_size, alphabar(0.05) ///}{p_end}
{phang2}{cmd:        controls(ptype_2 ptype_3) robust table}{p_end}

{pstd}{bf:Linear (fixed-cost-share) model}{p_end}
{phang2}{cmd:. mht_cost_estimate cost arms sample_size, alphabar(0.05) model(linear_share) robust table}{p_end}

{pstd}{bf:Feed estimated parameters into mht_test}{p_end}
{phang2}{cmd:. quietly mht_cost_estimate cost arms sample_size, alphabar(0.05) robust}{p_end}
{phang2}{cmd:. local b = e(beta)}{p_end}
{phang2}{cmd:. local i = e(iota)}{p_end}
{phang2}{cmd:. mht_test mypvals, alphabar(0.05) model(cobbdouglas) beta(`b') iota(`i')}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mht_cost_estimate} stores the following in {cmd:e()}:

{pstd}{bf:Cobb-Douglas (model = cobbdouglas)}:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(beta)}}estimated elasticity wrt arms{p_end}
{synopt:{cmd:e(iota)}}estimated elasticity wrt sample size{p_end}
{synopt:{cmd:e(beta_se)}}standard error of beta{p_end}
{synopt:{cmd:e(iota_se)}}standard error of iota{p_end}
{synopt:{cmd:e(p_beta0)}}p-value for H0: beta = 0{p_end}
{synopt:{cmd:e(p_beta1)}}p-value for H0: beta = 1{p_end}
{synopt:{cmd:e(p_iota0)}}p-value for H0: iota = 0{p_end}
{synopt:{cmd:e(p_iota1)}}p-value for H0: iota = 1{p_end}
{synopt:{cmd:e(alpha_bar)}}benchmark alpha (input){p_end}
{synopt:{cmd:e(N)}}number of observations used{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(model)}}cobbdouglas{p_end}

{pstd}{bf:Linear (model = linear_share)}:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(c_f)}}estimated fixed cost{p_end}
{synopt:{cmd:e(c_v)}}estimated variable cost per (J*n) unit{p_end}
{synopt:{cmd:e(cf_share)}}fixed cost share c_f / E[C]{p_end}
{synopt:{cmd:e(mean_J)}}mean number of arms{p_end}
{synopt:{cmd:e(alpha_bar)}}benchmark alpha (input){p_end}
{synopt:{cmd:e(N)}}number of observations used{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(model)}}linear_share{p_end}


{marker refs}{...}
{title:References}

{phang}
Viviano, D., K. Wuthrich, and P. Niehaus (2026).
{it:A model of multiple hypothesis testing}. arXiv:2104.13367v10.
{p_end}


{title:Also see}

{psee}
Online: {help mht_critical}, {help mht_test}, {help mht_est}, {help mht_table}
{p_end}
