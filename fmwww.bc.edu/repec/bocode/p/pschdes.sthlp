{smcl}
{* March 2012}{...}
{hline}
{hi:SUBSIM 2.0: Price Simulation Stata Toolkit}{right:{bf:World Bank}}
help for {hi:pschdes }
{hline}

{title:Describing the price schedules} 


{p 8 10}{cmd:pschdes}  {it:namelist} , {cmd:DGRA(}{it:string}{cmd:)} {cmd:SGRA(}{it:string}{cmd:)} {cmd:EGRA(}{it:string}{cmd:)}]

{syntab :Y-Axis, X-Axis, Title, Caption, Legend, Overall}
{synopt :{it:{help twoway_options}}}any of the options documented in 
{bind:{bf:[G]} {it:twoway_options}}{p_end}
{synoptline}
 
 

{p}where {p_end}
{p 8 8} {cmd:namlist} is a the assigned list of price schedule names. {p_end}


{title:Version} 9.2 and higher.

{title:Description}
 {p}{cmd:Describing the price schedules}  

With {cmd: pschdes}, we can produce the description a given price schedule or a list of price schedule. Further, we can also plot a graphical representation of the price schedule(s).


{title:Author(s)}
Abdelkrim Araar

{title:Options:} 

{p 0 4} {cmdab:dgra}    If option "0" is selected, the graph is not displayed. By default, the graph is displayed. {p_end}

{p 0 4} {cmdab:sgra}    To save the graph in Stata format (*.gph), indicate the name of the graph file using this option. {p_end}

{p 0 4} {cmdab:egra}    To export the graph in an EPS or WMF format, indicate the name of the graph file using this option. {p_end}


{dlgtab:Y-Axis, X-Axis, Title, Caption, Legend, Overall, By}

{phang}
{it:twoway_options} are any of the options documented in 
{it:{help twoway_options}}.  These include options for titling the graph 
(see {it:{help title_options}}), options for saving the graph to disk (see 
{it:{help saving_option}}), and the {opt by()} option (see 
{it:{help by_option}}).

        

{title:Contact}

If you note any problems, please contact {bf:Abdelkrim Araar:} {browse "mailto:aabd@ecn.ulaval.ca"}	                          
