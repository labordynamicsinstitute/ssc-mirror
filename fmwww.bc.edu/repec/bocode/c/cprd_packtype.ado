#delim ;
prog def cprd_packtype;
version 13.0;
*
 Create dataset packtype with 1 obs per pack size or type code.
 Add-on packages required:
 keyby
*!Author: Roger Newson
*!Date: 21 March 2016
*;

syntax using [ , CLEAR ];

*
 Input data
*;
import delimited `using', varnames(1) `clear';
desc, fu;
cap lab var packtype "Coded value associated with the pack size or type of the prescribed product";
cap lab var packtype_desc "Pack size or type of the prescribed product";
keyby packtype;
desc, fu;
char list;

end;
