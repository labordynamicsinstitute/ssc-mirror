{smcl}
{* *! version 2.0.2  8may2026}{...}
{viewerjumpto "Syntax" "pmean##syntax"}{...}
{viewerjumpto "Description" "pmean##description"}{...}
{viewerjumpto "Installation" "pmean##installation"}{...}
{viewerjumpto "Options" "pmean##options"}{...}
{viewerjumpto "Generated variables" "pmean##generated"}{...}
{viewerjumpto "Formulas" "pmean##formulas"}{...}
{viewerjumpto "Edge cases" "pmean##edge"}{...}
{viewerjumpto "Examples" "pmean##examples"}{...}
{viewerjumpto "Stored results" "pmean##results"}{...}
{viewerjumpto "References" "pmean##references"}{...}
{viewerjumpto "Authors" "pmean##author"}{...}
{viewerjumpto "Comparison with related commands" "pmean##comparison"}{...}
{viewerjumpto "Also see" "pmean##alsosee"}{...}

{title:Title}

{phang}
{bf:pmean} {hline 2} Panel-data means and exact within-between decomposition for two- and three-dimensional panel data{p_end}

{marker syntax}{...}
{title:Syntax}

{pstd}
Two-dimensional panel data:{p_end}

{p 8 17 2}
{cmd:pmean} {it:varlist} [{it:if}] [{it:in}],
{cmd:id(}{it:varname}{cmd:)} {cmd:time(}{it:varname}{cmd:)}
[{cmd:genprefix(}{it:name}{cmd:)} {cmd:replace} {cmd:listwise} {cmd:table} {cmd:save(}{it:filename}{cmd:)}]
{p_end}

{pstd}
Three-dimensional panel data:{p_end}

{p 8 17 2}
{cmd:pmean} {it:varlist} [{it:if}] [{it:in}],
{cmd:id(}{it:varname}{cmd:)} {cmd:time(}{it:varname}{cmd:)} {cmd:dim3(}{it:varname}{cmd:)}
[{cmd:genprefix(}{it:name}{cmd:)} {cmd:replace} {cmd:listwise} {cmd:table} {cmd:save(}{it:filename}{cmd:)} {cmd:full}]
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:pmean} computes panel-data means and the exact within-between decomposition for
two-dimensional ({it:id} x {it:time}) and three-dimensional ({it:id} x {it:time} x {it:dim3})
panel data. For each input variable, the command generates marginal means
(overall, by id, by time, and optionally by a third dimension), the implied
within and between components, and two- and three-way fixed-effect residuals.
With {cmd:dim3()} and {cmd:full}, the command additionally generates the full
ANOVA-style pairwise interaction components and the three-way residual.{p_end}

{pstd}
The additive identities (2D, 3D main effects, and full 3-way ANOVA) hold
{it:exactly} at every observation in any panel, balanced or unbalanced. The
third dimension can represent a sector, region, product group, industry,
cohort, or any other grouping observed alongside the panel id and time.{p_end}

{pstd}
The estimation sample is defined by {it:if}, {it:in}, and observations with
nonmissing values of {cmd:id()}, {cmd:time()}, and, when supplied, {cmd:dim3()}.
Missing values of the analysis variables are handled variable by variable
unless the {cmd:listwise} option is specified.{p_end}

{marker installation}{...}
{title:Installation}

{pstd}
To install:{p_end}

{phang2}{cmd:. ssc install pmean}{p_end}

{pstd}
To update an existing installation:{p_end}

{phang2}{cmd:. ssc install pmean, replace}{p_end}

{marker options}{...}
{title:Options}

{phang}
{cmd:id(}{it:varname}{cmd:)} specifies the panel identifier. Required.{p_end}

{phang}
{cmd:time(}{it:varname}{cmd:)} specifies the time identifier. Required.{p_end}

{phang}
{cmd:dim3(}{it:varname}{cmd:)} specifies the third panel dimension. When this
option is omitted, {cmd:pmean} runs in two-dimensional mode. When {cmd:dim3()}
is constant within each panel id (i.e., the third dimension is nested within
the panel), {cmd:pmean} prints an informational note and proceeds; the
id-by-dim3 interaction component is collinear with the between-dim3 component
in that case but the additive identity still holds.{p_end}

