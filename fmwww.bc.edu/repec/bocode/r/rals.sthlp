{smcl}
{* *! version 1.0.1  16may2026}{...}
{title:Title}

{phang}{bf:rals} {hline 2} Residual Augmented Least Squares unit-root and cointegration tests

{title:Jump to a help page}

{p 4 4 2}
{ul:Unit-root tests}{break}
   {help ralsadf}  {space 4}- RALS-ADF{break}
   {help ralslm}   {space 5}- RALS-LM{break}
   {help ralslmb}  {space 4}- RALS-LM with structural breaks{break}
   {help ralsfadf} {space 3}- RALS-Fourier ADF{break}
   {help ralsfkss} {space 3}- RALS-Fourier KSS{p_end}

{p 4 4 2}
{ul:Run-all driver}{break}
   {help ralsbattery} - run every test in the package on one or more series{p_end}

{p 4 4 2}
{ul:Cointegration tests}{break}
   {help ralscoint}  {space 2}- RALS ECM / ADL / EG / EG2{break}
   {help ralsfadl}   {space 3}- RALS-Fourier ADL cointegration{p_end}

{p 4 4 2}
{ul:Diagnostics}{break}
   {help ralsdiag}   {space 3}- Normality, linearity and rho^2 diagnostics{p_end}

{title:Description}

{pstd}
The {bf:rals} package implements every test in the {it:Residual Augmented
Least Squares} family (Im & Schmidt 2008): the second- and third-moment
information in the regression residuals is exploited to gain power whenever
the errors are non-normal.  The package collects {bf:nine} commands covering
both unit-root and cointegration testing, with optional Fourier deterministic
components and structural breaks.  All routines reproduce the original GAUSS
code shipped with the source papers (rals_adf.src, rals_lm.src,
rals_lm_breaks.src, RALS_coint_size_power.g, RALS_coint_crit.g) and the
Eviews routines ralsfadl1..4.prg used in Yilanci et al. (2022).

{pstd}
Author: {bf:Dr Merwan Roudane}, merwanroudane920@gmail.com

{title:Quick start}

{phang2}{cmd:. sysuse sp500, clear}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. ralsdiag close, trend}{p_end}
{phang2}{cmd:. ralsadf  close, trend graph}{p_end}
{phang2}{cmd:. ralsbattery close volume open, trend graph}      // run all tests on all variables{p_end}

{title:References}

{phang}Im, K.S., Schmidt, P. (2008). More efficient estimation under non-normality when higher moments do not depend on the regressors, using residual augmented least squares. {it:Journal of Econometrics} 144(1): 219-233.{p_end}

{phang}Im, K.S., Lee, J., Tieslau, M.A. (2014). More powerful unit root tests with non-normal errors. {it:Festschrift in Honor of Peter Schmidt}, 315-342.{p_end}

{phang}Meng, M., Im, K.S., Lee, J., Tieslau, M.A. (2014). More powerful LM unit root tests with non-normal errors. {it:Festschrift}, 343-357.{p_end}

{phang}Meng, M., Lee, J., Payne, J.E. (2017). RALS-LM unit root test with trend breaks and non-normal errors. {it:Studies in Nonlinear Dynamics & Econometrics} 21(1): 31-45.{p_end}

{phang}Lee, H., Lee, J., Im, K. (2015). More powerful cointegration tests with non-normal errors. {it:SNDE} 19(4): 397-413.{p_end}

{phang}Yilanci, V., Aydin, M., Aydin, M. (2019). Residual Augmented Fourier ADF Unit Root Test. MPRA Paper No. 96797.{p_end}

{phang}Yilanci, V., Ulucak, R., Zhang, Y., Andreoni, V. (2022). The role of affluence, urbanization and human capital for sustainable forest management in China. {it:Sustainable Development} 31(2): 812-824.{p_end}

{phang}Yilanci, V., Ozgur, O. (2025). Testing Real Interest Rate Parity for EU5 Countries. {it:Politicka Ekonomie} 73(3): 528-565.{p_end}

{title:Author}

{pstd}
Dr Merwan Roudane -- merwanroudane920@gmail.com
{break}Version 1.0.1  --  16 May 2026
