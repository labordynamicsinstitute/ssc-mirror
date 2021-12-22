{smcl}
{* April 2013}{...}
{hline}
{hi:SUBSIM 2.0: Subsidy Simulation Stata Toolkit}{right:{bf:World Bank}}
help for {hi:asubsim}{right:Dialog box:  {bf:{dialog asubsim}}}
{hline}

{title:Impact of subsidy reforms on household wellbeing and on government revenue} 

{title:Syntax}
{p 8 10}{cmd:asubsim}  {it:varlist (min=1, max=1)}  {cmd:,} [ 
{cmd:HSize(}{it:varname}{cmd:)} 
{cmd:HGroup(}{it:varname}{cmd:)}
{cmd:NITEMS(}{it:int}{cmd:)} 
{cmd:XFIL(}{it:string}{cmd:)} 
{cmd:FOLGR(}{it:string}{cmd:)}
{cmd:LAN(}{it:string}{cmd:)} 
{cmd:INISAVE(}{it:string}{cmd:)} 
{cmd:AGGReragte(}{it:string}{cmd:)} 
{cmd:APPR(}{it:int}{cmd:)} 
{cmd:WAPPR(}{it:int}{cmd:)} 
{cmd:TJOBS(}{it:string}{cmd:)} 
{cmd:GJOBS(}{it:string}{cmd:)} 

{cmd:OPRk:  k:1...10:(}{it:Syntax }{cmd:)} 
{cmd:SN(}{it:string}{cmd:)} 
{cmd:QU(}{it:string}{cmd:)}
{cmd:IT(}{it:varname}{cmd:)} 
{cmd:IP(}{it:real/string}{cmd:)}
{cmd:SU(}{it:real}{cmd:)}
{cmd:FP(}{it:real/string}{cmd:)}
{cmd:EL(}{it:real}{cmd:)} 
{cmd:PS(}{it:int}{cmd:)}

{cmd:OPGRk: k:1...10:(}{it:Syntax }{cmd:)} 
{cmd:MIN(}{it:string}{cmd:)} 
{cmd:MAX(}{it:string}{cmd:)} 
{cmd:OGR(}{it:string}{cmd:)} 

{cmd:ITNAMES(}{it:varname}{cmd:)} 
{cmd:SNAMES(}{it:varname}{cmd:)}
{cmd:IPSCH(}{it:varname}{cmd:)} 
{cmd:NSCEN(}{it:int}{cmd:)}
{cmd:FPSCHk: k:1..3(}{it:varname}{cmd:)}
{cmd:ELASk: k:1..3(}{it:varname}{cmd:)}
{cmd:OINF(}{it:int}{cmd:)} 

{cmd:CNAME(}{it:string}{cmd:)} 
{cmd:YSVY(}{it:string}{cmd:)} 
{cmd:YSIM(}{it:string}{cmd:)} 
{cmd:LCUR(}{it:string}{cmd:)} 

{cmd:TYPETR(}{it:int}{cmd:)}
{cmd:GTARG(}{it:varname}{cmd:)}

{cmd:CVIMP(}{it:int}{cmd:)} 

]

{p}where {p_end}
{p 8 8} {cmd:varlist} is a list of one variable: the per capita expenditures. {p_end}

{title:Description}
{p 8 8} {cmd: asubsim} is the main module of the package SUBSIM 2.0. The later was conceived to automate the estimation of a large size of results about the impact of subsidy reforms on household well-being and government revenue.  By default, the results are reported by quinitiles, but the user can indicate any other partition of population.  The following lists shows the produces tables and graphs.{p_end}

{p 2 8}{cmd:List of tables:}{p_end}
{p 4 8}{inp:[01] Table 1.1: Population and expenditures}{p_end} 

{p 4 8}{inp:[02] Table 2.1: Expenditures }{p_end}
{p 4 8}{inp:[03] Table 2.2: Expenditures per household}{p_end}
{p 4 8}{inp:[04] Table 2.3: Expenditures per capita}{p_end}
{p 4 8}{inp:[05] Table 2.4: Quantities consumed of subsidized products}{p_end}
{p 4 8}{inp:[06] Table 2.5: Per capita consumed quantities of subsidized products}{p_end}

{p 4 8}{inp:[07] Table 3.1: Structure of expenditure on subsidized products}{p_end}
{p 4 8}{inp:[08] Table 3.2: Expenditure on subsidized products over the total expenditures}{p_end}
{p 4 8}{inp:[09] Table 3.3: The total benefits through subsidies}{p_end}
{p 4 8}{inp:[10] Table 3.4: The per capita benefit through subsidies}{p_end}
{p 4 8}{inp:[11] Table 3.5: The proportion of benefit through subsidies}{p_end}

