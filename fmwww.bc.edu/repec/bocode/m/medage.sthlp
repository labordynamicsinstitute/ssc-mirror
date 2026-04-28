{smcl}
{* *! version 4.4  2026-04-25}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "medage##syntax"}{...}
{viewerjumpto "Description" "medage##description"}{...}
{viewerjumpto "Data Structure" "medage##structure"}{...}
{viewerjumpto "Modes" "medage##modes"}{...}
{viewerjumpto "Methods" "medage##methods"}{...}
{viewerjumpto "Options" "medage##options"}{...}
{viewerjumpto "Examples" "medage##examples"}{...}
{viewerjumpto "Stored results" "medage##results"}{...}
{title:Title}

{phang}
{bf:medage} {hline 2} Calculate linear interpolated median age from 5-year age group data.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:medage} {varname} {ifin} {cmd:,} {opt ageid(varname)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ageid(varname)}}Required; numeric ID for 5-year age groups (e.g., 1=0-4, 2=5-9).{p_end}
{synopt:{opt saving(filename)}}Save results to a new Stata dataset (Batch Mode).{p_end}
{synopt:{opt by(varlist)}}Variables defining groups for Batch Mode.{p_end}
{synopt:{opt replace}}Overwrite existing file in Batch Mode.{p_end}
{synoptline}
{p 4 6 2}The command is {cmd:byable(recall)} for interactive use.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:medage} is a professional demographic tool designed to estimate the median age from 
population data aggregated into 5-year age intervals (e.g., 0-4, 5-9, 10-14, ..., 95+). 
It assumes that the distribution of individuals across single years of age within 
such intervals is uniform enough that linear interpolation across the interval provides 
a statistically reliable approximation of the true population median.


{marker structure}{...}
{title:Data Structure and Pre-processing}

{pstd}
{cmd:medage} requires the dataset to be collapsed to the unit of analysis. For each 
unique combination of variables in {opt by()} (Batch Mode) or for the current selection 
(Interactive Mode), there must be exactly {bf:one observation per age group}.

{pstd}
{bf:Note on Validation:} To ensure demographic accuracy, {cmd:medage} performs a 
structural check before calculation. If multiple observations are found for the 
same {opt ageid} within a group, the command will issue {bf:error 459} and exit.

{pstd}
If the data contains multiple records per ageid (e.g., population by province when 
calculating a national or regional median), you must {cmd:collapse} the data first:

{phang2}{cmd:. collapse (sum) population, by(region scenario year ageid)}{p_end}
{phang2}{cmd:. medage population, ageid(ageid) by(region scenario year) saving(results.dta)}{p_end}


{marker modes}{...}
{title:Modes of Operation}

{pstd}
{cmd:1. Interactive Mode:} Used for quick analysis. When {opt saving()} is not 
specified, the command displays results in the Results window. Supports {cmd:by:}.

{pstd}
{cmd:2. Batch Mode (Vectorized):} Optimized for large-scale projections. Processes 
every group defined in {opt by()} and saves results to a new {it:.dta} file. 


{marker methods}{...}
{title:Methods and Formulas}

{pstd}
Derived from {bf:The Methods and Materials of Demography} (Siegel and Swanson):

{p 8 12 2}
{it:Median} = {it:L} + [ ( ({it:N}/2) - {it:CF} ) / {it:f} ] * 5

{pstd}
where:{p_end}
{p 8 12 2}{it:L}  = Lower limit of the median interval{p_end}
{p 8 12 2}{it:N}  = Total population{p_end}
{p 8 12 2}{it:CF} = Cumulative frequency before the median interval{p_end}
{p 8 12 2}{it:f}  = Frequency (population) within the median interval{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Quick interactive check for a specific group (ensure sorted by group):{p_end}
{phang2}{cmd:. bysort ctrystr scenario: medage population, ageid(ageid)}{p_end}

{pstd}Process all countries and scenarios, saving to a results file:{p_end}
{phang2}{cmd:. medage population, ageid(ageid) by(ctrystr scenario) saving(proj_results.dta) replace}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:medage} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(median)}}interpolated median age{p_end}
{synopt:{cmd:r(N)}}total population analyzed{p_end}


{title:Author}

{pstd}
Anne Fengyan Shi, Pew Research Center{break}
ashi@pewresearch.org

{break}

