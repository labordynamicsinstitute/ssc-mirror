{smcl}
{* *! Version 6, G. Cerulli, September 30, 2025}{...}

{title:Title}

{phang}{bf:opl_ma_fb} {hline 2} Optimal Policy Learning for Multi-Action Treatment using First-Best Policy and Risk Preference

{title:Syntax}

{p 8 8 2}
{cmd:opl_ma_fb} {it:depvar indepvars} {cmd:,} 
{cmd:policy_train(}{it:varname}{cmd:)}
{cmd:model(}{it:string}{cmd:)}
{cmd:name_opt_policy(}{it:name}{cmd:)}
[{cmd:match_name(}{it:name}{cmd:)}
{cmd:new_data(}{it:name}{cmd:)}
{cmd:policy_non_optimal_train(}{it:varname}{cmd:)}
{cmd:policy_non_optimal_new(}{it:varname}{cmd:)}
{cmd:save_preds_vars(}{it:name}{cmd:)}
{cmd:gr_action_train(}{it:name}{cmd:)}
{cmd:gr_reward_train(}{it:name}{cmd:)}
{cmd:gr_reward_new(}{it:name}{cmd:)}]


{title:Description}

{pstd}
{cmd:opl_ma_fb} implements first-best Optimal Policy Learning (OPL) algorithm to 
estimate the best treatment assignment given an outcome and a set of observed covariates 
and treatment effects. It allows for different risk preferences in decision-making 
(i.e., risk-neutral, risk-averse linear, risk-averse quadratic). This command uses linear regression for estimating nuisance conditional means.

{title:Options}

{dlgtab:Required}

{phang}
{opt policy_train(varname)} specifies the treatment variable, which must contain consecutive integers starting from 0 (e.g., 0,1,2,...,M).

{phang}
{opt model(string)} specifies the decision model:

{pmore}
{it:risk_neutral}: considers only expected reward (no variance or risk are accounted for).

{pmore}
{it:risk_averse_linear}: adjusts reward by a linear function of its variance.

{pmore}
{it:risk_averse_quadratic}: adjusts reward by a quadratic function of its variance.

{phang}
{opt name_opt_policy(name)} specifies the name of the generated variable containing the estimated optimal policy.


{dlgtab:Optional}

{phang}
{opt match_name(name)} specifies the name of the variable that stores whether the actual treatment matches the optimal one.

{phang}
{opt new_data(name)} provides a second dataset to predict optimal actions for new units. This dataset contains the same features as the training dataset.

{phang}
{opt policy_non_optimal_train(varname)} is an alternative (non-optimal) policy to compare against either training or optimal policy within training data.

{phang}
{opt policy_non_optimal_new(varname)} is an alternative (non-optimal) policy to compare against optimal policy within new data.
    
{phang}  
{opt save_preds_vars(name)} saves conditional expectations and variances.

{phang}
{opt gr_action_train(name)} saves a graph comparing actual vs. optimal action allocation in the training dataset.

{phang}
{opt gr_reward_train(name)} saves a graph comparing actual vs. maximal expected reward in the training dataset.

{phang}
{opt gr_reward_new(name)} saves a graph showing maximal expected reward for new policy observations.


{dlgtab:Returns}

{synoptset 24 tabbed}{...}
{syntab:Scalars}

{synopt:{cmd:e(N_train)}}Number of observations in the training dataset{p_end}

{synopt:{cmd:e(N_new)}}Number of observations in the new (unlabeled) dataset{p_end}

{synopt:{cmd:e(N_train_opt_pol)}}Number of observations for computing the optimal policy in the training dataset{p_end}

{synopt:{cmd:e(V_train)}}Value function in the training dataset{p_end}

{synopt:{cmd:e(N_V_train)}}Number of observations for computing the value function in the training dataset{p_end}

{synopt:{cmd:e(V_non_opt_train)}}Value function in the training dataset for the non-optimal policy{p_end}

{synopt:{cmd:e(N_V_non_opt_train)}}Number of observations for computing the value function in the non-optimal training dataset{p_end}

{synopt:{cmd:e(V_opt_train)}}Value function with optimal policy in the training dataset{p_end}

{synopt:{cmd:e(N_V_opt_train)}}Number of observations for computing with optimal policy the value function in the training dataset{p_end}

{synopt:{cmd:e(V_opt_new)}}Value function in the new dataset for the optimal policy{p_end}

{synopt:{cmd:e(N_V_opt_new)}} Number of observations for computing the value function in the new dataset for the optimal policy{p_end}

{synopt:{cmd:e(rate_opt_match)}}Rate of matches between the optimal and the current training policy{p_end}


{dlgtab:Generated variables}

