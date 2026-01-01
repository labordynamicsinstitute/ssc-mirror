{smcl}
{* *! version: 7 02Oct2024}{...}

help gpsmd
{hline}

{title:Title}

{pstd} {cmd:gpsmd} {hline 2} Estimation of the generalized propensity score for multi-dimensional continuous treatment 

{marker syntax}{...}
{title:Syntax}

{phang2} {cmd:gpsmd} {varlist}(min=1){cmd:,} {opt exogenous(varlist)} {opt gpsmd(string)} [{opt chosenpoint(string)} {opt ln(varlist)}]

{phang} {it: varlist}: the dimensions of the treatment.

{title:Description}

{pstd}
{cmd:gpsmd} estimates the generalized propensity score for multidimensional continuous treatment as described in Egger and von Ehrlich (2013).
The multidimensional continuous treatment is conceived as a vector whose dimensions are specified in {it:varlist}.
The command should be used together with {cmd:gpsmdcomsup}, {cmd:gpsmdbal}, and {cmd:gpsmdpolest} to estimate the dose-response function. 

{title:Options}

{phang}{opt exogenous(varlist)}: the list of the exogenous variable and their possible interactions and powers, depending on the model the user has in mind.

{phang}{opt gpsmd(string)}: the name for the variable where the generated propensity score will be stored.

{phang}{opt chosenpoint(string)}: the name of the Stata column vector with the point at which the propensity score must be computed (mostly for programs).
It is an option that enables the user to generate the propensity score calculated at a given point. It generates g({bf:t}, {bf: Z_i}) instead of g({bf:T_i}, {bf: Z_i}).

{phang}{opt ln(varlist)}: the treatment dimensions that have to be log-transformed.

{title:Examples}
{hline}
{pstd}Setup

{phang2}Setting the dataset:

{phang3}{cmd:. clear all}

{phang3}{cmd:. set obs 1200}

{phang2}Generating independent variables for the propensity score estimation:

{phang3}{cmd:. seed 13131}

{phang3}{cmd:. gen X1 = 1* rnormal(0,1)}

{phang3}{cmd:. gen X2 = 2* rnormal(0,1)}

{phang3}{cmd:. gen X3 = 3* rnormal(0,1)}

{phang3}{cmd:. gen X4 = 4* rnormal(0,1)}

{phang3}{cmd:. gen X5 = 5* rnormal(0,1)}

{phang3}{cmd:. gen X6 = 6* rnormal(0,1)}

{phang3}{cmd:. gen X7 = 7* rnormal(0,1)}

{phang2}Generating the treatment dimensions:

{phang3}{cmd:. matrix R = (25, 2 \2, 25)}

{phang3}{cmd:. drawnorm V1 V2, cov(R)}

{phang3}{cmd:. gen T1= 1*X1 + .5*X2 + 1*X3 + .5*X4 + 1*X5 + .5*X6 + 1*X7 + V1}

{phang3}{cmd:. gen T2= .5*X1 + 1*X2 + .5*X3 + 1*X4 + .5*X5 + 1*X6 + .5*X7 + V2}

{phang2}The estimation:

{phang3}{cmd:. gpsmd T1 T2, exogenous(X1 X2 X3 X4 X5 X6 X7) gpsmd(GPS)}

{hline}

{title:Stored results}

{p2col 5 20 24 2: Variables}{p_end}
{p 6 4 2}{cmd:gpsmd} generates a variable named as specified in {opt gpsmd(string)} with the estimated propensity score.

{pstd}
{cmd:gpsmd} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(gpsmdvar)}}macro with the string in the option {opt gpsmdvar(string)}{p_end}
{synopt:{cmd:r(Exogenous)}}macro with the varlist in the option {opt exogenous(varlist)}.{p_end}
{synopt:{cmd:r(Dimensions)}}macro with the varlist of the dimensions of the treatment.{p_end}
{synopt:{cmd:r(cmdline#)}}macro with the {it:cdmline} of the reduced equation for dimension #. The user may want to run again only one of the regressions and focus on those results. This macro enables to do it easily.{p_end}
{synopt:{cmd:r(cmd)}}macro with the name of the command just invoked ({cmd:gpsmd}){p_end}
{synopt:{cmd:r(cmdline)}}macro with the cdmline. This macro reports the command just invoked, including options and specifications{p_end}
{synopt:{cmd:r(chosenpoint)}}macro with the name of the column vector with the chosen point{p_end}
{synopt:{cmd:r(LNVarCreated)}}if the {opt ln(varlist)} option is specified, the program generates variables named LN_var consisting of the logarithmic transformation of the variables in the varlist. {cmd: r(LNVarCreated)} contains the list of the variable generated{p_end}
{synopt:{cmd:r(DimensionsFS)}}macro with the name of the dimension used in calculating the propensity score. It differs from {cmd: r(Dimensions)} only if the {opt ln(varlist)} option is used{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(VarCov)}}the estimated variance-covariance matrix{p_end}


{title:Bibliography and Sources}

{p}Egger, Peter H., and Maximilian von Ehrlich. 2013. ‘Generalized Propensity Scores for Multiple Continuous Treatment Variables’. {it: Economics Letters} 119 (1): 32–34.








