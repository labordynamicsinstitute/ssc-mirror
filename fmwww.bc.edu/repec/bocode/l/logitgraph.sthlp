{smcl}
{* 24oct2024}{...}
{title:logitgraph: Graph of the Probabilities from a Logistic Regression Model}

{p 4 4 2} Version 18.0

{p 4 4 2} October 24, 2024

{title:Syntax}

{p 4 4 2} {opt logitgraph}
{it:{help logitgraph##varname:varname}}
{it:{help logitgraph##varlist:varlist}}{cmd:,}
{it:{help logitgraph##options:options}}

{title:Description}

{p 4 4 2} {cmd:logitgraph} is a chart that horizontally displays the probabilities and their confidence intervals for all combinations of categories of each independent variable in a logistic regression model.

{title:Program Limitations}

{p 4 4 2} 1. Logitgraph quietly runs the command {it:logit varname varlist}. Its goal is to visually display the probabilities and their confidence intervals in an appealing way by showing probabilities directly instead of logits.

{p 4 4 2} 2. Logitgraph has not been designed to select the most appropriate variables for inclusion in the model. This graph should be created once the independent variables that will make up the final model have been selected.

{p 4 4 2} 3. This program will display the variable labels instead of the variable names and the value labels of the categories instead of the values.

{p 4 4 2} 4. The final result of the chart vary significantly depending on the number of categories for each of the selected independent variables. Once a preliminary chart has been constructed, the dialog box can be useful for small adjustments.

{title:Options}

{synoptset 40 tabbed}{...}
{marker varname}{...}
{synopt :{opt varname}}Name of the dependent variable.{p_end}
{marker varlist}{...}
{synopt :{opt varlist}}Name(s) of de independent variable(s).{p_end}
{marker options}{...}
{synopt :{opt keepvarorder}}If specified, it maintains the order of the independent variables as provided and does not sort them by significance.{p_end}
{synopt :{opt keepcatorder}}If specified, it maintains the default order of each variable’s categories and does not reverse it if the variable’s coefficient is negative.”{p_end}
{synopt :{opt linedist(#)}}Sets the vertical distance between the confidence intervals; the default is 1.{p_end}
{synopt :{opt bgcolor(string)}}Sets the color of the background of the chart in RGB; the default is white.{p_end}
{synopt :{opt textcolor(string)}}Sets the color of the text of the chart in RGB; the default is black.{p_end}
{synopt :{opt textsize(#)}}Sets the size of the text of the chart in pt; the default is 8pt.{p_end}
{synopt :{opt lcolor(string)}}Sets a unique color for the confidence interval line of the chart in RGB; the default is black.{p_end}
{synopt :{opt lcolor0(string)}}Sets the color of the confidence interval line if the probability is 0 and creates a gradient toward lcolor1 in RGB; the default is 255 255 80.{p_end}
{synopt :{opt lcolor1(string)}}Sets the color of the confidence interval line if the probability is 1 and creates a gradient from lcolor0 in RGB; the default is 200 0 150.{p_end}
{synopt :{opt colorlongway}}If specified, it will create the color gradient by rotating the hue along the longest path; for example, from red to yellow passing through violet, blue, and green instead of through orange.{p_end}
{synopt :{opt ptcolor(string)}}Sets the color of the interior of the point estimate marker; the default is similar to that of the line.{p_end}
{synopt :{opt ptsize(#)}}Sets the size of the point estimate marker in pt; the default is 6pt.{p_end}
{synopt :{opt labelgap(#)}}Sets the vertical separation between the confidence interval and the label of the point estimate value in pt; the default is 5pt.{p_end}
{synopt :{opt hideci}}If specified, the confidence interval will not be displayed.{p_end}
{synopt :{opt hidecilim}}If specified, the limits of the confidence interval will not be displayed.{p_end}
{synopt :{opt linewidth(#)}}Sets the width of the confidence interval in pt; the default is 3pt.{p_end}
{synopt :{opt basecolor(string)}}Sets the color of the base segment in RGB; the default is 200 200 200.{p_end}
{synopt :{opt basewidth(#)}}Sets the width of the base segment in pt; the default is 1pt.{p_end}

{title:Author}

{p 4 4 2} Emilio Domínguez-Durán, emilienko@gmail.com
