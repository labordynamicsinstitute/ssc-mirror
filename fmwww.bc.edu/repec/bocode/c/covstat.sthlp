{smcl}
{* 23jul2026}{...}
{vieweralsosee "covstat methods" "help covstat_methods"}{...}
{vieweralsosee "flexur (library)" "help flexur"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "icss" "help icss"}{...}
{vieweralsosee "tsset" "help tsset"}{...}
{viewerjumpto "Syntax" "covstat##syntax"}{...}
{viewerjumpto "Description" "covstat##description"}{...}
{viewerjumpto "Options" "covstat##options"}{...}
{viewerjumpto "Examples" "covstat##examples"}{...}
{viewerjumpto "Stored results" "covstat##results"}{...}
{viewerjumpto "Interpreting the output" "covstat##interpret"}{...}
{viewerjumpto "Remarks" "covstat##remarks"}{...}
{viewerjumpto "References" "covstat##refs"}{...}
{title:Title}

{phang}
{bf:covstat} {hline 2} Jansson-RALS covariate stationarity test: more powerful
stationarity tests with non-normal errors (Nazlioglu, Lee, Karul & You, 2021)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:covstat} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt mod:el(string)}}deterministic terms: {cmd:constant} or {cmd:trend}
(default){p_end}
{synopt:{opt iid}}i.i.d. long-run variance instead of the default VAR(1)-prewhitened
QS-kernel estimator{p_end}

{syntab:Plot}
{synopt:{opt g:raph}}plot the statistics against their {it:signal-to-noise}
critical-value curves{p_end}
{synopt:{opt gname(name)}}name of the graph{p_end}
{synopt:{opt graphopts(str)}}additional {help twoway} options{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}The time dimension is read from {helpb tsset} when set.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:covstat} tests the null hypothesis that a series is (trend-)stationary
against a unit-root alternative, using the stationarity tests of Jansson (2004)
{it:augmented with RALS covariates}. The key idea of Nazlioglu, Lee, Karul and
You (2021) is that, under non-normal errors, the {bf:residual-augmented least
squares} (RALS) terms

{p 12 12 2}{it:w{sub:t} = [ e{sub:t}{sup:2} - m{sub:2} ,  e{sub:t}{sup:3} - m{sub:3} - 3 m{sub:2} e{sub:t} ]}{p_end}

{pstd}
(built from the OLS residuals of the testing regression) are valid {it:stationary
covariates}: correlated with the error but not with the regressors. Adding them to
the Jansson framework yields substantially more powerful stationarity tests, and
{bf:no external covariate has to be found}.

{pstd}
The command reports four statistics:

{p 8 12 2}{bf:Ly_T}, {bf:Qy_T} {hline 1} the {it:benchmark} Jansson locally-optimal
and point-optimal statistics {it:without} covariates. Ly_T equals the KPSS test of
Kwiatkowski et al. (1992).{p_end}
{p 8 12 2}{bf:L_T}, {bf:Q_T} {hline 1} the {it:Jansson-RALS} locally-optimal and
point-optimal statistics {it:with} the RALS covariates.{p_end}

{pstd}
Because the distribution of the covariate tests depends on the signal-to-noise
ratio {it:rho^2}, p-values are obtained from the response-surface functions of the
paper (shipped in {cmd:jrals_rs.txt}). The long-run covariance is estimated, by
default, with a VAR(1)-prewhitened quadratic-spectral kernel and the Jansson (2004,
p.74) plug-in bandwidth. See {helpb covstat_methods:help covstat methods}.

{pstd}
{cmd:covstat} is part of the {helpb flexur:flexur} library.

{marker options}{...}
{title:Options}

