{smcl}
{* *! version 1 20nov2016}
{cmd:help ersur}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}

{p2col :{hi:ersur} {hline 2}} Calculate Elliott, Rothenberg & Stock (1996) unit root test statistic along with 1, 5 and 10% finite-sample critical values and associated p-values{p_end}
{p2colreset}{...}


{title:Syntax}
{p 8 17 2}
{cmd:ersur} {varname} {ifin} [{cmd:,} {cmd:noprint}
{cmdab:maxlag(}{it:integer}{cmd:)}
{cmdab:trend}]

{p 4 6 2}
{cmd:by} is not allowed. The routine can be applied to a single unit of a panel.{p_end}
{p 4 6 2}
Before using {opt ersur} you must {opt tsset} your data; see {manhelp tsset TS}.{p_end}
{p 4 6 2}
{it:varname} may contain time series operators; see {manhelp tsvarlist U}.{p_end}
{p 4 6 2}
Sample may not contain gaps.{p_end}

{title:Description}

{pstd}{cmd:ersur} computes Elliott, Rothenberg & Stock ERS (1996) GLS-detrending based unit root tests against the alternative of stationarity.
The command accommodates {it:varname} with nonzero mean and nonzero trend. Allowance is also made for the lag length to be either fixed (FIXED)
or determined endogenously using information criteria such as Akaike and Schwarz, denoted AIC and SIC, respectively. A data-dependent procedure often known as the general-to-specific (GTS)
algorithm is also permitted, using significance levels of 5 and 10%, denoted GTS05 and GTS10, respectively; see e.g. Hall (1994). Approximate p-values are also calculated.

{pstd}Both the finite-sample critical values and the p-value are estimated based on an extensive set of Monte Carlo simulations, summarized by means of response surface regressions; for more details see Otero (2017).


{title:Options}

{phang}{opt noprint} specifies that the results are to be returned but not printed.

{phang}{opt maxlag} sets the number of lags to be included in the test regression to account for residual serial correlation.
If not specified, {hi:ersur} sets the number of lags following Schwert (1989) with the formula maxlag=int(12*(T/100)^0.25), where T is the total number of observations.

{phang}{opt trend} specifies that GLS detrending is to be applied. Use {hi:trend} when {it:varname} is a nonzero trend stochastic process,
 in which case ERS recommend detrending the data using GLS. 
By default, {it:varname} is assumed to be a nonzero mean stochastic process.

{title:Examples}

{pstd} We begin by downloading the data from SSC and verifying that it has a time-series format:

{phang2}{inp:.} {stata "use usrates":use usrates}{p_end}

{phang2}{inp:.} {stata "tsset":tsset}{p_end}

{pstd}Then, let us say that we would like to test whether the interest rate spread between r6 and r3, which we shall denote as s6, contains a unit root, against the alternative that it is a stationary process.
Given that s6 has a nonzero mean, the relevant ERS statistic is that based on GLS demeaned data, which is implemented by default.
Initially, the number of lags is set by the user as p=3.

{phang2}{inp:.} {stata "ersur s6, maxlag(3)":ersur s6, maxlag(3)}{p_end}

{pstd}This second illustration is the same as above, but using a subsample of the data that starts in January 1997:

{phang2}{inp:.} {stata "ersur s6 if tin(1997m1,), maxlag(3)":ersur s6 if tin(1997m1,), maxlag(3)}{p_end}
 
{pstd}Lastly, we perform the ERS test using all the available observations, but with the number of lags determined based on Schwert's formula:

{phang2}{inp:.} {stata "ersur s6":ersur s6}{p_end}


{title:Stored results}

{synopt:{cmd:r(varname)}}Variable name{p_end}
{synopt:{cmd:r(treat)}}Demeaned or detrended, depending on the {cmd:trend} option{p_end}
{synopt:{cmd:r(minp)}}First period used in the test regression{p_end}
{synopt:{cmd:r(maxp)}}Last period used in the test regression{p_end}
{synopt:{cmd:r(tsfmt)}}Time series format of the time variable{p_end}
{synopt:{cmd:r(N)}}Number of observations{p_end}
{synopt:{cmd:r(results)}}Results matrix, 5x6{p_end}

{p}The rows of the results matrix indicate which method of lag length was used: 
FIX (lag selected by user, or using Schwert's formula); AIC; SIC;  GTS05; or GTS10{p_end}

{p}The columns of the results matrix contain, for each method: the number of lags used;
the ERS statistic; Its p-value; and the critical values at 1%, 5%, and 10%, respectively.{p_end}


{title:Authors}

{phang} Jesus Otero, Universidad del Rosario, Colombia{break} jesus.otero@urosario.edu.co{p_end}

{phang} Christopher F Baum, Boston College, USA{break} baum@bc.edu{p_end}

{title:References}

{phang}Elliott, G., T. J. Rothenberg and J. H. Stock (1996). Efficient tests for an autoregressive unit root. Econometrica 64, 813-836.

{phang}Hall, A. (1994). Testing for a unit root in time series with pretest data-based model selection. Journal of Business and Economic Statistics 12, 461-470.

{phang}Otero, J. (2017). Response surface models for the Elliott, Rothenberg and Stock unit root test.

{phang}Schwert, G. W. (1989). Tests for unit roots: A Monte Carlo investigation. Journal of Business and Economic Statistics 7, 147-159.





