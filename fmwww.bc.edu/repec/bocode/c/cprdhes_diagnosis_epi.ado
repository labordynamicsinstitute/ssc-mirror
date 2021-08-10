#delim ;
prog def cprdhes_diagnosis_epi;
version 13.0;
*
 Create dataset with 1 obs per diagnosis per episode of care
 and data on diagnosis attributes.
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
cap lab var spno "Spell number uniquely identifying a hospitalisation";
cap lab var epikey "Episode key uniquely identifying an episode of care";
cap lab var epistart "Date of start of episode";
cap lab var epiend "Date of end of episode";
cap lab var icd "ICD10 diagnosis code";
cap lab var icdx "5th/6th characters of the ICD code (if available)";
cap lab var d_order "Ordering of diagnosis code in episode";
desc, fu;

*
 Add numeric date variables
*;
foreach X of var epistart epiend {;
  local Xlab: var lab `X';
  gene long `X'_n=date(`X',"DMY");
  compress `X'_n;
  format `X'_n %tdCCYY/NN/DD;
  lab var `X'_n "`Xlab'";
};

*
 Key dataset if requested
*;
if "`key'"!="nokey" {;
  keyby patid spno epikey d_order, fast;
};

*
 Describe dataset
*;
desc, fu;
char list;

end;
