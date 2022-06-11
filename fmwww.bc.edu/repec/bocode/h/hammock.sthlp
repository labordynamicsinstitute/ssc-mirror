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
{synopt :{opt hivar:iable(varname)}} name of variable to highlight {p_end}
{synopt :{opt hival:ues(numlist)}}  list of values of {it:hivariable} to highlight {p_end}
{synopt :{opt col:orlist(str)}} list of colors for highlighting {p_end}

{syntab :Manipulating Spacing and Layout}
{synopt :{opt bar:width(real)}} Change width of the plot elements to reduce clutter {p_end}
{synopt :{opt spa:ce(real)}} Control fraction of space allocated to labels rather than to graph elements {p_end}
{synopt :{opt labelopt(str)}} Pass options to {it:{help added_text_options}}, e.g. to manipulate label text size{p_end}

{syntab :Other options}
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
All variables in {it:varlist} must be numerical. String variables should be 
converted to numerical variables first, e.g. using {cmd: encode} or {cmd: destring}. 


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

{phang}
{opt hivalues}
specifies which values of {it: hivariable} are highlighted.
For example, {it: hivalues(4 9)} will use different colors for {it:hivariable==4} and {it:hivariable==9}.
All values except 4 and 9 use the default color, the first color in {it: colorlist}.
Values 4 and 9 are assigned the second and third color in {it: colorlist}, respectively. 
If more than 8 values are specified, colors are recycled.
{it: hivalues} is ignored if {it: hivariable} is not specified. 

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
displaying labels. By default this is set to 0.3, meaning 30% of the available
 space is allocated to the display of labels, and 70% for the graph elements.
If option {it:label} is not specified, option {it:space} is ignored. 

{phang}
{opt barwidth} specifies the width of the bars relative to the default width.
 This can reduce visual clutter.  
 The relative width of any two bars is not affected.  For example, 0.5 means half as large as the default width.
  The default is 1.0. The value of {it: barwidth} should be greater than 0, and in most cases should be smaller or equal to 1.0.
   
{phang}
{opt labelopt} specifies optional arguments to the labels.
The arguments are passed  to {it:{help added_text_options}}. 
This can be used to manipulate the text sizes of the labels, for example, {it: labelopt(size(vsmall))}.
Text size names are explained in {it:{help textsizestyle}}. 
By default, label size is "medium". If option {it:label} is not specified,  option {it:labelopt} is ignored. 
  
{dlgtab:Other options}

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

{pstd}  Specify a scheme to ensure a white background to the plot.

{phang2}{cmd:. set scheme s1color}
	
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



{title:Copyright}

{pstd} Copyright 2002-2022 Matthias Schonlau {p_end}

{pstd} This program is free software: you can redistribute it and/or modify it under the terms of the GNU General 
Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any later version. {p_end}

{pstd} This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. {p_end}

{pstd} For the GNU General Public License, please visit {browse "http://www.gnu.org/licenses/"} {p_end}


{title:References}

{p 0 8}Schonlau M. Visualizing Categorical Data Arising in the Health Sciences 
Using Hammock Plots. In Proceedings of the Section on Statistical Graphics, 
American Statistical Association; 2003, CD-ROM. 
Available from : {browse "http://www.schonlau.net/publication/03jsm_hammockplot.pdf"}


{title:Author}

	Matthias Schonlau, University of Waterloo
	schonlau at uwaterloo dot ca
	{browse "http://www.schonlau.net":www.schonlau.net}


{title:Also see}

{p 0 19}Stata Journal:  {hi:[SJ] clustergram} {p_end}
{p 0 19}Stata Bulletin: {hi:[STB] parcoord}{p_end}


