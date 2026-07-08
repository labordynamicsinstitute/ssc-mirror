{smcl}
{* *! version 2.0.0  07jul2026  Merwan Roudane}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{vieweralsosee "[TS] dfgls" "help dfgls"}{...}
{viewerjumpto "Syntax" "boundedur##syntax"}{...}
{viewerjumpto "Description" "boundedur##description"}{...}
{viewerjumpto "Options" "boundedur##options"}{...}
{viewerjumpto "Method" "boundedur##method"}{...}
{viewerjumpto "Stored results" "boundedur##results"}{...}
{viewerjumpto "Examples" "boundedur##examples"}{...}
{viewerjumpto "Roadmap" "boundedur##roadmap"}{...}
{viewerjumpto "References" "boundedur##references"}{...}
{viewerjumpto "Author" "boundedur##author"}{...}
{title:Title}

{phang}
{bf:boundedur} {hline 2} Unit-root tests for bounded time series (a library)

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:boundedur} [{it:subcommand}] {varname} {ifin}{cmd:,}
{cmdab:lb:ound(}{it:#}{cmd:)}
[{cmdab:ub:ound(}{it:#}{cmd:)} {it:options}]

{p 8 8 2}
The {it:subcommand} selects the method. If omitted, {cmd:cx} (Cavaliere & Xu 2014) is used,
so that {cmd:boundedur} {it:y}{cmd:, lbound(0)} and {cmd:boundedur cx} {it:y}{cmd:, lbound(0)}
are equivalent.

{synoptset 26 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt cx}}Cavaliere & Xu (2014) simulation-based ADF and M tests {it:(default)}{p_end}
{synopt:{opt mtests}}Carrion-i-Silvestre & Gadea (2013) GLS M-tests {it:(roadmap)}{p_end}
{synopt:{opt breaks}}Carrion-i-Silvestre & Gadea (2016) bounds + breaks {it:(roadmap)}{p_end}
{synopt:{opt hlt}}Carrion-i-Silvestre & Gadea (2024) HLT level shifts {it:(roadmap)}{p_end}
{synoptline}

{pstd}
The series must be {helpb tsset}. {cmd:boundedur} operates on a single time series (no panels).

{synoptset 26 tabbed}{...}
{synopthdr:options for {cmd:cx}}
{synoptline}
{syntab:Bounds (required: at least one)}
{synopt:{opt lb:ound(#)}}lower bound {it:b} of the series; use {cmd:.} for none (one-sided){p_end}
{synopt:{opt ub:ound(#)}}upper bound {it:b-bar}; omit or {cmd:.} for a one-sided lower bound{p_end}

{syntab:Test and detrending}
{synopt:{opt t:est(name)}}which test(s) to report: {opt adfalpha} {opt adft} {opt mzalpha} {opt mzt} {opt msb} {opt all}; default {cmd:all}{p_end}
{synopt:{opt det:rend(method)}}{opt constant} (OLS de-mean, default), {opt gls} (pseudo-GLS de-mean), or {opt none}{p_end}
{synopt:{opt glsc(#)}}pseudo-GLS c-bar for {cmd:detrend(gls)}; default {cmd:-7}{p_end}

{syntab:Lag length (spectral AR long-run variance)}
{synopt:{opt l:ags(#)}}fix the number of ADF augmenting lags; default = MAIC-selected{p_end}
{synopt:{opt maxl:ag(#)}}maximum lag for MAIC; default {cmd:floor(12*(T/100)^.25)}{p_end}

{syntab:Simulation (Algorithm 1)}
{synopt:{opt n:sim(#)}}number of Monte Carlo replications B; default {cmd:499}{p_end}
{synopt:{opt nstep(#)}}discretization steps n (must be {cmd:>=} T); default {cmd:n = T}{p_end}
{synopt:{opt rec:olor}}add the re-colouring (sieve) device of Section 4.3{p_end}
{synopt:{opt krc:lag(#)}}lag order for the re-colouring filter; default = ADF lag{p_end}
{synopt:{opt seed(#)}}set the random-number seed for reproducibility{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level for the reported critical value; default {cmd:c(level)}{p_end}
{synopt:{opt savesim(name)}}save the simulated null draws in {it:name}1/{it:name}2/{it:name}3{p_end}
{synopt:{opt nograph}}suppress the diagnostic figure{p_end}
{synopt:{opt gname(string)}}stub name for the produced graphs; default {cmd:boundedur}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:boundedur} implements unit-root tests that remain valid when the series is {it:bounded}
{hline 1} either by construction or by policy {hline 1} such as unemployment rates, budget
shares, nominal interest rates, capacity-utilisation rates or target-zone exchange rates. In the
presence of bounds, conventional unit-root tests ({helpb dfuller}, {helpb dfgls}) over-reject the
unit-root null, even asymptotically, because the limiting distribution is a {it:regulated}
(reflected) Brownian motion rather than a standard one.

{pstd}
The default subcommand {cmd:cx} implements the simulation-based augmented Dickey-Fuller
(ADF{c 42}) and modified {c 34}M{c 34} tests (MZ{c 42}{sub:{&alpha}}, MZ{c 42}{sub:t}, MSB{c 42})
of {browse "https://doi.org/10.1016/j.jeconom.2013.08.026":Cavaliere and Xu (2014)}. The bounds
enter through two consistent nuisance-parameter estimates

{p 12 12 2}{cmd:c-hat} = ({it:b} {c 45} X0) / (s{sub:AR} {c 42} sqrt(T)),{space 6}{cmd:c-bar-hat} = ({it:b-bar} {c 45} X0) / (s{sub:AR} {c 42} sqrt(T)),{p_end}

{pstd}
where {cmd:X0} is the {it:first observation} of the series (estimated under the null, as in
Schmidt-Phillips) and s{sub:AR}{c 94}2 is the spectral autoregressive estimate of the long-run
variance from the ADF regression. Monte Carlo p-values are then obtained by simulating the
regulated Brownian motion via Algorithm 1 and evaluating the relevant continuous functionals; see
{help boundedur##method:Method}. Both one-sided and two-sided bounds are supported.

{marker options}{...}
{title:Options}

{dlgtab:Bounds}

{phang}
{opt lbound(#)} specifies the lower bound {it:b}. It is required unless {opt ubound()} is given.
Use {cmd:lbound(.)} together with {opt ubound()} to test a series that is bounded above only.

{phang}
{opt ubound(#)} specifies the upper bound {it:b-bar}. Omit it (or set {cmd:ubound(.)}) for a
series bounded below only. At least one finite bound must be supplied.

{dlgtab:Test and detrending}

{phang}
{opt test(name)} selects which statistics to display. {cmd:adfalpha}/{cmd:mzalpha} reject for
large negative values; {cmd:adft}/{cmd:mzt} likewise; {cmd:msb} rejects for {it:small} values.
Asymptotically ADF{c 42}{sub:{&alpha}} and MZ{c 42}{sub:{&alpha}} share one limiting law and
ADF{c 42}{sub:t} and MZ{c 42}{sub:t} share another, so their p-values are read from the same
simulated null.

{phang}
{opt detrend(method)} chooses the deterministic treatment of the data. {cmd:constant} removes an
OLS mean (the case tabulated in the paper); {cmd:gls} uses pseudo-GLS (ERS) de-meaning
(Remark 3.3); {cmd:none} leaves the raw series.

{phang}
{opt glsc(#)} is the pseudo-GLS noncentrality {c 45}{it:c-bar} used when {cmd:detrend(gls)}; the
Elliott-Rothenberg-Stock value for a constant is {cmd:-7} (the default).

{dlgtab:Lag length}

{phang}
{opt lags(#)} fixes the number of augmenting lags in the ADF regression (3.7). By default the
Ng-Perron modified AIC (MAIC) selects it over {cmd:0..maxlag}.

{phang}
{opt maxlag(#)} sets the MAIC search ceiling; the default follows Ng-Perron,
{cmd:floor(12*(T/100)^0.25)}.

{dlgtab:Simulation}

{phang}
{opt nsim(#)} is the number B of Monte Carlo replications used to compute the p-values
(Remark 4.3). The paper uses {cmd:B = 499}. The Monte Carlo standard error of a p-value is
{cmd:sqrt(p(1-p)/B)}.

{phang}
{opt nstep(#)} is the discretization step n of the regulated Brownian motion. Any {cmd:n >= T} is
admissible; the paper recommends {cmd:n = T} for the best finite-sample size (the default). Values
below T are reset to T.

{phang}
{opt recolor} activates the re-colouring device (eq. 4.13-4.14): the Monte Carlo innovations are
filtered through the estimated stationary AR dynamics before the bounds are applied, which sharply
improves finite-sample size under serially correlated errors.

{phang}
{opt krclag(#)} is the AR order of that re-colouring filter; it need not equal the ADF lag and
defaults to it.

{phang}
{opt seed(#)} seeds Stata's RNG so results are exactly reproducible.

{dlgtab:Reporting}

{phang}
{opt level(#)} sets the confidence level; the reported critical-value column is the corresponding
significance-level quantile (e.g. {cmd:level(95)} {c 8594} 5% critical value).

{phang}
{opt savesim(name)} stores the simulated null draws (columns 1=ADF/MZ-alpha, 2=ADF/MZ-t, 3=MSB)
as new variables {it:name}1 {it:name}2 {it:name}3, for custom plots.

{phang}
{opt nograph} suppresses the two-panel diagnostic figure; {opt gname()} sets its name stub.

{marker method}{...}
{title:Method}

{pstd}
{ul:Observed statistics.} On the de-trended series X-hat, the ADF regression (3.7)

{p 12 12 2}{&Delta}X-hat{sub:t} = {&pi} X-hat{sub:t-1} + {&Sigma}{sub:i} {&alpha}{sub:i} {&Delta}X-hat{sub:t-i} + e{sub:t,k}{p_end}

{pstd}
yields ADF{sub:{&alpha}} = T{c 42}{&pi}-hat/{&alpha}-hat(1), ADF{sub:t} = {&pi}-hat/se({&pi}-hat),
with {&alpha}-hat(1) = 1 {c 45} {&Sigma}{&alpha}-hat{sub:i}, and the M statistics of Perron-Ng /
Ng-Perron (2001) using s{sub:AR}{c 94}2 = {&sigma}-hat{c 94}2/{&alpha}-hat(1){c 94}2.

{pstd}
{ul:Simulated null (Algorithm 1).} For a discretization step n, let {&epsilon}{sub:t} be i.i.d.
N(0,1) and build, with X{sub:0}=0,

{p 12 12 2}X{sub:t} = c-bar-hat if X{sub:t-1}+n{c 94}(-1/2){&epsilon}{sub:t} > c-bar-hat;{space 3}= c-hat if < c-hat;{space 3}otherwise X{sub:t-1}+n{c 94}(-1/2){&epsilon}{sub:t},{p_end}

{pstd}
(the {it:clipping} construction of the paper). The de-meaned path X-tilde delivers the Monte Carlo
functionals {&lambda}{sub:{&alpha}} = [X-tilde(1){c 94}2 {c 45} X-tilde(0){c 94}2 {c 45} 1] /
(2{&int}X-tilde{c 94}2), {&lambda}{sub:MSB} = ({&int}X-tilde{c 94}2){c 94}(1/2),
{&lambda}{sub:t} = {&lambda}{sub:{&alpha}}{&lambda}{sub:MSB}. Repeating B times gives the
conditional null; the p-value is the fraction of simulated statistics at least as extreme as the
observed one (Theorem 2). With {opt recolor}, {&epsilon}{sub:t} is replaced by the AR-filtered
u{sub:t,krc} of eq. (4.14).

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:boundedur cx} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations T{p_end}
{synopt:{cmd:r(lags)}}ADF augmenting lags used{p_end}
{synopt:{cmd:r(s2ar)}}spectral AR long-run variance s{sub:AR}{c 94}2{p_end}
{synopt:{cmd:r(x0)}}first observation X0 (used in c-hat){p_end}
{synopt:{cmd:r(c_lower)}}{cmd:c-hat} lower bound parameter{p_end}
{synopt:{cmd:r(c_upper)}}{cmd:c-bar-hat} upper bound parameter{p_end}
{synopt:{cmd:r(lbound)} {cmd:r(ubound)}}the bounds ({cmd:.} = one-sided){p_end}
{synopt:{cmd:r(adf_alpha)} {cmd:r(adf_t)}}ADF{c 42} statistics{p_end}
{synopt:{cmd:r(mz_alpha)} {cmd:r(mz_t)} {cmd:r(msb)}}M{c 42} statistics{p_end}
{synopt:{cmd:r(p_adf_alpha)} ... {cmd:r(p_msb)}}Monte Carlo p-values{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:boundedur}{p_end}
{synopt:{cmd:r(depvar)}}the tested series{p_end}
{synopt:{cmd:r(detrend)}}detrending method{p_end}
{synopt:{cmd:r(timevar)}}the time variable{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}5{c 215}3 matrix: statistic, p-value, critical value{p_end}

{marker examples}{...}
{title:Examples}

{pstd}An unemployment rate bounded in [0,100]:{p_end}
{phang2}{cmd:. tsset time}{p_end}
{phang2}{cmd:. boundedur urate, lbound(0) ubound(100)}{p_end}

{pstd}A nominal interest rate, bounded below by zero only (one-sided):{p_end}
{phang2}{cmd:. boundedur irate, lbound(0)}{p_end}

{pstd}Report just the MSB test, GLS de-meaning, re-colouring, reproducible:{p_end}
{phang2}{cmd:. boundedur cx y, lbound(0) ubound(1) test(msb) detrend(gls) recolor seed(123)}{p_end}

{pstd}Fix the lag and increase the simulation accuracy, and keep the draws:{p_end}
{phang2}{cmd:. boundedur y, lbound(0) ubound(100) lags(4) nsim(1999) savesim(nulldraw)}{p_end}

{marker roadmap}{...}
{title:Roadmap (library modules under construction)}

{pstd}
{cmd:boundedur} is designed as a library. The base {cmd:cx} command is complete; the following
companion modules are being added and currently return an informative message:

{phang2}{cmd:boundedur mtests} {hline 1} GLS-detrended (OLS / ERS / bounds) M-tests with parametric
and non-parametric long-run variance and bound-specific simulated critical values
(Carrion-i-Silvestre & Gadea 2013).{p_end}
{phang2}{cmd:boundedur breaks} {hline 1} bounded M / variance-ratio / ADF tests allowing one or two
structural breaks in mean (Carrion-i-Silvestre & Gadea 2016).{p_end}
{phang2}{cmd:boundedur hlt} {hline 1} Harvey-Leybourne-Taylor trend/level-shift tests for bounded
series, Case A and Case B (Carrion-i-Silvestre & Gadea 2024).{p_end}

{marker references}{...}
{title:References}

{phang}
Cavaliere, G., and F. Xu. 2014. Testing for unit roots in bounded time series.
{it:Journal of Econometrics} 178: 259-272.
{browse "https://doi.org/10.1016/j.jeconom.2013.08.026":doi:10.1016/j.jeconom.2013.08.026}.

{phang}
Cavaliere, G. 2005. Limited time series with a unit root. {it:Econometric Theory} 21: 907-945.

{phang}
Ng, S., and P. Perron. 2001. Lag length selection and the construction of unit root tests with
good size and power. {it:Econometrica} 69: 1519-1554.

{phang}
Carrion-i-Silvestre, J. L., and M. D. Gadea. 2013. GLS-based unit root tests for bounded processes.
Working paper (companion to this library's {cmd:mtests} module).

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite Cavaliere & Xu (2014) when using {cmd:boundedur cx}.
