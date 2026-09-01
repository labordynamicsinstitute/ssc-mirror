{smcl}
{* 31aug2026}{...}
{cmd:help opl_fb_cba}
{hline}

{title:Title}

{p2colset 5 18 22 2}{...}
{p2col :opl_fb_cba {hline 1}} First-best cost-benefit analysis and policy-score frontier
{p2colreset}{...}

{title:Syntax}

{p 8 8}
{cmd:opl_fb_cba} {it:tauvar} {ifin},
{cmd:cost(}{it:varname}{cmd:)}
[{cmd:lambda(}{it:#}{cmd:)}
 {cmd:nquantiles(}{it:#}{cmd:)}
 {cmd:generate(}{it:name}{cmd:)}
 {cmd:frame(}{it:name}{cmd:)}
 {cmd:saving(}{it:filename}{cmd:)}
 {cmd:grsize(}{it:#}{cmd:)}
 {cmd:graph}
 {cmd:replace}]

{pstd}
where {it:tauvar} contains estimated individual treatment effects, such as
estimated CATEs or IATEs, and {it:varname} in {cmd:cost()} contains
individual treatment costs.

{dlgtab:Description}

{pstd}
{cmd:opl_fb_cba} performs a first-best cost-benefit analysis using estimated
individual treatment effects and individual treatment costs.

{pstd}
For each observation, the command constructs the policy score

{p 12 12}
{it:s_i} = {it:tau_i} - lambda {it:c_i},

{pstd}
where {it:tau_i} is the estimated treatment effect, {it:c_i} is the
individual treatment cost, and {it:lambda} is a user-specified cost-weight
parameter.

{pstd}
The first-best policy assigns treatment whenever the policy score is positive:

{p 12 12}
{it:pi_i}^{FB} = 1({it:tau_i} - lambda {it:c_i} > 0).

{pstd}
The command also evaluates a sequence of quantile-based policies obtained by
applying progressively higher cutoffs to the policy score. These policies form
a policy-score frontier that summarizes the relationship among treatment
coverage, total treatment benefit, average treatment effect on the treated,
treatment cost, weighted welfare, and net benefit.

{pstd}
The first-best policy is generated in the current dataset. Frontier results are
stored in a separate frame and may optionally be saved as a Stata dataset and
displayed graphically.

{dlgtab:Options}

{phang}
{cmd:cost(}{it:varname}{cmd:)} specifies the variable containing
nonnegative individual treatment costs. This option is required.

{phang}
{cmd:lambda(}{it:#}{cmd:)} specifies the weight attached to treatment costs
in the policy score. {it:#} must lie between 0 and 1. The default is
{cmd:lambda(1)}.

{phang}
{cmd:nquantiles(}{it:#}{cmd:)} specifies the number of quantile groups used
to construct the policy-score frontier. The command evaluates the first-best
policy and {it:#}-1 quantile-based policies. {it:#} must be at least 2 and
cannot exceed the number of valid observations. The default is
{cmd:nquantiles(20)}.

{phang}
{cmd:generate(}{it:name}{cmd:)} specifies the name of the generated
first-best policy variable. The default is {cmd:policy_fb}.

{phang}
{cmd:frame(}{it:name}{cmd:)} specifies the name of the frame containing the
frontier results. The default is {cmd:policy_frontier}.

{phang}
{cmd:saving(}{it:filename}{cmd:)} saves the frontier frame as a Stata
dataset.

{phang}
{cmd:grsize(}{it:#}{cmd:)} controls the scale of the combined graph produced
by {cmd:graph}. The default is {cmd:grsize(0.7)}.

{phang}
{cmd:graph} displays the policy-score frontier. The combined graph contains
the benefit-coverage, ATET-coverage, cost-coverage, welfare-coverage, and
net-benefit-coverage frontiers.

{phang}
{cmd:replace} allows an existing generated policy variable, frontier frame,
or saved dataset to be replaced.

{dlgtab:Measures reported}

{pstd}
For the first-best policy and for each quantile-based policy, the command
computes the following quantities:

{phang}
{cmd:Ntreat} is the number of treated observations.

{phang}
{cmd:coverage} is the percentage of valid observations assigned to treatment.

{phang}
{cmd:ATET} is the average estimated treatment effect among treated
observations.

{phang}
{cmd:TTET} is the sum of estimated treatment effects among treated
observations.

{phang}
{cmd:ATEPOP} is the total treatment effect divided by the number of valid
observations.

{phang}
{cmd:avg_cost} and {cmd:total_cost} are the average and total treatment costs
among treated observations.

{phang}
{cmd:net_benefit} is defined as

{p 12 12}
TTET - total cost.

{phang}
{cmd:welfare} is the objective used to construct the first-best policy:

{p 12 12}
TTET - lambda x total cost.

{phang}
{cmd:bc_ratio} is the ratio of total treatment benefit to total treatment
cost.

{dlgtab:Frontier frame}

{pstd}
The frame specified in {cmd:frame()} contains one observation for the
first-best policy and one observation for each quantile-based policy. It
contains the following variables:

{synoptset 20 tabbed}
{synopt:{cmd:quantile}}percentile used to define the score cutoff{p_end}
{synopt:{cmd:cutoff}}policy-score cutoff{p_end}
{synopt:{cmd:first_best}}indicator for the first-best policy{p_end}
{synopt:{cmd:Ntreat}}number treated{p_end}
{synopt:{cmd:coverage}}percentage treated{p_end}
{synopt:{cmd:ATET}}average estimated treatment effect among treated{p_end}
{synopt:{cmd:TTET}}total treatment benefit{p_end}
{synopt:{cmd:ATEPOP}}average treatment effect in the population{p_end}
{synopt:{cmd:avg_cost}}average treatment cost{p_end}
{synopt:{cmd:total_cost}}total treatment cost{p_end}
{synopt:{cmd:net_benefit}}TTET minus total cost{p_end}
{synopt:{cmd:welfare}}TTET minus lambda times total cost{p_end}
{synopt:{cmd:bc_ratio}}benefit-cost ratio{p_end}

{dlgtab:Stored results}

{pstd}
{cmd:opl_fb_cba} is {cmd:rclass} and stores the following results:

{synoptset 24 tabbed}
{synopt:{cmd:r(N)}}number of valid observations{p_end}
{synopt:{cmd:r(Ntreat)}}number treated under the first-best policy{p_end}
{synopt:{cmd:r(coverage)}}percentage treated under the first-best policy{p_end}
{synopt:{cmd:r(ATET)}}average estimated treatment effect among treated{p_end}
{synopt:{cmd:r(TTET)}}total treatment effect among treated{p_end}
{synopt:{cmd:r(ATEPOP)}}total treatment effect divided by the estimation sample size{p_end}
{synopt:{cmd:r(avg_cost)}}average treatment cost among treated{p_end}
{synopt:{cmd:r(total_cost)}}total treatment cost{p_end}
{synopt:{cmd:r(net_benefit)}}TTET minus total cost{p_end}
{synopt:{cmd:r(welfare)}}TTET minus lambda times total cost{p_end}
{synopt:{cmd:r(bc_ratio)}}benefit-cost ratio{p_end}
{synopt:{cmd:r(lambda)}}cost-weight parameter{p_end}
{synopt:{cmd:r(nquantiles)}}number of quantile groups{p_end}
{synopt:{cmd:r(policy)}}name of the generated policy variable{p_end}
{synopt:{cmd:r(frame)}}name of the frontier frame{p_end}

{dlgtab:Remarks}

{pstd}
The command assumes that estimated individual treatment effects have already
been obtained. They may be produced using {helpb cate}, {helpb make_cate}, or
another valid CATE estimator.

{pstd}
The quantity stored in {it:tauvar} should represent the estimated causal
benefit used by the decision rule. The command does not estimate treatment
effects internally.

{pstd}
{cmd:opl_fb_cba} does not impose an explicit budget constraint. It computes
the unconstrained first-best policy associated with the selected value of
{cmd:lambda()} and traces alternative policies obtained by tightening the
cutoff on the policy score.

{pstd}
Because treatment effects and costs must be expressed on compatible scales,
the interpretation of {cmd:lambda()} depends on the units of {it:tauvar} and
{cmd:cost()}.

{dlgtab:Example}

{pstd}
Load the example dataset, define the cost-weight parameter, and compute the
first-best policy and policy-score frontier:

{phang2}
{stata "sysuse data_opl_fb_cba, clear"}

{phang2}
{stata "local lambda = 0.60"}

{phang2}
{stata "opl_fb_cba tau, cost(cost) lambda(`lambda') nquantiles(40) generate(policy_fb) saving(policy_frontier.dta) frame(frontier) grsize(0.6) graph replace"}

{pstd}
Inspect the first-best results returned in {cmd:r()}:

{phang2}
{stata "return list"}

{pstd}
Open the frontier frame:

{phang2}
{stata "frame change frontier"}

{pstd}
Return to the default frame:

{phang2}
{stata "frame change default"}

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
