{smcl}
{* *! version 2.0.0  11nov2024}{...}
{viewerjumpto "Syntax" "i_ineq##syntax"}{...}
{viewerjumpto "Description" "i_ineq##description"}{...}
{viewerjumpto "Options" "i_ineq##options"}{...}
{viewerjumpto "Examples" "i_ineq##examples"}{...}
{viewerjumpto "Stored results" "i_ineq##results"}{...}
{viewerjumpto "References" "i_ineq##references"}{...}
{viewerjumpto "Author" "i_ineq##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:i_ineq} {hline 2}}Individual decomposition of inequality measures{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:i_ineq}
{it:varname}
{ifin}
{weight}
{cmd:,}
{opt group(varname)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{p2coldent:* {opt group(varname)}}grouping variable{p_end}
{synopt:{opt measure(string)}}inequality measure: {cmd:gini} (default), {cmd:theill}, or {cmd:theilt}{p_end}
{synopt:{opt gen:erate(string)}}stub name for generated variables{p_end}
{synopt:{opt replace}}replace existing variables{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt group()} is required.{p_end}
{p 4 6 2}{cmd:pweight}s are allowed; see {help weight}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:i_ineq} computes individual components of three inequality measures
(Gini index, Theil's L, and Theil's T) and their group-based decompositions.
The function takes as input an outcome variable (such as income), a grouping
variable, and an optional sampling weight. It returns three new variables
containing individual contributions and their between-group and within-group
components.

{pstd}
The Gini index (or Gini coefficient) is a widely used measure of inequality
that ranges from 0 (perfect equality) to 1 (maximum inequality). Theil's L
(also known as Theil's second measure or mean log deviation) and Theil's T
(also known as Theil's first measure or Theil entropy index) are members of
the generalized entropy family of inequality measures.

{pstd}
This command implements the individual decomposition methods described in
Liao (2022), which allow researchers to examine the contribution of each
individual to overall inequality and to decompose these contributions into
between-group and within-group components.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt group(varname)} specifies the grouping variable for the decomposition.
This variable should contain integers representing different groups (e.g.,
gender coded 1 & 2, race categories, income quintiles). The decomposition
will separate the inequality into between-group and within-group components
based on this grouping. This option is required.

{phang}
{opt measure(string)} specifies which inequality measure to compute. Options are:

{p 8 12}{cmd:gini} - Gini index (default). Computes individual components of
the Gini coefficient. Note that the Gini decomposition is computationally
intensive for large datasets.{p_end}

{p 8 12}{cmd:theill} - Theil's L index (mean log deviation). Requires all
values to be positive. Generally less sensitive to changes at the upper tail
of the distribution.{p_end}

{p 8 12}{cmd:theilt} - Theil's T index (Theil entropy index). Requires all
values to be positive though zeros are allowed (see Remarks below). 
Generally more sensitive to changes at the upper tail of the distribution.{p_end}

{phang}
{opt generate(string)} specifies an (optional, user-chosen) stub name for the 
three generated variables. If not specified, default names will be used based 
on the measure:

{p 8 12}For {cmd:gini}: {cmd:g_i}, {cmd:g_ikb}, {cmd:g_ikw}{p_end}
{p 8 12}For {cmd:theill}: {cmd:tl_i}, {cmd:tl_ib}, {cmd:tl_iw}{p_end}
{p 8 12}For {cmd:theilt}: {cmd:tt_i}, {cmd:tt_ib}, {cmd:tt_iw}{p_end}

{p 8 12}If you specify {cmd:generate(myineq)}, the variables will be named
{cmd:myineq_i}, {cmd:myineq_b}, and {cmd:myineq_w}.{p_end}

{phang}
{opt replace} allows overwriting existing variables with the same names as
the output variables.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}Basic Gini decomposition by car origin{p_end}
{phang2}{cmd:. i_ineq price, group(foreign)}{p_end}

{pstd}Theil L decomposition by car origin{p_end}
{phang2}{cmd:. i_ineq price, group(foreign) measure(theill) generate(tl)}{p_end}

{pstd}Theil T decomposition by car origin{p_end}
{phang2}{cmd:. i_ineq price, group(foreign) measure(theilt) generate(tt)}{p_end}

{pstd}Using with weights (with "auto weight" as a fake sampling weight variable){p_end}
{phang2}{cmd:. i_ineq price [pweight=weight], group(foreign)}{p_end}

{pstd}Visualize individual contributions{p_end}
{phang2}{cmd:. i_ineq price, group(foreign)}{p_end}
{phang2}{cmd:. scatter g_i price, by(foreign)}{p_end}

{pstd}Compare between and within components by group{p_end}
{phang2}{cmd:. i_ineq price, group(foreign)}{p_end}
{phang2}{cmd:. tabstat g_ikb g_ikw, by(foreign) statistics(sum)}{p_end}

{pstd}Multiple group analysis{p_end}
{phang2}{cmd:. egen price_quartile = cut(price), group(4)}{p_end}
{phang2}{cmd:. i_ineq mpg, group(price_quartile)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:i_ineq} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(groups)}}number of groups{p_end}
{synopt:{cmd:r(overall)}}overall inequality index{p_end}
{synopt:{cmd:r(between)}}between-group component{p_end}
{synopt:{cmd:r(within)}}within-group component{p_end}
{synopt:{cmd:r(ratio)}}ratio of between to total inequality{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(measure)}}inequality measure used{p_end}
{synopt:{cmd:r(varlist)}}outcome variable{p_end}
{synopt:{cmd:r(group)}}grouping variable{p_end}
{p2colreset}{...}