{p 4 8}{inp:[12] Table 4.1: The total impact on the population well-being}{p_end}
{p 4 8}{inp:[13] Table 4.2: The impact on the per capita well-being}{p_end}
{p 4 8}{inp:[13] Table 4.3: The impact on well-being (in %)}{p_end}
{p 4 8}{inp:[14] Table 4.4: The total impact on consumed quantities}{p_end}
{p 4 8}{inp:[15] Table 4.5: The impact on the per capita consumed quantities}{p_end}
{p 4 8}{inp:[16] Table 4.6: The impact of the reform on the government revenue}{p_end}
{p 4 8}{inp:[17] Table 4.7: The reform and the poverty headcount}{p_end}
{p 4 8}{inp:[18] Table 4.8: The reform and the poverty gap}{p_end}
{p 4 8}{inp:[19] Table 4.9: The reform and the Gini inequality}{p_end}


{p 2 8}{cmd:List of graphs:}{p_end}
{p 4 8}{inp:[01] Figure 01: The expenditures on the subsidized good relatively to the total expenditures (%)}{p_end}
{p 4 8}{inp:[02] Figure 02: The per capita benefits through the subsidized items}{p_end}
{p 4 8}{inp:[03] Figure 03: The progressivity in the distribution of benefits}{p_end}
{p 4 8}{inp:[04] Figure 04: The impact of price increasing on poverty (%)}{p_end}
{p 4 8}{inp:[05] Figure 05: Price changes and the impact on the government revenue}{p_end}
{p 4 8}{inp:[06] Figure 06: The elasticity and the impact on the government revenue}{p_end}
{p 4 8}{inp:[07] Figure 07: Subsidy changes and the impact on the government revenue}{p_end}
{p 4 8}{inp:[08] Figure 08: Level of transfer and wellbeing}{p_end}
{p 4 8}{inp:[09] Figure 09: Level of transfer and poverty}{p_end}
{p 4 8}{inp:[10] Figure 10: Level of transfer and government revenue}{p_end}


 The second is that of the household total expenditures on the concerned item by the price change
{title:Version} 10.1 and higher.

{title:Remark(s):} 
{p 8 8} Users should set their surveys' sampling design before using this module (and then save their data files). If the sampling design is not set, simple-random sampling (SRS) will be automatically assigned by default. {p_end}


{title:Description}
{p 8 8} {cmd: asubsim}, can be used to estimate the impact of price schedule reform on  the household wellbeing. 
Further, some descriptive results by population groups are produced. By default, the population groups are defined by deciles, but the user can indicate any other partition of population,  for instance, by urban and rural areas.  {p_end}


{title:Options} 

{p 0 6} {cmd:hsize:}    Household size. For example, to compute inequality at an individual level, one will want to weight household-level observations by household size (in addition to sampling weights, best set in survey design). {p_end}

{p 0 6} {cmd:hgroup}   Variable that captures a socio-demographic group. For example, this variable could equal 1 for rural households and 2 for urban ones. When this option is used, the associated varlist should contain only one variable. By default, the population groups are defined by deciles. {p_end}

{p 0 6} {cmd:nitems}   To indicate the number of items used in the simulation. For instance, if we plan to estimate the impact of the potential change in subsidies of Essence and Gasoil (we assume that we have the two variables of expenditures on these two items) the number of items is then two. {p_end}

{p 0 6} {cmd:typetr:}     To indicate the type of transfer. By default, the type is a universal per capita transfer. Set the value to 2 for the case of universal household transfer. {p_end}

{p 0 6} {cmd:appr:}   To indicate the approximation method. When this option is set to 2 (appr(2)), we take into account  interaction effects (dqdp) in computing the change in revenue. {p_end}

{p 0 6} {cmd:wappr:}   To indicate the method used to estimate the impact on well-being, consumed quantities, poverty and inequality. By default, the marginal approach is used. When this option is set to 2 (appr(2)), the modeling preferences approach is used (Cob-Douglas function). {p_end}

{p 0 6} {cmd:opr{cmd:k}: and k:1...10::}    To insert information on the item k by using the following syntax: {p_end}

{p 6 12} {cmd:sn:}    To indicate the short label of the item. {p_end}

{p 6 6} {cmd:qu:}     To indicate the quantity unit of the item. {p_end}

{p 6 6} {cmd:ps:}    To indicate the type of price schedule of the item (1: linear and 2: nonlinear: by default ps=1). {p_end}

{p 6 6} {cmd:ip:}    To indicate the price of item k before the reform.}. {p_end}

{p 6 6} {cmd:su:}    To indicate the unit subsidy of item k before the reform}. {p_end}

{p 6 6} {cmd:fp:}    To indicate the price of item k after the reform.}. {p_end}

{p 6 6} {cmd:el:}    To indicate the non-compensated own elasticity. {p_end}

