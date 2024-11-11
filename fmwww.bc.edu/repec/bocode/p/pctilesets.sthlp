{smcl}
{* NJC 1nov2024}{...}

{cmd:help pctilesets}
{hline}

{title:Title}

{p 4 4 2}{bf:pctilesets} {hline 2} Percentile or quantile sets for selected levels{p_end}


{title:Syntax}

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:pctilesets} {varlist} 
{ifin}
[{it:{help weight}}]
[
{cmd:,} 
{opt inclusive} 
{opt p:ctile(numlist)}
{opt min:imum}
{opt max:imum}
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:pctilesets} {varname} 
{ifin}
[{it:{help weight}}]
{cmd:,} {opt over(groupvar)} 
[
{cmdab:t:otal}
{opt p:ctile(numlist)}
{opt min:imum}
{opt max:imum}
{opt saving(filespec)}
{it:list_options}
]

{p 4 4 2}
{opt aweight}s and {opt fweight}s are allowed. 


{title:Description}

{pstd}
{cmd:pctilesets} computes percentile or quantile sets.  
It is a wrapper for {help summarize}.  
The help for {cmd:summarize} and the corresponding manual entry  
should be consulted for more detail on statistical principles and procedures. 

{pstd}
Typically the user will specify one or more of the options {opt pctile()}, 
{opt minimum} and {opt maximum} to select extremes and/or any or all 
of the percentiles for 1, 5, 10, 25 (lower quartile), 50 (median), 
75 (upper quartile), 90, 95 and 99% cumulative probability. 

{pstd}
There are two syntaxes. 

{p 8 8 2}{cmd:pctilesets} {it:varlist} calculates results
for one or more variables {it:varlist}. This is called the {it:variables syntax}.  

{p 8 8 2}{cmd:pctilesets} {it:varname}{cmd:,} {opt over(groupvar)} 
calculates results for one variable {it:varname} for each distinct value of
{it:groupvar}. This is called the {it:groups syntax}.  

{pstd}
A percentile set consists of a temporary dataset consisting of some 
or occasionally all of the following variables. 

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
* Any or all of {cmd:min}, {cmd:p1}, {cmd:p5}, {cmd:p10}, {cmd:p25},
{cmd:p50}, {cmd:p75}, {cmd:p90}, {cmd:p95} and {cmd:p99} holding results
for the measure concerned. 

{p 4 4 2}
* {cmd:weights} is a string variable appearing if (and only if) weights were 
specified as a record of such use. 


{title:Remarks}

{pstd}{cmd:pctilesets} by default lists its results. Although saving to 
a permanent dataset is optional, that is the intended key to many 
useful applications. Either the percentile dataset is what 
is needed or it may be combined using {help append} or {help merge} 
with other such sets for further analysis. 

{pstd}The approach is thus one of providing a building block that may 
be useful directly or if combined with other building blocks. 
Flexibility is needed because so many different problems may be of interest, 
not just comparison of percentiles for different variables, or of percentiles 
for one variable for different groups, but also of percentiles for several 
variables and several groups; and so forth. 

{pstd}At first sight, a percentile set may seem repetitious. 
With a little experience, you will see that such repetition is often 
helpful when 
combining such sets. In any case, you can always ignore what you 
do not need. Similarly, you can use {help rename} and {help replace}
as you wish downstream of this command.

{pstd}Graphical and other applications lie downstream of this command,
although some suggestions are included in the examples. Possibilities 
include {help twoway rcap}, {help twoway rspike} and {help twoway rbar} 
for plotting intervals between percentiles and {help twoway scatter} for 
plotting particular percentiles. 

{pstd}Helper commands include {cmd:myaxis} to sort on some criterion 
(Cox 2021) and {cmd:nicelabels} (Cox 2022) and {cmd:niceloglabels} (Cox 2018) 
for automating axis labels. 

{pstd}The approach to correlation confidence intervals of Cox (2008) is 
broadly similar. See also {help cisets} or {help momentsets} if installed. 

{pstd}The command {cmd:qplot} is used in examples: see Cox (1999, 2005) 
and search for updates. By default the horizontal axis is a probability 
scale from 0 to 1 so (for example) 1.1 is a predictable place to add 
something like a box plot on the right of each display, so long as each 
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

{it:Option allowed with either syntax}

{phang}
{cmd:pctile()} allows any or all of 1 5 10 25 50 75 90 95 99 indicating that 
such percentiles be included in the results as calculated by {help summarize}. 
Any other integers between 2 and 98 will be ignored with a warning. 

{phang} 
{cmd:minimum} requests that the minimum be included in the results. 

{phang} 
{cmd:maximum} requests that the maximum be included in the results.

{phang}
{it:list_options} are any options of {help list} other than {cmd:noobs} that 
may be specified to tune listing of the confidence interval set. 

{phang}
{opt saving(filespec)} specifies saving the percentile set to a file as a 
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
to produce separate results for the main variable specified. 


{it:Option allowed with the groups syntax}

