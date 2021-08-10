{smcl}
{* 2sep2009}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "cdl" "cdl"}{...}
{vieweralsosee "recent" "recent"}{...}
INCLUDE help also_vlowy
{title:Title} 

{pstd}{bf:Project Do (files)}

{title:Syntax}

{phang}{cmd:projdo run} [{cmd:off}]{p_end}
{phang}{cmd:projdo edit} [{cmd:off}]{p_end}


{title:Description}

{pstd}{cmd:projdo} is just a convenience for dealing with {help cdl##project:project settings} do-files (ie, {cmd:PROJECT SETTINGS.do} and {cmd:PROJECT SETTINGS off.do}).
You could create, edit, or run them in the usual way, but this command saves some effort dealing with names and paths.

{pstd}{cmd:projdo run} (re)runs the relevant file for the {help cdl##project:current project directory}.

{pstd}{cmd:projdo edit} opens the relevant file for editing.
If there is no {help cdl##project:current project directory}, {cmd:projdo edit} will create {cmd:PROJECT SETTINGS.do} in the current working directory (which then becomes the {help cdl##project:current project directory}).

