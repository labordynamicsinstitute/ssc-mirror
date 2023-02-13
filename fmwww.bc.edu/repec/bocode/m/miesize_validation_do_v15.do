*Validation .do file started 15th Jan 2023 by P A Tiffin
version 15.0
discard
sysdir set PERSONAL "C:\Users\pat512\ado\personal"
sysdir set PLUS "C:\Users\pat512\ado\plus"
cd C:\Users\pat512\ado\personal\

log using "C:\Users\pat512\ado\personal\validation_v15_do_log.smcl", replace

display "$S_DATE"
display "$S_TIME"

clear all
*Setup (creating some some missing values then performing multiple imputation)
sysuse auto
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
mi register imputed price foreign
mi impute chained (regress) price (logit) foreign, add(3)
*Note; both the price and foreign variables are imputed- mpg is not

*Creating another non-imputed binary variable:

gen economic=1 if mpg>20 & mpg!=.
replace economic=0 if mpg<=20

*Estimating two sample Cohen's d and Hedges' g effect sizes on the imputed datasets 
miesize price, by(foreign)

*Estimating a two sample Glass' Delta effect size on the imputed datasets with a countdown provided during the analysis 
miesize price, by(foreign) countdown glass

*Estimating two sample Cohen's d and Hedges' g effect sizes where the grouping variable is not imputed:
miesize price, by(economic)

*Estimating two sample Cohen's d and Hedges' g effect sizes where the outcome variable is not imputed:
miesize mpg, by(foreign)


*Attempting to use miesize where neither variable is imputed:
miesize mpg, by(economic)

*****Example where only one imputation exists for both group and outcome variable
clear all 
sysuse auto
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
mi register imputed price foreign
mi impute chained (regress) price (logit) foreign, add(1)
miesize price, by(foreign)
miesize price, by(foreign) countdown
miesize price, by(foreign) glass
miesize price, by(foreign) glass countdown

*****Example where only one imputation exists for the group variable the outcome variable is not imputed 
clear all
sysuse auto
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
mi register imputed foreign
mi impute chained (logit) foreign, add(1)
miesize price, by(foreign)
miesize price, by(foreign) countdown
miesize price, by(foreign) glass
miesize price, by(foreign) glass countdown

*****Example where only one imputation exists for the outcome variable the group variable is not imputed 
clear all
sysuse auto
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
mi register imputed price
mi impute chained (regress) price, add(1)
miesize price, by(foreign)
miesize price, by(foreign) countdown
miesize price, by(foreign) glass
miesize price, by(foreign) glass countdown



*****Example where no variables are imputed *********************************************************** 
clear all
sysuse auto
gen economic=1 if mpg>20 & mpg!=.
replace economic=0 if mpg<=20
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
mi register imputed foreign
mi impute chained (logit) foreign, add(1)
miesize mpg, by(economic)
miesize mpg, by(economic) countdown
miesize mpg, by(economic) glass
miesize mpg, by(economic) glass countdown

*****Example where there is an attempt to use a string variable as the group variable *********************************************************** 

clear all
sysuse auto
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
mi register imputed foreign
mi impute chained (logit) foreign, add(3)
miesize mpg, by(make)
miesize mpg, by(make) countdown
miesize mpg, by(make) glass
miesize mpg, by(make) glass countdown

*****Example where there is an attempt to use a string variable as the outcome variable *********************************************************** 

clear all
sysuse auto
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
mi register imputed foreign
mi impute chained (logit) foreign, add(3)
miesize make, by(foreign)
miesize make, by(foreign) countdown
miesize make, by(foreign) glass
miesize make, by(foreign) glass countdown



*****Example where there is an attempt to use two string variables as the outcome variable *********************************************************** 

clear all
sysuse auto
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
gen brand=make
replace brand="ford" if _n==1

mi register imputed foreign
mi impute chained (logit) foreign, add(3)
miesize make, by(foreign)
miesize make, by(foreign) countdown
miesize make, by(foreign) glass
miesize make, by(foreign) glass countdown





******Example where the grouping variable has only one category*******************************************************************************



clear all
sysuse auto
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
mi register imputed foreign
mi impute chained (logit) foreign, add(3)
*Create variable with one category
gen group=1
miesize price, by(group)



*******************Example where the grouping variable has three categories***********************************************************************************************************************************************************
clear all
sysuse auto
mi set wide
replace price=. if make=="Dodge Colt" | make=="Toyota Celica"
replace foreign=. if _n==11 | _n==3
mi register imputed foreign
mi impute chained (logit) foreign, add(3)
*Create variable with three categories
gen mpg_level=1 if mpg<20
replace mpg_level=2 if mpg>20
replace mpg_level=3 if mpg>28
miesize price, by(mpg_level)
