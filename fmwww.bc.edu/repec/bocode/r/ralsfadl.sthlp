{smcl}
{* *! version 1.0.1  16may2026}{...}
{title:Title}

{p2colset 5 17 18 2}{...}
{p2col :{cmd:ralsfadl} {hline 2}}RALS-Fourier ADL cointegration test (Yilanci, Ulucak, Zhang & Andreoni 2022){p_end}
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
{cmd:ralsfadl} {it:depvar regressors} {ifin} [{cmd:,}
{opt trend}
{opt maxl:ags(#)}
{opt fmax(#)}
{opt freq:uency(#)}
{opt g:raph}
{opt nohea:der}]

{phang}{it:depvar} is the dependent series; up to four explanatory series may be
supplied (matching the four Eviews scripts ralsfadl1..4.prg from the source
paper).  {cmd:tsset} must be active.{p_end}

{title:Description}

{pstd}
{cmd:ralsfadl} fits the Fourier-augmented ADL cointegration regression of
Banerjee, Arcabic & Lee (2017),

{p 8 17 2}
Dy_t = b_0 + b_1*sin(2*pi*k*t/T) + b_2*cos(2*pi*k*t/T) + d_1*y_{t-1} + g'*x_{t-1} + a'*Dx_t + sum Dy_{t-i} + eps_t,

{pstd}
and augments it with the RALS w-terms (Im & Schmidt 2008; Lee et al. 2015)
to obtain the {bf:RALS-FADL} statistic.  Both the Fourier frequency k and
the lag of Dy_t are chosen jointly to minimise the AIC, exactly as in the
Eviews loop of the supplement.  Critical values come from Tables A1-A2 of
Yilanci et al. (2022) and are interpolated across rho^2 and sample size.

{title:Options}

{phang}{opt trend} adds a deterministic trend.  Default constant-only.{p_end}
{phang}{opt maxlags(#)} largest lag of Dy_{t-i} (default 3, matching the Eviews code).{p_end}
{phang}{opt fmax(#)} largest Fourier frequency searched (default 5).{p_end}
{phang}{opt frequency(#)} fix the frequency at a known integer.{p_end}
{phang}{opt graph} plots depvar and the first regressor with the Fourier component.{p_end}
{phang}{opt noheader} suppresses the header.{p_end}

{title:Examples}

{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. ralsfadl forestfp gdp urb hc tfp, trend graph}{p_end}
{phang2}{cmd:. ralsfadl co2pc ecpc, fmax(3)}{p_end}

{title:Stored results}

{synoptset 17 tabbed}{...}
{synopt:{cmd:r(tauFADL)}}Fourier-ADL statistic (stage 1){p_end}
{synopt:{cmd:r(tauRALS)}}RALS-FADL statistic{p_end}
{synopt:{cmd:r(rho2)}}estimated rho^2{p_end}
{synopt:{cmd:r(kfreq)}}optimal Fourier frequency{p_end}
{synopt:{cmd:r(lag)}}selected Dy lag{p_end}
{synopt:{cmd:r(AIC)}}minimum AIC across the k x p grid{p_end}
{synopt:{cmd:r(cv01)}, {cmd:r(cv05)}, {cmd:r(cv10)}}critical values at the estimated rho^2{p_end}

{title:References}

{phang}Yilanci, V., Ulucak, R., Zhang, Y., Andreoni, V. (2022). The role of affluence, urbanization, and human capital for sustainable forest management in China.  {it:Sustainable Development} 31(2): 812-824.{p_end}

{phang}Banerjee, A., Arcabic, V., Lee, H. (2017). Fourier ADL cointegration test.  {it:Economic Modelling} 67: 114-124.{p_end}

{title:See also}

{p 4 6 2}{bf:Back to overview:} {help rals}{p_end}
{p 4 6 2}{bf:Unit-root tests:} {help ralsadf}, {help ralslm}, {help ralslmb}, {help ralsfadf}, {help ralsfkss}{p_end}
{p 4 6 2}{bf:Battery (run-all):} {help ralsbattery}{p_end}
{p 4 6 2}{bf:Cointegration tests:} {help ralscoint}, {help ralsfadl}{p_end}
{p 4 6 2}{bf:Diagnostics:} {help ralsdiag}{p_end}

{title:Author}

{pstd}Dr Merwan Roudane -- merwanroudane920@gmail.com
