{smcl}
{* *! version 1.3  2021-05-25}{...}
{* *  version 1.2  2020-06-02}{...}
{* *  version 1.1  2020-05-21}{...}
{* *  version 1.0  2020-05-05}{...}
{findalias asfradohelp}{...}
{vieweralsosee "[R] help" "help help"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] bunchfilter" "help bunchfilter"}{...}
{vieweralsosee "[R] bunchbounds" "help bunchbounds"}{...}
{vieweralsosee "[R] bunchtobit" "help bunchtobit"}{...}
{viewerjumpto "Syntax" "bunching##syntax"}{...}
{viewerjumpto "Description" "bunching##description"}{...}
{viewerjumpto "Stored results" "bunching##results"}{...}
{viewerjumpto "Reference" "bunching##reference"}{...}
{title:Title}

{phang}
{bf:bunching} {hline 2} uses bunching to partially and point identify the elasticity of a response variable with respect to
 changes in the slope of the budget set using different assumptions 
on unobserved heterogeneity  according to the procedures of Bertanha, McCallum, and Seegert (2021).
{bf:bunching} is a wrapper function for three other commands: {help bunchbounds}, {help bunchtobit}, and {help bunchfilter}.



{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:bunching}
{depvar} [{indepvars}]
{ifin}
{weight}
{cmd:,}
	 {cmdab:k:ink}({it:#}) 
	 {cmdab:s0}({it:#}) 
	 {cmdab:s1}({it:#}) 
	 {cmdab:m}({it:#}) 
[	 {cmdab:nopic}
	 {cmdab:savingbounds}({it:filename}[,{it:replace}])  
 	 {cmdab:binw:idth}({it:#})
	 {cmdab:g:rid}({it:numlist})  
	 {cmdab:n:umiter}({it:#}) 
	 {cmdab:savingtobit}({it:filename}[,{it:replace}]) 
	 {cmdab:verbose}
	 {cmdab:deltam}({it:#}) 
	 {cmdab:deltap}({it:#}) 
	 {cmdab:gen:erate}({it:newvar}) 
	 {cmdab:pct:obs}({it:#}) 
	 {cmdab:pol:order}({it:#})
]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt depvar}} must be one dependent variable (the response variable in logs in many applications){p_end}
{synopt :{opt k:ink(#)}} is the location of the kink point and must be a real number in the same units as the response variable{p_end}
{synopt :{opt s0(#)}} is a real number; in many applications, it is the log of the slope before the kink point{p_end}
{synopt :{opt s1(#)}} must be a real number that is strictly less than {opt s0}; in many applications, it is the log of the slope after the kink point{p_end}
{synopt :{opt m(#)}} is the maximum slope magnitude of the probability density function (PDF) of the unobserved heterogeneity, a strictly positive scalar
(option of {help bunchbounds}){p_end}


{syntab:Optional}
{synopt :{opt indepvars}} is a {help varlist} of covariates; heterogeneity is a linear function of these covariates and an unobserved error that is normally distributed 
	conditional on these covariates (option of {help bunchtobit}){p_end}
{synopt :{opt if | in}} like in any other Stata command, to restrict the working sample {p_end}
{synopt :{opt weight}} follows Stata's {help weight} syntax and only allows frequency weights, {help fweight} {p_end}
{synopt :{opt nopic}} suppresses displaying graphs; the default is to display graphs {p_end}
{synopt :{opt savingbounds}({it:filename}[,{it:replace}])} saves {it: filename.dta} with coordinates of the partially-identified set as a function 
	of the slope magnitude of the heterogeneity PDF;  use {it: replace} if {it: filename.dta} already exists in the working directory (option of {help bunchbounds}) {p_end}
{synopt :{opt binw:idth}({it:#})} is the width of the bins for the histograms; it must be a strictly positive real number; 
	the default value is half of what is automatically produced by the command {help histogram} {p_end}
{synopt :{opt g:rid(numlist)}} is a {help numlist} of integers from 1 to 99; 
	the values in the {opt numlist} correspond to percentages of the sample that define symmetric truncation windows around the kink point; 
	the truncated Tobit model is estimated on each of these samples
	and also the full sample so that the number of estimates is always one more than the number of entries in {opt numlist}; 
	for example, if {opt grid(15 82)}, then {cmd: bunching} estimates the Tobit model three times using 100, 82, and 15 percent of the data around the kink point; 
	the default value for the {opt numlist} is 10(10)90, which provides 10 estimates (option of {help bunchtobit}) {p_end}
{synopt :{opt n:umiter(#)}} is the maximum number of iterations allowed when maximizing the Tobit likelihood; 
	it must be a positive integer and the default is 500 (option of {help bunchtobit}) {p_end}
{synopt :{opt savingtobit}({it:filename}[,{it:replace}])} saves {it: filename.dta} with Tobit estimates for each truncation window;
	the  {it: filename.dta} file contains eight variables corresponding to the matrices that the code stores in {opt r()}; 
	see below for more details;
	use {it: replace} if {it: filename.dta} already exists in the working directory (option of {help bunchtobit}) {p_end}
{synopt :{opt verbose}} displays detailed output from the Tobit estimation including iterations of maximizing the likelihood; 
	non-verbose mode is the default (option of {help bunchtobit}) {p_end}
{synopt :{opt deltam(# real)}} is the distance between the kink point and the lower bound of the support of the friction error to be filtered;
	it must be a real number in the same units as the response variable;
	if this option is used, 
	then options {opt deltap} and {opt generate} must also be specified
	(options of {help bunchfilter}) {p_end}
{synopt :{opt deltap(# real)}} is the distance between the kink point and the upper bound of the support of the friction error to be filtered;
	it must be a real number in the same units as the response variable; 
	if this option is used, 
	then options {opt deltam} and {opt generate} must also be specified
	(options of {help bunchfilter}) 
	{p_end}
{synopt :{opt gen:erate(varname)}} generates the filtered variable with a user-specified name of {it:varname};
	if this option is used, 
	then options {opt deltam} and {opt deltap} must also be specified
	(options of {help bunchfilter}) 
	{p_end}
{synopt :{opt pct:obs(# real)}} for better fit, the polynomial regression uses observations in a symmetric window around the kink point that contains {opt pctobs} percent of the sample; 
	default value is 40 ({it: integer, min = 1, max = 99});
	if this option is used, 
	then options {opt deltam}, {opt deltap}, and {opt generate} must also be specified
	(options of {help bunchfilter}) 
	{p_end}
{synopt :{opt pol:order(# integer)}} order of polynomial for the filtering regression; default value is 7 ({it:min = 2; max = 7});
	if this option is used, 
	then options {opt deltam}, {opt deltap}, and {opt generate} must also be specified
	(options of {help bunchfilter}) 
	{p_end}


{marker description}{...}
{title:Description}

{pstd}
The user enters the name of the response variable, the location of the kink point, the slopes before and after the kink point, 
and the maximum slope magnitude of the heterogeneity PDF.
For example, in the income-tax application of Bertanha, McCallum, and Seegert (2021), dollars of taxable income and the dollar value of the kink point 
are transformed by taking logs, and the slopes must be input as the log of one minus the marginal tax rates.  
You need to have a dataset with the response variable drawn from a mixed continuous-discrete distribution.
The distribution is continuous except for the 
{it:kink} value, which has a positive mass point. 
The proportion of values at the {it:kink} value must be positive in your sample.
Check to see if {cmd:count if y==kink} (where {it:y} is the response variable) gives you the right number. In case it gives you zero when it should not, check the 
value of the {it:kink} and if {it:y} is type {it:double}.
In case your dependent variable is such that the bunching mass is dispersed in a neighborhood around the {it:kink} point because of friction errors,
 please refer to the last paragraph of this description.


{pstd}
First, {cmd: bunching} calls {help bunchbounds}. 
{cmd:bunchbounds} computes the maximum and minimum values of the elasticity that are consistent with the slope restriction on the PDF specified in {opt m},
the observed distribution of the response variable, and values of the PDF of the response variable evaluated at the left and right limits approaching the kink. 


{pstd}
Second, the code runs {help bunchtobit}.
{cmd: bunchtobit} estimates multiple mid-censored Tobit regressions using specified sub-samples of the data.
It starts with the entire sample, then it truncates the sample to symmetric windows centered at the kink as specified by the user. 
The elasticity estimate is plotted as a function of the percentage of data used in each truncation window. 
The code also plots the histogram of the response variable along with the best-fit Tobit distribution for each truncation window.
The user has the option of entering covariates that help explain the unobserved heterogeneity.


{pstd}
In case there are friction errors in the dependent variable and the the bunching mass is dispersed in a neighborhood around the {it:kink} point,
the user must specify the following three options together: {opt generate}, {opt deltam}, and {opt deltap}.
{cmd: bunching} will then run {help bunchfilter} before {help bunchbounds} and {help bunchtobit} and generate a variable without 
friction errors. 
The distribution of the data with error is continuous and its PDF typically exhibits a hump around the location of the mass point. 
The distribution without error is 
mixed continuous-discrete with one mass point at the kink.
The option {opt generate} specifies the name of the new variable without friction errors.
Options {opt deltam} and {opt deltap} specify the window around the mass point that contains the hump, that is, {it:(kink - deltam, kink + deltap)}.



{p 40 20 2}(Go up to {it:{help bunching##syntax:Syntax}}){p_end}

{marker examples}{...}
{title:Examples}

{pstd}
The package includes the sample data file "bunching.dta". The income data in logs (i.e., "y") 
were simulated using a middle-censored model with an elasticity of 0.5.
The budget constraint has a kink at ln(8) with log slopes of ln(1.3) and ln(0.9), respectively, to the left and right of the kink.
These correspond to tax rates to the left and right of the kink of -30 and 10 percent,
respectively. 
The unobserved agent heterogeneity is a linear combination of three
binary covariates (x1, x2, and x3) plus a Gaussian error term.
The data also include randomly generated frequency weights "w".
We introduce nonsharp bunching by adding a random error to the income of bunching
individuals. 
Such error term is a truncated normal with support [-ln(0.9), ln(1.1)],
which implies that deltam is 0.1054 and deltap is 0.0953.
The income variable with error is "yfric."



{p 4 8}Load the test data file included in the package:{p_end}
{p 8 8}{cmd:. use bunching}{p_end}

{p 4 8}Run {cmd: bunching} with filter:{p_end}
{p 8 8}{cmd:. bunching yfric x1 x2 x3, k(2.0794) s0(0.2624) s1(-0.1054) m(2) gen(yfilter) deltam(0.1054) deltap(0.0953) pctobs(30) polorder(7) savingtobit(dtobit.dta,replace) savingbounds(dbounds.dta, replace)}{p_end}

{p 4 8}Run {cmd: bunching} without filter:{p_end}
{p 8 8}{cmd:. bunching  y x1 x2 x3, k(2.0794) s0(0.2624) s1(-0.1054) m(2) savingtobit(dtobit2.dta, replace) savingbounds(dbounds2, replace)}{p_end}


{p 40 20 2}(Go up to {it:{help bunching##syntax:Syntax}}){p_end}

{marker results}{...}
{title:Stored results}{p 50 20 2}{p_end}
{pstd}
{cmd:bunching} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(tobit_theta_l_hat)}} intercept of the left-hand side equation{p_end}
{synopt:{cmd:r(tobit_theta_r_hat)}} intercept of the right-hand side equation{p_end}
{synopt:{cmd:r(tobit_sigma_hat)}} estimated standard deviation of the error term{p_end}
{synopt:{cmd:r(tobit_perc_obs)}} percentage of observations selected by truncation window{p_end}
{synopt:{cmd:r(tobit_eps_hat)}} elasticity estimate{p_end}
{synopt:{cmd:r(tobit_se_hat)}} standard error of the elasticity estimator{p_end}
{synopt:{cmd:r(tobit_covcol)}} number of covariates whose coefficients were restricted because of collinearity{p_end}
{synopt:{cmd:r(tobit_flag)}} dummy that equals one if the likelihood optimization did not converge {p_end}

{p2col 5 20 24 2: Scalars}{p_end}

{synopt:{cmd:r(bounds_e_trap)}} estimated elasticity using trapezoidal approximation{p_end}
{synopt:{cmd:r(bounds_emin_mmax)}} lower bound estimate for the elasticity using constant {it:m} entered by user{p_end}
{synopt:{cmd:r(bounds_emax_mmax)}} upper bound estimate for the elasticity using constant {it:m} entered by user{p_end}
{synopt:{cmd:r(bounds_M_hat)}} if the heterogeneity PDF has maximum slope magnitude greater than {it:M_hat}, then we cannot rule out PDFs that equal zero inside the bunching interval;
in this case, the upper bound is infinity{p_end}
{synopt:{cmd:r(bounds_M_min_hat)}} if the heterogeneity PDF has maximum slope magnitude smaller than {it:M_min_hat}, then no heterogeneity PDF is consistent with 
the observed distribution of income; bounds are not defined{p_end}
{synopt:{cmd:r(bounds_M_data_min)}} minimum value of the slope magnitude in the estimated PDF of the observed distribution of income (continuous part of the PDF){p_end}
{synopt:{cmd:r(bounds_M_data_max)}} maximum value of the slope magnitude in the estimated PDF of the observed distribution of income (continuous part of the PDF){p_end}
{synopt:{cmd:r(bounds_emin_mhat)}} lower bound estimate for the elasticity if the choice of {it:m} were equal to {it:M_hat};
available only when the choice of {it:m} entered by user is bigger than {it:M_hat}{p_end}
{synopt:{cmd:r(bounds_emax_mhat)}} upper bound estimate for the elasticity if the choice of {it:m} were equal to {it:M_hat};
available only when the choice of {it:m} entered by user is bigger than {it:M_hat}{p_end}
{synopt:{cmd:r(tobit_bin_n)}} number of bins used in histograms of {help bunchtobit}{p_end}
{synopt:{cmd:r(filter_Bhat)}} estimated bunching mass{p_end}
{synopt:{cmd:r(filter_R2)}} R-squared of polynomial regression{p_end}
{synopt:{cmd:r(filter_vars_dropped)}} number of variables dropped out of the polynomial regression in case the initial set of explanatory variables had perfect collinearity{p_end}
{synopt:{cmd:r(binwidth)}} value of bin width used in histograms of {help bunchfilter} and {help bunchtobit};
this is not stored if option {opt nopic} is stated. {p_end}

	
{p 40 20 2}(Go up to {it:{help bunching##syntax:Syntax}}){p_end}


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

