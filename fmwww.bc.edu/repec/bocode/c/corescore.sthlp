{smcl}
{hline}
help for {hi:corescore} {right:(Adapted for Stata by Dr. Nikhil Chervu and Jeffrey Balian,}
{right:under the direction of Dr. Peyman Benharash)}
{hline}

{title:Comorbid Operative Risk Evaluation (CORE) Score macro}

{p 8 16 2}
{cmd:corescore} {it:varlist} 
[{cmd:if} {it:exp}] [{cmd:in} {it:range}]
{cmd:, index(}{it:string}{cmd:)}
[{cmd:idvar(}{it:varname}{cmd:)}
{cmd:diagprfx(}{it:string}{cmd:)}
{cmd:noshow}]

{title:Description}

{p 4 4 2}
{cmd:corescore} takes a set of diagnoses from an input database containing ICD-10 diagnostic codes and calculates the CORE score ({cmd:COREscore}), a comorbidity score initially designed for use in surgical database research by Dr. Nikhil Chervu under the guidance of Dr. Peyman Benharash. ICD-10 codes can either be formatted with or without a decimal point. The diagnosis codes must be stored as string, with numbers 1 to the maximum number of comorbidities recorded, forming the suffix. These comorbidity variables must all begin with the same root(the prefix) and either form the {it:varlist} or be defined by the root string given
in the {cmd:diagprfx(}{it:string}{cmd:)} option. The user has the choice of units: hospital visits or patients. The former is the default, the latter will be implemented when a patient id variable is included in the options (see below). The {cmd:corescore} command  also stores the Clinical Classifications Software Refined (CCSR) groups required to calculate the CORE score, as denoted by the variables {cmd:corecomp1} - {cmd:corecomp69}. It additionally stores the raw point total prior to exponential transformation as {cmd:COREscore_raw}.

{title:Options}

{p 4 8 2}
{cmd:idvar}{cmd:(}{it:varname}{cmd:)} is required when the input data could possibly 
contain multiple patient records, that is, comorbidity information from more than one hospital visit per patient. The unit will then be patients rather than visits.

{p 4 8 2}
{cmd:diagprfx}{cmd:(}{it:string}{cmd:)} is required to provide the root of the diagnostic code variable
names when the variables are not
listed as the {it:varlist} immediately following the program name. 

{p 4 8 2}
{cmd:noshow} requests that the summary of selected options be not displayed in the results window, at the start of the running of the program.

{title:Remarks}

{p 4 4 2}
If the patient id variable option is not specified then the data cannot be sorted by patient and multiple patient records cannot be taken into account. Instead, every observation will be considered independent from every other, with each observation representing a unique patient-visit, causing the unit to be visits. Please note that when the observational unit is patients, rather than visits, only the final visit input data will be retained, so it is advised that the data be sorted by patient and visit date prior to running the {cmd:corescore} command.

{title:Examples}

{p 8 8 2}
	{cmd:. corescore, idvar(ip_chart_no) diagprfx(ip_diag)}
	
	{cmd:. corescore DX1-DX16, noshow}

	{cmd:. corescore DX? DX??, idvar(acb_numb)}

	{cmd:. corescore ip_diag*, idvar(rec_id)}

	{cmd:. corescore, idvar(rec_id) diagprfx(dx_code_)}


{title:References}

{p 4 8 2}
Currently under consideration for publication

{title:Authors}

		Dr. Nikhil Chervu, Jeffrey Balian, and Dr. Peyman Benharash    University of California Los Angeles, USA

{title:License for Use of Comorbid Operative Risk Evaluation Score (CORE Score)}
{cmd:Copyright Notice:}
© 2024 Cardiovascular Outcomes Research Laboratories, Department of Surgery, David Geffen School of Medicine, University of California, Los Angeles, CA, USA. All rights reserved.

{cmd:License:}
The CORE Score created by Dr. Nikhil Chervu and Jeffrey Balian is made available under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License (CC BY-NC-ND 4.0).

{cmd:You are free to:}
{cmd:Share} — Copy and redistribute the material in any medium or format.

{cmd:The licensor cannot revoke these freedoms as long as you follow the terms below.}

{cmd:Under the following terms:}
{cmd:Attribution} — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
{cmd:Non-Commercial} — You may not use the material for commercial purposes.
{cmd:No Derivatives} — If you remix, transform, or build upon the material, you may not distribute the modified material.
{cmd:No Additional Restrictions} — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

{cmd:Commercial Use:}
Entities interested in commercial use of the CORE Score should contact software@tdg.ucla.edu for licensing opportunities.

{cmd:Access and Implementation:}
To access the CORE Score and for further information on implementation, visit UCLA Department of Surgery’s website at http://surgery.ucla.edu

For a full understanding of your rights and responsibilities under this license, please visit the Creative Commons CC BY-NC-ND 4.0 license page at https://creativecommons.org/licenses/by-nc-nd/4.0/