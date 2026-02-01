{smcl}
{* *! version 1.0.0 28Mar2026}{...}
{title:Title}

{p 4 4 2}
{bf:shwinters_forecast} {hline 2} Holt-Winters seasonal forecasts with confidence intervals


{title:Syntax}

{p 4 4 2}
{cmd:shwinters_forecast} {help varname} {ifin} [, {cmdab:f:orecast(}{it:#}{cmd:)} 
{cmdab:l:evel(}{it:#}{cmd:)}
{cmdab:repl:ace}
{cmdab:fig:ure}
{cmdab:pre:fix(}{it:string}{cmd:)}
{cmdab:tw:owayopts(}{it:string}{cmd:)}
{it:model_options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt f:orecast(#)}}number of periods to forecast; default is {cmd:forecast(2)}{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt repl:ace}}replace existing forecast variables and added observations{p_end}
{synopt:{opt fig:ure}}display forecast graph{p_end}
{synopt:{opt pre:fix(string)}}prefix for forecast variable names{p_end}
{synopt:{opt tw:owayopts(string)}}options to pass to {helpb twoway} graph{p_end}
{synopt:{it:model_options}}any {helpb tssmooth shwinters} options{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {opt tsset} your data before using {opt shwinters_forecast}; see {manhelp tsset TS}.{p_end}



{title:Description}

{p 4 4 2}
{cmd:shwinters_forecast} fits a Holt-Winters seasonal model using {helpb tssmooth shwinters}
and computes analytic confidence intervals for forecasts following the methodology
of Yar & Chatfield (1990) for additive models and Chatfield & Yar (1991) for multiplicative models.



{title:Options}

{phang}
{opt forecast(#)} use # periods for the out-of-sample forecast; default is {cmd:forecast(2)}.

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] Estimation options}.

{phang}
{opt prefix(string)} specifies a prefix for the forecast variable names. 
If not specified, variables will be named {cmd:forecast}, {cmd:se}, {cmd:ll#}, 
and {cmd:ul#} (where # is the confidence level). For example, with 
{cmd:prefix(my)} and {cmd:level(95)}, variables will be named 
{cmd:myforecast}, {cmd:myse}, {cmd:myll95}, and {cmd:myul95}.

{phang}
{opt figure} generates a forecast plot showing the original series, 
point forecasts, and confidence intervals. The plot is styled to resemble 
the {browse "https://www.rdocumentation.org/packages/forecast/versions/8.5/topics/forecast":forecast} 
package's (in R) output.

{phang}
{opt twowayopts(string)} specifies options to pass to the {helpb twoway} graph
when the {cmd:figure} option is used. This allows customization of the graph
appearance, such as changing colors, adding titles, modifying legends, etc.

{phang}
{it:model_options} are any options allowed by {helpb tssmooth shwinters}. 



{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse air2, clear}{p_end}
{phang2}{cmd:. gen date = m(1949m1) + _n - 1}{p_end}
{phang2}{cmd:. format date %tm}{p_end}
{phang2}{cmd:. tsset date}{p_end}

{pstd}Produce forecasts for 12 future periods{p_end}
{phang2}{cmd:. shwinters_forecast air, forecast(12)}{p_end}

{pstd}Same as above but add graph and specify that the forecasts in memory be replaced{p_end}
{phang2}{cmd:. shwinters_forecast air, forecast(12) fig replace}{p_end}	

{pstd}Same as above but specify an additive seasonal model{p_end}
{phang2}{cmd:. shwinters_forecast air, forecast(12) fig replace additive}{p_end}	

{pstd}Here we show how to deal with data that are not {helpb tsset} seasonally. In the current data
the time variable {it:t} is sequentially numbered. We specify the {helpb tssmooth} option {cmd:period(12)}
to handle the seasonality {p_end}
{phang2}{cmd:. webuse air2, clear}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. shwinters_forecast air, forecast(12) fig replace period(12)}{p_end}	



{title:Saved Results}

{p 4 4 2}
{cmd:shwinters_forecast} saves the following results:

{synoptset 22 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(forecast)}}forecast horizon{p_end}
{synopt:{cmd:r(cv)}}coefficient of variation{p_end}
{synopt:{cmd:r(alpha)}}alpha smoothing parameter{p_end}
{synopt:{cmd:r(beta)}}beta smoothing parameter{p_end}
{synopt:{cmd:r(gamma)}}gamma smoothing parameter{p_end}
{synopt:{cmd:r(rmse)}}root mean squared error{p_end}
{synopt:{cmd:r(is_multiplicative)}}indicator of whether the model is multiplicative{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}matrix of forecasts {p_end}
{p2colreset}{...}



{title:References}

{phang}
Yar, M. and C. Chatfield. 1990. Prediction intervals for the Holt-Winters
forecasting procedure. {it:International Journal of Forecasting} 6(1): 127-137.
{p_end}

{phang}
Chatfield, C. and M. Yar. 1991. Prediction intervals for multiplicative
Holt-Winters. {it:International Journal of Forecasting} 7(1): 31-37.
{p_end}



{title:Citation of {cmd:shwinters_forecast}}

{p 4 8 2}{cmd:shwinters_forecast} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). SHWINTERS_FORECAST: Stata module to compute Holt-Winters seasonal forecasts with confidence intervals



{title:Author}

{p 4 4 2}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also See}

{p 4 4 2}
{help tssmooth shwinters}, {help graph twoway}, {help arima_forecast} (if installed) {p_end}

