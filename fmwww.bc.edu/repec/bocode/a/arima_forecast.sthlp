{smcl}
{* *! version 1.0.0  20Jan2026}{...}

{title:Title}

{p 4 4 2}
{opt arima_forecast} - Compute ARIMA forecast standard errors and generate dynamic forecasts

{title:Syntax}

{p 8 17 2}
{cmdab:arima_forecast}
[{cmd:,} {it:options}]

{pstd}
An {helpb arima} model must be estimated prior to running {opt arima_forecast}


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Forecast Settings}
{synopt:{opt h(#)}}forecast horizon; default is {cmd:h(1)}{p_end}
{synopt:{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{syntab:Output Options}
{synopt:{opt pre:fix(string)}}prefix for forecast variable names{p_end}
{synopt:{opt repl:ace}}replace existing forecast variables and added observations{p_end}
{synopt:{opt fig:ure}}generate forecast plot{p_end}
{synopt:{it:twoway_options}}any available twoway graph options{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{p 4 4 2}
{cmd:arima_forecast} is a post-estimation command for {helpb arima} that computes forecast standard errors 
for ARIMA models and generates dynamic forecasts with confidence interval using the theoretical variance formula for 
ARIMA models, following the approach implemented in R's 
{browse "https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/predict.Arima":predict.Arima} 
function from the stats package. These standard errors lead to wider (and more realistic) confidence intervals 
than those produced in Stata using manual computation with {cmd:predict ..., mse} as standard errors.
{cmd:arima_forecast} optionally generates a forecast plot similar to that produced by the
{browse "https://www.rdocumentation.org/packages/forecast/versions/8.5/topics/forecast":forecast} 
package in R.



{title:Options}

{dlgtab:Forecast Settings}

{phang}
{opt h(#)} specifies the forecast horizon, i.e., the number of periods to 
forecast. The default is {opt h(1)}.

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] Estimation options}.

{dlgtab:Output Options}

{phang}
{opt prefix(string)} specifies a prefix for the forecast variable names. 
If not specified, variables will be named {cmd:pred}, {cmd:se}, {cmd:ll#}, 
and {cmd:ul#} (where # is the confidence level). For example, with 
{cmd:prefix(my)} and {cmd:level(95)}, variables will be named 
{cmd:mypred}, {cmd:myse}, {cmd:myll95}, and {cmd:myul95}.

{phang}
{opt replace} removes any existing forecast variables and observations 
from the previous run before generating new forecasts. This option is 
useful when you want to update forecasts with different specifications 
or correct a previous run.

{phang}
{opt figure} generates a forecast plot showing the original series, 
point forecasts, and confidence intervals. The plot is styled to resemble 
the {browse "https://www.rdocumentation.org/packages/forecast/versions/8.5/topics/forecast":forecast} 
package's (in R) output.

{phang}
{it:twoway_options} are any standard {help twoway} graph options that 
can be used to customize the forecast plot when the {opt figure} option 
is specified.



{title:Remarks}

{p 4 4 2}
{cmd:arima_forecast} has the following requirements and will produce an error if not followed:

{p 8 12 2}
(1) Can only be used after {helpb arima} estimation.

{p 8 12 2}
(2) The ARIMA model must be specified using the {cmd:arima(p,d,q)} syntax. 
  Models specified using separate {cmd:ar()} and {cmd:ma()} options are 
  not supported.

{p 8 12 2}
(3) For seasonal models, use the {cmd:sarima(P,D,Q,s)} syntax. Do not use 
  separate {cmd:sar()}, {cmd:sma()}, {cmd:mar()}, or {cmd:mma()} options.

{p 8 12 2}
(4) Models with covariates (explanatory variables) are not supported.

{p 8 12 2}
(5) Models estimated with {cmd:if} or {cmd:in} qualifiers are not supported.

{p 8 12 2}
(6) Models with differencing (d > 0 or D > 0) must be estimated with the 
  {cmd:noconstant} option, consistent with standard ARIMA theory.

  

{title:Examples}

{hline}
{pstd}Setup{p_end}
{p 8 12 2}. {stata "webuse gnp96, clear"}{p_end}
{p 8 12 2}. {stata "tsset date"}{p_end}

{pstd}Simple ARIMA model with differencing and autoregressive component:{p_end}
{p 8 12 2}. {stata "arima gnp, arima(1,1,0) noconstant"}{p_end}

{pstd}Produce 8 future forecasts and generate figure{p_end}
{p 8 12 2}. {stata "arima_forecast, h(8) figure"}{p_end}

{pstd}Re-run {cmd:arima_forecast} and produce 12 future forecasts figure{p_end}
{p 8 12 2}. {stata "arima_forecast, h(12) figure replace"}{p_end}
    
{hline}
{pstd}Setup{p_end}
{p 8 12 2}. {stata "webuse air2, clear"}{p_end}
{p 8 12 2}. {stata "tsset t"}{p_end}

{pstd}Multiplicative SARIMA model:{p_end}
{p 8 12 2}. {stata "arima air, arima(0,1,1) sarima(0,1,1,12) noconstant"}{p_end}

{pstd}Produce 12 future forecasts and generate figure{p_end}
{p 8 12 2}. {stata "arima_forecast, h(12) fig"}{p_end}

{pstd}Replace existing forecasts and generate new ones:{p_end}
{p 8 12 2}. {stata "arima_forecast, h(12) level(99) replace figure"}{p_end}

{hline}


{title:Saved Results}

{p 4 4 2}
{cmd:arima_forecast} saves the following results:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(h)}}forecast horizon{p_end}
{synopt:{cmd:r(level)}}confidence level (if specified){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(se)}}forecast standard error matrix {p_end}
{p2colreset}{...}



{title:References}

{p 4 4 2}
The forecast standard error computation follows established time series 
theory as described in:

{p 8 12 2}
Box, G. E. P., Jenkins, G. M., Reinsel, G. C., & Ljung, G. M. (2015). 
{it:Time Series Analysis: Forecasting and Control} (5th ed.). 
John Wiley & Sons. [Section 5.2.3: Forecast error variance, pp. 144-146]

{p 8 12 2}
Hamilton, J. D. (1994). {it:Time Series Analysis}. 
Princeton University Press. [Section 4.8: Forecasting, pp. 80-84]

{p 8 12 2}
Brockwell, P. J., & Davis, R. A. (2016). 
{it:Introduction to Time Series and Forecasting} (3rd ed.). 
Springer. [Section 3.5: Prediction, pp. 102-106]

{p 4 4 2}
The specific implementation follows the algorithm used in R's 
{browse "https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/predict.Arima":predict.Arima} 
function, which is based on the psi-weight approach described in:

{p 8 12 2}
Hyndman, R. J., & Athanasopoulos, G. (2021). 
{it:Forecasting: Principles and Practice} (3rd ed.). 
OTexts. [Section 8.5: Prediction intervals for ARIMA models]

{p 4 4 2}
For the special case of ARIMA(3,1,0) and differenced models, the 
treatment follows the polynomial expansion method described in:

{p 8 12 2}
Ansley, C. F., & Newbold, P. (1980). 
Finite sample properties of estimators for autoregressive moving average models. 
{it:Journal of Econometrics}, 13(2), 159-183.



{title:Citation of {cmd:arima_forecast}}

{p 4 8 2}{cmd:arima_forecast} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). ARIMA_FORECAST: Stata module to compute ARIMA forecast standard errors and generate dynamic forecasts



{title:Author}

{p 4 4 2}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also See}

{p 4 4 2}
{helpb arima}, {helpb arima postestimation}, {helpb tsappend}  {p_end}


