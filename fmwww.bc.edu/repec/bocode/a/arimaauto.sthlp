{smcl}
{* *! version 1.0.6  07oct2022}{...}
{vieweralsosee "[TS] arima" "mansection TS arima"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] arima postestimation" "help arima postestimation"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "arimaauto##syntax"}{...}
{viewerjumpto "Description" "arimaauto##description"}{...}
{viewerjumpto "Options" "arimaauto##options"}{...}
{viewerjumpto "Methods and formulas" "arimaauto##methods"}{...}
{viewerjumpto "Remarks" "arimaauto##remarks"}{...}
{viewerjumpto "Examples" "arimaauto##examples"}{...}
{viewerjumpto "References" "arimaauto##references"}{...}
{p2colset 1 15 17 2}{...}

{title:Title}
{phang}
{bf:arimaauto} {hline 2} Finds the best {helpb arima:[TS] arima} model with the
help of a Stata-adjusted Hyndman-Khandakar (2008) algorithm through stepwise
traversing of the model space or a bulk estimation

{title:Requirements}
{phang}
{net sj 16-3 st0453:{bf:hegy}}: Hylleberg et al. (1990) seasonal unit-root tests
with OLS and GLS detrending (Rodrigues and Taylor 2007) and lag-length selection
based on MAIC, AIC, BIC, and the sequential method by Tomás del Barrio Castro,
Andrii Bodnar and Andreu Sansó, University of the Balearic Islands Palma, Spain.

