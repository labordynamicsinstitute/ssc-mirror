{smcl}
{* *! version 3.2  13jul2026}{...}

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

{pstd}
Loevinger's H for two dichotomous variables

{p 8 17 2}
{cmdab:loevh2} {varlist} {ifin} [{it:weight}] [{cmd:,} {it:options}]

{pstd}
Immediate command

{p 8 17 2}
{cmdab:loevh2i} {it:#a} {it:#b} [{cmd:\}] {it:#c} {it:#d} [{cmd:,} {it:immediate_options}]

{p 8 8 2}
where {it:#a}, {it:#b}, {it:#c}, and {it:#d} are the four (nonnegative
integer) cell frequencies of the 2×2 cross-tabulation of the two
variables, entered row by row (first row: {it:#a} {it:#b}; second row:
{it:#c} {it:#d}), exactly as for Stata's own {help tabi}. The backslash
separating the two rows is optional, e.g. {cmd:loevh2i 40 10 5 45} and
{cmd:loevh2i 40 10 \ 5 45} are equivalent.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt t:able}}display a 2×2 table with observed and expected counts, and cell percentages{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt p:earson}}calculate Pearson standard error for testing against zero{p_end}
{synopt:{opt s:mall}}calculate confidence interval with small-sample correction{p_end}
{p2coldent:* {opt compare}}test equality of H's across sub-samples (requires {cmd:by:}){p_end}
{p2coldent:† {opt abbreviate(#)}}abbreviate variable names to # characters; default is {cmd:abbreviate(8)}){p_end}

{syntab:Immediate command}
{synopt:{opt noTAB}}suppress display of any cross-tabulation{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt compare} is available only for {cmd:loevh2}.{p_end}
{p 4 6 2}
† {opt abbreviate} is available only for {cmd:loevh2}.{p_end}
{p 4 6}
{cmd:by} is allowed with {cmd:loevh2}, but not with {cmd:loevh2i}; see {manhelp by D}.{p_end}
{p 4 6}
{cmd:aweight}s and {cmd:fweight}s are allowed with {cmd:loevh2}, but not with {cmd:loevh2i}; see {help weight}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
Loevinger's H coefficient (Loevinger, 1947, pp. 29-31) is a measure of positive association between
two binary variables that is not influenced by their base rates (marginal proportions) -- i.e., it
isolates the proportion of "overlap" between the two variables that goes beyond what their (possibly
very different) base rates alone would predict. Stated differenty: Loevinger's H is a base-rate-independent
measure of overlap corrected for chance and ceiling, i.e. it is independent from how common or rare either
variable is. It answers the question: "How much of the overlap beyond chance is actually
realized?". Warrens (2008, p. 787) shows that Loevinger's H is "the only linear transformation of
the observed proportion of agreement that has zero value under independence and maximum unity
independent of the marginal distributions."

{pstd}
Loevinger's H can be expressed as follows:

{center:H = ({it:Total Correct} {c -} {it:Chance Correct}) / ({it:Maximum Correct} {c -} {it:Chance Correct})}

{pstd}
The unique properties of H are:

{p 4 6}- The {it:chance correction} removes the portion of the raw agreement/overlap that is
attributable exclusively to the two base rates (statistical independence). Two variables with very different base rates
will show some "expected" co-occurance just by chance; the coefficient substracts this out.{p_end}
{p 4 6}- The {it:ceiling correction} removes the part of the {it:scale} of the coefficient that is
constraint solely by unequal base rates. Without this correction, a coefficient (such as {it:phi}) can
never reach the value 1 if base rates differ, which would confound "imperfect association" with
"unequal base rates." H's maximum value of 1 is independent of the marginal distributions.{p_end}
{p 4 6}- However, there is no guarantee that the {it:minimum} value of H is {c -}1. Therefore, the "overlap"
framing is most natural for {it:positive} associations. For negative associations other coefficients such
as Yule's Y (Yule, 1912) may be preferable if both directions of association must be treated equally.

{pstd}
Due to these unique properties, the coefficient has been repeatedly (re)invented in various
fields: By Benini (1901, pp. 129-132; first known formulation) in demography (index of
attraction/repulsion) to compare groups of very different size, by Loevinger (1947) in psychometrics
(item homogeneity) to compare items of different difficulty, by Cole (1949) in zoology (coefficient
of interspecific association) to compare co-ocurrence of species in different habitats, and by Copas
& Loeber (1990) in criminology (relative improvement over chance) to compare predictors
and outcomes with mismatched base rates and selection ratios.

{pstd}
Mokken (1971) has adopted Loevinger's H as a key coefficient in Mokken scale analysis, which is
used to assess the scalability of items. According to Mokken, H is a measure of scalability whereby

{phang2}- H = 1 indicates perfect Guttman scalability,{p_end}
{phang2}- H = 0 indicates no association beyond chance,{p_end}
{phang2}- H < 0 indicates negative association.{p_end}

{pstd}
For a pair of dichotomous items, H > 0.3 suggests sufficient scalability. 

{pstd}
Without being aware of Benini (1901), Loevinger (1947), or Cole (1949), Copas & Loeber (1990) referred to this
coefficient as RIOC (relative improvement over chance) and used it in studies predicting delinquency to correct
prediction indices for chance and for the discrepancy between base rates and selection ratios. Their main contribution
was to propose methods addressing the sample properties problem of RIOC (or H). They proposed

{p 4 6}- a standard error for large samples (default of {cmd:loevh2}),{p_end}
{p 4 6}- a standard error for the significance test of a single RIOC/H against zero,{p_end}
{p 4 6}- a confidence intervall for small samples,{p_end}
{p 4 6}- formulas for comparing two or more coefficients.{p_end}

{pstd}
By default, {cmd:loevh2} calculates the test statistics (standard error, {it:z}-value, {it:p}-value, and confidence
interval) of H based on the estimated large-sample variance (see Copas & Loeber, 1990, Eq. 11). This standard error
should be used for meta-analyses of H. For smaller samples, or if the upper limit of the confidence interval exeeds
1, {help loevh2_boot} can be used instead. 

{pstd}
Using the option {opt compare} (requires {cmd:by:}), {cmd:loevh2}  performs a test of the equality of the
resulting sub-sample's H's according to Copas & Loeber (1990, Eq. 16): For each sub-sample i with estimate
H_i and standard error S_i (Copas & Loeber, Eq. 11), define weights w_i = 1/S_i^2. The weighted average of
the sub-samples' H is

{center:Hbar = sum(w_i*H_i) / sum(w_i)}
{pstd}
The test statistic

{center:chi2 = sum(w_i*H_i^2) - (sum(w_i*H_i))^2 / sum(w_i)}

{pstd}
is distributed as chi2 on (i-1) d.f. under the null hypothesis that all population H's are equal.


{marker options}{...}
{title:Options}

{phang}
{marker table}{...}
{opt table} displays a 2×2 table of the two variables with observed and expected counts, and cell
percentages. With {cmd:loevh2i}, this detailed table replaces the simple frequency-only table shown
by default (see {help loevh2##notab:noTAB} below).

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals. The
default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt pearson} overrides the default setting for the large-sample standard error. It calculates
the standard error to test the difference between H and the chance value of zero (exact
independence test in a 2×2 table). It should {it:not} be used for meta-analyses since using the
standard error for the null-hypothesis test would misrepresent the actual sampling variability
of each study if the true H is not equal to zero. Note that the confidence interval shown
is still calculated using the default large-sample standard error.

{phang}
{opt small} overrides the default setting for the large-sample standard error and calculates the
small-sample confidence interval based on the relative risk method (Copas &
Loeber, 1990, Eqs. 20-23). It can be used when the upper limit of the default confidence
interval for large samples exceeds 1 due to the non-normality of the sampling distribution
of H. The confidence interval tends to be asymmetric, especially for small samples. When using
{opt small}, the standard error, {it:z}-value, and {it:p}-value are not
shown. Alternatively, confidence intervals can be calculated using {help loevh2_boot} which
may be more robust for small sample sizes or when asymptotic assumptions are not met.

{phang}
{opt compare} requires {cmd:by:} (or {cmd:bysort:}) and cannot be combined with {opt small}
or {opt pearson}. After H has been estimated for all sub-samples specified with {cmd:by:} a
test of the equality of the resulting H's is performed and displayed (Copas &
Loeber, 1990, Eq. 16), analogous to a one-way test of homogeneity of effect sizes in
meta-analysis, and shown under a table listing each sub-sample's H coefficient, standard
error, and number of observations. Sub-samples with a degenerate 2×2 table (missing H or SE)
are excluded from this test. The number of observations shown for each sub-sample always
reflects the true (unweighted) count, whether or not {cmd:aweight}s were used. The results
are stored in {cmd:r(Hbar)}, {cmd:r(chi2)}, {cmd:r(df)}, and {cmd:r(p_chi2)}. Together with
the equality test, {cmd:loevh2} also returns {cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)}, {cmd:r(ub)}, and
{cmd:r(N)} for the {it:last valid sub-sample} processed (i.e., the last by-group with a
non-missing by-value and a non-degenerate 2×2 table), together with {cmd:r(lastgroup)} (see
{help loevh2##lastgroup:r(lastgroup)}), to indicate which value or category these
specific results belong to. Available only with {cmd:loevh2}.

{phang}
{opt abbreviate(#)} specifies the number of characters to which variable names are abbreviated
in the output. The default is {cmd:abbreviate(8)}. Available only with {cmd:loevh2}.

{phang}
{marker notab}{...}
{cmd:noTAB} (immediate command only; default) suppresses the display of any 2×2 table with
{cmd:loevh2i}. By default (when neither {opt notab} nor {opt table} is specified), {cmd:loevh2i}
displays a simple frequency-only 2×2 table of the entered cell frequencies. Specifying {opt table}
instead replaces this simple table with {cmd:loevh2}'s own, more detailed 2×2 table showing
observed and expected counts together with cell percentages (see {help loevh2##table:table} above); the
simple table is not shown in that case. {opt notab} and {opt table} cannot be combined.

{phang}
{cmd: by:} When {cmd:by:} is used, {marker lastgroup}{...}{cmd:r(lastgroup)} will be returned, indicating the
sub-sample the returned results ({cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)}, {cmd:r(ub)}, {cmd:r(N)}) belong to:

{p 8 10}- For an ordinary (non-missing, non-empty, non-degenerate) by-group call, {cmd:r(lastgroup)}
is simply the value or label of that by-group, and {cmd:r(loevh)} stores that group's results in
r-returns.{p_end}
{p 8 10}- If the by-value for the current by-group call is missing, or the {cmd:if}/{cmd:in}
condition leaves it with zero observations, "missing_byvar" is stored in ({cmd:r(error)} (see
{help loevh2##degenerate:Degenerate tables} below).{p_end}
{p 8 10}- If {opt small} or {opt pearson} are combined with {cmd:by:} {it:and} and
if a by-value has zero observations, {cmd:r(lastgroup)} and the other per-group results will
not be stored in r-returns.{p_end}


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

{pstd}By-group analysis, testing equality of H's across groups{p_end}
{phang2}{cmd:. bysort group: loevh2 item1 item2, compare}{p_end}

{pstd}Immediate command, enter the four cell frequencies of a 2×2 table directly{p_end}
{phang2}{cmd:. loevh2i 40 10 \ 5 45}{p_end}

{pstd}Immediate command, suppressing the display of any 2×2 table{p_end}
{phang2}{cmd:. loevh2i 40 10 \ 5 45, notab}{p_end}

{pstd}Immediate command, showing detailed 2×2 table instead of the simple table{p_end}
{phang2}{cmd:. loevh2i 40 10 \ 5 45, table}{p_end}

{pstd}Immediate command with small-sample confidence interval{p_end}
{phang2}{cmd:. loevh2i 40 10 \ 5 45, small}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:loevh2} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(loevh)}}Loevinger's H coefficient (missing if 2×2 table is degenerate); with
{cmd:by:}, this is H for the sub-sample identified by {cmd:r(lastgroup)}{p_end}
{synopt:{cmd:r(se)}}standard error (missing if 2×2 table is degenerate){p_end}
{synopt:{cmd:r(lb)}}lower bound of confidence interval (missing if 2×2 table is degenerate){p_end}
{synopt:{cmd:r(ub)}}upper bound of confidence interval (missing if 2×2 table is degenerate){p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(Hbar)}}weighted average H across sub-samples (only with {opt compare}){p_end}
{synopt:{cmd:r(chi2)}}chi2 test statistic for equality of H's across sub-samples (only with {opt compare}){p_end}
{synopt:{cmd:r(df)}}degrees of freedom of the chi2 test (only with {opt compare}){p_end}
{synopt:{cmd:r(p_chi2)}}p-value of the chi2 test (only with {opt compare}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(var1)}}name of first variable{p_end}
{synopt:{cmd:r(var2)}}name of second variable{p_end}
{synopt:{cmd:r(se_type)}}type of standard error{p_end}
{synopt:{cmd:r(weight_type)}}weight type used (if weights were used){p_end}
{synopt:{cmd:r(weight)}}weight variable name (if weights were used){p_end}
{synopt:{cmd:r(group)}}by-group variable(s) (if {cmd:by:} was used){p_end}
{synopt:{cmd:r(lastgroup)}}value or category label of the sub-sample to which
{cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)}, {cmd:r(ub)}, and {cmd:r(N)} belong (if
{cmd:by:} was used; see also {help loevh2##lastgroup:r(lastgroup)} above){p_end}
{synopt:{cmd:r(error)}}{cmd:"degenerate"} if the 2×2 table has a zero cell or margin,
so that H is undefined (see {help loevh2##degenerate:Degenerate tables} below), or
{cmd:"missing_byvar"} if this by-group was skipped because its by-value is missing or the
{cmd:if}/{cmd:in} condition left no observations for it{p_end}


{marker degenerate}{...}
{title:Degenerate tables}

{pstd}
Loevinger's H (and its standard error) requires that all four cells of the 2×2 table, as well
as all four margins, be strictly positive; otherwise H involves division by zero and is
undefined. Such a {it:degenerate} 2×2 table can occur, e.g., when one of the two variables is (nearly)
constant in the sample or subsample being analyzed -- this is most likely to happen in small
samples, in {help bysort:by-group} analyses with small groups, or during bootstrap resampling
(see {help loevh2_boot}).

{pstd}
When {cmd:loevh2} detects a degenerate 2×2 table, it does not abort with an error. Instead, it
displays a warning (unless the undocumented option {cmd:_boot} is specified, which is used
internally by {cmd:loevh2_boot} to suppress per-replication warnings during bootstrapping) and
returns missing values for {cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)}, and {cmd:r(ub)}, together
with {cmd:r(error) = "degenerate"}.


{marker seealso}{...}
{title:See also}

{pstd}
{help loevh2_boot} provides bootstrap confidence intervals for Loevinger's H, which may be more robust
when sample sizes are small or asymptotic assumptions are not met.

{pstd}
{help loevh} (if installed) by Jean-Benoit Hardouin calculates Loevinger's H coefficient for multiple
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
{cmd:loevh2i} leans heavily on {cmd:rioci} version 1.0.0 by Daniel Klein (see {stata ssc describe rioc}).


{marker references}{...}
{title:References}

{phang}
Benini, R. (1901). {it:Principii di Demografia}. Florence: G. Barbèra. {browse "https://archive.org/details/principiididemo00benigoog/page/n143/mode/2up":https://archive.org/details/principiididemo00benigoog/page/n143/mode/2up}

{phang}
Cole, L. C. (1949). The measurement of interspecific associaton. {it:Ecology}, {it:30}(4), 411–424. {browse "https://esajournals.onlinelibrary.wiley.com/doi/10.2307/1932444":https://esajournals.onlinelibrary.wiley.com/doi/10.2307/1932444}

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
