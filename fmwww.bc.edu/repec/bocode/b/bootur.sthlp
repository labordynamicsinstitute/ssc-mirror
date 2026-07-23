{smcl}
{* *! version 1.0.0  20jul2026}{...}
{vieweralsosee "bootur methods" "help bootur_methods"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "bootur##syntax"}{...}
{viewerjumpto "Description" "bootur##description"}{...}
{viewerjumpto "Options" "bootur##options"}{...}
{viewerjumpto "Subcommands" "bootur##subcommands"}{...}
{viewerjumpto "Stored results" "bootur##results"}{...}
{viewerjumpto "Examples" "bootur##examples"}{...}
{viewerjumpto "References" "bootur##references"}{...}
{viewerjumpto "Author" "bootur##author"}{...}
{title:Title}

{phang}
{bf:bootur} {hline 2} Bootstrap unit root tests for single series, multiple series and panels

{marker syntax}{...}
{title:Syntax}

{pstd}Standard (asymptotic) augmented Dickey-Fuller test{p_end}
{p 8 16 2}{cmd:bootur adf} {varname} {ifin}
[{cmd:,} {it:adf_options}]{p_end}

{pstd}Bootstrap unit root tests on each series (no multiple-testing control){p_end}
{p 8 16 2}{cmd:bootur ur} {varlist} {ifin}
[{cmd:,} {it:boot_options}]{p_end}

{pstd}Bootstrap union test / bootstrap ADF test on a single series{p_end}
{p 8 16 2}{cmd:bootur union} {varname} {ifin} [{cmd:,} {it:boot_options}]{p_end}
{p 8 16 2}{cmd:bootur bootadf} {varname} {ifin} [{cmd:,} {it:boot_options}]{p_end}

{pstd}Bootstrap tests with multiple-testing control{p_end}
{p 8 16 2}{cmd:bootur fdr} {varlist} {ifin} [{cmd:,} {it:boot_options}]{p_end}
{p 8 16 2}{cmd:bootur sqt} {varlist} {ifin} [{cmd:,} {opt steps(numlist)} {it:boot_options}]{p_end}

{pstd}Panel (group-mean) unit root test{p_end}
{p 8 16 2}{cmd:bootur panel} {varlist} {ifin} [{cmd:,} {it:boot_options}]{p_end}

