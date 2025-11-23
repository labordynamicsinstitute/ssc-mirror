{smcl}
{* NJC 21nov2025}{...}

{cmd:help quantilesets}
{hline}

{title:Title}

{p 4 4 2}{bf:quantilesets} {hline 2} Quantile sets for selected
probability levels{p_end}


{title:Syntax}

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:quantilesets} {varlist} 
{ifin}
{cmd:,} 
{opt p:rob(numlist)}
[
{opt inclusive}
{opt m:ethod(name)} 
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:quantilesets} {varname} 
{ifin}
{cmd:,} {opt over(groupvar)} 
{opt p:rob(numlist)}
[
{opt m:ethod(name)} 
{cmdab:t:otal}
{opt saving(filespec)}
{it:list_options}
]


{title:Description}

{pstd}
{cmd:quantilesets} computes percentile or quantile sets.  It is a
wrapper for the Mata function {help mf_quantile:quantile()} added to
Stata 19.50 on 12 November 2025.  The help for {help mf_quantile:quantile()}
and the corresponding manual entry should be consulted for more detail. 

{pstd}
Typically the user will specify one or more probability levels between 0
and 1 inclusive using the required option {opt prob()}. 

{pstd}
There are two syntaxes. 

{p 8 8 2}
{cmd:quantilesets} {it:varlist} calculates results for one or more
variables {it:varlist}. This is called the {it:variables syntax}.  

{p 8 8 2}
{cmd:quantilesets} {it:varname}{cmd:,} {opt over(groupvar)} calculates
results for one variable {it:varname} for each distinct value of
{it:groupvar}. This is called the {it:groups syntax}.  

{pstd}
A quantile set consists of a temporary dataset consisting of some or
occasionally all of the following variables. 

{p 4 4 2}
* {cmd:varname} is a string variable holding the name or names of the
variable(s) being summarized. 

{p 4 4 2}
* {cmd:varlabel} is a string variable holding the variable label of each 
variable being summarized. If no variable label has been defined, the
value is instead the variable name. 

{p 4 4 2}
* (Groups syntax only) {cmd:origgvar} is a numeric or string variable 
as specified in the {cmd:over()} option.

{p 4 4 2}
* (Groups syntax only) {cmd:groupvar} is a string variable holding the
name of the group variable specified in the {cmd:over()} option. 

{p 4 4 2}
* (Groups syntax only) {cmd:gvarlabel} is a string variable holding the
variable label of the group variable {it:groupvar} specified in the
{cmd:over()} option. If no variable label has been defined, the value is
instead the variable name.

{p 4 4 2}
* (Groups syntax only) {cmd:group} is a numeric variable with value 
labels describing each distinct value of {it:groupvar}. Each such
variable has integer values 1 up and value labels derived from the
variable specified. 

{p 4 4 2}
* {cmd:n} is a numeric variable holding the number of observations used 
in the estimate. 

{p 4 4 2}
* One or more quantile variables named {cmd:q1}, {cmd:q2}, and so forth. 
Conventions are best explained by example. Suppose the specification was
{cmd:prob(0.25 0.5 0.75)}. Then there are three resulting quantile
variables named {cmd:q1}, {cmd:q2}, {cmd:q3} and they have variable
labels  {cmd:0.25 quantile}, {cmd:0.5 quantile}, {cmd:0.75 quantile}. 

{p 4 4 2}
* {cmd:method} is a string variable naming the estimation method used. 
The default method choice is {cmd:tukey}. 


{title:Remarks}

{it:Quantiles, percentiles, and various Stata commands}

{pstd}
As explained for example by Cox (2024), the term {it:quantile} has
acquired related but distinct meanings. One meaning refers to the values
of a variable sorted or ordered in magnitude, the order statistics,
especially when plotted, usually against the quantiles
of another variable or as estimated for a candidate fitted distribution.
This is the sense behind official commands {help quantile}, 
{help qqplot}, {help qnorm} and {help qchi}, and behind community-contributed
commands such as {cmd:qplot} (discussed below), {cmd:multqplot} (Cox
2012, 2019), and {cmd:qqplotg} (Cox 2024). The term {it:percentile} is
also occasionally used in this sense (for example, Cleveland 1985).

