{smcl}
{* *! version 1.2.0 18 August 2024}{...}
{viewerdialog "pim3" "dialog pim3"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "pccmtoolkit" "help pccmtoolkit"}{...}
{vieweralsosee "pelod2" "help pelod2"}{...}
{vieweralsosee "prismscore" "help prismscore"}{...}
{viewerjumpto "Syntax" "./pim3##syntax"}{...}
{viewerjumpto "Description" "./pim3##description"}{...}
{viewerjumpto "Options" "./pim3##options"}{...}
{viewerjumpto "Remarks" "./pim3##remarks"}{...}
{viewerjumpto "Citation" "./pim3##citation"}{...}
{viewerjumpto "License" "./pim3##license"}{...}
{title:Title}

{phang}
{bf:pim3} {hline 2} a command to calculate the Paediatric Index of Mortality 3 (PIM3) score

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:pim3} {newvar}
{ifin}
{cmd:,}
{opth s:bp(varname)} {opt mv(varname)} {opt pao2(varname)} {opt f:io2(varname)}
{opt pup:ils(varname)} {opt base:excess(varname)} {opt el:ective(varname)}
{opt proc:edure(varname)}
[{opt lowr:isk(varname)} {opt highr:isk(varname)} {opt veryhighr:isk(varname)}]
[{opt risk(varname)}]
[{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Cardiovascular}
{synopt:{opth s:bp(varname)}}systolic blood pressure (mmHg){p_end}

{syntab: Respiratory}
{synopt:{opt mv(varname)}}mechanical ventilation within first hour (0=no, 1=yes){p_end}
{synopt:{opt pao2(varname)}}partial pressure of oxygen in arterial blood (mmHg){p_end}
{synopt:{opt f:io2(varname)}}fraction of inspired oxygen (0.21 - 1.0 or 21% - 100%){p_end}

{syntab: Neurologic}
{synopt:{opt pup:ils(varname)}}pupil reaction to light (0=both reactive, 1=both fixed and dilated){p_end}

{syntab: Renal}
{synopt:{opt base:excess(varname)}}base excess in arterial or capillary blood (mmol/L){p_end}

{syntab: Admission Reason}
{synopt:{opt el:ective(varname)}}elective admission (0=no, 1=yes){p_end}
{synopt:{opt proc:edure(varname)}}{help pim3##remarks:reason for ICU admission (0-3)}{p_end}

{syntab:Risk category}
{synopt:{opt lowr:isk(varname)}}low-risk diagnosis (0=no, 1=yes){p_end}
{synopt:{opt highr:isk(varname)}}high-risk diagnosis (0=no, 1=yes){p_end}
{synopt:{opt veryhighr:isk(varname)}}very high-risk diagnosis (0=no, 1=yes){p_end}
{center: {hline 5}{it: or} {hline 5}}
{synopt:{opt risk(varname)}}{help pim3##remarks:risk category (0-3)}{p_end}

{syntab:Debugging Options}
{synopt:{opt noimp:utation}}treat missing values as missing{p_end}
{synopt:{opt noval:idation}}skip out-of-range data checks{p_end}
{synopt:{opt tr:ace}}turn on trace for debugging{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:pim3} calculates the Paediatric Index of Mortality 3 (PIM3) score. The score is an outcome prognostication tools that has been used
extensively in clinical care and research to calculate the expected mortality and control for illness severity in pediatric intensive care units.{p_end}

{pstd}See {help "./pim3##citation":Citation} for proper attribution.{p_end}

{marker options}{...}
{title:Options}

{phang}
For all required variables, if there is data missing you will receive a warning. The calculation will still be performed using normal values for the age group.{p_end}

{dlgtab:Cardiovascular}

{phang}
{opth sbp(varname)} specifies the systolic blood pressure in mmHg.{p_end}

{dlgtab:Respiratory}

{phang}
{opt mv(varname)} specifies whether mechanical ventilation was used within the first hour of admission. The variable must be coded as {bf:0} = No | {bf:1} = Yes.{p_end}

{phang}
{opt pao2(varname)} specifies the name of the partial pressure of oxygen (PaO2) variable in mmHg.

{phang}
{opt fio2(varname)} specifies the name of the fraction of inspired oxygen (FiO2) variable. It can be entered as 0.21-1.0 or 21-100.{p_end}

{dlgtab:Neurologic}

{phang}
{opt pupils(varname)} specifies the pupillary reaction to light. The variables must be coded as: {bf:0} = reactive | {bf:1} = both fixed{p_end}

{dlgtab:Renal}

{phang}
{opt baseexcess(varname)} specifies the base excess in arterial or capillary blood in mmol/L.

{dlgtab:Admission Reason}

{phang}
{opt elective(varname)} specifies whether the admission was elective. The variable must be coded as {bf:0} = No | {bf:1} = Yes.{p_end}

{phang}
{opt procedure(varname)} specifies whether recovery from surgery or a procedure is the main reason for ICU admission (0-3). The variable must be coded as {bf:0} = Recovery from procedure {bf: {ul:IS NOT}} the main reason for ICU admission | {bf:1} = Recovery from a bypass cardiac procedures. | {bf:2} = Recovery from a non-bypass cardiac procedure | {bf:3} = Recovery from a noncardiac procedure {p_end}

See the {help pim3##remarks:remarks} section for more information.

{pstd}
You must specify either the {opt risk(varname)} or the three risk stratification variables: {opt lowrisk(varname)}, {opt highrisk(varname)}, and {opt veryhighrisk(varname)}.

{phang}
{opt lowrisk(varname)} specifies whether the patient has a low-risk diagnosis. The variable must be coded as {bf:0} = No | {bf:1} = Yes.{p_end}

{phang}
{opt highrisk(varname)} specifies whether the patient has a high-risk diagnosis. The variable must be coded as {bf:0} = No | {bf:1} = Yes.{p_end}

{phang}
{opt veryhighrisk(varname)} specifies whether the patient has a very high-risk diagnosis. The variable must be coded as {bf:0} = No | {bf:1} = Yes.{p_end}

{phang}
{opt risk(varname)} specifies the risk category (0-3). The variable must be coded as {bf:0} = No low risk, high risk or very high risk diagnosis | {bf:1} = Low risk diagnosis | {bf:2} = High risk diagnosis | {bf:3} = Very high risk diagnosis {p_end}
See the {help pim3##remarks:remarks} section for more information.

{dlgtab:Options}

{phang}
{opt noimputation} calculated score will be set to missing if any of the included variables are missing. The default is to use normal physiological values for age when values are missing.{p_end}

{phang}
{opt novalidation} specifies that out-of-range data checks should be skipped.
The default is to treat out-of-range values as missing.

{phang}
{opt trace} turns on trace for debugging purposes.

{marker remarks}{...}
{title:Remarks}

{pstd}
The {opt procedure} variable should be coded as follows:

{phang2}0: Recovery from procedure {bf: {ul:IS NOT}} the main reason for ICU admission{p_end}
{phang2}1: Recovery from a bypass cardiac procedures the main reason for ICU admission{p_end}
{phang2}2: Recovery from a non-bypass cardiac procedure{p_end}
{phang2}3: Recovery from a noncardiac procedure{p_end}

{pstd}
If using the {opt risk} variable instead of the individual risk stratification variables, it should be coded as follows:

{phang2}0: No low, high or very high risk diagnosis{p_end}
{phang2}1: Low risk diagnosis{p_end}
{phang2}2: High risk diagnosis{p_end}
{phang2}3: Very high risk diagnosis{p_end}

{pstd}
By default, the command performs data validation and imputes missing values with normal physiological values. These behaviors can be modified using the {opt novalidation} and {opt noimputation} options.

{title:References}

{pstd}
[1] Straney L, Clements A, Parslow RC, et al. Paediatric Index of Mortality 3: An Updated Model for Predicting Mortality in Pediatric Intensive Care. Ped Crit Care. 2013;14(7):673-681.

{marker citation}{...}
{title:Citation}

{pstd}
Please cite this command as:

Azamfirei R, Mennie C, Fackler J, Kudchadkar SR. Pediatric Critical Care Illness Severity Toolkit: Stata Commands for Calculation of Pediatric Index of Mortality and Pediatric Logistic Organ Dysfunction Scores. JCCM. 2024;10(1):16-18. | DOI: {browse "https://doi.org/10.2478/jccm-2023-0033":10.2478/jccm-2023-0033}

{title:Authors}
{p}

{pstd}Razvan Azamfirei | Email: {browse "mailto:stata@azamfirei.com":stata@azamfirei.com}{p_end}
{pstd}Colleen Mennie{p_end}
{pstd}James Fackler{p_end}
{pstd}Sapna R. Kudchadkar{p_end}

{marker License}{...}
{title:License}
{pstd}Copyright 2023 Razvan Azamfirei{p_end}
{pstd}Licensed under the Apache License, Version 2.0 (the"License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at: {p_end}

{pstd}{browse "https://www.apache.org/licenses/LICENSE-2.0":http://www.apache.org/licenses/LICENSE-2.0}{p_end}

{pstd}Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.{p_end}
{pstd} See the License for the specific language governing permissions and limitations under the License. {p_end}

{title:Also see}

{psee}
{helpb pelod2}, {helpb prismscore}, {helpb pccmtoolkit}
{p_end}
