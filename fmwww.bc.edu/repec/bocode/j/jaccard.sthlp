{smcl}
{* 30nov2022}{...}
{hline}
help for {hi:jaccard}
{hline}

{title:Jaccard similarity or dissimilarity of sets} 

{p 8 12 2}
{cmd:jaccard} 
{it:varlist}
[{it:weight}]
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}]{break} 
[
{cmd:,}
{c -(} 
{opt complement}
|
{opt count} 
{c )-}  
{opt upper}
{opt lower}
{opt diag:onal}
{opt varlabels}
{it:graph_options} 
{opt savedata(filespec)} 
]

{p 4 4 2}{cmd:fweight}s and {cmd:aweight}s may be specified. 


{title:Description}

{p 4 4 2}
{cmd:jaccard} calculates the Jaccard measure of similarity of two or
more sets, or its complement, and plots results in a tabular bar chart.
Set membership is specified by a bundle of indicator variables. 
Optionally, the count in each intersection may be plotted instead. 

{p 4 4 2}
For sets {it:A}, {it:B} the number of elements in their intersection
|{it:A} intersection {it:B}| is divided by the number of elements in
their union |{it:A} union {it:B}| to give a measure between 0 ({it:A}
and {it:B} are disjoint) and 1 ({it:A} and {it:B} are identical). Here
|.| indicating number of elements may be a count or some other measure
of abundance. 

{p 8 8 2}
Note: SMCL supports display on graphs of the standard cap and cup symbols for
intersection and union, but they will not show up in help files. See
{helpb text}. 

{p 4 4 2}
The order of variables presented to {cmd:jaccard} affects the order of
sets in the plot and in the associated dataset. 

{p 4 4 2}
Commonly, but not necessarily, subset frequencies (or abundances) are
already in a variable in the dataset and so that variable should be
specified as frequency or analytic weights. If no weights are specified,
{cmd:jaccard} counts observations for you. Either way, note that the
focus of this command is on displaying similarity or dissimilarity of
sets, and not the particular observations in each subset.  

{p 4 4 2}
The display uses {helpb tabplot} (Cox 2016b, 2017, 2020, 2022), which
must be installed separately.  Each row and column are labelled by
variable names or optionally by variable labels. In either case,
variable names or variable labels, short text is desirable. 

{p 4 4 2}
The code uses {helpb labmask} (Cox 2008), which must be installed
separately. 

{p 4 4 2}
The reduced dataset used by {cmd:jaccard} may be saved for future work
using the {cmd:savedata()} option. This dataset may be as useful as or
more useful than the plot.  Saving results allows greater flexibility in
plotting. Tabulation or other reporting is also made easier. 

{p 4 4 2}
The variables in such a reduced dataset are as follows. 

{p 8 8 2}
{cmd:_name1} and {cmd:_name2} are string variables containing the
original variable names or variable labels.

{p 8 8 2}
{cmd:_which1} and {cmd:_which2} are numeric variables with value labels
from the original variable names or variable labels.

{p 8 8 2}
{cmd:_inter} is a numeric variable measuring the frequency or abundance
of each intersection.  

{p 8 8 2}
{cmd:_union} is a numeric variable measuring the frequency or abundance
of each union.  

{p 8 8 2}
{cmd:_Jaccard} is a numeric variable containing the Jaccard measure or
its complement.

{p 8 8 2}
Allenby and Slomson (2011, p.14) comment: "There is, unfortunately, no
standard notation for the number of elements in a set". They could have
added "and no standard term either". Terms encountered (other than
"number of elements") include cardinality, order, potency, power, and
the homely size. See annotations of several references. 

{p 4 4 2}
More detailed Remarks, including many further references, follow later in
this help. 


{title:Options}

{p 4 8 2}
{cmd:complement} specifies calculating 1 minus the usual Jaccard
measure, as a measure of dissimilarity. 

{p 4 8 2}
{cmd:count} specifies plotting the intersection counts (more generally,
abundances) rather than 
the Jaccard measure or its complement. 

{p 8 8 2}
{cmd:complement} and {cmd:count} may not be combined. 

{p 4 8 2}
{cmd:upper} specifies display of the upper half of the bar matrix.

{p 4 8 2}
{cmd:lower} specifies display of the lower half of the bar matrix.

{p 4 8 2}
{cmd:diagonal} specifies display of the diagonal of the bar matrix.

{p 8 8 2}The three options above may be combined. The default is
{cmd:lower}.

{p 4 4 2}
{cmd:varlabels} specifies use of variable labels to describe each set.
The default is to use variable names. If a variable label has not been
defined, the variable name is used instead.  

{p 4 4 2}
{it:graph_options} are other options of {help tabplot}.  Defaults
include {cmd:xtitle("") ytitle("") aspect(1)}.  

{p 4 4 2}
{cmd:savedata()} specifies a (filepath and) filename for saving results
to a new dataset.  The specification may include {cmd:, replace} {c -}
which is needed to replace any existing dataset with the same path and
name. 


{title:Saved results} 

{p 4 4 2}
The {cmd:tabplot} command used is saved in local macro {cmd:graph_cmd}
in the program's space. 


