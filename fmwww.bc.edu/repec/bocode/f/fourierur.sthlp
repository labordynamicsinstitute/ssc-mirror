{smcl}
{* *! version 1.1  15jul2026}{...}
{viewerjumpto "Syntax" "fourierur##syntax"}{...}
{viewerjumpto "Description" "fourierur##description"}{...}
{viewerjumpto "Sub-commands" "fourierur##subcommands"}{...}
{viewerjumpto "Options" "fourierur##options"}{...}
{viewerjumpto "Test summary" "fourierur##tests"}{...}
{viewerjumpto "Interpretation" "fourierur##interpretation"}{...}
{viewerjumpto "Examples" "fourierur##examples"}{...}
{viewerjumpto "Stored results" "fourierur##results"}{...}
{viewerjumpto "References" "fourierur##references"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:fourierur} {hline 2}}Flexible Fourier Form unit root and stationarity tests (main command){p_end}
{p2colreset}{...}


{marker subcommands}{...}
{title:Quick navigation: individual test help files}

{pstd}
Click any link below to jump straight to that test's help file:
{p_end}

{p 8 8 2}
{bf:[1]} {helpb fourierlm}     {space 4}Fourier LM unit root test (Enders & Lee, 2012a){break}
{bf:[2]} {helpb fourierdf}     {space 4}Fourier ADF unit root test (Enders & Lee, 2012b){break}
{bf:[3]} {helpb fouriergls}    {space 3}Fourier GLS unit root test (Rodrigues & Taylor, 2012){break}
{bf:[4]} {helpb fourierkpss}   {space 2}Fourier KPSS stationarity test (Becker, Enders & Lee, 2006){break}
{bf:[5]} {helpb fourierfffff}  {space 1}Fractional-frequency FFFFF-DF test (Omay, 2015){break}
{bf:[6]} {helpb fourierdfdf}   {space 2}Double-frequency Fourier DF + sieve bootstrap (Cai & Omay, 2021; Gerolimetto & Magrini, 2026)
{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fourierur}
{varname}
{ifin}
[{cmd:,} {opt test(name)} {it:other_options}]

{pstd}
where {it:name} selects which test to run:
{p_end}

{synoptset 14 tabbed}{...}
{synopthdr:test(name)}
{synoptline}
{synopt:{opt lm}}run {helpb fourierlm}{p_end}
{synopt:{opt df}}run {helpb fourierdf}{p_end}
{synopt:{opt gls}}run {helpb fouriergls}{p_end}
{synopt:{opt kpss}}run {helpb fourierkpss}{p_end}
{synopt:{opt fffff}}run {helpb fourierfffff}{p_end}
{synopt:{opt dfdf}}run {helpb fourierdfdf}{p_end}
{synopt:{opt all}}run all six tests in sequence ({it:default}){p_end}
{synoptline}


