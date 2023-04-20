{smcl}
{* *! version 2  09Feb2023}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "[ME] mixed" "help mixed"}{...}
{vieweralsosee "[ME] menl" "help menl"}{...}
{vieweralsosee "runmixregls" "help runmixregls"}{...}
{vieweralsosee "runmlwin" "help runmlwin"}{...}
{vieweralsosee "gllamm" "help gllamm"}{...}
{viewerjumpto "Syntax" "runmixregmls##syntax"}{...}
{viewerjumpto "Description" "runmixregmls##description"}{...}
{viewerjumpto "Options" "runmixregmls##options"}{...}
{viewerjumpto "Remarks" "runmixregmls##remarks"}{...}
{viewerjumpto "Examples" "runmixregmls##examples"}{...}
{viewerjumpto "Saved results" "runmixregmls##saved_results"}{...}
{viewerjumpto "References" "runmixregmls##references"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd:runmixregmls} {hline 2}}Run the MIXREGMLS mixed-effects location scale software from within Stata{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:runmixregmls} {depvar} [{varlist}] {ifin} [{cmd:,} {it:options}]

{p 4 4 2}
where {varlist} specifies variables in the mean function.

{synoptset 33 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt nocons:tant}}suppress constant term in the mean function{p_end}
{synopt:{opt b:etween}{cmd:(}{varlist}[{cmd:,} {cmdab:nocons:tant}]{cmd:)}}specify variables in the mean function with random coefficients{p_end}
{synopt:{opt w:ithin}{cmd:(}{varlist}[{cmd:,} {cmdab:nocons:tant}]{cmd:)}}specify variables in within-group variance function{p_end}

{syntab:Random effects/Residuals}
{synopt:{opth meanxb(newvar)}}mean function linear prediction for the fixed portion only{p_end}
{synopt:{opth meanfitted(newvar)}}mean function fitted values based on the fixed portion linear prediction plus contributions based on the predicted random location effects{p_end}
{synopt:{opth bgvariancefitted(newvar)}}between-group variance function variance implied by the random effects{p_end}
{synopt:{opth wgvariancexb(newvar)}}within-group variance function linear prediction for the fixed portion only{p_end}
{synopt:{opth wgvarianceeta(newvar)}}within-group variance function linear prediction for the fixed portion plus predicted random scale effect{p_end}
{synopt:{opth wgvariancefitted(newvar)}}within-group variance function exponentiated linear prediction for the fixed portion plus predicted random scale effect{p_end}
{synopt:{opt reffects}{cmd:(}{it:stub{bf:*}}{cmd:)}}standardized random-location and random-scale effects{p_end}
{synopt:{opt reunstandard}{cmd:(}{it:stub{bf:*}}{cmd:)}}unstandardized random-location and random-scale effects{p_end}
{synopt:{opth residuals(newvar)}}standardized residual errors{p_end}
{synopt:{opth runstandard(newvar)}}unstandardized residual errors{p_end}

