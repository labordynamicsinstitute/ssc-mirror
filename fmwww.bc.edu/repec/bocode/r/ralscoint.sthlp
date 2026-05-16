{smcl}
{* *! version 1.0.0  13may2026}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col :{cmd:ralscoint} {hline 2}}RALS cointegration tests (ECM / ADL / EG / EG2){p_end}
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
{cmd:ralscoint} {it:depvar regressors} {ifin} [{cmd:,}
{opt trend}
{opt meth:od(string)}
{opt beta(#)}
{opt bw(#)}
{opt g:raph}
{opt nohea:der}]

{phang}{it:depvar} is the LHS I(1) series; {it:regressors} are one or more I(1)
explanatory series.  {cmd:tsset} must be active.{p_end}

{title:Description}

{pstd}
{cmd:ralscoint} runs the four single-equation cointegration tests of Lee,
Lee & Im (2015) -- error-correction (ECM), augmented distributed lag (ADL),
Engle-Granger (EG) and the modified EG2 of Lee (2012) -- in both their
standard OLS form and in the Residual-Augmented Least-Squares (RALS) version
that augments each regression with

{p 8 17 2}
w_t = (e_t^2 - m_2, e_t^3 - m_3 - 3*m_2*e_t)'.

{pstd}
The nuisance parameter rho^2 driving the limiting distribution is computed
via Newey-West long-run variances exactly as in RALS_coint_size_power.g.
Critical values are taken from the embedded tables of the GAUSS supplement
and interpolated across rho^2.

{title:Options}

{phang}{opt trend} include a linear trend (model 2).  Default model 1.{p_end}
{phang}{opt method(string)} {bf:ecm} | {bf:adl} | {bf:eg} | {bf:eg2} | {bf:all} (default).{p_end}
{phang}{opt beta(#)} pre-specified cointegration coefficient used by the ECM test (default 1).{p_end}
{phang}{opt bw(#)} bandwidth for the LR variance kernel ({bf:0} = automatic).{p_end}
{phang}{opt graph} draws a 2-line plot of depvar against the first regressor.{p_end}
{phang}{opt noheader} suppresses the header.{p_end}

{title:Examples}

{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. ralscoint y x1 x2, trend}{p_end}
{phang2}{cmd:. ralscoint forestfp gdp_pc urban hc tfp, trend graph}{p_end}

{title:Stored results}

{synoptset 17 tabbed}{...}
{synopt:{cmd:r(ECM_t)} ... {cmd:r(EG2_t)}}stage-1 OLS test statistics{p_end}
{synopt:{cmd:r(ECM_rals)} ... {cmd:r(EG2_rals)}}RALS statistics{p_end}
{synopt:{cmd:r(ECM_rho2)} ... {cmd:r(EG2_rho2)}}estimated rho^2 for each test{p_end}
{synopt:{cmd:r(cv)}}4x4 matrix: (OLS-5%, RALS-1%, RALS-5%, RALS-10%) per test{p_end}
{synopt:{cmd:r(T)}}sample size{p_end}

{title:References}

{phang}Lee, H., Lee, J., Im, K. (2015). More powerful cointegration tests with non-normal errors.  {it:SNDE} 19(4): 397-413.{p_end}

{phang}Lee, H. (2012). Three essays on more powerful cointegration tests.  PhD dissertation, University of Alabama.{p_end}

{title:See also}

{p 4 6 2}{bf:Back to overview:} {help rals}{p_end}
{p 4 6 2}{bf:Unit-root tests:} {help ralsadf}, {help ralslm}, {help ralslmb}, {help ralsfadf}, {help ralsfkss}{p_end}
{p 4 6 2}{bf:Battery (run-all):} {help ralsbattery}{p_end}
{p 4 6 2}{bf:Cointegration tests:} {help ralscoint}, {help ralsfadl}{p_end}
{p 4 6 2}{bf:Diagnostics:} {help ralsdiag}{p_end}

{title:Author}

{pstd}Dr Merwan Roudane -- merwanroudane920@gmail.com
