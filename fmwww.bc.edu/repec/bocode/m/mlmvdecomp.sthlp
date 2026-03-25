{smcl}
{* mlmvdecomp.sthlp  v1.0.0  Subir Hait  2026}{...}
{hline}
help for {cmd:mlmvdecomp}
{hline}

{title:Title}
{p 4 4 2}
{bf:mlmvdecomp} {hline 2} Decompose slope uncertainty into fixed vs random components

{title:Syntax}
{p 8 16 2}
{cmd:mlmvdecomp} {cmd:,} {opt pred(string)} {opt modx(string)}
[{it:options}]

{synoptset 22 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt pred(string)}}focal predictor name{p_end}
{synopt:{opt modx(string)}}moderator name{p_end}
{synopt:{opt level(#)}}confidence level; default 95{p_end}
{synopt:{opt plot}}draw variance decomposition plot{p_end}
{synopt:{opt saving(filename)}}save plot to file{p_end}
{synoptline}

{title:Description}
{p 4 4 2}
{cmd:mlmvdecomp} decomposes the total uncertainty in the simple slope of
{it:pred} into two components:

{p 8 8 2}
{bf:Fixed-effect variance}: uncertainty from estimating the regression
coefficients (captured by the fixed-effect confidence interval).

{p 8 8 2}
{bf:Random slope variance}: additional between-cluster variability in the
slope of {it:pred} (tau11, the random slope variance). This component
reflects genuine cross-cluster heterogeneity, not estimation error.

{p 4 4 2}
The decomposition is reported at -1 SD, Mean, and +1 SD of the moderator.
If the model does not include a random slope on {it:pred}, the random
component is zero.

{p 4 4 2}
Must be run immediately after {help mixed}.

{title:Stored results}
{synoptset 16 tabbed}
{synopt:{cmd:r(tau11)}}random slope variance for {it:pred}{p_end}
{synopt:{cmd:r(b_pred)}}main effect of predictor{p_end}
{synopt:{cmd:r(b_int)}}interaction coefficient{p_end}

{title:Example}
{phang2}// Model with random slope:{p_end}
{phang2}{cmd:. mixed math c.ses_c##c.climate_c gender || school: ses_c, reml}{p_end}
{phang2}{cmd:. mlmvdecomp, pred(ses_c) modx(climate_c)}{p_end}
{phang2}{cmd:. mlmvdecomp, pred(ses_c) modx(climate_c) plot}{p_end}

{title:Author}
{p 4 4 2}
Subir Hait, Michigan State University.

{title:Also see}
{p 4 4 2}
{help mlmsens}, {help mlmprobe}, {help mlmsummary}
{smcl}
