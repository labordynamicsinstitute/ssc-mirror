{smcl}
{* 16dec2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:source} {hline 2} Open (non-data) files
 
{title:Syntax}

{pmore}{cmd:source} {it:file}|{cmd:profile}

{title:Description}

{pstd}{cmd:source} opens files, such as {cmd:.do} or {cmd:.ado} files, in their default editors. You can specify an entire file-path, but a few shortcuts are available:

{phang}o-{space 2}If you specify just the word {cmd:profile}, it will open your {cmd:profile.do} file for editing (if it's in your 'home' folder).

{phang}o-{space 2}If you don't specify any directories, it will use the Stata system directories (so it will find Stata commands, for example).

{phang}o-{space 2}If you don't specify a file extension, it will first search for {cmd:.ado} (ie, Stata commands) and then {cmd:.mata} (ie, Mata function source code).


{title:Examples}

{cmd:source profile}

