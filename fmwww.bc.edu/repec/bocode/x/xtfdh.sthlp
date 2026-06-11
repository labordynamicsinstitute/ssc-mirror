{smcl}
{* *! version 1.0.0  05jun2026}{...}
{vieweralsosee "xtpfardl" "help xtpfardl"}{...}
{vieweralsosee "xtgcause" "help xtgcause"}{...}
{vieweralsosee "fbardl" "help fbardl"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "xtfdh##syntax"}{...}
{viewerjumpto "Description" "xtfdh##description"}{...}
{viewerjumpto "Options" "xtfdh##options"}{...}
{viewerjumpto "Methodology" "xtfdh##method"}{...}
{viewerjumpto "Examples" "xtfdh##examples"}{...}
{viewerjumpto "Stored results" "xtfdh##results"}{...}
{viewerjumpto "References" "xtfdh##refs"}{...}
{viewerjumpto "Also see" "xtfdh##alsosee"}{...}
{title:Title}

{phang}
{bf:xtfdh} {hline 2} Fourier Dumitrescu-Hurlin panel Granger non-causality test

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtfdh}
{it:depvar} {it:causevar}
{ifin}
[{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt lags(#)}}lag order K of the causality regressions; default {cmd:lags(1)}{p_end}
{synopt:{opt dir:ection(d)}}{cmd:forward}, {cmd:reverse} or {cmd:both} (default){p_end}

{syntab:Fourier}
{synopt:{opt maxk(#)}}maximum Fourier frequency searched; default {cmd:maxk(3)}{p_end}
{synopt:{opt k(#)}}fix the Fourier frequency{p_end}
{synopt:{opt frac:tional}}search frequencies in 0.1 steps{p_end}
{synopt:{opt nof:ourier}}standard (non-Fourier) Dumitrescu-Hurlin test{p_end}

{syntab:Reporting}
{synopt:{opt reg:ress}}display each cross-section unit's Wald statistic{p_end}
{synopt:{opt nogr:aph}}suppress the Wald-distribution graph{p_end}
{synopt:{opt graphp:refix(string)}}filename prefix for exported {cmd:.png}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}The data must be {helpb xtset}. {cmd:xtfdh} tests, in the
{cmd:forward} direction, the null that {it:causevar} does not Granger-cause
{it:depvar}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfdh} implements the {bf:Fourier Dumitrescu-Hurlin (FDH)} test of Granger
non-causality in heterogeneous panels (Ersin 2026), generalizing the
Dumitrescu & Hurlin (2012) test by adding Enders-Lee Fourier terms to each
unit's regression so that smooth structural breaks do not contaminate the
causality inference. With {opt nofourier} it reproduces the standard DH test
(as in {helpb xtgcause}).

{pstd}
By default ({cmd:direction(both)}) the command tests both directions and prints
a {bf:bidirectional / unidirectional} verdict, mirroring the causality tables of
Ersin (2026) and Sardarli & Suleymanli (2026). It also draws the distribution of
the individual Wald statistics against the {&chi}{sup:2} reference, revealing the
heterogeneity of causality across units.

{marker options}{...}
{title:Options}

{phang}{opt lags(#)} sets the common lag order K of y and of the causing variable
in each unit regression. Each unit must have more than 2K (+2 for the Fourier
terms) usable observations.

{phang}{opt direction(d)} chooses which null(s) to test: {cmd:forward}
({it:causevar} {c 0-/}{c +0} {it:depvar}), {cmd:reverse}, or {cmd:both} (default,
adds the verdict block).

{phang}{opt maxk(#)}, {opt k(#)}, {opt fractional}, {opt nofourier} govern the
Fourier frequency exactly as in {helpb xtpfardl}: by default the single optimal
frequency is chosen by minimum pooled SSR.

{phang}{opt regress} prints each unit's Wald statistic; {opt graph} controls and
{opt graphprefix()} names the exported figure.

{marker method}{...}
{title:Methodology}

{pstd}
For each unit i the command fits

{p 8 8 2}
y(i,t) = {&alpha}(i) + {&Sigma}{&gamma}(i,k)·y(i,t-k) + {&Sigma}{&beta}(i,k)·x(i,t-k)
+ {&lambda}0(i)·sin(2{&pi}kt/T) + {&lambda}1(i)·cos(2{&pi}kt/T) + {&epsilon}(i,t),

{pstd}
and forms the individual Wald statistic W(i) = K·F(i) for H0: {&beta}(i,1) = ... =
{&beta}(i,K) = 0. The panel statistics are the average W-bar and the standardized

{p 8 8 2}Z-bar = sqrt(N/2K)·(W-bar - K),{p_end}
{p 8 8 2}Z-tilde = sqrt[ N/2K · (T-3K-5)/(T-2K-3) ]·[ (T-3K-3)/(T-3K-1)·W-bar - K ],{p_end}

{pstd}
both standard normal under the null. The finite-T statistic {bf:Z-tilde} is the
recommended one (it corresponds to Z-bar in EViews). Two-sided p-values are
reported, following the {helpb xtgcause} convention.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. xtset id year}{p_end}

{pstd}Both directions, Fourier-augmented, 2 lags{p_end}
{phang2}{cmd:. xtfdh co2 y, lags(2)}{p_end}

{pstd}One direction only, fixed frequency{p_end}
{phang2}{cmd:. xtfdh fcd fd, direction(forward) k(1)}{p_end}

{pstd}Standard (non-Fourier) Dumitrescu-Hurlin test{p_end}
{phang2}{cmd:. xtfdh co2 ret, lags(1) nofourier}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtfdh} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(lags)}}lag order K{p_end}
{synopt:{cmd:r(kstar)}}selected Fourier frequency{p_end}
{synopt:{cmd:r(wbar_f)}, {cmd:r(zbar_f)}, {cmd:r(zbart_f)}, {cmd:r(p_f)}}forward direction{p_end}
{synopt:{cmd:r(wbar_r)}, {cmd:r(zbar_r)}, {cmd:r(zbart_r)}, {cmd:r(p_r)}}reverse direction{p_end}
{p2colreset}{...}

{marker refs}{...}
{title:References}

{phang}Bildirici, M., and F. Kay{&iacute}k{&ccedil}{&inodot}. 2022. Renewable energy and current
account balance nexus. {it:Environmental Science and Pollution Research} 29:
48759-48768. {browse "https://doi.org/10.1007/s11356-022-19286-9":doi:10.1007/s11356-022-19286-9}.{p_end}

{phang}Dumitrescu, E.-I., and C. Hurlin. 2012. Testing for Granger non-causality
in heterogeneous panels. {it:Economic Modelling} 29: 1450-1460.
{browse "https://doi.org/10.1016/j.econmod.2012.02.014":doi:10.1016/j.econmod.2012.02.014}.{p_end}

{phang}Ersin, {&Ouml}. {&Ouml}. 2026. Decoupling of CO2 emissions from growth with
energy transition and eco-innovations in OECD. {it:Sustainability} 18(6): 2728.
{browse "https://doi.org/10.3390/su18062728":doi:10.3390/su18062728}.{p_end}

{phang}Lopez, L., and S. Weber. 2017. Testing for Granger causality in panel
data. {it:Stata Journal} 17: 972-984.{p_end}

{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Help:  {helpb xtpfardl} (Fourier panel ARDL estimator),
{helpb xtgcause} (standard DH test), {helpb fbardl}{p_end}

{p 4 14 2}
Author:  Dr. Merwan Roudane{break}
Email:  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub:  {browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
