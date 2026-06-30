{smcl}
{* *! version 2.0.0  30jun2026}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "egranger (if installed)" "help egranger"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "makicoint##syntax"}{...}
{viewerjumpto "Options" "makicoint##options"}{...}
{viewerjumpto "Description" "makicoint##description"}{...}
{viewerjumpto "Methodology" "makicoint##method"}{...}
{viewerjumpto "Engines" "makicoint##engine"}{...}
{viewerjumpto "Models" "makicoint##models"}{...}
{viewerjumpto "Lag selection" "makicoint##lags"}{...}
{viewerjumpto "Critical values and beyond five breaks" "makicoint##beyond"}{...}
{viewerjumpto "Graph" "makicoint##graph"}{...}
{viewerjumpto "Postestimation regression" "makicoint##post"}{...}
{viewerjumpto "Interpreting the output" "makicoint##interpret"}{...}
{viewerjumpto "Examples" "makicoint##examples"}{...}
{viewerjumpto "Stored results" "makicoint##results"}{...}
{viewerjumpto "References" "makicoint##references"}{...}
{viewerjumpto "Author" "makicoint##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{hi:makicoint} {hline 2}}Maki (2012) cointegration test with multiple structural breaks{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:makicoint}
{it:depvar} {it:indepvars}
{ifin}{cmd:,}
{opth maxb:reaks(#)}
[{it:options}]

{pstd}
{it:depvar} is the dependent variable and {it:indepvars} the one to four
regressors of the cointegrating relationship. Both may contain time-series
operators (see {help tsvarlist}). The data must be {helpb tsset} as a single,
gap-free time series before estimation.

{synoptset 30 tabbed}{...}
{marker opttab}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth maxb:reaks(#)}}maximum number of structural breaks; integer {cmd:>= 1}{p_end}

{syntab:Model}
{synopt:{opth m:odel(#)}}deterministic specification {cmd:0}, {cmd:1}, {cmd:2}, or {cmd:3}; default {cmd:model(2)}{p_end}

{syntab:Break search}
{synopt:{opth tr:imming(#)}}trimming fraction, {cmd:0 < # < 0.5}; default {cmd:trimming(0.10)}{p_end}
{synopt:{opt paper}}use the Maki (2012) paper break rule instead of the default engine{p_end}
{synopt:{opt gauss}}the default engine (accepted for explicitness; no effect){p_end}

{syntab:ADF lag selection}
{synopt:{opth maxl:ags(#)}}maximum ADF lag order; default {cmd:maxlags(12)}{p_end}
{synopt:{opth lagm:ethod(method)}}{cmd:tsig} (default), {cmd:fixed}, {cmd:zero}, {cmd:aic}, or {cmd:bic}{p_end}

{syntab:Critical values for more than five breaks}
{synopt:{opth sim:cv(#)}}simulate the critical values with {it:#} Monte-Carlo replications{p_end}
{synopt:{opth simt(#)}}series length used by the simulation; default {cmd:simt(1000)}{p_end}
{synopt:{opth sims:eed(#)}}random-number seed for the simulation; default {cmd:simseed(12345)}{p_end}

{syntab:Reporting}
{synopt:{opt gr:aph}}draw the two-panel break dashboard{p_end}
{synopt:{opth name(string)}}name of the saved graph; default {cmd:makicoint_graph}{p_end}
{synopt:{opt reg}}show the cointegrating regression at the breaks (OLS){p_end}
{synopt:{opt regn:ewey}}show that regression with Newey-West HAC standard errors{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{cmd:makicoint} is for a single time series; panel data are not supported. Up to
four regressors are allowed, the range covered by Maki's (2012) critical-value
table.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:makicoint} performs the {bf:Maki (2012)} residual-based test for
cointegration that allows for an {it:unknown} number of structural breaks in the
cointegrating vector, assumed to be at most a maximum {it:m} chosen by the user
through {opt maxbreaks()}. The null hypothesis is

{p 8 8 2}{bf:H0:} no cointegration,{p_end}

{pstd}and the alternative is{p_end}

{p 8 8 2}{bf:H1:} cointegration with up to {it:m} structural breaks.{p_end}

{pstd}
The test extends Gregory and Hansen (1996), which allows a single break, and
Hatemi-J (2008), which allows two, to an arbitrary (bounded) number of breaks.
It is therefore appropriate when the number of breaks is genuinely unknown, when
the long-run relationship may shift more than twice, or when the relationship is
subject to persistent regime (Markov) switching, situations in which one- or
two-break tests are misspecified and lose power.

{pstd}
For the methodology see {help makicoint##method:Methodology}; for the two
available break-selection {help makicoint##engine:engines}; for the four
deterministic {help makicoint##models:models}; for the
{help makicoint##lags:lag-selection} rules; and for the treatment of more than
five breaks see {help makicoint##beyond:Critical values and beyond five breaks}.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth maxbreaks(#)} sets the maximum number of structural breaks entertained
under the alternative. Any integer {cmd:>= 1} is allowed, provided it is feasible
for the sample: a break needs at least {cmd:tb = round(trimming*N)} observations
on either side and between neighbours, so the feasible maximum is about
{cmd:floor(N/(tb+1)) - 1}. If you request more breaks than fit, {cmd:makicoint}
stops with an informative error. Maki (2012, Table 1) tabulates critical values
for one to five breaks; for more than five, see {opt simcv()}.

{dlgtab:Model}

{phang}
{opth model(#)} selects the deterministic terms and the type of break; the
default is {cmd:model(2)} (regime shift). The four models are detailed under
{help makicoint##models:Models}:

{p 8 12 2}{cmd:0} {space 3}level shift (break in the intercept only);{p_end}
{p 8 12 2}{cmd:1} {space 3}level shift with a (common) linear trend;{p_end}
{p 8 12 2}{cmd:2} {space 3}regime shift (break in the intercept and the slopes);{p_end}
{p 8 12 2}{cmd:3} {space 3}regime shift with trend (break in intercept, trend and slopes).{p_end}

{dlgtab:Break search}

{phang}
{opth trimming(#)} is the trimming fraction eta in (0,0.5); the default is
{cmd:0.10}. It fixes the minimum distance, {cmd:tb = round(#*N)}, that every
break must keep from the ends of the sample and from the other breaks, so that
no regime is shorter than this fraction of the sample. Smaller values permit
breaks nearer the ends and closer together (and hence more breaks); larger values
are more conservative. Maki (2012) uses {cmd:0.05}; the package default of
{cmd:0.10} matches the original GAUSS code.

{phang}
{opt paper} selects the {bf:Maki (2012) paper} break rule; {opt gauss} (the
default) selects the {bf:GAUSS/tspdlib} rule. The two give the same test
statistic but can place the break dates differently; see
{help makicoint##engine:Engines}. {opt gauss} is accepted only for explicitness
and has no effect, since it is the default.

{dlgtab:ADF lag selection}

{phang}
{opth maxlags(#)} is the largest ADF augmentation order considered; the default
is {cmd:12}. With {cmd:lagmethod(fixed)} this is the order actually used; with
{cmd:tsig}, {cmd:aic} and {cmd:bic} it is the upper bound of the search.

{phang}
{opth lagmethod(method)} chooses how the ADF lag is selected for {it:each}
candidate regression. See {help makicoint##lags:Lag selection} for the formulae.

{p 8 12 2}{cmd:tsig} {space 1}general-to-specific {it:t}-significance, the default and the
rule of the original GAUSS code (threshold |t| = 1.654);{p_end}
{p 8 12 2}{cmd:fixed} {space 0}always use {cmd:maxlags} lags;{p_end}
{p 8 12 2}{cmd:zero} {space 1}use zero lags (the plain Engle-Granger / Dickey-Fuller form);{p_end}
{p 8 12 2}{cmd:aic} {space 2}minimize the Akaike information criterion;{p_end}
{p 8 12 2}{cmd:bic} {space 2}minimize the Schwarz (Bayesian) information criterion.{p_end}

{dlgtab:Critical values for more than five breaks}

{phang}
{opth simcv(#)} simulates the critical values with {it:#} Monte-Carlo
replications, by the design Maki used to build Table 1. It is {it:required} for
inference when {cmd:maxbreaks() > 5} (no tabulated values exist) and is
{it:optional} otherwise (for example to obtain finite-sample values). Because the
entire break search is rerun on every replication it is computationally heavy:
use a few thousand replications for reported work. See
{help makicoint##beyond:Critical values and beyond five breaks}.

{phang}
{opth simt(#)} is the length of the simulated series (default {cmd:1000}, as in
Maki's Table 1); {opth simseed(#)} sets the seed (default {cmd:12345}) so the
simulated values are reproducible.

{dlgtab:Reporting}

{phang}
{opt graph} draws a two-panel dashboard of the result; {opth name(string)} names
the saved graph (default {cmd:makicoint_graph}). See {help makicoint##graph:Graph}.

{phang}
{opt reg} displays the cointegrating regression evaluated at the estimated break
dates by ordinary least squares; {opt regnewey} displays the same regression with
Newey-West heteroskedasticity- and autocorrelation-consistent standard errors,
with lag {cmd:floor(4*(T/100)^(2/9))}. These are descriptive long-run fits and do
{it:not} change the test. See {help makicoint##post:Postestimation regression}.


{marker method}{...}
{title:Methodology}

{pstd}
For a maximum of {it:m} breaks the cointegrating regression of {it:depvar} on
{it:indepvars}, the deterministic terms of the chosen {help makicoint##models:model},
and break dummies is estimated; its residual is tested for a unit root with an
augmented Dickey-Fuller (ADF) regression. Breaks are found one at a time, in the
spirit of Bai and Perron (1998):

{p 8 11 2}{bf:1.} Search a single break over all admissible dates (trimmed by {cmd:tb}).
For each candidate, fit the one-break cointegrating regression, run the ADF
regression on its residual, and record the ADF {it:t}-statistic for rho = 0 and a
sum of squared residuals (SSR). Keep the smallest {it:t} as this step's value and
locate the first break (see {help makicoint##engine:Engines} for which SSR).{p_end}

{p 8 11 2}{bf:2.} Holding the first break fixed, search a second break over the
remaining sub-samples; record the step-2 minimum {it:t} and the second break.{p_end}

{p 8 11 2}{bf:3.} Repeat until {it:m} breaks have been placed.{p_end}

{p 8 11 2}{bf:4.} The {bf:test statistic} is the {it:overall minimum} ADF
{it:t}-statistic across every candidate of every step. Because it is a minimum, it
can only become (weakly) more negative as {it:m} increases.{p_end}

{pstd}
Reject {bf:H0} when the test statistic is {it:below} (more negative than) the
critical value. The lag order of the ADF regression is chosen for each candidate
by {opt lagmethod()}; {cmd:r(lags)} reports the order at the regression that
attains the test statistic.


{marker engine}{...}
{title:Engines}

{pstd}
The two engines yield the {it:same} test statistic (the minimum ADF {it:t}). They
differ only in how each break {it:date} is chosen, which can change which
sub-samples are searched at later steps, and hence the statistic, once
{cmd:maxbreaks() >= 2}.

{pstd}
{bf:Default (GAUSS/tspdlib).} The sub-sample with the smallest minimum ADF
{it:t}-statistic is selected, and the break is placed at the minimizer of the
{it:ADF-regression} SSR within that sub-sample. This reproduces the original GAUSS
procedures (TSPDLIB {cmd:coint_maki}) exactly, so out of the box {cmd:makicoint}
returns the same statistic and break points as the standard GAUSS/tspdlib
implementation; this was verified on real and simulated data across all four
models and a range of break counts (agreement to floating-point precision).

{pstd}
{bf:paper.} With {opt paper}, each break is instead placed at the {it:global}
minimizer of the {it:cointegrating-regression} SSR over all admissible partitions,
which is the rule stated in Maki (2012, Steps 2 and 4). At one break the two
engines essentially agree; with two or more breaks the paper rule may select
different dates and therefore a different statistic.

{pstd}
Use the default to match published GAUSS/tspdlib results; use {opt paper} for the
break rule exactly as written in the article.


{marker models}{...}
{title:Models}

{pstd}With {it:D_it} = 1 if {it:t} > {it:TB_i} and 0 otherwise ({it:TB_i} the i-th break):{p_end}

{p 8 8 2}{bf:Model 0 - level shift}{p_end}
{p 12 12 2}{it:y_t = mu + sum_i mu_i D_it + beta' x_t + u_t}{p_end}

{p 8 8 2}{bf:Model 1 - level shift with trend}{p_end}
{p 12 12 2}{it:y_t = mu + sum_i mu_i D_it + gamma t + beta' x_t + u_t}{p_end}

{p 8 8 2}{bf:Model 2 - regime shift}{p_end}
{p 12 12 2}{it:y_t = mu + sum_i mu_i D_it + beta' x_t + sum_i delta_i' x_t D_it + u_t}{p_end}

{p 8 8 2}{bf:Model 3 - regime shift with trend}{p_end}
{p 12 12 2}{it:y_t = mu + sum_i mu_i D_it + gamma t + sum_i gamma_i t D_it + beta' x_t + sum_i delta_i' x_t D_it + u_t}{p_end}

{pstd}
Models 0 and 1 break only the intercept (and keep a common slope); models 2 and 3
also break the slope coefficients on {it:indepvars}, allowing the long-run
elasticities themselves to change at each break. Critical values differ by model,
by the number of regressors, and by the maximum number of breaks.


{marker lags}{...}
{title:Lag selection}

{pstd}
For a residual {it:u}, the ADF regression is

{p 8 12 2}{it:du_t = rho u_(t-1) + sum_(j=1)^(p) phi_j du_(t-j) + e_t},{p_end}

{pstd}and the reported quantity at each candidate is the {it:t}-statistic of {it:rho}.{p_end}

{p 4 6 2}o {space 1}{cmd:tsig} starts at {cmd:maxlags} and drops the highest lag until the
last included lag is significant (|t| > 1.654), else returns 0. This is the
default and the rule of the original code.{p_end}
{p 4 6 2}o {space 1}{cmd:fixed} uses exactly {cmd:maxlags} lags at every candidate.{p_end}
{p 4 6 2}o {space 1}{cmd:zero} uses {it:p} = 0 (no augmentation).{p_end}
{p 4 6 2}o {space 1}{cmd:aic} / {cmd:bic} pick {it:p} in 0..{cmd:maxlags} minimizing the
respective information criterion.{p_end}


{marker beyond}{...}
{title:Critical values and beyond five breaks}

{pstd}
For {cmd:maxbreaks() <= 5} the command reports the {bf:Maki (2012) Table 1}
critical values (Monte Carlo, T = 1,000, 10,000 replications), which depend on the
model, the number of regressors (1-4) and the maximum number of breaks (1-5).

{pstd}
Maki (2012, footnote 5) remarks that the test "can have more breaks" but reports
no results, and Table 1 stops at five. {bf:A contribution of this implementation}
({it:Roudane, 2026}) is to make that case usable: {cmd:makicoint} estimates the
statistic and break dates for {it:any} feasible number of breaks, and for more
than five it supplies the otherwise missing critical values on demand through
{opt simcv()}.

{pstd}
{opt simcv(#)} follows Maki's own simulation design (his footnote 3). On each of
the {it:#} replications, {it:depvar} and {it:indepvars} are replaced by
independent driftless random walks (cumulated i.i.d. N(0,I)), the {it:full} break
search is rerun for the requested {opt model()}, {opt maxbreaks()}, lag rule,
trimming and engine, and the resulting minimum-{it:t} statistic is stored; the
1%, 5% and 10% critical values are the corresponding quantiles. Use {opt simt()}
to set the series length and a few thousand replications for stable values
(reproducing Table 1 needs {cmd:simcv(10000)} at {cmd:simt(1000)}). The
computation is heavy because the whole search is repeated every replication.

{pstd}
{cmd:r(cvsource)} records the source of the reported values: {cmd:table} (Maki's
Table 1), {cmd:simulated} ({opt simcv()}), or {cmd:none} (more than five breaks
and no {opt simcv()}). With {opt simcv()}, {cmd:r(simreps)} holds the replication
count.

{pstd}{bf:Example} -- eight breaks with 5,000 simulated critical values:{p_end}
{phang2}{cmd:. makicoint y x, maxbreaks(8) model(2) simcv(5000) simt(600)}{p_end}
{phang2}{cmd:. display "stat=" r(test_stat) "  5% cv=" r(cv5) "  source=" "`=r(cvsource)'"}{p_end}


{marker graph}{...}
{title:Graph}

{pstd}
{opt graph} produces a two-panel dashboard with alternating shaded regimes and
dashed, dated break lines:

{p 8 10 2}{bf:Top} {space 4}{it:depvar} together with the fitted, break-adjusted long-run relation;{p_end}
{p 8 10 2}{bf:Bottom} {space 1}the cointegrating residual (the equilibrium error) about zero.{p_end}

{pstd}
The combined title gives the model and the reject / fail-to-reject conclusion, and
a footnote lists the break dates with the statistic and the 5% critical value.
Name the graph with {opt name()} and export it with {helpb graph export}. The fit
underlying the graph is the same cointegrating regression as
{help makicoint##post:reg}.


{marker post}{...}
{title:Postestimation regression}

{pstd}
{opt reg} (OLS) and {opt regnewey} (Newey-West HAC) display the cointegrating
regression evaluated at the estimated break dates: regime dummies, and for
models 2 and 3 the dummy-by-regressor (and dummy-by-trend) interactions. These
summarize the estimated long-run relationship and its shifts; they are reported
{it:after} and {it:independently of} the test statistic and do not affect it.


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
Read the test statistic against the three critical values: reject {bf:H0} of no
cointegration at the 1%, 5% or 10% level when the statistic is below the
corresponding value; otherwise fail to reject. The break table lists each
estimated break by observation number, calendar date and sample fraction. As the
maximum number of breaks rises the critical values become more extreme (more
negative), so allowing more breaks makes rejection harder, other things equal.
The reported {cmd:r(lags)} is the ADF order at the regression that delivered the
statistic.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}{bf:1.} Regime shift, up to two breaks, with the dashboard{p_end}
{phang2}{cmd:. makicoint ln_consump ln_inc ln_inv, maxbreaks(2) graph}{p_end}

{pstd}{bf:2.} Level shift, one break, showing the long-run regression at the break{p_end}
{phang2}{cmd:. makicoint ln_consump ln_inc, maxbreaks(1) model(0) reg}{p_end}

{pstd}{bf:3.} Regime shift with trend, three breaks{p_end}
{phang2}{cmd:. makicoint ln_consump ln_inc ln_inv, maxbreaks(3) model(3)}{p_end}

{pstd}{bf:4.} The Maki (2012) paper break rule instead of the default engine{p_end}
{phang2}{cmd:. makicoint ln_consump ln_inc, maxbreaks(3) model(2) paper}{p_end}

{pstd}{bf:5.} Custom trimming and information-criterion lag selection{p_end}
{phang2}{cmd:. makicoint ln_consump ln_inc ln_inv, maxbreaks(2) trimming(0.15) lagmethod(aic) maxlags(8)}{p_end}

{pstd}{bf:6.} Seven breaks with simulated critical values (heavy){p_end}
{phang2}{cmd:. makicoint ln_consump ln_inc, maxbreaks(7) simcv(2000) simt(500)}{p_end}

{pstd}{bf:7.} Using stored results{p_end}
{phang2}{cmd:. makicoint ln_consump ln_inc, maxbreaks(2)}{p_end}
{phang2}{cmd:. display "stat = " r(test_stat) "  reject = " r(reject) "  first break = " r(bpdate1)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:makicoint} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(test_stat)}}test statistic (minimum ADF {it:t}-statistic){p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}1%, 5%, 10% critical values (missing if unavailable){p_end}
{synopt:{cmd:r(reject)}}1 if {bf:H0} rejected at 10%, else 0 (missing if no CVs){p_end}
{synopt:{cmd:r(nobs)}}number of observations{p_end}
{synopt:{cmd:r(maxbreaks)}}maximum number of breaks requested{p_end}
{synopt:{cmd:r(model)}}model number (0-3){p_end}
{synopt:{cmd:r(trimming)}}trimming fraction{p_end}
{synopt:{cmd:r(lags)}}ADF lag order at the test-statistic regression{p_end}
{synopt:{cmd:r(simreps)}}simulation replications (only with {opt simcv()}){p_end}
{synopt:{cmd:r(bp#)}}observation number of the #-th break{p_end}
{synopt:{cmd:r(bpdate#)}}calendar/time value of the #-th break{p_end}
{synopt:{cmd:r(bpfrac#)}}sample fraction at the #-th break{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}independent variables{p_end}
{synopt:{cmd:r(model_name)}}model name{p_end}
{synopt:{cmd:r(lagmethod)}}lag-selection method{p_end}
{synopt:{cmd:r(engine)}}engine used (default or paper){p_end}
{synopt:{cmd:r(cvsource)}}{cmd:table}, {cmd:simulated}, or {cmd:none}{p_end}


{marker references}{...}
{title:References}

{phang}
Maki, D. 2012. Tests for cointegration allowing for an unknown number of breaks.
{it:Economic Modelling} 29: 2011-2015.
{browse "https://doi.org/10.1016/j.econmod.2012.04.022":https://doi.org/10.1016/j.econmod.2012.04.022}

{phang}
Bai, J., and P. Perron. 1998. Estimating and testing linear models with multiple
structural changes. {it:Econometrica} 66: 47-78.

{phang}
Gregory, A. W., and B. E. Hansen. 1996. Residual-based tests for cointegration in
models with regime shifts. {it:Journal of Econometrics} 70: 99-126.

{phang}
Hatemi-J, A. 2008. Tests for cointegration with two unknown regime shifts with an
application to financial market integration. {it:Empirical Economics} 35: 497-505.

{phang}
Kapetanios, G. 2005. Unit-root testing against the alternative hypothesis of up to
m structural breaks. {it:Journal of Time Series Analysis} 26: 123-133.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
The default engine reproduces the original GAUSS procedures by Daiki Maki,
included in the TSPDLIB GAUSS library (Saban Nazlioglu) and modified by Jason
Jones (Aptech Systems). The general support for more than five breaks and the
simulated critical values are contributions of this Stata implementation.

{pstd}
Please cite as:{break}
Roudane, M. 2026. makicoint: Stata module for the Maki cointegration test with
multiple structural breaks. Statistical Software Components, Boston College
Department of Economics.


{title:Also see}

{psee}
Online: {helpb tsset}, {helpb dfuller}, {helpb pperron}, {helpb vecrank}
{p_end}
