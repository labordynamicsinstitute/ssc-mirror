{smcl}
{* *! version 1.0.0  09aug2026}{...}
{vieweralsosee "xtasym methods" "help xtasym_methods"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{vieweralsosee "xtsum" "help xtsum"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{viewerjumpto "Syntax" "xtasym##syntax"}{...}
{viewerjumpto "Description" "xtasym##description"}{...}
{viewerjumpto "Options" "xtasym##options"}{...}
{viewerjumpto "Conventions" "xtasym##conventions"}{...}
{viewerjumpto "Interpreting the output" "xtasym##output"}{...}
{viewerjumpto "Using the partial sums in a model" "xtasym##model"}{...}
{viewerjumpto "Remarks" "xtasym##remarks"}{...}
{viewerjumpto "Stored results" "xtasym##results"}{...}
{viewerjumpto "Examples" "xtasym##examples"}{...}
{viewerjumpto "References" "xtasym##references"}{...}
{viewerjumpto "Author" "xtasym##author"}{...}
{hi:help xtasym}{right:Version 1.0.0  9 August 2026}
{hline}

{title:Title}

{phang}
{bf:xtasym} {hline 2} Directional asymmetry with panel data: partial sums,
diagnostics and graphics


{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:xtasym} {varlist} {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Construction}
{synopt:{opt t:hreshold(#)}}size of the dead band around zero; default
{cmd:threshold(0)}{p_end}
{synopt:{opt conv:ention(rule)}}{cmd:shin} (default) or {cmd:allison}; sets the
sign of the negative arm{p_end}
{synopt:{opt p:refix(string)}}prefix for every variable created{p_end}
{synopt:{opt nogen:erate}}do not create partial sums; treat {varlist} as partial
sums already built{p_end}
{synopt:{opt fdm}}also create the undifferenced first-difference-method
components{p_end}
{synopt:{opt replace}}overwrite variables of the same name{p_end}

{syntab:Tables}
{synopt:{opt f:requency}}directional frequency table of the first
differences{p_end}
{synopt:{opt sum:mary}}overall, within and between dispersion of the partial
sums{p_end}
{synopt:{opt csd}}Pesaran (2015) CD test for cross-sectional dependence{p_end}
{synopt:{opt csdopt(string)}}options passed to {helpb xtcse2} for the exponent
alpha{p_end}
{synopt:{opt cips(# #)}}Pesaran (2007) CIPS panel unit-root test; maximum lags
and Lagrange-multiplier order{p_end}
{synopt:{opt cipsopt(string)}}options passed to {helpb xtcips}{p_end}
{synopt:{opt all}}shorthand for {cmd:frequency summary csd graph}{p_end}

{syntab:Graphics}
{synopt:{opt g:raph}}shorthand for {cmd:grsum grfre grdist}{p_end}
{synopt:{opt grs:um}}accumulated-change paths, cross-panel mean with
interquartile band{p_end}
{synopt:{opt grf:re}}directional composition bar chart{p_end}
{synopt:{opt grd:ist}}distribution of the first differences, split at the
threshold{p_end}
{synopt:{opt sch:eme(name)}}{cmd:parula} (default), {cmd:viridis},
{cmd:journal} or {cmd:mono}{p_end}
{synopt:{opt na:me(stub)}}stub for the names of the graphs in memory{p_end}
{synopt:{opt sav:ing(stub)}}stub for {cmd:.gph} files written to disk{p_end}
{synopt:{opt nod:raw}}build the graphs but do not display them{p_end}
{synopt:{opt com:bine}}also produce a combined figure of everything drawn{p_end}
{synoptline}
{p2colreset}{...}

{phang}You must {helpb xtset} your data, with both a panel and a time variable,
before using {cmd:xtasym}.

{phang}{cmd:xtasym} has no compulsory dependencies. {helpb xtcse2} (from
{bf:xtdcce2}) is used, if it is installed, to add the exponent of
cross-sectional dependence to the {cmd:csd} table. {helpb xtcips} is required
only by the {cmd:cips()} option.


{marker description}{title:Description}

{pstd}
{cmd:xtasym} builds, describes and draws the {it:partial sums} used to model
directional asymmetry with panel data: the idea, going back to Lieberson
(1985), that an increase in x need not have an effect equal and opposite to
that of a decrease in x.

{pstd}
For each variable in {varlist} the command forms the first difference, splits
it into an increase and a decrease around a symmetric dead band of half-width
{cmd:threshold()}, and accumulates each part over time within panel. The two
new series appear as {it:var}{cmd:_p} and {it:var}{cmd:_n}. They are ordinary
variables: put them on the right-hand side of {helpb xtreg}, {helpb xtdcce2},
{helpb clogit} or anything else, and test asymmetry with {helpb test}.

{pstd}
{cmd:xtasym} then reports what you need in order to choose an estimator for
those series — how many changes there actually are in each direction, how much
{it:within} variation the partial sums carry, whether they are cross-sectionally
dependent, and whether they are stationary — and draws them.

{pstd}
The construction follows Shin, Yu and Greenwood-Nimmo (2014) as used by Thombs,
Huang and Fitzgerald (2022), or Allison (2019), at your choice; see
{help xtasym##conventions:Conventions} below and
{helpb xtasym_methods:help xtasym methods} for the algebra.


{marker options}{title:Options}

{dlgtab:Construction}

{phang}{opt threshold(#)} sets the half-width c of a symmetric dead band. A
first difference counts as an increase when it exceeds {cmd:+}c, as a decrease
when it falls below {cmd:-}c, and as no change when it lies in
[{cmd:-}c, {cmd:+}c]. The default {cmd:threshold(0)} reproduces the definitions
in Allison (2019) and Thombs et al. (2022) exactly. Raising c is useful when a
series moves by a trivial amount every period, so that almost nothing is
classified as "no change" and the two arms are nearly collinear.

{phang}{opt convention(rule)} chooses the sign of the negative arm.
{cmd:convention(shin)}, the default, follows Shin, Yu and Greenwood-Nimmo
(2014) and Thombs et al. (2022): the negative partial sum accumulates
min(dx, 0), so it is {it:negative-valued} and the symmetry restriction is
b{c 43} = b{c 45}. {cmd:convention(allison)} follows Allison (2019): the
negative arm accumulates -min(dx, 0), so it is {it:non-negative} and the
symmetry restriction is b{c 43} = -b{c 45}. The header of every run states
which restriction applies. See {help xtasym##conventions:Conventions}.

{phang}{opt prefix(string)} prepends {it:string} to every variable the command
creates. Use it to keep several thresholds or conventions side by side, for
example {cmd:prefix(t5_)}.

{phang}{opt nogenerate} suppresses variable creation and takes {varlist} to be
partial sums that already exist. Use it to run the diagnostic tables on series
you built earlier. It may not be combined with {cmd:threshold()} or {cmd:fdm},
and the {cmd:grsum} graph is skipped.

{phang}{opt fdm} additionally creates {it:var}{cmd:_pfd} and
{it:var}{cmd:_nfd}: the {it:period-by-period} positive and negative components,
not accumulated. These are the regressors of the first-difference method of
York and Light (2017) and Allison (2019, sec. 3), for a model whose dependent
variable is also first differenced. They obey the same {cmd:convention()}.

{phang}{opt replace} allows the command to overwrite variables of the same
name. Without it, an existing name is an error.

{dlgtab:Tables}

{phang}{opt frequency} reports, per variable, how many first differences are
increases, decreases and no-change, with percentages of the changes actually
observed. This is the table that tells you whether an asymmetric model is
identified at all: an arm supported by a handful of movements will not carry a
coefficient.

{phang}{opt summary} reports the mean and the overall, within and between
standard deviations of every partial sum, through {helpb xtsum}. The within
standard deviation is the one that matters: fixed-effects and
common-correlated-effects estimators identify from within variation only.

{phang}{opt csd} reports the Pesaran (2015) CD test for weak cross-sectional
dependence of each partial sum, together with the mean and mean absolute
pairwise correlation. The statistic is computed internally, so no other package
is needed. If {helpb xtcse2} is installed, the exponent of cross-sectional
dependence alpha (Bailey, Kapetanios and Pesaran 2016) is added to the table;
{cmd:csdopt()} passes options through to it.

{phang}{opt cips(# #)} reports the Pesaran (2007) CIPS panel unit-root test,
robust to cross-sectional dependence, for each partial sum. The first integer
is the maximum lag order, the second the autocorrelation order of the Lagrange
multiplier test. This option is a wrapper for {helpb xtcips}, which must be
installed; {cmd:cipsopt()} passes options through to it.

{phang}{opt all} is shorthand for {cmd:frequency summary csd graph}.

{dlgtab:Graphics}

{phang}{opt grsum} draws, for each variable, the cross-panel mean of the two
partial sums against time, with the interquartile range across panels shaded.
Unlike a per-panel line plot this stays readable with many panels: it is the
picture of accumulated directional change.

{phang}{opt grfre} draws a single horizontal stacked bar per variable giving
the share of increases, no-change and decreases.

{phang}{opt grdist} draws, for each variable, the distribution of the first
differences with increases and decreases shaded separately. Both halves share
one bin grid and are plotted as counts, so the two sides are directly
comparable; the dead band, when one is set, is marked by dashed vertical lines
at {cmd:-}c and {cmd:+}c.

{phang}{opt scheme(name)} selects the colour ramp. {cmd:parula} (default)
reproduces the MATLAB R2014b Parula ramp; {cmd:viridis} is the matplotlib
ramp; {cmd:journal} is the Okabe-Ito colour-blind-safe set; {cmd:mono} is
greyscale for print. Increases always take the warm end of the ramp and
decreases the cool end.

{phang}{opt name(stub)}, {opt saving(stub)}, {opt nodraw} and {opt combine}
control where the graphs go. Names are formed as {it:stub}{cmd:_composition},
{it:stub}{cmd:_dist_}{it:var} and {it:stub}{cmd:_path_}{it:var}; the default
stub is {cmd:xtasym}.


{marker conventions}{title:Conventions}

{pstd}
Two sign conventions circulate in this literature and they are easy to confuse.
Write dx for the first difference of x.

{p2colset 8 34 36 2}{...}
{p2col :{bf:Shin et al. (2014)}}x{c 43} = sum of max(dx, 0){p_end}
{p2col :}x{c 45} = sum of min(dx, 0){space 5}(negative-valued){p_end}
{p2col :}symmetry: b{c 43} = b{c 45}{p_end}
{p2col :}{it:used by Thombs, Huang and Fitzgerald (2022) and by} {bf:xtasysum}{p_end}
{p2col :}{p_end}
{p2col :{bf:Allison (2019)}}Z{c 43} = sum of max(dx, 0){p_end}
{p2col :}Z{c 45} = sum of -min(dx, 0){space 2}(non-negative){p_end}
{p2col :}symmetry: b{c 43} = -b{c 45}{p_end}
{p2colreset}{...}

{pstd}
The two are the same object with a flipped sign on one arm: x{c 45} =
-Z{c 45}. The coefficients therefore also differ by a sign, and so does the
restriction you must test. Getting this wrong reverses the sign of the reported
"effect of a decrease" and tests the wrong hypothesis. {cmd:xtasym} prints the
applicable restriction in its header on every run.

{pstd}
Note that under the Shin convention a {it:positive} coefficient on x{c 45}
means that a decrease in x lowers y. This is the reading behind the note to
Table 5 of Thombs et al. (2022).


{marker output}{title:Interpreting the output}

{pstd}
{bf:Header.} Confirms the panel and time variables, the number of panels and
observations entering the calculation, the threshold, the convention, and the
symmetry restriction implied by that convention.

{pstd}
{bf:Directional decomposition.} Counts are of first differences, so the first
period of every panel and any gap in the time variable contribute nothing. If
one arm has very few movements, its coefficient will be imprecise however you
estimate it; Thombs et al. (2022, note 10) suggest a non-zero threshold when
within variation is scarce.

{pstd}
{bf:Summary statistics.} A partial sum with a large between and a tiny within
standard deviation is nearly a fixed effect and will be absorbed by the panel
dummies.

{pstd}
{bf:CD table.} CD is standard normal under the null of weak cross-sectional
dependence. Rejection, especially with a large mean absolute correlation, is
the case for a common-correlated-effects estimator instead of two-way fixed
effects. Pairs of panels with fewer than three overlapping periods are dropped
from the average, and the count of usable pairs is reported when alpha is not
available.

{pstd}
{bf:CIPS table.} The test is left-tailed: a statistic more negative than the
critical value rejects the null of a homogeneous unit root. Partial sums of a
non-stationary series are themselves typically non-stationary, which is
expected rather than alarming; it is one reason Thombs et al. (2022) work with
an autoregressive distributed lag specification.


{marker model}{title:Using the partial sums in a model}

{pstd}
{cmd:xtasym} builds and describes the regressors; the model is yours. The
specifications compared by Thombs et al. (2022) are, in the notation of the
variables this command creates:

{pstd}
{bf:1. Static fixed effects} (York and Light 2017; Allison 2019). Biased when
the process is autoregressive, which it usually is with large T:

{phang2}{cmd:. xtasym lngdp}{p_end}
{phang2}{cmd:. xtreg lco2 lngdp_p lngdp_n i.year, fe cluster(id)}{p_end}
{phang2}{cmd:. test lngdp_p = lngdp_n}{p_end}

{pstd}
{bf:2. Dynamic fixed effects in ARDL form} (their eq. 18). Consistent
short-run effects, but unstable long-run effects under slope heterogeneity:

{phang2}{cmd:. xtreg lco2 L.lco2 lngdp_p lngdp_n L.lngdp_p L.lngdp_n i.year, fe cluster(id)}{p_end}
{phang2}{cmd:. nlcom (lr_p: (_b[lngdp_p]+_b[L.lngdp_p])/(1-_b[L.lco2]))}{p_end}

{pstd}
{bf:3. Mean group or common correlated effects} (their eq. 19), through
{helpb xtdcce2}, when the slope-heterogeneity and CD pre-tests reject:

{phang2}{cmd:. xtdcce2 lco2 lngdp_p lngdp_n, lr(L.lco2 L.lngdp_p L.lngdp_n) lr_options(ardl) crosssectional(lco2) cr_lags(3)}{p_end}

{pstd}
{bf:4. Asymmetric conditional logit} (Allison 2019, sec. 7) for a binary
outcome, which requires the Allison convention:

{phang2}{cmd:. xtasym spouse hours, convention(allison)}{p_end}
{phang2}{cmd:. clogit pov mother spouse_p spouse_n hours_p hours_n i.year, group(id) robust}{p_end}
{phang2}{cmd:. test spouse_p = -spouse_n}{p_end}

{pstd}
Note the restriction changes with the convention. Test slope heterogeneity with
{helpb xthst} before settling on 2 versus 3.


{marker remarks}{title:Remarks and practical guidance}

{phang}o Partial sums are accumulated within panel in time order and are set to
missing outside the estimation sample and wherever the source variable is
missing. A gap in the time variable produces no first difference for that
period, so nothing is accumulated across the gap.

{phang}o With {cmd:threshold()} greater than zero, changes inside the dead band
contribute nothing to either arm. The contribution of a change outside the band
is the {it:whole} first difference, not the excess over c, which is the
definition used in this literature.

{phang}o The command never changes the sort order of your data on exit and
never touches {cmd:e()}.

{phang}o With few panels or a short T the CD statistic is unreliable; Pesaran
(2015) is a large-N result.

{phang}o Comparability with {bf:xtasysum} (Thombs 2022): with
{cmd:threshold(0)} and the default convention, {cmd:xtasym} produces the same
{cmd:_p} and {cmd:_n} series as {cmd:xtasysum}, and {cmd:fdm} produces the same
{cmd:_pfd} and {cmd:_nfd} series. The results differ only when a non-zero
threshold is used: {cmd:xtasym} applies the threshold symmetrically as a dead
band, so that a small positive change is never counted as a decrease.


{marker results}{title:Stored results}

{pstd}{cmd:xtasym} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(threshold)}}the dead-band half-width c{p_end}
{synopt:{cmd:r(k)}}number of variables in {varlist}{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(varlist)}}the variables supplied{p_end}
{synopt:{cmd:r(partialsums)}}the partial sums created or used{p_end}
{synopt:{cmd:r(fdmvars)}}the first-difference-method components created{p_end}
{synopt:{cmd:r(convention)}}{cmd:shin} or {cmd:allison}{p_end}
{synopt:{cmd:r(panelvar)}}the panel variable{p_end}
{synopt:{cmd:r(timevar)}}the time variable{p_end}
{synopt:{cmd:r(graphs)}}names of the graphs produced{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(frequency)}}counts and percentages by direction, one row per
variable{p_end}
{synopt:{cmd:r(summary)}}mean and overall, within, between dispersion of each
partial sum{p_end}
{synopt:{cmd:r(csd)}}CD, p-value, mean rho, mean |rho|, alpha, pairs, n,
T-bar{p_end}
{synopt:{cmd:r(cips)}}CIPS statistic, critical values and the stationarity
verdict{p_end}
{p2colreset}{...}


{marker examples}{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Create the partial sums of {cmd:mvalue}{p_end}
{phang2}{cmd:. xtasym mvalue}{p_end}

{pstd}Everything at once, with graphs{p_end}
{phang2}{cmd:. xtasym mvalue kstock, all}{p_end}

{pstd}A dead band, so that trivial movements are not counted as changes{p_end}
{phang2}{cmd:. xtasym mvalue, threshold(50) frequency prefix(b_) }{p_end}

{pstd}Allison's convention, for a model in first differences or a
{helpb clogit}{p_end}
{phang2}{cmd:. xtasym mvalue, convention(allison) fdm replace}{p_end}

{pstd}Diagnostics only, on partial sums that already exist{p_end}
{phang2}{cmd:. xtasym mvalue_p mvalue_n, nogenerate summary csd}{p_end}

{pstd}A publication figure in colour-blind-safe colours, saved to disk{p_end}
{phang2}{cmd:. xtasym mvalue kstock, graph scheme(journal) saving(fig1) combine nodraw}{p_end}

{pstd}Use them{p_end}
{phang2}{cmd:. xtasym mvalue, replace}{p_end}
{phang2}{cmd:. xtreg invest mvalue_p mvalue_n kstock i.year, fe cluster(company)}{p_end}
{phang2}{cmd:. test mvalue_p = mvalue_n}{p_end}

{pstd}A complete worked run on simulated data with a known asymmetry is in
{cmd:xtasym_example.do}, retrieved with {cmd:net get xtasym}.


{marker references}{title:References}

{p 4 8 2}Allison, Paul D. 2019. "Asymmetric Fixed-Effects Models for Panel
Data." {it:Socius} 5: 1-12.

{p 4 8 2}Bailey, Natalia, George Kapetanios, and M. Hashem Pesaran. 2016.
"Exponent of Cross-Sectional Dependence: Estimation and Inference."
{it:Journal of Applied Econometrics} 31: 929-960.

{p 4 8 2}Burdisso, Tamara, and Maximo Sangiacomo. 2016. "Panel Time Series:
Review of the Methodological Evolution." {it:The Stata Journal} 16(2): 424-442.

{p 4 8 2}Chudik, Alexander, and M. Hashem Pesaran. 2015. "Common Correlated
Effects Estimation of Heterogeneous Dynamic Panel Data Models with Weakly
Exogenous Regressors." {it:Journal of Econometrics} 188(2): 393-420.

{p 4 8 2}Ditzen, Jan. 2021. "Estimating Long-Run Effects and the Exponent of
Cross-Sectional Dependence: An Update to xtdcce2." {it:The Stata Journal}
21(3): 687-707.

{p 4 8 2}Lieberson, Stanley. 1985. {it:Making It Count: The Improvement of
Social Research and Theory.} Berkeley: University of California Press.

{p 4 8 2}Pesaran, M. Hashem. 2006. "Estimation and Inference in Large
Heterogeneous Panels with a Multifactor Error Structure." {it:Econometrica}
74(4): 967-1012.

{p 4 8 2}Pesaran, M. Hashem. 2007. "A Simple Panel Unit Root Test in the
Presence of Cross-Section Dependence." {it:Journal of Applied Econometrics}
22(2): 265-312.

{p 4 8 2}Pesaran, M. Hashem. 2015. "Testing Weak Cross-Sectional Dependence in
Large Panels." {it:Econometric Reviews} 34(6-10): 1089-1117.

{p 4 8 2}Pesaran, M. Hashem, and Ron Smith. 1995. "Estimating Long-Run
Relationships from Dynamic Heterogeneous Panels." {it:Journal of Econometrics}
68(1): 79-113.

{p 4 8 2}Shin, Yongcheol, Byungchul Yu, and Matthew Greenwood-Nimmo. 2014.
"Modelling Asymmetric Cointegration and Dynamic Multipliers in a Nonlinear ARDL
Framework." Pp. 281-314 in {it:Festschrift in Honor of Peter Schmidt}, edited
by R. Sickles and W. C. Horrace. New York: Springer.

{p 4 8 2}Thombs, Ryan P., Xiaorui Huang, and Jared B. Fitzgerald. 2022. "What
Goes Up Might Not Come Down: Modeling Directional Asymmetry with Large-N,
Large-T Data." {it:Sociological Methodology} 52(1): 1-29.

{p 4 8 2}York, Richard, and Ryan Light. 2017. "Directional Asymmetry in
Sociological Analyses." {it:Socius} 3: 1-13.


{marker author}{title:Author}

{pstd}Dr Merwan Roudane{p_end}
{pstd}Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{pstd}GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}


{title:Also see}

{psee}Manual: {helpb xtset}, {helpb xtsum}, {helpb xtreg}{p_end}
{psee}Help: {helpb xtasym_methods:xtasym methods}{p_end}
{psee}If installed: {helpb xtdcce2}, {helpb xtcse2}, {helpb xtcips},
{helpb xthst}{p_end}
