#delim ;
prog def cprdhes_patient;
version 13.0;
*
 Create dataset with 1 obs per CPRD patient
 and data on HES information about the patient.
 Add-on packages required:
 keyby
*!Author: Roger Newson
*!Date: 30 June 2016
*;

syntax using [ , CLEAR noKEY DELIMiters(passthru) ];
/*
 clear specifies that any existing dataset in memory will be cleared.
 nokey specifies that the new dataset will not be keyed by patid, spno, epikey and d_order.
 delimiters() is passed through to import delimited.
*/

*
 Input data
*;
import delimited `using', varnames(1) `delimiters' `clear';
cap lab var patid "CPRD GOLD Patient ID";
cap lab var pracid "CPRD GOLD Practice ID";
cap lab var ethnos "Patient ethnicity derived from HES records";
cap lab var gen_hesid "Generated unique identifier for patient in HES";
cap lab var n_patid_hes "Number of CPRD GOLD patients assigned the same gen_hesid";
cap lab var match_rank "Matching quality rank between HES and CPRD GOLD";
desc, fu;

*
 Label values
*;
lab def match_rank
  1 "Exact match on NHS number, date of birth, sex and post code"
  2 "Exact match on NHS number, date of birth and sex"
  3 "Exact match on NHS number, partial match on date of birth, exact match on sex and post code"
  4 "Exact match on NHS number, partial match on date of birth, exact match on sex"
  5 "Exact match on NHS number and post code"
  ;
lab val match_rank match_rank;
desc match_rank, fu;
lablist match_rank, var noun;

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
