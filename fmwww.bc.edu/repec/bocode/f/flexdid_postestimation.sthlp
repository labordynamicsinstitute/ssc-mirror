{smcl}
{* *! version 1.0.0  10sep2025}{...}
{viewerjumpto "Syntax" "flexdid_postestimation##postestimation"}{...}
{viewerjumpto "Description" "flexdid_postestimation##syntax"}{...}
{viewerjumpto "Options" "flexdid_postestimation##description"}{...}
{viewerjumpto "Options" "flexdid_postestimation##options"}{...}
{viewerjumpto "Examples" "flexdid_postestimation##examples"}{...}
{viewerjumpto "Stored results" "flexdid_postestimation##results"}{...}
{p}
{bf:flexdid postestimation} {hline 2} Postestimation tools for flexdid


{marker postestimation}{...}
{title:Postestimation commands}

{pstd}
The following postestimation command is of special interest after
{cmd:flexdid}:

{synoptset 19 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{p2coldent:* {helpb flexdid_postestimation##syntax_estat atet:estat atet}} estimates ATETs 
to characterize the heterogenity of treatment effects{p_end}
{synoptline}
{p 4 6 2}
* {cmd:estat atet} may not be used without {it:options}.

{pstd}
The following postestimation commands are also available:

{synoptset 19}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
INCLUDE help post_lincom
INCLUDE help post_nlcom
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}


{marker syntax}{...}
{title:Syntax of estat atet}

{p 8 16 2}
{cmd:estat atet,} {it:{help flexdid postestimation##options:options}}

{marker estat_atet_opts}{...}
{synoptset 29 tabbed}{...}
{synopthdr:estat_atet_options}
{synoptline}
{synopt :{cmd:overall}[{cmd:(}{help flexdid_postestimation##options:{it:overall_list}}{cmd:)}]}
estimates overall ATET over exposure times in {it:overall_list}; cannot be combined with {cmd:graph}{p_end}
{synopt :{cmd:byexposure}[{cmd:(}{help flexdid_postestimation##options:{it:exposure_list}}{cmd:)}]}
estimates ATETs by exposure time in {it:exposure_list}{p_end}
{synopt :{cmd:bycalendar}[{cmd:(}{help flexdid_postestimation##options:{it:calendar_list}}{cmd:)}]}
estimates ATETs by calendar time in {it:calendar_list}{p_end}
{synopt :{cmd:bycohort}[{cmd:(}{help flexdid_postestimation##options:{it:cohort_list}}{cmd:)}]}
estimates ATETs by cohort in {it:cohort_list}{p_end}
{synopt :{cmd:bygroup}[{cmd:(}{help flexdid_postestimation##options:{it:group_list}}{cmd:)}]}
estimates ATETs by group in {it:group_list}{p_end}
{synopt :{cmd:no}{cmd:graph}} supress the ATET plot{p_end}
{p2coldent :* {opth graph:(marginsplot:graph_opts)}} affects rendition of the ATET plot{p_end}
{synoptline}

{p 4 6 2}
* {it:graph_opts} are most options included in {helpb marginsplot}.{p_end}


{marker description}{...}
{title:Description of estat atet}

{phang}
{cmd:estat atet} estimates ATETs to characterize the heterogenity of treatment
effects.


{marker options}{...}
{title:Options for estat atet}

{phang}
{opth overall[:(numlist:overall_list)}{bf:]} estimates the overall ATET over exposure times in {it:overall_list}. 
The list can contain negative integers, which indicate leads or pre-treatment periods.
Specifying {cmd:overall} without arguments estimates overall ATET over all treated exposure time periods,
i.e., from 0 to the latest exposure time observed in the data. Cannot be combined with {cmd:graph}.{p_end}

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
{cmd:nograph} specifies the suppression of the ATET plot. 

{phang}
{opt graph(graph_opts)} affects the rendition of the ATET plot.
{it:graph_opts} include most options found in {helpb marginsplot}.


{marker examples}{...}
{title:Examples of estat atet}

{pstd}
Setup{p_end}
{phang2}{cmd:.  webuse hhabits}{p_end}
{phang2}{cmd:.  flexdid bmi, tx(hhabit) group(schools) time(year), specification(lagsandleads)}{p_end}

{pstd}
Estimate ATET of treatment {cmd:hhabit} for each exposure time period (the event study plot).{p_end}
{phang2}{cmd:. estat atet, byexposure}{p_end}

{pstd}
Estimate the ATET for exposure time periods 0 to 3.{p_end}
{phang2}{cmd:. estat atet, byexposure(0 3)}{p_end}

{pstd}
Estimate the overall ATET for pre-treatment exposure periods -6 to 2.{p_end}
{phang2}{cmd:. estat atet, overall(-6 -2)}{p_end}

{pstd}
Estimate the ATET for specific groups, supressing the ATET graph.{p_end}
{phang2}{cmd:. estat atet, bygroup(1 31 33 34) nograph}{p_end}

{pstd}
Estimate the ATET for calendar years 2035 and 2038, supressing the ATET graph.{p_end}
{phang2}{cmd:. estat atet, bycalendar(2035 2038) nograph}{p_end}


{marker results}{...}
{title:Stored results after estat atet}

{pstd}
{cmd:estat atet} stores the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Macros}{p_end}
{synopt :{cmd:r(atettype)}}ATET option specified{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt :{cmd:r(table)}}matrix containing the ATETs with their standard errors,
test statistics, {it:p}-values, and confidence interval{p_end}
{synopt :{cmd:r(b)}}ATET vector{p_end}
{synopt :{cmd:r(V)}}variance-covariance matrix of the ATETs{p_end}
{p2colreset}{...}

