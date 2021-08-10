{smcl}
{* 27oct2004/26sep2005/22jan2007/7jul2009/24jul2009/25nov2009/30nov2009/10dec2009/14jun2010/14dec2010/1mar2011/11oct2011/16nov2011/9may2012/6jun2012/14aug2012/19oct2012}{...}
{* 21feb2013/16jul2013/28aug2013/30dec2013/2may2015/25may2015/9jul2015/26aug2015/29sep2015/15oct2015/18dec2015/6apr2016}{...}
{hline}
help for {hi:tabplot}
{hline}

{title:One-, two- and three-way bar charts for tables} 

{p 4 8 2} 
{cmd:tabplot}
{it:varname}
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]
[{it:weight}]
[
{cmd:,} {it:options} 
] 

{p 4 8 2} 
{cmd:tabplot}
{it:rowvar}
{it:colvar}
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]
[{it:weight}]
[
{cmd:,} {it:options} 
] 


{p 4 8 2}{it:options} specify 

{p 4 8 2}- whether bars show fractions, percents, missing categories 

{p 8 8 2}
[ {cmdab:fr:action} {c |} {cmdab:fr:action(}{it:varlist}{cmd:)} {c |} {cmdab:perc:ent} {c |} {cmdab:perc:ent(}{it:varlist}{cmd:)} 
] 
{p_end} 
{p 8 8 2}{cmdab:miss:ing}

{p 4 8 2}- whether {it:y} and/or {it:x} values are literal (default: map to integers 1 up)

{p 8 8 2}{cmd:yasis xasis}

{p 4 8 2}- horizontal bars (default vertical) 

{p 8 8 2}{cmdab:hor:izontal} 

{p 4 8 2}- maximum bar height (lengths if horizontal) (default 0.8) 

