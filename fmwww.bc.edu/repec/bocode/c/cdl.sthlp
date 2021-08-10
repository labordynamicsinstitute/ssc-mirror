{smcl}
{* 22may2008}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "recent" "recent"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:cdl} {hline 2} Change working directory, and project directory

{title:Syntax}

{phang2}{cmd:cdl} [{it:{help path_el}} | {cmd:<} | {cmdab:d:ata}]  [{cmd:,} {opt p:roject}]{p_end}


{title:Description}

{pstd}{cmd:cdl} displays the current working directory, or changes it and adds it to the {help recent} list. When the {opt p:roject} option is specified, {cmd:cdl} does the same thing for the {help cdl##project:current project directory}.
The {help recent} list is remembered across Stata sessions, and is specific to each {help elfs instance:instance id}.

{phang}o-{space 2}With no main parameter, {cmd:cdl} displays the current working directory.{p_end}
{phang}o-{space 2}{it:{help path_el}} explicitly specifies the directory to change to.{p_end}
{phang}o-{space 2}{cmd:<} specifies switching back to the prior working directory.{p_end}
{phang}o-{space 2}{cmdab:d:ata} specifies switching to the directory of the {help recent##datasource:current data source}.{p_end}

{pstd}If you have a path that conflicts with some other part of the command, you can either prefix your path with {cmd:./} (ie, current directory) and/or enclose it in quotes.


{title:On Startup}

{pstd}Because {help recent} settings are remembered across stata sessions, you can automatically start a new Stata session in your last used directory by including the appropriate command in {cmd:profile.do}.

{pstd}My recommendation for that command would be {cmd:elfs startup, run}, which can set the startup directory and more, and which can help insulate you and your {cmd:profile.do} file from future syntax changes.
However, in principal, {cmd:cdl} or {cmd:cdl, p} in {cmd:profile.do} would also work.


{marker project}{title:Project Directories}

{pstd}A {bf:project directory} is one directly containing a file named {cmd:project settings.do}.

{pstd}When you specify the {opt p:roject} option, {cmd:cdl} will change the {bf:current project directory} to the (new) current working directory or its nearest parent that is a {bf:project directory}.
If you specify {opt p:roject} for a directory that has no parent {bf:project directory}, the {bf:current project directory} is cleared {hline 2} set to empty.

{pstd}{help recent}  {bf:project directories} are tracked independently of {help recent} working directories.


{title:Project Settings}

{pstd}Whenever {cmd:cdl} changes the {bf:project directory} {hline 1} including to or from empty {hline 1} it runs a do-file or two: 

{phang}o-{space 2}If the {bf:project directory} being changed {it:from} contains a file named {cmd:project settings off.do}, that file will be run first.{p_end}
{phang}o-{space 2}Then, in the {bf:project directory} being changed {it:to}, {cmd:project settings.do} is run. That file exists by definition, though it can be empty.

{pstd}{help projdo} offers a bit of a shortcut for creating or running these files.


{title:Remarks}

{pstd}{cmd:cdl} tracks its current/recent working directories independently from the one built-in to Stata, so the two can get out of sync {hline 2} for example, if you use {cmd:cd} to change Stata's working directory.
Whenever {cmd:cdl} is invoked, though, it leaves the two in sync.
In the rest of this help file, then, 'current working directory' refers unambiguously to both.


{title:Examples}

   {cmd:. cdl a space filled name}
   
   {cmd:. cdl data} {it:to switch to the directory of the data in memory}
   
   {cmd:. cdl <}{space 4}{it:to return to the previous working directory}

   