{smcl}
{* February 2023}{...}
[CLASSO] {bf:classogroup} ——  Plot the group selection information after classifylasso.


{title:Syntax}

{p 8 15 2} {cmd:classogroup} [, options] {p_end}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{synopt: {help classogroup##global_twoway_options:global_twoway_options}}control the overall style{p_end}
{synopt: {help classogroup##icplot_options:icplot_options}}control the information criterion plot{p_end}
{synopt: {help classogroup##iterplot_options:iterplot_options}}control the iteration number plot{p_end}
{synoptline}


{marker global_twoway_options}{...}
{synoptset 36}{...}
{p2coldent :{it:global_twoway_options}}Description{p_end}
{synoptline}
{synopt :{opt ti:tle(tinfo)}}overall title; the default is "Detail of Group Number Selection"{p_end}
{synopt :{opt sub:title(tinfo)}}subtitle of title; the default is "Maximum Number of Groups: maxgroup; Chosen Number of Groups: group"{p_end}
{synopt :{opt ytitle1(axis_title)}}specify y-axis(1) title; the defalut is "Information Criterion"{p_end}
{synopt :{opt ytitle2(axis_title)}}specify y-axis(2) title; the defalut is "Number of Iterations"{p_end}
{synopt :{opt ylabel1(rule_or_values)}}specify y-axis(1) label; the defalut is adapted by Stata{p_end}
{synopt :{opt ylabel2(rule_or_values)}}specify y-axis(2) label; the defalut is "0(5)maxIter"{p_end}
{synopt :{opt xti:tle(axis_title)}}specify x-axis title; the defalut is "Number of Groups"{p_end}
{synopt :{opt xlab:el(rule_or_values)}}major ticks plus labels; the default is "1(1)numK"{p_end}
{synopt :{opth name(name_option)}}specify name; the default is "selection"{p_end}
{synopt :{opth saving(saving_option)}}save graph to disk; the default is not to save if not specified{p_end}
{synopt :{opt export(name [, options])}}export graph to disk; the default is not to export if not specified{p_end}
{synopt :{opth scheme(schemename)}}specify the overall look of the graph; the default is controled by {opt set scheme}{p_end}
{synopt :{opth twopt:ions(twoway_options)}}additional option for the graph{p_end}
{synopt :{opt nowin:dow}}suppress the graph window{p_end}
{synoptline}


{marker icplot_options}{...}
{synoptset 36}{...}
{p2coldent :{it:icplot_options}}Description{p_end}
{synoptline}
{synopt :{opt noic:plot}}suppress the information criterion plot{p_end}
{synopt :{opth iclw:idth(linewidthstyle)}}line width; the default is 0.5{p_end}
{synopt :{opth iclp:attern(linepatternstyle)}}line pattern; the default is solid{p_end}
{synopt :{opth iclc:olor(colorstyle)}}line color; the default is black{p_end}
{synopt: {opth icms:ize(markersize)}}scatter size; the default is 2{p_end}
{synopt: {opth icmc:olor(colorstyle)}}scatter color; the default is black{p_end}
{synopt: {opth icc:onnect(connectstyle)}}style of connected line; the default is direct{p_end}
{synopt: {opt icopt:ions(scatter_options)}}additional options{p_end}
{synopt: {opt icleg:end([contents] [locations])}}legend for the plot; the default is "Information Criterion"{p_end}
{synoptline}


{marker iterplot_options}{...}
{synoptset 36}{...}
{p2coldent :{it:iterplot_options}}Description{p_end}
{synoptline}
{synopt :{opt noiter:plot}}suppress the iteration plot{p_end}
{synopt :{opth iterlw:idth(linewidthstyle)}}line width; the default is 0.5{p_end}
{synopt :{opth iterlp:attern(linepatternstyle)}}line pattern; the default is dash{p_end}
{synopt :{opth iterlc:olor(colorstyle)}}line color; the default is blue{p_end}
{synopt: {opth iterms:ize(markersize)}}scatter size; the default is 2{p_end}
{synopt: {opth itermc:olor(colorstyle)}}scatter color; the default is blue{p_end}
{synopt: {opth iterc:onnect(connectstyle)}}style of connected line; the default is direct{p_end}
{synopt: {opt iteropt:ions(scatter_options)}}additional options{p_end}
{synopt: {opt iterleg:end([contents] [locations])}}legend for the plot; the default is "Number of Iterations"{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{p 4 4 2}{cmd:classogroup} utilizes {cmd:graph twoway} to visualize the group number selection information in one graph.
The x-axis indicates the group number.
Both information criterion and number of iterations are ploted, which are respectively measured by y-axis(1) and y-axis(2).
For each element, both line and scatter plot is allowed.


{marker options}{...}
{title:Options}

{phang}{it: global_twoway_options} specify how the overall style looks like, such as titles, axis labels, etc. 
See {helpb twoway_options:[G-3] twoway_options} for detailed description.

{pmore}{opt title()}, {opt subtitle()}, {opt ytitle1()}, {opt ytitle2()}, {opt ylabel1()}, {opt ylabel2()} {opt xtitle()}, and {opt xlabel()} are the same two-way options 
as in {helpb title_options:[G-3] title_options}, {helpb legend_options:[G-3] legend_options} and {help axis_options:[G-3] axis_options}.

{pmore}{opt name()} {opt saving()}, {opt export()}, and {opt scheme()} specify the graph name, the save path, the export name, or overall look,
as {helpb name_option:[G-3] name_option}, {helpb saving_option:[G-3] saving_option}, {helpb graph export:[G-2] graph export}, {helpb schemes: [G-4] Schemes intro}. 

{pmore}{opt twoptions()} specify additional {helpb twoway_options:[G-3] twoway_options} other than above if needed. 
To modify the above eight options, please do not use {opt twoptions()}. Use it only when the above is not enough.

{pmore}{opt nowindow} suppress the graph window.

{phang}{it: icplot_options} specify how the the style of the information criterion plot.
See {helpb scatter:[G-2] graph twoway scatter} for detailed description.

{pmore}{opt noicplot} suppresses the corresponding plot. 

{pmore}{opt iclpattern()},{opt iclcolor()},{opt icmsize()},{opt icmcolor()},{opt icconnect()} 
specify the line pattern, line color, scatter size, scatter color, connect style
as in {helpb connect_options:[G-3] connect_options} and {helpb marker_options:[G-3] marker_options}.

{pmore}{opt icoptions()} specifies additional options in {helpb scatter: [G-2] graph twoway scatter} for the corresponding plot other than above if needed. Note that to modify the above option, please do not use {opt icoptions()}.

{pmore}{opt iclegend()} specifies the legend of the information criterion plot as {helpb legend_options:[G-3] legend_options}.

{phang}{it: iterplot_options} specify how the the style of the iteration plot.
See {helpb scatter:[G-2] graph twoway scatter} for detailed description.

{pmore}{opt noiterplot} suppresses the corresponding plot. 

{pmore}{opt iterlpattern()},{opt iterlcolor()},{opt itermsize()},{opt itermcolor()},{opt iterconnect()} 
specify the line pattern, line color, scatter size, scatter color, connect style
as in {helpb connect_options:[G-3] connect_options} and {helpb marker_options:[G-3] marker_options}.

{pmore}{opt iteroptions()} specifies additional options in {helpb scatter: [G-2] graph twoway scatter} for the corresponding plot other than above if needed. Note that to modify the above option, please do not use {opt iteroptions()}.

{pmore}{opt iterlegend()} specifies the legend of the corresponding plot as {helpb legend_options:[G-3] legend_options}.