{pstd}Order of integration, differencing and diagnostics{p_end}
{p 8 16 2}{cmd:bootur order} {varlist} {ifin} [{cmd:,} {opt m:ethod(str)} {opt maxo:rder(#)} {opt lev:el(#)} {opt gen:erate(str)} {it:boot_options}]{p_end}
{p 8 16 2}{cmd:bootur diff} {varlist} {ifin}{cmd:,} {opt o:rders(numlist)} [{opt gen:erate(str)} {opt replace}]{p_end}
{p 8 16 2}{cmd:bootur plotmiss} {varlist} {ifin} [{cmd:,} {opt n:ame(str)} {opt title(str)}]{p_end}
{p 8 16 2}{cmd:bootur plotorder} {it:ordersmatrix} [{cmd:,} {opt n:ame(str)} {opt title(str)}]{p_end}

{synoptset 26 tabbed}{...}
{marker boot_options}{...}
{synopthdr:boot_options}
{synoptline}
{syntab:Bootstrap}
{synopt:{opt boot:strap(str)}}bootstrap method: {cmd:MBB}, {cmd:BWB}, {cmd:DWB}, {cmd:AWB} (default), {cmd:SB} or {cmd:SWB}{p_end}
{synopt:{opt b(#)}}number of bootstrap replications; default {cmd:b(1999)}{p_end}
{synopt:{opt block:length(#)}}block length; default {cmd:round(1.75*T^(1/3))}{p_end}
{synopt:{opt ar(#)}}autoregressive parameter for {cmd:AWB}; default {cmd:0.01^(1/blocklength)}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt nodots}}suppress the progress bar{p_end}
{syntab:Test specification}
{synopt:{opt union(#)}}{cmd:1} = union test (default), {cmd:0} = single deterministic case{p_end}
{synopt:{opt det:erministics(str)}}{cmd:none}, {cmd:intercept} (default) or {cmd:trend}; only if {cmd:union(0)}{p_end}
{synopt:{opt detr:end(str)}}{cmd:OLS} (default) or {cmd:QD}; only if {cmd:union(0)}{p_end}
{synopt:{opt lev:el(#)}}significance / FDR / SQT level; default {cmd:level(0.05)}{p_end}
{syntab:Lag selection}
{synopt:{opt crit:erion(str)}}{cmd:AIC}, {cmd:BIC}, {cmd:MAIC} (default) or {cmd:MBIC}{p_end}
{synopt:{opt sc:ale(#)}}{cmd:1} = rescaled criteria (default), {cmd:0} = standard{p_end}
{synopt:{opt minlag(#)}}minimum lag length; default {cmd:0}{p_end}
{synopt:{opt maxlag(#)}}maximum lag length; default a Schwert-type rule{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:bootur} is a Stata port of the {cmd:R} package {bf:bootUR} (Smeekes and
Wilms, 2023). It performs a wide range of bootstrap augmented Dickey-Fuller
(ADF) unit root tests for individual time series, several time series jointly,
and panel data. It also computes the standard (asymptotic) ADF test with
MacKinnon (1996) p-values, determines the order of integration of each series,
and provides differencing and missing-value/order diagnostics.

{pstd}
Data are supplied as one or more numeric variables in wide form (each variable
is one time series, rows are time). Series may have different starting and end
points (unbalanced): the leading/trailing missing values of each series are
handled automatically. Internal missing values (gaps) are not allowed.

{pstd}
Six bootstrap schemes are available. The moving-block ({cmd:MBB}) and sieve
({cmd:SB}) bootstraps resample and cannot be used with unbalanced panels for
the joint tests; the wild schemes ({cmd:BWB}, {cmd:DWB}, {cmd:AWB}, {cmd:SWB})
can. The {cmd:union} test takes the union of rejections over intercept/trend
and OLS/QD (GLS) detrending (Harvey, Leybourne and Taylor, 2012; Smeekes and
Taylor, 2012) and needs no choice of deterministic component.  See
{helpb bootur_methods:help bootur methods} for the underlying algorithm and its
mapping to the equations in the references.

{marker subcommands}{...}
{title:Subcommands}

{phang}{cmd:adf} {hline 2} standard ADF test on one series, with an asymptotic
MacKinnon p-value. Options: {opt det:erministics()}, {opt crit:erion()},
{opt sc:ale()}, {opt minlag()}, {opt maxlag()} and {opt onestep} (one-step
instead of the default two-step detrending).

{phang}{cmd:ur} {hline 2} bootstrap test on {it:each} series individually with no
multiple-testing correction. With {opt level()} a rejection flag is reported per
series. This is the general engine; {cmd:union} and {cmd:bootadf} are
single-series wrappers around it.

{phang}{cmd:union} {hline 2} bootstrap union test on a single series.

{phang}{cmd:bootadf} {hline 2} bootstrap ADF test on a single series
({cmd:union(0)}); choose {opt det:erministics()} and {opt detr:end()}.

{phang}{cmd:fdr} {hline 2} bootstrap tests controlling the false discovery rate
(Moon and Perron, 2012; Romano, Shaikh and Wolf, 2008).

{phang}{cmd:sqt} {hline 2} bootstrap sequential quantile test (Smeekes, 2015).
{opt steps()} gives an increasing list of {it:units} (integers) or {it:quantiles}
(values in [0,1]); e.g. {cmd:steps(0 0.5 1)} splits the series into two groups.

{phang}{cmd:panel} {hline 2} panel unit root test of the joint null that all
series contain a unit root, based on the group-mean statistic (Palm, Smeekes and
Urbain, 2011).

{phang}{cmd:order} {hline 2} determines the order of integration of each series by
a sequence of tests (Smeekes and Wijler, 2020) using {opt method()}
({cmd:ur}, {cmd:fdr}, {cmd:sqt}, {cmd:adf}, {cmd:union} or {cmd:bootadf}).

{phang}{cmd:diff} {hline 2} differences each series by its own order in
{opt orders()} and stores the result as new variables.

{phang}{cmd:plotmiss} {hline 2} plots the pattern of observed and missing values.

{phang}{cmd:plotorder} {hline 2} bar chart of a vector of integration orders (e.g.
the matrix returned by {cmd:bootur order}).

{marker results}{...}
{title:Stored results}

{pstd}{cmd:bootur ur}/{cmd:fdr}/{cmd:sqt}/{cmd:panel} store in {cmd:r()}:{p_end}
{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(level)}}significance level{p_end}
{synopt:{cmd:r(B)}}bootstrap replications{p_end}
{synopt:{cmd:r(block_length)}}block length{p_end}
{synopt:{cmd:r(statistic)}}test statistic (single series / panel){p_end}
{synopt:{cmd:r(p_value)}}p-value (single series / panel){p_end}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(statistic)}}test statistics (multiple series){p_end}
{synopt:{cmd:r(p_value)}}p-values (multiple series, {cmd:ur} only){p_end}
{synopt:{cmd:r(rejections)}}rejection flags ({cmd:fdr}, {cmd:sqt}){p_end}
{synopt:{cmd:r(sequence)}}sequence of tests ({cmd:fdr}, {cmd:sqt}){p_end}
{synopt:{cmd:r(indiv_stat)}}individual statistics, one column per detrending case{p_end}
{synopt:{cmd:r(indiv_est)}}individual (gamma) estimates{p_end}
{synopt:{cmd:r(indiv_lag)}}selected lag lengths{p_end}
{synopt:{cmd:r(indiv_pval)}}individual bootstrap p-values{p_end}
{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(bootstrap)}}bootstrap method{p_end}
{synopt:{cmd:r(criterion)}}information criterion{p_end}

{pstd}{cmd:bootur adf} stores {cmd:r(statistic)}, {cmd:r(p_value)},
{cmd:r(estimate)}, {cmd:r(lag)}, {cmd:r(N)}. {cmd:bootur order} stores the row
vector {cmd:r(order)}.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Load the macroeconomic example data (five countries; GDP, consumption,
inflation, unemployment):{p_end}
{phang2}{cmd:. use MacroTS}{p_end}

{pstd}Standard ADF test on Belgian GDP with a linear trend:{p_end}
{phang2}{cmd:. bootur adf GDP_BE, deterministics(trend)}{p_end}

{pstd}Bootstrap union test on a single series:{p_end}
{phang2}{cmd:. bootur union GDP_BE, bootstrap(AWB) b(1999)}{p_end}

{pstd}Bootstrap unit root tests on several GDP series with a rejection flag:{p_end}
{phang2}{cmd:. bootur ur GDP_BE GDP_DE GDP_FR GDP_NL GDP_UK, level(0.05)}{p_end}

{pstd}Control the false discovery rate across all twenty series:{p_end}
{phang2}{cmd:. bootur fdr GDP_* CONS_* HICP_* UR_*, level(0.10)}{p_end}

{pstd}Sequential quantile test in two equal groups:{p_end}
{phang2}{cmd:. bootur sqt GDP_BE GDP_DE GDP_FR GDP_NL GDP_UK, steps(0 0.5 1)}{p_end}

{pstd}Panel test of the joint unit root null:{p_end}
{phang2}{cmd:. bootur panel GDP_BE GDP_DE GDP_FR GDP_NL GDP_UK}{p_end}

{pstd}Determine and plot the order of integration:{p_end}
{phang2}{cmd:. bootur order GDP_* , method(ur)}{p_end}
{phang2}{cmd:. bootur plotorder r(order)}{p_end}

{pstd}Visualise the missing-value pattern:{p_end}
{phang2}{cmd:. bootur plotmiss GDP_NL HICP_BE UR_FR}{p_end}

{marker references}{...}
{title:References}

{phang}Harvey, D.I., Leybourne, S.J., and Taylor, A.M.R. 2012. Testing for unit
roots in the presence of uncertainty over both the trend and initial condition.
{it:Journal of Econometrics} 169(2): 188-195.{p_end}
{phang}MacKinnon, J.G. 1996. Numerical distribution functions for unit root and
cointegration tests. {it:Journal of Applied Econometrics} 11(6): 601-618.{p_end}
{phang}Moon, H.R. and Perron, B. 2012. Beyond panel unit root tests.
{it:Journal of Econometrics} 169(1): 29-33.{p_end}
{phang}Palm, F.C., Smeekes, S., and Urbain, J.-P. 2011. Cross-sectional
dependence robust block bootstrap panel unit root tests. {it:Journal of
Econometrics} 163(1): 85-104.{p_end}
{phang}Smeekes, S. 2015. Bootstrap sequential tests to determine the order of
integration. {it:Journal of Time Series Analysis} 36(3): 398-415.{p_end}
{phang}Smeekes, S. and Taylor, A.M.R. 2012. Bootstrap union tests for unit roots.
{it:Econometric Theory} 28(2): 422-456.{p_end}
{phang}Smeekes, S. and Wilms, I. 2023. bootUR: An R package for bootstrap unit
root tests. {it:Journal of Statistical Software} 106(12): 1-39.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}This command reproduces the methodology of the R package {bf:bootUR} by
Stephan Smeekes and Ines Wilms. Please cite Smeekes and Wilms (2023).{p_end}
