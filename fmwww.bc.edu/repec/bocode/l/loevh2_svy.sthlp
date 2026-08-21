{smcl}
{* *! version 1.0  20aug2026}{...}

{vieweralsosee "loevh2" "help loevh2"}{...}
{vieweralsosee "loevh2_boot" "help loevh2_boot"}{...}
{viewerjumpto "Syntax" "loevh2_svy##syntax"}{...}
{viewerjumpto "Description" "loevh2_svy##description"}{...}
{viewerjumpto "Options" "loevh2_svy##options"}{...}
{viewerjumpto "Degenerate tables and estimation failures" "loevh2_svy##degenerate"}{...}
{viewerjumpto "Why no asymmetric-{it:CI} option is offered" "loevh2_svy##asymmetic"}{...}
{viewerjumpto "When to trust the results" "loevh2##trust"}{...}
{viewerjumpto "Examples" "loevh2_svy##examples"}{...}
{viewerjumpto "Stored results" "loevh2_svy##results"}{...}
{title:Title}

{phang}
{bf:loevh2_svy} {hline 2} Design-based (survey) standard error and confidence
interval for Loevinger's {it:H}, using {help svyset}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:loevh2_svy} {varlist} {ifin} [{cmd:,} {it:options}]

{synoptset 17 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt t:able}}display the design-based cross tabulation of cell
percentages (via {cmd:svy: tabulate}) and the Pearson chi2 test{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt c:ompare}}test equality of {it:H}s across sub-samples (requires {cmd:by:}){p_end}
{synopt:{opt meta(filename, replace|append)}}save each valid sub-sample's
(label, {it:H}, {it:SE}, {it:N}) row to a persistent .dta file for later meta-analysis{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6}
{cmd:by} is allowed; see {manhelp by D}.{p_end}
{p 4 6}
No {help weight} is specified on the {cmd:loevh2_svy} command line itself --
weighting, clustering, and stratification are all taken from a
previously issued {help svyset} declaration; see {help loevh2_svy##description:Description}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:loevh2_svy} calculates Loevinger's {it:H} coefficient (Loevinger, 1947; see
{help loevh2} for the full definition, properties, and references) together
with a genuinely {it:design-based} (survey) standard error and confidence
interval, honoring an active {help svyset} declaration's sampling weight
({cmd:pweight}/{cmd:iweight}), clustering ({cmd:cluster()}), and/or
stratification ({cmd:strata()}) -- exactly as any other {cmd:svy:} estimation
command would. {cmd:loevh2_svy} does not accept a {help weight} on its own
command line; any weighting comes exclusively from the {cmd:svyset} declaration.

{pstd}
{cmd:loevh2_svy} obtains its {it:H} estimate and standard error via
{help svy_estimation:svy: mean} on four constructed cell-membership indicators, followed
by {help nlcom}'s delta method applied to Copas & Loeber's {it:H} formula written as
a nonlinear combination of those four cell proportions. Because {help svy_estimation:svy: mean}
already correctly incorporates {cmd:pweight}, {cmd:cluster()}, and/or {cmd:strata()}
into its variance-covariance matrix, the resulting {help nlcom} standard error
for {it:H} is a true design-based (linearized Taylor-series) survey standard error --
analogous to how one would obtain a design-based {it:SE} for any other nonlinear
function of survey-estimated proportions.{p_end}

{pstd}
{cmd:loevh2_svy} therefore requires an active {help svyset} design with at
least one of {cmd:pweight}/{cmd:iweight}, {cmd:cluster()}, or {cmd:strata()}
genuinely set. A plain {cmd:svyset _n} with none of these is rejected, since
{cmd:loevh2_svy} would then offer no benefit over the faster, better documented
{help loevh2}. If no {cmd:svyset} design (or only a degenerate one) is active,
{cmd:loevh2_svy} exits with an error pointing the user to {help loevh2} instead.