{pstd}
The related but distinct meaning foremost in {cmd:quantilesets} is that
of summary statistics (or correspondingly parameters) defined by the
fraction or probability of values being lower, and thus also by the
complementary fraction of values being higher. Such statistics must be
calculated, or such parameters must be estimated, using a rule or recipe
which variously yields either original data values or points between
them. The simplest example of such a recipe is that for the median, as 
given by the middlemost value if the number of values is odd and by the mean
of the two middlemost values (the comedians) if the number of values is even.
This recipe is explained to mathematical audiences as a convention and to less 
mathematical audiences as a rule. 

{pstd}
Much of the rationale for the Mata function {cmd:quantile()} and
thus for {cmd:quantilesets} is that several such rules or recipes exist,
which usually produce similar but not necessarily
identical results. Such varying methods are tied up with different
methods for calculating the corresponding cumulative probabilities, in a
graphical context often known as plotting positions, as quantiles are in
principle obtained by inverting the (cumulative) distribution function.
The documentation for {cmd:quantile()} flags Cunnane (1978) and Hyndman
and Fan (1996) as key references, but yet more approaches to quantile
estimation exist.  See for example Harrell and Davis (1982) (and
correspondingly {cmd:hdquantile} from SSC) and Ma, Genton and Parzen
(2021). 

{pstd} 
In official Stata commands for estimating particular quantiles include
{help pctile}, {help _pctile} and {help centile}. Other official
commands producing quantiles typically rest on one such command. See
also Ben Jann's {cmd:mm_quantile()} and related Mata functions from his
package {cmd:moremata} (SSC). 

{pstd} 
In practice the term {it:percentile} is typically used in this sense of
quantile, as a summary statistic or as an parameter estimate defined by
the percent of values lower. Usage has often morphed away from any
implication that there are 99 distinct percentiles for percents 1(1)99
(or 101 if the minimum and maximum are regarded by courtesy as the 0 and
100% percentiles). Thus many would feel no discomfort in regarding say
the 2.5% and 97.5% points as also being percentiles. For a menagerie of
related terms, from tertile onwards, see Cox (2016). To the list there
may be added pentile=quintile (5), decentile=decile (10),
hexadecile=suboctile (16), ventile=vigintile (20) and trentile (30). 

{pstd}
Yet another meaning of quantile is to refer to the bins, classes, or
intervals they delimit, as wheh the first quartile is the lowest quarter
of a distribution. 

{it:Use of quantilesets} 

{pstd}
{cmd:quantilesets} by default lists its results. Although saving to a
permanent dataset is optional, that is the intended key to many useful
applications. Either the quantile dataset is what is needed or it may be
combined using {help append} or {help merge} with other datasets for
further analysis. 

{pstd}
The approach is thus one of providing a building block that may be
useful directly or if combined with other building blocks.  Flexibility
is needed because so many different problems may be of interest, not
just comparison of quantiles for different variables, or of quantiles
for one variable for different groups, but also of quantiles for several
variables and several groups; and so forth. 

{pstd}
At first sight, a quantile set may seem repetitious.  With a little
experience, you will see that such repetition is often helpful when
combining such sets. In any case, you can always ignore what you do not
need. Similarly, you can use {help rename} and {help replace} as you
wish downstream of this command.

{pstd}
Graphical and other applications lie downstream of this command,
although some suggestions are included in the examples. Possibilities
include {help twoway rcap}, {help twoway rspike} and {help twoway rbar}
for plotting intervals between quantiles and {help twoway scatter} for
plotting particular quantiles. 

