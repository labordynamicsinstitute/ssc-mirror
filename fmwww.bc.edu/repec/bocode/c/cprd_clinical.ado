#delim ;
prog def cprd_clinical;
version 13.0;
*
 Create dataset clinical with 1 obs per clinical event.
 Add-on packages required:
 lablist
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
cap lab var patid "Patient Identifier";
cap lab var eventdate "Event Date";
cap lab var sysdate "System Date";
cap lab var constype "Consultation Type";
cap lab var consid "Consultation Identifier";
cap lab var medcode "Medical Code";
cap lab var staffid "Staff Identifier";
cap lab var textid "Text Identifier";
cap lab var episode "Episode";
cap lab var enttype "Entity Type";
cap lab var adid "Additional Details Identifier";

*
 Label values
*;
if `"`dofile'"'!="" {;
  run `"`dofile'"';
  lab val constype sed;
  lab val episode epi;
  foreach X of var constype episode {;
    desc `X', fu;
    lablist `X', var;
  };
};

*
 Create date variables
*;
foreach X of var eventdate sysdate {;
  gene long `X'_n=date(`X',"DMY");
  compress `X'_n;
  format `X'_n %tdCCYY/NN/DD;
};
lab var eventdate_n "Event date";
lab var sysdate_n "Event system entry date";

desc, fu;

end;
