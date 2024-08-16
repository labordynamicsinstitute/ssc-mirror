Title
le8 - Life’s Essential 8 for measuring Cardiovascular Health

Syntax
le8 using data in memory
le8 [if], diet(varname numeric) diet_measure(varname numeric) physical_activity(varname numeric) physical_activity_measure(varname numeric) nicotine(varname numeric) active_smoker_athome(varname numeric) sleep(varname numeric) bmi(varname numeric) total_cholesterol(varname numeric)hdl(varname numeric) lipids_treatment(varname numeric) fpg(varname numeric) hba1c(varname numeric) diabetes(varname numeric) sbp(varname numeric) dbp(varname numeric) bp_treatment(varname numeric) replace

le8 options     		   	Description
Required
diet(varname)				Diet variable 
diet_measure(varname)			Diet measure: 1=DASH/HEI percentile; 2=MEPA score; 3= WHO's recommeded fruit & veg servings 
physical_activity(varname)    		Physical activity variable
physical_activity_measure(varname)	Physical activity measure:1=Minutes; 2=METS 
nicotine(varname)  			Nicotine exposure: 1=Never smoker; 2=Former smoker, quit ≥5 y; 3=Former smoker, quit 1–<5 y; 4=Smokeless or inhaled NDS; 5=Current smoker
active_smoker_athome(varname)  		Active smoker at home: 1=Yes; 0=No
sleep(varname) 				Average sleep hours within 24 hours 
bmi(varname) 	 			Body Mass Index (Kg/m2)
total_cholesterol(varname) 		Total Cholesterol (mg/dl)
hdl(varname) 				High density lipoprotein level (mg/dl)
lipids_treatment(varname) 		Treatment of cholesterol: 1=Yes; 0=No
fpg(varname) 				Fasting Plasma glucose (mg/dl)
hba1c(varname) 				Glycated Hemoglobin (%)
diabetes(varname) 			Diabetes status: 1=Yes; 0=No
sbp(varname) 				Systolic blood pressure (mmHg)
dbp(varname) 				Diastolic blood pressure (mmhg)
bp_treatment(varname) 			Treatment for hypertension: 1=Yes; 0=No

Optional
replace              			replaces variables created by le8 if they already exist

Description
Le8 calculates the 8 components and the overall cardiovascular health score of an individual, based on the Life’s Essential 8 of the American Heart Association (Lloyd-Jones DM et al. 2022).

Examples
Setup
. use le8.dta
Run le8 using data in memory
. le8, diet(diet) diet_measure(diet_measure) physical_activity(physical_activity) physical_activity_measure(physical_activity_measure) nicotine(nicotine) active_smoker_athome(active_smoker_athome) sleep(sleep) bmi(bmi) total_cholesterol(total_cholesterol) hdl(hdl) lipids_treatment(lipids_treatment) fpg(fpg) hba1c(hba1c) diabetes(diabetes) sbp(sbp) dbp(dbp) bp_treatment(bp_treatment) 

Rerun le8, replace existing estimates
. le8, diet(diet) diet_measure(diet_measure) physical_activity(physical_activity) physical_activity_measure(physical_activity_measure) nicotine(nicotine) active_smoker_athome(active_smoker_athome) sleep(sleep) bmi(bmi) total_cholesterol(total_cholesterol) hdl(hdl) lipids_treatment(lipids_treatment) fpg(fpg) hba1c(hba1c) diabetes(diabetes) sbp(sbp) dbp(dbp) bp_treatment(bp_treatment) replace

Run le8 for a subset of the cases using [if] option. Please note that le8 will keep the selected cases only.
. le8 if id>50, diet(diet) diet_measure(diet_measure) physical_activity(physical_activity) physical_activity_measure(physical_activity_measure) nicotine(nicotine) active_smoker_athome(active_smoker_athome) sleep(sleep) bmi(bmi) total_cholesterol(total_cholesterol) hdl(hdl) lipids_treatment(lipids_treatment) fpg(fpg) hba1c(hba1c) diabetes(diabetes) sbp(sbp) dbp(dbp) bp_treatment(bp_treatment) replace

Stored results
Le8 stores the following in r():

Scalars
le8_diet 			Life's Essential 8 - Diet 
le8_p_activity 			Life's Essential 8 - Physical Activity  
le8_nicotine 			Life's Essential 8 - Nicotine Exposure  
le8_sleep 			Life's Essential 8 - Sleep 
le8_bmi 			Life's Essential 8 - Body Mass Index 
le8_cholesterol 		Life's Essential 8 - Cholesterol  
le8_glucose 			Life's Essential 8 - Blood Glucose  
le8_bp 				Life's Essential 8 - Blood pressure    
le8_CVH      			Cardiovascular health score
le8_CVH cat			Categories of Cardiovascular health score: 1=Optimal; 2:Moderate; 3=Low; 4=Very low

References
Lloyd-Jones DM, Allen NB, Anderson CAM, Black T, Brewer LC, Foraker RE, Grandner MA, Lavretsky H, Perak AM, Sharma G, Rosamond W; American Heart Association. Life's Essential 8: Updating and Enhancing the American Heart Association's Construct of Cardiovascular Health: A Presidential Advisory From the American Heart Association. Circulation. 2022 Aug 2;146(5):e18-e43.  
see also: https://www.heart.org/en/healthy-living/healthy-lifestyle/lifes-essential-8

Citation of le8
Le8 is not an official Stata command. It is a free contribution to the research community, like a paper. Please cite it as such:

Tilahun Haregu, Marnie Downes (2024). Le8: Stata module for calculating cardiovascular health score based on the American Heart Association’s Life’s Essential 8 metrics

Authors
Tilahun Haregu and Marnie Downes
The University of Melbourne

Acknowledgments 
We would like to thank the University of Melbourne for all the support while developing le8
