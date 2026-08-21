{smcl}
{* *! version 3.3  20aug2026}{...}

{vieweralsosee "loevh2_boot" "help loevh2_boot"}{...}
{vieweralsosee "loevh2_svy" "help loevh2_svy"}{...}
{viewerjumpto "Syntax" "loevh2##syntax"}{...}
{viewerjumpto "Description" "loevh2##description"}{...}
{viewerjumpto "Options" "loevh2##options"}{...}
{viewerjumpto "Degenerate tables" "loevh2##degenerate"}{...}
{viewerjumpto "When to trust the results" "loevh2##trust"}{...}
{viewerjumpto "Why no asymmetric-{it:CI} option is offered" "loevh2_svy##asymmetic"}{...}
{viewerjumpto "Examples" "loevh2##examples"}{...}
{viewerjumpto "Stored results" "loevh2##results"}{...}
{title:Title}

{phang}
{bf:loevh2} {hline 2} Calculate Loevinger's {it:H} for two dichotomous variables

{marker syntax}{...}
{title:Syntax}

{pstd}
Loevinger's {it:H} for two dichotomous variables

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

{pstd}
Immediate command, comparing two or more 2×2 tables ({opt c:ompare})

{p 8 17 2}
{cmdab:loevh2i} {it:label1} {it:#a1} {it:#b1} [{cmd:\}] {it:#c1} {it:#d1} {cmd:|} {it:label2} {it:#a2} {it:#b2} [{cmd:\}] {it:#c2} {it:#d2} [{cmd:| ...}] {cmd:,} {opt c:ompare} [{it:immediate_options}]

{p 8 8 2}
where each group consists of a {it:label} followed by that group's four
cell frequencies (entered exactly as above), and groups are separated
by the pipe character {cmd:|} (at least two groups are required). A
{it:label} may be a single unquoted word (e.g. {cmd:M}) or, if it
contains a space or could otherwise be mistaken for a number, must be
enclosed in double quotes (e.g. {cmd:"Kyiv Oblast"} or {cmd:"1"});
each label is limited to 32 characters.

{synoptset 17 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt t:able}}display a 2×2 table with observed and expected counts, and cell percentages{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt p:earson}}calculate Pearson standard error for testing against zero{p_end}
{synopt:{opt s:mall}}calculate confidence interval with small-sample correction{p_end}
{p2coldent:† {opt c:ompare}}test equality of {it:H}s across sub-samples (with {cmd: loevh2}, requires {cmd:by:}){p_end}
{synopt:{opt meta(filename, replace|append)}}save each valid sub-sample's (label,
{it:H}, {it:SE}, {it:N}) row to a persistent .dta file for later meta-analysis{p_end}

