{smcl}
{* 30nov2022/10dec2022}{...}
{hline}
help for {hi:upsetplot}
{hline}

{title:Euler or Venn diagrams mapped to bar charts, upsetplot style} 

{p 8 12 2}
{cmd:upsetplot} 
{it:varlist}
[{it:weight}]
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]{break} 
[
{cmd:,}
{opt fillin}
{opt percent}
{opt pcformat(str)}
{break}
{opt varlabels}
{opt sep:arator(str)}
{opt gsort(str)}   
{opt baropts(str)}  
{opt labelopts(str)}  
{opt matrixopts(str)}  
{opt spikeopts(str)}
{it:graph_options}  
{break}
{opt savedata(filespec)} 
]

{p 4 4 2}{cmd:fweight}s and {cmd:aweight}s may be specified. 


{title:Description}

{p 4 4 2}
{cmd:upsetplot} produces a bar chart alternative to Euler or Venn
diagrams showing the frequencies (or more generally abundances) of
subsets of observations as defined jointly by a bundle of numeric
indicator variables. The plot resembles what have been called UpSetPlots
elsewhere. 

{p 4 4 2}
The order of variables presented to {cmd:upsetplot} affects the order of
subsets in the plot and in the associated dataset, but not which subsets
are defined. If any indicator represents an outcome or response, it
might well be specified first. 

{p 4 4 2}
Commonly, but not necessarily, subset frequencies (or abundances) are
already in a variable in the dataset. If so, that variable should be
specified as frequency or analytic weights. If no weights are specified,
{cmd:upsetplot} counts observations for you. Either way, note that the
focus of this command is on displaying frequencies or abundances, and
not the particular values in each subset.  

{p 4 4 2}
The display uses various subcommands of {helpb graph twoway}.  The most
distinctive feature is a matrix- or table-like legend below the bar
chart with marker symbols shown on each row whenever any indicator is 1
in a subset. Correspondingly, absence of a marker symbol implies that
that indicator is 0 in that subset. Each row is labelled by a variable
name or optionally by a variable label. In either case, variable name or
variable label, short text is desirable. Vertical spikes connecting
uppermost and lowermost marker symbols are added. 

{p 4 4 2}
The reduced dataset used by {cmd:upsetplot} may be saved for future work
using the {cmd:savedata()} option. This dataset may be as useful as or
more useful than the plot.  Saving results allows greater flexibility in
plotting.  Tabulation or other reporting is also made easier.  Results
often need to be scaled in some way, e.g. by looking at conditional
proportions or percents.  (Optionally, percents can be saved too.) 

{p 4 4 2}
The variables in such a reduced dataset are the original indicator
variables and as follows. The names here may thus not be used as names
for the indicator variables specified. 

{p 8 8 2}
{cmd:_binary} is a string variable containing a binary code such as
{cmd:"00"}, {cmd:"01"}, {cmd:"10"} or {cmd:"11"}. 

{p 8 8 2}
{cmd:_decimal} is a numeric variable containing a decimal equivalent
such as {cmd:0}, {cmd:1}, {cmd:2} or {cmd:3}.

{p 8 8 2}
{cmd:_text} is a string variable containing a description of each subset
using variable names or optionally variable labels.  The text
{cmd:"<none>"} is reported for any subset which would otherwise have
empty text. 

{p 8 8 2}
{cmd:_count} is a numeric variable containing the count (frequency) of
occurrence of each subset. If analytic weights were specified, values
may have fractional parts.                                

{p 8 8 2}
(Optionally) {cmd:_percent} is a numeric variable containing the percent
occurrence of each subset. 

{p 8 8 2}
{cmd:_degree} is a numeric variable indicating the degree of each subset
(number of participating sets), counted as true (1) according to each
indicator variable. 

{p 8 8 2}
{cmd:_set} is a string variable that indicates each set using its
variable name or optionally its variable label. 

{p 8 8 2}
{cmd:_setfreq} is a numeric variable that indicates the frequency of
each set. 

{p 8 8 2} 
{cmd:_set} and {cmd:_setfreq} are physically but not logically aligned
with the other variables mentioned above. 

{p 8 8 2}
Allenby and Slomson (2011, p.14) comment: "There is, unfortunately, no
standard notation for the number of elements in a set". They could have
added "and no standard term either". Terms encountered (other than
"number of elements") include cardinality, order, potency, power, and
the homely size. See annotations of several references. 

{p 4 4 2}
More detailed Remarks, including many further references, follow later
in this help. 


{title:Options}

{p 0 0 2}{it:What to show}

{p 4 4 2}
{cmd:fillin} insists on showing subsets that do not occur with their
frequency or abundance zero. This can be helpful if there are only a few
such subsets, but not usually otherwise.

{p 4 4 2}
{cmd:percent} specifies listing and plotting of percents rather than
counts (frequencies}. 

{p 4 4 2}
{cmd:pcformat()} specifies a display format for percents in listings and
plots. The default is {cmd:%2.1f}.  This option has no effect without
{cmd:percent}.


{p 0 0 2}{it:Detail of display}

{p 4 4 2}
{cmd:varlabels} specifies use of variable labels to describe each
subset.  The default is to use variable names. In either case, only
variables taking on value 1 in each subset are named or labelled. If a
variable label has not been defined, the variable name is used instead.  

{p 4 4 2}
{cmd:separator()} specifies a string to separate variable names or, as
above, variable labels in calculating {cmd:_text}. The default is
{cmd:", "}, a comma followed by a space. Hint: the intersection symbol
can be obtained using {cmd:"{c -(}&cap{c )-}"}. Such SMCL notation will
be interpreted on graphs, but will appear uninterpreted in data
listings.  This option has no bearing on the graph produced by
{cmd:upsetplot}, but is explained here for symmetry with the help for
{helpb vennbar}. 

{p 4 4 2}
{cmd:gsort()} specifies instructions to {helpb gsort} on the order of
bars, mentioning one or more variable names for sorting the display.
The variable(s) named must be included in the reduced dataset as defined
above and should be one or more of the following:  

    {cmd:_binary}
    {cmd:_decimal}
    {cmd:_text} 
    {cmd:_count}
    {cmd:_percent} (if specified) 
    {cmd:_degree} 

{p 4 4 2} 
The default is to sort on the frequency or abundance variable
{cmd:_count} created by the command, highest values first.  

{p 4 4 2}
{cmd:axisgap()} specifies a gap between the {it:x} axis and the first
row of the legend. The default is (the maximum value of
{cmd:_count})/100.  After the command has run the value used is
accessible as local macro {cmd:axisgap}. 

{p 4 4 2}
{cmd:vargap()} specifies the gap between each row in the legend. The
default is (the maximum value of {cmd:_count})/25. After the command has
run the value used is accessible as local macro {cmd:vargap}. 

