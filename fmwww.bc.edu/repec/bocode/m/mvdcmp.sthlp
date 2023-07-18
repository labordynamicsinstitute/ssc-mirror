{smcl}
{* 26APR2017}{...}
{right: also see: {help mvdcmpgroup}}
{hi:help mvdcmp}
{hline}

{title:Title}

{pstd}{hi:mvdcmp} {hline 2}  multivariate decomposition for nonlinear response models


{title:Syntax}
{p 8 16 2}
{cmd:mvdcmp} {it:groupvar} [, {it:options} ]  {cmd: :} {it:estimation_command} {depvar} [{indepvars}] {weight} [, {it:options}]
{p_end}

{p 4 4 2} where

{p 8 16 2} {it:groupvar} specifies a binary variable coded 0 or 1 identifying the two groups;

{p 8 16 2} {it:estimation_command} (see help {help estcom}) should begin with
{it:regress}, {it:svyregress}, {it:logit}, {it:svylogit}, {it:probit}, {it:svyprobit}, {it:poisson}, {it:svypoisson}, {it:nbreg}, {it:svynbreg}, {it:cloglog}, or {it:svycloglog}; 

{synoptset 25 tabbed}{...}
{marker opt}{synopthdr:options}
{synoptline}
{synopt :{opt reverse}}reverse decomposition by swapping groups
    {p_end}
    
{synopt :{opt norm(varlist1|varlist2)}}identify dummy variable sets and apply deviation contrast normalization
    {p_end}
    
{synopt :{opt scale(real)}}multiply coefficients and standard errors by a scaling factor [default scale(1)]
    {p_end}
    
{pstd} {opt norm()} requires that all dummy variables corresponding to each level of a factor be specified. It is most useful for factors having more than two levels. 
For example, suppose that a set of dummy variables a1, a2, and a3 corresponds to a 3-level factor, 
then {opt norm(a1-a3)} will implement the anova-type normalization. With more than one factor, dummy 
variable sets should be separated by |. For example, suppose that dummy variables b1, b2, b2, and b4 correspond to a 
4-level factor to be normalized along with the 3-level factor above, then {opt norm(a1-a3|b1-b4)} 
will implement a  normalization of both factors.
       
{title:Models} 
{synoptset 25 tabbed}{...}
    {synopt :{cmd:regress}}linear regression model
    {p_end}
    {synopt :{cmd:svyregress}}linear regression model for complex survey design (see {help svy} and {help svyset})
    {p_end}
    {synopt :{cmd:logit}}logit model
    {p_end}
    {synopt :{cmd:svylogit}}logit model for complex survey design
    {p_end}
    {synopt :{cmd:probit}}probit model
    {p_end}
    {synopt :{cmd:svyprobit}}probit model for complex survey design
    {p_end}
    {synopt :{cmd:poisson}}Poisson regression model
    {p_end}
    {synopt :{cmd:svypoisson}}Poisson regression model for complex survey design
    {p_end}
    {synopt :{cmd:nbreg}}negative binomial regression model
    {p_end}
    {synopt :{cmd:svynbreg}}negative binomial regression model for complex survey design
    {p_end}
    {synopt :{cmd:cloglog}}complementary log-log regression model
    {p_end}
    {synopt :{cmd:svycloglog}}complementary log-log regression model for complex survey design
    {p_end}
    
{pstd} {cmd:fweight}s, {cmd:pweight}s, {cmd:aweights}, and {cmd: iweight}s are allowed 
when supported by the model (see {help weight}) in addition to the following model options:

{synoptset 25 tabbed}{...}
{marker opt}{synopthdr:options}
{synoptline}
{synopt :{opt cluster(varname)}} (see {cmd:cluster})
    {p_end}
{synopt :{opt robust}} (see {cmd:robust})
    {p_end}
{synopt :{opt offset(varname)}} (see {cmd:offset}) Applies to {cmd: poisson}, {cmd:nbreg}, {cmd:svypoisson}, and {cmd:svynbreg} only.
    {p_end}

{pstd} Note that {cmd:logit}, {cmd:svylogit}, {cmd:probit}, and {cmd:svyprobit} allow fractional responses (see {cmd:fracreg}). Use the {cmd:robust} option when fitting a fractional response using a {cmd:logit} or {cmd:probit} model.


{title:Description}

{pstd} {cmd:mvdcmp} computes a multivariate decomposition for a variety of models,
and is often used to analyze differentials by race, sex, or time. {it:estimation_command} is the model of interest, 
{it:depvar} is the outcome variable and {it:indepvars} are predictors. {it:groupvar} identifies the groups to be compared. 

{title:Examples}

{p 0 15 2}
{bf:logit regression decomposition}
{p_end}

{pstd} mvdcmp blk: logit devnt pctsmom nfamtran medu inc1000 nosibs magebir

{p 0 15 2}
{bf:negative binomial regression decomposition} with {cmd:offset} term and options {cmd:reverse} and {cmd:scale}
{p_end}

{pstd} mvdcmp consprot, scale(100) reverse : nbreg nabort medu adjinc south urban profam books, offset(lognpreg) 

{title:Saved Results}
{pstd}

{cmd:mvdcmp} saves the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}

{synopt:{cmd:e(N)}} number of observations
    {p_end}
{synopt:{cmd:e(scale)}} value of scale if used
    {p_end}

{p2col 5 15 19 2: Macros}{p_end}

{synopt:{cmd:e(cvarlist)}} complete list of coefficient names for ease of post-processing 
    {p_end}
{synopt:{cmd:e(depvar)}} names of dependent variable
    {p_end}
{synopt:{cmd:e(indvar)}} names of independent variables
    {p_end}
{synopt:{cmd:e(high)}} name of high-outcome group
    {p_end}
{synopt:{cmd:e(low)}} name of low-outcome group
    {p_end}

{p2col 5 15 19 2: Matrices}{p_end}

{synopt:{cmd:e(b)}} estimates
    {p_end}
{synopt:{cmd:e(V)}} variance/covariance matrix of estimates
    {p_end}

{title:References}

{phang} Jann, B. (2008). "The Blinder-Oaxaca Decomposition for Linear Regression Models." {it:The Stata Journal}, 8: 453-479.
{p_end}
{phang} Powers, Daniel A., Hirotoshi Yoshioka, and Myeong-Su Yun. (2011). “mvdcmp: Multivariate Decomposition for Nonlinear Response Models.” {it:The Stata Journal}, 11: 556-576.
{p_end}{phang} Yun, M-S. 2004. "Decomposing Differences in the First Moment." {it:Economics Letters}, 82: 275-280.
{p_end}
{phang} Yun, M-S. 2005. "Hypothesis Tests when Decomposing Differences in the First Moment." {it:Journal of Economic and Social Measurement}, 30: 305-319.
{p_end}
{phang} Yun, M-S. 2005. "A Simple Solution to the Identification Problem in Detailed Wage Decompositions." {it:Economic Inquiry}, 43: 766-772.
{p_end}

{title:Authors}

{p 4 4 2}Daniel A. Powers, University of Texas at Austin, dpowers@austin.utexas.edu
{p_end}
{p 4 4 2}Hirotoshi Yoshioka, University of Texas at Austin, hiro12@prc.utexas.edu
{p_end}
{p 4 4 2}Myeong-Su Yun, Inha University, msyun@inha.ac.kr
{p_end}

{title:Also see}

{p 4 13 2} Online help for {helpb oaxaca}, {helpb fairlie},
{helpb devcon}, {helpb regress}, {helpb logit}, {helpb probit}, {helpb poisson}, {helpb nbreg},  {helpb cloglog} and {helpb svy}.
{p_end}
