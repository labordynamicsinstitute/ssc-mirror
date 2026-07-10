{smcl}
{vieweralsosee "trop" "help trop"}{...}
{vieweralsosee "trop estat" "help trop_estat"}{...}
{vieweralsosee "trop predict" "help trop_predict"}{...}
{viewerjumpto "Syntax" "trop_estat##syntax"}{...}
{viewerjumpto "Description" "trop_estat##description"}{...}
{viewerjumpto "Subcommands" "trop_estat##subcommands"}{...}
{viewerjumpto "Examples" "trop_estat##examples"}{...}
{viewerjumpto "Stored results" "trop_estat##results"}{...}
{viewerjumpto "Methods and formulas" "trop_estat##methods"}{...}
{viewerjumpto "References" "trop_estat##references"}{...}
{viewerjumpto "Author" "trop_estat##author"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:estat} (after {cmd:trop}) {hline 2}}Postestimation statistics for trop{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:estat} {it:subcommand} [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt sum:marize}}sample and treatment structure summary{p_end}
{synopt:{opt weight:s}}weight diagnostics{p_end}
{synopt:{opt loocv}}LOOCV hyperparameter selection diagnostics{p_end}
{synopt:{opt factors}}factor matrix (L) SVD analysis{p_end}
{synopt:{opt boot:strap}}bootstrap distribution diagnostics{p_end}
{synopt:{opt sens:itivity}}hyperparameter sensitivity analysis{p_end}
{synopt:{opt vce}}variance-covariance matrix{p_end}
{synopt:{opt triple:rob}}triple-robustness bias decomposition (Theorem 5.1){p_end}
{synopt:{opt dist:ance}}unit distance distribution diagnostics{p_end}
{synopt:{opt mht}}multiple hypothesis testing correction{p_end}
{synopt:{opt event:study}}event-study analysis (twostep only){p_end}
{synopt:{opt pre:trend}}pre-trend test (twostep only){p_end}
{synopt:{opt table}}export results as formatted table (LaTeX/Markdown/CSV){p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Abbreviations are shown by underlining.


{marker description}{...}
{title:Description}

{pstd}
{cmd:estat} displays postestimation diagnostics after {helpb trop}.  Thirteen
subcommands are provided for inspecting the estimation sample, weight
distributions, hyperparameter selection, factor structure, bootstrap
inference, sensitivity of the LOOCV objective, the variance-covariance
matrix, triple-robustness bias decomposition, unit distance distribution,
multiple hypothesis testing, event-study analysis, pre-trend testing,
and publication-quality table export.

{pstd}
All subcommands require that {cmd:trop} has been executed previously.  If no
{cmd:trop} estimates are found in {cmd:e()}, error code 301 is returned.


{marker subcommands}{...}
{title:Subcommands}

{dlgtab:estat summarize}

{p 8 16 2}
{cmd:estat summarize} [{cmd:,} {opt detailed}]

{pstd}
Displays a summary of the estimation sample structure and treatment
distribution, including the number of units (N), periods (T), total
observations, treated and control observation counts, treatment adoption
pattern, outcome variable descriptive statistics, and estimation method.

{pstd}
Options:

{phang}
{opt detailed} displays a guide for tabulating the unit-by-period treatment
distribution in the original dataset.

{dlgtab:estat weights}

{p 8 16 2}
{cmd:estat weights} [{cmd:,} {opt heatmap} {opt detailed}]

{pstd}
Displays weight diagnostics.  Output differs by estimation method:

{phang}
{bf:Twostep method:} A note is displayed indicating that weights vary by
treated observation.  Summary statistics (mean, standard deviation, minimum,
maximum) are reported for the time weights (theta, T x 1) and unit weights
(omega, N x 1) associated with the first treated observation.  This is the
paper's main Algorithm 2 path and permits heterogeneous treatment effects.

{phang}
{bf:Joint method:} Summary statistics are reported for the global time
weights (delta_time, T x 1) and unit weights (delta_unit, N x 1).  This is
the shared-weight Remark 6.1 extension, intended for homogeneous effects in
simultaneous-adoption settings.

{pstd}
Options:

{phang}
{opt heatmap} generates a heatmap of the weight matrix.  If {cmd:e(W_mat)} is
available it is used directly; otherwise an outer-product approximation is
constructed from the weight vectors.  Requires the user-written command
{cmd:heatplot} (install via {cmd:ssc install heatplot}).

{phang}
{opt detailed} displays the 10th, 25th, 50th, 75th, and 90th percentiles of
the weight vectors.

{dlgtab:estat loocv}

{p 8 16 2}
{cmd:estat loocv} [{cmd:,} {opt stab:ility} {opt tab:le2}]

{pstd}
Displays LOOCV hyperparameter selection diagnostics, including:

{phang2}- Selected hyperparameters (lambda_time, lambda_unit, lambda_nn){p_end}
{phang2}- LOOCV objective value Q(lambda_hat){p_end}
{phang2}- Valid fits count and percentage{p_end}
{phang2}- Grid style used{p_end}
{phang2}- Method-specific search mode in effect for the preceding {cmd:trop} call{p_end}
{phang2}- First failed observation coordinates (if any){p_end}
{phang2}- Warning if failure rate exceeds 10%{p_end}

{pstd}
With the {opt stability} option, the following additional diagnostics are
appended:

{phang2}- LOOCV search strategy in effect ({cmd:cycling} or {cmd:exhaustive}
for the method used by the preceding {cmd:trop} call){p_end}
{phang2}- Size and [min, max] range of each lambda grid{p_end}
{phang2}- Boundary-hit flags when the selected lambda coincides with the
lowest or highest finite grid point, suggesting the grid should be
widened.  The {cmd:.} (Stata missing = +infinity) corner of
{bf:lambda_nn} is recognised as a legitimate DID/TWFE solution and is
never flagged.{p_end}

{pstd}
With the {opt table2} option, the command appends a per-dataset coverage
report for the seven benchmark applications of Table 2 in Athey et al.
(2025): CPS log-wage, CPS unemployment rate, PWT log-GDP, West Germany,
Basque, California Smoking, and Mariel Boatlift.  For every benchmark the
report checks whether the optimal
(lambda_unit, lambda_time, lambda_nn) triplet reported in the paper is
present in the lambda grids actually used by the preceding {cmd:trop} call.
When a value is missing, the report suggests switching to
{cmd:grid_style(extended)} or adding the missing value to the corresponding
{opt lambda_*_grid()} option.  This diagnostic requires that the previous
{cmd:trop} call performed LOOCV (i.e. no {opt fixedlambda()}).

{dlgtab:estat factors}

{p 8 16 2}
{cmd:estat factors}

{pstd}
Displays an analysis of the low-rank factor matrix L via singular value
decomposition (SVD), including:

{phang2}- Matrix dimensions (T x N){p_end}
{phang2}- Effective rank (singular values above tolerance){p_end}
{phang2}- Top singular values with variance explained{p_end}
{phang2}- Matrix norms (Frobenius, Nuclear){p_end}

{dlgtab:estat bootstrap}

{p 8 16 2}
{cmd:estat bootstrap} [{cmd:,} {opt graph}]

{pstd}
Displays bootstrap distribution diagnostics.  This subcommand requires that
the {opt bootstrap()} option was specified in the original {cmd:trop} command.

{pstd}
The reported dispersion summaries are descriptive summaries of the stored
bootstrap ATT draws.  The variance denominator used for the official
reported {cmd:e(se)} remains the one selected at estimation time through
{opt bsvariance(sample|paper)}.

{pstd}
Output includes:

{phang2}- Number of bootstrap samples and valid samples{p_end}
{phang2}- ATT distribution statistics (mean, standard deviation, median, IQR){p_end}
{phang2}- Percentiles (2.5%, 5%, 25%, 50%, 75%, 95%, 97.5%){p_end}
{phang2}- Normality test (Jarque-Bera statistic and p-value){p_end}

{pstd}
Options:

{phang}
{opt graph} plots a histogram of the bootstrap distribution with a normal
density overlay, the point estimate, and confidence interval reference lines.

{dlgtab:estat sensitivity}

{p 8 16 2}
{cmd:estat sensitivity} [{cmd:,} {opt graph} {opt table(#)}]

{pstd}
Displays hyperparameter sensitivity analysis based on the LOOCV grid search
results.  Reports the search range for each regularization parameter, the
selected optimum, the LOOCV score, and boundary diagnostics.

{pstd}
When full grid evaluation data are available (more than half of the Cartesian
product has valid CV scores), a ranked table of top grid points by CV loss is
displayed together with sensitivity metrics (coefficient of variation, loss
range, relative range).

{pstd}
Options:

{phang}
{opt graph} plots the CV loss curve.  Available only when full grid evaluation
data exist and a single regularization parameter varies.

{phang}
{opt table(#)} specifies the number of top grid points to display; default is
{cmd:table(10)}.

{dlgtab:estat vce}

{p 8 16 2}
{cmd:estat vce} [{cmd:,} {opt correlation}]

{pstd}
Displays the variance-covariance matrix of the estimates.  Because the TROP
estimator produces a scalar ATT, the matrix {cmd:e(V)} is 1 x 1.  The
standard error, variance estimation method, and bootstrap replication count
(if applicable) are also reported.  When bootstrap inference was used, the
display also reports whether the SE uses the default sample denominator
{cmd:1/(B-1)} or the paper denominator {cmd:1/B}.

{pstd}
Options:

{phang}
{opt correlation} is accepted for interface compatibility but has no effect
on the display because the TROP variance-covariance matrix is scalar (1 x 1).

{dlgtab:estat triplerob}

{p 8 16 2}
{cmd:estat triplerob} [{cmd:,} {opt rank(#)} {opt topk(#)}]

{pstd}
Reports a diagnostic decomposition of the paper Theorem 5.1 bias bound

{p 8 8 2}
|E[tau_hat - tau | L]| <= ||Delta^u(omega, Gamma)||_2 * ||Delta^t(theta, Lambda)||_2 * ||B||_*

{pstd}
as three factors, computed from {cmd:e(factor_matrix)}, the method-specific
weight vectors, and the rank-k singular-value decomposition of the estimated
L matrix.

{pstd}
{bf:Interpretation.}  Gamma (N x k) and Lambda (T x k) are the unit
loadings and time factors of the rank-k truncation of L.  The first two
imbalance terms measure how much the fitted weights fail to reproduce the
target unit's loading / target period's factor on average over the treated
cells.  The third term measures the nuclear mass discarded by the rank-k
truncation.  The product is a diagnostic proxy for the Theorem 5.1 upper
bound; a small value relative to the bootstrap standard error suggests the
triple-robustness guarantee is well satisfied.

{pstd}
For {opt method(joint)} the global weights {cmd:e(delta_time)} and
{cmd:e(delta_unit)} are used, and the imbalance terms are averaged over all
treated cells.  For {opt method(twostep)} only {cmd:e(theta)} and
{cmd:e(omega)} are stored, which describe the weights at the first treated
cell; the reported decomposition is therefore a conservative proxy for
that cell.

{pstd}
Options:

{phang}
{opt rank(#)} overrides the truncation rank k used for the SVD decomposition
of L.  Default is {cmd:ceil(e(effective_rank))}, capped at {cmd:min(T, N)}.
Higher rank retains more singular mass (smaller residual term) but may
inflate the two imbalance terms if additional components are poorly
balanced.

{phang}
{opt topk(#)} controls how many leading singular values are tabulated in
the header (default {cmd:3}).

{pstd}
Stored results (in {cmd:r()}):

{synoptset 24 tabbed}{...}
{synopt:{cmd:r(delta_unit)}}||Delta^u||_2 averaged over treated cells{p_end}
{synopt:{cmd:r(delta_time)}}||Delta^t||_2 averaged over treated cells{p_end}
{synopt:{cmd:r(residual)}}nuclear mass discarded by rank-k truncation{p_end}
{synopt:{cmd:r(bias_bound)}}product of the three factors{p_end}
{synopt:{cmd:r(rank)}}truncation rank used{p_end}
{synopt:{cmd:r(method)}}{cmd:twostep} or {cmd:joint}{p_end}
{synoptline}


{dlgtab:estat distance}

{p 8 16 2}
{cmd:estat distance} [{cmd:,} {opt graph} {opt sav:ing(filename)} {opt bins(#)}]

{pstd}
Displays unit distance distribution diagnostics.  The pairwise distances
between panel units are computed as the root-mean-squared difference in
outcomes across shared control periods (Paper Eq. 3).

{pstd}
Output includes the distance distribution summary (mean, standard deviation,
min, max, percentiles) and optionally publication-quality diagnostic plots.

{pstd}
Options:

{phang}
{opt graph} displays publication-quality weight diagnostic plots including
a distance distribution histogram, unit weights vs distance scatter, and
time weight decay curve (when lambda parameters are available).

{phang}
{opt saving(filename)} saves the combined diagnostic graph to {it:filename}.
Requires the {opt graph} option.

{phang}
{opt bins(#)} specifies the number of histogram bins; default is
{cmd:bins(30)}.

{pstd}
Stored results (in {cmd:r()}):

{synoptset 24 tabbed}{...}
{synopt:{cmd:r(mean_dist)}}mean pairwise distance{p_end}
{synopt:{cmd:r(sd_dist)}}standard deviation of distances{p_end}
{synopt:{cmd:r(min_dist)}}minimum distance{p_end}
{synopt:{cmd:r(max_dist)}}maximum distance{p_end}
{synopt:{cmd:r(N_pairs)}}number of pairwise distances{p_end}
{synoptline}


{dlgtab:estat mht}

{p 8 16 2}
{cmd:estat mht} [{cmd:,} {opt method(string)} {opt source(string)} {opt alpha(#)}]

{pstd}
Performs multiple hypothesis testing correction on treatment effects
obtained from {cmd:trop}.

{pstd}
Three correction methods are available:

{phang2}- {bf:bonferroni}: Bonferroni correction (FWER): p_adj_i = min(K * p_i, 1){p_end}
{phang2}- {bf:holm}: Holm step-down (FWER): sequential correction{p_end}
{phang2}- {bf:bh}: Benjamini-Hochberg (FDR): sequential correction (default){p_end}

{pstd}
Options:

{phang}
{opt method(string)} specifies the correction method; one of {cmd:bonferroni},
{cmd:holm}, or {cmd:bh} (default).

{phang}
{opt source(string)} specifies the source of effects; one of {cmd:cells}
(individual cell-level effects from {cmd:e(tau_matrix)}, requires
{cmd:method(twostep)}) or {cmd:eventstudy} (event-study horizon effects
from a prior {cmd:estat eventstudy} call).  Default is {cmd:cells}.

{phang}
{opt alpha(#)} specifies the significance level; default is {cmd:0.05}.

{pstd}
Stored results (in {cmd:r()}):

{synoptset 28 tabbed}{...}
{synopt:{cmd:r(method)}}correction method used{p_end}
{synopt:{cmd:r(alpha)}}significance level{p_end}
{synopt:{cmd:r(K)}}number of hypotheses tested{p_end}
{synopt:{cmd:r(n_reject)}}number of rejections after correction{p_end}
{synopt:{cmd:r(table)}}matrix of corrected p-values and decisions{p_end}
{synoptline}


{dlgtab:estat eventstudy}

{p 8 16 2}
{cmd:estat eventstudy} [{cmd:,} {opt w:indow(numlist)} {opt ref:erence(#)}
{opt placebo} {opt placebo_periods(#)} {opt graph} {opt no:graph}
{opt level(#)} {opt title(string)} {opt saving(string)}
{opt connect} {opt cicolor(string)} {opt mcolor(string)}
{opt msymbol(string)} {opt msize(string)}]

{pstd}
Aggregates individual treatment effects tau_{i,t} by relative event time
(horizon h = t - g_i) and optionally performs pre-trend testing.  This
subcommand requires {cmd:method(twostep)} because only that method produces
cell-level treatment effects in {cmd:e(tau_matrix)}.

{pstd}
Options:

{phang}
{opt window(numlist)} specifies the event-time window [min, max] to
display; default spans the full available range.

{phang}
{opt reference(#)} specifies the reference period for normalization;
default is {cmd:-1} (the last pre-treatment period).

{phang}
{opt placebo} performs a pre-trend (placebo) test using the pre-treatment
horizons.

{phang}
{opt placebo_periods(#)} specifies the number of pre-treatment periods
used for the placebo test; default is {cmd:3}.

{phang}
{opt graph} displays an event-study plot with point estimates and
confidence intervals.

{phang}
{opt nograph} suppresses the event-study plot.

{phang}
{opt level(#)} specifies the confidence level; default is {cmd:level(95)}.

{phang}
{opt title(string)} specifies a custom title for the graph.

{phang}
{opt saving(string)} saves the graph to a file.

{phang}
{opt connect} connects point estimates with a line across horizons.

{phang}
{opt cicolor(string)} specifies the colour for confidence interval caps;
default is {cmd:"24 105 175"} (publication blue).

{phang}
{opt mcolor(string)} specifies the marker and line colour for point
estimates; default is {cmd:"24 105 175"}.

{phang}
{opt msymbol(string)} specifies the marker symbol; default is {cmd:O}
(circle).  See {help symbolstyle}.

{phang}
{opt msize(string)} specifies the marker size; default is
{cmd:medsmall}.  See {help markersizestyle}.

{pstd}
Stored results (in {cmd:r()}):

{synoptset 28 tabbed}{...}
{synopt:{cmd:r(table)}}matrix of event-study estimates (horizon, ATT, SE, CI){p_end}
{synopt:{cmd:r(n_horizons)}}number of event-time horizons{p_end}
{synopt:{cmd:r(pretrend_F)}}pre-trend F-statistic (if {opt placebo} specified){p_end}
{synopt:{cmd:r(pretrend_p)}}pre-trend p-value (if {opt placebo} specified){p_end}
{synoptline}


{dlgtab:estat pretrend}

{p 8 16 2}
{cmd:estat pretrend} [{cmd:,} {opt p:eriods(#)} {opt l:evel(#)} {opt r:obust}]

{pstd}
Tests the null hypothesis that all pre-treatment effects are jointly zero:

{p 8 8 2}
H0: tau(-K) = tau(-K+1) = ... = tau(-1) = 0

{pstd}
This subcommand requires {cmd:method(twostep)} because only that method
produces cell-level treatment effects in {cmd:e(tau_matrix)}.  The test
uses a simplified Wald statistic with a chi-squared reference distribution.

{pstd}
Options:

{phang}
{opt periods(#)} specifies the number of pre-treatment periods to include
in the test.  Default uses all available pre-treatment periods.

{phang}
{opt level(#)} specifies the significance level for the pass/fail decision;
default is {cmd:95}.

{phang}
{opt robust} uses the bootstrap covariance matrix for the pre-treatment
period effects (if available from a prior {cmd:estat eventstudy} call)
instead of the default diagonal covariance assumption.

{pstd}
Stored results (in {cmd:r()}):

{synoptset 28 tabbed}{...}
{synopt:{cmd:r(chi2)}}Wald chi-squared test statistic{p_end}
{synopt:{cmd:r(df)}}degrees of freedom (number of pre-periods tested){p_end}
{synopt:{cmd:r(p)}}p-value{p_end}
{synopt:{cmd:r(pretrend_pass)}}1 if cannot reject H0 at the given level, 0 otherwise{p_end}
{synopt:{cmd:r(n_preperiods)}}number of pre-treatment periods used{p_end}
{synoptline}



{dlgtab:estat table}

{p 8 16 2}
{cmd:estat table} [{cmd:,} {opt f:ormat(string)} {opt sav:ing(filename)} {opt ti:tle(string)}
{opt no:tes(string)} {opt sta:rs} {opt app:end} {opt replace} {opt dec:imals(#)}]

{pstd}
Produces a publication-quality results table from the {cmd:e()} values
stored after a {cmd:trop} estimation command.  Supports four output formats
and optional significance stars.

{pstd}
Options:

{phang}
{opt format(string)} specifies the output format; one of {cmd:display} (Stata
console table, default), {cmd:latex} (LaTeX tabular environment in AER/QJE
style), {cmd:markdown} (GitHub-flavored Markdown table), or {cmd:csv}
(comma-separated values).

{phang}
{opt saving(filename)} writes the formatted table to {it:filename}.  If the
file already exists, {opt replace} or {opt append} must be specified.

{phang}
{opt title(string)} specifies a custom table title; default is
{cmd:"TROP Estimation Results"}.

{phang}
{opt notes(string)} appends a footnote below the table (LaTeX, Markdown,
and CSV formats only).

{phang}
{opt stars} appends significance stars to the ATT estimate: {cmd:***}
p<0.01, {cmd:**} p<0.05, {cmd:*} p<0.1.

{phang}
{opt append} appends output to an existing file specified by {opt saving()}.

{phang}
{opt replace} overwrites an existing file specified by {opt saving()}.

{phang}
{opt decimals(#)} specifies the number of decimal places for numeric values;
default is {cmd:4}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 1000}{p_end}
{phang2}{cmd:. gen id = ceil(_n/10)}{p_end}
{phang2}{cmd:. bysort id: gen t = _n}{p_end}
{phang2}{cmd:. gen y = rnormal() + 0.5*(id>80)*(t>7)}{p_end}
{phang2}{cmd:. gen d = (id > 80 & t > 7)}{p_end}

{pstd}Run trop with bootstrap{p_end}
{phang2}{cmd:. trop y d, panelvar(id) timevar(t) seed(42) bootstrap(200)}{p_end}

{pstd}Sample summary{p_end}
{phang2}{cmd:. estat summarize}{p_end}

{pstd}LOOCV diagnostics{p_end}
{phang2}{cmd:. estat loocv}{p_end}

{pstd}Weight diagnostics{p_end}
{phang2}{cmd:. estat weights}{p_end}

{pstd}Weight diagnostics with percentiles{p_end}
{phang2}{cmd:. estat weights, detailed}{p_end}

{pstd}Factor matrix analysis{p_end}
{phang2}{cmd:. estat factors}{p_end}

{pstd}Bootstrap distribution{p_end}
{phang2}{cmd:. estat bootstrap}{p_end}

{pstd}Bootstrap distribution with histogram{p_end}
{phang2}{cmd:. estat bootstrap, graph}{p_end}

{pstd}Hyperparameter sensitivity{p_end}
{phang2}{cmd:. estat sensitivity}{p_end}

{pstd}Variance-covariance matrix{p_end}
{phang2}{cmd:. estat vce}{p_end}

{pstd}Triple-robustness bias decomposition (Theorem 5.1){p_end}
{phang2}{cmd:. estat triplerob}{p_end}

{pstd}Same with a rank-2 truncation{p_end}
{phang2}{cmd:. estat triplerob, rank(2)}{p_end}

{pstd}Unit distance distribution{p_end}
{phang2}{cmd:. estat distance}{p_end}

{pstd}Weight diagnostic plots{p_end}
{phang2}{cmd:. estat distance, graph}{p_end}

{pstd}Save diagnostic panel to file{p_end}
{phang2}{cmd:. estat distance, graph saving(weight_diag.png)}{p_end}

{pstd}Multiple hypothesis testing (Benjamini-Hochberg){p_end}
{phang2}{cmd:. estat mht}{p_end}

{pstd}Bonferroni correction at 1% level{p_end}
{phang2}{cmd:. estat mht, method(bonferroni) alpha(0.01)}{p_end}

{pstd}Event-study analysis (requires twostep){p_end}
{phang2}{cmd:. estat eventstudy}{p_end}

{pstd}Event study with graph and placebo test{p_end}
{phang2}{cmd:. estat eventstudy, graph placebo}{p_end}

{pstd}Event study with custom graph options{p_end}
{phang2}{cmd:. estat eventstudy, graph connect mcolor("0 100 0") msymbol(D)}{p_end}

{pstd}Pre-trend test{p_end}
{phang2}{cmd:. estat pretrend}{p_end}

{pstd}Pre-trend test with 5 pre-periods at 99%% level{p_end}
{phang2}{cmd:. estat pretrend, periods(5) level(99)}{p_end}

{pstd}Export results as formatted table{p_end}
{phang2}{cmd:. estat table}{p_end}

{pstd}Export LaTeX table with significance stars{p_end}
{phang2}{cmd:. estat table, format(latex) stars saving(results.tex)}{p_end}

{pstd}Export Markdown table{p_end}
{phang2}{cmd:. estat table, format(markdown) saving(results.md)}{p_end}

{pstd}Export CSV with custom title{p_end}
{phang2}{cmd:. estat table, format(csv) title("Model 1") saving(results.csv)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
The {cmd:estat} subcommands do not modify the estimation results in {cmd:e()}.
All displayed statistics are computed from the {cmd:e()} results stored by
{helpb trop}.  The exception is {cmd:estat triplerob}, which also stores the
diagnostic scalars documented above in {cmd:r()}.  See
{helpb trop##results:trop stored results} for the complete list of scalars,
macros, and matrices available after estimation.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:estat weights}

{pstd}
For the twostep method, time weights theta_s and unit weights omega_j are
computed as exponential-decay functions of distance (Eq. 3 of Athey et al.,
2025):

{p 8 8 2}
theta_s = exp(-lambda_time * |t - s|)

{p 8 8 2}
omega_j = exp(-lambda_unit * dist(j, i))

{pstd}
where dist(j, i) is the root-mean-squared difference in outcomes between
units j and i over shared control periods.  For the joint method, the
analogous global weights are delta_time (T x 1) and delta_unit (N x 1).

{pstd}
{bf:estat loocv}

{pstd}
The LOOCV objective Q(lambda) is defined as (Eq. 5):

{p 8 8 2}
Q(lambda) = sum_{i,t} (1 - W_{it}) * (tau_hat_{it}(lambda))^2

{pstd}
where tau_hat_{it}(lambda) is the estimated pseudo-treatment effect for
control observation (i, t).  Hyperparameters are selected via coordinate
descent (cycling) over the grid of (lambda_time, lambda_unit, lambda_nn).

{pstd}
{bf:estat factors}

{pstd}
The effective rank of the factor matrix L is computed via SVD as
sum(s) / s[1], where s is the vector of singular values.  This continuous
measure indicates the degree to which the low-rank component concentrates on
a small number of factors.

{pstd}
{bf:estat bootstrap}

{pstd}
The cluster bootstrap resamples N_0 control units and N_1 treated units with
replacement, re-estimating the TROP estimator for each replicate.  The
reported dispersion summaries are descriptive summaries of the stored
bootstrap draws.  The official {cmd:e(se)} uses the denominator selected at
estimation time via {cmd:bsvariance(sample|paper)}; the paper denominator is:

{p 8 8 2}
V_hat = (1/B) * sum_{b=1}^{B} (tau_hat^(b) - tau_bar)^2

{pstd}
while the default {cmd:bsvariance(sample)} replaces {cmd:1/B} with
{cmd:1/(B-1)}.

{pstd}
Normality of the bootstrap distribution is assessed via the Jarque-Bera
statistic: JB = (B/6) * [S^2 + (1/4)(K - 3)^2], where S is skewness and K
is kurtosis.  Under the null of normality, JB follows a chi-squared
distribution with 2 degrees of freedom.

{pstd}
{bf:estat sensitivity}

{pstd}
Sensitivity metrics include the coefficient of variation of CV loss across
grid points, the loss range, and the relative range.  Boundary diagnostics
check whether the selected optimum lies at the edge of the search grid.

{pstd}
{bf:estat triplerob}

{pstd}
Starting from the rank-k SVD L = U * diag(s) * V' where U (T x r),
V (N x r), and s is the vector of singular values in non-increasing
order, the paper Theorem 5.1 bias bound is

{p 8 8 2}
|E[tau_hat - tau | L]| <= ||Delta^u(omega, Gamma)||_2 * ||Delta^t(theta, Lambda)||_2 * ||B||_*

{pstd}
with

{p 8 8 2}
Gamma_{i,.} = V[i, 1..k],    Lambda_{t,.} = U[t, 1..k]

{p 8 8 2}
Delta^u(omega, Gamma) = sum_j omega_j * Gamma_{j,.} - Gamma_{i*,.}

{p 8 8 2}
Delta^t(theta, Lambda) = sum_s theta_s * Lambda_{s,.} - Lambda_{t*,.}

{p 8 8 2}
||B||_* ~= sum_{h > k} s_h   (nuclear mass discarded by truncation)

{pstd}
where (i*, t*) indexes a treated cell.  The ||.||_2 terms are L2 norms
over the k-component loadings.  For {opt method(joint)} the reported
||Delta^u||_2 and ||Delta^t||_2 are arithmetic means over all treated
cells with the global weights {cmd:e(delta_unit)}, {cmd:e(delta_time)}.
For {opt method(twostep)} only the first-treated-cell weights
{cmd:e(omega)}, {cmd:e(theta)} are available in {cmd:e()}, and the
decomposition reports those cell-specific quantities.


{marker references}{...}
{title:References}

{phang}
Athey, S., G. W. Imbens, Z. Qu, and D. Viviano. 2025.
Triply robust panel estimators.
{it:arXiv preprint arXiv:2508.21536}.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Xuanyu Cai{break}
City University of Macau{break}
xuanyuCAI@outlook.com

{pstd}
Wenli Xu{break}
City University of Macau{break}
wlxu@cityu.edu.mo


{title:Also see}

{psee}
Online: {helpb trop}, {helpb trop_estat}, {helpb trop_predict}
{p_end}
