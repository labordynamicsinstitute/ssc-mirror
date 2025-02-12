{smcl}
{* 10feb2025}{...}
{cmd:help myrank}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{cmd:myrank} {hline 2}}Generate axis variable based on ranks{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}
{cmd:myrank} {it:newvar} {cmd:=} {it:varname}
{ifin}
[ 
{cmd:,} 
{opt desc:ending} 
{opt over(varname)} 
{opt gap(#)} 
{opt varl:abel(string)} 
]


{title:Description}

{p 4 4 2}
{cmd:myrank} generates a variable for a graph axis that is based on
(unique or distinct) ranks of values of a numeric variable, with various
possible twists.  First, if a grouping variable is specified, ranks are
determined separately within groups of that variable but remain distinct
overall.  Second, given the first twist, gaps of integer length may be
added between groups.  Third, ranking by default is ascending, lowest to
highest, but optionally may be descending, highest to lowest.  


{title:Remarks}  

{p 4 4 2}
See Cox (2024b) for the context here and examples of a simple graphical 
method using a special axis variable. This command is at root only a 
simple helper command to carry out preliminary calculation of that axis, 
variable allowing such graphs to follow more easily. 

{p 4 4 2}
The command name {cmd:myrank} is to be parsed "my rank variable".  The
element "rank" is key. Ranks are always unique or distinct, echoing a 
convention used by quantile plots. 

{p 4 4 2}
The first element "my" is at best harmless whimsy, but it arises because
mentions of a command named just {cmd:rank} would be harder to spot
among other uses of the term.

{p 4 4 2}
The major and intended use of such a variable is for side-by-side
quantile plots, as in Cox (2024b). See Cox (1999, 2005, 2007, 2024a) and 
{cmd:search qplot, sj} for more on quantile plots in Stata. The literal 
values of the rank variable have simple meaning only for the first group 
so created. However, the purpose is not to use those ranks literally, 
but only to create a variable to use as one axis. 

{p 4 4 2}
Local macros with names {cmd:mid1}, {cmd:mid2}, and so forth are inserted
in the calling program's space containing the mid-ranks (means of the
new variable) in the first group and any later groups of the new variable. 
If {cmd:over()} is not specified, or if it is specified and contains only
one distinct value, then there will be just one group.  

{p 4 4 2}
Local macros with names {cmd:gap1}, {cmd:gap2}, and so forth are inserted
in the calling program's space containing the positions of the gaps
after groups 1, 2, and so forth of the new variable. 

{p 4 4 2}
These local macros are potentially of use for specifying axis labels and
vertical separator lines in a later graph command. As is true of all local 
macros, the macros will only be visible in the calling program's name space
and will be overwritten easily, as by a later use of this command. Hence 
copy whatever is of value to somewhere safe. 

{p 4 4 2}
The {cmd:myaxis} command (Cox 2021) is for a related but distinct problem. 


{title:Options} 

{phang}
{opt over(varname)} specifies a grouping variable, typically but not
necessarily a numeric or string variable with categorical flavour. 

{phang}
{opt gap(#)} specifies a gap of integer length to be added to ranks 
to amplify visual separation between groups if {cmd:over()} is also 
specified. The gap is fixed at 0 otherwise. 

{phang}
{cmd:descending} specifies ranking with highest value first.  The
default rank order is ascending with lowest value first.

{phang}
{opt varlabel(string)} specifies a variable label for the new variable.


{title:Examples}

{phang}{cmd:. sysuse auto}{p_end}

{p 4 4 2}
The ranks of {cmd:mpg} will just run from 1 to 74 for 74 values if no 
{cmd:over()} option is specified. The plot created is a variation on 
that produced by {help quantile} or {help qplot}.{p_end}

{phang}{cmd:. myrank rank1=mpg}{p_end}
{phang}{cmd:. scatter mpg rank1, xla(none) xtitle(Values in order) name(G1, replace)}{p_end}

{p 4 4 2}
With {cmd:over(foreign)}, two groups of values are separated, for 
{cmd:foreign==0} and for {cmd:foreign==1}. The ranks of {cmd:mpg} 
are created as 1 to 52 for the first group and as 55 to 76 for the 
second group, given the extra gap of 2. Typically those ranks will 
(indeed should) not appear as axis labels, which are better reserved 
for explaining which group is which. Note here the use of local macros 
as explained above in Remarks.{p_end}

{phang}{cmd:. myrank rank2=mpg, over(foreign) gap(2)}{p_end}
{phang}{cmd:. scatter mpg rank2, xla(`mid1' "Domestic" `mid2' "Foreign", tlc(none))}{p_end}
{phang}{cmd:{space 2}xli(`gap1', lp(solid)) xtitle("") name(G2, replace)}{p_end}

{p 4 4 2}
With {cmd:over(rep78)}, five groups of values are separated, from 
{cmd:rep78==1} to {cmd:rep78==5}. The ranks of {cmd:mpg} are created 
as 1 to 2 for the first group, 5 to 12 for the second group, and so on, 
up to 67 to 77 for the last group, given the extra gaps of 2. Values 
that are missing on {cmd:rep78} are ignored. As above, axis labels 
should be used to show group information.{p_end}

{phang}{cmd:. myrank rank3=mpg, over(rep78) gap(2)}{p_end}
{phang}{cmd:. scatter mpg rank3, xla(`mid1' "1" `mid2' "2" `mid3' "3" `mid4' "4" `mid5' "5", tlength(0))}{p_end}
{phang}{cmd:{space 2}xli(`gap1' `gap2' `gap3' `gap4', lp(solid)) xtitle(Repair record 1978) name(G3, replace)}{p_end}

{p 4 4 2}
As these graphs are just applications of {cmd:scatter}, other 
{cmd:twoway} graphs can be added. Here means of each group 
are shown by horizontal lines. 

{phang}{cmd:. egen mean = mean(mpg), by(rep78)}{p_end}
{phang}{cmd:. separate mean, by(rep78) veryshortlabel}{p_end}
{phang}{cmd:. scatter mpg rank3, xla(`mid1' "1" `mid2' "2" `mid3' "3" `mid4' "4" `mid5' "5", tlength(0))}{p_end}
{phang}{cmd:{space 2}xli(`gap1' `gap2' `gap3' `gap4', lp(solid)) xtitle(Repair record 1978)}{p_end}
{phang}{cmd:{space 2}|| line mean? rank3, sort lc(stc2 ..) legend(off) note(horizontal lines show means)}{p_end}
{phang}{cmd:{space 2}ytitle("`: var label mpg'") name(G4, replace)}{p_end}

{p 4 4 2}
For the record, see summary statistics for the new variables.
{p_end}

{phang}{cmd:. tabstat rank1, s(min max)}{p_end}
{phang}{cmd:. tabstat rank2, s(min max) by(foreign)}{p_end}
{phang}{cmd:. tabstat rank3, s(min max) by(rep78)}{p_end}

{p 4 4 2}
For comparison, how far can we get with say {cmd:graph dot}?
{p_end}

{phang}{cmd:. bysort rep78 (mpg) : gen dotrank = _n}{p_end}

{phang}{cmd:. graph dot (asis) mpg, over(dotrank, label(nolabels)) over(rep78)}{p_end}
{phang}{cmd:{space 2}linetype(line) lines(lc(gs12) lw(vvthin)) vertical nofill exclude0}{p_end}
{phang}{cmd:{space 2}b2title(Repair record 1978) name(G5, replace)}{p_end}


{title:Author}

{pstd}
Nicholas J. Cox{break}
Department of Geography{break}
Durham University{break}
Durham, UK{break}
n.j.cox@durham.ac.uk


{title:References}

{p 4 8 2}Cox, N.J. 1999. 
Quantile plots, generalized. 
{it:Stata Technical Bulletin} 51: 16{c -}18. 
{browse "https://www.stata.com/products/stb/journals/stb51.pdf":https://www.stata.com/products/stb/journals/stb51.pdf}

{p 4 8 2}Cox, N.J. 2005. 
Speaking Stata: The protean quantile plot. 
{it:Stata Journal} 5: 442{c -}460. 
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X0500500312":https://journals.sagepub.com/doi/pdf/10.1177/1536867X0500500312}

{p 4 8 2}Cox, N.J. 2007. 
Stata tip 47: Quantile-quantile plots without programming
{it:Stata Journal} 7:275{c -}279.  
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X0700700213":https://journals.sagepub.com/doi/pdf/10.1177/1536867X0700700213}   

{p 4 8 2}Cox, N.J. 2021. 
Speaking Stata: Ordering or ranking groups of observations. 
{it:Stata Journal} 21: 818{c -}837. 
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X211045582":https://journals.sagepub.com/doi/pdf/10.1177/1536867X211045582}

{p 4 8 2}Cox, N.J. 2024a. 
Speaking Stata: Quantile–quantile plots, generalized. 
{it:Stata Journal} 24: 514{c -}534. 
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X241276114":https://journals.sagepub.com/doi/pdf/10.1177/1536867X241276114}

{p 4 8 2}Cox, N.J. 2024b. 
Speaking Stata: Getting by without the by() option: Some graphics for unequal groups. 
{it:Stata Journal} 24: 766{c -}776.  
{browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X241297949":https://journals.sagepub.com/doi/pdf/10.1177/1536867X241297949}


{marker alsosee}{...}
{title:Also see}

{p 7 14 2}
Help:  {manhelp graph_dot G-2:graph dot}, {manhelp diagnostic_plots R:diagnostic plots}, 
{helpb myaxis} (if installed), {helpb qplot} (if installed){p_end}
