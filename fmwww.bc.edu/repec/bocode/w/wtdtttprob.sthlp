{smcl}
{* *! version 1.0  May 17, 2017 @ 15:47:15}{...}
{vieweralsosee "wtdttt" "help wtdttt"}{...}
{viewerjumpto "Syntax" "wtdtttprob##syntax"}{...}
{viewerjumpto "Description" "wtdtttprob##description"}{...}
{viewerjumpto "Options" "wtdtttprob##options"}{...}
{viewerjumpto "Remarks - Methods and Formulas" "wtdtttprob##remarks"}{...}
{viewerjumpto "Examples" "wtdtttprob##examples"}{...}
{viewerjumpto "Results" "wtdtttprob##results"}{...}
{viewerjumpto "References" "wtdtttprob##references"}{...}
{title:Title}

{phang} {bf:wtdtttprob} {hline 2} Predict probability of a
patient still being in treatment after a prescription
redemption based on the estimated parametric Waiting Time 
Distribution (WTD).

{marker syntax}{...}
{title:Syntax}

{p 8 40 2}
{cmd:wtdtttprob}
{help newvar} [{it:if}] [{it:in}], {opt distrx}({help varname})

{marker description}{...}
{title:Description}

{pstd} {cmd:wtdtttprob} uses the last fitted reverse Waiting Time Distribution
to estimate the probability of a user still being treated at a time
{opt distrx} after a prescription redemption. Any covariates used in
the reverse WTD should also be present in the dataset, where the 
prediction is to be calculated. Estimation of the WTD will typically
take place in one dataset before another dataset is opened
in which the prediction is then carried out.

{marker options}{...}
{title:Options}

{phang} 
{opt distrx}({help varname}) The specified variable should contain
the time after a prescription redemption for which the prediction 
should be calculated. In some applications this will be the time 
from a prescription until a subsequent event.{p_end}

{marker examples}{...}
{title:Examples}

{pstd} In the following example we first fit a Log-Normal WTD model
before predicting the probability of being treated based on observed
prescription redemptions found in a new dataset and the estimated
parameters:

{phang}

{phang2}{cmd: . wtdttt last_rxtime, disttype(lnorm) reverse mucovar(i.packsize) logitpcovar(i.packsize)}

{phang2}{cmd: . drop _all}

{phang2}{cmd: . use rxdat}

{phang2}{cmd: . wtdtttprob probttt, distrx(distlast))}{p_end}

{pstd}
Further examples are provided in the example do-file
{it:wtdttt_ex.do}, which contains analyses based on the datafile
{it:wtddat.dta} - a simulated dataset, which is also enclosed.

{title:Author}

{pstd}
Henrik Støvring, Aarhus University, stovring@ph.au.dk.

