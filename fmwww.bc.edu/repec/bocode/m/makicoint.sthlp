{smcl}
{* *! version 1.0.0  30jan2026}{...}
{viewerjumpto "Syntax" "makicoint##syntax"}{...}
{viewerjumpto "Description" "makicoint##description"}{...}
{viewerjumpto "Options" "makicoint##options"}{...}
{viewerjumpto "Models" "makicoint##models"}{...}
{viewerjumpto "Examples" "makicoint##examples"}{...}
{viewerjumpto "Stored results" "makicoint##results"}{...}
{viewerjumpto "References" "makicoint##references"}{...}
{viewerjumpto "Author" "makicoint##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{hi:makicoint} {hline 2}}Maki (2012) cointegration test with multiple structural breaks{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:makicoint}
{it:depvar} {it:indepvars}
{ifin}{cmd:,}
{opt maxb:reaks(#)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt maxb:reaks(#)}}maximum number of structural breaks (1-5){p_end}

{syntab:Optional}
{synopt:{opt m:odel(#)}}model specification (0-3); default is {cmd:model(2)}{p_end}
{synopt:{opt tr:imming(#)}}trimming parameter; default is {cmd:trimming(0.10)}{p_end}
{synopt:{opt maxl:ags(#)}}maximum lags for ADF test; default is {cmd:maxlags(12)}{p_end}
{synopt:{opt lagm:ethod(method)}}lag selection method; default is {cmd:lagmethod(tsig)}{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:makicoint}; see {helpb tsset}.{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:makicoint} performs the Maki (2012) cointegration test with multiple structural breaks.
The test allows for an unknown number of breaks in the cointegrating relationship,
where the number of breaks is assumed to be less than or equal to a maximum number
specified by the user.

{pstd}
The null hypothesis is no cointegration, and the alternative hypothesis is
cointegration with up to {it:m} structural breaks, where {it:m} is specified
by the {opt maxbreaks()} option.

{pstd}
The test statistic is the minimum ADF t-statistic obtained by searching over all
possible break dates. The test is based on the methodology proposed by
Bai and Perron (1998) for detecting structural breaks and the unit root test
developed by Kapetanios (2005).

{pstd}
This test is particularly useful when:

{p 8 12 2}
{it:(i)} The number of structural breaks is unknown a priori.

{p 8 12 2}
{it:(ii)} The cointegrating relationship may have more than two breaks,
in which case the Gregory and Hansen (1996) test (one break) or the
Hatemi-J (2008) test (two breaks) would be misspecified.

{p 8 12 2}
{it:(iii)} The data exhibit persistent Markov switching behavior.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt maxbreaks(#)} specifies the maximum number of structural breaks to allow
in the cointegrating regression. Valid values are integers from 1 to 5.
Critical values are available only for up to 5 breaks.

{dlgtab:Optional}

{phang}
{opt model(#)} specifies the model for structural breaks. The default is
{cmd:model(2)} (regime shift).

{p 8 8 2}
{cmd:model(0)}: Level shift - breaks affect only the intercept.{p_end}
{p 8 8 2}
{cmd:model(1)}: Level shift with trend - includes a deterministic trend, breaks affect only the intercept.{p_end}
{p 8 8 2}
{cmd:model(2)}: Regime shift - breaks affect both the intercept and the slope coefficients.{p_end}
{p 8 8 2}
{cmd:model(3)}: Regime shift with trend - includes a trend, breaks affect intercept, trend, and slope coefficients.{p_end}

{phang}
{opt trimming(#)} specifies the trimming parameter, which determines the minimum
fraction of observations required at each end of the sample and between breaks.
Valid values are between 0 (exclusive) and 0.5 (exclusive). The default is
{cmd:trimming(0.10)}, meaning at least 10% of observations are required in each
regime.

{phang}
{opt maxlags(#)} specifies the maximum number of lags to consider in the ADF
regression. The default is {cmd:maxlags(12)}.

{phang}
{opt lagmethod(method)} specifies the method for selecting the number of lags
in the ADF test. Valid options are:

{p 8 8 2}
{cmd:tsig}: t-significance criterion - starts from {cmd:maxlags} and removes
lags until the last lag is significant at the 10% level. This is the default
and matches the original GAUSS code.{p_end}
{p 8 8 2}
{cmd:fixed}: uses exactly {cmd:maxlags} lags.{p_end}
{p 8 8 2}
{cmd:aic}: selects lags that minimize the Akaike Information Criterion.{p_end}
{p 8 8 2}
{cmd:bic}: selects lags that minimize the Bayesian Information Criterion.{p_end}


{marker models}{...}
{title:Models}

{pstd}
The four models correspond to different specifications of structural change
in the cointegrating relationship:

{pstd}
{bf:Model 0 - Level Shift:}

{p 8 8 2}
y_t = mu + sum(mu_i * D_it) + beta' * x_t + u_t

{pstd}
{bf:Model 1 - Level Shift with Trend:}

{p 8 8 2}
y_t = mu + sum(mu_i * D_it) + gamma * t + beta' * x_t + u_t

{pstd}
{bf:Model 2 - Regime Shift:}

{p 8 8 2}
y_t = mu + sum(mu_i * D_it) + beta' * x_t + sum(beta_i' * x_t * D_it) + u_t

{pstd}
{bf:Model 3 - Regime Shift with Trend:}

{p 8 8 2}
y_t = mu + sum(mu_i * D_it) + gamma * t + sum(gamma_i * t * D_it) + beta' * x_t + sum(beta_i' * x_t * D_it) + u_t

{pstd}
where D_it = 1 if t > TB_i and 0 otherwise, and TB_i denotes the break date.


{marker examples}{...}
{title:Examples}

{pstd}Setup: Load time series data and declare it as time series{p_end}
{phang2}{cmd:. webuse lutkepohl, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Basic usage with 2 maximum breaks using regime shift model{p_end}
{phang2}{cmd:. makicoint consumption investment income, maxbreaks(2)}{p_end}

{pstd}Test with 3 maximum breaks and level shift model{p_end}
{phang2}{cmd:. makicoint consumption investment, maxbreaks(3) model(0)}{p_end}

{pstd}Test with custom trimming and lag selection{p_end}
{phang2}{cmd:. makicoint consumption investment income, maxbreaks(2) trimming(0.15) lagmethod(aic) maxlags(8)}{p_end}

{pstd}Full model with trend and regime shifts{p_end}
{phang2}{cmd:. makicoint consumption investment income, maxbreaks(3) model(3)}{p_end}

{pstd}Store results for later use{p_end}
{phang2}{cmd:. makicoint consumption investment, maxbreaks(2)}{p_end}
{phang2}{cmd:. display "Test statistic: " r(test_stat)}{p_end}
{phang2}{cmd:. display "First break at observation: " r(bp1)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:makicoint} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(test_stat)}}test statistic (minimum ADF t-statistic){p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}
{synopt:{cmd:r(nobs)}}number of observations{p_end}
{synopt:{cmd:r(maxbreaks)}}maximum number of breaks{p_end}
{synopt:{cmd:r(model)}}model number (0-3){p_end}
{synopt:{cmd:r(trimming)}}trimming parameter{p_end}
{synopt:{cmd:r(lags)}}number of lags used in ADF test{p_end}
{synopt:{cmd:r(reject)}}1 if null rejected at 10% level, 0 otherwise{p_end}
{synopt:{cmd:r(bp1)}}observation number of first break{p_end}
{synopt:{cmd:r(bp2)}}observation number of second break{p_end}
{synopt:{cmd:r(bp3)}}observation number of third break{p_end}
{synopt:{cmd:r(bp4)}}observation number of fourth break{p_end}
{synopt:{cmd:r(bp5)}}observation number of fifth break{p_end}
{synopt:{cmd:r(bpdate1)}}date/time value of first break{p_end}
{synopt:{cmd:r(bpdate2)}}date/time value of second break{p_end}
{synopt:{cmd:r(bpdate3)}}date/time value of third break{p_end}
{synopt:{cmd:r(bpdate4)}}date/time value of fourth break{p_end}
{synopt:{cmd:r(bpdate5)}}date/time value of fifth break{p_end}
{synopt:{cmd:r(bpfrac1)}}fraction of sample at first break{p_end}
{synopt:{cmd:r(bpfrac2)}}fraction of sample at second break{p_end}
{synopt:{cmd:r(bpfrac3)}}fraction of sample at third break{p_end}
{synopt:{cmd:r(bpfrac4)}}fraction of sample at fourth break{p_end}
{synopt:{cmd:r(bpfrac5)}}fraction of sample at fifth break{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}names of independent variables{p_end}
{synopt:{cmd:r(model_name)}}name of model used{p_end}
{synopt:{cmd:r(lagmethod)}}lag selection method used{p_end}


{marker references}{...}
{title:References}

{phang}
Maki, D. (2012). Tests for cointegration allowing for an unknown number of
breaks. {it:Economic Modelling}, 29, 2011-2015.
{browse "https://doi.org/10.1016/j.econmod.2012.04.022":https://doi.org/10.1016/j.econmod.2012.04.022}

{phang}
Bai, J. and P. Perron (1998). Estimating and testing linear models with
multiple structural changes. {it:Econometrica}, 66, 47-78.

{phang}
Gregory, A.W. and B.E. Hansen (1996). Residual-based tests for cointegration
in models with regime shifts. {it:Journal of Econometrics}, 70, 99-126.

{phang}
Hatemi-J, A. (2008). Tests for cointegration with two unknown regime shifts
with an application to financial market integration.
{it:Empirical Economics}, 35, 497-505.

{phang}
Kapetanios, G. (2005). Unit-root testing against the alternative hypothesis
of up to m structural breaks. {it:Journal of Time Series Analysis}, 26, 123-133.


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
This command is based on the original GAUSS code by Daiki Maki, received from 
the author and later included in the TSPDLIB GAUSS package by Saban Nazlioglu 
and modified by Jason Jones (Aptech Systems).

{pstd}
Please cite as:{break}
Roudane, M. (2026). makicoint: Stata module to perform Maki cointegration test
with multiple structural breaks. Statistical Software Components, Boston College
Department of Economics.


{title:Also see}

{psee}
Online: {helpb ghansen}, {helpb zandrews}, {helpb dfuller}, {helpb egranger}, 
{helpb vecrank}
{p_end}
