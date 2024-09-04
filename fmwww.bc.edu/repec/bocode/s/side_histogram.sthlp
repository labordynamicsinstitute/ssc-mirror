{smcl}
{* 2sep2024}{...}
{cmd:help side_histogram}
{hline}

{title:Title}

{p2colset 5 19 23 2}{...}
{p2col :{hi:side_histogram} {hline 2} Side by side histograms for two groups}{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2} 
{cmd:side_histogram} 
{varname}
{ifin}
{weight}
{cmd:,}
{opt over(groupvar)}
[,
{opt start(#)}
{opt width(#)}
{ {opt frac:tion} | 
{opt freq:uency} } 
{opt d:iscrete} 
{opt bar1:options(bar_options)}
{opt bar2:options(bar_options)}
{opt squeeze(#)}
{it:graph_options}
] 

{p 4 4 2}fweights are allowed: see {help weight}.


{title:Description}

{p 4 4 2}
{cmd:side_histogram} draws side-by-side histograms for {it:varname} and
precisely two groups of {it:groupvar}. Suppose the bin width is {it:w}. 
Then histogram bars for each bin and group are by default placed side
by side, each with bar width {it:w}/2.


{title:Remarks}

{p 4 4 2}
This command is presented without endorsement of whether it is a good 
idea either in general or for particular applications. 

{p 4 4 2}
Generalisation to grouping variables with three or more distinct 
categories is not planned. You may get what you wish with 
{help graph bar}, but be warned that that command has limited scope to
plot bars for bins not populated in the data. 


{title:Options} 

{p 4 8 2}
{cmd:over()} specifies a numeric or string variable {it:groupvar} with
precisely two distinct non-missing values in the data chosen. It is a
required option. 

{p 4 8 2}
{cmd:start()} specifies the start of binning. It defaults to the minimum
observed value. 

{p 4 8 2}
{cmd:width()} specifies the bin width to be used. Its default implies a
maximum of 20 bins.

{p 8 8 2}
Most users should want to take control of bin start and width. That
choice should benefit from looking at results of {help summarize} and/or
a rough histogram. 

{p 4 8 2}{cmd:fraction} specifies that the vertical axis should show
fractions (proportions) of the total frequency. 

{p 4 8 2}{cmd:frequency} specifies that the vertical axis should show
frequencies or counts. 

{p 8 8 2}These options may not be specified together. 

{p 4 8 3}{cmd:discrete} specifies that {it:varname} should be regarded
as discrete, not continuous. 

{p 4 8 2}{cmd:bar1options()} and {cmd:bar2options()} specify options of
{help twoway bar} controlling the first and second sets of bars
respectively. 

{p 4 8 2}
{cmd:squeeze()} may be used to squeeze bars so that a thin space is
added on either side of each pair of bars. This action would be cosmetic
or psychological. The default is 1, meaning no squeezing, so that all
bars touch by default. Otherwise, a number such as 0.8 may have
appealing results.  

{p 4 8 2}
{it:graph_options} are other options of {help twoway}. Good examples would be 
{cmd:name()} or {cmd:saving()}. 


{title:Examples}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}

{p 4 8 2}{cmd:. side_histogram mpg, over(foreign) start(10) width(1) freq legend(row(1) pos(12)) name(mpg, replace)}{p_end}

{p 4 8 2}{cmd:. side_histogram rep78, over(foreign) discrete width(1) squeeze(0.8) freq legend(row(1) pos(12)) name(rep78, replace)}{p_end}

{p 4 8 2}{cmd:. * this example stimulated by Alexander (2023, pp.246{c -}247)}{p_end}
{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. set obs 1000}{p_end}
{p 4 8 2}{cmd:. set seed 314159}{p_end}

{p 4 8 2}{cmd:. gen which = _n >= 500}{p_end}
{p 4 8 2}{cmd:. label def which 1 No 0 Yes}{p_end}
{p 4 8 2}{cmd:. label val which which}{p_end}

{p 4 8 2}{cmd:. gen Outcome = rnormal(cond(which == 1, 5, 6), 1)}{p_end}

{p 4 8 2}{cmd:. side_histogram Outcome, width(0.2) over(which) freq xla(2/9) name(side, replace)}{p_end}

{p 4 8 2}{cmd:. twoway histogram Outcome if which == 0, freq ///}{p_end}
{p 4 8 2}{cmd:lcolor(stc1*2) fcolor(stc1%25) start(1.8) width(0.2) xla(2/9)  ///}{p_end}
{p 4 8 2}{cmd:|| histogram Outcome if which == 1, freq ///}{p_end}
{p 4 8 2}{cmd:lcolor(stc2*2) fcolor(stc2%25) start(1.8) width(0.2) ///}{p_end}
{p 4 8 2}{cmd:legend(order(1 "Yes" 2 "No")) name(super, replace)}{p_end}

{p 4 8 2}{cmd:. qplot Outcome, over(which) legend(off) trscale(invnormal(@)) ///}{p_end}
{p 4 8 2}{cmd:addplot(scatteri 8.8 2 "Yes", ms(none) mlabsize(large) mlabc(stc1) ///}{p_end}
{p 4 8 2}{cmd:|| scatteri 6.6 2 "No", ms(none) mlabsize(large) mlabc(stc2)) yla(2/9) xla(-3/3) ///}{p_end}
{p 4 8 2}{cmd:xtitle(Standard normal deviate) name(qplot, replace)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:References} 

{p 4 8 2}
Alexander, R. 2023. 
{it:Telling Stories with Data: With Examples in R.} 
Boca Raton, FL: CRC Press.
pp. 247, 319, 363, 364, 432, 497.  


{title:Also see}

{p 4 4 2}{help twoway__histogram_gen} 

{p 4 4 2}{help twoway bar} 

{p 4 4 2}{help qplot} ({it:Stata Journal}) (if installed)


