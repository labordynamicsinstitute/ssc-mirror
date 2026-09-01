{smcl}
{* 31aug2026}{...}
{cmd:help opl_tb_cba}
{hline}

{title:Title}

{p2colset 5 18 22 2}{...}
{p2col :opl_tb_cba {hline 1}} Welfare-maximizing cost-benefit analysis with threshold policies
{p2colreset}{...}

{title:Syntax}

{p 8 8}
{cmd:opl_tb_cba} {it:tauvar} {ifin},
{cmd:cost(}{it:varname}{cmd:)}
{cmd:select(}{it:varlist}{cmd:)}
[{cmd:lambda(}{it:#}{cmd:)}
 {cmd:npoints(}{it:#}{cmd:)}
 {cmd:custom(}{it:numlist}{cmd:)}
 {cmd:custompolicy(}{it:varname}{cmd:)}
 {cmd:generate(}{it:prefix}{cmd:)}
 {cmd:graph}
 {cmd:replace}]

{pstd}
where {it:tauvar} contains estimated individual treatment effects and
{cmd:select()} contains one or two variables used to construct the threshold
policy.

{dlgtab:Description}

{pstd}
{cmd:opl_tb_cba} learns an interpretable threshold-based treatment policy
that maximizes weighted social surplus:

{p 12 12}
Q(pi;lambda) = sum_i pi_i [tau_i - lambda c_i].

{pstd}
Here, {it:tau_i} is the estimated individual treatment effect,
{it:c_i} is the individual treatment cost, and {it:lambda} controls the
weight assigned to costs.

{pstd}
The command first computes the unconstrained first-best policy:

{p 12 12}
pi_i^{FB} = 1(tau_i - lambda c_i > 0).

{pstd}
It then searches for the best policy within a restricted and interpretable
class of upper-threshold rules. With one selection variable, the policy is

{p 12 12}
pi_i(g_1) = 1(z_{1i} >= g_1).

{pstd}
With two selection variables, the policy is

{p 12 12}
pi_i(g_1,g_2) = 1(z_{1i} >= g_1 and z_{2i} >= g_2).

{pstd}
The selection variables are internally standardized to the interval [0,1].
The optimal threshold or threshold pair is found by exhaustive grid search.
Thresholds are returned both on the standardized scale and on the original
scale of the selection variables.

{pstd}
The command reports the first-best policy, the optimal threshold policy, and
the welfare loss caused by restricting treatment assignment to the selected
threshold-policy class.

{dlgtab:Options}

{phang}
{cmd:cost(}{it:varname}{cmd:)} specifies the variable containing individual
treatment costs. This option is required.

{phang}
{cmd:select(}{it:varlist}{cmd:)} specifies one or two numeric variables used
to construct the threshold policy. One variable produces a one-threshold
rule; two variables produce a two-threshold rule. Constant selection
variables are not allowed.

{phang}
{cmd:lambda(}{it:#}{cmd:)} specifies the nonnegative weight attached to
treatment costs. The default is {cmd:lambda(1)}. Setting {cmd:lambda(0)}
maximizes total treatment benefit without penalizing costs.

{phang}
{cmd:npoints(}{it:#}{cmd:)} specifies the number of equally spaced threshold
values evaluated over [0,1] for each selection variable. The default is
{cmd:npoints(101)}. With two selection variables, the command evaluates
{it:#} squared candidate policies.

{phang}
{cmd:custom(}{it:numlist}{cmd:)} evaluates user-specified threshold policies
in addition to the optimum. With one selection variable, each number defines
a separate threshold policy. With two selection variables, exactly two
numbers must be supplied, defining one threshold pair. All thresholds must
lie in [0,1].

{phang}
{cmd:custompolicy(}{it:varname}{cmd:)} evaluates a user-supplied binary
policy variable. The variable must contain only 0 and 1 in the estimation
sample.

{phang}
{cmd:generate(}{it:prefix}{cmd:)} generates policy and auxiliary variables
using the specified prefix.

{pmore}
The following variables are created:

{synoptset 25 tabbed}
{synopt:{it:prefix}{cmd:_fb}}first-best treatment policy{p_end}
{synopt:{it:prefix}{cmd:_opt}}optimal threshold policy{p_end}
{synopt:{it:prefix}{cmd:_surplus}}individual weighted surplus{p_end}
{synopt:{it:prefix}{cmd:_z1}}first selection variable standardized to [0,1]{p_end}
{synopt:{it:prefix}{cmd:_z2}}second standardized selection variable, when specified{p_end}

{pmore}
When {cmd:custom()} is specified, the command also generates custom policy
variables. With one selection variable, these are named
{it:prefix}{cmd:_custom1}, {it:prefix}{cmd:_custom2}, and so on. With two
selection variables, the generated variable is named
{it:prefix}{cmd:_custom}.

{phang}
{cmd:graph} displays the optimal threshold policy. With one selection
variable, the graph plots individual weighted surplus against the standardized
selection variable. With two selection variables, it displays selected and
nonselected observations in the two-dimensional selection space.

{phang}
{cmd:replace} allows existing generated variables with the requested names to
be replaced.

{dlgtab:Policy evaluation measures}

{pstd}
For each policy, the following quantities are computed:

{synoptset 22 tabbed}
{synopt:{cmd:N_treated}}number of treated observations{p_end}
{synopt:{cmd:coverage}}share of valid observations assigned to treatment{p_end}
{synopt:{cmd:total_benefit}}sum of estimated treatment effects among treated observations{p_end}
{synopt:{cmd:total_cost}}sum of treatment costs among treated observations{p_end}
{synopt:{cmd:Q}}weighted social surplus{p_end}
{synopt:{cmd:ATET}}average estimated treatment effect among treated observations{p_end}
{synopt:{cmd:avg_cost}}average treatment cost among treated observations{p_end}
{synopt:{cmd:avg_surplus}}average weighted surplus among treated observations{p_end}

{pstd}
Weighted social surplus is

{p 12 12}
Q = total benefit - lambda x total cost.

{dlgtab:Stored results}

{pstd}
{cmd:opl_tb_cba} is {cmd:eclass} and stores the following results:

{synoptset 32 tabbed}
{synopt:{cmd:e(N)}}number of valid observations{p_end}
{synopt:{cmd:e(lambda)}}cost-weight parameter{p_end}
{synopt:{cmd:e(nselect)}}number of selection variables{p_end}
{synopt:{cmd:e(npoints)}}number of grid points per selection variable{p_end}
{synopt:{cmd:e(npolicies)}}number of candidate threshold policies evaluated{p_end}
{synopt:{cmd:e(x1_min)}}minimum of the first selection variable{p_end}
{synopt:{cmd:e(x1_max)}}maximum of the first selection variable{p_end}
{synopt:{cmd:e(x2_min)}}minimum of the second selection variable{p_end}
{synopt:{cmd:e(x2_max)}}maximum of the second selection variable{p_end}
{synopt:{cmd:e(threshold1)}}optimal first threshold on the standardized scale{p_end}
{synopt:{cmd:e(threshold1_lev)}}optimal first threshold on the original scale{p_end}
{synopt:{cmd:e(threshold2)}}optimal second threshold on the standardized scale{p_end}
{synopt:{cmd:e(threshold2_lev)}}optimal second threshold on the original scale{p_end}

{pstd}
First-best policy results:

{synoptset 32 tabbed}
{synopt:{cmd:e(N_fb)}}number treated{p_end}
{synopt:{cmd:e(coverage_fb)}}treatment coverage{p_end}
{synopt:{cmd:e(total_benefit_fb)}}total treatment benefit{p_end}
{synopt:{cmd:e(total_cost_fb)}}total treatment cost{p_end}
{synopt:{cmd:e(Q_fb)}}weighted social surplus{p_end}
{synopt:{cmd:e(ATET_fb)}}average treatment effect among treated{p_end}
{synopt:{cmd:e(avg_cost_fb)}}average treatment cost{p_end}
{synopt:{cmd:e(avg_surplus_fb)}}average weighted surplus{p_end}

{pstd}
Optimal threshold-policy results:

{synoptset 32 tabbed}
{synopt:{cmd:e(N_opt)}}number treated{p_end}
{synopt:{cmd:e(coverage_opt)}}treatment coverage{p_end}
{synopt:{cmd:e(total_benefit_opt)}}total treatment benefit{p_end}
{synopt:{cmd:e(total_cost_opt)}}total treatment cost{p_end}
{synopt:{cmd:e(Q_opt)}}weighted social surplus{p_end}
{synopt:{cmd:e(ATET_opt)}}average treatment effect among treated{p_end}
{synopt:{cmd:e(avg_cost_opt)}}average treatment cost{p_end}
{synopt:{cmd:e(avg_surplus_opt)}}average weighted surplus{p_end}
{synopt:{cmd:e(Q_loss)}}welfare loss relative to the first-best policy{p_end}
{synopt:{cmd:e(Q_ratio)}}ratio of threshold-policy welfare to first-best welfare{p_end}

{pstd}
The command also stores:

{synoptset 32 tabbed}
{synopt:{cmd:e(grid)}}matrix containing all candidate threshold policies and their outcomes{p_end}
{synopt:{cmd:e(custom)}}matrix containing results for policies specified in {cmd:custom()}{p_end}
{synopt:{cmd:e(custompolicy)}}matrix containing results for {cmd:custompolicy()}{p_end}
{synopt:{cmd:e(has_custompolicy)}}indicator that a custom policy was evaluated{p_end}
{synopt:{cmd:e(tauvar)}}treatment-effect variable{p_end}
{synopt:{cmd:e(costvar)}}cost variable{p_end}
{synopt:{cmd:e(selectvars)}}selection variables{p_end}
{synopt:{cmd:e(generate)}}generated-variable prefix{p_end}
{synopt:{cmd:e(policytype)}}policy class, equal to {cmd:threshold}{p_end}
{synopt:{cmd:e(direction)}}threshold direction, equal to {cmd:upper}{p_end}

{pstd}
When {cmd:custompolicy()} is specified, additional scalars with suffix
{cmd:_custompolicy} report its coverage, benefit, cost, welfare, ATET,
average cost, average surplus, welfare loss, and welfare ratio.

{title:Postestimation}

{pstd}
Postestimation tools are available after {cmd:opl_tb_cba}.

{pstd}
See {helpb opl_frontier_tb} for constructing, saving, and graphing the policy
frontiers associated with the estimated threshold-policy model.

{dlgtab:Examples}

{pstd}
One-dimensional threshold policy:

{phang2}
{stata "sysuse data_opl_tb_cba_1, clear"}

{phang2}
{stata "opl_tb_cba tau, cost(cost) select(x1) lambda(1) npoints(101) custompolicy(D) custom(.30 .50 .70) generate(opl1) replace"}

{phang2}
{stata "opl_frontier_tb, frame(welfare_frontier) graph replace"}

{pstd}
Two-dimensional threshold policy:

{phang2}
{stata "sysuse data_opl_tb_cba_2, clear"}

{phang2}
{stata "opl_tb_cba tau, cost(cost) select(x1 x2) lambda(1) npoints(51) custompolicy(D) custom(.30 .30) generate(opl2) graph replace"}

{phang2}
{stata "opl_frontier_tb, frame(welfare_frontier_2d) graph bands(15) splinepoints(150) replace"}

{dlgtab:Acknowledgment}

{pstd}
The development of this software was supported by FOSSR (Fostering Open
Science in Social Science Research), a project funded by the European Union -
NextGenerationEU under the NPRR Grant agreement n. MURIR0000008.

{dlgtab:Author}

{phang}
Giovanni Cerulli{p_end}

{phang}
IRCrES-CNR{p_end}

{phang}
Research Institute for Sustainable Economic Growth,
National Research Council of Italy{p_end}

{phang}
E-mail: {browse "giovanni.cerulli@cnr.it"}{p_end}

{dlgtab:Also see}

{psee}
Online: {helpb opl}
{p_end}
