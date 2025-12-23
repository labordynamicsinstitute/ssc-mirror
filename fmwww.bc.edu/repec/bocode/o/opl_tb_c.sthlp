{smcl}
{* 11dec2025}{...}
{cmd:help opl_tb_c}
{hline}

{title:Title}

{p2colset 5 16 21 2}{...}
{p2col :{hi:opl_tb_c} {hline 2}}Threshold-based policy learning at specific threshold values{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{hi:opl_tb_c} ,
{cmd:xlist}{cmd:(}{it:var1 var2}{cmd:)}
{cmd:cate}{cmd:(}{it:varname}{cmd:)}
{cmd:c1}{cmd:(}{it:number}{cmd:)}
{cmd:c2}{cmd:(}{it:number}{cmd:)}
{cmd:pom0}{cmd:(}{it:number}{cmd:)}
[
{cmd:custom_policy}{cmd:(}{it:varname}{cmd:)}
{cmd:depvar}{cmd:(}{it:name}{cmd:)}
{cmd:graph}
{cmd:save_gr_op}{cmd:(}{it:graphname}{cmd:)}
{cmd:save_gr_cp}{cmd:(}{it:graphname}{cmd:)}
]


{dlgtab:Description}

{pstd} {cmd:opl_tb_c} is a command implementing ex-ante treatment assignment using as policy 
class a threshold-based (or quadrant) approach at specific threshold values {it:c1} and {it:c2} for respectively the selection variables {it:var1} and {it:var2}.      


{dlgtab: Options}

{synoptset 32 tabbed}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt xlist(var1 var2)}}defines the two variables the policymaker decide to use for selecting policy beneficiaries.{p_end}
{synopt :{opt cate(varname)}}puts into {it:varname} a variable already present in the dataset containing the conditional average treatment effect (CATE). This variable can be generated using the command {helpb make_cate}.{p_end}
{synopt :{opt c1(number)}}puts into {it:number} the value of the threshold value {it:c1} for the first selection variable. This number must be chosen between 0 and 1.
{p_end}
{synopt :{opt c2(number)}}puts into {it:number} the value of the threshold value {it:c2} for the second selection variable. This number must be chosen between 0 and 1.
{p_end}
{synopt :{opt pom0(number)}}stores in {it:number} the potential outcome mean for untreated units. This value is returned as a scalar by the {helpb make_cate} command.
{p_end}
{synopt :{opt custom_policy(varname)}}specifies a user-defined policy to be evaluated in terms of its impact and welfare. This policy variable must be provided as a binary 0/1 variable. 
{p_end}
{synopt :{opt depvar(name)}}assigns the specified {it:name} to the dependent variable for display in the results table. While this option does not impact computations, it ensures a meaningful label for the dependent variable in the results table.
{p_end}
{synopt :{opt graph}}visualizes selected treated and untreated within the {it:var1} and {it:var2} quadrant.
{p_end}
{synopt :{opt save_gr_op()}}save in the current directory the graph that visualizes selected treated and untreated within the {it:var1} and {it:var2} quadrant for the optimal policy.
{p_end}
{synopt :{opt save_gr_cp()}}save in the current directory the graph that visualizes selected treated and untreated within the {it:var1} and {it:var2} quadrant for the customized policy.
{synoptline}


