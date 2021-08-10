#delim ;
prog def wridit, sortpreserve;
version 16.0;
/*
 Calculate weighted ridits for an input variable.
*! Author: Roger Newson
*! Date: 20 October 2020
*/


syntax varname [if] [in] [fweight pweight aweight iweight] , Generate(name) [
  by(varlist) HAndedness(string) FOLded REVerse PERCent float
 ];
/*
 generate() specifies the output variable name.
 by() specifies by-variables.
 handedness() specifies handedness of ridits (left, right or discontinuous).
 folded specifies folded ridits.
 reverse specifies reverse ridits.
 percent specifies percent ridits (instead of proportional ridits).
 float specifies that the output variable will have type float.
*/


*
 Set handedness (with sensible default)
*;
local handedness=lower(trim(`"`handedness'"'));
if `"`handedness'"'=="" {;
  local handedness="center";
};
else if strpos("left",`"`handedness'"')==1 {;
  local handedness="left";
};
else if strpos("right",`"`handedness'"')==1 {;
  local handedness="right";
};
else if strpos("center",`"`handedness'"')==1 {;
  local handedness="center";
};
else {;
  disp as error `"Invalid handedness(`handedness')"';
  error 498;
};


*
 Mark sample
*;
marksample touse, zeroweight;
if `"`exp'"'=="" {;local exp "=1";};


*
 Compute ridits
*;
tempvar wt minus subtotal total summand tempgen;
qui {;
  gene double `wt' `exp' if `touse';
  gene double `minus'=-`varlist';
  sort `touse' `by' `varlist';
  by `touse' `by': egen double `total'=total(`wt') if `touse';
  by `touse' `by' `varlist': egen double `subtotal'=total(`wt') if `touse';
  if `"`handedness'"'=="right" {;
    by `touse' `by' `varlist': gene double `summand'=`subtotal'*(_n==1) if `touse';
    by `touse' `by': gene double `tempgen' = sum(`summand') if `touse';
  };
  else {;
    by `touse' `by' `varlist': gene double `summand'=`subtotal'*(_n==_N) if `touse';
    by `touse' `by': gene double `tempgen' = sum(`summand'[_n-1]) if `touse';
  };
  sort `touse' `by' `minus';
  if `"`handedness'"'=="left" {;
    by `touse' `by' `minus': replace `summand'=`subtotal'*(_n==1) if `touse';
    by `touse' `by': replace `tempgen' = (`tempgen'-sum(`summand'))/`total' if `touse';
  };
  else {;
    by `touse' `by' `minus': replace `summand'=`subtotal'*(_n==_N) if `touse';
    by `touse' `by': replace `tempgen' = (`tempgen'-sum(`summand'[_n-1]))/`total' if `touse';
  };
  if "`reverse'" != "" {;replace `tempgen' = -`tempgen';};
  if "`folded'"=="" {;replace `tempgen' = (`tempgen'+1)/2;};
  if "`percent'" != "" {;replace `tempgen' = 100 * `tempgen';};
  if "`float'"!="" {;recast `tempgen' float;};
  compress `tempgen';
};
rename `tempgen' `generate';


end;
