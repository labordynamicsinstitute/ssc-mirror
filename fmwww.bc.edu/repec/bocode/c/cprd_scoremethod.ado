#delim ;
prog def cprd_scoremethod;
version 13.0;
*
 Create dataset scoremethod with 1 obs per scoring methodology code.
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
lab var code "Coded value associated with the scoring methodology used";
lab var scoringmethod "Scoring methodology";
keyby code;
desc, fu;
char list;

end;
