{smcl}
{* *! version 4.2  2026-04-24}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "medage##syntax"}{...}
{viewerjumpto "Description" "medage##description"}{...}
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
{synopt:{opt ageid(varname)}}Required; numeric ID for 5-year age groups.{p_end}
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
{bf:It assumes that} the distribution of individuals across single years of age within 
such intervals is uniform enough that linear interpolation across the interval provides 
a statistically reliable approximation of the true population median.


{marker modes}{...}
{title:Modes of Operation}

{pstd}
{cmd:1. Interactive Mode (Standard):} Used for quick analysis. When {opt saving()} is not 
specified, the command displays the (median age) for the current selection in the 
Results window. This mode supports the {cmd:by:} prefix.

{pstd}
{cmd:2. Batch Mode (Vectorized):} Optimized for large-scale projections. When {opt saving()} 
is specified, the command processes the entire dataset, calculates medians for every 
group defined in {opt by()}, and saves a new {it:.dta} file containing the results. 


{marker methods}{...}
{title:Methods and Formulas}

{pstd}
The methodology and interpolation formula are derived from {bf:The Methods and Materials 
of Demography}, edited by Jacob S. Siegel and David Swanson. The formula used for 
the interpolated median accounts for the 5-year interval width:

{p 8 12 2}
{it:Median} = {it:L} + [ ( ({it:N}/2) - {it:CF} ) / {it:f} ] * {it:i}

{pstd}
where:{p_end}
{p 8 12 2}{it:L}  = Lower limit of the median interval{p_end}
{p 8 12 2}{it:N}  = Total population{p_end}
{p 8 12 2}{it:CF} = Cumulative frequency before the median interval{p_end}
{p 8 12 2}{it:f}  = Frequency (population) within the median interval{p_end}
{p 8 12 2}{it:i}  = Width of the interval ({bf:fixed at 5 years}){p_end}


{marker options}{...}
{title:Options}

{phang}
{opt ageid(varname)} specifies the variable identifying the 5-year age groups 
(e.g., 1 = age 0-4, 2 = age 5-9 ... 20 = age 95+).

{phang}
{opt saving(filename)} creates a new Stata dataset containing only the grouping 
variables and the calculated {it:median_age}. 

{phang}
{opt by(varlist)} defines the geographical or scenario-based groups (e.g., country, 
year, religion) when using Batch Mode.


{marker examples}{...}
{title:Examples}

{pstd}Quick interactive check for a specific group:{p_end}
{phang2}{cmd:. by ctrystr scenario: medage population, ageid(ageid)}{p_end}

{pstd}Process all countries and scenarios, saving to a results file:{p_end}
{phang2}{cmd:. medage population, ageid(ageid) by(ctrystr scenario) saving(proj_results.dta) replace}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
In Interactive Mode, {cmd:medage} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(median)}}interpolated median age{p_end}
{synopt:{cmd:r(N)}}total population analyzed{p_end}


{title:Author}

{pstd}
Anne Fengyan Shi, Pew Research Center{break}
ashi@pewresearch.org

