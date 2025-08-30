{smcl}
{* *! version 2.0.1  28aug2025}{...}
{vieweralsosee "loevh2_boot" "help loevh2_boot"}{...}
{viewerjumpto "Syntax" "loevh2##syntax"}{...}
{viewerjumpto "Description" "loevh2##description"}{...}
{viewerjumpto "Options" "loevh2##options"}{...}
{viewerjumpto "Examples" "loevh2##examples"}{...}
{viewerjumpto "Stored results" "loevh2##results"}{...}
{title:Title}

{phang}
{bf:loevh2} {hline 2} Calculate Loevinger's H for two dichotomous variables


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:loevh2} {varlist} {ifin} [{it:weight}] [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt t:able}}display cross-tabulation with expected frequencies{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt a:bbreviate(#)}}abbreviate variable names to # characters; default is {cmd:abbreviate(8)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by} is allowed; see {manhelp by D}.{p_end}
{p 4 6 2}
{cmd:aweight}s and {cmd:fweight}s are allowed; see {help weight}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:loevh2} calculates Loevinger's H coefficient of homogeneity for two dichotomous (0/1) variables.
Loevinger's H is a measure of association that indicates the degree to which two items form a Guttman scale.
The coefficient ranges from -1 to +1, where:

{phang2}- H = 1 indicates perfect Guttman scalability{p_end}
{phang2}- H = 0 indicates no association beyond chance{p_end}
{phang2}- H < 0 indicates negative association{p_end}

{pstd}
The program provides standard errors, z-statistics, p-values, and confidence intervals for the H coefficient
(van der Ark et al., 2008).

{pstd}
Loevinger's H (Loevinger, 1947, pp. 29-31) is a key coefficient in Mokken scale analysis (Mokken, 1971), used
to assess the scalability of items. For a pair of dichotomous items, H > 0.3 suggests sufficient scalability
for Mokken scale analysis.

{pstd}
Warrens (2008) demonstrates that Loevinger's H is uniquely suited for the purpose, being "the only linear
transformation of the observed proportion of agreement that has zero value under independence and maximum
unity independent of the marginal distributions." This makes it particularly appropriate "in cases where
positive association needs to be distinguished from zero association, e.g., analyzing test items"
(Warrens, 2008, p. 787). Therefore, it also can be used as a measure of overlap of the positive answers
of two dichotomous items without being affected by its probability which is especially useful
when comparing this association measure across groups (see also Yule, 1912).


{marker options}{...}
{title:Options}

{phang}
{opt table} displays the cross-tabulation of the two variables with observed and expected frequencies.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals.
The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt abbreviate(#)} specifies the number of characters to which variable names are abbreviated in the output.
The default is {cmd:abbreviate(8)}.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage{p_end}
{phang2}{cmd:. loevh2 item1 item2}{p_end}

{pstd}With frequency weights{p_end}
{phang2}{cmd:. loevh2 item1 item2 [fw=freq]}{p_end}

{pstd}Show cross-tabulation and use 99% confidence level{p_end}
{phang2}{cmd:. loevh2 item1 item2, table level(99)}{p_end}

{pstd}By-group analysis{p_end}
{phang2}{cmd:. bysort group: loevh2 item1 item2}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:loevh2} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(loevh)}}Loevinger's H coefficient{p_end}
{synopt:{cmd:r(se)}}standard error{p_end}
{synopt:{cmd:r(lb)}}lower bound of confidence interval{p_end}
{synopt:{cmd:r(ub)}}upper bound of confidence interval{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(var1)}}name of first variable{p_end}
{synopt:{cmd:r(var2)}}name of second variable{p_end}
{synopt:{cmd:r(weight_type)}}weight type used (if weights were used){p_end}
{synopt:{cmd:r(weight)}}weight variable name (if weights were used){p_end}
{synopt:{cmd:r(group)}}by-group variables (if by: used){p_end}


{marker seealso}{...}
{title:See also}

{pstd}
{help loevh2_boot} provides bootstrap confidence intervals for Loevinger's H, which may be more robust
when sample sizes are small or asymptotic assumptions are not met.

{pstd}
{help loevh} (if installed) by Jean-Benoit Hardouin provides Loevinger's H coefficient for multiple
items (see {stata ssc describe loevh}).


{marker author}{...}
{title:Author}

{pstd}Dirk Enzmann (University of Hamburg) with AI assistance (Claude/Anthropic){p_end}


{marker references}{...}
{title:References}

{phang}
Loevinger, J. A. (1947). A systematic approach to the construction and evaluation of
tests of ability. {it:Psychological Monographs}, {it:61}(4), i–49. {browse "https://doi.org/10.1037/h0093565":https://doi.org/10.1037/h0093565}

{phang}
Mokken, R. J. (1971). {it:A Theory and Procedure of Scale Analysis}. The Hague: Mouton.

{phang}
van der Ark, L. A., Croon, M. A., & Sijtsma, K. (2008). Mokken scale analysis for dichotomous items using marginal
models.{it:Psychometrika}, {it:73}(2), 183-208. {browse "https://doi.org/10.1007/s11336-007-9034-z":https://doi.org/10.1007/s11336-007-9034-z}

{phang}
Warrens, M. J. (2008). On association coefficients for 2×2 tables and properties that do not depend on the marginal
distributions. {it:Psychometrika}, {it:73}(4), 777-789. {browse "https://doi.org/10.1007/s11336-008-9070-3":https://doi.org/10.1007/s11336-008-9070-3}

{phang}
Yule, G. U. (1912). On the methods of measuring association between two
attributes. {it:Journal of the Royal Statistical Society}, {it:75}, 579–642. {browse "https://doi.org/10.2307/2340126":https://doi.org/10.2307/2340126}
