{smcl}
{* $Id$}
{hline}
help for {cmd:biastest}{right:Hasraddin Guliyev}
{hline}

{title:Title}

{p 4 4 2}
{cmd:biastest} — Testing parameter equality across different models in Stata.

{title:Syntax}

{p 8 15 2}
{cmd:biastest} {depvar} {indepvars} {ifin}, 
{cmd:m1(}{it:string}{cmd:)} [{cmd:m1ops(}{it:string}{cmd:)}] 
{cmd:m2(}{it:string}{cmd:)} [{cmd:m2ops(}{it:string}{cmd:)}] 
[{cmd:sigmaless}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt m1}({it:string})}specifies the first regression model to estimate (required){p_end}
{synopt:{opt m1ops}({it:string})}specifies additional options for the first model{p_end}
{synopt:{opt m2}({it:string})}specifies the second regression model to estimate (required){p_end}
{synopt:{opt m2ops}({it:string})}specifies additional options for the second model{p_end}
{synopt:{opt sigmaless}}adjust for non–positive-definite-differenced covariance matrix {p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
The {cmd:biastest} command in Stata is a powerful and versatile tool for comparing the coefficients of different regression models.
It assesses the robustness and consistency of findings by testing for bias between two models.

{pstd}
The individual bias test examines each independent variable separately, while the joint bias test evaluates whether all
coefficients are jointly equal across the two models. This command is particularly useful in contexts such as:

{p 8 12 2}- Comparing ordinary least squares (OLS) and robust regression{p_end}
{p 8 12 2}- Comparing quantile regression across different percentiles{p_end}
{p 8 12 2}- Comparing fixed-effects and random-effects models in panel data analysis{p_end}

{title:Options}

{dlgtab:Model}

{phang}
{opt m1}({it:string}) specifies the first regression model to estimate (e.g., regress). This is a required option.

{phang}
{opt m1ops}({it:string}) specifies additional options for the first model (e.g., vce(robust)).

{phang}
{opt m2}({it:string}) specifies the second regression model to estimate (e.g., rreg). This is a required option.

{phang}
{opt m2ops}({it:string}) specifies additional options for the second model (e.g., nolog).

{phang}
{opt sigmaless} scales the variance matrix of the model with smaller coefficients by (σ₁/σ₂)², where σ₁ and σ₂ are the residual standard deviations from each model. This adjustment fixs non–positive-definite-differenced covariance matrix.

{title:Stored results}

{pstd}
{cmd:biastest} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{p2col:{cmd:e(N)}}number of observations{p_end}
{p2col:{cmd:e(chi2)}}chi-squared statistic for the joint test{p_end}
{p2col:{cmd:e(df_chi2)}}degrees of freedom for the joint test{p_end}
{p2col:{cmd:e(p_chi2)}}p-value for the joint test{p_end}
{p2col:{cmd:e(s2_1)}}σ from model 1 (if sigmaless used){p_end}
{p2col:{cmd:e(s2_2)}}σ from model 2 (if sigmaless used){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{p2col:{cmd:e(b1)}}coefficients from the first model{p_end}
{p2col:{cmd:e(V1)}}variance-covariance matrix from the first model{p_end}
{p2col:{cmd:e(b2)}}coefficients from the second model{p_end}
{p2col:{cmd:e(V2)}}variance-covariance matrix from the second model{p_end}
{p2col:{cmd:e(tstat)}}t-statistics for individual parameter tests{p_end}
{p2col:{cmd:e(pvalues)}}p-values for individual parameter tests{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{p2col:{cmd:e(sigmaless)}}"adjusted" if sigmaless option used{p_end}

{title:Examples}

{phang}{bf:Example 1:} Compare OLS and robust regression{p_end}
{cmd}{...}
. use https://stats.idre.ucla.edu/stat/stata/dae/crime, clear
. biastest crime pctmetro pcths poverty, m1(reg) m2(rreg) m2ops(nolog)
{txt}{...}

{phang}{bf:Example 2:} Quantile regression with sigmaless adjustment{p_end}
{cmd}{...}
. webuse engel1857, clear
. biastest foodexp income, m1(qreg) m1ops(q(25)) m2(qreg) m2ops(q(75)) sigmaless
{txt}{...}

{phang}{bf:Example 3:} Panel data models{p_end}
{cmd}{...}
. webuse grunfeld, clear
. biastest invest mvalue kstock, m1(xtreg) m1ops(fe) m2(xtreg) m2ops(re)
{txt}{...}

{title:Author}

{pstd}
Hasraddin Guliyev{p_end}
{pstd}
Azerbaijan State University of Economics{p_end}
{pstd}
hasradding@unec.edu.az{p_end}

{title:Also see}

{psee}
Manual: {help regress}, {help rreg}, {help sqreg}, {help xtreg}, {help test}{p_end}
