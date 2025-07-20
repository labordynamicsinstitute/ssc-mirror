{smcl}
{* *! version 2 07jul2025}

{title:Title} 
{pstd} 

	twc_inf -- Analytic inference under two-way clustering

{title:Remark}
{pstd} 
  
Compatible with version 16.1 of Stata and more recent ones

{title:Syntax}

{p 4 12 2} {cmd:twc_inf} {depvar} [{indepvars}]  {ifin} {cmd:,} {opt cluster(var1 var2)} [{opt method(methodname)} {opt alpha(numlist max=1 int)} {opt nodofcorr}]{p_end}

{title:Description}

{pstd}
{cmd:twc_inf} fits a regression model of {cmd:depvar} on {cmd:indepvars} using the model specified by {cmd:method()}. For each regression coefficient, the command computes the associated standard error se=max(se_1,se_2,se_u) - proposed in Davezies et al. (2025) - that allows to conduct asymptotically valid inference in presence of two-way clustering along the variables {cmd:var1} and {cmd:var2} provided through the {cmd:cluster()} option. Corresponding confidence intervals are also reported for each regression coefficient.{p_end}

{title:Options}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt: {opt cluster(var1 var2)}}indicates the two variables var1 and var2 along which clustering occurs. It is compulsory to indicate two clustering variables.{p_end}
{synopt: {opt method(methodname)}}provides the regression method methodname to be used. Methodname can be any of {help regress}, {help logit}, {help probit} or {help poisson}. The default method is {help regress}.{p_end}
{synopt: {opt alpha(numeric)}}sets the confidence level at 100 minus the value specified in alpha(). The default is 5. The given value has to be an integer between 1 and 99 included.{p_end}
{synopt: {opt nodofcorr}}allows users to estimate V1, V2 and V12 (namely oneway clustered variance along cl1, cl2 and cl1#cl2) - which are the building blocks of the standard errors proposed in Davezies et al. (2025) without Stata's standard degree of freedom corrections.{p_end}

{title:Examples}

	Load twc_inf_db.dta into memory from current directory

{phang2}{cmd:. use} twc_inf_db {p_end}

	Linear regression with twoway clustering along {cmd:rowclust} and {cmd:colclust}

{phang2}{cmd:. twc_inf} Yreg X1 X2, cl(rowclust colclust) {p_end}

	Logistic regression with twoway clustering along {cmd:rowclust} and {cmd:colclust}

{phang2}{cmd:. twc_inf} Ybinary X1 X2, cl(rowclust colclust) method(logit) {p_end}

	Poisson regression with twoway clustering along {cmd:rowclust} and {cmd:colclust}, 90% confidence intervals and no DOF correction

{phang2}{cmd:. twc_inf} Ypoisson X1 X2, cl(rowclust colclust) method(poisson) alpha(10) nodofcorr {p_end}

{hline}

{title:Stored results}

{pstd}In what follows, let k denote the number of indepvars. {cmd:twc_inf} saves the following in {cmd:r()}:{p_end}
{synoptset 24 tabbed}{...}

{syntab:Matrices}
{synopt:{cmd:r(coef_vec)}}a 1 x k matrix of regression coefficients.{p_end}
{synopt:{cmd:r(V1)}}a k x k var-cov matrix for regression coefficients one-way clustered along cl1.{p_end}
{synopt:{cmd:r(V2)}}a k x k var-cov matrix for regression coefficients one-way clustered along cl2.{p_end}
{synopt:{cmd:r(V12)}}a k x k var-cov matrix for regression coefficients one-way clustered along cl1#cl2.{p_end}
{synopt:{cmd:r(Vu)}}Cameron et al. (2011)'s var-cov matrix (k x k) that satisfies Vu = V1 + V2 - V12.{p_end}
{synopt:{cmd:r(eigenvals_Vu)}}a 1 x k matrix with the eigenvalues of Vu in decreasing order.{p_end}
{synopt:{cmd:r(se_vec)}}a 1 x k matrix with the standard errors for each coefficient proposed in Davezies et al.{p_end}

{title:References}

{phang} Davezies, L. and D'Haultfoeuille, X. and Guyonvarch, Y. 2025.  Analytic inference with two-way clustering.  {browse "https://arxiv.org/abs/2506.20749": Arxiv working paper}.


{title:Authors}

{phang}Laurent Davezies, CREST, Palaiseau, France.  {browse "mailto:laurent.davezies@ensae.fr":laurent.davezies@ensae.fr}.{p_end}

{phang}Xavier D'Haultfoeuille, CREST, Palaiseau, France. {browse "mailto:xavier.dhaultfoeuille@ensae.fr":xavier.dhaultfoeuille@ensae.fr}.{p_end}

{phang}Yannick Guyonvarch, PSAE, Palaiseau, France. {browse "mailto:yannick.guyonvarch@inrae.fr":yannick.guyonvarch@inrae.fr}.{p_end}

        