{phang}
{cmd:genprefix(}{it:name}{cmd:)} specifies the prefix used for generated
variables. The default is {cmd:pm_}. Generated variable names are checked
before any variables are created. If a name exceeds 32 characters, use a
shorter prefix or rename the source variable.{p_end}

{phang}
{cmd:replace} allows {cmd:pmean} to overwrite previously generated variables
with the same names. If {cmd:save()} is specified, {cmd:replace} also permits
overwriting an existing CSV file.{p_end}

{phang}
{cmd:listwise} restricts the estimation sample to observations that are
jointly non-missing on every variable in {it:varlist}. By default, missingness
is handled variable by variable.{p_end}

{phang}
{cmd:table} displays a compact summary table for each variable. The table
reports N, mean, standard deviation, minimum, maximum, number of panel units,
number of time periods, and, in three-dimensional mode, number of
third-dimension groups.{p_end}

{phang}
{cmd:save(}{it:filename}{cmd:)} saves the summary table as a CSV file. This
option requires {cmd:table}. If the file already exists, specify {cmd:replace}.
{p_end}

{phang}
{cmd:full} adds pairwise means, pairwise interaction components, and the full
three-way residual component. This option is available only with {cmd:dim3()}.
{cmd:pairwise} is accepted as a synonym for {cmd:full}.{p_end}

{marker generated}{...}
{title:Generated variables}

{pstd}
For a variable {it:x}, the default two-dimensional generated variables
are:{p_end}

{phang2}{cmd:pm_overall_}{it:x} {hline 2} Grand mean over the estimation sample{p_end}
{phang2}{cmd:pm_idmean_}{it:x} {hline 2} Unit mean (time-averaged within each id){p_end}
{phang2}{cmd:pm_timemean_}{it:x} {hline 2} Period mean (averaged across units within each time){p_end}
{phang2}{cmd:pm_within_id_}{it:x} {hline 2} One-way within deviation: x minus its id mean{p_end}
{phang2}{cmd:pm_between_id_}{it:x} {hline 2} Between-id component: id mean minus grand mean{p_end}
{phang2}{cmd:pm_between_time_}{it:x} {hline 2} Between-time component: period mean minus grand mean{p_end}
{phang2}{cmd:pm_twfe_}{it:x} {hline 2} Two-way demeaned variable (residual after id and time means){p_end}

{pstd}
With {cmd:dim3()}, the command additionally generates:{p_end}

{phang2}{cmd:pm_dim3mean_}{it:x} {hline 2} Group mean within each dim3 category{p_end}
{phang2}{cmd:pm_between_dim3_}{it:x} {hline 2} Between-dim3 component: dim3 mean minus grand mean{p_end}
{phang2}{cmd:pm_threefe_}{it:x} {hline 2} Three-way main-effect demeaned variable{p_end}

{pstd}
With {cmd:full}, the command further generates:{p_end}

{phang2}{cmd:pm_idtime_mean_}{it:x} {hline 2} Cell mean within each (id, time) pair{p_end}
{phang2}{cmd:pm_iddim3_mean_}{it:x} {hline 2} Cell mean within each (id, dim3) pair{p_end}
{phang2}{cmd:pm_timedim3_mean_}{it:x} {hline 2} Cell mean within each (time, dim3) pair{p_end}
{phang2}{cmd:pm_idtime_comp_}{it:x} {hline 2} Id-by-time interaction component{p_end}
{phang2}{cmd:pm_iddim3_comp_}{it:x} {hline 2} Id-by-dim3 interaction component{p_end}
{phang2}{cmd:pm_timedim3_comp_}{it:x} {hline 2} Time-by-dim3 interaction component{p_end}
{phang2}{cmd:pm_threeway_}{it:x} {hline 2} Full three-way ANOVA residual (saturated decomposition){p_end}

{pstd}
All generated variables are stored in double precision and are labeled.{p_end}

{marker formulas}{...}
{title:Formulas}

