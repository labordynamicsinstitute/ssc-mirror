#delim ;
prog def lexpgen;
version 10.0;
/*
 Expand by a numlist and generate new variables
 containing sequence number of original observation before duplication
 and numlist entry after duplication,
 sorting the dataset by these new variables
 to retain the original order.
*!Author: Roger Newson
*!Date: 07 March 2024
*/

syntax [newvarname] [if]  [in] , LEvels(numlist sort missingokay) CLEVel(name)  [ Oldseq(name) Copyseq(name) ORder fast * ];
/*
 levels() gives numlist to expand dataset by.
 clevel() gives name of new variable containing copy level from levels()
  for current generated observation.
 fast specifies that lexpgen will not go to extra work
  to restore original dataset if lexpgen fails or the user presses Break.
 Other options are passed to expgen.
*/

local levels: list uniq levels;
local Nlevel: word count `levels';

if "`fast'"=="" preserve;

if "`clevel'"=="" tempvar clevel;
if "`oldseq'"=="" tempvar oldseq;
if "`copyseq'"=="" tempvar copyseq;

marksample touse, novarlist;

* Expand dataset *;
expgen `varlist'=`Nlevel' if `touse', fast `order' oldseq(`oldseq') copyseq(`copyseq') `options';

*
 Evaluate clevel() variable
*;
qui gene byte `clevel'=.;
forv i1=1(1)`Nlevel' {;
  local levelcur: word `i1' of `levels';
  qui replace `clevel'=`levelcur' if `copyseq'==`i1';
};
lab var `clevel' "Copy level in output dataset";

*
 Sort dataset substituting clevel() for copyseq() in the sortedby varlist
 and order if specified
*;
local sb: sortedby;
local newsb="";
foreach BV of var `sb' {;
  if "`BV'" == "`copyseq'" local newsb "`newsb' `clevel'";
  else local newsb "`newsb' `BV'";
}; 
if "`newsb'"!="" qui sort `newsb', stable;
if "`order'"!="" order `newsb';

if "`fast'"=="" restore, not;

end;
