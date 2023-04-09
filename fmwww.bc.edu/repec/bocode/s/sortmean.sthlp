{smcl}
{* 30mar2023}{...}
{hline}
{cmd:help sortmean}
{hline}

{title:Title}

{p 8 8 2}
{hi:sortmean} {hline 2}  List of variable names sorted by their means


{title:Syntax}

{p 8 17 2}{cmd:sortmean} [{it:varlist}]
{ifin}
{weight} 
[{cmd:,} 
{opt allobs}
{opt desc:ending}
{opt local(macname)} 
]

{p 4 4 2}fweights and aweights are allowed. 


{title:Description}

{p 4 4 2}{cmd:sortmean} sorts the names of numeric variables in
{it:varlist} by their means, displays the list of variable names, and
produces a local macro (by default called {cmd:sortlist}) accessible to
the user. 

{p 4 4 2}If {it:varlist} is not specified, it defaults to all variables
in the dataset. Otherwise one or more variables may be specified. 

{p 4 4 2}Any string variables specified will be ignored, either with or
without an explicit {it:varlist}. 
    

{title:Options} 

{p 4 4 2}{cmd:allobs} specifies that observations with any missing
values on {it:varlist} will be included. The default is to ignore them. 

{p 4 4 2}{cmd:descending} specifies that variable names are to be sorted
in descending order, the variable with highest mean first. The default is to
sort in ascending order. 

{p 4 4 2}{cmd:local()} specifies an alternative name for the local macro
produced. 


{title:Examples}

{p 4 8 2}{cmd:. sysuse auto, clear}{p_end}
{p 4 8 2}{cmd:. sortmean weight mpg price}{p_end}
{p 4 8 2}{cmd:. sortmean weight mpg price, desc}{p_end}
{p 4 8 2}{cmd:. di "`sortlist'"}{p_end}

{p 4 8 2}{cmd:. separate mpg, by(rep78)}{p_end}
{p 4 8 2}{cmd:. sortmean mpg?, allobs}{p_end}
{p 4 8 2}{cmd:. sortmean mpg?, allobs desc}{p_end}
{p 4 8 2}{cmd:. tabstat `sortlist', c(s)}{p_end}


{title:Author}

{p 4 4 2}Nicholas J. Cox, Durham University, UK{break}
n.j.cox@durham.ac.uk


{title:Acknowledgments} 

{p 4 4 2}
Daniel Klein gave a kindly reminder about his {cmd:vorter} command on
SSC, which can do something similar, and much more, and gave helpful
suggestions about the Mata code for this command. 


{title:Also see}

{psee}
Online:
{help vorter} (SSC; if installed) 
{p_end}

