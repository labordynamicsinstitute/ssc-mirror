{smcl}
{* *! version 1.0  11mar2026}{...}
{viewerjumpto "Syntax" "fourierkpss##syntax"}{...}
{viewerjumpto "Description" "fourierkpss##description"}{...}
{viewerjumpto "Options" "fourierkpss##options"}{...}
{viewerjumpto "Methodology" "fourierkpss##methodology"}{...}
{viewerjumpto "Interpretation" "fourierkpss##interpretation"}{...}
{viewerjumpto "Stored results" "fourierkpss##stored"}{...}
{viewerjumpto "Examples" "fourierkpss##examples"}{...}
{viewerjumpto "References" "fourierkpss##references"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{cmd:fourierkpss} {hline 2}}Fourier KPSS stationarity test{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fourierkpss}
{varname}
{ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt m:odel(#)}}deterministic specification: {cmd:1}=constant, {cmd:2}=constant+trend; default is {cmd:model(2)}{p_end}
{synopt:{opt k:max(#)}}maximum Fourier frequency; default is {cmd:kmax(5)}{p_end}
{synopt:{opt k(#)}}fixed frequency; default is {cmd:k(0)} (data-driven){p_end}
{synopt:{opt notr:end}}equivalent to {cmd:model(1)}{p_end}
{synopt:{opt graph}}display observed vs. Fourier expansion plot{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fourierkpss} implements the Fourier KPSS stationarity test proposed by
{help fourierkpss##BEL2006:Becker, Enders, and Lee (2006)}. Unlike unit root tests
(which test H0: unit root), the KPSS test reverses the hypotheses: the null
hypothesis is stationarity.

{pstd}
This reversal is valuable because it provides a complementary perspective.
Using both a unit root test (e.g., {cmd:fourierlm}) and the KPSS test together
provides stronger inference about the order of integration.

{pstd}
The data must be {cmd:tsset} before using this command.


{marker options}{...}
{title:Options}

{phang}
{opt model(#)} deterministic specification: {cmd:model(1)} = level stationarity,
{cmd:model(2)} = trend stationarity. Default is {cmd:model(2)}.

{phang}
{opt kmax(#)} maximum Fourier frequency. Default is {cmd:kmax(5)}.

{phang}
{opt k(#)} fixed frequency. Default {cmd:k(0)} = data-driven selection.

{phang}
{opt notrend} equivalent to {cmd:model(1)}.

{phang}
{opt graph} displays observed series vs. Fourier expansion plot.


{marker methodology}{...}
{title:Methodology}

{pstd}
The KPSS test decomposes the series as:

{p 8 8 2}
y_t = d_t + r_t + epsilon_t

{pstd}
where d_t is the deterministic component (approximated by Fourier terms),
r_t is a random walk, and epsilon_t is a stationary error. The null hypothesis
of stationarity corresponds to H0: var(r_t) = 0.

{pstd}
The KPSS statistic is based on the partial sum of OLS residuals from the
regression of y_t on the Fourier deterministic terms. Under H0, the statistic
converges to a functional of Brownian motion.

{pstd}
{bf:Note on lag truncation:} This implementation uses the Newey-West bandwidth
for long-run variance estimation.


{marker interpretation}{...}
{title:Interpretation}

{pstd}
{bf:Null hypothesis:} The series is stationary (around a Fourier deterministic trend).{break}
{bf:Alternative:} The series has a unit root.

{pstd}
{bf:Decision rule:} Reject stationarity if the KPSS statistic {it:exceeds}
the critical value. Note this is the {ul:opposite} of unit root tests.

{pstd}
{ul:Confirmatory analysis strategy:}

{p 8 8 2}
Apply both a unit root test (e.g., {cmd:fourierlm}) and {cmd:fourierkpss} to the
same series:{break}
- If the unit root test rejects AND KPSS does not reject: strong evidence of stationarity.{break}
- If the unit root test does not reject AND KPSS rejects: strong evidence of unit root.{break}
- If both reject or neither rejects: evidence is inconclusive.

{pstd}
{ul:Cautions:}

{p 8 8 2}
{bf:1.} The KPSS test has known size distortions in small samples. Interpret
borderline rejections carefully.

{p 8 8 2}
{bf:2.} The test may over-reject the null in the presence of strong serial
correlation or large structural breaks.


{marker stored}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(KPSSk)}}KPSS test statistic{p_end}
{synopt:{cmd:r(k)}}optimal frequency{p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. sysuse gnp96, clear}{p_end}
{phang2}{cmd:. tsset date}{p_end}
{phang2}{cmd:. fourierkpss gnp96}{p_end}
{phang2}{cmd:. fourierkpss gnp96, model(1) graph}{p_end}


{marker references}{...}
{title:References}

{marker BEL2006}{...}
{phang}
Becker, R., Enders, W., and Lee, J. (2006). A stationarity test in the
presence of an unknown number of smooth breaks. {it:Journal of Time Series
Analysis}, 27(3), 381-409.
{p_end}

{phang}
Kwiatkowski, D., Phillips, P.C.B., Schmidt, P., and Shin, Y. (1992).
Testing the null hypothesis of stationarity against the alternative of a unit
root. {it:Journal of Econometrics}, 54(1-3), 159-178.
{p_end}


{title:Authors}

{pstd}
Dr. Merwan Roudane{break}
Email: merwanroudane920@gmail.com{p_end}



{title:Also see}

{psee}
{space 2}Help:  {helpb fourierlm}, {helpb fourierdf}, {helpb fouriergls},
{helpb fourierfffff}, {helpb fourierdfdf}, {helpb fourierall}
{p_end}
