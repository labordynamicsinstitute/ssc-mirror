{smcl}
{* NJC 27oct2024/1nov2024/5nov2024}{...}

{cmd:help cisets}
{hline}

{title:Title}

{p 4 4 2}{bf:cisets} {hline 2} Confidence interval sets for various summary statistics{p_end}


{title:Syntax}

{phang}Confidence interval sets for means, normal distribution

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:mean:s} {varlist} 
{ifin}
[{it:{help weight}}]
[
{cmd:,} 
{opt inclusive} 
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:mean:s} {varname} 
{ifin}
[{it:{help weight}}]
{cmd:,} {opt over(groupvar)} 
[
{cmdab:t:otal}
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]


{phang}Confidence interval sets for means, Poisson distribution

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:mean:s} {varlist} 
{ifin}
[{it:{help weight}}]
{cmd:,}
{opt pois:son}
[
{opth exp:osure(varname)}
{opt inclusive} 
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:mean:s} {varname} 
{ifin}
[{it:{help weight}}]
{cmd:,}
{opt pois:son} 
{opt over(groupvar)}
[
{opth exp:osure(varname)}
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]


{phang}Confidence interval sets for proportions

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:prop:ortions} {varlist}
{ifin}
[{it:{help weight}}]
[
{cmd:,}
{opt inclusive} 
{c -(}
{opt exact} | 
{opt wald} |
{opt wilson} |
{opt agres:ti} |
{opt jeff:reys}
{c )-}
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:prop:ortions} {varname} 
{ifin}
[{it:{help weight}}]
{cmd:,} 
{opt over(groupvar)}
[
{c -(}
{opt exact} | 
{opt wald} |
{opt wilson} |
{opt agres:ti} |
{opt jeff:reys}
{c )-}
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]


{phang}Confidence interval sets for variances  

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:var:iances}
{varlist}
{ifin}
[{it:{help weight}}]
[
{cmd:,}
{opt inclusive} 
{opt bon:ett}
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:var:iances}
{varname}
{ifin}
[{it:{help weight}}]
{cmd:,} 
{opt over(groupvar)}
[
{cmdab:t:otal}  
{opt bon:ett}
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]


