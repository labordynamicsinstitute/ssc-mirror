{smcl}
{* *! version 1.0.0  13may2026}{...}
{title:Title}

{p2colset 5 17 18 2}{...}
{p2col :{cmd:ralsfadf} {hline 2}}RALS-Fourier ADF unit-root test (Yilanci, Aydin & Aydin 2019){p_end}
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
{cmd:ralsfadf} {it:varname} {ifin} [{cmd:,}
{opt trend}
{opt maxl:ags(#)}
{opt ic(string)}
{opt fmax(#)}
{opt freq:uency(#)}
{opt g:raph}
{opt nohea:der}]

{title:Description}

{pstd}
{cmd:ralsfadf} estimates the Residual-Augmented Fourier ADF unit-root
regression of Yilanci, Aydin & Aydin (2019),

{p 8 17 2}
Dy_t = rho*y_{t-1} + c_1 + c_2*t + c_3*sin(2*pi*k*t/T) + c_4*cos(2*pi*k*t/T) + c_5*w_t + v_t

{pstd}
following Enders & Lee (2012a)'s Fourier ADF augmented by the RALS w-vector
(Im & Schmidt 2008).  The optimal frequency k is chosen on the grid
1..fmax as the one minimising the OLS sum of squared residuals; the chosen
lag length is reported in {bf:r(lag)}.

{pstd}
Critical values are read from the n x k x rho^2 x percentile table in
Yilanci, Aydin & Aydin (2019, MPRA 96797; Tables 1a & 1b).  Linear
interpolation is used both in rho^2 (10-row grid) and in T (5-row grid).

{title:Options}

{phang}{opt trend} adds a linear trend (model 2).  Default model 1.{p_end}
{phang}{opt maxlags(#)} largest Dy_{t-i} lag considered (default 8).{p_end}
{phang}{opt ic(string)} {bf:aic} | {bf:bic} | {bf:tstat} (default).{p_end}
{phang}{opt fmax(#)} largest Fourier frequency searched (default 5, max 5).{p_end}
{phang}{opt frequency(#)} fix the Fourier frequency (skips the grid search).{p_end}
{phang}{opt graph} plots the series with the fitted Fourier component overlaid.{p_end}
{phang}{opt noheader} suppresses the header.{p_end}

{title:Examples}

{phang2}{cmd:. ralsfadf close, trend graph}{p_end}
{phang2}{cmd:. ralsfadf forestfp, trend fmax(3) ic(aic)}{p_end}

{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(tauFADF)}}stage-1 Fourier-ADF statistic{p_end}
{synopt:{cmd:r(tauRALS)}}RALS-FADF statistic{p_end}
{synopt:{cmd:r(rho2)}}estimated rho^2{p_end}
{synopt:{cmd:r(kfreq)}}selected Fourier frequency{p_end}
{synopt:{cmd:r(ssr)}}minimum SSR over the k-grid{p_end}
{synopt:{cmd:r(lag)}}selected lag length{p_end}
{synopt:{cmd:r(cv01_FADF)}, {cmd:r(cv05_FADF)}, {cmd:r(cv10_FADF)}}stage-1 critical values{p_end}
{synopt:{cmd:r(cv01)}, {cmd:r(cv05)}, {cmd:r(cv10)}}stage-2 RALS critical values{p_end}

{title:References}

{phang}Yilanci, V., Aydin, M., Aydin, M. (2019).  Residual Augmented Fourier ADF Unit Root Test.  MPRA Paper No. 96797.{p_end}

{phang}Enders, W., Lee, J. (2012a).  The flexible Fourier form and Dickey-Fuller type unit root tests.  {it:Economics Letters} 117(1): 196-199.{p_end}

{title:See also}

{p 4 6 2}{bf:Back to overview:} {help rals}{p_end}
{p 4 6 2}{bf:Unit-root tests:} {help ralsadf}, {help ralslm}, {help ralslmb}, {help ralsfadf}, {help ralsfkss}{p_end}
{p 4 6 2}{bf:Battery (run-all):} {help ralsbattery}{p_end}
{p 4 6 2}{bf:Cointegration tests:} {help ralscoint}, {help ralsfadl}{p_end}
{p 4 6 2}{bf:Diagnostics:} {help ralsdiag}{p_end}

{title:Author}

{pstd}Dr Merwan Roudane -- merwanroudane920@gmail.com