{dlgtab:Returns}

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(c1)}}Chosen threshold for {it:var1}{p_end}
{synopt:{cmd:e(c2)}}Chosen threshold for {it:var2}{p_end}
{synopt:{cmd:e(I_uop)}}Impact (i.e., ATET) under the unconstrained optimal policy{p_end}
{synopt:{cmd:e(Ntreat_uop)}}Number of units assigned to treatment under the unconstrained optimal policy{p_end}
{synopt:{cmd:e(Nuntreat_uop)}}Number of units assigned to no treatment under the unconstrained optimal policy{p_end}
{synopt:{cmd:e(N_uop)}}Total number of units evaluated under the unconstrained optimal policy{p_end}
{synopt:{cmd:e(perc_treat_uop)}}Percentage of treated units under the unconstrained optimal policy{p_end}
{synopt:{cmd:e(I_cop)}}Impact (i.e., ATET) under the constrained optimal policy, at thresholds {it:c1} and {it:c2}{p_end}
{synopt:{cmd:e(N_cop)}}Total number of units evaluated under the constrained optimal policy{p_end}
{synopt:{cmd:e(perc_treat_cop)}}Percentage of treated units under the constrained optimal policy{p_end}
{synopt:{cmd:e(Ntreat_cop)}}Number of units assigned to treatment under the constrained optimal policy{p_end}
{synopt:{cmd:e(Nuntreat_cop)}}Number of units assigned to no treatment under the constrained optimal policy{p_end}
{synopt:{cmd:e(TTET_uop)}}Total treatment effect on treated units under the unconstrained optimal policy{p_end}
{synopt:{cmd:e(AW_uop)}}Average welfare under the unconstrained optimal policy; as computed by the command’s welfare function{p_end}
{synopt:{cmd:e(TW_uop)}}Total welfare under the unconstrained optimal policy; as computed by the command’s welfare function{p_end}
{synopt:{cmd:e(TTET_cop)}}Total treatment effect on treated units under the constrained optimal policy{p_end}
{synopt:{cmd:e(AW_cop)}}Average welfare under the constrained optimal policy; as computed by the command’s welfare function{p_end}
{synopt:{cmd:e(TW_cop)}}Total welfare under the constrained optimal policy; as computed by the command’s welfare function{p_end}
{synopt:{cmd:e(I_ucp)}}Impact (i.e., ATET) under the unconstrained customized policy provided via {opt custom_policy()}{p_end}
{synopt:{cmd:e(_N)}}Total sample size used in the evaluation{p_end}
{synopt:{cmd:e(TW_ccp)}}Total welfare under the constrained customized policy; as computed by the command’s welfare function{p_end}
{synopt:{cmd:e(AW_ccp)}}Average welfare under the constrained customized policy; as computed by the command’s welfare function{p_end}
{synopt:{cmd:e(TTET_ccp)}}Total treatment effect on treated units under the constrained customized policy{p_end}
{synopt:{cmd:e(TW_ucp)}}Total welfare under the unconstrained customized policy; as computed by the command’s welfare function{p_end}
{synopt:{cmd:e(AW_ucp)}}Average welfare under the unconstrained customized policy; as computed by the command’s welfare function{p_end}
{synopt:{cmd:e(TTET_ucp)}}Total treatment effect on treated units under the unconstrained customized policy{p_end}
{synopt:{cmd:e(Nuntreat_ccp)}}Number of units assigned to no treatment under the constrained customized policy{p_end}
{synopt:{cmd:e(Ntreat_ccp)}}Number of units assigned to treatment under the constrained customized policy{p_end}
{synopt:{cmd:e(perc_treat_ccp)}}Percentage of treated units under the constrained customized policy{p_end}
{synopt:{cmd:e(N_ccp)}}Total number of units evaluated under the constrained customized policy{p_end}
{synopt:{cmd:e(I_ccp)}}Impact (i.e., ATET) under the constrained customized policy{p_end}
{synopt:{cmd:e(perc_treat_ucp)}}Percentage of treated units under the unconstrained customized policy{p_end}
{synopt:{cmd:e(N_ucp)}}Total number of units evaluated under the unconstrained customized policy{p_end}
{synopt:{cmd:e(Nuntreat_ucp)}}Number of units assigned to no treatment under the unconstrained customized policy{p_end}
{synopt:{cmd:e(Ntreat_ucp)}}Number of units assigned to treatment under the unconstrained customized policy{p_end}

{syntab:Variables}
{synopt:{cmd:_units_to_be_treated_uop}}Flag variable indicating the policy beneficiaries at the unconstrained optimal policy{p_end}
{synopt:{cmd:_units_to_be_treated_cop}}Flag variable indicating the policy beneficiaries at threshold values {it:c1} and {it:c2} (i.e., constrained optimal policy){p_end}

