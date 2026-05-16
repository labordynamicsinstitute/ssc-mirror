{smcl}
{* *! version 1.0.0  13may2026}{...}
{title:Title}

{p2colset 5 17 18 2}{...}
{p2col :{cmd:ralsdiag} {hline 2}}Diagnostics for the RALS family: non-normality, linearity and rho^2{p_end}
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
{cmd:ralsdiag} {it:varname} {ifin} [{cmd:,} {opt trend} {opt maxl:ags(#)}]

{title:Description}

{pstd}
{cmd:ralsdiag} reports the three pre-tests that drive the decision tree in
Yilanci & Ozgur (2025, Figure 3):

{phang}1. Skewness, kurtosis, Shapiro-Wilk and Jarque-Bera normality tests on
the residuals of an auxiliary ADF regression.  Significant non-normality
implies that the RALS w-augmentation will deliver real power gains.{p_end}

{phang}2. A simple cube-extension linearity test in the spirit of Harvey,
Leybourne & Xiao (2008): an F-test for y^3_{t-1} in the ADF equation.{p_end}

{phang}3. The RALS variance ratio rho^2 = sigma^2_RALS / sigma^2_ADF,
estimated directly from a once-run pair of regressions.  Smaller values mean
more power gain over the OLS test.{p_end}

{title:Options}

{phang}{opt trend} include a trend in the auxiliary ADF regression.{p_end}
{phang}{opt maxlags(#)} number of Dy_{t-i} lags in the auxiliary regression (default 8).{p_end}

{title:Examples}

{phang2}{cmd:. ralsdiag close, trend}{p_end}

{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(skewness)}}sample skewness of residuals{p_end}
{synopt:{cmd:r(kurtosis)}}sample kurtosis of residuals{p_end}
{synopt:{cmd:r(sw_W)}, {cmd:r(sw_p)}}Shapiro-Wilk statistic & p-value{p_end}
{synopt:{cmd:r(JB)}, {cmd:r(JB_p)}}Jarque-Bera statistic & p-value{p_end}
{synopt:{cmd:r(HLX_F)}, {cmd:r(HLX_p)}}cube-extension linearity test{p_end}
{synopt:{cmd:r(rho2)}}estimated rho^2{p_end}

{title:References}

{phang}Yilanci, V., Ozgur, O. (2025).  Testing Real Interest Rate Parity for EU5 Countries.  {it:Politicka Ekonomie} 73(3): 528-565.{p_end}

{phang}Im, K.S., Schmidt, P. (2008).  More efficient estimation under non-normality when higher moments do not depend on the regressors, using residual augmented least squares.  {it:Journal of Econometrics} 144(1): 219-233.{p_end}

{title:See also}

{p 4 6 2}{bf:Back to overview:} {help rals}{p_end}
{p 4 6 2}{bf:Unit-root tests:} {help ralsadf}, {help ralslm}, {help ralslmb}, {help ralsfadf}, {help ralsfkss}{p_end}
{p 4 6 2}{bf:Battery (run-all):} {help ralsbattery}{p_end}
{p 4 6 2}{bf:Cointegration tests:} {help ralscoint}, {help ralsfadl}{p_end}

{title:Author}

{pstd}Dr Merwan Roudane -- merwanroudane920@gmail.com
