{smcl}
{* 24 Nov 2008/8 Dec 2008/26 May 2020}{...}
{hline}
help for {hi:panelthin}
{hline}

{title:Identify observations for possible thinned panel dataset}

{p 8 17 2}{cmd:panelthin} 
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
, 
{cmdab:g:enerate(}{it:newvar}{cmd:)} 
{cmdab:m:inimum(}{it:#}{cmd:)} 
  

{title:Description}

{p 4 4 2}{cmd:panelthin} identifies observations that would belong in a
thinned panel dataset in which observations in each panel are at least a
minimum time apart.  The result is a new variable tagging observations
in the thinned dataset by 1 and others by 0.  


{title:Remarks} 

{p 4 4 2}{cmd:panelthin} assumes {help tsset} data and automatically
works separately on each panel in a panel dataset. 

{p 4 4 2}In essence, the first observation in each panel is selected,
then the next after at least a minimum time, and so on. 

{p 4 4 2}If a thinned dataset is acceptable, then (provided that the
main dataset is {help save}d elsewhere) {help keep} the set with 
observations tagged 1 in the new variable. 

{p 4 4 2}The tags can be used to identify spells or runs in the data, 
which most obviously may be helpful if {help collapse} is to be used 
in a reduction of the dataset. For more on the principles of identifying
spells, see Cox (2007).  


{title:Options} 

{p 4 4 2}{cmd:generate()} specifies the name of a new variable to include 
tags for selected observations. It is a required option. 

{p 4 4 2}{cmd:minimum()} specifies the minimum acceptable spacing in the
units of the time variable defining the panel. It is a required option. 


{title:Examples}

{p 4 4 2}{cmd:clear}{p_end}
{p 4 4 2}{cmd:input id year whatever}{p_end}
{p 4 4 2}{cmd:4   1987 1}{p_end}
{p 4 4 2}{cmd:4   1988 3}{p_end}
{p 4 4 2}{cmd:4   1989 5}{p_end}
{p 4 4 2}{cmd:4   1990 7}{p_end}
{p 4 4 2}{cmd:4   1992 11}{p_end}
{p 4 4 2}{cmd:4   1993 13}{p_end}
{p 4 4 2}{cmd:4   1994 15}{p_end}
{p 4 4 2}{cmd:9   1987 42}{p_end}
{p 4 4 2}{cmd:9   1988 44}{p_end}
{p 4 4 2}{cmd:9   1989 46}{p_end}
{p 4 4 2}{cmd:9   1990 48}{p_end}
{p 4 4 2}{cmd:9   1992 52}{p_end}
{p 4 4 2}{cmd:9   1993 54}{p_end}
{p 4 4 2}{cmd:9   1994 56}{p_end}
{p 4 4 2}{cmd:end}

{p 4 4 2}{cmd:tsset id year}{p_end}
{p 4 4 2}{cmd:panelthin, min(2) gen(tag)}{p_end}
{p 4 4 2}{cmd:list}

{p 4 4 2}{* alternative 1: brute force}{p_end}
{p 4 4 2}{cmd:keep if tag}{p_end}
{p 4 4 2}{cmd:list, sepby(id)}

{p 4 4 2}{* alternative 2: collapse first}{p_end}
{p 4 4 2}{cmd:bysort id (year): gen spell = sum(tag)}{p_end}
{p 4 4 2}{cmd:collapse (min) year (mean) whatever, by(id spell)}{p_end}
{p 4 4 2}{cmd:list, sepby(id)}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University, UK{break} 
n.j.cox@durham.ac.uk


{title:Acknowledgments}

{p 4 4 2}This problem was suggested by Rajesh Tharyan on Statalist.
{browse "http://www.stata.com/statalist/archive/2008-05/msg00772.html":http://www.stata.com/statalist/archive/2008-05/msg00772.html}

{p 4 4 2}Leny Matthew signalled a bug in an earlier version. 

{p 4 4 2}Andrea Stringhetti posted a problem at 
{browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1555093-sorting-and-creation-of-variables":https://www.statalist.org/forums/forum/general-stata-discussion/general/1555093-sorting-and-creation-of-variables}
which led to emphasis on the scope for spell identification. 


{title:Reference} 

{p 4 8 2}Cox, N.J. 2007. 
Speaking Stata: Identifying spells. 
{it:Stata Journal} 7: 249{c -}265. 
{browse "http://www.stata-journal.com/article.html?article=dm0029":http://www.stata-journal.com/article.html?article=dm0029}


{title:Also see}

{p 4 13 2}On line: help for {help tsset} 


