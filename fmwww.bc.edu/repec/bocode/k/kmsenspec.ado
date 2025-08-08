#delim c;
program kmsenspec, eclass byable(recall);
version 16.0;
/*
 In a stset dataset,
 estimate sensitivity, specificity,
 positive predictive value, and negative predictive value
 for an input binary test-positivity indicator variable,
 using Kaplan-Meier survival probability for an input time.
*!Author: Roger Newson
*!Date: 07 August 2025
*/

* Check that required packages are present *;
qui whichlist kmest, packagelist(kmest);
local incomplete "`r(incomplete)'";
if !missing("`incomplete'") {;
  disp as error "The following SSC packages are required and not present:"
    _n as error "`incomplete'";
};

if(replay()){;
*
 Beginning of replay section (not indented)
*;

if "`e(cmd)'"!="kmsenspec"{;
  error 301;
};
syntax [, Level(cilevel) ];


* Display estimation results *;
disp as text "Kaplan-Meier PPV and NPV estimated at time: " as result e(time)
  _n as text "Valid observations: " as result e(N)
  _n as text "Observations testing positive: " as result e(Ntestpos)
  _n as text "Observations testing negative: " as result e(Ntestneg)
  ;
ereturn display, level(`level');

*
 End of replay section (not indented)
*;
};
else {;
*
 Beginning of non-replay section (not indented)
*;

syntax varname(min=1 max=1 numeric) [if] [in] , Time(numlist min=1 max=1 >=0) [ Level(cilevel) ];
/*
 time() is the time at which positive and negative predictive values,
   sensitivity, and specificity are evaluated.
*/

marksample touse;

*
 Identify test-positivity variable
 and check that it is binary,
 with values 0 and 1 (both present).
*;
local testpos `varlist';
assert inlist(`testpos',0,1) if `touse';
if _rc {;
  disp as error "Variable `testpos' must be binary with values 0 and 1";
  error 498;
};
summ `testpos' if `touse', meanonly;
assert r(min)==0 & r(max)==1;
if _rc {;
  disp as error "Variable `testpos' must contain both values 0 and 1";
  error 498;
};

* tempnames for scalars used in calculations *;
tempname Ntestpos Ntestneg PPV NPV Var_PPV Var_NPV sens spec Dcur;

* Estimate PPV *;
qui kmest if `touse' & `testpos'==1, times(`time');
scal `Ntestpos'=e(N);
scal `PPV'=1-e(b)[1,1];
scal `Var_PPV'=e(greenwood_Vdiag)[1,1];
scal `Var_PPV'=cond(missing(`Var_PPV'),0,`Var_PPV');

* Estimate NPV *;
qui kmest if `touse' & `testpos'==0, times(`time');
scal `Ntestneg'=e(N);
scal `NPV'=e(b)[1,1];
scal `Var_NPV'=e(greenwood_Vdiag)[1,1];
scal `Var_NPV'=cond(missing(`Var_NPV'),0,`Var_NPV');

* Create estimate and variance matrices for PPV and NPV *;
tempname A Cov_A B Cov_B D;
matr def `A'=J(1,2,0);
matr def `Cov_A'=J(2,2,0);
matrix colnames `A'=PPV NPV;
matr rownames  `A'=`testpos';
matr colnames `Cov_A'=PPV NPV;
matr rownames `Cov_A'=PPV NPV;
matr def `A'[1,1]=`PPV';
matr def `A'[1,2]=`NPV';
matr def `Cov_A'[1,1]=`Var_PPV';
matr def `Cov_A'[2,2]=`Var_NPV';

* Estimate sensitivity and specificity *;
tempname sensdenom specdenom sens spec Dcur;
scal `sensdenom' = `Ntestpos'*`PPV' + `Ntestneg'*(1-`NPV');
scal `specdenom' = `Ntestpos'*(1-`PPV') + `Ntestneg'*`NPV';
scal `sens' = `Ntestpos'*`PPV';
if `sens'!=0 scal `sens' = `sens'/`sensdenom';
scal `spec' = `Ntestneg'*`NPV';
if `spec'!=0 scal `spec' = `spec'/`specdenom';
matr def `B'=J(1,2,0);
matr rownames `B'=`testpos';
matr colnames `B'=Sensitivity Specificity;
matr def `B'[1,1]=`sens';
matr def `B'[1,2]=`spec';
matr def `B'=`B',`A';

