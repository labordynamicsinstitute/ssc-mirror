#delim ;
prog def cprd_additional;
version 13.0;
*
 Create datasets additional
 with 1 obs per set of additional clinical details.
 Add-on pachages needed:
 keyby, chardef
*!Author: Roger Newson
*!Date: 22 March 2016
*;

syntax using [ , CLEAR DOfile(string) ];

*
 Input data
*;
import delimited `using', varnames(1) stringcols(4/10) `clear';
desc, fu;
char list;
cap lab var patid "Patient Identifier";
cap lab var enttype "Entity Type";
cap lab var adid "Additional Details Identifier";
cap lab var data1 "Data 1 (Depends on Entity Type)";
cap lab var data2 "Data 2 (Depends on Entity Type)";
cap lab var data3 "Data 3 (Depends on Entity Type)";
cap lab var data4 "Data 4 (Depends on Entity Type)";
cap lab var data5 "Data 5 (Depends on Entity Type)";
cap lab var data6 "Data 6 (Depends on Entity Type)";
cap lab var data7 "Data 7 (Depends on Entity Type)";

*
 Key and describe dataset
*;
keyby patid adid, fast;
desc, fu;

end;
