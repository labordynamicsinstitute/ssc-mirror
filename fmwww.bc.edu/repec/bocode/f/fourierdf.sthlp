{smcl}
{* *! version 1.0  11mar2026}{...}
{viewerjumpto "Syntax" "fourierdf##syntax"}{...}
{viewerjumpto "Description" "fourierdf##description"}{...}
{viewerjumpto "Options" "fourierdf##options"}{...}
{viewerjumpto "Methodology" "fourierdf##methodology"}{...}
{viewerjumpto "Interpretation" "fourierdf##interpretation"}{...}
{viewerjumpto "Stored results" "fourierdf##stored"}{...}
{viewerjumpto "Examples" "fourierdf##examples"}{...}
{viewerjumpto "References" "fourierdf##references"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:fourierdf} {hline 2}}Fourier ADF unit root test with flexible Fourier form{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fourierdf}
{varname}
{ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt m:odel(#)}}deterministic specification: {cmd:1}=constant, {cmd:2}=constant+trend; default is {cmd:model(2)}{p_end}
{synopt:{opt k:max(#)}}maximum Fourier frequency; default is {cmd:kmax(5)}{p_end}
{synopt:{opt k(#)}}fixed frequency; default is {cmd:k(0)} (data-driven){p_end}
{synopt:{opt p:max(#)}}maximum lag order; default is {cmd:pmax(8)}{p_end}
{synopt:{opt ic(#)}}information criterion: {cmd:1}=AIC, {cmd:2}=SIC, {cmd:3}=t-stat; default is {cmd:ic(3)}{p_end}
{synopt:{opt notr:end}}equivalent to {cmd:model(1)}{p_end}
{synopt:{opt graph}}display observed vs. Fourier expansion plot{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fourierdf} implements the Fourier ADF (Augmented Dickey-Fuller) unit root test
proposed by {help fourierdf##EL2012b:Enders and Lee (2012b)}. It extends the standard
ADF test by incorporating trigonometric (Fourier) terms to capture unknown smooth
structural breaks in the deterministic component.

{pstd}
This approach approximates the time-varying deterministic trend using a Fourier
expansion, avoiding the need to pre-specify the number, dates, or form of structural
breaks. The optimal frequency is selected by minimizing the SSR.

{pstd}
The data must be {cmd:tsset} before using this command.


{marker options}{...}
{title:Options}

{phang}
{opt model(#)} specifies the deterministic component: {cmd:model(1)} includes
only a constant; {cmd:model(2)} includes both constant and linear trend. Default
is {cmd:model(2)}.

{phang}
{opt kmax(#)} specifies the maximum integer frequency for the grid search.
Default is {cmd:kmax(5)}.

{phang}
{opt k(#)} fixes the Fourier frequency. Default {cmd:k(0)} performs data-driven
selection via SSR minimization.

{phang}
{opt pmax(#)} maximum number of augmented lags. Default is {cmd:pmax(8)}.

{phang}
{opt ic(#)} information criterion: {cmd:1}=AIC, {cmd:2}=SIC, {cmd:3}=sequential
t-statistic. Default is {cmd:ic(3)}.

{phang}
{opt notrend} equivalent to specifying {cmd:model(1)}. Excludes the linear trend
from the deterministic component.

{phang}
{opt graph} displays a plot of the observed series (blue) overlaid with the
Fourier fitted deterministic component (red).


{marker methodology}{...}
{title:Methodology}

{pstd}
The Fourier ADF test is based on the augmented regression:

{p 8 8 2}
Delta(y_t) = c_0 [+ c_1*t] + alpha*sin(2*pi*k*t/T) + beta*cos(2*pi*k*t/T)
             + rho*y_{t-1} + sum_{j=1}^{p} phi_j*Delta(y_{t-j}) + epsilon_t

{pstd}
The null hypothesis H0: rho = 0 is tested using the t-ratio on the coefficient
of y_{t-1}. Under H0, the asymptotic distribution depends on the frequency k
and the deterministic specification. Critical values are tabulated in Enders and
Lee (2012b).

{pstd}
The F-test for the significance of the Fourier terms (H0: alpha = beta = 0)
is used to determine whether a nonlinear deterministic component exists. If the
F-test fails to reject, the standard ADF test without Fourier terms is preferred.


{marker interpretation}{...}
{title:Interpretation}

{pstd}
{bf:Null hypothesis:} The series contains a unit root.{break}
{bf:Alternative:} The series is stationary around a Fourier deterministic trend.

{pstd}
{bf:Decision rule:} Reject H0 if the ADF statistic is more negative than the
critical value.

{pstd}
{ul:Important warnings:}

{p 8 8 2}
{bf:1.} If the F-test does not reject linearity, use a standard ADF test instead.
Using Fourier terms when they are not needed reduces power.

{p 8 8 2}
{bf:2.} The test has higher power for smooth breaks than for sharp/instantaneous breaks.

{p 8 8 2}
{bf:3.} Critical values depend on the frequency k. Using the wrong critical values
(e.g., from a standard ADF table) will lead to incorrect inference.

{p 8 8 2}
{bf:4.} Minimum recommended sample size is T >= 50.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:fourierdf} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(ADFk)}}ADF test statistic{p_end}
{synopt:{cmd:r(k)}}optimal frequency{p_end}
{synopt:{cmd:r(p)}}optimal lag order{p_end}
{synopt:{cmd:r(Fk)}}F-statistic for Fourier terms{p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse gnp96, clear}{p_end}
{phang2}{cmd:. tsset date}{p_end}

{pstd}ADF test with constant and trend (default){p_end}
{phang2}{cmd:. fourierdf gnp96}{p_end}

{pstd}ADF test with constant only{p_end}
{phang2}{cmd:. fourierdf gnp96, notrend}{p_end}

{pstd}ADF test with graph{p_end}
{phang2}{cmd:. fourierdf gnp96, graph}{p_end}


{marker references}{...}
{title:References}

{marker EL2012b}{...}
{phang}
Enders, W. and Lee, J. (2012b). The flexible Fourier form and Dickey-Fuller
type unit root tests. {it:Economics Letters}, 117(1), 196-199.
{p_end}

{phang}
Becker, R., Enders, W., and Lee, J. (2006). A stationarity test in the
presence of an unknown number of smooth breaks. {it:Journal of Time Series
Analysis}, 27(3), 381-409.
{p_end}


{title:Authors}

{pstd}
Dr. Merwan Roudane{break}
Email: merwanroudane920@gmail.com{p_end}



{title:Also see}

{psee}
{space 2}Help:  {helpb fourierlm}, {helpb fouriergls}, {helpb fourierkpss},
{helpb fourierfffff}, {helpb fourierdfdf}, {helpb fourierall}
{p_end}
