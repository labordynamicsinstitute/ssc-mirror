{smcl}
{* *! opl_ma_vf, v5, GCerulli, 24nov2025}
{title:Title}

{phang}
{cmd:opl_ma_vf} {hline 2} Value-function estimation for multi-action Optimal Policy Learning  
using Regression Adjustment (RA), Inverse Probability Weighting (IPW), and Doubly Robust (DR) methods. This command uses linear regression for estimating nuisance conditional means.

{marker syntax}{title:Syntax}

{p 8 17 2}
{cmd:opl_ma_vf} {it:depvar indepvars} {cmd:} , {cmd:policy_train(}{it:varname}{cmd:)} {cmd:policy_new(}{it:varname}{cmd:)}


{marker description}{title:Description}

{pstd}
{cmd:opl_ma_vf} estimates the value-function for multi-action Optimal Policy Learning 
via three different methods:{p_end} 
{phang}
1. Regression Adjustment (RA): estimates expected outcomes for each action using regression models.
{p_end}
{phang}
2. Inverse Probability Weighting (IPW): uses estimated propensity scores to reweigh observations.
{p_end}
{phang}
3. Doubly Robust (DR): combines RA and IPW for a more robust estimator.
{p_end}

{marker options}{title:Options}

The following options are available:
{p2colset 5 35 35 2}
{p2line}
{p2col:{it:Option}}{it:Description}{p_end}
{p2line}
{p2col:{cmd:policy_train(}{it:varname}{cmd:)}} Variable indicating the treatment policy used for training.{p_end}
{p2col:{cmd:policy_new(}{it:varname}{cmd:)}} Variable indicating the new policy to be evaluated.{p_end}
{p2line}

{marker example}{title:Examples}

{pstd}{bf:Example}: Basic usage of {cmd:opl_ma_vf}{p_end}
{phang2} Generate the initial dataset by simulation:{p_end}
{phang3} {stata clear all}{p_end}
{phang3} {stata set obs 100}{p_end}
{phang3} {stata set seed 1010}{p_end}
{phang3} {stata generate A = floor(runiform()*3)}{p_end}
{phang3} {stata gen x1 = rnormal()}{p_end}
{phang3} {stata gen x2 = rnormal()}{p_end}
{phang3} {stata gen y = 100*runiform()}{p_end}
{phang2} Generate a new policy variable:{p_end}
{phang3} {stata gen pi = rpoisson(1)}{p_end}
{phang2} Estimate the value function for the new policy:{p_end}
{phang3} {stata opl_ma_vf y x1 x2 , policy_train(A) policy_new(pi)}{p_end}
{phang2} Print the return objects:{p_end}
{phang3} {stata ereturn list}{p_end}
{phang2} Estimate the value function for the training policy:{p_end}
{phang3} {stata opl_ma_vf y x1 x2 , policy_train(A) policy_new(A)}{p_end}
{phang2} Print the return objects:{p_end}
{phang3} {stata ereturn list}{p_end}


{marker results}{title:Stored Results}

{pstd}After execution, {cmd:opl_ma_vf} stores the following in {cmd:e()}: {p_end}

{synoptset 20 tabbed}
{synopthdr:Scalars}
{synoptline}
{synopt:{cmd:e(RA)}}Estimated value-function using Regression Adjustment{p_end}
{synopt:{cmd:e(IPW)}}Estimated value-function using Inverse Probability Weighting{p_end}
{synopt:{cmd:e(DR)}}Estimated value-function using Doubly Robust method{p_end}
{synoptline}

{dlgtab:References}

{phang}
Athey, S., and S. Wager. 2021.
Policy learning with observational data.
{it:Econometrica} 89(1): 133–161.
{p_end}

{phang}
Cerulli, G. 2021.
Improving econometric prediction by machine learning.
{it:Applied Economics Letters} 28(16): 1419–1425.
{p_end}

{phang}
Cerulli, G. 2022.
Optimal treatment assignment of a threshold-based policy: Empirical protocol and related issues.
{it:Applied Economics Letters} 30(8): 1010–1017.
{p_end}

{phang}
Cerulli, G. 2023.
{it:Fundamentals of Supervised Machine Learning: With Applications in Python, R, and Stata}.
Springer.
{p_end}

{phang}
Cerulli, G. 2024.
Optimal policy learning with observational data in multi-action scenarios:
Estimation, risk preference, and potential failures.
{it:arXiv preprint} arXiv:2403.20250.
{browse "https://arxiv.org/abs/2403.20250"}
{p_end}

{phang}
Cerulli, G. 2025.
Optimal policy learning using Stata.
{it:The Stata Journal} 25(2): 309–343.
{p_end}

{phang}
Gareth, J., D. Witten, T. Hastie, and R. Tibshirani. 2013.
{it:An Introduction to Statistical Learning: With Applications in R}.
Springer.
{p_end}

{phang}
Kennedy, E. H. 2023.
Towards optimal doubly robust estimation of heterogeneous causal effects.
{it:Electronic Journal of Statistics} 17(2): 3008–3049.
{p_end}

{phang}
Kitagawa, T., and A. Tetenov. 2018.
Who should be treated? Empirical welfare maximization methods for treatment choice.
{it:Econometrica} 86(2): 591–616.
{p_end}

{phang}
Kunzel, S. R., J. S. Sekhon, P. J. Bickel, and B. Yu. 2019.
Metalearners for estimating heterogeneous treatment effects using machine learning.
{it:Proceedings of the National Academy of Sciences} 116(10): 4156–4165.
{p_end}

{phang}
Zhou, Z., S. Athey, and S. Wager. 2023.
Offline multi-action policy learning: Generalization and optimization.
{it:Operations Research} 71(1): 148–183.
{p_end}

{dlgtab:Acknowledgment}

{pstd} 
The development of this software was supported by FOSSR (Fostering Open Science in Social Science Research), a project funded by the European Union - NextGenerationEU under the NPRR Grant agreement n. MURIR0000008.

{dlgtab:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@cnr.it":giovanni.cerulli@cnr.it}{p_end}


{dlgtab:Also see}

{psee}
Online: {helpb opl_ma_fb}, {helpb make_cate}, {helpb opl_tb}, {helpb opl_lc}, {helpb opl_lc_c}, {helpb opl_dt}, {helpb opl_dt_c}{p_end}
