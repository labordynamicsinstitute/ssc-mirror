{smcl}
{* *! version 0.0.1 22may2026}{...}
{viewerjumpto "Syntax" "upset_barchart_options##syntax"}{...}
{viewerjumpto "Description" "upset_barchart_options##description"}{...}
{viewerjumpto "Axis title options" "upset_barchart_options##title_options"}{...}
{viewerjumpto "Axis scale options" "upset_barchart_options##scale_options"}{...}
{viewerjumpto "Axis label options" "upset_barchart_options##label_rule_or_values"}{...}
{viewerjumpto "Bar label options" "upset_barchart_options##blabel_rule_or_values"}{...}
{viewerjumpto "Remarks" "upset_barchart_options##remarks"}{...}
{viewerjumpto "Authors" "upset_barchart_options##authors"}{...}
{title:Title}

{phang}
{it:upset_barchart_options} {hline 2} Options for controlling the display of bar
charts in {cmd:upset_plot}.


{marker syntax}{...}
{title:Syntax}

{pstd}
{it:upset_barchart_options} control the appearance of set and intersection bar
charts created through {cmd:upset_plot}; see {help upset_plot}.

{marker upset_barchart_options}{...}
{synoptset 37 tabbed}{...}
{synopthdr:upset_barchart_options}
{synoptline}
{synopt:{opt off}}suppress the bar chart{p_end}
{synopt:{opt gap(#)}}control the margin between the grid and bar chart{p_end}
{synopt:{cmdab:yti:tle(}{help upset_barchart_options##title_options:title_options}{cmd:)}}specify the y-axis title{p_end}
{synopt:{cmdab:xsc:ale(}{help upset_barchart_options##scale_options:scale_options}{cmd:)}}control the appearance of the x-axis{p_end}
{synopt:{cmdab:ysc:ale(}{help upset_barchart_options##scale_options:scale_options}{cmd:)}}control the appearance of the y-axis{p_end}
{synopt:{cmdab:ylab:el(}{help upset_barchart_options##label_rule_or_values:label_rule_or_values}{cmd:)}}control the y-axis ticks and labels{p_end}
{synopt:{cmdab:ysiz:e(}{it:#}{cmd:)}}height of the bar chart{p_end}
{synopt:{cmdab:blab:el(}{help upset_barchart_options##blabel_rule_or_values:blabel_rule_or_values}{cmd:)}}control bar label content and appearance{p_end}
{synoptline}


{marker title_options}{...}
{pstd}
where {it:title_options} is

{p 8 16 2}
{cmd:"}{it:string}{cmd:"} [{cmd:"}{it:string}{cmd:"} [ ...]]
[{cmd:,} {it:title_suboptions}]

{pmore}
{it:string} must be enclosed in quotation marks and may contain Unicode
characters and SMCL tags to render mathematical symbols, italics, etc.; see
{help graph_text:text}.

{synoptset 37 tabbed}{...}
{synopthdr:title_suboptions}
{synoptline}
{synopt:{cmdab:place:ment:(}{it:{help compassdirstyle:compassdirstyle}}{cmd:)}}where to place the title{p_end}
{synopt:{cmdab:orient:ation:(}{help orientationstyle:orientationstyle}{cmd:)}}whether to display title vertically or horizontally{p_end}
{synopt:{cmdab:titleg:ap:(}{it:#}{cmd:)}}margin between axis and title{p_end}
{synoptline}


{marker scale_options}{...}
{synoptset 37 tabbed}{...}
{synopthdr:scale_options}
{synoptline}
{synopt:{cmd:off}}suppress display of axis line{p_end}
{synopt:{cmd:range(}{it:{help numlist}}{cmd:)}}expand the axis range{p_end}
{synopt:{cmdab:lsty:le:(}{it:{help linestyle}}{cmd:)}}overall style of axis line{p_end}
{synopt:{cmdab:lc:olor:(}{it:{help colorstyle}}{cmd:)}}color and opacity of axis line{p_end}
{synopt:{cmdab:lw:idth:(}{it:{help linewidthstyle}}{cmd:)}}thickness of axis line{p_end}
{synopt:{cmdab:lp:attern:(}{it:{help linepatternstyle}}{cmd:)}}pattern of axis line (solid, dashed, etc.){p_end}
{synoptline}


{marker label_rule_or_values}{...}
{pstd}
where {it:label_rule_or_values} is defined as:

{p 8 16 2}
[{it:label_rule}] [{help numlist}]
[{cmd:,} {it:label_suboptions}]

{pmore}
You may not specify both {it:label_rule} and {it:numlist}.

{synoptset 37 tabbed}{...}
{synopthdr:label_rule}
{synoptline}
{synopt:{bf:#}#}approximately # nice values{p_end}
{synopt:#{bf:(}#{bf:)}#}specified range with uniform steps{p_end}
{synopt:{bf:minmax}}minimum and maximum values{p_end}
{synopt:{bf:none}}suppress labels{p_end}
{synoptline}

{synoptset 37 tabbed}{...}
{synopthdr:label_suboptions}
{synoptline}
{synopt:[{cmd:no}]{cmd:ticks}}display or suppress ticks{p_end}
{synopt:[{cmd:no}]{cmdab:lab:els}}display or suppress labels{p_end}
{synopt:{cmd:format(}{help format:{bf:%}{it:fmt}}{cmd:)}}format values per {cmd:%}{it:fmt}{p_end}
{synopt:{cmd:angle(}{it:{help anglestyle}}{cmd:)}}angle the labels{p_end}

{synopt:{cmd:labgap(}{it:{help size}}{cmd:)}}labels: margin between tick and label{p_end}
{synopt:{cmd:labstyle(}{it:{help textstyle}}{cmd:)}}labels: overall style{p_end}
{synopt:{cmdab:labs:ize:(}{it:#}{cmd:)}}labels: text size{p_end}
{synopt:{cmdab:labc:olor:(}{it:{help colorstyle}}{cmd:)}}labels: color and opacity of text{p_end}

{synopt:{cmdab:tl:ength:(}{it:#}{cmd:)}}ticks: length{p_end}
{synopt:{cmdab:tp:osition:(}{cmdab:o:utside}|{cmdab:c:rossing}|{cmdab:i:nside:)}}ticks: position/direction{p_end}
{synopt:{cmdab:tlsty:le:(}{it:{help linestyle}}{cmd:)}}ticks: overall line style{p_end}
{synopt:{cmdab:tlw:idth:(}{it:{help linewidthstyle}}{cmd:)}}ticks: thickness of line{p_end}
{synopt:{cmdab:tlc:olor:(}{it:{help colorstyle}}{cmd:)}}ticks: color and opacity of line{p_end}

{synopt:[{cmd:no}]{cmd:grid}}grid: display or suppress grid lines{p_end}
{synopt:{cmdab:glsty:le:(}{it:{help linestyle}}{cmd:)}}grid: overall line style{p_end}
{synopt:{cmdab:glw:idth:(}{it:{help linewidthstyle}}{cmd:)}}grid: line thickness{p_end}
{synopt:{cmdab:glc:olor:(}{it:{help colorstyle}}{cmd:)}}grid: color and opacity of line{p_end}
{synopt:{cmdab:glp:attern:(}{it:{help linepatternstyle}}{cmd:)}}grid: line pattern{p_end}
{synoptline}


{marker blabel_rule_or_values}{...}
{pstd}
where {it:blabel_rule_or_values} is defined as:

{p 8 16 2}
{it:blabel_rule}
[{cmd:,} {it:blabel_suboptions}]

{synoptset 37 tabbed}{...}
{synopthdr:blabel_rule}
{synoptline}
{synopt:{cmdab:total}}label each bar with its overall frequency{p_end}
{synopt:{cmdab:bar}}label each segment with its frequency{p_end}
{synopt:{cmdab:cumbar}}label each segment with its cumulative frequency{p_end}
{synoptline}

{synoptset 37 tabbed}{...}
{synopthdr:blabel_suboptions}
{synoptline}
{synopt:{cmdab:pos:ition:(}{cmdab:o:utside}|{cmdab:i:nside}|{cmdab:b:ase}|{cmdab:c:enter}{cmd:)}}placement of label relative to bar segment{p_end}
{synopt:{cmd:gap(}{help size}{cmd:)}}distance from {opt position()}{p_end}
{synopt:{cmd:format(}{help format:%fmt}{cmd:)}}format labels{p_end}
{synopt:{cmdab:orient:ation:(}{help orientationstyle:orientationstyle}{cmd:)}}display bar labels vertically or horizontally{p_end}
{synopt:{cmdab:si:ze:(}{help textsizestyle:textsizestyle}{cmd:)}}size of bar labels{p_end}
{synopt:{cmdab:c:olor:(}{help colorstyle:colorstyle}{cmd:)}}color and opacity of bar labels{p_end}
{synopt:{cmdab:perc:entage}}display percentages instead of frequencies{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{it:upset_barchart_options} control the appearance of the intersection and set
bar charts within {cmd:upset_plot}.

{pstd}
{it:upset_barchart_options} resembles standard twoway axis and
labeling options (see {help twoway_options}), but is implemented independently
within {cmd: upset_plot}. Due to this, several {it:twoway_options} features are not
available in {it:upset_barchart_options}, and others have modified syntax (e.g.,
{opt ytitle()} titles needing to be enclosed in quotation marks).


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:

	{help upset_barchart_options##remarks1:Default values}
	{help upset_barchart_options##remarks2:Tick positioning}
	{help upset_barchart_options##remarks3:Label positioning}


{marker remarks1}{...}
{title:Default values}

{pstd}
In some instances, options' default values vary by whether the caller was
{opt intopts()} or {opt setopts()}. The default values in such cases are given
below in #{opt rs} (see {help size}):

{synoptset 20 tabbed}{...}
{synopt:}{it:upset_barchart_options}{space 12}{it:label_suboptions}{p_end}

{synopt:caller}{opt gap(#)}{space 5}{opt ysize(#)}{space 15}{opt labgap(#)}{space 4}{opt tlength(#)}{p_end}
{synoptline}
{synopt:{cmd:intopts()}}0.1{space 8}3.0{space 20}0.020{space 8}0.025{p_end}
{synopt:{cmd:setopts()}}0.2{space 8}0.5{space 20}0.048{space 8}0.060{p_end}
{synoptline}


{marker remarks2}{...}
{title:Tick positioning}

{pstd}
Within {opt ylabel()}, {opt tposition()} controls where the ticks will be placed:

{pmore}
{opt tposition(outside)}, the default, places ticks wholly outside the bar chart region.

{pmore}
{opt tposition(crossing)} places ticks half-in, half-out of the bar chart region.

{pmore}
{opt tposition(inside)} places ticks wholly inside the bar chart region.


{marker remarks3}{...}
{title:Label positioning}

{pstd}
Within {opt blabel()}, {opt position()} controls where the bar labels will be placed:

{pmore}
{opt position(outside)}, the default, places labels just above the bar.

{pmore}
{opt position(inside)} places labels inside the bar at the top.

{pmore}
{opt position(base)} places labels inside the bar at the bar's base.

{pmore}
{opt position(center)} places labels inside the bar at the bar's center.


{marker authors}{...}
{title:Authors}

{pstd}
Dylan Taylor, London School of Hygiene and Tropical Medicine, London{break}
dylanjamestaylor00@gmail.com
