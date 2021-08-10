{smcl}
{* 20oct2011}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:randid} {c -} Generate a random id from a meaningful one

{title:Syntax}

{pmore}
{cmdab:randid} {newvar} {cmd:=} {it:{help varelist}} [{cmd:,} {cmdab:r:ange(}{it:min} [{it:max}]{cmd:)} {opt xw:alk(path)}]
 
{title:Description}

{pstd} {cmd:randid} creates {newvar}, containing a unique random value for each unique combination of {it:{help varelist}}.
In other words, it creates an anonymous ID variable. {newvar} will always contain integers.

{pstd}{it:{help varelist}} can contain numeric {it:or} string variables, but not both.

{title:Options}

{phang}{cmdab:r:ange()} can specify the minimum and maximum values for the new ID variable. If {cmdab:r:ange()} is not specified, the IDs will be numbered consecutively from 1. If {cmdab:r:ange()} is specified as {it:min} only, 
{it:newid} will range from the specified number, up to the the largest number with the same number of digits. E.g., if {cmdab:r:ange(100)} (or {cmdab:r:ange(352)}) is specified, IDs will be generated from there up to 999.

{phang}{opt xw:alk(path)} will save a crosswalk between old and new IDs in the file specified by {it:path}. Note that the file will be overwritten if it already exists.

