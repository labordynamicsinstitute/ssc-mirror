#delim ;
prog def cprd_batchnumber;
version 13.0;

*
 Create dataset batchnumber with 1 obs per immunisation batch number.
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
cap lab var batch "Coded value associated with the immunisation batch number";
cap lab var batch_number "Immunisation batch number";
keyby batch;
desc, fu;
char list;

end;
