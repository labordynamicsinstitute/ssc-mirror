{smcl}
{* mlmjn.sthlp  v1.0.0  Subir Hait  2026}{...}
{hline}
help for {cmd:mlmjn}
{hline}

{title:Title}
{p 4 4 2}
{bf:mlmjn} {hline 2} Johnson-Neyman interval for a two-way MLM interaction

{title:Syntax}
{p 8 16 2}
{cmd:mlmjn} {cmd:,} {opt pred(string)} {opt modx(string)}
[{it:options}]

{synoptset 22 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt pred(string)}}focal predictor name{p_end}
{synopt:{opt modx(string)}}moderator name{p_end}
{synopt:{opt alpha(#)}}significance level; default {bf:0.05}{p_end}
{synopt:{opt plot}}draw a Johnson-Neyman plot{p_end}
{synopt:{opt grid(#)}}number of grid points for plot; default {bf:200}{p_end}
{synopt:{opt saving(filename)}}save plot to file{p_end}
{synoptline}

{title:Description}
{p 4 4 2}
{cmd:mlmjn} computes the Johnson-Neyman (JN) interval: the value(s) of
{it:modx} at which the simple slope of {it:pred} transitions between
statistical significance and non-significance.

{p 4 4 2}
The boundary is computed analytically via the quadratic formula (exact
solution, not a grid search). Results are reported for boundaries that
fall within the observed range of {it:modx}.

{p 4 4 2}
{cmd:mlmjn} must be run immediately after {help mixed}. The model must
include the interaction as {cmd:c.}{it:pred}{cmd:##c.}{it:modx}.

{title:Stored results}
{synoptset 16 tabbed}
{synopt:{cmd:r(jn1)}}first JN boundary (. if none in observed range){p_end}
{synopt:{cmd:r(jn2)}}second JN boundary (. if none){p_end}
{synopt:{cmd:r(t_crit)}}critical t-value used{p_end}
{synopt:{cmd:r(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:r(b_pred)}}coefficient on focal predictor{p_end}
{synopt:{cmd:r(b_int)}}coefficient on interaction term{p_end}

{title:Example}
{phang2}{cmd:. mixed math c.ses_c##c.climate_c gender || school:, reml}{p_end}
{phang2}{cmd:. mlmjn, pred(ses_c) modx(climate_c)}{p_end}
{phang2}{cmd:. mlmjn, pred(ses_c) modx(climate_c) plot}{p_end}
{phang2}{cmd:. mlmjn, pred(ses_c) modx(climate_c) alpha(0.01) plot}{p_end}

{title:Author}
{p 4 4 2}
Subir Hait, Michigan State University.

{title:Reference}
{p 4 4 2}
Johnson, P. O., and Neyman, J. (1936). Tests of certain linear hypotheses
and their application to some educational problems.
{it:Statistical Research Memoirs}, 1, 57-93.

{title:Also see}
{p 4 4 2}
{help mlmprobe}, {help mlmplot}, {help mlmsummary}, {help mlmcenter}
{smcl}