{p 0 6} {cmd:oinf:}       To indicate the form to declare the information about items (name of variables of expenditues on items, prices/price shedules, etc). When variables are used to initialise the information, the value must be set to 2. {p_end}

{p 0 6} {cmd:snames:}     To declare varname of short names of items (the option oinf must be set to 2). {p_end}

{p 0 6} {cmd:itnames:}    To declare the varname of items in one string variable (the option oinf must be set to 2). {p_end}

{p 0 6} {cmd:ipsch:}            To indicate the varname of initial price schedules of items before the reform  (the option oinf must be set to 2). {p_end}

{p 0 6} {cmd:fpsch{cmd:s}}      To indicate the varname of final price schedules of items after the reform with scenario s (the option oinf must be set to 2). {p_end}

{p 0 6} {cmd:elas{cmd:s}}        To indicate the varname of the non-compensated price elasicities for scenario s (the option oinf must be set to 2). {p_end}

{p 0 6} {cmd:nscen:}      To indicate the number or simulated scenarios, which are defined by the final prices.  {p_end}


{p 0 6} {cmd:aggregate:}     To specify the desired aggregation form of results. {p_end}
{p 10 6}    Form:  # # # ... : label | # # # ... : label |...{p_end}
{p 10 6}    Example: {p_end}
{p 10 6}    If we have the following list of items:{p_end}
{p 20 6}    1- Butane {p_end}
{p 20 6}    2- Petrol {p_end}
{p 20 6}    3- Gas {p_end}
{p 20 6}    4- Cub Sugar {p_end}
{p 20 6}    5- Granulated Sugar {p_end}
{p 20 6}    6- Powdered Sugar {p_end}
{p 20 6}    7- National Flour {p_end}
{p 20 6}    8- Free Flour {p_end}

{p 10 6}    You may want to aggregate the result for sugar and flour. This may be done by adding the option: {p_end}
{p 10 6}    aggr( 4 5 6 : "Sugar" | 7 8 : "Flour" ) {p_end}

{p 0 6} {cmd:tjobs:}    You may want to produce only a subset of tables. In such case, you have to select the desired tables by indicating their codes with the option tjobs. 
For instance: tjops(11 21) . See also: {bf:{help jtables}}. {p_end}

{p 0 6} {cmd:gjobs:}    You may want to produce only a subset of graphs. In such case, you have to select the desired graphs by indicating their codes with the option gjobs. 
For instance: gjops(1 2) . See also: {bf:{help jgraphs}}. {p_end}

{p 0 6} {cmd:opgr{cmd:g} and g:1...10::}    Inserting options of graph g by using the following syntax: {p_end}

{p 6 6} {cmd:min:}    To indicate the minimum of the range of x-Axis of figure k. {p_end}
{p 6 6} {cmd:max:}    To indicate the maximum of the range of x-Axis of figure k. {p_end}
{p 6 6} {cmd:opt:}    To indicate additional twoway graph options of figure k. {p_end}
{phang}
{it:twoway_options} are any of the options documented in 
{it:{help twoway_options}}.  These include options for titling the graph 
(see {it:{help title_options}}), options for saving the graph to disk (see 
{it:{help saving_option}}), and the {opt by()} option (see 
{it:{help by_option}}).

{p 0 6} {cmd:xfil}   To indicate the name of Excel file, that will be used to save the results (*.xml format). {p_end}
{p 0 6} {cmd:folgr}   To indicate the name the folder in which the graph results will be saved. {p_end}
{p 0 6} {cmd:lan:}    By default, titles and labels are in English. Add the option lan(fr) for Frensh language.{p_end}
{p 0 6} {cmd:inisave:}    To save the subsim project information. Mainly, all inserted information in the dialogue box will be save in this file. In another session, the user can open the project using the command asubini followed by the name of project. This command will initialise all of the information of the asubsim dialog box. {p_end}

 
 {p 0 6} {cmd:cname}  To indicate the name of the country for which the simulation is performed. {p_end}
 {p 0 6} {cmd:ysvy}   To indicate the year of data survey. {p_end}
 {p 0 6} {cmd:ysvy}   To indicate the year of simulation. {p_end}
 {p 0 6} {cmd:lcur}   To indicate the name of local currency. {p_end}

 {p 0 6} {cmd:typetr}  To indicate unit concerned by the transfer (1: individual transfer | 2: household transfer). {p_end}
 {p 0 6} {cmd:gtarg}   By default, the transfer is universal. However, the user can indicate a dummy variable to indicate the targeted group by the constant transfer {p_end}

 {p 0 6} {cmd:gvimp}   To indicate the name of the new variable that will contain the per capita impact on wellbeing. {p_end}

 
{title:Author(s)}
Abdelkrim Araar
Paolo Verme

{title:Contact}
If you note any problems, please contact {bf:Abdelkrim Araar:} {browse "mailto:aabd@ecn.ulaval.ca"}



