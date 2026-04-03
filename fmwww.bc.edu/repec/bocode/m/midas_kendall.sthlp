{smcl}
{* version 2.0.0 25mar2026  Ben A. Dwamena (University of Michigan)}

{vieweralsosee "midas" "help midas"}{...}
{vieweralsosee "midas bivbox" "help midas_bivbox"}{...}
{vieweralsosee "midas chiplot" "help midas_chiplot"}{...}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:midas kendall} {hline 2}}Kendall K-plot for diagnostic test accuracy data{p_end}
{p2colreset}{...}

{hline}

{title:Syntax}

{p 8 16 2}
{cmd:midas kendall} {it:tp} {it:fp} {it:fn} {it:tn} {ifin}
[{cmd:,} {opt cc(#)}
{opt xtitle(string)}
{opt ytitle(string)}
{opt title(string)}
{opt subtitle(string)}
{opt name(name)}
{opt replace}
{it:twoway_options}]

{pstd}
{it:tp}, {it:fp}, {it:fn}, and {it:tn} are study-level 2×2 table counts:
true positives, false positives, false negatives, and true negatives,
supplied in that order.

{hline}

{title:Description}

{pstd}
{cmd:midas kendall} draws a Kendall K-plot for diagnostic test accuracy
meta-analysis using study-level 2×2 table data. The command internally
computes sensitivity and specificity from the raw counts, applies a
continuity correction, transforms them to the requested link scale, and
then compares the empirical Kendall joint cumulative distribution with the
theoretical distribution under independence.

{pstd}
The plot contains two elements:

{phang2}
1. A 45-degree dashed reference line corresponding to independence.{p_end}
{phang2}
2. The empirical Kendall cumulative curve plotted as points.{p_end}

{pstd}
When the transformed sensitivity and specificity are approximately
independent, the points lie close to the diagonal. Systematic departures
indicate concordance (points above the diagonal), discordance (below),
or other forms of dependence. In the context of DTA meta-analysis, a
negative correlation between logit sensitivity and logit specificity —
the threshold effect — will typically produce points above the diagonal
in the upper range of the theoretical cumulative.

{pstd}
{cmd:midas kendall} complements {helpb midas chiplot} and
{helpb midas bivbox}: the chi-plot detects local departures from
independence study by study; the bivariate boxplot characterises the
elliptical shape and flags outliers; the Kendall K-plot characterises
the global concordance pattern relative to independence.

{hline}

{title:Options}

{dlgtab:Input transformation}

{phang}
{opt cc(#)} specifies the continuity correction added to the numerator
and denominator before computing sensitivity and specificity. Applied
only when at least one cell count is zero. Default {cmd:cc(0.5)}.

{pstd}
Sensitivity and specificity are transformed to logit scale internally,
consistent with the bivariate normal model used throughout MIDAS.

{dlgtab:Graph appearance}

{phang}
{opt xtitle(string)} and {opt ytitle(string)} specify axis titles.
Defaults are "Theoretical cumulative under independence" and
"Empirical Kendall cumulative".

{phang}
{opt title(string)} and {opt subtitle(string)} specify the graph
title and subtitle. Default title is "Kendall Plot".

{phang}
{opt name(name)} assigns a name to the graph.

{phang}
{opt replace} permits replacement of an existing graph with the same name.

{phang}
{it:twoway_options} are passed directly to {help twoway}, allowing
control of schemes, marker options, regions, and other stylistic elements.

{hline}

{title:Returned results}

{pstd}{cmd:midas kendall} is {cmd:rclass} and stores:{p_end}

{p2colset 8 28 30 2}{...}
{p2col:{cmd:r(n)}}number of studies used{p_end}
{p2col:{cmd:r(kendall_tau)}}sample Kendall's τ on the transformed scale{p_end}
{p2col:{cmd:r(cc)}}continuity correction used{p_end}
{p2col:{cmd:r(input_mode)}}"tp fp fn tn"{p_end}
{p2colreset}{...}

{hline}

{title:Examples}

{pstd}Default K-plot in logit space:{p_end}
{phang2}{cmd:. use midas_example_data, clear}{p_end}
{phang2}{cmd:. midas kendall tp fp fn tn}{p_end}

{pstd}Custom title and graph name:{p_end}
{phang2}{cmd:. midas kendall tp fp fn tn, title("Kendall K-plot: logit accuracy space") name(kplot1) replace}{p_end}

{pstd}Review returned diagnostics:{p_end}
{phang2}{cmd:. midas kendall tp fp fn tn}{p_end}
{phang2}{cmd:. return list}{p_end}

{hline}

{title:Comparison with related exploratory commands}

{p2colset 9 22 24 2}
{p2col:{helpb midas chiplot}}study-by-study chi and lambda statistics;
detects local departures from independence; shows the threshold effect
study by study{p_end}
{p2col:{helpb midas bivbox}}bivariate boxplot; characterises elliptical shape,
correlation, and outliers; requires no copula assumption{p_end}
{p2col:{cmd:midas kendall}}global concordance pattern; K-plot relative to
independence diagonal; sensitive to monotone dependence{p_end}
{p2colreset}{...}

{hline}

{title:References}

{phang}
Kendall MG. A new measure of rank correlation.
{it:Biometrika} 1938;{bf:30}:81–93.
{browse "https://doi.org/10.1093/biomet/30.1-2.81"}
{p_end}

{phang}
Nelsen RB. {it:An Introduction to Copulas}. 2nd ed.
New York: Springer; 2006.
{p_end}

{phang}
Genest C, Boies J-C. Detecting dependence with Kendall plots.
{it:The American Statistician} 2003;{bf:57}:275–284.
{browse "https://doi.org/10.1198/0003130032431"}
{p_end}

{phang}
Reitsma JB, Glas AS, Rutjes AWS, Scholten RJPM, Bossuyt PM, Zwinderman AH.
Bivariate analysis of sensitivity and specificity produces informative
summary measures in diagnostic reviews.
{it:Journal of Clinical Epidemiology} 2005;{bf:58}:982–990.
{browse "https://doi.org/10.1016/j.jclinepi.2005.02.022"}
{p_end}

{hline}

{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
Division of Nuclear Medicine and Molecular Imaging{break}
University of Michigan, Ann Arbor, MI{break}
bdwamena@umich.edu

{hline}

{title:Also see}

{psee}
{helpb midas}, {helpb midas chiplot}, {helpb midas bivbox}
