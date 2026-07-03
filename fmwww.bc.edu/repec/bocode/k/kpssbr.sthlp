{smcl}
{* *! version 1.0.2  14may2026}{...}
{cmd:help kpssbr}
{hline}

{title:Title}

{p 4 4 2}
{bf:kpssbr} {hline 2} KPSS unit root tests with up to 2 structural breaks

{title:Syntax}

{p 8 16 2}
{cmd:kpssbr} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt trend}}add a linear trend to the deterministic component (only with {cmd:breaks(0)}){p_end}
{synopt :{opt bre:aks(#)}}number of structural breaks: {cmd:0} (default), {cmd:1}, or {cmd:2}{p_end}
{synopt :{opt m:odel(spec)}}for {cmd:breaks(1)}: {cmd:intercept} (default) | {cmd:both}{p_end}
{synopt :}for {cmd:breaks(2)}: {cmd:1}=AAn (default) | {cmd:2}=AA | {cmd:3}=BB | {cmd:4}=CC{p_end}
{synopt :{opt lag:s(spec)}}lag rule: {cmd:short} (default) | {cmd:long} | {cmd:nil} | positive integer{p_end}
{synopt :{opt u:se(spec)}}auto bandwidth: {it:method} {it:kernel} (e.g. {cmd:nw ba}) | fixed integer{p_end}
{synopt :{opt tri:m(#)}}trimming for the {cmd:breaks(1)} search (default {cmd:0.10}){p_end}
{synopt :{opt trace}}print progress for {cmd:breaks(2)} (cubic in T){p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:kpssbr} implements the family of KPSS stationarity tests, with the
null of I(0) stationarity. The test statistic is

    {space 8}eta = T^(-2) * sum(S_t^2) / lrv

{pstd}
where S_t is the partial sum of regression residuals from the deterministic
specification, and lrv is a kernel estimate of the long-run variance. The
null is rejected when eta exceeds the right-tail critical value.

{pstd}
Three variants are available:

{phang}
- {cmd:breaks(0)} (default): classic KPSS of
{help kpssbr##KPSS1992:Kwiatkowski, Phillips, Schmidt and Shin (1992)},
with intercept only (without {opt trend}) or intercept+trend (with {opt trend}).

{phang}
- {cmd:breaks(1)}: one unknown break extension of
{help kpssbr##Kurozumi2002:Kurozumi (2002)}. {opt model(intercept)} =
level shift only; {opt model(both)} = level + slope shift. The break point
is the value of TB in the trimmed range [round(trim*T), round((1-trim)*T)]
that {bf:minimises} eta.

{phang}
- {cmd:breaks(2)}: two unknown breaks of
{help kpssbr##CSS2007:Carrion-i-Silvestre and Sanso (2007)}. Four models
via {opt model()}: {cmd:1}=AAn (two level shifts only), {cmd:2}=AA (level
shifts + trend), {cmd:3}=BB (trend shifts), {cmd:4}=CC (level + trend
shifts). Joint search over all pairs (TB1, TB2). Cubic in T.

{title:Options}

{phang}
{opt trend} adds a linear trend to the deterministic component. Only
relevant when {opt breaks(0)}, the default. Without {opt trend} the
test is run against the null of {it:level stationarity} (intercept
only); with {opt trend} it is run against the null of {it:trend
stationarity} (intercept + linear trend). The choice changes both the
regressors used to compute residuals AND the critical values; see Ho's
COINT::kpss for details.

{phang}
{opt breaks(#)} selects the number of structural breaks:
{cmd:0} (default) is the classic KPSS test;
{cmd:1} is the Kurozumi (2002) one-break extension;
{cmd:2} is the Carrion-i-Silvestre and Sanso (2007) two-break extension.

{phang}
{opt model(spec)} selects the deterministic specification of the break
tests.

{pmore}
For {opt breaks(1)} (Kurozumi 2002), the regression of the time series
on the deterministic component is:

{p 12 14 2}
{cmd:intercept} (default): a level shift at the break date TB. The
regressors are: a constant and a level-shift dummy
DU(t) = 1 if t > TB, 0 otherwise.

{p 12 14 2}
{cmd:both}: a level shift plus a slope shift. The regressors are: a
constant, a linear trend, a level-shift dummy DU(t), and a slope-shift
dummy DT(t) = (t - TB)/T if t > TB, 0 otherwise.

{pmore}
For {opt breaks(2)} (Carrion-i-Silvestre and Sanso 2007), four models
are available, distinguished by which deterministic features change at
the two break dates TB1 and TB2:

{p 12 14 2}
{cmd:1 = AAn}: two level shifts, no trend. Regressors: constant,
DU1(t), DU2(t).

{p 12 14 2}
{cmd:2 = AA}: two level shifts and a linear trend (the trend itself
does not break). Regressors: constant, trend, DU1(t), DU2(t).

{p 12 14 2}
{cmd:3 = BB}: two slope shifts and a linear trend (no level jumps).
Regressors: constant, trend, DT1(t), DT2(t).

{p 12 14 2}
{cmd:4 = CC}: both level and slope shifts at each break point.
Regressors: constant, trend, DU1(t), DU2(t), DT1(t), DT2(t).

{pmore}
Here DUi(t) = 1 if t > TBi (level dummy) and DTi(t) = (t - TBi)/T if
t > TBi (slope dummy), for i = 1, 2; both dummies are zero before the
break. The break dates TB1 and TB2 are chosen jointly to minimise the
KPSS statistic over all admissible pairs.

{phang}
{opt lags(spec)} controls the lag length lmax used in the kernel sum
that estimates the long-run variance (LRV). The LRV enters the KPSS
statistic as the denominator:

    {space 8}eta = T^(-2) * sum(S_t^2) / lrv

{pmore}
The lag sum corrects the LRV for serial correlation in the residuals.
With u_t denoting the regression residual,

    {space 8}lrv = (1/T) sum_t u_t^2 + (2/T) sum_{j=1}^{lmax} w(j,lmax) sum_t u_t u_{t-j}

{pmore}
The first term is the ordinary residual variance; the second sum adds
the autocovariances up to lag lmax, weighted by the kernel w. The
{opt lags()} option only sets lmax (the kernel under {opt lags()} is
always Bartlett; see {opt use()} for other kernels).

{p 12 14 2}
{cmd:short} (default) sets lmax = floor(4*(T/100)^(2/9)). This is the
rule used by Tsung-wu Ho's COINT::kpss with {it:lags="short"} and
originates from KPSS (1992, appendix). Adequate when the residuals show
only weak serial correlation. For T=703 this gives lmax=6.

{p 12 14 2}
{cmd:long} sets lmax = floor(12*(T/100)^(2/9)) - the KPSS (1992) "long"
rule, also used by COINT::kpss with {it:lags="long"}. Recommended when
the residuals are strongly autocorrelated (e.g. an ARMA(1,1) error
process). For T=703 this gives lmax=18.

{p 12 14 2}
{cmd:nil} sets lmax = 0. No autocorrelation correction is performed:
the second sum vanishes, so lrv collapses to the plain residual
variance. If the residuals are serially correlated, the true LRV
exceeds e'e/T, the denominator is under-estimated, and the eta
statistic is {bf:inflated} - the test then over-rejects the null
of stationarity. Use {cmd:nil} only as a diagnostic; for inference
prefer {cmd:short}, {cmd:long}, or one of the automatic-bandwidth
rules under {opt use()}.

{p 12 14 2}
{it:positive integer} fixes lmax to that exact value, identical to
COINT::kpss with {it:lags=<integer>}.

{phang}
{opt use(spec)} overrides {opt lags()} and selects the lag length and
kernel automatically. Three forms:

{p 12 14 2}
{it:empty} (default): {opt use()} is inactive, so {opt lags()} drives
the lag length and the kernel is Bartlett.

{p 12 14 2}
{it:method kernel} (two tokens): the lag length is set to
floor(getBandwidth(y)) using one of two automatic bandwidth selection
rules - {cmd:and} for Andrews (1991), {cmd:nw} for Newey and West
(1994) - combined with one of three kernels - {cmd:ba} Bartlett,
{cmd:pa} Parzen, {cmd:qs} Quadratic Spectral. Identical to COINT::kpss
with {it:use=c(method,kernel)}.

{p 12 14 2}
{it:single integer}: fixes lmax to that value and uses the Bartlett
kernel. Identical to COINT::kpss with {it:use=integer}.

{phang}
{opt trim(#)} sets the trimming proportion used in the {opt breaks(1)}
break search. The candidate break dates run from round(trim*T) to
round((1-trim)*T). The default is 0.10.

{phang}
{opt trace} prints periodic progress messages for {opt breaks(2)},
which is cubic in T and can take minutes or hours on large samples.


{title:Bandwidth and lag selection - formal definition}

{pstd}
The long-run variance is

    {space 8}lrv = e'e/T + (2/T) sum_{i=1}^{lmax} w_i e[1..T-i]' e[i+1..T]

{pstd}
Three kernels are supported: {bf:Bartlett} ({cmd:ba}), {bf:Quadratic
Spectral} ({cmd:qs}), and {bf:Parzen} ({cmd:pa}) - in the centred form
used by Ho's COINT package.

{pstd}
The lag lmax is determined as follows:

{phang}
- If {opt use()} is empty: {opt lags()} drives the choice.
{cmd:short} = floor(4*(T/100)^(2/9)), {cmd:long} = floor(12*(T/100)^(2/9)),
{cmd:nil} = 0, integer = verbatim. Kernel is Bartlett.

{phang}
- If {opt use(method kernel)}: lmax = floor(getBandwidth(y)), with
{help kpssbr##Andrews1991:Andrews (1991)} bandwidth when {it:method}={cmd:and}
and {help kpssbr##NeweyWest1994:Newey and West (1994)} when {it:method}={cmd:nw}.
Bandwidth is computed on the {bf:original series} y.

{phang}
- If {opt use(#)}: lag is set to # and the Bartlett kernel is used.


{title:Examples}

{pstd}
All examples below have been verified against the equivalent R call
({cmd:kpss}, {cmd:kpss_1br}, {cmd:kpss_2br}) from Tsung-wu Ho's COINT
package to at least 14 decimal places. Each block is self-contained:
copy and paste to reproduce.


{dlgtab:Deterministic model specifications at a glance}

{pstd}
Before working through the examples, the table below summarises which
regressors enter the residual equation under each combination of
{opt breaks()} and {opt model()}, together with the exact Stata
command. Let DU(t) be a level-shift dummy (1 if t > TB, 0 otherwise)
and DT(t) = (t - TB)/T if t > TB, 0 otherwise, a slope-shift dummy.

{p 4 4 2}
{ul:No break ({cmd:breaks(0)}):}{p_end}

{p 8 8 2}intercept only: y = const + e{p_end}
{phang3}{cmd:kpssbr y}{p_end}

{p 8 8 2}intercept + trend: y = const + b*t + e{p_end}
{phang3}{cmd:kpssbr y, trend}{p_end}

{p 4 4 2}
{ul:One break ({cmd:breaks(1)}, Kurozumi 2002):}{p_end}

{p 8 8 2}model(intercept): y = const + a*DU(t) + e{p_end}
{phang3}{cmd:kpssbr y, breaks(1) model(intercept)}{p_end}

{p 8 8 2}model(both): y = const + b*t + a*DU(t) + c*DT(t) + e{p_end}
{phang3}{cmd:kpssbr y, breaks(1) model(both)}{p_end}

{p 4 4 2}
{ul:Two breaks ({cmd:breaks(2)}, Carrion-i-Silvestre and Sanso 2007):}{p_end}

{p 8 8 2}model(1) AAn: y = const + a1*DU1(t) + a2*DU2(t) + e{p_end}
{phang3}{cmd:kpssbr y, breaks(2) model(1)}{p_end}

{p 8 8 2}model(2) AA: y = const + b*t + a1*DU1(t) + a2*DU2(t) + e{p_end}
{phang3}{cmd:kpssbr y, breaks(2) model(2)}{p_end}

{p 8 8 2}model(3) BB: y = const + b*t + c1*DT1(t) + c2*DT2(t) + e{p_end}
{phang3}{cmd:kpssbr y, breaks(2) model(3)}{p_end}

{p 8 8 2}model(4) CC: y = const + b*t + a1*DU1(t) + a2*DU2(t) + c1*DT1(t) + c2*DT2(t) + e{p_end}
{phang3}{cmd:kpssbr y, breaks(2) model(4)}{p_end}

{pstd}
The KPSS statistic is computed from the partial sums of the
residuals e. The break date TB ({cmd:breaks(1)}) or the pair
(TB1, TB2) ({cmd:breaks(2)}) is chosen to minimise the resulting
statistic over a grid of admissible dates.


{dlgtab:Example 1: Classic KPSS, intercept only, lags=short}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF}{p_end}
{pstd}-> teststat = 3.550467574793232, lag = 6{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:install.packages("COINT")}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, lags = "short", use = NULL)}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 2: Classic KPSS, intercept only, lags=long}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, lags(long)}{p_end}
{pstd}-> teststat = 1.455862597583669, lag = 18{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, lags = "long", use = NULL)}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 3: Classic KPSS, intercept only, no lag correction}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, lags(nil)}{p_end}
{pstd}-> teststat = 23.917089315971140, lag = 0{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, lags = "nil", use = NULL)}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 4: Classic KPSS, intercept only, Newey-West / Bartlett}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, use(nw ba)}{p_end}
{pstd}-> teststat = 1.250961577820944, lag = 22{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, use = c("nw","ba"))}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 5: Classic KPSS, intercept only, Newey-West / Parzen}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, use(nw pa)}{p_end}
{pstd}-> teststat = 3.095123619789721, lag = 24{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, use = c("nw","pa"))}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 6: Classic KPSS, intercept only, Newey-West / QS}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, use(nw qs)}{p_end}
{pstd}-> teststat = 1.973728414365710, lag = 10{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, use = c("nw","qs"))}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 7: Classic KPSS, intercept only, Andrews / Bartlett}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, use(and ba)}{p_end}
{pstd}-> teststat = 0.333132491221583, lag = 457{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, use = c("and","ba"))}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 8: Classic KPSS, intercept only, Andrews / Parzen}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, use(and pa)}{p_end}
{pstd}-> teststat = 0.500215577865494, lag = 702{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, use = c("and","pa"))}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 9: Classic KPSS, intercept only, Andrews / QS}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, use(and qs)}{p_end}
{pstd}-> teststat = 0.544419758900968, lag = 622{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, use = c("and","qs"))}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 10: Classic KPSS, intercept only, fixed lag = 15}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, use(15)}{p_end}
{pstd}-> teststat = 1.679413432461915, lag = 15{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = NULL, use = 15)}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 11: Classic KPSS with linear trend, lags=short}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, trend}{p_end}
{pstd}-> teststat = 0.475262923729511, lag = 6{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:T <- length(INF); D <- cbind(const = rep(1,T), trend = seq(T)/T)}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = D, lags = "short", use = NULL)}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 12: Classic KPSS, trend, lags=long, Newey-West / Bartlett (kpss.Rd example)}

