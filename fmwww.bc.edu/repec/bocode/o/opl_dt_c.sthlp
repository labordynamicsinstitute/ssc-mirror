{smcl}
{* 10April2024}{...}
{cmd:help opl_dt_c}
{hline}

{title:Title}

{p2colset 5 16 21 2}{...}
{p2col :{hi:opl_dt_c} {hline 2}}Decision-tree policy learning at specific splitting variables and threshold values{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{hi:opl_dt_c} ,
{cmd:xlist}{cmd:(}{it:var1 var2}{cmd:)}
{cmd:cate}{cmd:(}{it:varname}{cmd:)}
{cmd:c1}{cmd:(}{it:number}{cmd:)}
{cmd:c2}{cmd:(}{it:number}{cmd:)}
{cmd:c3}{cmd:(}{it:number}{cmd:)}
{cmd:x1}{cmd:(}{it:varname}{cmd:)}
{cmd:x2}{cmd:(}{it:varname}{cmd:)}
{cmd:x3}{cmd:(}{it:varname}{cmd:)}
[
{cmd:depvar}{cmd:(}{it:name}{cmd:)}
{cmd:graph}
]


{dlgtab:Description}

{pstd} {cmd:opl_dt_c} is a command implementing ex-ante treatment assignment using as policy 
class a 2-layer fixed-depth decision-tree at specific splitting variables and threshold values.
   

{dlgtab: Options}

{synoptset 32 tabbed}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt xlist(var1 var2)}}defines the two variables the policymaker decide to use for selecting policy beneficiaries{p_end}
{synopt :{opt cate(varname)}}puts into {it:varname} a variable already present in the dataset containing the conditional average treatment effect (CATE). This variable can be generated using the command {helpb make_cate}{p_end}
{synopt :{opt c1(number)}}puts into {it:number} the value of the threshold value {it:c1} for the first splitting variable. This number must be chosen between 0 and 1{p_end}
{synopt :{opt c2(number)}}puts into {it:number} the value of the threshold value {it:c2} for the second splitting variable. This number must be chosen between 0 and 1{p_end}
{synopt :{opt c3(number)}}puts into {it:number} the value of the threshold value {it:c3} for the third splitting variable. This number must be chosen between 0 and 1{p_end}
{synopt :{opt x1(varname)}}puts into {it:varname} the name of the first splitting variable{p_end}
{synopt :{opt x2(varname)}}puts into {it:varname} the name of the second splitting variable{p_end}
{synopt :{opt x3(varname)}}puts into {it:varname} the name of the third splitting variable{p_end}
{synopt :{opt depvar(name)}}assigns the specified {it:name} to the dependent variable for display in the results table. While this option does not impact computations, it ensures a meaningful label for the dependent variable in the results table.
{p_end}
{synopt :{opt graph}}visualizes treated and untreated within the {it:var1} and {it:var2} quadrant{p_end}
{synoptline}


{dlgtab:Returns}

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(c1)}}threshold level of the first variable used for splitting{p_end}
{synopt:{cmd:e(c2)}}threshold level of the second variable used for splitting{p_end}
{synopt:{cmd:e(c3)}}threshold level of the third variable used for splitting{p_end}
{synopt:{cmd:e(W_unconstr)}}value of the unconstrained welfare at threshold values {it:c1} for the first splitting variable, {it:c2} for the second splitting variable, and {it:c3} for the third splitting variable{p_end}
{synopt:{cmd:e(W_constr)}}value of the constrained welfare at threshold values {it:c1} for the first splitting variable, {it:c2} for the second splitting variable, and {it:c3} for the third splitting variable{p_end}
{synopt:{cmd:e(perc_treat)}}percentage of beneficiaries to treat{p_end}

{syntab:Macros}
{synopt:{cmd:e(x1)}}first splitting variable{p_end}
{synopt:{cmd:e(x2)}}second splitting variable{p_end}
{synopt:{cmd:e(x3)}}third splitting variable{p_end}

{syntab:Variables}
{synopt:{cmd:_units_to_be_treated}}flag variable indicating the policy beneficiaries at parameters' values {it:c1}, {it:c2}, and {it:c3}{p_end}
{synoptline}

{dlgtab:Remarks}

{phang} Remark 1. Please, consider to keep updated with future versions of this command.


{dlgtab:Example}

{pstd}{bf:Example}: Decision-tree policy learning at specific splitting variables and threshold values{p_end}
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
{phang2} Generate a global macro containing the name of the variable "cate_new"{p_end}
{phang3} {stata global T `e(cate_new)'}{p_end}
{phang2} Select only the "new data"{p_end}
{phang3} {stata keep if _train_new_index=="new"}{p_end}
{phang2} Drop "my_cate_train" as in the new dataset treatment assignment and outcome performance are unknown{p_end}
{phang3} {stata drop my_cate_train $w $y}{p_end}
{phang2} Run "opl_dt" to find the optimal linear-combination parameters{p_end}
{phang3} {stata opl_dt  ,  xlist($z) cate($T)}{p_end}
{phang2} Save the optimal splitting variables into three global macros{p_end}
{phang3} {stata global x1_opt `e(best_x1)'}{p_end}
{phang3} {stata global x2_opt `e(best_x2)'}{p_end}
{phang3} {stata global x3_opt `e(best_x3)'}{p_end}
{phang2} Save the optimal splitting thresholds into three global macros{p_end}
{phang3} {stata global c1_opt=e(best_c1)}{p_end}
{phang3} {stata global c2_opt=e(best_c2)}{p_end}
{phang3} {stata global c3_opt=e(best_c3)}{p_end}
{phang2} Run "opl_dt_c" at optimal splitting variables and corresponding thresholds and generate the graph{p_end}
{phang3} {stata opl_dt_c , xlist($z) cate($T) c1($c1_opt) c2($c2_opt) c3($c3_opt) x1($x1_opt) x2($x2_opt) x3($x3_opt) graph depvar("re78")}{p_end}
{phang2} Tabulate the variable "_units_to_be_treated"{p_end}
{phang3} {stata tab _units_to_be_treated , mis}{p_end}


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
Online: {helpb make_cate}, {helpb opl_tb}, {helpb opl_dt}, {helpb opl_dt_c}, {helpb opl_dt}, {helpb opl_dt_c}{p_end}
