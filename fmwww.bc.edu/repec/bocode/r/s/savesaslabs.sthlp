{smcl}
{* 8nov2012}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:savesaslabs} {hline 2} Read a sas format program and create a stata dataset

{title:Syntax}

{pmore}{cmd:savesaslabs} {it:sas_program} {cmd:,} {opt s:aving(dataset)}

{title:Description}

{pstd}{cmd:savesaslabs} reads a sas program (that defines sas formats) and creates a stata dataset with the relevant info. The dataset has 3 columns: 

{phang}o-{space 2}{cmd:name}, the label name{p_end}
{phang}o-{space 2}{cmd:value}, the value to be labeled{p_end}
{phang}o-{space 2}{cmd:label}, the value label itself{p_end}

{pstd}Note that all columns are strings. In particular, although stata {it:values} must be numeric, that's not true in sas, so all the mappings are defined and you're free to deal with it as circumstances dictate.

{pstd}{cmd:savesaslabs} also reads any mappings of {it:labels} to {it:variables}, and stores them as a single characteristic: {cmd:_dta[assign]}. The format is {it:variable-name} {cmd:space} {it:label-name} {cmd:end-of-line} [{it:repeat}].

{pstd}The labels described in {it:dataset} can be created as actual labels, and assigned to variables, with the {help importlabels} command.