{pstd}
Helper commands include {cmd:myaxis} to sort on some criterion (Cox
2021) and {cmd:nicelabels} (Cox 2022) and {cmd:niceloglabels} (Cox 2018)
for automating axis labels. 

{pstd}
The approach to correlation confidence intervals of Cox (2008) is
broadly similar. See also {help pctilesets}, {help cisets}, 
{help momentsets} or {help lmomentsets} if installed. 

{it:Use with qplot} 

{pstd}
The command {cmd:qplot} is used in examples: see Cox (1999, 2005) and
search for updates. By default the horizontal axis is a probability
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

{it:Comparison with pctilesets} 

{pstd}
{cmd:quantilesets} differs from the author's {cmd:pctilesets} as 
follows. 

{pstd}
* As stated {cmd:quantilesets} is a wrapper for Mata function 
{cmd:quantile()} while {cmd:pctilesets} is a wrapper for 
{help summarize}. 

{pstd}
* {cmd:pctilesets} offers no choice of estimation method, while 
{cmd:quantilesets} offers several methods. That could be important if
you have a strong preference in principle for one method; or if you wish
to match a choice made in other software; or if you wish to compare
results obtained with different methods. Often differences will be
trivial, but not always, as with small datasets or those with gaps,
spikes or multiple modes. 

{pstd}
* {cmd:pctilesets} as a wrapper for {cmd:summarize} offers only selected 
percentiles, including the minimum and maximum. {cmd:quantilesets} 
allows any probability level between 0 and 1 (inclusive) to be 
specified. 

{pstd}
* {cmd:quantilesets} does not support weights, while {cmd:pctilesets} 
does support aweights and fweights. 


{title:Options}

{it:Option required with either syntax}

{phang}
{cmd:prob()} specifies one or more probability levels between 0 and 1 
(inclusive) for estimation of quantiles. For example, 
{cmd:prob(0.25 0.5 0.75)} specifies estimation of the quantiles often 
known as lower (first) quartile, median, and upper (third) quartie.  If
not presented in ascending order, levels will be sorted to ascending 
order any way. 

{it:Options allowed with either syntax}

{phang} 
{cmd:method()} requests use of a particular estimation method. The 
default method is {cmd:"tukey"}. See {help mf_quantile:quantile()} for
a list of allowed methods. See Hoaglin (1983, pp.44{c -}49) for much more detail
on the Tukey method hinging on use of (rank - 1/3) / (sample size + 1/3)
as probability level (and from a different perspective Tukey, 1977, pp.496{c -}497). 

{phang}
{it:list_options} are any options of {help list} other than {cmd:noobs} 
and {cmd:subvarname} that may be specified to tune listing of the 
quantile set. 

{phang}
{opt saving(filespec)} specifies saving the quantile set to a file as a 
Stata dataset. The suboption {cmd:, replace} must be specified to 
overwrite an existing dataset. 

{it:Option allowed with the variables syntax}

{phang}
{opt inclusive} may be specified if you wish to work with several
variables together. By default, calculations are only made with
observations that have non-missing values for all variables specified.
This option overrides that default selection: hence for several
variables which observations with non-missing values are used will be
determined separately for each variable. In other jargon, this option
triggers casewise deletion, not listwise deletion or complete case
analysis.  As a convenience for people familiar with that term, or with
other syntax used to this effect, {cmd:cw} and {cmd:allobs} are allowed
as synonyms. 

{it:Option required with the groups syntax}

{phang}
{opt over(groupvar)} must be specified to name the group variable.
Distinct groups of observations on {it:groupvar} will be used to produce
separate results for the main variable specified. 

{it:Option allowed with the groups syntax}

{phang}
{opt total} may be used with {opt over(groupvar)}. It specifies that in
addition to output for each group, output be added for all groups
combined.


{title:Examples}

{phang}{cmd:. sysuse auto, clear}{p_end}

{phang}{cmd:. quantilesets mpg, prob(0 0.25 0.5 0.75 1) over(foreign) saving(results, replace)}{p_end}

