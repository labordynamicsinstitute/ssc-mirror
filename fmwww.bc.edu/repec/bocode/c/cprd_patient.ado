#delim ;
prog def cprd_patient;
version 13.0;
*
 Create dataset patient with 1 obs per patient in the retrieval.
 Add-on do-files required:
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
cap lab var patid "Patient Identifier";
cap lab var vmid "VAMP Identifier";
cap lab var gender "Patient Gender";
cap lab var yob "Birth Year";
cap lab var mob "Birth Month";
cap lab var marital "Marital Status";
cap lab var famnum "Family Number";
cap lab var chsreg "CHS Registered";
cap lab var chsdate "CHS Registration Date";
cap lab var prescr "Prescription Exemption";
cap lab var capsup "Capitation Supplement";
cap lab var ses "Socio-Economic Status";
cap lab var frd "First Registration Date";
cap lab var crd "Current Registration Date";
cap lab var regstat "Registration Status";
cap lab var reggap "Registration Gaps";
cap lab var internal "Internal Transfer";
cap lab var tod "Transfer Out Date";
cap lab var toreason "Transfer Out Reason";
cap lab var deathdate "Death Date";
cap lab var accept "Acceptable Patient Flag";
keyby patid, fast;
desc, fu;

*
 Add value labels for variables
*;
if `"`dofile'"'!="" {;
  run `"`dofile'"';
  lab val gender sex;
  lab val marital mar;
  lab val chsreg y_n;
  lab val prescr pex;
  lab val capsup cap;
  lab val toreason tra;
  desc, fu;
  foreach X of var gender marital chsreg prescr capsup toreason {;
    lablist `X', var;
  };
};

*
 Add practice ID variable
 (computed from patient ID variable)
*;
gene long pracid=mod(patid-1,1000)+1;
compress pracid;
lab var pracid "Practice identifier";
desc pracid, fu;

*
 Add numeric date variables computed from string dates
*;
foreach X of var chsdate frd crd tod deathdate {;
  gene long `X'_n=date(`X',"DMY");
  compress `X'_n;
  format `X'_n %tdCCYY/NN/DD;
};
lab var chsdate_n "Child Health Surveillance registration date";
lab var frd_n "First registration date with practice";
lab var crd_n "Current registration date with practice";
lab var tod_n "Date of transfer out of practice";
lab var deathdate_n "Patient death date (CPRD Gold)";

*
 Add earliest possible birth date
*;
gene long yob2=yob+1800;
gene long mob2=mob+(mob==0);
compress yob2 mob2;
gene long ebdate_n=mdy(mob2,01,yob2);
compress ebdate_n;
format ebdate_n  %tdCCYY/NN/DD;
lab var ebdate_n "Earliest possible birth date";
drop yob2 mob2;
desc ebdate_n, fu;

desc, fu;

end;
