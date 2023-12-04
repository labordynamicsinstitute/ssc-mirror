{smcl}
{* *! version 1.2 29nov2023}{...}
{cmd:help xtnumfac}
{hline}

{viewerjumpto "Syntax" "xtnumfac##syntax"}{...}
{viewerjumpto "Description" "xtnumfac##description"}{...}
{viewerjumpto "Options" "xtnumfac##options"}{...}
{viewerjumpto "Remarks" "xtnumfac##remarks"}{...}
{viewerjumpto "Examples" "xtnumfac##examples"}{...}
{viewerjumpto "Results" "xtnumfac##results"}{...}


{title:Title}

{phang}
{bf:xtnumfac} Estimate the number of factors in time series and panel data

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtnumfac}
[{varlist}]
{ifin}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt kmax(#)}} Consider at most {it:#} factors; default is {cmd:kmax(8)}. {p_end}
{synopt:{opt d:etail}} Report detailed results. {p_end}
{synopt:{opt stan:dardize(#)}} Demean and/or rescale data. Default is {cmd:stan(1)} for neither demeaning nor rescaling.{p_end}

{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtnumfac} Estimates the number of factors in the variables {varlist}, observed in a large-dimensional panel dataset, by obtaining and reporting the estimators of Bai and Ng 
(2002), Ahn and Horenstein (2013), Onatski (2010) and Gagliardini et al. (2019).
Data must be {help tsset} or {help xtset}.
In case of unbalanced panels, {cmd:xtnumfac} internally fills in the gaps using {help tsfill}. 
Missing values are imputed following Stock and Watson (1998) and Bai et al. (2015).
{varlist} may contain time-series operators, see {help tsvarlist}.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt kmax(#)} specifies how many factors to consider at most when estimating its true number. The default is {cmd:kmax(8)}. The choice of kmax
mostly affects the length of the reported table of results. Additionally, the
values of the PC_{p1}, PC_{p2} and PC_{p3} statistics may be slightly affected since 
they are functions of an estimated error variance in the idiosyncratic component
which is obtained from the most general model (i.e. the one with {it: kmax} factors).

{phang}
{opt detail} allows to report extended result that show the exact values assumed by each criterion function when 
0,1,...,{it: kmax} factors are estimated. The estimator of Onatski (2010) is left out from this representation
in order to avoid confusion about how the estimated number of factors is obtained from a list of potential values.

{phang}
{opt standardize(#)} implements variable transformations prior to factor estimation. The following options are available: {break}
{it:1}: No transformations {break}
{it:2}: Remove individual fixed effects {break}
{it:3}: Remove individual fixed effects and standardize variance of each cross-section to 1 {break}
{it:4}: Remove individual and time fixed effects {break}
{it:5}: Remove individual&time fixed effects and standardize variance of each cross-section to 1 {break}



{marker remarks}{...}
{title:Remarks}
{pstd}
The methods of Bai and Ng (2002), Ahn and Horenstein (2013), Onatski (2010) and Gagliardini et al. (2019)
constitute four sets of estimators that rely on different mechanisms and that need to be 
interpreted differently. The six ICs of Bai and Ng (2002) are based on an 
adjustment to the sum of squared residuals which corrects for the optimism of the
training error. Accordingly, the estimated number of factors is determined by the 
{it: minimum} IC value among all numbers of factors under consideration.
By contrast, the two estimators of Ahn and Horenstein rely on the ratio between 
two subsequent eigenvalues (ER) or their growth rates (GR). Accordingly, the 
estimated number of factors is determined by the {it: maximum} ER or GR criterion, 
respectively.
Third, the ED (edge distribution) estimator of Onatski (2010) is based on the difference 
of two successive eigenvalues. Determining the number of factors is not achieved by picking the extremum
in a list of options. Instead, a threshold is determined from the data and the eigenvalue differences
exceeding this differences are targeted. This procedure is iterated to convergence with an updated list of eigenvalues and an updated threshold.
Lastly, the diagnostic criterion of Gagliardini et al. (2019) considers the decreasing sequence of eigenvalues minus a correction term. 
It chooses the number of factors as one less than the position of the earliest negative corrected eigenvalue in that series. 
The criterion shows {it:kmax+1} factors if no negative corrected eigenvalue is found.
 
{marker contact}{...}
{title:Contact}

{pstd}
Questions, Comments, Suggestions? Please let us know. 

{space 4}Simon Reese 
{space 4}Associate Senior Lecturer, Lund University 
{space 4}{browse "mailto:simon.reese@nek.lu.se":simon.reese@nek.lu.se}

 
{space 4}Jan Ditzen
{space 4}Free University of Bozen-Bolzano 
{space 4}{browse "mailto:jan.ditzen@unibz.it":jan.ditzen@unibz.it}
 
{marker examples}{...}
{title:Examples}

{pstd}
The following example uses the file {it:KPR2021_hpdata} which is downloaded together
with the package and which is taken from the first empirical example in Kapetanios et al. (2021)

{phang}{cmd:. use KPR2021_hpdata}{p_end}
{phang}{cmd:. xtnumfac d_lrhp, kmax(10)}{p_end}
{phang}{cmd:. xtnumfac rd_lrhp, stan(5) detail}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtnumfac} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}Number of cross-sections.{p_end}
{synopt:{cmd:e(T)}}Number of time periods.{p_end}
{synopt:{cmd:e(kmax)}}Maximum number of factors considered.{p_end}
{synopt:{cmd:e(missnum)}}Number of missing values which are imputed.{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(best_numfac)}} A (1 x 8) matrix containing the number of factors 
estimated by any of the 8 criteria. The order is as in the reported function 
output.{p_end}
{synopt:{cmd:e(allICs)}} A ({it:kmax} x 8) matrix containing the value of all measures for all numbers of
factors under consideration. Corresponds to the values in the reported function
output (albeit without asterisks).

{marker references}{...}
{title:References}

{phang}
Ahn, S. C., & Horenstein, A. R. (2013). Eigenvalue ratio test for the number of factors. {it:Econometrica}, 81(3), 1203-1227.

{phang}
Bai, J., & Ng, S. (2002). Determining the number of factors in approximate factor models. {it:Econometrica}, 70(1), 191-221.

{phang}
Bai, J., Y. Liao, & Jisheng Yang. 2015. Unbalanced Panel Data Models with Interactive Effects. In The Oxford Handbook of Panel Data, 149–170

{phang}
Gagliardini, P., Ossola, E., & Scaillet, O. (2019). A diagnostic criterion for approximate factor structure. {it: Journal of Econometrics}, 212(2), 503-521.

{phang} 
Kapetanios, G., Pesaran, M.H., & Reese, S. (2021). Detection of units with pervasive effects in large panel data models. {it: Journal of Econometrics}, 221(2),  510-541.

{phang} 
Onatski, A. 2010. Determining the Number of Factors from Empirical Distribution of Eigenvalues. {it:The Review of Economics and Statistics}, 92(4): 1004–1016.

{phang}
Stock, J. H., and M. W. Watson. 1998. Diffusion Indexes. NBER Working Paper (w6702).
