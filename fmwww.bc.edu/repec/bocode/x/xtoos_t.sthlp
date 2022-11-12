{smcl}
{* First Version July 23 2020}{...}
{* This Version Nov 11 2022}{...}
{viewerdialog xtoos_t "dialog xtoos_t"}{...}
{vieweralsosee "[XT] xtoos_i" "help xtoos_i"}{...}
{vieweralsosee "[XT] xtoos_bin_t" "help xtoos_bin_t"}{...}
{vieweralsosee "[XT] xtoos_bin_i" "help xtoos_bin_i"}{...}
{hline}
Help for {hi:xtoos_t}
{hline}

{title:Description}

{p}{cmd:xtoos_t} evaluates the out-of-sample prediction performance of a specified panel-data model in a time-series dimension.{p_end}

{p}The procedure excludes a number of time periods defined by the user from the estimation sample for each individual in the panel.
Then for the remaining subsample it fits the specified model and uses the resulting parameters to forecast the dependent variable in the unused periods (out-of-sample).
The unused time-period set is then recursively reduced by one period in every subsequent step and the estimation and forecasting procedures are repeated, 
until there are no more periods ahead that could be evaluated.{p_end} 
{p}{cmd:xtoos_t} allows to choose different estimation methods including some dynamic methodologies and could also be used in a time-series dataset only.{p_end}
{p}In the case the specification includes lags of the dependent variable, the procedure is able to automatically generate dynamic forecasts for the evaluation performance.{p_end}

{p}{cmd:xtoos_t} allows to evaluate the model's forecasting performance for one particular individual or for a defined group of individuals instead of the whole panel.{p_end}

{p}{cmd:xtoos_t} reports the specified model's forecasting performance, both in absolute terms (RMSE) and also relative to an alternative model by means of an U-Theil ratio, which is the ratio
between the RMSE of the specified model and the RMSE of the alternative model. By default, the alternative model is a "naive" prediction  in which 
the last observation of the in-sample period is used directly as a forecast without any change.  The procedure also allows to use an AR1 model as the alternative model for the comparison.
The procedure reports the RMSE of the specified model (RMSE_oos), the alternative model (RMSE_Alt_oos) and the U-Theil ratio (Utheil).{p_end}


{p}The performance results are broken down and reported in two different ways:{p_end}
{p}1) According to the last period included in the estimation sample.{p_end}
{p}2) According to the length of the forecasting horizon.{p_end}

{p}Additionally, it allows to draw a graph with the model forecasts at each forecasting horizon for a selected group of individuals in the panel. {p_end}

{title:Proceedings Spain Stata Conference 2019} 

https://www.stata.com/meeting/spain19/slides/Spain19_Ugarte-Ruiz.pdf


{title:Syntax}

{cmd:xtoos_t} {depvar} [{indepvars}] [{it:if}], {opt *ind:ate(string)} {opt *cd:ate(string)} 
	[{opt m:et(string)}] [{opt mc:omp(string)}] [{opt ev:alopt(varname)}] 
	[{opt fe}] [{opt xbu}] [{opt dum}] [{opt opar}] [{opt lags(numlist)}] [{opt hgraph(numlist)}]
	[{it:model_options}]


{synoptset}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt *ind:ate()}}It is always required. Specifies the last date (time-period) included in the estimation sample in the first step of the recursive procedure, 
i.e. it defines the date at which the performace evaluation starts. It allows Yearly, Quarterly and Monthly dates, or integer numbers, only. Quarterly and Monthly dates should be written as 1990q1 or 1990m1.{p_end}

{synopt:{opt *cd:ate()}}It is always required. Specifies the date at which the evaluation performance ends, i.e. the current date or the date at which the sample ends.  
It allows Yearly, Quarterly and Monthly dates, or integer numbers, only. Quarterly and Monthly dates should be written as 1990q1 or 1990m1.{p_end}

{synopt:{opt ev:alopt()}}Specifies a particular individual or group of individuals for which the prediction performance is evaluated. 
The particular individual or group must be defined by a dummy variable equal to one for those individuals.{p_end}

{synopt:{opt m:et()}}Specifies the estimation method. The default is {cmd:xtreg} when using panel data and {cmd:reg} when using time-series data.{p_end}

{synopt:{opt mc:omp()}}Specifies the estimation method for the AR1 model used as a comparison and for estimating the U-Theil, when an AR1 is preferred to a "naive" prediction. 
The AR1 could be estimated by dynamic panel methods such as {cmd:xtabond} or {cmd:xtdpdsys}, or simply by {cmd:xtreg} or {cmd:reg}.{p_end}

{synopt:{opt fe}}Estimates using Fixed-Effects (within) estimator.{p_end}

{synopt:{opt xbu}}Specifies that the prediction including the fixed or random component should be used.{p_end}

