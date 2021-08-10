#delim ;
prog def cprd_consultation;
version 13.1;
*
 Create dataset consultation with 1 obs per consultation.
 Add-on packages required:
 keyby, lablist
*!Author: Roger Newson
*!Date: 22 March 2016
*;

syntax using [ , CLEAR DOfile(string) ];

*
 Input data
*;
import delimited `using', varnames(1) `clear';
desc, fu;
char list;
* Label variables *;
cap lab var patid "Patient Identifier";
cap lab var eventdate "Event Date";
cap lab var sysdate "System Date";
cap lab var constype "Consultation Type";
cap lab var consid "Consultation Identifier";
cap lab var staffid "Staff Identifier";
cap lab var duration "Duration";
keyby patid consid, fast;
* Label values *;
if `"`dofile'"'!="" {;
  run `"`dofile'"';
  lab val constype cot;
  desc constype, fu;
  lablist constype, var;
};
* Create date variables *;
foreach X of var eventdate sysdate {;
  gene long `X'_n=date(`X',"DMY");
  compress `X'_n;
  format `X'_n %tdCCYY/NN/DD;
};
lab var eventdate_n "Event date";
lab var sysdate_n "Event system entry date";

desc, fu;

end;
