{smcl}
{* 09Apr2026}{...}

{title:Title}

{phang}
{bf:mlm_gof} {hline 2} Goodness-of-fit test after mixed-effects logistic regression with random intercepts


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mlm_gof} [{cmd:,} {opt gr:oups(#)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt gr:oups(#)}}number of groups; default is data-driven method{p_end}
{synoptline}

{pstd}
{cmd:mlm_gof} requires that the current estimation results be from {helpb melogit}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:mlm_gof} performs a goodness-of-fit test for binary multilevel logistic models with random intercepts, fitted by {helpb melogit}. It tests 
whether the fitted model describes the data adequately. Two-level models are tested using the method of Perera, Sooriyarachchi & 
Wickramasuriya (2016), and higher-order models are tested using the method of Fernando & Sooriyarachchi (2022).

{pstd}
The test is based on an extension of the Hosmer-Lemeshow goodness-of-fit test to the multilevel setting. The key idea is to divide observations 
within each innermost cluster into {it:G} groups based on their predicted probabilities, then test whether the group membership adds explanatory 
power beyond the fitted model. If the model fits well, group membership should be uninformative.



{title:Options}

{phang}
{opt groups(#)} specifies the number of groups, {it:G}, into which observations are divided within each cluster cell. 
By default, {it:G} is determined automatically from the data as the smaller of 10 and the minimum cluster cell size, so 
that every cell can be divided into {it:G} non-empty groups. The degrees of freedom for the test are {it:G}-1.


{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse bangladesh}{p_end}

{pstd}Two-level random-intercept model, followed by {cmd:mlm_gof} using default determimation of {cmd:groups()} {p_end}
{phang2}{cmd:. melogit c_use i.urban age i.children || district:}{p_end}
{phang2}{cmd:. mlm_gof}{p_end}

{pstd}Two-level random-intercept with correlated random effects{p_end}
{phang2}{cmd:. melogit c_use i.urban age i.children || district:, cov(unstruct)}{p_end}
{phang2}{cmd:. mlm_gof}{p_end}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse towerlondon}{p_end}

{pstd}Three-level nested model, {cmd:subject} nested within {cmd:family}{p_end}
{phang2}{cmd:. melogit dtlm difficulty i.group || family: || subject:}{p_end}
{phang2}{cmd:. mlm_gof}{p_end}

    {hline}



{title:Stored results}

{pstd}
{cmd:mlm_gof} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(chi2)}}Wald chi-squared statistic{p_end}
{synopt:{cmd:r(df)}}degrees of freedom (= G-1){p_end}
{synopt:{cmd:r(p)}}p-value{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(groups)}}effective number of groups G{p_end}
{synopt:{cmd:r(levels)}}number of data levels detected{p_end}
{p2colreset}{...}



{title:References}

{phang}
Abeysekera, W. W. M. and R. Sooriyarachchi. 2009. A novel method for
testing goodness of fit of a proportional odds model: An application
to AIDS study. {it:Journal of National Science Foundation Sri Lanka}
36(2): 125-135.

{phang}
Fernando, G. and R. Sooriyarachchi. 2022. The development of a
goodness-of-fit test for high level binary multilevel models.
{it:Communications in Statistics - Simulation and Computation}
51(5): 2710-2730.

{phang}
Hosmer, D. W. and S. Lemeshow. 1989.
{it:Applied Logistic Regression}. New York: John Wiley & Sons.

{phang}
Hosmer, D. W. and S. Lemeshow. 2000.
{it:Applied Logistic Regression}. 2nd ed. New York: John Wiley & Sons.

{phang}
Lipsitz, S. R., G. M. Fitzmaurice and G. Molenberghs. 1996.
Goodness-of-fit tests for ordinal response regression models.
{it:Journal of the Royal Statistical Society, Series C}
45(2): 175-190.

{phang}
Maydeu-Olivares, A. and C. Garcia-Forero. 2010. Goodness-of-fit
testing. {it:International Encyclopedia of Education} 7: 190-196.

{phang}
Perera, A. A. P. N. M., M. R. Sooriyarachchi and S. L. Wickramasuriya.
2016. A goodness of fit test for the multilevel logistic model.
{it:Communications in Statistics - Simulation and Computation}
45(2): 643-659.

{phang}
Rosner, B., R. J. Glynn and M.-L. T. Lee. 2003. Incorporation of
clustering effects for the Wilcoxon rank sum test: A large-sample
approach. {it:Biometrics} 59(4): 1089-1098.



{title:Citation of {cmd:mlm_gof}}

{p 4 8 2}{cmd:mlm_gof} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026. MLM_GOF: Stata module for computing the Goodness-of-fit test after mixed-effects logistic regression with random intercepts
{p_end}



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}




{title:Also see}

{psee}
{helpb melogit}, {helpb melogit postestimation}
{p_end}
