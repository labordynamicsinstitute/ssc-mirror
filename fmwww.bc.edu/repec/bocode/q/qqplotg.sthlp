{smcl}
{* 11dec2022}{...}
{vieweralsosee "[R] Diagnostic plots" "mansection R Diagnosticplots"}{...}
{hline}
help for {hi:qqplotg}
{hline}

{title:Quantile-quantile plots, generalized to allow groups and plotting difference vs mean}

{phang2}{cmd:qqplotg}
{it:{help varname:varname1}}
{it:{help varname:varname2}}
{ifin}
[{cmd:,}
{opt flip}
{opt diff:vsmean}
{opt group(groupvar)} 
{opt gen:erate(stub)} 
{it:qqplot_options}]

{phang2}{cmd:qqplotg}
{it:{help varname:varname}}
{ifin}
{cmd:,} 
{opt group(groupvar)} 
[
{opt flip}
{opt diff:vsmean}
{opt generate(stub)} 
{it:qqplot_options}]


{title:Description}

{pstd}
{cmd:qqplotg} plots the quantiles of one distribution against the
quantiles of another distribution. Here quantiles means ordered values. 
It is a generalization of official command {helpb qqplot}. 
Names for this plot include quantile-quantile plot and q-q or Q-Q plot. 

{pstd} 
There are two syntaxes. In the first, emulating {help qqplot}, the two
distributions are given by the values of two variables, {it:varname1}
and {it:varname2}.

{pstd}
In the second, the distributions are given by the values of {it:varname}
for two distinct groups of {it:groupvar} named in the compulsory option
{cmd:group()}. The help for {cmd:qqplot} explains how to set up such a
plot, but a one-line command may be convenient.

{pstd}
By default a reference line of equality is shown to aid in identifying
any systematic or random differences between the two distributions. 

{pstd}
Optionally, the distributions may be plotted as differences between
corresponding quantiles versus their means. 

{pstd}
The two distributions may be of unequal size: if so, 
corresponding quantiles are calculated by interpolation. 


{title:Options} 

{p 4 4 2}{cmd:flip} swaps axes as compared with the default. This can be
especially helpful when a first pass shows that two groups would be better 
plotted the other way but you have no desire to recode {it:groupvar}. 

{p 4 4 2}{cmd:diffvsmean} plots differences between corresponding
quantiles versus their means as an alternative to plotting quantile
versus quantile. The reference becomes the horizontal line defining difference zero. 

{p 4 4 2}{cmd:generate(}{it:stub}{cmd:)} generates the quantiles as two new
variables, variously {it:stub}{cmd:1} and {it:stub}{cmd:2} OR 
{it:stub}{cmd:d} and {it:stub}{cmd:m} if the previous option is
specified.  

{p 4 4 2}{it:qqplot_options} are those options allowed with 
{help diagnostic_plots##options1:qqplot}.


{title:Remarks} 

{p 4 4 2}
Quantile plots have a long history, especially but not only in the form
of (1) plotting quantiles against rank order or cumulative probability
(equivalent to plotting versus the quantiles of a uniform distribution)
(2) plotting quantiles against equivalent quantiles of a normal or
Gaussian distribution (also known (e.g.) as a normal probability plot, normal
scores plot or probit plot). The terminology {it:quantiles} appears to
have been introduced in the late 1930s, so names may vary.  Modern
history starts with an outstanding paper by Wilk and Gnanadesikan
(1968). Chambers, Cleveland, Kleiner, and Tukey (1983) and Cleveland
(1993, 1994) remain authoritative and lucid. For Stata-related
discussions, see for example Cox (2005, 2007). 

{p 4 4 2}
It may often be sensible and sufficient to plot selected quantiles, 
especially if a dataset is very large. That idea is not supported here, 
but see for example Cox (2016). 


{title:Examples}

{p 4 8 2}{cmd:. sysuse auto, clear }{p_end}

{p 4 8 2}{cmd:. qqplotg mpg, group(foreign) title(miles per gallon) name(QQ1, replace)}{p_end}
{p 4 8 2}{cmd:. qqplotg mpg, group(foreign) flip title(miles per gallon) name(QQ2,replace)}{p_end}
{p 4 8 2}{cmd:. qqplotg mpg, group(foreign) flip diffvsmean title(miles per gallon) name(QQ3, replace)}{p_end}

{p 4 8 2}{cmd:. gen recmpg = 100/mpg }{p_end}
{p 4 8 2}{cmd:. qqplotg recmpg, group(foreign) diffvsmean title(gallons per 100 miles) name(QQ4, replace)}{p_end}
{p 4 8 2}{cmd:. gen lnmpg = ln(mpg)}{p_end}
{p 4 8 2}{cmd:. qqplotg recmpg, group(foreign) diffvsmean title(ln miles per gallon) name(QQ5, replace)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:Also see}

{p 4 4 2}Help for{break}
{help qplot} ({it:Stata Journal}) (if installed){break}
{help distplot} ({it:Stata Journal}) (if installed){break}
{help stripplot} (SSC) (if installed)


{title:References} 

{p 4 8 2}
Chambers, J. M., W. S. Cleveland, B. Kleiner, and P. A. Tukey. 1983.
{it:Graphical Methods for Data Analysis.}
Belmont, CA: Wadsworth.

{p 4 8 2}
Cleveland, W. S. 1993.
{it:Visualizing Data.}
Summit, NJ: Hobart Press.

{p 4 8 2}
Cleveland, W. S. 1994. 
{it:The Elements of Graphing Data.}
Summit, NJ: Hobart Press.

{p 4 8 2}
Cox, N. J. 
2005. Speaking Stata: The protean quantile plot. {it:Stata Journal} 5:
442{c -}460.

{p 4 8 2}
Cox, N. J. 
2007. Stata tip 47: Quantile{c -}quantile plots without programming.
{it:Stata Journal} 7: 275{c -}279.

{p 4 8 2}
Cox, N. J. 
2016. Speaking Stata: Letter values as selected quantiles. 
{it:Stata Journal} 16: 1058{c -}1071.

{p 4 8 2}
Wilk, M.B. and Gnanadesikan, R. 1968. 
Probability plotting methods for the analysis of data. {it:Biometrika} 55: 1{c -}17.
https://doi.org/10.2307/2334448


