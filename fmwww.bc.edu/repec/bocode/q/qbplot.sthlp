{smcl}
{* 19aug2024}{...}
{cmd:help qbplot}
{hline}

{title:Title}

{p2colset 5 15 19 2}{...}
{p2col :{hi:qbplot} {hline 2}}Quantile plot with box flavour{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2} 
{cmd:qbplot} 
{varname}
{ifin}
[{cmd:,}
{opt spike(spike_options)}
{opt a(#)}
{opt addplot(twoway_command(s))}
{it:graph_options}
]


{title:Description}

{p 4 4 2}
{cmd:qbplot} is a dedicated pedagogic or propaganda command with the 
aim of showing that a quantile plot can convey all the key information
given by a box plot showing median and quartiles. Indeed, it can convey
much more. 

{p 4 4 2}
The main part of the display is a quantile plot, a scatter plot showing
ordered values against the so-called plotting positions, labelled
"Fraction of the data".  Compare official command {help quantile};
community-contributed command {help qplot} (Cox 1999, 2005, 2019, 2024);
community-contributed command {help multqplot} (Cox 2012, 2019);
community-contributed command {help stripplot}. 

{p 4 4 2} 
On the vertical axis, the values of the minimum, maximum, median and
quartiles are shown as axis labels. The median and quartiles are
connected using horizontal and vertical line segments to plotting
positions 0.25, 0.5, 0.75 on the horizontal axis. These segments may be
extended mentally to imagine a conventional box showing median and
quartiles, as in most variations of box plots. 

{p 4 4 2}
Variations from the basic design may be obtained by particular option
choices.


{title:Remarks}

{p 4 4 2}
The stance here is that this design can work well for samples of small,
moderate or large size. If a sample is small, there is enough space to
show all the detail in the data; the art is doing so while allowing
broad features to be grasped easily.  If a sample is very large, many
data points often blur into each other, but that doesn't make such plots
useless.  Marked outliers, gaps, spikes and so forth are likely to be
evident when they are present. Either way, quantile plots also convey
information on skewness and tail weight. 

{p 4 4 2}
The precise definition of plotting position is (unique rank - {it:a}) /
(#values - 2 * {it:a} + 1), where {it:a} defaults to 1/2 = 0.5, yielding
(unique rank - 0.5) / #values.  To specify another definition, see the
{cmd:a()} option. See also Cox (2014). 

{p 4 4 2}
Occasionally, ties in the data may lead to one or more of median,
quartiles, minimum and maximum coinciding. Such ties do not necessarily
render the plot useless. Indeed, the plot may help to clarify the fine
structure of the data, even if it also implies that some quite different
display may be more helpful.

{p 4 4 2}
Whenever data are strongly skewed, between two and four axis labels may
be uncomfortably close to each other. This is often a sign that you
might be better off using a transformed scale. Note that {cmd:ysc(log)}
is available for on-the-fly logarithmic transformation of entirely
positive data, Here we rely on median and quartiles of logarithms of
data being usually close enough to logarithms of median and quartiles of
data, at least for exploratory purposes. Otherwise you may need to apply
a transformation separately. 

{p 4 4 2}
Much of the point of this display is that we no longer need to worry
about precisely what is shown outside the box of a box plot. We just
show all the data points. So, we do not need to implement any particular
rule or convention, such as displaying data points individually if and
only if they are more than 1.5 IQR from the nearer quartile.  Nor do we
need to interpret the results of any such rule or convention.

{p 4 4 2}
Literature on so-called quantile-box plots is pertinent here.  Parzen
(1979a, 1979b, 1982, 1997) hybridised box and quantile plots as
quantile-box plots. See also (e.g.) Shera (1991), Militk{c y'} and
Meloun (1993), Meloun and Militk{c y'} (1994),  Nair {it:et al.} (2013),
Evans and Cox (2017) and Cox (2020).  Shelly (1996), Guevara and 
Avil{c e'}s (2007), Feigelson and Babu (2012, p.208) and Holmes and Huber (2019,
p.129) plotted quantile plots and box plots side by side.  Note,
however, that the quantile box plot of Keen (2010, 2018) is just a box
plot with whiskers extending to the extremes.  In contrast, the quantile
box plots of JMP are evidently box plots with marks at 0.5%, 2.5%, 10%,
90%, 97.5%, 99.5%: see Sall {it:et al.} (2014, pp.143{c -}4). 

{p 4 4 2}
For further references in this territory, see the help for {help stripplot}.  


{title:Options} 

{p 4 8 2} 
{cmd:a()} specifies an alternative rule for plotting position, as
discussed above. Possibilities are {cmd:a(0)} or {cmd:a(1/3)}. Note from
the last example that expressions yielding numeric results may be
specified. 

{p 4 8 2}
{cmd:spike()} indicates options of {help twoway spike} to tune the
display of line segments indicating median and quartiles. 

{p 4 8 2}
{cmd:addplot()} adds other {help twoway} commands. See help on 
{help addplot_option}. 

{p 4 8 2}
{it:graph_options} are other options of {help graph}, including any used
to tune the scatter.  Good examples would be {cmd:name()} or
{cmd:saving()}.  {cmd:aspect(1)} can work well for single plots. 


{title:Examples} 

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}

{p 4 8 2}{cmd:. qbplot mpg, aspect(1) name(qb1, replace)}{p_end}

{p 4 8 2}{cmd:. qbplot mpg, ysc(log) subtitle(logarithmic scale, place(w)) aspect(1) name(qb2, replace)}{p_end}

{p 4 8 2}{cmd:. means mpg}{p_end}
{p 4 8 2}{cmd:. local gmean = r(mean_g)}{p_end}
{p 4 8 2}{cmd:. qbplot mpg, ysc(log) subtitle(logarithmic scale, place(w)) note(dashed line shows geometric mean) addplot(function `gmean', lp(dash) lc(magenta)) aspect(1) name(qb3, replace)}{p_end}

{p 4 8 2}{cmd:. levelsof foreign}{p_end}

{p 4 8 2}{cmd:. foreach g in `r(levels)' {c -(}}{p_end}
{p 4 8 2}{cmd:. 	local this : label (foreign) `g'}{p_end}
{p 4 8 2}{cmd:. 	qbplot mpg if foreign == `g', ytitle("`this'", size(large)) name(G`g', replace)}{p_end}
{p 4 8 2}{cmd:. 	local G `G' G`g'}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. graph combine `G', ycommon subtitle("`: var label mpg'") name(qb4, replace)}{p_end}

{p 4 8 2}{cmd:. label var price "Price (USD)"}{p_end}

{p 4 8 2}{cmd:. foreach v in price weight length mpg {c -(}}{p_end}
{p 4 8 2}{cmd:. 	qbplot `v', ytitle(, size(large)) name(`v', replace)}{p_end}
{p 4 8 2}{cmd:. 	local V `V' `v'}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. graph combine `V', imargin(small) name(qb5, replace)}{p_end}


{p 4 8 2}{cmd:. sysuse nlsw88, clear}{p_end}

{p 4 8 2}{cmd:. qbplot wage, name(qb6, replace)}{p_end}

{p 4 8 2}{cmd:. qbplot wage, ysc(log) name(qb7, replace)}{p_end}

{p 4 8 2}{cmd:. qbplot wage, ysc(log) yla(, format(%3.2f)) name(qb8, replace)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:References} 

{p 4 8 2}
Cox, N.J. 1999. 
gr42: Quantile plots, generalized. 
{it:Stata Technical Bulletin} 51: 16{c -}18.

{p 4 8 2}
Cox, N.J. 2005. 
Speaking Stata: The protean quantile plot. 
{it:Stata Journal} 5: 442{c -}460.

{p 4 8 2}
Cox, N.J. 2012. 
Speaking Stata: Axis practice, or what goes where on a graph.
{it:Stata Journal} 12: 549{c -}561.

{p 4 8 2}
Cox, N.J. 2014. 
How can I calculate percentile ranks?
How can I calculate plotting positions?
{browse "http://www.stata.com/support/faqs/statistics/percentile-ranks-and-plotting-positions/":http://www.stata.com/support/faqs/statistics/percentile-ranks-and-plotting-positions/}

{p 4 8 2}
Cox, N.J. 2019. 
Software updates for qplot and multqplot.  
{it:Stata Journal} 19: 748{c -}751.

{p 4 8 2}Cox, N.J. 2020. 
Speaking Stata: More ways for rowwise. 
{it:Stata Journal} 20: 481{c -}488.

{p 4 8 2}
Cox, N.J. 2024. 
Software update for qplot.
{it:Stata Journal} 24: in press.

{p 4 8 2}Evans, I.S. and N.J. Cox. 2017. Comparability of cirque size and 
shape measures between regions and between researchers.  
{it:Zeitschrift f{c u:}r Geomorphologie} 61 SupplementBand 2: 81{c -}103.  

{p 4 8 2}Feigelson, E. D. and G. J. Babu. 2012. 
{it:Modern Statistical Methods for Astronomy with R Applications}. 
Cambridge: Cambridge University Press. 

{p 4 8 2}Guevara, J. and L. Avil{c e'}s. 2007. 
Multiple techniques confirm elevational differences in insect size that may influence spider sociality. 
{it:Ecology} 88: 2015{c -}2023. 

{p 4 8 2}Holmes, S. and W. Huber. 2019. 
{it:Modern Statistics for Modern Biology.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}Keen, K.J. 2010. 
{it:Graphics for Statistics and Data Analysis with R.} 
Boca Raton, FL: CRC Press. (second edition 2018)

{p 4 8 2}Meloun, M. and J. Militk{c y'}. 1994. 
Computer-assisted data treatment in analytical chemometrics.
I. Exploratory analysis of univariate data. 
{it:Chemical Papers} 48: 151{c -}157. 

{p 4 8 2}Militk{c y'}, J. and M. Meloun. 1993. 
Some graphical aids for univariate exploratory data analysis. 
{it:Analytica Chimica Acta} 277: 215{c -}221. 

{p 4 8 2}Nair, N.U., Sankaran, P.G. and Balakrishnan, N. 2013. 
{it:Quantile-based Reliability Analysis.} 
New York: Springer. 

{p 4 8 2}Parzen, E. 1979a. 
Nonparametric statistical data modeling. 
{it:Journal, American Statistical Association}  
74: 105{c -}121. 

{p 4 8 2}Parzen, E. 1979b. 
A density-quantile function perspective on robust estimation. 
In Launer, R.L. and G.N. Wilkinson (eds) {it:Robustness in Statistics.} 
New York: Academic Press, 237{c -}258. 

{p 4 8 2}Parzen, E. 1982. 
Data modeling using quantile and density-quantile functions. 
In Tiago de Oliveira, J. and B. Epstein (eds) 
{it:Some Recent Advances in Statistics.} London: Academic Press, 
23{c -}52.

{p 4 8 2}Parzen, E. 1997. 
Concrete statistics. In 
Ghosh, S., W.R. Schucany, and W.B. Smith (eds) 
{it:Statistics of Quality}. New York: Marcel Dekker, 309{c -}332. 

{p 4 8 2}Sall, J., A. Lehman, M. Stephens and L. Creighton. 2014. 
{it:JMP Start Statistics: A Guide to Statistics and Data Analysis Using JMP.} 
Cary, NC: SAS Institute. 

{p 4 8 2}Shelly, M. 1996. 
Exploratory data analysis: data visualization or torture? 
{it:Infection Control and Hospital Epidemiology} 17: 605{c -}612.

{p 4 8 2}Shera, D.M. 1991. 
Some uses of quantile plots to enhance data presentation. 
{it:Computing Science and Statistics} 23: 50{c -}53.
{browse "http://www.dtic.mil/dtic/tr/fulltext/u2/a252938.pdf":http://www.dtic.mil/dtic/tr/fulltext/u2/a252938.pdf} 


{title:Also see}

{p 4 4 2}
Online:  help for {help quantile},{break}
{help qplot} (if installed),{break}
{help multqplot} (if installed),{break}
{help stripplot} (if installed)

