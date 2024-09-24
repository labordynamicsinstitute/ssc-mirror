{smcl}
{* 16may2004/7jun2010/23sep2024}{...}
{hline}
help for {hi:catplot}
{hline}

{title:Title} 

{p 4 4 2}Plots of frequencies, fractions or percents of categorical data

{p 8 17 2} 
{cmd:catplot} 
[{it:weight}]
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]
{cmd:,}
{cmd:over(}{it:firstvar}{cmd:, }{it:over_options}{cmd:)}{break}
[
{cmd:over(}{it:secondvar}{cmd:, }{it:over_options}{cmd:)}
{cmd:by(}{it:thirdvar}{cmd:, }{it:by_options}{cmd:)}
{break} 
{c -(}{cmdab:fr:action}{c |}{cmdab:fr:action(}{it:varlist}{cmd:)}{c |}{cmdab:perc:ent}{c |}{cmdab:perc:ent(}{it:varlist}{cmd:)}{c )-} {break} 
{cmd:recast(}{it:plottype}{cmd:)} 
{it:graph_options}
]


{title:Description}

{p 4 4 2}
{cmd:catplot} shows frequencies (or optionally fractions or percents)
of the categories of one, two or three categorical variables. The
first-named variable {it:firstvar}, specified with an {cmd:over()} 
option, is innermost on the display; that is,
its categories vary fastest. Often, but not necessarily, it will be the
substantive response or outcome of interest. One or two other variables,
perhaps with predictor roles, may be specified using a second {cmd:over()} 
option and/or a {cmd:by()} option. 

{p 4 4 2}
By default {cmd:catplot} is a wrapper for {help graph_bar:graph hbar}.
Optionally {cmd:catplot} may be recast as a wrapper for      
{help graph bar} or {help graph_dot:graph dot}.  The choice is a
matter of personal taste, although in general horizontal displays make
it easier to identify names or labels of categories. 

{p 4 4 2}
{cmd:fweight}s, {cmd:aweight}s and {cmd:iweight}s may be specified. This
opens a door to use of {cmd:catplot} for plotting any set of values
for each of several different categories. 


{title:Quick start}

{p 4 4 2}Read in data{p_end}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}

{p 4 4 2}Horizontal bar chart showing category frequencies{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78)}{p_end}

{p 4 4 2}Horizontal bar chart showing category percents{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78) percent}{p_end}

{p 4 4 2}Given foreign or domestic, what is percent breakdown of repair record?{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78) over(foreign) percent(foreign)}{p_end}

{p 4 4 2}Given repair record, what is percent breakdown of foreign or domestic?{p_end}

{p 4 8 2}{cmd:. catplot, over(foreign) over(rep78) percent(rep78)}{p_end}

{p 4 4 2}And show the percents as numeric text? (You may need to add some space){p_end}

{p 4 8 2}{cmd:. catplot, over(foreign) over(rep78) percent(rep78) blabel(bar, format(%02.0f)) ysc(r(0 105))}{p_end}

{p 4 4 2}Show that as a side-by-side display {c -} and add an axis title too{p_end}

{p 4 8 2}{cmd:. catplot, by(foreign, l1title(Repair record 1978)) over(rep78) percent(rep78) blabel(bar, format(%02.0f)) ysc(r(0 105))}{p_end}


{title:Options} 

{p 4 8 2}
{cmd:over()} and {cmd:by()} options are intended to work as in 
{help graph bar}. Note however that {cmd:by(, total)} is not 
smart enough to work with fraction or percent options. 

{p 4 8 2}
{cmd:fraction} indicates that all frequencies should be shown as
fractions (with sum 1) of the total frequency of all values being
represented in the graph.

{p 4 8 2}
{cmd:fraction(}{it:varlist}{cmd:)} indicates that all frequencies should
be shown as fractions (with sum 1) of the total frequency for each
distinct category defined by the combinations of its {it:varlist}. For
example, given a variable {cmd:male} with two categories male and female,
the fractions shown for male would have sum 1 and those for female would
have sum 1. 

