{smcl}
{* 3nov2012}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "tlisthead" "tlisthead"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:tlist} {hline 2} Comprehensive tabular output

{title:Syntax}

{pmore}{cmdab:tlist} [{it:{help varelist}}] [{cmd:|} {it:{help varelist}} ...] {ifin} [{cmd:,} {it:options}]

{synoptset 22}
{synopthdr:general options}
{synoptline}
{synopt :{opt stub(integer)}}the number of left-hand columns to use as row headings{p_end}
{synopt :{opt foot(stat list)}}A list of summary statistics and labels to go at the end of the table{p_end}
{synopt :{cmdab:d:istinct}[{cmd:(}{it:{help varelist}}{cmd:)}]}display only rows with distinct values{p_end}
{synopt :{cmdab:r:andom}[{opt (integer)}]}random subset to display{p_end}
{synopt :{opt skip:names}}Don't use variable info in header{p_end}
INCLUDE help tabel_options1

{synopthdr:style options}
{synoptline}
{synopt :{opt alt:back(integer)}}alternate row backrounds{p_end}

{synopt :{opt vli:ne(details)}}vertical lines{p_end}
{synopt :{opt hli:ne(details)}}horizontal lines{p_end}
{synopt :{opt ali:gn(details)}}text alignment{p_end}
{synopt :{opt wr:ap(details)}}text wrapping{p_end}
{synopt :{opt cl:ass(details)}}other style info{p_end}


{title:Description}

{pstd}{cmd:tlist} can profitably be used as a replacement for {cmd:list}, but given the extensive style options and html output, it can also be used as a general-purpose table-composer.

{pstd}When a single {it:{help varelist}} is specified, the column headings will be the variable names and/or labels.
When multiple {it:{help varelist}}s are specified (that is, separated by {cmd:|}), each set will have one or more super-headings as specified with, and described under, {help tlisthead}.

{title:General Options}

{phang}{opt stub(integer)} specifies the number of left-hand columns to be treated as the stub (ie, row headings). It defaults to 0.

