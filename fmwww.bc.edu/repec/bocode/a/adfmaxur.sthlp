{smcl}
{* *! version 1 24mar2017}
{cmd:help adfmaxur}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}

{p2col :{hi:adfmaxur} {hline 2}} Calculate Leybourne (1995) ADFmax unit root test statistic along with finite-sample critical values and associated p-values{p_end}
{p2colreset}{...}


{title:Syntax}
{p 8 17 2}
{cmd:adfmaxur} {varname} {ifin} [{cmd:,} {cmd:noprint}
{cmdab:maxlag(}{it:integer}{cmd:)}
{cmdab:trend}]

{p 4 6 2}
The {cmd:by} prefix is not allowed. The routine can be applied to a single unit of a panel.{p_end}
{p 4 6 2}
Before using {opt adfmaxur} you must {opt tsset} your data; see {manhelp tsset TS}.{p_end}
{p 4 6 2}
{it:varname} may contain time series operators; see {manhelp tsvarlist U}.{p_end}
{p 4 6 2}
Sample may not contain gaps.{p_end}

{title:Description}

{pstd}{cmd:adfmaxur} computes Leybourne (1995) ADFmax unit root tests against the alternative of stationarity.
The command accommodates {it:varname} with nonzero mean and nonzero trend. Allowance is also made for the lag length to be either fixed (FIXED)
or determined endogenously using information criteria such as Akaike and Schwarz, denoted AIC and SIC, respectively. A data-dependent procedure often known as the general-to-specific (GTS)
algorithm is also permitted, using significance levels of 5 and 10%, denoted GTS05 and GTS10, respectively; see e.g. Hall (1994). Approximate p-values are also calculated.

{pstd}Both the finite-sample critical values and the p-value are estimated based on an extensive set of Monte Carlo simulations, summarized by means of response surface regressions; for more details see Otero and Smith (2012).


{title:Options}

{phang}{opt noprint} specifies that the results are to be returned but not printed.

{phang}{opt maxlag} sets the number of lags to be included in the test regression to account for residual serial correlation.
If not specified, {hi:adfmaxur} sets the number of lags following Schwert (1989) with the formula maxlag=int(12*(T/100)^0.25), where T is the total number of observations.

{phang}{opt trend} specifies that the test regression includes constant and trend. Use {hi:trend} when {it:varname} is a nonzero trend stochastic process. By default, {it:varname} is assumed to be a nonzero mean stochastic process.

{title:Examples}

{pstd} We begin by loading the data, provided as an ancillary file: 

{phang2}{inp:.} {stata "use rerdata":use rerdata}{p_end}

{pstd}Then, let us say that we would like to test whether the real exchange rate in the UK contains a unit root, against the alternative that it is a stationary process.
Given that UK has a nonzero mean, the relevant test regression includes a constant (but no trend), which is implemented by default.
Initially, the number of lags is set by the user as p=4.

{phang2}{inp:.} {stata "adfmaxur uk, maxlag(4)": adfmaxur uk, maxlag(4)}{p_end}

{pstd}This second illustration is the same as above, but using a subsample of the data that starts in the first quarter of 1978:

{phang2}{inp:.} {stata "adfmaxur uk if tin(1978q1,), maxlag(4)": adfmaxur uk if tin(1978q1,), maxlag(4)}{p_end}
 
{pstd}We can perform the ADFmax test using all the available observations, but with the number of lags determined based on Schwert's formula:

{phang2}{inp:.} {stata adfmaxur uk : adfmaxur uk}{p_end}

{pstd}We can also work with a long form of the data, in which a single variable ER contains all countries' real exchange rates, by restricting the sample to one country:

{phang2}{inp:.} {stata use rerdata_long :use rerdata_long}{p_end}

{phang2}{inp:.} {stata adfmaxur ER if cty=="uk" : adfmaxur ER if cty=="uk"}{p_end}

{title:Stored results}

{synopt:{cmd:r(varname)}}Variable name{p_end}
{synopt:{cmd:r(treat)}}Test regression includes constant, and constant and trend, depending on the {cmd:trend} option{p_end}
{synopt:{cmd:r(minp)}}First period used in the test regression{p_end}
{synopt:{cmd:r(maxp)}}Last period used in the test regression{p_end}
{synopt:{cmd:r(tsfmt)}}Time series format of the time variable{p_end}
{synopt:{cmd:r(N)}}Number of observations in the test regression{p_end}
{synopt:{cmd:r(results)}}Results matrix, 5x6{p_end}

{p}The rows of the results matrix indicate which method of lag length was used: 
FIX (lag selected by user, or using Schwert's formula); AIC; SIC;  GTS05; or GTS10{p_end}

{p}The columns of the results matrix contain, for each method: the number of lags used;
the ADFmax statistic; Its p-value; and the critical values at 1%, 5%, and 10%, respectively.{p_end}


{title:Authors}

{phang} Jesús Otero, Universidad del Rosario, Colombia{break} jesus.otero@urosario.edu.co{p_end}

{phang} Christopher F Baum, Boston College, USA{break} baum@bc.edu{p_end}

{title:References}

{phang}Hall, A. (1994). Testing for a unit root in time series with pretest data-based model selection. Journal of Business and Economic Statistics 12, 461-470.

{phang}Leybourne, S. (1995). Testing for unit roots using forward and reverse Dickey-Fuller regressions. Oxford Bulletin of Economics and Statistics 57, 559-571.

{phang}Otero, J., J. Smith (2012). Response surface models for the Leybourne unit root tests and lag order dependence. Computational Statistics 27, 473-486.

{phang}Schwert, G. W. (1989). Tests for unit roots: A Monte Carlo investigation. Journal of Business and Economic Statistics 7, 147-159.

