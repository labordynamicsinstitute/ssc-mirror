{smcl}
{* July 2022}{...}
{title:Title}

{p 4 4 2}
{bf:predict} —— Obtain fitted values, residuals, time-varying coefficients and impulse responses after {cmd:tvpreg}.

{title:Syntax}

{p 8 15 2} {cmd:predict} {helpb newvarlist}
[{cmd:,} {opt xb} {opt residual} {opth y(varlist)} {opth h(#)} {opt coef(namelist)} {opt coefub(namelist)} {opt coeflb(namelist)} {opt varirf(namelist)} {opt varirfub(namelist)} {opt varirflb(namelist)}]
{p_end}

{p 4 4 2} where the options {cmd:xb}, {cmd:residual}, {opt coef(namelist)}, {opt coefub(namelist)}, {opt coeflb(namelist)}, {opt varirf(namelist)}, {opt varirfub(namelist)}, and {opt varirflb(namelist)} are mutually exclusive.

{p 4 4 2} The number of variables specified in {helpb newvarlist} should be equal to the number of variables specified in {opth y(varlist)}
or the number of parameter names specified in {opt coef(namelist)}, {opt coefub(namelist)}, {opt coeflb(namelist)}, {opt varirf(namelist)}, {opt varirfub(namelist)}, or {opt varirflb(namelist)}.

{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt xb}}specifies that the fitted value is stored.
This is the default when no option is specified.{p_end}
{synopt :{opt residual}}specifies that the residual is stored.{p_end}
{synopt :{opth y(varlist)}}specifies the dependent (instrumented) variables whose (first-stage) fitted value or residual is stored.
The default is the first dependent variable.
this option only applies when option {cmd:xb} or {cmd:residual} is specified.{p_end}
{synopt :{opth h(#)}}specifies the number of horizon used in two cases:
(1) for local projection, when {cmd:xb}, {cmd:residual}, {opt coef(namelist)}, {opt coefub(namelist)}, or {opt coeflb(namelist)} is specified, and
(2) for the vector autoregressive model, when {opt varirf(namelist)}, {opt varirfub(namelist)}, or {opt varirflb(namelist)} is specified.
The default is the smallest number of horizon specified by the {opth nhorizon(numlist)} option in the {cmd:tvpreg} estimation.{p_end}
{synopt :{opt coef(namelist)}}specifies the parameter name (list) whose time-varying-parameter estimate is stored as new variables.
The parameter name is stored in {cmd:e(coefname)}.
To store the slope parameters, {it:namelist} is specified by {it:"yvar1:xvar1 yvar2:xvar2 ..."} and locates the parameter to be stored.
These parameters correspond to the coefficients of the variables {it:xvar#} in the equations for {it:yvar#}.
To store the covariance matrix parameters when {cmd:cholesky} is specified,
{it:namelist} is
specified by {it:"aij ... li ..."},
where {it:aij} denotes the {it:i}-th row and {it:j}-th column element in {it:A(t)},
{it:li} denotes the {it:i}-th element in {it:lnσ(t)};
{it:A(t)Σ(e,t)A(t)' = Σ(ε,t)Σ(ε,t)'}; {it:σ(t)=diag(Σ(ε,t))};
{it:A(t)} is a lower-triangular matrix with ones on the main diagonal;
{it:Σ(e,t)} is the covariance matrix; and {it:i > j}.
To store the convariance matrix parameters when {cmd:cholesky} is not specified,
{it:namelist} is specified by {it:"vij ..."},
where {it:vij} denotes the {it:i}-th row and {it:j}-th column element in the covariance matrix {it:Σ(e,t)},
and {it:i ≥ j}.{p_end}
{synopt :{opt coefub(namelist)}}specifies the parameter name (list) whose upper bound of the time-varying-parameter estimate is stored as new variables.
The format of {it:namelist} is the same as the one in option {opt coef(namelist)}.{p_end}
{synopt :{opt coeflb(namelist)}}specifies the parameter name (list) whose lower bound of the time-varying-parameter estimate is stored as new variables.
The format of {it:namelist} is the same as the one in option {opt coef(namelist)}.{p_end}
{synopt :{opt varirf(namelist)}}specifies the parameter name (list) whose time-varying-parameter vector autoregression impulse responses is stored as new variables.
The parameter name is stored in {cmd:e(varirfname)}.
{it:namelist} is specified as {it:"var1:shock1 var2:shock2 ..."} and locates the impulse response to be stored, 
where {it:var} ({it:shock}) is the variable (shock) of interest.
This option only applies when the {it:estimator} option is {cmd:var}.{p_end}
{synopt :{opt varirfub(namelist)}}specifies the parameter name (list) whose upper bound of the time-varying-parameter vector autoregression impulse responses is stored as new variables.
The format of {it:namelist} is the same as the one in option {opt varirf(namelist)}.{p_end}
{synopt :{opt varirflb(namelist)}}specifies the parameter name (list) whose lower bound of the time-varying-parameter vector autoregression impulse responses is stored as new variables.
The format of {it:namelist} is the same as the one in option {opt varirf(namelist)}.{p_end}
{synoptline}