{pstd}This is the first call in the R help file kpss.Rd.{p_end}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, trend lags(long) use(nw ba)}{p_end}
{pstd}-> teststat = 0.179928029530022, lag = 22{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:T <- length(INF); D <- cbind(const = rep(1,T), trend = seq(T)/T)}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = D, lags = "long", use = c("nw","ba"))}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 13: Classic KPSS, trend, lags=long, fixed lag = 15 (kpss.Rd example)}

{pstd}This is the second call in the R help file kpss.Rd.{p_end}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, trend lags(long) use(15)}{p_end}
{pstd}-> teststat = 0.233211133758688, lag = 15{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:T <- length(INF); D <- cbind(const = rep(1,T), trend = seq(T)/T)}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = D, lags = "long", use = 15)}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 14: Classic KPSS, trend, lags=long, use=NULL (kpss.Rd example)}

{pstd}This is the third call in the R help file kpss.Rd.{p_end}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, trend lags(long)}{p_end}
{pstd}-> teststat = 0.205124023449666, lag = 18{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:T <- length(INF); D <- cbind(const = rep(1,T), trend = seq(T)/T)}{p_end}
{phang2}{cmd:KPSS <- kpss(INF, x = D, lags = "long", use = NULL)}{p_end}
{phang2}{cmd:KPSS$teststat}{p_end}
{phang2}{cmd:KPSS$lag}{p_end}
{phang2}{cmd:KPSS$cval}{p_end}