{phang}
{opt _index}: indicator variable specifying the dataset source of each observation (0 = training data; 1 = new data).

{phang}
{opt _opt_policy}: the estimated optimal policy rule, assigning to each unit the treatment that maximizes expected welfare.

{phang}
{opt _Y_hat_policy_train}: the predicted outcome under the actual (observed) training policy, i.e. the historical assignment rule applied in the data.

{phang}
{opt _Y_hat_policy_train_non_optimal}: the predicted outcome under a given non-optimal policy provided in the training set, used as a benchmark for comparison.

{phang}
{opt Y_hat_policy_optimal}: the predicted outcome under the estimated optimal policy, i.e. the counterfactual outcome distribution if all units had followed the  rst-best policy.

{phang}
{opt _match_var}: an indicator variable equal to 1 if the actual treatment coincides with the estimated optimal treatment, and 0 otherwise. It measures the rate of alignment between historical and optimal assignments.


{dlgtab:Examples}

{pstd}{bf:Example}: Basic usage with a risk-neutral model{p_end}
{phang2} Generate the initial dataset by simulation:{p_end}
{phang3} {stata clear all}{p_end}
{phang3} {stata set obs 100}{p_end}
{phang3} {stata set seed 1010}{p_end}
{phang3} {stata generate A = floor(runiform()*3)}{p_end}
{phang3} {stata gen x1 = rnormal()}{p_end}
{phang3} {stata gen x2 = rnormal()}{p_end}
{phang3} {stata gen y = 100*runiform()}{p_end}
{phang2} Split the dataset into training and testing (i.e., new data):{p_end}
{phang3} {stata get_train_test , dataname(mydata) split(0.60 0.40) split_var(svar) rseed(101)}{p_end}
{phang2} Run opl_ma_fb with risk-neutral preferences{p_end}
{phang3} {stata opl_ma_fb y x1 x2 , policy_train(A) model(risk_neutral) name_opt_policy(opt_policy) new_data(mydata_test) match_name(match_var) gr_action_train(action_graph) gr_reward_train(reward_graph)}{p_end}


{dlgtab:References}

{phang}
Athey, S., and Wager S. 2021. Policy Learning with Observational Data, {it:Econometrica}, 89, 1, 133–161.

{phang}
Cerulli, G. 2021. Improving econometric prediction by machine learning, {it:Applied Economics Letters}, 28, 16, 1419-1425.

{phang}
Cerulli, G. 2022. Optimal treatment assignment of a threshold-based policy: empirical protocol and related issues, {it:Applied Economics Letters}, 30, 8, 1010-1017. 

{phang}
Cerulli, G. 2023. {it:Fundamentals of Supervised Machine Learning: With Applications in Python, R, and Stata}, Springer, 2023. 

{phang}
Cerulli, G. 2024. Optimal policy learning with observational data in multi-action scenarios: Estimation, risk preference, and potential failures. {it:arXiv preprint}, arXiv:2403.20250. https://arxiv.org/abs/2403.20250.

{phang}
Cerulli, G. 2025. Optimal policy learning using Stata. {it:The Stata Journal}, 25, 2, 309-343.

{phang}
Gareth, J., Witten, D., Hastie, D.T., Tibshirani, R. 2013. {it:An Introduction to Statistical Learning : with Applications in R}. New York, Springer.

{phang}
Kennedy, E. H. 2023. Towards optimal doubly robust estimation of heterogeneous causal effects. {it:Electronic Journal of Statistics}, 17, 2, 3008-3049.

{phang}
Kitagawa, T., and A. Tetenov. 2018. Who Should Be Treated? Empirical Welfare Maximization Methods for Treatment Choice, {it:Econometrica}, 86, 2, 591–616.

{phang}
Kunzel, S. R., Sekhon, J. S., Bickel, P. J., Yu, B. (2019). Metalearners for estimating heterogeneous treatment effects using machine learning. 
{it:Proceedings of the National Academy of Sciences of the United States of America}, 116, 10, 4156-4165.

{dlgtab:Acknowledgment}

{pstd} 
The development of this software was supported by: FOSSR (Fostering Open Science in Social Science Research), a project funded by the European Union - NextGenerationEU under the NPRR Grant agreement n. MURIR0000008; PRIN Project RECIPE (Linking Research Evidence to Policy Impact and Learning: Increasing the Effectiveness of Rural Development Programmes Towards Green Deal Goals), MUR code: 20224ZHNXE.


{dlgtab:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@cnr.it":giovanni.cerulli@cnr.it}{p_end}


{dlgtab:Also see}

{psee}
Online: {helpb make_cate}, {helpb opl_tb}, {helpb opl_lc}, {helpb opl_lc_c}, {helpb opl_dt}, {helpb opl_dt_c}{p_end}

