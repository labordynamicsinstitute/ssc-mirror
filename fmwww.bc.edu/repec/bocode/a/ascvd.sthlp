{smcl}
{* *! version 1.1.0 18Jub2024}{...}

{title:Title}

{p2colset 5 14 15 2}{...}
{p2col:{hi:ascvd} {hline 2}} Computes ACC/AHA 10-year risk for an initial hard atherosclerotic cardiovascular disease (ASCVD) event {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
{cmd:ascvd} using data in memory

{p 8 17 2}
				{cmdab:ascvd}
				{ifin}
				{cmd:,}
				{opt fem:ale}({it:varname}) 
				{opt bla:ck}({it:varname}) 				
				{opt age:}({it:varname}) 
				{opt chol:}({it:varname}) 				
				{opt hdl:}({it:varname}) 
				{opt sbp:}({it:varname})  
				{opt tr:htn}({it:varname}) 
				{opt sm:oker}({it:varname}) 
				{opt diab:etes}({it:varname}) 
 				[ {opt incl:ude} ]



{pstd}
Immediate form of {cmd:ascvd}

{p 8 17 2}
				{cmd:ascvdi}
				{cmd:,} 
				{opt fem:ale}({it:0/1}) 
				{opt bla:ck}({it:0/1}) 				
				{cmdab:age:}({it:#}) 
				{cmdab:chol:}({it:#})  
				{cmdab:hdl:}({it:#})  
				{cmdab:sbp:}({it:#})  
				{cmdab:tr:htn}({it:0/1}) 
				{cmdab:sm:oker}({it:0/1}) 
				{cmdab:diab:etes}({it:0/1}) 
				[ {opt incl:ude} ]



{synoptset 21 tabbed}{...}
{synopthdr:ascvd options}
{synoptline}
{syntab:Required}
{synopt:{opt fem:ale(varname)}}gender, where female = 1 and male = 0{p_end}
{synopt:{opt bla:ck(varname)}}race, where black = 1 and all others = 0{p_end}
{synopt:{opt age:}(varname)}age in years{p_end}
{synopt:{opt chol:}(varname)}total cholesterol level (mg/dL){p_end}
{synopt:{opt hdl:}(varname)}high density lipoprotein level (mg/dL){p_end}
{synopt:{opt sbp:}(varname)}systolic blood pressure (mmHg){p_end}
{synopt:{opt tr:htn}(varname)}treated for hypertension, where treated = 1 and not treated = 0 {p_end}
{synopt:{opt sm:oker}(varname)}smoking status, where smoker = 1 and non-smoker = 0{p_end}
{synopt:{opt diab:etes}(varname)}diabetes status, where diabetic = 1 and non-diabetic = 0{p_end}

{syntab:Optional}
{synopt:{opt incl:ude}}produces indicator for whether patient's input values meet ACC/AHA guidelines for computing ASCVD risk {p_end}
{synoptline}
{p 4 6 2}

{synoptset 21 tabbed}{...}
{synopthdr:immediate options}
{synoptline}
{syntab:Required}
{synopt:{opt fem:ale(#)}}gender, where female = 1 and male = 0{p_end}
{synopt:{opt bla:ck(#)}}race, where black = 1 and all others = 0{p_end}
{synopt:{opt age:}(#)}age in years{p_end}
{synopt:{opt chol:}(#)}total cholesterol level (mg/dL){p_end}
{synopt:{opt hdl:}(#)}high density lipoprotein level (mg/dL){p_end}
{synopt:{opt sbp:}(#)}systolic blood pressure (mmHg){p_end}
{synopt:{opt tr:htn}(#)}treated for hypertension, where treated = 1 and not treated = 0 {p_end}
{synopt:{opt sm:oker}(#)}smoking status, where smoker = 1 and non-smoker = 0{p_end}
{synopt:{opt diab:etes}(#)}diabetes status, where diabetic = 1 and non-diabetic = 0{p_end}

{syntab:Optional}
{synopt:{opt incl:ude}}indicates whether patient's input values meet ACC/AHA guidelines for computing ASCVD risk {p_end}

{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:ascvd} Computes 10-year risk for an initial hard atherosclerotic cardiovascular disease (ASCVD) event (defined as first occurrence 
of non-fatal myocardial infarction, congestive heart disease death, or fatal or nonfatal stroke), based on American College of 
Cardiology/American Heart Association (ACC/AHA) guidelines (Goff et al. 2014). 

{pstd}
As of early 2024, AHA has produced a new set of risk models (see Khan et al [2024]), which can be downloaded as a new package from SSC called {helpb prevent}. 

{pstd}
{opt ascvdi} is the immediate form of {opt ascvd}; see {help immed}.



{title:Remarks}

{pstd}
The ASCVD risk models were generated primarily for African American and White women and men. However, the number of African Americans, 
particularly men, used in generating these models was relatively low, creating a somewhat greater level of uncertainty with respect to these estimates. The 
absence of other ethnicities limits the applicability of the equations to other populations, in particular to lower risk populations, such as Asians or 
Hispanics/Latinos. Application of the Pooled Cohort Equations to these and other patient subgroups should be performed with caution, as it may lead to 
unpredictable over- and underestimation in these and other patient subgroups.    

{pstd}
The ASCVD risk models are also limited in their accuracy for individuals with characteristics outside of the ranges in which the models were generated and tested 
(or meet ACC/AHA guidelines for computing the risk score). {cmd:ascvd} will compute the risk score, regardless of whether the input values are within acceptable 
ranges or not. The {cmd:include} option will tell the user whether an individual input values are with acceptable ranges or not. More specifically: {it:age} between 40 and 79;
{it:total cholesterol} between 130 and 320; {it:high density lipoprotein} between 20 and 100; and {it:systolic blood pressure} between 90 and 200.  
   


{title:Examples}

    {hline}
    Setup
{phang2}{cmd:. use "example_ascvd.dta", clear}{p_end}

{pstd}Run {cmd:ascvd} using data in memory{p_end}
{phang2}{cmd:. ascvd , age(age) female(female) black(black) chol(chol) hdl(hdl) sbp(sbp) trhtn(bptreat) smoker(smoke) diabetes(diabetes)}

{pstd}Rerun command, specifying the "include" option to indicate whether patients' input values meet ACC/AHA guidelines for computing ASCVD risk {p_end}
{phang2}{cmd:. ascvd , age(age) female(female) black(black) chol(chol) hdl(hdl) sbp(sbp) trhtn(bptreat) smoker(smoke) diabetes( diabetes) include}

    {hline}
{pstd}Run {cmd:ascvdi} for an individual case and specify the include option{p_end}
{phang2}{cmd:. ascvdi , age(58) female(1) black(0) chol(270) hdl(99) sbp(190) trhtn(1) smoker(0) diabetes(1) include}{p_end}

    {hline}



{title:Stored results}

{pstd}
{cmd:ascvdi} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(ascvd10)}}10-year risk estimate{p_end}



{title:References}

{p 4 8 2}
Goff Jr, D.C., Lloyd-Jones, D.M., Bennett, G., Coady, S., D'agostino, R.B., Gibbons, R., Greenland, P., Lackland, D.T., 
Levy, D., O'donnell, C.J. and J.G. Robinson. 2014. 2013 ACC/AHA guideline on the assessment of cardiovascular risk: 
a report of the American College of Cardiology/American Heart Association Task Force on Practice Guidelines. 
{it:Circulation} 129(25_suppl_2), S49-S73.{p_end}

{p 4 8 2}
Khan, S. S., Matsushita, K., Sang, Y., et al. Development and validation of the American Heart Association 
Predicting Risk of Cardiovascular Disease EVENTs (PREVENT^TM) equations. Circulation 2024;149:30–449.{p_end}

{p 4 8 2} 
see also: {browse "https://www.cvriskcalculator.com/":"https://www.cvriskcalculator.com/"} {p_end}



{marker citation}{title:Citation of {cmd:ascvd}}

{p 4 8 2}{cmd:ascvd} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2023). ASCVD: Stata module for computing ACC/AHA 10-year risk for an initial hard atherosclerotic cardiovascular disease (ASCVD) event {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}	alinden@lindenconsulting.org{p_end}


         
{title:Acknowledgments} 

{p 4 4 2} I would like to thank Albert Botchway for advocating that I write this package.



{title:Also see}

{p 4 8 2} {helpb prevent} (if installed), {helpb framingham} (if installed){p_end}




