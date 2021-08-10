#delim ;
prog def cprdhes_hospital;
version 13.0;
*
 Create dataset with 1 obs per hospitalisation
 and data on hospitalisation attributes.
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
import delimited `using', varnames(1) `delim' `clear';
cap lab var patid "CPRD GOLD Patient ID";
cap lab var spno "Spell number uniquely identifying a hospitalisation";
cap lab var admidate "Date of admission";
cap lab var discharged "Date of discharge";
cap lab var admimeth "Method of admission";
cap lab var admisorc "Source of admission";
cap lab var disdest "Destination on discharge";
cap lab var dismeth "Method of discharge";
cap lab var duration "Duration of hospitalisation spell in days";
cap lab var elecdate "Date of decision to admit patient";
cap lab var elecdur "Waiting time (difference in days between elecdate and admidate)";
desc, fu;

*
 Add numeric date variables
*;
foreach X of var admidate discharged elecdate {;
  gene long `X'_n=date(`X',"DMY");
  compress `X'_n;
  format `X'_n %tdCCYY/NN/DD;
};
lab var admidate_n "Date of admission";
lab var discharged_n "Date of discharge";
lab var elecdate_n "Date of decision to admit patient";

*
 Key dataset if requested
*;
if "`key'"!="nokey" {;
  keyby patid spno, fast;
};

*
 Describe dataset
*;
desc, fu;
char list;

end;
