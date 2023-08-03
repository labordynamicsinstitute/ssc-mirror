***
*** GSS illustration of mscologit.ado
*** Pooled analysis that combines rating data from split-sample experiment
***
*** Source: 
*** GSS 1984, dependent variable: respondents' trust in Congress, 
*** outcome data collected in two variables conlegis and conlegiy
***
*** Note:
*** This exercise is meant to illustrate the principal idea of the mscologit model 
*** as well as the use of the ado in conjunction with publicly available data. The
*** substantive results are non-impressive, because it is quite obvious how to
*** usefully reconcile the conlegis and conlegiy response categories just from
*** inspecting the frequency table. In this particular case, manual harmonization
*** (= model 3) is giving virtually the same results as the mscologit model (= 
*** models 4 and 5), but the latter does not require any researcher commitment to
*** some particular data harmonization protocol. Instead, the mscologit model just
*** reflects all cutpoints on all alternative scale formats as present in the raw data
*** and estimates a common model for the substantive covariates on the pooled data.
***
*** A more wide-ranging and more complex example that involves data pooling in the
*** context of cross-nationally comparative research is described in the accompanying
*** full article, see
***
*** Markus Gangl (2023). A Generalized Ordered Logit Model to Accommodate Multiple 
*** Rating Scales. Sociological Methods & Research.
*** https://www.doi.org/10.1177/00491241231186655
***
*** The full article contains a separate replication package, including a description
*** of how to obtain the survey data used in the cross-country illustration of the 
*** mscologit model.
***


***
*** This illustration uses the public GSS 1984 data file available from:
*** https://gss.norc.org/documents/stata/1984_stata.zip
***
*** In case the above link has turned non-functional, please check the GSS main page
*** https://gss.norc.org/get-the-data/stata
*** https://gss.norc.org
*** for data access to either the 1984 or the cumulated GSS data file(s)
***

clear all
use GSS1984.dta

*** examine the two versions of the trust in congress question
desc conleg*
tab conlegis
tab conlegiy

*** reverse scale for analysis (top category = highest degree of trust)
gen rconleg = 4-conlegis if conlegis>=1 & conlegis<=3
gen rconlegy = 8-conlegiy if conlegiy>=1 & conlegiy<=7
*** recode 7-point conlegiy to standard 3-point conlegis item
recode rconlegy 1/2=1 3/5=2 6/7=3, gen(jconleg)
replace jconleg = rconleg if rconlegy==. & rconleg<.

*** independent variables will be sex, educ, and age
*** dummy and polynomial terms defined explicitly here
gen female = sex==2 if sex<.
gen agesq = age^2

*** model estimation
*** 1) ologit, dependent variable: conlegis (standard GSS item)
ologit rconleg female educ age agesq
est sto m1
*** 2) ologit, dependent variable: conlegiy (7-point Likert scale)
ologit rconlegy female educ age agesq
est sto m2
*** 3) ologit, dependent variable: jconleg (conlegiy recoded to conlegis)
ologit jconleg female educ age agesq
est sto m3
*** 4) mscologit, pooled estimates using both response formats combined 
***   (full ML estimates)
mscologit rconleg rconlegy, indvar(female educ age agesq)
est sto m4
*** 5) mscologit, pooled estimates using both response formats combined 
***   (alternative ML estimates, 
***    obtained from estimating binary logit model on expanded dataset)
mscologit rconleg rconlegy, indvar(female educ age agesq) logit acc
est sto m5

*** model comparison / regression output
est table m1 m2 m3 m4 m5, equations(1) stats(ll aic N) b se p 
 