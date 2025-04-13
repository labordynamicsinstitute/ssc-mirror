{smcl}
{* First Version June 26 2023}{...}
{* This Version February 07 2025}{...}
{viewerdialog lpgraph "dialog lpgraph"}{...}
{vieweralsosee "locproj" "help locproj"}{...}
{vieweralsosee "[R] graph combine" "help graph combine"}{...}
{vieweralsosee "[R] lincom" "help lincom"}{...}
{vieweralsosee "[R] margins" "help margins"}{...}
{hline}
Help for {hi:lpgraph}
{hline}

{title:Description}

{p}{cmd:lpgraph} plots together the results of previously estimated IRFs of more than one model into one graph. The graph can include up to 4 IRFs. 
It can also generate 4 separate IRF graphs and combine them in one in the same fashion as the command {cmd:grah combine}.{p_end}
 
{p}The first option is convenient when we want to have a graph in which we compare the magnitude of the different IRFs, since they share
the same axis.{p_end}

{p}The second option is more convenient when you want to create separate IRF graphs of previously estimated and saved results, and then combine them into a single graph.{p_end}

{p}{cmd:lpgraph} is a post-estimation command, and it uses the IRFs results saved as variables by the command {cmd:locproj}, which saves the IRF, 
its standard error and its confidence bands using the name defined by the user through the options {opt saveirf} and {opt irfname()}.
{p_end} 
{p}The command {cmd:lpgraph} can also be used to combine IRF results from other estimation methods, such as VAR, SVAR, arima, etc., as long as the results 
of those commands are saved with the same name structure in which {cmd:locproj} saves the IRFs results.{p_end}



{marker syntax}{...}
{title:Syntax}
{p 8 13 2}
{cmd:lpgraph} {it:irfname1} {it:irfname2} {it:irfname3} {it:irfname4}
{cmd:,}
[ {opt h:or(numlist integer)} {opt z:ero}  {opt tit:le(string)} {opt tti:tle(string)} {opt yti:tle(string)}} {opt sep:arate} 
{opt ti1(string)} {opt ti2(string)} {opt ti3(string)} {opt ti4(string)}
{opt lab1(string)} {opt lab2(string)} {opt lab3(string)} {opt lab4(string)} 
{opt lc1(string)} {opt lc2(string)} {opt lc3(string)} {opt lc4(string)}  
{opt nolegend}
{opt grn:ame(string)} {opt grs:ave(string)} 
{opt as(string)} {it: other_options}]{p_end}
	

{synoptset 33 tabbed}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}


{synopt:{opt h:or(numlist/integer)}}Specifies the number of steps or horizon length for the IRF. The initial horizon could be negative.
It can be specified either as a range (e.g. {it:hor(0/6)} or {it:hor(-3/6)}), or just as the final horizon period (e.g. {it:hor(6)}) 
in which case the command assumes the horizon starts at period 0 and ends in period 6. The default horizon range is {it:hor = 0,...,5} 
if nothing is specified.{p_end}

{synopt:{opt sep:arate}}If this option is specified, each IRF is plotted in a separate graph, and then all of them are combined in a new one, 
in the same fashion as if we were combining them by using the command {cmd: graph combine}. The only difference of using the option {opt sep:arate}
and the command {cmd: graph combine} is that {cmd: lpgraph} will first generate new graphs for each IRF. {p_end}

{synopt:{opt z:ero}}If this option is specified the graph(s) includes a dashed line for the value 0.{p_end}

