{smcl}
{* 24sep2024}{...}
{cmd:help framed_bar}
{hline}

{title:Title}

{p2colset 5 15 19 2}{...}
{p2col :{hi:framed_bar} {hline 2} Framed bar charts}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
Syntax 1: 

{p 8 17 2} 
{cmd:framed_bar} 
{varname}
{ifin}
{weight}
{cmd:,}
{opt over(groupvar)}
[
{it:statistical_options}
{it:bar_chart_options}
{it:annotation_options}
{it:twoway_options} 
{it:display_options} 
] 

{p 8 17 2}
Syntax 2: 

{p 8 17 2} 
{cmd:framed_bar} 
{varlist}
{ifin}
{weight}
[
{cmd:,}
{it:statistical_options}
{it:bar_chart_options}
{it:annotation_options}
{it:twoway_options} 
{it:display_options} 
]

{p 4 4 2}
fweights, aweights, pweights and iweights are allowed: see {help weight}.


{title:Description}

{p 4 4 2}
{cmd:framed_bar} draws framed bar charts showing summary statistics for 
one or more numeric variables. Frames comparing bars with limiting values
can work to simplify, by making an obvious complement tacit rather than
explicit, and to clarify, by making near extremes evident. 

{p 4 4 2}
Recall that when you are drinking from a glass, your glass can be easily
judged as (nearly) full, (nearly) empty, or in between. The glass analogy 
works better with vertical bars.  

{p 4 4 2}
It is best explained statistically by a leading application. Suppose we have a
binary (Boolean, dichotomous, dummy, indicator, logical, one-hot,
quantal, zero-one) variable conventionally coded 0 or 1. A common jargon
is that the state coded 0 is dubbed {it:failure} and the state coded 1
is dubbed {it:success}; sometimes these terms are evocative and
otherwise they are just terms of art. 

{p 4 4 2}
A common graphic for such data is a stacked bar chart showing the
proportions of whatever is coded 0 and whatever is coded 1. However,
missing values aside, those two proportions necessarily add to 1. Hence
an alternative graphic is just a bar chart showing the proportion of
successes within a frame of height or length 1. The empty space
corresponds to the proportion of failures. Equivalently, such a bar
chart plots the mean or means of one or more sets of binary values, as a
mean of such a (0, 1) variable is just the proportion of successes. 

{p 4 4 2}
Variations on this design are offered by default or may be achieved by
options. Headline possibilities include

{p 8 8 2}
Any single summary statistic offered by {help collapse} may be chosen
rather than means.  

{p 8 8 2}
Annotation by default shows the statistics (say means) concerned as a
numeric text display. 

{p 8 8 2}
Annotation may be shown optionally of sample sizes as a numeric text
display. 

{p 8 8 2}
Values shown may on the fly be replaced according to a specified
calculation. 

{p 8 8 2}
Frames may be suppressed. A frame may be irrelevant to your data or your
purpose, but you may like the design otherwise.


{title:Quick start} 

{p 4 8 2}{cmd:. set scheme stcolor}{p_end}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}

{p 4 4 2}% foreign by repair record: frames at 100%{p_end}
{p 4 8 2}{cmd:. framed_bar foreign, over(rep78) calc(100*@) frame(100) barlabel(mlabf(%2.0f)) yla(none) ytitle(% foreign)}{p_end}

{p 4 8 2}{cmd:. sysuse nlsw88, clear}{p_end}

{p 4 8 2}{cmd:. local yla yla(0(20)100)}{p_end}
{p 4 8 2}{cmd:. local xla xla(0(20)100)}{p_end}
{p 4 8 2}{cmd:. local blab mlabs(large) mlabf(%2.1f)}{p_end}

