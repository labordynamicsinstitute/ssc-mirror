{smcl}
{* version 3.00  25mar2026}{...}
{cmd:help midas chiplot}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas chiplot} {hline 2} Chi-plot for bivariate association in diagnostic meta-analysis

{hline}

{title:Syntax}

{p 8 18 2}
{cmd:midas chiplot}
{it:tp fp fn tn}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Styling}
{synopt:{cmd:scatteropts(}{it:scatter_options}{cmd:)}}marker options for the scatter panel points{p_end}
{synopt:{cmd:fitopts(}{it:line_options}{cmd:)}}options for the linear fit line in the scatter panel{p_end}
{synopt:{cmd:chiopts(}{it:scatter_options}{cmd:)}}marker options for the chi-plot panel points{p_end}
{synopt:{it:graph_options}}any {helpb twoway} options passed to both panels{p_end}
{synoptline}

{hline}

{title:Description}

{pstd}
{cmd:midas chiplot} produces a combined display of two panels. The left panel
is a scatter plot of logit(Se) against logit(Sp) with a linear fit line. The
right panel is the chi-plot: the chi-statistic ({it:chi_i}) plotted against
the lambda-statistic ({it:lambda_i}) for each study, with horizontal reference
lines at ±1.78/sqrt(n) marking the independence band.

{pstd}
The four variables must be supplied in the order {it:tp fp fn tn}. Logit
sensitivity and logit specificity are computed internally with a 0.5
continuity correction:

{p 8 12 2}logit(Se) = logit[(tp + 0.5) / (tp + fn + 1)]{p_end}
{p 8 12 2}logit(Sp) = logit[(tn + 0.5) / (tn + fp + 1)]{p_end}

{pstd}
Under independence the chi-statistics scatter randomly within the band.
Systematic departures indicate positive (chi > 0) or negative (chi < 0)
association. In diagnostic meta-analysis, negative values of chi concentrated
near high lambda indicate the SROC threshold effect: studies with high
sensitivity tend to have low specificity.

{pstd}
The Spearman rank correlation between logit(Se) and logit(Sp) is reported
in the chi-plot title.

{hline}

{title:Options}

{phang}
{cmd:scatteropts(}{it:scatter_options}{cmd:)} overrides the default style of
the scatter panel points (default: open circles, grey fill), e.g.
{cmd:scatteropts(mcolor(navy) msymbol(circle))}.

{phang}
{cmd:fitopts(}{it:line_options}{cmd:)} overrides the default style of the
linear fit line in the scatter panel, e.g. {cmd:fitopts(lcolor(maroon))}.

{phang}
{cmd:chiopts(}{it:scatter_options}{cmd:)} overrides the default style of the
chi-plot panel points (default: open squares, grey fill), e.g.
{cmd:chiopts(mcolor(maroon) msymbol(square_hollow))}.

{hline}

{title:Example}

{phang2}{cmd:. use midas_example_data, clear}{p_end}
{phang2}{cmd:. midas chiplot tp fp fn tn}{p_end}
{phang2}{cmd:. midas chiplot tp fp fn tn, scatteropts(mcolor(navy)) chiopts(mcolor(maroon))}{p_end}

{hline}

{title:References}

{phang}
Fisher NI, Switzer P. Chi-plots for assessing dependence.
{it:Biometrika} 1985;{bf:72}:253–265.
{browse "https://doi.org/10.1093/biomet/72.2.253"}
{p_end}

{phang}
Fisher NI, Switzer P. Graphical assessment of dependence: is a picture
worth 100 tests? {it:The American Statistician} 2001;{bf:55}:233–239.
{browse "https://doi.org/10.1198/000313001317098248"}
{p_end}

{hline}

{title:Also see}

{psee}
{helpb midas}, {helpb midas bivbox}
