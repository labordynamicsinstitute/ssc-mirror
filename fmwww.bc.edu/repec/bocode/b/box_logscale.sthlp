{smcl}
{* *! version 1.0  2023-10-03 Mark Chatfield}{...}
{vieweralsosee "[G-2] graph box" "mansection G-2 graphbox"}{...}
{viewerjumpto "Syntax" "box_logscale##syntax"}{...}
{viewerjumpto "Description" "box_logscale##description"}{...}
{viewerjumpto "Remarks" "box_logscale##remarks"}{...}
{viewerjumpto "Detail" "box_logscale##explanation"}{...}
{viewerjumpto "Examples" "box_logscale##examples"}{...}
{viewerjumpto "References" "box_logscale##references"}{...}
{viewerjumpto "Author" "box_logscale##author"}{...}
{viewerjumpto "Acknowledgements" "box_logscale##acknowledgements"}{...}
{viewerjumpto "Also see" "box_logscale##alsosee"}{...}
{title:Title}

{phang}
{bf:box_logscale} {hline 2} Box plots on the log scale (generalising Tukey's definition of whiskers)


{marker syntax}{...}
{title:Syntax}

{phang}
{opt box_logscale} {it:yvars} {ifin} {weight}{cmd:,} 
[{cmdab:h:orizontal}
{cmdab:lab:el(}{it:{help numlist}}{cmd:)} 
{cmdab:mti:ck(}{it:{help numlist}}{cmd:)} 
{it:{help graph box:graph_box_options}}]

{phang}
where {it:yvars} is a {it:{help varlist}}{p_end}

{synoptset 18 tabbed}{...}
{marker synoptions}{...}
{synopthdr:options}
{synoptline}
{synopt: {opt h:orizontal}}draw horizontal box plots{p_end}
{synopt: {opt lab:el(numlist)}}labels numeric axis with user-specified original-scale {it:numlist}{p_end}
{synopt: {opt mti:ck(numlist)}}minor values ticked along the numeric axis according to user-specified original-scale {it:numlist}{p_end}
{synopt: {it:graph_box_options}}choose from almost all of the options{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
See {help graph box} for what {bf:weight}s are allowed


{marker description}{...}
{title:Description}

{pstd}
{cmd:box_logscale} presents box plots on a logarithmic scale. 
It does this by log10 transforming the yvars, then running {cmd:graph box} or {cmd:graph hbox}. 
The numeric axis, however, is labelled with nice {it:original-scale} numbers. 
Optionally, you can specify what nice {it:original-scale} numbers you want as labels using {cmdab:lab:el()} 
and/or minor ticks using {cmdab:mti:ck()}.

{pstd}
N.B. If you want to use some {it: graph_box_options} such as {cmd:ylabel()}, {cmd:yline()}, {cmd:text()}, 
you will need to specify {it:log10-scale} numbers. See last example below.


{marker remarks}{...}
{title:Remarks}

{pstd}
This is an implementation of Nick Cox's advice in 
{browse "https://www.stata.com/support/faqs/graphics/box-plots-and-logarithmic-scales/":"How can I best get box plots on logarithmic scales?"}, 
which should save you time and brain power. It can be a better approach than: {cmd:graph box, yscale(log)}. 
Box plots where whiskers are instead based on percentiles can be produced with {cmd:stripplot}.

{pstd}{cmd:box_logscale} differs from {cmd:graph box, yscale(log)}{p_end}
{phang2}i) considerably in how whiskers (and therefore outside values) are defined{p_end}
{phang2}ii) considerably in how the numeric axis is labelled{p_end}
{phang2}iii) occasionally, and often in a minor way, in how the quartiles which make up the box (and middle line) are defined{p_end}

{pstd}This is because:{p_end} 
{pstd}{cmd:graph box, yscale(log)} applies the usual definitions to untransformed data, 
then plots the resulting statistics on a log-scaled axis.{p_end} 
{pstd}{cmd:box_logscale} log-transforms the data first, applies the usual definitions, 
plots the resulting statistics but labels on the numeric axis are carefully chosen 
such that they correspond to nice {it:original-scale} values 
̶ and with a little magic- these nice {it:original-scale} values appear on the numeric axis.{p_end}

{pstd}
Cox (2018) discusses labelling log-scaled axes in detail. His paper is well worth reading. 
When max/min is sufficiently large, I label using powers of 10 such as ..., 0.1, 1, 10, 100, 1,000, ... .
Otherwise, if max/min is not too small, I label like ..., 0.1, 0.2, 0.5, 1, 2, 5, 10, ... .
Labelling that I consider "nice" may not be labelling that you consider "nice".
You might prefer to specify different value labels and minor ticks, by specifying e.g. {cmd:label()} and {cmd:mtick()}.
You can attach "labels" to numbers by using {cmd:ylabel()} if you are careful - see last example below.


{marker explanation}{...}
{title:Detail}

