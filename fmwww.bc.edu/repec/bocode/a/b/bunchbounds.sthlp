{smcl}
{* *! version 1.7  2022-03-24}{...}
{* *  version 1.6  2021-05-25}{...}
{* *  version 1.5  2021-05-11}{...}
{* *  version 1.4  2020-06-02}{...}
{* *  version 1.3  2020-05-21}{...}
{* *  version 1.2  2019-12-19}{...}
{* * version 1.0  2019-11-05}{...}
{findalias asfradohelp}{...}
{vieweralsosee "[R] help" "help help"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] bunching" "help bunching"}{...}
{vieweralsosee "[R] bunchfilter" "help bunchfilter"}{...}
{vieweralsosee "[R] bunchtobit" "help bunchtobit"}{...}
{viewerjumpto "Syntax" "bunchbounds##syntax"}{...}
{viewerjumpto "Description" "bunchbounds##description"}{...}
{viewerjumpto "Stored results" "bunchbounds##results"}{...}
{viewerjumpto "Reference" "bunchbounds##reference"}{...}
{title:Title}

{phang}
{bf:bunchbounds} {hline 2} uses bunching to partially identify the elasticity of a response variable
with respect to changes in the slope of the budget set
according to the procedures of Bertanha, McCallum, and Seegert (2022). 




