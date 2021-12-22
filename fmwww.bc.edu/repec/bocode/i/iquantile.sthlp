{smcl}
{* 19 Jan 2009/31 Aug 2012/3 Dec 2021}{...}
{hline}
{cmd:help iquantile}
{hline}

{title:Interpolated quantiles}


{title:Syntax}

{p 8 18 2}
{cmd:iquantile} 
{it:varlist} 
{ifin} 
{weight} 
[ 
{cmd:,} 
{cmd:allobs} 
{cmd:by(}{it:byvarlist}{cmd:)}
{cmdab:f:ormat(}{it:format}{cmd:)}
{cmd:p(}{it:numlist}{cmd:)} 
{it:list_options} 
] 

{p 4 4 2}{opt fweight}s and {opt aweight}s are allowed.


{title:Description}

{p 4 4 2}
{cmd:iquantile} calculates and displays quantiles estimated by linear
interpolation in the mid-distribution function. The user may specify one
or more numeric variables, one or more grouping variables and one or
more quantiles. 

{p 4 8 2}
{cmd:iquantile} also displays the number of observations with non-missing values used in each calculation. 


{title:Remarks} 

{p 4 4 2}
By quantiles here are meant those summaries defined by the fact that
some percent of a batch of values is lower.  Thus the median (50%) and
the quartiles (25% and 75%) are examples. Most commands in Stata that
calculate such summaries select particular sample values or at most
average two sample values. That is often sufficient for the purpose
intended. {cmd:iquantile} offers an alternative, which is perhaps most
useful when the number of distinct values is small. For example,
although the variable in question may be measured coarsely, say on an
integer scale, and many ties may be observed, it may be hoped or
imagined that a property on a continuous scale lies beneath. Note that
{cmd:iquantile} performs no white magic, just elementary linear
interpolation. 

{p 4 4 2}
The cumulative probability is here defined as

	SUM counts of values below + (1/2) count of this value
	{hline 54}.
                       SUM counts of all values
		   
