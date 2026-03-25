{smcl}
{* mlmplot.sthlp  v1.0.0  Subir Hait  2026}{...}
{hline}
help for {cmd:mlmplot}
{hline}

{title:Title}
{p 4 4 2}
{bf:mlmplot} {hline 2} Publication-ready interaction plot for two-way MLM

{title:Syntax}
{p 8 16 2}
{cmd:mlmplot} {cmd:,} {opt pred(string)} {opt modx(string)}
[{it:options}]

{synoptset 24 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt pred(string)}}focal predictor (x-axis){p_end}
{synopt:{opt modx(string)}}moderator (separate lines){p_end}
{synopt:{opt at(numlist)}}custom moderator values{p_end}
{synopt:{opt v:alues(string)}}{bf:meansd} (default), {bf:quartiles}, or {bf:tertiles}{p_end}
{synopt:{opt level(#)}}confidence level for bands; default 95{p_end}
{synopt:{opt xlabel(string)}}x-axis label{p_end}
{synopt:{opt ylabel(string)}}y-axis label{p_end}
{synopt:{opt legendtitle(string)}}legend title; defaults to moderator name{p_end}
{synopt:{opt npred(#)}}number of x-axis grid points; default 50{p_end}
{synopt:{opt nointerval}}suppress confidence bands{p_end}
{synopt:{opt saving(filename)}}save graph to file{p_end}
{synoptline}

{title:Description}
{p 4 4 2}
{cmd:mlmplot} produces a publication-ready interaction plot showing
predicted values of the outcome across the range of {it:pred}, with
separate lines for selected values of {it:modx}. Confidence bands are
drawn by default using the delta method over fixed-effect uncertainty.

{p 4 4 2}
{cmd:mlmplot} must be run immediately after {help mixed}. The model must
include the interaction as {cmd:c.}{it:pred}{cmd:##c.}{it:modx}.

{title:Example}
{phang2}{cmd:. mixed math c.ses_c##c.climate_c gender || school:, reml}{p_end}
{phang2}{cmd:. mlmplot, pred(ses_c) modx(climate_c)}{p_end}
{phang2}{cmd:. mlmplot, pred(ses_c) modx(climate_c) values(quartiles)}{p_end}
{phang2}{cmd:. mlmplot, pred(ses_c) modx(climate_c) at(-1 0 1) ///}{p_end}
{phang3}{cmd:  xlabel("Student SES") ylabel("Math Score") legendtitle("School Climate")}{p_end}

{title:Author}
{p 4 4 2}
Subir Hait, Michigan State University.

{title:Also see}
{p 4 4 2}
{help mlmprobe}, {help mlmjn}, {help mlmsummary}, {help mlmcenter}
{smcl}
