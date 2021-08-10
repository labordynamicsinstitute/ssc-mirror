{smcl}
{* March 2012}{...}
{hline}
{hi:SUBSIM 2.0 : Subsidy Simulation Stata Toolkit}{right:{bf:World Bank}}
help for {hi:trexqua}{right:Dialog box:  {bf:{dialog trexqua}}}
{hline}

{title:Transforming expenditures on a given item into consumed quantities} 


{p 8 10}{cmd:trexqua}  {it:varlist (min=2, max=2)}  {cmd:,} [ 
{cmd:PSCH(}{it:string}{cmd:)} 
{cmd:HSize(}{it:varname}{cmd:)} 
{cmd:HGroup(}{it:varname}{cmd:)}
{cmd:NAME(}{it:string}{cmd:)} 
{cmd:RESULT(}{it:string}{cmd:)} 
{cmd:DEC(}{it:int}{cmd:)} 
{cmd:DSTE(}{it:int}{cmd:)} 
{cmd:DGRA(}{it:int}{cmd:)} 
]


{p}where {p_end}
{p 8 8} {cmd:varlist} is a list of two variables. The first variable is that of the household total expenditures. The second is that of the household total expenditures on the item concerned by the price change. {p_end}


{title:Version} 9.2 and higher.

{title:Remark(s):} 
{p 8 8} Users should set their surveys' sampling design before using this module (and then save their data files). If the sampling design is not set, simple-random sampling (SRS) will be automatically assigned by default. {p_end}


{title:Description}
{p 8 8} With {cmd: trexqua}, we can transform the household total expenditures on a given item with a predefined price schedule into consumed quantities. 
Further, some descritive results by population groups are produced. The population groups can be defined by consumption blocks or by any other partition of the population, 
for instance, urban and rural areas.  {p_end}


{title:Options} 

{p 0 6} {cmdab:psch}    To indicate the name of price schedule of the item. The price schedule must be initialised by the command {bf:{help pschset}}. {p_end}

{p 0 6} {cmdab:hsize}   Household size. For example, to compute inequality at an individual level, one will want to weight household-level observations by household size (in addition to sampling weights, best set in survey design). {p_end}

{p 0 6} {cmdab:hgroup}   Variable that captures a socio-demographic group. For example, this variable could equal 1 for rural households and 2 for urban ones. When this option is used, the associated varlist should contain only one variable. By default , the population groups are defined by consumption blocks. {p_end}

{p 0 6} {cmdab:name}    To indicate the name of the generated variable, which will contain the consummed quantity of the item by the household. {p_end}

{p 0 6} {cmdab:result}    If "per" is selected, the descriptive statitics are estimated at the individual level. By default, the household level ("hh") is considered. {p_end}

{p 0 6} {cmdab:dec}    To set the number of decimals used in the display of results. {p_end}

{p 0 6} {cmdab:dste}    If "1" is selected, standard errors are displayed. {p_end}

{p 0 6} {cmdab:dgra}    If option "0" is selected, the results are displayed in bar graphs. By default, the graph is not displayed. {p_end}


 
{title:Author(s)}
Abdelkrim Araar
Paolo Verme


        



{title:Contact}

If you note any problems, please contact {bf:Abdelkrim Araar:} {browse "mailto:aabd@ecn.ulaval.ca"}
