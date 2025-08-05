{smcl}
{* *! version 0.9.3 04aug2025}{...}
{hi:psr} {hline 2} Propensity score residual regression for overlap-weight average treatment effect

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt psr}
{depvar}
{it:treatment_var covariates} {ifin}
[{cmd:,} {it:options}]

{p 8 16 2}
{cmd:psr}
{depvar}
{cmd:(}
{it:treatment_var}
{cmd:=}
{it:instrument}
{cmd:)}
{it:covariates} {ifin}
[{cmd:,} {it:options}]

{synoptset 12 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt l:ogit}}specifies to use logit instead of probit for
propensity/instrument score regression.{p_end}
{synopt :{opt ord:er(#)}}specifies the maximum polynomial order q for
predicting the dependent variable by the fitted linear index or the
fitted probability. The default value is {cmd:2}.{p_end}
{synopt :{opt usep:rob}}uses the fitted probability for the prediction
of the dependent variable instead of fitted linear index. The linear
index is used, if this option is not called for.{p_end}

{syntab:Reporting}
{synopt :{opt aux:iliary}}reports results from auxiliary regression
for covariate slopes with the standard errors.{p_end}
{synopt :{opt v:erbose}}displays all intermediate step results.{p_end}
{synopt :{opt vv:erbose}}is the same as {cmd:auxiliary} and
{cmd:verbose} options used together.{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:psr} implements OLS with propensity score residual and IV
regression with instrument score residual. The first syntax fits OLS
and the second the IV regression. The covariates should be exogenous
always.

{title:Examples}

{pstd}OLS with propensity score residuals{p_end}
{phang2}{cmd:. {stata use flu, clear}}{p_end}
{phang2}{cmd:. {stata psr outcome receive age female white copd heartd renal}}{p_end}
{phang2}{cmd:. {stata psr outcome receive age female white copd heartd renal, order(3)}}{p_end}
{phang2}{cmd:. {stata psr outcome receive age female white copd heartd renal, logit}}{p_end}
{phang2}{cmd:. {stata psr outcome receive age female white copd heartd renal, aux}}{p_end}
{phang2}{cmd:. {stata psr outcome receive age female white copd heartd renal, v}}{p_end}
{phang2}{cmd:. {stata psr outcome receive age female white copd heartd renal, vv}}{p_end}

{pstd}IV regression with instrument score residuals{p_end}
{phang2}{cmd:. {stata use nlsdat, clear}}{p_end}
{phang2}{cmd:. {stata gen d = ed76 > 12}}{p_end}
{phang2}{cmd:. {stata global X0 age76 black reg662-reg669 smsa66r}}{p_end}
{phang2}{cmd:. {stata global X1 ${X0} smsa76r reg76r}}{p_end}
{phang2}{cmd:. {stata psr lwage76 (d = nearc4) ${X1}, vv}}{p_end}
{phang2}{cmd:. {stata psr lwage76 (d = nearc4) ${X0}, vv}}{p_end}

{title:Stored results}

{cmd:psr} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(q)}}polynomial order for outcome prediction{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector (average treatment effect){p_end}
{synopt:{cmd:e(V)}}variance of the estimator{p_end}
{synopt:{cmd:e(b_bin)}}coefficient vector from probit/logit regression{p_end}
{synopt:{cmd:e(V_bin)}}variance-covariance matrix of the estimators from probit/logit regression{p_end}
{synopt:{cmd:e(b_aux)}}coefficient vector from auxiliary regression{p_end}
{synopt:{cmd:e(b_aux)}}variance-covariance matrix from auxiliary regression{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:psr}{p_end}
{synopt:{cmd:e(depvar)}}name of output variable{p_end}
{synopt:{cmd:e(model)}}{cmd:ols} or {cmd:iv}{p_end}
{synopt:{cmd:e(pscmd)}}binary model classifier ({cmd:probit} or {cmd:logit}){p_end}
{synopt:{cmd:e(predictor)}}{cmd:xb} or {cmd:pr}{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
Chirok Han{break}
Department of Economics{break}
Korea University{break}
Seoul, Republic of Korea{break}
chirokhan@korea.ac.kr

{pstd}
Myoung-jae Lee{break}
Department of Economics{break}
Korea University{break}
Seoul, Republic of Korea{break}
myoungjae@korea.ac.kr

{marker references}{...}
{title:References}

{marker Lee2018}{...}
{phang}
Lee, M. J. 2018.
Simple least squares estimator for treatment effects using propensity
score residuals. {it:Biometrika} 105: 149-164.
{p_end}

{marker Lee2021}{...}
{phang}
Lee, M. J. 2021.
Instrument residual estimator for any response variable with endogenous
binary treatment.
{it:Journal of the Royal Statistical Society (Series B)} 83(3): 612-635.
