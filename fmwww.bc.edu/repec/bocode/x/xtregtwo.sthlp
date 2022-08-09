{smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:xtregtwo} {hline 2} Executes estimation of panel regression with standard errors robust to two-way clustering and serial correlation in time effects.


{marker syntax}{...}
{title:Syntax}
 
{p 4 17 2}
{cmd:xtregtwo}
{it:depvar}
[{it:indepvars}]
{ifin}
[{cmd:,} {bf:{ul:noc}onstant} {bf:fe}]


{marker description}{...}
{title:Description}

{phang}
{cmd:xtregtwo} executes estimation of linear panel regression models with standard errors robust to two-way clustering and untruncated serial correlation in common time effects.
The method is based on {browse "https://arxiv.org/abs/2201.11304":Chiang, Hansen, and Sasaki (2022)}.
The command reports the ordinary least squares estimates, robust standard errors, z values, p values, and confidence intervals.
The command runs the fixed-effect estimation by within-transformation if the {cmd:fe} option is used.


{marker options}{...}
{title:Options}

{phang}
{bf:{ul:noc}onstant} {space 1}suppress constant term
{p_end}

{phang}
{bf:fe} {space 9}fixed effects by within-transformation
{p_end}


{marker example}{...}
{title:Example}

{phang}Load the asset pricing data:

{phang}{cmd:. use "fama_french.dta"}{p_end}

{phang}Set {bf:i} and {bf:t} variables in the panel:

{phang}{cmd:. xtset i t}{p_end}

{phang}Estimation:

{phang}{cmd:. xtregtwo return mkt smb hml, fe}{p_end}


{marker stored}{...}
{title:Stored results}

{phang}
{bf:xtregtwo} stores the following in {bf:e()}: 
{p_end}

{phang}
Scalars
{p_end}
{phang2}
{bf:e(NT)} {space 9}observations
{p_end}
{phang2}
{bf:e(N)} {space 10}cross sectional units
{p_end}
{phang2}
{bf:e(T)} {space 10}time periods
{p_end}
{phang2}
{bf:e(M)} {space 10}time window for HAC estimation
{p_end}

{phang}
Macros
{p_end}
{phang2}
{bf:e(cmd)} {space 8}{bf:xtregtwo}
{p_end}
{phang2}
{bf:e(properties)} {space 1}{bf:b V}
{p_end}

{phang}
Matrices
{p_end}
{phang2}
{bf:e(b)} {space 10}coefficient vector
{p_end}
{phang2}
{bf:e(V)} {space 10}variance-covariance matrix of the estimators
{p_end}

{phang}
Functions
{p_end}
{phang2}
{bf:e(sample)} {space 5}marks estimation sample
{p_end}

{title:Reference}

{p 4 8}Chiang, H.D., B.E. Hansen, and Y. Sasaki 2022. Standard Errors for Two-Way Clustering with Serially Correlated Time Effects. Working Paper.
{browse "https://arxiv.org/abs/2201.11304":Link to Paper}.
{p_end}

{title:Authors}

{p 4 8}Harold D. Chiang, University of Wisconsin, Madison, WI.{p_end}

{p 4 8}Bruce E. Hansen, University of Wisconsin, Madison, WI.{p_end}

{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}
