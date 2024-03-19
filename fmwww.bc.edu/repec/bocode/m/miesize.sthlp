{smcl}
{* *! version 1.0.1  March 2024}{...}

{hline}
help for {hi:miesize}{right:Paul A Tiffin (March 2024)}
{hline}

{viewerdialog miesize "dialog miesize"}{...}
{viewerjumpto "Syntax" "imiesize##syntax"}{...}
{viewerjumpto "Options" "miesize##options"}{...}
{viewerjumpto "Description" "miesize##description"}{...}
{viewerjumpto "remarks" "miesize##remarks"}{...}
{viewerjumpto "Examples" "miesize##examples"}{...}
{viewerjumpto "Stored results" "miesize##results"}{...}
{viewerjumpto "References" "miesize##references"}{...}

{title:Effect size estimation using imputed data}

{marker syntax}{...}
{title:Syntax}

{pstd}
Cohen's {it:d} and Hedges' {it:g} effect size estimation using imputed data

{p 8 14 2}
{cmd:miesize} 
{varname}
{ifin}{cmd:,}
{opth by:(varlist:groupvar)} [{cmd:countdown}]

{pstd}
Glass' delta effect size estimation using imputed data

{p 8 14 2}
{cmd:miesize} 
{varname}
{ifin}{cmd:,}
{opth by:(varlist:groupvar)} [{cmd:glass countdown}]


{title:Options}

