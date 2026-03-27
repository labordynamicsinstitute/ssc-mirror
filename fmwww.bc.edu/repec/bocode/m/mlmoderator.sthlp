{smcl}
{* mlmoderator.sthlp  v1.0.0  Subir Hait  2026}{...}
{hline}
help for {cmd:mlmoderator}
{hline}

{title:Title}
{p 4 4 2}
{bf:mlmoderator} {hline 2} Probing, diagnosing, and visualizing cross-level interactions in multilevel models

{title:Description}
{p 4 4 2}
{cmd:mlmoderator} is a package providing a unified workflow for probing,
plotting, and assessing the robustness of two-way cross-level interaction
effects in mixed-effects models fitted with Stata's {help mixed} command.

{p 4 4 2}
The package integrates several post-estimation procedures that are commonly
needed when interpreting cross-level interactions in hierarchical and
longitudinal data settings.

{title:Commands}

{synoptset 18 tabbed}
{synopthdr:Command}
{synoptline}
{synopt:{helpb mlmcenter}}Grand-mean, group-mean, and within-between centering{p_end}
{synopt:{helpb mlmprobe}}Simple slopes at selected moderator values{p_end}
{synopt:{helpb mlmjn}}Johnson{c -}Neyman interval (analytical exact solution){p_end}
{synopt:{helpb mlmplot}}Publication-ready interaction plot with confidence bands{p_end}
{synopt:{helpb mlmsummary}}Consolidated moderation results report{p_end}
{synopt:{helpb mlmvdecomp}}Decompose slope variance into fixed vs. random components{p_end}
{synopt:{helpb mlmsens}}ICC-shift robustness and leave-one-cluster-out diagnostics{p_end}
{synoptline}

{title:Typical workflow}

{p 4 4 2}
Step 1: Center variables before modeling.

{phang2}{cmd:. mlmcenter ses, by(school) method(groupmean)}{p_end}

{p 4 4 2}
Step 2: Fit the multilevel model using {help mixed}.

{phang2}{cmd:. mixed math c.ses_c##c.climate_c gender || school:ses_c, reml cov(un)}{p_end}

{p 4 4 2}
Step 3: Probe simple slopes.

{phang2}{cmd:. mlmprobe, pred(ses_c) modx(climate_c)}{p_end}

{p 4 4 2}
Step 4: Compute the Johnson{c -}Neyman interval.

{phang2}{cmd:. mlmjn, pred(ses_c) modx(climate_c)}{p_end}

{p 4 4 2}
Step 5: Plot the interaction.

{phang2}{cmd:. mlmplot, pred(ses_c) modx(climate_c)}{p_end}

{p 4 4 2}
Step 6: Summarize all moderation results.

{phang2}{cmd:. mlmsummary, pred(ses_c) modx(climate_c)}{p_end}

{p 4 4 2}
Step 7: Decompose variance in the slope.

{phang2}{cmd:. mlmvdecomp, pred(ses_c)}{p_end}

{p 4 4 2}
Step 8: Assess robustness.

{phang2}{cmd:. mlmsens, pred(ses_c) modx(climate_c)}{p_end}

{title:Requirements}
{p 4 4 2}
Stata 14.1 or later. All commands require {help mixed} to have been run
immediately beforehand; they read the stored estimation results.

{title:Installation}
{p 4 4 2}
To install from GitHub:{p_end}

{phang2}{cmd:. net install mlmoderator, from("https://raw.githubusercontent.com/causalfragility-lab/mlmoderator-Stata/main/") replace}{p_end}

{p 4 4 2}
The package is also available from SSC:{p_end}

{phang2}{cmd:. ssc install mlmoderator, replace}{p_end}

{title:Author}
{p 4 4 2}
Subir Hait, Department of Counseling, Educational Psychology, and Special Education,
Michigan State University.{p_end}
{p 4 4 2}
ORCID: {browse "https://orcid.org/0009-0004-9871-9677":0009-0004-9871-9677}{p_end}
{p 4 4 2}
Bug reports and suggestions: {browse "https://github.com/causalfragility-lab/mlmoderator-Stata/issues"}{p_end}

{title:Also see}
{p 4 4 2}
{helpb mixed}, {helpb mlmcenter}, {helpb mlmprobe}, {helpb mlmjn},
{helpb mlmplot}, {helpb mlmsummary}, {helpb mlmvdecomp}, {helpb mlmsens}
