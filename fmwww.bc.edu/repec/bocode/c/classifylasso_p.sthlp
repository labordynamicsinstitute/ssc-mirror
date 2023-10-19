{smcl}
{* February 2023}{...}
[CLASSO] {bf:predict} ——  Predict group membership and fitted values after classifylasso.


{title:Syntax}

{p 8 15 2} {cmd:predict} {newvar}
{ifin} [{cmd:,} {it:statistic}]
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt :{opt gid}}group membership; the default{p_end}
{synopt :{opt xb}}xb fitted values{p_end}
{synopt :{opt xbd}}xb + d_absorbvars{p_end}
{synopt :{opt d}}d_absorbvars{p_end}
{synopt :{opt r:esiduals}}residuals{p_end}
{synopt :{opt stdp}}standard error of the prediction (of the xb component){p_end}
{synoptline}


{title:Description}

{p 4 4 2}{cmd:predict} calculates group membership and linear fitted values. It allows for both in-sample and out-sample prediction, with either C-Lasso or post-Lasso coefficients.


{marker options}{...}
{title:Options}

{phang}{opt gid} calculates the group membership. 
Both in-sample or out-of-sampe predictions are allowed. 
In-sample prediction is obtained directly from estimation; 
out-sample prediction is calculated by choosing the group membership whose coefficient vector minimizes the sum square error of certain individual unit.

{phang}{opt xb}, {opt xbd}, {opt d}, {opt residuals}, and {opt stdp} calculate the various fitted results from the model. 
It applies similarly to the {cmd:predict} command for {cmd:reghdfe}, only that it assigns different coefficients according to the group membership. 
Note that you do not need to predict membership before generating the fitted values.
