{smcl}
{* *! version 1.0.0  05jun2026}{...}
{vieweralsosee "xtfdh" "help xtfdh"}{...}
{vieweralsosee "xtdcce2" "help xtdcce2"}{...}
{vieweralsosee "fbardl" "help fbardl"}{...}
{vieweralsosee "xtcd2" "help xtcd2"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "xtpfardl##syntax"}{...}
{viewerjumpto "Description" "xtpfardl##description"}{...}
{viewerjumpto "Options" "xtpfardl##options"}{...}
{viewerjumpto "Models" "xtpfardl##models"}{...}
{viewerjumpto "Methodology" "xtpfardl##method"}{...}
{viewerjumpto "Examples" "xtpfardl##examples"}{...}
{viewerjumpto "Stored results" "xtpfardl##results"}{...}
{viewerjumpto "References" "xtpfardl##refs"}{...}
{viewerjumpto "Also see" "xtpfardl##alsosee"}{...}
{title:Title}

{phang}
{bf:xtpfardl} {hline 2} Fourier-augmented panel ARDL / CS-ARDL estimator

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtpfardl}
{it:depvar} {it:indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(type)}}estimator: {cmd:csardl} (default), {cmd:mg}, {cmd:pmg}, {cmd:dfe}{p_end}
{synopt:{opt cr:lags(#)}}lags of cross-section averages; default {cmd:crlags(3)}{p_end}
{synopt:{opt nocross}}omit cross-sectional averages (plain panel ARDL){p_end}

{syntab:Lag structure}
{synopt:{opt p:lags(#)}}short-run lags of {cmd:D.}{it:depvar}; default {cmd:plags(1)}{p_end}
{synopt:{opt q:lags(#)}}short-run lags of {cmd:D.}{it:indepvars}; default {cmd:qlags(1)}{p_end}
{synopt:{opt lags:earch(#)}}select (p,q) by pooled BIC up to this maximum{p_end}

{syntab:Fourier}
{synopt:{opt maxk(#)}}maximum Fourier frequency searched; default {cmd:maxk(3)}{p_end}
{synopt:{opt k(#)}}fix the Fourier frequency (skip the search){p_end}
{synopt:{opt frac:tional}}search frequencies in steps of 0.1 (cumulative frequencies){p_end}
{synopt:{opt nof:ourier}}exclude Fourier terms (standard panel ARDL){p_end}
{synopt:{opt trend}}include a (heterogeneous) linear trend{p_end}

{syntab:Reporting}
{synopt:{opt hausman}}report the PMG-vs-MG long-run poolability (Hausman) test{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt nogr:aph}}suppress all graphs{p_end}
{synopt:{opt graphp:refix(string)}}filename prefix for exported {cmd:.png} graphs{p_end}
{synopt:{opt nodiag}}suppress the diagnostics block{p_end}
{synopt:{opt nocinfo}}suppress the long-run coefficient plot{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:xtpfardl} requires the data to be {helpb xtset}, and uses {helpb xtdcce2}
(Ditzen) as the estimation engine. {it:depvar} and {it:indepvars} should be in
levels; the command builds the error-correction (UECM) form internally.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpfardl} estimates the {bf:Fourier-augmented panel ARDL} family of models for
heterogeneous, cross-sectionally dependent panels with smooth structural breaks.
It augments the (cross-section augmented) panel ARDL with Enders-Lee Fourier
terms {cmd:sin}(2{&pi}{it:kt}/T) and {cmd:cos}(2{&pi}{it:kt}/T) that approximate an
unknown number of gradual breaks without pre-testing break dates.

{pstd}
The command reproduces the estimators introduced in:

{p 8 12 2}{bf:o} Ersin (2026) — {bf:Fourier-CS-ARDL} ({cmd:model(csardl)}); and{p_end}
{p 8 12 2}{bf:o} Sardarli & Suleymanli (2026) — {bf:Fourier Panel ARDL} ({cmd:model(pmg)}/{cmd:mg}).{p_end}

{pstd}
For every model {cmd:xtpfardl} reports a journal-style {bf:long-run} table
(delta-method standard errors), the {bf:error-correction} speed of adjustment
with the implied half-life, the {bf:short-run} dynamics including the Fourier
terms, residual {bf:diagnostics} (Fourier joint significance and a Pesaran CD
test via {helpb xtcd2}), and publication-quality graphs (frequency selection
and a long-run coefficient plot).

{pstd}
To test Granger non-causality with the matching Fourier method, see {helpb xtfdh}.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt model(type)} selects the estimator. See {help xtpfardl##models:Models} below.
{cmd:csardl} (the default) is the cross-section augmented ARDL of Chudik et al.
(2016) used by Ersin (2026); {cmd:pmg} is the pooled mean-group panel ARDL of
Pesaran, Shin & Smith (1999) used by Sardarli & Suleymanli (2026).

{phang}
{opt crlags(#)} sets the number of lags of the cross-section averages used to
proxy the unobserved common factors (passed to {helpb xtdcce2}). Chudik et al.
suggest of order T^(1/3); {cmd:crlags(3)} is a common choice.

{phang}
{opt nocross} drops the cross-sectional averages, giving a plain (non-augmented)
panel ARDL. Use this to obtain a benchmark that ignores cross-sectional
dependence.

{dlgtab:Lag structure}

{phang}
{opt plags(#)} and {opt qlags(#)} fix the short-run augmentation, i.e. the lags of
{cmd:D.}{it:depvar} and of {cmd:D.}{it:indepvars}. {opt lagsearch(#)} instead
selects (p,q) automatically by minimizing the pooled BIC over a grid up to the
stated maximum.

{dlgtab:Fourier}

{phang}
{opt maxk(#)}, {opt k(#)} and {opt fractional} govern the Fourier frequency. By
default {cmd:xtpfardl} selects the single optimal frequency k* over the integer
grid 1,...,{cmd:maxk} by minimum pooled sum of squared residuals (Yilanci,
Bozoklu & Gorus 2020). {opt k(#)} fixes the frequency; {opt fractional} searches
in 0.1 steps; {opt nofourier} removes the Fourier terms altogether.

{dlgtab:Reporting}

{phang}
{opt hausman} estimates the model twice (pooled mean group and mean group) and
reports the Hausman test of long-run poolability (H0: long-run homogeneity).
Not rejecting H0 supports the more efficient {cmd:pmg}; rejecting favours {cmd:mg}.
The test is computed with the built-in {helpb hausman} command on the
{helpb nlcom}-posted long-run vectors.

{phang}
{opt graphprefix(string)} prepends {it:string} to the exported PNG filenames
({it:string}{cmd:xtpfardl_kstar.png} and {it:string}{cmd:xtpfardl_lr.png}).
{opt nograph} disables graph creation; {opt nodiag} and {opt nocinfo} suppress
the diagnostics block and the long-run plot, respectively.

{marker models}{...}
{title:Models}

{pstd}
The four models share the one-step unrestricted error-correction (UECM)
representation and differ only in which coefficients are pooled:

{p2colset 8 24 26 2}{...}
{p2col:{bf:csardl}}Fourier-CS-ARDL. All coefficients heterogeneous; equation
augmented with cross-section averages (Chudik et al. 2016; Ersin 2026). {bf:Default.}{p_end}
{p2col:{bf:mg}}Fourier mean-group panel ARDL (CCE-MG); heterogeneous, optionally augmented.{p_end}
{p2col:{bf:pmg}}Fourier pooled mean-group panel ARDL; long-run pooled, dynamics
heterogeneous (Pesaran, Shin & Smith 1999; Sardarli & Suleymanli 2026).{p_end}
{p2col:{bf:dfe}}Fourier dynamic fixed-effects; all coefficients pooled.{p_end}
{p2colreset}{...}

{marker method}{...}
{title:Methodology}

{pstd}
{cmd:xtpfardl} estimates, for each unit i = 1,...,N, the Fourier-augmented UECM

{p 8 8 2}
{cmd:D.}y(i,t) = c(i) + {&phi}(i)·y(i,t-1) + {&theta}(i)'x(i,t-1)
+ {&Sigma}{&psi}(i,j)·{cmd:D.}y(i,t-j) + {&Sigma}{&delta}(i,j)'{cmd:D.}x(i,t-j)
+ {&lambda}0(i)·sin(2{&pi}kt/T) + {&lambda}1(i)·cos(2{&pi}kt/T) + e(i,t),

{pstd}
augmented (in {cmd:csardl}/{cmd:mg}) with cross-section averages of all model
variables and their lags to remove unobserved common factors. The
{bf:long-run} coefficients are recovered by the delta method as
{&beta}(x) = -{&theta}(x)/{&phi} (reported with {helpb nlcom}-type standard errors),
and {&phi} is the {bf:error-correction speed of adjustment}. The Fourier
frequency k* is chosen by minimum SSR; the joint significance of the sine and
cosine terms is reported as a Fourier nonlinearity test.

{pstd}
Recommended preliminary tests (separate commands): cross-sectional dependence
{helpb xtcd2}; slope homogeneity; second-generation panel unit roots
{helpb xtcips}; and panel cointegration {helpb xtwest} / {helpb xtpedroni}.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse set https://www.stata-press.com/data/r17/}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}Fourier-CS-ARDL (Ersin 2026 specification){p_end}
{phang2}{cmd:. xtpfardl co2 y ret etd, model(csardl) crlags(3)}{p_end}

{pstd}Fourier Panel ARDL / PMG (Sardarli & Suleymanli 2026 specification){p_end}
{phang2}{cmd:. xtpfardl fcd fd f er inf, model(pmg) maxk(3)}{p_end}

{pstd}Fix the frequency and search the lag orders by BIC{p_end}
{phang2}{cmd:. xtpfardl y x z, model(mg) k(1) lagsearch(3)}{p_end}

{pstd}Benchmark without Fourier terms or cross-section averages{p_end}
{phang2}{cmd:. xtpfardl y x z, model(mg) nofourier nocross}{p_end}

{pstd}Then test causality with the matching Fourier method{p_end}
{phang2}{cmd:. xtfdh co2 y, lags(2)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtpfardl} stores the following in {cmd:e()} (in addition to the
{helpb xtdcce2} engine results, which remain in {cmd:e(b)}/{cmd:e(V)}):

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(kstar)}}selected Fourier frequency{p_end}
{synopt:{cmd:e(plags)}, {cmd:e(qlags)}}short-run lag orders{p_end}
{synopt:{cmd:e(crlags)}}cross-section average lags{p_end}
{synopt:{cmd:e(ect_b)}, {cmd:e(ect_se)}}speed of adjustment and its SE{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpfardl}{p_end}
{synopt:{cmd:e(model)}}selected model{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(indepvars)}}dependent / long-run variables{p_end}
{synopt:{cmd:e(lrnames)}}names of long-run coefficients{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(lr_b)}, {cmd:e(lr_V)}}long-run estimates and (delta-method) VCV{p_end}
{synopt:{cmd:e(kgrid)}}Fourier frequency grid and SSR{p_end}
{p2colreset}{...}

{pstd}The residual variable {cmd:_xtpf_resid} (common-factor partialled) is left
in memory for post-estimation use.{p_end}

{marker refs}{...}
{title:References}

{phang}Bildirici, M., and F. Kay{&iacute}k{&ccedil}{&inodot}. 2022. Renewable energy and current
account balance nexus. {it:Environmental Science and Pollution Research} 29:
48759-48768. {browse "https://doi.org/10.1007/s11356-022-19286-9":doi:10.1007/s11356-022-19286-9}.{p_end}

{phang}Bildirici, M., and F. {&Ccedil}oban Kay{&iacute}k{&ccedil}{&inodot}. 2024. Energy consumption,
energy intensity, economic growth, FDI, urbanization, PM2.5 concentrations
nexus. {it:Environment, Development and Sustainability} 26: 5047-5065.
{browse "https://doi.org/10.1007/s10668-023-02923-9":doi:10.1007/s10668-023-02923-9}.{p_end}

{phang}Chudik, A., K. Mohaddes, M. H. Pesaran, and M. Raissi. 2016.
Long-run effects in large heterogeneous panel data models with cross-sectionally
correlated errors. {it:Advances in Econometrics} 36: 85-135.{p_end}

{phang}Ditzen, J. 2021. Estimating long-run effects and the exponent of
cross-sectional dependence: An update to xtdcce2. {it:Stata Journal} 21: 687-707.{p_end}

{phang}Ersin, {&Ouml}. {&Ouml}. 2026. Decoupling of CO2 emissions from growth with
energy transition and eco-innovations in OECD: Novel Fourier-CS-ARDL and
Fourier-DH-causality analyses. {it:Sustainability} 18(6): 2728.
{browse "https://doi.org/10.3390/su18062728":doi:10.3390/su18062728}.{p_end}

{phang}Pesaran, M. H., Y. Shin, and R. P. Smith. 1999. Pooled mean group
estimation of dynamic heterogeneous panels. {it:JASA} 94: 621-634.{p_end}

{phang}Sardarli, K., and J. Suleymanli. 2026. Modeling the dynamics of financial
dollarization under structural shifts in Latin America: The new Fourier panel
ARDL approach. {it:Journal of Sustainable Development Issues} 3(2): 117-137.
{browse "https://doi.org/10.62433/josdi.v3i2.68":doi:10.62433/josdi.v3i2.68}.{p_end}

{phang}Yilanci, V., Bozoklu, {&Scaron}., and Gorus, M. S. 2020. Are BRICS
countries pollution havens? Evidence from a bootstrap ARDL bounds testing
approach with a Fourier function. {it:Sustainable Cities and Society} 55: 102035.{p_end}

{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Help:  {helpb xtfdh} (Fourier-DH causality),
{helpb fbardl} (time-series Fourier bootstrap ARDL),
{helpb xtdcce2}, {helpb xtcd2}, {helpb xtcips}, {helpb xtwest}{p_end}

{p 4 14 2}
Author:  Dr. Merwan Roudane{break}
Email:  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub:  {browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