{synoptset 18 tabbed}{...}
{marker options_tbl}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt:{opt by}}specifies the {it:groupvar} that defines the two groups that {opt miesize} will use to estimate the effect sizes{p_end}
{synopt:{opt countdown}}specifies that a countdown of analysis steps remaining will be displayed{p_end}
{synopt:{opt glass}}report Glass' Delta (Smith and Glass {help miesize##G1977:1977}) using each group's standard deviation{p_end}
{synopt:{opt l:evel(#)}}set a confidence level between 10 and 99.99%; default is level(95){p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:miesize} calculates effect sizes for a binary variable from multiply imputed data in wide format. The estimates and standard errors
(used to calculate the confidence intervals) are recombined using Rubin's rules (Rubin {help miesize##R2004:2004}). These rules are applied such
that the average point estimate for the effect size is calculated from the imputed datasets. The pooled standard error, and hence confidence
intervals, are calculated in such a way that accounts for both variance between the imputed datasets, as well as the variance within them. Pooled
effect-sizes and confidence intervals for Cohen's {it:d} (Cohen {help miesize##marker C1988:1988}), Hedges'{it:g} (Hedges {help miesize##H1981:1981}) and Glass' Delta (Smith and Glass {help miesize##G1977:1977}) are given.


{title:Remarks}

{p 4 4 2}
{cmd:miesize} can calculate two sample effect sizes from multiply imputed data in wide format. The command can handle situations where 
either one or both variables (namely the outcome and grouping variables) are imputed. When neither variable is detected as imputed 
then the {cmd:esize} command for non-imputed data will be invoked. The imputed data should be in the 'wide' format that stata provides. 
That is, imputed variables are named sequentially as "_m_varname" where m is the imputation number. For example, "_2_price" where this 
is the second imputed dataset for the variable "price". 

{phang}Do not confuse the {opt by()} option with the {cmd:by} prefix, which is not supported by {cmd:miesize}{p_end} 
{phang}See also {mansection R esize:[R] esize}.{p_end} 


{marker examples}{...}
{title:Examples}

{p 4 8 2}{txt: creating some some missing values then performing multiple imputation}

{p 4 8 2}{stata sysuse auto: . sysuse auto}

{p 4 8 2}{stata "mi set wide" : . mi set wide}{p_end}

{p 4 8 2}{stata `"replace price=. if make=="Dodge Colt" | make=="Toyota Celica""': . replace price=. if make=="Dodge Colt" | make=="Toyota Celica"}{p_end}

{p 4 8 2}{stata "replace foreign=. if _n==11 | _n==3" : . replace foreign=. if _n==11 | _n==3}{p_end}

{p 4 8 2}{stata "mi register imputed price foreign" : . mi register imputed price foreign}{p_end}

{p 4 8 2}{stata "mi impute chained (reg) price (logit) foreign=  mpg trunk weight length displacement , add(2) burnin(5)" : . mi impute chained (reg) price (logit) foreign=  mpg trunk weight length displacement , add(2) burnin(5)}{p_end}

{p 4 8 2}{txt: Estimating two sample Cohen's {it:d} and Hedges' {it:g} effect sizes on the imputed datasets}

{p 4 8 2}{stata "miesize price, by(foreign)": . miesize price, by(foreign)}{p_end}

{p 4 8 2}{txt: Estimating a two sample Glass' Delta effect size on the imputed datasets with a countdown provided during the analysis} 

{p 4 8 2}{stata "miesize price, by(foreign) countdown glass":. miesize price, by(foreign) countdown glass}{p_end}

{pstd}


{marker results}{...}
{title:Stored results}

{synoptset 25 tabbed}{...}
{p2col 5 16 25 2: Scalars}{p_end}
{synopt:{cmd:r(pooled_se_d)}}pooled standard error for Cohen's {it:d}{p_end}
{synopt:{cmd:r(pt_est_d)}}pooled point estimate for Cohen's {it:d}{p_end}
{synopt:{cmd:r(ub_d)}}upper confidence limit for the estimate of Cohen's {it:d}{p_end}
{synopt:{cmd:r(lb_d)}}lower confidence limit for the estimate of Cohen's {it:d}{p_end}
{synopt:{cmd:r(pooled_se_g)}}pooled standard error for Hedges' {it:g}{p_end}
{synopt:{cmd:r(pt_est_g)}}pooled point estimate for Hedges' {it:g}{p_end}
{synopt:{cmd:r(ub_g)}}upper confidence limit for the estimate of Hedges' {it:g}{p_end}
{synopt:{cmd:r(lb_g)}}lower confidence limit for the estimate of Hedges' {it:g}{p_end}
{synopt:{cmd:r(pooled_se_g1)}}pooled standard error for Glass's Delta for group 1{p_end}
{synopt:{cmd:r(pt_est_g1)}}pooled point estimate for Glass's Delta for group 1{p_end}
{synopt:{cmd:r(ub_g1)}}upper confidence limit for the estimate of Glass' group 1 Delta{p_end}
{synopt:{cmd:r(lb_g1)}}lower confidence limit for the estimate of Glass' group 1 Delta{p_end}
{synopt:{cmd:r(pooled_se_g2)}}pooled standard error for Glass's Delta for group 2{p_end}
{synopt:{cmd:r(pt_est_g2)}}pooled point estimate for Glass's Delta for group 2{p_end}
{synopt:{cmd:r(ub_g2)}}upper confidence limit for the estimate of Glass' group 2 Delta{p_end}
{synopt:{cmd:r(lb_g2)}}lower confidence limit for the estimate of Glass' group 2 Delta{p_end}
{synopt:{cmd:r(by_var)}}the grouping variable used in the {cmd:by} statement{p_end}
{synopt:{cmd:r(varname)}}the outcome variable used in the command{p_end}


{title:Author}
{p}

{p 4 4 2}Paul Alexander Tiffin{break}
The Hull York Medical School and Department of Health Sciences, University of York, York, UK.{break}
E-mail: {browse "mailto:paul.tiffin@york.ac.uk":paul.tiffin@york.ac.uk}  


{title:Acknowledgements}

{p 4 4 2}Many thanks to Drs Lewis Paton (the Hull York Medical School),
Nick Cox (Durham University), Yulia Marchenko (StataCorp LLC) and Mr Fraser Wiggins (University of York, Clinical Trials Unit) for feedback and advice on an earlier version of the code for
 this command.


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


