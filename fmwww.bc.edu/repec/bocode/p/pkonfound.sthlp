{smcl}
{* *! version 1.1.1  24jan2017}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "pkonfoundhelpfile##syntax"}{...}
{viewerjumpto "Description" "pkonfoundhelpfile##description"}{...}
{viewerjumpto "Options" "pkonfoundhelpfile##options"}{...}
{viewerjumpto "Remarks" "pkonfoundhelpfile##remarks"}{...}
{viewerjumpto "Examples" "pkonfoundhelpfile##examples"}{...}
{viewerjumpto "Authors" "pkonfoundhelpfile##authors"}{...}
{viewerjumpto "References" "pkonfoundhelpfile##references"}{...}
{title:Title}

{phang} 
{bf:pkonfound} {hline 2} This command calculates sensitivity analysis for published studies. This command calculates (1) how much bias there must be in an estimate to nullify/sustain an inference; (2) the impact of an omitted variable necessary to nullify/sustain an inference for a regression coefficient.


{marker syntax}{...}
{title:Syntax}

{phang}
{bf:Linear model} 

{pstd}
This model type calculates the following indices for the user's linear model: (1) the Impact Threshold for a Confounding Variable (ITCV), which indicates how strongly an omitted variable must be correlated with both the predictor of interest and the outcome to adjust the estimated effect to a user-specified p-value (e.g., 0.05); and (2) the Robustness of Inference to Replacement (RIR), which measures the proportion of data that must be replaced (with cases showing a specific null effect) to adjust the estimated effect to a given p-value (e.g., 0.5).

