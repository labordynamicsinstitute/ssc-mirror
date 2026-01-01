{smcl}
{* *! version 18 26Nov2025}{...}

help gpsmdpolest
{hline}

{title:Title}

{pstd} {cmd:gpsmdpolest} {hline 2} The command performs the estimation of the dose-response function

{title:Syntax}

{phang2} {cmd:gpsmdpolest} outcome treatment_dimensions {cmd:,}  {opt gpsmd(string)} {opt model(string)} {opt exogenous(varlist)} {opt file_pred(string)} {opt numboot(numlist integer max=1)}[{opt dividingint(numlist integer max=1)} {opt matrtreat(string)} {opt level(numlist max=1)} {opt cutpoints(numlist integer max=1)}  {opt index(string)}  {opt ln(varlist)} {opt matrixwithresults(string)}]

{phang} {it: outcome}: the outcome variable of interest.

{phang} {it: treatment_dimensions}: the variables storing the dimension of the treatment.

{title:Description}

{pstd}
{cmd:gpsmdpolest} The command performs the estimation of the dose-response function according to Egger and von Ehrlich (2013).
{cmd:gpsmdpolest} supports linear models where terms can be at a user-defined power. It further supports the logarithmic transformation of propensity score as well as the interactions.

{pstd}
Since the model includes the propensity score, a generated regressor (Wooldridge 2010), the t-approximation is not reliable for estimating the confidence intervals. Therefore, {cmd:gpsmdpolest} estimates confidence intervals by bootstrap (BC) (Carpenter and Bithell 2000).

{pstd}
The program does not produce any graphs. Drawing graphs in dimensions higher than two in Stata is not easy, and any graph would require some adjustments. 
Therefore, the main program's output consists of a dataset that the user can further process with programs like {help graph3d} (Rostam-Afschar and Jessen 2014) to obtain a graphical representation of the results – see also {help graph twoway contour}.

{pstd}
The command should be used together with {cmd:gpsmd}, {cmd:gpsmdcomsup}, and {cmd:gpsmdbal} to estimate the dose-response function. 

{pstd}
{it:Note}: {cmd:gpsmd} must be invoked before invoking {cmd:gpsmdpolest}. 

{title:Options}

{phang}{opt model(string)}: a string with the right side of the model.
The right side of the model must be explicitly written due to how the program parses inputs (e.g. "T1 + T2 + gps + T1*gps + T2*gps + T1^(2) + T2^2 + (gps^2) + ((T1*gps)^(2)) + (T2*gps)^2 + ln(gps) + (ln(gps))^2 + (T2*ln(gps))^2 + T2*ln(gps) "). The program does not support interactions between the dimensions of the treatment.

