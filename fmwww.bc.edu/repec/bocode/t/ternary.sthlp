{smcl}
{* 28Aug2024}{...}
{hi:help ternary}{...}
{right:{browse "https://github.com/asjadnaqvi/stata-ternary":ternary v1.0 beta (GitHub)}}

{hline}

{title:ternary}: A Stata package for plotting three variables in a triangle. 

{p 4 4 2}
The command is currently {it:beta} and is actively being updated. 
Layers are auto detected to either add up to 1 (fractions) or a 100 (percentages). If neither of the conditions is true, then please normalize the data points before running the command.
Nick Cox's {stata help triplot:triplot} (Cox 2009) provided inspiration for this package.

{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:ternary} {it:varL varR varB} {ifin}, 
                {cmd:[} {cmd:cuts}({it:num}) {cmd:zoom} {cmd:fill} {cmd:points} {cmd:lines} {cmd:labels} {cmd:colorL}({it:str}) {cmd:colorR}({it:str}) {cmd:colorB}({it:str})
                  {cmdab:lw:idth}({it:str}) {cmdab:msym:bol}({it:str}) {cmd:msize}({it:str}) {cmdab:mc:olor}({it:str}) {cmdab:mlc:olor}({it:str}) {cmdab:mlw:idth}({it:str}) {cmdab:labc:olor}({it:str}) {cmdab:ticks:ize}({it:str}) *                                  
                {cmd:]}

{p 4 4 2}
The options are described as follows:

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}

{p2coldent : {opt ternary varL varR varB}}The order of the variables is {it:Left}, {it:Right} and {it:Bottom}.{p_end}

{p2coldent : {opt cuts(num)}}Total number of evenly-spaced segments in the triangle. Default is {opt cuts(5)}.{p_end}

{p2coldent : {opt zoom(num)}}Zoom into the data based on the data extent of the bottom layer. This option will be enhanced further in later releases. Use this option if 
the data points are bunched in very few triangles. Rather than increasing the cuts to show more variation, {opt zoom} rescales the axes while keeping the cuts the same.{p_end}


{p 4 4 2}{it:{ul:Colors}}

{p2coldent : {opt fill}}Add graduated colors to the triangles. See below for color options.{p_end}

{p2coldent : {opt points}}Add graduated colors to the points defined by the triangle they are in. Note that while both {opt fill} and {opt points} can be simultanously used,
but it will create a hollow marker illusion where only marker outlines are visible. So avoid this. Broadly, just using {opt points} renders faster since not all triangles contain points.
Point markers and outcomes can also be customized. See below.{p_end}

{p2coldent : {opt lines}}Add line colors in the triangle.{p_end}

{p2coldent : {opt labels}}Add colors to axes labels and ticks.{p_end}