{dlgtab:Example 15: KPSS one break, intercept model, first 200 obs}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF in 1/200, breaks(1) model(intercept)}{p_end}
{pstd}-> teststat = 0.152040836378325, bpoint = 73, lag = 4{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[1:200,"INF"])}{p_end}
{phang2}{cmd:KPSS1 <- kpss_1br(INF, lags = "short", model = "intercept", use = NULL)}{p_end}
{phang2}{cmd:KPSS1$teststat}{p_end}
{phang2}{cmd:KPSS1$lag}{p_end}
{phang2}{cmd:KPSS1$bpoint}{p_end}
{phang2}{cmd:KPSS1$cval}{p_end}


{dlgtab:Example 16: KPSS one break, both model, first 200 obs}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF in 1/200, breaks(1) model(both)}{p_end}
{pstd}-> teststat = 0.100890074277901, bpoint = 157, lag = 4{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[1:200,"INF"])}{p_end}
{phang2}{cmd:KPSS1 <- kpss_1br(INF, lags = "short", model = "both", use = NULL)}{p_end}
{phang2}{cmd:KPSS1$teststat}{p_end}
{phang2}{cmd:KPSS1$lag}{p_end}
{phang2}{cmd:KPSS1$bpoint}{p_end}
{phang2}{cmd:KPSS1$cval}{p_end}


