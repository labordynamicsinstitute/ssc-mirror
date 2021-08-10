#delim ;
prog def cprd_product;
version 13.0;
*
 Create dataset product with 1 obs per product code.
 Add-on packages required:
 keyby
*!Author: Roger Newson
*!Date: 20 July 2016
*;

syntax using [ , CLEAR ];

*
 Input data
*;
import delimited `using', varnames(1) `clear';
desc, fu;
cap lab var prodcode "CPRD unique code for the treatment selected by the GP";
cap lab var gemscriptcode "Gemscript product code for the corresponding product name";
cap lab var productname "Product name as entered at the practice";
cap lab var drugsubstance "Drug substance";
cap lab var strength "Strength of the product";
cap lab var formulation "Form of the product e.g. tablets, capsules etc";
cap lab var route "Route of administration of the product";
cap lab var bnfcode "British National Formulary (BNF) code";
cap lab var bnfchapter "British National Formulary (BNF) chapter";
keyby prodcode;
desc, fu;
char list;

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

desc, fu;
char list;

end;
