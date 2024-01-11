{smcl}
{* *! version 2.0  08jan2024}{...}
{viewerjumpto "Syntax" "epitable2##syntax"}{...}
{viewerjumpto "Description" "epitable2##description"}{...}
{viewerjumpto "Options" "epitable2##options"}{...}
{viewerjumpto "Examples" "epitable2##examples"}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:epitable2} {hline 2}}Create a composite table for a set of multivariable models{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{phang}
Create a composite table after running a set of multivariable models through the {it:{help collect}} prefix

{p 8 17 2}
{cmdab:epitable2} {varname} [{cmd:,} {it:{help epitable2##options:options}}]
 
 {synoptset 20}{...}
{marker options}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt dp(#)}}set coeff. & conf. int. to {it:#} decimal places; default is {cmd:dp(2)}{p_end}
{synopt :{opth ci:limiter(strings:string)}}conf. int. separator; default is {cmd:cilimiter("-")}{p_end}
{synopt :{opth ti:tle(strings:string)}}Add a title to your table{p_end}
{synopt :{opth no:tes(strings:string)}}Add note(s) to your table, mutliple notes need to be enclosed in double-quotes{p_end}
{synopt :{opt inc:lude}}include all covariates in the table; default is to show {varname} only{p_end}
{synopt :{opt long}}set table layout as long; default is wide{p_end}
{synopt :{opt export}}exports to a currently open {it:{help putdocx}} document, or opens and exports to a new {it:{help putdocx}} document{p_end}
{synopt :{opt show:p}}display all p-values in the table; default is to only show trend p-values{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:export} does not save the document, allowing you to continue adding to it.

{marker description}{...}
{title:Description}

{pstd}
{cmd:epitable2} creates a composite table with regression coefficients and 95% confidence intervals after running a set of multivariable models. Each multivariable model that you want included must be collected with the {help collect} prefix.
All models must be collected into the same collection before this command can be run. The collection must be the current collection.{p_end}

{pstd}
This table is commonly referred to as Table 2 in epidemiological studies. The layout is pre-defined and uses shorter syntax, allowing for faster table generation than would be possible if the user set the table up themselves using {help collect} 
commands.{p_end}

{marker examples}{...}
{title:Examples}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nhanes2}

{phang2}{cmd:. collect clear}

{pstd}Create a table comparing coefficients for a continuous covariate{p_end}

{phang2}{cmd:. collect: logistic diabetes iron}

{phang2}{cmd:. collect: logistic diabetes iron age i.sex}

{phang2}{cmd:. collect: logistic diabetes iron age i.sex bmi i.highbp}

{phang2}{cmd:. epitable2 iron}

{hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nhanes2}

{phang2}{cmd:. collect clear}

{phang2}{cmd:. xtile iron4c = iron, nq(4)}

{pstd}Create a table comparing individual factors for a factor covariate (usually only has 4 factors){p_end}

{phang2}{cmd:. collect: logistic diabetes i.iron4c}

{phang2}{cmd:. collect: logistic diabetes i.iron4c age i.sex}

{phang2}{cmd:. collect: logistic diabetes i.iron4c age i.sex bmi i.highbp}

{phang2}{cmd:. epitable2 i.iron4c}

{hline}
{title:Notes}

{pstd}While this command has been designed to work with various regression modelling commands, it has only been tested by the author on {help regress} and {help logistic}. It has not been extensively tested. If you encounter errors with other 
commands, please forward them through to the author.

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