{title:Examples}

{p 4 8 2}{cmd:. local opts showval(format(%5.4f)) lcolor(blue) fcolor(blue*0.3)}{p_end}
{p 4 8 2}{cmd:. set more off }{p_end}
{p 4 8 2}{cmd:. set scheme s1color }{p_end}

{p 4 8 2}{cmd:. * EXAMPLE 1 }{p_end}
{p 4 8 2}{cmd:. * Schnable et al. 2009 counts of gene families }{p_end}

{p 4 8 2}{cmd:. clear }{p_end}
{p 4 8 2}{cmd:. input Rice Maize Sorghum Arabidopsis freq }{p_end}
{p 4 8 2}{cmd:1 0 0 0 1110}{p_end}
{p 4 8 2}{cmd:1 1 0 0 229}{p_end}
{p 4 8 2}{cmd:0 1 0 0 465 }{p_end}
{p 4 8 2}{cmd:1 0 1 0 661}{p_end}
{p 4 8 2}{cmd:1 1 1 0 2077 }{p_end}
{p 4 8 2}{cmd:0 1 1 0 405 }{p_end}
{p 4 8 2}{cmd:0 0 1 0 265}{p_end}
{p 4 8 2}{cmd:1 0 1 1 304}{p_end}
{p 4 8 2}{cmd:1 1 1 1 8494}{p_end}
{p 4 8 2}{cmd:0 1 1 1 112}{p_end}
{p 4 8 2}{cmd:0 0 1 1 34}{p_end}
{p 4 8 2}{cmd:1 0 0 1 81}{p_end}
{p 4 8 2}{cmd:1 1 0 1 96}{p_end}
{p 4 8 2}{cmd:0 1 0 1 11}{p_end}
{p 4 8 2}{cmd:0 0 0 1 1058 }{p_end}
{p 4 8 2}{cmd:end }{p_end}

{p 4 8 2}{cmd:. label var Arabidopsis "{c -(}it:Arabidopsis{c )-}"}{p_end}