{pstd}
Let {it:x_it} denote a two-dimensional observation for unit {it:i} and time
{it:t}. The two-way demeaned variable is computed as:{p_end}

{p 8 8 2}
{it:x_it} - mean_i({it:x}) - mean_t({it:x}) + mean({it:x}).{p_end}

{pstd}
Let {it:x_itg} denote a three-dimensional observation for unit {it:i}, time
{it:t}, and third dimension {it:g}. The three-way main-effect demeaned
variable is computed as:{p_end}

{p 8 8 2}
{it:x_itg} - mean_i({it:x}) - mean_t({it:x}) - mean_g({it:x}) + 2*mean({it:x}).{p_end}

{pstd}
With {cmd:full}, the full three-way residual component is computed as:{p_end}

{p 8 8 2}
{it:x_itg} - mean_it({it:x}) - mean_ig({it:x}) - mean_tg({it:x}) +
mean_i({it:x}) + mean_t({it:x}) + mean_g({it:x}) - mean({it:x}).{p_end}

{pstd}
The three additive identities (2D, 3D main effects, and full 3-way ANOVA)
hold {it:exactly} at every observation in any panel, balanced or unbalanced.
What balance buys is (i) mutual orthogonality of the components, (ii) an
additive decomposition of Var({it:x}) into between- and within-components, and
(iii) numerical equivalence between {cmd:pm_twfe_}{it:x} and the OLS residual
from {helpb reghdfe} {it:x}, {cmd:absorb(}{it:id time}{cmd:)} (Correia 2016).
In unbalanced panels these three properties fail, although the additive
identity itself remains exact at the observation level. See Wansbeek and
Kapteyn (1989) for a formal treatment of the unbalanced case.{p_end}

{marker edge}{...}
{title:Edge cases}

{phang}
{bf:Single observation per unit.} If a panel id has only one observation in
the estimation sample, the within-id deviation is identically zero for that
observation.{p_end}

{phang}
{bf:Single time period.} If only one time period is observed in the sample,
the between-time component is identically zero.{p_end}

{phang}
{bf:Nested third dimension.} When {cmd:dim3()} is constant within each panel
id (for example, region nesting state), the id-by-dim3 cell mean equals the
id mean and the id-by-dim3 interaction component is collinear with the
between-dim3 main effect. {cmd:pmean} detects this and prints an
informational note. The additive identity still holds.{p_end}

{phang}
{bf:Missingness.} By default, missingness on the analysis variables is
handled per-variable inside each {cmd:egen} call, so different generated
variables can be defined on slightly different observation sets. Use the
{cmd:listwise} option to require joint non-missingness across all variables
in {it:varlist}.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}
Two-dimensional use with the Grunfeld investment panel:{p_end}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. pmean invest mvalue, id(company) time(year) replace}{p_end}

{pstd}
Three-dimensional use with the Munnell public-capital panel (note: {cmd:gsp}
is already log-transformed in this dataset):{p_end}

{phang2}{cmd:. webuse productivity, clear}{p_end}
{phang2}{cmd:. xtset state year}{p_end}
{phang2}{cmd:. pmean gsp, id(state) time(year) dim3(region) replace}{p_end}

{pstd}
Three-dimensional summary table and CSV export:{p_end}

{phang2}{cmd:. pmean gsp, id(state) time(year) dim3(region) table save(pmean_summary.csv) replace}{p_end}

{pstd}
Full pairwise three-dimensional decomposition:{p_end}

{phang2}{cmd:. pmean gsp, id(state) time(year) dim3(region) full genprefix(p2_) replace}{p_end}

{pstd}
Listwise sample across multiple outcomes:{p_end}

{phang2}{cmd:. pmean invest mvalue kstock, id(company) time(year) listwise replace}{p_end}

{pstd}
Stored results:{p_end}

{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. display r(overall_gsp)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:pmean} stores the following in {cmd:r()}:{p_end}

{pstd}
Scalars:{p_end}

