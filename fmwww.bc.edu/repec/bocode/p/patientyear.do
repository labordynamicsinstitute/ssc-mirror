#delim ;
version 13.0;
*
 Create dataset with 1 obs per patient-year
*;

*
 Create patient dataset
*;
use ./dta/patient.dta, clear;
desc, fu;

*
 Keep only patients acceptable and observed
*;
tab accept observed, m;
keep if accept==1 & observed==1;

*
 Compute years of entry and exit
*;
gene long entryyear=year(entrydate);
gene long exityear=year(exitdate);
compress entryyear exityear;
lab var entryyear "Year of entry to CPRD observation";
lab var exityear "Year of exit from CPRD observation";
desc entryyear exityear, fu;
tab entryyear, m;
tab exityear, m;
assert entryyear<=exityear;

*
 Expand dataset to have 1 obs per patient per calendar year
*;
keep patid ebdate_n entrydate exitdate entryyear exityear;
expgen =exityear-entryyear+1,copyseq(calyear) sortedby(unique);
replace calyear=entryyear+calyear-1;
compress calyear;
lab var calyear "Calendar year";
* Exposure time *;
gene long fexpday=cond(calyear==entryyear,entrydate,mdy(01,01,calyear));
gene long lexpday=cond(calyear==exityear,exitdate,mdy(12,31,calyear));
compress fexpday lexpday;
lab var fexpday "First exposure day this year";
lab var lexpday "Last exposure day this year";
gene long exposure=lexpday-fexpday+1;
compress exposure;
lab var exposure "Exposure time in calendar year (days)";
* Age attained *;
gene long ageattained=calyear-year(ebdate_n);
compress ageattained;
lab var ageattained "Age attained in calendar year";
* Drop unnecessary variables and key dataset *;
keep patid calyear exposure ageattained;
keyby patid calyear, fast;
* Describe and summarize dataset *;
desc, fu;
tab calyear, m plot;
tab ageattained, m plot;
summ exposure, de;

*
 Save dataset
*;
save ./dta/patientyear.dta, replace;

exit;
