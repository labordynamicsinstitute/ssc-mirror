#delim ;
prog def cprd_browser_product;
version 13.0;
*
 Create dataset product with 1 obs per product code.
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
cap lab var prodcode "Product Code";
cap lab var therapyevents "Therapy Events";
cap lab var gemscriptcode "Gemscript Code";
cap lab var productname "Product Name";
cap lab var drugsubstancename "Drug Substance Name";
cap lab var substancestrength "Substance Strength";
cap lab var formulation "Formulation";
cap lab var routeofadministration "Route of Administration";
cap lab var bnfcode "BNF Code";
cap lab var bnfheader "BNF Header";
cap lab var databasebuild "Database Build";
desc, fu;

*
 Convert numeric variables to string if necessary
*;
foreach X in gemscriptcode {;
  cap conf numeric var `X';
  if !_rc {;
    tostring `X', replace format(%8.0f);
    desc `X', fu;
  };
};

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
  keyby prodcode;
};

*
 Describe dataset
*;
desc, fu;
char list;

end;
