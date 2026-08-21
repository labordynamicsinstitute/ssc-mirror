{smcl}
{* *! version 1.5.9  06aug2026  Ozan Eruygur}{...}
{viewerjumpto "Syntax" "lumpapell##syntax"}{...}
{viewerjumpto "Description" "lumpapell##description"}{...}
{viewerjumpto "Options" "lumpapell##options"}{...}
{viewerjumpto "Examples" "lumpapell##examples"}{...}
{viewerjumpto "Stored results" "lumpapell##results"}{...}
{viewerjumpto "References" "lumpapell##references"}{...}
{viewerjumpto "Author" "lumpapell##author"}{...}
{title:Title}

{phang}
{bf:lumpapell} {hline 2} Lumsdaine-Papell unit root test allowing for two unknown breaks


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:lumpapell} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt br:eak(type)}}break specification: {cmd:intercept} (default), {cmd:trend}, {cmd:both}, or {cmd:ca}{p_end}
{synopt:{opt m:ethod(type)}}lag selection: {cmd:input} (default), {cmd:aic}, {cmd:bic}, {cmd:hq}, or {cmd:ttest}{p_end}
{synopt:{opt l:ags(#)}}number of augmenting lags with {cmd:method(input)}, or the maximum to consider otherwise{p_end}
{synopt:{opt maxl:ags(#)}}same role as {opt lags()}; {opt lags()} takes precedence if both are given{p_end}
{synopt:{opt sig:nif(#)}}cutoff significance level for {cmd:method(ttest)}; default is {cmd:signif(0.10)}{p_end}
{synopt:{opt pi(#)}}trimming fraction and minimum gap between breaks; default is {cmd:pi(0.15)}{p_end}
{synopt:{opt cv(source)}}critical values: {cmd:rats} (default) or {cmd:paper}{p_end}
{synopt:{opt tc:rit(#)}}fixed cutoff for the last-lag |t| in {cmd:method(ttest)}{p_end}
{synopt:{opt paper}}article mode: grid, per-combination lag selection, and critical values of Lumsdaine and Papell (1997){p_end}
{synopt:{opt g:raph}}graph the series with vertical lines at the estimated break dates{p_end}
{synopt:{opt nopr:int}}suppress the report{p_end}
{synopt:{opt t:itle(string)}}title for the report{p_end}
{synoptline}
{p 4 6 2}
The data must be {cmd:tsset} as a single time series without gaps in the estimation window;
panel data are not allowed.


{marker description}{...}
{title:Description}

{pstd}
{cmd:lumpapell} implements the unit root test of Lumsdaine and Papell (1997), which extends
the endogenous single-break methodology of Zivot and Andrews (1992) to an alternative
hypothesis with two structural breaks at unknown dates. Four break specifications are
available; the first three are named as in the article. Model AA lets both breaks shift
the intercept:

{p 8 8 2}
dy(t) = mu + beta*t + theta1*DU1(t) + theta2*DU2(t) + alpha*y(t-1) + c(1)*dy(t-1) + ... + c(k)*dy(t-k) + e(t)

{pstd}
Model CC lets each break shift both the intercept and the slope:

{p 8 8 2}
dy(t) = mu + beta*t + theta1*DU1(t) + gamma1*DT1(t) + theta2*DU2(t) + gamma2*DT2(t) + alpha*y(t-1) + c(1)*dy(t-1) + ... + c(k)*dy(t-k) + e(t)

{pstd}
Model CA is the mixed case: the first break shifts the intercept and the slope, the
second shifts the intercept only:

{p 8 8 2}
dy(t) = mu + beta*t + theta1*DU1(t) + gamma1*DT1(t) + theta2*DU2(t) + alpha*y(t-1) + c(1)*dy(t-1) + ... + c(k)*dy(t-k) + e(t)

{pstd}
Finally, the {cmd:break(trend)} specification, which the article does not consider, lets
each break shift the slope only:

{p 8 8 2}
dy(t) = mu + beta*t + gamma1*DT1(t) + gamma2*DT2(t) + alpha*y(t-1) + c(1)*dy(t-1) + ... + c(k)*dy(t-k) + e(t)

{pstd}
where, for a break date TB, the intercept shift dummy is DU(t) = 1 if t > TB and the trend
shift dummy is DT(t) = (t - TB) if t > TB and 0 otherwise. A reported break date TB is thus
the last period of the old regime; the shift takes effect in the period after TB (in the
article's application, TB = 1929 for the Great Crash means the level shift begins in 1930).
The null hypothesis is a unit root, alpha = 0, with no breaks; as the article notes, breaks
are permitted under the alternative only. The break dates are chosen by estimating the
regression at every admissible combination of break dates and minimizing the t statistic on
alpha; the reported test statistic is that minimized t statistic.

{pstd}
With zero breaks the test is the standard augmented Dickey-Fuller test, and with one
break it is the Zivot-Andrews (1992) test; the zero- and one-break cases are therefore
not offered separately in the command syntax. The Lumsdaine-Papell test of the article
is the two-break case, and {cmd:lumpapell} implements exactly that.

{pstd}
{bf:What the command does, step by step.}

{phang}
{bf:Step 1, sample and model.} The usable range of the series and its first lag is
determined and the first difference dy is built. The estimated regression is equation (1)
of Lumsdaine and Papell (1997): dy(t) on y(t-1), the break dummies, a constant, a linear
trend, and k lagged differences. {opt break()} chooses the model: AA, CA, or CC in the
article's notation.
Following footnote 2 of the article, no breaks are permitted under the unit-root null;
they enter only under the alternative.

{phang}
{bf:Step 2, maximum lag.} The upper bound kmax is taken from {opt lags()} or
{opt maxlags()}; if neither is given it is trunc(T^0.25). The
article fixes kmax = 8 for every series and, following footnote 8, does not raise the
bound when the selected lag equals it; this implementation behaves the same way.

{phang}
{bf:Step 3, candidate break dates.} By default candidates are at
least trunc(pi*T') observations from the sample ends and from each other, with T' the
usable length. In the article mode the article's grid is built instead: candidate dates
run from the second observation of the series to the next-to-last one, matching the
article's search over break fractions from 2/T to (T-1)/T, and the only separation
requirement is that the two dates not be consecutive. For model CA the pairs are
enumerated in both time orders, since the article's table 4 reports TB1 after TB2 for
several series.

{phang}
{bf:Step 4, lag selection.} By default the number of lags is selected once, on the base
model without break dummies, over the fixed sample that kmax allows. In the article mode
the selection is repeated for every candidate
break combination with the break dummies included, following the practice of Zivot and
Andrews (1992): starting at kmax, the general-to-specific rule of Perron (1989) keeps the
first k whose last included lag satisfies |t| >= 1.60 (the article's cutoff, adjustable
via {opt tcrit()}), and sets k = 0 if none does. The k columns of the article's tables 2
to 4 differ across models for the same series, which identifies the selection as
per-combination.

{phang}
{bf:Step 5, estimation and minimization.} At every admissible break combination the
regression is estimated with the selected k and the t statistic on y(t-1) is recorded.
The test statistic is the minimum of these t statistics over the whole grid, and the
estimated break dates are the minimizers; ties keep the first combination encountered.
Combinations whose regressors are collinear on the available sample are inadmissible and
skipped.

{phang}
{bf:Step 6, inference.} The minimized t statistic is compared with the critical values:
the default table, or with {cmd:cv(paper)} the article's finite-sample values,
simulated under the null with T = 125, 500 replications, and endogenous lag selection,
including the 2.5 percent level. One star marks rejection at the 5 percent level, two
stars at the 1 percent level.

{phang}
{bf:Step 7, report, dummies, and stored results.} The default report shows the settings,
the test statistic against the critical values with a rejection verdict per level, the
break dates with their observation numbers, and the break regression. In addition the
command writes the break dummies, the trend variable, and nothing else to the dataset
under the {cmd:lumpapell_} prefix ({cmd:lumpapell_du1}, {cmd:lumpapell_dt1}, ..., and
{cmd:lumpapell_trend}), and prints below the regression a plain {cmd:regress} command
that reproduces the break regression from those variables; the same command string is
stored in {cmd:r(regcmd)}. Every reported quantity is stored in {cmd:r()} as listed
below.


{marker options}{...}
{title:Options}

{phang}
{opt break(type)} selects which deterministic components break at the two break dates, and
thereby the model in the nomenclature of the article. {cmd:break(intercept)} is model AA,
both breaks in the intercept only. {cmd:break(both)} is model CC, both breaks in the
intercept and the slope. {cmd:break(ca)} is the mixed model CA: the first
break date shifts the intercept and the slope, the second shifts the intercept only. Model CA
requires the {cmd:paper} option; the two dates of model CA are not restricted to be in chronological order, and the
reported TB1 is the intercept-and-slope break wherever it falls in time, as in table 4 of
the article. {cmd:break(trend)} is a trend-only specification the article does not consider. The default is {cmd:intercept}.

{phang}
{opt method(type)} selects how the number of augmenting lags k is determined. With
{cmd:input} (the default) the number given by {opt lags()} or {opt maxlags()} is used as
is. With {cmd:aic}, {cmd:bic}, or {cmd:hq} the criterion-minimizing lag between 0 and the
maximum is chosen. With {cmd:ttest} (general-to-specific) the
procedure of Perron (1989) followed by the article is used: start at the maximum lag and
prune downward until the last included lag is significant; if no lag is significant, k = 0.
By default the significance of the last lag is judged by its exact two-sided Student t
p-value against {opt signif()}; the article instead used the
approximate 10 percent value of the asymptotic normal distribution, 1.60, as the cutoff,
which is available through {opt tcrit()} and is the default in the article mode.

{phang}
{opt lags(#)} and {opt maxlags(#)} give the number of lags ({cmd:method(input)}) or the
maximum number of lags to consider (other methods). If neither is given, the maximum is
trunc(T^0.25), with T the number of usable observations of the series and one lag. The
article sets the maximum to 8 and, following Perron (1989) and Zivot and Andrews (1992),
does not increase the upper bound when the selected lag equals the maximum; this
implementation behaves the same way.

{phang}
{opt signif(#)} is the two-sided significance cutoff for {cmd:method(ttest)}. The default
is 0.10, the level used in the article. It is ignored when {opt tcrit()} is active.

{phang}
{opt pi(#)} sets the fraction of the sample excluded at each end as break candidates and
the minimum gap between breaks, converted to an observation count by truncation. The
default is 0.15. This option has no effect on the grid in the article mode.

{phang}
{opt cv(source)} chooses the critical value table. {cmd:rats} (the default without
{cmd:paper}) uses the critical value table of the procedure lpunit.src. {cmd:paper} uses
the finite-sample critical values of Lumsdaine and Papell (1997), simulated under the
null with 125 observations, 500 replications, and endogenous lag selection, and including
the 2.5 percent level; these are available for {cmd:break(intercept)}, {cmd:break(ca)},
and {cmd:break(both)}. The {cmd:paper} option sets {cmd:cv(paper)} by default. There are
no {cmd:cv(rats)} values for model CA, so {cmd:break(ca)} always uses {cmd:cv(paper)}.

{phang}
{opt tcrit(#)} makes {cmd:method(ttest)} keep the first lag length
whose last included lag satisfies |t| >= {it:#}, instead of applying the p-value cutoff of
{opt signif()}. The article uses 1.60, following Perron (1989); the {cmd:paper} option
therefore sets {cmd:tcrit(1.60)} by default when {cmd:method(ttest)} is chosen.

{phang}
{opt paper} switches on the article mode of Lumsdaine and Papell (1997): the article's
break grid, per-combination lag selection with the 1.60 cutoff, the article's
finite-sample critical values, and model CA. The default behavior is completely unchanged
when this option is not given.

{phang}
{opt graph} draws a time-series plot of the series with vertical lines at the estimated
break dates. The graph is produced even under {opt noprint}.

{phang}
{opt noprint} suppresses the report; all results remain available in {cmd:r()}.

{phang}
{opt title(string)} replaces the default report title.


{marker examples}{...}
{title:Examples}

{pstd}
The examples below use the quarterly Canadian data and, for the article mode, the extended
Nelson-Plosser annual data as distributed in the R package urca, truncated at 1970 so that
every series ends where the article's samples end.

{pstd}Setup{p_end}
{phang2}{cmd:. use https://eruygurakademi.com/datasets/lumpapell/Canada.dta, clear}{p_end}

{pstd}Two breaks in the intercept (model AA form), fixed lag length of 2{p_end}
{phang2}{cmd:. lumpapell prod, lags(2)}{p_end}

{pstd}Model CC form: two breaks in intercept and trend, lags chosen by AIC from at most 8{p_end}
{phang2}{cmd:. lumpapell prod, break(both) method(aic) maxlags(8)}{p_end}

{pstd}Breaks in the slope only{p_end}
{phang2}{cmd:. lumpapell prod, break(trend) method(bic) maxlags(8)}{p_end}

{pstd}Model AA with ttest lag selection{p_end}
{phang2}{cmd:. lumpapell prod, break(intercept) method(ttest) maxlags(8) signif(0.10)}{p_end}

{pstd}Hannan-Quinn lag selection, and a stricter pruning level{p_end}
{phang2}{cmd:. lumpapell prod, break(both) method(hq) maxlags(8)}{p_end}
{phang2}{cmd:. lumpapell prod, break(both) method(ttest) maxlags(8) signif(0.05)}{p_end}

{pstd}Wider break grid through a smaller trimming fraction{p_end}
{phang2}{cmd:. lumpapell prod, break(both) method(aic) maxlags(8) pi(0.10)}{p_end}

{pstd}Restricting the estimation range and skipping observations{p_end}
{phang2}{cmd:. lumpapell prod in 5/80, break(both) method(aic) maxlags(8)}{p_end}
{phang2}{cmd:. lumpapell prod if qdate<=tq(1998q4), break(both) method(aic) maxlags(8)}{p_end}

{pstd}Graph and a custom title{p_end}
{phang2}{cmd:. lumpapell prod, break(both) method(aic) maxlags(8) graph title("Canadian productivity")}{p_end}

{pstd}Suppressing the report and reading the stored results{p_end}
{phang2}{cmd:. lumpapell prod, break(both) method(aic) maxlags(8) noprint}{p_end}
{phang2}{cmd:. display %12.6f r(cdstat)}{p_end}
{phang2}{cmd:. display %tq r(break1)}{p_end}
{phang2}{cmd:. display %tq r(break2)}{p_end}

{pstd}
{ul:Article mode.} The following commands run the three specifications of Lumsdaine and
Papell (1997) for real GNP on the Nelson-Plosser data: model AA (table 2), model CC
(table 3), and model CA (table 4).

{phang2}{cmd:. use https://eruygurakademi.com/datasets/lumpapell/np.dta, clear}{p_end}
{phang2}{cmd:. lumpapell realgnp, break(intercept) method(ttest) maxlags(8) paper}{p_end}
{phang2}{cmd:. lumpapell realgnp, break(both) method(ttest) maxlags(8) paper}{p_end}
{phang2}{cmd:. lumpapell realgnp, break(ca) method(ttest) maxlags(8) paper}{p_end}

{pstd}Article mode combined with {cmd:cv(rats)}{p_end}
{phang2}{cmd:. lumpapell realgnp, break(intercept) method(ttest) maxlags(8) paper cv(rats)}{p_end}


{pstd}
{ul:Replication with WinRATS.} The default mode of {cmd:lumpapell} is a port of the RATS
procedure lpunit.src, option for option, and the two programs print identical results. In
the WinRATS output the lumpapell test statistic is the t statistic printed on the Y{c -(}1{c )-}
row, that is, the coefficient on y(-1); the default report of {cmd:lumpapell} prints the
same number on the t(alpha) line.

{pstd}
To run the WinRATS side, create a folder {cmd:c:\lumpapell_test} and download the
following two files into it:

{phang2}{browse "https://eruygurakademi.com/datasets/lumpapell/canada_prod.txt":https://eruygurakademi.com/datasets/lumpapell/canada_prod.txt}{p_end}
{phang2}{browse "https://eruygurakademi.com/datasets/lumpapell/lpunit.src":https://eruygurakademi.com/datasets/lumpapell/lpunit.src}{p_end}

{pstd}First pair: breaks in intercept and trend, AIC lag selection. In Stata:{p_end}
{phang2}{cmd:. use https://eruygurakademi.com/datasets/lumpapell/Canada.dta, clear}{p_end}
{phang2}{cmd:. lumpapell prod, break(both) method(aic) maxlags(8)}{p_end}

{pstd}and in WinRATS:{p_end}
{p 8 12 2}{cmd:cal(q) 1980:1}{p_end}
{p 8 12 2}{cmd:allocate 2000:4}{p_end}
{p 8 12 2}{cmd:open data c:\lumpapell_test\canada_prod.txt}{p_end}
{p 8 12 2}{cmd:data(format=free,org=columns) 1980:1 2000:4 prod}{p_end}
{p 8 12 2}{cmd:source c:\lumpapell_test\lpunit.src}{p_end}
{p 8 12 2}{cmd:@lpunit(break=both,method=aic,maxlags=8) prod}{p_end}

{pstd}Second pair: intercept breaks, general-to-specific lag selection. In Stata:{p_end}
{phang2}{cmd:. lumpapell prod, break(intercept) method(ttest) maxlags(8) signif(0.10)}{p_end}

{pstd}and in WinRATS, after the same data and source lines:{p_end}
{p 8 12 2}{cmd:@lpunit(break=intercept,method=ttest,maxlags=8,signif=0.10) prod}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:lumpapell} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(cdstat)}}test statistic (minimized t on y(t-1)){p_end}
{synopt:{cmd:r(N)}}number of observations in the reported regression{p_end}
{synopt:{cmd:r(autop)}}number of augmenting lags in the reported regression{p_end}
{synopt:{cmd:r(lags)}}same as {cmd:r(autop)}{p_end}
{synopt:{cmd:r(maxlag)}}maximum number of lags considered{p_end}
{synopt:{cmd:r(pinobs)}}trimming window of the break grid in observations{p_end}
{synopt:{cmd:r(pi)}}trimming fraction{p_end}
{synopt:{cmd:r(signif)}}significance cutoff for t-test pruning{p_end}
{synopt:{cmd:r(cv1)}}1 percent critical value{p_end}
{synopt:{cmd:r(cv25)}}2.5 percent critical value, when {cmd:cv(paper)}{p_end}
{synopt:{cmd:r(cv5)}}5 percent critical value{p_end}
{synopt:{cmd:r(cv10)}}10 percent critical value{p_end}
{synopt:{cmd:r(tcrit)}}last-lag |t| cutoff, when {cmd:tcrit()} is active{p_end}
{synopt:{cmd:r(minent)}}first reported break date as a time value{p_end}
{synopt:{cmd:r(maxent)}}second reported break date as a time value{p_end}
{synopt:{cmd:r(break1)}, {cmd:r(break2)}, ...}break dates as time values{p_end}

{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:lumpapell}{p_end}
{synopt:{cmd:r(varname)}}name of the tested series{p_end}
{synopt:{cmd:r(break)}}break specification{p_end}
{synopt:{cmd:r(method)}}lag selection method{p_end}
{synopt:{cmd:r(mode)}}{cmd:rats} or {cmd:paper}{p_end}
{synopt:{cmd:r(cvsource)}}source of the critical values{p_end}
{synopt:{cmd:r(regcmd)}}regress command reproducing the break regression{p_end}
{synopt:{cmd:r(breakdates)}}formatted break dates{p_end}
{synopt:{cmd:r(tsfmt)}}time variable display format{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}coefficient row vector, in the order Y1, break dummies, Constant, Trend, lags{p_end}
{synopt:{cmd:r(t)}}t statistics, same order{p_end}
{synopt:{cmd:r(breaks)}}break dates as time values, 1 x 2{p_end}


{marker references}{...}
{title:References}

{phang}
Doan, T. 2017. lpunit.src: RATS procedure for the Lumsdaine-Papell unit root test,
revision 05/2017. Evanston, IL: Estima.

{phang}
Lumsdaine, R. L., and D. H. Papell. 1997. Multiple trend breaks and the unit-root
hypothesis. {it:Review of Economics and Statistics} 79: 212-218.

{phang}
Nelson, C. R., and C. I. Plosser. 1982. Trends and random walks in macroeconomic time
series: Some evidence and implications. {it:Journal of Monetary Economics} 10: 139-162.

{phang}
Perron, P. 1989. The great crash, the oil price shock, and the unit root hypothesis.
{it:Econometrica} 57: 1361-1401.

{phang}
Zivot, E., and D. W. K. Andrews. 1992. Further evidence on the great crash, the
oil-price shock, and the unit-root hypothesis.
{it:Journal of Business and Economic Statistics} 10: 251-270.


{marker author}{...}
{title:Author}

{pmore}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com":https://www.ozaneruygur.com}{break}
{browse "mailto:eruygur@gmail.com":eruygur@gmail.com}

{pmore}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.{break}
{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}{break}
{browse "mailto:eruygurakademi@gmail.com":eruygurakademi@gmail.com}

{pmore}
This command is a faithful Stata/Mata port of the RATS procedure lpunit.src
(revision 05/2017) by Tom Doan, Estima, extended with an article mode
implementing the two-break models of Lumsdaine and Papell (1997), including
model CA.

{pmore}
lumpapell v1.5.9 - August 2026

{pstd}
{ul:Please cite as:}

{phang}
Eruygur, H. O. 2026. {bf:lumpapell}: Lumsdaine-Papell unit root test with
structural breaks. Stata package version 1.5.9. Available from:
{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}
