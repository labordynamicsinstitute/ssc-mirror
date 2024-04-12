{smcl}
{* 10April2024}{...}
{cmd:help opl_lc_c}
{hline}

{title:Title}

{p2colset 5 16 21 2}{...}
{p2col :{hi:opl_lc_c} {hline 2}}Linear-combination policy learning at specific parameters' values{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{hi:opl_lc_c} ,
{cmd:xlist}{cmd:(}{it:var1 var2}{cmd:)}
{cmd:cate}{cmd:(}{it:varname}{cmd:)}
{cmd:c1}{cmd:(}{it:number}{cmd:)}
{cmd:c2}{cmd:(}{it:number}{cmd:)}
{cmd:c3}{cmd:(}{it:number}{cmd:)}
[
{cmd:depvar}{cmd:(}{it:name}{cmd:)}
{cmd:graph}
]


{dlgtab:Description}

{pstd} {cmd:opl_lc_c} is a command implementing ex-ante treatment assignment using as policy 
class a linear-combination approach at specific parameters' values {it:c1}, {it:c2}, and {it:c3} 
for the linear-combination of variables {it:var1} and {it:var2}: c1*var1+c2*var2=c3.       


{dlgtab: Options}

{synoptset 32 tabbed}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt xlist(var1 var2)}}defines the two variables the policymaker decide to use for selecting policy beneficiaries.{p_end}
{synopt :{opt cate(varname)}}puts into {it:varname} a variable already present in the dataset containing the conditional average treatment effect (CATE). This variable can be generated using the command {helpb make_cate}.{p_end}
{synopt :{opt c1(number)}}puts into {it:number} the value of the parameter value {it:c1} for the first selection variable. This number must be chosen between 0 and 1.
{p_end}
{synopt :{opt c2(number)}}puts into {it:number} the value of the parameter value {it:c2} for the second selection variable. This number must be chosen between 0 and 1.
{p_end}
{synopt :{opt c3(number)}}puts into {it:number} the value of the parameter value {it:c3} of the linear-combination. This number must be chosen between 0 and 1.
{p_end}
{synopt :{opt depvar(name)}}assigns the specified {it:name} to the dependent variable for display in the results table. While this option does not impact computations, it ensures a meaningful label for the dependent variable in the results table.
{p_end}
{synopt :{opt graph}}visualizes treated and untreated within the {it:var1} and {it:var2} quadrant.
{p_end}
{synoptline}


{dlgtab:Returns}

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(c1)}}Parameter of {it:var1} in the linear-combination{p_end}
{synopt:{cmd:e(c2)}}Parameter of {it:var2} in the linear-combination{p_end}
{synopt:{cmd:e(c3)}}Third parameter of the linear-combination{p_end}
{synopt:{cmd:e(W_unconstr)}}Value of the unconstrained welfare at parameters' values {it:c1}, {it:c2}, and {it:c3}{p_end}
{synopt:{cmd:e(W_constr)}}Value of the constrained welfare at parameters' values {it:c1}, {it:c2}, and {it:c3}{p_end}
{synopt:{cmd:e(perc_treat)}}Percentage over the entire sample of the beneficiaries to treat at parameters' values {it:c1}, {it:c2}, and {it:c3}{p_end}

{syntab:Variables}
{synopt:{cmd:_units_to_be_treated}}Flag variable indicating the policy beneficiaries at parameters' values {it:c1}, {it:c2}, and {it:c3}{p_end}
{synoptline}

{dlgtab:Remarks}

{phang} Remark 1. Please, consider to keep updated with future versions of this command.


{dlgtab:Example}

{pstd}{bf:Example}: Linear-combination policy learning at specific parameters' values{p_end}
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
{phang2} Run "opl_lc" to find the optimal linear-combination parameters{p_end}
{phang3} {stata opl_lc  ,  xlist($z) cate($T)}{p_end}
{phang2} Save the optimal linear-combination parameters into three global macros{p_end}
{phang3} {stata global c1_opt=e(best_c1)}{p_end}
{phang3} {stata global c2_opt=e(best_c2)}{p_end}
{phang3} {stata global c3_opt=e(best_c3)}{p_end}
{phang2} Run "opl_lc_c" at optimal linear-combination parameters and generate the graph{p_end}
{phang3} {stata opl_lc_c , xlist($z) cate($T) c1($c1_opt) c2($c2_opt) c3($c3_opt) graph depvar("re78")}{p_end}
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
Online: {helpb make_cate}, {helpb opl_tb}, {helpb opl_lc}, {helpb opl_lc_c}, {helpb opl_dt}, {helpb opl_dt_c}{p_end}
