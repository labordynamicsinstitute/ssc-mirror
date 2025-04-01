{smcl}
{* *! version 1.0.0 20feb2025}{...}
{title:Title}

{p 4 4 2}
{bf:biastest} — Testing parameter equality across different models in Stata.

{title:Syntax}

{p 8 17 2}
{cmd:biastest} {it:depvar} {it:indepvars} [{cmd:if}] [{cmd:in}], {cmd:m1(}{it:string}{cmd:)} [{cmd:m1ops(}{it:string}{cmd:)}] {cmd:m2(}{it:string}{cmd:)} [{cmd:m2ops(}{it:string}{cmd:)}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt m1(string)}}specifies the first regression model to estimate. This is a required option.{p_end}
{synopt:{opt m1ops(string)}}specifies additional options for the first model.{p_end}
{synopt:{opt m2(string)}}specifies the second regression model to estimate. This is a required option.{p_end}
{synopt:{opt m2ops(string)}}specifies additional options for the second model.{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
The {cmd:biastest} command in Stata is a powerful and versatile tool for comparing the coefficients of different regression models. It assesses the robustness and consistency of findings by testing for bias between two models.

{p 4 4 2}
The individual bias test examines each independent variable separately, while the joint bias test evaluates whether all coefficients are jointly equal across the two models. This command is particularly useful in contexts such as:

{p 6 6 2}
- Comparing ordinary least squares (OLS) and robust regression.{p_end}
{p 6 6 2}
- Comparing quantile regression across different percentiles.{p_end}
{p 6 6 2}
- Comparing fixed-effects and random-effects models in panel data analysis.{p_end}

{title:Options}

{synoptset 25 tabbed}{...}
{syntab:Model}
{synopt:{opt m1(string)}}specifies the first regression model to estimate (e.g., {cmd:regress}). This is a required option.{p_end}
{synopt:{opt m1ops(string)}}specifies additional options for the first model (e.g., {cmd:vce(robust)}).{p_end}
{synopt:{opt m2(string)}}specifies the second regression model to estimate (e.g., {cmd:rreg}). This is a required option.{p_end}
{synopt:{opt m2ops(string)}}specifies additional options for the second model (e.g., {cmd:nolog}).{p_end}

{title:Stored Results}

{p 4 4 2}
{cmd:biastest} stores the following results in {cmd:e()}:

{synoptset 25 tabbed}{...}
{syntab:Matrices}
{synopt:{cmd:e(b1)}}coefficients from the first model.{p_end}
{synopt:{cmd:e(V1)}}variance-covariance matrix from the first model.{p_end}
{synopt:{cmd:e(b2)}}coefficients from the second model.{p_end}
{synopt:{cmd:e(V2)}}variance-covariance matrix from the second model.{p_end}
{synopt:{cmd:e(tstat)}}t-statistics for individual parameter tests.{p_end}
{synopt:{cmd:e(pvalues)}}p-values for individual parameter tests.{p_end}

{syntab:Scalars}
{synopt:{cmd:e(chi2)}}chi-squared statistic for the joint test.{p_end}
{synopt:{cmd:e(df_chi2)}}degrees of freedom for the joint test.{p_end}
{synopt:{cmd:e(p_chi2)}}p-value for the joint test.{p_end}

{title:Examples}

{p 4 4 2}
{bf:Example 1: Crime Dataset}
Compare OLS ({cmd:reg}) and robust regression ({cmd:rreg}) results for the crime dataset.

{phang2}
{cmd:. use https://stats.idre.ucla.edu/stat/stata/dae/crime, clear}{p_end}
{phang2}
{cmd:. biastest crime pctmetro pcths poverty, m1(reg) m2(rreg) m2ops(nolog)}{p_end}

{p 4 4 2}
{bf:Example 2: Engel1857 Dataset}
Compare quantile regression ({cmd:sqreg}) results at the 25th and 75th percentiles for the Engel1857 dataset.

{phang2}
{cmd:. webuse engel1857, clear}{p_end}
{phang2}
{cmd:. biastest foodexp income, m1(sqreg) m1ops(q(.25) r(100) nolog) m2(sqreg) m2ops(q(.75) r(100) nolog)}{p_end}

{p 4 4 2}
{bf:Example 3: Grunfeld Dataset}
Compare fixed-effects ({cmd:xtreg, fe}) and random-effects ({cmd:xtreg, re}) models for the Grunfeld dataset.

{phang2}
{cmd:. webuse grunfeld, clear}{p_end}
{phang2}
{cmd:. biastest invest mvalue kstock, m1(xtreg) m1ops(fe) m2(xtreg) m2ops(re)}{p_end}

{title:Author}

{p 4 4 2}
Hasraddin Guliyev, Azerbaijan State University of Economics, {browse "mailto:hasradding@unec.edu.az":hasradding@unec.edu.az}.

{title:Also See}

{p 4 4 2}
{help regress}, {help rreg}, {help sqreg}, {help xtreg}, {help test}
