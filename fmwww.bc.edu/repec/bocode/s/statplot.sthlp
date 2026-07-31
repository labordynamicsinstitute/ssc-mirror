{smcl}
{* 18jul2026}{...}
{hline}
help for {hi:statplot}{right:version 1.3.0}
{hline}

{title:Plots of summary statistics, including plots by category}

{p 4 8 2}
{cmd:statplot}
{it:varlist}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{it:weight}]
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:What is plotted}
{synopt :{cmdab:s:tatistic(}{it:stat}{cmd:)}}summary statistic to plot; default is {cmd:mean}{p_end}
{synopt :{cmd:over(}{it:over_options}{cmd:)}}grouping on the axis; may be repeated once{p_end}
{synopt :{cmd:by(}{it:by_options}{cmd:)}}draw separate panels by a further grouping{p_end}
{synopt :{cmdab:miss:ing}}include missing values of {cmd:over()}/{cmd:by()} variables{p_end}

{syntab:Confidence intervals}
{synopt :{cmd:ci}}add confidence-interval error bars to the bars/dots{p_end}
{synopt :{cmd:level(}{it:#}{cmd:)}}confidence level for {cmd:ci}; default is {cmd:level(95)}{p_end}
{synopt :{cmd:ciopts(}{it:rcap_options}{cmd:)}}look of the CI whiskers{p_end}
{synopt :{cmd:baropts(}{it:bar_options}{cmd:)}}look of the CI bars ({cmd:bar}/{cmd:hbar}){p_end}

{syntab:Percentages and shares}
{synopt :{cmd:percent}}scale the statistic to 0-100 (e.g. a mean of a 0/1 indicator){p_end}
{synopt :{cmd:share}}express each bar as a percentage share of a total{p_end}
{synopt :{cmd:base(}{it:base}{cmd:)}}denominator for {cmd:share}: {cmd:total}, {cmd:var}, or {cmd:over}{p_end}

{syntab:Order of the plotted variables}
{synopt :{cmd:sort}}order the plotted variables (or groups) by value{p_end}
{synopt :{cmdab:des:cending}}with {cmd:sort}, order from high to low{p_end}
{synopt :{cmd:order(}{it:varlist}{cmd:)}}fix the order of the plotted variables{p_end}
{synopt :{cmd:first(}{it:varlist}{cmd:)}}pin these variables first{p_end}
{synopt :{cmd:last(}{it:varlist}{cmd:)}}pin these variables last{p_end}

{syntab:Headings and groups (variables, {cmd:hbar}, no {cmd:over()})}
{synopt :{cmd:headings(}{it:spec}{cmd: = "}{it:label}{cmd:" ...)}}insert section-title rows among the bars{p_end}
{synopt :{cmd:groups(}{it:spec}{cmd: = "}{it:label}{cmd:" ...)}}bracket spans of bars with a side label{p_end}

{syntab:Saving the results set}
{synopt :{cmd:savedata(}{it:filename}[{cmd:, replace}]{cmd:)}}save the collapsed data that is graphed to a {cmd:.dta}{p_end}
{synopt :{cmdab:list:data}}list the collapsed data that is graphed{p_end}
{synopt :{cmd:frame(}{it:name}{cmd:)}}copy the collapsed data into a {help frame:frame} (Stata 16+){p_end}

{syntab:Presentation}
{synopt :{cmd:xpose}}transpose the nesting of the {cmd:over()} groupings{p_end}
{synopt :{cmd:recast(}{it:plottype}{cmd:)}}{cmd:hbar} (default), {cmd:bar}, or {cmd:dot}{p_end}
{synopt :{cmd:wrap(}{it:#}{cmd:)}}wrap axis labels longer than {it:#} characters{p_end}
{synopt :{cmd:varnames}}use variable names, not variable labels, for {it:varlist}{p_end}
{synopt :{cmd:varopts(}{it:varlist_options}{cmd:)}}look of the {it:varlist} bars or dots{p_end}
{synopt :{it:graph_options}}any options of {help graph_bar:graph hbar|bar|dot}{p_end}
{synoptline}

{p 4 6 2}
{cmd:fweight}s, {cmd:aweight}s, {cmd:iweight}s and {cmd:pweight}s may be specified;
whichever weights {help collapse} accepts for the chosen {cmd:statistic()} are
allowed.  The {cmd:ci} option does not accept {cmd:pweight}s.


{title:Description}

{p 4 4 2}
{cmd:statplot} plots summary statistics for {it:varlist}.


{title:Remarks}

{p 4 4 2}
By default {cmd:statplot} is a wrapper for {help graph_bar:graph hbar}.
Optionally, {cmd:statplot} may be recast as a wrapper for
{help graph_bar:graph bar} or {help graph_dot:graph dot}.  The choice is a
matter of personal taste, although in general horizontal displays make it
easier to identify names or labels of categories.

{p 4 4 2}
Like those commands, {cmd:statplot} calls upon {help collapse} to temporarily
produce a reduced dataset of summary statistics.  The difference is that it
organizes that dataset in a different way.  The graphs produced, compared with
those of {cmd:graph hbar|bar|dot}, are typically based more on axis labeling
than on the use of legends, and typically are shown in one color rather than
several.  Thus, they are likely to be closer to a format acceptable for
journal publication.

{p 4 4 2}
Otherwise put, {cmd:statplot} does in one step what would otherwise take a
{help collapse} and some reshaping: it summarizes {it:varlist}, lays the
categories out along the axis rather than in a legend, draws them in a single
colour, and makes reordering, relabelling and grouping the categories easy.
When you want the summarized numbers themselves -- for a companion table, a
check, or a different display -- the {cmd:savedata()}, {cmdab:list:data} and
{cmd:frame()} options (see below) hand that reduced dataset back to you.

{p 4 4 2}
Only one statistic may be plotted at once.  The {cmd:ci}, {cmd:headings()} and
{cmd:groups()} options are the one departure from the {cmd:graph hbar|bar|dot}
engine: because those commands cannot draw error bars or place labels at chosen
positions, these options build the graph with {help twoway} instead (see the
respective sections below).


{title:Options}

{dlgtab:What is plotted}

{p 4 8 2}
{cmdab:s:tatistic()} specifies the summary statistic used to summarize and plot
{it:varlist}.  The default is {cmd:mean}.  See {help collapse} for a full list
of accepted statistics (for example {cmd:median}, {cmd:sd}, {cmd:sum},
{cmd:count}, {cmd:p25}, {cmd:p75}).  Note that only one statistic may be
specified.

{p 4 8 2}
{cmd:over()} contains a call to an {cmd:over()} option (and its
{help graph bar##over_subopts:suboptions}) for {help graph_bar:graph hbar},
{help graph_bar:graph bar} or {help graph_bar:graph dot} as appropriate for
controlling grouping variables for the {it:varlist} on the axis.

{p 8 8 2}
No more than two {cmd:over()} options may be specified.  If two {cmd:over()}
options are used, the order is important for how these groupings are nested.
The second {cmd:over()} will be labeled on the axis and the first option will
be indicated in a legend.  To suppress the legend and place the first
{cmd:over()}'s variable labels closest to the axis, specify either
{cmd:legend(off)} or the {cmd:xpose} option.

{p 4 8 2}
{cmdab:miss:ing} indicates that observations for missing values in {cmd:over()}
or {cmd:by()} variables should be included on the graph.

{dlgtab:Confidence intervals}

{p 4 8 2}
{cmd:ci} adds confidence-interval error bars to a plot of means.  Because
{help graph_bar:graph hbar|bar|dot} cannot draw error bars, {cmd:ci} builds an
equivalent graph with {help twoway} ({cmd:rbar}/{cmd:bar} plus {cmd:rcap}, or
{cmd:rcap} plus {cmd:scatter} under {cmd:recast(dot)}).  The intervals are the
ordinary t-based confidence intervals of the mean (the same numbers as
{helpb ci:ci means}), computed from the mean, its standard error and the group
size returned by {help collapse}.

{p 8 8 2}
{cmd:ci} requires {cmd:statistic(mean)} (the default) and does not accept
{cmd:pweight}s.  It supports no {cmd:over()}, one {cmd:over()} with a single
variable, and one {cmd:over()} with several variables (drawn as small
multiples, one panel per variable).  Two {cmd:over()} options, or {cmd:by()},
are not supported with {cmd:ci}; for those, or for weighted intervals, see
{help cibar:cibar} (Staudt) or {help coefplot:coefplot} (Jann), from SSC.
{it:Use case:} a reviewer asks for 95% CIs on a bar chart of group means.

{p 8 8 2}
Because the {cmd:ci} graph is built with {help twoway} rather than
{cmd:graph bar}, the {cmd:xpose} and {cmd:varopts()} options have no effect
under {cmd:ci}, and {cmd:base()} is reserved by the {cmd:share} option (so it
cannot be forwarded to {cmd:twoway bar}).

{p 4 8 2}
{cmd:level(#)} sets the confidence level; the default is {cmd:level(95)} (or
{cmd:c(level)}).

{p 4 8 2}
{cmd:ciopts()} passes options to the {help rcap_options:rcap} whiskers, for
example {cmd:ciopts(lcolor(gs6))} for grey error bars.

{p 4 8 2}
{cmd:baropts()} passes options to the CI bars in {cmd:recast(hbar)} (the
default) and {cmd:recast(bar)} mode, for example {cmd:baropts(fcolor(gs10)
lcolor(gs6))}.  It has no effect under {cmd:recast(dot)}.

{dlgtab:Percentages and shares}

{p 4 8 2}
{cmd:percent} multiplies the plotted statistic by 100.  Its main use is with
0/1 indicator variables, where the mean is a proportion and {cmd:percent}
turns it into a percentage ("share answering yes").  The value-axis title
becomes {cmd:percent}.  {it:Use case:} plotting the percentage in each group
who agree with a survey item.  To print a {cmd:%} sign on each bar, add
{cmd:blabel()} (see {it:Bar value labels} below).

{p 8 8 2}
{cmd:percent} must be spelled in full.  The abbreviations {cmd:per} and
{cmd:perc}, and the full word {cmd:percentages}, are passed through to
{help graph_bar:graph hbar|bar}'s own {cmd:percentages} option (which rescales
bars to sum to 100 across the {cmd:over()} categories) rather than to this
{cmd:percent} option.

{p 4 8 2}
{cmd:share} rescales the bars to percentage shares of a total.  {cmd:base()}
chooses the denominator:

{p 8 12 2}{cmd:base(total)} (the default) each bar as a percent of the grand
total of all bars (all bars sum to 100).{p_end}
{p 8 12 2}{cmd:base(var)} each bar as a percent of its own variable's total
across groups (each variable sums to 100 across the axis).{p_end}
{p 8 12 2}{cmd:base(over)} each bar as a percent of its group's total across
variables (each group sums to 100).{p_end}

{p 8 8 2}
{cmd:share} is most natural with {cmd:statistic(sum)} or {cmd:statistic(count)}.
{it:Use case:} showing how counts are distributed across categories as
percentages, without collapsing and normalizing by hand.  For frequencies,
fractions or percents of {it:categorical} data, {help catplot:catplot} (Cox,
from SSC) is a close relative.

{dlgtab:Order of the plotted variables}

{p 4 8 2}
{cmd:sort} orders the bars or dots by the plotted value.  With two or more
variables in {it:varlist} it orders the variables by their statistic; with a
single variable and an {cmd:over()} it orders the groups.  {cmd:descending}
orders from high to low.  {it:Use case:} turning an alphabetical bar chart into
a ranking.

{p 4 8 2}
{cmd:order(varlist)} fixes the order of the plotted variables to the order
given (any variables not listed follow, in their sorted or original order).
{cmd:first(varlist)} and {cmd:last(varlist)} pin variables to the start or end.
{it:Use case:} ranking survey items by value but forcing a residual category
such as "None of these" to appear last: {cmd:sort descending last(none)}.

{dlgtab:Headings and groups}

{p 4 8 2}
{cmd:headings()} and {cmd:groups()} label sections of the plotted variables,
after the options of the same names in {help coefplot:coefplot} (Jann, from
SSC).  Each takes one or more {it:spec}{cmd: = "}{it:label}{cmd:"} entries,
where {it:spec} is one or more variable names (with {cmd:*} and {cmd:?}
wildcards).  Bold and other {help text:text} markup may be used in the labels,
e.g. {cmd:"{bf:Access}"}.

{p 8 8 2}
{cmd:headings()} inserts each label as a section-title row immediately before
the first variable its {it:spec} matches, shifting the following bars down.
{cmd:groups()} draws each label as a bracket beside the span of variables its
{it:spec} matches, without shifting anything.  {it:Use case:} grouping survey
items under section titles such as "Access" and "Quality".

{p 8 8 2}
Because these labels occupy positioned rows, they build the graph with
{help twoway} (as {cmd:ci} does), and are supported only for variables plotted
without {cmd:over()}, in {cmd:recast(hbar)} (the default).  They may be combined
with {cmd:ci}.

{dlgtab:Saving the results set}

{p 4 8 2}
{cmd:savedata(}{it:filename}[{cmd:, replace}]{cmd:)} saves the collapsed dataset
that underlies the graph -- the exact numbers that are plotted -- to a
{cmd:.dta} file.  {cmdab:list:data} lists that dataset to the Results window.
{cmd:frame(name)} copies it into a named {help frame:frame} (requires Stata 16
or later).  {it:Use case:} building a companion table, quality-checking the
bars against the numbers, or reusing the summary without re-running
{cmd:collapse}.  The saved numbers reflect any {cmd:percent}/{cmd:share}
rescaling.  Under {cmd:ci}, the saved data also carries the interval bounds
({cmd:mean}, {cmd:lo}, {cmd:hi}, {cmd:se}, {cmd:N}).

{dlgtab:Presentation}

{p 4 8 2}
{cmd:xpose} transposes or switches the grouping labels for {cmd:over()}
options.  If no {cmd:over()} options are specified, {cmd:xpose} has no effect.
If one {cmd:over()} option is used, {cmd:xpose} switches the position of the
{it:varlist} labels from the outermost nesting to closest to the axis.  If two
{cmd:over()} options are used, {cmd:xpose} switches the {it:varlist} labels to
the legend (which can be suppressed with {cmd:legend(off)}), moves the first
{cmd:over()} labels closest to the axis, and moves the second {cmd:over()}
labels off the axis.

{p 4 8 2}
{cmd:recast()} recasts the graph to another {it:plottype}, one of {cmd:hbar},
{cmd:bar}, or {cmd:dot}.

{p 4 8 2}
{cmd:wrap(#)} wraps axis labels longer than {it:#} characters onto several
lines, breaking at spaces.  It applies to the {it:varlist} labels and to the
{cmd:over()}/{cmd:by()} category labels, and changes only the label text, never
the plotted values.  {it:Use case:} long survey-item or policy-category labels
that would otherwise overrun or shrink on the axis.

{p 8 8 2}
Wrapped labels need vertical room.  With many {cmd:over()} categories the
multi-line labels can crowd; give them space with a larger {cmd:ysize()} and/or
a smaller label size, e.g. {cmd:varopts(label(labsize(small)))}.

{p 4 8 2}
{cmd:varnames} indicates that variable names should be used instead of variable
labels for {it:varlist}.

{p 4 8 2}
{cmd:varopts()} specifies options for the display of the {it:varlist} bars or
dots.  For example, labels could be modified with
{cmd:varopts(label(labsize(medsmall)))}.

{p 4 8 2}
{it:graph_options} refer to options of {help graph_bar:graph hbar},
{help graph_bar:graph bar} or {help graph_bar:graph dot} as appropriate.

{marker blabel}{...}
{dlgtab:Bar value labels (and a % sign)}

{p 4 8 2}
Numeric labels on the bars come straight from {help blabel_option:blabel()},
which {cmd:statplot} passes through untouched, for example
{cmd:blabel(bar, format(%3.1f))}.  In Stata 19 and later, {cmd:blabel()} gained
{cmd:prefix()} and {cmd:suffix()} suboptions, so a {cmd:%} sign (or any literal
text) can be appended to each bar:

{p 8 8 2}{cmd:. statplot union, over(race) percent blabel(bar, format(%2.0f) suffix(%))}

{p 4 8 2}
There is no numeric format that appends a {cmd:%} on its own, so on Stata 18 and
earlier use the {help Graph Editor:Graph Editor} for a per-bar {cmd:%} sign.


{title:Examples}

{p 4 8 2}{cmd:. sysuse citytemp, clear}{p_end}
{p 4 8 2}{cmd:. statplot heatdd cooldd}{p_end}
{p 4 8 2}{cmd:. statplot heatdd cooldd, over(region)}{p_end}
{p 4 8 2}{cmd:. statplot heatdd cooldd, over(region) sort descending}{p_end}
{p 4 8 2}{cmd:. statplot temp*, over(region, sort(1) descending) s(sd) blabel(bar, format(%2.1f)) ysc(r(. 17.5))}

{p 4 8 2}{it:Controlling the order of the bars}{p_end}
{p 4 8 2}{cmd:. statplot tempjan tempjuly heatdd cooldd, sort}                {it:// low to high by value}{p_end}
{p 4 8 2}{cmd:. statplot tempjan tempjuly heatdd cooldd, sort descending}     {it:// high to low}{p_end}
{p 4 8 2}{cmd:. statplot tempjan tempjuly heatdd cooldd, order(cooldd heatdd)} {it:// fix the first two; the rest follow}{p_end}
{p 4 8 2}{cmd:. statplot tempjan tempjuly heatdd cooldd, first(cooldd) last(tempjan)} {it:// pin one first, one last}{p_end}
{p 4 8 2}{cmd:. statplot tempjan tempjuly heatdd cooldd, sort descending last(tempjan)} {it:// rank by value, but pin one bar last}{p_end}
{p 4 8 2}{cmd:. statplot heatdd, over(division) sort descending}             {it:// one variable: sort the over() groups}{p_end}

{p 4 8 2}{cmd:. sysuse census, clear}{p_end}
{p 4 8 2}{cmd:. statplot marriage divorce, over(region) s(sum)}{p_end}
{p 4 8 2}{cmd:. statplot marriage divorce, over(region) s(sum) xpose}{p_end}
{p 4 8 2}{cmd:. statplot marriage divorce, over(region) s(sum) share base(var)}{p_end}

{p 4 8 2}{it:Percentage of a 0/1 indicator, labeled with a % sign}{p_end}
{p 4 8 2}{cmd:. sysuse nlsw88, clear}{p_end}
{p 4 8 2}{cmd:. statplot union, over(race) percent blabel(bar, format(%2.0f) suffix(%))}

{p 4 8 2}{it:Means with 95% confidence intervals}{p_end}
{p 4 8 2}{cmd:. statplot wage, over(race) ci}{p_end}
{p 4 8 2}{cmd:. statplot wage ttl_exp tenure, over(race) ci recast(bar)}{p_end}
{p 4 8 2}{cmd:. statplot wage, over(race) ci level(90) baropts(fcolor(navy)) ciopts(lcolor(gs6))}

{p 4 8 2}{it:Wrapping long labels}{p_end}
{p 4 8 2}{cmd:. statplot ttl_exp tenure grade hours, wrap(18)}

{p 4 8 2}{it:Section headings and group labels among the bars}{p_end}
{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. statplot price mpg weight length, headings(price = "{bf:Cost}" weight = "{bf:Size}")}{p_end}
{p 4 8 2}{cmd:. statplot price mpg weight length, groups(price mpg = "{bf:Performance}" weight length = "{bf:Size}") ci}

{p 4 8 2}{it:Keeping the numbers behind the bars}{p_end}
{p 4 8 2}{cmd:. sysuse nlsw88, clear}{p_end}
{p 4 8 2}{cmd:. statplot wage ttl_exp, over(race) savedata(wage_by_race, replace)}{p_end}
{p 4 8 2}{cmd:. statplot wage ttl_exp, over(race) listdata}

{p 4 8 2}{it:Using} {help separate} {it:with a single variable and one} {cmd:over()}{p_end}
{p 4 8 2}{cmd:. statplot wage, over(race) over(union)}{p_end}
{p 4 8 2}{cmd:. separate wage, by(race) veryshortlabel}{p_end}
{p 4 8 2}{cmd:. statplot wage?, over(union)}


{title:Stored results}

{p 4 8 2}{cmd:statplot} is {cmd:rclass} and stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations plotted{p_end}
{synopt:{cmd:r(N_vars)}}number of variables in {it:varlist}{p_end}
{synopt:{cmd:r(N_groups)}}number of {cmd:over()}/{cmd:by()} group combinations{p_end}
{synopt:{cmd:r(level)}}confidence level (with {cmd:ci} only){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:statplot}{p_end}
{synopt:{cmd:r(statistic)}}the statistic plotted{p_end}
{synopt:{cmd:r(varlist)}}the variables plotted, in the order plotted{p_end}


{title:Authors}

{p 4 4 2}Eric A. Booth, Texas 2036 {break}
         eric.a.booth@gmail.com

{p 4 4 2}Nicholas J. Cox, Durham University{break}
         n.j.cox@durham.ac.uk


{title:Also see}

{p 4 8 2}Built in:  {help graph_hbar:graph hbar}, {help graph_bar:graph bar},
{help graph_dot:graph dot}, {help collapse}, {help blabel_option:blabel()}

{p 4 8 2}Community-contributed, from SSC (for example,
{cmd:ssc install catplot}):  {help catplot:catplot} and {help tabplot:tabplot}
(Nicholas J. Cox); {help cibar:cibar} (Alexander Staudt);
{help coefplot:coefplot} (Ben Jann)
