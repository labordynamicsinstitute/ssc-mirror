{smcl}
{* 4 March 2024}{...}
{hline}
help for {hi:econsig}
{hline}


{title:Title}

{p 4 4 2}
{hi:econsig} —— Quickly calculate six types of economic significance to 
simplify your empirical process.{p_end}


{title:Syntax}

{p 4 4 2}
{cmdab:econsig}, 
{cmdab:m:odel:}{cmd:(}regression command{cmd:)}
[
{cmdab:k:eep:(}{it:string}{cmd:)}
{cmdab:reg:ression:}
{cmdab:ref:erence:}
]
{p_end}


{title:Description}

{p 4 4 2}
{cmd:econsig}
By specifying specific regression models, {it:econsig} can help 
you quickly calculate six common indicators of economic significance.  These 
indicators are from the Mitton(2024) review and have been indexed to the original 
literature.
{p_end}

{p 4 4 2}
Cite: Todd Mitton, Economic Significance in Corporate Finance, The Review of 
Corporate Finance Studies, Volume 13, Issue 1, February 2024, Pages 38–79, 
{it:{browse "https://doi.org/10.1093/rcfs/cfac008" :-Link-}}
{p_end}


{title:Requirements}

{p 4 4 2}
For ease of use, {hi:econsig} uses the simplest syntax. The only thing you need 
to set up is the regression equation in {it:model()} or {it:m()}.
{p_end}

{p 4 4 2}
Note that this command does not support adding {it:if} and {it:in} conditions 
because it is difficult to filter out {it:if} and {it:in} conditions by regular 
expressions or other text interception methods. If your regression is more 
complex, involving multiple {it:if} and {it:in} conditions, in this case, you 
need to prioritize the use of {it:keep if} or {it:keep in} to complete the 
sample filtering, and then use {hi:econsig}.
{p_end}

{p 4 4 2}
{cmdab:m:odel:}{cmd:(}regression command{cmd:)} Place your regression model in 
it, which can contain options from the regression command, but not {it:if} or 
{it:in} conditions.
{p_end}

{p 4 4 2}
{cmdab:k:eep:(}{it:string}{cmd:)} Specify the variables you need; if not, the 
economic significance of all explanatory variables is calculated by default.
{p_end}

{p 4 4 2}
{cmdab:reg:ression:}} Used to specify whether you need to show the regression 
results or not, if not then no regression results are shown by default.
{p_end}

{p 4 4 2}
{cmdab:ref:erence:} Used to specify whether references need to be displayed. 
This command calculates a total of six economic significance, and the references 
for each are recorded. This option allows you to choose whether or not the details 
of the references need to be displayed; the default is not to display them.
{p_end}


{title:Results}

{p 4 4 2}
After running {hi:econsig}, a table recording six different economic significances 
will appear on your screen, and you can copy and paste their values into the 
regression table you need to report on.
{p_end}


{title:Examples}

{p 4 4 2} *- The easiest way to use {p_end}

{p 4 4 2}{inp:.} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"econsig, m(reg price weight length)"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"econsig, m(reghdfe price weight length, noa)"'}
{p_end}

{p 4 4 2} *- Retaining only some of the variables {p_end}

{p 4 4 2}{inp:.} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"econsig, m(reg price weight length) k(weight)"'}
{p_end}

{p 4 4 2} *- Showing the original regression results {p_end}

{p 4 4 2}{inp:.} 
{stata `"sysuse auto.dta, clear"'}
{p_end}
{p 4 4 2}{inp:.} 
{stata `"econsig, m(reg price weight length) k(weight) reg"'}
{p_end}


{title:Author}

{p 4 4 2}
{cmd:Shutter Zor(左祥太)}{break}
Accounting Department, Xiamen University{break}
E-mail: {browse "mailto:Shutter_Z@outlook.com":Shutter_Z@outlook.com}{break}


{title:References}

{phang}Li F, Srinivasan S. 
Corporate governance when founders are directors[J]. 
Journal of financial economics, 2011, 102(2): 454-469.
{p_end}

{phang}Custódio C, Metzger D. 
Financial expert CEOs: CEO's work experience and firm's financial policies[J]. 
Journal of financial economics, 2014, 114(1): 125-154.
{p_end}

{phang}Guiso L, Sapienza P, Zingales L.
The value of corporate culture[J].
Journal of financial economics, 2015, 117(1): 60-76.
{p_end}

{phang}Smith J D.
US political corruption and firm financial policies[J].
Journal of financial economics, 2016, 121(2): 350-367.
{p_end}

{phang}Mueller H M, Ouimet P P, Simintzi E.
Within-firm pay inequality[J]. 
The Review of Financial Studies, 2017, 30(10): 3605-3635.
{p_end}

{phang}Mitton T.
Economic significance in corporate finance[J]. 
The Review of Corporate Finance Studies, 2024, 13(1): 38-79.
{p_end}
