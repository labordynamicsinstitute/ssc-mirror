{smcl}
{* *! version 1.0.0 16dec2022}{...}
{title:Title}

{p2colset 5 15 16 2}{...}
{p2col:{hi:elix22} {hline 2}} Calculate Elixhauser comorbidity measures (version 2022.1) {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 43 2}
{opt elix22} {help varlist} {ifin}
[{cmd:,} {opth i:d(varname)}]

{phang}
where {it:varlist} includes one or more diagnosis fields containing ICD-10-CM codes valid from October 2015 through September 2022{p_end}


{title:Options}

{p 4 8 2} 
{cmd:id(}{it:varname}{cmd:)} specifies the patients' identifier. {cmd:id()} should be specified when the data contain multiple observations 
per patient and it is desired to compute comorbidities across all observations within patients. When {cmd:id()} is not specified (the default),
Elixhauser comorbidities are computed separately for each observation in the data.



{marker description}{...}
{title:Description}

{pstd}
{opt elix22} computes Elixhauser comorbidities based on ICD-10-CM codes valid from October 2015 through September 2022. 
This updated Elixhauser version (2022.1) was developed as part of the Healthcare Cost and Utilization Project (HCUP), 
a Federal-State-Industry partnership sponsored by the Agency for Healthcare Research and Quality. The number of comorbidity 
measures increases from 29, in the original Elixhauser specifications (Elixhauser et al. 1998), to 38 starting in v2021.1, 
with three measures added, five measures modified to create 12 more specific measures, and one measure discontinued. 
Detailed information about Elixhauser version 2022.1 can be found at: 
{browse "https://www.hcup-us.ahrq.gov/toolssoftware/comorbidityicd10/comorbidity_icd10.jsp"}. 



{title:Remarks}

{pstd}
The Elixhauser comorbidities version (2022.1) specifications rely on {it:present on admission} (POA) indicators to compute a subset
of the comorbidity measures where the place of service is the hospital. {cmd:elix22} computes those comorbidity measures 
using all of the ICD-10-CM codes (i.e. ignoring POA). The reason for this is because the plurality of health care is provided in the 
outpatient setting where POA is irrelevant. {cmd:elix22} therefore captures all the possible ICD-10-CM to identify comorbidities 
regardless of setting in which healthcare was administered.

{pstd} 
Elixhauser comorbidities are intended to identify pre-existing conditions based on secondary diagnoses listed on hospital administrative data.
However, researchers may want to apply {cmd:elix22} across all available diagnosis fields in order to identify categories of disease conditions
(whether or not they represent "comorbitities" per se). In the former case, the user can limit the diagnoses fields to the secondary diagnosis 
onward. In the latter case, the user can include all diagnosis fields available in the data. See the examples below for a demonstration of these applications.  
  


{title:Examples}

{pstd}
    Use {cmd:elix22} across all available diagnosis fields in order to identify 
	categories of disease conditions (whether or not they represent "comorbitities" per se).{p_end}
{phang2}{cmd:. use example_data.dta, clear}{p_end}
{phang2}{cmd:. elix22 dx1-dx10, i(id)}

{pstd}
    Use {cmd:elix22} to compute commorbidities using diagnosis fields 2 through 10.{p_end}
{phang2}{cmd:. use example_data.dta, clear}{p_end}
{phang2}{cmd:. elix22 dx2-dx10, i(id)}

{pstd}
    Use {cmd:elix22} to compute commorbidities using only primary diagnosis (dx 1).{p_end}
{phang2}{cmd:. use example_data.dta, clear}{p_end}
{phang2}{cmd:. elix22 dx1, i(id)}

{pstd}
    Use {cmd:elix22} to compute commorbidities at the observation level (rather than at the aggregated patient level){p_end}
{phang2}{cmd:. use example_data.dta, clear}{p_end}
{phang2}{cmd:. elix22 dx2-dx10}



{title:References}

{p 4 8 2} Elixhauser, A., Steiner, C., Harris, D. R. and R. M. Coffey 1998. Comorbidity measures for use with administrative data. {it:Medical Care} 36:8-27. {p_end}



{marker citation}{title:Citation of {cmd:elix22}}

{p 4 8 2}{cmd:elix22} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2022). ELIX22: Stata module to compute Elixhauser commorbidity measures (version 2022.1) 



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb elixhauser} (if installed){p_end}