{p 4 4 2}% for various indicators: frames at 100%{p_end}
{p 4 8 2}{cmd:. framed_bar never married collgrad smsa, calc(100*@) frame(100) barlabel(`blab') count(size(medlarge)) `yla' ytitle(Percent)}{p_end}

{p 4 4 2}All possible observations, or casewise deletion: sample sizes shown{p_end}
{p 4 8 2}{cmd:. framed_bar union married collgrad smsa, calc(100*@) allobs sort frame(100) barlabel(`blab') count(mlabs(medlarge)) `yla' ytitle(Percent)}{p_end}

{p 4 4 2}Number of missing values (by subtraction from sample size){p_end}
{p 4 8 2}{cmd:. framed_bar grade industry occupation union hours tenure, stat(count) calc(`=_N' - @) allobs sort frame(0) horizontal barlabel(mlabc(black) mlabs(medlarge) mlabf(%1.0f)) xsc(off) subtitle(Missing values)}{p_end}

{p 4 4 2}Proportion of college graduates by race and union worker{p_end}
{p 4 8 2}{cmd:. framed_bar collgrad, over(union) by(race, row(1)) barlabel(mlabf(%04.3f)) ytitle(Proportion of college graduates) yla(0 "0" 1 "1" 0.2(0.2)0.8, format(%02.1f))}{p_end}


{title:Options} 

{p 4 8 2}
{cmd:over()} specifies a numeric or string variable {it:groupvar}.  A
separate bar will be shown for each distinct value of {it:groupvar}. It
is a required option with syntax 1 but not allowed otherwise.  Missing
values of {it:groupvar} are ignored. 


{it:Statistical options}

{p 4 8 2}
{opt stat:istic()} specifies any single statistical summary to be shown.
The default is to show means. Any statistic produced by {help collapse}
may be selected. 

{p 4 8 2}
{opt calc:ulator()} specifies a calculation to be applied on the fly
using an expression containing {cmd:@} to indicate the initial results.
{cmd:calc(100 * @)} for example specifies that percents rather than
proportions be shown if the application is to means of indicator 
variables. {cmd:calc(25.4 * @)} converts inches to mm.
{cmd:calc(1 - @)} would mean that 1 - {it:p} is to be shown rather than
{it:p}. This option has no effect on any axis title. 

{p 4 8 2}
{opt all:obs} applies if you wish to summarize occurrence of missing
values and/or to work with several variables that are being plotted
together. By default, calculations are only made with observations that
have non-missing values for all variables specified. This option
overrides that default selection: hence observations with missing values may be included
for one or more variables, while for several variables which
observations with non-missing values are used will be determined
separately for each variable. In other jargon, this option triggers
casewise deletion, not listwise deletion or complete case analysis. 
As a convenience for people familiar with that term, {cmd:cw} is a 
synonym for {cmd:allobs}. 

{p 4 8 2}
{cmd:sort} specifies that results are be shown in increasing order, so
increasing from left to right or from bottom to top across the graphic. 
If specified together with {opt desc:ending}, results will be shown 
decreasing from left to right or from bottom to top. If specified together 
with the {cmd:subset()} option, sorting will be based on order in the 
specified subset. See also {help myaxis} (Cox 2021),  


{it:Bar chart options}

{p 4 8 2}
{cmd:frame()} specifies the height of the frame. Note that
{cmd:frame(0)} or {cmd:frame(.)} wpuld suppress any (visible) frame. The
default is {cmd:frame(1)} and so geared to showing means of indicator
variables. 

{p 4 8 2}
{cmd:frameopts()} are options of {cmd:twoway bar} tuning the rendering
of frames. Defaults are {cmd:fcolor(none) pstyle(p2)} and as explained
below {cmd:barwidth(0.8)}. 

{p 4 8 2}
{cmd:base()} specifies the position of the base of bars and defaults to
0. It seems unlikely that you should prefer another value, but it may be
specified. 

{p 4 8 2}
{opt barw:idth()} specifies the width of bars and defaults to 0.8. 

{p 4 8 2}
{opt hori:zontal} specifies horizontal bars. The default is vertical
bars. 


{it:Annotation options}

{p 4 8 2}
As a general rule, these annotation options are not especially smart in
use of graph space. The displays shown may encroach on space used by
axes or their details.  You may wish to use {help axis scale options}
such as {cmd:xscale()} or {cmd:yscale()} to extend the space available.
See the Examples to get the idea. 

{p 4 8 2}
{cmd:barlabel()} tunes display of the bar labels that appear by default
at the top of vertical bars or at the right of horizontal bars showing
the numeric magnitudes concerned. 

{p 8 8 2}
As a special case, {cmd:barlabel(none)} suppresses this display. 

{p 8 8 2}
Otherwise, the defaults include {cmd:pstyle(p1)} and {cmd:mlabpos()} of
12 for vertical bars and 3 for horizontal bars. In particular, if you
are displaying integers, you may wish to specify {cmd:mlabformat(%1.0f)}. 
In general, see {help marker label options} for other possibilities. 

{p 4 8 2}
{opt count:label} or {opt count:label()} specifies that the number of observations
used be displayed at the bottom of vertical bars or at the left of
horizontal bars. This option may specify {help marker label options} or
other options affecting such display.  {cmd:pstyle(p1)} is a default for
this display. 

{p 8 8 2}
Exceptionally however, with syntax 2 and if you not specify the
{cmd:allobs} option, then the number of observations is necessarily a
constant and will be displayed using {cmd:note()}.  Options that apply
to {cmd:note()} may be used to tune the display. 


{it:twoway options}

{p 4 8 2}
{it:twoway_options} are other options of {help twoway}. Good examples
would be {cmd:by()}, {cmd:name()} or {cmd:saving()}. Note that ticks 
on the "categorical" axis (horizontal for vertical bars; vertical for 
horizontal bars) have been rendered invisible using the sub-option 
{cmd:tlc(none)}, See also Cox and Wiggins (2019) for more on tricks 
with ticks. 

{p 8 8 2}
Note that {cmd:by(, total)} and {cmd:by(, missing)} are not supported. 


{it:display options}

{p 4 8 2}
{cmd:list} requests a listing of main output. 

{p 4 8 2}
{cmd:format()} specifies a numeric display format for display of summary statistics. 


{title:Remarks}

{p 4 4 2}
Why is this offered as a new command? There are for me as author three 
main reasons.

{p 8 8 2}
{cmd:graph bar}, {cmd:graph hbar} and for that matter {cmd:graph dot}
offer charts showing summary statistics for groups and/or variables.
{cmd:twoway bar} allows frames to be drawn as empty bars on which other
bars can be superimposed. I often want to see both in combination. 

{p 8 8 2}
I often want annotation showing numbers of observations used. 

{p 8 8 2}
I often want to work around various small defaults with {cmd:graph bar}
and its kin, such as over-willing use of legends and axis ticks and 
neglect of variable labels. 

{p 4 4 2}
Users of this command should note that it is based on {cmd:twoway}, not 
{cmd:graph bar}, {cmd:graph hbar} or {cmd:graph dot}. 

{p 4 4 2}
On frames: 

{p 8 8 2}
See especially Cleveland and McGill (1984) or Cleveland (1985; examples
on pp.209, 222, 287) or Cleveland (1994; example on p.241) or Munzer
(2015, pp.112{c -}113) for direct explanation of the idea of framed rectangles.

{p 8 8 2}
See Dunn (1987, 1988), Monmonier (1993, pp.64{c -}65, 184{c -}185, 284)
and Kosslyn (1994, pp.248{c -}249, 290) or Kosslyn (2006, 
pp.235{c -}238) for cartographical applications.  

{p 8 8 2} 
See Wilkinson (1999, 2005), Wild and Seber (2000), Favillae (2008), Keen
(2010, 2018), or Wexler (2021, pp.186, 188{c -}189, 191) for examples
in terms of thermometer glyphs, plots or charts.  The main idea is much
older, although there is not a sharp division between showing a framed
rectangle and showing a stacked or divided bar chart with (usually) two
complementary fractions.  Brinton (1939, pp.51, 103, 200) gave various
examples; his earliest source is Emeny (1934, pp.17, 169).  Karsten
(1923, p.122) and Mudgett (1930, p.81) gave other clear examples.  For
fairly literal examples of the thermometer idea, see Haskell (1919,
p.106), Haskell (1922, p.215) and Karsten (1923, p.130).  The same idea
is standard to those accustomed to thinking in terms of mosaic plots or
their variants under any other name, in which each axis shows a
probability scale: see e.g. Unwin et al. (2006) or Unwin (2015).

{p 8 8 2}Frames are supported in {help tabplot} (Cox 2016, but in 
the 2020 update). 

{p 4 4 2}
For alternative displays of sets of indicator variables, see 
commands discussed by Cox and Morris (2024). 


{title:Examples}

{p 4 4 2}As indicated, these examples were developed using the {cmd:stcolor} 
scheme. If you need or prefer to use another scheme, then some commands
may need tweaking. In particular, you may need to extend axes to 
accommodate added text comfortably. 

{p 4 8 2}{cmd:. set scheme stcolor}{p_end}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}

{p 4 8 2}First, compare stacked bars for a binary outcome:{p_end}

{p 4 8 2}{cmd:. graph hbar, over(foreign) over(rep78) asyvars stack percent ytitle(percent) l1title(Repair record 1978) name(GH, replace)}{p_end}

{p 4 8 2}{cmd:. * ssc inst catplot}{p_end}
{p 4 8 2}{cmd:. catplot, over(foreign) over(rep78) percent(rep78) asyvars stack l1title(Repair record) name(CAT, replace)}{p_end}

{p 4 8 2}Now turn to {cmd:framed_bar}: 

{p 4 8 2}{cmd:. framed_bar foreign, over(rep78) calc(100*@) frame(100) barlabel(mlabf(%2.0f)) yla(none) ytitle(% foreign) name(FB1, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar foreign, over(rep78) calc(100*@) frame(0) barlabel(mlabf(%2.0f) mlabs(medlarge)) yla(none) ytitle(% foreign) name(FB2, replace)}{p_end}

{p 4 8 2}{cmd:. sysuse nlsw88, clear}{p_end}

{p 4 8 2}{cmd:. local yla yla(0 "0" 1 "1" 0.2(0.2)0.8, format(%02.1f))}{p_end}
{p 4 8 2}{cmd:. local xla xla(0 "0" 1 "1" 0.2(0.2)0.8, format(%02.1f))}{p_end}

{p 4 8 2}{cmd:. framed_bar collgrad, over(race) barlabel(mlabf(%04.3f) mlabs(large)) `yla' ytitle(Proportion of college graduates) name(FB3, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar collgrad, over(race) barlabel(mlabf(%04.3f) mlabs(large)) count(mlabs(medlarge)) `yla' ytitle(Proportion of college graduates) name(FB4, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar collgrad, over(race) barlabel(mlabf(%04.3f) mlabs(large)) count(mlabs(medlarge)) horizontal `xla' xsc(r(-0.16 .)) xtitle(Proportion of college graduates) ysc(reverse) name(FB5, replace)}{p_end}

{p 4 8 2}{cmd:. local yla yla(0(20)100)}{p_end}
{p 4 8 2}{cmd:. local xla xla(0(20)100)}{p_end}
{p 4 8 2}{cmd:. local blab mlabs(large) mlabf(%2.1f)}{p_end}

{p 4 8 2}{cmd:. framed_bar never married collgrad smsa, calc(100*@) frame(100) barlabel(`blab') count(size(medlarge)) `yla' ytitle(Percent) name(FB6, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar union married collgrad smsa, calc(100*@) frame(100) horizontal barlabel(`blab') count(size(medlarge)) `xla' xtitle(Percent) name(FB7, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar union married collgrad smsa, calc(100*@) allobs frame(100) barlabel(`blab') count(mlabs(medlarge)) horizontal xsc(r(-20 .)) `xla' xtitle(Percent) name(FB8, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar union married collgrad smsa, calc(100*@) allobs sort frame(100) barlabel(`blab') count(mlabs(medlarge)) `yla' ytitle(Percent) name(FB9, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar grade industry occupation union hours tenure, stat(count) calc(`=_N' - @) allobs sort frame(0) horizontal barlabel(mlabc(black) mlabs(medlarge) mlabf(%1.0f)) xsc(off) subtitle(Missing values) name(FB10, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar collgrad, over(union) by(race, row(1)) barlabel(mlabf(%04.3f)) ytitle(Proportion of college graduates) yla(0 "0" 1 "1" 0.2(0.2)0.8, format(%02.1f)) name(FB11, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar collgrad, over(union) by(race, row(1)) horizontal barlabel(mlabf(%04.3f)) ytitle(Proportion of college graduates) xla(0 "0" 1 "1" 0.2(0.2)0.8, format(%02.1f)) name(FB12, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar collgrad union, by(race, row(1)) barlabel(mlabf(%04.3f)) name(FB13, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar collgrad union, by(race, row(1)) horizontal barlabel(mlabf(%04.3f)) name(FB14, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar collgrad union smsa married, by(race, row(1)) frame(0) horizontal barlabel(mlabf(%04.3f)) recast(dropline) name(FB15, replace)}{p_end}

{p 4 8 2}{cmd:. framed_bar collgrad union smsa married, by(race, row(1)) sort subset(race==2) frame(0) horizontal barlabel(mlabf(%04.3f)) recast(dropline) xla(none) name(FB16, replace)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:Acknowledgments}

{p 4 4 2}Although frames as a graphic device are at least a century old, my understanding owes most to the work of 
William S. Cleveland. Encouragement to use frames in {cmd:tabplot} arose from comments from William Huber and 
Jeff Laux. The initial stimulus for this command was in a Statalist thread by Jonathan Afilalo. Encouraging comments came from Tim Morris.  


{title:References} 

{p 4 8 2}Brinton, W.C. 1939.
{it:Graphic Presentation.}
New York: Brinton Associates.

{p 4 8 2}Cleveland, W.S. 1985. 
{it:The Elements of Graphing Data.} 
Monterey, CA: Wadsworth.
 
{p 4 8 2}Cleveland, W.S. 1994. 
{it:The Elements of Graphing Data.} 
Summit, NJ: Hobart Press. 

{p 4 8 2}Cleveland, W.S. and R. McGill. 1984. 
Graphical perception: theory, experimentation, and application to the 
development of graphical methods. 
{it:Journal of the American Statistical Association} 
79: 531{c -}554.

{p 4 8 2}Cox, N.J. 2016. 
Speaking Stata: Multiple bar charts in table form. 
{it:Stata Journal} 16: 491{c -}510. 
Updates 17: 779; 20: 757{c -}758; 22: 467. 

{p 4 8 2}Cox, N.J. 2021. 
Speaking Stata: Ordering or ranking groups of observations. 
{it:Stata Journal} 21: 818{c -}837.

{p 4 8 2}Cox, N.J. and T.P. Morris. 2024. 
Speaking Stata: The joy of sets: Graphical alternatives to Euler and Venn diagrams.
{it:Stata Journal} 24: 329{c -}361. 

{p 4 8 2}Cox, N.J. and V. Wiggins. 2019. 
Stata tip 132: Tiny tricks and tips on ticks. 
{it:Stata Journal} 19: 741{c -}747.

{p 4 8 2}Dunn, R. 1987. 
Variable-width framed rectangle charts for statistical mapping. 
{it:American Statistician} 41: 153{c -}156.

{p 4 8 2}Dunn, R. 1988. 
Framed rectangle charts or statistical maps with shading: An experiment in graphical perception. 
{it:American Statistician} 42: 123{c -}129.

{p 4 8 2}Emeny, B. 1934.
{it:The Strategy of Raw Materials: A Study of America in Peace and War.}
New York: Macmillan.

{p 4 8 2}Favillae. 2008. 
Thermometer plots in R. 
{browse "https://favillae.blogspot.com/2008/11/thermometer-plots-in-r.html":https://favillae.blogspot.com/2008/11/thermometer-plots-in-r.html}

{p 4 8 2}Haskell, A.C. 1919. 
{it:How to Make and Use Graphic Charts.} 
New York: Codex Book Company. 

{p 4 8 2}Haskell, A.C. 1922.  
{it:Graphic Charts in Business: How to Make and Use Them.}
New York: Codex Book Company. 

{p 4 8 2}Karsten, K.G. 1923. 
{it:Charts and Graphs: An Introduction to Graphic Methods in the Control and Analysis of Statistics.} 
New York: Prentice-Hall. 

{p 4 8 2}Keen, K. J. 2010 (second edition 2018). 
{it:Graphics for Statistics and Data Analysis with  R.} 
Boca Raton, FL: CRC Press. 

{p 4 8 2}Kosslyn, S.M. 1994.
{it:Elements of Graph Design.} 
New York: W.H. Freeman. 
 
{p 4 8 2}Kosslyn, S.M. 2006. 
{it:Graph Design for the Eye and Mind.} 
New York: Oxford University Press. 

{p 4 8 2}Monmonier, M. 1993. 
{it:Mapping It Out: Expository Cartography for the Humanities and Social Sciences.} 
Chicago: University of Chicago Press. 

{p 4 8 2}Mudgett, B.D. 1930. 
{it:Statistical Tables and Graphs.} 
Boston, MA: Houghton Mifflin. 

{p 4 8 2}Munzner, T. 2015. 
{it:Visualization Analysis and Design.} 
Boca Raton, FL: CRC Press..

{p 4 8 2}
Unwin, A. 2015.
{it:Graphical Data Analysis with R.}
Boca Raton, FL: Taylor & Francis.

{p 4 8 2}
Unwin, A., M. Theus, and H. Hofmann. 2006.
{it:Graphics of Large Datasets: Visualizing a Million.}
New York: Springer.

{p 4 8 2}Wexler, S. 2021. 
{it:The Big Picture: How to Use Data Visualizations to Make Better Decisions{c -}Faster.} New York: McGraw Hill. 

{p 4 8 2}Wild, C.J. and G.A.F. Seber. 2000. 
{it:Chance Encounters: A First Course in Data Analysis and Inference.}
New York: John Wiley. 

{p 4 8 2}
Wilkinson, L. 1999.
{it:The Grammar of Graphics.}           
New York: Springer.

{p 4 8 2}
Wilkinson, L. 2005.
{it:The Grammar of Graphics.} 2nd ed.
New York: Springer.


{title:Also see}

{p 4 4 2}{help twoway bar}

{p 4 4 2}{help myaxis} ({it:Stata Journal}) (if installed) 

{p 4 4 2}{help tabplot}  ({it:Stata Journal}) (if installed)

{p 4 4 2}{help upsetplot}, {help vennbar} ({it:Stata Journal}) (if installed)


