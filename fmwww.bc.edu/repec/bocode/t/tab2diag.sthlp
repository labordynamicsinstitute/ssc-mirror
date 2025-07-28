{smcl}
{* *! version 1.3.1  03jun2025}{...}
{cmd:help tab2diag}
{hline}

{title:Title}

{p2colset 5 41 41 2}{...}
{p2col :{bf:[COMMUNITY-CONTRIBUTED] tab2diag} {hline 2}}Compute diagnostic metrics and predictive values from {bind:2-by-2} tables
{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 18 2}
{cmd:tab2diag} 
{it:{help varname:refvar}} {it:{help varname:classvar}} 
{ifin} 
{weight}
[ {cmd:,} {it:{help tab2diag##options:options}} ]

{p 8 18 2}
{cmd:tab2diagi} 
{it:#TP} 
{it:#FP}
[ {cmd:\} ]
{it:#FN} 
{it:#TN}
[ 
{cmd:,}
{it:{help tab2diag##options:options}}
]

{p 8 18 2}
{cmd:tab2diagmat}
{c -(}
{it:{help matrix:A}}
{c |}
{it:{help matrix define:matrix_expression}}
{c |}
{cmd:(}{it:#}{cmd:,}{it:#} {cmd:\} {it:#}{cmd:,}{it:#}{cmd:)}
{c )-}
[ {cmd:,} {it:{help tab2diag##options:options}} ]

{col 5}with 

{col 8}{it:#TP}{col 14}true positive
{col 8}{it:#FP}{col 14}false positive
{col 8}{it:#FN}{col 14}false negative
{col 8}{it:#TN}{col 14}true negative

{col 8}{it:A}{col 14}matrix name


{synoptset 24 tabbed}{...}
{marker options}{...}
{synopthdr :options}
{synoptline}
{syntab:Statistics}
{synopt :{opt comp:lement}}calculate 
complements of proportions
{p_end}

{syntab:CI/SE}
{synopt :{cmd:cii(}{it:{help tab2diag##cii_method:cii_method}}{cmd:)}}method 
for calculating confidence intervals for proportions
{p_end}
{synopt :{cmd:csi(}{it:{help tab2diag##csi_method:csi_method}}{cmd:)}}method 
for calculating confidence intervals for risk-ratios
{p_end}
{synopt :{cmd:cci(}{it:{help tab2diag##cci_method:cci_method}}{cmd:)}}method 
for calculating confidence intervals for odds ratio
{p_end}
{synopt :{cmdab:roc:tab(}{it:{help tab2diag##roc_method:roc_method}}{cmd:)}}method 
for calculating standard errors and confidence intervals for ROC area
{p_end}

{syntab:Reporting}
{synopt :{cmd:format(}{it:{help format:%fmt}}{cmd:)}}display format 
for diagnostic metrics and predictive values
{p_end}
{synopt :{opt percent}}report percentages
{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level({ccl level})}
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{opt fweight}s are allowed; see {help weight}.


{synoptset 24 tabbed}{...}
{marker cii_method}{...}
{synopthdr :cii_methods}
{synoptline}
{synopt :{opt wa:ld}}calculate Wald confidence intervals{p_end}
{synopt :{opt w:ilson}}calculate Wilson confidence intervals{p_end}
{synopt :{opt a:gresti}}calculate Agresti-Coull confidence intervals{p_end}
{synopt :{opt j:effreys}}calculate Jeffreys confidence intervals{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{marker csi_method}{...}
{synopthdr :csi_methods}
{synoptline}
{synopt :{opt tb}}calculate test-based confidence intervals{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{marker cci_method}{...}
{synopthdr :cci_methods}
{synoptline}
{synopt :{opt co:rnfield}}use Cornfield approximation to calculate CI{p_end}
{synopt :{opt w:oolf}}use Woolf approximation to calculate CI{p_end}
{synopt :{opt tb}}calculate test-based confidence intervals{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{marker roc_method}{...}
{synopthdr :roc_methods}
{synoptline}
{synopt:{opt bino:mial}}calculate exact binomial confidence intervals{p_end}
{synopt:{opt bam:ber}}calculate standard errors by using the Bamber method{p_end}
{synopt:{opt han:ley}}calculate standard errors by using the Hanley method{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:tab2diag}
computes diagnostic test statistics from a 2-by-2 contingency table, 
including sensitivity, specificity, predictive values, accuracy, 
likelihood ratios, odds ratio, and the area under the ROC curve.
Optionally, complementary error metrics, 
such as the false negative rate and false discovery rate, 
are also computed.

{pstd}
Confidence intervals are computed using {helpb cii} 
(for sensitivity, specificity, positive predictive value, negative predictive value, accuracy, and prevalence), 
{helpb csi} 
(for likelihood ratios), 
{helpb cci} 
(for the odds ratio), 
and {helpb roctab} 
(for the ROC area).

{pstd}
The two variables {it:refvar} and {it:classvar} must be numeric. 
The reference variable ({it:refvar}) indicates each observation's true state,
such as diseased versus nondiseased or normal versus abnormal. 
The classification variable ({it:classvar}) records 
the rating, prediction, or outcome 
produced by the diagnostic test or test modality. 

{pstd}
In both {it:refvar} and {it:classvar}, 
nonzero and nonmissing values (typically equal to 1) 
indicate a positive status or outcome (such as diseased or abnormal), 
whereas values equal to 0 
indicate a negative status or outcome (such as nondiseased or normal).

{pstd}
{cmd:tab2diagi} 
is the immediate form of {cmd:tab2diag}; see {help immed}.

{pstd}
{cmd:tab2diagmat}
is similar to the immediate form, {cmd:tab2diagi}, 
but takes a matrix name, a matrix expression, or matrix elements as input. 
In all cases, the input matrix must be 2 {it:x} 2.


{title:Options}

{phang}
{opt complement}
specifies that complements of 
sensitivity, specificity, positive predictive value, and negative predictive value
are calculated. 
Point estimates and confidence intervals for the complements 
are obtained by subtracting each original result from 1.

{phang}
{opt cii(cii_method)}
specifies the method for calculating confidence intervals 
for proportions (sensitivity, specificity, etc.);
see {helpb cii}.

{phang}
{opt csi(csi_method)}
specifies the method for calculating confidence intervals 
for the likelihood ratios;
see {helpb csi}. 

{phang}
{opt cci(cci_method)}
specifies the method for calculating confidence intervals 
for the odds ratio;
see {helpb cci}. 

{phang}
{opt roctab(roc_method)}
specifies the method for calculating standard errors and confidence intervals 
for the area under the ROC;
see {helpb roctab}. 

{phang}
{opt format(%fmt)}
specifies how to format diagnostic metrics and predictive values. 
The maximum format width is 9. See {manhelp set_cformat R:set cformat}.

{phang}
{opt percent}
specifies that proportions (such as sensitivity, specificity, etc.) 
are shown as percentages. 

{phang}
{opt level(#)} 
specifies the confidence level, as a
percentage, for confidence intervals.  The default is {cmd:level(95)} 
or as set by {helpb set level}.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse hanley}

{pstd}Create a binary rating{p_end}
{phang2}{cmd:. generate byte high_rating = (rating==5) if !missing(rating)}

{pstd}Compute diagnostic metrics and predictive values{p_end}
{phang2}{cmd:. tab2diag disease high_rating}

{pstd}Immediate form of the above command; compute complements{p_end}
{phang2}{cmd:. tab2diagi 33 2 18 56 , complement}

{pstd}Same as above, format as percentages{p_end}
{phang2}{cmd:. tab2diagi 33 2 18 56 , complement percent}


{title:Saved results}

{pstd}
{cmd:tab2diag}, {cmd:tab2diagi}, and {cmd:tab2diagmat} save the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(level)}}confidence level of confidence interval
{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:tab2diag}
{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(sens)}}sensitivity 
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(spec)}}specificity 
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(ppv)}}positive predictive value
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(npv)}}negative predictive value
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(acc)}}accuracy 
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(prev)}}prevalence 
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(lrp)}}positive likelihood ratio 
(point estimate, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(lrn)}}negative likelihood ratio 
(point estimate, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(or)}}odds ratio
(point estimate, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(roc)}}area under ROC 
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(ctable)}}2 by 2 contingency table
{p_end}

{pstd}
{cmd:tab2diag}, {cmd:tab2diagi}, and {cmd:tab2diagmat} 
with option {opt complement} additionally save the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(fnr)}}false negative rate 
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(fpr)}}false prediction rate 
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(fdr)}}false discovery rate
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}
{synopt:{cmd:r(for)}}false omission rate
(point estimate, standard error, lower CI bound, upper CI bound)
{p_end}


{title:Support}

{pstd}
Daniel Klein{break}
klein.daniel.81@gmail.com


{title:Also see}

{psee}
{space 2}Help:  
{manhelp tabulate_twoway R:tabulate twoway},
{manhelp ci R},
{manhelp cs R},
{manhelp cc R},
{manhelp roctab R},
{manhelp immed U:19 Immediate commands}
{p_end}

{psee}
{space 2}Community-contributed:
{helpb classtab},
{helpb diagt}, 
{helpb diagtest}
{p_end}
