{smcl}
{* *! version 2.0  11mar2026}{...}
{viewerjumpto "Syntax" "fourierall##syntax"}{...}
{viewerjumpto "Description" "fourierall##description"}{...}
{viewerjumpto "Options" "fourierall##options"}{...}
{viewerjumpto "Test summary" "fourierall##tests"}{...}
{viewerjumpto "Interpretation" "fourierall##interpretation"}{...}
{viewerjumpto "Examples" "fourierall##examples"}{...}
{viewerjumpto "References" "fourierall##references"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{cmd:fourierall} {hline 2}}Run all Fourier unit root and stationarity tests{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fourierall}
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
{synopt:{opt graph}}display graphs from all tests{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fourierall} is a convenience command that runs all six Fourier-based unit root
and stationarity tests sequentially on the specified variable. It provides a
comprehensive assessment of the unit root hypothesis using multiple methodologies.

{pstd}
The command runs:

{p 8 8 2}
1. {helpb fourierlm} - Fourier LM test (Enders & Lee, 2012a){break}
2. {helpb fourierdf} - Fourier ADF test (Enders & Lee, 2012b){break}
3. {helpb fouriergls} - Fourier GLS test (Rodrigues & Taylor, 2012){break}
4. {helpb fourierkpss} - Fourier KPSS stationarity test (Becker, Enders & Lee, 2006){break}
5. {helpb fourierfffff} - FFFFF-DF test (Omay, 2015){break}
6. {helpb fourierdfdf} - Double Frequency Fourier DF test (Cai & Omay, 2021)

{pstd}
The data must be {cmd:tsset} before using this command.


{marker options}{...}
{title:Options}

{pstd}
Options are passed through to the individual test commands as appropriate.
Not all options apply to all tests:

