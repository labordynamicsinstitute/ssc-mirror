#delim ;
prog def cprdhes_procedures_epi;
version 13.0;
*
 Create dataset with 1 obs per OPCS procedure per episode
 and data on OPCS procedure attributes.
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
cap lab var admidate "Date of admission";
cap lab var epistart "Date of start of episode";
cap lab var epiend "Date of end of episode";
cap lab var discharged "Date of discharge";
cap lab var opcs "OPCS 4 procedure code";
cap lab var evdate "Date of operation or procedure";
cap lab var p_order "Order of OPCS code within episode";
desc, fu;

*
 Add numeric date variables
*;
foreach X of var admidate epistart epiend discharged evdate {;
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
  keyby patid spno epikey p_order, fast;
};

*
 Describe dataset
*;
desc, fu;
char list;

end;
