{smcl}
{* *! version 1.0.2  26aug2016}{...}
{findalias asfradohelp}{...}
{title:xtqptest}

{phang}
{bf:xtqptest} {hline 2} Bias-corrected LM-based test for panel serial correlation, see Born & Breitung (2016)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd: xtqptest}
{varlist}
[if] [in]
[{cmd:,} {it:lags(integer) order(integer) force}] 

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt lags}}check for serial correlation {bf:up to} order {it:lags}{p_end}
{synopt:{opt order}}check for serial correlation {bf:of} order {it:order} {p_end}
{synopt:{opt force}}skips checking if residuals include the fixed effect{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtqptest} calculates the bias-corrected Q(P) statistic for serial correlation described in Born & Breitung (2016) for {varlist} of ue-residuals.

{pstd}
The underlying concept of the test is to regress current demeaned residuals on past demeaned and bias-corrected residuals (up to order {it:lags}) using a heteroskedasticity and autocorrelation robust estimator. 
A Wald test is then performed on the estimated coefficients. {bf:xtqptest} calculates the Q(p) statistic that is asymptotically equivalent to this Wald test. 

{pstd}
The authors have verified that the test in its current form is also valid for unbalanced panels. It might be slightly oversized (rejects the null too often), but this is still a matter of debate.

{pstd}
If {it:order()} is specified, {cmd:xtqptest} calculates the LM(k) statististic instead (also described in BB(2016)). This test also works with e-residuals. 
Unlike the default option, the order()-version tests for serial correlation {bf:of} order {it:order}. E.g. only second order correlation, not first and/or second order correlation.

{pstd}
This test is based on heteroskedasticity and autocorrelation robust t-test of the predictive power of lagged (of order {it:order}) demeaned residuals on current demeaned residuals.

{marker options}{...}
{title:Options}

{phang}
{opt lags} The test looks for autocorrelation up to order {it:lags}. Default value is 2.

{phang}
{opt order} The test looks for autocorrelation of order {it:order}.

{phang}
{opt force} The test only works if the dataset contains no gaps and the residuals provided include the fixed effect. Force skips testing if the latter condition is true.


{marker remarks}{...}
{title:Remarks}

{pstd}
Only valid for fixed effect models without gaps. Unbalanced panels (different starts/ends) are allowed.

{pstd}
You must use the {bf:ue}-option when predicting the residuals. That is, this test requires the fixed effect-included residuals (ci + eit).

{pstd}
Any mistakes are my own.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse xtline1.dta, clear}{p_end}

{phang}{cmd:. xtreg calories, fe}{p_end}
{phang}{cmd:. predict ue_residuals_1, ue}{p_end}
{phang}{cmd:. xtqptest ue_residuals_1, lags(1)}{p_end}
{phang}{cmd:. xtqptest ue_residuals_1, order(1)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtqptest} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(p)}}p values{p_end}
{synopt:{cmd:r(QP)}}values of the Q(P) statistics{p_end}
{synopt:{cmd:r(LM)}}values of the LM(k) statistics{p_end}

{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(pvalue{it:i})}}The p-values are also stored as scalars (often more convenient){p_end}
{synopt:{cmd:r(qp{it:i})}}Same for the qp-statistics{p_end}
{synopt:{cmd:r(lm{it:i})}}Same for the lm-statistics{p_end}
{p2colreset}{...}

{marker references}{...}
{title:References}

{pstd}
{it:Testing for Serial Correlation in Fixed-Effects Panel Data Models}, Benjamin Born and Jörg Breitung, Econometric Reviews 2016

{title:Author}
Jesse Wursten
Faculty of Economics and Business
KU Leuven
{browse "mailto:jesse.wursten@kuleuven.be":jesse.wursten@kuleuven.be} 
