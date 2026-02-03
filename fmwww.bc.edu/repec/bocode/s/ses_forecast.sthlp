{smcl}
{* *! version 1.0.0 30Jan2026}{...}
{title:Title}

{p 4 4 2}
{bf:ses_forecast} {hline 2} simple exponential smoothing forecasts with confidence intervals


{title:Syntax}

{p 4 4 2}
{cmd:ses_forecast} {help varname} {ifin} [, {cmdab:f:orecast(}{it:#}{cmd:)} 
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
{synopt:{it:model_options}}any {helpb tssmooth exponential} options{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {opt tsset} your data before using {opt ses_forecast}; see {manhelp tsset TS}.{p_end}



{title:Description}

{p 4 4 2}
{cmd:ses_forecast} generates point forecasts, standard errors, and confidence intervals
for simple exponential smoothing (SES) models. The procedure uses {helpb tssmooth exponential}
to fit the SES model and then computes forecast standard errors based on the innovation variance.
The implementation mirrors the method used in the R forecast package  
{browse "https://search.r-project.org/CRAN/refmans/forecast/html/ses.html":ses} function.



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
{it:model_options} are any options allowed by {helpb tssmooth exponential}. 


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse sales1, clear}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{p 4 4 2}Basic usage{p_end}
{phang2}{cmd:. ses_forecast sales, forecast(3)}{p_end}

{p 4 4 2}Same as above but replace added variables and produce figure {p_end}
{phang2}{cmd:. ses_forecast sales, forecast(3) replace fig}{p_end}

{p 4 4 2}Same as above but change level to 99% {p_end}
{phang2}{cmd:. ses_forecast sales, forecast(3) replace fig lev(99)}{p_end}



{title:Saved Results}

{p 4 4 2}
{cmd:ses_forecast} saves the following results:

{synoptset 22 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(forecast)}}forecast horizon{p_end}
{synopt:{cmd:r(alpha)}}alpha smoothing parameter{p_end}
{synopt:{cmd:r(sigma2)}}innovation variance{p_end}


{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}matrix of forecasts {p_end}
{p2colreset}{...}



{title:References}

{phang}
Hyndman, R.J., Koehler, A.B., Ord, J.K., & Snyder, R.D. (2008). 
{it:Forecasting with Exponential Smoothing: The State Space Approach}. 
Springer-Verlag. {p_end}

{phang}
Hyndman, R.J., & Athanasopoulos, G. (2021). 
{it:Forecasting: Principles and Practice} (3rd ed.). OTexts.{p_end}



{title:Citation of {cmd:ses_forecast}}

{p 4 8 2}{cmd:ses_forecast} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). SES_FORECAST: Stata module to compute simple exponential smoothing forecasts with confidence intervals



{title:Author}

{p 4 4 2}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also See}

{p 4 4 2}
{help tssmooth exponential}, {help arima_forecast} (if installed), {help shwinters_forecast} (if installed) {p_end}
