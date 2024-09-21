{smcl}
{* *! version 1.2 18 Aug 2024}{...}
{viewerdialog "pelod2" "dialog pelod2"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "pccmtoolkit" "help pccmtoolkit"}{...}
{vieweralsosee "pim3" "help pim3"}{...}
{vieweralsosee "prismscore" "help prismscore"}{...}
{viewerjumpto "Syntax" "./pelod2##syntax"}{...}
{viewerjumpto "Description" "./pelod2##description"}{...}
{viewerjumpto "Options" "./pelod2##options"}{...}
{viewerjumpto "Remarks" "./pelod2##remarks"}{...}
{viewerjumpto "Citation" "./pelod2##citation"}{...}
{viewerjumpto "License" "./pelod2##license"}{...}
{title:Title}

{phang}
{bf:pelod2} {hline 2} a command to calculate the Pediatric Logistic Organ Dysfunction 2 (PELOD-2) score

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:pelod2} {newvar}
{ifin}
{cmd:,}
{opth m:ap(varname)} {opt lac:tate(varname)} {opt pup:ils(varname)}
{opt g:cs(varname)} {opt mv(varname)} {opt pco2(varname)} {opt w:bc(varname)}
{opt cr:eatinine(varname)} {opt pl:t(varname)}
[{opt f:io2(varname)} {opt pao2(varname)} {opt pfr:atio(varname)}]
[{opt age(varname)} {opt dob(varname)} {opt doa(varname)}]
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Cardiovascular}
{synopt:{opt m:ap(varname)}}mean arterial pressure{p_end}
{synopt:{opt lac:tate(varname)}}lactate level (default: {bf:mg/dL}){p_end}

{syntab:Neurologic}
{synopt:{opt pup:ils(varname)}}pupil reaction (0=reactive, 1=fixed){p_end}
{synopt:{opt g:cs(varname)}}Glasgow Coma Scale score{p_end}

{syntab:Respiratory}
{synopt:{opt mv(varname)}}mechanical ventilation status (0=no, 1=yes){p_end}
{synopt:{opt pco2(varname)}}PaCO2 level (mmHg){p_end}
{p2line}
{synopt:{opt f:io2(varname)}}fraction of inspired oxygen (FiO2) (0.21 - 1.0){p_end}
{synopt:{opt pao2(varname)}}partial pressure of oxygen (PaO2) (mmHg){p_end}
{center: {hline 5}{it: or} {hline 5}}
{synopt:{opt pfr:atio(varname)}}PaO2/FiO2 ratio{p_end}
{p2line}

{syntab:Renal}
{synopt:{opt cr:eatinine(varname)}}creatinine level (default: {bf:mg/dL}){p_end}

{syntab:Hematologic}
{synopt:{opt w:bc(varname)}}white blood cell count (default: {bf:cells/mm3}){p_end}
{synopt:{opt pl:t(varname)}}platelet count (default: {bf:cells/mm3}){p_end}

