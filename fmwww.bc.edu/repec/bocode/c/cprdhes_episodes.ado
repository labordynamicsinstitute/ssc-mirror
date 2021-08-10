#delim ;
prog def cprdhes_episodes;
version 13.0;
*
 Create dataset with 1 obs per episode of care
 and data on care episode attributes.
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
cap lab var eorder "Order of episode within spell";
cap lab var epidur "Duration of episode in days";
cap lab var epitype "Type of episode";
cap lab var admimeth "Method of admission";
cap lab var admisorc "Source of admission";
cap lab var disdest "Destination on discharge";
cap lab var dismeth "Method of discharge";
cap lab var mainspef "Speciality under which consultant is contracted";
cap lab var tretspef "Speciality under which consultant is working under period of care";
cap lab var pconsult "Consultant code (pseudonymised)";
cap lab var intmanig "Intended management";
cap lab var classpat "Patient classification";
cap lab var firstreg "First regular day or night admission?";
desc, fu;

*
 Add numeric date variables
*;
foreach X of var admidate epistart epiend discharged {;
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
  keyby patid spno epikey, fast;
};

*
 Describe dataset
*;
desc, fu;
char list;

end;