{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:bunchbounds}
{depvar}
{ifin}
{weight}
{cmd:,}
	 {cmdab:k:ink}({it:#}) 
	 {cmdab:s0}({it:#}) 
	 {cmdab:s1}({it:#}) 
	 {cmdab:m}({it:#}) 	 
[	 {cmdab:nopic}
	 {cmdab:savingbounds}({it:filename}[,{it:replace}]) 
]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt depvar}} must be one dependent variable (the response variable in logs in many applications){p_end}
{synopt :{opt k:ink(#)}} is the location of the kink point and must be a real number in the same units as the response variable{p_end}
{synopt :{opt s0(#)}} is a real number; in many applications, it is the log of the slope before the kink point{p_end}
{synopt :{opt s1(#)}} must be a real number that is strictly less than {opt s0}; in many applications, it is the log of the slope after the kink point{p_end}
{synopt :{opt m(#)}} is the maximum slope magnitude of the probability density function (PDF) of the unobserved heterogeneity, a strictly positive scalar{p_end}


{syntab:Optional}
{synopt :{opt if | in}} like in any other Stata command, to restrict the working sample{p_end}
{synopt :{opt weight}} follows Stata's {help weight} syntax and only allows frequency weights, {help fweight} {p_end}
{synopt :{opt nopic}} suppresses displaying graphs; the default is to display graphs {p_end}
{synopt :{opt savingbounds}({it:filename}[,{it:replace}])} saves {it: filename.dta} with coordinates of the partially-identified set as a function 
of the slope magnitude of the heterogeneity PDF;  use {it: replace} if {it: filename.dta} already exists in the working directory {p_end}
{synoptline}



{marker description}{...}
{title:Description}

{pstd}
The user enters the name of the response variable, the location of the kink point, the slopes before and after the kink point,
and the maximum slope magnitude of the heterogeneity PDF.
For example, in the income-tax application of Bertanha, McCallum, and Seegert (2022), dollars of taxable income and the dollar value of the kink point 
are transformed by taking logs, and the slopes must be input as the log of one minus the marginal tax rates.  
You need to have a dataset with the response variable drawn from a mixed continuous-discrete distribution. The distribution is continuous except for the 
{it:kink} value, which has a positive mass point. 
The proportion of values at the {it:kink} value must be positive in your sample.
Check to see if {cmd:count if y==kink} (where {it:y} is the response variable) gives you the right number. In case it gives you zero when it should not, check the 
value of the {it:kink} and if {it:y} is type {it:double}.

{pstd}
{cmd:bunchbounds} computes the maximum and minimum values of the elasticity that are consistent with the slope restriction on the PDF specified in {opt m},
the observed distribution of the response variable, and values of the PDF of the response variable evaluated at the left and right limits approaching the kink. 
These limits are computed non-parametrically using the method of Cattaneo, Jansson and Ma (2020) as implemented by their Stata package {cmd:lpdensity},
discussed by Cattaneo, Jansson and Ma (2021). 
Thus, the user needs to install {cmd:lpdensity} before using {cmd:bunchbounds}.

{pstd}
It is important to emphasize that the true value of the slope magnitude is unknowable but {cmd:bunchbounds} provides four sample values as suggestions for the user.
The first two sample values are estimated using the continuous part of the distribution. 
Specifically, minimum and maximum slope magnitude sample values are constructed from a histogram of the dependent variable that excludes the kink point
and uses a bin width that is half of the default bin width for the command {help histogram}.
The third sample value is the maximum slope magnitude that results in a finite upper bound on the elasticity. 
The fourth sample value is the minimum slope magnitude for which the elasticity bounds exist and are equal.
This is the same elasticity estimate that one obtains with the trapezoidal approximation.
{cmd:bunchbounds} outputs elasticity bounds for three values of the slope: trapezoidal approximation, user-provided slope magnitude {opt m}, 
and the maximum slope magnitude that results in a finite upper bound.


{marker example}{...}
{title:Example}

{pstd}
The package includes the sample data file "bunching.dta". The income data in logs (i.e., "y") 
were simulated using a middle-censored model with an elasticity of 0.5.
The budget constraint has a kink at ln(8) with log slopes of ln(1.3) and ln(0.9), respectively, to the left and right of the kink. 
These correspond to tax rates to the left and right of the kink of -30 and 10 percent,
respectively. 
The data also include randomly generated frequency weights "w".
{p_end}

{p 4 8}Load the test data file included in the package:{p_end}
{p 8 8}{cmd:. use bunching}{p_end}

{p 4 8}Run {cmd: bunchbounds} with frequency weights and save graph points in a dta file:{p_end}
{p 8 8}{cmd:. bunchbounds y [fweight=w], k(2.0794) s0(0.2624) s1(-0.1054) m(2) savingbounds(dbounds.dta, replace)}{p_end}

{p 40 20 2}(Go up to {it:{help bunchbounds##syntax:Syntax}}){p_end}

{marker results}{...}
{title:Stored results}{p 50 20 2}{p_end}
{pstd}
{cmd:bunchbounds} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(bounds_e_trap)}}estimated elasticity using trapezoidal approximation{p_end}
{synopt:{cmd:r(bounds_emin_mmax)}}lower bound estimate for the elasticity using constant {it:m} entered by user{p_end}
{synopt:{cmd:r(bounds_emax_mmax)}}upper bound estimate for the elasticity using constant {it:m} entered by user{p_end}
{synopt:{cmd:r(bounds_M_hat)}}if the heterogeneity PDF has a maximum slope magnitude greater than {it:M_hat}, then we 
cannot rule out PDFs that equal zero inside the bunching interval; 
in this case, the upper bound is infinity{p_end}
{synopt:{cmd:r(bounds_M_min_hat)}}if the heterogeneity PDF has a maximum slope magnitude smaller than {it:M_min_hat}, 
then no heterogeneity PDF is consistent with the observed distribution of income; 
bounds are not defined{p_end}
{synopt:{cmd:r(bounds_M_data_min)}}minimum value of the slope magnitude in the estimated PDF of the observed distribution of income (continuous part of the PDF){p_end}
{synopt:{cmd:r(bounds_M_data_max)}}maximum value of the slope magnitude in the estimated PDF of the observed distribution of income (continuous part of the PDF){p_end}
{synopt:{cmd:r(bounds_emin_mhat)}}lower bound estimate for the elasticity if the choice of {it:m} were equal to {it:M_hat}; 
available only when the choice of {it:m} entered by user is bigger than {it:M_hat}{p_end}
{synopt:{cmd:r(bounds_emax_mhat)}}upper bound estimate for the elasticity if the choice of {it:m} were equal to {it:M_hat}; 
available only when the choice of {it:m} entered by user is bigger than {it:M_hat}{p_end}

	
{p 40 20 2}(Go up to {it:{help bunchbounds##syntax:Syntax}}){p_end}

{title:Authors}

{p 4 8} Marinho Bertanha, mbertanha@nd.edu, University of Notre Dame {p_end}

{p 4 8} Andrew McCallum, andrew.h.mccallum@frb.gov, Federal Reserve Board {p_end}

{p 4 8} Nathan Seegert, nathan.seegert@eccles.utah.edu, University of Utah. {p_end}


{marker reference}
{title:Reference}

{p 5 6 2}
Bertanha, M., McCallum, A., Seegert, N. (2022), "Better Bunching, Nicer Notching". Working paper SSRN 3144539.
{p_end}

{p 5 6 2}
Bertanha, M., McCallum, A., Payne, A., Seegert, N. (2022), "Bunching Estimation of Elasticities Using Stata".
Stata Journal, forthcoming. 
{p_end}

{p 5 6 2}
Cattaneo, M., Jansson, M., Ma, X. (2020), "Simple Local Polynomial Density Estimators".
Journal of the American Statistical Association 115(531), pg 1449 - 1455. 
{p_end}

{p 5 6 2}
Cattaneo, M., Jansson, M., Ma, X. (2022), "lpdensity: Local Polynomial Density Estimation and Inference".
Journal of Statistical Software 101(2): 1-25, January 2022.
{browse "https://nppackages.github.io/lpdensity/":https://nppackages.github.io/lpdensity/}
{p_end}
