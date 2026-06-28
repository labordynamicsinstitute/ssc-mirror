{smcl}
{* *! version 1.0.0  24jun2026}{...}
{viewerjumpto "Syntax" "maki##syntax"}{...}
{viewerjumpto "Description" "maki##description"}{...}
{viewerjumpto "Options" "maki##options"}{...}
{viewerjumpto "Examples" "maki##examples"}{...}
{viewerjumpto "GAUSS replication" "maki##gauss"}{...}
{viewerjumpto "Stored results" "maki##results"}{...}
{viewerjumpto "References" "maki##references"}{...}
{title:Title}

{phang}
{bf:maki} {hline 2} Maki (2012) cointegration test with unknown number of breaks


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:maki} {depvar} {indepvars} {ifin}{cmd:,}
{opt nbreaks(#)}
[{opt model(#)}
{opt trim:ming(#)}
{opt lag:option(#)}
{opt reg}
{opt regnew:ey}]

{phang}
The data must be {help tsset}-declared as a single (non-panel) time series.
{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt nbreaks(#)}}maximum number of breaks, an integer between 1 and 5{p_end}

{syntab:Optional}
{synopt :{opt model(#)}}deterministic specification; 0, 1, 2, or 3; default is {cmd:model(2)}{p_end}
{synopt :{opt trim:ming(#)}}trimming fraction in (0,0.5); default is {cmd:trimming(0.10)}{p_end}
{synopt :{opt lag:option(#)}}augmentation-lag rule; 0, 1, 2, or 3; default is {cmd:lagoption(1)}{p_end}
{synopt :{opt maxl:ag(#)}}maximum augmentation lag for {cmd:lagoption(1)} and {cmd:lagoption(2)}; default is {cmd:maxlag(12)}{p_end}
{synopt :{opt reg}}estimate the cointegrating regression at the selected breaks by OLS; the required dummy variables ({cmd:mk_*}) will be automatically generated and added to the dataset{p_end}
{synopt :{opt regnew:ey}}as {cmd:reg}, but with Newey-West (HAC) standard errors{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:maki} performs the residual-based cointegration test of Maki (2012), which
allows the cointegrating relationship to have an unknown number of structural
breaks, smaller than or equal to a maximum number of breaks {it:k} set a priori.
The procedure combines the sequential break-search idea of Bai and Perron (1998)
with the unit-root testing strategy of Kapetanios (2005).

{pstd}
The null hypothesis is no cointegration; the alternative is cointegration with
{it:i} breaks ({it:i} {c <=} {it:k}). For each candidate set of breaks the test
estimates the regression by OLS, runs an ADF-type regression on the residuals,
and records the {it:t}-statistic for the residual unit-root coefficient. The
test statistic is the minimum {it:t}-statistic over all the partitions searched
up to {it:k} breaks. Large negative values lead to rejection of the no-
cointegration null. Breakpoints are selected by minimizing the sum of squared
residuals (SSR).

{pstd}
This command is a Stata/Mata port of the original GAUSS
procedures written by Daiki Maki and distributed in the TSPDLIB library
(Aptech Systems). The first regressor in {indepvars} through the fourth is
supported; critical values are available for up to four regressors only.

{pstd}
The four deterministic specifications correspond to Maki (2012, Eq1-Eq4).
In all of them D(i,t) = 1 if t > TB(i) and 0 otherwise, where
TB(i) is the i-th break date; mu is the intercept, gamma the trend coefficient,
beta the cointegrating slope vector, and u(t) the equilibrium error. The sums
run over i = 1, ..., k breaks.

{pstd}
{bf:model(0)} - Level shift, Maki (2012, Eq1). Breaks shift only the intercept:{p_end}
{p 12 12 2}y(t) = mu + sum_i mu(i)*D(i,t) + beta'x(t) + u(t){p_end}

{pstd}
{bf:model(1)} - Level shift with trend, Maki (2012, Eq2). A deterministic trend is
added; breaks shift only the intercept:{p_end}
{p 12 12 2}y(t) = mu + sum_i mu(i)*D(i,t) + gamma*t + beta'x(t) + u(t){p_end}

{pstd}
{bf:model(2)} - Regime shift, Maki (2012, Eq3). Breaks shift both the intercept and the
slope coefficients (this is the default):{p_end}
{p 12 12 2}y(t) = mu + sum_i mu(i)*D(i,t) + beta'x(t) + sum_i (beta(i)'x(t))*D(i,t) + u(t){p_end}

{pstd}
{bf:model(3)} - Regime shift with trend, Maki (2012, Eq4). Breaks shift the intercept,
the trend, and the slope coefficients:{p_end}
{p 12 12 2}y(t) = mu + sum_i mu(i)*D(i,t) + gamma*t + sum_i gamma(i)*t*D(i,t) + beta'x(t) + sum_i (beta(i)'x(t))*D(i,t) + u(t){p_end}

{pstd}
With {opt reg} or {opt regnewey} these are exactly the regressions estimated at
the selected break dates: the regime dummies are the {cmd:mk_du}{it:i} terms, the
slope interactions are the {cmd:mk_du}{it:i}_{it:x} terms, and, under
{cmd:model(3)}, the trend interactions are the {cmd:mk_dtr}{it:i} terms.


{pstd}
The data must contain no missing values over the estimation sample; restrict the
sample with {help if} / {help in} or {cmd:keep} before running the command. The
break points are reported as the observation number, the corresponding value of
the {help tsset} time variable (Date), and the break fraction.

{pstd}
Because the critical values in Maki (2012, Table 1) depend on the model, the
number of regressors, the maximum number of breaks, and the trimming parameter,
they are tabulated only for {opt trimming(0.05)} in the source paper. The
critical values returned here reproduce those of the TSPDLIB GAUSS routine
exactly. Interpret rejections with this in mind when using a different trimming
value.


{marker options}{...}
{title:Options}

{phang}
{opt nbreaks(#)} sets the maximum number of breaks {it:k}. Must be an integer
from 1 to 5. As noted by Maki (2012), the case {cmd:nbreaks(1)} is consistent
with the models of Gregory and Hansen (1996), and {cmd:nbreaks(2)} is similar
to the models of Hatemi-J (2008).

{phang}
{opt model(#)} selects the deterministic terms entered in the cointegrating
regression; the four specifications and their equations are listed under
{help maki##description:Description}. The default {cmd:model(2)}
is the regime-shift model.

{phang}
{opt trimming(#)} is the fraction of the sample trimmed at each end of every
break search, to exclude breaks at the very beginning or end of the sample and
breaks in consecutive periods. Must lie strictly between 0 and 0.5. The default
is 0.10. Note that the internal region-eligibility thresholds for three or more
breaks are fixed at 0.1{it:T} and 0.9{it:T} as in the original GAUSS code and do
not change with this option.

{phang}
{opt lagoption(#)} chooses the augmentation lag in the residual ADF regression:

{p 12 16 2}{cmd:0}{space 3}no augmentation (lag = 0).{p_end}
{p 12 16 2}{cmd:1}{space 3}{it:t}-significance ("t-sig") rule, general-to-specific from the
maximum lag set by {opt maxlag()} (default 12), with the last retained lag
significant at the |t| > 1.654 threshold. This is the default.{p_end}
{p 12 16 2}{cmd:2}{space 3}Breusch-Godfrey ("BG") rule, general-to-specific: starting
from the maximum lag set by {opt maxlag()} and stepping down, the augmentation
lag at which the residuals of the ADF regression first show no serial
correlation, judged by the Breusch-Godfrey LM test at the 5% level. The BG test
is run for orders 1 to a horizon set by the data frequency (annual 2, quarterly
8, monthly 24, weekly 52, daily 100), and a lag is treated as clean only if the
test does not reject for any of those orders. If autocorrelation cannot be
eliminated even at the maximum lag, a warning is issued. This rule is an addition
to the command and is not part of the original GAUSS source.{p_end}
{p 12 16 2}{cmd:3}{space 3}fixed: uses exactly {opt maxlag()} lags, with no
selection. This rule is an addition to the command and is not part of the
original GAUSS source.{p_end}

{phang}
{opt maxlag(#)} sets the maximum augmentation lag for the lag rules in
{opt lagoption(1)} and {opt lagoption(2)}, and the exact number of lags used by
{opt lagoption(3)}. It must be a positive integer and defaults to 12 (the value
hard-coded in the GAUSS source). Under
{cmd:lagoption(0)} it has no effect. Increase it when the Breusch-Godfrey rule
reports that autocorrelation could not be eliminated at the current maximum.

{phang}
{opt reg} estimates, after the test, the cointegrating regression implied by the
selected break dates and reports it with Stata's {help regress:regress} (OLS).
The regressors reproduce the deterministic specification of the chosen
{opt model()}: regime dummies that switch on after each estimated break, the
regressors in {indepvars}, and, for the regime-shift models, the break-by-
regressor interactions (and break-by-trend interactions under {cmd:model(3)}).
The dummies are built from the break dates that produced the test statistic, so
the OLS residuals coincide with those underlying the reported {it:t}-statistic.
A line showing how to reproduce the regression directly is printed. The
required dummy variables ({cmd:mk_*}) will be automatically generated and added
to the dataset.

{phang}
{opt regnewey} does the same as {opt reg} but reports Newey-West
heteroskedasticity- and autocorrelation-consistent (HAC) standard errors via
{help newey:newey}. The lag truncation is set automatically to
floor(4*(T/100)^(2/9)). Specify {opt reg} or {opt regnewey}, not both.


{marker examples}{...}
{title:Examples}

{pstd}Nelson-Plosser data, money-demand-type relationship, 1909-1970{p_end}

{phang2}{cmd:. use "https://eruygurakademi.com/datasets/maki/nelsonplosser.dta", clear}{p_end}
{phang2}{cmd:. keep if year >= 1909}{p_end}
{phang2}{cmd:. tsset year}{p_end}

{pstd}Regime-shift model, up to two breaks:{p_end}
{phang2}{cmd:. maki lgnp lm bnd, nbreaks(2) model(2)}{p_end}

{pstd}Up to three breaks, regime shift with trend:{p_end}
{phang2}{cmd:. maki lgnp lm bnd, nbreaks(3) model(3)}{p_end}

{pstd}Single break, level-shift model, no lag augmentation:{p_end}
{phang2}{cmd:. maki lgnp lm bnd, nbreaks(1) model(0) lagoption(0)}{p_end}

{pstd}Regime-shift model with Breusch-Godfrey lag selection:{p_end}
{phang2}{cmd:. maki lgnp lm bnd, nbreaks(3) model(2) lagoption(2)}{p_end}

{pstd}Two regressors, five breaks, tighter trimming:{p_end}
{phang2}{cmd:. maki lgnp lm, nbreaks(5) model(2) trimming(0.05)}{p_end}

{pstd}Show the cointegrating regression at the selected breaks (OLS):{p_end}
{phang2}{cmd:. maki lgnp lm bnd, nbreaks(5) model(2) reg}{p_end}

{pstd}Same, with Newey-West (HAC) standard errors:{p_end}
{phang2}{cmd:. maki lgnp lm bnd, nbreaks(5) model(2) regnewey}{p_end}

{pstd}
Comparison with the {cmd:makicoint} command (if installed). {cmd:maki}
reproduces the result of the original GAUSS TSPDLIB {cmd:coint_maki} procedure:{p_end}
{phang2}{cmd:. maki lgnp lm bnd, nbreaks(5) model(2)}{p_end}
{phang2}{cmd:. makicoint lgnp lm bnd, maxbreaks(5) model(2)}{p_end}


{marker gauss}{...}
{title:GAUSS replication}

{pstd}
{cmd:maki} is a Stata/Mata port of the TSPDLIB GAUSS procedure
{cmd:coint_maki} and reproduces it to the displayed precision. The two commands
correspond as follows:

{p 8 8 2}Stata:{p_end}
{p 12 12 2}{cmd:maki} {it:depvar indepvars}{cmd:, nbreaks(}{it:m}{cmd:) model(}{it:M}{cmd:)}{p_end}
{p 8 8 2}GAUSS:{p_end}
{p 12 12 2}{cmd:call coint_maki(}{it:data}{cmd:, }{it:m}{cmd:, }{it:M}{cmd:);}{p_end}

{pstd}
{it:m} = {opt nbreaks()} is the second GAUSS argument and {it:M} = {opt model()}
is the third. In {cmd:coint_maki} the data matrix has the dependent variable in
its first column and the regressors in the remaining columns, matching
{it:depvar} {it:indepvars} here. Trimming and lag selection use the same defaults
in both ({opt trimming(0.10)} and the t-significance lag rule), so omitting them
in GAUSS reproduces the {cmd:maki} default.

{pstd}
Ready-to-run replication files for both packages are provided at
{browse "https://eruygurakademi.com/datasets/maki/":https://eruygurakademi.com/datasets/maki/}.
Each file runs the same 20 specifications (the four models, each with a maximum
of one through five breaks) on the Nelson-Plosser data, so the Stata and GAUSS
output can be compared side by side.

{dlgtab:Replicating in Stata}

{pstd}
The do-file
{browse "https://eruygurakademi.com/datasets/maki/maki_stata.do":maki_stata.do}
loads the data, sets the sample, and runs all 20 specifications. Run it directly
from the web with:{p_end}

{phang2}{cmd:. do https://eruygurakademi.com/datasets/maki/maki_stata.do}{p_end}

{dlgtab:Replicating in GAUSS}

{pstd}
The program
{browse "https://eruygurakademi.com/datasets/maki/maki_gauss.gss":maki_gauss.gss}
reads the data directly from the web and runs all 20 specifications, so no
manual download of the data is needed. To run it:{p_end}

{p 8 12 2}1. Make sure the TSPDLIB library is installed in GAUSS.{p_end}
{p 8 12 2}2. Open
{browse "https://eruygurakademi.com/datasets/maki/maki_gauss.gss":maki_gauss.gss}
in GAUSS, select the entire program with Ctrl+A, and press Run.{p_end}

{pstd}
GAUSS then prints the test statistic, critical values, estimated break dates,
and the test conclusion for all 20 specifications, matching the Stata output.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:maki} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(test_stat)}}minimum {it:t}-statistic (the test statistic){p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}
{synopt:{cmd:r(reject)}}1 if H0 rejected at the 10% level or better, 0 otherwise{p_end}
{synopt:{cmd:r(nobs)}}number of observations used{p_end}
{synopt:{cmd:r(nbreaks)}}maximum number of breaks{p_end}
{synopt:{cmd:r(model)}}model number{p_end}
{synopt:{cmd:r(trimming)}}trimming fraction{p_end}
{synopt:{cmd:r(sel_lag)}}augmentation lag of the ADF regression that produced the test statistic{p_end}
{synopt:{cmd:r(bp{it:i})}}observation number of break {it:i}{p_end}
{synopt:{cmd:r(bpdate{it:i})}}time-variable value at break {it:i}{p_end}
{synopt:{cmd:r(bpfrac{it:i})}}break fraction of break {it:i}{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}independent variable(s){p_end}
{synopt:{cmd:r(model_name)}}model description{p_end}


{marker references}{...}
{title:References}

{phang}
Bai, J., and P. Perron. 1998. Estimating and testing linear models with multiple
structural changes. {it:Econometrica} 66: 47-78.

{phang}
Hatemi-J, A. 2008. Tests for cointegration with two unknown regime shifts with
an application to financial market integration. {it:Empirical Economics} 35:
497-505.

{phang}
Kapetanios, G. 2005. Unit-root testing against the alternative hypothesis of up
to m structural breaks. {it:Journal of Time Series Analysis} 26: 123-133.

{phang}
Maki, D. 2012. Tests for cointegration allowing for an unknown number of breaks.
{it:Economic Modelling} 29: 2011-2015.


{title:Author}

{pstd}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com":https://www.ozaneruygur.com}{break}
eruygur@gmail.com

{pstd}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.{break}
{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}{break}
eruygurakademi@gmail.com

{pstd}
{cmd:maki} v3.5.0 {c -} June 2026

{pstd}
The test implemented here was proposed by Daiki Maki (Faculty of Economics,
Ryukoku University, Kyoto, Japan) in Maki (2012). {cmd:maki} is a Stata/Mata
port of the original GAUSS code, which was provided by Daiki Maki himself (by
email, October 2019) and modified by Jason Jones (Aptech Systems), and
distributed in the TSPDLIB library by Saban Nazlioglu.

{pstd}
{bf:Please cite as:}

{pstd}
Eruygur, H. O. 2026. {cmd:maki}: Maki (2012) cointegration test with unknown
number of breaks. Stata package version 3.5.0. Available from:
{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}.
{p_end}
