{smcl}
{* mlmcenter.sthlp  v1.0.0  Subir Hait  2026}{...}
{hline}
help for {cmd:mlmcenter}
{hline}

{title:Title}
{p 4 4 2}
{bf:mlmcenter} {hline 2} Center variables for multilevel modeling

{title:Syntax}
{p 8 16 2}
{cmd:mlmcenter} {varlist} [{it:if}] [{it:in}]
[{cmd:,} {it:options}]

{synoptset 22 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt cl:uster(varname)}}clustering variable (required for group/both){p_end}
{synopt:{opt t:ype(string)}}centering type: {bf:grand} (default), {bf:group}, or {bf:both}{p_end}
{synopt:{opt suf:fix_within(string)}}suffix for within-centered variable; default {it:_within}{p_end}
{synopt:{opt suf:fix_between(string)}}suffix for between (cluster mean) variable; default {it:_between}{p_end}
{synoptline}

{title:Description}
{p 4 4 2}
{cmd:mlmcenter} centers one or more numeric variables for use in multilevel
models. Three centering strategies are available:

{p 8 8 2}
{bf:grand}: subtract the overall (grand) mean. Creates {it:varname}{bf:_c}.

{p 8 8 2}
{bf:group}: subtract the cluster mean (within-cluster centering).
Creates {it:varname}{bf:_c}.

{p 8 8 2}
{bf:both}: within-between decomposition. Creates both a within-centered variable
({it:varname}{it:_within} by default) and the cluster mean ({it:varname}{it:_between}).

{title:Examples}
{phang}
Grand-mean center SES:{p_end}
{phang2}{cmd:. mlmcenter ses, type(grand)}{p_end}

{phang}
Group-mean center SES within schools:{p_end}
{phang2}{cmd:. mlmcenter ses, cluster(school) type(group)}{p_end}

{phang}
Within-between decomposition:{p_end}
{phang2}{cmd:. mlmcenter ses, cluster(school) type(both)}{p_end}

{title:Author}
{p 4 4 2}
Subir Hait, Michigan State University. {browse "https://github.com/causalfragility-lab/mlmoderator"}

{title:Also see}
{p 4 4 2}
{help mlmprobe}, {help mlmjn}, {help mlmplot}, {help mlmsummary},
{help mlmsens}, {help mlmvdecomp}
{smcl}