{marker caution}{...}
{pstd}
{bf:Caution:} a bare {cmd:pweight}-only svyset (no {cmd:cluster()}, no {cmd:strata()})
is syntactically valid and accepted by {cmd:loevh2_svy}, but it corrects only for
unequal probability of selection in the point estimate -- it does NOT correct
standard errors for any real clustering or stratification present in the actual
sampling design. If the true design includes clustering (e.g. respondents nested
within schools, interviewers, or areas) that is not declared via {cmd:cluster()},
the resulting {it:SE}/{it:CI} for {it:H} can understate the true sampling variability, sometimes
substantially. Before using {cmd:pweight} alone, confirm whether your sampling
design actually has a clustering/stratification structure that should be declared;
consult your data codebook/technical documentation or a survey statistician if
unsure. This risk is compounded when the weights are themselves correlated with
the outcome variables under study (see {cmd:loevh2}'s {help loevh2##trust:"When to trust the results"}
section, item 5, for a related, empirically documented instance of this general
phenomenon in the bootstrap-{it:SE} context).

{pstd}
{cmd:loevh2_svy} always displays a brief design summary header (number of
strata, PSUs, obs, population size, subpop size, and design df). Because
this design df is computed from {cmd:subpop()} ({help loevh2_svy##subpop:see below}), it reflects the
{it:full} svyset-declared sample size, not just the observations with
non-missing {it:var1}/{it:var2} -- so it will typically be {it:larger} than
the design df shown by a plain {mansection SVY svytabulatetwoway:svy: tabulate} / {help svy_estimation:svy: mean} on the
same two variables under the same {help svyset} (which automatically
restricts to non-missing observations only). This is expected and correct
(see the note on {help loevh2_svy##subpop:subpop()} below), not a discrepancy to be concerned
about. This part is followed by {it:H} with its design-based {it:SE}/{it:CI}.

{pstd}
If the {opt t:able} option is specified, it additionally displays, a design-based
{it:cross tabulation} of the two variables (cell percentages and a Pearson chi2
test), obtained via {mansection SVY svytabulatetwoway:svy: tabulate} and as this command
would display them. Additionally, it displays the percent of "overlap" in cell 1/1
({it:var1}=1 & {it:var2}=1), together with its standard error and an asymmetric,
logit-transformed Wald confidence interval. {cmd:r(overlap)} (as a proportion),
{cmd:r(se_overlap)}, {cmd:r(lb_overlap)}, and {cmd:r(ub_overlap)} are returned
irrespective of {opt t:able}. By default ({opt t:able} not specified), neither
the cross tabulation nor the overlap summary is shown (only the design summary
header plus the {it:H} results table).

{pstd}
Unlike {it:H} itself (which can be negative, and for which the analogous logit
construction was found to perform poorly -- see
{help loevh2_svy##asymmetric:"Why no asymmetric-{it:CI} option is offered"} below --
the overlap proportion is a genuine bounded parameter in [0,1], the textbook
use case for a logit-transformed {it:CI}: the {it:CI} is obtained by applying
{help nlcom}'s delta method to logit (overlap) and back-transforming the
resulting Wald interval with the inverse-logit function, guaranteeing
a {it:CI} that always stays within [0,1] and is naturally asymmetric.

{pstd}
{marker subpop}{...}
Internally, {cmd:loevh2_svy} uses {mansection SVY Subpopulationestimation:svy, subpop()} rather than filtering
the estimation sample with a plain {cmd:if} condition, so that any
{cmd:if}/{cmd:in}/{cmd:by:} restriction is handled the statistically
correct way for a complex survey design (retaining the full PSU/strata
information for variance estimation while restricting point estimation to
the relevant subpopulation), rather than potentially biasing the variance
estimate by silently dropping PSU/stratum information for excluded
observations.

{pstd}
The underlying nonlinear {it:H} expression (matching {help loevh2}'s own {it:H} formula),
and its "swap" convention -- which assigns the {cmd:cell 1/0} role to whichever
off-diagonal cell belongs to the variable with the {it:smaller} marginal
probability of being 1 (i.e. based on comparing the two margins {it:P}({it:var1}=1)
vs. {it:P}({it:var2}=1)) is:

{center:H = 1 {c -} p_10 / [(p_11 + p_10) × (1 {c -} (p_11 + p_01))]}

{pstd}
where p_11, p_10, p_01 (and implicitly p_00 = 1-p_11-p_10-p_01) are the four
joint cell proportions of the two binary variables, estimated via {help svy_estimation:svy: mean}.


{marker options}{...}
{title:Options}

{phang}
{opt t:able} displays the design-based cross tabulation of cell percentages
(and a Pearson chi2 test), obtained via {mansection SVY svytabulatetwoway:svy: tabulate}. Additionally,
it displays the percent of "overlap" in cell 1/1 ({it:var1}=1 & {it:var2}=1),
together with its standard error ({cmd:sqrt(p*(1-p)/N)}) and an asymmetric,
logit-transformed Wald confidence interval. By default ({opt t:able} not specified),
this cross tabulation and percent overlap are not shown. {cmd:r(overlap)},
{cmd:r(se_overlap)}, {cmd:r(lb_overlap)}, and {cmd:r(ub_overlap)} are returned
irrespective of {opt t:able}.

{phang}
{opt l:evel(#)} specifies the confidence level, as a percentage, for the confidence
interval. The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt c:ompare} requires {cmd:by:} (or {cmd:bysort:}). After {it:H} has been estimated
(with its design-based {it:SE}) for all sub-samples specified with {help by}, a test
of the equality of the resulting {it:H}s is performed (Copas & Loeber, 1990, Eq. 16),
using each sub-sample's design-based {it:H} and {it:SE} from {cmd:loevh2_svy}
in place of {cmd:loevh2}'s large-sample {it:SE}. Results are stored in {cmd:r(Hbar)},
{cmd:r(chi2)}, {cmd:r(df)}, {cmd:r(p_chi2)}, and {cmd:r(H_SE_N)} (a k×3 matrix of
each sub-sample's {it:H}, design-based {it:SE}, and {it:N}) -- see {bf:loevh2}'s
{help loevh2##description:Description} for the formulas. As with {help loevh2},
sub-samples with a degenerate 2×2 table or a missing by-value are excluded/skipped,
with {cmd:r(lastgroup)} indicating which sub-sample the top-level
{cmd:r(loevh)}/{cmd:r(se)}/etc. belong to.

{phang}
{marker meta}{...}
{opt meta(filename, replace|append)} saves each valid sub-sample's (label,
{it:H}, {it:SE}, {it:N}) row to a persistent Stata dataset {cmd:filename_svy.dta} (note
the automatically appended {cmd:_svy} suffix -- see {bf:loevh2}'s own
{help loevh2##meta:meta()} option for the full rationale of
this suffix convention, which keeps design-based results from being mixed
with plain {help loevh2}- or {help loevh2_boot}-sourced results in the
same pooled file even when the SAME base filename is supplied to more
than one of these commands). The {it:SE} column saved here is
{cmd:loevh2_svy}'s own design-based (delta-method/{help nlcom}) standard
error. In addition to the descriptive columns documented for {bf:loevh2}'s
{help loevh2##meta:meta()} option, the saved rows also record
the active {help svyset} design used to compute them: the weight type
and expression ({cmd:svy_wtype}, {cmd:svy_wexp}), cluster and strata
variable names ({cmd:svy_cluster}, {cmd:svy_strata}), and the finite
population correction ({cmd:svy_fpc}) -- for reference only, so that
pooled results from several different survey designs (or several
different {help loevh2} / {help loevh2_boot} / {cmd:loevh2_svy} runs) can
later be told apart.

{p 8 8}Otherwise, {opt meta()} behaves exactly as documented for {help loevh2##meta:loevh2}: without
{opt c:ompare}, exactly one row is saved per call (or per by-group, if
{cmd:by:} is used without {opt c:ompare}); with {opt c:ompare}, all valid
sub-samples' rows (matching {cmd:r(H_SE_N)}) are saved together, once, after the
last by-group has been processed. Exactly one of {cmd:replace} or {cmd:append}
must be specified, and a companion {cmd:filename_svy.do} pooling/{help meta}-setup
script is (re)written on every call -- see {bf:loevh2}'s {help loevh2##meta:meta()}
option for full details on the saved columns, the companion script, and replace/append
semantics.

{p 8 8}{bf:NOTE:} Running the companion pooling script (the {cmd:.do} file written
alongside the {cmd:.dta} file, e.g. {cmd:myfile.do}) will {bf:replace the dataset}
{bf:currently in memory} with the pooled meta-analysis results (it begins with
{cmd:use "myfile.dta", clear}). If you run this script in the middle of a longer
analysis session, be sure to reload your own working dataset (and re-issue any
{help svyset}, if applicable) afterward before continuing, or enclose "{help do}
{bf:myfile.do}" between "{help preserve}" and "{cmd:restore}".


{marker examples}{...}
{title:Examples}

{pstd}Set up a complex survey design (for {bf:all} following examples!){p_end}
{phang2}{bf:. svyset} {help svyset##psu:{it:psu}} {bf:[pweight=wt], strata(region)}{p_end}

{pstd}Basic use{p_end}
{phang2}{cmd:. loevh2_svy item1 item2}{p_end}

{pstd}With a 99% confidence level{p_end}
{phang2}{cmd:. loevh2_svy item1 item2, level(99)}{p_end}

{pstd}By-group analysis, testing equality of {it:H}s across strata{p_end}
{phang2}{cmd:. bysort region: loevh2_svy item1 item2, compare}{p_end}

{pstd}Same as above and saving {it:H}, {it:SE}, and {it:N} to loev_meta.dta{p_end}
{phang2}{cmd:. bysort region: loevh2_svy item1 item2, compare meta(loev_meta, replace)}{p_end}

{pstd}pweight only, no clustering/stratification (however, see {help loevh2_svy##caution:"Caution"} above){p_end}
{phang2}{cmd:. svyset [pweight=wt]}{p_end}
{phang2}{cmd:. loevh2_svy item1 item2}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:loevh2_svy} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(loevh)}}Loevinger's {it:H} coefficient (missing if 2×2 table is degenerate
or {help nlcom} / {help svy_estimation:svy: mean} fails); with {help by}, this {it:H} and the follwing
r-returns until {bf:r(ub_overlap)} are for the sub-sample identified by {cmd:r(lastgroup)}{p_end}
{synopt:{cmd:r(se)}}standard error (design-based){p_end}
{synopt:{cmd:r(lb)}}lower bound of confidence interval{p_end}
{synopt:{cmd:r(ub)}}upper bound of confidence interval{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(overlap)}}percent overlap in cell 1/1 ({it:var1}=1 & {it:var2}=1){p_end}
{synopt:{cmd:r(se_overlap)}}design-based standard error{p_end}
{synopt:{cmd:r(lb_overlap)}}lower bound of confidence interval (logit-transformed){p_end}
{synopt:{cmd:r(ub_overlap)}}upper bound of confidence interval (logit-transformed){p_end}
{synopt:{cmd:r(Hbar)}}weighted average {it:H} across sub-samples (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(Hbar_se)}}pooled (inverse-variance-weighted) standard error of {cmd:r(Hbar)}
(only with {opt c:ompare}){p_end}
{synopt:{cmd:r(chi2)}}chi2 test statistic for equality of {it:H}s across sub-samples (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(df)}}degrees of freedom of the chi2 test (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(p_chi2)}}{it:p}-value of the chi2 test (only with {opt c:ompare}){p_end}
{synopt:{cmd:r(Hbar_N)}}total number of observations summed across all valid sub-samples
(only with {opt c:ompare}){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(H_SE_N)}}k×3 matrix of each sub-sample's {it:H}, design-based {it:SE},
and {it:N} (only with {opt c:ompare}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(var1)}}name of row variable{p_end}
{synopt:{cmd:r(var2)}}name of column variable{p_end}
{synopt:{cmd:r(se_type)}}{cmd:"svy, nlcom (delta method)"}{p_end}
{synopt:{cmd:r(group)}}by-group variable(s) (if {cmd:by:} was used){p_end}
{synopt:{cmd:r(lastgroup)}}value or category label of the sub-sample to
which {cmd:r(loevh)}, {cmd:r(se)}, {cmd:r(lb)}, {cmd:r(ub)}, and {cmd:r(N)}
belong (if {cmd:by:} was used){p_end}
{synopt:{cmd:r(error)}}{cmd:"degenerate"} if the 2×2 table has a zero cell
or margin, {cmd:"missing_byvar"} if a by-group was skipped because its
by-value is missing, {cmd:"svy_failed"} if {help svy_estimation:svy: mean} itself failed,
or {cmd:"nlcom_failed"} if {help nlcom} failed (e.g. a singular Jacobian at
or very near a boundary cell proportion){p_end}


{marker degenerate}{...}
{title:Degenerate tables and estimation failures}

{pstd}
A 2×2 table in which any cell or margin is exactly zero makes {it:H} undefined;
{cmd:loevh2_svy} detects this (before ever calling {help svy_estimation:svy: mean})
and returns missing values with {cmd:r(error) = "degenerate"}, together with a
warning, rather than aborting with a hard error.

{pstd}
Because {cmd:loevh2_svy} additionally depends on {help svy_estimation:svy: mean} and
{help nlcom} succeeding (the latter requiring, in particular, a non-singular
Jacobian of the {it:H} expression evaluated at the estimated cell proportions),
two further failure modes are possible even when the 2×2 table is not
degenerate in the row-count sense above: {cmd:r(error) = "svy_failed"}
(the {help svy_estimation:svy: mean} call itself failed) and {cmd:r(error) = "nlcom_failed"}
({help nlcom}'s delta method failed, most likely because an estimated cell
proportion is at or extremely close to a boundary value under the given
design). In both cases {cmd:loevh2_svy} displays an explanatory error
message and returns missing values rather than terminating with an
uncaught error.


{marker asymmetric}{...}
{title:Why no asymmetric-{it:CI} option is offered}

{pstd}
{cmd:loevh2}'s {help loevh2##small:{ul:s}mall} option produces an asymmetric confidence
interval using a closed-form log-odds-ratio ("relative risk") construction
specific to a 2×2 table (Copas & Loeber, 1990, Eqs. 20-23) -- it is
{it:not} a delta-method/Wald construction at all, and has no direct {help nlcom}
analog. Since {cmd:loevh2_svy} is built entirely around {help svy_estimation:svy: mean} +
{help nlcom} -- a delta-method (Wald-type) machinery from the ground up --
there is no straightforward way to reproduce Eqs. 20-23 within this framework: that
formula's derivation does not go through a design-based variance-covariance
matrix of estimated proportions, and simply re-implementing it with
{help svy}-adjusted cell proportions would not, by itself, correctly propagate
the survey design's clustering/stratification into the resulting {it:CI} (Eqs. 20-23
assume a simple random-sample / fixed-margins setting, not a general design-based
covariance structure). So no direct analog of {help loevh2##small:{ul:s}mall} is available
under {cmd:loevh2_svy}.

{pstd}
A logit- or log-transformed Wald {it:CI} for {it:H} (the natural {help nlcom}-based candidate,
exactly analogous to what IS implemented for r(overlap)) was considered and
deliberately not implemented: unlike overlap, {it:H} is not confined to [0,1] and
treats {it:H}=0 as a substantively meaningful interior point, not a boundary; a
logit/log transform is undefined or numerically unstable exactly in that important
region, and an earlier Monte Carlo simulation confirmed that this transform badly
under-covers for small |{it:H}| (see {cmd:loevh2}'s
{help loevh2##trust:"When to trust the results"}).


{marker seealso}{...}
{title:See also}

{phang}
{help loevh2} calculates (asymptotic) standard errors for Loevinger's {it:H} for large and small
samples ({cmd:pweight} not allowed)

{phang}
{help loevh2_boot} provides bootstrap confidence intervals for Loevinger's {it:H},
which may be more robust when sample sizes are small or asymptotic assumptions
are not met -- see also {cmd:loevh2}'s {help loevh2##trust:"When to trust the results"}
section for when this actually holds.{p_end}

{phang}
{help loevh} (if installed) by Jean-Benoit Hardouin provides Loevinger's {it:H} coefficient for multiple
items (see {stata ssc describe loevh}).


{marker author}{...}
{title:Author}

{pstd}Dirk Enzmann (University of Hamburg) with AI assistance (Claude/Anthropic){p_end}


{marker acknowledgements}{...}
{title:Acknowledgments}

{phang}
Daniel Klein's suggestion to use {help nlcom} to calculate {it:H} with population
weighting was the key idea behind writing {cmd:loevh2_svy}.{p_end}


{marker references}{...}
{title:References}

{phang}
Copas, J. B., & Loeber, R. (1990). Relative improvement over chance (RIOC) for 2×2
tables. {it:British Journal of Mathematical and Statistical Psychology}, {it:43}(2),
293–307. {browse "https://doi.org/10.1111/j.2044-8317.1990.tb00942.x":https://doi.org/10.1111/j.2044-8317.1990.tb00942.x}

{phang}
Loevinger, J. A. (1947). A systematic approach to the construction and evaluation of
tests of ability. {it:Psychological Monographs}, {it:61}(4), i–49.
{browse "https://doi.org/10.1037/h0093565":https://doi.org/10.1037/h0093565}
{phang}
