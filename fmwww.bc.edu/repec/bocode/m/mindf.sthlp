{smcl}
{* *! version 1.0.0 08jul2026 Ozan Eruygur}{...}
{title:Title}

{phang}
{bf:mindf} {hline 2} HLT unit root tests with up to three breaks in trend
(Harvey, Leybourne and Taylor, 2013)


{title:Syntax}

{p 8 17 2}
{cmd:mindf} {varname} {ifin}{cmd:,} {opt break:s(#)} [{opt kmax(#)}
{opt lags(#)}]

{pstd}
{varname} may contain time-series operators. The data must be {cmd:tsset} and
the sample must be contiguous (no gaps).


{title:Description}

{pstd}
{cmd:mindf} computes the minimum Dickey-Fuller unit root tests of Harvey,
Leybourne and Taylor (2013, Journal of Econometrics 177, 265-284), henceforth
HLT. The null hypothesis is that the series contains an autoregressive unit
root; the alternative is stationarity around a linear trend with up to m
breaks in slope, where m is set by {opt breaks()}. Breaks in trend are
permitted under both the null and the alternative hypothesis.

{pstd}
The data generating process is that of HLT, equations (2.1)-(2.2):{p_end}

{p 8 12 2}
y_t = mu + beta*t + gamma_1*DT_t(tau_1) + ... + gamma_m*DT_t(tau_m) + u_t{p_end}

{p 8 12 2}
u_t = rho*u_(t-1) + e_t{p_end}

{pstd}
where DT_t(tau) = t - floor(tau*T) if t > floor(tau*T) and 0 otherwise, so
that each gamma_i measures the change in the slope of the linear trend at
the unknown break date floor(tau_i*T). The null hypothesis is a unit root,
H0: rho = 1; under the alternative, rho < 1, the series is stationary
around the broken trend. Because the breaks sit in the deterministic
component while the hypotheses concern only rho, the breaks are present
under both hypotheses. The disturbance e_t may be serially correlated,
which the lag augmentation of the ADF regression accounts for.{p_end}

{pstd}
The test statistic MDFm is the infimum, taken across all candidate break dates
in a trimmed range subject to a minimum separation between breaks, of local
GLS detrended augmented Dickey-Fuller statistics. The deterministic component
contains a constant, a linear trend, and m broken trend regressors DT_t(Tb) =
max(t - Tb, 0). Candidate break dates run from floor(0.15*T) to
floor(0.85*T), with a minimum separation of floor(0.15*T) between breaks;
these fractions are fixed at the values used by HLT and hard-coded in the
original GAUSS program. GLS detrending uses the quasi-differencing parameter cbar
tabulated by HLT (Table 1): 17.6 for one break, 21.5 for two breaks, and 25.5
for three breaks. The ADF lag order is selected by the MAIC of Ng and Perron
(2001) computed on OLS-detrended residuals, following the modification of
Perron and Qu (2007), exactly as in the original HLT GAUSS code.

{pstd}
Two design features place {cmd:mindf} in a distinct family of unit root
tests with breaks. First, trend breaks are permitted under both the unit
root null and the trend-stationary alternative, so the test remains valid
when breaks occur in a unit root process. Second, detrending is by local
GLS rather than OLS, and the statistic is the infimum over the full grid of
candidate break dates; HLT show that as a result the power of the test is
approximately invariant to the presence and magnitude of the trend breaks,
without requiring a break pretest. Infimum tests based on OLS detrending in
which breaks enter only under the alternative hypothesis, such as Zivot and
Andrews (1992) and its multiple-break extension by Kapetanios (2005) with
sequentially dated breaks, form a different family.

{pstd}
{bf:Contribution of this package.} The Mata engine is a line-by-line port
of the original GAUSS program {cmd:mindf.gp} distributed by the Granger
Centre for Time Series Econometrics, University of Nottingham. The
distributed program covers one and two breaks only.
{bf:Our Stata package mindf extends the test to three breaks}, a case
defined and tabulated in
HLT but with no published code. The three-break extension was verified
against the original GAUSS procedures to at least 12 decimal places, and
its critical values were reproduced by simulation within Monte Carlo error.


{title:Options}

{phang}
{opt breaks(#)} is required and sets the maximum number of trend breaks m; it
must be 1, 2 or 3. HLT regard allowing for up to three breaks as sufficient
for the great majority of economic applications. Setting m above the true
number of breaks costs power through overfitting; setting it below leaves a
neglected break and the test loses power against the stationary alternative.

{phang}
{opt kmax(#)} sets the maximum lag order for the MAIC search; default floor(12*(T/100)^(1/4)).

{phang}
{opt lags(#)} fixes the ADF lag order at # and skips the MAIC search. This
permits replication of the k = 0 settings used in the size and power
simulations of HLT.


{title:Critical values}

{pstd}
Asymptotic critical values from HLT, Table 1 (trimming 0.15, separation 0.15):

        {c |}   cbar     10%      5%      1%
   -----+---------------------------------
   MDF1 {c |}   17.6   -3.57   -3.85   -4.40
   MDF2 {c |}   21.5   -4.30   -4.58   -5.10
   MDF3 {c |}   25.5   -4.81   -5.06   -5.58

{pstd}
The test rejects for large negative values of the statistic.

{pstd}
The embedded critical values were verified by an independent simulation of
the null distribution of the statistic; the simulated quantiles reproduce
HLT, Table 1 within Monte Carlo error.


{title:Examples: replication of HLT (2013), Table 4}

{pstd}
The dataset contains the logarithms of four Grilli and Yang (1988) primary
commodity price indices relative to the price of manufactures (MUV), annual,
1900-2003, T = 104, as updated by Pfaffenzeller, Newbold and Rayner (2007) and
extended by Geronimi, Anani and Taranco (Mendeley Data,
doi:10.17632/j24mjpcrrz.1, sheet Indexgy), from which the series were
constructed as y = ln(index/MUV).{p_end}

{phang2}{cmd:. use https://eruygurakademi.com/datasets/mindf/mindf_gy.dta, clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. mindf lcopper, breaks(1)}{p_end}
{phang2}{cmd:. mindf lcopper, breaks(2)}{p_end}
{phang2}{cmd:. mindf lhides, breaks(2)}{p_end}
{phang2}{cmd:. mindf llead, breaks(1)}{p_end}
{phang2}{cmd:. mindf lsilver, breaks(2)}{p_end}
{phang2}{cmd:. display %20.14f r(mdf)}{p_end}

{pstd}
Published values (HLT, Table 4; k selected by MAIC): Copper MDF1 = -3.15, MDF2
= -4.81; Hides MDF1 = -3.45, MDF2 = -6.34; Lead MDF1 = -4.62, MDF2 = -4.86;
Silver MDF1 = -2.04, MDF2 = -4.71. With {opt breaks(2)} the unit root null is
rejected at the 5 percent level for all four series.

{pstd}
Allowing up to three breaks; for lcopper this yields MDF3 = -4.940 with the
minimizing breaks in 1914, 1934 and 1969:{p_end}

{phang2}{cmd:. mindf lcopper, breaks(3)}{p_end}

{pstd}
Smaller maximum lag order for the MAIC search:{p_end}

{phang2}{cmd:. mindf lcopper, breaks(2) kmax(8)}{p_end}

{pstd}
Fixed lag order, skipping the MAIC search (here k = 0, as in the size and
power simulations of HLT):{p_end}

{phang2}{cmd:. mindf lcopper, breaks(2) lags(0)}{p_end}


{title:Replication with the original GAUSS code}

{pstd}
The original GAUSS program is available from the Granger Centre, University
of Nottingham, at
{browse "https://www.nottingham.ac.uk/research/groups/grangercentre/documents/code/mindf.zip"}
and is mirrored at
{browse "https://eruygurakademi.com/datasets/mindf/mindf.zip"}.

{pstd}
To reproduce the same numbers in GAUSS, create a folder named
{bf:gaussexample} on the C: drive (so its path is {cmd:C:\gaussexample}),
download {bf:mindf_web_gauss.zip} from the link below and extract the files
it contains ({cmd:mindf_gauss_check.gss}, {cmd:mindf_procs.src},
{cmd:mindf_gy.csv}) into that folder, then open
{cmd:mindf_gauss_check.gss} in GAUSS and run it (Run / F5).
{cmd:mindf_procs.src} contains the computational procedures of the original
{cmd:mindf.gp}, byte-identical:{p_end}

{phang2}{browse "https://eruygurakademi.com/datasets/mindf/mindf_web_gauss.zip"}{p_end}

{pstd}
The program computes MDF1, MDF2 and MDF3 for lcopper and prints the
statistics to 14 decimal places together with the minimizing break years.
The MDF1 and MDF2 computations follow the loops of the original
{cmd:mindf.gp}. Since the original program contains no three-break code,
the MDF3 block in {cmd:mindf_gauss_check.gss} is the three-break extension
of this package: it calls the same byte-identical original procedures and
only adds a search loop over a third break date. The corresponding Stata
commands are:{p_end}

{phang2}{cmd:. use https://eruygurakademi.com/datasets/mindf/mindf_gy.dta, clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. mindf lcopper, breaks(1)}{p_end}
{phang2}{cmd:. mindf lcopper, breaks(2)}{p_end}
{phang2}{cmd:. mindf lcopper, breaks(3)}{p_end}

{pstd}
Both produce the same results:{p_end}

{p 8 12 2}MDF1 = -3.15418344335429   (break: 1926){p_end}
{p 8 12 2}MDF2 = -4.81289788428944   (breaks: 1943, 1968){p_end}
{p 8 12 2}MDF3 = -4.94034329773017   (breaks: 1914, 1934, 1969){p_end}

{pstd}
{cmd:mindf} reproduces the GAUSS statistics for all Table 4 series to at
least 12 decimal places; the full-precision values are stored in
{cmd:r(mdf)} and can be displayed with {cmd:display %20.14f r(mdf)}.{p_end}


{title:Stored results}

{pstd}
{cmd:mindf} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 12 16 2: Scalars}{p_end}
{synopt:{cmd:r(mdf)}}MDFm test statistic{p_end}
{synopt:{cmd:r(breaks)}}number of trend breaks m{p_end}
{synopt:{cmd:r(cbar)}}GLS quasi-differencing parameter{p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(trim)}}trimming fraction{p_end}
{synopt:{cmd:r(sep)}}minimum separation fraction{p_end}
{synopt:{cmd:r(kmax)}}maximum lag order for MAIC{p_end}
{synopt:{cmd:r(k)}}lag order at the minimizing break dates{p_end}
{synopt:{cmd:r(obs}#{cmd:)}}observation index of break # minimizing the DF statistic{p_end}
{synopt:{cmd:r(tb}#{cmd:)}}time value of break # minimizing the DF statistic{p_end}

{p2col 5 12 16 2: Macros}{p_end}
{synopt:{cmd:r(varname)}}name of the tested series{p_end}
{synopt:{cmd:r(cmd)}}{cmd:mindf}{p_end}


{title:References}

{phang}
Geronimi, V., Anani, E., Taranco, A. 2018. Data for: Revisiting the
Prebisch-Singer hypothesis (1900-2016). Mendeley Data,
doi:10.17632/j24mjpcrrz.1.

{phang}
Grilli, E.R., Yang, M.C. 1988. Commodity prices, manufactured goods prices,
and the terms of trade of developing countries. World Bank Economic Review 2,
1-48.

{phang}
Harvey, D.I., Leybourne, S.J., Taylor, A.M.R. 2013. Testing for unit roots in
the possible presence of multiple trend breaks using minimum Dickey-Fuller
statistics. Journal of Econometrics 177, 265-284.

{phang}
Kapetanios, G. 2005. Unit-root testing against the alternative hypothesis of
up to m structural breaks. Journal of Time Series Analysis 26, 123-133.

{phang}
Ng, S., Perron, P. 2001. Lag length selection and the construction of unit
root tests with good size and power. Econometrica 69, 1519-1554.

{phang}
Perron, P., Qu, Z. 2007. A simple modification to improve the finite sample
properties of Ng and Perron's unit root tests. Economics Letters 94, 12-19.

{phang}
Pfaffenzeller, S., Newbold, P., Rayner, A. 2007. A short note on updating the
Grilli and Yang commodity price index. World Bank Economic Review 21, 151-163.

{phang}
Zivot, E., Andrews, D.W.K. 1992. Further evidence on the great crash, the
oil-price shock, and the unit-root hypothesis. Journal of Business and
Economic Statistics 10, 251-270.


{title:Author}

{pstd}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com"}{break}
eruygur@gmail.com

{pstd}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara,
Turkiye.{break}
{browse "https://www.eruygurakademi.com"}{break}
eruygurakademi@gmail.com

{pstd}
{bf:mindf} v1.0.0 {c -} July 2026

{pstd}
The test implemented here was proposed by David I. Harvey, Stephen J.
Leybourne (University of Nottingham) and A.M. Robert Taylor (University of
Essex) in Harvey, Leybourne and Taylor (2013). {bf:mindf} is a Stata/Mata
port of the original GAUSS code {cmd:mindf.gp} distributed by the Granger
Centre for Time Series Econometrics, University of Nottingham; the
three-break case is an extension by this package.

{pstd}
{bf:Please cite as:}

{pstd}
Eruygur, H. O. 2026. {bf:mindf}: Harvey, Leybourne and Taylor (2013) unit
root tests allowing for up to three breaks in trend. Stata package version
1.0.0. Available from: {browse "https://www.eruygurakademi.com"}.


{title:Also see}

{pstd}
{helpb kapetanios}, {helpb leestra}, {helpb narayanp}, {helpb ckptest},
{helpb kpssbr} (if installed)
