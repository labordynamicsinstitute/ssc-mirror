{smcl}
{* *!version 1.1.0 12/03/2014}{...}
{cmd:help rctable}
{hline}
{title:Title}

{phang}
{bf:rctable} {hline 2} Simple tables for Randomized Controlled Trials




{title:Syntax}
{p 8 17 3}
{cmdab:rctable}
 {depvar} 
[if]
{weight} 
{cmd:,} {it:options}


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth treat:ment(treatvar)}} specify the treatment variable to be used (only one treatment branch possible){p_end} 
{synopt:{opth est:imator(esttype)}} default is ITT, other TOT possible {p_end} 
{synopt:{opth treated(varname)}}	  for TOT estimate, specify the "treated" variable {p_end} 
{synopt:{    opth  clust:er(varname)}}    specify the clustering variable if any {p_end} 
{synopt:{ opt      pval}}   		  display pvalues in square parenthesis under the standard error  {p_end} 
{synopt:{ opth  control(varlist)}}   specify the varibles used for baseline covariate adjustment. {p_end} 
{synopt:{ opt  keep }} instead of dropping the columns after running, the program keeps them in the dataset. {p_end} 
{synopt:{ opt  sd }} display the standard deviations of the average and of the control group below in square parenthesis.  
{p_end} 
{synoptline}

{p2colreset}{...}
{p 4 6 2}
{cmd:if} is allowed; see .{p_end}
{p 4 6 2}
{cmd:fweight, aweight, pweight}s are allowed; see {help weight}. {p_end} 

{title:Description}

{pstd}
 {cmd:rctable } creates simple table for Randomized Controlled Trials or experimental settings where a treatment group is compared to a comparison
group. rctable creates a table in your dataset composed of VAR (the variable name) LAB (its label) M (the average in both group) C the average in the control group, COEF (the difference between treatment and control). If the save option is specified, rctable exports the table in an excel, csv or text format. The variables created are then 
dropped. Beware, the save option includes a replace suboption by default: hence any variable called VAR LAB M C COEF will be dropped. Without option save, rctable just run the regressions.  The command only accept one treatment branch.

{pstd}
The table created has dependant variables in rows and has 7 columns: dependant variable names (VAR), dependant variable labels (LAB), number of observations 
(N_ind), number of clusters (N_clust), the average of the two groups (M), the control average (C), the difference between treatment and control (COEF).

{pstd}
The csv, excel or text document created with option save can be used either directly or be linked to an other xls or xlsx document to edit the table. That way, the xls or xlsx document can be formatted and edited 
independantly of the csvs are updated. With option keep, rctable table can also be used with listtex to create Latex tables.  

	
{title:Examples}

{phang}
Perform a simple ITT regression on several dependant varibles : {break}
{cmd:. rctable unemployment_rate health_score cognitive_score noncognitive_score, treat(treat_variable)}

{phang}
Save the results in a csv table :  {break}
{cmd:. rctable unemployment_rate health_score cognitive_score noncognitive_score, treat(treat_variable) save(C:\mytable.csv)}

{phang}	
	Perform a simple TOT regression on several dependant varibles : {break}
 {cmd:. rctable unemployment_rate health_score cognitive_score noncognitive_score, treat(treat_variable) estimator(TOT) treated(treated_variable)}
 
{phang}
Edit a simple Latex table using listtex and the keep option  : {break}
 {cmd:. rctable unemployment_rate health_score cognitive_score noncognitive_score, treat(treat_variable) estimator(ITT) treated(treated_variable) keep save(C:\mytable.csv) }

#delimit ;
listtex LAB    N_ind  N_clust M C COEF  if COEF!="" | LAB!=""   using "$table/baseline_s.txt", replace rstyle(tabular) 
head(" \begin{table}[htbp] \centering \begin{threeparttable}[b]  \medskip 
\begin{tabularx}{10cm}{l c c c c c \toprule & N  & Cluster & Average & C  &  {T-C} \\ 
\midrule") 
foot("\hline
  \end{tabularx} 
  \fignote{}
\end{threeparttable}
\end{table}");
#delimit cr	


{title:Author}
{pstd}
Adrien Bouguen, Paris School of Economics, J-PAL Europe 
abouguen@povertyactionlab.org
