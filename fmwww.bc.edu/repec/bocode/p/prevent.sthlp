{smcl}
{* *! version 1.0.0 17Jun2024}{...}

{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{hi:prevent} {hline 2}} Computes AHA 10-year and 30-year risk of cardiovascular disease (atherosclerotic and heart failure)  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Compute 10-year CVD risk using data in memory:

{p 8 17 2}
				{cmdab:prevent10}
				{ifin}
				{cmd:,}
				{it: options} 

				
{pstd}
Compute 30-year CVD risk using data in memory:

{p 8 17 2}
				{cmdab:prevent30}
				{ifin}
				{cmd:,}
				{it: options} 
	

{pstd}
Immediate form of {cmd:prevent10}

{p 8 17 2}
				{cmd:prevent10i}
				{cmd:,} 
				{it: options} 
				
				
{pstd}
Immediate form of {cmd:prevent30}

{p 8 17 2}
				{cmd:prevent30i}
				{cmd:,} 
				{it: options} 		


{synoptset 28 tabbed}{...}
{synopthdr:prevent10/prevent30 options}
{synoptline}
{syntab:Required}
{synopt:{opt fem:ale(varname)}}gender, where female = 1 and male = 0{p_end}
{synopt:{opt age:}(varname)}age in years between 30 and 79{p_end}
{synopt:{opt chol:}(varname)}total cholesterol level between 130 and 320 mg/dL{p_end}
{synopt:{opt hdl:}(varname)}high density lipoprotein level between 20 and 100 mg/dL{p_end}
{synopt:{opt sbp:}(varname)}systolic blood pressure between 90 and 200 mmHg {p_end}
{synopt:{opt bmi:}(varname)}body mass index between 18.5 and 40 {p_end}
{synopt:{opt gfr:}(varname)}estimated glomerular filtration rate between 15 and 150 {p_end}
{synopt:{opt anti:htn}(varname)}anti-hypertensive medication, where treated = 1 and not treated = 0 {p_end}
{synopt:{opt stat:in}(varname)}lipid-lowering medication (statin), where treated = 1 and not treated = 0 {p_end}
{synopt:{opt sm:oker}(varname)}smoking status, where smoker = 1 and non-smoker = 0{p_end}
{synopt:{opt diab:etes}(varname)}diabetes status, where diabetic = 1 and non-diabetic = 0{p_end}

{syntab:Optional}
{synopt:{opt incl:ude}}produces indicator for whether patient's input values meet AHA guidelines for computing risk {p_end}
{synoptline}
{p 4 6 2}

