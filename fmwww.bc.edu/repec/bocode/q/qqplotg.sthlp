{smcl}
{* 11dec2022/12dec2022/18dec2023}{...}
{vieweralsosee "[R] Diagnostic plots" "mansection R Diagnosticplots"}{...}
{hline}
help for {hi:qqplotg}
{hline}

{title:Quantile-quantile plots, generalized}

{phang2}{cmd:qqplotg}
{it:{help varname:varname1}}
{it:{help varname:varname2}}
{ifin}
{cmd:,}
[
{opt a(str)}
{opt flip}
{opt trans:form(specification)}
{c -(}
{opt dvm}
{c |} 
{opt dvp} 
{c )-} 
{opt gen:erate(stub)}
{opt by(byvar)}
{opt miss:ing}
{opt lpolyopts(options)}  
{opt rlopts(options)} 
{it:graph_options}]

{phang2}{cmd:qqplotg}
{it:{help varname:varname}}
{ifin}
{cmd:,} 
{opt over(groupvar)} 
[
{opt a(str)}
{opt flip}
{opt trans:form(specification)}
{c -(}
{opt dvm}
{c |}
{opt dvp}
{c )-}  
{opt generate(stub)}
{opt by(byvar)}
{opt miss:ing}
{opt lpolyopts(options)} 
{opt rlopts(options)} 
{it:graph_options}]


{title:Description}

{pstd}
{cmd:qqplotg} plots the quantiles of one distribution against the
quantiles of another distribution. Here quantiles means ordered values.
It is a generalization of official command {helpb qqplot}.  Names for
this plot include quantile-quantile plot and q-q or Q-Q plot. 

{pstd}
The two distributions may be of unequal size: if so, corresponding
quantiles are calculated by interpolation. 

{pstd} 
There are two main syntaxes. In the first, emulating {help qqplot}, the
two distributions are given by the values of two variables,
{it:varname1} and {it:varname2}.

{pstd}
In the second, the distributions are given by the values of {it:varname}
for two distinct groups of {it:groupvar} named in the compulsory option
{cmd:over()}. The help for {cmd:qqplot} explains how to set up such a
plot, but a one-line command may be convenient. 

{pstd}
By default a reference line of equality is shown to aid in identifying
any systematic or random differences between the two distributions. 

{pstd}
Optionally, the distributions may be plotted as differences between
corresponding quantiles versus their means; or as differences between
corresponding quantiles versus fraction of the data (a.k.a. cumulative
probability or plotting position). In each case, a smooth will be added
using {help twoway lpoly} of the difference over its support. 

{pstd}
Transformations on the fly are supported. It is suggested as essential
practice to supply an informative note or title (unless an informative
text caption is given otherwise); and as good practice to use axis
labels on the original scale.  See {help nicelabels} and {help mylabels}
(Cox 2022) for support. 


{title:Options} 

{p 4 4 2}{cmd:over()} is a required option whenever you need to specify
a group variable that takes on precisely two distinct numeric or string
values. 

{p 8 8 2}{cmd:group()} is allowed as a synonym. 

{p 4 4 2}{cmd:a()} specifies {it:a} within the plotting position recipe
({it:i} - {it:a}) / ({it:n} + 1 - 2{it:a}) for distinct or unique ranks
{it:i} running over the integers from 1 to sample size {it:n}. The
default is 0.5, yielding ({it:i} - 0.5) / {it:n}. Alternatives should
specify a number such as {cmd:a(0)} or a numeric expression such as
{cmd:a(1/3)}. For more detail, see Cox (2014).  

{p 4 4 2}{cmd:flip} swaps axes as compared with the default. This can be
especially helpful when a first pass shows that two groups would be
better plotted the other way but you have no desire to recode
{it:groupvar}. 

{p 4 4 2}{cmd:transform()} specifies a transformation to apply to what
is plotted on both axes. There are two syntaxes. 1. A bare function name
such as {cmd:ln} or {cmd:sqrt} will be applied directly. Do not supply
parentheses {cmd:()}. 2. An expression mentioning {cmd:@} will be
applied with {cmd:@} replaced on the fly with the appropriate variable
name. Hence {cmd:@^(1/3)} specifies cube roots of zero or positive
values and {cmd:1/@} specifies reciprocals.  If {cmd:dvm} or {cmd:dvp}
is also specified, then transforms are calculated first.

