{smcl}
{* *! version 1.0.5 Stephen P. Jenkins & Fernando Rios-Avila April 2026}{...}
{viewerjumpto "Syntax" "bimpoisson_postestimation##syntax"}{...}
{viewerjumpto "Description" "bimpoisson_postestimation##des_predict"}{...}
{viewerjumpto "Predict" "bimpoisson_postestimation##predict"}{...}
{viewerjumpto "Examples" "bimpoisson_postestimation##examples"}{...}
{viewerjumpto "Authors" "bimpoisson_postestimation##authors"}{...}
{viewerjumpto "References" "bimpoisson_postestimation##references"}{...}
{viewerjumpto "Also see" "bimpoisson_postestimation##alsosee"}{...}

{title:Bivariate mixed Poisson regression, post-estimation}

{phang}
{cmd:bimpoisson postestimation} {hline 2} Postestimation tools for bimpoisson{p_end}

{marker description}{...}
{title:Postestimation commands}

{pstd}
The following postestimation commands are available after {cmd:bimpoisson}:

{synoptset 17 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :{helpb bimpoisson postestimation##predict:predict}}predictions{p_end}
{synoptline}
{p2colreset}{...}

{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} 
{dtype}
{newvar} 
{ifin}
[{cmd:,} {it:statistic} {opt nooff:set}] [{it:{help options}}]

{synoptset 12}{...}
{synopthdr :statistic}
{synoptline}
{synopt :{opt xb1}}linear prediction for equation 1{p_end}
{synopt :{opt xb2}}linear prediction for equation 2{p_end}
{synopt :{opt stdp1}}standard error of the linear prediction for equation 1{p_end}
{synopt :{opt stdp2}}standard error of the linear prediction for equation 2{p_end}
{synopt :{opt n1}}count prediction for equation 1{p_end}
{synopt :{opt n2}}count prediction for equation 2{p_end}
{synopt :{opt pr1(#)}}predicted prob(outcome 1 = #); # is integer-valued{p_end}
{synopt :{opt pr2(#)}}predicted prob(outcome 2 = #); # is integer-valued{p_end}
{synopt :{opt pr12(#1 #2)}}predicted prob(outcome 1 = #1, outcome 2 = #2); 
#1, #2 are integer-valued{p_end}
{synoptline}
{p2colreset}{...}
INCLUDE help esample
{pstd}
Note: pr1, pr2, and pr12, are derived by simulation; the options below are 
relevant in this case.

{synoptset 12}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt nsim(#)}}sets number of simulations used to calculate predicted 
probabilities{p_end}
{synopt :{opt seed(#)}}sets the random seed used when calculating predicted 
probabilities. (If not set, defaults to current rng state.){p_end}
{synoptline}

{marker des_predict}{...}
{title:Description for predict}

{pstd}
{cmd:predict} creates a new variable containing predictions such as counts, 
linear predictions, and predicted probabilities. 

{pstd}
For each observation, and outcome equation {it:j} = 1, 2, the linear prediction
is {it:x}j'{it:b}j, where {it:x}j and {it:b}j are vectors of explanatory 
variables (including a constant term) and estimated coefficients, respectively.

{pstd}
The predicted count for outcome {it:j} is 

{center:lambda_{it:j} = E({it:yj}|{it:x}j) = exp({it:x}j'{it:b}j + ({it:sigma_j}^2)/2})

{pstd}
where sigma_{it:j} is the estimated standard deviation of the normal mixture 
distribution for outcome equation {it:j}. Thus the predicted count is the 
marginal predicted derived by integrating out the random effect. The 
lambda_{it:j} can be used to calculate marginal effects: see Jumamyradov 
and Munkin (2025, p. 67).

{pstd}
The formulae for the predicted probabilities are taken from Munkin and Trivedi 
(1999, pp. 43 and 46). Predicted probabilities are calculated by simulation using
uniform pseudorandom draws from normal distributions. For a univariate count 
probability, the normal distribution has mean zero and standard deviation 
set equal to the fitted standard deviation. For a joint count probability, the
normal distribution has mean zero and standard deviations set equal to the 
fitted standard deviations and correlation equal to the fitted correlation.

{marker options_predict}{...}
{title:Options for predict}

{phang}
{opt xb1} calculates the linear prediction for equation 1. Use exp(xb1_hat) to 
calculate mean conditional on a random effect.

{phang}
{opt xb2} calculates the linear prediction for equation 2. Use exp(xb2_hat) to 
calculate mean conditional on a random effect.

{phang}
{opt stdp1} calculates the standard error of the linear prediction of
equation 1

{phang}
{opt stdp2} calculates the standard error of the linear prediction of
equation 2

{phang}
{opt n1} calculates the predicted count for equation 1 (with random effect 
integrated out)

{phang}
{opt n2} calculates the predicted count for equation 2 (with random effect 
integrated out)

{phang}
{opt pr1(#)} calculates the predicted prob(outcome 1 = #) using simulation

{phang}
{opt pr2(#)} calculates the predicted prob(outcome 2 = #) using simulation

{phang}
{opt pr12(#1 #2)} calculates the predicted prob(outcome 1 = #1, outcome 2 = #2) 
using simulation

{phang}
{opt nsim(#)} sets the number of simulations used to calculate predicted 
probabilities (default # = 100)

{phang}
{opt seed(#)} sets the seed (affects calculations of predicted probabilities). 
If not set, defaults to current rng state.

{phang}
{opt nooffset} is relevant only if you specified {opth offset1(varname)} or
{opt offset2(varname)} for {cmd:bimpoisson}.  It modifies the calculations made
by {opt predict} so that they ignore the offset variables; the linear
predictions are treated as xb rather than as xb + offset1 and z_[gamma] rather
than as z_[gamma] + offset2.

{marker examples}{...}
{title:Examples}

{p 4 8 2}{cmd: * Setup (see also {help bimpoisson} Examples)}

{p 4 8 2}{cmd: use "rwm1984.dta", clear}

{p 4 8 2}{cmd: correlate docvis hospvis}

{p 4 8 2}{cmd: generate byte postHS = edlevel1 == 0}

{p 4 8 2}{cmd: generate byte MarM = (married == 1 & female == 0)}

{p 4 8 2}{cmd: generate byte MarF = (married == 1 & female == 1)}

{p 4 8 2}{cmd: generate byte SinM = (married == 0 & female == 0)}

{p 4 8 2}{cmd: generate byte SinF = (married == 0 & female == 1)}

{p 4 8 2}{cmd: global xvars MarM SinM SinF kids outwork postHS}

{p 4 8 2}{cmd: * Fit model in stages}

{p 4 8 2}{cmd: bimpoisson (docvis = ) ( hospvis = ), seed(111) }

{p 4 8 2}{cmd: matrix b0 = e(b)}

{p 4 8 2}{cmd: bimpoisson (docvis = $xvars) ( hospvis = $xvars), ///}

{p 8 8 2}{cmd: seed(4321) from(b0) nsim(250) antithetic bias rho_sf(`e(rho)')}

{p 4 8 2}{cmd: * Get predictions}

{p 4 8 2}{cmd: predict xb1, xb1}

{p 4 8 2}{cmd: predict xb2, xb2}

{p 4 8 2}{cmd: predict n1, n1}

{p 4 8 2}{cmd: predict n2, n2}

{p 4 8 2}{cmd: predict pr10, pr1(0) // Pr(outcome 1 = 0)}

{p 4 8 2}{cmd: predict pr20, pr2(0) // Pr(outcome 2 = 0)}

{p 4 8 2}{cmd: predict pr11, pr1(1) // Pr(outcome 1 = 1)}

{p 4 8 2}{cmd: predict pr21, pr2(1) // Pr(outcome 2 = 1)}

{p 4 8 2}{cmd: predict pr12, pr1(2) // Pr(outcome 1 = 2)}

{p 4 8 2}{cmd: predict pr22, pr2(2) // Pr(outcome 2 = 2)}

{p 4 8 2}{cmd: predict pr12_00, pr12(0 0) // Pr(outcome 1 = 0 & outcome 2 = 0)}

{p 4 8 2}{cmd: predict pr12_21, pr12(2 1) // Pr(outcome 1 = 2 & outcome 2 = 1)}

{marker authors}{...}
{title:Authors}
{p}

{p 4 4 2}Stephen P. Jenkins <s.jenkins@lse.ac.uk>{break}
London School of Economics and Political Science (LSE)

{p 4 4 2}Fernando Rios-Avila <f.rios.a@gmail.com>{break}
London School of Economics and Political Science (LSE)

{marker references}{...}
{title:References}

{p 4 8 2} 
Jumamyradov, M. and Munkin, M. K. 2022. Biases in maximum simulated 
likelihood estimation of bivariate models. {it:Journal of Econometric Methods} 
11, 55{c -}70. {browse "https://doi.org/10.1515/jem-2021-0003"}

{p 4 8 2}
Munkin, M. K. and Trivedi, P. K. 1999. Simulated maximum likelihood estimation 
of multivariate mixed-Poisson regression  models, with application. 
{it:The Econometrics Journal} 2, 29{c -}48.
{browse "https://doi.org/10.1111/1368-423X.00019"}

{title:Also see}

{p 7 14 2}Help:  {help bimpoisson} (if installed){p_end}
