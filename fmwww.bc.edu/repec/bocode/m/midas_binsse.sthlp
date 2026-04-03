{smcl}
{* version 2.00  25mar2026}{...}
{cmd:help midas binsse}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas binsse} {hline 2} Regression-based tests for small-study effects and publication bias in diagnostic accuracy meta-analysis

{hline}

{title:Syntax}

{p 8 18 2}
{cmd:midas binsse}
{it:tp fp fn tn}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:method(}{it:code}{cmd:)}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{cmd:method(}{it:code}{cmd:)}}regression test; see {it:Method codes} below{p_end}

{syntab:Output}
{synopt:{cmd:funnel}}funnel plot (y-axis: precision measure; x-axis: effect){p_end}
{synopt:{cmd:regplot}}regression scatter plot (axes transposed from funnel){p_end}
{synopt:{cmd:graph}}funnel plot with fitted regression line overlaid{p_end}

{syntab:Inference}
{synopt:{cmd:level(}{it:#}{cmd:)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{cmd:zcf(}{it:#}{cmd:)}}continuity correction for zero cells; default {cmd:zcf(0.5)}{p_end}

{syntab:Styling}
{synopt:{cmd:pointopts(}{it:scatter_options}{cmd:)}}marker options for study points{p_end}
{synopt:{cmd:regopts(}{it:line_options}{cmd:)}}line options for the fitted regression line{p_end}
{synopt:{cmd:scheme(}{it:schemename}{cmd:)}}graph scheme{p_end}
{synopt:{it:graph_options}}any additional {helpb twoway} options{p_end}
{synoptline}

{hline}

{title:Description}

{pstd}
{cmd:midas binsse} applies regression-based asymmetry tests to detect small-study
effects and publication bias in a set of diagnostic accuracy studies. The four 2×2
cell count variables must be supplied in the order {it:tp fp fn tn}.

{pstd}
All tests regress a transformation of the log diagnostic odds ratio (or a related
effect measure) on a measure of study size or precision. A statistically significant
non-zero intercept indicates asymmetry consistent with small-study effects. The
specific transformation and precision measure differ by {cmd:method()}.

{pstd}
A continuity correction of 0.5 ({cmd:zcf(0.5)}) is applied to all cells of any study
that has at least one zero cell count, before computing the effect measure.

{hline}

{title:Method codes}

{p2colset 9 16 18 2}
{p2col:{cmd:method(d)}}Deeks: weighted regression of log DOR on 1/sqrt(ESS),
    where ESS = 4n1n2/(n1+n2) is the effective sample size. The recommended
    test for diagnostic odds ratio-based meta-analyses.{p_end}

{p2col:{cmd:method(e)}}Egger: regression of (log OR)/(SE) on 1/SE (standardised
    effect on precision). Adapted from the original Egger test for therapeutic
    meta-analysis.{p_end}

{p2col:{cmd:method(h)}}Harbord: modified Egger test using efficient score Z and
    Fisher information V; regresses Z/sqrt(V) on sqrt(V). Reduces confounding
    between the asymmetry statistic and the effect measure in diagnostic studies.{p_end}

{p2col:{cmd:method(m)}}Macaskill: regression of log OR on total sample size n,
    weighted by 1/(1/n1 + 1/n2). Analogous to the Macaskill test in therapeutic
    meta-analysis.{p_end}

{p2col:{cmd:method(p)}}Peters: regression of log OR on 1/n (inverse sample size),
    weighted by 1/(1/n1 + 1/n2). A sample-size-based variant of Macaskill.{p_end}

{p2col:{cmd:method(r)}}Schwarzer: regression of the arcsine difference
    [arcsin(sqrt(Se)) − arcsin(sqrt(1−Sp))] on its standard error
    sqrt(1/(4n1) + 1/(4n2)). Uses a variance-stabilising transformation and
    is independent of the underlying prevalence.{p_end}

{p2col:{cmd:method(s)}}Sterne: regression of log OR on SE(log OR). A
    log-odds-ratio analogue of the standard Egger test; weight = 1/Var(log OR).{p_end}

{p2col:{cmd:method(t)}}Stanley: meta-significance test; regresses log|t| on
    log(n) where t = log OR / SE. A positive intercept suggests genuine empirical
    effect; a negative intercept suggests small-study bias dominates.{p_end}
{p2colreset}{...}

{hline}

{title:Options}

{phang}
{cmd:funnel} draws a funnel plot with the effect measure on the x-axis and the
precision measure on the y-axis, without the regression line.

{phang}
{cmd:regplot} draws the regression scatter plot with axes transposed relative to
the funnel (effect measure on y, precision on x) and the fitted line overlaid.

{phang}
{cmd:graph} draws the funnel plot with the fitted regression line overlaid.

{phang}
{cmd:level(}{it:#}{cmd:)} sets the confidence level for regression inference.
Default is {cmd:level(95)}.

{phang}
{cmd:zcf(}{it:#}{cmd:)} continuity correction added to all four cells of studies
with at least one zero. Default is {cmd:zcf(0.5)}.

{phang}
{cmd:pointopts(}{it:scatter_options}{cmd:)} controls the appearance of study
scatter points, e.g. {cmd:pointopts(mcolor(navy) msymbol(circle))}.

{phang}
{cmd:regopts(}{it:line_options}{cmd:)} controls the appearance of the fitted
regression line, e.g. {cmd:regopts(lcolor(maroon) lwidth(medium))}.

{phang}
{cmd:scheme(}{it:schemename}{cmd:)} sets the graph scheme.

{hline}

{title:Examples}

{pstd}Deeks funnel + regression plot:{p_end}
{phang2}{cmd:. midas binsse tp fp fn tn, method(d) graph}{p_end}

{pstd}Harbord test with custom point styling:{p_end}
{phang2}{cmd:. midas binsse tp fp fn tn, method(h) graph pointopts(mcolor(navy)) regopts(lcolor(maroon))}{p_end}

{pstd}Schwarzer arcsine test, funnel only:{p_end}
{phang2}{cmd:. midas binsse tp fp fn tn, method(r) funnel}{p_end}

{pstd}Peters test, 90% level:{p_end}
{phang2}{cmd:. midas binsse tp fp fn tn, method(p) graph level(90)}{p_end}

{hline}

{title:References}

{pstd}
{bf:Deeks test (method d):}{p_end}
{phang}
Deeks JJ, Macaskill P, Irwig L. The performance of tests of publication bias
and other sample size effects in systematic reviews of diagnostic test accuracy
was assessed. {it:Journal of Clinical Epidemiology} 2005;{bf:58}:882–893.
{browse "https://doi.org/10.1016/j.jclinepi.2005.01.016"}
{p_end}

{pstd}
{bf:Egger test (method e):}{p_end}
{phang}
Egger M, Davey Smith G, Schneider M, Minder C. Bias in meta-analysis detected
by a simple, graphical test. {it:BMJ} 1997;{bf:315}:629–634.
{browse "https://doi.org/10.1136/bmj.315.7109.629"}
{p_end}

{pstd}
{bf:Harbord test (method h):}{p_end}
{phang}
Harbord RM, Egger M, Sterne JAC. A modified test for small-study effects in
meta-analyses of controlled trials with binary endpoints.
{it:Statistics in Medicine} 2006;{bf:25}:3443–3457.
{browse "https://doi.org/10.1002/sim.2380"}
{p_end}

{pstd}
{bf:Macaskill test (method m):}{p_end}
{phang}
Macaskill P, Walter SD, Irwig L. A comparison of methods to detect publication
bias in meta-analysis. {it:Statistics in Medicine} 2001;{bf:20}:641–654.
{browse "https://doi.org/10.1002/sim.698"}
{p_end}

{pstd}
{bf:Peters test (method p):}{p_end}
{phang}
Peters JL, Sutton AJ, Jones DR, Abrams KR, Rushton L. Comparison of two methods
to detect publication bias in meta-analysis. {it:JAMA} 2006;{bf:295}:676–680.
{browse "https://doi.org/10.1001/jama.295.6.676"}
{p_end}

{pstd}
{bf:Schwarzer test (method r):}{p_end}
{phang}
Schwarzer G, Antes G, Schumacher M. Inflation of type I error rate in two
statistical tests for the detection of publication bias in meta-analyses with
binary outcomes. {it:Statistics in Medicine} 2002;{bf:21}:2465–2477.
{browse "https://doi.org/10.1002/sim.1235"}
{p_end}
{phang}
Rücker G, Schwarzer G, Carpenter J, Schumacher M. Undue reliance on I² in
assessing heterogeneity may mislead. {it:BMC Medical Research Methodology}
2008;{bf:8}:79.
{browse "https://doi.org/10.1186/1471-2288-8-79"}
{p_end}

{pstd}
{bf:Sterne test (method s):}{p_end}
{phang}
Sterne JAC, Egger M. Funnel plots for detecting bias in meta-analysis:
guidelines on choice of axis. {it:Journal of Clinical Epidemiology}
2001;{bf:54}:1046–1055.
{browse "https://doi.org/10.1016/S0895-4356(01)00377-8"}
{p_end}

{pstd}
{bf:Stanley meta-significance test (method t):}{p_end}
{phang}
Stanley TD. Wheat from chaff: meta-analysis as quantitative literature review.
{it:Journal of Economic Perspectives} 2001;{bf:15}:131–150.
{browse "https://doi.org/10.1257/jep.15.3.131"}
{p_end}

{hline}

{title:Also see}

{psee}
{helpb midas}, {helpb midas pubbias}
