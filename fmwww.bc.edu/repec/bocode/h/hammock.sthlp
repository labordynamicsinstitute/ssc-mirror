{smcl}
{hline}
help for {hi:hammock}{right:{hi: Matthias Schonlau}}
{hline}


{title:Title}

{p2colset 5 23 25 2}{...}
{p2col :{cmd:hammock} {hline 2}} Hammock plot for visualizing categorical and continuous data {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:hammock} {varlist} {ifin} {cmd:,}  [ {it:options}  ]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opt m:issing}} Show missing values {p_end}
{synopt :{opt lab:el}} Show value labels or else show values   {p_end}

{syntab :Highlighting}
{synopt :{opt hivar:iable(varname)}} Name of variable to highlight {p_end}
{synopt :{opt hival:ues(string)}}  List of values of {it:hivariable} to highlight {p_end}
{synopt :{opt col:orlist(str)}} Default color and colors for highlighting {p_end}

{syntab :Manipulating Spacing and Layout}
{synopt :{opt spa:ce(real)}} Control fraction of space allocated to labels rather than to graph elements {p_end}
{synopt :{opt bar:width(real)}} Change width of the plot elements to reduce clutter {p_end}
{synopt :{opt minbar:freq(int)}} Specify minimum bar width {p_end}
{synopt :{opt label_min_dist(real)}} Specify minimum distance between two labels on the same axis{p_end}
{synopt :{opt labelopt(str)}} Pass options to {it:{help added_text_options}}, e.g. to manipulate label text size{p_end}
{synopt :{opt aspect:ratio(real)}} Aspect ratio of the plot region {p_end}
{synopt :{opt no_outline}} Do not outline the edges of semi-translucent boxes {p_end}

{syntab :Other options}
{synopt :{opt shape(str)}} Box shape: "parallelogram" or "rectangle" (default) {p_end}
{synopt :{opt same:scale(varlist)}} Use the same axis scale for each variable specified {p_end}
{synopt :graph_options} Specify additional options passed to  {it:graph, twoway}  {p_end}
{synoptline}



{title:Description}

{pstd}{cmd:hammock} draws a graph to visualize categorical data - though it also does fine
with continuous data. 
Variables are lined up parallel to the vertical axis. Categories within a variable
are spread out along a vertical line. Categories of adjacent variables are connected by 
boxes. (The boxes are parallelograms; we use boxes for brevity). The "width" of a box is proportional to 
the number of observations that correspond to that box (i.e. have the same 
values/categories for the two variables). The "width" of a box refers to the 
distance between the longer set of parallel lines rather than the vertical distance.  
The proportionality constant can be controlled through the option {it: barwidth}.

{pstd} 
If the boxes degenerate to a single line, and no labels or missing values are used 
the hammock plot corresponds to a parallel coordinate plot. Boxes degenerate into a single
line if {it: barwidth} is so small that the boxes
for categorical variables appear to be a single line. For continuous variables boxes
will usually appear to be a single line because each category typically
 only contains one observation.

{pstd} The order of variables in {it:varlist} determines the order of variables in the graph.  
All variables in {it:varlist} must be numerical, but value labels can be used to assign labels to values.  
String variables should be 
converted to numerical variables first, e.g. using {cmd: encode} or {cmd: destring}. 

{title:Installation}
{phang} 
Installation via the {browse "https://github.com/schonlau/hammock-stata":Github repository}.  
The Github version may be more recent than the version on SSC.

{phang2} 
{cmd: . net install hammock, from "https://raw.githubusercontent.com/schonlau/hammock-stata/main/installation/" replace }

{phang} 
Installation via SSC: 

{phang2}
{cmd:. net install hammock, replace} 


{title:Options}
{dlgtab:Main}

{phang} {opt label} 
requests value {it:{help labels}} 
 to be displayed on the graph. For variables for which value labels are not defined,  
the values themselves are displayed. This makes it easier to identify which category
is displayed where. Value labels must not not contain the characters "@" or ",".

{phang}
{opt missing} specifies that "missing value" is a separate category. 
The "missing value category" is always the lowest category drawn at 
the bottom of the graph. A vertical line is drawn to separate missing values
from non-missing values. If there are no missing values the space below 
the vertical line remains empty.
If this option is not specified, observations with missing values are ignored.

{dlgtab:Highlighting}

{phang}
{opt hivariable} specifies which variable is highlighted. {it:  hivalues}
can be used to specify which individual categories to highlight. 
A value that is highlighted appears in a different color and observations in this 
category can be traced through the entire graph. 
{it:hivariable } does not have to be part of {it:varlist}.
If so, it can also be a string variable.

{phang}
{opt hivalues}
specifies which values of {it: hivariable} are highlighted.
{it: hivalues} allows either a numlist, 
a scalar preceeded by ">=","<=",">" or "<", 
or a string when highlighting a string variable.

