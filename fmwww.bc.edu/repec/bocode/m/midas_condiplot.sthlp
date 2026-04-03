{smcl}
{* version 2.00  25mar2026}{...}
{cmd:help midas condiplot}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas condiplot} {hline 2} Conditional post-test probability plot

{hline}

{title:Syntax}

{p 8 18 2}
{cmd:midas condiplot}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Prevalence range}
{synopt:{cmd:truncated}}use the observed prevalence range from the estimation; default is [0,1]{p_end}

{syntab:Styling}
{synopt:{cmd:ppvopts(}{it:line_options}{cmd:)}}options for the positive-test probability curve{p_end}
{synopt:{cmd:npvopts(}{it:line_options}{cmd:)}}options for the negative-test probability curve{p_end}
{synopt:{it:graph_options}}any {helpb twoway} options{p_end}
{synoptline}

{hline}

{title:Description}

{pstd}
{cmd:midas condiplot} displays a Fagan-style conditional probability plot after
a {cmd:midas mle}, {cmd:midas qrsim}, {cmd:midas mh}, {cmd:midas hmc}, or
{cmd:midas inla} estimation command. It plots two curves against prior
probability (prevalence) on the x-axis:

{p 8 12 2}{bf:Positive test result} (green dashed): post-test probability if the
test is positive, computed as LR+ × prevalence / (1 − prevalence + LR+ × prevalence).{p_end}

{p 8 12 2}{bf:Negative test result} (red dash-dot): post-test probability if the
test is negative, computed as LR− × prevalence / (1 − prevalence + LR− × prevalence).{p_end}

{pstd}
The diagonal reference line (y = x) represents a test with no discriminative
value. The greater the vertical separation between the positive and negative
curves, the more informative the test.

{pstd}
The summary likelihood ratios LR+ and LR− and their confidence limits are
taken from the stored estimation results. With {cmd:truncated}, the x-axis
is restricted to the range of observed prevalence values from the estimation.

{hline}

{title:Options}

{phang}
{cmd:truncated} restricts the prevalence axis to the range [prevmin, prevmax]
stored by the estimation command rather than the full [0, 1] interval.

{phang}
{cmd:ppvopts(}{it:line_options}{cmd:)} overrides the default style of the
positive-test probability curve (default: green dashed medium line), e.g.
{cmd:ppvopts(lcolor(navy) lwidth(thick))}.

{phang}
{cmd:npvopts(}{it:line_options}{cmd:)} overrides the default style of the
negative-test probability curve (default: red shortdash-dot medium line), e.g.
{cmd:npvopts(lcolor(maroon) lpattern(dash))}.

{hline}

{title:Returned results}

{p2colset 9 26 28 2}
{p2col:{cmd:r(LRpos)}}summary LR+{p_end}
{p2col:{cmd:r(LRpos_lb)}, {cmd:r(LRpos_ub)}}CI bounds for LR+{p_end}
{p2col:{cmd:r(LRneg)}}summary LR−{p_end}
{p2col:{cmd:r(LRneg_lb)}, {cmd:r(LRneg_ub)}}CI bounds for LR−{p_end}
{p2col:{cmd:r(prev_min)}, {cmd:r(prev_max)}}prevalence range used{p_end}
{p2colreset}{...}

{hline}

{title:Examples}

{pstd}Standard conditional probability plot:{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(author)}{p_end}
{phang2}{cmd:. midas condiplot}{p_end}

{pstd}Truncated range with custom curve colors:{p_end}
{phang2}{cmd:. midas condiplot, truncated ppvopts(lcolor(navy) lwidth(thick)) npvopts(lcolor(maroon))}{p_end}

{hline}

{title:Also see}

{psee}
{helpb midas}, {helpb midas lrmat}, {helpb midas fagan}
