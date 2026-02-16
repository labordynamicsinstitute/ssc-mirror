{smcl}
{* *! version 2.0  05feb2026}{...}
{* *! version 1.6  30nov2025}{...}
{* *! version 1.5  18oct2025}{...}
{* *! version 1.0  10sep2025}{...}
{viewerjumpto "Syntax" "flexdid_postestimation##syntax"}{...}
{viewerjumpto "Options" "flexdid_postestimation##options"}{...}
{viewerjumpto "Description" "flexdid_postestimation##description"}{...}
{viewerjumpto "Remarks" "flexdid_postestimation##remarks"}{...}
{viewerjumpto "Examples" "flexdid_postestimation##examples"}{...}
{viewerjumpto "Stored results" "flexdid_postestimation##results"}{...}
{p}
{bf:flexdid postestimation} {hline 2} Postestimation tools for flexdid


{marker postestimation}{...}
{title:Postestimation commands}

{pstd}
The following postestimation command is of special interest after
{cmd:flexdid}:

{synoptset 28 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{p2coldent: {helpb flexdid_postestimation##syntax_estat atet:estat atet}} estimates ATETs 
to characterize the heterogenity of treatment effects {p_end}
{synoptline}
{p 4 6 2}

{marker syntax}{...}
{title:Syntax of estat atet}

{p 8 16 2}
{cmd:estat atet,} {it:{help flexdid postestimation##options:options}}

{marker options}{...}
{synoptset 29 tabbed}{...}
{synopthdr:options}
{synoptline}
{p2coldent :* {cmd:overall}[{cmd:(}{help flexdid_postestimation##options:{it:overall_list}}{cmd:)}]}
estimates overall ATET over all exposure times in {it:overall_list}; implies {cmd:nograph}{p_end}
{p2coldent :* {cmd:byget}[{cmd:(}{help flexdid_postestimation##options:{it:exposure_list}}{cmd:)}]}
estimates group X exposure time ATETs by each time period in {it:exposure_list}; 
implies {cmd:nograph}{p_end}
{p2coldent :* {cmd:byexposure}[{cmd:(}{help flexdid_postestimation##options:{it:exposure_list}}{cmd:)}]}
estimates ATETs by each exposure time in {it:exposure_list}{p_end}
{p2coldent :* {cmd:bycalendar}[{cmd:(}{help flexdid_postestimation##options:{it:calendar_list}}{cmd:)}]}
estimates ATETs by each calendar time in {it:calendar_list}{p_end}
{p2coldent :* {cmd:bycohort}[{cmd:(}{help flexdid_postestimation##options:{it:cohort_list}}{cmd:)}]}
estimates ATETs by each treated cohort in {it:cohort_list}{p_end}
{p2coldent :* {cmd:bygroup}[{cmd:(}{help flexdid_postestimation##options:{it:group_list}}{cmd:)}]}
estimates ATETs by each treated group in {it:group_list}{p_end}
{synopt :{cmd:for}{cmd:(}{it:{help if}} {it:{help exp}})} estimates ATETs for the subpopulation 
identified by the {cmd:if exp} expression{p_end}
{synopt :{cmd:test}{cmd:(}{help flexdid_postestimation##nulltype:{it:nulltype}}{cmd:)}}
estimates an F test of a hypothesis of the ATETs specified by {it:nulltype}; {it:nulltype} must 
be specified{p_end}
{synopt :{cmd:no}{cmd:graph}} supresses the ATET plot{p_end}
{p2coldent :+ {opth graph:(marginsplot:graph_opts)}} affects rendition of the ATET plot{p_end}
{synopt :{opt dydx}} estimates ATETs using the {cmd:dydx} option in {cmd:{help margins}}; 
useful when the default procedure fails to produce standard errors of the ATETs{p_end}
{synopt :{opth agg:regationweight(flexdid_postestimation##wtype:wtype)}}specify the aggregation weights; 
default is {cmd:aggregationweight(obslevel)}{p_end}
{synoptline}

{marker nulltype}{...}
{synoptset 28}{...}
{synopthdr:nulltype}
{synoptline}
{synopt :{opt zero}}specifies the null hypothesis that all the ATETs are equal to zero{p_end}
{synopt :{opt equal}}specifies the null hypothesis that all the ATETs are equal to each other{p_end}
{synoptline}

{marker wtype}{...}
{synoptset 28}{...}
{synopthdr:wtype}
{synoptline}
{synopt :{opt obslevel}}specifies that observation-level ATETs are aggregated using simple averaging; the default{p_end}
{synopt :{opt grouplevel}}specifies that observation-level ATETs are first aggregated to the group-time level
and then aggregated using weighted means where the weights are the group-level sample sizes{p_end}
{synoptline}

{p 4 6 2}
* One of these options is required.{p_end}
{p 4 6 2}
+ {it:graph_opts} are most options included in {helpb marginsplot}.{p_end}


{marker description}{...}
{title:Description of estat atet}

{phang}
{cmd:estat atet} estimates ATETs to characterize the heterogenity of treatment
effects. In addition to tabular presentation of results, {cmd:estat atet} produces
plots of the effects in most cases. In addition, two important hypotheses, that
the ATETs are all equal to zero, or that the ATETs are equal to each other, can be tested.


{marker options}{...}
{title:Options for estat atet}

{phang}
{opth overall[:(numlist:overall_list)}{bf:]} estimates the overall ATET over all exposure time periods in {it:overall_list}. 
The list can contain negative integers, which indicate leads or pre-treatment exposure time periods.
Specifying {cmd:overall} without arguments estimates the overall ATET over all treated exposure time periods,
i.e., from 0 to the last exposure time period observed in the data. This option does not produce a graph, i.e., it implies {cmd:nograph}.{p_end}

{phang}
{opth byget[:(numlist:exposure_list)}{bf:]} estimates ATETs for each group X exposure time period in {it:exposure_list}.
The list can contain negative integers, which indicate leads or pre-treatment periods.
Specifying {cmd:byget} without arguments estimates the ATETs for all group X exposure time periods, from the 
earliest pre-treatment exposure time period to the last exposure time period observed in the data. This option does not produce a graph, i.e., it implies {cmd:nograph}.{p_end}

{phang}
{opth byexposure[:(numlist:exposure_list)}{bf:]} estimates ATETs for each exposure time period 
in {it:exposure_list}. The list can contain negative integers, which indicate leads or pre-treatment periods
appropriate for use in the lags and leads specification.
Specifying {cmd:byexposure} without arguments estimates ATETs for all exposure time periods,
i.e., from 0 or the earliest pre-treatment exposure period in the lags only and the lags and leads 
specifications respectively to the latest exposure time observed in the data.{p_end}

{phang}
{opth bycalendar[:(numlist:calendar_list)}{bf:]} estimates ATETs for each calendar time period in {it:calendar_list}. 
Specifying {cmd:bycalendar} without arguments estimates ATETs for all calendar time periods
observed in the data.{p_end}

{phang}
{opth bycohort[:(numlist:cohort_list)}{bf:]} estimates ATETs for each treatment cohort in {it:cohort_list}. 
Specifying {opt bycohort} without arguments estimates ATETs for each treated cohort in the data.{p_end}

{phang}
{opth bygroup[:(numlist:group_list)}{bf:]} estimates ATETs for each treated group in {it:group_list}. 
Specifying {opt bygroup} without arguments estimates ATETs for each treated group in the data.{p_end}

{phang}
{opth for:(if exp)} estimates ATETs for the subpopulation identified by the {cmd:if exp} expression.
{cmd:if exp} is a proper expression such as age<65 or age<65 & sex==1. 

{phang} 
{opt test(nulltype)} estimates an F test of a hypothesis of the ATETs specified by {cmd:nulltype} which 
is either {cmd: zero} or {cmd: equal}.

{phang2}{cmd: zero} specifies the null hypothesis that all the ATETs are equal to zero.

{phang2}{cmd: equal} specifies the null hypothesis that all the ATETs are equal to each other.

{phang}
{cmd:nograph} suppresses the ATET plot. 

{phang}
{opt graph(graph_opts)} affects the rendition of the ATET plot. {it:graph_opts} include most options 
found in {helpb marginsplot}.

{phang}
{opt dydx} estimates ATETs using the {cmd:dydx} option in {cmd:{help margins}}. The default
procedure is to use {cmd:{help margins_contrast}}. Although {cmd:{help margins_contrast}} is
substantially faster, on occasion it fails to produce standard errors of the estimates. 
{cmd:dydx} is useful in those cases.

{phang}
{opt agg:regationweight(wtype)} specifies the aggregaton wights, either {cmd: obslevel}
or {cmd: grouplevel}; the default is {cmd:aggregationweight(obslevel)}.  

{phang2}{cmd: obslevel} specifies that observation-level ATETs, computed using {cmd:{help margins}},
are aggregated using simple averaging over the treated observations or over the treated observations 
in the subsamples of interest, as appropriate.{p_end}

{phang2}{cmd: grouplevel} specifies that observation-level ATETs, computed using {cmd:{help margins}},
are first aggregated to the group-time level and then aggregated using weighted means where the weights 
are the group-level sample sizes over all time periods.{p_end}


{marker remarks}{...}
{title:Remarks}
{phang}
{cmd:estat atet,} {it:{help flexdid postestimation##options:options}}, by default, uses 
{cmd:{help margins_contrast}} to aggregate regression estimates to ATETs and to compute their
standard errors. Although {cmd:{help margins_contrast}} is fast and reliable, it can fail to
produce standard errors in some instances when the covariate matrix is not of full rank. Such
situations typically arise when ATETs at the group X exposure time level are required and when the 
cluster-robust variance estimator is used along with cluster-units identical to the units 
of group fixed effects and units at which treatment occurs. In such situations, {cmd:{help margins}}
with the {cmd:dydx} option can handle rank and stability issues better, at the cost of
substantially greater computation time.

{marker examples}{...}
{title:Examples of estat atet}

{pstd}
Setup{p_end}
{phang2}{cmd:. webuse hhabits}{p_end}
{phang2}{cmd:. egen chrt = min(year/hhabit), by(schools)}{p_end}
{phang2}{cmd:. replace chrt = 0 if chrt==.}{p_end}

{pstd}
Estimate the FLEX regression of the treatment, {cmd:hhabit}, on the outcome body mass index, {cmd:bmi},
for cohorts of school districts by year, {cmd:chrt}, using the lagsandleads specification.{p_end}
{phang2}{cmd:. flexdid bmi, tx(hhabit) group(chrt) time(year) specification(lagsandleads)}{p_end}

{pstd}
Estimate overall ATET of treatment over exposure time periods 0 to 3.{p_end}
{phang2}{cmd:. estat atet, overall(0/3)}{p_end}

{pstd}
Estimate ATET of treatment for each exposure time period (the event study plot).{p_end}
{phang2}{cmd:. estat atet, byexposure}{p_end}

{pstd}
Estimate the ATET for each exposure time period from 0 to 3.{p_end}
{phang2}{cmd:. estat atet, byexposure(0/3)}{p_end}

{pstd}
Estimate the ATET for pre-treatment exposure time periods from -6 to -2, suppressing the ATET graph
and testing the null hypothesis that all pre-treatment exposure time effects are equal to zero.{p_end}
{phang2}{cmd:. estat atet, byexposure(-6/-2) test(zero) nograph}{p_end}

{pstd}
Estimate the ATET for treatment exposure time periods from 0 to 6, suppressing the ATET graph
and testing the null hypothesis that all treatment exposure time effects are equal to each other.{p_end}
{phang2}{cmd:. estat atet, byexposure(0/6) test(equal) nograph}{p_end}

{pstd}
Estimate the ATET for calendar years 2035 and 2038, supressing the ATET graph.{p_end}
{phang2}{cmd:. estat atet, bycalendar(2035 2038) nograph}{p_end}

{pstd}
Estimate the FLEX regression of treatment on outcome body mass index, controlling for covariates,
for cohorts of school districts by year ; using the lagsandleads only specification.{p_end}
{phang2}{cmd:. flexdid bmi i.girl medu, tx(hhabit) group(chrt) time(year)}
        {cmd:specification(lagsandleads) vce(cluster schools)}{p_end}

{pstd}
Estimate the ATET for each group X exposure time period for the pre-treatment time periods, from 
-6 to -2, and test whether the group X exposure time effects are equal to zero.{p_end}
{phang2}{cmd:. estat atet, byget(-6/-2) test(zero)}{p_end}

{pstd}
Estimate the ATET for exposure periods from 0 to 6 for girl==1, supressing the ATET graph.{p_end}
{phang2}{cmd:. estat atet, byexposure(0/6) for(girl==1) nograph}{p_end}

{marker results}{...}
{title:Stored results after estat atet}

{pstd}
{cmd:estat atet} stores the following in {cmd:r()}

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Macros}{p_end}
{synopt :{cmd:r(atettype)}}ATET "by" option specified{p_end}
{synopt :* {cmd:r(test)}}test null hypothesis option specified{p_end}

{p2col 5 23 26 2: Scalars}{p_end}
{synopt :* {cmd:r(p)}}two-sided p-value{p_end}
{synopt :* {cmd:r(F)}}F statistic{p_end}
{synopt :* {cmd:r(df)}}test constraints degrees of freedom{p_end}
{synopt :* {cmd:r(df_r)}}residual degrees of freedom{p_end}
{synopt :* {cmd:r(drop)}}1 if constraints were dropped, 0 otherwise{p_end}


{p2col 5 23 26 2: Matrices}{p_end}
{synopt :{cmd:r(table)}}matrix containing the ATETs with their standard errors,
test statistics, {it:p}-values, and confidence interval{p_end}
{synopt :{cmd:r(b)}}ATET vector{p_end}
{synopt :{cmd:r(V)}}variance-covariance matrix of the ATETs{p_end}
{p2colreset}{...}

{p 4 6 2}
* Only stored when {cmd:test()} is specified.{p_end}
