{smcl}
{* 23Jan2026}{...}


{title:Title}

{p 4 4 2}
{bf:ocsb} {hline 2} Osborn-Chui-Smith-Birchenhall (OCSB) test for seasonal unit roots

{title:Syntax}

{pstd}
OCSB test for seasonal unit root:

{p 8 15 2}
{cmd:ocsb} {help varname} {ifin} [{cmd:,} {it:options}]


{pstd}
Estimate the number of seasonal differences needed to make the time series stationary:

{p 8 15 2}
{cmd:ocsb_ndiff} {help varname} {ifin} [{cmd:,} {it:options}]



{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:ocsb}
{synopt:{opt l:ag(#)}}lag order for AR model (0-3 recommended); default is {cmd: lag(0)}{p_end}
{synopt:{opt se:asonal(#)}}seasonal period; if not specified, determined from {help tsset}{p_end}
{synopt:{opt reg:ress}}display regression output{p_end}

{syntab:ocsb_ndiff}
{synopt:{opt max:diffs(#)}}maximum number of seasonal differences to consider; default is {cmd:maxdiff(2)}{p_end}
{synopt:{opt l:ag(#)}}lag order for OCSB test; default is {cmd:lag(0)}{p_end}
{synopt:{opt se:asonal(#)}}seasonal period; if not specified, determined from {help tsset}{p_end}
{synopt:{opt fo:rce}}continue testing even with insufficient observations{p_end}
{synopt:{opt qu:iet}}suppress iteration output, show only final result{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {opt tsset} your data before using {opt ocsb} and {opt ocsb_ndiff}; see {manhelp tsset TS}.{p_end}
{p 4 6 2}
{it:varname} may contain time-series operators; see {help tsvarlist}.{p_end}



{title:Description}

{pstd}
{cmd:ocsb} implements the Osborn-Chui-Smith-Birchenhall (OCSB) test for seasonal unit roots.
The OCSB test is designed to determine whether seasonal differencing is needed for a time series.
The null hypothesis is that the series has a seasonal unit root (needs seasonal differencing),
while the alternative is that the series is stationary (does not need seasonal differencing).

{pstd}
{cmd:ocsb_ndiff} is a wrapper program that repeatedly applies the OCSB test to determine
the optimal number of seasonal differences required to make a time series stationary.
It follows an iterative procedure similar to {browse "https://www.rdocumentation.org/packages/forecast/versions/9.0.0/topics/nsdiffs":nsdiffs} 
in R's {browse "https://www.rdocumentation.org/packages/forecast/versions/8.5/topics/forecast":forecast} package.


{title:Options}

{phang}
{opt lag(#)} specifies the lag order for the autoregressive (AR) model used in the test.
For {cmd:ocsb}, this is the lag used in the single test. For {cmd:ocsb_ndiff}, this is the
lag used at each iteration. Typical values are 0-3. Higher lags may be used for longer series.

{phang}
{opt seasonal(#)} specifies the seasonal period (e.g., 4 for quarterly, 12 for monthly, etc.).
If not specified, the program attempts to determine the period from the {help tsset} settings. 
If the seasonal period cannot be determined from {help tsset} (for example, if the time variable 
is sequential numbers 1, 2, 3, ...), you must specify the seasonal period using {cmd: seasonal(#)}. 
It is important that when using the {cmd:seasonal()} option, the specified seasonal 
period correctly reflects the true seasonality of the data. Using an incorrect seasonal period 
will produce meaningless test results. 

{phang}
{opt regress} (for {cmd:ocsb} only) displays the regression output from the final OCSB regression.

{phang}
{opt maxdiffs(#)} (for {cmd:ocsb_ndiff} only) specifies the maximum number of seasonal differences
to consider. Default is 2, as most time series require at most one or two seasonal differences.

{phang}
{opt force} (for {cmd:ocsb_ndiff} only) forces the program to continue testing even when there are
insufficient observations. By default, the program stops if there are not enough observations
for reliable testing.

{phang}
{opt quiet} (for {cmd:ocsb_ndiff} only) suppresses the iteration table and shows only the final result.



{title:Examples}

{hline 60}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse air2}{p_end}
{phang2}{cmd:. gen date = m(1949m1) + _n - 1}{p_end}
{phang2}{cmd:. format date %tm}{p_end}
{phang2}{cmd:. tsset date}{p_end}

{pstd}Test whether air follows a unit-root process for annual seasonal data{p_end}
{phang2}{cmd:. ocsb air}{p_end}
{phang2}{cmd:. ocsb air, lag(2) regress}{p_end}

{pstd}Determine seasonal differencing order up to a max of twice differencing{p_end}
{phang2}{cmd:. ocsb_ndiff air}{p_end}
{phang2}{cmd:. ocsb_ndiff air, maxd(2) lag(2)}{p_end}		

{hline 60}



{title:Remarks}

{phang2}
1. The OCSB test is designed for seasonal time series with period m > 1.
   For non-seasonal data, use {help dfuller}, {help pperron}, or {help kpss} instead.

{phang2}
2. The test requires at least m + lag + 3 observations for reliable results.

{phang2}
3. For automatic lag selection, consider using {cmd:lag(0)} for short series,
   {cmd:lag(1)} or {cmd:lag(2)} for medium series, and {cmd:lag(3)} for long series.

{phang2}
4. The {cmd:ocsb_ndiff} program follows the same logic as R's {browse "https://www.rdocumentation.org/packages/forecast/versions/9.0.0/topics/nsdiffs":nsdiffs}
   function with test="ocsb".
   


{title:Stored results for ocsb}

{pstd}
{cmd:ocsb} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(tstat)}}t-statistic{p_end}
{synopt:{cmd:r(crit)}}5% critical value{p_end}
{synopt:{cmd:r(coef)}}coefficient estimate{p_end}
{synopt:{cmd:r(lag)}}lag order used{p_end}
{synopt:{cmd:r(m)}}seasonal period{p_end}
{synopt:{cmd:r(N)}}number of observations in final regression{p_end}
{p2colreset}{...}

{pstd}
{cmd:ocsb_ndiff} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(D)}}optimal number of seasonal differences{p_end}
{synopt:{cmd:r(m)}}seasonal period{p_end}
{synopt:{cmd:r(maxD)}}maximum D considered{p_end}
{p2colreset}{...}   



{title:References}

{pstd}
Osborn, D. R., Chui, A. P. L., Smith, J., & Birchenhall, C. R. (1988).
Seasonality and the order of integration for consumption.
{it:Oxford Bulletin of Economics and Statistics}, 50(4), 361-377.

{pstd}
Hyndman, R. J., & Khandakar, Y. (2008).
Automatic time series forecasting: The forecast package for R.
{it:Journal of Statistical Software}, 27(3), 1-22.

{pstd}
Forecast package for R. {browse "https://pkg.robjhyndman.com/forecast/"}


{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Citation of {cmd:ocsb}}

{p 4 8 2}{cmd:ocsb} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). OCSB: Stata module to compute the Osborn-Chui-Smith-Birchenhall (OCSB) test for seasonal unit roots



{title:Also see}

{p 7 14 2} Help: {helpb dfuller}, {helpb pperron}, {helpb kpss} (if installed), {helpb hegy} (if installed) {p_end}