{p 4 8 2}{cmd:. jaccard A R M S [fw=freq], `opts' varlabels frame(1) name(JC1, replace)}{p_end}

{p 4 8 2}{cmd:. jaccard A R M S [fw=freq], `opts' varlabels lower diagonal frame(1) name(JC2, replace)}{p_end}

{p 4 8 2}{cmd:. jaccard A R M S [fw=freq], `opts' varlabels lower diagonal complement frame(1) name(JC3, replace)}{p_end}

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

{p 4 8 2}{cmd:. jaccard P-A [w=freq], `opts' frame(1) name(JC4, replace) xla(, labsize(small)) yla(, labsize(small))  }{p_end}

{p 4 8 2}{cmd:. * EXAMPLE 3 }{p_end}
{p 4 8 2}{cmd:. * incidence of missing values in nlswork.dta }{p_end}

{p 4 8 2}{cmd:. webuse nlswork, clear}{p_end}

{p 4 8 2}{cmd:. * missings from Stata Journal: search dm0085, entry}{p_end}
{p 4 8 2}{cmd:. capture noisily missings report }{p_end}

{p 4 8 2}{cmd:. foreach v in ind_code union wks_ue tenure wks_work {c -(}}{p_end}
{p 4 8 2}{cmd:. {space 4}gen M`v' = missing(`v')}{p_end}
{p 4 8 2}{cmd:. {space 4}label var M`v' "`v'"}{p_end}
{p 4 8 2}{cmd:. {c )-}}{p_end}

{p 4 8 2}{cmd:. jaccard M*, `opts' varlabels name(JC5, replace)}{p_end}

{p 4 8 2}{cmd:. jaccard M*, `opts' varlabels complement name(JC6, replace)}{p_end}

{p 4 8 2}{cmd:. * EXAMPLE 4}{p_end}
{p 4 8 2}{cmd:. * various indicators in nlswork.dta }{p_end}

{p 4 8 2}{cmd:. webuse nlswork, clear }{p_end}

{p 4 8 2}{cmd:. jaccard nev_mar c_city collgrad south, `opts' name(JC7, replace)}{p_end}

{p 4 8 2}{cmd:. label var nev_mar "never married"}{p_end}
{p 4 8 2}{cmd:. label var c_city "central city"}{p_end}
{p 4 8 2}{cmd:. label var collgrad "college graduate"}{p_end}
{p 4 8 2}{cmd:. label var south "South"}{p_end}

{p 4 8 2}{cmd:. jaccard nev_mar c_city collgrad south, `opts' varlabels name(JC8, replace)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, University of Durham{break}
n.j.cox@durham.ac.uk


{title:Acknowledgment} 

{p 4 4 2}
Tim Morris made several helpful suggestions.


{title:Also see}

{p 4 4 2}Help for{break}
{help groups} ({it:Stata Journal}) (if installed){break}
{help upsetplot} (if installed){break}
{help vennbar} (if installed)


{title:Remarks} 

{p 4 4 2}
{cmd:jaccard} requires a bundle of numeric variables with values 0 or 1.
Such variables are variously called indicator, dummy, binary,
dichotomous, zero-one, Boolean, logical or quantal.  Values other than 0
or 1, including missing values, will be ignored. Observations used will
thus have all values 0 or 1 in all variables specified. Otherwise put,
{cmd:jaccard} is not for arbitrary categorical variables which may have
3 or more distinct values, except in so far as they are represented by a
set of such indicator variables. 

{p 4 4 2}
If your dataset is already aggregated to frequencies or other measures
of abundance, specify those as weights multiplying the indicator
variables.

{p 4 4 2}
The elementary but fundamental idea of representing true (or present) as
1 and false (or absent) as 0 has a splendid history.  Although it has
yet longer roots, the idea was strongly developed by George Boole
(1815{c -}1864): Boole (1854) was his major work in this territory, on
which see particularly Grattan-Guinness (2005).  Boole has been given a
full-length biography (MacHale 2014) and an even longer sequel (MacHale
and Cohen 2018). For shorter accounts see Gardner (1969), Broadbent
(1970), MacHale (2000, 2008), Heath and Seneta (2001), or
Grattan-Guinness (2004). See (e.g.) Dewdney (1993) or Gregg (1998) for
samples of how such Boolean algebra features in computing.  See Knuth
(1998, Ch.4.1) for an excellent historical summary of positional number
systems and Knuth (2011) for a masterly synopsis, including historical
material, of related combinatorial algorithms.  See Strickland and Lewis
(2022) for a focus on binary arithmetic and logic in the work of Leibniz
(1646{c -}1716). The leading biography of Leibniz is by Antognazza
(2009), although the earlier biography by Aiton (1985) is still very
helpful. Leibniz's projects feature in many sub-plots in Stephenson
(2003) and its sequels.  Cox (2016a) makes further Stata-related
comments on truth, falsity, and indication.  Cox and Schechter (2019)
survey the creation of indicator variables in Stata. 

{p 4 4 2}
Friendly introductions to set theory include Stewart (1975) and Gullberg
(1997).  Conversely, compare Hamming (1985, p.367): "Set theory has been
taught until the typical student is weary of it, so we will assume that
it is familiar." Historically and to the present set theory is linked to
much fundamental work in logic, number theory, and other parts of
mathematics (Bagaria 2008; various chapters in Grattan-Guinness 1994;
Stillwell 2010).  

{p 4 4 2}
For more on Jaccard and the Jaccard measure, see [MV] measure_option and
its references. There is no immediate ambition to extend this command to
other measures in this territory.


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
Biggs, N.L. 2002. 
{it:Discrete Mathematics.} 
Oxford: Oxford University Press. 
p.48 size, cardinality 

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
Cameron, P.J. 1994. 
{it:Combinatorics: Topics, Techniques, Algorithms.} 
Cambridge: Cambridge University Press. 
p.16 cardinality  

{p 4 8 2} 
Cox, N.J. 2008. 
Between tables and graphs. 
{it:Stata Journal} 8: 269{c-}289.

{p 4 8 2}
Cox, N.J. 2016a. 
Truth, falsity, indication, and negation. 
{it:Stata Journal} 16: 229{c -}236. 

{p 4 8 2}
Cox, N.J. 2016b.
Multiple bar charts in table form. 
{it:Stata Journal} 16: 491{c -}510. 

{p 4 8 2}
Cox, N.J. 2017. 
Multiple bar charts in table form. 
{it:Stata Journal} 17: 779.  

{p 4 8 2}
Cox, N.J. 2020. 
Multiple bar charts in table form. 
{it:Stata Journal} 20: 757. 

{p 4 8 2}
Cox, N.J. 2022. 
Multiple bar charts in table form. 
{it:Stata Journal} 22: 467. 

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
Dewdney, A.K. 1993. 
{it:The New Turing Omnibus: 66 Excursions in Computer Science.} 
New York: Henry Holt. 

{p 4 8 2}
D'Hont, A. and many authors. 2012. 
The banana ({it:Musa acuminata}) genome and the evolution of monocotyledonous plants. 
{it:Nature} 488: 213{c -}217. https://doi.org/10.1038/nature11241 

{p 4 8 2}
Gardner, M. 1969.
Boolean algebra, Venn diagrams and the propositional calculus. 
{it:Scientific American} 220(2): 110{c -}114.
{browse "https://www.jstor.org/stable/pdf/24926287.pdf":https://www.jstor.org/stable/pdf/24926287.pdf}
Reprinted as Boolean algebra in 1979.
{it:Mathematical Circus.} New York: Alfred A. Knopf, 87{c -}101.

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
Liebeck, M. 2016.
{it:A Concise Introduction to Pure Mathematics.}
Boca Raton, FL: CRC Press. 
p.195 cardinality

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
Stillwell, J. 2010. 
{it:Mathematics and Its History.} 
New York: Springer. 

{p 4 8 2}
Strickland, L. and H.R. Lewis. 2022. 
{it:Leibniz on Binary: The Invention of Computer Arithmetic.} 
Cambridge, MA: MIT Press. 

{p 4 8 2}
Zeitz, P. 2007. 
{it:The Art and Craft of Problem Solving.} 
Hoboken, NJ: John Wiley. 
p.147 cardinality

