{smcl}
{* March 24 2022}{...}
{viewerdialog xtoos "dialog xtoos"}{...}
{vieweralsosee "[XT] xtoos_t" "help xtoos_t"}{...}
{vieweralsosee "[XT] xtoos_i" "help xtoos_i"}{...}
{vieweralsosee "[XT] xtoos_bin_t" "help xtoos_bin_t"}{...}
{vieweralsosee "[XT] xtoos_bin_i" "help xtoos_bin_i"}{...}
{hline}
Help for {hi:xtoos}
{hline}

{title:Description}

{p}The package {cmd:XTOOS} includes four commands that allow to evaluate the out-of-sample prediction performance of panel-data models in their time-series and cross-individual dimensions separately, 
also with separate procedures for different types of dependent variables, either continuous or dichotomous variables. {p_end}
{p}The name of the commands are { help xtoos_t}, {help xtoos_i}, {help xtoos_bin_t}, and {help xtoos_bin_i}. {p_end}

{p}The time-series procedures ({cmd:xtoos_t} and {cmd:xtoos_bin_t}) exclude a number of time periods defined by the user from the estimation sample for each individual in the panel. {p_end}

{p}Similarly, the cross-individual procedures ({cmd:xtoos_i} and {cmd:xtoos_bin_i}) exclude a group of individuals (for example, countries) defined by the user from the estimation sample (including all their observations throughout time). {p_end}

{p}Then, for the remaining subsamples (training-sample), they fit the specified models and use the resulting parameters to forecast the dependent variable (or the probability of a positive outcome) 
in the unused time-periods or the unused individuals (testing-sample).
 
The unused time-period or individual sets are then recursively reduced by one period in every subsequent step in the time-series dimension, 
or, either in a random or in an ordered fashion for the cross-individual dimension.

The estimation and forecasting evaluation are repeated until there are no more periods ahead or more individuals that could be evaluated. {p_end}

{p}In the continuous cases, the model's forecasting performance is reported both in absolute terms (RMSE) and relative to a naive prediction, by means of a U-Theil ratio. {p_end}

{p}In the dichotomous case, the prediction performance is evaluated based on the area under the receiver operator characteristic (ROC) statistic evaluated in both the training sample and the out of sample. {p_end}

{p}The procedures allow to choose different estimation methods, including some dynamic methodologies, and could also be used in a time-series or a cross-section dataset only. 
They also allow evaluating the model's forecasting performance for one particular individual or for a defined group of individuals instead of the whole panel.{p_end}


{p}See {help xtoos_t} for specific help about {cmd:xtoos_t} command.{p_end}
{p}See {help xtoos_i} for specific help about {cmd:xtoos_i} command.{p_end}
{p}See {help xtoos_bin_t} for specific help about {cmd:xtoos_bin_t} command.{p_end}
{p}See {help xtoos_bin_i} for specific help about {cmd:xtoos_bin_i} command.{p_end}

{title:Proceedings Spain Stata Conference 2019} 

https://www.stata.com/meeting/spain19/slides/Spain19_Ugarte-Ruiz.pdf

{title:Author}

Alfonso Ugarte-Ruiz
alfonso.ugarte@bbva.com

 
