{smcl}
{* 11jun2018/10dec2018/10may2019/26aug2020}
{* subsetplot 26sep2014/1oct2014/1may2015/12jun2015/18dec2015/1sep2016/21sep2016/13apr2017/6jun2017}{...}
{hline}
help for {hi:fabplot}
{hline}

{title:Plots for each subset with rest of the data as backdrop} 

{p 8 17 2} 
{cmd:fabplot}
{it:command} 
{it:yvar}
{it:xvar} 
[{help if}] 
[{help in}]
{cmd:,}
{cmd:by(}{it:byvar} [{cmd:,} {it:byopts}]{cmd:)} 
[
{cmd:select(}{it:condition}{cmd:)} 
{cmd:front(}{it:twoway_command}{cmd:)}
{cmd:frontopts(}{it:twoway_options}{cmd:)}
{it:graph_options}
]


{title:Description} 

{p 4 4 2} 
{cmd:fabplot} produces an array of {help scatter} or other {help twoway}
plots for {it:yvar} versus {it:xvar} according to a further variable
{it:byvar}.  There is one plot for observations for each distinct subset
of {it:byvar} in which data for that subset are highlighted (shown at
the front or in the foreground, as it were) and the rest of the data
are shown as backdrop. The name {cmd:fabplot} can thus be understood as
indicating a plot showing some observations in each panel in the
{cmd:f}ront or as {cmd:f}oreground and the others as {cmd:b}ackdrop or
{cmd:b}ackground. 


{title:Remarks} 

{p 4 4 2}
This approach was discussed in Cox (2010). See also Cox (2019) for wider 
discussion of the spaghetti problem.

{p 4 4 2}
Cleveland (1985, pp.74, 203, 205, 268) shows graphs in which summary curves 
for groups are repeated with data shown separately for each group. 
(Note: these graphs do not appear in Cleveland 1994.) 

{p 4 4 2} 
See also 
Wallgren et al. (1996) (almost), 
Koenker (2005), 
Carr and Pickle (2010), 
Rougier et al. (2014), 
Schwabish (2014, 2017), 
Knaflic (2015), 
Unwin (2015), 
Cairo (2016),  
Cam{c o~}es (2016), 
Kriebel and Murray (2018), 
Grant (2019)  
and Koponen and Hild{c e'}n (2019) 
for examples.  

{p 4 4 2} 
Readers knowing interesting or useful examples or
discussions, especially early in date or comprehensive in detail, 
are welcome to email the author. 


{title:Options}

{p 4 8 2}
{cmd:by()} specifies a numeric or string variable {it:byvar} defining
the distinct subsets being plotted. This is a required option. Options
of {cmd:by()} may be specified in the usual way: see {help by option}. 

{p 4 8 2}
{cmd:select()} specifies a true-or-false condition referring to {it:byvar} 
selecting which panels are shown. This is best explained with a concrete
example. You have 10 companies, but wish to display only panels for the
4 most interesting or important, but in each case data for the other 9 companies
should be shown as backdrop. Note that a standard {cmd:if} qualifier cannot 
match this mix of choices. 

{p 4 8 2}
{cmd:front(}{it:twoway_command}{cmd:)} specifies a {help twoway} 
command used to plot observations in each distinct subset as front or
foreground. 

{p 4 8 2}
{cmd:frontopts(}{it:twoway_options}{cmd:)} specifies options of 
{help twoway} tuning the front or foreground plot of each distinct subset. 

{p 4 8 2} 
{it:graph_options} are options of {help twoway} used to display
observations for the rest of the data in each plot. 


{title:Examples} 

{p 4 8 2}{cmd:. set scheme s1color}{p_end}
{p 4 8 2}{cmd:. set more on}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. fabplot scatter mpg weight, by(rep78)}{p_end}
{p 4 8 2}{cmd:. more}{p_end}
{p 4 8 2}{cmd:. fabplot scatter mpg weight, frontopts(ms(none) mla(rep78) mlabsize(*1.5) mlabpos(0) mlabcolor(blue)) by(rep78)}{p_end}
{p 4 8 2}{cmd:. more}{p_end}

{p 4 8 2}{cmd:. webuse grunfeld}{p_end}
{p 4 8 2}{cmd:. fabplot line invest year, by(company) ysc(log) yla(1 10 100 1000)}{p_end}
{p 4 8 2}{cmd:. more}{p_end}
{p 4 8 2}{cmd:. fabplot line invest year, by(company) ysc(log) yla(1 10 100 1000) front(connect) frontopts(mc(blue) lc(blue))}{p_end}
{p 4 8 2}{cmd:. more}{p_end}
{p 4 8 2}{cmd:. fabplot line invest year, by(company) ysc(log) yla(1 10 100 1000) frontopts(lw(thick)) select(company <= 4)}{p_end}


