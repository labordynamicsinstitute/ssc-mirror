{smcl}
{* *! version 1.2.1 1 Mar 2023}{...}
{viewerdialog "prismscore" "dialog prismscore"}{...}
{viewerjumpto "Syntax" "./prismscore##syntax"}{...}
{viewerjumpto "Syntax Details" "./prismscore##syntaxd"}{...}
{viewerjumpto "Description" "./prismscore##description"}{...}
{viewerjumpto "Options" "./prismscore##options"}{...}
{viewerjumpto "Remarks" "./prismscore##remarks"}{...}
{viewerjumpto "Custom Implementations" "./prismscore##custom"}{...}
{viewerjumpto "Citation" "./prismscore##citation"}{...}
{viewerjumpto "License" "./prismscore##citation"}{...}
{viewerjumpto "Variable Coding Reference" "./prismscore##variable"}{...}
{title:Title}

{phang}
{bf:PRISM Score} {hline 2} a command to calculate the PRISM III and PRISM IV scores

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:prismscore}
{help prismscore##new_varlist:new_varlist}
{ifin}
{cmd:,}
{help prismscore##p3v:{it:prismIII_varlist}} [{bf:prism4} {help prismscore##p4v:{it:prismIV_varlist}}] [{it:unit_options}] [{it:debugging_options}]

{marker syntaxd}{...}
{title:Syntax Details}

{synoptset 20 tabbed}{...}
{marker new_varlist}{...}
{syntab:{bf:New Variables}}

{phang} The new variables will contain the calculated scores. Depending on the scenario, you will need to specify either 1, 3, or 4 options.{p_end}

{synopthdr: Scenarios}
{synoptline}
{syntab:PRISM III}
{synopt:3 variables} new variables must follow this order: neurologic_score nonneurologic_score total_score{p_end}
{syntab:PRISM IV}
{synopt:1 variable} new variable will contain {ul:{bf:only}} the PRISM IV score.{p_end}
{synopt:4 variables} new variables must follow this order: neurologic_score nonneurologic_score total_score prism4_score{p_end}
{p2colreset}{...}
{synoptline}

{synoptset 20 tabbed}{...}
{syntab:{bf:Variable Lists}}

{synopt: {help prismscore##p3v:{it:PRISM III Variable List}}} See Below {p_end}
{synopt: {help prismscore##p4v:{it:PRISM IV Variable List}}}See Below{p_end}
{syntab:{bf:Options}}

{synopthdr}
{synoptline}{marker p3v}{...}
{syntab:{bf:PRISM III} (required)}

{synopt:Age - Must specify either {opt age} or both {opt dob} and {opt doa}} {p_end}
{p2line}
{synopt:{opt age(varname)}} age variable. Requires special coding.{p_end}
{synopt:{opt dob(varname)}} date of birth variable {p_end}
{synopt:{opt doa(varname)}} date of admission variable {p_end}

{synopt:Temperature} {p_end}
{p2line}
{synopt:{opt temp(varname)}} temperature variable. If {opt templow} is used, then {opt temp} designates the high temperature variable{p_end}
{synoptset 20 notes}{...}

{synopt: {it:Optional}} {p_end}
{p2line}
{synopt:{opt templ:ow(varname)}} temperature variable. If {opt templow} is used, then {opt temp} designates the high temperature variable{p_end}
{synoptset 20 tabbed}{...}

{synopt:Additional Vitals} {p_end}
{p2line}
{synopt:{opt sbp(varname)}} systolic blood pressure variable. {p_end}
{synopt:{opt hr(varname)}} heart rate variable. {p_end}
{synopt:{opt gcs(varname)}} Glasgow Coma Score variable. {p_end}
{synopt:{opt pup:ils(varname)}} number of pupils > 3mm and fixed. {p_end}

{synopt:Acid-Base Status} {p_end}
{p2line}
{synopt:{opt ph(varname)}} pH variable; if {opt phhigh} is used, then {opt ph} designates the low pH variable. {p_end}
{synopt:{opt bicarb(varname)}} designates the bicarbonate variable. if {opt bicarbhigh} is used, then it designates the low bicarbonate variable {p_end}
{synopt:{opt pc:o2(varname)}} PCO2 variable. {p_end}
{synopt:{opt pa:o2(varname)}} PaO2 variable. {p_end}

{synoptset 20 notes}{...}
{synopt: {it:Optional}} {p_end}
{p2line}
{synopt:{opt phh:igh(varname)}} pH variable; if {opt phhigh} is used, then {opt ph} designates the low pH variable. {p_end}
{synopt:{opt bicarbh:igh(varname)}} designates the bicarbonate variable. if {opt bicarbhigh} is used, then it designates the low bicarbonate variable {p_end}

{synoptset 20 tabbed}{...}
{synopt:Laboratory Values} {p_end}
{p2line}
{synopt:{opt glu:cose(varname)}} glucose variable in mg/dL. {p_end}
{synopt:{opt pot:assium(varname)}} potassium variable in mmol/L. {p_end}
{synopt:{opt cr:eatinine(varname)}} creatinine variable in mg/dL. {p_end}
{synopt:{opt bun(varname)}} BUN variable in mg/dL. {p_end}
{synopt:{opt wbc(varname)}} WBC variable in cells/mm3. {p_end}
{synopt:{opt plt(varname)}} Platelet Count variable in cells/mm3. {p_end}
{p2line}
{marker p4v}
{syntab:{bf:PRISM IV} (optional)}

{synopt:{opt prism:iv}} calculates the PRISM IV % mortality.{p_end}

{synoptset 20 notes}{...}
{synopt: {it:Required}} {p_end}
{p2line}
{synopt:{opt sou:rce(varname)}} admission source. Requires special coding. {p_end}
{synopt:{opt cpr(varname)}} CPR status. {p_end}
{synopt:{opt can:cer(varname)}} cancer status.{p_end}
{synopt:{opt risk(varname)}} low-risk system of primary dysfunction status. {p_end}
{p2line}

{syntab:{bf:Additional Options}}
{synoptline}
{synoptset 20 tabbed}{...}
{syntab:Unit Options}
{synopt:{opt si}} will calculate scores based on SI Lab values. {p_end}
{synopt:{opt pltu:nit(integer)}} allows specifying a different platelet count unit.{p_end}
{synopt:{opt wbcu:nit(integer)}} allows specifying a different WBC unit.{p_end}
{synopt:{opt FAHR:enheit}} allows specifying a different temperature unit.{p_end}

{syntab:Debugging Options}
{synopt:{opt trace}} enables the trace option for the command. Useful in case of unexpected errors. {p_end}
{synopt:{opt supp:ress}} suppresses warnings regarding data imputation. {p_end}
{synopt:{opt suppressa:ll}} suppress all errors and data validation functions. {p_end}
{synopt:{opt noimp:utation}} shows missing score if any variables are missing. {p_end}
{synopt:{opt noval:idation}} supresses out-of-range data checks. If this is not specified, values that are out-of-range will be considered missing. {p_end}
{synoptline}

{synoptset 20 tabbed}{...}
{syntab:{bf:PRISM III Variable List}}

{synopthdr}
{synoptline}{marker p3v}{...}
{syntab:Age - Must specify either {opt age} or both {opt dob} and {opt doa}}
{synopt:{opt age(varname)}} age variable. Requires special coding.{p_end}
{synopt:{opt dob(varname)}} date of birth variable {p_end}
{synopt:{opt doa(varname)}} date of admission variable {p_end}

{syntab:Temperature}
{synopt:{opt temp(varname)}} temperature variable. If {opt templow} is used, then {opt temp} designates the high temperature variable{p_end}

{synopt: {it:Optional}} {p_end}
{synopt:{opt templ:ow(varname)}} temperature variable. If {opt templow} is used, then {opt temp} designates the high temperature variable{p_end}

{syntab:Additional Vitals}
{synopt:{opt sbp(varname)}} systolic blood pressure variable. {p_end}
{synopt:{opt hr(varname)}} heart rate variable. {p_end}
{synopt:{opt gcs(varname)}} Glasgow Coma Score variable. {p_end}
{synopt:{opt pup:ils(varname)}} number of pupils > 3mm and fixed. {p_end}

{syntab:Acid-Base Status}
{synopt:{opt ph(varname)}} pH variable; if {opt phhigh} is used, then {opt ph} designates the low pH variable. {p_end}
{synopt:{opt bicarb(varname)}} designates the bicarbonate variable; if {opt bicarbhigh} is used, then it designates the low bicarbonate variable {p_end}
{synopt:{opt pc:o2(varname)}} PCO2 variable. {p_end}
{synopt:{opt pa:o2(varname)}} PaO2 variable. {p_end}

{synopt: {it:Optional}} {p_end}
{synopt:{opt phh:igh(varname)}} pH variable; if {opt phhigh} is used, then {opt ph} designates the low pH variable. {p_end}
{synopt:{opt bicarbh:igh(varname)}} designates the bicarbonate variable. if {opt bicarbhigh} is used, then it designates the low bicarbonate variable {p_end}

{synoptset 20 tabbed}{...}
{syntab:Laboratory Values}
{synopt:{opt glu:cose(varname)}} glucose variable in mg/dL. {p_end}
{synopt:{opt pot:assium(varname)}} potassium variable in mmol/L. {p_end}
{synopt:{opt cr:eatinine(varname)}} creatinine variable in mg/dL. {p_end}
{synopt:{opt bun(varname)}} BUN variable in mg/dL. {p_end}
{synopt:{opt wbc(varname)}} WBC variable in cells/mm3. {p_end}
{synopt:{opt plt(varname)}} Platelet Count variable in cells/mm3. {p_end}
{synoptline}
{marker p4v}
{syntab:{bf:PRISM IV Variable List}}

{synopthdr}
{synoptline}
{synopt:{opt sou:rce(varname)}} admission source. Requires special coding. {p_end}
{synopt:{opt cpr(varname)}} CPR status. {p_end}
{synopt:{opt can:cer(varname)}} cancer status.{p_end}
{synopt:{opt risk(varname)}} low-risk system of primary dysfunction status. {p_end}
{synoptline}

{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
{cmd:prismscore} calculates PRISM III and PRISM IV scores. The scores are outcome prognostication tools that have been used
extensively in clinical care and research to calculate the expected mortality and control for illness severity in pediatric intensive care units.{p_end}

{pstd}See {help "./prismscore##citation":Citation} for proper attribution.{p_end}

{marker options}{...}
{title:Options}

{phang}
For all required variables, if there is data missing you will receive a warning. The calculation will still be performed using normal values for the age group. See options  {opt suppress} and {opt suppressall} for more information.{p_end}

{dlgtab:Main}

{phang}
{opt prismiv} will calculate a percentage mortality based on the PRISM IV score. This will require specifying {opt admitsource(varname)}, {opt cancer(varname)}, {opt cpr(varname)}, and {opt risk(varname)}.{p_end}

{dlgtab:PRISM III}

{phang}
{opt age}(varname numeric) designates the age variable. Age must be coded as:
{bf:0} = (<- - 14 days] | {bf:1} = (14 days - 1 month) | {bf:2} = [1 month - 12 months) | {bf:3} = [12 months - 12 years) | {bf:4} = [12 years ->). Alternatively use {opt dob} and {opt doa} for automatic calculations of age.
This is recommended if the age is not already appropriately coded.{p_end}

{phang}
{opt dob}(varname {help datetime:date}) designates the date of birth variable. Date of birth must be in {help datetime_display_formats:%td} format.{p_end}

{phang}
{opt doa}(varname {help datetime:date}) designates the date of admission variable. Date of admission must be in {help datetime_display_formats:%td} format.{p_end}

{p2line 5 5}

{phang}
{opt sbp(varname numeric)} designates the systolic blood pressure variable.{p_end}

{phang}
{opt hr(varname numeric)} designates the heart rate variable.{p_end}

{phang}
{opt gcs(varname integer)} designates the Glascow Coma Score variable.{p_end}

{phang}
{opt pupils(varname integer)} designates the variable containing the number of pupils >3mm and fixed.{p_end}

{phang}
{opt temp(varname numeric)} designates the temperature variable. If there is only one temperature recorded, the command will use the recorded temperature for both high and low temperature calculations. If both a high and a low
temperature value are recorded, specify {opt templow}.{p_end}

{phang}
{opt templow(varname numeric)} designates the low temperature variable. If both {opt temp} and {opt templow} are specified, the command will compare the values and will use the highest value for high temperature calculations and the lowest value for the low temperature calculations.{p_end}

{p2line 5 5}

{phang}
{opt ph(varname numeric)} designates the ph variable. If there is only one pH recorded, the command will use the recorded pH for
both high and low pH calculations. If both a high and a low pH value are recorded, specify {opt phhigh}.{p_end}

{phang}
{opt phhigh(varname numeric)} designates the high ph variable. If both {opt ph} and {opt phhigh} are specified, the command will compare the values and will use the highest value for high ph calculations
and the lowest value for the low ph calculations.{p_end}

{phang}
{opt bicarb(varname numeric)} designates the HCO3-/CO2 variable. If there is only one bicarbonate value recorded, the command will use the recorded bicarbonate values for both high and low bicarbonate calculations.
If both a high and a low bicarbonate value are recorded, specify {opt bicarbhigh}.{p_end}

{phang}
{opt bicarbhigh(varname numeric)} designates the high HCO3-/CO2 variable. If both {opt bicarb} and {opt bicarbhigh} are specified, the command will compare the values and will use the highest
value for high bicarbonate calculations and the lowest value for the low bicarbonate calculations.{p_end}

{phang}
{opt pco2(varname numeric)} designates the PCO2 variable; not to be confused with the bicarb variable.{p_end}

{phang}
{opt po2(varname numeric)} designates the PO2 variable.{p_end}

{p2line 5 5}

{phang}
{opt glucose(varname)} glucose variable in mg/dL.{p_end}

{phang}
{opt potassium(varname)} potassium variable in mEq/L or mmol/L. The units are identical.{p_end}

{phang}
{opt creatinine(varname)} creatinine variable in mg/dL.{p_end}

{phang}
{opt bun(varname)} BUN variable in mg/dL.{p_end}

{phang}
{opt wbc(varname)} WBC variable in cells/mm3.{p_end}

{phang}
{opt plt(varname)} Platelet Count variable in cells/mm3.{p_end}

{dlgtab:PRISM IV}

{phang}
{opt source(varname)} Admission Source variable. Source must be coded as: {bf:0} = Operating Room or PACU | {bf:1} = Another Hospital| {bf:2} = Inpatient Unit| {bf:3} = Emergency Department.{p_end}

{phang}
{opt cpr(varname)} CPR in the last 24h variable. CPR must be coded as: {bf:0} = No | {bf:1} = Yes.{p_end}

{phang}
{opt cancer(varname)} Acute or Chronic Cancer variable. Cancer must be coded as: {bf:0} = No | {bf:1} = Yes.{p_end}

{phang}
{opt risk(varname)} Low-risk systems of primary dysfunction variable. Risk must be coded as: {bf:0} = No | {bf:1} = Yes. Endocrine, hematologic, musculoskeletal, and renal systems are defined as low risk.{p_end}

{dlgtab:Unit Options}

{phang}
{opt wbcunit(numeric)} If not specified, it defaults to cells/mm3 - {opt wbcunit(1)}. If data is in 1000 * cells/mm3 specify {opt wbcunit(1000)}.{p_end}

{phang}
{opt pltunit(numeric)} If not specified, it defaults to cells/mm3 - {opt pltunit(1)}. If data is in 1000 * cells/mm3 specify {opt pltunit(1000)}.{p_end}

{phang}
{opt si} If specified, it assumes glucose is recorded as mmol/L, creatinine is recorded as umol/L and BUN is recorded as mmol/L. Otherwise it assumes glucose, creatinine and BUN are recorded as mg/dL.{p_end}

{phang}
{opt fahrenheit} If specified, it assumes glucose is recorded in Fahrenheit. If not specified, Celsius is assumed.{p_end}

{dlgtab:Useful}

{phang}
{opt trace} enables trace{p_end}

{phang}
{opt suppress} suppresses warnings about calculation with missing values{p_end}

{phang}
{opt suppressall} suppresses all warnings and data checks{p_end}

{phang}
{opt noimputation} calculated score will be set to missing if any of the included variables are missing{p_end}

{phang}
{opt novalidation} if this option is {ul:NOT} specified, variables that are out of range (incompatible with known physiology) will be set to missing.{p_end}

{synoptline}

	Physiologic Variable{col 35} Acceptable Ranges
	{col 35} {it:(min) - (max)}
	{hline 45}
	Systolic BP{col 35}0{col 40} -{col 45}300
	Heart Rate{col 35}0{col 40} -{col 45}350
	Temperature - C{col 35}25{col 40} -{col 45}45
	Temperature - F{col 35}77{col 40} -{col 45}113
	pH{col 35}6.5{col 40} -{col 45}7.9
	Bicarbonate{col 35}0.1{col 40} -{col 45}60
	PCO2{col 35}1{col 40} -{col 45}200
	PaO2{col 35}1 {col 40} -{col 45}600
	Glucose - mg/dL{col 35}5 {col 40} -{col 45}999
	Glucose - mmol/L{col 35}0.2 {col 40} -{col 45}55.45
	Creatinine - mg/dL{col 35}0.01 {col 40} -{col 45}15
	Creatinine - mmol/L{col 35}0.8 {col 40} -{col 45}1350
	BUN - mg/dL{col 35}1 {col 40} -{col 45}150
	BUN - mmol/L{col 35}0.3 {col 40} -{col 45}53.6
	Potassium{col 35}1 {col 40} -{col 45}10
	GCS{col 35}3 {col 40} -{col 45}15

{marker variable}{...}
{title:Variable Coding Reference}

	Variable{col 30}Value{col 45}Reference
	{hline 60}
	Age{col 30}0{col 45}<= 14 days
	{col 30}1{col 45}>  14 days & <= 1 month
	{col 30}2{col 45}>  1 month & <= 1 year
	{col 30}3{col 45}>  1 year & < 12 years
	{col 30}4{col 45}>= 12 years

	Source{col 30}0{col 45}Operating Room or PACU
	{col 30}1{col 45}Another Hospital
	{col 30}2{col 45}Inpatient Unit
	{col 30}3{col 45}Emergency Department

	CPR{col 30}0{col 45}No
	{col 30}1{col 45}Yes

	Cancer{col 30}0{col 45}No
	{col 30}1{col 45}Yes

	Risk(Low-Risk){col 30}0{col 45}No
	{col 30}1{col 45}Yes
	{hline 60}
	Note: 1 month - 30 days; 1 year - 365 days

{marker custom}{...}
{title:Custom Implementations}

{pstd}
Some groups have modified the coefficients attributed to each of the variables in the PRISM IV score calculation. The coefficients used in this command are the ones reported in Pollack 2016. If you wish to change them, you have to modify the
prismscore.ado file.
I am not offering a command-based option to prevent inadvertent changes by inexperienced users. If you are having issues with this, please email me and I'm happy to help. {p_end}

{pstd}
{it:Instructions}{break}Open the prism.ado file. Locate the section containing the PRISM IV coefficients (line 292); alternatively search for {hi:CHANGE THIS}. Modify the coefficients as needed and reload the program.
The following commands should be helpful:

{phang}
1. {stata doedit prismscore.ado}

{phang}
2. Make edits and save.

{phang}
3. {stata program drop prismscore}

{phang}
4. {stata do prismscore.ado}


{title:References}
{pstd}

{pstd}
[1] Pollack MM, Patel KM, Ruttimann UE. PRISM III: an updated Pediatric Risk of Mortality score. Crit Care Med. 1996;24(5):743-52. {break}[2] Pollack MM, Holubkov R, Funai T, Dean JM, Berger JT, Wessel DL, et al. The Pediatric Risk of Mortality Score: Update 2015. Pediatr Crit Care Med. 2016;17(1):2-9.

{pstd}

{pstd}

{marker citation}{...}
{title:Citation}

{pstd}
Please cite this command as:

{pstd}
Azamfirei, Razvan; Mennie, Colleen; Fackler, James; Kudchadkar, Sapna R. Development of a Stata Command for Pediatric Risk of Mortality Calculation. Pediatric Critical Care Medicine 24(3):p e162-e163, March 2023. | DOI: {browse "https://doi.org/10.1097/PCC.0000000000003149":10.1097/PCC.0000000000003149}

{title:Author}
{p}

Razvan Azamfirei
Email: {browse "mailto:stata@azamfirei.com":stata@azamfirei.com}

{marker License}{...}
{title:License}
{p}{hi:Copyright 2022 Razvan Azamfirei}

{pstd}Licensed under the Apache License, Version 2.0 (the"License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at: {p_end}

{pstd}{browse "https://www.apache.org/licenses/LICENSE-2.0":http://www.apache.org/licenses/LICENSE-2.0}{p_end}

{pstd}Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.{p_end}
{pstd} See the License for the specific language governing permissions and limitations under the License. {p_end}
