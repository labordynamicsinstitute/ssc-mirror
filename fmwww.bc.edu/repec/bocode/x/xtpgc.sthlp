{smcl}
{* *! version 1.0.0  06jun2026}{...}
{vieweralsosee "xtpdlib" "help xtpdlib"}{...}
{vieweralsosee "xtfpss" "help xtfpss"}{...}
{vieweralsosee "xtcipsm" "help xtcipsm"}{...}
{vieweralsosee "xtgcause (if installed)" "help xtgcause"}{...}
{viewerjumpto "Syntax" "xtpgc##syntax"}{...}
{viewerjumpto "Description" "xtpgc##description"}{...}
{viewerjumpto "Options" "xtpgc##options"}{...}
{viewerjumpto "Methods" "xtpgc##methods"}{...}
{viewerjumpto "Interpretation" "xtpgc##interp"}{...}
{viewerjumpto "Cautions" "xtpgc##cautions"}{...}
{viewerjumpto "Examples" "xtpgc##examples"}{...}
{viewerjumpto "Stored results" "xtpgc##results"}{...}
{viewerjumpto "References" "xtpgc##references"}{...}
{viewerjumpto "Author" "xtpgc##author"}{...}
{title:Title}

{phang}
{bf:xtpgc} {hline 2} Bootstrap panel Granger causality in heterogeneous mixed panels
(Emirmahmutoglu & Kose 2011 Fisher; Konya 2006 SUR-Wald)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtpgc} {varlist} {ifin} [{cmd:,} {it:options}]

