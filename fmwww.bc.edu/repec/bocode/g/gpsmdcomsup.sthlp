{smcl}
{* *! version 7 02Oct2024}{...}

help gpsmdcomsup
{hline}

{title:Title}

{pstd} {cmd:gpsmdcomsup} {hline 2} Detecting observations inside common support when the treatment has multiple continuous dimensions 

{marker syntax}{...}
{title:Syntax}
 
{phang2} {cmd:gpsmdcomsup} {varlist}(min=1){cmd:,} {opt exogenous(varlist)} {opt index(string)} {opt cutpoints(numlist integer max=1)} {opt obs_notsup(string)} [{opt testing(numlist integer max=1)} {opt ln(varlist)}]

{phang} {it: varlist}: the dimensions of the treatment.

{title:Description}

{pstd}
{cmd:gpsmdcomsup} detects the observations inside common support when the treatment has multiple continuous dimensions. 
According to Flores et al. (2012) and Egger’s et al. (Peter Hannes Egger and Egger 2016; Peter H. Egger, Ehrlich, and Nelson 2020),
the common support can be selected by partitioning the treatment into an arbitrary number of subsets.
Iteratively, every discrete subset {it:d} is considered "the treatment group", while the others are considered the "control group".
For each subset {it:d}, a representative point is chosen, {bf:t_{it:d}}. There, the propensity score, g({bf:t_{it:d}}, {bf:Z_i}), is calculated for each observation in the sample.
The observations inside the common support are those observations whose propensity score is, irrespectively to the discrete subset considered as "treatment group", higher than the maximum of the minimums of “treatment” and “control” groups, as well as lower than the minimum of the maximums of “treatment” and “control” groups.

{pstd}
The command should be used together with {cmd:gpsmd}, {cmd:gpsmdbal}, and {cmd:gpsmdpolest} to estimate the dose-response function. 

{pstd}
{it: Note}: {cmd: gpsmdcomsup} is an n-class command (see {help return}}. It can be invoked after running {cmd:gpsmd} and before invoking {cmd:gpsmdbal} without incurring an error.

{title:Options}

{phang}{opt exogenous(varlist)}: exogenous variables in the same order that in the command {cmd:gpsmd}.

{phang}{opt index(string)}: the point {bf:t_{it:d}} where the user wants to calculate the GPS. It can be "mean" or "p50": "mean" for the mean, and "p50" for the median.

{phang}{opt cutpoints(numlist integer max=1)}: the number of discrete intervals of the dimensions of the treatment.

{phang}{opt obs_notsup(string)}: the name for the dummy variable taking value 1 if the observation is outside the common support and 0 if the observation is inside the common support.

{phang}{opt testing(numlist integer max=1)}: the user may want to inspect the distribution of the GPS calculated at the representative point of the discrete subsets of the treatment, g({bf:t_{it:d}}, {bf:Z_i}).
If {opt testing(numlist integer max=1)} is set to 1, the program generates one variable for each discrete subset of the treatment.
The variable stores, for all observations, the GPS calculated at the representative point of the corresponding discrete subset of the treatment.
These variables are named {it: obs_notsup#} where {it: obs_notsup} is the name specified in {opt obs_notsup(string)} and # stands for the number of the discrete subset.
The dummy variable indicating whether the observation is inside the common support is named simply as it is specified in {opt obs_notsup(string)}.

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

{phang3}{cmd:. gpsmdcomsup T1 T2, exogenous(X1 X2 X3 X4 X5 X6 X7) index("p50") cutpoints(2) obs_notsup(Commonsupport)}

{hline}

{title:Stored results}

{p2col 5 20 24 2: Variables}{p_end}
{p 6 8 2}If {cmd: testing} is different from 1, the {cmd:gpsmdcomsup} generates a variable named as in {opt obs_notsup(Commonsupport)} taking value 1 if the observation is outside the common support and value 0 if the observation is within the common support.

{p 6 8 2}If {opt testing(numlist integer max=1)} is set to 1, the program generates one variable for each discrete subset of the treatment.
The variable stores, for all observations, the GPS calculated at the representative point of the corresponding discrete subset of the treatment.
These variables are named {it: obs_notsup#}, where {it: obs_notsup} is the name specified in {opt obs_notsup(string)} and # stands for the number of the discrete subset.
The dummy variable indicating whether the observation is inside the common support is named simply as in {opt obs_notsup(string)}.

{pstd}
{cmd:gpsmdcomsup} stores the following in {cmd:r()} (directly copying {cmd:gpsmd} results):

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

{p}Egger, Peter H., and Maximilian von Ehrlich. 2013. ‘Generalized Propensity Scores for Multiple Continuous Treatment Variables’. {it:Economics Letters} 119 (1): 32–34.

{p}Egger, Peter H., and Peter Egger. 2016. ‘Heterogeneous Effects of Tariff and Nontariff Policy Barriers in General Equilibrium’. Beiträge zur Jahrestagung des Vereins für Socialpolitik 2016: Demographischer Wandel - Session: Trade Barriers, No. G18-V3, ZBW - Deutsche Zentralbibliothek für Wirtschaftswissenschaften, Leibniz-Informationszentrum Wirtschaft, Kiel und Hamburg.

{p}Egger, Peter H., Maximilian v. Ehrlich, and Douglas R. Nelson. 2020. ‘The Trade Effects of Skilled versus Unskilled Migration’. {it:Journal of Comparative Economics} 48 (2): 448–64.








