{smcl}
{* 23jul2026}{...}
{vieweralsosee "ffrals library (all commands)" "help ffrals_hub"}{...}
{vieweralsosee "ffrals methods" "help ffrals_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "ffadf" "help ffadf"}{...}
{vieweralsosee "fflm2" "help fflm2"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{vieweralsosee "tsset" "help tsset"}{...}
{viewerjumpto "Commands" "ffrals##commands"}{...}
{viewerjumpto "Syntax" "ffrals##syntax"}{...}
{viewerjumpto "Description" "ffrals##description"}{...}
{viewerjumpto "Options" "ffrals##options"}{...}
{viewerjumpto "Examples" "ffrals##examples"}{...}
{viewerjumpto "Stored results" "ffrals##results"}{...}
{viewerjumpto "Interpreting the output" "ffrals##interpret"}{...}
{viewerjumpto "References" "ffrals##refs"}{...}
{title:Title}

{phang}
{bf:ffrals} {hline 2} Flexible-Fourier LM unit-root test with RALS and factor
(RALS2) augmentation for non-normal errors

{marker commands}{...}
{title:Commands in the ffrals library}

{synoptset 12 tabbed}{...}
{synopt:{helpb ffrals}}flexible-Fourier {bf:LM} test ({cmd:rals(0/1/2)}){p_end}
{synopt:{helpb ffadf}}flexible-Fourier {bf:ADF} test ({cmd:rals(0/1/2)}, {cmd:det()}){p_end}
{synopt:{helpb fflm2}}two-break {bf:LM} test ({cmd:rals(0/1/2)}){p_end}
{synoptline}
{p2colreset}{...}
{pstd}See {helpb ffrals_hub:help ffrals_hub} for the library overview.{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:ffrals} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}The series must be {helpb tsset}.{p_end}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt r:als(#)}}augmentation: {cmd:0} plain flexible-Fourier LM (default),
{cmd:1} RALS, {cmd:2} RALS with common/group factors{p_end}
{synopt:{opt f:actors(varlist)}}common and group factor variables (required with
{cmd:rals(2)}){p_end}
{synopt:{opt fm:ax(#)}}maximum Fourier frequency to search (default 4){p_end}
{synopt:{opt p:max(#)}}maximum augmentation lag (default 8){p_end}
{synopt:{opt ic(#)}}lag selection: 1=AIC, 2=BIC, 3=t-stat (default){p_end}
{synopt:{opt n:sim(#)}}Monte-Carlo replications for the p-value (default 50000){p_end}
{synopt:{opt seed(#)}}random-number seed for the simulation (default 2345){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:ffrals} implements the flexible-Fourier LM unit-root test of Lee, Islam,
Tieslau, Payne and Nazlioglu, in which an unknown number of smooth structural
breaks is approximated by a single Fourier frequency (chosen by minimum residual
sum of squares over 1..{it:fmax}) and the score-based LM statistic is computed by
augmented regression. With {cmd:rals(1)} the regression is augmented by the
{it:residual-augmented least squares} (RALS) terms, which exploit non-normality
of the errors to gain power without nuisance parameters. With {cmd:rals(2)} the
regression is further augmented by supplied common and group {opt factors()}
(the RALS2 factor test), making the test robust to cross-sectional dependence
when applied series-by-series to a panel.

{pstd}
The test {it:statistic} is the {it:t}-ratio on the lagged level in the augmented
LM regression, and {bf:rho-squared} = the ratio of augmented to unaugmented error
variances measures the efficiency gain from the RALS terms. Because the null
distribution is non-standard (and, under RALS, depends on {bf:rho-squared}),
{cmd:ffrals} computes the p-value and critical values by Monte-Carlo simulation
of the null distribution for the sample size at hand.

{pstd}
{cmd:ffrals} is part of the {helpb ffrals_hub:ffrals} library of flexible-Fourier
+ RALS time-series unit-root tests. See {helpb ffrals_methods:help ffrals methods}
for the formulas.

{marker options}{...}
{title:Options}

{phang}{opt rals(#)}: {cmd:0} the plain flexible-Fourier LM test; {cmd:1} adds the
RALS moment terms; {cmd:2} additionally includes the {opt factors()} for the
factor-augmented (RALS2) test.

{phang}{opt factors(varlist)}: the common factor and the relevant group factor for
the series (required when {cmd:rals(2)}). These are appended to the augmented
regression exactly as the {it:more} matrix in the source routine.

{phang}{opt fmax(#)}, {opt pmax(#)}, {opt ic(#)}: the maximum Fourier frequency
searched (default 4), the maximum lag (default 8) and the lag-selection rule
(1=AIC, 2=BIC, 3=general-to-specific t-test, the default).

{phang}{opt nsim(#)}, {opt seed(#)}: the number of Monte-Carlo replications
(default 50000) and the seed (default 2345) used to simulate the null
distribution. The {it:test statistic} does not depend on these; only the p-value
and critical values do.

{marker examples}{...}
{title:Examples}

{pstd}Plain flexible-Fourier LM test:{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. ffrals lgdp, rals(0)}{p_end}

{pstd}RALS version (non-normal errors):{p_end}
{phang2}{cmd:. ffrals lgdp, rals(1)}{p_end}

{pstd}Factor-augmented RALS2 version with a common and a group factor:{p_end}
{phang2}{cmd:. ffrals lgdp, rals(2) factors(fcommon fgroup)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:ffrals} is {cmd:rclass} and stores:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}test statistic{p_end}
{synopt:{cmd:r(p)}}simulated p-value{p_end}
{synopt:{cmd:r(freq)}}selected Fourier frequency{p_end}
{synopt:{cmd:r(lag)}}selected augmentation lag{p_end}
{synopt:{cmd:r(rho2)}}RALS rho-squared ({cmd:rals(1)}/{cmd:rals(2)}){p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}simulated 1/5/10% critical values{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
The null is a unit root. The statistic is a (negative) {it:t}-ratio and the test
{bf:rejects for values below} the reported critical value (a large negative
statistic), i.e. in favour of a (trend-)stationary series around the estimated
smooth breaks. RALS ({cmd:rals(1/2)}) sharpens the test when the errors are
non-normal; the closer {bf:rho-squared} is to zero, the larger the efficiency
gain.

{dlgtab:A note on reproducibility}

{pstd}
The test statistic, selected frequency, lag and {bf:rho-squared} are exact and
match the source GAUSS routines to the last digit. The p-value and critical
values are obtained by Monte-Carlo simulation and therefore carry a small
simulation error (about 0.003 at 50,000 replications); increase {opt nsim()} for
more precision.

{marker refs}{...}
{title:References}

{phang}Lee, J., N. Islam, M. Tieslau, J. E. Payne, and S. Nazlioglu. 2026.
Relative commodity prices, smooth breaks, and non-normal errors: a RALS-Fourier
factor approach. {it:Journal of International Money and Finance}.{p_end}

{phang}Enders, W., and J. Lee. 2012. The flexible Fourier form and Dickey-Fuller
type unit root tests. {it:Economics Letters} 117: 196-199.{p_end}

{phang}Meng, M., J. Lee, and J. E. Payne. 2017. RALS-LM unit root test with
trend breaks and non-normal errors. {it:Applied Economics} 49: 2277-2296.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS routines {cmd:Fourier_LM},
{cmd:Fourier_LM_RALS} and {cmd:Fourier_LM_RALS2} by S. Nazlioglu; the test
statistics were validated byte-for-byte against the GAUSS output and the p-values
reproduce the same Monte-Carlo construction.{p_end}
