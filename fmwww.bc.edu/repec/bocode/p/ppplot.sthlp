{smcl}
{* 5mar2004/24aug2026}{...}
{hline}
help for {hi:ppplot}
{hline}

{title:P-P plots} 

{p 8 17 2} 
{cmd:ppplot}
{it:plottype} 
{it:varname}
[{it:weight}] 
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]
{cmd:,}
{cmd:by(}{it:byvar}{cmd:)}
[ 
{cmdab:miss:ing}
{cmdab:ref:erence(}{it:#}{cmd:)} 
{it:graph_options}
]

{p 8 17 2}
{cmd:ppplot} 
{it:plottype} 
{it:varlist}
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]
[{cmd:,}
{it:graph_options}
]


{title:Description}

{p 4 4 2}{cmd:ppplot} produces a P-P (probability-probability) plot of the 
cumulative distribution functions of one or more groups or 
variables against that of a reference group or variable, for the same sets of 
observed values. By default the reference group is the last variable named,  
or, with a single variable, that defined by the highest value of {it:byvar}. 

{p 4 4 2}For more than one variable in {it:varlist}, only observations with all
values of {it:varlist} present are shown.

{p 4 4 2}The plot may in principle be one of eight {help graph_twoway:twoway} types, namely,
{cmd:area}, {cmd:bar}, {cmd:connected}, {cmd:dot}, {cmd:dropline}, {cmd:line},
{cmd:scatter} or {cmd:spike}. The {it:plottype} must be specified. However, 
{cmd:line} or {cmd:connected} is likely to be preferred. 

{p 4 4 2}{cmd:fweight}s and {cmd:aweight}s may be specified. 


{title:Options}

{p 4 8 2} {cmd:by(}{cmd:)} specifies that groups are defined by the 
distinct values of a single variable {it:byvar}. {cmd:by()}
is only allowed with a single {it:varname}. Note: if the command were 
to be written from scratch in 2026, the option name would be {cmd:over()}, 
but the original option name is continued. 

{p 4 8 2}{cmd:missing}, used only with {cmd:by()}, permits the use of
non-missing values of {it:varname} corresponding to missing values for the
variable named by {cmd:by()}. The default is to ignore such values.

{p 4 8 2}{cmd:reference()}, used only with {cmd:by()}, specifies a reference 
group as a value of {it:byvar}. By default, the highest value of {it:byvar} 
in the data specified defines the reference group. 

{p 4 8 2}{it:graph_options} refers to options of {help graph} appropriate to
the {it:plottype} specified.  


{title:Remarks}

{p 4 4 2}This command was written in 2004 but I have not found it very useful 
as compared with plotting quantiles directly, or even cumulative distributions 
directly. I much appreciate a bug report from Chen Samulsion in 2026 which 
led to correction of the code. At the same time I made what I think are some 
other small improvements. I also add examples of quantile plots from the 
thread on Statalist 

{p 4 4 2}https://www.statalist.org/forums/forum/general-stata-discussion/general/1787111-ppplot-and-its-if-statement

{p 4 4 2}The extra examples require installation of {cmd:qplot} and 
{cmd:pctilesets} from the {it:Stata Journal}. 


{title:Examples}

{p 4 4 2}{cmd:. * 2004 examples, revised slightly }{p_end}
{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}

{p 4 8 2}{cmd:. ppplot connected mpg, by(foreign) name(mpg1, replace)}{p_end}
{p 4 8 2}{cmd:. ppplot connected mpg, by(foreign) ref(0) name(mpg2, replace)}{p_end}
{p 4 8 2}{cmd:. ppplot connected mpg, by(foreign) plot(function equality = x, clp(dash)) name(mpg3, replace)}{p_end}

{p 4 4 2}To sample all possible {it:plottype}s:
 
{p 4 8 2}{cmd:. foreach t in area bar connected dot dropline line scatter spike {c -(}}{p_end}
{p 4 8 2}{cmd:. ppplot `t' mpg, by(foreign) name(mpg`t', replace)}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 4 2}Some tuning may be desirable, for example::
 
{p 4 8 2}{cmd:. ppplot bar mpg, by(foreign) bartype(spanning) base(0) name(mpg4, replace)}{p_end}

{p 4 4 2}{cmd:. * 2026 additions }{p_end}
{p 4 8 2}{cmd:. webuse lbw, clear }{p_end}

{p 4 4 2}{cmd:. * example code originally from Chen Samulsion}{p_end}
{p 4 8 2}{cmd:. ppplot line bwt, by(race) plot(function equality=x, clp(dash)) name(gr123, replace)}{p_end}

{p 4 8 2}{cmd:. ppplot line bwt if race==1 | race==2, by(race) plot(function equality=x, clp(dash)) name(gr12, replace)}{p_end}

{p 4 4 2}{cmd:. * qplot 2.5.0 Stata Journal 26(3)}{p_end}
{p 4 8 2}{cmd:. qplot bwt, by(race, row(1) compact) name(G1, replace)}{p_end}
{p 4 8 2}{cmd:. egen mean = mean(bwt), by(race)}{p_end}
{p 4 8 2}{cmd:. bysort race (bwt) : gen x = cond(_n == 1, 0, cond(_n == _N, 1, 0))}{p_end}
{p 4 8 2}{cmd:. qplot bwt, by(race, row(1) compact note("lines show means") legend(off)) addplot(line mean x) xtitle(Fraction of data) name(G2, replace)}{p_end}

{p 4 4 2}{cmd:. * pctilesets from Stata Journal 26(2)}{p_end}
{p 4 8 2}{cmd:. pctilesets bwt, over(race) pctile(5 25 50 75 95) saving(pctiles, replace)}{p_end}
{p 4 8 2}{cmd:. clonevar origgvar=race }{p_end}
{p 4 8 2}{cmd:. merge m:1 origgvar using pctiles}{p_end}
{p 4 8 2}{cmd:. gen where = 1.1}{p_end}

{p 4 8 2}{cmd:. qplot bwt , by(race, row(1) compact note("lines show means; diamonds show medians; boxes show quartiles; spikes to 5% and 95% points") legend(off)) xtitle(Fraction of data)}{p_end}
{p 8 8 2}{cmd:addplot(line mean x || scatter p50 where, ms(Dh) msize(medlarge) pstyle(p2) || rbar p25 p75 where, barw(0.1) pstyle(p2) fcol(none) || rspike p75 p95 where, pstyle(p2) || rspike p25 p5 where, pstyle(p2))  name(G3, replace)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, University of Durham{break} 
n.j.cox@durham.ac.uk
	 

{title:Also see}

{p 4 13 2}On-line: help for {help graph}, {help cumul}, {help distplot} 
(if installed); {help qplot} (if installed); {help qqplotg} (if installed)

{p 4 13 2}Manual: {hi:[G] graph}, {hi:[R] cumul}, {hi:[R] diagnostic plots}

