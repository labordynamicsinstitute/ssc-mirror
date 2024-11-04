{smcl}
{* *! version 1.0 10 October 2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "pretty_linear##syntax"}{...}
{viewerjumpto "Description" "pretty_linear##description"}{...}
{viewerjumpto "Options" "pretty_linear##options"}{...}
{viewerjumpto "Remarks" "pretty_linear##remarks"}{...}
{viewerjumpto "Examples" "pretty_linear##examples"}{...}
{hline}
help for {cmd:pretty_linear} {right: Version 1.0 10 October 2024}
{hline}
{title:Author}
{tab}Georgia McRedmond & Rafael Gafoor
{tab}University College London, London UNITED KINGDOM 
{tab}{cmd:r.gafoor@ucl.ac.uk}

{tab}{bf:Version} 	     {bf:Date}    		  {bf:Comments}
{tab}1.0		10 October 2024		First release

{marker syntax}{...}
{title:Syntax}
{p 3 7 2}
{cmdab:pretty_logistic}
[{help if}]
[{help in}]
[{cmd:,}
{it:options}]


{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt independent:}({help varname})} - Independent Variable. {p_end}
{synopt:{opt dependent:}({help varlist})} - Dependent Variable(s).

{syntab:Optional}
{synopt:{opt con:founders}({help varlist})} - Confounding variables.{help fvvarlist} operators can be used to specify relationships and factor/continuous variables. {p_end}
{synopt:{opt flin}({help format})} - Specify the format of decimal points for the main coefficients. {p_end}
{synopt:{opt fci}({help format})} - Specify the format of decimal points for the confidence intervals. {p_end}
{synopt:{opt fp}({help format})} - Specify the format of decimal points for the probability. {p_end}
{synopt:{opt sav:ing}({help saving})} - Saves table as docx, can specify path and name of file. {p_end}

{synoptline}


{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
{marker description}{cmd:pretty_logistic} generates publication quality tables of linear regression results.{p_end}

{pstd}
The linear coefficient, 95% confidence interval and p-value will be produced. {p_end}

{pstd}
The default number of decimal places for the linear coefficient, 95% confidence interval, and p-value are three decimal places. The decimal place options can be changed for 
the coefficient, the 95% confidence interval, and the p-value using the {it: flog, fci} or {it: fp} options. Guidance can be found in Stata help files for the formatting options {help format}. {p_end}

{pstd}
Confounders can be specified using the {opt confounders} option. Confounders can be categorical or continuous, factor and continuous confounders as well as their relationship to each other can be specified through factor-variable operators. 
Guidance can be found in Stata help files for the factor-variabel operator options {help fvvarlist}. {p_end}


{pstd}
The default variable labels for the table are the variable labels from the dataset. Where variable labels are not specified, variable names will be presented. {p_end}

{pstd}
The default notes for adjusted coefficents use the confounder variable labels from the dataset. Where variable labels are not specified for all confounders, variable names will be presented. {p_end}


{marker examples}{...}

{title:Examples}
{marker examples}{...}

{hline}

Setup
{tab}{phang}{cmd:. webuse nhanes2l, clear}{p_end}

Basic Linear Regression Table
{tab}{phang} {cmd:. pretty_linear, independent(age) dependent(bmi)}

{hline}

Setup
{tab}{phang}{cmd:. webuse nhanes2l, clear}{p_end}

Adjusted Linear Regression Table
{tab}{phang} {cmd:. pretty_linear, independent(age) dependent(bmi)confounders(c.vitaminc##i.highbp)}

{hline}

Setup
{tab}{phang}{cmd:. webuse nhanes2l, clear}{p_end}

Linear Regression Table with Multiple Dependent Variables
{tab}{phang} {cmd:. pretty_linear, independent(age) dependent(bmi weight) confounders(c.vitaminc i.heartatk) flin(%9.2fc)}

{hline}