{p2coldent : {opt colorL(str)}, {opt colorR(str)}, {opt colorB(str)}}User either a named color recognized by {stata help colorpalette:colorpalette} or use a {it:hex} code.
Defaults are {opt colorL(#00E0DF)}, {opt colorR(#FF6CFF)}, and {opt colorB(#DCB600)}. These colors represent the maximum values for each axes.
The convex combinations of all the in-between colors are auto generated. Please note that the number of triangles = {it:cuts^2}, hence the program slows down exponentially.
as {it:O(n)=n^2}. So avoid going over 10 cuts which in any case renders the information meaningless as colors become indistinguishable. Here lower numbers are better.{p_end}


{p 4 4 2}{it:{ul:Markers and lines}}

{p2coldent : {opt lw:idth(str)}}Line width. Default is {opt lwidth(0.15)}.{p_end}

{p2coldent : {opt lc:olor(str)}}Line color. Default is {opt lcolor(gs8)}. If {opt fill} is used then it defaults to {lcolor(white)}.{p_end}

{p2coldent : {opt labc:olor(str)}}Label color. Default is {opt lcolor(black)}. Also affects tick colors.{p_end}

{p2coldent : {opt ticks:ize(str)}}Axes tick size. Default is {opt ticks(1)}.{p_end}

{p2coldent : {opt msym:bol(str)}}Marker symbol. Default is {opt msym(circle)}.{p_end}

{p2coldent : {opt msize(str)}}Marker size. Default is {opt msize(1.5)}.{p_end}

{p2coldent : {opt malpha(str)}}Marker fill intensity if the options {opt points} is used. Default is {opt malpha(90)} or 90% fill. For simple points use for example {opt mcolor(%50)}.{p_end}

{p2coldent : {opt mc:olor(str)}}Marker color if the option {opt points} is not specified. Default is {opt mcolor(black)}.{p_end}

{p2coldent : {opt mlc:olor(str)}}Marker outline color. Default is {opt mlcolor(white)}.{p_end}

{p2coldent : {opt mlw:idth(str)}}Marker outline width. Default is {opt mlwidth(0.1)}.{p_end}

{p2coldent : {opt *}}All other twoway options not elsewhere specified.{p_end}

{synoptline}
{p2colreset}{...}

{title:Dependencies}

The following packages are required for {cmd:ternary}:

{stata ssc install palettes, replace}
{stata ssc install colrspace, replace}
{stata ssc install moremata, replace}

Even if you have these installed, it is highly recommended to check for updates: {stata ado update, update}

{title:Examples}

See {browse "https://github.com/asjadnaqvi/stata-ternary":GitHub}.

{hline}


{title:Package details}

Version      : {bf:ternary} v1.0 beta
This release : 28 Aug 2024
First release: 28 Aug 2024
Repository   : {browse "https://github.com/asjadnaqvi/stata-ternary":GitHub}
Keywords     : Stata, graph, ternary, triplot
License      : {browse "https://opensource.org/licenses/MIT":MIT}

Author       : {browse "https://github.com/asjadnaqvi":Asjad Naqvi}
E-mail       : asjadnaqvi@gmail.com
Twitter/X    : {browse "https://x.com/AsjadNaqvi":@AsjadNaqvi}


{title:Feedback}

Please submit bugs, errors, feature requests on {browse "https://github.com/asjadnaqvi/stata-ternary/issues":GitHub} by opening a new issue.


{title:Citation guidelines}

Suggested citation guidlines for this package:

Naqvi, A. (2024). Stata package "ternary" version 1.0. Release date 28 August 2024. https://github.com/asjadnaqvi/stata-ternary.

@software{ternary,
   author = {Naqvi, Asjad},
   title = {Stata package ``ternary''},
   url = {https://github.com/asjadnaqvi/stata-ternary},
   version = {1.0},
   date = {2024-08-28}
}


{title:References}

{p 4 8 2}Cox, N. (2009). {browse "https://ideas.repec.org/c/boc/bocode/s342401.html":Triplot: Stata module to generate triangular plots}.

{p 4 8 2}Jann, B. (2018). {browse "https://www.stata-journal.com/article.html?article=gr0075":Color palettes for Stata graphics}. The Stata Journal 18(4): 765-785.

{p 4 8 2}Jann, B. (2022). {browse "https://ideas.repec.org/p/bss/wpaper/43.html":Color palettes for Stata graphics: An update}. University of Bern Social Sciences Working Papers No. 43. 


{title:Other visualization packages}

{psee}
    {helpb arcplot}, {helpb alluvial}, {helpb bimap}, {helpb bumparea}, {helpb bumpline}, {helpb circlebar}, {helpb circlepack}, {helpb clipgeo}, {helpb delaunay}, {helpb joyplot}, 
	{helpb marimekko}, {helpb polarspike}, {helpb sankey}, {helpb schemepack}, {helpb spider}, {helpb splinefit}, {helpb streamplot}, {helpb sunburst}, {helpb ternary}, {helpb treecluster}, {helpb treemap}, {helpb trimap}, {helpb waffle}
