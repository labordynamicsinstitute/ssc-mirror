{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtbreaklm methods" "help xtbreaklm_methods"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtpstat" "help xtpstat"}{...}
{vieweralsosee "xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtbreaklm##syntax"}{...}
{viewerjumpto "Description" "xtbreaklm##description"}{...}
{viewerjumpto "Options" "xtbreaklm##options"}{...}
{viewerjumpto "Examples" "xtbreaklm##examples"}{...}
{viewerjumpto "Stored results" "xtbreaklm##results"}{...}
{viewerjumpto "Interpreting the output" "xtbreaklm##interpret"}{...}
{viewerjumpto "References" "xtbreaklm##refs"}{...}
{title:Title}

{phang}
{bf:xtbreaklm} {hline 2} Panel Lagrange-multiplier (LM) unit-root tests that
allow for structural breaks: Enders-Lee flexible-Fourier (smooth breaks) and
Lee-Tieslau two-break (sharp breaks)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtbreaklm} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}The data must be {helpb xtset} as a {bf:strongly balanced} panel.{p_end}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt t:ype(string)}}{cmd:fourier} (Enders-Lee smooth breaks, the
default) or {cmd:sharp} (Lee-Tieslau two breaks){p_end}
{synopt:{opt nh:arm(#)}}cumulative Fourier frequency for {cmd:type(fourier)}
(0-3; default 1){p_end}
{synopt:{opt p:max(#)}}maximum number of augmentation lags (default 8){p_end}
{synopt:{opt ic(#)}}lag-selection rule: 1=AIC, 2=BIC, 3=general-to-specific
t-stat (default 3){p_end}
{synopt:{opt m:odel(string)}}deterministic terms; {cmd:trend} (default). Both
tests are trend-based{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtbreaklm} implements two panel LM unit-root tests that remain valid in the
presence of structural breaks {it:without} pre-testing for the break form. The
null hypothesis is a unit root in every panel; the alternative is that at least
one panel is (trend-)stationary around its break process.

{pstd}
{opt type(fourier)} is the Enders-Lee flexible-Fourier panel LM test. Each unit's
trend is augmented with {it:nharm} cumulative sine/cosine terms, which approximate
an unknown number of {it:smooth} (gradual) breaks; unit-specific LM-tau statistics
are converted to p-values with the paper's response surface and pooled into the
Fisher {bf:P}, standardized {bf:Pm} and inverse-normal {bf:Choi Z} panel
statistics.

{pstd}
{opt type(sharp)} is the Lee-Tieslau panel LM test with {it:two} sharp breaks in
level and trend. Each unit's two break dates are selected by grid search
(minimizing the LM-tau statistic); the group-mean statistic is standardized with
tabulated moments to give the {bf:Panel LM} (IPS-type) statistic.

{pstd}
Both tests are single-series LM tests pooled across the panel; they do {it:not}
remove common factors (use {helpb xtpstat} or {helpb xtfpanic} for
cross-sectional-dependence-robust tests). {cmd:xtbreaklm} is part of the
{helpb xtpdroot:xtpdroot} library. See
{helpb xtbreaklm_methods:help xtbreaklm methods} for the formulas.

{marker options}{...}
{title:Options}

{phang}{opt type(string)}: {cmd:fourier} (Enders-Lee, default) selects the smooth
Fourier LM test; {cmd:sharp} (Lee-Tieslau) selects the two-break LM test.

{phang}{opt nharm(#)}: the maximum cumulative Fourier frequency {it:k}=1..{it:#}
(only for {cmd:type(fourier)}). {cmd:nharm(1)} is the single-frequency form
recommended by Enders-Lee; {cmd:nharm(2)} adds the second harmonic.

{phang}{opt pmax(#)}: the maximum number of lagged differences in the LM
regression. The Nazlioglu et al. (2023) replication used {cmd:pmax(3)}; the
general-to-specific rule then trims from {it:#} downward.

{phang}{opt ic(#)}: {cmd:1} AIC, {cmd:2} BIC, or {cmd:3} (default) the
general-to-specific significance rule of Hall (1994) with a 10% (t=1.645)
threshold, exactly as in the source GAUSS code.

{phang}{opt model(string)}: kept for interface symmetry; both tests are estimated
with a broken linear trend ({cmd:trend}).

{marker examples}{...}
{title:Examples}

{pstd}Enders-Lee smooth-break panel LM (single frequency):{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtbreaklm y, type(fourier) nharm(1) pmax(3)}{p_end}

{pstd}Add the second harmonic:{p_end}
{phang2}{cmd:. xtbreaklm y, type(fourier) nharm(2) pmax(3)}{p_end}

{pstd}Lee-Tieslau two-break panel LM (per-unit break dates reported):{p_end}
{phang2}{cmd:. xtbreaklm y, type(sharp) pmax(3)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtbreaklm} is {cmd:rclass}. For {cmd:type(fourier)} it stores:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(P)}, {cmd:r(P_p)}}Fisher chi-square panel statistic and p-value{p_end}
{synopt:{cmd:r(Pm)}, {cmd:r(Pm_p)}}standardized panel statistic and p-value{p_end}
{synopt:{cmd:r(Choi)}, {cmd:r(Choi_p)}}inverse-normal (Choi Z) statistic and p-value{p_end}
{synopt:{cmd:r(nreject)}}number of units rejecting at 5%{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel and time dimensions{p_end}

{pstd}For {cmd:type(sharp)} it stores {cmd:r(PanelLM)} and {cmd:r(PanelLM_p)}
(the standardized group-mean statistic and its p-value) plus {cmd:r(N)},
{cmd:r(T)}.{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtbreaklm}{p_end}
{synopt:{cmd:r(type)}}{cmd:fourier} or {cmd:sharp}{p_end}
{synopt:{cmd:r(model)}}{cmd:trend}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(units)}}per-unit results: {cmd:fourier} = {it:id}, LM-tau,
p-value, lags, cv(10/5/1%); {cmd:sharp} = {it:id}, LM, break1, break2, lags{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
The null is a unit root in all panels. For {cmd:type(fourier)}, {bf:P} and
{bf:Pm} {bf:reject for large values} and {bf:Choi Z} for very {it:negative}
values, in favour of stationarity in at least one panel. For {cmd:type(sharp)},
the {bf:Panel LM} statistic rejects for very {it:negative} values. The reported
break columns are the estimated break {it:periods} (in the units of your time
variable), not indices.

{marker refs}{...}
{title:References}

{phang}Enders, W., and J. Lee. 2012. The flexible Fourier form and Dickey-Fuller
type unit root tests. {it:Economics Letters} 117: 196-199.{p_end}

{phang}Lee, J., and M. C. Strazicich. 2003. Minimum Lagrange multiplier unit root
test with two structural breaks. {it:Review of Economics and Statistics} 85:
1082-1089.{p_end}

{phang}Nazlioglu, S., et al. 2023. Fourier panel analysis of nonstationarity in
idiosyncratic and common components. {it:Econometric Reviews}.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS routines {cmd:Fourier_LM} (Enders-Lee) and
{cmd:LMt_2breaks} (Lee-Tieslau) by S. Nazlioglu; validated byte-for-byte against
the GAUSS output on the health-expenditure panel (Fourier m=1 P=42.348, m=2
P=55.282; Lee-Tieslau Panel LM=-24.048). Part of the {helpb xtpdroot:xtpdroot}
library.{p_end}