{phang}{cmd:. clonevar origgvar=foreign}{p_end}

{phang}{cmd:. merge m:1 origgvar using results}{p_end}

{phang}{cmd:. gen where = 1.1}{p_end}

{phang}{cmd:. #delimit ;}{p_end}
{phang}{cmd:. qplot mpg, ms(O) by(foreign, note("") legend(off))}{p_end}
{pstd}{cmd:   addplot(scatter q3 where, ms(Dh) msize(medlarge) pstyle(p2)}{p_end}
{pstd}{cmd:   xla(0 1 0.25 "0.25" 0.5 "0.5" 0.75 "0.75") xtitle(Fraction of data)}{p_end}
{pstd}{cmd:   || rbar q4 q2 where, fcolor(none) barw(0.12) pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike q2 q1 where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike q4 q5 where, pstyle(p2)) name(QB1, replace);}{p_end}
{phang}{cmd:. #delimit cr}{p_end}

{phang}{cmd:. replace where = 2.7}{p_end}

{phang}{cmd:. #delimit ;}{p_end}
{phang}{cmd:. qplot mpg, ms(O) by(foreign, note("") legend(off))}{p_end}
{pstd}{cmd:   xla(-2/2) xtitle(Standard normal deviate)}{p_end}
{pstd}{cmd:   addplot(scatter q3 where, ms(Dh) msize(medlarge) pstyle(p2)}{p_end}
{pstd}{cmd:   || rbar q4 q2 where, fcolor(none) barw(0.44) pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike q2 q1 where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike q4 q5 where, pstyle(p2)) trscale(invnormal(@))}{p_end}
{pstd}{cmd:   name(QB2, replace);}{p_end}
{phang}{cmd:. #delimit cr}{p_end}

{phang}{cmd:. replace where = 0.5}{p_end}

{phang}{cmd:. #delimit ;}{p_end}
{phang}{cmd:. qplot mpg, ms(O) by(foreign, note("") legend(off))}{p_end}
{pstd}{cmd:   xla(0 1 0.25 "0.25" 0.5 "0.5" 0.75 "0.75") xtitle(Fraction of data)}{p_end}
{pstd}{cmd:   addplot(rbar q2 q3 where, barw(0.5) fcolor(none) pstyle(p2)}{p_end}
{pstd}{cmd:   || rbar q4 q3 where, fcolor(none) barw(0.5) pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike q2 q1 where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike q4 q5 where, pstyle(p2) below)}{p_end}
{pstd}{cmd:   name(QB3, replace);}{p_end}
{phang}{cmd:. #delimit cr}{p_end}

{phang}* For this dataset, see Mardia {it:et al.} (1979, 2024){p_end}
{phang}{cmd:. use https://www.stata-journal.com/software/sj20-2/pr0046_1/mathsmarks, clear}{p_end}
{phang}{cmd:. rename * (marks*)}{p_end}
{phang}{cmd:. gen id = _n}{p_end}
{phang}{cmd:. reshape long marks, i(id) j(subject) string}{p_end}
{phang}{cmd:. myaxis subject2=subject, sort(median marks)}{p_end}

{phang}{cmd:. qplot marks, by(subject2, row(1) compact) ytitle(Mathematics marks)}{p_end}

{phang}{cmd:. quantilesets marks, over(subject2) prob(0 0.25 0.5 0.75 1) saving(results, replace)}{p_end}
{phang}{cmd:. gen where = 1.1 }{p_end}
{phang}{cmd:. clonevar origgvar=subject2}{p_end}
{phang}{cmd:. merge m:1 origgvar using results}{p_end}

{phang}{cmd:. #delimit ;}{p_end}
{phang}{cmd:. qplot marks, by(subject2, row(1) compact legend(off) note(""))}{p_end}
{pstd}{cmd:   addplot(rspike q2 q1 where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rspike q4 q5 where, pstyle(p2)}{p_end}
{pstd}{cmd:   || rbar q2 q4 where, barw(0.16) fcolor(none) pstyle(p2)}{p_end}
{pstd}{cmd:   || scatter q3 where, ms(Dh) msize(medlarge) pstyle(p2))}{p_end}
{pstd}{cmd:   ytitle(Mathematics marks)}{p_end}
{pstd}{cmd:   xla(0 0.25 "0.25" 0.5 "0.5" 0.75 "0.75" 1) xtitle(Fraction of data) name(QB4, replace);}{p_end}
{phang}{cmd:. #delimit cr}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:References}

{phang}Cleveland, W. S. 1985. 
{it:The Elements of Graphing Data.}
Monterey, CA: Wadsworth. 

{phang}Cox, N. J. 1999. 
Quantile plots, generalized.
{it:Stata Technical Bulletin} 51: 16{c -}18.        

{phang}Cox, N. J. 2005.      
Speaking Stata: The protean quantile plot. 
{it:Stata Journal} 5: 442{c -}460. 

{phang}Cox, N. J. 2008. 
Speaking Stata: Correlation with confidence, or Fisher's z revisited.
{it:Stata Journal} 8: 413{c -}439. 

{phang}Cox, N. J. 2012.
Speaking Stata: Axis practice, or what goes where on a graph.
{it:Stata Journal} 12: 549{c -}561.
       
{phang}Cox, N. J. 2016. 
Letter values as selected quantiles. 
{it:Stata Journal} 16: 1058{c -}1071. 

{phang}Cox, N. J. 2018. 
Speaking Stata: Logarithmic binning and labeling.
{it:Stata Journal} 18: 262{c -}286. 

{phang}Cox, N. J. 2019. 
Speaking Stata: Axis practice, or what goes where on a graph.
{it:Stata Journal} 19: 748{c -}751.

{phang}Cox, N. J. 2021. 
Speaking Stata: Ordering or ranking groups of observations.
{it:Stata Journal} 21: 818{c -}837. 

{phang}Cox, N. J. 2022.       
Speaking Stata: Automating axis labels: Nice numbers and transformed scales. 
{it:Stata Journal} 22: 975{c -}995.

{phang}Cox, N. J. 2024. 
Speaking Stata: Quantile-quantile plots, generalized.
{it:Stata Journal} 24: 514{c -}534.

{phang}Cunnane, C. 1978. 
Unbiased plotting positions{c -}a review.  
{it:Journal of Hydrology} 37: 205{c -}222.  
https://doi.org/10.1016/0022-1694(78)90017-3.

{phang}Harrell, F. E. and C. E. Davis. 1982. 
A new distribution-free quantile estimator. 
{it:Biometrika} 69: 635{c -}640.

{phang}Hoaglin, D. C. 1983. 
Letter values: A set of selected order statistics. 
In Hoaglin, D. C., F. Mosteller and J. W. Tukey (Eds)
{it:Understanding Robust and Exploratory Data Analysis}. 
New York: John Wiley, 33{c -}57. 

{phang}Hyndman, R. J. and Y. Fan. 1996. 
Sample quantiles in statistical packages.  
{it:American Statistician} 50: 361{c -}365.  
   
{phang}Ma, Y., M. G. Genton and E. Parzen. 2011. 
Asymptotic properties of sample quantiles of discrete distributions. 
{it:Annals of the Institute of Statistical Mathematics} 63: 227{c -}243.

{phang}Mardia, K. V., J. T. Kent and J. M. Bibby. 1979. 
{it:Multivariate Analysis.} London: Academic Press. 

{phang}Mardia, K. V., J. T. Kent and C. C. Taylor. 2024. 
{it:Multivariate Analysis.} Hoboken, NJ: John Wiley. 

{phang}Tukey, J. W. 1977. 
{it:Exploratory Data Analysis.} Reading, MA: Addison-Wesley. 



