{smcl}
{* *! xtqrplot v1.3.0  02apr2026}{...}
{viewerjumpto "Syntax" "xtqrplot##syntax"}{...}
{viewerjumpto "Description" "xtqrplot##description"}{...}
{viewerjumpto "Options" "xtqrplot##options"}{...}
{viewerjumpto "Effect types" "xtqrplot##effects"}{...}
{viewerjumpto "Output" "xtqrplot##output"}{...}
{viewerjumpto "Examples" "xtqrplot##examples"}{...}
{viewerjumpto "References" "xtqrplot##references"}{...}
{viewerjumpto "Author" "xtqrplot##author"}{...}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:xtqrplot} {hline 2}}Entity-specific marginal effects from panel quantile regression{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt xtqrplot} {depvar} {indepvars} {ifin}{cmd:,}
{opt panelvar(varname)}
{opt timevar(varname)}
[{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt panelvar(varname)}}panel (cross-section) identifier{p_end}
{synopt:{opt timevar(varname)}}time identifier{p_end}
{syntab:Model}
{synopt:{opt method(string)}}{bf:xtqreg} (default) or {bf:qregpd}{p_end}
{synopt:{opt reps(#)}}bootstrap replications for {bf:qregpd}; default {bf:200}{p_end}
{synopt:{opt seed(#)}}random seed for {bf:qregpd} reproducibility{p_end}
{synopt:{opt nwindows(#)}}number of quantile windows 1-49; default {bf:9}{p_end}
{syntab:Effect}
{synopt:{opt effect(string)}}{bf:coef} (default), {bf:semi}, {bf:elast}, or {bf:bp}{p_end}
{syntab:Plot}
{synopt:{opt plottype(string)}}{bf:cross} (default), {bf:time}, or {bf:twoway}{p_end}
{synopt:{opt noplot}}suppress graphs; produce only tables{p_end}
{synopt:{opt nonormal}}suppress pre-estimation normality tests and histograms{p_end}
{syntab:Output}
{synopt:{opt saving(string)}}base filename for .gph and .dta output files{p_end}
{synopt:{opt replace}}overwrite existing files{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtqrplot} estimates panel quantile regression across a grid of interior
quantile windows and produces entity-specific marginal effect plots and tables.
The command answers the economically relevant question: {it:what is the
coefficient for a given country (or year)?} -- not an average across the
distribution, but the coefficient at the quantile where that entity's
dependent variable actually sits.

{pstd}
{cmd:xtqrplot} is compatible with both {bf:balanced} and {bf:unbalanced} panel
data. Unbalanced panels are handled automatically through the underlying
estimators ({cmd:xtqreg} and {cmd:qregpd}); the entity-level effects and
plots are computed from whatever observations are available for each unit.

{pstd}
The command proceeds in five stages:

{phang2}
(1) {bf:Normality diagnostics.} Skewness-Kurtosis ({helpb sktest}),
Shapiro-Wilk ({helpb swilk}), and Shapiro-Francia ({helpb sfrancia}) tests
for each variable, plus histograms with kernel density overlays.
Suppress with {opt nonormal}.

{phang2}
(2) {bf:Quantile regression.} The panel model is estimated at each quantile
window using {cmd:xtqreg} or {cmd:qregpd}. Coefficients and standard errors
are stored internally.

{phang2}
(3) {bf:Median summary.} Results at the quantile nearest q50 are displayed
as a coefficient table with SE, z-statistic, p-value, and a replication
command to reproduce those results manually.

{phang2}
(4) {bf:Entity assignment.} Each entity's mean (or actual, for twoway) value
of the dependent variable is ranked in the overall distribution and assigned
to the nearest quantile window. The corresponding coefficient is scaled into
the chosen effect type with 95% confidence intervals.

{phang2}
(5) {bf:Visualisation.} Bar charts with CI error bars and secondary-axis
percentile markers (cross/time) or diverging-colour circle heat maps with
coefficient value labels (twoway) are produced, one per independent variable.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt method(string)} selects the estimator.

{pmore}
{bf:xtqreg} (default) implements Machado & Santos Silva (2019) moments-based
quantile regression for large balanced and unbalanced panels. Requires:
{stata ssc install xtqreg}.

{pmore}
{bf:qregpd} implements Powell (2016) with bootstrap inference, consistent
under non-additive fixed effects. Requires: {stata ssc install qregpd}.
Use {opt reps()} to control bootstrap replications and {opt seed()} for
reproducibility.

{phang}
{opt reps(#)} bootstrap replications for {opt method(qregpd)}. Default 200.

{phang}
{opt seed(#)} sets the random seed before each {cmd:qregpd} estimation,
ensuring identical results across runs. Not applicable to {cmd:xtqreg}.

{phang}
{opt nwindows(#)} number of interior quantile windows. Step = 100/(nwindows+1);
grid runs from step to nwindows*step. Default {bf:9} gives 10,20,...,90.

{col 12}{it:nwindows}{col 25}Quantile grid
{col 12}1{col 25}50 (median only)
{col 12}3{col 25}25, 50, 75
{col 12}4{col 25}20, 40, 60, 80
{col 12}9{col 25}10, 20, ..., 90 {it:(default)}
{col 12}19{col 25}5, 10, ..., 95

{dlgtab:Effect}

{phang}
{opt effect(string)} specifies what is plotted for each entity.

{pmore}{bf:coef} -- raw coefficient beta at the entity's assigned window{p_end}
{pmore}{bf:semi} -- semi-elasticity: beta x mean(X) for that entity{p_end}
{pmore}{bf:elast} -- elasticity: beta x mean(X) / mean(Y) (requires Y > 0){p_end}
{pmore}{bf:bp} -- basis points: beta x 10,000 (for financial rate variables){p_end}

{dlgtab:Plot}

{phang}
{opt plottype(string)} controls the visualisation dimension.

{pmore}{bf:cross} (default) -- horizontal bar chart, entities on y-axis, 95% CI
error bars, green circle on secondary x-axis showing exact percentile of
each entity's mean dependent variable.{p_end}

{pmore}{bf:time} -- same layout, time periods on y-axis.{p_end}

{pmore}{bf:twoway} -- heat map (rows=entities, cols=years) with a diverging
colour palette (blue=negative, red=positive, intensity=magnitude), coefficient
value labels, and a printed matrix table. One plot and table per independent
variable. If {cmd:heatplot} is installed ({stata ssc install heatplot}), a
high-quality continuous colour legend is produced. Otherwise a 10-bin scatter
fallback is used automatically.{p_end}

{pmore}{bf:Note on twoway plot size:} The twoway heat map is best suited for
panels with a limited number of units and time periods (e.g. up to 15 countries
and 20 years). For larger panels, labels and cells become unreadable; in those
cases the printed matrix table is the more informative output.{p_end}

{phang}
{opt noplot} suppresses all graphs.

{phang}
{opt nonormal} suppresses pre-estimation normality tests and histograms.

{dlgtab:Output}

{phang}
{opt saving(string)} base filename (no extension). Saves:
{it:basename}{bf:_cross.dta}, {it:basename}{bf:_cross.gph}, etc.

{phang}
{opt replace} overwrites existing files.


{marker effects}{...}
{title:Effect types}

{pstd}
Let beta(tau_i) be the estimated coefficient at entity i's assigned quantile.
X-bar_i and Y-bar_i are entity i's mean regressor and dependent variable.

{col 5}{bf:Effect}{col 16}{bf:Formula}{col 50}{bf:Interpretation}
{col 5}{hline 65}
{col 5}coef{col 16}beta(tau_i){col 50}Change in conditional quantile of Y per unit X
{col 5}semi{col 16}beta(tau_i) x X-bar_i{col 50}Effect scaled by entity's X level
{col 5}elast{col 16}beta(tau_i) x X-bar_i / Y-bar_i{col 50}Percentage change relative to Y level
{col 5}bp{col 16}beta(tau_i) x 10,000{col 50}Effect in basis points
{col 5}{hline 65}

{pstd}
All effects include 95% confidence intervals (beta +/- 1.96 x SE) shown as
error bars (cross/time plots).


{marker qc}{...}
{title:Quality checks performed internally}

{pstd}
{cmd:xtqrplot} performs the following quality checks automatically before
and during estimation:

{phang2}(1) {bf:Option validation} -- All option values are validated before
any estimation begins. Invalid values exit immediately with rc=198 and a
descriptive error message.{p_end}

{phang2}(2) {bf:Package availability} -- The selected estimator (xtqreg or
qregpd) is confirmed to be installed before estimation starts.{p_end}

{phang2}(3) {bf:Panel structure} -- {helpb xtset} is called internally to
verify that panelvar and timevar form a valid panel structure.{p_end}

{phang2}(4) {bf:Sample size warning} -- A warning is printed if fewer than
30 observations are in the estimation sample.{p_end}

{phang2}(5) {bf:Normality diagnostics} -- sktest, swilk, and sfrancia are
run for every variable in the model, with histograms, before any regression
is estimated. Use {opt nonormal} to suppress.{p_end}

{phang2}(6) {bf:Per-quantile convergence} -- Each quantile window is
estimated with {cmd:capture}. If any window fails, estimation stops
immediately with a detailed error message listing likely causes and
remedies.{p_end}

{phang2}(7) {bf:Missing effect check} -- After computing entity-level
effects, the count of missing values per variable is reported so the
user can identify assignment failures.{p_end}

{phang2}(8) {bf:CI consistency} -- Confidence interval bounds are computed
as beta +/- 1.96 x SE; missing SE values produce missing CI bounds rather
than incorrect values.{p_end}

{phang2}(9) {bf:File overwrite protection} -- Saving without {opt replace}
when the output file already exists exits with rc=602 and a clear message,
preventing silent data overwrites.{p_end}

{phang2}(10) {bf:Plot failure isolation} -- In twoway mode, each independent
variable's plot is wrapped in {cmd:capture}. A plot failure for one variable
does not prevent the others from being produced or the matrix table from
being printed.{p_end}

{pstd}
A formal pre-submission test suite ({cmd:xtqrplot_test_suite.do}) covering
37 tests across 11 test blocks is available from the package repository.
Run it after installation to verify all checks pass in your Stata environment.


{marker output}{...}
{title:Output produced}

{pstd}
{cmd:xtqrplot} prints three blocks to the Stata results window:

{phang2}
(1) {bf:Normality diagnostics} -- sktest, swilk, sfrancia for every variable,
plus histograms with kernel density overlays.

{phang2}
(2) {bf:Median-level table} -- coefficient, SE, z, p-value at the quantile
nearest q50, plus the exact command to replicate those results manually.

{phang2}
(3) {bf:Entity results table} -- entity name, mean(Y), exact percentile,
assigned quantile window, and computed effect for each independent variable.
For twoway plots, a full country x year matrix of coefficients is also printed.

{pstd}
The saved dataset (if {opt saving()} is used) contains:
{bf:_my} (mean Y), {bf:_mx#} (mean X#), {bf:_pctrank} (percentile 0-100),
{bf:_q_win} (assigned window), {bf:_eff#} (effect), {bf:_eff#_lo/_hi} (95% CI bounds).


{marker examples}{...}
{title:Examples}

    {hline 50}
    {it:Setup -- simulate panel with skewed x2}
    {hline 50}

        . clear
        . set seed 2024
        . set obs 100
        . gen country_id = ceil(_n/10)
        . gen year        = mod(_n-1,10) + 2010
        . gen x1 = rnormal(2,1)
        . gen u1 = runiform()
        . gen u2 = runiform()
        . gen x2 = -ln(u1) - ln(u2) - 2
        . drop u1 u2
        . gen y  = 1 + 0.4*x1 + 0.3*x2 + rnormal()*(1+0.5*abs(x2))
        . label define clab 1 "Argentina" 2 "Brazil" 3 "Chile" ///
              4 "Colombia" 5 "Ecuador" 6 "Mexico" 7 "Panama"   ///
              8 "Peru" 9 "Uruguay" 10 "Venezuela"
        . label values country_id clab
        . xtset country_id year

    {hline 50}
    {it:Default cross-section plot}
    {hline 50}

        . xtqrplot y x1 x2, panelvar(country_id) timevar(year)

    {hline 50}
    {it:Twoway heat map (observe x2 variation)}
    {hline 50}

        . xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
              plottype(twoway) nonormal

    {hline 50}
    {it:Basis points, semi-elasticity, save output}
    {hline 50}

        . xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
              effect(bp) saving(results/out) replace nonormal

    {hline 50}
    {it:qregpd with seed for reproducibility}
    {hline 50}

        . xtqrplot y x1, panelvar(country_id) timevar(year) ///
              method(qregpd) reps(300) seed(42) nwindows(4)

    {hline 50}
    {it:Suppress graph, extract data only}
    {hline 50}

        . xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
              noplot nonormal saving(mydata) replace
        . use mydata_cross, clear
        . list country_id _pctrank _q_win _eff1 _eff2


{marker references}{...}
{title:References}

{phang}
Koenker, R. and Bassett, G. (1978).
Regression quantiles.
{it:Econometrica}, 46(1), 33-50.

{phang}
Machado, J.A.F. and Santos Silva, J.M.C. (2019).
Quantiles via moments.
{it:Journal of Econometrics}, 213(1), 145-173.
{browse "https://doi.org/10.1016/j.jeconom.2019.04.009"}

{phang}
Powell, D. (2016).
Quantile regression with nonadditive fixed effects.
{it:RAND Working Paper WR-1088}.
{browse "https://www.rand.org/pubs/working_papers/WR1088.html"}

{phang}
Royston, P. (1991).
Shapiro-Francia test for normality.
{it:Stata Technical Bulletin}, 2, 16-17.


{marker disclaimer}{...}
{title:Model performance disclaimer}

{pstd}
{cmd:xtqrplot} is a visualisation and post-estimation tool. Model performance
and the validity of results depend entirely on the underlying panel quantile
regression and the data provided. The following caveats apply:

{phang2}
Results are only meaningful when the panel quantile regression converges
successfully at each quantile window. Always inspect the quantile-by-quantile
output and verify that coefficients move sensibly across quantiles.

{phang2}
The quantile window assignment is a nearest-neighbour approximation. Entities
near the boundary between two windows may be assigned to either; small samples
amplify this sensitivity.

{phang2}
The twoway heat map interpolates spatially across an unbalanced panel, which
can produce misleading colour patterns for panels with many missing cells.

{phang2}
{bf:This package is under active development.} If you observe any irregularity
-- unexpected output, errors not listed in the error catalogue, or results that
appear economically implausible -- please report them to the author with a
minimal reproducible example. Your feedback directly improves the package.

{pstd}
Contact: {browse "mailto:nouman.arshed@gmail.com":nouman.arshed@gmail.com}


{marker author}{...}
{title:Author}

{pstd}Dr Noman Arshed{p_end}
{pstd}Senior Lecturer{p_end}
{pstd}Department of Business Analytics{p_end}
{pstd}Sunway Business School, Sunway University{p_end}
{pstd}Email: {browse "mailto:nouman.arshed@gmail.com":nouman.arshed@gmail.com}{p_end}

{pstd}
Bug reports and suggestions are welcome. Please include a reproducible
example using the simulated dataset in the Examples section above.


{title:Also see}

{psee}
{helpb xtset}, {helpb qreg}, {helpb sktest}, {helpb swilk}, {helpb sfrancia},
{helpb xtqreg} (if installed), {helpb qregpd} (if installed),
{helpb heatplot} (if installed, enhances twoway plots)
{p_end}

{pstd}
To install optional enhanced plotting packages:{p_end}
{phang2}{stata ssc install heatplot}{p_end}
{phang2}{stata ssc install palettes}{p_end}
{phang2}{stata ssc install colrspace}{p_end}
