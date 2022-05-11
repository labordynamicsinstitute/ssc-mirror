{smcl}
{* 10may2022}{...}
{cmd:nicelabels}{right:({browse "http://www.stata-journal.com/article.html?article=gr00??":SJ22-?: gr00??)}}
{hline}

{title:Title}

{p2colset 5 19 22 2}{...}
{p2col :{cmd:nicelabels} {hline 2}}Nice axis labels for general scales{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:nicelabels}
{it:varname}
{ifin}{cmd:,}
{cmdab:l:ocal(}{it:macname}{cmd:)}
[
{cmd:tight} 
{opt nvals(#)} 
]

{p 4 17 2}
{cmd:nicelabels}
{it:#}1 {it:#}2{cmd:,}
{cmdab:l:ocal(}{it:macname}{cmd:)}
[
{cmd:tight} 
{opt nvals(#)} 
]


{title:Description}

{p 4 4 2}
{cmd:nicelabels} suggests axis labels that would look nice on a graph
using a general scale.  It can help when, for example, you want to
choose the same labels for a series of graphs. Results are put in a
local macro for later use.

{p 4 4 2}
"Nice" is a little hard to define but easier to recognize. This command
follows common practice in general and Heckbert (1990) in particular in
selecting power-of-ten multiples of 1, 2 or 5 that are equally spaced.   

{p 4 4 2}
See Hardin (1995) for an earlier implementation in Stata of such ideas.
Hardin (1995) implements what Heckbert calls a "loose" definition of
labels, while this command allows also a "tight" definition.  

{p 4 4 2}
There are two syntaxes.  In the first, the name of a numeric variable
must be given.  In the second, two numeric values are given, which will
be interpreted as indicating minimum and maximum of an axis range.
Those two values can be given in any order.


{title:Options}

{p 4 8 2}
{cmd:local(}{it:macname}{cmd:)} inserts the specification of labels in
local macro {it:macname} within the calling program's space.  Hence,
that macro will be accessible after {cmd:nicelabels} has finished.  This
is helpful for later use with {helpb graph twoway} or other graphics
commands.  {cmd:local()} is required.

{p 8 8 2}
Anyone new to the idea and use of local macros should study the examples
carefully.  {cmd:nicelabels} creates a local macro, which is a kind of
bag holding the text to be inserted in a {cmd:graph} command.  The local
macro is referred to in that graph command using the punctuation 
{cmd:` '} around the macro name.  Note that the opening (left) single
quote and the closing (right) single quote are different.  Other single
quotation marks will not work.  Do not be troubled by the closing single
quote ({cmd:'}) appearing as upright in many fonts.

{p 4 8 2}
{cmd:tight} tends to pull in as compared with the default and so not
suggest labels beyond the minimum or maximum. This option may often be
combined with the {cmd:nvals()} option (see below). 

{p 4 8 2} 
{cmd:nvals()} suggests a number of values to be labelled. The default is
5. Most commonly, you may wish to suggest more values, say
{cmd:nvals(10)}. As said, this is a suggestion, not an instruction.  
Note the suggestion by Cleveland (1985, 39; 1994, 39) of 3-10 labels on any
axis. 


{title:Remarks}

{p 4 4 2}
Likely uses of this command are in deciding in advance on a set of
labels to be used in a series of graphs, either directly or on a
transformed scale. For example, labels may be determined from a summary
of all data and then used consistently for various graphs of subsets of
the data.

{p 4 4 2}
The aim is not to repeat, still less to replace, what is already easy in
Stata. Thus if quantiles are being shown, it may be that labels 0.5,
0.25, 0.75, 0.125, 0.375, 0.625, 0.875, ... appeal for a probability
scale as corresponding to median, quartiles, octiles, and so forth.
These labels are easily produced either by spelling them out or by using
step sizes such as 0.25 or 0.125. The same issue arises with a percent
scale from 0 to 100 whenever labels like 25, 50, 75 seem desirable. 

{p 4 4 2}
The examples include extensions of the basic idea, as explained now.

{p 8 8 2}
Suppose you have a variable that is always positive but you prefer that
a graph axis starts at zero. Then use {helpb summarize} to find the
maximum and feed that and 0 to the command. Note that using the maximum
from {cmd:summarize} with options such as {cmd:yla(0(10)`max')} or
{cmd:yla(0(20)`max')} or {cmd:ysc(0 `max') yla(#6)} may be as or more
effective. Here {cmd:local max = r(max)} should be assigned just after
{cmd:summarize}. 

{p 8 8 2}
Suppose you want to insist that the minimum and maximum of a variable 
be shown as labels. Compare Tufte's illustration (Tufte 1983: 149;
Tufte 2001: 149). Then again the results of {cmd:summarize} can be used
with results from this command with the {cmd:tight} option. 

{p 8 8 2}
Suppose you want to insist on at least so many labels. Then count the
labels suggested and re-run the command using the {cmd:nvals()} option. 

{p 8 8 2}
Suppose you want to show "%" explicitly by each label.  Precedents
include Robbins (2013, 188, 250, 278, 318), Knaflic (2015, 1, 48f,
51, 59, 81f, 156, 209f, 228ff, 238f), Koponen and Hild{c e'}n (2019,
22, 64, 77, 84. 94, 101, 107, 185, 190, 193ff, 206, 209, 214ff),
Wilke (2019, 29, 34, 69, 101f, 104, 107, 139ff, 179, 184f, 234ff,
258f, 261), Tufte (2020, 107), and Gelman, Hill and Vehtari (2021,
4, 29f, 94, 96, 114, 126f, 166, 292, 467f).  {cmd:mylabels} will let
you do this. So, use {cmd:nicelabels} to get the labels and then
{cmd:mylabels} to add a "%" suffix. The same point arises with any other
prefix or suffix such as a currency symbol.

{p 4 4 2}
The references include some other papers of the author on axis labels and
ticks.

{p 4 4 2} 
This implementation focuses on the ideas covered by Heckbert (1990).
There is a wider literature both before and after that date. Wilkinson
(1999, 217{c -}218; 2005, 95{c -}97) and Talbot, Lin and Hanrahan (2010)
have spelled out how fully automated choice entails a delicate tradeoff
between several desiderata, chiefly simplicity, coverage, granularity,
and legibility. Talbot, Lin and Hanrahan (2010) give a full survey of
the problem. 


{title:Examples}

{p 4 8 2}{cmd:. set scheme s1color}{p_end}

{p 4 8 2}{cmd:. nicelabels 142 233, local(foo)}{p_end}
{p 4 8 2}(shows 140 160 180 200 220 240){p_end}
{p 4 8 2}{cmd:. nicelabels 142 233, local(foo) tight}{p_end}
{p 4 8 2}(shows 160 180 200 220){p_end}
{p 4 8 2}{cmd:. nicelabels 142 233, local(foo) nvals(10)}{p_end}
{p 4 8 2}(shows 140 150 160 170 180 190 200 210 220 230 240){p_end}
{p 4 8 2}{cmd:. nicelabels 142 233, local(foo) tight}{p_end}
{p 4 8 2}(shows 150 160 170 180 190 200 210 220 230){p_end}

{p 4 8 2}{cmd:. sysuse census, clear}{p_end}
{p 4 8 2}{cmd:. summarize medage}{p_end}
{p 4 8 2}(shows minimum 24.2, maximum 34.7){p_end}
{p 4 8 2}{cmd:. nicelabels medage, local(agela)}{p_end}
{p 4 8 2}(shows 20 25 30 35){p_end}
{p 4 8 2}{cmd:. nicelabels medage, local(agela) tight}{p_end}
{p 4 8 2}(shows 25 30){p_end}
{p 4 8 2}{cmd:. nicelabels medage, local(agela) nvals(10)}{p_end}
{p 4 8 2}(shows 24 26 28 30 32 34 36){p_end}
{p 4 8 2}{cmd:. nicelabels medage, local(agela) tight nvals(10)}{p_end}
{p 4 8 2}(shows 26 28 30 32 34){p_end}

{p 4 8 2}{cmd:. gen pc_older = 100 * pop65p / pop}{p_end}
{p 4 8 2}{cmd:. nicelabels pc_older, local(yla)}{p_end}
{p 4 8 2}{cmd:. mylabels `yla', suffix(%) local(yla)}{p_end}
{p 4 8 2}{cmd:. scatter pc_older medage, yla(`yla', ang(h)) xla(, format(%2.0f)) ytitle(% 65 and older) ms(none) mlabel(state2) mlabpos(0)}{p_end}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. summarize mpg, meanonly}{p_end}
{p 4 8 2}{cmd:. nicelabels 0 `r(max)', local(foo)}{p_end}
{p 4 8 2}(shows 0 10 20 30 40 50){p_end}

{p 4 8 2}{cmd:. nicelabels mpg, tight local(yla)}{p_end}
{p 4 8 2}{cmd:. summarize mpg, meanonly}{p_end}
{p 4 8 2}{cmd:. local yla `yla' `r(min)' `r(max)'}{p_end}
{p 4 8 2}{cmd:. nicelabels weight, tight local(xla)}{p_end}
{p 4 8 2}{cmd:. summarize weight, meanonly}{p_end}
{p 4 8 2}{cmd:. local xla `xla' `r(min)' `r(max)'}{p_end}
{p 4 8 2}{cmd:. scatter mpg weight, xla(`xla') yla(`yla', ang(h)) ms(Oh)}{p_end}

{p 4 8 2}{cmd:. nicelabels mpg, tight local(yla)}{p_end}
{p 4 8 2}(shows 20 30 40){p_end}
{p 4 8 2}{cmd:. if wordcount("`yla'") < 5 nicelabels mpg, tight local(yla) nvals(10)}{p_end}
{p 4 8 2}(shows 15 20 25 30 35 40){p_end}


{title:Author}

{pstd}
Nicholas J. Cox{break}
Department of Geography{break}
Durham University{break}
Durham, UK{break}
n.j.cox@durham.ac.uk


{title:References} 

{phang}
Cleveland, W.S. 1985.  
{it:The Elements of Graphing Data}. 
Monterey, CA: Wadsworth.

{phang}
Cleveland, W.S. 1994. 
{it:The Elements of Graphing Data}. Rev. ed.
Summit, NJ: Hobart.

{p 4 8 2}Cox, N.J. 2005. 
Stata tip 24: Axis labels on two or more levels. 
{it:Stata Journal} 5: 469.
 
{p 4 8 2}Cox, N.J. 2007. 
Stata tip 55: Better axis labeling for time points and time intervals. 
{it:Stata Journal} 7: 590{c -}592. 

{p 4 8 2}Cox, N.J. 2008. 
Stata tip 59: Plotting on any transformed scale. 
{it:Stata Journal} 8: 142{c -}145. 

{p 4 8 2}Cox, N.J. 2012. 
Speaking Stata: Transforming the time axis. 
{it:Stata Journal} 12: 332{c -}341. 

{p 4 8 2}Cox, N.J. 2018. 
Speaking Stata: Logarithmic binning and labeling. 
{it:Stata Journal} 18: 262{c -}286. (Update: 2020. 20: 1028)

{p 4 8 2}Cox, N.J. 2021. 
Stata tip 141: Adding marginal spike histograms to
quantile and cumulative distribution plots. 
{it:Stata Journal} 21: 838{c -}846. 

{p 4 8 2}Cox, N.J. and V. Wiggins. 2019. 
Stata tip 132: Tiny tricks and tips on ticks. 
{it:Stata Journal} 19: 741{c -}747. 

{p 4 8 2}
Gelman, A., J. Hill and A. Vehtari. 2021. 
{it:Regression and Other Stories.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}
Hardin, J.W. 1995. 
dm28: Calculate nice numbers for labeling or drawing grid lines.
{it:Stata Technical Bulletin} 25: 2{c -}3.  
(STB Reprints Vol 5, pp.19{c -}20)
{browse "https://www.stata.com/products/stb/journals/stb25.pdf":https://www.stata.com/products/stb/journals/stb25.pdf}

{p 4 8 2}
Heckbert, P.S. 1990. Nice numbers for graph labels. 
In A.S. Glassner (Ed.) {it:Graphics Gems}. 
San Diego, CA: Academic Press, 
61{c -}63 and 657{c -}659.

{p 4 8 2}
Knaflic, C.N. 2015. 
{it:Storytelling with Data: A Data VIsualization Guide for Business Professionals.}  
Hoboken, NJ: John Wiley. 

{p 4 8 2}
Koponen, J. and J. Hild{c e'}n, J. 2019. 
{it:The Data Visualization Handbook.} 
Espoo: Aalto ARTS Books.

{p 4 8 2}
Robbins, N.B. 2013.  
{it:Creating More Effective Graphs.}
Wayne, NJ: Chart House. 

{p 4 8 2}
Talbot, J., S. Lin, and P. Hanrahan. 2010.
An extension of Wilkinson's algorithm for positioning tick labels on axes. 
{it:IEEE Transactions on Visualization and Computer Graphics} 16: 1036{c -}1043.

{p 4 8 2}Tufte, E.R. 1983. 
{it:The Visual Display of Quantitative Information.} 
Cheshire, CT: Graphics Press. (2nd edition 2001) 

{p 4 8 2}
Tufte, E.R. 2020. 
{it:Seeing with Fresh Eyes: Meaning, Space, Data, Truth.}
Cheshire, CT: Graphics Press.

{p 4 8 2}
Wilke, C.O. 2019. 
{it:Fundamentals of Data Visualization: A Primer on Making Informative and Compelling Figures.} 
Sebastopol, CA: O'Reilly. 

{p 4 8 2} 
Wilkinson, L. 1999. 
{it:The Grammar of Graphics.} 
New York: Springer.

{p 4 8 2}
Wilkinson, L. 2005. 
{it:The Grammar of Graphics.} 
New York: Springer.


{title:Also see}

{p 4 14 2}
help: {manhelpi axis_label_options G-3}{p_end}

{p 4 14 2} 
help: {help niceloglabels} (if installed)

{p 4 14 2} 
help: {help mylabels} (if installed)

