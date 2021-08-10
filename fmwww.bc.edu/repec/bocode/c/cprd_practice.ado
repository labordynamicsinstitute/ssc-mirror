#delim ;
prog def cprd_practice;
version 13.0;
*
 Create dataset practice
 with 1 obs per practice in the retrieval.
 Add-on files required:
 keyby, lablist
*!Author: Roger Newson
*!Date: 22 March 2016
*;

syntax using [ , CLEAR DOfile(string) ];

*
 Input data
*;
import delimited `using', varnames(1) `clear';
desc, fu;
cap lab var pracid "Practice identifier";
cap lab var region "Region";
cap lab var lcd "Last Collection Date";
cap lab var uts "Up To Standard Date";
keyby pracid, fast;
desc, fu;

*
 Add value labels for variables
*;
if `"`dofile'"'!="" {;
  run `"`dofile'"';
  lab val region prg;
  desc region, fu;
  lablist region, var;
};

*
 Add numeric date variables
*;
foreach X of var lcd uts {;
  gene long `X'_n=date(`X',"DMY");
  compress `X'_n;
  format `X'_n %tdCCYY/NN/DD;
};
lab var lcd_n "Last collection date for practice";
lab var uts_n "Up to standard date for practice";
desc lcd_n uts_n, fu;

desc, fu;

end;
