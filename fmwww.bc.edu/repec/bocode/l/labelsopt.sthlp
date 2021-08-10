{smcl}
{* 18sep2009}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:nlabels()}, {bf:vlabels()} {c -} Label display options

{title:Syntax}

{pmore}{cmdab:nl:abels(}{it:nl1} [{cmd:,} {it:nl2}]{cmd:)}

{pmore}{cmdab:vl:abels(}{it:vl1} [{cmd:,} {it:vl2}]{cmd:)}

{pstd}where {it:nl1} and {it:nl2} are any combination of:

{space 8}[ {opt u:nlabeled} ]
{space 8}[ {opt l:abeled}[{opt (charname)}] ]
{space 8}[ {opt t:ip} ]
{space 8}[ {opt nom:ark} ]

{pstd}and {it:vl1} and {it:vl2} are any combination of:

{space 8}[ {opt u:nlabeled} ]
{space 8}[ {opt l:abeled} ]
{space 8}[ {opt t:ip} ]

{title:Description}

{pstd}These options determine how variable names ({opt nl:abels()}) and values ({opt vl:abels()}) are displayed.

{pstd}For some commands, different parts of the display {hline 1} for example, the header vs body of a table {hline 1} can be labeled differently by using a second set of suboptions; ie, {it:nl2} and/or {it:vl2}.
If a command will interpret {it:nl2} and/or {it:vl2}, that fact, and the part of the display affected, will be included in the command's documentation.

{pstd}For each set of suboptions:

{phang2}o-{space 2}When {opt u:nlabeled} or {opt l:abeled} is specified alone, that variety of output is produced ({opt t:ip} has no effect when specified alone).

{phang2}o-{space 2}When {opt u:nlabeled} and {opt l:abeled} are {it:both} specified, both will be displayed, {bf:in the order specified}.

{phang2}o-{space 2}When {opt t:ip} is specified along with {opt u:nlabeled} and/or {opt l:abeled}, the first of {opt u} or {opt l} is displayed, and the other (whether explicitly specified or not) is used as a 'tooltip'.

{pstd}String variable names (labeled or not) are ordinarily prefixed with an asterisk which has "string variable" as a tooltip. {opt nom:ark} suppresses that prefix.

{pstd}Note that for {opt nl()}, {opt l:abeled} can optionally include a parameter (ie, {opt l:abeled(charname)}), a {help char:characteristic name}. If one is specified, that characteristic will take the place of the variable label.
This can be useful, eg, to provide descriptions longer than 80 characters.

{title:Tooltips}

{pstd}Tooltips are produced in both HTML and Stata ouput, but they function a little differently:
In both cases you can view the tip by "hovering" the cursor over the link, but in Stata the tips show up in the status bar at the bottom of the window, rather than popping up over the link as they do in HTML.

{title:Additional Details}

{phang}o-{space 2}Date and Time values are treated as though their {it:formatted value} is a label. That is, {opt vl:abels()} will determine whether the raw and/or formatted value appears.

{phang}o-{space 2}When both types of information (ie, {cmd:u} and {cmd:l}) are displayed together, missing labels are left blank;
however, when {bf:only} labels are displayed (with or without tips), missing labels are filled in with the relevant unlabeled item.

{phang}o-{space 2}Since names and their labels are both text, {it:names} are underlined when there is the possibility of confusion (eg, when filling in for a missing label).


