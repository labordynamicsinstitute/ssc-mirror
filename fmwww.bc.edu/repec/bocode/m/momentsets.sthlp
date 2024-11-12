{smcl}
{* NJC 1nov2024}{...}

{cmd:help momentsets}
{hline}

{title:Title}

{p 4 4 2}{bf:momentsets} {hline 2} Moment-based measures collected as datasets{p_end}


{title:Syntax}

{p 4 8 2}{it:Variables syntax}

{p 8 11 2}
{cmd:momentsets} {varlist} 
{ifin}
[{it:{help weight}}]
[
{cmd:,} 
{opt inclusive} 
{opt m:ean}
{opt sd}
{opt v:ar}
{opt sk:ewness}
{opt ku:rtosis}
{opt saving(filespec)}
{it:list_options}
]

{p 4 8 2}{it:Groups syntax}

{p 8 11 2}
{cmd:momentsets} {varname} 
{ifin}
[{it:{help weight}}]
{cmd:,} {opt over(groupvar)} 
[
{cmdab:t:otal}
{opt m:ean}
{opt sd}
{opt v:ar}
{opt sk:ewness}
{opt ku:rtosis}
{opt saving(filespec)}
{it:list_options}
]

{p 4 4 2}
{opt aweight}s and {opt fweight}s are allowed. 


{title:Description}

{pstd}
{cmd:momentsets} computes moment-based measures and collects them into
datasets.  It is a wrapper for {help summarize}.  The help for
{cmd:summarize} and the corresponding manual entry  should be consulted
for more detail on statistical principles and procedures.  If interested
in more discussion of skewness and kurtosis in particular, see the 
references there and Cox (2010a) and its references. 

{pstd}
Typically the user will specify one or more of the options {opt mean},
{opt sd}, {opt var}, {opt skewness} or {opt kurtosis}.  

{pstd}
There are two syntaxes. 

{p 8 8 2}{cmd:momentsets} {it:varlist} calculates results
for one or more variables {it:varlist}. This is called the 
{it:variables syntax}.  

{p 8 8 2}{cmd:momentsets} {it:varname}{cmd:,} {opt over(groupvar)} 
calculates results for one variable {it:varname} for each distinct value of
{it:groupvar}. This is called the {it:groups syntax}.  

{pstd}
A moments-based measures set consists of a temporary dataset consisting of some 
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
* Any or all of {cmd:mean}, {cmd:sd}, {cmd:Var} [NB: not {cmd:var}],
{cmd:skewness}  and {cmd:kurtosis} holding results for the measure
concerned. 

{p 4 4 2}
* {cmd:weights} is a string variable appearing if (and only if) weights were 
specified as a record of such use. 


{title:Remarks}

{pstd}{cmd:momentsets} by default lists its results. Although saving to 
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

{pstd}Graphical and other applications lie downstream of this command,
although some suggestions are included in the examples. A plot of 
standard deviation or variance against mean could be used as a guide
to the structure of variability. A plot of kurtosis against skewness 
is a standard for considering distribution shape. 

{pstd}Helper commands include {cmd:myaxis} to sort on some criterion 
(Cox 2021b) and {cmd:nicelabels} (Cox 2022) and {cmd:niceloglabels} (Cox 2018) 
for automating axis labels. 

{pstd}The approach to correlation confidence intervals of Cox (2008) is 
broadly similar. See also {help cisets} or {help pctilesets} if installed. 


{title:Options}

{it:Option allowed with either syntax}

{phang}
{cmd:mean}, {cmd:sd}, {cmd:var}, {cmd:skewness} and {cmd:kurtosis} indicate 
that each measure is wanted in the results set. There is no default whereby 
a subset of those is automatically calculated. 

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
{phang}{cmd:. momentsets mpg, over(foreign) mean sd skewness kurtosis}{p_end}

{phang}* For this dataset, see Mardia {it:et al.} (1979, 2024){p_end}
{phang}{cmd:. use https://www.stata-journal.com/software/sj20-2/pr0046_1/mathsmarks, clear}{p_end}
{phang}{cmd:. momentsets *, mean sd skewness kurtosis}{p_end}

{phang}* For this dataset and some Stata uses: see Hosking and Wallis (1997) and Cox (2010b, 2021a){p_end}
{phang}{cmd:. u https://www.stata-journal.com/software/sj10-4/gr0046/windspeed.dta, clear}{p_end}
{phang}{cmd:. momentsets windspeed, over(place) mean sd skewness kurtosis saving(foo, replace)}{p_end}
{phang}{cmd:. u foo, clear}{p_end}
{phang}{cmd:. gen where = cond(mean < 51, 3, 9)}{p_end}
{phang}{cmd:. scatter sd mean, mla(group) mlabvpos(where) name(MO1, replace)}{p_end}
{phang}{cmd:. scatter kurt skew, mla(group) mlabvpos(where) name(MO2, replace)}{p_end}
{phang}{cmd:. graph combine MO1 MO2}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:References}

{phang}Cox, N. J. 2008. 
Speaking Stata: Correlation with confidence, or Fisher's z revisited.
{it:Stata Journal} 8: 413{c -}439. 

{phang}Cox, N. J. 2010a.
Speaking Stata: The limits of sample skewness and kurtosis.
{it:Stata Journal} 10: 482{c -}495.

{phang}Cox, N. J. 2010b.
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

{phang}Hosking, J. R. M. and J. R. Wallis. 1997. 
{it:Regional Frequency Analysis: An Approach Based on L-Moments.} 
Cambridge: Cambridge University Press. 

{phang}Mardia, K. V., J. T. Kent and J. M. Bibby. 1979. 
{it:Multivariate Analysis.} London: Academic Press. 

{phang}Mardia, K. V., J. T. Kent and C. C. Taylor. 2024. 
{it:Multivariate Analysis.} Hoboken, NJ: John Wiley. 


{title:Also see}

{p 4 4 2}help for {help summarize}