{pstd}
{cmd:box_logscale} calculates quartiles of log10(y) in the usual manner described in {mansection "G-2 graphbox":[G-2] graph box}. 
Call them q1log, q2log, q3log. 
Then the following are calculated: Ulog = q3log + 1.5*(q3log - q1log) and Llog = q1log - 1.5*(q3log - q1log).
Then adjacent values for log10(y) are defined in the usual manner described in {mansection "G-2 graphbox":[G-2] graph box}, i.e. 
the upper adjacent value is the largest value of log10(y) not exceeding Ulog, and 
the lower adjacent value is the smallest value of log10(y) exceeding Llog. 
The plot is then drawn, and labels on the numeric axis are carefully chosen 
such that they correspond to (nice, possibly user specified) {it:original-scale} values 
- I make these nice values appear on the numeric axis.

{pstd}
This has the effect of looking like a plot of the untransformed data, where the box shows 
q1 = 10^q1log, q2 = 10^q2log and q3 = 10^q3log, and whiskers are drawn between the box and adjacent values, 
where adjacent values are now defined as: the upper adjacent value is the largest value of y not exceeding U, 
and the lower adjacent value is the smallest value of y exceeding L, where
U = 10^Ulog = q3 * (q3/q1)^1.5, and
L = 10^Llog = q1 / (q3/q1)^1.5.
It could be argued this results in a generalisation of Tukey's definition of whiskers (Tukey 1977).

{pstd}
Minor point: q1 and q3 can differ from the first and third quartiles of y because 
order statistics sometimes need to be averaged to calculate quartiles. 
This happens when N is a multiple of 4. In that case q1 and q3 are calculating a geometric mean 
rather than an arithmetic mean. The same is true of the median, when N is a multiple of 2. 

{pstd}
When some values ≤0, {cmd:box_logscale} alerts the user and does not produce a graph.  

 
{marker examples}{...}
{title:Examples}

{pstd}Let's generate a dataset with a lognormal variable.{p_end}	
{phang2}{sf:. }{stata `"clear"'}{p_end}
{phang2}{sf:. }{stata `"set seed 999"'}{p_end}
{phang2}{sf:. }{stata `"set obs 999"'}{p_end}
{phang2}{sf:. }{stata `"generate y = 10^rnormal(0,0.3)"'}{p_end}

{pstd}Before showing off {cmd:box_logscale}, let's see the result of using Stata's {cmd:graph box} command 
when we ask for the numeric axis to have a log scale. Yuk! So many high outside values and no low outside values. 
And a badly labelled numeric axis.{p_end}

{phang2}{sf:. }{stata "graph box y, yscale(log)"}{p_end}

{pstd}In contrast, {cmd:box_logscale} shows just a few high outside values and just a few low outside values. 
It also labels the numeric axis nicely.{p_end}	
{phang2}{sf:. }{stata "box_logscale y"}{p_end}

{pstd}If you want just .1, 1 and 10 on the numeric axis. And minor ticks at .2(.1).9 and 2(1)9.{p_end}	
{phang2}{sf:. }{stata "box_logscale y, label(.1 1 10) mtick(.2(.1).9  2(1)9)"}{p_end}

{pstd}If you want just a line at y=0.5, and labels "0.1" and "0.5" on the numeric axis rather than the numbers .1 and .5.{p_end}	
{phang2}{sf:. }{stata `"box_logscale y, yline(`=log10(0.5)') ylabel(`=log10(0.1)' "0.1" `=log10(0.5)' "0.5" `=log10(1)' "1" `=log10(10)' "10") mtick(.2(.1).9  2(1)9) "'}{p_end}

{pstd}If you have {cmd:stripplot} installed, you can create box plots on the log scale using {it:percentile-based whiskers}. {p_end}	
{phang2}{sf:. }{stata `"stripplot y, box pctile(0.35) yscale(log) vertical ms(none) outside(ms(o)) note("whiskers to 0.35% and 99.65% percentiles")"'}{p_end}
{pstd}With {cmd:stripplot}, i) you would need to improve labels, 
ii) you can only have one over() if you have just one yvar, 
iii) you can do some cool things like plot all datapoints as well as a box.{p_end}


{marker references}{...}
{title:References}

{phang}Cox, N.J. "How can I best get box plots on logarithmic scales?" 
{browse "https://www.stata.com/support/faqs/graphics/box-plots-and-logarithmic-scales/"}{p_end}
{phang}Cox, N.J. 2018. Speaking Stata: Logarithmic binning and labelling. Stata Journal 18: 262–286.{p_end}
{phang}Cox, N.J. 2020. Software update for niceloglabels. Stata Journal 20: 1028-1030.{p_end}
{phang}Tukey, J.W. 1977. Exploratory Data Analysis. Reading, MA: Addison-Wesley.{p_end} 

{marker author}{...}
{title:Author}

{p 4 4 2}
Mark Chatfield, The University of Queensland, Australia.{break}
m.chatfield@uq.edu.au{break}


{marker acknowledgements}{...}
{title:Acknowledgements}

{p 4 4 2}
I have incorporated some of the syntax from Nick Cox's {cmd:niceloglabels} command (Cox 2018, 2020) 
as well as his {cmd:mylabels} and {cmd:myticks} commands. This is to avoid dependency on his commands being installed. 
But they are fabuluous, and worth checking out.


{marker alsosee}{...}
{title:Also see}

{p 4 4 2}
Help: {helpb niceloglabels} (if installed), {helpb mylabels} (if installed), {helpb myticks} (if installed), {helpb stripplot} (if installed){p_end}
