{smcl}
{* *! version 1.0.1, 12 Oct 2022}{...}
{cmd:help audit_cc}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:audit_cc} {hline 2} analysis of matched case-control audits of cervical cancer screening}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:audit_cc} {depvar} [{help if}] [{it:{help clogit##weight:weight}}] [{cmd:,} {it:options}]


{synoptset 28}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt gr:oupid}({varname})} matched group id variable {p_end}
{synopt :{opt id}({varname})} woman id variable {p_end}
{synopt :{opt casedd:iag}({varname})} case's date of diagnosis {p_end}
{synopt :{opt casedob}({varname})} case's date of birth {p_end}
{synopt :{opt casea:ge}({varname})} case's age at diagnosis {p_end}
{synopt :{opt casev:ars}} handles situations in which the variables in {bf:caseddiag()}, {bf:casedob()} and {bf:caseage()} are not case-specific {p_end}
{synopt :{opt scrd:ate}({varname})} date of the screening test {p_end}
{synopt :{opt res:ult}({varname})} result of the screening test {p_end}
{synopt :{opt agec:utpoints}({help numlist})} cut-points for age {p_end}
{synopt :{opt tlc:utpoints}({help numlist})} cut-points for screening exposures {p_end}
{synopt :{opt min:age}({help #})} minimum age for screening {p_end}
{synopt :{opt max:age}({help #})} maximum age for screening {p_end}
{synopt :{opt anythr:eshold}({help #})} exclusion of tests during the case's occult invasive phase for the time-since-last-screening-test exposure {p_end}
{synopt :{opt negthr:eshold}({help #})} exclusion of tests during the case's occult invasive phase for the time-since-last-negative-screening-test exposure {p_end}
{synopt :{opt nosres:ult}} allows for adequate but not otherwise specified test results {p_end}

{syntab:Reporting}
{synopt :{opt coeff:icients}} displays coefficients rather than odds ratios {p_end}
{synopt :{opt nod:etail}} suppresses information about the observations retained in the estimation {p_end}
{synopt :{opt sav:ing}({help filename:filename}[, replace])} saves the results in an external file {p_end}
{synopt :{opt data}({help filename:filename}[, replace])} saves the data necessary to re-estimate the models {p_end}
{synopt :{opt noh:eader}} suppresses the header information when the results are saved in a file {p_end}

{synoptline}
{p2colreset}{...}

{p 4 4 2}
{depvar} is a variable that identifies the cases and controls; {depvar} equal to one indicates cases, whereas all other non-missing values are treated as controls. Note that this is 
different from how the {help clogit} command would treat the dependent variable, i.e. non-zero and non-missing would indicate cases and zeros would represent controls.

{p 4 4 2}
The data must be in long format (see {help reshape:help reshape}), with each screening test on a separate line. Women with no screening event must be included in the data set with 
a single record where the date and result of the test are missing. Each matched group must contain one case and one or more controls matched on age and, if necessary, other characteristics. 

{p 4 4 2}
{opt fweight}s, {opt iweight}s and {opt pweight}s are allowed but, since they apply to groups as a whole and not to individual observations, their values 
must be constant which each matched group. For more details see {mansection R clogitRemarksandexamplesUseofweights:{it:Use of weights}} in {bf:[R] clogit}.


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:audit_cc} fits a set of conditional logistic models for the analysis of matched case-control audits of cervical screening programmes. The command assumes that cases 
and controls have been (approximately or exactly) matched on age as part of the study design prior to analysis. This is because cervical screening is usually offered at 
different intervals depending on age and there is some evidence suggesting that the impact of screening differs by age. Matching on other variables is optional. Analyses are 
then stratified by case's age group and reported for two screening exposure measures: (1) time since last test and (2) time since last negative test. Users can easily 
generate automatic reports with results displayed in publication-quality tables and can save the manipulated data set used for the estimation of 
the conditional logistic models so that further analysis or the use of post-estimation commands (e.g. {bf:margins}) is possible.{p_end}


{title:Options}

{dlgtab:Model}

{phang}
{opt groupid(varname)} specifies the variable (either string or numeric) that uniquely identifies the matched groups. This option is required.

{phang}
{opt id(varname)} specifies the variable (either string or numeric) that uniquely identifies the women. This option is required.

{phang}
{opt caseddiag(varname)} identifies the variable containing the date of diagnosis (for cases) or the matched case's date of diagnosis (for controls); {it: varname} must be a date variable (see {help datetime:help datetime}). This option is required.

{phang}
{opt casedob(varname)} names the variable for the case's date of birth (for the controls this is the date of birth of the matched case); {it: varname} must be a date variable. Either 
this option or {bf: caseage()}, but not both, must be specified. 

{phang}
{opt caseage(varname)} indicates the variable containing the age at diagnosis (for cases) or the matched case's age at diagnosis (for controls). Either this option or {bf: casedob()}, but 
not both, must be specified. 

{phang}
{opt casevars} implies that for the controls the observations for the variables specified in {bf: caseddiag()}, {bf: caseage()} and {bf: casedob()} are set to the corresponding case's 
values. This option is particularly useful when the data set does not contain the case-specific variables for date of diagnosis, age or date of birth and the users prefer not to create them 
(e.g. by using the {bf: egen} command) before running {bf: audit_cc}.

{phang}
{opt scrdate(varname)} specifies the variable containing the date of the screening test; {it: varname} must be a date variable. This option is required. 

{phang}
{opt result(varname)} identifies the variable containing the screening test results. {it:varname} must be a numeric variable with integer values indicating the following:{break}
{bf:-1} = "adequate but not otherwise specified"{break}
{space 1}{bf:1} = "inadequate"{break} 
{space 1}{bf:2} = "negative"{break}
{space 1}{bf:3} or above = "positive"{break}
Values below -1 or equal to zero are treated as missing test results.
When varname contains observations coded as -1 the {bf: nosresults} option must be specified; in that case the analysis for the time-since-last-negative-test exposure is not 
performed. The {bf:result()} option is required.

{phang}
{opt agecutpoints(numlist)} specifies the cut-points (in years) to be used for the age stratification. For example, {bf: agecutpoints(25 40 55 70)} tells Stata to display 
age-specific estimates for the 3 age groups: [25,40), [40,55) and [55,70), where here a square bracket means that the value is included whereas a round bracket means 
it is excluded (e.g. [40,55) refers to the interval 40 <= age < 55). The matched groups where the case's age is < the minimum or >= the  maximum cut-point 
(i.e. age<25 or age>=70 in the above example) are excluded from the analysis. Age stratification can be avoided by specifying for example {bf: agecutpoints(0 150)}. The choice of 
the age cut-points could reflect the different screening guidelines in force depending on the woman's age. The default is {bf: agecutpoints(25 50 65 100)}.

{phang}
{opt tlcutpoints(numlist)} specifies the cut-points (in years) to be used for the two screening exposure measures, i.e. (1) time since the last test and (2) time since the last negative 
test. The cut-points define time intervals, with the last one being an open interval. For example, {bf: tlcutpoints(0 1 3 5)} leads to four intervals: [0,1), [1,3), [3,5) and 
[5,+infinity). Note that the last cut-point is the lower bound of the last interval. Users interested in an "ever having had a test" exposure could, for instance, use 
{bf: tlcutpoints(0 150)}. The default is {bf: tclcutpoint(0 0.5 3.5 5.5 9.5)}.

{phang} 
{opt minage(#)} indicates the age (in years) at first invitation for screening. All screening tests carried out before the age specified in {bf: minage()} are ignored. The default is 
{bf: minage(25)}.

{phang}
{opt maxage(#)} indicates the age (in years) at last invitation for screening. All screening tests carried out after the age specified in {bf: maxage()} are ignored. The default is 
{bf: maxage(100)}.

{phang}
{opt anythreshold(#)} specifies the exclusion period (in months) related to the case's occult invasive phase when deriving the time-since-last-test exposure. All screening tests 
carried out during that period are disregarded in the analysis for time since last test. For example, {bf: anythreshold(12)} indicates a 12-month exclusion period. The default is 
{bf: anythreshold(6)}.
 
{phang}
{opt negthreshold(#)} specifies the exclusion period (in months) related to the case's occult invasive phase when deriving the time-since-last-negative-test exposure. All negative tests 
carried out during that period are disregarded in the analysis for time since last negative test. The default is {bf: negthreshold(0)}, i.e. no exclusion period.

{phang}
{opt nosresults} must be specified when the variable in {bf:result()} contains test results coded as -1 (i.e. "adequate but not otherwise specified"). When this option is used, 
the analysis for the time-since-last-negative-test exposure is not performed.


{dlgtab:Reporting}

{phang}
{opt coefficients} reports the estimated coefficients rather than the odds ratios (exponentiated coefficients). This option affects only how results are displayed and not how they are estimated.

{phang}
{opt nodetail} suppresses part of the output in the Results windows and in the saved file if {bf: saving()} is specified. The tables displaying the number of observations 
retained in each age-specific estimation are omitted.

{phang}
{opt saving(filename[, replace])} saves the results in an external file. If {it:filename} is specified without extension, .docx is assumed and the results are saved in a 
Word document. Possible file formats are .docx, .log and .smcl. If the sub-option {bf:replace} is supplied, Stata overwrites the file in case it already exists.

{phang}
{opt data(filename[, replace])} saves a data set containing the records (one per woman) used to fit the age-specific conditional logistic models. If filename is specified without 
extension, .dta is assumed. If the sub-option {bf: replace} is specified, Stata overwrites the file in case it already exists. The saved data set contains the variables 
specified in {bf: groupid()} and {bf: id()} along with {bf: agegroup} (categorical age variable created using the cut-points in {bf: agecutpoints()}), the two exposure 
measures ({bf:Time_since_last_test} and {bf:Last_screened_negative}), {bf: weights} (if weights are supplied). The variable {bf: Last_screened_negative} is omitted when 
the {bf:nosresults} option is specified.

{phang}
{opt noheader} has an effect only when the results are saved in a file using the {bf: saving()} option. It suppresses the header information (name of the command, Stata 
version and current date) at the top of the Word, log or smcl document.




{title:Examples}

{p 4} {it:Setup}

{phang2} {cmd:. use auditdata, clear}{p_end}


{p 4} {bf: {ul: Example 1}}

{p 4 4 2} Let's consider two age groups (25 to <50 and 50 to <65 years) and use the {bf: tlcutpoint()} option to specify cut-points for the screening exposures:

{phang2} {cmd:. audit_cc case, groupid(matchgrp) id(woman_id) caseddiag(case_ddiag) casedob(case_dbirth) scrdate(testdate) res(testresult) agec(25 50 65) tlc(0 5 10)} {p_end}


{p 4 4 2} Since the default cut-points for age are 25, 50, 65 and 100, we would obtained the same output by specifying an if qualifier instead of using the {bf: agecutpoints()} option:

{phang2} {cmd:. audit_cc case if case_age<65, groupid(matchgrp) id(woman_id) caseddiag(case_ddiag) casedob(case_dbirth) scrdate(testdate) res(testresult) tlc(0 5 10)} {p_end}



{p 4} {bf: {ul: Example 2}}

{p 4 4 2} Let's restrict the analysis to age<50 years and exclude all the screening tests performed during the 9 months (the default is 6 months) prior to the case's data
of diagnosis. We also save the results in a Word document called myresults.docx (the file already exists so we specify the sub-option {bf: replace} in {bf: saving()}). In addition, 
we use the {bf: noheader} option to suppress part of the output and we {bf:set showbaselevels} to {bf: on} so that the reference categories are displayed 
in the result tables.

{phang2} {cmd:. set showbaselevels on} {p_end}

{phang2} {cmd:. audit_cc case if case_age<50, groupid(matchgrp) id(woman_id) caseddiag(case_ddiag) casedob(case_dbirth) scrdate(testdate) res(testresult) anythr(9) noheader sav(myresults, replace)} {p_end}
	

{p 4 4 2} In the previous command we could have also specified the {bf: data()} option and saved the data set used for the estimation of the age-specific conditional logistic models. This 
would be useful if, for example, we want to use post-estimation commands (e.g. {bf:test} or {bf:margins}) or if we want to identify which observations were dropped by a specific 
{bf:clogit} model (i.e. we need to access the information stored in {bf: e(sample)}). For instance, had we specified the {bf:data(mydata, replace)} option

{phang2} {cmd:. audit_cc case if case_age<50, groupid(matchgrp) id(woman_id) caseddiag(case_ddiag) casedob(case_dbirth) scrdate(testdate) res(testresult) anythr(9) noheader sav(myresults, replace) data(mydata, replace)} {p_end}

{p 4 4 2} we could reproduce the results for the first age group (i.e. "25 to <50") and the time-since-last-test exposure by typing

{phang2} {cmd:. use mydata, clear} {p_end}

{phang2} {cmd:. clogit Case_status i.Time_since_last_test if agegroup==1, group(matchgrp) or} {p_end}

      
{title:Authors}

{p 4 4 2}
Milena Falcaro {break}
King's College London {break}
London, UK {break}
{browse "mailto:milena.falcaro@kcl.ac.uk":milena.falcaro@kcl.ac.uk}

{p 4 4 2}
Peter Sasieni {break}
King's College London {break}
London, UK {break}
{browse "mailto:peter.sasieni@kcl.ac.uk":peter.sasieni@kcl.ac.uk}

{p 4 4 2}
Alejandra Casta{c n~}on {break}
King's College London {break}
London, UK {break}
{browse "mailto:alejandra.castanon@kcl.ac.uk":alejandra.castanon@kcl.ac.uk}


{title:References}

{phang} Breslow NE and Day NE (1980). {it: Statistical methods in cancer research, vol. 1 - The analysis of case-control studies}. Lyon: IARC.

{phang} Casta{c n~}on A, Kamineni A, Elfstr{c o:}m KM, Lim AWW and Sasieni P (2021). Exposure definition in case-control studies of cervical cancer screening: a systematic
literature review. {it:Cancer Epidemiology, Biomarkers and Prevention} 30(12): 2154-2166.

{phang} Sasieni P, Cuzick J and Lynch-Farmery E (1996). Estimating the efficacy of screening by auditing smear histories of women with and without cervical 
cancer. {it:British Journal of Cancer} 73: 1001-1005.

{phang} Weiss NS (1994). Application of the case-control method in the evaluation of screening. {it:Epidemiologic Reviews} 16: 102-108.


