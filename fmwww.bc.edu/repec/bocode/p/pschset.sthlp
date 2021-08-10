{smcl}
{* March 2012}{...}
{hline}
{hi:SUBSIM 2.0: Price Simulation Stata Toolkit}{right:{bf:World Bank}}
help for {hi:pschset }{right:Dialog box:  {bf:{dialog pschset}}}
{hline}

{title:Setting the price schedule} 


{p 8 10}{cmd:pschset}  {it:namelist}  {cmd:,} [ 
{cmd:mxb1(}{it:real}{cmd:)}-{cmd:mxb`k-1'(}{it:real}{cmd:)}
{cmd:tr1(}{it:real}{cmd:)}-{cmd:tr`k'(}{it:real}{cmd:)}
{cmd:sub1(}{it:real}{cmd:)}-{cmd:sum`k'(}{it:real}{cmd:)}
{cmd:nblock(}{it:int}{cmd:)}
{cmd:bun(}{it:int}{cmd:)}
{cmd:mxb(}{it:varname}{cmd:)}
{cmd:tr(}{it:varname}{cmd:)}
{cmd:sub(}{it:varname}{cmd:)}
{cmd:insave(}{it:string}{cmd:)}
{cmd:bun(}{it:oinf}{cmd:)}
]
 

{p}where {p_end}
{p 8 8} {cmd:namlist} is a the assigned name to the price schedule. {p_end}


{title:Version} 9.2 and higher.

{title:Description}
 {p}{cmd:Setting the price schedule}  

With {cmd: pschset}, we can initialise the price schedule of a given good in order to perform other estimations.  For instance, we can initialise the price schedule of that before the reform and that after the reform. After that, we can estimate the impact of the price reform on household wellbeing or on producer revenue. 


{title:Options} 

{p 0 4} {cmd:nblock:}    To set the number of blocks. For instance, if the price applied for the first range of quantities [0,Q1] is p1, and that of ]Q1,and more] is p2, then we have two tariff blocks.  {p_end}

{p 0 4} {cmd:bun:}    To set the block unit. By default the block quantities are defined according to household consumption. Set the value of this option to 2 to indicate that the block are defined at individual level.{p_end}

{p 0 4} {cmd:mxb"k":}    Parameters used to set the maximum quantity of block k. {p_end}

{p 0 4} {cmd:tr"k":}     Parameters used to set the price of block k. {p_end}

{p 0 4} {cmd:sub"k":}    Parameters used to set the subsidy of block k. {p_end}

{p 0 6} {cmd:oinf:}       To indicate the used form to declare information about items (name of variables of expenditures on items, prices/price schedules, etc.). When variables are used, the value must be set to 2. {p_end}

{p 0 6} {cmd:mxb:} If oinf=2, indicate the varname of maximum quantities of blocks. {p_end}

{p 0 6} {cmd:tr:} If oinf=2, indicate the varname of prices of blocks. {p_end}

{p 0 6} {cmd:sub:} If oinf=2, indicate the varname of subsidies of blocks. {p_end}

{p 0 6} {cmd:inisave:}    To save the dialog box information. Mainly, all of the inserted information in the dialogue box will be saved in this file. In another session, the user can load the saved information by using the command pschini. {p_end}

{title:Author(s)}
Abdelkrim Araar
 

{title:Contact}
If you note any problems, please contact {bf:Abdelkrim Araar:} {browse "mailto:aabd@ecn.ulaval.ca"}

