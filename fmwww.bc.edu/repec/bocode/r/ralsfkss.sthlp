{smcl}
{* *! version 1.0.0  13may2026}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col :{cmd:ralsfkss} {hline 2}}RALS-Fourier KSS unit-root test (Yilanci & Ozgur 2025){p_end}
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
{cmd:ralsfkss} {it:varname} {ifin} [{cmd:,}
{opt trend}
{opt maxl:ags(#)}
{opt ic(string)}
{opt fmax(#)}
{opt freq:uency(#)}
{opt g:raph}
{opt nohea:der}]

{title:Description}

{pstd}
{cmd:ralsfkss} implements the RALS-Fourier KSS unit-root test of Yilanci &
Ozgur (2025).  The series is first de-trended with a Fourier function
(Christopoulos & Leon-Ledesma 2010); the de-trended residuals u_t are then
plugged into a Kapetanios-Shin-Snell (KSS) regression

{p 8 17 2}
Du_t = phi_1 * u^3_{t-1} + sum zeta_i Du_{t-i} + e_t,

{pstd}
and finally the second-stage residuals are augmented with the RALS w-vector
to gain power under non-normal innovations.

{title:Options}

{phang}{opt trend} adds a linear trend in the de-trending stage.{p_end}
{phang}{opt maxlags(#)} largest Du_{t-i} lag (default 8).{p_end}
{phang}{opt ic(string)} {bf:aic} (default), {bf:bic} or {bf:tstat}.{p_end}
{phang}{opt fmax(#)} largest Fourier frequency searched (max 5).{p_end}
{phang}{opt frequency(#)} fix the Fourier frequency directly.{p_end}
{phang}{opt graph} time-series plot with the chosen Fourier component overlaid.{p_end}
{phang}{opt noheader} suppress the header.{p_end}

{title:Examples}

{phang2}{cmd:. ralsfkss close, trend graph}{p_end}
{phang2}{cmd:. ralsfkss rid_italy, fmax(3)}{p_end}

{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(tauKSS)}}stage-1 KSS statistic{p_end}
{synopt:{cmd:r(tauRALS)}}RALS-FKSS statistic{p_end}
{synopt:{cmd:r(rho2)}}estimated rho^2{p_end}
{synopt:{cmd:r(kfreq)}}selected Fourier frequency{p_end}
{synopt:{cmd:r(lag)}}selected lag length{p_end}
{synopt:{cmd:r(cv01_FKSS)}, {cmd:r(cv05_FKSS)}, {cmd:r(cv10_FKSS)}}stage-1 critical values{p_end}
{synopt:{cmd:r(cv01)}, {cmd:r(cv05)}, {cmd:r(cv10)}}stage-2 RALS critical values{p_end}

{title:References}

{phang}Yilanci, V., Ozgur, O. (2025).  Testing Real Interest Rate Parity for EU5 Countries: 200 Years of Data, Non-normality, Non-linearity and Breaks.  {it:Politicka Ekonomie} 73(3): 528-565.{p_end}

{phang}Christopoulos, D.K., Leon-Ledesma, M.A. (2010). Smooth breaks and non-linear mean reversion.  {it:Journal of International Money and Finance} 29(6): 1076-1093.{p_end}

{title:See also}

{p 4 6 2}{bf:Back to overview:} {help rals}{p_end}
{p 4 6 2}{bf:Unit-root tests:} {help ralsadf}, {help ralslm}, {help ralslmb}, {help ralsfadf}, {help ralsfkss}{p_end}
{p 4 6 2}{bf:Battery (run-all):} {help ralsbattery}{p_end}
{p 4 6 2}{bf:Cointegration tests:} {help ralscoint}, {help ralsfadl}{p_end}
{p 4 6 2}{bf:Diagnostics:} {help ralsdiag}{p_end}

{title:Author}

{pstd}Dr Merwan Roudane -- merwanroudane920@gmail.com
