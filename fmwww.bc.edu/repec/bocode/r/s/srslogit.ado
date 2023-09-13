#delimit ;
program define srslogit, eclass sortpreserve;
version 16.0;
/*
 Fit primary logit model to the data
 followed by a secondary ridit spline model
 in the ridit of the predicted valued from the primary model,
 creating output variables if requested.
 This program allows fweights, iweights or pweights.
*! Author: Roger Newson
*! Date: 21 September 2021
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
  PPRObability(name) PXB(name) PIPWeight(name)
  noSRSpline
  POWer(integer 3) REFPts(numlist ascending >=0 <=100)
  RIDit(name)
  SPRObability(name) SXB(name) SIPWeight(name)
  RRSpline(name)
  noCONStant
  *
  ];


*
 Set defaults
*;
local refpts: list uniq refpts;
if "`refpts'"=="" {;
  local refpts "0 25 50 75 100";
};
local Nrefpt: word count `refpts';
if `Nrefpt'<`power'+1 {;
  disp as error "At least `=`power'+1' reference points needed for a ridit spline of power `power'";
  error 498;
};
* Single output variables *;
foreach X in pprobability pxb pipweight ridit sprobability sxb sipweight {;
  if "``X''"=="" {;
    tempvar `X';
  };
  conf new var ``X'';
};
* Ridit reference spline basis *;
local rrsbasis "";
if "`rrspline'"=="" {;
  forv i1=1(1)`Nrefpt' {;
    tempvar rscur;
    local rrsbasis "`rrsbasis' `rscur'";
  };
};
else {;
  forv i1=1(1)`Nrefpt' {;
    local rrsbasis "`rrsbasis'  `rrspline'`i1'";
  };
};


* Mark sample to use *;
marksample touse;


*
 Fit primary logit model
*;
disp _n as text "Primary logit model";
cap noi glm `varlist' if `touse' [`weight'`exp'] , family(bernoulli) link(logit) asis `constant' `options';
if !inlist(_rc,0,430) {;
  error _rc;
};
local depvar=e(depvar);
cap assert inlist(`depvar',0,1) if `touse';
if _rc {;
  disp as error "Depemdent variable `depvar' is not binary";
  error 498;
};


*
 Weight stabilization factors
*;
tempname stabfac0 stabfac1;
qui summ `depvar' if `touse', meanonly;
scal `stabfac1'=r(mean);
scal `stabfac0'=1-`stabfac1';


*
 Primary model output variables
*;
qui {;
  predict double `pprobability' if `touse';
  predict double `pxb' if `touse', xb;
  foreach X of var `pprobability' `pxb' {;
    local Xlab: var lab `X';
    lab var `X' "`Xlab' (primary)";
  };
  gene double `pipweight'=cond(`depvar',`stabfac1'/`pprobability',`stabfac0'/(1-`pprobability')) if `touse';
  lab var `pipweight' "Inverse probability weight (primary)";
};


*
 Ridit and ridit splines if required
*;
if "`srspline'"!="nosrspline" {;

  qui {;
    wridit `pxb' [`weight'`exp'], percent gene(`ridit');
    lab var `ridit' "Ridit of predicted mean (primary)";
    flexcurv `rrsbasis' if `touse' , xvar(`ridit') refpts(`refpts') power(`power') krule(interpolate)
      include(0 100) type(double)
      labprefix("Percent@");
  };
  disp _n as text "Reference ridit spline basis";
  desc `rrsbasis', fu;
  disp _n as text "Secondary ridit spline logit model";
  cap noi glm `depvar' `rrsbasis' if `touse' [`weight'`exp'] , family(bernoulli) link(logit) asis noconstant
    `options';
  if !inlist(_rc,0,430) {;
    error _rc;
  };


  *
   Secondary model output variables
  *;
  qui {;
    predict double `sprobability' if `touse';
    predict double `sxb' if `touse', xb;
    foreach X of var `sprobability' `sxb' {;
      local Xlab: var lab `X';
      lab var `X' "`Xlab' (secondary)";
    };
    gene double `sipweight'=cond(`depvar',`stabfac1'/`sprobability',`stabfac0'/(1-`sprobability')) if `touse';
    lab var `sipweight' "Inverse probability weight (secondary)";
  };


};


*
 End of non-replay section (not indented)
*;
};


end;
