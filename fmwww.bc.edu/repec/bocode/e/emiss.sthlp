{smcl}
{* 28aug2007}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "nmiss" "nmiss"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:emiss} {hline 2} Extended missing values

{title:Syntax}

{pstd}{cmd:emiss} [ {it:{help varelist}} ], [ {opt mv:list(list)} {opt o:mit} {opt out(details)} ]

{title:Description}

{pstd}{cmd:emiss} produces a table of variables vs. missing values.

{title:Options}

{phang}{opt mv:list(list)} Restricts the display to the specified set of missing values. It takes a list of single, lower case letters, and/or {cmd:.}, and accepts {cmd:-} as a range operator. Eg:

{phang3}{cmd:mvlist(a b g-l t-x z)}

{phang}{opt o:mit} causes {cmd:emiss} to omit variables which do not contain one of the specified missing values.

INCLUDE help tabel_out2

