{smcl}
{* February 2023}{...}
[CLASSO] {bf:classocoef} ——  Plot the coefficients after classifylasso.


{title:Syntax}

{p 8 15 2} {cmd:classocoef} [{indepvars}] [, options] {p_end}

{phang}{indepvars} must be independent variables used by {cmd:classifylasso}; if omitted, then all indepvars are input. One graph is generated for each input variable.

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{synopt: {help classocoef##global_twoway_options:global_twoway_options}}control the overall style; applies to all graphs{p_end}
{synopt: {help classocoef##groupcoef_line_options:groupcoef_line_options}}control the Lasso estimation coefficient line{p_end}
{synopt: {help classocoef##groupci_line_options:groupci_line_options}}control the confidence interval line{p_end}
{synopt: {help classocoef##tscoef_scatter_options:tscoef_scatter_options}}control the scatters of time series estimates{p_end}
{synopt: {help classocoef##zero_line_options:zero_line_options}}control the horizontal zero line{p_end}
{synoptline}


{marker global_twoway_options}{...}
{synoptset 35}{...}
{p2coldent :{it:global_twoway_options}}Description{p_end}
{synoptline}
{synopt :{opth col:ors(string)}}color list of each group; the default is "maroon dkorange sand forest_green navy"{p_end}
{synopt :{opt ti:tle(tinfo)}}overall title; the default is "Coefficient Plot of varname"{p_end}
{synopt :{opt sub:title(tinfo)}}subtitle of title; the default is "Number of Individuals: N; Number of Groups: group"{p_end}
{synopt :{opt leg:end([contents] [location])}}standard legend, contents and location; the default is off, and should not be modified{p_end}
{synopt :{opt yti:tle(axis_title)}}specify y-axis title; the defalut is "Coefficient of varname"{p_end}
{synopt :{opt xti:tle(axis_title)}}specify x-axis title; the defalut is "Individual ID"{p_end}
{synopt :{opt ylab:el(rule_or_values)}}major ticks plus labels; the default is ",nogrid"{p_end}
{synopt :{opt xlab:el(rule_or_values)}}major ticks plus labels; the default is "1(step)N", where step = ceil(N/20){p_end}
{synopt :{opth name(name_option)}}specify name; applies to all graphs; the default is "coefficient_varname"{p_end}
{synopt :{opth saving(saving_option)}}save graph to disk; applies to all graphs; the default is not to save if not specified{p_end}
{synopt :{opth export(name [, options])}}export graph to disk; applies to all graphs; the default is not to export if not specified{p_end}
{synopt :{opth scheme(schemename)}}specify the overall look of the graph; the default is controled by {opt set scheme}{p_end}
{synopt :{opth twopt:ions(twoway_options)}}additional option for the graph{p_end}
{synopt :{opt nowin:dow}}suppress the graph window{p_end}
{synoptline}


{marker groupcoef_line_options}{...}
{synoptset 35}{...}
{p2coldent :{it:groupcoef_line_options}}Description{p_end}
{synoptline}
{synopt :{opt nocoef:plot}}suppress the group estimation coefficients line{p_end}
{synopt :{opth coeflw:idth(linewidthstyle)}}width of group estimation coefficient line; the default is 1{p_end}
{synopt :{opth coeflp:attern(linepatternstyle)}}pattern of group estimation coefficient line; the default is solid{p_end}
{synopt: {opt coefopt:ions(line_options)}}additional option for the group estimation coefficient line{p_end}
{synoptline}


{marker groupci_line_options}{...}
{synoptset 35}{...}
{p2coldent :{it:groupci_line_options}}Description{p_end}
{synoptline}
{synopt :{opt noci:plot}}suppress the confidence interval line{p_end}
{synopt :{opth l:evel(#)}}specify the confidence level, as a percentage, for confidence intervals;
the default is controled by {opt set level}{p_end}
{synopt :{opth cilw:idth(linewidthstyle)}}width of the confidence interval lines; the default is 0.5{p_end}
{synopt :{opth cilp:attern(linepatternstyle)}}pattern of the confidence interval lines; the default is dash{p_end}
{synopt: {opt ciopt:ions(line_options)}}additional option for the confidence interval lines{p_end}
{synoptline}


{marker tscoef_scatter_options}{...}
{synoptset 35}{...}
{p2coldent :{it:tscoef_scatter_options}}Description{p_end}
{synoptline}
{synopt :{opt nots:scatter}}suppress the scatters of time series estimates{p_end}
{synopt: {opth tsms:ize(markersize)}}size of time series estimation coefficients scatters; default is 0.5{p_end}
{synopt: {opt tsopt:ions(scatter_options)}}additional option for the time series estimaion scatters{p_end}
{synoptline}


{marker zero_line_options}{...}
{synoptset 35}{...}
{p2coldent :{it:zero_line_options}}Description{p_end}
{synoptline}
{synopt :{opt nozero:line}}suppress the zero line{p_end}
{synopt: {opth zerolw:idth(linewidthstyle)}}width of the horizontal zero line; default is 0.5{p_end}
{synopt :{opth zerolp:attern(linepatternstyle)}}pattern of the horizontal zero line; the default is solid{p_end}
{synopt :{opth zerolc:olor(colorstyle)}}color of the horizontal zero line; the default is solid{p_end}
{synopt: {opt zeroopt:ions(line_options)}}additional option for the horizontal zero line{p_end}
{synoptline}


{title:Description}

{p 4 4 2}{cmd:classocoef} utilizes {cmd:graph twoway} to visualize the estimated coefficients. 
Each independent variables corresponds to one graph. 
For each graph, the y-axis and x-axis respectively indicates the value of coefficient and the individual id. 
In the graph, there are four major elements: 

{p 8 8 2}1. Lasso group coefficient line: The C-Lasso or post-Lasso estimates of each individual. Note that the individuals on the x-axis are clusterd by groups, so within each group, the coefficient forms a line.

{p 8 8 2}2. Confidence interval line: The confidence interval of the C-Lasso or post-Lasso estimates of each individual.

{p 8 8 2}3. Scatters of time series estimates: for each individual, the time series estimation results are obtained. The coefficients are visualized as scatters.

{p 8 8 2}4. Horizontal zero line: for direct visualization of significance.


{marker options}{...}
{title:Options}

{phang}{it: global_twoway_options} specify how the overall style looks like, such as titles, axis labels, colors of each group, etc. 
See {helpb twoway_options:[G-3] twoway_options} for detailed description.
Note that the options apply to all graphs.

{pmore}{opt title()}, {opt subtitle()}, {opt legend()}, {opt ytitle()}, {opt xtitle()}, {opt ylabel()}, and {opt xlabel()} are the same two-way options 
as in {helpb title_options:[G-3] title_options}, {helpb legend_options:[G-3] legend_options} and {help axis_options:[G-3] axis_options}.

{pmore}{opt name()} {opt saving()}, {opt export()}, and {opt scheme()} specify the graph name, the save path, the export name, or overall look,
as {helpb name_option:[G-3] name_option}, {helpb saving_option:[G-3] saving_option}, {helpb graph export:[G-2] graph export}, {helpb schemes: [G-4] Schemes intro}. 
Note that if there are more than one graph to be generated, modifying these options may cause error.

{pmore}{opt twoptions()} specifies additional {helpb twoway_options:[G-3] twoway_options} other than above if needed. To modify the above nine options, please do not use {opt twoptions()}. Use it only when the above is not enough.

{pmore}{opt colors()} specifies the color list of each group. 
The color of all elements except the zero line is controled by this option.
Each color should follow {help colorstyle:[G-4] colorstyle}, and different colors are separated by space. 
Suppose you input {it:M} colors, 
let {it:Color(M,k) = k(mod)M} if {it:k(mod)M > 0} and {it:= M} otherwise, 
then the {it:k^th} group is visualized by the {it:Color(M,k)^th} color. 

{pmore}{opt nowindow} suppresses the graph window.

{phang}{it: groupcoef_line_options} specify the style of the Lasso group estimation coefficient line. 
See {helpb line:[G-2] graph twoway line} for detailed description.

{pmore}{opt nocoefplot} suppresses the group estimation coefficient line. 

{pmore}{opt coeflwidth()} and {opt coeflpattern()} specify the line style as in {helpb connect_options:[G-3] connect_options}.

{pmore}{opt coefoptions()} specifies additional options in {helpb line:[G-2] graph twoway line} for the group coefficient line other than above if needed. Note that to modify the above two options or the line color, please do not use {opt coefoptions()}.

{phang}{it: groupci_line_options} specify the style of the confidence interval line. 
See {helpb line:[G-2] graph twoway line} for detailed description.

{pmore}{opt nociplot} suppresses the confidence interval line. 

{pmore}{opt level()} specifies the confidence level, as a percentage, for confidence intervals. 
The default is controled by {opt set level}; see {helpb estimation options##level():[R] Estimation options}.

{pmore}{opt cilwidth()} and {opt cilpattern} specify the line style as in {helpb connect_options:[G-3] connect_options}.

{pmore}{opt cioptions()} specifies additional options in {helpb line:[G-2] graph twoway line} for the confidence interval line other than above if needed. Note that to modify the above two options or the line color, please do not use {opt cioptions()}.

{phang}{it: tscoef_scatter_options} specify the style of the scatters of time series estimates. 
See {helpb scatter:[G-2] graph twoway scatter} for detailed description.

{pmore}{opt notsscatter} suppresses the scatters of time series estimates. 

{pmore}{opt tsmsize()} specifies the scatter size as in {helpb marker_options:[G-3] marker_options}.

{pmore}{opt tsoptions()} specifies additional options in {helpb scatter: [G-2] graph twoway scatter} for the scatters of time series estimates other than above if needed. Note that to modify the above option, please do not use {opt tsoptions()}.

{phang}{it: zero_line_options} specify the style of the horizontal zero line. 
See {helpb line: [G-2] graph twoway line} for detailed description.

{pmore}{opt nozeroline} suppresses the horizontal zero line. 

{pmore}{opt zerolwidth()}, {opt zerolpattern()}, and {opt zerolcolor()} specify the line style as in {helpb connect_options:[G-3] connect_options}.

{pmore}{opt zerooptions()} specifies additional options in {helpb line:[G-2] graph twoway line} for the horizontal zero line other than above if needed. Note that to modify the above three options, please do not use {opt zerooptions()}.