{syntab:Macros}
{synopt:{cmd:e(dep_var)}}Name of the dependent variable used in the analysis (as specified in the {opt depvar()} option){p_end}
{synopt:{cmd:e(sel_vars)}}List of selection variables ({it:var1 var2}) used to define the policy thresholds{p_end}
{synoptline}


{dlgtab:Remarks}

{phang} Remark 1. Please, consider to keep updated with future versions of this command.


{dlgtab:Example}

{pstd}{bf:Example}: Threshold-based policy learning at specific threshold values{p_end}

{phang2} Load initial dataset{p_end}
{phang3} {stata sysuse JTRAIN2, clear}{p_end}

{phang2} Split the original data into a "old" (training) and "new" (testing) dataset{p_end}
{phang3} {stata get_train_test, dataname(jtrain) split(0.60 0.40) split_var(svar) rseed(101)}{p_end}

{phang2} Use the "old" dataset (i.e. policy) for training{p_end}
{phang3} {stata use jtrain_train , clear}{p_end}

{phang2} Set the outcome{p_end}
{phang3} {stata global y "re78"}{p_end}

{phang2} Set the features{p_end}
{phang3} {stata global x "re74 re75 age agesq nodegree"}{p_end}

{phang2} Set the treatment variable{p_end}
{phang3} {stata global w "train"}{p_end}

{phang2} Set the selection variables{p_end}
{phang3} {stata global z "age mostrn"}{p_end}

{phang2} Run "make_cate" and generate training (old policy) and testing (new policy) CATE predictions{p_end}
{phang3} {stata make_cate $y $x , treatment($w) type("ra") model("linear") new_cate("my_cate_new") train_cate("my_cate_train") new_data("jtrain_test")}{p_end}

{phang2} Generate a global macro containing the name of the variable "cate_new"{p_end}
{phang3} {stata global T `e(cate_new)'}{p_end}

{phang2} Select only the "new data"{p_end}
{phang3} {stata keep if _train_new_index=="new"}{p_end}

{phang2} Drop "my_cate_train" as in the new dataset treatment assignment and outcome performance are unknown{p_end}
{phang3} {stata drop my_cate_train $w $y}{p_end}

{phang2} Save into a global macro the mean potential outcome model for untreated{p_end}
{phang3} {stata global Em0 = e(Em0_new)}{p_end}

{phang2} Run "opl_tb" to find the optimal thresholds{p_end}
{phang3} {stata opl_tb , xlist($z) cate($T) pom0($Em0)}{p_end}

{phang2} Save the optimal threshold values into two global macros{p_end}
{phang3} {stata global c1_opt=e(best_c1)}{p_end}
{phang3} {stata global c2_opt=e(best_c2)}{p_end}

{phang2} Generate randomly a customized policy{p_end}
{phang3} {stata set seed 1010}{p_end}
{phang3} {stata gen x = runiform()}{p_end}
{phang3} {stata gen cp = (x > 0.5)}{p_end}

{phang2} Run "opl_tb_c" at optimal policy thresholds, generate results for the customized policy, and include graphs{p_end}
{phang3} {stata opl_tb_c , xlist($z) cate($T) c1($c1_opt) c2($c2_opt) graph depvar("re78") pom0($Em0) custom_policy(cp)}{p_end}

{phang2} Tabulate the variable "_units_to_be_treated_uop" and "_units_to_be_treated_cop"{p_end}
{phang3} {stata tab _units_to_be_treated_uop , mis}{p_end}
{phang3} {stata tab _units_to_be_treated_cop , mis}{p_end}


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
The development of this software was supported by FOSSR (Fostering Open Science in Social Science Research), a project funded by the European Union - NextGenerationEU under the NPRR Grant agreement n. MURIR0000008.

{dlgtab:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@ircres.cnr.it":giovanni.cerulli@ircres.cnr.it}{p_end}


{dlgtab:Also see}

{psee}
Online: {helpb make_cate}, {helpb opl_tb}, {helpb opl_tb_c}, {helpb opl_lc}, {helpb opl_lc_c}, {helpb opl_dt}, {helpb opl_dt_c}, {helpb opl_budget}
{p_end}
