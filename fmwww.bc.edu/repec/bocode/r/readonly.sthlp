{smcl}
{* 13nov2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:readonly} {hline 2} Set a file to be read only

{title:Syntax}

{pstd}{cmd:readonly} {it:{help path_el}}

{title:Description}

{pstd}{cmd:readonly} makes a file read-only (on Windows, only).

{pstd}This is intended as an adjunct to {cmd:savel} and the rest of my commands, which universally over-write things without warning.
This is just an easy way to programmatically, visibly, protect 'source' datasets or similar.

{pstd}To make a file read-write, you can use the operating system...

