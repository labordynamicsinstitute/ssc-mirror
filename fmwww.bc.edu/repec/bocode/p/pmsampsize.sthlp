
{smcl}

{* *! version 1.2.0 09Jun2023}
{cmd:help pmsampsize}
{hline}

{title:Title}

{phang}
{bf:pmsampsize} {hline 2} Calculates the minimum sample size required for developing a multivariable prediction model

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:pmsampsize} , {opt type(string)} 
	[{opt csrsq:uared(real 0)} {opt nagrsq:uared(real 0)} {opt rsq:uared(real 0)} 
	{opt par:ameters(int 0)} {opt n(int 0)} {opt s:hrinkage(real 0.9)} 
	{opt rate(real 0)} {opt meanf:up(real 0)} {opt time:point(real 0)} 
	{opt int:ercept(real 0)} {opt sd(real 0)} {opt prev:alence(real 0)} {opt mmoe(real 1.1)}
	{opt cstat:istic(real 0)} 
	{opt seed(int 123456)}]

{synoptset 30}{...}
{synopthdr:pmsampsize_options}
{synoptline}
{synopt :{opt type(string)}}specifies the type of analysis for which sample size is being calculated{p_end}
{synopt :{opt csrsq:uared(real)}}expected value of the Cox-Snell R-squared of the developed model, based on previous evidence {p_end}
{synopt :{opt nagrsq:uared(real)}}expected value of the Nagelkerke's R-squared of the developed model, based on previous evidence {p_end}
{synopt :{opt rsq:uared(real)}}expected value of the R-squared of the developed model, based on previous evidence {p_end}
{synopt :{opt par:ameters(int)}}number of candidate predictor parameters for potential inclusion in the developed model{p_end}
{synopt :{opt n(int)}}fixed sample size of existing dataset to be used for new model development{p_end}
{synopt :{opt s:hrinkage(real 0.9)}}desired level of shrinkage (a measure of overfitting) in the developed model{p_end}
{synopt :{opt rate(real)}}overall event rate, for the survival (time-to-event) outcome of interest{p_end}
{synopt :{opt meanf:up(real)}}mean follow-up time, for the survival (time-to-event) outcome of interest{p_end}
{synopt :{opt time:point(real)}}timepoint of interest for prediction, for the survival (time-to-event) outcome of interest{p_end}
{synopt :{opt int:ercept(real)}}average outcome value expected within the model development dataset, based on previous evidence (for continuous outcomes){p_end}
{synopt :{opt sd(real)}}standard deviation of outcome values expected within the model development dataset, based on previous evidence (for continuous outcomes){p_end}
{synopt :{opt prev:alence(real)}}outcome proportion (for a prognostic model) or outcome prevalence (for a diagnostic model) expected within the model development dataset, based on previous evidence (for binary outcomes){p_end}
{synopt :{opt mmoe(real 1.1)}}multiplicative margin of error (MMOE) acceptable for calculation of the intercept (for continuous outcomes){p_end}
{synopt :{opt cstat:istic(real)}}approximates Cox-Snell R-squared from C-statistic & prevalence (for binary outcomes){p_end}
{synopt :{opt seed(int 123456)}}set seed for calculation of approximate R-squared from C-statistic (for binary outcomes){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}{cmd: pmsampsize} computes the minimum sample size required for the development of a new multivariable prediction model using the criteria proposed by Riley et al. 2018. 
{cmd: pmsampsize} can be used to calculate the minimum sample size for the development of models with continuous, binary or survival (time-to-event) outcomes. 
Riley et al. lay out a series of criteria the sample size should meet. These aim to minimise the overfitting and to ensure precise estimation of key parameters in the prediction model. 

{pstd}For continuous outcomes, there are four criteria: 
i) small overfitting defined by an expected shrinkage of predictor effects by 10% or less, 
ii) small absolute difference of 0.05 in the model's apparent and adjusted R-squared value, 
iii) precise estimation of the residual standard deviation, and 
iv) precise estimation of the average outcome value. 
The sample size calculation requires the user to pre-specify (e.g. based on previous evidence) the anticipated R-squared of the model, and the average outcome value and standard deviation of outcome values in the population of interest.

{pstd}For binary or survival (time-to-event) outcomes, there are three criteria: 
i) small overfitting defined by an expected shrinkage of predictor effects by 10% or less, 
ii) small absolute difference of 0.05 in the model's apparent and adjusted Nagelkerke's R-squared value, and 
iii) precise estimation (within +/- 0.05) of the average outcome risk in the population for a key timepoint of interest for prediction.