{p 4 4 2}
{cmd:baropts()} are options of {helpb twoway bar} used to tune the
rendering of bars. The defaults include
{cmd:yla(, ang(h)) barw(0.8) xsc(off)}. 

{p 4 4 2}
{cmd:labelopts()} are options of {helpb twoway scatter} used to tune the
rendering of text labels showing frequencies above each bar. The
defaults are 
{cmd:ms(none) mlabc(black) mla(_count) mlabpos(12) mlabsize(small)}. 

{p 4 4 2}
{cmd:matrixopts()} are options of {helpb twoway scatter} used to tune
the matrix- or table-like legend. The defaults include
{cmd:ymla(, ang(h) noticks) legend(off) aspect(0.8) ms(O T D S + X)}
and marker colours as defined by Okabe and Ito (2008) (on which see e.g. 
Wong (2011) or Wilke (2019)). 

{p 8 8 2}
Note that something like {cmd:matrixopts(ms(O ..) mc(gs8 ..))} would 
get you closer to conforming with a widespread if unimaginative convention.   

{p 4 4 2}
{cmd:spikeopts()} are options of {helpb twoway rspike} used to tune the
spikes connecting markers in the legend. The default is {cmd:lc(gs8)}.  

{p 4 4 2}
{it:graph_options} are other options of {help graphb}. An example might be 
{cmd:name()}. Note that {cmd:graph} may not be especially smart 
about any space needed above the highest bar label, so you may need 
two passes and a call to {cmd:yscale()} to extend the axis.


{p 0 0 2}{it:Saving results as new dataset} 

{p 4 4 2}
{cmd:savedata()} specifies a (filepath and) filename for saving results to
a new dataset.  The specification may include {cmd:, replace} {c -}
which is needed to replace any existing dataset with the same path and
name. 


{title:Examples}

{p 4 8 2}{cmd:. local bcolour lcolor(blue) fcolor(blue*0.3)}{p_end}
{p 4 8 2}{cmd:. set more off}{p_end}
{p 4 8 2}{cmd:. set scheme s1color}{p_end}

{p 4 8 2}{cmd:. * EXAMPLE 1}{p_end}
{p 4 8 2}{cmd:. * Schnable et al. 2009 counts of gene families}{p_end}

{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. input Rice Maize Sorghum Arabidopsis freq}{p_end}
{p 4 8 2}{cmd:1 0 0 0 1110}{p_end}
{p 4 8 2}{cmd:1 1 0 0 229}{p_end}
{p 4 8 2}{cmd:0 1 0 0 465}{p_end}
{p 4 8 2}{cmd:1 0 1 0 661}{p_end}
{p 4 8 2}{cmd:1 1 1 0 2077}{p_end}
{p 4 8 2}{cmd:0 1 1 0 405}{p_end}
{p 4 8 2}{cmd:0 0 1 0 265}{p_end}
{p 4 8 2}{cmd:1 0 1 1 304}{p_end}
{p 4 8 2}{cmd:1 1 1 1 8494}{p_end}
{p 4 8 2}{cmd:0 1 1 1 112}{p_end}
{p 4 8 2}{cmd:0 0 1 1 34}{p_end}
{p 4 8 2}{cmd:1 0 0 1 81}{p_end}
{p 4 8 2}{cmd:1 1 0 1 96}{p_end}
{p 4 8 2}{cmd:0 1 0 1 11}{p_end}
{p 4 8 2}{cmd:0 0 0 1 1058}{p_end}
{p 4 8 2}{cmd:end}{p_end}

{p 4 8 2}{cmd:. label var Arabidopsis "{c -(}it:Arabidopsis{c )-}"}{p_end}
{p 4 8 2}{cmd:. local toptitle  "t1title(Number of gene families)"}{p_end}

