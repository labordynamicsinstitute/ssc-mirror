#delim ;
prog def descgen;
version 10.0;
/*
 Generate dataset attribute variables in an xgen resultsset.
*! Author: Roger Newson
*! Date: 31 March 2017
*/


syntax [if] [in] [,
  FIlename(varname string) DIrname(varname string)
  noDN
  ISdta(name) NObs(name) NVar(name) WIdth(name) SIze(name)
  SOrtedby(name) ALLvars(name)
  noSB noAV
  REPLACE
  ];
/*
filename() specifies the file name input variable.
dirname() specifies the directory name input variable.
nodn specifies that the directory name input variable will not be used,
  even if it exists.
isdta() specifies the generated variable indicating whether a file name
  is a Stata dataset that can be described.
nobs() specifies the generated variable containing number of observations.
nvar() specifies the generated variable containing the number of observations.
width() specifies the generated variable containing the observation width
  (in bytes).
size() specifies the generated variable containing the size of the dataset
  (in bytes).
sortedby() specifies the generated variable containing the sort list of
  variables.
allvars() specifies the generated variable containing the varlist.
nosb specifies that the sortedby variable will not be created.
noav specifies that the allvars variable will not be created.
replace specifies that any existing variables with the same names as
  generated variables will be replaced.
*/


*
 Set default input variable options
*;
if `"`filename'"'=="" {;
  local filename filename;
};
if "`dirname'"=="" {;
  local dirname dirname;
};

*
 Set default generated variable name options
*;
local numgen "isdta nobs nvar width size";
local strgen "sortedby allvars";
foreach X in `numgen' `strgen' {;
  if "``X''"=="" {;
    local `X' `X';
  };
};


*
 Check that variables to be generated do not already exist
 if replace is not specified
*;
if "`replace'"=="" {;
  local tobegen "";
  foreach X in `numgen' {;
    local tobegen "`tobegen' ``X''";
  };
  if "`sb'"!="nosb" {;
    local tobegen "`tobegen' `sortedby'";
  };
  if "`av'"!="noav" {;
    local tobegen "`tobegen' `allvars'";  
  };
  conf new var `tobegen';
};


*
 Mark sample
*;
marksample touse;


*
 Initialize variables
*;
foreach X in `numgen' `strgen' {;
  if "`X'"!="" {;
    cap conf new var ``X'';
  };
};
foreach X in `numgen' {;
  tempvar `X'_t;
  qui gene byte ``X'_t'=. if `touse';
};
foreach X in `strgen' {;
  tempvar `X'_t;
  qui gene str1 ``X'_t'="" if `touse';
};


*
 Evaluate variables
*;
local vl "varlist";
if "`sb'"=="nosb" & "`av'"=="noav" {;
  local vl "";
};
tempname FNscal;
local Nfile=_N;
forv i1=1(1)`Nfile' {;
  if `touse'[`i1'] {;
    scal `FNscal' = `filename'[`i1'];
    if "`dn'"!="nodn" {;
      scal `FNscal'=`dirname'[`i1']+c(dirsep)+`FNscal';
    };
    * Check that the file name names a readable file *;
    mata: st_local("isFN",strofreal(fileexists(st_strscalar("`FNscal'"))));
    if !`isFN' {;
      qui replace `isdta_t'=0 in `i1';
    };
    else {;
      cap desc using `"`=`FNscal''"', `vl';
      qui replace `isdta_t'=(_rc==0) in `i1';
      if `isdta_t'[`i1']==1 {;
        qui {;
          replace `nobs_t'=r(N) in `i1';
          replace `nvar_t'=r(k) in `i1';
          replace `width_t'=r(width) in `i1';
          if "`sb'"!="nosb" {;
            replace `sortedby_t'=`"`r(sortlist)'"' in `i1';
          };
          if "`av'"!="noav" {;
            replace `allvars_t'=`"`r(varlist)'"' in `i1';
          };
        };
      };
    };
  };
};
qui replace `size_t'=`nobs_t'*`width_t' if `touse';


*
 Compress generated variables
*;
foreach X in `numgen' {;
  qui compress ``X'_t';
};


*
 Label variables
*;
lab var `isdta_t' "Stata dataset status indicator";
lab var `nobs_t' "N of observations";
lab var `nvar_t' "N of variables";
lab var `width_t' "Width of observation (bytes)";
lab var `size_t' "Size of dataset (bytes)";
lab var `sortedby_t' "Sort list of variables";
lab var `allvars_t' "List of all variables";


*
 Rename generated variables
*;
foreach X in `numgen' {;
  if "`replace'"!="" {;
    cap drop ``X'';
  };
  rename ``X'_t' ``X'';
};
if "`sb'"!="nosb" {;
  if "`replace'"!="" {;
    cap drop `sortedby';
  };
  rename `sortedby_t' `sortedby';
};
if "`av'"!="noav" {;
  if "`replace'"!="" {;
    cap drop `allvars';
  };
  rename `allvars_t' `allvars';
};


end;