{p 8 8 2}A warning will be displayed if the transform creates missing
values.  For example, taking logarithms of zero or negative values would
do that.

{p 4 4 2}{cmd:dvm} plots differences between corresponding quantiles
versus their means as an alternative to plotting quantile versus
quantile. The reference becomes the horizontal line defining difference
zero. 

{p 8 8 2}{cmd:diffvsmean} is allowed as a synonym. 

{p 4 4 2}{cmd:dvp} plots differences between corresponding quantiles
versus their plotting positions as an alternative to plotting quantile
versus quantile. The reference becomes the horizontal line defining
difference zero. 

{p 8 8 2}{cmd:dvm} and {cmd:dvp} may not be specified together. 

{p 4 4 2}{cmd:generate(}{it:stub}{cmd:)} generates the quantiles as two
new variables, variously {it:stub}{cmd:1} and {it:stub}{cmd:2}; OR
{it:stub}{cmd:d} and {it:stub}{cmd:m} if {cmd:dvm} is also specified; OR
{it:stub}{cmd:d} and {it:stub}{cmd:p} if {cmd:dvp} is also specified. 

{p 4 4 2}{opt by(byvar, byopts)} is supported to produce separate plots
for the distinct values of a variable {it:byvar}.  By default
{it:byopts} includes {cmd:legend(off) note("")}. Missing values of
{it:byvar} will be ignored unless the further option {cmd:missing} is
specified.

{p 4 4 2}{cmd:lpolyopts()} are options of {help twoway lpoly} that tune
the smooth that appears with options {cmd:dvm} or {cmd:dvp}. Note that
{cmd:lpolyopts(nodraw)} suppresses display of such graphs. 

{p 4 4 2}{cmd:rlopts()} may be used to tune the rendering of reference lines. 

{p 4 4 2}{it:graph_options} are other options allowed with 
{help scatter}. Specifically {cmd:aspect(1)} may be a good idea with
quantile-quantile plots. 


{title:Remarks} 

{p 4 4 2}
Quantile plots have a long history, especially but not only in the form
of (1) plotting quantiles against rank order or cumulative probability
(equivalent to plotting versus the quantiles of a uniform distribution)
(2) plotting quantiles against equivalent quantiles of a normal or
Gaussian distribution (also known (e.g.) as a normal probability plot,
normal scores plot, normal plot, probit plot, or fractile diagram). The terminology
{it:quantiles} appears to have been introduced in the late 1930s, so
names may vary.  Modern history starts with an outstanding paper by Wilk
and Gnanadesikan (1968). Chambers, Cleveland, Kleiner, and Tukey (1983)
and Cleveland (1993, 1994) remain authoritative and lucid. For
Stata-related discussions, see for example Cox (2005, 2007). The help
for {help qplot} includes much more discussion.

{p 4 4 2}
Plots such as those from the {cmd:dvm} and {cmd:dvp} options are 
known as delta plots in psychology (De Jong {it:et al.} 1994; 
Speckman {it:et al.} 2008.)

{p 4 4 2}
It may often be sensible and sufficient to plot selected quantiles,
especially if a dataset is very large. That idea is not supported here,
but see for example Cox (2016).

{p 4 4 2}
{cmd:qqplotg} does not explicitly support comparison with expected
quantiles from some reference distribution, but the examples include
calculations for a normal quantile plot and associated plots. The
procedure boils down to calculating plotting positions, possibly
obtaining parameter estimates, and pushing plotting positions through
code for a quantile function. For more, see Cox (2007, 2014). 


{title:Examples}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}

{p 4 8 2}{cmd:. nicelabels mpg, local(la) tight}{p_end}
{p 4 8 2}{cmd:. qqplotg mpg, over(foreign) flip xla(`la') yla(`la') subtitle(raw scale) name(QQG1, replace)}{p_end}

{p 4 8 2}{cmd:. mylabels `la', myscale(@^(1/3)) local(la2)}{p_end}
{p 4 8 2}{cmd:. qqplotg mpg, over(foreign) flip transform(@^(1/3)) xla(`la2') yla(`la2') subtitle(cube root scale) name(QQG2, replace)}{p_end}

{p 4 8 2}{cmd:. mylabels `la', myscale(ln(@)) local(la3)}{p_end}
{p 4 8 2}{cmd:. qqplotg mpg, over(foreign) flip transform(ln) xla(`la3') yla(`la3') subtitle(log scale) name(QQG3, replace)}{p_end}

