{smcl}
{* *! version 1.0.0 07jan2023}{...}
{cmd:help miesize}
{hline}


{title:Title}


{phang}
{bf:miesize  {hline 2} Estimate effect sizes from multiply imputed data}


{title:Syntax}

   Cohen's {it:d} and Hedges' {it:g} effect size estimation using imputed data

{p 8 }
{cmd:miesize} {varlist} {ifin}  {cmd:,} {opth by:(varlist:groupvar)} [{cmd:countdown}]


   Glass' delta effect size estimation using imputed data

{p 8 }
{cmd:miesize} {varlist} {ifin}  {cmd:,} {opth by:(varlist:groupvar)} [{cmd:glass countdown}]

{title:Options}

{synoptset 18 tabbed}{...}
{marker options_tbl}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt:{opt by}}specifies the {it:groupvar} that defines the two groups that {opt miesize} will use to estimate the effect sizes{p_end}
{synopt:{opt countdown}}specifies that a countdown of analysis steps remaining will be displayed{p_end}
{synopt:{opt glass}}report Glass' Delta (Smith and Glass {help miesize##G1977:1977}) using each group's standard deviation{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}
  {cmd:miesize} calculates effect sizes for a binary variable from multiply imputed data in wide format. The estimates and standard errors
  (used to calculate the confidence intervals) are recombined using Rubin's rules (Rubin {help miesize##R2004:2004}). These rules are applied such
  that the average point estimate for the effect size is calculated from the imputed datasets. The pooled standard error, and hence 95% confidence
  intervals, are calculated in such a way that accounts for both variance between the imputed datasets, as well as the variance within them. Pooled
  effect-sizes and confidence intervals for Cohen's {it:d} (Cohen {help miesize##marker C1988:1988}), Hedges'{it:g} (Hedges {help miesize##H1981:1981}) and Glass' Delta (Smith and Glass {help miesize##G1977:1977}) are given.

{title:Remarks}
    {cmd:miesize} can calculate two sample effect sizes from multiply imputed data in wide format. The command can handle situations where 
    either one or both variables (namely the outcome and grouping variables) are imputed. When neither variable is detected as imputed 
    then the {cmd:esize} command for non-imputed data will be invoked. The imputed data should be in the 'wide' format that stata provides. 
    That is, imputed variables are named sequentially as "_m_varname" where m is the imputation number. For example, "_2_price" where this 
    is the second imputed dataset for the variable "price". 

{phang}Do not confuse the {opt by()} option with the {cmd:by} prefix, which is not supported by {cmd:miesize}{p_end} 
{phang}See also {mansection R esize:[R] esize}.{p_end} 

{title:Examples}
Setup (creating some some missing values then performing multiple imputation)
{phang}{stata "sysuse auto" : . sysuse auto}{p_end}
{phang}{stata "mi set wide" : . mi set wide}{p_end}
{phang}{stata `"replace price=. if make=="Dodge Colt" | make=="Toyota Celica""': . replace price=. if make=="Dodge Colt" | make=="Toyota Celica"}{p_end}
{phang}{stata "replace foreign=. if _n==11 | _n==3" : . replace foreign=. if _n==11 | _n==3}{p_end}
{phang}{stata "mi register imputed price foreign" : . mi register imputed price foreign}{p_end}
{phang}{stata "mi impute chained (regress) price (logit) foreign, add(3)" : . mi impute chained (regress) price (logit) foreign, add(3)}{p_end}

Estimating two sample Cohen's {it:d} and Hedges' {it:g} effect sizes on the imputed datasets 
{phang}{stata "miesize price, by(foreign)": . miesize price, by(foreign)}{p_end}

Estimating a two sample Glass' Delta effect size on the imputed datasets with a countdown provided during the analysis 
{phang}{stata "miesize price, by(foreign) countdown glass":. miesize price, by(foreign) countdown glass}{p_end}

{marker results}{...}
{title:Stored results}

{synoptset 25 tabbed}{...}
{p2col 5 16 25 2: Scalars}{p_end}
{synopt:{cmd:r(pooled_se_d)}}pooled standard error for Cohen's {it:d}{p_end}
{synopt:{cmd:r(pt_est_d)}}pooled point estimate for Cohen's {it:d}{p_end}
{synopt:{cmd:r(ul_d)}}upper 95% confidence limit for the estimate of Cohen's {it:d}{p_end}
{synopt:{cmd:r(pooled_se_g)}}pooled standard error for Hedges' {it:g}{p_end}
{synopt:{cmd:r(pt_est_g)}}pooled point estimate for Hedges' {it:g}{p_end}
{synopt:{cmd:r(ul_g)}}upper 95% confidence limit for the estimate of Hedges' {it:g}{p_end}
{synopt:{cmd:r(pooled_se_g1)}}pooled standard error for Glass's Delta for group 1{p_end}
{synopt:{cmd:r(pooled_estimate_g1)}}pooled point estimate for Glass's Delta for group 1{p_end}
{synopt:{cmd:r(ul_g1)}}upper 95% confidence limit for the estimate of Glass' group 1 Delta{p_end}
{synopt:{cmd:r(pooled_se_g2)}}pooled standard error for Glass's Delta for group 2{p_end}
{synopt:{cmd:r(pooled_estimate_g2)}}pooled point estimate for Glass's Delta for group 2{p_end}
{synopt:{cmd:r(ul_g2)}}upper 95% confidence limit for the estimate of Glass' group 2 Delta{p_end}
{synopt:{cmd:r(by_var)}}the grouping variable used in the {cmd:by} statement{p_end}
{synopt:{cmd:r(varname)}}the outcome variable used in the command{p_end}


{marker references}{...}
{title:References}

{marker C1988}{...}
{phang}
Cohen, J. 1988.
{it:Statistical Power Analysis for the Behavioral Sciences}. 2nd ed.
Hillsdale, NJ: Erlbaum.

{marker H1981}{...}
{phang}
Hedges, L. V. 1981.
Distribution theory for Glass's estimator of effect size and related estimators.
{it:Journal of Educational Statistics} 6: 107-128.

{marker R2004}{...}
{phang}
Rubin, J. 2004.
{it:Multiple imputation for nonresponse in surveys}. 
Hoboken, NJ: John Wiley & Sons. 

{marker G1977}{...}
{phang}
Smith, M. L., and G. V. Glass. 1977.
Meta-analysis of psychotherapy outcome studies.  
{it:American Psychologist} 32: 752-760.
{p_end}

{title:Author and developer}
{phang}Paul Alexander Tiffin{p_end}
{phang}The Hull York Medical School and Department of Health Sciences, University of York, York, UK.{p_end}
{phang}E-mail: {browse "mailto:paul.tiffin@york.ac.uk":paul.tiffin@york.ac.uk}{p_end}  


