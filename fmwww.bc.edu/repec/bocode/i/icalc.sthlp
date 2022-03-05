{smcl}
{* *!  version 1.0 3/28/2018}
{title:Title}

{p 4 15 2}
Overview of {bf:ICALC} commands {hline 2} from Kaufman (2018) Interaction Effects in Linear and Generalized
Linear Models: Examples and Applications using Stata (Sage)

{title:Commands}

{p 4 8 2}
{help intspec} must run this before running other ICALC commands to define the interaction specifications.  See Kaufman (2018) 
for detailed explanation and step-by-step examples of using this and the other ICALC commands. 

{p 4 8 2}
{help gfi} produces algebraic expression for the effect of a focal variable as it changes with the moderators, a sign change analysis of the effect
and an optional visualization in a path-style diagram. 

{p 4 8 2}
{help sigreg} produces an empirically-derived definition of the significance region of a focal variable's effect in tabular form. Also performs, if possible, a 
Johnson-Neyman boundary value analysis to find the values of the moderating variables for which the effect of the focal variable is significant. 

{p 4 8 2}
{help effdisp} produces line plots, drop line plots, error bar plots or contour plots displaying the focal variable's effect on the observed or
 "modeled" outcome as it varies with the values of its moderator(s). Line plots and contour plots can optionally show where the moderated effect 
 of the focal variable is and is not significant.

{p 4 8 2}
{help outdisp} produces tables and/or bar charts, scatterplots or contour plots displaying the pattern of the relationship between 
interacting prdictors and the observed or "modeled" outcome. Bar charts and scatterplots can optionally superimpose main effects model 
predictions on the graphs of predicted values from the interaction model. Plots of the modeled outcome can show dual-axis labelling
in modeled and observed metrics.


{title:Author and Citation}

{p 4 4 2}
I would appreciate users of ICALC commands citing

{p 6 6 2}
Robert L. Kaufman.  2018. {it: Interaction Effects in Linear and Generalized Linear Models}, Sage Publcations. 

