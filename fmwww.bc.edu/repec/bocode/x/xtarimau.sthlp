{smcl}
{* *! version 1.0.3  07oct2022}{...}
{vieweralsosee "[TS] arima" "mansection TS arima"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] arima postestimation" "help arima postestimation"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "arimaauto##syntax"}{...}
{viewerjumpto "Description" "arimaauto##description"}{...}
{viewerjumpto "Options" "arimaauto##options"}{...}
{viewerjumpto "Examples" "arimaauto##examples"}{...}
{viewerjumpto "References" "arimaauto##references"}{...}
{p2colset 1 15 17 2}{...}

{title:Title}
{phang}
{bf:xtarimau} {hline 2} Finds the best [S]ARIMA[X] models in heterogeneous
panels with the help of {helpb arimaauto}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtarimau}
[{varlist}]
{ifin}
[{it:{help xtarimau##weight:weight}}]
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Panel wrapper}
{synopt:{opt pre:estimation(string)}}any command or program, defined with
        {cmd:program define}, including a series of commands, which will run
        prior to the model estimation for each time series{p_end}
{synopt:{opt post:estimation(string)}}any command or program, defined with
        {cmd:program define}, including a series of commands, which will run
        after the model estimation for each time series{p_end}
{synopt:{opt export(string)}}.ster file path, estimates will be appended

{syntab:Best model selection}
{synopt:{opt ic(string)}}model selection criterion for {helpb arima:[TS] arima}:
        {bf:"llf"} (maximization of the LLF),
        {bf:"aic"} (minimization of the AIC) or {bf:"sic"} (minimization
        of the SIC)  (by default: {bf:"aic"}){p_end}
{synopt:{opt stat:ionary}}limit the model space to stationary models only,
        ARIMA({it:p,0,q})({it:P,0,Q}) which will disable the automatic
        determination of {it:#d} with the help of {helpb dfgls:[TS] dfgls}
        and {helpb kpss}{p_end}
{synopt:{opt noseas:onal}}limit the model space to non-seasonal models only,
        ARIMA({it:p,d,q}) which will disable the automatic determination
        of {it:#D} with the help of {helpb hegy}{p_end}
{synopt:{opt nostep:wise}}switch to bulk estimation from the Hyndman-Khandakar
        algorithm{p_end}

{syntab:Tests-related}
{synopt:{opt l:evel(#)}}confidence level, constrained by the critical values of
        {helpb hegy}: {bf:90}, {bf:95} or {bf:99}
        (by default: {helpb clevel:c(level)}){p_end}
{synopt:{opt m:ode(string)}}lag selection criterion for unit root tests:
        {bf:"maic"}, {bf:"bic"} or {bf:"seq"} (by default: {bf:"maic"}){p_end}
{synopt:{helpb hegy##options:hegy(...)}}options directly passed to {helpb hegy}
        except {opt g:ls} (enabled by default, to disable specify {opt nog:ls}),
        {opth m:ode(string)} and {opth maxl:ag(#)} which will be ignored{p_end}
{synopt:{helpb dfgls##options:dfgls(...)}}options directly passed
        to {helpb dfgls:[TS] dfgls} except {opth maxl:ag(#)} which will
        be ignored{p_end}
{synopt:{helpb kpss##options:kpss(...)}}options directly passed to {helpb kpss}
        except {opth maxl:ag(#)} which will be ignored{p_end}
{synopt:{opt sd:test}}a test for heterogeneity, i.e., whether the standard
        deviations of #p, #d, #q, #P, #D, #Q across the panel are {bf:0}{p_end}

{syntab:ARIMA-related}
{synopt:{opt nocons:tant}}suppress constant term if both
        {opt arima(#p,#d,#q)} and {opt sarima(#P,#D,#Q,#s)} are specified{p_end}
{synopt:{opt arima(#p,#d,#q)}}specify ARIMA({it:p,d,q}) model for dependent
        variable which will disable the automatic determination of {it:#d}
        with the help of {helpb dfgls:[TS] dfgls} and {helpb kpss}{p_end}
{synopt:{opt sarima(#P,#D,#Q,#s)}}specify period-{it:#s} multiplicative
        seasonal ARIMA term which will disable the automatic determination
        of {it:#D} with the help of {helpb hegy}{p_end}
{synopt:{helpb arima##options:arima(...)}}options directly passed to 
        {helpb arima:[TS] arima} except {opth ar(numlist)}, {opth ma(numlist)},
        {cmd:mar(}{it:{help numlist}}{cmd:,} {it:#s}{cmd:)} and
        {cmd:mma(}{it:{help numlist}}{cmd:,} {it:#s}{cmd:)}} which will be
        ignored{p_end}

{syntab :Limits and maximum values}
{synopt:{opth  max(numlist)}}limit of {it:p} and {it:q}
        in ARIMA({it:p,d,q}) (by default: {bf:5 5}){p_end}
{synopt:{opth mmax(numlist)}}limit of {it:P} and {it:Q}
        in ARIMA({it:p,d,q})({it:P,D,Q}) (by default: {bf:2 2}){p_end}
{synopt:{opth invr:oot(real)}}limit of inverse characteristic roots
        in {helpb estat aroots} (by default: {bf:1/1.001}){p_end}
{synopt:{opth maxl:ag(#)}}maximum lag order to be used in unit root tests
        (by default: {bf:.} aka unlimited){p_end}
{synopt:{opth maxm:odels(#)}}maximum number of estimated models
        (by default: {bf:.} aka unlimited){p_end}
{synopt:{opth iter:ate(#)}}maximum number of iterations(influences convergence)
        (by default: {bf:100}){p_end}

{syntab :Reporting}
{synopt:{opth trace(#)}}print {helpb hegy}, {helpb dfgls:[TS] dfgls} and
        {helpb kpss} output if {bf:1} and {helpb arima:[TS] arima} output
        if {bf:2} (by default: {bf:0}){p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
The user must {opt tsset} the data before using {opt xtarimau};
see {manhelp tsset TS}.
{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators;
see {help tsvarlist}.
{p_end}
{p 4 6 2}
{opt by}, {opt collect}, {opt fp}, {opt rolling}, {opt statsby}, and {cmd:xi}
are {ul:not allowed}; see {help prefix}.{p_end}
{marker weight}{...}
{p 4 6 2}
{opt iweight}s are allowed; see {help weights}.
{p_end}
{p 4 6 2}
See {manhelp arima_postestimation TS:arima postestimation} for features
available after estimation.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtarimau} is a panel wrapper for {cmd:arimaauto} which is {it:de facto} an "augmented" Mata-written sister program to Christopher F. Baum's ARMA-limited
{helpb arimasel} with mutually consistent output, allowing for ARIMA({it:p,d,q})
and multiplicative seasonal ARIMA({it:p,d,q})({it:P,D,Q}) models, selecting the
best model based on the LLF, AIC or SIC, and returning its estimates at the same
time. However, unlike {helpb arimasel}, the selection is by default peformed
with the help of the Hyndman-Khandakar algorithm, first implemented in the
{browse "https://www.rdocumentation.org/search?q=auto.arima":{bf:auto.arima}}
function (part of of the "forecast" package) in the {bf: R language}.

{pstd}
{cmd:xtarimau} can therefore be considered an {bf:estimation command}, built on
top of {helpb arimaauto}, storing estimates under the name {bf:ts_#} or saving
them into a .ster file and returning the best estimated models in
{bf:r(models)}. The user can also access {bf:r(ictests)}, {bf:r(icarima)}, and
{help return:hidden} {bf:r(limits)}.

{pstd}
{ul:Stata-adjusted Hyndman-Khandakar algorithm:}

{pstd}
The model selection algorithm described in Hyndman and Khandakar (2008) is
based on a combination of a modified Canova-Hansen seasonal unit root test
(with an empirical formula for calculation of its critical values) and of the
KPSS unit root test, aimed at avoiding (alleged) overdifferencing caused
by tests which assume unit root in their null hypothesis such as {helpb hegy}
and {helpb dfuller:[TS] dfuller}. Since the Canova-Hansen test was unavailable
in {bf:Stata 17} and its implementation would have been a feat of its own,
the algorithm was "inverted" to work with more powerful GLS-based
{helpb hegy} and {helpb dfgls:[TS] dfgls} unit root tests with a correction
by the KPSS unit root test to prevent the mentioned overdifferencing aka large
{it:#d} in ARIMA({it:p,d,q}) and ARIMA({it:p,d,q})({it:P,D,Q}) models. The
user can disable GLS in {helpb hegy} and pass additional options to all the
three tests; see {help arimaauto##syntax:{it:options (syntax)}}.

{pstd}
{ul:Unit root tests:}

{pstd}
{helpb hegy} performs the Hylleberg, Engle, Granger, and Yoo (HEGY) (1990) test
for both monthly and quarterly data, allowing for generalized least-squares
(GLS) and ordinary least-squares (OLS) and detrending (controlled by the
{opt nog:ls} option). It automatically determines the lag length (order of
augmentation) based on the modified AIC (MAIC) (del Barrio Castro, Osborn, and
Taylor, 2016), Bayesian information criterion (BIC), and sequential t test
for the last augmentation lag (Hall, 1994; Ng and Perron, 2001). User may
control the deterministic terms with help of the {cmd:det()} option; see
{helpb hegy} for syntax and examples. The critical values are constructed
from the empirically estimated response surface (del Barrio Castro,
Bodnar, and Sans{c o'}, 2015).

{pstd}
{bf:NB} {cmd:xtarimau} only uses the {helpb hegy}'s t test for Nyquist
frequencies (t_S/2).

{pstd}
{helpb dfgls:[TS] dfgls} performs a modified Dickey-Fuller t test for a unit
root in which the series has been transformed by a generalized least-squares
regression. By default, a trend is included; see {helpb dfgls:[TS] dfgls}
for syntax and examples.

{pstd}
{helpb kpss} performs the Kwiatkowski, Phillips, Schmidt, Shin (KPSS, 1992)
test for stationarity of a time series. This test differs from
{helpb dfgls:[TS] dfgls}, by having a null hypothesis of stationarity. The
test may be conducted under the null of either trend stationarity
(the default) or level stationarity; see {helpb kpss} for syntax and
examples.

{pstd}
{bf:PS} The maximum lag length in the unit root tests is calculated with the
help of the Schwert (1989) formula(s) (the default) or {cmd:xtarimau}'s
{opth maxl:ag(#)} option.

{pstd}
{ul:Heterogeneity tests:}

{pstd}
A set of {helpb sdtesti} commands, called via the {bf:{opt sd:test}} option,
is used to test whether the standard deviations of #p, #d, #q, #P, #D, #Q in
{bf:r(models)} are equal to 0.

{marker options}{...}
{title:Options}

{phang}
For {helpb hegy:hegy(...)} see a list of
{help hegy##options:{it:hegy options}}

{phang}
For {helpb dfgls:dfgls(...)} see a list of
{help dfgls##options:{it:dfgls options}}

{phang}
For {helpb kpss:kpss(...)} see a list of
{help kpss##options:{it:kpss options}}

{phang}
For {helpb arima:arima(...)} see a list of
{help arima##options:{it:arima options}}

{marker examples}{...}
{title:Examples}

        panel data:
        {cmd:. sysuse xtline1.dta, clear}
        {cmd:. xtarimau calories, noseas}
        {cmd:. xtarimau calories, noseas nostep maxm(15) export(test)}
        {cmd:. xtarimau calories, noseas post(predict xb)}

{title:Author}

{pstd}
{bf:Ilya Bolotov}
{break}Prague University of Economics and Business
{break}Prague, Czech Republic
{break}{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
    Thanks for citing this software and my works on the topic:

{p 8 8 2}
    Bolotov, I. (2022). XTARIMAU: Stata module to find the best [S]ARIMA[X]
    models in heterogeneous panels with the help of arimaauto. Available from
    {browse "https://ideas.repec.org/c/boc/bocode/s459048.html"}.

{marker references}{...}
{title:References}

{phang}
del Barrio Castro, T., A. Bodnar, and A. Sans{c o'}. 2015. Numerical
distribution functions for seasonal unit root tests with OLS and GLS
detrending. Working Paper 73, DEA. 
{browse "http://dea.uib.es/digitalAssets/353/353054_w73.pdf"}.

{phang}
del Barrio Castro, T., D. R. Osborn, and A. M. R. Taylor. 2016. The
performance of lag selection and detrending methods for HEGY seasonal unit
root tests. {it:Econometric Reviews} 35: 122-168.

{phang}
Hall, A. 1994. Testing for a unit root in time series with pretest data-based
model selection.  {it:Journal of Business and Economic Statistics} 12: 461-470.

{phang}
Hylleberg, S., R. F. Engle, C. W. J. Granger, and B. S. Yoo. 1990. Seasonal
integration and cointegration. {it:Journal of Econometrics} 44: 215-238.

{phang}
Hyndman, R. J. and Y. Khandakar. 2008. Automatic time series forecasting: the
forecast package for R. {it:Journal of statistical software}, 27(1), 1-22.

{pstd}
Kwiatkowski, D., P. C. Phillips, P. Schmidt, and Y. Shin (1992). Testing the
null hypothesis of stationarity against the alternative of a unit root: How
sure are we that economic time series have a unit root?.
{it:Journal of econometrics}, 54(1-3), 159-178.

{phang}
Ng, S., and P. Perron. 2001. Lag length selection and the construction of unit
root tests with good size and power. {it:Econometrica} 69: 1519-1554.

{phang}
Rodrigues, P. M. M., and A. M. R. Taylor. 2007.  Efficient tests of the
seasonal unit root hypothesis. {it:Journal of Econometrics} 141: 548-573.

{phang}
Schwert, G. W. 1989. Tests for unit roots: A Monte Carlo investigation.
{it:Journal of Business and Economic Statistics} 2: 147-159.