{synoptset 28 tabbed}{...}
{synopthdr:immediate options}
{synoptline}
{syntab:Required}
{synopt:{opt fem:ale(#)}}gender, where female = 1 and male = 0{p_end}
{synopt:{opt age:}(#)}age in years between 30 and 79{p_end}
{synopt:{opt chol:}(#)}total cholesterol level between 130 and 320 mg/dL{p_end}
{synopt:{opt hdl:}(#)}high density lipoprotein level between 20 and 100 mg/dL{p_end}
{synopt:{opt sbp:}(#)}systolic blood pressure between 90 and 200 mmHg {p_end}
{synopt:{opt bmi:}(#)}body mass index between 18.5 and 40 {p_end}
{synopt:{opt gfr:}(#)}estimated glomerular filtration rate between 15 and 150 {p_end}
{synopt:{opt anti:htn}(#)}anti-hypertensive medication, where treated = 1 and not treated = 0 {p_end}
{synopt:{opt stat:in}(#)}lipid-lowering medication (statin), where treated = 1 and not treated = 0 {p_end}
{synopt:{opt sm:oker}(#)}smoking status, where smoker = 1 and non-smoker = 0{p_end}
{synopt:{opt diab:etes}(#)}diabetes status, where diabetic = 1 and non-diabetic = 0{p_end}

{syntab:Optional}
{synopt:{opt incl:ude}}indicates whether patient's input values meet AHA guidelines for computing risk {p_end}

{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:prevent10} computes 10-year risk for coronary vascular disease (CVD), atherosclerotic cardiovascular disease (ASCVD), and heart failure (HF). Similarly,
{cmd:prevent30} computes the 30-year risk for coronary vascular disease (CVD), atherosclerotic cardiovascular disease (ASCVD), and heart failure (HF). The 
risk equations were developed by the American Heart Association Cardiovascular-Kidney-Metabolic Scientific Advisory Group and were derived 
and validated in a large, diverse sample of over 6 million individuals (Khan et al 2024). {cmd:prevent10} and {cmd:prevent30} produce risk estimates 
using the base model described in Khan et al (2024). 

{pstd}
{cmd:prevent10i} and {cmd:prevent30i} are the immediate forms of {cmd:prevent10} and {cmd:prevent30}, respectively; see {help immed}.



{title:Remarks}

{pstd}
The risk for each outcome (CVD, ASCVD, HF) is calculated by separate models. Individuals may develop both ASCVD and HF. Therefore, the predicted risk of the 
components (ASCVD, HF) may be greater than the predicted risk of the composite outcome (CVD) [Khan et al 2024].

   

{title:Examples}

    Setup

{phang2}{cmd:. use "example_prevent.dta", clear}{p_end}

{pstd}Run {cmd:prevent10} to compute 10 year risk, using data in memory{p_end}

{phang2}{cmd:. prevent10 , female(female) age(age) chol(chol) hdl(hdl) sbp(sbp) diab(diab) smoke(smoke) bmi(bmi) gfr(gfr) antihtn(antihtn) statin(statin)}

{pstd}Rerun {cmd:prevent10}, specifying the "include" option to indicate whether patients' input values meet AHA guidelines for computing CVD risk {p_end}

{phang2}{cmd:. prevent10 , female(female) age(age) chol(chol) hdl(hdl) sbp(sbp) diab(diab) smoke(smoke) bmi(bmi) gfr(gfr) antihtn(antihtn) statin(statin) include}

{pstd}Run {cmd:prevent30} to compute 30 year risk, using data in memory{p_end}

{phang2}{cmd:. prevent30 , female(female) age(age) chol(chol) hdl(hdl) sbp(sbp) diab(diab) smoke(smoke) bmi(bmi) gfr(gfr) antihtn(antihtn) statin(statin) include}

{pstd}Run {cmd:prevent10i} to predict 10-year risk for an individual case{p_end}

{phang2}{cmd:. prevent10i , female(1) age(50) chol(200) hdl(45) sbp(160) diab(1) smoke(0) bmi(35) gfr(90) antihtn(1) statin(0) include}{p_end}

{pstd}Run {cmd:prevent30i} to predict 30-year risk for an individual case{p_end}

{phang2}{cmd:. prevent30i , female(1) age(50) chol(200) hdl(45) sbp(160) diab(1) smoke(0) bmi(35) gfr(90) antihtn(1) statin(0) include}{p_end}



{title:Stored results}

{pstd}
{cmd:prevent10i} and {cmd:prevent30i} store the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(ascvd10)}}10-year risk estimate for ASCVD{p_end}
{synopt:{cmd:r(cvd10)}}10-year risk estimate for CVD{p_end}
{synopt:{cmd:r(hf10)}}10-year risk estimate for HF{p_end}
{synopt:{cmd:r(ascvd30)}}30-year risk estimate for ASCVD{p_end}
{synopt:{cmd:r(cvd30)}}30-year risk estimate for CVD{p_end}
{synopt:{cmd:r(hf30)}}30-year risk estimate for HF{p_end}



{title:References}

{p 4 8 2}
Khan, S. S., Matsushita, K., Sang, Y., et al. Development and validation of the American Heart Association 
Predicting Risk of Cardiovascular Disease EVENTs (PREVENT^TM) equations. Circulation 2024;149:30–449.{p_end}

{p 4 8 2} 
see also: {browse "https://professional.heart.org/en/guidelines-and-statements/prevent-calculator"} {p_end}



{marker citation}{title:Citation of {cmd:prevent}}

{p 4 8 2}{cmd:prevent} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2024). PREVENT: Stata module for computing AHA 10-year and 30-year risk of cardiovascular disease (atherosclerotic and heart failure) {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}


         
{title:Acknowledgments} 

{p 4 4 2} I would like to thank Rawan Ajeen for advocating that I write this package.



{title:Also see}

{p 4 8 2} {helpb ascvd} (if installed), {helpb framingham} (if installed){p_end}




