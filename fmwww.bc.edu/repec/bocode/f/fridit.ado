#delim ;
prog def fridit;
version 16.0;
/*
 Calculate foreign weighted ridits for an input variable
 with respect to a distribution identified
 by an equivalent variable in a data frame.
*! Author: Roger Newson
*! Date: 26 October 2020
*/


syntax varname [if] [in] , Generate(name) FFRame(string asis) [
  by(varlist) *
 ];
/*
 generate() specifies the output variable name.
 frame() specifies the frame (with weights).
 by() specifies by-variables.
 Other options are passed to wridit.
*/


* Specify sample to use *;
marksample touse;


*
 Parse fframe() option
*;
cap fframe_parse `fframe';
if _rc {;
  disp as error "Illegal fframe() option: " `"`fframe'"';
  error 498;
};
local fframename `"`r(fframename)'"';
local fframeweightvar `"`r(ffweightvar)'"';


*
 Extract foreign distribution from frame specified in fframe()
 to a temporary frame
*;
tempname fforeign;
tempvar tempwei;
confirm frame `fframename';
frame `fframename' {;
  cap noi conf var `by' `varlist' `fframeweightvar';
  if _rc {;
    disp as error "Not all these variables found in frame `fframename':";
    disp "`by' `varlist' `fframeweightvar'";
    error 498;
  };
  if `"`fframeweightvar'"'=="" {;
    qui gene byte `tempwei'=1;
  };
  else {;
    cap noi conf numeric var `fframeweightvar';
    if _rc {;
      disp as error "Foreign weight variable `fframeweightvar' is not numeric";
      error 498;
    };
    qui gene double `tempwei'=`fframeweightvar';
  };
  frame put `by' `varlist' `tempwei' if !missing(`varlist') & !missing(`tempwei'),
    into(`fforeign');
  drop `tempwei';
};


*
 Collapse foreign distribution frame
 to have 1 obs per by-group per x-value
*;
frame `fforeign' {;
  collapse (sum) `tempwei', by(`by' `varlist') fast;
  local N_fforeign=_N;
};


*
 Create native distribution frame
 to have 1 obs per by-group per x-value
*;
tempname fnative;
frame put `by' `varlist' if `touse', into(`fnative');
frame `fnative' {;
  sort `by' `varlist';
  qui {;
    by `by' `varlist': keep if _n==1;
    gene byte `tempwei'=0;
  };
  local N_fnative=_N;
};


*
 Append foreign distribution frame
 to native distribution frame
 and compute weighted ridits
 and drop foreign distribution frame
*;
local N_nf=`N_fnative'+`N_fforeign';
tempvar foreignseq foreignlink native temphome temphome2 tempgen;
frame `fforeign': qui gene long `foreignseq'=_n;
frame `fnative' {;
  qui {;
    set obs `N_nf';
    gene byte `native'=_n<=`N_fnative';
    gene long `foreignseq'=_n-`N_fnative' if !`native';
    frlink m:1 `foreignseq' , frame(`fforeign') gene(`foreignlink');
  };
  foreach X of var `by' `varlist' `tempwei' {;
    qui {;
      frame `fforeign': clonevar `temphome2'=`X';
      frget `temphome'=`temphome2', from(`foreignlink');
      frame `fforeign': drop `temphome2';
    };
    cap replace `X'=`temphome' if !`native';
    if _rc {;
      disp as error "Values of variable `X' from frame `fframename' could not be assigned to variable `X' from current frame";
      error 498;
    };
    drop `temphome';
  };
  if "`by'"!="" {;
    local bybyvars "by(`by')";
  };
  qui {;
    wridit `varlist' [iweight=`tempwei'], gene(`tempgen') `bybyvars' `options';
    keep if `native';
    drop `foreignseq' `foreignlink' `native';
  };
};
frame drop `fforeign';


*
 Add weighted ridits from native distribution frame to current frame
 and drop native distribution frame
*;
tempvar nativelink;
qui {;
  frlink m:1 `by' `varlist', frame(`fnative') gene(`nativelink');
  frget `temphome'=`tempgen', from(`nativelink');
  clonevar `tempgen'=`temphome' if `touse';
  drop `nativelink' `temphome';
};
frame drop `fnative';


*
 Rename temporary generated variable to permanent name
*;
rename `tempgen' `generate';


end;


prog def fframe_parse, rclass;
version 16.0;
/*
  Parse syntax of fframe() option.
*/

syntax name(name=name) [ , Weightvar(name) ];

return local fframename "`name'";
return local ffweightvar "`weightvar'";

end;