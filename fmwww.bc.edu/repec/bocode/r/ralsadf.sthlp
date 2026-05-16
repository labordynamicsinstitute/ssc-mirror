{smcl}
{* *! version 1.0.0  13may2026}{...}
{title:Title}

{p2colset 5 16 17 2}{...}
{p2col :{cmd:ralsadf} {hline 2}}RALS-augmented Dickey-Fuller unit-root test of Im, Lee & Tieslau (2014){p_end}
{p2colreset}{...}

{title:Navigation}

{p 4 4 2}
{help rals:Overview} {c |}
{help ralsadf:adf} {c |}
{help ralslm:lm} {c |}
{help ralslmb:lm-breaks} {c |}
{help ralsfadf:f-adf} {c |}
{help ralsfkss:f-kss} {c |}
{help ralsbattery:battery} {c |}
{help ralscoint:coint} {c |}
{help ralsfadl:f-adl} {c |}
{help ralsdiag:diag}
{p_end}

{title:Syntax}

{p 8 17 2}
{cmd:ralsadf} {it:varname} {ifin} [{cmd:,} {opt trend} {opt maxl:ags(#)} {opt ic(string)} {opt l:evel(#)} {opt g:raph} {opt nohea:der}]

{phang}{it:varname} must be a single time-series-operated variable; {cmd:tsset} must already be active.{p_end}

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt trend}}include a linear trend (model 2); default is constant only (model 1).{p_end}
{synopt :{opt maxlags(#)}}maximum number of dy lags to consider (default = 8).{p_end}
{synopt :{opt ic(string)}}lag-selection rule: {bf:aic} | {bf:bic} | {bf:tstat} (default).{p_end}
{synopt :{opt level(#)}}confidence level used in the rejection message (default 95).{p_end}
{synopt :{opt graph}}draw a time-series plot annotated with the RALS-ADF statistic and 5% CV.{p_end}
{synopt :{opt noheader}}suppress the boxed header.{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:ralsadf} performs the two-stage residual-augmented Dickey-Fuller
unit-root test of Im, Lee & Tieslau (2014).  Stage 1 fits

{p 8 17 2}
Dy_t = alpha + rho*y_{t-1} + sum gamma_i Dy_{t-i} + eps_t

{pstd}
(with an optional linear trend) and records the ADF statistic tau_ADF.
Stage 2 augments the regression with

{p 8 17 2}
w_t = (e_t^2 - m_2, e_t^3 - m_3 - 3*m_2*e_t)'

{pstd}
and refits by OLS; tau_RALS = b_rho / se(b_rho) is the resulting test
statistic.  The asymptotic distribution of tau_RALS depends on the
variance-ratio nuisance parameter

{p 8 17 2}
rho^2 = sigma^2_RALS / sigma^2_ADF,

{pstd}
estimated as the ratio of the second-stage to the first-stage regression
variances.  Critical values come from the Hansen (1995) CADF tables built
into the GAUSS source file {bf:rals_adf.src} and are interpolated linearly
between adjacent rows of the rho^2 grid.

{pstd}
Decision rule: reject H0 (unit root) when the RALS-ADF statistic is less
than the (negative) critical value at the chosen level.

{title:Options}

{phang}{opt trend} selects the constant + trend specification (model 2 of the
GAUSS code).  When omitted, only a constant is included.{p_end}

{phang}{opt maxlags(#)} fixes the maximum number of Dy_{t-i} lags allowed
in stage 1.  The default of 8 follows Im, Lee & Tieslau (2014).{p_end}

{phang}{opt ic(string)} controls how the lag length is chosen:
{break}{bf:tstat} (default) starts at maxlags and removes the highest lag
whose |t| is below 1.645.
{break}{bf:aic} picks the lag minimising the Akaike information criterion.
{break}{bf:bic} picks the lag minimising the Schwarz information criterion.{p_end}

{phang}{opt graph} draws a time-series plot of the analysed variable, with
the RALS-ADF statistic and the 5% critical value displayed in the subtitle.{p_end}

{phang}{opt noheader} suppresses the boxed header.{p_end}

{title:Examples}

{phang2}{cmd:. sysuse sp500, clear}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. ralsadf close, trend}{p_end}
{phang2}{cmd:. ralsadf close, trend maxlags(12) ic(aic) graph}{p_end}

{title:Stored results}

{pstd}{cmd:ralsadf} stores the following in {bf:r()}:

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(tauADF)}}stage-1 ADF statistic{p_end}
{synopt:{cmd:r(tauRALS)}}RALS-ADF statistic{p_end}
{synopt:{cmd:r(rho2)}}estimated rho^2{p_end}
{synopt:{cmd:r(lag)}}lag length selected{p_end}
{synopt:{cmd:r(T)}}sample size used{p_end}
{synopt:{cmd:r(cv01_DF)}, {cmd:r(cv05_DF)}, {cmd:r(cv10_DF)}}stage-1 ADF critical values{p_end}
{synopt:{cmd:r(cv01)}, {cmd:r(cv05)}, {cmd:r(cv10)}}stage-2 RALS critical values{p_end}

{title:References}

{phang}Im, K.S., Lee, J., Tieslau, M.A. (2014).  More powerful unit-root tests with non-normal errors.  In {it:Festschrift in Honor of Peter Schmidt}, 315-342.{p_end}

{phang}Hansen, B.E. (1995).  Rethinking the univariate approach to unit-root testing.  {it:Econometric Theory} 11: 1148-1171.{p_end}

{title:See also}

{p 4 6 2}{bf:Back to overview:} {help rals}{p_end}
{p 4 6 2}{bf:Unit-root tests:} {help ralsadf}, {help ralslm}, {help ralslmb}, {help ralsfadf}, {help ralsfkss}{p_end}
{p 4 6 2}{bf:Battery (run-all):} {help ralsbattery}{p_end}
{p 4 6 2}{bf:Cointegration tests:} {help ralscoint}, {help ralsfadl}{p_end}
{p 4 6 2}{bf:Diagnostics:} {help ralsdiag}{p_end}

{title:Author}

{pstd}Dr Merwan Roudane -- merwanroudane920@gmail.com
