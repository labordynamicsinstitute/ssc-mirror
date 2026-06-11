{smcl}
{* *! version 1.0.0  06jun2026}{...}
{vieweralsosee "xtpdlib" "help xtpdlib"}{...}
{vieweralsosee "xtcipsm" "help xtcipsm"}{...}
{vieweralsosee "xtpgc" "help xtpgc"}{...}
{viewerjumpto "Syntax" "xtfpss##syntax"}{...}
{viewerjumpto "Description" "xtfpss##description"}{...}
{viewerjumpto "Options" "xtfpss##options"}{...}
{viewerjumpto "Method" "xtfpss##method"}{...}
{viewerjumpto "Interpretation" "xtfpss##interp"}{...}
{viewerjumpto "Cautions" "xtfpss##cautions"}{...}
{viewerjumpto "Examples" "xtfpss##examples"}{...}
{viewerjumpto "Stored results" "xtfpss##results"}{...}
{viewerjumpto "References" "xtfpss##references"}{...}
{viewerjumpto "Author" "xtfpss##author"}{...}
{title:Title}

{phang}
{bf:xtfpss} {hline 2} Fourier panel stationarity test with gradual structural shifts
(Nazlioglu & Karul, 2017)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtfpss} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(level|trend)}}deterministic component: {cmd:level} (level shift,
default) or {cmd:trend} (level and trend shift){p_end}
{synopt:{opt f:req(#)}}Fourier frequency {it:k}, an integer in 1..5; default {cmd:freq(1)}{p_end}
{synopt:{opt opt:freq}}select {it:k} automatically by minimum panel SSR over 1..{it:fmax}{p_end}
{synopt:{opt fm:ax(#)}}maximum frequency searched when {cmd:optfreq} is used (1..5); default {cmd:fmax(5)}{p_end}
{synopt:{opt var:m(#)}}long-run variance estimator, an integer in 1..7; default {cmd:varm(1)} (iid){p_end}

{syntab:Reporting & graph}
{synopt:{opt gr:aph}}draw the series with its Fourier approximation (small multiples, Fig. 1 style){p_end}
{synopt:{opt gen:fourier(newvar)}}save the fitted Fourier approximation to {it:newvar}{p_end}
{synopt:{opt nopr:intind}}suppress the table of individual KPSS statistics{p_end}
{synopt:{it:twoway_options}}any {help twoway_options} passed to the graph{p_end}
{synoptline}

{phang}The data must be {helpb xtset} (panel id and time) and the panel must be
{bf:balanced} (every unit observed for the same {it:T} periods).{p_end}
{phang}{cmd:xtfpss} is part of the {helpb xtpdlib} library.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfpss} implements the {it:Fourier panel stationarity test} of
{help xtfpss##NK2017:Nazlioglu and Karul (2017)}. The test allows for an unknown
number, date and form of {it:smooth/gradual} structural shifts that are modelled with
a {help xtfpss##B2006:Becker, Enders and Lee (2006)} Fourier approximation, while
cross-section dependence is captured by a common factor proxied by the cross-sectional
average ({help xtfpss##HK2011:Hadri and Kurozumi, 2011, 2012}).

{pstd}
The null hypothesis is that the panel is {bf:stationary} (all units stationary) against
the alternative that some or all units contain a unit root. The standardized panel
statistic {bf:FZk} has a standard {bf:N(0,1)} limiting distribution; the one-sided 5%
critical value is 1.645 and {cmd:xtfpss} reports the right-tail p-value.

{pstd}
This command is a Stata translation of the GAUSS routine {bf:PD_nkarul} (proc {bf:PDfzk})
from S. Nazlioglu's {bf:TSPDLIB} and is designed to reproduce its results.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}{opt model(level|trend)} sets the deterministic specification. {cmd:level}
(default) includes a constant plus the Fourier terms (level shifts). {cmd:trend} adds a
linear trend (level and trend shifts).

{phang}{opt freq(#)} sets the single Fourier frequency {it:k} (1..5). Because the
asymptotic moments are tabulated for {it:k} = 1..5 only, {it:k} is restricted to that
range. The homogeneous frequency assumption is used across units (see {help xtfpss##method:Method}).

{phang}{opt optfreq} selects {it:k} as the value in 1..{it:fmax} that minimises the
total panel sum of squared residuals. Without this option the fixed {cmd:freq()} is used.

{phang}{opt fmax(#)} is the largest frequency searched under {cmd:optfreq} (default 5).

{phang}{opt varm(#)} chooses the long-run variance estimator used in the individual KPSS
statistics:{p_end}
{p2colset 12 20 22 2}{...}
{p2col:1}iid (default){p_end}
{p2col:2}Bartlett kernel{p_end}
{p2col:3}Quadratic Spectral kernel{p_end}
{p2col:4}SPC prewhitened Bartlett ({help xtfpss##SPC2005:Sul, Phillips & Choi, 2005}){p_end}
{p2col:5}SPC prewhitened Quadratic Spectral{p_end}
{p2col:6}Kurozumi (2002) data-dependent bandwidth, Bartlett{p_end}
{p2col:7}Kurozumi (2002) data-dependent bandwidth, Quadratic Spectral{p_end}

{dlgtab:Reporting & graph}

{phang}{opt graph} produces a small-multiples graph (one panel per unit) overlaying the
original series (blue) and its estimated Fourier approximation (red), reproducing Fig. 1
of Nazlioglu and Karul (2017).

{phang}{opt genfourier(newvar)} saves the fitted Fourier deterministic component, so you
can build your own graphs.

{phang}{opt noprintind} suppresses the per-unit KPSS table and prints only the panel result.


{marker method}{...}
{title:Method}

{pstd}
For each unit {it:i} the individual KPSS statistic with a common factor and Fourier terms is

{p 12 12 2}{cmd:eta_i(k) = (1/T^2) * sum_t S_it(k)^2 / sigma2_i}

{pstd}
where {cmd:S_it(k)} is the partial sum of the OLS residuals from regressing y on a
constant (and trend, for {cmd:model(trend)}), {cmd:sin(2*pi*k*t/T)}, {cmd:cos(2*pi*k*t/T)},
and the cross-sectional average {cmd:Ft}; {cmd:sigma2_i} is the long-run variance
(option {cmd:varm()}). The panel statistic is the average {cmd:FP(k) = mean_i eta_i(k)}
and is standardized to

{p 12 12 2}{cmd:FZk = sqrt(N) * (FP(k) - mu(k)) / sqrt(zeta2(k)) ~ N(0,1)}

{pstd}
using the asymptotic mean {cmd:mu(k)} and variance {cmd:zeta2(k)} from Table 1 of the
paper (which depend on the deterministic model and {it:k}). A homogeneous frequency {it:k}
is assumed across units so that the panel statistic has the standard normal distribution.


{marker interp}{...}
{title:Interpretation}

{pstd}
{bf:Reading the panel result.} {cmd:FZk} is standard normal under the null of joint
stationarity. Because rejection occurs in the {it:right} tail, compare {cmd:FZk} with
the one-sided critical values 1.282 (10%), 1.645 (5%) and 2.326 (1%); the reported
p-value is 1 - Phi(FZk).{break}
 - {bf:p-value < 0.05}: reject joint stationarity {space 2}=>{space 2}at least a fraction
   of the panel units contain a {bf:unit root} (shocks are persistent/permanent).{break}
 - {bf:p-value >= 0.05}: do not reject {space 2}=>{space 2}the panel is {bf:stationary}
   around a (smooth, Fourier) deterministic component (shocks are transitory).

{pstd}
{bf:Reading the individual statistics.} The per-unit {cmd:FKPSS} values describe each
cross-section. Large values flag units that look non-stationary; small values look
stationary. Under the alternative the panel test rejects when a non-trivial fraction of
units are non-stationary, so the individual column is useful for seeing {it:which} units
drive (or do not drive) the panel conclusion. There is no per-unit p-value here because
the limiting distribution of {cmd:FKPSS} depends only on the Fourier frequency {it:k};
use the simulated time-series critical values of Becker, Enders and Lee (2006) for unit
inference if needed.

{pstd}
{bf:Reading the graph.} The blue line is the observed series and the red line is its
estimated Fourier deterministic component. A red curve that tracks the long swings of the
series indicates that gradual/smooth shifts (not sharp breaks) characterise the data;
this is exactly the situation in which the Fourier stationarity test outperforms
dummy-variable break tests.


{marker cautions}{...}
{title:Cautions}

{phang}o {bf:Balanced panel only.} The data must be {helpb xtset} and every unit must be
observed for the same {it:T} periods; otherwise the command stops with an error.{p_end}

{phang}o {bf:Frequency is restricted to 1..5.} The asymptotic moments (Table 1 of the
paper) are tabulated only for {it:k}=1..5. A {it:single, common} frequency is assumed
across units so that the panel statistic is N(0,1); do not interpret the test as allowing
unit-specific {it:k}.{p_end}

{phang}o {bf:Choosing k matters.} Using the wrong number of Fourier terms distorts size
and power (paper, Cases 3-5). Prefer {opt freq(1)} unless there is clear evidence of
multiple long swings; {opt optfreq} chooses {it:k} by minimum panel SSR but is only a
guide. Low integer frequencies (1 or 2) are recommended; high {it:k} approaches a
dummy-break specification and loses the smooth-shift advantage.{p_end}

{phang}o {bf:Serial correlation.} With i.i.d. errors the default {opt varm(1)} (iid) is
fine. With serially correlated errors use a kernel estimator; {opt varm(6)} or
{opt varm(7)} (Kurozumi 2002 data-dependent bandwidth) controls size distortion best in
small samples. The {opt varm(4)}/{opt varm(5)} SPC options apply a prewhitening boundary
rule.{p_end}

{phang}o {bf:Small T.} Size is close to nominal once T is moderate; with very small T the
test is somewhat undersized (conservative). Power rises with both N and T.{p_end}

{phang}o {bf:Not the same null as unit-root tests.} Here H0 = stationarity. Failing to
reject is {it:evidence for} stationarity, the opposite logic of {helpb xtcipsm} /
{helpb xtunitroot} where H0 = unit root. Using both (confirmatory analysis) is good
practice.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Baseline level-shift test at frequency 1 (recommended default){p_end}
{phang2}{cmd:. xtfpss invest, model(level) freq(1)}{p_end}

{pstd}Trend (level + trend shift) model at frequency 2{p_end}
{phang2}{cmd:. xtfpss invest, model(trend) freq(2)}{p_end}

{pstd}Let the data choose k in 1..3, Bartlett long-run variance{p_end}
{phang2}{cmd:. xtfpss invest, optfreq fmax(3) varm(2)}{p_end}

{pstd}Serially-correlated errors: Kurozumi data-dependent bandwidth{p_end}
{phang2}{cmd:. xtfpss invest, model(level) freq(1) varm(6)}{p_end}

{pstd}Fig. 1-style graph and keep the fitted Fourier component{p_end}
{phang2}{cmd:. xtfpss invest, model(trend) freq(1) graph genfourier(fhat)}{p_end}

{pstd}Use the stored results{p_end}
{phang2}{cmd:. xtfpss invest, model(level) freq(1)}{p_end}
{phang2}{cmd:. display "FZk = " r(fzk) "  p = " r(pval)}{p_end}
{phang2}{cmd:. matrix list r(kpss)}{p_end}

{pstd}Compare with a unit-root null test on the same data (confirmatory analysis){p_end}
{phang2}{cmd:. xtcipsm invest, model(constant)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtfpss} stores the following in {cmd:r()}:{p_end}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(fzk)}}panel FZk statistic{p_end}
{synopt:{cmd:r(pval)}}right-tail p-value of FZk{p_end}
{synopt:{cmd:r(fpk)}}panel statistic FP(k) (average of individual KPSS){p_end}
{synopt:{cmd:r(k)}}Fourier frequency used{p_end}
{synopt:{cmd:r(N)}}number of cross-sections{p_end}
{synopt:{cmd:r(T)}}time-series length{p_end}
{synopt:{cmd:r(varm)}}long-run variance method code{p_end}
{synopt:{cmd:r(model)}}deterministic model (1=level, 2=trend){p_end}

{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(kpss)}}{it:N} x 2 matrix of unit id and individual FKPSS statistic{p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(lrv)}}long-run variance method label{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtfpss}{p_end}


{marker references}{...}
{title:References}

{marker NK2017}{...}
{phang}Nazlioglu, S., and C. Karul. 2017. A panel stationarity test with gradual
structural shifts: re-investigate the international commodity price shocks.
{it:Economic Modelling} 61: 181-192.{p_end}

{marker B2006}{...}
{phang}Becker, R., W. Enders, and J. Lee. 2006. A stationarity test in the presence of an
unknown number of smooth breaks. {it:Journal of Time Series Analysis} 27: 381-409.{p_end}

{marker HK2011}{...}
{phang}Hadri, K., and E. Kurozumi. 2011. A simple panel stationarity test in the presence
of cross-sectional dependence. {it:Economics Letters} 115: 31-34.{p_end}

{marker SPC2005}{...}
{phang}Sul, D., P. C. B. Phillips, and C.-Y. Choi. 2005. Prewhitening bias in HAC
estimation. {it:Oxford Bulletin of Economics and Statistics} 67: 517-546.{p_end}

{phang}Kurozumi, E. 2002. Testing for stationarity with a break.
{it:Journal of Econometrics} 108: 63-99.{p_end}


{marker author}{...}
{title:Author}

{pstd}Stata implementation:{p_end}
{pmore}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Original GAUSS code (TSPDLIB, proc PDfzk):{p_end}
{pmore}Saban Nazlioglu, Pamukkale University, snazlioglu@pau.edu.tr{p_end}

{pstd}See also:{p_end}
{pmore}{helpb xtpdlib}, {helpb xtcipsm}, {helpb xtpgc}, {helpb xtunitroot}{p_end}
