{smcl}
{* *! version 1.2.0 30sep2022}
{cmd: help grmatgroups}
{hline}

{title:Title}

{pstd}{hi:grmatgroups} {hline 2} Scatter Plot Matrix with different marker looks according to another variable


{title:Syntax}

{p 8 15 2}
{cmd: grmatgroups} {varlist} {ifin}, over({varname}) [{help grmatgroups##requiredopts:{it:options}}]

{synoptset 25}{...}
{marker requiredopts}{synopthdr: required option}
{synoptline}
{synopt: {opth over(varname)}} specifies variable by which the markers are distinguished
{p_end}

{synoptset 25}{...}
{marker otheropts}{synopthdr: other options}
{synoptline}
{synopt: {opt miss:ing}} treat missing values of {bf: over()} var as normal values
{p_end}
{synopt: {opt h:alf}} only print plots below the diagonal
{p_end}
{synopt: {opt markeroptions(marker_info)}} specifies look of the markers at given values of the {bf: over()} var
{p_end}
{synopt: {opt {x|y}lab:el(rule_or_values)}} specifies look of the axis labels
{p_end}
{synopt: {opt {x|y}sc:ale(rule_or_values)}} specifies scale of the axis labels
{p_end}
{synopt: {opth mlabsize:(textsizestyle)}} size of text in diagonal fields, ie. varnames
{p_end}
{synopt: {opth mlabcolor:(colorstyle)}} color of text in diagonal fields
{p_end}
{synopt: {opt scheme:(scheme)}} overall look (note: some schemes are not compatible)

{synopt: {opth legend(legend_options)}} options regarding contents and look of legend
{p_end}
{synopt: {opth pos:ition(clockposstyle)}} where to put the legend in final graph
{p_end}
{synopt: {opth ring(ringposstyle)}} where to put the legend in final graph
{p_end}
{synopt: {opt span}} legend is centered relative to the whole graph area
{p_end}

{synopt: {help title_options: {it: title_options}}} titles to appear on final graph
{p_end}
{synopt: {bf:{help nodraw_option:nodraw}}} suppress display of graph
{p_end}
{synopt: {bf:{help name_option: name({it:name, ...})}}} specify name for final graph
{p_end}
{synopt: {bf:{help saving_option: saving({it:filename, ...})}}} save final graph in file
{p_end}


{title:Description}

{pstd}{cmd: grmatgroups} returns a matrix of scatter plots, similar to that produced by the command {help graph matrix}, but with different markers according to an {bf: over()} variable. Each value of the this variable is connected to a set of options which can be changed with {bf: markeroptions()}. There will be one legend for the whole graph. The command depends on Vince Wiggins' which has to be installed before using this command ({search grc1leg:search grc1leg} to find and install it).
{p_end}


{title:Options}

{phang}
{opt over(<varname>)} specifies the variable according to which the markers shall look differently. The variable has to be numeric. If the {bf: over()} variable is assigned value labels (see {manhelp label D}), these will be used for the legend of the main graph. If not, the underlying values will be printed in the legend.
The {bf:over()} variable has to be numeric. If you want to use a string variable, please transform it first using {manhelp encode D} with the {it: label} option.

{phang}
{opt missing} treat missing values of {bf: over()} var as normal values. If your {bf: over()} variable has two nonmissing values and one missing value, specifiying the option {bf: missing} will lead to three different markers, the default will produce two different marker types. 

{phang}
{opt half} prints only the lower half of the matrix. Similar to half-option in {help graph matrix:graph matrix}.

{phang}
{opt markeroptions(marker_info)} specifies the look of the markers. markeroptions takes a {it: marker_info} argument which is defined as

{phang2} {it: # marker_options [# marker_options]}

{pstd}
{it: #} denotes the rank of the over value for which the look options are to be changed. The space-separated list {it: marker_options} can contain all marker options that are specified under {help scatter##marker_options:twoway scatter/marker_options}. 
Type for example {bf: markeroptions(1 msymbol(X) mcolor(navy) 2 msymbol(+) mcolor(maroon))}. If the option is not specified, the command will use the default handling of the active scheme. Note that the numbering of the marker options is based not on the values themselves, but on their {it:order}. If your {bf: over()} variable has two levels, 1 and 3, you still have to type {bf: markeroptions(1 ... 2 ...)}. Missing values are listed after nonmissing values.

{phang}
{opt {x|y}label(label_info)} works like {help axis_label_options}. 
{break} Note: To achieve a common plot region size, grmatgroups works with invisible labels, which means that some of the suboptions are disallowed, namely {bf: alternate} and {bf:angle}. {bf:labstyle} is allowed, but not recommended. To get rid of all axis labels, type {bf: xlabel(none) ylabel(none)}.

{phang}
{opt {x|y}scale(scale_info)} works like {help axis_scale_options}. 

{phang}
{opth mlabsize(textsizestyle)} specifies the size of the variable labels in the diagonal plots of the matrix. If you want to change the text itself, please alter the variable label of the variable in question ({manhelp label D}).

{phang}
{opth mlabcolor(colorstyle)} specifies the color of the variable labels in the diagonal plots of the matrix. If you want to change the text itself, please alter the variable label of the variable in question ({manhelp label D}).

{phang}
{opt scheme()} sets a scheme. Note that most schemes lead to suboptimal results. I recommend {it:s1color, s1mono, s2color} or {it: s2mono}. Since most of what is defined by schemes is overwritten by the matrix look, anyways, schemes do not make much of a difference. 

{phang}
{opth legend(legend_options)} changes the contents and look of the legend. If you want to suppress the legend, type {bf: legend(off)}. If you want to change the {it:position} of the legend, please use the three arguments below which are specified outside of the legend option.

{phang}
{opth position(clockposstyle)} changes the position of the legend in the final graph. See {help grc1leg} for more information. 

{phang}
{opth ring(ringposstyle)} specifies where the legend sits in the final graph.

{phang}
{opt span} centers the legend according to the whole graph. See {help title_options##remarks5:Spanning} for more information.


{title:Remarks}

{pstd}
So far, the command works well with the default schemes {it: s2color} and {it: s1color}, but not so well with user-written schemes, such as {it: plottig}, {it: plotplain}, or {it: lean2}. Since the program internally relies on {help twoway scatter}, {help graph combine}, and {help grc1leg}, it is much slower than {it: graph matrix}.

{pstd}
The plots that are not at the margins of the final graph will deviate slightly in their aspect ratio. I have not found a solution for this while also drawing axis labels. If you prefer all plots having exactly the same size, you will have to suppress the axis labels.
{p_end}


{title: Acknowledgments}

{pstd}
Many thanks to Jonas Fischer and Maik Hamjediers for feedback.
{p_end}


{title:Example}
{phang}. sysuse auto, clear{p_end}
{phang}. grmatgroups mpg weight price, over(foreign) ///{p_end}
{phang}.    markeroptions(1 msymbol(X) mcolor(maroon) 2 msymbol(+) mcolor(green)){p_end}




{title:Author}

{phang} Dominik Flügel ({browse "mailto:mail@dominikfluegel.de":mail@dominikfluegel.de}){p_end}


