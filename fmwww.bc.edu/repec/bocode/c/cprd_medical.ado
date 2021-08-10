#delim ;
prog def cprd_medical;
version 13.0;
*
 Create dataset medical with 1 obs per medical code.
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
cap lab var medcode "CPRD unique code for the medical term selected by the GP";
cap lab var readcode "Read Code";
cap lab var desc "Description of the medical term";
keyby medcode;
desc, fu;
char list;

end;
