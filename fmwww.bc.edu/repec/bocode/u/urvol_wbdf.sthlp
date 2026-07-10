{smcl}
{* *! version 1.0.0  09jul2026}{...}
{vieweralsosee "urvol" "help urvol"}{...}
{vieweralsosee "urvol beare" "help urvol_beare"}{...}
{vieweralsosee "urvol bzu" "help urvol_bzu"}{...}
{vieweralsosee "dfuller" "help dfuller"}{...}
{vieweralsosee "pperron" "help pperron"}{...}
{viewerjumpto "Syntax" "urvol_wbdf##syntax"}{...}
{viewerjumpto "Description" "urvol_wbdf##description"}{...}
{viewerjumpto "Options" "urvol_wbdf##options"}{...}
{viewerjumpto "Method" "urvol_wbdf##method"}{...}
{viewerjumpto "Examples" "urvol_wbdf##examples"}{...}
{viewerjumpto "Stored results" "urvol_wbdf##results"}{...}
{viewerjumpto "References" "urvol_wbdf##references"}{...}
{title:Title}

{phang}
{bf:urvol wbdf} {hline 2} Wild-bootstrap (augmented) Dickey-Fuller / Phillips-Perron unit-root test

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:urvol wbdf} {varname} {ifin} {cmd:,} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt tr:end}}include a constant and linear trend (default: constant only){p_end}
{synopt:{opt noc:onstant}}no deterministic term{p_end}
{synopt:{opt stat:istic(t|rho)}}base statistic: {cmd:t} (ADF t-ratio, default) or {cmd:rho} (coefficient){p_end}