{dlgtab:Example 17: KPSS one break, intercept, Newey-West / Bartlett, first 200 obs}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF in 1/200, breaks(1) model(intercept) use(nw ba)}{p_end}
{pstd}-> teststat = 0.073088938651760, bpoint = 73, lag = 11{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[1:200,"INF"])}{p_end}
{phang2}{cmd:KPSS1 <- kpss_1br(INF, model = "intercept", use = c("nw","ba"))}{p_end}
{phang2}{cmd:KPSS1$teststat}{p_end}
{phang2}{cmd:KPSS1$lag}{p_end}
{phang2}{cmd:KPSS1$bpoint}{p_end}
{phang2}{cmd:KPSS1$cval}{p_end}


{dlgtab:Example 18: KPSS one break, both model, full sample (kpss_1br.Rd example)}

{pstd}This is the example block in the R help file kpss_1br.Rd.{p_end}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF, breaks(1) model(both) use(nw ba)}{p_end}
{pstd}-> teststat = 0.064682218165045, bpoint = 215, lag = 22{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:KPSS1 <- kpss_1br(INF, model = "both", use = c("nw","ba"))}{p_end}
{phang2}{cmd:KPSS1$teststat}{p_end}
{phang2}{cmd:KPSS1$lag}{p_end}
{phang2}{cmd:KPSS1$bpoint}{p_end}
{phang2}{cmd:KPSS1$cval}{p_end}


