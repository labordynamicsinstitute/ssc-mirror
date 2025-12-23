{smcl}
{* 11dec2025}{...}
{cmd:help opl}
{hline}

{p2colset 5 16 21 2}{...}
{p2col :{hi:OPL} {hline 1}}Stata package for optimal policy learning{p_end}
{p2colreset}{...}


{marker syntax}{...}
{dlgtab:Syntax}

{p 8 15 2}
{cmd:command} ... [{cmd:,} {it:options}]


    MODULE 1: BINARY TREATMENT

{synoptset 16}{...}
{synopthdr:command}
{synoptline}
{synopt :{helpb make_cate:make_cate}}Estimation of the conditional average treatment effect (CATE){p_end}
{synopt :{helpb opl_overlap:opl_overlap}}Assessing overlap between train and new data{p_end}
{synopt :{helpb opl_tb:opl_tb}}Threshold-based optimal policy learning{p_end}
{synopt :{helpb opl_tb_c:opl_tb_c}}Threshold-based policy learning at specific threshold values{p_end}
{synopt :{helpb opl_lc:opl_lc}}Linear-combination optimal policy learning{p_end}
{synopt :{helpb opl_lc_c:opl_lc_c}}Linear-combination policy learning at specific parameters' values{p_end}
{synopt :{helpb opl_dt:opl_dt}}Decision-tree optimal policy learning{p_end}
{synopt :{helpb opl_dt_c:opl_dt_c}}Decision-tree policy learning at specific splitting variables and threshold values{p_end}
{synopt :{helpb opl_budget:opl_budget}}Optimal policy learning under budget constraint and minimum number of treated units{p_end}
{synoptline}
{p2colreset}{...}


    MODULE 2: MULTIVALUED TREATMENT

{synoptset 16}{...}
{synopthdr:command}
{synoptline}
{synopt :{helpb opl_ma_fb:opl_ma_fb}}Optimal policy learning for multivalued treatment using first-best optimal policy and risk preferences{p_end}
{synopt :{helpb opl_ma_vf:opl_ma_vf}}Value-function estimation for multivalues optimal policy learning using RA, IPW, and DR estimators{p_end}
{synopt :{helpb opl_best_treat:opl_best_treat}}Computing maximal reward and best treatment after {helpb opl_ma_fb}{p_end}
{synopt :{helpb opl_plot_best:opl_plot_best}}Plotting observed vs. maximal expected reward, and observed vs. optimal treatment{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{dlgtab:Description: Binary Treatment}

{pstd}
The binary treatment module of {cmd:OPL} allows for learning optimal policies from data for empirical welfare and impact maximization.
It learns the optimal policy empirically, i.e. based on observations obtained from previous (similar) implemented policies.
Specifically, this module of {cmd:OPL} allows to find a "treatment assignment rule" (π(X)) that: (1) maximize the welfare (via the "first-best" solution),
defined as the "value-function" E[Y(π)]; (2) maximize the impact, defined as the Average Treatment Effect on Treated (ATET(π)), 
within specific policy classes. This {cmd:OPL} module carries out empirical impact maximization within three policy classes: (i) Threshold-based; (ii) Linear-combination; and
(iii) Decision-tree, conditionally on the (unconstrained) maximization of the welfare. 

{pstd}
Empirical welfare and impact maximization requires the estimation of the Conditional
Average Treatment Effect (CATE) of the past policy. Currently, this module of {cmd:OPL} estimates CATE via
linear and non-linear Regression Adjustment (RA) allowing for the target outcome to be continuous, binary, count, or fractional,
and via Cross-Fitting Augmented Inverse Probability Weighting (CF-AIPW).
The treatment variable of reference must be binary 0/1.
{p_end}

{marker description}{...}
{dlgtab:Description: Multivalued Treatment}

{pstd}
    The multivalued treatment module of {cmd:OPL} extends optimal policy 
    learning to settings where the treatment takes M 
    discrete values (0,1,2,…,M−1). In this framework, the goal is to 
    learn a policy π(X) that assigns each unit to the treatment level 
    that maximizes its expected welfare among all available actions.

{pstd}    
    OPL estimates the value-function E[Y(d)] for each treatment t using 
    Regression Adjustment (RA), Inverse Probability Weighting (IPW), and 
    Doubly Robust (DR) estimators. These provide flexible and robust 
    ways to evaluate counterfactual rewards under multiple actions.
    
{pstd}
   Specifically, the command {helpb opl_ma_fb} computes the "first-best" multivalued policy, 
   optionally incorporating "risk preferences". The command {helpb opl_best_treat} 
   then identifies, for each unit, the treatment level that maximizes its predicted value. 

{pstd} 
    The command {helpb opl_ma_vf} outputs estimated value-functions for all 
    treatment levels, while {helpb opl_plot_best} produces diagnostics comparing 
    observed outcomes with maximal expected outcomes and observed versus 
    optimal treatments.

{pstd} 
    In the multivalued case, {cmd:OPL} does not allow, at present, for considering constrained 
    welfare maximization under specific policy classes. Only the (unconditional) first-best optimal policy is estimated, 
    although with and without risk preferences on the part of the decision maker. 


{dlgtab:References}

{phang}

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
{phang}E-mail: {browse "mailto:giovanni.cerulli@ircres.cnr.it":giovanni.cerulli@ircres.cnr.it}{p_end}
