{smcl}
{* 8nov2012}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{title:Title}

{pstd}{bf:importlabels} {hline 2} Create value labels from data in another data file

{title:Syntax}

{pmore}{cmd:importlabels} {it:{help varelist}} {cmd:using} {it:{help path_el}}

{synoptset 18}
{synopt:{help varelist##mods:Modifiers}}Description{p_end}
{synoptline}
{synopt:{cmd:(}{it:name}[{cmd:->}{it:new-name}]{cmd:)}}Original and (optional) new label names{p_end}

{title:Description}

{pstd}{cmd:importlabels} creates & assigns value labels in the current dataset, using {it:data} (not labels) in another dataset. The external dataset is assumed to be arranged:

{it:{col 9}{ul:Var1}{col 16}{ul:Var2}{col 25}{ul:Var3}}

{col 9}name{col 16}value{col 25}label

{pstd}For each label name specified as a {help varelist##mods:modifier}, the appropriate rows are read from the external file, and created as value labels in the current dataset (using {it:new-name} if specified).
That label is then assigned to all the modified variables.

{title:Examples}

{cmd:importlabels (labname) var1-var5 using labelfile}

{cmd:importlabels (origname->newname) var1-var5 using labelfile}


INCLUDE help also_lowy

