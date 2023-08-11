{smcl}
{* *! version 1.0: 02-August-2023}{...}
{viewerjumpto "Syntax" "bivpoisson_ate##syntax"}{...}
{viewerjumpto "Description" "bivpoisson_ate##description"}{...}
{viewerjumpto "Options" "bivpoisson_ate##options"}{...}
{viewerjumpto "Examples" "bivpoisson_ate##examples"}{...}
{viewerjumpto "Saved results" "bivpoisson_ate##results"}{...}
{viewerjumpto "References" "bivpoisson_ate##references"}{...}
{vieweralsosee "bivpoisson_ate postestimation" "help bivpoisson_ate postestimation"}{...}
{hline}
{hi:help bivpoisson_ate}{right:{browse "https://github.com/zhangyl334/bivpoisson_ate":github.com/zhangyl334/bivpoisson_ate}}
{hline}
{right:version 1.0}

{p2colset 1 16 3 2}{...}
{p2col:{bf: bivpoisson_ate} {hline 2}}Average Treatment Effects Estimation in Seemingly Unrelated Count Regression{p_end}
{p2colreset}{...}




{marker syntax}{...}
{title:Syntax}

{p2colset 5 16 3 2}{...}
{p2col: {cmd:bivpoisson_ate}} {cmd:(} {it:depvar} {cmd:=} {it:indepvars1} {cmd:)}
	{cmd:(} {it:depvar2} {cmd:=} {it:indepvars2} {cmd:)} [if statement]
{p2colreset}{...}



{synoptset 28 tabbed}{...}
{marker opts}{col 5}{help bivpoisson_ate##options:{it:options}}{col 35}Description
{synoptline}
{syntab:Option}
{synopt :{opt if statement}}select a subsample {p_end}


{p 4 6 2}
	{it:depvar1} and {it:depvar2} are count-valued independent variables for the first and second equations respectively. 
	They cannot be zero inflated; model warns and exits on zero inflated data.
	{p_end}
{p 4 6 2}
    {it:indepvars1} and {it:indepvars2} are the independent variables for the first and second eqations respectively. 
    User should put the policy variable at the first place when supplying independent variables {it:depvar1} and {it:depvar2} for both equations. 
    Model automatically includes a constant; the constant cannot be omitted in the current version of the command.
	{p_end}



{marker description}{...}
{title:Description}

{pstd}
	{cmd:bivpoisson_ate} is a user-written command that estimate average treatment effects (ATEs), its standared errors (S.E.s 
	of the ATEs), and p-values under the seemingly unrelated count regressioin model (implemented by: bivpoisson).
	The ATEs are the potential outcomes of the population average for a counterfactural change in the value of underlying policy variable. 
	It fits a seemingly unrelated count regressioin model using maximum likelihood estimation. It is
	implemented as an {cmd:lf1 ml} evaluator. The model involves one equation with 
	the count valued dependent variable {it:depvar1} and a second equation with count valued dependent
	variable {it:depvar2}. Both dependent variables {it:depvar1} and {it:depvar2} have to be both integer valued. The policy variable needs 
	to be placed as the first element of both dependent variables list {it:depvar1} and {it:depvar2}.

{pstd}
	{cmd:bivpoisson_ate} calls bivpoisson command and conduct post-estimation under the causal inference framework.

{pstd}
	{cmd:bivpoisson_ate} estimate average treatment effects (ATEs), its standared errors (S.E.s of the ATEs), and p-values. 
	The standared errors formula for ATEs are detailed in Terza (2016), and Zhang (2021).

{pstd}
	{cmd:bivpoisson_ate} requires the first element, AKA the policy variable in both {it:indepvars1} and {it:indepvars2} to be identical. 

{pstd}
	{cmd:bivpoisson_ate} allows the REST of the independent variables , AKA the covariates in {it:indepvars1} and {it:indepvars2} to be different or identical.

{pstd}
	{cmd:bivpoisson_ate} is limited to a model with two equations.
{p_end}

	 
{marker examples}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. use  "https://github.com/zhangyl334/bivpoisson_ate/raw/main/Health_Data.dta", clear}{p_end}

{pstd}Seemingly unrelated count regression{p_end}
{phang2}{cmd:. bivpoisson_ate (ofp = privins black numchron) (ofnp = privins black numchron age)}	
{p_end}

{pstd}Seemingly unrelated count regression with if statement{p_end}
{phang2}{cmd:. bivpoisson_ate (ofp = privins black numchron) (ofnp = privins black numchron age) if poorhlth != 1}	
{p_end}

			
{marker results}{...}
{title:Stored results}

{pstd}
{cmd:bivpoisson_ate} stores the following in {cmd:e()}:


{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}


{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(indep2)}}names of first equation independent variables{p_end}
{synopt:{cmd:e(depvar2)}}names of first equation dependent variable{p_end}
{synopt:{cmd:e(indep1)}}names of second equation independent variables{p_end}
{synopt:{cmd:e(depvar1)}}names of second equation dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(cmd)}}{cmd:bivpoisson}{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program: BivPoissNormLF(){p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                         maximization or minimization{p_end}
{synopt:{cmd:e(depvar)}}names of two dependent variables as Y1 and Y2{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}


{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}



{marker references}{...}
{title:References}

{phang}
    Zhang, Fisher & Terza, 2022. "BIVPOISSON: Stata module to perform seemingly unrelated count regression," Statistical Software Components S459104, Boston College Department of Economics, revised 16 Aug 2022. {browse "https://EconPapers.repec.org/RePEc:boc:bocode:s459104"} 
    {p_end}

{phang}
	Zhang, Y. (2021). Exploring the Importance of Accounting for Nonlinearity in Correlated Count Regression Systems from the Perspective of Causal Estimation and Inference. DOI: {browse "https://doi.org/10.7912/C2/2873"}
	{p_end}

{phang}
	Baum, C. F. (2016). An introduction to Stata programming (Second edition). StataCorp LP. 
	{p_end}
	
{phang}
	Terza, J. V. (2016). Simpler Standard Errors for Two-stage Optimization Estimators. The Stata Journal: Promoting Communications on Statistics and Stata, 16(2), 368–385. DOI: {browse "https://doi.org/10.1177/1536867X1601600206"}
	{p_end}

{phang}
	Chib, S., & Winkelmann, R. (2001). Markov Chain Monte Carlo Analysis of Correlated Count Data. Journal of Business & Economic Statistics, 19(4), 428–435. DOI: {browse "https://doi.org/10.1198/07350010152596673"} 
	{p_end}

{phang}
	Aitchison, J., & Ho, C. H. (1989). The multivariate Poisson-log normal distribution. Biometrika, 76(4), 643–653. DOI: {browse "https://doi.org/10.1093/biomet/76.4.643"}
	{p_end}

	
{marker author}{...}
{title:Author}

{phang}Abbie Zhang{p_end}
{p2col 5 20 29 2:affiliation:}Boston University{p_end}
{p2col 5 20 29 2:email:}abbiezha@bu.edu{p_end}
{p2col 5 20 29 2:github:}{browse "https://github.com/zhangyl334":github.com/zhangyl334/bivpoisson_ate}{p_end}
{p2col 5 20 29 2:webpage:}{browse "https://yileizhang.com"}{p_end}

{marker coauthors}{...}
{title:Coauthors}

{phang}James Fisher{p_end}
{p2col 5 20 29 2:email:}jamescdf@gmail.com{p_end}



