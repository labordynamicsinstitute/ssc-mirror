{smcl}
{* 21Apr2026}{...}
{title:Title}

{phang}
{bf:mlm_gof} {hline 2} Goodness-of-fit test after mixed-effects logistic regression


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
{cmd:mlm_gof} requires that the estimation results currently in memory be from {helpb melogit}.



{marker description}{...}
{title:Description}

{pstd}
{cmd:mlm_gof} performs a goodness-of-fit test for binary multilevel logistic models fitted by {helpb melogit}. It 
extends the grouping-based test of Perera, Sooriyarachchi & Wickramasuriya (2016) and Fernando & Sooriyarachchi (2022) 
to models with random coefficients (Linden 2026). The test works by dividing observations within each level-2 cluster 
into {it:G} groups based on their conditional predicted probabilities, then testing whether group membership adds 
explanatory power beyond the fitted model via a joint Wald test on {it:G}{c -}1 indicator variables. Under a well-fitting 
model, the group indicators should be uninformative and the Wald statistic should follow a chi-squared distribution 
with {it:G}{c -}1 degrees of freedom. 



{title:Options}

{phang}
{opt groups(#)} specifies the number of groups, {it:G}, into which observations are
divided within each level-2 cluster. The default data-driven choice G = min(10, {it:min_cell_n}), 
where {it:min_cell_n} is the minimum number of observations across all level-2 clusters, ensures that every
level-2 cluster can be divided into {it:G} non-empty groups, preventing convergence
failures in the augmented model refit. This is equivalent to the fixed G = 10 used
by Perera et al. (2016) and Fernando & Sooriyarachchi (2022) when {it:min_cell_n}
>= 10, which covers all scenarios studied in those papers. When {it:min_cell_n} < 10,
G is reduced accordingly and a warning is issued. Users may specify a fixed value via
{cmd:groups(#)}, subject to the constraint that it does not exceed {it:min_cell_n}.
Note that only level-2 cluster sizes are considered when computing {it:min_cell_n};
higher-level units (level-3 clusters and above) are not checked because groups are
formed within level-2 clusters only, and empty-group problems cannot arise at higher
levels. See Linden (2026) for a comprehensive discussion.



{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse bangladesh}{p_end}

{pstd}Two-level random-intercept model{p_end}
{phang2}{cmd:. melogit c_use i.urban age i.children || district:}{p_end}
{phang2}{cmd:. mlm_gof}{p_end}

{pstd}Two-level random coefficient model with random slope on {cmd:urban}{p_end}
{phang2}{cmd:. melogit c_use i.urban age i.children || district: i.urban, cov(unstructured)}{p_end}
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
{synopt:{cmd:r(df)}}degrees of freedom (= G{c -}1){p_end}
{synopt:{cmd:r(p)}}p-value{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(groups)}}effective number of groups G{p_end}
{synopt:{cmd:r(levels)}}number of data levels detected{p_end}
{synopt:{cmd:r(reterms)}}number of random-effect terms (intercepts + slopes){p_end}
{p2colreset}{...}


{title:References}

{phang}
Fernando, G. and R. Sooriyarachchi. 2022. The development of a
goodness-of-fit test for high level binary multilevel models.
{it:Communications in Statistics - Simulation and Computation}
51(5): 2710-2730.

{phang}
Linden, A. 2026. {browse "https://arxiv.org/abs/2604.19694": A goodness-of-fit test for mixed-effects logistic regression}. 
Preprint. arXiv

{phang}
Perera, A. A. P. N. M., M. R. Sooriyarachchi and S. L. Wickramasuriya.
2016. A goodness of fit test for the multilevel logistic model.
{it:Communications in Statistics - Simulation and Computation}
45(2): 643-659.


{title:Citation of {cmd:mlm_gof}}

{p 4 8 2}{cmd:mlm_gof} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026. mlm_gof: Stata module for computing the goodness-of-fit
test after mixed-effects logistic regression. Statistical Software Components S459670, 
Boston College Department of Economics. 
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
