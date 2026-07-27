{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtfaclm methods" "help xtfaclm_methods"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtbreaklm" "help xtbreaklm"}{...}
{vieweralsosee "xtpstat" "help xtpstat"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtfaclm##syntax"}{...}
{viewerjumpto "Description" "xtfaclm##description"}{...}
{viewerjumpto "Options" "xtfaclm##options"}{...}
{viewerjumpto "Examples" "xtfaclm##examples"}{...}
{viewerjumpto "Stored results" "xtfaclm##results"}{...}
{viewerjumpto "Interpreting the output" "xtfaclm##interpret"}{...}
{viewerjumpto "References" "xtfaclm##refs"}{...}
{title:Title}

{phang}
{bf:xtfaclm} {hline 2} Factor-augmented panel LM unit-root test with two
structural breaks (PANIC + Lee-Strazicich)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtfaclm} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}The data must be {helpb xtset} as a {bf:strongly balanced} panel.{p_end}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(string)}}break specification: {cmd:constant} (level breaks,
default) or {cmd:trend} (level & trend breaks){p_end}
{synopt:{opt k:max(#)}}maximum number of common factors (default 5){p_end}
{synopt:{opt icf:actor(#)}}factor-number criterion: 1=PCp, 2=ICp (default){p_end}
{synopt:{opt p:max(#)}}maximum augmentation lag (default 5){p_end}
{synopt:{opt icl:ag(#)}}lag selection: 1=AIC, 2=BIC (default), 3=t-stat{p_end}
{synopt:{opt t:rim(#)}}break-location trimming fraction (default 0.3){p_end}
{synopt:{opt f:actors(#)}}fix the number of common factors instead of estimating{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfaclm} implements the factor-augmented panel LM unit-root test with two
structural breaks of Payne, Lee, Islam and Nazlioglu (2022), developed for
testing greenhouse-gas emission convergence. The procedure iterates between (i)
estimating two structural breaks in each series by minimum residual sum of
squares, and (ii) extracting common factors by principal components (the PANIC
approach), until the idiosyncratic variance stabilises. Each de-factored series
is then tested with a Lee-Strazicich two-break LM regression that includes the
estimated common factors, and the resulting p-values are combined into the Fisher
panel statistics {bf:P} and {bf:Pm}.

{pstd}
Removing the common factors makes the test robust to strong cross-sectional
dependence, while the two breaks accommodate structural change of unknown timing.
{cmd:xtfaclm} is part of the {helpb xtpdroot:xtpdroot} library. See
{helpb xtfaclm_methods:help xtfaclm methods} for the formulas.

{marker options}{...}
{title:Options}

{phang}{opt model(string)}: {cmd:constant} (breaks in the level, the default) or
{cmd:trend} (breaks in level and trend).

{phang}{opt kmax(#)}, {opt icfactor(#)}: the maximum number of common factors
(default 5) and the Bai-Ng (2002) criterion (1=PCp, 2=ICp, the default). The
number of factors is the ICp2 minimiser.

{phang}{opt pmax(#)}, {opt iclag(#)}: the maximum augmentation lag (default 5) and
the lag-selection rule. {cmd:iclag(2)} (BIC, the default) and {cmd:iclag(1)} (AIC)
select the lag from the regression sum of squares and reproduce the source GAUSS
routine to the last digit. {cmd:iclag(3)} reproduces the original
general-to-specific {it:t}-rule; because that rule keys off the {it:t}-statistic
of the last {it:common factor} — whose sign and rotation are not statistically
identified — its selected lag can depend on the eigenvector basis and is therefore
not reproducible across linear-algebra libraries. Use {cmd:iclag(1)} or the
default {cmd:iclag(2)} for exact reproducibility.

{phang}{opt trim(#)}: the fraction trimmed at each end when searching for break
dates (default 0.3).

{phang}{opt factors(#)} fixes the number of common factors at {it:#} instead of
estimating it.

{marker examples}{...}
{title:Examples}

{pstd}Level-break factor-augmented panel LM test:{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtfaclm lco2, model(constant)}{p_end}

{pstd}Level & trend breaks, three common factors imposed:{p_end}
{phang2}{cmd:. xtfaclm lco2, model(trend) factors(3)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtfaclm} is {cmd:rclass} and stores:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(P)}, {cmd:r(P_p)}}Fisher chi-square panel statistic and p-value{p_end}
{synopt:{cmd:r(Pm)}, {cmd:r(Pm_p)}}standardized panel statistic and p-value{p_end}
{synopt:{cmd:r(nf)}}number of common factors{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel and time dimensions{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(units)}}per-unit {it:id}, LM, p-value, break1, break2, lag{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
The null is a unit root in each panel. The per-unit LM statistic is a (negative)
{it:t}-ratio that rejects for large negative values; the panel {bf:P} and {bf:Pm}
reject for large values, in favour of (trend-)stationarity around the two breaks
once common factors are removed. The break columns report the estimated break
{it:periods} in the units of your time variable.

{marker refs}{...}
{title:References}

{phang}Payne, J. E., J. Lee, N. Islam, and S. Nazlioglu. 2022. Convergence of
per-capita greenhouse-gas emissions: LM unit-root tests with breaks and factors.
{it:Energy Economics} 115: 106360.{p_end}

{phang}Lee, J., and M. C. Strazicich. 2003. Minimum Lagrange multiplier unit root
test with two structural breaks. {it:Review of Economics and Statistics} 85:
1082-1089.{p_end}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS routine by S. Nazlioglu; validated
byte-for-byte against the GAUSS output on the CAIT greenhouse-gas panel (183
series, AIC/BIC lag selection: all per-unit LM statistics, breaks and lags exact).
Part of the {helpb xtpdroot:xtpdroot} library.{p_end}
