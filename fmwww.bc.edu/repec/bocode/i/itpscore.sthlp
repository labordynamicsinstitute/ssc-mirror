{smcl}
{viewerjumpto "Syntax" "itpscore##syntax"}{...}
{viewerjumpto "Description" "itpscore##description"}{...}
{viewerjumpto "Required Inputs" "itpscore##required"}{...}
{viewerjumpto "Options" "itpscore##options"}{...}
{viewerjumpto "Remarks" "itpscore##remarks"}{...}
{viewerjumpto "Examples" "itpscore##examples"}{...}

{title:Title}

{p 3 3 0 0} {bf:itpscore} - Iterative Propensity Score Logistic Regression Model Search Procedure

{marker syntax}{...}

{title:Syntax}

{p 3 3 0 0} {cmd:itpscore}, {cmd:treat}({it:newvar}) {cmd:cand}({it:varlist}) [ {cmd:base}({it:varlist})
{cmd:thr1}(#) {cmd:thr2}(#) {cmd:rand}(int) {cmd:keepint} {cmd:viewiter } ]

{marker description}{...}

{title:Description}

{p 3 3 0 0} The itpscore routine implements the Imbens and Rubin (2015) algorithm that identifies the “best” propensity score model by selecting covariates that lead to the greatest gains in the logit log-likelihood function. 
The method executes the following steps:

{p 5 5 0 0} (1) Estimate a baseline logistic regression model with user-specified baseline covariates and a constant term. Record the baseline log-likelihood as L_0.

{p 5 5 0 0} (2) For each user-specified candidate covariate, estimate a model that includes all baseline model variables and the  candidate covariate. Record the resulting log-likelihood for each model.

{p 5 5 0 0} (3) Of the models estimated in (2), select the model/candidate covariate with the highest log-likelihood. Record this likelihood value as L_1 and designate the corresponding covariate as the “best” covariate.

{p 5 5 0 0} (4) If model improvement of the “best” covariate satisfies the inclusion condition 2*(L_1 – L_0})>T_1, add the “best” covariate to the iterative model. Designate the updated iterative model as the new baseline model and repeat steps (1)–(4) until the inequality in (4) is no longer satisfied. (Note: By default, T_1=2.71. See the thr1 option below to alter this value.)

{p 5 5 0 0} (5) Generate first order interaction and quadratic terms for use as candidate variables. Repeat steps (1)–(4) on a new set of candidate variables using the updated inclusion condition 2*(L_1 – L_0})>T_2. The procedure terminates when no additional candidate variables satisfy the inclusion condition given the updated baseline model.

{marker required}{...}

{title:Required Inputs}

{p 3 3 0 0} Users must define the following arguments specifying a binary outcome and a set of candidate covariates.

{p2colset 6 20 20 6}{p2col:{cmd:treat}({it:newvar})}Variable suitable for serving as an outcome in a logit probability model taking values of 0 and 1. This variable will serve as the treatment variable in subsequent estimation.{p_end}

{p2colset 6 20 20 6}{p2col:{cmd:cand}({it:varlist})}A list of variables that are candidates for inclusion in the iterative predictive logit model of the treatment variable. Categorical variables with three or more categories are not permitted. The program accepts two or more candidate covariates. Variable names must be <= 15 characters. Longer variable names may lead to the creation of interaction terms with names that exceed Stata’s 32-character limit for variable names.


{title:Optional Inputs}

{p2colset 6 20 20 6}{p2col:{cmd:base}({it:varlist})}A list of variables for default inclusion in the predictive logit model of outcome. Categorical variables with three or more categories are not permitted. The program accepts one or more baseline covariates. Variable names must be <= 15 characters. Longer variable names may lead to the creation of interaction terms with names that exceed Stata’s 32-character limit for variable names. {p_end}

{p2colset 6 20 20 6}{p2col:{cmd:thr1}({it:real})}Specifies the log-likelihood improvement threshold that must be satisfied for the inclusion of linear terms into the iterative model according to 2*(L_1 – L_0})> thr1 where L_0 is the log-likelihood of current model and L_1 is the log-likelihood of the “best” model from the current candidate set. The default value of {cmd:thr1} is 2.71.{p_end}

{p2colset 6 20 20 6}{p2col:{cmd:thr2}({it:real})}Specifies the log-likelihood improvement threshold that must be satisfied for the inclusion of interaction terms into the iterative model according to 2*(L_1 – L_0})> thr2 where L_0 is the log likelihood of current model and L_1 is the log-likelihood of the “best” model from the current candidate set (as explained above). The default value of {cmd:thr2} is 3.84.{p_end}

{p2colset 6 20 20 6}{p2col:{cmd:rand}({it:int})}Specifies whether to include random normal candidate covariates in the iterative search process. An integer value of 1 or greater generates and includes the specified number of random normal variables as candidate covariates in the search model. This facilitates checking whether selected candidate covariates and interaction terms improve the model more than variables that are known to be randomly generated. {p_end}

{p2colset 6 20 20 6}{p2col: {cmd:keepint}}Specifies whether to retain automatically generated interaction terms in the dataset after program execution. By default the program drops automatically generated interaction terms when the program ends. The keepint option overrides this setting to keep all newly generated interactions in the dataset when the program terminates. This is especially helpful when the user wishes to move directly to the next stage of analysis without stopping to manually code interaction terms selected by the {it:itpscore} program. See the "Remarks" section below for examples of subsequent analyses. {p_end}

