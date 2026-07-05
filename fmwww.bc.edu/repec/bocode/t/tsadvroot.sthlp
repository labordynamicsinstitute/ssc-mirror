{smcl}
{* *! version 1.0.0  03jul2026}{...}
{viewerjumpto "Syntax" "tsadvroot##syntax"}{...}
{viewerjumpto "Description" "tsadvroot##description"}{...}
{viewerjumpto "Subcommands" "tsadvroot##subcommands"}{...}
{viewerjumpto "Source compatibility" "tsadvroot##compat"}{...}
{viewerjumpto "Examples" "tsadvroot##examples"}{...}
{viewerjumpto "References" "tsadvroot##references"}{...}
{viewerjumpto "Author" "tsadvroot##author"}{...}
{vieweralsosee "tsadvroot qadf" "help tsadvroot_qadf"}{...}
{vieweralsosee "tsadvroot fqadf" "help tsadvroot_fqadf"}{...}
{vieweralsosee "tsadvroot npadf" "help tsadvroot_npadf"}{...}
{vieweralsosee "tsadvroot cisur" "help tsadvroot_cisur"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{vieweralsosee "[TS] dfgls" "help dfgls"}{...}
{vieweralsosee "[R] qreg" "help qreg"}{...}
{title:Title}

{phang}
{bf:tsadvroot} {hline 2} Advanced time-series unit-root tests: quantile ADF,
Fourier quantile ADF, two-break ADF, and GLS tests with multiple structural
breaks


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tsadvroot} {it:subcommand} {varname} {ifin} [{cmd:,} {it:options}]

{p 4 4 2}
where {it:subcommand} is one of

{p2colset 8 20 22 2}{...}
{p2col:{helpb tsadvroot_qadf:qadf}}quantile ADF unit-root test
(Koenker and Xiao 2004){p_end}
{p2col:{helpb tsadvroot_fqadf:fqadf}}Fourier quantile ADF test with smooth
structural changes (Li and Zheng 2018), with residual bootstrap{p_end}
{p2col:{helpb tsadvroot_npadf:npadf}}unit-root test with two structural breaks
at unknown dates (Narayan and Popp 2010){p_end}
{p2col:{helpb tsadvroot_cisur:cisur}}GLS-based Pt, MPt, ADF, Za, MZa, MSB and
MZt tests with multiple structural breaks
(Carrion-i-Silvestre, Kim and Perron 2009){p_end}
{p2colreset}{...}

{p 4 4 2}
The data must be {helpb tsset} (a single time series, no gaps in the
estimation sample). Each subcommand has its own help page with the full
syntax, methods, stored results and examples; click the links above.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tsadvroot} is a library of modern univariate unit-root tests that go
beyond the classical Dickey-Fuller framework in two directions:

{phang2}
1. {bf:Quantile-based testing.} The {helpb tsadvroot_qadf:qadf} and
{helpb tsadvroot_fqadf:fqadf} subcommands test the unit-root hypothesis
across the conditional quantiles of the series, so that persistence may
differ in the lower, central and upper parts of the conditional
distribution. {cmd:fqadf} additionally allows smooth structural changes of
unknown form through a flexible Fourier component.

{phang2}
2. {bf:Structural breaks.} The {helpb tsadvroot_npadf:npadf} subcommand
allows two sharp breaks at unknown dates (in the level, or in the level and
slope), and {helpb tsadvroot_cisur:cisur} implements the full
Carrion-i-Silvestre, Kim and Perron (2009) battery of quasi-GLS-detrended
tests with up to 3 estimated (or 5 known) breaks, with critical values from
the authors' response surfaces.

{pstd}
All subcommands produce journal-style result tables, optional
publication-quality graphs ({opt graph} option), and full {cmd:r()} results
for post-processing.


{marker subcommands}{...}
{title:Subcommands at a glance}

{col 5}{it:Test}{col 34}{it:H0}{col 47}{it:Breaks}{col 60}{it:Inference}
{col 5}{hline 75}
{col 5}{cmd:qadf}{col 12}Koenker-Xiao t_n(tau){col 34}unit root{col 47}none{col 60}Hansen (1995) cv
{col 5}{cmd:fqadf}{col 12}Li-Zheng Fourier t_n(tau){col 34}unit root{col 47}smooth{col 60}bootstrap cv, p
{col 5}{cmd:npadf}{col 12}Narayan-Popp ADF{col 34}unit root{col 47}2 sharp{col 60}NP Table 3 cv
{col 5}{cmd:cisur}{col 12}CiS-Kim-Perron 7 tests{col 34}unit root{col 47}0-5{col 60}response surfaces
{col 5}{hline 75}