{p 8 17 2}
{cmdab:pkonfound}
[{# # # #}]
[,{cmd:model_type(0)} {it:options}]

{synoptset 20 tabbed}{...}
{syntab: {ul:Main}}
{synopt:{opt est_eff}} the estimated value of the regression coefficient{p_end}
{synopt:{opt std_err}} the standard error of the regression coefficient{p_end}
{synopt:{opt n_obs}} the sample size{p_end}
{synopt:{opt n_covariates}} the number of covariates in the model{p_end}

{syntab: {ul:Options}}

{phang}
{opt model_type(#)} Model type selection variable; the default is {cmd:model_type(0)} which applies to linear models

{phang}
{opt sig(#)} Significance level of the test; default is 0.05 {cmd:sig(.05)}. 
             To change the significance level to .10 use {cmd:sig(.1)}

{phang}
{opt nu(#)} The null hypothesis against which to test the estimate. Default is {cmd:nu(0)}

{phang}
{opt onetail(#)} Integer whether hypothesis testing is one-tailed or two-tailed;
        the default is two-tail {cmd:onetail(0)};
		to change to one-tail use {cmd:onetail(1)}

{phang}
{opt far_bound(#)} Whether the estimated effect is moved to the boundary closer {cmd:far_bound(0)} or further away {cmd:far_bound(1)}; default is {cmd:far_bound(0)}

{phang}
{opt sdx(#)} The standard deviation of X, specifically for unconditional ITCV calculations; the default value is NA {cmd:sdx(NA)}; to activate the unconditional ITCV calculations and give the value of sdx as m use {cmd:sdx(m)}.
Note that to calculate unconditional ITCV, one must specify sdx, sdy and rs at the same time.

{phang}
{opt sdy(#)} The standard deviation of Y, specifically for unconditional ITCV calculations; the default value is NA {cmd:sdy(NA)}; to activate the unconditional ITCV calculations and give the value of sdy as n use {cmd:sdy(n)}

{phang}
{opt rs(#)} The R-squared of the regression, specifically for unconditional ITCV calculations; the default value is NA {cmd:rs(NA)}; to activate the unconditional ITCV calculations and give the value of rs as p use {cmd:rs(p)}.
Please enter R-squared with the accuracy as high as possible, recommended at least 5 decimal points, because even small changes in R-squared can have a large impact on unconditional ITCV

{phang}
{opt eff_thr(#)} The users specified effective threshold; the default value is NA {cmd:eff_thr(NA)}

{phang}
{opt indx(#)} The user can specify whether the output for a linear model should be RIR {cmd:indx("RIR")} or ITCV {cmd:indx("IT")}; the default is RIR. To change to ITCV one should specify {cmd:indx("IT")} 		
		
{syntab: {ul:Values}}

{pstd}
To view these stored results, use the {cmd:return list} command immediately after running the pkonfound command.
		
{phang}
{opt obs_r}
Correlation between predictor of interest and outcome in the sample data

{phang}
{opt act_r}
Correlation between predictor of interest and outcome from the sample regression based on the t-ratio accounting for a non-zero null hypothesis

{phang}
{opt critical_r}
Critical correlation value at which the inference would be nullified, e.g., associated with p=0.05

{phang}
{opt r_final}
Final correlation value given CV, should be equal to critical_r

{phang}
{opt rxcv}
Correlation between predictor of interest (X) and CV necessary to nullify the inference for smallest impact

{phang}
{opt rycv}
Correlation between outcome (Y) and CV necessary to nullify the inference for smallest impact

{phang}
{opt rxcvGz}
Correlation between predictor of interest and CV necessary to nullify the inference for smallest impact, conditioning on all observed covariates (Given Z)

{phang}
{opt rycvGz}
Correlation between outcome and CV necessary to nullify the inference for smallest impact, conditioning on all observed covariates (Given Z)

{phang}
{opt itcvGz}
ITCV conditioning on the observed covariates

{phang}
{opt itcv}
Unconditional ITCV

{phang}
{opt benchmark_corr_product}
Benchmark correlation product representing the product RxZ × RyZ, capturing the association strength of all observed covariates Z with the predictor X and the outcome Y.

{phang}
{opt itcv_ratio_to_benchmark}
ITCV ratio to benchmark. The ratio of the required correlation product to the benchmark correlation product.

{phang}
{opt beta_threshold}
Threshold value for estimated effect

{phang}
{opt beta_threshold_verify}
Estimated effect given RIR. Should be equal to beta_threshold

{phang}
{opt perc_bias_to_change}
Percent bias needed to change the inference

{phang}
{opt RIR_primary}
Robustness of Inference to Replacement (RIR)

{phang}
{opt RIR_perc}
RIR as % of total sample (for linear regression) 


{phang}
{bf:Coefficient of Proportionality} 

{pstd}
This command calculates the correlation between the omitted variable and the focal predictor and between the omitted variable and the outcome necessary to make the estimated effect of the focal predictor be zero and an R-squared as specified on input. These correlations also generate the Coefficient of Proportionality (COP), the proportion selection on unobservables (omitted covariates) relative to observables (observed covariates) necessary to reduce the effect of the focal predictor to zero for a specified R-squared. COP requires extra inputs including the standard deviation of the outcome (Y), of the focal predictor (X), the observed R-squared, and the desired final R-squared (fr2max).

{p 8 17 2}
{cmdab:pkonfound}
[{# # # # # # #}]
[,{cmd:model_type(0) indx("COP")} {it:options}]

{synoptset 20 tabbed}{...}
{syntab: {ul:Main}}
{synopt:{opt est_eff}} the estimated effect size of the independent variable on the dependent variable{p_end}
{synopt:{opt std_err}} the standard error of the estimated effect size{p_end}
{synopt:{opt n_obs}} the total number of observations in the model{p_end}
{synopt:{opt n_covariates}} the number of covariates in the model{p_end}
{synopt:{opt sdx}} the standard deviation of the independent variable in the model{p_end}
{synopt:{opt sdy}} the standard deviation of the dependent variable in the model{p_end}
{synopt:{opt rs}} the R-squared value from the the model{p_end}

{syntab: {ul:Options}}

{phang}
{opt eff_thr(#)} Effect size threshold for sensitivity analysis; default is 0

{phang}
{opt fr2max_multiplier(#)} Multiplier for calculating FR2max when FR2max is not specified; default is 1.3

{phang}
{opt fr2max(#)} The largest R-squared value in the final model with unobserved confounder; default is 0.61

{phang}
{opt sig(#)} Significance level of the test; default is 0.05 {cmd:sig(.05)}; to change the significance level to .10 use {cmd:sig(.1)}

{phang}
{opt onetail(#)} Integer whether hypothesis testing is one-tailed or two-tailed; the default is two-tail {cmd:onetail(0)}; to change to one-tail use {cmd:onetail(1)}

{syntab: {ul:Values}}

{pstd}
To view these stored results, use the {cmd:return list} command immediately after running the pkonfound command.

{phang}
{opt delta_star} Delta calculated using Oster's unrestricted estimator

{phang}
{opt delta_star_restricted} Delta calculated using Oster's restricted estimator

{phang}
{opt delta_exact} Precise delta value, providing a more accurate assessment

{phang}
{opt delta_pctbias} Percent of bias when comparing delta_star with delta_exact

{phang}
{opt var_y} Variance of the dependent variable 

{phang}
{opt var_x} Variance of the independent variable

{phang}
{opt var_cv} Variance of the confounding variable

{phang}
{opt conditional_rir_pi_fixed_y} The proportional impact of replacing cases with a fixed value on the inference, offering a ratio that represents the sensitivity of the inference to such replacements.

{phang}
{opt conditional_rir_fixed_y} The conditional replacement inference risk (RIR) when replacement cases have a fixed value, quantifying the number of cases that must be replaced to nullify the statistical inference.

{phang}
{opt conditional_rir_pi_null} The proportional impact of replacements assuming a null distribution, providing insight into the robustness of the inference when adding null-effect cases.

{phang}
{opt conditional_rir_null} The conditional RIR under the assumption that replacement cases follow a null distribution. It estimates the impact of replacing a proportion of the sample with cases that have no effect.

{phang}
{opt conditional_rir_pi_rxygz} The proportional impact of such replacements, indicating how the assumption of zero conditional correlation affects the inference.

{phang}
{opt conditional_rir_rxygz} The conditional RIR when replacements satisfy the condition that the correlation between the dependent and independent variables given Z is zero, highlighting the sensitivity to this specific type of unobserved confounding.

{phang}
{opt cor_oster} Correlation matrix implied by delta_star

{phang}
{opt cor_exact} Correlation matrix implied by delta_exact


{phang}
{bf:Preserving the Standard Error} 

{pstd}
This command calculates the correlation between the omitted variable and the focal predictor and between the omitted variable and the outcome necessary to make the estimated effect of the focal predictor have a p-value of .05 while Preserving the Standard Error (PSE) of the original analysis. PSE requires extra inputs including the threshold for inference (e.g., 1.96 x standard error), standard deviation of the outcome (Y), the standard deviation of the focal predictor (X) and the observed R-squared.

{p 8 17 2}
{cmdab:pkonfound}
[{# # # # # # #}]
[,{cmd:model_type(0) indx("PSE")} {it:options}]

{synoptset 20 tabbed}{...}
{syntab: {ul:Main}}
{synopt:{opt est_eff}} the estimated effect size of the independent variable on the dependent variable{p_end}
{synopt:{opt std_err}} the standard error of the estimated effect size{p_end}
{synopt:{opt n_obs}} the total number of observations in the model{p_end}
{synopt:{opt n_covariates}} the number of covariates in the model{p_end}
{synopt:{opt sdx}} the standard deviation of the independent variable in the model{p_end}
{synopt:{opt sdy}} the standard deviation of the dependent variable in the model{p_end}
{synopt:{opt rs}} the R-squared value from the the model{p_end}

{syntab: {ul:Options}}

{phang}
{opt eff_thr(#)} Effect size threshold for sensitivity analysis; default is 0

{syntab: {ul:Values}}

{pstd}
To view these stored results, use the {cmd:return list} command immediately after running the pkonfound command.

{phang}
{opt Final Table} The Final Table summarizes the regression results for models M1, M2, and M3. M1 includes only the predictor X; M2 adds Z; and M3 includes both Z and CV. Each model demonstrates how adding variables affects the relationship between predictors and the outcome

{phang2}
R2: Represents the proportion of variance in the dependent variable explained by the predictors in each model. An increasing R2 value typically indicates a better model fit

{phang2}
coef_X: The coefficient for the predictor X in each model, showing the effect size of X on the dependent variable. A decrease in this coefficient across models might suggest the presence of confounding factors or shared variance with other predictors

{phang2}
SE_X: The standard error of the coefficient for X, reflecting the precision of the estimate. Smaller SE values indicate more precise estimates

{phang2}
std_coef_X: The standardized coefficient for X, allowing for comparisons across variables on a common scale. This metric is useful for assessing the relative importance of predictors

{phang2}
t_X: The t-statistic for the coefficient of X, used to test the null hypothesis that the coefficient is zero. Higher t-values indicate more significant predictors

{phang2}
coef_Z, SE_Z, t_Z: These columns provide the coefficient, standard error, and t-statistic for the predictor Z, which is introduced in Model 2 (M2) and included in Model 3 (M3)

{phang2}
coef_CV, SE_CV, t_CV: These columns pertain to CV, introduced in Model 3 (M3). These metrics allow for the examination of the effect of CV while controlling for other predictors

{phang}
{opt se_x_M3} The standard error of the estimated effect size for the predictor of interest

{phang}
{opt eff_x_M3} The estimated effect size for the predictor of interest

{phang}
{opt rycv} correlation between outcome (Y) and CV necessary to nullify the inference for smallest impact

{phang}
{opt rxcv} correlation between predictor of interest (X) and CV necessary to nullify the inference for smallest impact

{phang}
{opt rycvGz} correlation between outcome and CV necessary to nullify the inference for smallest impact conditioning on all observed covariates (given z)

{phang}
{opt rxcvGz} correlation between predictor of interest and CV necessary to nullify the inference for smallest impact conditioning on all observed covariates (given z)



{phang}
{bf:Logistic regression model} 

{pstd}
For user's logistic regression model, this command calculates Fragility – the number of data points that must be switched (e.g., from treatment success to treatment failure) to make the association between treatment and outcome have a specified p-value (e.g., .05). It also calculates the Robustness of Inference to Replacement (RIR), the number of data points that must be replaced to generate the switches associated with Fragility. 

{p 8 17 2}
{cmdab:pkonfound}
[{# # # # #}]
[,{cmd:model_type(1)} {it:options}]

{synoptset 20 tabbed}{...}
{syntab: {ul:Main}}
{synopt:{opt est_eff}} the estimated effect (such as an unstandardized beta coefficient or a group mean difference){p_end}
{synopt:{opt std_err}} the standard error of the regression coefficient{p_end}
{synopt:{opt n_obs}} the number of observations in the sample{p_end}
{synopt:{opt n_covariates}} the number of covariates in the regression model{p_end}
{synopt:{opt n_treat}} the number of cases associated with the treatment condition{p_end}

{syntab: {ul:Options}}

{phang}
{opt model_type(#)} Model type selection variable; the default is {cmd:model_type(0)} which applies to linear models; to change to logistic regression use {cmd:model_type(1)}

{phang}
{opt sig(#)} Significance level of the test; default is 0.05 {cmd:sig(.05)}; 
             to change the significance level to .10 use {cmd:sig(.1)}

{phang}
{opt onetail(#)} Integer whether hypothesis testing is one-tailed or two-tailed;
        the default is two-tail {cmd:onetail(0)};
		to change to one-tail use {cmd:onetail(1)}			 
			 
{phang}
{opt switch_trm(#)} Whether to switch the treatment and control cases; defaults to True {cmd:switch_trm(1)}.

{phang}
{opt replace(#)} Whether using entire sample or the control group to calculate the base rate; the default value is control {cmd:replace(1)}, to change to entire use {cmd:replace(0)}

{syntab: {ul:Values}}

{pstd}
To view these stored results, use the {cmd:return list} command immediately after running the pkonfound command.

{phang}
{opt RIR_primary}
Robustness of Inference to Replacement (RIR)

{phang}
{opt RIR_supplemental}
RIR for an extra row or column that is needed to nullify the inference

{phang}
{opt RIR_perc}
RIR as % of data points in the cell where replacement takes place (for logistic and 2 by 2 table)

{phang}
{opt fragility_primary}
Fragility; the number of switches (e.g., treatment success to treatment failure) to nullify the inference

{phang}
{opt fragility_supplemental}
Fragility for an extra row or column that is needed to nullify the inference

{phang}
{opt starting_table}
Observed 2 by 2 table before replacement and switching. Implied table for logistic regression

{phang}
{opt final_table}
The 2 by 2 table after replacement and switching

{phang}
{opt user_SE}
User entered standard error. Only applicable for logistic regression

{phang}
{opt analysis_SE}
The standard error used to generate a plausible 2 by 2 table. Only applicable for logistic regression



{phang}
{bf:2x2 table} 

{pstd}
This command calculates indices such as the Fragility and the Robustness of Inference to Replacement (RIR) for a 2x2 contingency table, commonly used in clinical trials and epidemiological studies. The Fragility measures how many data points must be switched (e.g., from treatment success to treatment failure) to render the association statistically insignificant. The RIR builds on this by quantifying how many data points need to be replaced with hypothetical ones to change the inference.

{p 8 17 2}
{cmdab:pkonfound}
[{# # # #}]
[,{cmd:model_type(2)} {it:options}]

{synoptset 20 tabbed}{...}
{syntab: {ul:Main}}
{synopt:{opt a}} the number of cases in the control group showing unsuccessful results{p_end}
{synopt:{opt b}} the number of cases in the control group showing successful results{p_end}
{synopt:{opt c}} the number of cases in the treatment group showing unsuccessful results{p_end}
{synopt:{opt d}} the number of cases in the treatment group showing successful results{p_end}

{syntab: {ul:Options}}

{phang}
{opt model_type(#)} Model type selection variable; the default is {cmd:model_type(0)} which applies to linear models; to change to 2 by 2 table use {cmd:model_type(2)}

{phang}
{opt sig(#)} Significance level of the test; default is 0.05 {cmd:sig(.05)}. 
             To change the significance level to .10 use {cmd:sig(.1)}

{phang}
{opt switch_trm(#)} Whether to switch the treatment and control cases; defaults to True {cmd:switch_trm(1)}.

{phang}
{opt replace(#)} Whether using entire sample or the control group to calculate the base rate; the default value is control {cmd:replace(1)}, to change to entire use {cmd:replace(0)}

{phang}
{opt test1(#)} Whether using Fisher's Exact Test or a chi-square test; the default value is Fisher's Exact Test {cmd:test1(0)}; to change to chi-square test use {cmd:test1(1)}

{syntab: {ul:Values}}

{pstd}
To view these stored results, use the {cmd:return list} command immediately after running the pkonfound command.

{phang}
{opt RIR_primary}
Robustness of Inference to Replacement (RIR)

{phang}
{opt RIR_perc}
RIR as % of data points in the cell where replacement takes place (for logistic and 2 by 2 table)

{phang}
{opt fragility_primary}
Fragility; the number of switches (e.g., treatment success to treatment failure) to nullify the inference

{phang}
{opt starting_table}
Observed 2 by 2 table before replacement and switching. Implied table for logistic regression

{phang}
{opt final_table}
The 2 by 2 table after replacement and switching


{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:pkonfound} this command calculates (1) how much bias there must be in an estimate to nullify/sustain an inference. The bias necessary to nullify/sustain an inference is interpreted in terms of sample replacement; (2) the impact of an omitted variable necessary to nullify/sustain an inference for a regression coefficient. It also assesses how strong an omitted variable has to be correlated with the outcome and the predictor of interest to nullify/sustain the inference.


{marker examples}{...}
{title:Examples}

{pstd}
## Assume in a linear model, the estimate is 10, the standard error of the estimate is 2, the sample size is 100, and the number of covariates is 5

{phang}For the result of RIR: {p_end}
{phang}{cmd:. pkonfound 10 2 100 5, indx("RIR")}{p_end}

{phang}For the result of ITCV: {p_end}
{phang}{cmd:. pkonfound 10 2 100 5, indx("IT")}{p_end}

{pstd}
## Assume in a linear model, the estimate is 10, the standard error of the estimate is 2, the sample size is 100, the number of covariates is 5, the standard deviation of X is 0.3, the standard deviation of Y is 0.5, and the R-squared of the regression is 0.7. To calculate unconditional ITCV:

{phang}{cmd:. pkonfound 10 2 100 5, sdx(0.3) sdy(0.5) rs(0.7) indx("IT")}{p_end}

{pstd}
## Assume in a study that the estimate is 0.125, the standard error of the estimate is 0.1, the sample size is 6174, and the number of covariates is 7. The standard deviation of the independent variable is 0.217, and the standard deviation of the dependent variable is 0.991. The R-squared value from the regression model is 0.251, with a specified threshold of 0 and a specified maximum R-squared of 0.61, using a significance level of 0.05 and a two-tailed test to calculate coefficient of proportionality.

{phang}{cmd:. pkonfound 0.125 0.1 6174 7 0.217 0.991 0.251, eff_thr(0) fr2max(0.61) sig(0.05) onetail(0) indx("COP")}{p_end}

{pstd}
## Assume in a study that the estimate is 0.5, the standard error of the estimate is 0.056, the sample size is 6174, and the number of covariates is 1. The standard deviation of the independent variable is 0.22, and the standard deviation of the dependent variable is 1. The R-squared value from the regression model is 0.3, with a specified threshold of 0.1. This setup calculates the correlation between a confounding variable (CV) and both the independent variable (X) and the dependent variable (Y), where the CV is strong enough to reduce the estimated effect size to the threshold while preserving the standard error.

{phang}{cmd:. pkonfound 0.5 0.056 6174 1 0.22 1 0.3, eff_thr(0.1) indx("PSE")}{p_end}

{pstd}
## Assume in a logistic regression, the estimate is -0.2, the standard error of the estimate is 0.103, the sample size is 20888, the number of covariates is 3, and the number of cases in the treatment condition is 17888.

{phang}{cmd:. pkonfound -0.2 0.103 20888 3 17888, model_type(1)}{p_end}

{pstd}
## In a binary outcome - binary treatment scenario, we have 35 participants in the control group showing unsuccessful results, 17 in the control group showing successful results, 10 in the treatment group showing unsuccessful results, and 5 in the treatment group showing successful results.

{phang}{cmd:. pkonfound 35 17 10 5, model_type(2)}{p_end}


{marker authors}{...}
{title:Authors}

{phang} Ran Xu {p_end}
{phang} University of Connecticut {p_end}

{phang} Xuesen Cheng {p_end}
{phang} Michigan State University {p_end}

{phang} Jihoon Choi {p_end}
{phang} Michigan State University {p_end}

{phang} Kenneth A. Frank {p_end}
{phang} Michigan State University {p_end}

{phang} Qinyun Lin {p_end}
{phang} University of Gothenburg {p_end}

{phang} Spiro Maroulis {p_end}
{phang} Arizona State University {p_end}

{phang} Sarah Narvaiz {p_end}
{phang} University of Tennessee, Knoxville {p_end}

{phang} Joshua Rosenberg {p_end}
{phang} University of Tennessee, Knoxville {p_end}

{phang} Guan K. Saw {p_end}
{phang} Claremont Graduate University {p_end}

{phang} Wei Wang {p_end}
{phang} University of Tennessee, Knoxville {p_end}

{phang} Gaofei Zhang {p_end}
{phang} University of Connecticut {p_end}

{phang} Please email {bf:ran.2.xu@uconn.edu} if you observe any problems. {p_end}


{marker references}{...}
{title:References}

{pstd}
Frank, K.A. (2000). Impact of a Confounding Variable on the Inference of a Regression Coefficient. Sociological Methods and Research, 29(2), 147-194.

{pstd}
Frank, K.A., Maroulis, S., Duong, M., and Kelcey, B. (2013). What would it take to Change an Inference?: Using Rubin's Causal Model to Interpret the Robustness of Causal Inferences. Education, Evaluation and Policy Analysis. 35, 437-460.

{pstd}
Frank, K. A., *Lin, Q., *Maroulis, S., *Mueller, A. S., Xu, R., Rosenberg, J. M., ... & Zhang, L. (2021). Hypothetical Case Replacement Can Be Used to Quantify the Robustness of Trial Results. Journal of Clinical Epidemiology, 134, 150-159. *authors are listed alphabetically.

{pstd}
Frank, K., Lin, Q., Maroulis, S., Dai, S., Jess, N., Lin, H. C., ... & Tait, J. (2022). Improving Oster's δ*: Exact Calculation for the Coefficient of Proportionality Without Subjective Specification of a Baseline Model.

{pstd}
Frank, K.A., Lin, Q., Xu, R., Maroulis, S., Mueller, A. (2023). Quantifying the Robustness of Causal Inferences: Sensitivity Analysis for Pragmatic Social Science, Social Science Research, 110, 102815.


See {browse "https://konfound-it.org/":https://konfound-it.org/} for more information.

