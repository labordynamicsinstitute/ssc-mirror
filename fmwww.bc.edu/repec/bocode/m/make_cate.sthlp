{smcl}
{* 10April2024}{...}
{cmd:help make_cate}
{hline}

{title:Title}

{p2colset 5 16 21 2}{...}
{p2col :{hi:make_cate} {hline 2}}Predicting conditional average treatment effect (CATE) on a new policy based on the training over an old policy{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{hi:make_cate}
{it:outcome}
{it:features} ,
{cmd:treatment}{cmd:(}{it:varname}{cmd:)}
{cmd:model}{cmd:(}{it:model_type}{cmd:)}
{cmd:new_cate}{cmd:(}{it:name}{cmd:)}
{cmd:train_cate}{cmd:(}{it:name}{cmd:)}
{cmd:new_data}{cmd:(}{it:name}{cmd:)}

{dlgtab:Inputs}

{phang} {it:outcome}: numerical variable    

{phang} {it:features}: list of numerical variables representing the features.   


{dlgtab:Description}

{pstd} {cmd:make_cate} is a command generating conditional average treatment effect (CATE) for both a training dataset and a testing (or new) dataset related to a binary (treated vs. untreated) policy program. It provides the main input for running {helpb opl_tb} (optimal policy learning of a threshold-based policy), {helpb opl_tb_c} (optimal policy learning of a threshold-based policy at specific thresholds), {helpb opl_lc} (optimal policy learning of a 
linear-combination policy), {helpb opl_lc_c} (optimal policy learning of a linear-combination policy at specific parameters), {helpb opl_dt} (optimal policy learning of a decision-tree policy), {helpb opl_dt_c} (optimal policy learning of a decision-tree policy at specific thresholds and selection variables). Based on Kitagawa and Tetenov (2018), the main econometrics supported by these commands can be found in Cerulli (2022).          


{dlgtab: Options}

{synoptset 32 tabbed}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt treatment(varname)}}defines the treatment variable adopted in the old (ex-post) policy run. It must be a 0/1 dummy (1=treated; 0=untreated).{p_end}
{synopt :{opt model(model_type)}}indicates the treatment model used for estimating and predicting the conditional average treatment effect (CATE). 
The implemented estimation methods are linear and non-linear regression adjustment. As {it:model_type}, use the following options: "linear", if the outcome variable is gaussian (numerical and continuous); 
"logit", if the outcome variable is binary (0/1); "poisson", if the outcome variable is countable; "flogit", if the outcome variable is fractional.{p_end}
{synopt :{opt new_data(name)}}indicates by {it:name} the dataset stored in the home directory containing the data of the new policy run (i.e., the features of the would-be beneficiaries).{p_end} 
{synopt :{opt new_cate(name)}}indicates by {it:name} the variable that will be generated containing the prediction over {cmd:new_data} of the conditional average treatment effect (CATE).{p_end}
{synopt :{opt train_cate(name)}}indicates by {it:name} the variable that will be generated containing the prediction over the training dataset of the conditional average treatment effect (CATE).{p_end}
{synoptline}


{dlgtab:Returns}

{synoptset 24 tabbed}{...}
{syntab:Macros}
{synopt:{cmd:e(cate_new)}}Name of the CATE in the new policy data{p_end}
{synopt:{cmd:e(cate_train)}}Name of the CATE in the old (training) policy data{p_end}

{syntab:Variables}
{synopt:{cmd:_train_new_index}}Flag variable indicating the training (i.e., old-policy) and the new-policy observations{p_end}
{synopt:{cmd:cate_train}}Variable containing training (i.e., old-policy) predictions for CATE{p_end}
{synopt:{cmd:cate_new}}Variable containing new (i.e., new-policy) predictions for CATE{p_end}
{synoptline}


{dlgtab:Remarks}

{phang} Remark 1. Please, consider to keep updated with future versions of this command.


{dlgtab:Example}

{pstd}{bf:Example}: Predicting CATE for a binary policy{p_end}
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
{phang3} {stata make_cate $y $x , treatment($w) model("linear") new_cate("my_cate_new") train_cate("my_cate_train") new_data("jtrain_test")}{p_end}


{dlgtab:References}

{pstd} 
Athey, S., and Wager S. 2021. Policy Learning with Observational Data, {it:Econometrica}, 89, 1, 133–161.

{pstd} 
Cerulli, G. 2021. Improving econometric prediction by machine learning, {it:Applied Economics Letters}, 28, 16, 1419-1425.

{pstd} 
Cerulli, G. 2022. Optimal treatment assignment of a threshold-based policy: empirical protocol and related issues, {it:Applied Economics Letters}, 30, 8, 1010-1017.

{pstd} 
Cerulli, G. 2023. {it:Fundamentals of Supervised Machine Learning: With Applications in Python, R, and Stata}, Springer. 

{pstd} 
Cerulli, G. 2024. Optimal Policy Learning using Stata. Zenodo. DOI: https://doi.org/10.5281/zenodo.10822240.

{pstd} 
Gareth, J., Witten, D., Hastie, D.T., Tibshirani, R. 2013. {it:An Introduction to Statistical Learning: with Applications in R}. New York, Springer.  

{pstd} Kitagawa, T., and A. Tetenov. 2018. Who Should Be Treated? Empirical Welfare Maximization Methods for Treatment Choice, {it:Econometrica}, 86, 2, 591–616.
{p_end}



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
Online: {helpb opl_tb}, {helpb opl_tb_c}, {helpb opl_lc}, {helpb opl_lc_c}, {helpb opl_dt}, {helpb opl_dt_c}
{p_end}
