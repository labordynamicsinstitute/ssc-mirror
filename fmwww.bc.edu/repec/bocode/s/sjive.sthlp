{smcl}
{* *! version 1.0 23 Dec 2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "sjive##syntax"}{...}
{viewerjumpto "Description" "sjive##description"}{...}
{viewerjumpto "Options" "sjive##options"}{...}
{viewerjumpto "Remarks" "sjive##remarks"}{...}
{viewerjumpto "Examples" "sjive##examples"}{...}
{title:Title}
{phang}
{bf:sjive} {hline 2} Shrunken jackknife instrumental variables estimator (SJIVE)

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:sjive}
depvar
[{help varlist}]
(var
=
varlist_iv)
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]


{p 4 6 2}
{it: varlist} is the list of exogenous variables.
{p_end}
{p 4 6 2}
{it: var} is the endogenous variable.
{p_end}
{p 4 6 2}
{it: varlist_iv} is the list of instrumental variables.
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt gen(string)}} creates a new variable containing the shrunken instrument

{synopt:{opt w(varlist)}} specifies shrinkage targets

{synopt:{opt chunk(#)}} specifies the number of observations processed per iteration

{synopt:{opt noshrink}} suppresses shrinkage

{synopt:{opt force}} drops singleton observations that cause estimation failure

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:sjive} implements the Shrunken Jackknife Instrumental Variables 
Estimator (SJIVE) developed by Frandsen, Lefgren, Leslie, and McIntyre (2025). 
SJIVE improves upon standard JIVE estimation by applying empirical Bayes 
shrinkage to first-stage fitted values, consequently improving the second-stage 
precision of treatment effect estimates. This is particularly beneficial in 
many-instrument designs like judge fixed effects.

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt gen(string)} creates a new variable containing the shrunken instrument
(phattilde) used in the second stage

{phang}
{opt w(varlist)} specifies low-dimensional covariates used as shrinkage targets.
These should be predictive of treatment propensities. When specified,
instruments are shrunk toward conditional means given these targets; otherwise shrinkage is toward
the grand mean

{phang}
{opt chunk(#)} specifies the number of observations processed per iteration
when computing large matrices in standard error and shrinkage parameter
calculation. Default is 1000. Larger values use more memory but may be faster

{phang}
{opt noshrink} suppresses shrinkage, reducing SJIVE to the unbiased jackknife
instrumental variables estimator (UJIVE)

{phang}
{opt force} drops observations that are perfectly identified by the instruments or
controls (singletons). These observations have leverage equal to one, causing 
the leave-one-out estimator to fail. The option recursively removes these 
observations until the sample is stable



{marker examples}{...}
{title:Examples}

{pstd}Fit the SJIVE model with offense type dummies as controls and judge dummies
 as shrinkage targets with judge-offense type interactions as instruments {p_end}
{pstd}
	 {cmd: . use sjiveexample.dta, clear} {break} {cmd: . sjive conviction offensetype* (pretrial_detention = judge_offensetype_int*), w(judge*) chunk(2000)}

{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}  number of observations used in estimation {p_end}
{synopt:{cmd:e(weak)}}  indicator equal to 1 if weak instruments are detected {p_end}
{synopt:{cmd:e(N_excluded)}}  number of excluded instruments {p_end}
{synopt:{cmd:e(N_dropped)}}  number of observations dropped by --force-- option {p_end}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}  coefficient vector {p_end}
{synopt:{cmd:e(V)}}  variance-covariance matrix of the estimators {p_end}


{title:References}
{pstd}
Frandsen, Brigham R., Lars J. Lefgren, Emily C. Leslie, and Samuel P. McIntyre (2025). The Incredible Shrinking Instruments: Using Empirical Bayes to Increase Efficiency in IV Designs with Many Instruments. Working Paper. 

{pstd}
Angrist, Joshua D., Guido W. Imbens, and Alan B. Krueger (1999). Jackknife Instrumental Variables Estimation. Journal of Applied Econometrics, 14(1), 57-67. 

{pstd}
Kolesar, Michal (2013). Estimation in an Instrumental Variables Model with Treatment Effect Heterogeneity. Unpublished working paper.

{pstd}

{pstd}

{title:See Also}
Related commands:
{help ivregress}


