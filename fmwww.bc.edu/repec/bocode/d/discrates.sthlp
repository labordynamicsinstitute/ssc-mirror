{smcl}
{* *! * *! version 1.0 30 Nov 2022}{...}
{cmd:help discrates}

{viewerdialog discrates "dialog disrates"}{...}
{viewerjumpto "Syntax" "discrates##syntax"}{...}
{viewerjumpto "Menu" "discrates##menu"}{...}
{viewerjumpto "Description" "discrimrates##description"}{...}
{viewerjumpto "Saved results" "discrimrates##saved_results"}{...}
{viewerjumpto "Author" "discrimrates##author"}{...}

{p2col:{bf:discrates}}Estimation and statistical test for gross and net discrimination rates


{marker syntax}{...}
{title:Syntax}
{pstd}
{cmd:discrates} {minority_response majority_response} {if}


{marker menu}{...}
{title:Menu}
{phang}{bf:User > Statistics > Estimate and statistical test for gross and net discrimination rates}

 
{marker description}{...}
{title:Description}
{pstd}
{cmd:discrates} calculates the gross and net discrimination rate for a paired-test correspondence or audit design (application of minority and majority applicant for one offer). 
Therefore the input data has to be in a binary form indicating a response (n/y) to the minority (minority_response) or majority applicant (majority_response) for one offer.
Gross discrimination of the minority applicant is the situation, where the majority applicant gets a response whereas the minority applicant did not. Net discrimination is just the difference between the gross discrimination estimates of the minority and majority applicant. 
To test for gross discrimination of the minority applicant a one-sided one-proportion z-test testing the H0 of no gross discrimination (= 0). A McNemar test is used to test for net discrimination.


{marker saved_results}{...}
{title:Saved results}
{pstd} Scalars

{p2colset 5 20 20 2}{...}
{p2col : {cmd:e(N)}}number of observations{p_end}
{p2col : {cmd:e(gd)}}gross discrimination rate{p_end}
{p2col : {cmd:e(nd)}}net discrimination rate}{p_end}


{marker author}{...}
{title:Author}
{pstd} Andreas Schneck, LMU Munich, andreas.schneck@lmu.de

{pstd}Thanks for citing this software as follows
Schneck, A. (2022). discrate: Stata module to estimate and statistically test for gross and net discrimination rates.