{syntab:Lag order (short-run dynamics)}
{synopt:{opt l:ags(#)}}fixed number of augmenting lags{p_end}
{synopt:{opt maxl:ags(#)}}maximum lag for information-criterion selection{p_end}
{synopt:{opt ic(string)}}selection rule: {cmd:maic} (default), {cmd:aic}, {cmd:bic} or {cmd:none}{p_end}

{syntab:Bootstrap}
{synopt:{opt r:eps(#)}}bootstrap replications (default 999){p_end}
{synopt:{opt w:ild(string)}}multiplier: {cmd:rademacher} (default), {cmd:normal} or {cmd:mammen}{p_end}
{synopt:{opt s:eed(#)}}random-number seed{p_end}

{syntab:Reporting}
{synopt:{opt g:raph}}plot the bootstrap null distribution with the observed statistic{p_end}
{synopt:{opt gname(name)}}name for the saved graph{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:urvol wbdf} computes the standard augmented Dickey{c 45}Fuller (ADF)
t-statistic (or the coefficient / {it:rho} statistic) for the null of a unit
root, and obtains its {it:p}-value from a {bf:wild bootstrap}.  This is the
approach of Cavaliere and Taylor (2008, 2009): rather than comparing the
statistic to a fixed critical value {c 45} which is invalid when the innovation
variance changes over the sample (Cavaliere 2004) {c 45} the wild bootstrap
regenerates pseudo-samples that inherit the observed volatility pattern, so the
resulting {it:p}-value is asymptotically correct under a very wide class of
non-stationary volatility.

{pstd}
{cmd:wbdf} is the robust {bf:baseline} of the family: it fixes the {it:size}
distortion of DF/PP but, because it does not reweight observations by their
volatility, its {it:power} is comparable to the ordinary DF test.  For power
gains use {helpb urvol_beare:beare} or {helpb urvol_bzu:bzu}.

{marker options}{...}
{title:Options}

{phang}{opt trend} / {opt noconstant} select the deterministic component removed
from the data.  With {opt trend} the regression includes {it:1} and {it:t}; the
default includes {it:1}.

{phang}{opt statistic(t|rho)} chooses the base statistic.  {cmd:t} is the ADF
t-ratio for the lagged-level coefficient; {cmd:rho} is the (normalized-bias)
coefficient statistic {it:n({c 40}alpha-hat {c 45} 1{c 41})}.  Both are lower-tailed.

{phang}{opt lags(#)} fixes the number of augmenting lagged differences.  If
omitted, the order is selected by {opt ic()} up to {opt maxlags()} (default
maxlag = floor(12(n/100){c 94}0.25)).  {cmd:maic} is the modified AIC of
Ng and Perron (2001).  {bf:The selection is re-run inside every bootstrap
replication} so the bootstrap fully mirrors the observed procedure.

{phang}{opt reps(#)} bootstrap replications (default 999; use {c 62}=999 for
reliable tail {it:p}-values).

{phang}{opt wild(string)} the external multiplier {it:z*}.  {cmd:rademacher}
({c 177}1 with equal probability, the default) is the standard choice for unit-root
wild bootstraps; {cmd:normal} draws N(0,1); {cmd:mammen} uses Mammen's (1993)
two-point distribution.

{marker method}{...}
{title:Method}

{pstd}
Let the ADF regression be

{p 8 8 2}{it:Dy(t) = mu ({c 43} beta t) {c 43} theta y(t-1) {c 43} sum_j gamma_j Dy(t-j) {c 43} e(t)},{p_end}

{pstd}
with observed statistic {it:S} (the t-ratio of {it:theta} or {it:n theta-hat}).
Restricted residuals {it:e-hat(t)} are obtained by imposing the unit root
(regressing {it:Dy} on the differenced deterministics only).  For
{it:b = 1,...,B}:  draw multipliers {it:z*(t)}; form bootstrap errors
{it:e*(t) = e-hat(t) z*(t)}; cumulate {it:X*(t) = sum_{s<=t} e*(s)}; and recompute
the statistic {it:S*(b)} from the {ul:same} ADF regression (re-selecting the lag
if an information criterion is used).  The one-sided bootstrap {it:p}-value is
the fraction of {it:S*(b) <= S}.

{pstd}
Because {it:e*(t)} multiplies the actual residuals, the pseudo-data reproduce the
sample's time-varying variance, delivering asymptotically valid inference under
non-stationary volatility (Cavaliere and Taylor 2008, 2009).

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse wpi1}{p_end}
{phang2}{cmd:. urvol wbdf ln_wpi, trend}{p_end}
{phang2}{cmd:. urvol wbdf ln_wpi, trend statistic(rho) reps(1999)}{p_end}
{phang2}{cmd:. urvol wbdf ln_wpi, trend maxlags(8) ic(maic) graph}{p_end}
{phang2}{cmd:. urvol wbdf ln_wpi, trend wild(mammen) seed(12345)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:urvol wbdf} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}observed test statistic{p_end}
{synopt:{cmd:r(p)}}one-sided wild-bootstrap p-value{p_end}
{synopt:{cmd:r(lags)}}augmenting lags used{p_end}
{synopt:{cmd:r(N)}}effective observations in the regression{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(test)}}{cmd:wbdf}{p_end}
{synopt:{cmd:r(statistic)}}{cmd:t} or {cmd:rho}{p_end}
{synopt:{cmd:r(wild)}}multiplier scheme{p_end}

{marker references}{...}
{title:References}

{phang}Cavaliere, G. 2004. Unit root tests under time-varying variances.
{it:Econometric Reviews} 23(3): 259-292.
{browse "https://doi.org/10.1081/ETC-200028215":doi:10.1081/ETC-200028215}.{p_end}

{phang}Cavaliere, G., and A. M. R. Taylor. 2008. Bootstrap unit root tests for
time series with non-stationary volatility. {it:Econometric Theory} 24(1): 43-71.{p_end}

{phang}Cavaliere, G., and A. M. R. Taylor. 2009. Heteroskedastic time series with
a unit root. {it:Econometric Theory} 25(5): 1228-1276.{p_end}

{phang}Ng, S., and P. Perron. 2001. Lag length selection and the construction of
unit root tests with good size and power. {it:Econometrica} 69(6): 1519-1554.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}{p_end}