{title:Author} 

{p 4 4 2}Nicholas J. Cox, Durham University, U.K.{break} 
         n.j.cox@durham.ac.uk


{title:References} 

{p 4 8 2}
Cairo, A. 2016. 
{it:The Truthful Art: Data, Charts, and Maps for Communication.} 
San Francisco, CA: New Riders. See p.211. 

{p 4 8 2}
Cam{c o~}es, J. 2016. 
{it:Data at Work: Best Practices for Creating Effective Charts and Information Graphics in Microsoft Excel}. 
San Francisco, CA: New Riders. See p.354. 

{p 4 8 2}
Carr, D.B. and L.W. Pickle. 2010. 
{it:Visualizing Data Patterns with Micromaps.}
Boca Raton, FL: CRC Press. See p.85.

{p 4 8 2}
Cleveland, W.S. 1985. {it:Elements of Graphing Data.} 
Monterey, CA: Wadsworth. 

{p 4 8 2}
Cleveland, W.S. 1994. {it:Elements of Graphing Data.} 
Summit, NJ: Hobart Press. 

{p 4 8 2}
Cox, N.J. 2010. Graphing subsets. 
{it:Stata Journal} 10: 670{c -}681. 
{browse "https://www.stata-journal.com/sjpdf.html?articlenum=gr0046":https://www.stata-journal.com/sjpdf.html?articlenum=gr0046} 

{p 4 8 2}
Cox, N.J. 2019. 
Some simple devices to ease the spaghetti problem. 
{it:Stata Journal} 19: 989{c -}1008. 
{browse "https://journals.sagepub.com/doi/10.1177/1536867X19893641":https://journals.sagepub.com/doi/10.1177/1536867X19893641}

{p 4 8 2}
Grant, R. 2019. 
{it:Data Visualization: Charts, Maps, and Interactive Graphics.} 
Boca Raton, FL: CRC Press. See p.52. 

{p 4 8 2}
Knaflic, C.N. 2015. 
{it:Storytelling with Data: A Data Visualization Guide for Business Professionals}. 
Hoboken, NJ: John Wiley.  

{p 4 8 2}
Koenker, R. 2005. 
{it:Quantile Regression.} 
Cambridge: Cambridge University Press. See pp.12-13. 

{p 4 8 2}
Koponen, J. and Hild{c e'}n, J. 2019. 
{it:The Data Visualization Handbook.} 
Espoo: Aalto ARTS Books. See p.101. 

{p 4 8 2} 
Kriebel, A. and Murray, E. 2018. 
{it:#MakeoverMonday: Improving How We Visualize and Analyze Data, One Chart at a Time.} 
Hoboken, NJ: John Wiley. See p.303. 

{p 4 8 2}
Rougier, N.P., Droettboom, M. and Bourne, P.E. 2014. 
Ten simple rules for better figures. 
{it:PLOS Computational Biology} 10(9): e1003833.
doi:10.1371/journal.pcbi.1003833
{browse "http://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1003833":http://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1003833}

{p 4 8 2}
Schwabish, J.A. 2014. An economist's guide to visualizing data.
{it:Journal of Economic Perspectives} 28: 209{c -}234.
{browse "https://pubs.aeaweb.org/doi/pdfplus/10.1257/jep.28.1.209":https://pubs.aeaweb.org/doi/pdfplus/10.1257/jep.28.1.209}

{p 4 8 2}
Schwabish, J. 2017.  
{it:Better Presentations: A Guide for Scholars, Researchers, and Wonks.}  
New York: Columbia University Press. See p.98.

{p 4 8 2}
Unwin, A. 2015. 
{it:Graphical Data Analysis with R.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}
Wallgren, A., B. Wallgren, R. Persson, U. Jorner, and J.-A. Haaland. 
1996. 
{it:Graphing Statistics and Data: Creating Better Charts.}
Newbury Park, CA: SAGE.

{p 4 8 2}
Wickham, H. 2016. 
{it:ggplot2: Elegant Graphics for Data Analysis.}
 Cham: Springer. See p.157.


{title:Also see}

{p 4 13 2}
On-line: help for {help twoway}, help for {help graph matrix}, 
help for {help graph combine}    

