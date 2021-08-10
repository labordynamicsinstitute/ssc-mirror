#delim ;
prog def cprd_bnfcodes;
version 13.0;
*
 Create dataset bnfcodes with 1 obs per BNF code.
 Add-on packages required:
 keyby, chardef
*!Author: Roger Newson
*! Date: 21 March 2016
*;

syntax using [ , CLEAR ];

*
 Input data
*;
import delimited `using', varnames(1) `clear';
desc, fu;
* Convert bnf to string as specified in the documentation *;
char list;
tostring bnf, replace;
char list;
charundef bnf, char(*);
char list;
cap lab var bnfcode "Coded value for the actual BNF code representation of the prescribed product";
cap lab var bnf "BNF code representing the chapter and section for the prescribed product";
keyby bnfcode;
desc, fu;
char list;

end;