* Create matriv covariances for sensitivity, specificity, PPV and NPV *;
matr def `D'=J(4,2,0);
matr colnames `D'=PPV NPV;
matr rownames `D'=Sensitivity Specificity PPV NPV;
matr def `D'[3,1]=1;
matr def `D'[4,2]=1;
scal `Dcur' = `Ntestpos'*`Ntestneg'*(1-`NPV')/(`sensdenom'*`sensdenom');
if !missing(`Dcur') matr def `D'[1,1] = `Dcur';
scal `Dcur' = `Ntestpos'*`Ntestneg'*`PPV'/(`sensdenom'*`sensdenom');
if !missing(`Dcur') matr def `D'[1,2] = `Dcur';
scal `Dcur' = `Ntestpos'*`Ntestneg'*`NPV'/(`specdenom'*`specdenom');
if !missing(`Dcur') matr def `D'[2,1] = `Dcur';
scal `Dcur' = `Ntestpos'*`Ntestneg'*(1-`PPV')/(`specdenom'*`specdenom');
if !missing(`Dcur') matr def `D'[2,2] = `Dcur';
matr def `Cov_B' = `D'*`Cov_A'*`D'';

* Return estimation results *;
local Ntot = `Ntestpos' + `Ntestneg';
ereturn post `B' `Cov_B', depname(`testpos') obs(`Ntot') esample(`touse');
ereturn scalar Ntestpos=`Ntestpos';
ereturn scalar Ntestneg=`Ntestneg';
ereturn scalar time=`time';
ereturn matrix D=`D';
ereturn local cmdline `"kmsenspec `0'"';
ereturn local cmd "kmsenspec";
ereturn local predict "kmsenspec_p";



* Display estimation results *;
disp as text "Kaplan-Meier PPV and NPV estimated at time: " as result e(time)
  _n as text "Valid observations: " as result e(N)
  _n as text "Observations testing positive: " as result e(Ntestpos)
  _n as text "Observations testing negative: " as result e(Ntestneg)
  ;
ereturn display, level(`level');

*
 End of non-replay section (not indented)
*;
};

end;


prog def whichlist, rclass;
version 16.0;
/*
 Input a list of which input items
 and optionally a package list
 and output lists of present and absent items
 and complete and incomplete packages.
*/


syntax anything(name=itemlist) [ , Packagelist(namelist) NOIsily ];
*
 packagelist() specifies a list of packages
   for the items to belong to.
 noisily specifies that whichlist will have the output generated by which
   for each item in the item list.
*;
local Nitem: word count `itemlist';

*
 Extend packagelist if required
*;
if "`packagelist'"!="" {;
  local Npackage: word count `packagelist';
  if `Npackage' < `Nitem' {;
    local lastpackage: word `Npackage' of `packagelist';
    forv i1=`=`Npackage'+1'(1)`Nitem' {;
      local packagelist "`packagelist' `lastpackage'";
    };
  };
};


*
 Create present, absent, complete, and incomplete lists
*;
if "`packagelist'"=="" {;
  * Create present and absent lists only *;
  forv i1=1(1)`Nitem' {;
    local itemcur: word `i1' of `itemlist';
    cap `noisily' which `itemcur';
    if _rc local absent `"`absent' `itemcur'"';
    else local present `"`present' `itemcur'"';
  };
};
else {;
  * Create present, absent, complete, and incomplete lists *;
  forv i1=1(1)`Nitem' {;
    local itemcur: word `i1' of `itemlist';
    local packagecur: word `i1' of `packagelist';
    cap `noisily' which `itemcur';
    if _rc {;
      local absent `"`absent' `itemcur'"';
      local incomplete "`incomplete' `packagecur'";
    };
    else {;
      local present `"`present' `itemcur'"';
      local complete "`complete' `packagecur'";
    };
  };
  local incomplete: list uniq incomplete;
  local incomplete: list sort incomplete;
  local complete: list uniq complete;
  local complete: list complete - incomplete;
  local complete: list sort complete;
};
local present: list uniq present;
local present: list sort present;
local absent: list uniq absent;
local absent: list sort absent;


*
 List results
*;
if `"`present'"'!="" {;
  disp as text "Present items:";
  disp as result `"`present'"';
};
if `"`absent'"'!="" {;
  disp as text "Absent items:";
  disp as result `"`absent'"';
};
if "`complete'"!="" {;
  disp as text "Complete packages:";
  disp as result `"`complete'"';
};
if "`incomplete'"!="" {;
  disp as text "Incomplete packages:";
  disp as result `"`incomplete'"';
};


*
 Return results
*;
foreach R in incomplete complete absent present {;
  return local `R' `"``R''"';
};


end;
