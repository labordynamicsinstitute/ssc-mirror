{smcl}
{* *! version 2.0  08jan2024}{...}
{viewerjumpto "Syntax" "epitable3##syntax"}{...}
{viewerjumpto "Description" "epitable3##description"}{...}
{viewerjumpto "Options" "epitable3##options"}{...}
{viewerjumpto "Examples" "epitable3##examples"}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:epitable3} {hline 2}}Create a table of association between exposure and outcome variables by various stratification variables.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{phang}
Create a table of association between an exposure variable and an outcome variable, broken down by various stratification variables.{p_end}

{p 8 17 2}
{cmdab:epitable3} {bf:commandname} {it:{depvar}} {it:xvar} {it:{indepvars}} [{it:{help if}}] [{it:{help in}}] [{it:{help weight}}], by({it:groupvars}) [{it:{help options}}]

{synoptset 20}{...}
{marker options}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt dp(#)}}set coeff. & conf. int. to {it:#} decimal places; default is {cmd:dp(2)}{p_end}
{synopt :{opth ci:limiter(strings:string)}}conf. int. separator; default is {cmd:cilimiter("-")}{p_end}
{synopt :{opth ti:tle(strings:string)}}Add a title to your table{p_end}
{synopt :{opth no:tes(strings:string)}}Add note(s) to your table, mutliple notes need to be enclosed in double-quotes{p_end}
{synopt :{opth ptr:endvar(varname)}}Calculates the p for trend based on the variable specified instead of {it:xvar}; designed to allow application of a median in each quartile{p_end}
{synopt :{opth after:covars(varlist)}}This is required for {it:{help mixed}} regressions, or any other regression where additions are made after the {it:{indepvars}} are given{p_end}
{synopt :{opth collect:ion(strings:string)}}Name the collection your table will be collected into; default is {cmd:collection("table3")}{p_end}
{synopt :{opt export}}exports to a currently open {it:{help putdocx}} document, or opens and exports to a new {it:{help putdocx}} document{p_end}
{synopt :{opt opcon}}Caculates p for interaction as the opposite of {it:xvar} type; if {it:xvar} is factor calculates p for interaction as continuous and vice versa{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:export} does not save the document, allowing you to continue adding to it.{p_end}

{p 4 6 2}Options used by {bf:commandname} should also be able to be applied here, though this has not been extensively tested.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:epitable3} creates a table with regression coefficients and 95% confidence intervals for {it:xvar}, broken down by various stratified or factor variables. A p-value for trend of each individual within-variable category is given, as well as a 
p-value for interaction for each overall stratified or factor variable. If {it:xvar} is given as a factor variable, the regression coefficients and 95% confidence intervals for {it:xvar} are shown over each quartile.{p_end}

{pstd}
This table is commonly referred to as Table 3 in epidemiological studies. The layout is pre-defined and uses shorter syntax, allowing for faster table generation than would be possible if the user set the table up themselves using {help collect} 
commands.{p_end}

{marker examples}{...}
{title:Examples}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nhanes2}

{phang2}{cmd:. collect clear}

{pstd}Create a table of association for a continuous covariate{p_end}

{phang2}{cmd:. epitable3 logistic diabetes lead age bmi highbp, by(sex race region)}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nhanes2}

{phang2}{cmd:. collect clear}

{phang2}{cmd:. xtile iron4c = iron, nq(4)}

{pstd}Create a table of association for a factor covariate (usually only has 4 factors){p_end}

{phang2}{cmd:. epitable3 logistic diabetes i.iron4c age bmi highbp, by(sex race region)}

{hline}
{title:Notes}

{pstd}While this command has been designed to work with various regression modelling commands, it has only been tested by the author on {help regress}, {help logistic}, and {help mixed}. It has not been extensively tested. If you encounter errors 
with other commands, please forward them through to the author.

{title:Author}

{pstd}Laura C Whiting{p_end}
{pstd}IT Support{p_end}
{pstd}Survey Design and Analysis Services{p_end}
{pstd}Canberra, Australia{p_end}
{pstd}{browse "mailto:support@surveydesign.com.au":support@surveydesign.com.au}

{pstd}This package was developed with the assistance and direction of:{p_end}
{pstd}Zumin Shi{p_end}
{pstd}Human Nutrition Department, College of Health Sciences, QU Health{p_end}
{pstd}Qatar University{p_end}
{pstd}Doha, Qatar{p_end}