{p2colset 6 20 20 6}{p2col:{cmd:viewiter}}Specifies whether the output should print information for each logit model estimated. Activating the option displays the command line call for each logit model, the associated model log likelihood, and the “best” additional covariate from each round of iteration. {p_end}
{p}

{marker remarks}{...}

{title:Remarks}

{p 3 3 0 0} In the search procedure the program may encounter logit models that converge slowly or do not converge. The authors highly recommend use of Stata’s maximum iteration setting to address such instances. Example code below demonstrates use of this setting. Please see {help set_iter:set maxiter}.

{p 3 3 0 0} The authors recommend a default value of 2.71 for thr1 and 3.84 for thr2. These values correspond to t-values of 1.65 and 1.96, respectively. Higher thresholds lead to a fewer selected covariates and shorter program run times.

{p 3 3 0 0} The {it: itpscore} package supports the development of logistic regression models for propensity score and heterogenous treatment effects analysis. The program employs a documented model selection algorithm to identify the set of covariates and interactions that best model a given binary treatment. Upon program completion, the selected model is stored in the global variable {it: covlist}. This {it: covlist} global variable is suitable for use in the {it: varlist} argument of the {help pscore: pscore} package, or in the {it: tvar} argument of the {help teffects: teffects psmatch} program. The itpscore package can also contribute to heterogenous treatment effect analysis with the {help hte: hte} package, which depends upon the {help pscore: pscore} package.

{p 3 3 0 0}When utilizing {it: itpscore} before subsequent analyses, consider activating the {it: keepint} option to ensure that any interaction terms listed in {it: covlist} remain in the data set at program completion.

{p 3 3 0 0} Use Stata's {help set seed:set seed} option to make results using the rand option replicable.

{p}

{title:Syntax Template}

{space 2} *-Program Call
{space 2} itpscore , treat({it:var1}) cand({it: varlist})

{marker example}{...}

{title:Example}

{space 2} sysuse nlsw88
{space 2} tab race, gen(race_)

{space 2} set maxiter 25

{space 2} itpscore , treat(married) cand(hours tenure south age)

{p 3 3 0 0} For examples that include output, see our PDF supplement. To access the supplement, type "search itpscore" and click on the itpscore package link. The PDF supplement is posted fow download under ancillary files.{p_end}


{title:Stored Results}

{space 2} itpscore stores the values and data listed below.

{space 5} {bf:Scalars}

{p2colset 8 23 23 8}{p2col:r(ll)}Log likelihood of the last completed model{p_end}
{p2colset 8 23 23 8}{p2col:r(ll_0)}Log likelihood including baseline covariates only{p_end}
{p2colset 8 23 23 8}{p2col:r(max_ll)}Log likelihood of “best” model{p_end}
{p2colset 8 23 23 8}{p2col:r(n_regs)}Total number of regression models estimated{p_end}
{p2colset 8 23 23 8}{p2col:r(rand_cov)}Random covariate parameter setting{p_end}
{p2colset 8 23 23 8}{p2col:r(thresh1)}Improvement threshold for linear terms{p_end}
{p2colset 8 23 23 8}{p2col:r(thresh2)}Improvement threshold for interactions{p_end}

{space 5} {bf:Strings}

{p2colset 8 23 23 8}{p2col:r(base_covs)}Baseline covariate variables{p_end}
{p2colset 8 23 23 8}{p2col:r(covlist)}Selected model from iterative search procedure{p_end}
{p2colset 8 23 23 8}{p2col:r(treat)}Treatment variable{p_end}


{space 5} {bf:Global Variable}

{p2colset 8 23 23 8}{p2col:covlist}Selected model from iterative search procedure{p_end}

{space 5} {bf:Data}

{p2colset 8 23 23 8}{p2col:_iterative.dta}Shows information for each model estimated including the full model
specification with the candidate covariate, the resulting model log-likelihood, the current
“best” variable, the number of iterations required for logit model convergence,
and a binary indicator of whether models converge. Data set saves to the default working directory, which can
be altered with the "cd" command.{p_end}


{title:References}

{p 8 8 0 0} Imbens, G., & Rubin, D. (2015). Estimating the Propensity Score. In Causal
Inference for Statistics, Social, and Biomedical Sciences: An Introduction
(pp. 281-308). Cambridge: Cambridge University Press.
doi:10.1017/CBO9781139025751.014 {p_end}

{p}

{title:Authors}

{p 8 8 0 0} Ravaris Moore (Princeton University and Loyola Marymount University, Los Angeles, rlmoore@princeton.edu) {p_end}
{p 8 8 0 0} Jennie E. Brand (UCLA, brand@soc.ucla.edu) {p_end}
{p 8 8 0 0} Tanvi Shinkre (UCLA, tanvishinkre@ucla.edu) {p_end}

{p 3 3 0 0}Thanks for citing this software as follows:

{p 8 8 0 0} Moore, Ravaris L., Jennie E. Brand, Tanvi Shinkre. 2021. itpscore: Stata module to perform iterative propensity score logistic regression model search procedure.
  http://ideas.repec.org/c/boc/bocode/s459018.html

{p}

{title:Also see}

{p 8 8 0 0}Online: help for {help logit:logit}; Also see the packages {help pscore:pscore}, {help teffects:teffects psmatch} and {help hte:hte}.

{p}
