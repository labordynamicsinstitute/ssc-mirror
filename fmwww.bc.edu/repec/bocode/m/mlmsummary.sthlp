{smcl}
{* mlmsummary.sthlp  v1.0.0  Subir Hait  2026}{...}
{hline}
help for {cmd:mlmsummary}
{hline}

{title:Title}
{p 4 4 2}
{bf:mlmsummary} {hline 2} Consolidated moderation report for two-way MLM

{title:Syntax}
{p 8 16 2}
{cmd:mlmsummary} {cmd:,} {opt pred(string)} {opt modx(string)}
[{it:options}]

{synoptset 22 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt pred(string)}}focal predictor name{p_end}
{synopt:{opt modx(string)}}moderator name{p_end}
{synopt:{opt alpha(#)}}significance level for JN; default {bf:0.05}{p_end}
{synopt:{opt level(#)}}confidence level; default 95{p_end}
{synoptline}

{title:Description}
{p 4 4 2}
{cmd:mlmsummary} prints a single consolidated report covering:
(1) fixed-effect estimates for the focal terms with significance stars,
(2) variance components and ICC,
(3) Johnson-Neyman boundary, and
(4) simple slopes at -1 SD, Mean, and +1 SD of the moderator.

{p 4 4 2}
Must be run immediately after {help mixed}.

{title:Stored results}
{synoptset 16 tabbed}
{synopt:{cmd:r(b_int)}}interaction coefficient{p_end}
{synopt:{cmd:r(p_int)}}p-value for interaction{p_end}
{synopt:{cmd:r(icc)}}observed ICC{p_end}
{synopt:{cmd:r(jn1)}}first JN boundary{p_end}
{synopt:{cmd:r(jn2)}}second JN boundary{p_end}

{title:Example}
{phang2}{cmd:. mixed math c.ses_c##c.climate_c gender || school:, reml}{p_end}
{phang2}{cmd:. mlmsummary, pred(ses_c) modx(climate_c)}{p_end}

{title:Author}
{p 4 4 2}
Subir Hait, Michigan State University.

{title:Also see}
{p 4 4 2}
{help mlmprobe}, {help mlmjn}, {help mlmplot}, {help mlmsens}
{smcl}