{phang}
{net sj 6-3 sts15_2:{bf:kpss}}: Kwiatkowski et al. (1992) tests for stationarity
of a time series  by Christopher F. Baum, Boston College, U.S.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:arimaauto}
[{varlist}]
{ifin}
[{it:{help arimaauto##weight:weight}}]
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}

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
The user must {opt tsset} the data before using {opt arimaauto};
see {manhelp tsset TS}.
{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators;
see {help tsvarlist}.
{p_end}
{p 4 6 2}
{opt by}, {opt collect}, {opt fp}, {opt rolling}, {opt statsby}, and {cmd:xi}
are allowed; see {help prefix}.{p_end}
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
{cmd:arimaauto} is {it:de facto} an "augmented" Mata-written sister program
to Christopher F. Baum's ARMA-limited {helpb arimasel} with mutually consistent
output, allowing for ARIMA({it:p,d,q}) and multiplicative seasonal
ARIMA({it:p,d,q})({it:P,D,Q}) models, selecting the best model based on
the LLF, AIC or SIC, and returning its estimates at the same time. However,
unlike {helpb arimasel}, the selection is by default performed with the help of 
the Hyndman-Khandakar algorithm, first implemented in the
{browse "https://www.rdocumentation.org/search?q=auto.arima":{bf:auto.arima}}
function (part of the "forecast" package) in the {bf: R language}.

{pstd}
{cmd:arimaauto} can therefore be considered an {bf:estimation command}, built
on top of {helpb arima:[TS] arima}, returning the standard {helpb arimasel}
output in {bf:r(...)}, performed tests in {bf:r(tests)}, and estimated models
in {bf:r(models)}. The user can also access {bf:r(ictests)}, {bf:r(icarima)},
and {help return:hidden} {bf:r(limits)}.

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
{bf:NB} {cmd:arimaauto} only uses the {helpb hegy}'s t test for Nyquist
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
help of the Schwert (1989) formula(s) (the default) or {cmd:arimaauto}'s
{opth maxl:ag(#)} option.

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

{marker methods}{...}
{title:Methods and formulas}

{pstd}
{ul:Bulk estimation:}

{pstd}
The bulk estimation (activated with the {opt nostep:wise} option in command
(see {help arimaauto##syntax:{it:options (syntax)}}) is based on a large
{bf:model space} generated from combinations of vectors of {it:p}, {it:q},
{it:P} and {it:Q} with values lying in the range {it:<0, limit>}. For
example, the default non-seasonal "bulk" model space includes
36 models and the seasonal one 324 models already. Therefore, caution
and the use of {opth maxm:odels(#)} is advisable.

{pstd}
{bf:NB} Some models may take a long time to converge or the optimizer may
even become stuck on flat regions with repeated {it:"(backed up)"} messages
(if {opth trace(2)} was specified). The user is advised to press the
{bf:break key} in such cases.

{pstd}
{bf:PS} To match the {helpb arimasel} command, the user should not forget
to increase the inverse characteristic root limit to 1 with the help of
{opth invr:oot(1)}.

{pstd}
{ul:Stepwise traversing:}

{pstd}
Both the Stata-adjusted and the original Hyndman-Khandakar algorithm consist of
two steps, the second of which is iterated.

{pstd}
{bf:Step 1:} Four initial models are considered as the {bf:model space} unless
{opt arima(#p,#d,#q)} and/or {opt sarima(#P,#D,#Q,#s)} are specified:

{pstd}
{break}{bind:    • }{bf:ARIMA({it:2,d,2})} if {it:#s} = 0 and
{bf:ARIMA({it:2,d,2})({it:1,D,1})} if {it:#s} ≥ 4
{break}{bind:    • }{bf:ARIMA({it:0,d,0})} if {it:#s} = 0 and
{bf:ARIMA({it:0,d,0})({it:0,D,0})} if {it:#s} ≥ 4
{break}{bind:    • }{bf:ARIMA({it:1,d,0})} if {it:#s} = 0 and
{bf:ARIMA({it:1,d,0})({it:1,D,0})} if {it:#s} ≥ 4
{break}{bind:    • }{bf:ARIMA({it:0,d,1})} if {it:#s} = 0 and
{bf:ARIMA({it:0,d,1})({it:0,D,1})} if {it:#s} ≥ 4

{pstd}
Otherwise, the algorithm starts with eventual combinations of the "specified"
and default terms or with a single model. If {it:d + D ≤ 1}, the model(s)
is(are) fitted with a {it:constant} or else the {it:constant} is omitted.

{pstd}
{bf:Step 2:} Out of the {bf:model space}, the model with the biggest LLF,
smallest AIC or smallest SIC (based on what is set in
{help arimaauto##syntax:{it:options (syntax)}}) is selected and is called
the {bf:"current" model}, of which thirteen variations are considered:

{pstd}
{break}{bind:    • }where one of {it:p}, {it:q}, {it:P} and {it:Q}
varies by ±1 from the {bf:"current" model};
{break}{bind:    • }where {it:p} and {it:q} both vary by ±1
from the {bf:"current" model};
{break}{bind:    • }where {it:P} and {it:Q} both vary by ±1
from the {bf:"current" model};
{break}{bind:    • }where the {it:constant} is excluded/included
if present/absent in the {bf:"current" model}.

{pstd}
This step is iterated until no better {bf:"current" model} can be found.

{pstd}
{ul:Default limits:}

{pstd}
The default limits of the Hyndman-Khandakar algorithm are {it:p ≤ 5},
{it:q ≤ 5}, {it:P ≤ 2}, {it:Q ≤ 2}, every {it:characteristic root ≥ 1.001} (in
absolute value), and an error-free fit of the model, which can be changed with 
the help of {cmd:arimaauto}'s {help arimaauto##syntax:{it:options (syntax)}}.

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:arimaauto} is an interface for the Mata class {bf:ARIMAAuto} (stored in
the {bf:larimaauto.mlib} file) which can be {bind:{bf:a)} extended} via
inheritance and {bind:{bf:b)} used} as a base for third
programs. {bf:ARIMAAuto} stores several types of variables in an associative
array (of which it is itself a child) declared with:

        {cmd:. mata: AA = ARIMAAuto()}

{pstd}
Contents of variables are stored and read with:

        {cmd:. mata: AA.put("key", value)}
        {cmd:. mata: AA.get("key")}

{pstd}
where {bf:"key"} is the name of the variable.

{pstd}
The variables are {bf:varlist} - [{varlist}] (string scalar), {bf:ifin} -
concatenated {ifin} (string scalar), {bf:iw} - [{it:{help weight}}]
(string scalar), {bf:o_*} - options (string scalar), {bf:f_*} - flags
(real scalar), {bf:level} - level (real scalar), {bf:mode} and {bf:ic} -
information criteria (string scalar), and finally {bf:L}, {bf:T}, and
{bf:MS} - real matrices of limits, tests, and models.

{pstd}
{bf:NB} The variables should be declared in the above given order.

{pstd}
{break}{bind:{bf:L} } is a {bind:(1 x 8)} matrix/vector of which {bf:r(limits)}
is a transposed copy, i.e. {it:r(limits) = AA.get("L")'}
{break}{bind:{bf:T} } is a {bind:(. x 6)} matrix of which {bf:r(tests)} is
a copy, i.e. {it:r(tests) = AA.get("T")}
{break}{bf:MS} is a {bind:(. x 12)} matrix of which {bf:r(models)} is
a reduced copy, i.e. {it:r(tests) = AA.get("MS")[,(1,3,4,6,8,10,11,12)]}. The
left out columns are {it:#d}, {it:#D}, {it:#s}, and {it:constant} (in the given
order).

{pstd}
{bf:NB} The example of their use can be found in the {bf:arimaauto.ado} file.

{pstd}
{bf:PS} {bf:ARIMAAuto} includes a virtual function {bf:get_cv_seas()} returning
a real matrix of critical values {bind:{it:(test x 0.01,0.05,0.10)}} for the
{helpb hegy} test (second row is retrieved), which can be replaced in an
eventual child class when a different test is required (the second row rule must
be observed, for example, coding {it:AA.put("T", J(1,6,.))} in the beginning)
together with the other variables). {bf:ARIMAAuto} considers unit root to be
present if {it:statistic > critical value}, hence signs may need to be adjusted
for unit root tests other than {helpb hegy}, {helpb dfgls:[TS] dfgls}, and
{helpb kpss}.

{pstd}
{bf:PSS} All estimations in {bf:ARIMAAuto} are performed under {bf:version 15}.

{marker examples}{...}
{title:Examples}

        quarterly data:
        {cmd:. sysuse gnp96.dta, clear}
        {cmd:. arimaauto gnp96}
        {cmd:. arimaauto gnp96, nostep maxm(15)}

        monthly data:
        {cmd:. webuse air2.dta, clear}
        {cmd:. arimaauto air, sarima(0,1,0,12)}

{title:Author}

{pstd}
{bf:Ilya Bolotov}
{break}Prague University of Economics and Business
{break}Prague, Czech Republic
{break}{browse "mailto:ilya.bolotov@vse.cz":ilya.bolotov@vse.cz}

{pstd}
    Thanks for citing this software and my works on the topic:

{p 8 8 2}
    Bolotov, I. (2022). ARIMAAUTO: Stata module to find the best ARIMA model
    with the help of a Stata-adjusted Hyndman-Khandakar (2008) algorithm.
    Available from {browse "https://ideas.repec.org/c/boc/bocode/s459043.html"}.

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
