{smcl}
{* *! version 1.5  2021-05-25}{...}
{* *  version 1.4  2020-09-05}{...}
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
{bf:bunchfilter} {hline 2} removes friction errors from data generated by a mixed continuous-discrete distribution with one mass point plus a continuously distributed friction error
according to the procedures of Bertanha, McCallum, and Seegert (2021). 
The distribution of the data with friction error is continuous and does not have a mass point. 
This type of data is common in bunching applications in economics. 
For example, the distribution of taxable income usually has a hump around the kink where marginal tax rate changes, instead of a mass point at the kink.



{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:bunchfilter}
{depvar}
{ifin}
{weight}
{cmd:,}
	 {cmdab:k:ink}({it:#}) 
	 {cmdab:deltam}({it:#}) 
	 {cmdab:deltap}({it:#}) 
	 {cmdab:gen:erate}({varname}) 
[	 
	 {cmdab:binw:idth}({it:#}) 
	 {cmdab:nopic}
	 {cmdab:pct:obs}({it:#}) 
	 {cmdab:pol:order}({it:#}) 
]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt depvar}} must be one dependent variable (the response variable in logs in many applications){p_end}
{synopt :{opt k:ink(#)}} is the location of the kink point and must be a real number in the same units as the response variable{p_end}
{synopt :{opt deltam(# real)}} is the distance between the kink point and the lower bound of the support of the friction error to be filtered;
it must be a real number in the same units as the response variable  {p_end}
{synopt :{opt deltap(# real)}} is the distance between the kink point and the upper bound of the support of the friction error to be filtered;
it must be a real number in the same units as the response variable {p_end}
{synopt :{opt gen:erate(varname)}} generates the filtered variable with a user-specified name of {it:varname}{p_end}

{syntab:Optional}
{synopt :{opt if | in}} like in any other Stata command, to restrict the working sample{p_end}
{synopt :{opt weight}} follows Stata's {help weight} syntax and only allows frequency weights, {help fweight} {p_end}
{synopt :{opt nopic}} suppresses displaying graphs; the default is to display graphs {p_end}
{synopt :{opt binw:idth}({it:#})} is the width of the bins for the histograms; it must be a strictly positive real number; 
the default value is half of what is automatically produced by the command {help histogram} {p_end}
{synopt :{opt pct:obs(# real)}} for better fit, the polynomial regression uses observations in a symmetric window around the kink point that contains {opt pctobs} percent of the sample; 
default value is 40 ({it: integer, min = 1, max = 99}){p_end}
{synopt :{opt pol:order(# integer)}} order of polynomial for the filtering regression; default value is 7 ({it:min = 2; max = 7}){p_end}




{marker description}{...}
{title:Description}

{pstd}
The user enters the variable to be filtered (for example, the log of income), 
the location of the kink, 
and size of a region around the mass point that contains the hump (in other words, kink - deltam, kink + deltap).  
{cmd:bunchfilter} fits a polynomial regression to the empirical CDF of the variable observed with error.  
This regression excludes points in the hump window and has a dummy for observations on the left or right of the kink.  
The fitted regression is used to predict values of the empirical CDF in the hump window with a jump discontinuity at the mass point.  
The filtered variable is then recovered from the inverse of the predicted CDF evaluated at the empirical CDF value for each observation in the sample.

{pstd}
This procedure works well for cases where the friction error has bounded support and only affects observations that would be at the kink in the absence of error.  
A proper deconvolution theory still needs to be developed for a filtering procedure with general validity.


{p 4 4 2}{it:Note}: You need to have a dataset with one variable drawn from a continuous distribution whose PDF clearly exhibits a hump around what would
 be a mass point in the absence of friction errors.{p_end}
 
{p 40 20 2}(Go up to {it:{help bunchfilter##syntax:Syntax}}){p_end}

{marker example}{...}
{title:Example}

{pstd}
The package includes the sample data file "bunching.dta". The income data in logs (i.e., "y") 
were simulated using a middle-censored model with an elasticity of 0.5.
The budget constraint has a kink at ln(8) with log slopes of ln(1.3) and ln(0.9), respectively, to the left and right of the kink. 
These correspond to tax rates to the left and right of the kink of -30 and 10 percent,
respectively.  
The data also include randomly generated frequency weights "w".
We introduce nonsharp bunching by adding a random error to the income of bunching
individuals. 
Such error term is a truncated normal with support [-ln(0.9), ln(1.1)],
which implies that deltam is 0.1054 and deltap is 0.0953.
The income variable with error is "yfric."
{p_end}

{p 4 8}Load the test data file included in the package:{p_end}
{p 8 8}{cmd:. use bunching}{p_end}

{p 4 8}Run {cmd: bunchfilter} with pctobs and polorder options:{p_end}
{p 8 8}{cmd:. bunchfilter yfric , generate(yfilter) kink(2.0794) deltam(0.1054) deltap(0.0953) pctobs(30) polorder(7)}{p_end}

{p 40 20 2}(Go up to {it:{help bunchfilter##syntax:Syntax}}){p_end}

{marker results}{...}
{title:Stored results}{p 50 20 2}{p_end}
{pstd}
{cmd:bunchfilter} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(filter_Bhat)}} estimated bunching mass{p_end}
{synopt:{cmd:r(filter_R2)}} R-squared of polynomial regression{p_end}
{synopt:{cmd:r(filter_vars_dropped)}} number of variables dropped out of the polynomial regression 
	in case the initial set of explanatory variables had perfect collinearity{p_end}
{synopt:{cmd:r(binwidth)}} value of bin width used in histograms; this is not stored if option {opt nopic} is stated {p_end}

	
{p 40 20 2}(Go up to {it:{help bunchfilter##syntax:Syntax}}){p_end}

{title:Authors}

{p 4 8} Marinho Bertanha, mbertanha@nd.edu, University of Notre Dame {p_end}

{p 4 8} Andrew McCallum, andrew.h.mccallum@frb.gov, Federal Reserve Board {p_end}

{p 4 8} Nathan Seegert, nathan.seegert@eccles.utah.edu, University of Utah. {p_end}

{marker reference}
{title:Reference}

{p 5 6 2}
Bertanha, M., McCallum, A., Seegert, N. (2021), "Better Bunching, Nicer Notching". Working paper SSRN 3144539.
{p_end}

{p 5 6 2}
Bertanha, M., McCallum, A., Payne, A., Seegert, N. (2021), "Bunching Estimation of Elasticities Using Stata".
Finance and Economics Discussion Series 2021-006. 
Board of Governors of the Federal Reserve System (U.S.).
{p_end}