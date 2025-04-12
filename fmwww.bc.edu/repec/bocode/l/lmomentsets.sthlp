{smcl}
{* NJC 10apr2025}{...}

{cmd:help lmomentsets}
{hline}

{title:Title}

{p 4 4 2}{bf:lmomentsets} {hline 2} L-moment-based measures collected as datasets{p_end}


{title:Syntax}

{phang}{it:Variables syntax}

{p 8 11 2}
{cmd:lmomentsets} {varlist} 
{ifin}
[
{cmd:,} 
{opt inclusive} 
{opt lmax(#)}
{opt saving(filespec)}
{it:list_options}
]

{phang}{it:Groups syntax}

{p 8 11 2}
{cmd:lmomentsets} {varname} 
{ifin}
{cmd:,} {opt over(groupvar)} 
[
{cmdab:t:otal}
{opt lmax(#)}
{opt saving(filespec)}
{it:list_options}
]


{title:Description}

{pstd}
{cmd:lmomentsets} computes L-moment-based measures and collects them into
datasets.  Compare {help lmoments} which is separate.          

{pstd}
There are two syntaxes. 

{p 8 8 2}{cmd:lmomentsets} {it:varlist} calculates results
for one or more variables {it:varlist}. This is called the 
{it:variables syntax}.  

{p 8 8 2}{cmd:lmomentsets} {it:varname}{cmd:,} {opt over(groupvar)} 
calculates results for one variable {it:varname} for each distinct value of
{it:groupvar}. This is called the {it:groups syntax}.  

{pstd}
An L-moments-based measures set consists of a temporary dataset consisting of some 
or occasionally all of the following variables. 

{p 4 4 2}
* {cmd:varname} is a string variable holding the name or names of the
variable(s) being summarized. 

{p 4 4 2}
* {cmd:varlabel} is a string variable holding the variable label of each
variable being summarized. If no variable label has been defined, 
its value is instead the variable name. 

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
* Any or all of {cmd:l_1} upward, {cmd:t}, {cmd:t_3} upward. The number 
of such variables is determined by the {cmd:lmax()} option, which 
defaults to 4. Thus by default the variables produced are L-moments 1 2 3 4, 
{cmd:t} (= {cmd:l_2/l_1}), 
{cmd:t_3} (= {cmd:l_3/l_2}), 
{cmd:t_4} (= {cmd:l_4/l_2}). 


{title:Remarks}

{title:{it:Mainly motivational}} 

{pstd}Definitions here are by way of example and phrased using slightly 
idiosyncratic notation, as conventional subscripts, summation and integral 
signs are not possible in a help file. 

{pstd}Here A[], following Whittle (1970, 1992, 2000), denotes averaging 
and {bind:C[n, k]} ("n choose k"), following (e.g.) Hamming (1985) or Allenby 
and Slomson (2011), denotes the binomial coefficient or choice number 
{bind:n! / (n - k)! k!}. {bind:C[n, k]} corresponds to the Stata or Mata function 
{cmd:comb(n, k)}. As usual k! is k factorial, namely the product
{bind:k*(k-1)*...*2*1}. 

{pstd}Use of upper case L or lower case l for L-moments is a little
capricious, but may imply emphasis on general definition or specific
calculation from data respectively. 

{pstd}Order statistics x(j:k) from a subsample of size k from a variable 
x are just data values ordered such that
 
{pstd}x(1:k) <= x(2:k) <= ... <= x(k-1:k) <= x(k:k). 

{pstd}To give some flavour of L-moments, we consider three takes. _1
for example indicates that subscript 1 would be shown whenever possible. 

{pstd}{it:Take 1}

{pstd}The first L-moment L_1 is just the usual mean or average as a measure of 
level or location, in this notation L_1 = A[x(1:1)] where the average is taken 
over all C[n, 1] = n subsamples of size 1. 

{pstd}The second L-moment L_2 is half the average difference between the 
larger and smaller order statistics over subsamples of size 2, so half
that average difference over C[n, 2] such subsamples, or 
{bind:(1/2) A[x(2:2) - x(1:2)]}. The second moment is, apart from  halving, the 
measure often known as Gini's mean difference, which however predates Gini. 
It is a measure of spread or scale.

{pstd}The third L-moment L_3 is based on largest, middle, and smallest order 
statistics in subsamples of size 3 and is 
{bind:(1/3) A[x(3:3) - 2x(2:3) + x(1:3)]}. 
The averaging is over {bind:C[n, 3]} such subsamples. 
It is a measure of asymmetry or skewness. 

{pstd}As we proceed, verbal paraphrases become more awkward and no
easier to think about than direct notation. The fourth L-moment L_4 is 
based on the order statistics of subsamples of size 4: there are
{bind:C[n, 4]} such subsamples. It is 
{bind:(1/4) A[x(4:4) - 3x(3:4) + 3x(2:4) - x(1:4)]} and is a measure of tail 
weight or kurtosis. 

{pstd}L-moments all have the same units of measurement and dimensions as the 
original data. As already mentioned, it is often convenient to calculate 
dimensionless versions, most importantly L_2/L_1 =: t, L_3/L_2 =: t_3,
L_4/L_2 =: t_4. 

{pstd}The first four L-moments are the most useful and many projects use no 
others. But L-moments of any order k may be defined as 

{pstd}(1) linear combinations of the order statistics of a subsample of 
size k, with coefficients extending the pattern 

{space 4}1 
{space 4}1 -1 
{space 4}1 -2 1 
{space 4}1 -3 3 1 

{pstd}{c -} namely binomial coefficients alternately assigned positive and negative signs {c -}

{pstd}(2) averaged over all C[n, k] subsamples from a sample of size n and 

{pstd}(3) multiplied by prefactor (1/k). 

{pstd}This approach may help to give much flavour. So the L-moments are 
a series of measures of a sample, giving in turn indicators of level, 
spread, asymmetry, tail weight and yet further properties. However, it is 
utterly hopeless as a practical recipe for calculation, as the number of 
combinations to deal with explodes with even modest n and r. 

{pstd}{it:Take 2}

{pstd}A more abstract but still helpful view is that each L-moment is a 
weighted average over the quantile function x = Q(p) for probability p 
from 0 to 1. The weighting functions are W[p, k]

{pstd}1 =: W[p, 1]

{pstd}2p - 1 =: W[p, 2]

{pstd}6p^2 - 6p + 1 =: W[p, 3]

{pstd}20p^3 - 30p^2 + 12p - 1 =: W[p, 4]

{pstd}so that the kth L-moment is A[ Q(p) W[p, k] ]. 

{pstd}{it:Take 3}

{pstd}Take 2 has a practical equivalent in terms of each L-moment being 
calculated as a L-statistic, a weighted linear combination of the order 
statistics. Without delving into the precise recipe, each L-moment is an
L-statistic with form 

{pstd}L_k = A [ weight(k, j, n) x(j:n) ]

{pstd}where the weights depend on the L-moment being calculated, the
ranks j and the sample size n. 

{pstd}{cmd:lmoments_explain.do}, distributed with this package, contains
code for three explanatory graphs: (1) motivating the idea that
subsamples of size 1, 2, 3 and 4 contain information on level, spread,
(a)symmetry and tail weight; (2) showing weight functions continuous in
probability p; (3) showing weights used in calculating from a sample of
size 19, a size both small enough and large enough to make the idea
concrete. 

{title:{it:Comments on using the command}} 

{pstd}{cmd:lmomentsets} by default lists its results. Although saving to 
a permanent dataset is optional, that is the intended key to many  
useful applications. Either the results dataset is what 
is needed or it may be combined using {help append} or {help merge} 
with other such sets for further analysis. 

{pstd}The approach is thus one of providing a building block that may 
be useful directly or if combined with other building blocks. 
Flexibility is needed because so many different problems may be of interest, 
not just comparison of measures for different variables, or of measures 
for one variable for different groups, but also of measures for several 
variables and several groups; and so forth. 

{pstd}At first sight, such a results set may seem repetitious. 
With a little experience, you will see that such repetition is often 
helpful when combining such sets. In any case, you can always ignore what you 
do not need. Similarly, you can use {help rename} and {help replace}
as you wish downstream of this command.

{pstd}The {cmd:l_*} and {cmd:t_*} variables created by this command do not 
have defined variable labels. As always, you may wish to define your 
own variable labels, particularly for graphical purposes. Note that 
italic font and literal subscripts are available using {help smcl}. 

{pstd}Graphical and other applications lie downstream of this command,
although some suggestions are included in the examples. A plot of 
l_2 against l_1 (mean) could be used as a guide
to the structure of variability. A plot of t_4 against t_3 
is a standard for considering distribution shape. 

{pstd}Helper commands include {cmd:myaxis} to sort on some criterion 
(Cox 2021b) and {cmd:nicelabels} (Cox 2022) and {cmd:niceloglabels} (Cox 2018) 
for automating axis labels. 

{pstd}The approach to correlation confidence intervals of Cox (2008) is 
broadly similar. See also {help cisets}, {help momentsets} or {help pctilesets} if installed. 

{title:{it:Leads to the literature}} 

{pstd}Hosking (1990) is the definitive paper. Although Hosking and Wallis (1997) is largely 
focused on hydrological applications, it contains much material applicable very broadly. 
Hosking (1992), Royston (1992), Vogel and Fennessey (1993) and Wang (1996) are short and/or 
non-technical papers that in various ways explain why you should find L-moments interesting and useful. 


{title:Options}

{it:Options allowed with either syntax}

{phang}
{cmd:lmax()} indicates the highest L-moment to be calculated. The default is 4.

{phang}
{it:list_options} are any options of {help list} other than {cmd:noobs} that 
may be specified to tune listing of the results set. 

{phang}
{opt saving(filespec)} specifies saving the results set to a file as a 
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
{phang}{cmd:. lmomentsets mpg, over(foreign)}{p_end}

{phang}* For this dataset, see Mardia {it:et al.} (1979, 2024){p_end}
{phang}{cmd:. use https://www.stata-journal.com/software/sj20-2/pr0046_1/mathsmarks, clear}{p_end}
{phang}{cmd:. lmomentsets *}{p_end}

{phang}* For this dataset and some Stata uses: see Hosking and Wallis (1997) and Cox (2010, 2021a){p_end}
{phang}{cmd:. use https://www.stata-journal.com/software/sj10-4/gr0046/windspeed.dta, clear}{p_end}
{phang}{cmd:. lmomentsets windspeed, over(place) saving(foo, replace)}{p_end}
{phang}{cmd:. use foo, clear}{p_end}
{phang}{cmd:. gen where = cond(l_1 < 51, 3, 9)}{p_end}
{phang}{cmd:. scatter l_2 l_1, mla(group) mlabvpos(where) name(LMO1, replace)}{p_end}
{phang}{cmd:. replace where = cond(t_3 < 0.25, 3, 9)}{p_end}
{phang}{cmd:. scatter t_4 t_3, mla(group) mlabvpos(where) name(LMO2, replace)}{p_end}
{phang}{cmd:. graph combine LMO1 LMO2}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:References}

{phang}
Allenby, R. B. J. T., and A. Slomson. 2011.
{it:How to Count: An Introduction to Combinatorics}. 
Boca Raton, FL: CRC Press.

{phang}Cox, N. J. 2008. 
Speaking Stata: Correlation with confidence, or Fisher's z revisited.
{it:Stata Journal} 8: 413{c -}439. 

{phang}Cox, N. J. 2010.
Speaking Stata: Graphing subsets. 
{it:Stata Journal} 10: 670{c -}681.

{phang}Cox, N. J. 2018. 
Speaking Stata: Logarithmic binning and labeling.
{it:Stata Journal} 18: 262{c -}286. 

{phang}Cox, N. J. 2021a. 
Speaking Stata: Front-and-back plots to ease spaghetti and paella problems. 
{it:Stata Journal} 21: 539{c -}554.

{phang}Cox, N. J. 2021b. 
Speaking Stata: Ordering or ranking groups of observations.
{it:Stata Journal} 21: 818{c -}837. 

{phang}Cox, N. J. 2022.       
Speaking Stata: Automating axis labels: Nice numbers and transformed scales. 
{it:Stata Journal} 22: 975{c -}995. 

{phang}
Hamming, R. W. 1985.
{it:Methods of Mathematics Applied to Calculus, Probability, and Statistics}.
Englewood Cliffs, NJ: Prentice-Hall.

{phang}Hosking, J. R. M. 1990. L-moments: Analysis and estimation of
distributions using linear combinations of order statistics.
{it:Journal of the Royal Statistical Society} Series B 52: 105{c -}124.

{phang}Hosking, J. R. M. 1992. Moments or L-moments? 
An example comparing two measures of distributional shape.
{it:American Statistician} 46: 186{c -}189. 

{phang}Hosking, J. R. M. 2006.  
On the characterization of distributions by their L-moments. 
{it:Journal of Statistical Planning and Inference}
136: 193{c -}198.  

{phang}Hosking, J. R. M. and N. Balakrishnan. 2015. 
A uniqueness result for L-estimators, with applications to L-moments. 
{it:Statistical Methodology} 24: 69{c -}80. 

{phang}Hosking, J. R. M. and J. R. Wallis. 1997. 
{it:Regional Frequency Analysis: An Approach Based on L-Moments.} 
Cambridge: Cambridge University Press. 

{phang}Jones, M. C. 2004. 
On some expressions for variance, covariance, skewness and L-moments. 
{it:Journal of Statistical Planning and Inference} 
126: 97{c -}106. 

{phang}Mardia, K. V., J. T. Kent and J. M. Bibby. 1979. 
{it:Multivariate Analysis.} London: Academic Press. 

{phang}Mardia, K. V., J. T. Kent and C. C. Taylor. 2024. 
{it:Multivariate Analysis.} Hoboken, NJ: John Wiley. 

{phang}Royston, P. 1992. 
Which measures of skewness and kurtosis are best? 
{it:Statistics in Medicine} 11: 333{c -}343. 

{phang}Serfling, R. and P. Xiao. 2007. 
A contribution to multivariate L-moments: L-comoment matrices. 
{it:Journal of Multivariate Analysis} 98: 1765{c -}1781.  

{phang}Vogel, R. M. and N. M. Fennessey. 1993. 
L-moment diagrams should replace product moment diagrams. 
{it:Water Resources Research} 29: 1745{c -}1752. 
 
{phang}Vogel, R. M., S. M. Papalexiou, J. R. Lamontagne and F. C. Dolan. 
2024. When heavy tails disrupt statistical inference. 
{it:The American Statistician} 1{c -}15. 
{browse "https://doi.org/10.1080/00031305.2024.2402898":https://doi.org/10.1080/00031305.2024.2402898}

{phang}Wang, Q. J. 1996. Direct sample estimators of L-moments. 
{it:Water Resources Research} 32: 2617{c -}2619. 

{phang}
Whittle, P. 1970. 
{it:Probability.} Harmondsworth: Penguin. 

{phang}
Whittle, P. 1992. 
{it:Probability via Expectation.} 3rd ed. 
New York: Springer. 

{phang}
Whittle, P. 2000.
{it:Probability via Expectation}. 4th ed.
New York: Springer. 


{title:Also see}

{p 4 4 2}help for {help lmoments}           


