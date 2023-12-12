{smcl}
{* 13nov2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:chlist} {hline 2} DIsplay variable characteristics

{title:Syntax}

{pstd}{cmd:chlist} {it:{help varelist}} [{cmd:,} {opt c:hars(char names)} {opt d:ta} {opt s:wap} {opt out(details)} ]

{title:Description}

{pstd}{cmd:chlist} displays a table of variables/characteristics.

{title:Options}

{phang}{opt c:hars(char names)} is a characteristic-name-list which uses the same syntax as a standard {it:{help varelist}}. It functions as a filter, so that only variables with matching characteristic names are displayed.

{phang}{opt d:ta} specifies that dataset characteristics should be included, in addition to variable characteristics.

{phang}{opt s:wap} transposes the display: Ordinarily, variables form the stub and char-names the header. {opt s:wap} makes char-names the stub and variables the header.

INCLUDE help tabel_out2

