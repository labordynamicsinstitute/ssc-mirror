{smcl}
{* *! version 1.0.0  05jun2026}{...}
{vieweralsosee "xtpfardl" "help xtpfardl"}{...}
{vieweralsosee "xtfdh" "help xtfdh"}{...}
{vieweralsosee "fbnardl" "help fbnardl"}{...}
{vieweralsosee "pnardl" "help pnardl"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "xtpfnardl##syntax"}{...}
{viewerjumpto "Description" "xtpfnardl##description"}{...}
{viewerjumpto "Options" "xtpfnardl##options"}{...}
{viewerjumpto "Methodology" "xtpfnardl##method"}{...}
{viewerjumpto "Examples" "xtpfnardl##examples"}{...}
{viewerjumpto "Stored results" "xtpfnardl##results"}{...}
{viewerjumpto "References" "xtpfnardl##refs"}{...}
{viewerjumpto "Also see" "xtpfnardl##alsosee"}{...}
{title:Title}

{phang}
{bf:xtpfnardl} {hline 2} Fourier-augmented panel nonlinear ARDL (Panel Fourier NARDL)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtpfnardl}
{it:depvar} {it:asymvars}
{ifin}
[{cmd:,} {it:options}]

{p 4 6 2}where {it:asymvars} are the regressors to be decomposed into positive and
negative partial sums (the asymmetric regressors).{p_end}

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt lin(varlist)}}linear (symmetric) control variables, entered without decomposition{p_end}
{synopt:{opt mod:el(type)}}{cmd:pmg} (default), {cmd:csardl}, {cmd:mg}, {cmd:dfe}{p_end}
{synopt:{opt cr:lags(#)}}lags of cross-section averages; default {cmd:crlags(3)}{p_end}
{synopt:{opt nocross}}omit cross-sectional averages{p_end}

{syntab:Lag / Fourier}
{synopt:{opt p:lags(#)} / {opt q:lags(#)}}short-run lags; default {cmd:plags(1) qlags(1)}{p_end}
{synopt:{opt maxk(#)}}max Fourier frequency searched; default {cmd:maxk(2)}{p_end}
{synopt:{opt k(#)}}fix the Fourier frequency{p_end}
{synopt:{opt frac:tional}}search frequencies in 0.1 steps{p_end}
{synopt:{opt nof:ourier}}standard panel NARDL (no Fourier terms){p_end}
{synopt:{opt trend}}include a linear trend{p_end}

{syntab:Reporting}
{synopt:{opt hausman}}report the PMG-vs-MG long-run poolability (Hausman) test{p_end}
{synopt:{opt mh:orizon(#)}}horizon for the cumulative dynamic multipliers; default {cmd:mhorizon(20)}{p_end}
{synopt:{opt replace}}overwrite existing {it:v}{cmd:_pos}/{it:v}{cmd:_neg} variables{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt nogr:aph}}suppress graphs{p_end}
{synopt:{opt graphp:refix(string)}}prefix for exported {cmd:.png} files{p_end}
{synopt:{opt nodiag}}suppress diagnostics{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}Data must be {helpb xtset}. The engine is {helpb xtdcce2}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpfnardl} estimates the {bf:Fourier-augmented panel nonlinear ARDL}, i.e.
the asymmetric (NARDL) counterpart of {helpb xtpfardl}. Each variable in
{it:asymvars} is decomposed into cumulative positive and negative partial sums
(Shin, Yu & Greenwood-Nimmo 2014), allowing increases and decreases to exert
distinct long- and short-run effects, while Enders-Lee Fourier terms absorb
unknown smooth structural breaks. This is the FPMG-NARDL estimator used to test
whether detected asymmetries are {it:genuine} or merely {it:spurious} artefacts
of unmodelled structural change.

{pstd}
For each decomposed variable it reports the long-run {cmd:(+)}/{cmd:(-)}
coefficients, the error-correction speed, the short-run dynamics, and formal
{bf:Wald asymmetry tests} (long-run {cmd:H0: }{&theta}{cmd:+ = }{&theta}{cmd:-}
and short-run {cmd:H0: }{&gamma}{cmd:+ = }{&gamma}{cmd:-}). For each decomposed
variable it draws two figures: the {bf:cumulative dynamic multipliers} with
confidence-interval bands (converging to {&beta}{c +} and {&beta}{c -}), and the
{bf:asymmetry path} m{c +}(h){&minus}m{c -}(h) with its CI band, which converges
to the long-run asymmetry {&beta}{c +}{&minus}{&beta}{c -} (zero under symmetry).
With {opt hausman} it also reports the PMG-vs-MG poolability test.

{marker options}{...}
{title:Options}

{phang}{opt lin(varlist)} lists symmetric controls that enter the model linearly
(e.g. GDP, FDI, trade openness), without {cmd:+}/{cmd:-} decomposition.

{phang}{opt model(type)} selects the estimator. {cmd:pmg} (default) pools the
long-run {cmd:+}/{cmd:-} coefficients while keeping the adjustment and short-run
dynamics heterogeneous, as in the source paper. {cmd:csardl}/{cmd:mg} make all
coefficients heterogeneous (with/without cross-section averages); {cmd:dfe}
pools everything.

{phang}{opt replace} is required to re-run on data where the partial-sum
variables {it:v}{cmd:_pos} / {it:v}{cmd:_neg} already exist (they are left in
memory for inspection).

{phang}The remaining options ({opt maxk}, {opt k}, {opt fractional},
{opt nofourier}, {opt crlags}, {opt nocross}, {opt plags}, {opt qlags},
{opt trend}) behave exactly as in {helpb xtpfardl}.

{marker method}{...}
{title:Methodology}

{pstd}
Each asymmetric regressor X is split into

{p 8 8 2}X{c +}(i,t) = {&Sigma}{sub:s} max({&Delta}X(i,s),0),{space 4}X{c -}(i,t) = {&Sigma}{sub:s} min({&Delta}X(i,s),0),{p_end}

{pstd}
and the Fourier-augmented asymmetric UECM is estimated:

{p 8 8 2}
{cmd:D.}Y = {&mu} + {&rho}·L.Y + {&theta}{c +}·L.X{c +} + {&theta}{c -}·L.X{c -}
+ {&Sigma}{&psi}{cmd:D.}Y + {&Sigma}({&gamma}{c +}{cmd:D.}X{c +} + {&gamma}{c -}{cmd:D.}X{c -})
+ {&lambda}0 sin(2{&pi}kt/T) + {&lambda}1 cos(2{&pi}kt/T) + e.

{pstd}
Long-run effects are {&beta}{c +} = -{&theta}{c +}/{&rho} and {&beta}{c -} =
-{&theta}{c -}/{&rho} (delta method). Asymmetry is assessed by Wald tests; if the
long-run asymmetry survives the Fourier augmentation, it is attributed to genuine
nonlinearity rather than smooth structural change.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. xtset country year}{p_end}

{pstd}Baseline FPMG-NARDL (paper specification): REC on three uncertainty
indicators (decomposed) with GDP, FDI, TO as linear controls{p_end}
{phang2}{cmd:. xtpfnardl rec cpu eru gpr, lin(gdp fdi to) model(pmg) maxk(2)}{p_end}

{pstd}Heterogeneous (mean-group) NARDL, fixed frequency{p_end}
{phang2}{cmd:. xtpfnardl rec cpu eru gpr, lin(gdp fdi to) model(mg) k(1) replace}{p_end}

{pstd}Robustness: drop Fourier terms to see whether asymmetry was spurious{p_end}
{phang2}{cmd:. xtpfnardl rec cpu eru gpr, lin(gdp fdi to) nofourier replace}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtpfnardl} stores in {cmd:e()} (plus the {helpb xtdcce2} engine results):{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_g)}, {cmd:e(kstar)}, {cmd:e(plags)}, {cmd:e(qlags)}}groups, frequency, lags{p_end}
{synopt:{cmd:e(ect_b)}, {cmd:e(ect_se)}}speed of adjustment{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(asymvars)}, {cmd:e(posvars)}, {cmd:e(negvars)}, {cmd:e(linvars)}}variable lists{p_end}
{synopt:{cmd:e(lrnames)}}long-run coefficient names{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(lr_b)}, {cmd:e(lr_V)}}long-run estimates and VCV{p_end}
{synopt:{cmd:e(asym)}}per-variable Wald asymmetry tests (LR W, p, SR W, p){p_end}
{synopt:{cmd:e(kgrid)}}frequency grid and SSR{p_end}
{p2colreset}{...}

{marker refs}{...}
{title:References}

{phang}Bildirici, M., and F. Kay{&iacute}k{&ccedil}{&inodot}. 2022. Renewable energy and current
account balance nexus. {it:Environmental Science and Pollution Research} 29:
48759-48768. {browse "https://doi.org/10.1007/s11356-022-19286-9":doi:10.1007/s11356-022-19286-9}.{p_end}

{phang}Bildirici, M., and F. {&Ccedil}oban Kay{&iacute}k{&ccedil}{&inodot}. 2024. Energy consumption,
energy intensity, economic growth, FDI, urbanization, PM2.5 concentrations
nexus. {it:Environment, Development and Sustainability} 26: 5047-5065.
{browse "https://doi.org/10.1007/s10668-023-02923-9":doi:10.1007/s10668-023-02923-9}.{p_end}

{phang}Arif, M. A., and F. Furuoka. 2026. Genuine or spurious asymmetry?
Disentangling uncertainty effects on renewable energy consumption using
Fourier-augmented panel NARDL. SSRN Working Paper 6719166.
{browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6719166":papers.ssrn.com/sol3/papers.cfm?abstract_id=6719166}.{p_end}

{phang}Shin, Y., B. Yu, and M. Greenwood-Nimmo. 2014. Modelling asymmetric
cointegration and dynamic multipliers in a nonlinear ARDL framework. In
{it:Festschrift in Honor of Peter Schmidt}, 281-314. Springer.{p_end}

{phang}Pesaran, M. H., Y. Shin, and R. P. Smith. 1999. Pooled mean group
estimation of dynamic heterogeneous panels. {it:JASA} 94: 621-634.{p_end}

{phang}Enders, W., and J. Lee. 2012. The flexible Fourier form and Dickey-Fuller
type unit root tests. {it:Economics Letters} 117: 196-199.{p_end}

{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Help:  {helpb xtpfardl} (symmetric Fourier panel ARDL),
{helpb xtfdh} (Fourier-DH causality),
{helpb fbnardl} (time-series Fourier NARDL),
{helpb pnardl}, {helpb xtdcce2}{p_end}

{p 4 14 2}
Author:  Dr. Merwan Roudane{break}
Email:  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub:  {browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
