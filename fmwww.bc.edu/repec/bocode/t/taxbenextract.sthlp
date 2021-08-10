{smcl}
{* *! version 1.1 01Apr2016}{...}
{viewerjumpto "Syntax" "taxbenextract##syntax"}{...}
{viewerjumpto "Description" "taxbenextract##description"}{...}
{viewerjumpto "Options" "taxbenextract##options"}{...}
{viewerjumpto "Install" "taxbenextract##install"}{...}
{viewerjumpto "Examples" "taxbenextract##examples"}{...}
{viewerjumpto "Authors" "taxbenextract##author"}{...}
{title:Data extraction from the OECD TAXBEN model - Desbuquois Alexandre (desbuquois.alexandre@gmail.com)}          v1.2 - 29/09/2016

{phang}
{bf:taxbenextract} {hline 2} Extracts data from the OECD TAXBEN model. 

{phang} {space 5} {p_end}

{marker syntax}{...}
{title:Syntax}
 
{p 8 16 2}
{cmdab:taxbenextract:} {it:rtype} {it:marital_status}  [{cmd:,} {it:options}]

					
{marker description}{...}
{title:Description}					
					
{p 4 4 6}
{cmd:taxbenextract} extracts data from the OECD tax and benefit (TAXBEN) model. This command is based on the latest version of the TAXBEN model published by early April 2016.
					This latter is available at {browse "http://www.oecd.org/els/soc/benefits-and-wages.htm"}, section `METHODOLOGY - DOWNLOAD THE MODEL' at the bottom of the page. 
					The command will be compatibe with future updates of the model provided that it keeps the same structure. 
					Tax and benefit levels are provided for each country - year - family situation.	Compared to the original version of the model, additional degrees of freedom are provided. 
					The user can for instance choose kids age, the number of hours worked by each member of the household, or the number of months the agent has spent unemployed.
					Instead of expressing all incomes as fraction of the Average Wage, this command gives the choice among various reference wages as deciles of the wage distribution, quartiles,
					or the minimum wage. It is also more flexible in the sense that, with only one line of code, 
					the taxbenextract command automatically combines into only one dta file different years, countries and family situations.

{pstd}	

{marker s_Options}
{title:Options}

{dlgtab:Main}

{synopt:{opt ch:ildnumber}}  - Specify the number of child for whom information have to be extracted (from zero to four).{p_end}
{synopt:{opt c:ountrylist}}  - TAXBEN country codes (2 digit codes) separated by a space.{p_end}
{synopt:{opt s:tart}}  - Specify the initial year for the extraction, e.g. start(2004).{p_end}
{synopt:{opt e:nd}}  - Specify the final year for the extraction, e.g. end(2010).{p_end}
{synopt:{opt pw:age_level}}  - Specify the wage level of the principal as a percentage of the average wage.{p_end}
{synopt:{opt pd:ays}}  - Specify the number of days worked by the principal.{p_end}
{synopt:{opt swo:rks}}  - Specify whether the secondary member of the household works or not.{p_end}
{synopt:{opt swa:ge_level}}  - Specify the wage level of the secondary earner within the household.{p_end}
{synopt:{opt sd:ays}}  - Specify the number of days worked by the secondary earner.{p_end}
{synopt:{opt tintow:ork}}  - Specify whether the agent has known a transition from unemployment to employment (yes) or if she/he was also working in the previous period (no).{p_end}
{synopt:{opt primben: }}  - Specify the primary source of benefits: UB or SA.{p_end}
{synopt:{opt sa: }}  - Specify whether individuals receive SA if conditions are meet (yes), or if you only authorise long term unemployed to receive SA (no).{p_end}
{synopt:{opt ntcp_ee: }}  - Specify whether non-tax compulsory payments paid by employees (ntcp_ee) are taken into account (yes) or not (no).{p_end}
{synopt:{opt ntcp_er: }}  - Specify whether non-tax compulsory payments paid by employers (ntcp_er) are taken into account (ys) or not (no).{p_end}
{synopt:{opt childcare: }}  - Specify whether child care benefits are included in household net income (yes) or not (no).{p_end}
{synopt:{opt ccpt: }} - Specify conditions for part-time childcare.{p_end}
{synopt:{opt postcci: }} - Specify whether child care costs are taken into account (yes) or not (no) in the household net income.{p_end}
{synopt:{opt adage: }} - Specify the adult age. Both adults are supposed to have the same age.{p_end}
{synopt:{opt cage1: }} - Specify first kid's age.{p_end}
{synopt:{opt cage2: }} - Specify second kid's age.{p_end}
{synopt:{opt cage3: }} - Specify third kid's age.{p_end}
{synopt:{opt cage4: }} - Specify fourth kid's age.{p_end}
{synopt:{opt uem:onth}} - Specify the number of months the individual has been unemployed.{p_end}
{synopt:{opt hc:ost}} - Specify the cost of housing, in percentage of the household's income.{p_end}
{synopt:{opt v:name}}  - Specify the name of the variable(s) to be selected from the extraction.{p_end}
{synopt:{opt iso:countrycodes}}  - Creates ISO country codes at 3 digit level for each country. {p_end}
{synopt:{opt gr:aph}}  - Creates a series of run-type specific graphs.{p_end}
{synopt:{opt save: }}  - Allows to directly save the created database.{p_end}
{synopt:{opt clear: }}  - Allows to clear the data, otherwise they are automatically appened.{p_end}


{dlgtab:Advanced}

{synopt:{opt split: }}  - In case where information is available, this option provides a decomposition between principal and spouse for some of the taxes and/or transfers.{p_end}

{synopt:{opt prefw:age }}  - Specify the reference for the wage level of the principal. Available choices contain deciles (q10,...,q90), quartiles (q25, Q50, q75) , average wage (AW), average production wage (APW), median (q50 or median) and minimum wage (MW).{p_end}

{synopt:{opt srefw:age }}  - Specify the reference for the wage level of the secondary member. Same options as for prefwage.{p_end}


{synopt:{opt derid:ecompos }}  - Provides a decomposition of the METR bewteen its different fiscal components (taxes and transfers).{p_end} 
{synopt: {opt in:put}} - Specify the name of the folder where the user-written files are located. This latter has to be saved into the same parent/super directory as the whole model.{p_end}

{synopt: {opt out:put}} - Provide the possibility to save the results into folders with specific names. This option must be used with the save option, otherwise the files will not be saved and the corresponding folder will not be created.{p_end}
 
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:by} is not allowed. {cmd:if} is not allowed.{p_end}
{p 4 4 2}					   
					   			   
				
{marker examples}{...}  
{title:Examples}
{phang} {space 5} {p_end} 
{phang}{cmd:. taxbenextract rtype2 single, childnumber(3) countrylist(nw) s(2001) e(2012)}{p_end}
{phang}{cmd:. taxbenextract rtype4 single, ch(1) c(ge) s(2001) e(2002) vname(details) clear}{p_end}
{phang}{cmd:. taxbenextract rtype2 married, ch(1-2) c(nw sp) s(2001) e(2002) prefwage(q20) clear}{p_end}
{phang}{cmd:. taxbenextract rtype3 married, ch(0-1) c(it us) s(2003) e(2003) derivd(yes) clear}{p_end}
{phang}{cmd:. taxbenextract rtype3 married, ch(1-2) s(2008) c(sz nw uk fr) pwage_level(70) pdays(3) sworks(1) swage_level(50) clear}{p_end}
{phang}{cmd:. taxbenextract rtype5 married, ch(2-3) c(us) pw(120) s(2004) e(2007) pdays(1) prefw(q80) swo(1) swa(20) sdays(1) srefw(q30) tintowork(no) primben(sa) childcare(yes) save(test_married_couple) }{p_end}
{phang}{cmd:. taxbenextract rtype4 married, ch(4) c(fr) pw(130) pdays(5) swo(2) tintowork(yes) primben(sa) sa(yes) childcare(yes) ccpt(2) adage(30) cage1(2) cage2(7) cage3(12) cage4(15) hcost(0.5) clear save(myfile) }{p_end}
{phang}{cmd:. taxbenextract rtype0 married, ch(1) c(ge) swo(2) primben(ub) sa(yes) childcare(yes) ccpt(2) adage(30) cage1(9) hcost(0.7) uemonth(11) graph(yes) clear}{p_end}

To use the input-output option:
{phang}{cmd:. taxbenextract rtype0 married, s(2003) c(fr) input(Fr_reform) output(Fr_UB_reform) save(UBreform_FR) clear}{p_end}
{pstd}


Please, after a few weeks of using the program, send me an email with your remarks in order to improve the code and help out bugs.


{marker author}{...}

{title:Author}

{space 8}{tab} Desbuquois Alexandre {tab} {space 6} desbuquois.alexandre@gmail.com ; a.n.desbuquois@lse.ac.uk
  
   