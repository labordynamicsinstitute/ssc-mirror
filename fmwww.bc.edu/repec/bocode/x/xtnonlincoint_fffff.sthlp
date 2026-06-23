{smcl}
{* *! version 1.0.0  21jun2026}{...}
{vieweralsosee "xtnonlincoint" "help xtnonlincoint"}{...}
{vieweralsosee "xtnonlincoint ecm" "help xtnonlincoint_ecm"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtnonlincoint_fffff##syntax"}{...}
{viewerjumpto "Description" "xtnonlincoint_fffff##description"}{...}
{viewerjumpto "Options" "xtnonlincoint_fffff##options"}{...}
{viewerjumpto "Method" "xtnonlincoint_fffff##method"}{...}
{viewerjumpto "Examples" "xtnonlincoint_fffff##examples"}{...}
{viewerjumpto "Stored results" "xtnonlincoint_fffff##results"}{...}
{viewerjumpto "References" "xtnonlincoint_fffff##references"}{...}
{viewerjumpto "Author" "xtnonlincoint_fffff##author"}{...}
{title:Title}

{phang}
{bf:xtnonlincoint fffff} {hline 2} Fractional frequency flexible Fourier form
(FFFFF) panel cointegration test (Olayeni, Tiwari & Wohar 2021)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtnonlincoint fffff} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt maxl:ags(#)}}maximum lag in the KSS-Fourier ADF regression; the lag
is chosen by AIC up to this value; default {cmd:maxlags(1)}{p_end}
{synopt:{opt ks:tep(#)}}step of the fractional-frequency grid searched on
[0.1, 2]; default {cmd:kstep(0.1)}{p_end}
{synopt:{opt tr:end}}include a linear trend in the cointegrating regression;
default is constant only{p_end}

{syntab:Bootstrap}
{synopt:{opt b:reps(#)}}stationary-bootstrap replications; default {cmd:breps(299)}{p_end}
{synopt:{opt bl:ock(#)}}mean block length of the stationary bootstrap; default
0 = round(sqrt(T)){p_end}
{synopt:{opt s:eed(#)}}random-number seed; default {cmd:seed(12345)}{p_end}

{syntab:Reporting}
{synopt:{opt spsm}}report the Sequential Panel Selection Method table{p_end}
{synopt:{opt l:evel(#)}}confidence level for reporting; default {cmd:level(95)}{p_end}
{synopt:{opt gr:aph}}draw the individual-statistics bar chart and the SPSM
sequence plot{p_end}
{synopt:{opt nopr:int}}suppress the results table{p_end}
{synoptline}

{pstd}The panel must be {helpb xtset} and balanced.

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtnonlincoint fffff} implements a panel cointegration test that is robust to
(i) nonlinearity, (ii) an unknown number and form of smooth structural breaks
and (iii) cross-sectional dependence. For each panel the cointegrating residual
nu(it) from the levels regression of {depvar} on {indepvars} is tested for a
unit root with the Kapetanios-Shin-Snell (KSS) nonlinear ADF regression
augmented with a flexible Fourier term:

{p 8 8 2}
D.nu(it) = a(i) + g(i)*nu(i,t-1)^3 + sum_j h(ij)*D.nu(i,t-j)
+ chi(i)*sin(2*pi*k*t/T) + phi(i)*cos(2*pi*k*t/T) + e(it).

{pstd}
The frequency {it:k} is treated as a {it:fractional} quantity and searched
jointly with the lag length on a grid; the fractional form nests the integer
case and protects the small-sample properties (Omay 2015). The individual KSS
statistic is the {it:t}-ratio on g(i). A stationary bootstrap applied jointly to
all panels delivers cross-section-dependence-robust {it:p}-values, and the
Sequential Panel Selection Method (SPSM) removes the most stationary series one
at a time to reveal which cross-sections generate the panel cointegration.

{marker options}{...}
{title:Options}

{phang}
{opt maxlags(#)} caps the augmentation lag; the AIC selects the lag (and, for
the FFFFF, the frequency) jointly.

{phang}
{opt kstep(#)} controls the resolution of the fractional-frequency grid on
[0.1, 2]. A finer grid is more faithful to the continuous search but slower.

{phang}
{opt trend} adds a linear trend to the first-stage cointegrating regression.

{phang}
{opt block(#)} sets the mean block length of the Politis-Romano stationary
bootstrap; 0 uses round(sqrt(T)). Longer blocks preserve more serial dependence.

{phang}
{opt spsm} prints the SPSM table: at each step the group statistic, its
bootstrap {it:p}-value, and the series (most stationary, lowest KSS) removed.

{phang}
{opt graph} produces a two-panel figure: the individual KSS statistics with
their 5% critical value, and the group statistic across SPSM steps.

{marker method}{...}
{title:Method}

{pstd}
Under the null of no cointegration the residual nu(it) is I(1). The bootstrap
imposes this by resampling the differenced residuals D.nu with a common
(cross-panel) stationary-bootstrap index, cumulating them into a pseudo random
walk, re-projecting it on the original regressors (so the pseudo-residual
carries the same spurious mean reversion as the observed residual), and then
{it:re-running the joint frequency/lag selection} on every replication. Letting
the bootstrap repeat the whole statistic - including the search over {it:k} - is
what keeps the test correctly sized; holding {it:k} fixed in the bootstrap would
ignore the selection advantage of the observed statistic and over-reject. The
group {it:p}-value is the share of bootstrap group means at or below the
observed group mean. SPSM compares the group mean of the {it:current} active set
to its bootstrap distribution at every step.

{pstd}
{it:Finite-sample behaviour.} Because the frequency search is fully
bootstrapped, the test is mildly {bf:conservative} in small panels (empirical
size below the nominal level) while retaining good power against genuine
cointegration. This errs on the safe side: it does not spuriously declare
cointegration. Size approaches the nominal level as T grows. The companion
{helpb xtnonlincoint_ecm:ecm} test is an alternative that is close to nominal
size in small samples.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtnonlincoint fffff invest mvalue kstock}{p_end}
{phang2}{cmd:. xtnonlincoint fffff invest mvalue kstock, maxlags(2) spsm graph}{p_end}
{phang2}{cmd:. matrix list r(spsm)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtnonlincoint fffff} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}group-mean KSS statistic{p_end}
{synopt:{cmd:r(p)}}bootstrap {it:p}-value{p_end}
{synopt:{cmd:r(cv10)}, {cmd:r(cv5)}, {cmd:r(cv1)}}group critical values{p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}number of periods{p_end}
{synopt:{cmd:r(nstat)}}number of panels with a computable statistic{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}long-run regressors{p_end}
{synopt:{cmd:r(test)}}test label{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(indstat)}}per-panel: id, KSS, k, lag, {it:p}-value, cv10, cv5, cv1{p_end}
{synopt:{cmd:r(spsm)}}SPSM path: step, group KSS, {it:p}-value, min KSS, k, id{p_end}
{synopt:{cmd:r(bootdist)}}bootstrap null distribution of the group statistic{p_end}

{marker references}{...}
{title:References}

{phang}
Kapetanios, G., Y. Shin, and A. Snell. 2003. Testing for a unit root in the
nonlinear STAR framework. {it:Journal of Econometrics} 112: 359-379.

{phang}
Omay, T. 2015. Fractional frequency flexible Fourier form to approximate smooth
breaks in unit root testing. {it:Economics Letters} 134: 123-126.

{phang}
Olayeni, R. O., A. K. Tiwari, and M. E. Wohar. 2021. Fractional frequency
flexible Fourier form (FFFFF) for panel cointegration test. {it:Applied
Economics Letters} 28(6): 482-486.
{browse "https://doi.org/10.1080/13504851.2020.1761526":doi:10.1080/13504851.2020.1761526}.

{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