{dlgtab:Example 19: KPSS two breaks, model 1 (AAn), first 80 obs}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF in 1/80, breaks(2) model(1)}{p_end}
{pstd}-> teststat = 0.119321187017947, bp1 = 21, bp2 = 46{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[1:80,"INF"])}{p_end}
{phang2}{cmd:KPSS2 <- kpss_2br(INF, lags = "short", model = 1, use = NULL)}{p_end}
{phang2}{cmd:KPSS2$teststat}{p_end}
{phang2}{cmd:KPSS2$lag}{p_end}
{phang2}{cmd:KPSS2$bpoint}{p_end}
{phang2}{cmd:KPSS2$cval}{p_end}


{dlgtab:Example 20: KPSS two breaks, model 2 (AA), first 80 obs}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF in 1/80, breaks(2) model(2)}{p_end}
{pstd}-> teststat = 0.072330771228686, bp1 = 44, bp2 = 56{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[1:80,"INF"])}{p_end}
{phang2}{cmd:KPSS2 <- kpss_2br(INF, lags = "short", model = 2, use = NULL)}{p_end}
{phang2}{cmd:KPSS2$teststat}{p_end}
{phang2}{cmd:KPSS2$lag}{p_end}
{phang2}{cmd:KPSS2$bpoint}{p_end}
{phang2}{cmd:KPSS2$cval}{p_end}