{marker options}{...}
{title:General Options}

{phang}{opt type(string)}specifies the type of analysis for which sample size is being calculated:{p_end}
{pmore}{opt c} specifies sample size calculation for a prediction model with a continuous outcome{p_end}
{pmore}{opt b} specifies sample size calculation for a prediction model with a binary outcome{p_end}
{pmore}{opt s} specifies sample size calculation for a prediction model with a survival (time-to-event) outcome{p_end}

{phang}{opt parameters(int)} specifies the number of candidate predictor parameters for potential inclusion in the new prediction model.
Note that this may be larger than the number of candidate predictors, as categorical and continous predictors often require two or more parameters to be estimated.

{phang}{opt shrinkage(real 0.9)} specifies the level of shrinkage desired at internal validation after developing the new model. 
Shrinkage is a measure of overfitting, and can range from 0 to 1, with higher values denoting less overfitting.
We recommend a shrinkage=0.9 (the default in {cmd: pmsampsize}), which indicates that the predictor effect (beta coefficients) in the model would need to be shrunk by 10% to adjust for overfitting.
See references below for further information.

{marker options}{...}
{title:Binary outcome options}

{phang}{opt csrsquared(real)} specifies the expected value of the Cox-Snell R-squared of the new model, where this is the generalised version of the well-known R-squared for continuous outcomes, based on the likelihood.
For example, the user may input the value of the Cox-Snell R-squared reported for a previous prediction model study in the same field. 
If taking a value from a previous prediction model {it: development} study, users should input the model's {it: adjusted} R-squared value, not the apparent R-squared value, as the latter is optimistic (biased).
However, if taking the R-squared value from an external validation of a previous model, the apparent R-squared can be used (as the validation data was not used for development, and so R-squared apparent is then unbiased).
The papers by Riley et al. (see references) outline how to obtain the Cox-Snell R-squared value from published studies if they are not reported, using other information 
(such as the C-statistic - see {opt cstatistic()} option below).
Users should be conservative with their chosen R-squared value; for example, by taking the R-squared value from a previous model, even if they hope their new model will improve performance.

{phang}{opt nagrsquared(real)} specifies the expected value of the Nagelkerke's R-squared of the new model, where this is the percentage of variation in outcome values explained by the model.
For example, the user may input the value of the Nagelkerke's R-squared reported for a previous prediction model study in the same field. 
If taking a value from a previous prediction model {it: development} study, users should input the model's {it: adjusted} R-squared value, not the apparent R-squared value, as the latter is optimistic (biased).
However, if taking the R-squared value from an external validation of a previous model, the apparent R-squared can be used (as the validation data was not used for development, and so R-squared apparent is then unbiased).
Users should be conservative with their chosen R-squared value; for example, by taking the R-squared value from a previous model, even if they hope their new model will improve performance.

{phang}{opt n(int)} specifies the fixed sample size of an existing dataset to be used for the new model development. 
When using this option {cmd: pmsampsize} calculates the maximum number of candidate predictor parameters that can be considered for potential inclusion in the new prediction model given the fixed sample size of the available dataset.
Remember that the number of candidate predictor parameters is often greater than the number of candidate predictors, as categorical and continous predictors often require two or more parameters to be estimated.
Only one of the {opt parameters()} or {opt n()} options may be specified.

{phang}{opt prevalence(real)} specifies the overall outcome proportion (for a prognostic model) or overall prevalence (for a diagnostic model) expected within the model development dataset. 
This should be derived based on previous studies in the same population.

{phang}{opt cstatistic(real)} specifies the C-statistic reported in an existing prediction model study to be used in conjunction with the expected prevalence to approximate the Cox-Snell R-squared using the approach of Riley et al. 2020. 
Ideally, this should be an optimism-adjusted C-statistic. 
The approximate Cox-Snell R-squared value is used as described above for the {opt rsquared()} option, and so is treated as a baseline for the expected performance of the new model. 

{phang}{opt seed(int 123456)} specifies the initial value of the random-number seed used by the random-number functions when simulating data 
to approximate the Cox-Snell R-squared based on reported C-statistic and expect prevalence as described by Riley et al. 2020. 

{marker options}{...}
{title:Survival outcome options}

