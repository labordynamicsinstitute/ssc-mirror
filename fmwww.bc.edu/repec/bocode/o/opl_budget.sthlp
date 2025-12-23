{smcl}
{* 21dec2025}{...}
{cmd:help opl_budget}
{hline}

{title:Title}

{p2colset 5 16 21 2}{...}
{p2col :opl_budget {hline 1}} Optimal policy learning under budget constraint and minimum number of treated units
{p2colreset}{...}

{title:Syntax}

{p 8 8}{cmd:opl_budget} {it:tauvar costvar} ,
    {cmd:budget(}{it:#}{cmd:)}
    {cmd:nmin(}{it:#}{cmd:)}
    {cmd:em0(}{it:#}{cmd:)}
    [{cmd:policy(}{it:name}{cmd:)} {cmd:replace} {cmd:custom_pol(}{it:varname}{cmd:)}]

{pstd}
where:

{pstd}
{it:tauvar}: estimated individual treatment effects (CATE or τ̂_i)

{pstd}
{it:costvar}: individual treatment costs

{dlgtab:Description}

{pstd}
{cmd:opl_budget} assigns binary treatment optimally under two constraints:
(1) a total budget limit, and (2) a minimum number of individuals to treat.
Individuals are ranked by cost-effectiveness (τ̂_i / cost_i). The optimizer
selects the cutoff {it:k*} that maximizes cumulative welfare while satisfying
both constraints.

{pstd}
The option {cmd:em0(#)} supplies the baseline outcome/welfare E[m0(X)],
so that the command can report both incremental welfare
(sum of τ̂_i over treated units) and total welfare
(E[m0(X)] + sum τ̂_i).

{pstd}
In addition to estimating the optimal policy, the command can also
evaluate a user-defined policy via the option
{cmd:custom_pol(varname)}, which must be a 0/1 variable.
For this customized policy, the command computes welfare, treatment
coverage, and total cost, and returns them in {cmd:r()}.

{pstd}
Estimated individual treatment effects (CATEs) may be obtained, for example, using
the {helpb make_cate} command.


{dlgtab:Options}

{p 4 8}{cmd:budget(}{it:#}{cmd:)} total available budget (positive)

{p 4 8}{cmd:nmin(}{it:#}{cmd:)} minimum number of treated individuals

{p 4 8}{cmd:em0(}{it:#}{cmd:)} baseline welfare E[m0(X)] for computing total welfare

{p 4 8}{cmd:policy(}{it:name}{cmd:)} name of the generated optimal policy variable
(default: {cmd:opl_policy})

{p 4 8}{cmd:replace} overwrite the policy variable if it exists

{p 4 8}{cmd:custom_pol(}{it:varname}{cmd:)} evaluate a user-defined 0/1 treatment policy;
returns welfare, cost, and coverage for the supplied policy


{dlgtab:Returned values}

{pstd}
The command is {cmd:rclass} and returns:

{p 8 12}{cmd:r(budget)} total budget

{p 8 12}{cmd:r(kstar)} optimal cutoff {it:k*}

{p 8 12}{cmd:r(welfare_incr)} incremental welfare (sum of τ̂_i over optimally treated)

{p 8 12}{cmd:r(welfare_tot)} total welfare = em0 + sum(τ̂_i)

{p 8 12}{cmd:r(cost)} total treatment cost under the optimal policy

{p 8 12}{cmd:r(Ntreated)} number of units treated under the optimal policy

{p 8 12}{cmd:r(Ptreated)} percentage treated under the optimal policy

{pstd}
If {cmd:custom_pol()} is specified, the following are additionally returned:

{p 8 12}{cmd:r(cust_welfare_incr)} incremental welfare under the custom policy

{p 8 12}{cmd:r(cust_welfare_tot)} total welfare under the custom policy (em0 + incremental)

{p 8 12}{cmd:r(cust_cost)} treatment cost under the custom policy

{p 8 12}{cmd:r(cust_Ntreated)} number treated under the custom policy

{p 8 12}{cmd:r(cust_Ptreated)} percentage treated under the custom policy


{dlgtab:Remarks}

{pstd}
The estimator uses a greedy, cost-effectiveness–based optimization procedure.
It guarantees feasibility with respect to both budget and minimum–treated constraints.
Comparison with alternative user-defined policies is possible via {cmd:custom_pol()}.


{dlgtab:Example}

{pstd}Example: Budget-constrained optimal policy learning with a custom policy evaluation{p_end}

{phang2} Clear the Stata environment{p_end}
{phang3} {stata clear all}{p_end}

{phang2} Load initial dataset{p_end}
{phang3} {stata sysuse JTRAIN2}{p_end}

{phang2} Split the original data into a "training" (old) and "testing" (new) dataset{p_end}
{phang3} {stata get_train_test, dataname(jtrain) split(0.60 0.40) split_var(svar) rseed(123)}{p_end}

{phang2} Use the training dataset{p_end}
{phang3} {stata use jtrain_train , clear}{p_end}

{phang2} Define outcome, features, treatment, and selection variables{p_end}
{phang3} {stata replace re78 = re78 * 1000}{p_end}
{phang3} {stata global y "re78"}{p_end}
{phang3} {stata global x "re74 re75 age agesq nodegree"}{p_end}
{phang3} {stata global w "train"}{p_end}

{phang2} Estimate CATEs on training and testing samples using {helpb make_cate}{p_end}
{phang3} {stata make_cate $y $x , treatment($w) type("ra") model("linear") new_cate("my_cate_new") train_cate("my_cate_train") new_data("jtrain_test")}{p_end}

{phang2} Store E[m0(X)] from the training sample and clean unnecessary variables{p_end}
{phang3} {stata global Em0_train = e(Em0_train)}{p_end}
{phang3} {stata drop my_cate_new}{p_end}
{phang3} {stata keep if my_cate_train != .}{p_end}

{phang2} Define individual treatment costs{p_end}
{phang3} {stata generate cost = 1000 + 50 * age}{p_end}

{phang2} Use as custom policy the training policy{p_end}
{phang3} {stata gen mypolicy = train}{p_end}

{phang2} Set total budget and minimum number of treated units{p_end}
{phang3} {stata global B = 80000}{p_end}
{phang3} {stata global N_min = 20}{p_end}

{phang2} Run {cmd:opl_budget} to compute the optimal policy and evaluate the custom policy{p_end}
{phang3} {stata opl_budget my_cate_train cost, budget($B) nmin($N_min) em0($Em0_train) policy(pol_opt) custom_pol(mypolicy) replace}{p_end}

{phang2} Inspect returned results{p_end}
{phang3} {stata return list}{p_end}


{dlgtab:Acknowledgment}

{pstd}
The development of this software was supported by FOSSR (Fostering Open Science
in Social Science Research), a project funded by the European Union - NextGenerationEU
under the NPRR Grant agreement n. MURIR0000008.


{dlgtab:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@ircres.cnr.it"}{p_end}


{dlgtab:Also see}

{psee}
Online: {helpb make_cate}, {helpb opl_tb}, {helpb opl_tb_c},
{helpb opl_lc}, {helpb opl_lc_c}, {helpb opl_dt}, {helpb opl_dt_c}, {helpb opl_overlap}
{p_end}
