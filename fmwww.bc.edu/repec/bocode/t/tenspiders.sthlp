{smcl}
{* *! version 1.0.0 11sep2025 Tzu-Yung Kuo; Adam C. Livori; Lachlan L. Dalli}
{title:Title}

{phang}
{bf:tenspiders} {hline 2} Stata command for measuring medication adherence using pharmaceutical claims data. It calculates adherence using the Proportion of Days Covered (PDC) method, with flexible parameters that can be customized according to 
the TEN-SPIDERS framework (Dalli et al.  Br J Clin Pharmacol. 2022;88(10):4427–4442).

{title:Syntax}

{p 8 15 2}
{cmd:tenspiders} [{cmd:using} {it:filename}] [{help if}] [{cmd:,} {it:options}]


{synoptset 32 tabbed}{...}
{synopthdr: dataset}
{synoptline}
{syntab:main dataset}
{synopt:{opt using "filename"}} Specifies the file path to the pharmaceutical claims dataset from which PDC will be calculated. This option cannot be used together with the {cmd:if} qualifier. If {cmd:using} is not specified, a claims dataset 
must already be loaded in memory before running the command. {p_end}

{syntab:condition}
{synopt:{opt if}} Optional condition to filter the dataset before calculating PDC. Note: the {cmd:if} qualifier cannot be used together with the {cmd:using} option. See examples below. {p_end}
{synoptline}

{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required Varialbes}
{synopt:{opt id(variable)}} Specifies the variable containing the patient identifier. Must be numeric. {p_end}

{synopt:{opt supply_date(date)}} Specifies the variable containing the dates of medication supply. {p_end}

{syntab:Optional Variables}

{synopt:{opt death_date(date)}} Specifies the variable containing the date of death.
This option is only required if {cmd:survival} is set to {cmd:1} or if {cmd:elig_survival} is greater than {cmd:0}. {p_end}

{synopt:{opt event_date(date)}} Specifies the event date variable (e.g. discharge date). Only required if PDC should be calculated after an event date. {cmd:numerator_start_date} should also be set to 0 to calculate PDC from the event date. 
If {cmd:numerator_start_date} is set to {cmd:1}, PDC is calculated from the first supply date following the event date. {p_end}

{synopt:{opt days_supply(variable)}} Specifies the days supplied variable. Required when {cmd:dosing} is set to {cmd:0}, and no imputation of days supplied is needed. {p_end}

{synopt:{opt drug_id(variable)}} Specifies the medication classification variable (e.g., ATC code). Required when {cmd:switching} is set to {cmd:1} or {cmd:dosing} is set to {cmd:>0}. {p_end}

{synopt:{opt drug_strength(variable)}} Specifies the medication strength variable. Required when {cmd:dosing} is set to {cmd:>0}. {p_end}


{syntab:Optional Dataset}
{synopt:{opt hospital_data}} Specifies the file path to a hospitalisation dataset (in .dta format) containing records of hospital stays during the follow-up period.{break}
The dataset must be in long format, with each row representing a unique hospitalisation, and must include the following variables: {break}
- {cmd:xadm} (admission date){break}
- {cmd:xsep} (separation/discharge date){break}
- {cmd:id} (patient identifier matching the {cmd:id} variable used in the main dataset)  {break}
This option is only required when {cmd:inhospital_supply} is set to {cmd:1} or {cmd:2}. {p_end}

{syntab:TEN-SPIDERS Parameters}

{synopt:{opt threshold}} Defines the threshold value used to classify patients as adherent (1) or non-adherent (0) based on their PDC.
Default is {cmd:0.8}. {p_end}

{synopt:{opt elig_survival}} Defines the minimum number of days a patient must survive during the observation period following the numerator start date (either the event date or first supply date, depending on settings).
A value of {cmd:0} applies no survival-based exclusion. Greater values indicate the minimum required survival time in days.  
Default is {cmd:0}. {p_end}

{synopt:{opt elig_min}} Defines the minimum number of medication supplies a patient must have during the observation period.
A value of {cmd:0} applies no supply-based exclusion. Greater values indicate the minimum required number of supplies.  
Default is {cmd:0}. {p_end}

{synopt:{opt numerator_start_date}} Defines the start date for calculating PDC.
A value of {cmd:0} indicates PDC should be calculated from the event date (specified via {cmd:event_date}).  
A value of {cmd:1} indicates PDC should be calculated from the first supply date.  
Default is {cmd:1}. {p_end}

{synopt:{opt denominator_days}} Defines the follow-up period for measuring PDC following the {cmd:numerator_start_date}, in days.
Default is {cmd:365}. {p_end}

{synopt:{opt survival}} Defines how survival should be considered in the PDC calculation.
A value of {cmd:0} indicates PDC is calculated for the entire follow-up period, regardless of whether death occurs during follow-up.  
A value of {cmd:1} indicates PDC is calculated only up to the date of death for patients who die during follow-up.  
Default is {cmd:1}. {p_end}

{synopt:{opt presupply}} Defines the look-back window (in days) prior to the event date for identifying pre-supplied medications.
Only medications with remaining supply at the {cmd:numerator_start_date} are considered available during the observation period, and are incorporated within the first supply.  
A value of {cmd:0} disables the look-back feature.  
Default is {cmd:0}. {p_end}

{synopt:{opt inhospital_supply}} Specifies how hospitalisations during the follow-up period are handled in PDC calculations.
Requires the {cmd:hospital_data} option to specify the file path to the hospitalisation dataset. 
A value of {cmd:0} indicates no adjustment for hospitalisations.  
A value of {cmd:1} indicates hospitalised days are assumed to be covered by medication (i.e., included in the numerator).  
A value of {cmd:2} indicates hospitalised days are excluded from the follow-up period (i.e., excluded from both numerator and denominator).  
Default is {cmd:0}. {p_end}