{phang}
{opt model(string)} sets the deterministic component: {cmd:constant} (level
stationarity, X{sub:t}=1) or {cmd:trend} (trend stationarity, X{sub:t}=[1,t]; the
default and the specification used in the paper's application).

{phang}
{opt iid} estimates the long-run (co)variance under serial independence. By default
{cmd:covstat} uses the VAR(1)-prewhitened quadratic-spectral kernel estimator with
an automatic plug-in bandwidth, matching the paper.

{phang}
{opt graph}, {opt gname(name)}, {opt graphopts(string)} draw and name a diagnostic
plot of the L_T and Q_T 5% critical-value curves as functions of rho^2, with the
estimated rho^2 marked.

{marker examples}{...}
{title:Examples}

{pstd}Trend-stationarity test with RALS covariates (recommended):{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. covstat lgnp, model(trend)}{p_end}

{pstd}Level stationarity, i.i.d. long-run variance:{p_end}
{phang2}{cmd:. covstat lgnp, model(constant) iid}{p_end}

{pstd}With the signal-to-noise diagnostic plot:{p_end}
{phang2}{cmd:. covstat lcpi, model(trend) graph}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:covstat} is {cmd:rclass} and stores:{p_end}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(Ly_T)}, {cmd:r(Ly_p)}}benchmark locally-optimal statistic (= KPSS) and p-value{p_end}
{synopt:{cmd:r(Qy_T)}, {cmd:r(Qy_p)}}benchmark point-optimal statistic and p-value{p_end}
{synopt:{cmd:r(L_T)}, {cmd:r(L_p)}}Jansson-RALS locally-optimal statistic and p-value{p_end}
{synopt:{cmd:r(Q_T)}, {cmd:r(Q_p)}}Jansson-RALS point-optimal statistic and p-value{p_end}
{synopt:{cmd:r(rho2)}}estimated signal-to-noise ratio{p_end}
{synopt:{cmd:r(T)}}number of usable observations{p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:covstat}{p_end}
{synopt:{cmd:r(model)}}deterministic model{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
All four statistics {bf:reject stationarity for large values / small p-values}.
Ly_T and Qy_T ignore the RALS information; L_T and Q_T exploit it.

{pstd}
{bf:The signal-to-noise ratio rho^2} measures how much the RALS covariates explain.
Under {it:normal} errors rho^2 is near 0 and the covariate tests collapse to their
benchmark counterparts (Ly_T then equals KPSS). A {it:large} rho^2 (say > 0.8)
signals strong non-normality: the RALS terms carry real information and the L_T /
Q_T tests can be far more powerful than KPSS. In the Nelson-Plosser application,
KPSS (Ly_T) rejects nothing, whereas the Jansson-RALS tests reject stationarity for
many series.

{marker remarks}{...}
{title:Remarks and practical guidance}

{phang}o Use {cmd:model(trend)} for the usual macro series; {cmd:model(constant)}
for level-stationarity questions.{p_end}

{phang}o The default (VAR(1)-prewhitened QS kernel) reproduces the paper. Use
{cmd:iid} only when the errors are known to be serially uncorrelated.{p_end}

{phang}o rho^2 is capped at 0.9 for the response-surface interpolation, as in the
original code; p-values are floored at 0.0001 and reported as approximate.{p_end}

{phang}o At least ~20 observations are required; the covariate machinery needs a
non-degenerate empirical third/fourth moment (i.e. genuinely non-normal errors) to
gain power.{p_end}

{marker refs}{...}
{title:References}

{phang}Im, K. S., and P. Schmidt. 2008. More efficient estimation under
non-normality: residuals augmented least squares. {it:Journal of Econometrics}
144: 219-233.{p_end}

{phang}Jansson, M. 2004. Stationarity testing with covariates. {it:Econometric
Theory} 20: 56-94.{p_end}

{phang}Kwiatkowski, D., P. C. B. Phillips, P. Schmidt, and Y. Shin. 1992. Testing
the null hypothesis of stationarity against the alternative of a unit root.
{it:Journal of Econometrics} 54: 159-178.{p_end}

{phang}Nazlioglu, S., J. Lee, C. Karul, and Y. You. 2021. Testing for stationarity
with covariates: more powerful tests with non-normal errors. {it:Studies in
Nonlinear Dynamics & Econometrics}.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS routine {cmd:appl_JanssonRALS.gss} by
S. Nazlioglu, J. Lee, C. Karul and Y. You; validated against Table 9 of the paper.
Part of the {helpb flexur:flexur} library.{p_end}
