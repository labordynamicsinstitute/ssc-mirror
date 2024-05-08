{smcl}
{* *! version 1.0  6 May 2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install regmat" "ssc install matrixtools"}{...}
{vieweralsosee "Help regmat (if installed)" "help regmat"}{...}
{viewerjumpto "Syntax" "sccsdta##syntax"}{...}
{viewerjumpto "Description" "sccsdta##description"}{...}
{viewerjumpto "Examples" "sccsdta##examples"}{...}
{viewerjumpto "Rreferences" "sccsdta##references"}{...}
{viewerjumpto "Author and support" "sccsdta##author"}{...}
{title:Title}
{phang}
{bf:sccsdta} {hline 2} Generating the dataset for the self-controlled case series method (SCCS)

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:sccsdta}
varlist(min=2
max=2)
[{cmd:,}
{it:options}]

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required }
{synopt:{opt en:ter}} Start of the individual observation period.{break}
It is a variable name or a number.

{synopt:{opt ex:it}} Stop of the individual observation period.{break}
It is a variable name or a number.{break}
It is also the end point of the last interval.

{synopt:{opt r:iskpoints(numlist sort)}} End points of intervals at risk.{break}
First value is the starting point of the first at risk interval.{break}
The rest of the values are the last point of an at risk interval.{break}
All intervals include their last end points.

{syntab:Optional}
{synopt:{opt t:imepoints(numlist sort)}} Interval end points for time dependence.{break}
The first time interval starts with {opt en:ter}.{break}
The last time interval ends with {opt ex:it}.{break}
All intervals include their last end points.

{synopt:{opt id(varname)}}  A variable for the participants id.
{synoptline}

{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}The SCCS method examines the association between a time-varying exposure 
and an event outcome.{break}
The study samples only cases, and it requires that an event has occurred during 
the observation period.{break}
The method doesn't compare incidences for cases with incidences for references.{break} 
Instead, it contrasts incidences in periods of risk with incidences in periods 
where the case is not at risk.{break}
In this approach, cases serve as their control for fixed confounders.{break}
It's feasible to adjust for time effects such as age.{break}
The intervals are marked by risk, time, and individual.{break}
For each interval, the number of incidences and the width of the interval are 
determined.

{marker examples}{...}
{title:Examples}

{phang}{bf:Case 3.1 in 2005 Whitaker}{break}
Hospital records indicate a association between MMR vaccination and viral meningitis.{break} 
Specifically, the use of a certain live mumps vaccine, known as the Urabe strain, 
has been linked to an increased risk of viral meningitis.{break}
Instances of viral meningitis were identified in 10 children during their second 
year of life. 
{p_end}

{phang}Get a dataset with an event day (day of meningitis) and a day for exposure
(day of vaccination):{p_end}
{phang}{stata `". use eventday exday using "https://sccs-studies.info/uploads/1/1/6/4/116436421/oxford.dta", clear"'}{p_end}
{phang}This dataset is readable from version 15.1. A version 12 dataset {it:sccsdta mmr.dta} with the same data is in the package.{p_end}

{phang}{bf:Case 3.1 in 2005 Whitaker continued}{break}
The observation period was from the 366th to the 730th day of age.{break}
Evidence led to the definition of the risk period as the 15th to the 35th day 
following the administration of the MMR vaccine.{break}
Age groups were 366 to 547 days and 548 to 730 days.{p_end}

{phang}Generate the SCCS dataset:{p_end}
{phang}{stata `". sccsdta eventday exday, enter(365) exit(730) riskpoints(14 35) timepoints(547)"'}{p_end}

{phang}We estimate the incidence rate ratio of the risk period versus the no 
risk period using a poisson regression and looking at the {it:i._exgr} estimate:{p_end}
{phang}{stata `". poisson _nevents i._exgr i._tmgr i._id, exposure(_interval) irr"'}{p_end}
{phang}Compare the {it:i._exgr} estimate with the Stata output at page 11 in 
2005 Whitaker.
{p_end}

{phang}We get a better estimate report using the command {help regmat:regmat} 
({cmd:ssc install matrixtools} - works for version 13.1){p_end}
{phang}{stata `". regmat, o(_nevents) e(i._exgr) a("i._tmgr i._id") eform d(3) label btext(irr) names("") base: poisson, exposure(_interval)"'}{p_end}

    -----------------------------------------------------------------------------------
                                      irr  se(irr)  Lower 95% CI  Upper 95% CI  P value
    -----------------------------------------------------------------------------------
    Events(#)  At risk (no)         1.000                                              
               At risk (]14; 35])  12.037    2.031         3.002        48.259    0.000
    -----------------------------------------------------------------------------------

{phang}{bf:Conclusion}{break}
The incidence rate in the risk period is around 12 times higher
than in the no-risk period.{break}
Hence, there is a a association between MMR vaccination and viral meningitis.{p_end} 

{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Created variables}{p_end}
{synopt:{cmd:_start}}  Interval start value (not included in interval){p_end}
{synopt:{cmd:_stop}}  Interval stop value (included in interval){p_end}
{synopt:{cmd:_nevents}}  Number of events per individual in interval{p_end}
{synopt:{cmd:_exgr}}  Intervals marked by risk groups{p_end}
{synopt:{cmd:_tmgr}}  Intervals marked by time groups{p_end}
{synopt:{cmd:_interval}}  Interval width (the exposure){p_end}

{marker references}{...}
{title:References}

{pstd}2005 Whitaker - Tutorial in biostatistics; The self-controlled case series method
{break}2016 Petersen - Self controlled case series methods; An alternative to standard epidemiological study designs

{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}



