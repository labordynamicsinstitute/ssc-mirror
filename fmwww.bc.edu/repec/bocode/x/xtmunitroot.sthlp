{smcl}
{* *! xtmunitroot version 1.0.0  27jun2026}{...}
{vieweralsosee "xtgunitroot" "help xtgunitroot"}{...}
{vieweralsosee "xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtmunitroot##syntax"}{...}
{viewerjumpto "Description" "xtmunitroot##description"}{...}
{viewerjumpto "Options" "xtmunitroot##options"}{...}
{viewerjumpto "Methods" "xtmunitroot##methods"}{...}
{viewerjumpto "Related command" "xtmunitroot##related"}{...}
{viewerjumpto "Stored results" "xtmunitroot##results"}{...}
{viewerjumpto "Examples" "xtmunitroot##examples"}{...}
{viewerjumpto "References" "xtmunitroot##references"}{...}
{viewerjumpto "Author" "xtmunitroot##author"}{...}
{title:Title}

{phang}
{bf:xtmunitroot} {hline 2} Fixed-T panel unit root tests with missing values

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtmunitroot}
{varname}
{ifin}
[{cmd:,}
{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(spec)}}deterministic specification: {opt intercept} (default),
{opt trend}, {opt break} or {opt breaktrend}{p_end}
{synopt:{opt br:eak(#)}}break point for {opt break}/{opt breaktrend}: a calendar
date, a fraction in (0,1), or {opt unknown}{p_end}

{syntab:Missing values}
{synopt:{opt meth:od(m)}}{opt zeroout} (default), {opt previous}, {opt linear} or
{opt all}{p_end}

{syntab:Unknown-break bootstrap}
{synopt:{opt brep:s(#)}}bootstrap replications for {opt break(unknown)}; default 399{p_end}
{synopt:{opt tr:im(#)}}end trimming fraction for the break-date search; default 0.15{p_end}
{synopt:{opt seed(#)}}RNG seed for the bootstrap{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}significance level for the decision; default {cmd:level(95)}{p_end}
{synopt:{opt graph}}draw the missing-value map and method-comparison dashboard{p_end}
{synopt:{opt name(str)}}stub for the graph names; default {cmd:xtmunitroot}{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb xtset}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtmunitroot} implements the fixed-T panel unit root tests of
{help xtmunitroot##HT1999:Harris and Tzavalis (1999)} and
{help xtmunitroot##KT2014:Karavias and Tzavalis (2014)}, extended to
{it:unbalanced} panels with missing values exactly as in
{help xtmunitroot##KTZ2022:Karavias, Tzavalis and Zhang (2022)}. These tests are
designed for panels with a large number of cross-section units {it:N} and a
small, fixed number of time periods {it:T}.

{pstd}
The model is an AR(1) panel, u(i,t) = rho*u(i,t-1) + e(i,t), and the test is

{p 8 8 2}H0: rho = 1  (every panel has a unit root)   vs   H1: rho < 1  (stationary).{p_end}

{pstd}
The pooled fixed-effects estimator of rho is inconsistent for fixed {it:T} (the
Hurwicz-Nickell bias), so it is bias-corrected and the resulting statistic is
asymptotically standard normal as N -> infinity:

{p 8 8 2}z = (rho_hat - bias - 1) / sqrt(V/N)  ->  N(0,1)   under H0.{p_end}

{pstd}
Because rho_hat is biased {it:downward}, the bias is negative; under stationarity
z is large and negative, so the unit-root null is rejected in the lower tail.

{pstd}
Missing values make the panel unbalanced and contaminate the bias correction,
which depends on the {it:location} of the gaps. {cmd:xtmunitroot} builds, for
every unit, the reshuffling matrix D(i) of
{help xtmunitroot##KTZ2022:Karavias, Tzavalis and Zhang (2022)} and applies the
unbalanced bias and variance corrections (their Propositions 1-2). The four
deterministic specifications correspond to models (1)-(4) of that paper:

{p2colset 8 26 28 2}{...}
{p2col:{opt intercept}}individual (incidental) intercepts{p_end}
{p2col:{opt trend}}individual intercepts and individual linear trends{p_end}
{p2col:{opt break}}individual intercepts with a common structural break at {opt break()}{p_end}
{p2col:{opt breaktrend}}intercepts and trends with a common structural break at {opt break()}{p_end}

{marker options}{...}
{title:Options}

{phang}{opt model(spec)} sets the deterministic component. Abbreviations
{cmd:i}, {cmd:t}, {cmd:b}, {cmd:bt} are accepted.

{phang}{opt break(#)} is required for {opt break} and {opt breaktrend}. A value
in (0,1) is read as a break {it:fraction} of the time grid; any other value is
read as a calendar {it:date} on the time variable. {opt break(unknown)} searches
all admissible break dates: the test statistic is the minimum (inf) of the t over
the candidate dates, and the p-value and critical values come from a cross-section
residual bootstrap that imposes the unit-root null (Karavias & Tzavalis 2019).
Only one {opt method()} may be used with {opt break(unknown)}.

{phang}{opt breps(#)}, {opt trim(#)}, {opt seed(#)} control the unknown-break
bootstrap: number of replications, the fraction trimmed from each end of the
break-date search, and the RNG seed for reproducibility.

{phang}{opt method(m)} chooses how missing values are handled:

{pmore}{opt zeroout} (default, {bf:recommended}) -- "closing the gaps". Every
equation that involves a missing value is dropped, and the {it:exact} unbalanced
bias/variance correction is applied. This is the method
{help xtmunitroot##KTZ2022:Karavias, Tzavalis and Zhang (2022)} prove delivers
the {it:greatest} power, for all deterministic specifications.

{pmore}{opt previous} -- the missing value is replaced by the last observed value
(carry-forward), then the test is computed on the completed series.

{pmore}{opt linear} -- the missing value is replaced by linear interpolation of
the two adjacent observed values, then the test is computed on the completed
series.

{pmore}{opt all} -- reports all three in one comparison table (and dashboard).

{phang}{opt level(#)} significance level used only for the printed decision.

{phang}{opt graph} produces a two-panel dashboard: (a) a missing-value map of the
panel and (b) a bar chart of the z-statistic by method with the 5% critical line.
If the user-contributed {helpb heatplot} is installed it is used for the map;
otherwise a scatter fallback is drawn.

{marker methods}{...}
{title:A note on the three methods}

{pstd}
The {opt zeroout} method is the full, exact implementation of
{help xtmunitroot##KTZ2022:Karavias, Tzavalis and Zhang (2022)}: the diagonal
D(i) drops the two equations contaminated by each gap and the bias correction is
computed from D(i). The {opt previous} and {opt linear} methods are implemented as
{it:impute-then-test}: the series is completed first and the standard fixed-T
correction is then applied. They are provided so the user can reproduce, on real
data, the {it:power ranking} reported in the paper -- namely that zeroing-out
dominates and substituting the previous value is generally worst. Report
{opt zeroout} as the primary result.

{marker related}{...}
{title:Related command}

{pstd}
{cmd:xtmunitroot} assumes i.i.d. errors and is built for {it:missing values}
(unbalanced panels). When the errors are instead {it:serially correlated} or
{it:heteroscedastic} and the panel is balanced, use its companion
{helpb xtgunitroot} (the generalized DME test of Karavias & Tzavalis 2019), which
shares the same {opt break(unknown)} inf-t bootstrap interface.

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtmunitroot} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(rho)}}bias-corrected rho (single-method runs){p_end}
{synopt:{cmd:r(bias)}}estimated bias correction (single-method runs){p_end}
{synopt:{cmd:r(z)}}test statistic (single-method runs){p_end}
{synopt:{cmd:r(p)}}one-sided p-value (single-method runs){p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}number of equations on the time grid{p_end}
{synopt:{cmd:r(N_used)}}panels contributing to the statistic{p_end}
{synopt:{cmd:r(N_drop)}}panels dropped (too few usable equations){p_end}
{synopt:{cmd:r(n_miss)}}missing cells on the rectangular grid{p_end}
{synopt:{cmd:r(kbreak)}}break equation index (break models){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtmunitroot}{p_end}
{synopt:{cmd:r(depvar)}}series tested{p_end}
{synopt:{cmd:r(ivar)} / {cmd:r(tvar)}}panel and time variables{p_end}
{synopt:{cmd:r(model)} / {cmd:r(method)}}chosen specification / method{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}3 x 8 matrix, one row per method (zeroout, previous,
linear): rho, bias, z, p, N_used, N_drop, n_miss, T_eq{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Setup a panel and introduce some gaps:{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. replace invest = . if mod(_n,17)==0}{p_end}

{pstd}Default test (zeroing-out, individual intercepts):{p_end}
{phang2}{cmd:. xtmunitroot invest}{p_end}

{pstd}Individual trends:{p_end}
{phang2}{cmd:. xtmunitroot invest, model(trend)}{p_end}

{pstd}Structural break at the middle of the sample, with the dashboard:{p_end}
{phang2}{cmd:. xtmunitroot invest, model(break) break(0.5) graph}{p_end}

{pstd}Compare all three missing-value methods:{p_end}
{phang2}{cmd:. xtmunitroot invest, method(all) graph}{p_end}

{pstd}Structural break at an unknown date (inf-t with bootstrap p-value):{p_end}
{phang2}{cmd:. xtmunitroot invest, model(break) break(unknown) breps(499) seed(42) graph}{p_end}

{marker references}{...}
{title:References}

{marker KTZ2022}{...}
{phang}Karavias, Y., E. Tzavalis, and H. Zhang. 2022. Missing values in panel
data unit root tests. {it:Econometrics} 10(1): 12.
{browse "https://doi.org/10.3390/econometrics10010012":doi:10.3390/econometrics10010012}.

{marker HT1999}{...}
{phang}Harris, R. D. F., and E. Tzavalis. 1999. Inference for unit roots in
dynamic panels where the time dimension is fixed. {it:Journal of Econometrics}
91: 201-226.
{browse "https://doi.org/10.1016/S0304-4076(98)00076-1":doi:10.1016/S0304-4076(98)00076-1}.

{marker KT2014}{...}
{phang}Karavias, Y., and E. Tzavalis. 2014. Testing for unit roots in short
panels allowing for a structural break. {it:Computational Statistics & Data
Analysis} 76: 391-407.
{browse "https://doi.org/10.1016/j.csda.2012.10.014":doi:10.1016/j.csda.2012.10.014}.

{marker KT2019}{...}
{phang}Karavias, Y., and E. Tzavalis. 2019. Generalized fixed-T panel unit root
tests. {it:Scandinavian Journal of Statistics} 46(4): 1227-1251.
{browse "https://doi.org/10.1111/sjos.12392":doi:10.1111/sjos.12392}.

{marker author}{...}
{title:Author}

{pstd}Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