{p 4 8 2}
{cmd:percent} indicates that all frequencies should be shown as
percents (with sum 100) of the total frequency of all values being
represented in the graph.

{p 4 8 2}
{cmd:percent(}{it:varlist}{cmd:)} indicates that all frequencies should
be shown as percents (with sum 100) of the total frequency for each
distinct category defined by the combinations of its {it:varlist}.  For
example, given a variable {cmd:male} with two categories male and female,
the percents shown for male would have sum 100 and those for female
would have sum 100. 

{p 8 8 2}
Only one of these {cmd:fraction}[{cmd:()}] and
{cmd:percent}[{cmd:()}] options may be specified. 

{p 4 8 2}
{cmd:recast()} recasts the graph to another {it:plottype}, one
of {cmd:hbar}, {cmd:bar}, {cmd:dot}. 

{p 8 8 2}
Note for users of Stata 10 up: using the {help Graph Editor} is another 
way to produce these and many other changes. 

{p 8 8 2}
Note for experienced users: although the name is suggested by another
{help advanced_options:recast()} option, this is not a back door to recasting
to a {cmd:twoway} plot. 

{p 4 8 2}
{it:graph_options} refers to other options of 
{help graph_bar:graph bar}, {help graph_bar:graph hbar} or 
{help graph_bar:graph dot} as appropriate.  

{p 8 8 2}
Note: you may find it helpful to display information on variables using
{cmd:l1title()} with {cmd:hbar} or {cmd:dot}; or {cmd:b1title()} with
{cmd:bar} or {cmd:dot} with the (undocumented) {cmd:vertical} option; or
with {cmd:subtitle()} in general. See also Remarks below on axis titles. 


{title:Remarks}

{it:Why and how this command was written}

{p 4 4 2}
This version of {cmd:catplot} is a moderate rewriting of the previous
version of {cmd:catplot} from SSC, now there renamed {cmd:catplot2010}.  
The rewriting reflects personal experience and judgement. The
revised syntax is offered as less awkward. The command is also perhaps
now better explained and exemplified. 

{p 4 4 2}
The original posting about {cmd:catplot} on Statalist (Cox 2003)
explained the main idea. I wanted a one-line command to plot counts, or
fractions, or percents of observations of one or more categorical
variables.  {cmd:graph hbar} and its kin, as released in Stata 8, would
do this if you first fed one of those commands a variable to be summed
over observations.  Suppose you have 10 observations and you can see
from listings that you have 7 frogs and 3 toads. Stata will come to the
same conclusion once you create a variable that is identically 1 in each
observation and then ask for sums. Evidently 1 + 1 + 1 + 1 + 1 + 1 + 1 =
7 and 1 + 1 + 1 = 3 are the counts you need.  So counting is just
summation. So also is working out fractions and percents. For those you
feed Stata, in this example, a variable with observations each
containing 1/10 and 100 (1/10) respectively.  More complicated set-ups,
such as wanting percent breakdowns of the categories of categorical
variable {it:C} given cross-combinations of categorical variables {it:A}
and {it:B}, are just trivial extensions of the main idea {c -} once you
have worked out the details. 

{p 4 4 2}
The easy part is thus writing a wrapper for {cmd:graph hbar} and its kin
in which such a variable is created on the fly before calling up the
main command. The more challenging part is combining that code with the
official {cmd:graph} code that does the hard work, principally through
{cmd:over()} and {cmd:by()} options as well as other {cmd:graph}
options. Indeed, the user needs to be able to choose between {cmd:hbar},
{cmd:bar} and {cmd:dot} as the engine. The original version (Cox 2003)
did that one way and the second version (Cox 2010) did it another way.  The
first version was discussed in Cox (2004), while the second version has
been discussed mainly on Statalist. Now this {cmd:catplot} is a new version
that is closer to the official Stata implementation of newer
commands {cmd:graph hbar (count)} and {cmd:graph hbar (percent)}, first 
released on 9 October 2014 within the life of Stata 13 (see 
{help whatsnew13}). 