{p 4 4 2}{it:varlist} contains 2 or more time-series variables. All ordered pairs
(cause -> effect) are tested. {cmd:method(konya)} requires exactly 2 variables.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Test}
{synopt:{opt meth:od(fisher|konya)}}causality test; default {cmd:fisher}{p_end}
{synopt:{opt maxl:ags(#)}}maximum VAR/SUR lag order considered; default {cmd:maxlags(4)}{p_end}
{synopt:{opt dmax(#)}}extra (Toda-Yamamoto) lags = max integration order; default {cmd:dmax(1)} ({cmd:fisher} only){p_end}
{synopt:{opt ic(#)}}lag-selection criterion: 1=AIC, 2=SIC; default {cmd:ic(1)}{p_end}

{syntab:Bootstrap}
{synopt:{opt b:reps(#)}}bootstrap replications; default {cmd:breps(1000)}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt nob:oot}}report asymptotic results only (no bootstrap critical values){p_end}

{syntab:Reporting & graph}
{synopt:{opt gr:aph}}plot the causality results{p_end}
{synopt:{opt nopr:intind}}suppress per-unit individual results ({cmd:fisher}){p_end}
{synopt:{it:graph_options}}options passed to the graph{p_end}
{synoptline}

{phang}The data must be {helpb xtset} and the panel {bf:balanced}.
{cmd:xtpgc} is part of the {helpb xtpdlib} library.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpgc} tests for Granger (non-)causality between variables in heterogeneous mixed
panels, allowing for cross-section dependence through a residual-resampling bootstrap
that preserves the contemporaneous correlation across units. Two tests are available.

{pstd}
{bf:Fisher} ({help xtpgc##EK2011:Emirmahmutoglu and Kose, 2011}). A level VAR is fitted
for each unit with {it:k_i} + {it:dmax} lags (the lag-augmented / Toda-Yamamoto approach,
so the Wald statistics are valid regardless of the integration and cointegration
properties). The individual Wald statistic for non-causality has a chi-squared
distribution with {it:k_i} degrees of freedom; the panel statistic combines the
individual p-values via Fisher's (1932) method,

{p 12 12 2}{cmd:Fisher = -2 * sum_i ln(p_i) ~ chi2(2N)}.

{pstd}
Because cross-sectional dependence invalidates the asymptotic distribution, bootstrap
critical values are computed (the empirical distribution of the Fisher statistic under
the non-causality null). This is the test used in
{help xtpgc##KNA2011:Kar, Nazlioglu and Agir (2011)}.

{pstd}
{bf:Konya SUR-Wald} ({help xtpgc##K2006:Konya, 2006}). A two-equation system is estimated
by Seemingly Unrelated Regressions across all units, giving a {it:country-specific} Wald
statistic for each unit together with its own bootstrap critical values, so causality can
differ across units.

{pstd}
{cmd:xtpgc} is a Stata translation of the GAUSS routines {bf:pd_cause},
{bf:PDcaus_Fisher} and {bf:PDcaus_SURwald} from S. Nazlioglu's {bf:TSPDLIB}. The
Dumitrescu-Hurlin (2012) Zbar test (the third option of pd_cause) is available via the
community command {helpb xtgcause}.


{marker options}{...}
{title:Options}

{phang}{opt method(fisher|konya)} selects the test. {cmd:fisher} (default) is the
Emirmahmutoglu-Kose panel Fisher test for any number of variables; {cmd:konya}
(synonym {cmd:surwald}) is the Konya SUR-Wald test for exactly two variables.

{phang}{opt maxlags(#)} is the maximum lag order searched by the information criterion.

{phang}{opt dmax(#)} is the number of extra unrestricted lags added for the
Toda-Yamamoto augmentation (the maximum suspected order of integration). Used by
{cmd:fisher} only.

{phang}{opt ic(#)} chooses 1 = Akaike or 2 = Schwarz for lag selection.

{phang}{opt breps(#)} sets the number of bootstrap replications.

{phang}{opt seed(#)} fixes the seed for reproducible bootstrap results.

{phang}{opt noboot} skips the bootstrap and reports only asymptotic results (the Fisher
chi-squared p-value; Konya Wald with no critical values).

{phang}{opt graph} draws the results: for {cmd:fisher}, a bar chart of the panel Fisher
statistic for each causal direction with the bootstrap 5% critical value; for
{cmd:konya}, per-unit Wald statistics against the unit-specific 5% bootstrap critical
value.

{phang}{opt noprintind} suppresses the per-unit table under {cmd:fisher}.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Bootstrap.} Both tests use a fixed-design residual bootstrap. The model is
re-estimated under the non-causality null (the cause's lags are removed from the effect
equation); the centered residuals are resampled jointly across units (the same time
indices are drawn for every unit) to preserve cross-section dependence; a bootstrap
dependent variable is built from the restricted fit plus the resampled residuals; and
the test statistic is recomputed on the original regressor design. Repeating this many
times yields the bootstrap distribution and its percentiles.


{marker interp}{...}
{title:Interpretation}

{pstd}
{bf:The null} for every reported block is "{it:cause} does not Granger-cause {it:effect}".
Rejection means there is predictive (Granger) causality from the cause to the effect.

{pstd}
{bf:Fisher (panel) decision.} Use the {bf:bootstrap} critical values, not the asymptotic
chi-squared p-value, when cross-section dependence is present (the usual case) {hline 1}
the asymptotic distribution is invalid under dependence. Reject the panel non-causality
null at 5% when {cmd:Fisher statistic > bootstrap 5% CV}. The asymptotic p-value
[chi2(2N)] is printed for reference and is the right one only under cross-sectional
independence ({opt noboot}).

{pstd}
{bf:Reading the per-unit Fisher table.} Each unit contributes a Wald statistic
(chi-squared with {it:k_i} d.f.) and its p-value; the panel Fisher statistic combines
these p-values. Units with small p-values are the ones generating panel-level causality.
Because the VAR is lag-augmented (Toda-Yamamoto), the Wald statistics are valid whatever
the integration/cointegration status, so you do {it:not} need to pre-difference.

{pstd}
{bf:Konya decision (per unit).} Konya gives a {it:country-specific} answer: for each unit,
reject non-causality at 5% when {cmd:Wald > 5% CV} (flagged with {bf:*} in the table). This
lets causality differ across units {hline 1} report which units show causality rather than
a single panel verdict.

{pstd}
{bf:Direction.} Run the command and read each "H0: A does not cause B" block separately;
two-way (feedback) causality is present when both directions reject, one-way when only one
does, and independence when neither does.


{marker cautions}{...}
{title:Cautions}

{phang}o {bf:Balanced panel only}, declared with {helpb xtset}.{p_end}

{phang}o {bf:Bootstrap is essential under cross-section dependence.} Keep {opt noboot} only
for a quick look or when units are genuinely independent. Use enough replications
({opt breps(1000)} or more for final results; the examples use small values for speed) and
set {opt seed()} for reproducibility.{p_end}

{phang}o {bf:dmax must cover the integration order.} {opt dmax()} is the number of extra
unrestricted lags in the lag-augmented VAR and must be >= the maximum order of integration
of the variables (run unit-root tests first; {opt dmax(1)} is typical for I(1) data). Too
small a {opt dmax()} invalidates the Toda-Yamamoto argument.{p_end}

{phang}o {bf:Lag length.} {opt maxlags()} bounds the VAR/SUR order chosen by AIC/SIC.
Larger systems (many variables or units) need more degrees of freedom: ensure
T is comfortably larger than (number of variables) x (maxlags+dmax).{p_end}

{phang}o {bf:Konya needs exactly two variables} and is computationally heavier (SUR with a
country-specific bootstrap); reduce {opt breps()} while exploring.{p_end}

{phang}o {bf:Number of directions.} With K variables {cmd:method(fisher)} tests all
K(K-1) ordered pairs; output can be long. Use {opt noprintind} to hide the per-unit tables.{p_end}

{phang}o {bf:Bootstrap scheme.} The implementation uses a fixed-design residual bootstrap
that resamples centred residuals jointly across units (preserving cross-section
dependence). The test statistics and Fisher combination match the published method; the
bootstrap follows the Emirmahmutoglu-Kose / Konya design.{p_end}

{phang}o {bf:Dumitrescu-Hurlin.} For the Zbar/Zbar-tilde panel non-causality test, use the
community command {helpb xtgcause}; it is not duplicated here.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Panel Fisher causality between two variables, reproducible bootstrap{p_end}
{phang2}{cmd:. xtpgc invest mvalue, method(fisher) maxlags(2) dmax(1) breps(1000) seed(123)}{p_end}

{pstd}Three variables (all six directions), hide per-unit tables, with the summary graph{p_end}
{phang2}{cmd:. xtpgc invest mvalue kstock, method(fisher) maxlags(2) dmax(1) breps(500) noprintind graph}{p_end}

{pstd}Konya SUR-Wald with country-specific bootstrap critical values{p_end}
{phang2}{cmd:. xtpgc invest mvalue, method(konya) maxlags(2) breps(1000) seed(1) graph}{p_end}

{pstd}Quick asymptotic Fisher only (no bootstrap){p_end}
{phang2}{cmd:. xtpgc invest mvalue kstock, method(fisher) maxlags(2) dmax(1) noboot}{p_end}

{pstd}Use the stored results (directions are rows of r(pairs)){p_end}
{phang2}{cmd:. xtpgc invest mvalue, method(fisher) breps(500) seed(1)}{p_end}
{phang2}{cmd:. matrix list r(pairs)}{p_end}
{phang2}{cmd:. matrix list r(units)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtpgc} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel dimensions{p_end}

{p2col 5 18 22 2: Matrices (method fisher)}{p_end}
{synopt:{cmd:r(pairs)}}one row per direction: effect idx, cause idx, Fisher, asy p-value, 10%/5%/1% bootstrap CV{p_end}
{synopt:{cmd:r(units)}}one row per direction x unit: direction, id, lag, Wald, p-value{p_end}

{p2col 5 18 22 2: Matrices (method konya)}{p_end}
{synopt:{cmd:r(pairs)}}one row per direction: effect idx, cause idx{p_end}
{synopt:{cmd:r(units)}}direction, id, Wald, 1%/5%/10% bootstrap CV{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(method)}}{cmd:fisher} or {cmd:konya}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtpgc}{p_end}


{marker references}{...}
{title:References}

{marker EK2011}{...}
{phang}Emirmahmutoglu, F., and N. Kose. 2011. Testing for Granger causality in
heterogeneous mixed panels. {it:Economic Modelling} 28: 870-876.{p_end}

{marker K2006}{...}
{phang}Konya, L. 2006. Exports and growth: Granger causality analysis on OECD countries
with a panel data approach. {it:Economic Modelling} 23: 978-992.{p_end}

{marker KNA2011}{...}
{phang}Kar, M., S. Nazlioglu, and H. Agir. 2011. Financial development and economic
growth nexus in the MENA countries: bootstrap panel Granger causality analysis.
{it:Economic Modelling} 28: 685-693.{p_end}

{phang}Dumitrescu, E.-I., and C. Hurlin. 2012. Testing for Granger non-causality in
heterogeneous panels. {it:Economic Modelling} 29: 1450-1460.{p_end}

{phang}Toda, H. Y., and T. Yamamoto. 1995. Statistical inference in vector
autoregressions with possibly integrated processes. {it:Journal of Econometrics}
66: 225-250.{p_end}


{marker author}{...}
{title:Author}

{pstd}Stata implementation:{p_end}
{pmore}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Original GAUSS code (TSPDLIB):{p_end}
{pmore}Saban Nazlioglu, Pamukkale University, snazlioglu@pau.edu.tr{p_end}

{pstd}See also:{p_end}
{pmore}{helpb xtpdlib}, {helpb xtfpss}, {helpb xtcipsm}{p_end}
