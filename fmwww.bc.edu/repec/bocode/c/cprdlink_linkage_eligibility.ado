#delim ;
prog def cprdlink_linkage_eligibility;
version 13.0;
*
 Create dataset with 1 obs per CPRD patient
 and data on eligibility for linkage with other datasets.
 Add-on packages required:
 keyby
*!Author: Roger Newson
*!Date: 19 June 2017
*;

syntax using [ , CLEAR noKEY ];
/*
 clear specifies that any existing dataset in memory will be cleared.
 nokey specifies that the new dataset will not be keyed by patid.
*/

*
 Input data
*;
import delimited `using', varnames(1) delim(tab) `clear';
cap lab var patid "CPRD GOLD Patient ID";
cap lab var pracid "CPRD GOLD Practice ID";
cap lab var linkdate "Patient Linkage Date";
cap lab var hes_e "Eligibility for linkage to HES data";
cap lab var death_e "Eligibility for linkage to ONS Death data";
cap lab var cr_e "Eligibility for linkage to Cancer Registry";
cap lab var minap_e "Eligibility for linkage to MINAP Registry";
cap lab var lsoa_e "Eligibility for linkage to patient-level LSOA data";
cap lab var mh_e "Eligibility for linkage to Mental Health data";
cap lab var referralevents "Referral Events";
desc, fu;

*
 Add numeric date variables
*;
foreach X of var linkdate {;
  gene long `X'_n=date(`X',"DMY");
  compress `X'_n;
  format `X'_n %tdCCYY/NN/DD;
};
lab var linkdate_n "Patient linkage date";

*
 Key dataset if requested
*;
if "`key'"!="nokey" {;
  keyby patid, fast;
};

*
 Describe dataset
*;
desc, fu;
char list;

end;
