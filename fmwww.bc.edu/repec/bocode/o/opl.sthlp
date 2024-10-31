{smcl}
{* 25July2024}{...}

{p2colset 5 16 21 2}{...}
{p2col :{hi:OPL} {hline 1}}Stata package for optimal policy learning{p_end}
{p2colreset}{...}


{marker syntax}{...}
{dlgtab:Syntax}

{p 8 15 2}
{cmd:command} ... [{cmd:,} {it:options}]

{synoptset 16}{...}
{synopthdr:command}
{synoptline}
{synopt :{helpb make_cate:make_cate}}Estimation of the conditional average treatment effect (CATE){p_end}
{synopt :{helpb opl_tb:opl_tb}}Threshold-based optimal policy learning{p_end}
{synopt :{helpb opl_tb_c:opl_tb_c}}Threshold-based policy learning at specific threshold values{p_end}
{synopt :{helpb opl_lc:opl_lc}}Linear-combination optimal policy learning{p_end}
{synopt :{helpb opl_lc_c:opl_lc_c}}Linear-combination policy learning at specific parameters' values{p_end}
{synopt :{helpb opl_dt:opl_dt}}Decision-tree optimal policy learning{p_end}
{synopt :{helpb opl_dt_c:opl_dt_c}}Decision-tree policy learning at specific splitting variables and threshold values{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{dlgtab:Description}

{pstd}
{cmd:OPL} is a package for learning optimal policies from data for empirical welfare maximization.
Specifically, {cmd:OPL} allows to find "treatment assignment rules" that maximize the overall welfare, defined as the sum of 
the policy effects estimated over all the policy beneficiaries. 
{cmd:OPL} learns the optimal policy empirically, i.e. based on data and observations obtained from previous (same or similar) implemented policies. 
{cmd:OPL} carries out empirical welfare maximization within three policy classes: (i) Threshold-based; (ii) Linear-combination; and
(iii) Decision-tree. 

{pstd}
Empirical welfare maximization requires the estimation of the Conditional
Average Treatment Effect (CATE) of the past policy. Currently, {cmd:OPL} estimates CATE via
linear and non-linear Regression Adjustment (RA), allowing for the target outcome to be continuous, binary, count, or fractional.
The treatment variable of reference must be binary 0/1.
{p_end}

{marker description}{...}
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