{phang}Confidence interval sets for standard deviations

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:var:iances}
{varlist} 
{ifin}
[{it:{help weight}}]
{cmd:,}
{opt sd}
[
{opt inclusive} 
{opt bon:ett}
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:cisets} {cmdab:var:iances}
{varname} 
{ifin}
[{it:{help weight}}]{cmd:,}
{opt sd}
{opt over(groupvar)}
[
{cmdab:t:otal}
{opt l:evel(#)}
{opt saving(filespec)}
{opt bon:ett}
{it:list_options}
]


{phang}Confidence interval sets for geometric means

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:cisets} {cmd:gmean}
{varlist} 
{ifin}
[{it:{help weight}}]
[
{cmd:,}
{opt inclusive} 
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:cisets} {cmd:gmean}
{varname} 
{ifin}
[{it:{help weight}}]{cmd:,}
{opt over(groupvar)}
[
{cmdab:t:otal}
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]


{phang}Confidence interval sets for harmonic means

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:cisets} {cmd:hmean}
{varlist}
{ifin}
[{it:{help weight}}]
[
{cmd:,}
{opt inclusive} 
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:cisets} {cmd:hmean}
{varname} 
{ifin}
[{it:{help weight}}]
{cmd:,}
{opt over(groupvar)}
[
{cmdab:t:otal}
{opt l:evel(#)}
{opt saving(filespec)}
{it:list_options}
]


{phang}Confidence interval sets for centiles 

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:cisets} {cmd:centile}
{varlist} 
{ifin}
[
{cmd:,}
{opt centile(#)}
{opt inclusive}
{c -(}
{opt cc:i} |
{opt n:ormal} | 
{opt m:eansd}
{c )-}
{opt saving(filespec)} 
{it:list_options}
] 

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:cisets} {cmd:centile}
{varname} 
{ifin}
{cmd:,}
{opt over(groupvar)}
[
{opt centile(#)}
{c -(}
{opt cc:i} |
{opt n:ormal} | 
{opt m:eansd}
{c )-}
{opt t:otal}
{opt l:evel(#)}
{opt saving(filespec)} 
{it:list_options}}
]


{p 4 4 2}
{opt aweight}s are allowed with {cmd:cisets} subcommands {cmd:means} for
normal data; {cmd:gmean}; and {cmd:hmean}. 

{p 4 4 2}
{opt fweight}s are allowed with {cmd:cisets} subcommands {cmd:means};
{cmd:proportions}; {cmd:variances}; {cmd:gmean}; and {cmd:hmean}. 

{p 4 4 2} 
Weights are not allowed with subcommand {cmd:centile}. 


{title:Description}

{pstd}
{cmd:cisets} computes confidence interval sets for population means,
proportions, variances, standard deviations, geometric means, harmonic
means, and centiles.  It is a wrapper for variously {help ci} (for
means, proportions, variances and standard deviations); {help ameans}
(for geometric and harmonic means); and {help centile}.  The help for
these commands and the corresponding manual entries should be consulted
for more detail on statistical principles and procedures. 

{pstd}
All syntaxes include {cmd:cisets} followed by a subcommand which
specifies a particular summary measure. There are two flavours of
commands otherwise: 

{p 8 8 2}{cmd:cisets} {it:subcommand} {it:varlist} calculates results
for one or more variables {it:varlist}. This is called the 
{it:variables syntax}.  

{p 8 8 2}{cmd:cisets} {it:subcommand} {it:varname} {cmd:,} {opt
over(groupvar)} calculates results for one variable {it:varname} for
each distinct value of {it:groupvar}. This is called the 
{it:groups syntax}.  

{pstd}
A confidence interval set consists of a temporary dataset consisting of
some or occasionally all of the following variables. 

{p 4 4 2}
* {cmd:varname} is a string variable holding the name or names of the
variable(s) being summarized. 

{p 4 4 2}
* {cmd:varlabel} is a string variable holding the variable label of each
variable being summarized. If no variable label has been defined, 
the value is instead the variable name. 

{p 4 4 2}
* (Groups syntax only) {cmd:origgvar} is a numeric or string variable 
as specified in the {cmd:over()} option.

{p 4 4 2}
* (Groups syntax only) {cmd:groupvar} is a string variable holding the
name of the group variable specified in the {cmd:over()}
option. 

{p 4 4 2}
* (Groups syntax only) {cmd:gvarlabel} is a string variable holding the
variable label of the group variable {it:groupvar} specified in the 
{cmd:over()} option. If no variable label has been defined, 
the value is instead the variable name.

{p 4 4 2}
* (Groups syntax only) {cmd:group} is a numeric variable with value labels 
describing each distinct value of {it:groupvar}. Each such variable 
has integer values 1 up and value labels derived from the variable specified. 

{p 4 4 2}
* {cmd:n} is a numeric variable holding the number of observations used 
in the estimate. 

{p 4 4 2}
* {cmd:statname} is a string variable holding a brief description of the 
parameter being estimated by a point estimate and a confidence
interval. With the subcommand {cmd:centile}, the corresponding percent 
is shown, either as specified with {cmd:centile()} or as defaulting to 
50% (median). 

{p 4 4 2}
* {cmd:point} is a numeric variable holding the point estimate of the
parameter being estimated.  

{p 4 4 2}
* (subcommands {cmd:means} and {cmd:proportions} only) 
{cmd:se} is a numeric variable holding the standard error reported. 

{p 4 4 2}
* {cmd:lb} is a numeric variable holding the lower bound of the confidence
interval estimate.  

{p 4 4 2}
* {cmd:ub} is a numeric variable holding the upper bound of the confidence 
interval estimate.

{p 4 4 2}
* {cmd:level} is a numeric variable holding the confidence level used. 

{p 4 4 2}
* {cmd:options} is a string variable appearing if (and only if) other
options have been specified as a record of such option choice. 

{p 4 4 2}
* {cmd:weights} is a string variable appearing if (and only if) weights were 
specified as a record of such use. 


{title:Remarks}

{pstd}{cmd:cisets} by default lists its results. Although saving to 
a permanent dataset is optional, that is the intended key to many 
useful applications. Either the confidence interval dataset is what 
is needed or it may be combined using {help append} or {help merge} 
with other such sets for further analysis. 

{pstd}The approach is thus one of providing a building block that may be
useful directly or if combined with other building blocks.  Flexibility
is needed because so many different problems may be of interest, not
just comparison of intervals for different variables, or of intervals
for one variable for different groups, but also of intervals for several
variables and several groups; comparison of parameters; comparison of
results for different confidence levels; comparison of different
methods; and so forth. 

{pstd}As in {help ci}, variables that are not (0, 1) binary variables 
are ignored with {cmd:cisets proportions}. 

{pstd}As in {help ameans}, any zero or negative values are ignored 
with {cmd:cisets gmean} and {cmd:cisets hmean}. 

{pstd}At first sight, a confidence interval set may seem repetitious.
With a little experience, you will see that such repetition is often
helpful when combining such sets. In any case, you can always ignore
what you do not need. Similarly, you can use {help rename} and 
{help replace} as you wish downstream of this command.

{pstd}Graphical and other applications lie downstream of this command,
although some suggestions are included in the examples. Possibilities 
include {help twoway rcap}, {help twoway rspike} and {help twoway rbar} 
for plotting intervals (lower and upper bounds) and {help twoway scatter} 
for the point estimates within. 

{pstd}Helper commands include {cmd:myaxis} to sort on some criterion 
(Cox 2021) and {cmd:nicelabels} (Cox 2022) and {cmd:niceloglabels} (Cox 2018) 
for automating axis labels.  

{pstd}The approach to correlation confidence intervals of Cox (2008) is 
broadly similar. See also {help pctilesets} or {help momentsets} if
installed.

{pstd}In statistical graphics, showing confidence intervals {c -} or their 
antecedents and relatives under various names such as error bars {c -} has 
a history over decades, if not centuries. That history does not seem well 
documented. 

{pstd}In terms of Stata's own {cmd:twoway} commands, use of something like 
{help scatter} to show a point estimate as a point or marker symbol is very 
common, but not universal. Some authors argue that the importance of showing 
estimates as intervals means that a point symbol should be suppressed. More 
frequently, bars usually starting at zero are used to show point estimates. 
When combined with capped or uncapped spikes, as mentioned just below, such 
plots have been described pejoratively as dynamite, detonator or plunger plots 
and often deplored. 

{pstd}Otherwise, showing the intervals with capped spikes using something 
like {help twoway rcap} seems the most common style; showing uncapped spikes 
using something like {help twoway rspike} next most common; and showing range bars, 
whether coloured or blank, using something like {help twoway rbar} seems less 
common than either of those. The choice may seem a matter of style or personal
preference unless there is evidence that any form is most effective. 
Wilkinson (1999, 2005) gives examples of all, including range bars. 
See also Wilkinson (2006) on Pareto dot plots. 

{pstd}The command {cmd:qplot} is used in examples: see Cox (1999, 2005) 
and search for updates. By default the horizontal axis is a probability 
scale from 0 to 1 so (for example) 1 is a predictable place to add 
a confidence interval on the right of each display, so long as any 
bar is not too wide. For a normal quantile plot the range of standard 
normal deviates depends on the sample size, as indicated by this Mata 
output for a plotting position (rank - 0.5) / sample size. The largest 
standard normal deviate plotted increases with sample size.

    : n ,  (n :- 0.5) :/ n,  invnormal((n :- 0.5) :/ n)
                     1             2             3
        +-------------------------------------------+
      1 |           10           .95   1.644853627  |
      2 |          100          .995   2.575829304  |
      3 |         1000         .9995   3.290526731  |
      4 |        10000        .99995   3.890591886  |
        +-------------------------------------------+


{title:Options}

{it:Options allowed with all subcommands}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals.  The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{it:list_options} are any options of {help list} other than {cmd:noobs} that 
may be specified to tune listing of the confidence interval set. 

{phang}
{opt saving(filespec)} specifies saving the confidence interval set to a file as a 
Stata dataset. The suboption {cmd:, replace} must be specified to overwrite
an existing dataset. 


{it:Option allowed with the variables syntax}

{phang}
{opt inclusive} may be specified if you wish to work with several variables 
together. By default, calculations are only made with observations that
have non-missing values for all variables specified. This option
overrides that default selection: hence for several variables which
observations with non-missing values are used will be determined
separately for each variable. In other jargon, this option triggers
casewise deletion, not listwise deletion or complete case analysis. 
As a convenience for people familiar with that term, or with other 
syntax used to this effect, {cmd:cw} and {cmd:allobs} are allowed 
as synonyms. 


{it:Option compulsory with the groups syntax}

{phang}
{opt over(groupvar)} must be specified to name the group variable. 
Distinct groups of observations on {it:groupvar} will be used 
to determine confidence intervals for the main variable specified. 


{it:Option allowed with the groups syntax}

{phang}
{opt total} may be used with {opt over(groupvar)}. It specifies that in addition
to output for each group, output be added for all groups combined.


{it:Options allowed with} {cmd:cisets mean}

{phang}
{opt poisson} specifies that the variables are
Poisson-distributed counts; exact Poisson confidence intervals will be
calculated. By default, confidence intervals for means are calculated based on
a normal distribution.

{phang}
{opth exposure(varname)} is used only with {opt poisson}.  You do not need
to specify {opt poisson} if you specify {opt exposure()};
{opt poisson} is assumed. {it:varname} contains the total exposure (typically a
time or an area) during or over which the number of events recorded was
observed.


{it:Options allowed with} {cmd:cisets proportions}

{phang}
{opt exact}, {opt wald}, {opt wilson}, {opt agresti}, and {opt jeffreys}
specify how binomial confidence intervals are to be calculated. Only one of 
these options may be specified. 

{phang}
{opt exact} is the default and specifies exact (also known in the literature
as Clopper-Pearson) binomial confidence intervals.

{phang}
{opt wald} specifies calculation of Wald confidence intervals.

{phang}
{opt wilson} specifies calculation of Wilson confidence intervals.

{phang}
{opt agresti} specifies calculation of Agresti-Coull confidence intervals.

{phang}
{opt jeffreys} specifies calculation of Jeffreys confidence intervals.


{it:Options allowed with} {cmd:cisets variances}

{phang}
{opt sd} specifies that confidence intervals for standard deviations be
calculated. The default is to compute confidence intervals for variances.

{phang}
{opt bonett} specifies that Bonett confidence intervals be calculated.
The default is to compute normal-based confidence intervals, which assume
normality for the data.


{it:Options allowed with} {cmd:cisets centile}

{phang}
{opth centile(#)} specifies the centile or percentile to be reported.
The default is to display the 50th centile or percentile (median).
Specifying {cmd:centile(5)} requests that the fifth centile be reported.

{phang}
Only one of the following options may be specified. 

{phang}
{opt cci} (conservative confidence interval) forces the confidence limits to
fall exactly on sample values.  Confidence intervals displayed with the
{opt cci} option are slightly wider than those with the default. 

{phang}
{opt normal} causes the confidence interval to be calculated by using a formula
for the standard error of a normal-distribution quantile. The {opt normal} option
is useful when you want empirical centiles -- that is, centiles based on sample
order statistics rather than on the mean and standard deviation -- and are
willing to assume normality.

{phang}
{opt meansd} causes the centile and confidence interval to be calculated based
on the sample mean and standard deviation, and it assumes normality.


{title:Examples}

{phang}{cmd:. sysuse auto, clear}{p_end}

{phang}{cmd:. cisets mean mpg, over(rep78) saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets mean mpg price weight, saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets prop foreign, over(rep78) jeffreys saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets prop foreign, jeffreys saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets var mpg, over(rep78) saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets var mpg price weight, saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets gmean mpg, over(rep78) saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets gmean mpg price weight, saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets hmean mpg, over(rep78) saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets hmean mpg price weight, saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets centile mpg, over(rep78) saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets centile mpg price weight, saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets centile mpg price weight, centile(75) saving(foo, replace)}{p_end}
{phang}{cmd:. d using foo}{p_end}

{phang}{cmd:. cisets centile mpg, over(rep78) total saving(foo, replace)}{p_end}
{phang}{cmd:. u foo, clear}{p_end}

{phang}{cmd:. replace statname = "median"}{p_end}

{pstd}{cmd:. twoway rspike ub lb group || scatter point group, pstyle(p1) msize(medlarge) ms(D)}{p_end}
{pstd}{cmd: xtitle("`=gvarlabel'") xla(1/6, valuelabel) legend(off) ytitle("`=varlabel'")}{p_end}
{pstd}{cmd: subtitle("`=statname's: `=level'% confidence intervals", place(w)) name(CI1, replace)}{p_end}

{pstd}{cmd:. twoway rspike ub lb group, horizontal || scatter group point, pstyle(p1) msize(medlarge) ms(D)}{p_end}
{pstd}{cmd:  ytitle("`=gvarlabel'") yla(1/6, valuelabel) legend(off) xtitle("`=varlabel'")}{p_end}
{pstd}{cmd:  subtitle("`=statname's: `=level'% confidence intervals", place(w)) ysc(reverse) xsc(alt) ysc(r(0.8 .)) name(CI2, replace)}{p_end}

{phang}{cmd:. su ub, meanonly}{p_end}
{phang}{cmd:. local ubmax = r(max)}{p_end}
{phang}{cmd:. su lb, meanonly}{p_end}
{phang}{cmd:. local lbmin = r(min)}{p_end}
{phang}{cmd:. gen where = `lbmin' - (`ubmax' - `lbmin') / 10}{p_end}
{phang}{cmd:. gen show_n = ("{it:n} = ") + strofreal(n)}{p_end}

{pstd}{cmd:. twoway rspike ub lb group || scatter where group, ms(none) mla(show_n) mlabpos(0) mlabc(black) mlabsize(medium)}{p_end}
{pstd}{cmd:  || scatter point group, pstyle(p1) msize(medlarge)  ms(D) xtitle("`=gvarlabel'") xla(1/6, valuelabel) xsc(r(0.5, 6.5))}{p_end}
{pstd}{cmd:  legend(off) ytitle("`=varlabel'") subtitle("`=statname's: `=level'% confidence intervals", place(w)) name(CI3, replace)}{p_end}

{pstd}{cmd:. twoway rbar ub lb group, lcolor(stc1) fcolor(none) barw(0.2)}{p_end}
{pstd}{cmd:  || scatter where group, ms(none) mla(show_n) mlabpos(0) mlabc(black) mlabsize(medium)}{p_end}
{pstd}{cmd:  || scatter point group, pstyle(p1) msize(medlarge)  ms(D) xtitle("`=gvarlabel'")}{p_end}
{pstd}{cmd:  xla(1/6, valuelabel) xsc(r(0.5, 6.5)) legend(off) ytitle("`=varlabel'") subtitle("`=statname's: `=level'% confidence intervals", place(w)) name(CI4, replace)}{p_end}

{phang}{cmd:. webuse citytemp, clear}{p_end}
{phang}{cmd:. cisets mean heatdd, over(division) saving(foo, replace)}{p_end}
{phang}{cmd:. u foo}{p_end}

{phang}{cmd:. myaxis group2=group, sort(mean point)}{p_end}
{pstd}{cmd:. twoway rspike ub lb group2 || scatter point group2, pstyle(p1) xla(1/9, valuelabel tlc(none))}{p_end}
{pstd}{cmd:  ytitle(`=varlabel' (day {&degree}F)) subtitle("`=statname's: `=level'% confidence intervals", place(w)) legend(off) xsc(r(0.8 9.2)) name(CI5, replace)}{p_end}

{phang}{cmd:. sysuse auto, clear}{p_end}

{phang}{cmd:. cisets gmean price, over(foreign) saving(foo, replace)}{p_end}

{phang}{cmd:. clonevar origgvar=foreign}{p_end}

{phang}{cmd:. merge m:1 origgvar using foo}{p_end}

{phang}{cmd:. gen where = 1}{p_end}

{phang}{cmd:. qplot price, ms(O) by(foreign, legend(off) note(95% confidence intervals for geometric means))}{p_end}
{pstd}{cmd: xla(0 0.25 "0.25" 0.5 "0.5" 0.75 "0.75" 1)}{p_end}
{pstd}{cmd: ysc(log) yla(3000(2000)15000) ytitle(Price (USD)) xtitle(Fraction of data)}{p_end}
{pstd}{cmd: addplot(rbar ub lb where, barw(0.08) fcolor(none) pstyle(p2)}{p_end}
{pstd}{cmd: || scatter point where, ms(D) msize(medlarge) pstyle(p2)) name(CI6, replace)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:References}

{phang}Cox, N. J. 1999. 
Quantile plots, generalized.
{it:Stata Technical Bulletin} 51: 16{c -}18.        

{phang}Cox, N. J. 2005.      
Speaking Stata: The protean quantile plot. 
{it:Stata Journal} 5: 442{c -}460. 

{phang}Cox, N. J. 2008. 
Speaking Stata: Correlation with confidence, or Fisher's z revisited.
{it:Stata Journal} 8: 413{c -}439. 

{phang}Cox, N. J. 2018. 
Speaking Stata: Logarithmic binning and labeling.
{it:Stata Journal} 18: 262{c -}286. 

{phang}Cox, N. J. 2021. 
Speaking Stata: Ordering or ranking groups of observations.
{it:Stata Journal} 21: 818{c -}837. 

{phang}Cox, N. J. 2022.       
Speaking Stata: Automating axis labels: Nice numbers and transformed scales. 
{it:Stata Journal} 22: 975{c -}995. 

{phang}Wilkinson, L. 1999.
{it:The Grammar of Graphics.}
New York: Springer. See pp.183, 223, 269, 271. 

{phang}Wilkinson, L. 2005.
{it:The Grammar of Graphics.}
New York: Springer. See pp.102, 131, 218, 220, 461, 470, 478, 479, 480, 481, 522. 

{phang}Wilkinson, L. 2006. 
Revising the Pareto chart.  {it:American Statistician} 60: 332{c -}334.


{title:Also see}

{p 4 4 2}help for {help ci}

{p 4 4 2}help for {help ameans} 

{p 4 4 2}help for {help centile} 