{dlgtab:Example 21: KPSS two breaks, model 3 (BB), first 80 obs}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF in 1/80, breaks(2) model(3)}{p_end}
{pstd}-> teststat = 0.030896518149923, bp1 = 39, bp2 = 68{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[1:80,"INF"])}{p_end}
{phang2}{cmd:KPSS2 <- kpss_2br(INF, lags = "short", model = 3, use = NULL)}{p_end}
{phang2}{cmd:KPSS2$teststat}{p_end}
{phang2}{cmd:KPSS2$lag}{p_end}
{phang2}{cmd:KPSS2$bpoint}{p_end}
{phang2}{cmd:KPSS2$cval}{p_end}


{dlgtab:Example 22: KPSS two breaks, model 4 (CC), first 80 obs}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF in 1/80, breaks(2) model(4)}{p_end}
{pstd}-> teststat = 0.029942326110303, bp1 = 38, bp2 = 65{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[1:80,"INF"])}{p_end}
{phang2}{cmd:KPSS2 <- kpss_2br(INF, lags = "short", model = 4, use = NULL)}{p_end}
{phang2}{cmd:KPSS2$teststat}{p_end}
{phang2}{cmd:KPSS2$lag}{p_end}
{phang2}{cmd:KPSS2$bpoint}{p_end}
{phang2}{cmd:KPSS2$cval}{p_end}


{dlgtab:Example 23: KPSS two breaks, model 1, T=200, Newey-West / Bartlett (kpss_2br.Rd example)}

{pstd}This is the example block in the R help file kpss_2br.Rd.{p_end}

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr INF in 1/200, breaks(2) model(1) use(nw ba) trace}{p_end}
{pstd}-> teststat = 0.067800029275150, bp1 = 81, bp2 = 196{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[1:200,"INF"])}{p_end}
{phang2}{cmd:KPSS2 <- kpss_2br(INF, model = 1, use = c("nw","ba"))}{p_end}
{phang2}{cmd:KPSS2$teststat}{p_end}
{phang2}{cmd:KPSS2$lag}{p_end}
{phang2}{cmd:KPSS2$bpoint}{p_end}
{phang2}{cmd:KPSS2$cval}{p_end}


{title:Comparison with the kpss command from SSC}