{synopt:{opt dosing}} Specifies the percentile cut-off for dose imputation.
A value of {cmd:0} indicates no imputation is performed, and a {cmd:days_supply} variable must be provided.  
A value greater than {cmd:0} (from 1 to 100) specifies the percentile used to impute the {cmd:days_supply} variable, based on the time patients typically take to return for a refill of the same medication within the same class.  
This requires the following variables: {cmd:drug_id} and {cmd:drug_strength}.  
Default is {cmd:0}. {p_end}


{synopt:{opt early_refills}} Specifies how early refills are handled in PDC calculations.
A value of {cmd:0} indicates no adjustment for early refills.  
A value of {cmd:1} indicates the numerator is extended to account for early refills.  
See {cmd:switching} below to apply additional criteria for early refill adjustments.  
Default is {cmd:1}. {p_end}

{synopt:{opt switching}} Specifies how medication switching is considered when adjusting for early refills.  
A value of {cmd:0} indicates early refill adjustments are applied regardless of medication class.  
A value of {cmd:1} restricts early refill adjustments to medications within the same class.  
This requires the variable {cmd:drug_id}.  
Default is {cmd:1}. {p_end}


{title:Description} 

{pstd}
{cmd:TENSPIDERS} Stata command for measuring medication adherence using pharmaceutical claims data. 
It calculates adherence using the Proportion of Days Covered (PDC) method, with flexible parameters that can be customized according to the TEN-SPIDERS framework (Dalli et al.  Br J Clin Pharmacol. 2022;88(10):4427–4442). 
Visit {browse "https://tenspiders.adherencelab.com/":tenspiders.adherencelab.com} or our {browse "https://github.com/TEN-SPIDERS":TEN-SPIDERS GitHub page}  for further information on the TEN-SPIDERS framework and {cmd:tenspiders} Stata command.

{title:Examples}


{pstd}
Without adjusting TEN-SPIDERS parameters:

{pstd}
{cmd:. use "medication.dta", clear}{break}
{cmd:. tenspiders, id(pnn) supply_date(spply_dt) days_supply(qty_sppld) event_date(sep_date) death_date(death_date)}

{pstd}
Adjust TEN-SPIDERS parameters:

{pstd}
{cmd:. use "medication.dta", clear}{break}
{cmd:. tenspiders, id(pnn) supply_date(spply_dt) days_supply(qty_sppld) event_date(sep_date) death_date(death_date) threshold(0.4) switching(0)}

{pstd}
When dosing >0:

{pstd}
{cmd:. use "medication.dta", clear}{break}
{cmd:. tenspiders, id(pnn) supply_date(spply_dt) event_date(sep_date) death_date(death_date) dosing(60) drug_id(atc5_code) drug_strength(itm_cd) inhospital_supply(1)}

{pstd}
Include hospital admission data:

{pstd}
{cmd:. use "medication.dta", clear}{break}
{cmd:. tenspiders, id(pnn) supply_date(spply_dt) days_supply(qty_sppld) event_date(sep_date) death_date(death_date) hospital_data("hosp_data.dta")}

{pstd}
Filter drug class for TEN-SPIDERS calculation using if condition:

{pstd}
{cmd:. use "medication.dta", clear}{break}
{cmd:. tenspiders if class == "Statin", id(pnn) supply_date(spply_dt) days_supply(qty_sppld) event_date(sep_date) death_date(death_date)}

{pstd}
Load the main drug dataset using "using" (if is not allowed):

{pstd}
{cmd:. tenspiders using "medication.dta", id(pnn) supply_date(spply_dt) days_supply(qty_sppld) event_date(sep_date) death_date(death_date)}


{title:Stored results}
{pstd}
{cmd:TENSPIDERS} saves the following files:

{synoptset 30 tabbed}{...}
{synopt:{cmd:tenspiders_settings.dta}} Settings of the TEN-SPIDERS package{p_end}
{synopt:{cmd:pdc_outcomes.dta}} Person-level PDC adherence dataset{p_end}

{pstd}
Therefore, it is important to set the working directory before running the package using:

{phang2}{cmd:cd "c:/directory"}{p_end}



{title:Author}

{pstd}
Adam C. Livori*; Tzu-Yung Kuo*; Jedidiah I. Morton; Lachlan L. Dalli{break}
{it:*Joint first authors}{break}
Monash University{break}
Email: lachlan.dalli@monash.edu{break}
Website: {browse "https://tenspiders.adherencelab.com/":tenspiders.adherencelab.com}{break}
GitHub: {browse "https://github.com/TEN-SPIDERS":github.com/TEN-SPIDERS} 

{title:References}

{phang}
Dalli, L.L., Kilkenny, M.F., Arnet, I., Sanfilippo, F.M., Cummings, D.M., Kapral, M.K., Kim, J., Cameron, J., Yap, K.Y., Greenland, M., Cadilhac, D.A. (2022). 
Towards better reporting of the proportion of days covered method in cardiovascular medication adherence: A scoping review and new tool TEN-SPIDERS. 
{it:British Journal of Clinical Pharmacology}, 88(10), 4427–4442. doi:10.1111/bcp.15391. PMID: 35524398; PMCID: PMC9546055.

{phang}
Livori, A.C., Kuo, Tzu-Yung., Ilomäki, J., Kilkenny, M.F., Talic, S., Ademi, Z., Bell, S.J., Morton, J.I., Dalli, L. (2025). 
Development of a statistical package to standardise the measurement and reporting of medication adherence using claims data: The TEN-SPIDERS tool.

{break}
