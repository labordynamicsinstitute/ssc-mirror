{smcl}
{* 11mar2016}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "elfs" "elfs"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: elfs startup} {hline 2} Things to do at startup


{title:Description}

{pstd}These are pre-defined actions that {it:can} be executed by {cmd:elfs startup, run} (which should be included in {cmd:profile.do}).
Each action (ie, each record in the settings data, described below) is only executed (by  {cmd:elfs startup, run}) if it has been individually turned {cmd:on}.

{pstd}Besides the listed actions, {cmd:elfs startup, run} will also put the {stata elfs misc, help:Stata appID} in the window title (unless the {stata elfs misc, help:Stata appID} has been set to empty).

{title:Records}

{phang}{cmd:instance} sets the {help elfs instance:instance id} and loads the corresponding {bf:Preference Set}.

{phang}{cmd:cdl} executes {cmd:cdl, p} which sets the {help cdl:current working directory} and {help cdl##project:current project directory} to whatever they were at the end of the last session (for this {help elfs instance:instance id}).

{phang}{cmd:fromEditor} adds two commands to the {cmd:User} menu, to interact with an external editor.{p_end}


{title:Links}

{phang}{cmd:Turn On} Adds a user-defined version of the setting, set to {cmd:on}.

{phang}{cmd:Delete} deletes a user-added setting (thus reverting to {cmd:off}).


