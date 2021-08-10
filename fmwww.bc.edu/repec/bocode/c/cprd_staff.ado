#delim ;
prog def cprd_staff;
version 13.0;
*
 Create dataset staff with1 obs per staff member.
 Add-on packages required:
 keyby, lablist
*!Author: Roger Newson
*!Date: 21 March 2016
*;

syntax using [ , CLEAR DOfile(string) ];

*
 Input data
*;
import delimited `using', varnames(1) `clear';
desc, fu;
cap lab var staffid "Staff Identifier";
cap lab var gender "Staff Gender";
cap lab var role "Staff Role";
keyby staffid, fast;
desc, fu;

*
 Add value labels for variables
*;
if `"`dofile'"'!="" {;
  run `"`dofile'"';
  lab val gender sex;
  lab val role rol;
  foreach X of var gender role {;
    desc `X', fu;
    lablist `X', var;
  };
};

*
 Save dataset
*;
desc, fu;

end;
