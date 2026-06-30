{smcl}
{* *! xtgunitroot version 1.0.0  28jun2026}{...}
{vieweralsosee "xtmunitroot" "help xtmunitroot"}{...}
{vieweralsosee "xtunitroot" "help xtunitroot"}{...}
{viewerjumpto "Syntax" "xtgunitroot##syntax"}{...}
{viewerjumpto "Description" "xtgunitroot##description"}{...}
{viewerjumpto "Options" "xtgunitroot##options"}{...}
{viewerjumpto "Stored results" "xtgunitroot##results"}{...}
{viewerjumpto "Examples" "xtgunitroot##examples"}{...}
{viewerjumpto "References" "xtgunitroot##references"}{...}
{viewerjumpto "Author" "xtgunitroot##author"}{...}
{title:Title}

{phang}
{bf:xtgunitroot} {hline 2} Generalized fixed-T panel unit root test (doubly modified estimator)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtgunitroot}
{varname}
{ifin}
[{cmd:,}
{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(spec)}}deterministic specification: {opt intercept} (default)
or {opt break}{p_end}
{synopt:{opt br:eak(#)}}break point for {opt break}: a date, a fraction in (0,1),
or {opt unknown}{p_end}
{synopt:{opt maxl:ag(p)}}maximum order of serial correlation to be robust to; default 0{p_end}

{syntab:Unknown-break bootstrap}
{synopt:{opt brep:s(#)}}bootstrap replications for {opt break(unknown)}; default 399{p_end}
{synopt:{opt tr:im(#)}}end trimming fraction for the break search; default 0.15{p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb xtset}. The panel must be balanced (units with any
missing time period are dropped).{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtgunitroot} implements the generalized fixed-T panel unit root test of
{help xtgunitroot##KT2019:Karavias and Tzavalis (2019)}, based on the {it:doubly
modified estimator} (DME). Unlike the simpler fixed-T tests, the DME is robust to

{p 8 8 2}- short-term {bf:serial correlation} of unspecified form (up to order {it:maxlag}),{p_end}
{p 8 8 2}- {bf:heteroscedasticity} and error cross-section heterogeneity,{p_end}
{p 8 8 2}- a common {bf:structural break} at a known or unknown date,{p_end}

{pstd}
while remaining valid for a large number of cross-section units {it:N} and a
small, fixed number of time periods {it:T}, and invariant to the initial condition.

{pstd}
The model is y(i,t) = X(i,t)'pi(i) + zeta(i,t), zeta(i,t) = phi*zeta(i,t-1) +
u(i,t), where u may be serially correlated and heteroscedastic. The test is

{p 8 8 2}H0: phi = 1   (unit root)   vs   H1: phi < 1   (stationary).{p_end}

{pstd}
The within-groups estimator of phi is inconsistent for fixed {it:T}; the DME
applies two bias corrections (a numerator correction and a nonparametric
covariance correction in the spirit of Abowd-Card and Arellano), giving a
statistic that is asymptotically standard normal under H0 (known break) and is
rejected for small (negative) values.

{pstd}
{cmd:xtgunitroot} complements {helpb xtmunitroot} (which handles {it:missing
values} under an i.i.d.-error assumption): use {cmd:xtgunitroot} when the
errors are serially correlated or heteroscedastic and the panel is (made)
balanced; use {helpb xtmunitroot} when the panel has gaps.

{pstd}
{bf:Scope of this version.} Only the {opt intercept} and {opt break} (individual
intercepts, with or without a common break) specifications are available.
Incidental-{opt trend} specifications require the trend-nuisance covariance
machinery and are not yet included; note that fixed-T panel unit root tests have
trivial local power against incidental trends
({help xtgunitroot##MPP2007:Moon, Perron and Phillips 2007}).

{marker options}{...}
{title:Options}

{phang}{opt model(spec)} sets the deterministic component: {opt intercept}
(individual intercepts, default) or {opt break} (individual intercepts with a
common structural break). Abbreviations {cmd:i}, {cmd:b}.

{phang}{opt break(#)} is required for {opt break}. A value in (0,1) is a break
{it:fraction}; any other number is a calendar {it:date}; {opt unknown} searches
all admissible break dates (the inf-t statistic) and obtains the p-value by
bootstrap.

{phang}{opt maxlag(p)} is the maximum order of serial correlation the test is
made robust to (the pmax-dependence bound). With {cmd:maxlag(0)} the errors are
treated as serially uncorrelated. For MA(q)-type dependence set {cmd:maxlag(q)}.
Choosing {it:p} larger than the true order is conservative (safe); too small can
distort size.

{phang}{opt breps(#)}, {opt trim(#)}, {opt seed(#)} control the unknown-break
bootstrap: number of replications, the fraction trimmed from each end of the
break-date search, and the RNG seed for reproducibility.

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtgunitroot} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(phi)}}within-groups estimate of phi{p_end}
{synopt:{cmd:r(phi_dme)}}doubly modified (bias-corrected) estimate of phi{p_end}
{synopt:{cmd:r(bias)}}bias correction b/d{p_end}
{synopt:{cmd:r(z)}}test statistic (inf-t under {opt break(unknown)}){p_end}
{synopt:{cmd:r(p)}}p-value (bootstrap under {opt break(unknown)}){p_end}
{synopt:{cmd:r(N)} / {cmd:r(N_used)} / {cmd:r(N_drop)}}panels total / used / dropped{p_end}
{synopt:{cmd:r(T)}}number of equations{p_end}
{synopt:{cmd:r(maxlag)}}serial-correlation order used{p_end}
{synopt:{cmd:r(kbreak)}}break equation index (break models){p_end}
{synopt:{cmd:r(cv05)} / {cmd:r(reps)}}5% bootstrap critical value / replications (unknown break){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)} {cmd:r(depvar)} {cmd:r(ivar)} {cmd:r(tvar)} {cmd:r(model)}}{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(profile)}}under {opt break(unknown)}: the t(date) profile (kindex, date, tstat){p_end}

{marker examples}{...}
{title:Examples}

{pstd}Balanced panel with serially correlated errors:{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtgunitroot y, maxlag(1)}{p_end}

{pstd}Structural break at a known date, robust to MA(1) errors:{p_end}
{phang2}{cmd:. xtgunitroot y, model(break) break(2008) maxlag(1)}{p_end}

{pstd}Structural break at an unknown date (inf-t with bootstrap p-value):{p_end}
{phang2}{cmd:. xtgunitroot y, model(break) break(unknown) maxlag(1) breps(499) seed(42)}{p_end}

{marker references}{...}
{title:References}

{marker KT2019}{...}
{phang}Karavias, Y., and E. Tzavalis. 2019. Generalized fixed-T panel unit root
tests. {it:Scandinavian Journal of Statistics} 46(4): 1227-1251.
{browse "https://doi.org/10.1111/sjos.12392":doi:10.1111/sjos.12392}.

{marker MPP2007}{...}
{phang}Moon, H. R., B. Perron, and P. C. B. Phillips. 2007. Incidental trends
and the power of panel unit root tests. {it:Journal of Econometrics} 141: 416-459.
{browse "https://doi.org/10.1016/j.jeconom.2006.10.001":doi:10.1016/j.jeconom.2006.10.001}.

{marker author}{...}
{title:Author}

{pstd}Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
