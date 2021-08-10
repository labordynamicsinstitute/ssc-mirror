#delim ;
prog def cprd_immunisation;
version 13.0;
*
 Create dataset immunisation with 1 obs per immunisation.
 Add-on packages required:
 lablist
*!Author: Roger Newson
*!Date: 21 March 2016
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
cap lab var immstype "Type";
cap lab var stage "Stage";
cap lab var status "Status";
cap lab var compound "Compound";
cap lab var source "Source";
cap lab var reason "Reason";
cap lab var method "Method";
cap lab var batch "Batch";
foreach X of var patid consid {;
  assert !missing(`X');
  assert `X'==int(`X');
};

*
 Label values
*;
if `"`dofile'"'!="" {;
  run `"`dofile'"';
  lab val constype sed;
  lab val immstype imt;
  lab val stage ist;
  lab val status imm;
  lab val compound imc;
  lab val source inp;
  lab val reason rin;
  lab val method ime;
  foreach X of var constype immstype stage status compound source reason method {;
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
  assert `X'_n==int(`X'_n);  
};
lab var eventdate_n "Event date";
lab var sysdate_n "Event system entry date";

desc, fu;

end;
