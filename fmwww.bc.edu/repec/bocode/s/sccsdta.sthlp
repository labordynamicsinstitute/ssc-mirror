{smcl}
{* *! version 1.1  24 May 2024}{...}
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
{synopt:{opt en:ter}({varname|number})} Start of the individual observation period.

{synopt:{opt r:iskpoints(numlist sort)}} End points of intervals at risk.{break}
First value is the starting point of the first at risk interval.{break}
The rest of the values are the last point of an at risk interval.{break}
All intervals include their last end points.

{synopt:{opt t:imepoints(numlist sort)}} At least one interval end point(s) 
for time dependence.{break}
The first time interval starts with {opt en:ter}.{break}
The end points are relative to {opt en:ter} unless 
option {opt a:bsolutetimepoints} is set.
The last time interval end is also the end of the individual observation period
unless the option {opt:ex:it} is set.{break}
All intervals include their last end points.

{syntab:Optional}
{synopt:{opt ex:it(varname)}}  A variable for the absolute last end point in the observation period.

{synopt:{opt a:bsolutetimepoints}}  Treat the time end points in 
{opt t:imepoints} as absolute.

{synopt:{opt nor:egression}} The regression output can be ignored by this option.

{synopt:{opt noq:uietly}}  See the code run in the result window.

{synopt:{opt *:}}  Add options for the used {help xtpoisson:xtpoisson} command.

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
determined..{break}
The command {cmd:sccsdta} reports the output from a {help xtpoisson:xtpoisson} 
where data are {help xtset:xtset} by the generated variable {it:_rowid}.{break}
However, the undocumented old version of {help xtpoisson:xtpoisson} using the 
option {opt i:} for the {help xtset:xtset}-setting.

{marker examples}{...}
{title:Examples}

{phang}The datasets used below are readable from version 15.1.{break}
Version 12 datasets with the same data are added to the package.{p_end}

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


{phang}{bf:Case 3.1 in 2005 Whitaker continued}{break}
The observation period was from the 366th to the 730th day of age.{break}
Evidence led to the definition of the risk period as the 15th to the 35th day 
following the administration of the MMR vaccine.{break}
Time groups were 366 to 547 (relative endpoint 182) days and 548 to 730 
days (relative endpoint 365).{p_end}

{phang}Generate the SCCS dataset and do the analysis using absolute time end points:{p_end}
{phang}{stata `". sccsdta eventday exday, enter(365) riskpoints(14 35) timepoints(547 730) absolutetimepoints nolog"'}{p_end}

{phang}or with relative time end points:{p_end}
{phang}{stata `". use eventday exday using "https://sccs-studies.info/uploads/1/1/6/4/116436421/oxford.dta", clear"'}{p_end}
{phang}{stata `". sccsdta eventday exday, enter(365) riskpoints(14 35) timepoints(182 365) nolog"'}{p_end}

     . xtpoisson _nevents i._exgr i._tmgr, fe i(_rowid) exposure(_interval) irr nolog
     
     
     Conditional fixed-effects Poisson regression         Number of obs    =     38
     Group variable: _id                                  Number of groups =     10
     
                                                          Obs per group:
                                                                       min =      2
                                                                       avg =    3.8
                                                                       max =      4
     
                                                          Wald chi2(2)     =  19.10
     Log likelihood = -10.088277                          Prob > chi2      = 0.0001
     
     ------------------------------------------------------------------------------
         _nevents |        IRR   Std. err.      z    P>|z|     [95% conf. interval]
     -------------+----------------------------------------------------------------
            _exgr |
        ]14; 35]  |     12.037      8.528     3.51    0.00        3.002      48.259
                  |
            _tmgr |
      ]182; 365]  |      0.225      0.252    -1.33    0.18        0.025       2.016
     ln(_inter~l) |      1.000  (exposure)
     ------------------------------------------------------------------------------

{phang}We estimate the incidence rate ratio of the risk period versus the no 
risk period using a poisson regression and looking at the {it:i._exgr} estimate:{p_end}
{phang}Compare the {it:i._exgr} estimate with the Stata output at page 11 in 
2005 Whitaker.
{p_end}

{phang}{bf:Conclusion}{break}
The incidence rate in the risk period is around 12 times higher
than in the no-risk period.{break}
Hence, there is a a association between MMR vaccination and viral meningitis.{p_end} 

{phang}Reproducing Table V in 2005 Whitaker:{p_end}
{phang}{stata `". use * using "https://sccs-studies.info/uploads/1/1/6/4/116436421/itp.dta", clear"'}{p_end}
{phang}{stata `". sccsdta eventday mmr, en(cutp1) ex(cutp2) r(-1 14 28 42) t(426(61)670) a nolog"'}{p_end}

{phang}Reproducing Table VII, analyses 1 in 2005 Whitaker:{p_end}
{phang}{stata `". use * using "https://sccs-studies.info/uploads/1/1/6/4/116436421/intuss.dta", clear"'}{p_end}
{phang}{stata `". sccsdta eventday agep3, en(cutp1) ex(cutp2) r(13 27 41) t(57(30)117 148(31)334) a nolog"'}{p_end}


{title:Variables in the generated dataset}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Created variables}{p_end}
{synopt:{cmd:_rowid}}  A row id variable{p_end}
{synopt:{cmd:_start}}  Interval start value (not included in interval){p_end}
{synopt:{cmd:_stop}}  Interval stop value (included in interval){p_end}
{synopt:{cmd:_nevents}}  Number of events per individual in interval{p_end}
{synopt:{cmd:_exgr}}  Intervals marked by risk groups{p_end}
{synopt:{cmd:_tmgr}}  Intervals marked by time groups{p_end}
{synopt:{cmd:_interval}}  Interval width (the exposure){p_end}

{title:Stored results}

{synopt:{cmd:cmd}}  The regression {help xtpoisson:xtpoisson} command.{p_end}


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



