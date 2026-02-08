{smcl}
{hline}
help for {hi:hammock}{right:{hi: Matthias Schonlau}}
{hline}


{title:Title}

{p2colset 5 23 25 2}{...}
{p2col :{cmd:hammock} {hline 2}} Hammock plot for visualizing categorical and numeric data {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:hammock} {varlist} {ifin} {cmd:,}  [ {it:options}  ]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab :Highlighting}
{synopt :{opt hivar:iable(varname)}} Name of variable to highlight {p_end}
{synopt :{opt hival:ues(string)}}  List of values of {it:hivariable} to highlight {p_end}
{synopt :{opt col:orlist(string)}} Default color and colors for highlighting {p_end}
{synopt :{opt uni_colorlist(string)}} Default color and colors for highlighting for univariate bars {p_end}

{syntab :Layout of univariate bars}
{synopt :{opt nouni:bar}} Do not show univariate bars {p_end}
{synopt :{opt uni_fraction(real)}} For univariate bars, proportion of vertical space covered with bars {p_end}

{syntab :Layout of labels}
{synopt :{opt nolab:el}} Do not show value labels  {p_end}
{synopt :{opt label_methodlist(string)}} Specify individual labeling methods for each variable {p_end}
{synopt :{opt label_too_many(int)}} When variable has at least {it:label_too_many unique} values, show only only min and max label  {p_end}
{synopt :{opt label_min_dist(#)}} For method {it:min_dist}, show only labels that are at least {it:label_min_dist} far apart {p_end}
{synopt :{opt labelopt(string)}} Pass options to {it:{help added_text_options}}, e.g. to manipulate label text size{p_end}
{synopt :{opt label_format(string)}} Display format of numeric labels {p_end}

{syntab :Missing values}
{synopt :{opt m:issing}} Show missing values {p_end}
{synopt :{opt missing_fraction(real)}} Proportion of vertical space allocated to missing values {p_end}

{syntab :Layout of connectors in between axes}
{synopt :{opt bar:width(#)}} Change width of the connectors to reduce clutter {p_end}
{synopt :{opt minbar:freq(int)}} Specify minimum connector width {p_end}
{synopt :{opt shape(string)}} connector shape: "parallelogram" (also "par") or "rectangle" (default) {p_end}
{synopt :{opt outline}} (rarely needed) Outline the edges of semi-translucent connectors {p_end}

{syntab :Other options}
{synopt :{opt spa:ce(real)}} Control fraction of space allocated to labels/univ. bars rather than to connectors {p_end}
{synopt :{opt same:scale(varlist)}} Use the same axis scale for each variable specified {p_end}
{synopt :{opt subspace(real)}} (rarely needed) adjust empty space between univariate bars and connectors {p_end}
{synopt :{opt aspect:ratio(#)}} (rarely needed) Aspect ratio of the plot region {p_end}
{synopt :graph_options} Specify additional options passed to  {it:graph, twoway}  {p_end}
{synoptline}



{title:Description}

{pstd}{cmd:hammock} draws a graph to visualize categorical and numeric data. 
The hammock plot uses parallel axes. 
On each axis, marginal frequencies are represented with a stacked barchart (with space in between the bars).
Between axes,  adjacent variables are connected with connectors (parallelograms or rectangles). 
The "width" of a connector is proportional to 
the number of observations that correspond to that connector (i.e. have the same 
values/categories for the two variables). The "width" of a connector refers to the 
distance between the longer set of parallel lines, rather than the vertical distance.  
The proportionality constant can be controlled through the option {it:barwidth}.

{pstd} 
If the connectors degenerate to a single line, and no labels or missing values are used 
the hammock plot corresponds to a parallel coordinate plot. Connectors degenerate into a single
line if {it:barwidth} is so small that the connectors connecting 
categorical variables appear to be a single line. For continuous variables, connectors 
will usually appear to be a single line because each category typically
 only contains one observation.

{pstd} The order of variables in {it:varlist} determines the order of variables in the graph.  
All variables in {it:varlist} must be numeric, but value labels can be used to assign labels to values. 
String variables should be 
converted to numeric variables first, e.g. using {cmd: encode} or {cmd: destring}. 
Each axis is labeled with the corresponding variable name or variable label, if specified. 

{title:Installation}
{phang} 
Installation via the {browse "https://github.com/schonlau/hammock-stata":Github repository}.  
The Github version may be more recent than the version on SSC.

{phang2} 
{cmd: . net install hammock, from("https://raw.githubusercontent.com/schonlau/hammock-stata/main/installation/")  replace }

{phang} 
Installation via SSC: 

{phang2}
{cmd:. ssc install hammock, replace} 


{title:Options}

{dlgtab:Highlighting}

{phang}
{opt hivariable(varname)} specifies which variable is highlighted. {it:hivalues}
can be used to specify which individual categories to highlight. 
A value that is highlighted appears in a different color and observations in this 
category can be traced through the entire graph. 
{it:hivariable } does not have to be part of {it:varlist}.
If so, it can also be a string variable.

{phang}
{opt hivalues(string)}
specifies which values of {it:hivariable} are highlighted.
{it:hivalues} allows either a numlist, 
a scalar preceded by ">=","<=",">" or "<", 
or a string when highlighting a string variable. 

{pmore}
{it:hivalues} as a numlist: 
To highlight multiple values of {it:hivariable}, specify, for example, {it:hivalues(4 9)}. 
Values 4 and 9 are assigned the second and third color in {it:colorlist}, respectively. 
(If desired, the second and third color may be the same color.) 
All values except 4 and 9 use the default color, the first color in {it:colorlist}. 
To highlight a single value of {it:hivariable}, specify, for example, {it:hivalues(4)}. 
To highlight missing values of {it:hivariable}, specify {it:hivalues(.)}

{pmore}
{it:hivalues} with ">","<",">=","<=" comparisons: For example, {it:hivalues(>=3)} highlights all values greater than or equal to 3 
using the same color  (the second color in {it:colorlist}).  When using ">" or ">=", missing values are not highlighted.

{pmore}
{it:hivalues} may specify strings or partial matches when {it:hivariable} is a string variable. 
For example, for the Shakespeare data set, {it:hivar(play_name)} {it:hivalues(Richard Mac)} 
highlights all plays that contain "Richard" in one color and those that contain "Mac" in another color.
Note 1: It is not possible to highlight a single string that contains a space like "Tedej Pogacar". 
The program will treat this as two strings. Just highlight "Pogacar" instead.  
Note 2: It is possible to highlight strings of a string variable as long as the string variable does not appear in the 
hammock plot.  If you want to show the variable in the plot, 
use {it:encode} to encode the variable as numeric with a string label.

{pmore}
Because variables in {it:varlist} must be numeric (with optional string labels), 
this is only relevant if the {it:hivar} is NOT part of {it:varlist}.

{pmore}
{it:hivalues} is ignored if {it:hivariable} is not specified. If more than 8 values/strings are specified, colors are recycled.

{phang}
{opt colorlist(string)} specifies a list of colors to be used.  
The first color in the list is the default color, the remainder is used for highlighting. 
If unspecified, the color list is "ltblue sandb lavender ltbluishgray eggshell". 
Color names are explained in {it:{help colorstyle}}. 
{it:colorlist} accepts RGB values as in colorlist(`" "127 201 127" "190 174 212" "253 192 134" "')
 but note the needed space between the compound quote and the regular quotes.
The color list must not be shorter than the number of values to be highlighted plus one (default color).

{phang}
{opt uni_colorlist(string)} specifies different colors to be used for univariate bars. By default, the first (default) color is {it:gray%20}, 
and the highlighting colors are as specified in {it:colorlist}. 
If you specify your own list, remember the first color is the default color 
and the second color is the first highlighting color.
To avoid univariate bars altogether, specify {it:uni_colorlist(bg)} 
or {it:uni_colorlist(bg bg)} if there is one highlighting color.
({it:bg} stands for background color, the bars will be invisible).


{dlgtab:Layout of univariate bars}

{phang} {opt nounibar} 
requests value univariate bars not be displayed on the graph. 

{phang}
{opt uni_fraction(real)} For univariate bars, {it:uni_fraction} specifies the proportion of vertical space covered with bars. 
By default, {it:uni_fraction(0.5)}. This option can be used to avoid overlapping univariate bars
or to improve layout according to user taste.


{dlgtab:Layout of labels}

{phang} {opt nolabel} 
requests that value {it:{help labels}}  
 not be displayed on the graph. For variables for which value labels are not defined,  
the values themselves are displayed. This makes it easier to identify which category
is displayed where.

{phang} {opt label_methodlist(string)}  specifies individual labeling methods for each variable. The argument is a list of methods of the same length as {it:varlist}. Available methods are: 
{it:none}, {it:all}, {it:minmax}, {it:min_dist}.
{it:minmax} plots only the two labels for minimum and maximum values at the bottom and top of the corresponding axis.
{it:min_dist} plots all labels unless they get too close to each other as specified in option {it:label_min_dist(#)}. 
Example usage when {it:varlist} contains 4 variables: {it:label_methodlist(minmax all all min_dist)}. If {it:label_methodlist} is not specified, by default all labels are shown unless a variable has {it:label_too_many(#)} or more values, and then only minimum and maximum are shown. {p_end}

{phang} {opt label_too_many(int)}  For variables with fewer or equal to {it:label_too_many(#)} labels, show all labels. Otherwise, show only labels for the minimum and maximum values. By default, {it:label_too_many(8)}. When specifying {it:label_methodlist(string)}, this option is ignored. {p_end}

{phang}
{opt label_min_dist(#)} specifies the minimum distance between two labels on the same axis.
A label is associated with each unique value of a variable.  
When (numeric) variables have values close to each other, overplotting of labels may occur.  
This option prevents overplotting by selectively suppressing some labels. 
The bottommost label is always plotted, and any additional label above it is only plotted if 
it is at least {it:label_min_dist(#)} away from the closest label below.  
Labels are plotted on a scale from 0 (bottom label) to 100 (top label). 
By default, a label must be at least 3 units (out of 100) away from the closest label below.
Specifying {it:label_min_dist(0)} will plot all labels.
Specifying {it:label_min_dist(100)} will plot only the bottom and the top label.
This option has no effect unless {it:min_dist}  is specified in {it:label_methodlist(string)}.

{phang}
{opt label_format(string)}  For numeric labels, display format of the numeric value. 
By default,   {it:label_format(%6.0g)}. 
See {it:{help format}} for other display formats.
This option has no effect on string labels.
  
{phang}
{opt labelopt} specifies optional arguments to the labels.
The arguments are passed  to {it:{help added_text_options}}. 
This can be used to manipulate the text sizes of the labels, for example, {it:labelopt(size(vsmall))}.
Text size names are explained in {it:{help textsizestyle}}. 
By default, label size is "medium". If option {it:nolabel} is specified,  option {it:labelopt} is ignored. 


{dlgtab:Missing values}

{phang}
{opt missing} specifies that missing value is a separate category. 
The missing-value category is always the lowest category drawn at 
the bottom of the graph. 
If this option is not specified, observations with missing values are ignored.

{phang}
{opt missing_fraction(real)} specifies the proportion of vertical space allocated to missing values. By default, {it:missing_fraction(0.1)}.
When the proportion of missing values is so large that the missing value bars overlap with bars above,
this option can be used to increase the space allocated to missing values and thereby prevent such overlap. {p_end}


{dlgtab:Layout of connectors in between axes}
 
{phang}
{opt barwidth(#)} specifies the width of the bars relative to the default width.
 This can reduce visual clutter.  
 The relative width of any two bars is not affected.  For example, 0.5 means half as large as the default width.
  The default is 1.0. The value of {it:barwidth} should be greater than 0, 
  and in most cases should be smaller than or equal to 1.0.

{phang}
{opt minbarfreq(int)} specifies the minimum width of the bars.
 If a bar is barely visible because it contains too few observations, 
 it may be useful to increase the width of bars that are barely visible. 
 The minimum bar width is not specified directly; 
 instead all frequencies below the specified minimum are increased. 
 All bars corresponding to fewer than {it:minbarfreq} observations are displayed as if they contained {it:minbarfreq} observations.
 By default, {it:minbarfreq} equals 1 observation.  
 In other words, by default this option has no effect.
 
{pmore}
 During highlighting, bars may consist of multiple segments with different colors. 
 In that case, {it:minbarfreq} is applied to each color segment separately.  
 Currently, this option has no effect on the univariate bars.

{phang}
{opt shape(string)} refers to the shape of the connectors. 
The two options are "parallelogram" (or "par" for short) and "rectangle" (default).  Rectangles can look better for steep angles. 
They also avoid the so-called reverse line-width illusion of the parallelogram: 
The vertical width of parallelograms with steep angles is larger than that of parallelograms with smaller angles. 
Focusing on the end points of the parallelogram can create the illusion that there are more observations in steep-angled parallelograms
than actually exist. 
The main advantage of "parallelogram" is that the plot will render faster.

{phang}
{opt outline}  In Stata, translucent bars or connectors (e.g. "red%50" , where the color is 50% translucent) 
are drawn with an outline that is not translucent.
If there are several overlapping colors, it may be visually simpler to show the translucent connector  
without outlining the edges of the connector. This option adds the outline back in.
 This option only affects semi-translucent colors; it has no effect on regular colors (e.g. "red"). 


{dlgtab:Other options}

{phang}
{opt space(real)} specifies the fraction of the plot allocated for 
displaying labels and univariate bars. The default is 0.3, meaning 30% of the available
 space is allocated to the univariate bars and the labels, and 70% for the graph elements.
 If {it:nolabel} is specified, the default is 0. 
 {it:space(1)} is the edge case where only univariate bars are shown.
 {it:space(0)} is the edge case where only bivariate connectors are shown. 
 
{phang}
{opt samescale(varlist)} specifies that for the list of variables specified each axis should have the same scale. 
The list of variables can be a subset of {it:varlist} or the entire list: {it:samescale(_all)}. 
This is useful, for example, if one categorical variable has been repeatedly measured over time, 
but not all categories occur at each time point.

{phang}
{opt subspace(real)}
(rarely needed) The plotting area consists of alternating univariate bars and connectors.
{it:space()} determines the fraction of space allocated for the univariate bars. 
To avoid the univariate bars and connectors touching, 
the univariate space is not used in full; instead, a large fraction is used. We call this fraction {it:subspace}. 
By default,  {it:subspace(0.8)} meaning that 80% of the allocated space is used for univariate bars; 
the remainder is empty. 

{phang}
{opt aspectratio(#)} specifies the aspect ratio of the plot region. By default, {it:aspect(0.7272)}. Changing the default 
also affects the space between the plot region and the available area. 
If a long variable name displays partially outside the graph area, increasing the aspect ratio is 
one way of ensuring variable names are fully visible. 

{phang}
{it:graph_options} are options of {cmd: graph, twoway} other than 
{cmd:symbol()} and {cmd:connect()}. 
In particular, I have found the following options useful: 
 {it:xlab(,labsize(vsmall))} makes variable names smaller. 
 {it:xlabel(, angle(30))} angles the variable names (helps to avoid overlap).
 You can add text such as {it:text(70 8 "America" "Emerging" "Asia" "Europe")}. 
For the placement of the text, the range of the y-axis is 0 to 100, 
and the range of the x-axis is 1 to the number of variables. 
You can explore the placement on the y-axis by specifying {it:yline(0 10 100)} 
(lowest value, missing value separator, highest value).


{title:Examples}

{dlgtab:First example}

{pstd} Plot variables for the blood pressure data. The variable when indicates whether the blood pressured was measured "before" or "after" the treatment. 
{p_end}

{phang2}{cmd:. sysuse bplong}{p_end}
	
{phang2}{cmd:. hammock sex agegrp when bp}{p_end}

{pstd} We find that the graph elements between the variables are equally thick,
meaning that they correspond to the same number of people. 
This may arise from an experimental design where you want the same number of people in each treatment arm.
The lowest blood pressures all belong to the "after" group. 
{p_end}

{pstd}{it:({stata hammock_examples hammock_bp:click to run})}{p_end}


{dlgtab:Highlighting}
{pstd} For the cancer data we highlighted patients who received the placebo. The variable studytime has a long variable label. We shorten this label first.

{phang2}{cmd:. sysuse cancer}{p_end}

{phang2}{cmd:. label var studytime "Study time (mths)"}{p_end}

{phang2}{cmd:. hammock died drug studytime age,  hivar(drug) hival(1) barwidth(.5) labelopt(size(small))}{p_end}

{pstd} We chose width of the bars half as large as the default to reduce visual clutter. 
To improve the display, we also specified that the size of labels for all variables should be "small" 
to avoid overlapping text labels for the variable studytime in the plot. 

{pstd} We find that almost all of the people who took a placebo died. 
The lines between studytime and age cross a lot, 
suggesting they are negatively correlated: younger people were observed longer before 
death occurred or the study was terminated.

{pstd}{it:({stata hammock_examples hammock_cancer:click to run})}{p_end}


{dlgtab:Parallel coordinate plot}

{pstd} If all the variables are continuous, a parallel coordinate plot emerges as a special case. 
The life expectancy data include the variables population growth (%), life expectancy at bith, GNP per capital, and safe water.

{phang2}{cmd:. 	sysuse lifeexp}

{phang2}{cmd:. 	hammock popgrowth-safewater, graphregion(margin(l+3 r+3)) space(0) }

{pstd} The option space(0) reduces the space allocated to univariate bars to 0% leaving 100% for the connectors. To improve the display, we specified extra space at the left and right margin. 
Without this option, the outer variable names run off the graph. Alternatively, we could have reduced the 
font size of the variable names by specifying {it:xlab(,labsize(vsmall))}. 

{pstd} 
We see that the minimal values for life expectancy (lexp), GNP (gnppc) and safewater all belong to the same observation.
Curiously, the maximal values for life expectancy, GNP and safewater also all belong to the same observation.
We also find that life expectancy, GNP and safewater are highly correlated, because the lines rarely cross.

{pstd}{it:({stata hammock_examples hammock_lifeexp:click to run})}{p_end}


{dlgtab:Missing values + Axes labeling}
{pstd} Continuing with the lifeexp data, we check for missing values.  The missing-values category is at the bottom. Once identified, we can highlight missing values across the plot.  

{phang2}{cmd:. 	hammock popgrowth lexp gnp  safewater, graphregion(margin(l+3 r+5)) missing hivar(gnp) hival(.) label_methodlist(min_dist all minmax min_dist) uni_fraction(.2)}

{pstd}  The option uni_fraction reduces box-width on the axes and thereby reduces overlap. The option label_methodlist specifies individual labeling methods for the axes.

{pstd} We notice that GNP and safewater have a quite a few missing values. 
Sometimes one can see that missing values all stem from a single category of another variable; 
occasionally due to a coding error. 
Here, there is no discernible pattern to the missing values.

{pstd}{it:({stata hammock_examples hammock_lifeexp_missing:click to run})}{p_end}


{dlgtab:Missing values 2}

{pstd} Finding out where missing values occur is often useful. Here, we show the missing value option can also identify a fairly innocent coding error.
  We first simulate an age variable which takes on values from age 0 to age 18.

{phang2}{cmd:. 	set seed 8768}

{phang2}{cmd:. 	set obs 100}

{phang2}{cmd:. 	gen age=round(uniform()*18)}

{pstd} Next, we code the age variable into age groups 0, 1, 2-5, 6-11, 12-15, >16.

{phang2}{cmd:. 	egen agegroup= cut(age), at(1,2,6,12,16) }

{pstd} We visually confirm that everything is as expected:

{phang2}{cmd:. 	hammock age agegroup, m space(0.1)  hivar(agegroup) hival(1 2 6 12) label_too_many(40) colorlist(blue%50 orange%50 green red teal) }

{pstd} We used a large value for the option label_too_many to make sure all the labels are plotted (rather than just the minimum and maximum. Including the default, we need to specify 5 colors. 

{pstd}{it:({stata hammock_examples hammock_agegroup:click to run})}{p_end}

{pstd}We found out that accidentally the highest and the lowest age is coded to missing. 
We realize that the egen command requires not just the cut points, but also the lower (0) and upper (19) bound for the first and last categories.
We also add a little more space to the left and right margins so the variable name is fully visible. The corrected code and plot are:

{phang2}{cmd:. 	egen agegroup2= cut(age), at(0,1,2,6,12,16,19)}


{phang2}{cmd:. hammock age agegroup2, missing space(.1) hivar(agegroup2) hival(0 1 2 6 12 16) graphregion(margin(l+2 r+3)) uni_fraction(0) label_too_many(40) colorlist(blue%50 orange%50 green red teal  yellow sand maroon olive)}


{pstd}{it:({stata hammock_examples hammock_agegroup2:click to run})}{p_end}


{dlgtab: Stata Version 17 and earlier}

{pstd}  In Stata 18 the default scheme, stcolor, has a white background. 
If you are using Stata 17 or earlier, specify a scheme to ensure a white background to the plot as follows:

{phang2}{cmd:. set scheme s1color}


{title:Copyright}

{pstd} Copyright 2002-2025 Matthias Schonlau {p_end}

{pstd} This program is free software: you can redistribute it and/or modify it under the terms of the GNU General 
Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any later version. {p_end}

{pstd} This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. {p_end}

{pstd} For the GNU General Public License, please visit {browse "http://www.gnu.org/licenses/"} {p_end}


{title:References}

{p 0 8} Schonlau M. Hammock plots: visualizing categorical and numerical variables. 
Journal of Computational and Graphical Statistics,  Nov 2024, 33(4), 1475–1487. 
{break} Journal: {browse "https://www.tandfonline.com/doi/full/10.1080/10618600.2024.2322561"}
{break} Preprint:{browse "https://schonlau.net/publication/24schonlau_hammock_JCGS.pdf"}

{p 0 8}Schonlau M. Visualizing Categorical Data Arising in the Health Sciences 
Using Hammock Plots. In Proceedings of the Section on Statistical Graphics, 
American Statistical Association; 2003, 
{browse "http://www.schonlau.net/publication/03jsm_hammockplot.pdf"}


{title:Author}

	Matthias Schonlau, University of Waterloo
	schonlau at uwaterloo dot ca
	{browse "http://www.schonlau.net":www.schonlau.net}


{title:Also see}

{hi:Visualizing cluster assignments:} {helpb clustergram} 