{synopt:{opt lab#(string)}}Specifies a label for each one of the IRFs, e.g. lab1(Label A), lab2(Label B), lab3(Label C) lab4(Label D).{p_end}

{synopt:{opt ti:tle(string)}}Specifies a title for the final graph.{p_end}

{synopt:{opt ti#(string)}}Specifies a title for each one of the 4 separated graphs, e.g. ti1(Title A), ti2(Title B), ti3(Title C) ti4(Title D).
These options should be used when using the option {opt sep:arate}.{p_end}

{synopt:{opt lcol:or(string)}}Specifies a unique color for the IRF line and the confidence bands of each one of the IRFs.{p_end}

{synopt:{opt lc#(string)}}Specifies a color for the IRF line and confidence bands of each one of the 4 IRFs, 
e.g. lc1(gray), lc2(green), lc3(blue), lc4(red). These options should be used when using the option {opt sep:arate}.{p_end}

{synopt:{opt nolegend}}Specifies that legends should not be shown. It could be useful if you have separated graphs and each one of 
them has a title.{p_end}

{synopt:{opt tti:tle(string)}}Specifies a name for the time axis in the IRF graph.{p_end}

{synopt:{opt grn:ame(string)}}Specifies a graph name that could be used, for instance, when combining various graphs.{p_end}

{synopt:{opt grs:ave(string)}}Specifies a file name and path that should be used to save the IRF graph on the disk.{p_end}

{synopt:{opt as(string)}}Specifies the desired file format of the saved graph.{p_end}

{synopt:{it:other_options}}Specifies any other graph options not defined elsewhere. The user just need to enter any other graph option not included
in the list before alongside the rest of {cmd:lpgraph} options.{p_end}

{synopt:{opt combine(string)}}Specifies any other options specific to the {cmd:grah combine} command not defined elsewhere. The user just need to enter any other graph combine option not included before inside the option parenthesis.{p_end}

{synoptline}


{marker Examples}{...}


{title:Example 1. Creating one graph with various IRFs}

{p 4 8 2}{cmd:. use AED_INTERESTRATES.dta}{p_end}

{p}First, we are going to estimate 3 different IRFs, the first one is a model in levels, the second one uses cumulative changes and the third one
includes a cuadratic term in the shock. We do not generate graphs ({opt nograph}) and we save the IRFs giving each one a different name 
(e.g. {it: level, cmlt, cuad}):{p_end}

{p 4 8 2}{cmd:. locproj gs10 l(0/4).gs1, h(12) m(newey) hopt(lag) yl(3) nograph save irfn(level)}{p_end}
{p 4 8 2}{cmd:. locproj gs10 l(0/4).gs1, h(12) m(newey) hopt(lag) yl(3) tr(cmlt) nograph save irfn(cmlt)}{p_end}
{p 4 8 2}{cmd:. locproj gs10, shock(gs1 c.gs1#c.gs1) h(12) m(newey) hopt(lag) yl(3) sl(4) nograph save irfn(quad)}{p_end}
{p 4 8 2}{cmd:. locproj gs10, shock(gs1 c.gs1#c.gs1) h(12) m(newey) hopt(lag) yl(3) sl(4) tr(cmlt) nograph save irfn(quad_cmlt)}{p_end}

{p}Second, we are going to create one graph with the 4 IRFs plotted together.{p_end}

{p 4 8 2}{cmd:. lpgraph level cmlt quad quad_cmlt, h(12) tti(Number of Days) lab1(Levels) lab2(Cumulative) lab3(Quadratic) lab4(Quad. & Cumult.) title(1-Year Treasury IRF, size(*0.9))}{p_end}

{p}In this case we have the option of choosing the color of each one of the IRFs:{p_end}

{p 4 8 2}{cmd:. lpgraph level cmlt quad quad_cmlt, h(12) tti(Number of Days) lab1(Levels) lab2(Cumulative) lab3(Quadratic) lab4(Quad. & Cumult.) lc1(red) lc2(green) lc3(blue) lc4(brown) title(1-Year Treasury IRF, size(*0.9))}{p_end}


{title:Example 2. Creating separate graphs and combining them into a single one}

{p}We are going to create three separate graphs and then combine them into a single one. For doing so, we need to specify the option 
{opt separate}. In this case, we are giving each separate graph a title, and therefore, we also specify the option {opt nogelend}.
Additionally, we are choosing the color red for the IRFs lines of the three graphs:{p_end}


{p 4 8 2}{cmd:. lpgraph level cmlt quad quad_cmlt, ti1(Levels) ti2(Cumulative) ti3(Quadratic) ti4(Quadratic & Cumulative) separate nolegend lcolor(red) tti(Number of Days) h(12) title(1-Year Treasury IRF, size(*0.9))}{p_end}


{synoptline}

{title:Author}

Alfonso Ugarte-Ruiz
alfonso.ugarte@bbva.com