{synoptset 22 tabbed}{...}
{synopthdr:other_options}
{synoptline}
{synopt:{opt m:odel(#)}}deterministic specification: {cmd:1}=constant, {cmd:2}=constant+trend; default {cmd:model(2)}{p_end}
{synopt:{opt notr:end}}equivalent to {cmd:model(1)}{p_end}
{synopt:{opt k:max(#)}}maximum Fourier frequency (integer for most tests); default {cmd:kmax(5)}{p_end}
{synopt:{opt k(#)}}fixed frequency; default {cmd:k(0)} = data-driven{p_end}
{synopt:{opt p:max(#)}}maximum lag order; default {cmd:pmax(8)}{p_end}
{synopt:{opt ic(#)}}lag-selection criterion: {cmd:1}=AIC, {cmd:2}=SIC, {cmd:3}=t-stat; default {cmd:ic(3)}{p_end}
{synopt:{opt graph}}draw the Fourier-fit graph for the selected test(s){p_end}
{synopt:{opt kfmin(#)}}({helpb fourierfffff:fffff} only) lower bound of fractional grid; default {cmd:0.1}{p_end}
{synopt:{opt kfmax(#)}}({helpb fourierfffff:fffff} only) upper bound of fractional grid; default {cmd:2.0}{p_end}
{synopt:{opt kfstep(#)}}({helpb fourierfffff:fffff} only) grid step; default {cmd:0.1}{p_end}
{synopt:{opt kfr(#)}}({helpb fourierfffff:fffff} only) fixed fractional frequency; default {cmd:0} = data-driven{p_end}
{synopt:{opt noftest}}({helpb fourierfffff:fffff} only) suppress F-test on Fourier terms{p_end}
{synopt:{opt dk(#)}}({helpb fourierdfdf:dfdf} only) frequency step; {cmd:1}=integer, {cmd:0.1}=fractional; default {cmd:dk(1)}{p_end}
{synopt:{opt boot:strap}}({helpb fourierdfdf:dfdf} only) compute sieve-bootstrap critical values{p_end}
{synopt:{opt breps(#)}}({helpb fourierdfdf:dfdf} only) bootstrap replications; default {cmd:breps(500)}{p_end}
{synoptline}

{pstd}
{varname} must be {cmd:tsset} as a time-series variable.
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fourierur} is the {bf:single main command} of the {cmd:fourierur} package.
It provides a unified interface to six Fourier-based unit root and
stationarity tests that use a Flexible Fourier Form (FFF) to approximate
unknown smooth structural breaks.
{p_end}

{pstd}
With {opt test(name)} you pick {it:one} test to run; with {opt test(all)}
(the default) it runs all six tests sequentially and prints a comparative
summary. Each test can also still be called directly by name — see the
links at the top of this help file.
{p_end}


{marker tests}{...}
{title:Test summary}

{pstd}
{bf:Quick reference for the six tests:}

{col 5}{bf:test()}{col 18}{bf:Command}{col 35}{bf:H0}{col 53}{bf:Frequency}{col 68}{bf:Method}
{col 5}{hline 78}
{col 5}lm{col 18}{helpb fourierlm}{col 35}Unit root{col 53}Integer{col 68}LM (SP-type)
{col 5}df{col 18}{helpb fourierdf}{col 35}Unit root{col 53}Integer{col 68}ADF (OLS)
{col 5}gls{col 18}{helpb fouriergls}{col 35}Unit root{col 53}Integer{col 68}ADF (GLS)
{col 5}kpss{col 18}{helpb fourierkpss}{col 35}Stationarity{col 53}Integer{col 68}KPSS
{col 5}fffff{col 18}{helpb fourierfffff}{col 35}Unit root{col 53}Fractional{col 68}ADF (OLS)
{col 5}dfdf{col 18}{helpb fourierdfdf}{col 35}Unit root{col 53}Double{col 68}ADF (OLS) + boot

{pstd}
{bf:Note:} {helpb fourierkpss} has the {ul:reversed} null hypothesis.
Rejecting the KPSS null = evidence the series is {it:not} stationary, which
is consistent with failing to reject the unit-root null in the other five
tests.
{p_end}


{marker interpretation}{...}
{title:Interpretation guidelines}

{pstd}
{bf:Recommended decision strategy:}
{p_end}

{p 8 8 2}
{bf:Step 1.} Check whether the Fourier terms are significant (F-test in
{helpb fourierdf}, {helpb fourierfffff}, {helpb fourierdfdf}). If the
Fourier component is not significant, compare results to standard
(non-Fourier) unit root tests such as {cmd:dfuller} / {cmd:dfgls} /
{cmd:kpss}.

{p 8 8 2}
{bf:Step 2.} Compare the unit-root tests (lm, df, gls, fffff, dfdf).
Concordance across tests strengthens the conclusion.

{p 8 8 2}
{bf:Step 3.} Confirm with the KPSS stationarity test. UR tests fail to
reject {it:and} KPSS rejects ==> strong evidence of a unit root. UR tests
reject {it:and} KPSS fails to reject ==> strong evidence of stationarity.

{p 8 8 2}
{bf:Step 4.} Use {opt graph} to visually inspect the Fourier fit. A close
fit supports the validity of the Fourier-based tests.

{pstd}
{ul:Practical notes:}
{p_end}

{p 8 8 2}
{bf:-} Different tests may disagree. Give more weight to GLS-based tests
for power, and to LM tests for robustness to initial conditions.

{p 8 8 2}
{bf:-} {helpb fourierdfdf} with {cmd:dk(0.1)} is the most powerful but the
most computationally expensive. Under {cmd:test(all)} it runs with the
default {cmd:dk(1)}. For maximum power call {cmd:fourierur} with
{cmd:test(dfdf) dk(0.1)} (or call {helpb fourierdfdf} directly).

{p 8 8 2}
{bf:-} All tests require {cmd:tsset}. Gaps in the time series may give
unreliable results.

{p 8 8 2}
{bf:-} Minimum recommended sample size: T >= 50.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse gnp96, clear}{p_end}
{phang2}{cmd:. tsset date}{p_end}

{pstd}Run all six tests (default){p_end}
{phang2}{cmd:. fourierur gnp96}{p_end}
{phang2}{cmd:. fourierur gnp96, test(all) graph}{p_end}

{pstd}Run a single test by name{p_end}
{phang2}{cmd:. fourierur gnp96, test(lm)}{p_end}
{phang2}{cmd:. fourierur gnp96, test(df) graph}{p_end}
{phang2}{cmd:. fourierur gnp96, test(gls) notrend}{p_end}
{phang2}{cmd:. fourierur gnp96, test(kpss) graph}{p_end}
{phang2}{cmd:. fourierur gnp96, test(fffff) kfstep(0.05) kfmax(3) graph}{p_end}
{phang2}{cmd:. fourierur gnp96, test(dfdf) dk(0.1) graph}{p_end}

{pstd}Maximum-power DFDF with sieve-bootstrap critical values{p_end}
{phang2}{cmd:. fourierur gnp96, test(dfdf) dk(0.1) bootstrap breps(500) graph}{p_end}

{pstd}Constant-only model on all tests{p_end}
{phang2}{cmd:. fourierur gnp96, test(all) notrend}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
When {opt test()} selects a single test, {cmd:fourierur} returns the
underlying test's {cmd:r()} results unchanged, plus:
{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(test)}}name of the test that was run ({cmd:lm}, {cmd:df},
{cmd:gls}, {cmd:kpss}, {cmd:fffff}, {cmd:dfdf}, or {cmd:all}){p_end}

{pstd}
For {opt test(all)} only {cmd:r(test) = "all"} is returned; consult each
sub-command's help for its own {cmd:r()} results.
{p_end}


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


{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: merwanroudane920@gmail.com{p_end}


{title:Also see}

{psee}
{space 2}Individual test help:{break}
{space 4}{helpb fourierlm}   {space 2}- Fourier LM (Enders & Lee 2012a){break}
{space 4}{helpb fourierdf}   {space 2}- Fourier ADF (Enders & Lee 2012b){break}
{space 4}{helpb fouriergls}  {space 1}- Fourier GLS (Rodrigues & Taylor 2012){break}
{space 4}{helpb fourierkpss} {space 0}- Fourier KPSS (Becker, Enders & Lee 2006){break}
{space 4}{helpb fourierfffff}{space 0}- FFFFF-DF (Omay 2015){break}
{space 4}{helpb fourierdfdf} {space 0}- Double-frequency Fourier DF (Cai & Omay 2021)
{p_end}