{pstd}
The {cmd:kpss} command from SSC (Baum 2006) defaults to a {bf:trend
stationary} null with an intercept and a linear trend, and prints a
{it:table} of test statistics for lag orders 0 through Maxlag (Schwert
criterion). Our {cmd:kpssbr} defaults to an {bf:intercept-only} null,
matching the R {cmd:COINT::kpss} reference. To get the same number from
both commands, run {cmd:kpssbr} with the {cmd:trend} option and the
matching lag.

{dlgtab:Example 24: kpssbr matches the SSC kpss}

{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpss INF}{p_end}
{phang2}{cmd:kpssbr INF, trend}{p_end}
{phang2}{cmd:kpssbr INF, trend use(15)}{p_end}

{pstd}
{cmd:kpss INF} prints a table; rows lag 6 -> .475, lag 15 -> .233.
{cmd:kpssbr INF, trend} returns 0.475262923729511 (lag 6, the short
rule for T=703), and {cmd:kpssbr INF, trend use(15)} returns
0.233211133758688 (lag 15). The displayed digits agree exactly.

{pstd}
Compared with the SSC {cmd:kpss}, {cmd:kpssbr} additionally offers
(i) Andrews (1991) automatic bandwidth selection, (ii) the Parzen
kernel, and (iii) extensions to one and two unknown structural breaks
via {opt breaks()}. For example, the following call uses Andrews
bandwidth with the QS kernel - a combination not available in SSC
{cmd:kpss}:

{phang2}{cmd:kpssbr INF, trend use(and qs)}{p_end}
{pstd}-> teststat = 1.767614551567974, lag = 622{p_end}


{dlgtab:Example 25: Testing the order of integration via differencing}

{pstd}
The level series INF rejects the stationarity null
({cmd:kpssbr INF} returns eta = 3.55 versus the 1% critical value of
0.739), suggesting that INF is at least I(1). To verify, run the test
on the first and second differences. Stata's time-series operators
{cmd:D.} and {cmd:D2.} produce the same series as R's {cmd:diff(.)}
with {it:differences=1} and {it:differences=2}.

{pstd}{ul:Stata}{p_end}
{phang2}{cmd:use https://www.eruygurakademi.com/datasets/kpsstest/macro.dta, clear}{p_end}
{phang2}{cmd:kpssbr d.INF}{p_end}
{pstd}-> teststat = 0.038699, lag = 6, N = 702{p_end}
{phang2}{cmd:kpssbr d2.INF}{p_end}
{pstd}-> teststat = 0.006713, lag = 6, N = 701{p_end}

{pstd}{ul:R}{p_end}
{phang2}{cmd:library(COINT)}{p_end}
{phang2}{cmd:load(url("https://www.eruygurakademi.com/datasets/kpsstest/macro.rda"))}{p_end}
{phang2}{cmd:INF <- as.numeric(macro[,"INF"])}{p_end}
{phang2}{cmd:dINF  <- diff(INF, lag = 1, differences = 1)}{p_end}
{phang2}{cmd:d2INF <- diff(INF, lag = 1, differences = 2)}{p_end}
{phang2}{cmd:KPSSd  <- kpss(dINF,  x = NULL, lags = "short", use = NULL)}{p_end}
{phang2}{cmd:KPSSd2 <- kpss(d2INF, x = NULL, lags = "short", use = NULL)}{p_end}
{phang2}{cmd:KPSSd$teststat;  KPSSd$lag}{p_end}
{phang2}{cmd:KPSSd2$teststat; KPSSd2$lag}{p_end}

{pstd}
The first difference of INF gives eta = 0.0387, far below the 10%
critical value of 0.347, so the null of stationarity is not rejected:
{cmd:D.INF} is I(0), and therefore INF itself is I(1). The second
difference gives an even smaller eta = 0.0067, confirming the result.


{title:Stored results}

{pstd}{cmd:kpssbr} stores the following in {cmd:r()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(teststat)}}KPSS test statistic eta{p_end}
{synopt:{cmd:r(lag)}}lag used in the kernel sum{p_end}
{synopt:{cmd:r(N)}}sample size{p_end}
{synopt:{cmd:r(breaks)}}number of breaks (0, 1, 2){p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv1)}}1% critical value{p_end}
{synopt:{cmd:r(cv25)}}2.5% critical value (only for {cmd:breaks(0)}){p_end}
{synopt:{cmd:r(bpoint)}}selected break point ({cmd:breaks(1)}){p_end}
{synopt:{cmd:r(bpoint1)}}first selected break point ({cmd:breaks(2)}){p_end}
{synopt:{cmd:r(bpoint2)}}second selected break point ({cmd:breaks(2)}){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:kpssbr}{p_end}
{synopt:{cmd:r(model)}}deterministic model used in break tests{p_end}

