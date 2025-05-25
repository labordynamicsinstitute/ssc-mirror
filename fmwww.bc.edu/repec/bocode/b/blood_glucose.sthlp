{smcl}
{* *! version 1.0.0 22May2025}{...}

{title:Title}

{p2colset 5 22 23 2}{...}
{p2col:{hi:blood glucose} {hline 2}} conversions between HbA1c and blood glucose values {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Compute HbA1c from blood glucose:

{p 8 14 2}
{cmd:bg2hba1c}
{it:varname}
[{cmd:,}
{opt mmol}
{opt re:place}
]


{pstd}
Immediate form for computing HbA1c from blood glucose:

{p 8 14 2}
{cmd:bg2hba1ci}
{it:#}
[{cmd:,}
{opt mmol}
]


{pstd}
Compute blood glucose from HbA1c:

{p 8 14 2}
{cmd:hba1c2bg}
{it:varname}
[{cmd:,}
{opt mmol}
{opt re:place}
]


{pstd}
Immediate form for computing blood glucose from HbA1c:

{p 8 14 2}
{cmd:hba1c2bgi}
{it:#}
[{cmd:,}
{opt mmol}
]


{synoptset 22 tabbed}{...}
{marker Option}{...}
{synopthdr:Option}
{synoptline}
{synopt:{opt mmol}}indicates that the {it:varname} or {it:#} is measured as a mmol (millimole); default is as a percent for Hba1c or as mg/dL for blood glucose {p_end}
{synopt:{opt re:place}}replace variables created by the respective command if they already exist {p_end}
{synoptline}



{marker description}{...}
{title:Description}

{pstd}
The {opt blood glucose} package converts glycated hemoglobin (HbA1c) values to blood glucose values and vice versa. HbA1c is a measure of the average blood glucose
levels over the past three months. 


{pstd}
{opt bg2hba1ci} and {opt hba1c2bgi} are immediate forms of {opt bg2hba1c} and {opt hba1c2bg}, respectively; see {help immed}.



{title:Examples}

{pmore} load data {p_end}
{pmore2}{cmd:. use "hba1c.dta", clear}

{pstd}
{opt 1a) Compute HbA1c from blood glucose using variables:}{p_end}

{pmore} here blood glucose is measured as ml/dL {p_end}
{pmore2}{cmd:. bg2hba1c bgml}

{pmore} here blood glucose is measured as mmol/L. We use {opt replace} to replace the variables generated {p_end}
{pmore2}{cmd:. bg2hba1c bgmmol, mmol replace}

{pstd}
{opt 1b) Compute HbA1c from blood glucose using immediate form:}{p_end}

{pmore} here blood glucose is measured as ml/dL {p_end}
{pmore2}{cmd:. bg2hba1ci 120}

{pmore} here blood glucose is measured as mmol/L  {p_end}
{pmore2}{cmd:. bg2hba1ci 5.5, mmol}

{pstd}
{opt 2a) Compute blood glucose from HbA1c using variables:}{p_end}

{pmore} here HbA1c is measured as a percent {p_end}
{pmore2}{cmd:. hba1c2bg a1cpct, replace}

{pmore} here HbA1c is measured as on a mmol/mol scale{p_end}
{pmore2}{cmd:. hba1c2bg a1cmmol, mmol replace}

{pstd}
{opt 2b) Compute blood glucose from HbA1c using immmediate form:}{p_end}

{pmore} here HbA1c is measured as a percent {p_end}
{pmore2}{cmd:. hba1c2bgi 9.1}

{pmore} here HbA1c is measured as on a mmol/mol scale{p_end}
{pmore2}{cmd:. hba1c2bgi 32.1, mmol}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:hba1c2bgi} and {cmd:bg2hba1ci} store the following in {cmd:r()}, respectively:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(bg_mg)}}computed blood glucose value in mg/dL{p_end}
{synopt:{cmd:r(bg_mmol)}}computed blood glucose value in mmol/L{p_end}

{synopt:{cmd:r(hba1c_pct)}}computed HbA1c value as a percent{p_end}
{synopt:{cmd:r(hba1c_mmol)}}computed HbA1c value in mmol/mol{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2} Nathan DM, Kuenen J, Borg R, et al., A1c-Derived Average Glucose Study Group. Translating the A1C assay into estimated average glucose values. A1c-Derived Average Glucose Study Group. Diabetes Care. 2008 Aug;31(8):1473-8. Epub 2008 Jun 7. Erratum in: Diabetes Care. 2009 Jan;32(1):207. PubMed ID: 18540046
{p_end}

{p 4 8 2} Trevino G. Consensus statement on the Worldwide Standardization of the Hemoglobin A1C Measurement: the American Diabetes Association, European Association for the Study of Diabetes, International Federation of Clinical Chemistry and Laboratory Medicine, and the International Diabetes Federation: response to the Consensus Committee. Diabetes Care. 2007 Dec;30(12):e141. PubMed ID: 18042750
{p_end}

{p 4 8 2} Hoelzel W, Weykamp C, Jeppsson JO, et al., IFCC Working Group on HbA1c Standardization. IFCC reference system for measurement of hemoglobin A1c in human blood and the national standardization schemes in the United States, Japan, and Sweden: a method-comparison study. Clin Chem. 2004 Jan;50(1):166-74. PubMed ID: 14709644
{p_end}

{p 4 8 2} Little RR, Sacks DB. HbA1c: how do we measure it and what does it mean? Curr Opin Endocrinol Diabetes Obes. 2009 Apr;16(2):113-8. Review. PubMed ID: 19300091 
{p_end}
 


{marker citation}{title:Citation of {cmd:blood glucose}}

{p 4 8 2}{cmd:blood glucose} is not an official Stata suite of commands. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2019). BLOOD GLUCOSE: Stata package for converting between HbA1c and blood glucose values.



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



