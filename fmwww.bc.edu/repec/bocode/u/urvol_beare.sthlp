{smcl}
{* *! version 1.0.0  09jul2026}{...}
{vieweralsosee "urvol" "help urvol"}{...}
{vieweralsosee "urvol wbdf" "help urvol_wbdf"}{...}
{vieweralsosee "urvol bzu" "help urvol_bzu"}{...}
{vieweralsosee "pperron" "help pperron"}{...}
{viewerjumpto "Syntax" "urvol_beare##syntax"}{...}
{viewerjumpto "Description" "urvol_beare##description"}{...}
{viewerjumpto "Options" "urvol_beare##options"}{...}
{viewerjumpto "Method" "urvol_beare##method"}{...}
{viewerjumpto "Examples" "urvol_beare##examples"}{...}
{viewerjumpto "Stored results" "urvol_beare##results"}{...}
{viewerjumpto "References" "urvol_beare##references"}{...}
{title:Title}

{phang}
{bf:urvol beare} {hline 2} Beare (2017) kernel-rescaled Phillips-Perron unit-root test

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:urvol beare} {varname} {ifin} {cmd:,} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt tr:end}}include a constant and linear trend (default: constant only){p_end}
{synopt:{opt noc:onstant}}no deterministic term{p_end}

{syntab:Volatility & long-run variance}
{synopt:{opt b:andwidth(#)}}kernel bandwidth {it:h} for the volatility path, in (0,1) (default 0.1){p_end}
{synopt:{opt hacbw(#)}}Bartlett HAC bandwidth for the PP long-run variance (default: Newey-West rule){p_end}

{syntab:Inference}
{synopt:{opt boot:strap}}report wild-bootstrap p-values (default){p_end}
{synopt:{opt asy:mptotic}}report only the asymptotic DF critical values (constant case){p_end}
{synopt:{opt r:eps(#)}}bootstrap replications (default 999){p_end}
{synopt:{opt s:eed(#)}}random-number seed{p_end}

{syntab:Reporting}
{synopt:{opt g:raph}}plot the estimated volatility path and the rescaled series{p_end}
{synopt:{opt gname(name)}}name for the saved graph{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:urvol beare} implements the unit-root test of Beare (2017).  The idea is to
{bf:rescale} the differenced series by a non-parametric estimate of the
volatility path and then apply a Phillips{c 45}Perron (PP) test to the cumulated,
rescaled data.  Beare shows that in the constant-mean case the rescaled statistic
recovers the {bf:ordinary} Dickey{c 45}Fuller null distribution, so the classical
critical values apply {c 45} no simulation or bootstrap is strictly required.  The
test is convenient and performs well even when the volatility path is
discontinuous (variance breaks).

{marker options}{...}
{title:Options}

{phang}{opt trend} / {opt noconstant} select the deterministic component.  With a
constant the rescaled statistic is {bf:pivotal} (standard DF distribution).  With
a {opt trend} it is {ul:not} pivotal (Beare 2017, Theorem 4.3): use bootstrap
{it:p}-values ({opt bootstrap}, the default).

{phang}{opt bandwidth(#)} the bandwidth {it:h} of the Gaussian (Nadaraya{c 45}Watson)
kernel used to estimate the volatility path {it:omega-hat(s/n)}.  It must lie in
(0,1); Beare (2017) recommends {bf:0.1}, which controls size well.  Larger {it:h}
oversmooths (approaching the homoskedastic PP test); smaller {it:h} undersmooths.

{phang}{opt hacbw(#)} the Bartlett-kernel bandwidth for the long-run variance in
the PP correction.  The default is the Newey{c 45}West rule
floor(4(n/100){c 94}(2/9)).

{phang}{opt bootstrap} (default) reports one-sided wild-bootstrap {it:p}-values,
valid in {ul:all} deterministic cases including the non-pivotal trend case.
{opt asymptotic} instead reports only the asymptotic 5% DF critical values (valid
with a constant).

{marker method}{...}
{title:Method}

{pstd}
Write the increments {it:Dy(t) = y(t) {c 45} y(t-1)}.  The volatility path is the
Nadaraya{c 45}Watson estimator (Beare 2017, eq. 4.2)

{p 8 8 2}{it:omega-hat(r){c 94}2 = sum_t k({c 40}(t/n {c 45} r)/h{c 41}) u-hat(t){c 94}2 / sum_t k({c 40}(t/n {c 45} r)/h{c 41})},{p_end}

{pstd}
with a Gaussian kernel {it:k} and (detrended) residuals {it:u-hat}.  The rescaled
series is

{p 8 8 2}{it:y*(t) = sum_{s<=t} Dy(s) / omega-hat(s/n)}   (constant case),{p_end}

{pstd}
and, with a trend, the increments are Schmidt{c 45}Phillips detrended before
rescaling (eq. 4.7).  The reported statistics are the PP coefficient
{it:Z-alpha} and t-ratio {it:Z-t} computed on {it:y*(t)} regressed on its lag and
a constant (Cavaliere 2004, eq. 6):

{p 8 8 2}{it:Z-alpha = n({c 40}phi-hat {c 45} 1{c 41}) {c 45} (lambda-hat{c 94}2 {c 45} s-hat{c 94}2)/2 / [n{c 94}{c 45}2 sum {c 40}y*(t-1) {c 45} ybar*{c 41}{c 94}2]}.{p_end}

{pstd}
In the constant case {it:Z-alpha} and {it:Z-t} have the standard DF
{it:rho}- and {it:tau}-distributions (Beare 2017, Theorem 4.2).

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse wpi1}{p_end}
{phang2}{cmd:. urvol beare ln_wpi, trend}{p_end}
{phang2}{cmd:. urvol beare ln_wpi, bandwidth(0.1) graph}{p_end}
{phang2}{cmd:. urvol beare ln_wpi, bandwidth(0.2) asymptotic}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:urvol beare} stores the following in {cmd:r()}:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(zalpha)}}rescaled PP coefficient statistic{p_end}
{synopt:{cmd:r(zt)}}rescaled PP t-statistic{p_end}
{synopt:{cmd:r(p_zalpha)}}bootstrap p-value for Z-alpha{p_end}
{synopt:{cmd:r(p_zt)}}bootstrap p-value for Z-t{p_end}
{synopt:{cmd:r(bandwidth)}}volatility bandwidth h{p_end}
{synopt:{cmd:r(hacbw)}}HAC bandwidth{p_end}
{synopt:{cmd:r(N)}}number of increments{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(test)}}{cmd:beare}{p_end}

{marker references}{...}
{title:References}

{phang}Beare, B. K. 2017. Unit root testing with unstable volatility.
{it:Journal of Time Series Analysis} 39(6): 816-835.
{browse "https://doi.org/10.1111/jtsa.12279":doi:10.1111/jtsa.12279}.{p_end}

{phang}Cavaliere, G. 2004. Unit root tests under time-varying variances.
{it:Econometric Reviews} 23(3): 259-292.
{browse "https://doi.org/10.1081/ETC-200028215":doi:10.1081/ETC-200028215}.{p_end}

{phang}Schmidt, P., and P. C. B. Phillips. 1992. LM tests for a unit root in the
presence of deterministic trends. {it:Oxford Bulletin of Economics and
Statistics} 54(3): 257-287.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}{p_end}
