{smcl}
{* 12oct2010}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "dd" "dd"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:del} {hline 2} Describe(l)

{title:Syntax}

{p 8 15 2}
{cmd:del} [{it:{help varelist}}]  [{cmd:using} {it:{help path_el}}] [{cmd:,} {it:options}]

{synoptset 24}
{synopthdr}
{synoptline}
{synopt:{opt i:nclude(details)}}Specify information to display.{p_end}
{synopt:{opt nov:ars}}Display only dataset info, not individual variable info.{p_end}
{synopt:{opt wr:ap}}Wrap long text instead of truncating.{p_end}
{synopt:{opt def:ine}}Saves metadata choices with dataset{p_end}
INCLUDE help tabel_out1

{title:Description}

{pstd}{cmd:del} describes a dataset in memory or on disk. It can be used with any file that {help usel} could read. For non-Stata files, some information may be missing or approximated.

{pstd}The arrangement and information displayed can be customized for each data file, and can include {help char:characteristics} specific to that data file.


{title:Options}

{phang}{cmdab:i:nclude(}{it:column list} [{cmd:,} {opt only}]{cmd:)} where {it:column list} can include:

{p2colset 9 25 25 2}{...}
{p2col:{ul:Column}}{ul:Description}{p_end}
{p2col:{opt irs:type}}integer/real/string, plus size in bytes{p_end}
{p2col:{opt std:type}}Stata datatype (byte, long, etc.){p_end}
{p2col:{opt nl:abel}}Name label{p_end}
{p2col:{opt vl:abel}}Value labels{p_end}
{p2col:{opt f:ormat}}{p_end}
{p2col:{it:{help char:charname}}}Specify the characteristic name; the characteristic content is displayed.{p_end}

{pmore}The columns you specify will be followed by any others in the saved/default display, unless you specify {opt only}.

{pmore}{opt vl:abel} includes the value-label name as a link, which will bring up the actual labels in a viewer tab.

{pmore}{it:{help char:charname}} will display the relevant content for both the variables, and the dataset, if present.

{phang}{opt nov:ars} suppresses the table of variables, leaving only the description of the dataset as a whole.
{it:{help char:charnames}} specified in {opt i:nclude()} can still add to the dataset display.

{phang}{opt wr:ap} causes the text in the variables-table to wrap rather than truncate. The dataset-table (if present) always wraps.

{phang}{opt def:ine} makes the current display the default for this dataset. The choice will be saved with the data.

INCLUDE help tabel_out2


{title:Examples}

{col 5}{stata usel exampel, sys}
{col 5}{stata del}
{col 5}{stata del, i(format)}
{col 5}{stata del, i(irs method)}
{col 5}{stata del, i(how irs method) wrap}