{syntab:Age}
{synopt:{opt age(varname)}}{help pelod2##remarks:age category (0-5)}{p_end}
{center: {hline 5}{it: or} {hline 5}}
{synopt:{opt dob(varname)}}date of birth{p_end}
{synopt:{opt doa(varname)}}date of admission{p_end}

{syntab:Additional Options}
{synopt:{opt raw:score(newvar)}}specify variable name for the raw PELOD-2 score{p_end}
{synopt:{opt si}}use SI units for lactate and creatinine{p_end}
{synopt:{opt pltu:nit(#)}}specify platelet count unit (default: 1){p_end}
{synopt:{opt wbcu:nit(#)}}specify white blood cell count unit (default: 1){p_end}

{syntab:Debugging Options}
{synopt:{opt noimp:utation}}treat missing values as missing{p_end}
{synopt:{opt noval:idation}}skip out-of-range data checks{p_end}
{synopt:{opt tr:ace}}turn on trace for debugging{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:pelod2} calculates the Pediatric Logistic Organ Dysfunction 2 (PELOD-2) score. The scores is an outcome prognostication tools that has been used
extensively in clinical care and research to calculate the expected mortality and control for illness severity in pediatric intensive care units.{p_end}

{pstd}See {help "./pelod2##citation":Citation} for proper attribution.{p_end}

{marker options}{...}
{title:Options}

{phang}
For all required variables, if there is data missing you will receive a warning. The calculation will still be performed using normal values for the age group.{p_end}

{dlgtab:Cardiovascular}

{phang}
{opt map(varname)} specifies the name of the mean arterial pressure variable in mmHg.{p_end}

{phang}
{opt lactate(varname)} specifies the name of the lactate level variable. Default unit is mg/dL; use the {opt si} option for mmol/L.{p_end}

{dlgtab:Neurologic}

{phang}
{opt pupils(varname)} specifies the name of the pupillary reaction to light. The variables must be coded as: {bf:0} = reactive | {bf:1} = both fixed{p_end}

{phang}
{opt gcs(varname)} specifies the name of the Glasgow Coma Scale score variable.

{dlgtab:Respiratory}

{phang}
{opt mv(varname)} specifies the name of the mechanical ventilation status variable. The variable must be coded as {bf:0} = No | {bf:1} = Yes.{p_end}

{phang}
{opt pco2(varname)} specifies the name of the PaCO2 level variable in mmHg.{p_end}

{pstd}
You can specify either the PaO2/FiO2 ratio directly, or the PaO2 and FiO2 variables
separately and the ratio will be calculated.{p_end}

{phang}
{opt fio2(varname)} specifies the name of the fraction of inspired oxygen (FiO2) variable. It can be entered as 0.21-1.0 or 21-100.{p_end}

{phang}
{opt pao2(varname)} specifies the name of the partial pressure of oxygen (PaO2) variable in mmHg.

{phang}
{opt pfratio(varname)} specifies the name of the PaO2/FiO2 ratio variable.{p_end}

{dlgtab:Hematologic}

{phang}
{opt wbc(varname)} WBC variable in cells/mm3.{p_end}

{phang}
{opt plt(varname)} Platelet Count variable in cells/mm3.{p_end}

{dlgtab:Renal}

{phang}
{opt creatinine(varname)} specifies the name of the creatinine level variable. Default unit is mg/dL; use the {opt si} option for μmol/L.

{dlgtab:Age}

{pstd}
Age can be specified as either a categorical variable (0-5) or as date of birth
and admission date.

{phang}
{opt age(varname)} specifies the name of the age category variable (0-5). See {help pelod2##remarks:the remarks}

{phang}
{opt dob(varname)} specifies the name of the date of birth variable (in Stata {help datetime##s3:date format}).

{phang}
{opt doa(varname)} specifies the name of the date of admission variable (in Stata {help datetime##s3:date format}).

{dlgtab:Options}

{phang}
{opt raw:score(varname)} specifies the name of a variable to hold the raw PELOD-2 score.

{phang}
{opt noimputation} calculated score will be set to missing if any of the included variables are missing. The default is to use normal physiological values for age when values are missing.{p_end}

{phang}
{opt novalidation} specifies that out-of-range data checks should be skipped.
The default is to treat out-of-range values as missing.

{phang}
{opt wbcunit(numeric)} If not specified, it defaults to cells/mm3 - {opt wbcunit(1)}. If data is in 1000 * cells/mm3 specify {opt wbcunit(1000)}.{p_end}

{phang}
{opt pltunit(numeric)} If not specified, it defaults to cells/mm3 - {opt pltunit(1)}. If data is in 1000 * cells/mm3 specify {opt pltunit(1000)}.{p_end}

{phang}
{opt si} specifies that lactate and creatinine values are provided in SI units (mmol/L for lactate, μmol/L for creatinine). Otherwise, conventional units (mg/dL) are used.

{phang}
{opt trace} turns on trace for debugging purposes.

{marker remarks}{...}
{title:Remarks}

{pstd}
Age can be specified either as a categorical variable (0-5) or by providing the date of birth and date of admission. If both are provided, the command will use the categorical age variable. The age categories are defined as follows:

{phang2}0: 0-30 days{p_end}
{phang2}1: 31-365 days{p_end}
{phang2}2: 366-730 days{p_end}
{phang2}3: 731-1825 days{p_end}
{phang2}4: 1826-4380 days{p_end}
{phang2}5: >4380 days{p_end}

{pstd}
For the respiratory dysfunction, you can provide either the PaO2/FiO2 ratio directly or the PaO2 and FiO2 separately. If both are provided, the command will use the directly provided ratio.

{pstd}
By default, the command performs data validation and imputes missing values with normal physiological values for age. These behaviors can be modified using the {opt novalidation} and {opt noimputation} options.


{title:References}

{pstd}
[1] Leteurtre S, Duhamel A, Salleron J, Grandbastien B, Lacroix J, Leclerc F. PELOD-2. Crit Care Med. 2013;41(7):1761–73.

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
{helpb pim3}, {helpb prismscore}, {helpb pccmtoolkit}
{p_end}
