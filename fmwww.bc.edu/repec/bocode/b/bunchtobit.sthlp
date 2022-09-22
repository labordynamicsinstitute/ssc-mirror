{smcl}
{* *! version 1.8  2022-03-24}{...}
{* *  version 1.7  2021-05-25}{...}
{* *  version 1.6  2021-05-11}{...}
{* *  version 1.5  2020-06-02}{...}
{* *  version 1.4  2020-05-21}{...}
{* *  version 1.3  2020-04-24}{...}
{* *  version 1.2  2019-12-19}{...}
{* *  version 1.0  2019-11-05}{...}
{findalias asfradohelp}{...}
{vieweralsosee "[R] help" "help help"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] bunching" "help bunching"}{...}
{vieweralsosee "[R] bunchfilter" "help bunchfilter"}{...}
{vieweralsosee "[R] bunchbounds" "help bunchbounds"}{...}
{viewerjumpto "Syntax" "bunchtobit##syntax"}{...}
{viewerjumpto "Description" "bunchtobit##description"}{...}
{viewerjumpto "Stored results" "bunchtobit##results"}{...}
{viewerjumpto "Reference" "bunchtobit##reference"}{...}
{title:Title}

{phang}
{bf:bunchtobit} {hline 2} uses bunching, Tobit regressions, and covariates to point identify the elasticity of a response variable with respect to
 changes in the slope of the budget set according to the procedures of Bertanha, McCallum, and Seegert (2022).


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:bunchtobit}
{depvar} [{indepvars}]
{ifin}
{weight}
{cmd:,}
	 {cmdab:k:ink}({it:#}) 
	 {cmdab:s0}({it:#}) 
	 {cmdab:s1}({it:#}) 
[	 
	{cmdab:binw:idth}({it:#})
	{cmdab:g:rid}({it:numlist})
	{cmdab:nopic}
	{cmdab:n:umiter}({it:#}) 	 
	{cmdab:savingtobit}({it:filename}[,{it:replace}]) 
	{cmdab:verbose}
]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt depvar}} must be one dependent variable (the response variable in logs in many applications){p_end}
{synopt :{opt k:ink(#)}} is the location of the kink point and must be a real number in the same units as the response variable{p_end}
{synopt :{opt s0(#)}} is a real number; in many applications, it is the log of the slope before the kink point{p_end}
{synopt :{opt s1(#)}} must be a real number that is strictly less than {opt s0}; in many applications, it is the log of the slope after the kink point{p_end}

{syntab:Optional}
{synopt :{opt indepvars}} is a {help varlist} of covariates; heterogeneity is a linear function of these covariates and an unobserved error that is normally distributed 
conditional on these covariates {p_end}
{synopt :{opt if | in}} like in any other Stata command, to restrict the working sample {p_end}
{synopt :{opt weight}} follows Stata's {help weight} syntax and only allows frequency weights, {help fweight} {p_end}
{synopt :{opt binw:idth}({it:#})} is the width of the bins for the histograms; it must be a strictly positive real number; 
the default value is half of what is automatically produced by the command {help histogram} {p_end}
{synopt :{opt g:rid(numlist)}} is a {help numlist} of integers from 1 to 99; 
the values in the {opt numlist} correspond to percentages of the sample that define symmetric truncation windows around the kink point; 
the truncated Tobit model is estimated on each of these samples
and also the full sample so that the number of estimates is always one more than the number of entries in {opt numlist}; 
for example, if {opt grid(15 82)}, then {cmd: bunchtobit} estimates the Tobit model three times using 100, 82, and 15 percent of the data around the kink point; 
the default value for the {opt numlist} is 10(10)90, which provides 10 estimates {p_end}
{synopt :{opt nopic}} suppresses displaying graphs; the default is to display graphs {p_end}
{synopt :{opt n:umiter(#)}} is the maximum number of iterations allowed when maximizing the Tobit log likelihood; 
it must be a positive integer and the default is 500 {p_end}
{synopt :{opt savingtobit}({it:filename}[,{it:replace}])} saves {it: filename.dta} with Tobit estimates for each truncation window;
the  {it: filename.dta} file contains eight variables corresponding to the matrices that the code stores in {opt r()}; 
see below for more details;
use {it: replace} if {it: filename.dta} already exists in the working directory {p_end}
{synopt :{opt verbose}} displays detailed output from the Tobit estimation including iterations of maximizing the log likelihood; 
non-verbose mode is the default {p_end}
{synoptline}



{marker description}{...}
{title:Description}

{pstd}
The user enters the name of the response variable, the location of the kink point, and the slopes before and after the kink point.
For example, in the income-tax application of Bertanha, McCallum, and Seegert (2022), dollars of taxable income and the dollar value of the kink point 
are transformed by taking logs, and the slopes must be input as the log of one minus the marginal tax rates.  
You need to have a dataset with the response variable drawn from a mixed continuous-discrete distribution.
The distribution is continuous except for the 
{it:kink} value, which has a positive mass point. 
The proportion of values at the {it:kink} value must be positive in your sample.
Check to see if {cmd:count if y==kink} (where {it:y} is the response variable) gives you the right number. In case it gives you zero when it should not, check the 
value of the {it:kink} and if {it:y} is type {it:double}.

{pstd}
{cmd: bunchtobit} estimates multiple mid-censored Tobit regressions using specified sub-samples of the data.
It starts with the entire sample, then it truncates the sample to symmetric windows centered at the kink as specified by the user. 
The elasticity estimate is plotted as a function of the percentage of data used in each truncation window. 
The code also plots the histogram of the response variable along with the best-fit Tobit distribution for each truncation window.

{pstd}
The user has the option of entering covariates that help explain the unobserved heterogeneity.
Lemma 1 by Bertanha, McCallum, and Seegert (2022) demonstrates that the distribution of the unobserved heterogeneity 
conditional on covariates does not need to be normal for the Tobit estimates to be consistent.
Consistency requires (i) the unconditional distribution of heterogeneity is a semi-parametric mixture of normal distributions 
averaged over the included covariates; 
and (ii) the unconditional distribution of the response variable predicted by the Tobit model fits the observed distribution of the response variable well.
If the user does not enter covariates, then the unconditional distribution of heterogeneity needs to be normal.  


{p 40 20 2}(Go up to {it:{help bunchtobit##syntax:Syntax}}){p_end}

{marker example}{...}
{title:Example}

{pstd}
The package includes the sample data file "bunching.dta". The income data in logs (i.e., "y") 
were simulated using a middle-censored model with an elasticity of 0.5.
The budget constraint has a kink at ln(8) with log slopes of ln(1.3) and ln(0.9), respectively, to the left and right of the kink.
These correspond to tax rates to the left and right of the kink of -30 and 10 percent,
respectively.  
The unobserved agent heterogeneity is a linear combination of three
binary covariates (x1, x2, and x3) plus a Gaussian error term.
The data also include randomly generated frequency weights "w".
{p_end}


{p 4 8}Load the test data file included in the package:{p_end}
{p 8 8}{cmd:. use bunching}{p_end}

{p 4 8}Run a correctly specified {cmd: bunchtobit} with binwidth and savingtobit options:{p_end}
{p 8 8}{cmd:. bunchtobit y x1 x2 x3 , k(2.0794) s0(0.2624) s1(-0.1054)  binwidth(0.08) savingtobit(ctobitdata, replace)}{p_end}

{p 4 8}Run a misspecified {cmd: bunchtobit} with verbose, numiter, binwidth, and savingtobit options:{p_end}
{p 8 8}{cmd:. bunchtobit y x1 x3 , k(2.0794) s0(0.2624) s1(-0.1054) verbose numiter(1000) binwidth(0.08) savingtobit(mtobitdata, replace)}{p_end}


{p 40 20 2}(Go up to {it:{help bunchtobit##syntax:Syntax}}){p_end}

{marker results}{...}
{title:Stored results}{p 50 20 2}{p_end}
{pstd}
{cmd:bunchtobit} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(tobit_theta_l_hat)}} intercept of the left-hand side equation{p_end}
{synopt:{cmd:r(tobit_theta_r_hat)}} intercept of the right-hand side equation{p_end}
{synopt:{cmd:r(tobit_sigma_hat)}} estimated standard deviation of the error term{p_end}
{synopt:{cmd:r(tobit_perc_obs)}} percentage of observations selected by truncation window{p_end}
{synopt:{cmd:r(tobit_eps_hat)}} elasticity estimate{p_end}
{synopt:{cmd:r(tobit_se_hat)}} standard error of the elasticity estimator{p_end}
{synopt:{cmd:r(tobit_covcol)}} number of covariates whose coefficients were restricted because of collinearity{p_end}
{synopt:{cmd:r(tobit_flag)}} dummy that equals one if the log likelihood optimization did not converge {p_end}

{p2col 5 20 24 2: Scalars}{p_end}

{synopt:{cmd:r(binwidth)}} value of the bin width used in histograms{p_end}
{synopt:{cmd:r(tobit_bin_n)}} number of bins used in histograms{p_end}
	
{p 40 20 2}(Go up to {it:{help bunchtobit##syntax:Syntax}}){p_end}


{title:Authors}

{p 4 8} Marinho Bertanha, mbertanha@nd.edu, University of Notre Dame {p_end}

{p 4 8} Andrew McCallum, andrew.h.mccallum@frb.gov, Federal Reserve Board {p_end}

{p 4 8} Nathan Seegert, nathan.seegert@eccles.utah.edu, University of Utah. {p_end}



{marker reference}{...}
{title:Reference}

{p 5 6 2}
Bertanha, M., McCallum, A., Seegert, N. (2022), "Better Bunching, Nicer Notching". Working paper SSRN 3144539.
{p_end}

{p 5 6 2}
Bertanha, M., McCallum, A., Payne, A., Seegert, N. (2022), "Bunching Estimation of Elasticities Using Stata".
Stata Journal, forthcoming.
{p_end}
