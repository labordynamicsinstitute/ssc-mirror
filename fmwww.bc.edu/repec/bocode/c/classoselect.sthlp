{smcl}
{* February 2023}{...}
[CLASSO] {bf:classoselect} ——  Select the active estimationi results after classifylasso.


{title:Syntax}


{p 8 15 2} {cmd:classoselect} [{cmd:,} {it:options}] 
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt group(#)}}use coefficients estimated under certain number of groups{p_end}
{synopt :{opt post:selection}}use postselection (unpenalized) coefficients{p_end}
{synopt :{opt pen:alized}}use penalized coefficients{p_end}
{synoptline}


{title:Description}

{p 4 4 2}{cmd:classoselect} alters the active result used by {cmd:predict}, {cmd:estimates replay} and {cmd:classocoef} after classifylasso. By default, post-Lasso coefficients with the BIC-best number of groups are active.


{marker options}{...}
{title:Options}

{phang}{opt g:roup(#)} specifies the number of groups be used to estimate the coefficients.
The default is the best fitted number of group selected by information criterion.
The number must be one of the list {opth group(numlist)} specified by {cmd:classifylasso}.

{phang}{opt postselection} specifies that post-Lasso coefficients be used to plot the graph. That is the default.
Post-Lasso coefficients are calculated by regressing the corresponding model for each estimated group.

{phang}{opt penalized} specifies that penalized coefficients be used to plot the graph.
Penalized coefficients are those estimated by C-Lasso in the calculation of the additive-multiplication penalty.