{p 4 8 2}{cmd:. mylabels `la', myscale(1/@) local(la4)}{p_end}
{p 4 8 2}{cmd:. qqplotg mpg, over(foreign) flip transform(1/@) xla(`la4') yla(`la4') ysc(reverse) xsc(reverse) subtitle(reciprocal scale) name(QQG4, replace)}{p_end}

{p 4 8 2}{cmd:. graph combine QQG1 QQG2 QQG3 QQG4, name(QQG5, replace)}{p_end}

{p 4 8 2}{cmd:. * using egen is over the top here, but extends easily to groups}{p_end}
{p 4 8 2}{cmd:. egen rank = rank(mpg), unique}{p_end}
{p 4 8 2}{cmd:. egen n = count(mpg)}{p_end}
{p 4 8 2}{cmd:. su mpg}{p_end}
{p 4 8 2}{cmd:. gen normal = r(mean) + r(sd) * invnormal((rank - 0.5)/n)}{p_end}
{p 4 8 2}{cmd:. label var normal "Expected normal quantiles"}{p_end}

{p 4 8 2}{cmd:. qqplotg mpg normal, name(QQG6, replace)}{p_end}

{p 4 8 2}{cmd:. qqplotg mpg normal, dvp lpolyopts(kernel(biweight) bw(0.1)) name(QQG7, replace)}{p_end}

{p 4 8 2}{cmd:. use ozone, clear}{p_end}

{p 4 8 2}{cmd:. qqplotg stamford yonkers, xla(0(50)150) yla(0(50)250) name(QQG8, replace)}{p_end}

{p 4 8 2}{cmd:. mylabels 10 20 50 100 200, myscale(ln(@)) local(la)}{p_end}

{p 4 8 2}{cmd:. qqplotg stamford yonkers, xla(`la') yla(`la') transform(ln) subtitle(log scale) name(QQG9, replace)}{p_end}

{p 4 8 2}{cmd:. qqplotg stamford yonkers, by(month,  subtitle(log scale)) transform(ln) xla(`la') yla(`la') name(QQG10, replace)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:Also see}

{p 4 4 2}Help for{break}
{help qqplot}{break}
{help qplot} ({it:Stata Journal}) (if installed){break}
{help distplot} ({it:Stata Journal}) (if installed){break}
{help nicelabels} ({it:Stata Journal}) (if installed){break}
{help mylabels} ({it:Stata Journal}) (if installed){break}
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
2014. How can I calculate percentile ranks?
How can I calculate plotting positions?
{browse "http://www.stata.com/support/faqs/statistics/percentile-ranks-and-plotting-positions/":http://www.stata.com/support/faqs/statistics/percentile-ranks-and-plotting-positions/}

{p 4 8 2}
Cox, N. J. 
2016. Speaking Stata: Letter values as selected quantiles. 
{it:Stata Journal} 16: 1058{c -}1071.

{p 4 8 2}
Cox, N. J. 
2022. Speaking Stata: Automating axis labels: Nice numbers and transformed scales. 
{it:Stata Journal} 22: 975{c -}995.

{p 4 8 2}
De Jong, R., C. C. Liang and E. Lauber. 1994. 
Conditional and unconditional automaticity: A dual-process model of 
effects of spatial stimulus-response concordance. 
{it:Journal of Experimental Psychology: Human Perception and Performance} 20: 731{c -}750. 

{p 4 8 2}
Speckman, P. L., J. N. Rouder, R. D. Morey and M.S. Pratte.
2008. Delta plots and coherent distribution ordering. 
{it:The American Statistician} 62: 262{c -}266. 
doi: 10.1198/000313008X333493

{p 4 8 2}
Wilk, M. B. and R. Gnanadesikan. 1968. 
Probability plotting methods for the analysis of data. {it:Biometrika} 55: 1{c -}17.
https://doi.org/10.2307/2334448
	
