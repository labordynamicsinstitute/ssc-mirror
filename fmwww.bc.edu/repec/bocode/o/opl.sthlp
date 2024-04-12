{smcl}
{* 10April2024}{...}

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

{synopt :{helpb make_cate:make_cate}}Predicting conditional average treatment effect (CATE){p_end}
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