{it:catplot principles and practice}

{p 4 4 2}
The default display of {cmd:catplot} using {cmd:graph hbar} or
{cmd:graph bar} is graphically conservative, reflecting the view that
height or length of bars and text indicating categories are good ways of
conveying information.  If you wish also to have bars in different
colours, specify the option {cmd:asyvars}, which differentiates the
categories of the first-named variable.  If you wish also to stack bars
of different colours, specify the further option {cmd:stack}.

{p 4 4 2}
The default display of {cmd:catplot} using {cmd:graph dot} is
similarly conservative.  If you wish to have point symbols in different
colours, specify the option {cmd:asyvars}, which differentiates the
categories of the first-named variable. If you wish also to use
different point symbols, use the further option {cmd:marker()}. 

{p 8 8 2}
Such choices may or may not improve the graph. Personal suggestions:
legends are to be avoided if possible; multiple colours can confuse as
much as they clarify; stacking may make it harder to compare categories
with rare or zero frequencies or to show annotation visibly. 

{p 4 4 2}
There is much scope for personal judgment over what is presented as
{it:firstvar}, {it:secondvar} and {it:thirdvar}. Indeed, in the {it:Titanic}
example below, the mean survival proportion presented as weights is the
outcome of interest. A simple comparison such as 

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. catplot, percent(foreign) over(rep78) over(foreign) name(G1)}{p_end}
{p 4 8 2}{cmd:. catplot, percent(foreign) over(foreign) over(rep78) name(G2)}{p_end}

{p 4 4 2}
highlights the possibilities for displaying the same results 
differently. Note the moral that the order of {cmd:over()} options 
does matter. 

{p 4 4 2}
As usual, running the examples should impart a good sense of what the
command can do. Some examples using {cmd:collgrad} (college graduate?)
from the {cmd:nlsw88} data are redundant in the sense that
{cmd:collgrad} is a (0, 1) indicator variable, so that it would be
simpler to plot means, so avoiding the redundancy of plotting two
complementary fractions or percents, but they may help to underline how
the command works.

{p 4 4 2}
All that said, a personal suggestion is that many one-, two- or
three-way breakdowns of categorical data are better served by
{cmd:tabplot}. See Cox (2016) and {cmd:search tabplot, sj} for updates. 


{it:Axis titles}

{p 4 4 2}
It is clearly documented that 

{p 8 8 2}
the axis of {cmd:graph bar}, {cmd:graph hbar} and {cmd:graph dot}
showing magnitudes is always regarded as the {it:y} axis, even if it is
horizontal, while

{p 8 8 2}
the other axis in those commands is always regarded as a categorical
axis, and {it:not} as the {it:x} axis, regardless of whether it is
horizontal or vertical. 

{p 4 4 2}
For any programmer coding with these commands, and any user working with
them directly or indirectly, these choices become hard rules. In
{cmd:catplot} the {cmd:ytitle()} defaults to simple text such as
"frequency", "fraction" or "percent" (unless you are using weights), but
you are encouraged to over-write that default with any text closer to
your purpose. That title is displayed horizontally if you are using
{cmd:graph hbar} or {cmd:graph dot} and vertically if you are using
{cmd:graph bar} or {cmd:graph dot, vertical}. 

{p 4 4 2}
While attempts to set an {cmd:xtitle()} will fail, a rich variety of
other {help title options} are available. The examples show some of the
possibilities. 


{it:Homespun and other wisdom}

{p 4 4 2}
Note some simple principles in this territory:

{p 8 8 2}
It is difficult to create a great graph, but easy to improve a bad one. 

{p 8 8 2}
Comparisons should be easy. That could mean in one dimension, across a
row or down a column, or it could mean using a table structure. 

{p 8 8 2}
Ordering by magnitude may be even more useful than ordering by category. 

{p 8 8 2}
Bars are better than pie slices as length is easier to judge than angle.
Dots on a scale are a good way to include magnitudes. 

