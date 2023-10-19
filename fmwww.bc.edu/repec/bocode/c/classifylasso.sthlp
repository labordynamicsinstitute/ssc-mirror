{smcl}
{* July 2022}{...}
{title:Title}

{p 4 4 2}
{bf:classifylasso} —— Identify latent group structures via Classifier-Lasso.

{title:Syntax}

{p 8 15 2} {cmd:classifylasso}
{depvar} [{indepvars}]
{ifin} [{cmd:, group()} {help classifylasso##options:options}] 
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Optimization {help classifylasso##opt_optimization:[+]}}
{synopt :{opth g:roup(numlist)}}specify the possible numbers of latent groups; 
the default is {cmd:group(2)}{p_end}
{synopt :{opth lam:bda(#)}}tuning parameter in the penalized least squares (PLS) objective function; 
the default is {cmd:lambda(0.5)}{p_end}
{synopt :{opth rho(#)}}constant multiplier of the tuning parameter in the BIC-type information criterion; 
the default is {cmd:rho(0.67)}{p_end}
{synopt :{opth tol:erance(#)}}tolerance criterion for convergence in the iterative algorithm; 
the default is {cmd:tolerance(0.01)}{p_end}
{synopt :{opth maxit:erations(#)}}maximum level of iterations in the iterative algorithm; 
the default is {cmd:maxiterations(20)}{p_end}
{synopt :{help classifylasso##optoptions:{it:optimize_options}}}control the {opt optimize} package;
{opth optp:tol(#)}, {opth optv:tol(#)}, {opth optnr:tol(#)}, {opth optmax:iter(#)}, {opt optign:orenrtol(string)}, {opt opttech:nique(string)}, {opt optsing:ularHmethod(string)}

{syntab:Regression {help classifylasso##opt_regression:[+]}}
{synopt :{opth a:bsorb(varlist)}}categorical variables that identify the fixed effects to be absorbed; the default is the panel (unit) variable by {opt xtset}{p_end}
{synopt :{opt noa:bsorb}}suppress the fixed effects{p_end}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt ols} (default),
   {opt r:obust}, or {opt cl:uster} {it:clustvar}{p_end}
{synopt :{opt dy:namic}}conduct bias correction in dynamic models{p_end}

{syntab:Display {help classifylasso##opt_display:[+]}}
{synopt :{opt notab:le}}suppress the estimation table{p_end}
{synopt :{help classifylasso##disoptions:{it:display_options}}}control the display style{p_end}
{synoptline}


{title:Description}

{p 4 4 2}{cmd:classifylasso} facalitates practitioners to identifiy latent group structures via Classifier-Lasso.
It simultaneously identifies and estimates unobserved parameter heterogeneity in
panel data models using penalized techniques. {p_end}

{p 4 4 2}{cmd:classifylasso} displays the group selection information and an estimation table.
{help classifylasso##storedresults:Estimation results} are stored in {cmd:e()} form.
{help classifylasso##postestimation:Postestimation commands} are allowed to generate new variables or to visualize more results. {p_end}


{marker options}{...}
{title:Options}

{marker opt_optimization}{...}
{dlgtab:Optimization}

{phang}{opth g:roup(numlist)} specifies the possible numbers of latent groups. 
The default is {cmd:group(2)}. 
When the group number is set to be 1, the regression degenerates to the conventional panel data estimation with common slope coefficients.

{pmore} If more than one possible number is input, the best-fit number of groups will be determined by minimizing the information criterion. 
The information criterion consists of the logarithm of min-squared error and a penalized term of the product of number of parameters and number of groups. 

{phang}{opt lam:bda(#)} specifies the tuning parameter in the penalized least squares PLS objective function. The default is {opt lambda(0.5)}.

{pmore}The PLS objective function consists of the conventional least-squares function and a additive-multiplication penalized term. 
Note that the lambda option controls the {it: λ} instead of {it: λ_NT=λT^(-1/3)} eq.(2.6) in Section 2.3 of Su, Shi, and Phillips (2016).

{phang}{opt rho(#)} specifies the constant multiplier of the tuning parameter in the BIC-type information
criterion. 
The default is {opt rho(0.67)}. 

{pmore}Note that the rho option controls the value of {it:ρ} instead of {it:ρ_NT=ρ(NT)^(-1/2)}, according to Assumption A5* in Section 2.6 of Su, Shi, and Phillips (2016).

{phang}{opt tol:erance(#)} specifies the tolerance criterion for convergence in the iterative algorithm.
 The default is {opt tolerance(0.01)}. 

{pmore} If the tolerance criterion is not tight enough, the iteration may not end in optimal estimation. On the other hand, if the tolerance criterion is too small, the iteration may be time-consuming. The
same comments suit the {opt maxiterations(#)} option.

{phang}{opt maxit:erations(#)} specifies the maximum level of iterations in the iterative algorithm. 
The default is {opt maxiterations(20)}. 

{marker optoptions}{...}
{phang}{it:optimize_options} control the {opt optimize} package; 
see {helpb optimize:[M-5] optimize()} for more details.

{pmore}{opt optp:tol(#)}, {opt optv:tol(#)}, {opt optnr:tol(#)}, {opt optmax:iter(#)}, and {opt optign:orenrtol(string)} determine the convergence criterion, whose parameters are transmitted to
{opt optimize_init_conv_ptol(#)}, ... {opt vtol(#)}, ... {opt nrtol(#)}, ... {opt maxiter(#)}, ... {opt ignorenrtol(S, "off"|"on")}; 
the default is 1e-6, 1e-7, 1e-5, 150, "off", respectively.

{pmore}{opt opttech:nique(string)} and {opt optsing:ularHmethod(string)} determine the optimization method, 
whose parameters are transmitted to {opt optimize_init_technique(S, "nr"|"dfp"|"bfgs"|"bhhh"|"nm")} and ... {opt optsingularHmethod(S, "m-marquardt"|"hybrid")} 
({it:S} is the transmorphic defined in the command); 
the default is "bfgs" and "m-marquardt", respectively.

{marker opt_regression}{...}
{dlgtab:Regression}

{phang}{opth a:bsorb(varlist)} specifies the categorical variables representing the the fixed effects to be absorbed. By default, the panel (unit) variable is absorbed.

{phang}{opt noa:bsorb} suppresses the fixed effects in the model.

{phang}{opth vce(vcetype)} specifies the type of standard error in post-Lasso estimation, which
includes types that are derived from asymptotic theory ({opt ols}, the default),
that are robust to some kinds of misspecification ({opt robust}), that allow
for intragroup correlation ({opt cluster} {it:clustvar}); see
{helpb vce_option:[R] {it:vce_option}}. 
Moreover, a single {opt robust} option is the same as {cmd:vce(robust)}, and a single {opt cluster} {it:clustvar} option is the same as {cmd:vce(cluster {it:clustvar})}. 
Note that the standard error in C-Lasso estimation is always the default {opt ols}.

{phang}{opt dy:namic} applies Dhaene and Jochmans's (2015) half-panel jackknife method to conduct
bias correction in dynamic models. 
Meanwhile, the autocorrelation-and-heteroscedasticity consistent standard errors (HAC) will be the default of {opt vce()}.

{marker opt_display}{...}
{dlgtab:Display}

{phang}{opt notab:le} suppresses the estimation table. 

{marker disoptions}{...}
{phang}{it:display_options}: {opt noci}, {opt nopv:alues}, {opt noomit:ted}, {opt vsquish}, {opt noempty:cells}, {opt base:levels}, {opt allbase:levels}, {opt nofvlab:el},
{opt fvwrap(#)}, {opt fvwrapon(style)}, {opth cformat(%fmt)}, {opt pformat(%fmt)}, {opt sformat(%fmt)}, and {opt nolstretch};
see {helpb Estimation options:[R] Estimation options}.


{marker examples}{...}
{title:Examples}

{synoptline}
{pstd}Setup{p_end}
{phang2}{cmd:. use classifylasso.dta, clear}{p_end}
{phang2}{cmd:. xtset id t}{p_end}
{pstd}Obtain selection and estimation results{p_end}
{phang2}{cmd:. classifylasso y x1 x2, group(1/5)}{p_end}
{pstd}Or obtain the estimation results without selection{p_end}
{phang2}{cmd:. classifylasso y x1 x2, group(2)}{p_end}
{synoptline}
{pstd}Replication of Su, Shi and Phillips (2016). Note that it is time-consuming. {p_end}
{phang2}{cmd:. use saving.dta, clear}{p_end}
{phang2}{cmd:. xtset code year}{p_end}
{phang2}{cmd:. classifylasso savings lagsavings cpi interest gdp, group(1/5) dynamic}{p_end}
{synoptline}


{marker postestimation}{...}
{title:Postestimation commands}

{p 4 4 2}The following postestimation commands are available after {cmd:classifylasso}:

{synoptset 17}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :{helpb classoselect}}select an alternative estimation result{p_end}
{synopt :{helpb classifylasso_p:predict}}predict group membership and fitted values{p_end}
{synopt :{cmd:estimates replay}}redisplay the estimation results{p_end}
{synopt :{helpb classocoef}}plot the coefficients{p_end}
{synopt :{helpb classogroup}}plot the group selection information{p_end}
{synoptline}

{p 4 4 2}The syntaxes for {cmd:classoselect}, {cmd:predict} and {cmd:estimates replay} are listed as follows:

{p 8 15 2} {cmd:classoselect} [{cmd:,} {it:options}] 
{p_end}
{col 23}The selected estimation result is used by {cmd:predict}, {cmd:estimates replay} and {cmd:classocoef}
{col 23}By default, post-Lasso coefficients with the BIC-best number of groups are selected

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt group(#)}}use coefficients estimated under certain number of groups{p_end}
{synopt :{opt post:selection}}use postselection (unpenalized) coefficients{p_end}
{synopt :{opt pen:alized}}use penalized coefficients{p_end}
{synoptline}

{p 8 15 2} {cmd:predict} {newvar}
{ifin} [{cmd:,} {it:statistic}]
{p_end}
{col 23}For each group, suppose y = xb + d_absorbvars + e; see {helpb reghdfe} for details

{synoptset 20 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt :{opt gid}}group membership; the default{p_end}
{synopt :{opt xb}}xb fitted values{p_end}
{synopt :{opt xbd}}xb + d_absorbvars{p_end}
{synopt :{opt d}}d_absorbvars{p_end}
{synopt :{opt r:esiduals}}residuals{p_end}
{synopt :{opt stdp}}standard error of the prediction (of the xb component){p_end}
{synoptline}

{p 8 13 2}
{cmd:estimates replay} [{cmd:,} {it:options}]
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt out:reg2(filename)}}export the tables one group a column; require {helpb outreg2} installed {p_end}
{synopt :{help classifylasso##disoptions:{it:display_options}}}control the display style{p_end}
{synoptline}

{p 4 4 2}For more details, please link to the corresponding help file.


{marker storedresults}{...}
{title:Stored results}

{pstd}{cmd:classifylasso} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(obs)}}sample size{p_end}
{synopt:{cmd:e(N)}}number of individual units{p_end}
{synopt:{cmd:e(group)}}active number of groups{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(title)}}{opt Classifier-Lasso}{p_end}
{synopt:{cmd:e(cmd)}}{opt classifylasso}{p_end}
{synopt:{cmd:e(predict)}}{opt classifylasso_p}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvar)}}name of independent variables{p_end}
{synopt:{cmd:e(absvar)}}name of the absorbed variables{p_end}
{synopt:{cmd:e(grouplist)}}possible group number list{p_end}
{synopt:{cmd:e(coef)}}active coefficients, postselection or penalized{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(a_classo_G}{it:K}{cmd:)}}C-Lasso coefficient matrix under {it:K} groups{p_end}
{synopt:{cmd:e(V_classo_G}{it:K}{cmd:)}}C-Lasso covariance matrix under {it:K} groups{p_end}
{synopt:{cmd:e(rsq_classo_G}{it:K}{cmd:)}}C-Lasso R-squared under {it:K} groups{p_end}
{synopt:{cmd:e(a_post_G}{it:K}{cmd:)}}post-Lasso coefficient matrix under {it:K} groups{p_end}
{synopt:{cmd:e(V_post_G}{it:K}{cmd:)}}post-Lasso covariance matrix under {it:K} groups{p_end}
{synopt:{cmd:e(rsq_post_G}{it:K}{cmd:)}}post-Lasso R-squared under {it:K} groups{p_end}
{synopt:{cmd:e(df_G}{it:K}{cmd:)}}degrees of freedom under {it:K} groups{p_end}
{synopt:{cmd:e(id)}}group membership and individual information matrix {p_end}
{synopt:{cmd:e(selection)}}selection information matrix{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{phang}For the ereturn matrices, {it:K} can be any number specified by {opth group(numlist)}. Let {it: N}, {it: p}, and {it: nK} be the number of individuals, independent variables, and length of {opth group(numlist)}:

{pmore}{cmd:e(a_classo_G}{it:K}{cmd:)} and {cmd:e(a_post_G}{it:K}{cmd:)} are {it:K×p} matrices with each row representing a coefficient vector of one group; 
{cmd:e(V_classo_G}{it:K}{cmd:)} and {cmd:e(V_post_G}{it:K}{cmd:)} are {it:Kp×p} matrices with each {it:p×p} matrix representing a covariance matrix of one group.
{cmd:e(rsq_classo_G}{it:K}{cmd:)} and {cmd:e(rsq_post_G}{it:K}{cmd:)} are {it:K×5} matrices with each row representing R-sq., Adj R-sq., Within R-sq., Adj Within R-sq., and RMSE of one group.
{cmd:e(df_G}{it:K}{cmd:)} are {it:K×6} matrices with each row representing various degrees of freedom of one group.

{pmore}{cmd:e(id)} is a {it:N×(p+nK+2)} matrix with each row reporting the id, group membership under different groups,
the time-series estimations, and number of observations.
{cmd:e(selection)} is a {it:nK×6} matrix with each row representing one selection with the
group number, information criterion, logarithm mean square error, number of iterations, maximum iteration, and computation time. 

{title:References}

{p 4 4 2}The program is designed by{p_end}

{phang2}Wenxin Huang, Yiru Wang, and Lingyun Zhou. "Identifying latent structures in panel data: the classifylasso command".  {it:Accepted at the Stata Journal.}{p_end}

{p 4 4 2}For the rationale behind Classifier-Lasso, see{p_end}

{phang2}Liangjun Su, Zhentao Shi, and Peter C.B. Phillips. "Identifying latent structures in panel data".  {it:Econometrica 84.6 (2016): 2215-2264.} {browse "https://onlinelibrary.wiley.com/doi/abs/10.3982/ECTA12560":[link]} {p_end}

{p 4 4 2}Additional references:{p_end}

{phang2}Geert Dhaene and Koen Jochmans. "Split-panel jackknife estimation of fixed-effect models".  {it:The Review of Economic Studies 82.3 (2015): 991-1030.} 
{browse "https://academic.oup.com/restud/article-abstract/82/3/991/1574974":[link]} {p_end}

{title:Compatibility and known issues}

{phang} Please ensure the following information before running the {opt classifylasso} program:{p_end}
{phang2}. The programs are written in version 17.0.{p_end}
{phang2}. The following files are required: classifylasso.ado and classifylasso.mata, classifylasso_p.ado classoselect.ado, classocoef.ado, and classogroup.ado.{p_end}
{phang2}. Commands {cmd:reghdfe} and {cmd:ftools} are pre-installed.{p_end}
{phang2}. Panel structure is declared: {opt tsset} or {opt xtset} {it: panelvar timevar}.{p_end}

{title:Author}

{p 4 4 2}
{cmd:Wenxin HUANG}{break}
Antai College of Economics and Management, Shanghai Jiao Tong University.{break}

{p 4 4 2}
{cmd:Yiru WANG}{break}
Department of Economics, University of Pittsburgh.{break}

{p 4 4 2}
{cmd:Lingyun ZHOU}{break}
PBC School of Finance, Tsinghua University.{break}
