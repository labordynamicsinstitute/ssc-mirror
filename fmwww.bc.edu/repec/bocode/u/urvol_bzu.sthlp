{smcl}
{* *! version 1.0.0  09jul2026}{...}
{vieweralsosee "urvol" "help urvol"}{...}
{vieweralsosee "urvol wbdf" "help urvol_wbdf"}{...}
{vieweralsosee "urvol beare" "help urvol_beare"}{...}
{vieweralsosee "dfgls" "help dfgls"}{...}
{viewerjumpto "Syntax" "urvol_bzu##syntax"}{...}
{viewerjumpto "Description" "urvol_bzu##description"}{...}
{viewerjumpto "Options" "urvol_bzu##options"}{...}
{viewerjumpto "Method" "urvol_bzu##method"}{...}
{viewerjumpto "Examples" "urvol_bzu##examples"}{...}
{viewerjumpto "Stored results" "urvol_bzu##results"}{...}
{viewerjumpto "References" "urvol_bzu##references"}{...}
{title:Title}

{phang}
{bf:urvol bzu} {hline 2} Boswijk & Zu (2018) adaptive wild-bootstrap likelihood-ratio unit-root test

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:urvol bzu} {varname} {ifin} {cmd:,} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt tr:end}}include a constant and linear trend (default: constant only){p_end}
{synopt:{opt noc:onstant}}no deterministic term (known zero mean){p_end}
{synopt:{opt cbar(#)}}GLS local-to-unity constant (default -7 for a constant, -13.5 for a trend){p_end}

{syntab:Lag order}
{synopt:{opt l:ags(#)}}fixed AR order p{p_end}
{synopt:{opt maxl:ags(#)}}maximum p for information-criterion selection{p_end}
{synopt:{opt ic(string)}}selection rule: {cmd:maic} (default), {cmd:aic}, {cmd:bic} or {cmd:none}{p_end}

{syntab:Volatility estimator}
{synopt:{opt w:indow(#)}}exponential-kernel window N (default: leave-one-out cross-validation){p_end}

{syntab:Bootstrap}
{synopt:{opt r:eps(#)}}bootstrap replications (default 999){p_end}
{synopt:{opt s:eed(#)}}random-number seed{p_end}

{syntab:Reporting}
{synopt:{opt g:raph}}plot the estimated volatility path{p_end}
{synopt:{opt gname(name)}}name for the saved graph{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:urvol bzu} implements the {bf:adaptive} unit-root test of Boswijk and Zu
(2018).  Unlike {helpb urvol_wbdf:wbdf} and {helpb urvol_beare:beare}, which only
correct the {it:size} of classical tests, {cmd:bzu} exploits the volatility path
to {bf:gain power}: it non-parametrically estimates the innovation volatility
{it:sigma-hat(t)}, forms a {bf:variance-weighted} generalized-least-squares
(GLS) detrended likelihood-ratio statistic, and thereby attains the Gaussian
asymptotic {bf:power envelope} for the unit-root problem under non-stationary
volatility.  Inference is by the wild bootstrap, so no critical-value tables are
needed (the limiting null distribution depends on the volatility path).

{pstd}
{cmd:bzu} is the most powerful member of the family; the power advantage over
DF-type tests grows with the sample size and is largest when the volatility
varies strongly over the sample.

{marker options}{...}
{title:Options}

{phang}{opt trend} / {opt noconstant} select the deterministic component.  With a
constant, GLS demeaning uses {it:cbar = -7}; with a {opt trend}, {it:cbar = -13.5}
(Elliott, Rothenberg and Stock 1996).  {opt cbar(#)} overrides these.

{phang}{opt lags(#)} fixes the autoregressive order {it:p} of the short-run
dynamics (an AR(p) for the level, i.e. AR(p-1) in differences).  If omitted, {it:p}
is chosen by {opt ic()} up to {opt maxlags()}.

{phang}{opt window(#)} the window {it:N} of the double-sided exponential kernel
{it:k(x) = exp(-5|x|)} used to smooth the squared residuals into the volatility
path.  If omitted it is selected by {bf:leave-one-out cross-validation}
(Boswijk and Zu 2018, Remark 4.4).

{phang}{opt reps(#)} bootstrap replications (default 999).

{marker method}{...}
{title:Method  (Boswijk & Zu 2018, Algorithm 5.1)}

{pstd}
{space 2}1. Estimate {it:sigma-hat(t)} from the OLS residuals of an AR(p-1) for
{it:Dy(t)} (a unit root imposed), smoothed by the double-sided exponential kernel
with window N.{p_end}
{pstd}
{space 2}2. GLS-demean at {it:cbar} to obtain {it:X-hat-d(t)} (weighted by
{it:1/sigma-hat(t){c 94}2}).{p_end}
{pstd}
{space 2}3. The adaptive LR statistic is the t-ratio of {it:delta} in the
variance-weighted regression{p_end}
{p 10 10 2}{it:DX-hat-d(t)/sigma-hat(t) = delta X-hat-d(t-1)/sigma-hat(t) {c 43} sum_j gamma_j DX-hat-d(t-j)/sigma-hat(t) {c 43} z(t)},{p_end}
{pstd}
which rejects for large {ul:negative} values.{p_end}
{pstd}
{space 2}4. Wild bootstrap: {it:e*(t) = e-hat(t) z*(t)}, regenerate {it:Y*} from the
fitted AR(p) with a unit root imposed, and recompute the statistic reusing the
{ul:same} {it:sigma-hat(t)} (the wild error already carries the volatility, so the
smoother is not re-estimated {c 45} Boswijk and Zu 2018).  The lower-tail
bootstrap {it:p}-value follows.{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse wpi1}{p_end}
{phang2}{cmd:. urvol bzu ln_wpi, trend}{p_end}
{phang2}{cmd:. urvol bzu ln_wpi, trend lags(4) graph}{p_end}
{phang2}{cmd:. urvol bzu ln_wpi, window(15) reps(1999) seed(777)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:urvol bzu} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}adaptive LR statistic{p_end}
{synopt:{cmd:r(p)}}one-sided wild-bootstrap p-value{p_end}
{synopt:{cmd:r(lags)}}AR order p used{p_end}
{synopt:{cmd:r(window)}}volatility window N{p_end}
{synopt:{cmd:r(cbar)}}GLS local-to-unity constant{p_end}
{synopt:{cmd:r(N)}}number of increments{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(test)}}{cmd:bzu}{p_end}

{marker references}{...}
{title:References}

{phang}Boswijk, H. P., and Y. Zu. 2018. Adaptive wild bootstrap tests for a unit
root with non-stationary volatility. {it:Econometrics Journal} 21(2): 87-113.
{browse "https://doi.org/10.1111/ectj.12100":doi:10.1111/ectj.12100}.{p_end}

{phang}Elliott, G., T. J. Rothenberg, and J. H. Stock. 1996. Efficient tests for
an autoregressive unit root. {it:Econometrica} 64(4): 813-836.{p_end}

{phang}Cavaliere, G. 2004. Unit root tests under time-varying variances.
{it:Econometric Reviews} 23(3): 259-292.
{browse "https://doi.org/10.1081/ETC-200028215":doi:10.1081/ETC-200028215}.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}{p_end}