{phang}{cmd:foot(}{it:{help cfuncspec##cfunc:C-func} list}{cmd:)} specifies summary statistics for the last rows of the table.

{pmore}If {opt stub()} is specified, the left-most columns will display a description for each {it:{help cfuncspec##cfunc:C-func}}.
This description can be specified in the {it:{help cfuncspec##cfunc:C-func}} {opt d:escription()} option.

{pmore}{bf:[+]} Since the {help cfuncspec##cfunc:C-funcs} implicitly refer to the main {it:{help varelist}}, they are in {it:vars-by-funcs context}, and should be specified as, eg, {cmd:Mean()}.

{phang}{cmdab:d:istinct}[{cmd:(}{it:{help varelist}}{cmd:)}] displays only one row with each distinct combination of {it:{help varelist}} {hline 1} {it:which} row, exactly, is indeterminate.
If {it:{help varelist}} is not specified, the main {it:{help varelist}} is used.

{phang}{cmdab:r:andom}[{opt (integer)}] restricts the display to {it:integer} randomly selected rows. The random selection happens after exclusions for {ifin} and {opt d:istinct()}.
When {opt r:andom} is specified without a parameter, one screen-full is displayed.

{phang}{opt skip:names} causes the display to omit the variable names/labels from the column headers; using only the super-headers specified in {help tlisthead}.
When this option is specified, {opt nl:abels()} has no effect.

INCLUDE help tabel_options2n

{pmore}{it:nl1} governs the main (body) column-headings, and {it:nl2} governs the stub column-headings.

INCLUDE help tabel_options2v

{pmore}{it:vl1} governs the body of the table, and {it:vl2} governs the stub.

INCLUDE help tabel_out2

{title:Style Options}

{phang}{opt alt:back(integer)} specifies the number of consecutive rows to be styled normally/alternately. If {opt alt:back()} is not specified, it defaults to one.

{pmore}The effect varies depending on the {help outopt:out()} option: For {cmd:html} output, alternate row backgrounds are slightly shaded.
For {cmd:stata} or {cmd:email} output, when {opt alt:back()} is greater than 1, alternate rows are italicized.

{pmore}Also, see below for use of {cmd:class(altback:)}; when that is specified, the {opt altback()} option has no effect.

{pstd}{opt vline()}, {opt hline()}, {opt align()}, {opt wrap()}, and {opt class()} may each be specified multiple times per command, to style multiple areas.
In the case of {opt vline()} or {opt hline()}, the defined lines are {it:to the right} or {it:below} the specified cells, respectively. 

{pstd}The body of each option is:

{pmore}{it:style-name}{cmd::}{it:styled-area}


{pstd}where {it:style-name} is mainly an option-specific word:

{p2colset 9 20 20 2}{...}
{p2col:{ul:{it:option}}}{ul:{it:style-names}}

{p2col:{cmd:vline()}}{cmd:major}, {cmd:minor}, {cmd:space}, or {cmd:none}{p_end}
{p2col:{cmd:hline()}}{cmd:major}, {cmd:minor}, {cmd:space}, or {cmd:none}{p_end}
{p2col:{cmd:align()}}{cmd:left}, {cmd:right}, or {cmd:center}{p_end}
{p2col:{cmd:wrap()}}{it:integer}{p_end}

{p2col:{cmd:class()}}The available {opt class()} names are determined by the {help outopt:out()} option:

{p2colset 20 38 38 2}{...}
{p2col:{ul:Destination}}{ul:Class Names}{p_end}
{p2col:{opt results}}{stata elfs outstata}{p_end}
{p2col:{opt v:iewer}}{stata elfs outstata}{p_end}
{p2col:{opt html p:age}}{stata elfs outhtml}{p_end}
{p2col:{opt htm:l file}}{stata elfs outhtml}{p_end}
{p2col:{opt htm:l file, email}}{stata elfs outemail}{p_end}
{p2col:{opt m:ata}}any, depending

{p 19 19 2}There will always be a selected {bf:scheme} (set of standard classes), but you can also define classes on-the-fly in the {help outopt:out()} option.
Class names {it:defined} in the {help outopt:out()} option can be {it:applied} to the data via {opt class()}.{p_end}


{pstd}and where {it:styled-area} is:

{pmore}[{it:{help varelist}}]  {ifin} [{cmd:,}{cmdab:r:ows(}{it:{help numlist}}{cmd:)}]

{phang2}o-{space 2}{it:{help varelist}} determines the {bf:columns} to style (ie, the variables).

{phang2}o-{space 2}{cmdab:r:ows(}{it:{help numlist}}{cmd:)} selects {bf:rows} of the {bf:display} to style.{break}
{cmd:rows(3(2)20)} would style every other row from 3 to 20, {it:including} the header.

{phang2}o-{space 2}{ifin} selects {bf:rows} from the {bf:dataset} to style. The conditions can include variables and rows that are not displayed. Eg:

{pmore3}{cmd:tlist a b c, class(hi1:if x>5)}

{pmore2}displays variables {bf:a}, {bf:b}, and {bf:c}, highlighting rows for which variable {bf:x} (not displayed) is greater than 5.

{space 4}{hline}

{phang}Note for {opt wrap()}:

{phang2}o-{space 2}The specified integer is the character count of the first line indent. Negative numbers specify a hanging indent, and zero specifies text-wrapping with no indent.{p_end}
{phang2}o-{space 2}It has no effect on html output, which always wraps rather than truncating.{p_end}


{title:Example}

{cmd:tlist a b c, vline(major:a) vline(minor:b) ///}
             {cmd:hline(space:if x==5) class(bf:c if p<.05) class(v-thisway:a)}
             
{cmd:tlist,  class(mystyle: var1) out(htm, ///}
	{cmd:style(.mystyle {color:red; background:yellow; font-weight:bold}))}
	