{phang}{opt dividingint(numlist integer max=1)}: if {opt matrtreat(string)} is not specified the program generates a matrix by dividing the dimensions in {it: dividingint} number of intervals.
The Cartesian product of the extremes of the intervals in the different dimensions constitutes the set of treatment points for which the program estimates the response.
The set of treatment points will be stored in {cmd:r(matrtreat)} as a matrix with {it:(`dividingint'+1)^|dimensions|} (where |dimensions| is the number of dimensions) rows and columns equal |dimensions|.

{phang}{opt matrtreat(string)}: The user can specify the treatment points for which she is interested in estimating the response.
Treatment points must be stored in a Stata matrix named as specified in {opt matrtreat(string)}. The matrix must have one column for each treatment dimension.
A row of the matrix identifies a single point. The user can specify only one option between {opt dividingint} and {opt matrtreat}.

{phang}{opt exogenous(varlist)}: the exogenous variables the user wants to use in the reduced equations.

{phang}{opt file_pred(string)}: As explained above, the program does not generate any graphs. It generates a dataset with the necessary information for the user to generate the desired graphs (see below for a more detailed description of the file generated).
In {opt file_pred(string)}, the user must specify the first characters of the name for the files {it:.dta} storing the results.

{phang}{opt level(numlist max=1)}: the confidence level for the confidence intervals (default 0.05).

{phang}{opt numboot(numlist integer max=1)}: the number of bootstrap samples. Since bootstrapping is the only way to obtain the confidence intervals, this is not an optional argument.

{phang}{opt cutpoints(numlist integer max=1)}: the chosen number of discrete intervals of the dimensions of the treatment for the common support estimation.
It is worth noticing that when common support is required, the program estimates the dose-response function by using only those observations that lie on the common support.
It is suggested to use the same number used to calculate the common support.

{phang}{opt index(string)}: the point {bf:t_{it:d}} where the user wants to calculate the GPS. It can be "mean" or "p50": "mean" for the mean, and "p50" for the median.

{phang}{opt ln(varlist)}: the treatment dimensions that have to be log-transformed.

{phang}{opt matrixwithresults(string)}: if the argument is “T”, the program returns a matrix called {cmd:r(returnresults)}that includes all the results as well as the chosen doses.
The default is “T”. If “F”, the matrix is not generated. This option can be helpful when the number of treatment points exceeds Stata matrix limits.

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

{phang2}Generating the outcomes:

{phang3}{cmd:. gen res= rnormal(0, 25)}

{phang3}{cmd:. gen Y = 1+ 2*T1 + 1.5*T2 + 1*X1 + 1.5*X2 + 2*X3 + 1*X4 + 1.5*X5 + 2*X6 + 1*X7 + res}

{phang2}The estimation:

{phang3}{cmd:. gpsmd T1 T2, exogenous(X1 X2 X3 X4 X5 X6 X7) gpsmd(GPS)}

{phang3}{cmd:. gpsmdcomsup T1 T2, exogenous(X1 X2 X3 X4 X5 X6 X7) index("p50") cutpoints(2) obs_notsup(Commonsupport)}

{phang3}{cmd:. gpsmdbal X1 X2 X3 X4 X5 X6 X7,  index("p50") cutpoints(2) nq_gpsmd(4) discrtreat(Discretetreat) obs_notsup(Commonsupport)}

{phang3}{cmd:. gpsmdpolest Y T1 T2, gpsmd(GPS)  exogenous(X1 X2 X3 X4 X5 X6 X7) model("T1 + T2  + GPS + T1*GPS + T2*GPS") file_pred(ExampleStata) numboot(1000) dividingint(3) index("p50") cutpoints(2)}

{hline}

{title:Stored results}

{p2col 5 20 24 2: Variables}{p_end}
{p 6 8 2}{cmd:gpsmdpolest} generates the variables specified in {opt model} but the treatment dimensions and the GPS.
All the variables are named starting with {it:__I_}, {it:__P_}, or {it:__LN_}. {it:I_} represent interaction variables and {it:P_} variables with power (variables like ((T1*GPS)^(2)) are named with both, e.g., __P_2_I_T1_GPS).
{it:LN_} represents logarithmic transformation. The user should check whether in her dataset there are variables whose names begin with these characters.
If it is the case, it is preferable to change their names before running the program.

{p2col 5 20 24 2: Datasets}{p_end}
{p 6 8 2}{cmd:gpsmdpolest} generates the following dataset:{p_end}
{p 8 10 2}- One dataset named as specified in {opt file_pred()}. It includes one row for each treatment point.
The columns store the response, the partial derivatives, and the upper and lower bound of the confidence intervals.{p_end}

{pstd}
{cmd:gpsmdbal} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(gpsmd)}}the name of the variable with the GPS estimates{p_end}
{synopt:{cmd:r(exogenous)}}the exogenous variables for the reduced equation estimation{p_end}
{synopt:{cmd:r(Dimensions)}}the dimensions of the treatment({cmd:gpsmdbal}){p_end}
{synopt:{cmd:r(listgenvar))}}the program generates the variables as specified in {opt model(string)}. This macro reports the list of the variables generated{p_end}
{synopt:{cmd:r(regmodel)}}the command for the regression for the polynomial estimation{p_end}
{synopt:{cmd:r(cmd)}}macro with the command{p_end}
{synopt:{cmd:r(cmdline)}}macro with the {it:cdmline}. This macro reports the command just invoked, including options and specifications{p_end}
{synopt:{cmd:r(Outcome)}}macro containing the name of the outcome variable{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(matrtreat)}}a matrix with the treatment points for which the dose-response has been estimated{p_end}
{synopt:{cmd:r(returnresults)}}if {opt matrixwithresults(string)} is equal to "T", the program returns a matrix with the same information included in {it: `file_pred’.dta}.


{title:Bibliography and Sources}

{p}Carpenter, James, and John Bithell. 2000. ‘Bootstrap Confidence Intervals: When, Which, What? A Practical Guide for Medical Statisticians’. {it:Statistics in Medicine} 19 (9). Wiley Online Library: 1141–64.

{p}Egger, Peter H., and Maximilian von Ehrlich. 2013. ‘Generalized Propensity Scores for Multiple Continuous Treatment Variables’. {it:Economics Letters} 119 (1): 32–34.

{p}Egger, Peter H., and Peter Egger. 2016. ‘Heterogeneous Effects of Tariff and Nontariff Policy Barriers in General Equilibrium’. Beiträge zur Jahrestagung des Vereins für Socialpolitik 2016: Demographischer Wandel - Session: Trade Barriers, No. G18-V3, ZBW - Deutsche Zentralbibliothek für Wirtschaftswissenschaften, Leibniz-Informationszentrum Wirtschaft, Kiel und Hamburg.

{p}Egger, Peter H., Maximilian v. Ehrlich, and Douglas R. Nelson. 2020. ‘The Trade Effects of Skilled versus Unskilled Migration’. {it:Journal of Comparative Economics} 48 (2): 448–64.

{p}Leuven, Edwin, and Barbara Sianesi. 2003. ‘PSMATCH2: Stata Module to Perform Full Mahalanobis and Propensity Score Matching, Common Support Graphing, and Covariate Imbalance Testing’.

{p}Präg, Patrick. 2019. ‘Visualizing Individual Outcomes of Social Mobility Using Heatmaps’. {it:Socius} 5 (January). SAGE Publications: 1-2.

{p}Rostam-Afschar, Davud, and Robin Jessen. 2014. ‘GRAPH3D: Stata Module to Draw Colored, Scalable, Rotatable 3D Plots’. Boston College Department of Economics.

{p}Wooldridge, Jeffrey M. 2010. Econometric Analysis of Cross Section and Panel Data. MIT press.






