{smcl}
{* 14July2016}{...}
{hline}
help for {hi:hanoitower}
{hline}

{title:Play Tower of Hanoi in Stata}

{cmd:hanoitwoer } provide demos of Tower of Hanoi in Stata. 
{marker syntax}{...}
{title:Syntax}

{p 4 10 2}
{cmd:hanoi } #1 [#2], [fig] 

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}

{synopt :{opt #1}}specify the number of disks{p_end}
{synopt :{opt #2}}specify the sleep time for each step; 
by default, it is 1000ms {p_end}
{synopt :{opt fig}}show the figures {p_end}

{synoptline}
 

{marker examples}{...}
{title:Examples}

{phang}

{p 12 16 2}
{cmd:.hanoitower 10 1000}

{p 12 16 2}
{cmd:.hanoitower 5, fig}

{p 12 16 2}
{cmd:.qui hanoitower 3 2000, fig}

{hline}


{title:Authors}
{phang}
{cmd:Kerry Du}, School of Management, Xiamen University, China.{break}
 E-mail: {browse "mailto:kerrydu@xmu.edu.cn":kerrydu@xmu.edu.cn}. {break}


