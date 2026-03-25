{smcl}
{* mlmsens.sthlp  v1.0.0  Subir Hait  2026}{...}
{hline}
help for {cmd:mlmsens}
{hline}

{title:Title}
{p 4 4 2}
{bf:mlmsens} {hline 2} Robustness diagnostics for cross-level MLM interactions

{title:Syntax}
{p 8 16 2}
{cmd:mlmsens} {cmd:,} {opt pred(string)} {opt modx(string)} {opt cl:uster(varname)}
[{it:options}]

{synoptset 26 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt pred(string)}}focal predictor name{p_end}
{synopt:{opt modx(string)}}moderator name{p_end}
{synopt:{opt cl:uster(varname)}}level-2 clustering variable{p_end}
{synopt:{opt alpha(#)}}significance threshold; default {bf:0.05}{p_end}
{synopt:{opt iccrange(# #)}}ICC range to evaluate; default {bf:0.01 0.40}{p_end}
{synopt:{opt iccgrid(#)}}number of ICC grid points; default {bf:40}{p_end}
{synopt:{opt noloco}}skip leave-one-cluster-out analysis{p_end}
{synopt:{opt verbose}}print progress during LOCO refitting{p_end}
{synopt:{opt plot}}draw ICC-shift sensitivity plot{p_end}
{synopt:{opt saving(filename)}}save plot to file{p_end}
{synoptline}

{title:Description}
{p 4 4 2}
{cmd:mlmsens} provides two MLM-appropriate robustness diagnostics for a
cross-level interaction:

{p 8 8 2}
{bf:ICC-shift}: how does the interaction SE change if the intraclass
correlation were different? Reports a robustness index: the proportion of
the ICC range where the interaction remains statistically significant.

{p 8 8 2}
{bf:LOCO} (leave-one-cluster-out): refits the model dropping one cluster
at a time and reports how the interaction coefficient changes. Flags
influential clusters.

{p 4 4 2}
{bf:Important}: These are robustness diagnostics, not a full causal
sensitivity analysis. They do not quantify the strength of unmeasured
confounding needed to explain away the interaction.

{p 4 4 2}
Must be run immediately after {help mixed}. LOCO refitting can be slow
for large datasets; use {opt noloco} to skip it.

{title:Stored results}
{synoptset 18 tabbed}
{synopt:{cmd:r(b_int)}}interaction coefficient{p_end}
{synopt:{cmd:r(se_int)}}SE of interaction{p_end}
{synopt:{cmd:r(icc_obs)}}observed ICC{p_end}
{synopt:{cmd:r(rob_index)}}robustness index (0-1){p_end}
{synopt:{cmd:r(n_clusters)}}number of clusters{p_end}

{title:Example}
{phang2}{cmd:. mixed math c.ses_c##c.climate_c gender || school:, reml}{p_end}
{phang2}{cmd:. mlmsens, pred(ses_c) modx(climate_c) cluster(school)}{p_end}
{phang2}{cmd:. mlmsens, pred(ses_c) modx(climate_c) cluster(school) noloco plot}{p_end}

{title:Author}
{p 4 4 2}
Subir Hait, Michigan State University.

{title:Also see}
{p 4 4 2}
{help mlmprobe}, {help mlmjn}, {help mlmsummary}, {help mlmvdecomp}
{smcl}
