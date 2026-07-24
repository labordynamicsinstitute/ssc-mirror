{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpanic methods" "help xtpanic_methods"}{...}
{vieweralsosee "xtflexur (library)" "help xtflexur"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtpanic##syntax"}{...}
{viewerjumpto "Description" "xtpanic##description"}{...}
{viewerjumpto "Options" "xtpanic##options"}{...}
{viewerjumpto "Examples" "xtpanic##examples"}{...}
{viewerjumpto "Stored results" "xtpanic##results"}{...}
{viewerjumpto "Interpreting the output" "xtpanic##interpret"}{...}
{viewerjumpto "Remarks" "xtpanic##remarks"}{...}
{viewerjumpto "References" "xtpanic##refs"}{...}
{title:Title}

{phang}
{bf:xtpanic} {hline 2} PANIC panel unit root test (Bai & Ng 2004): tests the
idiosyncratic component after extracting common factors by principal components

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtpanic} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}The data must be {helpb xtset} as a {bf:strongly balanced} panel.{p_end}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(string)}}deterministic terms: {cmd:constant} (default) or
{cmd:trend}{p_end}
{synopt:{opt k:max(#)}}maximum number of common factors (default 5){p_end}
{synopt:{opt icf:actor(#)}}factor-number criterion: 1=PCp, 2=ICp (default), 3=AIC/BIC{p_end}
{synopt:{opt p:max(#)}}maximum lags for the idiosyncratic ADF (default 3){p_end}
{synopt:{opt icl:ag(#)}}ADF lag criterion: 1=AIC, 2=SIC, 3=t-sig (default){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpanic} implements the {bf:PANIC} procedure of Bai and Ng (2004) — Panel
Analysis of Nonstationarity in Idiosyncratic and Common components. Rather than
testing the observed series directly, PANIC first extracts the {it:common
factors} by principal components on the differenced data, and then tests the
{it:idiosyncratic} component for a unit root. This makes the panel test robust to
strong cross-sectional dependence of an unknown form.

{pstd}
The steps are: (i) difference the data (and, for the trend model, demean the
differences); (ii) estimate the number of common factors by the Bai-Ng (2002)
information criterion; (iii) extract the factors and loadings by principal
components; (iv) cumulate the idiosyncratic residuals; (v) run an augmented
Dickey-Fuller regression {it:without} deterministic terms on each unit's
idiosyncratic component; (vi) pool the p-values into the Fisher-type panel
statistics {bf:P} and {bf:Pm}.

{pstd}
{cmd:xtpanic} is part of the {helpb xtflexur:xtflexur} library and shares its
common-factor engine with the other factor-based panel tests in that library.
See {helpb xtpanic_methods:help xtpanic methods} for the formulas.

{marker options}{...}
{title:Options}

{phang}{opt model(string)} chooses the deterministic specification of the {it:levels}:
{cmd:constant} (the differenced data are used as is) or {cmd:trend} (the
differences are demeaned, removing the drift). Both use the Dickey-Fuller
no-constant distribution for the idiosyncratic ADF, as in Bai and Ng (2004).

{phang}{opt kmax(#)} is the maximum number of common factors considered by the
information criterion (default 5).

{phang}{opt icfactor(#)} selects the Bai-Ng (2002) criterion used to estimate the
number of factors: {cmd:1}=PCp, {cmd:2}=ICp (default), {cmd:3}=AIC/BIC. The number
of factors reported is the one chosen by the second column of the criterion (ICp2).

{phang}{opt pmax(#)} and {opt iclag(#)} govern the per-unit ADF lag length:
maximum lags (default 3) and the selection rule ({cmd:1}=AIC, {cmd:2}=SIC,
{cmd:3}=general-to-specific t-significance at 10%, the default).

{marker examples}{...}
{title:Examples}

{pstd}Panel unit root test with a constant:{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtpanic lgdp}{p_end}

{pstd}Trend model, up to 5 factors chosen by ICp, ADF lags by t-significance:{p_end}
{phang2}{cmd:. xtpanic lgdp, model(trend) kmax(5) icfactor(2) pmax(3) iclag(3)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtpanic} is {cmd:rclass} and stores:{p_end}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(P)}, {cmd:r(P_p)}}Fisher chi-square panel statistic and p-value{p_end}
{synopt:{cmd:r(Pm)}, {cmd:r(Pm_p)}}standardized (normal) panel statistic and p-value{p_end}
{synopt:{cmd:r(nf)}}estimated number of common factors{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel and time dimensions{p_end}

{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(units)}}per-unit {it:id}, ADF statistic, p-value, lags{p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtpanic}{p_end}
{synopt:{cmd:r(model)}}deterministic model{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
The null hypothesis is that the {it:idiosyncratic} component contains a unit root
(the series is non-stationary once common factors are removed). The pooled tests
{bf:P} (Fisher chi-square, 2N degrees of freedom) and {bf:Pm} (standardized to
N(0,1)) {bf:reject for large values / small p-values}. Rejection means the
idiosyncratic components are stationary.

{pstd}
Because PANIC separates common from idiosyncratic dynamics, a rejection here is
{it:not} contaminated by cross-sectional dependence: the common factors, which
carry most of the co-movement, are removed before testing. The per-unit table
shows which series drive the panel result.

{marker remarks}{...}
{title:Remarks}

{phang}o Requires a strongly balanced panel (no gaps). Difference-based factor
extraction needs a common time span across units.{p_end}

{phang}o The idiosyncratic ADF is run without deterministic terms in both models;
the deterministics of the levels are handled by the differencing/demeaning and by
the common factors (Bai and Ng 2004). p-values use the finite-sample
Dickey-Fuller (no constant) response surface.{p_end}

{phang}o The command tests only the idiosyncratic component. Tests of the common
factors themselves (MQ statistics) can be added; see the methods page.{p_end}

{marker refs}{...}
{title:References}

{phang}Bai, J., and S. Ng. 2002. Determining the number of factors in approximate
factor models. {it:Econometrica} 70: 191-221.{p_end}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.{p_end}

{phang}Nazlioglu, S., et al. 2023. Smooth structural changes and common factors in
nonstationary panel data: an analysis of healthcare expenditures. {it:Econometric
Reviews} 42(1): 78-97.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS routine {cmd:BNG_PANIC} (TSPDLIB) by
S. Nazlioglu; validated byte-for-byte against Table 3 of Nazlioglu et al. (2023).
Part of the {helpb xtflexur:xtflexur} library.{p_end}
