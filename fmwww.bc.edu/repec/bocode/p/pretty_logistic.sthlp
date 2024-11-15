{smcl}
{* *! version 1.0 06 February 2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "pretty_logistic##syntax"}{...}
{viewerjumpto "Description" "pretty_logistic##description"}{...}
{viewerjumpto "Options" "pretty_logistic##options"}{...}
{viewerjumpto "Remarks" "pretty_logistic##remarks"}{...}
{viewerjumpto "Examples" "pretty_logistic##examples"}{...}
{hline}
help for {cmd:pretty_logistic} {right: Version 1.0 06 February 2024}
{hline}
{title:Author}
{tab}Georgia McRedmond & Rafael Gafoor
{tab}University College London, London UNITED KINGDOM 
{tab}{cmd:r.gafoor@ucl.ac.uk}

{tab}{bf:Version} 	     {bf:Date}    		  {bf:Comments}
{tab}1.0		06 February 2024	First release

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:pretty_logistic}
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]


{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required }
{synopt:{opt predictor:}({help varname})} - grouping variable. 

{syntab:Optional}
{synopt:{opt logtype}({help string})} - {it: string} may be {bf: rr rd or}. {it: string} specifies the coefficent to be returned. {p_end}
{synopt:{opt out:comes}({help varlist})} - specified outcome variables. {p_end}
{synopt:{opt con:founders}({help varlist})} - confounding variables. {help fvvarlist} operators can be used to specify relationships and factor/continuous variables. {p_end}
{synopt:{opt re:equation}({help string})} - {it: string} may used to specify random effects following {help melogit} {it: syntax} for random effects equations, the initial || does not need to be specified. {p_end}
{synopt:{opt title:}({help string})} - title the table will be saved by. when multiple tables generated separate titles by {bf: ,} {p_end}
{synopt:{opt nosub:headings}({help string})} - option to remove primary and secondary outcome titles if multiple outcomes specified. {p_end}
{synopt:{opt flog}({help format})} - specify the format of decimal points for the main coefficients. {p_end}
{synopt:{opt fci}({help format})} - specify the format of decimal points for the confidence intervals. {p_end}
{synopt:{opt fp}({help format})} - specify the format of decimal points for the probability. {p_end}

{synoptline}


{p2colreset}{...}
{p 4 6 2}

{title:Description}

{phang}{marker description}{cmd:pretty_logistic} generates publication quality tables of logistic coefficients.{p_end}

{pstd}
{opt pretty_logistic} generates unadjusted and adjusted risk difference, risk ratio or odds ratio tables. {opt pretty_logistic} can  produce up to three tables. These tables can be exported to a docx file using {help putdocx}.
The counts and percents by the predictor variable will be produced, alongside the specified logistic coefficient, 95% confidence interval and p-value. 

{pstd}
The default number of decimal places for the logistic coefficient, 95% confidence interval, and p-value are three decimal places. The percentage output has a default of 1 decimal place. The decimal place options can be changed for 
the coefficient, the 95% confidence interval, and the p-value using the {it: flog, fci} or {it: fp} options. Guidance can be found in Stata help files for the formatting options {help format}. 

{pstd}
Confounders can be specified using the {opt confounders} option. Confounders can be categorical or continuous, factor and continuous confounders as well as their relationship to each other can be specified through factor-variable operators. 
Guidance can be found in Stata help files for the factor-variabel operator options {help fvvarlist}. 

{pstd}
Random effects equations can be specified using the {opt reequation} option. Random effects are to be written in the syntax specified by {help melogit}. The re_options from {help melogit} can be used. The first set of || used to differentiate fixed effects equation from random effects equation are pre-included.

{pstd}
The default variable labels for the table are the variable labels from the dataset. Where variable labels are not specified, variable names will be presented.

{pstd}
The default notes for adjusted coefficents use the confounder variable labels from the dataset. Where variable labels are not specified for all confounders, variable names will be presented. 


{marker examples}{...}

{title:Examples}
{marker examples}{...}

{hline}

Setup
{tab}{phang}{cmd:. webuse nhanes2l, clear}{p_end}

Basic Risk Ratio Table
{tab}{phang} {cmd:. pretty_logistic, predictor(diabetes) logtype(rr) outcomes(heartatk)}

{hline}

Setup
{tab}{phang}{cmd:. webuse nhanes2l, clear}{p_end}

Adjusted Odds Ratio Table
{tab}{phang} {cmd:. pretty_logistic, predictor(diabetes) logtype(or) outcomes(heartatk) confounders(c.age##i.highbp) title(Table 1)}

{hline}

Setup
{tab}{phang}{cmd:. webuse bangladesh, clear}{p_end}

Adjusted Risk Difference Table with Random Effects
{tab}{phang}{cmd:. pretty_logistic, predictor(urban) logtype(rd) outcomes(c_use) confounders(age i.children) reequation(district:) title(Table 1)}

{hline}

Setup
{tab}{phang}{cmd:. webuse nhanes2, clear}{p_end}

Multiple Tables with Multiple Outcomes
{tab}{phang} {cmd:. pretty_logistic, predictor(diabetes) logtype(or rr rd) outcomes(heartatk highbp) confounders(c.age i.female) title(Table 1, Table 2, Table 3) flog(%9.2fc)}