{p 8 8 2}
Text is better read as horizontal than as vertical. 

{p 8 8 2}
Showing numbers as text as well by graphical elements can be helpful. 

{p 8 8 2}
Lose the legend if you can. A great advantage of 
{cmd:graph hbar {c |} bar {c |} dot} is strong support for category
labels, which can be nested too. 

{p 8 8 2}
The sum of one value is just that value, so weights allow showing any
values, not just frequencies or percents. 

{p 8 8 2}
{cmd:by()} allows table structures to be shown with
{cmd:graph hbar {c |} bar {c |} dot}. 

{p 8 8 2}
{cmd:by()} can look like another {cmd:over()}. 


{title:Examples}

{p 4 8 2}Choose a different scheme according to taste or if using Stata 17 or earlier.{p_end}
{p 4 8 2}{cmd:. set scheme stcolor}

{p 4 4 2}(Stata's auto data){p_end}
{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78) l1title(Repair record 1978) name(CAT1, replace)}{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78, sort(1)) l1title(Repair record 1978) name(CAT2, replace)}{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78, sort(1) descending) l1title(Repair record 1978) name(CAT3, replace)}{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78) l1title(Repair record 1978) blabel(bar, pos(base) size(4)) bar(1, bfcolor(none)) ysc(off) name(CAT4, replace)}{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78) over(foreign) subtitle(Car origin and Repair record 1978) name(CAT5, replace)}{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78) over(foreign) subtitle(Car origin and Repair record 1978) nofill name(CAT6, replace)}{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78) by(foreign, note("") l1title(Repair record 1978)) percent(foreign) name(CAT7, replace)}{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78) by(foreign, note("")) b2title(Repair record 1978) percent(foreign) recast(bar) name(CAT8, replace)}{p_end}

{p 4 8 2}{cmd:. catplot, over(rep78) by(foreign, note("") l1title(Repair record 1978)) percent(foreign) blabel(bar, position(outside) format(%3.1f)) ylabel(none) yscale(r(0,60)) name(CAT9, replace)}{p_end}