{phang}
{opt total} may be used with {opt over(groupvar)}. It specifies that in addition
to output for each group, output be added for all groups combined.


{title:Examples}

{phang}{cmd:. sysuse auto, clear}{p_end}

{phang}{cmd:. pctilesets mpg, p(25 50 75) min max over(foreign) saving(foo, replace)}{p_end}

{phang}{cmd:. clonevar origgvar=foreign}{p_end}

{phang}{cmd:. merge m:1 origgvar using foo}{p_end}

{phang}{cmd:. gen where = 1.1}{p_end}

{phang}{cmd:. #delimit ;}{p_end}
{phang}{cmd:. qplot mpg, ms(O) by(foreign, note("") legend(off))}{p_end}
{pstd}{cmd:   addplot(scatter p50 where, ms(Dh) msize(medlarge) pstyle(p2)}{p_end}
{pstd}{cmd:   xla(0 1 0.25 "0.25" 0.5 "0.5" 0.75 "0.75") xtitle(Fraction of data)}{p_end}
{pstd}{cmd:   || rbar p75 p25 where, fcolor(none) barw(0.12) pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike p25 min where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike p75 max where, pstyle(p2)) name(QB1, replace);}{p_end}
{phang}{cmd:. #delimit cr}{p_end}

{phang}{cmd:. replace where = 2.7}{p_end}

{phang}{cmd:. #delimit ;}{p_end}
{phang}{cmd:. qplot mpg, ms(O) by(foreign, note("") legend(off))}{p_end}
{pstd}{cmd:   xla(-2/2) xtitle(Standard normal deviate)}{p_end}
{pstd}{cmd:   addplot(scatter p50 where, ms(Dh) msize(medlarge) pstyle(p2)}{p_end}
{pstd}{cmd:   || rbar p75 p25 where, fcolor(none) barw(0.44) pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike p25 min where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike p75 max where, pstyle(p2)) trscale(invnormal(@))}{p_end}
{pstd}{cmd:   name(QB2, replace);}{p_end}
{phang}{cmd:. #delimit cr}{p_end}

{phang}{cmd:. replace where = 0.5}{p_end}

{phang}{cmd:. #delimit ;}{p_end}
{phang}{cmd:. qplot mpg, ms(O) by(foreign, note("") legend(off))}{p_end}
{pstd}{cmd:   xla(0 1 0.25 "0.25" 0.5 "0.5" 0.75 "0.75") xtitle(Fraction of data)}{p_end}
{pstd}{cmd:   addplot(rbar p25 p50 where, barw(0.5) fcolor(none) pstyle(p2)}{p_end}
{pstd}{cmd:   || rbar p75 p50 where, fcolor(none) barw(0.5) pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike p25 min where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike p75 max where, pstyle(p2) below)}{p_end}
{pstd}{cmd:   name(QB3, replace)}{p_end}
{phang}{cmd:. #delimit cr}{p_end}

{phang}* For this dataset, see Mardia {it:et al.} (1979, 2024){p_end}
{phang}{cmd:. use https://www.stata-journal.com/software/sj20-2/pr0046_1/mathsmarks, clear}{p_end}
{phang}{cmd:. rename * (marks*)}{p_end}
{phang}{cmd:. gen id = _n}{p_end}
{phang}{cmd:. reshape long marks, i(id) j(subject) string}{p_end}
{phang}{cmd:. myaxis subject2=subject, sort(median marks)}{p_end}

{phang}{cmd:. qplot marks, by(subject2, row(1) compact) ytitle(Mathematics marks)}{p_end}

{phang}{cmd:. pctilesets marks, over(subject2) min max p(25 50 75) saving(foo, replace)}{p_end}
{phang}{cmd:. gen where = 1.1 }{p_end}
{phang}{cmd:. clonevar origgvar=subject2}{p_end}
{phang}{cmd:. merge m:1 origgvar using foo}{p_end}

{phang}{cmd:. #delimit ;}{p_end}
{phang}{cmd:. qplot marks, by(subject2, row(1) compact legend(off) note(""))}{p_end}
{pstd}{cmd:   addplot(rspike p25 min where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike p75 max where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rbar p25 p75 where, barw(0.16) fcolor(none) pstyle(p2)}{p_end}
{pstd}{cmd:   || scatter p50 where, ms(Dh) msize(medlarge) pstyle(p2))}{p_end}
{pstd}{cmd:   ytitle(Mathematics marks)}{p_end}
{pstd}{cmd:   xla(0 0.25 "0.25" 0.5 "0.5" 0.75 "0.75" 1) xtitle(Fraction of data) name(QB4, replace);}{p_end}
{phang}{cmd:. #delimit cr}{p_end}


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

{phang}Mardia, K. V., J. T. Kent and J. M. Bibby. 1979. 
{it:Multivariate Analysis.} London: Academic Press. 

{phang}Mardia, K. V., J. T. Kent and C. C. Taylor. 2024. 
{it:Multivariate Analysis.} Hoboken, NJ: John Wiley. 


{title:Also see}

{p 4 4 2}help for {help summarize}

