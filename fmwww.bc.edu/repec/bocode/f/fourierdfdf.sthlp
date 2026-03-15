{smcl}
{* *! version 1.0  11mar2026}{...}
{viewerjumpto "Syntax" "fourierdfdf##syntax"}{...}
{viewerjumpto "Description" "fourierdfdf##description"}{...}
{viewerjumpto "Options" "fourierdfdf##options"}{...}
{viewerjumpto "Methodology" "fourierdfdf##methodology"}{...}
{viewerjumpto "Bootstrap" "fourierdfdf##bootstrap"}{...}
{viewerjumpto "Interpretation" "fourierdfdf##interpretation"}{...}
{viewerjumpto "Stored results" "fourierdfdf##stored"}{...}
{viewerjumpto "Examples" "fourierdfdf##examples"}{...}
{viewerjumpto "References" "fourierdfdf##references"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:fourierdfdf} {hline 2}}Double Frequency Fourier Dickey-Fuller unit root test{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fourierdfdf}
{varname}
{ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt m:odel(#)}}deterministic specification: {cmd:1}=constant, {cmd:2}=constant+trend; default is {cmd:model(2)}{p_end}
{synopt:{opt kmax(#)}}maximum frequency; default is {cmd:kmax(3)}{p_end}
{synopt:{opt dk(#)}}search precision (Delta k); default is {cmd:dk(1)}{p_end}
{synopt:{opt p:max(#)}}maximum lag order; default is {cmd:pmax(8)}{p_end}
{synopt:{opt ic(#)}}information criterion: {cmd:1}=AIC, {cmd:2}=SIC, {cmd:3}=t-stat; default is {cmd:ic(3)}{p_end}
{synopt:{opt notr:end}}equivalent to {cmd:model(1)}{p_end}
{synopt:{opt graph}}display comparison plot of single vs. double frequency fit{p_end}
{synopt:{opt boot:strap}}compute Sieve Bootstrap critical values (Gerolimetto & Magrini, 2026){p_end}
{synopt:{opt breps(#)}}number of bootstrap replications; default is {cmd:breps(500)}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fourierdfdf} implements the Double Frequency Fourier Dickey-Fuller (DFDF)
unit root test proposed by {help fourierdfdf##CO2021:Cai and Omay (2021)},
with an optional Sieve Bootstrap extension following
{help fourierdfdf##GM2026:Gerolimetto and Magrini (2026)}.

{pstd}
{bf:Key innovation:} Unlike standard Fourier tests that use a {it:single}
frequency k for both sine and cosine components, the DFDF test allows
{it:different} frequencies: k_s for the sine component and k_c for the cosine
component. This enables the test to capture {bf:asymmetrically located}
structural breaks, where the timing and magnitude of upward and downward shifts
differ.

{pstd}
This test is more powerful than single-frequency methods when structural breaks
are (i) located at the beginning or end of the sample, (ii) asymmetrically
distributed, or (iii) involve complex smooth transitions (LSTAR, ESTAR).

{pstd}
The data must be {cmd:tsset} before using this command.


{marker options}{...}
{title:Options}

{phang}
{opt model(#)} deterministic specification: {cmd:model(1)} = constant only;
{cmd:model(2)} = constant + trend. Default is {cmd:model(2)}.

{phang}
{opt kmax(#)} maximum frequency for the grid search. Cai and Omay (2021) use
{cmd:kmax(3)} in their simulations. Default is {cmd:kmax(3)}.

{phang}
{opt dk(#)} search precision (Delta k). Controls the step size of the grid
search over frequency pairs.{break}
{cmd:dk(1)} searches integer frequencies only (k_s, k_c = 1, 2, ..., kmax).{break}
{cmd:dk(0.1)} searches fractional frequencies (k_s, k_c = 0.1, 0.2, ..., kmax).{break}
Smaller values yield more precise frequency selection but increase computation time.
Default is {cmd:dk(1)}. Cai and Omay (2021) recommend {cmd:dk(0.1)} for
maximum power.

{phang}
{opt pmax(#)} maximum lag order for augmented lags. Default is {cmd:pmax(8)}.

{phang}
{opt ic(#)} lag selection criterion. Default is {cmd:ic(3)}.

{phang}
{opt notrend} equivalent to {cmd:model(1)}.

{phang}
{opt graph} displays a three-line comparison plot:{break}
{space 4}Black (thick) = observed series{break}
{space 4}Red = double frequency Fourier fit (k_s, k_c){break}
{space 4}Blue (thin) = single frequency Fourier fit (best integer k){break}
This matches the visualization style in Cai and Omay (2021, Figs 1-4).

{phang}
{opt bootstrap} activates the Sieve Bootstrap for computing empirical critical
values, following Gerolimetto and Magrini (2026). This avoids reliance on
tabulated asymptotic critical values and can improve finite-sample performance.
{bf:Warning:} Computation time increases substantially with this option.

{phang}
{opt breps(#)} number of bootstrap replications. Default is {cmd:breps(500)}.
Gerolimetto and Magrini (2026) use 500 replications in their Monte Carlo
experiments.


{marker methodology}{...}
{title:Methodology}

{pstd}
{bf:Double frequency deterministic trend} (Eq. 2 of Cai and Omay 2021):

{p 8 8 2}
d_t^Dfr = c_0 [+ c_1*t] + alpha*sin(2*pi*k_s*t/T) + beta*cos(2*pi*k_c*t/T)

{pstd}
Note that k_s (sine frequency) and k_c (cosine frequency) can differ.
When k_s = k_c, this reduces to the standard single-frequency specification
of Enders and Lee (2012b).

{pstd}
{bf:Augmented DFDF regression} (Eq. 10):

{p 8 8 2}
Delta(y_t) = c_0 [+ c_1*t] + alpha*sin(2*pi*k_s*t/T) + beta*cos(2*pi*k_c*t/T)
             + rho*y_{t-1} + sum_{j=1}^{p} phi_j*Delta(y_{t-j}) + epsilon_t

{pstd}
The test statistic tau_Dfr is the t-ratio on rho (H0: rho = 0, i.e., unit root).

{pstd}
{bf:Grid search procedure} (Section 2.3): The optimal frequency pair (k_s*, k_c*)
is determined by minimizing the SSR over all (k_s, k_c) pairs from dk to kmax
with step size dk.

{pstd}
{bf:F-test for nonlinearity} (Eq. 6): Tests H0: alpha = beta = 0. If the F-test
fails to reject, the Fourier terms are not significant and a standard ADF test
should be used instead.


{marker bootstrap}{...}
{title:Sieve Bootstrap (Gerolimetto & Magrini, 2026)}

{pstd}
The {opt bootstrap} option implements the Pre-filtered Sieve Bootstrap Double
Frequency Dickey-Fuller (SB-DFDF) test. The algorithm:

{p 8 8 2}
1. First-difference the series: x_t = Delta(y_t){break}
2. Fit AR(p) to x_t (p selected by AIC){break}
3. Resample residuals with replacement to get epsilon_t*{break}
4. Generate bootstrap stationary series x_t* using AR coefficients and epsilon_t*{break}
5. Reconstruct bootstrap series y_t* by cumulative sum of x_t*{break}
6. Compute tau_Dfr on y_t*{break}
7. Repeat B times to obtain the empirical distribution{break}
8. Bootstrap critical values = quantiles of the empirical distribution

{pstd}
{bf:Advantages:}
{p 8 8 2}
- Does not rely on asymptotic tables (which are only available for T = 50, 150, 300){break}
- Gerolimetto and Magrini (2026) show systematically better finite-sample power{break}
- Especially useful when T does not match tabulated sample sizes


{marker interpretation}{...}
{title:Interpretation}

{pstd}
{bf:Null hypothesis:} The series has a unit root.{break}
{bf:Alternative:} The series is stationary around a double-frequency Fourier
deterministic trend.

{pstd}
{bf:Decision rule:} Reject H0 if tau_Dfr is more negative than the critical value.

{pstd}
{bf:Interpreting the frequency pair:}

{p 8 8 2}
- k_s = k_c: The double-frequency method reduces to single-frequency. The series
has symmetric structural breaks.{break}
- k_s != k_c: The series has asymmetric structural breaks. The sine and cosine
components capture different aspects of the deterministic trend.{break}
- Small frequencies (< 1): Indicate very slow smooth changes.{break}
- Larger frequencies: Indicate more rapid or multiple changes.

{pstd}
{bf:When to use dk(0.1) vs dk(1):}

{p 8 8 2}
- Use {cmd:dk(1)} (integer frequencies) as a baseline. This is computationally
faster and uses the exact critical values from Table 1 of Cai and Omay (2021).{break}
- Use {cmd:dk(0.1)} (fractional frequencies) for maximum power, especially if
the series may contain complex or asymmetric breaks. Cai and Omay (2021, Table 8)
show that power with dk=0.1 can be 70% higher than with integer frequencies.

{pstd}
{ul:Cautions and Warnings:}

{p 8 8 2}
{bf:1.} Always check the F-test first. If H0: alpha = beta = 0 cannot be rejected,
the Fourier terms are not needed and a standard ADF test is more powerful.

{p 8 8 2}
{bf:2.} Critical values are only tabulated for T = 50, 150, and 300. For other
sample sizes, the nearest tabulated value is used. Consider using the {opt bootstrap}
option for more precise critical values.

{p 8 8 2}
{bf:3.} With fractional frequencies ({cmd:dk(0.1)}) and {cmd:kmax(3)}, the grid
search evaluates 30x30 = 900 frequency pairs. This is computationally intensive
for large datasets.

{p 8 8 2}
{bf:4.} When combined with {opt bootstrap}, computation time is B * 900
regressions. Consider reducing {opt breps} or increasing {opt dk}.

{p 8 8 2}
{bf:5.} The test is most powerful for smooth breaks (LSTAR, ESTAR) and
asymmetric breaks. For sharp instantaneous breaks, dummy-based tests may be
more appropriate.


{marker stored}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(tau_dfr)}}tau_Dfr test statistic{p_end}
{synopt:{cmd:r(ks)}}optimal sine frequency{p_end}
{synopt:{cmd:r(kc)}}optimal cosine frequency{p_end}
{synopt:{cmd:r(p)}}optimal lag order{p_end}
{synopt:{cmd:r(F_dfr)}}F-statistic for Fourier terms{p_end}
{synopt:{cmd:r(cv1)}}1% asymptotic critical value{p_end}
{synopt:{cmd:r(cv5)}}5% asymptotic critical value{p_end}
{synopt:{cmd:r(cv10)}}10% asymptotic critical value{p_end}
{synopt:{cmd:r(Fcv90)}}F-test 90% critical value{p_end}
{synopt:{cmd:r(Fcv95)}}F-test 95% critical value{p_end}
{synopt:{cmd:r(Fcv99)}}F-test 99% critical value{p_end}
{synopt:{cmd:r(bcv1)}}1% bootstrap critical value (if {opt bootstrap}){p_end}
{synopt:{cmd:r(bcv5)}}5% bootstrap critical value (if {opt bootstrap}){p_end}
{synopt:{cmd:r(bcv10)}}10% bootstrap critical value (if {opt bootstrap}){p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse gnp96, clear}{p_end}
{phang2}{cmd:. tsset date}{p_end}

{pstd}DFDF test with integer frequencies (default){p_end}
{phang2}{cmd:. fourierdfdf gnp96}{p_end}

{pstd}DFDF test with fractional frequencies (Dk=0.1){p_end}
{phang2}{cmd:. fourierdfdf gnp96, dk(0.1)}{p_end}

{pstd}DFDF test with graph (3-line comparison plot){p_end}
{phang2}{cmd:. fourierdfdf gnp96, dk(0.1) graph}{p_end}

{pstd}DFDF test with Sieve Bootstrap critical values{p_end}
{phang2}{cmd:. fourierdfdf gnp96, dk(0.1) bootstrap breps(500)}{p_end}

{pstd}DFDF test with constant-only model{p_end}
{phang2}{cmd:. fourierdfdf gnp96, notrend}{p_end}

{pstd}View stored results{p_end}
{phang2}{cmd:. return list}{p_end}


{marker references}{...}
{title:References}

{marker CO2021}{...}
{phang}
Cai, Y. and Omay, T. (2021). Using double frequency in Fourier Dickey-Fuller
unit root test. {it:Computational Economics}, 59, 445-470.
{p_end}

{marker GM2026}{...}
{phang}
Gerolimetto, M. and Magrini, S. (2026). Bootstrap double frequency Dickey
Fuller test for unit roots. {it:Rivista Italiana di Economia Demografia e
Statistica}, LXXX(3), 332-342.
{p_end}

{phang}
Enders, W. and Lee, J. (2012b). The flexible Fourier form and Dickey-Fuller
type unit root tests. {it:Economics Letters}, 117(1), 196-199.
{p_end}

{phang}
Omay, T. (2015). Fractional frequency flexible Fourier form to approximate
smooth breaks in unit root testing. {it:Economics Letters}, 134, 123-126.
{p_end}


{title:Authors}

{pstd}
Dr. Merwan Roudane{break}
Email: merwanroudane920@gmail.com{p_end}



{title:Also see}

{psee}
{space 2}Help:  {helpb fourierlm}, {helpb fourierdf}, {helpb fouriergls},
{helpb fourierkpss}, {helpb fourierfffff}, {helpb fourierall}
{p_end}
