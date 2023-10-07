{smcl}
{* *! version 3.0.1 05OCt2023}{...}
{* *! version 3.0.0 01Sep2022}{...}
{* *! version 2.0.1 12Jul2018}{...}
{* *! version 2.0.0 03Oct2017}{...}
{* *! version 1.0.1 29May2016}{...}
{* *! version 1.0.0 29Dec2015}{...}
{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:classtab} {hline 2}} Diagnostic accuracy statistics and classification table {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Using data stored in memory

{p 8 17 2}
{cmd:classtab} {it:refvar} {it:classvar} [{cmd:,} {opt l:evel(#)}] 


{pstd}
Immediate form of {cmd:classtab}

{p 8 17 2}
{cmd:classtabi} {it:#a #b #c #d} [{cmd:,} {opt l:evel(#)}] 


{pstd}
Immediate form of {cmd:classtab} referring to a saved 2 X 2 matrix

{p 8 17 2}
{cmd:classtabi} {it:matname}  [{cmd:,} {opt l:evel(#)}]


{phang}
{it:#a} is the true positive (disease=1 and test=1); {it:#b} is the false negative (disease=1 and test=0); 
{it:#c} is the false positive (disease=0 and test=1); {it:#d} is the true negative (disease=0 and test=0).
{it:#a}, {it:#b}, {it:#c}, and {it:#d} must be positive integers.    
 


{synoptset 19 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p 4 6 2}
{opt by} is allowed with {cmd:classtab}; see {manhelp by D}.{p_end}


 
{p 4 6 2}
{p2colreset}{...}				
	
{title:Description}

{pstd}
{cmd:classtab} reports various classification statistics and their exact confidence intervals
(also known in the literature as Clopper-Pearson [1934] binomial confidence intervals) and
provides a 2 x 2 classification table. 

{pstd}
{cmd:classtabi} is the immediate form of {cmd:classtab}; see {help immed}.


{title:Remarks}

{pstd}
For {cmd:classtabi}, row values indicate the true (binary) state of the observation ({it: refvar}), such as diseased and nondiseased, or normal and abnormal. Column values represent
the binary rating or outcome of the diagnostic test ({it:classvar}), or predicted class from a classification algorithm. As such, when manually entering the four values (syntax 1), 
the data should be entered as follows (for example, we use disease as the reference [row] variable, and diagnostic test outcome as the classifier [column] variable):{p_end} 

{pstd}
-------------------------------------------------------------------------------------- {p_end}
{pstd}
{it:#a} -- disease=1, test=1 (true positive) | {it:#b} -- disease=1, test=0 (false negative) {p_end}
{pstd}
-------------------------------------------------------------------------------------- {p_end}
{pstd}
{it:#c} -- disease=0, test=1 (false positive)| {it:#d} -- disease=0, test=0 (true negative){p_end}
{pstd} 
-------------------------------------------------------------------------------------- {p_end}

{pstd}
To use the second {cmd:classtabi} syntax (syntax 2), the four values must be saved in a 2 X 2 matrix (see example below).



{title:Options}

{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for confidence intervals; default level is {cmd:level(95)}.


		
{title:Examples}

{pstd}Using data stored in memory{p_end}

{phang2}{cmd:. use example.dta}{p_end}

{phang2}{cmd:. classtab disease test}{p_end}

{pstd}Entering values manually using {cmd:classtabi}{p_end}

{phang2}{cmd:. classtabi 324 50 397 1231}{p_end}

{phang2}{cmd:. classtabi 324 50 397 1231, level(99)}{p_end}

{pstd}Referring to a matrix using {cmd:classtabi}{p_end}

{phang2}{cmd:. matrix input B = (324 50\397 1231)}{p_end}

{phang2}{cmd:. classtabi B, level(99)}{p_end}


{title:Stored results}

{pstd}
{cmd:classtab} and {cmd:classtabi} store the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(sens)}}sensitivity{p_end}
{synopt:{cmd:r(senslb)}}sensitivity - lower bound of confidence interval{p_end}
{synopt:{cmd:r(sensub)}}sensitivity - upper bound of confidence interval{p_end}
{synopt:{cmd:r(spec)}}specificity{p_end}
{synopt:{cmd:r(speclb)}}specificity - lower bound of confidence interval{p_end}
{synopt:{cmd:r(specub)}}specificity - upper bound of confidence interval{p_end}
{synopt:{cmd:r(fpr)}}false-positive rate{p_end}
{synopt:{cmd:r(fprlb)}}false-positive rate - lower bound of confidence interval{p_end}
{synopt:{cmd:r(fprub)}}false-positive rate - upper bound of confidence interval{p_end}
{synopt:{cmd:r(fnr)}}false-negative rate{p_end}
{synopt:{cmd:r(fnrlb)}}false-negative rate - lower bound of confidence interval{p_end}
{synopt:{cmd:r(fnrub)}}false-negative rate - upper bound of confidence interval{p_end}
{synopt:{cmd:r(ppv)}}positive predictive value{p_end}
{synopt:{cmd:r(ppvlb)}}positive predictive value - lower bound of confidence interval{p_end}
{synopt:{cmd:r(ppvub)}}positive predictive value - upper bound of confidence interval{p_end}
{synopt:{cmd:r(npv)}}negative predictive value{p_end}
{synopt:{cmd:r(npvlb)}}negative predictive value - lower bound of confidence interval{p_end}
{synopt:{cmd:r(npvub)}}negative predictive value - upper bound of confidence interval{p_end}
{synopt:{cmd:r(all)}}overall correctly classified{p_end}
{synopt:{cmd:r(alllb)}}overall correctly classified - lower bound of confidence interval{p_end}
{synopt:{cmd:r(allub)}}overall correctly classified - upper bound of confidence interval{p_end}
{synopt:{cmd:r(roc)}}ROC curve{p_end}
{synopt:{cmd:r(roclb)}}ROC curve - lower bound of confidence interval{p_end}
{synopt:{cmd:r(rocub)}}ROC curve - upper bound of confidence interval{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Clopper, C. J., and E. S. Pearson. 1934.  The use of confidence or fiducial limits illustrated in the case of the binomial.  Biometrika 26: 404-413.

{p 4 8 2}
Linden A. 2006. Measuring diagnostic and predictive accuracy in disease management: an introduction to receiver operating characteristic (ROC) analysis. 
{it:Journal of Evaluation in Clinical Practice} 12: 132-139.{p_end}


{marker citation}{title:Citation of {cmd:classtab}}

{p 4 8 2}{cmd:classtab} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2022). classtab: Stata module for computing diagnostic accuracy statistics and classification table {p_end}


{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{p_end}


         
{title:Also see}

{p 4 8 2} Online: {helpb estat classification}, {helpb roccomp}, {helpb roctabi} (if installed), {helpb rmclass} (if installed), 
{helpb looclass} (if installed), {helpb kfoldclass} (if installed){p_end}