{p 4 4 2}
With terminology from Tukey (1977, 496-497), this could be called a
`split fraction below'. It is also a `ridit' as defined by Bross (1958):
see also Fleiss et al. (2003, 198-205), Beder and Heim (1990) or Flora (1988).  Yet again, it
is also the mid-distribution function of Parzen (1993, 3295) and the
grade function of Haberman (1996, 240-241). Parzen's term appears best for
the purposes of this command. The numerator is a `split count'. Using
this numerator, rather than 

	SUM counts of values below 

{p 4 4 2}
or 

	SUM counts of values below + count of this value, 
	
{p 4 4 2}
treats distributions symmetrically. For applications to plotting ordinal
categorical data, see Cox (2004). For yet more discussion and references, 
see the help for {cmd:distplot} as updated in Cox (2019) (or any later update). 

{p 4 4 2}
The technique used in {cmd:iquantile} is illustrated by a worked example using Mata
calculator-style. We first enter the data as values and frequencies: 

	: y = 2, 3, 4, 5

	: f = 2, 9, 8, 8

{p 4 4 2}
Then we can work out the cumulative frequencies:

	: runningsum(f)
        	1    2    3    4
	    +---------------------+
	  1 |   2   11   19   27  |
	    +---------------------+

{p 4 4 2}
Subtract half the frequencies and get the cumulative proportions,
symmetrically considered, i.e. the mid-distribution function: 

	: runningsum(f) :- f/2
	         1     2     3     4
	    +-------------------------+
	  1 |    1   6.5    15    23  |
	    +-------------------------+

	: (runningsum(f) :- f/2) / 27
	                 1             2             3             4
	    +---------------------------------------------------------+
	  1 |   .037037037   .2407407407   .5555555556   .8518518519  |
	    +---------------------------------------------------------+

	: cup = (runningsum(f) :- f/2) / 27

{p 4 4 2}
To get the median, we need to interpolate between the 2nd and 3rd
values of y. 

	: y[2] + (y[3] - y[2]) * (0.5 - cup[2]) / (cup[3] - cup[2])
	  3.823529412

{p 4 4 2}
{cmd:iquantile} uses {help list} to show results. 

{p 4 4 2} 
{cmd:iquantile} issues a warning if any quantile was calculated by
extrapolation, i.e. it lies in one or other tail of the distribution
beyond the observed mid-distribution function. Such results should be
treated with extreme caution. 

{p 4 4 2}
If the data consist of a single distinct value, then exactly that value
is always returned as a quantile. 

{p 4 4 2}
{cmd:iquantile} uses Mata for its innermost calculations.
Thus Stata 9 up is required. 


{title:Options} 

{p 4 8 2}
{cmd:allobs} specifies use of all possible observations when missing
values are present. Suppose you ask for results for two variables 
{cmd:x y} and there are missing values in either variable or in both. Then by
default {cmd:iquantile} works only with observations with non-missing
values on both variables. The purpose of {cmd:allobs} is to override
this default and to insist on using all observations with non-missing
values, so ignoring missing values separately for each variable
specified. 

{p 4 8 2}
{cmd:by()} specifies that calculations are to be carried out separately
for the distinct groups defined by {it:byvarlist}. The variable(s) in
{it:byvarlist} may be numeric or string. 

{p 4 8 2}
{cmd:format()} specifies a numeric format to be used to display the
quantiles. This option has no lasting effect. 

{p 4 8 2}
{cmd:p()} specifies a {help numlist} of integers betweem 1 and 99 to
indicate the {it:p}% quantiles. If {cmd:p()} is not specified, it
defaults to 50, i.e. the 50% point or median is calculated.
{cmd:p(25(25)75)} specifies the median and quartiles. 

{p 4 8 2}
{it:list_options} are options of {help list} other than {cmd:noobs} and
{cmd:subvarname}. They may be specified to tune the display of quantiles. 


{title:Examples}

{p 4 8 2}{cmd:. sysuse auto, clear} 

{p 4 8 2}{cmd:. iquantile mpg}{p_end}
{p 4 8 2}{cmd:. iquantile mpg, p(25 50 70)}{p_end}
{p 4 8 2}{cmd:. iquantile mpg, p(25 50 70) format(%2.1f)}{p_end}
{p 4 8 2}{cmd:. iquantile mpg, p(25 50 70) format(%2.1f) by(rep78)}{p_end}
{p 4 8 2}{cmd:. iquantile mpg weight price}

{p 4 8 2}{cmd:. iquantile mpg rep78, by(foreign)}{p_end}
{p 4 8 2}{cmd:. iquantile mpg rep78, allobs by(foreign)}


{title:Saved results} 

{p 4 4 2}
Saved results are best explained by example. After {cmd:iquantile mpg},
saved results include {cmd:r(mpg_50_1)} and {cmd:r(mpg_50_1_epolate)}.
The elements of the name for both are first, the variable name (if
necessary, abbreviated to 16 characters); second, the percent defining
the quantile; third, the number of the group in question in the
observations processed (here, the first of one). The extra flag
{cmd:epolate} indicates whether extrapolation was needed (1 for true, 0
for false).

{p 4 4 2}
In addition, the number of non-missing values is saved as {cmd:r(n_1)}
upwards by default, depending on whether there is just one group or there are
more groups; and as something like {cmd:r(n_mpg_1)} upwards if the
{cmd:allobs} option is specified (that is, the number of non-missing
values is saved for each variable as well as each group specified).  


{title:Author} 

{p 4 4 2}Nicholas J. Cox, Durham University, UK{break} 
n.j.cox@durham.ac.uk


{title:Acknowledgments} 

{p 4 8 2}This command grew out of a thread on Statalist started by
Taggert J. Brooks. See
{browse "http://www.stata.com/statalist/archive/2009-01/msg00652.html":http://www.stata.com/statalist/archive/2009-01/msg00652.html} 

{p 4 8 2}
Cees van der Eijk asked how the command handles observations with missing values and thereby prompted the addition of the {cmd:allobs} option and of 
display of the number of observations used. Thanks to Cees for
wide-ranging discussion. 


{title:References}

{p 4 8 2}Beder, J. H. and R. C. Heim. 
1990. On the use of ridit analysis. {it:Psychometrika} 55: 603{c -}616.

{p 4 8 2}Bross, I. D. J. 1958. How to use ridit analysis. {it:Biometrics}
14: 38{c -}58.

{p 4 8 2}Cox, N. J. 2004. Speaking Stata: Graphing categorical and
compositional data. {it:Stata Journal} 4(2): 190{c -}215. 
See Section 5. 
{browse "http://www.stata-journal.com/sjpdf.html?articlenum=gr0004":http://www.stata-journal.com/sjpdf.html?articlenum=gr0004}

{p 4 8 2}Cox, N. J. 2019. Software update: Distribution function plots. 
{it:Stata Journal} 19(1): 260.  

{p 4 8 2}Fleiss, J. L., B. Levin, and M. C. Paik. 2003. 
{it:Statistical Methods for Rates and Proportions}.
Hoboken, NJ: Wiley. 

{p 4 8 2}Flora, J. D. 1988. Ridit analysis. In 
{it:Encyclopedia of Statistical Sciences},
ed. S. Kotz and N. L. Johnson, (8) 136{c -}139.
New York: Wiley. 

{p 4 8 2}Haberman, S. J. 1996. 
{it:Advanced Statistics Volume I: Description of Populations}.
New York: Springer. 

{p 4 8 2}Parzen, E. 1993. Change {it:PP} plot and continuous sample quantile 
function. {it:Communications in Statistics {c -}Theory and Methods} 
22: 3287{c -}3304.

{p 4 4 2}Tukey, J. W. 1977. {it:Exploratory Data Analysis}.
Reading, MA: Addison-Wesley. 


{title:Also see}

{p 4 13 2}help for {help summarize}, {help centile}, {help pctile},
{help tabstat}, {help distplot} (if installed), {help hdquantile} (if installed) 

