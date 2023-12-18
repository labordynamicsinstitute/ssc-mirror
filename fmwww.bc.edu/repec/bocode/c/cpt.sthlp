{smcl}
{* *! version 1.0 16 Dec 2022}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "cpt##syntax"}{...}
{viewerjumpto "Description" "cpt##description"}{...}
{viewerjumpto "Author and support" "cpt##author"}{...}
{viewerjumpto "Examples" "cpt##examples"}{...}
{title:Title}
{phang}
{bf:cpt} {hline 2} Optimal cut-points for empirical ROC curves and other ROC/AUC calculations

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:cpt}
varlist(min=2)
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt f:ormat(string)}}  Stata format for the cut-point values in the returned 
ROC matrix

{synopt:{opt r:eplace}} Option for replacing generated variables with sensitivity
and specificity

{synopt:{opt ba:mber				}}  calculate standard errors by using the Hanley method. See {help roctab:roctab}

{synopt:{opt h:anley				}}  calculate standard errors by using the Bamber method. See {help roctab:roctab}

{synopt:{opt bi:nomial			}}  calculate exact binomial confidence intervals. See {help roctab:roctab}

{synopt:{opt gr:aph}} Generate a default graph.{p_end}

{synopt:{opt twoway options:}} Generate a default graph with the twoway options.
Option {opt gr:aph} is not necessary in this case.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}The command {cmdab:cpt} is a wrapper for {help roctab:roctab}.

{pstd}It generates three matrices: A AUC estimation report; 
The sensitivity, the specificity, the accuracy, the lr+,  and the lr- from 
{help roctab:roctab} at each cut-point value, as well as the PPV, the NPV, and 
the AUC in each cut-point value. 

{pstd}AUC is the average of sensitivity and specificity and is the AUC in the 
cut-point values.

{pstd}PPV is the prevalence weighted average of the sensitivity and the 1 - -specificity. 

{pstd}NPV is the prevalence weighted average of the 1 - sensitivity and the specificity. 

{pstd}The {cmdab:cpt} command marks the optimal cut-point values by Youden (J) and 
Liu(L) in the returned ROC matrix row names and the submatrix of the ROC matrix 
containing only the optimal cut-point values.

{pstd}Finally, variables (prefix tpr_) for sensitivity and false positive rates 
(prefix fpr_) are saved to make one or more curves.

{marker examples}{...}
{title:Examples}

{phang}Getting example data:{p_end}
{phang}{stata `"webuse hanley"'}{p_end}
{phang}Calling {cmdab:cpt}:{p_end}
{phang}{stata `"cpt disease rating"'}{p_end}
{phang}Calling {cmdab:cpt} with {help roctab:roctab} options:{p_end}
{phang}{stata `"cpt disease rating, binomial format(%2.0f) replace"'}{p_end}
{phang}The returned ROC matrix:{p_end}
{phang}{stata `"matlist r(roc)"'}{p_end}
{phang}The returned AUC matrix:{p_end}
{phang}{stata `"matlist r(auc)"'}{p_end}
{phang}The returned matrix with optimal cut-point values:{p_end}
{phang}{stata `"matlist r(cutpt)"'}{p_end}
{phang}A simple ROC curve:{p_end}
{phang}{stata `"line tpr_rating fpr_rating"'}{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(auctext)}} AUC report from {help roctab:roctab} {p_end}
{synopt:{cmd:r(graph_cmd)}}The {help twoway:twoway} graph command generating the graph.{p_end}

{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(auc)}} AUC report from {help roctab:roctab} {p_end}
{synopt:{cmd:r(roc)}} Sensitivity, specificity, PPV, NPV, accuracy, lr+,  and lr- from 
{help roctab:roctab} at each cut-point values. 
Also the AUCs in each cut-point value are reported. 
The optimal cut-point values by Youden (J) and Liu(L) are marked in the matrix row
names{p_end}
{synopt:{cmd:r(cutpt)}} A submatrix of the ROC matrix containing only the 
optimal cut-point values {p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