{p 8 8 2}
{opt model(#)}: Passed to fourierdf, fouriergls, fourierkpss, fourierfffff, fourierdfdf.
Not used by fourierlm (which has no model option).{break}
{opt kmax(#)}: Passed to fourierlm, fourierdf, fouriergls, fourierkpss.{break}
{opt k(#)}: Passed to fourierlm, fourierdf, fouriergls, fourierkpss.
Not passed to fourierfffff (uses kfr) or fourierdfdf (uses dk, ks, kc).{break}
{opt pmax(#)}: Passed to fourierlm, fourierdf, fouriergls, fourierfffff, fourierdfdf.{break}
{opt ic(#)}: Passed to fourierlm, fourierdf, fouriergls, fourierfffff, fourierdfdf.{break}
{opt graph}: Passed to all tests.


{marker tests}{...}
{title:Test summary}

{pstd}
{bf:Understanding the six tests:}

{col 5}{bf:Test}{col 30}{bf:H0}{col 50}{bf:Frequency}{col 65}{bf:Method}
{col 5}{hline 65}
{col 5}fourierlm{col 30}Unit root{col 50}Integer{col 65}LM (SP-type)
{col 5}fourierdf{col 30}Unit root{col 50}Integer{col 65}ADF (OLS)
{col 5}fouriergls{col 30}Unit root{col 50}Integer{col 65}ADF (GLS)
{col 5}fourierkpss{col 30}Stationarity{col 50}Integer{col 65}KPSS
{col 5}fourierfffff{col 30}Unit root{col 50}Fractional{col 65}ADF (OLS)
{col 5}fourierdfdf{col 30}Unit root{col 50}Double{col 65}ADF (OLS)

{pstd}
{bf:Note:} The KPSS test (test 4) has the {ul:opposite} null hypothesis.
Rejecting the KPSS null means the series is {it:not} stationary, which is
consistent with not rejecting the unit root null in the other tests.


{marker interpretation}{...}
{title:Interpretation guidelines}

{pstd}
{bf:Recommended decision strategy:}

{p 8 8 2}
{bf:Step 1:} Examine whether Fourier terms are significant (F-test in fourierdf,
fourierfffff, fourierdfdf). If not significant for any test, compare with
standard (non-Fourier) unit root tests.

{p 8 8 2}
{bf:Step 2:} Compare unit root test results (tests 1-3, 5-6). Concordance
across multiple tests strengthens the conclusion.

{p 8 8 2}
{bf:Step 3:} Check the KPSS test (test 4) for confirmation. If the KPSS test
rejects stationarity AND the unit root tests fail to reject, there is strong
evidence of a unit root.

{p 8 8 2}
{bf:Step 4:} Use the {opt graph} option to visually inspect the Fourier fits.
A good fit between the Fourier expansion and the observed series supports the
validity of the Fourier-based tests.

{pstd}
{ul:Important warnings:}

{p 8 8 2}
{bf:1.} Different tests may disagree. This is normal and reflects differences
in methodology and power. Give more weight to GLS-based tests (fouriergls)
for power, and to LM tests (fourierlm) for robustness to initial conditions.

{p 8 8 2}
{bf:2.} The DFDF test with dk(0.1) is the most powerful but also the most
computationally intensive. It is run with default dk(1) (integer frequencies)
via fourierall. For maximum power, run {cmd:fourierdfdf} separately with
{cmd:dk(0.1)}.

{p 8 8 2}
{bf:3.} All tests require the data to be {cmd:tsset}. Gaps in the time series
may produce unreliable results.

{p 8 8 2}
{bf:4.} Minimum recommended sample size: T >= 50.


{marker examples}{...}
{title:Examples}

{pstd}Run all tests with defaults{p_end}
{phang2}{cmd:. sysuse gnp96, clear}{p_end}
{phang2}{cmd:. tsset date}{p_end}
{phang2}{cmd:. fourierall gnp96}{p_end}

{pstd}Run all tests with graphs{p_end}
{phang2}{cmd:. fourierall gnp96, graph}{p_end}

{pstd}Run all tests with constant-only model{p_end}
{phang2}{cmd:. fourierall gnp96, notrend}{p_end}

{pstd}Run individual test separately for more control{p_end}
{phang2}{cmd:. fourierdfdf gnp96, dk(0.1) bootstrap breps(500) graph}{p_end}


{marker references}{...}
{title:References}

{phang}
Becker, R., Enders, W., and Lee, J. (2006). A stationarity test in the
presence of an unknown number of smooth breaks. {it:Journal of Time Series
Analysis}, 27(3), 381-409.
{p_end}

{phang}
Cai, Y. and Omay, T. (2021). Using double frequency in Fourier Dickey-Fuller
unit root test. {it:Computational Economics}, 59, 445-470.
{p_end}

{phang}
Enders, W. and Lee, J. (2012a). A unit root test using a Fourier series to
approximate smooth breaks. {it:Oxford Bulletin of Economics and Statistics},
74(4), 574-599.
{p_end}

{phang}
Enders, W. and Lee, J. (2012b). The flexible Fourier form and Dickey-Fuller
type unit root tests. {it:Economics Letters}, 117(1), 196-199.
{p_end}

{phang}
Gerolimetto, M. and Magrini, S. (2026). Bootstrap double frequency Dickey
Fuller test for unit roots. {it:Rivista Italiana di Economia Demografia e
Statistica}, LXXX(3), 332-342.
{p_end}

{phang}
Omay, T. (2015). Fractional frequency flexible Fourier form to approximate
smooth breaks in unit root testing. {it:Economics Letters}, 134, 123-126.
{p_end}

{phang}
Rodrigues, P.M. and Taylor, A.R. (2012). The flexible Fourier form and local
generalised least squares de-trended unit root tests. {it:Oxford Bulletin of
Economics and Statistics}, 74(5), 736-759.
{p_end}


{title:Authors}

{pstd}
Dr. Merwan Roudane{break}
Email: merwanroudane920@gmail.com{p_end}



{title:Also see}

{psee}
{space 2}Help:  {helpb fourierlm}, {helpb fourierdf}, {helpb fouriergls},
{helpb fourierkpss}, {helpb fourierfffff}, {helpb fourierdfdf}
{p_end}