{phang}{opt rate(real)} specifies the overall event rate in the population of interest, for example as obtained from a previous study, for the survival outcome of interest. 
NB: rate must be given in time units used for {opt meanfup} and {opt timepoint}

{phang}{opt timepoint(real)} specifies the timepoint of interest for prediction. NB: time units must be the same as given for {opt meanfup} (e.g. years, months)

{phang}{opt meanfup(real)} specifies the average (mean) follow-up time anticipated for individuals in the model development dataset, for example as taken from a previous study in the population of interest. 
NB: time units must be the same as given for {opt timepoint}

{marker options}{...}
{title:Continuous outcome options}

{phang}{opt rsquared(real)} specifies the expected value of the R-squared of the new model, where R-squared is the percentage of variation in outcome values explained by the model.
For example, the user may input the value of the R-squared reported for a previous prediction model study in the same field. 
If taking a value from a previous prediction model {it: development} study, users should input the model's {it: adjusted} R-squared value, not the apparent R-squared value, as the latter is optimistic (biased).
However, if taking the R-squared value from an external validation of a previous model, the apparent R-squared can be used (as the validation data was not used for development, and so R-squared apparent is then unbiased).
Users should be conservative with their chosen R-squared value; for example, by taking the R-squared value from a previous model, even if they hope their new model will improve performance.

{phang}{opt intercept(real 0)} specifies the average outcome value in the population of interest e.g. the average blood pressure, or average pain score. 
This could be based on a previous study, or on clinical knowledge.

{phang}{opt sd(real 0)} specifies the standard deviation (SD) of outcome values in the population e.g. the SD for blood pressure in patients with all other predictors set to the average. 
This could again be based on a previous study, or on clinical knowledge.

{phang}{opt mmoe(real 1.1)} multiplicative margin of error (MMOE) acceptable for calculation of the intercept. 
The default is a MMOE of 10%. Confidence interval for the intercept will be displayed in the output for reference. 
See references below for further information.


{marker examples}{...}
{title:Examples}

{pstd}Examples based on those included in two papers by Riley et al. published in Statistics in Medicine (2018). {p_end}

{phang}
{bf:Binary outcomes (Logistic prediction models)}

{pstd}Use {cmd: pmsampsize} to calculate the minimum sample size required to develop a multivariable prediction model for a binary outcome using 24 candidate predictor parameters. 
Based on previous evidence, the outcome prevalence is anticipated to be 0.174 (17.4%) and a lower bound (taken from the adjusted Cox-Snell R-squared of an existing prediction model) for the new model's R-squared value is 0.288 {p_end}
{phang2}{cmd:. }{stata pmsampsize, type(b) csrsquared(0.288) parameters(24) prevalence(0.174)}{p_end}

{pstd}Now lets assume we could not obtain a Cox-Snell R-squared estimate from an existing prediction model, but instead had a C-statistic (0.89) reported for the existing prediction model. 
We can use this C-statistic along with the prevalence to approximate the Cox-Snell R-squared using the approach of Riley et al. (2020). 
Use {cmd: pmsampsize} with the {opt cstatistic()} option instead of {opt rsquared()} option. {p_end}
{phang2}{cmd:. }{stata pmsampsize, type(b) cstatistic(0.89) parameters(24) prevalence(0.174)}{p_end}

{pstd}Now lets assume we have an existing dataset for developing a new multivariable prediction model, i.e. we have a fixed sample size (N). 
Given a fixed sample size we can use pmsampsize to calculate the maximum number of candidate predictor parameters that can be considered during model development using the existing dataset. 
To do this we use the {opt n()} option and do not specify the {opt parameters} option. 
{p_end}
{phang2}{cmd:. }{stata pmsampsize, type(b) cstatistic(0.89) n(660) prevalence(0.174)}
{p_end}

{phang}
{bf:Survial outcomes (Cox prediction models)}

{pstd}Use {cmd: pmsampsize} to calculate the minimum sample size required for developing a multivariable prediction model with a survival outcome using 25 candidate predictors. 
We know an existing prediction model in the same field has an Cox-Snell R-squared adjusted of 0.051. 
Further, in the previous study the mean follow-up was 2.07 years, and overall event rate was 0.065.
We select a timepoint of interest for prediction using the newly developed model of 2 years {p_end}
{phang2}{cmd:. }{stata  pmsampsize, type(s) csrsquared(0.051) parameters(25) rate(0.065) timepoint(2) meanfup(2.07)}{p_end}