{title:Implementation notes}

{pstd}
{cmd:kpssbr} is a verbatim port of the R functions {bf:kpss},
{bf:kpss_1br}, and {bf:kpss_2br} from Tsung-wu Ho's COINT package (CRAN,
2025), together with the {bf:getBandwidth} machinery from cointReg 0.2.0
(Aschoff 2018). All test statistics, bandwidths, lag selections, break
points and critical values match the R reference to 14 decimal places
(only the final IEEE 754 rounding bit may differ).

{pstd}
The OLS step in every candidate regression uses Mata's {bf:qrsolve},
which is robust to the rank-deficient design matrices that occasionally
arise for some break-point combinations in {cmd:breaks(2), model(3)} and
{cmd:model(4)}. This mirrors the behaviour of R's {bf:lm.fit}.

{title:References}

{p 4 8 2}{marker Andrews1991}{...}
Andrews, D. W. K. (1991). Heteroskedasticity and autocorrelation
consistent covariance matrix estimation. {it:Econometrica}, 59(3),
817-858.

{p 4 8 2}
Aschoff, S. (2018). cointReg: parameter estimation and inference in a
cointegrating regression. R package version 0.2.0.

{p 4 8 2}{marker CSS2007}{...}
Carrion-i-Silvestre, J. L. and Sanso, A. (2007). The KPSS test with two
structural breaks. {it:Spanish Economic Review}, 9(2), 105-127.

{p 4 8 2}
Ho, T.-w. (2025). COINT: cointegration analysis of time series. R
package.

{p 4 8 2}{marker Kurozumi2002}{...}
Kurozumi, E. (2002). Testing for stationarity with a break.
{it:Journal of Econometrics}, 108(1), 105-127.

{p 4 8 2}{marker KPSS1992}{...}
Kwiatkowski, D., Phillips, P. C. B., Schmidt, P. and Shin, Y. (1992).
Testing the null hypothesis of stationarity against the alternative of a
unit root. {it:Journal of Econometrics}, 54(1-3), 159-178.

{p 4 8 2}{marker NeweyWest1994}{...}
Newey, W. K. and West, K. D. (1994). Automatic lag selection in
covariance matrix estimation. {it:Review of Economic Studies}, 61(4),
631-653.

{p 4 8 2}
Phillips, P. C. B. and Jin, S. (2002). The KPSS test with seasonal
dummies. {it:Economics Letters}, 77(2), 239-243.

{title:Author}

{pstd}
H. Ozan Eruygur{p_end}
{pstd}
AHBV University, Ankara, Turkiye.{p_end}
{pstd}
Department of Economics{p_end}
{pstd}
{browse "https://www.ozaneruygur.com"}{p_end}
{pstd}
eruygur@gmail.com{p_end}

{pstd}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.{p_end}
{pstd}
{browse "https://www.eruygurakademi.com"}{p_end}
{pstd}
eruygurakademi@gmail.com{p_end}

{pstd}
kpssbr v1.0.2 -- June 2026{p_end}

{title:Please cite as:}

{pstd}
Eruygur, H. O. 2026. {bf:kpssbr}: KPSS unit root tests with up to 2
structural breaks. Stata package version 1.0.2. Available from:
{browse "https://www.eruygurakademi.com"}{p_end}
