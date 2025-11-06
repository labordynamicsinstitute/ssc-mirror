{smcl}
{* NJC 3nov2025}{...}
{title:Title}

{phang}
{bf:swapval} {hline 2} Swapping values of two variables


{title:Syntax}

{p 8 17 2}
{cmd:swapval} {it:avar} {it:bvar} {ifin}


{title:Description}

{pstd}
{cmd:swapval} interchanges the values of two variables {it:avar} and {it:bvar}, 
so long as both variables are numeric or both are string.  


{title:Remarks}

{pstd}
{cmd:swapval} may be useful whenever data checking suggests that values for two 
variables have been interchanged. In simple cases, this calls for a few 
{cmd:replace} statements, or the use of the data Editor, but in other cases 
a single command may be useful. 

{pstd}
{cmd:swapval} can be applied unconditionally, in which case it is in essence 
a swapping of variable names. 

{pstd}
Alternatively, it can be applied conditionally, using {cmd:if} and/or {cmd:in}, 


{title:Examples}

{pstd}
In a data set {cmd:max} should always be not less than {cmd:min}. 
A check shows that this is not true in two observations, 
42 and 666. If we suppose that this must be a data error, 
then it can be fixed by

{phang}{cmd:. swapval min max if inlist(_n, 42, 666)}{p_end}

{pstd}or  

{phang}{cmd:. swapval min max if max < min}{p_end}

{pstd}See also {cmd:rowsort} (Cox 2009). 

 
{title:Author}  

{p 4 4 2}Nicholas J. Cox, University of Durham, U.K.{break}
         n.j.cox@durham.ac.uk
		
		
{title:Acknowledgments}

{pstd}
This command was first issued in 1999. 
In 2025 Daniel Klein identified a bug and commented on a rewriting of the code. 
The opportunity has been taken to simplify the design of the command. 


{title:Reference}

{phang}
Cox, N. J. 2009. Speaking Stata: Rowwise. {it:Stata Journal} 9: 137{c -}157.
       
	
{title:Also see} 

{p 4 4 2}
On-line:  help for {cmd:replace}, {cmd:edit}, {cmd:rowsort} (if installed)
