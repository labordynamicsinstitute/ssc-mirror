{smcl}
{* *! version 2.0 ||23.7.2026 || Gordey Yastrebov}{...}
{hi:help apcplot}{...}
{right:also see: {helpb apcdescribe}, {helpb apcest}, {helpb apcbound}}
{hline}


{title:Title}

{pstd}{hi:apcplot} {hline 2} A tool for visualizing APC effects to facilitate the Fosse-Winship bounding approach to APC analysis (part of the {cmd:apcbound} package).


{title:Syntax}

{p 8 15 2}{cmd:apcplot} [{it:APC_set}], {help apcplot##options:{it:options}}

{pstd}where {it:APC_set} defines the set of APC effects to be plotted, with {it:A} 
for {bf:age} effect, {it:P} for {bf:period} effect, and {it:C} for {bf:cohort} effect. If 
nothing is specified, all three effects will be plotted. For example, if {cmd:apcplot A C} 
is specified, only age and cohort effects will be plotted.

{synoptset 34 tabbed}
{synopthdr:options}
{synoptline}

{syntab:{help apcplot##basic:Basic options}}
{synopt:{opt b:ounded}}requests bounded solution visualization{p_end}
{synopt:{opt i:nfo}}requests the legend for the bounds and assumptions{p_end}
{synopt:{opt k:eepshape}}forces shape line rendering{p_end}
{synopt:{opt m:atrix(suffix)}}stores plot value matrices{p_end}
{synopt:{opt ci(#)}}requests visualization of #% confidence intervals{p_end}
{synopt:{opt a|p|c(#)}}specifies custom values for {bf:α}, {bf:π}, and/or {bf:γ}{p_end}
{synopt:{opt pea|p|c:bounds(# #)}}specifies custom bounds for {bf:α}, {bf:π}, and/or {bf:γ}{p_end}
{synopt:{opt cia|p|c:bounds(# #)}}specifies custom confidence-interval-adjusted bounds for {bf:α}, {bf:π}, and/or {bf:γ}{p_end}

{syntab:{help apcplot##grid:Diagnostic grid lines options}}
{synopt:{opt g:rid(# [#])}}requests grid lines visualization: {it:#} for grid increment [{it:#} for the number of increments; default is 1]{p_end}
{synopt:{opt gridlab:els(off|left|right)}}controls which grid labels to plot{p_end}
{synopt:{opt anc:horgrid}}anchors grid rendering{p_end}
{synopt:{opt gridf:ading(#)}}sets the intensity of grid fading, where # is greater than or equal to 0 and less than 1{p_end}
{synopt:{opt gridlabops}({it:{help textbox_options}})}custom grid labels decoration{p_end}
{synopt:{opt gridline}({it:{help line_options}})}custom grid lines decoration{p_end}
{synopt:{opt gridpal:ette}({help colorpalette##palette:{it:palette(s)}})}grid color palette(s); default is {help colorpalette##:{it:tableau}}{p_end}

{syntab:{help apcplot##gradient:Gradient options}}
{synopt:{opt nogr:adient}}suppresses gradient rendering{p_end}
{synopt:{opt grad:es(#)}}number of grades in a color gradient; default is 100{p_end}
{synopt:{opt areacon:tour}({it:{help line_options}})}area contour custom decoration{p_end}
{synopt:{opt areapal:ette}({help colorpalette##palette:{it:palette}})}gradient area color palette; default is {help colorpalette##CET:{it:CET R1}}, i.e., rainbow colors{p_end}

{syntab:{help apcplot##further:Further plot customization options}}
{synopt:{opt shapepl:otops}({help line_options:{it:line_options}})}shape line options{p_end}
{synopt:{opt pl:otops}({it:{help twoway_options}})}common plot options{p_end}
{synopt:{opt a|p|cpl:otops}({it:{help twoway_options}})}APC-effect-specific plot options{p_end}
{synopt:{opt cipl:otops}({it:{help twoway_options}})}confidence interval plot options{p_end}
{synopt:{opt recast:ci}({help graph_twoway:{it:plottype}})}custom confidence interval plot type{p_end}
{synopt:{opt comb:ined}}combines plots{p_end}
{synopt:{opt combpl:otops}({help graph combine:{it:combined_options}})}combined plot options{p_end}

{synoptline}


{title:Description}

{pstd}{cmd:apcplot} is a tool for exploring and visualizing APC effects 
inspired by Fosse-Winship bounding approach to APC analysis 
({browse "https://doi.org/10.1146/annurev-soc-073018-022616":{it:Fosse & Winship}, 2019}). It
can produce both point-identified and bounded-range solutions.


{marker options}{title:Options}
{marker basic}{dlgtab:Basic options}

{phang}{opt bounded} requests the visualization of a bounded solution. If it is not specified, 
{cmd:apcplot} will assume that only the shape lines for selected APC effects will be plotted. If 
the option is specified, the shape lines will not be produced over the bounded solutions 
unless {opt keepshape} is specified.

{phang}{opt info} embeds the information on the bounds and assumptions from the previous call 
of {cmd:apcbound} into the plots produced by {cmd:apcplot}.

{phang}{opt keepshape} forces the rendering of the shape lines, when {opt bounded} is specified.

{phang}{opt matrix(suffix)} stores the lower and upper bounded solutions at every
plotted value of age, period, and cohort. The matrices are named {it:aPE_suffix}, {it:pPE_suffix}, and {it:cPE_suffix} for point estimates, and {it:aCI_suffix}, {it:pCI_suffix}, and {it:cCI_suffix} for confidence intervals, as applicable. 
Each matrix contains the columns {cmd:lower_Y}, {cmd:upper_Y}, and {cmd:X}. Only matrices corresponding to the
requested APC plots are stored. This option requires {opt bounded}. Existing
matrices with the same names are replaced.

{phang}{opt ci(#)} requests the rendering of #% confidence intervals. If {opt bounded} is specified, 
it will produce confidence-interval-adjusted bounded solutions (if the bounded solution is assumed
from the previous call of {cmd:apcbound}, the confidence levels specified with both commands should 
match, otherwise the program will signal an error). If {opt bounded} {it:is not} specified, the 
confidence interval will refer exclusively to the shape lines.

{phang}{opt a(#)}, {opt p(#)}, and {opt c(#)} specify custom exact values for linear components {bf:α}, 
{bf:π}, and/or {bf:γ}. This option is thus only relevant for the visualization of shape lines. Only one 
of the three parameters can be specified, because the command will automatically deduce the values 
of the remaining two parameters by using {bf:θ₁ = α + π} and {bf:θ₂ = γ + π} estimated with {cmd:apcest}.

{phang}{opt peabounds(# #)}, {opt pepbounds(# #)}, and {opt pecbounds(# #)} specify custom bounds for 
{bf:α}, {bf:π}, and/or {bf:γ}. This option is thus only relevant for the visualization of bounded solutions, 
and will override the solutions produced by the previous call of {cmd:apcbound}.

{phang}{opt ciabounds(# #)}, {opt cipbounds(# #)}, and {opt cicbounds(# #)} are similar to the options above, 
except that they specify custom confidence-interval-adjusted bounds for {bf:α}, {bf:π}, and/or {bf:γ}. 


{marker grid}{dlgtab:Diagnostic grid lines options}

{phang}{opt grid(# [#])} is an option that allows producing a diagnostic grid 
in the background, illustrating incremental changes in the values of the linear 
components {bf:α}, {bf:π}, and/or {bf:γ}. The option is intended for fine-tuning 
the bounding assumptions, revealing how the shapes of APC effects might change 
depending on the changes in {bf:α}, {bf:π}, and/or {bf:γ}. If the option is not 
specified, no grid will be produced.

{pmore}The first parameter # sets the desired {it:increment}. 

{pmore}The second parameter # is optional and must be an integer. It sets the {it:number of 
incremental shifts} to demonstrate. If it is not specified, 1 will be the default value. If 
the value is preceded by a "+" or "-", respectively only increasing (positive) or decreasing 
(negative) shifts will be assumed (e.g., {opt grid(.001 -2)}). Otherwise, both increasing 
and decreasing shifts will be illustrated.

{phang}{opt gridlabels(off|left|right)} controls whether and which values of increments 
will be labeled. By default, if {opt grid()} is specified, the labels will appear both 
on the left and the right horizontal axes.

{phang}{opt anchorgrid} controls whether the grid will ignore the correspondence 
between {bf:α}, {bf:π}, and/or {bf:γ} (a default option) or not (when anchoring is 
requested). Basically, the option commands the grid for {bf:π} to be rendered in 
the opposite direction of {bf:α} and {bf:γ} (i.e., turning positive shifts into negative 
and vice versa).

{phang}{opt gridfading(#)} sets the intensity of grid fading. Fading refers to increasing 
transparency of subsequent grid lines. It is controlled by a single value greater than or equal to 0 
(default) and less than 1.

{phang}{opt gridlabops}({it:{help textbox_options}}) allows specifying custom options for the grid labels.

{phang}{opt gridline}({it:{help line_options}}) determines the 
custom look for the grid lines.

{phang}{opt gridpalette}({help colorpalette##palette:{it:palette(s)}}) determines the color 
palette(s) to color the grid lines. If two palettes are specified (need to be separated by
a comma, e.g., {opt gridpalette(palette1, palette2)}), positive and negative grid increments 
will be rendered using separate palettes. The default palette is set to 
{help colorpalette##:{it:tableau}}. 

{marker gradient}{dlgtab:Gradient options}

{phang}{opt nogradient} suppresses the rendering of the gradient for bounded range 
solutions. This might be useful to expedite rendering.

{phang}{opt grades(#)} sets the number of grades to be distinguished in a color gradient. The 
default is 100. Setting it to a lower number might speed up rendering, but a higher number 
might produce aesthetically better results.

{phang}{opt areacontour}({it:{help line_options}}) allows specifying a custom 
look for the contour lines enclosing the gradient.

{phang}{opt areapalette}({help colorpalette##palette:{it:palette}}) determines the color 
palette for the gradient (rainbow colors palette {help colorpalette##CET:{it:CET R1}} is 
the default). If {opt nogradient} is specified, the argument must be a single color. The 
rendering of the gradient will always reverse for the period effects, to correspond exactly 
to the system of relationships specified by θ₁ = α + π and θ₂ = γ + π.

{marker further}{dlgtab:Further plot customization options}

{phang}{opt shapeplotops}({it:{help line_options}}) allows customizing the look 
of the lines depicting the shape of APC effects (point-estimate solutions).

{phang}{opt plotops}({it:{help twoway_options}}) allows customizing master plot options common to all APC effects specified.

{phang}{opt aplotops}({it:{help twoway_options}}), {opt pplotops}({it:{help twoway_options}}), and {opt cplotops}({it:{help twoway_options}}) 
determine APC-effect-specific plot options. These override customization with {opt plotops()}.

{phang}{opt ciplotops}(twoway) allows customizing the look of the confidence intervals.

{phang}{opt recastci}({help graph_twoway:{it:plottype}}) specifies the plot type for the confidence intervals. The default is {helpb twoway rarea:rarea}.

{phang}{opt combined} orders the production of a combined plot. By default, separate graphs are rendered for the specified APC effects.

{phang}{opt combplotops}({help graph combine:{it:combined_options}}) specifies options for the combined plot.


{title:Examples}

{pstd}Load sample data and estimate a model:

	. {stata webuse nlswork, clear}
	. {stata "apcest, a(age^2) p(ib78.year) c(birth_yr): regress ln_wage"}
	
{pstd}A simple call to inspect the nonlinear shapes of APC effects after estimation in 
a single combined plot:

	. {stata apcplot, combined}

{pstd}The nonlinear shapes enhanced with the diagnostic grid lines for the age effects 
with 3 degrees of rotation for α, both positive and negative, and each step defined as .01:
	
	. {stata apcplot A, grid(.01 3)}

{pstd}A diagnostic grid for all APC effects, with the grid anchored and only negative 
rotation assumed for α and γ (accordingly, positive for π), in a combined plot:

	. {stata apcplot, grid(.01 -2) anchorgrid combined}

{pstd}The shape of period effects assuming a specific custom value for α, 
with 95% confidence intervals for the nonlinear effects included:
	
	. {stata apcplot P, a(.01) ci(95)}

{pstd}A call to visualize the bounded solution obtained after {cmd:apcbound}:

	. {stata apcbound, p(-.03 .) c(0 .)}
	. {stata apcplot, bounded combined}

{pstd}Requesting a bounded solution, with 95% confidence intervals shown and plot values stored to matrices:

	. {stata apcbound, p(-.03 .) c(0 .) ci(95)}
	. {stata apcplot, bounded combined ci(95) matrix(plotvalues)}
	. {stata matrix list pPE_plotvalues}
	. {stata matrix list pCI_plotvalues}


{title:Author}

{p 4} {cmd:Gordey Yastrebov} {p_end}
{p 4} {it:University of Cologne} {p_end}
{p 4} {browse "mailto:gordey.yastrebov@gmail.com":gordey.yastrebov@gmail.com} {p_end}


{title:Citation}

{pstd}
When referring to {cmd:apcbound}, {cmd:apcest}, {cmd:apcplot}, or
{cmd:apcdescribe} in published work, please consider citing the software package
and the article implementing the bounding approach:
{p_end}

{phang}
{cmd:Yastrebov, G.} (2026). "APCBOUND: Stata module for the Fosse-Winship bounding
approach to age-period-cohort analysis (Version 2.0)" [Computer software]. Boston College Department of Economics, Statistical Software Components.
{browse "https://ideas.repec.org/c/boc/bocode/s459449.html":https://ideas.repec.org/c/boc/bocode/s459449.html}
{p_end}

{phang}
{cmd:Yastrebov, G., Trinidad, A., and Leopold, T.} (2025). A Bounding Approach to Age-Period-Cohort Analysis: A Demonstration Using Public Crime Concerns in Germany. {it:Journal of Quantitative Criminology}.
{browse "https://doi.org/10.1007/s10940-025-09633-7":https://doi.org/10.1007/s10940-025-09633-7}
{p_end}