{synopt:{opt dum}}Estimates including one dummy variable per individual in the specification and in the prediction.{p_end}

{synopt:{opt opar}}Specifies that the contribution of the dummy variables per individual should not be included in the prediction. 
It can only be used together with the option {opt dum}.{p_end}

{synopt:{opt lags()}}Specifies the number of lags of the dependent variable that must be included the specification, the default is zero lags.
This option should be used when using a dynamic panel methods such as {cmd:xtabond} or {cmd:xtdpdsys}.  If other estimation method is being used,
the command {cmd:xtoos_t} also allows to write down the desired lagged dependent variables terms simply as other explanatory variables. {p_end}

{synopt:{opt hgraph()}}Specifies the individuals for which to draw a "hair" graph, with all the model forecasts at each forecasting horizon. 
The graph displays the actual dependent variable together with the model's prediction for each forecasting horizon and the alternative (comparison) prediction, which by default
corresponds to the prediction of an AR(1) model. The option requires to specify a list of numbers (panel code number) corresponding to the individals that you want to draw the hair graph.{p_end}

{synopt:{it:model_options}}Specifies any other estimation options specific to the method used and not defined elsewhere.{p_end}
{synoptline}

{marker Examples}{...}

{title:Example 1. Defining the evaluation (out-of-sample) period}

Use of {cmd:xtoos_t} to evaluate the prediction performance between periods 15 and 20 (out of 20 total periods in the sample)

{p 4 8 2}{cmd:. webuse invest2, clear}{p_end}
{p 4 8 2}{cmd:. xtset company time}{p_end}
{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20)}{p_end}

{title:Example 2. Restricting the evaluation to a group of individuals}

Use of {cmd:xtoos_t} to evaluate the prediction performance between periods 15 and 20, but restricting the evaluation only to company # 1 

{p 4 8 2}{cmd:. gen company1=company==1}{p_end}
{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20) evalopt(company1)}{p_end}

{title:Example 3. Changing the estimation method}

Use of {cmd:xtoos_t} using as estimation method the command {cmd:xtregar}

{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20) met(xtregar)}{p_end}

{title:Example 4. Changing the comparison method}

Use of {cmd:xtoos_t} using OLS ({cmd:reg}) as the estimation method for an AR(1) comparison model 

{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20) mcomp(reg)}{p_end}

{title:Example 5. Fixed Effects and individual components options}

Use of {cmd:xtoos_t} using Fixed-Effects (within) estimator including the estimated individual components in the prediction

{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20) fe xbu}{p_end}

{title:Example 6. No individual component in the prediction}

Use of {cmd:xtoos_t} using Fixed-Effects (within) estimator but without including the estimated individual components in the prediction

{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20) fe}{p_end}

{title:Example 7. Use of dummy variables}

Use of {cmd:xtoos_t} using dummy variables per individual and including their estimated values in the prediction (equivalent to options fe xbu)

{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20) dum}{p_end}

{title:Example 8. Use of dummy varibles in the specification but not in the prediction}

Use of {cmd:xtoos_t} using dummy variables per individual but without including their estimated values in the prediction (equivalent to option fe)

{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20) dum opar}{p_end}

{title:Example 9. Defining lags of the dependent variable}

Use of {cmd:xtoos_t} including lags of the dependent variable in the specification.  The following three specifications are equivalent:

{p 4 8 2}{cmd: xtoos_t invest market stock, indate(15) cdate(20) lags(3)} {p_end}
{p 4 8 2}{cmd: xtoos_t l(0/3).invest market stock, indate(15) cdate(20)} {p_end}
{p 4 8 2}{cmd: xtoos_t invest l.invest l2.invest l3.invest market stock, indate(15) cdate(20)} {p_end}

{title:Example 10. Using a dynamic model method}

Use of {cmd:xtoos_t} using a dynamic model method, either {cmd:xtabond} or {cmd:xtdpdsys}. In this case, the default specification includes one lag 
of the dependent variable

{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20) met(xtabond)}{p_end}
{p 4 8 2}{cmd:. xtoos_t invest market stock, indate(15) cdate(20) met(xtdpdsys) lags(2)}{p_end}

{title:Example 11. Drawing a graph with the different out-of-sample forecasts}

Use of {cmd:xtoos_t} to draw a "hair" graph with all the model forecasts at each forecasting horizons for individuals 1 to 5. 

{p 4 8 2}{cmd: xtoos_t invest market stock, indate(15) cdate(20) hgraph(1/5)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtoos_t} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(ev_last)}}evaluation according to the last in-sample period{p_end}
{synopt:{cmd:r(ev_hor)}}evaluation according to the forecasting horizon{p_end}

{title:Author}

Alfonso Ugarte-Ruiz
alfonso.ugarte@bbva.com