{phang}
{bf:Continuous outcomes (Linear prediction models)}

{pstd}Use {cmd: pmsampsize} to calculate the minimum sample size required for developing a multivariable prediction model for a continuous outcome (here, FEV1 say), using 25 candidate predictors. 
We know an existing prediction model in the same field has an R-squared adjusted of 0.2, and that FEV1 values in the population have a mean of 1.9 and SD of 0.6{p_end}
{phang2}{cmd:. }{stata  pmsampsize, type(c) rsquared(0.2) parameters(25) intercept(1.9) sd(.6)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:pmsampsize} stores the following in {cmd:r()} as relevant for the specific outcome type chosen:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(sample_size)}}Minimum sample size required for model development{p_end}
{synopt:{cmd:r(parameters)}}Number of candidate predictor parameters{p_end}
{synopt:{cmd:r(final_shrinkage)}}Expected shrinkage required{p_end}
{synopt:{cmd:r(r2)}}Specified R-squared adjusted{p_end}
{synopt:{cmd:r(max_r2)}}Maximum Cox-Snell R-squared possible (binary & survival models){p_end}
{synopt:{cmd:r(EPP)}}Events per Predictor Parameter (binary & survival models){p_end}
{synopt:{cmd:r(events)}}Minimum number of events required assuming input outcome proportion or outcome prevalence (binary & survival models){p_end}
{synopt:{cmd:r(prevalence)}}Overall prevalence (binary models){p_end}
{synopt:{cmd:r(rate)}}Overall event rate (survival models){p_end}
{synopt:{cmd:r(SPP)}}Subjects per Predictor Parameter (linear models){p_end}
{synopt:{cmd:r(int_mmoe)}}Multiplicative Margin Of Error (MMOE) for the intercept (linear models){p_end}
{synopt:{cmd:r(var_mmoe)}}MMOE for the residual standard deviation (linear models){p_end}
{synopt:{cmd:r(int_cuminc)}}Estimate of the true cumulative incidence (overall risk) assuming user input overall event rate and timepoint of interest for prediction (survival models){p_end}
{synopt:{cmd:r(int_lci)}}Lower 95% CI for the overall risk (survival models){p_end}
{synopt:{cmd:r(int_uci)}}Upper 95% CI for the overall risk (survival models){p_end}
{synopt:{cmd:r(cstatistic)}}C-statistic input by user to approximate R-squared (binary models){p_end}
{synopt:{cmd:r(seed)}}Seed used to approximate R-squared from C-statistic (binary models){p_end}
{p2colreset}{...}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}A matrix of all tabular output{p_end}
{p2colreset}{...}

{title:Authors}

{phang}Joie Ensor, University of Birmingham {break}
j.ensor@bham.ac.uk{p_end}

{title:Acknowledgements}

{phang}With thanks to Richard Riley, Gary Collins, Glen Martin & Kym Snell for helpful feedback{p_end}

{marker reference}{...}
{title:References}

{p 5 12 2}
Riley RD, Ensor J, Snell KIE, Harrell FE, Martin GP, Reitsma JB, Moons KGM, Collins G, van Smeden M. Calculating the sample size required for developing a 
clinical prediction model. {it:BMJ}. 2020.{p_end}

{p 5 12 2}
Riley RD, Snell KIE, Ensor J, Burke DL, Harrell FE, Jr., Moons KG, Collins GS. 
Minimum sample size required for developing a multivariable prediction model: Part I continuous outcomes. {it:Statistics in Medicine}. 2019.{p_end}

{p 5 12 2}
Riley RD, Snell KIE, Ensor J, Burke DL, Harrell FE, Jr., Moons KG, Collins GS. 
Minimum sample size required for developing a multivariable prediction model: Part II binary and time-to-event outcomes. {it:Statistics in Medicine}. 2019.{p_end}

{p 5 12 2}
Riley, RD, Van Calster, B, Collins, GS. A note on estimating the Cox‐Snell R2 from a reported C statistic (AUROC) to inform sample size calculations for developing a prediction model with a binary outcome. 
{it:Statistics in Medicine}. 2020.{p_end}


{title:Also see}

{psee}
Online: {helpb pmvalsampsize}, {helpb pmcalplot}, {helpb matlist}
{p_end}
