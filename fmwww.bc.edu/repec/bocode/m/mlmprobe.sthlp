{smcl}
{* mlmprobe.sthlp  v1.0.0  Subir Hait  2026}{...}
{hline}
help for {cmd:mlmprobe}
{hline}

{title:Title}
{p 4 4 2}
{bf:mlmprobe} {hline 2} Simple slopes for a two-way MLM interaction

{title:Syntax}
{p 8 16 2}
{cmd:mlmprobe} {cmd:,} {opt pred(string)} {opt modx(string)}
[{it:options}]

{synoptset 22 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt pred(string)}}name of the focal predictor{p_end}
{synopt:{opt modx(string)}}name of the moderator variable{p_end}
{synopt:{opt at(numlist)}}custom moderator values to probe{p_end}
{synopt:{opt v:alues(string)}}{bf:meansd} (default), {bf:quartiles}, or {bf:tertiles}{p_end}
{synopt:{opt level(#)}}confidence level; default 95{p_end}
{synoptline}

{title:Description}
{p 4 4 2}
{cmd:mlmprobe} computes simple slopes of {it:pred} at selected values of {it:modx}
using the delta method, based on the coefficient vector and variance-covariance
matrix stored after {help mixed}.

{p 4 4 2}
The model must include the interaction as {cmd:c.}{it:pred}{cmd:##c.}{it:modx}.
Run {cmd:mixed} immediately before {cmd:mlmprobe}.

{title:Stored results}
{p 4 4 2}
{cmd:mlmprobe} stores the following in {cmd:r()}:

{synoptset 16 tabbed}
{synopt:{cmd:r(slope_}{it:i}{cmd:)}}simple slope at moderator value {it:i}{p_end}
{synopt:{cmd:r(se_}{it:i}{cmd:)}}standard error at moderator value {it:i}{p_end}
{synopt:{cmd:r(t_}{it:i}{cmd:)}}t-statistic at moderator value {it:i}{p_end}
{synopt:{cmd:r(p_}{it:i}{cmd:)}}p-value at moderator value {it:i}{p_end}
{synopt:{cmd:r(w_}{it:i}{cmd:)}}moderator value for probe {it:i}{p_end}

{title:Example}
{phang2}{cmd:. mixed math c.ses_c##c.climate_c gender || school:, reml}{p_end}
{phang2}{cmd:. mlmprobe, pred(ses_c) modx(climate_c)}{p_end}
{phang2}{cmd:. mlmprobe, pred(ses_c) modx(climate_c) values(quartiles)}{p_end}
{phang2}{cmd:. mlmprobe, pred(ses_c) modx(climate_c) at(-1 0 1)}{p_end}

{title:Author}
{p 4 4 2}
Subir Hait, Michigan State University.

{title:Also see}
{p 4 4 2}
{help mlmjn}, {help mlmplot}, {help mlmsummary}, {help mlmcenter}
{smcl}