{pmore}
{it:hivalues} as a numlist: 
To highlight multiple values of {it: hivariable}, specify, for example, {it: hivalues(4 9)}. 
Values 4 and 9 are assigned the second and third color in {it: colorlist}, respectively. 
(If desired, the second and third color may be the same color.) 
All values except 4 and 9 use the default color, the first color in {it: colorlist}. 
To highlight a single value of {it: hivariable}, specify, for example, {it: hivalues(4)}. 
To highlight missing values of {it: hivariable}, specify {it: hivalues(.)}

{pmore}
{it:hivalues} with ">","<",">=","<=" comparisons: For example, {it: hivalues(>=3)} highlights all values greater than or equal to 3 
using the same color  (the second color in {it: colorlist}).  

{pmore}
{it:hivalues} may specify strings or subsets of strings when {it:hivariable} is a string variable. 
For example, for the Shakespeare data set, {it:hivar(play_name)} {it:hivalues(Richard Mac)} 
highlights all plays that contain "Richard" in one color and those that contain "Mac" in another color. 
Because variables in {it:varlist} must be numerical (with optional string labels), 
this is only relevant if the {it:hivar} is NOT part of {it:varlist}.

{pmore}
{it: hivalues} is ignored if {it: hivariable} is not specified. If more than 8 values/strings are specified, colors are recycled.

{phang}
{opt colorlist} specifies a list of colors to be used.  
The first color in the list is the default color, the remainder is used for highlighting. 
If unspecified, the color list is  
"black red  blue teal  yellow sand maroon orange olive magenta".
Color names are explained in {it:{help colorstyle}}.
The color list should not be shorter than the number of values to be highlighted plus one (default color).

{dlgtab:Spacing and Layout}

{phang}
{opt space} specifies the fraction of plot allocated for 
displaying labels. If {it:label} is specified, the default is 0.3, meaning 30% of the available
 space is allocated to the display of labels, and 70% for the graph elements.
 If {it:label} is not specified, the default is 0. Negative values are allowed.

{pmore}
Note: If {it:shape=(parallelogram)}, for technical reasons it is sometimes necessary 
to "shrink" the boxes to make sure width is proportional to the number of observations.
(Stata automatically extends the plotting area with interferes with the calculation of width.) 
In that case, {it:space(0)} may still result in some space.
Space can be removed by using negative values as in {it:space(-0.1)}.
 
{phang}
{opt barwidth} specifies the width of the bars relative to the default width.
 This can reduce visual clutter.  
 The relative width of any two bars is not affected.  For example, 0.5 means half as large as the default width.
  The default is 1.0. The value of {it: barwidth} should be greater than 0, 
  and in most cases should be smaller or equal to 1.0.

{phang}
{opt minbarfreq} specifies the minimum width of the bars.
 If a bar is barely visible because it contains too few observations, 
 it may be useful to increase the width of barely visible bars. 
 The minimum bar width is not specified directly; 
 instead all frequencies below the specified minimum are increased. 
 All bars corresponding to fewer than {it:minbarfreq} observations are displayed as if they contained {it:minbarfreq} observations.
 By default, {it:minbarfreq} equals 1 observation.  
 In other words, by default this option has no effect.
 
{pmore}
 During highlighting, bars may consist of multiple segments with different colors. 
 In that case, {it:minbarfreq} is applied to each color segment separately.
  
{phang}
{opt label_min_dist} specifies the minimum distance between two labels on the same axis.
A label is associated with each unique value of a variable.  
When (numerical) variables have values close to each other, overplotting of labels may occur.  
This option prevents overplotting by selectively not plotting some labels. 
The bottom most label is always plotted, and any additional label above is only plotted if 
it is at least {it:label_min_dist} away from the closest label below.  
Labels are plotted on a scale from 0 (bottom label) to 100 (top label). 
By default, a label must be at least 3 units (out of 100) away from the closest label below.
Specifying {it:label_min_dist=0} will plot all labels.
Specifying {it:label_min_dist=100} will plot only the bottom and the top label.
This option has no effect unless {it:label} is specified.
  
{phang}
{opt labelopt} specifies optional arguments to the labels.
The arguments are passed  to {it:{help added_text_options}}. 
This can be used to manipulate the text sizes of the labels, for example, {it: labelopt(size(vsmall))}.
Text size names are explained in {it:{help textsizestyle}}. 
By default, label size is "medium". If option {it:label} is not specified,  option {it:labelopt} is ignored. 
  
{phang}
{opt aspectratio} specifies the aspect ratio of the plot region. By default, aspect=0.7272. Changing the default 
also affects the space between the plot region and the available area. 
If a long variable name displays partially outside the graph area, increasing the aspect ratio is 
one way of ensuring variable names are fully visible. 
  
{phang}
{opt no_outline} (rarely needed) In Stata, translucent boxes (e.g. "red%50" , where the color is 50% translucent) 
are drawn with an outline that is not translucent.
If there are several overlapping colors, it may be visually simpler to show the translucent box 
without outlining the edges of the box. This option removes the outline.
 This option only effects semi-translucent colors; it has no effect on regular colors (e.g. "red"). 
  

{dlgtab:Other options}

