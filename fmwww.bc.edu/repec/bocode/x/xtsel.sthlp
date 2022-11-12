{smcl}
{* Nov 11 2022}{...}
{viewerdialog xtsel "dialog xtsel"}{...}
{vieweralsosee "[XT] xtselmod" "help xtselmod"}{...}
{vieweralsosee "[XT] xtselvar" "help xtselvar"}{...}
{vieweralsosee "[XT] xtoos_t" "help xtoos_t"}{...}
{vieweralsosee "[XT] xtoos_i" "help xtoos_i"}{...}
{vieweralsosee "[XT] xtoos_bin_t" "help xtoos_bin_t"}{...}
{vieweralsosee "[XT] xtoos_bin_i" "help xtoos_bin_i"}{...}
{vieweralsosee "tuples" "help tuples"}{...}

{hline}
Help for {hi:xtsel}
{hline}

{title:Description}

{p} The package {cmd:XTSEL}  includes two commands that help us to rank the best predictors between a number of alternative explanatory variables ({help xtselvar}), 
or the best specification between all possible combinations of a set of explanatory variables ({help xtselmod}), according to several in-sample and out-of-sample statistics. 
They are specially adapted for a panel data framework, firstly because the out-of-sample prediction performance is measured in the two inherent dimensions of a panel (time-series and cross-individuals), 
and secondly because they allow a large number of methodological options that typically are necessary in panel data analysis.

Given a set of {it:n} predictors, {cmd:xtselvar} estimates the same specification {it:n} times, one for each predictor. 
{cmd:xtselmod} estimates {it:(2^n - 1)} different specifications, one per each possible combination out of the set of {it:n} variables. 

Both procedures keep constant the same dependent variable and an optional list of fixed control variables, plus several other methodological options. 
For each candidate variable/specification, the procedures estimate a set of parameters and statistical criteria:

1. Adjusted R squared (R2_ad). 
2. Akaike Information Criterion (AIC). 
3. Bayesian Information Criterion (BIC)
4. U-Theil in time-series dimension: RMSE of variable/specification vs. RMSE from a naïve prediction or an AR1 model (Uth_TS). 
5. U-Theil in cross-section dimension: RMSE of variable/specification vs. RMSE from a naïve prediction or an AR1 model (Uth_CS)

Both commands rank each variable/specification according to each criterion and generate one ranking per each one of them. 

{cmd:xtselvar} also reports coefficients and t-statistic of each candidate variable. They also compute a composite ranking summarizing all five criteria. 
They finally sort all candidate variables/specifications according to the selected ranking, which by default is the composite ranking.

{p}See {help xtselvar} for specific help about {cmd:xtselvar} command.{p_end}
{p}See {help xtselmod} for specific help about {cmd:xtselmod} command.{p_end}

{title:Proceedings USA Stata Conference 2020} 

https://www.stata.com/meeting/us20/slides/us20_Ugarte-Ruiz.pdf


{title:Author}

Alfonso Ugarte-Ruiz
alfonso.ugarte@bbva.com


{title:References}

. Joseph N. Luchman & Daniel Klein & Nicholas J. Cox, 2006. "TUPLES: Stata module for selecting all possible tuples from a list", 
Statistical Software Components S456797, Boston College Department of Economics, revised 17 May 2020.
. Alfonso Ugarte-Ruiz, 2019. "XTOOS: Stata module for evaluating the out-of-sample prediction performance of panel-data models," 
Statistical Software Components S458710, Boston College Department of Economics, revised 09 Jun 2020.
