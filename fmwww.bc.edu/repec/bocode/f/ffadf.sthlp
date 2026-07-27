{smcl}
{* 23jul2026}{...}
{vieweralsosee "ffrals" "help ffrals"}{...}
{vieweralsosee "fflm2" "help fflm2"}{...}
{vieweralsosee "ffrals library" "help ffrals_hub"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{viewerjumpto "Syntax" "ffadf##syntax"}{...}
{viewerjumpto "Description" "ffadf##description"}{...}
{viewerjumpto "Options" "ffadf##options"}{...}
{viewerjumpto "Examples" "ffadf##examples"}{...}
{viewerjumpto "Stored results" "ffadf##results"}{...}
{title:Title}

{phang}
{bf:ffadf} {hline 2} Flexible-Fourier ADF unit-root test with RALS and RALS2
(factor) augmentation for non-normal errors

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:ffadf} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}The series must be {helpb tsset}.{p_end}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt r:als(#)}}{cmd:0} plain flexible-Fourier ADF (default), {cmd:1} RALS,
{cmd:2} RALS with common/group factors{p_end}
{synopt:{opt f:actors(varlist)}}common and group factors (required with {cmd:rals(2)}){p_end}
{synopt:{opt d:et(#)}}deterministics: {cmd:1} constant, {cmd:2} constant + trend (default){p_end}
{synopt:{opt fm:ax(#)}}maximum Fourier frequency to search (default 4){p_end}
{synopt:{opt p:max(#)}}maximum augmentation lag (default 8){p_end}
{synopt:{opt ic(#)}}lag selection: 1=AIC, 2=BIC, 3=t-stat (default){p_end}
{synopt:{opt n:sim(#)}}Monte-Carlo replications for the p-value (default 50000){p_end}
{synopt:{opt seed(#)}}random-number seed (default 2345){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:ffadf} is the Dickey-Fuller counterpart of {helpb ffrals}: an augmented
Dickey-Fuller test in which an unknown number of smooth breaks is approximated by
a single Fourier frequency (chosen by minimum residual sum of squares over
1..{it:fmax}). With {cmd:rals(1)} the regression is augmented by the
residual-augmented least-squares (RALS) moment terms for non-normal errors, and
with {cmd:rals(2)} by supplied common and group {opt factors()}. The statistic is
the {it:t}-ratio on the lagged level; the p-value and critical values are obtained
by Monte-Carlo simulation of the null distribution for the sample size at hand.

{pstd}
As for {helpb ffrals}, the test {it:statistic} and {bf:rho-squared} are exact and
match the source GAUSS routines to the last digit; the p-value and critical values
carry a small simulation error. {cmd:ffadf} is part of the
{helpb ffrals_hub:ffrals} library.

{marker options}{...}
{title:Options}

{phang}{opt rals(#)}, {opt factors(varlist)}: as in {helpb ffrals}.

{phang}{opt det(#)}: {cmd:1} demeans (constant only); {cmd:2} (default) allows a
linear trend.

{phang}{opt fmax(#)}, {opt pmax(#)}, {opt ic(#)}, {opt nsim(#)}, {opt seed(#)}: as
in {helpb ffrals}.

{marker examples}{...}
{title:Examples}

{pstd}Plain flexible-Fourier ADF (trend):{p_end}
{phang2}{cmd:. ffadf lgdp, rals(0) det(2)}{p_end}

{pstd}RALS and factor-augmented versions:{p_end}
{phang2}{cmd:. ffadf lgdp, rals(1)}{p_end}
{phang2}{cmd:. ffadf lgdp, rals(2) factors(fcommon fgroup)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:ffadf} is {cmd:rclass} and stores {cmd:r(stat)}, {cmd:r(p)},
{cmd:r(freq)}, {cmd:r(lag)}, {cmd:r(rho2)} (RALS), {cmd:r(cv1)}, {cmd:r(cv5)},
{cmd:r(cv10)} and {cmd:r(N)}. The test rejects for a statistic {bf:below} the
critical value.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS {cmd:Fourier_ADF}/{cmd:Fourier_ADF_RALS}
routines by S. Nazlioglu; statistics validated byte-for-byte against the GAUSS
output.{p_end}
