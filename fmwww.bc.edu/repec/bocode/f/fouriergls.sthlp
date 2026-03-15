{smcl}
{* *! version 1.0  11mar2026}{...}
{viewerjumpto "Syntax" "fouriergls##syntax"}{...}
{viewerjumpto "Description" "fouriergls##description"}{...}
{viewerjumpto "Options" "fouriergls##options"}{...}
{viewerjumpto "Methodology" "fouriergls##methodology"}{...}
{viewerjumpto "Interpretation" "fouriergls##interpretation"}{...}
{viewerjumpto "Stored results" "fouriergls##stored"}{...}
{viewerjumpto "Examples" "fouriergls##examples"}{...}
{viewerjumpto "References" "fouriergls##references"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{cmd:fouriergls} {hline 2}}Fourier GLS de-trended unit root test{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fouriergls}
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
{cmd:fouriergls} implements the Fourier GLS (Generalized Least Squares) de-trended
unit root test proposed by {help fouriergls##RT2012:Rodrigues and Taylor (2012)}.
This test combines the power advantages of GLS de-trending (Elliott, Rothenberg,
and Stock, 1996) with the flexibility of Fourier approximations for unknown
structural breaks.

{pstd}
GLS de-trending is known to produce unit root tests with superior power compared
to OLS-based tests (such as the standard ADF or Fourier ADF). The Fourier GLS
test applies local GLS de-trending with a c-bar parameter that depends on the
model specification, then tests for a unit root in the de-trended series.

{pstd}
The data must be {cmd:tsset} before using this command.


{marker options}{...}
{title:Options}

{phang}
{opt model(#)} specifies the deterministic component: {cmd:model(1)} includes
only a constant (c_bar = -7); {cmd:model(2)} includes constant and trend
(c_bar = -22). Default is {cmd:model(2)}.

{phang}
{opt kmax(#)} maximum Fourier frequency. Default is {cmd:kmax(5)}.

{phang}
{opt k(#)} fixed frequency. Default {cmd:k(0)} = data-driven selection.

{phang}
{opt pmax(#)} maximum augmented lags. Default is {cmd:pmax(8)}.

{phang}
{opt ic(#)} lag selection criterion. Default is {cmd:ic(3)}.

{phang}
{opt notrend} equivalent to {cmd:model(1)}.

{phang}
{opt graph} displays a plot of observed series vs. Fourier expansion.


{marker methodology}{...}
{title:Methodology}

{pstd}
The Fourier GLS test proceeds in two stages:

{pstd}
{bf:Stage 1 - GLS de-trending:} The series is de-trended using the local GLS
procedure. For model 2, the de-trending parameter c_bar = -22 (as recommended by
Elliott, Rothenberg, and Stock, 1996). The quasi-differenced series is regressed
on quasi-differenced deterministic components including Fourier terms.

{pstd}
{bf:Stage 2 - ADF test on residuals:} An ADF regression is performed on the
GLS de-trended residuals to test for a unit root.

{pstd}
The test statistic is the t-ratio on the lagged de-trended series in the ADF
regression. Critical values depend on the frequency k and the model specification.

{pstd}
{bf:c-bar values:} c_bar = -7 for model 1 (constant only), c_bar = -22 for
model 2 (constant + trend). These values maximize the local asymptotic power
of the test at the 50% power point.


{marker interpretation}{...}
{title:Interpretation}

{pstd}
{bf:Null hypothesis:} The series has a unit root.{break}
{bf:Alternative:} The series is stationary around a Fourier deterministic trend.

{pstd}
{bf:Decision rule:} Reject H0 if the GLS statistic is more negative than the
critical value.

{pstd}
{bf:Power advantage:} The GLS de-trending yields higher power than OLS-based
Fourier tests (fourierlm, fourierdf), especially in finite samples. This makes
fouriergls the most powerful single-frequency Fourier unit root test.

{pstd}
{ul:Important warnings:}

{p 8 8 2}
{bf:1.} GLS de-trending is designed for testing near the null hypothesis.
It may not perform well far from the null.

{p 8 8 2}
{bf:2.} The c_bar parameter is model-specific. Using the wrong model
specification reduces power.

{p 8 8 2}
{bf:3.} As with all Fourier tests, check whether Fourier terms are needed
before relying on the results.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:fouriergls} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(GLSk)}}GLS test statistic{p_end}
{synopt:{cmd:r(k)}}optimal frequency{p_end}
{synopt:{cmd:r(p)}}optimal lag order{p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. sysuse gnp96, clear}{p_end}
{phang2}{cmd:. tsset date}{p_end}
{phang2}{cmd:. fouriergls gnp96}{p_end}
{phang2}{cmd:. fouriergls gnp96, model(1) graph}{p_end}


{marker references}{...}
{title:References}

{marker RT2012}{...}
{phang}
Rodrigues, P.M. and Taylor, A.R. (2012). The flexible Fourier form and local
generalised least squares de-trended unit root tests. {it:Oxford Bulletin of
Economics and Statistics}, 74(5), 736-759.
{p_end}

{phang}
Elliott, G., Rothenberg, T.J., and Stock, J.H. (1996). Efficient tests for
an autoregressive unit root. {it:Econometrica}, 64(4), 813-836.
{p_end}


{title:Authors}

{pstd}
Dr. Merwan Roudane{break}
Email: merwanroudane920@gmail.com{p_end}



{title:Also see}

{psee}
{space 2}Help:  {helpb fourierlm}, {helpb fourierdf}, {helpb fourierkpss},
{helpb fourierfffff}, {helpb fourierdfdf}, {helpb fourierall}
{p_end}
