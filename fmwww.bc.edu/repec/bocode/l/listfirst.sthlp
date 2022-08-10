{smcl}
{* 6aug2022/8aug2022}{...}
{hline}
{cmd:help listfirst}
{hline}

{title:Title}

{p 8 8 2}
{hi:listfirst} {hline 2}  List first so many observations 

{title:Syntax}

{p 8 17 2}{cmd:listfirst} [{it:varlist}]
[{cmd:if} {it:exp}]
[{cmd:,} 
{opt first(#)}
{opt last} 
{opt last(#)}
{it:list_options}  
]


{title:Description}

{p 4 4 2}{cmd:listfirst} lists the first {it:#} observations, either
generally or (more usefully) those satisfying an {help if} condition. 

{p 4 4 2}Optionally it will also list the last {it:#} observations,
either generally or (more usefully) those satisfying an {help if}
condition. 

{p 4 4 2}{it:#} defaults to 10. Optionally it may be changed, and need
not be equal for first and last subsets. 

{p 4 4 2}If {it:varlist} is not specified, it defaults to all variables in the 
dataset. Otherwise one or more variables may be specified. 

{p 4 4 2}Output may be limited by what exists in the dataset. For
example, no observations will be {cmd:list}ed if none exist that
satisfy a specified {cmd:if} condition. That is not considered an error.  


{title:Remarks}  

{p 4 4 2}Many readers will be familiar with utilities in Unix or other
operating systems allowing you to see the head (top or first lines) or
tail (bottom or end lines) of text files. Similar features have been
folded into various statistical programs. In Stata most but not quite
all the possibilities yield easily to {help list} or {help edit} or
{help browse} when the concern is with a dataset.

{p 4 4 2}You may have special interest in what is at either end of a
dataset. Perhaps more commonly the point is just to see a small sample
of the dataset, especially of a large dataset.  Perhaps a full
{cmd:list} or opening {cmd:edit} or {cmd:browse} seems over the top. 

{p 4 4 2}Examples use the auto dataset bundled with Stata, which has 74
observations. 

{p 4 4 2}The simplest applications of {cmd:listfirst} are trivial. 

{p 8 8 2}{cmd:listfirst} by itself is equivalent to {cmd:list in 1/10}. 

{p 8 8 2}{cmd:listfirst mpg} by itself is equivalent to {cmd:list mpg in 1/10}. 

{p 8 8 2}{cmd:listfirst mpg, first(5)} is equivalent to 
{cmd:list mpg in 1/5}. 

{p 4 4 2}Such examples don't take you beyond what is already easy with
{cmd:list}. However, 

{p 8 8 2}{cmd:listfirst mpg, last} 

{p 4 4 2}is equivalent to 

{p 8 8 2}{cmd:list mpg if inrange(_n, 1, 10) | inrange(_n, 65, 74)} 

{p 4 4 2}or more generally to 

{p 8 8 2}{cmd:list mpg if inrange(_n, 1, 10) | inrange(_n, _N - 9, _N)}. 

{p 4 4 2}Either is harder to work out or to type. 

{p 8 8 2}{cmd:listfirst mpg, first(5) last(5)} 

{p 4 4 2}is similarly more
challenging to emulate with {cmd:list}. 

{p 4 4 2}The use of an {cmd:if} condition is where {cmd:listfirst}
scores. 

{p 8 8 2}{cmd:listfirst mpg if foreign} 

{p 4 4 2}lists the first 10 observations satisfying the condition
specified, which is more difficult otherwise without working out where 
they are in the dataset, or knowing that for another reason. However, a
useful trick is

{p 8 8 2}{cmd:list mpg if foreign & sum(foreign) <= 10} 

{p 4 4 2}given that {cmd:foreign} is a (0, 1) indicator variable. 
That generalises to any
true-or-false expression. See (e.g.) Cox (2007) for more on such ideas.  

{p 8 8 2}{cmd:listfirst mpg if foreign, last} 

{p 4 4 2}shows the last 10 observations too.  


{title:Options} 

{p 4 4 2}{cmd:first()} specifies that the first {it:#} pertinent observations be
listed. The default is 10. 

{p 4 4 2}{cmd:last()} specifies that the last {it:#} pertinent observations also
be listed. 

{p 4 4 2}{cmd:last} is a convenient alternative to {cmd:last(10)}. 

{p 4 4 2}{it:list_options} are options of {help list}. For example, you
might not care about observation numbers. If so, you can suppress
them with {cmd:noobs} (to be parsed as "no obs" and not otherwise).


{title:Examples}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. listfirst}{p_end}
{p 4 8 2}{cmd:. listfirst mpg}{p_end}
{p 4 8 2}{cmd:. listfirst mpg, last}{p_end}
{p 4 8 2}{cmd:. listfirst mpg, first(5) last(5)}{p_end}

{p 4 8 2}{cmd:. listfirst mpg if foreign}{p_end}
{p 4 8 2}{cmd:. listfirst mpg if foreign, last}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University, UK{break}
n.j.cox@durham.ac.uk


{title:Acknowledgments} 

{p 4 4 2}
A command {cmd:listsome} was posted on Statalist on 10 April 2008 
in 
{browse "https://www.stata.com/statalist/archive/2008-04/msg00448.html":this post}
in response to a question from Malcolm Wardlaw in 
{browse "https://www.stata.com/statalist/archive/2008-04/msg00438.html":this earlier post} 
on the same day. But that command was never documented or made public beyond
Statalist.

{p 4 4 2}Independently Robert Picard posted a {cmd:listsome} command on
SSC that was first announced on 18 August 2014 in 
{browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/163527-new-on-ssc-listsome-a-program-to-list-a-small-random-sample-of-observations":this post}. 

{p 4 4 2}Robert's command has a strong feature of offering random
samples, which is not attempted here. This {cmd:listfirst} command has
two small virtues, being limited, and therefore simple; and showing
"last" observations too if that is also wanted. I happily yield the
command name to Robert. 


{title:References} 

{p 4 8 2}
Cox, N.J. 2007.
How can I identify first and last occurrences systematically in panel data?
{browse "http://www.stata.com/support/faqs/data-management/first-and-last-occurrences/"} 


{title:Also see}

{psee}
Online:
{manhelp list D}, 
{help listsome} (SSC; if installed), 
{p_end}

