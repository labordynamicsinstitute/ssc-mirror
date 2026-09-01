{smcl}
{* 31aug2026}{...}
{cmd:help opl_frontier_tb}
{hline}

{title:Title}

{p2colset 5 18 22 2}{...}
{p2col :opl_frontier_tb {hline 1}} Postestimation frontiers for threshold-based optimal policy learning
{p2colreset}{...}

{title:Syntax}

{p 8 8}
{cmd:opl_frontier_tb}
[{cmd:,}
 {cmd:frame(}{it:name}{cmd:)}
 {cmd:saving(}{it:filename}{cmd:)}
 {cmd:graph}
 {cmd:bands(}{it:#}{cmd:)}
 {cmd:splinepoints(}{it:#}{cmd:)}
 {cmd:grsize(}{it:#}{cmd:)}
 {cmd:replace}]

{title:Description}

{pstd}
{cmd:opl_frontier_tb} is a postestimation command for
{helpb opl_cba_tb}. It extracts the candidate-policy grid stored in
{cmd:e(grid)}, creates a Stata frame containing all candidate threshold
policies, identifies efficient policies, and optionally produces graphical
representations of the policy frontier.

{pstd}
The command computes both the cost-benefit efficient frontier and the
cost-surplus efficient frontier and provides graphical summaries of the
trade-offs among treatment coverage, treatment benefit, treatment cost,
and weighted welfare.

{dlgtab:Remarks}

{pstd}
The variable supplied as {it:tauvar} should contain estimated causal treatment
effects. These may be obtained using {helpb cate}, {helpb make_cate}, or
another valid CATE estimator. The command does not estimate treatment effects
internally.

{pstd}
Threshold policies are deliberately restrictive. Their main advantage is
interpretability: treatment assignment can be expressed using one or two
observable cutoff rules. The difference between {cmd:e(Q_fb)} and
{cmd:e(Q_opt)} measures the welfare cost of imposing this interpretable policy
class.

{pstd}
The threshold direction is always upper: observations are treated when each
standardized selection variable is greater than or equal to its threshold.

{pstd}
Because selection variables are standardized internally, values supplied in
{cmd:custom()} refer to the [0,1] scale rather than the variables' original
units.

{dlgtab:Example}

{pstd}
Load the example dataset and estimate a one-threshold welfare-maximizing
policy:

{phang2}
{stata "sysuse data_opl_tb_cba_2, clear"}

{phang2}
{stata "local lambda = 0.60"}

{phang2}
{stata "opl_tb_cba tau, cost(cost) select(x1) lambda(`lambda') npoints(101) custom(.30 .50 .70) custompolicy(D) generate(opl1) graph replace"}

{pstd}
Inspect the estimation results and the grid of candidate policies:

{phang2}
{stata "ereturn list"}

{phang2}
{stata "matrix list e(grid)"}

{pstd}
Construct and graph the policy frontiers:

{phang2}
{stata "opl_frontier_tb, frame(welfare_frontier) saving(welfare_frontier.dta) graph grsize(0.8) replace"}

{pstd}
Open the frontier frame:

{phang2}
{stata "frame change welfare_frontier"}

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