{syntab:Immediate command}
{synopt:{opt noTAB}}suppress display of any cross-tabulation{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
† {opt c:ompare} with {cmd:loevh2i} must not use {cmd:by:}.{p_end}
{p 4 6 2}
{cmd:by} is allowed with {cmd:loevh2}, but not with {cmd:loevh2i}; see {manhelp by D}.{p_end}
{p 4 6 2}
{cmd:fweight}s are allowed with {cmd:loevh2}, but not with {cmd:loevh2i}; see {help weight}. For
{cmd:pweight} use {help loevh2_svy}.


{marker description}{...}
{title:Description}

{pstd}
Loevinger's {it:H} coefficient (Loevinger, 1947, pp. 29-31) is a measure of positive association between
two binary variables that is not influenced by their base rates (marginal proportions) -- i.e., it
isolates the proportion of "overlap" between the two variables that goes beyond what their (possibly
very different) base rates alone would predict. Stated differently: Loevinger's {it:H} is a base-rate-independent
measure of overlap corrected for chance and ceiling, i.e. it is independent from how common or rare either
variable is. It answers the question: "How much of the overlap beyond chance is actually
realized?" Warrens (2008, p. 787) shows that Loevinger's {it:H} is "the only linear transformation of
the observed proportion of agreement that has zero value under independence and maximum unity
independent of the marginal distributions."

{pstd}
Loevinger's {it:H} can be expressed as follows:

{center:H = ({it:Total Correct} {c -} {it:Chance Correct}) / ({it:Maximum Correct} {c -} {it:Chance Correct})}

{pstd}
The unique properties of {it:H} are:

{p 4 6}- The {it:chance correction} removes the portion of the raw agreement/overlap that is
attributable exclusively to the two base rates (statistical independence). Two variables with very different base rates
will show some "expected" co-occurence just by chance; the coefficient subtracts this out.{p_end}
{p 4 6}- The {it:ceiling correction} removes the part of the {it:scale} of the coefficient that is
constrained solely by unequal base rates. Without this correction, a coefficient (such as {it:phi}) can
never reach the value 1 if base rates differ, which would confound "imperfect association" with
"unequal base rates." {it:H}'s maximum value of 1 is independent of the marginal distributions.{p_end}
{p 4 6}- However, there is no guarantee that the {it:minimum} value of {it:H} is {c -}1. Therefore, the "overlap"
framing is most natural for {it:positive} associations. For negative associations other coefficients such
as Yule's {it:Y} (Yule, 1912) may be preferable if both directions of association must be treated equally.

{pstd}
Due to these unique properties, the coefficient has been repeatedly (re)invented in various
fields: By Benini (1901, pp. 129-133; first known formulation) in demography (index of
attraction/repulsion) to compare groups of very different size, by Loevinger (1947) in psychometrics
(item homogeneity) to compare items of different difficulty, by Cole (1949) in zoology (coefficient
of interspecific association) to compare co-ocurrence of species in different habitats, and by Copas
& Loeber (1990) in criminology (relative improvement over chance) to compare predictors
and outcomes with mismatched base rates and selection ratios.

{pstd}
Mokken (1971) has adopted Loevinger's {it:H} as a key coefficient in Mokken scale analysis, which is
used to assess the scalability of items. According to Mokken, {it:H} is a measure of scalability whereby

{phang2}- {it:H} = 1 indicates perfect Guttman scalability,{p_end}
{phang2}- {it:H} = 0 indicates no association beyond chance,{p_end}
{phang2}- {it:H} < 0 indicates negative association.{p_end}

{pstd}
(However, because {it:H}'s negative range is not bounded by {c -}1, negative values are less directly
interpretable.) For a pair of dichotomous items, {it:H} > 0.3 suggests sufficient scalability. 

{pstd}
Without being aware of Benini (1901), Loevinger (1947), or Cole (1949), Copas & Loeber (1990) referred to this
coefficient as RIOC (relative improvement over chance) and used it in studies predicting delinquency to correct
prediction indices for chance and for the discrepancy between base rates and selection ratios. Their main contribution
was to propose methods addressing the sample properties problem of RIOC (or {it:H}). They proposed

{p 4 6}- a standard error for large samples (default of {cmd:loevh2}),{p_end}
{p 4 6}- a standard error for the significance test of a single RIOC/{it:H} against zero,{p_end}
{p 4 6}- a confidence interval for small samples,{p_end}
{p 4 6}- formulas for comparing two or more coefficients.{p_end}

{pstd}
By default, {cmd:loevh2} calculates the test statistics (standard error, {it:z}-value, {it:p}-value, and confidence
interval) of {it:H} based on the estimated large-sample variance (see Copas & Loeber, 1990, Eq. 11). This standard error
should be used for meta-analyses of {it:H}. If the upper limit of the confidence interval exceeds 1 due to the
non-normality of {it:H}'s sampling distribution at small {it:N}, {opt s:mall}'s asymmetric small-sample {it:CI} is the more
directly applicable remedy; see also the {help loevh2##trust:"When to trust the results"} section below for when
{help loevh2_boot}'s bootstrap {it:CI} is (and is not) a genuinely more robust alternative in that same small-sample
regime.

{pstd}
Using the option {opt c:ompare} (requires {cmd:by:}), {cmd:loevh2}  performs a test of the equality of the
resulting sub-sample's {it:H}s according to Copas & Loeber (1990, Eq. 16): For each sub-sample i with estimate
H_i and standard error S_i (Copas & Loeber, Eq. 11), define weights w_i = 1/S_i{c 178}. The weighted average of
the sub-samples' {it:H} is

{center:Hbar = sum(w_i*H_i) / sum(w_i)}
{pstd}
The test statistic

{center:chi2 = sum(w_i*H_i{c 178}) {c -} (sum(w_i*H_i)){c 178} / sum(w_i)}

{pstd}
is distributed as chi2 on (i{c - }1) d.f. under the null hypothesis that all population {it:H}s are equal. The
per-sub-sample table of H_i, S_i, and N_i (see below and {help loevh2##Matrices:r(H_SE_N)}) shows/returns the natural,
untransformed values, so that it can also serve as input for a later meta-analysis.


{marker options}{...}
{title:Options}

{phang}
{marker table}{...}
{opt t:able} displays a 2×2 table of the two variables with observed and expected counts, and cell
percentages. With {cmd:loevh2i}, this detailed table replaces the simple frequency-only table shown
by default (see {help loevh2##notab:noTAB} below). Additionally, it displays the percent of
"overlap" in cell 1/1 ({it:var1}=1 & {it:var2}=1), together with its standard error
({cmd:sqrt(p*(1-p)/{it:N})}) and an asymmetric, logit-transformed Wald confidence
interval. {cmd:r(overlap)}, {cmd:r(se_overlap)}, {cmd:r(lb_overlap)}, and {cmd:r(ub_overlap)} are
returned irrespective of {opt t:able}.

{phang}
{opt l:evel(#)} specifies the confidence level, as a percentage, for confidence intervals. The
default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt p:earson} overrides the default setting for the large-sample standard error. It calculates
the standard error to test the difference between {it:H} and the chance value of zero (exact
independence test in a 2×2 table). It should {it:not} be used for meta-analyses since using the
standard error for the null-hypothesis test would misrepresent the actual sampling variability
of each study if the true {it:H} is not equal to zero. Note that the confidence interval shown
is still calculated using the default large-sample standard error.

{phang}
{marker small}{...}
{opt s:mall} overrides the default setting for the large-sample standard error and calculates the
small-sample confidence interval based on the relative risk method (Copas &
Loeber, 1990, Eqs. 20-23). It can be used when the upper limit of the default confidence
interval for large samples exceeds 1 due to the non-normality of the sampling distribution
of {it:H}. The confidence interval tends to be asymmetric, especially for small samples. When using
{opt s:mall}, the standard error, {it:z}-value, and {it:p}-value are not
shown. {help loevh2_boot}'s bootstrap ({it:BCa}) confidence interval is {it:not} a
generally more robust alternative for small samples, despite offering an
alternative asymmetric-{it:CI} construction: simulation evidence (see the
{help loevh2##trust:"When to trust the results"} section below) shows that in
the small-{it:N}/high-|{it:H}| corner where {opt s:mall}'s coverage degrades, the
bootstrap {it:BCa} {it:CI} from {help loevh2_boot} typically degrades at least as
much, and sometimes more, because both anchor tightly around the same
potentially biased point estimate -- neither should be trusted at face
value in that regime without additional safeguards (e.g. bias correction,
or reporting both side by side).

{phang}
{marker compare}{...}
{opt c:ompare} requires {cmd:by:} (or {cmd:bysort:}) if used with {cmd:loevh2} and cannot be
combined with {opt s:mall} or {opt p:earson}. After {it:H} has been estimated for all sub-samples
specified with {cmd:by:} a test of the equality of the resulting {it:H}s is performed and
displayed (Copas & Loeber, 1990, Eq. 16; see {help loevh2##description:Description} above),
analogous to a one-way test of homogeneity of effect sizes in meta-analysis, and shown under
a table listing each sub-sample's {it:H} coefficient, {it:SE}, and {it:N}. Sub-samples with
a degenerate 2×2 table (missing {it:H} or {it:SE}) are excluded from this test. The {it:N}
shown for each sub-sample always reflects the true (unweighted) count. The results are
stored in {cmd:r(Hbar)}, {cmd:r(chi2)}, {cmd:r(df)}, {cmd:r(p_chi2)}, and (as a k×3 matrix
of each sub-sample's {it:H}, {it:SE}, and {it:N}, row-named by sub-sample label)
{cmd:r(H_SE_N)} -- the latter suitable as direct input for a later meta-analysis. Together
with the equality test, {cmd:loevh2} also returns {cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)},
{cmd:r(ub)}, and {cmd:r(N)} for the {it:last valid sub-sample} processed (i.e., the last
by-group with a non-missing by-value and a non-degenerate 2×2 table), together with
{cmd:r(lastgroup)} (see {help loevh2##lastgroup:r(lastgroup)}), to indicate which value
or category these specific results belong to.

{phang}
{marker meta}{...}
{opt meta(filename, replace|append)} saves each valid sub-sample's (label,
{it:H}, {it:SE}, {it:N}) row to a persistent Stata dataset {cmd:filename.dta}, together
with a small set of purely descriptive string columns ({cmd:run_id},
{cmd:source}, {cmd:se_type}, and, only ever populated by
{help loevh2_svy}, {cmd:svy_wtype}/{cmd:svy_wexp}/{cmd:svy_cluster}/
{cmd:svy_strata}/{cmd:svy_fpc} -- always present as columns, but left
empty for rows saved by plain {cmd:loevh2}). Exactly one of {cmd:replace}
or {cmd:append} must be specified (there is no default): {cmd:replace}
overwrites {cmd:filename.dta} (and its companion .do file, see below)
from scratch; {cmd:append} requires {cmd:filename.dta} to already exist
(created by an earlier {cmd:replace}) and adds new row(s) to it. A
timestamp column, {cmd:run_id}, common to every row added by a single
{cmd:meta()} call, lets rows contributed by different invocations
(even to the same file) be told apart later.

{p 8 8}What gets saved depends on whether {opt c:ompare} is also specified:

{p 8 10}- {bf:without {opt c:ompare}} (a plain, non-{cmd:by:} call, or
{cmd:by:} alone): exactly {bf:one} row is saved per {cmd:loevh2} call --
for a plain call, labeled {cmd:"var1_var2"}; for a {cmd:by:} call
(without {opt c:ompare}), one row per by-group is saved AS EACH GROUP IS
PROCESSED, labeled by that by-group's value/category.{p_end}
{p 8 10}- {bf:with {opt c:ompare}}: instead of the single-row save above,
{bf:all} valid sub-samples' rows (exactly the same rows shown in the
{opt c:ompare} table, i.e. {cmd:r(H_SE_N)}) are saved together, once, when
the last by-group of the sequence is processed.

{p 8 8}{opt meta()} is not allowed together with {opt s:mall} or {opt p:earson}
(see {help loevh2##options:Options} above), since neither of those
standard-error types is on the large-sample scale the pooling formula
(and Stata's {help meta} suite) assumes.

{p 8 8}Alongside {cmd:filename.dta}, a small, fully self-contained companion
script {cmd:filename.do} is (re)written on every {opt meta()} call. This
script reloads {cmd:filename.dta} (never the original raw data) and {bf:(a)} sets the
data up for Stata's {help meta} suite to reproduce the results from loevh2 / loevh2_boot
/ loevh2_svy's {opt c:ompare} output (fixed-effects model, assuming all k studies/sub-samples
share exactly ONE true underlying effect; analogous to Copas & Loeber's, 1990,
Eq. 16)). {bf:(b)} The script sets the data up for random-effects model meta analysis
(assuming each study/sub-sample has its OWN true effect, drawn from a distribution of
true effects -- i.e., there is genuine between-study heterogeneity, tau{c 178} > 0);
more commonly recommended if {it:Q} is (strongly) significant. {bf:(c)} If the
meta-analysis data were generated with a sequence of {cmd:loevh2/loevh2i} calls
(using the {opt filename()} option {opt append}), scripts for additional fixed-
and random-effects are set up if the number of groups is >= 2. Further analyses
(meta summarize, subgroup analyses, meta forestplot, etc.) can be run directly on
the pooled results -- possibly combining sub-samples saved from several different
{cmd:loevh2}, {help loevh2_boot}, or {help loevh2_svy} calls (or several different
original datasets), entirely independently of, and without ever needing to reload,
whatever raw dataset(s) the {it:H}/{it:SE}/{it:N} values were originally computed from.

{p 8 8}{bf:NOTE:} Running the companion pooling script (the {cmd:.do} file written
alongside the {cmd:.dta} file, e.g. {cmd:myfile.do}) will {bf:replace the dataset}
{bf:currently in memory} with the pooled meta-analysis results (it begins with
{cmd:use "myfile.dta", clear}). If you run this script in the middle of a longer
analysis session, be sure to reload your own working dataset (and re-issue any
{help svyset}, if applicable) afterward before continuing, or enclose "{help do}
{bf:myfile.do}" between "{help preserve}" and "{cmd:restore}".

{phang}
{marker notab}{...}
{cmd:noTAB} (immediate command only; default) suppresses the display of any 2×2 table with
{cmd:loevh2i}. By default (when neither {opt notab} nor {opt t:able} is specified), {cmd:loevh2i}
displays a simple frequency-only 2×2 table of the entered cell frequencies. Specifying {opt t:able}
instead replaces this simple table with {cmd:loevh2}'s own, more detailed 2×2 table showing
observed and expected counts together with cell percentages plus the percent of "overlap" in cell
1/1 ({it:var1}=1 & {it:var2}=1) (see {help loevh2##table:table} above); the simple table is
not shown in that case. {opt notab} and {opt t:able} cannot be combined.

{phang}
{cmd: by:} When {cmd:by:} (or {cmd:loevhi, {ul:c}ompare}) is used, {marker lastgroup}{...}{cmd:r(lastgroup)}
will be returned, indicating the sub-sample the returned results ({cmd:r(loevh)}, {cmd:r(se)},
{cmd:r(lb)}, {cmd:r(ub)}, {cmd:r(N)}) belong to:

{p 8 10}- For an ordinary (non-missing, non-empty, non-degenerate) by-group call, {cmd:r(lastgroup)}
is simply the value or label of that by-group, and {cmd:r(loevh)} stores that group's results in
r-returns.{p_end}
{p 8 10}- If the by-value for the current by-group call is missing, or the {cmd:if}/{cmd:in}
condition leaves it with zero observations, "missing_byvar" is stored in ({cmd:r(error)} (see
{help loevh2##degenerate:Degenerate tables} below).{p_end}
{p 8 10}- If {opt s:mall} or {opt p:earson} are combined with {cmd:by:} {it:and} if a by-value
has zero observations, {cmd:r(lastgroup)} and the other per-group results will not be stored in
r-returns.{p_end}


{marker examples}{...}
{title:Examples}

{p 4 6}Basic usage{p_end}
{p 8 10}{cmd:. loevh2 item1 item2}{p_end}

{p 4 6}With frequency weights{p_end}
{p 8 10}{cmd:. loevh2 item1 item2 [fw=freq]}{p_end}

{p 4 6}Show cross-tabulation (and percent overlap) and use 99% confidence level{p_end}
{p 8 10}{cmd:. loevh2 item1 item2, table level(99)}{p_end}

{p 4 6}By-group analysis{p_end}
{p 8 10}{cmd:. bysort group: loevh2 item1 item2}{p_end}

{p 4 6}By-group analysis, testing equality of {it:H}s across groups{p_end}
{p 8 10}{cmd:. bysort group: loevh2 item1 item2, compare}{p_end}

{p 4 6}Same as above and saving {it:H}s, {it:SE}s, and {it:N}s to loev_meta.dta{p_end}
{p 8 10}{cmd:. bysort group: loevh2 item1 item2, compare meta(loev_meta, replace)}{p_end}

{p 4 6}Immediate command, enter the four cell frequencies of a 2×2 table directly{p_end}
{p 8 10}{cmd:. }{stata "loevh2i 40 10 \ 5 45"}{p_end}

{p 4 6}Immediate command, suppressing the display of any 2×2 table{p_end}
{p 8 10}{cmd:. }{stata "loevh2i 40 10 \ 5 45, notab"}{p_end}

{p 4 6}Immediate command, comparing two groups (unquoted single-word labels){p_end}
{p 8 10}{cmd:. }{stata "loevh2i M 40 10 \ 5 45 | F 30 20 \ 15 35, compare"}{p_end}

{p 4 6}Immediate command, comparing groups with multi-word labels (must be quoted){p_end}
{p 8 10}{cmd:. }{stata `"loevh2i "Kyiv Oblast" 874 282 \ 432 421 | "Kharkiv Oblast" 900 300 \ 400 450, compare"'}{p_end}

{p 4 6}Immediate command, comparing three or more groups{p_end}
{p 8 10}{cmd:. }{stata `"loevh2i "Sheffield" 274 200 \ 278 3951 | "Leicester" 19 2 \ 139 197 | "Homerton & Fulham" 1103 692 \ 1424 8207, compare"'}{p_end}

{p 4 6}Same as above, creating dta- and do-file "Yule_1912" {it:(must not exist)} to use Stata's
{help meta} suite for meta-analysis of these data{p_end}
{p 8 10}{cmd:. }{stata `"loevh2i "Sheffield" 274 200 \ 278 3951 | "Leicester" 19 2 \ 139 197 | "Homerton & Fulham" 1103 692 \ 1424 8207, c meta("Yule_1912", replace)"'}{p_end}
{p 8 10}{cmd:. }{stata "preserve"}{p_end}
{p 8 10}{cmd:. }{stata "   do Yule_1912.do"}{p_end}
{p 8 10}{cmd:. }{stata "restore"}{p_end}

{p 4 6}Your dataset contains data for a meta-analyses of several studies (e.g. the string
variable "study" and the frequencies of the row cells as numeric variables "vn" (valid
negatives), "fn" (false negatives), "fp" (false positives), and "vp" (valid positives))
and you want to create a dta-file and do-file with filenames "rean_ld83_" to use Stata's
{help meta} suite for your meta-analysis of these data. You can use the immediate
command {cmd:loevh2i} with:{p_end}
{p 8 10}{bf:. local spec = `""`=study[1]'" `=vn[1]' `=fn[1]' `=fp[1]' `=vp[1]'"'}{p_end}
{p 8 10}{bf:. forvalues i = 2/`=_N' {c 123}}{p_end}
{p 8 10}{bf:.{space 4}local spec = `"`spec' | "`=study[`i']'" `=vn[`i']' `=fn[`i']' `=fp[`i']' `=vp[`i']'"'}{p_end}
{p 8 10}{bf:.{space 2}{c 125}}{p_end}
{p 8 10}{bf:. loevh2i `spec', compare meta(rean_ld83_, replace)}{p_end}
{p 8 10}{bf:. perserve}{p_end}
{p 8 10}{bf:.{space 4}do rean_ld83_.do}{p_end}
{p 8 10}{bf:. restore}{p_end}

{p 4 6}Immediate command, showing detailed 2×2 table (and percent overlap) instead of the simple table{p_end}
{p 8 10}{cmd:. }{stata "loevh2i 40 10 \ 5 45, table"}{p_end}

{p 4 6}Immediate command with small-sample confidence interval{p_end}
{p 8 10}{cmd:. }{stata "loevh2i 40 10 \ 5 45, small"}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:loevh2} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(loevh)}}Loevinger's {it:H} coefficient (missing if 2×2 table is degenerate); with
{cmd:by:}, this {it:H} and the follwing r-returns until {bf:r(ub_overlap)} are for the sub-sample
identified by {help loevh2##lastgroup:r(lastgroup)}{p_end}
{synopt:{cmd:r(se)}}standard error (missing if 2×2 table is degenerate){p_end}
{synopt:{cmd:r(lb)}}lower bound of confidence interval (missing if 2×2 table is degenerate){p_end}
{synopt:{cmd:r(ub)}}upper bound of confidence interval (missing if 2×2 table is degenerate){p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(overlap)}}Percent overlap in cell 1/1 ({it:var1}=1 & {it:var2}=1){p_end}
{synopt:{cmd:r(se_overlap)}}Standard error{p_end}
{synopt:{cmd:r(lb_overlap)}}lower bound of confidence interval (logit-transformed){p_end}
{synopt:{cmd:r(ub_overlap)}}upper bound of confidence interval (logit-transformed){p_end}
{synopt:{cmd:r(Hbar)}}weighted average of {it:H}s across sub-samples (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(Hbar_se)}}pooled (inverse-variance-weighted) standard error of {cmd:r(Hbar)}
(only with {opt c:ompare}){p_end}
{synopt:{cmd:r(chi2)}}chi2 test statistic for equality of {it:H}s across sub-samples (only with
{opt c:ompare}){p_end}
{synopt:{cmd:r(df)}}degrees of freedom of the chi2 test (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(p_chi2)}}{it:p}-value of the chi2 test (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(Hbar_N)}}total number of observations summed across all valid sub-samples
(only with {opt c:ompare}){p_end}

{marker Matrices}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(H_SE_N)}}k×3 matrix of each sub-sample's untransformed {it:H}, {it:SE}, and {it:N} (columns),
row-named by sub-sample label (only with {opt c:ompare}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(var1)}}name of row variable{p_end}
{synopt:{cmd:r(var2)}}name of column variable{p_end}
{synopt:{cmd:r(se_type)}}type of standard error{p_end}
{synopt:{cmd:r(weight_type)}}weight type used (if weights were used){p_end}
{synopt:{cmd:r(weight)}}weight variable name (if weights were used){p_end}
{synopt:{cmd:r(group)}}by-group variable(s) (if {cmd:by:} was used){p_end}
{synopt:{cmd:r(lastgroup)}}value or category label of the sub-sample to which
{cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)}, {cmd:r(ub)}, and {cmd:r(N)} belong (if
{cmd:by:} was used; see also {help loevh2##lastgroup:r(lastgroup)} above){p_end}
{synopt:{cmd:r(error)}}{cmd:"degenerate"} if the 2×2 table has a zero cell or margin,
so that {it:H} is undefined (see {help loevh2##degenerate:Degenerate tables} below), or
{cmd:"missing_byvar"} if this by-group was skipped because its by-value is missing or the
{cmd:if}/{cmd:in} condition left no observations for it{p_end}


{marker degenerate}{...}
{title:Degenerate tables}

{pstd}
Loevinger's {it:H} (and its standard error) requires that all four cells of the 2×2 table, as well
as all four margins, be strictly positive; otherwise {it:H} involves division by zero and is
undefined. Such a {it:degenerate} 2×2 table can occur, e.g., when one of the two variables is (nearly)
constant in the sample or subsample being analyzed -- this is most likely to happen in small
samples, in {help bysort:by-group} analyses with small groups, or during bootstrap resampling
(see {help loevh2_boot}).

{pstd}
When {cmd:loevh2} detects a degenerate 2×2 table, it does not abort with an error. Instead, it
displays a warning (unless the undocumented option {cmd:_boot} is specified, which is used
internally by {help loevh2_boot} to suppress per-replication warnings during bootstrapping) and
returns missing values for {cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)}, and {cmd:r(ub)}, together
with {cmd:r(error) = "degenerate"}.


{marker trust}{...}
{title:When to trust the results}

{pstd}
A large Monte Carlo simulation study examined the coverage of {cmd:loevh2}'s default
large-sample confidence interval, its {opt s:mall}-sample interval, and {help loevh2_boot}'s
bootstrap interval, across a wide grid of {it:N}, true {it:H}, and base-rate combinations. The main
conclusions in deciding {it:whether to trust the default CI at all, or to reach for the small sample CI or to loevh2_boot instead},
are:

{phang2}1. {bf:N >= ~500-1,000 and |{it:H}-hat| not close to 1 (say < 0.7):} the default
large-sample {it:CI} (Copas & Loeber, Eq. 11) is close to nominal 95% coverage. There is little
practical benefit from {opt s:mall} or {help loevh2_boot} in this regime -- use the default.{p_end}

{phang2}2. {bf:N small (< ~250) and/or |{it:H}-hat| large (> ~0.7-0.8):} {it:all} {it:CI} methods --
the default large-sample {it:CI}, {opt s:mall}, and {help loevh2_boot}'s bootstrap {it:BCa} {it:CI} -- can
perform poorly, in different directions. The default {it:CI} tends to {it:over-cover} deceptively
(its width happens to reach a badly biased {it:H}-hat more or less by coincidence, not because it is
well calibrated); {opt s:mall} and the bootstrap {it:BCa} {it:CI} can {it:catastrophically under-cover}
(down to 0.00 in the worst simulation scenarios), because both anchor tightly around the same badly biased
point estimate. {bf:Do not trust any single {it:CI} method at face value here.} The single biggest
remedy is increasing {it:N}. If {it:N} cannot be increased: report {it:H}-hats and {it:CI}s from more than one
method side by side, and consider a bootstrap bias-corrected point estimate
({cmd:hbootbc = 2*H {c -} mean(bootstrap replicate {it:H})}, obtainable from {cmd:loevh2_boot}'s
{help loevh2_boot##bccorrect:{ul:bc}correct} option; ({it:not} jackknife, which the simulation study shows worsens bias).{p_end}

{phang2}3. {bf:N < ~500 and |{it:H}-hat| < ~0.7 -- is {opt s:mall} worth using?} In this region
(away from the severe small-{it:N}/large-{it:H} corner covered in point 2), neither the default
large-sample {it:CI} nor {opt s:mall}'s asymmetric {it:CI} is clearly, consistently better calibrated
-- across the simulation grid, {opt s:mall}'s coverage is closer to nominal 95% in only about
45% of scenarios, and both methods' average deviation from nominal coverage is under ~2-3
percentage points. If anything, {opt s:mall} offers a modest calibration improvement for {it:N}
roughly 100-250 with balanced to moderately imbalanced base rates of {it:var1} and {it:var2}
(ratio up to ~4-8:1), while the default {it:CI} remains at least as good for {it:N} <= 50 or for
highly imbalanced base rates (ratio >~8:1) at any {it:N} in this range. In short: do not expect
{opt s:mall} to systematically fix coverage here -- check both, but neither is a clear default
recommendation over the other in this specific corner.

{phang2}4. {bf:{opt c:ompare}/meta-analysis:} before trusting the inverse-variance-weighted
{cmd:Hbar}/chi2 test, flag or exclude any sub-sample with {it:N} < ~250 or |{it:H}-hat| > ~0.7 -- the
weighting by {cmd:1/{it:SE}{c 178}} implicitly assumes each sub-sample's {it:H}-hat is approximately unbiased,
which is exactly what fails in this corner (see {cmd:r(H_SE_N)} above). This caution applies
whether the weighting {it:SE} comes from {bf:loevh2}'s {help loevh2##compare:{ul:c}ompare} (Eq. 11) or
from {cmd:loevh2_boot}'s {help loevh2_boot##compare:{ul:c}ompare}} ({bf:boot_se}) -- switching to the
bootstrap {it:SE} does not fix it.{p_end}

{phang2}5. {bf:When loevh2_boot itself can be trusted (its "safe zone"):} the simulation grids for
the region where mean bootstrap {it:CI} coverage reaches >= 0.85 gave the answer: |{it:H}-hat| <= ~0.85;
{it:N} at least ~100-150 when the two variables' base rates are roughly balanced (ratio <= 3), rising
to ~200-250 when the base-rate ratio is 3:1 or worse; and, if {cmd:pweight} is used
(see {help loevh2_svy}), no detectable correlation between the weight and the outcome variables
(even a mild correlation drops coverage from ~0.90 to ~0.82). Outside this zone, treat
{help loevh2_boot} (like the default {it:CI} here) with extra scepticism, and prefer bias correction
or increasing {it:N} over trusting any single {it:CI} method.{p_end}

{pstd}
For a discussion of asymmetric confidence intervals also {cmd:loevh2_svy's}
{help loevh2_svy##asymmetric:"Why no asymmetric-{it:CI} option is offered"}.


{marker seealso}{...}
{title:See also}

{phang}
{help loevh2_boot} provides bootstrap confidence intervals for Loevinger's {it:H}, which may be more robust
when sample sizes are small or asymptotic assumptions are not met -- see also the
{help loevh2##trust:"When to trust the results"} section above for when this actually holds.{p_end}

{phang}
{help loevh2_svy} provides survey-design-based ({help svyset}) estimation of Loevinger's {it:H}, and is the
recommended command for {cmd:pweight}/complex-survey data.{p_end}

{phang}
{help loevh} (if installed) by Jean-Benoit Hardouin calculates Loevinger's {it:H} coefficient for multiple
items (see {stata ssc describe loevh}).{p_end}

{phang}
{help rioc} (if installed) by Daniel Klein calculates the "relative improvement over chance" (RIOC)
coefficient according to Copas & Loeber (1990) together with additional statistics (see {stata ssc describe rioc}).{p_end}

{phang}
{help rioci} (if installed) by Daniel Klein is the immediate-command counterpart to {cmd:rioc}
(see {stata ssc describe rioc}).{p_end}


{marker author}{...}
{title:Author}

{pstd}Dirk Enzmann (University of Hamburg) with AI assistance (Claude/Anthropic){p_end}


{marker acknowledgements}{...}
{title:Acknowledgments}

{phang}
Daniel Klein's critical comments and his suggestion to use {help nlcom} for using population weights greatly helped to
improve {cmd:loevh2}. {cmd:loevhi} leans heavily on {cmd:rioci} version 1.0.0 by Daniel Klein (see {stata ssc describe rioc}).{p_end}


{marker references}{...}
{title:References}

{phang}
Benini, R. (1901). {it:Principii di Demografia}. Florence: G. Barbèra. {browse "https://archive.org/details/principiididemo00benigoog/page/n143/mode/2up":https://archive.org/details/principiididemo00benigoog/page/n143/mode/2up}

{phang}
Cole, L. C. (1949). The measurement of interspecific associaton. {it:Ecology}, {it:30}(4),
411–424. {browse "https://esajournals.onlinelibrary.wiley.com/doi/10.2307/1932444":https://esajournals.onlinelibrary.wiley.com/doi/10.2307/1932444}

{phang}
Copas, J. B., & Loeber, R. (1990). Relative improvement over chance (RIOC) for 2×2
tables. {it:British Journal of Mathematical and Statistical Psychology}, {it:43}(2),
293–307. {browse "https://doi.org/10.1111/j.2044-8317.1990.tb00942.x":https://doi.org/10.1111/j.2044-8317.1990.tb00942.x}

{phang}
Loevinger, J. A. (1947). A systematic approach to the construction and evaluation of
tests of ability. {it:Psychological Monographs}, {it:61}(4),
i–49. {browse "https://doi.org/10.1037/h0093565":https://doi.org/10.1037/h0093565}

{phang}
Mokken, R. J. (1971). {it:A Theory and Procedure of Scale Analysis}. The Hague: Mouton.

{phang}
Warrens, M. J. (2008). On association coefficients for 2×2 tables and properties that do not depend on the marginal
distributions. {it:Psychometrika}, {it:73}(4), 777-789. {browse "https://doi.org/10.1007/s11336-008-9070-3":https://doi.org/10.1007/s11336-008-9070-3}

{phang}
Yule, G. U. (1912). On the methods of measuring association between two
attributes. {it:Journal of the Royal Statistical Society}, {it:75}(6), 579–642. {browse "https://doi.org/10.2307/2340126":https://doi.org/10.2307/2340126}
{phang}
