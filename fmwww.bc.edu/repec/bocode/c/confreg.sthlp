{smcl}
{* *! version 1.2 2026-03-01}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "confreg##syntax"}{...}
{viewerjumpto "Description" "confreg##description"}{...}
{viewerjumpto "Examples" "confreg##examples"}{...}
{viewerjumpto "References" "confreg##references"}{...}
{viewerjumpto "Author and support" "confreg##author"}{...}
{title:Title}
{phang}
{bf:confreg} {hline 2} Confusion matrix (Accuracy measures) estimated by 
mixed regression and {help nlcom:nlcom}

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:confreg}
varlist(min=2
max=3)
[{help if}]
[{cmd:,}
{it:options}]

{synoptset 40 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt id(passthru)}} If modalities are measured on the same id, 
specify the id variable. The used model becomes a mixed random intercepts by id.

{synopt:{opt r:andomeffect(string)}} String for adding random effects to the model.
Possibly succeeded by the random effect of the ids (||id:).

{synopt:{opt adj:ustment(varlist fv)}} Add adjustment variables to the model.

{synopt:{opt c:oleq(string)}} Add coleq text to the stored matrices.

{synopt:{opt p:revalence(numlist max=1  >0  <1)}} Specify prevalence to use. 
Default is the sample prevalence.

{synopt:{opt vce(passthru)}} Set {help vce_option:vce options}.

{synopt:{opt st:ub(string)}} Stub to add the names of the returned {help estimates:estimates}.

{synopt:{opt sc:ale(#)}}  Default value is 100.

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}{cmd:confreg} estimates sensitivity and specificity for a single modality 
by OLS regressing the binary values from the modality on the pathology using 
robust variance estimation.
{break}The area under the ROC curve (AUC) is estimated here as the mean of 
sensitivity and specificity for the modality.
{break}There are non-linear formulas for estimating the PPV, NPV, and accuracy 
using prevalence, sensitivity, and specificity (Bland, 2015, subsection 20.6).
{break}To model more modalities, confreg stacks the values of each modality and 
the pathology and adds a categorical modality variable.
{break}Using the stacked dataset, sensitivity and specificity are estimated by 
regressing the modality values on the pathology values and the categorical 
modality variable, with robust variance estimation.
{break}If modalities are measured on the same patients, estimation uses random 
intercepts by ID.
{break}The AUC, PPV, NPV, and accuracy are estimated from the prevalence, 
sensitivity, and specificity as described.




{marker examples}{...}
{title:Examples}

{phang}Getting example data:{p_end}
{phang}{stata `"webuse hanley, clear"'}{p_end}
{phang}Reviewer classified 109 tomographic images using a 5-point scale, 
from 1 = definitely normal to 5 = definitely abnormal.{p_end}
{phang}Patients: 58 normal, 51 abnormal.{p_end}

{phang}Making data long:{p_end}
{phang}{stata `"generate id = _n"'}{p_end}
{phang}{stata `"generate rating2 = rating >= 2"'}{p_end}
{phang}{stata `"generate rating3 = rating >= 3"'}{p_end}
{phang}{stata `"drop rating"'}{p_end}
{phang}{stata `"reshape long rating, i(id) j(point)"'}{p_end}
{phang}{stata `"label define point 2 "rating 2" 3 "rating 3" "'}{p_end}
{phang}{stata `"label values point point"'}{p_end}

{phang}Using {cmdab:confreg} to report sensitivities, specificities, and AUCs
at values 2 and 3:{p_end}
{phang}{stata `"confreg disease rating point, id(id) vce(robust)"'}{p_end}

{phang}The sensitivities are highly correlated, likewise for the specificities:{p_end}
{phang}{stata `"matlist r(se_sp_auc_corr), tw(32)"'}{p_end}
{phang}Note that sensitivities and specificities are uncorrelated:{p_end}

{phang}Report all the accuracy measures:{p_end}
{phang}{stata `"matlist r(confreg), tw(32)"'}{p_end}

{phang}Retrieve sensitivities, specificities, and AUCs for estimation:{p_end}
{phang}{stata `"estimates restore _se_sp_auc"'}{p_end}
{phang}See the estimation table from nlcom:{p_end}
{phang}{stata `"nlcom"'}{p_end}
{phang}Test if the sensitivities are the same:{p_end}
{phang}{stata `"test se2 = se3"'}{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(se_sp_auc)}}  {p_end}
{synopt:{cmd:r(se_sp_auc_corr)}}  {p_end}
{synopt:{cmd:r(acc_ppv_npv)}}  {p_end}
{synopt:{cmd:r(confreg)}}  {p_end}

{p2col 5 15 19 2: {help estimates:Estimates} based on {help nlcom:nlcom}}{p_end}
{synopt:{cmd:_se_sp_auc}} For testing sensitivities, specificities, and AUCs.{p_end}
{synopt:{cmd:_acc_ppv_npv}} For testing accuracies, PPVs, and NPVs.{p_end}


{marker references}{...}
{title:References}
{pstd}Bland, Martin. 2015. An Introduction to Medical Statistics. Fourth edition. 
Oxford University Press.{p_end}
{pstd}Cohen, Jérémie F, Daniël A Korevaar, Douglas G Altman, et al. 2016. 
"STARD 2015 Guidelines for Reporting Diagnostic Accuracy Studies: 
Explanation and Elaboration." BMJ Open (LONDON) 6 (11): e012799–.{p_end}


{marker author}{...}
{title:Authors and support}


{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
