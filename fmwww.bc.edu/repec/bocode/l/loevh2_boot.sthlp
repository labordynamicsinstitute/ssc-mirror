{smcl}
{* *! version 3.2  13jul2026}{...}

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

{pstd}
Bootstrap confidence intervals for Loevinger's H

{p 8 17 2}
{cmdab:loevh2_boot} {varlist} {ifin} [{it:weight}] [{cmd:,} {it:options}]

{pstd}
Immediate command

{p 8 17 2}
{cmdab:loevh2_booti} {it:#a} {it:#b} [{cmd:\}] {it:#c} {it:#d} [{cmd:,} {it:immediate_options}]

{p 8 8 2}
where {it:#a}, {it:#b}, {it:#c}, and {it:#d} are the four (nonnegative
integer) cell frequencies of the 2×2 cross-tabulation of the two
variables, entered row by row (first row: {it:#a} {it:#b}; second row:
{it:#c} {it:#d}), exactly as for Stata's own {help tabi}. The backslash
separating the two rows is optional, e.g. {cmd:loevh2_booti 40 10 5 45} and
{cmd:loevh2_booti 40 10 \ 5 45} are equivalent.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt r:eps(#)}}number of bootstrap replications; default is {cmd:reps(100)}{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt s:eed(#)}}set random-number seed for reproducibility{p_end}
{synopt:{opt t:able}}display a 2×2 table with observed and expected counts, and cell percentages{p_end}
{p2coldent:* {opt abbreviate(#)}}abbreviate variable names to # characters; default is {cmd:abbreviate(8)}){p_end}
{synopt:{opt p:rogress}}display bootstrap progress bar{p_end}
{synopt:{opt maxtries(#)}}maximum number of resampling attempts per replication when a
resample yields a degenerate 2×2 table; default is {cmd:maxtries(50)}{p_end}

{syntab:Immediate command}
{synopt:{opt noTAB}}suppress display of any cross-tabulation{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt abbreviate} is available only for {cmd:loevh2_boot}.{p_end}
{p 4 6 2}
{cmd:by} is allowed with {cmd:loevh2_boot}, but not with {cmd:loevh2_booti}; see {manhelp by D}.{p_end}
{p 4 6 2}
{cmd:aweight}s and {cmd:fweight}s are allowed with {cmd:loevh2_boot}, but not with
{cmd:loevh2_booti}; see {help weight}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:loevh2_boot} extends {help loevh2} to include bootstrap confidence intervals for Loevinger's H
coefficient. Bootstrap resampling offers a complementary approach to the confidence intervals
calculated by {cmd:loevh2}, which can be more robust when sample sizes are small or asymptotic
assumptions are not met (e.g. when the upper bound of the confidence interval exceeds 1).

{pstd}
Loevinger's H (Loevinger, 1947, pp. 29-31) is a measure of the positive association between two binary
variables that is not influenced by their base rates (marginal proportions) and can be interpreted
as the proportion of "overlap" of two positively associated binary variables, corrected for chance
and ceiling effects.

{pstd}
Loevinger's H is a key coefficient in Mokken scale analysis (Mokken, 1971) that is used to assess the
scalability of items. For a pair of dichotomous items, H > 0.3 suggests sufficient scalability
for Mokken scale analysis. It has also be re-invented by Copas & Loeber as "relative improvement
over chance" (RIOC). Warrens (2008) shows that Loevinger's H is "the only linear transformation
of the observed proportion of agreement that has zero value under independence and maximum
unity independent of the marginal distributions." This makes it particularly suitable "in cases where
positive association needs to be distinguished from zero association" (Warrens, 2008, p. 787). Therefore, it
also can be used as a measure of overlap and is particularly useful when this measure of association
is compared across groups (see also Yule, 1912).

{pstd}
The program first calculates Loevinger's H and its large-sample standard error according to Copas &
Loeber (1990, eq. 11), then performs bootstrap resampling with BCa (bias-corrected and accelerated)
confidence intervals. This dual approach allows a comparison between the large-sample and bootstrap
confidence intervals.

{pstd}
The bootstrap confidence intervals are based on the BCa method, which adjusts confidence
intervals (1) for systematic bias in the sampling distribution of H (BC = bias correction), and
(2) for non-constant variance and skewness (a = acceleration). This can be particularly
useful when assessing H in small samples or when the data structure deviates from conditions
assumed in the asymptotic theory (normal approximation) that is likely to happen for H in the
interval [-1,1].


{marker options}{...}
{title:Options}

{phang}
{opt reps(#)} specifies the number of bootstrap replications to perform. The default
is {cmd:reps(100)}. For the BCa method as used here 1,000 replications (better 2,000) are
generally recommended. More replications provide better estimates but take longer to compute.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals. The
default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt seed(#)} sets the random-number seed for reproducibility of bootstrap results. This
should be specified whenever you want to ensure the same results across different runs.

{phang}
{marker table}{...}
{opt table} displays a 2×2 table of the two variables with observed and expected counts, and cell
percentages. With {cmd:loevh2_booti}, this detailed table replaces the simple frequency-only
table shown by default (see {help loevh2_boot##notab:noTAB} below).

{phang}
{opt abbreviate(#)} specifies the number of characters to which variable names are abbreviated
in the output. The default is {cmd:abbreviate(8)}. Available only with {cmd:loevh2_boot}.

{phang}
{opt progress} displays a progress bar during bootstrap replications. By default, no
progress information is shown.

{phang}
{opt maxtries(#)} specifies the maximum number of times a bootstrap replication will be
redrawn (resampled) if it produces a degenerate 2×2 table (i.e., a table with a zero
cell or a zero margin, which leaves H undefined). This can happen, e.g., in small samples
or with unbalanced items, when a resample happens to make one of the two variables (nearly)
constant. The default is {cmd:maxtries(50)}. If a replication still produces a degenerate
table after {cmd:maxtries()} attempts, it is excluded from the bootstrap distribution and
counted; a warning summarizing the number of excluded replications is displayed after the
bootstrap loop, and the bias-correction and percentile calculations of the BCa confidence
interval are based on the actual (possibly reduced) number of valid replications rather
than the nominal {cmd:reps()}. If the {it:original} (non-bootstrapped) sample itself
produces a degenerate table, {cmd:loevh2_boot} stops with an error, since bootstrapping
is not meaningful in that case.

{phang}
{marker notab}{...}
{cmd:noTAB} (immediate command only; default) suppresses the display of any 2×2 table with
{cmd:loevh2_booti}. By default (when neither {opt notab} nor {opt table} is specified), {cmd:loevh2_booti}
displays a simple frequency-only 2×2 table of the entered cell frequencies. Specifying {opt table}
instead replaces this simple table with {cmd:loevh2_boot}'s own, more detailed 2×2 table showing
observed and expected counts together with cell percentages (see {help loevh2_boot##table:table} above); the
simple table is not shown in that case. {opt notab} and {opt table} cannot be combined.


{marker examples}{...}
{title:Examples}

{pstd}Basic usage with 1,000 replications{p_end}
{phang2}{cmd:. loevh2_boot item1 item2, reps(1000)}{p_end}

{pstd}With random seed for reproducibility{p_end}
{phang2}{cmd:. loevh2_boot item1 item2, reps(1000) seed(12345)}{p_end}

{pstd}With analytic weights and progress display{p_end}
{phang2}{cmd:. loevh2_boot item1 item2 [aw=wt], reps(1000) progress}{p_end}

{pstd}By-group analysis{p_end}
{phang2}{cmd:. bysort group: loevh2_boot item1 item2, reps(1000)}{p_end}

{pstd}Immediate command, enter the four cell frequencies of a 2×2 table directly{p_end}
{phang2}{cmd:. loevh2_booti 40 10 \ 5 45, reps(1000) seed(12345)}{p_end}

{pstd}Immediate command, suppressing the display of any 2×2 table{p_end}
{phang2}{cmd:. loevh2_booti 40 10 \ 5 45, notab reps(1000) seed(12345)}{p_end}

{pstd}Immediate command, showing detailed 2×2 table instead of the simple table{p_end}
{phang2}{cmd:. loevh2_booti 40 10 \ 5 45, table reps(1000) seed(12345)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:loevh2_boot} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Original results (scalars)}{p_end}
{synopt:{cmd:r(loevh)}}Loevinger's H coefficient{p_end}
{synopt:{cmd:r(se)}}large-sample standard error{p_end}
{synopt:{cmd:r(lb)}}lower bound of asymptotic confidence interval{p_end}
{synopt:{cmd:r(ub)}}upper bound of asymptotic confidence interval{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}

{p2col 5 20 24 2: Bootstrap results (scalars)}{p_end}
{synopt:{cmd:r(boot_h)}}Loevinger's H coefficient, bootstrapped{p_end}
{synopt:{cmd:r(boot_se)}}bootstrap standard error{p_end}
{synopt:{cmd:r(boot_lb)}}bootstrap lower bound of confidence interval{p_end}
{synopt:{cmd:r(boot_ub)}}bootstrap upper bound of confidence interval{p_end}
{synopt:{cmd:r(boot_z0)}}bootstrap bias-correction constant{p_end}
{synopt:{cmd:r(boot_a)}}bootstrap acceleration constant{p_end}
{synopt:{cmd:r(reps)}}number of bootstrap replications requested{p_end}
{synopt:{cmd:r(reps_valid)}}number of valid (non-degenerate) bootstrap replications used{p_end}
{synopt:{cmd:r(reps_failed)}}number of replications excluded due to a persistently degenerate table{p_end}
{synopt:{cmd:r(maxtries)}}maximum number of times a bootstrap replication will be redrawn{p_end}
{synopt:{cmd:r(seed)}}random seed used (0 if not set){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(var1)}}name of first variable{p_end}
{synopt:{cmd:r(var2)}}name of second variable{p_end}
{synopt:{cmd:r(weight_type)}}weight type used (if weights were used){p_end}
{synopt:{cmd:r(weight)}}weight variable name (if weights were used){p_end}
{synopt:{cmd:r(group)}}by-group variables (if by: used){p_end}
{synopt:{cmd:r(lastgroup)}}value or category label of the sub-sample to which
{cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)}, {cmd:r(ub)}, and {cmd:r(N)} belong (if
{cmd:by:} was used; see also {help loevh2##lastgroup:r(lastgroup)} above){p_end}


{marker seealso}{...}
{title:See also}

{pstd}
{help loevh2} provides asymptotic standard errors and confidence intervals for Loevinger's H.

{pstd}
{help loevh} (if installed) by Jean-Benoit Hardouin provides Loevinger's H coefficient for multiple
items (see {stata ssc describe loevh}).

{pstd}
{help rioc} (if installed) by Daniel Klein calculates the "relative improvement over chance" (RIOC)
coefficient according to Copas & Loeber (1990) together with additional statistics (see {stata ssc describe rioc}).

{pstd}
{help rioci} (if installed) by Daniel Klein is the immediate-command counterpart to {cmd:rioci} (see {stata ssc describe rioc}).


{marker author}{...}
{title:Author}

{pstd}Dirk Enzmann (University of Hamburg) with AI assistance (Claude/Anthropic){p_end}


{marker acknowledgements}{...}
{title:Acknowledgments}

{pstd}
{cmd:loevh2_booti} leans heavily on {cmd:rioci} version 1.0.0 by Daniel Klein (see {stata ssc describe rioc}).


{marker references}{...}
{title:References}

{phang}
Copas, J. B., & Loeber, R. (1990). Relative improvement over chance (RIOC) for 2×2
tables. {it:British Journal of Mathematical and Statistical Psychology}, {it:43}(2), 293–307. {browse "https://doi.org/10.1111/j.2044-8317.1990.tb00942.x":https://doi.org/10.1111/j.2044-8317.1990.tb00942.x}

{phang}
Loevinger, J. A. (1947). A systematic approach to the construction and evaluation of
tests of ability. {it:Psychological Monographs}, {it:61}(4), i–49. {browse "https://doi.org/10.1037/h0093565":https://doi.org/10.1037/h0093565}

{phang}
Mokken, R. J. (1971). {it:A Theory and Procedure of Scale Analysis}. The Hague: Mouton.

{phang}
Warrens, M. J. (2008). On association coefficients for 2×2 tables and properties that do not depend on the marginal
distributions. {it:Psychometrika}, {it:73}(4), 777-789. {browse "https://doi.org/10.1007/s11336-008-9070-3":https://doi.org/10.1007/s11336-008-9070-3}

{phang}
Yule, G. U. (1912). On the methods of measuring association between two
attributes. {it:Journal of the Royal Statistical Society}, {it:75}(6), 579–642. {browse "https://doi.org/10.2307/2340126":https://doi.org/10.2307/2340126}
{phang}
