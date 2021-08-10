{smcl}
{* *! version 1.0.0  12aug2016}{...}
{findalias asfradohelp}{...}
{title:timeit}

{phang}
{bf:timeit} {hline 2} Easy to use single line version of timer on/off


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd: timeit }
{it:integer}
[{it:name}]
{cmd: :}
{it:cmd}

{marker description}{...}
{title:Description}


{tab}{cmd:timeit} {it:#} {cmd::} {it:cmd} {col 30} will store the runtime of {it:cmd} in timer {it:#}. 

{tab}{cmd:timeit} {it:#} {it:name} {cmd::} {it:cmd} {col 30} will store the runtime of {it:cmd} in timer {it:#} and in scalar {it:name}. 


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:timeit} {it:#} {cmd::} {it:cmd} is functionally equivalent to{p_end}
{tab}{cmd:. timer on} {it:#}
{tab}{it:. cmd}
{tab}{cmd:. timer off} {it:#}

{pstd}
If your {it: cmd} leads to an error, the timer will stop running. Hitting break will also stop the timer.

{pstd}The time stored in timer # or {it:name} will always be total accumulated time of that timer. {p_end} 
{tab}E.g. if timer 1 was at 5s before and ran for 2s during the -timeit 1:-, then timer 1 will be 7s and {it:name} = 7.

{pstd}
Any mistakes are my own.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto, clear}{p_end}

{phang}{cmd:. timer clear}{p_end}
{phang}{cmd:. timeit 1: reg price mpg}{p_end}
{phang}{cmd:. timeit 2 fullRegTime: reg price mpg trunk weight length, r}{p_end}
{phang}{cmd:. timer list}{p_end}
{phang}{cmd:. di fullRegTime}{p_end}


{title:Author}
Jesse Wursten
Faculty of Economics and Business
KU Leuven
{browse "mailto:jesse.wursten@kuleuven.be":jesse.wursten@kuleuven.be} 

Special thanks go to Daniel Klein for his suggestions and code snippets that vastly improved this command.
