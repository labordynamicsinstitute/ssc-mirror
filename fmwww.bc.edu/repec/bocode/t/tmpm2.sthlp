{smcl}
{* *! version 2.0 January 1, 2021}{...}
{viewerjumpto "Syntax" "tmpm2##syntax"}{...}
{viewerjumpto "Description" "tmpm2##description"}{...}
{viewerjumpto "Requirements" "tmpm2##requirements"}{...}
{viewerjumpto "Options" "tmpm2##options"}{...}
{viewerjumpto "Remarks" "tmpm2##remarks"}{...}
{viewerjumpto "Examples" "tmpm2##examples"}{...}
{viewerjumpto "Authors" "tmpm2##authors"}{...}
{viewerjumpto "References" "tmpm2##references"}{...}
{title:Title}

{phang}
{bf:tmpm2} {hline 2} Trauma Mortality Prediction Model using AIS, ICD-9-CM or ICD-10-CM codes
{p2colreset}{...} 


{marker syntax}{...}
{title:Syntax}

{phang}
{cmdab:tmpm2,} 
[i(varname) inj({it:stub}) {it:ais} {it:icd9} {it:icd10}]

{marker description}{...}
{title:Description}

{pstd}
{cmd:tmpm2} calculates probability of death (p(death)) based on the Trauma 
Mortality Prediction Model created by Turner Osler, MD, MSc, and Laurent Glance, MD. 
The {cmd:tmpm2} uses injuries recorded in either AIS, ICD-9-CM or ICD-10-CM 
and computes the probability of death (p(Death)) for each patient in the 
dataset. {cmd:tmpm2} will accommodate datasets arranged in wide format (one record 
per patient with one or more injuries per record), or the long format (one or more records per 
patient, with one injury/record). {cmd:tmpm2} will calculate a probability of death 
(p(Death)) value for each observation expressed as a vartype float and add this new 
variable, -pDeath-, to the user's otherwise unchanged dataset.


{marker requirements}{...}
{title:Requirements}

{phang}
1.) A unique identifier is required for each patient and must be of vartype 
string. 

{phang}
2.) The variable name used to identify each patient -i()- and the injury variable(s)
-inj()- must not have the same {it:stubname}. 

{phang}
3.) The  -inj()- is the {it:stubname} for variable containing the injury codes. 

{phang}
4.) The coding lexicon must be specifiec as -{it:ais,} {it:icd9,} or {it:icd10}- for the 
Abbreviated Injury Scale (ais), ICD-9-CM (icd9) or ICD-10-CM (icd10) codes, respectively.

{phang}
5.) The names of the variables containing the injury codes must begin with a common 
{it:stubname} (e.g., inj1, inj2, ... inj{it:n}). 

{phang}
6.) {cmd:tmpm2} and the accompanying {it:marc2} table ("marc2_table.dta") must be 
installed to the same directory.

{phang}
7.) The AIS codes must be the 6 digit "predot" codes only, e.g. do not include 
the decimal or severity value.


{marker remarks}{...}
{title:Remarks}

{phang}
1.) {cmd:tmpm2} requires STATA 11.0 or higher. This command will not operate on any 
previous version of STATA.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}

{phang}{cmd:. sysuse tmpm2_ex.dta}

{phang}
Calculate the p(Death) using AIS predot codes. {p_end}

{phang}
{cmd:. tmpm2, i(id) inj(injais) ais}{p_end}
{phang}

{phang}
Calculate the p(Death) using ICD-9-CM codes. {p_end}

{phang}
{cmd:. tmpm2, i(id) inj(icd9inj) icd9}{p_end}
{phang}

{phang}
Calculate the p(Death) using ICD-10-CM codes. {p_end}

{phang}
{cmd:. tmpm2, i(id) inj(icd10inj) icd10}{p_end}
{phang}

{marker authors}{...} 
{title:Authors}
{pstd}
Alan Cook, M.D., MS, FACS <adcookmd@gmail.com> {p_end}

{pstd}
Turner Osler, M.D., MSc(Biostatistics) <tosler@uvm.edu> {p_end}


{marker authors}{...}
{title:References:}

{pstd}
1.) Osler TM, Glance LG, Buzas JS, Mukamel DB, Wagner J, Dick AW. A trauma mortality 
prediction model based on the anatomic injury scale. Ann Surg 2008;247:1041-8. 
{browse "https://pubmed.ncbi.nlm.nih.gov/18520233/"} {p_end}

{pstd}
2.) Glance LG, Osler TM, Mukamel DB, Meredith W, Wagner J, Dick AW. TMPM-ICD9: 
a trauma mortality prediction model based on ICD-9-CM codes. Ann Surg 2009;249:1032-9.
{browse "https://pubmed.ncbi.nlm.nih.gov/19474696/"} {p_end}

{pstd}
3.) Osler TM, Glance LG, Cook A, Buzas JS, Hosmer DW. A trauma mortality prediction 
model based on the ICD-10-CM lexicon: TMPM-ICD10. J Trauma Acute Care Surg. 
2019 May;86(5):891-895. {browse "https://pubmed.ncbi.nlm.nih.gov/30633101/"} {p_end}





