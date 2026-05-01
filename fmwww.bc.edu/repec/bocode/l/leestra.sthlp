{smcl}
{* *! version 1.2.0  29apr2026}{...}
{cmd:help leestra}
{hline}

{title:Title}

{p2colset 5 16 22 2}{...}
{p2col:{cmd:leestra} {hline 2}}Lee-Strazicich unit root tests with one or two structural breaks{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}
{cmd:leestra} {it:varname} {ifin}
[{cmd:,} {it:options}]


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Options}
{synopt:{opt model(string)}}break model: {cmd:crash} (default) or {cmd:break}{p_end}
{synopt:{opt breaks(#)}}number of breaks: {cmd:0}, {cmd:1}, or {cmd:2}; default is {cmd:1}{p_end}
{synopt:{opt lags(#)}}number of lagged differences; default is {cmd:0} for {cmd:method(fixed)} and floor(4*(T/100)^0.25) (at least 1) for {cmd:method(gtos)} and {cmd:method(bg)}{p_end}
{synopt:{opt method(method)}}lag selection: {cmd:fixed}, {cmd:gtos} (default), or {cmd:bg}{p_end}
{synopt:{opt slstay(#)}}significance level to retain a lag in GTOS; default is {cmd:0.10}{p_end}
{synopt:{opt signif(#)}}alias for {opt slstay()}; takes precedence if specified{p_end}
{synopt:{opt bglags(#)}}BG horizon (number of lags tested for autocorrelation) under {cmd:method(bg)}; default depends on data frequency{p_end}
{synopt:{opt pi(#)}}trimming fraction at each end and minimum gap between breaks; default is {cmd:0.10}{p_end}
{synopt:{opt thin(#)}}grid spacing for break search; default is {cmd:1}{p_end}
{synopt:{opt title(string)}}custom report title{p_end}
{synopt:{opt nopr:int}}suppress the result table{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:leestra} performs the Lee-Strazicich minimum LM unit-root test on a time series. The test allows
for up to two endogenously determined structural breaks under both the null and alternative
hypotheses, in contrast to tests in the Perron tradition which assume no break under the null. There
are three cases depending on the number of breaks:

{phang2}
{cmd:breaks(0)} - the Schmidt and Phillips (1992) LM unit-root test (no break).{p_end}
{phang2}
{cmd:breaks(1)} - the Lee and Strazicich (2013) one-break LM test.{p_end}
{phang2}
{cmd:breaks(2)} - the Lee and Strazicich (2003) two-break LM test.{p_end}

{pstd}
Two break models are supported. {cmd:model(crash)} (Model A) allows abrupt changes in the level only,
while {cmd:model(break)} (Model C) allows simultaneous changes in level and trend.

{pstd}
The break dates are estimated by grid search over all admissible combinations: the first and last
{cmd:pi()} fraction of the regression range are excluded as candidate break dates, and consecutive
breaks must be at least {cmd:pi()*T} observations apart. For each combination, the test regression
is estimated and the LM t-statistic on the lagged level is computed. The reported test statistic is
the minimum t-statistic across all admissible break configurations.

{pstd}
The data must be declared as time series using {help tsset} before calling {cmd:leestra}.

{pstd}
{ul:Note on gaps in the time index.}
{cmd:leestra} works on the observation order of the touse-filtered sample: consecutive rows
are treated as one period apart, irrespective of the calendar values of the time variable.
If {cmd:tsset} reports gaps, {cmd:leestra} prints a warning and proceeds. This is appropriate
when the gaps are an artifact of the time variable's encoding (for example, weekly data
imported with mis-spaced dates), but may be misleading if the data is genuinely irregularly
sampled. Verify the data layout in such cases.

{pstd}
{cmd:leestra} is a Stata implementation of the @LSUnit procedure for RATS (Tom Doan, Estima);
the algorithm, critical-value tables, and numerical results match the original.

{pstd}
In addition to the standard lag-selection rules, {cmd:leestra} extends the procedure by a
Breusch-Godfrey based option ({cmd:method(bg)}) that selects the smallest lag length at
which residual autocorrelation is no longer detected.


{title:Test procedure}

{pstd}
{ul:Auxiliary regression}

{pstd}
The Lee-Strazicich LM test is based on the following two-step regression. In the first step,
deterministic terms (a constant and the contemporaneous break dummies, if any) are removed from
the first differences of the series. In the second step, the partial sums of these residuals
{it:S(t)} are regressed on their own lag, the deterministic terms in levels, and {it:k} lagged
differences {it:dS(t-i)}:

{p 8 8 2}
dy(t) = c0 + (sum over breaks i) phi_i*D_i(t) + u(t){p_end}
{p 8 8 2}
S(t) = S(t-1) + u_hat(t),  with S(0) = 0{p_end}
{p 8 8 2}
dy(t) = alpha*S(t-1) + c1 + (sum over breaks i) [phi_i*D_i(t) + (model 2 only) psi_i*DT_i(t)] +
        (sum from j=1 to k) c_j*dS(t-j) + e(t){p_end}

{pstd}
where {it:D_i(t) = 1[t = T_b,i + 1]} is a one-period dummy at the date following the break, and
{it:DT_i(t) = 1[t >= T_b,i + 1]} is a step dummy active from one period after the break onward (used
only when {cmd:model(break)} is specified). The null hypothesis of a unit root corresponds to
{it:H0: alpha = 0}. The reported test statistic is the t-statistic on {it:alpha}.

{pstd}
{ul:Break search}

{pstd}
For each admissible combination of break dates the auxiliary regression is estimated and its
t-statistic on {it:alpha} is recorded. The reported break dates are those that minimise the
t-statistic. With two breaks and {cmd:thin(1)} (the default) on a sample of about 60 observations,
roughly a thousand combinations are evaluated; on larger samples consider increasing {cmd:thin()}.

{pstd}
{ul:Critical values}

{pstd}
Critical values draw on the simulations of Lee and Strazicich (2003, 2013) and Schmidt and
Phillips (1992). Tables are tabulated for sample sizes T = 100, 250, 500 and 1000. Values are
linearly interpolated in T and, for {cmd:model(break)} with one break, in the relative break
location lambda; for two breaks the closest tabulated combination is used.


{title:Options}

{phang}
{opt model(string)} specifies the type of structural break.
{cmd:crash} (Model A) allows an abrupt level shift only;
{cmd:break} (Model C) allows simultaneous shifts in the level and the trend slope.
{cmd:crash} is the default.

{phang}
{opt breaks(#)} specifies the number of breaks. Must be {cmd:0}, {cmd:1}, or {cmd:2}; critical
values are not tabulated for more than two breaks and the command will return an error if a
larger value is supplied. Default is {cmd:breaks(1)}.

{phang}
{opt lags(#)} specifies the number of lagged differences in the auxiliary regression.
With {cmd:method(fixed)} this value is always used; with {cmd:method(gtos)} or
{cmd:method(bg)} it is the maximum from which lags are pruned. If unspecified, the
default is {cmd:0} for {cmd:method(fixed)}, and floor(4*(T/100)^0.25) (at least 1)
for {cmd:method(gtos)} and {cmd:method(bg)} so that the data-driven methods have a
non-trivial maximum from which to prune.

{phang}
{opt method(method)} specifies the lag-selection method. {cmd:fixed} keeps {cmd:lags()} lags in
all regressions; {cmd:gtos} (general-to-specific) starts from the maximum and drops the highest
lag whenever its t-statistic falls below the critical value at the {cmd:slstay()} level;
{cmd:bg} (Breusch-Godfrey) selects the smallest lag count for which the residuals of the
auxiliary regression show no serial correlation up to {cmd:bglags()} (BG p-value at every lag
order from 1 to {cmd:bglags()} exceeds 0.05). {cmd:gtos} is the default, matching the original
Lee-Strazicich procedure. The BG selection is performed at every break combination, so the
chosen lag may differ across candidate break points and the reported {it:bestlag} corresponds
to the configuration that minimises the test statistic.

{phang}
{opt slstay(#)} sets the two-sided t-test significance level for retaining a lag under
{cmd:method(gtos)}. Default is {cmd:0.10}.

{phang}
{opt signif(#)} is an alias for {cmd:slstay()}. If both are specified, {cmd:signif()} takes
precedence.

{phang}
{opt bglags(#)} is the BG horizon for {cmd:method(bg)}: at each candidate lag length the
Breusch-Godfrey LM test is computed at every lag order from 1 to {cmd:bglags()}, and the
minimum p-value is used to decide whether residual autocorrelation is present. Default depends
on the data frequency: 2 for annual, 4 for half-yearly, 8 for quarterly, 24 for monthly,
52 for weekly, 100 for daily.

{phang}
{opt pi(#)} sets the fraction of the regression range excluded as break candidates at each end
of the sample, and the minimum spacing between consecutive breaks. Must lie strictly in (0, 0.5).
Default is {cmd:0.10}.

{phang}
{opt thin(#)} sets the grid step for the break search. The default value 1 examines every
admissible point. For two-break models on large samples, {cmd:thin(5)} or higher reduces runtime
significantly at the cost of a coarser grid.

{phang}
{opt title(string)} overrides the default report title.

{phang}
{opt noprint} suppresses the on-screen result table. Stored results are still produced.


{title:Remarks}

{pstd}
{ul:Choosing the model}

{pstd}
{cmd:model(break)} (Model C) is the most general specification and is recommended when there is
uncertainty about the nature of the breaks. {cmd:model(crash)} (Model A) is appropriate when
breaks affect only the level of the series, for example a one-time policy intervention or a
currency depreciation. Using a more general model than necessary reduces the power of the test.

{pstd}
{ul:Choosing the number of breaks}

{pstd}
The maximum number of breaks should reflect prior economic knowledge about the series. Critical
values are only tabulated for up to two breaks; for series where more than two structural breaks
are plausible, alternative tests such as Kapetanios (2005) (see {help kapetanios:kapetanios}, if
installed) or Carrion-i-Silvestre, Kim and Perron (2009) should be considered.

{pstd}
{ul:Lag selection}

{pstd}
The {cmd:method(gtos)} approach is the original Lee-Strazicich procedure: it eliminates lags
from the highest down whenever their t-statistic is insignificant. The {cmd:method(fixed)}
alternative keeps all {cmd:lags()} lags in the regression and is useful for replication or when
a specific lag length is dictated by theory or by an information criterion computed beforehand.

{pstd}
{cmd:method(bg)} - General-to-specific (GTS) selection based on the Breusch-Godfrey LM test
for serial correlation. Starting from {cmd:lags()} downward, the BG test is applied to the
residuals of the auxiliary regression at lag orders 1 through {cmd:bglags()}. If
autocorrelation is detected at any of these lag orders (p < 0.05), the procedure retains the
previous lag length. This method directly targets the elimination of serial correlation,
which is the primary purpose of including lagged differences in the test regression. Because
each candidate break configuration in the Lee-Strazicich grid search yields a different
auxiliary regression, the BG selection is repeated at every break combination, and the chosen
lag may differ across candidate break dates. In addition to the standard lag-selection rules,
{cmd:leestra} extends the procedure by this Breusch-Godfrey based option that selects the
smallest lag length at which residual autocorrelation is no longer detected.

{pstd}
{ul:Sample-size considerations}

{pstd}
Critical values are tabulated for T = 100, 250, 500 and 1000. For samples below T = 100,
finite-sample distortions can be substantial; results should be interpreted with caution. For
samples between two tabulated values, critical values are linearly interpolated in T.


{title:Stored results}

{pstd}
{cmd:leestra} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(tstat)}}LM unit-root test statistic (minimum t){p_end}
{synopt:{cmd:r(nobs)}}observations in the auxiliary regression{p_end}
{synopt:{cmd:r(bestlag)}}selected lag length{p_end}
{synopt:{cmd:r(ndf)}}degrees of freedom{p_end}
{synopt:{cmd:r(breaks)}}number of breaks{p_end}
{synopt:{cmd:r(model)}}1 for crash, 2 for break{p_end}
{synopt:{cmd:r(lambda1)}}relative position of the first break{p_end}
{synopt:{cmd:r(lambda2)}}relative position of the second break{p_end}
{synopt:{cmd:r(ncomb)}}number of break combinations evaluated{p_end}
{synopt:{cmd:r(bg_chi2)}}Breusch-Godfrey AR(1) test statistic (only for {cmd:method(bg)}){p_end}
{synopt:{cmd:r(bg_p)}}Breusch-Godfrey AR(1) p-value (only for {cmd:method(bg)}){p_end}
{synopt:{cmd:r(bg_minp)}}minimum BG p-value across orders 1..{cmd:bglags()} (only for {cmd:method(bg)}){p_end}
{synopt:{cmd:r(bg_warn)}}1 if autocorrelation could not be eliminated at {cmd:lags()} (only for {cmd:method(bg)}){p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(beta)}}coefficients (S(t-1), constant, break dummies){p_end}
{synopt:{cmd:r(tstats)}}t-statistics for the coefficients{p_end}
{synopt:{cmd:r(bps)}}selected break positions (relative observation numbers){p_end}
{synopt:{cmd:r(cv)}}1%, 5%, 10% critical values{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(varname)}}name of the tested series{p_end}


{title:Examples}

{pstd}
The examples below use the classic Nelson-Plosser dataset. For each example, the equivalent
@LSUnit call in WinRATS is given immediately after the Stata command for direct comparison.

{pstd}
{ul:Setup} {p_end}

        {hline 65}

{pstd}
{it:Stata}

{phang2}{cmd:. use "https://www.eruygurakademi.com/datasets/nelsonplosser.dta", clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. gen lrgnp   = log(realgnp)}{p_end}
{phang2}{cmd:. gen logwage = 100 * log(realwages)}{p_end}
{phang2}{cmd:. gen lcpi    = log(cpi)}{p_end}
{phang2}{cmd:. gen lstock  = log(stockprice)}{p_end}

{pstd}
{it:WinRATS}

{phang2}{cmd:cal(a) 1860}{p_end}
{phang2}{cmd:allocate 1970:1}{p_end}
{phang2}{cmd:open data nelsonplosser.rat}{p_end}
{phang2}{cmd:data(format=rats) 1860:1 1970:1}{p_end}
{phang2}{cmd:source lsunit.src}{p_end}
{phang2}{cmd:set lrgnp   1909:1 1970:1 = log(realgnp)}{p_end}
{phang2}{cmd:set logwage 1900:1 1970:1 = 100*log(realwages)}{p_end}
{phang2}{cmd:set lcpi    1860:1 1970:1 = log(cpi)}{p_end}
{phang2}{cmd:set lstock  1871:1 1970:1 = log(stockprice)}{p_end}

        {hline 65}

{pstd}
{ul:Note on running the WinRATS examples.}
The @LSUnit procedure determines the regression range automatically from the input series.
When several commands are submitted in succession in the same RATS session, the determined range
may occasionally carry over from a previous call. If the resulting "Regression Run From ... to ..."
line shows an unexpected range, run the command in a fresh session, or provide the start and end
dates explicitly, e.g. {cmd:@lsunit(...) lrgnp 1909:1 1970:1}.

{pstd}
{ul:Example 1.} Real GNP, crash model, one break, fixed lags = 4.

{pstd}
{it:Stata}

{phang2}{cmd:. leestra lrgnp, model(crash) breaks(1) lags(4) method(fixed)}{p_end}

{pstd}
{it:WinRATS}

{phang2}{cmd:@lsunit(model=crash,breaks=1,lags=4,method=fixed) lrgnp}{p_end}

{pstd}
{ul:Example 2.} Real GNP, break model, two breaks, GTOS lag selection up to 4.

{pstd}
{it:Stata}

{phang2}{cmd:. leestra lrgnp, model(break) breaks(2) lags(4)}{p_end}

{pstd}
{it:WinRATS}

{phang2}{cmd:@lsunit(model=break,breaks=2,lags=4,method=gtos) lrgnp}{p_end}

{pstd}
{ul:Example 3.} Real GNP, no break (Schmidt-Phillips test), fixed lags = 4.

{pstd}
{it:Stata}

{phang2}{cmd:. leestra lrgnp, breaks(0) lags(4) method(fixed)}{p_end}

{pstd}
{it:WinRATS}

{phang2}{cmd:@lsunit(breaks=0,lags=4,method=fixed) lrgnp}{p_end}

{pstd}
{ul:Example 4.} 100*log(real wages), break model, one break, GTOS up to 8.

{pstd}
{it:Stata}

{phang2}{cmd:. leestra logwage, model(break) breaks(1) lags(8)}{p_end}

{pstd}
{it:WinRATS}

{phang2}{cmd:@lsunit(model=break,breaks=1,lags=8,method=gtos) logwage}{p_end}

{pstd}
{ul:Example 5.} log(CPI), crash model, two breaks, fixed lags = 2.

{pstd}
{it:Stata}

{phang2}{cmd:. leestra lcpi, model(crash) breaks(2) lags(2) method(fixed)}{p_end}

{pstd}
{it:WinRATS}

{phang2}{cmd:@lsunit(model=crash,breaks=2,lags=2,method=fixed) lcpi}{p_end}

{pstd}
{ul:Example 6.} log(stock prices), break model, one break, GTOS up to 6, slstay = 0.05.

{pstd}
{it:Stata}

{phang2}{cmd:. leestra lstock, model(break) breaks(1) lags(6) slstay(0.05)}{p_end}

{pstd}
{it:WinRATS}

{phang2}{cmd:@lsunit(model=break,breaks=1,lags=6,method=gtos,slstay=0.05) lstock}{p_end}

{pstd}
{ul:Example 7.} Real GNP, break model, one break, BG-based lag selection up to 4.
This option is provided in {cmd:leestra} as an extension and has no direct WinRATS counterpart.

{pstd}
{it:Stata}

{phang2}{cmd:. leestra lrgnp, model(break) breaks(1) lags(4) method(bg)}{p_end}


{pstd}
{ul:Examples using Gretl sample datasets}

{pstd}
The following examples use datasets from the Gretl sample file collection, hosted at
{browse "https://www.eruygurakademi.com/datasets/kapetanios/"}. They are tsset and ready
for use.

{pstd}
{ul:Example 8.} Annual data (T=43): Interest rates and inflation, Canada.

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/kapetanios/jgm-data.dta, clear}{p_end}
{phang2}{cmd:. leestra r_s, model(break) breaks(2)}{p_end}

{pstd}
With default {cmd:method(gtos)}, autocorrelation may remain at zero lags. Switching to
{cmd:method(bg)} addresses this directly:

{phang2}{cmd:. leestra r_s, model(break) breaks(2) method(bg)}{p_end}

{pstd}
The output prints a warning if autocorrelation persists at the maximum lag tried:

{phang2}{it:Warning: Autocorrelation could not be eliminated with lags = 0. BG selected the maximum lag (0). Try lags(1) or higher.}{p_end}

{pstd}
A larger {cmd:lags()} can be specified explicitly. If too large, {cmd:leestra} reports the
maximum feasible value:

{phang2}{cmd:. leestra r_s, model(break) breaks(2) method(bg) lags(18)}{p_end}
{phang2}{it:lags(18) is too large for the available sample (T = 43). Try lags(15) or smaller.}{p_end}

{phang2}{cmd:. leestra r_s, model(break) breaks(2) method(bg) lags(15)}{p_end}
{phang2}{cmd:. leestra r_s, model(break) breaks(2) method(bg) lags(12)}{p_end}

{pstd}
{ul:Example 9.} Quarterly data (T=258): MIDAS data, quarterly GDP and monthly covariates.

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/kapetanios/gdp_midas.dta, clear}{p_end}
{phang2}{cmd:. leestra qgdp, breaks(2) model(break) method(bg) thin(10)}{p_end}
{phang2}{cmd:. leestra d.qgdp, breaks(2) model(break) method(bg) thin(10)}{p_end}
{phang2}{cmd:. leestra d2.qgdp, breaks(2) model(break) method(bg) thin(10)}{p_end}

{pstd}
{it:Note:} {cmd:thin(10)} is used here to speed up the example. More accurate
results are obtained with no thin (default {cmd:thin(1)}) or with smaller
values such as {cmd:thin(5)}, at the cost of longer runtimes.

{pstd}
{ul:Example 10.} Monthly data (T=144): Box and Jenkins Series G (airline passengers).

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/kapetanios/bjg.dta, clear}{p_end}
{phang2}{cmd:. leestra lg, breaks(2) model(break) method(bg) thin(10)}{p_end}

{pstd}
{it:Note:} {cmd:thin(10)} is used here to speed up the example. More accurate
results are obtained with no thin (default {cmd:thin(1)}) or with smaller
values such as {cmd:thin(5)}, at the cost of longer runtimes.

{pstd}
{ul:Example 11.} Weekly data (T=2117): Weekly NYSE closing price, 1966-2006.
Due to the large sample size, estimation may take approximately 2-3 minutes.

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/nysewk2.dta, clear}{p_end}
{phang2}{cmd:. leestra close, breaks(2) thin(10)}{p_end}

{pstd}
{it:Note:} {cmd:thin(10)} is used here to speed up the example. More accurate
results are obtained with no thin (default {cmd:thin(1)}) or with smaller
values such as {cmd:thin(5)}, at the cost of longer runtimes.

{pstd}
{ul:Example 12.} Daily data (T=1974): Bollerslev and Ghysels exchange rate data.
Due to the large sample size, estimation may take approximately 2-3 minutes.

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/kapetanios/b-g.dta, clear}{p_end}
{phang2}{cmd:. leestra Y, breaks(2) thin(10)}{p_end}

{pstd}
{it:Note:} {cmd:thin(10)} is used here to speed up the example. More accurate
results are obtained with no thin (default {cmd:thin(1)}) or with smaller
values such as {cmd:thin(5)}, at the cost of longer runtimes.


{pstd}
{ul:Accessing stored results}

{phang2}{cmd:. leestra lrgnp, model(break) breaks(1) lags(4)}{p_end}
{phang2}{cmd:. display r(tstat)}{p_end}
{phang2}{cmd:. matrix list r(bps)}{p_end}
{phang2}{cmd:. matrix list r(cv)}{p_end}


{title:References}

{phang}
Lee, J. and M. C. Strazicich. 2003. Minimum LM unit-root test with two structural breaks.
{it:Review of Economics and Statistics} 85(4): 1082-1089.

{phang}
Lee, J. and M. C. Strazicich. 2013. Minimum LM unit-root test with one structural break.
{it:Economics Bulletin} 33(4): 2483-2492.

{phang}
Schmidt, P. and P. C. B. Phillips. 1992. LM tests for a unit root in the presence of
deterministic trends. {it:Oxford Bulletin of Economics and Statistics} 54(3): 257-287.

{phang}
Doan, T. 2017. @LSUnit: Lee-Strazicich unit-root test (RATS procedure).
Estima, Evanston, IL. Available from {browse "http://www.estima.com"}.


{title:Author}

{pstd}
        H. Ozan Eruygur{break}
        AHBV University, Ankara, Turkiye.{break}
        Department of Economics{break}
        {browse "https://www.ozaneruygur.com"}{break}
        eruygur@gmail.com

{pstd}
        Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.{break}
        {browse "https://www.eruygurakademi.com"}{break}
        eruygurakademi@gmail.com

{pstd}
        leestra v1.2.0 - April 2026

{pstd}
Please cite as:

{pstd}
Eruygur, H. O. 2026. leestra: Lee-Strazicich unit root tests with one or two structural breaks.
Stata package version 1.2.0. Available from: {browse "https://www.eruygurakademi.com"}
