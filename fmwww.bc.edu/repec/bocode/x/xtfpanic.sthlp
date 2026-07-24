{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtfpanic methods" "help xtfpanic_methods"}{...}
{vieweralsosee "xtpanic" "help xtpanic"}{...}
{vieweralsosee "xtflexur (library)" "help xtflexur"}{...}
{viewerjumpto "Syntax" "xtfpanic##syntax"}{...}
{viewerjumpto "Description" "xtfpanic##description"}{...}
{viewerjumpto "Options" "xtfpanic##options"}{...}
{viewerjumpto "Examples" "xtfpanic##examples"}{...}
{viewerjumpto "Stored results" "xtfpanic##results"}{...}
{viewerjumpto "Interpreting the output" "xtfpanic##interpret"}{...}
{viewerjumpto "References" "xtfpanic##refs"}{...}
{title:Title}

{phang}
{bf:xtfpanic} {hline 2} Fourier-PANIC panel unit root test: PANIC with smooth
(Fourier) structural breaks and a common factor structure (Nazlioglu et al. 2023)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtfpanic} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}The data must be {helpb xtset} as a {bf:strongly balanced} panel.{p_end}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt f:req(#)}}maximum cumulative Fourier frequency (m): 1 (default), 2 or 3{p_end}
{synopt:{opt k:max(#)}}maximum number of common factors (default 5){p_end}
{synopt:{opt icf:actor(#)}}factor-number criterion: 1=PCp, 2=ICp (default), 3=AIC/BIC{p_end}
{synopt:{opt p:max(#)}}maximum lags for the LM regression (default 3){p_end}
{synopt:{opt icl:ag(#)}}lag criterion: 1=AIC, 2=SIC, 3=t-sig (default){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfpanic} implements the panel unit root test of Nazlioglu et al. (2023),
which combines two ideas: a {bf:Fourier} approximation to capture smooth,
unknown-form structural breaks, and the {bf:PANIC} procedure of Bai and Ng
(2004) to control for cross-sectional dependence through common factors. The test
therefore allows for {it:both} multiple gradual breaks {it:and} strong
cross-correlation, without having to specify the number, location, or form of the
breaks.

{pstd}
The steps are: (i) difference the data; (ii) remove a flexible Fourier trend from
each differenced series; (iii) extract the common factors from the
Fourier-detrended differences by principal components; (iv) form the
idiosyncratic component; (v) run a Fourier-augmented LM unit root regression on
each unit's cumulated idiosyncratic component, with the estimated factors as
additional regressors; (vi) pool the p-values into the Fisher-type panel
statistics {bf:P} and {bf:Pm} using the paper's response surface.

{pstd}
{cmd:xtfpanic} is part of the {helpb xtflexur:xtflexur} library and shares its
common-factor engine with {helpb xtpanic}. See {helpb xtfpanic_methods:help
xtfpanic methods} for the formulas.

{marker options}{...}
{title:Options}

{phang}{opt freq(#)} sets the maximum {it:cumulative} Fourier frequency m: {cmd:1}
uses frequency 1 only (default), {cmd:2} uses frequencies 1 and 2, {cmd:3} uses
1, 2 and 3. Higher m captures more break flexibility at the cost of power.

{phang}{opt kmax(#)}, {opt icfactor(#)} govern the common-factor estimation (as in
{helpb xtpanic}): maximum factors (default 5) and the Bai-Ng (2002) criterion
(default ICp).

{phang}{opt pmax(#)}, {opt iclag(#)} govern the LM-regression lag length: maximum
lags (default 3) and the selection rule ({cmd:3}=general-to-specific t-test at
10%, the default).

{marker examples}{...}
{title:Examples}

{pstd}Fourier-PANIC with a single frequency:{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtfpanic lhealth, freq(1)}{p_end}

{pstd}Cumulative frequencies 1 and 2:{p_end}
{phang2}{cmd:. xtfpanic lhealth, freq(2) kmax(5) pmax(3)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtfpanic} is {cmd:rclass} and stores:{p_end}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(P)}, {cmd:r(P_p)}}Fisher chi-square panel statistic and p-value{p_end}
{synopt:{cmd:r(Pm)}, {cmd:r(Pm_p)}}standardized (normal) panel statistic and p-value{p_end}
{synopt:{cmd:r(nf)}}estimated number of common factors{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel and time dimensions{p_end}

{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(units)}}per-unit {it:id}, Fourier-LM statistic, p-value, lags{p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtfpanic}{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
The null is a unit root in the {it:idiosyncratic} component. The pooled tests
{bf:P} (Fisher chi-square) and {bf:Pm} (standardized normal) {bf:reject for large
values / small p-values}. Because the test removes both smooth breaks and common
factors, a non-rejection is strong evidence of genuine non-stationarity that
cannot be explained away by breaks or cross-sectional dependence. In the paper's
healthcare application, allowing for both features leaves the null of a unit root
un-rejected, unlike the simpler tests.

{marker refs}{...}
{title:References}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.{p_end}

{phang}Enders, W., and J. Lee. 2012. The flexible Fourier form and Dickey-Fuller
type unit root tests. {it:Economics Letters} 117: 196-199.{p_end}

{phang}Nazlioglu, S., et al. 2023. Smooth structural changes and common factors in
nonstationary panel data: an analysis of healthcare expenditures. {it:Econometric
Reviews} 42(1): 78-97.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS code (appl3_PANIC_fourier) by S. Nazlioglu
et al.; validated byte-for-byte against Table 3 of Nazlioglu et al. (2023). Part
of the {helpb xtflexur:xtflexur} library.{p_end}
