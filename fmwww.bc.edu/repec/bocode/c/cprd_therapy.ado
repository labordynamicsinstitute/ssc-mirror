#delim ;
prog def cprd_therapy;
version 13.0;
*
 Create dataset therapy with 1 obs per therapy event.
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

*
 Label variables
*;
cap lab var patid "Patient Identifier";
cap lab var eventdate "Event Date";
cap lab var sysdate "System Date";
cap lab var consid "Consultation Identifier";
cap lab var prodcode "Product Code";
cap lab var staffid "Staff Identifier";
cap lab var textid "Text Identifier";
cap lab var bnfcode "BNF Code";
cap lab var qty "Total Quantity";
cap lab var ndd "Numeric Daily Dose";
cap lab var numdays "Number of Days";
cap lab var numpacks "Number of Packs";
cap lab var packtype "Pack Type";
cap lab var issueseq "Issue Sequence Number";

*
 Create numeric date variables
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
