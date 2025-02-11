{smcl}
{* *! version 2.0  10feb2025}{...}
{vieweralsosee "loevh2" "help loevh2"}{...}
{viewerjumpto "Syntax" "loevh2_boot##syntax"}{...}
{viewerjumpto "Description" "loevh2_boot##description"}{...}
{viewerjumpto "Options" "loevh2_boot##options"}{...}
{viewerjumpto "Examples" "loevh2_boot##examples"}{...}
{viewerjumpto "Stored results" "loevh2_boot##results"}{...}
{title:Title}

{phang}
{bf:loevh2_boot} {hline 2} Bootstrap confidence intervals for Loevinger's H

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:loevh2_boot} {varlist} {ifin} [{it:weight}] [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt r:eps(#)}}number of bootstrap replications; default is {cmd:reps(100)}{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt s:eed(#)}}set random-number seed for reproducibility{p_end}
{synopt:{opt t:able}}display cross-tabulation with expected frequencies{p_end}
{synopt:{opt ab:breviate(#)}}abbreviate variable names to # characters; default is {cmd:abbreviate(8)}{p_end}
{synopt:{opt pr:ogress}}display bootstrap progress bar{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by} is allowed; see {manhelp by D}.{p_end}
{p 4 6 2}
{cmd:aweight}s and {cmd:fweight}s are allowed; see {help weight}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:loevh2_boot} extends {help loevh2} by providing bootstrap confidence intervals for Loevinger's H coefficient.
While van der Ark et al. (2008) provide asymptotic standard errors for H, bootstrap resampling offers a complementary
approach that may be more robust when sample sizes are small or asymptotic assumptions are not met.

{pstd}
Loevinger's H is uniquely suited for analyzing item associations, being "the only linear transformation of
the observed proportion of agreement that has zero value under independence and maximum unity independent
of the marginal distributions." This makes it particularly appropriate "in cases where positive association
needs to be distinguished from zero association, e.g., analyzing test items" (Warrens, 2008, p. 787).

{pstd}
The program first computes Loevinger's H and its asymptotic standard error following van der Ark et al. (2008),
then performs bootstrap resampling to obtain percentile-based confidence intervals. This dual approach allows
comparison between asymptotic and bootstrap-based inference for the scalability coefficient introduced by
Mokken (1971). For a pair of items, H > 0.3 suggests sufficient scalability for Mokken scale analysis.

{pstd}
The bootstrap confidence intervals are based on the percentile method, which makes no assumptions about
the sampling distribution of H. This can be particularly useful when assessing item scalability in small
samples or when the data structure deviates from conditions assumed in the asymptotic theory.

{marker options}{...}
{title:Options}

{phang}
{opt reps(#)} specifies the number of bootstrap replications to perform.
The default is {cmd:reps(100)}. More replications provide better estimates but take longer to compute.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals.
The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt seed(#)} sets the random-number seed for reproducibility of bootstrap results.
This should be specified whenever you want to ensure the same results across different runs.

{phang}
{opt table} displays the cross-tabulation of the two variables with observed and expected frequencies
(passed through to {help loevh2}).

{phang}
{opt abbreviate(#)} specifies the number of characters to which variable names are abbreviated in the output.
The default is {cmd:abbreviate(8)}.

{phang}
{opt progress} displays a progress bar during bootstrap replications.
By default, no progress information is shown.

{marker examples}{...}
{title:Examples}

{pstd}Basic usage with 1000 replications{p_end}
{phang2}{cmd:. loevh2_boot item1 item2, reps(1000)}{p_end}

{pstd}With random seed for reproducibility{p_end}
{phang2}{cmd:. loevh2_boot item1 item2, reps(1000) seed(12345)}{p_end}

{pstd}With analytic weights and progress display{p_end}
{phang2}{cmd:. loevh2_boot item1 item2 [aw=wt], reps(1000) progress}{p_end}

{pstd}By-group analysis{p_end}
{phang2}{cmd:. bysort group: loevh2_boot item1 item2, reps(1000)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:loevh2_boot} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Original results}{p_end}
{synopt:{cmd:r(loevh)}}Loevinger's H coefficient{p_end}
{synopt:{cmd:r(se)}}standard error (van der Ark et al., 2008){p_end}
{synopt:{cmd:r(lb)}}lower bound of asymptotic confidence interval{p_end}
{synopt:{cmd:r(ub)}}upper bound of asymptotic confidence interval{p_end}

{p2col 5 20 24 2: Bootstrap results}{p_end}
{synopt:{cmd:r(boot_se)}}bootstrap standard error{p_end}
{synopt:{cmd:r(boot_lb)}}bootstrap lower bound of confidence interval{p_end}
{synopt:{cmd:r(boot_ub)}}bootstrap upper bound of confidence interval{p_end}

{p2col 5 20 24 2: Additional information}{p_end}
{synopt:{cmd:r(var1)}}name of first variable{p_end}
{synopt:{cmd:r(var2)}}name of second variable{p_end}
{synopt:{cmd:r(weight_type)}}weight type used (if weights were used){p_end}
{synopt:{cmd:r(weight)}}weight variable name (if weights were used){p_end}
{synopt:{cmd:r(group)}}by-group variables (if by: used){p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(reps)}}number of bootstrap replications{p_end}
{synopt:{cmd:r(seed)}}random seed used (0 if not set){p_end}

{marker seealso}{...}
{title:See also}

{pstd}
{help loevh2} provides asymptotic standard errors and confidence intervals for Loevinger's H.

{pstd}
{help loevh} (if installed) by Jean-Benoit Hardouin provides Loevinger's H coefficient for multiple items.
Install using {stata "net describe loevh, from(http://fmwww.bc.edu/RePEc/bocode/l)"}.

{marker author}{...}
{title:Author}

{pstd}Dirk Enzmann{p_end}
{pstd}Version 2.0  {p_end}
{pstd}10 Feb 2025{p_end}

{marker references}{...}
{title:References}

{phang}
Mokken, R. J. (1971). A Theory and Procedure of Scale Analysis. The Hague: Mouton.

{phang}
van der Ark, L. A., Croon, M. A., & Sijtsma, K. (2008). Mokken scale analysis for dichotomous items using marginal models.
{it:Psychometrika}, 73(2), 183-208. {browse "https://doi.org/10.1007/s11336-007-9034-z":https://doi.org/10.1007/s11336-007-9034-z}

{phang}
Warrens, M. J. (2008). On association coefficients for 2×2 tables and properties that do not depend on the marginal distributions.
{it:Psychometrika}, 73(4), 777-789. {browse "https://doi.org/10.1007/s11336-008-9070-3":https://doi.org/10.1007/s11336-008-9070-3}
