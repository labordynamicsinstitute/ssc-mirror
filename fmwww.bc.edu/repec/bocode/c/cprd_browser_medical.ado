#delim ;
prog def cprd_browser_medical;
version 13.0;
*
 Create dataset with 1 obs per medical code
 and data on CPRD browser output.
 Add-on packages required:
 keyby
*!Author: Roger Newson
*!Date: 19 October 2016
*;

syntax using [ , CLEAR noKEY ];
/*
 clear specifies that any existing dataset in memory will be cleared.
 nokey specifies that the new dataset will not be keyed by prodcode.
*/

*
 Input data
*;
import delimited `using', varnames(1) `clear';
cap lab var medcode "Medical Code";
cap lab var clinicalevents "Clinical Events";
cap lab var referralevents "Referral Events";
cap lab var testevents "Test Events";
cap lab var immunisationevents "Immunisation Events";
cap lab var readcode "Read Code";
cap lab var readterm "Read Term";
cap lab var databasebuild "Database Build";
desc, fu;

*
 Add numeric database build variable
*;
cap conf string var databasebuild;
if !_rc {;
  gene long databasebuild_n=monthly(databasebuild,"MY",2099);
  compress databasebuild_n;
  format databasebuild_n %tmCCYY/NN;
  lab var databasebuild_n "Database build (monthly date)";
};

*
 Key dataset if requested
*;
if "`key'"!="nokey" {;
  keyby medcode;
};

*
 Describe dataset
*;
desc, fu;
char list;

end;
