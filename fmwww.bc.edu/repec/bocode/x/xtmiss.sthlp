{smcl}
{* 11Apr2025}{...}
{hline}
help for {hi:xtmiss}
{hline}

{title:Report Missing Observations of Individual and Time variables in Panel Data}

{cmd:xtmiss} report missing observations of individual and time variables in panel data.

{marker syntax}{...}
{title:Syntax}

{p 4 32 2}{cmd:xtmiss} {ifin} {cmd:,} {opt i:d(varlist)} {opt t:ime(varlist)} [ {opt b:oth} {opt p:unct(parse_strings)}
{opt j:oin(parse_strings)} {opt e:xist} {opt k:eep} {opt a:scending} {opt d:escending} {opt n:olist} ] {p_end}


{synoptset 21 tabbed}{...}
{marker options}{...}
{synopthdr}
{synoptline}
{synopt :{opt i:d(varlist)}}defines the individual variable(s) (or the panel variable).{p_end}
{synopt :{opt t:ime(varlist)}}defines the time variable(s) (or the grouping variable).{p_end}
{synopt :{opt b:oth}}is optional, also reports on missing observations of time variable. The default is only reporting on individual variable(s).{p_end}
{synopt :{opt p:unct(parse_strings)}}is optional, specifies strings to concatenate variables in {opt i:d(varlist)} and {opt t:ime(varlist)}; See function {cmd:concat()} in {helpb egen} for details.{p_end}
{synopt :{opt j:oin(parse_strings)}}is optional, specifies strings to concatenate missing elements in {opt i:d(varlist)} and {opt t:ime(varlist)}. The default is {opt j:oin}{cmd:(}{res:;}{cmd:)}.{p_end}
{synopt :{opt e:xist}}is optional, generates a new variable on the number of existing individual and time variable(s); should set with option {opt k:eep}.{p_end}
{synopt :{opt k:eep}}is optional, generates new variables on missing situations of individual and time variables.{p_end}
{synopt :{opt a:scending}}is optional, displays rows in ascending order of the number of missing observations of individual (or time) variables.{p_end}
{synopt :{opt d:escending}}is optional, displays rows in descending order of the number of missing observations of individual (or time) variables.{p_end}
{synopt :{opt n:olist}}is optional, doesn't displays the results of missing situations. It is invalid if option {opt k:eep} is not set.{p_end}
{synopt :{it:list_options}}are optional, are any options available for {helpb list}.{p_end}
{synoptline}
{p2colreset}{...}

{p 4}{res:*** Important Notes:}{p_end}
{p 4 7 2}1. Both options {opt i:d(varlist)} and {opt t:ime(varlist)} allow setting multiple variables with different types;{p_end}
{p 4 7 2}2. The option {opt a:scending} or {opt d:escending} should be set at most one, and will be invalid if option {opt n:olist} is set;{p_end}
{p 4 7 2}3. If the option {opt k:eep} is set, the command {cmd:xtmiss} may generate the following variables:{break}
{cmd:Id_Miss}, {cmd:Id_Total}, {cmd:Id_MProp}, {cmd:Id_MissElm} ;{break}
{cmd:Id_Var}, {cmd:Time_Var} (not keep) ;{break}
{cmd:Id_Exist}, {cmd:Time_Exist} (if option {opt e:xist} is set);{break}
 {cmd:Time_Miss}, {cmd:Time_Total}, {cmd:Time_MProp}, {cmd:Time_MissElm} (if option {opt b:oth} is set).{p_end}


{title:Examples}

{phang}
{cmd:. xtmiss , id(prov) time(year)}

{phang}
{cmd:. xtmiss , id(prov) time(year) both}

{phang}
{cmd:. xtmiss , id(prov) time(year) keep}

{phang}
{cmd:. xtmiss , id(prov) time(year) both keep}

{phang}
{cmd:. xtmiss , id(prov) time(year) ascending}

{phang}
{cmd:. xtmiss , id(prov) time(year) both descending}

{phang}
{cmd:. xtmiss , id(prov) time(year) nolist keep}

{phang}
{cmd:. xtmiss , id(prov) time(year) exist keep}

{phang}
{cmd:. xtmiss , id(prov) time(year) join(,)}

{phang}
{cmd:. xtmiss , id(prov city) time(year)}

{phang}
{cmd:. xtmiss , id(prov city) time(year) punct(-)}

{phang}
{cmd:. xtmiss , id(prov city) time(year month)}

{phang}
{cmd:. xtmiss , id(prov city) time(year month) both}

{phang}
{cmd:. xtmiss , id(city) time(year month) both keep}

{phang}
{cmd:. xtmiss if inrange(year,2003,2022) , id(prov) time(year)}

{phang}
{cmd:. xtmiss , id(prov) time(year) notrim}

{phang}
{cmd:. return list}


{title:Returned Values}

{synoptset 21 tabbed}{...}
{synopt:{cmd:r(Idvars)}}the list of the individual variable(s).{p_end}
{synopt:{cmd:r(Timevars)}}the list of the time variable(s).{p_end}
{synopt:{cmd:r(missing_num)}}the number of missing observations in the current data.{p_end}
{synopt:{cmd:r(exist_num)}}the number of existing observations in the current data.{p_end}
{synopt:{cmd:r(balance_num)}}the number of total observations if the current data is balanced.{p_end}


{title:Authors}
{phang}
{cmd:Dejin Xie}, School of Economics and Management, Nanchang University, China.{break}
 E-mail: {browse "mailto:xiedejin@ncu.edu.cn":xiedejin@ncu.edu.cn}.{break}


{title:Also see}
{p 4 14 2}Help: {helpb xtdescribe}, {helpb egen}, {helpb gsort}; {helpb stvarag}, {helpb xtmis},
{helpb xtpattern}, {helpb xtbalance}, {helpb missings} (if they are installed).{p_end}
