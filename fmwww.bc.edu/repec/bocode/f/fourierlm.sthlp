{smcl}
{* *! version 1.0  11mar2026}{...}
{viewerjumpto "Syntax" "fourierlm##syntax"}{...}
{viewerjumpto "Description" "fourierlm##description"}{...}
{viewerjumpto "Options" "fourierlm##options"}{...}
{viewerjumpto "Methodology" "fourierlm##methodology"}{...}
{viewerjumpto "Interpretation" "fourierlm##interpretation"}{...}
{viewerjumpto "Stored results" "fourierlm##stored"}{...}
{viewerjumpto "Examples" "fourierlm##examples"}{...}
{viewerjumpto "References" "fourierlm##references"}{...}
{viewerjumpto "Authors" "fourierlm##authors"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:fourierlm} {hline 2}}Fourier LM unit root test with flexible Fourier form{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fourierlm}
{varname}
{ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt k:max(#)}}maximum Fourier frequency to search; default is {cmd:kmax(5)}{p_end}
{synopt:{opt k(#)}}fixed frequency; default is {cmd:k(0)} meaning data-driven selection{p_end}
{synopt:{opt p:max(#)}}maximum lag order for augmentation; default is {cmd:pmax(8)}{p_end}
{synopt:{opt ic(#)}}information criterion for lag selection: {cmd:1}=AIC, {cmd:2}=SIC, {cmd:3}=t-statistic; default is {cmd:ic(3)}{p_end}
{synopt:{opt graph}}display plot of observed series overlaid with Fourier expansion{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fourierlm} implements the Fourier LM unit root test proposed by
{help fourierlm##EL2012a:Enders and Lee (2012a)}. This test extends the
Schmidt-Phillips (1992) LM unit root test by incorporating a flexible Fourier
form to capture unknown structural breaks in the deterministic trend.

{pstd}
The key advantage of this approach is that the Fourier approximation can capture
the essential characteristics of an unknown number of structural breaks without
specifying their number, dates, or functional form. Unlike dummy variable approaches,
this method does not require pre-testing for break locations and avoids the associated
nuisance parameter problem.

{pstd}
The data must be {cmd:tsset} before using this command.


{marker options}{...}
{title:Options}

{phang}
{opt kmax(#)} specifies the maximum integer frequency to consider in the Fourier
approximation. Becker, Enders, and Lee (2006) recommend using small values of
{it:k} (typically up to 5) to capture low-frequency structural breaks.
Larger frequencies tend to capture short-run dynamics rather than structural breaks.
Default is {cmd:kmax(5)}.

{phang}
{opt k(#)} specifies a fixed Fourier frequency. When {cmd:k(0)} (the default),
the optimal frequency is selected by minimizing the sum of squared residuals (SSR)
over {it:k} = 1, ..., {it:kmax}. Setting a specific value bypasses the search.

{phang}
{opt pmax(#)} specifies the maximum number of augmented lags to include for
correcting serial correlation. Default is {cmd:pmax(8)}.

{phang}
{opt ic(#)} specifies the information criterion used to select the optimal lag
length: {cmd:1} = Akaike Information Criterion (AIC), {cmd:2} = Schwarz
Information Criterion (SIC/BIC), {cmd:3} = sequential t-statistic method at 10%
significance level. Default is {cmd:ic(3)}.

{phang}
{opt graph} displays a plot with two lines: the observed time series (blue, thin)
and the fitted Fourier expansion series (red, thick). This visualization shows how
well the Fourier deterministic component captures the smooth structural changes
in the data.


{marker methodology}{...}
{title:Methodology}

{pstd}
The Fourier LM test is based on the following data-generating process:

{p 8 8 2}
y_t = d_t + e_t,  where e_t = rho * e_{t-1} + epsilon_t

{pstd}
The deterministic component d_t is approximated using a Fourier expansion:

{p 8 8 2}
d_t = c_0 + c_1*t + alpha*sin(2*pi*k*t/T) + beta*cos(2*pi*k*t/T)

{pstd}
The LM test regression (in first differences) is:

{p 8 8 2}
Delta(y_t) = d_1 + d_2*t + d_3*sin(2*pi*k*t/T) + d_4*cos(2*pi*k*t/T)
             + phi*S_{t-1} + sum_{j=1}^{p} a_j*Delta(y_{t-j}) + u_t

{pstd}
where S_{t-1} is the de-trended series from a first-stage regression. The null
hypothesis is H0: phi = 0 (unit root). The test statistic is the t-ratio on phi.

{pstd}
Optimal frequency k* is determined by minimizing the SSR of the LM regression
over k = 1, ..., kmax. An F-test for the joint significance of the Fourier terms
(alpha = beta = 0) is also reported.


{marker interpretation}{...}
{title:Interpretation}

{pstd}
{bf:Null hypothesis:} The series has a unit root.{break}
{bf:Alternative hypothesis:} The series is stationary around a Fourier deterministic trend.

{pstd}
{bf:Decision rule:} Reject the null if the LM statistic is {it:more negative} than
the critical value at the chosen significance level.

{pstd}
{bf:F-test:} Before interpreting the LM statistic, check the F-test for nonlinearity.
If the F-test cannot reject H0: alpha = beta = 0, the Fourier terms are not significant,
and the standard LM unit root test (without Fourier terms) should be preferred.

{pstd}
{bf:Frequency interpretation:} Optimal frequency k = 1 suggests a single smooth
structural change over the sample period. Higher values of k indicate more frequent
or complex changes.

{pstd}
{ul:Cautions:}

{p 8 8 2}
{bf:1.} This test assumes smooth structural breaks. For sharp or instantaneous
breaks, dummy-based tests (e.g., Zivot-Andrews) may be more appropriate.

{p 8 8 2}
{bf:2.} Power may be reduced if the true DGP does not contain nonlinear
deterministic components. Always check the F-test.

{p 8 8 2}
{bf:3.} The test requires sufficient sample size. Small samples (T < 50)
may produce unreliable results.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:fourierlm} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(LMk)}}LM test statistic{p_end}
{synopt:{cmd:r(k)}}optimal Fourier frequency{p_end}
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

{pstd}Basic LM test with defaults{p_end}
{phang2}{cmd:. fourierlm gnp96}{p_end}

{pstd}LM test with AIC lag selection and graph{p_end}
{phang2}{cmd:. fourierlm gnp96, ic(1) graph}{p_end}

{pstd}LM test with fixed frequency k=2{p_end}
{phang2}{cmd:. fourierlm gnp96, k(2)}{p_end}

{pstd}Return stored results{p_end}
{phang2}{cmd:. return list}{p_end}


{marker references}{...}
{title:References}

{marker EL2012a}{...}
{phang}
Enders, W. and Lee, J. (2012a). A unit root test using a Fourier series to
approximate smooth breaks. {it:Oxford Bulletin of Economics and Statistics},
74(4), 574-599.
{p_end}

{phang}
Becker, R., Enders, W., and Lee, J. (2006). A stationarity test in the
presence of an unknown number of smooth breaks. {it:Journal of Time Series
Analysis}, 27(3), 381-409.
{p_end}

{phang}
Schmidt, P. and Phillips, P.C. (1992). LM tests for a unit root in the
presence of deterministic trends. {it:Oxford Bulletin of Economics and
Statistics}, 54(3), 257-287.
{p_end}


{marker authors}{...}
{title:Authors}

{pstd}
Dr. Merwan Roudane{break}
Email: merwanroudane920@gmail.com{p_end}



{title:Also see}

{psee}
{space 2}Help:  {helpb fourierdf}, {helpb fouriergls}, {helpb fourierkpss},
{helpb fourierfffff}, {helpb fourierdfdf}, {helpb fourierall}
{p_end}
