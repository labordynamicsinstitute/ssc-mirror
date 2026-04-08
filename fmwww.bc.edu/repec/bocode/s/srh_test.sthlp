{smcl}
{* 06Apr2026}{...}
{title:Title}

{phang}
{bf:srh_test} {hline 2} Scheirer-Ray-Hare nonparametric two-way analysis of variance test


{title:Syntax}

{p 8 17 2}
{cmd:srh_test} {depvar} {it:{help fvvarlist:factor_var1}} {it:{help fvvarlist:factor_var2}} {ifin}



{title:Description}

{pstd}
{cmd:srh_test} performs the Scheirer-Ray-Hare (SRH) test, a nonparametric alternative to two-way factorial ANOVA. The test was introduced by
Scheirer, Ray, and Hare (1976) as an extension of the Kruskal-Wallis one-way test to designs with two crossed factors and their interaction.

{pstd}
The command displays the standard ANOVA table augmented with two additional columns, {cmd:H}, the Scheirer-Ray-Hare test statistic for each term,
and {cmd:Prob>chi2}, the p-value for {cmd:H} based on the chi-squared distribution with degrees of freedom equal to those of the term.

{pstd}
Like the Kruskal-Wallis test, the SRH test does not require normality. It assumes that observations are independent and that the response variable
is at least ordinal. The chi-squared approximation improves with larger sample sizes; results should be interpreted cautiously in small samples.

{pstd}
The SRH test is intended for balanced factorial designs, where every combination of {it:factor_var1} and {it:factor_var2} levels contains 
the same number of observations. With unbalanced designs the test may produce unreliable results, because the sums of squares and MS({cmd:total}) are
distorted when cell sizes differ. If the design is unbalanced, alternative approaches should be considered.

{pstd}
The SRH test has lower statistical power than parametric two-way ANOVA and is considered conservative relative to the parametric alternative
(Dytham 2003). When the normality assumption of parametric ANOVA is plausible, that test is preferred. Post-hoc pairwise comparisons should
be performed separately if significant effects are found.



{title:Saved results}

{pstd}
{cmd:srh_test} runs {helpb anova} internally and all {cmd:e()} results
from that call remain available after the command returns. These include:

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(mss)}}model sum of squares{p_end}
{synopt:{cmd:e(rss)}}residual sum of squares{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(F)}}overall F statistic{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(ss_}{it:k}{cmd:)}}sum of squares for term {it:k}{p_end}
{synopt:{cmd:e(df_}{it:k}{cmd:)}}degrees of freedom for term {it:k}{p_end}
{synopt:{cmd:e(F_}{it:k}{cmd:)}}F statistic for term {it:k}{p_end}


{title:Example}

{pstd}Two-way factorial design{p_end}
{phang2}{cmd:. webuse systolic}{p_end}
{phang2}{cmd:. srh_test systolic drug disease}{p_end}

{pstd} Compare to two-way factorial ANOVA{p_end}
{phang2}{cmd:. anova systolic drug##disease}{p_end}



{title:References}

{phang}
Dytham, C. 2003.
{it:Choosing and Using Statistics: A Biologist's Guide}, 2nd ed.
Oxford: Blackwell. pp. 145-150.

{phang}
Scheirer, C. J., Ray, W. S., and Hare, N. 1976.
The analysis of ranked data derived from completely randomized factorial
designs.
{it:Biometrics} 32(2): 429-434.
{browse "https://www.jstor.org/stable/2529511"}

{phang}
Wikipedia. 2015.
Scheirer-Ray-Hare test.
{browse "https://en.wikipedia.org/wiki/Scheirer%E2%80%93Ray%E2%80%93Hare_test"}



{title:Author}

{pstd}Ariel Linden{p_end}
{pstd}Linden Consulting Group, LLC{p_end}
{pstd}alinden@lindenconsulting.org{p_end}
       



{title:Citation of {cmd:srh_test}}

{p 4 8 2}{cmd:srh_test} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, A. 2026. SRH_TEST: Stata module for computing the Scheirer-Ray-Hare nonparametric two-way analysis of variance test.
{p_end}

	   
	   
{title:Also see}
{psee}
{helpb anova}, {helpb kwallis}, {helpb ranksum}, {helpb dunntest} (if installed)
{p_end}