{syntab:Integration}
{synopt:{opt noadapt}}do not perform adaptive Gaussian quadrature {p_end}
{synopt:{opt intp:oints(#)}}set the number of integration (quadrature) points; default is {cmd:intpoints(11)}{p_end}

{syntab:Maximization}
{synopt:{opt iterate(#)}}maximum number of iterations; default is {cmd:iterate(200)}{p_end}
{synopt:{opt tol:erance(#)}}tolerance; default is {cmd:tolerance(0.0005)}{p_end}
{synopt:{opt stand:ardize}}standardize all covariates{p_end}
{synopt:{opt ridge:in(#)}}initial value for ridge; default is {cmd:ridgein(0)}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{it:{help runmixregmls##display_options:display_options}}}control column formats, row spacing, line width,
and display of omitted variables and base and empty cells{p_end}
{synopt:{opt nohe:ader}}suppress table header{p_end}
{synopt:{opt notab:le}}suppress coefficient table{p_end}
{synopt:{opt coefl:egend}}display legend instead of statistics{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
A panel variable must be specified. Use {helpb xtset}. {p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:runmixregmls} runs the
{browse "http://publichealth.uic.edu/epidemiology-and-biostatistics/projects":MIXREGMLS}
mixed-effects location scale software from within Stata.

{pstd}
The software can fit two-level random-intercept and random-coefficient mixed-effects location scale models for continuous responses.

{pstd}
The mixed-effects location scale model extends the conventional 
mixed-effects model ({cmd:xtreg, mle} and {cmd:mixed}) in three ways.

{p 8 12 2}
(1) The (log of the) within-group variance is further modeled as functions of the covariates.

{p 8 12 2}
(2) A new random effect, referred to as the random-scale effect, 
is then entered into the within-group variance function to account for any unexplained group differences in the residual variance.
The existing random-intercept and any random-coefficient effects are now referred to as random-intercept and random-coefficient location effects. 

{p 8 12 2}
(3) The covariances between the location and the scale random effects are freely estimated.

{pstd}
The distributions of the random-location and random-scale effects are assumed to be Gaussian.  

{pstd}
runmixregmls is the sister command to the original runmixregls command which runs the MIXREGLS mixed-effects location scale software (Hedeker and Nordgren 2013) from within Stata. 
The difference between the two commands is that runmixregls can only fit two-level random-intercept versions of the mixed-effects location scale model for continuous responses, 
but in contrast to runmixregmls can allow the log of the between-group variance to optionally be modelled as a function of the variables. 
The two commands also differ in their parameterisation of the model. 

{pstd}
Both runmixregls and runmixregmls can therefore fit two-level random-intercept models with a constant between-group variance and a log within-group variance further modeled as 
functions of the covariates and a new scale random-scale effect, but both commands allow different extensions to this model and that will dictate which command is used. 
Where only this simplest model is desired, the two commands implement different parameterisations of this model and so while the model fit statistics will be identical, the model estimates will differ correspondingly. 

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt noconstant}; see
{helpb estimation options##noconstant:[R] estimation options}. 

{phang}
{opt between}{cmd:(}{varlist}[{cmd:,} {cmdab:nocons:tant}]{cmd:)} 
specifies the variables with random coefficients.

{phang}
{opt within}{cmd:(}{varlist}[{cmd:,} {cmdab:nocons:tant}]{cmd:)}
specifies the variables in the within-group variance function.

{dlgtab:Postestimation prediction tools}

{phang}
{opth meanxb(newvar)} calculates the mean function linear prediction for the fixed portion only. This is equivalent to fixing the random location effects in the model to their theoretical (prior) mean value of 0.

{phang}
{opth meanfitted(newvar)} calculates the mean function fitted values based on the fixed portion linear prediction plus contributions based on the predicted random location effects.

{phang}
{opth bgvariancefitted(newvar)} calculates the between-group variance function variance implied by the random location effects.

{phang}
{opth wgvariancexb(newvar)} calculates the within-group variance function linear prediction for the fixed portion only. This is equivalent to fixing the random scale effect in the function to its theoretical (prior) mean value of 0.

{phang}
{opth wgvarianceeta(newvar)} calculates the within-group variance function linear prediction for the fixed portion plus the predicted random scale effect.

{phang}
{opth wgvariancefitted(newvar)} calculates the within-group variance function exponentiated linear prediction for the fixed portion plus the predicted random scale effect.


{phang}
{opt reffects}{cmd:(}{it:stub{bf:*}}{cmd:)}
retrieves the best linear unbiased predictions (BLUPs) of the standardized random effects from MIXREGMLS.
BLUPs are also known as empirical Bayes estimates. The sampling variances, covariances and SEs are also returned. 

{phang}
{opt reunstandard}{cmd:(}{it:stub{bf:*}}{cmd:)}
retrieve unstandardized random-location and random-scale effects.
The sampling variances, covariances and SEs are also returned.

{phang}
{opth runstandard(newvar)} retrieves the residual errors from MIXREGMLS.

{phang}
{opth residuals(newvar)} retrieves the standardized residual errors from MIXREGMLS.


{dlgtab:Integration}

{phang}
{opt noadapt} prevents MIXREGMLS from using adaptive Gaussian quadrature.
MIXREGMLS will use ordinary Gaussian quadrature instead.

{phang}
{opt intpoints(#)} sets the number of integration points for (adaptive) Gaussian quadrature.
The default is {cmd:intpoints(11)}.
The more points, the more accurate the approximation to the log likelihood.
However, computation time increases with the number of quadrature points.
When models do not converge properly, increasing the number of quadrature points can sometimes lead to convergence.

{dlgtab:Maximization}

{phang}
{opt iterate(#)} specifies the maximum number of iterations.  
The default is {cmd:iterate(200)}.
You should seldom have to use this option.

{phang}
{opt tolerance(#)} specifies the convergence tolerance.
The default is {cmd:tolerance(0.0005)}.
You should seldom have to use this option.

{phang}
{opt standardize} standardizes all covariates in all functions during optimization.
This ensures all covariates are on the same numerical scale with mean 0 and variance 1.
This can be helpful if the model "blows up" or does not converge to the solution.

{phang}
{opt ridgein(#)} specifies the initial value for the ridge parameter.
The default is {cmd:ridgein(200)}.
This is a numeric value that adds to the diagonal of the second derivative matrix, which can aid in convergence of the solution; usually set to 0 or some small fractional value.


{dlgtab:Reporting}

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] estimation options}.

{marker display_options}{...}
{phang}
{it:display_options}:
{opt noomit:ted},
{opt vsquish},
{opt noempty:cells},
{opt base:levels},
{opt allbase:levels},
{opth cformat(%fmt)},
{opt pformat(%fmt)},
{opt sformat(%fmt)}, and
{opt nolstretch};
    see {helpb estimation options##display_options:[R] estimation options}.

{phang}
{opt noheader} suppresses the display of the summary statistics at the top of 
the output; only the coefficient table is displayed.

{phang}
{opt notable} suppresses display of the coefficient table.

{phang}
{opt coeflegend}; see
     {helpb estimation options##coeflegend:[R] estimation options}.


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:

            {help runmixregmls##remarks_ri_model:Remarks on the random-intercept mixed-effects location scale model}
            {help runmixregmls##remarks_rc_model:Remarks on the random-coefficient mixed-effects location scale model}
            {help runmixregmls##remarks_first_time:Remarks on getting runmixregmls working for the first time}
            {help runmixregmls##remarks_mixregls_estimation:Remarks on MIXREGMLS estimation}
            {help runmixregmls##remarks_runmixregmls_output:Remarks on runmixregmls output}


{marker remarks_ri_model}{...}
{title:Remarks on the random-intercept mixed-effects location scale model}

{pstd}
The random-intercept mixed-effects location scale model fitted by MIXREGMLS consists of two functions

{p 8 12 2}
(1) the mean function,

{p 8 12 2}
(2) the within-group variance function.

{pstd}
For simplicity, consider a model with a single covariate x_ij.

{pstd}
These two functions can then be written as

{pmore}
y_ij = b0 + b1*x_ij + u_j + e_ij,   i=1,...,n_j;   j=1,...,J,

{pmore}
log(sigma2_e_ij) = a0 + a1*x_ij + v_j,

{pstd}
where

{pmore}
u_j ~ N(0, sigma2_u),

{pmore}
v_j ~ N(0, sigma2_v),

{pmore}
e_ij ~ N(0, sigma2_e_ij),

{pmore}
sigma_uv = cov(u_j, v_j)

{pstd}
and

{pmore}
y_ij is the continuous response variable,

{pmore}
x_ij is the covariate,

{pmore}
b0, b1, a0, a1, are regression coefficients to be estimated,

{pmore}
u_j is the unobserved random-intercept location effect,

{pmore}
v_j is the unobserved random-scale effect,

{pmore}
e_ij are the observation-specific errors.

{pstd}
The u_j and v_j are modeled as correlated.

{pstd}
For computational reasons, MIXREGLS estimates a reparameterised version of the above model where a Cholesky decomposition is applied to the 2x2 random effects covariance matrix S leading to S = L*L’ where L is a lower triangular matrix.
The associated random effects are then standardized independent standard normal variates theta_u_j and theta_v_j.
While the random effects variances and covariance returned by MIXREGLS are on the metric of the original parameterisation, the predicted random effects are on the reparametrized metric and so are predicted standardized random effects.
The predicted unstandardized random effects are calculated by applying L to the predicted standardize random effects.

{pmore}
u_j = sigma_u * theta_u_j

{pmore}
v_j = (sigma_uv / sigma_v) * theta_u_j + sqrt(sigma_v^2 – sigma_vw^2 / sigma_u^2) * theta_v_j

{marker remarks_rc_model}{...}
{title:Remarks on the random-coefficient mixed-effects location scale model}

{pstd}
The random-coefficient mixed-effects location scale model fitted by MIXREGMLS consists of two functions

{p 8 12 2}
(1) the mean function,

{p 8 12 2}
(2) the within-group variance function.

{pstd}
For simplicity, consider a model with a single covariate x_ij.

{pstd}
These two functions can then be written as

{pmore}
y_ij = b0 + b1*x_ij + u0_j + u1_j*x_ij + e_ij,   i=1,...,n_j;   j=1,...,J,

{pmore}
log(sigma2_e_ij) = a0 + a1*x_ij + v_j,

{pstd}
where

{pmore}
u0_j ~ N(0, sigma2_u0),

{pmore}
u1_j ~ N(0, sigma2_u1),

{pmore}
v_j ~ N(0, sigma2_v),

{pmore}
e_ij ~ N(0,sigma2_e_ij),

{pmore}
sigma_u0u1 = cov(u0_j, u1_j)

{pmore}
sigma_u0v = cov(u0_j, v_j)

{pmore}
sigma_u1v = cov(u1_j, v_j)

{pstd}
and

{pmore}
y_ij is the continuous response variable,

{pmore}
x_ij is the covariate,

{pmore}
b0, b1, a0, a1 are regression coefficients to be estimated,

{pmore}
u0_j is the unobserved random-intercept location effect,

{pmore}
u1_j is the unobserved random-coefficient location effect,

{pmore}
v_j is the unobserved random-scale effect,

{pmore}
e_ij are the observation-specific errors.

{pstd}
The u0_j, u1_j and v_j are modeled as correlated

{pstd}
When the predicted random effects are requested, these will be predicted standardized random effects theta_u0_j, theta_u1_j and theta_v_j. 
The predicted unstandardized random effects are calculated by applying L from the Cholesky decomposition of the 3*3 random effect covariance matrix to the predicted standardized random effects.


{marker remarks_first_time}{...}
{title:Remarks on getting runmixregmls working for the first time}

{pstd}
{cmd:runmixregmls} can be installed from the Statistical Software Components (SSC) archive by typing the following
from a net-aware version of Stata

{p 8 12 2}
{cmd:. ssc install runmixregls}

{pstd}
If you have already installed {cmd:runmixregls} from the SSC, you can check that you are using the latest version
by typing the following command:

{phang2}{stata "adoupdate runmixregls":. adoupdate runmixregls}{p_end}


{marker remarks_mixregls_estimation}{...}
{title:Remarks on MIXREGMLS estimation}

{pstd}
MIXREGMLS uses maximum likelihood estimation, utilizing both the EM algorithm and a Newton-Raphson solution.
Because the log likelihood for this model has no closed form, it is approximated by adaptive Gaussian quadrature.
Estimation of the random effects is accomplished using empirical Bayes methods.
The full model is estimated in three sequential stages. For simplicity we focus here on the random-intercept version of the model:

{p 8 18 2}
(1) Standard mixed-effects model

{p 8 18 2}
(2) Stage 1 model + within-group variance function regression coefficients

{p 8 18 2}
(3) Stage 2 model + random-scale effect + covariances between location and scale random effects

{pstd}
Prior to Stage 1, 20 iterations are performed of the EM algorithm 
to estimate the parameters of a standard random-intercept model
(regression coefficients, between-group variance, within-group variance, and random-location effects).
These estimates are then used as starting values for Stage 1
estimates at each stage are used as starting values for the next stage, 
which improves the convergence of the final model.
This also provides a way of assessing the statistical significance of the additional parameters in each stage via likelihood-ratio tests.
The results of each stage as well as these likelihood-ratio tests are provided in the {help runmixregmls##saved_results:saved results}.

{pstd}
See {help runmixregmls##HN2013:Hedeker and Nordgren 2013} for further details on the MIXREGMLS estimation which is the same as the MIXREGLS estimation.


{marker remarks_runmixregmls_output}{...}
{title:Remarks on runmixregmls output}

{pstd}
The {cmd:runmixregmls} output displays five different sets of parameters

{p 8 12 2}
Mean:{space 8}
Mean function regression coefficients

{p 8 12 2}
Between:{space 5}
Between-group variance-covariance parameters

{p 8 12 2}
Within:{space 6}
Within-group variance function regression coefficients (log scale)

{p 8 12 2}
Association:{space 1}
Covariances between the location and scale random effects

{p 8 12 2}
Scale:{space 7}
Random-scale variance


{marker examples}{...}
{title:Example:}

{pstd}Load the data{p_end}
{phang2}{bf:{stata "use http://www.bristol.ac.uk/cmm/media/runmixregmls/tutorial, clear":. use http://www.bristol.ac.uk/cmm/media/runmixregmls/tutorial, clear}}

{pstd}Declare panel variable to be school{p_end}
{phang2}{bf:{stata "xtset school":. xtset school}}

{pstd}Fit the two-level random-intercept mixed-effects location scale model with no covariates{p_end}
{phang2}{bf:{stata "runmixregmls normexam":. runmixregmls normexam}}

{pstd}Refit the model adding covariates to the mean model{p_end}
{phang2}{bf:{stata "runmixregmls normexam standlrt girl":. runmixregmls normexam standlrt girl}}

{pstd}Refit the model adding covariates to the within-group variance function{p_end}
{phang2}{bf:{stata "runmixregmls normexam standlrt girl, within(standlrt girl)":. runmixregmls normexam standlrt girl, within(standlrt girl)}}

{pstd}Refit the model and calculate the unstandardized random effects and residual errors{p_end}
{phang2}{bf:{stata "runmixregmls normexam standlrt girl, within(standlrt girl) reunstandard(u) runstandard(e)":. runmixregmls normexam standlrt girl, within(standlrt girl) reunstandard(u) runstandard(e)}}

{pstd}Refit the model adding a random coefficient{p_end}
{phang2}{bf:{stata "runmixregmls normexam standlrt girl, between(standlrt)":. runmixregmls normexam standlrt girl, between(standlrt)}}

{pstd}Refit the model adding a random coefficient and covariates to the within-group variance function{p_end}
{phang2}{bf:{stata "runmixregmls normexam standlrt girl, between(standlrt) within(standlrt girl)":. runmixregmls normexam standlrt girl, between(standlrt) within(standlrt girl)}}
 
{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:runmixregmls} saves the following in e():

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Scalars}{p_end}

{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(g_min)}}smallest group size{p_end}
{synopt:{cmd:e(g_avg)}}average group size{p_end}
{synopt:{cmd:e(g_max)}}largest group size{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_1)}}number of parameters, stage 1 model{p_end}
{synopt:{cmd:e(k_2)}}number of parameters, stage 2 model{p_end}
{synopt:{cmd:e(k_3)}}number of parameters, stage 3 model{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_1)}}log likelihood, stage 1 model{p_end}
{synopt:{cmd:e(ll_2)}}log likelihood, stage 2 model{p_end}
{synopt:{cmd:e(ll_3)}}log likelihood, stage 3 model{p_end}
{synopt:{cmd:e(deviance_1)}}deviance, stage 1 model{p_end}
{synopt:{cmd:e(deviance_2)}}deviance, stage 2 model{p_end}
{synopt:{cmd:e(deviance_3)}}deviance, stage 3 model{p_end}
{synopt:{cmd:e(iterations)}}number of iterations{p_end}
{synopt:{cmd:e(iterations_1)}}number of iterations, stage 1 model{p_end}
{synopt:{cmd:e(iterations_2)}}number of iterations, stage 2 model{p_end}
{synopt:{cmd:e(iterations_3)}}number of iterations, stage 3 model{p_end}
{synopt:{cmd:e(time)}}estimation time (seconds){p_end}
{synopt:{cmd:e(chi2_1vs2)}}chi-squared, stage 1 model vs. stage 2 model{p_end}
{synopt:{cmd:e(chi2_1vs3)}}chi-squared, stage 1 model vs. stage 3 model{p_end}
{synopt:{cmd:e(chi2_2vs3)}}chi-squared, stage 2 model vs. stage 3 model{p_end}
{synopt:{cmd:e(p_1vs2)}}p-value, stage 1 model vs. stage 2 model{p_end}
{synopt:{cmd:e(p_1vs3)}}p-value, stage 1 model vs. stage 3 model{p_end}
{synopt:{cmd:e(p_2vs3)}}p-value, stage 2 model vs. stage 3 model{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}runmixregmls{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivar)}}variable denoting groups{p_end}
{synopt:{cmd:e(adapt)}}adaptive Gaussian quadrature {p_end}
{synopt:{cmd:e(n_quad)}}number of integration points{p_end}
{synopt:{cmd:e(iterate)}}maximum number of iterations{p_end}
{synopt:{cmd:e(tolerance)}}tolerance{p_end}
{synopt:{cmd:e(ridgein)}}initial ridge{p_end}
{synopt:{cmd:e(standardize)}}standardized variables{p_end}
{synopt:{cmd:e(properties)}}b V{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(b_1)}}coefficient vector, stage 1 model{p_end}
{synopt:{cmd:e(b_2)}}coefficient vector, stage 2 model{p_end}
{synopt:{cmd:e(b_3)}}coefficient vector, stage 3 model{p_end}
{synopt:{cmd:e(V_1)}}variance-covariance matrix of the estimators, stage 1 model{p_end}
{synopt:{cmd:e(V_2)}}variance-covariance matrix of the estimators, stage 2 model{p_end}
{synopt:{cmd:e(V_3)}}variance-covariance matrix of the estimators, stage 3 model{p_end}

{synoptset 19 tabbed}{...}
{p2col 5 19 23 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{marker authors}{...}
{title:Authors}

{p 4}George Leckie{p_end}
{p 4}Centre for Multilevel Modelling{p_end}
{p 4}University of Bristol{p_end}
{p 4}{browse "mailto:g.leckie@bristol.ac.uk":g.leckie@bristol.ac.uk}{p_end}
{p 4}{browse "http://www.bristol.ac.uk/cmm/team/leckie.html":http://www.bristol.ac.uk/cmm/team/leckie.html}{p_end}

{p 4}Chris Charlton{p_end}
{p 4}Centre for Multilevel Modelling{p_end}
{p 4}University of Bristol{p_end}

{marker disclaimer}{...}
{title:Disclaimer}

{pstd}{cmd:runmixregmls} comes with no warranty.


{marker references}{...}
{title:References}

{marker HN2013}{...}
{phang}
Hedeker, D. R. and Nordgren. 2013. 
MIXREGLS: A Program for Mixed-effects Location Scale Analysis.
{it:Journal of Statistical Software}, 52, 12, 1-38.
URL: {browse "http://www.jstatsoft.org/v52/i12":http://www.jstatsoft.org/v52/i12}.

{title:Also see}

{psee}
Manual:  {bf:[XT] xtreg} {bf:[ME] mixed} {bf:[ME] menl} 

{psee}
Online:  {manhelp xtreg XT}, {manhelp mixed ME}, {manhelp menl ME}, {bf:{help runmixregls}}, {bf:{help runmlwin}}, {bf:{help gllamm}}
{p_end}
