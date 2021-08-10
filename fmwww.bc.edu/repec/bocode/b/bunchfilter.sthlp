{smcl}
{* *! version 1.4  2020-09-05}{...}
{* *  version 1.3  2020-06-02}{...}
{* *  version 1.2  2020-05-21}{...}
{* *  version 1.1  2020-04-24}{...}
{* * version 1.0  2019-11-05}{...}
{findalias asfradohelp}{...}
{vieweralsosee "[R] help" "help help"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] bunching" "help bunching"}{...}
{vieweralsosee "[R] bunchbounds" "help bunchbounds"}{...}
{vieweralsosee "[R] bunchtobit" "help bunchtobit"}{...}
{viewerjumpto "Syntax" "bunchfilter##syntax"}{...}
{viewerjumpto "Description" "bunchfilter##description"}{...}
{viewerjumpto "Stored results" "bunchfilter##results"}{...}
{viewerjumpto "Reference" "bunchfilter##reference"}{...}
{title:Title}

{phang}
{bf:bunchfilter} {hline 2} filters out friction errors of data drawn from a mixed continuous-discrete distribution.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:bunchfilter}
{it:varname}
{ifin}
{weight}
{cmd:,}
	 {cmdab:gen:erate}({it:newvar}) 
	 {cmdab:deltam}({it:#}) 
	 {cmdab:deltap}({it:#}) 
	 {cmdab:k:ink}({it:#}) 
[	 {cmdab:nopic}
	 {cmdab:binw:idth}({it:#}) 
	 {cmdab:perc:_obs}({it:#}) 
	 {cmdab:pol:order}({it:#}) 
]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt varname}}must be one dependent variable (ln of income){p_end}
{synopt :{opt if | in}}like in any other Stata command, to restrict the working sample{p_end}

{syntab:Options}
{synopt :{opt gen:erate(newvar)}}generates the filtered variable with a user-specified name of {it:varname}{p_end}
{synopt :{opt deltam(# real)}}is the half-length of the hump window, that is, the distance between the mass point to the lower-bound of the hump window (see description below) {p_end}
{synopt :{opt deltap(# real)}}is the half-length of the hump window, that is, the distance between the mass point to the upper-bound of the hump window (see description below) {p_end}
{synopt :{opt k:ink}(# real)}is the location of the mass point{p_end}
{p2coldent :* {opt nopic}}if you state this option, then no graphs will be displayed. Default state is to have graphs displayed{p_end}
{p2coldent :* {opt binw:idth(# real)}}the width of the bins for histograms. Default value is half of what is automatically produced by the command {help histogram}.
 A strictly positive value {p_end}
{p2coldent :* {opt perc:_obs(# real)}}for better fit, the polynomial regression uses observations in a symmetric window around the kink point that contains perc_obs percent of the sample. 
Default value is 40 ({it: integer, min = 1, max = 99}){p_end}
{p2coldent :* {opt pol:order(# integer)}}maximum order of polynomial regression. Default value is 7 ({it:min = 2; max = 7}){p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:*} optional parameters {p_end}
{p 4 4 2}
only {cmd:fweight} or {cmd:fw} (frequency weights) are allowed; see {help weight} {p_end}



{marker description}{...}
{title:Description}

{pstd}
{cmd:bunchfilter} – filters out friction errors of data drawn from a mixed continuous-discrete distribution with one mass point plus a continuously distributed friction error.
 The distribution of the data with error is continuous and its probability density function (PDF) typically exhibits a hump around the location of the mass point.
 This type of data arises in bunching applications in economics, for example, the distribution of reported income usually has a hump around the kink points where marginal tax rate changes. 

{pstd}
The user enters the variable to be filtered (e.g., ln of income), the location of the mass point, 
and length of a window around the mass point that contains the hump (i.e., kink - deltam, kink + deltap).
 The procedure fits a polynomial regression to the empirical cumulative distribution function (CDF) of the variable observed with error.
 This regression excludes points in the hump window and has a dummy for observations on the left or right of the mass point.
 The fitted regression predicts values of the empirical CDF in the hump window with a jump discontinuity at the mass point.
 The filtered data equals the inverse of the predicted CDF evaluated at the empirical CDF value of each observation in the sample.

{pstd}
This procedure works well for cases where the friction error has bounded support and only affects observations that would be at the kink in the absence of error.
 A proper deconvolution theory still needs to be developed for a filtering procedure with general validity. 

{p 4 4 2}{it:Note}: You need to have a dataset with one variable drawn from a continuous distribution whose PDF clearly exhibits a hump around what would be a mass point in the absence of friction errors.{p_end}
 
{p 40 20 2}(Go up to {it:{help bunchfilter##syntax:Syntax}}){p_end}

{marker example}{...}
{title:Example}

{pstd}
The package includes the sample data file "bunching.dta. The income data in logs (i.e., "y") 
was simulated using a middle-censored model with an elasticity of 0.5.
The budget constraint has a kink at ln(8) with slopes to the right and left of 
ln(1.3) and ln(0.9), respectively. 
These correspond to tax rates to the left and right of the kink of -0.3 and 0.1,
respectively. The unobserved agent heterogeneity is a linear combination of three
binary covariates (x1, x2, and x3) plus a Gaussian error term.
We introduce nonsharp bunching by adding a random error to the income of bunching
individuals. Such error term is a truncated normal with support [-ln(0.9), ln(1.1)]
and the income variable with error is "yfric." The data also include randomly generated frequency weights "w".
{p_end}

{p 4 8}Load the test data file included in the package:{p_end}
{p 8 8}{cmd:. use bunching}{p_end}

{p 4 8}Run {cmd: bunchfilter} with perc_obs and polorder options:{p_end}
{p 8 8}{cmd:. bunchfilter yfric , generate(yfilter) kink(2.0794) deltam(0.1054) deltap(0.0953) perc_obs(30) polorder(7)}{p_end}

{p 40 20 2}(Go up to {it:{help bunchfilter##syntax:Syntax}}){p_end}

{marker results}{...}
{title:Stored results}{p 50 20 2}{p_end}
{pstd}
{cmd:bunchfilter} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(filter_Bhat)}}estimated bunching mass{p_end}
{synopt:{cmd:r(filter_R2)}}R-squared of polynomial regression{p_end}
{synopt:{cmd:r(filter_vars_dropped)}}number of variables dropped out of the polynomial regression 
	in case the initial set of explanatory variables had perfect collinearity{p_end}
{synopt:{cmd:r(binwidth)}}value of bindwidth used in histograms. This is not stored if option {opt nopic} is stated {p_end}

	
{p 40 20 2}(Go up to {it:{help bunchfilter##syntax:Syntax}}){p_end}

{title:Authors}

{p 4 8} Marinho Bertanha, mbertanha@nd.edu, University of Notre Dame {p_end}

{p 4 8} Andrew McCallum, andrew.h.mccallum@frb.gov, Federal Reserve Board {p_end}

{p 4 8} Nathan Seegert, nathan.seegert@eccles.utah.edu, University of Utah. {p_end}

{marker reference}
{title:Reference}

{p 5 6 2}
Bertanha, M., McCallum, A., Seegert, N. (2019), “Better Bunching, Nicer Notching”. Working paper SSRN 3144539. {p_end}