{phang2}{cmd:r(N)} {hline 2} number of observations in the estimation sample{p_end}
{phang2}{cmd:r(dimensions)} {hline 2} number of panel dimensions (2 or 3){p_end}
{phang2}{cmd:r(overall_}{it:x}{cmd:)} {hline 2} overall mean of variable {it:x}, for each {it:x} in {it:varlist}{p_end}

{pstd}
Macros:{p_end}

{phang2}{cmd:r(cmd)} {hline 2} {cmd:pmean}{p_end}
{phang2}{cmd:r(cmdline)} {hline 2} command as typed{p_end}
{phang2}{cmd:r(varlist)} {hline 2} variables decomposed{p_end}
{phang2}{cmd:r(id)} {hline 2} panel identifier{p_end}
{phang2}{cmd:r(time)} {hline 2} time variable{p_end}
{phang2}{cmd:r(dim3)} {hline 2} third-dimension variable, if specified{p_end}
{phang2}{cmd:r(prefix)} {hline 2} prefix used for generated variables{p_end}
{phang2}{cmd:r(generated)} {hline 2} list of generated variables{p_end}
{phang2}{cmd:r(mode)} {hline 2} {cmd:2D} or {cmd:3D}{p_end}

{marker references}{...}
{title:References}

{phang}
Correia, S. 2016. A feasible estimator for linear models with multi-way
fixed effects. Preprint.
{browse "http://scorreia.com/research/hdfe.pdf":http://scorreia.com/research/hdfe.pdf}.{p_end}

{phang}
Mundlak, Y. 1978. On the pooling of time series and cross section data.
{it:Econometrica} 46: 69-85.{p_end}

{phang}
Wansbeek, T., and A. Kapteyn. 1989. Estimation of the error-components model
with incomplete panels. {it:Journal of Econometrics} 41: 341-361.{p_end}

{marker author}{...}
{title:Authors}

{pstd}Ahmad Nawaz{p_end}

{pstd}
School of Economics, Department of Industrial Economics,
Nanjing University, Nanjing 210093, China{p_end}

{pstd}
Department of Economics, University of Sahiwal, Sahiwal 57000, Pakistan{p_end}

{pstd}
Email: {browse "mailto:ahmadnawaz@uosahiwal.edu.pk":ahmadnawaz@uosahiwal.edu.pk}{p_end}

{pstd}Jianghuai Zheng{p_end}

{pstd}
School of Economics, Department of Industrial Economics,
Nanjing University, Nanjing 210093, China{p_end}

{pstd}
Email: {browse "mailto:zhengjh@nju.edu.cn":zhengjh@nju.edu.cn}{p_end}

{pstd}
Repository: {browse "https://github.com/ahmadNJU/stata-pmean":github.com/ahmadNJU/stata-pmean}{p_end}

{pstd}
{bf:Citation:}{p_end}

{pstd}
Nawaz, A., and J. Zheng. 2026. {it:pmean: Stata module for panel-data means
and exact within-between decomposition}. Statistical Software Components
SXXXXXX, Boston College Department of Economics.{p_end}

{pstd}
Version-pinned DOI: {browse "https://doi.org/10.5281/zenodo.20079459":10.5281/zenodo.20079459}{p_end}

{marker comparison}{...}
{title:Comparison with related commands}

{pstd}
{cmd:pmean} is descriptive: it generates panel-data transformations
(overall mean, unit and time means, within and between components, two-way
and three-way fixed-effect residuals) and stores them as new variables. It
does not perform statistical inference on differences in means.
{p_end}

{pstd}
For inferential pairwise comparisons of group means in cross-sectional
data, see {manhelp pwmean R}, which computes all pairwise differences
between group means under an equal-variance assumption and supports
multiple-comparison adjustments such as Tukey's HSD, Bonferroni, and
Dunnett.
{p_end}

{pstd}
For two-way and high-dimensional fixed-effects regression with proper inference, see {helpb reghdfe} (Correia 2016).
{p_end}

{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Help: {manhelp xtreg XT}, {manhelp xtsum XT}, {manhelp xtdescribe XT}, {manhelp egen D}, {manhelp pwmean R}; {helpb reghdfe} (if installed)
{p_end}