{p 4 8 2}(Stata's nlsw88 data){p_end}
{p 4 8 2}{cmd:. sysuse nlsw88, clear}{p_end}

{p 4 8 2}{cmd:. catplot, over(collgrad) over(race) by(married, note("")) name(CAT10, replace)}{p_end}
{p 4 8 2}{cmd:. catplot, over(collgrad) over(race) by(married, note("")) recast(dot) name(CAT11, replace)}{p_end}

{p 4 8 2}{cmd:. local opts percent(race married) blabel(bar, format(%02.1f))}{p_end}

{p 4 8 2}{cmd:. catplot, over(collgrad) over(race) by(married, note("")) `opts' name(CAT12, replace)}{p_end}

{p 4 8 2}{cmd:. local trick subtitle(, pos(9) ring(1) bcolor(none) nobexpand place(e))}{p_end}
{p 4 8 2}{cmd:. local opts `opts' `trick'}{p_end}
	
{p 4 8 2}{cmd:. catplot, over(married) over(race) by(collgrad, col(1) note("")) `opts' name(CAT13, replace)}{p_end}
{p 4 8 2}{cmd:. catplot, over(married) over(race) by(collgrad, col(1) note("")) recast(bar) `opts' name(CAT14, replace)}{p_end}
{p 4 8 2}{cmd:. catplot, over(married) over(race) by(collgrad, col(1) note("")) recast(dot) `opts' name(CAT15, replace)}{p_end}
	
{p 4 8 2}({it:Titanic} data: Dawson 1995){p_end}
{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. input byte(class adult male) float survived}{p_end}
{p 4 8 2}{cmd:1 0 0         1}{p_end}
{p 4 8 2}{cmd:2 0 0         1}{p_end}
{p 4 8 2}{cmd:3 0 0  .4516129}{p_end}
{p 4 8 2}{cmd:1 0 1         1}{p_end}
{p 4 8 2}{cmd:2 0 1         1}{p_end}
{p 4 8 2}{cmd:3 0 1 .27083334}{p_end}
{p 4 8 2}{cmd:1 1 0  .9722222}{p_end}
{p 4 8 2}{cmd:2 1 0  .8602151}{p_end}
{p 4 8 2}{cmd:3 1 0  .4606061}{p_end}
{p 4 8 2}{cmd:4 1 0  .8695652}{p_end}
{p 4 8 2}{cmd:1 1 1  .3257143}{p_end}
{p 4 8 2}{cmd:2 1 1 .08333334}{p_end}
{p 4 8 2}{cmd:3 1 1 .16233766}{p_end}
{p 4 8 2}{cmd:4 1 1  .2227378}{p_end}
{p 4 8 2}{cmd:end}{p_end}
{p 4 8 2}{cmd:. label values class class}{p_end}
{p 4 8 2}{cmd:. label def class 1 "first" 2 "second" 3 "third" 4 "crew" }{p_end}
{p 4 8 2}{cmd:. label values adult adult}{p_end}
{p 4 8 2}{cmd:. label def adult 0 "child" 1 "adult"}{p_end}
{p 4 8 2}{cmd:. label values male male}{p_end}
{p 4 8 2}{cmd:. label def male 0 "female" 1 "male"}{p_end}

{p 4 8 2}{cmd:. catplot [aw=100*survived], over(adult, gap(*0.3) axis(noline)) over(male, gap(*0.8)) outergap(*.2) ///}{p_end}
{p 4 8 2}{cmd:by(class, compact note("") col(1) subtitle(% survived from Titanic))   ///}{p_end}
{p 4 8 2}{cmd:bar(1, blcolor(gs8) bfcolor(pink*.1)) blabel(bar, format(%4.1f) pos(base)) `trick' ///}{p_end}
{p 4 8 2}{cmd:ysize(7) yla(none) ytitle("") ysc(noline) name(CAT16, replace)}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break} 
         n.j.cox@durham.ac.uk

	 
{title:Acknowledgments} 

{p 4 4 2}The first version of {cmd:catplot} was written and revised in
2003 and 2004.  At that time, Vince Wiggins provided very helpful
comments, Fred Wolfe asked for sorting and David Schwappach provided
feedback on limitations. During revision in 2010, Vince Wiggins and 
Ron{c a'}n Conroy made encouraging noises. 


{title:References}

{p 4 8 2}
Cox, N.J. 2003. 
st: -catplot- available for download from SSC. 
Statalist post 21 February. 
{browse "https://www.stata.com/statalist/archive/2003-02/msg00608.html":https://www.stata.com/statalist/archive/2003-02/msg00608.html}

{p 4 8 2}
Cox, N.J. 2004. 
Speaking Stata: Graphing categorical and compositional data. 
{it:Stata Journal} 4: 190{c -}215.
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X0400400209":https://journals.sagepub.com/doi/pdf/10.1177/1536867X0400400209}                            

{p 4 8 2}
Cox, N.J. 2010.
st: -catplot- revised on SSC. 
Statalist post 8 June.  
{browse "https://www.stata.com/statalist/archive/2010-06/msg00431.html":https://www.stata.com/statalist/archive/2010-06/msg00431.html}

{p 4 8 2}
Cox, N.J. 2016. 
Multiple bar charts in table form.
{it:Stata Journal} 16: 491{c -}510.  
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X1601600214":https://journals.sagepub.com/doi/pdf/10.1177/1536867X1601600214}                          

{p 4 8 2}
Dawson, R.J.MacG. 1995.
The "unusual episode" data revisited. 
{it:Journal of Statistics Education} 3(3).
[{it:Titanic} data]
{browse "https://jse.amstat.org/v3n3/datasets.dawson.html":https://jse.amstat.org/v3n3/datasets.dawson.html}


{title:Also see}

{p 4 8 2}On-line:  help for {help graph_hbar:graph hbar}; 
{help graph_bar:graph bar}; {help graph_dot:graph dot}; {help histogram}; 
{help tabplot} (if installed)

