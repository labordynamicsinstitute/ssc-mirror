{smcl}
{* *! opl_best_treat, v5, GCerulli, 29aug2025}
{title:Title}

{pstd}
{cmd:opl_best_treat} {hline 2} Computing maximal reward and best treatment after {cmd:opl_ma_fb}.

{marker syntax}{...}{title:Syntax}

{p 8 17 2}
{cmd:opl_best_treat} {it:varlist} 

where:

{pstd}
{it:varlist} are the reward counterfactual predictions obtained after estimating {cmd:opl_ma_fb}, that is: {cmd:__pred0}, {cmd:__pred1}, {cmd:__pred2}, etc..

{title:Description}

{pstd}
{cmd:opl_best_treat} is used after running {cmd:opl_ma_fb} and loading the dataset saved via
option {cmd:save_preds_vars(}{it:name}{cmd:)} of {cmd:opl_ma_fb}, which stores individual-level
counterfactual expected rewards and conditional variances.

{pstd}
Given the counterfactual predictions in {it:varlist} (one variable per treatment arm,
e.g. {cmd:__pred0}, {cmd:__pred1}, {cmd:__pred2}, ...), {cmd:opl_best_treat} computes:
(1) the maximal expected outcome across arms, and
(2) the corresponding best treatment, according to the first-best decision rule.

{title:Options}

{pstd}
{it:None.} The command takes only {it:varlist} as input.

{title:Returned variables}

{phang}
{cmd:__Y_hat_max}: maximal expected outcome over the treatments in {it:varlist}.{p_end}
{phang}
{cmd:__T_best}: index of the best (optimal) treatment achieving {cmd:__Y_hat_max}
(first-best rule).{p_end}

{title:Remarks}

{pstd}
{cmd:opl_best_treat} assumes that all variables in {it:varlist} are on the same outcome scale and
correspond to mutually exclusive treatment arms with consistent naming (e.g., {cmd:__pred0}, {cmd:__pred1}, ...).
The command does not alter the input predictions.

{title:Examples}

{phang}* After running {cmd:opl_ma_fb} with option {cmd:save_preds_vars()} and loading the saved dataset:{p_end}
{phang}. describe __pred0 __pred1 __pred2{p_end}
{phang}. {cmd:opl_best_treat} __pred0 __pred1 __pred2{p_end}
{phang}. summarize __Y_hat_max{p_end}
{phang}. tabulate __T_best{p_end}

{dlgtab:Author}

{phang}Giovanni Cerulli{p_end}
{phang}IRCrES-CNR{p_end}
{phang}Research Institute for Sustainable Economic Growth, National Research Council of Italy{p_end}
{phang}E-mail: {browse "mailto:giovanni.cerulli@cnr.it":giovanni.cerulli@cnr.it}{p_end}

{dlgtab:Also see:}

{psee}
{help opl_ma_fb}, {help opl_ma_vf}, {help opl_plot_best}
{p_end}