{phang}
{opt shape} refers to the shape of the boxes or plotting elements. 
The two options are "parallelogram" and "rectangle" (default).  Rectangles can look better for steep angles. 
They also avoid the so-called reverse line-width illusion of the parallelogram: 
The vertical width of parallelogram-boxes with steep angles are larger than that of parallelogram-boxes with smaller angles. 
Focusing on the end points of the boxes, can create the illusion that there are more observations in steep-angled parallelograms
than there really are. 

{phang}
{opt samescale} specifies that for the list of variables specified each axis should have the same scale. 
The list of variables can be a subset of {it:varlist} or the entire list: {it: samescale(_all)}. 
This is useful, for example, if one categorical variable has been repeatedly measured over time, 
but not all categories occur each at each time point.

{phang}
{it:graph_options} are options of {cmd: graph, twoway} other than 
{cmd:symbol()} and {cmd:connect()}. 
In particular,  the option {it: xlab(,labsize(vsmall))} makes variable names smaller and is sometimes useful.


{title:Examples}

{dlgtab:First example}

{pstd} Plot variables for the blood pressure data. The variable when indicates whether the blood pressured was measured "before" or "after" the treatment. 
{p_end}

{phang2}{cmd:. sysuse bplong}{p_end}
	
{phang2}{cmd:. hammock sex agegrp when bp, label}{p_end}

{pstd} We find that the graph elements between the variables are equally thick,
meaning that they correspond to the same number of people. 
This may arise from an experimental design where you want the same number of people in each treatment arm.
The lowest blood pressures all belong to the "after" group. 
{p_end}

{pstd}{it:({stata hammock_examples hammock_bp:click to run})}{p_end}


{dlgtab:Highlighting}
{pstd} For the cancer data we highlighted patients who received the placebo. 

{phang2}{cmd:. sysuse cancer}{p_end}

{pstd}  We first need to find which value of the variable drug corresponds to the label "placebo".

{phang2}{cmd:. describe drug}{p_end}

{pstd} We found variable drug is associated with the set of labels called "type".

{phang2}{cmd:. label list type}{p_end}

{pstd} We found "placebo" is the label for the value 1.

{phang2}{cmd:. hammock died drug studytime age, label hivar(drug) hival(1) barwidth(.5) labelopt(size(small))}{p_end}

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

{phang2}{cmd:. 	hammock popgrowth-safewater, graphregion(margin(l+3 r+3))}

{pstd} To improve the display, we specified extra space at the left and right margin. 
Without this option, the outer variable names run off the graph. Alternatively, we could have reduced the 
font size of the variable names by specifying {it: xlab(,labsize(vsmall))}. 

{pstd} 
We see that the minimal values for life expectancy (lexp), GNP (gnppc) and safewater all belong to the same observation.
Curiously, the maximal values for life expectancy, GNP and safewater also all belong to the same observation.
We also find that life expectancy, GNP and safewater are highly correlated, because the lines rarely cross.

{pstd}{it:({stata hammock_examples hammock_lifeexp:click to run})}{p_end}


{dlgtab:Missing values 1}
{pstd} Continuing with the lifeexp data, we check for missing values.  Missing values are indicated 
by a category below the horizontal line near the bottom. 

{phang2}{cmd:. 	hammock popgrowth-safewater, graphregion(margin(l+3 r+3)) missing }

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

{phang2}{cmd:. 	hammock age agegroup, m space(0.1) label hivar(agegroup) hival(1 2 6 12)}

{pstd}{it:({stata hammock_examples hammock_agegroup:click to run})}{p_end}

{pstd}We found out that accidentally the highest and the lowest age is coded to missing. 
We realize that the egen command requires not just the cut points, but also the lower (0) and upper (19) bound for the first and last categories.
We also add a little more space to the left and right margins so the variable name is fully visible. The corrected code and plot are:

{phang2}{cmd:. 	egen agegroup2= cut(age), at(0,1,2,6,12,16,19)}

{phang2}{cmd:. 	hammock age agegroup2, m space(.1) label hivar(agegroup2) hival(0 1 2 6 12 16) graphregion(margin(l+2 r+3))}

{pstd}{it:({stata hammock_examples hammock_agegroup2:click to run})}{p_end}


{dlgtab: Stata Version 17 and earlier}

{pstd}  In Stata 18 the default scheme, stcolor, has a white background. 
If you are using Stata 17 or earlier, specify a scheme to ensure a white background to the plot as follows:

{phang2}{cmd:. set scheme s1color}


{title:Copyright}

{pstd} Copyright 2002-2024 Matthias Schonlau {p_end}

{pstd} This program is free software: you can redistribute it and/or modify it under the terms of the GNU General 
Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any later version. {p_end}

{pstd} This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. {p_end}

{pstd} For the GNU General Public License, please visit {browse "http://www.gnu.org/licenses/"} {p_end}


{title:References}

{p 0 8} Schonlau M. Hammock plots: visualizing categorical and numerical variables. 
Journal of Computational and Graphical Statistics (to appear in print). 
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


