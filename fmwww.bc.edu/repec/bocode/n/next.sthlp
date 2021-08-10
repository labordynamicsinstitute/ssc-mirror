{smcl}
{* *! version 1.0 30Aug2016}{...}
{* *! version 2.0 17Apr2020 (complete overhaul from Version 1.0)}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "next_new##syntax"}{...}
{viewerjumpto "Description" "next_new##description"}{...}
{viewerjumpto "Options" "next_new##options"}{...}
{viewerjumpto "Remarks" "next_new##remarks"}{...}
{viewerjumpto "Examples" "next_new##examples"}{...}
{title:Title}

{phang}
{bf:next} {hline 2} Regression discontinuity design (RDD) estimator

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:next}
varlist(min=2
max=2)
[{help if}]
[{help in}]
[fw]
[{cmd:,}
{it:options}]

{pstd}
where {it:varlist} is 
{p_end}
		{it:Y} {it:X}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt threshold(#)}}  Default value is 0.{p_end}
{synopt:{opt minorder(#)}}  Default value is 1.{p_end}
{synopt:{opt maxorder(#)}}  Default value is 3.{p_end}
{synopt:{opt bins(#)}}  Number of bins used for learning the optimal specification. Default is no binning.{p_end}
{synopt:{opt bins_graph(#)}}  Number of bins used for graphing the results. Default is no binning.{p_end}
{synopt:{opt alpha_spe(#)}}  Smoothing parameter for squared prediction errors. Default is 0.02.{p_end}
{synopt:{opt regtype(string)}}  Regression type (regress (default), logit, or probit).{p_end}
{synopt:{opt kernel(string)}}  Kernel type (all (default), uniform, triangular, or epanechnikov).{p_end}

{syntab:Reporting}
{synopt:{opt details}} Print details of the bandwidth learning for each candidate specification. {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
{cmd:next} simultaneously selects the polynomial specification and bandwidth
 that minimizes the prediction error of Y from both sides of a discontinuity threshold. 
 It achieves this selection by evaluating the combinations of polynomial order, kernel, and bandwidth 
 that perform best in estimating the next point in the observed sequence on each side of the 
 discontinuity. For more information on the algorithm, see {browse "http://evans.uw.edu/profile/long":{it:Next: Machine Learning for Regression Discontinuity}.}

{pstd} Using the best order, kernel, and bandwidth for each side, the {bf:next} command then generates a regression using this specification, 
generates an estimate of the local average treatment effect, and generates a spiffy graph.

{pstd} {bf:User Notes:}

{pstd} (1) The first variable in the varlist is the outcome of interest (Y). The second variable in the varlist is the running variable (X). 
No other variables should be included.

{pstd} (2) The graph that is produced plots the raw data (in bins if bins_graph(#) is selected) with circles proportional to the number of observations
that are included at that value of X. The graph also plots the estimated regression specification, with the red line showing the extent of the 
left-hand-side bandwidth and blue line showing the extent of the right-hand-side bandwidth. For a nicely generated graph, 
please label your Y and X variables prior to running the {bf:next} command. 
The graph uses as a font "LM Roman 12" if this font is installed on your computer. This font can be changed by the user using Stata's Graph Editor.
The graph is not saved by the program, so the user may want to include code after the {bf:next} command to save the graph, if desired.

{pstd} (3) Frequency weights can be used. If you have already collapsed your data into bins, then the frequency weight should be the count of the number
of observations that are included in the bin.

{pstd} (4) Threshold is the threshold for receiving treatment. It is assumed that an observation with X=Threshold is on the right side of the discontinuity. 
If an observation that is exactly at the threshold should be considered to be with the group on the left side of the discontinuity, 
set the Threshold to be Threshold+Epsilon, where Epsilon is a very small number that will successfully cleave the treatment and control groups 
into two approriate parts. (Alternatively, generate a new variable that is -X (i.e., reverse the order of X) and apply the {bf:next} command using this 
tranformed variable).

{pstd} (5) minorder (maxorder) defines the minimum (maximum) order of the polynomial that you wish to be considered as a candidate specification. 
The minimum number of observations on each side must equal 5+maxorder.
This algorithm's usefulness is limited if there are a small number of distinct values of X as there is little scope for learning.

{pstd} (6) This program is slow, particularly if you have a lot of distinct values of X or if using a logit/probit specification.  
It does a lot of learning!  To get a quick feel for the data and the program, you might want to set the maxorder and the number of bins to low numbers 
(e.g., "maxorder(1) bins(20)"). The program runs a bit faster without the "details" option.

{pstd} (7) Note that the program automatically bins the data when multiple observations share the same value of X.  These observations are then weighted in
the graph. However, the raw, unbinned data are used in the final regression.

{pstd} (8) The smoothing parameter, "alpha_spe", can be set to any value >0 and <=1. A larger value will mean more smoothing, while a smaller value will put 
more emphasis on accurate predictions of the observations that are nearest to the threshold.

{pstd} (9) If the user chooses "regtype(logit)" or "regtype(probit)", the dependent variable should lie in the range 0 to 1, inclusive.

{pstd} (10) The default kernel setting is "all", which means that it will evaluate each of the following kernels: uniform, triangular, or epanechnikov. 
If you with to force one particular kernel to be used on both sides of the discontinuity, then use the option "kernel(uniform)", "kernel(triangular)", or
"kernel(epanechnikov)". 

{pstd} (11) In the unusual case where Y is constant across a consecutive series of X values near the threshold, the algorithm with "learn" that the best 
specification is uniform with a narrow bandwidth as this produces a perfect prediction at this Y-bar.  To avoid this result, you might want to bin the data.

{pstd} (12) This program produces an RD estimate assuming a strict cutoff.  For those seeking to produce an estimate in the context of a Fuzzy RD design, this 
program can be used to generate the appropriate specification as the first stage in an instrumental variable estimation approach.

{title:Example}

{pstd}Setup (data from Jacob et al., 2012, with simulated treatment effect of -10 at threshold=215){p_end}
{col 9}{stata `"import excel using https://www.mdrc.org/sites/default/files/img/RDD_Guide_Dataset_0.xls, firstrow sheet("Data")"' : import excel using https://www.mdrc.org/sites/default/files/img/RDD_Guide_Dataset_0.xls, firstrow sheet("Data")}
{col 9}{stata `"label var posttest "7th Grade Math Posttest Score"' : label var posttest "7th Grade Math Posttest Score"}
{col 9}{stata `"label var pretest "7th Grade Math Pretest Score"' : label var pretest "7th Grade Math Pretest Score"}

{pstd}Run regression discontinuity analysis with default settings, except threshold set at 215 (as in Jacob et al., 2012, data grouped into 30 roughly equal bins and restricting the analysis to a quadratic or lower order polynomial.){p_end}
{col 9}{stata "next posttest pretest, threshold(215)" : next posttest pretest, threshold(215)}

{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(LATE)}}  {p_end}
{synopt:{cmd:e(LATE_t)}}  {p_end}
{synopt:{cmd:e(LATE_se)}}  {p_end}
{synopt:{cmd:e(LATE_p)}}  {p_end}
     Logit/Probit only:
{synopt:{cmd:e(LtoR_DISCONTINUITY)}} {p_end}
{synopt:{cmd:e(LtoR__Chi2)}} {p_end}
{synopt:{cmd:e(LtoR__DISC_p)}} {p_end}

{title:Author}
{p}

{phang}
Mark C. Long, University of Washington (corresponding author){p_end}
{p2colset 10 22 24 2}{...}
{p2col:Email {browse "mailto:marklong@uw.edu":marklong@uw.edu}}{p_end}
{p2colreset}{...}
{phang}
Jordan Rooklyn, Portland Water Bureau{p_end}

{title:References}

{phang}
Long, M., and J. Rooklyn. 2020.
{browse "http://evans.uw.edu/profile/long":{it:Next: Machine Learning for Regression Discontinuity}}.
Working paper.
{p_end}

{phang}
Jacob, R.T., P. Zhu, M.A. Somers, and H. Bloom. 2012.
{browse "https://www.mdrc.org/publication/practical-guide-regression-discontinuity":{it:A Practical Guide to Regression Discontinuity}}. 
New York: MDRC.
{p_end}

{phang}
Imbens, G., and K. Kalyanaraman. 2012. 
{browse "https://doi.org/10.1093/restud/rdr043":{it:Optimal Bandwidth Choice for the Regression Discontinuity Estimator}}. Review of Economic Studies, 79(3), 933-959.
{p_end}

{phang}
Calonico, S., M. D. Cattaneo, and R. Titiunik. 2014.  
{browse "https://doi.org/10.3982/ECTA11757":{it:Robust Nonparametric Confidence Intervals for Regression-Discontinuity Designs}}.  Econometrica 82(6): 2295-2326.
{p_end}

{phang}
Calonico, S., M. D. Cattaneo, M. H. Farrell, and R. Titiunik. 2017. 
{browse "https://doi.org/10.1177%2F1536867X1701700208":{it:drobust: Software for regression-discontinuity designs}}. The Stata Journal, 17(2), 372–404.
{p_end}

{title:See Also}

{help rd} (if installed)     {stata ssc install rd} (to install this command)
{help rdrobust} (if installed)     {stata ssc install rdrobust} (to install this command)