{marker compat}{...}
{title:Source compatibility}

{pstd}
Each routine is an {it:exact} translation of the reference GAUSS source code:

{phang2}{cmd:qadf}: {cmd:qr_adf.src} (tspdlib, Saban Nazlioglu), procedure
{cmd:QRADF} with the {cmd:ADF} lag pre-selection.{p_end}
{phang2}{cmd:fqadf}: {cmd:qr_fourier_adf.src} (tspdlib), procedures
{cmd:QR_Fourier_ADF} and {cmd:QR_Fourier_ADF_bootstrap}.{p_end}
{phang2}{cmd:npadf}: {cmd:narayan pop.src} (tspdlib), procedure
{cmd:ADF_2breaks}.{p_end}
{phang2}{cmd:cisur}: {cmd:carrion silvestre2009.src}
(Carrion-i-Silvestre, based on Ng-Perron code), procedures {cmd:sbur_gls}
and {cmd:__sbur_multiple_gls_brute} with the response surfaces
{cmd:__sbur_c_bar_rs} and {cmd:pd_msbur_rsf}.{p_end}

{pstd}
Every numeric convention of the sources is reproduced, including their
idiosyncrasies (documented in the "Source compatibility" section of each
subcommand's help page). Quantile regressions are computed with Stata's
exact {helpb qreg} solver, which minimizes the same check-function objective
as the GAUSS {cmd:quantileFit} routine; remaining differences are of
numerical-convergence order only.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. webuse air2, clear}{p_end}
{phang}{cmd:. gen lair = ln(air)}{p_end}

{pstd}Quantile ADF over the deciles, with the journal-style profile plot{p_end}
{phang}{cmd:. tsadvroot qadf lair, model(ct) graph}{p_end}

{pstd}Fourier quantile ADF at the median with 500 bootstrap replications{p_end}
{phang}{cmd:. tsadvroot fqadf lair, tau(0.5) model(ct) freq(1) nboot(500) seed(12345)}{p_end}

{pstd}Narayan-Popp two-break test (breaks in level and slope){p_end}
{phang}{cmd:. tsadvroot npadf lair, model(2) graph}{p_end}

{pstd}Carrion-i-Silvestre et al. with two estimated level-and-slope breaks{p_end}
{phang}{cmd:. tsadvroot cisur lair, model(break) breaks(2) graph}{p_end}


{marker references}{...}
{title:References}

{phang}
Carrion-i-Silvestre, J. L., D. Kim, and P. Perron. 2009. GLS-based unit root
tests with multiple structural breaks under both the null and the
alternative hypotheses. {it:Econometric Theory} 25: 1754-1792.

{phang}
Hansen, B. E. 1995. Rethinking the univariate approach to unit root testing:
Using covariates to increase power. {it:Econometric Theory} 11: 1148-1171.

{phang}
Koenker, R., and Z. Xiao. 2004. Unit root quantile autoregression inference.
{it:Journal of the American Statistical Association} 99: 775-787.

{phang}
Li, H., and C. Zheng. 2018. Unit root quantile autoregression testing with
smooth structural changes. {it:Finance Research Letters} 25: 83-89.

{phang}
Narayan, P. K., and S. Popp. 2010. A new unit root test with two structural
breaks in level and slope at unknown time.
{it:Journal of Applied Statistics} 37: 1425-1438.

{phang}
Ng, S., and P. Perron. 2001. Lag length selection and the construction of
unit root tests with good size and power. {it:Econometrica} 69: 1519-1554.

{pstd}
{it:Acknowledgment.} The Stata implementation follows the GAUSS routines by
Saban Nazlioglu (tspdlib) and by Josep Lluis Carrion-i-Silvestre (in turn
based on code by Serena Ng and Pierre Perron).


{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}


{title:Also see}

{psee}
Help: {helpb tsadvroot_qadf}, {helpb tsadvroot_fqadf},
{helpb tsadvroot_npadf}, {helpb tsadvroot_cisur},
{helpb dfuller}, {helpb dfgls}, {helpb qreg}
{p_end}
