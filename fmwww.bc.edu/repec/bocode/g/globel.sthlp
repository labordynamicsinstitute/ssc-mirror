{smcl}
{* 13feb2016}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:globel} {hline 2} Set a global and display it

{title:Syntax}

{phang2}{cmd:globel} {it:mname} {it:mcontent}


{title:Description}

{pstd}{cmd:globel} simply creates a global, and then lists it. For a global that is cleared (ie, set to empty) it will list the name, and show no contents.

{pstd}Using {cmd:noisily globel} instead of {cmd:global} in a do-file that gets {cmd:run} (eg, {cmd:profile.do}) will display/confirm the globals that are set or cleared in that do-file.

