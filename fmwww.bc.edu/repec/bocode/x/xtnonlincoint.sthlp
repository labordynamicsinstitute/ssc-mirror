{smcl}
{* *! version 1.0.0  21jun2026}{...}
{vieweralsosee "xtnonlincoint ecm" "help xtnonlincoint_ecm"}{...}
{vieweralsosee "xtnonlincoint fffff" "help xtnonlincoint_fffff"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtnonlincoint##syntax"}{...}
{viewerjumpto "Description" "xtnonlincoint##description"}{...}
{viewerjumpto "Subcommands" "xtnonlincoint##subcommands"}{...}
{viewerjumpto "Options" "xtnonlincoint##options"}{...}
{viewerjumpto "Remarks" "xtnonlincoint##remarks"}{...}
{viewerjumpto "Examples" "xtnonlincoint##examples"}{...}
{viewerjumpto "Stored results" "xtnonlincoint##results"}{...}
{viewerjumpto "References" "xtnonlincoint##references"}{...}
{viewerjumpto "Author" "xtnonlincoint##author"}{...}
{title:Title}

{phang}
{bf:xtnonlincoint} {hline 2} Nonlinear panel cointegration tests robust to
structural breaks and cross-sectional dependence

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtnonlincoint} {it:subcommand} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{pstd}
where {it:subcommand} is one of:

{synoptset 16 tabbed}{...}
{synopt:{helpb xtnonlincoint_ecm:ecm}}nonlinear error-correction based test
(Omay, Emirmahmutoglu & Denaux 2017){p_end}
{synopt:{helpb xtnonlincoint_fffff:fffff}}fractional frequency flexible Fourier
form test (Olayeni, Tiwari & Wohar 2021){p_end}
{synopt:{cmd:all}}run both tests on the same model{p_end}
{synoptline}

{pstd}
The data must be {helpb xtset} as a {bf:balanced} panel before use.
{depvar} is the left-hand-side variable and {indepvars} the long-run regressors.

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtnonlincoint} implements two recent panel cointegration tests that allow
the long-run adjustment to be {it:nonlinear} and the panel to display
{it:cross-sectional dependence (CSD)}. Both tests reject the null of no
cointegration when the adjustment back to equilibrium is significant, and both
obtain critical values and {it:p}-values by a CSD-robust residual bootstrap.

{pstd}
{cmd:ecm} estimates a panel logistic smooth-transition error-correction model
(PLSTR-ECM) and forms the Abadir-Distaso modified Wald (MWALD) group-mean
statistic. {cmd:fffff} tests the stationarity of the cointegrating residual with
a Kapetanios-Shin-Snell (KSS) nonlinear ADF regression augmented by a
{it:fractional}-frequency Fourier term that captures an unknown number of smooth
structural breaks, and applies the Sequential Panel Selection Method (SPSM) to
identify which cross-sections drive the result.

{marker subcommands}{...}
{title:Subcommands}

{phang}
{helpb xtnonlincoint_ecm:xtnonlincoint ecm} {hline 2} the nonlinear ECM-based
test. The cointegrating residual enters a conditional ECM with linear and
quadratic terms (a first-order Taylor expansion of a logistic transition). The
MWALD statistic orthogonalises the one-sided coefficient against the two-sided
one; a sieve bootstrap on a panel VAR in differences provides CSD-robust
critical values.

{phang}
{helpb xtnonlincoint_fffff:xtnonlincoint fffff} {hline 2} the FFFFF test. For
each panel the cointegrating residual is tested for a unit root with a KSS cubic
term plus {cmd:sin}/{cmd:cos} Fourier terms whose frequency {it:k} is searched
on a fractional grid. A stationary bootstrap applied jointly to all panels
delivers CSD-robust {it:p}-values, and SPSM peels off the most stationary series
one at a time.

{marker options}{...}
{title:Options}

{pstd}
Options specific to each test are documented on its own help page. Common
options include {cmd:breps()} (bootstrap replications), {cmd:seed()},
{cmd:trend} (detrend rather than demean), {cmd:graph} (journal-style plots) and
{cmd:noprint}. See {helpb xtnonlincoint_ecm} and {helpb xtnonlincoint_fffff}.

{marker remarks}{...}
{title:Remarks}

{pstd}
A balanced panel is required because the bootstrap resamples a {it:common} time
index across all cross-sections to preserve contemporaneous dependence. If the
panel is unbalanced the command stops with an informative error.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Nonlinear ECM-based test{p_end}
{phang2}{cmd:. xtnonlincoint ecm invest mvalue kstock, lags(1) breps(299)}{p_end}

{pstd}FFFFF test with SPSM and plots{p_end}
{phang2}{cmd:. xtnonlincoint fffff invest mvalue kstock, spsm graph}{p_end}

{pstd}Both tests at once{p_end}
{phang2}{cmd:. xtnonlincoint all invest mvalue kstock, breps(299) seed(123)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
Each subcommand stores its results in {cmd:r()}; see the subcommand help pages
for the full list. Key scalars are {cmd:r(stat)} (group statistic),
{cmd:r(p)} (bootstrap {it:p}-value) and {cmd:r(cv5)} (5% critical value);
{cmd:r(indstat)} holds the per-panel statistics.

{marker references}{...}
{title:References}

{phang}
Abadir, K. M., and W. Distaso. 2007. Testing joint hypotheses when one of the
alternatives is one-sided. {it:Journal of Econometrics} 140: 695-718.

{phang}
Olayeni, R. O., A. K. Tiwari, and M. E. Wohar. 2021. Fractional frequency
flexible Fourier form (FFFFF) for panel cointegration test. {it:Applied
Economics Letters} 28(6): 482-486.
{browse "https://doi.org/10.1080/13504851.2020.1761526":doi:10.1080/13504851.2020.1761526}.

{phang}
Omay, T., F. Emirmahmutoglu, and Z. S. Denaux. 2017. Nonlinear error correction
based cointegration test in panel data. {it:Economics Letters} 157: 1-4.
{browse "https://doi.org/10.1016/j.econlet.2017.05.017":doi:10.1016/j.econlet.2017.05.017}.

{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