{pstd}
The command creates three new variables in the dataset:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Variables}{p_end}
{synopt:{it:prefix}_i}individual contribution to overall inequality{p_end}
{synopt:{it:prefix}_b}between-group component of individual contribution{p_end}
{synopt:{it:prefix}_w}within-group component of individual contribution{p_end}
{p2colreset}{...}

{pstd}
Note: For each observation, {it:prefix}_i = {it:prefix}_b + {it:prefix}_w


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Interpretation of results:}

{pstd}
The overall inequality index is the sum of all individual contributions
({it:prefix}_i). This can be decomposed into:

{p 8 12}1. {bf:Between-group inequality}: Sum of {it:prefix}_b across all
observations. This measures inequality that arises from differences in mean
outcomes between groups.{p_end}

{p 8 12}2. {bf:Within-group inequality}: Sum of {it:prefix}_w across all
observations. This measures inequality that arises from differences in
outcomes within each group.{p_end}

{pstd}
The {cmd:r(ratio)} result gives the proportion of total inequality that is
due to between-group differences. A higher ratio indicates that group
membership explains a larger share of overall inequality.

{pstd}
{bf:Handling of zero and negative values:}

{pstd}
The three measures handle zero and negative values differently:

{p 8 12}{bf:Gini index}: Can handle all values including zeros and negatives.
No observations are excluded.{p_end}

{p 8 12}{bf:Theil L}: Requires strictly positive values. Observations with
zero or negative values are automatically excluded with a note displayed.{p_end}

{p 8 12}{bf:Theil T}: Can include zero values but excludes negative values.
This follows the information theory principle that 0*log(0) = 0 by definition
(Shannon 1948; Cover and Thomas 2006). This allows Theil T to correctly
measure extreme inequality situations, such as when one person has all
income while others have none. In such cases, Theil T = ln(N), its maximum
value. See Liao (2016) for detailed discussion including the two references above.{p_end}

{pstd}
{bf:Computational considerations:}

{pstd}
The Gini decomposition is computationally intensive, especially for large
datasets, as it requires O(n²) comparisons. For datasets with more than a few
thousand observations, computation may take several minutes. The Theil measures
(L and T) are much faster, requiring only O(n) operations.

{pstd}
{bf:Missing values:}

{pstd}
Observations with missing values in either the outcome variable or the grouping
variable are excluded from the analysis.


{marker references}{...}
{title:References}

{phang}
Liao, T. F. 2016. "Evaluating Distributional Differences in Income Inequality with 
Sampling Weights." {it:Socius: Sociological Research for a Dynamic World}
2: 1-7. Extensions to/Supplementary Material for: "Evaluating Distributional Differences 
in Income Inequality." {it:Socius: Sociological Research for a Dynamic World}
2: 1-14.{browse "https://doi.org/10.1177/2378023115627462"}

{phang}
Liao, T. F. 2022. "Individual Components of Three Inequality Measures for
Analyzing Shapes of Inequality." {it:Sociological Methods & Research}
51(3): 1325-1356.
{browse "https://doi.org/10.1177/0049124119875961"}

{marker author}{...}
{title:Author}

{pstd}
Tim F. Liao{break}
University of Illinois Urbana-Champaign{break}
tfliao@illinois.edu

{pstd}
This Stata implementation is ported from the R package {bf:iIneq}.


{title:Also see}

{psee}
Online:  {helpb summarize}, {helpb tabstat}, {helpb egen}
{p_end}