{p 8 8 2}{cmdab:h:eight(}{it:#}{cmd:)} 

{p 4 8 2}- showing numeric values below or beside bars 

{p 8 8 2}{cmdab:show:val}[{cmd:(}{it:specification}{cmd:)}] 

{p 4 8 2}- more specialised variants 

{p 8 8 2}
{cmdab:min:imum(}{it:#}{cmd:)} 
{cmdab:max:imum(}{it:#}{cmd:)} 
{cmdab:sep:arate(}{it:sepspec}{cmd:)} 

{p 4 8 2}- different displays for individual bars 

{p 8 8 2}{cmd:bar1(}{it:rbar_options}{cmd:)} 
...
{cmd:bar20(}{it:rbar_options}{cmd:)} 
{cmd:barall(}{it:rbar_options}{cmd:)} 

{p 4 8 2}- other graph details 

{p 8 8 2} 
{it:graph_options}
[ {cmd:plot(}{it:plot}{cmd:)} {c |}
{cmd:addplot(}{it:plot}{cmd:)} ]


{p 4 4 2}{cmd:fweight}s, {cmd:aweight}s and {cmd:iweights} may be specified. 


{title:Description} 

{p 4 4 2}{cmd:tabplot} plots a table of numerical values 
(e.g. frequencies, fractions or percents) in graphical form as a bar chart.
It is mainly intended for representing contingency tables for one, two
or three categorical variables. It also has uses for producing multiple
histograms and graphs for general one-, two- or three-way tables. 

{p 4 4 2}{cmd:tabplot} {it:varname} creates a bar chart which by default
displays one set of vertical bars; with the {cmd:horizontal} option it
displays one set of horizontal bars. The categories of {it:varname} thus
define either columns from left (low values) to right (high values) or
rows from top (low values) to bottom (high values).  The value 
(e.g. frequency, fraction or percent) for each column or row is shown as a bar. 

{p 4 4 2}{cmd:tabplot} {it:rowvar} {it:colvar} follows standard
tabular alignment: the categories of {it:rowvar} define rows from top
(low values) to bottom (high values) and the categories of {it:colvar}
define columns from left (low values) to right (high values). The value 
(e.g. frequency, fraction or percent) for each combination of row and column is
shown as a bar, with default alignment vertical.

{p 4 4 2}The default bar width is 0.5. Use the {cmd:barwidth()} option
to vary width, but note that all bars will have the same width.  

{p 4 4 2}By default both variables are mapped on the fly in sort order
to successive integers from 1 up, but original values or value labels
are used as value labels: this may be varied by use of the {cmd:yasis}
or {cmd:xasis} options. The maximum bar height is by default 0.8. 
Use the {cmd:height()} option to vary this. 

{p 4 4 2}See {cmd:Remarks} and {cmd:Examples} for advice when you want
to plot two or more variables on the rows or the columns of such a plot.


{title:Remarks} 

{p 4 4 2}The display is deliberately minimal. No numeric scales are
shown for reading off numeric values, although optionally numeric values
may be shown below or beside bars by use of the {cmd:showval} option.
Above all, there is no facility for any kind of three-dimensional
display or effect. The maximum value (or more generally value furthest 
from zero) shown is indicated by use of {cmd:note()}, unless {cmd:showval} or
{cmd:showval()} is specified. 

{p 4 4 2}In contrast to a table, in which it is easier to compare values
down columns, it is usually easier to compare values across rows
whenever bars are vertical.  A simple alternative is to use the
{cmd:horizontal} option, in which case it is usually easier to compare
down columns.  Some experimentation with both forms and with
{cmd:percent(}{it:rowvar}{cmd:)} or {cmd:percent(}{it:colvar}{cmd:)}
will often be helpful. 

{p 4 4 2}{cmd:tabplot} {it:rowvar colvar}{cmd:, by()} is the way to plot
three-way tables. The variable specified in {cmd:by()} is used to
produce a set of graphs in several panels. Similarly, {cmd:tabplot}
{it:varname}{cmd:, by()} is another way to plot two-way tables. 

{p 4 4 2}Four-way or higher charts would often not be readable or
interpretable, but there are three evident ways to attempt them. First,
try to {help reshape} or otherwise restructure the data
concerned to fewer variables. Second, combine
variables, usually predictor variables, into a composite variable to be
shown on one axis. See Cox (2007) for discussion of how to do that.
Third, use {cmd:tabplot} repeatedly and then {help graph combine}. 

{p 4 4 2}{cmd:tabplot} with the {cmd:xasis} option may be useful for
stacking histograms vertically. Less commonly, with the {cmd:yasis} and
{cmd:horizontal} options it may be useful for stacking them
horizontally.  A typical protocol would be, for {cmd:mpg} shown in bins
of width 2.5 mpg, 

{p 8 8 2}
{cmd:. sysuse auto, clear}{break} 
{cmd:. gen midpoint = round(mpg, 2.5)}{break} 
{cmd:. _crcslbl midpoint mpg}{break} 
{cmd:. tabplot foreign midpoint, xasis barw(2.5) bstyle(histogram) percent(foreign)}

{p 4 4 2}In general, specify a variable containing equally-spaced
midpoints and assign to it an appropriate variable label.  {cmd:tabplot}
will do the rest.  Omit the {cmd:percent()} option for display of
frequencies. 

{p 4 4 2}A recipe for subverting {cmd:tabplot} to plot any variable that
takes on a single value for each cross-combination of categories is
illustrated in the examples below. The key is to select precisely one
observation for each cross-combination and to specify that variable as
(most generally) an {cmd:iweight}. 

{p 4 4 2}Furthermore, using an {cmd:iweight} is the only possible method
whenever a variable has at least some negative values. In that case, 

{p 8 8 2}1. Consider changing the maximum height through {cmd:height()}
to avoid overlap of bars variously representing positive and negative
values.  By default {cmd:tabplot} chooses the scale to accommodate the
longest bar to be shown, but it contains no special intelligence
otherwise to avoid overlap of bars in the same column or row. 

{p 8 8 2}2. If also using {cmd:showval} or {cmd:showval()}, consider
changing the {cmd:offset()} and using a transparent {cmd:bfcolor()}. 

{p 4 4 2}
Bar charts presented as one row or one column of bars go back at least
as far as Playfair (1786). See (e.g.) Playfair (2005, p.25) or Wainer
(2005, p.45; 2009, p.174). 

{p 4 4 2} 
Bar charts presented in table form with two or more rows and two or more
columns are less common. They have been used in one form of pollen
diagram.  Sears (1933, 1935) gave some early examples. See also Emeny (1934)
for a well-illustrated monograph on raw materials. 

{p 4 4 2} 
Brinton (1939), 
Neurath (1939), 
Stouffer {it:et al.} (1949a, 1949b), 
Rogers (1961), 
Ager (1963), 
Lockwood (1969), 
Koch and Link (1970), 
Doran and Hodson (1975), 
Bertin (1981, 1983), 
Lebart, Morineau and Warwick (1984), 
Morrison (1985), 
Anderson and May (1991), 
Gleick (1993),
Chapman and Wykes (1996), 
de Falguerolles et al. (1997), 
Chauchat and Risson (1998), 
Valiela (2001), 
Mihalisin (2002), 
MacKay (2003, 2008),  
Wilkinson (2005), 
Unwin, Theus and Hofmann (2006), 
Hahsler, Hornik and Buchta (2008), 
Hofmann (2008),
Sarkar (2008),  
Theus and Urbanek (2009),  
Few (2009, 2012, 2015), 
Atkins (2010), 
McDaniel and McDaniel (2012a, 2012b),  
Merz (2012) 
and Unwin (2015) 
also give a variety of examples. 

{p 4 4 2}
As the example of pollen diagrams shows, the same form of graph can be
used for showing on any one axis either the categories of what is
regarded as one variable or two or more variables considered similar or
comparable. Such bar charts, or similar displays, are also known as 

{p 8 8 2}aligned bar charts, multi-pane bar charts: Mackinlay (1986), 
McDaniel and McDaniel (2012a, 2012b)  

{p 8 8 2}survey plots: Lohninger (1994, 1996), Hoffman and Grinstein (2002), Grinstein et al. (2002), Ward et al. (2010) 

{p 8 8 2}table lens: Rao and Card (1994), Pirolli and Rao (1996), Spence (2007),
Ward et al. (2010), Few (2012)

{p 8 8 2}multiple bar charts and fluctuation diagrams: 
Becker et al. (1988), 
Unwin et al. (2006), Hofmann (2008), Theus and Urbanek (2009), 
Unwin (2015) 

{p 4 4 2}Such bar charts may require no more than a {help reshape}. The
Examples include one with archaeological data, in which levels are
counted from the top downwards, so that the row numbering convention is
fortuitously and fortunately what is wanted. 

{p 4 4 2}Displays such as bar and pie charts with added numeric labels
have been called {it:grables} (Hink et al. 1996, 1998; Bradstreet 2012). 

{p 4 4 2}We note also what are often called Hinton diagrams or Hinton 
plots in machine learning. Rumelhart et al. (1986) is a token reference. 
Examples occur in mainstream machine learning texts such as MacKay (2003), 
Bishop (2006), Barber (2012) and Murphy (2012). 

{p 4 4 2}Brinton (1939, pp.142, 505) uses the term two-way bar chart for 
back-to-back or bilateral bar charts, a use different from that here. 

{p 4 4 2}Similar references would be much appreciated by the author. 

{p 4 4 2}For applications of {cmd:tabplot}, see also Cox (2004, 2008, 2012)
or search Statalist. 


{title:Options} 

{p 4 8 2}{cmd:fraction} indicates that all frequencies should be shown
as fractions (with sum 1) of the total frequency of all values being
represented in the graph.

{p 4 8 2}{cmd:fraction(}{it:varlist}{cmd:)} indicates that all
frequencies should be shown as fractions (with sum 1) of the total
frequency for each distinct category defined by the combinations of
{it:varlist}. Usually, {it:varlist} will be one or more of the variables
specified. 

{p 4 8 2}{cmd:percent} indicates that all frequencies should be shown as
percents (with sum 100) of the total frequency of all values being
represented in the graph. 

{p 4 8 2}{cmd:percent(}{it:varlist}{cmd:)} indicates that all
frequencies should be shown as percents (with sum 100) of the total
frequency for each distinct category defined by the combinations of
{it:varlist}. Usually, {it:varlist} will be one or more of the variables
specified. 

{p 4 8 2}Only one of these {cmd:fraction}[{cmd:()}] and
{cmd:percent}[{cmd:()}] options may be specified. 

{p 4 8 2}{cmd:missing} specifies that any missing values of any of the
variables specified should also be included within their own categories.

{p 4 8 2}{cmd:yasis} and {cmd:xasis} specify respectively that the
{it:y} (row) variable and the {it:x} (column) variable are to be treated
literally (that is, numerically). Most commonly, each option will be
specified if the variable in question is a measured scale or a graded
variable with gaps. If values 1 to 5 are labelled A to E, but no value
of 4 (D) is present in the data, {cmd:yasis} or {cmd:xasis} prevents a
mapping to 1 (A) ... 4 (E).

{p 4 8 2}{cmd:horizontal} specifies horizontal bars. The default is 
vertical bars. 

{p 4 8 2}{cmd:height(}{it:#}{cmd:)} controls the amount of graph space
taken up by bars. The default is 0.8.  Note that the height may need to
be much smaller or much larger with {cmd:yasis} or {cmd:xasis}, given
that the latter take values literally.  

{p 4 8 2}{cmd:showval} specifies that numeric values are to be shown
beneath (or if {cmd:horizontal} is specified to the left of) bars.

{p 4 8 2} {cmd:showval} may also be specified with a variable name
and/or options.  If options alone are specified, no comma need be
given.  In particular, 

{p 8 8 2}{cmd:showval(}{it:varname}{cmd:)} would specify that the values
to be shown are those of {it:varname}. For example, the values of some
kind of residuals might be shown alongside frequency bars. 

{p 8 8 2}{cmd:showval(offset(}{it:#}{cmd:))} specifies an offset between
the base (or left-hand edge) of the bar and the position of the numeric
value.  Default is 0.1 with two variables or 0.02 with one variable.
Tweak this if the spacing is too large or too small. 

{p 8 8 2}{cmd:showval(format(}{it:format}{cmd:))} specifies a format
with which to show values. Specifying a format will often be advisable
with non-integers. Example: {cmd:showval(format(%2.1f))} specifies
rounding to 1 decimal place. Note that with a specified variable the
format defaults to the format of that variable; with percent options the
format defaults to %2.1f (1 decimal place); with fraction options the
format defaults to %4.3f (3 decimal places). 

{p 8 8 2}{cmd:showval(}{it:varname}{cmd:, format(%2.1f))} is an example
of {it:varname} specified with options. As usual, a comma is needed 
in such cases. 

{p 8 8 2}Otherwise the options of {cmd:showval()} can be options of
{help scatter}, most usually {help marker label options}. 

{p 4 8 2}{cmd:minimum()} suppresses plotting of bars with values less
than the minimum specified, in effect setting them to zero. 

{p 4 8 2}{cmd:maximum()} truncates bars with values more than the
maximum specified to show that maximum.  

{p 4 8 2}{cmd:separate()} specifies that bars associated with different
{it:sepspec} will be shown differently, most obviously using different
colours. {it:sepspec} is passed as an argument to the {cmd:by()} option
of {help separate}, except that references to {cmd:@} are first
translated to be references to the quantity being plotted. 

{p 8 8 2}A call to {cmd:separate()} may be supplemented with calls to
options {cmd:bar1()} ...  {cmd:bar20} and/or to {cmd:barall()}. The
arguments should be options of {help twoway rbar}. 

{p 8 8 2}Options {cmd:bar1()} to {cmd:bar20()} are provided to allow
overriding the defaults on up to 20 categories, the first, second, etc.,
shown.  The limit of 20 is plucked out of the air as more than any user
should really want. The option {cmd:barall()} is available to override
the defaults for all bars. Any {cmd:bar}?  option always overrides
{cmd:barall()}. Thus if you wanted thicker {cmd:blwidth()} on all bars
you could specify {cmd:barall(blwidth(thick))}. If you wanted to
highlight the first category only you could specify
{cmd:bar1(blwidth(thick))}.

{p 4 8 2}{it:graph_options} refers to options of 
{help twoway_rbar:twoway rbar}.  Among others: 

{p 8 8 2}{cmd:barwidth()} specifies the widths of the bars. The default
is 0.5.  This may need changing, especially with option {cmd:xasis} or
{cmd:yasis} and/or if you wish bars to touch, exactly or nearly. 

{p 8 8 2}{cmd:bfcolor()} tunes bar fill colour. In particular, Stata's
defaults often imply that bars are filled with strong colours, but
unfilled bars using {cmd:bfcolor(none)} may be more subtle and just as
clear. 

{p 8 8 2}{cmd:by()} specifies another variable used to subdivide the
display into panels. 

{p 8 8 2}{cmd:recast()} recasts the graph as another twoway plottype. In
practice, {cmd:recast(rspike)} is the main alternative. 

{p 8 8 2}{cmd:subtitle()} shown by default outside the graph and at top
left specifies what kind of quantity is being shown: {cmd:"frequency"},
{cmd: "percent"}, and so forth. The Examples include examples in which
it is changed, which may mean being blanked out. 

{p 4 8 2}{cmd:plot(}{help plot_option:plot}{cmd:)} provides a way to add
other plots to the generated graph.  Sometimes useful in Stata 8. 

{p 4 8 2}{cmd:addplot(}{help addplot option:addplot}{cmd:)} provides a
way to add other plots to the generated graph. Allowed in Stata 9
upwards.

{p 8 8 2}With large datasets especially, it is advisable to ensure that
the extra plot(s) do(es) not contain information repeated for every
observation within each combination of {it:rowvar} and {it:colvar}. The
examples show one technique for avoiding this.


{title:Examples}

{p 4 8 2}Stata's auto data: 

{p 4 8 2}{cmd:. sysuse auto, clear}

{p 4 8 2}{cmd:. tabplot rep78}{p_end}
{p 4 8 2}{cmd:. tabplot rep78, showval}{p_end}
{p 4 8 2}{cmd:. tabplot rep78, showval horizontal}

{p 4 8 2}{cmd:. tabplot for rep78}{p_end}
{p 4 8 2}{cmd:. tabplot for rep78, showval}{p_end}
{p 4 8 2}{cmd:. tabplot for rep78, percent(foreign) showval(offset(0.05) format(%2.1f))}{p_end}
{p 4 8 2}{cmd:. tabplot for rep78, percent(foreign) sep(foreign) bar1(bcolor(red*0.5)) bar2(bcolor(blue*0.5)) showval(offset(0.05) format(%2.1f)) subtitle(% by origin)}

{p 4 8 2}{cmd:. tabplot rep78 mpg, xasis barw(1) bstyle(histogram)}

{p 4 8 2}{cmd:. egen mean = mean(mpg), by(rep78)}{p_end}
{p 4 8 2}{cmd:. gen rep78_2 = 6 - rep78 - 0.05}{p_end}
{p 4 8 2}{cmd:. bysort rep78 : gen byte tag = _n == 1}{p_end}
{p 4 8 2}{cmd:. tabplot rep78 mpg, xasis barw(1) bstyle(histogram) addplot(scatter rep78_2 mean if tag)}

{p 4 8 2}{cmd:. egen mean2 = mean(mpg), by(foreign rep78)}{p_end}
{p 4 8 2}{cmd:. egen tag = tag(foreign rep78)}{p_end}
{p 4 8 2}{cmd:. tabplot foreign rep78 if tag [iw=mean2], showval(format(%2.1f)) subtitle(mean miles per gallon)}{p_end}

{p 4 8 2}Stata's radiologist assessment data: 

{p 4 8 2}{cmd:. webuse rate2, clear}{p_end}
{p 4 8 2}{cmd:. tabplot rad?, percent showval}{p_end}
{p 4 8 2}{cmd:. count}{p_end}
{p 4 8 2}{cmd:. bysort rada radb : gen show = string(_N) + "  " + string(_N * 100/85, "%2.1f") + "%"}{p_end}
{p 4 8 2}{cmd:. tabplot rad?, showval(show) subtitle("frequency and %")}{p_end}
{p 4 8 2}{cmd:. tabplot rad?, showval(show) xsc(alt) subtitle("frequency and %", pos(7))}

{p 4 8 2}Doran and Hodson (1975, p.259) gave these archaeological data:

{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. input levels freqcores freqblanks freqtools}{p_end}
{p 4 8 2}{cmd:.     25 21 32 70}{p_end}
{p 4 8 2}{cmd:.     24 36 52 115}{p_end}
{p 4 8 2}{cmd:.     23 126 650 549}{p_end}
{p 4 8 2}{cmd:.     22 159 2342 1633}{p_end}
{p 4 8 2}{cmd:.     21 75 487 511}{p_end}
{p 4 8 2}{cmd:.     20 176 1090 912}{p_end}
{p 4 8 2}{cmd:.     19 132 713 578}{p_end}
{p 4 8 2}{cmd:.     18 46 374 266}{p_end}
{p 4 8 2}{cmd:.     17 550 6182 1541}{p_end}
{p 4 8 2}{cmd:.     16 76 846 349}{p_end}
{p 4 8 2}{cmd:.     15 17 182 51}{p_end}
{p 4 8 2}{cmd:.     14 4 51 14}{p_end}
{p 4 8 2}{cmd:.     13 29 228 130}{p_end}
{p 4 8 2}{cmd:.     12 135 2227 729}{p_end}
{p 4 8 2}{cmd:. end}{p_end}
{p 4 8 2}{cmd:. reshape long freq, i(levels) j(type) string}{p_end}
{p 4 8 2}{cmd:. tabplot levels type [w=freq], bfcolor(none) horizontal barw(1) percent(levels) subtitle(% at each level) showval(offset(0.45)) xsc(r(0.8 .))}

{p 4 8 2}Greenacre (2007, p.42) gave these data from the Encuesta Nacional 
de la Salud (Spanish National Health Survey), 1997:

{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. input byte(agegroup health) long freq}{p_end}
{p 4 8 2}{cmd:. 1 1 243}{p_end}
{p 4 8 2}{cmd:. 1 2 789}{p_end}
{p 4 8 2}{cmd:. 1 3 167}{p_end}
{p 4 8 2}{cmd:. 1 4  18}{p_end}
{p 4 8 2}{cmd:. 1 5   6}{p_end}
{p 4 8 2}{cmd:. 2 1 220}{p_end}
{p 4 8 2}{cmd:. 2 2 809}{p_end}
{p 4 8 2}{cmd:. 2 3 164}{p_end}
{p 4 8 2}{cmd:. 2 4  35}{p_end}
{p 4 8 2}{cmd:. 2 5   6}{p_end}
{p 4 8 2}{cmd:. 3 1 147}{p_end}
{p 4 8 2}{cmd:. 3 2 658}{p_end}
{p 4 8 2}{cmd:. 3 3 181}{p_end}
{p 4 8 2}{cmd:. 3 4  41}{p_end}
{p 4 8 2}{cmd:. 3 5   8}{p_end}
{p 4 8 2}{cmd:. 4 1  90}{p_end}
{p 4 8 2}{cmd:. 4 2 469}{p_end}
{p 4 8 2}{cmd:. 4 3 236}{p_end}
{p 4 8 2}{cmd:. 4 4  50}{p_end}
{p 4 8 2}{cmd:. 4 5  16}{p_end}
{p 4 8 2}{cmd:. 5 1  53}{p_end}
{p 4 8 2}{cmd:. 5 2 414}{p_end}
{p 4 8 2}{cmd:. 5 3 306}{p_end}
{p 4 8 2}{cmd:. 5 4 106}{p_end}
{p 4 8 2}{cmd:. 5 5  30}{p_end}
{p 4 8 2}{cmd:. 6 1  44}{p_end}
{p 4 8 2}{cmd:. 6 2 267}{p_end}
{p 4 8 2}{cmd:. 6 3 284}{p_end}
{p 4 8 2}{cmd:. 6 4  98}{p_end}
{p 4 8 2}{cmd:. 6 5  20}{p_end}
{p 4 8 2}{cmd:. 7 1  20}{p_end}
{p 4 8 2}{cmd:. 7 2 136}{p_end}
{p 4 8 2}{cmd:. 7 3 157}{p_end}
{p 4 8 2}{cmd:. 7 4  66}{p_end}
{p 4 8 2}{cmd:. 7 5  17}{p_end}
{p 4 8 2}{cmd:. end}{p_end}
{p 4 8 2}{cmd:. label values agegroup agegroup}{p_end}
{p 4 8 2}{cmd:. label def agegroup 1 "16-24", modify}{p_end}
{p 4 8 2}{cmd:. label def agegroup 2 "25-34", modify}{p_end}
{p 4 8 2}{cmd:. label def agegroup 3 "35-44", modify}{p_end}
{p 4 8 2}{cmd:. label def agegroup 4 "45-54", modify}{p_end}
{p 4 8 2}{cmd:. label def agegroup 5 "55-64", modify}{p_end}
{p 4 8 2}{cmd:. label def agegroup 6 "65-74", modify}{p_end}
{p 4 8 2}{cmd:. label def agegroup 7 "75+", modify}{p_end}
{p 4 8 2}{cmd:. label values health health}{p_end}
{p 4 8 2}{cmd:. label def health 1 "very good", modify}{p_end}
{p 4 8 2}{cmd:. label def health 2 "good", modify}{p_end}
{p 4 8 2}{cmd:. label def health 3 "regular", modify}{p_end}
{p 4 8 2}{cmd:. label def health 4 "bad", modify}{p_end}
{p 4 8 2}{cmd:. label def health 5 "very bad", modify}{p_end}
{p 4 8 2}{cmd:. tabplot health agegroup [w=freq] ,  percent(agegroup) showval subtitle(% of age group) xtitle("") bfcolor(none)}{p_end}

{p 4 4 2}Aitkin et al. (1989, p.242) reported
data from a survey of student opinion on the Vietnam War taken at the
University of North Carolina in Chapel Hill in May 1967. Students were
classified by sex, year of study, and the policy they supported, given choices
of 

{p 8 11 2} 
A. The United States should defeat the power of North Vietnam by widespread
bombing of its industries, ports, and harbors and by land invasion. 

{p 8 11 2} 
B. The United States should follow the present policy in Vietnam. 

{p 8 11 2} 
C. The United States should de-escalate its military activity, stop bombing
North Vietnam, and intensify its efforts to begin negotiation. 

{p 8 11 2} 
D. The United States should withdraw its military forces from Vietnam
immediately. 

{p 4 4 2} 
(They also report response rates [p.243], averaging 26% for males and 17% 
for females.) 

{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. input str6 sex str8 year str1 policy int freq}{p_end}
{p 4 8 2}{cmd:. "male"   "1"        "A" 175}{p_end}
{p 4 8 2}{cmd:. "male"   "1"        "B" 116}{p_end}
{p 4 8 2}{cmd:. "male"   "1"        "C" 131}{p_end}
{p 4 8 2}{cmd:. "male"   "1"        "D"  17}{p_end}
{p 4 8 2}{cmd:. "male"   "2"        "A" 160}{p_end}
{p 4 8 2}{cmd:. "male"   "2"        "B" 126}{p_end}
{p 4 8 2}{cmd:. "male"   "2"        "C" 135}{p_end}
{p 4 8 2}{cmd:. "male"   "2"        "D"  21}{p_end}
{p 4 8 2}{cmd:. "male"   "3"        "A" 132}{p_end}
{p 4 8 2}{cmd:. "male"   "3"        "B" 120}{p_end}
{p 4 8 2}{cmd:. "male"   "3"        "C" 154}{p_end}
{p 4 8 2}{cmd:. "male"   "3"        "D"  29}{p_end}
{p 4 8 2}{cmd:. "male"   "4"        "A" 145}{p_end}
{p 4 8 2}{cmd:. "male"   "4"        "B"  95}{p_end}
{p 4 8 2}{cmd:. "male"   "4"        "C" 185}{p_end}
{p 4 8 2}{cmd:. "male"   "4"        "D"  44}{p_end}
{p 4 8 2}{cmd:. "male"   "Graduate" "A" 118}{p_end}
{p 4 8 2}{cmd:. "male"   "Graduate" "B" 176}{p_end}
{p 4 8 2}{cmd:. "male"   "Graduate" "C" 345}{p_end}
{p 4 8 2}{cmd:. "male"   "Graduate" "D" 141}{p_end}
{p 4 8 2}{cmd:. "female" "1"        "A"  13}{p_end}
{p 4 8 2}{cmd:. "female" "1"        "B"  19}{p_end}
{p 4 8 2}{cmd:. "female" "1"        "C"  40}{p_end}
{p 4 8 2}{cmd:. "female" "1"        "D"   5}{p_end}
{p 4 8 2}{cmd:. "female" "2"        "A"   5}{p_end}
{p 4 8 2}{cmd:. "female" "2"        "B"   9}{p_end}
{p 4 8 2}{cmd:. "female" "2"        "C"  33}{p_end}
{p 4 8 2}{cmd:. "female" "2"        "D"   3}{p_end}
{p 4 8 2}{cmd:. "female" "3"        "A"  22}{p_end}
{p 4 8 2}{cmd:. "female" "3"        "B"  29}{p_end}
{p 4 8 2}{cmd:. "female" "3"        "C" 110}{p_end}
{p 4 8 2}{cmd:. "female" "3"        "D"   6}{p_end}
{p 4 8 2}{cmd:. "female" "4"        "A"  12}{p_end}
{p 4 8 2}{cmd:. "female" "4"        "B"  21}{p_end}
{p 4 8 2}{cmd:. "female" "4"        "C"  58}{p_end}
{p 4 8 2}{cmd:. "female" "4"        "D"  10}{p_end}
{p 4 8 2}{cmd:. "female" "Graduate" "A"  19}{p_end}
{p 4 8 2}{cmd:. "female" "Graduate" "B"  27}{p_end}
{p 4 8 2}{cmd:. "female" "Graduate" "C" 128}{p_end}
{p 4 8 2}{cmd:. "female" "Graduate" "D"  13}{p_end}
{p 4 8 2}{cmd:. end}{p_end}
{p 4 8 2}{cmd:. tabplot policy  year [w=freq], by(sex, subtitle(% by sex and year, place(w)) note("")) percent(sex year) showval}{p_end}


{title:Author} 

{p 4 4 2}Nicholas J. Cox, Durham University, U.K.{break} 
n.j.cox@durham.ac.uk


{title:Acknowledgments} 

{p 4 4 2}Bob Fitzgerald, Friedrich Huebler and Martyn Sherriff found
typos in this help. Friedrich also pointed to various efficiency issues.
Marcello Pagano provided encouragement and found a bug. Vince Wiggins
suggested how best to align x-axis labels when bars are horizontal. 
Jay Goodliffe suggested flagging use of the {cmd:subtitle()} option in
this help. 
 

{title:References} 

{p 4 8 2}Ager, D.V. 1963. 
{it:Principles of paleoecology: An introduction to the study of how and where animals and plants lived in the past.} 
New York: McGraw-Hill. See pp.187 
(citing unpublished work by B.W. Sparks), 206, 308. 

{p 4 8 2}Aitkin, M., D. Anderson, B. Francis, and J. Hinde. 1989.
{it:Statistical Modelling in GLIM.} Oxford: Oxford University Press

{p 4 8 2}Anderson, R.M. and May, R.M. 1991. 
{it:Infectious diseases of humans: dynamics and control.} 
Oxford: Oxford University Press. 

{p 4 8 2}Atkins, P.J. 2010. 
{it:Liquid materialities: A history of milk, science and the law.} 
Farnham: Ashgate. 

{p 4 8 2}Barber, D. 2012. 
{it:Bayesian reasoning and machine learning.} 
Cambridge: University Press.  

{p 4 8 2}Becker, R.A., J.M. Chambers, and A.R. Wilks. 1988. 
{it:The new S language: A programming environment for data analysis and graphics.} 
Pacific Grove, CA: Wadsworth and Brooks/Cole. 

{p 4 8 2}Bertin, J. 1981. 
{it:Graphics and graphic information-processing.} 
Berlin: Walter de Gruyter. 

{p 4 8 2}Bertin, J. 1983/2011. 
{it:Semiology of graphics: Diagrams, networks, maps.} 
Madison: University of Wisconsin Press; Redlands, CA: Esri Press. 

{p 4 8 2}Bishop, C.M. 2006.  
{it:Pattern recognition and machine learning.} 
New York: Springer. 

{p 4 8 2}Bradstreet, T.E. 2012.
Grables: Visual displays that combine the best attributes of graphs 
and tables. 
In Krause, A. and O'Connell, M. (Eds) 
{it:A picture is worth a thousand tables: Graphics in life sciences.} 
New York: Springer, 41{c -}69.  

{p 4 8 2}Brinton, W.C. 1939. 
{it:Graphic presentation.} 
New York: Brinton Associates. 
{browse "http://www.archive.org/stream/graphicpresentat00brinrich":http://www.archive.org/stream/graphicpresentat00brinrich} 

{p 4 8 2}Chapman, M. and Wykes, C. 1996. 
{it:Plain figures.} 
London: The Stationery Office. 

{p 4 8 2}Chauchat, J.-H. and Risson, A. 1998. 
Bertin's graphics and multidimensional data analysis. 
In Blasius, J. and Greenacre, M. (Eds) 
{it:Visualization of Categorical Data} 
San Diego, CA: Academic Press, 37{c -}45. 

{p 4 8 2}Cox, N.J. 2004. 
Graphing categorical and compositional data.
{it:Stata Journal} 4: 190{c -}215.

{p 4 8 2}Cox, N.J. 2007. 
Generating composite categorical variables. 
{it:Stata Journal} 7: 582{c -}583.

{p 4 8 2}Cox, N.J. 2008. 
Spineplots and their kin. 
{it:Stata Journal} 8: 105{c -}121.

{p 4 8 2}Cox, N.J. 2012. 
Axis practice, or what goes where on a graph. 
{it:Stata Journal} 12: 549{c -}561.

{p 4 8 2}de Falguerolles, A.,  Friedrich, F. and Sawitzki, G. 1997. 
A tribute to J. Bertin's graphical data analysis.
In Bandilla, W. and Faulbaum, F. (Eds) 
{it:Advances in Statistical Software 6.}
Stuttgart: Lucius and Lucius, 11{c -}20.
{browse "http://statlab.uni-hd.de/reports/by.series/beitrag.34.pdf":http://statlab.uni-hd.de/reports/by.series/beitrag.34.pdf}

{p 4 8 2}Doran, J.E. and Hodson, F.R. 1975. 
{it:Mathematics and computers in archaeology.} 
Edinburgh: Edinburgh University Press. 
See p.118. 

{p 4 8 2}Emeny, B. 1934. 
{it:The strategy of raw materials: A study of America in peace and war.} 
Cambridge, MA: Bureau of International Research, Harvard University 
and Radcliffe College. 

{p 4 8 2}Few, S. 2009. 
{it:Now you see it: Simple visualization techniques for quantitative analysis.} 
Oakland, CA: Analytics Press. 

{p 4 8 2}Few, S. 2012. 
{it:Show me the numbers: Designing tables and graphs to enlighten.} 
Burlingame, CA: Analytics Press.

{p 4 8 2}Few, S. 2015. 
{it:Signal: Understanding what matters in a world of noise.} 
Burlingame, CA: Analytics Press. 

{p 4 8 2}Gleick, P.H. (Ed.) 1993. 
{it:Water in crisis: A guide to the world's fresh water resources.} 
New York: Oxford University Press. 

{p 4 8 2}Greenacre, M. 2007. {it:Correspondence analysis in practice.} 
Boca Raton, FL: Chapman & Hall/CRC. 

{p 4 8 2}
Grinstein, G.G., Hoffman, P.E., Pickett, R.M. and Laskowski, S.J. 
2002. 
Benchmark development for the evaluation of visualization for data mining. 
In Fayyad, U., Grinstein, G.G. and Wierse, A. (Eds). 
{it:Information visualization in data mining and knowledge discovery.} 
San Francisco: Morgan Kaufmann, 129{c -}176. 

{p 4 8 2}Hahsler, M., Hornik, K. and Buchta, C. 2008. 
Getting things in order: an introduction to the R package seriation. 
{it:Journal of Statistical Software} 25(3) 
{browse "http://www.jstatsoft.org/v25/i03":http://www.jstatsoft.org/v25/i03}

{p 4 8 2}
Hink, J.K., Eustace, J.K. and Wogalter, M.S. 1998.
Do grables enable the extraction of quantitative information
better than pure graphs or tables?
{it:International Journal of Industrial Ergonomics} 22: 439{c -}447.

{p 4 8 2}
Hink, J.K., Wogalter, M.S. and Eustace, J.K. 1996. 
Display of quantitative information: 
Are grables better than plain graphs or tables? 
{it:Proceedings of the Human Factors and Ergonomics Society} 
40: 1155{c -}1159.

{p 4 8 2}Hoffman, P.E. and Grinstein, G.G. 2002. 
A survey of visualizations for high-dimensional data mining. 
In Fayyad, U., Grinstein, G.G. and Wierse, A. (Eds). 
{it:Information visualization in data mining and knowledge discovery.} 
San Francisco: Morgan Kaufmann, 47{c -}82. 

{p 4 8 2}Hofmann, H. 2008. 
Mosaic plots and their variants. 
In Chen, C., H{c a:}rdle, W. and Unwin, A. (Eds)
{it:Handbook of data visualization.} 
Berlin: Springer, 617{c -}642. 

{p 4 8 2}Koch, G.S. and Link, R.F. 1970. 
{it:Statistical analysis of geological data: Volume I.} 
New York: John Wiley. See p.271. 

{p 4 8 2}Lebart, L., Morineau, A. and Warwick, K.M. 1984.
{it:Multivariate descriptive statistical analysis: Correspondence analysis and related techniques for large matrices.}
New York: John Wiley. See p.50.

{p 4 8 2}Lockwood, A. 1969. 
{it:Diagrams: A visual survey of graphs, maps, charts and diagrams for the graphic designer.}
London: Studio Vista. 
See pp.27, 32, 45, 53, 61, 62.

{p 4 8 2}Lohninger, H. 1994. 
INSPECT: A program system to visualize and interpret chemical data.
{it:Chemometrics and Intelligent Laboratory Systems}
22: 147{c -}153.

{p 4 8 2}
Lohninger, H. 1996. 
{it:INSPECT: A program system for scientific and engineering data analysis: HANDBOOK with 2 diskettes.}
Berlin: Springer.

{p 4 8 2}MacKay, D.J.C. 2003. 
{it:Information theory, inference, and learning algorithms.} 
Cambridge: Cambridge University Press. 

{p 4 8 2}MacKay, D.J.C. 2008. 
{it:Sustainable energy {c -} without the hot air.}
Cambridge: UIT Cambridge.

{p 4 8 2}Mackinlay, J.D. 1986. 
Automating the design of graphical presentations of relational information. 
{it:ACM Transactions on Graphics} 
5: 111{c -}141. 

{p 4 8 2}McDaniel, E. and McDaniel, S. 2012a. 
{it:The accidental analyst: Show your data who's boss.}
Seattle, WA: Freakalytics.

{p 4 8 2}McDaniel, S. and McDaniel, E. 2012b. 
{it:Rapid graphs with Tableau 7: Create intuitive, actionable insights in just 15 days.}
Seattle, WA: Freakalytics.

{p 4 8 2}Merz, M. 2012.
(Interactive) graphics for biomarker assessment.                        
In Krause, A. and O'Connell, M. (Eds) 
{it:A picture is worth a thousand tables: Graphics in life sciences.} 
New York: Springer, 117{c -}138.  

{p 4 8 2}Mihalisin, T.W. 2002. 
Data warfare and multidimensional education. 
In Fayyad, U., Grinstein, G.G. and Wierse, A. (Eds). 
{it:Information visualization in data mining and knowledge discovery.} 
San Francisco: Morgan Kaufmann, 315{c -}344. 

{p 4 8 2}Morrison, P.S. 1985. 
Symbolic representation of tabular data. 
{it:New Zealand Journal of Geography} 79: 11{c -}18. 

{p 4 8 2}Murphy, K.P. 2012. 
{it:Machine learning: a probabilistic perspective.} 
Cambridge, MA: MIT Press. 

{p 4 8 2}Neurath, O. 1939. 
{it:Modern man in the making.} 
London: Secker and Warburg. See p.74.

{p 4 8 2}
Pirolli, P. and Rao, R. 1996. 
Table lens as a tool for making sense of data.
In Catarci, T., Costabilem, M.F., Levialdi, S. and Santucci, G. (Eds) 
{it:Workshop on Advanced Visual Interfaces: AVI-96.}
New York: Association for Computing Machinery, 67{c -}80.  

{p 4 8 2}Playfair, W. 1786. 
{it:The commercial and political atlas.} 
London: Debrett; Robinson; and Sewell. 

{p 4 8 2}Playfair, W. 2005. 
{it:The commercial and political atlas and Statistical breviary.} 
(eds. Wainer, H. and Spence, I.) 
Cambridge: Cambridge University Press.  

{p 4 8 2}
Rao, R. and Card, S.K. 1994.
The table lens: merging graphical and symbolic representations in an interactive focus+context visualization for tabular information. 
{it:Proceedings of CHI '94, ACM Conference on Human Factors in Computing Systems}
New York: Association for Computing Machinery, 318{c -}322 and 481{c -}482.  

{p 4 8 2}Rogers, A.C. 1961. 
{it:Graphic charts handbook.} 
Washington, DC: Public Affairs Press. 

{p 4 8 2}
Rumelhart, D.E., Hinton, G.E. and Williams, R.J. 
1986. 
Learning representations by back-propagating errors. 
{it:Nature} 323: 533{c -}536. 

{p 4 8 2}
Sarkar, D. 2008. 
{it:Lattice: Multivariate data visualization with R.}
New York: Springer. 

{p 4 8 2}Sears, P.B. 1933. 
Climatic change as a factor in forest succession.
{it:Journal of Forestry} 31: 934{c -}942.

{p 4 8 2}Sears, P.B. 1935.  
Types of North American pollen profiles. 
{it:Ecology} 16: 488{c -}499.

{p 4 8 2}
Spence, R. 2007. 
{it:Information visualization: Design for interaction.} 
Harlow, Essex: Pearson Education. 

{p 4 8 2}
Stouffer, S.A., Suchman, E.A., DeVinney, L., Star, S.A. and Williams, R.M. 
1949a. 
{it:The American soldier: Adjustment during army life.}
Princeton, NJ: Princeton University Press. 

{p 4 8 2}
Stouffer, S.A., Lumsdaine, A.A., Lumsdaine, M.H., Williams, R.M., Smith, M.B.,
Janis, I.L.  Star, S.A.  and Cottrell, L.S.  1949b. 
{it:The American soldier: Combat and its aftermath.}
Princeton, NJ: Princeton University Press. 

{p 4 8 2}
Theus, M. and Urbanek, S. 2009. 
{it:Interactive graphics for data analysis: Principles and examples.} 
Boca Raton, FL: CRC Press. 

{p 4 8 2}
Unwin, A. 2015. 
{it:Graphical data analysis with R.}
Boca Raton, FL: CRC Press. 

{p 4 8 2}
Unwin, A., Theus, M. and Hofmann, H. 2006.  
{it:Graphics of large datasets: Visualizing a million.}
New York: Springer. 

{p 4 8 2}
Valiela, I. 2001. 
{it:Doing science: Design, analysis, and communication of scientific research.} 
New York: Oxford University Press. 

{p 4 8 2}Wainer, H. 2005. 
{it:Graphic discovery: A trout in the milk and other visual adventures.} 
Princeton, NJ: Princeton University Press. 

{p 4 8 2}Wainer, H. 2009. 
{it:Picturing the uncertain world: How to understand, communicate, and control uncertainty through graphical display.} 
Princeton, NJ: Princeton University Press. 

{p 4 8 2}Ward, M., Grinstein, G. and Keim, D. 2010. 
{it:Interactive data visualization: Foundations, techniques, and applications.} 
Natick, MA: A K Peters. 

{p 4 8 2}
Wilkinson, L. 2005. 
{it:The grammar of graphics.}
New York: Springer. 


{title:Also see} 

{p 4 13 2}
On-line: help for {help twoway_rbar:twoway rbar}, {help histogram}, 
{help catplot} (if installed), {help spineplot} (if installed)  