{p 4 8 2}{cmd:. upsetplot A R M S [fw=freq], varlabels  baropts(`toptitle' `bcolour') name(UP1, replace)}{p_end}

{p 4 8 2}{cmd:. upsetplot A R M S [fw=freq], varlabels  baropts(`toptitle' `bcolour') gsort(_decimal) name(UP2, replace)}{p_end}

{p 4 8 2}{cmd:. upsetplot A R M S [fw=freq], varlabels gsort(_degree -_count) baropts(`toptitle' `bcolour') name(UP3, replace)}{p_end}

{p 4 8 2}{cmd:. upsetplot A R M S [fw=freq], varlabels gsort(-_degree -_count) baropts(`toptitle' `bcolour') name(UP4, replace)}{p_end}

{p 4 8 2}{cmd:. tempfile schnable}{p_end}
 
{p 4 8 2}{cmd:. upsetplot A R M S [fw=freq], varlabels gsort(-_degree -_count) baropts(`toptitle' `bcolour') savedata("`schnable'")}{p_end}

{p 4 8 2}{cmd:. use "`schnable'", clear}{p_end}

{p 4 8 2}{cmd:. graph hbar (asis) _setfreq, over(_set, sort(1)) bar(1, `bcolour') blabel(bar) ysc(off) `toptitle' name(UP5, replace)}{p_end}

{p 4 8 2}{cmd:. * EXAMPLE 2}{p_end}
{p 4 8 2}{cmd:. * D'Hont et al. 2012}{p_end}

{p 4 8 2}{cmd:. clear}{p_end}
{p 4 8 2}{cmd:. input byte(Phoenix Musa Brachypodium Sorghum Oryza Arabidopsis) float freq str52 name}{p_end}
{p 4 8 2}{cmd:1 1 1 1 1 1 7674 "Phoenix Musa Brachypodium Sorghum Oryza Arabidopsis"}{p_end}
{p 4 8 2}{cmd:1 1 1 1 1 0  685 "Phoenix Musa Brachypodium Sorghum Oryza"            }{p_end}
{p 4 8 2}{cmd:1 1 1 1 0 1  113 "Phoenix Musa Brachypodium Sorghum Arabidopsis"      }{p_end}
{p 4 8 2}{cmd:1 1 1 1 0 0   24 "Phoenix Musa Brachypodium Sorghum"                  }{p_end}
{p 4 8 2}{cmd:1 1 1 0 1 1   80 "Phoenix Musa Brachypodium Oryza Arabidopsis"        }{p_end}
{p 4 8 2}{cmd:1 1 1 0 1 0   18 "Phoenix Musa Brachypodium Oryza"                    }{p_end}
{p 4 8 2}{cmd:1 1 1 0 0 1    7 "Phoenix Musa Brachypodium Arabidopsis"              }{p_end}
{p 4 8 2}{cmd:1 1 1 0 0 0   12 "Phoenix Musa Brachypodium"                          }{p_end}
{p 4 8 2}{cmd:1 1 0 1 1 1  149 "Phoenix Musa Sorghum Oryza Arabidopsis"             }{p_end}
{p 4 8 2}{cmd:1 1 0 1 1 0   62 "Phoenix Musa Sorghum Oryza"                         }{p_end}
{p 4 8 2}{cmd:1 1 0 1 0 1   23 "Phoenix Musa Sorghum Arabidopsis"                   }{p_end}
{p 4 8 2}{cmd:1 1 0 1 0 0   19 "Phoenix Musa Sorghum"                               }{p_end}
{p 4 8 2}{cmd:1 1 0 0 1 1   28 "Phoenix Musa Oryza Arabidopsis"                     }{p_end}
{p 4 8 2}{cmd:1 1 0 0 1 0   35 "Phoenix Musa Oryza"                                 }{p_end}
{p 4 8 2}{cmd:1 1 0 0 0 1  206 "Phoenix Musa Arabidopsis"                           }{p_end}
{p 4 8 2}{cmd:1 1 0 0 0 0  467 "Phoenix Musa"                                       }{p_end}
{p 4 8 2}{cmd:1 0 1 1 1 1  258 "Phoenix Brachypodium Sorghum Oryza Arabidopsis"     }{p_end}
{p 4 8 2}{cmd:1 0 1 1 1 0  190 "Phoenix Brachypodium Sorghum Oryza"                 }{p_end}
{p 4 8 2}{cmd:1 0 1 1 0 1   11 "Phoenix Brachypodium Sorghum Arabidopsis"           }{p_end}
{p 4 8 2}{cmd:1 0 1 1 0 0   23 "Phoenix Brachypodium Sorghum"                       }{p_end}
{p 4 8 2}{cmd:1 0 1 0 1 1    5 "Phoenix Brachypodium Oryza Arabidopsis"             }{p_end}
{p 4 8 2}{cmd:1 0 1 0 1 0   12 "Phoenix Brachypodium Oryza"                         }{p_end}
{p 4 8 2}{cmd:1 0 1 0 0 1    3 "Phoenix Brachypodium Arabidopsis"                   }{p_end}
{p 4 8 2}{cmd:1 0 1 0 0 0   25 "Phoenix Brachypodium"                               }{p_end}
{p 4 8 2}{cmd:1 0 0 1 1 1   21 "Phoenix Sorghum Oryza Arabidopsis"                  }{p_end}
{p 4 8 2}{cmd:1 0 0 1 1 0   42 "Phoenix Sorghum Oryza"                              }{p_end}
{p 4 8 2}{cmd:1 0 0 1 0 1    4 "Phoenix Sorghum Arabidopsis"                        }{p_end}
{p 4 8 2}{cmd:1 0 0 1 0 0   49 "Phoenix Sorghum"                                    }{p_end}
{p 4 8 2}{cmd:1 0 0 0 1 1    6 "Phoenix Oryza Arabidopsis"                          }{p_end}
{p 4 8 2}{cmd:1 0 0 0 1 0   32 "Phoenix Oryza"                                      }{p_end}
{p 4 8 2}{cmd:1 0 0 0 0 1  105 "Phoenix Arabidopsis"                                }{p_end}
{p 4 8 2}{cmd:1 0 0 0 0 0  769 "Phoenix"                                            }{p_end}
{p 4 8 2}{cmd:0 1 1 1 1 1 1458 "Musa Brachypodium Sorghum Oryza Arabidopsis"        }{p_end}
{p 4 8 2}{cmd:0 1 1 1 1 0  368 "Musa Brachypodium Sorghum Oryza"                    }{p_end}
{p 4 8 2}{cmd:0 1 1 1 0 1   54 "Musa Brachypodium Sorghum Arabidopsis"              }{p_end}
{p 4 8 2}{cmd:0 1 1 1 0 0   13 "Musa Brachypodium Sorghum"                          }{p_end}
{p 4 8 2}{cmd:0 1 1 0 1 1   29 "Musa Brachypodium Oryza Arabidopsis"                }{p_end}
{p 4 8 2}{cmd:0 1 1 0 1 0   28 "Musa Brachypodium Oryza"                            }{p_end}
{p 4 8 2}{cmd:0 1 1 0 0 1    7 "Musa Brachypodium Arabidopsis"                      }{p_end}
{p 4 8 2}{cmd:0 1 1 0 0 0    9 "Musa Brachypodium"                                  }{p_end}
{p 4 8 2}{cmd:0 1 0 1 1 1   71 "Musa Sorghum Oryza Arabidopsis"                     }{p_end}
{p 4 8 2}{cmd:0 1 0 1 1 0   64 "Musa Sorghum Oryza"                                 }{p_end}
{p 4 8 2}{cmd:0 1 0 1 0 1   21 "Musa Sorghum Arabidopsis"                           }{p_end}
{p 4 8 2}{cmd:0 1 0 1 0 0   49 "Musa Sorghum"                                       }{p_end}
{p 4 8 2}{cmd:0 1 0 0 1 1   13 "Musa Oryza Arabidopsis"                             }{p_end}
{p 4 8 2}{cmd:0 1 0 0 1 0   29 "Musa Oryza"                                         }{p_end}
{p 4 8 2}{cmd:0 1 0 0 0 1  155 "Musa Arabidopsis"                                   }{p_end}
{p 4 8 2}{cmd:0 1 0 0 0 0  759 "Musa"                                               }{p_end}
{p 4 8 2}{cmd:0 0 1 1 1 1  206 "Brachypodium Sorghum Oryza Arabidopsis"             }{p_end}
{p 4 8 2}{cmd:0 0 1 1 1 0 2809 "Brachypodium Sorghum Oryza"                         }{p_end}
{p 4 8 2}{cmd:0 0 1 1 0 1   14 "Brachypodium Sorghum Arabidopsis"                   }{p_end}
{p 4 8 2}{cmd:0 0 1 1 0 0  402 "Brachypodium Sorghum"                               }{p_end}
{p 4 8 2}{cmd:0 0 1 0 1 1   18 "Brachypodium Oryza Arabidopsis"                     }{p_end}
{p 4 8 2}{cmd:0 0 1 0 1 0  547 "Brachypodium Oryza"                                 }{p_end}
{p 4 8 2}{cmd:0 0 1 0 0 1   10 "Brachypodium Arabidopsis"                           }{p_end}
{p 4 8 2}{cmd:0 0 1 0 0 0  387 "Brachypodium"                                       }{p_end}
{p 4 8 2}{cmd:0 0 0 1 1 1   40 "Sorghum Oryza Arabidopsis"                          }{p_end}
{p 4 8 2}{cmd:0 0 0 1 1 0 1151 "Sorghum Oryza"                                      }{p_end}
{p 4 8 2}{cmd:0 0 0 1 0 1    9 "Sorghum Arabidopsis"                                }{p_end}
{p 4 8 2}{cmd:0 0 0 1 0 0  827 "Sorghum"                                            }{p_end}
{p 4 8 2}{cmd:0 0 0 0 1 1    6 "Oryza Arabidopsis"                                  }{p_end}
{p 4 8 2}{cmd:0 0 0 0 1 0 1246 "Oryza"                                              }{p_end}
{p 4 8 2}{cmd:0 0 0 0 0 1 1187 "Arabidopsis"                                        }{p_end}
{p 4 8 2}{cmd:0 0 0 0 0 0    . ""                                                   }{p_end}
{p 4 8 2}{cmd:end}{p_end}

{p 4 8 2}{cmd:. local toptitle  "t1title(Number of gene families)"}{p_end}

{p 4 8 2}{cmd:. upsetplot P-A [w=freq], baropts(`toptitle' `bcolour' ysc(r(. 8500))) labelopts(mlabang(v) mlabpos(1) mlabsize(vsmall)) name(UP6, replace)}{p_end}

{p 4 8 2}{cmd:. * EXAMPLE 3}{p_end}
{p 4 8 2}{cmd:. * incidence of missing values in nlswork.dta}{p_end}

{p 4 8 2}{cmd:. webuse nlswork, clear}{p_end}

{p 4 8 2}{cmd:. * missings from Stata Journal: search dm0085, entry}{p_end}
{p 4 8 2}{cmd:. capture noisily missings report}{p_end}

{p 4 8 2}{cmd:. foreach v in ind_code union wks_ue tenure wks_work {c -(}}{p_end}
{p 4 8 2}{cmd:. {space 4}gen M`v' = missing(`v')}{p_end}
{p 4 8 2}{cmd:. {space 4}label var M`v' "`v'"}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. local toptitle  "t1title(Number of missing values)"}{p_end}

{p 4 8 2}{cmd:. upsetplot M*, varlabels baropts(`toptitle' `bcolour') name(UP7, replace)}{p_end}

{p 4 8 2}{cmd:. upsetplot M* if missing(ind_code, union, wks_ue, tenure, wks_work), varlabels baropts(`toptitle' `bcolour') gsort(_degree -_count) name(UP8, replace)}{p_end}

{p 4 8 2}{cmd:. * EXAMPLE 4}{p_end}
{p 4 8 2}{cmd:. * various indicators in nlswork.dta}{p_end}

{p 4 8 2}{cmd:. webuse nlswork, clear}{p_end}
{p 4 8 2}{cmd:. local toptitle "t1title(Number of people)"}{p_end}

{p 4 8 2}{cmd:. upsetplot nev_mar c_city collgrad south, baropts(`toptitle' `bcolour') name(UP9, replace)}{p_end}

{p 4 8 2}{cmd:. label var nev_mar "never married"}{p_end}
{p 4 8 2}{cmd:. label var c_city "central city"}{p_end}
{p 4 8 2}{cmd:. label var collgrad "college graduate"}{p_end}
{p 4 8 2}{cmd:. label var south "South"}{p_end}

{p 4 8 2}{cmd:. upsetplot nev_mar c_city collgrad south, varlabels baropts(`toptitle' `bcolour') name(UP10, replace)}{p_end}


{title:Authors}

{p 4 4 2}Tim Morris, MRC Clinical Trials Unit, University College London{break} 
tim.morris@ucl.ac.uk

{p 4 4 2}Nicholas J. Cox, Durham University{break}
n.j.cox@durham.ac.uk


{title:Also see}

{p 4 4 2}Help for{break}
{help groups} ({it:Stata Journal}) (if installed){break}
{help vennbar} (if installed){break}
{help jaccard} (if installed)


{title:Remarks} 

{p 4 4 2}
{cmd:upsetplot} requires a bundle of numeric variables with values 0 or
1.  Such variables are variously called indicator, dummy, binary,
dichotomous, zero-one, Boolean, logical or quantal. Missing values will
be ignored.  Otherwise presenting values other than 0 or 1 is considered
an error.  Observations used will thus have all values 0 or 1 in all
variables specified.  Differently put, {cmd:upsetplot} is not for string
variables or categorical variables that have 3 or more distinct values. 

{p 4 4 2}
If your dataset is already aggregated to frequencies or other measures
of abundance, specify those as weights multiplying the indicator
variables.

{p 4 4 2}
Consider two such indicators. The concatenations 00, 01, 10 and 11
define the 4 possible subsets defined by those variables, and also
distinct binary codes for binary numbers 00 to 11, and also distinct
decimal equivalents 0 to 3. Otherwise put, concatenation is here a
simple and natural way to define composite categorical variables (Cox
2007). 00 is of degree 0, 01 and 10 are of degree 1, and 11 is of degree
2. Here, and indeed generally, leading zeros are retained as helpful 
reminders even though they might be considered redundant or ornamental. 

{p 4 4 2}
Similarly, three such variables have eight possible binary
concatenations 000, 001, 010, 011, 100, 101, 110, 111 and decimal
equivalents 0 to 7. More generally, {it:k} such variables define
2^{it:k} possible subsets. 

{p 4 4 2}
The elementary but fundamental idea of representing true (or present) as
1 and false (or absent) as 0 has a splendid history.  Although it has
yet longer roots, the idea was strongly developed by George Boole
(1815{c -}1864): Boole (1854) was his major work in this territory, on
which see particularly Grattan-Guinness (2005).  Boole has been given a
full-length biography (MacHale 2014) and an even longer sequel (MacHale
and Cohen 2018). For shorter accounts see Gardner (1969), Broadbent (1970), 
MacHale (2000, 2008), Heath and Seneta (2001), or Grattan-Guinness (2004). 
See (e.g.) Dewdney (1993) or Gregg (1998) for samples of how such Boolean
algebra features in computing.  See Knuth (1998, Ch.4.1) for an excellent
historical summary of positional number systems and Knuth (2011) for a masterly
synopsis, including historical material, of related combinatorial algorithms.
See Strickland and Lewis (2022) for a focus on binary arithmetic and logic in
the work of Leibniz (1646{c -}1716). The leading biography of Leibniz is by
Antognazza (2009), although the earlier biography by Aiton (1985) is still very
helpful. Leibniz's projects feature in many sub-plots in Stephenson (2003) and
its sequels. Cox (2016) makes further Stata-related comments on truth,
falsity, and indication.  Cox and Schechter (2019) survey the creation of
indicator variables in Stata. 

{p 4 4 2}
Various commentators, from Leibniz onward, have seen anticipations
of bimary arithmetic in the divination manual {it:I Ching} ({it:Yijing}, {it:Yi Jing},
{it:Yi King}, etc.). That seems exaggerated. See Gardner (1974} for a brisk
discussion and Knuth (2011) and Strickland and Lewis (2022) for further comments.  

{p 4 4 2}
For 2 or 3 variables Euler or Venn diagrams annotated with subset
frequencies (or other information) are relatively easy to draw and
sometimes to understand, but even for 4 or 5 variables they are harder
to draw and even harder to understand.  For say {it:k} = 5, 2^5 = 32,
which poses a challenge to show data intelligibly.  For say {it:k} = 10,
2^10 = 1024, which is often far too many subsets to work with
simultaneously.  However, the problem may be eased in practice if many
of the possible subsets do not occur, or occur so rarely that they can
be ignored. For modest values of {it:k}, bar charts may be a competitive
alternative, which is the idea implemented here.  

{p 4 4 2}
This {cmd:upsetplot} command was stimulated by what have been called
UpSetPlots. (Presentations and implementations show some variety in use
of upper or lower case and over whether the name is given with an extra
space.) See Lex (2021), Lex and Gehlenberg (2014), Lex {it:et al.}
(2014), Conway {it:et al.} (2017), and Ballarini {it:et al.}
(2020). Lex (2022) explains the origin of
the name as a play on "set" and because he was "upset" by Venn diagram
alternatives in the literature (e.g. D'Hont {it:et al.} 2012).  The idea
that Venn diagrams are better replaced by bar chart alternatives is
older (e.g. Kosara 2007) and indeed implicit in any decision to use bar
charts when researchers are aware of Venn diagrams.  The assertion "I
would argue that Venn diagrams are a great tool for learning about sets,
but useless as a visualization" (Kosara 2007) is unfortunately supported
by many examples in various literatures. 

{p 4 4 2}
Venn diagrams are widely familiar in mathematics and science and indeed
as a cultural meme echoed in cartoons, T-shirt or mug designs, and much
else.  Christianson (2012) mentioned Venn diagrams as one of 
{it:100 diagrams that changed the world}.  Friendly introductions to set
theory featuring Venn diagrams include Stewart (1975) and Gullberg
(1997).  Conversely, compare Hamming (1985, p.367): "Set theory has been
taught until the typical student is weary of it, so we will assume that
it is familiar." Beyond their original and continuing use in logic, Venn
diagrams are commonly used in introductions to probability: see (e.g.)
Pitman (1993), Whittle (2000), Dekking {it:et al.} (2005), Miller
(2017), or Blitzstein and Hwang (2019).  Historically and to the present
set theory is linked to much fundamental work in logic, number theory,
and other parts of mathematics (Bagaria 2008; various chapters in
Grattan-Guinness 1994; Stillwell 2010).  

{p 4 4 2}
For the history of Venn and related diagrams, see Baron (1969), Gardner
(1982), Edwards (2004), Moktefi and Shin (2012), and Bennett (2015).
Wainer and Friendly (2021, pp.102{c -}103) flag the use of an
area-proportional Venn-like diagram by Playfair (1801, opp.p.48).
Wilkinson (2012) covers some more recent work on drawing
area-proportional plots from a statistical point of view. Macfarlane
(1885, 1890) referred to composite categories laid out in sequence as
the logical spectrum.

{p 4 4 2}
Venn (1880a, 1880b, 1880c, 1881, 1894) made explicit that the diagrams
later named after him grew out of earlier work. Indeed, few logicians
were as fully aware of previous contributions. Thus the name exemplifies
Stigler's Law (1980, 1999) that "No scientific discovery is named after
its original discoverer". The injustice is partially corrected by
crediting Euler's earlier work (1768), on which see conveniently
Sandifer (2007) or Bennett (2015).  A distinction is often drawn (e.g.
Mollerup 2015, p.166) that Venn diagrams show all possible combinations,
while Euler diagrams only show actual combinations.  However, Euler's
contribution in turn was preceded by yet earlier work by Leibniz and
several other scholars.  Nevertheless, crediting Euler or Venn is fair
and there is no point to suggesting yet another term when both terms are
so well established. 

{p 4 4 2}
John Venn (1834{c -}1923) now benefits from a full-length biography
(Verbugt 2022). For shorter appreciations, see Broadbent (1976),
Grattan-Guinness (2001), or Gibbins (2004). Grattan-Guinness (2011)
places the work of Boole and Venn in context, surveying the development
of logic in 19th century Britain. Venn's interest in probability and 
statistics was profound: see especially his first book {it:The Logic of Chance} 
(1866, 1876, 1888) and a still useful review paper on averages (Venn 1891). 

{p 4 4 2}
Leonhard Euler (1707{c -}1783) is also well served by a full-length
biography (Calinger 2016).  See also Calinger, Denisova and Polyakhova
(2019) on what in English is known as {it:Letters to a German Princess}.
For a concise overview of some of his mathematical achievements, see
Dunham (1999). For a shorter although still detailed account, see
Youschkevitch (1971).  For a very concise account, see Sandifer (2008).  

{p 4 4 2}
For implementations of Venn diagrams in Stata, see Lauritsen (1999a,
1999b, 1999c, 2000, 2009), Gong and Osterman (2011), and Over (2022).


{title:References}

{p 4 8 2}Aiton, E.J. 1985. 
{it:Leibniz: A Biography.} 
Bristol: Adam Hilger.

{p 4 8 2}
Allenby, R.B.J.T. and A. Slomson. 2011. 
{it:How to Count: An Introduction to Combinatorics.} 
Boca Raton, FL: CRC Press. 

{p 4 8 2}
Antognazza, M.R. 2009. 
{it:Leibniz: An Intellectual Biography.} 
New York: Cambridge University Press. 

{p 4 8 2}
Bagaria, J. 2008. 
Set theory.
In Gowers, T. (ed.) 
{it:The Princeton Companion to Mathematics.} 
Princeton, NJ: Princeton University Press, 615{c -}634.

{p 4 8 2}
Ballarini, N.M., Y-D. Chiu, F. K{c o:}nig, M. Posch, and T. Jaki. 
2020. 
A critical review of graphics for subgroup analyses in clinical trials. 
{it:Pharmaceutical Statistics} 19: 541{c -}560. 
{browse "https://doi.org/10.1002/pst.2012":https://doi.org/10.1002/pst.2012}

{p 4 8 2}
Baron, M.E. 1969. 
A note on the historical development of logic diagrams: Leibniz, Euler
and Venn. 
{it:The Mathematical Gazette} 
53: 113{c -}125. doi:10.2307/3614533

{p 4 8 2}
Bennett, D. 2015.
Origins of the Venn diagram. 
In Zack, M. and E. Landry (eds) 
{it:Research in History and Philosophy of Mathematics.} 
New York: Springer, 105{c -}120. 
{browse "https://logic-teaching.github.io/pred/texts/Bennett%202015%20-%20Origins%20of%20the%20Venn%20Diagram.pdf":https://logic-teaching.github.io/pred/texts/Bennett%202015%20-%20Origins%20of%20the%20Venn%20Diagram.pdf}

{p 4 8 2}
Biggs, N.L. 2002. 
{it:Discrete Mathematics.} 
Oxford: Oxford University Press. 
p.48 size, cardinality 

{p 4 8 2}
Blitzstein, J.K. and J. Hwang. 2019.
{it:Introduction to Probability.} 
Boca Raton, FL: CRC Press. 

{p 4 8 2}
Boole, G. 1854. 
{it:An Investigation of the Laws of Thought on Which are Founded the Mathematical Theories of Logic and Probabilities.}
London: Walton and Maberley; Cambridge: Macmillan. 

{p 4 8 2}
Broadbent, T.A.A. 1970. 
Boole, George. 
In Gillispie, C.C. (ed.} {it:Dictionary of Scientific Biography.} 
New York: Charles Scribner's Sons 2: 293{c -}298.

{p 4 8 2}
Broadbent, T.A.A. 1976. 
Venn, John. 
In Gillispie, C.C. (ed.} {it:Dictionary of Scientific Biography.} 
New York: Charles Scribner's Sons 13: 611{c -}613.

{p 4 8 2}
Calinger, R.S. 2016. 
{it:Leonhard Euler: Mathematical Genius in the Enlightenment.} 
Princeton, NJ: Princeton University Press. 

{p 4 8 2}
Calinger, R.S., E. Denisova and E.N. Polyakhova. 2019. 
{it: Leonhard Euler's Letters to a German Princess: A Milestone in the History of Physics Textbooks and More.} 
San Rafaei, CA: Morgan & Claypool. 

{p 4 8 2}
Cameron, P.J. 1994. 
{it:Combinatorics: Topics, Techniques, Algorithms.} 
Cambridge: Cambridge University Press. 
p.16 cardinality  

{p 4 8 2}
Christianson, S. 2012. 
{it:100 Diagrams That Changed the World: From the Earliest Cave Paintings to the Innovation of the iPod.}
New York: Penguin. 

{p 4 8 2}
Conway, J.R., A. Lex and N. Gehlenborg. 2017. 
UpSetR: An R package for the
visualization of intersecting sets and their properties.
{it:Bioinformatics} 33: 2938{c -}2940. doi:10.1093/bioinformatics/btx364.

{p 4 8 2}
Cox, N.J. 2007. 
Stata tip 52: Generating composite categorical variables. 
{it:Stata Journal} 7: 582{c -}583.     

{p 4 8 2}
Cox, N.J. 2016. 
Truth, falsity, indication, and negation. 
{it:Stata Journal} 16: 229{c -}236. 

{p 4 8 2}
Cox, N.J. 2017. 
Tables as lists: The groups command. 
{it:Stata Journal} 17: 760{c -}773.  

{p 4 8 2}
Cox, N.J. 2018. 
Software update: Tables as lists: The groups command. 
{it:Stata Journal} 18: 291. 

{p 4 8 2}
Cox, N.J. and C.B. Schechter. 2019. 
How best to generate indicator or dummy variables. 
{it:Stata Journal} 19: 246{c -}259. 

{p 4 8 2}
Crossley, J.N., J. Ash, C.J. Brickhill, J.C. Stillwell and N.H.
Williams. 1972. 
{it:What is Mathematical Logic?} 
London: Oxford University Press.
p.69 cardinality 

{p 4 8 2}
Dekking, F.M., C. Kraikamp, H.P. Lopuha{c a:} and L.E. Meester. 2005. 
{it:A Modern Introduction to Probability and Statistics.} 
London: Springer. 

{p 4 8 2}
Dewdney, A.K. 1993. 
{it:The New Turing Omnibus: 66 Excursions in Computer Science.} 
New York: Henry Holt. 

{p 4 8 2}
D'Hont, A. and many authors. 2012. 
The banana ({it:Musa acuminata}) genome and the evolution of monocotyledonous plants. 
{it:Nature} 488: 213{c -}217. https://doi.org/10.1038/nature11241 

{p 4 8 2}
Dunham, W. 1999. 
{it:Euler: The Master of Us All.} 
Washington, DC: Mathematical Association of America. 

{p 4 8 2}
Edwards, A.W.F. 2004. 
{it:Cogwheels of the Mind: The Story of Venn Diagrams.} 
Baltimore: Johns Hopkins University Press. 

{p 4 8 2}
Euler, L. 1768. 
{it:Lettres {c a'g} Une Princesse d'Allemagne sur Divers Sujets de Physique & de Philosophie.} Tome second.
Saint Petersbourg: L'Acad{c e'}mie Imp{c e'}riale des Sciences. 

{p 4 8 2}
Friendly, M. and H. Wainer. 2021. 
{it:A History of Data Visualization and Graphic Communication.} 
Cambridge, MA: Harvard University Press. 

{p 4 8 2}
Gardner, M. 1969.
Boolean algebra, Venn diagrams and the propositional calculus. 
{it:Scientific American} 220(2): 110{c -}114.
{browse "https://www.jstor.org/stable/pdf/24926287.pdf":https://www.jstor.org/stable/pdf/24926287.pdf}
Reprinted as Boolean algebra in 1979.
{it:Mathematical Circus.} New York: Alfred A. Knopf, 87{c -}101. 

{p 4 8 2}
Gardner, M. 1974.
The combinatorial basis of the "I Ching," the Chinese book of divination and wisdom. 
{it:Scientific American} 230(1): 108{c -}113. 
{browse "https://www.jstor.org/stable/pdf/24949988.pdf":https://www.jstor.org/stable/pdf/24949988.pdf} 
Reprinted as The {it:I Ching} in 
1986. {it:Knotted Doughnuts and other Mathematical Entertainments.} 
New York: W.H. Freeman, 243{c -}256.

{p 4 8 2}
Gardner, M. 1982. 
{it:Logic Machines and Diagrams.} 
Chicago: University of Chicago Press.

{p 4 8 2}
Gibbins, J.R. 2004. 
Venn, John. 
In Matthew, H.C.G. and B. Harrison (eds)
{it:Oxford Dictionary of National Biography.}
Oxford: Oxford University Press 56: 259{c -}260. 

{p 4 8 2}
Gong, W. and J. Ostermann. 2011.
pvenn: module to create proportional Venn diagram.
http://fmwww.bc.edu/RePEc/bocode/p
[accessed 20 September 2022] 

{p 4 8 2}
Graham, R.L., D.E. Knuth and O. Patashnik. 1994.
{it:Concrete Mathematics: A Foundation for Computer Science.} 
Reading, MA: Addison-Wesley.
p.xi cardinality  

{p 4 8 2}
Grattan-Guinness, I. (ed.) 1994.  
{it:Companion Encyclopedia of the History and Philosophy of the Mathematical Sciences.} 
London: Routledge.

{p 4 8 2}
Grattan-Guinness, I. 2001. 
John Venn. 
In Heyde, C.C. and E. Seneta (eds) 
{it:Statisticians of the Centuries.} 
New York: Springer, 194{c -}196. 
 
{p 4 8 2}
Grattan-Guinness, I. 2004. 
Boole, George. 
In Matthew, H.C.G. and B. Harrison (eds)
{it:Oxford Dictionary of National Biography.}
Oxford: Oxford University Press 6: 582{c -}585. 

{p 4 8 2}
Grattan-Guinness, I. 2005. 
George Boole, 
{it:An Investigation of the Laws of Thought on Which are Founded the Mathematical Theories of Logic and Probabilities} (1854). 
In Grattan-Guinness, I. (ed.) 
{it:Landmark Writings in Western Mathematics 1640{c -}1940.} 
Amsterdam: Elsevier, 470{c -}479. 

{p 4 8 2}
Grattan-Guinness, I. 2011. 
Victorian logic: From Whately to Russell. 
In Flood, R., A. Rice and R. Wilson (eds) 
{it:Mathematics in Victorian Britain.} 
Oxford: Oxford University Press, 359{c -}374. 

{p 4 8 2}
Green, J.A. 1965. 
{it:Sets and Groups.} 
London: Routledge and Kegan Paul. 
p.2 order [of a finite set] 

{p 4 8 2}
Green, J.A. 1988. 
{it:Sets and Groups: A First Course in Algebra.}
London: Chapman & Hall. 
p.2 order [of a finite set]  

{p 4 8 2}
Gregg, J.R. 1998. 
{it:Ones and Zeros: Understanding Boolean Algebra, Digital Circuits, and the Logic of Sets.} 
Piscataway, NJ: IEEE Press. 

{p 4 8 2}
Grimmett, G.R. and D.R. Stirzaker. 2020. 
{it:Probability and Random Processes.} 
Oxford: Oxford University Press.
p.6 cardinality

{p 4 8 2}
Gullberg, J. 1997. 
{it:Mathematics: From the Birth of Numbers.} 
New York: W.W. Norton. 

{p 4 8 2}
Hamming, R.W. 1985. 
{it:Methods of Mathematics Applied to Calculus, Probability, and Statistics.} 
Englewood Cliffs, NJ: Prentice-Hall.

{p 4 8 2}
Heath, P. and E. Seneta. 2001. 
George Boole. 
In Heyde, C.C. and E. Seneta (eds) 
{it:Statisticians of the Centuries.} 
New York: Springer, 167{c -}170.  

{p 4 8 2}
Ito, K. (ed.) 1987. 
{it:Encyclopedic Dictionary of Mathematics.} 
Cambridge, MA: MIT Press. [macron accent on o of Ito] 
potency, power 

{p 4 8 2}
James, G. and R.C. James. 1992. 
{it:Mathematics Dictionary.} 
New York: Van Nostrand Reinhold. 
potency, power 

{p 4 8 2}
Knuth, D.E. 1997. 
{it:The Art of Computer Programming: Volume 1: Fundamental Algorithms.} 
Reading, MA: Addison-Wesley. 
p.625 cardinality

{p 4 8 2}
Knuth, D.E. 1998. 
{it:The Art of Computer Programming: Volume 2: Seminumerical Algorithms.}
Reading, MA: Addison-Wesley.  

{p 4 8 2}
Knuth, D.E. 2011. 
{it:The Art of Computer Programming: Volume 4A: Combinatorial Algorithms, Part 1.}  
Upper Saddle River, NJ: Addison-Wesley. 

{p 4 8 2}
Kosara, R. 2007. 
Autism diagnosis accuracy {c -} Visualization redesign. 
{browse "https://eagereyes.org/criticism/autism-diagnosis-accuracy":https://eagereyes.org/criticism/autism-diagnosis-accuracy} 
[accessed 20 September 2022] 

{p 4 8 2}
Lauritsen, J.M. 1999a.
Drawing Venn diagrams.
{it:Stata Technical Bulletin} 47: 3{c -}8.

{p 4 8 2}
Lauritsen, J.M. 1999b.
Drawing Venn diagrams.
{it:Stata Technical Bulletin} 48: 3.

{p 4 8 2}
Lauritsen, J.M. 1999c.
Drawing Venn diagrams.
{it:Stata Technical Bulletin} 49: 8.

{p 4 8 2}
Lauritsen, J.M. 2000.
An update to drawing Venn diagrams.
{it:Stata Technical Bulletin} 54: 17{c -}19.

{p 4 8 2}
Lauritsen, J.M. 2009. 
venndiag: module to generate Venn diagrams. 
http://fmwww.bc.edu/RePEc/bocode/v
[accessed 20 September 2022]

{p 4 8 2}
Lex, A. 2021. UpSet: Visualizing intersecting sets. 
{browse "https://upset.app/":https://upset.app/} 
[accessed 20 September 2022] 

{p 4 8 2}
Lex, A. 13 September 2022. 
{browse "https://mobile.twitter.com/alexander_lex/status/1569741352417787905": https://mobile.twitter.com/alexander_lex/status/1569741352417787905} 
[accessed 20 September 2022] 

{p 4 8 2}
Lex, A. and N. Gehlenborg. 2014. 
Sets and intersections. 
{it:Nature Methods} 11: 779. doi:10.1038/nmeth.3033

{p 4 8 2}
Lex, A., N. Gehlenborg, H. Strobelt, R. Vuillemot and H. Pfister. 2014. 
UpSet: Visualization of intersecting sets.  
{it:IEEE Transactions on Visualization and Computer Graphics} 20: 
1983{c -}1992. doi:10.1109/TVCG.2014.2346248/ 

{p 4 8 2}
Liebeck, M. 2016.
{it:A Concise Introduction to Pure Mathematics.}
Boca Raton, FL: CRC Press. 
p.195 cardinality

{p 4 8 2}
Macfarlane, A. 1885.
The logical spectrum. 
{it:The London, Edinburgh, and Dublin Philosophical Magazine and Journal of Science} 
Series 5, 19 (119): 286{c -}290. 
doi:10.1080/14786448008626877. 

{p 4 8 2}
Macfarlane, A. 1890. 
Adaption of the method of the logical spectrum to Boole's problem.
{it:Proceedings of the American Association of the Advancement of Science} 
39: 57{c -}60.

{p 4 8 2}
MacHale, D. 2000.
George Boole 1815{c -}1864. 
In Houston, K.  (ed.)
{it:Creators of Mathematics: The Irish Connection.} 
Dublin: University College Dublin Press, 27{c -}32.  

{p 4 8 2}
MacHale, D. 2008. 
George Boole. 
In Gowers, T. (ed.) 
{it:The Princeton Companion to Mathematics.} 
Princeton, NJ: Princeton University Press, 769{c -}770. 
 
{p 4 8 2}
MacHale, D. 2014. 
{it:The Life and Work of George Boole: A Prelude to the Digital Age.} 
Cork: Cork University Press.

{p 4 8 2}
MacHale, D. and Y. Cohen. 2018. 
{it:New Light on George Boole.} 
Cork: Cork University Press.

{p 4 8 2}
Miller, S.J. 2017.
{it:The Probability Lifesaver: All the Tools You Need to Understand Chance.} 
Princeton, NJ: Princeton University Press. 

{p 4 8 2}
Moktefi, A. and S.-J. Shin. 2012. 
A history of logic diagrams. 
In Gabbay, D.M., F.J. Pelletier and J. Woods (eds) 
{it:Handbook of the History of Logic. Volume 11: Logic: A History of Its Central Concepts.} 
Amsterdam: North-Holland, 611{c -}682.

{p 4 8 2}
Mollerup, P. 
2015. 
{it:Data Design: Visualizing Quantities, Locations, Connections.} 
London: Bloomsbury. 

{p 4 8 2}
Okabe, M. and K. Ito. 2008. 
Color Universal Design (CUD): How to make figures and presentations that are friendly to colorblind people. 
{browse "http://jfly.uni-koeln.de/color/":http://jfly.uni-koeln.de/color/}

{p 4 8 2}
Over, M. 2022. 
pvenn2: Proportional Venn diagram, enhanced version of pvenn. 
{browse "http://digital.cgdev.org/doc/stata/MO/Misc":http://digital.cgdev.org/doc/stata/MO/Misc}
[accessed 20 September 2022]

{p 4 8 2}
Pitman, J. 1993. 
{it:Probability.} 
New York: Springer.

{p 4 8 3}
Playfair, W. 1801.
{it:The Statistical Breviary.} 
London: Wallis etc.  
 
{p 4 8 2}
Sandifer, C.E. 2007. 
{it:How Euler Did It.}
Washington, DC: Mathematical Association of America.
 
{p 4 8 2}
Sandifer, C.E. 2008. 
Leonhard Euler. 
In Gowers, T. (ed.) 
{it:The Princeton Companion to Mathematics.} 
Princeton, NJ: Princeton University Press, 747{c -}749.

{p 4 8 2} 
Schnable, P.S. and many co-authors. 2009. 
The B73 maize genome: complexity, diversity, and dynamics. 
{it:Science} 326: 1112{c -}1115. 
http://www.jstor.org/stable/27736489

{p 4 8 2}
Stephenson, N. 2003. 
{it:Quicksilver: Volume One of the Baroque Cycle.} 
New York: William Morrow.  

{p 4 8 2}
Stewart, I. 1975. 
{it:Concepts of Modern Mathematics.}
Harmondsworth: Penguin.

{p 4 8 2}
Stigler, S.M. 1980. 
Stigler's law of eponymy. 
{it:Transactions of the New York Academy of Sciences} 
39: 147{c -}158. doi:10.1111/j.2164-0947.1980.tb02775.x

{p 4 8 2}
Stigler, S.M. 1999. 
{it:Statistics on the Table: The History of Statistical Concepts and Methods.} 
Cambridge, MA: Harvard University Press.  

{p 4 8 2}
Stillwell, J. 2010. 
{it:Mathematics and Its History.} 
New York: Springer. 

{p 4 8 2}
Strickland, L. and H.R. Lewis. 2022. 
{it:Leibniz on Binary: The Invention of Computer Arithmetic.} 
Cambridge, MA: MIT Press. 

{p 4 8 2}
Venn, J. 1866, 1876, 1888. 
{it:The Logic of Chance.} 
London: Macmillan.

{p 4 8 2}
Venn, J. 1880a. 
On the forms of logical proposition. 
{it:Mind} 5(19): 336{c -}349. 

{p 4 8 2}
Venn, J. 1880b. 
On the diagrammatic and mechanical representation of propositions and reasonings. 
{it:The London, Edinburgh, and Dublin Philosophical Magazine and Journal of Science} 
Series 5, 10 (59): 1{c -}18. 
doi:10.1080/14786448008626877. 

{p 4 8 2}
Venn, J. 1880c.
On the employment of geometrical diagrams for the sensible
representation of logical propositions. 
{it:Transactions of the Cambridge Philosophical Society} 
4: 47{c -}59. 

{p 4 8 2}
Venn, J. 1881, 1894. 
{it:Symbolic Logic.}
London: Macmillan.

{p 4 8 2}
Venn, J. 1891. 
On the nature and uses of averages. 
{it:Journal of the Royal Statistical Society}
52: 429{c -}456.

{p 4 8 2}
Verbugt, L.M. 2022. 
{it:John Venn: A Life in Logic.} 
Chicago: University of Chicago Press. 

{p 4 8 2}
Whittle, P. 2000. 
{it:Probability via Expectation.} 
New York: Springer. 

{p 4 8 2}
Wilke, C.O. 2019. 
{it:Fundamentals of Data Visualization: A Primer on Making Informative and Compelling Figures.}
Sebastopol, CA: O'Reilly. 

{p 4 8 2}
Wilkinson, L. 2012.
Exact and approximate area-proportional circular Venn and Euler
diagrams.
{it:IEEE Transactions on Visualization and Computer Graphics}
18: 321{c -}331. doi:10.1109/TVCG.2011.56

{p 4 8 2}
Wong, B. 2011. Color blindness. {it:Nature Methods} 8: 441.
{browse "https://www.nature.com/articles/nmeth.1618.pdf":https://www.nature.com/articles/nmeth.1618.pdf}

{p 4 8 2}
Youschkevitch, A.P. 1971. 
Euler, Leonhard. 
In Gillispie, C.C. (ed.} {it:Dictionary of Scientific Biography.} 
New York: Charles Scribner's Sons 4: 467{c -}484.

{p 4 8 2}
Zeitz, P. 2007. 
{it:The Art and Craft of Problem Solving.} 
Hoboken, NJ: John Wiley. 
p.147 cardinality


{title:Bibliographic note on Martin Gardner's columns} 

{p 4 4 2}
Martin Gardner's columns on "Mathematical games" over many years in
{it:Scientific American} covered much more than games and puzzles and
included many splendid expositions of topics with mathematical content.
They present a variety of small bibliographical challenges. The original
articles will be accessible to many readers at jstor.org, but typically
under the titles "Mathematical Games". A further tiny detail is that
pagination starts afresh in each issue of {it:Scientific American}, so
volume and issue number together are needed for an exact citation. The
columns were collected later in book form, often revised and/or
retitled, in books that themselves often varied in publisher and even
title over various reprints and reissues. A project to publish further
revised editions, under yet other titles, from Cambridge University
Press and the Mathematical Association of America, released its first
four volumes between 2008 and 2014, but appears to have stalled. At the
time of writing it had not reached the books mentioned here. 

{p 4 4 2} 
{browse "https://en.wikipedia.org/wiki/List_of_Martin_Gardner_Mathematical_Games_columns":https://en.wikipedia.org/wiki/List_of_Martin_Gardner_Mathematical_Games_columns} 
and 
{browse "https://ansible.uk/misc/mgardner.html":https://ansible.uk/misc/mgardner.html} 
will help you find what you are looking for or indeed to determine 
whether a relevant column was ever written.

