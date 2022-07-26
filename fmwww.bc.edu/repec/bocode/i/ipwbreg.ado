#delimit ;
program define ipwbreg, eclass sortpreserve;
version 16.0;
/*
 Fit Bernoulli GLM model to the data
 creating inverse probability weights as requested.
 This program allows fweights, iweights or pweights.
*! Author: Roger Newson
*! Date: 24 July 2022
*/

if(replay()){;
*
 Beginning of replay section (not indented)
*;

if "`e(cmd)'"!="glm"{;
  error 301;
 };
syntax [, Level(cilevel) EForm ];

*
 Display output
*;
glm, level(`level') `eform' ;

*
 End of replay section (not indented)
*;
};

else{;
*
 Beginning of non-replay section (not indented)
*;

syntax varlist(min=1 max=9999 numeric fv ts) [if] [in] [fweight iweight pweight]
  [,
  noSTABfact
  LTRim(numlist max=1 >=0 <=1) RTRim(numlist max=1 >=0 <=1)
  PRObability(name) XB(name) IPWeight(name) ATETweight(name) ATECweight(name) OVWeight(name)
  noCONStant
  *
  ];


*
 Set defaults
*;
* Single output variables *;
foreach X in probability {;
  if "``X''"=="" {;
    tempvar `X';
  };
  conf new var ``X'';
};


* Mark sample to use *;
marksample touse;


*
 Fit Bernoulli regression model
*;
disp _n as text "Binary propensity model";
cap noi glm `varlist' if `touse' [`weight'`exp'] , family(bernoulli) asis `constant' `options';
if !inlist(_rc,0,430) {;
  error _rc;
};
local depvar=e(depvar);
cap assert inlist(`depvar',0,1) if `touse';
if _rc {;
  disp as error "Dependent variable `depvar' is not binary";
  error 498;
};


*
 Weight stabilization factors
*;
tempname stabfac0 stabfac1;
qui summ `depvar' if `touse' [`weight'`exp'], meanonly;
if "`stabfact'"=="nostabfact" {;
  scal `stabfac1'=1;
  scal `stabfac0'=1;
};
else {;
  scal `stabfac1'=r(mean);
  scal `stabfac0'=1-`stabfac1';
};
ereturn scalar stabfac0=`stabfac0';
ereturn scalar stabfac1=`stabfac1';


*
 Output variables
*;
qui {;
  predict double `probability' if `touse';
  if "`xb'"!="" predict double `xb' if `touse', xb;
  * Trim probabilities if requested *;
  if "`ltrim'"!="" replace `probability'=max(`probability',`ltrim') if `touse' & !missing(`probability');
  if "`rtrim'"!="" replace `probability'=min(`probability',`rtrim') if `touse' & !missing(`probability');
  * Compute weights if requested *;
  if "`ipweight'"!="" gene double `ipweight'=cond(`depvar',`stabfac1'/`probability',`stabfac0'/(1-`probability')) if `touse';
  if "`atetweight'"!="" gene double `atetweight'=cond(`depvar',`stabfac1',`stabfac0'*`probability'/(1-`probability')) if `touse';
  if "`atecweight'"!="" gene double `atecweight'=cond(`depvar',`stabfac1'*(1-`probability')/`probability',`stabfac0') if `touse';
  if "`ovweight'"!="" gene double `ovweight'=cond(`depvar',1-`probability',`probability') if `touse';
};
cap lab var `ipweight' "Inverse probability weight";
cap lab var `atetweight' "ATET weight";
cap lab var `atecweight' "ATEC weight";
cap lab var `ovweight' "Overlap weight";


*
 End of non-replay section (not indented)
*;
};


end;
