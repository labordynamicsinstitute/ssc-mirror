{smcl}
{* *! version 0.0.1 22may2026}{...}
{viewerjumpto "Syntax" "upset_plot##syntax"}{...}
{viewerjumpto "Description" "upset_plot##description"}{...}
{viewerjumpto "Options" "upset_plot##options"}{...}
{viewerjumpto "Remarks" "upset_plot##remarks"}{...}
{viewerjumpto "Examples" "upset_plot##examples"}{...}
{viewerjumpto "Stored results" "upset_plot##stored"}{...}
{viewerjumpto "References" "upset_plot##references"}{...}
{viewerjumpto "Authors" "upset_plot##authors"}{...}
{title:Title}

{phang}
{bf:upset_plot} {hline 2} UpSet plots for binary indicator variables.


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{opt upset_plot}
{varlist}
{ifin}
[{it:{help upset_plot##weight:weight}}]
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{cmd:over(}{varname}[{cmd:,} {help upset_plot##over_suboptions:{it:over_suboptions}}]{cmd:)}}groups over which bars are drawn{p_end}
{synopt:{cmd:bar(}{it:#}{cmd:,} {it:{help barlook_options:bar_suboptions}}{cmd:)}}look of {it:#}th bar{p_end}
{synopt:{cmdab:int:opts:(}{it:{help upset_barchart_options:{it:barchart_options}}}{cmd:)}}control appearance of intersection bar chart{p_end}
{synopt:{cmdab:set:opts:(}{it:{help upset_barchart_options:{it:barchart_options}}}{cmd:)}}control appearance of set bar chart{p_end}
{synopt:{cmdab:grid:opts:(}{it:{help upset_plot##grid_options:{it:grid_options}}}{cmd:)}}control appearance of grid{p_end}

{syntab:Options}
{synopt:{cmd:sort(}{it:{help upset_plot##sort_rule_or_values:sort_rule_or_values}}{cmd:)}}specify ordering of intersection bars{p_end}
{synopt:{opt keep:first(#)}}display only the first # intersection patterns{p_end}
{synopt:{opt fill:in}}include intersections with zero frequency{p_end}
{synopt:{opt notab:le}}suppress display of intersection and set frequency tables{p_end}

{syntab:Add plots}
{synopt:{cmd:addplot(}{help addplot_option:{it:plot}}{cmd:)}}add other plots to the upset plot{p_end}

{syntab:Titles, Legend, Overall}
{synopt:{help twoway_options}}all options except {it:axis_options}, {it:by()},
and {it:recast()}{p_end}
{synoptline}
{marker weight}{...}
{p 4 6 2}
{opt fweight}s are allowed; see {help weight}.


{marker over_suboptions}{...}
{synoptset 35 tabbed}{...}
{synopthdr:over_suboptions}
{synoptline}
{synopt:{cmd:relabel(}{help upset_plot##over_label_info:over_label_info}{cmd:)}}change {it:varname} value labels{p_end}
{synopt:{cmd:sort(}#[ #[ ...]]{cmd:)}}change order of {it:varname} values{p_end}
{synopt:{cmdab:desc:ending:}}reverse order of {it:varname} values{p_end}
{synoptline}


{marker bar_suboptions}{...}
{synoptset 35 tabbed}{...}
{synopthdr:bar_suboptions}
{synoptline}
{synopt:{cmdab:col:or:(}{it:{help colorstyle}}{cmd:)}}outline and fill color and opacity{p_end}
{synopt:{cmdab:fc:olor:(}{it:{help colorstyle}}{cmd:)}}fill color and opacity{p_end}
{synopt:{cmdab:fi:ntensity:(}{it:{help intensitystyle}}{cmd:)}}fill intensity{p_end}

{synopt:{cmdab:lc:olor:(}{it:{help colorstyle}}{cmd:)}}outline color and opacity{p_end}
{synopt:{cmdab:lw:idth:(}{it:{help linewidthstyle}}{cmd:)}}thickness of outline{p_end}
{synopt:{cmdab:lp:attern:(}{it:{help linepatternstyle}}{cmd:)}}outline pattern (solid, dashed, etc.){p_end}
{synopt:{cmdab:la:lign:(}{it:{help linealignmentstyle}}{cmd:)}}outline alignment (inside, outside, center){p_end}
{synopt:{cmdab:lsty:le:(}{it:{help linestyle}}{cmd:)}}overall look of outline{p_end}

{synopt:{cmdab:bsty:le:(}{it:{help areastyle}}{cmd:)}}overall look of bar, all settings above{p_end}
{synoptline}


{marker grid_options}{...}
{synoptset 35 tabbed}{...}
{synopthdr:grid_options}
{synoptline}
{synopt:{cmdab:onc:olor:(}{it:{help colorstyle:{it:colorstyle}}list}{cmd:)}}color and opacity of active markers{p_end}
{synopt:{cmdab:offc:olor:(}{it:{help colorstyle:{it:colorstyle}}list}{cmd:)}}color and opacity of inactive markers{p_end}
{synopt:{cmdab:mc:olor:(}{it:{help colorstyle}list}{cmd:)}}synonym for {it:oncolor()}{p_end}

{synopt:{cmdab:m:symbol:(}{it:{help symbolstyle}list}{cmd:)}}shape of markers{p_end}
{synopt:{cmdab:msiz:e:(}{it:{help markersizestyle}list}{cmd:)}}size of markers{p_end}
{synopt:{cmdab:msa:ngle:(}{it:{help anglestyle}list}{cmd:)}}angle of marker symbols{p_end}
{synopt:{cmdab:mfc:olor:(}{it:{help colorstyle}list}{cmd:)}}inside or "fill" color and opacities{p_end}
{synopt:{cmdab:mlc:olor:(}{it:{help colorstyle}list}{cmd:)}}outline color and opacities{p_end}
{synopt:{cmdab:mlw:idth:(}{it:{help linewidthstyle}list}{cmd:)}}outline thicknesses{p_end}
{synopt:{cmdab:mla:lign:(}{it:{help linealignmentstyle}list}{cmd:)}}outline alignment(inside, outside, center){p_end}
{synopt:{cmdab:mlsty:le:(}{it:{help linestyle}list}{cmd:)}}thickness and color, overall style of outlines{p_end}
{synopt:{cmdab:msty:le:(}{it:{help markerstyle}list}{cmd:)}}overall style of markers; all settings above{p_end}

{synopt:{cmdab:mlabsty:le:(}{it:{help markerlabelstyle}}{cmd:)}}overall style of {it:varlist} labels{p_end}
{synopt:{cmdab:mlabg:ap:(}{it:{help size}}{cmd:)}}gap between left-most marker and {it:varlist} labels{p_end}
{synopt:{cmdab:mlabang:le:(}{it:{help anglestyle}}{cmd:)}}angle of {it:varlist} labels{p_end}
{synopt:{cmdab:mlabt:extstyle:(}{it:{help textstyle}}{cmd:)}}overall style of {it:varlist} label text{p_end}
{synopt:{cmdab:mlabs:ize:(}{it:{help textsizestyle}}{cmd:)}}size of {it:varlist} labels{p_end}
{synopt:{cmdab:mlabc:olor:(}{it:{help colorstyle}}{cmd:)}}color and opacity of {it:varlist} labels{p_end}
{synopt:{cmdab:mlabf:ormat:(}{it:{help %fmt}}{cmd:)}}format of {it:varlist} labels{p_end}

{synopt:{cmdab:lp:attern:(}{it:{help linepatternstyle}}{cmd:)}}whether vertical grid lines are solid, dashed, etc.{p_end}
{synopt:{cmdab:lw:idth:(}{it:{help linewidthstyle}}{cmd:)}}thickness of vertical grid lines{p_end}
{synopt:{cmdab:lc:olor:(}{it:{help colorstyle}}{cmd:)}}color and opacity of vertical grid lines{p_end}
{synopt:{cmdab:la:lign:(}{it:{help linealignmentstyle}}{cmd:)}}vertical grid line alignment (inside, outside, center){p_end}
{synopt:{cmdab:lsty:le:(}{it:{help linestyle}}{cmd:)}}overall style of vertical grid lines{p_end}
{synoptline}


{marker sort_rule_or_values}{...}
{pstd}
{it:sort_rule_or_values}, the argument allowed by {cmd:sort()}, is defined as:

{p 8 16 2}
[#[ #[ ...]]] [[+|-] sort_rule[ [+|-] sort_rule[ ...]]]
[{cmd:,} {it:sort_suboptions}]

{pmore}
{it:#} is either a base-2 or base-10 representation of one of the patterns defined by {it:varlist}. See {help upset_plot##remarks2:{it:Reordering the bars}} under {it:Remarks} below.

{marker sort_rule}{...}
{synoptset 35 tabbed}{...}
{synopthdr:sort_rule}
{synoptline}
{synopt:{cmdab:p:attern:}}sort by numeric representation of {it:varlist} pattern{p_end}
{synopt:{cmdab:f:requency:}}sort by {it:varlist} pattern frequency{p_end}
{synopt:{cmdab:b:itsum:}}sort by {it:varlist} pattern bit sum{p_end}
{synopt:{cmdab:r:andom:}}sort in random order{p_end}
{synoptline}

{marker sort_suboptions}{...}
{synoptset 35 tabbed}{...}
{synopthdr:sort_suboptions}
{synoptline}
{synopt:{cmd:intwo}}specify that {it:#}s are given in base-2 (the default){p_end}
{synopt:{cmd:inten}}specify that {it:#}s are given in base-10{p_end}
{synoptline}


{marker over_label_info}{...}
{pstd}
{it:over_label_info}, the argument allowed by {cmd:relabel()} within {cmd:over()}, is defined as:

{p 8 16 2}
{it:#} {cmd:"}{it:text}{cmd:"} [{cmd:"}{it:text}{cmd:"} ...] [{it:#} {cmd:"}{it:text}{cmd:"} [{cmd:"}{it:text}{cmd:"} ...] [ ...]]


{marker description}{...}
{title:Description}

{pstd}{cmd:upset_plot} calculates and displays intersection and set frequencies 
for combinations of binary indicator variables in {it:varlist}, using the UpSet
plot design described by Lex et al. (2014).


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt over(varname[, over_suboptions])} specifies a numeric categorical variable
used to stack the intersection and set bars.

{phang}
{opt bar(#, bar_suboptions)} specifies the look of the bars. {opt bar(1, ...)}
refers to the bar associated with the first {cmd:over(varname)} value. If
{opt over()} is not specified, {cmd:bar(1, ...)} controls the look of all bars
in the plot.

{phang}
{opt intopts(barchart_options)} specifies the rendition of the vertical
intersection bar chart. {it:barchart_options} are similar to {it:axis_options}
and {it:title_options} in {it:twoway_options}: full details are provided in
{help upset_barchart_options}.

{phang}
{opt setopts(barchart_options)} specifies the rendition of the horizontal set 
bar chart. {it:barchart_options} are similar to {it:axis_options} and
{it:title_options} in {it:twoway_options}: full details are provided in
{help upset_barchart_options}.

{phang}
{opt gridopts(grid_options)} specifies the look of the markers in the grid. The 
{opt oncolor(colorstylelist)} and {opt offcolor(colorstylelist)} suboptions 
control the color of the active and inactive markers, respectively. All other 
{it:grid_options} apply uniformly to all markers regardless of
active/inactive status.

{dlgtab:Options}

{phang}
{opt sort(sort_rule_or_values)} controls how intersection bars are ordered. By
default, bars are ordered by descending frequency and then by ascending
numeric representation of the corresponding {it:varlist} pattern.

{phang}
{opt keepfirst(#)} displays only the first {it:#} bars in the intersection bar chart.

{phang}
{opt fillin} specifies that intersection patterns with zero frequency should be
displayed in the intersection bar chart. By default, these are excluded.

{phang}
{opt notable} suppress display of intersection and set frequency tables.

{dlgtab:Add plots}

{phang}
{opt addplot(plot)} adds {opt graph twoway} plots to the graph; see {help addplot_option}.

{dlgtab:Titles, Legend, Overall}

{phang}
{it:twoway_options} specifies most options documented in {help twoway_options}, 
including titling (see {help title_options}) and graph saving options (see 
{help saving_option}). 

{pmore}
{cmd:upset_plot} does not support the {cmd:recast()} and {cmd:by()} 
options. The {cmd:{help axis_options}} suboptions will generally have no effect
on plot rendition.


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:

	{help upset_plot##remarks1:Rescaling}
	{help upset_plot##remarks2:Reordering the bars}
	{help upset_plot##remarks3:Other remarks}


{marker remarks1}{...}
{title:Rescaling}

{pstd}
In order to present both bar charts in the same region, {cmd:upset_plot}
significantly rescales the data. The default dimensions are as follows:


			        {bf:Intersection bar chart}
			    {c TLC}{c -}{c TRC}				     {c -}{c TRC}
			    {c |} {c |}				      {c |}
			    {c |} {c |}				      {c |}
			    {c |} {c |}				      {c |}
			    {c |} {c |} {c TLC}{c -}{c TRC}			      {c |}
			    {c |} {c |} {c |} {c |}			      {c |}
			    {c |} {c |} {c |} {c |} {c TLC}{c -}{c TRC}			      {c |}ysize(3)
			    {c |} {c |} {c |} {c |} {c |} {c |} {c TLC}{c -}{c TRC} {c TLC}{c -}{c TRC}		      {c |}
			    {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |}		      {c |}
			    {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c TLC}{c -}{c TRC} {c TLC}{c -}{c TRC}	      {c |}
			    {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c TLC}{c -}{c TRC}   {c |}
			    {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |} {c |}   {c |}
			    {c BLC}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BT}{c -}{c BRC}  {c -}{c BRC} {c -}{c TRC}
	   {bf:set bar chart}				{space 14}{c |}gap(0.1)
	    {c TLC}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c TRC}				         {c -}{c TRC} {c -}{c BRC}
	    {c BLC}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c RT}     {c 176}   {c 176}   {c 176}   {c 176}   {c 176}   {c 176}   {c 176}   {c 176}    {c |}
	         {c TLC}{c -}{c -}{c -}{c -}{c -}{c RT}				  	     {c |}
	         {c BLC}{c -}{c -}{c -}{c -}{c -}{c RT}     {c 176}   {c 176}   {c 176}   {c 176}   {c 176}   {c 176}   {c 176}   {c 176}    {c |}1
	      {c TLC}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c RT}				         {c |}
	      {c BLC}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c BRC}     {c 176}   {c 176}   {c 176}   {c 176}   {c 176}   {c 176}   {c 176}   {c 176}	 {c -}{c BRC}

	    {c BLC}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c BRC}{space 4}{c BLC}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c -}{c BRC}
	{space 5}ysize(0.5)		        1
		{space 7}{c BLC}{c -}{c -}{c -}{c -}{c BRC}
		{space 7}gap(0.2)


{pstd}
The point of intersection between the vertical axis in the intersection bar chart
and the horizontal axis in the set bar chart is the point {it:(0,0)} on the
original axes. All listed dimensions – except the width and height of the 
grid – can be changed using {opt intopts()} and {opt setopts()}.

{pstd}
Added lines, text, and plots may need rescaling to appear as intended.


{marker remarks2}{...}
{title:Reordering the bars}

{pstd}
The order of bars in the set bar chart is determined by the order they are 
supplied to {cmd:upset_plot}. The order of bars in the intersection bar chart is 
determined by the {opt sort()} option.

{pstd}
{opt sort()} allows the user to order specific bars according to their
base-2 or base-10 representations, and/or to order them by their {opt frequency}, 
{opt pattern} (the numeric representation of {it:varlist} patterns), or
{opt bitsum} (the number of nonzero bits in the base-2 representations of
{it:varlist} patterns). 

{pstd}
You may prefix {opt frequency}, {opt pattern}, and {opt bitsum} with a {cmd:+}
or {cmd:-} to sort them in ascending or descending order, respectively.

{pstd}
The default {opt sort()} behavior is {opt -frequency pattern} (that is, bars are
ordered first by decreasing frequency and then by increasing numeric value).


{marker remarks3}{...}
{title:Other remarks}

{pstd}
Sorting is performed before {opt keepfirst()} executes. Bars omitted by the
{opt keepfirst()} option are counted in the set frequencies.

{pstd}
The set bar chart is rendered such that its y-axis is horizontal. Changes to
set bar chart size, ticks, tick labels, or titles must be done through 
{opt ysize()}, {opt yscale()}, {opt ylabel()}, or {opt ytitle()}, as appropriate.

{pstd}
Because each axis element is rendered separately, {opt yscale(off)} does not 
suppress ticks, tick labels, or titles as it does in standard {cmd: twoway}
graphs: these can be suppressed using {opt ylabel()} and {opt ytitle()}, if 
needed.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use upset_plot_dataex}{p_end}

{pstd}Create an upset plot for patterns defined by {bf:a}, {bf:b}, {bf:c}, {bf:d}{p_end}
{phang2}{cmd:. upset_plot a b c d}{p_end}
	  {it:({stata "_upsetexample 0":click to run})}

{pstd}Same as above, but now over values defined by variable {bf:over}{p_end}
{phang2}{cmd:. upset_plot a b c d, over(over)}{p_end}
	  {it:({stata "_upsetexample 1":click to run})}

{pstd}Same as above, but with pretty colors{p_end}
{phang2}{cmd:. upset_plot a b c d, over(over) bar(1, color(stc2)) bar(2, color(stc2*0.66)) bar(3, color(stc2*0.33))}{p_end}
	  {it:({stata "_upsetexample 2":click to run})}

{pstd}Repeating the first plot, but with a modified grid{p_end}
{phang2}{cmd:. upset_plot a b c d, gridopts(msymbol(O S D T) oncolor(stc2 stc2 stc2 stc2))}{p_end}
	  {it:({stata "_upsetexample 3":click to run})}

{pstd}Repeating the first plot, but with percentage bar labels and no axis lines{p_end}
{phang2}{cmd:. local plotsyn yscale(off) ylabel(none) ytitle("") xscale(off) blabel(total)}{p_end}
{phang2}{cmd:. upset_plot a b c d, intopts(`plotsyn') setopts(`plotsyn')}{p_end}
	  {it:({stata "_upsetexample 4":click to run})}

{pstd}Repeating the first plot, but with user-specified tick placement{p_end}
{phang2}{cmd:. upset_plot a b c d, intopts(ylabel(0(100)500)) setopts(ylabel(#3))}{p_end}
	  {it:({stata "_upsetexample 5":click to run})}

{pstd}Repeating the first plot, but with 0000 placed first and subsequent bars ordered by decreasing bit sum and then by increasing frequency, with empty bars shown{p_end}
{phang2}{cmd:. upset_plot a b c d, fillin sort(0000 -bitsum frequency)}{p_end}
	  {it:({stata "_upsetexample 6":click to run})}

{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:upset_plot} stores the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(n_var)}}number of binary indicator variables{p_end}
{synopt:{cmd:r(n_over)}}number of distinct values of {opt over(varname)}{p_end}

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:upset_plot}{p_end}
{synopt:{cmd:r(cmdline)}}command as typed{p_end}
{synopt:{cmd:r(varlist)}}binary indicator variables{p_end}
{synopt:{cmd:r(overvar)}}categorical over variable{p_end}

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:r(intmatrix)}}intersection matrix{p_end}
{synopt:{cmd:r(setmatrix)}}set matrix{p_end}

{phang}
Note that results stored in {cmd:r()} are updated when the command is replayed
and will be replaced when any r-class command is run after the estimation command.


{marker references}{...}
{title:References}

{phang}
Lex, A., Gehlenborg, N., Strobelt, H., Vuillemot, R., & Pfister, H. (2014). UPSET:
Visualization of intersecting sets. IEEE Transactions on Visualization and Computer
Graphics, 20(12), 1983–1992. {browse "https://www.doi.org/10.1109/tvcg.2014.2346248"}


{marker authors}{...}
{title:Authors}

{pstd}
Dylan Taylor, London School of Hygiene and Tropical Medicine, London{break}
dylanjamestaylor00@gmail.com
