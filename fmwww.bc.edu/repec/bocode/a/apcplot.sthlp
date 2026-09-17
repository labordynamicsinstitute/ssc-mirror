{smcl}
{* *! version 2.2 || 16.9.2026 || Gordey Yastrebov}{...}
{hi:help apcplot}{...}
{right:also see: {helpb apcdescribe}, {helpb apcest}, {helpb apcbound}}
{hline}


{title:Title}

{pstd}{hi:apcplot} {hline 2} A tool for visualizing APC effects to facilitate the Fosse-Winship bounding approach to APC analysis (part of the {cmd:apcbound} package).


{title:Syntax}

{p 8 15 2}{cmd:apcplot} [{it:APC_set}], {help apcplot##options:{it:options}}

{pstd}where {it:APC_set} defines the set of APC effects to be plotted, with {it:a} for {bf:age} effect, {it:p} 
for {bf:period} effect, and {it:c} for {bf:cohort} effect. If nothing is specified, all three effects will be 
plotted. For example, if {cmd:apcplot a c} is specified, only age and cohort effects will be plotted.

{synoptset 34 tabbed}
{synopthdr:options}
{synoptline}

{syntab:{help apcplot##basic:Basic options}}
{synopt:{opt b:ounded}}requests bounded or semi-bounded solution visualization{p_end}
{synopt:{opt i:nfo}}requests the legend for the bounds and assumptions{p_end}
{synopt:{opt k:eepshape}}forces shape line rendering{p_end}
{synopt:{opt m:atrix(suffix)}}stores plot value matrices{p_end}
{synopt:{opt ci}}requests confidence interval visualization{p_end}
{synopt:{opt level(#)}}sets the confidence level; default is {cmd:c(level)}{p_end}
{synopt:{opt a|p|c(#)}}specifies custom values for {bf:α}, {bf:π}, and/or {bf:γ}{p_end}
{synopt:{opt pea|p|c:bounds(# #)}}specifies custom fully bounded or semi-bounded limits for {bf:α}, {bf:π}, and/or {bf:γ}{p_end}
{synopt:{opt cia|p|c:bounds(# #)}}specifies custom confidence-interval-adjusted fully bounded or semi-bounded limits{p_end}

{syntab:{help apcplot##grid:Diagnostic grid lines options}}
{synopt:{cmd:grid(}{it:#} [[{it:+|-}]{it:#}]{cmd:)}}requests diagnostic rotations: step size and optional signed number of shifts{p_end}
{synopt:{opt gridlab:els(off|left|right)}}controls which grid labels to plot{p_end}
{synopt:{opt anc:horgrid}}anchors grid rendering{p_end}
{synopt:{opt gridlabops}({it:{help textbox_options}})}custom grid labels decoration{p_end}
{synopt:{opt gridline}({it:{help line_options}})}custom grid lines decoration{p_end}
{synopt:{opt gridpal:ette}({help colorpalette##palette:{it:palette(s)}})}grid color palette(s); default is {help colorpalette##:{it:tableau}}{p_end}

{syntab:{help apcplot##gradient:Gradient options}}
{synopt:{opt nogr:adient}}suppresses gradient rendering{p_end}
{synopt:{opt grad:es(#)}}number of grades in a color gradient; default is 100{p_end}
{synopt:{opt fades:peed(#)}}controls opacity fading speed for semi-bounded solutions; default is 1{p_end}
{synopt:{opt fadew:idth(#)}}controls the artificial closing-bound distance for semi-bounded solutions; default is 1{p_end}
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

{pstd}{cmd:apcplot} is a tool for exploring and visualizing APC effects inspired by Fosse-Winship bounding approach 
to APC analysis ({browse "https://doi.org/10.1146/annurev-soc-073018-022616":{it:Fosse & Winship}, 2019}). It can 
visualize nonlinear shapes and/or fully bounded or semi-bounded solution ranges.


{marker options}{title:Options}
{marker basic}{dlgtab:Basic options}

{phang}{opt bounded} requests the visualization of bounded solutions. Fully bounded solutions are rendered as closed gradient ranges. Semi-bounded solutions are rendered as fading gradient ranges extending from the finite bound toward an artificial closing bound. If a selected solution is unbounded, only its nonlinear shape is rendered. If {opt bounded} is not specified, {cmd:apcplot} renders only shape lines for the selected 
APC effects. Shape lines are not additionally drawn over bounded or semi-bounded solutions unless {opt keepshape} is specified.

{phang}{opt info} embeds the information on the bounds and assumptions from the previous call of {cmd:apcbound} into the plots produced by {cmd:apcplot}.

{phang}{opt keepshape} forces the rendering of the shape lines, when {opt bounded} is specified.

{phang}{opt matrix(suffix)} stores the lower and upper bounded solutions at every plotted value of age, period, 
and cohort. The matrices are named {it:aPE_suffix}, {it:pPE_suffix}, and {it:cPE_suffix} for point estimates, 
and {it:aCI_suffix}, {it:pCI_suffix}, and {it:cCI_suffix} for confidence intervals, as applicable. Each matrix 
contains the columns {cmd:lower_Y}, {cmd:upper_Y}, and {cmd:X}. 

{pmore}For internally grouped APC dimensions, {cmd:X} contains the observed within-group means used as plotting 
positions; the corresponding linear component is measured relative to the reference group's mean. For a semi-bounded
solution, the open endpoint remains missing in the stored matrix; the artificial closing bound is used only for
rendering. Only matrices corresponding to the requested APC plots are stored. This option requires {opt bounded}.
Existing matrices with the same names are replaced.

{phang}{opt ci} requests confidence interval rendering. If {opt bounded} is not specified, the confidence intervals 
refer exclusively to the nonlinear shape lines. The confidence level is set by {opt level(#)} when specified and 
otherwise by Stata's current {cmd:c(level)}. 

{pmore}If {opt bounded} is specified and any plotted confidence-interval-adjusted 
bounds are obtained from the previous call of {cmd:apcbound}, the confidence level resolved by {cmd:apcplot} must 
coincide with the level stored by {cmd:apcbound}; otherwise, {cmd:apcplot} issues an error rather than combining bounds 
and confidence intervals based on different levels.

{phang}{opt level(#)} sets the confidence level used when {opt ci} is specified. The value must be greater than 0 and less than 100. If {opt level(#)} is omitted, Stata's current {cmd:c(level)} is used. Option {opt level()} requires {opt ci}. When CI-adjusted bounds from {cmd:apcbound} are used, the resulting level must match {cmd:e(apcboundCI)}.

{phang}{opt a(#)}, {opt p(#)}, and {opt c(#)} specify a custom reference value for linear components {bf:α}, 
{bf:π}, and/or {bf:γ}. The resulting solution is used for the shape line and, when {opt grid()} is 
specified, as the reference line around which the diagnostic rotations are drawn. Only one of the 
three parameters can be specified, because the command automatically deduces the remaining two 
using {bf:θ₁ = α + π} and {bf:θ₂ = γ + π} estimated with {cmd:apcest}.

{phang}{opt peabounds(# #)}, {opt pepbounds(# #)}, and {opt pecbounds(# #)} specify custom bounds for 
{bf:α}, {bf:π}, and/or {bf:γ}. A missing value ({cmd:.}) denotes one open endpoint. Thus, {cmd:peabounds(. .02)} is lower-unbounded and {cmd:pepbounds(-.03 .)} is upper-unbounded. At least one endpoint must be finite. Custom bounds override the corresponding solutions produced by the previous call of {cmd:apcbound}.

{phang}{opt ciabounds(# #)}, {opt cipbounds(# #)}, and {opt cicbounds(# #)} are similar to the options above, 
except that they specify custom confidence-interval-adjusted bounds for {bf:α}, {bf:π}, and/or {bf:γ}. These options require {opt ci} and an explicit {opt level(#)}, because the confidence level cannot be inferred from custom bounds. 


{marker grid}{dlgtab:Diagnostic grid lines options}

{phang}{opt grid(# [[+|-]#])} is an option that allows producing a diagnostic grid in the background, illustrating incremental changes in the values of the linear components {bf:α}, {bf:π}, and/or {bf:γ}. The option is intended for fine-tuning the bounding assumptions, revealing how the shapes of APC effects might change depending on the changes in {bf:α}, {bf:π}, and/or {bf:γ}. If the option is not specified, no grid will be produced.

{pmore}The first parameter # sets the desired increment. The second parameter # is optional and must be an integer. It sets the number of incremental shifts to display. If it is omitted, the default is 1. A leading {cmd:+} or {cmd:-} requests only increasing or only decreasing shifts, respectively (for example, {opt grid(.001 -2)}). Without a sign, both increasing and decreasing shifts are displayed.

{phang}{opt gridlabels(off|left|right)} controls whether and which values of increments will be labeled. By default, if {opt grid()} is specified, the labels will appear both on the left and the right horizontal axes.

{phang}{opt anchorgrid} controls whether the grid will ignore the correspondence between {bf:α}, {bf:π}, and/or {bf:γ} (a default option) or not (when anchoring is requested). Basically, the option commands the grid for {bf:π} to be rendered in the opposite direction of {bf:α} and {bf:γ} (i.e., turning positive shifts into negative and vice versa).

{phang}{opt gridlabops}({it:{help textbox_options}}) allows specifying custom options for the grid labels.

{phang}{opt gridline}({it:{help line_options}}) determines the custom look for the grid lines.

{phang}{opt gridpalette}({help colorpalette##palette:{it:palette(s)}}) determines the color palette(s) to color the grid lines. If two palettes are specified (need to be separated by a comma, e.g., {opt gridpalette(palette1, palette2)}), positive and negative grid increments will be rendered using separate palettes. The default palette is set to {help colorpalette##:{it:tableau}}. 

{marker gradient}{dlgtab:Gradient options}

{phang}{opt nogradient} suppresses the rendering of the gradient for bounded range solutions. This might be useful to expedite rendering.

{phang}{opt grades(#)} sets the number of grades to be distinguished in a color gradient for both fully bounded and semi-bounded solutions. The default is 100. Setting it to a lower number might speed up rendering, but a higher number might produce aesthetically better results.

{phang}{opt fadespeed(#)} controls the rate at which opacity declines from the finite bound toward the artificial closing bound of a semi-bounded point-estimate solution. The default is 1, which produces a linear fade. Values above 1 fade faster; values between 0 and 1 fade more slowly. The value must be greater than 0.

{phang}{opt fadewidth(#)} controls how far the artificial closing bound is placed from the finite bound of a semi-bounded solution. The default is 1. Values below 1 produce a narrower displayed range, and values above 1 produce a wider displayed range. The option changes only the artificial range width: it does not change the number of grades or truncate the color palette. The value must be greater than 0. 

{phang}{opt areacontour}({it:{help line_options}}) allows specifying a custom look for the contour lines enclosing a fully bounded gradient. For a semi-bounded plot, it draws exactly one contour: the finite boundary. No contour is drawn at the artificial transparent endpoint.

{phang}{opt areapalette}({help colorpalette##palette:{it:palette}}) determines the color palette for the gradient (rainbow colors palette {help colorpalette##CET:{it:CET R1}} is the default). If {opt nogradient} is specified, the argument must be a single color. The rendering of the gradient will always reverse for the period effects, to correspond exactly to the system of relationships specified by θ₁ = α + π and θ₂ = γ + π.


{marker further}{dlgtab:Further plot customization options}

{phang}{opt shapeplotops}({it:{help line_options}}) allows customizing the look of the lines depicting the shape of APC effects (point-estimate solutions).

{phang}{opt plotops}({it:{help twoway_options}}) allows customizing master plot options common to all APC effects specified.

{phang}{opt aplotops}({it:{help twoway_options}}), {opt pplotops}({it:{help twoway_options}}), and {opt cplotops}({it:{help twoway_options}}) determine APC-effect-specific plot options. These override customization with {opt plotops()}.

{phang}{opt ciplotops}(twoway) allows customizing the look of the confidence intervals.

{phang}{opt recastci}({help graph_twoway:{it:plottype}}) specifies the plot type for the confidence intervals. The default is {helpb twoway rarea:rarea}.

{phang}{opt combined} orders the production of a combined plot. By default, separate graphs are rendered for the specified APC effects.

{phang}{opt combplotops}({help graph combine:{it:combined_options}}) specifies options for the combined plot.


{title:Examples}

{pstd}Load the example data and estimate the APC model:

	. {stata webuse nlswork, clear}
	. {stata "apcest, a(age^2) p(ib78.year) c(birth_yr): regress ln_wage"}

{pstd}Inspect all nonlinear shapes with 95% confidence intervals in one combined graph:

	. {stata apcplot, ci level(95) combined}

{pstd}Inspect diagnostic rotations around a custom age-slope reference. The grid uses 
increments of .005 and displays four positive shifts, with labels only on the left:

	. {stata apcplot a, a(.01) grid(.005 +4) gridlabels(left)}

{pstd}Inspect linked diagnostic rotations for all three effects. With {opt anchorgrid}, 
negative age and cohort shifts imply positive period shifts:

	. {stata apcplot, grid(.005 -3) anchorgrid combined}

{pstd}Estimate and plot a fully bounded solution with 95% confidence intervals, bound information, 
and plot values stored in matrices:

	. {stata apcbound, p(-.03 .) c(0 .) ci level(95)}
	. {stata apcplot, bounded ci level(95) combined info matrix(plotvalues)}
	. {stata matrix list pPE_plotvalues}
	. {stata matrix list pCI_plotvalues}

{pstd}Plot a semi-bounded solution. {opt grades()} controls rendering resolution, 
{opt fadespeed()} controls opacity loss, {opt fadewidth()} controls only the distance 
to the artificial closing bound, and {opt areacontour()} marks the finite boundary:

	. {stata apcbound, p(-.03 .) ci level(95)}
	. {stata "apcplot, bounded ci level(95) combined grades(80) fadespeed(1.5) fadewidth(.75) areacontour(lcolor(gs8))"}

{pstd}Supply custom semi-bounded point-estimate limits directly for selected effects:

	. {stata "apcplot a p, bounded peabounds(. .025) pepbounds(-.03 .) areapalette(CET C1)"}


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
approach to age-period-cohort analysis (Version 2.2)" [Computer software]. Boston College Department of Economics, Statistical Software Components.
{browse "https://ideas.repec.org/c/boc/bocode/s459449.html":https://ideas.repec.org/c/boc/bocode/s459449.html}
{p_end}

{phang}
{cmd:Yastrebov, G., Trinidad, A., and Leopold, T.} (2025). A Bounding Approach to Age-Period-Cohort Analysis: A Demonstration Using Public Crime Concerns in Germany. {it:Journal of Quantitative Criminology}.
{browse "https://doi.org/10.1007/s10940-025-09633-7":https://doi.org/10.1007/s10940-025-09633-7}
{p_end}
