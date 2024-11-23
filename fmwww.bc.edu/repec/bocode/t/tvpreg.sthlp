{smcl}
{* July 2022}{...}
{title:Title}

{p 4 4 2}
{bf:tvpreg} —— Parameter path estimation in unstable environments

{title:Syntax}

{p 8 15 2} {cmd:tvpreg} {it:{help varlist:varlist_dep}} {it:{help varlist:varlist1}}
{cmd:(}{it:{help varlist:varlist2}} {cmd:=}
{it:{help varlist:varlist_iv}}{cmd:)}
{ifin} [{cmd:,} {help tvpreg##options:options}] 
{p_end}

{phang}
{it:varlist_dep} denotes the list of dependent variables.{p_end}
{phang}
{it:varlist1} denotes the list of exogenous variables.{p_end}
{phang}
{it:varlist2} denotes the list of endogenous variables.{p_end}
{phang}
{it:varlist_iv} denotes the list of exogenous variables used with {it:varlist1} as instruments for {it:varlist2}.

{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Estimator}
{synopt: {opt ols}}ordinary least squares (OLS); the default when no insturment is specified.{p_end}
{synopt: {opt newey}}applies Newey-West HAC estimation to the long-run variance of scores.{p_end}
{synopt: {opt 2sls}}two-stage least squares (2SLS); the default when instruments are specified.{p_end}
{synopt: {opt gmm}}generalized method of moments (GMM).{p_end}
{synopt: {opt weakiv}}indicates the weak-instrument environment and use OLS for the reduced-from regression.{p_end}
{synopt: {opt var}}indicates the vector autoregressive (VAR) environment.{p_end}

{syntab:Model}
{synopt :{opt c:matrix(matname)}}specifies the {it:C} grid for {it:c(i)}.
This option controls the magnitude of time variation allowed in the parameters: larger {it:c(i)} values allow for larger magnitude of time variation.
The default is a scalar {it:c(i)} with the {it:C} grid 0:5:50. 
We allow {it:c(i)} to be either a scalar or a vector: a vector {it:c(i)} allows different magnitudes of time-variation in different subsets of the parameters.
When {it:c(i)} is a scalar, {it:C} is a row vector;
when {it:c(i)} is a vector, {it:C} is a matrix whose number of rows should equal the number of
parameters, {it:q}.
Note that an excessively large value of {it:c(i)} may cause the calculation to exceed the maximum representable value in precision, in which case the intermediate step of weight computation returns {it:Inf}, which ultimately leads to a quasi-posterior value of {it:NaN}.
{p_end}
{synopt :{opth nhor:izon(numlist)}}specifies the number list of horizons in the local projection or the vector autoregressive model.
The default is {cmd:nhorizon(0)}.{p_end}
{synopt :{opt lplag:ged}}specifies that in the TVP-LP or TVP-LP-IV models, the endogenous variables are lagged and held at their current-period value across horizons, while the dependent variable is the {it:h}-step-ahead future value.
This option only applies when the {it:estimator} option is {cmd:2sls}, {cmd:gmm}, or {cmd:weakiv}.{p_end}
{synopt :{opt cum:ulative}}indicates that the dependent variables and endogenous variables are cumulated over horizons.
If the {cmd:lplagged} option is specified, then the endogenous variables are not cumulated.
{p_end}
{synopt :{opt slope}}imposes that only the slope parameters are time-varying.{p_end}
{synopt :{opt chol:esky}}indicates that the logarithm of the standard deviation is considered in the parameter path for univariate regressions,
or that the triangular reduction of the covariance matrix is implemented for multivariate regressions.{p_end}
{synopt :{opth nwl:ag(#)}}specifies the number of lags to calculate the long run variance {it:Vhat} of the scores.
The default is {cmd:nwlag(0)} for {it:estimator} option being {cmd:ols} or {cmd:var},
and {cmd:nwlag(T^(1/3))} for other {it:estimator} options,
where {it:T} is the total sample size.
For instance, if no {it:estimator} option is set and {cmd:nwlag(8)} is specified, {cmd:ols} will be used to obtain the constant parameter estimate for evaluating scores and Hessians, with 8 lags applied to calculate the long-run variance of the scores.
{p_end}
{synopt :{opt nocons:tant}}suppresses the constant term.{p_end}
{synopt :{opth ny(#)}}specifies the number of dependent variables.
The default is {cmd:ny(1)}.
This option does not apply when the {it:estimator} option is {cmd:var}{p_end}
{synopt :{opth varlag(numlist)}}specifies the number of lags in the vector autoregressive model. 
The default is {cmd:varlag(1)}.
This option only applies when the {it:estimator} option is {cmd:var}.{p_end}
{synopt :{opth ndraw(#)}}specifies the number of draws used to simulate the confidence band in the precense of weak instruments
or for the impulse responses computed by iterating the VAR. 
The default is {cmd:ndraw(1000)}.
This option only applies when the {it:estimator} option is {cmd:weakiv} or {cmd:var}.
To fix the estimation results, use {helpb set seed}. For example, {cmd: set seed 1234}.{p_end}

{syntab:Reporting}
{synopt :{opt getb:and}}generates the confidence bands.{p_end}
{synopt :{opth level(clevel)}}sets the confidence level.
The default is {cmd:level(95)}.{p_end}
{synopt :{opt nodis:play}}suppresses the text output.{p_end}

{syntab:Plotting}
{synopt :{opt plotcoef(namelist)}}specifies the parameter name (list) to be plotted.
The parameter name is stored in {cmd:e(coefname)}.
To plot the slope parameters, {it:namelist} is specified by {it:"yvar1:xvar1 yvar2:xvar2 ..."} and locates the parameter to be plotted.
These parameters correspond to the coefficients of the variables {it:xvar#} in the equations for {it:yvar#}.
To plot the covariance matrix parameters when {cmd:cholesky} is specified,
{it:namelist} is
specified by {it:"aij ... li ..."},
where {it:aij} denotes the {it:i}-th row and {it:j}-th column element in {it:A(t)},
{it:li} denotes the {it:i}-th element in {it:lnσ(t)};
{it:A(t)Σ(e,t)A(t)' = Σ(ε,t)Σ(ε,t)'}; {it:σ(t)=diag(Σ(ε,t))};
{it:A(t)} is a lower-triangular matrix with ones on the main diagonal;
{it:Σ(e,t)} is the covariance matrix; and {it:i > j}.
To plot the convariance matrix parameters when {cmd:cholesky} is not specified,
{it:namelist} is specified by {it:"vij ..."},
where {it:vij} denotes the {it:i}-th row and {it:j}-th column element in the covariance matrix {it:Σ(e,t)},
and {it:i ≥ j}.{p_end}
{synopt :{opt plotvarirf(namelist)}}specifies the parameter name (list) of the time-varying parameter vector autoregression impulse responses to be plotted.
The parameter name is stored in {cmd:e(varirfname)}.
{it:namelist} is specified as {it:"var1:shock1 var2:shock2 ..."} and locates the impulse response to be plotted, 
where {it:var} ({it:shock}) is the variable (shock) of interest.
This option only applies when the {it:estimator} option is {cmd:var}.
{opt plotcoef(namelist)} and {opt plotvarirf(namelist)} cannot be specified together.{p_end}
{synopt :{opth plotnhor:izon(numlist)}}specifies the number (list) of horizons to be plotted.
This list must be a subset of the number list in {opth nhorizon(numlist)}.
The command plots the parameter path over time (horizons)
when {opth plotnhorizon(numlist)} specifies a single number (or a list of numbers).
The default is the list specified by {opth nhorizon(numlist)}.{p_end}
{synopt :{opt plotc:onst}}includes the constant parameter estimate (a line in the graph).
This option does not apply when the {it:estimator} option is {cmd:weakiv}.{p_end}
{synopt :{opth period(varname)}}specifies the dummy variable indicating the time points to be highlighted in the plots.
when {opth plotnhorizon(numlist)} specifies a list of numbers, this option indicates the specific time points to be plotted in the parameter paths across horizons.
When {opth plotnhorizon(numlist)} specifies a single number, this option adds a background shade in the graph at the selected time points of the parameter path.{p_end}
{synopt :{opth movavg(#)}}specifies the degree of the moving average when ploting a (smoothed) parameter path.
The default is {cmd:movavg(1)}.{p_end}
{synopt :{opt noci}}suppresses the confidence band in the figures.
The confidence band is only computed and stored when {cmd:getband} is specified.{p_end}
{synopt :{opt ti:tle(tinfo)}}specifies the graph title.
The default is the parameter name.{p_end}
{synopt :{opt yti:tle(axis_title)}}specifies y-axis title.
The default is "Parameter."{p_end}
{synopt :{opt xti:tle(axis_title)}}specifies x-axis title
The default is "Time" ("Horizons") for parameter path across time (horizons).{p_end}
{synopt :{opt tvpl:egend(string)}}specifies the legend for the time-varying-parameter estimate.
The default is "Time-varying parameter."{p_end}
{synopt :{opt constl:egend(string)}}specifies the legend for the constant-parameter estimate.
The default is "Constant parameter."
This option may be specified only when {opt plotconst} is specified.{p_end}
{synopt :{opt bandl:egend(string)}}specifies the legend name for the confidence band.
The default is "95% confidence band."
This option may be specified only when {opt getband} is specified and {opt noci} is not specified.{p_end}
{synopt :{opt shadel:egend(string)}}specifies the legend for the background shade.
The default is the variable name specified by {opth period(varname)}.
This option may be specified only when {opth period(varname)} is specified and a single number is specified by {opth plotnhorizon(numlist)}.{p_end}
{synopt :{opt periodl:egend(namelist)}}specifies the legend for the time-varying estimates in different time periods;
{it:namelist} is specified by {it:"periodname1,periodname2,..."}, where the order of names should match the increasing order of time periods.
If this option is not specified, all the time-varying estimates have the same legend specified by {opt tvpl:egend(string)}.
This option may be specified only when a list of numbers is specified by {opth plotnhorizon(numlist)}.
{p_end}
{synopt :{opt nolegend}}suppresses the legend.
The legend is displayed only when more than two of the above elements are plotted in the figure.{p_end}
{synopt :{opth sch:eme(schemename)}}specifies the overall look of the graph.
The default is controled by {opt set scheme}.{p_end}
{synopt :{opth tvpc:olor(colorstyle)}}specifies the color of the time-varying-parameter estimate.
The default is {cmd:tvpcolor(green)}.{p_end}
{synopt :{opth constc:olor(colorstyle)}}specifies the color of the constant-parameter estimate.
The default is {cmd:constcolor(black)}.{p_end}
{synopt :{opth name(name_option)}}specifies the graph name.
The default is "tvpreg."{p_end}
{synoptline}
{p 4 6 2} {it:estimator} specifies the estimation method for the constant parameter estimate which is used to evaluate the scores and Hessians.
The command allows to specify at most one estimator.{p_end}
{phang2}. {cmd:ols} or {cmd:newey} estimates the linear regression or local projection.
The syntax is analogous to Stata command {cmd:regress} and {cmd:newey}:
{cmd:tvpreg} {it:{help varlist:varlist_dep}} {it:{help varlist:varlist1}}
{ifin} [{cmd:,} {cmd:ols/newey} {help tvpreg##options:options}]{p_end}
{phang2}. {cmd:2sls}, {cmd:gmm} and {cmd:weakiv} are designed for instrument variable estimation.
The syntax is analogous to Stata command {cmd:ivreg2}:
{cmd:tvpreg} {it:{help varlist:varlist_dep}} [{it:{help varlist:varlist1}}]
{cmd:(}{it:{help varlist:varlist2}} {cmd:=}
{it:{help varlist:varlist_iv}}{cmd:)}
{ifin} [{cmd:,} {cmd:2sls/gmm/weakiv} {help tvpreg##options:options}] {p_end}
{phang2}. {cmd:var} estimates vector autoregregressive models.
The syntax is analogous to Stata command {cmd:var}
{cmd:tvpreg} {it:{help varlist:varlist_dep}}
{ifin} [{cmd:,} {cmd:var} {help tvpreg##options:options}] {p_end}


{title:Description}

{p 4 4 2}{cmd:tvpreg} facilitates practitioners to estimate and visualize the parameter path and impulse response functions in unstable environments.
{help tvpreg##storedresults:Estimation results} are stored in {cmd:e()} form.
{help tvpreg##postestimation:Postestimation commands} are provided to store and visualize the estimation results. 
{p_end}


{marker postestimation}{...}
{title:Postestimation commands}

{p 4 4 2}The following postestimation commands are available after {cmd:tvpreg}.

{synoptset 17}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :{helpb tvpreg_p:predict}}obtains fitted values, residuals, time-varying coefficients and impulse responses{p_end}
{synopt :{helpb tvpplot}}visualizes the time-varying coefficients and impulse responses{p_end}
{synoptline}

{p 4 4 2}The syntaxes for {cmd:predict} and {cmd:tvpplot} are listed as follows:

{p 8 15 2} {cmd:predict} {helpb newvarlist}
[{cmd:,} {opt xb} {opt residual} {opth y(varlist)} {opth h(#)} {opt coef(namelist)} {opt coefub(namelist)} {opt coeflb(namelist)} {opt varirf(namelist)} {opt varirfub(namelist)} {opt varirflb(namelist)}]
{p_end}

{p 4 4 2}Detailed description of the above options is in {helpb tvpreg_p:predict}.

{p 8 15 2} {cmd:tvpplot} [{cmd:,} {opt plotcoef(namelist)} {opt plotvarirf(namelist)} {opth hor:izon(numlist)} {opt plotc:onst} {opth period(varname)} {opth movavg(#)}
{cmd:noci} {opt ti:tle(tinfo)} {opt yti:tle(axis_title)} {opt xti:tle(axis_title)} {opth name(name_option)}
{opt tvpl:egend(string)} {opt constl:egend(string)} {opt bandl:egend(string)} {opt shadel:egend(string)} {opt periodl:egend(namelist)} {opth sch:eme(schemename)} {opth tvpc:olor(colorstyle)} {opth constc:olor(colorstyle)} {opt nolegend}] 
{p_end}

{p 4 4 2}The options for {cmd:tvpplot} are the same as {cmd:tvpreg}. {opt plotcoef(namelist)} or {opt plotvarirf(namelist)} should be specified to locate the parameter.


{marker examples}{...}
{title:Examples}

{p 4 4 2}Please refer to Inoue et al. (2024) for detailed examples.
Table 1 therein provides a summary of commonly used specifications and their corresponding commands to assist users in selecting the appropriate options.
Table 2 provides a summary of the impelmentation examples, including TVP-VAR, TVP-LP, TVP-LP-IV, and TVP-weak IV.{p_end}


{marker storedresults}{...}
{title:Stored results}

{pstd}{cmd:tvpreg} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(T)}}sample size{p_end}
{synopt:{cmd:e(q)}}number of time varying parameters{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(title)}}{opt Time-Varying-Parameter Estimation}{p_end}
{synopt:{cmd:e(cmd)}}{opt tvpreg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(model)}}estimator type{p_end}
{synopt:{cmd:e(coefname)}}parameter name of the model{p_end}
{synopt:{cmd:e(varirfname)}}parameter name of the TVP-VAR impulse response functions{p_end}
{synopt:{cmd:e(horizon)}}number (list) of horizons{p_end}
{synopt:{cmd:e(cumulative)}}"yes" if the variables are cumulated; "no" otherwise{p_end}
{synopt:{cmd:e(lplagged)}}"yes" if endogenous variables do not vary across horizons; "no" otherwise{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvar)}}name of independent variables{p_end}
{synopt:{cmd:e(instd)}}name of instrumented variables{p_end}
{synopt:{cmd:e(insts)}}name of instruments{p_end}
{synopt:{cmd:e(inexog)}}name of included instruments{p_end}
{synopt:{cmd:e(exexog)}}name of excluded instruments{p_end}
{synopt:{cmd:e(varlags)}}number list of lags in TVP-VAR{p_end}
{synopt:{cmd:e(maxl)}}maximum lag in TVP-VAR{p_end}
{synopt:{cmd:e(constant)}}"yes" if constant is included; "no" otherwise{p_end}
{synopt:{cmd:e(band)}}"yes" if confidence band is obtained; "no" otherwise{p_end}
{synopt:{cmd:e(cholesky)}}"yes" if triangular reduction of the coveriance matrix is implemented; "no" otherwise{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(c)}}input {it:C} grid matrix{p_end}
{synopt:{cmd:e(qLL)}}qLL test statistic if a default {it:C} grid is specified by {cmd:cmatrix(matname)}{p_end}
{synopt:{cmd:e(weight)}}weights associated with the path for each {it:c(i)} in {it:C} grid{p_end}
{synopt:{cmd:e(coef_const)}}constant parameter estimate{p_end}
{synopt:{cmd:e(coef)}}parameter path{p_end}
{synopt:{cmd:e(coef_lb)}}lower bound of the parameter path{p_end}
{synopt:{cmd:e(coef_ub)}}upper bound of the parameter path{p_end}
{synopt:{cmd:e(Omega)}}covariance matrix of the parameter path{p_end}
{synopt:{cmd:e(varirf_const)}}constant parameter estimate of VAR impulse response function{p_end}
{synopt:{cmd:e(varirf)}}TVP-VAR impulse response function path{p_end}
{synopt:{cmd:e(varirf_lb)}}lower bound of the TVP-VAR impulse response function path{p_end}
{synopt:{cmd:e(varirf_ub)}}upper bound of the TVP-VAR impulse response function path{p_end}
{synopt:{cmd:e(residual)}}residuals{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{title:References}

{phang}Inoue, A., Rossi, B., Wang, Y., and Zhou, L., 2024. "Parameter path estimation in unstable environments: the tvpreg command."  {it:Working Paper.}{p_end}


{title:Compatibility and known issues}

{phang} Please ensure the following information before running the {opt tvpreg} program:{p_end}
{phang2}. The programs are written in version 17.0.{p_end}
{phang2}. Time-series structure is declared: {opt tsset} {it: timevar}.{p_end}
{phang2}. The time-series should be consecutive with no missing values.{p_end}
{phang2}. The tvpreg and tvpplot commands use the {help bgshade:bgshade} package to add background shading in the parameter path. 
It can be found and installed in Stata by typing -ssc install bgshade- in the command window.{p_end}


{title:Author}

{p 4 4 2}
{cmd:Atsushi INOUE}{break}
Department of Economics, Vanderbilt University.{break}

{p 4 4 2}
{cmd:Barbara ROSSI}{break}
ICREA-Universitat Pompeu Fabra, EUI, Barcelona School of Economics, and CREI.{break}

{p 4 4 2}
{cmd:Yiru WANG}{break}
Department of Economics, University of Pittsburgh.{break}

{p 4 4 2}
{cmd:Lingyun ZHOU}{break}
PBC School of Finance, Tsinghua University.{break}
