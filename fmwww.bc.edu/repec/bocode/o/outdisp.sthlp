    {smcl}
    {* *!  version 1.0 2/27/2018}
    {title:Title}
    
    {p 4 15 2}
    {cmd:outdisp} {hline 2} creates tables or graphs of the observed or "modeled" outcome showing how it varies with a set of interacting predictors 
    with options to unpack the confounded non-linearities of interactions with prediction functions for generalized linear models.
    
    {title:Description}
    
    {p 4 4 2}
    {cmd:outdisp} produces tables and/or bar charts, scatterplots or contour plots displaying the pattern of the relationship between 
    interacting prdictors and the observed or "modeled" outcome. Bar charts and scatterplots can optionally superimpose main effects model 
    predictions on the graphs of predicted values from the interaction model. Plots of the modeled outceoem can show dual-axis labelling
     in modeled and observed metrics. Must run {help intspec} before running {cmd:outdisp}. 
    See Kaufman (2018) for detailed explanation and step-by-step examples of using this and other ICALC add-on commands. 
    
    {title:Syntax}
    
    {p 2 10 2}
    {cmd:outdisp} {cmd:,} [ {opt out:come:}({opt metric}({it:predtype}) {opt atopt}({it:marginspec}) {opt sdy} {opt dual:axis} {opt main:est}({it:estname})) 
    {opt plot}({opt type}({it:plottype}) {opt sing:le}({it:detail}) {opt name}({it:graphname}) {opt save}({it:filepath}) {opt freq}({it:base}) 
    {opt keep:frq} {opt ccuts}({it:numlist}))) {opt tab:le}({opt rowvar}({it:type}) {opt save}({it:filepath}) {opt freq}({it:base}) {opt abs}) 
    {opt ndigits}(#) {opt pltopts}({it:string}) ]    
     
    {p2colset 2 25 25 2}
    {p2col: {it:options}}Description {p_end}
       {hline}
    {p2colset 2 25 27 2}
    {p2col:{cmd:outcome(metric}({it:predtype}) {opt suboptions})}get predictions in observed or modeled metric, prediction and display suboptions{p_end}
    {p2colset 5 25 25 2}
    {p2col:{cmd:metric}({it:predtype})}{it:plottype} is {it:obs} for observed metric ({bf:default}), {it:model} for modelled metric{p_end}
    
    {p2col:{opt suboptions}}{p_end}
    {p2colset 7 25 27 2}
    {p2col: {cmd:atopt}({it:marginspec})}Specify content for the at( ) option of the {help margins} command for predictors other than focal 
    or moderators. {bf:Default atopt((asobs) _all)}{p_end}
    {p2col: {cmd:sdy}}keyword {opt sdy} valid only with {bf:metric(model)}. Labels the primary y-axis in model metric standard 
    deviation units (if applicable){p_end}
    {p2col: {cmd:dualaxis}}keyword {cmd:dualaxis} valid only with metric(model). Adds a 2nd y-axis labelled in the observed outcome metric. 
    Not valid for mlogit{p_end}
    {p2col: {cmd:mainest}({it:estname})} valid only with {bf:metric(obs)}. Adds main effects predictions to interaction effects display. 
    Must have used {bf: estimates store {it:estname}} to save main effects model estimates.{p_end}
    {p2colset 4 24 26 2}
    {p2col:{cmd:plot(type}({it:plottype}) {opt suboptions})}specifies how to plot outcome varying with the focal and moderating variables{p_end}
    {p2colset 7 24 26 2}
    {p2col:{cmd:type}({it:plottype})}{ul:{it:plottype} is keyword for type of plot}  {p_end}
    {p2colset 7 25 25 2}
    {p2col: {cmd: }}{cmd:scat} for scatterplot, default if focal is interval {p_end}
    {p2col: {cmd: }}{cmd:bar} for bar chart, default if focal is categorical {p_end}
    {p2col: {cmd: }}{cmd:contour} for contour plot, only if focal & 1st moderator are interval{p_end}
    {p2col:{it:suboptions}}{p_end}
    {p2colset 8 24 26 2}
    {p2col: {cmd:name}({it:graphname})}save plot as memory graph with name {it:graphname}{p_end}
    {p2colset 8 24 26 2}
    {p2col:{opt sing:le}({it:detail})}{ul:{it:detail} is # or keyword for what is shown on single graph}  {p_end}
    {p2colset 8 25 25 2}
    {p2col: {cmd: }}{cmd:1} show separate outcome-focal plots for each display value of moderator#1{p_end}
    {p2col: {cmd: }}{cmd:2} show all moderator#1 results on same outcome-focal plot but a single graph for each display value of moderator#2{p_end}
    {p2col: {cmd: }}{cmd:all} show separate outcome-focal plots for each combination of moderator#1 and moderator#2 display values{p_end}
    
    {p2col: {cmd:save}({it:filepath})}save plotting data & frequency distribution to Excel file with name & location given by {it:filepath}{p_end}
    
    {p2col: {cmd:freq}({it:base})}add relative frequency distribution of 1st moderating variable or 1st by 2nd moderator to the plot{p_end}
    {p2col: {cmd: }}{ul:{it:base} can be            }{p_end}
    {p2col: {cmd: }}  {it:tot} for distribution of 1st moderator {p_end}
    {p2col: {cmd: }}  {it:sub} for distribution of the 1st moderator within levels of the 2nd{p_end}
    {p2col: {cmd: }}  {it:subtot} for joint distribution of the 1st & 2nd moderators relative to total sample size{p_end}
    
    {p2col: {cmd:keepfreq}} save the separate frequency distribution graphs used to create final frequency graph{p_end}
    
    {p2colset 4 24 26 2}
    {p2col:{cmd:table({it:suboptions}))}}make table of predicted outcome by focal & moderating variables{p_end}
    {p2colset 7 24 26 2}
    {p2col:{it:suboptions}}{p_end}
    {p2colset 8 24 26 2}
    {p2col: {cmd:rowvar}({it:type})}keyword {it:type} = {it:focal} or {it:mod} to define table rows. {bf:Default rowvar(focal)}{p_end}
    {p2col: {cmd:save}({it:filepath})}same as for {cmd:plot} {it:suboptions}{p_end}
    {p2col: {cmd:freq}({it:base})}same as for {cmd:plot} {it:suboptions}{p_end}
    
    {p2col:{cmd:ndigits(#)}}number of digits for {it:y}-axis labels {bf:Default = 4}. {p_end}
    {p2col: {cmd:ccuts}({it:numlist})}{it:numlist} defines contour cutpoints. {bf:Default is 6 equal steps from min to max of predicted outcome.}{p_end}
    {p2col:{cmd:pltopts}({it:string})}{it:string} contains {help twoway_options:two-way graph options} to customize appearance (e.g. line colors). These do not always work as expected. 
    Use the graph editor if not.{p_end}
    
    {p 2 11 2}
    {bf:Note:} Focal and moderator {cmd:range( )} define display values/labels on axis plotting focal variable (contour plots: also for 1st moderator). 
    For tables, sets display values/labels of row and column. For both plots and tables, moderators’ range( ) defines calculation points 
    at which the plot or table calculations are repeated.
    
	{p 0 0 2}
    {title:Example: two-way interaction}
    
    {p 0 0 2}
    For a model predicting poor mental health days ({it:pmhdays}) by the interaction of work-family conflict ({it:wfconflict}) 
    and job status ({it:sei}), {cmd:intspec} specfies {it:wfconflict} as the focal variable and {it:sei} as its moderator.  {cmd:outdisp} 
    produces a scatterplot of the predicted count for {it:pmhays} against {it:wfconflict} with separate prediction curves for each of the 5 display value of {it:sei} (17, 37, 57, 77, 97), the default plot type.
    
    {p 6 10 2}
    nbreg pmhdays c.wfconflict##c.sei ... {p_end}
    {p 6 10 2}
    intspec, focal(c.wfconlifct) main( (c.sei name(JobStatus) range(17(20)97)) (c.wfconflict name(WorkFamConflict) range(1/4))) int2vars(c.wfconflict#c.sei) {p_end}
    {p 6 10 2}
    
    outdisp ,  plot(type(scat)) ndigits(2)
    
    
    {p 2 4 2}
    *** Add superimposed main effects plot from model estimates stored in mymainmod
    
    {p 6 10 2}
    outdisp ,  plot(type(scat)) outcome(main(mymainmod)) ndigits(2)
    
    {p 2 4 2} 
    *** Change to modelled outcome (ln count) metric
    
    {p 6 4 2}
    outdisp ,  plot(type(scat))) outcome(metric(model)) ndigits(2)
    
    
    {p 2 4 2}
    *** Add 2nd y-axis labelled as count to primary y-axis labelled as log count
    
    {p 6 4 2}
    outdisp ,  plot(type(scat))) outcome(metric(model) dualaxis) ndigits(2)
    
    
    {p 2 4 2}
    *** Change plot type to contour
    
    {p 6 4 2}
    outdisp ,  plot(type(cont))) outcome(metric(model) dualaxis) ndigits(2)
    
	{p 2 2 2} {bf:Note} that for a three-way interaction {cmd:outdisp} creates repeated plots of the predicted outcome 
	against the focal variable with separate prediction curves for each display value of the first moderator.
	This plot is repeated for each display value of the second moderator.
	
    
    {title:Author and Citation}
    
    {p 4 4 2}
    I would appreciate users of this and other ICALC commands citing
    
    {p 6 6 2}
	Robert L. Kaufman.  2018. {it: Interaction Effects in Linear and Generalized Linear Models}, Sage Publcations. 
    
